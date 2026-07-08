--[[
    bypass.lua — Volt-safe teleport helper.

    Loads hotkeys immediately. Teleport guard installs AFTER the game finishes
    loading (delayed) and uses hookfunction on TeleportService only — no
    hookmetamethod, no getconnections, no heartbeat loops.

    If Volt still crashes, set ENABLE_GUARD = false at the top (F1/F2 only).
]]

if rawget(_G, "__july_bypass_loaded") then
    return
end
rawset(_G, "__july_bypass_loaded", true)

local ENABLE_GUARD = true
local GUARD_DELAY_SECONDS = 12

local PLACE_MAIN = 13927562399
local PLACE_HAVOC = 16530963934

local ALLOWED_PLACES = {
    [PLACE_MAIN] = true,
    [PLACE_HAVOC] = true,
    [116219682389763] = true,
    [84097267761690] = true,
}

local BLOCK_SERVER_HOPS = true
local FORCE_TP_COOLDOWN = 2.0
local FORCE_GRACE_SECONDS = 8

local user_force_tp = false
local force_tp_until = 0
local last_force_tp = 0
local guard_installed = false

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local function now()
    if tick then return tick() end
    if os and os.clock then return os.clock() end
    return 0
end

local function get_local_player()
    return Players.LocalPlayer
end

local function allowed_place(place_id)
    place_id = tonumber(place_id)
    return place_id ~= nil and ALLOWED_PLACES[place_id] == true
end

local function force_tp_active()
    return user_force_tp and now() < force_tp_until
end

local function block(reason)
    warn("[bypass] " .. reason)
end

local function begin_force_grace()
    user_force_tp = true
    force_tp_until = now() + FORCE_GRACE_SECONDS
end

local function should_block(method, place_id, extra)
    place_id = tonumber(place_id)

    if force_tp_active() and allowed_place(place_id) then
        if method == "Teleport" or method == "TeleportAsync" then
            return false
        end
    end

    if method == "TeleportToPlaceInstance" and BLOCK_SERVER_HOPS then
        block(("blocked server hop (place %s%s)"):format(
            tostring(place_id),
            extra and (", " .. extra) or ""
        ))
        return true
    end

    if not allowed_place(place_id) then
        block(("blocked %s -> place %s%s"):format(
            method,
            tostring(place_id),
            extra and (", " .. extra) or ""
        ))
        return true
    end

    return false
end

local function wrap_teleport_method(method_name, pick_place_id, pick_extra)
    local original = TeleportService[method_name]
    if type(original) ~= "function" then
        return false
    end

    local old_fn
    local ok, err = pcall(function()
        old_fn = hookfunction(original, function(self, ...)
            local args = { ... }
            local place_id = pick_place_id(args)
            local extra = pick_extra and pick_extra(args) or nil
            if should_block(method_name, place_id, extra) then
                return nil
            end
            return old_fn(self, ...)
        end)
    end)

    if not ok then
        warn("[bypass] failed to hook " .. method_name .. ": " .. tostring(err))
        return false
    end

    return true
end

local function try_install_guard()
    if guard_installed or not ENABLE_GUARD then
        return
    end
    if not hookfunction then
        warn("[bypass] hookfunction unavailable — guard skipped")
        return
    end

    local count = 0
    if wrap_teleport_method("Teleport", function(args) return args[1] end) then
        count = count + 1
    end
    if wrap_teleport_method("TeleportAsync", function(args) return args[1] end) then
        count = count + 1
    end
    if wrap_teleport_method("TeleportToPlaceInstance", function(args) return args[1] end, function(args)
        return "instance " .. tostring(args[2])
    end) then
        count = count + 1
    end

    guard_installed = count > 0
    if guard_installed then
        print("[bypass] guard installed on " .. count .. " TeleportService method(s)")
    else
        warn("[bypass] guard not installed — F1/F2 still work")
    end
end

local function force_teleport(place_id, label)
    local lp = get_local_player()
    if not lp then
        warn("[bypass] LocalPlayer not ready")
        return
    end
    if not allowed_place(place_id) then
        return
    end

    local t = now()
    if t - last_force_tp < FORCE_TP_COOLDOWN then
        return
    end
    last_force_tp = t

    begin_force_grace()
    print(("[bypass] force teleport -> %s (%s)"):format(label, tostring(place_id)))

    local ok, err = pcall(function()
        TeleportService:Teleport(place_id, lp)
    end)

    if not ok then
        user_force_tp = false
        force_tp_until = 0
        warn("[bypass] force teleport failed: " .. tostring(err))
    end
end

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode == Enum.KeyCode.F1 then
        force_teleport(PLACE_MAIN, "main game")
    elseif input.KeyCode == Enum.KeyCode.F2 then
        force_teleport(PLACE_HAVOC, "Havoc")
    end
end)

local function schedule_guard()
    if not ENABLE_GUARD then
        print("[bypass] hotkeys ready — F1: main, F2: Havoc (guard disabled)")
        return
    end

    local function run_guard()
        pcall(try_install_guard)
    end

    if spawn and wait then
        spawn(function()
            wait(GUARD_DELAY_SECONDS)
            run_guard()
        end)
        print("[bypass] hotkeys ready — guard installs in " .. GUARD_DELAY_SECONDS .. "s")
    else
        run_guard()
        print("[bypass] hotkeys ready — F1: main, F2: Havoc")
    end
end

schedule_guard()
