local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")
local combat_menu = July.require("features.combat.combat_menu")
local menu_util = July.require("core.menu_util")

local M = {}
M.TAB = constants.TAB

local function register_loot_type_toggles(TAB, G, parent)
    local ids = {}
    for i = 1, #loot_catalog.LOOT_TYPES do
        local entry = loot_catalog.LOOT_TYPES[i]
        menu.add_checkbox(TAB, G, entry.key, entry.display, true, {
            parent = parent,
            colorpicker = entry.color,
        })
        menu_util.COLOR_DEFAULTS[entry.key] = entry.color
        ids[#ids + 1] = entry.key
    end
    for i = 1, #loot_catalog.DROP_TYPES do
        local entry = loot_catalog.DROP_TYPES[i]
        menu.add_checkbox(TAB, G, entry.key, entry.display, true, {
            parent = parent,
            colorpicker = entry.color,
        })
        menu_util.COLOR_DEFAULTS[entry.key] = entry.color
        ids[#ids + 1] = entry.key
    end
    local body = loot_catalog.BODY_BAG_TYPE
    menu.add_checkbox(TAB, G, body.key, body.display, true, {
        parent = parent,
        colorpicker = body.color,
    })
    menu_util.COLOR_DEFAULTS[body.key] = body.color
    ids[#ids + 1] = body.key
    return ids
end

local function register_trap_type_toggles(TAB, G, parent)
    local ids = {}
    for i = 1, #trap_types.TRAP_TYPES do
        local entry = trap_types.TRAP_TYPES[i]
        menu.add_checkbox(TAB, G, entry.key, entry.display, true, {
            parent = parent,
            colorpicker = entry.color,
        })
        menu_util.COLOR_DEFAULTS[entry.key] = entry.color
        ids[#ids + 1] = entry.key
    end
    return ids
end

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB
    local G = menu_util.G
    local P_AIM = "havoc_aimbot_enabled"
    local P_AIM_KEY = "havoc_aimbot_keybind"
    local P_NPC = "havoc_npc_enabled"
    local P_LOOT = "havoc_loot_enabled"
    local P_TRAP = "havoc_trap_enabled"

    menu_util.ensure_groups()

    -- Row 1: Aimbot | NPC Visuals
    menu.add_checkbox(TAB, G.AIMBOT, P_AIM, "Enable Aimbot", false)
    menu_util.register_feature_keybind(TAB, G.AIMBOT, P_AIM, P_AIM_KEY, "Aimbot Keybind", false)
    menu.add_combo(TAB, G.AIMBOT, "havoc_aimbot_bone", "Aimbot Target Bone", combat_menu.SILENT_BONES, 1, { parent = P_AIM })
    menu.add_combo(TAB, G.AIMBOT, "havoc_aimbot_target_type", "Aimbot Priority", { "Crosshair", "Distance" }, 0, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_fov", "Aimbot FOV Radius", 10, 500, 150, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_max_distance", "Aimbot Max Distance", 0, 3000, 3000, { parent = P_AIM })
    menu.add_slider_int(TAB, G.AIMBOT, "havoc_aimbot_smooth", "Aimbot Smoothness", 1, 100, 8, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_sticky", "Aimbot Sticky Target", false, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_players", "Aimbot Target Players", false, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_npcs", "Aimbot Target NPCs", true, { parent = P_AIM })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_draw_fov", "Aimbot FOV Circle", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 1.0 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_fill_fov", "Aimbot Fill FOV", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 0.15 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_target_line", "Aimbot Target Line", false, {
        parent = P_AIM, colorpicker = { 1.0, 0.3, 0.3, 1.0 },
    })
    menu.add_checkbox(TAB, G.AIMBOT, "havoc_aimbot_rainbow", "Aimbot Rainbow", false, { parent = P_AIM })

    menu_util.bind_children(P_AIM, {
        P_AIM_KEY, P_AIM_KEY .. "_mode",
        "havoc_aimbot_bone", "havoc_aimbot_target_type", "havoc_aimbot_fov", "havoc_aimbot_max_distance",
        "havoc_aimbot_smooth", "havoc_aimbot_sticky", "havoc_aimbot_target_players", "havoc_aimbot_target_npcs",
        "havoc_aimbot_draw_fov", "havoc_aimbot_fill_fov", "havoc_aimbot_target_line", "havoc_aimbot_rainbow",
    })

    menu_util.register_keybind(TAB, G.NPC, P_NPC, "Enable NPC Visuals", false)
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_scav", "Show Scavs", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_boss", "Show Bosses", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_show_sniper", "Show Snipers", true, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_box", "NPC Box", false,
        { parent = P_NPC, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, G.NPC, "havoc_npc_box_style", "NPC Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_box_fill", "NPC Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_name", "NPC Name", false,
        { parent = P_NPC, colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_name_size", "NPC Name Size", 6, 24, 13, { parent = "havoc_npc_name" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_distance", "NPC Distance", false,
        { parent = P_NPC, colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_distance_size", "NPC Distance Size", 6, 18, 10, { parent = "havoc_npc_distance" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_held_item", "NPC Held Item", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_held_item_size", "NPC Held Item Size", 6, 18, 10, { parent = "havoc_npc_held_item" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_npc_type", "NPC Type Tag", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_npc_type_size", "NPC Type Tag Size", 6, 18, 9, { parent = "havoc_npc_npc_type" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_health_bar", "NPC Health Bar", false, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_health_text", "NPC Health Text", false,
        { parent = P_NPC, colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_health_text_size", "NPC Health Text Size", 6, 18, 8, { parent = "havoc_npc_health_text" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_chams", "NPC Chams", false,
        { parent = P_NPC, colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.add_combo(TAB, G.NPC, "havoc_npc_chams_style", "NPC Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_skeleton", "NPC Skeleton", false,
        { parent = P_NPC, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_hide_dead", "NPC Hide Dead", false, { parent = P_NPC })
    menu.add_checkbox(TAB, G.NPC, "havoc_npc_rainbow", "NPC Rainbow", false, { parent = P_NPC })
    menu.add_slider_int(TAB, G.NPC, "havoc_npc_max_distance", "NPC Max Distance", 0, 1000, 1000, { parent = P_NPC })

    menu_util.bind_children(P_NPC, {
        "havoc_npc_show_scav", "havoc_npc_show_boss", "havoc_npc_show_sniper",
        "havoc_npc_box", "havoc_npc_name", "havoc_npc_distance", "havoc_npc_held_item", "havoc_npc_npc_type",
        "havoc_npc_health_bar", "havoc_npc_health_text", "havoc_npc_chams", "havoc_npc_skeleton",
        "havoc_npc_hide_dead", "havoc_npc_rainbow", "havoc_npc_max_distance",
        P_NPC .. "_mode",
    })
    menu_util.bind_children("havoc_npc_box", { "havoc_npc_box_style", "havoc_npc_box_fill" })
    menu_util.bind_children("havoc_npc_name", { "havoc_npc_name_size" })
    menu_util.bind_children("havoc_npc_distance", { "havoc_npc_distance_size" })
    menu_util.bind_children("havoc_npc_held_item", { "havoc_npc_held_item_size" })
    menu_util.bind_children("havoc_npc_npc_type", { "havoc_npc_npc_type_size" })
    menu_util.bind_children("havoc_npc_health_text", { "havoc_npc_health_text_size" })
    menu_util.bind_children("havoc_npc_chams", { "havoc_npc_chams_style" })

    -- Row 2: Loot ESP | Trap ESP
    menu_util.register_keybind(TAB, G.LOOT, P_LOOT, "Enable Loot ESP", false)
    local loot_type_ids = register_loot_type_toggles(TAB, G.LOOT, P_LOOT)
    menu.add_checkbox(TAB, G.LOOT, "havoc_loot_box", "Loot Box", false,
        { parent = P_LOOT, colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, G.LOOT, "havoc_loot_box_style", "Loot Box Style",
        { "Corners", "Outline", "3D Box" }, 2, { parent = "havoc_loot_box" })
    menu.add_checkbox(TAB, G.LOOT, "havoc_loot_distance", "Loot Show Distance", false, { parent = P_LOOT })
    menu.add_combo(TAB, G.LOOT, "havoc_loot_distance_pos", "Loot Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_loot_distance" })
    menu.add_checkbox(TAB, G.LOOT, "havoc_loot_marker", "Loot Position Marker", false, { parent = P_LOOT })
    menu.add_combo(TAB, G.LOOT, "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = P_LOOT })
    menu.add_checkbox(TAB, G.LOOT, "havoc_loot_rainbow", "Loot Rainbow", false, { parent = P_LOOT })
    menu.add_slider_int(TAB, G.LOOT, "havoc_loot_max_distance", "Loot Max Distance", 0, 2000, 500, { parent = P_LOOT })
    menu.add_slider_int(TAB, G.LOOT, "havoc_loot_text_size", "Loot Text Size", 1, 15, 13, { parent = P_LOOT })

    menu_util.register_keybind(TAB, G.TRAP, P_TRAP, "Enable Trap ESP", false)
    local trap_type_ids = register_trap_type_toggles(TAB, G.TRAP, P_TRAP)
    menu.add_checkbox(TAB, G.TRAP, "havoc_trap_box", "Trap Box", false,
        { parent = P_TRAP, colorpicker = { 1.0, 0.35, 0.25, 1.0 } })
    menu.add_combo(TAB, G.TRAP, "havoc_trap_box_style", "Trap Box Style",
        { "Corners", "Outline", "3D Box" }, 2, { parent = "havoc_trap_box" })
    menu.add_checkbox(TAB, G.TRAP, "havoc_trap_distance", "Trap Show Distance", false, { parent = P_TRAP })
    menu.add_combo(TAB, G.TRAP, "havoc_trap_distance_pos", "Trap Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_trap_distance" })
    menu.add_checkbox(TAB, G.TRAP, "havoc_trap_marker", "Trap Position Marker", false, { parent = P_TRAP })
    menu.add_checkbox(TAB, G.TRAP, "havoc_trap_rainbow", "Trap Rainbow", false, { parent = P_TRAP })
    menu.add_slider_int(TAB, G.TRAP, "havoc_trap_max_distance", "Trap Max Distance", 0, 2000, 500, { parent = P_TRAP })
    menu.add_slider_int(TAB, G.TRAP, "havoc_trap_text_size", "Trap Text Size", 1, 15, 13, { parent = P_TRAP })

    local loot_children = {
        "havoc_loot_box", "havoc_loot_distance", "havoc_loot_marker",
        "havoc_loot_filter", "havoc_loot_rainbow", "havoc_loot_max_distance", "havoc_loot_text_size",
        P_LOOT .. "_mode",
    }
    for i = 1, #loot_type_ids do
        loot_children[#loot_children + 1] = loot_type_ids[i]
    end
    menu_util.bind_children(P_LOOT, loot_children)
    menu_util.bind_children("havoc_loot_box", { "havoc_loot_box_style" })
    menu_util.bind_children("havoc_loot_distance", { "havoc_loot_distance_pos" })

    local trap_children = {
        "havoc_trap_box", "havoc_trap_distance", "havoc_trap_marker",
        "havoc_trap_rainbow", "havoc_trap_max_distance", "havoc_trap_text_size",
        P_TRAP .. "_mode",
    }
    for i = 1, #trap_type_ids do
        trap_children[#trap_children + 1] = trap_type_ids[i]
    end
    menu_util.bind_children(P_TRAP, trap_children)
    menu_util.bind_children("havoc_trap_box", { "havoc_trap_box_style" })
    menu_util.bind_children("havoc_trap_distance", { "havoc_trap_distance_pos" })

    -- Row 3: World Visuals | Config
    menu.add_checkbox(TAB, G.WORLD, "havoc_target_gear", "Target Gear Viewer", false)
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_fov", "Target Gear FOV", 40, 400, 150,
        { parent = "havoc_target_gear" })
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_gear_size", "Gear Icon Size", 32, 64, 48,
        { parent = "havoc_target_gear" })
    menu.add_slider_int(TAB, G.WORLD, "havoc_target_gear_top", "Top Offset", 48, 160, 88,
        { parent = "havoc_target_gear" })

    menu_util.bind_children("havoc_target_gear", {
        "havoc_target_gear_fov", "havoc_target_gear_gear_size", "havoc_target_gear_top",
    })

    menu_util.sync_masters()
    menu_util.seed_color_defaults()
end

return M
