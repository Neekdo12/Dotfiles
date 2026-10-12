#!/usr/bin/env python3
import os
import re
import subprocess
import time

TRACKED_FINGERS = "3"
TIMESTAMP_RE = re.compile(r"^[+-]?\d+\.\d+s$")

# Upper bound on how many "update" IPC calls we dispatch per second.
# Each call spawns a "qs" process, so this is the main resource-usage
# knob: touchpads can report well above 100 samples/sec, but the panel
# only needs to redraw at display refresh rate. Bursts of libinput
# events between dispatches are coalesced into a single accumulated delta.
UPDATE_HZ = 120
UPDATE_INTERVAL = 1.0 / UPDATE_HZ

# A gesture can be diagonal-ish, opening both panels at once, so every
# sample's dx AND dy are always forwarded together (to the single
# "panels" IPC target) - no more per-gesture axis locking. shell.qml
# decides at release time which panel (if only one can stay open) wins.

# Minimum |velocity| (libinput units/s) a direction reversal must reach
# before we treat it as an intentional "retract" rather than sensor
# noise around zero. Without this, reversing mid-drag (still one
# continuous gesture, fingers never lifted) would keep the stale peak
# velocity from the earlier opening motion, so release-time direction
# logic in QML would still see "fast open" and open the panel anyway
# even though the user visibly dragged it back.
REVERSAL_MIN_SPEED = 30.0

DEBUG = os.environ.get("BOUNCE_DEBUG") == "1"


def send_ipc(target: str, function: str, *args: float | str, wait: bool = True) -> None:
    """Invoke an IPC handler (target "panels") in Quickshell.

    wait=False fires the call without blocking on it, so the libinput
    read-loop never stalls waiting for "qs" to spawn/exit - important
    for keeping the drag feeling smooth under load.
    """
    cmd: list[str] = ["qs", "ipc", "call", target, function, *map(str, args)]
    try:
        if wait:
            subprocess.run(cmd, check=True, capture_output=not DEBUG)
        else:
            subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL if not DEBUG else None,
                stderr=subprocess.DEVNULL if not DEBUG else subprocess.STDOUT,
            )
        if DEBUG:
            print(f"[DEBUG] Odesláno do Quickshellu: {target} {function} {' '.join(map(str, args))}")
    except Exception as e:
        print(f"[DEBUG] Chyba při volání qs ipc: {e}")


def opposite_sign(a: float, b: float) -> bool:
    return a != 0 and b != 0 and (a > 0) != (b > 0)


is_swiping: bool = False
last_sample_time: float = 0.0   # last time we measured instantaneous velocity
last_send_time: float = 0.0     # last time an "update" was actually dispatched
velocity_x: float = 0.0
velocity_y: float = 0.0
peak_velocity_x: float = 0.0    # highest |velocity| seen this gesture per axis, reset
peak_velocity_y: float = 0.0    # on a genuine direction reversal (see REVERSAL_MIN_SPEED)
pending_dx: float = 0.0         # delta accumulated since the last dispatched "update"
pending_dy: float = 0.0


def main() -> None:
    global is_swiping, last_sample_time, last_send_time
    global velocity_x, velocity_y, peak_velocity_x, peak_velocity_y
    global pending_dx, pending_dy

    print("[DEBUG] Spouštím libinput debug-events. Udělej gesto 3 prsty...")

    try:
        proc = subprocess.Popen(
            ["libinput", "debug-events", "--udev", "seat0"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
    except FileNotFoundError:
        print("[ERROR] Příkaz 'libinput' nenalezen.")
        return

    assert proc.stdout is not None  # guaranteed by stdout=subprocess.PIPE above

    try:
        for line in proc.stdout:
            line = line.strip()
            if "GESTURE_SWIPE" not in line:
                continue

            parts = line.split()
            try:
                type_idx = next(i for i, p in enumerate(parts) if p.startswith("GESTURE_SWIPE_"))
                time_idx = next(i for i, p in enumerate(parts) if TIMESTAMP_RE.match(p))
            except StopIteration:
                continue

            event = parts[type_idx]
            if DEBUG:
                print(f"[LIBINPUT EVENT] {line}")

            fingers = parts[time_idx + 1] if len(parts) > time_idx + 1 else None

            if event == "GESTURE_SWIPE_BEGIN":
                if fingers == TRACKED_FINGERS:
                    is_swiping = True
                    velocity_x = 0.0
                    velocity_y = 0.0
                    peak_velocity_x = 0.0
                    peak_velocity_y = 0.0
                    pending_dx = 0.0
                    pending_dy = 0.0
                    last_sample_time = time.time()
                    last_send_time = 0.0
                    send_ipc("panels", "begin")

            elif event == "GESTURE_SWIPE_UPDATE" and is_swiping:
                if len(parts) > time_idx + 2:
                    now = time.time()
                    dt = now - last_sample_time

                    # libinput right-pads each axis to a fixed width, so a
                    # non-negative dy (no "-" to absorb the padding space)
                    # prints as e.g. "11.30/  0.00" - split() then breaks
                    # that into two whitespace tokens ("11.30/" and "0.00")
                    # instead of one. Reassemble them before parsing.
                    dxdy_str = parts[time_idx + 2]
                    if dxdy_str.endswith("/") and len(parts) > time_idx + 3:
                        dxdy_str += parts[time_idx + 3]
                    dx_str, dy_str = dxdy_str.split("/")
                    dx = float(dx_str)
                    dy = float(dy_str)

                    if dt > 0:
                        instant_vx = dx / dt
                        instant_vy = dy / dt
                        # light smoothing (biased toward the instant sample)
                        # so a short quick flick registers immediately
                        # instead of needing to sustain speed for a while
                        velocity_x = 0.85 * instant_vx + 0.15 * velocity_x
                        velocity_y = 0.85 * instant_vy + 0.15 * velocity_y

                        if opposite_sign(velocity_x, peak_velocity_x) and abs(velocity_x) > REVERSAL_MIN_SPEED:
                            # gesture reversed direction on this axis - drop
                            # the stale peak instead of letting it outlive
                            # the retract motion
                            peak_velocity_x = velocity_x
                        elif abs(velocity_x) > abs(peak_velocity_x):
                            peak_velocity_x = velocity_x

                        if opposite_sign(velocity_y, peak_velocity_y) and abs(velocity_y) > REVERSAL_MIN_SPEED:
                            peak_velocity_y = velocity_y
                        elif abs(velocity_y) > abs(peak_velocity_y):
                            peak_velocity_y = velocity_y
                    last_sample_time = now

                    pending_dx += dx
                    pending_dy += dy

                    # throttle: coalesce fast bursts into at most
                    # UPDATE_HZ dispatched "update" calls per second
                    if now - last_send_time >= UPDATE_INTERVAL:
                        send_ipc("panels", "update", pending_dx, pending_dy, wait=False)
                        pending_dx = 0.0
                        pending_dy = 0.0
                        last_send_time = now

            elif event == "GESTURE_SWIPE_END" and is_swiping:
                is_swiping = False
                # flush any not-yet-sent movement so the final position
                # QML decides open/closed from is exact
                if pending_dx != 0.0 or pending_dy != 0.0:
                    send_ipc("panels", "update", pending_dx, pending_dy)
                    pending_dx = 0.0
                    pending_dy = 0.0
                # use each axis' peak velocity, not just the value at
                # release, so a brief fast flick still bounces even if the
                # swipe slowed down before lifting fingers
                send_ipc("panels", "end", f"{peak_velocity_x:.2f}", f"{peak_velocity_y:.2f}")
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"[ERROR] Chyba libinput: {e}")
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
