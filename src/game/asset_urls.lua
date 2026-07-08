local M = {}

M.REPO = "Cunzaki/July"
M.BRANCH = "main"
M.CDN_BASE = "https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/assets"

local function digits(id)
    return id and tostring(id):match("(%d+)")
end

function M.asset_delivery(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("https://assetdelivery.roblox.com/v1/asset?id=%s", asset_id)
end

function M.roblox_asset(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format("https://www.roblox.com/asset/?id=%s", asset_id)
end

function M.roblox_thumb(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/asset-thumbnail/image?assetId=%s&width=420&height=420&format=png",
        asset_id
    )
end

function M.roblox_thumb_legacy(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=%s",
        asset_id
    )
end

function M.item_png(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return M.CDN_BASE .. "/items/" .. asset_id .. ".png"
end

function M.decal_url(asset_id)
    asset_id = digits(asset_id)
    if not asset_id then return nil end
    return string.format(
        "https://raw.githubusercontent.com/%s/refs/heads/%s/assets/decals/%s.png",
        M.REPO, M.BRANCH, asset_id
    )
end

return M
