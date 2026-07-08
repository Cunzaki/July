--[[ Havoc weapon mods — refreshgc → getgc(keys) → applygc(keys, values)
     Keys match weapon config tables from dump (M4A1.lua etc.) ]]

local env = July.require("core.env")

local M = {}

M.WEAPON_FIND_KEYS = {
    "vPunchBase",
    "hPunchBase",
    "dPunchBase",
    "recoilPunch",
    "minRecoilPower",
    "maxRecoilPower",
    "recoilReduce",
    "spreadReduce",
    "aimWeight",
    "unAimWeight",
    "vel",
}

M.PATCHES = {
    havoc_no_recoil = {
        vPunchBase = 0,
        hPunchBase = 0,
        dPunchBase = 0,
        recoilPunch = 0,
        minRecoilPower = 0,
        maxRecoilPower = 0,
        recoilReduce = 1,
    },
    havoc_no_spread = {
        spreadReduce = 1,
    },
    havoc_no_sway = {
        aimWeight = 0,
        unAimWeight = 0,
    },
    havoc_fast_vel = {
        vel = 5000,
    },
}

M._last_node_count = 0

local function has_api()
    return type(refreshgc) == "function"
        and type(getgc) == "function"
        and type(applygc) == "function"
end

function M.available()
    return has_api()
end

function M.last_node_count()
    return M._last_node_count
end

function M.in_game()
    return env.get_local_player() ~= nil
end

local function warm_nodes(keys)
    local count = 0
    local ok, result = pcall(getgc, keys)
    if ok and type(result) == "number" then
        count = result
    end
    if count <= 0 then
        ok, result = pcall(getgc, M.WEAPON_FIND_KEYS)
        if ok and type(result) == "number" then
            count = result
        end
    end
    return count
end

local function patch_count(keys, payload)
    local patched = 0

    local ok, result = pcall(applygc, keys, payload)
    if ok and type(result) == "number" then
        patched = result
    end

    if patched <= 0 then
        ok, result = pcall(applygc, M.WEAPON_FIND_KEYS, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    if patched <= 0 then
        ok, result = pcall(applygc, payload)
        if ok and type(result) == "number" then
            patched = result
        end
    end

    return patched
end

function M.warm()
    if not has_api() or not M.in_game() then
        M._last_node_count = 0
        return 0
    end

    pcall(refreshgc)
    local count = warm_nodes(M.WEAPON_FIND_KEYS)
    M._last_node_count = count
    return count
end

function M.apply_enabled(enabled_ids)
    if not has_api() then
        return false, 0
    end

    if not M.in_game() then
        return false, 0
    end

    pcall(refreshgc)
    warm_nodes(M.WEAPON_FIND_KEYS)

    local patched = 0
    for i = 1, #enabled_ids do
        local patch = M.PATCHES[enabled_ids[i]]
        if patch then
            local keys = {}
            for k in pairs(patch) do
                keys[#keys + 1] = k
            end
            table.sort(keys)
            patched = patched + patch_count(keys, patch)
        end
    end

    M._last_node_count = math.max(M._last_node_count, patched, warm_nodes(M.WEAPON_FIND_KEYS))
    return patched > 0, patched
end

return M
