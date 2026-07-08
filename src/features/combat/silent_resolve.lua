local settings = July.require("core.settings")
local silent_ray = July.require("core.silent_ray")
local manip_math = July.require("core.manip_math")
local targeting = July.require("features.combat.targeting")
local bullet_tp_ray = July.require("features.combat.bullet_tp_ray")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }
local PIERCE_PAD = 1.25

local function pierce_origin(from, to)
    if not from or not to then return from end
    if not raycast or not raycast.cast then return from end
    if raycast.is_ready and not raycast.is_ready() then return from end

    local fx, fy, fz = from.x, from.y, from.z
    local tx, ty, tz = to.x, to.y, to.z
    local dx, dy, dz = tx - fx, ty - fy, tz - fz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return from end

    local hit, _, dist = raycast.cast(fx, fy, fz, tx, ty, tz)
    if not hit or not dist or dist <= 0.05 then return from end

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

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local camera = silent_ray.get_camera_origin()
    if not camera then return nil, nil, OFF_INFO end

    local aim = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not aim then return nil, nil, OFF_INFO end

    local track_origin = camera
    local manip_info = OFF_INFO
    local bullet_tp = settings.bool(prefix .. "bullet_tp", false)
    local wallbang = settings.bool(prefix .. "wallbang", false)

    if bullet_tp then
        local head = targeting.bone_world(target, "Head") or aim
        local mode_name = bullet_tp_ray.mode_name(settings.num(prefix .. "tp_ray_mode", 0))
        aim = head
        track_origin = bullet_tp_ray.track_origin(camera, aim, mode_name) or aim
        manip_info = {
            state = "tp",
            peek = nil,
            radius = 0,
            tp_mode = mode_name,
            tp_path = bullet_tp_ray.build_path(mode_name, track_origin, aim),
        }
    elseif settings.bool(prefix .. "bullet_manip", false) then
        local body = targeting.get_server_origin()
        local max_r = manip_math.clamp_radius(settings.num(prefix .. "manip_dist", 1))

        if body then
            local ev = manip_math.evaluate_manipulation(body, aim, { max_radius = max_r })
            manip_info = {
                state = ev.state,
                peek = ev.peek,
                radius = ev.radius or max_r,
            }
            if ev.state == "ready" and ev.peek then
                track_origin = manip_math.peek_track_origin(ev.peek) or camera
            end
        else
            manip_info = { state = "blocked", peek = nil, radius = max_r }
        end

        if wallbang then
            track_origin = pierce_origin(track_origin, aim) or track_origin
        end
    elseif wallbang then
        track_origin = pierce_origin(track_origin, aim) or track_origin
    end

    return track_origin, aim, manip_info
end

return M
