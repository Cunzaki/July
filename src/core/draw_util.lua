local constants = July.require("core.constants")
local color_util = July.require("core.color_util")

local M = {}

local function vec3_size(size)
    if not size then return 1, 1, 1 end
    return size.X or size.x or 1, size.Y or size.y or 1, size.Z or size.z or 1
end

local function vec3_pos(pos)
    if not pos then return nil end
    return pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z
end

function M.get_entity_bounds_from_parts(part_pos, part_size)
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    local has_aabb = false

    for name, pos in pairs(part_pos) do
        local size = part_size[name]
        if size then
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            local lx, ly, lz = pos.X - hx, pos.Y - hy, pos.Z - hz
            local ux, uy, uz = pos.X + hx, pos.Y + hy, pos.Z + hz
            if lx < min_x then min_x = lx end
            if ly < min_y then min_y = ly end
            if lz < min_z then min_z = lz end
            if ux > max_x then max_x = ux end
            if uy > max_y then max_y = uy end
            if uz > max_z then max_z = uz end
            has_aabb = true
        else
            if pos.X < min_x then min_x = pos.X end
            if pos.Y < min_y then min_y = pos.Y end
            if pos.Z < min_z then min_z = pos.Z end
            if pos.X > max_x then max_x = pos.X end
            if pos.Y > max_y then max_y = pos.Y end
            if pos.Z > max_z then max_z = pos.Z end
            has_aabb = true
        end
    end

    if not has_aabb then return { valid = false } end

    local wcx, wcy, wcz = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5
    local hwx, hwy, hwz = (max_x - min_x) * 0.5, (max_y - min_y) * 0.5, (max_z - min_z) * 0.5

    local bmin_x, bmin_y = math.huge, math.huge
    local bmax_x, bmax_y = -math.huge, -math.huge
    local valid = false

    for i = 1, 8 do
        local s = constants.CORNER_SIGNS[i]
        local cx, cy, cok = utility.WorldToScreen(wcx + s[1] * hwx, wcy + s[2] * hwy, wcz + s[3] * hwz)
        if cok then
            valid = true
            if cx < bmin_x then bmin_x = cx end
            if cx > bmax_x then bmax_x = cx end
            if cy < bmin_y then bmin_y = cy end
            if cy > bmax_y then bmax_y = cy end
        end
    end

    if not valid then return { valid = false } end
    return { x = bmin_x, y = bmin_y, w = bmax_x - bmin_x, h = bmax_y - bmin_y, valid = true }
end

function M.get_entity_bounds_fallback(root_pos)
    local top_x, top_y, top_ok = utility.WorldToScreen(root_pos.X, root_pos.Y + constants.HEAD_OFFSET, root_pos.Z)
    local bot_x, bot_y, bot_ok = utility.WorldToScreen(root_pos.X, root_pos.Y - constants.FOOT_OFFSET, root_pos.Z)

    if not (top_ok and bot_ok) then
        return { valid = false }
    end

    local height = math.abs(bot_y - top_y)
    if height < 1 then height = 1 end
    local width = height * 0.5

    return { x = top_x - width * 0.5, y = top_y, w = width, h = height, valid = true }
end

function M.get_entity_bounds(part_pos, part_size, root_pos)
    if next(part_pos) ~= nil then
        local bounds = M.get_entity_bounds_from_parts(part_pos, part_size)
        if bounds.valid then return bounds end
    end
    return M.get_entity_bounds_fallback(root_pos)
end

