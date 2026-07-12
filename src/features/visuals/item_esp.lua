local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local item_esp_catalog = July.require("game.item_esp_catalog")
local tier_util = July.require("game.tier_util")
local esp_scan = July.require("game.esp_scan")
local esp_util = July.require("core.esp_util")
local esp_render = July.require("core.esp_render")
local env = July.require("core.env")
local item_categories = July.require("game.item_categories")
local menu_util = July.require("core.menu_util")

local M = {}

local P = "havoc_item_enabled"
local candidates = {}

local function clear_candidates()
    for i = 1, #candidates do
        candidates[i] = nil
    end
end

local function cam_xyz(cam_pos)
    if not cam_pos then return 0, 0, 0 end
    return cam_pos.X or cam_pos.x or 0, cam_pos.Y or cam_pos.y or 0, cam_pos.Z or cam_pos.z or 0
end

function M.register_menu(TAB, G)
    local ids = {}
    menu_util.register_keybind(TAB, G, P, "Enable Item ESP", false)

    menu.add_checkbox(TAB, G, "havoc_item_show_guns", "Show Dropped Guns", true, { parent = P })
    menu.add_checkbox(TAB, G, "havoc_item_show_keycards", "Show Keycards", true, { parent = P })
    menu.add_checkbox(TAB, G, "havoc_item_show_body_bags", "Show Body Bags", true, { parent = P })

    for si = 1, #item_categories.SECTIONS do
        local sec = item_categories.SECTIONS[si]
        local labels = sec.items or {}
        local defaults = {}
        for i = 1, #labels do
            defaults[i] = true
        end
        local mcb_id = item_esp_catalog.section_multicombo_id(sec.id)
        menu.add_multicombo(TAB, G, mcb_id, sec.label, labels, defaults, { parent = P })
        ids[#ids + 1] = mcb_id

        for ii = 1, #labels do
            local color_id = item_esp_catalog.item_color_id(sec.id, ii)
            local default = item_esp_catalog.SECTION_COLORS[sec.id] or { 1, 1, 1, 1 }
            menu.add_colorpicker(TAB, G, color_id, labels[ii], default, { parent = P })
            menu_util.COLOR_DEFAULTS[color_id] = default
            ids[#ids + 1] = color_id
        end
    end

    menu.add_checkbox(TAB, G, "havoc_item_box", "Item Box", false,
        { parent = P, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, G, "havoc_item_box_style", "Item Box Style",
        { "Corners", "Outline", "3D Box" }, 2, { parent = P })
    menu.add_checkbox(TAB, G, "havoc_item_distance", "Item Show Distance", false, { parent = P })
    menu.add_combo(TAB, G, "havoc_item_distance_pos", "Item Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = P })
    menu.add_checkbox(TAB, G, "havoc_item_marker", "Item Position Marker", false, { parent = P })
    menu.add_checkbox(TAB, G, "havoc_item_rainbow", "Item Rainbow", false, { parent = P })
    menu.add_slider_int(TAB, G, "havoc_item_text_size", "Item Text Size", 1, 15, 13, { parent = P })
    menu.add_slider_int(TAB, G, "havoc_item_max_distance", "Item Max Distance", 0, 2000, 500, { parent = P })

    ids[#ids + 1] = "havoc_item_show_guns"
    ids[#ids + 1] = "havoc_item_show_keycards"
    ids[#ids + 1] = "havoc_item_show_body_bags"
    ids[#ids + 1] = "havoc_item_box"
    ids[#ids + 1] = "havoc_item_box_style"
    ids[#ids + 1] = "havoc_item_distance"
    ids[#ids + 1] = "havoc_item_distance_pos"
    ids[#ids + 1] = "havoc_item_marker"
    ids[#ids + 1] = "havoc_item_rainbow"
    ids[#ids + 1] = "havoc_item_text_size"
    ids[#ids + 1] = "havoc_item_max_distance"
    ids[#ids + 1] = P .. "_mode"

    menu_util.bind_children(P, ids)
    menu_util.bind_children("havoc_item_box", { "havoc_item_box_style" })
    menu_util.bind_children("havoc_item_distance", { "havoc_item_distance_pos" })

    return ids
end

function M.update()
end

function M.render(cam_pos)
    if not settings.enabled(P) then return end

    local base_drops = loot_scan.get_drops()
    local show_bags = settings.bool("havoc_item_show_body_bags", true)
    local draw_drops = base_drops
    if show_bags then
        draw_drops = {}
        for i = 1, #base_drops do
            draw_drops[i] = base_drops[i]
        end
        local static = loot_scan.get_cache()
        for i = 1, #static do
            local entry = static[i]
            local cat = entry and entry.category
            if entry and cat and cat.loot_type == "body.bag" and not entry.is_drop then
                draw_drops[#draw_drops + 1] = entry
            end
        end
    end

    local n = #draw_drops
    if n == 0 then return end

    local constants = July.require("core.constants")
    local show_dist = settings.bool("havoc_item_distance", false)
    local dist_pos = settings.num("havoc_item_distance_pos", 0)
    local show_marker = settings.bool("havoc_item_marker", false)
    local box_on = settings.bool("havoc_item_box", false)
    local box_style = settings.num("havoc_item_box_style", 2)
    local max_dist = settings.num("havoc_item_max_distance", 500)
    local text_size = settings.num("havoc_item_text_size", 13)
    local item_rgb = settings.bool("havoc_item_rainbow", false) and color_util.rainbow_color(0.3) or nil
    local max_dist_sq = max_dist * max_dist
    local budget = constants.ESP_RENDER_BUDGET or 80
    local cx, cy, cz = cam_xyz(cam_pos)

    clear_candidates()
    local count = 0

    for i = 1, n do
        local entry = draw_drops[i]
        local category = entry and entry.category
        if not entry or not category then goto continue end
        if not ((entry.root and env.is_valid(entry.root)) or (entry.inst and env.is_valid(entry.inst))) then
            goto continue
        end

        local name = entry.display_name or category.display
        if not item_esp_catalog.is_item_enabled(name, category) then goto continue end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end

        local dx, dy, dz = lx - cx, ly - cy, lz - cz
        local dist_sq = dx * dx + dy * dy + dz * dz
        if dist_sq > max_dist_sq then goto continue end

        count = count + 1
        candidates[count] = {
            entry = entry,
            name = name,
            lx = lx,
            ly = ly,
            lz = lz,
            dist_sq = dist_sq,
        }

        ::continue::
    end

    if count == 0 then return end

    local draw_list = esp_render.pick_closest(candidates, budget)

    for i = 1, #draw_list do
        local item = draw_list[i]
        local entry = item.entry
        local lx, ly, lz = item.lx, item.ly, item.lz
        local dist = math.sqrt(item.dist_sq)
        local base_color = item_rgb or item_esp_catalog.get_item_color(item.name)
        local box_color = item_rgb or settings.color("havoc_item_box", base_color)

        if box_on then
            esp_util.draw_entry_boxes(entry, box_color, 1, box_style)
        end

        local sx, sy, vis = esp_util.w2s(lx, ly, lz)
        if not vis then goto continue end

        local label = tier_util.get_item_label(item.name)
        draw_util.draw_loot_label(sx, sy, label, false, dist, show_dist, base_color,
            dist_pos, show_marker, text_size)

        ::continue::
    end
end

return M
