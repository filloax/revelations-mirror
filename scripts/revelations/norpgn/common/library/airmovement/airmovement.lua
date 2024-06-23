---@diagnostic disable: need-check-nil
local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

local SubModules = {
    "scripts.revelations.common.library.airmovement.zpos_basics",
    "scripts.revelations.common.library.airmovement.zpos_utils",
    "scripts.revelations.common.library.airmovement.zpos_logic",
    "scripts.revelations.common.library.airmovement.zpos_player",

	-- Enable when testing stuff, includes keybinds to jump, launch ents, etc
    -- "scripts.revelations.common.library.airmovement.zpos_test",
}

local LoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

------------------------------
--AIR MOVEMENT FUNCTIONALITY--
------------------------------

-------------
--CALLBACKS--
-------------

--REV_PRE_ENTITY_ZPOS_UPDATE(entity, airMovementData)
--can take entity type as value
--triggered before every time the entity air movement system updates
--return false to prevent the update from happening

--REV_PRE_ENTITY_ZPOS_LAND(entity, airMovementData, fromGrid)
--can take entity type as value
--triggered before an entity lands (where velocity and position would be preserved)
--if this is a landing cut short because landing from grid collision is enabled and this entity touched a grid then fromGrid will be the grid entity that caused this, otherwise nil
--return false to prevent the default entity landing code from running

--REV_POST_ENTITY_ZPOS_UPDATE(entity, airMovementData)
--can take entity type as value
--triggered after every time the entity air movement system updates
--this runs after all air movement code, so returning here does nothing

--REV_POST_ENTITY_ZPOS_LAND(entity, airMovementData, fromGrid, oldZVelocity)
--can take entity type as value
--triggered after an entity lands
--if this is a landing cut short because landing from grid collision is enabled and this entity touched a grid then fromGrid will be the grid entity that caused this, otherwise nil
--return false to prevent the entity from being removed if they can potentially fall in a pit (this is the only use of returning here)

REVEL.ZPos = {
    ---@type EntityPtr[] doesn't include players
    RoomEntitiesWithZPos = {},
    ---@type table<integer, true> hashes set
    RoomEntitySet = {},
	---@enum RevZPos.EntityCollisionMode
	EntityCollisionMode = {
		DONT_HANDLE = 0, -- don't change collision if entity is airborne
		SIMPLE_AIRBORNE = 1, -- simply remove collision from flying entities (previous behavior)
		HITBOX = 2, -- check airborne collision depending on an "hitbox" by checking entity height
	},
	LEVEL_GROUND_BASE = 0,
}


---@class AirMovementData
---@field ZPosition number --The entity's current position in the air. Positive = above
---@field ZVelocity number --How fast the entity is moving up/down. Positive = above
---@field Gravity number --How fast the entity falls.
---@field TerminalVelocity number --The fastest an entity can fall.
---@field Bounce number --How much velocity is reversed when an entity lands.
---@field BounceMinSpeed number -- default 0.75
---@field DoRotation boolean --True to make the entity's sprite rotate to point at where it is traveling.
---@field RotationOffset number --How much to offset the entity's sprite when it rotates.
---@field DisableCollision boolean --True to let the movement code control and disable the grid collision of this entity if it's high enough.
--How to handle entity collision depending on Z pos distance. Interaction between entities is as follows, from highest priority to lowest:
--* SIMPLE_AIRBORNE (in air) vs anything (ground or air): collision is prevented
--* HITBOX (in air): treats DONT_HANDLE as if on ground
--The PRE_ZPOS_COLLISION_CHECK is not called if both entities don't have airmovement data/have DONT_HANDLE collision mode.
---@field EntityCollisionMode RevZPos.EntityCollisionMode
---@field EntityCollisionHeight number --Entity collision distance
---@field CollisionOffset number --How high the entity needs to be to have its collision disabled.
---@field BounceFromGrid boolean --True to bounce the entity if it has landed on a grid. fromGrid in the callbacks will return the pit when this happens.
---@field BounceFromGridZVelocity number --How much to push the entity upward if they land on a grid and BounceFromGrid is true.
---@field LandFromGrid boolean --True to trigger landing code if the entity touched a grid. fromGrid in the callbacks will return the pit when this happens.
---@field PoofInPits boolean --True to remove the entity and spawn a poof effect if it falls in a pit. fromGrid in the callbacks will return the pit when this happens.
---@field DisableAI boolean --True to disable the AI of npcs who are in the air. Will not work for other kinds of entities. This gets set back to false when the npc lands, so they will regain their ai when bouncing.
---@field FloatOnPits boolean --<default false> True if the entity should stop falling while above pits
---@field RenderExp number -- exponential offset rendering
---@field LandEventMinDelay integer -- <default 5> minimum frames between land events, to prevent spam due to bounce
---@field PreviousState table
---@field TargetSpriteOffset number?

