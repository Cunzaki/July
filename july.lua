--[[
    July — Havoc for Project Vector
    https://github.com/Cunzaki/July
    Built: 2026-07-08T01:31:29.843Z
]]

July = {
    version = "0.1.0",
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

-- ── menu/menu_defs.lua ──
July._mods["menu.menu_defs"] = (function()
local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")

local M = {}
M.TAB = constants.TAB

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB

    menu.AddTab(TAB, "J", "full")

    menu.AddGroup(TAB, "Aimbot", -1)

    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_enabled", "Enable NPC Aimbot", false, { key = 2, show_mode = false })
    menu.AddCombo(TAB, "Aimbot", "havoc_aimbot_bone", "Aimbot Bone", { "Head", "Torso" }, 0, { parent = "havoc_aimbot_enabled" })
    menu.AddCombo(TAB, "Aimbot", "havoc_aimbot_target_type", "Aimbot Target Type", { "Closest To Crosshair", "Closest Distance" }, 0,
        { parent = "havoc_aimbot_enabled" })

    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_draw_fov", "Field Of View Circle", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_fill_fov", "Fill FOV", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 0.15 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_target_line", "Target Line", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 0.3, 0.3, 1.0 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_rainbow", "Rainbow Colors", false,
        { parent = "havoc_aimbot_enabled" })

    menu.AddGroup(TAB, "NPC Visuals")

    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_enabled", "Enable NPC Visuals", false)
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_box", "Enable NPC Box", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCombo(TAB, "NPC Visuals", "havoc_npc_box_style", "Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_box_fill", "Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_name", "Enable NPC Name", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_distance", "Enable NPC Distance", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_held_item", "Enable Held Item", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_npc_type", "Show NPC Type Tag", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_health_bar", "Enable NPC Health Bar", false, { parent = "havoc_npc_enabled" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_health_text", "Enable NPC Health Text", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_chams", "Enable NPC Chams", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.AddCombo(TAB, "NPC Visuals", "havoc_npc_chams_style", "Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_skeleton", "Enable NPC Skeleton", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_hide_dead", "Hide Dead NPCs", false, { parent = "havoc_npc_enabled" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_rainbow", "Rainbow Colors", false,
        { parent = "havoc_npc_enabled" })

    menu.AddGroup(TAB, "Weapon Mods", 0, true)

    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_recoil", "Enable No Recoil", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_spread", "Enable No Spread", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_sway", "Enable No Sway", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_fast_vel", "Enable Fast Bullet Velocity", false)

    menu.AddGroup(TAB, "Trap Visuals")

    menu.AddCheckbox(TAB, "Trap Visuals", "havoc_trap_enabled", "Enable Trap Visuals", false, { colorpicker = { 1.0, 0.2, 0.0, 1.0 } })
    menu.AddCheckbox(TAB, "Trap Visuals", "havoc_trap_rainbow", "Rainbow Colors", false,
        { parent = "havoc_trap_enabled" })

    menu.AddGroup(TAB, "Sliders", 0, true)

    menu.AddSliderInt(TAB, "Sliders", "havoc_aimbot_fov", "Aimbot Field Of View", 10, 500, 150)
    menu.AddSliderInt(TAB, "Sliders", "havoc_aimbot_max_distance", "Aimbot Max Distance", 0, 3000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_max_distance", "NPC Max Render Distance", 0, 3000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_trap_max_distance", "Trap Max Render Distance", 0, 5000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_loot_max_distance", "Loot Max Render Distance", 0, 5000, 5000)
    menu.AddSeparator(TAB, "Sliders")
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_name_size", "NPC Name Text Size", 6, 24, 13)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_health_text_size", "NPC Health Text Size", 6, 18, 8)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_held_item_size", "NPC Weapon Text Size", 6, 18, 10)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_distance_size", "NPC Distance Text Size", 6, 18, 10)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_npc_type_size", "NPC Type Tag Text Size", 6, 18, 9)
    menu.AddSliderInt(TAB, "Sliders", "havoc_loot_text_size", "Loot Text Size", 1, 15, 13)
    menu.AddSliderInt(TAB, "Sliders", "havoc_trap_text_size", "Trap Text Size", 6, 18, 13)

    menu.AddGroup(TAB, "Loot Visuals", -1)

    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_enabled", "Enable Loot Visuals", false, { colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    for i = 1, #loot_catalog.LOOT_TYPES do
        local entry = loot_catalog.LOOT_TYPES[i]
        menu.AddCheckbox(TAB, "Loot Visuals", entry.key, "Enable " .. entry.display .. " Visuals", false,
            { parent = "havoc_loot_enabled" })
    end
    menu.AddCheckbox(TAB, "Loot Visuals", loot_catalog.LOOT_FALLBACK.key, "Enable " .. loot_catalog.LOOT_FALLBACK.display .. " Visuals", false,
        { parent = "havoc_loot_enabled" })
    menu.AddCheckbox(TAB, "Loot Visuals", loot_catalog.BODY_BAG_TYPE.key, "Enable " .. loot_catalog.BODY_BAG_TYPE.display .. " Visuals", false,
        { parent = "havoc_loot_enabled" })

    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_distance", "Show Distance", false, { parent = "havoc_loot_enabled" })
    menu.AddCombo(TAB, "Loot Visuals", "havoc_loot_distance_pos", "Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0,
        { parent = "havoc_loot_distance" })
    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_marker", "Show Position Marker", false,
        { parent = "havoc_loot_enabled" })
    menu.AddCombo(TAB, "Loot Visuals", "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = "havoc_loot_enabled" })
    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_rainbow", "Rainbow Colors", false,
        { parent = "havoc_loot_enabled" })

    menu.AddGroup(TAB, "Config", -1)
