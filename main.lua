local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
_G.revel = RegisterMod("Revelations",1)

_G.REVEL = {
    DEBUG = false,
    Testmode = false,
  
    VERSION = "4.0.0",
  
    MODID = "2880387531", --steam workshop id

    FOLDER_NAME = "revelations",
    IS_WORKSHOP = true,
    FAILED_LOAD = false,
}

_G.REV_RELOAD_PERSIST = _G.REV_RELOAD_PERSIST or {}

-- To enable setting this by console, then reloading rev with luamod
-- as many REVEL.DEBUG functions are done at load
if REVEL_FORCE_DEBUG then
    REVEL.DEBUG = true
end

require("lua.apioverride")

---------------------------
-- TRACK ADDED CALLBACKS --
---------------------------
local PatchMod_TrackAddedCallbacks = include("lua.revelcommon.patches.callback_track")

PatchMod_TrackAddedCallbacks(revel)

--------------------------
-- PERFORMANCE DIAGNOSTICS
--------------------------

REVEL.DO_DEBUG_METRICS = false
-- can be set from console before reloading
REVEL.DO_DEBUG_METRICS = REVEL.DO_DEBUG_METRICS or REV_FORCE_DEBUG_METRICS

local PatchMod_PerformanceMetrics = include("lua.revelcommon.patches.performance_metrics")

if REVEL.DO_DEBUG_METRICS then
    PatchMod_PerformanceMetrics(revel)
end

-----------------------
-- SHADERS CRASH FIX --
-----------------------

-- Thanks Cucco
revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function()
    if #Isaac.FindByType(EntityType.ENTITY_PLAYER) == 0 then
        Isaac.ExecuteCommand("reloadshaders")
    end
end)

----------------------
-- LOAD
----------------------

--[[

Due to require() only working during a mod's initial load, we can't properly delay it to after StageAPI loads.
Our solution to this is to have each file return a load function that we can call later when StageAPI has loaded.

]]

REVEL.Modules = include("lua.revelcommon.loadorder")

-- include now works in luadebug
REVEL.PCALL_WORKAROUND = false

REVEL.LoadFunctions = {}

--[[
    Generalization of the previous loading code to allow modules to load
    more modules on their own (for entity file management and similar)
    for better retrocompatibility, it still uses the REVEL.LoadFunctions table, 
    but only for reading the output (returning the load function wouldn't really work
    with pcall for the workaround when --luadebug is enabled)
    Basically: every module adds a function to REVEL.LoadFunctions, then those are put 
    into a local table that gets returned, and LoadFunctions is reset; it is used only internally

    If LoadFunctions is already non-empty at the start, it means this was called when loading another 
    module; it saves those in a temp table, does the loading, then restores LoadFunctions to previous state
]] 
function REVEL.LoadModulesFromTable(modules)
    local isMainLoad = #REVEL.LoadFunctions == 0

    local prevLoadFunctions = REVEL.LoadFunctions
    REVEL.LoadFunctions = {}

    local loadFunctions = {}
    local loadCounter = 0

    for i, v in ipairs(modules) do
        local success, ret = true, nil
        
        if REVEL.PCALL_WORKAROUND then
            _, ret = pcall(require, v)
            success = string.match(tostring(ret), "attempt to index a nil value %(field 'bork'%)") --supposed to error this way at end of file for luamod command workaround
        else
            success, ret = pcall(include, v)
        end
        
        if success then
            loadCounter = loadCounter + 1
        else
            Isaac.DebugString("Failed to load module: " .. tostring(ret))
            Isaac.ConsoleOutput("Failed to load module: " .. tostring(ret) .. "\n")
            break
        end
    end

    if loadCounter < #modules then
        revel:RemoveAllCallbacks()
        StageAPI.UnregisterCallbacks("Revelations")
        if MinimapAPI then
            MinimapAPI:RemoveAllCallbacks("Revelations")
        end
        REVEL.FAILED_LOAD = true
        error("Revelations: Couldn't load everything! Version " .. REVEL.VERSION, 0)
    elseif isMainLoad then
        Isaac.DebugString("Revelations: Finished initial loading! Version "..REVEL.VERSION)
    end
      
    loadFunctions = REVEL.LoadFunctions
    REVEL.LoadFunctions = prevLoadFunctions

    return loadFunctions
