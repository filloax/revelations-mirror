local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local chuckBalance = {
    BaseFriction = 0.9,
    HighFriction = 0.75, -- used when throwing ice block or stunned
    HighestFriction = 0.5, -- after ground pound
    DashFriction = 0.92,
    DashAcceleration = 0.9,
    JumpSpeed = 6,

    IceSpawnDashSpeed = 8,
    IceSpawnRange = 100,

    DefaultAttackCooldown = 20,
    PunchAttackCooldown = 50,
    QuickHitAttackCooldown = 10,

    RunningToBlockSpeed = 8,
    PushingBlockSpeed = 9,
    HazardShotSpeed = 10,
    EnemySmackMulti = 5,
    BlockPunchSpeed = 18,
    PunchForwardPower = 8,
    PushRangeMin = 90, -- has to be within this range to push the block
    AdjustRangeMin = 50, -- if outside this range, will re-adjust position to block
    BlockPunchRange = 140,
    CreepInterval = 6,

    TurnFrameLength = 20, -- The amount of frames in the short turn animation

    MaxAttackLoops = 3,
    HPToNextPhase = 0.5,

    FinalDashSpeed = 14,
    BlockOffset = 50, -- offset for final death dash

    ImpactSpeedMulti = 1.5, -- when chuck hits something, it is flung off at his velocity * this number
    ImpactRecoil = 0.3, -- when chuck hits something, he is sent in the other direction at his velocity * this number
    ExtraImpactDistance = 16, -- chuck will hit objects within a distance of chuck size + object size + this number
    EnemyImpactDamage = 10,
    GroundPoundSpawns = {
        Min = 1,
        Max = 1
    },
    IceBlockFlightTime = 20,
    StunTime = {
        Min = 30,
        Max = 30
    },
    DefaultIceHazardDamage = 0.04,

    BloodScale = {
        Min = 75,
        Max = 125
    },
    BloodFrequency = 10,
    BloodColor = Color(0, 0, 0, 1,conv255ToFloat( 20, 51, 78)),
    IceBlockCanCrush = {
        [GridEntityType.GRID_POOP] = true,
        [GridEntityType.GRID_ROCK_ALT] = true,
        [GridEntityType.GRID_ROCK] = true,
        [GridEntityType.GRID_ROCK_BOMB] = true,
        [GridEntityType.GRID_ROCKT] = true,
        [GridEntityType.GRID_ROCK_SS] = true
    },

    DamageResistPct = 0.25,
    DamageResistPct2 = 0.5,

    GigachuckPct = 0.03,
    GigachuckSize = 1.15,

    Sounds = {
        Spawn = {Sound = REVEL.SFX.CHUCK.BONK},
        Laugh = {Sound = REVEL.SFX.CHUCK.LAUGH, Volume = 1.35},
        Throw = {Sound = REVEL.SFX.CHUCK.LIFT},
        Punch = {Sound = SoundEffect.SOUND_SHELLGAME},
        -- HitDash = {},
        Hurt = {Sound = SoundEffect.SOUND_FETUS_JUMP, Pitch = 1.2},
        Bonk = {Sound = REVEL.SFX.CHUCK.BONK, Volume = 1},
        -- Ow = {Sound = REVEL.SFX.CHUCK.OW, Volume = 0.9},
        Jump = {Sound = REVEL.SFX.CHUCK.JUMP},
        MeatSpawn = {Sound = SoundEffect.SOUND_BOIL_HATCH, Volume = 0.6},
        -- Birds = {Sound = REVEL.SFX.BIRD_STUN, Loop = true, Volume = 0.6},
        Dead = {Sound = REVEL.SFX.CHUCK.DEAD, Volume = 1.3},
        AngryStart = {Sound = REVEL.SFX.CHUCK.ANGRY, Volume = 1.3},
        -- AngryDash = {Sound = REVEL.SFX.CHUCK.ANGRY2, Volume = 1.3},
        Bump = {Sound = REVEL.SFX.ICE_BUMP, Volume = 1.4},
        Shatter = {Sound = SoundEffect.SOUND_MIRROR_BREAK, Volume = 0.8},
    },
}

REVEL.Elites = {
    Chuck = {
        Music = REVEL.SFX.ELITE1,
        ClearMusic = REVEL.SFX.GLACIER_BOSS_OUTRO
    }
}

function REVEL.IsEliteRoom(name)
    local currentRoom = StageAPI.GetCurrentRoom()
    return currentRoom and currentRoom.PersistentData.BossID == name
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, 5, function(stage, musicID, roomType, rng)
    for elite, data in pairs(REVEL.Elites) do
        if REVEL.IsEliteRoom(elite) then
            if not REVEL.room:IsClear() then
                return data.Music
            elseif not REVEL.RoomWasClear and REVEL.room:IsClear() then
                return data.ClearMusic
            end

            break
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_CLEAR, 1, function()
    REVEL.sfx:Stop(REVEL.SFX.BIRD_STUN)
end)

