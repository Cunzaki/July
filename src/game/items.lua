local havoc_icons = July.require("game.havoc_icons")
local havoc_catalog = July.require("game.havoc_item_catalog")
local item_images = July.require("game.item_images")
local gear_types = July.require("game.gear_types")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")

local M = {}

local SKIP_WELD_NAMES = {
    WeldObjectsLink = true,
    thermalTemplate = true,
    welds = true,
    _at = true,
    _mod = true,
}

local function parse_variant_name(name)
    if not name then return nil, nil end
    local base, variant = name:match("^([^/]+)/(.+)$")
    if base and variant then return base, variant end
    return name, nil
end

local function read_string_value(inst)
    if not inst then return nil end
    local ok, value = pcall(function() return inst.Value end)
    if ok and value and value ~= "" then return tostring(value) end
    return nil
end

local function variant_from_model(model, name)
    if not model or not env.is_valid(model) then return nil end

    local data = env.find_child(model, "_data")
    if data then
        local variant = read_string_value(env.find_child(data, "variant"))
            or read_string_value(env.find_child(data, "skin"))
            or read_string_value(env.find_child(data, "skinName"))
        if variant then return variant end
    end

    local link = env.find_child(model, "linkItemFolder")
    if link and link.ClassName == "ObjectValue" then
        local ok, folder = pcall(function() return link.Value end)
        if ok and folder and env.is_valid(folder) then
            local folder_variant = read_string_value(env.find_child(folder, "variant"))
                or read_string_value(env.find_child(folder, "skin"))
            if folder_variant then return folder_variant end
        end
    end

    local skins = env.find_child(model, "skins")
    if skins then
        local ok, children = pcall(function() return skins:GetChildren() end)
        if ok and children and #children == 1 then
            return children[1].Name
        end
    end

    return nil
end

local function texture_asset_from_inst(inst)
    if not inst or not env.is_valid(inst) then return nil end

    local tex_val = env.find_child(inst, "textureId")
    if tex_val then
        local ok, value = pcall(function() return tex_val.Value end)
        if ok and value then
            local id = tostring(value):match("rbxassetid://(%d+)") or tostring(value):match("^(%d+)$")
            if id and id ~= "0" then return id end
        end
    end

    local handle = env.find_child(inst, "Handle")
    if handle then
        local ok, tex = pcall(function() return handle.TextureID end)
        if ok and tex and tex ~= "" then
            local id = tostring(tex):match("(%d+)")
            if id and id ~= "0" then return id end
        end
    end

    return nil
end

local function find_named_child(model, name)
    if not model or not name then return nil end
    return env.safe_call(function()
        if model.FindFirstChild then
            local ok, found = pcall(function() return model:FindFirstChild(name, true) end)
            if ok and found then return found end
            return model:FindFirstChild(name)
        end
        return nil
    end)
end

local function resolve_asset_id(name, variant, model)
    local asset_id = havoc_icons.lookup(name, variant)
    if asset_id and asset_id ~= "0" then return asset_id end

    asset_id = havoc_catalog.get_asset_id(name, variant)
    if asset_id and asset_id ~= "0" then return asset_id end

    asset_id = item_images.get_asset_id(name, variant)
    if asset_id and asset_id ~= "0" then return asset_id end

    if model then
        local inst = find_named_child(model, name)
        asset_id = texture_asset_from_inst(inst)
        if asset_id then return asset_id end
        asset_id = texture_asset_from_inst(model)
        if asset_id then return asset_id end
    end

    return nil
end

function M.make_piece(name, variant, model)
    if not name or name == "" then return nil end

    if not variant or variant == "" then
        variant = variant_from_model(model, name)
    end

    return {
        name = name,
        variant = variant,
        slot = gear_types.get_slot(name),
        asset_id = resolve_asset_id(name, variant, model),
    }
end

function M.resolve_item_label(label, model)
    if not label or label == "" then return nil end
    local base, variant = parse_variant_name(label)
    return M.make_piece(base, variant, model)
end

function M.get_image_asset_id(name, variant, model)
    local piece = M.resolve_item_label(name, model)
    if piece and piece.variant ~= variant and variant then
        piece = M.make_piece(piece.name, variant, model)
    end
    return piece and piece.asset_id or nil
end

function M.is_gear_piece_name(name)
    if not name or name == "" then return false end
    if SKIP_WELD_NAMES[name] then return false end
    if name:sub(1, 1) == "_" then return false end
    if gear_types.is_gear(name) then return true end
    if tier_util.is_known_item(name) or tier_util.is_gun_name(name) or tier_util.is_keycard(name) then
        return true
    end
    if havoc_catalog.get_asset_id(name) then return true end
    if item_images.get_asset_id(name) then return true end
    return false
end

return M
