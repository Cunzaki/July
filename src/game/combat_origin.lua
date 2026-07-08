local env = July.require("core.env")
local weapons = July.require("game.weapons")

local M = {}

local frame = { weapon = nil, muzzle = nil, server = nil }

local function part_pos(part)
    if not part or not env.is_valid(part) then return nil end
    local ok, pos = pcall(function() return part.Position end)
    if ok and pos then
        if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
        if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    end
    return nil
end

local function find_muzzlefx(tool)
    if not tool then return nil end

    local handle = env.find_child(tool, "Handle")
    if handle then
        local ok, children = pcall(function() return handle:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local child = children[i]
                if child.Name == "MuzzleFX" or child.ClassName == "Attachment" then
                    local pos = part_pos(handle)
                    if pos then return pos end
                end
            end
        end
        local pos = part_pos(handle)
        if pos then return pos end
    end

    local mod = env.find_child(tool, "_mod")
    if mod then
        local ok, children = pcall(function() return mod:GetChildren() end)
        if ok and children then
            for i = 1, #children do
                local pos = part_pos(children[i])
                if pos then return pos end
            end
        end
    end

    return nil
end

local function viewmodel_muzzle()
    local ws = env.get_workspace()
    if not ws then return nil end

    local vm = ws:FindFirstChild("__viewmodel")
    if not vm then return nil end

    local ok, children = pcall(function() return vm:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local pos = part_pos(children[i])
            if pos then return pos end
        end
    end

    return nil
end

local function camera_origin()
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then
            if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
            if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
        end
    end
    return nil
end

local function server_origin()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.Position then
        local p = lp.Position
        if p.X then return { x = p.X, y = p.Y, z = p.Z } end
        if p.x then return { x = p.x, y = p.y, z = p.z } end
    end

    local char = lp.Character or lp.character
    if char and env.is_valid(char) then
        local root = env.find_child(char, "HumanoidRootPart")
            or env.find_child(char, "Head")
        return part_pos(root)
    end

    return nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held()
    frame.weapon = weapon
    frame.server = server_origin()

    local lp = env.get_local_player()
    local char = lp and (lp.Character or lp.character)
    if char and weapon then
        local tool = env.find_child(char, weapon)
        frame.muzzle = find_muzzlefx(tool) or viewmodel_muzzle() or camera_origin()
    else
        frame.muzzle = viewmodel_muzzle() or camera_origin()
    end
end

function M.get_muzzle_origin()
    M.sync_weapon()
    return frame.muzzle
end

function M.get_server_origin()
    M.sync_weapon()
    return frame.server
end

function M.get_fire_origin()
    M.sync_weapon()
    return frame.muzzle or frame.server or camera_origin()
end

return M
