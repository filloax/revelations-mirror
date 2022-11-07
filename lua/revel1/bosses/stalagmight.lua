REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.StalagmightBalance = {
    Champions = {Frost = "Default"},
    Spritesheet = {
        Default = "",
        Frost = "gfx/bosses/revel1/stalagmight/stalagmight_champion.png",
    },
    SpikeSpritesheet = {
        Default = "",
        Frost = "gfx/bosses/revel1/stalagmight/stalagmight_champion_spikes.png",
    },
    StalactiteSpritesheet = {
        Default = "",
        Frost = "gfx/bosses/revel1/stalagmight/stalagmight_champion_stalactites.png",
    },
    GibsSpritesheet = {
        Default = "gfx/effects/revel1/ice_gibs.png",
        Frost = "gfx/effects/revel1/ice_gibs_dark.png",
    },
    IceHazardBotSpritesheet = {
        Default = "",
        -- Frost = "gfx/bosses/revel1/stalagmight/dark_ice_hazard_overlay_bottom.png",
    },
    IceHazardEnemiesSpritesheet = {
        Default = "",
        -- Frost = "gfx/bosses/revel1/stalagmight/dark_ice_hazard_enemies.png",
    },
    AttackCycleDefaultCooldownBetween = 0,
    AttackCycleDefaultCooldown = 40,

    -- DebugCycle = {
    --     {
    --         Attacks = {
    --             Summon = 1,
    --         }
    --     },
    --     {
    --         ChangeSpikes = true,
    --         RaiseWithHoles = 1,
    --         Attacks = {
    --             FreezeBlow = 1,
    --         },
    --     }
    -- },
    StartCycle = {
        Default = {
            {
                ChangeSpikes = false,
                Attacks = {
                    TripleShot = 1,
                },
                Repeat = {
                    Min = 1,
                    Max = 2,
                },
            },
            {
                Attacks = {
                    Summon = 1,
                },
                CooldownAfter = 0,
            },
            {
                ChangeSpikes = true,
                Attacks = {
                    Blow = 1,
                },
            },
            {
                ChangeSpikes = true,
                Attacks = {
                    IceBreaker = 1,
                },
            },
        },
        Frost = {
            {
                ChangeSpikes = false,
                Attacks = {
                    TripleShot = 1,
                },
                Repeat = 2,
            },
            {
                Attacks = {
                    Summon = 1,
                },
                CooldownAfter = 0,
            },
            {
                ChangeSpikes = true,
                RaiseWithHoles = 1,
                Attacks = {
                    FreezeBlow = 1,
                },
            },
            {
                Attacks = {
                    Summon = 1,
                },
                CooldownAfter = 60,
            },
            {
                ChangeSpikes = true,
                Attacks = {
                    IceBreaker = 1,
                },
            },
        },
    },
    MidHealthCycle = {
        Default = {
            {
                ChangeSpikes = false,
                Attacks = {
                    Rumble = 1,
                }
            },
        },
    },
    LowHealthCycle = {
        Default = {
            {
                Attacks = {
                    ChargeBreak = 1,
                }
            },
        },
    },
    UnfrozenCycle = {
        Default = {
            {
                Attacks = {
                    UnfrozenBlow = 1,
                },
                CooldownAfter = {Min = 80, Max = 180},
            },
        }
    },

    HealthCycleTrigger = 35, --health percent
    IceBreakHealthTrigger = {
        Default = 15,
        Frost = 25,
    },

    AttackToStateAnim = {
        TripleShot = {State = "TripleShot", Anim = "TripleShot", OverlayAnim = "Body"},
        Summon = {State = "Summon", Anim = "Summon"},
        Blow = {State = "Blow", OverlayAnim = "Body"},
        IceBreaker = {State = "IceBreaker", Anim = "Suck Start", OverlayAnim = "SpikesOn"},
        Rumble = {State = "Rumble", Anim = "Charge"},
        UnfrozenBlow = {State = "UnfrozenBlow", Anim = "Blow Start"},
        FreezeBlow = {State = "FreezeBlow", OverlayAnim = "Body"},
    },

    AttackNames = {
        TripleShot = "Triple Shot",
        Summon = "",
        Blow = "Blow",
        IceBreaker = "Ice Breaker",
        Rumble = "Rumble",
        UnfrozenBlow = "Blow",
        FreezeBlow = "Freeze Blow",
    },

    TripleShot = {
        Default = {
            Spread = 30,
            Speed = 10,
            Num = 3,
        },
        Frost = {
            Spread = 30,
            Speed = 10,
            Num = 4,
        },
    },

    Summon = {
        Default = {
            MaxNumForFirst = 0,
            ExtraNum = {Min = 0, Max = 1},
            InstaBreak = false,
            DelayBetween = 10,
            CreepRadius = 80,
        },
        Frost = {
            MaxNumForFirst = 1,
            ExtraNum = {Min = 0, Max = 1},
            DelayBetween = 10,
            SpawnIceHazard = true,
            IceHazardVariants = {REVEL.ENT.ICE_HAZARD_GAPER, REVEL.ENT.ICE_HAZARD_HORF},
            MaxSpawnedEnemies = 2,
        },
    },

    Blow = {
        Duration = {Min = 120, Max = 200},
        PlayerBlowStrengthIce = 2,
        PlayerBlowStrength = 0.4,
        BlowStartDelay = 60,
    },

    FreezeBlow = {
        Duration = 60,
        BlowStartDelay = 60,
    },

    IceBreaker = {
        Default = {
            Delay = 40,
            PlayerSuckStrengthIce = 0.75,
            PlayerSuckStrength = 0.34,
            ProjSuckStrength = 0.55,
            RandomProjAngle = false,
            SpikesFreezeRadius = -1,
        },
        Frost = {
            Delay = 25,
            PlayerSuckStrengthIce = 0.75,
            PlayerSuckStrength = 0.34,
            ProjSuckStrength = 0.6,
            SpikesFreezeRadius = 60,
            SpikesFreezeAuraTime = 40,
            RandomProjAngle = true,
        },
    },

    SpikeProjectileSpeed = {
        Default = 8,
        Frost = 10,
    },

    Rumble = {
        Default = {
            Speed = 6,
            BreakingSpeed = 12,
            StalShotNum = 0,
            ImpactSlow = 0.6,
            AccelMult = 1.03,
            StalShotSpeed = 10.5,
            MaxStalactites = 4,
            SpawnCooldown = 25,
            AlternateSpawn = true,
        },
        Frost = {
            Speed = 6,
            MaxStalactites = 4,
            BreakingSpeed = 12,
            StalShotNum = 0,
            ImpactSlow = 0.6,
            AccelMult = 1.03,
            IceHazardVariants = {REVEL.ENT.ICE_HAZARD_GAPER, REVEL.ENT.ICE_HAZARD_BROTHER, REVEL.ENT.ICE_HAZARD_HORF, REVEL.ENT.ICE_HAZARD_CLOTTY},
            MaxSpawnedEnemies = 2,
            DoMelt = true,
            MeltDuration = 90,
            SpawnCooldown = 35,
            AlternateSpawn = false,
            SpawnIceHazard = true,
            NumChillos = 1,
        },
    },

    UnfrozenDefaultAccel = 0.75,
    UnfrozenFriction = 0.9,
    UnfrozenWalkAnims = {Horizontal = "WalkHori", Vertical = "WalkVert"},
    MeltHeadOffset = Vector(0, 18),
    MeltHeadOffsetFrame = 128,

    UnfrozenBlow = {
        Default = {
            WalkAccel = 0.6,
            Duration = {Min = 180, Max = 220},
            PlayerBlowStrengthIce = 2,
            PlayerBlowStrength = 0.5,
            ProjBlowStrength = 0.1,
            TearBlowStrength = 0.4,
            ProjShootRate = 12,
            ProjShootSpeed = 3,
            ProjAccel = 0.6,
        },
        Frost = {
            WalkAccel = 0.5,
            Duration = {Min = 180, Max = 220},
            PlayerBlowStrengthIce = 1.5,
            PlayerBlowStrength = 0.3,
            ProjBlowStrength = 0.1,
            TearBlowStrength = 0.45,
            ProjShootRate = 15,
            ProjShootSpeed = 3,
            ProjAccel = 0.5,
            ChilloBlowStrength = 0.4,
        },
    },

    SpikeRaiseDelay = 1, --delay between raising each spike
    SpikesBulletNum = {
        Default = 5,
        Frost = 3,
    },
}

