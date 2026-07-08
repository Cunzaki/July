local M = {}

function M.tick(co, budget_ms)
    if not co or coroutine.status(co) == "dead" then
        return true
    end

    budget_ms = budget_ms or 4
    local t0 = os.clock()

    while coroutine.status(co) ~= "dead" do
        local ok = coroutine.resume(co)
        if not ok then
            return true
        end
        if (os.clock() - t0) * 1000 >= budget_ms then
            return false
        end
    end

    return true
end

return M
