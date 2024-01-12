return function()

--- Run callback once, can be used akin to a "on next <callback>"
-- Note: will run N times on next trigger if called N times before last 
-- call is used
---@param callbackId ModCallbacks
---@param func function
---@param param any?
function REVEL.CallbackOnce(callbackId, func, param)
    -- have a unique function created so that it 
    -- gets singularly removed, so that if the function is called
    -- more than once, RemoveCallback will remove only this call's 
    -- version
    local function singleCallback(...)
        func(...)
        revel:RemoveCallback(callbackId, singleCallback)
    end
    revel:AddCallback(callbackId, singleCallback, param)
end

end