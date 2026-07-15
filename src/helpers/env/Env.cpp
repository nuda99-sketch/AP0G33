#include "Env.hpp"

#include <cstdlib>
#include <cstring>
#include <string>

static bool rawEnvEnabled(const char* env) {
    const auto ret = getenv(env);
    return ret && ret[0] != '\0' && !(ret[0] == '0' && ret[1] == '\0');
}

bool Env::envEnabled(const char* env) {
    // AP0G33: HYPRLAND_* toggles are also accepted as AP0G33_*
    constexpr const char* LEGACY_PREFIX = "HYPRLAND_";
    if (std::strncmp(env, LEGACY_PREFIX, std::strlen(LEGACY_PREFIX)) == 0) {
        const std::string branded = std::string{"AP0G33_"} + (env + std::strlen(LEGACY_PREFIX));
        if (rawEnvEnabled(branded.c_str()))
            return true;
    }
    return rawEnvEnabled(env);
}

bool Env::isTrace() {
    static bool TRACE = envEnabled("HYPRLAND_TRACE");
    return TRACE;
}
