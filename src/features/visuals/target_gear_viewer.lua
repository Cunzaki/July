local settings = July.require("core.settings")
local math_util = July.require("core.math_util")
local gear_types = July.require("game.gear_types")
local target_gear = July.require("game.target_gear")
local entity_scan = July.require("game.entity_scan")
local targeting = July.require("features.combat.targeting")
local aimbot = July.require("features.combat.aimbot")
local env = July.require("core.env")

local M = {}

local P = "havoc_target_gear"
local GEAR_TTL = 500
local TARGET_POLL_MS = 120
local MAX_EXTRA = 4
local MAX_STASH = 8

local gear_cache = {}
local last_poll_ms = 0

M._target = nil
M._layout = nil

local PANEL_BG = { 0.06, 0.06, 0.08, 0.82 }
local PANEL_EDGE = { 1, 1, 1, 0.1 }
local HELD_BG = { 0.45, 0.1, 0.12, 0.92 }
local HELD_EDGE = { 0.95, 0.28, 0.32, 0.75 }
local ITEM_BG = { 0.14, 0.14, 0.16, 0.88 }
local ITEM_EDGE = { 1, 1, 1, 0.08 }
local SLOT_MUTED = { 0.5, 0.5, 0.54, 0.85 }
local TEXT_MAIN = { 0.94, 0.94, 0.96, 1 }
local TEXT_DIM = { 0.55, 0.55, 0.58, 0.9 }
local ROUND = 6

