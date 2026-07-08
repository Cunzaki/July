local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local trap_types = July.require("game.trap_types")
local env = July.require("core.env")

local M = {}

local trap_cache = {}
local trap_cache_stamp = -9997
local trap_folders_found = false
local trap_live_cursor = 1

local IGNORED_FOLDER = nil
local EVENT_OBJECTS_FOLDER = nil
local ENV_INTERACTABLE_FOLDER = nil

local function get_buildings_folder()
    local ws = env.get_workspace()
    if not ws then return nil end
    return env.safe_call(function()
        if ws.FindFirstChild then return ws:FindFirstChild("Buildings") end
        return nil
    end)
end

local function get_ignored_folder()
    if IGNORED_FOLDER and not env.is_valid(IGNORED_FOLDER) then
        IGNORED_FOLDER = nil
    end
    if not IGNORED_FOLDER then
        local ws = env.get_workspace()
        if ws then
            IGNORED_FOLDER = env.safe_call(function()
                if ws.FindFirstChild then return ws:FindFirstChild("Ignored") end
                return nil
            end)
        end
    end
    return IGNORED_FOLDER
end

local function get_event_objects_folder()
    if EVENT_OBJECTS_FOLDER and not env.is_valid(EVENT_OBJECTS_FOLDER) then
        EVENT_OBJECTS_FOLDER = nil
    end
    if not EVENT_OBJECTS_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            EVENT_OBJECTS_FOLDER = buildings:FindFirstChild("EventObjects")
        end
        if not EVENT_OBJECTS_FOLDER then
            local ws = env.get_workspace()
            if ws then
                EVENT_OBJECTS_FOLDER = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild("EventObjects") end
                    return nil
                end)
            end
        end
    end
    return EVENT_OBJECTS_FOLDER
end

local function get_env_interactable_folder()
    if ENV_INTERACTABLE_FOLDER and not env.is_valid(ENV_INTERACTABLE_FOLDER) then
        ENV_INTERACTABLE_FOLDER = nil
    end
    if not ENV_INTERACTABLE_FOLDER then
        local buildings = get_buildings_folder()
        if buildings then
            ENV_INTERACTABLE_FOLDER = buildings:FindFirstChild("EnvInteractable")
        end
        if not ENV_INTERACTABLE_FOLDER then
            local ws = env.get_workspace()
            if ws then
                ENV_INTERACTABLE_FOLDER = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild("EnvInteractable") end
                    return nil
                end)
            end
        end
    end
    return ENV_INTERACTABLE_FOLDER
end

