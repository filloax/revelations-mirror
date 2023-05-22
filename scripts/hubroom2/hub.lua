local hub2 = require "scripts.hubroom2"

local game = Game()
local sfx = SFXManager()
local music = MusicManager()

---@class Hub2.Entry
---@field Id string
---@field Stage CustomStage
---@field QuadPng string?
---@field Quad string
---@field TrapdoorAnm2 string?
---@field TrapdoorSize integer?
---@field Conditions (fun(): boolean)?
---@field DisableTrapdoor boolean

---@type Hub2.Entry[]
hub2.CustomStagesInHub2 = {}
hub2.CustomStagesContainingHub2 = {}

-- Rooms of RoomType 27 are alt-path transition rooms (not present in RoomType enum)
local ROOMTYPE_TRANSITION = 27

local ROOMTYPE_HUBCHAMBER = "Hub2Chamber"

hub2.ROOMTYPE_HUBCHAMBER  = ROOMTYPE_HUBCHAMBER

local MAIN_CHAMBER_ID = "Hub2_MainChamber"

local CustomStagesIndicesById = {}

local EntryFields = {
	"Stage", 
	"Quad",
	"QuadPng",
	"TrapdoorAnm2",
	"TrapdoorSize",
	"Conditions",
	"DisableTrapdoor",
}

---@param id string
---@param stage CustomStage
---@param quadPng? string
---@param trapdoorAnm2? string
---@param trapdoorSize? integer
---@param stageConditions? fun(): boolean # gets called upon first entering hub2.0 for the first time each level. Returning true will add the stage to that hub2.0
---@param addHub2ToStage? boolean
---@param levelStage? LevelStage 
---@overload fun(id: string, entry: Hub2.Entry, addHub2ToStage?: boolean, addStage?: LevelStage)
function hub2.AddCustomStageToHub2(id, stage, quadPng, trapdoorAnm2, trapdoorSize, stageConditions, addHub2ToStage, levelStage)
	local quad = quadPng or "gfx/backdrop/hubroom_2.0/hubquads/closet_quad.png"
	
	---@type Hub2.Entry
	local entry

	if type(stage) == "table" then
		entry = {
			Id = id,
		}
		for _, key in ipairs(EntryFields) do
			entry[key] = stage[key]
		end
		addHub2ToStage = quadPng
		levelStage = trapdoorAnm2
	else
		entry = {
			Id = id,
			Stage = stage,
			QuadPng = quad,
			TrapdoorAnm2 = trapdoorAnm2,
			TrapdoorSize = trapdoorSize,
			Conditions = stageConditions,
			DisableTrapdoor = stage == nil
		}
	end
	entry.TrapdoorAnm2 = entry.TrapdoorAnm2 or "gfx/grid/door_11_trapdoor.anm2"
	if entry.DisableTrapdoor == nil then
		entry.DisableTrapdoor = entry.Stage == nil
	end

	-- replace if already existing (mod reload?)
	local index = CustomStagesIndicesById[entry.Id]
	if index then
		hub2.CustomStagesInHub2[index] = entry
	else
		index = #hub2.CustomStagesInHub2 + 1
		hub2.CustomStagesInHub2[index] = entry
		CustomStagesIndicesById[entry.Id] = index
	end
	
	if addHub2ToStage and entry.Stage then
		hub2.AddHub2ToCustomStage(entry.Stage, entry.QuadPng, levelStage)
	end
end

---@param stage CustomStage
function hub2.AddHub2ToCustomStage(stage, quadPng, levelStage)
	hub2.CustomStagesContainingHub2[stage.Name] = {
		QuadPng = quadPng,
		LevelStage = levelStage
	}

	-- Do not add if IsSecondStage, otherwise it would
	-- override the entry set by the first stage
	if stage.XLStage and not stage.IsSecondStage then
		hub2.CustomStagesContainingHub2[stage.XLStage.Name] = {
			QuadPng = quadPng,
			LevelStage = levelStage + 1
		}
	end
end

function hub2.SetHub2Active(isHub2Active)
	hub2.data.isHub2Active = isHub2Active
