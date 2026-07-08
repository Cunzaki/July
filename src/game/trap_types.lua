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

function M.is_enabled(vals, trap_type)
    if type(vals) ~= "table" or not trap_type then return false end
    local idx = M.KEY_TO_INDEX[trap_type.key]
    if not idx then return false end
    return vals[idx] == true
end

function M.get_color(trap_type)
    if trap_type and trap_type.color then return trap_type.color end
    return { 1, 0.2, 0, 1 }
end

return M
