return function()


local DefaultUpdatesOnRender = true

---@param entity1 Entity
---@param entity2 Entity
---@return number
function REVEL.ZPos.Distance(entity1, entity2)
    return math.abs(REVEL.ZPos.GetPosition(entity1) - REVEL.ZPos.GetPosition(entity2))
end

---Distance between entity "hitboxes" on z level, considering height; 0 if they overlap.
---@param entity1 Entity
---@param entity2 Entity
---@param z1? number
---@param z2? number
---@return number
function REVEL.ZPos.CollisionDistance(entity1, entity2, z1, z2)
	local data1 = REVEL.ZPos.GetData(entity1, true)
	local data2 = REVEL.ZPos.GetData(entity2, true)
    z1 = z1 or REVEL.ZPos.GetPosition(entity1)
    z2 = z2 or REVEL.ZPos.GetPosition(entity2)

    -- Consider height of the lower entity, the other's doesn't matter for this purpose
	local collisionHeight
    if z1 > z2 then
        collisionHeight = data2 and data2.EntityCollisionHeight or REVEL.GetEntityHeight(entity2)
    else
        collisionHeight = data1 and data1.EntityCollisionHeight or REVEL.GetEntityHeight(entity1)
    end

    return math.max(math.abs(z2 - z1) - collisionHeight, 0)
end

---Time left (in update amount) before landing (reaching z 0), assuming no external changes to velocity z position etc
---@param entity Entity
---@param round? boolean
---@return number updates
function REVEL.ZPos.FramesBeforeLanding(entity, round)
    local airMovementData = REVEL.ZPos.GetData(entity)

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
function REVEL.ZPos.DistanceBeforeLanding(entity, xySpeed)
    xySpeed = xySpeed or entity.Velocity:Length()

    return REVEL.ZPos.FramesBeforeLanding(entity, false) * xySpeed
end

---How much z velocity should be for the entity to fly the specified distance before landing
---@param entity Entity
---@param flyDistance number
---@param xySpeed number
---@return number zSpeed
function REVEL.ZPos.GetNeededVelocityForDistance(entity, flyDistance, xySpeed)
    local airMovementData = REVEL.ZPos.GetData(entity)

    local g = airMovementData.Gravity
    local h = REVEL.ZPos.GetPosition(entity)
    xySpeed = xySpeed or entity.Velocity:Length()
    if DefaultUpdatesOnRender then --game velocity is applied on updates only
        xySpeed = xySpeed / 2
    end

    local zSpeed = (flyDistance^2 * g - 2 * xySpeed^2 * h) / (2 * flyDistance * xySpeed) --trust wolfram alpha on this one

    return zSpeed
end


--#region Deprecated

---@deprecated
function REVEL.GetUpdatesBeforeZLanding(entity, round)
    return REVEL.ZPos.FramesBeforeLanding(entity, round)
end
---@deprecated
function REVEL.GetDistanceBeforeZLanding(entity, xySpeed)
    return REVEL.ZPos.DistanceBeforeLanding(entity, xySpeed)
end
---@deprecated
function REVEL.GetNeededZSpeedForDistance(entity, flyDistance, xySpeed)
    return REVEL.ZPos.GetNeededVelocityForDistance(entity, flyDistance, xySpeed)
end
--#endregion

end