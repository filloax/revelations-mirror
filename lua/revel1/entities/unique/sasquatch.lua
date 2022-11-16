local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local LineCheckMode     = require("lua.revelcommon.enums.LineCheckMode")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Sasquatch
local SasquatchAnims = {
    Up = "MoveUp", Horizontal = "MoveHori", Down = "MoveDown"
}
local SasquatchAnimsIce = {
    Up = "MoveUp2", Horizontal = "MoveHori2", Down = "MoveDown2"
}
local GrabAnims = {
    Up = "GrabUp", Horizontal = "GrabHori", Down = "GrabDown"
}
local ThrowAnims = {
    Up = "ThrowUp", Horizontal = "ThrowHori", Down = "ThrowDown"
}

local SnowballOffset = Vector(8, -4) * REVEL.SCREEN_TO_WORLD_RATIO
local BlockOffset = {}

local SnowballDelay = {Min = 75, Max = 90}
local MaxIceFlyDistance = 40 * 6
local IceThrowSpeed = 10

local CanPickUpEntities = {REVEL.ENT.FLURRY_ICE_BLOCK, REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW, REVEL.ENT.YELLOW_BLOCK_GAPER,
    REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER, REVEL.ENT.BLOCK_GAPER, REVEL.ENT.CARDINAL_BLOCK_GAPER}
