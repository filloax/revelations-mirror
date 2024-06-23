local hub2 = require "scripts.hubroom2"
local json = require "json"

local HasRunDataResetThisFrame = false

hub2.DisableSaving = false
hub2.LoadedData = false

hub2.DefaultData = {
	run = {
		level = {
		
		},
		unlockedTrinkets = {},
		unlockedCards = {},
		trinketHistory = {}
	},
	isHub2Active = true
}

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
	if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

hub2.data = deepcopy(hub2.DefaultData)

---@param stringifyIds? boolean If should convert int-key tables to string-key tables (for example redundant when passed to StageAPI serialization)
---@return table
function hub2.GetSaveData(stringifyIds)
	if stringifyIds then
		return StageAPI.SaveTableMarshal(hub2.data, "Hub2Data")
	else
		return deepcopy(hub2.data)
	end
end


local function convertOldStringIndices(tbl, path)
    local t = tbl
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    for i = 1, #parts - 1 do
        t = t[parts[i]]
    end

    local target = parts[#parts]
    local targetTable = t[target]

    if targetTable then
        local isAllKeysNumbers = true
        local newTable = {}

        for k, v in pairs(targetTable) do
            if type(k) ~= "number" then
                isAllKeysNumbers = false
                break
            end

            newTable[k] = v
        end

        if isAllKeysNumbers then
            t[target] = newTable
        end
    end
end

---@param newSaveTable table Loaded data passed from another mod
---@param stringifyIds? boolean If should convert saved string-key tables to int-key tables (for example redundant when passed to StageAPI serialization)
function hub2.LoadSaveData(newSaveTable, stringifyIds)
	local data
	if stringifyIds then
		data = StageAPI.SaveTableUnmarshal(hub2.data, "Hub2Data")
	else
		data = deepcopy(newSaveTable)

		-- double check for string tables (old version data)
		for _, v in ipairs({
			"run.unlockedTrinkets",
			"run.unlockedCards",
			"run.level.hub2Statues",
		}) do
			convertOldStringIndices(data, v)
		end
	end

	hub2.data = data

	if HasRunDataResetThisFrame then
		hub2.data.run = deepcopy(hub2.DefaultData.run)
	end
end

function hub2.SetDisableSaving(disableSaving)
	hub2.DisableSaving = disableSaving
end

hub2:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
	if not hub2.DisableSaving and not hub2.LoadedData then
		if hub2:HasData() then
			hub2.LoadSaveData(json.decode(Isaac.LoadModData(hub2)), true)
		end
		
		hub2.LoadedData = true
	end
	
	if not continued then
		HasRunDataResetThisFrame = true
		hub2.data.run = hub2.DefaultData.run
	end
end)

hub2:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
	if not hub2.DisableSaving then
		Isaac.SaveModData(hub2, json.encode(hub2.GetSaveData(true)))
	end
end)

hub2:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	hub2.data.run.level = hub2.DefaultData.run.level
end)

hub2:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	HasRunDataResetThisFrame = false
end)