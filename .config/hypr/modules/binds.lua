-- Set programs that you use
local terminal = "kitty"
local transparent_terminal = "kitty --class kitty-magic"
local fileManager = "kitty -e env EDITOR=code yazi"
local menu = "./.config/rofi/type-2/launcher.sh"
local browser = "zen-browser"
local editor = "code"
local clipboard_manager =
	"cliphist list | rofi -dmenu -theme $HOME/.config/rofi/type-1/style-3.rasi | cliphist decode | wl-copy && wtype -M ctrl v"
local calculator = "rofi -show calc -modi calc -no-show-match -no-sort -theme $HOME/.config/rofi/type-1/style-3.rasi"

-- resizing windows
local step = 50

-- Binds
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- Aps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(calculator))

-- Window managmet
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + Q", hl.dsp.window.kill())
-- hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + A", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + slash", hl.dsp.window.float())
-- Launch a completely fresh instance of the focused app (Just like Rofi)
hl.bind(
	"SUPER + S",
	hl.dsp.exec_cmd(
		[[bash -c 'class=$(hyprctl activewindow -j | jq -r ".class"); gtk-launch "$class" 2>/dev/null || gtk-launch "${class,,}" 2>/dev/null || exec "${class,,}"']]
	)
)

-- Misc
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(clipboard_manager))
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("hyprlock"))

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))
hl.bind(
	"SHIFT + PRINT",
	hl.dsp.exec_cmd("hyprshot -m output -m active --raw | satty --filename -")
)
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window --raw | satty --filename -"))

-- Move and resize winows
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -step, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = step, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -step, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = step, relative = true }), { repeating = true })

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CONTROL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CONTROL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CONTROL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.window.move({ direction = "right" }))

-- hl.bind(mainMod .. " + [", hl.dsp.focus({workspace = }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad) - with transparent terminal
-- hl.bind("SUPER + S", function()
--     hl.dispatch(hl.dsp.focus({ workspace = "special:magic" }))
--     hl.dispatch(hl.dsp.exec_cmd(transparent_terminal))
-- end)

-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- hl.bind("mouse:272", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("swayosd-client --brightness raise"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --brightness lower"),
	{ locked = true, repeating = true }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