local function collect_tripmines(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Folder" and child.Name:find("Tripmine", 1, true) then
            local mainPart = child:FindFirstChild("mainPart")
            local connectedPart = child:FindFirstChild("connectedPart")
            if mainPart and mainPart:IsA("BasePart") then
                out[#out + 1] = {
                    root = mainPart,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[1],
                    extra = connectedPart,
                }
            end
        elseif child.ClassName == "Folder" then
            collect_tripmines(child, out, depth + 1)
        end
    end
end

local function collect_mine_hitboxes(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child:IsA("BasePart") and child.Name == "MineHitbox" then
            out[#out + 1] = {
                root = child,
                model = child,
                trap_type = trap_types.TRAP_TYPES[2],
                extra = nil,
            }
        elseif child.ClassName == "Folder" or child:IsA("BasePart") then
            collect_mine_hitboxes(child, out, depth + 1)
        end
    end
end

local function collect_alarms(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" and child.Name:find("Alarm", 1, true) then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[3],
                    extra = nil,
                }
            end
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_alarms(child, out, depth + 1)
        end
    end
end

local function collect_airstrike_alarms(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" and child.Name:find("AirstrikeAlarm", 1, true) then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[4],
                    extra = nil,
                }
            end
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_airstrike_alarms(child, out, depth + 1)
        end
    end
end

local function collect_explosive_barrels(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChild("Base")
            if not root then root = child:FindFirstChildWhichIsA("BasePart") end
            if root then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[5],
                    extra = nil,
                }
            end
        end
    end
end

local function collect_sentries(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child.ClassName == "Model" then
            local root = child:FindFirstChild("Base")
            if root and root:IsA("BasePart") then
                out[#out + 1] = {
                    root = root,
                    model = child,
                    trap_type = trap_types.TRAP_TYPES[6],
                    extra = nil,
                }
            end
        end
    end
end

local function collect_toxic_gas(container, out, depth)
    if depth > constants.TRAP_SCAN_DEPTH then return end

    local ok, children = pcall(function() return container:GetChildren() end)
    if not ok or not children then return end

    for i = 1, #children do
        scan_yield.yield()

        local child = children[i]
        if child:IsA("MeshPart") then
            out[#out + 1] = {
                root = child,
                model = child,
                trap_type = trap_types.TRAP_TYPES[7],
                extra = nil,
            }
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_toxic_gas(child, out, depth + 1)
        end
    end
end

function M.refresh(force)
    local interval = trap_folders_found and constants.TRAP_SCAN_INTERVAL or constants.FOLDER_POLL_INTERVAL

    local now = os.clock()
    if not force and (now - trap_cache_stamp) < interval then return end
    trap_cache_stamp = now

    local out = {}
    local any_found = false

    local env = get_env_interactable_folder()
    if env then any_found = true end
    if env then
        local mines = env:FindFirstChild("Mines")
        if mines then
            local tripmines = mines:FindFirstChild("Tripmines")
            if tripmines then
                collect_tripmines(tripmines, out, 0)
            end
        end
    end

    local ignored = get_ignored_folder()
    if ignored then any_found = true end
    if ignored then
        collect_alarms(ignored, out, 0)
    end

    local event_objects = get_event_objects_folder()
    if event_objects then any_found = true end
    if event_objects then
        local minefields = event_objects:FindFirstChild("Minefields")
        if minefields then
            collect_mine_hitboxes(minefields, out, 0)
        end
        local airstrike = event_objects:FindFirstChild("ST_AirstrikeAlarms")
        if airstrike then
            collect_airstrike_alarms(airstrike, out, 0)
        end
        local barrels = event_objects:FindFirstChild("ExplosiveBarrels")
        if barrels then
            collect_explosive_barrels(barrels, out, 0)
        end
        local sentries = event_objects:FindFirstChild("Sentries")
        if sentries then
            collect_sentries(sentries, out, 0)
        end
        local gas = event_objects:FindFirstChild("ToxicGas")
        if gas then
            collect_toxic_gas(gas, out, 0)
        end
    end

    trap_folders_found = any_found
    trap_cache = out
    if trap_live_cursor > #trap_cache then
        trap_live_cursor = 1
    end
end

function M.refresh_live()
    local n = #trap_cache
    if n == 0 then return end

    local batch = constants.TRAP_LIVE_BATCH or 10
    local checked = 0

    while checked < batch and n > 0 do
        if trap_live_cursor > n then trap_live_cursor = 1 end

        local trap = trap_cache[trap_live_cursor]
        if not trap or not env.is_valid(trap.root) or not env.is_valid(trap.model) then
            trap_cache[trap_live_cursor] = trap_cache[n]
            trap_cache[n] = nil
            n = n - 1
        else
            if trap.extra and not env.is_valid(trap.extra) then
                trap.extra = nil
            end
            trap_live_cursor = trap_live_cursor + 1
        end
        checked = checked + 1
    end
end

local refresh_co = nil

function M.queue_refresh()
    if refresh_co and coroutine.status(refresh_co) ~= "dead" then return end
    refresh_co = coroutine.create(function()
        M.refresh(true)
    end)
end

function M.tick_async(budget_ms)
    local scan_async = July.require("core.scan_async")
    budget_ms = budget_ms or constants.SCAN_BUDGET_MS or 4
    if refresh_co and scan_async.tick(refresh_co, budget_ms) then
        refresh_co = nil
    end
end

function M.invalidate()
    trap_cache = {}
    trap_cache_stamp = -9997
    trap_folders_found = false
    trap_live_cursor = 1
    refresh_co = nil
    IGNORED_FOLDER = nil
    EVENT_OBJECTS_FOLDER = nil
    ENV_INTERACTABLE_FOLDER = nil
end

function M.get_cache()
    return trap_cache
end

return M
