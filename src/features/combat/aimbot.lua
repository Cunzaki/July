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
