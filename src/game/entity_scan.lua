local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local havoc_sync = July.require("game.havoc_sync")
local npc_types = July.require("game.npc_types")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")

local M = {}

local entity_by_model = {}
local characters_folder = nil
local entity_cache = {}
local entity_cache_stamp = -9999
local entity_live_cursor = 1

local function is_humanoid_by_properties(obj)
    local ok_health, health = pcall(function() return obj.Health end)
    local ok_maxh, maxh = pcall(function() return obj.MaxHealth end)
    if ok_health and ok_maxh then
        if type(health) == "number" and type(maxh) == "number" then
            return true
        end
    end
    return false
end

local function find_humanoid(model)
    local ok, hum = pcall(function() return model:FindFirstChildOfClass("Humanoid") end)
    if ok and hum then return hum end
    local ok_c, children = pcall(function() return model:GetChildren() end)
    if ok_c and children then
        for i = 1, #children do
            if is_humanoid_by_properties(children[i]) then
                return children[i]
            end
        end
    end
    return nil
end

local function collect_body_parts(model)
    local parts = {}
    local sizes = {}
    local ok, children = pcall(function() return model:GetChildren() end)
    if not ok or not children then return parts, sizes end

    for i = 1, #children do
        local child = children[i]
        local cls = child.ClassName
        if cls == "Part" or cls == "MeshPart" then
            parts[child.Name] = child
            local ok_size, size = pcall(function() return child.Size end)
            sizes[child.Name] = ok_size and size or nil
        end
    end

    return parts, sizes
end

local function get_or_create_entity(model, root, humanoid)
    local entry = entity_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) and env.is_valid(entry.humanoid) then
            entry.root = root
            entry.humanoid = humanoid
            return entry
        end
        entity_by_model[model] = nil
    end

    local parts, part_sizes = collect_body_parts(model)
    local is_boss, is_sniper = npc_types.classify(model)

    entry = {
        model = model,
        root = root,
        humanoid = humanoid,
        parts = parts,
        part_size = part_sizes,
        scr_bounds = { x = 0, y = 0, w = 0, h = 0, valid = false },
        is_boss = is_boss,
        is_sniper = is_sniper,
    }
    entity_by_model[model] = entry
    return entry
end

local function is_player_character(model, root, players)
    for i = 1, #players do
        local char = players[i].Character
        if char and char == model then
            return true
        end
    end

    local ok, pos = pcall(function() return root.Position end)
    if not ok or not pos then return false end

    for i = 1, #players do
        local ok_ppos, ppos = pcall(function() return players[i].Position end)
        if ok_ppos and ppos and (pos - ppos).Magnitude < constants.PLAYER_MATCH_DIST then
            return true
        end
    end

    local ok_lp, local_player = pcall(entity.GetLocalPlayer)
    if ok_lp and local_player then
        local ok_char, char = pcall(function() return local_player.Character end)
        if ok_char and char and char == model then
            return true
        end

        local ok_lp_pos, lp_pos = pcall(function() return local_player.Position end)
        if ok_lp_pos and lp_pos and (pos - lp_pos).Magnitude < constants.PLAYER_MATCH_DIST then
            return true
        end
    end

    return false
end