local function GetEntitiesInRadius(position, radius, ents)
    local out = {}
    for _, ent in ipairs(ents) do
        if ent.Position:Distance(position) <= radius then
            out[#out + 1] = ent
        end
    end
    return out
end

REVEL.StalagmightChampionColor = Color(100 / 255, 100 / 255, 200 / 255, 1,conv255ToFloat( 0, 0, 0))

local function canSpawnIceHazard(npc, data, stateTable)
    return (Isaac.CountEntities(npc, EntityType.ENTITY_NULL, -1, -1) or 0) < stateTable.MaxSpawnedEnemies
end

local function getStalactitePos(npc, stateTable)
    local data, target = npc:GetData(), npc:GetPlayerTarget()
    local prevStalacs = REVEL.ENT.STALACTITE:getInRoom()

    local pos, good = nil, true
    local attempts = 0

    repeat
        attempts = attempts + 1
        local off = RandomVector() * math.random(250, 300)
        pos = target.Position
        if not REVEL.room:IsPositionInRoom(pos + off, 0) then
            pos = pos - off
        else
            pos = pos + off
        end

        pos = REVEL.room:GetClampedPosition(pos, 80)

        good = true
        for _, stal in pairs(prevStalacs) do
            local index1, index2 = REVEL.room:GetGridIndex(stal.Position), REVEL.room:GetGridIndex(pos)
            if (attempts > 15 and index1 == index2) or pos:DistanceSquared(stal.Position) < (80) ^ 2 then
                good = false
                break
            end
        end
    until good or attempts > 99

    return pos, good
end

local function spawnStalactite(npc, stateTable)
    local data, target = npc:GetData(), npc:GetPlayerTarget()

    local stalactrites = REVEL.ENT.STALACTRITE:getInRoom()

    if #stalactrites > 0 then
        REVEL.randomFrom(stalactrites):GetData().StalactriteTriggered = true
        return
    end

    if stateTable.SpawnIceHazard and not canSpawnIceHazard(npc, data, stateTable) then return end

    local pos = data.NextStalactitePos
    local good = not not data.NextStalactitePos

    if not pos then
        pos, good = getStalactitePos(npc, stateTable)
    end

    data.NextStalactitePos = nil

    if good then
        local stalac
        if stateTable.SpawnIceHazard then
            local hazard = REVEL.randomFrom(stateTable.IceHazardVariants)
            local entity = hazard:spawn(pos, Vector.Zero, npc)
            entity.SpawnerEntity = npc

            if data.bal.IceHazardBotSpritesheet ~= "" then
                entity:GetSprite():ReplaceSpritesheet(0, data.bal.IceHazardBotSpritesheet)
                entity:GetSprite():ReplaceSpritesheet(1, data.bal.IceHazardEnemiesSpritesheet)
                entity:GetSprite():LoadGraphics()
            end
            if data.IsChampion then
                -- entity:GetData().DarkIce = true
            end

            REVEL.SetEntityAirMovement(entity, {ZPosition = 150, ZVelocity = -5, Gravity = 0.25})
            REVEL.UpdateEntityAirMovement(entity)
        else
            if stateTable.InstaBreak then
                stalac = REVEL.ENT.STALACTITE_SMALL:spawn(pos, Vector.Zero, npc)
            else
                stalac = REVEL.ENT.STALACTITE:spawn(pos, Vector.Zero, npc)
            end
            
            stalac.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            local stalacSprite, stalacData = stalac:GetSprite(), stalac:GetData()

            if data.NextStalactiteTarget then
                stalacData.spawnedTarget = true
                stalacData.target = data.NextStalactiteTarget
                data.NextStalactiteTarget:GetData().noRequireStalactite = nil
                data.NextStalactiteTarget:GetData().Stalactite = stalac   

                data.NextStalactiteTarget = nil     
            end

            if data.bal.SpikeSpritesheet ~= "" then
                stalacSprite:ReplaceSpritesheet(0, data.bal.StalactiteSpritesheet)
                stalacSprite:ReplaceSpritesheet(2, data.bal.GibsSpritesheet)
                stalacSprite:ReplaceSpritesheet(3, data.bal.GibsSpritesheet)
                stalacSprite:LoadGraphics()
                stalacData.DontShootStart = true
                stalacData.IsDarkIce = true
            end

            stalacData.StalagmightSpawned = true
            -- stalacData.stretch = true
            stalacData.StalagmightCreepRadius = data.bal.Summon.CreepRadius
        end
    end
end

local function SpawnPhaseTwo(npc)
    local data = npc:GetData()

    for _, creep in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_SLIPPERY_BROWN, -1, false, false)) do
        creep:ToEffect():SetTimeout(5)
    end

    for _, stal in ipairs(Isaac.FindByType(REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1, false, false)) do
        stal:GetData().DontShoot = true
        stal:Kill()
    end

    local iceVariant = REVEL.IceGibType.DEFAULT
    if data.IsChampion then
        iceVariant = REVEL.IceGibType.DARK
    end
    for i=1, 18 do
        REVEL.SpawnIceRockGib(npc.Position, RandomVector():Resized(math.random(1, 9)), npc, iceVariant, true)
    end
    local phase2 = Isaac.Spawn(REVEL.ENT.STALAGMITE.id, REVEL.ENT.STALAGMITE_2.variant, 0, npc.Position, Vector.Zero, npc)
    phase2.MaxHitPoints = npc.MaxHitPoints
    phase2.HitPoints = npc.HitPoints

    data.SpikesRaised = false
    REVEL.UpdateStalagmightSpikes(npc, data.Spikes)

    local pdata = phase2:GetData()
    pdata.IsChampion = data.IsChampion
    phase2:GetSprite():Play("AppearAnim")
    pdata.bal = data.bal
    pdata.State = "DefaultFollow"
    pdata.AttackCooldown = 60
    pdata.Spikes = data.Spikes

    npc:Remove()
end

local function initSpike(npc, data, spike)
    spike:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    spike:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_TARGET, EntityFlag.FLAG_NO_STATUS_EFFECTS))


    local sdata, ssprite = spike:GetData(), spike:GetSprite()
    sdata.Init = true

    if data.bal.SpikeSpritesheet ~= "" then
        ssprite:ReplaceSpritesheet(0, data.bal.SpikeSpritesheet)
        ssprite:LoadGraphics()
        sdata.IsDarkIce = true
    end

    sdata.randomnum = tostring(math.random(1,3))
    sdata.IsStalagmiteSpike = true
    spike.SpawnerType = npc.Type
    sdata.LockPosition = spike.Position

    local room = StageAPI.GetCurrentRoom()
    if room and room.Metadata:Has{Index = REVEL.room:GetGridIndex(spike.Position), Name = "AlwaysOnStalagSpike"} then
        sdata.AlwaysOn = true
    end

    if sdata.AlwaysOn then
        ssprite:Play("Summon" .. sdata.randomnum, true)
        sdata.Raised = true
    else
        spike.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        spike.Visible = false
    end
