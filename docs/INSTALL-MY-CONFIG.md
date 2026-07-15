# Installing your personal config

This covers putting the generated configs in `my-config/` (`ap0g33.lua` and `hyprpaper.conf`) onto a running AP0G33 system.

## 1. Install the apps the config expects

The config autostarts / binds to these — install them before your first launch so nothing silently fails:

```bash
sudo apt install kitty wofi waybar mako-notifier hyprpaper thunar firefox \
    grim slurp wl-clipboard playerctl brightnessctl
```

Notes:

- `mako-notifier` is the Debian/Kali package name for the `mako` notification daemon.
- Volume keys use `wpctl` (WirePlumber, part of PipeWire) — install `wireplumber` if it's not already pulled in as part of your audio stack.
- `cliphist` (clipboard history, bound via `wl-paste --watch cliphist store`) is optional — skip installing it and delete that autostart line in `ap0g33.lua` if you don't want it.

## 2. Copy the config files into place

From a clone of this repo, on the machine actually running AP0G33:

```bash
mkdir -p ~/.config/ap0g33 ~/.config/hypr
cp my-config/ap0g33.lua    ~/.config/ap0g33/ap0g33.lua
cp my-config/hyprpaper.conf ~/.config/hypr/hyprpaper.conf
```

`ap0g33.lua` goes under `~/.config/ap0g33/` (AP0G33's own config dir). `hyprpaper.conf` goes under `~/.config/hypr/` because that's where the `hyprpaper` binary itself looks, regardless of which compositor launched it.

## 3. Add your wallpaper

`hyprpaper.conf` points at `~/Pictures/walpaper.jpg` — put your image there (rename it to match, or edit the two paths in the file to match your actual filename):

```bash
mkdir -p ~/Pictures
cp /path/to/your/image.jpg ~/Pictures/walpaper.jpg
```

## 4. Apply it

If AP0G33 isn't running yet, just launch it (see the TTY guide above) — it reads `ap0g33.lua` on startup and the autostart block will bring up `waybar`, `mako`, and `hyprpaper` for you.

If AP0G33 is already running, reload without restarting:

```bash
ap0g33ctl reload
```

`hyprpaper` doesn't reload with `ap0g33ctl reload` — if you change `hyprpaper.conf` while it's already running, restart it:

```bash
pkill hyprpaper && hyprpaper &
```

## 5. Verify

```bash
ap0g33ctl configerrors     # should print nothing if the config parsed cleanly
ap0g33ctl binds             # confirm your keybinds loaded
```

If something didn't autostart, check the log:

```bash
ap0g33ctl rollinglog -f
```
