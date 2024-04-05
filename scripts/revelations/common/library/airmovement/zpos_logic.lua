local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
local StageAPICallbacks = require "scripts.revelations.common.enums.StageAPICallbacks"
return function()

--[[
    Contents:
    - Base logic: entity updates, basic visuals
    - Entity collision logic
    - NPC AI disable
    - Ground level
]]

local GetGroundLevel
local UsesCallbackForOffset

---@param entity Entity
---@param airMovementData? AirMovementData
---@param zpos? number
local function UpdateEntityVisuals(entity, airMovementData, zpos)
    airMovementData = airMovementData or REVEL.ZPos.GetData(entity)
    zpos = zpos or REVEL.ZPos.GetPosition(entity)

    local callbackRet = Isaac.RunCallbackWithParam(RevCallbacks.PRE_ZPOS_UPDATE_GFX, entity.Type, entity, airMovementData, zpos)

    if callbackRet == false then
        return
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

    local targetOffset = -offset * REVEL.WORLD_TO_SCREEN_RATIO
    if not UsesCallbackForOffset(entity) then
        --offset the entity's sprite
        --add instead of setting so other things can affect offset too
        local lastOffset = airMovementData.LastRenderOffset or 0
        airMovementData.LastRenderOffset = targetOffset
        local newSpriteOffset = entity.SpriteOffset.Y + targetOffset - lastOffset
        entity.SpriteOffset = Vector(0, newSpriteOffset)
    else
        airMovementData.RenderOffset = Vector(0, targetOffset)
    end


    Isaac.RunCallbackWithParam(RevCallbacks.POST_ZPOS_UPDATE_GFX, entity.Type, entity, airMovementData, zpos)
end

REVEL.ZPos.UpdateEntityVisuals = UpdateEntityVisuals

