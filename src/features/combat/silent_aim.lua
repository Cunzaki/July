local settings = July.require("core.settings")
local targeting = July.require("features.combat.targeting")
local weapons = July.require("game.weapons")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")
local silent_resolve = July.require("features.combat.silent_resolve")

local M = {}

local PREFIX = "july_silent_"
local P_MASTER = "july_silent_aim"
local SHOOT_VK = 0x01
local TARGET_SCAN_MS = 33

local locked_target = nil
local last_target_scan = 0

M.draw_state = {
    scx = nil,
    scy = nil,
    fov = 150,
    draw_fov = false,
    fill_fov = false,
    active = false,
    tx = 0,
    ty = 0,
    manip = { state = "off" },
    tp_path = nil,
}

local function tick_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or (os.clock() * 1000)
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)
    local now = tick_ms()

    if sticky and locked_target then
        if not targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
            locked_target = nil
        end
    end

    if locked_target and sticky then return end

    if now - last_target_scan < TARGET_SCAN_MS then return end
    last_target_scan = now
    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

function M.tick()
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil

    if not settings.enabled("havoc_aimbot_enabled") or not settings.enabled(P_MASTER) or not silent_ray.available() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    silent_ray.ensure_hook()

    if not weapons.holding_weapon() then
        silent_ray.stop()
        return
    end

    combat_origin.sync_weapon(weapons.cached_held())

    local cx, cy = targeting.screen_center()
    local fov = settings.num(PREFIX .. "fov", 150)

    M.draw_state.scx = cx
    M.draw_state.scy = cy
    M.draw_state.fov = fov
    M.draw_state.draw_fov = settings.bool(PREFIX .. "draw_fov", false)
    M.draw_state.fill_fov = settings.num(PREFIX .. "fov_style", 1) == 1

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
    M.draw_state.tp_path = manip_info and manip_info.tp_path or nil

    local fx, fy, fvis = utility.WorldToScreen(aim.x, aim.y, aim.z)
    if fvis then
        M.draw_state.active = true
        M.draw_state.tx = fx
        M.draw_state.ty = fy
    end

    silent_ray.track(origin, aim, SHOOT_VK)
end

function M.reset()
    locked_target = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    silent_ray.stop()
end

function M.get_prefix()
    return PREFIX
end

function M.get_master_id()
    return P_MASTER
end

return M
