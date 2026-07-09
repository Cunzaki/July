local settings = July.require("core.settings")

local M = {}

M.MODES = { "Toggle", "Hold" }

local registry = {}
local last_down = {}
local toggled = {}

function M.register(spec)
    if not spec or not spec.id then return end
    registry[spec.id] = {
        id = spec.id,
        master_id = spec.master_id,
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
    local e = registry[id]
    if e and e.master_id then
        return settings.bool(e.master_id, false)
    end
    return settings.bool(id, false)
end

function M.active(id)
    if not registry[id] then
        return settings.bool(id, false)
    end

    if not M.armed(id) then return false end

    local key = M.get_key(id)
    if key <= 0 then return true end

    if M.is_hold(id) then
        return input and input.is_key_down and input.is_key_down(key)
    end

    local e = registry[id]
    if e and e.master_id then
        return toggled[id] == true
    end

    return M.armed(id)
end

function M.tick()
    if not input or not input.is_key_down then return end

    for id in pairs(registry) do
        local key = M.get_key(id)
        if M.is_hold(id) then
            if key > 0 then
                last_down[id] = input.is_key_down(key)
            end
        elseif key > 0 then
            local down = input.is_key_down(key)
            if down and not last_down[id] then
                local e = registry[id]
                if e and e.master_id then
                    toggled[id] = not toggled[id]
                else
                    local cur = settings.bool(id, false)
                    if menu and menu.set then
                        pcall(menu.set, id, not cur)
                    end
                end
            end
            last_down[id] = down
        end
    end
end

function M.get_key_ids()
    local seen = {}
    local out = {}
    for _, e in pairs(registry) do
        local key_id = e.key_id or e.id
        if key_id and not seen[key_id] then
            seen[key_id] = true
            out[#out + 1] = key_id
        end
    end
    table.sort(out)
    return out
end

function M.reset_runtime_state()
    last_down = {}
    toggled = {}
end

return M
