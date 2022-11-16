---@diagnostic disable: need-check-nil
local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------------------
--AIR MOVEMENT FUNCTIONALITY--
------------------------------
do

-------------
--CALLBACKS--
-------------

--REV_PRE_ENTITY_AIR_MOVEMENT_UPDATE(entity, airMovementData)
--can take entity type as value
--triggered before every time the entity air movement system updates
--return false to prevent the update from happening

--REV_PRE_ENTITY_AIR_MOVEMENT_LAND(entity, airMovementData, fromGrid)
--can take entity type as value
--triggered before an entity lands (where velocity and position would be preserved)
--if this is a landing cut short because landing from grid collision is enabled and this entity touched a grid then fromGrid will be the grid entity that caused this, otherwise nil
--return false to prevent the default entity landing code from running

--REV_POST_ENTITY_AIR_MOVEMENT_UPDATE(entity, airMovementData)
--can take entity type as value
--triggered after every time the entity air movement system updates
--this runs after all air movement code, so returning here does nothing

--REV_POST_ENTITY_AIR_MOVEMENT_LAND(entity, airMovementData, fromGrid, oldZVelocity)
--can take entity type as value
--triggered after an entity lands
--if this is a landing cut short because landing from grid collision is enabled and this entity touched a grid then fromGrid will be the grid entity that caused this, otherwise nil
--return false to prevent the entity from being removed if they can potentially fall in a pit (this is the only use of returning here)

-------------
--ZVELOCITY--
-------------
-- ZVelocity is how fast the entity is currently moving in the air.
-- A positive ZVelocity is flying, a negative ZVelocity is falling.

--REVEL.AddEntityZVelocity
-- Adds the value provided to the current ZVelocity on the entity
function REVEL.AddEntityZVelocity(entity, velocity)
    local data = entity:GetData()
	REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)
	data.AirMovement.ZVelocity = data.AirMovement.ZVelocity + velocity
end

--REVEL.SetEntityZVelocity
-- Sets ZVelocity on the entity
function REVEL.SetEntityZVelocity(entity, velocity)
    local data = entity:GetData()
	REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)
	data.AirMovement.ZVelocity = velocity
end

--REVEL.GetEntityZVelocity
-- Returns the entity's current ZVelocity
function REVEL.GetEntityZVelocity(entity)
    local data = entity:GetData()
	if data.AirMovement and data.AirMovement.ZVelocity then
		return data.AirMovement.ZVelocity
	end
	return 0
end

-------------
--ZPOSITION--
-------------
-- ZPosition is how how high up in the air the entity currently is.
-- Entities cannot have a negative ZPoistion.

--REVEL.AddEntityZPosition
-- Adds the value provided to the current ZPosition on the entity
function REVEL.AddEntityZPosition(entity, position)
    local data = entity:GetData()
	REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)
	data.AirMovement.ZPosition = data.AirMovement.ZPosition + position
end

--REVEL.SetEntityZPosition
-- Sets ZPosition on the entity
function REVEL.SetEntityZPosition(entity, position)
    local data = entity:GetData()
	REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)
	data.AirMovement.ZPosition = position
end

--REVEL.GetEntityZPosition
-- Returns the entity's current ZPosition
function REVEL.GetEntityZPosition(entity)
    local data = entity:GetData()
	if data.AirMovement and data.AirMovement.ZPosition then
		return data.AirMovement.ZPosition
	end
	return 0
end

-------------------
-- GET VARIABLES --
-------------------

--Get stuff like distance before landing, etc

---@param entity Entity
---@return AirMovementData
function REVEL.GetAirMovementData(entity)
	local data = entity:GetData()
	data.AirMovement = data.AirMovement or {}
	REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)

	return data.AirMovement
end

local DefaultUpdatesOnRender = true

