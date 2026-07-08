local M = {}

local seen_errors = {}

function M.enabled()
    return July and July.debug == true
end

function M.log(msg)
    if not M.enabled() then return end
    print("[July] " .. tostring(msg))
end

function M.error_once(key, err)
    key = tostring(key)
    if seen_errors[key] then return end
    seen_errors[key] = true
    print("[July ERROR][" .. key .. "] " .. tostring(err))
    if debug and debug.traceback then
        print(debug.traceback(err, 2))
    end
end

function M.guard(key, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        M.error_once(key, a)
        return nil
    end
    return a, b, c
end

function M.traceback(err, level)
    if debug and debug.traceback then
        return debug.traceback(err, level or 2)
    end
    return tostring(err)
end

function M.register_frame_hook(fn)
    if type(fn) ~= "function" then
        M.error_once("frame_hook", "on_frame handler is not a function")
        return false
    end

    _G.on_frame = fn

    if draw then
        draw.callback = nil
    end

    return true
end

return M
