local math_util = July.require("core.math_util")

local M = {}

local ROBLOX_GRAV = 196.2
local LEAD_PASSES = 6

local function vec3(v)
    if not v then return 0, 0, 0 end
    return v.x or v.X or 0, v.y or v.Y or 0, v.z or v.Z or 0
end

function M.gravity_accel(gravity_mult)
    if not gravity_mult or gravity_mult <= 0 then
        return ROBLOX_GRAV * 0.55
    end
    if gravity_mult <= 2 then
        return ROBLOX_GRAV * gravity_mult
    end
    return gravity_mult
end

function M.calculate_target_position(bullet_speed, bullet_gravity, velocity, position, origin)
    local px, py, pz = vec3(position)
    local ox, oy, oz = vec3(origin)
    local vx, vy, vz = vec3(velocity)

    local speed = math.max(bullet_speed or 950, 1)
    local g = M.gravity_accel(bullet_gravity)

    local horiz_speed = math.sqrt(vx * vx + vz * vz)
    if horiz_speed < 1.5 then
        vx, vy, vz = 0, vy, 0
    end

    vy = math.max(-80, math.min(80, vy))

    local time = math_util.distance3(px - ox, py - oy, pz - oz) / speed

    for _ = 1, LEAD_PASSES do
        local tx = px + vx * time
        local ty = py + vy * time
        local tz = pz + vz * time
        time = math_util.distance3(tx - ox, ty - oy, tz - oz) / speed
    end

    local tx = px + vx * time
    local ty = py + vy * time
    local tz = pz + vz * time
    local drop = 0.5 * g * time * time

    return {
        x = tx,
        y = ty + drop,
        z = tz,
    }
end

function M.predict_for_weapon(origin, position, velocity, weapon_name)
    local stats = July.require("game.combat_stats").get_effective_stats(weapon_name)
    return M.calculate_target_position(stats.speed, stats.gravity, velocity, position, origin)
end

return M
