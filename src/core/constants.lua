local M = {}

M.TAB = "July"
M.CONFIG_PATH = "C:/July_Config.txt"

M.TEXT_SIZE = 13
M.HEAD_OFFSET = 2.6
M.FOOT_OFFSET = 3.2

M.BOUNDS_UPDATE_INTERVAL = 3
M.SCAN_YIELD_EVERY = 24
M.SCAN_BUDGET_MS = 4
M.ENTITY_SCAN_INTERVAL = 1.0
M.ENTITY_LIVE_BATCH_SIZE = 20
M.NPC_BOUNDS_BATCH = 8
M.NPC_CHAMS_BUDGET = 6
M.FOLDER_POLL_INTERVAL = 0.25
M.PLAYER_MATCH_DIST = 5.0

M.LOOT_SCAN_INTERVAL = 30.0
M.LOOT_SCAN_DEPTH = 8
M.LOOT_LIVE_BATCH_SIZE = 24
M.LOOT_PRUNE_BATCH = 24
M.LOOT_COMPACT_INTERVAL = 8.0
M.LOOT_MAX_PARTS = 6
M.DROP_SCAN_DEPTH = 4
M.DROP_SCAN_INTERVAL = 3.5
M.TRAP_LIVE_BATCH = 16

M.TRAP_SCAN_DEPTH = 8
M.TRAP_SCAN_INTERVAL = 5.0

M.AIMBOT_ACQUIRE_INTERVAL = 0.05
M.AIMBOT_TICK_INTERVAL = 1

M.LOOT_MARKER_RADIUS = 3
M.LOOT_MARKER_GAP = 8

M.ESP_HIDE_SQ = 9
M.ESP_RENDER_BUDGET = 100
M.ESP_POS_CACHE_MS = 200
M.ESP_POS_CACHE_COMBAT_MS = 50

M.SKELETON_OUTLINE_COLOR = { 0, 0, 0, 0.78 }

M.NPC_BOSS_NAMES = {
    Boris = true, Bruno = true, Brutus = true, Tagilla = true,
    Ranger = true, Clutch = true, Kodiak = true, Vandal = true, Grizzly = true,
    Crossfire = true, Warlock = true, Stalemate = true, Lynx = true, Hawk = true,
    Talon = true, Volt = true, Dagger = true, Spartan = true, Cipher = true,
    Maverick = true, Falcon = true,
    Scorch = true, Raptor = true, Knox = true, Fox = true, Bullet = true,
    Zero = true, Cobra = true, Ghost = true, Shade = true, Checkmate = true,
    Mamba = true, Phoenix = true, Anvil = true, Gunner = true,
}

M.BONE_NAMES = {
    "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

M.SKELETON_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" }, { "RightUpperArm", "RightLowerArm" },
    { "LeftLowerArm", "LeftHand" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" }, { "RightUpperLeg", "RightLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "RightLowerLeg", "RightFoot" },
}

M.SKELETON_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

M.CORNER_SIGNS = {
    { -1, -1, -1 }, { -1, -1, 1 }, { -1, 1, -1 }, { -1, 1, 1 },
    { 1, -1, -1 }, { 1, -1, 1 }, { 1, 1, -1 }, { 1, 1, 1 },
}

return M
