local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")
local trap_types = July.require("game.trap_types")
local combat_menu = July.require("features.combat.combat_menu")

local M = {}
M.TAB = constants.TAB

M.NPC_DISPLAY_LABELS = {
    "Box", "Fill", "Name", "Distance", "Held Item", "Type Tag",
    "Health Bar", "Health Text", "Chams", "Skeleton",
}

M.NPC_DISPLAY_DEFAULTS = {
    false, false, false, false, false, false,
    false, false, false, false,
}

M.WEAPON_MOD_LABELS = { "No Recoil", "No Spread", "No Sway", "Fast Velocity" }
M.WEAPON_MOD_DEFAULTS = { false, false, false, false }

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB

    menu.add_tab(TAB, "J", "full")

    -- ── Combat: Aimbot ──
    menu.add_group(TAB, "Aimbot", -1)

    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_enabled", "Enable NPC Aimbot", false, { key = 2, show_mode = false })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_bone", "Aimbot Bone", { "Head", "Torso" }, 0, { parent = "havoc_aimbot_enabled" })
    menu.add_combo(TAB, "Aimbot", "havoc_aimbot_target_type", "Target Type", { "Closest To Crosshair", "Closest Distance" }, 0, { parent = "havoc_aimbot_enabled" })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_fov", "FOV Radius", 10, 500, 150, { parent = "havoc_aimbot_enabled" })
    menu.add_slider_int(TAB, "Aimbot", "havoc_aimbot_max_distance", "Max Distance", 0, 3000, 3000, { parent = "havoc_aimbot_enabled" })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_draw_fov", "FOV Circle", false, {
        parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 },
    })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_fill_fov", "Fill FOV", false, {
        parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 0.15 },
    })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_target_line", "Target Line", false, {
        parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 0.3, 0.3, 1.0 },
    })
    menu.add_checkbox(TAB, "Aimbot", "havoc_aimbot_rainbow", "Rainbow Colors", false, { parent = "havoc_aimbot_enabled" })

    -- ── Combat: Silent Aim ──
    menu.add_group(TAB, "Silent Aim", 0, true)

    menu.add_checkbox(TAB, "Silent Aim", "july_silent_aim", "Enable Silent Aim", false)
    combat_menu.register_silent_aim(TAB, "Silent Aim", "july_silent_", "july_silent_aim")
    menu.add_checkbox(TAB, "Silent Aim", "july_silent_rainbow", "Rainbow Colors", false, { parent = "july_silent_aim" })

    -- ── NPC Visuals ──
    menu.add_group(TAB, "NPC Visuals")

    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_enabled", "Enable NPC Visuals", false)
    menu.add_multicombo(TAB, "NPC Visuals", "havoc_npc_display", "Display Options", M.NPC_DISPLAY_LABELS, M.NPC_DISPLAY_DEFAULTS, { parent = "havoc_npc_enabled" })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_box_style", "Box Style", { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_enabled" })
    menu.add_combo(TAB, "NPC Visuals", "havoc_npc_chams_style", "Chams Style", { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_hide_dead", "Hide Dead NPCs", false, { parent = "havoc_npc_enabled" })
    menu.add_checkbox(TAB, "NPC Visuals", "havoc_npc_rainbow", "Rainbow Colors", false, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_max_distance", "Max Distance", 0, 3000, 3000, { parent = "havoc_npc_enabled" })
    menu.add_separator(TAB, "NPC Visuals")
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_name_size", "Name Size", 6, 24, 13, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_health_text_size", "Health Text Size", 6, 18, 8, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_held_item_size", "Weapon Text Size", 6, 18, 10, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_distance_size", "Distance Text Size", 6, 18, 10, { parent = "havoc_npc_enabled" })
    menu.add_slider_int(TAB, "NPC Visuals", "havoc_npc_npc_type_size", "Type Tag Size", 6, 18, 9, { parent = "havoc_npc_enabled" })

    -- ── Loot Visuals ──
    menu.add_group(TAB, "Loot Visuals", -1)

    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_enabled", "Enable Loot Visuals", false)
    menu.add_multicombo(TAB, "Loot Visuals", "havoc_loot_types", "Loot Types", loot_catalog.MULTICOMBO_LABELS, loot_catalog.MULTICOMBO_DEFAULTS, { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_distance", "Show Distance", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_distance_pos", "Distance Position", { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0, { parent = "havoc_loot_distance" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_marker", "Position Marker", false, { parent = "havoc_loot_enabled" })
    menu.add_combo(TAB, "Loot Visuals", "havoc_loot_filter", "Loot Filter", { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0, { parent = "havoc_loot_enabled" })
    menu.add_checkbox(TAB, "Loot Visuals", "havoc_loot_rainbow", "Rainbow Colors", false, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_max_distance", "Max Distance", 0, 5000, 5000, { parent = "havoc_loot_enabled" })
    menu.add_slider_int(TAB, "Loot Visuals", "havoc_loot_text_size", "Text Size", 1, 15, 13, { parent = "havoc_loot_enabled" })

    -- ── Trap Visuals ──
    menu.add_group(TAB, "Trap Visuals", 0, true)

    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_enabled", "Enable Trap Visuals", false)
    menu.add_multicombo(TAB, "Trap Visuals", "havoc_trap_types", "Trap Types", trap_types.MULTICOMBO_LABELS, trap_types.MULTICOMBO_DEFAULTS, { parent = "havoc_trap_enabled" })
    menu.add_checkbox(TAB, "Trap Visuals", "havoc_trap_rainbow", "Rainbow Colors", false, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_max_distance", "Max Distance", 0, 5000, 3000, { parent = "havoc_trap_enabled" })
    menu.add_slider_int(TAB, "Trap Visuals", "havoc_trap_text_size", "Text Size", 6, 18, 13, { parent = "havoc_trap_enabled" })

    -- ── Weapon Mods ──
    menu.add_group(TAB, "Weapon Mods", -1)

    menu.add_multicombo(TAB, "Weapon Mods", "havoc_weapon_mods", "Weapon Mods", M.WEAPON_MOD_LABELS, M.WEAPON_MOD_DEFAULTS)

    -- ── Config ──
    menu.add_group(TAB, "Config", -1)
end

return M
