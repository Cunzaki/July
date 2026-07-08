local M = {}

M.TRAP_TYPES = {
    { key = "trap_tripmine", display = "Tripmine", color = { 1.0, 0.5, 0.0, 1.0 } },
    { key = "trap_mine", display = "Mine", color = { 1.0, 0.2, 0.0, 1.0 } },
    { key = "trap_alarm", display = "Alarm", color = { 1.0, 0.0, 0.0, 1.0 } },
    { key = "trap_airstrike", display = "Airstrike Alarm", color = { 1.0, 0.1, 0.1, 1.0 } },
    { key = "trap_barrel", display = "Explosive Barrel", color = { 1.0, 0.3, 0.0, 1.0 } },
    { key = "trap_sentry", display = "Sentry", color = { 0.8, 0.0, 0.0, 1.0 } },
    { key = "trap_gas", display = "Toxic Gas", color = { 0.2, 0.8, 0.0, 1.0 } },
}

M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

for i = 1, #M.TRAP_TYPES do
    M.MULTICOMBO_LABELS[i] = M.TRAP_TYPES[i].display
    M.MULTICOMBO_DEFAULTS[i] = true
    M.KEY_TO_INDEX[M.TRAP_TYPES[i].key] = i
end

function M.is_enabled(trap_type)
    if not trap_type or not trap_type.key then return false end
    local settings = July.require("core.settings")
    return settings.bool(trap_type.key, true)
end

function M.get_color(trap_type)
    if not trap_type or not trap_type.key then return { 1, 0.2, 0, 1 } end
    local settings = July.require("core.settings")
    return settings.color(trap_type.key, trap_type.color or { 1, 0.2, 0, 1 })
end

return M
