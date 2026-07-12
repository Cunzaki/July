local settings = July.require("core.settings")
local math_util = July.require("core.math_util")
local gear_types = July.require("game.gear_types")
local target_gear = July.require("game.target_gear")
local entity_scan = July.require("game.entity_scan")
local targeting = July.require("features.combat.targeting")
local aimbot = July.require("features.combat.aimbot")
local env = July.require("core.env")
local havoc_icons = July.require("game.havoc_icons")
local image_cache = July.require("core.image_cache")

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

local TEXT_MAIN = { 0.96, 0.96, 0.98, 1 }
local TEXT_DIM = { 0.58, 0.58, 0.62, 0.92 }
local SLOT_MUTED = { 0.62, 0.62, 0.66, 0.88 }
local HELD_TINT = { 1.0, 0.42, 0.45, 1.0 }

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
    local icon_size = settings.num(P .. "_gear_size", 48)
    local row_h = math.max(18, icon_size * 0.42)

    if held then
        rows[#rows + 1] = {
            kind = "held",
            label = "Held",
            text = piece_label(held) or "Unknown",
            piece = held,
            row_h = row_h + 2,
        }
    end

    if not is_npc then
        for i = 1, #order do
            local slot_id = order[i]
            local piece = slots[slot_id]
            if piece then
                rows[#rows + 1] = {
                    kind = "gear",
                    label = SLOT_LABELS[slot_id] or slot_id,
                    text = piece_label(piece) or "Unknown",
                    piece = piece,
                    row_h = row_h,
                }
            end
        end

        for i = 1, #extra do
            local piece = extra[i]
            rows[#rows + 1] = {
                kind = "gear",
                label = "Extra",
                text = piece_label(piece) or "Unknown",
                piece = piece,
                row_h = row_h,
            }
        end

        for i = 1, #stash do
            local piece = stash[i]
            rows[#rows + 1] = {
                kind = "stash",
                label = "Bag",
                text = piece_label(piece) or "Unknown",
                piece = piece,
                row_h = row_h,
            }
        end
    end

    return {
        is_npc = is_npc,
        rows = rows,
        icon_size = icon_size,
        row_h = row_h,
        has_held = held ~= nil,
    }
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

local function draw_icon(x, y, size, piece)
    if not piece or not piece.name then return 0 end
    local asset_id = havoc_icons.lookup(piece.name, piece.variant)
    if not asset_id then return 0 end
    local key = "gear_" .. tostring(asset_id)
    image_cache.ensure(key, asset_id)
    if image_cache.draw_fit(key, x, y, size, size) then
        return size + 6
    end
    return 0
end

local function draw_row(cx, y, row, layout)
    local icon_size = layout.icon_size
    local row_h = row.row_h or layout.row_h
    local label_fs = row.kind == "held" and 10 or 9
    local text_fs = row.kind == "held" and 12 or 11
    local label_col = row.kind == "held" and HELD_TINT or SLOT_MUTED
    local text_col = TEXT_MAIN

    local text = row.text
    local tw = text_w(text, text_fs)
    local total_w = icon_size + 8 + tw + 40
    local start_x = cx - total_w * 0.5

    local icon_off = draw_icon(start_x, y + (row_h - icon_size) * 0.5, icon_size, row.piece)
    local text_x = start_x + (icon_off > 0 and icon_off or icon_size + 6)

    draw.text(text_x, y + (row_h - text_fs) * 0.5, text, text_col, text_fs)

    local label = row.label
    local lw = text_w(label, label_fs)
    draw.text(text_x + tw + 10, y + (row_h - label_fs) * 0.5, label, label_col, label_fs)

    return row_h + 6
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
    if not draw or not draw.text then return end

    local target = M._target
    local layout = M._layout
    if not target or not layout then return end

    local sw, _ = screen_size()
    local top = settings.num(P .. "_top", 88)
    local cx = sw * 0.5
    local name = target_display_name(target)
    local name_fs = 13

    local nw = text_w(name, name_fs)
    draw.text(cx - nw * 0.5, top, name, TEXT_MAIN, name_fs)

    local y = top + name_fs + 10
    if #layout.rows == 0 then
        local hint = layout.is_npc and "No held weapon" or "No gear detected"
        local hw = text_w(hint, 10)
        draw.text(cx - hw * 0.5, y, hint, TEXT_DIM, 10)
        return
    end

    for i = 1, #layout.rows do
        y = y + draw_row(cx, y, layout.rows[i], layout)
    end
end

return M
