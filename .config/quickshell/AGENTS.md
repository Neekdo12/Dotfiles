# Panel open/close behavior

This repo drives two slide-out panels from a single 3-finger trackpad
gesture, read by `bounce_script.py` via `libinput debug-events` and
forwarded to Quickshell's `panels` IPC handler (`begin` / `update` / `end`)
in `shell.qml`.

- **RightPanel** (`RightPanel.qml`) slides in from the right edge, driven
  by `root.currentX`.
- **TopPanel** (`TopPanel.qml`) slides in from the top edge (right-aligned,
  narrower than the screen), driven by `root.currentY`.
- Both panels, plus the always-visible clock tab (`cornerTab` /
  `Time.qml`), live in **one** `PanelWindow` anchored to all 4 screen
  edges - not two separate windows - so stacking order and the click-mask
  are simple/deterministic (see `mask:` in `shell.qml`).
- Panel fill colors live in `RightPanel.qml`/`TopPanel.qml`/`Time.qml`
  themselves; `shell.qml`'s `panelContent`/`topPanelContent`/`cornerTab`
  rectangles are transparent and only handle sizing/position/animation.

## Core model

- `root.currentX`/`root.currentY` are the single source of truth for each
  panel's position.
  - `current* == 0` → fully **open** (panel size == `panelWidth`/`panelHeight`).
  - `current* == panelWidth`/`panelHeight` → fully **closed** (size == 0).
  - Size is always derived, e.g. `width = panelWidth - currentX`.
- `cornerTab` tracks whichever panel is currently deployed: its `x` follows
  `panelContent`'s left edge, its `y` follows `topPanelContent`'s bottom
  edge, each overlapping by `seamOverlap` px to avoid a 1px rendering gap.
- Only one panel can end up open at a time - see "Mutual exclusion" below.

## Gesture flow (bounce_script.py → shell.qml)

A gesture can be diagonal-ish (not perfectly axis-aligned), so
`bounce_script.py` never locks onto a single axis - it always forwards
both `dx` and `dy` together to the one `"panels"` IPC target, and
`shell.qml` reconciles which panel (if only one) ends up open once the
gesture ends.

1. `begin()` - gesture starts. Resets per-axis drag state and snapshots
   `wasOpenXAtBegin`/`wasOpenYAtBegin` (see "Mutual exclusion").
2. `update(dxStr, dyStr)` - called at up to `UPDATE_HZ` while dragging.
   Advances both `currentX` (from `dx`) and `currentY` (from `dy`)
   unconditionally. If a drag pushes `current*` past its `[0, size]`
   range, it rubber-bands (30% resistance) into the overdrag range
   `[minX, maxX]` / `[minY, maxY]` (`±overdragAmount` from `openAnim.js`).
   `maxOverdragX`/`Y` track the peak overdrag distance reached this drag -
   the "how long/hard did you pull" signal used later for bounce
   intensity. Also accumulates `accumDeltaX`/`Y` to detect which axis was
   genuinely dragged this gesture (see below).
