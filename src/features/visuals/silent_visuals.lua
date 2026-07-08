local settings = July.require("core.settings")
local silent_aim = July.require("features.combat.silent_aim")
local color_util = July.require("core.color_util")
local manip_math = July.require("core.manip_math")
local combat_origin = July.require("game.combat_origin")
local world_vis = July.require("core.world_vis")

local M = {}

local MANIP_LABELS = {
    direct = "MANIP: CLEAR SHOT",
    ready = "MANIP: RAY READY",
    blocked = "MANIP: NO PEEK",
    tp = "BULLET TP",
    off = "",
}

local function manip_active(state)
    return state and state.state and state.state ~= "off"
end

local function manip_ready(state)
    return state.state == "ready" or state.state == "direct" or state.state == "tp"
end

function M.render()
    local state = silent_aim.draw_state
    local prefix = silent_aim.get_prefix()

    if not settings.enabled(silent_aim.get_master_id()) then return end
    if state.scx == nil then return end

    local rgb = settings.bool(prefix .. "rainbow", false) and color_util.rainbow_color(0.5) or nil
    local manip = state.manip or { state = "off" }

    if state.draw_fov then
        local fov_color = rgb or settings.color(prefix .. "draw_fov", { 0.55, 0.2, 1.0, 1.0 })
        if state.fill_fov then
            local fill = { fov_color[1], fov_color[2], fov_color[3], 0.15 }
            draw.CircleFilled(state.scx, state.scy, state.fov, fill, 48)
        end
        draw.Circle(state.scx, state.scy, state.fov, fov_color, 48)
    end

    if state.active and settings.bool(prefix .. "target_line", false) then
        local line_color = rgb or settings.color(prefix .. "target_line", { 1.0, 0.25, 0.25, 1.0 })
        draw.Line(state.scx, state.scy, state.tx, state.ty, line_color)
    end

    if settings.bool(prefix .. "manip_status", false) and manip_active(manip) then
        local label = MANIP_LABELS[manip.state] or "MANIP: ..."
        if manip.state == "tp" and manip.tp_mode then
            label = "BULLET TP: " .. manip.tp_mode
        end
        local col = manip_ready(manip) and { 0.2, 1.0, 0.3, 1.0 } or { 1.0, 0.2, 0.2, 1.0 }
        local tw = draw.GetTextSize(label, 11)
        draw.Text(state.scx - tw * 0.5, state.scy + state.fov + 10, label, col, 11)
    end

    if settings.bool(prefix .. "bullet_manip", false) and settings.bool(prefix .. "manip_ring", false) then
        local body = combat_origin.get_server_origin() or combat_origin.get_head_origin()
        if body then
            local radius = manip.radius or manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))
            local ring_y = manip_math.ring_y(body)
            local ring_col = { 0.15, 0.95, 0.55, 0.55 }
            if manip.state == "blocked" then
                ring_col = { 0.95, 0.25, 0.25, 0.45 }
            elseif manip_ready(manip) then
                ring_col = { 0.2, 0.95, 0.45, 0.7 }
            end
            world_vis.draw_sphere_ring(body.x, ring_y, body.z, radius, ring_col, 1.5)
        end
    end

    if settings.bool(prefix .. "manip_peek_vis", true) and manip.peek and manip.state == "ready" then
        local body = combat_origin.get_server_origin() or combat_origin.get_head_origin()
        local peek = manip.peek
        local col_peek = { 1, 0.85, 0.2, 0.95 }
        local eye_y = peek.y + manip_math.eye_offset_y()
        world_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
        if settings.bool(prefix .. "manip_status", false) then
            world_vis.draw_labeled(peek.x, eye_y, peek.z, "PEEK", col_peek, 11)
        end
        if body then
            world_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.3 }, 1)
        end
        if state.aim_world then
            local ray_from = manip_math.peek_track_origin(peek)
            if ray_from then
                world_vis.draw_link(ray_from, state.aim_world, { 1, 0.45, 0.2, 0.55 }, 1.5)
            end
        end
    end

    if settings.bool(prefix .. "tp_ray_vis", false) and state.tp_path and #state.tp_path >= 2 then
        local col = settings.color(prefix .. "tp_ray_vis", { 0.95, 0.45, 1.0, 0.9 })
        world_vis.draw_world_path(state.tp_path, col, 2)
        if manip.player_origin and state.aim_world then
            world_vis.draw_cross(manip.player_origin.x, manip.player_origin.y, manip.player_origin.z, 0.6, col, 2)
        end
        if manip.bone_aim then
            world_vis.draw_cross(manip.bone_aim.x, manip.bone_aim.y, manip.bone_aim.z, 0.45, { 1, 0.85, 0.2, 0.95 }, 2)
        end
    end
end

return M
