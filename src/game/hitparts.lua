local M = {}

M.DEFAULT_BONE_INDEX = 1

M.LABELS = {
    "Closest",
    "Head",
    "UpperTorso",
    "LowerTorso",
    "HumanoidRootPart",
    "Torso",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand",
    "LeftUpperLeg",
    "RightUpperLeg",
    "LeftLowerLeg",
    "RightLowerLeg",
    "LeftFoot",
    "RightFoot",
    "Left Arm",
    "Right Arm",
    "Left Leg",
    "Right Leg",
}

M.MAP = {
    ["Head"] = { "Head" },
    ["UpperTorso"] = { "UpperTorso", "Torso" },
    ["LowerTorso"] = { "LowerTorso", "Torso" },
    ["HumanoidRootPart"] = { "HumanoidRootPart", "Torso", "UpperTorso" },
    ["Torso"] = { "Torso", "UpperTorso" },
    ["LeftUpperArm"] = { "LeftUpperArm", "Left Arm" },
    ["RightUpperArm"] = { "RightUpperArm", "Right Arm" },
    ["LeftLowerArm"] = { "LeftLowerArm", "Left Arm" },
    ["RightLowerArm"] = { "RightLowerArm", "Right Arm" },
    ["LeftHand"] = { "LeftHand", "Left Arm" },
    ["RightHand"] = { "RightHand", "Right Arm" },
    ["LeftUpperLeg"] = { "LeftUpperLeg", "Left Leg" },
    ["RightUpperLeg"] = { "RightUpperLeg", "Right Leg" },
    ["LeftLowerLeg"] = { "LeftLowerLeg", "Left Leg" },
    ["RightLowerLeg"] = { "RightLowerLeg", "Right Leg" },
    ["LeftFoot"] = { "LeftFoot", "Left Leg" },
    ["RightFoot"] = { "RightFoot", "Right Leg" },
    ["Left Arm"] = { "Left Arm", "LeftUpperArm", "LeftLowerArm" },
    ["Right Arm"] = { "Right Arm", "RightUpperArm", "RightLowerArm" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg" },
}

function M.label_from_index(idx)
    idx = tonumber(idx)
    if idx == nil then idx = M.DEFAULT_BONE_INDEX end
    return M.LABELS[idx + 1] or "Head"
end

function M.candidate_names(label)
    if label == "Closest" then
        return nil
    end
    return M.MAP[label] or { label }
end

function M.all_part_names()
    local out = {}
    for i = 2, #M.LABELS do
        local names = M.MAP[M.LABELS[i]]
        if names then
            for j = 1, #names do
                out[#out + 1] = names[j]
            end
        end
    end
    return out
end

return M
