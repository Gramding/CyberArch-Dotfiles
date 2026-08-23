local cyberpunk = os.getenv("HOME") .. "/.config/hypr/themes/cyberpunk"

-- MOD drives the window-management binds (ported from a niri config, where mod-key was "Alt").
-- Set this to "SUPER" if Alt starts fighting with application shortcuts — Alt+Tab, Alt+F4 and the
-- Alt+<letter> menu mnemonics in GTK/Qt apps all live on this key. One edit, every bind follows.
local MOD       = "ALT"

-- themeMod carries the HUD binds and must stay clear of MOD's modifier combinations. With MOD=ALT
-- that's SUPER+SHIFT; with MOD=SUPER it has to move, because MOD+SHIFT+<key> would otherwise land
-- on top of it — SUPER+SHIFT+E would mean both "read notifications" and "quit Hyprland".
local themeMod  = (MOD == "SUPER") and "SUPER + ALT" or "SUPER + SHIFT"

-- Same reason: the orca toggle sits on SUPER+ALT, which becomes themeMod when MOD is SUPER.
local orcaKey   = (MOD == "SUPER") and "CTRL + ALT + S" or "SUPER + ALT + S"
local augSock   = os.getenv("XDG_RUNTIME_DIR") .. "/astal/cyberpunk.sock"
local TERM      = "rio"
local TERMFLOAT = "rio"

local once = function(cmd)
    hl.on("hyprland.start", function()
        hl.exec_cmd(cmd)
    end)
end

--------------------------------------------------------------------------------
-- MONITORS
--------------------------------------------------------------------------------
-- Ported from niri. Positions are logical (post-scale) pixels; Hyprland transforms are
-- 0=normal 1=90 2=180 3=270, so niri's transform "270" becomes transform 3.
--
--   DP-1      1920x1080  left    x=-1920   normal
--   HDMI-A-1  3840x2160  middle  x=0       normal, scale 1
--   DP-2      1920x1080  right   x=3840    rotated 270 (portrait)
--
-- Kept here rather than in hyprland.lua on purpose: install.sh truncates hyprland.lua with a
-- `>` redirect when it detects another shell (it matches on ~/.config/caelestia), which would
-- wipe a monitor block living there. This file is on the far side of the `require("theme")`,
-- so it survives that.
local monitors = {
    "DP-1,1920x1080@60,-1920x0,1",
    "HDMI-A-1,3840x2160@59.997,0x0,1",
    "DP-2,1920x1080@60,3840x0,1,transform,3",
}

local function monitors_via_hyprctl()
    for _, m in ipairs(monitors) do
        once('hyprctl keyword monitor "' .. m .. '"')
    end
end

-- Set this to true if the layout doesn't apply on login. The pcall below catches an hl.monitor
-- that doesn't exist, but not one that exists as a silent no-op — if your build swallows unknown
-- keywords, nothing errors and nothing happens either. This flag forces the hyprctl path.
-- Verify which happened with:  hyprctl monitors -j | jq -r '.[] | "\(.name) \(.x)x\(.y)"'
local MONITORS_VIA_HYPRCTL = false

if MONITORS_VIA_HYPRCTL then
    monitors_via_hyprctl()
elseif not pcall(function()
    for _, m in ipairs(monitors) do hl.monitor(m) end
end) then
    monitors_via_hyprctl()
end

hl.exec_cmd("killall -9 waybar mako dunst swaync 2>/dev/null; systemctl --user stop waybar mako dunst swaync 2>/dev/null || true")
hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/ags quit -i cyberpunk 2>/dev/null")
hl.exec_cmd("sleep 1 && " .. cyberpunk .. "/scripts/launch-theme")
hl.exec_cmd(cyberpunk .. "/scripts/ws pin")
hl.exec_cmd("awww img " .. os.getenv("HOME") .. "/.config/hypr/themes/cyberpunk/assets/img/lucy_wallpaper.png")
once(cyberpunk .. "/components/login/lock.sh")

