local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

local SpikeState = require("lua.revelcommon.enums.SpikeState")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------
-- TRAPS --
-----------

--[[

Trap types

Name = { -- name needs to match name in the Variants.Traps table
    OnSelect = function,
    OnSpawn = function, -- for spawning arrow trap heads, linking to coffins
    OnTrigger = function,  OnTrigger(tile, data, player, isPositiveEffect)
    OnUpdate = function,
    IsValidRandomSpawn = function, -- eventually unused, get fine random trap positions.
    SingleUse = boolean,
    Cooldown = integer
}

]]

REVEL.TrapTypes = {
    Blank = {},
}

REVEL.MinTraps = 3
REVEL.MaxTraps = 5
REVEL.PerilMinTraps = 5
REVEL.PerilMaxTraps = 7

REVEL.TrapSelectionRNG = REVEL.RNG()
REVEL.ParanoiaTileRNG = REVEL.RNG()

REVEL.TrapDirectionToRotation = {
    Right = 270,
    Down = 0,
    Left = 90,
    Up = 180
}

--[[
    metaEntity =  {
        Entity = {
            SubType = 0,
            GridX = 11,
            Index = 42,
            Type = 789,
            Variant = 6,
            GridY = 1
        },
        Index = 42,
        Metadata = {
            ConflictTag = "RevTraps",
            Type = 789,
            Variant = 6,
            Tags = ["RevTraps"],
            Name = "ArrowTrap"
        },
        Name = "ArrowTrap"
    }
]]

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, function(newRoom, fromSaveData, saveData)
    local traps = newRoom.Metadata:Search{Tag = "RevTraps"}

    if traps and next(traps) then
        REVEL.TrapSelectionRNG:SetSeed(newRoom.Seed, 0)
        local potentialTraps, forcedTraps = {}, {}
        for _, metaEntity in ipairs(traps) do
            if newRoom.Metadata:Has{Index = metaEntity.Index, Name = "ForcedTrap"} then
                forcedTraps[#forcedTraps + 1] = {metaEntity.Name, metaEntity.Index}
            else
                potentialTraps[#potentialTraps + 1] = {metaEntity.Name, metaEntity.Index}
            end
        end

        local spawnTrapData = forcedTraps
        if #potentialTraps > 0 then
            potentialTraps = REVEL.Shuffle(potentialTraps)
            local min, max = REVEL.MinTraps, REVEL.MaxTraps
            if REVEL.IsShrineEffectActive(ShrineTypes.PERIL) then
                min, max = REVEL.PerilMinTraps, REVEL.PerilMaxTraps
            end

            local numToSpawn = StageAPI.Random(math.min(min, #potentialTraps), math.min(max, #potentialTraps), REVEL.TrapSelectionRNG)
            for i = 1, numToSpawn do
                spawnTrapData[#spawnTrapData + 1] = potentialTraps[i]
            end
        end

        if #spawnTrapData > 0 then
            local spawnTraps = {}
            for _, trapData in ipairs(spawnTrapData) do
                local trap = {}
                trap.Cooldown = 0
                trap.Trap = trapData[1]
                trap.Index = trapData[2]
                local direction = newRoom.Metadata:Search({Index = trap.Index, Name = "Direction"})[1]
                if direction then
                    trap.Angle = direction.BitValues.Direction*22.50
                end
                --trap.Angle = newRoom.Metadata:GetDirections(trap.Index)[1]
                if trap.Angle then
                    trap.Rotation = (trap.Angle - 90) % 360 --how much to rotate some traps' sprites
                end

                local strindex = tostring(trap.Index)

                if REVEL.TrapTypes[trap.Trap] and REVEL.TrapTypes[trap.Trap].OnSelect then
                    REVEL.TrapTypes[trap.Trap].OnSelect(trap, trap.Index)
                end

                spawnTraps[strindex] = trap
            end

            newRoom.PersistentData.Traps = spawnTraps
            newRoom:SetTypeOverride(RevRoomType.TRAP)
        end
    elseif not newRoom.PersistentData.Traps and (newRoom.TypeOverride == RevRoomType.TRAP or REVEL.IsPrideRoom()) then --defined in sins2
        newRoom.PersistentData.Traps = REVEL.SelectTrapsRandomly(newRoom)
    end

    if newRoom.PersistentData.Traps 
    and not REVEL.isEmpty(newRoom.PersistentData.Traps) 
    and REVEL.IsShrineEffectActive(ShrineTypes.PARANOIA) then
        local fakeTraps = REVEL.AddParanoiaTiles(newRoom)
        for strindex, trapData in pairs(fakeTraps) do
            newRoom.PersistentData.Traps[strindex] = trapData
        end
    end

    if newRoom.PersistentData.Traps then
        local trapsOverlapping = {}
        local hasSpikeTrap
        for strindex, trap in pairs(newRoom.PersistentData.Traps) do
            if trap.Trap == "SpikeTrap" or trap.Trap == "SpikeTrapOffset" then
                hasSpikeTrap = true
            end
        end

        if hasSpikeTrap then
            for _, metaEntity in ipairs(newRoom.Metadata:Search{Tag = "SpikeTrap"}) do
                local gridData = {
                    Type = GridEntityType.GRID_SPIKES,
                    Variant = 0,
                    Index = metaEntity.Index
                }

                newRoom.SpawnGrids[gridData.Index] = gridData
                newRoom.GridTakenIndices[gridData.Index] = true

                if not newRoom.Data.SpikeTrapSpikes then
                    newRoom.Data.SpikeTrapSpikes = {}
                end

                newRoom.Data.SpikeTrapSpikes[gridData.Index] = metaEntity.Name == "SpikeTrapSpike"
            end
        end
    end

    if newRoom.TypeOverride ~= RevRoomType.TRAP then
        for index, entityList in pairs(newRoom.SpawnEntities) do
            for _, entityInfo in ipairs(entityList) do
                if entityInfo.Data.Type == REVEL.ENT.TILE_MONGER.id and entityInfo.Data.Variant == REVEL.ENT.TILE_MONGER.variant then
                    newRoom:SetTypeOverride(RevRoomType.TRAP)
                    break
                end
            end

            if newRoom.TypeOverride == RevRoomType.TRAP then
                break
            end
        end

        if newRoom.Metadata:Has{Name = "TileMongerTile"} then
            newRoom:SetTypeOverride(RevRoomType.TRAP)
        end
    end
end)

function REVEL.SpawnTrapTile(ind, trapData)
    local tile = StageAPI.SpawnFloorEffect(REVEL.room:GetGridPosition(ind), Vector.Zero, nil, "gfx/grid/revel2/traps/traptiles.anm2", true)
    local sprite, data = tile:GetSprite(), tile:GetData()
    data.TrapTriggerCooldown = trapData.Cooldown
    data.TrapData = trapData
    data.TrapName = data.TrapData.Trap

    if REVEL.TrapTypes[data.TrapName] and REVEL.TrapTypes[data.TrapName].Animation then
        data.Animation = REVEL.TrapTypes[data.TrapName].Animation
    else
        data.Animation = "Arrow"
    end

    local currentRoom = StageAPI.GetCurrentRoom()
    if (currentRoom and currentRoom.Metadata:Has{Index = ind, Name = "TrapUnknown"}) 
    or REVEL.IsShrineEffectActive(ShrineTypes.PARANOIA) then
        data.Animation = "Unknown"
    end

    sprite:SetFrame(data.Animation, 0)

    if REVEL.TrapTypes[data.TrapName] and REVEL.TrapTypes[data.TrapName].OnSpawn then
        REVEL.TrapTypes[data.TrapName].OnSpawn(tile, data, ind)
    end

    return tile
end

function REVEL.GetTrapTiles()
    return REVEL.filter(
        Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V),
        function(eff) return eff:GetData().TrapData end
    )
end

function REVEL.SelectTrapsRandomly(newRoom)
    REVEL.TrapSelectionRNG:SetSeed(newRoom.Seed, 0)
    local validTraps = {}

    for i = 0, REVEL.room:GetGridSize() do
        if not REVEL.room:GetGridEntity(i) and (not newRoom or not newRoom.Layout or (not newRoom.GridTakenIndices[i] and not newRoom.EntityTakenIndices[i])) and REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
            local nearDoor
            for slot = 0, 7 do
                if REVEL.room:IsDoorSlotAllowed(slot) and REVEL.room:GetDoorSlotPosition(slot):DistanceSquared(REVEL.room:GetGridPosition(i)) < 100 ^ 2 then
                    nearDoor = true
                    break
                end
            end

            if not nearDoor then
                local validAtGrid = {}

                for name, trapType in pairs(REVEL.TrapTypes) do
                    if trapType.IsValidRandomSpawn then
                        local isValid = trapType.IsValidRandomSpawn(i)
                        if isValid then
                            local trapData = {
                                Index = i,
                                Trap = name,
                                Angle = 90,
                                Cooldown = 0
                            }

                            if type(isValid) == "table" then
                                for k, v in pairs(isValid) do
                                    trapData[k] = v
                                end
                            end

                            if trapData.Angle then
                                trapData.Rotation = (trapData.Angle - 90) % 360 --how much to rotate some traps' sprites
                            end
            
                            validAtGrid[#validAtGrid + 1] = trapData
                        end
                    end
                end

                if #validAtGrid > 0 then
                    validTraps[#validTraps + 1] = {
                        Index = i,
                        TrapData = validAtGrid[StageAPI.Random(1, #validAtGrid, REVEL.TrapSelectionRNG)]
                    }
                end
            end
        end
    end

    local traps = {}

    if #validTraps > 0 then
        validTraps = REVEL.Shuffle(validTraps, REVEL.TrapSelectionRNG)
        local min, max = REVEL.MinTraps, REVEL.MaxTraps
        if REVEL.IsShrineEffectActive(ShrineTypes.PERIL) then
            min, max = REVEL.PerilMinTraps, REVEL.PerilMaxTraps
        end

        local numToSpawn = StageAPI.Random(math.min(min, #validTraps), math.min(max, #validTraps), REVEL.TrapSelectionRNG)
        Isaac.DebugString("Can spawn " .. tostring(#validTraps) .. " traps")
        Isaac.DebugString("Spawning " .. tostring(numToSpawn) .. " traps")
        for i = 1, numToSpawn do
            local trap = validTraps[i]
            if trap then
                traps[tostring(trap.Index)] = trap.TrapData
            else
                Isaac.DebugString("Spawning trap failed, index " .. tostring(i))
            end
        end
    end

    return traps
end

function REVEL.AddParanoiaTiles(newRoom)
    REVEL.ParanoiaTileRNG:SetSeed(newRoom.Seed, 0)

    local fakeTraps = {}
    local validTiles = {}

    for i = 0, REVEL.room:GetGridSize() do
        if not REVEL.room:GetGridEntity(i) and (
            not newRoom 
            or not newRoom.Layout 
            or (not newRoom.GridTakenIndices[i] and not newRoom.EntityTakenIndices[i])
        ) and REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
            local nearDoor
            for slot = 0, 7 do
                if REVEL.room:IsDoorSlotAllowed(slot) 
                and REVEL.room:GetDoorSlotPosition(slot):DistanceSquared(REVEL.room:GetGridPosition(i)) < 100 ^ 2 then
                    nearDoor = true
                    break
                end
            end

            if not nearDoor then
                validTiles[#validTiles + 1] = i
            end
        end
    end

    if #validTiles > 0 then
        validTiles = REVEL.Shuffle(validTiles, REVEL.ParanoiaTileRNG)
        local min, max = math.floor(REVEL.MinTraps / 2), math.floor(REVEL.MaxTraps / 2)
        if REVEL.IsShrineEffectActive(ShrineTypes.PERIL) then
            min, max = math.floor(REVEL.PerilMinTraps / 2), math.floor(REVEL.PerilMaxTraps / 2)
        end

        local numToSpawn = StageAPI.Random(min, max, REVEL.ParanoiaTileRNG)
        Isaac.DebugString("Spawning " .. tostring(numToSpawn) .. " paranoia tiles")

        for i = 1, numToSpawn do
            local trapData = {
                Index = validTiles[i],
                Trap = "Blank",
                Angle = 0,
                Cooldown = 0
            }
            fakeTraps[tostring(trapData.Index)] = trapData
        end
    end

    return fakeTraps
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, isFirstVisit, isExtraRoom)
    if newRoom.Data.SpikeTrapSpikes then
        for strindex, isDownAtStart in pairs(newRoom.Data.SpikeTrapSpikes) do
            local grindex = tonumber(strindex)
            if isDownAtStart or newRoom.Metadata:Has{Index = grindex, Name = "DisableOnClear"} then
                local grid = REVEL.room:GetGridEntity(grindex)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES then
                    grid.State = SpikeState.SPIKE_OFF
                    local sprite = grid:GetSprite()
                    sprite:SetFrame("Unsummon", 11)
                end
            end
        end
    end

    if newRoom.PersistentData.Traps then
        for strindex, trap in pairs(newRoom.PersistentData.Traps) do
            REVEL.SpawnTrapTile(tonumber(strindex), trap)
        end
    end

    local tileMongers = Isaac.FindByType(REVEL.ENT.TILE_MONGER.id, REVEL.ENT.TILE_MONGER.variant, -1, false, false)

    local maxGroup = REVEL.reduce(newRoom.Metadata:Search{Name = "Group"}, function(prevMax, currentGroup)
        local groupId = currentGroup.BitValues.GroupID
        return math.max(prevMax, groupId)
    end, -1)

    local tileMongerTiles = newRoom.Metadata:Search{Name = "TileMongerTile"}
    for _, metaEntity in ipairs(tileMongerTiles) do
        local index = metaEntity.Index
        local invalid
        for _, tileMonger in ipairs(tileMongers) do
            if REVEL.room:GetGridIndex(tileMonger.Position) == index then
                invalid = true
                break
            end
        end

        if not invalid then
            REVEL.SpawnTileMongerTile(index)
        end
    end

    local autoShooterTraps = newRoom.Metadata:Search{Tag = "AutoShooterTrap"}
    for _, metaEntity in ipairs(autoShooterTraps) do
        local index = metaEntity.Index
        local pos = REVEL.room:GetGridPosition(index)
        local dirs = newRoom.Metadata:GetDirections(index)
        if #dirs == 0 then
            error("No directions specified at index " .. index)
        end
        local rotation = dirs and ((dirs[1] - 90) % 360)
        local direction = REVEL.GetDirectionFromAngle(rotation)

        if direction == Direction.DOWN then pos = Vector(REVEL.room:GetBottomRightPos().X, pos.Y)
        elseif direction == Direction.LEFT then pos = Vector(pos.X, REVEL.room:GetBottomRightPos().Y)
        elseif direction == Direction.UP then pos = Vector(REVEL.room:GetTopLeftPos().X, pos.Y)
        elseif direction == Direction.RIGHT then pos = Vector(pos.X, REVEL.room:GetTopLeftPos().Y) end

        local eff
        if metaEntity.Name == "FlameTrapAlwaysActive" or metaEntity.Name == "FlameTrapTimed" or metaEntity.Name == "FlameTrapTimedOffset" then
            eff = Isaac.Spawn(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, 0, pos, Vector.Zero, nil)
        else
            eff = Isaac.Spawn(REVEL.ENT.BRIM_TRAP.id, REVEL.ENT.BRIM_TRAP.variant, 0, pos, Vector.Zero, nil)
        end

        local sprite, data = eff:GetSprite(), eff:GetData()
        sprite.Rotation = rotation
        eff.Position = pos + (Vector.FromAngle(rotation - 90) * 5)

        data.TrapRotation = rotation
        data.TrapDirection = direction

        if metaEntity.Name == "FlameTrapTimed" then
            data.FlameTrapType = "Timed"
        elseif metaEntity.Name == "FlameTrapTimedOffset" then
            data.FlameTrapType = "TimedOffset"
        elseif metaEntity.Name == "BrimstoneTrapTimed" or metaEntity.Name == "BrimstoneTrapTimedOffset" then
            local groups = newRoom.Metadata:GroupsWithIndex(index)

            if groups and #groups > 0 then
                data.MetaGroups = groups
                data.MaxGroup = maxGroup
                data.TrapType = "TimedGroup"
            elseif metaEntity.Name == "BrimstoneTrapTimedOffset" then
                data.TrapType = "TimedOffset"
            else
                data.TrapType = "Timed"
            end
        end

        if newRoom.Metadata:Has{Name = "DisableOnClear", Index = index} then
            data.DisableOnClear = true
            data.Disabled = REVEL.room:IsClear()
        end

        data.Init = true
    end

end)

function REVEL.TriggerTrap(tile, player, isPositiveEffect)
    local data = tile:GetData()

    REVEL.DebugStringMinor("Triggering trap:", REVEL.room:GetGridIndex(tile.Position), data.TrapName)

    if not REVEL.sfx:IsPlaying(REVEL.SFX.ACTIVATE_TRAP) then
        REVEL.sfx:Play(REVEL.SFX.ACTIVATE_TRAP, 1, 0, false, 1)
    end

    data.TrapTriggered = true
    data.TrapIsPositiveEffect = isPositiveEffect
    local trapTypeData = REVEL.TrapTypes[data.TrapName]
    if trapTypeData.Cooldown then
        data.TrapTriggerCooldown = trapTypeData.Cooldown
    end

    if trapTypeData.SingleUse then
        data.TrapTriggerCooldown = -1
    end

    if trapTypeData.OnTrigger then
        trapTypeData.OnTrigger(tile, data, player)
    end

    tile:GetSprite():SetFrame(data.Animation, 1)
end

function REVEL.IsTrapTriggerable(tile, data)
    data = data or tile:GetData()
    return not data.TrapTriggerCooldown or (data.TrapTriggerCooldown > -1 and data.TrapTriggerCooldown <= 0)
end

function REVEL.TriggerTrapsInRange(pos, dist, prank, requireUnpranked, wallTrapper)
    for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
        local tdata = trap:GetData()
        if tdata.TrapData and (not tdata.Pranked or not requireUnpranked) and REVEL.IsTrapTriggerable(trap, tdata) then
            if trap.Position:DistanceSquared(pos) < dist ^ 2 then
                tdata.TrapTriggerCooldown = 15
                REVEL.TriggerTrap(trap, REVEL.player)
                if prank then
                    tdata.Pranked = true
                end
                if wallTrapper then
                    return trap
                end
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data = eff:GetData()
    if data.TrapData then
        local sprite = eff:GetSprite()
        local trapTypeData = REVEL.TrapTypes[data.TrapName]
        local isTriggerable = REVEL.IsTrapTriggerable(eff, data)
        if isTriggerable and not data.TrapTriggered then
            if sprite:GetFrame() ~= 0 then
                sprite:SetFrame(data.Animation, 0)
            end
        else
            if sprite:GetFrame() ~= 1 then
                sprite:SetFrame(data.Animation, 1)
            end
        end

        if data.TrapTriggerCooldown and data.TrapTriggerCooldown > 0 then
            data.TrapTriggerCooldown = data.TrapTriggerCooldown - 1
        elseif isTriggerable then
            local triggered = false
            for _, player in ipairs(REVEL.players) do
                local size = 16 + player.Size
                if player.Position:DistanceSquared(eff.Position) < size * size then
                    triggered = true
                    break
                end
            end

            for _, npc in ipairs(REVEL.roomNPCs) do
                if npc:GetData().CanTriggerTraps then
                    local size = 16 + npc.Size
                    if npc.Position:DistanceSquared(eff.Position) < size * size then
                        triggered = true
                        break
                    end
                end
            end

            if triggered then
                if not data.TrapTriggered then
                    REVEL.TriggerTrap(eff, player, false)
                end
            elseif data.TrapTriggered then
                data.TrapIsPositiveEffect = nil
                data.TrapTriggered = nil
                eff:GetSprite():SetFrame(data.Animation, 0)
            end
        end

        if REVEL.room:IsClear() and data.TrapTriggerCooldown ~= -2 then
            local currentRoom = StageAPI.GetCurrentRoom()
            local grindex = REVEL.room:GetGridIndex(eff.Position)
            if currentRoom and currentRoom.Metadata:Has{Index = grindex, Name = "DisableOnClear"} then
                data.TrapTriggerCooldown = -2
                if trapTypeData.Disable then
                    trapTypeData.Disable(eff, data)
                end
            end
        end

        if trapTypeData.OnUpdate then
            trapTypeData.OnUpdate(eff, data)
        end

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.PersistentData and currentRoom.PersistentData.Traps and currentRoom.PersistentData.Traps[tostring(data.TrapData.Index)] then
            currentRoom.PersistentData.Traps[tostring(data.TrapData.Index)].Cooldown = data.TrapTriggerCooldown
        end
    end
end, StageAPI.E.FloorEffect.V)


end