local M = {}

function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.distance_sq(a, b)
    if not a or not b then return math.huge end
    return M.distance3(a.x - b.x, a.y - b.y, a.z - b.z) ^ 2
end

function M.screen_fov_dist_sq(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return dx * dx + dy * dy
end

function M.screen_fov_dist(sx, sy, cx, cy)
    return math.sqrt(M.screen_fov_dist_sq(sx, sy, cx, cy))
end

return M
