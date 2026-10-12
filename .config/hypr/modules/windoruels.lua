-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.layer_rule({
    name = "rofi-popup",
    match = {namespace = 'rofi'},
    animation = 'slide bottom',
    dim_around = true
})

hl.layer_rule({
    name = 'notifications-animation',
    match = {namespace = 'swaync-control-center'},
    animation = 'slide top'
})

-- Transparent terminal on sratch workspace
hl.window_rule({
    match = {
        class = "^kitty-magic$",
    },
    opacity = "0.5 0.5",
    no_blur = true
})

-- Satty floaty and position
-- hl.window_rule({
--     match = { class = "^(com.gabm.satty)$" },
--     float = true,
--     monitor = "cursor",
--     center = true,
--     size = {"(monitor_w*0.5)", "(monitor_h*0.5)"}
-- })

-- Satty floaty and position
hl.window_rule({
    match = { 
        title = "satty-screenshot" 
    },
    float = true,
    monitor = "cursor",
    center = true,
    size = {"(monitor_w*0.5)", "(monitor_h*0.5)"},
    workspace = "special:satty_term"
})

-- Network and bluthoot config
hl.window_rule({
    match = {
        class = "^kitty-config",
    },
    center = true,
    float = true,
    size = {"(monitor_w*0.4)", "(monitor_h*0.4)"},
})

hl.window_rule({
    match = {
        title = "lern"
    },
    workspace = 1,
})