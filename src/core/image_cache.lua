local asset_urls = July.require("game.asset_urls")

local M = {}

local keys = {}

local function rbx_asset_url(asset_id)
    local id = tostring(asset_id or ""):match("(%d+)")
    if not id or id == "0" then return nil end
    return "rbxassetid://" .. id
end

local function url_for(asset_id_or_url)
    if type(asset_id_or_url) == "string" and asset_id_or_url:find("://", 1, true) then
        return asset_id_or_url
    end
    local asset_id = type(asset_id_or_url) == "number" and tostring(asset_id_or_url)
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    if not asset_id or asset_id == "0" then return nil end
    return asset_urls.decal_url(asset_id)
        or asset_urls.item_png(asset_id)
        or rbx_asset_url(asset_id)
        or asset_urls.roblox_thumb(asset_id)
        or asset_urls.roblox_thumb_legacy(asset_id)
        or asset_urls.asset_delivery(asset_id)
        or asset_urls.roblox_asset(asset_id)
end

function M.ensure(key, asset_id_or_url)
    if keys[key] then return keys[key] end
    local asset_id = type(asset_id_or_url) == "number" and tostring(asset_id_or_url)
        or (type(asset_id_or_url) == "string" and asset_id_or_url:match("^(%d+)$"))
    if asset_id == "0" then return nil end
    local url = url_for(asset_id_or_url)
    if not url then return nil end
    keys[key] = {
        url = url,
        asset_id = asset_id,
        handle = nil,
        failed = false,
        fallback = 0,
    }
    return keys[key]
end

local FALLBACKS = {
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.decal_url(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.item_png(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return rbx_asset_url(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.roblox_thumb(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.roblox_thumb_legacy(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.asset_delivery(entry.asset_id)
    end,
    function(entry)
        if not entry.asset_id then return nil end
        return asset_urls.roblox_asset(entry.asset_id)
    end,
}

local function free_entry_handle(entry)
    if entry.handle and draw and draw.free_image then
        pcall(function() draw.free_image(entry.handle) end)
    end
    entry.handle = nil
end

local function try_fallback(entry)
    if not entry.asset_id then return false end
    entry.fallback = (entry.fallback or 0) + 1
    local fn = FALLBACKS[entry.fallback]
    if not fn then return false end
    local fb = fn(entry)
    if not fb or fb == entry.url then
        return try_fallback(entry)
    end
    free_entry_handle(entry)
    entry.url = fb
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
        free_entry_handle(entry)
        return nil
    end

    if draw.image_loaded and not draw.image_loaded(entry.handle) then
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

function M.state(key)
    local entry = keys[key]
    if not entry then return "none" end
    if entry.failed then return "failed" end
    if not entry.handle then return "loading" end
    if draw and draw.image_failed and draw.image_failed(entry.handle) then
        if try_fallback(entry) then
            return "loading"
        end
        entry.failed = true
        free_entry_handle(entry)
        return "failed"
    end
    if draw and draw.image_loaded and not draw.image_loaded(entry.handle) then
        return "loading"
    end
    return "ready"
end

function M.is_ready(key)
    return M.state(key) == "ready"
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

function M.preload_asset(asset_id)
    if not asset_id then return end
    local key = "item_" .. tostring(asset_id)
    M.ensure(key, asset_id)
    M.begin_load(key)
end

return M