function M.draw_entity_chams(part_pos, part_size, color, style)
    local hulls = {}

    for name, pos in pairs(part_pos) do
        local size = part_size[name]
        if size then
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            local screen_pts = {}
            for i = 1, 8 do
                local s = constants.CORNER_SIGNS[i]
                local cx, cy, cok = utility.WorldToScreen(pos.X + s[1] * hx, pos.Y + s[2] * hy, pos.Z + s[3] * hz)
                if cok then screen_pts[#screen_pts + 1] = { cx, cy } end
            end
            if #screen_pts >= 3 then
                local hull = draw.ComputeHull(screen_pts)
                if #hull >= 3 then
                    hulls[#hulls + 1] = hull
                    if style == 1 then
                        for j = 1, #hull do
                            local next = j % #hull + 1
                            draw.Line(hull[j][1], hull[j][2], hull[next][1], hull[next][2], color, 1.5)
                        end
                    end
                end
            end
        end
    end

    if #hulls > 0 and style ~= 1 then
        draw.Chams(hulls, { color[1], color[2], color[3], color[4] * 0.6 })
    end
end

function M.draw_entity_skeleton(part_pos, color)
    local bone_list = part_pos["UpperTorso"] and constants.SKELETON_R15 or constants.SKELETON_R6

    for i = 1, #bone_list do
        local pos1 = part_pos[bone_list[i][1]]
        local pos2 = part_pos[bone_list[i][2]]
        if pos1 and pos2 then
            local x1, y1, vis1 = utility.WorldToScreen(pos1.X, pos1.Y, pos1.Z)
            local x2, y2, vis2 = utility.WorldToScreen(pos2.X, pos2.Y, pos2.Z)
            if vis1 and vis2 then
                draw.Line(x1, y1, x2, y2, constants.SKELETON_OUTLINE_COLOR, 3.0)
                draw.Line(x1, y1, x2, y2, color, 1.5)
            end
        end
    end
end

function M.draw_aabb_3d(wcx, wcy, wcz, hwx, hwy, hwz, color)
    local scr = {}
    local visible = 0
    for i = 1, 8 do
        local s = constants.CORNER_SIGNS[i]
        local sx, sy, ok = utility.WorldToScreen(wcx + s[1] * hwx, wcy + s[2] * hwy, wcz + s[3] * hwz)
        scr[i] = { x = sx, y = sy, ok = ok }
        if ok then visible = visible + 1 end
    end

    if visible < 1 then return end

    local edges = {
        { 1, 2 }, { 1, 3 }, { 1, 5 },
        { 2, 4 }, { 2, 6 },
        { 3, 4 }, { 3, 7 },
        { 4, 8 },
        { 5, 6 }, { 5, 7 },
        { 6, 8 },
        { 7, 8 },
    }

    for i = 1, #edges do
        local a, b = edges[i][1], edges[i][2]
        if scr[a].ok or scr[b].ok then
            draw.Line(scr[a].x, scr[a].y, scr[b].x, scr[b].y, color)
        end
    end
end

function M.draw_entity_3d_box(part_pos, part_size, color)
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    local has_data = false

    for name, pos in pairs(part_pos) do
        local px, py, pz = vec3_pos(pos)
        local size = part_size[name]
        if size and px then
            local hx, hy, hz = vec3_size(size)
            hx, hy, hz = hx * 0.5, hy * 0.5, hz * 0.5
            local lx, ly, lz = px - hx, py - hy, pz - hz
            local ux, uy, uz = px + hx, py + hy, pz + hz
            if lx < min_x then min_x = lx end
            if ly < min_y then min_y = ly end
            if lz < min_z then min_z = lz end
            if ux > max_x then max_x = ux end
            if uy > max_y then max_y = uy end
            if uz > max_z then max_z = uz end
            has_data = true
        elseif px then
            if px < min_x then min_x = px end
            if py < min_y then min_y = py end
            if pz < min_z then min_z = pz end
            if px > max_x then max_x = px end
            if py > max_y then max_y = py end
            if pz > max_z then max_z = pz end
            has_data = true
        end
    end

    if not has_data then return end

    local wcx, wcy, wcz = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5
    local hwx, hwy, hwz = (max_x - min_x) * 0.5, (max_y - min_y) * 0.5, (max_z - min_z) * 0.5
    local max_half = 15
    hwx = math.min(hwx, max_half)
    hwy = math.min(hwy, max_half)
    hwz = math.min(hwz, max_half)
    M.draw_aabb_3d(wcx, wcy, wcz, hwx, hwy, hwz, color)
end

function M.draw_root_3d_box(root, color)
    if not root then return end
    local esp_scan = July.require("game.esp_scan")
    local esp_util = July.require("core.esp_util")
    local box = esp_scan.read_part_box(root)
    if box then
        esp_util.draw_oriented_box(box, color, 1)
        return
    end

    local ok_pos, pos = pcall(function() return root.Position end)
    local ok_size, size = pcall(function() return root.Size end)
    if not ok_pos or not ok_size or not pos then return end

    local px, py, pz = vec3_pos(pos)
    local sx, sy, sz = vec3_size(size)
    if not px then return end

    local max_half = 15
    sx = math.min(math.abs(sx), max_half)
    sy = math.min(math.abs(sy), max_half)
    sz = math.min(math.abs(sz), max_half)

    M.draw_aabb_3d(px, py, pz, sx * 0.5, sy * 0.5, sz * 0.5, color)
end

function M.draw_esp(bounds, name_str, dist_val, opts)
    if not bounds.valid then return end

    if opts.box then
        if opts.box_style == 0 then
            draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, opts.box_color)
        elseif opts.box_style == 1 then
            draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, opts.box_color)
        end
    end
    if opts.box_fill and opts.box_fill_color then
        draw.RectFilled(bounds.x, bounds.y, bounds.w, bounds.h, opts.box_fill_color)
    end

    if opts.health_bar then
        local hb_x = bounds.x - 4
        local hb_w = 3
        local hb_h = bounds.h
        local pct = math.max(0, math.min(1, opts.health / opts.max_health))
        local hb_color = color_util.health_bar_color(opts.health, opts.max_health)
        draw.RectFilled(hb_x - 1, bounds.y - 1, hb_w + 2, hb_h + 2, { 0, 0, 0, 0.6 })
        local fill_h = hb_h * pct
        local hb_y = bounds.y + hb_h - fill_h
        draw.RectFilled(hb_x, hb_y, hb_w, fill_h, hb_color)
        if opts.health_text then
            local hts = opts.health_text_size or 8
            local ht = string.format("%d", math.floor(opts.health))
            draw.Text(hb_x - draw.GetTextSize(ht, hts) - 4, bounds.y + 1, ht, opts.health_text_color, hts)
        end
    end

    if opts.name then
        local ns = opts.name_size or 13
        local tw = draw.GetTextSize(name_str, ns)
        draw.Text(bounds.x + (bounds.w - tw) * 0.5, bounds.y - ns - 4, name_str, opts.name_color, ns)
    end

    local below_y = bounds.y + bounds.h + 4

    if opts.held_item then
        local his = opts.held_item_size or 10
        local tw = draw.GetTextSize(opts.held_item, his)
        draw.Text(bounds.x + (bounds.w - tw) * 0.5, below_y, opts.held_item, opts.held_item_color, his)
        below_y = below_y + his + 2
    elseif opts.held_item_slot then
        local his = opts.held_item_size or 10
        below_y = below_y + his + 2
    end

    if opts.dist then
        local ds = opts.dist_size or 10
        local dist_str = string.format("%dm", math.floor(dist_val))
        local tw = draw.GetTextSize(dist_str, ds)
        draw.Text(bounds.x + (bounds.w - tw) * 0.5, below_y, dist_str, opts.dist_color, ds)
        below_y = below_y + ds + 2
    end

    if opts.npc_type and opts.npc_type_on then
        local nts = opts.npc_type_size or 9
        local nw = draw.GetTextSize(opts.npc_type, nts)
        draw.Text(bounds.x + (bounds.w - nw) * 0.5, below_y, opts.npc_type, opts.npc_type_color, nts)
        below_y = below_y + nts + 2
    end

    if opts.flags then
        local flag_fs = opts.flag_size or 9
        for i = 1, #opts.flags do
            local flag = opts.flags[i]
            if flag and flag.text and flag.text ~= "" then
                local color = flag.color or { 1, 1, 1, 1 }
                local tw = draw.GetTextSize(flag.text, flag_fs)
                draw.Text(bounds.x + (bounds.w - tw) * 0.5, below_y, flag.text, color, flag_fs)
                below_y = below_y + flag_fs + 2
            end
        end
    end
