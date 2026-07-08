local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local menu_defs = July.require("menu.menu_defs")

local M = {}

M.CONFIG_IDS = {
    "havoc_aimbot_enabled", "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "havoc_aimbot_rainbow",
    "havoc_npc_enabled", "havoc_npc_box", "havoc_npc_box_style", "havoc_npc_box_fill", "havoc_npc_name",
    "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_health_bar",
    "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_chams_style", "havoc_npc_skeleton",
    "havoc_npc_rainbow",
    "havoc_npc_hide_dead", "havoc_no_recoil", "havoc_no_spread",
    "havoc_no_sway", "havoc_fast_vel", "havoc_loot_enabled",
    "havoc_loot_rainbow",
    "havoc_loot_distance", "havoc_loot_marker",
    "havoc_aimbot_bone", "havoc_aimbot_target_type",
    "havoc_loot_distance_pos", "havoc_loot_filter",
    "havoc_aimbot_fov", "havoc_aimbot_max_distance",
    "havoc_npc_max_distance", "havoc_loot_max_distance", "havoc_loot_text_size",
}

M.CONFIG_COLOR_IDS = {
    "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line",
    "havoc_npc_box", "havoc_npc_box_fill", "havoc_npc_name", "havoc_npc_distance",
    "havoc_npc_held_item", "havoc_npc_health_text",
    "havoc_npc_chams", "havoc_npc_skeleton",
}

M.CONFIG_COLOR_IDS[#M.CONFIG_COLOR_IDS + 1] = "havoc_loot_enabled"
for i = 1, #loot_catalog.LOOT_TYPES do
    M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.LOOT_TYPES[i].key
end
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.LOOT_FALLBACK.key
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = loot_catalog.BODY_BAG_TYPE.key
M.CONFIG_COLOR_IDS[#M.CONFIG_COLOR_IDS + 1] = "havoc_trap_enabled"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_enabled"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_max_distance"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_rainbow"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_trap_text_size"
M.CONFIG_IDS[#M.CONFIG_IDS + 1] = "havoc_npc_npc_type"

local function val_to_str(v)
    local t = type(v)
    if t == "boolean" then
        return v and "true" or "false"
    elseif t == "number" then
        return tostring(v)
    elseif t == "table" then
        return table.concat({ v[1], v[2], v[3], v[4] }, ",")
    end
    return tostring(v)
end

local function str_to_val(s)
    if s == "true" then return true end
    if s == "false" then return false end
    local n = tonumber(s)
    if n then return n end
    local r, g, b, a = s:match("^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
    if r then
        return { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }
    end
    return nil
end

function M.save()
    local lines = { "# values" }
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        local val = menu.Get(id)
        lines[#lines + 1] = id .. "=" .. val_to_str(val)
    end
    lines[#lines + 1] = "# colors"
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        local val = menu.GetColor(id)
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
    notify.Success("Config saved (" .. #M.CONFIG_IDS + #M.CONFIG_COLOR_IDS .. " values)")
end

function M.load()
    local f, err = io.open(constants.CONFIG_PATH, "r")
    if not f then
        notify.Warning("No config at " .. constants.CONFIG_PATH, "", 4)
        return
    end
    local content = f:read("*a")
    f:close()

    local values = {}
    local colors = {}
    local section = nil
    for line in content:gmatch("[^\r\n]+") do
        if line == "# values" then
            section = "values"
        elseif line == "# colors" then
            section = "colors"
        else
            local key, val_str = line:match("^([^=]+)=(.+)$")
            if key and val_str then
                if section == "colors" then
                    colors[key] = str_to_val(val_str)
                elseif section == "values" then
                    values[key] = str_to_val(val_str)
                end
            end
        end
    end

    local count = 0
    for i = 1, #M.CONFIG_IDS do
        local id = M.CONFIG_IDS[i]
        if values[id] ~= nil then
            local ok = menu.Set and menu.Set(id, values[id])
            if ok ~= false then count = count + 1 end
        end
    end
    for i = 1, #M.CONFIG_COLOR_IDS do
        local id = M.CONFIG_COLOR_IDS[i]
        if colors[id] ~= nil then
            local ok = menu.SetColor and menu.SetColor(id, colors[id])
            if ok ~= false then count = count + 1 end
        end
    end

    if count > 0 then
        notify.Success("Loaded " .. count .. " settings")
    else
        notify.Warning("Loaded but 0 settings applied — check if menu.Set/menu.SetColor exist", "", 6)
    end
end

function M.register_menu()
    local TAB = menu_defs.TAB
    menu.AddButton(TAB, "Config", "btn_save_config", "Save Config", M.save)
    menu.AddButton(TAB, "Config", "btn_load_config", "Load Config", M.load)
end

return M
