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
    local dist_sq = dx * dx + dy * dy
    if dist_sq < 2.25 then return false end

    local smooth_val = math.max(1, smooth)
    local factor = 1 / smooth_val
    local mx, my = dx * factor, dy * factor

    local step = math.sqrt(mx * mx + my * my)
    local max_step = math.min(dist_sq ^ 0.5 * 0.92, 120 / smooth_val)
    if step > max_step and step > 0 then
        local scale = max_step / step
        mx = mx * scale
        my = my * scale
    end

    if math.abs(mx) < 0.01 and math.abs(my) < 0.01 then return false end
    input.move_mouse(mx, my)
    return true
end

local function refresh_target_hit(target, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
    if not target then return nil end
    if target.kind == "npc" then
        return evaluate_npc(target.ent, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
    end
    if target.kind == "player" then
        return evaluate_player(target.player, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio)
    end
    return nil
end

local function aim_at(target, smooth, scx, scy)
    if not target or not target.pos then return false end
    if not input or not input.move_mouse then return false end

    scx = scx or select(1, screen_center())
    scy = scy or select(2, screen_center())
    local sx, sy = target.sx, target.sy
    if not sx or not sy then
        local vis
        sx, sy, vis = w2s(target.pos)
        if not vis then return false end
    end

    return smooth_mouse(sx, sy, scx, scy, smooth)
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
    if not settings.bool("havoc_aimbot_enabled", false) then
        M.reset()
        return
    end

    if not settings.enabled("havoc_aimbot_keybind") then
        M.draw_state.active = false
        return
    end

    if not input or not input.is_key_down then
        M.draw_state.active = false
        return
    end

    local aiming = input.is_key_down(0x02) or input.is_key_down(0x01)
    if not aiming then
        M.draw_state.active = false
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
        local refreshed = refresh_target_hit(
            target, bone_idx, cam_pos, max_dist, scx, scy, fov, crosshair_prio
        )
        if refreshed then
            target = refreshed
            if sticky then
                locked_ent = target
            else
                current_target = target
            end
        else
            target = nil
            if sticky then
                locked_ent = nil
            else
                current_target = nil
            end
        end
    end

    if target then
        M.draw_state.active = true
        M.draw_state.tx = target.sx
        M.draw_state.ty = target.sy
        aim_at(target, smooth, scx, scy)
    else
        M.draw_state.active = false
    end
end

local function aimbot_to_target(hit)
    if not hit then return nil end
    if hit.kind == "npc" and hit.ent then
        return {
            is_npc = true,
            inst = hit.ent.model,
            model = hit.ent.model,
            humanoid = hit.ent.humanoid,
            root = hit.ent.root,
            parts = hit.ent.parts,
            name = hit.ent.model and hit.ent.model.Name or "NPC",
            _held_name = hit.ent._held_name,
        }
    end
    if hit.kind == "player" and hit.player then
        return {
            is_npc = false,
            player = hit.player,
            character = hit.char,
            name = hit.player.Name or hit.player.name,
        }
    end
    return nil
end

function M.get_current_target()
    local hit = locked_ent or current_target
    return aimbot_to_target(hit)
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
