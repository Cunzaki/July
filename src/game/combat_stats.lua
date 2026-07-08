local weapons = July.require("game.weapons")

local M = {}

local DEFAULT = { speed = 900, gravity = 0.55 }

local FALLBACK = {
    ["M4A1"] = { speed = 900, gravity = 0.55 },
    ["HK416"] = { speed = 900, gravity = 0.55 },
    ["SR16"] = { speed = 900, gravity = 0.55 },
    ["M16A1"] = { speed = 900, gravity = 0.55 },
    ["AK-74M"] = { speed = 900, gravity = 0.55 },
    ["AKS-74U"] = { speed = 850, gravity = 0.55 },
    ["QBZ-95"] = { speed = 900, gravity = 0.55 },
    ["CMMG Mk47 Mutant"] = { speed = 900, gravity = 0.55 },
    ["Mk14 EBR"] = { speed = 880, gravity = 0.55 },
    ["SKS"] = { speed = 735, gravity = 0.55 },
    ["SVD"] = { speed = 830, gravity = 0.55 },
    ["SV-98"] = { speed = 850, gravity = 0.55 },
    ["VSS Vintorez"] = { speed = 750, gravity = 0.55 },
    ["AWP"] = { speed = 850, gravity = 0.55 },
    ["P90"] = { speed = 750, gravity = 0.55 },
    ["MP7"] = { speed = 720, gravity = 0.55 },
    ["MP9"] = { speed = 720, gravity = 0.55 },
    ["MP5A5"] = { speed = 720, gravity = 0.55 },
    ["MP34"] = { speed = 410, gravity = 0.55 },
    ["MAC-10"] = { speed = 650, gravity = 0.55 },
    ["UMP45"] = { speed = 700, gravity = 0.55 },
    ["KRISS Vector"] = { speed = 750, gravity = 0.55 },
    ["870 MCS"] = { speed = 550, gravity = 0.55 },
    ["Citori 725"] = { speed = 550, gravity = 0.55 },
    ["311 Double Barrel"] = { speed = 550, gravity = 0.55 },
    ["DP-27"] = { speed = 500, gravity = 0.55 },
    ["Beretta 92X"] = { speed = 650, gravity = 0.55 },
    ["GL 19 Gen4"] = { speed = 650, gravity = 0.55 },
    ["M1911"] = { speed = 650, gravity = 0.55 },
    ["Makarov"] = { speed = 600, gravity = 0.55 },
}

function M.get_effective_stats(weapon_name)
    weapon_name = weapon_name or weapons.cached_held()
    local base = weapon_name and FALLBACK[weapon_name] or nil
    if not base then
        return {
            speed = DEFAULT.speed,
            gravity = DEFAULT.gravity,
            name = weapon_name or "Unknown",
        }
    end
    return {
        speed = base.speed,
        gravity = base.gravity,
        name = weapon_name,
    }
end

return M
