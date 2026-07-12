local M = {}

local env = July.require("core.env")

local BOX_EDGES = {
    { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 },
    { 5, 6 }, { 5, 7 }, { 6, 8 }, { 7, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local BOX_SIGNS = {
    { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
    { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
}

function M.w2s(x, y, z)
    if utility and utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function draw_line(x1, y1, x2, y2, col, thick)
    if draw and draw.Line then
        draw.Line(x1, y1, x2, y2, col, thick or 1)
    elseif draw and draw.line then
        draw.line(x1, y1, x2, y2, col, thick or 1)
    end
end

local function corner_world(box, sx, sy, sz)
    local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
    -- Roblox Size.Z is along -LookVector
    return box.x + box.rx * lx + box.ux * ly - box.lx * lz,
        box.y + box.ry * lx + box.uy * ly - box.ly * lz,
        box.z + box.rz * lx + box.uz * ly - box.lz * lz
end

function M.project_oriented_box(box)
    if not box then return nil end

    local bmin_x, bmin_y = math.huge, math.huge
    local bmax_x, bmax_y = -math.huge, -math.huge
    local valid = false
    local screen = {}

    for i = 1, 8 do
        local s = BOX_SIGNS[i]
        local wx, wy, wz = corner_world(box, s[1], s[2], s[3])
        local px, py, vis = M.w2s(wx, wy, wz)
        if vis then
            valid = true
            screen[i] = { x = px, y = py }
            if px < bmin_x then bmin_x = px end
            if px > bmax_x then bmax_x = px end
            if py < bmin_y then bmin_y = py end
            if py > bmax_y then bmax_y = py end
        end
    end

    if not valid then return nil end
    return {
        x = bmin_x,
        y = bmin_y,
        w = bmax_x - bmin_x,
        h = bmax_y - bmin_y,
        valid = true,
        screen = screen,
    }
end

function M.draw_oriented_box(box, col, thick)
    if not box then return end
    thick = thick or 1

    local projected = M.project_oriented_box(box)
    if not projected then return end
    local screen = projected.screen

    for i = 1, #BOX_EDGES do
        local edge = BOX_EDGES[i]
        local a = screen[edge[1]]
        local b = screen[edge[2]]
        if a and b then
            draw_line(a.x, a.y, b.x, b.y, col, thick)
        end
    end
end

function M.draw_entry_boxes(entry, col, thick, style)
    if not entry then return end

    local box = entry.box
    if not box then
        local esp_scan = July.require("game.esp_scan")
        esp_scan.refresh_entry_bounds(entry)
        box = entry.box
    end
    if not box then return end

    style = style or 2
    if style == 2 then
        M.draw_oriented_box(box, col, thick)
        return
    end

    local bounds = M.project_oriented_box(box)
    if not bounds or not bounds.valid then return end
    if style == 0 then
        if draw and draw.CornerBox then
            draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, col)
        end
    else
        if draw and draw.Rect then
            draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, col)
        end
    end
end

return M
