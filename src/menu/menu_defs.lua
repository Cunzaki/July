local constants = July.require("core.constants")
local loot_catalog = July.require("game.loot_catalog")

local M = {}
M.TAB = constants.TAB

function M.register_all()
    if M._registered then return end
    M._registered = true

    local TAB = M.TAB

    menu.AddTab(TAB, "J", "full")

    menu.AddGroup(TAB, "Aimbot", -1)

    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_enabled", "Enable NPC Aimbot", false, { key = 2, show_mode = false })
    menu.AddCombo(TAB, "Aimbot", "havoc_aimbot_bone", "Aimbot Bone", { "Head", "Torso" }, 0, { parent = "havoc_aimbot_enabled" })
    menu.AddCombo(TAB, "Aimbot", "havoc_aimbot_target_type", "Aimbot Target Type", { "Closest To Crosshair", "Closest Distance" }, 0,
        { parent = "havoc_aimbot_enabled" })

    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_draw_fov", "Field Of View Circle", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_fill_fov", "Fill FOV", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 1.0, 1.0, 0.15 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_target_line", "Target Line", false,
        { parent = "havoc_aimbot_enabled", colorpicker = { 1.0, 0.3, 0.3, 1.0 } })
    menu.AddCheckbox(TAB, "Aimbot", "havoc_aimbot_rainbow", "Rainbow Colors", false,
        { parent = "havoc_aimbot_enabled" })

    menu.AddGroup(TAB, "NPC Visuals")

    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_enabled", "Enable NPC Visuals", false)
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_box", "Enable NPC Box", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCombo(TAB, "NPC Visuals", "havoc_npc_box_style", "Box Style",
        { "Corners", "Outline", "3D Box" }, 0, { parent = "havoc_npc_box" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_box_fill", "Fill Box", false,
        { parent = "havoc_npc_box", colorpicker = { 1.0, 1.0, 1.0, 0.35 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_name", "Enable NPC Name", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.92, 0.92, 0.92, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_distance", "Enable NPC Distance", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.67, 0.67, 0.67, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_held_item", "Enable Held Item", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.85, 0.4, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_npc_type", "Show NPC Type Tag", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.5, 0.0, 0.85 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_health_bar", "Enable NPC Health Bar", false, { parent = "havoc_npc_enabled" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_health_text", "Enable NPC Health Text", false,
        { parent = "havoc_npc_enabled", colorpicker = { 0.3, 1.0, 0.4, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_chams", "Enable NPC Chams", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 0.2, 0.2, 0.55 } })
    menu.AddCombo(TAB, "NPC Visuals", "havoc_npc_chams_style", "Chams Style",
        { "Filled", "Wireframe" }, 0, { parent = "havoc_npc_chams" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_skeleton", "Enable NPC Skeleton", false,
        { parent = "havoc_npc_enabled", colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_hide_dead", "Hide Dead NPCs", false, { parent = "havoc_npc_enabled" })
    menu.AddCheckbox(TAB, "NPC Visuals", "havoc_npc_rainbow", "Rainbow Colors", false,
        { parent = "havoc_npc_enabled" })

    menu.AddGroup(TAB, "Weapon Mods", 0, true)

    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_recoil", "Enable No Recoil", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_spread", "Enable No Spread", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_no_sway", "Enable No Sway", false)
    menu.AddCheckbox(TAB, "Weapon Mods", "havoc_fast_vel", "Enable Fast Bullet Velocity", false)

    menu.AddGroup(TAB, "Trap Visuals")

    menu.AddCheckbox(TAB, "Trap Visuals", "havoc_trap_enabled", "Enable Trap Visuals", false, { colorpicker = { 1.0, 0.2, 0.0, 1.0 } })
    menu.AddCheckbox(TAB, "Trap Visuals", "havoc_trap_rainbow", "Rainbow Colors", false,
        { parent = "havoc_trap_enabled" })

    menu.AddGroup(TAB, "Sliders", 0, true)

    menu.AddSliderInt(TAB, "Sliders", "havoc_aimbot_fov", "Aimbot Field Of View", 10, 500, 150)
    menu.AddSliderInt(TAB, "Sliders", "havoc_aimbot_max_distance", "Aimbot Max Distance", 0, 3000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_max_distance", "NPC Max Render Distance", 0, 3000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_trap_max_distance", "Trap Max Render Distance", 0, 5000, 3000)
    menu.AddSliderInt(TAB, "Sliders", "havoc_loot_max_distance", "Loot Max Render Distance", 0, 5000, 5000)
    menu.AddSeparator(TAB, "Sliders")
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_name_size", "NPC Name Text Size", 6, 24, 13)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_health_text_size", "NPC Health Text Size", 6, 18, 8)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_held_item_size", "NPC Weapon Text Size", 6, 18, 10)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_distance_size", "NPC Distance Text Size", 6, 18, 10)
    menu.AddSliderInt(TAB, "Sliders", "havoc_npc_npc_type_size", "NPC Type Tag Text Size", 6, 18, 9)
    menu.AddSliderInt(TAB, "Sliders", "havoc_loot_text_size", "Loot Text Size", 1, 15, 13)
    menu.AddSliderInt(TAB, "Sliders", "havoc_trap_text_size", "Trap Text Size", 6, 18, 13)

    menu.AddGroup(TAB, "Loot Visuals", -1)

    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_enabled", "Enable Loot Visuals", false, { colorpicker = { 1.0, 1.0, 1.0, 1.0 } })
    for i = 1, #loot_catalog.LOOT_TYPES do
        local entry = loot_catalog.LOOT_TYPES[i]
        menu.AddCheckbox(TAB, "Loot Visuals", entry.key, "Enable " .. entry.display .. " Visuals", false,
            { parent = "havoc_loot_enabled" })
    end
    menu.AddCheckbox(TAB, "Loot Visuals", loot_catalog.LOOT_FALLBACK.key, "Enable " .. loot_catalog.LOOT_FALLBACK.display .. " Visuals", false,
        { parent = "havoc_loot_enabled" })
    menu.AddCheckbox(TAB, "Loot Visuals", loot_catalog.BODY_BAG_TYPE.key, "Enable " .. loot_catalog.BODY_BAG_TYPE.display .. " Visuals", false,
        { parent = "havoc_loot_enabled" })

    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_distance", "Show Distance", false, { parent = "havoc_loot_enabled" })
    menu.AddCombo(TAB, "Loot Visuals", "havoc_loot_distance_pos", "Distance Position",
        { "Same Line", "Below Name", "Left Of Name", "Right Of Name" }, 0,
        { parent = "havoc_loot_distance" })
    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_marker", "Show Position Marker", false,
        { parent = "havoc_loot_enabled" })
    menu.AddCombo(TAB, "Loot Visuals", "havoc_loot_filter", "Loot Filter",
        { "Show All", "Show Locked Only", "Show Unlocked Only", "Show Opened Only", "Show Unopened Only" }, 0,
        { parent = "havoc_loot_enabled" })
    menu.AddCheckbox(TAB, "Loot Visuals", "havoc_loot_rainbow", "Rainbow Colors", false,
        { parent = "havoc_loot_enabled" })

    menu.AddGroup(TAB, "Config", -1)
end

return M
