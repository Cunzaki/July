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
