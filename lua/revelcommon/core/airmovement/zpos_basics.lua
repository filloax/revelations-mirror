return function()


-------------
--ZVELOCITY--
-------------
-- ZVelocity is how fast the entity is currently moving in the air.
-- A positive ZVelocity is flying, a negative ZVelocity is falling.

-- Adds the value provided to the current ZVelocity on the entity
function REVEL.ZPos.AddVelocity(entity, velocity)
	local airMovementData = REVEL.ZPos.TryInitEntity(entity)
	airMovementData.ZVelocity = airMovementData.ZVelocity + velocity
end

-- Sets ZVelocity on the entity
function REVEL.ZPos.SetVelocity(entity, velocity)
	local airMovementData = REVEL.ZPos.TryInitEntity(entity)
	airMovementData.ZVelocity = velocity
end

-- Returns the entity's current ZVelocity
function REVEL.ZPos.GetVelocity(entity)
    local airMovementData = REVEL.ZPos.GetData(entity, true)
	if airMovementData and airMovementData.ZVelocity then
		return airMovementData.ZVelocity
	end
	return 0
end

-------------
--ZPOSITION--
-------------
-- ZPosition is how how high up in the air the entity currently is.
-- Entities cannot have a negative ZPoistion.

-- Adds the value provided to the current ZPosition on the entity
function REVEL.ZPos.AddPosition(entity, position)
	local airMovementData = REVEL.ZPos.TryInitEntity(entity)
	airMovementData.ZPosition = airMovementData.ZPosition + position
end

-- Sets ZPosition on the entity
function REVEL.ZPos.SetPosition(entity, position)
	local airMovementData = REVEL.ZPos.TryInitEntity(entity)
	REVEL.ZPos.TryInitEntity(entity, airMovementData)
	airMovementData.ZPosition = position
end

-- Returns the entity's current ZPosition
function REVEL.ZPos.GetPosition(entity)
	local airMovementData = REVEL.ZPos.GetData(entity, true)
	if airMovementData and airMovementData.ZPosition then
		return airMovementData.ZPosition
	end
	return 0
end

-- Sets air movement data on the entity.
---@param entity Entity
---@param airMovementData AirMovementData
---@return AirMovementData
function REVEL.ZPos.SetData(entity, airMovementData)
	local data = REVEL.GetData(entity)
	data.AirMovement = REVEL.ZPos.TryInitEntity(entity, data.AirMovement)
	for value, valueData in pairs(airMovementData) do
		data.AirMovement[value] = valueData
	end
	return data.AirMovement
end

---@param entity Entity
---@param noInit? boolean
---@return AirMovementData
function REVEL.ZPos.GetData(entity, noInit)
	local data = REVEL.GetData(entity)
	if not noInit then
		data.AirMovement = data.AirMovement or {}
		REVEL.ZPos.TryInitEntity(entity, data.AirMovement)
	end
	
	return data.AirMovement
end


--#region Deprecated

---@deprecated
function REVEL.AddEntityZVelocity(entity, velocity)
	return REVEL.ZPos.AddVelocity(entity, velocity)
end

---@deprecated
function REVEL.SetEntityZVelocity(entity, velocity)
	return REVEL.ZPos.SetVelocity(entity, velocity)
end

---@deprecated
function REVEL.GetEntityZVelocity(entity)
	return REVEL.ZPos.GetVelocity(entity)
end

---@deprecated
function REVEL.AddEntityZPosition(entity, position)
	return REVEL.ZPos.AddPosition(entity, position)
end

---@deprecated
function REVEL.SetEntityZPosition(entity, position)
	return REVEL.ZPos.SetPosition(entity, position)
end

---@deprecated
function REVEL.GetEntityZPosition(entity)
	return REVEL.ZPos.GetPosition(entity)
end

---@deprecated
function REVEL.SetEntityDefaultAirMovement(entity, airMovementData)
	return REVEL.ZPos.TryInitEntity(entity, airMovementData)
end
---@deprecated
function REVEL.SetEntityAirMovement(entity, airMovementData)
	return REVEL.ZPos.SetData(entity, airMovementData)
end
---@deprecated
function REVEL.GetAirMovementData(entity)
	return REVEL.ZPos.GetData(entity)
end
--#endregion

end