---@param entity Entity
---@param airMovementData? AirMovementData
local function UpdateEntity(entity, airMovementData)
    if not REVEL.RanFirstUpdate() then
        REVEL.DebugStringMinor("Cancel update air movement before run load")
        return 
    end

    --make sure we have some values to work with here
    if not airMovementData then
        local data = REVEL.GetData(entity)
        data.AirMovement = data.AirMovement or {}
        airMovementData = data.AirMovement
    end
    REVEL.ZPos.TryInitEntity(entity, airMovementData)
    airMovementData.OriginalGridCollision = airMovementData.OriginalGridCollision or entity.GridCollisionClass

    --trigger REV_PRE_ENTITY_ZPOS_UPDATE callbacks
    local ret = Isaac.RunCallbackWithParam(RevCallbacks.PRE_ENTITY_ZPOS_UPDATE, entity.Type, 
        entity, airMovementData)
    if ret ~= nil then
        if ret == false then
            UpdateEntityVisuals(entity)
        end
        return
    end

    if entity:Exists() then --checking this incase a callback deleted the entity
        local float = false --avoid updating z pos/speed if true
        local fall = true --no gravity if false

        local gridAtEntity

        local groundLevel = GetGroundLevel(entity)

        if airMovementData.FloatOnPits then
            gridAtEntity = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position))
            float = float or (gridAtEntity and gridAtEntity.CollisionClass == GridCollisionClass.COLLISION_PIT)
        end

        local oldPosition = airMovementData.ZPosition

        if airMovementData.ZPosition <= groundLevel then
            fall = false
        end


        if not float then
            if fall then
                --modify the velocity based on gravity
                -- as this function isnt 60fps anymore but alternated with interpolation function,
                -- double gravity to keep the same end result
                airMovementData.ZVelocity = airMovementData.ZVelocity - airMovementData.Gravity * 2
            end

            --make sure it isn't over the terminal velocity
            if airMovementData.ZVelocity < -airMovementData.TerminalVelocity and airMovementData.TerminalVelocity > 0 then
                airMovementData.ZVelocity = -airMovementData.TerminalVelocity
            end

            --set the position
            airMovementData.ZPosition = airMovementData.ZPosition + airMovementData.ZVelocity
        end

        --handle grid collision
        --and grid to collide checks
        local landFromGrid = nil
        gridAtEntity = gridAtEntity or REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position))
        local collisionDistance = entity.Size + 5
        local gridToCollide = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(entity.Position + entity.Velocity:Resized(collisionDistance)))
        if airMovementData.DisableCollision or airMovementData.LandFromGrid or airMovementData.BounceFromGrid or airMovementData.PoofInPits then
            if airMovementData.ZPosition <= groundLevel then
                --falling in pits
                if airMovementData.BounceFromGrid or airMovementData.PoofInPits then
                    if gridAtEntity and (
                        (gridAtEntity.CollisionClass == GridCollisionClass.COLLISION_PIT) 
                        or (
                            airMovementData.BounceFromGrid 
                            and gridAtEntity.CollisionClass ~= GridCollisionClass.COLLISION_NONE 
                            and gridAtEntity.CollisionClass ~= GridCollisionClass.COLLISION_PIT
                        )
                    ) then
                        landFromGrid = gridAtEntity
                    end
                end
            elseif airMovementData.ZPosition <= groundLevel + airMovementData.CollisionOffset and not (float and airMovementData.FloatOnPits) then
                --collision
                if airMovementData.DisableCollision then
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

        local onGround = airMovementData.ZPosition <= groundLevel or landFromGrid

        --landing code
        if onGround and airMovementData.ZVelocity <= 0 or landFromGrid then
            --trigger REV_PRE_ENTITY_ZPOS_LAND callbacks
            local preCallbackZPosition = airMovementData.ZPosition --we set the data to "old" values so the land callbacks can still have something to check once we clear these
            local preCallbackZVelocity = airMovementData.ZVelocity

            local ret = Isaac.RunCallbackWithParam(RevCallbacks.PRE_ENTITY_ZPOS_LAND, entity.Type,
                entity, airMovementData, landFromGrid)

            if entity:Exists() and ret ~= false then --checking this in case a callback deleted the entity
				if not airMovementData.PreviousState.Grounded then

					local positionToSet = groundLevel
					if landFromGrid and oldPosition > groundLevel + airMovementData.CollisionOffset and airMovementData.ZPosition < airMovementData.CollisionOffset then
						positionToSet = groundLevel + airMovementData.CollisionOffset
					end

					-- REVEL.DebugLog("Land, was pos", airMovementData.ZPosition, "set pos", positionToSet)

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

					if airMovementData.DoRotation then
						entity.SpriteRotation = 0
					end
					-- if airMovementData.FloatOnPits then
					-- 	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
					-- end

					--reenable ai
					airMovementData.DisableAI = false

					local preventRemoval = false

					if not airMovementData.LastLandEventFrame 
					or entity.FrameCount - airMovementData.LastLandEventFrame > airMovementData.LandEventMinDelay 
					then
						airMovementData.LastLandEventFrame = entity.FrameCount
						
						--trigger REV_POST_ENTITY_ZPOS_LAND callbacks
						local ret = Isaac.RunCallbackWithParam(RevCallbacks.POST_ENTITY_ZPOS_LAND, entity.Type, 
							entity, airMovementData, landFromGrid, preCallbackZVelocity)
						
						if ret == false then
							preventRemoval = true
						end
					end

					if entity:Exists() and not preventRemoval then --checking this in case a callback deleted the entity
						--poof the entity
						if airMovementData.PoofInPits and landFromGrid and landFromGrid.CollisionClass == GridCollisionClass.COLLISION_PIT then
							local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity)
                            REVEL.DebugStringMinor("Removing entity in pit:", entity)
							entity:Remove()
						end
					end
				else
                    -- no bounce/land event, still set velocity to ground
					local positionToSet = groundLevel

					airMovementData.ZPosition = positionToSet

					local velocityToSet = 0
					airMovementData.ZVelocity = velocityToSet

					if airMovementData.DoRotation then
						entity.SpriteRotation = 0
					end
					-- if airMovementData.FloatOnPits then
					-- 	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
					-- end

					--reenable ai
					airMovementData.DisableAI = false
                end
            end
        end

        UpdateEntityVisuals(entity, airMovementData)

        --trigger REV_POST_ENTITY_ZPOS_UPDATE callbacks
        Isaac.RunCallbackWithParam(RevCallbacks.POST_ENTITY_ZPOS_UPDATE, entity.Type, 
            entity, airMovementData, landFromGrid)

        airMovementData.PreviousState.ZPosition = airMovementData.ZPosition
        airMovementData.PreviousState.ZVelocity = airMovementData.ZVelocity
        airMovementData.PreviousState.GroundLevel = groundLevel
        airMovementData.PreviousState.Grounded = onGround
    end
