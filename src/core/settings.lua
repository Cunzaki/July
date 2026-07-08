local M = {}

function M.get(id, default)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    if menu and menu.Get then
        local v = menu.Get(id)
        if v ~= nil then return v end
    end
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.enabled(id)
    if not menu then return false end
    local v = M.get(id, false)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return c end
    end
    if menu and menu.GetColor then
        local c = menu.GetColor(id)
        if c then return c end
    end
    return default or { 1, 1, 1, 1 }
end

function M.multicombo_get(id, index, default)
    local vals = M.get(id, nil)
    if type(vals) ~= "table" then return default end
    local v = vals[index]
    if v == nil then return default end
    return v == true
end

return M
