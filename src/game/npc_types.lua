local env = July.require("core.env")

local M = {}

-- Dump-backed bosses (__tempSTORAGE.characters) + legacy Havoc boss names.
M.BOSS_NAMES = {
    Anvil = true,
    Boris = true,
    Breaker = true,
    Bruno = true,
    Brutus = true,
    Bullet = true,
    Cervus = true,
    Charger = true,
    Checkmate = true,
    Cipher = true,
    Clutch = true,
    Cobra = true,
    Crossfire = true,
    Dagger = true,
    Falcon = true,
    Fox = true,
    Ghost = true,
    Grizzly = true,
    Gunner = true,
    Hawk = true,
    Ironclad = true,
    Kingslayer = true,
    Knox = true,
    Kodiak = true,
    Lockstep = true,
    Lynx = true,
    Mamba = true,
    Maverick = true,
    Omen = true,
    Phantom = true,
    Phoenix = true,
    Queensguard = true,
    Ranger = true,
    Raptor = true,
    Scorch = true,
    Shade = true,
    Spartan = true,
    Stalemate = true,
    Tagilla = true,
    Talon = true,
    Vandal = true,
    Volt = true,
    Warlock = true,
    Wolf = true,
    Zero = true,
}

M.SNIPER_NAMES = {
    Sentry = true,
}

local function strip_sniper_prefix(name)
    if not name then return "" end
    local stripped = name:match("^%[Sniper%]%s*(.+)$")
    return stripped or name
end

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
            if model:GetAttribute("Boss") or model:GetAttribute("IsBoss") then
                is_boss = true
            end
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
    local base_name = strip_sniper_prefix(name)

    if not is_boss then
        if M.BOSS_NAMES[name] or M.BOSS_NAMES[base_name] or M.has_boss_template(model) then
            is_boss = true
        end
    end

    if not is_boss then
        if M.SNIPER_NAMES[name]
            or M.SNIPER_NAMES[base_name]
            or name:find("Sniper", 1, true)
            or name:find("[Sniper]", 1, true)
        then
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
    if ent.model then
        local name = ent.model.Name or ""
        if name == "Sentry" or name:find("Sentry", 1, true) then
            return "Sentry"
        end
    end
    return "Scav"
end

function M.combat_kind(ent)
    if not ent then return "soldier" end
    if ent.is_boss then return "boss" end
    if ent.is_sniper then return "sniper" end
    return "soldier"
end

return M
