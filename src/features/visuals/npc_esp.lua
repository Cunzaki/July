local constants = July.require("core.constants")
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")

local M = {}

local frame_counter = 0

local DISPLAY = {
    box = 1,
    fill = 2,
    name = 3,
    dist = 4,
    held_item = 5,
    npc_type = 6,
    health_bar = 7,
    health_text = 8,
    chams = 9,
    skeleton = 10,
}

local NPC_COLORS = {
    box = { 1.0, 1.0, 1.0, 1.0 },
    fill = { 1.0, 1.0, 1.0, 0.35 },
    name = { 0.92, 0.92, 0.92, 1.0 },
    dist = { 0.67, 0.67, 0.67, 1.0 },
    held_item = { 1.0, 0.85, 0.4, 1.0 },
    npc_type = { 1.0, 0.5, 0.0, 0.85 },
    health_text = { 0.3, 1.0, 0.4, 1.0 },
    chams = { 1.0, 0.2, 0.2, 0.55 },
    skeleton = { 1.0, 1.0, 1.0, 1.0 },
}

function M.set_frame_counter(n)
    frame_counter = n
end

local function display_on(vals, idx)
    return type(vals) == "table" and vals[idx] == true
end

local function get_npc_type(entity_name)
    if string.find(entity_name, "[Sniper]", 1, true) then return "Sniper" end
    if constants.NPC_BOSS_NAMES[entity_name] then return "Boss" end
    if entity_name == "Sentry" then return nil end
    return "Scav"
end

local function get_held_item_name(ent)
    local model_children = ent.model:GetChildren()
    if model_children then
        for i = 1, #model_children do
            local child = model_children[i]
            if child.ClassName == "Tool" then
                return child.Name
            end
        end
    end

    for _, part in pairs(ent.parts) do
        local children = part:GetChildren()
        if children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Model" and child:FindFirstChild("Handle") then
                    return child.Name
                end
            end
        end
    end

    return nil
end

function M.render(cam_pos)
    if not settings.enabled("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    if #entity_cache == 0 then return end

    local display = settings.get("havoc_npc_display", {})
    local ent_rgb = settings.bool("havoc_npc_rainbow", false) and color_util.rainbow_color(0.4) or nil

    local box_on = display_on(display, DISPLAY.box)
    local fill_on = display_on(display, DISPLAY.fill)
    local name_on = display_on(display, DISPLAY.name)
    local dist_on = display_on(display, DISPLAY.dist)
    local held_on = display_on(display, DISPLAY.held_item)
    local type_on = display_on(display, DISPLAY.npc_type)
    local health_bar_on = display_on(display, DISPLAY.health_bar)
    local health_text_on = display_on(display, DISPLAY.health_text)
    local chams_on = display_on(display, DISPLAY.chams)
    local skeleton_on = display_on(display, DISPLAY.skeleton)

    local box_style = settings.num("havoc_npc_box_style", 0)
    local chams_style = settings.num("havoc_npc_chams_style", 0)
    local hide_dead = settings.bool("havoc_npc_hide_dead", false)
    local max_dist = settings.num("havoc_npc_max_distance", 3000)

    local name_size = settings.num("havoc_npc_name_size", 13)
    local health_text_size = settings.num("havoc_npc_health_text_size", 8)
    local held_item_size = settings.num("havoc_npc_held_item_size", 10)
    local dist_size = settings.num("havoc_npc_distance_size", 10)
    local npc_type_size = settings.num("havoc_npc_npc_type_size", 9)

    local needs_full_bounds = box_on and box_style == 2

    local esp_opts = {
        box_style = box_style,
        name_size = name_size,
        health_text_size = health_text_size,
        held_item_size = held_item_size,
        dist_size = dist_size,
        npc_type_size = npc_type_size,
    }

    for i = 1, #entity_cache do
        local ent = entity_cache[i]

        local health = ent.humanoid.Health or 0
        local max_health = ent.humanoid.MaxHealth or 100

        if not (hide_dead and health <= 0) then
            local root_pos = ent.root.Position
            if root_pos then
                local dist = (cam_pos - root_pos).Magnitude
                if dist <= max_dist then
                    local sc = ent.scr_bounds
                    local do_update = (frame_counter + i) % constants.BOUNDS_UPDATE_INTERVAL == 0

                    if needs_full_bounds or chams_on or skeleton_on then
                        local part_pos = {}
                        for name, part in pairs(ent.parts) do
                            local pos = part.Position
                            if pos then part_pos[name] = pos end
                        end
                        local bounds = draw_util.get_entity_bounds(part_pos, ent.part_size, root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid

                        if chams_on and bounds.valid then
                            draw_util.draw_entity_chams(part_pos, ent.part_size, ent_rgb or NPC_COLORS.chams, chams_style)
                        end
                        if skeleton_on and bounds.valid then
                            draw_util.draw_entity_skeleton(part_pos, ent_rgb or NPC_COLORS.skeleton)
                        end
                        if needs_full_bounds and bounds.valid then
                            draw_util.draw_entity_3d_box(part_pos, ent.part_size, ent_rgb or NPC_COLORS.box)
                        end
                    elseif do_update then
                        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                    end

                    if sc.valid then
                        local name_str = ent.model.Name
                        esp_opts.box = box_on
                        esp_opts.box_color = ent_rgb or NPC_COLORS.box
                        esp_opts.box_fill = fill_on
                        esp_opts.box_fill_color = ent_rgb or NPC_COLORS.fill
                        esp_opts.name = name_on
                        esp_opts.name_color = ent_rgb or NPC_COLORS.name
                        esp_opts.dist = dist_on
                        esp_opts.dist_color = ent_rgb or NPC_COLORS.dist
                        esp_opts.health_bar = health_bar_on
                        esp_opts.health_text = health_text_on
                        esp_opts.health_text_color = ent_rgb or NPC_COLORS.health_text
                        esp_opts.npc_type_on = type_on
                        esp_opts.npc_type_color = ent_rgb or NPC_COLORS.npc_type
                        esp_opts.health = health
                        esp_opts.max_health = max_health
                        esp_opts.held_item = held_on and get_held_item_name(ent) or nil
                        esp_opts.held_item_color = ent_rgb or NPC_COLORS.held_item
                        esp_opts.npc_type = get_npc_type(name_str)

                        draw_util.draw_esp({ x = sc.x, y = sc.y, w = sc.w, h = sc.h, valid = true }, name_str, dist, esp_opts)
                    end
                end
            end
        end
    end
end

return M
