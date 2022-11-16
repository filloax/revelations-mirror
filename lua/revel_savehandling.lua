local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local LoadedData = false

local LastRunResetDataFrame = -1

local json = require("json")
local hub2 = require("scripts.hubroom2.init") --hub2 savedata table is seperately stored

REVEL.PRINT_MODDATA_ON_LOAD = false

local DoResetSaveData = false

function REVEL.IsSaveDataLoaded()
    return LoadedData
end

---@param force? boolean
---@param continuedRun? boolean
function revel:loadModdata(force, continuedRun)
    if not LoadedData or force then --if moddata wasn't properly loaded yet
        local readTime, decodeTime
        local t1 = Isaac.GetTime()
        local data
        local firstLoad

        if Isaac.HasModData(revel) and not DoResetSaveData then
            local dataStr = Isaac.LoadModData(revel)
            local t2 = Isaac.GetTime()
            data = json.decode(dataStr)
            local t3 = Isaac.GetTime()
            readTime = t2 - t1
            decodeTime = t3 - t2

            -- Isaac.DebugString("dataStr:\n" .. dataStr)

            if not data then
                data = { run = { level = { room = {} }}, unlockValues = {} }
            end
        else
            data = { run = { level = { room = {} }}, unlockValues = {} }
            firstLoad = true
            if DoResetSaveData then
                DoResetSaveData = false
                REVEL.DebugLog("############################################")
                REVEL.DebugLog("[REVEL] Reset all of Revelation's save data!")
                REVEL.DebugLog("############################################")
            end
        end

        local prevKeys = REVEL.keys(data)

        data = REVEL.CopyTable(data, REVEL.DEFAULT_MODDATA) --fill missing variables in case there are some

        local newKeys = REVEL.keys(data)

        for _, key in ipairs(newKeys) do
            if not REVEL.includes(prevKeys, key) then
                REVEL.DebugToString("New mod data entry: " .. tostring(key))
            end
        end

        local changedFromOldFormat
        local newUnlockValues = {}
        for name, a in pairs(data.unlockValues) do
            if type(a) == "table" then
                changedFromOldFormat = true
                newUnlockValues[name] = a.unlocked
            end
        end

        if changedFromOldFormat then
            Isaac.DebugString("[REVEL] Changed from old achievement format. This shouldn't happen more than once.")
            data.unlockValues = newUnlockValues
        end

        revel.data = data

        local t4 = Isaac.GetTime()

        if readTime then
            Isaac.DebugString("Revelations: Loaded Moddata in " .. ((t4 - t1)/1000) .. 
                "s, of which file loading is " .. ((readTime)/1000) .. "s and decoding is " .. ((decodeTime)/1000))
        else
            Isaac.DebugString("Revelations: Loaded Moddata in " .. ((t4 - t1)/1000) .. "s, new save")
        end
        if REVEL.PRINT_MODDATA_ON_LOAD then
            Isaac.DebugString("It is: "..table_tostring(revel.data or {"not avaiable"}))
        end

        if REVEL.UsingIntegratedMinimapAPI() then
            if firstLoad then
                data.minimapapi = REVEL.GetMinimapAPISaveData()
                REVEL.LoadMinimapAPIFirstLoad(data)
            else
                REVEL.LoadMinimapAPISaveData(data, REVEL.game:GetFrameCount() > 2)
            end
        end
		
		if revel.data.hub2 then
			hub2.LoadSaveData(revel.data.hub2)
		end

        revel:saveData()

        StageAPI.CallCallbacks(RevCallbacks.POST_SAVEDATA_LOAD)

        LoadedData = true
    end
end

function REVEL.ResetSaveData()
    REVEL.DebugLog("[REVEL] Resetting mod data...")

    DoResetSaveData = true
    revel:loadModdata(true)
    revel:saveData()
end

setmetatable(revel,
{
	__index = function(t, k)
		if k == "data" then
            error("[REVEL] Tried to access unloaded mod data, this shouldn't really happen" .. REVEL.TryGetTraceback(false, true))
			-- revel:loadModdata()
			-- return revel.data
		end
	end
})

local IgnoreNumberDictNum = 4 -- for player-related stuff

local function CheckDataTable(tbl)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            CheckDataTable(v)
        elseif type(k) == "number" and k > #tbl and k > IgnoreNumberDictNum then -- number index in non array
            REVEL.DebugLog("[REVEL] WARN: Saving non-continuous number-indexed table to mod data, might lead to lag spikes on load")
            REVEL.DebugLog("           - key:", k, "| value:", v, " table:", tbl)
        end
    end
end

local function CheckSavingData(data)
    CheckDataTable(data)
end

function revel:saveData(menuExit)
    local data = revel.data

    if REVEL.UsingIntegratedMinimapAPI() then
        data.minimapapi = REVEL.GetMinimapAPISaveData(menuExit)
    end
	
	data.hub2 = hub2.GetSaveData()
    
    CheckSavingData(data)

    local t1 = Isaac.GetTime()
    local dataStr = json.encode(data)
    local t2 = Isaac.GetTime()
    Isaac.SaveModData(revel, dataStr)
    local t3 = Isaac.GetTime()

--    REVEL.DebugToString(json.encode(data))

    if REVEL.DEBUG then 
        Isaac.DebugString("Revelations: Saved Moddata in " .. ((t3-t1)/1000) .. 
            "s (Encoding: " .. ((t2-t1)/1000) .. "s, Writing: " .. ((t3-t2)/1000) .. "s)!") 
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.game:GetFrameCount() % 200 == 0 then
        revel:saveData()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function()
    revel:loadModdata(false)

    if REVEL.game:GetFrameCount() == 0 then 
        REVEL.DebugToString("[REVEL] Resetting run save data")
        revel.data.run = REVEL.CopyTable(REVEL.DEFAULT_MODDATA.run)
    end
end)
revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function()
    revel:loadModdata(false)
end)
StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_LOAD_SAVE, 1, function()
    revel:loadModdata(false)
end)

revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, menuExit)
    if LoadedData then
        revel:saveData(menuExit)
        --reset data so it will be loaded correctly in case the save is switched
        revel.data = {}
        LoadedData = false
        REVEL.DebugToString("[REVEL] Run exit, unloaded data")
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -100, function()
    if REVEL.room:IsFirstVisit() and REVEL.level:GetCurrentRoomIndex() == REVEL.level:GetStartingRoomIndex() then
        REVEL.DebugToString("[REVEL] Resetting level save data")
        revel.data.run.level = REVEL.CopyTable(REVEL.DEFAULT_MODDATA.run.level)
    end

    REVEL.DebugStringMinor("[REVEL] Resetting room save data")
    revel.data.run.level.room = REVEL.CopyTable(REVEL.DEFAULT_MODDATA.run.level.room)
end)

Isaac.DebugString("Revelations: Loaded Save Handling!")
end