local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local loot_catalog = July.require("game.loot_catalog")
local tier_util = July.require("game.tier_util")
local env = July.require("core.env")
local havoc_sync = July.require("game.havoc_sync")
local cache = July.require("core.cache")
local settings = July.require("core.settings")

local M = {}

M._static = {}
M._drops = {}

local loot_by_model = {}
local loot_cache = {}
local loot_cache_stamp = -9998
local drop_cache_stamp = -9996
local loot_live_cursor = 1
local last_compact = -9999
local buildings_folder = nil
local objects_folder = nil
local grid_weld_lookup = nil
local grid_weld_lookup_stamp = -9999

local function vec3(pos)
    if not pos then return nil end
    return {
        X = pos.X or pos.x or 0,
        Y = pos.Y or pos.y or 0,
        Z = pos.Z or pos.z or 0,
    }
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

local function hydrate_loot_entry(entry)
    if not entry then return end
    local esp_scan = July.require("game.esp_scan")

    if entry.is_drop then
        if entry.root and env.is_valid(entry.root) then
            entry.main_part = entry.root
            esp_scan.hydrate_entry(entry, { part = entry.root })
            local weld = entry.inst and entry.inst ~= entry.root and entry.inst.ClassName == "Model" and entry.inst
            if not entry.box and weld and env.is_valid(weld) then
                local aabb = esp_scan.read_parts_aabb(weld, 4)
                if aabb then
                    entry.box = aabb
                end
            end
        end
        return
    end

    if not entry.model or not env.is_valid(entry.model) then return end
    entry.inst = entry.model
    esp_scan.hydrate_entry(entry, {
        aabb_inst = entry.model,
        max_parts = constants.LOOT_MAX_PARTS,
    })

    if not entry.lx and entry.root and env.is_valid(entry.root) then
        local box = esp_scan.read_part_box(entry.root)
        if box then
            entry.box = box
            entry.main_part = entry.root
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
        end
    end
end

local function drop_entry_alive(entry)
    if not entry then return false end
    if entry.root and env.is_valid(entry.root) then return true end
    if entry.inst and env.is_valid(entry.inst) then return true end
    return false
end

local function get_or_create_loot(model, root, category, is_open_inst, is_locked_inst)
    local entry = loot_by_model[model]
    if entry then
        if env.is_valid(entry.model) and env.is_valid(entry.root) then
            entry.category = category or entry.category
            if not entry.lx then
                hydrate_loot_entry(entry)
            end
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)

    entry = {
        inst = model,
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
        is_open_inst = is_open_inst,
        is_locked_inst = is_locked_inst,
        is_open = nil,
        is_locked = nil,
        category = category,
    }
    loot_by_model[model] = entry
    hydrate_loot_entry(entry)
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

local function get_weld_temp_others()
    local ws = env.get_workspace()
    if not ws then return nil end
    return ws:FindFirstChild("_weldobjects.temp.others")
end

local function is_in_world_weld_temp(inst)
    local temp = get_weld_temp_folder()
    return temp and is_descendant_of(inst, temp)
end

local function is_in_equipped_weld_pool(inst)
    local others = get_weld_temp_others()
    return others and is_descendant_of(inst, others)
end

local function is_on_viewmodel(inst)
    if not inst then return false end
    local ws = env.get_workspace()
    if ws then
        local vm = ws:FindFirstChild("__viewmodel")
        if vm and is_descendant_of(inst, vm) then return true end
    end
    if workspace and workspace.CurrentCamera and is_descendant_of(inst, workspace.CurrentCamera) then
        return true
    end
    return false
end

local function is_world_drop_model(model)
    if not model or not env.is_valid(model) then return false end
    if is_player_owned(model) then return false end
    if is_character_ancestor(model) then return false end
    if is_on_viewmodel(model) then return false end
    if is_in_equipped_weld_pool(model) then return false end
    if is_in_world_weld_temp(model) then return true end

    local objects = get_objects_folder()
    if objects and is_descendant_of(model, objects) then return true end

    return false
end

local function resolve_grid_folder_name(folder)
    if not folder then return nil end
    local display = string_value(folder, "name")
    if display and display ~= "" then return display end
    local folder_name = folder.Name
    if folder_name and folder_name ~= "" then return folder_name end
    return nil
end

local function resolve_grid_item_type(folder)
    if not folder then return nil end
    return string_value(folder, "itemType") or string_value(folder, "category")
