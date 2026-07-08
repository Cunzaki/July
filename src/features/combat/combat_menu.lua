local M = {}

local hitparts = July.require("game.hitparts")

M.SILENT_BONES = hitparts.LABELS
M.BONE_MAP = hitparts.MAP

function M.bone_from_index(idx)
    return hitparts.label_from_index(idx)
end

return M
