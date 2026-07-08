local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val)
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

function M.render(cam_pos)
    if not menu.Get("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    if #loot_cache == 0 then return end

    local show_dist = menu.Get("havoc_loot_distance")
    local dist_pos = menu.Get("havoc_loot_distance_pos")
    local show_marker = menu.Get("havoc_loot_marker")
    local max_dist = menu.Get("havoc_loot_max_distance")
    local filter_idx = menu.Get("havoc_loot_filter")
    local text_size = menu.Get("havoc_loot_text_size")
    local loot_rgb = menu.Get("havoc_loot_rainbow") and color_util.rainbow_color(0.3) or nil
    local group_color = menu.GetColor("havoc_loot_enabled")

    for i = 1, #loot_cache do
        local loot = loot_cache[i]

        if loot.pos and menu.Get(loot.category.key) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked) then
                local dist = (cam_pos - loot.pos).Magnitude
                if dist <= max_dist then
                    local sx, sy, sok = utility.WorldToScreen(loot.pos.X, loot.pos.Y, loot.pos.Z)
                    if sok then
                        local color = loot_rgb or group_color
                        draw_util.draw_loot_label(sx, sy, loot.category.display, loot.is_locked, dist, show_dist, color,
                            dist_pos, show_marker, text_size)
                    end
                end
            end
        end
    end
end

return M
