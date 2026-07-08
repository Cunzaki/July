local M = {}

M.REPO = "Cunzaki/July"
M.BRANCH = "main"

function M.decal_url(asset_id)
    return string.format(
        "https://raw.githubusercontent.com/%s/refs/heads/%s/assets/decals/%s.png",
        M.REPO, M.BRANCH, tostring(asset_id)
    )
end

return M
