local constants = July.require("core.constants")
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local menu_util = July.require("core.menu_util")
local menu_defs = July.require("menu.menu_defs")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")

local M = {}

local function append_unique(list, seen, id)
    if not id or seen[id] then return end
    seen[id] = true
    list[#list + 1] = id
end

local function fallback_registry()
    local value_ids = {}
    local color_ids = {}
    local seen_v, seen_c = {}, {}

    local static_values = {
        "havoc_aimbot_enabled",
        "havoc_aimbot_keybind", "havoc_aimbot_keybind_mode",
        "havoc_aimbot_bone", "havoc_aimbot_target_type",
        "havoc_aimbot_fov", "havoc_aimbot_max_distance", "havoc_aimbot_smooth", "havoc_aimbot_sticky",
        "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
        "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
        "havoc_npc_enabled", "havoc_npc_enabled_mode",
        "havoc_npc_show_scav", "havoc_npc_show_boss", "havoc_npc_show_sniper",
        "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill",
        "havoc_npc_name", "havoc_npc_name_size",
        "havoc_npc_distance", "havoc_npc_distance_size",
        "havoc_npc_held_item", "havoc_npc_held_item_size",
        "havoc_npc_ammo", "havoc_npc_ammo_size",
        "havoc_npc_reloading", "havoc_npc_reloading_size",
        "havoc_npc_npc_type", "havoc_npc_npc_type_size",
        "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_health_text_size",
        "havoc_npc_chams", "havoc_npc_chams_style",
        "havoc_npc_skeleton", "havoc_npc_hide_dead", "havoc_npc_rainbow",
        "havoc_npc_max_distance",
        "havoc_loot_enabled", "havoc_loot_enabled_mode",
        "havoc_loot_box", "havoc_loot_box_style",
        "havoc_loot_distance", "havoc_loot_distance_pos",
        "havoc_loot_marker", "havoc_loot_filter", "havoc_loot_rainbow",
        "havoc_loot_max_distance", "havoc_loot_text_size",
        "havoc_trap_enabled", "havoc_trap_enabled_mode",
        "havoc_trap_box", "havoc_trap_box_style",
        "havoc_trap_distance", "havoc_trap_distance_pos",
        "havoc_trap_marker", "havoc_trap_rainbow",
        "havoc_trap_max_distance", "havoc_trap_text_size",
        "havoc_local_ammo", "havoc_local_ammo_size",
        "havoc_local_reloading", "havoc_local_reloading_size",
        "havoc_target_gear", "havoc_target_gear_fov", "havoc_target_gear_gear_size", "havoc_target_gear_top",
    }

    local static_colors = {
        "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
        "havoc_loot_box", "havoc_trap_box",
        "havoc_npc_box", "havoc_npc_box_fill", "havoc_npc_name", "havoc_npc_distance",
        "havoc_npc_held_item", "havoc_npc_ammo", "havoc_npc_reloading", "havoc_npc_npc_type",
        "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_skeleton",
        "havoc_local_ammo", "havoc_local_reloading",
    }

    for i = 1, #static_values do
        append_unique(value_ids, seen_v, static_values[i])
    end
    for i = 1, #static_colors do
        append_unique(color_ids, seen_c, static_colors[i])
    end

    local catalogs = { loot_catalog.LOOT_TYPES, loot_catalog.DROP_TYPES, { loot_catalog.BODY_BAG_TYPE }, trap_types.TRAP_TYPES }
    for c = 1, #catalogs do
        local entries = catalogs[c]
        for i = 1, #entries do
            local key = entries[i].key
            append_unique(value_ids, seen_v, key)
            append_unique(color_ids, seen_c, key)
        end
    end

    return { value_ids = value_ids, color_ids = color_ids }
end

local function get_registry()
    local reg = menu_defs.get_config_registry and menu_defs.get_config_registry()
    if reg and reg.value_ids and #reg.value_ids > 0 then
        return reg
    end
    return fallback_registry()
end

local function read_value(id)
    if menu and menu.get then
        local v = menu.get(id)
        if v ~= nil then return v end
    end
    if menu and menu.Get then
        local v = menu.Get(id)
        if v ~= nil then return v end
    end
    return settings.get(id)
end

local function read_key(id)
    if menu and menu.get_key then
        local k = menu.get_key(id)
        if k ~= nil then return tonumber(k) or 0 end
    end
    return 0
end

local function write_value(id, val)
    if val == nil then return false end
    if menu and menu.set then
        local ok = pcall(menu.set, id, val)
        if ok then return true end
    end
    if menu and menu.Set then
        local ok = pcall(menu.Set, id, val)
        if ok then return true end
    end
    return false
end

local function write_key(id, key)
    key = tonumber(key) or 0
    if menu and menu.set_key then
        local ok = pcall(menu.set_key, id, key)
        if ok then return true end
    end
    if menu and menu.SetKey then
        local ok = pcall(menu.SetKey, id, key)
        if ok then return true end
    end
    return false
end

local function val_to_str(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false"
    elseif t == "number" then return tostring(v)
    elseif t == "table" then
        local parts = {}
        for i = 1, #v do
            if type(v[i]) == "boolean" then
                parts[i] = v[i] and "1" or "0"
            elseif type(v[i]) == "number" then
                parts[i] = tostring(v[i])
            else
                parts[i] = tostring(v[i])
            end
        end
        return table.concat(parts, ",")
    end
    return tostring(v)
end

local function str_to_val(s)
    if s == "true" then return true end
    if s == "false" then return false end
    local n = tonumber(s)
    if n then return n end
    if s:find(",", 1, true) then
        local out = {}
        for part in s:gmatch("[^,]+") do
            if part == "1" or part == "true" then out[#out + 1] = true
            elseif part == "0" or part == "false" then out[#out + 1] = false
            else
                local num = tonumber(part)
                out[#out + 1] = num or part
            end
        end
        return out
    end
    local r, g, b, a = s:match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
    if r then return { tonumber(r), tonumber(g), tonumber(b), tonumber(a) } end
    return s
end

function M.save()
    local reg = get_registry()
    local feature_bind = July.require("core.feature_bind")

    local lines = { "# values" }
    for i = 1, #reg.value_ids do
        local id = reg.value_ids[i]
        local val = read_value(id)
        if val ~= nil then
            lines[#lines + 1] = id .. "=" .. val_to_str(val)
        end
    end

    lines[#lines + 1] = "# colors"
    for i = 1, #reg.color_ids do
        local id = reg.color_ids[i]
        local val = settings.color(id)
        if val and type(val) == "table" and #val == 4 then
            lines[#lines + 1] = id .. "=" .. val_to_str(val)
        end
    end

    lines[#lines + 1] = "# keys"
    local key_ids = feature_bind.get_key_ids and feature_bind.get_key_ids() or {}
    for i = 1, #key_ids do
        local id = key_ids[i]
        lines[#lines + 1] = id .. "=" .. tostring(read_key(id))
    end

    local f, err = io.open(constants.CONFIG_PATH, "w")
    if not f then
        notify.Warning("Config save failed: " .. tostring(err), "", 4)
        return
    end
    f:write(table.concat(lines, "\n"))
    f:close()
    notify.Success("Config saved")
end

function M.load()
    local f = io.open(constants.CONFIG_PATH, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    local reg = get_registry()
    local feature_bind = July.require("core.feature_bind")

    local values, colors, keys = {}, {}, {}
    local section = nil
    for line in content:gmatch("[^\r\n]+") do
        if line == "# values" then section = "values"
        elseif line == "# colors" then section = "colors"
        elseif line == "# keys" then section = "keys"
        else
            local key, val_str = line:match("^([^=]+)=(.+)$")
            if key and val_str then
                if section == "colors" then colors[key] = str_to_val(val_str)
                elseif section == "keys" then keys[key] = str_to_val(val_str)
                elseif section == "values" then values[key] = str_to_val(val_str) end
            end
        end
    end

    local count = 0
    for i = 1, #reg.value_ids do
        local id = reg.value_ids[i]
        if values[id] ~= nil and write_value(id, values[id]) then
            count = count + 1
        end
    end

    for i = 1, #reg.color_ids do
        local id = reg.color_ids[i]
        if colors[id] ~= nil then
            local default = menu_util.COLOR_DEFAULTS[id] or { 1, 1, 1, 1 }
            local normalized = color_util.normalize_rgba(colors[id], default)
            local ok = (menu.set_color and pcall(menu.set_color, id, normalized))
                or (menu.SetColor and pcall(menu.SetColor, id, normalized))
            if ok then count = count + 1 end
        end
    end

    for key_id, key_val in pairs(keys) do
        if write_key(key_id, key_val) then
            count = count + 1
        end
    end

    if feature_bind.reset_runtime_state then
        feature_bind.reset_runtime_state()
    end
    menu_util.sync_masters()

    if count > 0 then notify.Success("Loaded " .. count .. " settings") end
end

function M.register_menu()
    local TAB = menu_defs.TAB
    menu.add_button(TAB, "Config", "btn_save_config", "Save Config", M.save)
    menu.add_button(TAB, "Config", "btn_load_config", "Load Config", M.load)
end

return M
