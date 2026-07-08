local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local trap_scan = July.require("game.trap_scan")

local M = {}

function M.render(cam_pos)
    if not menu.Get("havoc_trap_enabled") then return end

    local trap_cache = trap_scan.get_cache()
    if #trap_cache == 0 then return end

    local max_dist = menu.Get("havoc_trap_max_distance")
    local text_size = menu.Get("havoc_trap_text_size") or 13
    local trap_rgb = menu.Get("havoc_trap_rainbow") and color_util.rainbow_color(0.35) or nil
    local group_color = menu.GetColor("havoc_trap_enabled")

    for i = 1, #trap_cache do
        local trap = trap_cache[i]

        local ok_pos, pos = pcall(function() return trap.root.Position end)
        if ok_pos and pos then
            local dist = (cam_pos - pos).Magnitude
            if dist <= max_dist then
                local color = trap_rgb or group_color

                local sx, sy, sok = utility.WorldToScreen(pos.X, pos.Y, pos.Z)
                if sok then
                    if trap.extra then
                        local ex_ok, ex_pos = pcall(function() return trap.extra.Position end)
                        if ex_ok and ex_pos then
                            local ex_sx, ex_sy, ex_sok = utility.WorldToScreen(ex_pos.X, ex_pos.Y, ex_pos.Z)
                            if ex_sok then
                                draw.Line(sx, sy, ex_sx, ex_sy, color, 1.0)
                            end
                        end
                    end
                    draw_util.draw_trap_label(sx, sy, trap.trap_type.display, color, text_size)
                end
            end
        end
    end
end

return M