end

-- Throws the error that is catched above in LoadModules, 
-- avoids caching ~~(since include() doesn't work with luadebug for now)~~
-- now it does, whoo
function REVEL.PcallWorkaroundBreakFunction()
    if REVEL.PCALL_WORKAROUND then 
        revel.bork.NonExistantFunctionThatIsCalledToIntentionallyErrorThis() 
    end
end

local MainLoadFunctions = REVEL.LoadModulesFromTable(REVEL.Modules)

function REVEL.RunLoadFunctions(funcs)
    for _, fn in ipairs(funcs) do
        local success, err = pcall(fn)
        if not success then
            revel:RemoveAllCallbacks()
            StageAPI.UnregisterCallbacks("Revelations")
            if MinimapAPI then
                MinimapAPI:RemoveAllCallbacks("Revelations")
            end
            REVEL.FAILED_LOAD = true
            error("Failed to run load function: " .. tostring(err))
        end
    end
end

function REVEL.LoadRevel()
    StageAPI.UnregisterCallbacks("Revelations")
    if MinimapAPI then
        MinimapAPI:RemoveAllCallbacks("Revelations")
    end
    if REVEL.UnsplitBosses then
        for key, files in pairs(REVEL.UnsplitBosses) do
            StageAPI.SplitRoomsIntoLists(files, REVEL.Bosses[key], false, true)
        end
    end

    if REVEL.UnsplitSins then
        for key, files in pairs(REVEL.UnsplitSins) do
            StageAPI.SplitRoomsIntoLists(files, StageAPI.SinsSplitData, false, false, key)
        end
    end

    for k, names in pairs(REVEL.RoomLists) do
        if type(names) == "table" then
            REVEL.RoomLists[k] = StageAPI.RoomsList(k)
            for _, name in ipairs(names) do
                REVEL.RoomLists[k]:AddRooms(REVEL.Rooms[name])
            end
        else
            REVEL.RoomLists[k] = StageAPI.RoomsList(k, REVEL.Rooms[names])
        end
    end

    for k, bossDataList in pairs(REVEL.Bosses) do
        REVEL.ProcessBossData(bossDataList)
    end

    --[[ -- uncommend to log room list quantities
    REVEL.forEach(REVEL.sortKeys(StageAPI.RoomsLists), function(v)
        local key, list = table.unpack(v)
        REVEL.DebugToConsole(key, ':')
        REVEL.forEach(list.ByShape, function(v,k)
            REVEL.DebugToConsole(k, ':', #v)
        end)
    end)
    ]]

    Isaac.DebugString("Revelations: Running modules!")
    local time_preModules = Isaac.GetTime()
    REVEL.RunLoadFunctions(MainLoadFunctions)
    local time_postModules = Isaac.GetTime()
    Isaac.DebugString("Revelations: All modules loaded in " .. ((time_postModules - time_preModules) / 1000) .. "s.")

    if MinimapAPI then
        local verString = tostring(MinimapAPI.MajorVersion) .. "." .. tostring(MinimapAPI.MinorVersion)
        if REVEL.UsingIntegratedMinimapAPI() then
            Isaac.DebugString("Revelations: Using integrated MinimapAPI, version " .. verString)
        else
            Isaac.DebugString("Revelations: External MinimapAPI detected: version " .. verString)
        end
    else
        Isaac.DebugString("Revelations: No MinimapAPI version detected!")
    end

    ------------------------------------------------------
    -- INIT IN CASE MOD WAS RELOADED INGAME WITH luamod --
    ------------------------------------------------------

    if Isaac.GetPlayer(0) then
        revel:loadModdata()

        StageAPI.CallCallbacks(RevCallbacks.POST_INGAME_RELOAD, false, true)

        for _, player in ipairs(REVEL.players) do
            player:AddCacheFlags(CacheFlag.CACHE_ALL)
            player:EvaluateItems()
        end

        math.randomseed(Isaac.GetTime())
    end

    REVEL.DebugLog("Revelations: Fully loaded! Version " .. REVEL.VERSION)
    StageAPI.MarkLoaded("Revelations", REVEL.VERSION, true, false, "")

    REVEL.PostLoadMessage = REVEL.PostLoadMessage or ""

    -- if not REVEL.IS_WORKSHOP then
    --     REVEL.PostLoadMessage = REVEL.PostLoadMessage
    --         .. ("\nNot using workshop version; make sure that the folder"
    --             .. "name for the mod is '%s', or else custom fonts won't work")
    --         :format(REVEL.FOLDER_NAME)
    -- end

    if REVEL.PostLoadMessage ~= "" then
        REVEL.DebugLog("Revelations: " .. REVEL.PostLoadMessage)
    end

    -- IN CASE OF FIRE BREAK GLASS, use (modified for the occasion) if a var is getting changed
    -- for no apparent reason and you (really, really) cannot figure out why
    -- Try just printing to console AND log first though
    if REVEL.DEBUG_PANIC_MODE then
        local prevEliteValue = (revel.data and revel.data.run) and revel.data.run.eliteEncountered.tomb or false
        local lastTraceback = ""
        ---@diagnostic disable-next-line: lowercase-global
        revel2 = revel
        ---@diagnostic disable-next-line: lowercase-global
        revel = {}

        setmetatable(revel, {
            __index = function(t, key)
                if revel2.data and revel2.data.run and
                        prevEliteValue ~= revel2.data.run.eliteEncountered.tomb then
                    REVEL.DebugToConsole("Changed mbe to", revel2.data.run.eliteEncountered.tomb)
                    REVEL.DebugToString ("Changed mbe to", revel2.data.run.eliteEncountered.tomb, key, t[key], '\n', debug.traceback(), "\nLast traceback:\n", lastTraceback)
                    prevEliteValue = revel2.data.run.eliteEncountered.tomb
                end

                lastTraceback = debug.traceback()
                return revel2[key]
            end,
            __newindex = function(t, key, val)
                revel2[key] = val

                if revel2.data and revel2.data.run and
                        prevEliteValue ~= revel2.data.run.eliteEncountered.tomb then
                    REVEL.DebugToConsole("Changed mbe to", revel2.data.run.eliteEncountered.tomb)
                    REVEL.DebugToString ("Changed mbe to", revel2.data.run.eliteEncountered.tomb, key, val, '\n', debug.traceback())
                    prevEliteValue = revel2.data.run.eliteEncountered.tomb
                end

                return revel2[key]
            end
        })
    end
end

if StageAPI and StageAPI.Loaded then
    REVEL.LoadRevel()
else
    if not StageAPI then
        StageAPI = {Loaded = false, ToCall = {}}
    end

    StageAPI.ToCall[#StageAPI.ToCall + 1] = REVEL.LoadRevel
end

local shadersWorkaround = false
local revShaders = {["TombMask"] = true, ["AdjustColorCorrection"] = true, ["MidtonesColorCorrection"] = true, ["LightsShadowsColorCorrection"] = true}

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not StageAPI or not StageAPI.Loaded then
        Isaac.RenderText("StageAPI is missing (Requirement for Revelations to function)", 100, 52, 255, 255, 255, 1)

        if not shadersWorkaround then
          revel:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, function(_, name)
              if revShaders[name] then return {Active = 0} end
          end)
          shadersWorkaround = true
        end
    end
end)
