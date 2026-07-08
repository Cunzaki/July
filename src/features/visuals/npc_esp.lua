local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")
local tier_util = July.require("game.tier_util")
local npc_types = July.require("game.npc_types")
local constants = July.require("core.constants")
local env = July.require("core.env")

local M = {}

local frame_counter = 0

function M.set_frame_counter(n)
    frame_counter = n
end

local function get_npc_type(ent)
    return npc_types.display_type(ent)
end

local function npc_type_allowed(npc_type)
    if npc_type == "Boss" then return settings.bool("havoc_npc_show_boss", true) end
    if npc_type == "Sniper" then return settings.bool("havoc_npc_show_sniper", true) end
    if npc_type == "Scav" then return settings.bool("havoc_npc_show_scav", true) end
    return true
end

local function collect_part_positions(ent)
    local part_pos = {}
    for name, part in pairs(ent.parts) do
        if env.is_valid(part) then
            local ok, pos = pcall(function() return part.Position end)
            if ok and pos then
                part_pos[name] = pos
            end
        end
    end
    return part_pos
end

function M.render(cam_pos)
    if not settings.enabled("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    local n = #entity_cache
    if n == 0 then return end

    local ent_rgb = settings.bool("havoc_npc_rainbow", false) and color_util.rainbow_color(0.4) or nil

    local box_on = settings.bool("havoc_npc_box", false)
    local fill_on = settings.bool("havoc_npc_box_fill", false)
    local name_on = settings.bool("havoc_npc_name", false)
    local dist_on = settings.bool("havoc_npc_distance", false)
    local held_on = settings.bool("havoc_npc_held_item", false)
    local type_on = settings.bool("havoc_npc_npc_type", false)
    local health_bar_on = settings.bool("havoc_npc_health_bar", false)
    local health_text_on = settings.bool("havoc_npc_health_text", false)
    local chams_on = settings.bool("havoc_npc_chams", false)
    local skeleton_on = settings.bool("havoc_npc_skeleton", false)

    local box_style = settings.num("havoc_npc_box_style", 0)
    local chams_style = settings.num("havoc_npc_chams_style", 0)
    local hide_dead = settings.bool("havoc_npc_hide_dead", false)
    local max_dist = math.min(settings.num("havoc_npc_max_distance", 1000), 1000)

    local name_size = settings.num("havoc_npc_name_size", 13)
    local health_text_size = settings.num("havoc_npc_health_text_size", 8)
    local held_item_size = settings.num("havoc_npc_held_item_size", 10)
    local dist_size = settings.num("havoc_npc_distance_size", 10)
    local npc_type_size = settings.num("havoc_npc_npc_type_size", 9)

    local needs_full_bounds = box_on and box_style == 2
    local heavy_on = chams_on or skeleton_on or needs_full_bounds
    local heavy_stride = heavy_on and math.max(1, math.ceil(n / constants.NPC_CHAMS_BUDGET)) or 1
    local heavy_budget = 0

    local esp_opts = {
        box_style = box_style,
        name_size = name_size,
        health_text_size = health_text_size,
        held_item_size = held_item_size,
        dist_size = dist_size,
        npc_type_size = npc_type_size,
    }

    for i = 1, n do
        local ent = entity_cache[i]
        if not entity_scan.is_entry_valid(ent) then goto continue_ent end

        local health = ent.humanoid.Health or 0
        local max_health = ent.humanoid.MaxHealth or 100

        if hide_dead and health <= 0 then goto continue_ent end

        local root_pos = ent._live_pos
        if not root_pos then
            local ok_pos, pos = pcall(function() return ent.root.Position end)
            if not ok_pos or not pos then goto continue_ent end
            root_pos = pos
        end

        local dist = (cam_pos - root_pos).Magnitude
        if dist > max_dist then goto continue_ent end

        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
        if not bounds.valid then goto continue_ent end

        if heavy_on and heavy_budget < constants.NPC_CHAMS_BUDGET then
            if ((frame_counter + i) % heavy_stride) == 0 then
                local part_pos = collect_part_positions(ent)
                if next(part_pos) then
                    if chams_on then
                        draw_util.draw_entity_chams(part_pos, ent.part_size,
                            ent_rgb or settings.color("havoc_npc_chams", { 1, 0.2, 0.2, 0.55 }), chams_style)
                    end
                    if skeleton_on then
                        draw_util.draw_entity_skeleton(part_pos,
                            ent_rgb or settings.color("havoc_npc_skeleton", { 1, 1, 1, 1 }))
                    end
                    if needs_full_bounds then
                        draw_util.draw_entity_3d_box(part_pos, ent.part_size,
                            ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 }))
                    end
                end
                heavy_budget = heavy_budget + 1
            end
        end

        local name_str = ent.model.Name
        local npc_type = get_npc_type(ent)
        if npc_type and not npc_type_allowed(npc_type) then goto continue_ent end

        local held_name = ent._held_name
        local held_color = held_name and tier_util.get_esp_color(held_name)
            or settings.color("havoc_npc_held_item", { 1, 0.85, 0.4, 1 })

        esp_opts.box = box_on
        esp_opts.box_color = ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 })
        esp_opts.box_fill = fill_on
        esp_opts.box_fill_color = ent_rgb or settings.color("havoc_npc_box_fill", { 1, 1, 1, 0.35 })
        esp_opts.name = name_on
        esp_opts.name_color = ent_rgb or settings.color("havoc_npc_name", { 0.92, 0.92, 0.92, 1 })
        esp_opts.dist = dist_on
        esp_opts.dist_color = ent_rgb or settings.color("havoc_npc_distance", { 0.67, 0.67, 0.67, 1 })
        esp_opts.health_bar = health_bar_on
        esp_opts.health_text = health_text_on
        esp_opts.health_text_color = ent_rgb or settings.color("havoc_npc_health_text", { 0.3, 1, 0.4, 1 })
        esp_opts.npc_type_on = type_on
        esp_opts.npc_type_color = ent_rgb or settings.color("havoc_npc_npc_type", { 1, 0.5, 0, 0.85 })
        esp_opts.health = health
        esp_opts.max_health = max_health
        esp_opts.held_item = held_on and held_name or nil
        esp_opts.held_item_color = ent_rgb or held_color
        esp_opts.npc_type = npc_type

        draw_util.draw_esp(bounds, name_str, dist, esp_opts)

        ::continue_ent::
    end
end

return M
