local env = July.require("core.env")

local M = {}

M._last_held = nil

local function inst_name(inst)
    if not inst then return nil end
    return inst.Name or inst.name
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.Character or lp.character
    if not char or not env.is_valid(char) then return nil end

    local ok, children = pcall(function() return char:GetChildren() end)
    if not ok or not children then return nil end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Tool" then
            return inst_name(child)
        end
    end

    return nil
end

function M.cached_held()
    local name = M.get_held_tool_name()
    M._last_held = name
    return name
end

function M.holding_weapon()
    return M.get_held_tool_name() ~= nil
end

return M
