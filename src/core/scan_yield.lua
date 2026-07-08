local constants = July.require("core.constants")

local M = {}
local scan_yield_counter = 0

function M.yield()
    scan_yield_counter = scan_yield_counter + 1
    if scan_yield_counter >= constants.SCAN_YIELD_EVERY then
        scan_yield_counter = 0
        sleep(0)
    end
end

return M
