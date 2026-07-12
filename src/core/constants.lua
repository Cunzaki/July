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
M.ENTITY_LIVE_BATCH_SIZE = 24
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
M.DROP_SCAN_INTERVAL = 2.0
M.DROP_LIVE_BATCH = 24
M.TRAP_LIVE_BATCH = 16

M.TRAP_SCAN_DEPTH = 8
M.TRAP_SCAN_INTERVAL = 5.0

M.AIMBOT_ACQUIRE_INTERVAL = 0.05
M.AIMBOT_TICK_INTERVAL = 1

M.LOOT_MARKER_RADIUS = 3
M.LOOT_MARKER_GAP = 8

M.ESP_HIDE_SQ = 9
M.ESP_RENDER_BUDGET = 80
M.ESP_POS_CACHE_MS = 750
M.ESP_POS_CACHE_COMBAT_MS = 200

M.SKELETON_OUTLINE_COLOR = { 0, 0, 0, 0.78 }

M.NPC_BOSS_NAMES = {
    Anvil = true, Boris = true, Breaker = true, Bruno = true, Brutus = true,
    Bullet = true, Cervus = true, Charger = true, Checkmate = true, Cipher = true,
    Clutch = true, Cobra = true, Crossfire = true, Dagger = true, Falcon = true,
    Fox = true, Ghost = true, Grizzly = true, Gunner = true, Hawk = true,
    Ironclad = true, Kingslayer = true, Knox = true, Kodiak = true, Lockstep = true,
    Lynx = true, Mamba = true, Maverick = true, Omen = true, Phantom = true,
    Phoenix = true, Queensguard = true, Ranger = true, Raptor = true, Scorch = true,
    Shade = true, Spartan = true, Stalemate = true, Tagilla = true, Talon = true,
    Vandal = true, Volt = true, Warlock = true, Wolf = true, Zero = true,
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
