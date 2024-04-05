-- Assorted utilities that didn't fit in a specific category

local RevCallbacks = require("scripts.revelations.common.enums.RevCallbacks")

return function()

--#region CallbackOnce

local CallbacksToRemove = {}
local CallbacksToRemoveUpdate = {}

--- Run callback once, can be used akin to a "on next <callback>"
-- Note: will run N times on next trigger if called N times before last 
-- call is used
---@param callbackId ModCallbacks
---@param func function
---@param isStageapi? boolean
---@param param? any
function REVEL.CallbackOnce(callbackId, func, isStageapi, param)
    -- have a unique function created so that it 
    -- gets singularly removed, so that if the function is called
    -- more than once, RemoveCallback will remove only this call's 
    -- version
    -- Additionally, check if already executed regardless
    -- as it gets removed in other callbacks

    local executed = false
    local entry = {
        CallbackId = callbackId,
        StageAPI = isStageapi,
    }

    local function singleCallback(...)
        if not executed then
            executed = true
            entry.Remove = true
            func(...)
        end
    end

    entry.Function = singleCallback
    local callbackTbl = callbackId == ModCallbacks.MC_POST_UPDATE and CallbacksToRemoveUpdate or CallbacksToRemove
    callbackTbl[#callbackTbl+1] = entry

    if isStageapi then 
        StageAPI.AddCallback("Revelations", callbackId, 0, singleCallback, param)
    else
        revel:AddCallback(callbackId, singleCallback, param)
    end
end

local function checkTbl(tbl)
    for i, callbackInfo in ripairs(tbl) do
        if callbackInfo.Remove then
            if callbackInfo.StageAPI then
                for i, callback in StageAPI.ReverseIterate(StageAPI.Callbacks[callbackInfo.CallbackId]) do
                    if callback.Function == callbackInfo.Function then
                        table.remove(StageAPI.Callbacks[callbackInfo.CallbackId], i)
                        break
                    end
                end
            else
                revel:RemoveCallback(callbackInfo.CallbackId, callbackInfo.Function)
            end
            table.remove(tbl, i)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    checkTbl(CallbacksToRemove)
end)
-- Separate callback to remove POST_UPDATE to avoid affecting its execution
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    checkTbl(CallbacksToRemoveUpdate)
end)

--#endregion

--#region WasChanged

local WasChanged = {}

---Call with a name and some variables, will return true if the values passed changed
---since the last time this was called with <name>. Used if you want to shorten doing 
---things like tracking a value in an entity Data and doing things when it changes
---between updates.
---@param name string
---@param ... any #values
---@return boolean
function REVEL.WasChanged(name, ...) --breaks with nil values
    local arg = {...}
    if WasChanged[name] == nil then
        WasChanged[name] = arg
        return true
    else
        if #arg ~= #WasChanged[name] then
            return true
        else
            for i,v in ipairs(WasChanged[name]) do
                if v ~= arg[i] then
                    WasChanged[name] = arg
                    return true
                end
            end
        end

        return false
    end
end

--#endregion

----------------------
-- DELAYED FUNCTION --
----------------------

--call function after x updates or renders
local DelayedFuncs = {}

local lastId = 0

function REVEL.DelayFunction(func, delay, args, removeOnNewRoom, useRender)
    if type(func) == 'number' then
        local temp = func
        func = delay
        delay = temp
    end
    if type(args) ~= "table" then args = {args} end
    table.insert(DelayedFuncs, 1, {func, delay, args, removeOnNewRoom, useRender, lastId})
    lastId = lastId + 1
    return lastId - 1
end

function REVEL.ClearDelayedFunction(id)
    local idx = REVEL.findKey(DelayedFuncs, function(v) return v[6] == id end)
    if idx then
        table.remove(DelayedFuncs, idx)
    end
end

local function delayFunctionHandling(onRender)
    if #DelayedFuncs ~= 0 then
        for i,v in ripairs(DelayedFuncs) do
            if (v[5] and onRender) or (not v[5] and not onRender) then
                if v[2] == 0 then
                    -- Run only once even in case of errors
                    table.remove(DelayedFuncs, i)
                    if v[3] then
                        v[1](table.unpack(v[3]))
                    else
                        v[1]()
                    end
                else
                    v[2] = v[2] - 1
                end
            end
        end
    end
end


StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for i, func in ripairs(DelayedFuncs) do
        if func[4] then
            table.remove(DelayedFuncs, i)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    delayFunctionHandling(false)
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    delayFunctionHandling(true)
end)

end