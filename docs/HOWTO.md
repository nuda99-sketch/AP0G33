# AP0G33 — How to Use

AP0G33 is a rebrand of Hyprland 0.55.0, built and packaged for Debian-based distros (target: Kali Rolling). Everything below applies as if you were using Hyprland — swap `hyprctl` → `ap0g33ctl`, `hyprpm` → `ap0g33pm`, etc. Legacy names still work as symlinks, so any existing Hyprland tooling (waybar, wlogout, hyprpaper, xdg-desktop-portal-hyprland) keeps functioning unchanged.

## 1. Install

On Kali Rolling / Debian testing, clone and run the bootstrap script as root:

```bash
git clone https://github.com/nuda99-sketch/AP0G33.git
cd AP0G33
sudo ./install-kali.sh
```

What it does, in order:

1. Installs apt build dependencies (`build-essential`, `cmake`, `meson`, Wayland/X11/DRM dev packages, etc.), skipping any not present in Kali's repos.
2. Picks a compiler ≥ GCC 14 (needed for C++26) and exports `CC`/`CXX`.
3. Version-checks `wayland-server`, `wayland-protocols`, `xkbcommon`, and `libinput` via `pkg-config`, and source-builds only the ones Kali ships too old, plus Lua 5.5 and `tomlplusplus` if missing.
4. Builds the hypr* dependency stack from source, pinned to the exact revisions Hyprland 0.55.0's `flake.lock` uses: `hyprwayland-scanner`, `hyprutils`, `hyprlang`, `hyprcursor`, `hyprgraphics`, `hyprwire`, `aquamarine`.
5. Builds and installs AP0G33 itself to `/usr/local`.
6. Enables `seatd` if present (needed if you're not using logind/systemd-logind for session management).

The whole thing installs to `/usr/local`, so binaries land in `/usr/local/bin`.

**Requirements:** run as root (`sudo`), on a system with `apt-get`. If your default GCC is older than 14, install `gcc-14`/`g++-14` first — the script will refuse to proceed otherwise.

## 2. Launch it

Log out, then either:

- Pick **AP0G33** from your display manager's session list, or
- Run `AP0G33` directly from a TTY.

A default config is generated on first launch at `~/.config/ap0g33/ap0g33.lua`. If you already have a `~/.config/hypr/` setup from stock Hyprland, AP0G33 picks it up automatically — no migration needed.

Recommended companion packages, install with:

```bash
sudo apt install waybar wofi kitty xdg-desktop-portal-wlr grim slurp wl-clipboard
```

## 3. Configuration

Config lives at `~/.config/ap0g33/ap0g33.lua` (Lua config, the current Hyprland style) — `.conf` is also read if you prefer the legacy format. You can override the location with the `AP0G33_CONFIG` env var (`HYPRLAND_CONFIG` still works too).

A stripped-down example, taken from `example/hyprland.lua` in this repo:

```lua
-- Monitors
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Look and feel
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        blur = { enabled = true, size = 3, passes = 1 },
    },
})

-- Input
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = false },
    },
})

-- Keybindings
local mainMod = "SUPER"
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))               -- open terminal
hl.bind(mainMod .. " + C", hl.dsp.window.close())                  -- close window
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + 1",     hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
```

Copy the full example into your config directory to start from a complete, working setup:

```bash
mkdir -p ~/.config/ap0g33
cp example/hyprland.lua ~/.config/ap0g33/ap0g33.lua
```

Split large configs into multiple files and pull them in with `require("myfile")`, same as upstream Hyprland. All of the [Hyprland wiki](https://wiki.hypr.land/) applies directly — every `hyprctl` reference there maps onto `ap0g33ctl` (or just keep using the `hyprctl` symlink if that's less to remember).

## 4. `ap0g33ctl` — the control tool

This is the `hyprctl` equivalent (symlinked as `hyprctl` too, so both names work). Common usage:

```bash
ap0g33ctl monitors               # list connected outputs
ap0g33ctl clients                # list open windows and their properties
ap0g33ctl activewindow           # info on the focused window
ap0g33ctl workspaces             # list workspaces
ap0g33ctl reload                 # reload the config live
ap0g33ctl kill                   # click a window to kill it
ap0g33ctl -j clients             # any command, JSON output
```

Issue a keybind dispatcher directly (useful for scripting, or binding from another tool):

```bash
ap0g33ctl dispatch exec kitty
ap0g33ctl dispatch workspace 3
ap0g33ctl dispatch movetoworkspace 2
ap0g33ctl dispatch fullscreen
```

Change a config option at runtime without editing the file:

```bash
ap0g33ctl keyword general:gaps_out 10
```

Send yourself a desktop notification from a script:

```bash
ap0g33ctl notify 5 5000 "rgb(00ff00)" "Build finished"
```

Batch several commands in one call (separated by `;`):

```bash
ap0g33ctl --batch "dispatch workspace 2; dispatch exec kitty"
```

Tail the compositor log for debugging:

```bash
ap0g33ctl rollinglog -f
```

## 5. `ap0g33pm` — the plugin manager

This is the `hyprpm` equivalent (symlinked as `hyprpm`), for installing community plugins:

```bash
ap0g33pm add https://github.com/some/hyprland-plugin      # install a plugin repo
ap0g33pm list                                              # see what's installed
ap0g33pm enable plugin-name                                # load a plugin
ap0g33pm disable plugin-name                                # unload a plugin
ap0g33pm update                                             # update all plugins
ap0g33pm reload                                              # apply enable/disable changes
ap0g33pm reload -f                                           # force reload
ap0g33pm remove https://github.com/some/hyprland-plugin    # uninstall a plugin repo
```

## 6. Naming cheat sheet

| Thing | AP0G33 name | Still works |
|---|---|---|
| Compositor binary | `AP0G33` | `Hyprland`, `hyprland` |
| Control tool | `ap0g33ctl` | `hyprctl` |
| Plugin manager | `ap0g33pm` | `hyprpm` |
| Launcher | `start-ap0g33` | `start-hyprland` |
| Config file | `~/.config/ap0g33/ap0g33.lua` | `~/.config/hypr/` if present |
| Config env var | `AP0G33_CONFIG` | `HYPRLAND_CONFIG` |
| Runtime/IPC dir | `$XDG_RUNTIME_DIR/ap0g33` | `hypr` symlink |
| Instance env var | `AP0G33_INSTANCE_SIGNATURE` | `HYPRLAND_INSTANCE_SIGNATURE` |
| Logs/crash reports | `~/.cache/ap0g33/`, `ap0g33.log` | — |

Because both env var names get exported and the socket path is symlinked, third-party tools that only know about `hyprctl`/Hyprland env vars work without modification.

## 7. Uninstall

```bash
cd AP0G33/build && sudo make uninstall
# or, equivalently:
xargs sudo rm < build/install_manifest.txt
```

## 8. Troubleshooting

- **"Need g++ >= 14 for C++26"** — install `gcc-14`/`g++-14` (or newer) before rerunning `install-kali.sh`.
- **No session after login / black screen** — make sure `seatd` is enabled (`systemctl enable --now seatd`) and your user is in the `video` and `seat`/`_seatd` groups, unless you're using systemd-logind.
- **Old config not picked up** — AP0G33 reads `~/.config/hypr/` automatically only if `~/.config/ap0g33/` doesn't already have a config; check `AP0G33_CONFIG`/`HYPRLAND_CONFIG` aren't pointing elsewhere.
- **Plugin build failures** — plugins compiled against the Hyprland headers; `ap0g33pm update -f` forces a rebuild against the current AP0G33 sources if a plugin gets out of sync after an update.
