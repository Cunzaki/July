local env = July.require("core.env")
local cache = July.require("core.cache")

local M = {}

M._ready = false
M._last_char_key = nil
M._last_folder_name = nil
M._icons_warmed = false

local function char_key(lp)
    if not lp then return nil end
    local char = lp.Character or lp.character
    if not char then return nil end
    if not env.is_valid(char) then return nil end
    local addr = char.Address or char.address
    if addr then return tostring(addr) end
    return tostring(char)
end

function M.invalidate_all()
    cache.reset()
    M._icons_warmed = false

    July.require("game.havoc_sync").reset()
    July.require("game.havoc_icons").reset()
    July.require("game.entity_scan").invalidate()
    July.require("game.loot_scan").invalidate()
    July.require("game.trap_scan").invalidate()
    July.require("features.combat.aimbot").reset()
    July.require("game.combat_origin").invalidate()
end

local function warm_item_icons()
    if M._icons_warmed then return end
    M._icons_warmed = true

    pcall(function()
        July.require("game.havoc_icons").warm()
    end)

    pcall(function()
        local image_cache = July.require("core.image_cache")
        local warmed = {}

        local function warm_catalog(mod_name, limit)
            local catalog = July.require(mod_name)
            if not catalog or not catalog.get_asset_id then return 0 end
            local by_name = catalog.by_name
            if not by_name then return 0 end
            local count = 0
            for name, _ in pairs(by_name) do
                local id = catalog.get_asset_id(name)
                if id and not warmed[id] then
                    warmed[id] = true
                    image_cache.preload_asset(id)
                    count = count + 1
                    if count >= limit then break end
                end
            end
            return count
        end

        warm_catalog("game.havoc_item_catalog", 256)
        warm_catalog("game.item_images", 256)
    end)
end

function M.tick()
    local lp = env.get_local_player()
    local char_key = char_key(lp)
    local folder_name = July.require("game.havoc_sync").get_folder_name()

    if M._ready then
        local changed = false
        if char_key ~= M._last_char_key then
            changed = true
        end
        if folder_name and M._last_folder_name and folder_name ~= M._last_folder_name then
            changed = true
        end
        if changed then
            M.invalidate_all()
        end
    end

    if char_key then
        M._ready = true
        M._last_char_key = char_key
        warm_item_icons()
    end
    if folder_name then
        M._last_folder_name = folder_name
    end
end

return M