end

function hub2.IsRepStage()
	local stageType = game:GetLevel():GetStageType()
	
	return stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B
end

local function PlayerIsLost(player)
    return player:GetPlayerType() == PlayerType.PLAYER_THELOST
        or player:GetPlayerType() == PlayerType.PLAYER_THELOST_B
        or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B
        or player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B
        or player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
end

local tombMausoleumDoorPayments = 0

local function mausoleumDoorUpdate(door, isInit)
	local sprite = door:GetSprite()
	
	if isInit then
		local anim = sprite:GetAnimation()
		
		sprite:Load(hub2.RepHub2Doors.Mausoleum, true)

		if door:IsLocked() then
			door:TryUnlock(Isaac.GetPlayer(0), true)
		end
		
		if tombMausoleumDoorPayments < 2 then
			door.CollisionClass = GridCollisionClass.COLLISION_WALL
			sprite:SetFrame("KeyClosed", 0)
			
		else
			sprite:SetFrame("Opened", 0)
		end
	end
	
	-- mausoleum door not fully paid yet
	if tombMausoleumDoorPayments < 2 then
		door.CollisionClass = GridCollisionClass.COLLISION_WALL
		
		local sprite = door:GetSprite()

		if sprite:IsEventTriggered("Sound") then
			sfx:Play(SoundEffect.SOUND_UNLOCK00)
		end
		
		if not sprite:IsPlaying("Feed") then
			for i=0, game:GetNumPlayers() - 1 do
				local player = Isaac.GetPlayer(i)
				
				if player.Position:Distance(door.Position) <= 30 + player.Size then
					if PlayerIsLost(player) then
						tombMausoleumDoorPayments = 2
						sprite:Play("KeyOpen", true)
						door.CollisionClass = GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER

					elseif player:TakeDamage(2, DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 0) then
						tombMausoleumDoorPayments = tombMausoleumDoorPayments + 1
						
						if tombMausoleumDoorPayments == 2 then
							sprite:Play("KeyOpen", true)
							door.CollisionClass = GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER
						else
							sprite:Play("Feed", true)
						end
					end
				end
			end
		end
	end
end

---@param includeDepthsDoor? boolean
---@return boolean
function hub2.IsTransitionRoom(includeDepthsDoor)
	return game:GetRoom():GetType() == ROOMTYPE_TRANSITION
		and (includeDepthsDoor or game:GetLevel():GetStage() ~= LevelStage.STAGE3_2)
end

local EMPTY_LAYOUT = StageAPI.CreateEmptyRoomLayout(RoomShape.ROOMSHAPE_1x1)
local LAYOUT_NAME = "Hub2_RoomLayout"
StageAPI.RegisterLayout(LAYOUT_NAME, EMPTY_LAYOUT)

local function MakeHubChamberRoom()
	return StageAPI.LevelRoom {
		LayoutName = LAYOUT_NAME,
		Shape = RoomShape.ROOMSHAPE_1x1,
		RoomType = ROOMTYPE_HUBCHAMBER,
		IsExtraRoom = true,
		Music = hub2.SFX.HUB_ROOM,
	}
end

hub2.ChamberDoor = StageAPI.CustomDoor("Hub2Chamber", "gfx/grid/hubroom_2.0/door_chamber.anm2")
---@type table<string, CustomDoor>
hub2.RepDoors = {
	Downpour = StageAPI.CustomDoor("Hub2Downpour", hub2.RepHub2Doors.Downpour),
	Mines = StageAPI.CustomDoor("Hub2Mines", hub2.RepHub2Doors.Mines),
	Mausoleum = StageAPI.CustomDoor("Hub2Mausoleum", hub2.RepHub2Doors.Mausoleum),
}

local CheckedOutDoorSlots = {}

local function ShouldRemoveTransitionDoor()
	if room:GetType() == RoomType.ROOM_BOSS and StageAPI.InOverriddenStage() then
		local currentStage = StageAPI.GetCurrentStage()
		return currentStage and not hub2.CustomStagesContainingHub2[currentStage.Name]
	end

	return false
