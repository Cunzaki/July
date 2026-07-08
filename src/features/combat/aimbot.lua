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