---Time left (in update amount) before landing (reaching z 0), assuming no external changes to velocity z position etc
---@param entity Entity
---@param round? boolean
---@return number updates
function REVEL.GetUpdatesBeforeZLanding(entity, round)
	local airMovementData = REVEL.GetAirMovementData(entity)

	if round == nil then round = true end

	local zVel = airMovementData.ZVelocity
	local g = airMovementData.Gravity
	local termVel = airMovementData.TerminalVelocity
	local zPos = airMovementData.ZPosition
	local timeUntilLanding

	-- if already over terminal velocity, it should stay the same until landing
	if zVel <= -termVel and termVel > 0 then
		timeUntilLanding = zPos / termVel
	-- if not yet at terminal velocity, take gravity into account too
	else
		--time at which terminal velocity will be reached
		local terminalVelTime = (zVel + termVel) / g
		timeUntilLanding = (zVel + math.sqrt(zVel * zVel + 2 * g * zPos)) / g

		--if it reaches z 0 after terminal velocity time, adjust to the fact velocity will stay at terminal velocity once it reaches it
		if timeUntilLanding > terminalVelTime then
			local terminalVelocityZ = zPos + zVel * terminalVelTime - g * terminalVelTime * terminalVelTime / 2 --z pos when it reaches terminal velocity
			timeUntilLanding = terminalVelTime + terminalVelocityZ / termVel
		end
	end

	if DefaultUpdatesOnRender then
		timeUntilLanding = timeUntilLanding/ 2
	end
	if round then
		timeUntilLanding = timeUntilLanding > 0.5 and math.ceil(timeUntilLanding) or math.floor(timeUntilLanding)
	end

	return timeUntilLanding
end

---@param entity Entity
---@param xySpeed number
---@return number distance
function REVEL.GetDistanceBeforeZLanding(entity, xySpeed)
	xySpeed = xySpeed or entity.Velocity:Length()

	return REVEL.GetUpdatesBeforeZLanding(entity, false) * xySpeed
end

---How much z velocity should be for the entity to fly the specified distance before landing
---@param entity Entity
---@param flyDistance number
---@param xySpeed number
---@return number zSpeed
function REVEL.GetNeededZSpeedForDistance(entity, flyDistance, xySpeed)
	local airMovementData = REVEL.GetAirMovementData(entity)

	local g = airMovementData.Gravity
	local h = REVEL.GetEntityZPosition(entity)
	xySpeed = xySpeed or entity.Velocity:Length()
	if DefaultUpdatesOnRender then --game velocity is applied on updates only
		xySpeed = xySpeed / 2
	end

	local zSpeed = (flyDistance^2 * g - 2 * xySpeed^2 * h) / (2 * flyDistance * xySpeed) --trust wolfram alpha on this one

	return zSpeed
end
  
------------
--HANDLING--
------------

local RoomHasNPCAirMovement = false

--REVEL.SetEntityAirMovement
-- Makes sure the airMovementData table provided has the values it needs to work.
---@param entity Entity
---@param airMovementData AirMovementData
---@return AirMovementData
function REVEL.SetEntityDefaultAirMovement(entity, airMovementData)
	if not airMovementData then
		local data = entity:GetData()
		data.AirMovement = data.AirMovement or {}
		airMovementData = data.AirMovement
	end
	airMovementData.Gravity = airMovementData.Gravity or math.min(0.5, math.max(0.1, 0.2 + (entity.Mass * 0.1)))
	airMovementData.ZVelocity = airMovementData.ZVelocity or 0
	airMovementData.ZPosition = airMovementData.ZPosition or 0
	airMovementData.TerminalVelocity = airMovementData.TerminalVelocity or entity.Mass * 10
	airMovementData.Bounce = airMovementData.Bounce or math.min(0.5, math.abs(entity.Mass-100)*0.002)
	airMovementData.BounceMinSpeed = airMovementData.BounceMinSpeed or 1
	if airMovementData.DoRotation == nil then airMovementData.DoRotation = false end
	airMovementData.RotationOffset = airMovementData.RotationOffset or 0
	if airMovementData.DisableCollision == nil then airMovementData.DisableCollision = true end
	airMovementData.CollisionOffset = airMovementData.CollisionOffset or 15
	if airMovementData.BounceFromGrid == nil then airMovementData.BounceFromGrid = false end
	airMovementData.BounceFromGridZVelocity = airMovementData.BounceFromGridZVelocity or math.min(0.5, math.max(0.1, 0.2 + (entity.Mass * 0.1))) * 10
	if airMovementData.LandFromGrid == nil then airMovementData.LandFromGrid = false end
	if airMovementData.PoofInPits == nil then airMovementData.PoofInPits = true end
	if airMovementData.DisableAI == nil then airMovementData.DisableAI = false end
	if airMovementData.FloatOnPits == nil then airMovementData.FloatOnPits = false end
	airMovementData.RenderExp = airMovementData.RenderExp or 1
	airMovementData.LandEventMinDelay = airMovementData.LandEventMinDelay or 5

	if entity.Type ~= 1 then
		RoomHasNPCAirMovement = true
	end

	return airMovementData
