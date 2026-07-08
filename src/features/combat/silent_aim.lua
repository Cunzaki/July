local settings = July.require("core.settings")
local targeting = July.require("features.combat.targeting")
local weapons = July.require("game.weapons")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")
local silent_resolve = July.require("features.combat.silent_resolve")

local M = {}

local PREFIX = "july_silent_"
local P_MASTER = "july_silent_aim"

local locked_target = nil

M.draw_state = {
    scx = nil,
    scy = nil,
    fov = 150,
    draw_fov = false,
    fill_fov = false,
    active = false,
    tx = 0,
    ty = 0,
    aim_world = nil,
    manip = { state = "off" },
}

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if sticky and locked_target and targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        return
    end

    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

local function active()
    return settings.enabled(P_MASTER) and silent_ray.available()
end

function M.tick()
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.aim_world = nil

    if not active() then
        locked_target = nil
        silent_ray.disable_hook()
        M.draw_state.draw_fov = false
        return
    end

    local cx, cy = targeting.screen_center()
    M.draw_state.scx = cx
    M.draw_state.scy = cy
    M.draw_state.fov = settings.num(PREFIX .. "fov", 150)
    M.draw_state.draw_fov = settings.bool(PREFIX .. "draw_fov", false)
    M.draw_state.fill_fov = settings.num(PREFIX .. "fov_style", 1) == 1

    if not weapons.holding_weapon() then
        silent_ray.stop()
        return
    end

    silent_ray.ensure_hook()
    combat_origin.sync_weapon(weapons.cached_held())

    local fov = M.draw_state.fov
    update_target(cx, cy, fov)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        return
    end

    local origin, aim, manip_info = silent_resolve.resolve_track(locked_target, PREFIX, cx, cy)
    if not aim or not origin then
        silent_ray.stop()
        return
    end

    M.draw_state.manip = manip_info or { state = "off" }
    M.draw_state.aim_world = aim

    local fx, fy, fvis = utility.WorldToScreen(aim.x, aim.y, aim.z)
    if fvis then
        M.draw_state.active = true
        M.draw_state.tx = fx
        M.draw_state.ty = fy
    end

    silent_ray.track(origin, aim)
end

function M.get_locked_target()
    return locked_target
end

function M.reset()
    locked_target = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    M.draw_state.draw_fov = false
    M.draw_state.manip = { state = "off" }
    silent_ray.stop()
end

function M.get_prefix()
    return PREFIX
end

function M.get_master_id()
    return P_MASTER
end

return M
