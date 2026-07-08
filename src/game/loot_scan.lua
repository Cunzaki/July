local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local loot_catalog = July.require("game.loot_catalog")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")
local havoc_sync = July.require("game.havoc_sync")

local M = {}

local loot_by_model = {}
local loot_cache = {}
local loot_cache_stamp = -9998
local drop_cache_stamp = -9996
local loot_live_cursor = 1
local buildings_folder = nil
local objects_folder = nil

local function vec3(pos)
    if not pos then return nil end
    return {
        X = pos.X or pos.x or 0,
        Y = pos.Y or pos.y or 0,
        Z = pos.Z or pos.z or 0,
    }
end

local function collect_model_parts(model, part_pos, part_size, depth)
    if depth > 4 then return end
    local ok, children = pcall(function() return model:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()
        local child = children[i]
        local cls = child.ClassName
        if cls == "Part" or cls == "MeshPart" then
            local ok_pos, pos = pcall(function() return child.Position end)
            local ok_size, size = pcall(function() return child.Size end)
            if ok_pos and pos then
                part_pos[child] = vec3(pos)
                part_size[child] = ok_size and size or nil
            end
        elseif cls == "Model" or cls == "Folder" then
            collect_model_parts(child, part_pos, part_size, depth + 1)
        end
    end
end

local function get_loot_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local loot_type = data:FindFirstChild("lootType")
    local is_open = data:FindFirstChild("isOpen")
    local is_locked = data:FindFirstChild("isLocked")
    if not (loot_type and is_open and is_locked) then return nil end

    local type_str = nil
    pcall(function()
        type_str = loot_type.Value
    end)

    return type_str, is_open, is_locked
end

local function get_door_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local is_open = data:FindFirstChild("isOpen")
    if not is_open then return nil end

    local is_locked = data:FindFirstChild("isLocked")
        or data:FindFirstChild("isKeyRequired")
        or data:FindFirstChild("lockable")

    return is_open, is_locked
end

local function get_or_create_loot(model, root, category, is_open_inst, is_locked_inst)
    local entry = loot_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) then
            entry.category = category or entry.category
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)
    local part_pos, part_size = {}, {}
    collect_model_parts(model, part_pos, part_size, 0)

    entry = {
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
        part_pos = part_pos,
        part_size = part_size,
        is_open_inst = is_open_inst,
        is_locked_inst = is_locked_inst,
        is_open = nil,
        is_locked = nil,
        category = category,
    }
    loot_by_model[model] = entry
    return entry
end

local function is_equipped_tool(tool)
    local parent = tool.Parent
    local depth = 0
    while parent and depth < 8 do
        if parent.ClassName == "Model" then
            local hum = parent:FindFirstChildOfClass("Humanoid")
            if hum then return true end
        end
        parent = parent.Parent
        depth = depth + 1
    end
    return false
end

local function string_value(inst, name)
    if not inst then return nil end
    local ref = inst:FindFirstChild(name)
    if not ref or ref.ClassName ~= "StringValue" then return nil end
    local ok, value = pcall(function() return ref.Value end)
    if ok and value and value ~= "" then
        return value
    end
    return nil
end

local function is_descendant_of(inst, ancestor)
    if not inst or not ancestor or not env.is_valid(inst) or not env.is_valid(ancestor) then
        return false
    end
    local ok, result = pcall(function() return inst:IsDescendantOf(ancestor) end)
    return ok and result == true
end

local function is_player_owned(inst)
    local lp = env.get_local_player()
    if not lp or not inst then return false end

    local char = lp.Character or lp.character
    if char and is_descendant_of(inst, char) then return true end

    local backpack = lp.Backpack or lp.backpack
    if backpack and is_descendant_of(inst, backpack) then return true end

    if game and game.ReplicatedStorage then
        local storage = game.ReplicatedStorage:FindFirstChild("Storage")
        if storage then
            local grid_storage = storage:FindFirstChild("GridItemStorage")
            if grid_storage and is_descendant_of(inst, grid_storage) then
                return true
            end
        end
    end

    return false
end

local function is_character_ancestor(inst)
    if not inst or not env.is_valid(inst) then return false end

    local chars = havoc_sync.get_characters_folder()
    if chars and is_descendant_of(inst, chars) then return true end

    local lp = env.get_local_player()
    if lp then
        local char = lp.Character or lp.character
        if char and is_descendant_of(inst, char) then return true end
    end

    if entity and entity.GetPlayers then
        local ok, players = pcall(function() return entity.GetPlayers() end)
        if ok and players then
            for i = 1, #players do
                local p = players[i]
                local char = p.Character or p.character
                if char and is_descendant_of(inst, char) then return true end
            end
        end
    end

    local cur = inst
    local depth = 0
    while cur and depth < 12 do
        if cur.ClassName == "Model" then
            local hum = cur:FindFirstChildOfClass("Humanoid")
            if hum then return true end
        end
        cur = cur.Parent
        depth = depth + 1
    end

    return false
