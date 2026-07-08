local M = {}

local function w2s(x, y, z)
    if utility and utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.draw_world_line(x1, y1, z1, x2, y2, z2, col, thick)
    local sx1, sy1, ok1 = w2s(x1, y1, z1)
    local sx2, sy2, ok2 = w2s(x2, y2, z2)
    if ok1 or ok2 then
        draw.Line(sx1, sy1, sx2, sy2, col, thick or 1)
        return true
    end
    return false
end

function M.draw_world_path(path, col, thick)
    if not path or #path < 2 then return end
    thick = thick or 1.5
    for i = 1, #path - 1 do
        local a, b = path[i], path[i + 1]
        if a and b then
            M.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, thick)
        end
    end
end

function M.draw_cross(wx, wy, wz, size, col, thick)
    if not wx then return end

    if camera and camera.get_look_vector then
        local ok, look = pcall(camera.get_look_vector)
        if ok and look then
            local lx = look.x or look.X or 0
            local ly = look.y or look.Y or 0
            local lz = look.z or look.Z or 0
            local mag = math.sqrt(lx * lx + ly * ly + lz * lz)
            if mag >= 0.001 then
                lx, ly, lz = lx / mag, ly / mag, lz / mag

                local ux, uy, uz = 0, 1, 0
                local rx = uy * lz - uz * ly
                local ry = uz * lx - ux * lz
                local rz = ux * ly - uy * lx
                local rm = math.sqrt(rx * rx + ry * ry + rz * rz)
                if rm < 0.001 then
                    ux, uy, uz = 0, 0, 1
                    rx = uy * lz - uz * ly
                    ry = uz * lx - ux * lz
                    rz = ux * ly - uy * lx
                    rm = math.sqrt(rx * rx + ry * ry + rz * rz)
                end
                if rm >= 0.001 then
                    rx, ry, rz = rx / rm, ry / rm, rz / rm
                    ux = ly * rz - lz * ry
                    uy = lz * rx - lx * rz
                    uz = lx * ry - ly * rx
                    local um = math.sqrt(ux * ux + uy * uy + uz * uz)
                    if um >= 0.001 then
                        ux, uy, uz = ux / um, uy / um, uz / um
                        size = size or 0.35
                        thick = thick or 2
                        local s = size * 0.5
                        M.draw_world_line(
                            wx - rx * s - ux * s, wy - ry * s - uy * s, wz - rz * s - uz * s,
                            wx + rx * s + ux * s, wy + ry * s + uy * s, wz + rz * s + uz * s,
                            col, thick
                        )
                        M.draw_world_line(
                            wx - rx * s + ux * s, wy - ry * s + uy * s, wz - rz * s + uz * s,
                            wx + rx * s - ux * s, wy + ry * s - uy * s, wz + rz * s - uz * s,
                            col, thick
                        )
                        return
                    end
                end
            end
        end
    end

    size = size or 1.5
    thick = thick or 2
    M.draw_world_line(wx - size, wy, wz, wx + size, wy, wz, col, thick)
    M.draw_world_line(wx, wy - size, wz, wx, wy + size, wz, col, thick)
    M.draw_world_line(wx, wy, wz - size, wx, wy, wz + size, col, thick)
end

function M.draw_sphere_ring(wx, wy, wz, radius, col, thick)
    if not wx then return end
    radius = radius or 1.5
    thick = thick or 2
    local steps = 24
    local prev_sx, prev_sy, prev_vis
    for i = 0, steps do
        local a = (i / steps) * math.pi * 2
        local px = wx + math.cos(a) * radius
        local pz = wz + math.sin(a) * radius
        local sx, sy, vis = w2s(px, wy, pz)
        if prev_vis ~= nil and (vis or prev_vis) then
            draw.Line(prev_sx, prev_sy, sx, sy, col, thick)
        end
        prev_sx, prev_sy, prev_vis = sx, sy, vis
    end
end

function M.draw_link(a, b, col, thick)
    if not a or not b then return end
    M.draw_world_line(a.x, a.y, a.z, b.x, b.y, b.z, col, thick or 2)
end

function M.draw_labeled(wx, wy, wz, label, col, size)
    if not wx or not label then return end
    local sx, sy, vis = w2s(wx, wy + 2, wz)
    if vis then
        local tw = draw.GetTextSize(label, size or 11)
        draw.Text(sx - tw * 0.5, sy, label, col, size or 11)
    end
end

return M
