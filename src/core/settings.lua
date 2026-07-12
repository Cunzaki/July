local M = {}

local _callbacks = {}

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
    local ok, fb = pcall(function()
        return July.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(id) then
        return fb.active(id)
    end

    if not menu then return false end
    local v = M.get(id, false)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.combo_index(id, labels, default)
    default = default or 0
    local v = M.get(id, default)
    if type(v) == "string" then
        local lower = v:lower()
        for i, label in ipairs(labels or {}) do
            if label:lower() == lower then return i - 1 end
        end
        return default
    end
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

function M.color(id, default)
    default = default or { 1, 1, 1, 1 }
    local color_util = July.require("core.color_util")

    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return color_util.normalize_rgba(c, default) end
    end
    if menu and menu.GetColor then
        local c = menu.GetColor(id)
        if c then return color_util.normalize_rgba(c, default) end
    end
    return color_util.normalize_rgba(default, { 1, 1, 1, 1 })
end

local function as_bool(v, default)
    if v == nil then return default == true end
    if v == false or v == 0 or v == "false" or v == "0" then return false end
    return v == true or v == 1 or v == "true" or v == "1"
end

function M.multicombo_get(id, index, default)
    local vals = M.get(id, nil)
    if type(vals) ~= "table" then return default == true end
    local v = vals[index]
    if v == nil and index >= 1 then
        v = vals[index - 1]
    end
    return as_bool(v, default)
end

-- Alias used by GPU chams / April-style multicombos (1-based index).
function M.multi(id, index, default)
    return M.multicombo_get(id, index, default)
end

function M.on_change(id, fn)
    if not id or not fn then return end
    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn
    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

return M
