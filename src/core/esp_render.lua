local M = {}

function M.screen_size()
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    if input and input.GetScreenSize then
        return input.GetScreenSize()
    end
    return 1920, 1080
end

function M.on_screen(sx, sy, pad)
    pad = pad or 48
    local sw, sh = M.screen_size()
    return sx >= -pad and sx <= sw + pad and sy >= -pad and sy <= sh + pad
end

function M.w2s(x, y, z)
    if utility and utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.pick_closest(entries, budget)
    budget = budget or #entries
    if #entries <= budget then
        return entries
    end
    table.sort(entries, function(a, b)
        return a.dist < b.dist
    end)
    local out = {}
    for i = 1, budget do
        out[i] = entries[i]
    end
    return out
end

return M
