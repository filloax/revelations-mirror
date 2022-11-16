local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Big Blowy
local SnowParticleOffset = {[0] = Vector(-10, -5), Vector(0, 0), Vector(8, -5), Vector(0, -6)}

function REVEL.IsBigBlowyTrack(index, onlyBusy)
    local pos = REVEL.room:GetGridPosition(index)

    local blowies = REVEL.ENT.BIG_BLOWY:getInRoom(false, true, false)

    for _, blowy in pairs(blowies) do
        local data = blowy:GetData()

        if data.TrackTopLeft and REVEL.IsPositionInRect(pos, data.TrackTopLeft, data.TrackBottomRight) then
            local isTrack = not onlyBusy
                            or REVEL.some(REVEL.players, function(player)
                                return REVEL.IsPositionInRect(player.Position, data.TrackTopLeft, data.TrackBottomRight)
                            end)
            if isTrack then return true end
        end
    end

    return false
end

local function spawnWindRenderer(blowy, data, trackTopLeft, trackBottomRight)
    local lowerMostY = math.max(blowy.Position.Y, trackBottomRight.Y, trackTopLeft.Y)

    local deco = REVEL.ENT.DECORATION:spawn(Vector(blowy.Position.X, lowerMostY), Vector.Zero)
    deco.Color = REVEL.NO_COLOR
    deco:GetData().WindRenderer = true
    deco:GetData().BlowyData = data

    return deco
end

local windAnimSpeed = 1.3
local windBaseAlpha = 0.45
--One way of having em in sync (also easier to use with rendertiled)
local WindStartSprite = REVEL.LazyLoadRoomSprite{
    ID = "bb_WindStartSprite",
    Anm2 = "gfx/effects/revel1/icewind_laser.anm2",
    Animation = "Start",
    PlaybackSpeed = windAnimSpeed,
}
local WindLineSprite = REVEL.LazyLoadRoomSprite{
    ID = "bb_WindLineSprite",
    Anm2 = "gfx/effects/revel1/icewind_laser.anm2",
    Animation = "Line",
    PlaybackSpeed = windAnimSpeed,
}
local WindEndSprite = REVEL.LazyLoadRoomSprite{
    ID = "bb_WindEndSprite",
    Anm2 = "gfx/effects/revel1/icewind_laser.anm2",
    Animation = "End",
    PlaybackSpeed = windAnimSpeed,
}

local lastWindSpriteUpdate = -1

-- local windOffsets = {[0] = Vector(-4, -2), Vector(0, 0), Vector(4, -3), Vector(2, -10)}
local windOffsets = {[0] = Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0)}
local windTileFadeDuration = 5 --fade time when extending trail

-- Temporary, until resource loading is fixed 
-- and grimace variants aren't invisible
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.BIG_BLOWY:isEnt(npc) then return end

    local data, sprite = npc:GetData(), npc:GetSprite()
    sprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
end, REVEL.ENT.BIG_BLOWY.id)

