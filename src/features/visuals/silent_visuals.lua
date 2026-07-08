local settings = July.require("core.settings")
local silent_aim = July.require("features.combat.silent_aim")
local color_util = July.require("core.color_util")

local M = {}

local MANIP_LABELS = {
    direct = "MANIP: CLEAR SHOT",
    ready = "MANIP: RAY READY",
    blocked = "MANIP: NO PEEK",
    tp = "BULLET TP",
    off = "",
}

function M.render()
    local state = silent_aim.draw_state
    local prefix = silent_aim.get_prefix()

    if not settings.enabled(silent_aim.get_master_id()) then return end
    if state.scx == nil then return end

    local rgb = settings.bool(prefix .. "rainbow", false) and color_util.rainbow_color(0.5) or nil

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

    if settings.bool(prefix .. "manip_status", false) and state.manip and state.manip.state ~= "off" then
        local text = MANIP_LABELS[state.manip.state] or "MANIP: ..."
        local col = (state.manip.state == "ready" or state.manip.state == "direct" or state.manip.state == "tp")
            and { 0.2, 1.0, 0.3, 1.0 } or { 1.0, 0.2, 0.2, 1.0 }
        local tw = draw.GetTextSize(text, 11)
        draw.Text(state.scx - tw * 0.5, state.scy + state.fov + 10, text, col, 11)
    end

    if settings.bool(prefix .. "tp_ray_vis", false) and state.tp_path and #state.tp_path >= 2 then
        local col = settings.color(prefix .. "tp_ray_vis", { 0.95, 0.45, 1.0, 0.9 })
        for i = 1, #state.tp_path - 1 do
            local a, b = state.tp_path[i], state.tp_path[i + 1]
            local x1, y1, ok1 = utility.WorldToScreen(a.x, a.y, a.z)
            local x2, y2, ok2 = utility.WorldToScreen(b.x, b.y, b.z)
            if ok1 and ok2 then
                draw.Line(x1, y1, x2, y2, col, 1.5)
            end
        end
    end
end

return M
