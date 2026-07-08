local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")

local M = {}
M.TAB = constants.TAB

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB
    local P_AIM = "havoc_aimbot_enabled"
    local P_SILENT = "july_silent_aim"

    menu.add_tab(TAB, "J", "full")

    -- Row 1: Aimbot | Aim Visuals
    menu.add_group(TAB, "Aimbot", 0)
    menu.add_checkbox(TAB, "Aimbot", P_AIM, "Enable Aimbot", false, { key = 2, show_mode = false })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_bone", "Target Bone", { "Head", "Torso", "Closest" }, 0, { parent = P_AIM })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_target_type", "Priority", { "Crosshair", "Distance" }, 0, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_fov", "FOV Radius", 10, 500, 150, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_max_distance", "Max Distance", 0, 3000, 3000, { parent = P_AIM })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_smooth", "Smoothness", 1, 100, 8, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_sticky", "Sticky Target", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_target_players", "Target Players", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_target_npcs", "Target NPCs", true, { parent = P_AIM })
    menu.add_separator(TAB, "Aimbot")
    menu.add_checkbox(TAB, "Aimbot", P_SILENT, "Enable Silent Aim", false, { parent = P_AIM })

    menu.add_group(TAB, "Aim Visuals", 0, true)
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_draw_fov", "Aimbot FOV Circle", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_fill_fov", "Fill Aimbot FOV", false, {
        parent = P_AIM, colorpicker = { 1.0, 1.0, 1.0, 0.15 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_target_line", "Aimbot Target Line", false, {
        parent = P_AIM, colorpicker = { 1.0, 0.3, 0.3, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "havoc_aimbot_rainbow", "Aimbot Rainbow", false, { parent = P_AIM })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_draw_fov", "Silent FOV Circle", false, {
        parent = P_SILENT, colorpicker = { 0.55, 0.2, 1.0, 1.0 },
    })
    menu.add_combo(TAB, "Aim Visuals", "july_silent_fov_style", "Silent FOV Style", { "Outline", "Filled Circle" }, 1, { parent = P_SILENT })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_target_line", "Silent Target Line", false, {
        parent = P_SILENT, colorpicker = { 1.0, 0.25, 0.25, 1.0 },
    })
    menu.add_checkbox(TAB, "Aim Visuals", "july_silent_rainbow", "Silent Rainbow", false, { parent = P_SILENT })

    -- Row 2: Silent Options | NPC Visuals
    menu.add_group(TAB, "Silent Options", 0)
    July.require("features.combat.combat_menu").register_silent_aim(TAB, "Silent Options", "july_silent_", P_SILENT)

    menu.add_group(TAB, "NPC Visuals", 0, true)
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_enabled", "Enable NPC Visuals", false)
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_box", "Box", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_box_style", "Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_box_fill", "Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_name", "Name", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_distance", "Distance", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_held_item", "Held Item", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_npc_type", "Type Tag", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_health_bar", "Health Bar", false, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_health_text", "Health Text", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_chams", "Chams", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_chams_style", "Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_skeleton", "Skeleton", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_hide_dead", "Hide Dead", false, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_rainbow", "Rainbow", false, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_max_distance", "Max Distance", 0, 3000, 3000, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_name_size", "Name Size", 6, 24, 13, { parent = "havoc_npc_name" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_health_text_size", "Health Text Size", 6, 18, 8, { parent = "havoc_npc_health_text" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_held_item_size", "Weapon Text Size", 6, 18, 10, { parent = "havoc_npc_held_item" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_distance_size", "Distance Text Size", 6, 18, 10, { parent = "havoc_npc_distance" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_npc_type_size", "Type Tag Size", 6, 18, 9, { parent = "havoc_npc_npc_type" })

    -- Row 3: Loot | Traps
    menu.add_group(TAB, "Loot Visuals", 0)
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_enabled", "Enable Loot Visuals", false)
    menu.add_multicombo(TAB, "Loot Visuals", "havoc_loot_types", "Loot Types",
        loot_catalog.MULTICOMBO_LABELS, loot_catalog.MULTICOMBO_DEFAULTS, { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_distance", "Show Distance", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_distance_pos", "Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_loot_distance" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_marker", "Position Marker", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_rainbow", "Rainbow", false, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_max_distance", "Max Distance", 0, 5000, 5000, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_text_size", "Text Size", 1, 15, 13, { parent = "havoc_loot_enabled" })

    menu.add_group(TAB, "Trap Visuals", 0, true)
    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_enabled", "Enable Trap Visuals", false)
    menu.add_multicombo(TAB, "Trap Visuals", "havoc_trap_types", "Trap Types",
        trap_types.MULTICOMBO_LABELS, trap_types.MULTICOMBO_DEFAULTS, { parent = "havoc_trap_enabled" })
    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_rainbow", "Rainbow", false, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_max_distance", "Max Distance", 0, 5000, 3000, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_text_size", "Text Size", 6, 18, 13, { parent = "havoc_trap_enabled" })

    -- Row 4: Weapon Mods | Config
    menu.add_group(TAB, "Weapon Mods", 0)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_recoil", "No Recoil", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_spread", "No Spread", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_no_sway", "No Sway", false)
    menu.add_checkbox(TAB, "Weapon Mods", "havoc_fast_vel", "Fast Bullet Velocity", false)

    menu.add_group(TAB, "Config", 0, true)
end

return M
