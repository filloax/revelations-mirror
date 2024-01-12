local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

local hub2 = require("scripts.hubroom2.init")

_G.hub2 = hub2

hub2.SetDisableSaving(true)

-- hub --

REVEL.DEBUG_HUB_CHAMBERS = false

REVEL.RevHub2Quads = {
	[LevelStage.STAGE1_1] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/glacier_quad.png",
	[LevelStage.STAGE1_2] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/glacier_quad.png",
	[LevelStage.STAGE2_1] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/tomb_quad.png",
	[LevelStage.STAGE2_2] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/tomb_quad.png",
	[LevelStage.STAGE3_1] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/vestige_quad.png",
	[LevelStage.STAGE3_2] = "gfx/backdrop/revelcommon/hubroom_2.0/hubquads/vestige_quad.png"
}

REVEL.Hub2CustomTrapdoors = {
	Glacier = {
		Anm2 = "gfx/backdrop/revelcommon/hubroom_2.0/trapdoors/trapdoor_glacier.anm2"
	},
	Tomb = {
		Anm2 = "gfx/backdrop/revelcommon/hubroom_2.0/trapdoors/trapdoor_tomb.anm2"
	},
	Vestige = {
		Anm2 = "gfx/backdrop/revelcommon/hubroom_2.0/trapdoors/trapdoor_vestige.anm2"
	},
}

local function isRevStage()
	for _,stage in pairs(REVEL.STAGE) do
		if stage:IsStage() then
			return true
		end
	end
	
	return false
end

local function spawnRevTrapdoor(gridIndex)
	local currentStage = StageAPI.GetCurrentStage()
	if not currentStage then REVEL.DebugToString("[WARN] spawnRevTrapdoor | not in stageapi stage, abort") return end

	local stage
	if not currentStage.IsSecondStage then
		local stageName = currentStage.Name .. "Two"
		stage = REVEL.STAGE[stageName]
	else
		local levelgenStage = currentStage.LevelgenStage
		local levelStage = currentStage.StageNumber or (levelgenStage and levelgenStage.Stage or REVEL.level:GetAbsoluteStage())

		local nextStage = currentStage.NextStage

		stage = {
			NormalStage = nextStage.NormalStage,
			Stage = nextStage.Stage,
			StageType = REVEL.SimulateStageTransitionStageType(levelStage + 2 , false)
		}
	end
	
	local trapdoor
	if stage.Name then
		trapdoor = REVEL.Hub2CustomTrapdoors[stage.Name:gsub(" 2", "")]
	end
	
	StageAPI.SpawnCustomTrapdoor(
		REVEL.room:GetGridPosition(gridIndex), 
		stage, 
		trapdoor and trapdoor.Anm2, 
		trapdoor and trapdoor.Size or 24,
		false
	)
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
	if isRevStage() then
		for _, trapdoorData in ipairs(revel.data.run.level.revTrapdoors) do
			if REVEL.level:GetCurrentRoomDesc().ListIndex == trapdoorData.ListIndex then
				spawnRevTrapdoor(trapdoorData.GridIndex)
			end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if REVEL.room:GetFrameCount() == 0
	and StageAPI.GetCurrentRoomType() == hub2.ROOMTYPE_HUBCHAMBER 
	and REVEL.room:IsFirstVisit()
	and REVEL.music:GetCurrentMusicID() ~= REVEL.SFX.HUB_ROOM_STINGER
	then
		REVEL.music:Play(REVEL.SFX.HUB_ROOM_STINGER, Options.MusicVolume)
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if revel.data.oldHubActive == 2 and isRevStage() 
	and StageAPI.GetCurrentRoomType() ~= hub2.ROOMTYPE_HUBCHAMBER then
		for i = 0, REVEL.room:GetGridSize() do
			local grid = REVEL.room:GetGridEntity(i)
			
			if grid and grid.Desc.Type == GridEntityType.GRID_TRAPDOOR and grid:GetSprite():GetFilename() ~= "gfx/grid/voidtrapdoor.anm2" then
				REVEL.room:RemoveGridEntity(i, 0, false)
				REVEL.room:Update()
				
				spawnRevTrapdoor(i)
				
				table.insert(revel.data.run.level.revTrapdoors, {ListIndex=REVEL.level:GetCurrentRoomDesc().ListIndex, GridIndex=i})
			end
		end
	end
end)

function REVEL.SyncHub2IsActive()
	hub2.SetHub2Active(revel.data.oldHubActive == 2)
end

-- hub2 stages --

hub2.AddCustomStageToHub2 (  -- Glacier
	"RevGlacier",
	{
		Stage = REVEL.STAGE.Glacier, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE1_1], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Glacier.Anm2, 
		Conditions = function()
			local levelStage = hub2.GetCorrectedLevelStage()
			return not REVEL.STAGE.Glacier:IsStage()
				and levelStage == LevelStage.STAGE1_1
		end, 
	},
	true,
	LevelStage.STAGE1_2
)

