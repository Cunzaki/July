local havoc_icons = July.require("game.havoc_icons")
local havoc_catalog = July.require("game.havoc_item_catalog")
local item_images = July.require("game.item_images")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")

local M = {}

local SKIP_WELD_NAMES = {
    Mask = true,
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
    end

    return nil
end

function M.make_piece(name, variant, model)
    if not name or name == "" then return nil end

    return {
        name = name,
        variant = variant,
        asset_id = resolve_asset_id(name, variant, model),
    }
end

function M.resolve_item_label(label, model)
    if not label or label == "" then return nil end
    local base, variant = parse_variant_name(label)
    if tier_util.is_known_item(base) or tier_util.is_gun_name(base) or tier_util.is_keycard(base) then
        return M.make_piece(base, variant, model)
    end
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
    if tier_util.is_known_item(name) or tier_util.is_gun_name(name) or tier_util.is_keycard(name) then
        return true
    end
    return havoc_catalog.get_asset_id(name) ~= nil
end

return M
