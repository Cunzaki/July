local constants = July.require("core.constants")

local M = {}

M.WORKSPACE_SCAN_MS = 1000
M.POS_CACHE_MS = 250
M._last_pos_cache = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.should_refresh_positions(combat_active)
    local interval = combat_active and constants.ESP_POS_CACHE_COMBAT_MS or M.POS_CACHE_MS
    local now = tick_ms()
    if now - M._last_pos_cache >= interval then
        M._last_pos_cache = now
        return true
    end
    return false
end

function M.reset()
    M._last_pos_cache = 0
end

return M