--Ideally should use below method and not layer spritesheet replacement to be dynamic, but w/e we're not going to add more grabbables anyways
-- local EntityAnimData = { --no way to get anim names, hopefully repentance brings it
--   [REVEL.ENT.FLURRY_ICE_BLOCK] = {AnimName = "Empty"},
--   [REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW] = {AnimName = "Empty_Yellow"},
--   [REVEL.ENT.YELLOW_BLOCK_GAPER] = {AnimName = "Slide", UseAnm2 = "gfx/monsters/revel1/blockhead.anm2", Spritesheet = {[0] = "gfx/monsters/revel1/blockhead_gaper_yellow_2.png"}},
--   [REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER] = {AnimName = "Slide", UseAnm2 = "gfx/monsters/revel1/blockhead_cardinal.anm2", Spritesheet = {[0] = "gfx/monsters/revel1/blockhead_gaper_yellow.png"}},
--   [REVEL.ENT.BLOCK_GAPER] = {AnimName = "Slide", UseAnm2 = "gfx/monsters/revel1/blockhead.anm2"},
--   [REVEL.ENT.CARDINAL_BLOCK_GAPER] = {AnimName = "Slide", UseAnm2 = "gfx/monsters/revel1/blockhead_cardinal.anm2"},
-- }
-- local HoldingSpriteOffsets = { --offset for each frame of each animation where he holds things, leave nil to not render the sprite in that frame
--   GrabDown = {[0] = nil, nil, nil, nil, Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   GrabHori = {[0] = nil, nil, nil, nil, Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   GrabUp = {[0] = nil, nil, nil, nil, Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   MoveDown2 = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   MoveHori2 = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   MoveUp2 = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   ThrowDown = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   ThrowHori = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
--   ThrowUp = {[0] = Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40), Vector(0, -40)},
-- }
-- local HoldingSpriteAnims = REVEL.keys(HoldingSpriteOffsets)
local EntityBlockSprites = {
    [REVEL.ENT.FLURRY_ICE_BLOCK] = "sasquatch_blocks/sasquatch_iceblock.png",
    [REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW] = "sasquatch_blocks/sasquatch_pissblock.png",
    [REVEL.ENT.YELLOW_BLOCK_GAPER] =  "blockhead_gaper_yellow_2.png",
    [REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER] = "blockhead_gaper_yellow.png",
    [REVEL.ENT.BLOCK_GAPER] = "blockhead_gaper_2.png",
    [REVEL.ENT.CARDINAL_BLOCK_GAPER] = "blockhead_gaper.png",
}
local GridFrameSprites = {
    [0] = "sasquatch_blocks/sasquatch_icegrid.png",
    "sasquatch_blocks/sasquatch_icegrid2.png",
    "sasquatch_blocks/sasquatch_icegrid3.png",
    "sasquatch_blocks/sasquatch_icegrid4.png",
}
local GaperToHead = {
    [REVEL.ENT.YELLOW_BLOCK_GAPER] = REVEL.ENT.YELLOW_BLOCKHEAD,
    [REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER] = REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD,
    [REVEL.ENT.BLOCK_GAPER] = REVEL.ENT.BLOCKHEAD,
    [REVEL.ENT.CARDINAL_BLOCK_GAPER] = REVEL.ENT.CARDINAL_BLOCKHEAD,
}

local StepSpeed = 8
local Friction = 0.83

local SasquatchPathMap = REVEL.NewPathMapFromTable("Sasquatch", {
    GetTargetSets = function()
        local squatches = REVEL.ENT.SASQUATCH:getInRoom()

        return REVEL.GetMinimumTargetSets(squatches)
    end,
    GetInverseCollisions = function() --can pass through ice as it picks em up
        local hazardFree = {}
        local fireIndices = {}
        for _, fire in ipairs(REVEL.roomFires) do
            if fire.HitPoints > 1 then
                fireIndices[REVEL.room:GetGridIndex(fire.Position)] = true
            end
        end

        for i = 0, REVEL.room:GetGridSize() do
            local pos = REVEL.room:GetGridPosition(i)
            if REVEL.room:IsPositionInRoom(pos, 0) then
                local grid = REVEL.room:GetGridEntity(i)
                if grid and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT then
                    hazardFree[i] = true
                else
                    hazardFree[i] = REVEL.IsGridPassable(i, true, true, false, fireIndices, REVEL.room)
                end
            end
        end

        return hazardFree
    end,
    GetInverseCriticalCollisions = function() --can pass through ice as it picks em up
        return REVEL.Range(REVEL.room:GetGridSize())
    end,
    OnPathUpdate = function(map)
        local squatches = REVEL.ENT.SASQUATCH:getInRoom()
        for _, sasquatch in ipairs(squatches) do
            for _, set in ipairs(map.TargetMapSets) do
                if sasquatch:GetData().PathID == set.ID then
                    sasquatch:GetData().Path = REVEL.GetPathToZero(REVEL.room:GetGridIndex(sasquatch.Position), set.Map, nil, map)
                    sasquatch:GetData().PathIndex = nil
                end
            end
        end
        if Input.IsButtonPressed(Keyboard.KEY_0, 0) then
            REVEL.PrintPathMap(map)
        end
    end
})

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.SASQUATCH:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Init then
        data.State = "Move"
        data.SnowDelay = SnowballDelay.Min + math.random(SnowballDelay.Max - SnowballDelay.Min)
        REVEL.UsePathMap(SasquatchPathMap, npc)

        data.Init = true
    end

    npc.SplatColor = REVEL.WaterSplatColor

    local player = npc:GetPlayerTarget()

    if data.State == "Move" and player then
        npc.Velocity = npc.Velocity * Friction

        local tpos
        if REVEL.room:CheckLine(npc.Position, player.Position, 0, 0, false, false) then
            tpos = player.Position
        elseif data.Path then
            local prev
            for i = 1, #data.Path do
                tpos = REVEL.room:GetGridPosition(data.Path[i])
                if not REVEL.room:CheckLine(npc.Position, tpos, 0, 0, false, false) then
                tpos = prev
                break
                end
                prev = tpos
            end

            if data.HoldingSomething then --if holding ice and blocked by ice, throw the held one to be able to pick up the blocking one
                local iceBlockingPath

                for _, gridIndex in ipairs(data.Path) do
                    local grid = REVEL.room:GetGridEntity(gridIndex)
                    if grid and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT and not REVEL.IsGridBroken(grid) then
                        -- IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, grid.Position, nil, nil, nil, nil, Color(0, 0, 1, 0.9,conv255ToFloat( 0, 0, 0)))
                        iceBlockingPath = true
                        break
                    end
                end

                if iceBlockingPath then
                    data.State = "ThrowIce"
                    REVEL.AnimateWalkFrame(sprite, player.Position - npc.Position, ThrowAnims, true, false)
                    return
                end
            end
        end

        -- if data.Path then
        --   IDebug.RenderListOfGridsUntilNextUpdate(data.Path)
        --   if Input.IsButtonPressed(Keyboard.KEY_0, 0) then
        --     REVEL.DebugToString("\n" .. REVEL.GridListToString(data.Path, REVEL.room:GetGridIndex(npc.Position), REVEL.room:GetGridIndex(player.Position)))
        --   end
        -- end

        if tpos then
            --Turn around depending on player position, not self velocity
            if data.HoldingSomething then
                REVEL.AnimateWalkFrame(sprite, tpos - npc.Position, SasquatchAnimsIce, true, false)
            else
                REVEL.AnimateWalkFrame(sprite, tpos - npc.Position, SasquatchAnims, true, false)
            end

            if sprite:IsEventTriggered("Move") then
                npc.Velocity = npc.Velocity + (tpos - npc.Position):Resized(StepSpeed)
            end
        end

        if data.SnowDelay then
            data.SnowDelay = data.SnowDelay - 1
            if data.SnowDelay < 0 then
                data.SnowDelay = nil
            end
        end

        if not data.HoldingSomething and REVEL.STAGE.Glacier:IsStage() then
            local grabbingIce = false

            --Didn't find entity ice blocks, check grid ice blocks
            if not grabbingIce then
                local width = REVEL.room:GetGridWidth()
                local index = REVEL.room:GetGridIndex(npc.Position)

                local adjIndexes = {
                index - 1,
                index - width,
                index + 1,
                index + width,
                }

                if data.Path then
                    --Check which one of the adjacent indexes is in the path, and check that one first (to prioritize freeing up the path from ice blocks)
                    local matchingKey = REVEL.findKey(adjIndexes, function(i) return i == data.Path[1] or i == data.Path[2] end)
                    if matchingKey then --swap places with first in list
                        local tmp = adjIndexes[1]
                        adjIndexes[1] = adjIndexes[matchingKey]
                        adjIndexes[matchingKey] = tmp
                    end
                end

                for i, adjIndex in ipairs(adjIndexes) do
                    local npcGridPos = REVEL.room:GetGridPosition(index)
                    local gridPos = REVEL.room:GetGridPosition(adjIndex)
                    local closeEntities = Isaac.FindInRadius(npcGridPos + (gridPos - npcGridPos) * 2 / 3, 28, -1)
                    local found = false

                    for _, entity in pairs(closeEntities) do
                        for __, checkEntity in ipairs(CanPickUpEntities) do
                            if checkEntity:isEnt(entity) then
                                found = true
                                data.State = "Grab"
                                data.Grabbing = entity
                                data.GrabbedMatch = checkEntity
                                REVEL.AnimateWalkFrame(sprite, entity.Position - npc.Position, GrabAnims, true, false)
                                grabbingIce = true
                                break
                            end
                        end
                        if found then break end
                    end

                    local grid = REVEL.room:GetGridEntity(adjIndex)
                    if not found and grid and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT and not REVEL.IsGridBroken(grid) then
                        data.State = "Grab"
                        data.Grabbing = adjIndex
                        REVEL.AnimateWalkFrame(sprite, REVEL.room:GetGridPosition(adjIndex) - npc.Position, GrabAnims, true, false)
                        grabbingIce = true
                    end
                end
            end

            local currentRoom = StageAPI.GetCurrentRoom()

            -- If on snow and not with ice in hand
            if not grabbingIce 
            and not data.SnowDelay 
            ---@diagnostic disable-next-line: need-check-nil
            and not (currentRoom and currentRoom.PersistentData.IcePitFrames[tostring(REVEL.room:GetGridIndex(npc.Position))])
            and REVEL.room:CheckLine(npc.Position, player.Position, LineCheckMode.PROJECTILE, 0, false, false) then
                data.SnowDelay = SnowballDelay.Min + math.random(SnowballDelay.Max - SnowballDelay.Min)
                data.State = "Snowball"
                sprite:Play("Snowball", true)
            end
        elseif data.HoldingSomething and (player.Position:DistanceSquared(npc.Position) < MaxIceFlyDistance ^ 2 + 100 or (player.Position:DistanceSquared(npc.Position) < (10 * 40) ^ 2 and REVEL.room:CheckLine(npc.Position, player.Position, 0, 0, false, false))) then
            data.State = "ThrowIce"
            REVEL.AnimateWalkFrame(sprite, player.Position - npc.Position, ThrowAnims, true, false)
        end

    elseif data.State == "Snowball" then
        local target = player and (player.Position + player.Velocity * 0.9) or (npc.Position + RandomVector() * 120)

        npc.Velocity = Vector.Zero

        if sprite:IsEventTriggered("Throw") then --throw snowball
            REVEL.sfx:Play(REVEL.SFX.WHOOSH, 0.8, 0, false, 1)
            REVEL.ShootChillSnowball(npc, npc.Position + SnowballOffset, (target - npc.Position - SnowballOffset):Resized(16), REVEL.GlacierBalance.DarkIceChillDuration)
        end
        if sprite:IsFinished("Snowball") then
            data.State = "Move"
        end

    elseif data.State == "Grab" then
        npc.Velocity = Vector.Zero

        local grabbingExists
        if type(data.Grabbing) == "number" then
            local grid = REVEL.room:GetGridEntity(data.Grabbing)
            grabbingExists = grid and not REVEL.IsGridBroken(grid)
        else
            grabbingExists = data.Grabbing and data.Grabbing.Exists and data.Grabbing:Exists()
        end

        if not REVEL.MultiAnimOnCheck(sprite, GrabAnims) and data.Grabbing then
            if type(data.Grabbing) == "number" then
                REVEL.AnimateWalkFrame(sprite, REVEL.room:GetGridPosition(data.Grabbing) - npc.Position, GrabAnims, true, false)
            else
                REVEL.AnimateWalkFrame(sprite, data.Grabbing.Position - npc.Position, GrabAnims, true, false)
            end
        end

        if not grabbingExists and (not sprite:WasEventTriggered("Grab") or sprite:IsEventTriggered("Grab")) then
            data.State = "Move"
            data.Grabbing = nil
            data.GrabbedMatch = nil
        elseif sprite:IsEventTriggered("Grab") then
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.7, 0, false, 1)

            if type(data.Grabbing) == "number" then --grabbing grid, .Grabbing is grid index
                local grid = REVEL.room:GetGridEntity(data.Grabbing)
                if grid and REVEL.CanGridBeDestroyed(grid) then
                    local frame = grid:GetSprite():GetFrame()
                    REVEL.PreventGridBreakSound(data.Grabbing)
                    REVEL.PreventGridItemDrop(data.Grabbing)

                    REVEL.room:RemoveGridEntity(data.Grabbing, 0, true)
                    -- REVEL.room:Update()
                    data.HeldIceGridFrame = frame

                    -- data.GrabbingSprite = grid:GetSprite()
                    local sheet = GridFrameSprites[frame] or GridFrameSprites[0]
                    sprite:ReplaceSpritesheet(2, "gfx/monsters/revel1/" .. sheet)
                    sprite:LoadGraphics()
                end
            elseif data.Grabbing and data.Grabbing:Exists() then
                --[[
                    data.GrabbingSprite = Sprite()
                    local filepath = EntityAnimData[data.GrabbedMatch] and EntityAnimData[data.GrabbedMatch].UseAnm2 or data.Grabbing:GetSprite():GetFilename()
                    data.GrabbingSprite:Load(filepath, false)
                    local replaceSprite = EntityAnimData[data.GrabbedMatch] and EntityAnimData[data.GrabbedMatch].Spritesheet

                    if replaceSprite then
                        for layer, sheet in pairs(replaceSprite) do
                            data.GrabbingSprite:ReplaceSpritesheet(layer, sheet)
                        end
                    end

                    data.GrabbingSprite:LoadGraphics()

                    local anim = EntityAnimData[data.GrabbedMatch] and EntityAnimData[data.GrabbedMatch].AnimName or data.GrabbingSprite:GetDefaultAnimationName()
                    data.GrabbingSprite:Play(anim, true)
                ]]
                local sheet = EntityBlockSprites[data.GrabbedMatch]
                sprite:ReplaceSpritesheet(2, "gfx/monsters/revel1/" .. sheet)
                sprite:LoadGraphics()

                if REVEL.ENT.FLURRY_ICE_BLOCK:isEnt(data.Grabbing) or REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW:isEnt(data.Grabbing) then
                    local isPiss = data.GrabbedMatch.variant == REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW.variant
                    data.HoldingEntIceBlock = isPiss and "SlideEntityBlock_Piss" or "SlideEntityBlock" -- anim names
                    data.HoldingPissBlock = isPiss

                    data.Grabbing:Remove()
                else
                    data.HoldingEntity = data.GrabbedMatch

                    if GaperToHead[data.HoldingEntity] then
                        data.HoldingEntity = GaperToHead[data.HoldingEntity]
                        data.Grabbing.HitPoints = 0
                        data.Grabbing:GetData().BeheadNoSpawn = true

                        REVEL.BeheadIceBlockGaper(data.Grabbing:ToNPC())
                    else
                        data.Grabbing:Remove()
                    end
                end
            end

            data.HoldingSomething = true
            data.GrabbedMatch = nil
            data.Grabbing = nil
        end

        if REVEL.MultiFinishCheck(sprite, "GrabHori", "GrabUp", "GrabDown") then
            data.State = "Move"
        end

    elseif data.State == "ThrowIce" then
        if sprite:IsEventTriggered("Throw") then --throw ice
            local tpos
            -- if REVEL.room:CheckLine(npc.Position, player.Position, 0, 0, false, false) then
                tpos = player.Position
            -- elseif data.Path then
            --   tpos = REVEL.room:GetGridPosition(data.Path[1])
            -- end

            local dist = (tpos - npc.Position):Length()
            local throwDist = math.min(MaxIceFlyDistance, dist)
            local startHeight = 20
            local thrownEnt

            if data.HeldIceGridFrame or data.HoldingEntIceBlock then
                thrownEnt = REVEL.ENT.ICE_BLOCK:spawn(npc.Position, (tpos - npc.Position) * (IceThrowSpeed / dist), npc)
                thrownEnt:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

                if data.HeldIceGridFrame then
                    thrownEnt:GetSprite():Play("Slide" .. data.HeldIceGridFrame, true)
                    data.HeldIceGridFrame = nil
                elseif data.HoldingEntIceBlock then
                    thrownEnt:GetSprite():Play(data.HoldingEntIceBlock, true)
                    if data.HoldingPissBlock then
                        thrownEnt:GetData().IsPiss = true
                        data.HoldingPissBlock = nil
                    end
                    data.HoldingEntIceBlock = nil
                end
            elseif data.HoldingEntity then
                thrownEnt = data.HoldingEntity:spawn(npc.Position, (tpos - npc.Position) * (IceThrowSpeed / dist), npc)
                thrownEnt:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end

            if thrownEnt then
                thrownEnt.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                REVEL.AddEntityZPosition(thrownEnt, startHeight)

                REVEL.AddEntityZVelocity(thrownEnt, REVEL.GetNeededZSpeedForDistance(npc, throwDist, IceThrowSpeed))

                -- local nextDist = REVEL.GetDistanceBeforeZLanding(iceBlock)
                -- IDebug.RenderUntilNext("IceblockThrow", IDebug.RenderLine, iceBlock.Position, iceBlock.Position + iceBlock.Velocity:Resized(nextDist), false, Color(1, 0, 0, 0.2,conv255ToFloat( 0, 0, 0)))

                -- local pos = iceBlock.Position + iceBlock.Velocity:Rotated(90):Resized(5)

                -- IDebug.RenderUntilNext("IceblockThrow2", IDebug.RenderLine, pos, pos + iceBlock.Velocity:Resized(throwDist), false, Color(0, 1, 0, 0.2,conv255ToFloat( 0, 0, 0)))
            end

            data.HoldingSomething = nil

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_4, 0.8, 0, false, 0.8)
        end

        if REVEL.MultiFinishCheck(sprite, "ThrowHori", "ThrowUp", "ThrowDown") then
            data.State = "Move"
        end
    end
