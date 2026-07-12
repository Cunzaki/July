local M = {}

local hitparts = July.require("game.hitparts")

M.BONE_LABELS = hitparts.LABELS
M.BONE_MAP = hitparts.MAP

function M.bone_from_index(idx)
    return hitparts.label_from_index(idx)
end

return M