-- Makes sure the airMovementData table provided has the values it needs to work.
---@param entity Entity
---@param airMovementData? AirMovementData
---@return AirMovementData
function REVEL.ZPos.TryInitEntity(entity, airMovementData)
	if not airMovementData then
		local data = REVEL.GetData(entity)
		data.AirMovement = data.AirMovement or {}
		airMovementData = data.AirMovement
		Isaac.RunCallbackWithParam(RevCallbacks.POST_ENTITY_ZPOS_INIT, entity.Type, entity, airMovementData)
	end
	local groundLevel = REVEL.ZPos.GetGroundLevel(entity) or 0
	airMovementData.Gravity = airMovementData.Gravity or math.min(0.5, math.max(0.1, 0.2 + (entity.Mass * 0.1)))
	airMovementData.ZVelocity = airMovementData.ZVelocity or 0
	airMovementData.ZPosition = airMovementData.ZPosition or groundLevel
	airMovementData.TerminalVelocity = airMovementData.TerminalVelocity or entity.Mass * 10
	airMovementData.Bounce = airMovementData.Bounce or math.min(0.5, math.abs(entity.Mass-100)*0.002)
	airMovementData.BounceMinSpeed = airMovementData.BounceMinSpeed or 1
	if airMovementData.DoRotation == nil then airMovementData.DoRotation = false end
	airMovementData.RotationOffset = airMovementData.RotationOffset or 0
	if airMovementData.DisableCollision == nil then airMovementData.DisableCollision = true end
	if airMovementData.EntityCollisionMode == nil then airMovementData.EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.HITBOX end
	if airMovementData.EntityCollisionHeight == nil then 
		airMovementData.EntityCollisionHeight = REVEL.GetEntityHeight(entity)
	end
	airMovementData.CollisionOffset = airMovementData.CollisionOffset or 15
	if airMovementData.BounceFromGrid == nil then airMovementData.BounceFromGrid = false end
	airMovementData.BounceFromGridZVelocity = airMovementData.BounceFromGridZVelocity or math.min(0.5, math.max(0.1, 0.2 + (entity.Mass * 0.1))) * 10
	if airMovementData.LandFromGrid == nil then airMovementData.LandFromGrid = false end
	if airMovementData.PoofInPits == nil then airMovementData.PoofInPits = true end
	if airMovementData.DisableAI == nil then airMovementData.DisableAI = false end
	if airMovementData.FloatOnPits == nil then airMovementData.FloatOnPits = false end
	airMovementData.RenderExp = airMovementData.RenderExp or 1
	airMovementData.LandEventMinDelay = airMovementData.LandEventMinDelay or 5
	airMovementData.PreviousState = airMovementData.PreviousState or {
		ZPosition = airMovementData.ZPosition, 
		ZVelocity = airMovementData.ZVelocity, 
		GroundLevel = groundLevel,
	}

    local hash = GetPtrHash(entity) 
	if entity.Type ~= 1 and not REVEL.ZPos.RoomEntitySet[hash] then
        REVEL.ZPos.RoomEntitiesWithZPos[#REVEL.ZPos.RoomEntitiesWithZPos+1] = {EntityPtr(entity), hash}
		REVEL.ZPos.RoomEntitySet[hash] = true
	end

	return airMovementData
end


REVEL.RunLoadFunctions(LoadFunctions)

Isaac.DebugString("Revelations: Loaded Air Movement!")
end