end

function hub2.UpdateHub2Doors()
	local room = game:GetRoom()
	local level = game:GetLevel()
	
	-- Remove transition room door if custom stage without hub
	if ShouldRemoveTransitionDoor() then
		for slot=DoorSlot.LEFT0, DoorSlot.DOWN1 do
			local door = room:GetDoor(slot)
			if door and door.TargetRoomType == ROOMTYPE_TRANSITION then
				room:RemoveDoor(slot)
				hub2.LogMinor("Removed Door at slot ", slot)
			end
		end
		return
	end

	-- Replace doors
	if room:GetType() == RoomType.ROOM_BOSS or hub2.IsTransitionRoom() then
		local levelStage = hub2.GetCorrectedLevelStage()
		
		-- mausoleum door (instead of mines door)
		if levelStage == LevelStage.STAGE3_1 then
			for slot=DoorSlot.LEFT0, DoorSlot.DOWN1 do
				local door = room:GetDoor(slot)
				
				if door then
					if door.TargetRoomType == ROOMTYPE_TRANSITION then
						hub2.Hub2BossRoomIndex = level:GetCurrentRoomIndex()
						
						if not CheckedOutDoorSlots[slot] then
							mausoleumDoorUpdate(door, true)

							CheckedOutDoorSlots[slot] = true
							
						else
							mausoleumDoorUpdate(door, false)
						end
					end
				end
			end
			
		else
			for slot=DoorSlot.LEFT0, DoorSlot.DOWN1 do
				local door = room:GetDoor(slot)
				
				if door then
					if door.TargetRoomType == ROOMTYPE_TRANSITION and not CheckedOutDoorSlots[slot] then
						if StageAPI.InNewStage() and levelStage%2 == 0 or not door:IsLocked() then
							local stageName = hub2.RepHub2Quads[levelStage]:gsub("^%l", string.upper)
							
							local anim = door:GetSprite():GetAnimation()
							
							door:GetSprite():Load(hub2.RepHub2Doors[stageName], true)
							door:GetSprite():Play(anim, true)
							door:GetSprite():SetLastFrame()
							
							if door:IsLocked() then
								door:TryUnlock(Isaac.GetPlayer(0), true)
							end
						end

						CheckedOutDoorSlots[slot] = true
					end
				end
			end
		end
	end
end

function hub2.GetCorrectedLevelStage()
	local level = game:GetLevel()
	local levelStage = level:GetAbsoluteStage()
	
	if hub2.HasBit(level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH) then
		levelStage = levelStage + 1
	end
	
	if StageAPI.InNewStage() then
		---@type CustomStage
		local stage = StageAPI.GetCurrentStage()
		
		if hub2.CustomStagesContainingHub2[stage.Name] and hub2.CustomStagesContainingHub2[stage.Name].LevelStage then
			levelStage = hub2.CustomStagesContainingHub2[stage.Name].LevelStage
		end

	elseif hub2.IsRepStage() then
		levelStage = levelStage + 1
	end
	
	return levelStage
end