local function collect_entities(container, players, out, depth)
    if depth > 6 then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" or cls == "WorldModel" then
            local hum = find_humanoid(child)
            if hum then
                local root = child:FindFirstChild("HumanoidRootPart")
                    or child:FindFirstChild("Torso")
                    or child:FindFirstChild("UpperTorso")
                    or child:FindFirstChild("Head")
                    or child:FindFirstChildWhichIsA("BasePart")

                if root and not is_player_character(child, root, players) then
                    out[#out + 1] = get_or_create_entity(child, root, hum)
                end
            else
                collect_entities(child, players, out, depth + 1)
            end
        elseif cls == "Folder" then
            collect_entities(child, players, out, depth + 1)
        end
    end
end

local function get_entity_root()
    if characters_folder and not env.is_valid(characters_folder) then
        characters_folder = nil
    end

    local folder = havoc_sync.get_characters_folder()
    if folder then
        characters_folder = folder
        return folder
    end

    if not characters_folder then
        local ok, ws_children = pcall(function() return game.Workspace:GetChildren() end)
        if ok and ws_children then
            for i = 1, #ws_children do
                local child = ws_children[i]
                if child:IsA("Model") or child:IsA("Folder") then
                    local ok2, sub = pcall(function() return child:GetChildren() end)
                    if ok2 and sub then
                        for j = 1, #sub do
                            local subchild = sub[j]
                            if subchild:IsA("Model") then
                                local hum = subchild:FindFirstChildOfClass("Humanoid")
                                if not hum then
                                    local ok3, subsub = pcall(function() return subchild:GetChildren() end)
                                    if ok3 and subsub then
                                        for k = 1, #subsub do
                                            if is_humanoid_by_properties(subsub[k]) then
                                                hum = subsub[k]
                                                break
                                            end
                                        end
                                    end
                                end
                                if hum then
                                    characters_folder = child
                                    return characters_folder
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return characters_folder
end

function M.refresh()
    local now = os.clock()
    local interval = characters_folder and constants.ENTITY_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if (now - entity_cache_stamp) < interval then return end
    entity_cache_stamp = now

    local root = get_entity_root()
    if not root then
        entity_cache = {}
        entity_by_model = {}
        return
    end

    local players = entity.GetPlayers()
    local out = {}
    collect_entities(root, players, out, 0)

    local new_by_model = {}
    for i = 1, #out do
        new_by_model[out[i].model] = out[i]
    end
    entity_by_model = new_by_model
    entity_cache = out
    if entity_live_cursor > #entity_cache then
        entity_live_cursor = 1
    end
end

local function get_held_weapon_inst(model)
    if not model then return nil, nil end

    local ok, model_children = pcall(function() return model:GetChildren() end)
    if ok and model_children then
        for i = 1, #model_children do
            local child = model_children[i]
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

local function get_held_weapon_name(model)
    local name = get_held_weapon_inst(model)
    return name
end

local HELD_EMPTY_CLEAR_TICKS = 45
local WEAPON_STATE_CLEAR_TICKS = 45

local function read_weapon_values(weapon)
    local ammo_current, reloading = nil, nil

    local data = env.find_child(weapon, "_data")
    if not data then
        return ammo_current, reloading
    end

    local ammo = env.find_child(data, "ammoCurrent")
    if ammo then
        local ok, value = pcall(function() return ammo.Value end)
        ammo_current = ok and value or nil
    end

    local reload = env.find_child(data, "reload")
    if reload then
        local reloading_inst = env.find_child(reload, "reloading")
        if reloading_inst then
            local ok, value = pcall(function() return reloading_inst.Value end)
            reloading = ok and value == true or false
        end
    end

    return ammo_current, reloading
end

local function refresh_weapon_state(ent)
    local name, weapon = get_held_weapon_inst(ent.model)
    if name and name ~= "" and weapon then
        ent._held_name = name
        ent._held_empty_ticks = 0
        ent._weapon_empty_ticks = 0
        ent._ammo_current, ent._reloading = read_weapon_values(weapon)
        return
    end

    ent._weapon_empty_ticks = (ent._weapon_empty_ticks or 0) + 1
    if ent._weapon_empty_ticks >= WEAPON_STATE_CLEAR_TICKS then
        ent._held_name = nil
        ent._ammo_current = nil
        ent._reloading = nil
        ent._weapon_empty_ticks = 0
        ent._held_empty_ticks = 0
    end
end

local function refresh_held_name(ent)
    refresh_weapon_state(ent)
end

-- Live read for draw frame; keeps last good values on transient misses (no flicker).
function M.read_weapon_display(ent)
    if not ent or not ent.model then
        return ent and ent._held_name, ent and ent._ammo_current, ent and ent._reloading
    end

    local name, weapon = get_held_weapon_inst(ent.model)
    if name and name ~= "" and weapon then
        ent._held_name = name
        ent._held_empty_ticks = 0
        ent._weapon_empty_ticks = 0
        ent._ammo_current, ent._reloading = read_weapon_values(weapon)
        return ent._held_name, ent._ammo_current, ent._reloading
    end

    return ent._held_name, ent._ammo_current, ent._reloading
end

function M.refresh_live()
    local n = #entity_cache
    if n == 0 then return end

    if entity_live_cursor > n then entity_live_cursor = 1 end

    local batch = math.min(constants.ENTITY_LIVE_BATCH_SIZE or 16, n)
    for _ = 1, batch do
        local ent = entity_cache[entity_live_cursor]
        if ent and env.is_valid(ent.model) and env.is_valid(ent.root) and env.is_valid(ent.humanoid) then
            local ok_pos, pos = pcall(function() return ent.root.Position end)
            if ok_pos and pos then
                ent._live_pos = pos
                local px, py, pz = pos.X or pos.x, pos.Y or pos.y, pos.Z or pos.z
                if px then
                    ent._sx, ent._sy, ent._sok = utility.WorldToScreen(px, py, pz)
                end
            end
            local is_boss, is_sniper = npc_types.classify(ent.model)
            ent.is_boss = is_boss
            ent.is_sniper = is_sniper
            refresh_held_name(ent)
            refresh_weapon_state(ent)
        end
        entity_live_cursor = entity_live_cursor + 1
        if entity_live_cursor > n then entity_live_cursor = 1 end
    end
end

function M.is_entry_valid(ent)
    return ent
        and env.is_valid(ent.model)
        and env.is_valid(ent.root)
        and env.is_valid(ent.humanoid)
end

function M.invalidate()
    characters_folder = nil
    entity_by_model = {}
    entity_cache = {}
    entity_cache_stamp = -9999
    entity_live_cursor = 1
    havoc_sync.reset()
end

function M.get_cache()
    return entity_cache
end

return M