local SLOT_LABELS = {
    helmet = "Helmet",
    face_cover = "Face",
    armor = "Chest",
    lower_armor = "Legs",
    gloves = "Gloves",
    backpack = "Backpack",
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or (os.clock() * 1000)
end

local function screen_size()
    if utility and utility.get_screen_size then
        return utility.get_screen_size()
    end
    return 1920, 1080
end

local function text_w(str, fs)
    return select(1, draw.get_text_size(str, fs))
end

local function piece_label(piece)
    if not piece or not piece.name or piece.name == "" then return nil end
    if piece.variant and piece.variant ~= "" then
        return piece.name .. " / " .. piece.variant
    end
    return piece.name
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
        parts = ent.parts,
        name = ent.model and ent.model.Name or "NPC",
        _held_name = ent._held_name,
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

local function combat_target_allowed(target)
    if not target or not targeting.is_aim_target(target) then return false end
    if target.is_npc then
        return settings.bool(P .. "_target_npcs", true)
    end
    return settings.bool(P .. "_target_players", true)
end

local function get_combat_target()
    if settings.bool("havoc_aimbot_enabled", false) and settings.enabled("havoc_aimbot_keybind") then
        local target = aimbot.get_current_target()
        if target and combat_target_allowed(target) then
            return target
        end
    end
    return nil
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

local function infer_slot(piece)
    if piece.slot then return piece.slot end
    return gear_types.get_slot(piece.name)
end

local function pack_gear_slots(armor_list)
    local slots = {}
    local extra = {}
    local order = gear_types.SLOT_ORDER or {
        "helmet", "face_cover", "armor", "lower_armor", "gloves", "backpack",
    }

    for i = 1, #order do
        slots[order[i]] = nil
    end

    for i = 1, #(armor_list or {}) do
        local piece = armor_list[i]
        local slot = infer_slot(piece)
        if slot and slots[slot] == nil then
            slots[slot] = piece
        elseif #extra < MAX_EXTRA then
            extra[#extra + 1] = piece
        end
    end

    return slots, extra, order
end

local function pack_stash(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_STASH) do
        packed[#packed + 1] = list[i]
    end
    return packed
end

local function build_layout(gear)
    local is_npc = gear and gear.is_npc
    local held = gear and gear.held
    local slots, extra, order = pack_gear_slots(gear and gear.armor)
    local stash = is_npc and {} or pack_stash(gear and gear.stash)

    local rows = {}
    local panel_w = 220

    if held then
        rows[#rows + 1] = {
            kind = "held",
            label = "Held",
            text = piece_label(held) or "Unknown",
        }
        panel_w = math.max(panel_w, text_w(rows[#rows].text, 11) + 56)
    end

    if not is_npc then
        for i = 1, #order do
            local slot_id = order[i]
            local piece = slots[slot_id]
            if piece then
                local text = piece_label(piece) or "Unknown"
                rows[#rows + 1] = {
                    kind = "gear",
                    label = SLOT_LABELS[slot_id] or slot_id,
                    text = text,
                }
                panel_w = math.max(panel_w, text_w(text, 10) + 88)
            end
        end

        for i = 1, #extra do
            local text = piece_label(extra[i]) or "Unknown"
            rows[#rows + 1] = {
                kind = "gear",
                label = "Extra",
                text = text,
            }
            panel_w = math.max(panel_w, text_w(text, 10) + 88)
        end

        for i = 1, #stash do
            local text = piece_label(stash[i]) or "Unknown"
            rows[#rows + 1] = {
                kind = "stash",
                label = "Bag",
                text = text,
            }
            panel_w = math.max(panel_w, text_w(text, 10) + 72)
        end
    end

    return {
        is_npc = is_npc,
        rows = rows,
        panel_w = math.min(math.max(panel_w, 200), 420),
        has_held = held ~= nil,
    }
end

local function draw_pill(x, y, w, h, bg, edge)
    draw.rect_filled(x, y, w, h, bg, ROUND)
    if draw.rect and edge then
        draw.rect(x, y, w, h, edge, ROUND, 1)
    end
end

local function draw_row(cx, y, row, panel_w)
    local pad_x = 10
    local row_h = row.kind == "held" and 26 or 22
    local label_fs = row.kind == "held" and 10 or 9
    local text_fs = row.kind == "held" and 11 or 10
    local row_w = panel_w
    local row_x = cx - row_w * 0.5

    local bg = ITEM_BG
    local edge = ITEM_EDGE
    if row.kind == "held" then
        bg = HELD_BG
        edge = HELD_EDGE
    end

    draw_pill(row_x, y, row_w, row_h, bg, edge)

    local label = row.label .. ":"
    draw.text(row_x + pad_x, y + (row_h - label_fs) * 0.5, label, SLOT_MUTED, label_fs)

    local label_w = text_w(label, label_fs)
    local text = row.text
    local tw = text_w(text, text_fs)
    local max_text_w = row_w - pad_x * 2 - label_w - 8
    if tw > max_text_w and #text > 3 then
        while tw > max_text_w and #text > 3 do
            text = text:sub(1, #text - 1)
            tw = text_w(text .. "…", text_fs)
        end
        text = text .. "…"
        tw = text_w(text, text_fs)
    end

    draw.text(row_x + row_w - pad_x - tw, y + (row_h - text_fs) * 0.5, text, TEXT_MAIN, text_fs)
    return row_h + 4
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
    local target = get_combat_target()
    if not target then
        target = find_crosshair_target(fov)
    end

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
        M._layout = build_layout(get_gear(target))
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
    local name_fs = 12
    local name = target_display_name(target)
    local panel_w = layout.panel_w
    local header_h = name_fs + 14
    local rows_h = 0
    for i = 1, #layout.rows do
        rows_h = rows_h + (layout.rows[i].kind == "held" and 30 or 26)
    end
    if #layout.rows == 0 then
        rows_h = 22
    end
    local panel_h = header_h + rows_h + 10
    local panel_x = cx - panel_w * 0.5
    local panel_y = top

    draw_pill(panel_x, panel_y, panel_w, panel_h, PANEL_BG, PANEL_EDGE)

    local nw = text_w(name, name_fs)
    draw.text(cx - nw * 0.5, panel_y + 6, name, TEXT_MAIN, name_fs)

    local y = panel_y + header_h
    if #layout.rows == 0 then
        local hint = layout.is_npc and "No held weapon" or "No gear detected"
        local hw = text_w(hint, 10)
        draw.text(cx - hw * 0.5, y + 4, hint, TEXT_DIM, 10)
        return
    end

    for i = 1, #layout.rows do
        y = y + draw_row(cx, y, layout.rows[i], panel_w - 16)
    end
end

return M
