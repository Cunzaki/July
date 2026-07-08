local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 16

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < 0.1 then return 0.1 end
    if radius > 1 then return 1 end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast or not raycast.is_visible then
        return true
    end
    local ex, ey, ez = ox, oy + EYE_OFFSET_Y, oz
    return raycast.is_visible(ex, ey, ez, tx, ty, tz) == true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return M.is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function search_peek(origin, target_pos, max_radius, steps)
    max_radius = M.clamp_radius(max_radius)
    steps = steps or DEFAULT_STEPS

    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * max_radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * max_radius
        if M.is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
            return { x = cx, y = cy, z = cz }, max_radius
        end
    end

    return nil, max_radius
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}

    if not origin or not target_pos then
        return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return { state = "direct", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    local peek, radius = search_peek(origin, target_pos, opts.max_radius, opts.steps)
    if peek then
        return { state = "ready", peek = peek, radius = radius }
    end

    return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return { x = peek.x, y = peek.y + EYE_OFFSET_Y, z = peek.z }
end

return M
