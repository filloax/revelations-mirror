local hub2 = require "scripts.hubroom2"

local json = require "json"
local hasRunDataResetThisFrame = false

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

hub2.data = hub2.DefaultData

function hub2.GetSaveData()
	return hub2.data
end

function hub2.LoadSaveData(newSaveTable)
	hub2.data = newSaveTable
	
	if hasRunDataResetThisFrame then
		hub2.data.run = hub2.DefaultData.run
	end
end

function hub2.SetDisableSaving(disableSaving)
	hub2.DisableSaving = disableSaving
end

hub2:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
	if not hub2.DisableSaving and not hub2.LoadedData then
		if hub2:HasData() then
			hub2.data = json.decode(Isaac.LoadModData(hub2))
		end
		
		hub2.LoadedData = true
	end
	
	if not continued then
		hasRunDataResetThisFrame = true
		hub2.data.run = hub2.DefaultData.run
	end
end)

hub2:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
	if not hub2.DisableSaving then
		Isaac.SaveModData(hub2, json.encode(hub2.data))
	end
end)

hub2:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	hub2.data.run.level = hub2.DefaultData.run.level
end)

hub2:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	hasRunDataResetThisFrame = false
end)