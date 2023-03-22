REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()

-- revelations performance tracker 1.7.9b edition
-- which can work on other mods too
-- this will miss callbacks added dynamically during gameplay
-- (but will still get callbacks added for example on POST_GAME_STARTED
-- for old priority reasons)

REVEL.DO_DEBUG_METRICS = false
-- can be set from console before reloading
REVEL.DO_DEBUG_METRICS = REVEL.DO_DEBUG_METRICS or REV_FORCE_DEBUG_METRICS

if not REVEL.DO_DEBUG_METRICS then
    return
end

REVEL.Performance = {
    -- other mods can be added here to check them too,
    -- but only rev will be able to track custom callbacks
    -- used by it
    TrackedMods = {
        revel.Name,
        "StageAPI",
        "Minimap API",
    },
    DoNotTrackFuncs = {},
    -- again, only for rev if on
    -- as custom callbacks are called inside other callbacks, 
    -- the total time might be skewed as the containing callback
    -- will count this one's too
    CountCustomCallbacks = false, 
    DoDetailedPcall = true,
    UpdatePeriod = -1, -- in ms, use -1 to only print final average
    ExpAverageWeighting = 0.75, -- how much the old average matters in new average, from 0 to 1
    CountPausedTime = false,
}

_G.REV_ALREADY_LOGGING_TRACEBACK = debug and REVEL.Performance.DoDetailedPcall

local DoSingleFunctionTracking = not not debug

---@type table<function, CallbackEntry>
local TrackedCallbacks = {}
---@type table<function, CallbackEntry>
local TrackedCallbacksByWrappers = {}
---@type table<function, function>
local CallbackFuncsByWrapper = {}
---@type table<function, CallbackID>
local CallbackIDsByFunc = {}

---@type table<CallbackID, number>
local CallbackTimeTotals = {}
---@type table<function, number>
local CallbackTimeByFunc = {}
---@type table<CallbackID, number>
local ExpAverageTime = {}
---@type table<function, number>
local ExpAverageTimePerFunc = {}


local TrackAllCallbacks
local PatchCallback
local GetFunctionInfo
local PrintFunctionInfo
local gettime = Isaac.GetTime


