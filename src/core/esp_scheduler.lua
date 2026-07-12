local settings = July.require("core.settings")
local constants = July.require("core.constants")
local cache = July.require("core.cache")

local M = {}
local scans_ready = false

local function combat_active()
    return settings.bool("havoc_aimbot_enabled", false)
        and settings.enabled("havoc_aimbot_keybind")
end

local function any_loot_esp()
    return settings.enabled("havoc_loot_enabled")
end

local function any_item_esp()
    return settings.enabled("havoc_item_enabled")
end

local function any_drop_esp()
    return any_item_esp()
end

local function any_trap_esp()
    return settings.enabled("havoc_trap_enabled")
end

local function any_npc_esp()
    return settings.enabled("havoc_npc_enabled")
end

function M.setup()
    if scans_ready then return end
    scans_ready = true

    local iscan = July.require("core.incremental_scan")
    local loot_scan = July.require("game.loot_scan")
    local trap_scan = July.require("game.trap_scan")

    iscan.configure({ budget_ms = 6, items_per_step = 16 })

    local SCAN_MS = cache.WORKSPACE_SCAN_MS or 1000

    iscan.register("loot_static", SCAN_MS, function()
        return any_loot_esp()
    end, loot_scan.begin_static_scan, loot_scan.step_static_scan, loot_scan.complete_static_scan, 0)

    iscan.register("loot_drops", SCAN_MS, function()
        return any_drop_esp()
    end, loot_scan.begin_drops_scan, loot_scan.step_drops_scan, loot_scan.complete_drops_scan, 360)

    iscan.register("traps", SCAN_MS, function()
        return any_trap_esp()
    end, trap_scan.begin_scan, trap_scan.step_scan, trap_scan.complete_scan, 480)
end

function M.tick(frame_counter)
    M.setup()

    frame_counter = frame_counter or 0
    local entity_scan = July.require("game.entity_scan")
    local loot_scan = July.require("game.loot_scan")
    local trap_scan = July.require("game.trap_scan")
    local iscan = July.require("core.incremental_scan")

    local t = os.clock()
    local last = M._last or {}
    M._last = last

    if any_npc_esp() then
        local entity_iv = combat_active() and 0.5 or constants.ENTITY_SCAN_INTERVAL
        if t - (last.entity or 0) >= entity_iv then
            last.entity = t
            entity_scan.refresh()
        end
    end

    iscan.tick()

    if any_loot_esp() then
        if t - (last.compact or 0) >= (constants.LOOT_COMPACT_INTERVAL or 8.0) then
            last.compact = t
            loot_scan.compact_invalid(true)
        end
        loot_scan.tick_live_state()
        loot_scan.tick_static_bounds(constants.LOOT_PRUNE_BATCH or 8)
    end

    if any_drop_esp() then
        loot_scan.tick_drop_positions(constants.DROP_LIVE_BATCH or 24)
        if #loot_scan.get_drops() == 0 and not iscan.is_active("loot_drops") then
            iscan.force("loot_drops")
        end
    end

    if any_loot_esp() or any_drop_esp() then
        loot_scan.tick_cache()
    end

    if any_trap_esp() then
        trap_scan.tick_positions(constants.TRAP_LIVE_BATCH or 16)
        trap_scan.tick_cache()
    end

    local live_iv = 0.15
    if t - (last.live or 0) >= live_iv then
        last.live = t
        if any_npc_esp() then
            entity_scan.refresh_live()
        end
    end
end

function M.reset()
    M._last = {}
    scans_ready = false
    cache.reset()
    July.require("core.incremental_scan").force("loot_static")
    July.require("core.incremental_scan").force("loot_drops")
    July.require("core.incremental_scan").force("traps")
end

return M