end

--REVEL.SetEntityAirMovement
-- Sets air movement data on the entity.

---@class AirMovementData
---@field ZPosition number --The entity's current position in the air. Positive = above
---@field ZVelocity number --How fast the entity is moving up/down. Positive = above
---@field Gravity number --How fast the entity falls.
---@field TerminalVelocity number --The fastest an entity can fall.
---@field Bounce number --How much velocity is reversed when an entity lands.
---@field BounceMinSpeed number -- default 0.75
---@field DoRotation boolean --True to make the entity's sprite rotate to point at where it is traveling.
---@field RotationOffset number --How much to offset the entity's sprite when it rotates.
---@field DisableCollision boolean --True to let the movement code control and disable the collision of this entity if it's high enough.
---@field CollisionOffset number --How high the entity needs to be to have its collision disabled.
---@field BounceFromGrid boolean --True to bounce the entity if it has landed on a grid. fromGrid in the callbacks will return the pit when this happens.
---@field BounceFromGridZVelocity number --How much to push the entity upward if they land on a grid and BounceFromGrid is true.
---@field LandFromGrid boolean --True to trigger landing code if the entity touched a grid. fromGrid in the callbacks will return the pit when this happens.
---@field PoofInPits boolean --True to remove the entity and spawn a poof effect if it falls in a pit. fromGrid in the callbacks will return the pit when this happens.
---@field DisableAI boolean --True to disable the AI of npcs who are in the air. Will not work for other kinds of entities. This gets set back to false when the npc lands, so they will regain their ai when bouncing.
---@field FloatOnPits boolean --<default false> True if the entity should stop falling while above pits
---@field RenderExp number -- exponential offset rendering
---@field LandEventMinDelay integer -- <default 5> minimum frames between land events, to prevent spam due to bounce

---@param entity Entity
---@param airMovementData AirMovementData
---@return AirMovementData
function REVEL.SetEntityAirMovement(entity, airMovementData)
	local data = entity:GetData()
	data.AirMovement = data.AirMovement or {}
	data.AirMovement = REVEL.SetEntityDefaultAirMovement(entity, data.AirMovement)
	for value, valueData in pairs(airMovementData) do
		data.AirMovement[value] = valueData
	end
	return data.AirMovement
end

function REVEL.SetPlayerJumpSprites(player, ...)
  local data = player:GetData()

  data.CustomJumpSprites = {...}
end

function REVEL.ClearPlayerJumpSprites(player)
  player:GetData().CustomJumpSprites = nil
end