--Get track area
local function updateTracks(blowy, room)
    room = room or StageAPI.GetCurrentRoom()

    local data = blowy:GetData()
    local trackTopLeft, trackBottomRight, isIce, isPit

    if not data.Wind then data.Wind = {} end

    local currentFrame

    for i, wind in ripairs(data.Wind) do
        local breaks, isPit = REVEL.Glacier.GridBreaksTotalFreeze(REVEL.room:GetGridIndex(wind.Position), true)

        isIce = not breaks

        if not (isIce or isPit) then
            wind:Remove()
            table.remove(data.Wind, i)
        elseif i ~= #data.Wind and wind:GetSprite():IsPlaying("End") then
            wind:GetSprite():Play("Line", true)
            if currentFrame then
                REVEL.SkipAnimFrames(wind:GetSprite(), currentFrame)
            end
        end

        currentFrame = wind:GetSprite():GetFrame()
    end

    local i = 1
    local lastIndex, lastPos

    repeat
        local pos = blowy.Position + data.DirVector * (i * 40)
        local index = REVEL.room:GetGridIndex(pos)
        i = i + 1

        local breaks, isPit = REVEL.Glacier.GridBreaksTotalFreeze(index, true)

        isIce = not breaks

        -- REVEL.DebugToConsole(index, isIce, isPit, " ")

        --Works because they're in a line, woudln't work with rectangles
        if not trackTopLeft or index < trackTopLeft then
            trackTopLeft = index
        end
        if not trackBottomRight or index > trackBottomRight then
            trackBottomRight = index
        end

        lastIndex = index
        lastPos = pos
    until not (isIce or isPit)

    if not data.CurrentWindIndex or data.CurrentWindIndex == lastIndex then
        data.WindEndPos = lastPos
        data.CurrentWindIndex = lastIndex
        data.TargetWindIndex = nil
        data.WindTargetLonger = nil
    else
        local increases = data.Direction == Direction.DOWN or data.Direction == Direction.RIGHT
        data.WindTargetLonger = increases and lastIndex > data.CurrentWindIndex or not increases and lastIndex < data.CurrentWindIndex
        data.TargetWindIndex = lastIndex
    end

    data.WindBlocked = i < 3

    if not trackTopLeft or not trackBottomRight then
        -- REVEL.DebugLog("Ice pit tracks not found for " .. REVEL.ENT.BIG_BLOWY.name .. " at " .. REVEL.room:GetGridIndex(blowy.Position))
    else
        data.TrackTopLeft = REVEL.room:GetGridPosition(trackTopLeft) + Vector(-20, -20)
        data.TrackBottomRight = REVEL.room:GetGridPosition(trackBottomRight) + Vector(20, 20)

        if not data.WindBlocked and not data.WindRenderer then
            data.WindStartPos = blowy.Position + data.DirVector * 80
            data.WindRenderer = spawnWindRenderer(blowy, data, data.TrackTopLeft, data.TrackBottomRight)
        end
    end
end

local lastRoom = -1

local function loadBlowyDirections(room)
    if lastRoom ~= StageAPI.GetCurrentListIndex() then
        local blowies = REVEL.ENT.BIG_BLOWY:getInRoom(false, false, false)

        for _, blowy in ipairs(blowies) do
            local data = blowy:GetData()
            local dirs = room.Metadata:GetDirections(REVEL.room:GetGridIndex(blowy.Position))
            local dirAngle = dirs and dirs[1]
            if dirAngle then
                data.Direction = REVEL.GetDirectionFromAngle(dirAngle)
                blowy.SubType = data.Direction
            else
                data.Direction = blowy.SubType
            end

            data.DirVector = REVEL.dirToVel[data.Direction]

            updateTracks(blowy, room)
        end
    end

    lastRoom = StageAPI.GetCurrentListIndex()
end

