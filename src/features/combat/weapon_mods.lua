local settings = July.require("core.settings")

local M = {}

local PATCHES = {
    { index = 1, patch = { vPunchBase = 0, hPunchBase = 0 } },
    { index = 2, patch = { spreadReduce = 100 } },
    { index = 3, patch = { weight = 0, aimWeight = 0, unAimWeight = 0 } },
    { index = 4, patch = { vel = 100000 } },
}

function M.apply()
    local vals = settings.get("havoc_weapon_mods", {})
    for i = 1, #PATCHES do
        if type(vals) == "table" and vals[PATCHES[i].index] then
            pcall(applygc, PATCHES[i].patch)
        end
    end
end

return M
