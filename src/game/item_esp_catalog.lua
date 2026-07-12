local item_categories = July.require("game.item_categories")
local settings = July.require("core.settings")

local M = {}

M.SECTION_COLORS = {
    ammo = { 0.85, 0.75, 0.35, 1.0 },
    attachments = { 0.55, 0.65, 0.75, 1.0 },
    buildings = { 0.45, 0.55, 0.45, 1.0 },
    containers = { 0.7, 0.55, 0.35, 1.0 },
    documents = { 0.9, 0.9, 0.7, 1.0 },
    electronics = { 0.35, 0.85, 0.95, 1.0 },
    gears = { 0.95, 0.45, 0.25, 1.0 },
    households = { 0.75, 0.75, 0.8, 1.0 },
    mags = { 0.6, 0.6, 0.65, 1.0 },
    medical = { 0.9, 0.25, 0.25, 1.0 },
    tools = { 0.4, 0.7, 0.9, 1.0 },
    valuables = { 1.0, 0.85, 0.2, 1.0 },
}

M.ITEM_INDEX = {}
M.NORM_INDEX = {}

local function normalize_name(name)
    if not name then return nil end
    name = name:gsub("\194\226\128\153", "'"):gsub("\194\226\128\156", "\""):gsub("\194\226\128\157", "\"")
    name = name:gsub("%s+", " ")
    return name:match("^%s*(.-)%s*$")
end

local function rebuild_index()
    M.ITEM_INDEX = {}
    M.NORM_INDEX = {}
    for si = 1, #item_categories.SECTIONS do
        local sec = item_categories.SECTIONS[si]
        for ii = 1, #(sec.items or {}) do
            local name = sec.items[ii]
            M.ITEM_INDEX[name] = { sec.id, ii, si }
            local norm = normalize_name(name)
            if norm then
                M.NORM_INDEX[norm] = { sec.id, ii, si }
            end
        end
    end
end

rebuild_index()

function M.normalize_name(name)
    return normalize_name(name)
end

function M.section_multicombo_id(cat_id)
    return "item_sec_" .. cat_id
end

function M.item_color_id(cat_id, item_idx)
    return "item_clr_" .. cat_id .. "_" .. tostring(item_idx)
end

function M.lookup_item(name)
    if not name or name == "" then return nil end
    local map = M.ITEM_INDEX[name] or M.NORM_INDEX[normalize_name(name)]
    return map
end

function M.is_item_enabled(name, category)
    if category and category.loot_type == "body.bag" then
        return settings.bool("havoc_item_show_body_bags", true)
    end
    if category and category.loot_type == "drop.keycard" then
        return settings.bool("havoc_item_show_keycards", true)
    end
    if category and category.loot_type == "drop.gun" then
        return settings.bool("havoc_item_show_guns", true)
    end

    if not name or name == "" then return false end
    local map = M.lookup_item(name)
    if not map then return true end
    local cat_id, item_idx = map[1], map[2]
    return settings.multi(M.section_multicombo_id(cat_id), item_idx, true)
end

function M.get_item_color(name)
    local tier_util = July.require("game.tier_util")
    local map = M.lookup_item(name)
    if not map then
        return tier_util.get_esp_color(name)
    end
    local cat_id, item_idx = map[1], map[2]
    local default = M.SECTION_COLORS[cat_id] or tier_util.get_esp_color(name)
    return settings.color(M.item_color_id(cat_id, item_idx), default)
end

function M.is_drop_category(category)
    if not category or not category.loot_type then return false end
    local lt = category.loot_type
    return lt == "drop.gun" or lt == "drop.item" or lt == "drop.keycard" or lt == "body.bag"
end

return M