end

local function resolve_drop_name_from_sources(inst, grid_folder)
    if grid_folder then
        local grid_name = resolve_grid_folder_name(grid_folder)
        if grid_name and grid_name ~= "" then
            return grid_name
        end
    end
    return resolve_drop_name(inst)
end

local function categorize_drop(name, grid_folder)
    if tier_util.is_keycard(name) then
        return loot_catalog.TYPE_MAP["drop.keycard"]
    end

    local item_type = grid_folder and resolve_grid_item_type(grid_folder)
    if item_type == "gun" or item_type == "weapon" then
        return loot_catalog.TYPE_MAP["drop.gun"]
    end
    if tier_util.is_gun_name(name) then
        return loot_catalog.TYPE_MAP["drop.gun"]
    end

    return loot_catalog.TYPE_MAP["drop.item"]
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

local function rebuild_grid_weld_lookup()
    grid_weld_lookup = {}
    local grid = get_grid_item_folder()
    if not grid or not env.is_valid(grid) then return end

    local ok, children = pcall(function() return grid:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local folder = children[i]
        if folder.ClassName == "Folder" then
            local weld = object_value_target(folder, "currentWeldModel")
            if weld then
                grid_weld_lookup[weld] = folder
            end
        end
    end
    grid_weld_lookup_stamp = os.clock()
end

local function find_grid_folder_for_weld(weld_model)
    if not weld_model then return nil end

    local now = os.clock()
    if not grid_weld_lookup or (now - grid_weld_lookup_stamp) > 2.0 then
        rebuild_grid_weld_lookup()
    end

    return grid_weld_lookup and grid_weld_lookup[weld_model]
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

local function should_skip_drop_inst(inst)
    if not env.is_valid(inst) then return true end
    if is_character_ancestor(inst) then return true end
    if is_in_equipped_weld_pool(inst) then return true end
    if is_on_viewmodel(inst) then return true end

    if inst.ClassName == "Tool" and is_equipped_tool(inst) then
        return true
    end

    local ok, flag = pcall(function()
        return inst:GetAttribute("isDealer") == true
            or inst:GetAttribute("isQuestGiver") == true
            or inst:GetAttribute("stashName") ~= nil
    end)
    if ok and flag then return true end

    if inst.ClassName == "Model" then
        local type_str = get_loot_info(inst)
        if type_str then return true end
    end

    return false
end

local function get_or_create_drop(model, root, category, display_name)
    local entry = loot_by_model[model]
    if entry then
        if drop_entry_alive(entry) then
            entry.category = category or entry.category
            entry.display_name = display_name
            entry.tier_color = tier_util.get_esp_color(display_name)
            if not entry.lx then
                hydrate_loot_entry(entry)
            end
            return entry
        end
        loot_by_model[model] = nil
    end

    local ok_pos, pos = pcall(function() return root.Position end)

    entry = {
        inst = model,
        model = model,
        root = root,
        pos = ok_pos and vec3(pos) or nil,
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
    hydrate_loot_entry(entry)
    return entry
end

local function register_drop_entry(cache_key, root, category, display_name, out, seen)
    if seen[cache_key] then return end
    if not root or not env.is_valid(root) then return end
    if not display_name or display_name == "" then return end

    seen[cache_key] = true
    out[#out + 1] = get_or_create_drop(cache_key, root, category, display_name)
end

local function weld_is_world_drop(weld)
    if not weld or not env.is_valid(weld) then return false end
    if is_player_owned(weld) then return false end
    if is_character_ancestor(weld) then return false end
    if is_on_viewmodel(weld) then return false end
    if is_in_equipped_weld_pool(weld) then return false end
    return is_in_world_weld_temp(weld) or is_world_drop_model(weld)
end

local function get_weld_temp_root()
    return get_weld_temp_folder()
end

local function is_skip_weld_child(name)
    return name == "Highlight" or name == "thermalTemplate"
end

local function grid_folder_from_model(model)
    if not model then return nil end
    local link = object_value_target(model, "linkItemFolder")
    if not link then return nil end
    local cur = link
    for _ = 1, 10 do
        if not cur then break end
        if is_grid_item_folder(cur) then return cur end
        cur = cur.Parent
    end
    return nil
end

local function clean_item_name(name)
    if not name or name == "" then return nil end
    name = name:gsub("%s*%(%d+%)$", "")
    if name == "WeldObjects" or name == "" then return nil end
    return name
end

local function item_name_from_model(model, grid_folder)
    if grid_folder then
        local grid_name = resolve_grid_folder_name(grid_folder)
        if grid_name and grid_name ~= "" then return grid_name end
    end
    local resolved = resolve_drop_name(model)
    if resolved and resolved ~= "" then return resolved end
    return clean_item_name(model and model.Name)
end

local function register_item_drop(model, grid_folder, out, seen)
    if not model or not env.is_valid(model) or seen[model] then return end
    if is_player_owned(model) or is_on_viewmodel(model) or is_character_ancestor(model) then return end
    if is_in_equipped_weld_pool(model) then return end

    local name = item_name_from_model(model, grid_folder)
    if not name or name == "" then return end

    local root = resolve_drop_root(model)
    if not root or not env.is_valid(root) then return end

    local category = categorize_drop(name, grid_folder)
    register_drop_entry(model, root, category, name, out, seen)
end

local function scan_weld_container(container, out, seen, depth)
    if not container or not env.is_valid(container) or depth > 4 then return end

    local grid_folder = grid_folder_from_model(container)
    if grid_folder then
        register_item_drop(container, grid_folder, out, seen)
        return
    end

    if container.ClassName == "Model" and not is_skip_weld_child(container.Name) then
        local name = container.Name
        if object_value_target(container, "linkItemFolder")
            or tier_util.is_known_item(name)
            or tier_util.is_gun_name(name)
            or tier_util.is_keycard(name) then
            register_item_drop(container, nil, out, seen)
            return
        end
    end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        if child.ClassName == "Model" then
            register_item_drop(child, grid_folder_from_model(child), out, seen)
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            scan_weld_container(child, out, seen, depth + 1)
        end
    end
end

local function collect_weld_temp_drops(out, seen)
    local temp = get_weld_temp_root()
    if not temp or not env.is_valid(temp) then return end

    local ok, children = pcall(function() return temp:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        local child = children[i]
        if not is_skip_weld_child(child.Name) then
            scan_weld_container(child, out, seen, 0)
        end
    end
end

local function register_grid_drop(folder, out, seen)
    if not folder or not env.is_valid(folder) or seen[folder] then return end

    local weld = object_value_target(folder, "currentWeldModel")
    if not weld or not env.is_valid(weld) then return end
    if not weld_is_world_drop(weld) then return end

    local name = resolve_drop_name_from_sources(weld, folder)
    if not name or name == "" then return end

    local root = resolve_drop_root(folder) or resolve_drop_root(weld)
    if not root or not env.is_valid(root) then return end

    local category = categorize_drop(name, folder)
    register_drop_entry(folder, root, category, name, out, seen)
end

local function register_weld_drop(weld_model, out, seen)
    if not weld_model or not env.is_valid(weld_model) or seen[weld_model] then return end
    if should_skip_drop_inst(weld_model) then return end
    if not is_world_drop_model(weld_model) then return end

    local grid_folder = grid_folder_from_model(weld_model) or find_grid_folder_for_weld(weld_model)
    if grid_folder then
        register_grid_drop(grid_folder, out, seen)
        return
    end

    local name = resolve_drop_name_from_sources(weld_model, nil)
    if not name or name == "" then
        name = weld_model.Name
    end
    if not name or name == "" then return end

    local root = resolve_drop_root(weld_model)
    if not root or not env.is_valid(root) then return end

    local category = categorize_drop(name, nil)
    register_drop_entry(weld_model, root, category, name, out, seen)
end

local function register_drop_instance(inst, out, seen)
    if not inst or not env.is_valid(inst) then return end

    if is_grid_item_folder(inst) then
        register_grid_drop(inst, out, seen)
        return
    end

    if inst.ClassName == "Model" and is_world_drop_model(inst) then
        register_weld_drop(inst, out, seen)
        return
    end

    if should_skip_drop_inst(inst) or is_player_owned(inst) then return end

    local cls = inst.ClassName
    if cls == "Tool" then
        if not inst:FindFirstChild("Handle") then return end
    elseif cls == "Model" then
        if inst:FindFirstChildOfClass("Humanoid") then return end
        if not is_world_drop_model(inst) then return end
    elseif cls ~= "Folder" and cls ~= "Part" and cls ~= "MeshPart" then
        return
    end

    local grid_folder = grid_folder_from_model(inst) or find_grid_folder_for_weld(inst)
    local name = resolve_drop_name_from_sources(inst, grid_folder)
    if not name or name == "" then
        if cls == "Tool" then
            name = inst.Name
        else
            local tool = object_value_target(inst, "itemTool")
            if tool then name = tool.Name end
        end
    end
    if not name or name == "" then return end

    local root = resolve_drop_root(inst)
    if not root or not env.is_valid(root) then return end

    local cache_key = grid_folder or inst
    local category = categorize_drop(name, grid_folder)
    register_drop_entry(cache_key, root, category, name, out, seen)
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
    collect_weld_temp_drops(out, seen)

    local folder = get_objects_folder()
    if folder and env.is_valid(folder) then
        collect_drops(folder, out, seen, 0)
    end
end

local function collect_objects_drops(out, seen)
    collect_objects_drops_deep(out, seen)
end

local function rebuild_draw_cache()
    cache.loot = {}
    for i = 1, #M._static do
        cache.loot[#cache.loot + 1] = M._static[i]
    end
    for i = 1, #M._drops do
        cache.loot[#cache.loot + 1] = M._drops[i]
    end
    loot_cache = cache.loot
    if loot_live_cursor > #loot_cache then
        loot_live_cursor = 1
    end
end

local function split_static_drops(list)
    local static_out = {}
    local drops_out = {}
    for i = 1, #list do
        local entry = list[i]
        if entry.is_drop then
            drops_out[#drops_out + 1] = entry
        else
            static_out[#static_out + 1] = entry
        end
    end
    return static_out, drops_out
end

local drop_live_cursor = 1
local static_bounds_cursor = 1

function M.tick_static_bounds(batch)
    batch = batch or constants.LOOT_PRUNE_BATCH or 8
    if #M._static == 0 then return end

    local esp_scan = July.require("game.esp_scan")
    local n = #M._static
    if static_bounds_cursor > n then static_bounds_cursor = 1 end

    for _ = 1, math.min(batch, n) do
        local entry = M._static[static_bounds_cursor]
        if entry and not entry.is_drop and env.is_valid(entry.model) then
            esp_scan.refresh_entry_bounds(entry)
        end
        static_bounds_cursor = static_bounds_cursor + 1
        if static_bounds_cursor > n then static_bounds_cursor = 1 end
    end
end

local function preserve_drops(out)
    for i = 1, #M._drops do
        local entry = M._drops[i]
        if entry and entry.is_drop and drop_entry_alive(entry) then
            out[#out + 1] = entry
        end
    end
end

local function merge_drop_cache(new_drops)
    M._drops = new_drops or {}
    rebuild_draw_cache()
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

    preserve_drops(out)

    local static_out, drops_in_scan = split_static_drops(out)
    M._static = static_out
    M._drops = drops_in_scan

    local new_by_model = {}
    rebuild_draw_cache()
    for i = 1, #loot_cache do
        new_by_model[loot_cache[i].model] = loot_cache[i]
    end
    loot_by_model = new_by_model
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.refresh_drops(force)
    local now = os.clock()
    if not force and (now - drop_cache_stamp) < constants.DROP_SCAN_INTERVAL then return end
    drop_cache_stamp = now

    local out = {}
    local seen = {}
    collect_objects_drops_deep(out, seen)
    merge_drop_cache(out)
end

function M.begin_drops_scan()
    return { ci = 1, children = nil, seen = {}, out = {} }
end

function M.step_drops_scan(state, batch)
    if not state.children then
        state.children = {}
        local temp = get_weld_temp_root()
        if temp and env.is_valid(temp) then
            local ok, kids = pcall(function() return temp:GetChildren() end)
            if ok and kids then state.children = kids end
        end
        state.ci = 1
    end

    local processed = 0
    while processed < batch and state.ci <= #state.children do
        local child = state.children[state.ci]
        state.ci = state.ci + 1
        processed = processed + 1
        if child and env.is_valid(child) and not is_skip_weld_child(child.Name) then
            scan_weld_container(child, state.out, state.seen, 0)
        end
    end

    if state.ci <= #state.children then
        return false
    end

    if not state.objects_done then
        state.objects_done = true
        local folder = get_objects_folder()
        if folder and env.is_valid(folder) then
            collect_drops(folder, state.out, state.seen, 0)
        end
    end

    return true
end

function M.complete_drops_scan(state)
    merge_drop_cache(state.out or {})
    drop_cache_stamp = os.clock()
end

function M.begin_static_scan()
    return { co = coroutine.create(function()
        M.refresh(true)
    end) }
end

function M.step_static_scan(state, batch)
    if not state or not state.co then return true end
    if coroutine.status(state.co) == "dead" then return true end

    local scan_async = July.require("core.scan_async")
    local budget = math.max(2, math.floor((constants.SCAN_BUDGET_MS or 4) * 0.75))
    for _ = 1, math.max(1, math.floor(batch / 6)) do
        if scan_async.tick(state.co, budget) then
            return true
        end
    end
    return coroutine.status(state.co) == "dead"
end

function M.complete_static_scan(state)
    local new_by_model = {}
    for i = 1, #loot_cache do
        new_by_model[loot_cache[i].model] = loot_cache[i]
    end
    loot_by_model = new_by_model
    cache.stats.last_loot_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
end

function M.compact_invalid(force)
    local now = os.clock()
    local interval = constants.LOOT_COMPACT_INTERVAL or 8.0
    if not force and (now - last_compact) < interval then return end
    last_compact = now

    cache.prune_invalid(M._static)
    cache.prune_invalid(M._drops)
    rebuild_draw_cache()

    local new_by_model = {}
    for i = 1, #loot_cache do
        new_by_model[loot_cache[i].model] = loot_cache[i]
    end
    loot_by_model = new_by_model
end

local function combat_active()
    return settings.bool("havoc_aimbot_enabled", false)
        and settings.enabled("havoc_aimbot_keybind")
end

-- April-style: prune + refresh static positions on interval.
function M.tick_cache()
    if cache.should_refresh_positions(combat_active()) then
        cache.prune_invalid(M._static)
        cache.prune_invalid(M._drops)
        rebuild_draw_cache()
    end
end

local drop_pos_cursor = 1

function M.tick_drop_positions(batch)
    batch = batch or constants.DROP_LIVE_BATCH or 24
    local n = #M._drops
    if n == 0 then return end

    local esp_scan = July.require("game.esp_scan")
    if drop_pos_cursor > n then drop_pos_cursor = 1 end

    for _ = 1, math.min(batch, n) do
        local entry = M._drops[drop_pos_cursor]
        if entry and drop_entry_alive(entry) then
            esp_scan.refresh_entry_position(entry)
        end
        drop_pos_cursor = drop_pos_cursor + 1
        if drop_pos_cursor > n then drop_pos_cursor = 1 end
    end
end

function M.tick_drops_live(batch)
    M.tick_drop_positions(batch)
end

-- Batched door/crate open state only — cheap between position refreshes.
function M.tick_live_state()
    local n = #loot_cache
    if n == 0 then return end

    if loot_live_cursor > n then loot_live_cursor = 1 end

    local batch = math.min(constants.LOOT_LIVE_BATCH_SIZE or 24, n)
    for _ = 1, batch do
        local loot = loot_cache[loot_live_cursor]
        if loot and env.is_valid(loot.model) and env.is_valid(loot.root) then
            if not loot.is_drop and loot.is_open_inst and env.is_valid(loot.is_open_inst) then
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
        end

        loot_live_cursor = loot_live_cursor + 1
        if loot_live_cursor > n then loot_live_cursor = 1 end
    end
end

function M.refresh_live()
    M.tick_live_state()
end

local static_co = nil
local drops_co = nil

function M.invalidate()
    buildings_folder = nil
    objects_folder = nil
    grid_weld_lookup = nil
    grid_weld_lookup_stamp = -9999
    loot_by_model = {}
    M._static = {}
    M._drops = {}
    loot_cache = {}
    cache.loot = {}
    loot_cache_stamp = -9998
    drop_cache_stamp = -9996
    loot_live_cursor = 1
    last_compact = -9999
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
    local half = math.max(1, math.floor(budget_ms * 0.5))

    if static_co and scan_async.tick(static_co, half) then
        static_co = nil
    end
    if drops_co and scan_async.tick(drops_co, half) then
        drops_co = nil
    end
end

function M.get_cache()
    return cache.loot
end

function M.get_drops()
    return M._drops
end

return M
