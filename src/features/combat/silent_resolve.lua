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
