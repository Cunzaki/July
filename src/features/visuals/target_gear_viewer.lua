local settings = July.require("core.settings")
local draw_util = July.require("core.draw_util")
local math_util = July.require("core.math_util")
local image_cache = July.require("core.image_cache")
local items = July.require("game.items")
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
local MAX_ATTACHMENTS = 10
local MAX_EXTRA = 4

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

local SLOT_LABELS = {
    helmet = "HELM",
    face_cover = "FACE",
    armor = "CHEST",
    lower_armor = "LEGS",
    gloves = "GLV",
    backpack = "BAG",
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
            piece.asset_id = asset_id
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

local function pack_attachments(list)
    local packed = {}
    for i = 1, math.min(#(list or {}), MAX_ATTACHMENTS) do
        packed[#packed + 1] = list[i]
    end
    return packed
end

local function preload_piece(piece)
    local key = resolve_image_key(piece)
    if key then
        image_cache.begin_load(key)
    end
    return key
end

local function build_layout(gear, gear_sz)
    local held = gear and gear.held
    local slots, extra, order = pack_gear_slots(gear and gear.armor)
    local attachments = pack_attachments(gear and gear.attachments)
    local held_sz = math.floor(gear_sz * 1.28)
    local att_sz = math.floor(gear_sz * 0.78)
    local gap = 5
    local att_gap = 4
    local slot_count = #order + (#extra > 0 and #extra or 0)
    local row_w = slot_count * gear_sz + (slot_count - 1) * gap
    local att_row_w = #attachments > 0 and (#attachments * att_sz + (#attachments - 1) * att_gap) or 0
    local held_row_w = held_sz + (#attachments > 0 and (10 + att_row_w) or 0)
    local panel_w = math.max(row_w, held_row_w)

    local layout = {
        held = held,
        attachments = attachments,
        slots = slots,
        extra = extra,
        order = order,
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
        slot_keys = {},
        extra_keys = {},
    }

    layout.held_key = held and preload_piece(held) or nil
    for i = 1, #order do
        local slot_id = order[i]
        layout.slot_keys[slot_id] = slots[slot_id] and preload_piece(slots[slot_id]) or nil
    end
    for i = 1, #extra do
        layout.extra_keys[i] = preload_piece(extra[i])
    end
    for i = 1, #attachments do
        layout.att_keys[i] = preload_piece(attachments[i])
    end

    return layout
end

local function draw_slot(x, y, size, key, piece, style, hint)
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

    if hint and style == "empty" then
        local fs = math.max(8, math.floor(size * 0.18))
        local tw = select(1, draw.get_text_size(hint, fs))
        draw.text(
            x + size * 0.5 - tw * 0.5,
            y + size - fs - 3,
            hint,
            { 0.45, 0.45, 0.48, 0.75 },
            fs
        )
    end

    if not piece then return end

    if key then
        image_cache.begin_load(key)
        if image_cache.draw_fit(key, x + pad, y + pad, size - pad * 2, size - pad * 2) then
            return
        end
        local state = image_cache.state(key)
        if state == "loading" or state == "none" then
            return
        end
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
    local col = 0
    for i = 1, #layout.order do
        local slot_id = layout.order[i]
        local piece = layout.slots[slot_id]
        local sx = start_x + col * (layout.gear_sz + layout.gap)
        draw_slot(
            sx,
            y,
            layout.gear_sz,
            layout.slot_keys[slot_id],
            piece,
            piece and "gear" or "empty",
            SLOT_LABELS[slot_id]
        )
        col = col + 1
    end

    for i = 1, #layout.extra do
        local piece = layout.extra[i]
        local sx = start_x + col * (layout.gear_sz + layout.gap)
        draw_slot(sx, y, layout.gear_sz, layout.extra_keys[i], piece, "gear")
        col = col + 1
    end

    local has_gear = held ~= nil
    for i = 1, #layout.order do
        if layout.slots[layout.order[i]] then
            has_gear = true
            break
        end
    end
    if #layout.extra > 0 then has_gear = true end

    if not has_gear then
        local hint = "No gear detected"
        local hw = select(1, draw.get_text_size(hint, 10))
        draw.text(cx - hw * 0.5, y + layout.gear_sz + 6, hint, { 0.55, 0.55, 0.58, 0.85 }, 10)
    end
end

return M