end

return M

end)()

-- ── features/utility/config.lua ──
July._mods["features.utility.config"] = (function()
local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local menu_defs = July.require("menu.menu_defs")

local M = {}

M.CONFIG_IDS = {
    "havoc_aimbot_enabled", "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "havoc_aimbot_rainbow",
    "havoc_npc_enabled", "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill", "havoc_npc_name",
    "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_health_bar",
    "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_chams_style", "havoc_npc_skeleton",
    "havoc_npc_rainbow",
    "havoc_npc_hide_dead", "havoc_no_recoil", "havoc_no_spread",
    "havoc_no_sway", "havoc_fast_vel", "havoc_loot_enabled",
    "havoc_loot_rainbow",
    "havoc_loot_distance", "havoc_loot_marker",
    "havoc_aimbot_bone", "havoc_aimbot_target_type",
    "havoc_loot_distance_pos", "havoc_loot_filter",
    "havoc_aimbot_fov", "havoc_aimbot_max_distance",
    "havoc_npc_max_distance", "havoc_loot_max_distance", "havoc_loot_text_size",
}

M.CONFIG_COLOR_IDS = {
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "havoc_npc_box", "havoc_npc_box_fill", "havoc_npc_name", "havoc_npc_distance",
    "havoc_npc_held_item", "havoc_npc_health_text",
    "havoc_npc_chams", "havoc_npc_skeleton",
}

M.CONFIG_COLOR_IDS[#M.CONFIG_COLOR_IDS + 1] = "havoc_loot_enabled"
for i = 1, #loot_catalog.LOOT_TYPES do
    M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.LOOT_TYPES[i].key
end
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.LOOT_FALLBACK.key
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.BODY_BAG_TYPE.key
M.CONFIG_COLOR_IDS[#M.CONFIG_COLOR_IDS + 1] = "havoc_trap_enabled"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_enabled"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_max_distance"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_rainbow"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_text_size"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_npc_npc_type"

local function val_to_str(v)
    local t = type(v)
    if t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        return tostring(v)
    elseif t == "table" then
        return table.concat({ v[1], v[2], v[3], v[4] }, ",")
    end
    return tostring(v)
end

local function str_to_val(s)
    if s == "true" then return true end
    if s == "false" then return false end
    local n = tonumber(s)
    if n then return n end
    local r, g, b, a = s:match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
    if r then
        return { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }
    end
    return nil
end

function M.save()
    local lines = { "# values" }
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        local val = menu.Get(id)
        lines[#lines + 1] = id .. "=" .. val_to_str(val)
    end
    lines[#lines + 1] = "# colors"
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        local val = menu.GetColor(id)
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
    notify.Success("Config saved (" .. #M.CONFIG_IDS + #M.CONFIG_COLOR_IDS .. " values)")
end

function M.load()
    local f, err = io.open(constants.CONFIG_PATH, "r")
    if not f then
        notify.Warning("No config at " .. constants.CONFIG_PATH, "", 4)
        return
    end
    local content = f:read("*a")
    f:close()

    local values = {}
    local colors = {}
    local section = nil
    for line in content:gmatch("[^\r\n]+") do
        if line == "# values" then
            section = "values"
        elseif line == "# colors" then
            section = "colors"
        else
            local key, val_str = line:match("^([^=]+)=(.+)$")
            if key and val_str then
                if section == "colors" then
                    colors[key] = str_to_val(val_str)
                elseif section == "values" then
                    values[key] = str_to_val(val_str)
                end
            end
        end
    end

    local count = 0
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        if values[id] ~= nil then
            local ok = menu.Set and menu.Set(id, values[id])
            if ok ~= false then count = count + 1 end
        end
    end
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        if colors[id] ~= nil then
            local ok = menu.SetColor and menu.SetColor(id, colors[id])
            if ok ~= false then count = count + 1 end
        end
    end

    if count > 0 then
        notify.Success("Loaded " .. count .. " settings")
    else
        notify.Warning("Loaded but 0 settings applied — check if menu.Set/menu.SetColor exist", "", 6)
    end
end

function M.register_menu()
    local TAB = menu_defs.TAB
    menu.AddButton(TAB, "Config", "btn_save_config", "Save Config", M.save)
    menu.AddButton(TAB, "Config", "btn_load_config", "Load Config", M.load)
end

return M

end)()

-- ── features/combat/weapon_mods.lua ──
July._mods["features.combat.weapon_mods"] = (function()
local M = {}

function M.apply()
    local patches = {
        { id = "havoc_no_recoil", patch = { vPunchBase = 0, hPunchBase = 0 } },
        { id = "havoc_no_spread", patch = { spreadReduce = 100 } },
        { id = "havoc_no_sway", patch = { weight = 0, aimWeight = 0, unAimWeight = 0 } },
        { id = "havoc_fast_vel", patch = { vel = 100000 } },
    }
    for i = 1, #patches do
        if menu.Get(patches[i].id) then
            pcall(applygc, patches[i].patch)
        end
    end
end

return M

end)()

-- ── features/combat/aimbot.lua ──
July._mods["features.combat.aimbot"] = (function()
local constants = July.require("core.constants")
local entity_scan = July.require("game.entity_scan")

local M = {}

local aimbot_prev_target = nil
local aimbot_locked_ent = nil
local aimbot_next_acquire = 0

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

local function get_aim_part(ent, bone_idx)
    if bone_idx == 0 then
        return ent.parts["Head"] or ent.root
    else
        return ent.parts["Torso"] or ent.parts["UpperTorso"] or ent.root
    end
end

local function evaluate_candidate(ent, bone_idx, cam_pos, max_dist)
    local health = ent.humanoid.Health
    if not (health and health > 0) then return nil end

    local part = get_aim_part(ent, bone_idx)
    if not part then return nil end

    local pos = part.Position
    if not pos then return nil end

    local dist = (cam_pos - pos).Magnitude
    if max_dist > 0 and dist > max_dist then return nil end

    return pos, dist
end

function M.tick()
    local settings = {
        fov = menu.Get("havoc_aimbot_fov"),
        draw_fov = menu.Get("havoc_aimbot_draw_fov"),
        fill_fov = menu.Get("havoc_aimbot_fill_fov"),
        bone_idx = menu.Get("havoc_aimbot_bone"),
        target_type = menu.Get("havoc_aimbot_target_type"),
        max_dist = menu.Get("havoc_aimbot_max_distance"),
    }

    local scx, scy = input.GetScreenCenter()

    M.draw_state.scx = scx
    M.draw_state.scy = scy
    M.draw_state.fov = settings.fov
    M.draw_state.draw_fov = settings.draw_fov
    M.draw_state.fill_fov = settings.fill_fov

    local key = menu.GetKey("havoc_aimbot_enabled")
    if key == 0 then key = 2 end

    local now = utility.GetTime()
    local cam_pos = camera.GetPosition()
    local entity_cache = entity_scan.get_cache()

    local best_pos, best_model = nil, nil

    if aimbot_locked_ent and now < aimbot_next_acquire then
        local pos = evaluate_candidate(aimbot_locked_ent, settings.bone_idx, cam_pos, settings.max_dist)
        if pos then
            local sx, sy, svis = utility.WorldToScreen(pos.X, pos.Y, pos.Z)
            if svis then
                local dx, dy = sx - scx, sy - scy
                local px_dist = math.sqrt(dx * dx + dy * dy)
                if px_dist <= settings.fov then
                    best_pos = pos
                    best_model = aimbot_locked_ent.model
                end
            end
        end
    end

    if not best_pos then
        aimbot_next_acquire = now + constants.AIMBOT_ACQUIRE_INTERVAL

        local best_score = math.huge
        local best_ent = nil

        for i = 1, #entity_cache do
            local ent = entity_cache[i]
            local pos, dist = evaluate_candidate(ent, settings.bone_idx, cam_pos, settings.max_dist)
            if pos then
                local sx, sy, svis = utility.WorldToScreen(pos.X, pos.Y, pos.Z)
                if svis then
                    local dx, dy = sx - scx, sy - scy
                    local px_dist = math.sqrt(dx * dx + dy * dy)
                    if px_dist <= settings.fov then
                        local score = (settings.target_type == 1) and dist or px_dist
                        if score < best_score then
                            best_score = score
                            best_pos = pos
                            best_model = ent.model
                            best_ent = ent
                        end
                    end
                end
            end
        end

        aimbot_locked_ent = best_ent
    end

    aimbot_prev_target = best_model

    if best_pos then
        local fx, fy, fvis = utility.WorldToScreen(best_pos.X, best_pos.Y, best_pos.Z)
        if fvis then
            M.draw_state.active = true
            M.draw_state.tx = fx
            M.draw_state.ty = fy
        else
            M.draw_state.active = false
        end

        local aim_part = get_aim_part(aimbot_locked_ent, settings.bone_idx)
        camera.TrackTarget(aim_part, aimbot_locked_ent.humanoid, key, settings.max_dist)
    else
        M.draw_state.active = false
        camera.StopTracking()
    end
end

function M.reset()
    aimbot_prev_target = nil
    aimbot_locked_ent = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    camera.StopTracking()
end

return M

end)()

-- ── features/visuals/npc_esp.lua ──
July._mods["features.visuals.npc_esp"] = (function()
local constants = July.require("core.constants")
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local entity_scan = July.require("game.entity_scan")

local M = {}

local frame_counter = 0

function M.set_frame_counter(n)
    frame_counter = n
end

local function get_npc_type(entity_name)
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
    if not menu.Get("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    if #entity_cache == 0 then return end

    local ent_rgb = menu.Get("havoc_npc_rainbow") and color_util.rainbow_color(0.4) or nil

    local opts = {
        box = menu.Get("havoc_npc_box"),
        box_style = menu.Get("havoc_npc_box_style"),
        box_color = ent_rgb or menu.GetColor("havoc_npc_box"),
        box_fill = menu.Get("havoc_npc_box_fill"),
        box_fill_color = ent_rgb or menu.GetColor("havoc_npc_box_fill"),
        name = menu.Get("havoc_npc_name"),
        name_color = ent_rgb or menu.GetColor("havoc_npc_name"),
        dist = menu.Get("havoc_npc_distance"),
        dist_color = ent_rgb or menu.GetColor("havoc_npc_distance"),
        health_bar = menu.Get("havoc_npc_health_bar"),
        health_text = menu.Get("havoc_npc_health_text"),
        health_text_color = ent_rgb or menu.GetColor("havoc_npc_health_text"),
    }

    local chams_on = menu.Get("havoc_npc_chams")
    local chams_color = ent_rgb or menu.GetColor("havoc_npc_chams")
    local skeleton_on = menu.Get("havoc_npc_skeleton")
    local skeleton_color = ent_rgb or menu.GetColor("havoc_npc_skeleton")
    local held_item_on = menu.Get("havoc_npc_held_item")
    local held_item_color = ent_rgb or menu.GetColor("havoc_npc_held_item")
    local npc_type_on = menu.Get("havoc_npc_npc_type")
    local npc_type_color = ent_rgb or menu.GetColor("havoc_npc_npc_type")
    local name_size = menu.Get("havoc_npc_name_size")
    local health_text_size = menu.Get("havoc_npc_health_text_size")
    local held_item_size = menu.Get("havoc_npc_held_item_size")
    local dist_size = menu.Get("havoc_npc_distance_size")
    local npc_type_size = menu.Get("havoc_npc_npc_type_size")

    local hide_dead = menu.Get("havoc_npc_hide_dead")
    local max_dist = menu.Get("havoc_npc_max_distance")

    local needs_full_bounds = opts.box and opts.box_style == 2
    local chams_style = menu.Get("havoc_npc_chams_style")

    local esp_opts = {
        box = needs_full_bounds and false or opts.box,
        box_style = opts.box_style,
        box_color = opts.box_color,
        box_fill = opts.box_fill,
        box_fill_color = opts.box_fill_color,
        name = opts.name,
        name_color = opts.name_color,
        dist = opts.dist,
        dist_color = opts.dist_color,
        health_bar = opts.health_bar,
        health_text = opts.health_text,
        health_text_color = opts.health_text_color,
        npc_type_on = npc_type_on,
        npc_type_color = npc_type_color,
        name_size = name_size or 13,
        health_text_size = health_text_size or 8,
        held_item_size = held_item_size or 10,
        dist_size = dist_size or 10,
        npc_type_size = npc_type_size or 9,
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
                    local do_update = (frame_counter + i) % constants.BOUNDS_UPDATE_INTERVAL == 0

                    if needs_full_bounds or chams_on or skeleton_on then
                        local part_pos = {}
                        for name, part in pairs(ent.parts) do
                            local pos = part.Position
                            if pos then part_pos[name] = pos end
                        end
                        local bounds = draw_util.get_entity_bounds(part_pos, ent.part_size, root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                        if chams_on and bounds.valid then draw_util.draw_entity_chams(part_pos, ent.part_size, chams_color, chams_style) end
                        if skeleton_on and bounds.valid then draw_util.draw_entity_skeleton(part_pos, skeleton_color) end
                        if needs_full_bounds and bounds.valid then draw_util.draw_entity_3d_box(part_pos, ent.part_size, opts.box_color) end
                    elseif do_update then
                        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
                        sc.x = bounds.x; sc.y = bounds.y; sc.w = bounds.w; sc.h = bounds.h; sc.valid = bounds.valid
                    end

                    if sc.valid then
                        local name_str = ent.model.Name
                        esp_opts.health = health
                        esp_opts.max_health = max_health
                        esp_opts.held_item = held_item_on and get_held_item_name(ent) or nil
                        esp_opts.held_item_color = held_item_color
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
local color_util = July.require("core.color_util")
local draw_util = July.require("core.draw_util")
local loot_scan = July.require("game.loot_scan")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val)
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

function M.render(cam_pos)
    if not menu.Get("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    if #loot_cache == 0 then return end

    local show_dist = menu.Get("havoc_loot_distance")
    local dist_pos = menu.Get("havoc_loot_distance_pos")
    local show_marker = menu.Get("havoc_loot_marker")
    local max_dist = menu.Get("havoc_loot_max_distance")
    local filter_idx = menu.Get("havoc_loot_filter")
    local text_size = menu.Get("havoc_loot_text_size")
    local loot_rgb = menu.Get("havoc_loot_rainbow") and color_util.rainbow_color(0.3) or nil
    local group_color = menu.GetColor("havoc_loot_enabled")

    for i = 1, #loot_cache do
        local loot = loot_cache[i]

        if loot.pos and menu.Get(loot.category.key) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked) then
                local dist = (cam_pos - loot.pos).Magnitude
                if dist <= max_dist then
                    local sx, sy, sok = utility.WorldToScreen(loot.pos.X, loot.pos.Y, loot.pos.Z)
                    if sok then
                        local color = loot_rgb or group_color
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

end)()

-- ── features/visuals/aimbot_visuals.lua ──
July._mods["features.visuals.aimbot_visuals"] = (function()
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

end)()

-- ── menu/tabs.lua ──
July._mods["menu.tabs"] = (function()
local constants = July.require("core.constants")
local menu_defs = July.require("menu.menu_defs")
local config = July.require("features.utility.config")
local entity_scan = July.require("game.entity_scan")
local loot_scan = July.require("game.loot_scan")
local trap_scan = July.require("game.trap_scan")
local weapon_mods = July.require("features.combat.weapon_mods")
local aimbot = July.require("features.combat.aimbot")
local npc_esp = July.require("features.visuals.npc_esp")
local loot_esp = July.require("features.visuals.loot_esp")
local trap_esp = July.require("features.visuals.trap_esp")
local aimbot_visuals = July.require("features.visuals.aimbot_visuals")

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

    local aimbot_enabled = menu.Get("havoc_aimbot_enabled")
    if aimbot_enabled then
        aimbot_tick_counter = aimbot_tick_counter + 1
        if aimbot_tick_counter >= constants.AIMBOT_TICK_INTERVAL then
            aimbot_tick_counter = 0
            aimbot.tick()
        end
    else
        aimbot_tick_counter = 0
        aimbot.reset()
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
