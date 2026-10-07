-- ==============================================================================
-- Hyprland Configuration with Dynamic Wallpaper Colors & Modern Blur/Transparency
-- Migrated to Hyprland 0.55+ Lua format
-- ==============================================================================

-- Source dynamically generated colors
local colors = {
    accent = "rgba(8fc70bee)",
    accent2 = "rgba(83bc08ee)",
    accent_inactive = "rgba(25253555)",
    bg = "rgba(000000ee)",
}

local ok, loaded_colors = pcall(require, "colors")
if ok and type(loaded_colors) == "table" then
    colors = loaded_colors
end

-- Monitor Configuration
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})

-- Set programs that you use
local terminal    = "foot"
local fileManager = "nautilus"
local browser     = "google-chrome-stable"
local menu        = "pkill rofi || rofi -show drun"

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11,*")

-- Input Configuration, Layout, Decor, Animations
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },

    -- General Layout & Borders
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { colors.accent, colors.accent2 }, angle = 45 },
            inactive_border = colors.accent_inactive,
        },
        layout = "dwindle",
        allow_tearing = false,
    },

    -- Decoration: Rounding, Transparency, Shadows and Blur
    decoration = {
        rounding = 12,
        active_opacity   = 0.95,
        inactive_opacity = 0.88,
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            noise             = 0.02,
            contrast          = 1.05,
            brightness        = 0.9,
            vibrancy          = 0.35,
        },
        shadow = {
            enabled        = true,
            range          = 15,
            render_power   = 3,
            color          = "rgba(00000088)",
            color_inactive = "rgba(00000044)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

-- Bezier curves & animations
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.13, 0.99 }, { 0.29, 1.1 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4, bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "myBezier", style = "slide" })

-- Window rules for Opacity, Blur & Floating
hl.window_rule({ match = { class = "foot" },            opacity = "0.82 0.75" })
hl.window_rule({ match = { class = "kitty" },           opacity = "0.82 0.75" })
hl.window_rule({ match = { class = "Alacritty" },       opacity = "0.82 0.75" })
hl.window_rule({ match = { class = "nautilus" },        opacity = "0.90 0.82" })
hl.window_rule({ match = { class = "thunar" },          opacity = "0.90 0.82" })
hl.window_rule({ match = { class = "rofi" },            opacity = "0.88 0.80" })

hl.window_rule({ match = { class = "float-term" },      float = true, size = "950 550", center = true })
hl.window_rule({ match = { class = "pavucontrol" },     float = true, size = "700 450" })
hl.window_rule({ match = { class = "blueman-manager" }, float = true, size = "700 450" })

-- Autostart essential daemons
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar &")
    hl.exec_cmd("~/.config/hypr/scripts/wall.sh --restore &")
    hl.exec_cmd("dunst || mako &")
    hl.exec_cmd("~/.config/hypr/scripts/layout_notify.sh &")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/polkit-kde-authentication-agent-1 &")
end)

-- Keybindings
local mainMod = "SUPER"

-- Applications
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))
hl.bind("SUPER + SUPER_L",      hl.dsp.exec_cmd(menu), { release = true })
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Screen Lock (Hyprlock) & Power Menu
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("~/.config/hypr/scripts/powermenu.sh"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("~/.config/hypr/scripts/powermenu.sh"))

-- Random Wallpaper / Dynamic Theme Switcher
hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd("~/.config/hypr/scripts/wall.sh --random"))

-- Terminal tools popup (Cava, Cmatrix, Btop)
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("foot --app-id=float-term btop"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("foot --app-id=float-term cava"))
hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd("foot --app-id=float-term cmatrix"))

-- Audio controls
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ || pamixer -i 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- || pamixer -d 5"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle || pamixer -t"),         { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),                     { locked = true })

-- Brightness controls
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Media Player controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind("Print",                   hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy && notify-send "Скриншот скопирован" || true]]))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy && notify-send "Скриншот скопирован" || true]]))

-- Focus movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces
for i = 1, 6 do
    hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
