local env = July.require("core.env")

local M = {}

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    UnionOperation = true,
    WedgePart = true,
    CornerWedgePart = true,
    TrussPart = true,
}

function M.is_part(inst)
    if not inst then return false end
    if PART_CLASSES[inst.ClassName] then return true end
    return env.safe_call(function()
        if inst.IsA then return inst:IsA("BasePart") end
        if inst.is_a then return inst:is_a("BasePart") end
        return false
    end) == true
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

    local base = env.safe_call(function()
        return model:FindFirstChild("Base")
    end)
    if base and M.is_part(base) then return base end

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

local function read_axes(part)
    local rv, uv, lv
    pcall(function()
        local cf = part.CFrame
        if cf then
            rv = cf.RightVector or cf.XVector
            uv = cf.UpVector or cf.YVector
            lv = cf.LookVector
            if not lv and cf.ZVector then
                local zx = cf.ZVector.X or cf.ZVector.x or 0
                local zy = cf.ZVector.Y or cf.ZVector.y or 0
                local zz = cf.ZVector.Z or cf.ZVector.z or 0
                lv = { X = -zx, Y = -zy, Z = -zz }
            end
        end
    end)
    if not rv or not uv or not lv then
        pcall(function()
            rv = rv or part.RightVector
            uv = uv or part.UpVector
            lv = lv or part.LookVector
        end)
    end
    return rv, uv, lv
end

function M.read_part_box(part)
    if not env.is_valid(part) or not M.is_part(part) then return nil end

    local pos, size
    pcall(function()
        pos = part.Position
        size = part.Size
    end)
    if not pos or not size then return nil end

    local rv, uv, lv = read_axes(part)

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

-- ponytail: GetBoundingBox is accurate but too heavy for per-frame ESP; use on demand only.
function M.read_model_box(model)
    if not env.is_valid(model) then return nil end
    local main = M.find_main_part(model)
    return M.read_part_box(main)
end

local function expand_aabb(minx, miny, minz, maxx, maxy, maxz, box)
    local corners = {
        { -1, -1, -1 }, { 1, -1, -1 }, { -1, 1, -1 }, { 1, 1, -1 },
        { -1, -1, 1 }, { 1, -1, 1 }, { -1, 1, 1 }, { 1, 1, 1 },
    }
    for i = 1, 8 do
        local s = corners[i]
        local wx = box.x + box.rx * box.hx * s[1] + box.ux * box.hy * s[2] - box.lx * box.hz * s[3]
        local wy = box.y + box.ry * box.hx * s[1] + box.uy * box.hy * s[2] - box.ly * box.hz * s[3]
        local wz = box.z + box.rz * box.hx * s[1] + box.uz * box.hy * s[2] - box.lz * box.hz * s[3]
        if wx < minx then minx = wx end
        if wy < miny then miny = wy end
        if wz < minz then minz = wz end
        if wx > maxx then maxx = wx end
        if wy > maxy then maxy = wy end
        if wz > maxz then maxz = wz end
    end
    return minx, miny, minz, maxx, maxy, maxz
end

-- Multi-part world AABB (cheap, no GetBoundingBox).
function M.read_parts_aabb(model, max_parts)
    if not env.is_valid(model) then return nil end
    max_parts = max_parts or 6

    local minx, miny, minz = math.huge, math.huge, math.huge
    local maxx, maxy, maxz = -math.huge, -math.huge, -math.huge
    local count = 0

    local function visit(inst, depth)
        if not inst or not env.is_valid(inst) or depth > 4 or count >= max_parts then return end
        if M.is_part(inst) then
            local box = M.read_part_box(inst)
            if box then
                minx, miny, minz, maxx, maxy, maxz = expand_aabb(minx, miny, minz, maxx, maxy, maxz, box)
                count = count + 1
            end
            return
        end
        local children = env.safe_call(function() return inst:GetChildren() end)
        if not children then return end
        for i = 1, #children do
            visit(children[i], depth + 1)
        end
    end

    visit(model, 0)
    if count == 0 or minx == math.huge then return nil end

    local cx = (minx + maxx) * 0.5
    local cy = (miny + maxy) * 0.5
    local cz = (minz + maxz) * 0.5
    return {
        x = cx, y = cy, z = cz,
        hx = (maxx - minx) * 0.5,
        hy = (maxy - miny) * 0.5,
        hz = (maxz - minz) * 0.5,
        rx = 1, ry = 0, rz = 0,
        ux = 0, uy = 1, uz = 0,
        lx = 0, ly = 0, lz = 1,
        aabb = true,
    }
