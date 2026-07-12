local constants = July.require("core.constants")
local scan_yield = July.require("core.scan_yield")
local trap_types = July.require("game.trap_types")
local env = July.require("core.env")
local cache = July.require("core.cache")

local M = {}

M._entries = {}

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

local function vec3_pos(pos)
    if not pos then return nil end
    return {
        X = pos.X or pos.x or 0,
        Y = pos.Y or pos.y or 0,
        Z = pos.Z or pos.z or 0,
    }
end

local function add_trap_entry(out, root, model, trap_type, extra)
    local ok_pos, pos = pcall(function() return root.Position end)
    out[#out + 1] = {
        root = root,
        model = model,
        trap_type = trap_type,
        extra = extra,
        pos = ok_pos and vec3_pos(pos) or nil,
    }
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
                add_trap_entry(out, mainPart, child, trap_types.get("trap_tripmine"), connectedPart)
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
            add_trap_entry(out, child, child, trap_types.get("trap_mine"), nil)
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
        if child.ClassName == "Model"
            and child.Name:find("Alarm", 1, true)
            and not child.Name:find("Airstrike", 1, true)
        then
            local root = child:FindFirstChildWhichIsA("BasePart")
            if root then
                add_trap_entry(out, root, child, trap_types.get("trap_alarm"), nil)
            end
        elseif child.ClassName == "Folder" or child.ClassName == "Model" then
            collect_alarms(child, out, depth + 1)
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
                add_trap_entry(out, root, child, trap_types.get("trap_barrel"), nil)
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
                add_trap_entry(out, root, child, trap_types.get("trap_sentry"), nil)
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
        if child.ClassName == "Model" then
            local root = child:FindFirstChildWhichIsA("BasePart") or child:FindFirstChildWhichIsA("MeshPart")
            if root then
                add_trap_entry(out, root, child, trap_types.get("trap_gas"), nil)
            end
        elseif child:IsA("MeshPart") and depth <= 1 then
            add_trap_entry(out, child, child, trap_types.get("trap_gas"), nil)
        elseif child.ClassName == "Folder" then
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
    M._entries = out
    cache.traps = out
    trap_cache = cache.traps
    cache.stats.last_trap_scan = utility and utility.get_tick_count and utility.get_tick_count() or 0
    if trap_live_cursor > #trap_cache then
        trap_live_cursor = 1
    end
end

local function combat_active()
    local settings = July.require("core.settings")
    return settings.bool("havoc_aimbot_enabled", false)
        and settings.enabled("havoc_aimbot_keybind")
end

local trap_pos_cursor = 1

function M.tick_positions(batch)
    batch = batch or constants.TRAP_LIVE_BATCH or 16
    local n = #M._entries
    if n == 0 then return end

    if trap_pos_cursor > n then trap_pos_cursor = 1 end

    for _ = 1, math.min(batch, n) do
        local trap = M._entries[trap_pos_cursor]
        if trap and trap.root and env.is_valid(trap.root) then
            local ok_pos, pos = pcall(function() return trap.root.Position end)
            if ok_pos and pos then
                trap.pos = vec3_pos(pos)
            end
        end
        trap_pos_cursor = trap_pos_cursor + 1
        if trap_pos_cursor > n then trap_pos_cursor = 1 end
    end
end

function M.tick_cache()
    if not cache.should_refresh_positions(combat_active()) then return end

    cache.prune_invalid(M._entries)
    cache.traps = M._entries
    trap_cache = cache.traps
end

function M.begin_scan()
    return { co = coroutine.create(function()
        M.refresh(true)
    end) }
end

function M.step_scan(state, batch)
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

function M.complete_scan(_state)
end

function M.refresh_live()
    -- Legacy hook: position refresh moved to tick_cache (April interval pattern).
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
    cache.traps = {}
    M._entries = {}
    trap_cache_stamp = -9997
    trap_folders_found = false
    trap_live_cursor = 1
    refresh_co = nil
    IGNORED_FOLDER = nil
    EVENT_OBJECTS_FOLDER = nil
    ENV_INTERACTABLE_FOLDER = nil
end

function M.get_cache()
    return cache.traps
end

return M
