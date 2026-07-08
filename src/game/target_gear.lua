local env = July.require("core.env")
local items = July.require("game.items")
local gear_types = July.require("game.gear_types")
local tier_util = July.require("game.tier_util")

local M = {}

local function resolve_character_model(target)
    if not target then return nil end
    if target.is_npc then
        local model = target.model or target.inst or target.character
        if model and env.is_valid(model) then return model end
        return model
    end

    local p = target.player or target
    if p then
        local char = target.character or p.Character or p.character
        if char and env.is_valid(char) then return char end
    end

    local model = target.character or target.model or target.inst
    if model and env.is_valid(model) then return model end
    return model
end

local function add_armor(out, seen, piece)
    if not piece or not piece.name then return end
    if seen[piece.name] then return end
    seen[piece.name] = true
    if not piece.slot then
        piece.slot = gear_types.get_slot(piece.name)
    end
    out.armor[#out.armor + 1] = piece
end

local function resolve_held(model)
    if not model or not env.is_valid(model) then return nil, nil end

    local ok, children = pcall(function() return model:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child.ClassName == "Tool" then
                return child.Name, child
            end
            if child.ClassName == "Model" and tier_util.is_gun_name(child.Name) then
                return child.Name, child
            end
        end
    end

    return nil, nil
end

local function scan_holsters(model, out)
    if not model or not env.is_valid(model) or out.held then return end

    local holsters = env.find_child(model, "Holsters")
    local holster_models = holsters and env.find_child(holsters, "Models")
    if not holster_models then return end

    local ok, children = pcall(function() return holster_models:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Model" or child.ClassName == "Tool" then
            if tier_util.is_gun_name(child.Name) then
                out.held = items.resolve_item_label(child.Name, child)
                return
            end
        end
    end
end

local function get_weld_pool_from_link(model)
    local link = env.find_child(model, "WeldObjectsLink")
    if not link or link.ClassName ~= "ObjectValue" then return nil end

    local ok, target = pcall(function() return link.Value end)
    if not ok or not target or not env.is_valid(target) then return nil end

    if target.ClassName == "Folder" and target.Name:match("^WeldObjects") then
        return target
    end

    local nested = env.find_child(target, "WeldObjects")
    if nested and nested.Name:match("^WeldObjects") then
        return nested
    end

    return target
end

local function pool_matches_character(pool, model)
    if not pool or not model then return false end
    local link = env.find_child(pool, "WeldObjectsLink")
    if not link or link.ClassName ~= "ObjectValue" then return false end

    local ok, value = pcall(function() return link.Value end)
    if not ok or not value then return false end

    if value == model then return true end
    local ok2, same = pcall(function() return tostring(value) == tostring(model) end)
    return ok2 and same
end

local function find_weld_pool_by_reverse_link(model)
    local ws = env.get_workspace()
    if not ws or not model then return nil end

    local roots = {}
    local direct = ws:FindFirstChild("_weldobjects.temp.others")
    if direct then roots[#roots + 1] = direct end

    local ignored = ws:FindFirstChild("Ignored")
    if ignored then
        local nested = ignored:FindFirstChild("_weldobjects.temp.others")
        if nested then roots[#roots + 1] = nested end
    end

    for r = 1, #roots do
        local root = roots[r]
        local ok, children = pcall(function() return root:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local pool = children[i]
                if pool.ClassName == "Folder" and pool.Name:match("^WeldObjects") then
                    if pool_matches_character(pool, model) then
                        return pool
                    end
                end
            end
        end
    end

    return nil
end

local function collect_weld_pools(model)
    local pools = {}
    local seen = {}

    local function add_pool(pool)
        if not pool or not env.is_valid(pool) then return end
        local key = tostring(pool)
        if seen[key] then return end
        seen[key] = true
        pools[#pools + 1] = pool
    end

    add_pool(env.find_child(model, "WeldObjects"))

    local linked = get_weld_pool_from_link(model)
    if linked then
        add_pool(linked)
    else
        add_pool(find_weld_pool_by_reverse_link(model))
    end

    return pools
end

local function scan_gear_model(piece_model, out, armor_seen)
    if not piece_model or not env.is_valid(piece_model) then return end
    if piece_model.ClassName ~= "Model" then return end

    local name = piece_model.Name
    if items.is_gear_piece_name(name) then
        add_armor(out, armor_seen, items.resolve_item_label(name, piece_model))
    end
end

local function scan_weld_folder(weld, out, armor_seen)
    if not weld or not env.is_valid(weld) then return end

    local ok, children = pcall(function() return weld:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_gear_model(children[i], out, armor_seen)
    end
end

local function scan_weld_objects(model, out, armor_seen)
    local pools = collect_weld_pools(model)
    for i = 1, #pools do
        scan_weld_folder(pools[i], out, armor_seen)
    end
end

local function scan_backpack_items(backpack, out)
    if not backpack or not env.is_valid(backpack) then return end

    local seen = {}
    local ok, children = pcall(function() return backpack:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        local name = child.Name
        if not name or name == "" or seen[name] then goto continue_child end

        local is_item = child.ClassName == "Tool"
            or (child.ClassName == "Model" and (tier_util.is_gun_name(name) or items.is_gear_piece_name(name)))

        if is_item then
            seen[name] = true
            out.stash[#out.stash + 1] = items.resolve_item_label(name, child)
        end

        ::continue_child::
    end
end

local function scan_npc_held(model, ent, out)
    local held_name, tool_inst = resolve_held(model)
    if not held_name and ent then
        held_name = ent.held_name or ent._held_name
        if held_name and held_name ~= "" then
            local child = env.find_child(model, held_name)
            if child and env.is_valid(child) then
                tool_inst = child
            end
        end
    end

    if held_name then
        out.held = items.resolve_item_label(held_name, tool_inst or model)
    end
end

local function scan_character(model)
    local out = {
        held = nil,
        armor = {},
        stash = {},
    }

    if not model or not env.is_valid(model) then return out end

    local held_name, tool_inst = resolve_held(model)
    if held_name then
        out.held = items.resolve_item_label(held_name, tool_inst or model)
    end

    if not out.held then
        scan_holsters(model, out)
    end

    local armor_seen = {}
    scan_weld_objects(model, out, armor_seen)

    return out
end

function M.scan_npc(ent)
    local model = resolve_character_model(ent)
    local out = {
        held = nil,
        armor = {},
        stash = {},
        is_npc = true,
    }
    if not model then return out end

    scan_npc_held(model, ent, out)
    return out
end

function M.scan_player(player)
    local model = resolve_character_model({ player = player, is_npc = false })
    if not model then
        return { held = nil, armor = {}, stash = {} }
    end

    local out = scan_character(model)
    local backpack = player.Backpack or player.backpack
    if backpack then
        scan_backpack_items(backpack, out)
    end
    return out
end

function M.scan_target(target)
    if not target then
        return { held = nil, armor = {}, stash = {} }
    end
    if target.is_npc then
        return M.scan_npc(target)
    end
    return M.scan_player(target.player or target)
end

return M