end

local function stalagmight_NpcUpdate(_, npc)
    if not (REVEL.ENT.STALAGMITE:isEnt(npc) or REVEL.ENT.STALAGMITE_2:isEnt(npc)) then return end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    --Frozen
    if REVEL.ENT.STALAGMITE:isEnt(npc) then
        local maxMoveSpeed

        if not data.Init then
            data.IsChampion = REVEL.IsChampion(npc)
            REVEL.SetScaledBossHP(npc)

            if data.IsChampion then
                data.bal = REVEL.GetBossBalance(REVEL.StalagmightBalance, "Frost")
            else
                -- if REVEL.IsRuthless() then
                --     data.bal = REVEL.GetBossBalance(REVEL.StalagmightBalance, "Ruthless")
                -- else
                    data.bal = REVEL.GetBossBalance(REVEL.StalagmightBalance, "Default")
                -- end
            end

            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

            if data.bal.Spritesheet ~= "" then
                sprite:ReplaceSpritesheet(0, data.bal.Spritesheet)
                sprite:ReplaceSpritesheet(3, data.bal.Spritesheet)
                sprite:ReplaceSpritesheet(4, data.bal.Spritesheet)
                sprite:LoadGraphics()
            end

            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

            if REVEL.room:GetFrameCount() > 10 and not data.NoReposition then
                npc.Position = REVEL.room:GetGridPosition(37)
            end

            local hasPlayerStart

            if StageAPI.GetCurrentRoom() and StageAPI.GetCurrentRoom().Metadata:Has{Name = "SetPlayerPosition"} then
                hasPlayerStart = true
            end

            if not hasPlayerStart then
                local center = REVEL.room:GetCenterPos()
                local br = REVEL.room:GetBottomRightPos()
                local basePlayerPos = Vector(center.X, REVEL.Lerp(center.Y, br.Y, 0.66))
                for _, player in ipairs(REVEL.players) do
                    player.Position = Isaac.GetFreeNearPosition(basePlayerPos, 20)
                end
            end

            sprite:Play("AppearAnim", true)
            data.State = "Appear"
            data.AttackCooldown = data.bal.AttackCycleDefaultCooldown

            npc.Mass = 0
            data.LockPosition = npc.Position

            data.Spikes = {}

            local roomSpikes = REVEL.ENT.STALAGMITE_SPIKE:getInRoom()

            if #roomSpikes == 0 then
                for i = 0, REVEL.room:GetGridSize() do
                    local pos = REVEL.room:GetGridPosition(i)
                    if REVEL.room:IsPositionInRoom(pos, 0) and (REVEL.room:GetClampedPosition(pos, 32).X ~= pos.X or REVEL.room:GetClampedPosition(pos, 32).Y ~= pos.Y) then
                        local spike = Isaac.Spawn(REVEL.ENT.STALAGMITE_SPIKE.id, REVEL.ENT.STALAGMITE_SPIKE.variant, 0, pos, Vector.Zero, npc)
                        data.Spikes[#data.Spikes + 1] = spike

                        initSpike(npc, data, spike)
                    end
                end
            else
                for _, spike in pairs(roomSpikes) do
                    initSpike(npc, data, spike)
                end

                data.Spikes = roomSpikes
            end

            data.Init = true
        end

        REVEL.ApplyKnockbackImmunity(npc)

        if npc.HitPoints < npc.MaxHitPoints * 0.75 * data.bal.IceBreakHealthTrigger / 100 and not (data.State == "Rumble" or data.State == "Break") then
            data.State = "Break"
            sprite:Play("Break", true)
        end

        if data.State == "Appear" then
            if sprite:IsEventTriggered("Shockwaves") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                npc.Mass = 9999
                for num=1, 4 do
                    local off = Vector.FromAngle(num * 90 + 45)
                    REVEL.SpawnCustomShockwave(npc.Position + off * 25, off * 6, "gfx/effects/revel1/glacier_shockwave.png", 20, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
                end
                REVEL.game:ShakeScreen(15)
                SFXManager():Play(48, 0.9, 0, false, 1)

                --Drop down stalactrites
            end

            if sprite:IsFinished("AppearAnim") then
                sprite:Play("Idle", true)
                data.State = "Idle"
            end
        elseif data.State == "Idle" then
            if sprite:IsFinished("Suck Final") or sprite:IsFinished("Blow End") then
                sprite:Play("Idle", true)
                sprite:RemoveOverlay()
            end

            if data.AttackCooldown then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            else
                local useCycle = (npc.HitPoints <= npc.MaxHitPoints * data.bal.HealthCycleTrigger / 100) and data.bal.MidHealthCycle or data.bal.StartCycle

                if data.bal.DebugCycle and #data.bal.DebugCycle > 0 then
                    useCycle = data.bal.DebugCycle
                end

                if data.PrevCycle ~= useCycle then data.Cycle = nil end

                data.PrevCycle = useCycle

                local curCycle, isAttacking, attack, cooldown, changedPhase = REVEL.ManageAttackCycle(data, data.bal, useCycle)
                if isAttacking then
                    REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                    if data.bal.AttackToStateAnim[attack] then
                        data.State = data.bal.AttackToStateAnim[attack].State
                        if data.bal.AttackToStateAnim[attack].Anim then
                            sprite:Play(data.bal.AttackToStateAnim[attack].Anim, true)
                        end
                        if data.bal.AttackToStateAnim[attack].OverlayAnim then
                            sprite:PlayOverlay(data.bal.AttackToStateAnim[attack].OverlayAnim, true)
                            sprite:SetOverlayRenderPriority(true)
                        else
                            sprite:RemoveOverlay()
                        end
                    end

                    data.AttackCooldown = cooldown

                    if curCycle.ChangeSpikes ~= nil then
                        data.SpikesRaised = curCycle.ChangeSpikes
                    end
                    if curCycle.RaiseWithHoles then
                        data.SpikesRaiseHolesNum = REVEL.GetFromMinMax(curCycle.RaiseWithHoles)
                    end
                end
            end

        elseif data.State == "TripleShot" then
            if sprite:IsEventTriggered("Triple Shot") then
                REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GHOST_SHOOT, 1, 0, false, 1)
                local angle = data.bal.TripleShot.Spread
                local angleStep = data.bal.TripleShot.Spread / (data.bal.TripleShot.Num - 1)
                for i = -angle / 2, angle / 2, angleStep do
                    local pro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, (target.Position - npc.Position):Resized(data.bal.TripleShot.Speed):Rotated(i), npc):ToProjectile()
                    pro.FallingSpeed = -3
                    pro.FallingAccel = 0.05
                end
            end

            if sprite:IsFinished("TripleShot") then
                sprite:Play("Idle", true)
                sprite:RemoveOverlay()
                data.State = "Idle"
            end

        elseif data.State == "Summon" then
            if sprite:IsEventTriggered("Summon") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_5, 1, 0, false, 1)
                local numStalactites = Isaac.CountEntities(nil, REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1) or 0
                local toSpawn = REVEL.Round(REVEL.GetFromMinMax(data.bal.Summon.ExtraNum))
                if numStalactites <= data.bal.Summon.MaxNumForFirst then
                    toSpawn = toSpawn + 1
                end

                -- REVEL.DebugToConsole(toSpawn, numStalactites, data.bal.Summon.MaxNumForFirst)

                if toSpawn > 0 then
                    spawnStalactite(npc, data.bal.Summon)

                    for i = 2, toSpawn do
                        REVEL.DelayFunction(data.bal.Summon.DelayBetween, spawnStalactite, {npc, data.bal.Summon})
                    end
                end
            end

            if (data.bal.Summon.SpawnIceHazard and not canSpawnIceHazard(npc, data, data.bal.Summon) and not sprite:WasEventTriggered("Summon")) or sprite:IsFinished("Summon") then
                sprite:Play("Idle", true)
                data.State = "Idle"
            end

        elseif data.State == "Blow" then
            if npc.HitPoints <= npc.MaxHitPoints * data.bal.HealthCycleTrigger / 100 then
                sprite:Play("Blow End", true)
                REVEL.DisableWindSound(npc)
                data.State = "Idle"
                data.AttackCooldown = 5
            end

            if data.StateFrame >= data.bal.Blow.BlowStartDelay and not (IsAnimOn(sprite, "Blow Start") or IsAnimOn(sprite, "Blow Loop") or IsAnimOn(sprite, "Blow End")) then
                sprite:Play("Blow Start", true)
            end

            if sprite:IsFinished("Blow Start") then
                sprite:Play("Blow Loop", true)
                data.AttackTimer = REVEL.GetFromMinMax(data.bal.Blow.Duration)
                REVEL.EnableWindSound(npc)
            end

            if sprite:IsPlaying("Blow Loop") then
                if data.AttackTimer then
                    data.AttackTimer = data.AttackTimer - 1
                    if data.AttackTimer <= 0 then
                        data.AttackTimer = nil
                        sprite:Play("Blow End", true)
                        REVEL.DisableWindSound(npc)
                        data.State = "Idle"
                    end
                end

                local curRoom = StageAPI.GetCurrentRoom()
                for _, player in ipairs(REVEL.players) do
                    local addVel = (player.Position - npc.Position):Normalized()
                    if player:GetDamageCooldown() == 0 then
                        if REVEL.Glacier.CheckIce(player, curRoom) then
                            player.Velocity = player.Velocity + addVel * data.bal.Blow.PlayerBlowStrengthIce
                        else
                            player.Velocity = player.Velocity + addVel * data.bal.Blow.PlayerBlowStrength
                        end
                    end
                end

                if math.random(2) == 1 then
                    local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, npc.Position, Vector(math.random() * 16 - 8, math.random() * 16 - 8), npc)
                    --snowp.Position = npc.Position + snowp.Velocity * -30
                    snowp:GetSprite():Play("Fade", true)
                    snowp:GetSprite().Offset = Vector(0,-25)
                    snowp:GetData().Rot = math.random() * 20 - 10
                end
            end

        elseif data.State == "IceBreaker" then
            if npc.HitPoints <= npc.MaxHitPoints * data.bal.HealthCycleTrigger / 100 then
                sprite:Play("Suck Final", true)
                sprite:PlayOverlay("SpikesOff", true)
                REVEL.DisableWindSound(npc)
                data.State = "Idle"
                data.AttackCooldown = 5
            end

            if not data.NotExplodedSpikes then
                data.NotExplodedSpikes = {}
                for i = 1, #data.Spikes do
                    local grId = REVEL.room:GetGridIndex(data.Spikes[i].Position)
                    if (grId < 21 or grId > 23) and not data.Spikes[i]:GetData().AlwaysOn and data.Spikes[i]:GetData().Raised then --exclude spikes behind stalag default pos
                        data.NotExplodedSpikes[i] = 1
                    end
                end
                data.NotExplodedSpikessNum = #data.Spikes
                data.SpikeCooldown = REVEL.GetFromMinMax(data.bal.IceBreaker.Delay)
            end

            if data.SpikeCooldown then
                data.SpikeCooldown = data.SpikeCooldown - 1
                if data.SpikeCooldown <= 0 then
                    data.SpikeCooldown = nil
                end
            else
                data.SpikeCooldown = REVEL.GetFromMinMax(data.bal.IceBreaker.Delay)

                if data.NotExplodedSpikessNum <= #data.Spikes / 2 then
                    data.NotExplodedSpikes = nil
                    sprite:Play("Suck Final", true)
                    sprite:PlayOverlay("SpikesOff", true)
                    data.State = "Idle"
                    REVEL.DisableWindSound(npc)
                else
                    local index = REVEL.WeightedRandom(data.NotExplodedSpikes)
                    local spike = data.Spikes[index]
                    data.NotExplodedSpikes[index] = nil
                    data.NotExplodedSpikessNum = data.NotExplodedSpikessNum - 1
                    spike:GetSprite():Play("Explode" .. spike:GetData().randomnum, true)
                    spike:GetData().UseFreezeAura = data.bal.IceBreaker.SpikesFreezeRadius > 0
                end
            end

            if sprite:IsFinished("Suck Start") then
                sprite:Play("Suck Loop", true)
            end

            if sprite:IsEventTriggered("Blow") then
                REVEL.EnableWindSound(npc, true)
            end

            --suck in player and bullets
            if sprite:WasEventTriggered("Blow") or sprite:IsPlaying("Suck Loop") then
                REVEL.DoGideonSuctionEffect(npc, Vector.Zero, Vector(0, -40), 0.4)
                
                local curRoom = StageAPI.GetCurrentRoom()
                for _, player in ipairs(REVEL.players) do
                    local addVel = (npc.Position - player.Position):Normalized()
                    if player:GetDamageCooldown() == 0 then
                        if REVEL.Glacier.CheckIce(player, curRoom) then
                            player.Velocity = player.Velocity + addVel * data.bal.IceBreaker.PlayerSuckStrengthIce
                        else
                            player.Velocity = player.Velocity + addVel * data.bal.IceBreaker.PlayerSuckStrength
                        end
                    end
                end
                for _, projectile in pairs(REVEL.roomProjectiles) do
                    if not projectile:GetData().HeldByAura then
                        projectile.Velocity = projectile.Velocity + (npc.Position - projectile.Position):Resized(data.bal.IceBreaker.ProjSuckStrength)
                    end
                end

                if math.random(2) == 1 then
                    local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, npc.Position, Vector(math.random() * 16 - 8, math.random() * 16 - 8), npc)
                    snowp.Position = npc.Position + snowp.Velocity * -30
                    snowp:GetSprite():Play("Appear", true)
                    snowp:GetSprite().Offset = Vector(0,-25)
                    snowp:GetData().Rot = math.random() * 20 - 10
                end
            end

        elseif data.State == "Rumble" then
            local player = npc:GetPlayerTarget()
            maxMoveSpeed = data.Breaking and data.bal.Rumble.BreakingSpeed or data.bal.Rumble.Speed

            if npc.HitPoints < npc.MaxHitPoints * data.bal.IceBreakHealthTrigger / 100 and not data.Breaking and not data.Melting then
                if data.bal.Rumble.DoMelt then
                    data.Melting = true
                    data.MeltCountdown = data.bal.Rumble.MeltDuration
                    local hs = Sprite()
                    hs:Load(sprite:GetFilename(), true)
                    if data.bal.Spritesheet ~= "" then
                        hs:ReplaceSpritesheet(0, data.bal.Spritesheet)
                        hs:ReplaceSpritesheet(3, data.bal.Spritesheet)
                        hs:ReplaceSpritesheet(4, data.bal.Spritesheet)
                    end
                    hs:Play("ChargeHead", true)
                    data.HeadSprite = hs
                else
                    data.Breaking = 1
                    sprite:Play("Charge", true)
                    data.Moving = false
                    data.LockPosition = npc.Position
                    data.NextStalactitePos = nil
                    if data.NextStalactiteTarget then
                        data.NextStalactiteTarget:Remove()
                        data.NextStalactiteTarget = nil    
                    end
                end
                sprite:RemoveOverlay()
            end

            if sprite:IsEventTriggered("Charge") then
                REVEL.game:ShakeScreen(11)
                data.Moving = true
                local vel = (player.Position - npc.Position):Resized(maxMoveSpeed)
                if math.abs(vel.X) < 2 then
                    vel = Vector(vel.X * 3, vel.Y):Resized(maxMoveSpeed)
                end
                npc.Velocity = vel
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_5, 1, 0, false, 1)
            end

            if sprite:IsFinished("Charge") then
                sprite:Play("ChargeHead", true)
                sprite:PlayOverlay("Body", true)
                sprite:SetOverlayRenderPriority(true)
            end

            if data.Melting then
                data.HeadSprite:Update()
                data.MeltCountdown = data.MeltCountdown - 1
                sprite:SetFrame("BodyMelt", math.ceil(128 - 128 * data.MeltCountdown / data.bal.Rumble.MeltDuration))
                if data.bal.Rumble.NumChillos > 0 then
                    for i = 1, data.bal.Rumble.NumChillos do
                        local targ = i * data.bal.Rumble.MeltDuration / (data.bal.Rumble.NumChillos + 1)
                        if data.MeltCountdown <= targ and data.MeltCountdown + 1 > targ then
                            local chillo = REVEL.ENT.CHILL_O_WISP:spawn(npc.Position, -npc.Velocity, npc)
                            chillo:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            REVEL.SpawnMeltEffect(npc.Position)
                        end
                    end
                end

                if data.MeltCountdown <= 0 then
                    REVEL.SpawnMeltEffect(npc.Position)
                    SpawnPhaseTwo(npc)
                    return
                end
            end

            local colliding = data.Moving and npc:CollidesWithGrid()

            if colliding then
                local numStalactites = Isaac.CountEntities(nil, REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1) or 0
                if not data.Breaking and numStalactites < data.bal.Rumble.MaxStalactites and not (data.CollidedWithGridTime and npc.FrameCount - data.CollidedWithGridTime < data.bal.Rumble.SpawnCooldown) then
                    if not data.bal.Rumble.AlternateSpawn or (data.bal.Rumble.AlternateSpawn and data.NextStalactitePos) then
                        spawnStalactite(npc, data.bal.Rumble)
                    else
                        local nextPos = getStalactitePos(npc, data.bal.Rumble)
                        if nextPos then
                            data.NextStalactitePos = nextPos
                            data.NextStalactiteTarget = REVEL.SpawnDecorationFromTable(nextPos, Vector.Zero, REVEL.StalactiteTargetDeco2)
                            data.NextStalactiteTarget:GetData().noRequireStalactite = true
                        end
                    end
                end

                REVEL.game:ShakeScreen(11)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                if not data.Breaking then
                    npc.Velocity = npc.Velocity:Resized(data.bal.Rumble.ImpactSlow * data.bal.Rumble.Speed)
                end
                data.CollidedWithGridTime = npc.FrameCount
                if data.Breaking and not sprite:IsPlaying("Break" .. (data.Breaking - 1)) then
                    sprite:Play("Break" .. data.Breaking, true)
                    sprite:RemoveOverlay()
                    data.Breaking = data.Breaking + 1
                end
            elseif not colliding then
                local l = npc.Velocity:Length()
                if not data.Breaking then
                    if l < 0.00001 then
                        npc.Velocity = Vector.FromAngle(math.random(0, 3) * 90 + 45) * maxMoveSpeed
                    elseif l < 1 then
                        npc.Velocity = npc.Velocity * (maxMoveSpeed * 0.5 / l)
                    else
                        npc.Velocity = npc.Velocity * data.bal.Rumble.AccelMult --accelerate in case of slowdown
                    end
                elseif l > 0.00001 then
                    npc.Velocity = npc.Velocity * (maxMoveSpeed / l)
                else
                    npc.Velocity = Vector.FromAngle(math.random(0, 3) * 90 + 45) * maxMoveSpeed
                end

                if l > 2 then
                    local stalactites = REVEL.ENT.STALACTITE:getInRoom()

                    local close = Isaac.FindInRadius(npc.Position, npc.Size + 80, EntityPartition.ENEMY)
                    for _, enemy in pairs(close) do
                        if enemy.Position:DistanceSquared(npc.Position) < (npc.Size + enemy.Size + 5) ^ 2 then
                            if REVEL.ENT.STALACTITE:isEnt(enemy) then
                                enemy:GetData().ShotNum = data.bal.Rumble.StalShotNum
                                -- enemy:GetData().StartAngle = math.random(360)
                                enemy:GetData().ShotSpeed = data.bal.Rumble.StalShotSpeed
                                enemy:Die()
                            elseif enemy.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
                                enemy.Velocity = enemy.Velocity + (enemy.Position - npc.Position):Resized(10)
                            elseif not enemy:IsBoss() then
                                enemy:TakeDamage(15, 0, EntityRef(npc), 0)
                            end
                        end
                    end
                end
            end

            if sprite:IsFinished("Break3") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 0.9+math.random()*0.1)
                data.NextStalactitePos = nil
                if data.NextStalactiteTarget then
                    data.NextStalactiteTarget:Remove()
                    data.NextStalactiteTarget = nil
                end
                SpawnPhaseTwo(npc)
                return
            end
            if sprite:IsEventTriggered("Sound") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 0.9 + math.random()*0.1)
                local iceVariant = REVEL.IceGibType.DEFAULT
                if data.IsChampion then
                    iceVariant = REVEL.IceGibType.DARK
                end
                for i=1, 18 do
                    REVEL.SpawnIceRockGib(npc.Position, RandomVector():Resized(math.random(1, 9)), npc, iceVariant, true)
                end
            end
        elseif data.State == "FreezeBlow" then
            if npc.HitPoints <= npc.MaxHitPoints * data.bal.HealthCycleTrigger / 100 then
                sprite:Play("Blow End", true)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.WILLIWAW.BLOW_END)
                REVEL.DisableWindSound(npc)
                data.State = "Idle"
                data.AttackCooldown = 5
            end

            if data.StateFrame >= data.bal.FreezeBlow.BlowStartDelay and not (IsAnimOn(sprite, "Blow Start") or IsAnimOn(sprite, "Blow Loop") or IsAnimOn(sprite, "Blow End")) then
                sprite:Play("Blow Start", true)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.WILLIWAW.BLOW_START)
            end

            if sprite:IsFinished("Blow Start") then
                sprite:Play("Blow Loop", true)
                REVEL.EnableWindSound(npc, true)
            end

            if sprite:IsPlaying("Blow Loop") then
                if not data.BlowDir then
                    data.BlowDir = sign(math.random() - 0.5)
                    data.BlowAngle = 90 - 90 * data.BlowDir
                    data.StartTime = npc.FrameCount
                end

                local t = (npc.FrameCount - data.StartTime) / data.bal.FreezeBlow.Duration

                local key1, key2 = 0.18, 0.6

                --start with a pause, then do first 45° slowly, then speed up
                --overcomplicated? yes, but this was after losing myself in a glass of water while tweaking speeds
                --and trying it to get to feel right and getting all OCD
                if t > key1 and t < key2 then --0 to 45°
                    t = (t - key1) / (key2 - key1)
                    data.BlowAngle = REVEL.Lerp(90 - 90 * data.BlowDir, 90 - 45 * data.BlowDir, REVEL.EaseIn(t))
                elseif t >= key2 then --45° to 180
                    t = (t - key2) / (1 - key2)
                    data.BlowAngle = REVEL.Lerp(90 - 45 * data.BlowDir, 90 + 90 * data.BlowDir, REVEL.EaseOut(t, 1.2))
                end

                local lstart = npc.Position + Vector(0, -52)
                local fromAngle = Vector.FromAngle(data.BlowAngle)
                local lend = lstart + fromAngle * 900

                -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, lstart, lend, false, Color(1, 1, 1, 0.5,conv255ToFloat( 0, 0, 0)), 20)

                for i, player in ipairs(REVEL.players) do
                    if not player:GetData().StalagFrozenOnce and REVEL.CollidesWithLine(player.Position, lstart, lend, 20) then
                        player:GetData().StalagFrozenOnce = true
                        REVEL.Glacier.TotalFreezePlayer(player, (player.Position - npc.Position):Normalized(), 8, nil, false)
                    end
                end

                local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)

                for _, hazard in pairs(iceHazards) do
                    if not hazard:GetData().StalagMovedOnce and REVEL.CollidesWithLine(hazard.Position, lstart, lend, 20) then
                        hazard.Velocity = hazard.Velocity + (hazard.Position - npc.Position):Resized(10)
                    end
                end

                if data.BlowDir > 0 and data.BlowAngle >= 180 or data.BlowDir < 0 and data.BlowAngle <= 0 then
                    data.BlowDir = nil
                    data.State = "Idle"
                    sprite:Play("Blow End", true)
                    REVEL.DisableWindSound(npc)
                    for i, player in ipairs(REVEL.players) do
                        player:GetData().StalagFrozenOnce = nil
                    end
                    for i, player in ipairs(iceHazards) do
                        player:GetData().StalagMovedOnce = nil
                    end
                end
            end

        elseif data.State == "Break" then
            if sprite:IsFinished("Break") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 0.9+math.random()*0.1)
                SpawnPhaseTwo(npc)
                return
            end
            if sprite:IsEventTriggered("Sound") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 0.9 + math.random()*0.1)
                local iceVariant = REVEL.IceGibType.DEFAULT
                if data.IsChampion then
                    iceVariant = REVEL.IceGibType.DARK
                end
                for i=1, 18 do
                    REVEL.SpawnIceRockGib(npc.Position, RandomVector():Resized(math.random(1, 9)), npc, iceVariant, true)
                end
            end
        end

        if not data.Moving then
            npc.Velocity = Vector.Zero
            npc.Position = data.LockPosition
        else
            local len = npc.Velocity:Length()

            if maxMoveSpeed and len > maxMoveSpeed then
                npc.Velocity = npc.Velocity * (maxMoveSpeed / len)
            end

            if len > 2 then
                if not data.SpawnedIceCreepGibs then
                    for i = 1, math.random(7,12) do
                        local randomVec = (RandomVector() * math.random(1,5)) + Vector(math.random(-5,5),0)
                        local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, (npc.Position - Vector(0,-20)) + randomVec, randomVec, npc)
                        eff:GetData().NoGibOverride = true
                        eff.Color = Color.Default
                        if data.bal.GibsSpritesheet ~= "" then
                            eff:GetSprite():ReplaceSpritesheet(0, data.bal.GibsSpritesheet)
                            eff:GetSprite():LoadGraphics()
                        end
                    end
                    data.SpawnedIceCreepGibs = true
                end

                if npc.FrameCount % 8 == 0 then
                    local creep = REVEL.SpawnIceCreep(npc.Position, npc):ToEffect()
                    REVEL.UpdateCreepSize(creep, creep.Size * 2.5, true)
                end
            end
        end

        
        local speed = npc.Velocity:Length()

        if speed > 4 then
            data.DustLastPos = data.DustLastPos or npc.Position

            if data.DustLastPos:DistanceSquared(npc.Position) > 30*30 then
                ---@type EntityEffect
                local dust = Isaac.Spawn(
                    1000, 
                    EffectVariant.DUST_CLOUD, 
                    0, 
                    npc.Position - npc.Velocity:Rotated(math.random(-15, 15)) * (25 / speed), 
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

    --Unfrozen
    elseif REVEL.ENT.STALAGMITE_2:isEnt(npc) then
        if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        end

        if sprite:IsPlaying("AppearAnim") then
            return
        elseif sprite:IsFinished("AppearAnim") then
            sprite:Play("Head", true)
        end

        local accel = data.bal.UnfrozenDefaultAccel
        local follow = true
        local target = npc:GetPlayerTarget()

        if data.State == "DefaultFollow" then
            if sprite:IsFinished("Blow End") then sprite:Play("Head", true) end

            if data.AttackCooldown then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            else
                local curCycle, isAttacking, attack, cooldown, changedPhase = REVEL.ManageAttackCycle(data, data.bal, data.bal.UnfrozenCycle)
                if isAttacking then
                    REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                    if data.bal.AttackToStateAnim[attack] then
                        data.State = data.bal.AttackToStateAnim[attack].State
                        if data.bal.AttackToStateAnim[attack].Anim then
                            sprite:Play(data.bal.AttackToStateAnim[attack].Anim, true)
                        end
                        if data.bal.AttackToStateAnim[attack].OverlayAnim then
                            sprite:PlayOverlay(data.bal.AttackToStateAnim[attack].OverlayAnim, true)
                            sprite:SetOverlayRenderPriority(true)
                        else
                            sprite:RemoveOverlay()
                        end
                    end

                    data.AttackCooldown = cooldown

                    if curCycle.ChangeSpikes ~= nil then
                        data.SpikesRaised = curCycle.ChangeSpikes
                    end
                    if curCycle.RaiseWithHoles then
                        data.SpikesRaiseHolesNum = REVEL.GetFromMinMax(curCycle.RaiseWithHoles)
                    end
                end
            end
        elseif data.State == "UnfrozenBlow" then
            if sprite:IsPlaying("Blow Start") then
                follow = false
            elseif sprite:IsFinished("Blow Start") then
                sprite:Play("Blow Loop", true)
                data.AttackTimer = REVEL.GetFromMinMax(data.bal.UnfrozenBlow.Duration)
                REVEL.EnableWindSound(npc, true)
            end

            accel = data.bal.UnfrozenBlow.WalkAccel

            if sprite:WasEventTriggered("Blow") or sprite:IsPlaying("Blow Loop") then
                if data.AttackTimer then
                    data.AttackTimer = data.AttackTimer - 1
                    if data.AttackTimer <= 0 then
                        data.AttackTimer = nil
                        sprite:Play("Blow End", true)
                        data.State = "DefaultFollow"
                        REVEL.DisableWindSound(npc)
                    end
                end

                local curRoom = StageAPI.GetCurrentRoom()
                for _, player in ipairs(REVEL.players) do
                    local addVel = (player.Position - npc.Position ):Normalized()
                    if player:GetDamageCooldown() == 0 then
                        if REVEL.Glacier.CheckIce(player, curRoom) then
                            player.Velocity = player.Velocity + addVel * data.bal.UnfrozenBlow.PlayerBlowStrengthIce
                        else
                            player.Velocity = player.Velocity + addVel * data.bal.UnfrozenBlow.PlayerBlowStrength
                        end
                    end
                end
                for _, projectile in pairs(REVEL.roomProjectiles) do
                    projectile.Velocity = projectile.Velocity + (projectile.Position - npc.Position):Resized(data.bal.UnfrozenBlow.ProjBlowStrength)
                end
                for _, tear in pairs(REVEL.roomTears) do
                    tear.Velocity = tear.Velocity + (tear.Position - npc.Position):Resized(data.bal.UnfrozenBlow.TearBlowStrength)
                end
                local chillos = REVEL.ENT.CHILL_O_WISP:getInRoom()
                for _, chillo in pairs(chillos) do
                    local diffc, diffp = chillo.Position - npc.Position, npc:GetPlayerTarget().Position - npc.Position
                    if diffc:Dot(diffp) > 0 then
                        chillo.Velocity = chillo.Velocity + REVEL.Lerp(npc:GetPlayerTarget().Position - chillo.Position, diffc, 0.3):Resized(data.bal.UnfrozenBlow.ChilloBlowStrength)
                    else
                        chillo.Velocity = chillo.Velocity + (-diffc):Resized(data.bal.UnfrozenBlow.ChilloBlowStrength * 0.7)
                    end
                end

                if math.random(2) == 1 then
					local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, npc.Position, Vector(math.random()*16-8,math.random()*16-8), npc)
					snowp:GetSprite():Play("Fade", true)
					snowp:GetSprite().Offset = Vector(0,-25)
					snowp:GetData().Rot = math.random()*20-10
                end

                if npc.FrameCount % data.bal.UnfrozenBlow.ProjShootRate == 0 then
                    local dir = (target.Position + target.Velocity - npc.Position):Normalized()
                    local pro = Isaac.Spawn(9, 0, 0, npc.Position + dir * 2, dir:Rotated(math.random(30) - 15) * data.bal.UnfrozenBlow.ProjShootSpeed, npc)
                    pro:GetData().ProjAccel = data.bal.UnfrozenBlow.ProjAccel
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 0.8, 0, false, 1)
                end
            end
        end

        data.UsePlayerMap = follow

        if follow then
            if data.Path then
                REVEL.FollowPath(npc, accel, data.Path, true, data.bal.UnfrozenFriction)
            end
        else
            npc.Velocity = npc.Velocity * 0.6
        end
        REVEL.AnimateWalkFrameOverlaySpeed(sprite, npc.Velocity, data.bal.UnfrozenWalkAnims)
        sprite:SetOverlayRenderPriority(true)
    end

    if sprite:IsOverlayPlaying("SpikesOn") and sprite:GetOverlayFrame() == 0 then
        REVEL.sfx:Play(REVEL.SFX.STALAG_SPIKES, 1, 0, false, 1)
    end

    -- Inhale sound
    if sprite:IsEventTriggered("Inhale") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.INHALE, 1, 0, false, 1)
    end
    -- Blow sound
    if sprite:IsEventTriggered("Blow") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.MOUTH_PULL, 1, 0, false, 1)
    end

    if data.Spikes then
        REVEL.UpdateStalagmightSpikes(npc, data.Spikes)
    end
    npc.SplatColor = REVEL.WaterSplatColor

    if data.State ~= data.PrevState then
        data.StateFrame = 0
        data.PrevState = data.State
    else
        data.StateFrame = data.StateFrame + 1
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, stalagmight_NpcUpdate, REVEL.ENT.STALAGMITE.id)

