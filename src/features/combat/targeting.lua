local settings = July.require("core.settings")
local math_util = July.require("core.math_util")
local env = July.require("core.env")
local entity_scan = July.require("game.entity_scan")
local combat_origin = July.require("game.combat_origin")
local npc_types = July.require("game.npc_types")
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
        model = ent.model,
        humanoid = ent.humanoid,
        root = ent.root,
        parts = ent.parts,
        name = ent.model.Name,
        kind = get_npc_kind(ent),
        _held_name = ent._held_name,
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

local function resolve_origin()
    combat_origin.sync_weapon(weapons.cached_held())
    return combat_origin.get_fire_origin()
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
    local hit = evaluate_candidate(target, bone_label, cx, cy, fov_sq, origin, prefix, false)
    return hit ~= nil
end

function M.is_aim_target(target)
    return is_alive(target)
end

return M
