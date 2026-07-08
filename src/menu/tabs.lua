local constants = July.require("core.constants")
local settings = July.require("core.settings")
local menu_defs = July.require("menu.menu_defs")
local config = July.require("features.utility.config")
local session = July.require("core.session")
local esp_scheduler = July.require("core.esp_scheduler")
local aimbot = July.require("features.combat.aimbot")
local npc_esp = July.require("features.visuals.npc_esp")
local loot_esp = July.require("features.visuals.loot_esp")
local trap_esp = July.require("features.visuals.trap_esp")
local aimbot_visuals = July.require("features.visuals.aimbot_visuals")
local local_weapon_hud = July.require("features.visuals.local_weapon_hud")
local target_gear_viewer = July.require("features.visuals.target_gear_viewer")

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
        July.require("core.menu_util").sync_masters()
    end

    frame_counter = frame_counter + 1

    session.tick()
    July.require("core.feature_bind").tick()
    July.require("core.menu_util").sync_masters()

    esp_scheduler.tick(frame_counter)

    if settings.bool("havoc_aimbot_enabled", false) then
        aimbot.update_visuals()
        if settings.enabled("havoc_aimbot_keybind") then
            aimbot_tick_counter = aimbot_tick_counter + 1
            if aimbot_tick_counter >= constants.AIMBOT_TICK_INTERVAL then
                aimbot_tick_counter = 0
                aimbot.tick()
            end
        else
            aimbot_tick_counter = 0
        end
    else
        aimbot_tick_counter = 0
        aimbot.reset()
    end

    target_gear_viewer.update()

    local cam_pos
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok then cam_pos = pos end
    end
    if not cam_pos then return end

    npc_esp.render(cam_pos)
    loot_esp.render(cam_pos)
    trap_esp.render(cam_pos)
    aimbot_visuals.render()
    local_weapon_hud.render()
    target_gear_viewer.draw()
end

return M
