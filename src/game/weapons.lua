local env = July.require("core.env")
local tier_util = July.require("game.tier_util")

local M = {}

M._last_held = nil

local function inst_name(inst)
    if not inst then return nil end
    return inst.Name or inst.name
end

function M.get_held_weapon_inst()
    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.Character or lp.character
    if not char or not env.is_valid(char) then return nil end

    local ok, children = pcall(function() return char:GetChildren() end)
    if not ok or not children then return nil end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Tool" then
            return child
        end
        if child.ClassName == "Model" and tier_util.is_gun_name(child.Name) then
            return child
        end
    end

    return nil
end

function M.get_held_tool_name()
    return inst_name(M.get_held_weapon_inst())
end

function M.get_live_state()
    local weapon = M.get_held_weapon_inst()
    if not weapon then return nil end

    local state = {
        weapon_name = inst_name(weapon),
        ammo = nil,
        reloading = false,
    }

    local data = env.find_child(weapon, "_data")
    if not data then return state end

    local ammo = env.find_child(data, "ammoCurrent")
    if ammo then
        local ok, value = pcall(function() return ammo.Value end)
        if ok then state.ammo = value end
    end

    local reload = env.find_child(data, "reload")
    if reload then
        local reloading = env.find_child(reload, "reloading")
        if reloading then
            local ok, value = pcall(function() return reloading.Value end)
            if ok then state.reloading = value == true end
        end
    end

    return state
end

function M.cached_held()
    local name = M.get_held_tool_name()
    M._last_held = name
    return name
end

function M.holding_weapon()
    return M.get_held_weapon_inst() ~= nil
end

return M