hub2.AddCustomStageToHub2( -- Glacier 2
	"RevGlacier2",
	{
		Stage = REVEL.STAGE.GlacierTwo, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE1_2], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Glacier.Anm2, 
		Conditions = function()
			local levelStage = hub2.GetCorrectedLevelStage()
			return not REVEL.STAGE.Glacier:IsStage()
				and levelStage == LevelStage.STAGE1_2 
		end, 
	},
	true,
	LevelStage.STAGE2_1
)

hub2.AddCustomStageToHub2( -- Tomb
	"RevTomb",
	{
		Stage = REVEL.STAGE.Tomb, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE2_1], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Tomb.Anm2, 
		Conditions = function()
			local levelStage = hub2.GetCorrectedLevelStage()
			return not REVEL.STAGE.Tomb:IsStage()
				and levelStage == LevelStage.STAGE2_1
		end, 
	},
	true,
	LevelStage.STAGE2_2
)
hub2.AddCustomStageToHub2( -- Tomb 2
	"RevTomb2",
	{
		Stage = REVEL.STAGE.TombTwo, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE2_2], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Tomb.Anm2, 
		Conditions = function()
			local levelStage = hub2.GetCorrectedLevelStage()
			return not REVEL.STAGE.Tomb:IsStage()
				and levelStage == LevelStage.STAGE2_2
		end, 
	},
	true,
	LevelStage.STAGE3_1
)
hub2.AddCustomStageToHub2( -- Vestige
	"RevVestige",
	{
		Stage = nil, --REVEL.STAGE.Vestige, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE3_1], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Vestige.Anm2, 
		Conditions = function()
			local levelStage = hub2.GetCorrectedLevelStage()
			return REVEL.STAGE.Tomb:IsStage()
				and levelStage == LevelStage.STAGE3_1
		end, 
	},
	false --true,
	--LevelStage.STAGE3_3
)
hub2.AddCustomStageToHub2( -- Vestige 2
	"RevVestige2",
	{
		Stage = nil, --REVEL.STAGE.VestigeTwo, 
		QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE3_2], 
		TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Vestige.Anm2, 
		Conditions = function()
			--local levelStage = hub2.GetCorrectedLevelStage()
			return false --not StageAPI.InNewStage()
					--and levelStage == LevelStage.STAGE3_2
		end, 
	},
	false --true,
	--LevelStage.STAGE4_1
)

-- statues --

hub2.AddHub2Statue { -- Sarah
	Id = "RevSarah",
	StatueAnm2 = "gfx/backdrop/revelcommon/hubroom_2.0/hub_2.0_statues.anm2",
	StatueAnimation = "Sarah",
	TrinketDrop = TrinketType.TRINKET_ROSARY_BEAD,
	--SoulDrop = Card.CARD_SOUL_,
	ConsumableCount = 1,
	ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_ETERNAL}
}
hub2.AddHub2Statue { -- Dante
	Id = "RevDante",
	StatueAnm2 = "gfx/backdrop/revelcommon/hubroom_2.0/hub_2.0_statues.anm2",
	StatueAnimation = "Dante",
	TrinketDrop = REVEL.ITEM.LIBRARY_CARD.id,
	--SoulDrop = Card.CARD_SOUL_,
	--ConsumableCount = 1,
	--ConsumableDrop = 
}
hub2.AddHub2Statue { -- Charon
	Id = "RevCharon",
	StatueAnm2 = "gfx/backdrop/revelcommon/hubroom_2.0/hub_2.0_statues.anm2",
	StatueAnimation = "Charon",
	TrinketDrop = TrinketType.TRINKET_FOUND_SOUL,
	--SoulDrop = Card.CARD_SOUL_,
	ConsumableCount = 1,
	ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.CARD_WORLD}
}
hub2.AddHub2Statue { -- Bertran
	Id = "RevBertran",
	StatueAnm2 = "gfx/backdrop/revelcommon/hubroom_2.0/hub_2.0_statues.anm2",
	StatueAnimation = "Bertran",
	--TrinketDrop = TrinketType.TRINKET_,
	--ConsumableCount = 1,
	--ConsumableDrop = 
}

-- Add a bunch of stages to debug hub chambers
if REVEL.DEBUG_HUB_CHAMBERS then
	for i = 1, 10 do
		hub2.AddCustomStageToHub2 (  -- Glacier
			"RevGlacierTest" .. i,
			{
				Stage = REVEL.STAGE.Glacier, 
				QuadPng = REVEL.RevHub2Quads[LevelStage.STAGE1_1], 
				TrapdoorAnm2 = REVEL.Hub2CustomTrapdoors.Glacier.Anm2, 
				Conditions = function()
					return true
				end, 
			},
			true,
			LevelStage.STAGE1_2
		)	
	end
end

Isaac.DebugString("Revelations: Loaded Hub Room 2.0!")
end