--REVEL.UpdateEntityAirMovement
-- Runs air movement code based on whats provided in airMovementData
-- If no airMovementData is provided, pulls it from entity:GetData().AirMovement
---@param entity Entity
---@param airMovementData? AirMovementData
function REVEL.UpdateEntityAirMovement(entity, airMovementData)
	--make sure we have some values to work with here
	if not airMovementData then
		local data = entity:GetData()
		data.AirMovement = data.AirMovement or {}
		airMovementData = data.AirMovement
	end
	REVEL.SetEntityDefaultAirMovement(entity, airMovementData)
	airMovementData.OriginalEntityCollision = airMovementData.OriginalEntityCollision or entity.EntityCollisionClass
	airMovementData.OriginalGridCollision = airMovementData.OriginalGridCollision or entity.GridCollisionClass

	--trigger REV_PRE_ENTITY_AIR_MOVEMENT_UPDATE callbacks
	local ret = StageAPI.CallCallbacksWithParams(RevCallbacks.PRE_ENTITY_AIR_MOVEMENT_UPDATE, true, entity.Type, 
		entity, airMovementData)
	if ret == false then
		return
	end

	if entity:Exists() then --checking this incase a callback deleted the entity
		local float = false --avoid updating z pos/speed if true

		local gridAtEntity

		if airMovementData.FloatOnPits then
			gridAtEntity = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position))
			float = float or (gridAtEntity and gridAtEntity.CollisionClass == GridCollisionClass.COLLISION_PIT)
		end

		local oldPosition = airMovementData.ZPosition

		if not float then
			--modify the velocity based on gravity
			airMovementData.ZVelocity = airMovementData.ZVelocity - airMovementData.Gravity

			--make sure it isn't over the terminal velocity
			if airMovementData.ZVelocity < -airMovementData.TerminalVelocity and airMovementData.TerminalVelocity > 0 then
				airMovementData.ZVelocity = -airMovementData.TerminalVelocity
			end

			--set the position
			airMovementData.ZPosition = airMovementData.ZPosition + airMovementData.ZVelocity
		end

		--grid to collide checks
		local landFromGrid = nil
		gridAtEntity = gridAtEntity or REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position))
		local gridToCollide = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position + entity.Velocity:Resized(entity.Size+5)))
		if airMovementData.DisableCollision or airMovementData.LandFromGrid or airMovementData.BounceFromGrid or airMovementData.PoofInPits then
			if airMovementData.ZPosition <= 0 then
				--falling in pits
				if airMovementData.BounceFromGrid or airMovementData.PoofInPits then
					if gridAtEntity and ((gridAtEntity.CollisionClass == GridCollisionClass.COLLISION_PIT) or (airMovementData.BounceFromGrid and gridAtEntity.CollisionClass ~= GridCollisionClass.COLLISION_NONE and gridAtEntity.CollisionClass ~= GridCollisionClass.COLLISION_PIT)) then
						landFromGrid = gridAtEntity
					end
				end
			elseif airMovementData.ZPosition <= airMovementData.CollisionOffset and not (float and airMovementData.FloatOnPits) then
				--collision
				if airMovementData.DisableCollision then
					if entity.EntityCollisionClass ~= airMovementData.OriginalEntityCollision and airMovementData.OriginalEntityCollision ~= EntityCollisionClass.ENTCOLL_NONE then
						entity.EntityCollisionClass = airMovementData.OriginalEntityCollision
					end
					if entity.GridCollisionClass ~= airMovementData.OriginalGridCollision and airMovementData.OriginalGridCollision ~= EntityGridCollisionClass.GRIDCOLL_NONE and airMovementData.OriginalGridCollision ~= EntityGridCollisionClass.GRIDCOLL_WALLS_X and airMovementData.OriginalGridCollision ~= EntityGridCollisionClass.GRIDCOLL_WALLS_Y and airMovementData.OriginalGridCollision ~= EntityGridCollisionClass.GRIDCOLL_WALLS then
						entity.GridCollisionClass = airMovementData.OriginalGridCollision
					end
				end

				--falling into rocks
				if airMovementData.LandFromGrid then
					if gridToCollide and gridToCollide.CollisionClass ~= GridCollisionClass.COLLISION_NONE and gridToCollide.CollisionClass ~= GridCollisionClass.COLLISION_PIT then
						landFromGrid = gridToCollide
					end
				end
			else
				--collision
				if airMovementData.DisableCollision then
					if entity.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
						airMovementData.OriginalEntityCollision = entity.EntityCollisionClass
						entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					end
					if entity.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_NONE and entity.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_WALLS_X and entity.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_WALLS_Y and entity.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_WALLS then
						airMovementData.OriginalGridCollision = entity.GridCollisionClass
						entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					end
				end

				--falling into walls or rocks with BounceFromGrid enabled
				if airMovementData.LandFromGrid then
					if gridToCollide and gridToCollide.CollisionClass == GridCollisionClass.COLLISION_WALL then
						landFromGrid = gridToCollide
					end
				end
			end
		end

		--landing code
		if airMovementData.ZPosition <= 0 or landFromGrid then
			--trigger REV_PRE_ENTITY_AIR_MOVEMENT_LAND callbacks
			airMovementData.OldZPosition = airMovementData.ZPosition --we set the data to "old" values so the land callbacks can still have something to check once we clear these
			airMovementData.OldZVelocity = airMovementData.ZVelocity

			local ret = StageAPI.CallCallbacksWithParams(RevCallbacks.PRE_ENTITY_AIR_MOVEMENT_LAND, false, entity.Type,
				entity, airMovementData, landFromGrid)
            if ret == false then
				return 
			end

			if entity:Exists() then --checking this in case a callback deleted the entity
				local positionToSet = 0
				if landFromGrid and oldPosition > airMovementData.CollisionOffset and airMovementData.ZPosition < airMovementData.CollisionOffset then
					positionToSet = airMovementData.CollisionOffset
				end
				airMovementData.ZPosition = positionToSet

				--bouncing
				local velocityToSet = 0
				if landFromGrid and airMovementData.BounceFromGrid and landFromGrid.CollisionClass ~= GridCollisionClass.COLLISION_PIT then
					velocityToSet = airMovementData.BounceFromGridZVelocity
				elseif airMovementData.Bounce > 0 
				and math.floor(airMovementData.ZVelocity*100) < 0 
				and math.abs(airMovementData.ZVelocity) > airMovementData.BounceMinSpeed
				then
					velocityToSet = (math.floor(-airMovementData.ZVelocity*100)*0.01) * airMovementData.Bounce
				end
				airMovementData.ZVelocity = velocityToSet

				entity.SpriteOffset = Vector(0,0)

				if airMovementData.DoRotation then
					entity.SpriteRotation = 0
				end
				if airMovementData.FloatOnPits then
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				end

				--reenable ai
				airMovementData.DisableAI = false

				if not airMovementData.LastLandEventFrame 
				or entity.FrameCount - airMovementData.LastLandEventFrame > airMovementData.LandEventMinDelay 
				then
					airMovementData.LastLandEventFrame = entity.FrameCount

					--trigger REV_POST_ENTITY_AIR_MOVEMENT_LAND callbacks
					local ret = StageAPI.CallCallbacksWithParams(RevCallbacks.POST_ENTITY_AIR_MOVEMENT_LAND, true, entity.Type, 
						entity, airMovementData, landFromGrid, airMovementData.OldZVelocity)
					
					if ret == false then
						return
					end
				end

				if entity:Exists() then --checking this in case a callback deleted the entity
					--poof the entity
					if airMovementData.PoofInPits and landFromGrid and landFromGrid.CollisionClass == GridCollisionClass.COLLISION_PIT then
						local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity)
						entity:Remove()
					end
				end

				return
			end
		end

		--rotate the entity's sprite
		local offset = airMovementData.ZPosition
		if airMovementData.DoRotation then
			local rotation = Vector(-entity.Velocity.X, airMovementData.ZVelocity):GetAngleDegrees()-90
			offset = offset + math.abs(rotation)/airMovementData.RotationOffset
			entity.SpriteRotation = rotation
		end
		if airMovementData.RenderExp and airMovementData.RenderExp ~= 1 then
			offset = offset ^ airMovementData.RenderExp
		end

		--offset the entity's sprite
		entity.SpriteOffset = Vector(0,-offset)

		--trigger REV_POST_ENTITY_AIR_MOVEMENT_UPDATE callbacks
		local ret = StageAPI.CallCallbacksWithParams(RevCallbacks.POST_ENTITY_AIR_MOVEMENT_UPDATE, true, entity.Type, 
			entity, airMovementData, landFromGrid)
		if ret == false then
			return
		end
	end
