local env = July.require("core.env")
local items = July.require("game.items")
local tier_util = July.require("game.tier_util")

local M = {}

local ATTACHMENT_SLOT_HINTS = {
    p1 = true, p2 = true, p3 = true, p4 = true,
    slot1 = true, slot2 = true, slot3 = true,
    sight = true, muzzle = true, underbarrel = true,
    foregrip = true, tactical = true,
}

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    if name:match("^%d+$") then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
end

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
    out.armor[#out.armor + 1] = piece
end

local function add_attachment(out, seen, label, model)
    if not label or label == "" or is_attachment_slot_name(label) then return end
    if seen[label] then return end
    seen[label] = true
    local piece = items.resolve_item_label(label, model)
    if piece then
        out.attachments[#out.attachments + 1] = piece
    end
end

local function scan_attachments_folder(folder, model, out, seen)
    if not folder or not env.is_valid(folder) then return end
    local ok, children = pcall(function() return folder:GetChildren() end)
    if not ok or not children then return end
    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Folder" or child.ClassName == "Model" then
            add_attachment(out, seen, child.Name, model)
        end
    end
end

local function scan_mods_folder(mods, model, out, seen)
    if not mods or not env.is_valid(mods) then return end
    local ok, slots = pcall(function() return mods:GetChildren() end)
    if not ok or not slots then return end
    for i = 1, #slots do
        local slot = slots[i]
        if slot.ClassName == "Folder" then
            local ok2, slot_children = pcall(function() return slot:GetChildren() end)
            if ok2 and slot_children then
                for j = 1, #slot_children do
                    local item = slot_children[j]
                    if item.ClassName == "Folder" or item.ClassName == "Model" then
                        add_attachment(out, seen, item.Name, model)
                    end
                end
            end
        end
    end
end

local function scan_tool_attachments(tool, model, out, seen)
    if not tool or not env.is_valid(tool) then return end

    local data = env.find_child(tool, "_data")
    if data then
        scan_mods_folder(env.find_child(data, "mods"), model, out, seen)

        local mag = env.find_child(data, "magAttached")
        if mag then
            local ok, value = pcall(function() return mag.Value end)
            if ok and value and value ~= "" then
                add_attachment(out, seen, value, model)
            end
        end
    end

    scan_attachments_folder(env.find_child(tool, "Attachments"), model, out, seen)

    local weapon = env.find_child(tool, "Weapon")
    if weapon then
        scan_attachments_folder(env.find_child(weapon, "Attachments"), model, out, seen)
    end

    scan_attachments_folder(env.find_child(tool, "_at"), model, out, seen)
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

local function scan_gear_model(piece_model, out, armor_seen, att_seen)
    if not piece_model or not env.is_valid(piece_model) then return end
    if piece_model.ClassName ~= "Model" then return end

    local name = piece_model.Name
    if name == "Mask" then return end

    if items.is_gear_piece_name(name) then
        add_armor(out, armor_seen, items.resolve_item_label(name, piece_model))
    end

    scan_attachments_folder(env.find_child(piece_model, "_at"), piece_model, out, att_seen)
end

local function scan_weld_folder(weld, out, armor_seen, att_seen)
    if not weld or not env.is_valid(weld) then return end

    local ok, children = pcall(function() return weld:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_gear_model(children[i], out, armor_seen, att_seen)
    end
end

local function scan_weld_objects(model, out, armor_seen, att_seen)
    local pools = collect_weld_pools(model)
    for i = 1, #pools do
        scan_weld_folder(pools[i], out, armor_seen, att_seen)
    end
end

local function scan_character(model)
    local out = {
        held = nil,
        attachments = {},
        armor = {},
    }

    if not model or not env.is_valid(model) then return out end

    local held_name, tool_inst = resolve_held(model)
    if held_name then
        out.held = items.resolve_item_label(held_name, tool_inst or model)
    end

    local att_seen = {}
    scan_tool_attachments(tool_inst, model, out, att_seen)

    if not tool_inst then
        local ok, children = pcall(function() return model:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Tool" or (child.ClassName == "Model" and tier_util.is_gun_name(child.Name)) then
                    scan_tool_attachments(child, model, out, att_seen)
                end
            end
        end
    end

    if not out.held then
        scan_holsters(model, out)
    end

    local armor_seen = {}
    scan_weld_objects(model, out, armor_seen, att_seen)

    return out
end

function M.scan_npc(ent)
    local model = resolve_character_model(ent)
    if not model then
        return { held = nil, attachments = {}, armor = {} }
    end

    local out = scan_character(model)
    local held_name = ent.held_name or ent._held_name
    if not out.held and held_name and held_name ~= "" then
        out.held = items.resolve_item_label(held_name, model)
    end
    return out
end

function M.scan_player(player)
    local model = resolve_character_model({ player = player, is_npc = false })
    if not model then
        return { held = nil, attachments = {}, armor = {} }
    end
    return scan_character(model)
end

function M.scan_target(target)
    if not target then
        return { held = nil, attachments = {}, armor = {} }
    end
    if target.is_npc then
        return M.scan_npc(target)
    end
    return M.scan_player(target.player or target)
end

return M
