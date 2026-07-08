local M = {}

M.MODES = { "Direct", "Snap", "Deep" }

local BACK_OFFSET = {
    Direct = 3.5,
    Snap = 1.75,
    Deep = 6.0,
}

function M.mode_name(idx)
    return M.MODES[(idx or 0) + 1] or "Direct"
end

function M.track_origin(camera, aim, mode_name)
    if not camera or not aim then return nil end
    local back = BACK_OFFSET[mode_name] or BACK_OFFSET.Direct
    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return aim end
    local inv = back / len
    return {
        x = aim.x - dx * inv,
        y = aim.y - dy * inv,
        z = aim.z - dz * inv,
    }
end

function M.build_path(mode_name, origin, aim)
    if not origin or not aim then return {} end
    return { origin, aim }
end

return M
