local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")
local gpu_chams = July.require("core.gpu_chams")

local M = {}

local P = "havoc_npc_enabled"
local CHAMS_GPU = "havoc_npc_gpu_chams"
local CHAMS_MODE = "havoc_npc_gpu_chams_mode"
local CHAMS_COLOR = "havoc_npc_gpu_chams_color"

local function npc_type(ent)
    if ent.is_boss then return "Boss" end
    if ent.is_sniper then return "Sniper" end
    local name = ent.model and ent.model.Name or ""
    if name == "Sentry" or name:find("Sentry", 1, true) then return "Sentry" end
    return "Scav"
end

local function npc_type_allowed(npc_type_name)
    if npc_type_name == "Boss" then return settings.bool("havoc_npc_show_boss", true) end
    if npc_type_name == "Sniper" then return settings.bool("havoc_npc_show_sniper", true) end
    if npc_type_name == "Scav" then return settings.bool("havoc_npc_show_scav", true) end
    if npc_type_name == "Sentry" then return settings.bool("havoc_npc_show_sniper", true) end
    return true
end

local function dist_sq_cam(cam_pos, pos)
    local cx = cam_pos.X or cam_pos.x or 0
    local cy = cam_pos.Y or cam_pos.y or 0
    local cz = cam_pos.Z or cam_pos.z or 0
    local px = pos.X or pos.x or 0
    local py = pos.Y or pos.y or 0
    local pz = pos.Z or pos.z or 0
    local dx, dy, dz = px - cx, py - cy, pz - cz
    return dx * dx + dy * dy + dz * dz
end

local function live_root_pos(ent)
    if not ent or not ent.root or not env.is_valid(ent.root) then return nil end
    local ok, pos = pcall(function() return ent.root.Position end)
    if ok and pos then
        ent._live_pos = pos
        return pos
    end
    return ent._live_pos
end

local function collect_part_positions(ent)
    local part_pos = {}
    for name, part in pairs(ent.parts or {}) do
        if env.is_valid(part) then
            local ok, pos = pcall(function() return part.Position end)
            if ok and pos then
                part_pos[name] = pos
            end
        end
    end
    return part_pos
end

local function npc_gpu_active()
    if not gpu_chams.available() then return false end
    if not settings.enabled(P) then return false end
    return settings.bool(CHAMS_GPU, false)
end

local function collect_npc_chams(applied)
    local cam_pos
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok then cam_pos = pos end
    end
    if not cam_pos then return end

    local max_dist = math.min(settings.num("havoc_npc_max_distance", 1000), 1000)
    local max_sq = max_dist * max_dist
    local hide_dead = settings.bool("havoc_npc_hide_dead", false)
    local cache = entity_scan.get_cache()

    for i = 1, #cache do
        local ent = cache[i]
        if not entity_scan.is_entry_valid(ent) then goto continue end

        local health = ent.humanoid.Health or 0
        if hide_dead and health <= 0 then goto continue end

        local kind = npc_type(ent)
        if not npc_type_allowed(kind) then goto continue end

        local root_pos = ent._live_pos or live_root_pos(ent)
        if not root_pos then goto continue end
        if dist_sq_cam(cam_pos, root_pos) > max_sq then goto continue end

        root_pos = live_root_pos(ent)
        if not root_pos then goto continue end

        gpu_chams.cham_player_character(ent.model, applied)

        ::continue::
    end
end

function M.register_gpu_menu(TAB, G, parent)
    if not gpu_chams.available() then return {} end

    menu.add_checkbox(TAB, G, CHAMS_GPU, "NPC Engine Chams", false, { parent = parent })
    gpu_chams.add_mode_color_menu(TAB, G, parent, CHAMS_MODE, CHAMS_COLOR,
        "NPC Chams Mode", "NPC Chams Color")

    gpu_chams.register_owner("npcs", {
        rescan_ms = 350,
        is_active = npc_gpu_active,
        style = function()
            return gpu_chams.mode_index(CHAMS_MODE, 0), gpu_chams.color_index(CHAMS_COLOR, 0)
        end,
        collect = collect_npc_chams,
    })
    gpu_chams.wire_style_controls("npcs", CHAMS_MODE, CHAMS_COLOR)

    local function resync()
        if npc_gpu_active() then
            gpu_chams.sync_owner("npcs", true)
        else
            gpu_chams.clear_owner("npcs")
        end
    end
    settings.on_change(CHAMS_GPU, resync)
    settings.on_change(P, resync)
    settings.on_change("havoc_npc_show_scav", resync)
    settings.on_change("havoc_npc_show_boss", resync)
    settings.on_change("havoc_npc_show_sniper", resync)
    settings.on_change("havoc_npc_hide_dead", resync)
    settings.on_change("havoc_npc_max_distance", resync)

    return { CHAMS_GPU, CHAMS_MODE, CHAMS_COLOR }
end

function M.sync_gpu()
    if npc_gpu_active() then
        gpu_chams.sync_owner("npcs")
    end
end

