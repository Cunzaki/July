local M = {}

M.SILENT_BONES = {
    "Head",
    "Torso",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
    "Closest",
}

M.BONE_MAP = {
    ["Head"] = "Head",
    ["Torso"] = "UpperTorso",
    ["Left Arm"] = "LeftUpperArm",
    ["Right Arm"] = "RightUpperArm",
    ["Left Leg"] = "LeftUpperLeg",
    ["Right Leg"] = "RightUpperLeg",
    ["Closest"] = "Closest",
}

function M.register_silent_aim(TAB, GROUP, prefix, parent_id)
    local root = { parent = parent_id }

    menu.add_combo(TAB, GROUP, prefix .. "target_type", "Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(TAB, GROUP, prefix .. "bone", "Target Hitbox", M.SILENT_BONES, 0, root)

    menu.add_separator(TAB, GROUP)
    menu.add_label(TAB, GROUP, "Filters")
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_health", "Health Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_visible", "Visible Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_team", "Team Check", true, root)

    menu.add_separator(TAB, GROUP)
    menu.add_label(TAB, GROUP, "Targets")
    menu.add_checkbox(TAB, GROUP, prefix .. "target_players", "Target Players", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npcs", "Target NPCs", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_soldiers", "NPC Soldiers", true, { parent = prefix .. "target_npcs" })
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_bosses", "NPC Bosses", true, { parent = prefix .. "target_npcs" })

    menu.add_separator(TAB, GROUP)
    menu.add_slider_int(TAB, GROUP, prefix .. "max_dist", "Max Distance (m)", 50, 2000, 500, root)
    menu.add_slider_int(TAB, GROUP, prefix .. "fov", "FOV Radius (px)", 20, 600, 150, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "sticky", "Sticky Target", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "wallbang", "Wallbang", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_tp", "Bullet TP", false, root)
    menu.add_combo(TAB, GROUP, prefix .. "tp_ray_mode", "TP Ray Mode", { "Direct", "Snap", "Deep" }, 0, { parent = prefix .. "bullet_tp" })
    menu.add_checkbox(TAB, GROUP, prefix .. "tp_ray_vis", "Visualize Ray Path", false, {
        parent = prefix .. "bullet_tp",
        colorpicker = { 0.95, 0.45, 1.0, 0.9 },
    })
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_manip", "Bullet Manipulation", false, root)
    menu.add_slider_float(TAB, GROUP, prefix .. "manip_dist", "Manip Distance", 0.1, 1.0, 1.0, "%.2f", { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_status", "Manip Status Bar", false, { parent = prefix .. "bullet_manip" })
end

return M