local function bigblowyUpdate(_, npc)
    if not REVEL.ENT.BIG_BLOWY:isEnt(npc) then return end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.AttemptedLoad then
        loadBlowyDirections(StageAPI.GetCurrentRoom())
        data.AttemptedLoad = true
    end

    -- Currently grimaces seem to have 60 fps updates
    if data.LastUpdateFrame == REVEL.game:GetFrameCount() then
        return
    end
    data.LastUpdateFrame = REVEL.game:GetFrameCount()

    if npc.State ~= NpcState.STATE_INIT and not data.Init then
        if not data.Direction then
            data.Direction = npc.SubType
            data.DirVector = REVEL.dirToVel[data.Direction]
        end

        npc.State = NpcState.STATE_ATTACK2
        sprite:Play("StartShoot" .. REVEL.dirToString[data.Direction], true)

        data.Init = true
    end

    if npc.State ~= NpcState.STATE_INIT and npc.State ~= NpcState.STATE_SPECIAL and npc.FrameCount % 10 == 0 then
        updateTracks(npc)
    end

    if lastWindSpriteUpdate < REVEL.game:GetFrameCount() and (not data.WindAlpha or data.WindAlpha > 0) then
        WindLineSprite:Update()
        WindStartSprite:Update()
        WindEndSprite:Update()
        lastWindSpriteUpdate = REVEL.game:GetFrameCount()
    end

    -- if data.Wind and npc.State == NpcState.STATE_SPECIAL then
    --     for i, wind in ipairs(data.Wind) do
    --         wind:Remove()
    --     end

    --     data.Wind = nil
    -- end

    if npc.State == NpcState.STATE_ATTACK then
        npc.State = NpcState.STATE_ATTACK2
        sprite:Play("StartShoot" .. REVEL.dirToString[data.Direction], true)

    elseif npc.State == NpcState.STATE_ATTACK2 then
        if sprite:IsFinished("StartShoot" .. REVEL.dirToString[data.Direction]) then
            sprite:Play("Shoot" .. REVEL.dirToString[data.Direction], true)
            data.DoWind = true
            REVEL.EnableWindSound(npc, true)
        end

        if sprite:IsPlaying("Shoot".. REVEL.dirToString[data.Direction]) then
            if npc.FrameCount % 5 == 0 then
                local dir = data.DirVector--:Rotated(-5 + math.random(10))
                local pos = npc.Position + dir * 3 + data.DirVector:Rotated(90) * (math.random(-5, 5))
                local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, pos, dir * 5, npc)
                snowp:GetSprite():Play("Fade", true)
                snowp:GetSprite().Offset = SnowParticleOffset[data.Direction]
                snowp:GetData().Rot = math.random()*20-10
                snowp.Color = Color(1, 1, 1, 1.5,conv255ToFloat( 0, 0, 0))
            end

            if data.TrackTopLeft then
                for _, player in ipairs(REVEL.filter(REVEL.players, function(player)
                    return REVEL.IsPositionInRect(player.Position, data.TrackTopLeft, data.TrackBottomRight)
                end)) do
                    local pdata = player:GetData()

                    -- if players is in the 2 grids in front
                    local playerGrid     = REVEL.room:GetGridIndex(player.Position)
                    local nextPlayerGrid = REVEL.room:GetGridIndex(player.Position + data.DirVector * 40)
                    local nextGrid       = REVEL.room:GetGridIndex(npc.Position + data.DirVector * 40)

                    local playerGridFrozen     = not REVEL.Glacier.GridBreaksTotalFreeze(playerGrid, true, player)
                    local nextPlayerGridFrozen = not REVEL.Glacier.GridBreaksTotalFreeze(nextPlayerGrid, true, player)

                    -- REVEL.DebugToConsole(playerGridFrozen, nextPlayerGridFrozen)

                    if playerGridFrozen then
                        if not nextPlayerGridFrozen then
                            -- push the player back if he would be immediately defrozen
                            local parallelVelocity, perpendicularVelocity = REVEL.GetVectorComponents(player.Velocity, data.DirVector)
                            player.Velocity = data.DirVector * 3 + perpendicularVelocity
                        elseif not REVEL.Glacier.CanBeTotalFrozen(player) then
                            local opposite = (player.Position - REVEL.room:GetGridPosition(nextPlayerGrid)):Normalized()
                            local parallelVelocity, perpendicularVelocity = REVEL.GetVectorComponents(opposite, data.DirVector)
                            player.Velocity = perpendicularVelocity * player.Velocity:Length() * 3
                        elseif not pdata.TotalFrozen then
                            REVEL.Glacier.TotalFreezePlayer(player, data.Direction, 8, playerGrid)
                        elseif playerGrid == nextGrid then
                            -- if already frozen, i.e. chained blowies
                            -- wait for the player to be at/past the center for the grid so he doesn't get pushed in a non-aligned way,
                            -- and also so it doesn't look weird if he instasnapped

                            pdata.NoBreakThisFrame = true

                            if REVEL.IsMidGridInDirection(nextGrid, player.Position, player.Velocity,
                                                            data.Direction == Direction.LEFT or data.Direction == Direction.RIGHT) then
                                REVEL.Glacier.TotalFreezePlayer(player, data.Direction, 8, nextGrid)
                            end
                        end
                    end
                end

                for _, pickup in ipairs(REVEL.filter(REVEL.roomPickups, function(pickup)
                    return REVEL.IsPositionInRect(pickup.Position, data.TrackTopLeft, data.TrackBottomRight)
                end)) do
                    pickup.Velocity = pickup.Velocity * 0.95 + data.DirVector * 0.5
                end
            end
        end
    end

    if data.DoWind then
        if not data.WindAlpha then
            data.WindAlpha = 0
            data.WindAppearCount = 0
            data.WindAlphaEnd = 1
        elseif data.WindAppearCount < 20 then
            data.WindAppearCount = data.WindAppearCount + 1
            data.WindAlpha = data.WindAppearCount * windBaseAlpha / 20
        end

        if data.TargetWindIndex then
            local changeDir = data.WindTargetLonger and 1 or -1
            if not data.WindEndFadeCount then
                data.WindEndPos = REVEL.room:GetGridPosition(data.CurrentWindIndex) + data.DirVector * (40 * changeDir)
                data.CurrentWindIndex = REVEL.room:GetGridIndex(data.WindEndPos)
                data.WindAlphaEnd = 0
                data.WindEndFadeCount = data.WindTargetLonger and 0 or windTileFadeDuration
            else
                data.WindEndFadeCount = data.WindEndFadeCount + changeDir
                data.WindAlphaEnd = data.WindEndFadeCount / windTileFadeDuration
                if (data.WindTargetLonger and data.WindEndFadeCount >= windTileFadeDuration) or (not data.WindTargetLonger and data.WindEndFadeCount <= 0) then
                    data.WindEndFadeCount = nil
                    data.WindAlphaEnd = 1
                    if data.CurrentWindIndex == data.TargetWindIndex then
                        data.TargetWindIndex = nil
                    end
                end
            end
        end
    end
    if npc.State == NpcState.STATE_SPECIAL then
        if not data.WindFadeCount then
            data.WindFadeCount = 40
        elseif data.WindFadeCount > 0 then
            data.WindFadeCount = data.WindFadeCount - 1

            if data.WindFadeCount == 0 then
                REVEL.DisableWindSound(npc)
            end

            data.WindAlpha = data.WindFadeCount * windBaseAlpha / 40
        end
    end