end

---@param entity Entity
local function InterpolateEntity(entity)
    local airMovementData = REVEL.ZPos.GetData(entity, true)
    if airMovementData then
        airMovementData.ZPosition = airMovementData.ZPosition + airMovementData.ZVelocity
        UpdateEntityVisuals(entity)
    end
end

--REVEL.ZPos.UpdateEntity
-- Runs air movement code based on whats provided in airMovementData
---@param entity Entity
function REVEL.ZPos.UpdateEntity(entity)
    UpdateEntity(entity)
end

--MC_PRE_NPC_UPDATE callback separate treatment for the disable ai feature
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    local airMovementData = REVEL.ZPos.GetData(npc, true)

    -- REVEL.DebugLog("Checking for", npc.Type, "|", not not airMovementData)

    if airMovementData then
        UpdateEntity(npc, airMovementData)
        if (airMovementData.ZPosition > GetGroundLevel(npc) or airMovementData.ZVelocity > 0) and airMovementData.DisableAI then
            return true
        end
    end
end)

local function airMovement_PostEntityUpdate(_, entity)
    local airMovementData = REVEL.ZPos.GetData(entity, true)

    if airMovementData then
        UpdateEntity(entity, airMovementData)
    end
end

---@param entity Entity
---@param renderOffset Vector
local function airMovement_PreEntityRender(_, entity, renderOffset)
    local airMovementData = REVEL.ZPos.GetData(entity, true)

    if airMovementData and airMovementData.RenderOffset then
        return renderOffset + airMovementData.RenderOffset - REVEL.room:GetRenderScrollOffset()
    end
end

local EntityUpdateCallbacks = {
    ModCallbacks.MC_POST_PEFFECT_UPDATE,
    ModCallbacks.MC_POST_TEAR_UPDATE,
    ModCallbacks.MC_FAMILIAR_UPDATE,
    ModCallbacks.MC_POST_BOMB_UPDATE,
    ModCallbacks.MC_POST_PICKUP_UPDATE,
    ModCallbacks.MC_POST_SLOT_UPDATE,
    ModCallbacks.MC_POST_LASER_UPDATE,
    ModCallbacks.MC_POST_KNIFE_UPDATE,
    ModCallbacks.MC_POST_PROJECTILE_UPDATE,
    -- npcs included above
    -- ModCallbacks.MC_POST_EFFECT_UPDATE, --effects use table to avoid lag with using the callback generally
}

local EntityPreRenderCallbacks = {
    ModCallbacks.MC_PRE_PLAYER_RENDER,
    ModCallbacks.MC_PRE_TEAR_RENDER,
    ModCallbacks.MC_PRE_FAMILIAR_RENDER,
    ModCallbacks.MC_PRE_BOMB_RENDER,
    ModCallbacks.MC_PRE_PICKUP_RENDER,
    -- ModCallbacks.MC_PRE_LASER, no PRE_LASER_RENDER
    ModCallbacks.MC_PRE_KNIFE_RENDER,
    ModCallbacks.MC_PRE_PROJECTILE_RENDER,
    ModCallbacks.MC_PRE_NPC_RENDER,
    -- ModCallbacks.MC_POST_EFFECT_UPDATE, --effects use table to avoid lag with using the callback generally
    ModCallbacks.MC_PRE_SLOT_RENDER,
}

-- Also check in init callbacks to initialize gfx in first frame before appear freeze
local EntityInitCallbacks = {
    ModCallbacks.MC_POST_PLAYER_INIT,
    ModCallbacks.MC_POST_TEAR_INIT,
    ModCallbacks.MC_FAMILIAR_INIT,
    ModCallbacks.MC_POST_BOMB_INIT,
    ModCallbacks.MC_POST_PICKUP_INIT,
    -- add slots when rev callback uses new rep system
    ModCallbacks.MC_POST_LASER_INIT,
    ModCallbacks.MC_POST_KNIFE_INIT,
    ModCallbacks.MC_POST_PROJECTILE_INIT,
    ModCallbacks.MC_POST_NPC_INIT,
}