local function pickSpawnIndicesNearPos(position, groups, count)
    local currentRoom = StageAPI.GetCurrentRoom()
    local spawnIndices = {}
    for _, group in ipairs(groups) do
        local indices = currentRoom.Metadata:IndicesInGroup(group)
        for _, index in ipairs(indices) do
            if currentRoom.Metadata:Has{Index = index, Name = "Spawner"} then
                if not spawnIndices[index] then
                    spawnIndices[index] = true
                end
            end
        end
    end

    local weightTable = {}
    local highestDist = 0
    for index, _ in pairs(spawnIndices) do
        local dist = position:Distance(REVEL.room:GetGridPosition(index)) ^ 3
        weightTable[#weightTable + 1] = {Index = index, Weight = dist}
        if not highestDist or dist > highestDist then
            highestDist = dist
        end
    end

    highestDist = highestDist + 1

    local weightTotal = 0
    for _, indexData in ipairs(weightTable) do
        indexData.Weight = highestDist - indexData.Weight
        weightTotal = weightTotal + indexData.Weight
    end

    local outIndices = {}
    for i = 1, count do
        local useIndex, listIndex = StageAPI.WeightedRNG(weightTable, nil, "Weight", weightTotal)
        weightTotal = weightTotal - useIndex.Weight
        outIndices[#outIndices + 1] = useIndex.Index
        table.remove(weightTable, listIndex)
    end

    return outIndices
end

function REVEL.AddSpikesToIceHazard(entity, dontLock)
    if not dontLock then
        entity:GetData().LockedInPlace = true
        entity.Mass = 2000
    end

    local sprite = entity:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/bosses/revel1/chuck/ice_hazard_overlay_chuck_bottom.png")
    sprite:ReplaceSpritesheet(2, "gfx/bosses/revel1/chuck/ice_hazard_overlay_chuck_top.png")
    sprite:LoadGraphics()
    entity.CollisionDamage = 1
end

local function spawnChuckEntity(index)
    local isStalactite
    if index > 10000 then
        isStalactite = true
        index = index - 10000
    end

    local pos = REVEL.room:GetGridPosition(index)
    local inRadius = #Isaac.FindInRadius(pos, 20, EntityPartition.ENEMY) + #Isaac.FindInRadius(pos, 20, EntityPartition.PLAYER)
    if inRadius == 0 then
        local currentRoom = StageAPI.GetCurrentRoom()
        local entities = currentRoom.Metadata.BlockedEntities[index]
        if entities and #entities > 0 then
            local ent = entities[math.random(1, #entities)]
            local entity
            if isStalactite then
                entity = Isaac.Spawn(REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1, pos, Vector.Zero, nil)
            else
                entity = Isaac.Spawn(ent.Type, ent.Variant or 0, ent.SubType or 0, pos, Vector.Zero, nil)
            end

            if entity.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
                REVEL.SetEntityAirMovement(entity, {
                    ZPosition = 500, 
                    ZVelocity = -5,
                    Gravity = 0.25,
                    Bounce = 0,
                })
                REVEL.UpdateEntityAirMovement(entity)
                REVEL.AddSpikesToIceHazard(entity)
            end
            entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

            local stalTarget = REVEL.SpawnDecorationFromTable(entity.Position, Vector.Zero, REVEL.StalactiteTargetDeco2)
            stalTarget:GetData().noRequireStalactite = true
            stalTarget:SetTimeout(25)
        end
    end
end

local function manageUpcomingGrids(npc, target, destroyAll, shredNearGrids)
    local upcomingGrids = {npc.Position + npc.Velocity:Resized(20),npc.Position + npc.Velocity:Resized(40),npc.Position + npc.Velocity:Resized(60)}
    if shredNearGrids then
        for _, gridpos in StageAPI.ReverseIterate(upcomingGrids) do
            upcomingGrids[#upcomingGrids + 1] = gridpos + Vector(0, -40)
            upcomingGrids[#upcomingGrids + 1] = gridpos + Vector(0, 40)
        end
    end

    local isUpcomingGrid
    for _, gridpos in ipairs(upcomingGrids) do
        local grid = REVEL.room:GetGridIndex(gridpos)
        local gridEnt = REVEL.room:GetGridEntity(grid)
        if gridEnt then
            if gridEnt.CollisionClass == GridCollisionClass.COLLISION_PIT then
                isUpcomingGrid = true
                if destroyAll and gridEnt.Desc.Type == GridEntityType.GRID_PIT then
                    REVEL.room:TryMakeBridge(gridEnt, gridEnt)
                end
            elseif gridEnt.Desc.Type == GridEntityType.GRID_ROCK_ALT and gridEnt.CollisionClass == GridCollisionClass.COLLISION_SOLID then
                REVEL.room:DestroyGrid(grid, false)
                npc:FireBossProjectiles(8, target.Position, 5, ProjectileParams())
            elseif destroyAll and gridEnt.CollisionClass == GridCollisionClass.COLLISION_SOLID then
                REVEL.room:DestroyGrid(grid, false)
            end
        end
    end

    return isUpcomingGrid
end

local function adjustToBlock(npc, block, targetPos)
    local angle = (block.Position-targetPos):GetAngleDegrees()

    local adjustDist = 60
    local dir, adjustPos
    angle = angle+180
    if angle >= 45 and angle < 135 then
        dir = "Down"
        --adjustPos = Vector(block.Position.X,block.Position.Y-adjustDist)
    elseif angle >= 135 and angle < 225 then
        dir = "Left"
        --adjustPos = Vector(block.Position.X+adjustDist,block.Position.Y)
    elseif angle >= 225 and angle < 315 then
        dir = "Up"
        --adjustPos = Vector(block.Position.X,block.Position.Y+adjustDist)
    elseif angle >= 315 or angle < 45 then
        dir = "Right"
        --adjustPos = Vector(block.Position.X-adjustDist,block.Position.Y)
    end
    adjustPos = block.Position - Vector.FromAngle(angle)*adjustDist

    return adjustPos, dir
end

local function gridCrush(npc, data)
    for i = 0, REVEL.room:GetGridSize() do
        local grid = REVEL.room:GetGridEntity(i)
        if grid and data.bal.IceBlockCanCrush[grid.Desc.Type] and REVEL.CanGridBeDestroyed(grid) then
            local pos = grid.Position
            if pos:DistanceSquared(npc.Position) < (20 + npc.Size + 16) ^ 2 then
                REVEL.room:DestroyGrid(i, false)
            end
        end
    end
end

local function chuckDeathDeco(npc, pos, anim, gigachuck, bal)
    local faceDir = -1
    if npc.FlipX then faceDir = 1 end
    local deco = REVEL.SpawnDecoration(pos, Vector(4,0)*-faceDir, anim, "gfx/bosses/revel1/chuck/chuck.anm2", nil, nil, nil, nil, function(eff)
        eff.Velocity = eff.Velocity * 0.9
        if eff:GetSprite():IsEventTriggered("Land") then
            REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
        end
    end, nil, false)

    if gigachuck then
        deco:GetSprite():ReplaceSpritesheet(0, "gfx/bosses/revel1/chuck/gigachuck.png")
        deco:GetSprite():LoadGraphics()
        REVEL.ScaleEntity(deco, {SpriteScale = Vector.One * bal.GigachuckSize})
    end

    deco:GetSprite().FlipX = npc:GetSprite().FlipX
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_AIR_MOVEMENT_LAND, 2, function(entity, airMovementData, fromPit)
    REVEL.SpawnDustParticles(entity.Position, 6, entity, Color(1, 1, 1, 1,conv255ToFloat( 97, 140, 181)))
    REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 1, 0, false, 1)

    for i = 1, 4 do
        REVEL.SpawnIceRockGib(entity.Position, RandomVector() * math.random(1, 5), entity, entity:GetData().DarkIce and REVEL.IceGibType.DARK)
    end
end, REVEL.ENT.ICE_HAZARD_GAPER.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.CHUCK.variant then
        return
    end

    local sprite, data, target, path = npc:GetSprite(), npc:GetData(), npc:GetPlayerTarget(), npc.Pathfinder
    local iceblocks, stalactites, icehazards = Isaac.FindByType(REVEL.ENT.CHUCK_ICE_BLOCK.id, REVEL.ENT.CHUCK_ICE_BLOCK.variant, -1, false, false), Isaac.FindByType(REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1, false, false), Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)
    local block = iceblocks[1]

    if not data.Init then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite:Play("Appear", true)

        data.bal = REVEL.GetBossBalance(chuckBalance, "Default")
        data.State = "Appear"
        data.IdleState = 0
        data.AttackLoopCount = 0
        npc.Velocity = npc.Velocity * data.bal.HighestFriction
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS

        if math.random() < data.bal.GigachuckPct then
            data.Gigachuck = true
            sprite:ReplaceSpritesheet(0, "gfx/bosses/revel1/chuck/gigachuck.png")
            sprite:LoadGraphics()
            REVEL.ScaleEntity(npc, {SpriteScale = Vector.One * data.bal.GigachuckSize})
        end

        data.SpawnIndices = {}
        data.SpawnDelay = math.random(4, 7)

        data.StartPosition = npc.Position

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            local spawnGroups = {}

            local spawners = currentRoom.Metadata:Search{Name = "Spawner"}
            for _, metaEntity in ipairs(spawners) do
                local index = metaEntity.Index
                local groups = currentRoom.Metadata:GroupsWithIndex(index)

                for __, group in ipairs(groups) do
                    spawnGroups[#spawnGroups + 1] = group
                end

                for i = 1, math.random(2, 3) do
                    --SpawnIceRockGib makes em jump in the air, but these should be in the ground from the start
                    local pos = REVEL.room:GetGridPosition(index) + RandomVector() * math.random(5, 15)
                    local spritesheet = "gfx/grid/revel1/glacier_rocks.png"                                
                    local gib = REVEL.SpawnDecoration(pos, Vector.Zero, "rubble_alt", "gfx/grid/grid_rock.anm2", nil, nil, nil, nil, nil, math.random(1, 3), false)
                    gib:GetSprite():ReplaceSpritesheet(0, spritesheet)
                    gib:GetSprite():LoadGraphics()
                end
            end

            data.SpawnGroups = spawnGroups
        end

        REVEL.SetScaledBossHP(npc)

        data.Init = true
    end

    if data.SpawnIndices and #data.SpawnIndices > 0 then
        if data.SpawnDelay <= 0 then
            local index = data.SpawnIndices[#data.SpawnIndices]
            spawnChuckEntity(index)
            data.SpawnIndices[#data.SpawnIndices] = nil
            data.SpawnDelay = math.random(4, 7)
        else
            data.SpawnDelay = data.SpawnDelay - 1
        end
    end

    if sprite:IsPlaying("Appear") and sprite:IsEventTriggered("Land") then
        REVEL.PlaySound(npc, data.bal.Sounds.Spawn)
    end

    if sprite:IsEventTriggered("Throw") then
        REVEL.PlaySound(npc, data.bal.Sounds.Throw)
    end

    if sprite:IsEventTriggered("Jump") then
        REVEL.PlaySound(npc, data.bal.Sounds.Jump)
    end

    -- APPEAR
    if data.State == "Appear" then
        if sprite:GetFrame() == 1 then
            REVEL.PlaySound(npc,SoundEffect.SOUND_REVERSE_EXPLOSION,0.5,2,false,1.1)
        end

        if sprite:IsEventTriggered("Blood") then
            REVEL.PlaySound(npc, data.bal.Sounds.MeatSpawn)
            REVEL.PlaySound(npc, data.bal.Sounds.Throw)
        end

        if sprite:IsFinished("Appear") then
            data.State = "SpawnIceBlock"
        end

        npc.Velocity = Vector.Zero

    -- SPAWN ICE BLOCK
    elseif data.State == "SpawnIceBlock" then

        if not data.Substate then
            if npc.Position:Distance(data.StartPosition) > data.bal.IceSpawnRange then
                if not sprite:IsPlaying("Dash Start") and not sprite:IsPlaying("Dash") then
                    sprite:Play("Dash Start")
                end
                if sprite:IsFinished("Dash Start") then
                    sprite:Play("Dash")
                end

                if REVEL.room:CheckLine(npc.Position,data.StartPosition,3,0,false,false) then
                    npc.Velocity = REVEL.Lerp(npc.Velocity,(data.StartPosition-npc.Position):Normalized() * data.bal.IceSpawnDashSpeed,0.1)
                else
                    path:FindGridPath(data.StartPosition, data.bal.IceSpawnDashSpeed*0.15, 900, true)
                end
                npc.FlipX = npc.Velocity.X > 0
            else
                data.Substate = "Start"
            end

        elseif data.Substate == "Start" then
            if not sprite:IsPlaying("SpawnIceBlock") then
                sprite:Play("SpawnIceBlock")
            end

            if sprite:IsEventTriggered("Land") then
                REVEL.game:ShakeScreen(10)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)

                if data.SpawnGroups and #data.SpawnGroups > 0 then
                    local currentRoom = StageAPI.GetCurrentRoom()
                    local indices = currentRoom.Metadata:IndicesInGroup(data.SpawnGroups[math.random(1, #data.SpawnGroups)])
                    local spawnIndices = {}
                    for _, index in ipairs(indices) do
                        if currentRoom.Metadata:Has{Index = index, Name = "Spawner"} then
                            spawnIndices[#spawnIndices + 1] = index
                        end
                    end

                    for _, index in ipairs(REVEL.Shuffle(spawnIndices)) do
                        data.SpawnIndices[#data.SpawnIndices + 1] = index
                    end
                end
            end

            if sprite:WasEventTriggered("Land") then
                npc.Velocity = npc.Velocity * data.bal.HighestFriction
            else
                npc.Velocity = npc.Velocity * data.bal.BaseFriction
            end

            if sprite:IsEventTriggered("Hit") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 1, 0, false, 1)
            end

            if sprite:IsEventTriggered("Throw") then
                local faceDir = -1
                if npc.FlipX then faceDir = 1 end
                local block = Isaac.Spawn(REVEL.ENT.CHUCK_ICE_BLOCK.id,REVEL.ENT.CHUCK_ICE_BLOCK.variant,0,npc.Position,Vector(5*faceDir,0),npc)
                block:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                block.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                block:GetData().State = "Toss"
                block:GetData().FaceDir = faceDir
            end

            if sprite:IsFinished("SpawnIceBlock") then
                data.Substate = nil
                data.State = "Idle"
            end
        end

    -- IDLE
    elseif data.State == "Idle" then
        if not sprite:IsPlaying("Idle") and not sprite:IsPlaying("UnStun") then
            sprite:Play("Idle", true)
        end

        npc.Velocity = npc.Velocity * data.bal.HighestFriction

        data.IdleWait = data.IdleWait or data.bal.DefaultAttackCooldown
        if data.IdleWait <= 0 then
            if data.IdleState == 0 then
                if block then
                    if block:GetData().State == "Idle" then
                        data.IdleWait = nil
                        data.IdleState = 1
                        data.AttackLoopCount = data.AttackLoopCount + 1
                        data.State = "BlockChain"
                    end
                end
            elseif data.IdleState == 1 then
                if not block then
                    data.IdleWait = nil
                    data.IdleState = 0
                    data.State = "SpawnIceBlock"
                end
            elseif data.IdleState == 2 then
                data.IdleWait = nil
                data.State = "Dashing"
                sprite:Play("Dash Start", true)
            end
        else
            data.IdleWait = data.IdleWait - 1
        end

    -- BLOCK CHAIN (Pushes block into ice hazards)
    elseif data.State == "BlockChain" then
        if not block then
            data.Substate = "End"
        end

        data.HazardOrder = data.HazardOrder or {}
        data.HazardTarget = data.HazardTarget or nil
        if not data.Substate then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            data.TempHazards = data.TempHazards or icehazards

            --print(#data.TempHazards .. " hazards left")
            local smallest, smallestPos = nil, nil
            for i, hazard in ipairs(data.TempHazards) do
                if hazard:GetData().LockedInPlace then
                    if not smallest or smallest.Ref.SubType >= hazard.SubType then
                        smallest = EntityPtr(hazard)
                        smallestPos = i
                        --print("-> " .. smallest.Ref.SubType)
                    else
                        --print(hazard.SubType .. " > " .. smallest.Ref.SubType)
                    end
                else
                    --print("X")
                    table.remove(data.TempHazards,i)
                    smallestPos = nil
                    break
                end
            end

            if smallestPos then
                --print("added to table:" .. smallest.Ref.SubType)
                table.remove(data.TempHazards,smallestPos)
                table.insert(data.HazardOrder,smallest)
            end

            if #data.TempHazards <= 0 then
                data.TempHazards = nil
                sprite:Play("Dash Start")
                data.Substate = "Push"
            end
        elseif data.Substate == "Push" then
            if not sprite:IsPlaying("Dash Start") and not sprite:IsPlaying("Dash") then
                sprite:Play("Dash Start")
            end
            if sprite:IsFinished("Dash Start") then
                sprite:Play("Dash")
            end

            if #data.HazardOrder <= 0 and not data.PunchPos then
                data.PunchPos = target.Position
                data.HazardTarget = target

            elseif not data.HazardTarget and #data.HazardOrder > 0 then
                if data.HazardOrder[1].Ref then
                    data.HazardTarget = data.HazardOrder[1].Ref
                else
                    table.remove(data.HazardOrder,1)
                end
                
            elseif data.HazardTarget and data.HazardSmash and #data.HazardOrder > 0 then
                table.remove(data.HazardOrder,1)
                data.HazardTarget = nil
                data.HazardSmash = nil
            else
                --Too far from block
                local adjustPos = adjustToBlock(npc,block,data.HazardTarget.Position)
                if npc.Position:Distance(block.Position) > data.bal.PushRangeMin and block:GetData().HazardTarget then
                    block:GetData().HazardTarget = nil

                    npc.Velocity = (block.Position-npc.Position):Normalized() * data.bal.RunningToBlockSpeed
                    npc.FlipX = npc.Position.X < block.Position.X
                elseif npc.Position:Distance(block.Position) > data.bal.PushRangeMin*0.66 and not block:GetData().HazardTarget then

                    npc.Velocity = (block.Position-npc.Position):Normalized() * data.bal.RunningToBlockSpeed
                    npc.FlipX = npc.Position.X < block.Position.X
                --Adjust to correct position
                elseif npc.Position:Distance(adjustPos) > data.bal.AdjustRangeMin then
                    block:GetData().HazardTarget = nil
                    data.Substate = "Adjust"
                elseif not data.PunchPos then
                --Push
                    block:GetData().HazardTarget = data.HazardTarget
                    npc.Velocity = block.Velocity
                    npc.FlipX = npc.Position.X < block.Position.X
                    --npc.Position = Vector(block.Position.X+70,block.Position.Y)
                else
                    data.Substate = "Punch"
                end
            end
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        elseif data.Substate == "Adjust" then
            if not data.HazardTarget and #data.HazardOrder > 0 then
                data.HazardTarget = data.HazardOrder[1].Ref
            else
                local adjustPos, adjustDir = adjustToBlock(npc,block,data.HazardTarget.Position)

                if npc.Position:Distance(adjustPos) <= data.bal.AdjustRangeMin*0.4 and sprite:IsFinished("TurnShort") then
                    if not data.PunchPos then
                        sprite:Play("Dash")
                        data.Substate = "Push"
                    else
                        data.PunchPos = target.Position
                        data.Substate = "Punch"
                    end
                else
                    if not sprite:IsPlaying("TurnShort") then
                        sprite:Play("TurnShort")
                    end

                    if sprite:IsEventTriggered("Turn") then
                        npc.FlipX = npc.Position.X < data.HazardTarget.Position.X
                    end
            
                    npc.Velocity = Vector.Zero
                    npc.Position = REVEL.Lerp2(npc.Position, adjustPos, sprite:GetFrame()/data.bal.TurnFrameLength)
                end

                --if too close to wall, push back
                if npc:CollidesWithGrid() then
                    block.Position = block.Position+(REVEL.room:GetCenterPos()-block.Position):Normalized()*5
                    block:GetData().LockPosition = block.Position
                end
            end

            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        elseif data.Substate == "Punch" then
            npc.FlipX = npc.Position.X < block.Position.X

            if not sprite:IsPlaying("HitIceBlock") then
                if data.AttackLoopCount >= data.bal.MaxAttackLoops or npc.HitPoints < npc.MaxHitPoints*data.bal.HPToNextPhase then
                    data.Substate = "EndToFlex"
                else
                    sprite:Play("HitIceBlock")
                end
            end

            if sprite:IsEventTriggered("Hit") then
                if npc.Position:Distance(block.Position) < data.bal.BlockPunchRange then
                    npc.Velocity = (block.Position-npc.Position):Normalized() * data.bal.PunchForwardPower
                    REVEL.game:ShakeScreen(4)
                    REVEL.PlaySound(npc, data.bal.Sounds.Bump)
                    block:GetData().PunchVec = (data.PunchPos-block.Position):Normalized()
                end
            end

            if sprite:IsFinished("HitIceBlock") then
                if not block:GetData().PunchVec then
                    sprite:Play("Dash Start")
                    data.PunchPos = nil
                    data.Substate = "Push"
                else
                    data.Substate = "End"
                end
            end

            npc.Velocity = npc.Velocity * data.bal.HighFriction
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        elseif data.Substate == "End" or data.Substate == "EndToFlex" then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.HazardOrder = nil
            data.HazardTarget = nil
            data.PunchPos = nil

            data.IdleWait = data.bal.PunchAttackCooldown

            if data.Substate == "EndToFlex" then
                sprite:Play("Throw", true)
                data.Phase2 = true
                data.State = "Throw"
            else
                data.State = "Idle"
            end
            data.Substate = nil
        end

    -- THROW
    elseif data.State == "Throw" then
        local iceSpr = block:GetSprite()
        if sprite:IsEventTriggered("Throw") and sprite:IsPlaying("Throw") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
            block:GetData().State = "Thrown"
        end

        if sprite:IsFinished("Throw") or sprite:IsFinished("Idle2") then
            sprite:Play("Idle2", true)
        end

        if sprite:IsEventTriggered("Throw") and sprite:IsPlaying("Catch") then
            block:GetData().State = "ThrownHigh"
            REVEL.PlaySound(npc, data.bal.Sounds.Throw)
        end

        if iceSpr:IsFinished("Thrown") and not sprite:IsPlaying("Catch") then
            sprite:Play("Catch", true)
        end

        if sprite:IsFinished("Catch") or sprite:IsFinished("Idle3") then
            data.ThrownIceBlock = true
            sprite:Play("Idle3", true)
        end

        if data.ThrownIceBlock and (iceSpr:IsFinished("Land") or iceSpr:IsEventTriggered("Land") or iceSpr:IsPlaying("Idle") or iceSpr:IsFinished("Idle")) then
            sprite:Play("Flex", true)
            data.ThrownIceBlock = nil

            if data.SpawnGroups and #data.SpawnGroups > 0 then
                local currentRoom = StageAPI.GetCurrentRoom()
                local indices = currentRoom.Metadata:IndicesInGroup(data.SpawnGroups[math.random(1, #data.SpawnGroups)])
                local spawnIndices = {}
                for _, index in ipairs(indices) do
                    if currentRoom.Metadata:Has{Index = index, Name = "Spawner"} and math.random(0,1) == 1 then
                        spawnIndices[#spawnIndices + 1] = index
                    end
                end

                for _, index in ipairs(REVEL.Shuffle(spawnIndices)) do
                    data.SpawnIndices[#data.SpawnIndices + 1] = index
                end
            end
        end

        if sprite:IsEventTriggered("Flex") then
            REVEL.PlaySound(npc, data.bal.Sounds.Laugh)
        end
        if sprite:IsEventTriggered("Bonk") then
            REVEL.PlaySound(npc, data.bal.Sounds.Bonk)
            REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.5, 0, false, 1)
        end

        -- if sprite:IsPlaying("Flex") and not sprite:WasEventTriggered("Spawn") then
        --     data.ResistDamage = true
        -- end

        if sprite:IsEventTriggered("Spawn") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            REVEL.PlaySound(npc, data.bal.Sounds.Ow)
            REVEL.PlaySound(data.bal.Sounds.Birds)

            for i=1, 6 do
                REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(1, 5), npc)
            end

            local trite = Isaac.Spawn(EntityType.ENTITY_HOPPER, 1, 0, npc.Position, RandomVector() * 12, npc)
            trite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            REVEL.ForceReplacement(trite, "Glacier")
            trite:GetSprite():Play("Idle", true)
        end

        if sprite:IsFinished("Flex") then
            data.State = "Stunned"
            data.StunEndTime = npc.FrameCount + math.random(data.bal.StunTime.Min, data.bal.StunTime.Max)
            sprite:Play("Stun", true)
        end

        npc.Velocity = npc.Velocity * data.bal.HighFriction
    
    -- STUNNED
    elseif data.State == "Stunned" then
        if not sprite:IsPlaying("Stun") then
            sprite:Play("Stun", true)
        end

        if npc.FrameCount > data.StunEndTime then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.StunEndTime = nil
            sprite:Play("UnStun", true)
            if data.bal.Sounds.Birds then
                REVEL.sfx:Stop(data.bal.Sounds.Birds.Sound)
            end
            data.IdleState = 2
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * data.bal.HighFriction

    -- DASHING
    elseif data.State == "Dashing" then
        if sprite:IsFinished("Dash Start") or sprite:IsFinished("Dash") or sprite:IsFinished("Turn") or sprite:IsFinished("JumpEnd") then
            sprite:Play("Dash", true)
        end

        if sprite:IsFinished("JumpStart") or sprite:IsFinished("JumpLoop") then
            sprite:Play("JumpLoop", true)
        elseif sprite:IsFinished("JumpEnd") then
            sprite:Play("Dash", true)
        end

        local isJumping = sprite:IsPlaying("JumpStart") or sprite:IsPlaying("JumpLoop") or sprite:IsPlaying("JumpEnd")

        local targetPos = REVEL.room:GetClampedPosition(target.Position, npc.Size)

        if sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Dash") then
            npc.Velocity = (targetPos - npc.Position):Resized(data.bal.JumpSpeed)
        elseif sprite:IsPlaying("Dash") or sprite:WasEventTriggered("Dash") or sprite:IsPlaying("Turn") or isJumping then
            if sprite:IsFinished("Dash Start") then
                sprite:Play("Dash", true)
            end

            if sprite:IsPlaying("Turn") and not sprite:WasEventTriggered("Turn") then
                npc.Velocity = npc.Velocity + (targetPos - npc.Position):Resized(data.bal.DashAcceleration)
            else
                npc.Velocity = npc.Velocity * data.bal.DashFriction + (targetPos - npc.Position):Resized(data.bal.DashAcceleration)
            end

            local isUpcomingGrid = manageUpcomingGrids(npc, target, false, true)

            if isUpcomingGrid then
                if not isJumping then
                    local jumpVel = Vector(npc.Velocity.X, 0)
                    local len = jumpVel:Length()
                    if len > 6 then
                        data.JumpVel = jumpVel
                    else
                        data.JumpVel = jumpVel:Resized(6)
                    end

                    isJumping = true
                    sprite:Play("JumpStart", true)
                    if math.random() < 0.5 then
                        REVEL.PlaySound(npc, data.bal.Sounds.Jump)
                    end
                end
            elseif sprite:IsPlaying("JumpLoop") then
                sprite:Play("JumpEnd", true)
            end

            if isJumping and sprite:IsEventTriggered("Land") then
                -- local creep = REVEL.SpawnGlacierDamagingCreep(npc, npc.Position, 3, data.bal.BloodColor)
                -- creep:ToEffect().Timeout = 20

                REVEL.game:ShakeScreen(10)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                for _, index in ipairs(pickSpawnIndicesNearPos(npc.Position, data.SpawnGroups, math.random(data.bal.GroundPoundSpawns.Min, data.bal.GroundPoundSpawns.Max))) do
                    local stalactiteChance = math.min(#icehazards, 10)
                    if math.random(1, 10) <= stalactiteChance then
                        data.SpawnIndices[#data.SpawnIndices + 1] = index + 10000
                    else
                        data.SpawnIndices[#data.SpawnIndices + 1] = index
                    end
                end
            end

            if isJumping and not sprite:WasEventTriggered("Land") then
                npc.Velocity = data.JumpVel
            else
                data.JumpVel = nil
            end

            if not isJumping and not sprite:IsPlaying("Turn") and npc:CollidesWithGrid() then
                npc.Velocity = npc.Velocity * data.bal.HighestFriction
            end

            if sprite:WasEventTriggered("Land") and not sprite:WasEventTriggered("Jump") then
                npc.Velocity = npc.Velocity * data.bal.HighestFriction
            end

            if not sprite:IsPlaying("Turn") and math.abs(npc.Velocity.X) > 6 and not isJumping then
                if (target.Position.X > npc.Position.X and npc.Velocity.X < 0) or (target.Position.X < npc.Position.X and npc.Velocity.X > 0) then
                    sprite.FlipX = not sprite.FlipX
                    sprite:Play("Turn", true)
                end
            end

            if block then
                if block.Position:DistanceSquared(npc.Position) < (block.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2 then
                    sprite:Play("Hit", true)
                    sprite.FlipX = block.Position.X > npc.Position.X
                    data.State = "Hit"
                    -- REVEL.DebugToString("hit ice block")
                    block:GetData().PunchVec = (block.Position-npc.Position):Normalized()
                    npc.Velocity = Vector.Zero
                    REVEL.PlaySound(npc, data.bal.Sounds.Bump)
                end
            end
        else
            npc.Velocity = npc.Velocity * data.bal.BaseFriction
        end

        if not sprite:IsPlaying("Turn") and not sprite:IsPlaying("Hit") and npc.Velocity:Length() > 1 then
            sprite.FlipX = npc.Velocity.X > 0
        end

        if npc.FrameCount % data.bal.BloodFrequency == 0 then
            local scale = math.random(data.bal.BloodScale.Min, data.bal.BloodScale.Max) / 100
            local splat = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, npc.Position, Vector.Zero, npc):ToEffect()
            splat.SpriteScale = Vector(scale, scale)
            splat.Color = data.bal.BloodColor
            splat:Update()
        end

        local impacted
        for _, stalactite in ipairs(stalactites) do
            if stalactite.Position:DistanceSquared(npc.Position) < (stalactite.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2 and not stalactite:IsDead() then
                stalactite:Die()
            end
        end

        for _, icehazard in ipairs(icehazards) do
            if icehazard.Position:DistanceSquared(npc.Position) < (icehazard.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2 and not icehazard:IsDead() and REVEL.GetEntityZPosition(icehazard) == 0 then
                local flingVel = (target.Position-npc.Position):Normalized() * data.bal.BlockPunchSpeed

                data.State = "Hit"
                -- REVEL.DebugToString("hit hazard")
                if not data.HittingEnemies then
                    data.HittingEnemies = {}
                end

                data.HittingEnemies[#data.HittingEnemies + 1] = {icehazard, flingVel, npc.Velocity}
                npc.Velocity = Vector.Zero

                npc:TakeDamage(npc.MaxHitPoints * data.bal.DefaultIceHazardDamage, 0, EntityRef(npc), 0)

                sprite:Play("HitHazard", true)
                REVEL.PlaySound(npc, data.bal.Sounds.Hurt)
                sprite.FlipX = target.Position.X > npc.Position.X
            end
        end

        for _, player in ipairs(REVEL.players) do
            if not player:GetData().Pitfalling and player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2 and player:GetDamageCooldown() > 0 then
                player.Velocity = npc.Velocity * data.bal.ImpactSpeedMulti
                impacted = true
                data.State = "Hit"
                -- REVEL.DebugToString("hit player")
                sprite:Play("Hit", true)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BIRD_FLAP, 0.7, 0, false, 1)
                REVEL.sfx:Play(SoundEffect.SOUND_PUNCH)
            end
        end

        if impacted then
            npc.Velocity = -npc.Velocity * data.bal.ImpactRecoil
        end

        for _, enemy in ipairs(REVEL.roomEnemies) do
            if GetPtrHash(enemy) ~= GetPtrHash(npc) and enemy.Position:DistanceSquared(npc.Position) < (enemy.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2 and enemy:IsVulnerableEnemy() and enemy:IsActiveEnemy(false) and enemy.CanShutDoors then
                enemy:TakeDamage(data.bal.EnemyImpactDamage, 0, EntityRef(npc), 0)
                enemy.Velocity = npc.Velocity * data.bal.ImpactSpeedMulti
            end
        end

        gridCrush(npc, data)

    -- HIT
    elseif data.State == "Hit" then
        if sprite:IsEventTriggered("Hit") and data.HittingEnemies then
            for _, enemyData in ipairs(data.HittingEnemies) do
                local icehazard = enemyData[1]
                icehazard.Velocity = enemyData[2]
                npc.Velocity = -enemyData[3] * data.bal.ImpactRecoil
                if icehazard:GetData().LockedInPlace then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
                    icehazard:GetData().BreakShotVel = data.bal.HazardShotSpeed
                    icehazard:GetData().BreakShotRotated = math.random(0,1)
                end

                icehazard:GetData().LockedInPlace = false
            end

            data.HittingEnemies = nil
        end

        if sprite:IsFinished("Hit") or sprite:IsFinished("HitShort") or sprite:IsFinished("HitHazard") then
            data.IdleWait = data.bal.QuickHitAttackCooldown
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * data.bal.BaseFriction
    
    -- RESPAWN
    elseif data.State == "Respawn" then
        if sprite:GetFrame() == 1 and sprite:IsPlaying("Respawn") then
            REVEL.PlaySound(npc,SoundEffect.SOUND_REVERSE_EXPLOSION,0.5,2,false,1.1)
        end

        if sprite:IsEventTriggered("Blood") then
            REVEL.PlaySound(npc, data.bal.Sounds.MeatSpawn)
        end

        if sprite:IsEventTriggered("Flex") then
            REVEL.PlaySound(npc, data.bal.Sounds.AngryStart)
        end

        data.IdleWait = data.IdleWait or data.bal.DefaultAttackCooldown
        if data.IdleWait <= 0 then
            if sprite:IsFinished("Respawn") then
                data.State = "PostDeath"
                data.IdleWait = nil

            elseif not sprite:IsPlaying("Respawn") then
                npc.Visible = true
                sprite:Play("Respawn", true)
            end
        else
            data.IdleWait = data.IdleWait - 1
            sprite:Play("Idle", true)
        end

        npc.Velocity = Vector.Zero

    -- POST DEATH
    elseif data.State == "PostDeath" then
        if not data.Substate then
            if not sprite:IsPlaying("Idle4") then
                sprite:Play("Idle4")
            end

            data.IdleWait = data.IdleWait or data.bal.QuickHitAttackCooldown
            if data.IdleWait <= 0 then
                if block and block:Exists() then
                    data.Substate = "BlockSmash"
                else
                    data.Substate = "BlockSpawn"
                end

                data.IdleWait = nil
            else
                data.IdleWait = data.IdleWait - 1
            end
        
        elseif data.Substate == "BlockSpawn" then
            if not sprite:IsPlaying("SpawnIceDeath") then
                sprite:Play("SpawnIceDeath")
            end

            if sprite:IsEventTriggered("Land") then
                REVEL.game:ShakeScreen(10)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            end

            if sprite:WasEventTriggered("Land") then
                npc.Velocity = npc.Velocity * data.bal.HighestFriction
            else
                npc.Velocity = npc.Velocity * data.bal.BaseFriction
            end

            if sprite:IsFinished("SpawnIceDeath") then
                REVEL.sfx:Play(SoundEffect.SOUND_MIRROR_BREAK)
                for i=1, 10 do
                    REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(2, 6)), npc, 0)
                end
                for i = 1, math.random(20, 25) do
                    local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, RandomVector(), npc):ToProjectile()
                    projectile.FallingSpeed = -11 + math.random(-8, 8)
                    projectile.FallingAccel = 0.5
                    projectile.Velocity = projectile.Velocity * (math.random(20, 60) * 0.1)
                    projectile:GetData().SpawnIceCreep = true
                    -- projectile:GetData().IceCreepTimeout = projtimeout
                    projectile:GetData().IceCreepScaleMulti = 1
                end
                REVEL.game:ShakeScreen(20)
                local eff = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()
                eff:GetSprite().Color = REVEL.WaterSplatColor

                local faceDir = -1
                if npc.FlipX then faceDir = 1 end
                
                chuckDeathDeco(npc,npc.Position,"Death2",data.Gigachuck,data.bal)

                npc:Remove()
                return
            end
        elseif data.Substate == "BlockSmash" then
            if (not block) or (block and not block:Exists()) then data.Substate = nil end

            local faceDir = -1
            if npc.FlipX then faceDir = 1 end
            local blockOffset = (block.Position+(Vector(data.bal.BlockOffset,0)*-faceDir))

            if sprite:IsFinished("Dash3 Start") then
                sprite:Play("Dash3")

            elseif sprite:WasEventTriggered("Dash") or sprite:IsPlaying("Dash3") then
                gridCrush(npc, data)
                npc.CollisionDamage = 1

                if block.Position:DistanceSquared(npc.Position) > (block.Size + npc.Size + data.bal.ExtraImpactDistance) ^ 2
                and REVEL.room:CheckLine(npc.Position,block.Position,2,0,false,false) then
                    npc.Velocity = REVEL.Lerp(npc.Velocity,(blockOffset-npc.Position):Normalized() * data.bal.FinalDashSpeed,0.1)
                elseif npc.Position:Distance(block.Position) <= data.bal.PushRangeMin then
                    REVEL.game:ShakeScreen(20)
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                    block:GetSprite().FlipX = sprite.FlipX
                    block:GetData().State = "Death"
                    block:GetData().ChuckPosition = npc.Position
                    npc:Remove()
                    return
                else
                    path:FindGridPath(block.Position, data.bal.FinalDashSpeed*0.15, 900, true)
                end
            else
                npc.Velocity = npc.Velocity * data.bal.HighestFriction
            end
            npc.FlipX = npc.Position.X < block.Position.X

            if not sprite:IsPlaying("Dash3 Start")
            and not sprite:IsPlaying("Dash3") then
                sprite:Play("Dash3 Start")
            end

        end
    end

end, REVEL.ENT.CHUCK.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.CHUCK_ICE_BLOCK:isEnt(npc) then
        return
    end

    local sprite, data, target = npc:GetSprite(), npc:GetData(), npc:GetPlayerTarget()

    if not data.Init then
        npc:AddEntityFlags(BitOr(
            EntityFlag.FLAG_DONT_COUNT_BOSS_HP,
            EntityFlag.FLAG_NO_KNOCKBACK,
            EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK, 
            EntityFlag.FLAG_NO_STATUS_EFFECTS,
            EntityFlag.FLAG_NO_TARGET
        ))
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
        data.Init = true
    end

    if not data.Chuck or not data.Chuck:Exists() then
        data.Chuck = Isaac.FindByType(REVEL.ENT.CHUCK.id, REVEL.ENT.CHUCK.variant, -1, false, false)[1]
    end

    if data.Chuck and not data.bal then
        data.bal = data.Chuck:GetData().bal
        if data.Chuck:GetData().Gigachuck then
            data.Gigachuck = true
            npc:GetSprite():ReplaceSpritesheet(1, "gfx/bosses/revel1/chuck/gigachuck.png")
            npc:GetSprite():LoadGraphics()
        end
    end

    if not data.PushDirection then
        npc.CollisionDamage = 0
    end

    if sprite:IsEventTriggered("Crack") then
        for i = 1, 3 do
            REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(4, 12), npc)
        end

        REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_CRACK, 1, 0, false, 0.9 + math.random()*0.1)
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle")
        end

    elseif data.State == "Toss" then
        data.Airborne = true
        if not sprite:IsPlaying("Toss") then
            sprite:Play("Toss")
        end

        if sprite:IsEventTriggered("Land") then
            REVEL.game:ShakeScreen(4)
            REVEL.PlaySound(npc, data.bal.Sounds.Bump)
        end

        if sprite:IsFinished("Toss") then
            data.State = "Idle"
        end

        if sprite:WasEventTriggered("Land") then
            data.Airborne = false
            npc.Velocity = npc.Velocity * 0.5
        else
            local faceDir = data.FaceDir or -1
            npc.Velocity = Vector(5*faceDir,0)
        end

    elseif data.State == "Thrown" then
        data.Airborne = true
        npc.Velocity = (data.Chuck.Position - npc.Position) * 0.2

        if not sprite:IsPlaying("Thrown") then
            sprite:Play("Thrown")
        end

        if sprite:IsFinished("Thrown") then
            npc.Visible = false
        end

    elseif data.State == "ThrownHigh" then
        if not npc.Visible then
            sprite:Play("Throw High", true)
            npc.Visible = true
        end

        if sprite:IsFinished("Throw High") then
            sprite:Play("Airborn", true)
            data.AirbornTime = 0
            data.StartPos = npc.Position
            data.TargetPos = REVEL.room:GetClampedPosition(npc:GetPlayerTarget().Position, npc.Size * 2)
        end

        if data.AirbornTime then
            data.AirbornTime = data.AirbornTime + 1
            npc.Velocity = REVEL.Lerp(data.StartPos, data.TargetPos, data.AirbornTime / data.bal.IceBlockFlightTime) - npc.Position
            if data.AirbornTime >= data.bal.IceBlockFlightTime then
                sprite:Play("Land", true)
                data.AirbornTime = nil
                data.LockPosition = nil
                data.TargetPos = nil
                data.StartPos = nil
                npc.Velocity = Vector.Zero
            end
        end
    
        if sprite:IsEventTriggered("Land") then
            for i = 1, 5 do
                REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(4, 12), npc)
            end
    
            data.BloodCreep = false
            data.Airborne = false
            REVEL.game:ShakeScreen(20)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
    
            local angleOffset = 0
            if data.IsCrackedBlock then
                angleOffset = 45
            end
    
            for num = 1, 12 do
                local dir = Vector.FromAngle(num * 30)
                if num == 1 then
                    REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 4, "gfx/effects/revel1/glacier_shockwave.png", 30, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
                else
                    REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 4, "gfx/effects/revel1/glacier_shockwave.png", 30)
                end
            end
    
            for i = 1, math.random(20, 25) do
                local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, RandomVector(), npc):ToProjectile()
                projectile.FallingSpeed = -11 + math.random(-8, 8)
                projectile.FallingAccel = 0.5
                projectile.Velocity = projectile.Velocity * (math.random(20, 60) * 0.1)
                projectile:GetData().SpawnIceCreep = true
                -- projectile:GetData().IceCreepTimeout = projtimeout
                projectile:GetData().IceCreepScaleMulti = 1
            end
        end
    
        if sprite:IsFinished("Land") then
            data.State = "Idle"
        end

    elseif data.State == "Break" then

        if sprite:IsFinished("Break") then
            for i=1, 10 do
                REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(2, 6)), npc, 0)
            end
            local playerDir = (target.Position - npc.Position):Normalized()
			for i = 1, math.random(20, 25) do
                local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, playerDir:Rotated(math.random(-35, 35)), npc):ToProjectile()
                projectile.FallingSpeed = -14 + math.random(-8, 8)
                projectile.FallingAccel = 0.5
                projectile.Velocity = projectile.Velocity * (math.random(20, 90) * 0.1)
                projectile:GetData().SpawnIceCreep = true
                -- projectile:GetData().IceCreepTimeout = projtimeout
                projectile:GetData().IceCreepScaleMulti = 1
            end
            REVEL.game:ShakeScreen(10)
            local eff = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()
            eff:GetSprite().Color = REVEL.WaterSplatColor
            npc:Remove()

        elseif not sprite:IsPlaying("Break") then
            REVEL.sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER, 0.95, 0, false, 0.85)
            REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.95, 0, false, 0.9)
            sprite:Play("Break")
        end

    elseif data.State == "Death" then
        if sprite:IsFinished("Death") then
            REVEL.game:ShakeScreen(20)
            REVEL.sfx:Play(SoundEffect.SOUND_FREEZE_SHATTER, 0.95, 0, false, 0.85)
            REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.95, 0, false, 0.9)

            REVEL.SpawnDustParticles(npc.Position, 12, npc, Color(1, 1, 1, 1,conv255ToFloat( 97, 140, 181)), 1000, 1500)

            for i = 1, 12 do
                REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(4, 12), npc, true)
            end

            REVEL.PlaySound(npc, data.bal.Sounds.Dead)

            chuckDeathDeco(npc,data.ChuckPosition,"Death",data.Gigachuck,data.bal)

            npc:Remove()
            return
        end

        if not sprite:IsPlaying("Death") then
            sprite:Play("Death")
        end

        npc.Velocity = Vector.Zero

    elseif sprite:IsFinished("Idle") or sprite:IsPlaying("Idle") or sprite:IsPlaying("Land") then
        data.Airborne = false
    end

    if data.BloodCreep and not data.Airborne then
        if npc.FrameCount % data.bal.CreepInterval == 0 then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
            REVEL.UpdateCreepSize(creep, creep.Size * 1.5, true)
            creep:ToEffect():SetTimeout(50)
        end

        data.BloodCreep = data.BloodCreep - 1
        if data.BloodCreep < 0 then
            data.BloodCreep = false
        end
    end

    if not data.Airborne then
        gridCrush(npc, data)

        if npc.Velocity:Length() > 4 then
            for _,ent in ipairs(REVEL.roomEnemies) do
                if ent.Type ~= npc.Type and ent.Type ~= data.Chuck.Type
                and not ent:GetData().ChuckSmacked then
                    if ent.Position:DistanceSquared(npc.Position) < (20 + npc.Size + 8) ^ 2 then
                        if ent.HitPoints < 25 then
                            ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
                            ent:Kill()
                            data.BloodCreep = ent.MaxHitPoints * 10
                        else
                            ent:TakeDamage(10,0,EntityRef(npc),0)
                        end
                    end
                end
            end
        end
    end

    if data.Airborne then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    --Pushing towards an ice target
    elseif data.HazardTarget then
        data.LockPosition = nil
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
        npc.Velocity = REVEL.Lerp(npc.Velocity,(data.HazardTarget.Position-npc.Position):Normalized() * data.bal.PushingBlockSpeed,0.2)

        if npc.Position:Distance(data.HazardTarget.Position) < 50 then
            data.Chuck:GetData().HazardSmash = true

            if data.HazardTarget:Exists() then
                local shotSpeed = data.bal.HazardShotSpeed
                local rotated = 0
                if #data.Chuck:GetData().HazardOrder % 2 == 0 then rotated = 45 end
                for i = 1, 4 do
                    Isaac.Spawn(9, 4, 0, data.HazardTarget.Position, Vector.FromAngle((i * 90) + rotated) * shotSpeed, npc)
                end

                data.HazardTarget:GetData().ChuckSmackVel = npc.Velocity*data.bal.EnemySmackMulti
                data.HazardTarget:Kill()
            end
            data.HazardTarget = nil
        end
        npc.CollisionDamage = 1

    --Launched after punched
    elseif data.PunchVec then
        data.LockPosition = nil
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
        npc.Velocity = data.PunchVec * data.bal.BlockPunchSpeed

        if npc:CollidesWithGrid() then
            data.State = "Break"
            data.PunchVec = nil
        end

        if npc.Velocity:Length() > 4 then
            data.DustLastPos = data.DustLastPos or npc.Position
    
            if data.DustLastPos:DistanceSquared(npc.Position) > 30*30 then
                ---@type EntityEffect
                local dust = Isaac.Spawn(
                    1000, 
                    EffectVariant.DUST_CLOUD, 
                    0, 
                    npc.Position, 
                    Vector.Zero, 
                    npc
                ):ToEffect()
                dust.Timeout = math.random(30, 45)
                dust.LifeSpan = dust.Timeout
                dust.Color = Color(1.25, 1.25, 1.25, 0.75, 0.5, 0.5, 0.5)
                dust.DepthOffset = -75
    
                data.DustLastPos = npc.Position
            end
        end
        npc.CollisionDamage = 1
    else
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
        if npc.Velocity:Length() < 0.5 then
            if not data.LockPosition then
                data.LockPosition = npc.Position
            end
            npc.Velocity = Vector.Zero
            npc.Position = data.LockPosition
        else
            npc.Velocity = REVEL.Lerp(npc.Velocity,Vector.Zero,0.1)
        end
        npc.CollisionDamage = 0
    end

    if sprite:IsEventTriggered("Crack") then
        for i = 1, 3 do
            REVEL.SpawnIceRockGib(npc.Position, RandomVector() * math.random(4, 12), npc)
        end

        REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_CRACK, 1, 0, false, 0.9 + math.random()*0.1)
    end
end, REVEL.ENT.CHUCK_ICE_BLOCK.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount)
    if entity.Variant == REVEL.ENT.CHUCK.variant then
        local data, sprite = entity:GetData(), entity:GetSprite()
        if not data.Init then
            return
        end

        if data.Death then
            return false
        end

        if sprite:IsPlaying("Throw")
        or sprite:IsPlaying("Idle2")
        or sprite:IsPlaying("Catch") then
            return false
        end

        --High reduction while transitioning to phase 2
        if data.State == "Throw" or data.State == "Stunned" then
            local dmgReduction = amount*data.bal.DamageResistPct2
            entity.HitPoints = math.min(entity.HitPoints + dmgReduction, entity.MaxHitPoints)

        --High reduction if below threshold and still in phase 1
        elseif entity.HitPoints < entity.MaxHitPoints*data.bal.HPToNextPhase and not data.Phase2 then
            local dmgReduction = amount*data.bal.DamageResistPct2
            entity.HitPoints = math.min(entity.HitPoints + dmgReduction, entity.MaxHitPoints)

        --Low reduction while in phase 1 and not pushing block
        elseif data.State ~= "BlockChain" then
            local dmgReduction = amount*data.bal.DamageResistPct
            entity.HitPoints = math.min(entity.HitPoints + dmgReduction, entity.MaxHitPoints)
        end

        if entity.HitPoints - amount - REVEL.GetDamageBuffer(entity) <= 0 then
            entity.HitPoints = REVEL.GetDamageBuffer(entity)
            entity.MaxHitPoints = 0

            local splat = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 1, entity.Position + Vector(0, 1), Vector.Zero, entity):ToEffect()
            splat.SpriteOffset = Vector(0, -30)
            splat.Color = entity:GetData().bal.BloodColor

            local explosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 1, entity.Position, Vector.Zero, entity)
            explosion.Color = entity:GetData().bal.BloodColor

            REVEL.sfx:Play(SoundEffect.SOUND_ROCKET_BLAST_DEATH, 1)

            local guy = Isaac.Spawn(EntityType.ENTITY_HOPPER, 0, 0, entity.Position, Vector.Zero, entity)
            guy:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            guy:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
            guy.Visible = false
            guy.SplatColor = entity:GetData().bal.BloodColor
            guy:Kill()

            -- entity.HitPoints = entity.MaxHitPoints
            entity:GetData().State = "Respawn"
            entity:GetData().Death = true
            entity:GetData().Substate = nil
            entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
            entity.Visible = false
            entity.CollisionDamage = 0
            entity.Position = entity:GetData().StartPosition

            local iceblocks = Isaac.FindByType(REVEL.ENT.CHUCK_ICE_BLOCK.id, REVEL.ENT.CHUCK_ICE_BLOCK.variant, -1, false, false)
            for _, block in ipairs(iceblocks) do
                local sprite, data = block:GetSprite(), block:GetData()
                block.CollisionDamage = 0
                block.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                block.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
                data.HazardTarget = nil
                block.Visible = true
                data.Airborne = false
                if data.LockPosition then
                    block.Position = data.LockPosition
                end
                data.State = "Idle"
            end

            return false
        end
    end
end, REVEL.ENT.CHUCK.id)

end