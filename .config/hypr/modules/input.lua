hl.config({
	input = {
		kb_layout = "cz",
		kb_variant = "coder",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
		},
	},
})

hl.gesture({
	fingers = 4,
	direction = "horizontal",
	action = "workspace",
})

-- Přidej 4-prsté gesto pro aktivaci odchytávání v Hyprlandu

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
