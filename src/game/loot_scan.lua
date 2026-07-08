local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local loot_catalog = July.require("game.loot_catalog")

local M = {}

local loot_by_model = {}
local loot_cache = {}
local loot_cache_stamp = -9998
local loot_live_cursor = 1
local buildings_folder = nil

local function get_loot_info(model)
    local data = model:FindFirstChild("data")
    if not data or data.ClassName ~= "Configuration" then return nil end

    local loot_type = data:FindFirstChild("lootType")
    local is_open = data:FindFirstChild("isOpen")
    local is_locked = data:FindFirstChild("isLocked")
    if not (loot_type and is_open and is_locked) then return nil end

    return is_open, is_locked
end

local function get_or_create_loot(model, root, category, is_open_inst, is_locked_inst)
    local entry = loot_by_model[model]
    if entry then return entry end

    local ok_pos, pos = pcall(function() return root.Position end)
    entry = {
        model = model,
        root = root,
        pos = ok_pos and pos or nil,
        is_open_inst = is_open_inst,
        is_locked_inst = is_locked_inst,
        is_open = nil,
        is_locked = nil,
        category = category,
    }
    loot_by_model[model] = entry
    return entry
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
            local is_open, is_locked = get_loot_info(child)
            if is_open then
                local root = child:FindFirstChildWhichIsA("BasePart")
                if root then
                    out[#out + 1] = get_or_create_loot(child, root, loot_catalog.categorize_loot(child.Name), is_open, is_locked)
                end
            else
                collect_loot(child, out, depth + 1)
            end
        elseif cls == "Folder" or cls == "WorldModel" then
            collect_loot(child, out, depth + 1)
        end
    end
end

local function get_buildings_folder()
    if not buildings_folder then
        buildings_folder = game.Workspace:FindFirstChild("Buildings")
    end
    return buildings_folder
end

local function collect_body_bags(buildings, out)
    local loots1 = buildings:FindFirstChild("Loots")
    if not loots1 then return end
    local loots2 = loots1:FindFirstChild("Loots")
    if not loots2 then return end
    local characters = loots2:FindFirstChild("Characters")
    if not characters then return end

    local ok, children = pcall(function() return characters:GetChildren() end)
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

function M.refresh()
    local now = os.clock()
    local interval = buildings_folder and constants.LOOT_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL
    if (now - loot_cache_stamp) < interval then return end
    loot_cache_stamp = now

    local out = {}
    local buildings = get_buildings_folder()
    if buildings then
        local ok, children = pcall(function() return buildings:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local loots = children[i]:FindFirstChild("Loots")
                if loots then
                    collect_loot(loots, out, 0)
                end
            end
        end
        collect_body_bags(buildings, out)
    end

    if #out > 0 then
        local new_by_model = {}
        for i = 1, #out do
            new_by_model[out[i].model] = out[i]
        end
        loot_by_model = new_by_model
        loot_cache = out
    end
end

function M.refresh_live()
    local n = #loot_cache
    if n == 0 then return end

    if loot_live_cursor > n then loot_live_cursor = 1 end

    local remaining = math.min(constants.LOOT_LIVE_BATCH_SIZE, n)
    while remaining > 0 do
        local loot = loot_cache[loot_live_cursor]
        if loot.is_open_inst then
            local ok, is_open_val, is_locked_val = pcall(function()
                return loot.is_open_inst.Value, loot.is_locked_inst.Value
            end)
            if ok then
                loot.is_open = is_open_val
                loot.is_locked = is_locked_val
            end
        end

        loot_live_cursor = loot_live_cursor + 1
        if loot_live_cursor > n then loot_live_cursor = 1 end
        remaining = remaining - 1
    end
end

function M.get_cache()
    return loot_cache
end

return M
