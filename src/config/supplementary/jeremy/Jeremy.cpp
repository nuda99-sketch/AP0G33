#include "Jeremy.hpp"

#include "../../../Compositor.hpp"

#include <hyprutils/path/Path.hpp>
#include <filesystem>
#include <optional>

using namespace Config;
using namespace Config::Supplementary;
using namespace Config::Supplementary::Jeremy;

static bool needsPathRecheck = false;

//
void Jeremy::flushCachedCfgPath() {
    needsPathRecheck = true;
}

std::expected<SConfigStateReply, std::string> Jeremy::getMainConfigPath() {
    static bool lastSafeMode = g_pCompositor->m_safeMode;

    static auto getCfgPath = []() -> std::expected<SConfigStateReply, std::string> {
        lastSafeMode     = g_pCompositor->m_safeMode;
        needsPathRecheck = false;

        if (g_pCompositor->m_safeMode)
            return SConfigStateReply{.path = (std::filesystem::path{g_pCompositor->m_instancePath} / "recoverycfg.lua").string(), .type = CONFIG_TYPE_SPECIAL};

        if (!g_pCompositor->m_explicitConfigPath.empty())
            return SConfigStateReply{.path = g_pCompositor->m_explicitConfigPath, .type = CONFIG_TYPE_EXPLICIT};

        if (const auto CFG_ENV = getenv("AP0G33_CONFIG"); CFG_ENV)
            return SConfigStateReply{.path = CFG_ENV, .type = CONFIG_TYPE_EXPLICIT};

        if (const auto CFG_ENV = getenv("HYPRLAND_CONFIG"); CFG_ENV)
            return SConfigStateReply{.path = CFG_ENV, .type = CONFIG_TYPE_EXPLICIT};

        // AP0G33: primary config lives in $XDG_CONFIG_HOME/ap0g33/ap0g33.{lua,conf}
        const auto AP0G33_DIR = []() -> std::optional<std::filesystem::path> {
            if (const auto XDG = getenv("XDG_CONFIG_HOME"); XDG && *XDG)
                return std::filesystem::path{XDG} / "ap0g33";
            if (const auto HOME = getenv("HOME"); HOME && *HOME)
                return std::filesystem::path{HOME} / ".config" / "ap0g33";
            return std::nullopt;
        }();

        if (AP0G33_DIR.has_value()) {
            if (std::filesystem::exists(*AP0G33_DIR / "ap0g33.lua"))
                return SConfigStateReply{.path = (*AP0G33_DIR / "ap0g33.lua").string(), .type = CONFIG_TYPE_REGULAR};
            if (std::filesystem::exists(*AP0G33_DIR / "ap0g33.conf"))
                return SConfigStateReply{.path = (*AP0G33_DIR / "ap0g33.conf").string(), .type = CONFIG_TYPE_REGULAR};
        }

        // legacy hyprland config paths (compat fallback)
        const auto LUA_PATHS  = Hyprutils::Path::findConfig(ISDEBUG ? "hyprlandd" : "hyprland", "lua");
        const auto CONF_PATHS = Hyprutils::Path::findConfig(ISDEBUG ? "hyprlandd" : "hyprland", "conf");

        if (LUA_PATHS.first.has_value())
            return SConfigStateReply{.path = LUA_PATHS.first.value(), .type = CONFIG_TYPE_REGULAR};
        else if (CONF_PATHS.first.has_value())
            return SConfigStateReply{.path = CONF_PATHS.first.value(), .type = CONFIG_TYPE_REGULAR};
        else if (AP0G33_DIR.has_value()) {
            // nothing exists yet: the shipped Tokyo Night default (DefaultConfig.hpp)
            // gets generated at the AP0G33 path, classic .conf syntax
            return SConfigStateReply{.path = (*AP0G33_DIR / "ap0g33.conf").string(), .type = CONFIG_TYPE_REGULAR};
        } else if (LUA_PATHS.second.has_value()) {
            auto CONFIGPATH = Hyprutils::Path::fullConfigPath(LUA_PATHS.second.value(), ISDEBUG ? "hyprlandd" : "hyprland", "lua");
            return SConfigStateReply{.path = CONFIGPATH, .type = CONFIG_TYPE_REGULAR};
        } else
            return std::unexpected("Neither HOME nor XDG_CONFIG_HOME are set in the environment. Could not find config in XDG_CONFIG_DIRS or /etc/xdg.");
    };
    static auto CONFIG_PATH = getCfgPath();

    if (lastSafeMode != g_pCompositor->m_safeMode || needsPathRecheck)
        CONFIG_PATH = getCfgPath();

    return CONFIG_PATH;
}
