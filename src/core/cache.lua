local constants = July.require("core.constants")

local M = {}

M.loot = {}
M.traps = {}
M.stats = {
    last_loot_scan = 0,
    last_trap_scan = 0,
}

M.WORKSPACE_SCAN_MS = 1000
M.POS_CACHE_MS = 1000
M._last_pos_cache = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.should_refresh_positions(combat_active)
    local interval = M.POS_CACHE_MS
    if combat_active then
        interval = math.min(interval, constants.ESP_POS_CACHE_COMBAT_MS or 250)
    else
        interval = constants.ESP_POS_CACHE_MS or interval
    end
    if interval <= 0 then
        interval = M.POS_CACHE_MS
    end

    local now = tick_ms()
    if now - M._last_pos_cache >= interval then
        M._last_pos_cache = now
        return true
    end
    return false
end

function M.clear_bucket(bucket)
    if not bucket then return end
    for k in pairs(bucket) do
        bucket[k] = nil
    end
end

-- Compact array ESP lists between workspace rescans (April pattern).
function M.prune_invalid(list)
    if not list or #list == 0 then return 0 end
    local env = July.require("core.env")
    local write = 1
    for read = 1, #list do
        local entry = list[read]
        local inst = entry and (entry.inst or entry.model)
        local alive = entry and inst and env.is_valid(inst)
        if entry and entry.is_drop then
            alive = (entry.root and env.is_valid(entry.root))
                or (entry.inst and env.is_valid(entry.inst))
        end
        if entry and alive then
            if write ~= read then
                list[write] = entry
            end
            write = write + 1
        end
    end
    for i = write, #list do
        list[i] = nil
    end
    return write - 1
end

function M.reset()
    M._last_pos_cache = 0
    M.clear_bucket(M.loot)
    M.clear_bucket(M.traps)
    M.stats.last_loot_scan = 0
    M.stats.last_trap_scan = 0
end

return M
