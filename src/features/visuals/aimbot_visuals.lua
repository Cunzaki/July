local color_util = July.require("core.color_util")
local aimbot = July.require("features.combat.aimbot")

local M = {}

function M.render()
    if not menu.Get("havoc_aimbot_enabled") then return end

    local state = aimbot.draw_state
    if state.scx == nil then return end

    local aimbot_rgb = menu.Get("havoc_aimbot_rainbow") and color_util.rainbow_color(0.5) or nil

    if state.draw_fov then
        local fov_color = aimbot_rgb or menu.GetColor("havoc_aimbot_draw_fov")
        local fill_color
        if aimbot_rgb then
            local orig = menu.GetColor("havoc_aimbot_fill_fov")
            fill_color = { aimbot_rgb[1], aimbot_rgb[2], aimbot_rgb[3], orig[4] }
        else
            fill_color = menu.GetColor("havoc_aimbot_fill_fov")
        end
        if state.fill_fov then
            draw.CircleFilled(state.scx, state.scy, state.fov, fill_color, 48)
        end
        draw.Circle(state.scx, state.scy, state.fov, fov_color, 48)
    end

    if state.active and menu.Get("havoc_aimbot_target_line") then
        local line_color = aimbot_rgb or menu.GetColor("havoc_aimbot_target_line")
        draw.Line(state.scx, state.scy, state.tx, state.ty, line_color)
    end
end

return M
