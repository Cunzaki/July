-- GPU instance chams with a double-buffer applied set.
--
-- front (owner.applied) = addresses currently stamped by the engine
-- back  (fresh collect) = addresses that SHOULD be chammed this tick (in-range only)
--
-- If back == front → no work (or only apply brand-new addrs).
-- If any addr left back → RevertChams + re-apply ONLY back (all active owners).
-- That is the "double buffer": never leave stale out-of-range instances chammed.
--
-- Range is fail-closed: without a local player position, collect applies nothing.

local settings = July.require("core.settings")
local env = July.require("core.env")

local M = {}

M.MODE_LABELS = { "Fill", "Wireframe", "Fill Glow", "Wireframe Glow" }
M.COLOR_LABELS = { "Default", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan" }

local PART_CLASSES = {
    Part = true,
    MeshPart = true,
    WedgePart = true,
    CornerWedgePart = true,
    TrussPart = true,
    UnionOperation = true,
    NegateOperation = true,
}

local owners = {}
local owner_order = {}
local rebuild_busy = false
local last_global_rebuild = 0
local MIN_REBUILD_GAP_MS = 250

function M.available()
    return exploits ~= nil
        and type(exploits.ApplyChamsToInstance) == "function"
        and type(exploits.RevertChams) == "function"
        and type(exploits.SetChamsMode) == "function"
        and type(exploits.SetChamsColor) == "function"
end

function M.is_part(inst)
    if not inst then return false end
    local cn = inst.ClassName or inst.class_name
    if PART_CLASSES[cn] then return true end
    return env.safe_call(function()
        if inst.is_a then return inst:is_a("BasePart") end
        if inst.IsA then return inst:IsA("BasePart") end
        return false
    end) == true
end

function M.instance_addr(inst)
    if not inst then return nil end
    return inst.Address or inst.address
end

function M.color_visible_for_mode(mode)
    mode = tonumber(mode) or 0
    return mode == 2 or mode == 3
end

function M.mode_index(id, default)
    return settings.combo_index(id, M.MODE_LABELS, default or 0)
end

function M.color_index(id, default)
    return settings.combo_index(id, M.COLOR_LABELS, default or 0)
end

function M.multicombo_selected(id, index)
    return settings.multi(id, index, false)
end

function M.multicombo_defaults(count)
    local out = {}
    for i = 1, count do
        out[i] = false
    end
    return out
end

local function now_ms()
    return utility and utility.get_tick_count and utility.get_tick_count() or 0
end

local function push_style(mode, color)
    pcall(function() exploits.SetChamsMode(mode or 0) end)
    pcall(function() exploits.SetChamsColor(color or 0) end)
end

local function any_other_active(except_id)
    for _, oid in ipairs(owner_order) do
        local o = owners[oid]
        if o and oid ~= except_id and o.is_active() then
            return true
        end
    end
    return false
end

local function sets_equal(a, b)
    for k in pairs(a) do
        if not b[k] then return false end
    end
    for k in pairs(b) do
        if not a[k] then return false end
    end
    return true
end

local function has_removed(prev, fresh)
    for addr in pairs(prev) do
        if not fresh[addr] then return true end
    end
    return false
end

local function apply_one(inst, applied)
    if not M.available() or not inst then return false end
    if not M.is_part(inst) then return false end
    local addr = M.instance_addr(inst)
    if not addr then return false end
    if applied[addr] then return true end
    local ok, result = pcall(exploits.ApplyChamsToInstance, inst)
    -- Some builds return nil on success; only treat explicit false as failure.
    if ok and result ~= false then
        applied[addr] = true
        return true
    end
    return false
end

function M.cham_part(inst, applied)
    return apply_one(inst, applied or {})
end

-- Fallen R15: body MeshParts + nested armor copies under skin Models (dump).
local PLAYER_CHAM_NAMES = {
    Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
    LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true,
    LeftHand = true, RightHand = true,
    LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true,
    LeftFoot = true, RightFoot = true,
    Armor = true, -- clothing layer MeshParts under Default/Abibas models
}

local PLAYER_CHAM_SKIP = {
    HumanoidRootPart = true,
    CollisionPart = true,
}

function M.cham_player_character(char, applied)
    if not char or not env.is_valid(char) then return 0 end
    applied = applied or {}

    local list = env.safe_call(function()
        if char.get_descendants then return char:get_descendants() end
        return char:GetDescendants()
    end) or {}

    local n = 0
    for i = 1, #list do
        local inst = list[i]
        local name = inst and (inst.Name or inst.name)
        if name and PLAYER_CHAM_NAMES[name] and not PLAYER_CHAM_SKIP[name] then
            if apply_one(inst, applied) then
                n = n + 1
            end
        end
    end

    -- Fallback: direct children only (some builds omit nested descendants).
    if n == 0 then
        local kids = env.safe_call(function()
            if char.get_children then return char:get_children() end
            return char:GetChildren()
        end) or {}
        for i = 1, #kids do
            local inst = kids[i]
            local name = inst and (inst.Name or inst.name)
            if name and PLAYER_CHAM_NAMES[name] and not PLAYER_CHAM_SKIP[name] then
                if apply_one(inst, applied) then
                    n = n + 1
                end
            end
        end
    end

    return n
end

-- Prefer a single visual part per ESP entry (Main / HRP / first MeshPart).
-- Cham'ing every descendant was heavy and made shared-mesh bleed worse.
function M.cham_entry_part(entry, applied)
    if not entry then return false end
    local part = entry.main_part
    if part and env.is_valid(part) and M.is_part(part) then
        return apply_one(part, applied)
    end
    if entry.inst and env.is_valid(entry.inst) then
        local esp_scan = July.require("game.esp_scan")
        local main = esp_scan.find_main_part(entry.inst)
        if main then
            entry.main_part = main
            return apply_one(main, applied)
        end
        -- Animals / odd models: first MeshPart descendant
        local desc = env.safe_call(function()
            if entry.inst.get_descendants then return entry.inst:get_descendants() end
            return entry.inst:GetDescendants()
        end) or {}
        for _, d in ipairs(desc) do
            if M.is_part(d) then
                entry.main_part = d
                return apply_one(d, applied)
            end
        end
    end
    return false
end

function M.cham_model_main(model, applied)
    if not model then return false end
    local esp_scan = July.require("game.esp_scan")
    local main = esp_scan.find_main_part(model)
    if main then return apply_one(main, applied) end
    return apply_one(model, applied)
end

function M.cham_container_parts(container, applied, max_parts)
    -- Kept for compatibility; prefer cham_entry_part for ESP.
    max_parts = max_parts or 8
    if not container then return 0 end
    local n = 0
    local main = July.require("game.esp_scan").find_main_part(container)
    if main and apply_one(main, applied) then
        n = n + 1
    end
    if n > 0 then return n end

    local list = env.safe_call(function()
        if container.get_descendants then return container:get_descendants() end
        return container:GetDescendants()
    end) or {}
    for _, d in ipairs(list) do
        if n >= max_parts then break end
        if apply_one(d, applied) then n = n + 1 end
    end
    return n
end

function M.register_owner(id, opts)
    opts = opts or {}
    if not owners[id] then
        owner_order[#owner_order + 1] = id
    end
    owners[id] = {
        id = id,
        applied = {}, -- front buffer
        was_active = false,
        is_active = opts.is_active or function() return false end,
        style = opts.style or function() return 0, 0 end,
        collect = opts.collect or function(_back) end,
        last_rescan = 0,
        rescan_ms = opts.rescan_ms or 500,
    }
    return owners[id]
end

function M.get_owner(id)
    return owners[id]
end

local function apply_owner_into(owner, into)
    if not owner or not owner.is_active() then return end
    local mode, color = owner.style()
    push_style(mode, color)
    pcall(owner.collect, into)
end

function M.rebuild_all()
    if not M.available() or rebuild_busy then return false end
    local now = now_ms()
    if last_global_rebuild ~= 0 and (now - last_global_rebuild) < MIN_REBUILD_GAP_MS then
        return false
    end
    last_global_rebuild = now
    rebuild_busy = true

    pcall(function() exploits.RevertChams() end)

    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner then
            owner.applied = {}
            owner.last_rescan = 0
        end
    end

    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner and owner.is_active() then
            local back = {}
            apply_owner_into(owner, back)
            owner.applied = back
            owner.was_active = true
        elseif owner then
            owner.was_active = false
        end
    end

    rebuild_busy = false
    return true
end

function M.revert_all()
    if not M.available() then return end
    pcall(function() exploits.RevertChams() end)
    last_global_rebuild = now_ms()
    for _, id in ipairs(owner_order) do
        local owner = owners[id]
        if owner then
            owner.applied = {}
            owner.was_active = false
            owner.last_rescan = 0
        end
    end
end

function M.clear_owner(id, rebuild_others)
    local owner = owners[id]
    if not owner then return end
    local had = owner.was_active or next(owner.applied) ~= nil
    owner.applied = {}
    owner.was_active = false
    owner.last_rescan = 0
    if not had or rebuild_others == false then return end
    if any_other_active(id) then
        M.rebuild_all()
    else
        M.revert_all()
    end
end

function M.refresh_owner_style(id)
    local owner = owners[id]
    if not owner then return end
    if not owner.is_active() then
        M.clear_owner(id)
        return
    end
    -- Style change: must re-stamp; safest is full rebuild of active set.
    M.rebuild_all()
end

function M.sync_owner(id, force)
    if not M.available() or rebuild_busy then return end
    local owner = owners[id]
    if not owner then return end

    if not owner.is_active() then
        if owner.was_active or next(owner.applied) ~= nil then
            M.clear_owner(id)
        end
        return
    end

    local now = now_ms()
    if not force and owner.last_rescan ~= 0 and (now - owner.last_rescan) < owner.rescan_ms then
        owner.was_active = true
        return
    end
    owner.last_rescan = now
    owner.was_active = true

    -- Back buffer: what should be chammed right now (collectors must range-filter).
    local back = {}
    local mode, color = owner.style()
    push_style(mode, color)
    local ok = pcall(owner.collect, back)
    if not ok then return end

    local front = owner.applied

    if sets_equal(front, back) then
        return
    end

    if has_removed(front, back) or next(front) == nil then
        -- Something left range / first populate after clear → swap buffers via rebuild.
        -- Rebuild reapplies ALL active owners from scratch (correct multi-owner state).
        owner.applied = {}
        if not M.rebuild_all() then
            -- Rate-limited: still track desired set; next tick will rebuild.
            owner.applied = back
        end
        return
    end

    -- Only additions: stamp new addresses, no Revert needed.
    for addr, _ in pairs(back) do
        if not front[addr] then
            pcall(exploits.ApplyChamsToInstance, addr)
            front[addr] = true
        end
    end
    owner.applied = front
end

function M.wire_style_controls(owner_id, mode_id, color_id)
    if not menu or not menu.set_visible then return end

    local function sync_color_vis()
        local mode = M.mode_index(mode_id, 0)
        pcall(menu.set_visible, color_id, M.color_visible_for_mode(mode))
    end

    settings.on_change(mode_id, function()
        sync_color_vis()
        M.refresh_owner_style(owner_id)
    end)
    settings.on_change(color_id, function()
        M.refresh_owner_style(owner_id)
    end)
    sync_color_vis()
end

function M.add_mode_color_menu(T, G, parent_id, mode_id, color_id, mode_label, color_label)
    local root = { parent = parent_id }
    menu.add_combo(T, G, mode_id, mode_label or "Chams Mode", M.MODE_LABELS, 0, root)
    menu.add_combo(T, G, color_id, color_label or "Chams Color", M.COLOR_LABELS, 0, root)
    return mode_id, color_id
end

return M
