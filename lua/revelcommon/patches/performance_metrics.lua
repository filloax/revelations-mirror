
local function DebugLog(str)
    Isaac.DebugString(str)
    Isaac.ConsoleOutput(str .. "\n")
end

local UpdatePeriod = -1 -- in ms, use -1 to only print final average
local DoSingleFunctionTracking = not not debug
local DoDetailedPcall = not not debug
local ExpAverageWeighting = 0.75 -- how much the old average matters in new average, from 0 to 1

local gettime = Isaac.GetTime

local function timeToSec(x)
    return x / 1000
end
local function timeToMs(x)
    return x
end

if debug then
    local socket = require("socket")
    gettime = function()
        return socket.gettime() * 1000
    end
    -- function timeToSec(x)
    --     return x
    -- end
    -- function timeToMs(x)
    --     return x * 1000
    -- end
    -- UpdatePeriod = UpdatePeriod / 1000
end

local function MakeCallbackInfo()
    return {
        List = {},
        AllList = {}, --doesn't get removed by RemoveCallback, used for printing
        FuncSet = {}, --doesn't get removed by RemoveCallback, used for tracking which ones are in AllSet
        TimeTakenThisPeriod = 0,
        TimeTakenThisPeriodPerFunc = {},
    }
end

local ExpAverageTime = {}
local ExpAverageTimePerFunc = {}
local CallbackInfo = {}
local CallbackFunctionMap = {} --not grouped by entity id, used for remove, contains entity ids that have added this function
local ToRemoveFunc = {}

-- Track the wrapper callbacks added with the real function
-- so they can be removed
local WrapperCallbackFunctions = {}

for k, callbackId in pairs(ModCallbacks) do
    CallbackInfo[callbackId] = {}
    ExpAverageTime[callbackId] = 0
    ToRemoveFunc[callbackId] = {}
    CallbackFunctionMap[callbackId] = {}
    WrapperCallbackFunctions[callbackId] = {}
end

local function RemoveCallbackFromInfo(callbackInfo, fn)
    local index

    for i = #callbackInfo.List, 1, -1 do
        if callbackInfo.List[i] == fn then
            index = i
            break
        end
    end
    table.remove(callbackInfo.List, index)
end

local function RemoveCallbackByTypeAndFn(mod, callbackId, fn, entityId)
    entityId = entityId or -1 -- base game behavior

    local callbackInfo = CallbackInfo[callbackId][entityId]

    -- Avoid removing during the function loop, do when done
    if mod.RunningCallback == callbackId then
        table.insert(ToRemoveFunc[callbackId], fn)
    else
        RemoveCallbackFromInfo(callbackInfo, fn)
    end
end

local BreakingReturnCallbacks = {
    [ModCallbacks.MC_ENTITY_TAKE_DMG] = true,
    [ModCallbacks.MC_GET_SHADER_PARAMS] = true,
    [ModCallbacks.MC_PRE_USE_ITEM] = true,
    [ModCallbacks.MC_PRE_FAMILIAR_COLLISION] = true,
    [ModCallbacks.MC_PRE_NPC_COLLISION] = true,
    [ModCallbacks.MC_PRE_PLAYER_COLLISION] = true,
    [ModCallbacks.MC_PRE_PLAYER_COLLISION] = true,
    [ModCallbacks.MC_PRE_PICKUP_COLLISION] = true,
    [ModCallbacks.MC_PRE_TEAR_COLLISION] = true,
    [ModCallbacks.MC_PRE_PROJECTILE_COLLISION] = true,
    [ModCallbacks.MC_PRE_KNIFE_COLLISION] = true,
    [ModCallbacks.MC_PRE_BOMB_COLLISION] = true,
    [ModCallbacks.MC_PRE_NPC_UPDATE] = true,
    [ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD] = true,
}

local CallbackNames = {}
for k, callbackId in pairs(ModCallbacks) do
    CallbackNames[callbackId] = k
end

