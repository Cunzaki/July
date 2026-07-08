local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local loot_catalog = July.require("game.loot_catalog")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val)
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

function M.render(cam_pos)
    if not settings.enabled("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    if #loot_cache == 0 then return end

    local type_vals = settings.get("havoc_loot_types", {})
    local show_dist = settings.bool("havoc_loot_distance", false)
    local dist_pos = settings.num("havoc_loot_distance_pos", 0)
    local show_marker = settings.bool("havoc_loot_marker", false)
    local max_dist = settings.num("havoc_loot_max_distance", 5000)
    local filter_idx = settings.num("havoc_loot_filter", 0)
    local text_size = settings.num("havoc_loot_text_size", 13)
    local loot_rgb = settings.bool("havoc_loot_rainbow", false) and color_util.rainbow_color(0.3) or nil

    for i = 1, #loot_cache do
        local loot = loot_cache[i]

        if loot.pos and loot_catalog.is_enabled(type_vals, loot.category) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked) then
                local dist = (cam_pos - loot.pos).Magnitude
                if dist <= max_dist then
                    local sx, sy, sok = utility.WorldToScreen(loot.pos.X, loot.pos.Y, loot.pos.Z)
                    if sok then
                        local color = loot_rgb or loot_catalog.get_color(loot.category)
                        draw_util.draw_loot_label(sx, sy, loot.category.display, loot.is_locked, dist, show_dist, color,
                            dist_pos, show_marker, text_size)
                    end
                end
            end
        end
    end
end

return M
