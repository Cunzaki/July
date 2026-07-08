local havoc_catalog = July.require("game.havoc_item_catalog")
local env = July.require("core.env")

local M = {}

local runtime_cache = {}
local weapons_info = nil

local WEAPON_CATEGORIES = {
    "Primary",
    "Secondary",
    "Melee",
    "Grenades",
    "Throwable",
}

local function parse_rbx_asset_id(value)
    if value == nil then return nil end
    local text = tostring(value)
    if text == "" or text == "0" or text == "rbxassetid://0" then return nil end
    local id = text:match("rbxassetid://(%d+)") or text:match("^(%d+)$")
    if not id or id == "0" then return nil end
    return id
end

local function read_texture_id(folder)
    if not folder or not env.is_valid(folder) then return nil end
    local tex = env.find_child(folder, "textureId")
    if not tex then return nil end
    local ok, value = pcall(function() return tex.Value end)
    if not ok then return nil end
    return parse_rbx_asset_id(value)
end

local function get_weapons_info()
    if weapons_info and env.is_valid(weapons_info) then
        return weapons_info
    end

    weapons_info = nil
    if not game or not game.ReplicatedStorage then return nil end

    local temp = game.ReplicatedStorage:FindFirstChild("__tempSTORAGE")
    if not temp then return nil end

    local info = temp:FindFirstChild("weaponsInfo")
    if info and env.is_valid(info) then
        weapons_info = info
        return info
    end

    return nil
end

local function lookup_in_folder(folder, name)
    if not folder or not name or name == "" then return nil end
    local child = env.safe_call(function()
        if folder.FindFirstChild then return folder:FindFirstChild(name) end
        return nil
    end)
    if not child then return nil end
    return read_texture_id(child)
end

local function lookup_runtime(name, variant)
    local info = get_weapons_info()
    if not info then return nil end

    if variant and variant ~= "" then
        local item_folder = env.safe_call(function()
            return info:FindFirstChild(name)
        end)
        if item_folder then
            local skins = env.find_child(item_folder, "skins")
            local skin_folder = skins and env.safe_call(function()
                return skins:FindFirstChild(variant)
            end)
            local skin_id = read_texture_id(skin_folder)
            if skin_id then return skin_id end
        end
    end

    local asset_id = lookup_in_folder(info, name)
    if asset_id then return asset_id end

    for i = 1, #WEAPON_CATEGORIES do
        local cat = info:FindFirstChild(WEAPON_CATEGORIES[i])
        asset_id = lookup_in_folder(cat, name)
        if asset_id then return asset_id end
    end

    return nil
end

function M.lookup(name, variant)
    if not name or name == "" then return nil end

    local cache_key = name .. "\0" .. (variant or "")
    local cached = runtime_cache[cache_key]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end

    local     asset_id = lookup_runtime(name, variant)
    if not asset_id then
        asset_id = havoc_catalog.get_asset_id(name, variant)
    end
    if not asset_id then
        asset_id = July.require("game.item_images").get_asset_id(name, variant)
    end

    runtime_cache[cache_key] = asset_id or false
    if asset_id == "0" then return nil end
    return asset_id
end

function M.warm()
    local info = get_weapons_info()
    if not info then return 0 end

    local count = 0
    local ok, children = pcall(function() return info:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child.ClassName == "Folder" then
                local id = read_texture_id(child)
                if id then
                    M.lookup(child.Name)
                    count = count + 1
                end
            end
        end
    end

    for i = 1, #WEAPON_CATEGORIES do
        local cat = info:FindFirstChild(WEAPON_CATEGORIES[i])
        if cat then
            local ok2, cat_children = pcall(function() return cat:GetChildren() end)
            if ok2 and cat_children then
                for j = 1, #cat_children do
                    local weapon = cat_children[j]
                    local id = read_texture_id(weapon)
                    if id then
                        M.lookup(weapon.Name)
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

function M.reset()
    weapons_info = nil
    runtime_cache = {}
end

return M
