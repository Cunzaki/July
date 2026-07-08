local env = July.require("core.env")

local M = {}

M._chars_folder = nil
M._folder_name = nil
M._last_sync_attempt = -999
M._sync_failures = 0

local SYNC_RETRY_INTERVAL = 2.0

local function read_shared_folder_name()
    local ok, name = pcall(function()
        if shared and type(shared.charactersFolderName) == "string" then
            return shared.charactersFolderName
        end
        return nil
    end)
    if ok and name and name ~= "" then
        return name
    end
    return nil
end

function M.get_folder_name()
    if M._folder_name then return M._folder_name end

    local shared_name = read_shared_folder_name()
    if shared_name then
        M._folder_name = shared_name
        return shared_name
    end

    local now = os.clock()
    if (now - M._last_sync_attempt) < SYNC_RETRY_INTERVAL then
        return nil
    end
    M._last_sync_attempt = now

    local rs = game and (game.ReplicatedStorage or (game.GetService and game:GetService("ReplicatedStorage")))
    if not rs then return nil end

    local storage = env.find_child(rs, "Storage")
    local events = storage and env.find_child(storage, "Events")
    local getGSync = events and env.find_child(events, "GetGSync")
    if not getGSync then return nil end

    local ok, name = pcall(function()
        if getGSync.InvokeServer then return getGSync:InvokeServer() end
        return nil
    end)

    if ok and type(name) == "string" and name ~= "" then
        M._folder_name = name
        M._sync_failures = 0
        return name
    end

    M._sync_failures = M._sync_failures + 1
    return nil
end

function M.get_characters_folder()
    if M._chars_folder and not env.is_valid(M._chars_folder) then
        M._chars_folder = nil
    end

    if M._chars_folder then
        return M._chars_folder
    end

    local ws = env.get_workspace()
    if not ws then return nil end

    local name = M.get_folder_name()
    if name then
        local folder = env.safe_call(function()
            if ws.FindFirstChild then return ws:FindFirstChild(name) end
            return nil
        end)
        if not folder then
            M._folder_name = nil
            name = M.get_folder_name()
            if name then
                folder = env.safe_call(function()
                    if ws.FindFirstChild then return ws:FindFirstChild(name) end
                    return nil
                end)
            end
        end
        if folder then
            M._chars_folder = folder
            return folder
        end
        folder = env.safe_call(function()
            if ws.WaitForChild and name then return ws:WaitForChild(name, 2) end
            return nil
        end)
        if folder then
            M._chars_folder = folder
            return folder
        end
    end

    return nil
end

function M.reset()
    M._chars_folder = nil
    M._folder_name = nil
    M._last_sync_attempt = -999
    M._sync_failures = 0
end

return M
