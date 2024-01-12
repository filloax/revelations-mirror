local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
local StageAPICallbacks = require "lua.revelcommon.enums.StageAPICallbacks"
return function()

---------------------------
-- UPDATE ROOM AND LEVEL --
---------------------------

local function updateSharedVariables()
	REVEL.DebugStringMinor("Updating REVEL.room,REVEL.level")

    REVEL.room = REVEL.game:GetRoom()
    REVEL.level = REVEL.game:GetLevel()
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_STAGEAPI_LOAD_SAVE, -900, updateSharedVariables)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, -900, updateSharedVariables)
revel:AddPriorityCallback(RevCallbacks.POST_BASE_PLAYER_INIT, -900, updateSharedVariables)
if Isaac.GetPlayer(0) then --reloaded
    updateSharedVariables()
end
  
function revel:UpdateCollSize()
	local counter = CollectibleType.NUM_COLLECTIBLES
	while true do
		local item = REVEL.config:GetCollectible(counter)
		if not item then
			REVEL.collectiblesSize = counter - 1
			break
		else
			counter = counter + 1
		end
	end
end
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, revel.UpdateCollSize)

function revel:LoadConfigItems()
	for _,name in pairs(REVEL.ITEMS_MAP) do
		REVEL.REGISTERED_ITEMS[name].ConfigItem = REVEL.config:GetCollectible(REVEL.REGISTERED_ITEMS[name].id)
	end

	REVEL.loadedConfigItems = true
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, revel.LoadConfigItems)
if Isaac.GetPlayer(0) then
	revel:LoadConfigItems()
end


end