end

-- Euthanasia fix
local function bigblowyEuthanasiaPreTearCollision(_, tear, ent)
    if not REVEL.ENT.BIG_BLOWY:isEnt(ent) then return end

    if tear.Variant == TearVariant.NEEDLE then
        return false
    end
end

local function bigblowyPostEntityRemove(_, ent)
    if not REVEL.ENT.BIG_BLOWY:isEnt(ent) then return end

    local sprite, data = ent:GetSprite(), ent:GetData()

    if data.WindRenderer then
        REVEL.FadeEntity(data.WindRenderer, 15)
    end
end

local function bigblowyRender(_, npc)
    if not REVEL.ENT.BIG_BLOWY:isEnt(npc) and REVEL.IsRenderPassNormal() then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if data.DoWind 
    and (not data.WindAlpha or data.WindAlpha > 0)
    and not data.WindBlocked
    and REVEL.IsRenderPassNormal() then
        local windStartPos = npc.Position + data.DirVector * 40
        WindStartSprite.Rotation = REVEL.dirToAngle[data.Direction]
        WindStartSprite.Color = Color(1, 1, 1, data.WindAlpha or 1)
        WindStartSprite:Render(Isaac.WorldToScreen(windStartPos) + windOffsets[data.Direction], Vector.Zero, Vector.Zero)

        if data.Direction == Direction.UP then
            sprite:Render(Isaac.WorldToScreen(npc.Position))
        end
    end
end

local function bigblowyWindRender(_, eff)
    local data = eff:GetData()

    if data.WindRenderer and data.BlowyData.DoWind 
    and (not data.BlowyData.WindAlpha or data.BlowyData.WindAlpha > 0)
    and not data.BlowyData.WindBlocked
    and REVEL.IsRenderPassNormal() then
        local startPos = Isaac.WorldToScreen(data.BlowyData.WindStartPos) + windOffsets[data.BlowyData.Direction]
        local endPos = Isaac.WorldToScreen(data.BlowyData.WindEndPos) + windOffsets[data.BlowyData.Direction]
        WindLineSprite.Color = Color(1, 1, 1, data.BlowyData.WindAlpha or 1)
        REVEL.DrawRotatedTilingSprite(WindLineSprite, startPos, endPos, 26)
        -- REVEL.DrawRotatedTilingCapSprites(windEndSprite, startPos, endPos, 0, true) --it's flipped
        -- IDebug.RenderCircle(REVEL.room:GetGridPosition(data.BlowyData.CurrentWindIndex))
        -- if data.BlowyData.TargetWindIndex then
        --   IDebug.RenderCircle(REVEL.room:GetGridPosition(data.BlowyData.TargetWindIndex), nil, nil, nil, nil, Color(0, 1, 0, 1,conv255ToFloat( 0, 0, 0)))
        -- end
        WindEndSprite.Color = Color(1, 1, 1, (data.BlowyData.WindAlpha or 1) * (data.BlowyData.WindAlphaEnd or 1))
        WindEndSprite.Rotation = REVEL.dirToAngle[data.BlowyData.Direction]
        WindEndSprite:Render(endPos)
        -- IDebug.RenderCircle(endPos, true)
    end