function UsesCallbackForOffset(entity)
    return entity.Type ~= EntityType.ENTITY_EFFECT and entity.Type ~= EntityType.ENTITY_LASER
end

for _, callback in ipairs(EntityUpdateCallbacks) do
    revel:AddCallback(callback, airMovement_PostEntityUpdate)
end
for _, callback in ipairs(EntityInitCallbacks) do
    revel:AddPriorityCallback(callback, CallbackPriority.LATE, airMovement_PostEntityUpdate)
end
for _, callback in ipairs(EntityPreRenderCallbacks) do
    revel:AddCallback(callback, airMovement_PreEntityRender)
end

-- handle effects
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i, ptr in ripairs(REVEL.ZPos.RoomEntitiesWithZPos) do
        local entity = ptr[1].Ref
        local hash = ptr[2]
        if entity and entity.Type == EntityType.ENTITY_EFFECT then
            UpdateEntity(entity)
        elseif not entity then
            table.remove(REVEL.ZPos.RoomEntitiesWithZPos, i)
            REVEL.ZPos.RoomEntitySet[hash] = nil
        end
    end
end)

-- Interpolation

-- Use render for all to avoid rerender/.Visible hijinks
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not REVEL.game:IsPaused() then
        for i, ptr in ripairs(REVEL.ZPos.RoomEntitiesWithZPos) do
            local entity = ptr[1].Ref
            local hash = ptr[2]
            if entity then
                local airMovementData = REVEL.ZPos.GetData(entity, true)
                local frame = entity.FrameCount
                if airMovementData and frame ~= airMovementData.LastInterpolationFrame then
                    InterpolateEntity(entity)
                    airMovementData.LastInterpolationFrame = frame
                end
            else
                table.remove(REVEL.ZPos.RoomEntitiesWithZPos, i)
                REVEL.ZPos.RoomEntitySet[hash] = nil
            end
        end

        for _, player in ipairs(REVEL.players) do
            local airMovementData = REVEL.ZPos.GetData(player, true)
            local frame = player.FrameCount
            if airMovementData and frame ~= airMovementData.LastInterpolationFrame then
                InterpolateEntity(player)
                airMovementData.LastInterpolationFrame = frame
            end
        end
    end
end)


--#region EntityCollision

local NoDataCollisionMode = REVEL.ZPos.EntityCollisionMode.SIMPLE_AIRBORNE

---Collide if distance between entities
---@param mainEntity Entity
---@param collEntity Entity
---@return boolean collides
local function EntityCollisionCheck(mainEntity, collEntity)
    local data1, data2 = REVEL.ZPos.GetData(mainEntity, true), REVEL.ZPos.GetData(collEntity, true)

    if not data1 and not data2 then return true end

    local mode1, mode2 = data1 and data1.EntityCollisionMode or NoDataCollisionMode, 
        data2 and data2.EntityCollisionMode or NoDataCollisionMode

    if mode1 == REVEL.ZPos.EntityCollisionMode.DONT_HANDLE 
    and mode2 == REVEL.ZPos.EntityCollisionMode.DONT_HANDLE
    then
        return true
    end
    -- At least one entity is in simple airborne or hitbox collision mode
    -- if previous if passed

    local collides = true
    local z1 = REVEL.ZPos.GetPosition(mainEntity)
    local z2 = REVEL.ZPos.GetPosition(collEntity)
    local ground1 = GetGroundLevel(mainEntity)
    local ground2 = GetGroundLevel(collEntity)

    -- If one entity is in simple airborne mode, and airborne, do not collide
    if mode1 == REVEL.ZPos.EntityCollisionMode.SIMPLE_AIRBORNE and z1 > ground1
    or mode2 == REVEL.ZPos.EntityCollisionMode.SIMPLE_AIRBORNE and z2 > ground2
    then
        collides = false
    -- Otherwise, if at least one entity is in hitbox mode, do hitbox check
    elseif mode1 == REVEL.ZPos.EntityCollisionMode.HITBOX or mode2 == REVEL.ZPos.EntityCollisionMode.HITBOX then
        local collZ1 = z1
        local collZ2 = z2
        -- Treat entities with DONT_HANDLE as being on the ground
        if mode1 == REVEL.ZPos.EntityCollisionMode.DONT_HANDLE then
            collZ1 = ground1
        end
        if mode2 == REVEL.ZPos.EntityCollisionMode.DONT_HANDLE then
            collZ2 = ground2
        end

        local dist = REVEL.ZPos.CollisionDistance(mainEntity, collEntity, collZ1, collZ2)
        collides = dist == 0
    end

    -- REVEL.DebugLog(("Collide check [%d.%d]x[%d.%d]: %d-%d, %f - %f"):format(
    --     mainEntity.Type, mainEntity.Variant,
    --     collEntity.Type, collEntity.Variant,
    --     mode1, mode2,
    --     z1, z2
    -- ))

    ---@type boolean?
    local callbackRet = Isaac.RunCallback(RevCallbacks.PRE_ZPOS_COLLISION_CHECK, mainEntity, collEntity, mode1, mode2, collides)
    if callbackRet ~= nil then
        collides = callbackRet
    end

    return collides
