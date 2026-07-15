#pragma once

#include <string_view>

// AP0G33: the shipped Tokyo Night config, generated on first launch when no
// config exists. Keep in sync with config/ap0g33/ap0g33.conf (same content).
inline constexpr std::string_view EXAMPLE_CONFIG = R"#(# ============================================================================
#  AP0G33 — pre-patched config (Tokyo Night)
#  Docs: https://wiki.hypr.land/ (all Hyprland options apply 1:1)
#  Installed to ~/.config/ap0g33/ap0g33.conf
# ============================================================================

# ---------------------------------------------------------------- monitors
monitor = , preferred, auto, 1

# ------------------------------------------------------------- environment
env = XCURSOR_SIZE, 24
env = QT_QPA_PLATFORM, wayland;xcb
env = QT_WAYLAND_DISABLE_WINDOWDECORATION, 1
env = GDK_BACKEND, wayland,x11,*
env = MOZ_ENABLE_WAYLAND, 1
# system-wide themed configs (waybar/kitty read these; ~/.config overrides win)
env = XDG_CONFIG_DIRS, /usr/local/share/ap0g33/xdg:/etc/xdg

# ---------------------------------------------------------------- autostart
# tools use your ~/.config if present, otherwise the shipped AP0G33 theme
$sys = /usr/local/share/ap0g33
exec-once = waybar
exec-once = [ -f "$HOME/.config/hypr/hyprpaper.conf" ] && hyprpaper || hyprpaper -c $sys/hypr/hyprpaper.conf
exec-once = [ -f "$HOME/.config/mako/config" ] && mako || mako -c $sys/mako/config
exec-once = [ -f "$HOME/.config/hypr/hypridle.conf" ] && hypridle || hypridle --config $sys/hypr/hypridle.conf
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = command -v mate-polkit >/dev/null && /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 || true

# ---------------------------------------------------- Tokyo Night palette
# bg        #1a1b26   bg-dark  #16161e   fg      #c0caf5
# blue      #7aa2f7   purple   #bb9af7   cyan    #7dcfff
# green     #9ece6a   red      #f7768e   orange  #ff9e64
# yellow    #e0af68   comment  #565f89

general {
    gaps_in = 4
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(7aa2f7ee) rgba(bb9af7ee) 45deg
    col.inactive_border = rgba(565f89aa)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 8
    active_opacity = 1.0
    inactive_opacity = 0.96

    blur {
        enabled = true
        size = 6
        passes = 3
        vibrancy = 0.17
    }

    shadow {
        enabled = true
        range = 12
        render_power = 3
        color = rgba(16161eb0)
    }
}

# ------------------------------------------------------------- VM MODE ----
# Running in a VM (VirtualBox/VMware/QEMU)? Blur and shadows are expensive
# without a real GPU. Uncomment this block:
# decoration {
#     blur { enabled = false }
#     shadow { enabled = false }
# }
# animations { enabled = false }
# ---------------------------------------------------------------------------

animations {
    enabled = true

    bezier = ap0g33, 0.05, 0.9, 0.1, 1.05
    bezier = easeOut, 0.16, 1, 0.3, 1

    animation = windows, 1, 5, ap0g33
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, default
    animation = fade, 1, 6, default
    animation = workspaces, 1, 5, easeOut, slide
}

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}

dwindle {
    preserve_split = true
}

misc {
    disable_hyprland_logo = true
    force_default_wallpaper = 0
    focus_on_activate = true
}

# ----------------------------------------------------------------- keybinds
$mod  = SUPER
$term = kitty
$menu = wofi --show drun --conf $sys/wofi/config --style $sys/wofi/style.css

# core
bind = $mod, Q, exec, $term
bind = $mod, R, exec, $menu
bind = $mod, C, killactive,
bind = $mod, M, exit,
bind = $mod, E, exec, $term -e btop
bind = $mod, F, fullscreen,
bind = $mod, V, togglefloating,
bind = $mod, P, pseudo,
bind = $mod, T, layoutmsg, togglesplit
bind = $mod, ESCAPE, exec, [ -f "$HOME/.config/hypr/hyprlock.conf" ] && hyprlock || hyprlock --config $sys/hypr/hyprlock.conf

# focus: arrows + vim hjkl
bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d
bind = $mod, H, movefocus, l
bind = $mod, J, movefocus, d
bind = $mod, K, movefocus, u
bind = $mod, L, movefocus, r

# move window: vim hjkl
bind = $mod SHIFT, H, movewindow, l
bind = $mod SHIFT, J, movewindow, d
bind = $mod SHIFT, K, movewindow, u
bind = $mod SHIFT, L, movewindow, r

# resize with mod + right hand
bind = $mod ALT, H, resizeactive, -40 0
bind = $mod ALT, L, resizeactive, 40 0
bind = $mod ALT, K, resizeactive, 0 -40
bind = $mod ALT, J, resizeactive, 0 40

# workspaces
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10
bind = $mod, mouse_down, workspace, e+1
bind = $mod, mouse_up, workspace, e-1
bind = $mod, S, togglespecialworkspace, magic
bind = $mod SHIFT, S, movetoworkspace, special:magic

# mouse drag
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

# clipboard history
bind = $mod SHIFT, V, exec, cliphist list | wofi --dmenu --conf $sys/wofi/config --style $sys/wofi/style.css | cliphist decode | wl-copy

# screenshots
bind = , Print, exec, mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png | wl-copy && notify-send "AP0G33" "Region captured"
bind = SHIFT, Print, exec, mkdir -p ~/Pictures/Screenshots && grim - | tee ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png | wl-copy && notify-send "AP0G33" "Screen captured"

# media / volume / brightness
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# ------------------------------------------------------------- window rules
windowrule = float, class:(pavucontrol|nm-connection-editor|blueman-manager)
windowrule = float, title:(Open File|Save File|Open Folder)
windowrule = suppressevent maximize, class:.*
)#";