hl.exec_cmd("mkdir -p " .. os.getenv("HOME") .. "/.config/kitty && ln -sfn " .. cyberpunk .. "/assets/kitty/kitty.conf " .. os.getenv("HOME") .. "/.config/kitty/kitty.conf")
hl.exec_cmd("mkdir -p " .. os.getenv("HOME") .. "/.local/share/icons && ln -sfn " .. cyberpunk .. "/assets/gtk/iconpack " .. os.getenv("HOME") .. "/.local/share/icons/iconpack")
hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'iconpack'")
hl.exec_cmd("ln -sfn " .. cyberpunk .. "/assets/cursor " .. os.getenv("HOME") .. "/.local/share/icons/neurodance")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'neurodance'")
hl.exec_cmd("hyprctl setcursor neurodance 48")
hl.env("XCURSOR_THEME", "neurodance")
hl.env("XCURSOR_SIZE", "48")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
once(cyberpunk .. "/scripts/apply_theme")
once("mkdir -p " .. os.getenv("HOME") .. "/.config/Kvantum/Daemon && cp -f " .. cyberpunk .. "/assets/gtk/DaemonKvantum/Daemon.kvconfig " .. os.getenv("HOME") .. "/.config/Kvantum/Daemon/Daemon.kvconfig && cp -f " .. cyberpunk .. "/assets/gtk/DaemonKvantum/Daemon.svg " .. os.getenv("HOME") .. "/.config/Kvantum/Daemon/Daemon.svg && echo '[General]' > " .. os.getenv("HOME") .. "/.config/Kvantum/kvantum.kvconfig && echo 'theme=Daemon' >> " .. os.getenv("HOME") .. "/.config/Kvantum/kvantum.kvconfig")

local sock = function(msg)
    return hl.dsp.exec_cmd('echo "' .. msg .. '" | socat - UNIX-CONNECT:' .. augSock)
end

--------------------------------------------------------------------------------
-- PROGRAMS  (niri: spawn / spawn-sh)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + T", hl.dsp.exec_cmd(TERM))                                      -- niri Mod+T
hl.bind(MOD .. " + D", hl.dsp.exec_cmd(cyberpunk .. "/scripts/launcher"))          -- niri Mod+D (fuzzel)
hl.bind(MOD .. " + E", hl.dsp.exec_cmd("kitty -e spf"))                            -- niri Mod+E
hl.bind(MOD .. " + M", hl.dsp.exec_cmd("sh " .. os.getenv("HOME") .. "/Desktop/mount.sh"))
hl.bind(MOD .. " + L", hl.dsp.exec_cmd(cyberpunk .. "/components/login/lock.sh"))  -- niri Mod+L
hl.bind(MOD .. " + P", sock("modal pwr"))                                          -- niri Mod+P (powermenu)
hl.bind(orcaKey, hl.dsp.exec_cmd("pkill orca || exec orca"))

-- Stock-rice extras, kept so the launcher and peek stay reachable without MOD. Skipped when
-- MOD is SUPER, or these would land on the same keys as MOD+Tab / MOD+D with different actions.
if MOD ~= "SUPER" then
    hl.bind("SUPER + TAB", hl.dsp.exec_cmd(cyberpunk .. "/scripts/launcher"))
    hl.bind("SUPER + D",   hl.dsp.exec_cmd(cyberpunk .. "/scripts/peek"))
end
hl.bind(themeMod .. " + Z", sock("toggle-hud"))
hl.bind(themeMod .. " + V", sock("modal vol"))
hl.bind(themeMod .. " + I", sock("modal brt"))
hl.bind(themeMod .. " + U", sock("modal aur"))
hl.bind(themeMod .. " + J", sock("aur-dismiss"))
hl.bind(themeMod .. " + M", sock("notif-hud"))
hl.bind(themeMod .. " + O", sock("player"))
hl.bind(themeMod .. " + N", sock("modal wifi"))
hl.bind(themeMod .. " + B", sock("modal bt"))
hl.bind(themeMod .. " + P", sock("modal pwr"))
hl.bind(themeMod .. " + W", sock("forecast"))
hl.bind(themeMod .. " + minus", sock("clock"))
hl.bind(themeMod .. " + G", sock("markets"))
hl.bind(themeMod .. " + Y", sock("modal bat"))
hl.bind(themeMod .. " + C", sock("modal sys"))
hl.bind(themeMod .. " + H", sock("modal keys"))
hl.bind(themeMod .. " + E", sock("notif-read"))
hl.bind(themeMod .. " + X", sock("notif-dismiss"))
hl.bind(themeMod .. " + R", hl.dsp.exec_cmd(cyberpunk .. "/scripts/screenrecord"))
hl.bind(themeMod .. " + T", hl.dsp.exec_cmd(cyberpunk .. "/scripts/terminal"))
hl.bind(themeMod .. " + S", hl.dsp.exec_cmd(cyberpunk .. "/scripts/screenshot"))

