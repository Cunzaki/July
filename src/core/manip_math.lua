local M = {}

local DEFAULT_STEPS = 12
local MIN_RADIUS = 0.1
local MAX_RADIUS = 8
local CACHE_MS = 200

local cache = {
    key = nil,
    result = nil,
    time = 0,
}

function M.eye_offset_y()
    return 0
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

local function now_ms()
    if utility and utility.get_tick_count then
        return utility.get_tick_count()
    end
    return os.clock() * 1000
end

local function cache_key(origin, target_pos, max_radius)
    return string.format(
        "%.0f_%.0f_%.0f_%.0f_%.0f_%.0f_%.1f",
        origin.x, origin.y, origin.z,
        target_pos.x, target_pos.y, target_pos.z,
        max_radius or 1
    )
end

local function ray_ready()
    if not raycast then return false end
    if not raycast.is_ready then return true end
    return raycast.is_ready() == true
end

local function is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast then return true end
    if not ray_ready() then return true end

    if raycast.is_visible and raycast.is_visible(ox, oy, oz, tx, ty, tz) == true then
        return true
    end

    if raycast.cast then
        local dx, dy, dz = tx - ox, ty - oy, tz - oz
        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
        if len < 0.05 then return true end
        local hit, _, dist = raycast.cast(ox, oy, oz, tx, ty, tz)
        if not hit then return true end
        if dist and dist >= len - 1.5 then return true end
        return false
    end

    return true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function any_origin_visible(origins, target_pos)
    for i = 1, #origins do
        local o = origins[i]
        if o and M.is_visible_from_pos(o, target_pos) then
            return true
        end
    end
    return false
end

local function search_peek(origin, target_pos, max_radius, steps)
    max_radius = M.clamp_radius(max_radius)
    steps = steps or DEFAULT_STEPS

    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * max_radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * max_radius
        if is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
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

    local max_r = M.clamp_radius(opts.max_radius)
    if not opts.force then
        local key = cache_key(origin, target_pos, max_r)
        local t = now_ms()
        if cache.key == key and (t - cache.time) < CACHE_MS then
            return cache.result
        end
    end

    local result
    local origins = { origin }
    if opts.alt_origins then
        for i = 1, #opts.alt_origins do
            origins[#origins + 1] = opts.alt_origins[i]
        end
    end

    if any_origin_visible(origins, target_pos) then
        result = { state = "direct", peek = nil, radius = max_r }
    else
        local peek, radius = search_peek(origin, target_pos, max_r, opts.steps or DEFAULT_STEPS)
        if peek then
            result = { state = "ready", peek = peek, radius = radius }
        else
            result = { state = "blocked", peek = nil, radius = max_r }
        end
    end

    if not opts.force then
        cache.key = cache_key(origin, target_pos, max_r)
        cache.result = result
        cache.time = now_ms()
    end

    return result
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return { x = peek.x, y = peek.y, z = peek.z }
end

function M.ring_y(origin)
    if not origin then return 0 end
    return origin.y
end

function M.invalidate_cache()
    cache.key = nil
    cache.result = nil
    cache.time = 0
end

return M