end

function M.draw_loot_label(x, y, display_name, locked, dist, show_dist, color, dist_pos, show_marker, text_size)
    local name_text = display_name
    if locked then
        name_text = name_text .. " [Locked]"
    end

    local dist_text = nil
    if show_dist then
        dist_text = string.format("%dm", math.floor(dist))
        if dist_pos == 0 then
            name_text = name_text .. " [" .. dist_text .. "]"
            dist_text = nil
        end
    end

    local name_w = draw.GetTextSize(name_text, text_size)
    local name_x = x - name_w * 0.5
    local name_y = y - text_size * 0.5

    if show_marker then
        draw.CircleFilled(x, name_y - constants.LOOT_MARKER_GAP, constants.LOOT_MARKER_RADIUS, color, 12)
    end

    if dist_text then
        local dist_w = draw.GetTextSize(dist_text, text_size)
        if dist_pos == 1 then
            draw.Text(x - dist_w * 0.5, name_y + text_size + 2, dist_text, color, text_size)
        elseif dist_pos == 2 then
            draw.Text(name_x - dist_w - 4, name_y, dist_text, color, text_size)
        elseif dist_pos == 3 then
            draw.Text(name_x + name_w + 4, name_y, dist_text, color, text_size)
        end
    end

    draw.Text(name_x, name_y, name_text, color, text_size)
end

function M.draw_trap_label(sx, sy, display_name, color, text_size)
    local tw = draw.GetTextSize(display_name, text_size)
    draw.Text(sx - tw * 0.5, sy - text_size * 0.5, display_name, color, text_size)
end

return M