local function generateHub2Layout(levelStage, entranceDoorSlot)
	local level = game:GetLevel()
	
	local hub2Slots
	if StageAPI.InNewStage() then
		---@type CustomStage
		local stage = StageAPI.GetCurrentStage()
		if levelStage%2 == 0 then -- first floor
			hub2Slots = {
				{
					[entranceDoorSlot] = {
						-- set both, usually one of these is nil
						Quad = hub2.CustomStagesContainingHub2[stage.Name].Quad,
						QuadPng = hub2.CustomStagesContainingHub2[stage.Name].QuadPng,
						BossDoor = true
					},
					[(entranceDoorSlot+1)%4] = {
						Quad = hub2.VanillaHub2Quads[levelStage + 1] or "closet",
						Trapdoor = hub2.VanillaHub2Quads[levelStage + 1] and "vanilla"
					},
					[(entranceDoorSlot+3)%4] = {
						Quad = hub2.RepHub2Quads[levelStage] or "closet",
						Trapdoor = hub2.RepHub2Quads[levelStage] and "rep"
					}
				}
			}
		else -- second floor
			hub2Slots = {
				{
					[entranceDoorSlot] = {
						Quad = hub2.CustomStagesContainingHub2[stage.Name].Quad,
						QuadPng = hub2.CustomStagesContainingHub2[stage.Name].QuadPng,
						BossDoor = true
					},
					[(entranceDoorSlot+1)%4] = {
						Quad = hub2.RepHub2Quads[levelStage],
						Trapdoor = "rep"
					}
				}
			}

		end
	
	elseif hub2.IsRepStage() then
		hub2Slots = {
			{
				[entranceDoorSlot] = {
					Quad = hub2.RepHub2Quads[levelStage],
					BossDoor = true
				},
				[(entranceDoorSlot+1)%4] = {
					Quad = hub2.RepHub2Quads[levelStage],
					Trapdoor = "rep"
				}
			}
		}
		
	else
		hub2Slots = {
			{
				[entranceDoorSlot] = {
					Quad = hub2.VanillaHub2Quads[levelStage],
					BossDoor = true
				},
				[(entranceDoorSlot+1)%4] = {
					Quad = hub2.RepHub2Quads[levelStage],
					Trapdoor = "rep"
				}
			}
		}
	end
	
	hub2.Hub2MainChamberRoomIndex = level:GetCurrentRoomIndex()
	
	local customStagesToAdd = {}
	for _,customStage in ipairs(hub2.CustomStagesInHub2) do
		if not customStage.Conditions or customStage.Conditions() then
			table.insert(customStagesToAdd, customStage)
		end
	end
	
	local numChambers = math.floor((#customStagesToAdd + 2)/2)
	for chamberId=1, numChambers do
		if not hub2Slots[chamberId] then
			hub2Slots[chamberId] = {}
		end
		
		-- add doors to previous chambers
		if chamberId ~= 1 and not hub2Slots[chamberId][entranceDoorSlot] then
			hub2Slots[chamberId][entranceDoorSlot] = {
				Quad = "closet",
				Door = chamberId - 1
			}
		end
		
		-- add doors to upcoming chambers
		if chamberId ~= numChambers and not hub2Slots[chamberId][(entranceDoorSlot+2)%4] then
			hub2Slots[chamberId][(entranceDoorSlot+2)%4] = {
				Quad = "closet",
				Door = chamberId + 1
			}
		end
		
		-- setup LevelRoom
		if chamberId ~= 1 then
			local chamber = MakeHubChamberRoom()
			StageAPI.GetDefaultLevelMap():AddRoom(chamber, {RoomID = "Hub2.0_Chamber_" .. tostring(chamberId)})
		end
	end
	
	for _,customStage in ipairs(customStagesToAdd) do
		for _,hubChamber in ipairs(hub2Slots) do
			local addQuad = false
			for slot=DoorSlot.LEFT0, DoorSlot.DOWN0 do
				if not hubChamber[slot] then
					hubChamber[slot] = customStage
					addQuad = true
					break
				end
			end
			
			if addQuad then
				break
			end
		end
	end
	
	-- empty quads get changed into empty closet quads
	for _,hubChamber in ipairs(hub2Slots) do
		for slot=DoorSlot.LEFT0, DoorSlot.DOWN0 do
			if not hubChamber[slot] then
				hubChamber[slot] = {
					Quad = "closet"
				}
			end
		end
	end
	
	return hub2Slots
end

local function WarpToMainChamber(entranceSlot)
	hub2.LogDebug("Warping to main chamber from entrance slot ", entranceSlot)

	local defaultMap = StageAPI.GetDefaultLevelMap()
	local extraRoomData = defaultMap:GetRoomDataFromRoomID(MAIN_CHAMBER_ID)
	local extraRoom

	if not extraRoomData then
		extraRoom = MakeHubChamberRoom()
		extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = MAIN_CHAMBER_ID})
	else
		---@type LevelRoom
		extraRoom = defaultMap:GetRoom(extraRoomData)
	end

	-- Save entrance slot, as the extra room starts with no doors
	extraRoom.PersistentData.EntranceDoorSlot = entranceSlot
	
	-- -1 = instant warp
	StageAPI.ExtraRoomTransition(
		extraRoomData.MapID, 
		nil, 
		-1, 
		StageAPI.DefaultLevelMapID,
		(entranceSlot + 2) % 4,
		entranceSlot
	)
