local settings = July.require("core.settings")
local manip_math = July.require("core.manip_math")
local targeting = July.require("features.combat.targeting")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")

local M = {}

local OFF_INFO = { state = "off", peek = nil, radius = 1 }

function M.resolve_track(target, prefix, cx, cy)
    if not target then return nil, nil, OFF_INFO end

    local track_origin = combat_origin.get_fire_origin() or silent_ray.get_camera_origin()
    if not track_origin then return nil, nil, OFF_INFO end

    local aim = targeting.resolve_bone_world(target, targeting.bone_name(prefix), cx, cy)
    if not aim then return nil, nil, OFF_INFO end

    local manip_info = OFF_INFO

    if settings.bool(prefix .. "bullet_manip", false) then
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
                track_origin = manip_math.peek_track_origin(ev.peek) or track_origin
            end
        else
            manip_info = { state = "blocked", peek = nil, radius = max_r }
        end
    end

    return track_origin, aim, manip_info
end

return M
