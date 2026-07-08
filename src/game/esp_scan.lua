--[[ Shared ESP scan helpers — part lookup + oriented 3D box data. ]]

local env = July.require("core.env")

local M = {}

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    UnionOperation = true,
}

function M.is_part(inst)
    if not inst then return false end
    return PART_CLASSES[inst.ClassName] == true
end

function M.find_main_part(model)
    if not env.is_valid(model) then return nil end

    local main = env.safe_call(function()
        return model:FindFirstChild("Main")
    end)
    if main and M.is_part(main) then return main end

    local hrp = env.safe_call(function()
        return model:FindFirstChild("HumanoidRootPart")
    end)
    if hrp and M.is_part(hrp) then return hrp end

    local children = env.safe_call(function() return model:GetChildren() end) or {}
    for i = 1, #children do
        if M.is_part(children[i]) then return children[i] end
    end

    if M.is_part(model) then return model end
    return nil
end

local function vec3(v, axis)
    if not v then return 0 end
    if axis == "x" then return v.x or v.X or 0 end
    if axis == "y" then return v.y or v.Y or 0 end
    return v.z or v.Z or 0
end

function M.read_part_box(part)
    if not env.is_valid(part) or not M.is_part(part) then return nil end

    local pos, size, rv, uv, lv
    pcall(function()
        pos = part.Position
        size = part.Size
        rv = part.RightVector
        uv = part.UpVector
        lv = part.LookVector
    end)

    if not pos or not size then return nil end

    return {
        x = vec3(pos, "x"),
        y = vec3(pos, "y"),
        z = vec3(pos, "z"),
        hx = vec3(size, "x") * 0.5,
        hy = vec3(size, "y") * 0.5,
        hz = vec3(size, "z") * 0.5,
        rx = rv and vec3(rv, "x") or 1,
        ry = rv and vec3(rv, "y") or 0,
        rz = rv and vec3(rv, "z") or 0,
        ux = uv and vec3(uv, "x") or 0,
        uy = uv and vec3(uv, "y") or 1,
        uz = uv and vec3(uv, "z") or 0,
        lx = lv and vec3(lv, "x") or 0,
        ly = lv and vec3(lv, "y") or 0,
        lz = lv and vec3(lv, "z") or 1,
    }
end

function M.label_position(entry)
    if not entry or not env.is_valid(entry.inst) then return nil end
    local main = M.find_main_part(entry.inst)
    if main then
        local box = M.read_part_box(main)
        if box then
            return box.x, box.y + box.hy + 0.25, box.z
        end
        local pos = main.Position
        if pos then
            return vec3(pos, "x"), vec3(pos, "y"), vec3(pos, "z")
        end
    end
    return nil
end

function M.hydrate_entry(entry)
    if not entry or not env.is_valid(entry.inst) then return entry end

    local main = M.find_main_part(entry.inst)
    entry.main_part = main

    if main then
        local box = M.read_part_box(main)
        entry.box = box
        if box then
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
        else
            local pos = main.Position
            if pos then
                entry.lx = vec3(pos, "x")
                entry.ly = vec3(pos, "y")
                entry.lz = vec3(pos, "z")
            end
        end
    end

    return entry
end

function M.refresh_entry_position(entry)
    if not entry or not env.is_valid(entry.inst) then return false end

    if entry.main_part and env.is_valid(entry.main_part) then
        local box = M.read_part_box(entry.main_part)
        if box then
            entry.box = box
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
            return true
        end
    end

    M.hydrate_entry(entry)

    if not entry.lx and entry.root and env.is_valid(entry.root) then
        local box = M.read_part_box(entry.root)
        if box then
            entry.box = box
            entry.main_part = entry.root
            entry.lx = box.x
            entry.ly = box.y + box.hy + 0.25
            entry.lz = box.z
            return true
        end
        local ok, pos = pcall(function() return entry.root.Position end)
        if ok and pos then
            entry.lx = pos.X or pos.x
            entry.ly = (pos.Y or pos.y) + 0.25
            entry.lz = pos.Z or pos.z
            return true
        end
    end

    return entry.lx ~= nil
end

function M.entry_coords(entry)
    if entry and entry.lx and entry.ly and entry.lz then
        return entry.lx, entry.ly, entry.lz
    end
    return M.label_position(entry)
end

return M
