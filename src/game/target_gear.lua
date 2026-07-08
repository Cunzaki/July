local env = July.require("core.env")
local items = July.require("game.items")
local tier_util = July.require("game.tier_util")
local weapons = July.require("game.weapons")

local M = {}

local ATTACHMENT_SLOT_HINTS = {
    p1 = true, p2 = true, p3 = true, p4 = true,
    slot1 = true, slot2 = true, slot3 = true,
    sight = true, muzzle = true, underbarrel = true,
}

local function is_attachment_slot_name(name)
    if not name or name == "" then return true end
    local lower = name:lower()
    if ATTACHMENT_SLOT_HINTS[lower] then return true end
    if lower:match("^p%d+$") then return true end
    if lower:match("^slot%d+$") then return true end
    return false
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
        add_attachment(out, seen, children[i].Name, model)
    end
end

local function scan_tool_attachments(tool, model, out, seen)
    if not tool or not env.is_valid(tool) then return end

    local attachments = env.find_child(tool, "Attachments")
    scan_attachments_folder(attachments, model, out, seen)

    local weapon = env.find_child(tool, "Weapon")
    if weapon then
        scan_attachments_folder(env.find_child(weapon, "Attachments"), model, out, seen)
    end

    local at = env.find_child(tool, "_at")
    if at then
        scan_attachments_folder(at, model, out, seen)
    end
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

    local held = weapons.get_held_tool_name()
    if held and tier_util.is_gun_name(held) then
        return held, find_named_child(model, held)
    end

    return nil, nil
end

local function scan_weld_objects(model, out, seen)
    local weld = env.find_child(model, "WeldObjects")
    if not weld or not env.is_valid(weld) then return end

    local ok, children = pcall(function() return weld:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Model" and items.is_gear_piece_name(child.Name) then
            add_armor(out, seen, items.resolve_item_label(child.Name, model))
        end
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
        out.held = items.resolve_item_label(held_name, model)
    end

    local att_seen = {}
    scan_tool_attachments(tool_inst, model, out, att_seen)

    if not tool_inst then
        local ok, children = pcall(function() return model:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Tool" or child.ClassName == "Model" then
                    scan_tool_attachments(child, model, out, att_seen)
                end
            end
        end
    end

    local armor_seen = {}
    scan_weld_objects(model, out, armor_seen)

    return out
end

function M.scan_npc(ent)
    if not ent or not ent.model then
        return { held = nil, attachments = {}, armor = {} }
    end
    local out = scan_character(ent.model)
    local held_name = ent.held_name or ent._held_name
    if not out.held and held_name and held_name ~= "" then
        out.held = items.resolve_item_label(held_name, ent.model)
    end
    return out
end

function M.scan_player(player)
    local model = player and (player.Character or player.character)
    if not model or not env.is_valid(model) then
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
