local settings = July.require("core.settings")
local targeting = July.require("features.combat.targeting")
local weapons = July.require("game.weapons")

local M = {}

function M.render()
    local ammo_on = settings.bool("havoc_local_ammo", false)
    local reload_on = settings.bool("havoc_local_reloading", false)
    if not ammo_on and not reload_on then return end
    if not draw or not draw.Text or not draw.GetTextSize then return end

    local weapon_state = weapons.get_live_state()
    if not weapon_state then return end

    local scx, scy = targeting.screen_center()
    local fov = settings.num("havoc_aimbot_fov", 150)
    local y = scy + fov + 10
    local cx = scx

    if ammo_on and weapon_state.ammo ~= nil then
        local text = tostring(weapon_state.ammo)
        local fs = settings.num("havoc_local_ammo_size", 12)
        local color = settings.color("havoc_local_ammo", { 0.55, 0.85, 1, 1 })
        local tw = draw.GetTextSize(text, fs)
        draw.Text(cx - tw * 0.5, y, text, color, fs)
        y = y + fs + 4
    end

    if reload_on and weapon_state.reloading then
        local text = "RELOADING"
        local fs = settings.num("havoc_local_reloading_size", 12)
        local color = settings.color("havoc_local_reloading", { 1, 0.45, 0.2, 1 })
        local tw = draw.GetTextSize(text, fs)
        draw.Text(cx - tw * 0.5, y, text, color, fs)
    end
end

return M
