--[[
    July — Havoc for Project Vector
    https://github.com/Cunzaki/July
    Built: 2026-07-08T02:05:50.076Z
]]

July = {
    version = "0.3.0",
    debug = false,
    _mods = {},
    bundled = true,
}

if menu and menu.add_tab then
    menu.add_tab("July", "J", "full")
end
July._menu_tab_ready = true

function July.require(path)
    local mod = July._mods[path]
    if mod == nil then
        error("[July] bundled module missing: " .. path)
    end
    return mod
end


-- ── core/constants.lua ──
July._mods["core.constants"] = (function()
local M = {}

M.TAB = "July"
M.CONFIG_PATH = "C:/July_Config.txt"

M.TEXT_SIZE = 13
M.HEAD_OFFSET = 2.6
M.FOOT_OFFSET = 3.2

M.BOUNDS_UPDATE_INTERVAL = 3
M.SCAN_YIELD_EVERY = 64
M.ENTITY_SCAN_INTERVAL = 1.0
M.FOLDER_POLL_INTERVAL = 0.25
M.PLAYER_MATCH_DIST = 5.0

M.LOOT_SCAN_INTERVAL = 30.0
M.LOOT_SCAN_DEPTH = 8
M.LOOT_LIVE_BATCH_SIZE = 60

M.TRAP_SCAN_DEPTH = 8
M.TRAP_SCAN_INTERVAL = 5.0

M.AIMBOT_ACQUIRE_INTERVAL = 0.05
M.AIMBOT_TICK_INTERVAL = 2

M.LOOT_MARKER_RADIUS = 3
M.LOOT_MARKER_GAP = 8

M.SKELETON_OUTLINE_COLOR = { 0, 0, 0, 0.78 }

M.NPC_BOSS_NAMES = {
    Scorch = true, Raptor = true, Knox = true, Volt = true, Fox = true,
    Bullet = true, Zero = true, Cobra = true, Ghost = true, Shade = true,
    Checkmate = true, Vandal = true, Mamba = true, Phoenix = true,
    Talon = true, Anvil = true, Gunner = true,
}

M.BONE_NAMES = {
    "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

M.SKELETON_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" }, { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" }, { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "RightLowerLeg", "RightFoot" },
}

M.SKELETON_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

M.CORNER_SIGNS = {
    { -1, -1, -1 }, { -1, -1, 1 }, { -1, 1, -1 }, { -1, 1, 1 },
    { 1, -1, -1 }, { 1, -1, 1 }, { 1, 1, -1 }, { 1, 1, 1 },
}

return M

end)()

-- ── core/env.lua ──
July._mods["core.env"] = (function()
local M = {}

function M.has_api(name)
    return _G[name] ~= nil
end

function M.safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

function M.is_valid(inst)
    if not inst or not utility then return false end
    return utility.is_valid(inst)
end

function M.get_workspace()
    if game and game.Workspace then return game.Workspace end
    if game and game.workspace then return game.workspace end
    return M.safe_call(function() return workspace end)
end

function M.get_local_player()
    if entity and entity.GetLocalPlayer then
        return entity.GetLocalPlayer()
    end
    if entity and entity.get_local_player then
        return entity.get_local_player()
    end
    return nil
end

function M.find_child(parent, name)
    if not parent then return nil end
    return M.safe_call(function()
        if parent.FindFirstChild then return parent:FindFirstChild(name) end
        if parent.find_first_child then return parent:find_first_child(name) end
        return nil
    end)
end

return M

end)()

-- ── core/debug.lua ──
July._mods["core.debug"] = (function()
local M = {}

local seen_errors = {}

function M.enabled()
    return July and July.debug == true
end

function M.log(msg)
    if not M.enabled() then return end
    print("[July] " .. tostring(msg))
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] then return end
    seen_errors[key] = true
    print("[July ERROR][" .. key .. "] " .. tostring(err))
    if debug and debug.traceback then
        print(debug.traceback(err, 2))
    end
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    return a, b, c
end

function M.traceback(err, level)
    if debug and debug.traceback then
        return debug.traceback(err, level or 2)
    end
    return tostring(err)
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    _G.on_frame = fn

    if draw then
        draw.callback = nil
    end

    return true
end

return M

end)()

-- ── core/settings.lua ──
July._mods["core.settings"] = (function()
local M = {}

function M.get(id, default)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    if menu and menu.Get then
        local v = menu.Get(id)
        if v ~= nil then return v end
    end
    return default
end

function M.bool(id, default)
    local v = M.get(id, default)
    if v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.enabled(id)
    if not menu then return false end
    local v = M.get(id, false)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.color(id, default)
    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return c end
    end
    if menu and menu.GetColor then
        local c = menu.GetColor(id)
        if c then return c end
    end
    return default or { 1, 1, 1, 1 }
end

function M.multicombo_get(id, index, default)
    local vals = M.get(id, nil)
    if type(vals) ~= "table" then return default end
    local v = vals[index]
    if v == nil then return default end
    return v == true
end

return M

end)()

-- ── core/math_util.lua ──
July._mods["core.math_util"] = (function()
local M = {}

function M.distance3(dx, dy, dz)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function M.distance_sq(a, b)
    if not a or not b then return math.huge end
    return M.distance3(a.x - b.x, a.y - b.y, a.z - b.z) ^ 2
end

return M

end)()

-- ── core/color_util.lua ──
July._mods["core.color_util"] = (function()
local M = {}

function M.hsv_to_rgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return { v, t, p, 1.0 }
    elseif i == 1 then return { q, v, p, 1.0 }
    elseif i == 2 then return { p, v, t, 1.0 }
    elseif i == 3 then return { p, q, v, 1.0 }
    elseif i == 4 then return { t, p, v, 1.0 }
    else return { v, p, q, 1.0 } end
end

function M.rainbow_color(speed)
    local hue = (os.clock() * (speed or 0.5)) % 1
    return M.hsv_to_rgb(hue, 1, 1)
end

function M.health_bar_color(health, max_health)
    local pct = health / max_health
    if pct > 0.6 then return { 0.2, 1.0, 0.3, 1.0 }
    elseif pct > 0.3 then return { 1.0, 0.8, 0.1, 1.0 }
    else return { 1.0, 0.2, 0.2, 1.0 } end
end

return M

end)()

-- ── core/scan_yield.lua ──
July._mods["core.scan_yield"] = (function()
local constants = July.require("core.constants")

local M = {}
local scan_yield_counter = 0

function M.yield()
    scan_yield_counter = scan_yield_counter + 1
    if scan_yield_counter >= constants.SCAN_YIELD_EVERY then
        scan_yield_counter = 0
        sleep(0)
    end
end

return M

end)()

-- ── core/draw_util.lua ──
July._mods["core.draw_util"] = (function()
local constants = July.require("core.constants")
local color_util = July.require("core.color_util")

local M = {}

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

function M.draw_entity_3d_box(part_pos, part_size, color)
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge
    local has_data = false

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
            has_data = true
        else
            if pos.X < min_x then min_x = pos.X end
            if pos.Y < min_y then min_y = pos.Y end
            if pos.Z < min_z then min_z = pos.Z end
            if pos.X > max_x then max_x = pos.X end
            if pos.Y > max_y then max_y = pos.Y end
            if pos.Z > max_z then max_z = pos.Z end
            has_data = true
        end
    end

    if not has_data then return end

    local wcx, wcy, wcz = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5, (min_z + max_z) * 0.5
    local hwx, hwy, hwz = (max_x - min_x) * 0.5, (max_y - min_y) * 0.5, (max_z - min_z) * 0.5

    local scr = {}
    local all_ok = true
    for i = 1, 8 do
        local s = constants.CORNER_SIGNS[i]
        local sx, sy, ok = utility.WorldToScreen(wcx + s[1] * hwx, wcy + s[2] * hwy, wcz + s[3] * hwz)
        scr[i] = { x = sx, y = sy, ok = ok }
        if not ok then all_ok = false end
    end

    if not all_ok then return end

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
        if scr[a].ok and scr[b].ok then
            draw.Line(scr[a].x, scr[a].y, scr[b].x, scr[b].y, color)
        end
    end
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

end)()

-- ── core/silent_ray.lua ──
July._mods["core.silent_ray"] = (function()
local M = {}

local hook_ready = false
local tracking = false
local MOUSE_RAY_LEN = 1024

M._last_origin = nil
M._last_target = nil
M._last_ok = false

local function unpack_pos(v)
    if not v then return nil end
    if v.x ~= nil then return v.x, v.y, v.z end
    if v.X ~= nil then return v.X, v.Y, v.Z end
    return nil
end

local function make_vec3(x, y, z)
    if Vector3 and Vector3.new then
        return Vector3.new(x, y, z)
    end
    return { x = x, y = y, z = z }
end

function M.available()
    return raycast
        and raycast.track_silent_target
        and raycast.stop_silent_tracking
end

function M.ensure_hook()
    if not M.available() then return false end
    if hook_ready or (raycast.is_silent_hook_active and raycast.is_silent_hook_active()) then
        hook_ready = true
        return true
    end
    if not raycast.enable_silent_hook then
        hook_ready = true
        return true
    end
    local ok = raycast.enable_silent_hook()
    hook_ready = ok == true
    return hook_ready
end

function M.get_camera_origin()
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then
            local x, y, z = unpack_pos(pos)
            if x then return { x = x, y = y, z = z } end
        end
    end
    if camera and camera.get_position then
        local ok, pos = pcall(camera.get_position)
        if ok and pos then
            local x, y, z = unpack_pos(pos)
            if x then return { x = x, y = y, z = z } end
        end
    end
    return nil
end

function M.stop()
    M._last_origin = nil
    M._last_target = nil
    M._last_ok = false
    tracking = false
    if not M.available() then return end
    pcall(raycast.stop_silent_tracking)
    if raycast.clear_silent_target then
        pcall(raycast.clear_silent_target)
    end
end

function M.track(origin, aim_point, shoot_vk)
    M._last_ok = false
    if not aim_point then return false end

    origin = origin or M.get_camera_origin()
    if not origin then return false end
    if not M.ensure_hook() then return false end

    local ox, oy, oz = unpack_pos(origin)
    local ax, ay, az = unpack_pos(aim_point)
    if not ox or not ax then return false end

    local dx, dy, dz = ax - ox, ay - oy, az - oz
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local dir

    if dist < 0.001 then
        local cam = M.get_camera_origin()
        if cam then
            dx, dy, dz = cam.x - ox, cam.y - oy, cam.z - oz
            dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        end
        if not dist or dist < 0.001 then
            dir = make_vec3(0, MOUSE_RAY_LEN * 0.01, 0)
        else
            local inv = 1 / dist
            dir = make_vec3(dx * inv * MOUSE_RAY_LEN, dy * inv * MOUSE_RAY_LEN, dz * inv * MOUSE_RAY_LEN)
        end
    else
        local inv = 1 / dist
        dir = make_vec3(dx * inv * MOUSE_RAY_LEN, dy * inv * MOUSE_RAY_LEN, dz * inv * MOUSE_RAY_LEN)
    end

    local origin_v = make_vec3(ox, oy, oz)
    local key = shoot_vk or 0x01

    M._last_origin = { x = ox, y = oy, z = oz }
    M._last_target = { x = ax, y = ay, z = az }

    local ok = raycast.track_silent_target(origin_v, dir, key) == true
    M._last_ok = ok
    tracking = ok
    return ok
end

return M

end)()

