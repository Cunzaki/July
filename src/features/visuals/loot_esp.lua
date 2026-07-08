local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local loot_catalog = July.require("game.loot_catalog")
local tier_util = July.require("game.tier_util")
local esp_scan = July.require("game.esp_scan")
local esp_util = July.require("core.esp_util")
local env = July.require("core.env")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val, is_drop)
    if is_drop then
        if filter_idx == 1 or filter_idx == 3 or filter_idx == 4 then
            return false
        end
        return true
    end
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

local function cam_xyz(cam_pos)
    if not cam_pos then return 0, 0, 0 end
    return cam_pos.X or cam_pos.x or 0, cam_pos.Y or cam_pos.y or 0, cam_pos.Z or cam_pos.z or 0
end

function M.render(cam_pos)
    if not settings.enabled("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    local n = #loot_cache
    if n == 0 then return end

    local constants = July.require("core.constants")

    local show_dist = settings.bool("havoc_loot_distance", false)
    local dist_pos = settings.num("havoc_loot_distance_pos", 0)
    local show_marker = settings.bool("havoc_loot_marker", false)
    local box_on = settings.bool("havoc_loot_box", false)
    local box_style = settings.num("havoc_loot_box_style", 2)
    local draw_3d = box_on and box_style == 2
    local max_dist = settings.num("havoc_loot_max_distance", 500)
    local filter_idx = settings.num("havoc_loot_filter", 0)
    local text_size = settings.num("havoc_loot_text_size", 13)
    local loot_rgb = settings.bool("havoc_loot_rainbow", false) and color_util.rainbow_color(0.3) or nil
    local max_dist_sq = max_dist * max_dist
    local hide_sq = constants.ESP_HIDE_SQ or 9
    local cx, cy, cz = cam_xyz(cam_pos)

    for i = 1, n do
        local entry = loot_cache[i]
        local category = entry and entry.category
        if not entry or not category or not loot_catalog.is_enabled(category) then
            goto continue
        end
        if not env.is_valid(entry.model) then goto continue end
        if not loot_passes_filter(filter_idx, entry.is_open, entry.is_locked, entry.is_drop) then
            goto continue
        end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dx, dy, dz = lx - cx, ly - cy, lz - cz
        local dist_sq = dx * dx + dy * dy + dz * dz
        if dist_sq > max_dist_sq then goto continue end
        if not entry.is_drop and dist_sq <= hide_sq then goto continue end

        local dist = math.sqrt(dist_sq)

        local base_color
        if entry.is_drop then
            base_color = loot_rgb or loot_catalog.get_color(category) or entry.tier_color
        else
            base_color = entry.tier_color or loot_rgb or loot_catalog.get_color(category)
        end
        local box_color = loot_rgb or settings.color("havoc_loot_box", base_color)

        if draw_3d then
            esp_util.draw_entry_boxes(entry, box_color, 1)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if not vis then goto continue end

        local label = category.display
        if entry.display_name then
            label = tier_util.get_item_label(entry.display_name)
        end
        draw_util.draw_loot_label(sx, sy, label, entry.is_locked, dist, show_dist, base_color,
            dist_pos, show_marker, text_size)

        ::continue::
    end
end

return M