end

-- MC_POST_RENDER callback to call REVEL.UpdateEntityAirMovement on all entities 
-- with a valid data.AirMovement table which has a position or velocity greater than 0.
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not REVEL.game:IsPaused() then
		if RoomHasNPCAirMovement then
			for _, entity in ipairs(REVEL.roomEntities) do
				local data = entity:GetData()
				if data.AirMovement and (data.AirMovement.ZPosition > 0 or data.AirMovement.ZVelocity > 0) then
					REVEL.UpdateEntityAirMovement(entity, data.AirMovement)
				end
			end
		else
			for _, entity in ipairs(REVEL.players) do
				local data = entity:GetData()
				if data.AirMovement and (data.AirMovement.ZPosition > 0 or data.AirMovement.ZVelocity > 0) then
					REVEL.UpdateEntityAirMovement(entity, data.AirMovement)
				end
			end
		end
	end
end)

--MC_PRE_NPC_UPDATE callback for the disable ai feature
REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	local data = npc:GetData()
	if data.AirMovement and (data.AirMovement.ZPosition > 0 or data.AirMovement.ZVelocity > 0) and data.AirMovement.DisableAI then
		return true
	end
end)

--do special handling for the player
local function setPlayerAirMovementData(player)
	REVEL.SetEntityAirMovement(player, {
		Gravity = 0.23,
		DisableCollision = true,
		BounceFromGrid = true,
		BounceFromGridZVelocity = 4,
		LandFromGrid = false,
		PoofInPits = true
	})
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	RoomHasNPCAirMovement = false

	for _, player in ipairs(REVEL.players) do
		setPlayerAirMovementData(player)
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	setPlayerAirMovementData(player)
end)

