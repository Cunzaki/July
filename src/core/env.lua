local M = {}

function M.has_api(name)
    return _G[name] ~= nil
end

function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

function M.is_valid(inst)
    if not inst or not utility then return false end
    return utility.is_valid(inst)
end

function M.get_workspace()
    if game and game.Workspace then return game.Workspace end
    if game and game.workspace then return game.workspace end
    return M.safe_call(function() return workspace end)
end

function M.get_local_player()
    if entity and entity.GetLocalPlayer then
        return entity.GetLocalPlayer()
    end
    if entity and entity.get_local_player then
        return entity.get_local_player()
    end
    return nil
end

function M.find_child(parent, name)
    if not parent then return nil end
    return M.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

return M
