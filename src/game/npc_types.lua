--[[
    NPC classification for Project Vector.
    Boss templates: ReplicatedStorage/__tempSTORAGE/characters/<name>/WeldObjects/Mask
    Runtime: Character:GetAttribute("Boss") / GetAttribute("Sniper")
]]

local M = {}

-- Codename elite NPCs from dump character templates (+ legacy aliases).
M.BOSS_NAMES = {
    Boris = true,
    Bruno = true,
    Brutus = true,
    Tagilla = true,
    Ranger = true,
    Clutch = true,
    Kodiak = true,
    Vandal = true,
    Grizzly = true,
    Crossfire = true,
    Warlock = true,
    Stalemate = true,
    Lynx = true,
    Hawk = true,
    Talon = true,
    Volt = true,
    Dagger = true,
    Spartan = true,
    Cipher = true,
    Maverick = true,
    Falcon = true,
    Checkmate = true,
    Scorch = true,
    Raptor = true,
    Knox = true,
    Fox = true,
    Bullet = true,
    Zero = true,
    Cobra = true,
    Ghost = true,
    Shade = true,
    Mamba = true,
    Phoenix = true,
    Anvil = true,
    Gunner = true,
}

M.SNIPER_NAMES = {
    Sentry = true,
}

function M.has_boss_template(model)
    if not model then return false end

    local ok, weld = pcall(function() return model:FindFirstChild("WeldObjects") end)
    if not ok or not weld then return false end

    local ok_mask, mask = pcall(function() return weld:FindFirstChild("Mask") end)
    return ok_mask and mask and mask.ClassName == "Model"
end

function M.read_attributes(model)
    local is_boss = false
    local is_sniper = false

    pcall(function()
        if model.GetAttribute then
            if model:GetAttribute("Boss") then is_boss = true end
            if model:GetAttribute("Sniper") or model:GetAttribute("IsSniper") then
                is_sniper = true
            end
        end
    end)

    return is_boss, is_sniper
end

function M.classify(model)
    if not model then return false, false end

    local is_boss, is_sniper = M.read_attributes(model)
    local name = model.Name or ""

    if not is_boss then
        if M.BOSS_NAMES[name] or M.has_boss_template(model) then
            is_boss = true
        end
    end

    if not is_boss then
        if M.SNIPER_NAMES[name] or name:find("Sniper", 1, true) then
            is_sniper = true
        end
    else
        is_sniper = false
    end

    return is_boss, is_sniper
end

function M.display_type(ent)
    if not ent then return nil end
    if ent.is_boss then return "Boss" end
    if ent.is_sniper then return "Sniper" end
    if ent.model and ent.model.Name == "Sentry" then return nil end
    return "Scav"
end

function M.combat_kind(ent)
    if not ent then return "soldier" end
    if ent.is_boss then return "boss" end
    if ent.is_sniper then return "sniper" end
    return "soldier"
end

return M
