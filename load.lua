-- Load teleport bypass first, then July.
local BYPASS_URL = "https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/bypass.lua"
local JULY_URL = "https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/july.lua"

local function load_local_bypass()
    if not loadfile then
        return false
    end

    local paths = {
        "bypass.lua",
        "July/bypass.lua",
        "C:/Users/Cunza/Desktop/Vector Fallen V2/July/bypass.lua",
    }

    for i = 1, #paths do
        local fn = loadfile(paths[i])
        if fn then
            fn()
            return true
        end
    end

    return false
end

if not load_local_bypass() then
    utility.load_url(BYPASS_URL)
end

local function load_local_july()
    if not loadfile then
        return false
    end

    local paths = {
        "july.lua",
        "July/july.lua",
        "C:/Users/Cunza/Desktop/Vector Fallen V2/July/july.lua",
    }

    for i = 1, #paths do
        local fn = loadfile(paths[i])
        if fn then
            fn()
            return true
        end
    end

    return false
end

if not load_local_july() then
    utility.load_url(JULY_URL)
end
