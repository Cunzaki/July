local settings = July.require("core.settings")
local gc = July.require("game.gc_weapon_mods")

local M = {}

local MOD_IDS = {
    "havoc_no_recoil",
    "havoc_no_spread",
    "havoc_no_sway",
    "havoc_fast_vel",
}

local warm_counter = 0

function M.warm()
    if not settings.enabled("havoc_weapon_mods_enabled") then
        return 0
    end
    return gc.warm()
end

function M.apply()
    if not settings.enabled("havoc_weapon_mods_enabled") then
        return
    end

    warm_counter = warm_counter + 1
    if warm_counter % 4 == 1 then
        gc.warm()
    end

    local enabled = {}
    for i = 1, #MOD_IDS do
        if settings.bool(MOD_IDS[i], false) then
            enabled[#enabled + 1] = MOD_IDS[i]
        end
    end

    if #enabled > 0 then
        gc.apply_enabled(enabled)
    end
end

return M
