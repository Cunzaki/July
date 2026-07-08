local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local loot_catalog = July.require("game.loot_catalog")
local tier_util = July.require("game.tier_util")
local esp_render = July.require("core.esp_render")
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

local function dist_sq(a, b)
    local dx = (a.X or a.x or 0) - (b.X or b.x or 0)
    local dy = (a.Y or a.y or 0) - (b.Y or b.y or 0)
    local dz = (a.Z or a.z or 0) - (b.Z or b.z or 0)
    return dx * dx + dy * dy + dz * dz
end

local function draw_loot_box(loot, color, box_style)
    if not loot.part_pos or not next(loot.part_pos) then
        if loot.pos then
            local bounds = draw_util.get_entity_bounds_fallback(loot.pos)
            if bounds.valid then
                if box_style == 0 then
                    draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
                else
                    draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
                end
            end
        end
        return
    end

    if box_style == 2 then
        if loot.root and env.is_valid(loot.root) then
            draw_util.draw_root_3d_box(loot.root, color)
            return
        end
        if loot.part_pos and next(loot.part_pos) then
            draw_util.draw_entity_3d_box(loot.part_pos, loot.part_size, color)
        end
        return
    end

    local bounds = draw_util.get_entity_bounds(loot.part_pos, loot.part_size, loot.pos)
    if not bounds.valid then return end
    if box_style == 0 then
        draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
    else
        draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
    end
end

function M.render(cam_pos)
    if not settings.enabled("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    local n = #loot_cache
    if n == 0 then return end

    local constants = July.require("core.constants")

    local type_vals = settings.get("havoc_loot_types", {})
    local show_dist = settings.bool("havoc_loot_distance", false)
    local dist_pos = settings.num("havoc_loot_distance_pos", 0)
    local show_marker = settings.bool("havoc_loot_marker", false)
    local box_on = settings.bool("havoc_loot_box", false)
    local box_style = settings.num("havoc_loot_box_style", 2)
    local max_dist = settings.num("havoc_loot_max_distance", 500)
    local filter_idx = settings.num("havoc_loot_filter", 0)
    local text_size = settings.num("havoc_loot_text_size", 13)
    local loot_rgb = settings.bool("havoc_loot_rainbow", false) and color_util.rainbow_color(0.3) or nil
    local max_dist_sq = max_dist * max_dist
    local budget = constants.ESP_RENDER_BUDGET or 100
    local candidates = {}

    for i = 1, n do
        local loot = loot_cache[i]
        if loot.pos and loot.category and env.is_valid(loot.model) and loot_catalog.is_enabled(type_vals, loot.category) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked, loot.is_drop) then
                local dsq = dist_sq(cam_pos, loot.pos)
                if dsq <= max_dist_sq and (loot.is_drop or dsq > constants.ESP_HIDE_SQ) then
                    candidates[#candidates + 1] = {
                        loot = loot,
                        dist = math.sqrt(dsq),
                    }
                end
            end
        end
    end

    if #candidates == 0 then return end

    local draw_list = esp_render.pick_closest(candidates, budget)

    for i = 1, #draw_list do
        local entry = draw_list[i]
        local loot = entry.loot
        local dist = entry.dist
        local px = loot.pos.X or loot.pos.x
        local py = loot.pos.Y or loot.pos.y
        local pz = loot.pos.Z or loot.pos.z

        local sx, sy, sok = esp_render.w2s(px, py, pz)
        if not sok or not esp_render.on_screen(sx, sy) then
            goto continue_draw
        end

        local base_color
        if loot.is_drop and loot.category then
            base_color = loot_rgb or loot_catalog.get_color(loot.category) or loot.tier_color
        else
            base_color = loot.tier_color or loot_rgb or loot_catalog.get_color(loot.category)
        end
        local box_color = loot_rgb or settings.color("havoc_loot_box", base_color)

        if box_on and dist <= math.min(max_dist, 250) then
            draw_loot_box(loot, box_color, box_style)
        end

        local label = loot.category.display
        if loot.display_name then
            label = tier_util.get_item_label(loot.display_name)
        end
        draw_util.draw_loot_label(sx, sy, label, loot.is_locked, dist, show_dist, base_color,
            dist_pos, show_marker, text_size)

        ::continue_draw::
    end
end

return M
