local settings = July.require("core.settings")

local M = {}

local PATCHES = {
    havoc_no_recoil = { vPunchBase = 0, hPunchBase = 0 },
    havoc_no_spread = { spreadReduce = 100 },
    havoc_no_sway = { weight = 0, aimWeight = 0, unAimWeight = 0 },
    havoc_fast_vel = { vel = 100000 },
}

function M.apply()
    for id, patch in pairs(PATCHES) do
        if settings.bool(id, false) then
            pcall(applygc, patch)
        end
    end
end

return M