end

local function set_label_from_box(entry, box)
    entry.box = box
    entry.lx = box.x
    entry.ly = box.y + box.hy + 0.25
    entry.lz = box.z
end

local function set_label_from_pos(entry, pos)
    entry.lx = vec3(pos, "x")
    entry.ly = vec3(pos, "y") + 0.25
    entry.lz = vec3(pos, "z")
end

function M.label_position(entry)
    if not entry or not env.is_valid(entry.inst) then return nil end
    local main = entry.main_part or M.find_main_part(entry.inst)
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

function M.hydrate_entry(entry, opts)
    if not entry then return entry end
    opts = opts or {}

    local target = opts.part or entry.main_part or entry.root
    if not target or not env.is_valid(target) then
        target = entry.inst or entry.model
    end
    if not target or not env.is_valid(target) then return entry end

    if opts.aabb_inst and env.is_valid(opts.aabb_inst) then
        local aabb = M.read_parts_aabb(opts.aabb_inst, opts.max_parts)
        if aabb then
            entry.main_part = M.find_main_part(opts.aabb_inst) or target
            set_label_from_box(entry, aabb)
            return entry
        end
    end

    if M.is_part(target) then
        entry.main_part = target
        local box = M.read_part_box(target)
        if box then
            set_label_from_box(entry, box)
        else
            local pos = target.Position
            if pos then set_label_from_pos(entry, pos) end
        end
        return entry
    end

    entry.main_part = M.find_main_part(target)
    local main = entry.main_part
    if main then
        local box = M.read_part_box(main)
        if box then
            set_label_from_box(entry, box)
        else
            local pos = main.Position
            if pos then set_label_from_pos(entry, pos) end
        end
    end

    return entry
end

-- Cheap live refresh: main/root part only (no GetBoundingBox).
function M.refresh_entry_position(entry)
    if not entry then return false end

    local part = entry.main_part
    if not part or not env.is_valid(part) then
        part = entry.root
    end
    if not part or not env.is_valid(part) then
        local inst = entry.inst or entry.model
        if inst and env.is_valid(inst) then
            part = M.find_main_part(inst)
            entry.main_part = part
        end
    end

    if part and env.is_valid(part) then
        local box = M.read_part_box(part)
        if box then
            set_label_from_box(entry, box)
            return true
        end
        local ok, pos = pcall(function() return part.Position end)
        if ok and pos then
            set_label_from_pos(entry, pos)
            return true
        end
    end

    return entry.lx ~= nil
end

function M.refresh_entry_bounds(entry)
    if not entry then return false end
    local constants = July.require("core.constants")

    if entry.is_drop then
        local part = entry.root or entry.main_part
        if part and env.is_valid(part) then
            entry.main_part = part
            local box = M.read_part_box(part)
            if box then
                set_label_from_box(entry, box)
                return true
            end
        end
        return false
    end

    local inst = entry.inst or entry.model
    if inst and env.is_valid(inst) then
        local aabb = M.read_parts_aabb(inst, constants.LOOT_MAX_PARTS or 8)
        if aabb then
            entry.main_part = M.find_main_part(inst) or entry.main_part
            set_label_from_box(entry, aabb)
            return true
        end
        return M.refresh_entry_position(entry)
    end

    return false
end

function M.entry_coords(entry)
    if entry and entry.lx and entry.ly and entry.lz then
        return entry.lx, entry.ly, entry.lz
    end
    return M.label_position(entry)
end

return M
