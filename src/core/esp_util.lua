local M = {}

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

function M.draw_oriented_box(box, col, thick)
    if not box then return end
    thick = thick or 1

    local screen = {}
    for i = 1, 8 do
        local sx, sy, sz = BOX_SIGNS[i][1], BOX_SIGNS[i][2], BOX_SIGNS[i][3]
        local lx, ly, lz = sx * box.hx, sy * box.hy, sz * box.hz
        local wx = box.x + box.rx * lx + box.ux * ly - box.lx * lz
        local wy = box.y + box.ry * lx + box.uy * ly - box.ly * lz
        local wz = box.z + box.rz * lx + box.uz * ly - box.lz * lz
        local px, py, vis = M.w2s(wx, wy, wz)
        if vis then
            screen[i] = { x = px, y = py }
        end
    end

    for i = 1, #BOX_EDGES do
        local edge = BOX_EDGES[i]
        local a = screen[edge[1]]
        local b = screen[edge[2]]
        if a and b then
            draw_line(a.x, a.y, b.x, b.y, col, thick)
        end
    end
end

function M.draw_entry_boxes(entry, col, thick)
    if not entry or not entry.inst then return end
    if entry.box then
        M.draw_oriented_box(entry.box, col, thick)
        return
    end

    local esp_scan = July.require("game.esp_scan")
    local main = entry.main_part or esp_scan.find_main_part(entry.inst)
    local box = esp_scan.read_part_box(main)
    if box then
        entry.box = box
        M.draw_oriented_box(box, col, thick)
    end
end

return M