3. `end(velXStr, velYStr)` - gesture released. Each `vel*` is the
   **signed peak** velocity seen on that axis during the gesture (see
   `bounce_script.py`'s `peak_velocity_x`/`_y`), not just the value at
   release - so a brief fast flick still registers even if the swipe
   slowed down before lifting fingers.

## Deciding open vs. closed on release

For each axis independently, in `end()`:
- If `|velocity| > flickVelocityThreshold`: a fast flick decided by
  **direction** alone, regardless of how far it was dragged (`velX < 0`
  opens the right panel; `velY > 0`, i.e. a downward swipe, opens the top
  panel).
- Otherwise (slow release): decided by **position** - if `current*` is
  past `openThreshold = size * (1 - openDragFraction)`, it opens.
  `openDragFraction` (in `openAnim.js`) controls how much of the panel
  needs to be dragged open before a slow release snaps it open; lower =
  shorter required gesture.

This per-axis `wantOpen*` result is provisional - see "Mutual exclusion"
for how conflicts between the two axes get resolved.

## Mutual exclusion (only one panel open at a time)

An axis that's already open sits at `current* ≈ 0`, which trivially
satisfies the position-based `wantOpen` check above regardless of what
the current gesture actually did - so naively comparing "both want open"
by position unfairly favors whichever panel was already open. To avoid
that:

- `begin()` snapshots `wasOpenXAtBegin`/`wasOpenYAtBegin` - each panel's
  resting state *before* this gesture touched anything.
- In `end()`: whichever axis **wasn't** already open before this gesture
  always wins if it now wants to open, unconditionally forcing the
  resting-open axis shut. This is what makes a fresh flick/drag reliably
  switch panels, regardless of how little the already-open axis moved.
- Only when **neither** panel was open at gesture start (a genuine
  diagonal-ish attempt to open both from closed) does resolution fall
  back to comparing how far each got (`openFrac = 1 - current/size`),
  with "whichever axis moved first this gesture" (`openStartTimeX`/`Y`,
  set once `accumDeltaX`/`Y` crosses `axisTouchThreshold`) as a tie-break.

## Retract-without-lifting-fingers fix

If a user drags a panel open then reverses direction mid-gesture (fingers
never lift, so it's still one continuous swipe), the peak velocity
tracked so far would otherwise still reflect the earlier *opening*
motion, making `end()` think it was a fast open even though the user
visibly dragged it back. `bounce_script.py` fixes this by resetting
`peak_velocity_x`/`_y` whenever that axis's smoothed velocity flips sign
past `REVERSAL_MIN_SPEED` - a genuine reversal restarts peak-tracking from
the new (retracting) direction instead of keeping the stale one.

## Bounce (overshoot) behavior

- Opening can bounce; **closing never bounces** - `bounceOvershoot*` is
  forced to `0` and `closeDuration` is used whenever closing.
- When opening, `bounceOvershootFor()` (in `shell.qml`'s `panels`
  handler) computes "intensity" as the louder of:
  - normalized peak velocity (`|velocity| / velocityCap`), and
  - normalized peak overdrag (`maxOverdrag / overdragCap`).
  `intensity` is raised to `bounceCurveExponent` before scaling
  `maxOvershoot`, so normal short/slow gestures stay ~flat and only a
  genuinely fast flick or a long pull shows a visible bounce.
- The actual animation is a **single** `Behavior on width`/`height` using
  `NumberAnimation` with `easing.type: Easing.OutBack` and a dynamic
  `easing.overshoot` (0 = no bounce). `Easing.OutBack` overshoots at most
  once before settling - it cannot ring/oscillate like `SpringAnimation`
  could.
  - Important: QML only honors **one** `Behavior` per property. Do not add
    a second `Behavior on width`/`height` block - instead adjust
    `settleDuration*`/`bounceOvershoot*` before changing `current*`, as
    `end()` already does.

## libinput parsing gotcha

`libinput debug-events` right-pads each gesture axis to a fixed width, so
a non-negative second value (no `-` sign to absorb the padding space)
prints like `"11.30/  0.00"` - naive whitespace-splitting breaks that into
two tokens (`"11.30/"`, `"0.00"`) instead of one `dx/dy` pair.
`bounce_script.py` reassembles them (see the token-ends-with-`/` check in
`GESTURE_SWIPE_UPDATE` handling) before parsing floats - don't remove that
without re-testing a downward/rightward (non-negative) swipe.

## Where to tweak things

- All animation tuning **and size** constants (speeds, durations,
  overshoot amount, thresholds, panel/tab dimensions) live in
  `openAnim.js` with comments - edit there, not in `shell.qml`.
- `minX`/`maxX`/`minY`/`maxY` (the absolute overdrag clamp ranges) are
  derived from `panelWidth`/`panelHeight` and `OpenAnim.overdragAmount` -
  never hardcode them, or the clamp can end up smaller than the panel
  itself, causing it to visibly jump partway open while overdragging
  closed (this was a real bug: a clamp was once hardcoded to `135` while
  the panel was `375` wide).
- Panel content (widgets, layout) goes inside `RightPanel.qml` /
  `TopPanel.qml`; the clock widget goes inside `Time.qml`. `shell.qml`
  should stay limited to positioning/animation/gesture-handling.