function REVEL.UpdateStalagmightSpikes(stalag, spikes)
    local data = stalag:GetData()

    local stalagDead = stalag:IsDead() or not stalag:Exists()

    for _, spike in ipairs(spikes) do
        local sdata, ssprite = spike:GetData(), spike:GetSprite()

        -- fallback
        if not sdata.Init then
            initSpike(stalag, data, spike)
            REVEL.DebugStringMinor("Initialized stalagmight spike via fallback at " .. tostring(REVEL.room:GetGridIndex(spike.Position)))
        end

        if sdata.LockPosition then
            spike.Position = spike:GetData().LockPosition
        end
        if ssprite:IsFinished("Unsummon" .. sdata.randomnum) then
            spike.Visible = false
        end
        --Explode
        if ssprite:IsFinished("Explode" .. sdata.randomnum) and sdata.Raised then
            spike.Visible = false
            sdata.Raised = false
            spike.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)

            if sdata.UseFreezeAura and data.bal.IceBreaker.SpikesFreezeRadius > 0 then
                local radius = data.bal.IceBreaker.SpikesFreezeRadius
                sdata.NoAuraRerender = true
                sdata.Aura = REVEL.SpawnAura(radius, spike.Position + Vector(0, 15), REVEL.CHILL_COLOR_LOWA, spike, true)
                sdata.AuraDuration = data.bal.IceBreaker.SpikesFreezeAuraTime
            end

            if not data.DontShoot and not sdata.DontShootThisTime then
                local startAngle = 0
                if data.bal.IceBreaker.RandomProjAngle then
                    startAngle = math.random(360)
                end
                for i = 1, data.bal.SpikesBulletNum do
                    local angle = i * 360 / data.bal.SpikesBulletNum + startAngle
                    local vel = Vector.FromAngle(angle) * data.bal.SpikeProjectileSpeed
                    local proj = Isaac.Spawn(9, 4, 0, spike.Position + Vector(0, 15), vel, spike)
                    if sdata.UseFreezeAura and data.bal.IceBreaker.SpikesFreezeRadius > 0 then
                        REVEL.HoldAuraProjectile(proj:ToProjectile(), sdata.Aura)
                    end
                end
            end
            local iceVariant = REVEL.IceGibType.DEFAULT
            if data.IsDarkIce then
                iceVariant = REVEL.IceGibType.DARK
            end
            for i=1, 4 do
                REVEL.SpawnIceRockGib(spike.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), spike, iceVariant, false)
            end
            sdata.UseFreezeAura = nil
            sdata.DontShootThisTime = nil
        end
        if ssprite:IsFinished("Summon" .. sdata.randomnum) then
            spike.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if sdata.Aura then
            sdata.AuraDuration = sdata.AuraDuration - 1
            if sdata.AuraDuration <= 0 then
                sdata.AuraDuration = nil
                REVEL.AuraExpandFade(sdata.Aura, 5, sdata.Aura:GetData().Radius * 1.6)
                sdata.Aura = nil
            end
        end
    end

    if data.SpikeRaisingComplete then
        data.AvoidSpikes = nil
    end

    if not data.SpikesRaised then
        data.SpikeRaisingComplete = nil
        data.SpikeCheckLeft = nil
        data.SpikeCheckRight = nil
        data.SpikeCheckY = nil
        for _, spike in ipairs(spikes) do
            local sdata, ssprite = spike:GetData(), spike:GetSprite()
            if stalagDead or not sdata.AlwaysOn then
                sdata.Raised = false
                if (IsAnimOn(ssprite, "Summon"..sdata.randomnum) or IsAnimOn(ssprite, "Explode" .. sdata.randomnum)) then
                    ssprite:Play("Unsummon"..sdata.randomnum, true)
                end

                spike.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end
        end
    elseif not data.SpikeRaisingComplete then
        local room = REVEL.room
        local topCenterX, topCenterY = REVEL.GridToVector(room:GetGridIndex(room:GetClampedPosition(Vector(room:GetCenterPos().X, -99999), 0)))

        if not data.AvoidSpikes and data.SpikesRaiseHolesNum then
            data.AvoidSpikes = {}
            local doneSet = {}
            for i = 1, data.SpikesRaiseHolesNum do
                --pick 3 adjacent random spikes that are below stalag
                local spike1, spike2
                repeat
                    spike1 = REVEL.randomFrom(spikes)
                until spike1.Position.Y > stalag.Position.Y + 120 and not data.AvoidSpikes[GetPtrHash(spike1)]

                data.AvoidSpikes[GetPtrHash(spike1)] = true

                local closeSpikes = {}
                for dir = 0, 3 do --check in cardinal directions
                    local checkPos = spike1.Position + REVEL.dirToVel[dir] * 40
                    local spike = GetEntitiesInRadius(checkPos, 12, spikes)[1]
                    if spike and not data.AvoidSpikes[GetPtrHash(spike)] then
                        data.AvoidSpikes[GetPtrHash(spike)] = true
                    end
                end
            end
        end

        data.SpikeCheckLeft = data.SpikeCheckLeft or topCenterX + 1
        data.SpikeCheckRight = data.SpikeCheckRight or topCenterX
        data.SpikeCheckY = data.SpikeCheckY or topCenterY
        if not data.SpikeRaiseCounter or data.bal.SpikeRaiseDelay == 0 then
            local done
            while not done do
                local checkLeft, checkRight = room:GetGridPosition(REVEL.VectorToGrid(data.SpikeCheckLeft, data.SpikeCheckY)), room:GetGridPosition(REVEL.VectorToGrid(data.SpikeCheckRight, data.SpikeCheckY))
                if not room:IsPositionInRoom(checkLeft, 0) or not room:IsPositionInRoom(checkRight, 0) then
                    data.SpikeCheckLeft = topCenterX + 1
                    data.SpikeCheckRight = topCenterX
                    data.SpikeCheckY = data.SpikeCheckY + 1
                    done = true
                end

                local spikesLeft, spikesRight = GetEntitiesInRadius(checkLeft, 8, spikes), GetEntitiesInRadius(checkRight, 8, spikes)
                if #spikesLeft > 0 or #spikesRight > 0 then
                    local activateSpikes = REVEL.ConcatTables(spikesLeft, spikesRight)
                    for _, spike in ipairs(activateSpikes) do
                        local sdata, ssprite = spike:GetData(), spike:GetSprite()
                        if not sdata.Raised and not (data.AvoidSpikes and data.AvoidSpikes[GetPtrHash(spike)]) then
                            ssprite:Play("Summon"..sdata.randomnum, true)
                            spike.Visible = true
                            sdata.Raised = true
                            for _, player in ipairs(REVEL.players) do
                                if spike.Position:DistanceSquared(player.Position) < 40 * 40 then
                                    player.Velocity = (REVEL.room:GetCenterPos() - player.Position):Resized(8)
                                end
                            end
                            SFXManager():Play(REVEL.SFX.STALAG_STALAGMITE, 0.8, 0, false, 1)
                            data.SpikeRaiseCounter = data.bal.SpikeRaiseDelay
                        end
                    end

                    done = true
                end

                data.SpikeCheckLeft = data.SpikeCheckLeft - 1
                data.SpikeCheckRight = data.SpikeCheckRight + 1
                if data.SpikeCheckY > room:GetGridHeight() then
                    data.SpikeRaisingComplete = true
                    data.SpikeCheckLeft = nil
                    data.SpikeCheckRight = nil
                    data.SpikeCheckY = nil
                    done = true
                end

                done = true
            end
        else
            data.SpikeRaiseCounter = data.SpikeRaiseCounter - 1
            if data.SpikeRaiseCounter <= 0 then
                data.SpikeRaiseCounter = nil
            end
        end
    end
