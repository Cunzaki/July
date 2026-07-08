local M = {}

M.LOOT_TYPES = {
    { key = "loot_medium_crate", match = "Medium Wooden Crate", display = "Medium Wooden Crate", color = { 0.62, 0.44, 0.24, 1.0 } },
    { key = "loot_complex_crate", match = "Complex Crate", display = "Complex Crate", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_military_crate", match = "Military Crate", display = "Military Crate", color = { 0.3, 0.55, 0.3, 1.0 } },
    { key = "loot_wooden_crate", match = "Wooden Crate", display = "Wooden Crate", color = { 0.55, 0.4, 0.25, 1.0 } },
    { key = "loot_weapon_locker", match = "Weapon Locker", display = "Weapon Locker", color = { 1.0, 0.4, 0.2, 1.0 } },
    { key = "loot_weapon_box", match = "Weapon Box", display = "Weapon Box", color = { 1.0, 0.35, 0.25, 1.0 } },
    { key = "loot_rifle_case", match = "Rifle Case", display = "Rifle Case", color = { 1.0, 0.5, 0.3, 1.0 } },
    { key = "loot_pistol_case", match = "Pistol Case", display = "Pistol Case", color = { 1.0, 0.45, 0.3, 1.0 } },
    { key = "loot_small_case", match = "Small Case", display = "Small Case", color = { 0.9, 0.6, 0.4, 1.0 } },
    { key = "loot_ammunition_box", match = "Ammunition Box", display = "Ammunition Box", color = { 0.3, 0.75, 1.0, 1.0 } },
    { key = "loot_technical_shelf", match = "Technical Shelf", display = "Technical Shelf", color = { 0.35, 0.7, 0.9, 1.0 } },
    { key = "loot_tool_shelf", match = "Tool Shelf", display = "Tool Shelf", color = { 0.4, 0.68, 0.88, 1.0 } },
    { key = "loot_toolbox", match = "Toolbox", display = "Toolbox", color = { 0.4, 0.65, 0.85, 1.0 } },
    { key = "loot_medical_box", match = "Medical Box", display = "Medical Box", color = { 0.9, 0.2, 0.2, 1.0 } },
    { key = "loot_safe", match = "Safe", display = "Safe", color = { 1.0, 0.85, 0.2, 1.0 } },
    { key = "loot_cabinet", match = "Cabinet", display = "Cabinet", color = { 0.9, 0.75, 0.3, 1.0 } },
    { key = "loot_cash_register", match = "Cash Register", display = "Cash Register", color = { 1.0, 0.8, 0.1, 1.0 } },
    { key = "loot_duffel_bag", match = "Duffel Bag", display = "Duffel Bag", color = { 0.85, 0.7, 0.35, 1.0 } },
    { key = "loot_backpack", match = "backpack", display = "Backpack", color = { 0.8, 0.65, 0.3, 1.0 } },
    { key = "loot_closet", match = "Closet", display = "Closet", color = { 0.6, 0.6, 0.65, 1.0 } },
    { key = "loot_computer", match = "Computer", display = "Computer", color = { 0.3, 0.9, 0.9, 1.0 } },
    { key = "loot_server_unit", match = "Server Unit", display = "Server Unit", color = { 0.25, 0.8, 0.95, 1.0 } },
    { key = "loot_powerbox", match = "PowerBox", display = "Power Box", color = { 0.9, 0.85, 0.2, 1.0 } },
    { key = "loot_standing_atm", match = "StandingATM", display = "ATM", color = { 0.2, 0.9, 0.5, 1.0 } },
    { key = "loot_locker", match = "Locker", display = "Locker", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_tall_fridge", match = "Tall Fridge", display = "Tall Fridge", color = { 0.7, 0.85, 0.9, 1.0 } },
    { key = "loot_fridge", match = "Fridge", display = "Fridge", color = { 0.75, 0.88, 0.92, 1.0 } },
    { key = "loot_stove", match = "Stove", display = "Stove", color = { 0.5, 0.5, 0.5, 1.0 } },
    { key = "loot_washing_machine", match = "Washing Machine", display = "Washing Machine", color = { 0.65, 0.75, 0.85, 1.0 } },
    { key = "loot_dishwasher", match = "Dishwasher", display = "Dishwasher", color = { 0.6, 0.7, 0.8, 1.0 } },
    { key = "loot_envelope", match = "Envelope", display = "Envelope", color = { 0.9, 0.85, 0.7, 1.0 } },
    { key = "loot_explosive_barrel", match = "ExplosiveBarrel", display = "Explosive Barrel", color = { 1.0, 0.3, 0.0, 1.0 } },
    { key = "loot_door", match = { "WoodenDoor", "DoubleGlassDoor", "DoubleMetalDoor", "MetalDoor", "GarageDoorLock" },
      display = "Locked Door", color = { 0.5, 0.4, 0.3, 1.0 } },
}

M.LOOT_FALLBACK = { key = "loot_other", display = "Other Loot", color = { 0.8, 0.8, 0.8, 1.0 } }
M.BODY_BAG_TYPE = { key = "loot_body_bag", display = "Body Bag", color = { 0.35, 0.35, 0.35, 1.0 } }

M.MULTICOMBO_ENTRIES = {}
M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

local function rebuild_multicombo()
    M.MULTICOMBO_ENTRIES = {}
    M.MULTICOMBO_LABELS = {}
    M.MULTICOMBO_DEFAULTS = {}
    M.KEY_TO_INDEX = {}

    for i = 1, #M.LOOT_TYPES do
        M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.LOOT_TYPES[i]
        M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.LOOT_TYPES[i].display
        M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
        M.KEY_TO_INDEX[M.LOOT_TYPES[i].key] = #M.MULTICOMBO_ENTRIES
    end

    M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.LOOT_FALLBACK
    M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.LOOT_FALLBACK.display
    M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
    M.KEY_TO_INDEX[M.LOOT_FALLBACK.key] = #M.MULTICOMBO_ENTRIES

    M.MULTICOMBO_ENTRIES[#M.MULTICOMBO_ENTRIES + 1] = M.BODY_BAG_TYPE
    M.MULTICOMBO_LABELS[#M.MULTICOMBO_LABELS + 1] = M.BODY_BAG_TYPE.display
    M.MULTICOMBO_DEFAULTS[#M.MULTICOMBO_DEFAULTS + 1] = false
    M.KEY_TO_INDEX[M.BODY_BAG_TYPE.key] = #M.MULTICOMBO_ENTRIES
end

rebuild_multicombo()

function M.is_enabled(vals, category)
    if type(vals) ~= "table" then return false end
    local idx = M.KEY_TO_INDEX[category and category.key]
    if not idx then return false end
    return vals[idx] == true
end

function M.get_color(category)
    if category and category.color then return category.color end
    return { 1, 1, 1, 1 }
end

local function name_matches(name, pattern)
    if type(pattern) == "table" then
        for i = 1, #pattern do
            if string.find(name, pattern[i], 1, true) then return true end
        end
        return false
    end
    return string.find(name, pattern, 1, true) ~= nil
end

function M.categorize_loot(name)
    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        if name_matches(name, entry.match) then
            return entry
        end
    end
    return M.LOOT_FALLBACK
end

return M