end

StageAPI.AddCallback("Hub2.0", "PRE_STAGEAPI_NEW_ROOM", 1, function()
	local level = game:GetLevel()
	local room = game:GetRoom()

	for _,eff in ipairs(hub2.Hub2StatueEffects) do
		eff:Remove()
	end
	hub2.Hub2StatueEffects = {}
	CheckedOutDoorSlots = {}
	
	if room:GetType() == RoomType.ROOM_BOSS 
	then
		hub2.Hub2BossRoomIndex = level:GetCurrentRoomIndex()
	end
end)

---@param room Room
---@param levelRoom LevelRoom
---@param isFirstLoad boolean
function hub2.LoadHub2(room, levelRoom, isFirstLoad)
	local levelStage = hub2.GetCorrectedLevelStage()
	local entranceDoorSlot = levelRoom.PersistentData.EntranceDoorSlot

	hub2.LogDebug("Transforming room to hub 2, entranceDoorSlot=", entranceDoorSlot, ", current ID: ", StageAPI.GetCurrentRoomID())
	
	if not hub2.Hub2Slots then
		hub2.Hub2Slots = generateHub2Layout(levelStage, entranceDoorSlot)
	end
	
	local currentHubChamber = hub2.Hub2Slots[hub2.CurrentSelectedHub2ChamberId]
	hub2.LogMinor("Selected chamber ", hub2.CurrentSelectedHub2ChamberId, ", hub stage is ", levelStage)
	hub2.SetUpHub2Background(currentHubChamber)

	-- spawn new trapdoors
	for slot=DoorSlot.LEFT0, DoorSlot.DOWN0 do	
		if currentHubChamber[slot].Trapdoor or currentHubChamber[slot].TrapdoorAnm2 then
			local stageName
			if currentHubChamber[slot].Trapdoor == "rep" then
				stageName = hub2.RepHub2Quads[levelStage]:gsub("^%l", string.upper)
			end
			
			local trapdoor = hub2.Hub2CustomTrapdoors[stageName]
			
			local stage
			if currentHubChamber[slot].Stage then
				stage = currentHubChamber[slot].Stage
			else
				stage = {
					NormalStage = true,
					Stage = currentHubChamber[slot].Trapdoor == "vanilla" and levelStage + 1 or levelStage,
					StageType = hub2.SimulateStageTransitionStageType(levelStage + levelStage%2, trapdoor and trapdoor.StageType == "rep")
				}
			end

			if trapdoor and (trapdoor.StageType == "rep" or trapdoor.StageType == "vanilla") then
				stage = StageAPI.CallCallbacks("PRE_SELECT_NEXT_STAGE", true, StageAPI.GetCurrentStage(), trapdoor.StageType == "rep") or stage
			end

			local trapdoorAnm2 = currentHubChamber[slot].TrapdoorAnm2 or trapdoor and trapdoor.Anm2
			if not trapdoorAnm2 and stage.NormalStage 
			and (stage.Stage == LevelStage.STAGE4_1 or stage.Stage == LevelStage.STAGE4_2) 
			then
				trapdoorAnm2 = "gfx/grid/door_11_wombhole.anm2"
			end
			
			local trapdoorEnt = StageAPI.SpawnCustomTrapdoor(
				room:GetGridPosition(hub2.Hub2TrapdoorSpots[slot]), 
				stage, 
				trapdoorAnm2, 
				currentHubChamber[slot].TrapdoorSize or trapdoor and trapdoor.Size or 24,
				false
			)
			
			if currentHubChamber[slot].DisableTrapdoor then
				trapdoorEnt:GetData().IsDisabledHub2Trapdoor = true
			end
		end

		if currentHubChamber[slot].Door and isFirstLoad then
			if currentHubChamber[slot].Door == 1 then
				local mainChamberData = StageAPI.GetDefaultLevelMap():GetRoomDataFromRoomID(MAIN_CHAMBER_ID)

				if mainChamberData then
					hub2.LogDebug("Placing main chamber door (id <", MAIN_CHAMBER_ID, ">:<", mainChamberData.MapID, ">)")

					StageAPI.SpawnCustomDoor(
						slot, 
						mainChamberData.MapID, 
						StageAPI.DefaultLevelMapID, 
						hub2.ChamberDoor.Name
					)
				else
					hub2.Log("Error: unknown main chamber ", MAIN_CHAMBER_ID)
				end
				
			else
				local roomId = "Hub2.0_Chamber_" .. tostring(currentHubChamber[slot].Door)
				local chamberRoomData = StageAPI.GetDefaultLevelMap():GetRoomDataFromRoomID(roomId)
				if chamberRoomData then
					hub2.LogDebug("Placing chamber door (id <", roomId, ">:<", chamberRoomData.MapID, ">)")

					StageAPI.SpawnCustomDoor(
						slot, 
						chamberRoomData.MapID, 
						StageAPI.DefaultLevelMapID, 
						hub2.ChamberDoor.Name
					)
				else
					hub2.Log("Error: unknown chamber " .. roomId)
				end
			end
		end
		
		if currentHubChamber[slot].BossDoor and isFirstLoad then
			local stageName = hub2.RepHub2Quads[levelStage]:gsub("^%l", string.upper)
			local doorType = hub2.RepDoors[stageName]

			hub2.LogDebug("Placing boss door (idx: <", hub2.Hub2BossRoomIndex, ">), has door <", doorType.Name, "> for stage name <", stageName, ">")

			StageAPI.SpawnCustomDoor(
				slot, 
				hub2.Hub2BossRoomIndex, 
				nil, 
				doorType.Name
			)
		end
	end
	
	-- spawn statues
	if hub2.CurrentSelectedHub2ChamberId == 1 then
		if isFirstLoad then
			hub2.data.run.level.hub2Statues = {}
			
			local statueIndices = {16, 28, 106, 118}
			for i=1, 4 do
				---@type CustomGridEntity
				local grid = hub2.GRIDENT.HUB2_STATUE:Spawn(statueIndices[i], true, false)
				local persistData = StageAPI.GetCustomGrid(statueIndices[i], hub2.GRIDENT.HUB2_STATUE.Name).PersistentData
								
				if isFirstLoad then
					table.insert(hub2.data.run.level.hub2Statues, {
						Index = statueIndices[i],
						StatueId = persistData.StatueId,
						IsBroken = false
					})
				end
			end
		end
	end