-- ── core/manip_math.lua ──
July._mods["core.manip_math"] = (function()
local M = {}

local EYE_OFFSET_Y = 2.5
local DEFAULT_STEPS = 16

function M.eye_offset_y()
    return EYE_OFFSET_Y
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < 0.1 then return 0.1 end
    if radius > 1 then return 1 end
    return math.floor(radius * 100 + 0.5) / 100
end

function M.is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast or not raycast.is_visible then
        return true
    end
    local ex, ey, ez = ox, oy + EYE_OFFSET_Y, oz
    return raycast.is_visible(ex, ey, ez, tx, ty, tz) == true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return M.is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function search_peek(origin, target_pos, max_radius, steps)
    max_radius = M.clamp_radius(max_radius)
    steps = steps or DEFAULT_STEPS

    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * max_radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * max_radius
        if M.is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
            return { x = cx, y = cy, z = cz }, max_radius
        end
    end

    return nil, max_radius
end

function M.evaluate_manipulation(origin, target_pos, opts)
    opts = opts or {}

    if not origin or not target_pos then
        return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    if M.is_visible_from_pos(origin, target_pos) then
        return { state = "direct", peek = nil, radius = M.clamp_radius(opts.max_radius) }
    end

    local peek, radius = search_peek(origin, target_pos, opts.max_radius, opts.steps)
    if peek then
        return { state = "ready", peek = peek, radius = radius }
    end

    return { state = "blocked", peek = nil, radius = M.clamp_radius(opts.max_radius) }
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return { x = peek.x, y = peek.y + EYE_OFFSET_Y, z = peek.z }
end

return M

end)()

