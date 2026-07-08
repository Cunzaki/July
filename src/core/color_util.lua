local M = {}

function M.hsv_to_rgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return { v, t, p, 1.0 }
    elseif i == 1 then return { q, v, p, 1.0 }
    elseif i == 2 then return { p, v, t, 1.0 }
    elseif i == 3 then return { p, q, v, 1.0 }
    elseif i == 4 then return { t, p, v, 1.0 }
    else return { v, p, q, 1.0 } end
end

function M.rainbow_color(speed)
    local hue = (os.clock() * (speed or 0.5)) % 1
    return M.hsv_to_rgb(hue, 1, 1)
end

function M.health_bar_color(health, max_health)
    local pct = health / max_health
    if pct > 0.6 then return { 0.2, 1.0, 0.3, 1.0 }
    elseif pct > 0.3 then return { 1.0, 0.8, 0.1, 1.0 }
    else return { 1.0, 0.2, 0.2, 1.0 } end
end

return M
