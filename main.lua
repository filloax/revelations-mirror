local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"

_G.revel = RegisterMod("Revelations",1)

_G.REVEL = {
    DEBUG = false,
    Testmode = false,
  
    VERSION = "4.3.1",
  
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

require("scripts.revelations.libraries.sources.apioverride")

---------------------------
-- TRACK ADDED CALLBACKS --
---------------------------
local PatchMod_TrackAddedCallbacks = include("scripts.revelations.common.patches.callback_track")

PatchMod_TrackAddedCallbacks(revel)

--------------------------
-- PERFORMANCE DIAGNOSTICS
--------------------------

-- moved to own file with new callbacks system

-- local PatchMod_PerformanceMetrics = include("scripts.revelations.common.patches.performance_metrics")

-- if REVEL.DO_DEBUG_METRICS then
--     PatchMod_PerformanceMetrics(revel)
-- end

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

REVEL.Modules = include("scripts.revelations.loadorder")

REVEL.LoadFunctions = {}

---Keep a local cache of modules that still resets with luamod (unlike require)
---@type table<string, Rev.ModuleData>
local LoadedModules = {}
-- Used to check for recursion
---@type string[]
local LoadModuleStack = {}

if REVEL.DEBUG then
    -- expose for debug
    REVEL.LoadedModules = LoadedModules
end

---@class Rev.ModuleData : table
---@field LoadFunction fun()? # Will be executed only once per mod load. Can be nil, as some modules do not have load functions (e.g. initialization side-effects only).
---@field Loaded boolean # Has the load function been executed? (If no function, will just be true)

local function includes(list, val)
    for _, v in ipairs(list) do
        if v == val then
            return true
        end
    end
    return false
end

-- Modules that contain an older no-repentogon alternative if repentogon is not loaded
local NoRepentogonAltModules = require("scripts.revelations.norpgn.no_repentogon_files")
local NoRepentogonAltModulesSet = {}
for i, v in ipairs(NoRepentogonAltModules) do NoRepentogonAltModulesSet[v] = true end

---@return string modulePath
---@return boolean changed
local function AdjustPathNoRepentogon(modulePath)
    if not REPENTOGON and NoRepentogonAltModulesSet[modulePath] then
        return modulePath:gsub("scripts.revelations.", "scripts.revelations.norpgn."), true
    end
    return modulePath, false
end

---Load a module, placing it in the cache at LoadedModules
---@param modulePath string
---@return boolean success
---@return Rev.ModuleData? moduleData
---@return string modulePath
local function LoadModule(modulePath)
    if LoadedModules[modulePath] then
        Isaac.DebugString("[WARN] Module is being loaded twice!")
        return true, LoadedModules[modulePath], modulePath
    end

    -- Check recursive loads
    if includes(LoadModuleStack, modulePath) then
        local stackStr = ""
        for _, mod in ipairs(LoadModuleStack) do stackStr = stackStr .. mod .. ", " end
        error("Recursive load calls when loading module " .. modulePath .. ", stack is [" .. stackStr .. "]. " .. 
            "Try moving some of the calls to REVEL.Module inside of the load functions or use REVEL.LazyProxy (see REVEL.Module luadoc)", 
            2
        )
    end
    LoadModuleStack[#LoadModuleStack+1] = modulePath

    local success, ret = pcall(include, modulePath)
    local loadFunction = nil

    LoadModuleStack[#LoadModuleStack] = nil

    if #REVEL.LoadFunctions > 0 then
        loadFunction = REVEL.LoadFunctions[1]
        Isaac.DebugString("[WARN] Module " .. modulePath .. " uses deprecated LoadFunctions method of setting load function")

        -- Clear, not supposed to be used
        REVEL.LoadFunctions = {}
    end

    if not success then
        Isaac.DebugString("Failed to load module: " .. tostring(ret))
        Isaac.ConsoleOutput("Failed to load module: " .. tostring(ret) .. "\n")
        return false, nil, modulePath
    end

    if not loadFunction and type(ret) == "function" then
        loadFunction = ret
    end
    if not loadFunction and type(ret) == "table" then
        loadFunction = ret.LoadFunction
        if loadFunction and type(loadFunction) ~= "function" then
            loadFunction = nil
            Isaac.DebugString("[ERR] Table LoadFunction for module " .. modulePath .. " is not function!")
            return false, nil, modulePath
        end
    end

    local moduleData
    if type(ret) == "table" then
        ret.Loaded = false
        moduleData = ret
    else
        moduleData = {
            Loaded = false,
        }
    end

    -- Some modules intentionally have no load function, just do nothing there
    if loadFunction then
        local function wrappedLoadFunction()
            if not moduleData.Loaded then
                loadFunction()
            else
                Isaac.DebugString("[WARN] Tried to run load function twice for module " .. modulePath)
            end
        end
        moduleData.LoadFunction = wrappedLoadFunction
    else
        moduleData.Loaded = true -- no load function to run, so already loaded
    end

    LoadedModules[modulePath] = moduleData
    return true, moduleData, modulePath
end

---Get the table of a given module, at minimum containing
-- its LoadFunction, but also any other field in its returned table.
-- Will load the module if not loaded yet.
--
-- Note that recursive loads between modules will error, unless you either
-- put the load calls of one of the two modules inside its load function, or
-- use `REVEL.LazyProxy` (see basiclibrary.lua).
---@param modulePath string
---@return Rev.ModuleData
function REVEL.Module(modulePath)
    local path, pathChanged = AdjustPathNoRepentogon(modulePath)
    modulePath = path

    if not LoadedModules[modulePath] then
        if pathChanged then
            Isaac.DebugString("Using alt no-repentogon module for " .. modulePath)
        end
        LoadModule(modulePath)
    end
    return LoadedModules[modulePath]
end

--[[
    Generalization of the previous loading code to allow modules to load
    more modules on their own (for entity file management and similar).

    Every module must return either a function to load, or a table containing a LoadFunction field
    in case it returns other things for require purposes.

    For retrocompatibility, it still allows using the REVEL.LoadFunctions table like before.
]] 
---@param modules string[]
---@return fun()[]
function REVEL.LoadModulesFromTable(modules)
    REVEL.LoadFunctions = {}

    local loadFunctions = {}
    local loadCounter = 0

    if REVEL.PCALL_WORKAROUND then
        Isaac.DebugString("[WARN] PCALL_WORKAROUND not needed since Repentance")
    end

    for i, modulePath in ipairs(modules) do
        local path, pathChanged = AdjustPathNoRepentogon(modulePath)
        modulePath = path
    
        local success = false
        if LoadedModules[modulePath] then
            success = true
        else
            if pathChanged then
                Isaac.DebugString("Using alt no-repentogon module for " .. modulePath)
            end
            success = LoadModule(modulePath)
        end
        if success then
            loadCounter = loadCounter + 1
            local loadFunction = LoadedModules[modulePath].LoadFunction
            if loadFunction then
                loadFunctions[#loadFunctions+1] = loadFunction
            end
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
    end

    return loadFunctions
end

local MainLoadFunctions = REVEL.LoadModulesFromTable(REVEL.Modules)
Isaac.DebugString("Revelations: Finished initial loading! Version " .. REVEL.VERSION)

---@param funcs fun()[]
function REVEL.RunLoadFunctions(funcs, ...)
    for _, fn in ipairs(funcs) do
        local success, err = pcall(fn, ...)
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
        REVEL.LoadModData()

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