local springManager = REVEL.ent("Revelations Spring Manager")

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local data, sprite = player:GetData(), player:GetSprite()
	if data.lastSafeAirMovementPos then
		if sprite:IsFinished("FallIn") then
			if data._AirJumpWasVisible == nil then
      			data._AirJumpWasVisible = player.Visible
			end
			player.Visible = false
		end
		if sprite:IsPlaying("JumpOut") and sprite:GetFrame() == 14 then
			REVEL.DelayFunction(function(player)
				local data = player:GetData()
				player.Visible = true
				data.lastSafeAirMovementPos = data.lastSafeAirMovementPos or player.Position
				player.Position = data.lastSafeAirMovementPos
				data.lastSafeAirMovementPos = nil
			end, 1, {player}, true)
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect, renderOffset)
	local data = effect:GetData()
	if data.AirMovementManaging then
		local player = data.AirMovementManaging
		local playerData = player:GetData()
		local jumpSprites = playerData.CustomJumpSprites or {player:GetSprite()}

		effect.Position = player.Position
		for _, sprite in ipairs(jumpSprites) do
			sprite:Render(Isaac.WorldToScreen(player.Position + player.SpriteOffset) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
		end

		if playerData.AirMovement and playerData.AirMovement.ZPosition <= 0 and playerData.AirMovement.ZVelocity <= 0 then
			player.Visible = playerData._AirJumpWasVisible
			playerData._AirJumpWasVisible = nil
			playerData.AirMovementManager = nil
			data.AirMovementManaging = nil
			effect:Remove()
		end
	end
end, springManager.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_ENTITY_AIR_MOVEMENT_UPDATE, 0, function(entity, airMovementData)
	local data = entity:GetData()
	data.lastSafeAirMovementPos = data.lastSafeAirMovementPos or entity.Position
	if not data.AirMovementManager or data.AirMovementManager and not data.AirMovementManager:Exists() then
		local airMovementManagerEffect = Isaac.Spawn(springManager.id, springManager.variant, 0, entity.Position, Vector.Zero, entity)
		data.AirMovementManager = airMovementManagerEffect
		airMovementManagerEffect:GetData().AirMovementManaging = entity
		if data._AirJumpWasVisible == nil then
			data._AirJumpWasVisible = entity.Visible
		end
		entity.Visible = false
	end
end, EntityType.ENTITY_PLAYER)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_AIR_MOVEMENT_LAND, 0, function(entity, airMovementData, fromPit, oldZSpeed)
	if fromPit then
		if entity:ToPlayer().CanFly then
			airMovementData.ZPosition = 0
			airMovementData.ZVelocity = 0
			return false
		elseif fromPit.CollisionClass == GridCollisionClass.COLLISION_PIT then
			local data, sprite = entity:GetData(), entity:GetSprite()
			data.lastSafeAirMovementPos = data.lastSafeAirMovementPos or entity.Position
			entity:ToPlayer():AnimatePitfallIn()
			for i=1, 6 do
				sprite:Update()
			end
			return false
		end
	end
	if math.abs(oldZSpeed) > 1.5 then
		REVEL.sfx:Play(SoundEffect.SOUND_SCAMPER, 0.5, 0, false, 1)
	end
end, EntityType.ENTITY_PLAYER)

end

Isaac.DebugString("Revelations: Loaded Air Movement!")
end