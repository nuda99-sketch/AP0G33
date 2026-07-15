#!/usr/bin/env bash
# ============================================================================
#  AP0G33 — Hyprland port for Debian-based distros (target: Kali Rolling)
#
#  One-shot bootstrap: installs apt build deps, builds the hypr* dependency
#  stack from source (pinned to the exact revisions upstream Hyprland 0.55.0
#  pins in its flake.lock), source-builds any core library that Kali ships
#  too old, then builds and installs AP0G33 to /usr/local.
#
#  Usage:  sudo ./install-kali.sh
# ============================================================================
set -euo pipefail

# ----------------------------------------------------------- configuration
PREFIX=/usr/local
WORKDIR="${WORKDIR:-/tmp/ap0g33-build}"
JOBS="$(nproc)"
SRCDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# hypr* stack, pinned to Hyprland 0.55.0 flake.lock
HYPRWAYLAND_SCANNER_REV=b8632713a6beaf28b56f2a7b0ab2fb7088dbb404
HYPRUTILS_REV=41fb809557abd29a57151b6e1aaeabd05f9437e1
HYPRLANG_REV=090117506ddc3d7f26e650ff344d378c2ec329cc
HYPRCURSOR_REV=39435900785d0c560c6ae8777d29f28617d031ef
HYPRGRAPHICS_REV=c6e7b9f673f4360bc813d3dc75028f75ee88d3f8
HYPRWIRE_REV=85148a8e612808cf5ddb25d0b3c5840f3498a7dc
AQUAMARINE_REV=6d6e2384f381def4ea4ea81543cba4bbdac72457

# minimum versions required by Hyprland 0.55.0 (from CMakeLists.txt)
MIN_XKBCOMMON=1.11.0
MIN_WAYLAND=1.22.91
MIN_WAYLAND_PROTOCOLS=1.49
MIN_LIBINPUT=1.29
MIN_CMAKE=3.30

ARCH_TRIPLET="$(uname -m)-linux-gnu"
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib/$ARCH_TRIPLET/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH PATH

# ----------------------------------------------------------------- helpers
log()  { printf '\033[1;32m[AP0G33]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AP0G33]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[AP0G33]\033[0m %s\n' "$*" >&2; exit 1; }

# pc_ok <pkg-config module> <minver> — true if system already satisfies it
pc_ok() { pkg-config --atleast-version="$2" "$1" 2>/dev/null; }

fetch() { # fetch <github owner/repo> <rev> <destdir>
    local repo=$1 rev=$2 dest=$3
    if [[ -d $dest ]]; then rm -rf "$dest"; fi
    log "Fetching $repo @ ${rev:0:12}"
    mkdir -p "$dest"
    curl -fsSL "https://github.com/$repo/archive/$rev.tar.gz" | tar xz --strip-components=1 -C "$dest"
}

cmake_build() { # cmake_build <srcdir> [extra cmake args...]
    local src=$1; shift
    cmake -S "$src" -B "$src/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        "$@"
    cmake --build "$src/build" -j "$JOBS"
    cmake --install "$src/build"
}

meson_build() { # meson_build <srcdir> [extra meson args...]
    local src=$1; shift
    meson setup "$src/build" "$src" --prefix="$PREFIX" --libdir=lib --buildtype=release "$@"
    ninja -C "$src/build" -j "$JOBS"
    ninja -C "$src/build" install
}

# ------------------------------------------------------------- preflight
[[ $EUID -eq 0 ]] || die "Run as root: sudo ./install-kali.sh"
command -v apt-get >/dev/null || die "apt-get not found — this script targets Debian-based distros."
mkdir -p "$WORKDIR"

log "Target prefix: $PREFIX   Build dir: $WORKDIR   Jobs: $JOBS"

# ------------------------------------------------------ 1. apt build deps
log "Installing apt packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