end

local function bigblowyWindPostNewRoom()
    lastWindSpriteUpdate = -1
end

local DefaultVolume = 1
local WindEntities = {}
local windEntNum = 0

local fadeProgress = 0
local FadeTime = 30

function REVEL.EnableWindSound(entity, strong, vol)
    if not WindEntities[entity.InitSeed] then
        WindEntities[entity.InitSeed] = {Entity = entity, Strong = strong, Volume = vol}
        windEntNum = windEntNum + 1
    end
    WindEntities[entity.InitSeed].Strong = strong
    WindEntities[entity.InitSeed].Volume = vol or WindEntities[entity.InitSeed].Volume
end

function REVEL.DisableWindSound(entity)
    if WindEntities[entity.InitSeed] then
        WindEntities[entity.InitSeed] = nil
        windEntNum = windEntNum - 1
    end
end

local function bigblowyWindSoundUpdate()
    local doPlay, strong, setVolume = false, false, false
    local targetVolume = DefaultVolume

    if windEntNum > 0 then
        local toRemove = {}
        for seed, info in pairs(WindEntities) do
            if info.Entity:Exists() and not info.Entity:IsDead() then
                doPlay = true
                strong = strong or info.Strong
                if info.Volume and (not setVolume or info.Volume > targetVolume) then
                    targetVolume = info.Volume
                    setVolume = true
                end
            else
                toRemove[#toRemove + 1] = seed
            end
        end

        for _, toRemoveSeed in pairs(toRemove) do
            WindEntities[toRemoveSeed] = nil
            windEntNum = windEntNum - 1
        end
    end

    local actualVolume = targetVolume

    if doPlay and fadeProgress < FadeTime then
        fadeProgress = fadeProgress + 1
        actualVolume = REVEL.Lerp2Clamp(0, targetVolume, fadeProgress, 0, FadeTime)
    elseif not doPlay and fadeProgress > 0 then
        fadeProgress = fadeProgress - 1
        actualVolume = REVEL.Lerp2Clamp(0, targetVolume, fadeProgress, 0, FadeTime)
    end

    if REVEL.sfx:IsPlaying(REVEL.SFX.WIND_LOOP) then
        if strong or not doPlay then
            REVEL.sfx:Stop(REVEL.SFX.WIND_LOOP)
        else
            REVEL.sfx:AdjustVolume(REVEL.SFX.WIND_LOOP, actualVolume)
        end
    end
    if REVEL.sfx:IsPlaying(REVEL.SFX.WINDSTRONG_LOOP) then
        if not strong or not doPlay then
            REVEL.sfx:Stop(REVEL.SFX.WINDSTRONG_LOOP)
        else
            REVEL.sfx:AdjustVolume(REVEL.SFX.WINDSTRONG_LOOP, actualVolume)
        end
    end
    if doPlay and not strong and not REVEL.sfx:IsPlaying(REVEL.SFX.WIND_LOOP) then
        REVEL.sfx:Play(REVEL.SFX.WIND_LOOP, actualVolume, 0, true, 1)
    end
    if doPlay and strong and not REVEL.sfx:IsPlaying(REVEL.SFX.WINDSTRONG_LOOP) then
        REVEL.sfx:Play(REVEL.SFX.WINDSTRONG_LOOP, actualVolume, 0, true, 1)
    end
end

local function bigblowyWindSoundPostNewRoom()
    WindEntities = {}
    windEntNum = 0
    fadeProgress = 0
    REVEL.sfx:Stop(REVEL.SFX.WIND_LOOP)
    REVEL.sfx:Stop(REVEL.SFX.WINDSTRONG_LOOP)
end

-- StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, loadBlowyDirections)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, bigblowyUpdate, REVEL.ENT.BIG_BLOWY.id)
REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, bigblowyEuthanasiaPreTearCollision)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, bigblowyPostEntityRemove, REVEL.ENT.BIG_BLOWY.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, bigblowyRender, REVEL.ENT.BIG_BLOWY.id)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, bigblowyWindRender, REVEL.ENT.DECORATION.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, bigblowyWindPostNewRoom)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, bigblowyWindSoundUpdate)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, bigblowyWindSoundPostNewRoom)

end