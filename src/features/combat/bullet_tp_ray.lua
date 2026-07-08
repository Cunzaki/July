local ballistic = July.require("core.ballistic")
local combat_origin = July.require("game.combat_origin")
local math_util = July.require("core.math_util")
local env = July.require("core.env")

local M = {}

M.MODES = { "Direct", "Snap", "Deep", "Curve", "Arch" }

local BACK_OFFSET = {
    Direct = 3.5,
    Snap = 1.75,
    Deep = 6.0,
    Curve = 3.5,
    Arch = 3.5,
}

local function copy_pos(p)
    return { x = p.x, y = p.y, z = p.z }
end

local function lerp(a, b, t)
    return {
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t,
        z = a.z + (b.z - a.z) * t,
    }
end

local function unit(dx, dy, dz)
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return 0, 0, 0, 0 end
    local inv = 1 / len
    return dx * inv, dy * inv, dz * inv, len
end

function M.mode_name(idx)
    return M.MODES[(idx or 0) + 1] or "Direct"
end

function M.player_origin()
    local lp = env.get_local_player()
    if lp then
        local char = lp.Character or lp.character
        if char and env.is_valid(char) then
            local root = env.find_child(char, "HumanoidRootPart")
                or env.find_child(char, "UpperTorso")
                or env.find_child(char, "Torso")
                or env.find_child(char, "Head")
            if root then
                local ok, pos = pcall(function() return root.Position end)
                if ok and pos then
                    if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
                    if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
                end
            end
        end
        if lp.Position then
            local pos = lp.Position
            if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
            if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
        end
    end

    return combat_origin.get_head_origin()
        or combat_origin.get_server_origin()
        or combat_origin.get_fire_origin()
end

function M.predict_aim(target, bone_aim, origin, weapon_name)
    if not bone_aim or not origin then return nil end

    local vel = { x = 0, y = 0, z = 0 }
    if target and target.root then
        local ok, root_vel = pcall(function() return target.root.Velocity end)
        if ok and root_vel then
            vel = {
                x = root_vel.X or root_vel.x or 0,
                y = root_vel.Y or root_vel.y or 0,
                z = root_vel.Z or root_vel.z or 0,
            }
        end
    elseif target and target.character then
        local root = target.character:FindFirstChild("HumanoidRootPart")
        if root then
            local ok, root_vel = pcall(function() return root.Velocity end)
            if ok and root_vel then
                vel = {
                    x = root_vel.X or root_vel.x or 0,
                    y = root_vel.Y or root_vel.y or 0,
                    z = root_vel.Z or root_vel.z or 0,
                }
            end
        end
    end

    return ballistic.predict_for_weapon(origin, bone_aim, vel, weapon_name) or copy_pos(bone_aim)
end

function M.track_origin(camera, aim, mode_name)
    if not aim then return nil end
    if not camera then return copy_pos(aim) end

    local dx, dy, dz = aim.x - camera.x, aim.y - camera.y, aim.z - camera.z
    local ux, uy, uz, len = unit(dx, dy, dz)
    if len < 0.05 then return copy_pos(aim) end

    local back = BACK_OFFSET[mode_name] or BACK_OFFSET.Direct
    if back >= len - 0.35 then
        back = math.max(0.75, len * 0.35)
    end

    return {
        x = aim.x - ux * back,
        y = aim.y - uy * back,
        z = aim.z - uz * back,
    }
end

local function sample_line(a, b, steps)
    steps = steps or 12
    local out = {}
    for i = 0, steps do
        out[#out + 1] = lerp(a, b, i / steps)
    end
    return out
end

local function sample_curve(from, to, steps)
    steps = steps or 16
    local mid = lerp(from, to, 0.5)
    local dx, dy, dz = to.x - from.x, to.y - from.y, to.z - from.z
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)
    if len < 0.001 then return sample_line(from, to, steps) end

    local bend = math.min(4.5, len * 0.12)
    local px, py, pz = -dz / len * bend, 0, dx / len * bend
    mid = { x = mid.x + px, y = mid.y + py, z = mid.z + pz }

    local out = {}
    for i = 0, steps do
        local t = i / steps
        local u = 1 - t
        out[#out + 1] = {
            x = u * u * from.x + 2 * u * t * mid.x + t * t * to.x,
            y = u * u * from.y + 2 * u * t * mid.y + t * t * to.y,
            z = u * u * from.z + 2 * u * t * mid.z + t * t * to.z,
        }
    end
    return out
end

local function sample_arch(origin, aim, weapon_name, steps)
    steps = steps or 20
    if not origin or not aim then return {} end

    local stats = July.require("game.combat_stats").get_effective_stats(weapon_name)
    local speed = math.max(stats.speed or 900, 1)
    local g = ballistic.gravity_accel(stats.gravity)

    local dx, dy, dz = aim.x - origin.x, aim.y - origin.y, aim.z - origin.z
    local dist = math_util.distance3(dx, dy, dz)
    local flight = math.max(dist / speed, 0.01)

    local vx = dx / flight
    local vy = (dy + 0.5 * g * flight * flight) / flight
    local vz = dz / flight

    local out = {}
    for i = 0, steps do
        local t = (i / steps) * flight
        out[#out + 1] = {
            x = origin.x + vx * t,
            y = origin.y + vy * t - 0.5 * g * t * t,
            z = origin.z + vz * t,
        }
    end
    out[#out + 1] = copy_pos(aim)
    return out
end

function M.build_path(mode_name, player_origin, bone_aim, weapon_name)
    if not player_origin or not bone_aim then return {} end

    local start = copy_pos(player_origin)
    local target = copy_pos(bone_aim)

    if mode_name == "Curve" then
        return sample_curve(start, target, 18)
    end
    if mode_name == "Arch" then
        return sample_arch(start, target, weapon_name, 22)
    end
    return sample_line(start, target, 14)
end

return M