# apt_try <pkg...> — install what exists, warn about what doesn't
apt_try() {
    local ok=() missing=()
    for p in "$@"; do
        if apt-cache show "$p" >/dev/null 2>&1; then ok+=("$p"); else missing+=("$p"); fi
    done
    ((${#ok[@]})) && apt-get install -y --no-install-recommends "${ok[@]}"
    ((${#missing[@]})) && warn "Not in apt (will source-build or skip): ${missing[*]}"
    return 0
}

apt_try \
    build-essential cmake ninja-build meson pkg-config git curl ca-certificates \
    gcc-15 g++-15 gcc-14 g++-14 \
    wayland-protocols libwayland-dev wayland-scanner++ \
    libxkbcommon-dev libxkbcommon-x11-dev xkb-data \
    libinput-dev libudev-dev libevdev-dev libmtdev-dev \
    libpixman-1-dev libcairo2-dev libpango1.0-dev \
    libdrm-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev libvulkan-dev \
    glslang-dev glslang-tools spirv-tools \
    libseat-dev seatd libdisplay-info-dev hwdata \
    libxcursor-dev uuid-dev libglib2.0-dev \
    libre2-dev libmuparser-dev liblcms2-dev libreadline-dev \
    libzip-dev librsvg2-dev libtomlplusplus-dev \
    libjpeg-dev libwebp-dev libmagic-dev libspng-dev libjxl-dev \
    libpugixml-dev \
    xwayland libxcb1-dev libxcb-composite0-dev libxcb-errors-dev \
    libxcb-ewmh-dev libxcb-icccm4-dev libxcb-render-util0-dev \
    libxcb-res0-dev libxcb-xfixes0-dev libxcb-xinput-dev libxcb-shm0-dev \
    libxcb-util-dev libx11-xcb-dev libxcb-dri3-dev libxcb-present-dev \
    hyprland-protocols \
    lua5.5 liblua5.5-dev \
    libpam0g-dev libsdbus-c++-dev

# desktop suite for the pre-patched AP0G33 config (Tokyo Night rice)
apt_try \
    waybar wofi kitty mako-notifier cliphist \
    grim slurp wl-clipboard libnotify-bin \
    btop brightnessctl playerctl pavucontrol \
    pipewire-pulse wireplumber \
    fonts-jetbrains-mono fonts-font-awesome \
    mate-polkit sddm

# ------------------------------------------------- 2. toolchain sanity
GXX=""
for c in g++-15 g++-14 g++; do
    if command -v "$c" >/dev/null; then
        v=$("$c" -dumpversion | cut -d. -f1)
        if (( v >= 14 )); then GXX=$(command -v "$c"); GCC=${GXX/g++/gcc}; break; fi
    fi
done
[[ -n $GXX ]] || die "Need g++ >= 14 for C++26. Install gcc-14/g++-14 (or newer) and re-run."
export CC="$GCC" CXX="$GXX"
log "Using compiler: $CXX ($("$CXX" -dumpversion))"

if ! cmake --version | head -1 | grep -qE 'version ([4-9]|3\.([3-9][0-9]))'; then
    warn "cmake < $MIN_CMAKE — installing current CMake from Kitware binary release..."
    CMV=3.31.6
    ARCH=$(uname -m)
    curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMV}/cmake-${CMV}-linux-${ARCH}.tar.gz" \
        | tar xz --strip-components=1 -C "$PREFIX"
fi

# --------------------------- 3. core libs: source-build only if too old
if ! pc_ok wayland-server "$MIN_WAYLAND"; then
    log "wayland-server too old — building wayland 1.24.0"
    d=$WORKDIR/wayland; rm -rf "$d"; mkdir -p "$d"
    curl -fsSL "https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.24.0/downloads/wayland-1.24.0.tar.xz" | tar xJ --strip-components=1 -C "$d"
    meson_build "$d" -Ddocumentation=false -Dtests=false
fi

if ! pc_ok wayland-protocols "$MIN_WAYLAND_PROTOCOLS"; then
    log "wayland-protocols too old — building 1.49"
    d=$WORKDIR/wayland-protocols; rm -rf "$d"; mkdir -p "$d"
    curl -fsSL "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.49/downloads/wayland-protocols-1.49.tar.xz" | tar xJ --strip-components=1 -C "$d"
    meson_build "$d" -Dtests=false
fi

if ! pc_ok xkbcommon "$MIN_XKBCOMMON"; then
    log "libxkbcommon too old — building 1.11.0"
    d=$WORKDIR/libxkbcommon; rm -rf "$d"; mkdir -p "$d"
    curl -fsSL "https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-1.11.0.tar.gz" | tar xz --strip-components=1 -C "$d"
    meson_build "$d" -Denable-docs=false -Denable-wayland=true -Denable-x11=true
fi

if ! pc_ok libinput "$MIN_LIBINPUT"; then
    log "libinput too old — building 1.29.0"
    d=$WORKDIR/libinput; rm -rf "$d"; mkdir -p "$d"
    curl -fsSL "https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.29.0/libinput-1.29.0.tar.gz" | tar xz --strip-components=1 -C "$d"
    meson_build "$d" -Ddocumentation=false -Dtests=false -Ddebug-gui=false -Dlibwacom=false
fi

# Lua 5.5 (Hyprland requires >=5.5 <5.6; Debian may not package it yet)
if ! pkg-config --exists 'lua5.5' 2>/dev/null && ! pc_ok lua 5.5; then
    log "Lua 5.5 not found — building from lua.org"
    d=$WORKDIR/lua; rm -rf "$d"; mkdir -p "$d"
    curl -fsSL "https://www.lua.org/ftp/lua-5.5.0.tar.gz" | tar xz --strip-components=1 -C "$d"
    make -C "$d" linux MYCFLAGS="-fPIC" -j "$JOBS"
    make -C "$d" install INSTALL_TOP="$PREFIX"
    mkdir -p "$PREFIX/lib/pkgconfig"
    cat > "$PREFIX/lib/pkgconfig/lua5.5.pc" <<EOF
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Lua
Description: An Extensible Extension Language
Version: 5.5.0
Libs: -L\${libdir} -llua -lm -ldl
Cflags: -I\${includedir}
EOF
fi

# tomlplusplus fallback (needed by hyprpm and hyprcursor)
if ! pkg-config --exists tomlplusplus 2>/dev/null; then
    log "tomlplusplus not in apt — installing from source (header-only)"
    d=$WORKDIR/tomlplusplus
    fetch marzer/tomlplusplus v3.4.0 "$d"
    cmake_build "$d" -DTOML_BUILD_TESTS=OFF -DTOML_BUILD_EXAMPLES=OFF
fi

ldconfig

# ------------------------------------- 4. hypr* stack (pinned revisions)
log "Building hyprwayland-scanner"
d=$WORKDIR/hyprwayland-scanner
fetch hyprwm/hyprwayland-scanner "$HYPRWAYLAND_SCANNER_REV" "$d"
cmake_build "$d"

log "Building hyprutils"
d=$WORKDIR/hyprutils
fetch hyprwm/hyprutils "$HYPRUTILS_REV" "$d"
cmake_build "$d"
ldconfig

log "Building hyprlang"
d=$WORKDIR/hyprlang
fetch hyprwm/hyprlang "$HYPRLANG_REV" "$d"
cmake_build "$d"
ldconfig

log "Building hyprcursor"
d=$WORKDIR/hyprcursor
fetch hyprwm/hyprcursor "$HYPRCURSOR_REV" "$d"
cmake_build "$d"
ldconfig

log "Building hyprgraphics"
d=$WORKDIR/hyprgraphics
fetch hyprwm/hyprgraphics "$HYPRGRAPHICS_REV" "$d"
cmake_build "$d"
ldconfig

log "Building hyprwire"
d=$WORKDIR/hyprwire
fetch hyprwm/hyprwire "$HYPRWIRE_REV" "$d"
cmake_build "$d"
ldconfig

log "Building aquamarine"
d=$WORKDIR/aquamarine
fetch hyprwm/aquamarine "$AQUAMARINE_REV" "$d"
cmake_build "$d"
ldconfig

# --------------------------- 4.5 satellite tools (wallpaper, lock, idle)
# Latest release tags (our hypr* lib stack is current, so latest releases fit);
# falls back to the main branch if the GitHub API is unavailable.
gh_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
        | grep -oP '"tag_name":\s*"\K[^"]+' || true
}

for sat in hyprpaper hyprlock hypridle; do
    log "Building $sat"
    d=$WORKDIR/$sat
    tag=$(gh_latest_tag "hyprwm/$sat")
    if [[ -n $tag ]]; then
        fetch "hyprwm/$sat" "refs/tags/$tag" "$d"
    else
        warn "GitHub API unavailable, building $sat from main branch"
        fetch "hyprwm/$sat" "refs/heads/main" "$d"
    fi
    cmake_build "$d"
    ldconfig
done

# --------------------------------------------------- 5. AP0G33 itself
log "Building AP0G33 (Hyprland $(cat "$SRCDIR/VERSION"))"
cmake --no-warn-unused-cli -S "$SRCDIR" -B "$SRCDIR/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build "$SRCDIR/build" -j "$JOBS"
cmake --install "$SRCDIR/build"
ldconfig

# ------------------------------------- 6. system-wide theme (zero per-user files)
# Ready to use from first boot: the compositor generates its own Tokyo Night
# config on first launch (embedded default), and all satellite tools read
# these system paths unless the user creates their own ~/.config overrides.
log "Installing wallpaper and system-wide Tokyo Night theme..."

SYS=/usr/local/share/ap0g33

install -Dm644 "$SRCDIR/assets/wallpapers/ap0g33-circuit.png" "$SYS/wallpapers/ap0g33-circuit.png"

# waybar + kitty read these via XDG_CONFIG_DIRS (set by the default config)
install -Dm644 "$SRCDIR/config/waybar/config.jsonc" "$SYS/xdg/waybar/config"
install -Dm644 "$SRCDIR/config/waybar/style.css"    "$SYS/xdg/waybar/style.css"
install -Dm644 "$SRCDIR/config/kitty/kitty.conf"    "$SYS/xdg/kitty/kitty.conf"

# wofi / mako / hypr satellites get pointed here explicitly by the default config
install -Dm644 "$SRCDIR/config/wofi/config"         "$SYS/wofi/config"
install -Dm644 "$SRCDIR/config/wofi/style.css"      "$SYS/wofi/style.css"
install -Dm644 "$SRCDIR/config/mako/config"         "$SYS/mako/config"
install -Dm644 "$SRCDIR/config/hypr/hyprpaper.conf" "$SYS/hypr/hyprpaper.conf"
install -Dm644 "$SRCDIR/config/hypr/hyprlock.conf"  "$SYS/hypr/hyprlock.conf"
install -Dm644 "$SRCDIR/config/hypr/hypridle.conf"  "$SYS/hypr/hypridle.conf"

# reference copy of the compositor config (also embedded as the generated default)
install -Dm644 "$SRCDIR/config/ap0g33/ap0g33.conf"  "$SYS/ap0g33.conf.example"

log "Theme installed to $SYS — no files written to any user's home."

# --------------------------------------------------------- 7. finishing
if command -v systemctl >/dev/null && systemctl list-unit-files seatd.service >/dev/null 2>&1; then
    systemctl enable --now seatd.service || true
    warn "seatd enabled. Add your user to the 'video' and '_seatd'/'seat' group if not using logind."
fi

# display manager: don't fight an existing one
if systemctl is-enabled lightdm gdm3 2>/dev/null | grep -q enabled; then
    warn "Existing display manager detected — AP0G33 will appear in its session list."
elif command -v sddm >/dev/null; then
    systemctl enable sddm || true
    log "SDDM enabled — pick the AP0G33 session on the login screen."
fi

log "Done!"
log "  Compositor:    $PREFIX/bin/AP0G33       (compat symlinks: Hyprland, hyprland)"
log "  Control tool:  $PREFIX/bin/ap0g33ctl    (compat symlink: hyprctl)"
log "  Plugin mgr:    $PREFIX/bin/ap0g33pm     (compat symlink: hyprpm)"
log "  Launcher:      $PREFIX/bin/start-ap0g33 (compat symlink: start-hyprland)"
log "  Session file:  $PREFIX/share/wayland-sessions/ap0g33.desktop"
log "  Config:        auto-generated at ~/.config/ap0g33/ap0g33.conf on first launch"
log "                 (Tokyo Night rice, works with zero setup; theme files in"
log "                 /usr/local/share/ap0g33 — copy to ~/.config to customize)"
log "  Wallpaper:     /usr/local/share/ap0g33/wallpapers/ap0g33-circuit.png"
log "  Keys:          SUPER+Q terminal | SUPER+R launcher | SUPER+hjkl focus"
log "                 SUPER+ESC lock | Print screenshot | SUPER+SHIFT+V clipboard"
log "  VM users:      uncomment the 'VM MODE' block in ap0g33.conf"
log "Log out and pick AP0G33 in your display manager, or run 'AP0G33' from a TTY."
