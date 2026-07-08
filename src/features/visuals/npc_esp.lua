local constants = July.require("core.constants")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")

local M = {}

local frame_counter = 0

function M.set_frame_counter(n)
    frame_counter = n
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
    if not menu.Get("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    if #entity_cache == 0 then return end

    local ent_rgb = menu.Get("havoc_npc_rainbow") and color_util.rainbow_color(0.4) or nil

    local opts = {
        box = menu.Get("havoc_npc_box"),
        box_style = menu.Get("havoc_npc_box_style"),
        box_color = ent_rgb or menu.GetColor("havoc_npc_box"),
        box_fill = menu.Get("havoc_npc_box_fill"),
        box_fill_color = ent_rgb or menu.GetColor("havoc_npc_box_fill"),
        name = menu.Get("havoc_npc_name"),
        name_color = ent_rgb or menu.GetColor("havoc_npc_name"),
        dist = menu.Get("havoc_npc_distance"),
        dist_color = ent_rgb or menu.GetColor("havoc_npc_distance"),
        health_bar = menu.Get("havoc_npc_health_bar"),
        health_text = menu.Get("havoc_npc_health_text"),
        health_text_color = ent_rgb or menu.GetColor("havoc_npc_health_text"),
    }

    local chams_on = menu.Get("havoc_npc_chams")
    local chams_color = ent_rgb or menu.GetColor("havoc_npc_chams")
    local skeleton_on = menu.Get("havoc_npc_skeleton")
    local skeleton_color = ent_rgb or menu.GetColor("havoc_npc_skeleton")
    local held_item_on = menu.Get("havoc_npc_held_item")
    local held_item_color = ent_rgb or menu.GetColor("havoc_npc_held_item")
    local npc_type_on = menu.Get("havoc_npc_npc_type")
    local npc_type_color = ent_rgb or menu.GetColor("havoc_npc_npc_type")
    local name_size = menu.Get("havoc_npc_name_size")
    local health_text_size = menu.Get("havoc_npc_health_text_size")
    local held_item_size = menu.Get("havoc_npc_held_item_size")
    local dist_size = menu.Get("havoc_npc_distance_size")
    local npc_type_size = menu.Get("havoc_npc_npc_type_size")

    local hide_dead = menu.Get("havoc_npc_hide_dead")
    local max_dist = menu.Get("havoc_npc_max_distance")

    local needs_full_bounds = opts.box and opts.box_style == 2
    local chams_style = menu.Get("havoc_npc_chams_style")

    local esp_opts = {
        box = needs_full_bounds and false or opts.box,
        box_style = opts.box_style,
        box_color = opts.box_color,
        box_fill = opts.box_fill,
        box_fill_color = opts.box_fill_color,
        name = opts.name,
        name_color = opts.name_color,
        dist = opts.dist,
        dist_color = opts.dist_color,
        health_bar = opts.health_bar,
        health_text = opts.health_text,
        health_text_color = opts.health_text_color,
        npc_type_on = npc_type_on,
        npc_type_color = npc_type_color,
        name_size = name_size or 13,
        health_text_size = health_text_size or 8,
        held_item_size = held_item_size or 10,
        dist_size = dist_size or 10,
        npc_type_size = npc_type_size or 9,
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
                        if chams_on and bounds.valid then draw_util.draw_entity_chams(part_pos, ent.part_size, chams_color, chams_style) end
                        if skeleton_on and bounds.valid then draw_util.draw_entity_skeleton(part_pos, skeleton_color) end
                        if needs_full_bounds and bounds.valid then draw_util.draw_entity_3d_box(part_pos, ent.part_size, opts.box_color) end
                    elseif do_update then
                        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                    end

                    if sc.valid then
                        local name_str = ent.model.Name
                        esp_opts.health = health
                        esp_opts.max_health = max_health
                        esp_opts.held_item = held_item_on and get_held_item_name(ent) or nil
                        esp_opts.held_item_color = held_item_color
                        esp_opts.npc_type = get_npc_type(name_str)

                        draw_util.draw_esp({ x = sc.x, y = sc.y, w = sc.w, h = sc.h, valid = true }, name_str, dist, esp_opts)
                    end
                end
            end
        end
    end
end

return M
