local settings = July.require("core.settings")
local constants = July.require("core.constants")
local cache = July.require("core.cache")

local M = {}

local last = {
    entity = 0,
    loot = 0,
    drops = 0,
    trap = 0,
    live = 0,
    compact = 0,
}

local function now()
    return os.clock()
end

local function combat_active()
    return settings.bool("havoc_aimbot_enabled", false)
        and settings.enabled("havoc_aimbot_keybind")
end

local function any_loot_esp()
    return settings.enabled("havoc_loot_enabled")
end

local function any_trap_esp()
    return settings.enabled("havoc_trap_enabled")
end

local function any_world_esp()
    return any_loot_esp() or any_trap_esp()
end

local function any_npc_esp()
    return settings.enabled("havoc_npc_enabled")
end

function M.tick(frame_counter)
    frame_counter = frame_counter or 0
    local t = now()
    local entity_scan = July.require("game.entity_scan")
    local loot_scan = July.require("game.loot_scan")
    local trap_scan = July.require("game.trap_scan")
    local scan_budget = constants.SCAN_BUDGET_MS or 4

    if any_npc_esp() then
        local entity_iv = combat_active() and 0.5 or constants.ENTITY_SCAN_INTERVAL
        if t - last.entity >= entity_iv then
            last.entity = t
            entity_scan.refresh()
        end
    end

    if any_loot_esp() then
        if t - last.loot >= constants.LOOT_SCAN_INTERVAL then
            last.loot = t
            loot_scan.queue_refresh()
        end
        if t - last.drops >= constants.DROP_SCAN_INTERVAL then
            last.drops = t
            loot_scan.queue_refresh_drops()
        end
        if t - last.compact >= (constants.LOOT_COMPACT_INTERVAL or 8.0) then
            last.compact = t
            loot_scan.compact_invalid(true)
        end
        loot_scan.tick_async(scan_budget)
    end

    if any_trap_esp() then
        if t - last.trap >= constants.TRAP_SCAN_INTERVAL then
            last.trap = t
            trap_scan.queue_refresh()
        end
        trap_scan.tick_async(scan_budget)
    end

    local pos_ms = combat_active() and constants.ESP_POS_CACHE_COMBAT_MS or constants.ESP_POS_CACHE_MS
    local live_iv = (pos_ms or 120) / 1000
    if t - last.live >= live_iv then
        last.live = t
        if any_npc_esp() then
            entity_scan.refresh_live()
        end
        if any_loot_esp() then
            loot_scan.refresh_live()
        end
        if any_trap_esp() then
            trap_scan.refresh_live()
        end
    end
end

function M.reset()
    last.entity = 0
    last.loot = 0
    last.drops = 0
    last.trap = 0
    last.live = 0
    last.compact = 0
    cache.reset()
end

return M
