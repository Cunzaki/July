local M = {}

function M.apply()
    local patches = {
        { id = "havoc_no_recoil", patch = { vPunchBase = 0, hPunchBase = 0 } },
        { id = "havoc_no_spread", patch = { spreadReduce = 100 } },
        { id = "havoc_no_sway", patch = { weight = 0, aimWeight = 0, unAimWeight = 0 } },
        { id = "havoc_fast_vel", patch = { vel = 100000 } },
    }
    for i = 1, #patches do
        if menu.Get(patches[i].id) then
            pcall(applygc, patches[i].patch)
        end
    end
end

return M