once(cyberpunk .. "/scripts/overkill prewarm")
hl.bind(themeMod .. " + K", hl.dsp.exec_cmd(cyberpunk .. "/scripts/overkill"))
hl.define_submap("kill", function()
    hl.bind("mouse:272", hl.dsp.exec_cmd(cyberpunk .. "/scripts/overkill kill"))
    hl.bind("escape", hl.dsp.exec_cmd(cyberpunk .. "/scripts/overkill exit"))
end)

hl.bind(themeMod .. " + L", hl.dsp.exec_cmd(cyberpunk .. "/components/login/lock.sh"))
hl.bind("CTRL + SHIFT + ALT + r", hl.dsp.exec_cmd(cyberpunk .. "/scripts/restart"))
hl.bind("SUPER + CTRL + Delete", hl.dsp.exec_cmd("hyprctl reload"))

--------------------------------------------------------------------------------
-- WINDOWS
--------------------------------------------------------------------------------
hl.bind(MOD .. " + Q", hl.dsp.window.close())                                       -- niri close-window
hl.bind(MOD .. " + V", hl.dsp.window.float({ action = "toggle" }))                   -- niri toggle-window-floating
hl.bind(MOD .. " + F", hl.dsp.window.fullscreen({ mode = "maximize" }))              -- niri maximize-column
hl.bind(MOD .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))    -- niri fullscreen-window
hl.bind(MOD .. " + C", hl.dsp.exec_cmd("hyprctl dispatch centerwindow"))             -- niri center-column (floating only)

hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------------------------------------------------------
-- FOCUS  (niri: focus-column-* / focus-window-*)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(MOD .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(MOD .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(MOD .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(MOD .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(MOD .. " + J",     hl.dsp.focus({ direction = "down" }))
hl.bind(MOD .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(MOD .. " + Tab",   hl.dsp.exec_cmd("hyprctl dispatch cyclenext"))            -- niri focus-column-right-or-first

--------------------------------------------------------------------------------
-- MOVE WINDOW  (niri: move-column-* / move-window-*)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(MOD .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(MOD .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(MOD .. " + CTRL + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + CTRL + J",     hl.dsp.window.move({ direction = "down" }))
hl.bind(MOD .. " + CTRL + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(MOD .. " + CTRL + L",     hl.dsp.window.move({ direction = "right" }))

--------------------------------------------------------------------------------
-- MONITORS  (niri: focus-monitor-* / move-column-to-monitor-*)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + SHIFT + left",  hl.dsp.exec_cmd("hyprctl dispatch focusmonitor l"))
hl.bind(MOD .. " + SHIFT + right", hl.dsp.exec_cmd("hyprctl dispatch focusmonitor r"))
hl.bind(MOD .. " + SHIFT + up",    hl.dsp.exec_cmd("hyprctl dispatch focusmonitor u"))
hl.bind(MOD .. " + SHIFT + down",  hl.dsp.exec_cmd("hyprctl dispatch focusmonitor d"))
hl.bind(MOD .. " + SHIFT + H",     hl.dsp.exec_cmd("hyprctl dispatch focusmonitor l"))
hl.bind(MOD .. " + SHIFT + J",     hl.dsp.exec_cmd("hyprctl dispatch focusmonitor d"))
hl.bind(MOD .. " + SHIFT + K",     hl.dsp.exec_cmd("hyprctl dispatch focusmonitor u"))
hl.bind(MOD .. " + SHIFT + L",     hl.dsp.exec_cmd("hyprctl dispatch focusmonitor r"))

hl.bind(MOD .. " + SHIFT + CTRL + left",  hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:l"))
hl.bind(MOD .. " + SHIFT + CTRL + right", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:r"))
hl.bind(MOD .. " + SHIFT + CTRL + up",    hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:u"))
hl.bind(MOD .. " + SHIFT + CTRL + down",  hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:d"))
hl.bind(MOD .. " + SHIFT + CTRL + H",     hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:l"))
hl.bind(MOD .. " + SHIFT + CTRL + L",     hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:r"))

--------------------------------------------------------------------------------
-- RESIZE  (niri: set-column-width / set-window-height ±10%)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + minus", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind(MOD .. " + equal", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }))
hl.bind(MOD .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
hl.bind(MOD .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 40,  relative = true }))

hl.bind("CTRL + SHIFT + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
hl.bind("CTRL + SHIFT + right", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }))
hl.bind("CTRL + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }))
hl.bind("CTRL + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 40, relative = true }))

--------------------------------------------------------------------------------
-- WORKSPACES
--------------------------------------------------------------------------------
-- niri stacks workspaces vertically per monitor; Hyprland's are flat and numbered, so
-- "up/down" becomes relative +1/-1. These go through hyprctl rather than scripts/ws because
-- that script only takes absolute workspace numbers.
hl.bind(MOD .. " + Page_Down", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind(MOD .. " + Page_Up",   hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))
hl.bind(MOD .. " + U",         hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind(MOD .. " + I",         hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))
hl.bind(MOD .. " + CTRL + Page_Down", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e+1"))
hl.bind(MOD .. " + CTRL + Page_Up",   hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e-1"))
hl.bind(MOD .. " + CTRL + U",         hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e+1"))
hl.bind(MOD .. " + CTRL + I",         hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace e-1"))

hl.bind(MOD .. " + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"), { mouse = true })
hl.bind(MOD .. " + mouse_up",   hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"), { mouse = true })

-- niri Mod+1..9 / Mod+Ctrl+1..9 — these keep the rice's ws script so per-monitor pinning holds
for i = 1, 10 do
    local key = i % 10
    hl.bind(MOD .. " + " .. key,        hl.dsp.exec_cmd(cyberpunk .. "/scripts/ws go " .. i))
    hl.bind(MOD .. " + CTRL + " .. key, hl.dsp.exec_cmd(cyberpunk .. "/scripts/ws move " .. i))
    if MOD ~= "SUPER" then
        hl.bind("SUPER + " .. key,      hl.dsp.exec_cmd(cyberpunk .. "/scripts/ws go " .. i))
    end
end

--------------------------------------------------------------------------------
-- SCREENSHOTS  (scripts/screenshot takes "full" for the active monitor, or nothing for region)
--------------------------------------------------------------------------------
hl.bind(MOD .. " + SHIFT + S", hl.dsp.exec_cmd(cyberpunk .. "/scripts/screenshot"))         -- niri screenshot
hl.bind(MOD .. " + CTRL + S",  hl.dsp.exec_cmd(cyberpunk .. "/scripts/screenshot full"))    -- niri screenshot-screen
hl.bind("Print",               hl.dsp.exec_cmd(cyberpunk .. "/scripts/screenshot"))
-- niri screenshot-window has no equivalent: the rice only does region + whole-monitor.

--------------------------------------------------------------------------------
-- MEDIA KEYS  (the stock rice binds none of these at all)
--------------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"))
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"))
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl --class=backlight set +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl --class=backlight set 10%-"))

--------------------------------------------------------------------------------
-- SESSION
--------------------------------------------------------------------------------
hl.bind(MOD .. " + SHIFT + P", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))   -- niri power-off-monitors
hl.bind(MOD .. " + SHIFT + E", hl.dsp.exec_cmd("hyprctl dispatch exit"))       -- niri quit
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind(MOD .. " + SHIFT + slash", sock("modal keys"))                         -- niri show-hotkey-overlay

--------------------------------------------------------------------------------
-- NOT PORTED — these are scrollable-tiling concepts with no Hyprland equivalent.
-- Left here as a record rather than faked with something that behaves differently.
--------------------------------------------------------------------------------
--   Mod+W                    toggle-overview            (needs the hyprexpo plugin)
--   Mod+BracketLeft/Right    consume-or-expel-window
--   Mod+Comma / Mod+Period   consume/expel-window-from-column
--   Mod+R / Mod+Shift+R      switch-preset-column-width / -window-height
--   Mod+Ctrl+R               reset-window-height
--   Mod+Ctrl+F               expand-column-to-available-width
--   Mod+Ctrl+C               center-visible-columns
--   Mod+Home / Mod+End       focus-column-first / -last
--   Mod+Shift+V              switch-focus-between-floating-and-tiling
--   Mod+Escape               toggle-keyboard-shortcuts-inhibit
-- Closest Hyprland analogue for the column/tab model is window groups:
--   hyprctl dispatch togglegroup / changegroupactive

hl.config({
    general = {
        border_size = 2,
        gaps_in  = 12,
        gaps_out = 24,
        col = {
            active_border   = { colors = { "rgba(ff2d3dff)", "rgba(ff6677ff)" }, angle = 45 },
            inactive_border = "rgba(ff2d3d44)",
        },
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            noise = 0.04,
        },
        shadow = {
            enabled = true,
            range = 8,
            render_power = 2,
            color = "rgba(ff2d3d55)",
            color_inactive = "rgba(ff2d3d22)",
            offset = { 0, 0 },
        },
        screen_shader = "",
    },
})

local barsfile = cyberpunk .. "/assets/cyberbars/hyprbars.so"
local barsfh = io.open(barsfile, "rb")
if barsfh then
    barsfh:close()
    hl.plugin.load(barsfile)
    hl.config({
        plugin = {
            hyprbars = {
                bar_height = 28,
                bar_color = "rgba(160409f2)",
                col = { text = "rgba(ff2d3dff)" },
                bar_text_size = 12,
                bar_text_font = "FiraCode Nerd Font",
                bar_part_of_window = true,
                bar_precedence_over_border = false,
                bar_padding = 12,
                bar_button_padding = 10,
                ["hyprbars-button"] = {
                    "rgb(ff2d3d), 15, \xEE\xAE\x8B, hyprctl dispatch killactive",
                    "rgb(ff2d3d), 14, \xEE\xAA\xB9, hyprctl dispatch fullscreen 1",
                    "rgb(ff2d3d), 14, \xEE\xAA\xB7, hyprctl dispatch movetoworkspacesilent special:minimized",
                },
            },
        },
    })
end

hl.layer_rule({ match = { namespace = "modal_.*" }, blur = true })

hl.window_rule({
    name        = "rio-terminal",
    match       = { class = "^(rio)$" },
    border_size = 0,
    no_shadow   = true,
    float       = true,
    size        = "1238 766",
    center      = true,
})

hl.window_rule({ match = { class = "^cool-retro-term$" },          float = true })
hl.window_rule({ match = { class = "^cool-retro-term$" },          center = true })
hl.window_rule({ match = { class = "^cool-retro-term$" },          size  = "60% 65%" })
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" },   float = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" },   center = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" },   size  = "60% 65%" })

local filewin = "^(File Upload|Save As|Save File|Save Image|Enter name of file|Open File|Open Files|Select File|Select Files|Choose.*[Ff]ile|Upload File).*$"
hl.window_rule({ match = { title = filewin }, float = true })
hl.window_rule({ match = { title = filewin }, center = true })
hl.window_rule({ match = { title = filewin }, size  = "60% 65%" })

local opwin = "^(Rename.*|Create New Folder|Create Folder|Create Document|Bulk Rename.*|Properties.*|Confirm to replace.*|File Operation.*|Permissions.*|Delete|Trash|Empty Trash)$"
hl.window_rule({ match = { title = opwin }, float = true })
hl.window_rule({ match = { title = opwin }, center = true })

hl.config({ animations = { enabled = true } })
hl.curve("swiftOut", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "swiftOut", style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4, bezier = "swiftOut", style = "slide left" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "swiftOut", style = "slide right" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "swiftOut", style = "slide" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4, bezier = "swiftOut" })
hl.animation({ leaf = "workspaces",  enabled = false })
hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "swiftOut", style = "fade" })