end, REVEL.ENT.SASQUATCH.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    if not REVEL.ENT.SASQUATCH:isEnt(npc) or not REVEL.IsRenderPassNormal() then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Dying and npc:HasMortalDamage() then
        npc.HitPoints = 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        sprite:Play("Death", true)
        npc:RemoveStatusEffects()
        data.Dying = true
        npc.State = NpcState.STATE_UNIQUE_DEATH
    end

    if IsAnimOn(sprite, "Death") then
        if data.HoldingSomething then
            local heldEnt

            if data.HeldIceGridFrame or data.HoldingEntIceBlock then
                heldEnt = REVEL.ENT.ICE_BLOCK:spawn(npc.Position, Vector.Zero, npc)
                heldEnt:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

                if data.HeldIceGridFrame then
                    heldEnt:GetSprite():Play("Slide" .. data.HeldIceGridFrame, true)
                    data.HeldIceGridFrame = nil
                elseif data.HoldingEntIceBlock then
                    heldEnt:GetSprite():Play(data.HoldingEntIceBlock, true)
                    if data.HoldingPissBlock then
                        heldEnt:GetData().IsPiss = true
                        data.HoldingPissBlock = nil
                    end
                    data.HoldingEntIceBlock = nil
                end
            elseif data.HoldingEntity then
                heldEnt = data.HoldingEntity:spawn(npc.Position, Vector.Zero, npc)
                heldEnt:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end

            if heldEnt then
                heldEnt:GetData().SpawnedOnSasquatchDeath = true
                REVEL.AddEntityZPosition(heldEnt, -40)
                REVEL.AddEntityZVelocity(heldEnt, 3)
            end

            data.HoldingSomething = nil
        end

        npc.Velocity = Vector.Zero
        if sprite:IsEventTriggered("Scream") and not data.TriggeredScream then
            data.TriggeredScream = true
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_YELL_A, 0.8, 0, false, 0.6)
        end
        if sprite:IsEventTriggered("Slam") and not data.TriggeredSlam then
            data.TriggeredSlam = true
            REVEL.game:ShakeScreen(25)
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)

            local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, true, false)
            for _, hazard in ipairs(iceHazards) do
                hazard.Velocity = hazard.Velocity + (hazard.Position - npc.Position):Resized(7)
            end

            local stalactrites = REVEL.ENT.STALACTRITE:getInRoom()
            for _, stalactrite in pairs(stalactrites) do
                StageAPI.RemovePersistentEntity(stalactrite)
                stalactrite:GetData().State = "JumpDown"
            end

            REVEL.SpawnBlurShockwave(npc.Position)
        end
    end

    if sprite:IsFinished("Death") and not data.Gibbed then
        npc:BloodExplode()
        data.Gibbed = true
    end

    --[[
        if data.HoldingSomething and data.GrabbingSprite then
            local anim = sprite:GetAnimation()
            local frame = sprite:GetFrame()
            if anim and HoldingSpriteOffsets[anim][frame] then
                data.GrabbingSprite:Render(Isaac.WorldToScreen(npc.Position) + HoldingSpriteOffsets[anim][frame], Vector.Zero, Vector.Zero)
            end
        elseif data.GrabbingSprite then
            data.GrabbingSprite = nil
        end
    ]]
