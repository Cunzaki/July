local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local trap_scan = July.require("game.trap_scan")
local trap_types = July.require("game.trap_types")
local esp_render = July.require("core.esp_render")
local esp_scan = July.require("game.esp_scan")
local esp_util = July.require("core.esp_util")
local env = July.require("core.env")

local M = {}

local candidates = {}

local function clear_candidates()
    for i = 1, #candidates do
        candidates[i] = nil
    end
end

local function dist_sq(a, b)
    local dx = (a.X or a.x or 0) - (b.X or b.x or 0)
    local dy = (a.Y or a.y or 0) - (b.Y or b.y or 0)
    local dz = (a.Z or a.z or 0) - (b.Z or b.z or 0)
    return dx * dx + dy * dy + dz * dz
end

local function draw_trap_box(trap, color, box_style)
    if not trap.root or not env.is_valid(trap.root) then return end

    if box_style == 2 then
        draw_util.draw_root_3d_box(trap.root, color)
        return
    end

    local box = esp_scan.read_part_box(trap.root)
    if box then
        local bounds = esp_util.project_oriented_box(box)
        if bounds and bounds.valid then
            if box_style == 0 and draw.CornerBox then
                draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
            elseif draw.Rect then
                draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
            end
            return
        end
    end

    local pos = trap.pos
    if pos then
        local bounds = draw_util.get_entity_bounds_fallback(pos)
        if bounds.valid then
            if box_style == 0 then
                draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
            else
                draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
            end
        end
    end
end

function M.update()
end

function M.render(cam_pos)
    if not settings.enabled("havoc_trap_enabled") then return end

    local trap_cache = trap_scan.get_cache()
    if #trap_cache == 0 then return end

    local constants = July.require("core.constants")
    local show_dist = settings.bool("havoc_trap_distance", false)
    local dist_pos = settings.num("havoc_trap_distance_pos", 0)
    local show_marker = settings.bool("havoc_trap_marker", false)
    local box_on = settings.bool("havoc_trap_box", false)
    local box_style = settings.num("havoc_trap_box_style", 2)
    local max_dist = settings.num("havoc_trap_max_distance", 500)
    local text_size = settings.num("havoc_trap_text_size", 13)
    local trap_rgb = settings.bool("havoc_trap_rainbow", false) and color_util.rainbow_color(0.35) or nil
    local max_dist_sq = max_dist * max_dist
    local budget = constants.ESP_RENDER_BUDGET or 100
    local count = 0

    clear_candidates()

    for i = 1, #trap_cache do
        local trap = trap_cache[i]
        if not trap.root or not env.is_valid(trap.root) then goto continue end
        if not trap_types.is_enabled(trap.trap_type) then goto continue end

        local pos = trap.pos
        if not pos then goto continue end

        local dsq = dist_sq(cam_pos, pos)
        if dsq > max_dist_sq then goto continue end

        count = count + 1
        candidates[count] = {
            trap = trap,
            dist_sq = dsq,
        }

        ::continue::
    end

    if count == 0 then return end

    local draw_list = esp_render.pick_closest(candidates, budget)

    for i = 1, #draw_list do
        local entry = draw_list[i]
        local trap = entry.trap
        local pos = trap.pos
        if not pos then goto continue_draw end
        local dist = math.sqrt(entry.dist_sq)

        local sx, sy, sok = esp_render.w2s(pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z)
        if not sok or not esp_render.on_screen(sx, sy) then
            goto continue_draw
        end

        local base_color = trap_rgb or trap_types.get_color(trap.trap_type)
        local box_color = trap_rgb or settings.color("havoc_trap_box", base_color)

        if box_on and dist <= math.min(max_dist, 250) then
            draw_trap_box(trap, box_color, box_style)
        end

        if trap.extra and env.is_valid(trap.extra) then
            local ex_ok, ex_pos = pcall(function() return trap.extra.Position end)
            if ex_ok and ex_pos then
                local ex_sx, ex_sy, ex_sok = esp_render.w2s(ex_pos.X, ex_pos.Y, ex_pos.Z)
                if ex_sok and esp_render.on_screen(ex_sx, ex_sy) then
                    draw.Line(sx, sy, ex_sx, ex_sy, base_color, 1.0)
                end
            end
        end

        draw_util.draw_loot_label(sx, sy, trap.trap_type.display, false, dist, show_dist, base_color,
            dist_pos, show_marker, text_size)

        ::continue_draw::
    end
end

return M