end

local function zpos_PreEntityCollision(_, entity, coll, low)
    if not EntityCollisionCheck(entity, coll) then
        return true -- ignore collision
    end
end

local CollisionCallbacks = {
    ModCallbacks.MC_PRE_PLAYER_COLLISION,
    ModCallbacks.MC_PRE_TEAR_COLLISION,
    ModCallbacks.MC_PRE_FAMILIAR_COLLISION,
    ModCallbacks.MC_PRE_PICKUP_COLLISION,
    ModCallbacks.MC_PRE_BOMB_COLLISION,
    ModCallbacks.MC_PRE_KNIFE_COLLISION,
    ModCallbacks.MC_PRE_PROJECTILE_COLLISION,
    ModCallbacks.MC_PRE_NPC_COLLISION,
}
for _, callbackId in ipairs(CollisionCallbacks) do
    revel:AddCallback(callbackId, zpos_PreEntityCollision)
end

-- Lasers not handled by collision callback

---@param entity Entity
---@param src EntityRef
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, dmg, flag, src, invuln)
    if src and src.Entity 
    and (
        HasBit(flag, DamageFlag.DAMAGE_LASER)
        or src.Type == EntityType.ENTITY_LASER --usually it's the first case, but jic
    )
    and REVEL.ZPos.GetData(entity, true) 
    then
        local sourceEnt = REVEL.GetEntFromRef(src)
        if not EntityCollisionCheck(entity, sourceEnt) then
            return false
        end
    end
end)

--#endregion

--#region GroundLevel

-- Supports both higher than average ground level,
-- and "negative" ground level. Doesn't offer much handling for things that
-- would be expected from that, like lower ground entities colliding against
-- a higher ground place, past the air movement basics.
-- Visuals for negative ground level are also weird without specific retouching in
-- its own logic.

-- By default: use the REVEL.SetIndexGroundLevel function
-- to change the ground level of a grid index, or use the ZPOS_GET_GROUND_LEVEL
-- for more specific functionality. Index ground level persists.

-- readonly
local EMPTY_TABLE = setmetatable({}, {__newindex = function() end})

local function GetGroundIndexTable(create, currentRoom)
    currentRoom = currentRoom or StageAPI.GetCurrentRoom()

    if not currentRoom then
        if create then
            REVEL.DebugLog("[WARN] GetGroundIndexTable | not in stageapi room (or not initialized yet)")
        end
        return EMPTY_TABLE
    end

    if not currentRoom.PersistentData.ZPosGroundLevel then
        if create then
            currentRoom.PersistentData.ZPosGroundLevel = {}
        else
            return EMPTY_TABLE
        end
    end
    return currentRoom.PersistentData.ZPosGroundLevel
end

-- by entity or y/x
local GroundLevelCache = {}
local LastCacheFrame = -1

