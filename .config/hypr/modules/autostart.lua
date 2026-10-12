-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
local zen_windows = {}

hl.on("hyprland.start", function()
	hl.exec_cmd("python3 .config/quickshell/bounce_script.py")
	hl.exec_cmd("qs")
	hl.exec_cmd("swaync")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("hyprctl setcursor macOS 24")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("hypridle")
end)

hl.on("window.open", function(w)
	if w.class == "zen" then
		table.insert(zen_windows, w)
	end
end)

hl.on("window.close", function(w)
	for i, win in ipairs(zen_windows) do
		if win == w then
			table.remove(zen_windows, i)
			break
		end
	end
end)

hl.on("hyprland.shutdown", function()
	for i = 2, #zen_windows do
		hl.dispatch(hl.dsp.window.close({ window = zen_windows[i] }))
	end
end)
