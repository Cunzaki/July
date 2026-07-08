--[[ Toggle / Hold keybind polling — April Fallen pattern for Vector menu checkboxes. ]]

local settings = July.require("core.settings")

local M = {}

M.MODES = { "Toggle", "Hold" }

local registry = {}
local last_down = {}

function M.register(spec)
    if not spec or not spec.id then return end
    registry[spec.id] = {
        id = spec.id,
        mode_id = spec.mode_id or (spec.id .. "_mode"),
        key_id = spec.key_id or spec.id,
    }
end

function M.is_registered(id)
    return registry[id] ~= nil
end

function M.get_key(id)
    local e = registry[id]
    local key_id = e and e.key_id or id
    if menu and menu.get_key then
        local k = menu.get_key(key_id)
        if k and k > 0 then return k end
    end
    return 0
end

function M.is_hold(id)
    local e = registry[id]
    if not e then return false end
    return settings.combo_index(e.mode_id, M.MODES, 0) == 1
end

function M.armed(id)
    return settings.bool(id, false)
end

function M.active(id)
    if not registry[id] then
        return settings.bool(id, false)
    end

    if M.is_hold(id) then
        if not M.armed(id) then return false end
        local key = M.get_key(id)
        if key <= 0 then return false end
        return input and input.is_key_down and input.is_key_down(key)
    end

    return M.armed(id)
end

function M.tick()
    if not input or not input.is_key_down then return end

    for id in pairs(registry) do
        if M.is_hold(id) then
            last_down[id] = input.is_key_down(M.get_key(id))
        else
            local key = M.get_key(id)
            if key > 0 then
                local down = input.is_key_down(key)
                if down and not last_down[id] then
                    local cur = settings.bool(id, false)
                    if menu and menu.set then
                        pcall(menu.set, id, not cur)
                    end
                end
                last_down[id] = down
            end
        end
    end
end

return M