---@param pos Vector
---@param entity? Entity
---@param noCache? boolean
---@return number
---@overload fun(entity: Entity, useCache?: boolean): number
---@overload fun(index: integer, useCache?: boolean): number
function GetGroundLevel(pos, entity, noCache)
    ---@diagnostic disable-next-line: undefined-field
    if type(pos) == "number" then
        pos = REVEL.room:GetGridPosition(pos)
    elseif type(entity) ~= "userdata" and pos.Position then
        entity = pos
        pos = entity.Position
        noCache = entity
    end

    if LastCacheFrame ~= REVEL.game:GetFrameCount() then
        GroundLevelCache = {}
        LastCacheFrame = REVEL.game:GetFrameCount()
    end

    -- cache get
    local hash
    if entity then
        hash = GetPtrHash(entity)
        if GroundLevelCache[hash] then
            if noCache then
                GroundLevelCache[hash] = nil
            else
                return GroundLevelCache[hash]
            end
        end
    else
        if GroundLevelCache[pos.Y] then
            if GroundLevelCache[pos.Y][pos.X] then
                if noCache then
                    GroundLevelCache[pos.Y][pos.X] = nil
                else
                    return GroundLevelCache[pos.Y][pos.X]
                end
            end
        elseif not noCache then
            GroundLevelCache[pos.Y] = {}
        end
    end
    
    local groundByIndex = GetGroundIndexTable(false)
    local index = REVEL.room:GetGridIndex(pos)
    local groundLevel = groundByIndex[index] or REVEL.ZPos.LEVEL_GROUND_BASE

    local callbackRet = Isaac.RunCallback(RevCallbacks.ZPOS_GET_GROUND_LEVEL, pos, entity, groundLevel)
    if callbackRet then
        groundLevel = callbackRet
    end

    -- cache set
    if entity then
        hash = hash or GetPtrHash(entity)
        GroundLevelCache[hash] = groundLevel
    else
        GroundLevelCache[pos.Y][pos.X] = groundLevel
    end


    return groundLevel
end

REVEL.ZPos.GetGroundLevel = GetGroundLevel

---@param index integer | Vector
---@param level number
---@param currentRoom? LevelRoom In case the room is not initialized yet
function REVEL.ZPos.SetIndexGroundLevel(index, level, currentRoom)
    if type(index) == "userdata" and index.X then
        index = REVEL.room:GetGridIndex(index)
    end

    if level ~= 0 then
        GetGroundIndexTable(true, currentRoom)[index] = level
    else
        GetGroundIndexTable(true, currentRoom)[index] = nil
    end
end

if REVEL.DEBUG then
    local TEST_GROUND_META = "Test - Airmovement Ground Level"

    ---@param currentRoom LevelRoom
    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 0, function(currentRoom)
        local metaents = currentRoom.Metadata:Search{
            Name = TEST_GROUND_META, 
        }

        for _, metaent in ipairs(metaents) do
            local index = metaent.Index
            local groundLevel = metaent.BitValues.GroundLevel
            REVEL.DebugLog("Setting", index, "to", groundLevel)
            REVEL.ZPos.SetIndexGroundLevel(index, groundLevel)
        end
    end)

    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local currentRoom = StageAPI.GetCurrentRoom()

        if currentRoom then
            local metaents = currentRoom.Metadata:Search{
                Name = TEST_GROUND_META, 
            }
    
            for _, metaent in ipairs(metaents) do
                local index = metaent.Index
                local pos = REVEL.room:GetGridPosition(index)
                local groundLevel = metaent.BitValues.GroundLevel
                local renderPos = Isaac.WorldToScreen(pos)
                Isaac.RenderText(tostring(groundLevel), renderPos.X, renderPos.Y, 255, 255, 255, 255)
            end
        end
    end)

end

--#endregion

--#region Deprecated

---@deprecated Use Airmovement function instead
function REVEL.UpdateEntityAirMovement(entity, airMovementData)
    if airMovementData then
        REVEL.DebugLog("UpdateEntityAirMovement | deprecated, also setting airMovementData useless now")
    end
    UpdateEntity(entity)
end

--#endregion

end