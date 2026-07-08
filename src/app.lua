local tabs = July.require("menu.tabs")
local debug = July.require("core.debug")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.guard("tabs.update", tabs.update)
end

return M
