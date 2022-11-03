local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------
-- SAND CASTLES --
------------------

local SandCastleDropChances = {
    {6 / 100, PickupVariant.PICKUP_COIN},
    {2 / 100, PickupVariant.PICKUP_HEART},
    {0.3 / 100, PickupVariant.PICKUP_TRINKET, REVEL.ITEM.ARCHAEOLOGY.id},
    {0.075 / 100, PickupVariant.PICKUP_TRINKET, REVEL.ITEM.SPARE_CHANGE.id},
    {0.04 / 100, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_BROKEN_ANKH},
}

function REVEL.GetSandCastleFrame(left, right, up, down, farleft, farright, existingFrame)
    local noTower = existingFrame and (existingFrame == 1 or existingFrame == 2 or existingFrame == 4 or existingFrame == 5 or existingFrame == 8 or existingFrame == 9 or existingFrame == 10 or existingFrame == 21 or existingFrame == 22)
	local frame = 21

    if not noTower then
        if left and right and up and down then frame = 12
        elseif left and right and up then frame = 19
        elseif left and right and down then frame = 24
        elseif left and up and down then frame = 18
        elseif right and up and down then frame = 20
        elseif left and up then frame = 3
        elseif right and up then frame = 6
        elseif left and down then frame = 11
        elseif right and down then frame = 13
        elseif left and right and farleft and farright then frame = 9
        elseif left and right then frame = 5
        elseif up and down then frame = 10
        elseif up then frame = 0
        elseif down then frame = 16
        elseif left then frame = 15
        elseif right then frame = 14
        else frame = 7 end
    else
        if left and right and farleft and farright then frame = 9
        elseif left and right then frame = 5
        elseif up and down then frame = 10
        elseif up then frame = 1
        elseif down then frame = 2
        elseif left then frame = 4
        elseif right then frame = 8
        elseif existingFrame == 1 or existingFrame == 2 or existingFrame == 10 then frame = 22
        else frame = 21 end
    end

	return frame
end