end, REVEL.ENT.SASQUATCH.id)

local function IceBlockDie(npc)
    local sprite, data = npc:GetSprite(), npc:GetData()

    REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
    sprite:Play("Break", true)

    if REVEL.GetEntityZPosition(npc) < 5 then
        if data.IsPiss then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
            REVEL.UpdateCreepSize(creep, creep.Size * 0.7, true)
            creep:GetData().YellowIceblockCreep = true
        else
            REVEL.SpawnIceCreep(npc.Position, npc)
        end
        for i=1, 6 do
            REVEL.SpawnIceRockGib(npc.Position, RandomVector():Resized(math.random(1, 5)), npc, data.IsPiss and REVEL.IceGibType.YELLOW)
        end
        local numProjs = 4
        local startAngle = 45
        for angle = startAngle, startAngle + 360 - 360 / numProjs, 360 / numProjs do
            local proj = Isaac.Spawn(9, data.IsPiss and 0 or ProjectileVariant.PROJECTILE_TEAR, 0, npc.Position, Vector.FromAngle(angle) * 10, npc)
            if data.IsPiss then
                proj:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/frosty_projectiles_yellow.png")
                proj:GetSprite():LoadGraphics()
                proj.SplatColor = REVEL.YellowSplatColor
                proj:GetData().isFrostyProjectile = true
                proj:GetData().IsPiss = true
            end
        end
    end
    npc:Die()
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.ICE_BLOCK:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Init then
        data.Velocity = npc.Velocity
        data.Init = true
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
    end

    if data.IsPiss then
        npc.SplatColor = REVEL.YellowSplatColor
    else
        npc.SplatColor = REVEL.WaterSplatColor
    end

    if REVEL.GetEntityZPosition(npc) == 0 then
        if npc.FrameCount % 3 == 0 then
            if data.IsPiss then
                local creep = REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
                REVEL.UpdateCreepSize(creep, creep.Size * 0.35, true)
                creep:GetData().YellowIceblockCreep = true
            else
                REVEL.SpawnIceCreep(npc.Position, npc)
            end
        end
        local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position))
        if data.SpawnedOnSasquatchDeath or (grid and grid.CollisionClass > GridCollisionClass.COLLISION_NONE) then
            IceBlockDie(npc)
            return
        end
    end

    if npc.Velocity.X * data.Velocity.X < 0 or npc.Velocity.Y * data.Velocity.Y < 0 or (REVEL.GetEntityZPosition(npc) == 0 and data.DieOnLand) then
        IceBlockDie(npc)
        return
    end

    npc.Velocity = data.Velocity
end, REVEL.ENT.ICE_BLOCK.id)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(player, dmg, flag, src, invuln)
    if src and src.Entity and src.Entity.Type == REVEL.ENT.ICE_BLOCK.id and src.Entity.Variant == REVEL.ENT.ICE_BLOCK.id then
        local srcEnt = REVEL.GetEntFromRef(src)
        IceBlockDie(srcEnt:ToNPC())
    end
end, 1)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_AIR_MOVEMENT_LAND, 0, function(entity, airMovementData, fromGrid)
    if entity.Type == REVEL.ENT.BLOCKHEAD.id and
            (entity.Variant == REVEL.ENT.BLOCKHEAD.variant or entity.Variant == REVEL.ENT.CARDINAL_BLOCKHEAD.variant
            or entity.Variant == REVEL.ENT.YELLOW_BLOCKHEAD.variant or entity.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant)
            and entity:GetData().SpawnedOnSasquatchDeath then
        REVEL.BeheadIceBlockGaper(entity)
    end
end)

end