local function GetTrackedCallbackIDs()
    local checkCallbacks = {}
    for _, callbackId in pairs(ModCallbacks) do
        checkCallbacks[#checkCallbacks+1] = callbackId
    end

    if REVEL.Performance.CountCustomCallbacks 
    and revel.GetUsedCallbackIDs then
        for callbackId, _ in pairs(revel:GetUsedCallbackIDs()) do
            checkCallbacks[#checkCallbacks+1] = callbackId
        end
    end
    return checkCallbacks
end

-- check current callbacks, may need to be called also after launch
-- to track callbacks added after launch
function TrackAllCallbacks()
    local checkCallbacks = GetTrackedCallbackIDs()
    REVEL.DebugToString("[REV PERF] Checking callbacks to track,", #checkCallbacks, "IDs to check...")
    local count = 0
    local mods = {}

    for _, callbackId in ipairs(checkCallbacks) do
        local callbacks = Isaac.GetCallbacks(callbackId)
        for _, callbackEntry in ipairs(callbacks) do
            if REVEL.includes(REVEL.Performance.TrackedMods, callbackEntry.Mod.Name) 
            and not TrackedCallbacks[callbackEntry.Function]
            and not TrackedCallbacksByWrappers[callbackEntry.Function]
            and not REVEL.Performance.DoNotTrackFuncs[callbackEntry.Function]
            then
                -- local info = debug.getinfo(callbackEntry.Function)
                -- REVEL.DebugLog("Patching callback ", info.short_src, info.linedefined)
                -- local func = callbackEntry.Function
                PatchCallback(callbackEntry, callbackId)
                -- assert(TrackedCallbacks[func])
                -- assert(TrackedCallbacksByWrappers[callbackEntry.Function])
                count = count + 1
                mods[callbackEntry.Mod] = true
            end
        end
    end

    REVEL.DebugToString("[REV PERF] Tracked", count, "callbacks from", 
        REVEL.tlen(mods), "mods:", table.concat(REVEL.flatmap(mods, function(v, k) return k.Name end), ", "))
end

---@param callbackEntry CallbackEntry
---@param callbackId CallbackID
function PatchCallback(callbackEntry, callbackId)
    local originalFunc = callbackEntry.Function

    TrackedCallbacks[originalFunc] = callbackEntry
    CallbackIDsByFunc[originalFunc] = callbackId
    CallbackTimeTotals[callbackId] = CallbackTimeTotals[callbackId] or 0
    ExpAverageTime[callbackId] = ExpAverageTime[callbackId] or 0

    if DoSingleFunctionTracking then
        CallbackTimeByFunc[originalFunc] = 0
        ExpAverageTimePerFunc[originalFunc] = 0
    end

    ---@type function
    local wrapperFunc

    if REVEL.Performance.DoDetailedPcall and DoSingleFunctionTracking then
        wrapperFunc = function(...)
            local t1, t2
            t1 = gettime()
            -- PrintFunctionInfo(fn, "Revelations")
            local ok, ret = xpcall(originalFunc, debug.traceback, ...)
            if not ok then
                error(("\n[Rev track] Error in \"%s\" with param '%s': %s"):format(
                    tostring(REVEL.getKeyFromValue(ModCallbacks, callbackId)), 
                    tostring(callbackEntry.Param), 
                    tostring(ret)
                ))
            end
            t2 = gettime()
            
            -- count time
            if REVEL.Performance.CountPausedTime or not REVEL.game:IsPaused() then
                CallbackTimeByFunc[originalFunc] = CallbackTimeByFunc[originalFunc] + t2 - t1
                CallbackTimeTotals[callbackId] = CallbackTimeTotals[callbackId] + t2 - t1
            end

            return ret
        end
    elseif DoSingleFunctionTracking then
        wrapperFunc = function(...)
            local t1, t2
            t1 = gettime()
            local ret = originalFunc(...)
            t2 = gettime()
            
            -- count time
            if REVEL.Performance.CountPausedTime or not REVEL.game:IsPaused() then
                CallbackTimeByFunc[originalFunc] = CallbackTimeByFunc[originalFunc] + t2 - t1
                CallbackTimeTotals[callbackId] = CallbackTimeTotals[callbackId] + t2 - t1
            end

            return ret
        end
    else
        wrapperFunc = function(...)
            local t1, t2
            t1 = gettime()
            local ret = originalFunc(...)
            t2 = gettime()
            
            -- count time
            if REVEL.Performance.CountPausedTime or not REVEL.game:IsPaused() then
                CallbackTimeTotals[callbackId] = CallbackTimeTotals[callbackId] + t2 - t1
            end

            return ret
        end
    end

    TrackedCallbacksByWrappers[wrapperFunc] = callbackEntry
    CallbackFuncsByWrapper[wrapperFunc] = originalFunc

    callbackEntry.Function = wrapperFunc
end

function GetFunctionInfo(func)
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

function PrintFunctionInfo(func, context)
    if debug then
        REVEL.DebugToString((context or "") .. ": Running: '" .. GetFunctionInfo(func) .. "'")
    end
end

local function timeToSec(x)
    return x / 1000
end
local function timeToMs(x)
    return x
end

local function formatAvg(x)
    return ("%6s"):format(("%3.4f"):format(x))
end

local function expAverage(oldAvg, newVal)
    return oldAvg * REVEL.Performance.ExpAverageWeighting 
        + newVal * (1 - REVEL.Performance.ExpAverageWeighting)
end

if debug then
    local socket = require("socket")
    gettime = function()
        return socket.gettime() * 1000
    end
end

--#region RegisterTracking

-- immediately add all currently loaded callbacks
TrackAllCallbacks()

-- check after load
-- (also insert POST_mod_LOAD subscriptions here later when mods start to do this thing)

local function perfTrack_TrackAdd_PostUpdate()
    -- this should cover most POST_GAME_STARTED and similar
    -- callbacks with the old way to handle priority
    if REVEL.game:GetFrameCount() == 2 then
        TrackAllCallbacks()
    end
end

-- if reloading
if Isaac.GetPlayer(0) then
    REVEL.DelayFunction(TrackAllCallbacks, 2)
end

--unloading/luamod
local function perfTrack_TrackAdd_PreModUnload(self, mod)
    local toRemove = {}
    for origFunc, callbackEntry in pairs(TrackedCallbacks) do
        if callbackEntry.Mod == mod then
            local wrapperFunc = callbackEntry.Function
            CallbackFuncsByWrapper[wrapperFunc] = nil
            TrackedCallbacksByWrappers[wrapperFunc] = nil
            toRemove[#toRemove+1] = origFunc
        end
    end

    for _, origFunc in ipairs(toRemove) do
        TrackedCallbacks[origFunc] = nil
    end
end

revel:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, perfTrack_TrackAdd_PostUpdate)
revel:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, perfTrack_TrackAdd_PreModUnload)

REVEL.mixin(REVEL.Performance.DoNotTrackFuncs, {
    [perfTrack_TrackAdd_PostUpdate] = true,
    [perfTrack_TrackAdd_PreModUnload] = true,
})

--#endregion

--#region TrackLogic

local CallbackNames = {}
for k, callbackId in pairs(ModCallbacks) do
    CallbackNames[callbackId] = k
end

local MIN_RUN_TIME_FOR_PRINT = 3 --seconds

local LastTime = -1
local LastPausedTime = -1
local PausedTotalTime = 0

local function perfTrack_PostRender()
    local t = gettime()
    if LastTime == -1 then
        LastTime = t
        LastPausedTime = -1
        PausedTotalTime = 0
        REVEL.DebugLog("Revelations: Performance metrics started")
    end

    if REVEL.game:IsPaused() then
        if LastPausedTime == -1 then
            LastPausedTime = gettime()
        else
            PausedTotalTime = PausedTotalTime + gettime() - LastPausedTime
            LastPausedTime = -1
        end
    end

    if REVEL.Performance.UpdatePeriod > 0 and t - LastTime > REVEL.Performance.UpdatePeriod then
        local period = t - LastTime
        Isaac.DebugString("---- REV PERFORMANCE (Paused: " .. (REVEL.game:IsPaused() and "Y" or "N") ..") ----")
        local totalTotal = 0

        local trackedCallbacks = GetTrackedCallbackIDs()

        local totalTimes = REVEL.CopyTable(CallbackTimeTotals)

        for _, callbackId in ipairs(trackedCallbacks) do
            local totalTime = totalTimes[callbackId] or 0
            totalTotal = totalTotal + totalTime
            ExpAverageTime[callbackId] = expAverage(ExpAverageTime[callbackId], totalTime * period / REVEL.Performance.UpdatePeriod)
            CallbackTimeTotals[callbackId] = 0
        end

        if DoSingleFunctionTracking then
            for fn, time in pairs(CallbackTimeByFunc) do
                ExpAverageTimePerFunc[fn] = expAverage(ExpAverageTimePerFunc[fn], time * period / REVEL.Performance.UpdatePeriod)
                CallbackTimeByFunc[fn] = 0
            end
        end

        for _, callbackId in ipairs(trackedCallbacks) do
            Isaac.DebugString(tostring(CallbackNames[callbackId] or callbackId) .. ": "
                .. formatAvg(timeToMs(totalTimes[callbackId])) .. "ms | " 
                .. formatAvg(totalTimes[callbackId] * 100 / totalTotal) .. "%"
            )
        end
        Isaac.DebugString("TOTAL: " .. formatAvg(timeToMs(totalTotal)) .. "ms | " .. formatAvg(totalTotal * 100 / period) .. "%")
        REVEL.DebugToString("------------------------------------")
        LastTime = gettime()
    end
end

local function perfTrack_PreGameExit()
    local t = gettime()
    local period = t - LastTime
    Isaac.DebugString("------ REV PERFORMANCE AVERAGE ------")
    if REVEL.Performance.UpdatePeriod < 0 then
        period = period - PausedTotalTime
        Isaac.DebugString("TIME ELAPSED: " .. timeToSec(period) .. "s AVG'D to 1s")

        if timeToSec(period) < MIN_RUN_TIME_FOR_PRINT then
            Isaac.DebugString("[RUN TOO SHORT - STOPPING]")
           return
        end
    else
        Isaac.DebugString("OVER PERIODS OF " .. timeToSec(REVEL.Performance.UpdatePeriod) .. "s AVG'D to 1s")
    end
    if not REVEL.Performance.CountPausedTime then
        Isaac.DebugString("[NOT COUNTING PAUSED TIME]")
    end
    local oneSec = 1000
    local ratio = oneSec / REVEL.Performance.UpdatePeriod
    if REVEL.Performance.UpdatePeriod < 0 then
        ratio = oneSec / period
    end

    local totalTotal = 0
    local maxNameLen = {}
    local maxModLen = {}
    local callbackTimes = {} -- used for sorting
    local functionTimes = {} -- used for sorting
    local trackedCallbacks = GetTrackedCallbackIDs()
    local totalTimes = REVEL.CopyTable(CallbackTimeTotals)

    for _, callbackId in ipairs(trackedCallbacks) do
        local totalTime = totalTimes[callbackId] or 0

        if REVEL.Performance.UpdatePeriod < 0 then
            ExpAverageTime[callbackId] = totalTime
        else
            ExpAverageTime[callbackId] = expAverage(ExpAverageTime[callbackId], totalTime * period / REVEL.Performance.UpdatePeriod)
        end

        callbackTimes[#callbackTimes+1] = {CallbackId = callbackId, Value = ExpAverageTime[callbackId]}

        local avg = ExpAverageTime[callbackId] * ratio
        totalTotal = totalTotal + avg

        CallbackTimeTotals[callbackId] = 0
    end
    table.sort(callbackTimes, function(a, b) return a.Value > b.Value end)

    if DoSingleFunctionTracking then
        for fn, time in pairs(CallbackTimeByFunc) do
            local callbackId = CallbackIDsByFunc[fn]
            functionTimes[callbackId] = functionTimes[callbackId] or {}

            if REVEL.Performance.UpdatePeriod < 0 then
                ExpAverageTimePerFunc[fn] = time
            else
                ExpAverageTimePerFunc[fn] = expAverage(ExpAverageTimePerFunc[fn], time * period / REVEL.Performance.UpdatePeriod)
            end

            functionTimes[callbackId][#functionTimes[callbackId]+1] = {
                Function = fn,
                Value = ExpAverageTimePerFunc[fn],
            }

            maxNameLen[callbackId] = math.max(#GetFunctionInfo(fn), maxNameLen[callbackId] or -1)
            local modname = TrackedCallbacks[fn].Mod.Name
            maxModLen[callbackId] = math.max(#modname, maxModLen[callbackId] or -1)

            CallbackTimeByFunc[fn] = 0
        end

        for callbackId, times in pairs(functionTimes) do
            table.sort(times, function(a, b) return a.Value > b.Value end)
        end
    end

    for _, v in ipairs(callbackTimes) do
        local callbackId = v.CallbackId

        local avg = ExpAverageTime[callbackId] * ratio
        Isaac.DebugString(CallbackNames[callbackId] .. ": " .. formatAvg(timeToMs(avg)) .. "ms | " .. formatAvg(avg * 100 / totalTotal) .. "%")

        if avg > 0 and DoSingleFunctionTracking then
            for _, v2 in ipairs(functionTimes[callbackId]) do
                local fn = v2.Function

                local fnAvg = ExpAverageTimePerFunc[fn] * ratio
                local modname = TrackedCallbacks[fn].Mod.Name
                local name =  GetFunctionInfo(fn)
                Isaac.DebugString("\t"  .. ("%" .. (maxModLen[callbackId] + 2) .. "s "):format("[" .. modname .. "]")
                    .. ("%" .. maxNameLen[callbackId] .. "s"):format(name) .. ": " 
                    .. formatAvg(timeToMs(fnAvg)) .. "ms | " .. formatAvg(fnAvg * 100 / avg) .. "%")
            end
        end

        totalTotal = totalTotal + avg
    end
    Isaac.DebugString("TOTAL: " .. formatAvg(timeToMs(totalTotal)) .. "ms | " .. formatAvg(totalTotal * 100 / oneSec) .. "%")
    REVEL.DebugToString("------------------------------------")
    LastTime = -1
end

revel:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, CallbackPriority.LATE, perfTrack_PostRender)
revel:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, CallbackPriority.LATE, perfTrack_PreGameExit)

REVEL.mixin(REVEL.Performance.DoNotTrackFuncs, {
    [perfTrack_PostRender] = true,
    [perfTrack_PreGameExit] = true,
})

--#endregion

REVEL.DebugLog("Revelations: Loaded Performance Metrics")

end