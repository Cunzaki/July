local constants = July.require("core.constants")
local settings = July.require("core.settings")
local menu_defs = July.require("menu.menu_defs")
local config = July.require("features.utility.config")
local entity_scan = July.require("game.entity_scan")
local loot_scan = July.require("game.loot_scan")
local trap_scan = July.require("game.trap_scan")
local weapon_mods = July.require("features.combat.weapon_mods")
local aimbot = July.require("features.combat.aimbot")
local silent_aim = July.require("features.combat.silent_aim")
local npc_esp = July.require("features.visuals.npc_esp")
local loot_esp = July.require("features.visuals.loot_esp")
local trap_esp = July.require("features.visuals.trap_esp")
local aimbot_visuals = July.require("features.visuals.aimbot_visuals")
local silent_visuals = July.require("features.visuals.silent_visuals")

local M = {}
M._menu_registered = false

local frame_counter = 0
local config_loaded = false
local aimbot_tick_counter = 0

function M.register_all()
    if M._menu_registered then return end
    menu_defs.register_all()
    config.register_menu()
    M._menu_registered = true
end

function M.init()
    M.register_all()
    return true
end

function M.update()
    if not config_loaded then
        config_loaded = true
        config.load()
    end

    frame_counter = frame_counter + 1
    npc_esp.set_frame_counter(frame_counter)

    if frame_counter % 3 == 1 then entity_scan.refresh() end
    if frame_counter % 15 == 1 then loot_scan.refresh() end
    if frame_counter % 8 == 1 then loot_scan.refresh_live() end
    if frame_counter % 20 == 1 then trap_scan.refresh() end
    if frame_counter % 30 == 1 then weapon_mods.apply() end

    local cam_pos = camera.GetPosition()

    npc_esp.render(cam_pos)
    loot_esp.render(cam_pos)
    trap_esp.render(cam_pos)
    aimbot_visuals.render()
    silent_visuals.render()

    if settings.enabled("havoc_aimbot_enabled") then
        aimbot_tick_counter = aimbot_tick_counter + 1
        if aimbot_tick_counter >= constants.AIMBOT_TICK_INTERVAL then
            aimbot_tick_counter = 0
            aimbot.tick()
        end
    else
        aimbot_tick_counter = 0
        aimbot.reset()
    end

    silent_aim.tick()
end

return M
