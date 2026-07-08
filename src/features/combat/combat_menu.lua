local M = {}

local hitparts = July.require("game.hitparts")

M.SILENT_BONES = hitparts.LABELS
M.BONE_MAP = hitparts.MAP

function M.bone_from_index(idx)
    return hitparts.label_from_index(idx)
end

function M.register_silent_aim(TAB, GROUP, prefix, parent_id)
    local root = { parent = parent_id }

    menu.add_combo(TAB, GROUP, prefix .. "target_type", "Silent Target Type", { "Crosshair", "Distance" }, 0, root)
    menu.add_combo(TAB, GROUP, prefix .. "bone", "Silent Target Hitbox", M.SILENT_BONES, 1, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_health", "Silent Health Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_visible", "Silent Visible Only", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "filter_team", "Silent Team Check", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_players", "Silent Target Players", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npcs", "Silent Target NPCs", true, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_soldiers", "Silent Soldier Targets", true, { parent = prefix .. "target_npcs" })
    menu.add_checkbox(TAB, GROUP, prefix .. "target_npc_bosses", "Silent Boss Targets", true, { parent = prefix .. "target_npcs" })
    menu.add_slider_int(TAB, GROUP, prefix .. "max_dist", "Silent Max Distance", 50, 3000, 2000, root)
    menu.add_slider_int(TAB, GROUP, prefix .. "fov", "Silent FOV Radius", 20, 600, 150, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "sticky", "Silent Sticky Target", false, root)
    menu.add_checkbox(TAB, GROUP, prefix .. "bullet_manip", "Silent Bullet Manip", false, root)
    menu.add_slider_float(TAB, GROUP, prefix .. "manip_dist", "Silent Manip Distance", 0.1, 8.0, 1.0, "%.1f", { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_status", "Silent Manip Status", false, { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_ring", "Silent Manip Ring", false, { parent = prefix .. "bullet_manip" })
    menu.add_checkbox(TAB, GROUP, prefix .. "manip_peek_vis", "Silent Manip Peek", true, { parent = prefix .. "bullet_manip" })
end

return M
