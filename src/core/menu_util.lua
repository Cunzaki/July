local M = {}

M.TAB = "July"

M.G = {
    AIMBOT = "Aimbot",
    NPC = "NPC Visuals",
    LOOT = "Loot ESP",
    ITEMS = "Item ESP",
    TRAP = "Trap ESP",
    MISC = "Misc",
    CONFIG = "Config",
}

M._tab_ready = false
M._groups_ready = false
M._groups = {}
M._master_children = {}
M._master_hooked = {}
M._child_parent = {}

local function settings_mod()
    return July.require("core.settings")
end

function M.ensure_tab()
    if M._tab_ready then return end
    if not (July and July._menu_tab_ready) and menu and menu.add_tab then
        menu.add_tab(M.TAB, "J", "full")
    end
    M._tab_ready = true
end

function M.ensure_groups()
    if M._groups_ready then return end
    M.ensure_tab()

    local rows = {
        { M.G.AIMBOT, M.G.NPC },
        { M.G.LOOT, M.G.ITEMS },
        { M.G.TRAP, M.G.MISC },
        { M.G.CONFIG },
    }

    for _, row in ipairs(rows) do
        menu.add_group(M.TAB, row[1])
        M._groups[row[1]] = true
        if row[2] then
            menu.add_group(M.TAB, row[2], 0, true)
            M._groups[row[2]] = true
        end
    end

    M._groups_ready = true
end

function M.parent(main_id, extra)
    local opts = { parent = main_id }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            opts[k] = v
        end
    end
    return opts
end

local function add_child_ids(bucket, ids)
    bucket = bucket or {}
    local seen = {}
    for _, id in ipairs(bucket) do
        seen[id] = true
    end
    for _, id in ipairs(ids or {}) do
        if id and not seen[id] then
            seen[id] = true
            bucket[#bucket + 1] = id
        end
    end
    return bucket
end

local function set_visible(id, show)
    if menu and menu.set_visible and id then
        pcall(menu.set_visible, id, show)
    end
end

local function master_visible(master_id)
    local ok, fb = pcall(function()
        return July.require("core.feature_bind")
    end)
    if ok and fb and fb.is_registered(master_id) then
        return fb.active(master_id)
    end
    return settings_mod().bool(master_id, false)
end

local function is_hidden_by_master(id)
    local cur = id
    local visited = {}
    while cur do
        if visited[cur] then break end
        visited[cur] = true
        local parent = M._child_parent[cur]
        if not parent then break end
        if not master_visible(parent) then
            return true
        end
        cur = parent
    end
    return false
end

local function child_visible(master_id, enabled)
    if is_hidden_by_master(master_id) then
        return false
    end
    return master_visible(master_id) and enabled
end

function M.sync_masters()
    for master_id in pairs(M._master_hooked) do
        local show = master_visible(master_id)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, child_visible(master_id, show))
        end
    end
end

M.COLOR_DEFAULTS = {
    havoc_aimbot_draw_fov = { 1.0, 1.0, 1.0, 1.0 },
    havoc_aimbot_fill_fov = { 1.0, 1.0, 1.0, 0.15 },
    havoc_aimbot_target_line = { 1.0, 0.3, 0.3, 1.0 },
    havoc_npc_box = { 1.0, 1.0, 1.0, 1.0 },
    havoc_npc_box_fill = { 1.0, 1.0, 1.0, 0.35 },
    havoc_npc_name = { 0.92, 0.92, 0.92, 1.0 },
    havoc_npc_distance = { 0.67, 0.67, 0.67, 1.0 },
    havoc_npc_held_item = { 1.0, 0.85, 0.4, 1.0 },
    havoc_npc_npc_type = { 1.0, 0.5, 0.0, 0.85 },
    havoc_npc_health_text = { 0.3, 1.0, 0.4, 1.0 },
    havoc_npc_chams = { 1.0, 0.2, 0.2, 0.55 },
    havoc_npc_skeleton = { 1.0, 1.0, 1.0, 1.0 },
    havoc_loot_box = { 1.0, 1.0, 1.0, 1.0 },
    havoc_trap_box = { 1.0, 0.35, 0.25, 1.0 },
    havoc_item_box = { 1.0, 1.0, 1.0, 1.0 },
    havoc_local_ammo = { 0.55, 0.85, 1.0, 1.0 },
    havoc_local_reloading = { 1.0, 0.45, 0.2, 1.0 },
}

function M.seed_color_defaults()
    if not menu or not menu.set_color then return end

    local color_util = July.require("core.color_util")
    for id, default in pairs(M.COLOR_DEFAULTS) do
        local cur = menu.get_color and menu.get_color(id) or nil
        local normalized = color_util.normalize_rgba(cur, default)
        local r, g, b = normalized[1], normalized[2], normalized[3]
        if not cur or (r + g + b) < 0.04 then
            pcall(menu.set_color, id, default)
        end
    end
end

function M.bind_children(master_id, child_ids)
    if not master_id or not child_ids then return end
    M._master_children[master_id] = add_child_ids(M._master_children[master_id], child_ids)

    for _, id in ipairs(child_ids or {}) do
        if id then
            M._child_parent[id] = master_id
        end
    end

    if M._master_hooked[master_id] then return end
    M._master_hooked[master_id] = true

    local function sync(new_val)
        local enabled = master_visible(master_id)
        if new_val ~= nil then
            enabled = enabled and (new_val == true or new_val == 1)
        end
        local show = child_visible(master_id, enabled)
        for _, id in ipairs(M._master_children[master_id] or {}) do
            set_visible(id, show)
        end
    end

    settings_mod().on_change(master_id, sync)
    sync()
end

function M.register_keybind(T, G, id, label, default, extra)
    extra = extra or {}
    local cb_opts = { show_mode = false, key = extra.key or 0 }
    if extra.parent then cb_opts.parent = extra.parent end
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, id, label, default or false, cb_opts)

    local mode_id = id .. "_mode"
    local root = M.parent(id)
    menu.add_combo(T, G, mode_id, label .. " Mode", { "Toggle", "Hold" }, 0, root)

    July.require("core.feature_bind").register({
        id = id,
        mode_id = mode_id,
        key_id = id,
    })

    return mode_id
end

function M.register_feature_keybind(T, G, master_id, keybind_id, label, default, extra)
    extra = extra or {}
    local root = M.parent(master_id)
    local cb_opts = { show_mode = false, key = extra.key or 0, parent = master_id }
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, keybind_id, label, default or false, cb_opts)

    local mode_id = keybind_id .. "_mode"
    menu.add_combo(T, G, mode_id, label .. " Mode", { "Toggle", "Hold" }, 0, root)

    July.require("core.feature_bind").register({
        id = keybind_id,
        mode_id = mode_id,
        key_id = keybind_id,
    })

    return mode_id
end

function M.register_master_keybind(T, G, master_id, key_id, label, extra)
    extra = extra or {}
    local root = M.parent(master_id)
    local cb_opts = { show_mode = false, key = extra.key or 0, parent = master_id }
    if extra.colorpicker then cb_opts.colorpicker = extra.colorpicker end

    menu.add_checkbox(T, G, key_id, label, false, cb_opts)

    local mode_id = key_id .. "_mode"
    menu.add_combo(T, G, mode_id, label .. " Mode", { "Toggle", "Hold" }, 0, root)

    July.require("core.feature_bind").register({
        id = key_id,
        master_id = master_id,
        mode_id = mode_id,
        key_id = key_id,
    })

    return mode_id
end

return M
