--[[
    July - Havoc for Project Vector
    https://github.com/Cunzaki/July
    Built: 2026-07-08T06:34:13.460Z
]]

July = {
    version = "0.8.4",
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
M.SCAN_YIELD_EVERY = 24
M.SCAN_BUDGET_MS = 4
M.ENTITY_SCAN_INTERVAL = 1.0
M.ENTITY_LIVE_BATCH_SIZE = 20
M.NPC_BOUNDS_BATCH = 8
M.NPC_CHAMS_BUDGET = 6
M.FOLDER_POLL_INTERVAL = 0.25
M.PLAYER_MATCH_DIST = 5.0

M.LOOT_SCAN_INTERVAL = 30.0
M.LOOT_SCAN_DEPTH = 8
M.LOOT_LIVE_BATCH_SIZE = 60
M.DROP_SCAN_DEPTH = 8
M.DROP_SCAN_INTERVAL = 1.0
M.TRAP_LIVE_BATCH = 10

M.TRAP_SCAN_DEPTH = 8
M.TRAP_SCAN_INTERVAL = 5.0

M.AIMBOT_ACQUIRE_INTERVAL = 0.05
M.AIMBOT_TICK_INTERVAL = 1

M.LOOT_MARKER_RADIUS = 3
M.LOOT_MARKER_GAP = 8

M.ESP_HIDE_SQ = 9
M.ESP_RENDER_BUDGET = 100
M.ESP_POS_CACHE_MS = 120
M.ESP_POS_CACHE_COMBAT_MS = 50

M.SKELETON_OUTLINE_COLOR = { 0, 0, 0, 0.78 }

M.NPC_BOSS_NAMES = {
    Boris = true, Bruno = true, Brutus = true, Tagilla = true,
    Ranger = true, Clutch = true, Kodiak = true, Vandal = true, Grizzly = true,
    Crossfire = true, Warlock = true, Stalemate = true, Lynx = true, Hawk = true,
    Talon = true, Volt = true, Dagger = true, Spartan = true, Cipher = true,
    Maverick = true, Falcon = true,
    Scorch = true, Raptor = true, Knox = true, Fox = true, Bullet = true,
    Zero = true, Cobra = true, Ghost = true, Shade = true, Checkmate = true,
    Mamba = true, Phoenix = true, Anvil = true, Gunner = true,
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

local _callbacks = {}

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
    local ok, fb = pcall(function()
        return July.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(id) then
        return fb.active(id)
    end

    if not menu then return false end
    local v = M.get(id, false)
    if v == nil or v == false or v == 0 or v == "false" then return false end
    return v == true or v == 1
end

function M.num(id, default)
    return tonumber(M.get(id, default)) or default or 0
end

function M.combo_index(id, labels, default)
    default = default or 0
    local v = M.get(id, default)
    if type(v) == "string" then
        local lower = v:lower()
        for i, label in ipairs(labels or {}) do
            if label:lower() == lower then return i - 1 end
        end
        return default
    end
    local n = tonumber(v)
    if n == nil then return default end
    return n
end

function M.color(id, default)
    default = default or { 1, 1, 1, 1 }
    local color_util = July.require("core.color_util")

    if menu and menu.get_color then
        local c = menu.get_color(id)
        if c then return color_util.normalize_rgba(c, default) end
    end
    if menu and menu.GetColor then
        local c = menu.GetColor(id)
        if c then return color_util.normalize_rgba(c, default) end
    end
    return color_util.normalize_rgba(default, { 1, 1, 1, 1 })
end

function M.multicombo_get(id, index, default)
    local vals = M.get(id, nil)
    if type(vals) ~= "table" then return default end
    local v = vals[index]
    if v == nil then return default end
    return v == true
end

function M.on_change(id, fn)
    if not id or not fn then return end
    _callbacks[id] = _callbacks[id] or {}
    _callbacks[id][#_callbacks[id] + 1] = fn
    if menu and menu.set_callback then
        menu.set_callback(id, function(new_val)
            for _, cb in ipairs(_callbacks[id] or {}) do
                pcall(cb, new_val)
            end
        end)
    end
end

return M

end)()

-- ── core/cache.lua ──
July._mods["core.cache"] = (function()
local constants = July.require("core.constants")

local M = {}

M.WORKSPACE_SCAN_MS = 1000
M.POS_CACHE_MS = 250
M._last_pos_cache = 0

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.should_refresh_positions(combat_active)
    local interval = combat_active and constants.ESP_POS_CACHE_COMBAT_MS or M.POS_CACHE_MS
    local now = tick_ms()
    if now - M._last_pos_cache >= interval then
        M._last_pos_cache = now
        return true
    end
    return false
end

function M.reset()
    M._last_pos_cache = 0
end

return M

end)()

-- ── core/session.lua ──
July._mods["core.session"] = (function()
local env = July.require("core.env")
local cache = July.require("core.cache")

local M = {}

M._ready = false
M._last_char_key = nil
M._last_folder_name = nil

local function char_key(lp)
    if not lp then return nil end
    local char = lp.Character or lp.character
    if not char then return nil end
    if not env.is_valid(char) then return nil end
    local addr = char.Address or char.address
    if addr then return tostring(addr) end
    return tostring(char)
end

function M.invalidate_all()
    cache.reset()

    July.require("game.havoc_sync").reset()
    July.require("game.entity_scan").invalidate()
    July.require("game.loot_scan").invalidate()
    July.require("game.trap_scan").invalidate()
    July.require("core.silent_ray").reset_session()
    July.require("features.combat.aimbot").reset()
    July.require("features.combat.silent_aim").reset()
    July.require("game.combat_origin").invalidate()

    local gc = July.require("game.gc_weapon_mods")
    if gc.available() then
        pcall(gc.warm)
    end
end

function M.tick()
    local lp = env.get_local_player()
    local char_key = char_key(lp)
    local folder_name = July.require("game.havoc_sync").get_folder_name()

    if M._ready then
        local changed = false
        if char_key ~= M._last_char_key then
            changed = true
        end
        if folder_name and M._last_folder_name and folder_name ~= M._last_folder_name then
            changed = true
        end
        if changed then
            M.invalidate_all()
        end
    end

    if char_key then
        M._ready = true
        M._last_char_key = char_key
    end
    if folder_name then
        M._last_folder_name = folder_name
    end
end

return M

end)()

-- ── core/feature_bind.lua ──
July._mods["core.feature_bind"] = (function()
--[[ Toggle / Hold keybind polling — April Fallen pattern for Vector menu checkboxes. ]]

local settings = July.require("core.settings")

local M = {}

M.MODES = { "Toggle", "Hold" }

local registry = {}
local last_down = {}

function M.register(spec)
    if not spec or not spec.id then return end
    registry[spec.id] = {
        id = spec.id,
        mode_id = spec.mode_id or (spec.id .. "_mode"),
        key_id = spec.key_id or spec.id,
    }
end

function M.is_registered(id)
    return registry[id] ~= nil
end

function M.get_key(id)
    local e = registry[id]
    local key_id = e and e.key_id or id
    if menu and menu.get_key then
        local k = menu.get_key(key_id)
        if k and k > 0 then return k end
    end
    return 0
end

function M.is_hold(id)
    local e = registry[id]
    if not e then return false end
    return settings.combo_index(e.mode_id, M.MODES, 0) == 1
end

function M.armed(id)
    return settings.bool(id, false)
end

function M.active(id)
    if not registry[id] then
        return settings.bool(id, false)
    end

    if M.is_hold(id) then
        if not M.armed(id) then return false end
        local key = M.get_key(id)
        if key <= 0 then return false end
        return input and input.is_key_down and input.is_key_down(key)
    end

    return M.armed(id)
end

function M.tick()
    if not input or not input.is_key_down then return end

    for id in pairs(registry) do
        if M.is_hold(id) then
            last_down[id] = input.is_key_down(M.get_key(id))
        else
            local key = M.get_key(id)
            if key > 0 then
                local down = input.is_key_down(key)
                if down and not last_down[id] then
                    local cur = settings.bool(id, false)
                    if menu and menu.set then
                        pcall(menu.set, id, not cur)
                    end
                end
                last_down[id] = down
            end
        end
    end
end

return M

end)()

-- ── core/menu_util.lua ──
July._mods["core.menu_util"] = (function()
--[[
    Vector full-mode grid (April/June pattern):
      menu.add_group(tab, name)           -> left column, new row
      menu.add_group(tab, name, 0, true)  -> right column, same row
]]

local M = {}

M.TAB = "July"

M.G = {
    AIMBOT = "Aimbot",
    SILENT = "Silent Aim",
    NPC = "NPC Visuals",
    WORLD = "World Visuals",
    WEAPON = "Weapon Mods",
    CONFIG = "Config",
}

M._tab_ready = false
M._groups_ready = false
M._groups = {}
M._master_children = {}
M._master_hooked = {}

local function settings_mod()
    return July.require("core.settings")
end

function M.ensure_tab()
    if M._tab_ready then return end
    if not (July and July._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "J", "full")
    end
    M._tab_ready = true
end

function M.ensure_groups()
    if M._groups_ready then return end
    M.ensure_tab()

    local rows = {
        { M.G.AIMBOT, M.G.SILENT },
        { M.G.NPC, M.G.WORLD },
        { M.G.WEAPON, M.G.CONFIG },
    }

    for _, row in ipairs(rows) do
        menu.add_group(M.TAB, row[1])
        M._groups[row[1]] = true
        if row[2] then
            menu.add_group(M.TAB, row[2], 0, true)
            M._groups[row[2]] = true
        end
    end

    M._groups_ready = true
end

function M.parent(main_id, extra)
    local opts = { parent = main_id }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            opts[k] = v
        end
    end
    return opts
end

local function add_child_ids(bucket, ids)
    bucket = bucket or {}
    local seen = {}
    for _, id in ipairs(bucket) do
        seen[id] = true
    end
    for _, id in ipairs(ids or {}) do
        if id and not seen[id] then
            seen[id] = true
            bucket[#bucket + 1] = id
        end
    end
    return bucket
end

local function set_visible(id, show)
    if menu and menu.set_visible and id then
        pcall(menu.set_visible, id, show)
    end
end

local function master_visible(master_id)
    local ok, fb = pcall(function()
        return July.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(master_id) then
        return fb.active(master_id)
    end
    return settings_mod().bool(master_id, false)
end

function M.sync_masters()
    for master_id in pairs(M._master_hooked) do
        local show = master_visible(master_id)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end
end

M.COLOR_DEFAULTS = {
    havoc_aimbot_draw_fov = { 1.0, 1.0, 1.0, 1.0 },
    havoc_aimbot_fill_fov = { 1.0, 1.0, 1.0, 0.15 },
    havoc_aimbot_target_line = { 1.0, 0.3, 0.3, 1.0 },
    july_silent_draw_fov = { 0.55, 0.2, 1.0, 1.0 },
    july_silent_target_line = { 1.0, 0.25, 0.25, 1.0 },
    july_silent_tp_ray_vis = { 0.95, 0.45, 1.0, 0.9 },
    havoc_npc_box = { 1.0, 1.0, 1.0, 1.0 },
    havoc_npc_box_fill = { 1.0, 1.0, 1.0, 0.35 },
    havoc_npc_name = { 0.92, 0.92, 0.92, 1.0 },
    havoc_npc_distance = { 0.67, 0.67, 0.67, 1.0 },
    havoc_npc_held_item = { 1.0, 0.85, 0.4, 1.0 },
    havoc_npc_npc_type = { 1.0, 0.5, 0.0, 0.85 },
    havoc_npc_health_text = { 0.3, 1.0, 0.4, 1.0 },
    havoc_npc_chams = { 1.0, 0.2, 0.2, 0.55 },
    havoc_npc_skeleton = { 1.0, 1.0, 1.0, 1.0 },
    havoc_loot_box = { 1.0, 1.0, 1.0, 1.0 },
    havoc_trap_box = { 1.0, 0.35, 0.25, 1.0 },
}

function M.seed_color_defaults()
    if not menu or not menu.set_color then return end

    local color_util = July.require("core.color_util")
    for id, default in pairs(M.COLOR_DEFAULTS) do
        local cur = menu.get_color and menu.get_color(id) or nil
        local normalized = color_util.normalize_rgba(cur, default)
        local r, g, b = normalized[1], normalized[2], normalized[3]
        if not cur or (r + g + b) < 0.04 then
            pcall(menu.set_color, id, default)
        end
    end
end

function M.bind_children(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    if M._master_hooked[master_id] then return end
    M._master_hooked[master_id] = true

    local function sync(new_val)
        local show
        if new_val == nil then
            show = master_visible(master_id)
        else
            show = new_val == true or new_val == 1
        end
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end

    settings_mod().on_change(master_id, sync)
    sync()
end

function M.register_keybind(T, G, id, label, default, extra)
    extra = extra or {}
    local cb_opts = { show_mode = false, key = extra.key or 0 }
    if extra.parent then cb_opts.parent = extra.parent end
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, id, label, default or false, cb_opts)

    local mode_id = id .. "_mode"
    local root = M.parent(id)
    menu.add_combo(T, G, mode_id, label .. " Mode", { "Toggle", "Hold" }, 0, root)

    July.require("core.feature_bind").register({
        id = id,
        mode_id = mode_id,
        key_id = id,
    })

    return mode_id
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

function M.screen_fov_dist_sq(sx, sy, cx, cy)
    local dx, dy = sx - cx, sy - cy
    return dx * dx + dy * dy
end

function M.screen_fov_dist(sx, sy, cx, cy)
    return math.sqrt(M.screen_fov_dist_sq(sx, sy, cx, cy))
end

return M

end)()

-- ── core/color_util.lua ──
July._mods["core.color_util"] = (function()
local M = {}

function M.normalize_rgba(c, fallback)
    fallback = fallback or { 1, 1, 1, 1 }
    if type(c) ~= "table" then return fallback end

    local r = tonumber(c[1] or c.r) or 0
    local g = tonumber(c[2] or c.g) or 0
    local b = tonumber(c[3] or c.b) or 0
    local a = tonumber(c[4] or c.a)
    if a == nil then a = 1 end

    if r > 1 or g > 1 or b > 1 or a > 1 then
        r, g, b, a = r / 255, g / 255, b / 255, a / 255
    end

    r = math.max(0, math.min(1, r))
    g = math.max(0, math.min(1, g))
    b = math.max(0, math.min(1, b))
    a = math.max(0, math.min(1, a))

    if (r + g + b) < 0.04 and fallback then
        return M.normalize_rgba(fallback, { 1, 1, 1, 1 })
    end

    return { r, g, b, a }
end

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
        if coroutine.running() then
            coroutine.yield()
        elseif sleep then
            sleep(0)
        end
    end
end

return M

end)()

-- ── core/scan_async.lua ──
July._mods["core.scan_async"] = (function()
local M = {}

function M.tick(co, budget_ms)
    if not co or coroutine.status(co) == "dead" then
        return true
    end

    budget_ms = budget_ms or 4
    local t0 = os.clock()

    while coroutine.status(co) ~= "dead" do
        local ok = coroutine.resume(co)
        if not ok then
            return true
        end
        if (os.clock() - t0) * 1000 >= budget_ms then
            return false
        end
    end

    return true
end

return M

end)()

-- ── core/draw_util.lua ──
July._mods["core.draw_util"] = (function()
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

-- ── core/image_cache.lua ──
July._mods["core.image_cache"] = (function()
local asset_urls = July.require("game.asset_urls")

local M = {}

local keys = {}

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" and asset_id_or_url:find("https://", 1, true) then
        return asset_id_or_url
    end
    return asset_urls.item_png(asset_id_or_url) or asset_urls.roblox_thumb(asset_id_or_url)
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    local asset_id = type(asset_id_or_url) == "number" and asset_id_or_url
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    keys[key] = {
        url = url,
        asset_id = asset_id and tostring(asset_id) or nil,
        handle = nil,
        failed = false,
        fallback = false,
    }
    return keys[key]
end

local function try_fallback(entry)
    if entry.fallback or not entry.asset_id then return false end
    local fb = asset_urls.roblox_thumb(entry.asset_id)
    if not fb or fb == entry.url then return false end
    entry.fallback = true
    entry.url = fb
    entry.handle = nil
    entry.failed = false
    return true
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if not entry.handle then
        entry.handle = draw.load_image(entry.url)
        return nil
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return nil
        end
        entry.failed = true
        entry.handle = nil
        return nil
    end

    return entry.handle
end

local function draw_image(handle, x, y, w, h, col)
    if col and type(col) == "table" then
        local r = math.floor((col[1] or 1) * 255)
        local g = math.floor((col[2] or 1) * 255)
        local b = math.floor((col[3] or 1) * 255)
        local a = math.floor((col[4] or 1) * 255)
        draw.image(handle, x, y, w, h, r, g, b, a)
    else
        draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    end
end

function M.draw_fit(key, x, y, w, h, col)
    if not draw or not draw.image then return false end
    local handle = get_handle(key)
    if not handle then return false end
    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    draw_image(handle, x, y, w, h, col)
    return true
end

function M.begin_load(key)
    if not key then return end
    get_handle(key)
end

return M

end)()

-- ── core/world_vis.lua ──
July._mods["core.world_vis"] = (function()
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
    if camera and camera.get_position then
        local ok, pos = pcall(camera.get_position)
        if ok and pos then
            local x, y, z = unpack_pos(pos)
            if x then return { x = x, y = y, z = z } end
        end
    end
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then
            local x, y, z = unpack_pos(pos)
            if x then return { x = x, y = y, z = z } end
        end
    end

    local env = July and July.require and July.require("core.env") or nil
    local ws = env and env.get_workspace and env.get_workspace() or nil
    if ws then
        local cam = env.safe_call(function()
            if ws.FindFirstChild then return ws:FindFirstChild("Camera") end
            return nil
        end)
        if cam and cam.CFrame and cam.CFrame.Position then
            local pos = cam.CFrame.Position
            return { x = pos.X, y = pos.Y, z = pos.Z }
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

function M.reset_session()
    hook_ready = false
    M.stop()
end

--[[
    opts:
      keys = { 0x01, 0x02 }  mouse buttons for track_silent_target
      always = true          also set_silent_target every frame (always-on silent)
]]
function M.track(origin, aim_point, opts)
    M._last_ok = false
    if not aim_point then return false end

    origin = origin or M.get_camera_origin()
    if not origin then return false end
    if not M.ensure_hook() then return false end

    opts = opts or {}
    local keys = opts.keys
    if not keys then
        keys = { opts.track_key or opts.key or 0x01 }
    end

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

    M._last_origin = { x = ox, y = oy, z = oz }
    M._last_target = { x = ax, y = ay, z = az }

    local ok = false

    if opts.always and raycast.set_silent_target then
        pcall(raycast.set_silent_target, origin_v, dir)
        ok = true
    end

    local should_track = opts.shooting == true
    if should_track then
        for i = 1, #keys do
            if raycast.track_silent_target then
                local tracked = raycast.track_silent_target(origin_v, dir, keys[i]) == true
                ok = ok or tracked
            end
        end
    end

    M._last_ok = ok
    tracking = ok
    return ok
end

return M

end)()

-- ── core/manip_math.lua ──
July._mods["core.manip_math"] = (function()
local M = {}

local DEFAULT_STEPS = 12
local MIN_RADIUS = 0.1
local MAX_RADIUS = 5
local CACHE_MS = 200

local cache = {
    key = nil,
    result = nil,
    time = 0,
}

function M.eye_offset_y()
    return 0
end

function M.clamp_radius(radius)
    radius = tonumber(radius) or 1
    if radius < MIN_RADIUS then return MIN_RADIUS end
    if radius > MAX_RADIUS then return MAX_RADIUS end
    return math.floor(radius * 100 + 0.5) / 100
end

local function now_ms()
    if utility and utility.get_tick_count then
        return utility.get_tick_count()
    end
    return os.clock() * 1000
end

local function cache_key(origin, target_pos, max_radius)
    return string.format(
        "%.0f_%.0f_%.0f_%.0f_%.0f_%.0f_%.1f",
        origin.x, origin.y, origin.z,
        target_pos.x, target_pos.y, target_pos.z,
        max_radius or 1
    )
end

local function ray_ready()
    if not raycast then return false end
    if not raycast.is_ready then return true end
    return raycast.is_ready() == true
end

local function is_visible_from(ox, oy, oz, tx, ty, tz)
    if not raycast then return true end
    if not ray_ready() then return true end

    if raycast.is_visible and raycast.is_visible(ox, oy, oz, tx, ty, tz) == true then
        return true
    end

    if raycast.cast then
        local dx, dy, dz = tx - ox, ty - oy, tz - oz
        local len = math.sqrt(dx * dx + dy * dy + dz * dz)
        if len < 0.05 then return true end
        local hit, _, dist = raycast.cast(ox, oy, oz, tx, ty, tz)
        if not hit then return true end
        if dist and dist >= len - 1.5 then return true end
        return false
    end

    return true
end

function M.is_visible_from_pos(origin, target)
    if not origin or not target then return false end
    return is_visible_from(origin.x, origin.y, origin.z, target.x, target.y, target.z)
end

local function any_origin_visible(origins, target_pos)
    for i = 1, #origins do
        local o = origins[i]
        if o and M.is_visible_from_pos(o, target_pos) then
            return true
        end
    end
    return false
end

local function search_peek(origin, target_pos, max_radius, steps)
    max_radius = M.clamp_radius(max_radius)
    steps = steps or DEFAULT_STEPS

    for i = 0, steps - 1 do
        local angle = (i / steps) * math.pi * 2
        local cx = origin.x + math.cos(angle) * max_radius
        local cy = origin.y
        local cz = origin.z + math.sin(angle) * max_radius
        if is_visible_from(cx, cy, cz, target_pos.x, target_pos.y, target_pos.z) then
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

    local max_r = M.clamp_radius(opts.max_radius)
    if not opts.force then
        local key = cache_key(origin, target_pos, max_r)
        local t = now_ms()
        if cache.key == key and (t - cache.time) < CACHE_MS then
            return cache.result
        end
    end

    local result
    local origins = { origin }
    if opts.alt_origins then
        for i = 1, #opts.alt_origins do
            origins[#origins + 1] = opts.alt_origins[i]
        end
    end

    if any_origin_visible(origins, target_pos) then
        result = { state = "direct", peek = nil, radius = max_r }
    else
        local peek, radius = search_peek(origin, target_pos, max_r, opts.steps or DEFAULT_STEPS)
        if peek then
            result = { state = "ready", peek = peek, radius = radius }
        else
            result = { state = "blocked", peek = nil, radius = max_r }
        end
    end

    if not opts.force then
        cache.key = cache_key(origin, target_pos, max_r)
        cache.result = result
        cache.time = now_ms()
    end

    return result
end

function M.peek_track_origin(peek)
    if not peek then return nil end
    return { x = peek.x, y = peek.y, z = peek.z }
end

function M.ring_y(origin)
    if not origin then return 0 end
    return origin.y
end

function M.invalidate_cache()
    cache.key = nil
    cache.result = nil
    cache.time = 0
end

return M

end)()

-- ── core/ballistic.lua ──
July._mods["core.ballistic"] = (function()
local math_util = July.require("core.math_util")

local M = {}

local ROBLOX_GRAV = 196.2
local LEAD_PASSES = 6

local function vec3(v)
    if not v then return 0, 0, 0 end
    return v.x or v.X or 0, v.y or v.Y or 0, v.z or v.Z or 0
end

function M.gravity_accel(gravity_mult)
    if not gravity_mult or gravity_mult <= 0 then
        return ROBLOX_GRAV * 0.55
    end
    if gravity_mult <= 2 then
        return ROBLOX_GRAV * gravity_mult
    end
    return gravity_mult
end

function M.calculate_target_position(bullet_speed, bullet_gravity, velocity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local vx, vy, vz = vec3(velocity)

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)

    local horiz_speed = math.sqrt(vx * vx + vz * vz)
    if horiz_speed < 1.5 then
        vx, vy, vz = 0, vy, 0
    end

    vy = math.max(-80, math.min(80, vy))

    local time = math_util.distance3(px - ox, py - oy, pz - oz) / speed

    for _ = 1, LEAD_PASSES do
        local tx = px + vx * time
        local ty = py + vy * time
        local tz = pz + vz * time
        time = math_util.distance3(tx - ox, ty - oy, tz - oz) / speed
    end

    local tx = px + vx * time
    local ty = py + vy * time
    local tz = pz + vz * time
    local drop = 0.5 * g * time * time

    return {
        x = tx,
        y = ty + drop,
        z = tz,
    }
end

function M.predict_for_weapon(origin, position, velocity, weapon_name)
    local stats = July.require("game.combat_stats").get_effective_stats(weapon_name)
    return M.calculate_target_position(stats.speed, stats.gravity, velocity, position, origin)
end

return M

end)()

-- ── game/item_tiers.lua ──
July._mods["game.item_tiers"] = (function()
-- Auto-generated from Havoc dump. Run: node scripts/extract-extra.mjs
local M = {}

M.TIER_GAME = {
    cash = { level = 0, type = "cash", r = 29, g = 38, b = 23 },
    common = { level = 1, type = "common", r = 31, g = 31, b = 31 },
    common_households = { level = 1, type = "common", r = 31, g = 31, b = 31 },
    contraband = { level = 2, type = "contraband", r = 62, g = 61, b = 44 },
    gear_common = { level = 1, type = "common", r = 31, g = 31, b = 31 },
    gear_rare = { level = 3, type = "rare", r = 38, g = 37, b = 50 },
    keys = { level = 4, type = "keys", r = 62, g = 56, b = 34 },
    mythic = { level = 5, type = "mythic", r = 50, g = 32, b = 32 },
    player_item = { level = 4, type = "rare", r = 71, g = 48, b = 68 },
    rare = { level = 3, type = "rare", r = 38, g = 29, b = 50 },
    t = { level = 1, type = "common", r = 31, g = 31, b = 31 },
    uncommon = { level = 2, type = "uncommon", r = 27, g = 35, b = 38 },
    usable_item = { level = 1, type = "usable", r = 33, g = 38, b = 34 },
    usable_item_inhaler = { level = 1, type = "usable", r = 62, g = 52, b = 48 },
}

M.TIER_ESP = {
    cash = { 0.626, 0.820, 0.496, 1 },
    common = { 0.820, 0.820, 0.820, 1 },
    common_households = { 0.820, 0.820, 0.820, 1 },
    contraband = { 0.820, 0.807, 0.582, 1 },
    gear_common = { 0.820, 0.820, 0.820, 1 },
    gear_rare = { 0.623, 0.607, 0.820, 1 },
    keys = { 0.820, 0.741, 0.450, 1 },
    mythic = { 0.820, 0.525, 0.525, 1 },
    player_item = { 0.820, 0.554, 0.785, 1 },
    rare = { 0.623, 0.476, 0.820, 1 },
    t = { 0.820, 0.820, 0.820, 1 },
    uncommon = { 0.583, 0.755, 0.820, 1 },
    usable_item = { 0.712, 0.820, 0.734, 1 },
    usable_item_inhaler = { 0.820, 0.688, 0.635, 1 },
    common_gun = { 0.95, 0.32, 0.22, 1 },
}

M.ITEM_TIER = {
    [".338 Lapua Magnum"] = "mythic",
    [".408 Cheyenne Tactical"] = "mythic",
    [".45 ACP"] = "uncommon",
    [".50 Action Express"] = "uncommon",
    ["0.2 BTC"] = "rare",
    ["12 Gauge Buckshot"] = "uncommon",
    ["23x75mm Shrapnel-10"] = "mythic",
    ["23x75mm Zvezda flashbang round"] = "mythic",
    ["311 Double Barrel"] = "common_gun",
    ["4.6x30mm"] = "uncommon",
    ["40x46mm M406 grenade"] = "mythic",
    ["5.11 Hexgrid Plate Carrier"] = "mythic",
    ["5.45x39mm"] = "uncommon",
    ["5.56x45 Beta C-Mag 100-round drum magazine"] = "uncommon",
    ["5.56x45 Colt AR-15 STANAG 20-round magazine"] = "uncommon",
    ["5.56x45 Colt AR-15 STANAG 30-round magazine"] = "uncommon",
    ["5.56x45 Colt AR-15 STANAG 60-round magazine"] = "uncommon",
    ["5.56x45 PMAG 60-round magazine"] = "uncommon",
    ["5.56x45 TV 100-round magazine"] = "uncommon",
    ["5.56x45mm NATO"] = "uncommon",
    ["5.7x28mm"] = "uncommon",
    ["5.8x42mm"] = "uncommon",
    ["7.62x39mm"] = "uncommon",
    ["7.62x51mm NATO"] = "uncommon",
    ["7.62x54mmR"] = "uncommon",
    ["870 MCS"] = "common_gun",
    ["9x18mm"] = "uncommon",
    ["9x19mm"] = "uncommon",
    ["9x39 20-round magazine"] = "uncommon",
    ["9x39 30-round magazine"] = "uncommon",
    ["9x39mm"] = "uncommon",
    ["A7 Delta Riot Helmet"] = "gear_common",
    ["AA Battery"] = "common",
    ["ACOG TA11D 3.5x35 riflescope"] = "uncommon",
    ["AI-2"] = "usable_item",
    ["Airstrike"] = "mythic",
    ["AK 7.62x39 40-round magazine"] = "uncommon",
    ["AK 7.62x39 Magpul PMAG 30 GEN M3 30-round magazine"] = "uncommon",
    ["AK-1 Helm"] = "player_item",
    ["AK-74 5.45x39 6L20 30-round magazine"] = "uncommon",
    ["AK-74 5.45x39 Magpul PMAG 30 GEN M3 30-round magazine"] = "uncommon",
    ["AK-74M"] = "common_gun",
    ["AKS-74U"] = "common_gun",
    ["Alien on a Rampage Book"] = "common",
    ["Altyn bulletproof Helmet"] = "mythic",
    ["Altyn helmet face shield"] = "gear_rare",
    ["Aluminium Nails"] = "common",
    ["Ammunition case"] = "usable_item",
    ["AN/PEQ-15 tactical device"] = "uncommon",
    ["Angled foregrip"] = "uncommon",
    ["Antique teapot"] = "rare",
    ["AS VAL"] = "mythic",
    ["Awl"] = "common",
    ["AWP"] = "mythic",
    ["AWP .338 Lapua Magnum 5-round magazine"] = "uncommon",
    ["Bad Guys"] = "common",
    ["Bandage"] = "usable_item",
    ["Barbed Wire Bat"] = "uncommon",
    ["Beretta 92X"] = "common_gun",
    ["Beretta 92X 9x19 17-round magazine"] = "uncommon",
    ["Bimetallic Thermometer"] = "rare",
    ["Blackberryz Wallet"] = "usable_item",
    ["Blahaj Baja Blast Pen"] = "player_item",
    ["Box of Sugar"] = "common_households",
    ["Bramit 7.62x54R sound suppressor"] = "uncommon",
    ["Brassknuckles"] = "uncommon",
    ["Cables"] = "common",
    ["Can of Beef"] = "rare",
    ["Can of Mackerel"] = "common_households",
    ["Can of Salt"] = "common_households",
    ["Can of Tuna"] = "common_households",
    ["Capacitors"] = "common",
    ["Car Battery"] = "common",
    ["Cash"] = "cash",
    ["Chemical Solution"] = "common",
    ["Citori 725"] = "common_gun",
    ["CJJ\\226\\128\\153s Guide to Making Money"] = "common",
    ["CMMG Mk47 Mutant"] = "mythic",
    ["CMT ZCOMP linear compensator"] = "mythic",
    ["Colt 4x20 riflescope"] = "uncommon",
    ["Colt Python"] = "common_gun",
    ["Compact antenna"] = "rare",
    ["Conductor's Gold Pocket Watch"] = "rare",
    ["Construction Measuring Tape"] = "common",
    ["Corrugated Tube"] = "rare",
    ["Cottage Cache Key"] = "keys",
    ["Dawnscript Fragment"] = "rare",
    ["DC 800 High Cut Combat Helmet"] = "gear_rare",
    ["Deagle"] = "common_gun",
    ["Deagle .50 AE 7-round magazine"] = "uncommon",
    ["Defibrillator monitor"] = "rare",
    ["Deluxe Pirate Hook"] = "rare",
    ["Deodorant"] = "common_households",
    ["Diamond ring"] = "mythic",
    ["Diary"] = "rare",
    ["DIY Flamethrower"] = "common_gun",
    ["Dogtag"] = "common",
    ["Domino Crown"] = "rare",
    ["DP-27"] = "mythic",
    ["DP-27 7.62x54mmR 47-round pan magazine"] = "uncommon",
    ["Duct tape"] = "common",
    ["Electric Drill"] = "common",
    ["Empty dish"] = "common_households",
    ["EOTech 553 holographic sight"] = "uncommon",
    ["F-1"] = "uncommon",
    ["FAST MT Helmet"] = "gear_rare",
    ["FAST multi-hit ballistic face shield"] = "gear_rare",
    ["Fists"] = "uncommon",
    ["Flash Drive"] = "common",
    ["Flour"] = "common_households",
    ["FN P90 5.7x28 50-round magazine"] = "uncommon",
    ["FN SCAR-H 7.62x51 20-round magazine"] = "uncommon",
    ["FN SCAR-H 7.62x51 50-round drum magazine"] = "uncommon",
    ["Forest Green Ghillie Suit"] = "mythic",
    ["FORT-9 Heavy Assault Rig"] = "gear_rare",
    ["FORTIS Coastal Outpost Cache Key"] = "keys",
    ["FORTIS Level-0 keycard"] = "keys",
    ["FORTIS Level-1 keycard"] = "keys",
    ["FORTIS Level-2 keycard"] = "keys",
    ["FORTIS Level-3 keycard"] = "keys",
    ["FORTIS Level-4 keycard"] = "keys",
    ["FORTIS Level-5 keycard"] = "keys",
    ["FORTIS Level-6 keycard"] = "keys",
    ["FORTIS MK.II Gloves"] = "mythic",
    ["Gears"] = "common",
    ["Gemtech SFN-57 5.7x28 sound suppressor"] = "uncommon",
    ["Geolocator"] = "common",
    ["GL 19 Gen4"] = "common_gun",
    ["GL 9x19 17-round magazine"] = "uncommon",
    ["GL 9x19 33-round magazine"] = "uncommon",
    ["GL 9x19 50-round drum magazine"] = "uncommon",
    ["Glim Charm"] = "player_item",
    ["Glue"] = "common",
    ["Gold bar"] = "mythic",
    ["Gold Trophy"] = "rare",
    ["Golden Cube"] = "rare",
    ["Golden Skull"] = "rare",
    ["Golden Smartphone"] = "rare",
    ["Golden Watch"] = "rare",
    ["Gorynych-S \"Sten\" Assault Rig"] = "mythic",
    ["Graphics card"] = "rare",
    ["Gunpowder"] = "rare",
    ["Gzhel-K Body Armor"] = "mythic",
    ["Hand Wraps"] = "gear_common",
    ["Havocola Cherry Burn"] = "common_households",
    ["Havocola Classic"] = "common_households",
    ["HK MP5 9x19 30-round magazine"] = "uncommon",
    ["HK MP5 9x19 50-round drum magazine"] = "uncommon",
    ["HK MP7 4.6x30 40-round magazine"] = "uncommon",
    ["HK MP7 SD 2 4.6x30 sound suppressor"] = "uncommon",
    ["HK UMP .45 ACP 25-round magazine"] = "uncommon",
    ["HK416"] = "mythic",
    ["HM6: Hemostatic Inhaler"] = "usable_item_inhaler",
    ["Homemade Soap"] = "common_households",
    ["HVC Gen4 Body Armor"] = "mythic",
    ["HVC Gen4 Body Armor (HMK)"] = "mythic",
    ["HVC Plate Carrier"] = "gear_rare",
    ["HVC-10T Night Vision Goggles"] = "gear_rare",
    ["iDog Bot"] = "player_item",
    ["Improvised plastic sound suppressor"] = "uncommon",
    ["Insecticide spray"] = "common_households",
    ["Insects Spray"] = "common_households",
    ["Insulin pump"] = "common",
    ["Integrated Tactical Plate Carrier"] = "gear_rare",
    ["Intelligence folder"] = "rare",
    ["Intervention M200"] = "mythic",
    ["Jiffy Domino Top Hat"] = "player_item",
    ["Karambit"] = "uncommon",
    ["Katana"] = "mythic",
    ["Ketchup"] = "common_households",
    ["Keycard holder case"] = "usable_item",
    ["Korund-VM Body Armor"] = "gear_rare",
    ["KRISS Vector"] = "common_gun",
    ["KS-23M"] = "mythic",
    ["Leupold Mark 8 8x24 riflescope"] = "uncommon",
    ["Lockpick"] = "uncommon",
    ["Long Screwdriver"] = "common",
    ["LVPO 10x28 riflescope"] = "uncommon",
    ["M16A1"] = "common_gun",
    ["M18 (White)"] = "uncommon",
    ["M1911"] = "common_gun",
    ["M1911A1 .45 ACP 7-round magazine"] = "uncommon",
    ["M200 .408 Cheyenne Tactical 5-round magazine"] = "uncommon",
    ["M249"] = "mythic",
    ["M4 Benelli"] = "mythic",
    ["M40 Gas Mask Filter"] = "gear_rare",
    ["M40-1 Gas Mask"] = "gear_common",
    ["M40-2 Gas Mask"] = "gear_common",
    ["M4A1"] = "mythic",
    ["M67"] = "uncommon",
    ["M79"] = "mythic",
    ["M84"] = "uncommon",
    ["MAC-10"] = "common_gun",
    ["MAC-10 9x19 30-round magazine"] = "uncommon",
    ["MAC-10 sound suppressor"] = "uncommon",
    ["Magic Lamp"] = "rare",
    ["Magnet"] = "common",
    ["Makarov"] = "common_gun",
    ["Makarov 9x18 8-round magazine"] = "uncommon",
    ["Mask"] = "gear_common",
    ["Maska-1SCh \"Voin\" face shield"] = "gear_rare",
    ["Maska-1SCh \"Voin\" Helmet"] = "mythic",
    ["Maska-1SCh face shield"] = "gear_rare",
    ["Maska-1SCh Helmet"] = "mythic",
    ["Mayonnaise"] = "common_households",
    ["MBC Plate Carrier"] = "gear_common",
    ["Measuring tape"] = "common",
    ["Meat grinder"] = "common_households",
    ["Medical bloodset"] = "common",
    ["Medical Kit"] = "usable_item",
    ["Medical set"] = "rare",
    ["Metal Awl"] = "common",
    ["Metal Cutting Scissors"] = "common",
    ["Metal fuel tank"] = "common_households",
    ["Microcircuits"] = "common",
    ["Military Backpack"] = "mythic",
    ["Military Helmet"] = "gear_common",
    ["Mk14 7.62x51 10-round magazine"] = "common",
    ["Mk14 EBR"] = "mythic",
    ["Molotov"] = "uncommon",
    ["Mosin\\226\\128\\147Nagant"] = "common_gun",
    ["MOTR Concealable Reinforced Vest"] = "gear_common",
    ["Mounting Foam"] = "common",
    ["MP34"] = "common_gun",
    ["MP34 9x19 32-round magazine"] = "uncommon",
    ["MP5A5"] = "common_gun",
    ["MP7"] = "common_gun",
    ["MP9"] = "common_gun",
    ["MP9 9x19 30-round magazine"] = "uncommon",
    ["MP9 9x19 sound suppressor"] = "uncommon",
    ["MSA Paraclete Plate Carrier"] = "gear_rare",
    ["Mug"] = "common_households",
    ["Nails"] = "common",
    ["NCStar AQPTLMG Compact Green Laser"] = "uncommon",
    ["Nightforce ATACR 7-35x56"] = "uncommon",
    ["Nomad Route Notes"] = "rare",
    ["North Dolphin Hospital Safe Key"] = "keys",
    ["Northmont Sparkling Cider"] = "rare",
    ["NovaTec reflex sight"] = "uncommon",
    ["NovaTec RMR reflex sight"] = "uncommon",
    ["ODWave 556 5.56x45 sound suppressor"] = "uncommon",
    ["Oil Filter sound suppressor"] = "uncommon",
    ["OKP-7 reflex sight"] = "uncommon",
    ["Orange juice carton"] = "common_households",
    ["P90"] = "common_gun",
    ["PA3: Relief Inhaler"] = "usable_item_inhaler",
    ["Pack of matches"] = "common_households",
    ["Palmolive handwash"] = "common_households",
    ["PBS-1 sound suppressor"] = "uncommon",
    ["Perfume"] = "common_households",
    ["PG-7V HEAT grenade"] = "mythic",
    ["Pickaxe"] = "uncommon",
    ["PICO-A1 Light Lower Body Armor"] = "gear_common",
    ["PICO-A2 Heavy Lower Body Armor"] = "gear_rare",
    ["Pile of meds"] = "common",
    ["Pipe wrench"] = "rare",
    ["Pipecleaner"] = "common",
    ["Porcelain"] = "rare",
    ["Power unit"] = "common",
    ["Powerbank"] = "common",
    ["Precisive Grips"] = "gear_rare",
    ["Printer Paper"] = "common",
    ["PSO-1 4x24 scope"] = "uncommon",
    ["PU-1 3.5x riflescope"] = "uncommon",
    ["PureFire X300 Ultra"] = "uncommon",
    ["PX27 Headlamp"] = "gear_rare",
    ["QBZ-95"] = "common_gun",
    ["QDSS-NT4 5.56x45 sound suppressor"] = "uncommon",
    ["RAM"] = "rare",
    ["Rapid Emergency AED Compact Tool"] = "mythic",
    ["Rat Poison"] = "rare",
    ["RG-9: Regenerative Inhaler"] = "usable_item_inhaler",
    ["RGO"] = "mythic",
    ["RK-1 tactical foregrip"] = "uncommon",
    ["ROVER Motorcycle Helmet"] = "gear_common",
    ["RPG-7"] = "mythic",
    ["RPK"] = "common_gun",
    ["RPK-16 5.45x39 95-round drum magazine"] = "uncommon",
    ["RV11: Emergency Resuscitator Inhaler"] = "usable_item_inhaler",
    ["S&M Backpack"] = "usable_item",
    ["S7: Stimulant Inhaler"] = "usable_item_inhaler",
    ["SA-58"] = "mythic",
    ["SA58/FAL 7.62x51 20-round magazine"] = "uncommon",
    ["SA58/FAL 7.62x51 50-round drum magazine"] = "uncommon",
    ["Saiga 12"] = "mythic",
    ["SAIPH signal pistol"] = "usable_item",
    ["SAS drive"] = "rare",
    ["SCAR-H"] = "mythic",
    ["Scissors"] = "common_households",
    ["Scrap Metal"] = "common",
    ["Screwdriver"] = "common",
    ["Scuba Gear"] = "gear_common",
    ["Sealed black file"] = "rare",
    ["Sealing Foam"] = "common",
    ["Sewing Kit"] = "common",
    ["Shampoo"] = "common_households",
    ["Shards in the Code: Season One"] = "common",
    ["SHARK muzzle brake"] = "mythic",
    ["SilKo Osprey 9 9x19 sound suppressor"] = "uncommon",
    ["SilKo Salvo 12 12ga sound suppressor"] = "uncommon",
    ["SKS"] = "common_gun",
    ["Slick Plate Carrier"] = "mythic",
    ["Sling Bag"] = "usable_item",
    ["Smartphone"] = "common",
    ["Sodium Bicarbonate"] = "common",
    ["Sodium Chloride"] = "common",
    ["Splint"] = "usable_item",
    ["Spoon"] = "common_households",
    ["Spork 777"] = "player_item",
    ["Sport Complex \\226\\128\\156Lych Zdorovya\\226\\128\\157 Cache Key"] = "keys",
    ["SR16"] = "mythic",
    ["SSD"] = "rare",
    ["Sticky Tape"] = "common",
    ["String"] = "common",
    ["Superpunch"] = "uncommon",
    ["SureFire 3-prong flash hider"] = "uncommon",
    ["SureFire 4-prong flash hider"] = "uncommon",
    ["Surgical kit"] = "rare",
    ["SV-98"] = "common_gun",
    ["SV-98 7.62x51 10-round magazine"] = "uncommon",
    ["SV-98 7.62x54R sound suppressor"] = "uncommon",
    ["SVD"] = "common_gun",
    ["SVD 7.62x54mmR 10-round magazine"] = "uncommon",
    ["T-7 Thermal Goggles"] = "mythic",
    ["T178 Raid Backpack"] = "mythic",
    ["Tactical Sword"] = "uncommon",
    ["Tagilla's welding mask \"Gorilla\""] = "mythic",
    ["Tagilla's welding mask \"UBEY\""] = "mythic",
    ["Tank Battery"] = "rare",
    ["The 5th Annual Bloxy Award"] = "rare",
    ["The Cap Of The Rebelled"] = "player_item",
    ["The Crucible"] = "contraband",
    ["The Greatest Admin plushie"] = "player_item",
    ["Thraggorian Arms 3516"] = "player_item",
    ["Titanium Alloy Plate"] = "rare",
    ["Toilet paper"] = "common_households",
    ["Tomahawk"] = "uncommon",
    ["Toothpaste"] = "common_households",
    ["Tourniquet"] = "usable_item",
    ["Tube of cold welding"] = "common",
    ["Type 04-1 holographic sight"] = "uncommon",
    ["Type 95 5.8x42mm 30-round magazine"] = "uncommon",
    ["UH-1 holographic sight"] = "uncommon",
    ["ULACH IIIA Helmet"] = "gear_rare",
    ["UMP45"] = "common_gun",
    ["USB extension cable"] = "common",
    ["Vanish 30 5.56x45 sound suppressor"] = "mythic",
    ["Vegetable oil"] = "common_households",
    ["Vertical foregrip"] = "uncommon",
    ["Vintage Gold Crown"] = "rare",
    ["Vitamins"] = "common",
    ["VSS modern stock"] = "mythic",
    ["VSS Vintorez"] = "mythic",
    ["Watch"] = "common_households",
    ["Weapon case"] = "usable_item",
    ["Weapon parts"] = "rare",
    ["White tube"] = "common",
    ["Wrench"] = "common",
    ["XDM's Red Helm"] = "player_item",
    ["XLaser pointer module"] = "mythic",
    ["Xtreme Motorcycle Helmet"] = "gear_common",
    ["YMA95-1 3.5x riflescope"] = "uncommon",
}

M.KEYCARDS = {
    ["FORTIS Level-0 keycard"] = true,
    ["FORTIS Level-1 keycard"] = true,
    ["FORTIS Level-2 keycard"] = true,
    ["FORTIS Level-3 keycard"] = true,
    ["FORTIS Level-4 keycard"] = true,
    ["FORTIS Level-5 keycard"] = true,
    ["FORTIS Level-6 keycard"] = true,
    ["Keycard holder case"] = true,
}

return M

end)()

-- ── game/tier_util.lua ──
July._mods["game.tier_util"] = (function()
local item_tiers = July.require("game.item_tiers")

local M = {}

local DEFAULT = { 0.55, 0.55, 0.58, 1.0 }

local WEAPON_NAMES = {
    ["870 MCS"] = true, ["AK-74M"] = true, ["AKS-74U"] = true, ["Beretta 92X"] = true,
    ["Brassknuckles"] = true, ["CMMG Mk47 Mutant"] = true, ["Citori 725"] = true,
    ["DP-27"] = true, ["F-1"] = true, ["Fists"] = true, ["GL 19 Gen4"] = true,
    ["HK416"] = true, ["KRISS Vector"] = true, ["Karambit"] = true, ["M16A1"] = true,
    ["M1911"] = true, ["M4A1"] = true, ["M67"] = true, ["M84"] = true, ["MAC-10"] = true,
    ["MP34"] = true, ["MP7"] = true, ["MP9"] = true, ["Makarov"] = true, ["Molotov"] = true,
    ["P90"] = true, ["QBZ-95"] = true, ["SKS"] = true, ["SR16"] = true, ["Tomahawk"] = true,
    ["UMP45"] = true, ["VSS Vintorez"] = true,
}

local TIER_DISPLAY = {
    common_gun = "Common",
    common = "Common",
    common_households = "Common",
    gear_common = "Common",
    uncommon = "Uncommon",
    contraband = "Contraband",
    rare = "Rare",
    gear_rare = "Rare",
    player_item = "Rare",
    keys = "Keycard",
    mythic = "Mythic",
    usable_item = "Usable",
    usable_item_inhaler = "Usable",
    cash = "Cash",
}

local KEYCARD_LEVEL = {
    [0] = { 0.72, 0.68, 0.42, 1.0 },
    [1] = { 0.78, 0.72, 0.38, 1.0 },
    [2] = { 0.84, 0.76, 0.34, 1.0 },
    [3] = { 0.9, 0.8, 0.3, 1.0 },
    [4] = { 0.95, 0.85, 0.28, 1.0 },
    [5] = { 1.0, 0.88, 0.22, 1.0 },
    [6] = { 1.0, 0.92, 0.15, 1.0 },
}

function M.is_keycard(name)
    if not name then return false end
    if item_tiers.KEYCARDS[name] then return true end
    if name == "Keycard holder case" then return true end
    if name == "FORTIS Coastal Outpost Cache Key" then return true end
    return false
end

function M.is_gun_name(name)
    if not name then return false end
    if WEAPON_NAMES[name] then return true end
    return item_tiers.ITEM_TIER[name] == "common_gun"
end

function M.is_known_item(name)
    if not name or name == "" then return false end
    if item_tiers.ITEM_TIER[name] then return true end
    if item_tiers.KEYCARDS[name] then return true end
    if name == "Keycard holder case" then return true end
    if name == "FORTIS Coastal Outpost Cache Key" then return true end
    return false
end

function M.get_keycard_color(name)
    local level = tonumber(string.match(name or "", "Level%-(%d+)")) or 0
    return KEYCARD_LEVEL[level] or item_tiers.TIER_ESP.keys or DEFAULT
end

function M.get_tier_key(name)
    if not name then return nil end
    if M.is_keycard(name) then return "keys" end
    return item_tiers.ITEM_TIER[name]
end

function M.get_tier_display(tier_key)
    if not tier_key then return nil end
    return TIER_DISPLAY[tier_key]
end

function M.get_esp_color(name)
    if not name or name == "" then return DEFAULT end
    if M.is_keycard(name) then
        return M.get_keycard_color(name)
    end
    if M.is_gun_name(name) then
        return item_tiers.TIER_ESP.common_gun or { 0.95, 0.32, 0.22, 1 }
    end
    local tier_key = item_tiers.ITEM_TIER[name]
    if tier_key and item_tiers.TIER_ESP[tier_key] then
        return item_tiers.TIER_ESP[tier_key]
    end
    return DEFAULT
end

function M.get_item_label(name)
    if not name or name == "" then return name end
    local tier_key = M.get_tier_key(name)
    local tier_label = M.get_tier_display(tier_key)
    if tier_label then
        return name .. " · " .. tier_label
    end
    return name
end

return M

end)()

-- ── game/hitparts.lua ──
July._mods["game.hitparts"] = (function()
local M = {}

-- Zero-based combo index: 0 = Closest, 1 = Head (default).
M.DEFAULT_BONE_INDEX = 1

M.LABELS = {
    "Closest",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "Torso",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

M.MAP = {
    ["Head"] = { "Head" },
    ["UpperTorso"] = { "UpperTorso", "Torso" },
    ["LowerTorso"] = { "LowerTorso", "Torso" },
    ["HumanoidRootPart"] = { "HumanoidRootPart", "Torso", "UpperTorso" },
    ["Torso"] = { "Torso", "UpperTorso" },
    ["LeftUpperArm"] = { "LeftUpperArm", "Left Arm" },
    ["RightUpperArm"] = { "RightUpperArm", "Right Arm" },
    ["LeftLowerArm"] = { "LeftLowerArm", "Left Arm" },
    ["RightLowerArm"] = { "RightLowerArm", "Right Arm" },
    ["LeftHand"] = { "LeftHand", "Left Arm" },
    ["RightHand"] = { "RightHand", "Right Arm" },
    ["LeftUpperLeg"] = { "LeftUpperLeg", "Left Leg" },
    ["RightUpperLeg"] = { "RightUpperLeg", "Right Leg" },
    ["LeftLowerLeg"] = { "LeftLowerLeg", "Left Leg" },
    ["RightLowerLeg"] = { "RightLowerLeg", "Right Leg" },
    ["LeftFoot"] = { "LeftFoot", "Left Leg" },
    ["RightFoot"] = { "RightFoot", "Right Leg" },
    ["Left Arm"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm" },
    ["Right Arm"] = { "Right Arm", "RightUpperArm", "RightLowerArm" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg" },
}

function M.label_from_index(idx)
    idx = tonumber(idx)
    if idx == nil then idx = M.DEFAULT_BONE_INDEX end
    return M.LABELS[idx + 1] or "Head"
end

function M.candidate_names(label)
    if label == "Closest" then
        return nil
    end
    return M.MAP[label] or { label }
end

function M.all_part_names()
    local out = {}
    for i = 2, #M.LABELS do
        local names = M.MAP[M.LABELS[i]]
        if names then
            for j = 1, #names do
                out[#out + 1] = names[j]
            end
        end
    end
    return out
end

return M

end)()

-- ── game/loot_catalog.lua ──
July._mods["game.loot_catalog"] = (function()
local env = July.require("core.env")

local M = {}

-- lootType ids from game dump (33) + body bags
M.LOOT_TYPES = {
    { key = "loot_ammo_crate", loot_type = "ammo.crate", display = "Ammo Crate", color = { 0.3, 0.75, 1.0, 1.0 } },
    { key = "loot_big_safe", loot_type = "big.safe", display = "Safe", color = { 1.0, 0.85, 0.2, 1.0 } },
    { key = "loot_cabinet", loot_type = "cabinet", display = "Cabinet", color = { 0.9, 0.75, 0.3, 1.0 } },
    { key = "loot_cash_register", loot_type = "cash.register", display = "Cash Register", color = { 1.0, 0.8, 0.1, 1.0 } },
    { key = "loot_closet", loot_type = "closet", display = "Closet", color = { 0.6, 0.6, 0.65, 1.0 } },
    { key = "loot_complex_crate", loot_type = "complex.crate", display = "Complex Crate", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_computer", loot_type = "computer", display = "Computer", color = { 0.3, 0.9, 0.9, 1.0 } },
    { key = "loot_dishwasher", loot_type = "dishwasher", display = "Dishwasher", color = { 0.6, 0.7, 0.8, 1.0 } },
    { key = "loot_duffel_bag", loot_type = "duffel.bag", display = "Duffel Bag", color = { 0.85, 0.7, 0.35, 1.0 } },
    { key = "loot_envelope", loot_type = "envelope", display = "Envelope", color = { 0.9, 0.85, 0.7, 1.0 } },
    { key = "loot_file_cabinet", loot_type = "file.cabinet", display = "File Cabinet", color = { 0.55, 0.5, 0.45, 1.0 } },
    { key = "loot_fridge", loot_type = "fridge", display = "Fridge", color = { 0.75, 0.88, 0.92, 1.0 } },
    { key = "loot_hospital_cabinet", loot_type = "hospital.cabinet", display = "Hospital Cabinet", color = { 0.9, 0.9, 0.95, 1.0 } },
    { key = "loot_locker", loot_type = "locker", display = "Locker", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_medical_box", loot_type = "medical.box", display = "Medical Box", color = { 0.9, 0.2, 0.2, 1.0 } },
    { key = "loot_medium_crate", loot_type = "medium.wooden.crate", display = "Medium Wooden Crate", color = { 0.62, 0.44, 0.24, 1.0 } },
    { key = "loot_military_radio", loot_type = "military.radio", display = "Military Radio", color = { 0.35, 0.55, 0.35, 1.0 } },
    { key = "loot_military_supply", loot_type = "military.supply", display = "Military Supply", color = { 0.3, 0.55, 0.3, 1.0 } },
    { key = "loot_pistol_case", loot_type = "pistol.case", display = "Pistol Case", color = { 1.0, 0.45, 0.3, 1.0 } },
    { key = "loot_rifle_case", loot_type = "rifle.case", display = "Rifle Case", color = { 1.0, 0.5, 0.3, 1.0 } },
    { key = "loot_server_unit", loot_type = "server.unit", display = "Server Unit", color = { 0.25, 0.8, 0.95, 1.0 } },
    { key = "loot_small_case", loot_type = "small.case", display = "Small Case", color = { 0.9, 0.6, 0.4, 1.0 } },
    { key = "loot_standing_atm", loot_type = "standing.atm", display = "ATM", color = { 0.2, 0.9, 0.5, 1.0 } },
    { key = "loot_stove", loot_type = "stove", display = "Stove", color = { 0.5, 0.5, 0.5, 1.0 } },
    { key = "loot_tall_fridge", loot_type = "tall.fridge", display = "Tall Fridge", color = { 0.7, 0.85, 0.9, 1.0 } },
    { key = "loot_tool_shelf", loot_type = "tool.shelf", display = "Tool Shelf", color = { 0.4, 0.68, 0.88, 1.0 } },
    { key = "loot_toolbox", loot_type = "toolbox", display = "Toolbox", color = { 0.4, 0.65, 0.85, 1.0 } },
    { key = "loot_washing_machine", loot_type = "washing.machine", display = "Washing Machine", color = { 0.65, 0.75, 0.85, 1.0 } },
    { key = "loot_weapon_box", loot_type = "weapon.box", display = "Weapon Box", color = { 1.0, 0.35, 0.25, 1.0 } },
    { key = "loot_weapon_locker", loot_type = "weapon.locker", display = "Weapon Locker", color = { 1.0, 0.4, 0.2, 1.0 } },
    { key = "loot_wooden_crate", loot_type = "wooden.crate", display = "Wooden Crate", color = { 0.55, 0.4, 0.25, 1.0 } },
    { key = "loot_door", loot_type = "door", display = "Locked Door", color = { 0.5, 0.4, 0.3, 1.0 } },
}

M.BODY_BAG_TYPE = { key = "loot_body_bag", loot_type = "body.bag", display = "Body Bag", color = { 0.35, 0.35, 0.35, 1.0 } }

M.DROP_TYPES = {
    { key = "loot_dropped_guns", loot_type = "drop.gun", display = "Dropped Guns", color = { 0.95, 0.32, 0.22, 1.0 } },
    { key = "loot_dropped_items", loot_type = "drop.item", display = "Dropped Items", color = { 0.55, 0.55, 0.58, 1.0 } },
    { key = "loot_keycards", loot_type = "drop.keycard", display = "Keycards", color = { 0.95, 0.82, 0.32, 1.0 } },
}

M.TYPE_MAP = {}
M.NAME_MAP = {}
M.MULTICOMBO_ENTRIES = {}
M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

local MODEL_ALIASES = {
    ["Ammunition Box"] = "ammo.crate",
    ["Safe"] = "big.safe",
    ["Cash Register"] = "cash.register",
    ["HospitalCabinet"] = "hospital.cabinet",
    ["StandingATM"] = "standing.atm",
    ["Military Crate"] = "military.supply",
    ["Raider Cache"] = "big.safe",
    ["Technical Shelf"] = "tool.shelf",
    ["Surgeon's Tool Shelf"] = "tool.shelf",
    ["WoodenDoor"] = "door",
    ["DoubleGlassDoor"] = "door",
    ["DoubleMetalDoor"] = "door",
    ["MetalDoor"] = "door",
    ["GarageDoorLock"] = "door",
}

local function rebuild()
    M.TYPE_MAP = {}
    M.NAME_MAP = {}
    M.MULTICOMBO_ENTRIES = {}
    M.MULTICOMBO_LABELS = {}
    M.MULTICOMBO_DEFAULTS = {}
    M.KEY_TO_INDEX = {}

    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        M.TYPE_MAP[entry.loot_type] = entry
        M.KEY_TO_INDEX[entry.key] = i
        M.MULTICOMBO_ENTRIES[i] = entry
        M.MULTICOMBO_LABELS[i] = entry.display
        M.MULTICOMBO_DEFAULTS[i] = true
    end

    local base = #M.LOOT_TYPES
    for i = 1, #M.DROP_TYPES do
        local entry = M.DROP_TYPES[i]
        local idx = base + i
        M.TYPE_MAP[entry.loot_type] = entry
        M.KEY_TO_INDEX[entry.key] = idx
        M.MULTICOMBO_ENTRIES[idx] = entry
        M.MULTICOMBO_LABELS[idx] = entry.display
        M.MULTICOMBO_DEFAULTS[idx] = true
    end

    local body_idx = base + #M.DROP_TYPES + 1
    M.TYPE_MAP[M.BODY_BAG_TYPE.loot_type] = M.BODY_BAG_TYPE
    M.KEY_TO_INDEX[M.BODY_BAG_TYPE.key] = body_idx
    M.MULTICOMBO_ENTRIES[body_idx] = M.BODY_BAG_TYPE
    M.MULTICOMBO_LABELS[body_idx] = M.BODY_BAG_TYPE.display
    M.MULTICOMBO_DEFAULTS[body_idx] = true

    for model_name, loot_type in pairs(MODEL_ALIASES) do
        M.NAME_MAP[model_name] = loot_type
    end
    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        if entry.display then
            M.NAME_MAP[entry.display] = entry.loot_type
        end
    end
end

rebuild()

function M.resolve(loot_type_str, model_name)
    if loot_type_str and M.TYPE_MAP[loot_type_str] then
        return M.TYPE_MAP[loot_type_str]
    end
    if model_name then
        local alias = M.NAME_MAP[model_name]
        if alias and M.TYPE_MAP[alias] then
            return M.TYPE_MAP[alias]
        end
        if string.find(model_name, "Door", 1, true) then
            return M.TYPE_MAP["door"]
        end
    end
    return nil
end

function M.is_enabled(vals, category)
    if not category then return false end
    local idx = M.KEY_TO_INDEX[category.key]
    if not idx then return false end
    if type(vals) ~= "table" then return true end
    local v = vals[idx]
    if v == nil then return true end
    return v == true
end

function M.get_color(category)
    if category and category.color then return category.color end
    return { 1, 1, 1, 1 }
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

-- ── game/havoc_sync.lua ──
July._mods["game.havoc_sync"] = (function()
local env = July.require("core.env")

local M = {}

M._chars_folder = nil
M._folder_name = nil
M._last_sync_attempt = -999
M._sync_failures = 0

local SYNC_RETRY_INTERVAL = 2.0

local function read_shared_folder_name()
    local ok, name = pcall(function()
        if shared and type(shared.charactersFolderName) == "string" then
            return shared.charactersFolderName
        end
        return nil
    end)
    if ok and name and name ~= "" then
        return name
    end
    return nil
end

function M.get_folder_name()
    if M._folder_name then return M._folder_name end

    local shared_name = read_shared_folder_name()
    if shared_name then
        M._folder_name = shared_name
        return shared_name
    end

    local now = os.clock()
    if (now - M._last_sync_attempt) < SYNC_RETRY_INTERVAL then
        return nil
    end
    M._last_sync_attempt = now

    local rs = game and (game.ReplicatedStorage or (game.GetService and game:GetService("ReplicatedStorage")))
    if not rs then return nil end

    local storage = env.find_child(rs, "Storage")
    local events = storage and env.find_child(storage, "Events")
    local getGSync = events and env.find_child(events, "GetGSync")
    if not getGSync then return nil end

    local ok, name = pcall(function()
        if getGSync.InvokeServer then return getGSync:InvokeServer() end
        return nil
    end)

    if ok and type(name) == "string" and name ~= "" then
        M._folder_name = name
        M._sync_failures = 0
        return name
    end

    M._sync_failures = M._sync_failures + 1
    return nil
end

function M.get_characters_folder()
    if M._chars_folder and not env.is_valid(M._chars_folder) then
        M._chars_folder = nil
    end

    if M._chars_folder then
        return M._chars_folder
    end

    local ws = env.get_workspace()
    if not ws then return nil end

    local name = M.get_folder_name()
    if name then
        local folder = env.safe_call(function()
            if ws.FindFirstChild then return ws:FindFirstChild(name) end
            return nil
        end)
        if not folder then
            M._folder_name = nil
            name = M.get_folder_name()
            if name then
                folder = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild(name) end
                    return nil
                end)
            end
        end
        if folder then
            M._chars_folder = folder
            return folder
        end
        folder = env.safe_call(function()
            if ws.WaitForChild and name then return ws:WaitForChild(name, 2) end
            return nil
        end)
        if folder then
            M._chars_folder = folder
            return folder
        end
    end

    return nil
end

function M.reset()
    M._chars_folder = nil
    M._folder_name = nil
    M._last_sync_attempt = -999
    M._sync_failures = 0
end

return M

end)()

-- ── game/asset_urls.lua ──
July._mods["game.asset_urls"] = (function()
local M = {}

M.REPO = "Cunzaki/July"
M.BRANCH = "main"
M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/April/refs/heads/main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.roblox_thumb(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=%s",
        asset_id
    )
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.decal_url(asset_id)
    return string.format(
        "https://raw.githubusercontent.com/%s/refs/heads/%s/assets/decals/%s.png",
        M.REPO, M.BRANCH, tostring(asset_id)
    )
end

return M

end)()

-- ── game/item_images.lua ──
July._mods["game.item_images"] = (function()
-- AUTO-GENERATED by scripts/extract-item-catalog.mjs — do not edit by hand
-- Source: dump/scripts/ReplicatedStorage.Modules.Items.ModuleScript.lua

local M = {}

M.by_name = {
    ["%s\\'s Trophy"] = { default = "15274399715" },
    ["Admin Tool"] = { default = "16630443040" },
    ["Ammo Press"] = { default = "15061609857" },
    ["Animal Fat"] = { default = "15304534433" },
    ["Anvil"] = { default = "15082009292" },
    ["Armor Plate"] = { default = "126213314272257" },
    ["Armor Polish"] = { default = "106804025023012" },
    ["Armor Stand"] = { default = "80529735817758" },
    ["Auto Turret"] = { default = "92892387954820" },
    ["Balaclava"] = { default = "14654791788", variants = { ["Default"] = "14654791788", ["Jester"] = "15344534842", ["Frankenstein"] = "15883389666", ["Independence"] = "18341880885", ["Digital"] = "18965910197", ["Jolly"] = "129387971218495", ["Skull"] = "139941774966045", ["Monkey"] = "74568523494874", } },
    ["Bandage"] = { default = "14134567329" },
    ["Barrel Light"] = { default = "17508402018" },
    ["Base Cabinet"] = { default = "14653876852", variants = { ["Default"] = "14653876852", ["Server"] = "109131187101243", } },
    ["Baseball Cap"] = { default = "14654795325", variants = { ["Default"] = "14654795325", ["Quack"] = "16208669800", ["Independence"] = "18341880766", ["Propeller"] = "115535550124192", ["Pilgrim"] = "132977576727336", } },
    ["Bean Can"] = { default = "14162885124" },
    ["Bear Trap"] = { default = "16283811174" },
    ["Bed"] = { default = "15368539842", variants = { ["Default"] = "15368539842", ["Pixel"] = "125567129432156", } },
    ["Beef MRE"] = { default = "14162884919" },
    ["Black Keycard"] = { default = "115892814344173" },
    ["Blade"] = { default = "14651119220" },
    ["Blast Furnace"] = { default = "15876671239", variants = { ["Default"] = "15876671239", ["Robot"] = "18149216269", ["Steampunk"] = "113856439034974", } },
    ["Blueberries"] = { default = "17508520653" },
    ["Blueberry Pie I"] = { default = "17513319274" },
    ["Blueberry Pie II"] = { default = "17513319171" },
    ["Blueberry Pie III"] = { default = "17513318992" },
    ["Blueberry Pie IV"] = { default = "17513318548" },
    ["Blueberry Plant Seed"] = { default = "17357236681" },
    ["Blueprint"] = { default = "15132469785" },
    ["Bone Armor"] = { default = "119847143620647", variants = { ["Default"] = "119847143620647", } },
    ["Bone Arrow"] = { default = "13981013521" },
    ["Bone Shards"] = { default = "13207713694" },
    ["Bone Tool"] = { default = "15510368323", variants = { ["Default"] = "15510368323", } },
    ["Boots"] = { default = "14654795457", variants = { ["Default"] = "14654795457", ["Black"] = "15283152697", ["Abibas"] = "15305690697", ["Valentine"] = "16293022275", ["Woodland"] = "16473066174", ["Correctional"] = "92577755087375", ["Nutcracker"] = "102533866187536", ["Brutus"] = "124559624944530", ["Tundra"] = "75185734630840", ["Pilot"] = "134265072222654", ["Medal"] = "107412050354842", } },
    ["Boss Chestplate"] = { default = "16652581317", variants = { ["Default"] = "16652581317", ["Cryo"] = "106187507956822", ["Boris"] = "18354053691", ["Brutus"] = "120699966211693", } },
    ["Boss Helmet"] = { default = "16652579167", variants = { ["Default"] = "16652579167", ["Cryo"] = "102872157681930", ["Boris"] = "18312187080", ["Brutus"] = "134265072222654", } },
    ["Bottle Caps"] = { default = "14654996629" },
    ["Boulder"] = { default = "15304806846", variants = { ["Default"] = "15304806846", ["Bubblegum"] = "15304805303", ["Frosty"] = "15304805239", ["Tester"] = "15304805180", ["Voxel"] = "15574223076", ["Wrapped"] = "15712360641", ["Pixskull"] = "17766619061", ["Stellark"] = "97313343547804", ["Cursed"] = "92913832321996", ["Sushi"] = "78426403974796", ["Chocolate"] = "139716602333201", ["Moai"] = "115978938918724", ["Ducky"] = "124674000707337", ["Pumpkin"] = "126349162347833", ["Mosaic"] = "74510585736689", } },
    ["Bruno\\'s ACOG Sight"] = { default = "16671196298" },
    ["Bruno\\'s M4A1"] = { default = "15574295393", variants = { ["Default"] = "15574295393", } },
    ["Buckshot"] = { default = "13186566301" },
    ["Bunny Ears"] = { default = "16916795577", variants = { ["Default"] = "16916795577", } },
    ["Button"] = { default = "93858053715998" },
    ["Cactus Flesh"] = { default = "13219980518" },
    ["Campfire"] = { default = "15128008159", variants = { ["Default"] = "15128008159", ["Skulls"] = "133107732568884", } },
    ["Candle"] = { default = "117249643725742", variants = { ["Default"] = "117249643725742", ["Medium"] = "108927440959870", ["Large"] = "84899373039469", } },
    ["Candy Cane"] = { default = "15633196493", variants = { ["Default"] = "15633196493", } },
    ["Candy Roll"] = { default = "138463136634140" },
    ["Care Package Signal"] = { default = "15128007999" },
    ["Carpentry Table"] = { default = "15082010398" },
    ["Carrot Blade"] = { default = "16916703095", variants = { ["Default"] = "16916703095", } },
    ["Chainsaw"] = { default = "17201657737", variants = { ["Default"] = "17201657737", ["Recycle"] = "17357130465", } },
    ["Charcoal"] = { default = "13207713474" },
    ["Chemistry Lab"] = { default = "15074207343" },
    ["Chicken Egg"] = { default = "17497768025" },
    ["Chicken House"] = { default = "17499918454" },
    ["Chicken MRE"] = { default = "14162884663" },
    ["Chocolate Bar"] = { default = "14162884792" },
    ["Christmas Lights"] = { default = "134491722995587", variants = { ["Default"] = "134491722995587", } },
    ["Christmas Tree"] = { default = "15634564093", variants = { ["Default"] = "15634564093", } },
    ["Circuit Boards"] = { default = "14651118848" },
    ["Clan Table"] = { default = "74442604226077" },
    ["Cloth"] = { default = "13207713326" },
    ["Cloth Footwraps"] = { default = "14654794730", variants = { ["Default"] = "14654794730", ["Ninja"] = "132892877448790", } },
    ["Cloth Handwraps"] = { default = "14654831164", variants = { ["Default"] = "14654831164", ["Ninja"] = "114878511497747", } },
    ["Cloth Headwrap"] = { default = "14654795058", variants = { ["Default"] = "14654795058", ["Ninja"] = "120080222783269", } },
    ["Cloth Pants"] = { default = "14654794952", variants = { ["Default"] = "14654794952", ["Ninja"] = "88014133756226", } },
    ["Cloth Shirt"] = { default = "14654794835", variants = { ["Default"] = "14654794835", ["Ninja"] = "107568365412229", } },
    ["Collared Shirt"] = { default = "14654793432", variants = { ["Default"] = "14654793432", ["Business"] = "15444462393", ["Correctional"] = "140110401401547", ["Flannel"] = "97292443788852", } },
    ["Combination Lock"] = { default = "15305165381" },
    ["Combustive Arrow"] = { default = "13981013386" },
    ["Combustive Buckshot"] = { default = "13186565241" },
    ["Combustive Heavy Ammo"] = { default = "13186583441" },
    ["Combustive Rocket"] = { default = "15637959127" },
    ["Common Goodie Bag"] = { default = "118444522725158" },
    ["Compensator"] = { default = "15347108187" },
    ["Cooked Pork"] = { default = "15295773801" },
    ["Cooked Venison"] = { default = "13220221662" },
    ["Cooked Wolf"] = { default = "15295773801" },
    ["Cooking Pot"] = { default = "15127562373", variants = { ["Default"] = "15127562373", } },
    ["Copper Cogs"] = { default = "14651228837" },
    ["Corn"] = { default = "17412555936" },
    ["Corn Bread I"] = { default = "17513318249" },
    ["Corn Bread II"] = { default = "17513318071" },
    ["Corn Bread III"] = { default = "17513317915" },
    ["Corn Bread IV"] = { default = "17513317765" },
    ["Corn Plant Seed"] = { default = "17357236563" },
    ["Cow Pasture"] = { default = "17499917838" },
    ["Crossbow"] = { default = "15305596532", variants = { ["Default"] = "15305596532", ["Crossbones"] = "15305756728", ["HotDog"] = "15877969435", ["Emerald"] = "16751858634", ["Rose"] = "80803215254174", ["Toy"] = "102956782968040", ["Chief"] = "137062431435688", } },
    ["Crude Fuel"] = { default = "14651282157" },
    ["Crude Fuel Generator"] = { default = "117457710807147", variants = { ["Default"] = "117457710807147", } },
    ["Culinary Table"] = { default = "15061609707" },
    ["Cursed Pumpkin"] = { default = "74135087469069" },
    ["Diving Goggles"] = { default = "13842989638" },
    ["Diving Tank"] = { default = "13843003364" },
    ["Duct Tape"] = { default = "14651118525" },
    ["Dynamite Bundle"] = { default = "15127431071" },
    ["Dynamite Stick"] = { default = "15127430886" },
    ["Electric Furnace"] = { default = "71536889851799", variants = { ["Default"] = "71536889851799", ["ICBM"] = "115876027631434", } },
    ["Electric Heater"] = { default = "117015755787407", variants = { ["Default"] = "117015755787407", } },
    ["Empty Can"] = { default = "14594762895" },
    ["Epic Goodie Bag"] = { default = "93565798791105" },
    ["Explosive Shell"] = { default = "71411772918243" },
    ["Extended Mag"] = { default = "17286302189" },
    ["External Stone Gate"] = { default = "14134361372" },
    ["External Stone Wall"] = { default = "15709318091" },
    ["External Wooden Gate"] = { default = "15132487698" },
    ["External Wooden Wall"] = { default = "15132487460" },
    ["Fireplace"] = { default = "134438626724268", variants = { ["Default"] = "134438626724268", } },
    ["Fish Can"] = { default = "14162884523" },
    ["Flannel Jacket"] = { default = "14654794281", variants = { ["Default"] = "14654794281", ["Biker"] = "15877516070", ["Correctional"] = "100006176575349", ["Abibas"] = "138547747231782", } },
    ["Flippers"] = { default = "13843003596" },
    ["Floor Grill"] = { default = "15853202987" },
    ["Furnace"] = { default = "15074084708", variants = { ["Default"] = "15074084708", ["Banana"] = "15344532656", ["Glyphs"] = "15630767150", ["Gorilla"] = "16484587298", ["Burger"] = "84948985557474", ["Penguin"] = "122396159441498", ["Pumpkin"] = "81542845446759", } },
    ["Garage Door"] = { default = "16574547137", variants = { ["Default"] = "16574547137", ["Blob"] = "15509791543", ["Cryo"] = "113706556350765", ["Witch"] = "85491019952546", } },
    ["Glass Window"] = { default = "15210914495" },
    ["Glue"] = { default = "14651236358" },
    ["Gunpowder"] = { default = "15074277771" },
    ["Halloween Scythe"] = { default = "97593929634585" },
    ["Hammer"] = { default = "15318044673", variants = { ["Default"] = "15318044673", ["Toy"] = "15509809013", } },
    ["Hard Hat"] = { default = "14654794545", variants = { ["Default"] = "14654794545", ["Slurpee"] = "15950562586", } },
    ["Hazmat Suit"] = { default = "15046441717", variants = { ["Default"] = "15046441717", ["Snowman"] = "15712521421", ["Spark"] = "18965466357", ["Stellark"] = "123693400858947", ["Classified"] = "78801273340050", ["Front"] = "109185322610878", ["Guard"] = "113617571174399", ["Ducky"] = "116234383398695", ["Ghoul"] = "102977931837887", ["Specialist"] = "99406105774604", } },
    ["Heavy Ammo"] = { default = "13186564679" },
    ["Heavy Padding"] = { default = "136131316663930" },
    ["Holo Sight"] = { default = "14162721610" },
    ["Hoodie"] = { default = "14654794392", variants = { ["Default"] = "14654794392", ["Boris"] = "18312277063", ["Red"] = "15283152304", ["Purple"] = "15283152380", ["Green"] = "15283152598", ["Abibas"] = "15305689057", ["Wool"] = "15877516276", ["Valentine"] = "16293021303", ["Woodland"] = "16448119412", ["Tyrant"] = "130901964742021", ["Nutcracker"] = "72418266986929", ["Puffer"] = "71855339887230", ["Brutus"] = "116605401922894", ["Tundra"] = "94852483691948", ["Pilot"] = "134265072222654", ["Player"] = "72323540553042", ["Bee"] = "106663686372311", ["Night"] = "104718096945503", } },
    ["Horizontal Window Cover"] = { default = "15396925485" },
    ["Iron Ore"] = { default = "14308849053" },
    ["Iron Shard Hatchet"] = { default = "15073617640", variants = { ["Default"] = "15073617640", ["Fade"] = "16663953399", ["Sawblade"] = "18963884209", ["Leather"] = "82373698320243", } },
    ["Iron Shard Pickaxe"] = { default = "15073617491", variants = { ["Default"] = "15073617491", ["Fade"] = "16663949312", ["Leather"] = "99659875069484", } },
    ["Iron Shards"] = { default = "14184000696" },
    ["Jack-O-Lantern"] = { default = "139460860545325", variants = { ["Default"] = "139460860545325", ["Sad"] = "101370696376275", ["Happy"] = "130966939339167", } },
    ["Jail Door"] = { default = "13547704298" },
    ["Jail Wall"] = { default = "13547704099" },
    ["Jukebox"] = { default = "17343466496", variants = { ["Default"] = "17343466496", } },
    ["Ladder"] = { default = "15127607098", variants = { ["Default"] = "15127607098", } },
    ["Landmine Trap"] = { default = "16283811057" },
    ["Large Battery"] = { default = "78253036378845", variants = { ["Default"] = "78253036378845", } },
    ["Large Cobweb"] = { default = "104604287353224" },
    ["Large Furnace"] = { default = "15133678858", variants = { ["Default"] = "15133678858", } },
    ["Large Medkit"] = { default = "75730798424498" },
    ["Large Planter Box"] = { default = "17506371558" },
    ["Large Storage Box"] = { default = "15094083403", variants = { ["Default"] = "15094083403", ["Canvas"] = "15283200485", ["Festive"] = "15709683124", ["Forged"] = "17758887216", ["Coffin"] = "112688458744179", ["Ouja"] = "102172335761498", } },
    ["Large Wooden Sign"] = { default = "15509119053" },
    ["Leather"] = { default = "13207712789" },
    ["Leather Boots"] = { default = "14654794176", variants = { ["Default"] = "14654794176", ["Correctional"] = "95515905374532", } },
    ["Leather Gloves"] = { default = "14654794097", variants = { ["Default"] = "14654794097", ["Correctional"] = "92980178755471", ["Noir"] = "107804982630320", } },
    ["Leather Pants"] = { default = "14654793993", variants = { ["Default"] = "14654793993", ["Correctional"] = "108412621160578", } },
    ["Leather Poncho"] = { default = "14654793821", variants = { ["Default"] = "14654793821", ["Viva"] = "16208668209", ["Pilgrim"] = "98358561085174", } },
    ["Leather Shirt"] = { default = "14654793568", variants = { ["Default"] = "14654793568", ["Correctional"] = "109168692318343", } },
    ["Lemon"] = { default = "17508522472" },
    ["Lemon Cake I"] = { default = "17513316973" },
    ["Lemon Cake II"] = { default = "17513316847" },
    ["Lemon Cake III"] = { default = "17513316683" },
    ["Lemon Cake IV"] = { default = "17513316422" },
    ["Lemon Plant Seed"] = { default = "17357236426" },
    ["Light Ammo"] = { default = "13685818536" },
    ["Lighter"] = { default = "15128007580", variants = { ["Default"] = "15128007580", ["Lantern"] = "123377357974589", } },
    ["Lightweight Padding"] = { default = "96591489718879" },
    ["Loom"] = { default = "17517380322" },
    ["Machete"] = { default = "16249771824", variants = { ["Default"] = "16249771824", ["Rainbow"] = "16823202004", ["Crimson"] = "16912320468", ["Foam"] = "18761536955", ["Oni"] = "84793810931259", } },
    ["Marsh Bar"] = { default = "113016339245665" },
    ["Meatball Can"] = { default = "14162884362" },
    ["Medium Battery"] = { default = "129552454538184", variants = { ["Default"] = "129552454538184", } },
    ["Metal Barricade"] = { default = "15380991275" },
    ["Metal Door"] = { default = "15132832907", variants = { ["Default"] = "15132832907", ["Pixel"] = "15310965325", ["Frosty"] = "15304875360", ["Independence"] = "18341881259", ["Comic"] = "18444379748", ["Industrial"] = "78073516430678", ["Demon"] = "137869636615146", ["Bayou"] = "88981731583061", } },
    ["Metal Double Door"] = { default = "15132833297", variants = { ["Default"] = "15132833297", ["Pixel"] = "15310966370", ["Tropical"] = "16483738322", ["Nightwave"] = "119789304012674", } },
    ["Metal Plating"] = { default = "14651164157" },
    ["Metal Scraps"] = { default = "14651117901" },
    ["Metal Spikes"] = { default = "16484592502" },
    ["Metal Window Bars"] = { default = "15132553555" },
    ["Military AA12"] = { default = "15068791139", variants = { ["Default"] = "15068791139", ["Zombie"] = "17199281354", ["Monster"] = "136853604493538", } },
    ["Military ACOG Sight"] = { default = "15373701079" },
    ["Military Backpack"] = { default = "117242081838466", variants = { ["Default"] = "117242081838466", ["Tundra"] = "98126095773472", ["Abibas"] = "82640089227507", } },
    ["Military Barrett"] = { default = "15346280030", variants = { ["Default"] = "15346280030", ["Surge"] = "15876918136", ["Leprechaun"] = "16751857511", ["Mystra"] = "98792148092190", ["Fade"] = "73907766386158", ["Molten"] = "103075738835660", ["Cryo"] = "124741300378620", } },
    ["Military Boat"] = { default = "14183996624" },
    ["Military Chestplate"] = { default = "14654793303", variants = { ["Default"] = "14654793303", ["Nutcracker"] = "70853333750344", ["Pilot"] = "134265072222654", ["Medal"] = "81188910996008", } },
    ["Military Gloves"] = { default = "14654794652", variants = { ["Default"] = "14654794652", ["Nutcracker"] = "118158228480821", ["Arctic"] = "76148467345468", ["Pilot"] = "134265072222654", ["Grim"] = "123472167772965", ["Medal"] = "137375914230135", } },
    ["Military Grenade"] = { default = "15444535479" },
    ["Military Grenade Launcher"] = { default = "136030704871223", variants = { ["Default"] = "136030704871223", } },
    ["Military Helmet"] = { default = "14654793165", variants = { ["Default"] = "14654793165", ["Nutcracker"] = "80633563389909", ["Pilot"] = "134265072222654", ["Medal"] = "108938282129584", } },
    ["Military Lasersight"] = { default = "15510372535" },
    ["Military Leggings"] = { default = "14654792938", variants = { ["Default"] = "14654792938", ["Nutcracker"] = "84566720271674", ["Brutus"] = "75512320758936", ["Tundra"] = "86308809791688", ["Cryo"] = "88056077715569", ["Medal"] = "136956516639652", } },
    ["Military M39"] = { default = "74435081612082", variants = { ["Default"] = "74435081612082", ["Medusa"] = "117342321001432", ["Turkey"] = "111197339750272", } },
    ["Military M4A1"] = { default = "15346201415", variants = { ["Default"] = "15346201415", ["Syntax"] = "15951831122", ["Monster"] = "16663261126", ["Toy"] = "17521734560", ["Independence"] = "18341881006", ["Phantom"] = "139190777075295", ["Nutcracker"] = "136729540441664", ["Medusa"] = "101267874762837", ["Cryo"] = "94745687589547", ["CyberPop"] = "101893225757265", } },
    ["Military MP7"] = { default = "17607841424", variants = { ["Default"] = "17607841424", ["Fade"] = "18764670728", ["Whiteout"] = "112724849582854", ["Tyrant"] = "88901653074832", ["Wave"] = "108003941053496", ["Animeaster"] = "137259300477168", ["Solitare"] = "128296099845816", ["Grunge"] = "96361565266502", ["Zap"] = "126949129741030", } },
    ["Military PKM"] = { default = "16471125314", variants = { ["Default"] = "16471125314", ["Woodland"] = "16471122135", ["Resistance"] = "18149212335", ["Turbo"] = "18950918343", } },
    ["Military Sniper Scope"] = { default = "15304097316" },
    ["Military USP"] = { default = "85577075764668", variants = { ["Default"] = "85577075764668", ["Fade"] = "89094430760827", ["Azure"] = "74032961902891", } },
    ["Milk"] = { default = "17497767948" },
    ["Mining Drill"] = { default = "17287978593", variants = { ["Default"] = "17287978593", ["Recycle"] = "17357129069", ["Brick"] = "111424776562874", } },
    ["Muzzle Boost"] = { default = "15347107233" },
    ["Nail Gun"] = { default = "15305104734", variants = { ["Default"] = "15305104734", ["Striker"] = "15305729695", ["Magma"] = "15946260536", ["Wintrane"] = "114731373088561", } },
    ["Nails"] = { default = "13186564996" },
    ["Night Vision Goggles"] = { default = "97551543360376" },
    ["Pants"] = { default = "14654792590", variants = { ["Default"] = "14654792590", ["Boris"] = "18312279038", ["Khaki"] = "15283151856", ["Abibas"] = "15305689962", ["Valentine"] = "16293019822", ["Woodland"] = "16448121262", ["Correctional"] = "135793344308303", ["Tyrant"] = "136885851029799", ["Nutcracker"] = "71901466636387", ["Brutus"] = "85540429494017", ["Tundra"] = "90847059484754", ["Pilot"] = "134265072222654", ["Player"] = "129572575838612", ["Bee"] = "136553486453775", } },
    ["Peanut Butter Cup"] = { default = "77624523695187" },
    ["Petroleum"] = { default = "14651118356" },
    ["Petroleum Refinery"] = { default = "15304104065", variants = { ["Default"] = "15304104065", } },
    ["Phosphate Dust"] = { default = "14183996960" },
    ["Phosphate Ore"] = { default = "15132608151" },
    ["Piercing Heavy Ammo"] = { default = "13186565419" },
    ["Piercing Light Ammo"] = { default = "13186588755" },
    ["Pink Keycard"] = { default = "15247381747" },
    ["Pipe"] = { default = "14651117776" },
    ["Pistol Receiver"] = { default = "14651117642" },
    ["Power Cell"] = { default = "13187407477" },
    ["Propane Tank"] = { default = "13187406443" },
    ["Pumpkin"] = { default = "88626583598376" },
    ["Pumpkin Launcher"] = { default = "119532925295032" },
    ["Pumpkin Pie"] = { default = "84895386905458" },
    ["Pumpkin Plant Seed"] = { default = "121878490679837" },
    ["Purple Keycard"] = { default = "15247381544" },
    ["Purple Ornament"] = { default = "131580423003709" },
    ["Quality Iron Ore"] = { default = "14308848947" },
    ["Radiation Vitamins"] = { default = "15304290390" },
    ["Rare Goodie Bag"] = { default = "82913604650237" },
    ["Raspberries"] = { default = "17508521640" },
    ["Raspberry Pie I"] = { default = "17513317601" },
    ["Raspberry Pie II"] = { default = "17513317487" },
    ["Raspberry Pie III"] = { default = "17513317352" },
    ["Raspberry Pie IV"] = { default = "17513317172" },
    ["Raspberry Plant Seed"] = { default = "17357236197" },
    ["Raw Pork"] = { default = "15295774046" },
    ["Raw Venison"] = { default = "13220221327" },
    ["Raw Wolf"] = { default = "15295774046" },
    ["Red Keycard"] = { default = "18313788194" },
    ["Red Ornament"] = { default = "100403008362378" },
    ["Repair Table"] = { default = "15283452092", variants = { ["Default"] = "15283452092", } },
    ["Resistant Rubber"] = { default = "114763366778253" },
    ["Rifle Receiver"] = { default = "14651117496" },
    ["Rocket"] = { default = "15132772763" },
    ["Rope"] = { default = "14651117276" },
    ["Rug"] = { default = "17205250687", variants = { ["Default"] = "17205250687", ["Kraken"] = "17518134457", ["Independence"] = "18341881393", } },
    ["SMG Receiver"] = { default = "14651115848" },
    ["Salvaged AK47"] = { default = "14882620172", variants = { ["Default"] = "14882620172", ["Frosty"] = "15304886302", ["Vaporwave"] = "15574230457", ["Diablo"] = "16021791118", ["Fade"] = "79444477121964", ["Tyrant"] = "124312637758997", ["Gingerbread"] = "85687142665622", ["Ghillie"] = "132083989873001", ["Anodized"] = "80710562596890", ["CyberPop"] = "128785004285267", ["Oni"] = "105854184847862", ["Medal"] = "102460072725837", ["Dune"] = "83484244695308", } },
    ["Salvaged AK74u"] = { default = "15073408197", variants = { ["Default"] = "15073408197", ["Beast"] = "15305755800", ["Splash"] = "15509741616", ["VIP"] = "16014753591", ["Comic"] = "16114228051", ["Clover"] = "16748171046", ["Nebula"] = "17518135139", ["Tundra"] = "114982197234346", ["MP5"] = "78960618674854", ["Flarette"] = "125113179502352", ["Zombie"] = "101630769388124", } },
    ["Salvaged Backpack"] = { default = "80978101846806", variants = { ["Default"] = "80978101846806", ["Ducky"] = "84777906931514", } },
    ["Salvaged Break Action"] = { default = "15305085935", variants = { ["Default"] = "15305085935", ["Splat"] = "15305729191", ["HotDog"] = "15632163269", ["Boom"] = "16823202171", ["Carrot"] = "16917852163", ["Surf"] = "17766587211", } },
    ["Salvaged Chestplate"] = { default = "14654792418", variants = { ["Default"] = "14654792418", ["Cupid"] = "16261611092", ["Burnout"] = "18557168052", ["Tempest"] = "18966646034", } },
    ["Salvaged Double Barrel"] = { default = "132642766917853", variants = { ["Default"] = "132642766917853", ["Ducky"] = "140296796147704", ["HotDog"] = "86842880761011", } },
    ["Salvaged Explosive Shell"] = { default = "100468627382165" },
    ["Salvaged Flycopter"] = { default = "14183996624" },
    ["Salvaged Gloves"] = { default = "14654792260", variants = { ["Default"] = "14654792260", ["Cupid"] = "16261613114", ["Tempest"] = "18971460487", } },
    ["Salvaged Grenade Launcher"] = { default = "122319440938090", variants = { ["Default"] = "122319440938090", } },
    ["Salvaged Helmet"] = { default = "14654792150", variants = { ["Default"] = "14654792150", ["Cupid"] = "16261611838", ["Tempest"] = "18966646232", ["Cardboard"] = "71323845635099", } },
    ["Salvaged Lasersight"] = { default = "15347108897" },
    ["Salvaged Leggings"] = { default = "14654792046", variants = { ["Default"] = "14654792046", ["Cupid"] = "16261614321", ["Tempest"] = "18966645952", } },
    ["Salvaged M14"] = { default = "14882876522", variants = { ["Default"] = "14882876522", ["Paintball"] = "15305730875", ["Splat"] = "16031054728", ["Arcane"] = "17507702118", ["Stellark"] = "77123726699368", ["Huntsman"] = "121372881282577", ["Glitch"] = "82715807510122", ["Frog14"] = "133627766691157", } },
    ["Salvaged Metal Door"] = { default = "15132658803", variants = { ["Default"] = "15132658803", ["Visions"] = "15444463543", ["Graffiti"] = "16664082484", } },
    ["Salvaged P250"] = { default = "15305065991", variants = { ["Default"] = "15305065991", ["Splat"] = "15305728596", ["Fade"] = "15631601051", ["Peppermint"] = "15712513595", ["Sketch"] = "16208668754", ["Tempest"] = "18966645823", ["Festive"] = "101842524476750", ["Drift"] = "94234232543243", } },
    ["Salvaged Pipe Rifle"] = { default = "15073408081", variants = { ["Default"] = "15073408081", ["Surge"] = "15509721163", ["Gingerbread"] = "15638252851", ["Frost"] = "16208668377", ["Skyline"] = "18557168359", } },
    ["Salvaged Pump Action"] = { default = "15092313032", variants = { ["Default"] = "15092313032", ["Cyber"] = "91058444899439", ["Flurry"] = "138789905852084", } },
    ["Salvaged Python"] = { default = "15188995729", variants = { ["Default"] = "15188995729", ["Canvas"] = "15283200809", ["Hazard"] = "15305731383", ["Saku"] = "16029067988", ["Inferno"] = "16283806768", ["Shockwave"] = "17366304773", ["Independence"] = "18341881121", ["Stellark"] = "124497972716738", ["Hyper"] = "85697748071844", ["Smudge"] = "76952866923184", ["Medal"] = "128419932789140", } },
    ["Salvaged RPG"] = { default = "15132772506", variants = { ["Default"] = "15132772506", ["Blast"] = "15305772236", ["Boomstick"] = "18965877488", ["Festive"] = "81287503464820", } },
    ["Salvaged SMG"] = { default = "15132874040", variants = { ["Default"] = "15132874040", ["Splat"] = "15313314715", ["Inferno"] = "15883391466", ["Checkmate"] = "16114277804", ["Valentine"] = "16281529715", ["Knight"] = "17366143384", ["Tempest"] = "18966646387", ["Joker"] = "104734469891887", ["Ducky"] = "119924390182546", } },
    ["Salvaged Shell"] = { default = "127373719846093" },
    ["Salvaged Shotgun"] = { default = "128621428767531", variants = { ["Default"] = "128621428767531", ["Banana"] = "90420924851404", ["HotDog"] = "94732589170018", ["Camo"] = "85391407055752", } },
    ["Salvaged Shovel"] = { default = "15074352064" },
    ["Salvaged Sight"] = { default = "15283494417" },
    ["Salvaged Skorpion"] = { default = "15369212859", variants = { ["Default"] = "15369212859", ["Gingerbread"] = "15637191692", ["Superior"] = "15950161435", ["Pegasus"] = "16577230942", ["Surge"] = "18149214997", ["Rusty"] = "87710451691684", ["Comic"] = "103323135308928", ["Celestial"] = "102882157920367", } },
    ["Salvaged Sniper"] = { default = "74470836610605", variants = { ["Default"] = "74470836610605", ["Valentine"] = "134067753909583", ["Radioactive"] = "128500957974672", } },
    ["Salvaged Sniper Scope"] = { default = "15304097362" },
    ["Santa Hat"] = { default = "15636087096", variants = { ["Default"] = "15636087096", } },
    ["Saw Bat"] = { default = "16249771997" },
    ["Scarecrow"] = { default = "99382957417299" },
    ["Semi Receiver"] = { default = "14651116315" },
    ["Sewing Table"] = { default = "15061609510" },
    ["Shop Machine"] = { default = "16769451135", variants = { ["Default"] = "16769451135", } },
    ["Shorts"] = { default = "14654791921", variants = { ["Default"] = "14654791921", } },
    ["Shotgun Shell"] = { default = "90346230004065" },
    ["Shotgun Turret"] = { default = "16009975774" },
    ["Silencer"] = { default = "15347105863" },
    ["Sleeping Bag"] = { default = "15313154200", variants = { ["Default"] = "15313154200", ["Prismatic"] = "15574227229", ["Santa"] = "15715978392", ["Shark"] = "16117442613", ["Voxel"] = "18147427074", ["Spooky"] = "85015559308510", ["Fruit"] = "81952434018281", ["UwU"] = "96904970768142", ["Chocolate"] = "108416357231982", } },
    ["Slug"] = { default = "13186564525" },
    ["Small Battery"] = { default = "88959343384498", variants = { ["Default"] = "88959343384498", } },
    ["Small Cobweb"] = { default = "72444796789811" },
    ["Small Medkit"] = { default = "15086741523" },
    ["Small Planter Box"] = { default = "17506371372" },
    ["Small Storage Box"] = { default = "15094083341", variants = { ["Default"] = "15094083341", ["Monster"] = "15883290696", ["Comic"] = "16577230729", ["Gremlin"] = "16748563435", ["Burger"] = "95806776502625", ["Medical"] = "97915388339168", } },
    ["Small Wooden Sign"] = { default = "15509119765" },
    ["Snorkle"] = { default = "136407336127139" },
    ["Solar Panel"] = { default = "81539973869850", variants = { ["Default"] = "81539973869850", } },
    ["Splitter"] = { default = "119105209870894" },
    ["Spring"] = { default = "14651115579" },
    ["Steel Axe"] = { default = "13206734202", variants = { ["Default"] = "13206734202", ["Ruby"] = "15444465626", ["Freeze"] = "15712516834", ["Lava"] = "81357829552245", } },
    ["Steel Chestplate"] = { default = "14654791689", variants = { ["Default"] = "14654791689", ["Frosty"] = "15305683641", ["OBEY"] = "15305695517", ["Woodland"] = "16447572145", ["Tyrant"] = "140168023066476", ["Oni"] = "126974041982300", ["Dune"] = "105836010915280", } },
    ["Steel Door"] = { default = "15132554218", variants = { ["Default"] = "15132554218", ["Galactic"] = "16483736587", ["Tyrant"] = "90255972475887", ["Duck"] = "132207599970757", } },
    ["Steel Double Door"] = { default = "15132553963", variants = { ["Default"] = "15132553963", ["Vaporwave"] = "17199280862", } },
    ["Steel Glass Window"] = { default = "15132487922" },
    ["Steel Helmet"] = { default = "14654791532", variants = { ["Default"] = "14654791532", ["Golden"] = "15305714913", ["Frosty"] = "15305683226", ["OBEY"] = "15305695029", ["VIP"] = "16014684244", ["Cardboard"] = "15627624994", ["Woodland"] = "16447574211", ["Tyrant"] = "109539796004549", ["Bomo"] = "80249585885084", ["Hockey"] = "97015125505963", ["Fear"] = "81724456402833", ["Oni"] = "114978122703010", ["Dune"] = "72849082443137", } },
    ["Steel Leggings"] = { default = "14654791387", variants = { ["Default"] = "14654791387", ["Frosty"] = "15305684250", ["OBEY"] = "15311675719", ["Woodland"] = "16447575529", ["Tyrant"] = "79519920346999", ["Oni"] = "98478307520733", ["Dune"] = "76898574981463", } },
    ["Steel Metal"] = { default = "16252541108" },
    ["Steel Pickaxe"] = { default = "13206733920", variants = { ["Default"] = "13206733920", ["Cross"] = "15444466662", ["Freeze"] = "15712518908", ["Molten"] = "18762535576", } },
    ["Steel Shovel"] = { default = "15074351964", variants = { ["Default"] = "15074351964", } },
    ["Steel Toes"] = { default = "117409121428636" },
    ["Stone"] = { default = "14308848818" },
    ["Stone Hatchet"] = { default = "15073617325", variants = { ["Default"] = "15073617325", ["Molten"] = "15305732445", ["Shark"] = "16208668072", ["VIP"] = "16014755281", ["Valentine"] = "16281532811", ["Slime"] = "80657230310751", } },
    ["Stone Pickaxe"] = { default = "15073617163", variants = { ["Default"] = "15073617163", ["Molten"] = "15305731898", ["VIP"] = "16014754516", ["Valentine"] = "16281531919", } },
    ["Stone Spear"] = { default = "15303292549" },
    ["Storage Cabinet"] = { default = "15572100650", variants = { ["Default"] = "15572100650", ["Monster"] = "15631715604", ["Hades"] = "16293483340", ["Tyrant"] = "125396135034194", ["Server"] = "83936574533516", } },
    ["Swift Arrow"] = { default = "13981013848" },
    ["Swift Heavy Ammo"] = { default = "13186565740" },
    ["Swift Light Ammo"] = { default = "13186591166" },
    ["Swift Rocket"] = { default = "15637955888" },
    ["Switch"] = { default = "99819564678318" },
    ["Tank Top"] = { default = "14654791246", variants = { ["Default"] = "14654791246", } },
    ["Tarp"] = { default = "14651115367" },
    ["Thread"] = { default = "14651157447" },
    ["Timed Charge"] = { default = "13169199238" },
    ["Tomato"] = { default = "17412555272" },
    ["Tomato Plant Seed"] = { default = "17357235843" },
    ["Trap Door"] = { default = "13143032792", variants = { ["Default"] = "13143032792", } },
    ["Triangle Trap Door"] = { default = "13724822281", variants = { ["Default"] = "13724822281", } },
    ["Vertical Window Cover"] = { default = "15396925620" },
    ["Water Bottle"] = { default = "14162884193" },
    ["Water Filter"] = { default = "128444748129429" },
    ["Water Turbine"] = { default = "118840048689367", variants = { ["Default"] = "118840048689367", } },
    ["Weapon Flashlight"] = { default = "15373700419" },
    ["Wetsuit"] = { default = "15304093679", variants = { ["Default"] = "15304093679", ["Pink"] = "17363544575", ["Frog"] = "80603678790020", } },
    ["White Ornament"] = { default = "125029502429647" },
    ["Windmill"] = { default = "84509705966195", variants = { ["Default"] = "84509705966195", } },
    ["Wire Cutters"] = { default = "118552370695485" },
    ["Wood Log"] = { default = "14183996624" },
    ["Wooden Arrow"] = { default = "13981013657" },
    ["Wooden Boat"] = { default = "14183996624" },
    ["Wooden Bow"] = { default = "15313266356", variants = { ["Default"] = "15313266356", ["Cupid"] = "16260403928", ["Crimson"] = "16912320324", ["Dragon"] = "119198626388204", } },
    ["Wooden Chestplate"] = { default = "14776135830", variants = { ["Default"] = "14776135830", } },
    ["Wooden Door"] = { default = "15132568626", variants = { ["Default"] = "15132568626", ["Beware"] = "15305026376", ["Chocolate"] = "15712523927", ["Cardboard"] = "132805078818983", ["Pixel"] = "106378082611103", ["Wise"] = "101629446511815", } },
    ["Wooden Double Door"] = { default = "15132568988", variants = { ["Default"] = "15132568988", ["Rainbow"] = "15344501592", } },
    ["Wooden Helmet"] = { default = "14776135648", variants = { ["Default"] = "14776135648", } },
    ["Wooden Leggings"] = { default = "14776135514", variants = { ["Default"] = "14776135514", } },
    ["Wooden Lock"] = { default = "15305165322" },
    ["Wooden Spear"] = { default = "15303292373" },
    ["Wooden Spikes"] = { default = "15380989444" },
    ["Wooden Window Bars"] = { default = "15128007380" },
    ["Wool"] = { default = "17499807914" },
    ["Wool Plant Seed"] = { default = "17357235671" },
    ["Wreath"] = { default = "125156247966096", variants = { ["Default"] = "125156247966096", } },
    ["Yellow Keycard"] = { default = "15247381343" },
    ["ez shovel"] = { default = "13877485530" },
}

function M.get_asset_id(name, variant)
    local row = name and M.by_name[name]
    if not row then return nil end
    if variant and row.variants and row.variants[variant] then
        return row.variants[variant]
    end
    return row.default
end

return M

end)()

-- ── game/items.lua ──
July._mods["game.items"] = (function()
local item_images = July.require("game.item_images")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")

local M = {}

local SKIP_WELD_NAMES = {
    Mask = true,
    WeldObjectsLink = true,
    thermalTemplate = true,
    welds = true,
    _at = true,
    _mod = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then return base, variant end
    return name, nil
end

local function texture_asset_from_inst(inst)
    if not inst or not env.is_valid(inst) then return nil end

    local handle = env.find_child(inst, "Handle")
    if handle then
        local ok, tex = pcall(function() return handle.TextureID end)
        if ok and tex and tex ~= "" then
            local id = tostring(tex):match("(%d+)")
            if id then return id end
        end
    end

    return nil
end

local function find_named_child(model, name)
    if not model or not name then return nil end
    return env.safe_call(function()
        if model.FindFirstChild then
            local ok, found = pcall(function() return model:FindFirstChild(name, true) end)
            if ok and found then return found end
            return model:FindFirstChild(name)
        end
        return nil
    end)
end

function M.make_piece(name, variant, model)
    if not name or name == "" then return nil end

    local asset_id = item_images.get_asset_id(name, variant)
    if not asset_id and model then
        local inst = find_named_child(model, name)
        asset_id = texture_asset_from_inst(inst)
    end

    return {
        name = name,
        variant = variant,
        asset_id = asset_id,
    }
end

function M.resolve_item_label(label, model)
    if not label or label == "" then return nil end
    local base, variant = parse_variant_name(label)
    if tier_util.is_known_item(base) or tier_util.is_gun_name(base) or tier_util.is_keycard(base) then
        return M.make_piece(base, variant, model)
    end
    return M.make_piece(base, variant, model)
end

function M.get_image_asset_id(name, variant, model)
    local piece = M.resolve_item_label(name, model)
    return piece and piece.asset_id or nil
end

function M.is_gear_piece_name(name)
    if not name or name == "" then return false end
    if SKIP_WELD_NAMES[name] then return false end
    if name:sub(1, 1) == "_" then return false end
    return tier_util.is_known_item(name) or tier_util.is_gun_name(name) or tier_util.is_keycard(name)
end

return M

end)()

-- ── game/target_gear.lua ──
July._mods["game.target_gear"] = (function()
local env = July.require("core.env")
local items = July.require("game.items")
local tier_util = July.require("game.tier_util")
local weapons = July.require("game.weapons")

local M = {}

local ATTACHMENT_SLOT_HINTS = {
    p1 = true, p2 = true, p3 = true, p4 = true,
    slot1 = true, slot2 = true, slot3 = true,
    sight = true, muzzle = true, underbarrel = true,
}

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end

local function add_armor(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    out.armor[#out.armor + 1] = piece
end

local function add_attachment(out, seen, label, model)
    if not label or label == "" or is_attachment_slot_name(label) then return end
    if seen[label] then return end
    seen[label] = true
    local piece = items.resolve_item_label(label, model)
    if piece then
        out.attachments[#out.attachments + 1] = piece
    end
end

local function scan_attachments_folder(folder, model, out, seen)
    if not folder or not env.is_valid(folder) then return end
    local ok, children = pcall(function() return folder:GetChildren() end)
    if not ok or not children then return end
    for i = 1, #children do
        add_attachment(out, seen, children[i].Name, model)
    end
end

local function scan_tool_attachments(tool, model, out, seen)
    if not tool or not env.is_valid(tool) then return end

    local attachments = env.find_child(tool, "Attachments")
    scan_attachments_folder(attachments, model, out, seen)

    local weapon = env.find_child(tool, "Weapon")
    if weapon then
        scan_attachments_folder(env.find_child(weapon, "Attachments"), model, out, seen)
    end

    local at = env.find_child(tool, "_at")
    if at then
        scan_attachments_folder(at, model, out, seen)
    end
end

local function find_named_child(model, name)
    if not model or not name then return nil end
    return env.safe_call(function()
        if model.FindFirstChild then
            local ok, found = pcall(function() return model:FindFirstChild(name, true) end)
            if ok and found then return found end
            return model:FindFirstChild(name)
        end
        return nil
    end)
end

local function resolve_held(model)
    if not model or not env.is_valid(model) then return nil, nil end

    local ok, children = pcall(function() return model:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child.ClassName == "Tool" then
                return child.Name, child
            end
            if child.ClassName == "Model" and tier_util.is_gun_name(child.Name) then
                return child.Name, child
            end
        end
    end

    local held = weapons.get_held_tool_name()
    if held and tier_util.is_gun_name(held) then
        return held, find_named_child(model, held)
    end

    return nil, nil
end

local function scan_weld_objects(model, out, seen)
    local weld = env.find_child(model, "WeldObjects")
    if not weld or not env.is_valid(weld) then return end

    local ok, children = pcall(function() return weld:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Model" and items.is_gear_piece_name(child.Name) then
            add_armor(out, seen, items.resolve_item_label(child.Name, model))
        end
    end
end

local function scan_character(model)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }

    if not model or not env.is_valid(model) then return out end

    local held_name, tool_inst = resolve_held(model)
    if held_name then
        out.held = items.resolve_item_label(held_name, model)
    end

    local att_seen = {}
    scan_tool_attachments(tool_inst, model, out, att_seen)

    if not tool_inst then
        local ok, children = pcall(function() return model:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Tool" or child.ClassName == "Model" then
                    scan_tool_attachments(child, model, out, att_seen)
                end
            end
        end
    end

    local armor_seen = {}
    scan_weld_objects(model, out, armor_seen)

    return out
end

function M.scan_npc(ent)
    if not ent or not ent.model then
        return { held = nil, attachments = {}, armor = {} }
    end
    local out = scan_character(ent.model)
    local held_name = ent.held_name or ent._held_name
    if not out.held and held_name and held_name ~= "" then
        out.held = items.resolve_item_label(held_name, ent.model)
    end
    return out
end

function M.scan_player(player)
    local model = player and (player.Character or player.character)
    if not model or not env.is_valid(model) then
        return { held = nil, attachments = {}, armor = {} }
    end
    return scan_character(model)
end

function M.scan_target(target)
    if not target then
        return { held = nil, attachments = {}, armor = {} }
    end
    if target.is_npc then
        return M.scan_npc(target)
    end
    return M.scan_player(target.player or target)
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

-- ── game/combat_stats.lua ──
July._mods["game.combat_stats"] = (function()
local weapons = July.require("game.weapons")

local M = {}

local DEFAULT = { speed = 900, gravity = 0.55 }

local FALLBACK = {
    ["M4A1"] = { speed = 900, gravity = 0.55 },
    ["HK416"] = { speed = 900, gravity = 0.55 },
    ["SR16"] = { speed = 900, gravity = 0.55 },
    ["M16A1"] = { speed = 900, gravity = 0.55 },
    ["AK-74M"] = { speed = 900, gravity = 0.55 },
    ["AKS-74U"] = { speed = 850, gravity = 0.55 },
    ["QBZ-95"] = { speed = 900, gravity = 0.55 },
    ["CMMG Mk47 Mutant"] = { speed = 900, gravity = 0.55 },
    ["Mk14 EBR"] = { speed = 880, gravity = 0.55 },
    ["SKS"] = { speed = 735, gravity = 0.55 },
    ["SVD"] = { speed = 830, gravity = 0.55 },
    ["SV-98"] = { speed = 850, gravity = 0.55 },
    ["VSS Vintorez"] = { speed = 750, gravity = 0.55 },
    ["AWP"] = { speed = 850, gravity = 0.55 },
    ["P90"] = { speed = 750, gravity = 0.55 },
    ["MP7"] = { speed = 720, gravity = 0.55 },
    ["MP9"] = { speed = 720, gravity = 0.55 },
    ["MP5A5"] = { speed = 720, gravity = 0.55 },
    ["MP34"] = { speed = 410, gravity = 0.55 },
    ["MAC-10"] = { speed = 650, gravity = 0.55 },
    ["UMP45"] = { speed = 700, gravity = 0.55 },
    ["KRISS Vector"] = { speed = 750, gravity = 0.55 },
    ["870 MCS"] = { speed = 550, gravity = 0.55 },
    ["Citori 725"] = { speed = 550, gravity = 0.55 },
    ["311 Double Barrel"] = { speed = 550, gravity = 0.55 },
    ["DP-27"] = { speed = 500, gravity = 0.55 },
    ["Beretta 92X"] = { speed = 650, gravity = 0.55 },
    ["GL 19 Gen4"] = { speed = 650, gravity = 0.55 },
    ["M1911"] = { speed = 650, gravity = 0.55 },
    ["Makarov"] = { speed = 600, gravity = 0.55 },
}

function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held()
    local base = weapon_name and FALLBACK[weapon_name] or nil
    if not base then
        return {
            speed = DEFAULT.speed,
            gravity = DEFAULT.gravity,
            name = weapon_name or "Unknown",
        }
    end
    return {
        speed = base.speed,
        gravity = base.gravity,
        name = weapon_name,
    }
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

local function vec3_from_any(pos)
    if not pos then return nil end
    if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
    if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    return nil
end

local function attachment_world_pos(att)
    if not att or not env.is_valid(att) then return nil end
    local ok, pos = pcall(function()
        if att.WorldPosition then return att.WorldPosition end
        if att.Position then return att.Position end
        return nil
    end)
    return vec3_from_any(ok and pos or nil)
end

local function get_current_camera()
    local ws = env.get_workspace()
    if ws then
        local cam = env.safe_call(function()
            if ws.CurrentCamera then return ws.CurrentCamera end
            if ws.FindFirstChildOfClass then return ws:FindFirstChildOfClass("Camera") end
            return nil
        end)
        if cam then return cam end
    end
    return nil
end

local function find_muzzlefx_on(tool)
    if not tool then return nil end

    local handle = env.find_child(tool, "Handle")
    if not handle then return nil end

    local muzzle = env.find_child(handle, "MuzzleFX")
    if muzzle then
        return attachment_world_pos(muzzle) or part_pos(handle)
    end

    local ok, children = pcall(function() return handle:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child.Name == "MuzzleFX" or child.ClassName == "Attachment" then
                local pos = attachment_world_pos(child) or part_pos(handle)
                if pos then return pos end
            end
        end
    end

    return part_pos(handle)
end

local function viewmodel_muzzle()
    local cam = get_current_camera()
    if cam then
        local vm = env.find_child(cam, "__viewmodel")
        if vm then
            local ok, children = pcall(function() return vm:GetChildren() end)
            if ok and children then
                for i = 1, #children do
                    local pos = part_pos(children[i])
                    if pos then return pos end
                end
            end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local legacy = ws:FindFirstChild("__viewmodel")
        if legacy then
            local ok, children = pcall(function() return legacy:GetChildren() end)
            if ok and children then
                for i = 1, #children do
                    local pos = part_pos(children[i])
                    if pos then return pos end
                end
            end
        end
    end

    return nil
end

local function camera_origin()
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then return vec3_from_any(pos) end
    end
    return nil
end

local function head_origin()
    local lp = env.get_local_player()
    if lp then
        if lp.head_position then
            local pos = vec3_from_any(lp.head_position)
            if pos then return pos end
        end

        local char = lp.Character or lp.character
        if char and env.is_valid(char) then
            local head = env.find_child(char, "Head")
            local pos = part_pos(head)
            if pos then return pos end
        end
    end
    return nil
end

local function body_origin()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.Position then
        local pos = vec3_from_any(lp.Position)
        if pos then return pos end
    end

    local char = lp.Character or lp.character
    if char and env.is_valid(char) then
        local root = env.find_child(char, "HumanoidRootPart")
            or env.find_child(char, "Torso")
            or env.find_child(char, "UpperTorso")
        return part_pos(root)
    end

    return nil
end

function M.invalidate()
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held()
    frame.weapon = weapon
    frame.server = head_origin() or body_origin()

    local lp = env.get_local_player()
    local char = lp and (lp.Character or lp.character)
    if char and weapon then
        local tool = env.find_child(char, weapon)
        frame.muzzle = find_muzzlefx_on(tool) or viewmodel_muzzle() or head_origin() or camera_origin()
    else
        frame.muzzle = viewmodel_muzzle() or head_origin() or camera_origin()
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
    return frame.muzzle or frame.server or head_origin() or camera_origin()
end

function M.get_head_origin()
    return head_origin() or body_origin()
end

return M

end)()

-- ── game/npc_types.lua ──
July._mods["game.npc_types"] = (function()
--[[
    NPC classification for Project Vector.
    Boss templates: ReplicatedStorage/__tempSTORAGE/characters/<name>/WeldObjects/Mask
    Runtime: Character:GetAttribute("Boss") / GetAttribute("Sniper")
]]

local M = {}

-- Codename elite NPCs from dump character templates (+ legacy aliases).
M.BOSS_NAMES = {
    Boris = true,
    Bruno = true,
    Brutus = true,
    Tagilla = true,
    Ranger = true,
    Clutch = true,
    Kodiak = true,
    Vandal = true,
    Grizzly = true,
    Crossfire = true,
    Warlock = true,
    Stalemate = true,
    Lynx = true,
    Hawk = true,
    Talon = true,
    Volt = true,
    Dagger = true,
    Spartan = true,
    Cipher = true,
    Maverick = true,
    Falcon = true,
    Checkmate = true,
    Scorch = true,
    Raptor = true,
    Knox = true,
    Fox = true,
    Bullet = true,
    Zero = true,
    Cobra = true,
    Ghost = true,
    Shade = true,
    Mamba = true,
    Phoenix = true,
    Anvil = true,
    Gunner = true,
}

M.SNIPER_NAMES = {
    Sentry = true,
}

function M.has_boss_template(model)
    if not model then return false end

    local ok, weld = pcall(function() return model:FindFirstChild("WeldObjects") end)
    if not ok or not weld then return false end

    local ok_mask, mask = pcall(function() return weld:FindFirstChild("Mask") end)
    return ok_mask and mask and mask.ClassName == "Model"
end

function M.read_attributes(model)
    local is_boss = false
    local is_sniper = false

    pcall(function()
        if model.GetAttribute then
            if model:GetAttribute("Boss") then is_boss = true end
            if model:GetAttribute("Sniper") or model:GetAttribute("IsSniper") then
                is_sniper = true
            end
        end
    end)

    return is_boss, is_sniper
end

function M.classify(model)
    if not model then return false, false end

    local is_boss, is_sniper = M.read_attributes(model)
    local name = model.Name or ""

    if not is_boss then
        if M.BOSS_NAMES[name] or M.has_boss_template(model) then
            is_boss = true
        end
    end

    if not is_boss then
        if M.SNIPER_NAMES[name] or name:find("Sniper", 1, true) then
            is_sniper = true
        end
    else
        is_sniper = false
    end

    return is_boss, is_sniper
end

function M.display_type(ent)
    if not ent then return nil end
    if ent.is_boss then return "Boss" end
    if ent.is_sniper then return "Sniper" end
    if ent.model and ent.model.Name == "Sentry" then return nil end
    return "Scav"
end

function M.combat_kind(ent)
    if not ent then return "soldier" end
    if ent.is_boss then return "boss" end
    if ent.is_sniper then return "sniper" end
    return "soldier"
end

return M

end)()

-- ── game/entity_scan.lua ──
July._mods["game.entity_scan"] = (function()
local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local havoc_sync = July.require("game.havoc_sync")
local npc_types = July.require("game.npc_types")
local env = July.require("core.env")

local M = {}

local entity_by_model = {}
local characters_folder = nil
local entity_cache = {}
local entity_cache_stamp = -9999
local entity_live_cursor = 1

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
            parts[child.Name] = child
            local ok_size, size = pcall(function() return child.Size end)
            sizes[child.Name] = ok_size and size or nil
        end
    end

    return parts, sizes
end

local function get_or_create_entity(model, root, humanoid)
    local entry = entity_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) and env.is_valid(entry.humanoid) then
            entry.root = root
            entry.humanoid = humanoid
            return entry
        end
        entity_by_model[model] = nil
    end

    local parts, part_sizes = collect_body_parts(model)
    local is_boss, is_sniper = npc_types.classify(model)

    entry = {
        model = model,
        root = root,
        humanoid = humanoid,
        parts = parts,
        part_size = part_sizes,
        scr_bounds = { x = 0, y = 0, w = 0, h = 0, valid = false },
        is_boss = is_boss,
        is_sniper = is_sniper,
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
    if characters_folder and not env.is_valid(characters_folder) then
        characters_folder = nil
    end

    local folder = havoc_sync.get_characters_folder()
    if folder then
        characters_folder = folder
        return folder
    end

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
    if not root then
        entity_cache = {}
        entity_by_model = {}
        return
    end

    local players = entity.GetPlayers()
    local out = {}
    collect_entities(root, players, out, 0)

    local new_by_model = {}
    for i = 1, #out do
        new_by_model[out[i].model] = out[i]
    end
    entity_by_model = new_by_model
    entity_cache = out
    if entity_live_cursor > #entity_cache then
        entity_live_cursor = 1
    end
end

local function get_held_weapon_name(model)
    if not model then return nil end

    local ok, model_children = pcall(function() return model:GetChildren() end)
    if ok and model_children then
        for i = 1, #model_children do
            local child = model_children[i]
            if child.ClassName == "Tool" then
                return child.Name
            end
        end
    end

    return nil
end

local HELD_EMPTY_CLEAR_TICKS = 45

local function refresh_held_name(ent)
    local new_held = get_held_weapon_name(ent.model)
    if new_held and new_held ~= "" then
        ent._held_name = new_held
        ent._held_empty_ticks = 0
        return
    end

    if ent._held_name then
        ent._held_empty_ticks = (ent._held_empty_ticks or 0) + 1
        if ent._held_empty_ticks >= HELD_EMPTY_CLEAR_TICKS then
            ent._held_name = nil
            ent._held_empty_ticks = 0
        end
    end
end

function M.refresh_live()
    local n = #entity_cache
    if n == 0 then return end

    if entity_live_cursor > n then entity_live_cursor = 1 end

    local batch = math.min(constants.ENTITY_LIVE_BATCH_SIZE or 16, n)
    for _ = 1, batch do
        local ent = entity_cache[entity_live_cursor]
        if ent and env.is_valid(ent.model) and env.is_valid(ent.root) and env.is_valid(ent.humanoid) then
            local ok_pos, pos = pcall(function() return ent.root.Position end)
            if ok_pos and pos then
                ent._live_pos = pos
                local px, py, pz = pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z
                if px then
                    ent._sx, ent._sy, ent._sok = utility.WorldToScreen(px, py, pz)
                end
            end
            local is_boss, is_sniper = npc_types.classify(ent.model)
            ent.is_boss = is_boss
            ent.is_sniper = is_sniper
            refresh_held_name(ent)
        end
        entity_live_cursor = entity_live_cursor + 1
        if entity_live_cursor > n then entity_live_cursor = 1 end
    end
end

function M.is_entry_valid(ent)
    return ent
        and env.is_valid(ent.model)
        and env.is_valid(ent.root)
        and env.is_valid(ent.humanoid)
end

function M.invalidate()
    characters_folder = nil
    entity_by_model = {}
    entity_cache = {}
    entity_cache_stamp = -9999
    entity_live_cursor = 1
    havoc_sync.reset()
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
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")
local havoc_sync = July.require("game.havoc_sync")

local M = {}

local loot_by_model = {}
local loot_cache = {}
local loot_cache_stamp = -9998
local drop_cache_stamp = -9996
local loot_live_cursor = 1
local buildings_folder = nil
local objects_folder = nil

local function vec3(pos)
    if not pos then return nil end
    return {
        X = pos.X or pos.x or 0,
        Y = pos.Y or pos.y or 0,
        Z = pos.Z or pos.z or 0,
    }
end

local function collect_model_parts(model, part_pos, part_size, depth)
    if depth > 4 then return end
    local ok, children = pcall(function() return model:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()
        local child = children[i]
        local cls = child.ClassName
        if cls == "Part" or cls == "MeshPart" then
            local ok_pos, pos = pcall(function() return child.Position end)
            local ok_size, size = pcall(function() return child.Size end)
            if ok_pos and pos then
                part_pos[child] = vec3(pos)
                part_size[child] = ok_size and size or nil
            end
        elseif cls == "Model" or cls == "Folder" then
            collect_model_parts(child, part_pos, part_size, depth + 1)
        end
    end
end

local function get_loot_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local loot_type = data:FindFirstChild("lootType")
    local is_open = data:FindFirstChild("isOpen")
    local is_locked = data:FindFirstChild("isLocked")
    if not (loot_type and is_open and is_locked) then return nil end

    local type_str = nil
    pcall(function()
        type_str = loot_type.Value
    end)

    return type_str, is_open, is_locked
end

local function get_door_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local is_open = data:FindFirstChild("isOpen")
    if not is_open then return nil end

    local is_locked = data:FindFirstChild("isLocked")
        or data:FindFirstChild("isKeyRequired")
        or data:FindFirstChild("lockable")

    return is_open, is_locked
end

local function get_or_create_loot(model, root, category, is_open_inst, is_locked_inst)
    local entry = loot_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) then
            entry.category = category or entry.category
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)
    local part_pos, part_size = {}, {}
    collect_model_parts(model, part_pos, part_size, 0)

    entry = {
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
        part_pos = part_pos,
        part_size = part_size,
        is_open_inst = is_open_inst,
        is_locked_inst = is_locked_inst,
        is_open = nil,
        is_locked = nil,
        category = category,
    }
    loot_by_model[model] = entry
    return entry
end

local function is_equipped_tool(tool)
    local parent = tool.Parent
    local depth = 0
    while parent and depth < 8 do
        if parent.ClassName == "Model" then
            local hum = parent:FindFirstChildOfClass("Humanoid")
            if hum then return true end
        end
        parent = parent.Parent
        depth = depth + 1
    end
    return false
end

local function string_value(inst, name)
    if not inst then return nil end
    local ref = inst:FindFirstChild(name)
    if not ref or ref.ClassName ~= "StringValue" then return nil end
    local ok, value = pcall(function() return ref.Value end)
    if ok and value and value ~= "" then
        return value
    end
    return nil
end

local function is_descendant_of(inst, ancestor)
    if not inst or not ancestor or not env.is_valid(inst) or not env.is_valid(ancestor) then
        return false
    end
    local ok, result = pcall(function() return inst:IsDescendantOf(ancestor) end)
    return ok and result == true
end

local function is_player_owned(inst)
    local lp = env.get_local_player()
    if not lp or not inst then return false end

    local char = lp.Character or lp.character
    if char and is_descendant_of(inst, char) then return true end

    local backpack = lp.Backpack or lp.backpack
    if backpack and is_descendant_of(inst, backpack) then return true end

    if game and game.ReplicatedStorage then
        local storage = game.ReplicatedStorage:FindFirstChild("Storage")
        if storage then
            local grid_storage = storage:FindFirstChild("GridItemStorage")
            if grid_storage and is_descendant_of(inst, grid_storage) then
                return true
            end
        end
    end

    return false
end

local function is_character_ancestor(inst)
    if not inst or not env.is_valid(inst) then return false end

    local chars = havoc_sync.get_characters_folder()
    if chars and is_descendant_of(inst, chars) then return true end

    local lp = env.get_local_player()
    if lp then
        local char = lp.Character or lp.character
        if char and is_descendant_of(inst, char) then return true end
    end

    if entity and entity.GetPlayers then
        local ok, players = pcall(function() return entity.GetPlayers() end)
        if ok and players then
            for i = 1, #players do
                local p = players[i]
                local char = p.Character or p.character
                if char and is_descendant_of(inst, char) then return true end
            end
        end
    end

    local cur = inst
    local depth = 0
    while cur and depth < 12 do
        if cur.ClassName == "Model" then
            local hum = cur:FindFirstChildOfClass("Humanoid")
            if hum then return true end
        end
        cur = cur.Parent
        depth = depth + 1
    end

    return false
end

local function is_weld_pool(inst)
    if not inst or not env.is_valid(inst) then return false end

    local ws = env.get_workspace()
    if not ws then return false end

    local ignored = ws:FindFirstChild("Ignored")
    if ignored then
        local temp = ignored:FindFirstChild("_weldobjects.temp")
        if temp and is_descendant_of(inst, temp) then return true end
    end

    local pool_names = { "_weldobjects.temp", "_weldobjects.temp.others" }
    for i = 1, #pool_names do
        local pool = ws:FindFirstChild(pool_names[i])
        if pool and is_descendant_of(inst, pool) then return true end
    end

    return false
end

local function has_equipped_link(inst)
    if not inst then return false end
    local cur = inst
    local depth = 0
    while cur and depth < 10 do
        if cur.ClassName == "Model" or cur.ClassName == "Folder" then
            local link = cur:FindFirstChild("linkItemFolder")
            if link and link.ClassName == "ObjectValue" then
                return true
            end
        end
        cur = cur.Parent
        depth = depth + 1
    end
    return false
end

local function object_value_target(inst, name)
    if not inst then return nil end
    local ref = inst:FindFirstChild(name)
    if not ref or ref.ClassName ~= "ObjectValue" then return nil end
    local ok, value = pcall(function() return ref.Value end)
    if ok and value and env.is_valid(value) then
        return value
    end
    return nil
end

local function resolve_drop_name(inst)
    if not inst then return nil end

    local cur = inst
    local depth = 0
    while cur and depth < 10 do
        local display = string_value(cur, "name")
        if display and display ~= "" then
            if tier_util.is_known_item(display) or tier_util.is_gun_name(display) or tier_util.is_keycard(display) then
                return display
            end
            if not tier_util.is_known_item(cur.Name) then
                return display
            end
        end

        local name = cur.Name
        if tier_util.is_known_item(name) then
            return name
        end

        local tool = object_value_target(cur, "itemTool")
        if tool and tier_util.is_known_item(tool.Name) then
            return tool.Name
        end
        if tool and tool.Name and tool.Name ~= "" then
            return tool.Name
        end

        if cur.ClassName == "Tool" and name and name ~= "" then
            return name
        end

        cur = cur.Parent
        depth = depth + 1
    end

    return nil
end

local function resolve_drop_root(inst)
    if not inst or not env.is_valid(inst) then return nil end

    if inst.ClassName == "Tool" then
        return inst:FindFirstChild("Handle")
    end

    if inst.ClassName == "Part" or inst.ClassName == "MeshPart" then
        return inst
    end

    local weld_model = object_value_target(inst, "currentWeldModel")
    if weld_model then
        local root = weld_model.PrimaryPart
        if not root then
            root = weld_model:FindFirstChildWhichIsA("BasePart")
        end
        if root then return root end
    end

    local tool = object_value_target(inst, "itemTool")
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then return handle end
    end

    if inst.ClassName == "Model" then
        local root = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if root then return root end
    end

    if inst.ClassName == "Folder" then
        local ok, children = pcall(function() return inst:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Model" then
                    local root = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                    if root then return root end
                elseif child.ClassName == "Part" or child.ClassName == "MeshPart" then
                    return child
                end
            end
        end
    end

    return nil
end

local function is_grid_item_folder(inst)
    if not inst or inst.ClassName ~= "Folder" then return false end
    return inst:FindFirstChild("itemType") ~= nil
        or inst:FindFirstChild("itemTool") ~= nil
        or inst:FindFirstChild("name") ~= nil
        or inst:FindFirstChild("currentWeldModel") ~= nil
end

local function get_weld_temp_folder()
    local ws = env.get_workspace()
    if not ws then return nil end

    local ignored = ws:FindFirstChild("Ignored")
    if ignored then
        local weld = ignored:FindFirstChild("_weldobjects.temp")
        if weld then return weld end
    end

    return ws:FindFirstChild("_weldobjects.temp")
end

local function get_grid_item_folder()
    if not game or not game.ReplicatedStorage then return nil end
    local storage = game.ReplicatedStorage:FindFirstChild("Storage")
    if not storage then return nil end
    return storage:FindFirstChild("GridItemFolder")
end

local function get_buildings_folder()
    if buildings_folder and not env.is_valid(buildings_folder) then
        buildings_folder = nil
        objects_folder = nil
    end
    if not buildings_folder then
        local ws = env.get_workspace()
        if ws then
            buildings_folder = env.safe_call(function()
                if ws.FindFirstChild then return ws:FindFirstChild("Buildings") end
                return nil
            end)
        end
    end
    return buildings_folder
end

local function get_objects_folder()
    local buildings = get_buildings_folder()
    if not buildings then return nil end

    if not objects_folder or not env.is_valid(objects_folder) then
        objects_folder = buildings:FindFirstChild("Objects")
    end
    return objects_folder
end

local function is_world_drop_weld(model)
    if not model or not env.is_valid(model) then return false end
    if is_player_owned(model) then return false end
    if is_character_ancestor(model) then return false end
    if is_weld_pool(model) then return false end

    local objects = get_objects_folder()
    if objects and is_descendant_of(model, objects) then return true end

    return false
end

local function should_skip_drop_inst(inst)
    if not env.is_valid(inst) then return true end

    if is_character_ancestor(inst) then return true end
    if is_weld_pool(inst) then return true end

    if inst.ClassName == "Tool" and is_equipped_tool(inst) then
        return true
    end

    local ok, flag = pcall(function()
        return inst:GetAttribute("isDealer") == true
            or inst:GetAttribute("isQuestGiver") == true
            or inst:GetAttribute("stashName") ~= nil
    end)
    if ok and flag then return true end

    if has_equipped_link(inst) and not is_world_drop_weld(inst) then
        return true
    end

    if inst.ClassName == "Model" then
        local type_str = get_loot_info(inst)
        if type_str then return true end
    end

    return false
end

local function is_drop_candidate(inst)
    if should_skip_drop_inst(inst) then return false end
    if is_player_owned(inst) then return false end

    local cls = inst.ClassName
    if cls == "Tool" then
        return inst:FindFirstChild("Handle") ~= nil
    end

    if cls == "Model" and inst:FindFirstChildOfClass("Humanoid") then
        return false
    end

    if is_grid_item_folder(inst) then
        local weld = object_value_target(inst, "currentWeldModel")
        if weld and not is_world_drop_weld(weld) then
            return false
        end
        return resolve_drop_name(inst) ~= nil
            or object_value_target(inst, "itemTool") ~= nil
            or weld ~= nil
    end

    if cls == "Model" or cls == "Folder" then
        local weld = object_value_target(inst, "currentWeldModel")
        if weld and not is_world_drop_weld(weld) then
            return false
        end
        local name = resolve_drop_name(inst)
        if name then return true end
        return object_value_target(inst, "itemTool") ~= nil or weld ~= nil
    end

    if cls == "Part" or cls == "MeshPart" then
        return resolve_drop_name(inst) ~= nil
    end

    return false
end

local function categorize_drop(name)
    if tier_util.is_keycard(name) then
        return loot_catalog.TYPE_MAP["drop.keycard"]
    end
    if tier_util.is_gun_name(name) then
        return loot_catalog.TYPE_MAP["drop.gun"]
    end
    return loot_catalog.TYPE_MAP["drop.item"]
end

local function get_or_create_drop(model, root, category, display_name)
    local entry = loot_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) then
            entry.category = category or entry.category
            entry.display_name = display_name
            entry.tier_color = tier_util.get_esp_color(display_name)
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)
    local part_pos, part_size = {}, {}
    if model.ClassName == "Model" or model.ClassName == "Folder" then
        collect_model_parts(model, part_pos, part_size, 0)
    end

    entry = {
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
        part_pos = next(part_pos) and part_pos or nil,
        part_size = next(part_size) and part_size or nil,
        is_open_inst = nil,
        is_locked_inst = nil,
        is_open = nil,
        is_locked = nil,
        category = category,
        display_name = display_name,
        tier_color = tier_util.get_esp_color(display_name),
        is_drop = true,
    }
    loot_by_model[model] = entry
    return entry
end

local function register_drop_instance(inst, out, seen)
    if seen[inst] or not is_drop_candidate(inst) then return end

    local name = resolve_drop_name(inst)
    if not name or name == "" then
        if inst.ClassName == "Tool" then
            name = inst.Name
        else
            local tool = object_value_target(inst, "itemTool")
            if tool then name = tool.Name end
        end
    end
    if not name or name == "" then return end

    local root = resolve_drop_root(inst)
    if not root or not env.is_valid(root) then return end

    seen[inst] = true
    local category = categorize_drop(name)
    out[#out + 1] = get_or_create_drop(inst, root, category, name)
end

local function collect_drops_from_list(instances, out, seen)
    for i = 1, #instances do
        scan_yield.yield()
        local inst = instances[i]
        if not inst or not env.is_valid(inst) then goto continue_drop end

        local cls = inst.ClassName
        if cls == "Tool" or cls == "Model" or cls == "Folder" or cls == "Part" or cls == "MeshPart" then
            register_drop_instance(inst, out, seen)
        end

        ::continue_drop::
    end
end

local function collect_drops(container, out, seen, depth)
    if depth > constants.DROP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Tool" or cls == "Model" or cls == "Folder" or cls == "Part" or cls == "MeshPart" then
            register_drop_instance(child, out, seen)
        end

        if cls == "Model" or cls == "Folder" or cls == "WorldModel" then
            collect_drops(child, out, seen, depth + 1)
        end
    end
end

local function collect_objects_drops_deep(out, seen)
    local folder = get_objects_folder()
    if folder and env.is_valid(folder) then
        local ok, descendants = pcall(function() return folder:GetDescendants() end)
        if ok and descendants and #descendants > 0 then
            collect_drops_from_list(descendants, out, seen)
        else
            collect_drops(folder, out, seen, 0)
        end
    end

    local grid_folder = get_grid_item_folder()
    if grid_folder and env.is_valid(grid_folder) then
        local ok, children = pcall(function() return grid_folder:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                scan_yield.yield()
                local child = children[i]
                if child.ClassName == "Folder" then
                    local weld = object_value_target(child, "currentWeldModel")
                    if weld and is_world_drop_weld(weld) then
                        register_drop_instance(child, out, seen)
                    end
                end
            end
        end
    end
end

local function collect_objects_drops(out, seen)
    collect_objects_drops_deep(out, seen)
end

local function append_preserved_drops(out)
    for i = 1, #loot_cache do
        local entry = loot_cache[i]
        if entry.is_drop and env.is_valid(entry.model) and env.is_valid(entry.root) then
            out[#out + 1] = entry
        end
    end
end

local function merge_drop_cache(new_drops)
    local kept = {}
    for i = 1, #loot_cache do
        if not loot_cache[i].is_drop then
            kept[#kept + 1] = loot_cache[i]
        end
    end
    for i = 1, #new_drops do
        kept[#kept + 1] = new_drops[i]
    end

    local new_by_model = {}
    for i = 1, #kept do
        new_by_model[kept[i].model] = kept[i]
    end
    loot_by_model = new_by_model
    loot_cache = kept
    if loot_live_cursor > #loot_cache then
        loot_live_cursor = 1
    end
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
            local type_str, is_open, is_locked = get_loot_info(child)
            if is_open then
                local category = loot_catalog.resolve(type_str, child.Name)
                if category then
                    local root = child:FindFirstChildWhichIsA("BasePart")
                    if root then
                        out[#out + 1] = get_or_create_loot(child, root, category, is_open, is_locked)
                    end
                end
            else
                collect_loot(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_loot(child, out, depth + 1)
        end
    end
end

local function collect_doors(container, out, depth)
    if depth > constants.LOOT_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" then
            local is_open, is_locked = get_door_info(child)
            if is_open then
                local category = loot_catalog.resolve(nil, child.Name)
                if category then
                    local root = child:FindFirstChildWhichIsA("BasePart")
                    if root then
                        out[#out + 1] = get_or_create_loot(child, root, category, is_open, is_locked)
                    end
                end
            else
                collect_doors(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_doors(child, out, depth + 1)
        end
    end
end

local function collect_body_models(container, out)
    local ok, children = pcall(function() return container:GetChildren() end)
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

local function collect_body_bags(buildings, out)
    local loots1 = buildings:FindFirstChild("Loots")
    if not loots1 then return end

    local bodies = loots1:FindFirstChild("Bodies")
    if bodies then
        collect_body_models(bodies, out)
    end

    local loots2 = loots1:FindFirstChild("Loots")
    if not loots2 then return end

    local characters = loots2:FindFirstChild("Characters")
    if characters then
        collect_body_models(characters, out)
    end
end

local function collect_buildings_loot(buildings, out)
    local top_loots = buildings:FindFirstChild("Loots")
    if top_loots then
        collect_loot(top_loots, out, 0)

        local doors = top_loots:FindFirstChild("Doors")
        if doors then
            collect_doors(doors, out, 0)
        end

        local interactable = top_loots:FindFirstChild("Interactable")
        if interactable then
            collect_doors(interactable, out, 0)
        end
    end

    local ok, children = pcall(function() return buildings:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child ~= top_loots then
                local loots = child:FindFirstChild("Loots")
                if loots then
                    collect_loot(loots, out, 0)
                end
            end
        end
    end
end

function M.refresh(force)
    local now = os.clock()
    local interval = buildings_folder and constants.LOOT_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if not force and (now - loot_cache_stamp) < interval then return end
    loot_cache_stamp = now

    local out = {}
    local buildings = get_buildings_folder()
    if buildings then
        collect_buildings_loot(buildings, out)
        collect_body_bags(buildings, out)
    end

    append_preserved_drops(out)

    local new_by_model = {}
    for i = 1, #out do
        new_by_model[out[i].model] = out[i]
    end
    loot_by_model = new_by_model
    loot_cache = out
    if loot_live_cursor > #loot_cache then
        loot_live_cursor = 1
    end
end

function M.refresh_drops(force)
    local now = os.clock()
    if not force and (now - drop_cache_stamp) < constants.DROP_SCAN_INTERVAL then return end
    drop_cache_stamp = now

    local out = {}
    local seen = {}
    collect_objects_drops(out, seen)
    merge_drop_cache(out)
end

function M.refresh_live()
    local n = #loot_cache
    if n == 0 then return end

    if loot_live_cursor > n then loot_live_cursor = 1 end

    local prune_batch = 6
    local pruned = 0
    while pruned < prune_batch and n > 0 do
        if loot_live_cursor > n then loot_live_cursor = 1 end
        local loot = loot_cache[loot_live_cursor]
        if not loot or not env.is_valid(loot.model) or not env.is_valid(loot.root) then
            if loot and loot.model then
                loot_by_model[loot.model] = nil
            end
            loot_cache[loot_live_cursor] = loot_cache[n]
            loot_cache[n] = nil
            n = n - 1
        else
            loot_live_cursor = loot_live_cursor + 1
        end
        pruned = pruned + 1
    end

    local remaining = math.min(constants.LOOT_LIVE_BATCH_SIZE, n)
    while remaining > 0 do
        local loot = loot_cache[loot_live_cursor]
        if loot and env.is_valid(loot.model) and env.is_valid(loot.root) then
            if loot.is_drop then
                local root = resolve_drop_root(loot.model) or loot.root
                if root and env.is_valid(root) then
                    loot.root = root
                end
                local ok_pos, pos = pcall(function() return loot.root.Position end)
                if ok_pos and pos then
                    loot.pos = vec3(pos)
                end
            elseif loot.is_open_inst and env.is_valid(loot.is_open_inst) then
                local ok, is_open_val = pcall(function()
                    return loot.is_open_inst.Value
                end)
                if ok then
                    loot.is_open = is_open_val
                end
                if loot.is_locked_inst and env.is_valid(loot.is_locked_inst) then
                    local ok2, is_locked_val = pcall(function()
                        return loot.is_locked_inst.Value
                    end)
                    if ok2 then
                        loot.is_locked = is_locked_val
                    end
                end
            end
            if not loot.is_drop then
                local ok_pos, pos = pcall(function() return loot.root.Position end)
                if ok_pos and pos then
                    loot.pos = vec3(pos)
                end
            end
        end

        loot_live_cursor = loot_live_cursor + 1
        if loot_live_cursor > n then loot_live_cursor = 1 end
        remaining = remaining - 1
    end
end

local static_co = nil
local drops_co = nil

function M.invalidate()
    buildings_folder = nil
    objects_folder = nil
    loot_by_model = {}
    loot_cache = {}
    loot_cache_stamp = -9998
    drop_cache_stamp = -9996
    loot_live_cursor = 1
    static_co = nil
    drops_co = nil
end

function M.queue_refresh()
    if static_co and coroutine.status(static_co) ~= "dead" then return end
    static_co = coroutine.create(function()
        M.refresh(true)
    end)
end

function M.queue_refresh_drops()
    if drops_co and coroutine.status(drops_co) ~= "dead" then return end
    drops_co = coroutine.create(function()
        M.refresh_drops(true)
    end)
end

function M.tick_async(budget_ms)
    local scan_async = July.require("core.scan_async")
    budget_ms = budget_ms or constants.SCAN_BUDGET_MS or 4

    if static_co and scan_async.tick(static_co, budget_ms) then
        static_co = nil
    end
    if drops_co and scan_async.tick(drops_co, budget_ms) then
        drops_co = nil
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
local env = July.require("core.env")

local M = {}

local trap_cache = {}
local trap_cache_stamp = -9997
local trap_folders_found = false
local trap_live_cursor = 1

local IGNORED_FOLDER = nil
local EVENT_OBJECTS_FOLDER = nil
local ENV_INTERACTABLE_FOLDER = nil

local function get_buildings_folder()
    local ws = env.get_workspace()
    if not ws then return nil end
    return env.safe_call(function()
        if ws.FindFirstChild then return ws:FindFirstChild("Buildings") end
        return nil
    end)
end

local function get_ignored_folder()
    if IGNORED_FOLDER and not env.is_valid(IGNORED_FOLDER) then
        IGNORED_FOLDER = nil
    end
    if not IGNORED_FOLDER then
        local ws = env.get_workspace()
        if ws then
            IGNORED_FOLDER = env.safe_call(function()
                if ws.FindFirstChild then return ws:FindFirstChild("Ignored") end
                return nil
            end)
        end
    end
    return IGNORED_FOLDER
end

local function get_event_objects_folder()
    if EVENT_OBJECTS_FOLDER and not env.is_valid(EVENT_OBJECTS_FOLDER) then
        EVENT_OBJECTS_FOLDER = nil
    end
    if not EVENT_OBJECTS_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            EVENT_OBJECTS_FOLDER = buildings:FindFirstChild("EventObjects")
        end
        if not EVENT_OBJECTS_FOLDER then
            local ws = env.get_workspace()
            if ws then
                EVENT_OBJECTS_FOLDER = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild("EventObjects") end
                    return nil
                end)
            end
        end
    end
    return EVENT_OBJECTS_FOLDER
end

local function get_env_interactable_folder()
    if ENV_INTERACTABLE_FOLDER and not env.is_valid(ENV_INTERACTABLE_FOLDER) then
        ENV_INTERACTABLE_FOLDER = nil
    end
    if not ENV_INTERACTABLE_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            ENV_INTERACTABLE_FOLDER = buildings:FindFirstChild("EnvInteractable")
        end
        if not ENV_INTERACTABLE_FOLDER then
            local ws = env.get_workspace()
            if ws then
                ENV_INTERACTABLE_FOLDER = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild("EnvInteractable") end
                    return nil
                end)
            end
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
        if child.ClassName == "Folder" and child.Name:find("Tripmine", 1, true) then
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

function M.refresh(force)
    local interval = trap_folders_found and constants.TRAP_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL

    local now = os.clock()
    if not force and (now - trap_cache_stamp) < interval then return end
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
    trap_cache = out
    if trap_live_cursor > #trap_cache then
        trap_live_cursor = 1
    end
end

function M.refresh_live()
    local n = #trap_cache
    if n == 0 then return end

    local batch = constants.TRAP_LIVE_BATCH or 10
    local checked = 0

    while checked < batch and n > 0 do
        if trap_live_cursor > n then trap_live_cursor = 1 end

        local trap = trap_cache[trap_live_cursor]
        if not trap or not env.is_valid(trap.root) or not env.is_valid(trap.model) then
            trap_cache[trap_live_cursor] = trap_cache[n]
            trap_cache[n] = nil
            n = n - 1
        else
            if trap.extra and not env.is_valid(trap.extra) then
                trap.extra = nil
            end
            trap_live_cursor = trap_live_cursor + 1
        end
        checked = checked + 1
    end
end

local refresh_co = nil

function M.queue_refresh()
    if refresh_co and coroutine.status(refresh_co) ~= "dead" then return end
    refresh_co = coroutine.create(function()
        M.refresh(true)
    end)
end

function M.tick_async(budget_ms)
    local scan_async = July.require("core.scan_async")
    budget_ms = budget_ms or constants.SCAN_BUDGET_MS or 4
    if refresh_co and scan_async.tick(refresh_co, budget_ms) then
        refresh_co = nil
    end
end

function M.invalidate()
    trap_cache = {}
    trap_cache_stamp = -9997
    trap_folders_found = false
    trap_live_cursor = 1
    refresh_co = nil
    IGNORED_FOLDER = nil
    EVENT_OBJECTS_FOLDER = nil
    ENV_INTERACTABLE_FOLDER = nil
end

function M.get_cache()
    return trap_cache
end

return M

end)()

-- ── core/esp_scheduler.lua ──
July._mods["core.esp_scheduler"] = (function()
local settings = July.require("core.settings")
local constants = July.require("core.constants")
local cache = July.require("core.cache")

local M = {}

local last = {
    entity = 0,
    loot = 0,
    drops = 0,
    trap = 0,
    live = 0,
}

local function now()
    return os.clock()
end

local function combat_active()
    return settings.enabled("july_silent_aim")
        or settings.enabled("havoc_aimbot_enabled")
end

local function any_world_esp()
    return settings.enabled("havoc_loot_enabled")
        or settings.enabled("havoc_trap_enabled")
end

local function any_npc_esp()
    return settings.enabled("havoc_npc_enabled")
end

function M.tick(frame_counter)
    frame_counter = frame_counter or 0
    local t = now()
    local fast = combat_active()
    local entity_scan = July.require("game.entity_scan")
    local loot_scan = July.require("game.loot_scan")
    local trap_scan = July.require("game.trap_scan")
    local scan_budget = constants.SCAN_BUDGET_MS or 4

    if any_npc_esp() then
        local entity_iv = fast and 0.5 or constants.ENTITY_SCAN_INTERVAL
        if t - last.entity >= entity_iv then
            last.entity = t
            entity_scan.refresh()
        end
    end

    if any_world_esp() then
        if t - last.loot >= constants.LOOT_SCAN_INTERVAL then
            last.loot = t
            loot_scan.queue_refresh()
        end
        local drop_iv = fast and 0.5 or constants.DROP_SCAN_INTERVAL
        if t - last.drops >= drop_iv then
            last.drops = t
            loot_scan.queue_refresh_drops()
        end
        loot_scan.tick_async(scan_budget)
    end

    if settings.enabled("havoc_trap_enabled") then
        if t - last.trap >= constants.TRAP_SCAN_INTERVAL then
            last.trap = t
            trap_scan.queue_refresh()
        end
        trap_scan.tick_async(scan_budget)
    end

    local live_iv = fast and 0.08 or 0.18
    if t - last.live >= live_iv then
        last.live = t
        if any_npc_esp() then
            entity_scan.refresh_live()
        end
        if any_world_esp() then
            loot_scan.refresh_live()
        end
        if settings.enabled("havoc_trap_enabled") then
            trap_scan.refresh_live()
        end
    end
end

function M.reset()
    last.entity = 0
    last.loot = 0
    last.drops = 0
    last.trap = 0
    last.live = 0
    cache.reset()
end

return M

end)()

-- ── core/esp_render.lua ──
July._mods["core.esp_render"] = (function()
local M = {}

function M.screen_size()
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    if input and input.GetScreenSize then
        return input.GetScreenSize()
    end
    return 1920, 1080
end

function M.on_screen(sx, sy, pad)
    pad = pad or 48
    local sw, sh = M.screen_size()
    return sx >= -pad and sx <= sw + pad and sy >= -pad and sy <= sh + pad
end

function M.w2s(x, y, z)
    if utility and utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if draw and draw.world_to_screen then
        return draw.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

function M.pick_closest(entries, budget)
    budget = budget or #entries
    if #entries <= budget then
        return entries
    end
    table.sort(entries, function(a, b)
        return a.dist < b.dist
    end)
    local out = {}
    for i = 1, budget do
        out[i] = entries[i]
    end
    return out
end

return M

end)()

-- ── game/gc_weapon_mods.lua ──
July._mods["game.gc_weapon_mods"] = (function()
--[[ Havoc weapon mods — refreshgc → getgc(keys) → applygc(keys, values)
     Keys match weapon config tables from dump (M4A1.lua etc.) ]]

local env = July.require("core.env")

local M = {}

M.WEAPON_FIND_KEYS = {
    "vPunchBase",
    "hPunchBase",
    "dPunchBase",
    "recoilPunch",
    "minRecoilPower",
    "maxRecoilPower",
    "recoilReduce",
    "spreadReduce",
    "aimWeight",
    "unAimWeight",
    "vel",
}

M.PATCHES = {
    havoc_no_recoil = {
        vPunchBase = 0,
        hPunchBase = 0,
        dPunchBase = 0,
        recoilPunch = 0,
        minRecoilPower = 0,
        maxRecoilPower = 0,
        recoilReduce = 1,
    },
    havoc_no_spread = {
        spreadReduce = 1,
    },
    havoc_no_sway = {
        aimWeight = 0,
        unAimWeight = 0,
    },
    havoc_fast_vel = {
        vel = 5000,
    },
}

M._last_node_count = 0

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end

function M.available()
    return has_api()
end

function M.last_node_count()
    return M._last_node_count
end

function M.in_game()
    return env.get_local_player() ~= nil
end

local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    if count <= 0 then
        ok, result = pcall(getgc, M.WEAPON_FIND_KEYS)
        if ok and type(result) == "number" then
            count = result
        end
    end
    return count
end

local function patch_count(keys, payload)
    local patched = 0

    local ok, result = pcall(applygc, keys, payload)
    if ok and type(result) == "number" then
        patched = result
    end

    if patched <= 0 then
        ok, result = pcall(applygc, M.WEAPON_FIND_KEYS, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    if patched <= 0 then
        ok, result = pcall(applygc, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    return patched
end

function M.warm()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    pcall(refreshgc)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end

function M.apply_enabled(enabled_ids)
    if not has_api() then
        return false, 0
    end

    if not M.in_game() then
        return false, 0
    end

    pcall(refreshgc)
    warm_nodes(M.WEAPON_FIND_KEYS)

    local patched = 0
    for i = 1, #enabled_ids do
        local patch = M.PATCHES[enabled_ids[i]]
        if patch then
            local keys = {}
            for k in pairs(patch) do
                keys[#keys + 1] = k
            end
            table.sort(keys)
            patched = patched + patch_count(keys, patch)
        end
    end

    M._last_node_count = math.max(M._last_node_count, patched, warm_nodes(M.WEAPON_FIND_KEYS))
    return patched > 0, patched
end

return M

end)()

-- ── features/combat/combat_menu.lua ──
July._mods["features.combat.combat_menu"] = (function()
local M = {}

local hitparts = July.require("game.hitparts")

M.SILENT_BONES = hitparts.LABELS
M.BONE_MAP = hitparts.MAP

function M.bone_from_index(idx)
    return hitparts.label_from_index(idx)
end

function M.register_silent_aim(TAB, GROUP, prefix, parent_id)
    local root = { parent = parent_id }

    menu.add_combo(TAB, GROUP, prefix .. "target_type", "Silent Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(TAB, GROUP, prefix .. "bone", "Silent Target Hitbox", M.SILENT_BONES, 1, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "lmb_only", "Silent Active on LMB Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "rmb_only", "Silent Active on RMB Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_health", "Silent Health Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_visible", "Silent Visible Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_team", "Silent Team Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_players", "Silent Target Players", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npcs", "Silent Target NPCs", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_soldiers", "Silent Soldier Targets", true, { parent = prefix .. "target_npcs" })
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_bosses", "Silent Boss Targets", true, { parent = prefix .. "target_npcs" })
    menu.add_slider_int(TAB, GROUP, prefix .. "max_dist", "Silent Max Distance", 50, 2000, 500, root)
    menu.add_slider_int(TAB, GROUP, prefix .. "fov", "Silent FOV Radius", 20, 600, 150, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "sticky", "Silent Sticky Target", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "wallbang", "Silent Wallbang", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_tp", "Silent Bullet TP", false, root)
    menu.add_combo(TAB, GROUP, prefix .. "tp_ray_mode", "Silent TP Ray Mode",
        { "Direct", "Snap", "Deep", "Curve", "Arch" }, 0, { parent = prefix .. "bullet_tp" })
    menu.add_checkbox(TAB, GROUP, prefix .. "tp_ray_vis", "Silent Ray Path", false, {
        parent = prefix .. "bullet_tp",
        colorpicker = { 0.95, 0.45, 1.0, 0.9 },
    })
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_manip", "Silent Bullet Manip", false, root)
    menu.add_slider_float(TAB, GROUP, prefix .. "manip_dist", "Silent Manip Distance", 0.1, 5.0, 1.0, "%.1f", { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_status", "Silent Manip Status", false, { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_ring", "Silent Manip Ring", false, { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_peek_vis", "Silent Manip Peek", true, { parent = prefix .. "bullet_manip" })
end

return M

end)()

-- ── menu/menu_defs.lua ──
July._mods["menu.menu_defs"] = (function()
local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")
local combat_menu = July.require("features.combat.combat_menu")
local menu_util = July.require("core.menu_util")

local M = {}
M.TAB = constants.TAB

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB
    local G = menu_util.G
    local P_AIM = "havoc_aimbot_enabled"
    local P_SILENT = "july_silent_aim"
    local P_WEAPON = "havoc_weapon_mods_enabled"
    local P_NPC = "havoc_npc_enabled"
    local P_LOOT = "havoc_loot_enabled"
    local P_TRAP = "havoc_trap_enabled"
    local S = "july_silent_"

    menu_util.ensure_groups()

    -- Row 1: Aimbot | Silent Aim
    menu.add_checkbox(TAB, G.AIMBOT, P_AIM, "Enable Aimbot", false, { show_mode = false, key = 2 })
    menu.add_combo(TAB, G.AIMBOT, "havoc_aimbot_bone", "Aimbot Target Bone", combat_menu.SILENT_BONES, 1, { parent = P_AIM })
    menu.add_combo(TAB, G.AIMBOT, "havoc_aimbot_target_type", "Aimbot Priority", { "Crosshair", "Distance" }, 0, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_fov", "Aimbot FOV Radius", 10, 500, 150, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_max_distance", "Aimbot Max Distance", 0, 3000, 3000, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_smooth", "Aimbot Smoothness", 1, 100, 8, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_sticky", "Aimbot Sticky Target", false, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_players", "Aimbot Target Players", false, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_npcs", "Aimbot Target NPCs", true, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_draw_fov", "Aimbot FOV Circle", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 1.0 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_fill_fov", "Aimbot Fill FOV", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 0.15 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_line", "Aimbot Target Line", false, {
        parent = P_AIM, colorpicker = { 1.0, 0.3, 0.3, 1.0 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_rainbow", "Aimbot Rainbow", false, { parent = P_AIM })

    menu_util.bind_children(P_AIM, {
        "havoc_aimbot_bone", "havoc_aimbot_target_type", "havoc_aimbot_fov", "havoc_aimbot_max_distance",
        "havoc_aimbot_smooth", "havoc_aimbot_sticky", "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
        "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
    })

    menu.add_checkbox(TAB, G.SILENT, P_SILENT, "Enable Silent Aim", false, { show_mode = false })
    combat_menu.register_silent_aim(TAB, G.SILENT, S, P_SILENT)
    menu.add_checkbox(TAB, G.SILENT, "july_silent_draw_fov", "Silent FOV Circle", false, {
        parent = P_SILENT, colorpicker = { 0.55, 0.2, 1.0, 1.0 },
    })
    menu.add_combo(TAB, G.SILENT, "july_silent_fov_style", "Silent FOV Style", { "Outline", "Filled Circle" }, 1, { parent = P_SILENT })
    menu.add_checkbox(TAB, G.SILENT, "july_silent_target_line", "Silent Target Line", false, {
        parent = P_SILENT, colorpicker = { 1.0, 0.25, 0.25, 1.0 },
    })
    menu.add_checkbox(TAB, G.SILENT, "july_silent_rainbow", "Silent Rainbow", false, { parent = P_SILENT })

    menu_util.bind_children(P_SILENT, {
        S .. "target_type", S .. "bone", S .. "lmb_only", S .. "rmb_only",
        S .. "filter_health", S .. "filter_visible", S .. "filter_team",
        S .. "target_players", S .. "target_npcs", S .. "target_npc_soldiers", S .. "target_npc_bosses",
        S .. "max_dist", S .. "fov", S .. "sticky",
        S .. "wallbang", S .. "bullet_tp", S .. "tp_ray_mode", S .. "tp_ray_vis",
        S .. "bullet_manip", S .. "manip_dist", S .. "manip_status", S .. "manip_ring", S .. "manip_peek_vis",
        "july_silent_draw_fov", "july_silent_fov_style", "july_silent_target_line", "july_silent_rainbow",
    })
    menu_util.bind_children(S .. "target_npcs", { S .. "target_npc_soldiers", S .. "target_npc_bosses" })
    menu_util.bind_children(S .. "bullet_tp", { S .. "tp_ray_mode", S .. "tp_ray_vis" })
    menu_util.bind_children(S .. "bullet_manip", { S .. "manip_dist", S .. "manip_status", S .. "manip_ring", S .. "manip_peek_vis" })

    -- Row 2: NPC Visuals | World Visuals
    menu_util.register_keybind(TAB, G.NPC, P_NPC, "Enable NPC Visuals", false)
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_scav", "Show Scavs", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_boss", "Show Bosses", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_sniper", "Show Snipers", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_box", "NPC Box", false,
        { parent = P_NPC, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, G.NPC, "havoc_npc_box_style", "NPC Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_box_fill", "NPC Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_name", "NPC Name", false,
        { parent = P_NPC, colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_name_size", "NPC Name Size", 6, 24, 13, { parent = "havoc_npc_name" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_distance", "NPC Distance", false,
        { parent = P_NPC, colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_distance_size", "NPC Distance Size", 6, 18, 10, { parent = "havoc_npc_distance" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_held_item", "NPC Held Item", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_held_item_size", "NPC Held Item Size", 6, 18, 10, { parent = "havoc_npc_held_item" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_npc_type", "NPC Type Tag", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_npc_type_size", "NPC Type Tag Size", 6, 18, 9, { parent = "havoc_npc_npc_type" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_health_bar", "NPC Health Bar", false, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_health_text", "NPC Health Text", false,
        { parent = P_NPC, colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_health_text_size", "NPC Health Text Size", 6, 18, 8, { parent = "havoc_npc_health_text" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_chams", "NPC Chams", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.add_combo(TAB, G.NPC, "havoc_npc_chams_style", "NPC Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_skeleton", "NPC Skeleton", false,
        { parent = P_NPC, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_hide_dead", "NPC Hide Dead", false, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_rainbow", "NPC Rainbow", false, { parent = P_NPC })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_max_distance", "NPC Max Distance", 0, 1000, 1000, { parent = P_NPC })

    menu_util.bind_children(P_NPC, {
        "havoc_npc_show_scav", "havoc_npc_show_boss", "havoc_npc_show_sniper",
        "havoc_npc_box", "havoc_npc_name", "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_npc_type",
        "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_skeleton",
        "havoc_npc_hide_dead", "havoc_npc_rainbow", "havoc_npc_max_distance",
        P_NPC .. "_mode",
    })
    menu_util.bind_children("havoc_npc_box", { "havoc_npc_box_style", "havoc_npc_box_fill" })
    menu_util.bind_children("havoc_npc_name", { "havoc_npc_name_size" })
    menu_util.bind_children("havoc_npc_distance", { "havoc_npc_distance_size" })
    menu_util.bind_children("havoc_npc_held_item", { "havoc_npc_held_item_size" })
    menu_util.bind_children("havoc_npc_npc_type", { "havoc_npc_npc_type_size" })
    menu_util.bind_children("havoc_npc_health_text", { "havoc_npc_health_text_size" })
    menu_util.bind_children("havoc_npc_chams", { "havoc_npc_chams_style" })

    menu_util.register_keybind(TAB, G.WORLD, P_LOOT, "Enable Loot ESP", false)
    menu.add_multicombo(TAB, G.WORLD, "havoc_loot_types", "Loot Types",
        loot_catalog.MULTICOMBO_LABELS, loot_catalog.MULTICOMBO_DEFAULTS, { parent = P_LOOT })
    menu.add_checkbox(TAB, G.WORLD, "havoc_loot_box", "Loot Box", false,
        { parent = P_LOOT, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, G.WORLD, "havoc_loot_box_style", "Loot Box Style",
        { "Corners", "Outline", "3D Box" }, 2, { parent = "havoc_loot_box" })
    menu.add_checkbox(TAB, G.WORLD, "havoc_loot_distance", "Loot Show Distance", false, { parent = P_LOOT })
    menu.add_combo(TAB, G.WORLD, "havoc_loot_distance_pos", "Loot Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_loot_distance" })
    menu.add_checkbox(TAB, G.WORLD, "havoc_loot_marker", "Loot Position Marker", false, { parent = P_LOOT })
    menu.add_combo(TAB, G.WORLD, "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = P_LOOT })
    menu.add_checkbox(TAB, G.WORLD, "havoc_loot_rainbow", "Loot Rainbow", false, { parent = P_LOOT })
    menu.add_slider_int(TAB, G.WORLD, "havoc_loot_max_distance", "Loot Max Distance", 0, 2000, 500, { parent = P_LOOT })
    menu.add_slider_int(TAB, G.WORLD, "havoc_loot_text_size", "Loot Text Size", 1, 15, 13, { parent = P_LOOT })
    menu_util.register_keybind(TAB, G.WORLD, P_TRAP, "Enable Trap ESP", false)
    menu.add_multicombo(TAB, G.WORLD, "havoc_trap_types", "Trap Types",
        trap_types.MULTICOMBO_LABELS, trap_types.MULTICOMBO_DEFAULTS, { parent = P_TRAP })
    menu.add_checkbox(TAB, G.WORLD, "havoc_trap_box", "Trap Box", false,
        { parent = P_TRAP, colorpicker = { 1.0, 0.35, 0.25, 1.0 } })
    menu.add_combo(TAB, G.WORLD, "havoc_trap_box_style", "Trap Box Style",
        { "Corners", "Outline", "3D Box" }, 2, { parent = "havoc_trap_box" })
    menu.add_checkbox(TAB, G.WORLD, "havoc_trap_distance", "Trap Show Distance", false, { parent = P_TRAP })
    menu.add_combo(TAB, G.WORLD, "havoc_trap_distance_pos", "Trap Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_trap_distance" })
    menu.add_checkbox(TAB, G.WORLD, "havoc_trap_marker", "Trap Position Marker", false, { parent = P_TRAP })
    menu.add_checkbox(TAB, G.WORLD, "havoc_trap_rainbow", "Trap Rainbow", false, { parent = P_TRAP })
    menu.add_slider_int(TAB, G.WORLD, "havoc_trap_max_distance", "Trap Max Distance", 0, 2000, 500, { parent = P_TRAP })
    menu.add_slider_int(TAB, G.WORLD, "havoc_trap_text_size", "Trap Text Size", 1, 15, 13, { parent = P_TRAP })

    menu.add_checkbox(TAB, G.WORLD, "havoc_target_gear", "Target Gear Viewer", false)
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_fov", "Target Gear FOV", 40, 400, 150,
        { parent = "havoc_target_gear" })
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_gear_size", "Gear Icon Size", 32, 64, 48,
        { parent = "havoc_target_gear" })
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_top", "Top Offset", 48, 160, 88,
        { parent = "havoc_target_gear" })

    menu_util.bind_children(P_LOOT, {
        "havoc_loot_types", "havoc_loot_box", "havoc_loot_distance", "havoc_loot_marker",
        "havoc_loot_filter", "havoc_loot_rainbow", "havoc_loot_max_distance", "havoc_loot_text_size",
        P_LOOT .. "_mode",
    })
    menu_util.bind_children("havoc_loot_box", { "havoc_loot_box_style" })
    menu_util.bind_children("havoc_loot_distance", { "havoc_loot_distance_pos" })
    menu_util.bind_children(P_TRAP, {
        "havoc_trap_types", "havoc_trap_box", "havoc_trap_distance", "havoc_trap_marker",
        "havoc_trap_rainbow", "havoc_trap_max_distance", "havoc_trap_text_size",
        P_TRAP .. "_mode",
    })
    menu_util.bind_children("havoc_trap_box", { "havoc_trap_box_style" })
    menu_util.bind_children("havoc_trap_distance", { "havoc_trap_distance_pos" })
    menu_util.bind_children("havoc_target_gear", {
        "havoc_target_gear_fov", "havoc_target_gear_gear_size", "havoc_target_gear_top",
    })

    -- Row 3: Weapon Mods | Config
    menu_util.register_keybind(TAB, G.WEAPON, P_WEAPON, "Enable Weapon Mods", false)
    menu.add_checkbox(TAB, G.WEAPON, "havoc_no_recoil", "No Recoil", false, { parent = P_WEAPON })
    menu.add_checkbox(TAB, G.WEAPON, "havoc_no_spread", "No Spread", false, { parent = P_WEAPON })
    menu.add_checkbox(TAB, G.WEAPON, "havoc_no_sway", "No Sway", false, { parent = P_WEAPON })
    menu.add_checkbox(TAB, G.WEAPON, "havoc_fast_vel", "Fast Bullet Velocity", false, { parent = P_WEAPON })
    menu_util.bind_children(P_WEAPON, {
        "havoc_no_recoil", "havoc_no_spread", "havoc_no_sway", "havoc_fast_vel",
        P_WEAPON .. "_mode",
    })

    menu_util.sync_masters()
    menu_util.seed_color_defaults()
end

return M

end)()

-- ── features/utility/config.lua ──
July._mods["features.utility.config"] = (function()
local constants = July.require("core.constants")
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local menu_util = July.require("core.menu_util")

local M = {}

M.CONFIG_IDS = {
    "havoc_aimbot_enabled",
    "havoc_aimbot_bone", "havoc_aimbot_target_type",
    "havoc_aimbot_fov", "havoc_aimbot_max_distance", "havoc_aimbot_smooth", "havoc_aimbot_sticky",
    "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
    "july_silent_aim", "july_silent_rainbow",
    "july_silent_target_type", "july_silent_bone", "july_silent_lmb_only", "july_silent_rmb_only",
    "july_silent_filter_health", "july_silent_filter_visible", "july_silent_filter_team",
    "july_silent_target_players", "july_silent_target_npcs", "july_silent_target_npc_soldiers", "july_silent_target_npc_bosses",
    "july_silent_max_dist", "july_silent_fov", "july_silent_sticky",
    "july_silent_wallbang", "july_silent_bullet_tp", "july_silent_tp_ray_mode", "july_silent_tp_ray_vis",
    "july_silent_bullet_manip", "july_silent_manip_dist", "july_silent_manip_status",
    "july_silent_draw_fov", "july_silent_fov_style", "july_silent_target_line",
    "havoc_npc_enabled", "havoc_npc_enabled_mode",
    "havoc_npc_show_scav", "havoc_npc_show_boss", "havoc_npc_show_sniper",
    "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill",
    "havoc_npc_name", "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_npc_type",
    "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_chams_style",
    "havoc_npc_skeleton", "havoc_npc_hide_dead", "havoc_npc_rainbow",
    "havoc_npc_max_distance", "havoc_npc_name_size", "havoc_npc_health_text_size",
    "havoc_npc_held_item_size", "havoc_npc_distance_size", "havoc_npc_npc_type_size",
    "havoc_loot_enabled", "havoc_loot_enabled_mode", "havoc_loot_types",
    "havoc_loot_box", "havoc_loot_box_style",
    "havoc_loot_distance", "havoc_loot_distance_pos",
    "havoc_loot_marker", "havoc_loot_filter", "havoc_loot_rainbow",
    "havoc_loot_max_distance", "havoc_loot_text_size",
    "havoc_trap_enabled", "havoc_trap_enabled_mode", "havoc_trap_types",
    "havoc_trap_box", "havoc_trap_box_style",
    "havoc_trap_distance", "havoc_trap_distance_pos",
    "havoc_trap_marker", "havoc_trap_rainbow",
    "havoc_trap_max_distance", "havoc_trap_text_size",
    "havoc_target_gear", "havoc_target_gear_fov", "havoc_target_gear_gear_size", "havoc_target_gear_top",
    "havoc_weapon_mods_enabled", "havoc_weapon_mods_enabled_mode",
    "havoc_no_recoil", "havoc_no_spread", "havoc_no_sway", "havoc_fast_vel",
}

M.CONFIG_COLOR_IDS = {
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "july_silent_draw_fov", "july_silent_target_line", "july_silent_tp_ray_vis",
    "havoc_loot_box",
    "havoc_trap_box",
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
            local default = menu_util.COLOR_DEFAULTS[id] or { 1, 1, 1, 1 }
            local normalized = color_util.normalize_rgba(colors[id], default)
            local ok = (menu.set_color and menu.set_color(id, normalized))
                or (menu.SetColor and menu.SetColor(id, normalized))
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
local gc = July.require("game.gc_weapon_mods")

local M = {}

local MOD_IDS = {
    "havoc_no_recoil",
    "havoc_no_spread",
    "havoc_no_sway",
    "havoc_fast_vel",
}

local warm_counter = 0

function M.warm()
    if not settings.enabled("havoc_weapon_mods_enabled") then
        return 0
    end
    return gc.warm()
end

function M.apply()
    if not settings.enabled("havoc_weapon_mods_enabled") then
        return
    end

    warm_counter = warm_counter + 1
    if warm_counter % 4 == 1 then
        gc.warm()
    end

    local enabled = {}
    for i = 1, #MOD_IDS do
        if settings.bool(MOD_IDS[i], false) then
            enabled[#enabled + 1] = MOD_IDS[i]
        end
    end

    if #enabled > 0 then
        gc.apply_enabled(enabled)
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
local npc_types = July.require("game.npc_types")
local ballistic = July.require("core.ballistic")
local weapons = July.require("game.weapons")
local hitparts = July.require("game.hitparts")

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
    return hitparts.label_from_index(
        settings.combo_index(prefix .. "bone", hitparts.LABELS, hitparts.DEFAULT_BONE_INDEX)
    )
end

function M.is_npc_target(target)
    return target and target.is_npc == true
end

local function get_npc_kind(ent)
    return npc_types.combat_kind(ent)
end

local function npc_from_entity(ent)
    return {
        is_npc = true,
        inst = ent.model,
        humanoid = ent.humanoid,
        root = ent.root,
        parts = ent.parts,
        name = ent.model.Name,
        kind = get_npc_kind(ent),
    }
end

local function player_from_entity(p)
    return {
        is_npc = false,
        player = p,
        character = p.Character or p.character,
        name = p.Name or p.name,
    }
end

local function part_world(part)
    if not part or not env.is_valid(part) then return nil end
    local ok, pos = pcall(function() return part.Position end)
    if ok and pos then
        if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
        if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    end
    return nil
end

local function find_character_part(char, names)
    if not char or not names then return nil end
    for i = 1, #names do
        local part = env.find_child(char, names[i])
        if part and env.is_valid(part) then
            return part
        end
    end
    return nil
end

local function find_npc_part(ent, names)
    if not ent or not names then return nil end

    if ent.parts then
        for i = 1, #names do
            local part = ent.parts[names[i]]
            if part and env.is_valid(part) then
                return part
            end
        end
    end

    local model = ent.inst or ent.model
    if not model or not env.is_valid(model) then return nil end

    for i = 1, #names do
        local part = env.safe_call(function()
            if model.FindFirstChild then
                local ok, found = pcall(function() return model:FindFirstChild(names[i], true) end)
                if ok and found and env.is_valid(found) then return found end
                return model:FindFirstChild(names[i])
            end
            return nil
        end)
        if part and env.is_valid(part) then
            if ent.parts then ent.parts[names[i]] = part end
            return part
        end
    end

    return ent.root
end

local function npc_part_world(target, names)
    if not target then return nil end
    local part = find_npc_part(target, names)
    return part_world(part) or part_world(target.root)
end

function M.bone_world(target, bone_label)
    if not target then return nil end
    if bone_label == "Closest" then
        return nil
    end

    local names = hitparts.candidate_names(bone_label)
    if not names then return nil end

    if M.is_npc_target(target) then
        return npc_part_world(target, names)
    end

    if bone_label == "Head" and target.player then
        local hp = target.player.head_position or target.player.HeadPosition
        if hp then
            if hp.X then return { x = hp.X, y = hp.Y, z = hp.Z } end
            if hp.x then return { x = hp.x, y = hp.y, z = hp.z } end
        end
    end

    local char = target.character
    if not char or not env.is_valid(char) then return nil end
    return part_world(find_character_part(char, names))
end

function M.closest_bone_world(target, cx, cy)
    cx = cx or 0
    cy = cy or 0
    local best, best_d = nil, math.huge

    if M.is_npc_target(target) then
        local head = M.bone_world(target, "Head")
        if head then
            local sx, sy, ok = w2s(head.x, head.y, head.z)
            if ok then
                return head
            end
        end
    end

    if M.is_npc_target(target) and target.parts then
        for _, part in pairs(target.parts) do
            local pos = part_world(part)
            if pos then
                local sx, sy, ok = w2s(pos.x, pos.y, pos.z)
                if ok then
                    local d = math_util.screen_fov_dist_sq(sx, sy, cx, cy)
                    if d < best_d then
                        best_d = d
                        best = pos
                    end
                end
            end
        end
        if best then return best end
        return part_world(target.root)
    end

    local char = target.character
    if char and env.is_valid(char) then
        if target.player and target.player.get_bones_screen then
            local bones = target.player:get_bones_screen()
            if bones then
                for name, pt in pairs(bones) do
                    local bx = pt.x or pt[1]
                    local by = pt.y or pt[2]
                    if bx and by then
                        local d = math_util.screen_fov_dist_sq(bx, by, cx, cy)
                        if d < best_d then
                            best_d = d
                            best = M.bone_world(target, name)
                        end
                    end
                end
                if best then return best end
            end
        end

        local ok, children = pcall(function() return char:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Part" or child.ClassName == "MeshPart" then
                    local pos = part_world(child)
                    if pos then
                        local sx, sy, vis = w2s(pos.x, pos.y, pos.z)
                        if vis then
                            local d = math_util.screen_fov_dist_sq(sx, sy, cx, cy)
                            if d < best_d then
                                best_d = d
                                best = pos
                            end
                        end
                    end
                end
            end
        end
    end

    return best or M.bone_world(target, "Head")
end

function M.resolve_bone_world(target, bone_label, cx, cy)
    if bone_label == "Closest" then
        return M.closest_bone_world(target, cx, cy)
    end
    return M.bone_world(target, bone_label)
end

local function target_velocity(target)
    if M.is_npc_target(target) then
        local root = target.root
        if root and env.is_valid(root) then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and (vel.X or vel.x) then
                local vx = vel.X or vel.x or 0
                local vy = vel.Y or vel.y or 0
                local vz = vel.Z or vel.z or 0
                return { x = vx, y = math.max(-100, math.min(100, vy)), z = vz }
            end
        end
        return { x = 0, y = 0, z = 0 }
    end

    if target.player and target.player.velocity then
        local v = target.player.velocity
        if v.x ~= nil then
            return {
                x = v.x,
                y = math.max(-100, math.min(100, v.y or 0)),
                z = v.z,
            }
        end
    end

    local char = target.character
    if char and env.is_valid(char) then
        local root = find_character_part(char, { "HumanoidRootPart", "Torso", "UpperTorso" })
        if root then
            local vel = root.AssemblyLinearVelocity or root.Velocity or root.velocity
            if vel and (vel.X or vel.x) then
                local vx = vel.X or vel.x or 0
                local vy = vel.Y or vel.y or 0
                local vz = vel.Z or vel.z or 0
                return { x = vx, y = math.max(-100, math.min(100, vy)), z = vz }
            end
        end
    end

    return { x = 0, y = 0, z = 0 }
end

function M.predict_point(origin, point, target, weapon_name)
    if not origin or not point then return point end
    weapon_name = weapon_name or weapons.cached_held()
    return ballistic.predict_for_weapon(origin, point, target_velocity(target), weapon_name)
end

local function passes_team(target, prefix)
    if M.is_npc_target(target) then return true end
    if not settings.bool(prefix .. "filter_team", true) then return true end

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

local function passes_visibility(target, aim, origin, prefix)
    if not settings.bool(prefix .. "filter_visible", false) then return true end
    if not origin or not aim then return true end

    if not M.is_npc_target(target) and target.character and raycast and raycast.is_player_visible then
        local addr = target.character.Address or target.character.address
        if addr then
            return raycast.is_player_visible(addr) == true
        end
    end

    if raycast and raycast.is_visible then
        return raycast.is_visible(origin.x, origin.y, origin.z, aim.x, aim.y, aim.z) == true
    end

    return true
end

function M.passes_filters(target, prefix, aim, origin)
    if not target then return false end
    if settings.bool(prefix .. "filter_health", true) and not is_alive(target) then return false end
    if not passes_team(target, prefix) then return false end
    if not passes_visibility(target, aim, origin, prefix) then return false end
    return true
end

function M.collect_candidates(prefix)
    local out = {}

    if settings.bool(prefix .. "target_players", true) then
        local players = entity.GetPlayers and entity.GetPlayers() or {}
        local lp = env.get_local_player()
        for i = 1, #players do
            local p = players[i]
            if p ~= lp then
                out[#out + 1] = player_from_entity(p)
            end
        end
    end

    if settings.bool(prefix .. "target_npcs", true) then
        local cache = entity_scan.get_cache()
        for i = 1, #cache do
            local ent = cache[i]
            if not entity_scan.is_entry_valid(ent) then goto continue_npc end
            local npc = npc_from_entity(ent)
            if npc.kind == "boss" and settings.bool(prefix .. "target_npc_bosses", true) then
                out[#out + 1] = npc
            elseif npc.kind == "sniper" and settings.bool(prefix .. "target_npc_soldiers", true) then
                out[#out + 1] = npc
            elseif npc.kind == "soldier" and settings.bool(prefix .. "target_npc_soldiers", true) then
                out[#out + 1] = npc
            end
            ::continue_npc::
        end
    end

    return out
end

local function resolve_origin()
    combat_origin.sync_weapon(weapons.cached_held())
    return silent_ray.get_camera_origin() or combat_origin.get_fire_origin()
end

local function evaluate_candidate(target, bone_label, cx, cy, fov_sq, origin, prefix, crosshair_prio)
    local aim = M.resolve_bone_world(target, bone_label, cx, cy)
    if not aim then return nil end
    if not M.passes_filters(target, prefix, aim, origin) then return nil end

    local max_d = settings.num(prefix .. "max_dist", 500)
    if max_d > 0 and origin then
        local dist = math_util.distance3(aim.x - origin.x, aim.y - origin.y, aim.z - origin.z)
        if dist > max_d then return nil end
    end

    local sx, sy, ok = w2s(aim.x, aim.y, aim.z)
    if not ok then return nil end

    local fov_dist_sq = math_util.screen_fov_dist_sq(sx, sy, cx, cy)
    if fov_dist_sq > fov_sq then return nil end

    local score = crosshair_prio and fov_dist_sq
        or math_util.distance3(aim.x - origin.x, aim.y - origin.y, aim.z - origin.z)

    return { target = target, aim = aim, score = score }
end

function M.find_target(cx, cy, fov, prefix)
    local bone_label = M.bone_name(prefix)
    local origin = resolve_origin()
    local candidates = M.collect_candidates(prefix)
    local crosshair_prio = settings.num(prefix .. "target_type", 0) == 0
    local fov_sq = fov * fov

    local best, best_score = nil, math.huge

    for i = 1, #candidates do
        local hit = evaluate_candidate(
            candidates[i], bone_label, cx, cy, fov_sq, origin, prefix, crosshair_prio
        )
        if hit and hit.score < best_score then
            best_score = hit.score
            best = hit.target
        end
    end

    return best
end

function M.is_target_valid(target, prefix, cx, cy, fov)
    if not target or not M.is_aim_target(target) then return false end

    local bone_label = M.bone_name(prefix)
    local origin = resolve_origin()
    local fov_sq = fov * fov
    local hit = evaluate_candidate(target, bone_label, cx, cy, fov_sq, origin, prefix, true)
    return hit ~= nil
end

function M.is_aim_target(target)
    return is_alive(target)
end

return M

end)()

-- ── features/combat/bullet_tp_ray.lua ──
July._mods["features.combat.bullet_tp_ray"] = (function()
local ballistic = July.require("core.ballistic")
local combat_origin = July.require("game.combat_origin")
local math_util = July.require("core.math_util")
local env = July.require("core.env")

local M = {}

M.MODES = { "Direct", "Snap", "Deep", "Curve", "Arch" }

local BACK_OFFSET = {
    Direct = 3.5,
    Snap = 1.75,
    Deep = 6.0,
    Curve = 3.5,
    Arch = 3.5,
}

local function copy_pos(p)
    return { x = p.x, y = p.y, z = p.z }
end

local function lerp(a, b, t)
    return {
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t,
        z = a.z + (b.z - a.z) * t,
    }
end

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

function M.mode_name(idx)
    return M.MODES[(idx or 0) + 1] or "Direct"
end

function M.player_origin()
    local lp = env.get_local_player()
    if lp then
        local char = lp.Character or lp.character
        if char and env.is_valid(char) then
            local root = env.find_child(char, "HumanoidRootPart")
                or env.find_child(char, "UpperTorso")
                or env.find_child(char, "Torso")
                or env.find_child(char, "Head")
            if root then
                local ok, pos = pcall(function() return root.Position end)
                if ok and pos then
                    if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
                    if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
                end
            end
        end
        if lp.Position then
            local pos = lp.Position
            if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
            if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
        end
    end

    return combat_origin.get_head_origin()
        or combat_origin.get_server_origin()
        or combat_origin.get_fire_origin()
end

function M.predict_aim(target, bone_aim, origin, weapon_name)
    if not bone_aim or not origin then return nil end

    local vel = { x = 0, y = 0, z = 0 }
    if target and target.root then
        local ok, root_vel = pcall(function() return target.root.Velocity end)
        if ok and root_vel then
            vel = {
                x = root_vel.X or root_vel.x or 0,
                y = root_vel.Y or root_vel.y or 0,
                z = root_vel.Z or root_vel.z or 0,
            }
        end
    elseif target and target.character then
        local root = target.character:FindFirstChild("HumanoidRootPart")
        if root then
            local ok, root_vel = pcall(function() return root.Velocity end)
            if ok and root_vel then
                vel = {
                    x = root_vel.X or root_vel.x or 0,
                    y = root_vel.Y or root_vel.y or 0,
                    z = root_vel.Z or root_vel.z or 0,
                }
            end
        end
    end

    return ballistic.predict_for_weapon(origin, bone_aim, vel, weapon_name) or copy_pos(bone_aim)
end

function M.track_origin(camera, aim, mode_name)
    if not aim then return nil end
    if not camera then return copy_pos(aim) end

    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local ux, uy, uz, len = unit(dx, dy, dz)
    if len < 0.05 then return copy_pos(aim) end

    local back = BACK_OFFSET[mode_name] or BACK_OFFSET.Direct
    if back >= len - 0.35 then
        back = math.max(0.75, len * 0.35)
    end

    return {
        x = aim.x - ux * back,
        y = aim.y - uy * back,
        z = aim.z - uz * back,
    }
end

local function sample_line(a, b, steps)
    steps = steps or 12
    local out = {}
    for i = 0, steps do
        out[#out + 1] = lerp(a, b, i / steps)
    end
    return out
end

local function sample_curve(from, to, steps)
    steps = steps or 16
    local mid = lerp(from, to, 0.5)
    local dx, dy, dz = to.x - from.x, to.y - from.y, to.z - from.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return sample_line(from, to, steps) end

    local bend = math.min(4.5, len * 0.12)
    local px, py, pz = -dz / len * bend, 0, dx / len * bend
    mid = { x = mid.x + px, y = mid.y + py, z = mid.z + pz }

    local out = {}
    for i = 0, steps do
        local t = i / steps
        local u = 1 - t
        out[#out + 1] = {
            x = u * u * from.x + 2 * u * t * mid.x + t * t * to.x,
            y = u * u * from.y + 2 * u * t * mid.y + t * t * to.y,
            z = u * u * from.z + 2 * u * t * mid.z + t * t * to.z,
        }
    end
    return out
end

local function sample_arch(origin, aim, weapon_name, steps)
    steps = steps or 20
    if not origin or not aim then return {} end

    local stats = July.require("game.combat_stats").get_effective_stats(weapon_name)
    local speed = math.max(stats.speed or 900, 1)
    local g = ballistic.gravity_accel(stats.gravity)

    local dx, dy, dz = aim.x - origin.x, aim.y - origin.y, aim.z - origin.z
    local dist = math_util.distance3(dx, dy, dz)
    local flight = math.max(dist / speed, 0.01)

    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    local out = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        out[#out + 1] = {
            x = origin.x + vx * t,
            y = origin.y + vy * t - 0.5 * g * t * t,
            z = origin.z + vz * t,
        }
    end
    out[#out + 1] = copy_pos(aim)
    return out
end

function M.build_path(mode_name, player_origin, bone_aim, weapon_name)
    if not player_origin or not bone_aim then return {} end

    local start = copy_pos(player_origin)
    local target = copy_pos(bone_aim)

    if mode_name == "Curve" then
        return sample_curve(start, target, 18)
    end
    if mode_name == "Arch" then
        return sample_arch(start, target, weapon_name, 22)
    end
    return sample_line(start, target, 14)
end

return M

end)()

-- ── features/combat/silent_resolve.lua ──
July._mods["features.combat.silent_resolve"] = (function()
local settings = July.require("core.settings")
local silent_ray = July.require("core.silent_ray")
local manip_math = July.require("core.manip_math")
local targeting = July.require("features.combat.targeting")
local combat_origin = July.require("game.combat_origin")
local bullet_tp_ray = July.require("features.combat.bullet_tp_ray")
local weapons = July.require("game.weapons")
local math_util = July.require("core.math_util")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }
local PIERCE_PAD = 1.25

local function track_origin()
    return silent_ray.get_camera_origin() or combat_origin.get_fire_origin()
end

local function pierce_origin(from, to)
    if not from or not to then return from end
    if not raycast or not raycast.cast then return from end

    local fx, fy, fz = from.x, from.y, from.z
    local tx, ty, tz = to.x, to.y, to.z
    local dx, dy, dz = tx - fx, ty - fy, tz - fz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return from end

    local hit, _, dist = raycast.cast(fx, fy, fz, tx, ty, tz)
    if not hit or not dist or dist <= 0.05 then return from end
    if dist >= len - 1.5 then return from end

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

function M.resolve_track(target, prefix, cx, cy, shooting)
    if not target then return nil, nil, OFF_INFO end

    local camera = track_origin()
    if not camera then return nil, nil, OFF_INFO end

    combat_origin.sync_weapon(weapons.cached_held())

    local bullet_tp = settings.bool(prefix .. "bullet_tp", false)
    local bullet_manip = settings.bool(prefix .. "bullet_manip", false)
    local wallbang = settings.bool(prefix .. "wallbang", false)
    local weapon = weapons.cached_held()

    local bone_aim = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not bone_aim then return nil, nil, OFF_INFO end

    local fire_origin = combat_origin.get_fire_origin() or camera
    if not bullet_tp and not bullet_manip then
        bone_aim = targeting.predict_point(fire_origin, bone_aim, target, weapon) or bone_aim
    end

    local track_origin_pos = camera
    local manip_info = OFF_INFO
    local aim = bone_aim
    local player_origin = bullet_tp_ray.player_origin()

    if bullet_tp then
        local mode_name = bullet_tp_ray.mode_name(settings.num(prefix .. "tp_ray_mode", 0))
        local dist = math_util.distance3(
            bone_aim.x - player_origin.x,
            bone_aim.y - player_origin.y,
            bone_aim.z - player_origin.z
        )

        if dist > 35 then
            aim = bullet_tp_ray.predict_aim(target, bone_aim, player_origin, weapon) or bone_aim
        else
            aim = bone_aim
        end

        track_origin_pos = player_origin

        manip_info = {
            state = "tp",
            peek = nil,
            radius = 0,
            tp_mode = mode_name,
            tp_path = bullet_tp_ray.build_path(mode_name, player_origin, bone_aim, weapon),
            bone_aim = bone_aim,
            player_origin = player_origin,
        }

        if wallbang then
            track_origin_pos = pierce_origin(track_origin_pos, aim) or track_origin_pos
        end
    elseif bullet_manip then
        local body = combat_origin.get_head_origin() or combat_origin.get_server_origin()
        local fire = combat_origin.get_fire_origin()
        local max_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))

        if body then
            local ev = manip_math.evaluate_manipulation(body, bone_aim, {
                max_radius = max_r,
                alt_origins = { fire, camera },
            })
            manip_info = {
                state = ev.state,
                peek = ev.peek,
                radius = ev.radius or max_r,
            }
            if ev.state == "ready" and ev.peek then
                track_origin_pos = manip_math.peek_track_origin(ev.peek) or camera
            end
        else
            manip_info = { state = "blocked", peek = nil, radius = max_r }
        end

        if wallbang then
            track_origin_pos = pierce_origin(track_origin_pos, aim) or track_origin_pos
        end
    elseif wallbang then
        track_origin_pos = pierce_origin(track_origin_pos, aim) or track_origin_pos
    end

    return track_origin_pos, aim, manip_info
end

return M

end)()

-- ── features/combat/aimbot.lua ──
July._mods["features.combat.aimbot"] = (function()
local settings = July.require("core.settings")
local constants = July.require("core.constants")
local entity_scan = July.require("game.entity_scan")
local targeting = July.require("features.combat.targeting")
local hitparts = July.require("game.hitparts")
local env = July.require("core.env")

local M = {}

local locked_ent = nil
local current_target = nil
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

local function screen_center()
    return targeting.screen_center()
end

local function w2s(pos)
    if not pos then return 0, 0, false end
    local x = pos.x or pos.X
    local y = pos.y or pos.Y
    local z = pos.z or pos.Z
    if utility.WorldToScreen then
        return utility.WorldToScreen(x, y, z)
    end
    if utility.world_to_screen then
        return utility.world_to_screen(x, y, z)
    end
    return 0, 0, false
end

local function npc_target(ent)
    return {
        is_npc = true,
        inst = ent.model,
        humanoid = ent.humanoid,
        root = ent.root,
        parts = ent.parts,
    }
end

local function player_target(p, char)
    return {
        is_npc = false,
        player = p,
        character = char,
    }
end

local function dist3(a, b)
    local ax = a.X or a.x or 0
    local ay = a.Y or a.y or 0
    local az = a.Z or a.z or 0
    local dx, dy, dz = ax - b.x, ay - b.y, az - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function resolve_aim_pos(kind, ent, char, player, bone_idx, scx, scy)
    local label = hitparts.label_from_index(bone_idx)
    local target
    if kind == "npc" then
        target = npc_target(ent)
    else
        target = player_target(player, char)
    end
    return targeting.resolve_bone_world(target, label, scx, scy)
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
    local pos = resolve_aim_pos("npc", ent, nil, nil, bone_idx, scx, scy)
    if not pos then return nil end
    local dist = dist3(cam_pos, pos)
    if max_dist > 0 and dist > max_dist then return nil end
    local sx, sy, vis = w2s(pos)
    if not vis then return nil end
    local px_dist = math.sqrt((sx - scx) ^ 2 + (sy - scy) ^ 2)
    if px_dist > fov then return nil end
    return {
        kind = "npc",
        ent = ent,
        pos = pos,
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
    local pos = resolve_aim_pos("player", nil, char, p, bone_idx, scx, scy)
    if not pos then return nil end
    local dist = dist3(cam_pos, pos)
    if max_dist > 0 and dist > max_dist then return nil end
    local sx, sy, vis = w2s(pos)
    if not vis then return nil end
    local px_dist = math.sqrt((sx - scx) ^ 2 + (sy - scy) ^ 2)
    if px_dist > fov then return nil end
    return {
        kind = "player",
        player = p,
        char = char,
        pos = pos,
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

    local scx, scy = screen_center()
    local sx, sy = target.sx, target.sy
    if not sx or not sy then
        local vis
        sx, sy, vis = w2s(target.pos)
        if not vis then return false end
    end

    if input and input.move_mouse then
        return smooth_mouse(sx, sy, scx, scy, smooth)
    end

    if camera and camera.look_at then
        return pcall(camera.look_at, target.pos.x, target.pos.y, target.pos.z, smooth) == true
    end
    if camera and camera.LookAt then
        return pcall(camera.LookAt, target.pos.x, target.pos.y, target.pos.z, smooth) == true
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
    local bone_idx = settings.combo_index("havoc_aimbot_bone", hitparts.LABELS, hitparts.DEFAULT_BONE_INDEX)
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
    local target = sticky and locked_ent or current_target

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
        else
            current_target = target
        end
    elseif target and not sticky_valid(target, cam_pos, scx, scy, fov, bone_idx, max_dist) then
        target = nil
        current_target = nil
    end

    if target then
        M.draw_state.active = true
        M.draw_state.tx = target.sx
        M.draw_state.ty = target.sy
        aim_at(target, smooth)
    else
        M.draw_state.active = false
    end
end

function M.reset()
    locked_ent = nil
    current_target = nil
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
local VK_LMB = 0x01
local VK_RMB = 0x02

local locked_target = nil

M.draw_state = {
    scx = nil,
    scy = nil,
    fov = 150,
    draw_fov = false,
    fill_fov = false,
    active = false,
    tx = 0,
    ty = 0,
    aim_world = nil,
    manip = { state = "off" },
    tp_path = nil,
}

local function key_down(vk)
    return input and input.is_key_down and input.is_key_down(vk)
end

local function track_opts()
    local lmb_only = settings.bool(PREFIX .. "lmb_only", false)
    local rmb_only = settings.bool(PREFIX .. "rmb_only", false)
    local lmb = key_down(VK_LMB)
    local rmb = key_down(VK_RMB)

    if not lmb_only and not rmb_only then
        return true, {
            always = true,
            shooting = lmb or rmb,
            track_key = VK_LMB,
        }
    end

    local keys = {}
    if lmb_only and lmb then keys[#keys + 1] = VK_LMB end
    if rmb_only and rmb then keys[#keys + 1] = VK_RMB end

    if #keys == 0 then
        return false, nil
    end

    return true, { always = false, shooting = true, keys = keys, track_key = keys[1] }
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if sticky and locked_target and targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        return
    end

    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

local function update_draw_state()
    if not settings.enabled(P_MASTER) then
        M.draw_state.draw_fov = false
        M.draw_state.active = false
        return false
    end

    local cx, cy = targeting.screen_center()
    M.draw_state.scx = cx
    M.draw_state.scy = cy
    M.draw_state.fov = settings.num(PREFIX .. "fov", 150)
    M.draw_state.draw_fov = settings.bool(PREFIX .. "draw_fov", false)
    M.draw_state.fill_fov = settings.num(PREFIX .. "fov_style", 1) == 1
    return true
end

function M.tick()
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil
    M.draw_state.aim_world = nil

    if not update_draw_state() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    if not silent_ray.available() then
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

    local cx, cy = M.draw_state.scx, M.draw_state.scy
    local fov = M.draw_state.fov

    update_target(cx, cy, fov)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        return
    end

    local shooting = key_down(VK_LMB) or key_down(VK_RMB)
    local origin, aim, manip_info = silent_resolve.resolve_track(locked_target, PREFIX, cx, cy, shooting)
    if not aim or not origin then
        silent_ray.stop()
        return
    end

    M.draw_state.manip = manip_info or { state = "off" }
    M.draw_state.tp_path = manip_info and manip_info.tp_path or nil
    M.draw_state.aim_world = aim

    local fx, fy, fvis = utility.WorldToScreen(aim.x, aim.y, aim.z)
    if fvis then
        M.draw_state.active = true
        M.draw_state.tx = fx
        M.draw_state.ty = fy
    end

    local should_track, opts = track_opts()
    if not should_track or not opts then
        if not opts or not opts.always then
            silent_ray.stop()
        end
        return
    end

    opts.shooting = opts.shooting or shooting
    silent_ray.track(origin, aim, opts)
end

function M.reset()
    locked_target = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil
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
local tier_util = July.require("game.tier_util")
local npc_types = July.require("game.npc_types")
local constants = July.require("core.constants")
local env = July.require("core.env")

local M = {}

local frame_counter = 0

function M.set_frame_counter(n)
    frame_counter = n
end

local function get_npc_type(ent)
    return npc_types.display_type(ent)
end

local function npc_type_allowed(npc_type)
    if npc_type == "Boss" then return settings.bool("havoc_npc_show_boss", true) end
    if npc_type == "Sniper" then return settings.bool("havoc_npc_show_sniper", true) end
    if npc_type == "Scav" then return settings.bool("havoc_npc_show_scav", true) end
    return true
end

local function collect_part_positions(ent)
    local part_pos = {}
    for name, part in pairs(ent.parts) do
        if env.is_valid(part) then
            local ok, pos = pcall(function() return part.Position end)
            if ok and pos then
                part_pos[name] = pos
            end
        end
    end
    return part_pos
end

function M.render(cam_pos)
    if not settings.enabled("havoc_npc_enabled") then return end

    local entity_cache = entity_scan.get_cache()
    local n = #entity_cache
    if n == 0 then return end

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
    local max_dist = math.min(settings.num("havoc_npc_max_distance", 1000), 1000)

    local name_size = settings.num("havoc_npc_name_size", 13)
    local health_text_size = settings.num("havoc_npc_health_text_size", 8)
    local held_item_size = settings.num("havoc_npc_held_item_size", 10)
    local dist_size = settings.num("havoc_npc_distance_size", 10)
    local npc_type_size = settings.num("havoc_npc_npc_type_size", 9)

    local needs_full_bounds = box_on and box_style == 2
    local heavy_on = chams_on or skeleton_on or needs_full_bounds
    local heavy_stride = heavy_on and math.max(1, math.ceil(n / constants.NPC_CHAMS_BUDGET)) or 1
    local heavy_budget = 0

    local esp_opts = {
        box_style = box_style,
        name_size = name_size,
        health_text_size = health_text_size,
        held_item_size = held_item_size,
        dist_size = dist_size,
        npc_type_size = npc_type_size,
    }

    for i = 1, n do
        local ent = entity_cache[i]
        if not entity_scan.is_entry_valid(ent) then goto continue_ent end

        local health = ent.humanoid.Health or 0
        local max_health = ent.humanoid.MaxHealth or 100

        if hide_dead and health <= 0 then goto continue_ent end

        local root_pos = ent._live_pos
        if not root_pos then
            local ok_pos, pos = pcall(function() return ent.root.Position end)
            if not ok_pos or not pos then goto continue_ent end
            root_pos = pos
        end

        local dist = (cam_pos - root_pos).Magnitude
        if dist > max_dist then goto continue_ent end

        local bounds = draw_util.get_entity_bounds_fallback(root_pos)
        if not bounds.valid then goto continue_ent end

        if heavy_on and heavy_budget < constants.NPC_CHAMS_BUDGET then
            if ((frame_counter + i) % heavy_stride) == 0 then
                local part_pos = collect_part_positions(ent)
                if next(part_pos) then
                    if chams_on then
                        draw_util.draw_entity_chams(part_pos, ent.part_size,
                            ent_rgb or settings.color("havoc_npc_chams", { 1, 0.2, 0.2, 0.55 }), chams_style)
                    end
                    if skeleton_on then
                        draw_util.draw_entity_skeleton(part_pos,
                            ent_rgb or settings.color("havoc_npc_skeleton", { 1, 1, 1, 1 }))
                    end
                    if needs_full_bounds then
                        draw_util.draw_entity_3d_box(part_pos, ent.part_size,
                            ent_rgb or settings.color("havoc_npc_box", { 1, 1, 1, 1 }))
                    end
                end
                heavy_budget = heavy_budget + 1
            end
        end

        local name_str = ent.model.Name
        local npc_type = get_npc_type(ent)
        if npc_type and not npc_type_allowed(npc_type) then goto continue_ent end

        local held_name = ent._held_name
        local held_color = held_name and tier_util.get_esp_color(held_name)
            or settings.color("havoc_npc_held_item", { 1, 0.85, 0.4, 1 })

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
        esp_opts.held_item = held_on and held_name or nil
        esp_opts.held_item_color = ent_rgb or held_color
        esp_opts.npc_type = npc_type

        draw_util.draw_esp(bounds, name_str, dist, esp_opts)

        ::continue_ent::
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
local tier_util = July.require("game.tier_util")
local esp_render = July.require("core.esp_render")
local env = July.require("core.env")

local M = {}

local function loot_passes_filter(filter_idx, is_open_val, is_locked_val, is_drop)
    if is_drop then
        if filter_idx == 1 or filter_idx == 3 or filter_idx == 4 then
            return false
        end
        return true
    end
    if filter_idx == 1 then return is_locked_val == true end
    if filter_idx == 2 then return is_locked_val ~= true end
    if filter_idx == 3 then return is_open_val == true end
    if filter_idx == 4 then return is_open_val ~= true end
    return true
end

local function dist_sq(a, b)
    local dx = (a.X or a.x or 0) - (b.X or b.x or 0)
    local dy = (a.Y or a.y or 0) - (b.Y or b.y or 0)
    local dz = (a.Z or a.z or 0) - (b.Z or b.z or 0)
    return dx * dx + dy * dy + dz * dz
end

local function draw_loot_box(loot, color, box_style)
    if not loot.part_pos or not next(loot.part_pos) then
        if loot.pos then
            local bounds = draw_util.get_entity_bounds_fallback(loot.pos)
            if bounds.valid then
                if box_style == 0 then
                    draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
                else
                    draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
                end
            end
        end
        return
    end

    if box_style == 2 then
        if loot.root and env.is_valid(loot.root) then
            draw_util.draw_root_3d_box(loot.root, color)
            return
        end
        if loot.part_pos and next(loot.part_pos) then
            draw_util.draw_entity_3d_box(loot.part_pos, loot.part_size, color)
        end
        return
    end

    local bounds = draw_util.get_entity_bounds(loot.part_pos, loot.part_size, loot.pos)
    if not bounds.valid then return end
    if box_style == 0 then
        draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
    else
        draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
    end
end

function M.render(cam_pos)
    if not settings.enabled("havoc_loot_enabled") then return end

    local loot_cache = loot_scan.get_cache()
    local n = #loot_cache
    if n == 0 then return end

    local constants = July.require("core.constants")

    local type_vals = settings.get("havoc_loot_types", {})
    local show_dist = settings.bool("havoc_loot_distance", false)
    local dist_pos = settings.num("havoc_loot_distance_pos", 0)
    local show_marker = settings.bool("havoc_loot_marker", false)
    local box_on = settings.bool("havoc_loot_box", false)
    local box_style = settings.num("havoc_loot_box_style", 2)
    local max_dist = settings.num("havoc_loot_max_distance", 500)
    local filter_idx = settings.num("havoc_loot_filter", 0)
    local text_size = settings.num("havoc_loot_text_size", 13)
    local loot_rgb = settings.bool("havoc_loot_rainbow", false) and color_util.rainbow_color(0.3) or nil
    local max_dist_sq = max_dist * max_dist
    local budget = constants.ESP_RENDER_BUDGET or 100
    local candidates = {}

    for i = 1, n do
        local loot = loot_cache[i]
        if loot.pos and loot.category and env.is_valid(loot.model) and loot_catalog.is_enabled(type_vals, loot.category) then
            if loot_passes_filter(filter_idx, loot.is_open, loot.is_locked, loot.is_drop) then
                local dsq = dist_sq(cam_pos, loot.pos)
                if dsq <= max_dist_sq and (loot.is_drop or dsq > constants.ESP_HIDE_SQ) then
                    candidates[#candidates + 1] = {
                        loot = loot,
                        dist = math.sqrt(dsq),
                    }
                end
            end
        end
    end

    if #candidates == 0 then return end

    local draw_list = esp_render.pick_closest(candidates, budget)

    for i = 1, #draw_list do
        local entry = draw_list[i]
        local loot = entry.loot
        local dist = entry.dist
        local px = loot.pos.X or loot.pos.x
        local py = loot.pos.Y or loot.pos.y
        local pz = loot.pos.Z or loot.pos.z

        local sx, sy, sok = esp_render.w2s(px, py, pz)
        if not sok or not esp_render.on_screen(sx, sy) then
            goto continue_draw
        end

        local base_color
        if loot.is_drop and loot.category then
            base_color = loot_rgb or loot_catalog.get_color(loot.category) or loot.tier_color
        else
            base_color = loot.tier_color or loot_rgb or loot_catalog.get_color(loot.category)
        end
        local box_color = loot_rgb or settings.color("havoc_loot_box", base_color)

        if box_on and dist <= math.min(max_dist, 250) then
            draw_loot_box(loot, box_color, box_style)
        end

        local label = loot.category.display
        if loot.display_name then
            label = tier_util.get_item_label(loot.display_name)
        end
        draw_util.draw_loot_label(sx, sy, label, loot.is_locked, dist, show_dist, base_color,
            dist_pos, show_marker, text_size)

        ::continue_draw::
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
local esp_render = July.require("core.esp_render")
local env = July.require("core.env")

local M = {}

local function mag3(a, b)
    local dx = (a.X or 0) - (b.X or b.x or 0)
    local dy = (a.Y or 0) - (b.Y or b.y or 0)
    local dz = (a.Z or 0) - (b.Z or b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function draw_trap_box(trap, color, box_style)
    if not trap.root or not env.is_valid(trap.root) then return end

    if box_style == 2 then
        draw_util.draw_root_3d_box(trap.root, color)
        return
    end

    local ok_pos, pos = pcall(function() return trap.root.Position end)
    local ok_size, size = pcall(function() return trap.root.Size end)
    if ok_pos and pos and ok_size and size then
        local bounds = draw_util.get_entity_bounds_from_parts({ root = pos }, { root = size })
        if bounds.valid then
            if box_style == 0 then
                draw.CornerBox(bounds.x, bounds.y, bounds.w, bounds.h, color)
            else
                draw.Rect(bounds.x, bounds.y, bounds.w, bounds.h, color)
            end
            return
        end
    end

    if ok_pos and pos then
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

function M.render(cam_pos)
    if not settings.enabled("havoc_trap_enabled") then return end

    local trap_cache = trap_scan.get_cache()
    if #trap_cache == 0 then return end

    local constants = July.require("core.constants")
    local type_vals = settings.get("havoc_trap_types", {})
    local show_dist = settings.bool("havoc_trap_distance", false)
    local dist_pos = settings.num("havoc_trap_distance_pos", 0)
    local show_marker = settings.bool("havoc_trap_marker", false)
    local box_on = settings.bool("havoc_trap_box", false)
    local box_style = settings.num("havoc_trap_box_style", 2)
    local max_dist = settings.num("havoc_trap_max_distance", 500)
    local text_size = settings.num("havoc_trap_text_size", 13)
    local trap_rgb = settings.bool("havoc_trap_rainbow", false) and color_util.rainbow_color(0.35) or nil
    local budget = constants.ESP_RENDER_BUDGET or 100
    local candidates = {}

    for i = 1, #trap_cache do
        local trap = trap_cache[i]
        if not trap.root or not env.is_valid(trap.root) then goto continue end
        if not trap_types.is_enabled(type_vals, trap.trap_type) then goto continue end

        local ok_pos, pos = pcall(function() return trap.root.Position end)
        if not ok_pos or not pos then goto continue end

        local dist = mag3(cam_pos, pos)
        if dist > max_dist then goto continue end

        candidates[#candidates + 1] = {
            trap = trap,
            pos = pos,
            dist = dist,
        }

        ::continue::
    end

    if #candidates == 0 then return end

    local draw_list = esp_render.pick_closest(candidates, budget)

    for i = 1, #draw_list do
        local entry = draw_list[i]
        local trap = entry.trap
        local pos = entry.pos
        local dist = entry.dist

        local sx, sy, sok = esp_render.w2s(pos.X, pos.Y, pos.Z)
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
local manip_math = July.require("core.manip_math")
local combat_origin = July.require("game.combat_origin")
local world_vis = July.require("core.world_vis")

local M = {}

local MANIP_LABELS = {
    direct = "MANIP: CLEAR SHOT",
    ready = "MANIP: RAY READY",
    blocked = "MANIP: NO PEEK",
    tp = "BULLET TP",
    off = "",
}

local function manip_active(state)
    return state and state.state and state.state ~= "off"
end

local function manip_ready(state)
    return state.state == "ready" or state.state == "direct" or state.state == "tp"
end

function M.render()
    local state = silent_aim.draw_state
    local prefix = silent_aim.get_prefix()

    if not settings.enabled(silent_aim.get_master_id()) then return end
    if state.scx == nil then return end

    local rgb = settings.bool(prefix .. "rainbow", false) and color_util.rainbow_color(0.5) or nil
    local manip = state.manip or { state = "off" }

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

    if settings.bool(prefix .. "manip_status", false) and manip_active(manip) then
        local label = MANIP_LABELS[manip.state] or "MANIP: ..."
        if manip.state == "tp" and manip.tp_mode then
            label = "BULLET TP: " .. manip.tp_mode
        end
        local col = manip_ready(manip) and { 0.2, 1.0, 0.3, 1.0 } or { 1.0, 0.2, 0.2, 1.0 }
        local tw = draw.GetTextSize(label, 11)
        draw.Text(state.scx - tw * 0.5, state.scy + state.fov + 10, label, col, 11)
    end

    if settings.bool(prefix .. "bullet_manip", false) and settings.bool(prefix .. "manip_ring", false) then
        local body = combat_origin.get_server_origin() or combat_origin.get_head_origin()
        if body then
            local radius = manip.radius or manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))
            local ring_y = manip_math.ring_y(body)
            local ring_col = { 0.15, 0.95, 0.55, 0.55 }
            if manip.state == "blocked" then
                ring_col = { 0.95, 0.25, 0.25, 0.45 }
            elseif manip_ready(manip) then
                ring_col = { 0.2, 0.95, 0.45, 0.7 }
            end
            world_vis.draw_sphere_ring(body.x, ring_y, body.z, radius, ring_col, 1.5)
        end
    end

    if settings.bool(prefix .. "manip_peek_vis", true) and manip.peek and manip.state == "ready" then
        local body = combat_origin.get_server_origin() or combat_origin.get_head_origin()
        local peek = manip.peek
        local col_peek = { 1, 0.85, 0.2, 0.95 }
        local eye_y = peek.y + manip_math.eye_offset_y()
        world_vis.draw_cross(peek.x, eye_y, peek.z, 0.85, col_peek, 2)
        if settings.bool(prefix .. "manip_status", false) then
            world_vis.draw_labeled(peek.x, eye_y, peek.z, "PEEK", col_peek, 11)
        end
        if body then
            world_vis.draw_link(body, peek, { col_peek[1], col_peek[2], col_peek[3], 0.3 }, 1)
        end
        if state.aim_world then
            local ray_from = manip_math.peek_track_origin(peek)
            if ray_from then
                world_vis.draw_link(ray_from, state.aim_world, { 1, 0.45, 0.2, 0.55 }, 1.5)
            end
        end
    end

    if settings.bool(prefix .. "tp_ray_vis", false) and state.tp_path and #state.tp_path >= 2 then
        local col = settings.color(prefix .. "tp_ray_vis", { 0.95, 0.45, 1.0, 0.9 })
        world_vis.draw_world_path(state.tp_path, col, 2)
        if manip.player_origin and state.aim_world then
            world_vis.draw_cross(manip.player_origin.x, manip.player_origin.y, manip.player_origin.z, 0.6, col, 2)
        end
        if manip.bone_aim then
            world_vis.draw_cross(manip.bone_aim.x, manip.bone_aim.y, manip.bone_aim.z, 0.45, { 1, 0.85, 0.2, 0.95 }, 2)
        end
    end
end

return M

end)()

-- ── features/visuals/target_gear_viewer.lua ──
July._mods["features.visuals.target_gear_viewer"] = (function()
local settings = July.require("core.settings")
local draw_util = July.require("core.draw_util")
local math_util = July.require("core.math_util")
local image_cache = July.require("core.image_cache")
local items = July.require("game.items")
local target_gear = July.require("game.target_gear")
local entity_scan = July.require("game.entity_scan")
local targeting = July.require("features.combat.targeting")
local env = July.require("core.env")

local M = {}

local P = "havoc_target_gear"
local GEAR_SLOTS = 7
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_ATTACHMENTS = 5

local gear_cache = {}
local last_poll_ms = 0

M._target = nil
M._layout = nil

local SLOT_BG = { 0.14, 0.14, 0.16, 0.72 }
local HELD_BG = { 0.52, 0.12, 0.14, 0.9 }
local HELD_EDGE = { 0.95, 0.28, 0.32, 0.85 }
local ATT_BG = { 0.16, 0.16, 0.18, 0.82 }
local ATT_EDGE = { 0.45, 0.45, 0.48, 0.5 }
local EMPTY_BG = { 0.08, 0.08, 0.1, 0.55 }
local EMPTY_EDGE = { 1, 1, 1, 0.12 }
local ROUND = 5

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or (os.clock() * 1000)
end

local function screen_size()
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
end

local function img_key(prefix, id)
    return prefix .. tostring(id)
end

local function resolve_image_key(piece)
    if not piece then return nil end
    if piece.asset_id then
        local key = img_key("item_", piece.asset_id)
        image_cache.ensure(key, piece.asset_id)
        return key
    end
    if piece.name then
        local asset_id = items.get_image_asset_id(piece.name, piece.variant)
        if asset_id then
            local key = img_key("item_", asset_id)
            image_cache.ensure(key, asset_id)
            return key
        end
    end
    return nil
end

local function target_key(target)
    if not target then return nil end
    if target.is_npc then
        return target.inst and tostring(target.inst) or target.name
    end
    local p = target.player or target
    return p.user_id or p.UserId or p.Name or p.name
end

local function get_gear(target)
    if not target then return nil end
    local key = target_key(target)
    if not key then return nil end

    local now = tick_ms()
    local cached = gear_cache[key]
    if cached and (now - cached.t) < GEAR_TTL then
        return cached.data
    end

    local data = target_gear.scan_target(target)
    gear_cache[key] = { t = now, data = data }
    return data
end

local function npc_target_from_ent(ent)
    return {
        is_npc = true,
        inst = ent.model,
        model = ent.model,
        humanoid = ent.humanoid,
        root = ent.root,
        name = ent.model and ent.model.Name or "NPC",
        held_name = ent._held_name,
    }
end

local function player_target_from_entity(p)
    return {
        is_npc = false,
        player = p,
        character = p.Character or p.character,
        name = p.Name or p.name,
    }
end

local function target_head_world(target)
    if target.is_npc then
        local pos = targeting.bone_world(target, "Head")
        if pos then return pos end
        if target.root and env.is_valid(target.root) then
            local ok, p = pcall(function() return target.root.Position end)
            if ok and p then
                if p.X then return { x = p.X, y = p.Y, z = p.Z } end
                if p.x then return { x = p.x, y = p.y, z = p.z } end
            end
        end
        return nil
    end

    local p = target.player or target
    if p.head_position then
        local hp = p.head_position
        if hp.X then return { x = hp.X, y = hp.Y, z = hp.Z } end
        if hp.x then return { x = hp.x, y = hp.y, z = hp.z } end
    end

    return targeting.bone_world(player_target_from_entity(p), "Head")
end

local function find_crosshair_target(fov_px)
    local sw, sh = screen_size()
    local cx, cy = sw * 0.5, sh * 0.5
    local best, best_dist = nil, fov_px

    if settings.bool(P .. "_target_players", true) then
        local players = entity.GetPlayers and entity.GetPlayers() or {}
        local lp = env.get_local_player()
        for i = 1, #players do
            local p = players[i]
            if p ~= lp then
                local target = player_target_from_entity(p)
                if targeting.is_aim_target(target) then
                    local pos = target_head_world(target)
                    if pos then
                        local sx, sy, ok = utility.WorldToScreen(pos.x, pos.y, pos.z)
                        if ok then
                            local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
                            if dist <= fov_px and dist < best_dist then
                                best_dist = dist
                                best = target
                            end
                        end
                    end
                end
            end
        end
    end

    if settings.bool(P .. "_target_npcs", true) then
        local cache = entity_scan.get_cache()
        for i = 1, #cache do
            local ent = cache[i]
            if entity_scan.is_entry_valid(ent) then
                local target = npc_target_from_ent(ent)
                if targeting.is_aim_target(target) then
                    local pos = target_head_world(target)
                    if pos then
                        local sx, sy, ok = utility.WorldToScreen(pos.x, pos.y, pos.z)
                        if ok then
                            local dist = math_util.screen_fov_dist(sx, sy, cx, cy)
                            if dist <= fov_px and dist < best_dist then
                                best_dist = dist
                                best = target
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

local function armor_sort_key(piece)
    local n = (piece.name or ""):lower()
    if n:find("helmet", 1, true) or n:find("head", 1, true) or n:find("cap", 1, true)
        or n:find("wrap", 1, true) or n:find("balaclava", 1, true) or n:find("hood", 1, true) then
        return 1
    end
    if n:find("chest", 1, true) or n:find("plate", 1, true) or n:find("shirt", 1, true)
        or n:find("jacket", 1, true) or n:find("hoodie", 1, true) or n:find("vest", 1, true)
        or n:find("suit", 1, true) or n:find("torso", 1, true) or n:find("carrier", 1, true) then
        return 2
    end
    if n:find("legging", 1, true) or n:find("pants", 1, true) or n:find("shorts", 1, true) then
        return 3
    end
    if n:find("glove", 1, true) or n:find("handwrap", 1, true) or n:find("hand wrap", 1, true) then
        return 4
    end
    if n:find("boot", 1, true) or n:find("footwrap", 1, true) or n:find("shoe", 1, true) then
        return 5
    end
    if n:find("backpack", 1, true) or n:find("bag", 1, true) then
        return 6
    end
    return 7
end

local function pack_gear(armor_list)
    local sorted = {}
    for i = 1, #(armor_list or {}) do
        sorted[i] = armor_list[i]
    end
    table.sort(sorted, function(a, b)
        return armor_sort_key(a) < armor_sort_key(b)
    end)

    local packed = {}
    for i = 1, #sorted do
        packed[#packed + 1] = sorted[i]
        if #packed >= GEAR_SLOTS then break end
    end
    return packed
end

local function pack_attachments(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_ATTACHMENTS) do
        packed[#packed + 1] = list[i]
    end
    return packed
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local packed = pack_gear(gear and gear.armor)
    local attachments = pack_attachments(gear and gear.attachments)
    local held_sz = math.floor(gear_sz * 1.28)
    local att_sz = math.floor(gear_sz * 0.78)
    local gap = 5
    local att_gap = 4
    local row_w = GEAR_SLOTS * gear_sz + (GEAR_SLOTS - 1) * gap
    local att_row_w = #attachments > 0 and (#attachments * att_sz + (#attachments - 1) * att_gap) or 0
    local held_row_w = held_sz + (#attachments > 0 and (10 + att_row_w) or 0)
    local panel_w = math.max(row_w, held_row_w)

    local layout = {
        held = held,
        attachments = attachments,
        packed = packed,
        filled = #packed,
        gear_sz = gear_sz,
        held_sz = held_sz,
        att_sz = att_sz,
        gap = gap,
        att_gap = att_gap,
        row_w = row_w,
        held_row_w = held_row_w,
        panel_w = panel_w,
        row_gap = 8,
        name_fs = 11,
        held_key = nil,
        att_keys = {},
        gear_keys = {},
    }

    layout.held_key = held and resolve_image_key(held) or nil
    for i = 1, layout.filled do
        layout.gear_keys[i] = resolve_image_key(packed[i])
        if layout.gear_keys[i] then image_cache.begin_load(layout.gear_keys[i]) end
    end
    for i = 1, #attachments do
        layout.att_keys[i] = resolve_image_key(attachments[i])
        if layout.att_keys[i] then image_cache.begin_load(layout.att_keys[i]) end
    end
    if layout.held_key then
        image_cache.begin_load(layout.held_key)
    end

    return layout
end

local function draw_slot(x, y, size, key, piece, style)
    local pad = 3
    local bg = SLOT_BG
    local edge = nil

    if style == "held" then
        bg = HELD_BG
        edge = HELD_EDGE
    elseif style == "attachment" then
        bg = ATT_BG
        edge = ATT_EDGE
    elseif style == "empty" then
        bg = EMPTY_BG
        edge = EMPTY_EDGE
    end

    draw.rect_filled(x, y, size, size, bg, ROUND)
    if edge and draw.rect then
        draw.rect(x, y, size, size, edge, ROUND, 1.5)
    elseif style == "empty" and draw.rect then
        draw.rect(x, y, size, size, EMPTY_EDGE, ROUND, 1)
    end

    if not piece then return end

    if key and image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
        return
    end

    local label = "?"
    if piece.name and piece.name ~= "" then
        label = piece.name:sub(1, 1):upper()
    end

    local fs = math.max(10, math.floor(size * 0.34))
    local tw = select(1, draw.get_text_size(label, fs))
    draw.text(
        x + size * 0.5 - tw * 0.5,
        y + size * 0.5 - fs * 0.45,
        label,
        { 0.55, 0.55, 0.58, 0.85 },
        fs
    )
end

local function same_target(a, b)
    if a == b then return true end
    if not a or not b then return false end
    return target_key(a) == target_key(b)
end

local function target_display_name(target)
    if not target then return "Unknown" end
    if target.is_npc then
        return target.name or "NPC"
    end
    local p = target.player or target
    return p.display_name or p.DisplayName or p.Name or p.name or "Player"
end

function M.register_menu()
end

function M.refresh_target()
    if not settings.bool(P, false) then
        M._target = nil
        M._layout = nil
        return
    end

    local fov = settings.num(P .. "_fov", 150)
    local gear_sz = settings.num(P .. "_gear_size", 48)
    local target = find_crosshair_target(fov)

    if not target or not targeting.is_aim_target(target) then
        M._target = nil
        M._layout = nil
        return
    end

    local key = target_key(target)
    local cached = key and gear_cache[key]
    local gear_stale = not cached or (tick_ms() - cached.t) >= GEAR_TTL
    local target_changed = not same_target(M._target, target)

    M._target = target

    if target_changed or not M._layout or gear_stale then
        M._layout = build_layout(get_gear(target), gear_sz)
    end
end

function M.update(_dt)
    if not settings.bool(P, false) then
        M._target = nil
        M._layout = nil
        return
    end

    local now = tick_ms()
    if now - last_poll_ms < TARGET_POLL_MS then return end
    last_poll_ms = now

    M.refresh_target()
end

function M.draw()
    if not settings.bool(P, false) then return end
    if not draw or not draw.text or not draw.rect_filled then return end

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5

    local name = target_display_name(target)
    local nw = select(1, draw.get_text_size(name, layout.name_fs))
    draw.text(cx - nw * 0.5, top, name, { 1, 1, 1, 1 }, layout.name_fs)

    local y = top + layout.name_fs + 6
    local held = layout.held
    local row_x = cx - layout.held_row_w * 0.5

    draw_slot(row_x, y, layout.held_sz, layout.held_key, held, held and "held" or "empty")

    if #layout.attachments > 0 then
        local ax = row_x + layout.held_sz + 10
        for i = 1, #layout.attachments do
            local sx = ax + (i - 1) * (layout.att_sz + layout.att_gap)
            draw_slot(
                sx,
                y + (layout.held_sz - layout.att_sz) * 0.5,
                layout.att_sz,
                layout.att_keys[i],
                layout.attachments[i],
                "attachment"
            )
        end
    end

    y = y + layout.held_sz + layout.row_gap

    local start_x = cx - layout.row_w * 0.5
    for i = 1, GEAR_SLOTS do
        local piece = i <= layout.filled and layout.packed[i] or nil
        local sx = start_x + (i - 1) * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, layout.gear_keys[i], piece, piece and "gear" or "empty")
    end

    if not held and layout.filled == 0 then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, { 0.55, 0.55, 0.58, 0.85 }, 10)
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
local session = July.require("core.session")
local esp_scheduler = July.require("core.esp_scheduler")
local weapon_mods = July.require("features.combat.weapon_mods")
local aimbot = July.require("features.combat.aimbot")
local silent_aim = July.require("features.combat.silent_aim")
local npc_esp = July.require("features.visuals.npc_esp")
local loot_esp = July.require("features.visuals.loot_esp")
local trap_esp = July.require("features.visuals.trap_esp")
local aimbot_visuals = July.require("features.visuals.aimbot_visuals")
local silent_visuals = July.require("features.visuals.silent_visuals")
local target_gear_viewer = July.require("features.visuals.target_gear_viewer")

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
        July.require("core.menu_util").sync_masters()
    end

    frame_counter = frame_counter + 1
    npc_esp.set_frame_counter(frame_counter)

    session.tick()
    July.require("core.feature_bind").tick()
    July.require("core.menu_util").sync_masters()

    esp_scheduler.tick(frame_counter)

    if frame_counter % 30 == 1 then
        weapon_mods.apply()
    elseif frame_counter % 10 == 1 and settings.enabled("havoc_weapon_mods_enabled") then
        weapon_mods.warm()
    end

    if settings.enabled("havoc_aimbot_enabled") then
        aimbot_tick_counter = aimbot_tick_counter + 1
        if aimbot_tick_counter >= constants.AIMBOT_TICK_INTERVAL then
            aimbot_tick_counter = 0
            aimbot.tick()
        end
    else
        aimbot_tick_counter = 0
        aimbot.reset()
    end

    if settings.enabled("july_silent_aim") then
        silent_aim.tick()
    else
        silent_aim.reset()
    end

    target_gear_viewer.update()

    local cam_pos
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok then cam_pos = pos end
    end
    if not cam_pos then return end

    npc_esp.render(cam_pos)
    loot_esp.render(cam_pos)
    trap_esp.render(cam_pos)
    aimbot_visuals.render()
    silent_visuals.render()
    target_gear_viewer.draw()
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

    print("[July] v" .. (July.version or "dev") .. " ready - open Scripts then July")
end)

if not ok then
    print("[July] Fatal: " .. tostring(err))
    if debug and debug.traceback then print(debug.traceback(err)) end
end