function M.render(cam_pos)
    if not settings.enabled(P) then return end

    local entity_cache = entity_scan.get_cache()
    local n = #entity_cache
    if n == 0 then return end

    local ent_rgb = settings.bool("havoc_npc_rainbow", false) and color_util.rainbow_color(0.4) or nil

    local box_on = settings.bool("havoc_npc_box", false)
    local fill_on = settings.bool("havoc_npc_box_fill", false)
    local name_on = settings.bool("havoc_npc_name", false)
    local dist_on = settings.bool("havoc_npc_distance", false)
    local held_on = settings.bool("havoc_npc_held_item", false)
    local ammo_on = settings.bool("havoc_npc_ammo", false)
    local reloading_on = settings.bool("havoc_npc_reloading", false)
    local type_on = settings.bool("havoc_npc_npc_type", false)
    local health_bar_on = settings.bool("havoc_npc_health_bar", false)
    local health_text_on = settings.bool("havoc_npc_health_text", false)
    local chams_on = settings.bool("havoc_npc_chams", false)
    local skeleton_on = settings.bool("havoc_npc_skeleton", false)

    local box_style = settings.num("havoc_npc_box_style", 0)
    local chams_style = settings.num("havoc_npc_chams_style", 0)
    local hide_dead = settings.bool("havoc_npc_hide_dead", false)
    local max_dist = math.min(settings.num("havoc_npc_max_distance", 1000), 1000)
    local max_dist_sq = max_dist * max_dist

    local name_size = settings.num("havoc_npc_name_size", 13)
    local health_text_size = settings.num("havoc_npc_health_text_size", 8)
    local held_item_size = settings.num("havoc_npc_held_item_size", 10)
    local ammo_size = settings.num("havoc_npc_ammo_size", 9)
    local reloading_size = settings.num("havoc_npc_reloading_size", 9)
    local dist_size = settings.num("havoc_npc_distance_size", 10)
    local npc_type_size = settings.num("havoc_npc_npc_type_size", 9)

    local needs_parts = chams_on or skeleton_on or (box_on and box_style == 2)

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

        local kind = npc_type(ent)
        if not npc_type_allowed(kind) then goto continue_ent end

        -- Coarse cull on batched live pos, then live HRP for in-range only.
        local root_pos = ent._live_pos
        if not root_pos then
            root_pos = live_root_pos(ent)
        end
        if not root_pos then goto continue_ent end

        if dist_sq_cam(cam_pos, root_pos) > max_dist_sq then goto continue_ent end

        root_pos = live_root_pos(ent)
        if not root_pos then goto continue_ent end

        local dist = math.sqrt(dist_sq_cam(cam_pos, root_pos))

        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
        if not bounds.valid then goto continue_ent end

        if needs_parts then
            local part_pos = collect_part_positions(ent)
            if part_pos and next(part_pos) then
                if box_on and box_style == 2 then
                    local full = draw_util.get_entity_bounds_from_parts(part_pos, ent.part_size)
                    if full and full.valid then bounds = full end
                end
                if chams_on then
                    draw_util.draw_entity_chams(part_pos, ent.part_size,
                        ent_rgb or settings.color("havoc_npc_chams", { 1, 0.2, 0.2, 0.55 }), chams_style)
                end
                if skeleton_on then
                    draw_util.draw_entity_skeleton(part_pos,
                        ent_rgb or settings.color("havoc_npc_skeleton", { 1, 1, 1, 1 }))
                end
                if box_on and box_style == 2 then
                    draw_util.draw_entity_3d_box(part_pos, ent.part_size,
                        ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 }))
                end
            end
        end

        local name_str = ent.model.Name

        local held_name, ammo_val, reloading_val
        if held_on or ammo_on or reloading_on then
            held_name, ammo_val, reloading_val = entity_scan.read_weapon_display(ent)
        else
            held_name = ent._held_name
            ammo_val = ent._ammo_current
            reloading_val = ent._reloading
        end

        local held_color = held_name and tier_util.get_esp_color(held_name)
            or settings.color("havoc_npc_held_item", { 1, 0.85, 0.4, 1 })

        esp_opts.box = box_on and box_style ~= 2
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
        esp_opts.held_item_slot = held_on
        esp_opts.held_item_color = ent_rgb or held_color
        esp_opts.npc_type = kind
        esp_opts.flags = nil

        local flags = {}
        if ammo_on and ammo_val ~= nil then
            flags[#flags + 1] = {
                text = string.format("Ammo: %s", tostring(ammo_val)),
                color = ent_rgb or settings.color("havoc_npc_ammo", { 0.55, 0.85, 1, 1 }),
            }
        end
        if reloading_on and reloading_val then
            flags[#flags + 1] = {
                text = "RELOADING",
                color = ent_rgb or settings.color("havoc_npc_reloading", { 1, 0.45, 0.2, 1 }),
            }
        end
        if #flags > 0 then
            esp_opts.flags = flags
            esp_opts.flag_size = math.max(ammo_on and ammo_size or 0, reloading_on and reloading_size or 0, 9)
        end

        draw_util.draw_esp(bounds, name_str, dist, esp_opts)

        ::continue_ent::
    end
end

return M