end

local function is_weld_pool(inst)
    if not inst or not env.is_valid(inst) then return false end

    local ws = env.get_workspace()
    if not ws then return false end

    local ignored = ws:FindFirstChild("Ignored")
    if ignored then
        local temp = ignored:FindFirstChild("_weldobjects.temp")
        if temp and is_descendant_of(inst, temp) then return true end
    end

    local pool_names = { "_weldobjects.temp", "_weldobjects.temp.others" }
    for i = 1, #pool_names do
        local pool = ws:FindFirstChild(pool_names[i])
        if pool and is_descendant_of(inst, pool) then return true end
    end

    return false
end

local function has_equipped_link(inst)
    if not inst then return false end
    local cur = inst
    local depth = 0
    while cur and depth < 10 do
        if cur.ClassName == "Model" or cur.ClassName == "Folder" then
            local link = cur:FindFirstChild("linkItemFolder")
            if link and link.ClassName == "ObjectValue" then
                return true
            end
        end
        cur = cur.Parent
        depth = depth + 1
    end
    return false
end

local function object_value_target(inst, name)
    if not inst then return nil end
    local ref = inst:FindFirstChild(name)
    if not ref or ref.ClassName ~= "ObjectValue" then return nil end
    local ok, value = pcall(function() return ref.Value end)
    if ok and value and env.is_valid(value) then
        return value
    end
    return nil
end

local function resolve_drop_name(inst)
    if not inst then return nil end

    local cur = inst
    local depth = 0
    while cur and depth < 10 do
        local display = string_value(cur, "name")
        if display and display ~= "" then
            if tier_util.is_known_item(display) or tier_util.is_gun_name(display) or tier_util.is_keycard(display) then
                return display
            end
            if not tier_util.is_known_item(cur.Name) then
                return display
            end
        end

        local name = cur.Name
        if tier_util.is_known_item(name) then
            return name
        end

        local tool = object_value_target(cur, "itemTool")
        if tool and tier_util.is_known_item(tool.Name) then
            return tool.Name
        end
        if tool and tool.Name and tool.Name ~= "" then
            return tool.Name
        end

        if cur.ClassName == "Tool" and name and name ~= "" then
            return name
        end

        cur = cur.Parent
        depth = depth + 1
    end

    return nil
end