local SandCastleAdjacentChecks = {
    {X = -1, Y = 0},
    {X = 1, Y = 0},
    {X = 0, Y = -1},
    {X = 0, Y = 1},
    {X = -2, Y = 0},
    {X = 2, Y = 0}
}

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SELECT_ENTITY_LIST, 1, function(entityList, index)
    local changed = false
    local retEntityList = {}
    local addEntities = {}
    for ind, entData in StageAPI.ReverseIterate(entityList) do
        if entData.Type == REVEL.ENT.SAND_CASTLE.id and entData.Variant == REVEL.ENT.SAND_CASTLE.variant then
            addEntities[#addEntities + 1] = entData
            changed = true
        else
            retEntityList[#retEntityList + 1] = entData
        end
    end

    if changed then
        return addEntities, retEntityList, true
    end
end)

function REVEL.GetSandCastleFrames(sandCastleIndices, existingFrames, width, height)
    local sandCastleFrames = {}
    for index, _ in pairs(sandCastleIndices) do
        local x, y = StageAPI.GridToVector(index, width)
        local adjIndices = {}
        for _, adjust in ipairs(SandCastleAdjacentChecks) do
            local nX, nY = x + adjust.X, y + adjust.Y
            if (nX >= 0 and nX <= width) and (nY >= 0 and nY <= height) then
                local backToGrid = StageAPI.VectorToGrid(nX, nY, width)
                if sandCastleIndices[backToGrid] then
                    adjIndices[#adjIndices + 1] = true
                else
                    adjIndices[#adjIndices + 1] = false
                end
            else
                adjIndices[#adjIndices + 1] = false
            end
        end

        local existingFrame
        if existingFrames and existingFrames[index] then
            existingFrame = existingFrames[index]
        end

        adjIndices[#adjIndices + 1] = existingFrame

        sandCastleFrames[tostring(index)] = REVEL.GetSandCastleFrame(
            table.unpack(adjIndices)
        )
    end

    return sandCastleFrames
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_INIT, 1, function(newRoom)
    local hasSandCastle, sandCastleIndices = false, {}
    for index, spawnEntities in pairs(newRoom.SpawnEntities) do
        for _, entityInfo in ipairs(spawnEntities) do
            local entityData = entityInfo.Data
            if entityData.Type == REVEL.ENT.SAND_CASTLE.id and entityData.Variant == REVEL.ENT.SAND_CASTLE.variant then
                sandCastleIndices[index] = true
                hasSandCastle = true
            end
        end
    end

    if hasSandCastle then
        newRoom.PersistentData.SandCastleFrames = REVEL.GetSandCastleFrames(sandCastleIndices, nil, newRoom.Layout.Width, newRoom.Layout.Height)
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SPAWN_ENTITY, 1, function(info, entityList, index, doGrids, doPersistentOnly, doAutoPersistent, avoidSpawning, persistentPositions)
    if info.Data.Type == REVEL.ENT.SAND_CASTLE.id and info.Data.Variant == REVEL.ENT.SAND_CASTLE.variant then
        if doGrids then
            REVEL.GRIDENT.SAND_CASTLE:Spawn(index, true, false)
        end

        return false
    end
end)

local shouldUpdateFramesOnReenter = {} --list of room ids

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if not REVEL.room:IsFirstVisit() and REVEL.STAGE.Tomb:IsStage() and shouldUpdateFramesOnReenter[StageAPI.GetCurrentRoomID()] then
        REVEL.UpdateSandCastleFrames()
        shouldUpdateFramesOnReenter[StageAPI.GetCurrentRoomID()] = nil
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, function(customGrid)
    local persistData = customGrid.PersistentData
	local grindex = customGrid.GridIndex
	local grid = customGrid.GridEntity
	
	if not persistData.Frame then
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.PersistentData.SandCastleFrames then
            persistData.Frame = currentRoom.PersistentData.SandCastleFrames[tostring(grindex)]
        else
            persistData.Frame = 21
        end
    end

    if not REVEL.room:IsFirstVisit() then
        shouldUpdateFramesOnReenter[StageAPI.GetCurrentRoomID()] = true
    end

    local sprite = grid:GetSprite()
    sprite.FlipX = false
    if REVEL.IsGridBroken(grid) then
        sprite:SetFrame("Broken", math.random(0,3))
    elseif REVEL.GetPoopDamagePct(grid) > 0 then
        sprite:SetFrame("HalfBroken", persistData.Frame)
    else
        sprite:SetFrame("Default", persistData.Frame)
    end
end, REVEL.GRIDENT.SAND_CASTLE.Name)

function REVEL.UpdateSandCastleFrames()
    local sandcastles = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.SAND_CASTLE.Name)
    local sandCastleIndices, existingFrames = {}, {}
    for _, castle in ipairs(sandcastles) do
        local grid = REVEL.room:GetGridEntity(castle.GridIndex)
        if grid and not REVEL.IsGridBroken(grid) then
            sandCastleIndices[castle.GridIndex] = true
            if not grid:GetSprite():IsFinished("Broken") then
                existingFrames[castle.GridIndex] = grid:GetSprite():GetFrame()
            end
        end
    end

    local sandCastleFrames = REVEL.GetSandCastleFrames(sandCastleIndices, existingFrames, REVEL.room:GetGridWidth(), REVEL.room:GetGridHeight())
    StageAPI.GetCurrentRoom().PersistentData.SandCastleFrames = sandCastleFrames
    for strindex, frame in pairs(sandCastleFrames) do
        local grid = REVEL.room:GetGridEntity(tonumber(strindex))
        if grid and not REVEL.IsGridBroken(grid) then
            local sprite = grid:GetSprite()
            if REVEL.GetPoopDamagePct(grid) > 0 then
                sprite:SetFrame("HalfBroken", frame)
            else
                sprite:SetFrame("Default", frame)
            end

            local persistData = StageAPI.GetCustomGrid(tonumber(strindex), REVEL.GRIDENT.SAND_CASTLE.Name)
            if persistData then
                persistData.Frame = frame
            end
        end
    end
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 1, function(customGrid)
    local grid = customGrid.GridEntity
	
	local sprite = grid:GetSprite()
    if REVEL.GetPoopDamagePct(grid) > 0 and not REVEL.IsGridBroken(grid) and not sprite:IsFinished("HalfBroken") then
        if sprite:IsFinished("Broken") then
            REVEL.UpdateSandCastleFrames()
        else
            sprite:SetFrame("HalfBroken", sprite:GetFrame())
        end
    elseif REVEL.IsGridBroken(grid) and not sprite:IsFinished("Broken") then
        local frame = sprite:GetFrame()
        if frame == 1 or frame == 2 or frame == 4 or frame == 5 or frame == 8 or frame == 9 or frame == 10 or frame == 21 or frame == 22 then
            sprite:SetFrame("Broken", math.random(0,1))
        else
            sprite:SetFrame("Broken", math.random(2,3))
        end

        REVEL.UpdateSandCastleFrames()
    elseif REVEL.GetPoopDamagePct(grid) == 0 and not sprite:IsFinished("Default") then
        if sprite:IsFinished("Broken") then
            REVEL.UpdateSandCastleFrames()
        else
            sprite:SetFrame("Default", sprite:GetFrame())
        end
    end
end, REVEL.GRIDENT.SAND_CASTLE.Name)

---@param customGrid CustomGridEntity
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_DESTROY, 1, function(customGrid)
    local r = customGrid.RNG and customGrid.RNG:RandomFloat() or math.random()
    local selected = nil

    local chancesMult = 1
    if REVEL.OnePlayerHasTrinket(REVEL.ITEM.ARCHAEOLOGY.id) then
        chancesMult = chancesMult + 1
    end

    local chances = REVEL.map(SandCastleDropChances, function(dropEntry)
        if dropEntry[2] == PickupVariant.PICKUP_TRINKET
        and dropEntry[3] and REVEL.OnePlayerHasTrinket(dropEntry[3])
        then
            return {
                0,
                dropEntry[2],
                dropEntry[3],
            }
        end
        return dropEntry
    end)


    for _, dropEntry in ipairs(chances) do
        local chance = dropEntry[1] * chancesMult
        if r < chance then
            selected = dropEntry
            break
        else
            r = r - chance
        end
    end

    if selected then
        local pos = REVEL.room:GetGridPosition(customGrid.GridIndex)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, selected[2], selected[3] or 0, 
            pos, Vector.Zero, nil)
    end
end, REVEL.GRIDENT.SAND_CASTLE.Name)

function REVEL.SandCastleParticleCheck(_, eff)
    if not eff:GetData().SandCastleRegistered and StageAPI.IsCustomGrid(REVEL.room:GetGridIndex(eff.Position), REVEL.GRIDENT.SAND_CASTLE.Name) then
        if eff.Variant == EffectVariant.POOP_EXPLOSION then
			eff:GetSprite().Color = Color(0,0,0,1,conv255ToFloat(93,65,40))
		elseif eff.Variant == EffectVariant.POOP_PARTICLE then
			eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_gibs.png")
			eff:GetSprite():LoadGraphics()
		end
    end
	eff:GetData().SandCastleRegistered = true
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, REVEL.SandCastleParticleCheck, EffectVariant.POOP_EXPLOSION)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, REVEL.SandCastleParticleCheck, EffectVariant.POOP_PARTICLE)

end

REVEL.PcallWorkaroundBreakFunction()