end

local windAnimSpeed = 1.3
local windBaseAlpha = 0.75

--One way of having em in sync (also easier to use with rendertiled)
local windSprite = {}
for i = 1, 3 do
    local animation = "Line"
    if i == 1 then
        animation = "Start"
    elseif i == 3 then
        animation = "End"
    end

    windSprite[i] = REVEL.LazyLoadRoomSprite {
        ID = "Stalagmight_WindSprite" .. i,
        Anm2 = "gfx/effects/revel1/icewind_laser_offset.anm2",
        Animation = animation,
        Color = Color(1, 1, 1, windBaseAlpha),
        PlaybackSpeed = windAnimSpeed,
    }
end

local lastUpdated

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.STALAGMITE:isEnt(npc) or not REVEL.IsRenderPassNormal() then return end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if data.HeadSprite then
        local offset = REVEL.Lerp2(Vector.Zero, data.bal.MeltHeadOffset, sprite:GetFrame(), 0, data.bal.MeltHeadOffsetFrame)
        data.HeadSprite:Render(Isaac.WorldToScreen(npc.Position) + offset, Vector.Zero, Vector.Zero)
    end

    if data.State == "FreezeBlow" and (sprite:WasEventTriggered("Blow") or sprite:IsPlaying("Blow Loop")) then
        if not lastUpdated or REVEL.game:GetFrameCount() > lastUpdated then
            for i = 1, 3 do windSprite[i]:Update() end
            lastUpdated = REVEL.game:GetFrameCount()
        end

        local offset = Vector(0, -52)

        local startPos = npc.Position + offset
        local fromAngle = Vector.FromAngle(data.BlowAngle)
        local endPos = REVEL.room:GetClampedPosition(startPos + fromAngle * 300, 20)

        startPos = Isaac.WorldToScreen(startPos)
        endPos = Isaac.WorldToScreen(endPos)
        local lineStartPos = startPos + (endPos - startPos):Resized(26)
        local angle = data.BlowAngle

        windSprite[1].Rotation = angle
        windSprite[1]:Render(startPos, Vector.Zero, Vector.Zero)
        REVEL.DrawRotatedTilingSprite(windSprite[2], lineStartPos, endPos, 26)
        windSprite[3].Rotation = angle
        windSprite[3]:Render(endPos, Vector.Zero, Vector.Zero)
    end
end, REVEL.ENT.STALAGMITE.id)

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    lastUpdated = nil
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flag)
    if e.Type == REVEL.ENT.STALAGMITE.id and (e.Variant == REVEL.ENT.STALAGMITE.variant or e.Variant == REVEL.ENT.STALAGMITE_2.variant) then
        if HasBit(flag, DamageFlag.DAMAGE_SPIKES) then
            return false
        end
        if e.Variant == REVEL.ENT.STALAGMITE.variant then
            local data = e:GetData()
            if data.State == "Break" or data.Breaking then
                return false
            end
        end
        if e.HitPoints - amount - REVEL.GetDamageBuffer(e) <= 0 then
            e:GetData().SpikesRaised = false
            REVEL.UpdateStalagmightSpikes(e:ToNPC(), e:GetData().Spikes)
            REVEL.DisableWindSound(e)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    local data = proj:GetData()

    if data.ProjAccel then
        local l = proj.Velocity:Length()
        proj.Velocity = proj.Velocity * ((l + data.ProjAccel) / l)
    end
end)

end
REVEL.PcallWorkaroundBreakFunction()