local env = July.require("core.env")

local M = {}

-- lootType ids from game dump (33) + body bags
M.LOOT_TYPES = {
    { key = "loot_ammo_crate", loot_type = "ammo.crate", display = "Ammo Crate", color = { 0.3, 0.75, 1.0, 1.0 } },
    { key = "loot_big_safe", loot_type = "big.safe", display = "Safe", color = { 1.0, 0.85, 0.2, 1.0 } },
    { key = "loot_cabinet", loot_type = "cabinet", display = "Cabinet", color = { 0.9, 0.75, 0.3, 1.0 } },
    { key = "loot_cash_register", loot_type = "cash.register", display = "Cash Register", color = { 1.0, 0.8, 0.1, 1.0 } },
    { key = "loot_closet", loot_type = "closet", display = "Closet", color = { 0.6, 0.6, 0.65, 1.0 } },
    { key = "loot_complex_crate", loot_type = "complex.crate", display = "Complex Crate", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_computer", loot_type = "computer", display = "Computer", color = { 0.3, 0.9, 0.9, 1.0 } },
    { key = "loot_dishwasher", loot_type = "dishwasher", display = "Dishwasher", color = { 0.6, 0.7, 0.8, 1.0 } },
    { key = "loot_duffel_bag", loot_type = "duffel.bag", display = "Duffel Bag", color = { 0.85, 0.7, 0.35, 1.0 } },
    { key = "loot_envelope", loot_type = "envelope", display = "Envelope", color = { 0.9, 0.85, 0.7, 1.0 } },
    { key = "loot_file_cabinet", loot_type = "file.cabinet", display = "File Cabinet", color = { 0.55, 0.5, 0.45, 1.0 } },
    { key = "loot_fridge", loot_type = "fridge", display = "Fridge", color = { 0.75, 0.88, 0.92, 1.0 } },
    { key = "loot_hospital_cabinet", loot_type = "hospital.cabinet", display = "Hospital Cabinet", color = { 0.9, 0.9, 0.95, 1.0 } },
    { key = "loot_locker", loot_type = "locker", display = "Locker", color = { 0.55, 0.55, 0.6, 1.0 } },
    { key = "loot_medical_box", loot_type = "medical.box", display = "Medical Box", color = { 0.9, 0.2, 0.2, 1.0 } },
    { key = "loot_medium_crate", loot_type = "medium.wooden.crate", display = "Medium Wooden Crate", color = { 0.62, 0.44, 0.24, 1.0 } },
    { key = "loot_military_radio", loot_type = "military.radio", display = "Military Radio", color = { 0.35, 0.55, 0.35, 1.0 } },
    { key = "loot_military_supply", loot_type = "military.supply", display = "Military Supply", color = { 0.3, 0.55, 0.3, 1.0 } },
    { key = "loot_pistol_case", loot_type = "pistol.case", display = "Pistol Case", color = { 1.0, 0.45, 0.3, 1.0 } },
    { key = "loot_rifle_case", loot_type = "rifle.case", display = "Rifle Case", color = { 1.0, 0.5, 0.3, 1.0 } },
    { key = "loot_server_unit", loot_type = "server.unit", display = "Server Unit", color = { 0.25, 0.8, 0.95, 1.0 } },
    { key = "loot_small_case", loot_type = "small.case", display = "Small Case", color = { 0.9, 0.6, 0.4, 1.0 } },
    { key = "loot_standing_atm", loot_type = "standing.atm", display = "ATM", color = { 0.2, 0.9, 0.5, 1.0 } },
    { key = "loot_stove", loot_type = "stove", display = "Stove", color = { 0.5, 0.5, 0.5, 1.0 } },
    { key = "loot_tall_fridge", loot_type = "tall.fridge", display = "Tall Fridge", color = { 0.7, 0.85, 0.9, 1.0 } },
    { key = "loot_tool_shelf", loot_type = "tool.shelf", display = "Tool Shelf", color = { 0.4, 0.68, 0.88, 1.0 } },
    { key = "loot_toolbox", loot_type = "toolbox", display = "Toolbox", color = { 0.4, 0.65, 0.85, 1.0 } },
    { key = "loot_washing_machine", loot_type = "washing.machine", display = "Washing Machine", color = { 0.65, 0.75, 0.85, 1.0 } },
    { key = "loot_weapon_box", loot_type = "weapon.box", display = "Weapon Box", color = { 1.0, 0.35, 0.25, 1.0 } },
    { key = "loot_weapon_locker", loot_type = "weapon.locker", display = "Weapon Locker", color = { 1.0, 0.4, 0.2, 1.0 } },
    { key = "loot_wooden_crate", loot_type = "wooden.crate", display = "Wooden Crate", color = { 0.55, 0.4, 0.25, 1.0 } },
    { key = "loot_door", loot_type = "door", display = "Locked Door", color = { 0.5, 0.4, 0.3, 1.0 } },
}

M.BODY_BAG_TYPE = { key = "loot_body_bag", loot_type = "body.bag", display = "Body Bag", color = { 0.35, 0.35, 0.35, 1.0 } }

M.DROP_TYPES = {
    { key = "loot_dropped_guns", loot_type = "drop.gun", display = "Dropped Guns", color = { 0.95, 0.32, 0.22, 1.0 } },
    { key = "loot_dropped_items", loot_type = "drop.item", display = "Dropped Items", color = { 0.55, 0.55, 0.58, 1.0 } },
    { key = "loot_keycards", loot_type = "drop.keycard", display = "Keycards", color = { 0.95, 0.82, 0.32, 1.0 } },
}

M.TYPE_MAP = {}
M.NAME_MAP = {}
M.MULTICOMBO_ENTRIES = {}
M.MULTICOMBO_LABELS = {}
M.MULTICOMBO_DEFAULTS = {}
M.KEY_TO_INDEX = {}

local MODEL_ALIASES = {
    ["Ammunition Box"] = "ammo.crate",
    ["Safe"] = "big.safe",
    ["Cash Register"] = "cash.register",
    ["HospitalCabinet"] = "hospital.cabinet",
    ["StandingATM"] = "standing.atm",
    ["Military Crate"] = "military.supply",
    ["Raider Cache"] = "big.safe",
    ["Technical Shelf"] = "tool.shelf",
    ["Surgeon's Tool Shelf"] = "tool.shelf",
    ["WoodenDoor"] = "door",
    ["DoubleGlassDoor"] = "door",
    ["DoubleMetalDoor"] = "door",
    ["MetalDoor"] = "door",
    ["GarageDoorLock"] = "door",
}

local function rebuild()
    M.TYPE_MAP = {}
    M.NAME_MAP = {}
    M.MULTICOMBO_ENTRIES = {}
    M.MULTICOMBO_LABELS = {}
    M.MULTICOMBO_DEFAULTS = {}
    M.KEY_TO_INDEX = {}

    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        M.TYPE_MAP[entry.loot_type] = entry
        M.KEY_TO_INDEX[entry.key] = i
        M.MULTICOMBO_ENTRIES[i] = entry
        M.MULTICOMBO_LABELS[i] = entry.display
        M.MULTICOMBO_DEFAULTS[i] = true
    end

    local base = #M.LOOT_TYPES
    for i = 1, #M.DROP_TYPES do
        local entry = M.DROP_TYPES[i]
        local idx = base + i
        M.TYPE_MAP[entry.loot_type] = entry
        M.KEY_TO_INDEX[entry.key] = idx
        M.MULTICOMBO_ENTRIES[idx] = entry
        M.MULTICOMBO_LABELS[idx] = entry.display
        M.MULTICOMBO_DEFAULTS[idx] = true
    end

    local body_idx = base + #M.DROP_TYPES + 1
    M.TYPE_MAP[M.BODY_BAG_TYPE.loot_type] = M.BODY_BAG_TYPE
    M.KEY_TO_INDEX[M.BODY_BAG_TYPE.key] = body_idx
    M.MULTICOMBO_ENTRIES[body_idx] = M.BODY_BAG_TYPE
    M.MULTICOMBO_LABELS[body_idx] = M.BODY_BAG_TYPE.display
    M.MULTICOMBO_DEFAULTS[body_idx] = true

    for model_name, loot_type in pairs(MODEL_ALIASES) do
        M.NAME_MAP[model_name] = loot_type
    end
    for i = 1, #M.LOOT_TYPES do
        local entry = M.LOOT_TYPES[i]
        if entry.display then
            M.NAME_MAP[entry.display] = entry.loot_type
        end
    end
end

rebuild()

function M.resolve(loot_type_str, model_name)
    if loot_type_str and M.TYPE_MAP[loot_type_str] then
        return M.TYPE_MAP[loot_type_str]
    end
    if model_name then
        local alias = M.NAME_MAP[model_name]
        if alias and M.TYPE_MAP[alias] then
            return M.TYPE_MAP[alias]
        end
        if string.find(model_name, "Door", 1, true) then
            return M.TYPE_MAP["door"]
        end
    end
    return nil
end

function M.is_enabled(category)
    if not category or not category.key then return false end
    local settings = July.require("core.settings")
    return settings.bool(category.key, true)
end

function M.get_color(category)
    if not category or not category.key then return { 1, 1, 1, 1 } end
    local settings = July.require("core.settings")
    return settings.color(category.key, category.color or { 1, 1, 1, 1 })
end

return M
