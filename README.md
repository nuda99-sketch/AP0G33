# AP0G33

**AP0G33** is a port of [Hyprland](https://github.com/hyprwm/Hyprland) — the dynamic tiling Wayland compositor — for **Debian-based distros**, targeting **Kali Rolling**.

Upstream Hyprland does not officially support Debian-based distros because their packaged toolchains and libraries lag behind what Hyprland requires. AP0G33 solves this with a bootstrap script that builds the required dependency stack from source where Kali's packages are too old, then builds and installs the compositor.

Based on Hyprland **0.55.0**.

## What's different from upstream

- Binary is installed as `AP0G33` (with `Hyprland` and `hyprland` compat symlinks)
- Branding: greeting, `--version` output, session entry name
- `install-kali.sh`: one-shot build/install for Kali Rolling / Debian testing
- **Everything else is stock Hyprland**: config lives in `~/.config/hypr/`, `hyprctl` / `hyprpm` keep their names, IPC sockets and `XDG_CURRENT_DESKTOP` are unchanged — so waybar, wlogout, xdg-desktop-portal-hyprland and the rest of the ecosystem work as-is

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

Then pick **AP0G33** in your display manager, or run `Hyprland` / `AP0G33` from a TTY.

## Post-install

- Config: `~/.config/hypr/hyprland.conf` (a default is generated on first launch — Hyprland wiki applies 1:1)
- Recommended extras: `sudo apt install waybar wofi kitty xdg-desktop-portal-wlr grim slurp wl-clipboard`
- All [Hyprland wiki](https://wiki.hypr.land/) docs apply; only the binary name differs

## Uninstall

```bash
cd build && sudo make uninstall   # or: xargs sudo rm < build/install_manifest.txt
```

## License

BSD-3-Clause, same as upstream. See [LICENSE](LICENSE). All credit for the compositor goes to [vaxerski](https://github.com/vaxry) and the Hyprland contributors — AP0G33 is a packaging/branding port, not a fork of functionality.
