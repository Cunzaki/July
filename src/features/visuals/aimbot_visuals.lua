local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local aimbot = July.require("features.combat.aimbot")

local M = {}

function M.render()
    if not settings.enabled("havoc_aimbot_enabled") then return end

    local state = aimbot.draw_state
    if state.scx == nil then return end

    local aimbot_rgb = settings.bool("havoc_aimbot_rainbow", false) and color_util.rainbow_color(0.5) or nil

    if state.draw_fov then
        local fov_color = aimbot_rgb or settings.color("havoc_aimbot_draw_fov", { 1, 1, 1, 1 })
        local fill_color
        if aimbot_rgb then
            local orig = settings.color("havoc_aimbot_fill_fov", { 1, 1, 1, 0.15 })
            fill_color = { aimbot_rgb[1], aimbot_rgb[2], aimbot_rgb[3], orig[4] }
        else
            fill_color = settings.color("havoc_aimbot_fill_fov", { 1, 1, 1, 0.15 })
        end
        if state.fill_fov then
            draw.CircleFilled(state.scx, state.scy, state.fov, fill_color, 48)
        end
        draw.Circle(state.scx, state.scy, state.fov, fov_color, 48)
    end

    if state.active and settings.bool("havoc_aimbot_target_line", false) then
        local line_color = aimbot_rgb or settings.color("havoc_aimbot_target_line", { 1, 0.3, 0.3, 1 })
        draw.Line(state.scx, state.scy, state.tx, state.ty, line_color)
    end
end

return M
