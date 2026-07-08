local env = July.require("core.env")
local cache = July.require("core.cache")

local M = {}

M._ready = false
M._last_char_key = nil
M._last_folder_name = nil

local function char_key(lp)
    if not lp then return nil end
    local char = lp.Character or lp.character
    if not char then return nil end
    if not env.is_valid(char) then return nil end
    local addr = char.Address or char.address
    if addr then return tostring(addr) end
    return tostring(char)
end

function M.invalidate_all()
    cache.reset()

    July.require("game.havoc_sync").reset()
    July.require("game.entity_scan").invalidate()
    July.require("game.loot_scan").invalidate()
    July.require("game.trap_scan").invalidate()
    July.require("core.silent_ray").reset_session()
    July.require("features.combat.aimbot").reset()
    July.require("features.combat.silent_aim").reset()
    July.require("game.combat_origin").invalidate()

    local gc = July.require("game.gc_weapon_mods")
    if gc.available() then
        pcall(gc.warm)
    end
end

function M.tick()
    local lp = env.get_local_player()
    local char_key = char_key(lp)
    local folder_name = July.require("game.havoc_sync").get_folder_name()

    if M._ready then
        local changed = false
        if char_key ~= M._last_char_key then
            changed = true
        end
        if folder_name and M._last_folder_name and folder_name ~= M._last_folder_name then
            changed = true
        end
        if changed then
            M.invalidate_all()
        end
    end

    if char_key then
        M._ready = true
        M._last_char_key = char_key
    end
    if folder_name then
        M._last_folder_name = folder_name
    end
end

return M
