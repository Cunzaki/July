local settings = July.require("core.settings")
local targeting = July.require("features.combat.targeting")
local weapons = July.require("game.weapons")
local combat_origin = July.require("game.combat_origin")
local silent_ray = July.require("core.silent_ray")
local silent_resolve = July.require("features.combat.silent_resolve")

local M = {}

local PREFIX = "july_silent_"
local P_MASTER = "july_silent_aim"
local VK_LMB = 0x01
local VK_RMB = 0x02

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
    tp_path = nil,
}

local function key_down(vk)
    return input and input.is_key_down and input.is_key_down(vk)
end

local function track_opts()
    local lmb_only = settings.bool(PREFIX .. "lmb_only", false)
    local rmb_only = settings.bool(PREFIX .. "rmb_only", false)
    local lmb = key_down(VK_LMB)
    local rmb = key_down(VK_RMB)

    if not lmb_only and not rmb_only then
        return true, {
            always = true,
            shooting = lmb or rmb,
            track_key = VK_LMB,
        }
    end

    local keys = {}
    if lmb_only and lmb then keys[#keys + 1] = VK_LMB end
    if rmb_only and rmb then keys[#keys + 1] = VK_RMB end

    if #keys == 0 then
        return false, nil
    end

    return true, { always = false, shooting = true, keys = keys, track_key = keys[1] }
end

local function update_target(cx, cy, fov)
    local sticky = settings.bool(PREFIX .. "sticky", false)

    if sticky and locked_target and targeting.is_target_valid(locked_target, PREFIX, cx, cy, fov) then
        return
    end

    locked_target = targeting.find_target(cx, cy, fov, PREFIX)
end

local function update_draw_state()
    if not settings.enabled(P_MASTER) then
        M.draw_state.draw_fov = false
        M.draw_state.active = false
        return false
    end

    local cx, cy = targeting.screen_center()
    M.draw_state.scx = cx
    M.draw_state.scy = cy
    M.draw_state.fov = settings.num(PREFIX .. "fov", 150)
    M.draw_state.draw_fov = settings.bool(PREFIX .. "draw_fov", false)
    M.draw_state.fill_fov = settings.num(PREFIX .. "fov_style", 1) == 1
    return true
end

function M.tick()
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil
    M.draw_state.aim_world = nil

    if not update_draw_state() then
        locked_target = nil
        silent_ray.stop()
        return
    end

    if not silent_ray.available() then
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

    local cx, cy = M.draw_state.scx, M.draw_state.scy
    local fov = M.draw_state.fov

    update_target(cx, cy, fov)

    if not locked_target or not targeting.is_aim_target(locked_target) then
        silent_ray.stop()
        return
    end

    local shooting = key_down(VK_LMB) or key_down(VK_RMB)
    local origin, aim, manip_info = silent_resolve.resolve_track(locked_target, PREFIX, cx, cy, shooting)
    if not aim or not origin then
        silent_ray.stop()
        return
    end

    M.draw_state.manip = manip_info or { state = "off" }
    M.draw_state.tp_path = manip_info and manip_info.tp_path or nil
    M.draw_state.aim_world = aim

    local fx, fy, fvis = utility.WorldToScreen(aim.x, aim.y, aim.z)
    if fvis then
        M.draw_state.active = true
        M.draw_state.tx = fx
        M.draw_state.ty = fy
    end

    local should_track, opts = track_opts()
    if not should_track or not opts then
        if not opts or not opts.always then
            silent_ray.stop()
        end
        return
    end

    opts.shooting = opts.shooting or shooting
    silent_ray.track(origin, aim, opts)
end

function M.reset()
    locked_target = nil
    M.draw_state.scx = nil
    M.draw_state.active = false
    M.draw_state.manip = { state = "off" }
    M.draw_state.tp_path = nil
    silent_ray.stop()
end

function M.get_prefix()
    return PREFIX
end

function M.get_master_id()
    return P_MASTER
end

return M