-- ── game/loot_catalog.lua ──
July._mods["game.loot_catalog"] = (function()
local M = {}

M.LOOT_TYPES = {
    { key = "loot_medium_crate", match = "Medium Wooden Crate", display = "Medium Wooden Crate", color = { 0.62, 0.44, 0.24, 1.0 } },
    { key = "loot_complex_crate", match = "Complex Crate", display = "Complex Crate", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_military_crate", match = "Military Crate", display = "Military Crate", color = { 0.3, 0.55, 0.3, 1.0 } },
    { key = "loot_wooden_crate", match = "Wooden Crate", display = "Wooden Crate", color = { 0.55, 0.4, 0.25, 1.0 } },
    { key = "loot_weapon_locker", match = "Weapon Locker", display = "Weapon Locker", color = { 1.0, 0.4, 0.2, 1.0 } },
    { key = "loot_weapon_box", match = "Weapon Box", display = "Weapon Box", color = { 1.0, 0.35, 0.25, 1.0 } },
    { key = "loot_rifle_case", match = "Rifle Case", display = "Rifle Case", color = { 1.0, 0.5, 0.3, 1.0 } },
    { key = "loot_pistol_case", match = "Pistol Case", display = "Pistol Case", color = { 1.0, 0.45, 0.3, 1.0 } },
    { key = "loot_small_case", match = "Small Case", display = "Small Case", color = { 0.9, 0.6, 0.4, 1.0 } },
    { key = "loot_ammunition_box", match = "Ammunition Box", display = "Ammunition Box", color = { 0.3, 0.75, 1.0, 1.0 } },
    { key = "loot_technical_shelf", match = "Technical Shelf", display = "Technical Shelf", color = { 0.35, 0.7, 0.9, 1.0 } },
    { key = "loot_tool_shelf", match = "Tool Shelf", display = "Tool Shelf", color = { 0.4, 0.68, 0.88, 1.0 } },
    { key = "loot_toolbox", match = "Toolbox", display = "Toolbox", color = { 0.4, 0.65, 0.85, 1.0 } },
    { key = "loot_medical_box", match = "Medical Box", display = "Medical Box", color = { 0.9, 0.2, 0.2, 1.0 } },
    { key = "loot_safe", match = "Safe", display = "Safe", color = { 1.0, 0.85, 0.2, 1.0 } },
    { key = "loot_cabinet", match = "Cabinet", display = "Cabinet", color = { 0.9, 0.75, 0.3, 1.0 } },
    { key = "loot_cash_register", match = "Cash Register", display = "Cash Register", color = { 1.0, 0.8, 0.1, 1.0 } },
    { key = "loot_duffel_bag", match = "Duffel Bag", display = "Duffel Bag", color = { 0.85, 0.7, 0.35, 1.0 } },
    { key = "loot_backpack", match = "backpack", display = "Backpack", color = { 0.8, 0.65, 0.3, 1.0 } },
    { key = "loot_closet", match = "Closet", display = "Closet", color = { 0.6, 0.6, 0.65, 1.0 } },
    { key = "loot_computer", match = "Computer", display = "Computer", color = { 0.3, 0.9, 0.9, 1.0 } },
    { key = "loot_server_unit", match = "Server Unit", display = "Server Unit", color = { 0.25, 0.8, 0.95, 1.0 } },
    { key = "loot_powerbox", match = "PowerBox", display = "Power Box", color = { 0.9, 0.85, 0.2, 1.0 } },
    { key = "loot_standing_atm", match = "StandingATM", display = "ATM", color = { 0.2, 0.9, 0.5, 1.0 } },
    { key = "loot_locker", match = "Locker", display = "Locker", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_tall_fridge", match = "Tall Fridge", display = "Tall Fridge", color = { 0.7, 0.85, 0.9, 1.0 } },
    { key = "loot_fridge", match = "Fridge", display = "Fridge", color = { 0.75, 0.88, 0.92, 1.0 } },
    { key = "loot_stove", match = "Stove", display = "Stove", color = { 0.5, 0.5, 0.5, 1.0 } },
    { key = "loot_washing_machine", match = "Washing Machine", display = "Washing Machine", color = { 0.65, 0.75, 0.85, 1.0 } },
    { key = "loot_dishwasher", match = "Dishwasher", display = "Dishwasher", color = { 0.6, 0.7, 0.8, 1.0 } },
    { key = "loot_envelope", match = "Envelope", display = "Envelope", color = { 0.9, 0.85, 0.7, 1.0 } },
    { key = "loot_explosive_barrel", match = "ExplosiveBarrel", display = "Explosive Barrel", color = { 1.0, 0.3, 0.0, 1.0 } },
    { key = "loot_door", match = { "WoodenDoor", "DoubleGlassDoor", "DoubleMetalDoor", "MetalDoor", "GarageDoorLock" },
      display = "Locked Door", color = { 0.5, 0.4, 0.3, 1.0 } },
}

M.LOOT_FALLBACK = { key = "loot_other", display = "Other Loot", color = { 0.8, 0.8, 0.8, 1.0 } }
M.BODY_BAG_TYPE = { key = "loot_body_bag", display = "Body Bag", color = { 0.35, 0.35, 0.35, 1.0 } }

M.MULTICOMBO_ENTRIES = {}
M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

local function rebuild_multicombo()
    M.MULTICOMBO_ENTRIES = {}
    M.MULTICOMBO_LABELS = {}
    M.MULTICOMBO_DEFAULTS = {}
    M.KEY_TO_INDEX = {}

    for i = 1, #M.LOOT_TYPES do
        M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.LOOT_TYPES[i]
        M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.LOOT_TYPES[i].display
        M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
        M.KEY_TO_INDEX[M.LOOT_TYPES[i].key] = #M.MULTICOMBO_ENTRIES
    end

    M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.LOOT_FALLBACK
    M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.LOOT_FALLBACK.display
    M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
    M.KEY_TO_INDEX[M.LOOT_FALLBACK.key] = #M.MULTICOMBO_ENTRIES

    M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.BODY_BAG_TYPE
    M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.BODY_BAG_TYPE.display
    M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
    M.KEY_TO_INDEX[M.BODY_BAG_TYPE.key] = #M.MULTICOMBO_ENTRIES
end

rebuild_multicombo()

function M.is_enabled(vals, category)
    if type(vals) ~= "table" then return false end
    local idx = M.KEY_TO_INDEX[category and category.key]
    if not idx then return false end
    return vals[idx] == true
end

function M.get_color(category)
    if category and category.color then return category.color end
    return { 1, 1, 1, 1 }
end

local function name_matches(name, pattern)
    if type(pattern) == "table" then
        for i = 1, #pattern do
            if string.find(name, pattern[i], 1, true) then return true end
        end
        return false
    end
    return string.find(name, pattern, 1, true) ~= nil
end

function M.categorize_loot(name)
    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        if name_matches(name, entry.match) then
            return entry
        end
    end
    return M.LOOT_FALLBACK
end

return M

end)()

-- ── game/trap_types.lua ──
July._mods["game.trap_types"] = (function()
local M = {}

M.TRAP_TYPES = {
    { key = "trap_tripmine", display = "Tripmine", color = { 1.0, 0.5, 0.0, 1.0 } },
    { key = "trap_mine", display = "Mine", color = { 1.0, 0.2, 0.0, 1.0 } },
    { key = "trap_alarm", display = "Alarm", color = { 1.0, 0.0, 0.0, 1.0 } },
    { key = "trap_airstrike", display = "Airstrike Alarm", color = { 1.0, 0.1, 0.1, 1.0 } },
    { key = "trap_barrel", display = "Explosive Barrel", color = { 1.0, 0.3, 0.0, 1.0 } },
    { key = "trap_sentry", display = "Sentry", color = { 0.8, 0.0, 0.0, 1.0 } },
    { key = "trap_gas", display = "Toxic Gas", color = { 0.2, 0.8, 0.0, 1.0 } },
}

M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

for i = 1, #M.TRAP_TYPES do
    M.MULTICOMBO_LABELS[i] = M.TRAP_TYPES[i].display
    M.MULTICOMBO_DEFAULTS[i] = true
    M.KEY_TO_INDEX[M.TRAP_TYPES[i].key] = i
end

function M.is_enabled(vals, trap_type)
    if type(vals) ~= "table" or not trap_type then return false end
    local idx = M.KEY_TO_INDEX[trap_type.key]
    if not idx then return false end
    return vals[idx] == true
end

function M.get_color(trap_type)
    if trap_type and trap_type.color then return trap_type.color end
    return { 1, 0.2, 0, 1 }
end

return M

end)()

-- ── game/asset_urls.lua ──
July._mods["game.asset_urls"] = (function()
local M = {}

M.REPO = "Cunzaki/July"
M.BRANCH = "main"

function M.decal_url(asset_id)
    return string.format(
        "https://raw.githubusercontent.com/%s/refs/heads/%s/assets/decals/%s.png",
        M.REPO, M.BRANCH, tostring(asset_id)
    )
end

return M

end)()

-- ── game/weapons.lua ──
July._mods["game.weapons"] = (function()
local env = July.require("core.env")

local M = {}

M._last_held = nil

local function inst_name(inst)
    if not inst then return nil end
    return inst.Name or inst.name
end

function M.get_held_tool_name()
    local lp = env.get_local_player()
    if not lp then return nil end

    local char = lp.Character or lp.character
    if not char or not env.is_valid(char) then return nil end

    local ok, children = pcall(function() return char:GetChildren() end)
    if not ok or not children then return nil end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Tool" then
            return inst_name(child)
        end
    end

    return nil
end

function M.cached_held()
    local name = M.get_held_tool_name()
    M._last_held = name
    return name
end

function M.holding_weapon()
    return M.get_held_tool_name() ~= nil
end

return M

end)()

-- ── game/combat_origin.lua ──
July._mods["game.combat_origin"] = (function()
local env = July.require("core.env")
local weapons = July.require("game.weapons")

local M = {}

local frame = { weapon = nil, muzzle = nil, server = nil }

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local ok, pos = pcall(function() return part.Position end)
    if ok and pos then
        if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
        if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    end
    return nil
end

local function find_muzzlefx(tool)
    if not tool then return nil end

    local handle = env.find_child(tool, "Handle")
    if handle then
        local ok, children = pcall(function() return handle:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.Name == "MuzzleFX" or child.ClassName == "Attachment" then
                    local pos = part_pos(handle)
                    if pos then return pos end
                end
            end
        end
        local pos = part_pos(handle)
        if pos then return pos end
    end

    local mod = env.find_child(tool, "_mod")
    if mod then
        local ok, children = pcall(function() return mod:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local pos = part_pos(children[i])
                if pos then return pos end
            end
        end
    end

    return nil
end

local function viewmodel_muzzle()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vm = ws:FindFirstChild("__viewmodel")
    if not vm then return nil end

    local ok, children = pcall(function() return vm:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local pos = part_pos(children[i])
            if pos then return pos end
        end
    end

    return nil
end

local function camera_origin()
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then
            if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
            if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
        end
    end
    return nil
end

local function server_origin()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.Position then
        local p = lp.Position
        if p.X then return { x = p.X, y = p.Y, z = p.Z } end
        if p.x then return { x = p.x, y = p.y, z = p.z } end
    end

    local char = lp.Character or lp.character
    if char and env.is_valid(char) then
        local root = env.find_child(char, "HumanoidRootPart")
            or env.find_child(char, "Head")
        return part_pos(root)
    end

    return nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held()
    frame.weapon = weapon
    frame.server = server_origin()

    local lp = env.get_local_player()
    local char = lp and (lp.Character or lp.character)
    if char and weapon then
        local tool = env.find_child(char, weapon)
        frame.muzzle = find_muzzlefx(tool) or viewmodel_muzzle() or camera_origin()
    else
        frame.muzzle = viewmodel_muzzle() or camera_origin()
    end
end

function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end

function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end

function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server or camera_origin()
end

return M

end)()

-- ── game/entity_scan.lua ──
July._mods["game.entity_scan"] = (function()
local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")

local M = {}

local entity_by_model = {}
local characters_folder = nil
local entity_cache = {}
local entity_cache_stamp = -9999

local function is_humanoid_by_properties(obj)
    local ok_health, health = pcall(function() return obj.Health end)
    local ok_maxh, maxh = pcall(function() return obj.MaxHealth end)
    if ok_health and ok_maxh then
        if type(health) == "number" and type(maxh) == "number" then
            return true
        end
    end
    return false
end

local function find_humanoid(model)
    local ok, hum = pcall(function() return model:FindFirstChildOfClass("Humanoid") end)
    if ok and hum then return hum end
    local ok_c, children = pcall(function() return model:GetChildren() end)
    if ok_c and children then
        for i = 1, #children do
            if is_humanoid_by_properties(children[i]) then
                return children[i]
            end
        end
    end
    return nil
end

local function collect_body_parts(model)
    local parts = {}
    local sizes = {}
    local ok, children = pcall(function() return model:GetChildren() end)
    if not ok or not children then return parts, sizes end

    for i = 1, #children do
        local child = children[i]
        local cls = child.ClassName
        if cls == "Part" or cls == "MeshPart" then
            for j = 1, #constants.BONE_NAMES do
                if child.Name == constants.BONE_NAMES[j] then
                    parts[child.Name] = child
                    local ok_size, size = pcall(function() return child.Size end)
                    sizes[child.Name] = ok_size and size or nil
                    break
                end
            end
        end
    end

    return parts, sizes
end

local function get_or_create_entity(model, root, humanoid)
    local entry = entity_by_model[model]
    if entry then return entry end

    local parts, part_sizes = collect_body_parts(model)
    entry = {
        model = model,
        root = root,
        humanoid = humanoid,
        parts = parts,
        part_size = part_sizes,
        scr_bounds = { x = 0, y = 0, w = 0, h = 0, valid = false },
    }
    entity_by_model[model] = entry
    return entry
end

local function is_player_character(model, root, players)
    for i = 1, #players do
        local char = players[i].Character
        if char and char == model then
            return true
        end
    end

    local ok, pos = pcall(function() return root.Position end)
    if not ok or not pos then return false end

    for i = 1, #players do
        local ok_ppos, ppos = pcall(function() return players[i].Position end)
        if ok_ppos and ppos and (pos - ppos).Magnitude < constants.PLAYER_MATCH_DIST then
            return true
        end
    end

    local ok_lp, local_player = pcall(entity.GetLocalPlayer)
    if ok_lp and local_player then
        local ok_char, char = pcall(function() return local_player.Character end)
        if ok_char and char and char == model then
            return true
        end

        local ok_lp_pos, lp_pos = pcall(function() return local_player.Position end)
        if ok_lp_pos and lp_pos and (pos - lp_pos).Magnitude < constants.PLAYER_MATCH_DIST then
            return true
        end
    end

    return false
end

local function collect_entities(container, players, out, depth)
    if depth > 6 then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" or cls == "WorldModel" then
            local hum = find_humanoid(child)
            if hum then
                local root = child:FindFirstChild("HumanoidRootPart")
                    or child:FindFirstChild("Torso")
                    or child:FindFirstChild("UpperTorso")
                    or child:FindFirstChild("Head")
                    or child:FindFirstChildWhichIsA("BasePart")

                if root and not is_player_character(child, root, players) then
                    out[#out + 1] = get_or_create_entity(child, root, hum)
                end
            else
                collect_entities(child, players, out, depth + 1)
            end
        elseif cls == "Folder" then
            collect_entities(child, players, out, depth + 1)
        end
    end
end

local function get_entity_root()
    if not characters_folder then
        local ok, ws_children = pcall(function() return game.Workspace:GetChildren() end)
        if ok and ws_children then
            for i = 1, #ws_children do
                local child = ws_children[i]
                if child:IsA("Model") or child:IsA("Folder") then
                    local ok2, sub = pcall(function() return child:GetChildren() end)
                    if ok2 and sub then
                        for j = 1, #sub do
                            local subchild = sub[j]
                            if subchild:IsA("Model") then
                                local hum = subchild:FindFirstChildOfClass("Humanoid")
                                if not hum then
                                    local ok3, subsub = pcall(function() return subchild:GetChildren() end)
                                    if ok3 and subsub then
                                        for k = 1, #subsub do
                                            if is_humanoid_by_properties(subsub[k]) then
                                                hum = subsub[k]
                                                break
                                            end
                                        end
                                    end
                                end
                                if hum then
                                    characters_folder = child
                                    return characters_folder
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return characters_folder
end

function M.refresh()
    local now = os.clock()
    local interval = characters_folder and constants.ENTITY_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if (now - entity_cache_stamp) < interval then return end
    entity_cache_stamp = now

    local root = get_entity_root()
    if not root then return end

    local players = entity.GetPlayers()
    local out = {}
    collect_entities(root, players, out, 0)

    if #out > 0 then
        local new_by_model = {}
        for i = 1, #out do
            new_by_model[out[i].model] = out[i]
        end
        entity_by_model = new_by_model
        entity_cache = out
    end
end

function M.get_cache()
    return entity_cache
end

return M

end)()

-- ── game/loot_scan.lua ──
July._mods["game.loot_scan"] = (function()
local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local loot_catalog = July.require("game.loot_catalog")

local M = {}

local loot_by_model = {}
local loot_cache = {}
local loot_cache_stamp = -9998
local loot_live_cursor = 1
local buildings_folder = nil

local function get_loot_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local loot_type = data:FindFirstChild("lootType")
    local is_open = data:FindFirstChild("isOpen")
    local is_locked = data:FindFirstChild("isLocked")
    if not (loot_type and is_open and is_locked) then return nil end

    return is_open, is_locked
end

local function get_or_create_loot(model, root, category, is_open_inst, is_locked_inst)
    local entry = loot_by_model[model]
    if entry then return entry end

    local ok_pos, pos = pcall(function() return root.Position end)
    entry = {
        model = model,
        root = root,
        pos = ok_pos and pos or nil,
        is_open_inst = is_open_inst,
        is_locked_inst = is_locked_inst,
        is_open = nil,
        is_locked = nil,
        category = category,
    }
    loot_by_model[model] = entry
    return entry
end

local function collect_loot(container, out, depth)
    if depth > constants.LOOT_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" then
            local is_open, is_locked = get_loot_info(child)
            if is_open then
                local root = child:FindFirstChildWhichIsA("BasePart")
                if root then
                    out[#out + 1] = get_or_create_loot(child, root, loot_catalog.categorize_loot(child.Name), is_open, is_locked)
                end
            else
                collect_loot(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_loot(child, out, depth + 1)
        end
    end
end

local function get_buildings_folder()
    if not buildings_folder then
        buildings_folder = game.Workspace:FindFirstChild("Buildings")
    end
    return buildings_folder
end

local function collect_body_bags(buildings, out)
    local loots1 = buildings:FindFirstChild("Loots")
    if not loots1 then return end
    local loots2 = loots1:FindFirstChild("Loots")
    if not loots2 then return end
    local characters = loots2:FindFirstChild("Characters")
    if not characters then return end

    local ok, children = pcall(function() return characters:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = get_or_create_loot(child, root, loot_catalog.BODY_BAG_TYPE, nil, nil)
            end
        end
    end
end

function M.refresh()
    local now = os.clock()
    local interval = buildings_folder and constants.LOOT_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if (now - loot_cache_stamp) < interval then return end
    loot_cache_stamp = now

    local out = {}
    local buildings = get_buildings_folder()
    if buildings then
        local ok, children = pcall(function() return buildings:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local loots = children[i]:FindFirstChild("Loots")
                if loots then
                    collect_loot(loots, out, 0)
                end
            end
        end
        collect_body_bags(buildings, out)
    end

    if #out > 0 then
        local new_by_model = {}
        for i = 1, #out do
            new_by_model[out[i].model] = out[i]
        end
        loot_by_model = new_by_model
        loot_cache = out
    end
end

function M.refresh_live()
    local n = #loot_cache
    if n == 0 then return end

    if loot_live_cursor > n then loot_live_cursor = 1 end

    local remaining = math.min(constants.LOOT_LIVE_BATCH_SIZE, n)
    while remaining > 0 do
        local loot = loot_cache[loot_live_cursor]
        if loot.is_open_inst then
            local ok, is_open_val, is_locked_val = pcall(function()
                return loot.is_open_inst.Value, loot.is_locked_inst.Value
            end)
            if ok then
                loot.is_open = is_open_val
                loot.is_locked = is_locked_val
            end
        end

        loot_live_cursor = loot_live_cursor + 1
        if loot_live_cursor > n then loot_live_cursor = 1 end
        remaining = remaining - 1
    end
end

function M.get_cache()
    return loot_cache
end

return M

end)()

-- ── game/trap_scan.lua ──
July._mods["game.trap_scan"] = (function()
local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local trap_types = July.require("game.trap_types")

local M = {}

local trap_cache = {}
local trap_cache_stamp = -9997
local trap_folders_found = false

local IGNORED_FOLDER = nil
local EVENT_OBJECTS_FOLDER = nil
local ENV_INTERACTABLE_FOLDER = nil

local function get_buildings_folder()
    return game.Workspace:FindFirstChild("Buildings")
end

local function get_ignored_folder()
    if not IGNORED_FOLDER then
        IGNORED_FOLDER = game.Workspace:FindFirstChild("Ignored")
    end
    return IGNORED_FOLDER
end

local function get_event_objects_folder()
    if not EVENT_OBJECTS_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            EVENT_OBJECTS_FOLDER = buildings:FindFirstChild("EventObjects")
        end
        if not EVENT_OBJECTS_FOLDER then
            EVENT_OBJECTS_FOLDER = game.Workspace:FindFirstChild("EventObjects")
        end
    end
    return EVENT_OBJECTS_FOLDER
end

local function get_env_interactable_folder()
    if not ENV_INTERACTABLE_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            ENV_INTERACTABLE_FOLDER = buildings:FindFirstChild("EnvInteractable")
        end
        if not ENV_INTERACTABLE_FOLDER then
            ENV_INTERACTABLE_FOLDER = game.Workspace:FindFirstChild("EnvInteractable")
        end
    end
    return ENV_INTERACTABLE_FOLDER
end

local function collect_tripmines(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Folder" and child.Name == "Tripmine" then
            local mainPart = child:FindFirstChild("mainPart")
            local connectedPart = child:FindFirstChild("connectedPart")
            if mainPart and mainPart:IsA("BasePart") then
                out[#out + 1] = {
                    root = mainPart,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[1],
                    extra = connectedPart,
                }
            end
        elseif child.ClassName == "Folder" then
            collect_tripmines(child, out, depth + 1)
        end
    end
end

local function collect_mine_hitboxes(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child:IsA("BasePart") and child.Name == "MineHitbox" then
            out[#out + 1] = {
                root = child,
                model = child,
                trap_type = trap_types.TRAP_TYPES[2],
                extra = nil,
            }
        elseif child.ClassName == "Folder" or child:IsA("BasePart") then
            collect_mine_hitboxes(child, out, depth + 1)
        end
    end
end

local function collect_alarms(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" and child.Name:find("Alarm", 1, true) then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[3],
                    extra = nil,
                }
            end
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_alarms(child, out, depth + 1)
        end
    end
end

local function collect_airstrike_alarms(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" and child.Name:find("AirstrikeAlarm", 1, true) then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[4],
                    extra = nil,
                }
            end
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_airstrike_alarms(child, out, depth + 1)
        end
    end
end

local function collect_explosive_barrels(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChild("Base")
            if not root then root = child:FindFirstChildWhichIsA("BasePart") end
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[5],
                    extra = nil,
                }
            end
        end
    end
end

local function collect_sentries(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChild("Base")
            if root and root:IsA("BasePart") then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[6],
                    extra = nil,
                }
            end
        end
    end
end

local function collect_toxic_gas(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child:IsA("MeshPart") then
            out[#out + 1] = {
                root = child,
                model = child,
                trap_type = trap_types.TRAP_TYPES[7],
                extra = nil,
            }
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_toxic_gas(child, out, depth + 1)
        end
    end
end

function M.refresh()
    local interval = trap_folders_found and constants.TRAP_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL

    local now = os.clock()
    if (now - trap_cache_stamp) < interval then return end
    trap_cache_stamp = now

    local out = {}
    local any_found = false

    local env = get_env_interactable_folder()
    if env then any_found = true end
    if env then
        local mines = env:FindFirstChild("Mines")
        if mines then
            local tripmines = mines:FindFirstChild("Tripmines")
            if tripmines then
                collect_tripmines(tripmines, out, 0)
            end
        end
    end

    local ignored = get_ignored_folder()
    if ignored then any_found = true end
    if ignored then
        collect_alarms(ignored, out, 0)
    end

    local event_objects = get_event_objects_folder()
    if event_objects then any_found = true end
    if event_objects then
        local minefields = event_objects:FindFirstChild("Minefields")
        if minefields then
            collect_mine_hitboxes(minefields, out, 0)
        end
        local airstrike = event_objects:FindFirstChild("ST_AirstrikeAlarms")
        if airstrike then
            collect_airstrike_alarms(airstrike, out, 0)
        end
        local barrels = event_objects:FindFirstChild("ExplosiveBarrels")
        if barrels then
            collect_explosive_barrels(barrels, out, 0)
        end
        local sentries = event_objects:FindFirstChild("Sentries")
        if sentries then
            collect_sentries(sentries, out, 0)
        end
        local gas = event_objects:FindFirstChild("ToxicGas")
        if gas then
            collect_toxic_gas(gas, out, 0)
        end
    end

    trap_folders_found = any_found

    if #out > 0 then
        trap_cache = out
    end
end

function M.get_cache()
    return trap_cache
end

return M

end)()

-- ── features/combat/combat_menu.lua ──
July._mods["features.combat.combat_menu"] = (function()
local M = {}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
}

function M.register_silent_aim(TAB, GROUP, prefix, parent_id)
    local root = { parent = parent_id }

    menu.add_combo(TAB, GROUP, prefix .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(TAB, GROUP, prefix .. "bone", "Target Hitbox", M.SILENT_BONES, 0, root)

    menu.add_separator(TAB, GROUP)
    menu.add_label(TAB, GROUP, "Filters")
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_health", "Health Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_visible", "Visible Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_team", "Team Check", true, root)

    menu.add_separator(TAB, GROUP)
    menu.add_label(TAB, GROUP, "Targets")
    menu.add_checkbox(TAB, GROUP, prefix .. "target_players", "Target Players", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npcs", "Target NPCs", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_soldiers", "NPC Soldiers", true, { parent = prefix .. "target_npcs" })
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_bosses", "NPC Bosses", true, { parent = prefix .. "target_npcs" })

    menu.add_separator(TAB, GROUP)
    menu.add_slider_int(TAB, GROUP, prefix .. "max_dist", "Max Distance (m)", 50, 2000, 500, root)
    menu.add_slider_int(TAB, GROUP, prefix .. "fov", "FOV Radius (px)", 20, 600, 150, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "wallbang", "Wallbang", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_tp", "Bullet TP", false, root)
    menu.add_combo(TAB, GROUP, prefix .. "tp_ray_mode", "TP Ray Mode", { "Direct", "Snap", "Deep" }, 0, { parent = prefix .. "bullet_tp" })
    menu.add_checkbox(TAB, GROUP, prefix .. "tp_ray_vis", "Visualize Ray Path", false, {
        parent = prefix .. "bullet_tp",
        colorpicker = { 0.95, 0.45, 1.0, 0.9 },
    })
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_manip", "Bullet Manipulation", false, root)
    menu.add_slider_float(TAB, GROUP, prefix .. "manip_dist", "Manip Distance", 0.1, 1.0, 1.0, "%.2f", { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_status", "Manip Status Bar", false, { parent = prefix .. "bullet_manip" })
end

return M

end)()

-- ── menu/menu_defs.lua ──
July._mods["menu.menu_defs"] = (function()
local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")

local M = {}
M.TAB = constants.TAB

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB
    local P_AIM = "havoc_aimbot_enabled"
    local P_SILENT = "july_silent_aim"

    menu.add_tab(TAB, "J", "full")

    -- Row 1: Aimbot | Aim Visuals
    menu.add_group(TAB, "Aimbot", 0)
    menu.add_checkbox(TAB, "Aimbot", P_AIM, "Enable Aimbot", false, { key = 2, show_mode = false })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_bone", "Target Bone", { "Head", "Torso", "Closest" }, 0, { parent = P_AIM })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_target_type", "Priority", { "Crosshair", "Distance" }, 0, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_fov", "FOV Radius", 10, 500, 150, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_max_distance", "Max Distance", 0, 3000, 3000, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_smooth", "Smoothness", 1, 100, 8, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_sticky", "Sticky Target", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_target_players", "Target Players", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_target_npcs", "Target NPCs", true, { parent = P_AIM })
    menu.add_separator(TAB, "Aimbot")
    menu.add_checkbox(TAB, "Aimbot", P_SILENT, "Enable Silent Aim", false, { parent = P_AIM })

    menu.add_group(TAB, "Aim Visuals", 0, true)
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_draw_fov", "Aimbot FOV Circle", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_fill_fov", "Fill Aimbot FOV", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 0.15 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_target_line", "Aimbot Target Line", false, {
        parent = P_AIM, colorpicker = { 1.0, 0.3, 0.3, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_rainbow", "Aimbot Rainbow", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_draw_fov", "Silent FOV Circle", false, {
        parent = P_SILENT, colorpicker = { 0.55, 0.2, 1.0, 1.0 },
    })
    menu.add_combo(TAB, "Aim Visuals", "july_silent_fov_style", "Silent FOV Style", { "Outline", "Filled Circle" }, 1, { parent = P_SILENT })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_target_line", "Silent Target Line", false, {
        parent = P_SILENT, colorpicker = { 1.0, 0.25, 0.25, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_rainbow", "Silent Rainbow", false, { parent = P_SILENT })

    -- Row 2: Silent Options | NPC Visuals
    menu.add_group(TAB, "Silent Options", 0)
    July.require("features.combat.combat_menu").register_silent_aim(TAB, "Silent Options", "july_silent_", P_SILENT)

    menu.add_group(TAB, "NPC Visuals", 0, true)
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_enabled", "Enable NPC Visuals", false)
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_box", "Box", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_box_style", "Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_box_fill", "Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_name", "Name", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_distance", "Distance", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_held_item", "Held Item", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_npc_type", "Type Tag", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_health_bar", "Health Bar", false, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_health_text", "Health Text", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_chams", "Chams", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_chams_style", "Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_skeleton", "Skeleton", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_hide_dead", "Hide Dead", false, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_rainbow", "Rainbow", false, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_max_distance", "Max Distance", 0, 3000, 3000, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_name_size", "Name Size", 6, 24, 13, { parent = "havoc_npc_name" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_health_text_size", "Health Text Size", 6, 18, 8, { parent = "havoc_npc_health_text" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_held_item_size", "Weapon Text Size", 6, 18, 10, { parent = "havoc_npc_held_item" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_distance_size", "Distance Text Size", 6, 18, 10, { parent = "havoc_npc_distance" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_npc_type_size", "Type Tag Size", 6, 18, 9, { parent = "havoc_npc_npc_type" })

    -- Row 3: Loot | Traps
    menu.add_group(TAB, "Loot Visuals", 0)
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_enabled", "Enable Loot Visuals", false)
    menu.add_multicombo(TAB, "Loot Visuals", "havoc_loot_types", "Loot Types",
        loot_catalog.MULTICOMBO_LABELS, loot_catalog.MULTICOMBO_DEFAULTS, { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_distance", "Show Distance", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_distance_pos", "Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_loot_distance" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_marker", "Position Marker", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_rainbow", "Rainbow", false, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_max_distance", "Max Distance", 0, 5000, 5000, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_text_size", "Text Size", 1, 15, 13, { parent = "havoc_loot_enabled" })

    menu.add_group(TAB, "Trap Visuals", 0, true)
    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_enabled", "Enable Trap Visuals", false)
    menu.add_multicombo(TAB, "Trap Visuals", "havoc_trap_types", "Trap Types",
        trap_types.MULTICOMBO_LABELS, trap_types.MULTICOMBO_DEFAULTS, { parent = "havoc_trap_enabled" })
    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_rainbow", "Rainbow", false, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_max_distance", "Max Distance", 0, 5000, 3000, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_text_size", "Text Size", 6, 18, 13, { parent = "havoc_trap_enabled" })

    -- Row 4: Weapon Mods | Config
    menu.add_group(TAB, "Weapon Mods", 0)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_recoil", "No Recoil", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_spread", "No Spread", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_sway", "No Sway", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_fast_vel", "Fast Bullet Velocity", false)

    menu.add_group(TAB, "Config", 0, true)
end

return M

end)()

-- ── features/utility/config.lua ──
July._mods["features.utility.config"] = (function()
local constants = July.require("core.constants")
local settings = July.require("core.settings")

local M = {}

M.CONFIG_IDS = {
    "havoc_aimbot_enabled", "havoc_aimbot_bone", "havoc_aimbot_target_type",
    "havoc_aimbot_fov", "havoc_aimbot_max_distance", "havoc_aimbot_smooth", "havoc_aimbot_sticky",
    "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
    "july_silent_aim", "july_silent_rainbow",
    "july_silent_target_type", "july_silent_bone",
    "july_silent_filter_health", "july_silent_filter_visible", "july_silent_filter_team",
    "july_silent_target_players", "july_silent_target_npcs", "july_silent_target_npc_soldiers", "july_silent_target_npc_bosses",
    "july_silent_max_dist", "july_silent_fov", "july_silent_sticky",
    "july_silent_wallbang", "july_silent_bullet_tp", "july_silent_tp_ray_mode", "july_silent_tp_ray_vis",
    "july_silent_bullet_manip", "july_silent_manip_dist", "july_silent_manip_status",
    "july_silent_draw_fov", "july_silent_fov_style", "july_silent_target_line",
    "havoc_npc_enabled", "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill",
    "havoc_npc_name", "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_npc_type",
    "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_chams_style",
    "havoc_npc_skeleton", "havoc_npc_hide_dead", "havoc_npc_rainbow",
    "havoc_npc_max_distance", "havoc_npc_name_size", "havoc_npc_health_text_size",
    "havoc_npc_held_item_size", "havoc_npc_distance_size", "havoc_npc_npc_type_size",
    "havoc_loot_enabled", "havoc_loot_types", "havoc_loot_distance", "havoc_loot_distance_pos",
    "havoc_loot_marker", "havoc_loot_filter", "havoc_loot_rainbow",
    "havoc_loot_max_distance", "havoc_loot_text_size",
    "havoc_trap_enabled", "havoc_trap_types", "havoc_trap_rainbow",
    "havoc_trap_max_distance", "havoc_trap_text_size",
    "havoc_no_recoil", "havoc_no_spread", "havoc_no_sway", "havoc_fast_vel",
}

M.CONFIG_COLOR_IDS = {
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "july_silent_draw_fov", "july_silent_target_line", "july_silent_tp_ray_vis",
    "havoc_npc_box", "havoc_npc_box_fill", "havoc_npc_name", "havoc_npc_distance",
    "havoc_npc_held_item", "havoc_npc_npc_type", "havoc_npc_health_text",
    "havoc_npc_chams", "havoc_npc_skeleton",
}

local function val_to_str(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false"
    elseif t == "number" then return tostring(v)
    elseif t == "table" then
        local parts = {}
        for i = 1, #v do
            if type(v[i]) == "boolean" then
                parts[i] = v[i] and "1" or "0"
            elseif type(v[i]) == "number" then
                parts[i] = tostring(v[i])
            else
                parts[i] = tostring(v[i])
            end
        end
        return table.concat(parts, ",")
    end
    return tostring(v)
end

local function str_to_val(s)
    if s == "true" then return true end
    if s == "false" then return false end
    local n = tonumber(s)
    if n then return n end
    if s:find(",", 1, true) then
        local out = {}
        for part in s:gmatch("[^,]+") do
            if part == "1" or part == "true" then out[#out + 1] = true
            elseif part == "0" or part == "false" then out[#out + 1] = false
            else
                local num = tonumber(part)
                out[#out + 1] = num or part
            end
        end
        return out
    end
    local r, g, b, a = s:match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
    if r then return { tonumber(r), tonumber(g), tonumber(b), tonumber(a) } end
    return nil
end

function M.save()
    local lines = { "# values" }
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        local val = settings.get(id)
        if val ~= nil then lines[#lines + 1] = id .. "=" .. val_to_str(val) end
    end
    lines[#lines + 1] = "# colors"
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        local val = settings.color(id)
        if val and type(val) == "table" and #val == 4 then
            lines[#lines + 1] = id .. "=" .. val_to_str(val)
        end
    end

    local f, err = io.open(constants.CONFIG_PATH, "w")
    if not f then
        notify.Warning("Config save failed: " .. tostring(err), "", 4)
        return
    end
    f:write(table.concat(lines, "\n"))
    f:close()
    notify.Success("Config saved")
end

function M.load()
    local f = io.open(constants.CONFIG_PATH, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    local values, colors = {}, {}
    local section = nil
    for line in content:gmatch("[^\r\n]+") do
        if line == "# values" then section = "values"
        elseif line == "# colors" then section = "colors"
        else
            local key, val_str = line:match("^([^=]+)=(.+)$")
            if key and val_str then
                if section == "colors" then colors[key] = str_to_val(val_str)
                elseif section == "values" then values[key] = str_to_val(val_str) end
            end
        end
    end

    local count = 0
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        if values[id] ~= nil then
            local ok = (menu.set and menu.set(id, values[id])) or (menu.Set and menu.Set(id, values[id]))
            if ok ~= false then count = count + 1 end
        end
    end
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        if colors[id] ~= nil then
            local ok = (menu.set_color and menu.set_color(id, colors[id])) or (menu.SetColor and menu.SetColor(id, colors[id]))
            if ok ~= false then count = count + 1 end
        end
    end

    if count > 0 then notify.Success("Loaded " .. count .. " settings") end
end

function M.register_menu()
    local TAB = July.require("menu.menu_defs").TAB
    menu.add_button(TAB, "Config", "btn_save_config", "Save Config", M.save)
    menu.add_button(TAB, "Config", "btn_load_config", "Load Config", M.load)
end

return M

end)()

-- ── features/combat/weapon_mods.lua ──
July._mods["features.combat.weapon_mods"] = (function()
local settings = July.require("core.settings")

local M = {}

local PATCHES = {
    havoc_no_recoil = { vPunchBase = 0, hPunchBase = 0 },
    havoc_no_spread = { spreadReduce = 100 },
    havoc_no_sway = { weight = 0, aimWeight = 0, unAimWeight = 0 },
    havoc_fast_vel = { vel = 100000 },
}

function M.apply()
    for id, patch in pairs(PATCHES) do
        if settings.bool(id, false) then
            pcall(applygc, patch)
        end
    end
end

return M

end)()

-- ── features/combat/targeting.lua ──
July._mods["features.combat.targeting"] = (function()
local settings = July.require("core.settings")
local math_util = July.require("core.math_util")
local env = July.require("core.env")
local entity_scan = July.require("game.entity_scan")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")
local constants = July.require("core.constants")
local combat_menu = July.require("features.combat.combat_menu")

local M = {}

local TARGET_SCAN_MS = 33
local last_scan = 0

local SILENT_BONES = combat_menu.SILENT_BONES
local BONE_MAP = combat_menu.BONE_MAP

local function w2s(x, y, z)
    if utility and utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.screen_center()
    if input and input.GetScreenCenter then
        return input.GetScreenCenter()
    end
    if utility and utility.get_screen_size then
        local w, h = utility.get_screen_size()
        return w * 0.5, h * 0.5
    end
    return 960, 540
end

function M.get_server_origin()
    return combat_origin.get_server_origin()
end

function M.bone_name(prefix)
    local idx = settings.num(prefix .. "bone", 0)
    local label = SILENT_BONES[idx + 1] or "Head"
    return BONE_MAP[label] or label
end

function M.is_npc_target(target)
    return target and target.is_npc == true
end

local function get_npc_kind(model_name)
    if constants.NPC_BOSS_NAMES[model_name] then return "boss" end
    return "soldier"
end

local function npc_from_entity(ent)
    return {
        is_npc = true,
        inst = ent.model,
        humanoid = ent.humanoid,
        root = ent.root,
        parts = ent.parts,
        name = ent.model.Name,
        kind = get_npc_kind(ent.model.Name),
    }
end

local function player_from_entity(p)
    return {
        is_npc = false,
        player = p,
        character = p.Character,
        name = p.Name or p.name,
    }
end

local function part_world(part)
    if not part then return nil end
    local ok, pos = pcall(function() return part.Position end)
    if ok and pos then
        if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
        if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    end
    return nil
end

function M.bone_world(target, bone)
    if not target then return nil end

    if M.is_npc_target(target) then
        if bone == "Closest" then return part_world(target.parts["Head"] or target.root) end
        if bone == "Head" then return part_world(target.parts["Head"] or target.root) end
        if bone == "UpperTorso" or bone == "Torso" then
            return part_world(target.parts["UpperTorso"] or target.parts["Torso"] or target.root)
        end
        return part_world(target.parts[bone] or target.root)
    end

    local char = target.character
    if not char or not env.is_valid(char) then return nil end

    if bone == "Closest" then
        return part_world(env.find_child(char, "Head") or env.find_child(char, "HumanoidRootPart"))
    end

    local mapped = BONE_MAP[bone] or bone
    local part = env.find_child(char, mapped) or env.find_child(char, bone)
    return part_world(part)
end

function M.resolve_bone_world(target, bone, cx, cy)
    if bone == "Closest" then
        local best, best_d = nil, math.huge
        for i = 1, #SILENT_BONES - 1 do
            local b = BONE_MAP[SILENT_BONES[i]] or SILENT_BONES[i]
            local pos = M.bone_world(target, b)
            if pos then
                local sx, sy, ok = w2s(pos.x, pos.y, pos.z)
                if ok then
                    local dx, dy = sx - cx, sy - cy
                    local d = dx * dx + dy * dy
                    if d < best_d then
                        best_d = d
                        best = pos
                    end
                end
            end
        end
        return best
    end
    return M.bone_world(target, bone)
end

local function passes_team(target)
    if M.is_npc_target(target) then return true end
    if not settings.bool("july_silent_filter_team", true) then return true end

    local char = target.character
    if not char then return true end

    local hum = env.find_child(char, "Humanoid")
    if not hum then return true end

    local ok, team = pcall(function() return hum:GetAttribute("Team") end)
    if not ok then return true end

    local lp = env.get_local_player()
    if not lp or not lp.Character then return true end
    local lp_hum = env.find_child(lp.Character, "Humanoid")
    if not lp_hum then return true end
    local ok2, my_team = pcall(function() return lp_hum:GetAttribute("Team") end)
    if not ok2 then return true end

    return team ~= my_team
end

local function is_alive(target)
    if M.is_npc_target(target) then
        local hp = target.humanoid and target.humanoid.Health
        return hp and hp > 0
    end
    local char = target.character
    if not char then return false end
    local hum = env.find_child(char, "Humanoid")
    if not hum then return false end
    local hp = hum.Health or hum.health
    return hp and hp > 0
end

local function passes_visibility(target, aim, origin)
    if not settings.bool("july_silent_filter_visible", false) then return true end
    if not raycast or not raycast.is_visible or not origin or not aim then return true end
    return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z) == true
end

function M.passes_filters(target, prefix, aim, origin)
    if not target then return false end
    if settings.bool(prefix .. "filter_health", true) and not is_alive(target) then return false end
    if not passes_team(target) then return false end
    if not passes_visibility(target, aim, origin) then return false end
    return true
end

local function within_distance(target, origin, prefix)
    local max_d = settings.num(prefix .. "max_dist", 500)
    if max_d <= 0 or not origin then return true end

    local aim = M.bone_world(target, "Head") or M.bone_world(target, "UpperTorso")
    if not aim then return false end

    return math_util.distance3(aim.x - origin.x, aim.y - origin.y, aim.z - origin.z) <= max_d
end

local function within_fov(target, cx, cy, fov, prefix, origin)
    local aim = M.resolve_bone_world(target, M.bone_name(prefix), cx, cy)
    if not aim then return false end
    local sx, sy, ok = w2s(aim.x, aim.y, aim.z)
    if not ok then return false end
    local dx, dy = sx - cx, sy - cy
    return math.sqrt(dx * dx + dy * dy) <= fov
end

function M.collect_candidates(prefix, origin)
    local out = {}

    if settings.bool(prefix .. "target_players", true) then
        local players = entity.GetPlayers and entity.GetPlayers() or {}
        for i = 1, #players do
            local p = players[i]
            local lp = env.get_local_player()
            if p ~= lp then
                out[#out + 1] = player_from_entity(p)
            end
        end
    end

    if settings.bool(prefix .. "target_npcs", true) then
        local cache = entity_scan.get_cache()
        for i = 1, #cache do
            local ent = cache[i]
            local npc = npc_from_entity(ent)
            if npc.kind == "boss" and settings.bool(prefix .. "target_npc_bosses", true) then
                out[#out + 1] = npc
            elseif npc.kind == "soldier" and settings.bool(prefix .. "target_npc_soldiers", true) then
                out[#out + 1] = npc
            end
        end
    end

    return out
end

function M.find_target(cx, cy, fov, prefix)
    local origin = combat_origin.get_fire_origin() or silent_ray.get_camera_origin()
    if not origin and camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos and pos.X then
            origin = { x = pos.X, y = pos.Y, z = pos.Z }
        end
    end

    local candidates = M.collect_candidates(prefix, origin)
    local crosshair_prio = settings.num(prefix .. "target_type", 0) == 0

    local best, best_score = nil, math.huge

    for i = 1, #candidates do
        local t = candidates[i]
        local aim = M.resolve_bone_world(t, M.bone_name(prefix), cx, cy)
        if aim and M.passes_filters(t, prefix, aim, origin) and within_distance(t, origin, prefix) and within_fov(t, cx, cy, fov, prefix, origin) then
            local sx, sy, ok = w2s(aim.x, aim.y, aim.z)
            if ok then
                local px = math.sqrt((sx - cx) ^ 2 + (sy - cy) ^ 2)
                local world = math_util.distance3(aim.x - origin.x, aim.y - origin.y, aim.z - origin.z)
                local score = crosshair_prio and px or world
                if score < best_score then
                    best_score = score
                    best = t
                end
            end
        end
    end

    return best
end

function M.is_target_valid(target, prefix, cx, cy, fov)
    if not target then return false end
    local origin = combat_origin.get_fire_origin()
    local aim = M.resolve_bone_world(target, M.bone_name(prefix), cx, cy)
    return aim
        and M.passes_filters(target, prefix, aim, origin)
        and within_distance(target, origin, prefix)
        and within_fov(target, cx, cy, fov, prefix, origin)
end

function M.is_aim_target(target)
    if M.is_npc_target(target) then
        return is_alive(target)
    end
    return is_alive(target)
end

return M

end)()

-- ── features/combat/bullet_tp_ray.lua ──
July._mods["features.combat.bullet_tp_ray"] = (function()
local M = {}

M.MODES = { "Direct", "Snap", "Deep" }

local BACK_OFFSET = {
    Direct = 3.5,
    Snap = 1.75,
    Deep = 6.0,
}

function M.mode_name(idx)
    return M.MODES[(idx or 0) + 1] or "Direct"
end

function M.track_origin(camera, aim, mode_name)
    if not camera or not aim then return nil end
    local back = BACK_OFFSET[mode_name] or BACK_OFFSET.Direct
    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return aim end
    local inv = back / len
    return {
        x = aim.x - dx * inv,
        y = aim.y - dy * inv,
        z = aim.z - dz * inv,
    }
end

function M.build_path(mode_name, origin, aim)
    if not origin or not aim then return {} end
    return { origin, aim }
end

return M

end)()

-- ── features/combat/silent_resolve.lua ──
July._mods["features.combat.silent_resolve"] = (function()
local settings = July.require("core.settings")
local silent_ray = July.require("core.silent_ray")
local manip_math = July.require("core.manip_math")
local targeting = July.require("features.combat.targeting")
local bullet_tp_ray = July.require("features.combat.bullet_tp_ray")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }
local PIERCE_PAD = 1.25

local function pierce_origin(from, to)
    if not from or not to then return from end
    if not raycast or not raycast.cast then return from end
    if raycast.is_ready and not raycast.is_ready() then return from end

    local fx, fy, fz = from.x, from.y, from.z
    local tx, ty, tz = to.x, to.y, to.z
    local dx, dy, dz = tx - fx, ty - fy, tz - fz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return from end

    local hit, _, dist = raycast.cast(fx, fy, fz, tx, ty, tz)
    if not hit or not dist or dist <= 0.05 then return from end

    local travel = dist + PIERCE_PAD
    if travel >= len - 0.5 then
        travel = len * 0.65
    end

    local t = travel / len
    return {
        x = fx + dx * t,
        y = fy + dy * t,
        z = fz + dz * t,
    }
end

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local aim = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not aim then return nil, nil, OFF_INFO end

    local track_origin = camera
    local manip_info = OFF_INFO
    local bullet_tp = settings.bool(prefix .. "bullet_tp", false)
    local wallbang = settings.bool(prefix .. "wallbang", false)

    if bullet_tp then
        local head = targeting.bone_world(target, "Head") or aim
        local mode_name = bullet_tp_ray.mode_name(settings.num(prefix .. "tp_ray_mode", 0))
        aim = head
        track_origin = bullet_tp_ray.track_origin(camera, aim, mode_name) or aim
        manip_info = {
            state = "tp",
            peek = nil,
            radius = 0,
            tp_mode = mode_name,
            tp_path = bullet_tp_ray.build_path(mode_name, track_origin, aim),
        }
    elseif settings.bool(prefix .. "bullet_manip", false) then
        local body = targeting.get_server_origin()
        local max_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))

        if body then
            local ev = manip_math.evaluate_manipulation(body, aim, { max_radius = max_r })
            manip_info = {
                state = ev.state,
                peek = ev.peek,
                radius = ev.radius or max_r,
            }
            if ev.state == "ready" and ev.peek then
                track_origin = manip_math.peek_track_origin(ev.peek) or camera
            end
        else
            manip_info = { state = "blocked", peek = nil, radius = max_r }
        end

        if wallbang then
            track_origin = pierce_origin(track_origin, aim) or track_origin
        end
    elseif wallbang then
        track_origin = pierce_origin(track_origin, aim) or track_origin
    end

    return track_origin, aim, manip_info
end

return M

end)()

-- ── features/combat/aimbot.lua ──
July._mods["features.combat.aimbot"] = (function()
local settings = July.require("core.settings")
local constants = July.require("core.constants")
local entity_scan = July.require("game.entity_scan")
local env = July.require("core.env")

local M = {}

local locked_ent = nil
local locked_player = nil
local next_acquire = 0

M.draw_state = {
    scx = nil,
    scy = nil,
    fov = 150,
    draw_fov = false,
    fill_fov = false,
    active = false,
    tx = 0,
    ty = 0,
}

local BONE_MAP = {
    [0] = "Head",
    [1] = "Torso",
    [2] = "Closest",
}

local function screen_center()
    if input and input.GetScreenCenter then
        return input.GetScreenCenter()
    end
    if input and input.get_screen_center then
        return input.get_screen_center()
    end
    return 960, 540
end

local function w2s(pos)
    if not pos then return 0, 0, false end
    local x = pos.X or pos.x
    local y = pos.Y or pos.y
    local z = pos.Z or pos.z
    if utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function get_npc_aim_pos(ent, bone_idx, scx, scy)
    if bone_idx == 2 then
        local best, best_d = nil, math.huge
        for name, part in pairs(ent.parts) do
            local pos = part.Position
            if pos then
                local sx, sy, ok = w2s(pos)
                if ok then
                    local d = (sx - scx) ^ 2 + (sy - scy) ^ 2
                    if d < best_d then
                        best_d = d
                        best = pos
                    end
                end
            end
        end
        return best
    end
    local bone = BONE_MAP[bone_idx] or "Head"
    if bone == "Head" then
        return ent.parts["Head"] and ent.parts["Head"].Position or ent.root.Position
    end
    return ent.parts["Torso"] and ent.parts["Torso"].Position
        or ent.parts["UpperTorso"] and ent.parts["UpperTorso"].Position
        or ent.root.Position
end

local function get_player_aim_pos(char, bone_idx, scx, scy)
    if not char or not env.is_valid(char) then return nil end
    if bone_idx == 2 then
        local best, best_d = nil, math.huge
        local names = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
        for i = 1, #names do
            local part = env.find_child(char, names[i])
            if part then
                local ok, pos = pcall(function() return part.Position end)
                if ok and pos then
                    local sx, sy, vis = w2s(pos)
                    if vis then
                        local d = (sx - scx) ^ 2 + (sy - scy) ^ 2
                        if d < best_d then
                            best_d = d
                            best = pos
                        end
                    end
                end
            end
        end
        return best
    end
    local bone = bone_idx == 1 and "UpperTorso" or "Head"
    local part = env.find_child(char, bone) or env.find_child(char, "Head")
    if part then
        local ok, pos = pcall(function() return part.Position end)
        if ok then return pos end
    end
    return nil
end

local function npc_alive(ent)
    local hp = ent.humanoid and ent.humanoid.Health
    return hp and hp > 0
end

local function player_alive(char)
    local hum = env.find_child(char, "Humanoid")
    if not hum then return false end
    local hp = hum.Health or hum.health
    return hp and hp > 0
end

local function evaluate_npc(ent, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
    if not npc_alive(ent) then return nil end
    local pos = get_npc_aim_pos(ent, bone_idx, scx, scy)
    if not pos then return nil end
    local px, py, pz = pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z
    local dist = (cam_pos - pos).Magnitude
    if max_dist > 0 and dist > max_dist then return nil end
    local sx, sy, vis = w2s(pos)
    if not vis then return nil end
    local px_dist = math.sqrt((sx - scx) ^ 2 + (sy - scy) ^ 2)
    if px_dist > fov then return nil end
    return {
        kind = "npc",
        ent = ent,
        pos = { x = px, y = py, z = pz },
        score = crosshair_prio and px_dist or dist,
        sx = sx,
        sy = sy,
    }
end

local function evaluate_player(p, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
    local lp = env.get_local_player()
    if p == lp then return nil end
    local char = p.Character or p.character
    if not char or not player_alive(char) then return nil end
    local pos = get_player_aim_pos(char, bone_idx, scx, scy)
    if not pos then return nil end
    local px, py, pz = pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z
    local dist = (cam_pos - pos).Magnitude
    if max_dist > 0 and dist > max_dist then return nil end
    local sx, sy, vis = w2s(pos)
    if not vis then return nil end
    local px_dist = math.sqrt((sx - scx) ^ 2 + (sy - scy) ^ 2)
    if px_dist > fov then return nil end
    return {
        kind = "player",
        player = p,
        char = char,
        pos = { x = px, y = py, z = pz },
        score = crosshair_prio and px_dist or dist,
        sx = sx,
        sy = sy,
    }
end

local function smooth_mouse(sx, sy, scx, scy, smooth)
    if not input or not input.move_mouse then return false end
    local dx, dy = sx - scx, sy - scy
    local mx, my = dx / smooth, dy / smooth
    if dx > 0 and mx < 0.5 then mx = 0.5 elseif dx < 0 and mx > -0.5 then mx = -0.5 end
    if dy > 0 and my < 0.5 then my = 0.5 elseif dy < 0 and my > -0.5 then my = -0.5 end
    input.move_mouse(mx, my)
    return true
end

local function aim_at(target, smooth)
    if not target or not target.pos then return false end
    local x, y, z = target.pos.x, target.pos.y, target.pos.z

    if camera and camera.look_at then
        return pcall(camera.look_at, x, y, z, smooth) == true
    end
    if camera and camera.LookAt then
        return pcall(camera.LookAt, x, y, z, smooth) == true
    end

    local scx, scy = screen_center()
    if target.sx and target.sy then
        return smooth_mouse(target.sx, target.sy, scx, scy, smooth)
    end

    if target.kind == "npc" and target.ent and camera.TrackTarget then
        local bone_idx = settings.num("havoc_aimbot_bone", 0)
        local part = get_npc_aim_pos(target.ent, bone_idx, scx, scy)
        if part then
            local key = settings.get("havoc_aimbot_enabled") and (menu.get_key and menu.get_key("havoc_aimbot_enabled") or 2) or 2
            if key == 0 then key = 2 end
            pcall(camera.TrackTarget, part, target.ent.humanoid, key, settings.num("havoc_aimbot_max_distance", 3000))
            return true
        end
    end

    return false
end

local function find_target(cam_pos, scx, scy, fov, bone_idx, max_dist, crosshair_prio, target_players, target_npcs)
    local best, best_score = nil, math.huge
    local players = entity.GetPlayers and entity.GetPlayers() or {}

    if target_npcs then
        local cache = entity_scan.get_cache()
        for i = 1, #cache do
            local hit = evaluate_npc(cache[i], bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
            if hit and hit.score < best_score then
                best_score = hit.score
                best = hit
            end
        end
    end

    if target_players then
        for i = 1, #players do
            local hit = evaluate_player(players[i], bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
            if hit and hit.score < best_score then
                best_score = hit.score
                best = hit
            end
        end
    end

    return best
end

local function sticky_valid(target, cam_pos, scx, scy, fov, bone_idx, max_dist)
    if not target then return false end
    if target.kind == "npc" then
        local hit = evaluate_npc(target.ent, bone_idx, cam_pos, max_dist, scx, scy, fov, true)
        return hit ~= nil
    end
    if target.kind == "player" then
        local hit = evaluate_player(target.player, bone_idx, cam_pos, max_dist, scx, scy, fov, true)
        return hit ~= nil
    end
    return false
end

function M.tick()
    if not settings.enabled("havoc_aimbot_enabled") then
        M.reset()
        return
    end

    local scx, scy = screen_center()
    local fov = settings.num("havoc_aimbot_fov", 150)
    local bone_idx = settings.num("havoc_aimbot_bone", 0)
    local max_dist = settings.num("havoc_aimbot_max_distance", 3000)
    local smooth = math.max(1, settings.num("havoc_aimbot_smooth", 8))
    local sticky = settings.bool("havoc_aimbot_sticky", false)
    local crosshair_prio = settings.num("havoc_aimbot_target_type", 0) == 0
    local target_players = settings.bool("havoc_aimbot_target_players", false)
    local target_npcs = settings.bool("havoc_aimbot_target_npcs", true)

    M.draw_state.scx = scx
    M.draw_state.scy = scy
    M.draw_state.fov = fov
    M.draw_state.draw_fov = settings.bool("havoc_aimbot_draw_fov", false)
    M.draw_state.fill_fov = settings.bool("havoc_aimbot_fill_fov", false)

    local cam_pos = camera.GetPosition and camera.GetPosition() or camera.get_position and camera.get_position()
    if not cam_pos then return end

    local now = utility.GetTime and utility.GetTime() or os.clock()
    local target = locked_ent

    if sticky and target and sticky_valid(target, cam_pos, scx, scy, fov, bone_idx, max_dist) then
        if target.kind == "npc" then
            local hit = evaluate_npc(target.ent, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
            if hit then target = hit end
        else
            local hit = evaluate_player(target.player, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
            if hit then target = hit end
        end
    elseif now >= next_acquire or not target then
        next_acquire = now + constants.AIMBOT_ACQUIRE_INTERVAL
        target = find_target(cam_pos, scx, scy, fov, bone_idx, max_dist, crosshair_prio, target_players, target_npcs)
        if sticky then
            locked_ent = target
        end
    end

    if target then
        M.draw_state.active = true
        M.draw_state.tx = target.sx
        M.draw_state.ty = target.sy
        aim_at(target, smooth)
    else
        M.draw_state.active = false
        if camera.StopTracking then camera.StopTracking() end
    end
end

function M.reset()
    locked_ent = nil
    locked_player = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    if camera and camera.StopTracking then camera.StopTracking() end
    if camera and camera.stop_tracking then camera.stop_tracking() end
end

return M

end)()

-- ── features/combat/silent_aim.lua ──
July._mods["features.combat.silent_aim"] = (function()
local settings = July.require("core.settings")
local targeting = July.require("features.combat.targeting")
local weapons = July.require("game.weapons")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")
local silent_resolve = July.require("features.combat.silent_resolve")

local M = {}

local PREFIX = "july_silent_"
local P_MASTER = "july_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33

local locked_target = nil
local last_target_scan = 0

M.draw_state = {
    scx = nil,
    scy = nil,
    fov = 150,
    draw_fov = false,
    fill_fov = false,
    active = false,
    tx = 0,
    ty = 0,
    manip = { state = "off" },
    tp_path = nil,
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or (os.clock() * 1000)
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)
    local now = tick_ms()

    if sticky and locked_target then
        if not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
            locked_target = nil
        end
    end

    if locked_target and sticky then return end

    if now - last_target_scan < TARGET_SCAN_MS then return end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

function M.tick()
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil

    if not settings.enabled("havoc_aimbot_enabled") or not settings.enabled(P_MASTER) or not silent_ray.available() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    silent_ray.ensure_hook()

    if not weapons.holding_weapon() then
        silent_ray.stop()
        return
    end

    combat_origin.sync_weapon(weapons.cached_held())

    local cx, cy = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 150)

    M.draw_state.scx = cx
    M.draw_state.scy = cy
    M.draw_state.fov = fov
    M.draw_state.draw_fov = settings.bool(PREFIX .. "draw_fov", false)
    M.draw_state.fill_fov = settings.num(PREFIX .. "fov_style", 1) == 1

    update_target(cx, cy, fov)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        return
    end

    local origin, aim, manip_info = silent_resolve.resolve_track(locked_target, PREFIX, cx, cy)
    if not aim or not origin then
        silent_ray.stop()
        return
    end

    M.draw_state.manip = manip_info or { state = "off" }
    M.draw_state.tp_path = manip_info and manip_info.tp_path or nil

    local fx, fy, fvis = utility.WorldToScreen(aim.x, aim.y, aim.z)
    if fvis then
        M.draw_state.active = true
        M.draw_state.tx = fx
        M.draw_state.ty = fy
    end

    silent_ray.track(origin, aim, SHOOT_VK)
end

function M.reset()
    locked_target = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    silent_ray.stop()
end

function M.get_prefix()
    return PREFIX
end

function M.get_master_id()
    return P_MASTER
end

return M

end)()

-- ── features/visuals/npc_esp.lua ──
July._mods["features.visuals.npc_esp"] = (function()
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")

local M = {}

local frame_counter = 0

function M.set_frame_counter(n)
    frame_counter = n
end

local function get_npc_type(entity_name)
    local constants = July.require("core.constants")
    if string.find(entity_name, "[Sniper]", 1, true) then return "Sniper" end
    if constants.NPC_BOSS_NAMES[entity_name] then return "Boss" end
    if entity_name == "Sentry" then return nil end
    return "Scav"
end

local function get_held_item_name(ent)
    local model_children = ent.model:GetChildren()
    if model_children then
        for i = 1, #model_children do
            local child = model_children[i]
            if child.ClassName == "Tool" then
                return child.Name
            end
        end
    end

    for _, part in pairs(ent.parts) do
        local children = part:GetChildren()
        if children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Model" and child:FindFirstChild("Handle") then
                    return child.Name
                end
            end
        end
    end

    return nil
end

function M.render(cam_pos)
    if not settings.enabled("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    if #entity_cache == 0 then return end

    local ent_rgb = settings.bool("havoc_npc_rainbow", false) and color_util.rainbow_color(0.4) or nil

    local box_on = settings.bool("havoc_npc_box", false)
    local fill_on = settings.bool("havoc_npc_box_fill", false)
    local name_on = settings.bool("havoc_npc_name", false)
    local dist_on = settings.bool("havoc_npc_distance", false)
    local held_on = settings.bool("havoc_npc_held_item", false)
    local type_on = settings.bool("havoc_npc_npc_type", false)
    local health_bar_on = settings.bool("havoc_npc_health_bar", false)
    local health_text_on = settings.bool("havoc_npc_health_text", false)
    local chams_on = settings.bool("havoc_npc_chams", false)
    local skeleton_on = settings.bool("havoc_npc_skeleton", false)

    local box_style = settings.num("havoc_npc_box_style", 0)
    local chams_style = settings.num("havoc_npc_chams_style", 0)
    local hide_dead = settings.bool("havoc_npc_hide_dead", false)
    local max_dist = settings.num("havoc_npc_max_distance", 3000)

    local name_size = settings.num("havoc_npc_name_size", 13)
    local health_text_size = settings.num("havoc_npc_health_text_size", 8)
    local held_item_size = settings.num("havoc_npc_held_item_size", 10)
    local dist_size = settings.num("havoc_npc_distance_size", 10)
    local npc_type_size = settings.num("havoc_npc_npc_type_size", 9)

    local needs_full_bounds = box_on and box_style == 2

    local esp_opts = {
        box_style = box_style,
        name_size = name_size,
        health_text_size = health_text_size,
        held_item_size = held_item_size,
        dist_size = dist_size,
        npc_type_size = npc_type_size,
    }

    for i = 1, #entity_cache do
        local ent = entity_cache[i]

        local health = ent.humanoid.Health or 0
        local max_health = ent.humanoid.MaxHealth or 100

        if not (hide_dead and health <= 0) then
            local root_pos = ent.root.Position
            if root_pos then
                local dist = (cam_pos - root_pos).Magnitude
                if dist <= max_dist then
                    local sc = ent.scr_bounds
                    local do_update = (frame_counter + i) % July.require("core.constants").BOUNDS_UPDATE_INTERVAL == 0

                    if needs_full_bounds or chams_on or skeleton_on then
                        local part_pos = {}
                        for name, part in pairs(ent.parts) do
                            local pos = part.Position
                            if pos then part_pos[name] = pos end
                        end
                        local bounds = draw_util.get_entity_bounds(part_pos, ent.part_size, root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                        if chams_on and bounds.valid then
                            draw_util.draw_entity_chams(part_pos, ent.part_size,
                                ent_rgb or settings.color("havoc_npc_chams", { 1, 0.2, 0.2, 0.55 }), chams_style)
                        end
                        if skeleton_on and bounds.valid then
                            draw_util.draw_entity_skeleton(part_pos,
                                ent_rgb or settings.color("havoc_npc_skeleton", { 1, 1, 1, 1 }))
                        end
                        if needs_full_bounds and bounds.valid then
                            draw_util.draw_entity_3d_box(part_pos, ent.part_size,
                                ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 }))
                        end
                    elseif do_update then
                        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                    end

                    if sc.valid then
                        local name_str = ent.model.Name
                        esp_opts.box = box_on
                        esp_opts.box_color = ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 })
                        esp_opts.box_fill = fill_on
                        esp_opts.box_fill_color = ent_rgb or settings.color("havoc_npc_box_fill", { 1, 1, 1, 0.35 })
                        esp_opts.name = name_on
                        esp_opts.name_color = ent_rgb or settings.color("havoc_npc_name", { 0.92, 0.92, 0.92, 1 })
                        esp_opts.dist = dist_on
                        esp_opts.dist_color = ent_rgb or settings.color("havoc_npc_distance", { 0.67, 0.67, 0.67, 1 })
                        esp_opts.health_bar = health_bar_on
                        esp_opts.health_text = health_text_on
                        esp_opts.health_text_color = ent_rgb or settings.color("havoc_npc_health_text", { 0.3, 1, 0.4, 1 })
                        esp_opts.npc_type_on = type_on
                        esp_opts.npc_type_color = ent_rgb or settings.color("havoc_npc_npc_type", { 1, 0.5, 0, 0.85 })
                        esp_opts.health = health
                        esp_opts.max_health = max_health
                        esp_opts.held_item = held_on and get_held_item_name(ent) or nil
                        esp_opts.held_item_color = ent_rgb or settings.color("havoc_npc_held_item", { 1, 0.85, 0.4, 1 })
                        esp_opts.npc_type = get_npc_type(name_str)

                        draw_util.draw_esp({ x = sc.x, y = sc.y, w = sc.w, h = sc.h, valid = true }, name_str, dist, esp_opts)
                    end
                end
            end
        end
    end
end

return M

end)()

-- ── features/visuals/loot_esp.lua ──
July._mods["features.visuals.loot_esp"] = (function()
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")
local loot_catalog = July.require("game.loot_catalog")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val)
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

function M.render(cam_pos)
    if not settings.enabled("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    if #loot_cache == 0 then return end

    local type_vals = settings.get("havoc_loot_types", {})
    local show_dist = settings.bool("havoc_loot_distance", false)
    local dist_pos = settings.num("havoc_loot_distance_pos", 0)
    local show_marker = settings.bool("havoc_loot_marker", false)
    local max_dist = settings.num("havoc_loot_max_distance", 5000)
    local filter_idx = settings.num("havoc_loot_filter", 0)
    local text_size = settings.num("havoc_loot_text_size", 13)
    local loot_rgb = settings.bool("havoc_loot_rainbow", false) and color_util.rainbow_color(0.3) or nil

    for i = 1, #loot_cache do
        local loot = loot_cache[i]

        if loot.pos and loot_catalog.is_enabled(type_vals, loot.category) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked) then
                local dist = (cam_pos - loot.pos).Magnitude
                if dist <= max_dist then
                    local sx, sy, sok = utility.WorldToScreen(loot.pos.X, loot.pos.Y, loot.pos.Z)
                    if sok then
                        local color = loot_rgb or loot_catalog.get_color(loot.category)
                        draw_util.draw_loot_label(sx, sy, loot.category.display, loot.is_locked, dist, show_dist, color,
                            dist_pos, show_marker, text_size)
                    end
                end
            end
        end
    end
end

return M

end)()

-- ── features/visuals/trap_esp.lua ──
July._mods["features.visuals.trap_esp"] = (function()
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local trap_scan = July.require("game.trap_scan")
local trap_types = July.require("game.trap_types")

local M = {}

function M.render(cam_pos)
    if not settings.enabled("havoc_trap_enabled") then return end

    local trap_cache = trap_scan.get_cache()
    if #trap_cache == 0 then return end

    local type_vals = settings.get("havoc_trap_types", {})
    local max_dist = settings.num("havoc_trap_max_distance", 3000)
    local text_size = settings.num("havoc_trap_text_size", 13)
    local trap_rgb = settings.bool("havoc_trap_rainbow", false) and color_util.rainbow_color(0.35) or nil

    for i = 1, #trap_cache do
        local trap = trap_cache[i]

        if not trap_types.is_enabled(type_vals, trap.trap_type) then
            goto continue
        end

        local ok_pos, pos = pcall(function() return trap.root.Position end)
        if ok_pos and pos then
            local dist = (cam_pos - pos).Magnitude
            if dist <= max_dist then
                local color = trap_rgb or trap_types.get_color(trap.trap_type)

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

        ::continue::
    end
end

return M

end)()

-- ── features/visuals/aimbot_visuals.lua ──
July._mods["features.visuals.aimbot_visuals"] = (function()
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

end)()

-- ── features/visuals/silent_visuals.lua ──
July._mods["features.visuals.silent_visuals"] = (function()
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

end)()

-- ── menu/tabs.lua ──
July._mods["menu.tabs"] = (function()
local constants = July.require("core.constants")
local settings = July.require("core.settings")
local menu_defs = July.require("menu.menu_defs")
local config = July.require("features.utility.config")
local entity_scan = July.require("game.entity_scan")
local loot_scan = July.require("game.loot_scan")
local trap_scan = July.require("game.trap_scan")
local weapon_mods = July.require("features.combat.weapon_mods")
local aimbot = July.require("features.combat.aimbot")
local silent_aim = July.require("features.combat.silent_aim")
local npc_esp = July.require("features.visuals.npc_esp")
local loot_esp = July.require("features.visuals.loot_esp")
local trap_esp = July.require("features.visuals.trap_esp")
local aimbot_visuals = July.require("features.visuals.aimbot_visuals")
local silent_visuals = July.require("features.visuals.silent_visuals")

local M = {}
M._menu_registered = false

local frame_counter = 0
local config_loaded = false
local aimbot_tick_counter = 0

function M.register_all()
    if M._menu_registered then return end
    menu_defs.register_all()
    config.register_menu()
    M._menu_registered = true
end

function M.init()
    M.register_all()
    return true
end

function M.update()
    if not config_loaded then
        config_loaded = true
        config.load()
    end

    frame_counter = frame_counter + 1
    npc_esp.set_frame_counter(frame_counter)

    if frame_counter % 3 == 1 then entity_scan.refresh() end
    if frame_counter % 15 == 1 then loot_scan.refresh() end
    if frame_counter % 8 == 1 then loot_scan.refresh_live() end
    if frame_counter % 20 == 1 then trap_scan.refresh() end
    if frame_counter % 30 == 1 then weapon_mods.apply() end

    local cam_pos = camera.GetPosition()

    npc_esp.render(cam_pos)
    loot_esp.render(cam_pos)
    trap_esp.render(cam_pos)
    aimbot_visuals.render()
    silent_visuals.render()

    if settings.enabled("havoc_aimbot_enabled") then
        aimbot_tick_counter = aimbot_tick_counter + 1
        if aimbot_tick_counter >= constants.AIMBOT_TICK_INTERVAL then
            aimbot_tick_counter = 0
            aimbot.tick()
        end
        silent_aim.tick()
    else
        aimbot_tick_counter = 0
        aimbot.reset()
        silent_aim.reset()
    end
end

return M

end)()

-- ── app.lua ──
July._mods["app"] = (function()
local tabs = July.require("menu.tabs")
local debug = July.require("core.debug")

local M = {}
local initialized = false

function M.init()
    if initialized then return true end
    initialized = tabs.init()
    return initialized
end

function M.on_frame()
    if not initialized then return end
    debug.guard("tabs.update", tabs.update)
end

return M

end)()

do
    July.require("menu.tabs").register_all()
end

July._init_ok = false

local ok, err = pcall(function()
    local debug = July.require("core.debug")
    local app = July.require("app")

    if not app.init() then
        debug.error_once("init", "app.init() returned false")
        return
    end

    July._init_ok = true

    if not debug.register_frame_hook(function()
        app.on_frame()
    end) then
        debug.error_once("init", "Failed to register on_frame")
        return
    end

    print("[July] v" .. (July.version or "?") .. " ready — open Scripts → July")
end)

if not ok then
    print("[July] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
end
