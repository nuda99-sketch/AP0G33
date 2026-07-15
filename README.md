# AP0G33

**AP0G33** is a port of [Hyprland](https://github.com/hyprwm/Hyprland) — the dynamic tiling Wayland compositor — for **Debian-based distros**, targeting **Kali Rolling**.

Upstream Hyprland does not officially support Debian-based distros because their packaged toolchains and libraries lag behind what Hyprland requires. AP0G33 solves this with a bootstrap script that builds the required dependency stack from source where Kali's packages are too old, then builds and installs the compositor.

Based on Hyprland **0.55.0**.

## What's different from upstream

Full rebrand — AP0G33 names everywhere, with legacy compat shims so the Hyprland ecosystem keeps working:

| | AP0G33 (primary) | Legacy compat |
|---|---|---|
| Compositor binary | `AP0G33` | `Hyprland`, `hyprland` symlinks |
| Control tool | `ap0g33ctl` | `hyprctl` symlink |
| Plugin manager | `ap0g33pm` | `hyprpm` symlink |
| Launcher | `start-ap0g33` | `start-hyprland` symlink |
| Config | `~/.config/ap0g33/ap0g33.{lua,conf}` | `~/.config/hypr/` still read if present |
| Config env var | `AP0G33_CONFIG` | `HYPRLAND_CONFIG` still honored |
| IPC/runtime dir | `$XDG_RUNTIME_DIR/ap0g33` | `hypr` symlink created at startup |
| Instance env var | `AP0G33_INSTANCE_SIGNATURE` | `HYPRLAND_INSTANCE_SIGNATURE` also exported |
| Toggles | `AP0G33_NO_RT`, `AP0G33_TRACE`, ... | `HYPRLAND_*` equivalents still work |
| Desktop identity | `XDG_CURRENT_DESKTOP=AP0G33` | `ap0g33-portals.conf` + `hyprland-portals.conf` installed |
| Session entries | `ap0g33.desktop`, `ap0g33-uwsm.desktop` | — |
| Crash reports / logs | `~/.cache/ap0g33/`, `ap0g33.log` | — |

Because the instance signature is exported under both names and the legacy socket path is symlinked, waybar, wlogout, hyprpaper, xdg-desktop-portal-hyprland and plugins work unchanged.

Also: `install-kali.sh`, a one-shot build/install for Kali Rolling / Debian testing.

## Install (Kali Rolling)

```bash
git clone https://github.com/nuda99-sketch/AP0G33.git
cd AP0G33
sudo ./install-kali.sh
```

The script:

1. Installs build tools and library dev packages via `apt`
2. Version-checks core libs (`libinput`, `xkbcommon`, `wayland-protocols`, Lua) with `pkg-config` and builds from source only what's too old
3. Builds the hypr* stack from source: `hyprwayland-scanner`, `hyprutils`, `hyprlang`, `hyprcursor`, `hyprgraphics`, `aquamarine`
4. Builds and installs AP0G33 to `/usr/local`

Then pick **AP0G33** in your display manager, or run `AP0G33` from a TTY.

## Post-install

- Config: `~/.config/ap0g33/ap0g33.lua` (a default is generated on first launch); an existing `~/.config/hypr/` setup is picked up automatically
- Recommended extras: `sudo apt install waybar wofi kitty xdg-desktop-portal-wlr grim slurp wl-clipboard`
- All [Hyprland wiki](https://wiki.hypr.land/) docs apply; substitute `ap0g33ctl` for `hyprctl` (or keep using the `hyprctl` symlink)

## Uninstall

```bash
cd build && sudo make uninstall   # or: xargs sudo rm < build/install_manifest.txt
```

## License

BSD-3-Clause, same as upstream. See [LICENSE](LICENSE). All credit for the compositor goes to [vaxerski](https://github.com/vaxry) and the Hyprland contributors — AP0G33 is a packaging/branding port, not a fork of functionality.
