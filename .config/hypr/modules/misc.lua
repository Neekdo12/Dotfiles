hl.config({
    debug = {
        disable_logs = true,
    },
    xwayland = {
        enabled = false,
    },
    cursor = {
        no_hardware_cursors = true,
    },
    misc = {
        vrr = 0,
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        disable_splash_rendering = true,
        disable_watchdog_warning = true,
    },
    input = {
        repeat_delay = 350,
        repeat_rate = 40,
        sensitivity = -1,
        touchpad = {
        scroll_factor = 0.7
        }
    }
})