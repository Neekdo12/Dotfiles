-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
	output = "eDP-1",
	mode = "2560x1600@144",
	position = "0x0",
	scale = "2",
	vrr = 0,
})

-- Explicitly disable inactive external outputs to bypass pipeline evaluation
hl.monitor({ output = "DP-1", disabled = true })
hl.monitor({ output = "DP-2", disabled = true })
hl.monitor({ output = "HDMI-A-1", disabled = true })

hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "4", persistent = true })
hl.workspace_rule({ workspace = "5", persistent = true })

