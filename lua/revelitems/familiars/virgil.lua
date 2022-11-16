local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    ------------
    -- VIRGIL --
    ------------

    revel.virgil = {
        defOffsetStep = 1 / 20,
        defTRockTime = 25, -- time he takes to go onto tinted rock
        angryPointingDuration = 75,
        angryPointingOffset = Vector(1, 1):Resized(1), -- this gets multiplied
        trocks = {}, -- tinted/secret
        thrownRocks = {},
        stageToRoomType = {},
        idlePlayerDistanceMax = 120,
        enemyRockCooldown = {Min = 350, Max = 420},
        stageToDoorName = {},
        revelStageToDoorName = {
            ["Glacier 2"] = "TombEntranceDoorBoss",
            ["Tomb 2"] = nil
        },
        companionChance = 1 / 25,
        rockEnemyBlacklist = {
            -- part is defined in game_start cause revel2_modcompat
            [EntityType.ENTITY_PORTAL] = -1,
            [EntityType.ENTITY_GUSHER] = -1,
            [EntityType.ENTITY_DIP] = {0, 1}
        },
        busyStates = {
            "Respawn", "Throw_Rock_Enemy", "Run_Away", "Throw_Rock",
            "Throw_Bomb", "AngryPointing", "Swat_Bomb", "Point_Trapdoor"
        }, -- states for which he is considered busy and cannot take new actions
        pathMap = REVEL.NewPathMapFromTable("Virgil Flee Enemies", {
            GetTargetIndices = function()
                local targets = {}
                local virgils = Isaac.FindByType(3, REVEL.ENT.VIRGIL.variant,
                                                 -1, true)
                for _, ent in ipairs(virgils) do
                    local data = ent:GetData()
                    if data.evadeEnemy then
                        targets[#targets + 1] =
                            REVEL.room:GetGridIndex(data.evadeEnemy.Position)
                    end
                end

                return targets
            end,
            GetInverseCollisions = function()
                local inverseCollisions = {}
                for i = 0, REVEL.room:GetGridSize() do
                    if REVEL.room:IsPositionInRoom(
                        REVEL.room:GetGridPosition(i), 0) then
                        inverseCollisions[i] =
                            REVEL.room:GetGridCollision(i) == 0
                    end
                end

                return inverseCollisions
            end,
            OnPathUpdate = function(map)
                local virgils = Isaac.FindByType(3, REVEL.ENT.VIRGIL.variant,
                                                 -1, true)

                for _, ent in ipairs(virgils) do
                    local data = ent:GetData()
                    if data.evadeEnemy then
                        data.Path, data.PathLength =
                            REVEL.GeneratePathAStar(
                                REVEL.room:GetGridIndex(ent.Position),
                                map.TargetMapSets[1].FarthestIndex)
                    end
                end
            end
        })
    }

    revel.virgil.GameStart = function()
        revel.virgil.rockEnemyBlacklist[REVEL.COMP_ENTS.POTATO_FOR_SCALE.id] = {
            REVEL.COMP_ENTS.POTATO_FOR_SCALE.variant
        }
    end

    revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, revel.virgil.GameStart)

    if Isaac.GetPlayer(0) then revel.virgil.GameStart() end

    if DetailedRespawn then
        REVEL.DRes_VirgilIdx = #DetailedRespawn.Respawns + 1
        DetailedRespawn.AddCustomRespawn({
            Name = "Virgil",
            ItemId = REVEL.ITEM.VIRGIL.id,
            Condition = function(player)
                return REVEL.ITEM.VIRGIL:PlayerHasCollectible(player) and
                           not revel.data.run.virgilRevive
            end
        }, REVEL.DRes_VirgilIdx)
    end

    revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if HasBit(flag, CacheFlag.CACHE_FAMILIARS) then
            --    REVEL.DebugToString({player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) , REVEL.ITEM.VIRGIL:GetCollectibleNum(player)})
            local num = (REVEL.ITEM.VIRGIL:GetCollectibleNum(player) +
                            (revel.data.run.virgilTemp[REVEL.GetPlayerID(player)] or 0)) *
                            (player:GetEffects():GetCollectibleEffectNum(
                                CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            --    REVEL.DebugToString(num)
            local rng = REVEL.RNG()
            rng:SetSeed(math.random(10000), 0)
            player:CheckFamiliar(REVEL.ENT.VIRGIL.variant, num, rng:GetRNG())
        end
    end)

    revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, e)
        e:GetData().player = e.Player -- used when it was not a proper familiar, kept in case it stops being one again
        e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        e.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        e.Player:GetData().virgil = e
        e:GetSprite():Play("Idle", true)
        --  e:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

        if e:GetData().startPos then -- manual spawn bug workaround
            e.Position = e:GetData().startPos
        end
    end, REVEL.ENT.VIRGIL.variant)

    local function getGoodSecretRocks()
        local trocks = {}
        for i, v in ipairs(REVEL.roomRocks) do
            if v and v.State ~= 2 and
                (v:GetType() == GridEntityType.GRID_ROCKT or
                    REVEL.room:GetDungeonRockIdx() == v:GetGridIndex()) and
                not revel.data.run.virgilTargetedRocks[tostring(
                    REVEL.room:GetDecorationSeed() * v:GetGridIndex())] then
                table.insert(trocks, v)
            end
        end

        return trocks
    end

    local function goToPos(pos, eff, data, speed, dist)
        pos = Isaac.GetFreeNearPosition(pos, 20)

        data.gotoSpeed = speed or data.speed

        data.gotoDist = dist or 2

        data.targetPos = pos
    end

    local function goToEnt(ent, eff, data, speed, offset)
        data.targetEnt = ent
        data.targetEntSpeed = speed or data.speed
        data.targetEntOffset = offset or Vector.Zero
    end

    local function stopGoToPos(eff, data) data.targetPos = nil end

    local function stopGoToEnt(data) data.targetEnt = nil end

    local function defaultMove(ent, data, spr)
        if not data.targetPos then
            if data.randomMoveTimer == 0 then
                --      REVEL.DebugToString("test")
                local pos = Isaac.GetFreeNearPosition(
                                data.player.Position + RandomVector() *
                                    (math.random() *
                                        revel.virgil.idlePlayerDistanceMax), 20)
                local speedMult = 1

                if REVEL.room:IsClear() then speedMult = 0.5 end

                goToPos(pos, ent, data, data.speed * speedMult, 100)
                data.randomMoveTimer = 25 + math.random(25)
            else
                data.randomMoveTimer = data.randomMoveTimer - 1

                if data.player.Position:DistanceSquared(ent.Position) >
                    (revel.virgil.idlePlayerDistanceMax * 1.1) ^ 2 then
                    data.randomMoveTimer = 0
                end
            end
        end
    end

    revel.virgil.walkAnims = {
        Horizontal = "WalkHori",
        Up = "WalkUp",
        Down = "WalkDown"
    }

    local function animWalkFrame(vel, spr, data)
        REVEL.AnimateWalkFrameSpeed(spr, vel, revel.virgil.walkAnims, false,
                                    false, "Idle")
    end

    local function playExtraAnim(anim, state, ent, spr, data)
        spr.PlaybackSpeed = 1
        data.ExtraAnim = anim
        spr:Play(anim, true)
        data.ExtraAnimState = state -- can be nil
    end

    StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
        revel.virgil.trocks = getGoodSecretRocks()
        revel.virgil.thrownRocks = {}

        for i, player in ipairs(REVEL.players) do
            local virgil = player:GetData().virgil
            if virgil then
                if virgil:GetData().State == "Respawn" then
                    stopGoToPos(virgil, virgil:GetData())
                    player.Position = Isaac.GetFreeNearPosition(
                                          player.Position + Vector(-64, 0), 32)
                    virgil.Position = Isaac.GetFreeNearPosition(
                                          player.Position + Vector(0, 32), 32)
                else
                    virgil.Position = player.Position
                end

                REVEL.SpawnLightAtEnt(
                    virgil, 
                    Color(1, 0.5, 0, 1, conv255ToFloat(255, 150, 0)),
                    1.5
                )
            end
        end

        if revel.data.run.tempVirgilThisFloor and
            REVEL.level:GetCurrentRoomIndex() ==
            REVEL.level:GetStartingRoomIndex() then
            local ent = REVEL.ENT.VIRGIL_W:spawn(
                            REVEL.room:GetTopLeftPos() + Vector(92, 76),
                            Vector.Zero, nil)
            ent:GetSprite():Play("Idle", true)
        end
    end)

    revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, ent)
        if ent.Variant ~= REVEL.ENT.VIRGIL.variant then return end

        local spr, data = ent:GetSprite(), ent:GetData()

        local standstill

        if not data.vInit then
            data.State = "Move_Default"
            data.FrameCount = 0
            data.WalkFrame = 0
            data.rockCooldown = 0
            data.tRockCooldown = 0
            data.speed = 5
            data.randomMoveTimer = 0
            data.prevTarg = Vector(0, 0)

            data.vInit = true
        end

        if REVEL.room:GetFrameCount() == 1 then
            data.randomMoveTimer = 0
            data.FrameCount = 0
            if data.State ~= "Respawn" then
                data.State = "Move_Default"
            end
            stopGoToPos(ent, data)
            stopGoToEnt(data)
        end

        -- REVEL.DebugToConsole(data.State)

        if data.State == "Throw_Bomb" then
            if ent.Position:Distance(data.rockTarget.Position) < 350 then
                if data.targetPos then stopGoToPos(ent, data) end

                standstill = true
                if not IsAnimOn(spr, "ThrowBomb") then
                    playExtraAnim("ThrowBomb", nil, ent, spr, data)
                elseif spr:IsFinished("ThrowBomb") then
                    data.tRockCooldown = 100
                    data.State = "Move_Default"
                elseif spr:IsEventTriggered("Throw") then
                    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP,
                                             BombVariant.BOMB_NORMAL, 0,
                                             ent.Position, (data.rockTarget
                                                 .Position - ent.Position) *
                                                 0.05, ent)
                    bomb.GridCollisionClass =
                        EntityGridCollisionClass.GRIDCOLL_WALLS
                end
            end
        elseif data.State == "Throw_Rock" then
            if ent.Position:Distance(data.rockTarget.Position) < 350 then
                if data.targetPos then stopGoToPos(ent, data) end

                standstill = true
                if not IsAnimOn(spr, "ThrowRockSecret") then
                    playExtraAnim("ThrowRockSecret", nil, ent, spr, data)
                elseif spr:IsFinished("ThrowRockSecret") then
                    data.tRockCooldown = 100
                    data.State = "Move_Default"
                elseif spr:IsEventTriggered("Throw") then
                    revel.virgil.throwRock(ent, data.rockTarget.Position, false,
                                           true)
                end
            end
        elseif data.State == "Swat_Bomb" then
            if data.swatBomb:Exists() and not data.swatBomb:IsDead() then
                if ent.Position:Distance(data.swatBomb.Position) < 16 then
                    -- keep pushing mega troll bombs
                    if data.swatBomb.Variant ~= BombVariant.BOMB_SUPERTROLL then
                        if not IsAnimOn(spr, ("SlapFast")) then
                            stopGoToEnt(data)
                            playExtraAnim("SlapFast", nil, ent, spr, data)
                        elseif spr:IsEventTriggered("Slap") then
                            data.swatBomb.Velocity =
                                (data.swatBomb.Position - data.player.Position):Resized(
                                    15)
                            data.swatBomb:GetData().swatted = true
                        end
                    else
                        data.swatBomb.Velocity =
                            (data.swatBomb.Position - data.player.Position):Resized(
                                ent.Velocity:Length())
                    end
                end
                if spr:IsFinished("SlapFast") then
                    data.State = "Move_Default"
                    data.swatBomb = nil
                end
            else
                data.State = "Move_Default"
            end
        elseif data.State == "AngryPointing" then
            if spr:IsFinished("Point") or not data.pointingAt:Exists() or
                data.pointingAt:IsDead() then
                data.State = "Move_Default"
            elseif spr:IsPlaying("Point") then
                standstill = true
            end

            if data.pointingAt.Position:Distance(ent.Position) < 80 and
                not IsAnimOn(spr, "Point") then
                stopGoToEnt(data)
                data.pointingAt:AddConfusion(EntityRef(ent), revel.virgil
                                                 .angryPointingDuration, true)
                playExtraAnim("Point", nil, ent, spr, data)
                spr.FlipX = ent.Position.X > data.pointingAt.Position.X
            end
        elseif data.State == "Throw_Rock_Enemy" then
            if data.targetEnt and
                data.targetEnt.Position:DistanceSquared(ent.Position) < 25600 and
                not IsAnimOn(spr, "ThrowRock") then
                playExtraAnim("ThrowRock", nil, ent, spr, data)
            elseif spr:IsPlaying("ThrowRock") then
                standstill = true
            elseif not data.targetEnt then
                data.State = "Move_Default"
            end

            if spr:IsFinished("ThrowRock") then
                data.State = "Run_Away"
                data.FrameCount = 0
                stopGoToEnt(data)
            elseif spr:IsEventTriggered("Throw") then
                data.thrownRockEnemy = revel.virgil.throwRock(ent,
                                                              data.evadeEnemy
                                                                  .Position,
                                                              true, false, 10)
            end
        elseif data.State == "Point_Secret" then
            if not data.targetPos and not IsAnimOn(spr, "Point") then
                if data.doorPosX then
                    spr.FlipX = data.doorPosX < ent.Position.X
                end

                playExtraAnim("Point", "Point_Secret", ent, spr, data)
            end
        elseif data.State == "Point_Trapdoor" then
            if not data.targetPos and not IsAnimOn(spr, "Happy") then
                playExtraAnim("Happy", nil, ent, spr, data)
            elseif spr:IsFinished("Happy") then
                data.State = "Move_Default"
            end
            if not data.targetPos then standstill = true end
        elseif data.State == "Respawn" then
            if data.player:IsDead() and data.player:GetExtraLives() == 0 
            and data.player:GetSprite():GetFrame() == 39 then
                REVEL.SafeRoomTransition(
                    REVEL.level:GetLastRoomDesc().SafeGridIndex, true)
                REVEL.FadeIn(15)
                playExtraAnim("Happy", nil, ent, spr, data)
                data.player:Revive()
                data.player:PlayExtraAnimation("Appear")

                if data.player:GetMaxHearts() > 0 then
                    data.player:AddHearts(data.player:GetMaxHearts())
                else
                    data.player:AddSoulHearts(4)
                end
            end

            standstill = true

            if spr:IsFinished("Happy") then
                data.State = "Move_Default"
            end
        elseif data.State == "Move_Default" then -- default move, "lead" player
            defaultMove(ent, data, spr)
        end

        if data.State ~= "Run_Away" and data.dummy then -- just in case
            data.dummy:Remove()
            data.dummy = nil
        end

        if not data.ExtraAnim then
            animWalkFrame(ent.Velocity, spr, data)
        elseif spr:IsFinished(data.ExtraAnim) or
            (data.ExtraAnimState and data.State ~= data.ExtraAnimState) then
            data.ExtraAnim = nil
        end

        local path, targ, speed

        if data.targetEnt and
            (not data.targetEnt:Exists() or data.targetEnt:IsDead()) then
            data.targetEnt = nil
        end

        -- IDebug.RenderUntilNextUpdate(Isaac.RenderText, data.State ..";".. tostring(data.rockCooldown), 30, 60, 255, 255, 255, 255)

        if data.State == "Run_Away" then
            data.FrameCount = data.FrameCount + 1
            if data.evadeEnemy:Exists() and not data.evadeEnemy:IsDead() then
                -- IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, data.evadeEnemy.Position, nil, nil, nil, nil, Color(0, 1, 1, 1,conv255ToFloat( 0, 0, 0)))

                if data.evadeEnemy:GetData().pissedOff then
                    path = data.Path
                    speed = data.speed
                    targ = data.evadeEnemy.Position

                    if not data.dummy then
                        data.dummy = Isaac.Spawn(3,
                                                 FamiliarVariant.PUNCHING_BAG,
                                                 0, ent.Position, ent.Velocity,
                                                 ent)
                        data.dummy:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        data.dummy.Color = REVEL.NO_COLOR
                    end

                    data.dummy.Visible = false
                    data.evadeEnemy.Target = data.dummy -- set in take damage
                else
                    standstill = true
                    if data.thrownRockEnemy:IsDead() or
                        not data.thrownRockEnemy:Exists() then -- missed shot
                        data.State = "Move_Default"
                        data.evadeEnemy = nil
                        data.rockCooldown = 0
                    end
                end

                if data.FrameCount > 250 then
                    data.State = "Move_Default"
                    data.evadeEnemy.Target = data.player
                    data.evadeEnemy:GetData().pissedOff = false
                    data.evadeEnemy = nil
                    data.FrameCount = 0
                    if data.dummy then
                        data.dummy:Remove()
                        data.dummy = nil
                    end
                    data.rockCooldown = revel.virgil.enemyRockCooldown.Min +
                                            math.random(
                                                revel.virgil.enemyRockCooldown
                                                    .Max -
                                                    revel.virgil
                                                        .enemyRockCooldown.Min)
                end
            else
                data.FrameCount = 0
                data.State = "Move_Default"
                data.evadeEnemy = nil
                data.rockCooldown = revel.virgil.enemyRockCooldown.Min +
                                        math.random(
                                            revel.virgil.enemyRockCooldown.Max -
                                                revel.virgil.enemyRockCooldown
                                                    .Min)
            end
        elseif data.targetEnt then
            targ = data.targetEntOffset + data.targetEnt.Position
            local sind, tind = REVEL.room:GetGridIndex(ent.Position),
                               REVEL.room:GetGridIndex(targ)

            path = REVEL.GeneratePathAStar(sind, tind)

            speed = data.targetEntSpeed
        elseif data.targetPos then
            targ = data.targetPos

            local sind, tind = REVEL.room:GetGridIndex(ent.Position),
                               REVEL.room:GetGridIndex(targ)

            path = REVEL.GeneratePathAStar(sind, tind)
            speed = data.gotoSpeed *
                        math.min(1, targ:Distance(ent.Position) / 60 + 0.5)

            if ent.Position:Distance(data.targetPos) < data.gotoDist then
                data.targetPos = nil
                standstill = true
            end
        end

        if (targ and
            (not data.prevTarg or targ:DistanceSquared(data.prevTarg) > 50)) or
            (path and #path ~= data.prevPathLength) then
            data.PathIndex = 1
        end

        --  if targ then
        --    REVEL.DebugToString({targ, REVEL.room:GetGridIndex(targ)})
        --  end

        if standstill or not (targ and path) then
            local l = ent.Velocity:LengthSquared()
            if l < 0.01 then
                ent.Velocity = Vector.Zero
            else
                ent:MultiplyFriction(0.8)
            end
        elseif #path == 0 then
            -- IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, targ, nil, nil, nil, nil, Color(0, 0, 1, 1,conv255ToFloat( 0, 0, 0)))
            ent.Velocity = ent.Velocity +
                               (targ - ent.Position):Resized(speed * 0.2)
            ent:MultiplyFriction(0.8)
        else
            -- IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, REVEL.room:GetGridPosition(path[1]))
            REVEL.FollowPath(ent, speed * 0.2, path, true, 0.8)
        end

        --    REVEL.DebugToString({data.State, data.dummy, data.dummy:Exists()})

        if data.dummy then
            data.dummy.Position = ent.Position
            data.dummy.Velocity = ent.Velocity

            --    REVEL.DebugToString(data.dummy.Position)
        end

        if data.rockCooldown > 0 then
            data.rockCooldown = data.rockCooldown - 1
        end
        if data.tRockCooldown > 0 then
            data.tRockCooldown = data.tRockCooldown - 1
        end

        if data.player:IsDead() and data.player:GetExtraLives() == 0 
        and data.player:GetSprite():GetFrame() == 10 
        and not revel.data.run.virgilRevive then
            revel.data.run.virgilRevive = true
            --    if math.random(100) <= 20*math.max(player.Luck*0.2/7+1, 0.5)  then
            data.State = "Respawn"
            goToPos(data.player.Position, ent, data)
            REVEL.FadeOut(29)
            return
            --    end
        end

        if not REVEL.includes(revel.virgil.busyStates, data.State) then -- action select
            revel.virgil.chooseState(ent, spr, data)
        end

        data.prevTarg = targ
        if path then data.prevPathLength = #path end
    end, REVEL.ENT.VIRGIL.variant)

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, ent)
        if ent.Variant == REVEL.ENT.VIRGIL_W.variant then
            local spr, data = ent:GetSprite(), ent:GetData()

            if not IsAnimOn(spr, "Happy") then
                for i, v in ipairs(REVEL.players) do
                    if v.Position:Distance(ent.Position) < v.Size + ent.Size then
                        REVEL.sfx:Play(SoundEffect.SOUND_THUMBSUP)
                        spr:Play("Happy", true)
                        data.p = v
                    end
                end
            elseif spr:IsFinished("Happy") then
                --      if not data.spawned then
                revel.data.run.tempVirgilThisFloor = false
                revel.data.run.virgilTemp[REVEL.GetPlayerID(data.p)] = 1

                --        local fam = REVEL.ENT.VIRGIL:spawn(ent.Position, ent.Velocity, data.p)
                --        fam:GetData().startPos = ent.Position

                data.p:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
                data.p:EvaluateItems()

                --        data.spawned = true
                --      else

                --        local virgils = Isaac.FindByType(3, REVEL.ENT.VIRGIL.variant, -1, true)
                --        for i,v in ipairs(virgils) do
                --          v.Position = ent.Position
                --          ent:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
                ent:Remove()
                --        end
                --      end
            end
        end
    end)

    function revel.virgil.chooseState(ent, spr, data)
        -- if there are bombs and targetable (tinted/ladder) rocks, drag bombs to rocks
        -- also, try to swat nearby troll bombs away
        local stage = REVEL.level:GetStage()

        if #REVEL.roomBombdrops ~= 0 then
            local badbombs = {}
            for i, v in ipairs(REVEL.roomBombdrops) do
                if (v.Variant == BombVariant.BOMB_TROLL or v.Variant ==
                    BombVariant.BOMB_SUPERTROLL) and
                    v.Position:Distance(data.player.Position) < 150 and
                    not v:GetData().swatted then
                    table.insert(badbombs, v)
                end
            end

            if #badbombs ~= 0 then
                data.swatBomb = badbombs[math.random(#badbombs)]
                goToEnt(data.swatBomb, ent, data, 6)
                data.State = "Swat_Bomb"
                return
            end
        end

        -- Throw rocks/bombs at secret and tinted rocks
        if (REVEL.room:IsClear() or data.player:GetHearts() +
            data.player:GetSoulHearts() < 3) and #revel.virgil.trocks ~= 0 and
            data.tRockCooldown == 0 then
            revel.virgil.trocks = getGoodSecretRocks() -- update rock in case some got destroyed
            if #revel.virgil.trocks ~= 0 then -- if there are still some
                local i = math.random(#revel.virgil.trocks)
                data.rockTarget = revel.virgil.trocks[i]

                revel.data.run.virgilTargetedRocks[tostring(
                    REVEL.room:GetDecorationSeed() *
                        data.rockTarget:GetGridIndex())] = true

                if data.player:GetNumBombs() == 0 and revel.data.run.virgilBombs >
                    0 then -- throw bombs
                    revel.data.run.virgilBombs = revel.data.run.virgilBombs - 1
                    data.State = "Throw_Bomb"
                else
                    data.State = "Throw_Rock"
                end
                goToPos(data.rockTarget.Position, ent, data, nil)
                return
            end
        end

        -- Throw rocks at enemies
        if #REVEL.roomEnemies ~= 0 and data.rockCooldown == 0 then
            local enemies = REVEL.GetFilteredEntityList(REVEL.roomEnemies,
                                                        revel.virgil
                                                            .rockEnemyBlacklist,
                                                        false, true, true, true)
            if #enemies ~= 0 then
                local targ = enemies[math.random(#enemies)]
                if targ.Position:DistanceSquared(ent.Position) < 25600 then -- 160^2, aka 4 tiles
                    playExtraAnim("ThrowRock", nil, ent, spr, data)
                else
                    goToEnt(targ, ent, data)
                end
                data.State = "Throw_Rock_Enemy"
                data.evadeEnemy = targ
                return
            end
        end

        local customDoors = StageAPI.GetCustomGrids(nil, "CustomDoor")
        local doorPos

        -- if not already visited and nothing else to do, point to secret floor entrance
        if data.State ~= "Point_Secret" and revel.virgil.stageToRoomType[stage] and
            REVEL.room:IsClear() and
            not StageAPI.InNewStage() then
            local rng = REVEL.RNG()
            rng:SetSeed(math.random(10000), 0)
            local targetId = REVEL.level:QueryRoomTypeIndex(revel.virgil
                                                                .stageToRoomType[stage],
                                                            true, rng:GetRNG())
            if targetId ~= REVEL.level:GetCurrentRoomIndex() then
                local i, door = REVEL.FindDoorToIdx(targetId, false)

                if door then doorPos = door.Position end
            elseif revel.virgil.stageToRoomType[stage] ==
                StageAPI.GetCurrentRoomType() and #customDoors ~= 0 then
                local door

                for i, v in ipairs(customDoors) do
                    if v.PersistentData.DoorDataName ==
                        revel.virgil.stageToDoorName[stage] then
                        door = v
                        break
                    end
                end

                doorPos = REVEL.room:GetGridPosition(door.Index)
            end
        elseif data.State ~= "Point_Secret" and
            (StageAPI.InNewStage() or not revel.virgil.stageToRoomType[stage]) and
            REVEL.room:IsClear() then
            local rooms = REVEL.level:GetRooms()
            local bossId =
                rooms:Get(REVEL.level:GetLastBossRoomListIndex()).SafeGridIndex
            if bossId ~= REVEL.level:GetCurrentRoomIndex() then
                local i, door = REVEL.FindDoorToIdx(bossId, false)
                if door then doorPos = door.Position end
            elseif revel.virgil.revelStageToDoorName[StageAPI.GetCurrentStageDisplayName()] and
                #customDoors ~= 0 then
                local door

                for i, v in ipairs(customDoors) do
                    if v.PersistentData.DoorDataName ==
                        revel.virgil.revelStageToDoorName[StageAPI.GetCurrentStageDisplayName()] then
                        door = v
                        break
                    end
                end

                doorPos = REVEL.room:GetGridPosition(door.Index)
            end
        end

        if doorPos then
            data.doorPosX = doorPos.X
            if doorPos:Distance(ent.Position) > 80 then
                goToPos(doorPos, ent, data, data.speed, 80)
            else
                goToPos(doorPos +
                            (doorPos - REVEL.room:GetCenterPos()):Resized(80),
                        ent, data, data.speed)
            end

            data.State = "Point_Secret"
        end

        -- if REVEL.IsRevelEntrance() and REVEL.room:GetFrameCount() == 5 then
        --     goToPos(REVEL.room:GetCenterPos() + Vector(60, 30), ent, data)
        --     data.State = "Point_Trapdoor"
        -- end
    end

    revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        revel.data.run.virgilBombs = 3
        revel.data.run.virgilTargetedRocks = {}
        revel.data.run.tempVirgilThisFloor = false

        for i, p in ipairs(REVEL.players) do
            revel.data.run.virgilTemp[i] = 0
            p:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            p:EvaluateItems()
        end

        if math.random() < revel.virgil.companionChance and REVEL.IsRevelStage() and
            not REVEL.ITEM.VIRGIL:OnePlayerHasCollectible() then
            local ent = REVEL.ENT.VIRGIL_W:spawn(
                            REVEL.room:GetTopLeftPos() + Vector(92, 76),
                            Vector.Zero, nil)
            ent:GetSprite():Play("Idle", true)

            revel.data.run.tempVirgilThisFloor = true
        end
    end)

    -- if hit is true, then don't make it pass thru enemies and don't do the not falling stuff
    function revel.virgil.throwRock(ent, pos, hit, tinted, speedMult)
        -- memo:Spawned with height: -23, accel can be approximated to 0.6 but will be forced to 0.9 as it's unreliable
        local length = (pos - ent.Position):Length()
        local speed
        if hit then
            speed = speedMult
        else
            speed = math.min(10, math.max(1, length / 3.2)) * (speedMult or 1)
        end

        local g = 0.8
        local rock = Isaac.Spawn(2, TearVariant.TOOTH, 0, ent.Position,
                                 (pos - ent.Position) * (speed / length), ent):ToTear()

        local spr = rock:GetSprite()

        if tinted then
            spr.Color = Color(130 / 255, 130 / 255, 180 / 255, 1,
                              conv255ToFloat(0, 0, 0))
        else
            spr.Color = Color(130 / 255, 110 / 255, 110 / 255, 1,
                              conv255ToFloat(0, 0, 0))
        end
        spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
        spr:LoadGraphics()

        local rockSpr = Sprite()
        rockSpr:Load("gfx/familiar/revelcommon/virgil.anm2", true)
        if tinted then
            rockSpr:Play("RockTinted", true)
        else
            rockSpr:Play("Rock", true)
        end

        rock:GetData().rockSpr = rockSpr

        rock.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        if not hit then
            rock.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

            local k = ent.Position:Distance(pos) / speed
            rock.FallingSpeed = 23 / k - g * 0.5 * k -- to make it land in the right spot
            rock:GetData().targetPos = pos
            rock:GetData().g = g
            rock:GetData().speed0 = rock.FallingSpeed
        else
            rock.FallingSpeed = -5
            rock.CollisionDamage = 1
        end
        table.insert(revel.virgil.thrownRocks, rock)

        rock:GetData().virgil = ent
        REVEL.sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)
        return rock
    end

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        for i, rock in ripairs(revel.virgil.thrownRocks) do
            if not REVEL.room:IsPositionInRoom(rock.Position, 0) then
                rock:Die()
            end

            --      REVEL.DebugToString({rock.Height, rock.FallingSpeed})
            if not rock:IsDead() and rock:Exists() then
                --      data.rockSpr:Update() --not working properly (:GetFrame() indicates it should, but visuals don't change) for some reason
                local data = rock:GetData()

                if data.g then
                    local targ = data.targetPos
                    rock.FallingSpeed = data.speed0 + data.g * rock.FrameCount
                    rock.FallingAcceleration = data.g -- to fix a weird position error that would happen on death if this wasn't changed too
                end
                data.rockSpr.Rotation = data.rockSpr.Rotation + 26
            else
                revel.virgil.thrownRocks[i] = nil
            end
        end
    end)

    revel:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, function(_, e, renderOffset)
        local data = e:GetData()

        if data.rockSpr then
            local pos = Isaac.WorldToScreen(e.Position + Vector(0, e.Height))
            data.rockSpr:Render(pos + e.SpriteOffset + renderOffset - REVEL.room:GetRenderScrollOffset())
        end
    end)

    StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(e, dmg, flag, src)
        local virgil = e:GetData().virgil
        if virgil then
            if e:GetSprite():IsPlaying("Appear") then return false end

            local data = virgil:GetData()

            local hp = e:ToPlayer():GetHearts() + e:ToPlayer():GetSoulHearts()

            if src.Entity and
                not REVEL.includes(revel.virgil.busyStates, data.State) and
                not (e:ToPlayer():GetExtraLives() == 0 and hp - dmg <= 0) then
                local targs = Isaac.FindInRadius(src.Entity.Position, 1, -1)
                local targ = targs[1]
                --      REVEL.DebugToString({"Attacked by", targ})
                if targ and targ:IsActiveEnemy() then -- closest entity
                    data.State = "AngryPointing"

                    data.pointingAt = targ
                    goToEnt(targ, virgil, data)
                end
            end
        end
    end, 1)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src)
        if src.Entity and src.Entity.SpawnerType == REVEL.ENT.VIRGIL.id and
            src.Entity.SpawnerVariant == REVEL.ENT.VIRGIL.variant then
            local ent = Isaac.FindInRadius(src.Entity.Position, 1, -1)[1]
            local virgil = ent:GetData().virgil
            if virgil then
                e:GetData().pissedOff = true
                virgil:GetData().evadeEnemy = e -- in case it hit a different enemy
                return false
            end
        end
    end)
end