end

StageAPI.AddCallback("Hub2.0", "POST_ROOM_LOAD", 1, function(currentRoom, isFirstLoad, isExtraRoom)
	if currentRoom:GetType() ~= ROOMTYPE_HUBCHAMBER then
		return
	end

	local room = game:GetRoom()
	if currentRoom.LevelIndex == MAIN_CHAMBER_ID then
		hub2.CurrentSelectedHub2ChamberId = 1
	else
		local currentRoom = StageAPI.GetCurrentRoom()
		local roomId = currentRoom.LevelIndex
		local prefix = "Hub2.0_Chamber_"
		local chamberIdStr = roomId:gsub(prefix, "")

		hub2.CurrentSelectedHub2ChamberId = tonumber(chamberIdStr)
	end	

	hub2.LoadHub2(room, currentRoom, isFirstLoad)

	-- Handle seeds, as entering the transition DOOR (regardless of actual targeted room,
	-- so even here where it's actually a separate grid index altogether) will make the
	-- seeds reset

	local seeds = game:GetSeeds()
	local numReseeds = math.floor(hub2.GetCorrectedLevelStage() * .5 - .5) * 5
	hub2.LogDebug("Trying to reset seeds ", numReseeds, " times")
	for i = 1, numReseeds do
		seeds:GetNextSeed()
		for name, v in pairs(StageAPI.StageOverride) do
			seeds:ForgetStageSeed(v.OverrideStage)
		end
	end
end)

-- Separate callback for recursion reasons
hub2:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	local room = game:GetRoom()

	if hub2.data.isHub2Active and game:GetLevel():GetAbsoluteStage() < LevelStage.STAGE3_2 then
		hub2.UpdateHub2Doors()
	end

	if hub2.IsTransitionRoom() then
		local slot
		for slot2 = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
			if room:GetDoor(slot2) then
				slot = slot2
				break
			end
		end

		hub2.LogMinor("Entered replaced transition room, warping to hub (slot: ", slot, ")...")
		WarpToMainChamber(slot)
	end
end)

