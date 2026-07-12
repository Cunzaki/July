local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local loot_catalog = July.require("game.loot_catalog")
local item_esp_catalog = July.require("game.item_esp_catalog")
local tier_util = July.require("game.tier_util")
local esp_scan = July.require("game.esp_scan")
local esp_util = July.require("core.esp_util")
local esp_render = July.require("core.esp_render")
local env = July.require("core.env")
local gpu_chams = July.require("core.gpu_chams")

local M = {}

local P = "havoc_loot_enabled"
local CHAMS_ID = "havoc_loot_gpu_chams"
local CHAMS_MODE = "havoc_loot_gpu_chams_mode"
local CHAMS_COLOR = "havoc_loot_gpu_chams_color"

local candidates = {}

local function clear_candidates()
    for i = 1, #candidates do
        candidates[i] = nil
    end
end

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

local function loot_chams_labels()
    return loot_catalog.MULTICOMBO_LABELS
end

local function loot_chams_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    local labels = loot_chams_labels()
    for i = 1, #labels do
        if gpu_chams.multicombo_selected(CHAMS_ID, i) then
            return true
        end
    end
    return false
end

local function collect_loot_chams(applied)
    local cam_pos
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok then cam_pos = pos end
    end
    if not cam_pos then return end

    local cx, cy, cz = cam_xyz(cam_pos)
    local max_dist = settings.num("havoc_loot_max_distance", 500)
    local max_sq = max_dist * max_dist
    local draw_cache = loot_scan.get_cache()

    for i = 1, #draw_cache do
        local entry = draw_cache[i]
        local category = entry and entry.category
        if not entry or not category or not loot_catalog.is_enabled(category) then
            goto continue
        end
        if entry.is_drop or item_esp_catalog.is_drop_category(category) then goto continue end
        if not env.is_valid(entry.inst or entry.model) then goto continue end

        local idx = loot_catalog.KEY_TO_INDEX[category.key]
        if not idx or not gpu_chams.multicombo_selected(CHAMS_ID, idx) then
            goto continue
        end

        local lx, ly, lz = esp_scan.entry_coords(entry)
        if not lx then goto continue end
        local dx, dy, dz = lx - cx, ly - cy, lz - cz
        if (dx * dx + dy * dy + dz * dz) > max_sq then goto continue end

        gpu_chams.cham_entry_part(entry, applied)

        ::continue::
    end
end

function M.register_gpu_menu(TAB, G, parent)
    if not gpu_chams.available() then return {} end

    local labels = loot_chams_labels()
    menu.add_multicombo(TAB, G, CHAMS_ID, "Loot Engine Chams", labels,
        gpu_chams.multicombo_defaults(#labels), { parent = parent })
    gpu_chams.add_mode_color_menu(TAB, G, parent, CHAMS_MODE, CHAMS_COLOR,
        "Loot Chams Mode", "Loot Chams Color")

    gpu_chams.register_owner("loot", {
        rescan_ms = 500,
        is_active = loot_chams_active,
        style = function()
            return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
        end,
        collect = collect_loot_chams,
    })
    gpu_chams.wire_style_controls("loot", CHAMS_MODE, CHAMS_COLOR)

    local function resync()
        if loot_chams_active() then
            gpu_chams.sync_owner("loot", true)
        else
            gpu_chams.clear_owner("loot")
        end
    end
    settings.on_change(CHAMS_ID, resync)
    settings.on_change(P, resync)
    for i = 1, #loot_catalog.MULTICOMBO_ENTRIES do
        local entry = loot_catalog.MULTICOMBO_ENTRIES[i]
        if entry and entry.key then
            settings.on_change(entry.key, resync)
        end
    end

    return { CHAMS_ID, CHAMS_MODE, CHAMS_COLOR }
end

function M.sync_gpu()
    if loot_chams_active() then
        gpu_chams.sync_owner("loot")
    end
end

function M.update()
end

function M.render(cam_pos)
    if not settings.enabled(P) then return end

    local draw_cache = loot_scan.get_cache()
    local n = #draw_cache
    if n == 0 then return end

    local constants = July.require("core.constants")

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
    local hide_sq = constants.ESP_HIDE_SQ or 9
    local budget = constants.ESP_RENDER_BUDGET or 100
    local cx, cy, cz = cam_xyz(cam_pos)

    clear_candidates()
    local count = 0

    for i = 1, n do
        local entry = draw_cache[i]
        local category = entry and entry.category
        if not entry or not category or not loot_catalog.is_enabled(category) then
            goto continue
        end
        if entry.is_drop or item_esp_catalog.is_drop_category(category) then goto continue end
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

        count = count + 1
        candidates[count] = {
            entry = entry,
            category = category,
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
        local category = item.category
        local lx, ly, lz = item.lx, item.ly, item.lz
        local dist = math.sqrt(item.dist_sq)

        local base_color
        if entry.is_drop then
            base_color = loot_rgb or loot_catalog.get_color(category) or entry.tier_color
        else
            base_color = entry.tier_color or loot_rgb or loot_catalog.get_color(category)
        end
        local box_color = loot_rgb or settings.color("havoc_loot_box", base_color)

        if box_on then
            esp_util.draw_entry_boxes(entry, box_color, 1, box_style)
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