local function resolve_drop_root(inst)
    if not inst or not env.is_valid(inst) then return nil end

    if inst.ClassName == "Tool" then
        return inst:FindFirstChild("Handle")
    end

    if inst.ClassName == "Part" or inst.ClassName == "MeshPart" then
        return inst
    end

    local weld_model = object_value_target(inst, "currentWeldModel")
    if weld_model then
        local root = weld_model.PrimaryPart
        if not root then
            root = weld_model:FindFirstChildWhichIsA("BasePart")
        end
        if root then return root end
    end

    local tool = object_value_target(inst, "itemTool")
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then return handle end
    end

    if inst.ClassName == "Model" then
        local root = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if root then return root end
    end

    if inst.ClassName == "Folder" then
        local ok, children = pcall(function() return inst:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.ClassName == "Model" then
                    local root = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                    if root then return root end
                elseif child.ClassName == "Part" or child.ClassName == "MeshPart" then
                    return child
                end
            end
        end
    end

    return nil
end

local function is_grid_item_folder(inst)
    if not inst or inst.ClassName ~= "Folder" then return false end
    return inst:FindFirstChild("itemType") ~= nil
        or inst:FindFirstChild("itemTool") ~= nil
        or inst:FindFirstChild("name") ~= nil
        or inst:FindFirstChild("currentWeldModel") ~= nil
end

local function get_weld_temp_folder()
    local ws = env.get_workspace()
    if not ws then return nil end

    local ignored = ws:FindFirstChild("Ignored")
    if ignored then
        local weld = ignored:FindFirstChild("_weldobjects.temp")
        if weld then return weld end
    end

    return ws:FindFirstChild("_weldobjects.temp")
end

local function get_grid_item_folder()
    if not game or not game.ReplicatedStorage then return nil end
    local storage = game.ReplicatedStorage:FindFirstChild("Storage")
    if not storage then return nil end
    return storage:FindFirstChild("GridItemFolder")
end

local function get_buildings_folder()
    if buildings_folder and not env.is_valid(buildings_folder) then
        buildings_folder = nil
        objects_folder = nil
    end
    if not buildings_folder then
        local ws = env.get_workspace()
        if ws then
            buildings_folder = env.safe_call(function()
                if ws.FindFirstChild then return ws:FindFirstChild("Buildings") end
                return nil
            end)
        end
    end
    return buildings_folder
end

local function get_objects_folder()
    local buildings = get_buildings_folder()
    if not buildings then return nil end

    if not objects_folder or not env.is_valid(objects_folder) then
        objects_folder = buildings:FindFirstChild("Objects")
    end
    return objects_folder
end

local function is_world_drop_weld(model)
    if not model or not env.is_valid(model) then return false end
    if is_player_owned(model) then return false end
    if is_character_ancestor(model) then return false end
    if is_weld_pool(model) then return false end

    local objects = get_objects_folder()
    if objects and is_descendant_of(model, objects) then return true end

    return false
end

local function should_skip_drop_inst(inst)
    if not env.is_valid(inst) then return true end

    if is_character_ancestor(inst) then return true end
    if is_weld_pool(inst) then return true end

    if inst.ClassName == "Tool" and is_equipped_tool(inst) then
        return true
    end

    local ok, flag = pcall(function()
        return inst:GetAttribute("isDealer") == true
            or inst:GetAttribute("isQuestGiver") == true
            or inst:GetAttribute("stashName") ~= nil
    end)
    if ok and flag then return true end

    if has_equipped_link(inst) and not is_world_drop_weld(inst) then
        return true
    end

    if inst.ClassName == "Model" then
        local type_str = get_loot_info(inst)
        if type_str then return true end
    end

    return false
end

local function is_drop_candidate(inst)
    if should_skip_drop_inst(inst) then return false end
    if is_player_owned(inst) then return false end

    local cls = inst.ClassName
    if cls == "Tool" then
        return inst:FindFirstChild("Handle") ~= nil
    end

    if cls == "Model" and inst:FindFirstChildOfClass("Humanoid") then
        return false
    end

    if is_grid_item_folder(inst) then
        local weld = object_value_target(inst, "currentWeldModel")
        if weld and not is_world_drop_weld(weld) then
            return false
        end
        return resolve_drop_name(inst) ~= nil
            or object_value_target(inst, "itemTool") ~= nil
            or weld ~= nil
    end

    if cls == "Model" or cls == "Folder" then
        local weld = object_value_target(inst, "currentWeldModel")
        if weld and not is_world_drop_weld(weld) then
            return false
        end
        local name = resolve_drop_name(inst)
        if name then return true end
        return object_value_target(inst, "itemTool") ~= nil or weld ~= nil
    end

    if cls == "Part" or cls == "MeshPart" then
        return resolve_drop_name(inst) ~= nil
    end

    return false
end

local function categorize_drop(name)
    if tier_util.is_keycard(name) then
        return loot_catalog.TYPE_MAP["drop.keycard"]
    end
    if tier_util.is_gun_name(name) then
        return loot_catalog.TYPE_MAP["drop.gun"]
    end
    return loot_catalog.TYPE_MAP["drop.item"]
end

local function get_or_create_drop(model, root, category, display_name)
    local entry = loot_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) then
            entry.category = category or entry.category
            entry.display_name = display_name
            entry.tier_color = tier_util.get_esp_color(display_name)
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)
    local part_pos, part_size = {}, {}
    if model.ClassName == "Model" or model.ClassName == "Folder" then
        collect_model_parts(model, part_pos, part_size, 0)
    end

    entry = {
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
        part_pos = next(part_pos) and part_pos or nil,
        part_size = next(part_size) and part_size or nil,
        is_open_inst = nil,
        is_locked_inst = nil,
        is_open = nil,
        is_locked = nil,
        category = category,
        display_name = display_name,
        tier_color = tier_util.get_esp_color(display_name),
        is_drop = true,
    }
    loot_by_model[model] = entry
    return entry
end

