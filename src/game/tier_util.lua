local item_tiers = July.require("game.item_tiers")

local M = {}

local DEFAULT = { 0.55, 0.55, 0.58, 1.0 }

local WEAPON_NAMES = {
    ["870 MCS"] = true, ["AK-74M"] = true, ["AKS-74U"] = true, ["Beretta 92X"] = true,
    ["Brassknuckles"] = true, ["CMMG Mk47 Mutant"] = true, ["Citori 725"] = true,
    ["DP-27"] = true, ["F-1"] = true, ["Fists"] = true, ["GL 19 Gen4"] = true,
    ["HK416"] = true, ["KRISS Vector"] = true, ["Karambit"] = true, ["M16A1"] = true,
    ["M1911"] = true, ["M4A1"] = true, ["M67"] = true, ["M84"] = true, ["MAC-10"] = true,
    ["MP34"] = true, ["MP7"] = true, ["MP9"] = true, ["Makarov"] = true, ["Molotov"] = true,
    ["P90"] = true, ["QBZ-95"] = true, ["SKS"] = true, ["SR16"] = true, ["Tomahawk"] = true,
    ["UMP45"] = true, ["VSS Vintorez"] = true,
}

local TIER_DISPLAY = {
    common_gun = "Common",
    common = "Common",
    common_households = "Common",
    gear_common = "Common",
    uncommon = "Uncommon",
    contraband = "Contraband",
    rare = "Rare",
    gear_rare = "Rare",
    player_item = "Rare",
    keys = "Keycard",
    mythic = "Mythic",
    usable_item = "Usable",
    usable_item_inhaler = "Usable",
    cash = "Cash",
}

local KEYCARD_LEVEL = {
    [0] = { 0.72, 0.68, 0.42, 1.0 },
    [1] = { 0.78, 0.72, 0.38, 1.0 },
    [2] = { 0.84, 0.76, 0.34, 1.0 },
    [3] = { 0.9, 0.8, 0.3, 1.0 },
    [4] = { 0.95, 0.85, 0.28, 1.0 },
    [5] = { 1.0, 0.88, 0.22, 1.0 },
    [6] = { 1.0, 0.92, 0.15, 1.0 },
}

function M.is_keycard(name)
    if not name then return false end
    if item_tiers.KEYCARDS[name] then return true end
    if name == "Keycard holder case" then return true end
    if name == "FORTIS Coastal Outpost Cache Key" then return true end
    return false
end

function M.is_gun_name(name)
    if not name then return false end
    if WEAPON_NAMES[name] then return true end
    return item_tiers.ITEM_TIER[name] == "common_gun"
end

function M.is_known_item(name)
    if not name or name == "" then return false end
    if item_tiers.ITEM_TIER[name] then return true end
    if item_tiers.KEYCARDS[name] then return true end
    if name == "Keycard holder case" then return true end
    if name == "FORTIS Coastal Outpost Cache Key" then return true end
    return false
end

function M.get_keycard_color(name)
    local level = tonumber(string.match(name or "", "Level%-(%d+)")) or 0
    return KEYCARD_LEVEL[level] or item_tiers.TIER_ESP.keys or DEFAULT
end

function M.get_tier_key(name)
    if not name then return nil end
    if M.is_keycard(name) then return "keys" end
    return item_tiers.ITEM_TIER[name]
end

function M.get_tier_display(tier_key)
    if not tier_key then return nil end
    return TIER_DISPLAY[tier_key]
end

function M.get_esp_color(name)
    if not name or name == "" then return DEFAULT end
    if M.is_keycard(name) then
        return M.get_keycard_color(name)
    end
    if M.is_gun_name(name) then
        return item_tiers.TIER_ESP.common_gun or { 0.95, 0.32, 0.22, 1 }
    end
    local tier_key = item_tiers.ITEM_TIER[name]
    if tier_key and item_tiers.TIER_ESP[tier_key] then
        return item_tiers.TIER_ESP[tier_key]
    end
    return DEFAULT
end

function M.get_item_label(name)
    if not name or name == "" then return name end
    local tier_key = M.get_tier_key(name)
    local tier_label = M.get_tier_display(tier_key)
    if tier_label then
        return name .. " · " .. tier_label
    end
    return name
end

return M
