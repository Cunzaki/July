-- Prefer local bundle (dev); fall back to GitHub main.
local function load_local()
    if not readfile then return false end
    local paths = { "july.lua", "July/july.lua", "Vector Scripts/July/july.lua" }
    for i = 1, #paths do
        local src = readfile(paths[i])
        if src and src ~= "" then
            local chunk, err = loadstring(src, paths[i])
            if not chunk then
                print("[July] local load parse error: " .. tostring(err))
                return false
            end
            chunk()
            return true
        end
    end
    return false
end

if not load_local() then
    utility.load_url("https://raw.githubusercontent.com/Cunzaki/July/refs/heads/main/july.lua")
end