local function register_drop_instance(inst, out, seen)
    if seen[inst] or not is_drop_candidate(inst) then return end

    local name = resolve_drop_name(inst)
    if not name or name == "" then
        if inst.ClassName == "Tool" then
            name = inst.Name
        else
            local tool = object_value_target(inst, "itemTool")
            if tool then name = tool.Name end
        end
    end
    if not name or name == "" then return end

    local root = resolve_drop_root(inst)
    if not root or not env.is_valid(root) then return end

    seen[inst] = true
    local category = categorize_drop(name)
    out[#out + 1] = get_or_create_drop(inst, root, category, name)
end

local function collect_drops_from_list(instances, out, seen)
    for i = 1, #instances do
        scan_yield.yield()
        local inst = instances[i]
        if not inst or not env.is_valid(inst) then goto continue_drop end

        local cls = inst.ClassName
        if cls == "Tool" or cls == "Model" or cls == "Folder" or cls == "Part" or cls == "MeshPart" then
            register_drop_instance(inst, out, seen)
        end

        ::continue_drop::
    end
end

local function collect_drops(container, out, seen, depth)
    if depth > constants.DROP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Tool" or cls == "Model" or cls == "Folder" or cls == "Part" or cls == "MeshPart" then
            register_drop_instance(child, out, seen)
        end

        if cls == "Model" or cls == "Folder" or cls == "WorldModel" then
            collect_drops(child, out, seen, depth + 1)
        end
    end
end

local function collect_objects_drops_deep(out, seen)
    local folder = get_objects_folder()
    if folder and env.is_valid(folder) then
        local ok, descendants = pcall(function() return folder:GetDescendants() end)
        if ok and descendants and #descendants > 0 then
            collect_drops_from_list(descendants, out, seen)
        else
            collect_drops(folder, out, seen, 0)
        end
    end

    local grid_folder = get_grid_item_folder()
    if grid_folder and env.is_valid(grid_folder) then
        local ok, children = pcall(function() return grid_folder:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                scan_yield.yield()
                local child = children[i]
                if child.ClassName == "Folder" then
                    local weld = object_value_target(child, "currentWeldModel")
                    if weld and is_world_drop_weld(weld) then
                        register_drop_instance(child, out, seen)
                    end
                end
            end
        end
    end
end

local function collect_objects_drops(out, seen)
    collect_objects_drops_deep(out, seen)
end

local function append_preserved_drops(out)
    for i = 1, #loot_cache do
        local entry = loot_cache[i]
        if entry.is_drop and env.is_valid(entry.model) and env.is_valid(entry.root) then
            out[#out + 1] = entry
        end
    end
end

local function merge_drop_cache(new_drops)
    local kept = {}
    for i = 1, #loot_cache do
        if not loot_cache[i].is_drop then
            kept[#kept + 1] = loot_cache[i]
        end
    end
    for i = 1, #new_drops do
        kept[#kept + 1] = new_drops[i]
    end

    local new_by_model = {}
    for i = 1, #kept do
        new_by_model[kept[i].model] = kept[i]
    end
    loot_by_model = new_by_model
    loot_cache = kept
    if loot_live_cursor > #loot_cache then
        loot_live_cursor = 1
    end
end

local function collect_loot(container, out, depth)
    if depth > constants.LOOT_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" then
            local type_str, is_open, is_locked = get_loot_info(child)
            if is_open then
                local category = loot_catalog.resolve(type_str, child.Name)
                if category then
                    local root = child:FindFirstChildWhichIsA("BasePart")
                    if root then
                        out[#out + 1] = get_or_create_loot(child, root, category, is_open, is_locked)
                    end
                end
            else
                collect_loot(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_loot(child, out, depth + 1)
        end
    end
end

local function collect_doors(container, out, depth)
    if depth > constants.LOOT_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        local cls = child.ClassName

        if cls == "Model" then
            local is_open, is_locked = get_door_info(child)
            if is_open then
                local category = loot_catalog.resolve(nil, child.Name)
                if category then
                    local root = child:FindFirstChildWhichIsA("BasePart")
                    if root then
                        out[#out + 1] = get_or_create_loot(child, root, category, is_open, is_locked)
                    end
                end
            else
                collect_doors(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_doors(child, out, depth + 1)
        end
    end
end

local function collect_body_models(container, out)
    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = get_or_create_loot(child, root, loot_catalog.BODY_BAG_TYPE, nil, nil)
            end
        end
    end
end

local function collect_body_bags(buildings, out)
    local loots1 = buildings:FindFirstChild("Loots")
    if not loots1 then return end

    local bodies = loots1:FindFirstChild("Bodies")
    if bodies then
        collect_body_models(bodies, out)
    end

    local loots2 = loots1:FindFirstChild("Loots")
    if not loots2 then return end

    local characters = loots2:FindFirstChild("Characters")
    if characters then
        collect_body_models(characters, out)
    end
end

local function collect_buildings_loot(buildings, out)
    local top_loots = buildings:FindFirstChild("Loots")
    if top_loots then
        collect_loot(top_loots, out, 0)

        local doors = top_loots:FindFirstChild("Doors")
        if doors then
            collect_doors(doors, out, 0)
        end

        local interactable = top_loots:FindFirstChild("Interactable")
        if interactable then
            collect_doors(interactable, out, 0)
        end
    end

    local ok, children = pcall(function() return buildings:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child ~= top_loots then
                local loots = child:FindFirstChild("Loots")
                if loots then
                    collect_loot(loots, out, 0)
                end
            end
        end
    end
end

function M.refresh(force)
    local now = os.clock()
    local interval = buildings_folder and constants.LOOT_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if not force and (now - loot_cache_stamp) < interval then return end
    loot_cache_stamp = now

    local out = {}
    local buildings = get_buildings_folder()
    if buildings then
        collect_buildings_loot(buildings, out)
        collect_body_bags(buildings, out)
    end

    append_preserved_drops(out)

    local new_by_model = {}
    for i = 1, #out do
        new_by_model[out[i].model] = out[i]
    end
    loot_by_model = new_by_model
    loot_cache = out
    if loot_live_cursor > #loot_cache then
        loot_live_cursor = 1
    end
end

function M.refresh_drops(force)
    local now = os.clock()
    if not force and (now - drop_cache_stamp) < constants.DROP_SCAN_INTERVAL then return end
    drop_cache_stamp = now

    local out = {}
    local seen = {}
    collect_objects_drops(out, seen)
    merge_drop_cache(out)
end

function M.refresh_live()
    local n = #loot_cache
    if n == 0 then return end

    if loot_live_cursor > n then loot_live_cursor = 1 end

    local prune_batch = 6
    local pruned = 0
    while pruned < prune_batch and n > 0 do
        if loot_live_cursor > n then loot_live_cursor = 1 end
        local loot = loot_cache[loot_live_cursor]
        if not loot or not env.is_valid(loot.model) or not env.is_valid(loot.root) then
            if loot and loot.model then
                loot_by_model[loot.model] = nil
            end
            loot_cache[loot_live_cursor] = loot_cache[n]
            loot_cache[n] = nil
            n = n - 1
        else
            loot_live_cursor = loot_live_cursor + 1
        end
        pruned = pruned + 1
    end

    local remaining = math.min(constants.LOOT_LIVE_BATCH_SIZE, n)
    while remaining > 0 do
        local loot = loot_cache[loot_live_cursor]
        if loot and env.is_valid(loot.model) and env.is_valid(loot.root) then
            if loot.is_drop then
                local root = resolve_drop_root(loot.model) or loot.root
                if root and env.is_valid(root) then
                    loot.root = root
                end
                local ok_pos, pos = pcall(function() return loot.root.Position end)
                if ok_pos and pos then
                    loot.pos = vec3(pos)
                end
            elseif loot.is_open_inst and env.is_valid(loot.is_open_inst) then
                local ok, is_open_val = pcall(function()
                    return loot.is_open_inst.Value
                end)
                if ok then
                    loot.is_open = is_open_val
                end
                if loot.is_locked_inst and env.is_valid(loot.is_locked_inst) then
                    local ok2, is_locked_val = pcall(function()
                        return loot.is_locked_inst.Value
                    end)
                    if ok2 then
                        loot.is_locked = is_locked_val
                    end
                end
            end
            if not loot.is_drop then
                local ok_pos, pos = pcall(function() return loot.root.Position end)
                if ok_pos and pos then
                    loot.pos = vec3(pos)
                end
            end
        end

        loot_live_cursor = loot_live_cursor + 1
        if loot_live_cursor > n then loot_live_cursor = 1 end
        remaining = remaining - 1
    end
end

local static_co = nil
local drops_co = nil

function M.invalidate()
    buildings_folder = nil
    objects_folder = nil
    loot_by_model = {}
    loot_cache = {}
    loot_cache_stamp = -9998
    drop_cache_stamp = -9996
    loot_live_cursor = 1
    static_co = nil
    drops_co = nil
end

function M.queue_refresh()
    if static_co and coroutine.status(static_co) ~= "dead" then return end
    static_co = coroutine.create(function()
        M.refresh(true)
    end)
end

function M.queue_refresh_drops()
    if drops_co and coroutine.status(drops_co) ~= "dead" then return end
    drops_co = coroutine.create(function()
        M.refresh_drops(true)
    end)
end

function M.tick_async(budget_ms)
    local scan_async = July.require("core.scan_async")
    budget_ms = budget_ms or constants.SCAN_BUDGET_MS or 4

    if static_co and scan_async.tick(static_co, budget_ms) then
        static_co = nil
    end
    if drops_co and scan_async.tick(drops_co, budget_ms) then
        drops_co = nil
    end
end

function M.get_cache()
    return loot_cache
end

return M
