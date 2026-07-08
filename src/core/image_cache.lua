local asset_urls = July.require("game.asset_urls")

local M = {}

local keys = {}

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" and asset_id_or_url:find("https://", 1, true) then
        return asset_id_or_url
    end
    return asset_urls.item_png(asset_id_or_url) or asset_urls.roblox_thumb(asset_id_or_url)
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    local asset_id = type(asset_id_or_url) == "number" and asset_id_or_url
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    keys[key] = {
        url = url,
        asset_id = asset_id and tostring(asset_id) or nil,
        handle = nil,
        failed = false,
        fallback = false,
    }
    return keys[key]
end

local function try_fallback(entry)
    if entry.fallback or not entry.asset_id then return false end
    local fb = asset_urls.roblox_thumb(entry.asset_id)
    if not fb or fb == entry.url then return false end
    entry.fallback = true
    entry.url = fb
    entry.handle = nil
    entry.failed = false
    return true
end

local function get_handle(key)
    local entry = keys[key]
    if not entry or entry.failed or not draw or not draw.load_image then
        return nil
    end

    if not entry.handle then
        entry.handle = draw.load_image(entry.url)
        return nil
    end

    if draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return nil
        end
        entry.failed = true
        entry.handle = nil
        return nil
    end

    return entry.handle
end

local function draw_image(handle, x, y, w, h, col)
    if col and type(col) == "table" then
        local r = math.floor((col[1] or 1) * 255)
        local g = math.floor((col[2] or 1) * 255)
        local b = math.floor((col[3] or 1) * 255)
        local a = math.floor((col[4] or 1) * 255)
        draw.image(handle, x, y, w, h, r, g, b, a)
    else
        draw.image(handle, x, y, w, h, 255, 255, 255, 255)
    end
end

function M.draw_fit(key, x, y, w, h, col)
    if not draw or not draw.image then return false end
    local handle = get_handle(key)
    if not handle then return false end
    w = math.max(w or 0, 8)
    h = math.max(h or 0, 8)
    draw_image(handle, x, y, w, h, col)
    return true
end

function M.begin_load(key)
    if not key then return end
    get_handle(key)
end

return M
