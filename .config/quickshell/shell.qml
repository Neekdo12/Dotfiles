import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "openAnim.js" as OpenAnim

PanelWindow {
    id: root

    // All size/animation constants live in openAnim.js so they're in one
    // place with explanations - see that file to tweak feel/dimensions.
    readonly property real panelWidth: OpenAnim.panelWidth
    readonly property real panelHeight: OpenAnim.panelHeight

    // TopPanel's width is a fixed size (not full-screen), right-aligned
    // (see topPanelContent below).
    readonly property real topPanelWidth: OpenAnim.topPanelWidth

    // Rubber-band overdrag range, symmetric around the [0, panelWidth] /
    // [0, panelHeight] ranges currentX/currentY normally live in.
    readonly property real minX: -OpenAnim.overdragAmount
    readonly property real maxX: panelWidth + OpenAnim.overdragAmount
    readonly property real minY: -OpenAnim.overdragAmount
    readonly property real maxY: panelHeight + OpenAnim.overdragAmount

    // Corner tab (clock panel) has its own independent size, separate
    // from either sliding panel's size.
    readonly property real cornerTabWidth: OpenAnim.cornerTabWidth

    // The panels and the tab are drawn as separate rectangles positioned
    // via independent bindings, so subpixel rounding can leave a 1px seam
    // between them. Overlapping the tab by this much guarantees they
    // always visually touch with no gap, regardless of rounding.
    readonly property real seamOverlap: OpenAnim.seamOverlap

    // Always-out tab. It sits immediately next to whichever panel's
    // leading edge is currently deployed, so it acts as "the corner of
    // the display" for it: glued to the real screen corner while both
    // panels are closed, and sliding along with whichever one opens
    // (bounce included). A diagonal-ish gesture can drag both panels open
    // at once; only one wins at release time (see the "panels" IpcHandler
    // below), so the tab converges back onto a single axis once the
    // gesture ends.
    readonly property real cornerTabHeight: OpenAnim.cornerTabHeight

    // Open-bounce tuning. All the actual numbers live in openAnim.js so
    // they're in one place with explanations - see that file to tweak
    // feel/timing.
    readonly property real velocityCap: OpenAnim.velocityCap
    readonly property real overdragCap: OpenAnim.overdragCap
    readonly property real bounceCurveExponent: OpenAnim.bounceCurveExponent
    readonly property real maxOvershoot: OpenAnim.maxOvershoot
    readonly property real openDuration: OpenAnim.openDuration
    readonly property real closeDuration: OpenAnim.closeDuration
    readonly property real flickVelocityThreshold: OpenAnim.flickVelocityThreshold
    readonly property real openDragFraction: OpenAnim.openDragFraction
    readonly property real axisTouchThreshold: OpenAnim.axisTouchThreshold

    property real currentX: panelWidth
    property bool isDraggingX: false
    property real maxOverdragX: 0        // peak overdrag reached this drag (the "long gesture" signal)
    property real bounceOvershootX: 0    // OutBack amplitude for the current settle animation (0 = no bounce)
    property real settleDurationX: closeDuration
    property real openStartTimeX: 0      // Date.now() of this drag's first real X movement, 0 = hasn't moved yet
    property real accumDeltaX: 0         // total dx this gesture, used for the both-closed diagonal tie-break
    property bool wasOpenXAtBegin: false // whether the right panel was already open before this gesture started

    property real currentY: panelHeight
    property bool isDraggingY: false
    property real maxOverdragY: 0
    property real bounceOvershootY: 0
    property real settleDurationY: closeDuration
    property real openStartTimeY: 0
    property real accumDeltaY: 0
    property bool wasOpenYAtBegin: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1

    // Bug fix: only the area the panels/tab currently occupy accepts
    // clicks. Without this, the (invisible/transparent) full-screen window
    // would eat all clicks even where nothing is drawn. The mask follows
    // each item's real geometry, so anywhere none of them are currently
    // drawn, clicks pass straight through to the windows behind it.
    mask: Region {
        item: panelContent
        Region { item: topPanelContent }
        Region { item: cornerTab }
    }

    Rectangle {
        id: panelContent

        // The right edge stays glued to the display edge at all times.
        // Only the width (i.e. the left edge) animates, so a fast-release
        // bounce visibly stretches the panel past panelWidth instead of
        // sliding the whole shape left and detaching the right edge from
        // the screen border.
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        width: Math.max(0, root.panelWidth - root.currentX)
        color: "transparent"

        Behavior on width {
            enabled: !root.isDraggingX
            NumberAnimation {
                duration: root.settleDurationX
                easing.type: Easing.OutBack
                easing.overshoot: root.bounceOvershootX
            }
        }

        RightPanel {}
    }

    Rectangle {
        id: topPanelContent

        // The top-right corner stays glued to the display edges at all
        // times. Only the height (i.e. the bottom edge) animates, so a
        // fast-release bounce visibly stretches the panel past panelHeight
        // instead of sliding the whole shape down and detaching the top
        // edge from the screen border.
        anchors {
            top: parent.top
            right: parent.right
        }

        width: root.topPanelWidth
        height: Math.max(0, root.panelHeight - root.currentY)
        color: "transparent"

        Behavior on height {
            enabled: !root.isDraggingY
            NumberAnimation {
                duration: root.settleDurationY
                easing.type: Easing.OutBack
                easing.overshoot: root.bounceOvershootY
            }
        }

        TopPanel {}
    }

    // Always-out tab. Declared last, so it paints in front of both sliding
    // panels. x tracks the right panel's current left edge, y tracks the
    // top panel's current bottom edge - each is a live binding, so this
    // tracks dragging AND the spring bounce automatically, no extra
    // animation needed here.
    Rectangle {
        id: cornerTab

        x: panelContent.x - width + root.seamOverlap
        y: Math.max(0, topPanelContent.height - root.seamOverlap)

        width: root.cornerTabWidth
        height: root.cornerTabHeight
        color: "transparent"

        // Sem vlož obsah "úchytu" (ikona, label...)
        Time {}
    }

    // Single combined handler: a diagonal-ish gesture can drive both
    // panels at once (see bounce_script.py, which always forwards both
    // dx and dy together), so both axes are updated from one "update"
    // call and reconciled together in "end" instead of two independent
    // handlers racing each other.
    IpcHandler {
        target: "panels"

        // Shared by both axes' "open" branch below: how hard/fast the
        // gesture was determines the OutBack overshoot amplitude - see
        // openAnim.js for the curve/cap explanations.
        function bounceOvershootFor(absVel: real, maxOverdrag: real): real {
            let velNorm = Math.min(absVel / root.velocityCap, 1.0);
            let dragNorm = Math.min(maxOverdrag / root.overdragCap, 1.0);
            let intensity = Math.max(velNorm, dragNorm);
            return Math.pow(intensity, root.bounceCurveExponent) * root.maxOvershoot;
        }

        function begin(): void {
            root.isDraggingX = true;
            root.isDraggingY = true;
            root.maxOverdragX = 0;
            root.maxOverdragY = 0;
            root.openStartTimeX = 0;
            root.openStartTimeY = 0;
            root.accumDeltaX = 0;
            root.accumDeltaY = 0;
            // Snapshot of each panel's resting state before this gesture
            // touches anything - see end() for why this matters more than
            // the live (noise-prone) position.
            root.wasOpenXAtBegin = root.currentX < root.panelWidth / 2;
            root.wasOpenYAtBegin = root.currentY < root.panelHeight / 2;
        }

        function update(dxStr: string, dyStr: string): void {
            if (!root.isDraggingX && !root.isDraggingY)
                return;

            let dx = parseFloat(dxStr);
            let dy = parseFloat(dyStr);

            // Record which axis first showed *real* movement this gesture,
            // so end() can tell "genuinely being dragged" apart from
            // incidental cross-axis noise (a real single-axis flick is
            // rarely perfectly axis-aligned). Accumulate the raw delta
            // rather than checking each sample individually, since noise
            // stays small sample-to-sample but a real drag/flick quickly
            // blows past the threshold.
            root.accumDeltaX += dx;
            root.accumDeltaY += dy;
            if (root.openStartTimeX === 0 && Math.abs(root.accumDeltaX) > root.axisTouchThreshold)
                root.openStartTimeX = Date.now();
            if (root.openStartTimeY === 0 && Math.abs(root.accumDeltaY) > root.axisTouchThreshold)
                root.openStartTimeY = Date.now();

            let targetX = root.currentX + dx;
            if (targetX < 0) {
                let overdrag = targetX;
                root.currentX = Math.max(root.minX, overdrag * 0.3);
                root.maxOverdragX = Math.max(root.maxOverdragX, Math.abs(overdrag));
            } else if (targetX > root.panelWidth) {
                let overdrag = targetX - root.panelWidth;
                root.currentX = Math.min(root.maxX, root.panelWidth + overdrag * 0.3);
                root.maxOverdragX = Math.max(root.maxOverdragX, Math.abs(overdrag));
            } else {
                root.currentX = targetX;
            }

            // Downward swipe (dy > 0, libinput convention) pulls the panel
            // out from the top edge, so it decreases currentY toward 0
            // (open) - the mirror image of the X handling above.
            let targetY = root.currentY - dy;
            if (targetY < 0) {
                let overdrag = targetY;
                root.currentY = Math.max(root.minY, overdrag * 0.3);
                root.maxOverdragY = Math.max(root.maxOverdragY, Math.abs(overdrag));
            } else if (targetY > root.panelHeight) {
                let overdrag = targetY - root.panelHeight;
                root.currentY = Math.min(root.maxY, root.panelHeight + overdrag * 0.3);
                root.maxOverdragY = Math.max(root.maxOverdragY, Math.abs(overdrag));
            } else {
                root.currentY = targetY;
            }
        }

        function end(velXStr: string, velYStr: string): void {
            root.isDraggingX = false;
            root.isDraggingY = false;

            let velX = parseFloat(velXStr || "0");
            let velY = parseFloat(velYStr || "0");
            let absVelX = Math.abs(velX);
            let absVelY = Math.abs(velY);

            // currentX = 0 is fully open (width = panelWidth), currentX =
            // panelWidth is fully closed (width = 0). Positive dx/velocity
            // moves currentX toward panelWidth, i.e. closing. Mirrored for Y.
            //
            // A fast enough flick decides open/closed by its direction, so
            // a quick small flick fully opens/closes the panel even though
            // it barely crossed the halfway point. Otherwise fall back to
            // whether current* has passed the openDragFraction threshold.
            let openThresholdX = root.panelWidth * (1 - root.openDragFraction);
            let wantOpenX = absVelX > root.flickVelocityThreshold ? velX < 0 : root.currentX < openThresholdX;

            let openThresholdY = root.panelHeight * (1 - root.openDragFraction);
            let wantOpenY = absVelY > root.flickVelocityThreshold ? velY > 0 : root.currentY < openThresholdY;

            // Only one panel can end up open. wantOpenX/Y above is trivially
            // true for whichever axis was ALREADY open, regardless of what
            // this gesture actually did to it (its position simply never
            // left "open" territory) - comparing that directly against a
            // noise-prone "was this axis touched" flag caused inconsistent
            // switching. Instead: whichever axis wasn't already open before
            // this gesture always wins if it now wants to open, so a fresh
            // flick/drag reliably switches panels regardless of how little
            // the resting-open axis moved. Only when NEITHER was open to
            // start with (both dragged from closed - a genuine diagonal
            // open race) do we fall back to comparing how far each got,
            // with "started moving first" as a tie-break.
            if (!root.wasOpenXAtBegin && root.wasOpenYAtBegin) {
                if (wantOpenX)
                    wantOpenY = false;
            } else if (root.wasOpenXAtBegin && !root.wasOpenYAtBegin) {
                if (wantOpenY)
                    wantOpenX = false;
            } else if (!root.wasOpenXAtBegin && !root.wasOpenYAtBegin && wantOpenX && wantOpenY) {
                let openFracX = 1 - root.currentX / root.panelWidth;
                let openFracY = 1 - root.currentY / root.panelHeight;
                let xWins;
                if (openFracX !== openFracY) {
                    xWins = openFracX > openFracY;
                } else {
                    let startX = root.openStartTimeX || Infinity;
                    let startY = root.openStartTimeY || Infinity;
                    xWins = startX <= startY;
                }
                if (xWins)
                    wantOpenY = false;
                else
                    wantOpenX = false;
            }

            if (wantOpenX) {
                // Bounce only on open, never on close (see below) - and
                // only ever overshoots once before settling (OutBack).
                root.bounceOvershootX = bounceOvershootFor(absVelX, root.maxOverdragX);
                root.settleDurationX = root.openDuration;
                root.currentX = 0;
            } else {
                // Closing never bounces/overshoots, regardless of speed.
                root.bounceOvershootX = 0;
                root.settleDurationX = root.closeDuration;
                root.currentX = root.panelWidth;
            }

            if (wantOpenY) {
                root.bounceOvershootY = bounceOvershootFor(absVelY, root.maxOverdragY);
                root.settleDurationY = root.openDuration;
                root.currentY = 0;
            } else {
                root.bounceOvershootY = 0;
                root.settleDurationY = root.closeDuration;
                root.currentY = root.panelHeight;
            }
        }
    }
}