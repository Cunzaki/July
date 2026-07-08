local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")

local M = {}

local entity_by_model = {}
local characters_folder = nil
local entity_cache = {}
local entity_cache_stamp = -9999

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
            for j = 1, #constants.BONE_NAMES do
                if child.Name == constants.BONE_NAMES[j] then
                    parts[child.Name] = child
                    local ok_size, size = pcall(function() return child.Size end)
                    sizes[child.Name] = ok_size and size or nil
                    break
                end
            end
        end
    end

    return parts, sizes
end

local function get_or_create_entity(model, root, humanoid)
    local entry = entity_by_model[model]
    if entry then return entry end

    local parts, part_sizes = collect_body_parts(model)
    entry = {
        model = model,
        root = root,
        humanoid = humanoid,
        parts = parts,
        part_size = part_sizes,
        scr_bounds = { x = 0, y = 0, w = 0, h = 0, valid = false },
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
    if not root then return end

    local players = entity.GetPlayers()
    local out = {}
    collect_entities(root, players, out, 0)

    if #out > 0 then
        local new_by_model = {}
        for i = 1, #out do
            new_by_model[out[i].model] = out[i]
        end
        entity_by_model = new_by_model
        entity_cache = out
    end
end

function M.get_cache()
    return entity_cache
end

return M
