local constants = July.require("core.constants")
local settings = July.require("core.settings")
local color_util = July.require("core.color_util")
local menu_util = July.require("core.menu_util")

local M = {}

M.CONFIG_IDS = {
    "havoc_aimbot_enabled",
    "havoc_aimbot_bone", "havoc_aimbot_target_type",
    "havoc_aimbot_fov", "havoc_aimbot_max_distance", "havoc_aimbot_smooth", "havoc_aimbot_sticky",
    "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
    "july_silent_aim", "july_silent_rainbow",
    "july_silent_target_type", "july_silent_bone", "july_silent_lmb_only", "july_silent_rmb_only",
    "july_silent_filter_health", "july_silent_filter_visible", "july_silent_filter_team",
    "july_silent_target_players", "july_silent_target_npcs", "july_silent_target_npc_soldiers", "july_silent_target_npc_bosses",
    "july_silent_max_dist", "july_silent_fov", "july_silent_sticky",
    "july_silent_wallbang", "july_silent_bullet_tp", "july_silent_tp_ray_mode", "july_silent_tp_ray_vis",
    "july_silent_bullet_manip", "july_silent_manip_dist", "july_silent_manip_status",
    "july_silent_draw_fov", "july_silent_fov_style", "july_silent_target_line",
    "havoc_npc_enabled", "havoc_npc_enabled_mode",
    "havoc_npc_show_scav", "havoc_npc_show_boss", "havoc_npc_show_sniper",
    "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill",
    "havoc_npc_name", "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_npc_type",
    "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_chams_style",
    "havoc_npc_skeleton", "havoc_npc_hide_dead", "havoc_npc_rainbow",
    "havoc_npc_max_distance", "havoc_npc_name_size", "havoc_npc_health_text_size",
    "havoc_npc_held_item_size", "havoc_npc_distance_size", "havoc_npc_npc_type_size",
    "havoc_loot_enabled", "havoc_loot_enabled_mode", "havoc_loot_types",
    "havoc_loot_box", "havoc_loot_box_style",
    "havoc_loot_distance", "havoc_loot_distance_pos",
    "havoc_loot_marker", "havoc_loot_filter", "havoc_loot_rainbow",
    "havoc_loot_max_distance", "havoc_loot_text_size",
    "havoc_trap_enabled", "havoc_trap_enabled_mode", "havoc_trap_types",
    "havoc_trap_box", "havoc_trap_box_style",
    "havoc_trap_distance", "havoc_trap_distance_pos",
    "havoc_trap_marker", "havoc_trap_rainbow",
    "havoc_trap_max_distance", "havoc_trap_text_size",
    "havoc_target_gear", "havoc_target_gear_fov", "havoc_target_gear_gear_size", "havoc_target_gear_top",
    "havoc_weapon_mods_enabled", "havoc_weapon_mods_enabled_mode",
    "havoc_no_recoil", "havoc_no_spread", "havoc_no_sway", "havoc_fast_vel",
}

M.CONFIG_COLOR_IDS = {
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "july_silent_draw_fov", "july_silent_target_line", "july_silent_tp_ray_vis",
    "havoc_loot_box",
    "havoc_trap_box",
    "havoc_npc_box", "havoc_npc_box_fill", "havoc_npc_name", "havoc_npc_distance",
    "havoc_npc_held_item", "havoc_npc_npc_type", "havoc_npc_health_text",
    "havoc_npc_chams", "havoc_npc_skeleton",
}

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
    return nil
end

function M.save()
    local lines = { "# values" }
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        local val = settings.get(id)
        if val ~= nil then lines[#lines + 1] = id .. "=" .. val_to_str(val) end
    end
    lines[#lines + 1] = "# colors"
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        local val = settings.color(id)
        if val and type(val) == "table" and #val == 4 then
            lines[#lines + 1] = id .. "=" .. val_to_str(val)
        end
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

    local values, colors = {}, {}
    local section = nil
    for line in content:gmatch("[^\r\n]+") do
        if line == "# values" then section = "values"
        elseif line == "# colors" then section = "colors"
        else
            local key, val_str = line:match("^([^=]+)=(.+)$")
            if key and val_str then
                if section == "colors" then colors[key] = str_to_val(val_str)
                elseif section == "values" then values[key] = str_to_val(val_str) end
            end
        end
    end

    local count = 0
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        if values[id] ~= nil then
            local ok = (menu.set and menu.set(id, values[id])) or (menu.Set and menu.Set(id, values[id]))
            if ok ~= false then count = count + 1 end
        end
    end
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        if colors[id] ~= nil then
            local default = menu_util.COLOR_DEFAULTS[id] or { 1, 1, 1, 1 }
            local normalized = color_util.normalize_rgba(colors[id], default)
            local ok = (menu.set_color and menu.set_color(id, normalized))
                or (menu.SetColor and menu.SetColor(id, normalized))
            if ok ~= false then count = count + 1 end
        end
    end

    if count > 0 then notify.Success("Loaded " .. count .. " settings") end
end

function M.register_menu()
    local TAB = July.require("menu.menu_defs").TAB
    menu.add_button(TAB, "Config", "btn_save_config", "Save Config", M.save)
    menu.add_button(TAB, "Config", "btn_load_config", "Load Config", M.load)
end

return M