local function GetFunctionInfo(func)
    if not func then
        error("GetFunctionInfo: func nil", 2)
    end
    if debug then
        local info = debug.getinfo(func)
        local src_name = string.gsub(info.short_src, '\\', '/')
        local thirdLastSlashIndex = (src_name:match('^.*()/.+/.+/') or 0) + 1
        local name = string.sub(src_name, thirdLastSlashIndex, #src_name)
        return name .. " @line:" .. info.linedefined
    end
    return tostring(func)
end 

local function PrintFunctionInfo(func, context)
    if debug then
        REVEL.DebugToString((context or "") .. ": Running: '" .. GetFunctionInfo(func) .. "'")
    end
end

local function formatAvg(x)
    return ("%6s"):format(("%3.4f"):format(x))
end

local function expAverage(oldAvg, newVal)
    return oldAvg * ExpAverageWeighting + newVal * (1 - ExpAverageWeighting)
end

local MIN_RUN_TIME_FOR_PRINT = 3 --seconds

local lastTime = -1
local lastPausedTime = -1
local pausedTotalTime = 0

-- Doesn't actually work on multiple mods rn, as the local variables are
-- one instance just found it cleaner to split it in a separate function
local function PatchMod_PerformanceMetrics(mod)
    _G.REV_ALREADY_LOGGING_TRACEBACK = DoSingleFunctionTracking and DoDetailedPcall
    
    mod._PrePerfAddCallback = mod.AddCallback
    mod._PrePerfRemoveCallback = mod.RemoveCallback
    mod._PrePerfRemoveAllCallbacks = mod.RemoveAllCallbacks
    mod.RunningCallback = nil
    
    function mod:AddCallback(callbackId, fn, entityId)
        entityId = entityId or -1 -- base game behavior

        if not fn then
            error("AddCallback | function nil", 2)
        end
        if type(fn) ~= "function" then
            error("AddCallback | function not a function: " .. tostring(fn), 2)
        end

        local callbackInfo = CallbackInfo[callbackId][entityId]
        if not callbackInfo then
            CallbackInfo[callbackId][entityId] = MakeCallbackInfo()
            callbackInfo = CallbackInfo[callbackId][entityId]
        end

        callbackInfo.TimeTakenThisPeriodPerFunc[fn] = 0
        ExpAverageTimePerFunc[fn] = 0

        if #callbackInfo.List == 0 then
            WrapperCallbackFunctions[callbackId][entityId] = function(...)
                return self:PerformanceMetricsCallback(callbackId, entityId, ...)
            end
            self:_PrePerfAddCallback(callbackId, WrapperCallbackFunctions[callbackId][entityId], entityId)
        end

        callbackInfo.List[#callbackInfo.List + 1] = fn

        if not callbackInfo.FuncSet[fn] then
            callbackInfo.AllList[#callbackInfo.AllList + 1] = fn
            callbackInfo.FuncSet[fn] = true
        end

        CallbackFunctionMap[callbackId][fn] = CallbackFunctionMap[callbackId][fn] or {}
        table.insert(CallbackFunctionMap[callbackId][fn], entityId)
    end

    function mod:RemoveCallback(callbackId, fn)
        local entityIds = CallbackFunctionMap[callbackId] and CallbackFunctionMap[callbackId][fn]
        if entityIds then
            for _, entityId in ipairs(entityIds) do
                RemoveCallbackByTypeAndFn(self, callbackId, fn, entityId)
            end
            CallbackFunctionMap[callbackId][fn] = nil

            local anyLeft = false
            for entityId, callbackInfo in pairs(CallbackInfo[callbackId]) do
                if #callbackInfo.List > 0 then
                    anyLeft = true
                    break
                end
            end

            if not anyLeft then
                for entityId, wrapperFunction in pairs(WrapperCallbackFunctions[callbackId]) do
                    self:_PrePerfRemoveCallback(callbackId, wrapperFunction)
                end
                WrapperCallbackFunctions[callbackId] = {}
            end
        end
    end

    function mod:RemoveAllCallbacks()
        for _, callbackId in pairs(ModCallbacks) do
            for fn, entityIds in pairs(CallbackFunctionMap[callbackId]) do
                self:RemoveCallback(callbackId, fn)
            end
        end

        if mod.RemoveRegisteredCallbacks then
            mod:RemoveRegisteredCallbacks()
        end
    end

    function mod:PerformanceMetricsCallback(callbackId, entityId, ...)
        local callbackInfo = CallbackInfo[callbackId][entityId]
        local ret
        local t1, t2
        local dur = 0

        local prevRunningCallback = self.RunningCallback
        local isPaused = REVEL.game:IsPaused()
        self.RunningCallback = callbackId

        if DoSingleFunctionTracking then
            local ttpf = callbackInfo.TimeTakenThisPeriodPerFunc
            -- Avoid inner if to not affect performance too much
            if DoDetailedPcall then
                for _, fn in ipairs(callbackInfo.List) do
                    local thisRet
                    t1 = gettime()
                    -- PrintFunctionInfo(fn, "Revelations")
                    local ok, thisRet = xpcall(fn, debug.traceback, ...)
                    if not ok then
                        error(("\n[Revelations] Error in \"%s\" with param '%s': %s"):format(
                            tostring(REVEL.getKeyFromValue(ModCallbacks, callbackId)), 
                            tostring(entityId), 
                            tostring(thisRet)
                        ))
                    end
                    t2 = gettime()
                    if thisRet ~= nil then
                        ret = thisRet
                    end
                    -- count time when paused only with periodic updates
                    if isPaused ~= (UpdatePeriod < 0) then
                        ttpf[fn] = ttpf[fn] + t2 - t1
                    end
                    if BreakingReturnCallbacks[callbackId] and ret ~= nil then
                        break
                    end
                    dur = dur + t2 - t1
                end
            else
                for _, fn in ipairs(callbackInfo.List) do
                    local thisRet
                    t1 = gettime()
                    thisRet = fn(...)
                    t2 = gettime()
                    if thisRet ~= nil then
                        ret = thisRet
                    end
                    -- count time when paused only with periodic updates
                    if isPaused ~= (UpdatePeriod < 0) then
                        ttpf[fn] = ttpf[fn] + t2 - t1
                    end
                    if BreakingReturnCallbacks[callbackId] and ret ~= nil then
                        break
                    end
                    dur = dur + t2 - t1
                end
            end
        else
            t1 = gettime()
            for _, fn in ipairs(callbackInfo.List) do
                local thisRet
                thisRet = fn(...)

                if thisRet ~= nil then
                    ret = thisRet
                end

                if BreakingReturnCallbacks[callbackId] and ret ~= nil then
                    break
                end
            end
            t2 = gettime()
            dur = t2 - t1
        end

        self.RunningCallback = prevRunningCallback
        if self.RunningCallback ~= prevRunningCallback
        and #ToRemoveFunc[callbackId] > 0 
        then
            for _, fn in ipairs(ToRemoveFunc[callbackId]) do
                self:RemoveCallback(callbackId, fn)
            end
            ToRemoveFunc[callbackId] = {}
        end

        -- count time when paused only with periodic updates
        if isPaused ~= (UpdatePeriod < 0) then
            callbackInfo.TimeTakenThisPeriod = callbackInfo.TimeTakenThisPeriod + dur
        end

        return ret
    end

    mod:_PrePerfAddCallback(ModCallbacks.MC_POST_RENDER, function()
        local t = gettime()
        if lastTime == -1 then
            lastTime = t
            lastPausedTime = -1
            pausedTotalTime = 0
            DebugLog("Revelations: Performance metrics started")
        end

        if REVEL.game:IsPaused() then
            if lastPausedTime == -1 then
                lastPausedTime = gettime()
            else
                pausedTotalTime = pausedTotalTime + gettime() - lastPausedTime
                lastPausedTime = -1
            end
        end

        if UpdatePeriod > 0 and t - lastTime > UpdatePeriod then
            local period = t - lastTime
            Isaac.DebugString("---- REV PERFORMANCE (Paused: " .. (REVEL.game:IsPaused() and "Y" or "N") ..") ----")
            local totalTotal = 0
            local totalTimes = {}
            for callbackId, infoList in pairs(CallbackInfo) do
                local totalTime = 0
                for entityId, info in pairs(infoList) do
                    totalTime = totalTime + info.TimeTakenThisPeriod
                    info.TimeTakenThisPeriod = 0

                    if DoSingleFunctionTracking then
                        for fn, v in pairs(info.TimeTakenThisPeriodPerFunc) do
                            ExpAverageTimePerFunc[fn] = expAverage(ExpAverageTimePerFunc[fn], v * period / UpdatePeriod)
                            info.TimeTakenThisPeriodPerFunc[fn] = 0
                        end
                    end
                end
                ExpAverageTime[callbackId] = expAverage(ExpAverageTime[callbackId], totalTime * period / UpdatePeriod)
                totalTimes[callbackId] = totalTime
                totalTotal = totalTotal + totalTime
            end
            for callbackId, infoList in pairs(CallbackInfo) do
                Isaac.DebugString(CallbackNames[callbackId] .. ": " .. formatAvg(timeToMs(totalTimes[callbackId])) .. "ms | " .. formatAvg(totalTimes[callbackId] * 100 / totalTotal) .. "%")
            end
            Isaac.DebugString("TOTAL: " .. formatAvg(timeToMs(totalTotal)) .. "ms | " .. formatAvg(totalTotal * 100 / period) .. "%")
            REVEL.DebugToString("------------------------------------")
            lastTime = gettime()
        end
    end)

    mod:_PrePerfAddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        local t = gettime()
        local period = t - lastTime
        Isaac.DebugString("------ REV PERFORMANCE AVERAGE ------")
        if UpdatePeriod < 0 then
            if timeToSec(period) < MIN_RUN_TIME_FOR_PRINT then
                return
            end

            period = period - pausedTotalTime
            Isaac.DebugString("TIME ELAPSED: " .. timeToSec(period) .. "s AVG'D to 1s")
            Isaac.DebugString("[NOT COUNTING PAUSED TIME]")
        else
            Isaac.DebugString("OVER PERIODS OF " .. timeToSec(UpdatePeriod) .. "s AVG'D to 1s")
        end
        local oneSec = 1000
        local ratio = oneSec / UpdatePeriod
        if UpdatePeriod < 0 then
            ratio = oneSec / period
        end

        local totalTotal = 0
        local maxNameLen = {}
        local callbackTimes = {} -- used for sorting
        local functionTimes = {} -- used for sorting
        for callbackId, infoList in pairs(CallbackInfo) do
            local totalTime = 0
            for entityId, info in pairs(infoList) do
                totalTime = totalTime + info.TimeTakenThisPeriod
                info.TimeTakenThisPeriod = 0

                if DoSingleFunctionTracking then
                    functionTimes[callbackId] = {}
                    for fn, v in pairs(info.TimeTakenThisPeriodPerFunc) do
                        if UpdatePeriod < 0 then
                            ExpAverageTimePerFunc[fn] = v
                        else
                            ExpAverageTimePerFunc[fn] = expAverage(ExpAverageTimePerFunc[fn], v * period / UpdatePeriod)
                        end
                        info.TimeTakenThisPeriodPerFunc[fn] = 0

                        functionTimes[callbackId][#functionTimes[callbackId]+1] = {
                            Function = fn,
                            Value = ExpAverageTimePerFunc[fn],
                        }

                        maxNameLen[callbackId] = math.max(#GetFunctionInfo(fn), maxNameLen[callbackId] or -1)
                    end

                    table.sort(functionTimes[callbackId], function(a, b) return a.Value > b.Value end)
                end
            end

            if UpdatePeriod < 0 then
                ExpAverageTime[callbackId] = totalTime
            else
                ExpAverageTime[callbackId] = expAverage(ExpAverageTime[callbackId], totalTime * period / UpdatePeriod)
            end

            callbackTimes[#callbackTimes+1] = {CallbackId = callbackId, Value = ExpAverageTime[callbackId]}

            local avg = ExpAverageTime[callbackId] * ratio
            totalTotal = totalTotal + avg
        end

        table.sort(callbackTimes, function(a, b) return a.Value > b.Value end)

        for _, v in ipairs(callbackTimes) do
            local callbackId = v.CallbackId
            local infoList = CallbackInfo[callbackId]

            local avg = ExpAverageTime[callbackId] * ratio
            Isaac.DebugString(CallbackNames[callbackId] .. ": " .. formatAvg(timeToMs(avg)) .. "ms | " .. formatAvg(avg * 100 / totalTotal) .. "%")

            if avg > 0 and DoSingleFunctionTracking then
                for _, v2 in ipairs(functionTimes[callbackId]) do
                    local fn = v2.Function

                    local fnAvg = ExpAverageTimePerFunc[fn] * ratio
                    local name =  GetFunctionInfo(fn)
                    Isaac.DebugString("\t" .. ("%" .. maxNameLen[callbackId] .. "s"):format(name) .. ": " 
                    .. formatAvg(timeToMs(fnAvg)) .. "ms | " .. formatAvg(fnAvg * 100 / avg) .. "%")
                end
            end

            totalTotal = totalTotal + avg
        end
        Isaac.DebugString("TOTAL: " .. formatAvg(timeToMs(totalTotal)) .. "ms | " .. formatAvg(totalTotal * 100 / oneSec) .. "%")
        REVEL.DebugToString("------------------------------------")
        lastTime = -1
    end)
    
    DebugLog("Revelations: Performance metrics enabled")
    if not debug then
        DebugLog("Luadebug is off; performance metrics are more accurate with --luadebug enabled, "
            .. "but remember to only do so if you trust the mods you have installed")
    end
end

return PatchMod_PerformanceMetrics