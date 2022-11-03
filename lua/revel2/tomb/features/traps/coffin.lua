local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.CoffinEnemies = {
    {
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant}
    },
    {
        {REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant},
        {REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant},
        {REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant},
        {REVEL.ENT.LOCUST.id, REVEL.ENT.LOCUST.variant}
    },
    {
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant}
    },
    {
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant},
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant}
    }
}
    
REVEL.TrapTypes.CoffinTrap = {
    OnTrigger = function(tile, data, player)
        local validCoffins = {}
        local triggeredCoffins = {}
        local mustTriggerAll = {}
        local currentRoom = StageAPI.GetCurrentRoom()
        local index = data.TrapData.Index
        local requireGroup
        if currentRoom and currentRoom.Metadata:Has{Index = index, Name = "Groups"} then
            local groups = currentRoom.Metadata:GroupsWithIndex(index)
            if groups and #groups > 0 then
                requireGroup = groups[math.random(1, #groups)]
            end
        end

        local coffins = Isaac.FindByType(REVEL.ENT.CORNER_COFFIN.id, REVEL.ENT.CORNER_COFFIN.variant, -1, false, false)
        for _, coffin in ipairs(coffins) do
            local cdata = coffin:GetData()
            if (cdata.IsPathable or requireGroup) and (not cdata.SpawnEnemies or #cdata.SpawnEnemies == 0) then
                if requireGroup then
                    if REVEL.IndicesShareGroup(currentRoom, index, REVEL.room:GetGridIndex(coffin.Position), requireGroup) then
                        mustTriggerAll[#mustTriggerAll + 1] = coffin
                    end
                else
                    if cdata.CoffinBeenTriggered then
                        triggeredCoffins[#triggeredCoffins + 1] = coffin
                    else
                        validCoffins[#validCoffins + 1] = coffin
                    end
                end
            end
        end

        if #validCoffins == 0 and #triggeredCoffins > 0 then
            for _, coffin in ipairs(coffins) do
                coffin:GetData().CoffinBeenTriggered = nil
            end

            validCoffins = triggeredCoffins
        end

        if #mustTriggerAll > 0 then
            for _, coffin in ipairs(mustTriggerAll) do
                local cdata = coffin:GetData()
                cdata.Triggered = true
                cdata.AllFriendly = data.TrapIsPositiveEffect
                cdata.CoffinBeenTriggered = true
            end
        elseif #validCoffins > 0 then
            local coffin = validCoffins[math.random(1, #validCoffins)]
            local cdata = coffin:GetData()
            cdata.Triggered = true
            cdata.AllFriendly = data.TrapIsPositiveEffect
            cdata.CoffinBeenTriggered = true
        end
    end,
    IsValidRandomSpawn = function()
        local isCoffin
        for _, coffin in ipairs(Isaac.FindByType(REVEL.ENT.CORNER_COFFIN.id, REVEL.ENT.CORNER_COFFIN.variant, -1, false, false)) do
            local cdata = coffin:GetData()
            if cdata.IsPathable then
                isCoffin = true
            end
        end

        return isCoffin
    end,
    SingleUse = true,
    Animation = "Coffin"
}

local lastPlayerMapUpdateFrame

function REVEL.SpawnTombCornerDecorations(noCoffins, noBraziers)
    local cornerPositions, edgePositions = REVEL.GetCornerPositions()

    for i, corner in ipairs(cornerPositions) do
        local rotation = corner.Rotation
        local off = Vector.FromAngle(rotation - 90)
        local currentRoom = StageAPI.GetCurrentRoom()
        local grindex = REVEL.room:GetGridIndex(corner.Position)

        if not noBraziers and (not currentRoom or not currentRoom.Metadata:Has{Index = grindex, Name = "BrazierBlocker"}) then
            local brazier = Isaac.Spawn(REVEL.ENT.CORNER_BRAZIER.id, REVEL.ENT.CORNER_BRAZIER.variant, 0, corner.Position + off * 100, Vector.Zero, nil)
            brazier:GetSprite().Rotation = rotation + 45
            brazier:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_STATUS_EFFECTS, EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
            brazier.RenderZOffset = -10000
            -- if REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
                -- REVEL.SpawnLight(brazier.Position, Color(0.65, 0.32, 0, 1,conv255ToFloat( 0,0,0)), 3)
                -- REVEL.SpawnLight(brazier.Position, Color(0.35, 0.35, 0, 1,conv255ToFloat( 0,0,0)), 6)
            -- end
        end

        local grid = REVEL.room:GetGridEntity(grindex)
        if not noCoffins and (not grid or (REVEL.room:GetGridCollision(grindex) == 0 and grid.Desc.Type ~= GridEntityType.GRID_SPIKES)) then
            local nearFire
            for _, fire in ipairs(REVEL.roomFires) do
                if fire.Position:DistanceSquared(corner.Position) < 20 * 20 then
                    nearFire = true
                end
            end

            local frameCount = REVEL.game:GetFrameCount()

            if not nearFire and (not currentRoom or not currentRoom.Metadata:Has{Index = grindex, Name = "CoffinBlocker"}) then
                local doPlayerMapUpdate = lastPlayerMapUpdateFrame ~= frameCount
                lastPlayerMapUpdateFrame = frameCount
        

                local eff = Isaac.Spawn(REVEL.ENT.CORNER_COFFIN.id, REVEL.ENT.CORNER_COFFIN.variant, 0, corner.Position, Vector.Zero, nil)
                eff:GetData().CornerIndex = i
                eff:GetData().IsPathable = REVEL.AnyPlayerCanReachIndex(REVEL.room:GetGridIndex(corner.Position), doPlayerMapUpdate)
                eff:GetSprite().Rotation = rotation
                eff:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_STATUS_EFFECTS, EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
                eff.RenderZOffset = -1001
            end
        end
    end
end

-- Mainly for BR testing
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    lastPlayerMapUpdateFrame = nil
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        REVEL.roomBraziers = {}
        if REVEL.includes(REVEL.TombGfxRoomTypes, currentRoomType) or REVEL.TombGfxBrazierOnlyTypes[currentRoomType] ~= nil then
            REVEL.SpawnTombCornerDecorations(REVEL.TombGfxBrazierOnlyTypes[currentRoomType], false)
        end
    end
end)


local coffinSpawns = {}
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite, data = eff:GetSprite(), eff:GetData()
    local rotation = eff:GetSprite().Rotation
    for _, player in ipairs(REVEL.players) do
        local pos = player.Position + player.Velocity
        if REVEL.room:GetGridIndex(pos) == REVEL.room:GetGridIndex(eff.Position) then
            local diff = eff.Position - pos
            local x, y
            local yDiff, xDiff = eff.Position.Y - pos.Y, eff.Position.X - pos.X
            if rotation == -45 and pos.Y < eff.Position.Y + xDiff then
                x = pos.X - (eff.Position.X + yDiff)
                y = pos.Y - (eff.Position.Y + xDiff)
            elseif rotation == 45 and pos.Y < eff.Position.Y - xDiff then
                x = pos.X - (eff.Position.X - yDiff)
                y = pos.Y - (eff.Position.Y - xDiff)
            elseif rotation == 135 and pos.Y > eff.Position.Y + xDiff then
                x = pos.X - (eff.Position.X + yDiff)
                y = pos.Y - (eff.Position.Y + xDiff)
            elseif rotation == 225 and pos.Y > eff.Position.Y - xDiff then
                x = pos.X - (eff.Position.X - yDiff)
                y = pos.Y - (eff.Position.Y - xDiff)
            end

            if x and y then
                player.Velocity = Vector(
                    pos.X - (x * (math.abs(x / y)) / 2),
                    pos.Y - (y * (math.abs(y / x)) / 2)
                ) - player.Position
            end
        end
    end

    if data.Triggered then
        if (not data.SpawnEnemies or #data.SpawnEnemies == 0) then
            data.SpawnEnemies = {}
            local currentRoom = StageAPI.GetCurrentRoom()
            local shouldRandomize = true
            if currentRoom then
                local index = REVEL.room:GetGridIndex(eff.Position)
                if currentRoom.Metadata:Has{Index = index, Name = "CoffinPacker"} then
                    if currentRoom.Metadata.BlockedEntities[index] then
                        for _, enemy in ipairs(currentRoom.Metadata.BlockedEntities[index]) do
                            data.SpawnEnemies[#data.SpawnEnemies + 1] = {
                                enemy.Type,
                                enemy.Variant,
                                enemy.SubType,
                            }
                        end
                        shouldRandomize = nil
                    end
                end
            end

            if shouldRandomize then
                local enemies = REVEL.CoffinEnemies[math.random(1, #REVEL.CoffinEnemies)]
                for _, enemy in ipairs(enemies) do
                    data.SpawnEnemies[#data.SpawnEnemies + 1] = enemy
                end
            end
        end

        data.Triggered = nil
    end

    if data.SpawnEnemies and #data.SpawnEnemies > 0 then
        if sprite:IsFinished("Idle") then
            sprite:Play("OpenTell", true)
        elseif sprite:IsFinished("OpenTell") then
            sprite:Play("Open", true)
        elseif sprite:IsFinished("Open") or sprite:IsFinished("OpenIdle") then
            sprite:Play("OpenIdle", true)
        end
        if sprite:IsEventTriggered("spawn enemy") then
            if not data.SpawnEnemies[1][5] then
            local r = math.random(55,125)
            local ent = REVEL.SpawnEntCoffin(data.SpawnEnemies[1][1], data.SpawnEnemies[1][2], 0, eff.Position, Vector.FromAngle(sprite.Rotation + r) * 5, eff)

            if data.SpawnEnemies[1][3] then
                if data.SpawnEnemies[1][1] == REVEL.ENT.LOCUST.id and data.SpawnEnemies[1][2] == REVEL.ENT.LOCUST.variant
                and data.SpawnEnemies[1][3] > 1 then
                        for i=1, data.SpawnEnemies[1][3]-1 do
                            data.SpawnEnemies[#data.SpawnEnemies + 1] = {
                                REVEL.ENT.LOCUST.id,
                                REVEL.ENT.LOCUST.variant,
                                0}
                        end
                    end
                end
            end
            if data.SpawnEnemies[1][4] then
                ent:GetData().Buffed = true
            end

            if data.AllFriendly then
                ent:AddCharmed(EntityRef(REVEL.player), -1)
            end

            table.remove(data.SpawnEnemies, 1)
        end
    else
        data.AllFriendly = nil
        if sprite:IsFinished("Open") or sprite:IsFinished("OpenIdle") then
            sprite:Play("Close", true)
        elseif eff:GetSprite():IsFinished("Close") then
            sprite:Play("Idle", true)
        end
    end
    if sprite:IsEventTriggered("open") then REVEL.sfx:Play(REVEL.SFX.COFFIN_OPEN, 1, 0, false, 1) end
    if sprite:IsEventTriggered("close") then REVEL.sfx:Play(REVEL.SFX.COFFIN_CLOSE, 1, 0, false, 1) end
end, REVEL.ENT.CORNER_COFFIN.variant)

function REVEL.SpawnEntCoffin(t, v, s, pos, vel, spawner) --also used for Maxwell
    local ent = Isaac.Spawn(t, v, s, pos, vel, spawner)
    coffinSpawns[#coffinSpawns + 1] = ent
    ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    ent:GetData().BlackFade = true
    ent:GetSprite().Color = Color(0,0,0,1,conv255ToFloat(0,0,0))
    ent.SpawnerEntity = spawner

    return ent
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i, v in ripairs(coffinSpawns) do
        if not v:Exists() then
            table.remove(coffinSpawns, i)
        else
            local fade = math.min(1, 0+(v.FrameCount*0.12))
            v:GetSprite().Color = Color(fade,fade,fade,1,conv255ToFloat(0,0,0))
            if fade == 1 then
                table.remove(coffinSpawns, i)
            end
        end
    end
end)

REVEL.PerilCoffinSpawns = {
    {Type = REVEL.ENT.RAG_DRIFTY.id, Variant = REVEL.ENT.RAG_DRIFTY.variant},
    {Type = REVEL.ENT.LOCUST.id, Variant = REVEL.ENT.LOCUST.variant, Count = 4},
    {Type = REVEL.ENT.RAG_BONY.id, Variant = REVEL.ENT.RAG_BONY.variant, Buffed = true}
}

--[[
    Shrines don't give positive effects anymore
-- if in peril, spawn friendly enemies from an empty pathable coffin
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 2, function()
    if REVEL.IsShrineEffectActive(ShrineTypes.PERIL) and math.random() <= 0.18 then
        local validCoffins = REVEL.filter(REVEL.ENT.CORNER_COFFIN:getInRoom(), function(coffin)
            local cdata = coffin:GetData()
            return cdata.IsPathable and not (cdata.SpawnEnemies and #cdata.SpawnEnemies > 0)
        end)

        if #validCoffins > 0 then
            local coffin = validCoffins[math.random(1, #validCoffins)]
            local cdata = coffin:GetData()

            cdata.SpawnEnemies = {}

            local spawn = REVEL.PerilCoffinSpawns[math.random(1, #REVEL.PerilCoffinSpawns)]
            local count = spawn.Count or 1
            for i = 1, count do
                cdata.SpawnEnemies[i] = {spawn.Type, spawn.Variant, spawn.Buffed}
            end

            cdata.AllFriendly = true
        end
    end
end)
]]


end

REVEL.PcallWorkaroundBreakFunction()