local DoRemoveDoorSpawnsCheck = false

hub2:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	local room = game:GetRoom()
	if room:GetType() == RoomType.ROOM_BOSS then
		if room:IsClear() then
			hub2.UpdateHub2Doors()
		end
		DoRemoveDoorSpawnsCheck = true
	else
		DoRemoveDoorSpawnsCheck = false
	end
end)

hub2:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	hub2.Hub2Slots = nil
	hub2.CurrentSelectedHub2ChamberId = 1
	tombMausoleumDoorPayments = 0
end)

-- do
-- 	local stopClearDoorSound = false

-- 	hub2:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
-- 		if hub2.data.isHub2Active and hub2.IsTransitionRoom() and game:GetLevel():GetAbsoluteStage() < LevelStage.STAGE3_2 then
-- 			stopClearDoorSound = true
			
-- 			return true
-- 		end
-- 	end)

-- 	hub2:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
-- 		if stopClearDoorSound then
-- 			sfx:Stop(SoundEffect.SOUND_DOOR_HEAVY_OPEN)
-- 			stopClearDoorSound = false
-- 		end
-- 	end)
-- end

hub2:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if eff:GetData().IsDisabledHub2Trapdoor then -- forces the trapdoor to stay closed
		local sprite = eff:GetSprite()
		if sprite:IsPlaying("Open Animation") then
			sprite:SetFrame("Closed", 0)
		end
	end
end, StageAPI.E.Trapdoor.V)

---@param hubChamber table<integer, Hub2.Entry>
function hub2.SetUpHub2Background(hubChamber)
	local room = game:GetRoom()
	local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, room:GetTopLeftPos(), Vector.Zero, nil)
	local sprite = eff:GetSprite()
	
	sprite:Load("gfx/backdrop/hubroom_2.0/hub_2.0_backdrop.anm2", true)
	sprite:Play("1x1", true)
	
	for slot=DoorSlot.LEFT0, DoorSlot.DOWN0 do
		if hubChamber[slot].QuadPng then
			sprite:ReplaceSpritesheet(slot, hubChamber[slot].QuadPng)
		else
			sprite:ReplaceSpritesheet(slot, "gfx/backdrop/hubroom_2.0/hubquads/" .. hubChamber[slot].Quad .. "_quad.png")
		end
	end
	sprite:LoadGraphics()
	
	eff:AddEntityFlags(hub2.BitOr(EntityFlag.FLAG_RENDER_FLOOR, EntityFlag.FLAG_RENDER_WALL))
end

hub2:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, etype, variant, subtype, pos, vel, spawner, seed)
    if DoRemoveDoorSpawnsCheck and etype == EntityType.ENTITY_EFFECT
    and (variant == EffectVariant.WOOD_PARTICLE or variant == EffectVariant.DUST_CLOUD)
	and ShouldRemoveTransitionDoor()
    then
		local room = game:GetRoom()

        for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            local door = room:GetDoor(i)
            if door and door.TargetRoomType == ROOMTYPE_TRANSITION then
                local doorPos = room:GetGridPosition(door:GetGridIndex())
                if doorPos:DistanceSquared(pos) < 60^2 then
                    return {
                        StageAPI.E.DeleteMeEffect.T,
                        StageAPI.E.DeleteMeEffect.V,
                        0,
                        seed
                    }
                else
                    return
                end
            end
        end
    end
end)
