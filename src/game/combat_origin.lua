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

local function vec3_from_any(pos)
    if not pos then return nil end
    if pos.X then return { x = pos.X, y = pos.Y, z = pos.Z } end
    if pos.x then return { x = pos.x, y = pos.y, z = pos.z } end
    return nil
end

local function attachment_world_pos(att)
    if not att or not env.is_valid(att) then return nil end
    local ok, pos = pcall(function()
        if att.WorldPosition then return att.WorldPosition end
        if att.Position then return att.Position end
        return nil
    end)
    return vec3_from_any(ok and pos or nil)
end

local function get_current_camera()
    local ws = env.get_workspace()
    if ws then
        local cam = env.safe_call(function()
            if ws.CurrentCamera then return ws.CurrentCamera end
            if ws.FindFirstChildOfClass then return ws:FindFirstChildOfClass("Camera") end
            return nil
        end)
        if cam then return cam end
    end
    return nil
end

local function find_muzzlefx_on(tool)
    if not tool then return nil end

    local handle = env.find_child(tool, "Handle")
    if not handle then return nil end

    local muzzle = env.find_child(handle, "MuzzleFX")
    if muzzle then
        return attachment_world_pos(muzzle) or part_pos(handle)
    end

    local ok, children = pcall(function() return handle:GetChildren() end)
    if ok and children then
        for i = 1, #children do
            local child = children[i]
            if child.Name == "MuzzleFX" or child.ClassName == "Attachment" then
                local pos = attachment_world_pos(child) or part_pos(handle)
                if pos then return pos end
            end
        end
    end

    return part_pos(handle)
end

local function viewmodel_muzzle()
    local cam = get_current_camera()
    if cam then
        local vm = env.find_child(cam, "__viewmodel")
        if vm then
            local ok, children = pcall(function() return vm:GetChildren() end)
            if ok and children then
                for i = 1, #children do
                    local pos = part_pos(children[i])
                    if pos then return pos end
                end
            end
        end
    end

    local ws = env.get_workspace()
    if ws then
        local legacy = ws:FindFirstChild("__viewmodel")
        if legacy then
            local ok, children = pcall(function() return legacy:GetChildren() end)
            if ok and children then
                for i = 1, #children do
                    local pos = part_pos(children[i])
                    if pos then return pos end
                end
            end
        end
    end

    return nil
end

local function camera_origin()
    if camera and camera.GetPosition then
        local ok, pos = pcall(camera.GetPosition)
        if ok and pos then return vec3_from_any(pos) end
    end
    return nil
end

local function head_origin()
    local lp = env.get_local_player()
    if lp then
        if lp.head_position then
            local pos = vec3_from_any(lp.head_position)
            if pos then return pos end
        end

        local char = lp.Character or lp.character
        if char and env.is_valid(char) then
            local head = env.find_child(char, "Head")
            local pos = part_pos(head)
            if pos then return pos end
        end
    end
    return nil
end

local function body_origin()
    local lp = env.get_local_player()
    if not lp then return nil end

    if lp.Position then
        local pos = vec3_from_any(lp.Position)
        if pos then return pos end
    end

    local char = lp.Character or lp.character
    if char and env.is_valid(char) then
        local root = env.find_child(char, "HumanoidRootPart")
            or env.find_child(char, "Torso")
            or env.find_child(char, "UpperTorso")
        return part_pos(root)
    end

    return nil
end

function M.invalidate()
    frame.weapon = nil
    frame.muzzle = nil
    frame.server = nil
end

function M.sync_weapon(weapon)
    weapon = weapon or weapons.cached_held()
    frame.weapon = weapon
    frame.server = head_origin() or body_origin()

    local lp = env.get_local_player()
    local char = lp and (lp.Character or lp.character)
    if char and weapon then
        local tool = env.find_child(char, weapon)
        frame.muzzle = find_muzzlefx_on(tool) or viewmodel_muzzle() or head_origin() or camera_origin()
    else
        frame.muzzle = viewmodel_muzzle() or head_origin() or camera_origin()
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
    return frame.muzzle or frame.server or head_origin() or camera_origin()
end

function M.get_head_origin()
    return head_origin() or body_origin()
end

return M
