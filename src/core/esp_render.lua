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

--[[ Pick closest N entries without sorting the full candidate list. ]]
function M.pick_closest(entries, budget)
    budget = budget or #entries
    local n = #entries
    if n <= budget then
        return entries
    end

    local best = {}
    local best_key = {}
    local count = 0

    for i = 1, n do
        local entry = entries[i]
        local key = entry.dist_sq or entry.dist or 0
        if count < budget then
            count = count + 1
            best[count] = entry
            best_key[count] = key
        else
            local worst_i, worst_key = 1, best_key[1]
            for j = 2, count do
                if best_key[j] > worst_key then
                    worst_i = j
                    worst_key = best_key[j]
                end
            end
            if key < worst_key then
                best[worst_i] = entry
                best_key[worst_i] = key
            end
        end
    end

    return best
end

return M
