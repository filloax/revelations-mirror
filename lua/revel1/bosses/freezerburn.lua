local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

return function()
    REVEL.FreezerBurnBalance = {
        Champions = {Headless = "Default"},
        Skin = {Default = "", Headless = "gfx/bosses/revel1/freezer_burn/freezer_burn_champion.png"},

        AttackCycleDefaultCooldownBetween = 20,
        AttackCycleDefaultCooldown = 40,
        StartCooldown = 80,
        IncreaseSubcycleIndexOnChildEnd = true,

        SubCycles = {
            DoubleChase = {
                Default = {
                    {
                        HeadAttack = true,
                        NoBodyAttack = true,
                        Attacks = {
                            HeadShoot = 1,
                        },
                        Repeat = {Min = 2, Max = 4},
                        DamagePctForEarlyEnd = 0.1, --finishes before finishing all repeats if he gets damaged this much
                        CooldownBetween = {Min = 30 * 2, Max = 30 * 4},
                        CooldownAfter = {Min = 30 * 1, Max = 30 * 3},
                    },
                },
                Headless = {
                    {
                        HeadAttack = true,
                        NoBodyAttack = true,
                        Attacks = {
                            HeadShoot = 1,
                        },
                        Repeat = 2,
                        CooldownBetween = {Min = 45, Max = 90},
                        CooldownAfter = {Min = 60, Max = 100},
                    },
                },
            },
            HeadlessFinale = {
                {
                    HeadAttack = true,
                    NoWaitForFireEnd = true,
                    Attacks = {
                        Fireworks = 1,
                    },
                    CooldownAfter = 0,
                },
                {
                    Attacks = {
                        MeltyRebounder = 1,
                    },
                },
            },
            HeadwithFinale = {
                {
                    Attacks = {
                        Finale = 1,
                    },
                    CooldownAfter = 0,
                },
                {
                    Attacks = {
                        MeltyRebounder = 1,
                    },
                },
            },
       },

        --Cycles aren't really needed for base frezerburn, since each phase is a 1 attack loop, 
        --but eventual champions might use them and 
        --it looks cool ok
        StartHeadCycle = {
            {
                RepeatTimesForPermaRebound = 3,
                Attacks = {
                    Rebounder = 1,
                }
            }
        },

        DefaultFireDamageHpPercent = 0.09,
        NonHeadlessDamageResist = 0.60, --to encourage using the fires
        FireHitCooldown = 20,

        MidHpPct = {
            Default = 0.6,
            Headless = 0.5,  
        },
        FinaleHpPct = {
            Default = 0.2,
            Headless = 0,
        },

        MidHeadCycle = {
            {
                RepeatTimesForPermaRebound = 3,
                Attacks = {
                    MeltyRebounder = 1,
                }
            }
        },

        HeadlessCycle = {
            {
                HeadAttack = true,
                NoBodyAttack = true,
                Attacks = {
                    DoubleChase = 1,
                },
            },
            {
                HeadAttack = true,
                Attacks = {
                    Fireworks = 1,
                },
            }
        },

        CycleStartCheck = function(data, bal, curCycleSegment, primaryCycle, curCycle, npc, roomFires)
            if not data.IsChampion then
                local fire, dist = REVEL.getClosestInTable(roomFires, npc)

                if fire and dist < (npc.Size + fire.Size + 30) ^ 2 then
                    return false
                end
            end
            return true
        end,

        NoBodyCycle = {
            Default = false,
            Headless = true,
        },
        HeadAlwaysOff = {
            Default = false,
            Headless = true,
        },
        HeadChases = {
            Default = false,
            Headless = true,
        },
        HeadChasesDuringFireworks = false,
        NoHeadAttackDuringFireworks = {
            Default = false,
            Headless = true,
        },
        ChaseImmuneToFires = true,

        AttackStartAnims = {
            Rebounder = "Slide Charge",
            Fireworks = "Headless Idle",
            MeltyRebounder = "Slide Charge",
            Finale = "Fire",
        },

        AttackStartHeadAnims = {
            -- HeadShoot = "Fire",
            -- Fireworks = "Fire",
        },

        RebounderCollisions = 1,
        RebounderAlwaysChases = true,
        DisableChaseOnReboundCollision = true,

        HeadShoot = {
            Default = {
                TimeBeforeShoot = 15,
                ShotAmount = 1,
                FireNum = {Min = 4, Max = 6},
                ShotRandomSpread = 60,
                RotationAfterShots = 0,
                TimeBeforeShotShrink = 20,
                ShotSpeed = 13,
                ShotFriction = 0.5,
                FinalSpeedTime = 30,
                BulletScale = 1,
            },
            Headless = {
                TimeBeforeShoot = 18,
                ShotAmount = 3,
                FireNum = 3,
                ShotRandomSpread = 0,
                RotationAfterShots = 40,
                TimeBeforeShotShrink = 65,
                ShotSpeed = 11,
                ShotFriction = 0.8,
                FinalSpeedTime = 48,
                BulletScale = 1,
            },
        },
        
        Fireworks = {
            Default = {
                TimeBeforeShoot = 15,
                SuperFireDuration = 120,
                DoSuperFires = true,
                ShutOffFiresAfter = false,
            },
            Headless = {
                TimeBeforeShoot = 15,
                SuperFireDuration = 120,
                DoSuperFires = true,
                ShutOffFiresAfter = true,
            },
        },

        MeltyRebounder = {
            NumMelts = 2,
            BounceLastTime = true,
            ReformDistance = 120,
            TimeToReform = 5,
            RandomAngleSpread = 270,
            MeltsBetweenBoundsAtFinale = 1,
            BoundsBetweenMeltsAtFinale = 1,
        },

        Finale = {
            SuperFireShootTime = 120,
            FireDamageHpPercent = 0.01,
        },

        ChampionShootDefaultCooldown = 70,
        ChampionJumpDefaultCooldown = 140,

        ChaseAccel = 0.5,
        ChaseFriction = 0.92,
        SlideStartSpd = 4,
        SlideFriction = 0.96,
        SlideAccel = 0.45,
        HeadlessChaseAccel = 0.5,
        HeadlessChaseFriction = 0.96,
        HeadAccel = {
            Default = 0.6,
            Headless = 0.5,
        },
        HeadFriction = 0.91,
        HeadWarmRadius = 90,

        FireplacePositions = {32, 42, 92, 102},
        
        WalkAnims = {Vertical = "Walk Vert", Horizontal = "Walk Right", Idle = "Idle"},
        HeadlessWalkAnims = {Vertical = "Headless Walk Vert", Horizontal = "Headless Walk Right"},
        AttackNames = {Rebounder = "Rebounder", HeadShoot = "Nova", Fireworks = "Fireworks", MeltyRebounder = "Melty Rebounder"},
    }

    REVEL.FreezerBurnChampionColor = Color(255 / 255, 243 / 255, 50 / 255, 1,conv255ToFloat( 0, 0, 0))
    local h,s,v = hsvToRgb(0.1, 0.8, 0.95)
    REVEL.FreezerBurnFireLightColor = Color(h,s,v,1,conv255ToFloat( 70,70,70))
    h,s,v = hsvToRgb(0, 0.95, 1)
    REVEL.FreezerBurnChampionLightColor = Color(h,s,v,1,conv255ToFloat( 70,70,70))

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_BOSS_ROOM_INIT, 1, function(newRoom, boss)
        if boss.Name == "Freezer Burn" or boss.NameTwo == "Freezer Burn" then
            newRoom:SetTypeOverride(RevRoomType.CHILL_FREEZER_BURN)
        end
    end)
    
    local function getOnFires()
        return REVEL.filter(REVEL.ENT.LIGHTABLE_FIRE:getInRoom(), REVEL.Glacier.IsLightableFireOn)
    end
    
    local function getOffFires()
        return REVEL.filter(REVEL.ENT.LIGHTABLE_FIRE:getInRoom(), function(fire) return not REVEL.Glacier.IsLightableFireOn(fire) end)
    end

    local function areThereSuperFires()
        local fires = getOnFires()
        local superFiresLeft = false

        for _, fire in pairs(fires) do
            if fire:GetData().SuperFireTime then
                superFiresLeft = true 
                break
            end
        end

        if not superFiresLeft then
            local bulletFires = Isaac.FindByType(1000, 8, -1, false, false)
            for _, ent in pairs(bulletFires) do
                if ent:GetData().FreezerburnFire and ent:GetData().Super then
                    superFiresLeft = true
                    break
                end
            end
        end

        return superFiresLeft
    end

    local function collidesWithFire(npc)
        local data = npc:GetData()

        if not data.LastHitFireFrame or npc.FrameCount - data.LastHitFireFrame > data.bal.FireHitCooldown then
            if data.JustHitFire then
                local fire = data.JustHitFire
                data.JustHitFire = nil
                data.LastHitFireFrame = npc.FrameCount
                return fire
            else
                --additional check for when he's melting
                local fires = getOnFires()

                for _, fire in pairs(fires) do
                    if fire.Position:DistanceSquared(npc.Position) <= (fire.Size + npc.Size) ^ 2 then
                        data.CustomFireDamage = true
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                        npc:TakeDamage(npc.MaxHitPoints * data.bal.DefaultFireDamageHpPercent, 0, EntityRef(fire:GetData().Fire), 15)
                        data.CustomFireDamage = nil
                        data.LastHitFireFrame = npc.FrameCount
                        return fire
                    end
                end
            end
        end

        return nil
    end

    local function shootBulletFire(npc, pos, vel, targetFire, noTarget, friction, shrinking, endVel, endVelTime, super, sizeMult, shutdownAfterSuper, glow)
        local fireBullet = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LADDER, 0, pos, vel, npc)
        local data, sprite = fireBullet:GetData(), fireBullet:GetSprite()
        if glow then
            sprite:Load("gfx/effects/revel1/freezer_burn_fire_glowing.anm2", true)
        else
            sprite:Load("gfx/effects/revel1/freezer_burn_fire.anm2", true)
        end
        sprite:Play("Idle", true)

        REVEL.SpawnLightAtEnt(fireBullet, REVEL.FreezerBurnFireLightColor, 1.5)
        fireBullet.Size = 24 * (sizeMult or 1)
        fireBullet.SpriteScale = Vector.One * (sizeMult or 1)
        fireBullet.SpawnerEntity = npc

        data.FreezerburnFire = true
        data.TargetFire = targetFire
        data.NoTargetFires = noTarget
        data.Friction = friction
        data.Shrinking = shrinking
        data.StartVelocity = vel
        data.EndVelocity = endVel
        data.TimeToEndVel = endVelTime
        data.TimeToEndVelStart = endVelTime
        data.Super = super
        data.ShutdownAfterSuper = shutdownAfterSuper

        if super then
            fireBullet.Color = Color(1, 1, 1, 1,conv255ToFloat( 90, 60, 30))
            data.SuperFireDuration = npc:GetData().bal.Fireworks.SuperFireDuration
        end

        REVEL.SetWarmAura(fireBullet)

        return fireBullet
    end

    function REVEL.ShootFreezerBurnFire(npc, pos, vel, sizeMult, friction, shrinking, endVel, endVelTime, glow)
        return shootBulletFire(npc, pos, vel, nil, true, friction, shrinking, endVel, endVelTime, false, sizeMult, false, glow)
    end

    --This function is _not_ getting removed
    local function fireFireAtFire(npc, targFire, time, super, shutdownAfterSuper, superOnFires)
        local fire = shootBulletFire(npc, npc.Position, (targFire.Position - npc.Position) / time, targFire, false, nil, nil, nil, nil, super, nil, shutdownAfterSuper)
        fire:GetData().SyncSuperFires = superOnFires and REVEL.ENT.LIGHTABLE_FIRE:getInRoom() or getOffFires()
        return fire
    end
    

    local function isHeadless(freezerburn)
        local data = freezerburn:GetData()
        -- local cycleData = data.Cycle[2]

        -- for i = 2, #data.Cycle do
        --     if data.Cycle[i].SubCycle == "DoubleChase" then
        --         return true
        --     end
        -- end

        return data.Head ~= nil
    end
    
    ---@param npc EntityNPC
    local function spawnFreezerBurnHead(npc, vel, bdata)
        local head = REVEL.ENT.FREEZER_BURN_HEAD:spawn(npc.Position + Vector(0, 2), vel, npc)
        local data, sprite = head:GetData(), head:GetSprite()
        data.IsChampion = bdata.IsChampion
        data.bal = bdata.bal
        bdata.Head = head
        data.Body = npc
        REVEL.SetWarmAura(head, data.bal.HeadWarmRadius)
        REVEL.SpawnLightAtEnt(head, REVEL.FreezerBurnFireLightColor, 4, Vector(0, -15))

        data.State = "Escape"
        data.StateFrame = 0

        if data.bal.Skin ~= "" then
            for i = 0, 1 do
                sprite:ReplaceSpritesheet(i, data.bal.Skin)
            end
            sprite:LoadGraphics()
        end

        sprite:Play("Appear", true)

        return head
    end

    local jumpDuration = 16

    local function freezerBurnChampionBodyUpdate(npc, data, sprite, target)
        local belowHpTreshold1 = npc.HitPoints < npc.MaxHitPoints * data.bal.MidHpPct
        local jumping
        local fireworksOn = areThereSuperFires()

        if not belowHpTreshold1 then
            if sprite:IsPlaying("Headless Idle") then
                if data.ChampionShootCooldown <= 0 then
                    data.ChampionShootCooldown = data.bal.ChampionShootDefaultCooldown
                    sprite:Play("Puking", true)
                elseif not fireworksOn then
                    data.ChampionShootCooldown = data.ChampionShootCooldown - 1
                end
            elseif sprite:IsEventTriggered("Shoot") then
                local dir = target.Position - npc.Position
                local pro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, dir:Resized(9), npc):ToProjectile()
                
                pro.FallingAccel = 0.2
                pro.FallingSpeed = -5
            end
        else --jump around sometimes
            if sprite:IsPlaying("Headless Idle") then
                if data.ChampionShootCooldown <= 0 then
                    data.ChampionShootCooldown = data.bal.ChampionJumpDefaultCooldown
                    sprite:Play("Hit Fire Jump", true)
                    data.JumpVel = (target.Position + RandomVector() * math.random(1, 90) - npc.Position)
                    local l = data.JumpVel:Length()
                    if l > 40 * 12 then
                        data.JumpVel = data.JumpVel * (40 * 12 / l)
                    end
                    data.JumpVel = data.JumpVel / jumpDuration
                elseif not fireworksOn then
                    data.ChampionShootCooldown = data.ChampionShootCooldown - 1
                end
            elseif sprite:IsPlaying("Hit Fire Jump") then
                if sprite:WasEventTriggered("Stomp2") and not sprite:WasEventTriggered("Stomp") then
                    npc.Velocity = data.JumpVel
                    jumping = true
                end
            elseif sprite:IsFinished("Hit Fire Jump") then
                sprite:Play("Headless Idle", true)
            end
        end

        if not jumping then
            npc.Velocity = npc.Velocity * 0.8
        end

        if sprite:IsFinished("Puking") then
            sprite:Play("Headless Idle", true)
        end
    end

    --Update FB
    local function FreezerBurnUpdate(npc, data, sprite, target)
        npc.SplatColor = REVEL.SnowSplatColor

        if not data.State then
            data.State = "Chase"
            sprite:Play("Appear", true)
            data.StateFrame = 0

            data.IsChampion = REVEL.IsChampion(npc)

            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

            REVEL.SetScaledBossHP(npc)

            if data.IsChampion then
                data.bal = REVEL.GetBossBalance(REVEL.FreezerBurnBalance, "Headless")

                npc.MaxHitPoints = npc.MaxHitPoints * 0.8
                npc.HitPoints = npc.MaxHitPoints

                data.ChampionShootCooldown = data.bal.ChampionShootDefaultCooldown
            else
                data.bal = REVEL.GetBossBalance(REVEL.FreezerBurnBalance, "Default")
            end

            if data.bal.Skin ~= "" then
                for i = 0, 3 do
                    sprite:ReplaceSpritesheet(i, data.bal.Skin)
                end
                sprite:LoadGraphics()
            end
    
            data.AttackCooldown = data.bal.StartCooldown

            -- Spawning / Initializing White Fires
            local fireEntities = REVEL.ENT.LIGHTABLE_FIRE:getInRoom()
            if #fireEntities == 0 then
                for i = 1, 4 do
                    fireEntities[#fireEntities + 1] = REVEL.ENT.LIGHTABLE_FIRE:spawn(room:GetGridPosition(data.bal.FireplacePositions[i]), Vector.Zero, nil)
                end
            end

            if data.bal.HeadAlwaysOff then
                spawnFreezerBurnHead(npc, Vector.Zero, data)

                sprite:Play("Headless Idle", true)

                for _, fire in pairs(fireEntities) do
                    if fire:GetData().Init then --if fire was initialized before champion was decided
                        REVEL.Glacier.ShutdownLightableFire(fire, true)
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Stomp") or sprite:IsEventTriggered("Stomp2") then
            if REVEL.MultiPlayingCheck(sprite, "Walk Right", "Walk Vert", "Headless Walk Right", "Headless Walk Vert") then
                REVEL.game:ShakeScreen(2)
                REVEL.sfx:Play(48, 0.3, 0, false, 0.98 + math.random() * 0.1)
            else
                REVEL.game:ShakeScreen(8)
                REVEL.sfx:Play(48, 1, 0, false, 0.95 + math.random() * 0.1)
            end
        end

        if sprite:IsEventTriggered("Shoot") then
			local dir = target.Position - npc.Position
			local pro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, dir:Resized(9), npc):ToProjectile()
            pro.FallingAccel = 0.2
            pro.FallingSpeed = -5
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
		end

        if sprite:IsEventTriggered("Poof") then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position + Vector(0,3), Vector.Zero, npc)
			REVEL.game:ShakeScreen(5)
		end

        if sprite:IsFinished("Default Die") then
            npc:Die()
        end
        if sprite:IsFinished("Headless Die") then
            data.Head:Die()
            npc:Die()
        end

        if REVEL.MultiPlayingCheck(sprite, "Appear", "Headless Die", "Default Die") then return end

        local doChase

        if npc.HitPoints < npc.MaxHitPoints * data.bal.FinaleHpPct and not data.Finale and data.bal.FinaleHpPct > 0 then
            if isHeadless(npc) then
                REVEL.JumpToCycle(data, 1, "HeadlessFinale", 1)
            else
                REVEL.JumpToCycle(data, 1, "HeadwithFinale", 1)
            end

            for _, fire in pairs(REVEL.ENT.LIGHTABLE_FIRE:getInRoom()) do
                fire:GetData().SuperFireShootTime = data.bal.Finale.SuperFireShootTime --do it now since it will get applied later anyways
            end

            data.State = "Chase"
            data.Finale = true
            data.AttackCooldown = 0
            data.HPForCycleEarlyEnd = nil

            if REVEL.DEBUG then
                REVEL.DebugLog("Triggered finale")
            end
        end

        if REVEL.MultiPlayingCheck(sprite, "Hit Fire", "Headless Hit Fire") then
            npc.Velocity = npc.Velocity * 0.85
        end

        --Default state, cycle management is here
        if data.State == "Chase" then
            local dir = target.Position - npc.Position
            local dist = dir:Length()
            local doNextAttack

            if isHeadless(npc) then
                if data.bal.NoHeadAttackDuringFireworks and areThereSuperFires() then
                    data.AttackCooldown = data.AttackCooldown + 1
                end

                doNextAttack = data.Head:GetData().State == "Escape" and data.Head:GetData().StateFrame > data.AttackCooldown
            else
                doNextAttack = data.StateFrame > data.AttackCooldown
            end

            doChase = not (data.IsChampion or REVEL.MultiPlayingCheck(sprite, "Hit Fire", "Headless Hit Fire"))

            if data.IsChampion then
                freezerBurnChampionBodyUpdate(npc, data, sprite, target)
            end

            if data.HPForCycleEarlyEnd and npc.HitPoints <= data.HPForCycleEarlyEnd and not data.Finale then
                data.HPForCycleEarlyEnd = nil
                data.Cycle[#data.Cycle].Repeats = 0
                data.AttackCooldown = 0

                if REVEL.DEBUG then
                    REVEL.DebugLog("Triggered phase damage end")
                end
            end

            if doNextAttack then
                local belowHpTreshold1 = npc.HitPoints < npc.MaxHitPoints * data.bal.MidHpPct
                local useCycle = isHeadless(npc) and data.bal.HeadlessCycle
                                 or (belowHpTreshold1 and data.bal.MidHeadCycle or data.bal.StartHeadCycle)

                if data.bal.DebugCycle and #data.bal.DebugCycle > 0 then
                    useCycle = data.bal.DebugCycle
                end

                if data.PrevCycle ~= useCycle then data.Cycle = nil end

                data.PrevCycle = useCycle
                data.ReboundChasePlayer = data.bal.RebounderAlwaysChases
                
                local curCycle, isAttacking, attack, cooldown, changedPhase = REVEL.ManageAttackCycle(data, data.bal, useCycle, npc, REVEL.ENT.LIGHTABLE_FIRE:getInRoom())
                if isAttacking then
                    REVEL.AnnounceAttack(data.bal.AttackNames[attack] or attack)
                    if data.bal.AttackStartAnims[attack] then
                        sprite:Play(data.bal.AttackStartAnims[attack], true)
                    end
                    if data.bal.AttackStartHeadAnims[attack] and data.Head then
                        data.Head:GetSprite():Play(data.bal.AttackStartHeadAnims[attack], true)
                    end

                    data.NoWaitForFireEnd = curCycle.NoWaitForFireEnd

                    if data.PrevAttack == attack then
                        data.SameAttackCounter = (data.SameAttackCounter or 0) + 1
                    else
                        data.SameAttackCounter = 0
                        data.PrevAttack = attack
                    end

                    data.PermaRebound = curCycle.PermaRebound or (curCycle.RepeatTimesForPermaRebound and data.SameAttackCounter >= curCycle.RepeatTimesForPermaRebound)

                    doChase = curCycle.KeepChasing

                    if curCycle.DamagePctForEarlyEnd then
                        data.HPForCycleEarlyEnd = npc.HitPoints - npc.MaxHitPoints * curCycle.DamagePctForEarlyEnd
                    else
                        data.HPForCycleEarlyEnd = nil
                    end

                    data.AttackCooldown = cooldown

                    if curCycle.HeadAttack then
                        data.Head:GetData().State = attack
                    end
                    if not (curCycle.NoBodyAttack or data.bal.NoBodyCycle) then
                        data.State = attack
                    end
                end
            end
        elseif data.State == "Rebounder" then
            if sprite:IsPlaying("Slide Charge") then
                local fires = getOnFires()
                local goodOnes = {}
                for i, player in ipairs(REVEL.players) do
                    for j, fire in ipairs(fires) do
                        --if player is behind a fire
                        if math.abs((fire.Position - npc.Position):GetAngleDegrees() - (player.Position - npc.Position):GetAngleDegrees()) < 4 then
                        --and (player.Position - fire.Position):Dot(npc.Position - fire.Position) < 0 then --prevent activation when player is between fire and boss
                            goodOnes[#goodOnes + 1] = fire
                        end
                    end
                end

                if #goodOnes > 0 then
                    local fire = REVEL.getClosestInTable(goodOnes, npc)
                    sprite:Play("Fire", true)
                    data.TargetFire = fire
                end
            end

            if sprite:IsPlaying("Fire") and sprite:IsEventTriggered("Fire") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1.05)
                shootBulletFire(npc, npc.Position, (data.TargetFire.Position - npc.Position):Resized(12.5), data.TargetFire)
            end

            if sprite:IsFinished("Slide Charge") or sprite:IsFinished("Fire") then
                sprite:Play("Slide Start", true)
                data.CollideCount = 0
            end
            if sprite:IsFinished("Slide Start") then
                sprite:Play("Slide", true)
            end

            if sprite:IsEventTriggered("Stomp") and sprite:IsPlaying("Slide Start") then
                data.SlideDir = (target.Position - npc.Position):Normalized()
                npc.Velocity = data.SlideDir * data.bal.SlideStartSpd
                data.PrevVel = npc.Velocity
            end

            if sprite:IsPlaying("Slide") or (sprite:IsPlaying("Slide Start") and sprite:WasEventTriggered("Stomp")) then
                local hitFire = collidesWithFire(npc)

                if hitFire then
                    local numOnFires = #getOnFires()

                    if not (data.PermaRebound and numOnFires > 1) then
                        data.HitFire = hitFire
                        data.State = "Chase"
                        sprite:Play("Hit Fire", true)
                    end

                    REVEL.sfx:NpcPlay(hitFire:ToNPC(), SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)

                    if numOnFires <= 1 then
                        spawnFreezerBurnHead(npc, npc.Velocity * 2, data)
                        sprite:Play("Headless Hit Fire", true)
                        REVEL.JumpToCycle(data, 1)
                    end

                    if not data.Finale then
                        npc.Velocity = (npc.Position - hitFire.Position):Resized(10)
                        REVEL.Glacier.ShutdownLightableFire(hitFire)
                    end

                elseif npc:CollidesWithGrid() then
                    if not data.WasColliding then
                        REVEL.game:ShakeScreen(5)
                        REVEL.sfx:Play(48, 1, 0, false, 1)

                        local doCollision = true

                        if data.CollideCount >= data.bal.RebounderCollisions then
                            if data.PermaRebound then
                                data.ReboundChasePlayer = true
                            else
                                data.State = "Chase"
                                doCollision = false
                            end
                        end
                        if doCollision then
                            data.CollideCount = data.CollideCount + 1

                            local normal = REVEL.GetCardinal((npc.Velocity - data.PrevVel):Normalized())

                            npc.Velocity = data.PrevVel
                            npc.Velocity = npc.Velocity - normal * (2 * npc.Velocity:Dot(normal)) -- reflect the velocity along the normal
                            data.SlideDir = npc.Velocity:Normalized()
                            REVEL.game:ShakeScreen(5)

                            if not data.PermaRebound and data.bal.DisableChaseOnReboundCollision then
                                data.ReboundChasePlayer = nil
                            end
                            if data.PermaRebound then
                                npc.Velocity = npc.Velocity:Rotated(math.random(-25, 25)) * 1.5
                            end
                        end
                        data.WasColliding = true
                    end
                else
                    if data.WasColliding then
                        data.WasColliding = nil
                    end

                    if data.ReboundChasePlayer then
                        npc.Velocity = npc.Velocity * data.bal.SlideFriction + (target.Position - npc.Position):Resized(data.bal.SlideAccel)
                    else
                        npc.Velocity = npc.Velocity * data.bal.SlideFriction + data.SlideDir * data.bal.SlideAccel
                    end

                    data.PrevVel = npc.Velocity
                end
            else
                npc.Velocity = npc.Velocity * 0.8
            end

        elseif data.State == "MeltyRebounder" then
            if sprite:IsPlaying("Slide Charge") then
                local fires = getOnFires()
                local goodOnes = {}
                for i, player in ipairs(REVEL.players) do
                    for j, fire in ipairs(fires) do
                        --if player is behind a fire
                        if math.abs((fire.Position - npc.Position):GetAngleDegrees() - (player.Position - npc.Position):GetAngleDegrees()) < 4 then
                        --and (player.Position - fire.Position):Dot(npc.Position - fire.Position) < 0 then --prevent activation when player is between fire and boss
                            goodOnes[#goodOnes + 1] = fire
                        end
                    end
                end

                if #goodOnes > 0 then
                    local fire = REVEL.getClosestInTable(goodOnes, npc)
                    sprite:Play("Fire", true)
                    data.TargetFire = fire
                end
            end

            if sprite:IsPlaying("Fire") and sprite:IsEventTriggered("Fire") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1.05)
                shootBulletFire(npc, npc.Position, (data.TargetFire.Position - npc.Position):Resized(12.5), data.TargetFire)
            end

            if sprite:IsFinished("Slide Charge") or sprite:IsFinished("Fire") then
                sprite:Play("Slide Start", true)
                data.CollideCount = 0
                data.MeltCount = 0
            end
            if REVEL.MultiFinishCheck(sprite, "Slide Start", "SlideReform") then
                sprite:Play("Slide", true)
            end

            if sprite:IsEventTriggered("Stomp") and sprite:IsPlaying("Slide Start") then
                data.SlideDir = (target.Position - npc.Position):Normalized()
                npc.Velocity = data.SlideDir * data.bal.SlideStartSpd
                data.PrevVel = npc.Velocity
            end

            if sprite:IsFinished("SlideMelt") and not data.TimeToReform then
                data.TimeToReform = data.bal.MeltyRebounder.TimeToReform
            end
            if data.TimeToReform then
                if data.TimeToReform <= 0 then
                    data.TimeToReform = nil
                    local baseAngle = target.Velocity:GetAngleDegrees()
                    local angle = baseAngle + (math.random() ^ 2) * data.bal.MeltyRebounder.RandomAngleSpread --random angle more likely to be in the player's moving direction
                    npc.Position = Isaac.GetFreeNearPosition(REVEL.room:GetClampedPosition(target.Position + Vector.FromAngle(angle) * 80, npc.Size + 10), 10)
                    npc.Velocity = Vector.Zero
                    sprite:Play("SlideReform", true)
                else
                    data.TimeToReform = data.TimeToReform - 1
                end
            end

            if sprite:IsPlaying("SlideReform") and sprite:IsEventTriggered("Stomp") then
                data.SlideDir = (target.Position - npc.Position):Normalized()
                npc.Velocity = data.SlideDir * data.bal.SlideStartSpd
                data.PrevVel = npc.Velocity
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end

            if REVEL.MultiPlayingCheck(sprite, "Slide", "SlideMelt") or (REVEL.MultiPlayingCheck(sprite, "Slide Start", "SlideReform") and sprite:WasEventTriggered("Stomp")) then
                local hitFire = collidesWithFire(npc)

                if hitFire then
                    local numOnFires = #getOnFires()

                    if not (data.PermaRebound and numOnFires > 1) and not data.Finale then
                        data.HitFire = hitFire
                        data.State = "Chase"
                        data.ReboundChasePlayer = nil
                        sprite:Play("Hit Fire", true)
                    end

                    REVEL.sfx:NpcPlay(hitFire:ToNPC(), SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)

                    if not data.Finale then
                        REVEL.Glacier.ShutdownLightableFire(hitFire)
                        npc.Velocity = (npc.Position - hitFire.Position):Resized(10)
                    end

                    if numOnFires <= 1 then
                        spawnFreezerBurnHead(npc, npc.Velocity * 2, data)
                        sprite:Play("Headless Hit Fire", true)
                        REVEL.JumpToCycle(data, 1)
                    end
                else
                    if ((data.MeltCount < data.bal.MeltyRebounder.NumMelts and not data.Finale)
                    or (data.PermaRebound and not data.bal.MeltyRebounder.PermaDoesRebounds)
                    or (data.MeltCount < data.bal.MeltyRebounder.MeltsBetweenBoundsAtFinale and data.Finale))
                    and not sprite:IsPlaying("SlideMelt") then
                        local velDir = npc.Velocity:Normalized()
                        local perp = velDir:Rotated(90)
                        local aboutToCollide = false

                        for i = -1, 1 do
                            local origin = npc.Position + perp * (npc.Size * i)
                            local rayStart = origin + velDir * 20
                            local rayEnd = rayStart + velDir * 80

                            if not REVEL.room:CheckLine(rayStart, rayEnd, 0, 1000, false, false) then
                                aboutToCollide = true
                                break
                            end
                        end

                        if aboutToCollide then
                            data.MeltCount = data.MeltCount + 1
                            sprite:Play("SlideMelt", true)
                            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

                            if data.Finale and data.bal.MeltyRebounder.MeltsBetweenBoundsAtFinale > -1 then
                                data.CollideCount = 0
                            end
                        end
                    end

                    if sprite:IsPlaying("SlideMelt") then
                        local nextPos = npc.Position + npc.Velocity
                        if not REVEL.room:IsPositionInRoom(nextPos, 30) then
                            npc.Velocity = npc.Velocity * 0.8
                        end
                    end

                    if npc:CollidesWithGrid() and not sprite:IsPlaying("SlideMelt") then
                        if not data.WasColliding then
                            REVEL.game:ShakeScreen(5)
                            REVEL.sfx:Play(48, 1, 0, false, 1)
                            local reflect = true

                            if (data.CollideCount >= data.bal.RebounderCollisions and not data.Finale) or (data.CollideCount >= data.bal.MeltyRebounder.BoundsBetweenMeltsAtFinale - 1 and data.Finale) then
                                if data.Finale and data.bal.MeltyRebounder.BoundsBetweenMeltsAtFinale > -1 then
                                    data.MeltCount = 0
                                elseif data.PermaRebound then
                                    data.ReboundChasePlayer = true
                                    reflect = false
                                else
                                    data.State = "Chase"
                                    data.ReboundChasePlayer = nil
                                    reflect = false
                                end
                            end
                            if reflect then
                                data.CollideCount = data.CollideCount + 1

                                local normal = REVEL.GetCardinal((npc.Velocity - data.PrevVel):Normalized())

                                npc.Velocity = data.PrevVel
                                npc.Velocity = npc.Velocity - normal * (2 * npc.Velocity:Dot(normal)) -- reflect the velocity along the normal
                                data.SlideDir = npc.Velocity:Normalized()
                                REVEL.game:ShakeScreen(5)
                            end
                            data.WasColliding = true
                        end
                    else
                        if data.WasColliding then
                            data.WasColliding = nil
                        end

                        if data.ReboundChasePlayer then
                            npc.Velocity = npc.Velocity * data.bal.SlideFriction + (target.Position - npc.Position):Resized(data.bal.SlideAccel)
                        else
                            npc.Velocity = npc.Velocity * data.bal.SlideFriction + data.SlideDir * data.bal.SlideAccel
                        end

                        data.PrevVel = npc.Velocity
                    end
                end
            else
                npc.Velocity = npc.Velocity * 0.8
            end

        elseif data.State == "Fireworks" then
            npc.Velocity = npc.Velocity * 0.9

            if not isHeadless(npc) then
                if data.NoWaitForFireEnd then
                    data.State = "Chase"
                else
                    REVEL.PlayIfNot(sprite, "Idle", true)
    
                    if not areThereSuperFires() then
                        data.State = "Chase"
                    end
                end
            end
        elseif data.State == "Finale" then
            npc.Velocity = npc.Velocity * 0.9
            if sprite:IsEventTriggered("Fire") then
                local fires = REVEL.ENT.LIGHTABLE_FIRE:getInRoom()

                for _, fire in pairs(fires) do
                    --shoot super fire that super-activates lightable fires
                    fireFireAtFire(npc, fire, 30, true, false, true)
                end

                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1)

            elseif sprite:IsFinished("Fire") then
                data.State = "Chase"
            end
        elseif data.State == "Death" then --somehow skipped death anim
            npc:Die()
            if data.Head then
                data.Head:Die()
            end
            return
        end

        if doChase then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        else
            REVEL.StopUsingPathMap(REVEL.GenericChaserPathMap, npc)
        end

        if doChase and data.Path then
            local friction, accel, walkAnims

            if isHeadless(npc) then
                friction, accel = data.bal.HeadlessChaseFriction, data.bal.HeadlessChaseAccel
                walkAnims = data.bal.HeadlessWalkAnims
            else
                friction, accel = data.bal.ChaseFriction, REVEL.Lerp2Clamp(0, data.bal.ChaseAccel, data.StateFrame / 30)
                walkAnims = data.bal.WalkAnims
            end

            REVEL.FollowPath(npc, accel, data.Path, true, friction)

            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, walkAnims, false, false, walkAnims.Idle)

            if not data.bal.ChaseImmuneToFires then
                local hitFire = collidesWithFire(npc)

                if hitFire then
                    data.HitFire = hitFire
                    sprite:Play("Hit Fire", true)

                    npc.Velocity = (npc.Position - hitFire.Position):Resized(10)

                    REVEL.Glacier.ShutdownLightableFire(hitFire)
                end
            end
        else
            if doChase then
                npc.Velocity = npc.Velocity * 0.9
            end
            sprite.PlaybackSpeed = 1
        end

        if data.Finale then
            local firstTime, firstAlign --to make sure all fires are synced
            for _, fire in pairs(getOnFires()) do
                firstTime = firstTime or fire:GetData().SuperFireTime
                if not firstAlign then
                    firstAlign = fire:GetData().LastWasAxisAligned
                else
                    fire:GetData().LastWasAxisAligned = firstAlign
                end

                if fire:GetData().SuperFireTime == 1 then
                    fire:GetData().SuperFireTime = data.bal.Finale.SuperFireShootTime * 2 + 1
                elseif fire:GetData().SuperFireTime ~= firstTime then
                    fire:GetData().SuperFireTime = firstTime
                end
            end
        end
    end

    --Head update
    local function FreezerBurnHeadUpdate(npc, data, sprite, target)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS

        if sprite:IsPlaying("Appear") then return end

        if not data.NoBodyRequired and (not data.Body or not data.Body:Exists()) then
            npc:Die()
            return  
        end

        if data.State == "Death" then
            REVEL.PlayIfNot(sprite, "Idle")
            npc.Velocity = npc.Velocity * 0.9

        elseif data.State == "Escape" then
            REVEL.PlayIfNot(sprite, "Idle")

            if data.bal.HeadChases and (data.bal.HeadChasesDuringFireworks or not areThereSuperFires()) then
                npc.Velocity = npc.Velocity * data.bal.HeadFriction + (target.Position - npc.Position):Resized(data.bal.HeadAccel)
            else
                if not REVEL.IsUsingPathMap(REVEL.PathToPlayerMap, npc) then
                    REVEL.UsePathMap(REVEL.PathToPlayerMap, npc)
                end

                data.Path = REVEL.GeneratePathAStar(REVEL.room:GetGridIndex(npc.Position), REVEL.PathToPlayerMap.TargetMapSets[1].FarthestIndex)
                data.PathIndex = nil

                if data.Path and #data.Path == 0 then
                    data.Path = nil
                end

                if data.Path then
                    REVEL.FollowPath(npc, data.bal.HeadAccel, data.Path, true, data.bal.HeadFriction)
                else
                    npc.Velocity = npc.Velocity * data.bal.HeadFriction
                end
            end

        elseif data.State == "HeadShoot" then
            npc.Velocity = npc.Velocity * 0.8

            if data.StateFrame >= data.bal.HeadShoot.TimeBeforeShoot and not IsAnimOn(sprite, "Fire") then
                sprite:Play("Fire", true)
                data.HeadShootShotsLeft = data.bal.HeadShoot.ShotAmount
                data.HeadShootAngleOffset = 0
            end

            if sprite:IsEventTriggered("Fire") then
                local num = data.bal.HeadShoot.FireNum
                if type(num) == "table" then
                    num = math.random(data.bal.HeadShoot.FireNum.Min, data.bal.HeadShoot.FireNum.Max)
                end

                for i = 1, num do
                    local angle = 360 * i / num + data.HeadShootAngleOffset
                    if data.bal.HeadShoot.ShotRandomSpread > 0 then
                        angle = angle + math.random(-data.bal.HeadShoot.ShotRandomSpread / 2, data.bal.HeadShoot.ShotRandomSpread / 2)
                    end

                    local fire = shootBulletFire(npc, 
                        npc.Position,
                        Vector.FromAngle(angle) * data.bal.HeadShoot.ShotSpeed, 
                        nil, 
                        true, 
                        data.bal.HeadShoot.ShotFriction, 
                        false, 
                        Vector.FromAngle(angle + 90) * data.bal.HeadShoot.ShotSpeed, 
                        data.bal.HeadShoot.FinalSpeedTime, 
                        nil, 
                        data.bal.HeadShoot.BulletScale)
                    REVEL.DelayFunction(data.bal.HeadShoot.TimeBeforeShotShrink, function() fire:GetData().Shrinking = true end)
                end
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1.05)
            elseif sprite:IsFinished("Fire") then
                data.HeadShootShotsLeft = data.HeadShootShotsLeft - 1
                if data.HeadShootShotsLeft <= 0 then
                    data.State = "Escape"
                else
                    data.HeadShootAngleOffset = data.HeadShootAngleOffset + data.bal.HeadShoot.RotationAfterShots
                    sprite:Play("Fire", true)
                end
            end

        elseif data.State == "Fireworks" then
            if data.StateFrame >= data.bal.Fireworks.TimeBeforeShoot and not data.Shot then
                sprite:Play("Fire", true)
                data.Shot = true
            end

            if sprite:IsEventTriggered("Fire") then
                local fires = getOffFires()

                for _, fire in pairs(fires) do
                    --shoot super fire that super-activates lightable fires
                    fireFireAtFire(npc, fire, 30, data.bal.Fireworks.DoSuperFires, data.bal.Fireworks.ShutOffFiresAfter)
                end

                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1)

            elseif sprite:IsFinished("Fire") then
                sprite:Play("Idle", true)
            elseif sprite:IsPlaying("Idle") then
                if data.bal.HeadAlwaysOff then
                    data.State = "Escape"
                    data.Shot = nil
                else
                    npc.Velocity = npc.Velocity * 0.9 + (data.Body.Position - npc.Position):Resized(0.5)

                    if npc.Position:DistanceSquared(data.Body.Position) <= (data.Body.Size + npc.Size) ^ 2 then
                        data.Body:GetData().Head = nil
                        npc:Remove()
                    end
                end
            end
        end
    end

    --Both head and body updates
    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if not (REVEL.ENT.FREEZER_BURN:isEnt(npc) or REVEL.ENT.FREEZER_BURN_HEAD:isEnt(npc)) then return end

        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        if REVEL.ENT.FREEZER_BURN:isEnt(npc) then
            FreezerBurnUpdate(npc, data, sprite, target)
        else
            FreezerBurnHeadUpdate(npc, data, sprite, target)
        end

        if data.PrevState ~= data.State then
            data.StateFrame = 0
            data.PrevState = data.State
        else
            data.StateFrame = data.StateFrame + 1
        end
    end, REVEL.ENT.FREEZER_BURN.id)
	
	revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
		if not REVEL.ENT.FREEZER_BURN:isEnt(npc) or not REVEL.IsRenderPassNormal() then 
            return 
        end
        
		local data = npc:GetData()
		if not data.Dying and npc:HasMortalDamage() then
            npc.HitPoints = 0
            local sprite = npc:GetSprite()
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.Velocity = Vector.Zero
			npc:RemoveStatusEffects()
            if isHeadless(npc) then
                data.Head:GetData().State = "Death"
                if not sprite:IsPlaying("Headless Die") and not sprite:IsFinished("Headless Die") then
                    sprite:Play("Headless Die", true)
                end
            elseif not sprite:IsPlaying("Default Die") and not sprite:IsFinished("Default Die") then
                sprite:Play("Default Die", true)
            end
            data.State = "Death"
			data.Dying = true
			npc.State = NpcState.STATE_UNIQUE_DEATH
		end
    end, REVEL.ENT.FREEZER_BURN.id)

    local softDamageColor = Color(1,1,1,1,conv255ToFloat(55,15,15))
        
    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flag, source, cool)
        if not REVEL.ENT.FREEZER_BURN:isEnt(ent) then return end

        local data = ent:GetData()

        if data.TakingDamageFB then return end

        --Hit by fire
        if source and source.Type == 33 then
            local srcEnt = REVEL.GetEntFromRef(source)
            if srcEnt and srcEnt:GetData().LightableFireFire then
                if not (data.bal.ChaseImmuneToFires and data.State == "Chase") then
                    data.JustHitFire = srcEnt:GetData().LightableFireFire
                    data.TakingDamageFB = true
                    --keeping the fire flag makes calling damage two times not work for some reason
                    local dmgPct = data.bal.DefaultFireDamageHpPercent
                    if data.Finale then
                        dmgPct = data.bal.Finale.FireDamageHpPercent
                    end
                    ent:TakeDamage(ent.MaxHitPoints * dmgPct, 0, source, cool)
                    data.TakingDamageFB = nil
                end
                return false
            end
        elseif not isHeadless(ent) and not data.Finale then
            local newDmg = dmg * (1 - data.bal.NonHeadlessDamageResist)
            data.TakingDamageFB = true
            ent:TakeDamage(newDmg, flag, source, cool)
            data.TakingDamageFB = nil

            REVEL.sfx:NpcPlay(ent:ToNPC(), SoundEffect.SOUND_MEAT_IMPACTS, 0.5, 0, false, 1.5)
            ent:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
            ent:SetColor(softDamageColor, 3, 50, true, false)
            REVEL.DelayFunction(1, function() ent:ClearEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE) end, nil, true)
            return false
        end
    end, REVEL.ENT.FREEZER_BURN.id)

    REVEL.AddDeathEventsCallback(function(npc)
        npc.SplatColor = REVEL.SnowSplatColor
        npc:BloodExplode()
    end,
    function (npc, triggeredEventThisFrame)
        local sprite = npc:GetSprite()
        if (sprite:IsFinished("Default Die") or sprite:IsFinished("Headless Die")) and not triggeredEventThisFrame then
            npc:BloodExplode()
            return true
        end
    end, REVEL.ENT.FREEZER_BURN.id, REVEL.ENT.FREEZER_BURN.variant)

    local pendingFires = {}
    local numFiresToActivate = -1

    local SuperFireStartDuration = 34

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
        local data = eff:GetData()
    
        if data.SpecialFire or data.FreezerburnFire then
            for _, player in ipairs(REVEL.players) do
                local dist = player.Position:Distance(eff.Position)
                local sizeCheck = player.Size + eff.Size
                if dist < sizeCheck and (not data.Scale or data.Scale > 0.35) then
                    player:TakeDamage(1, DamageFlag.DAMAGE_FIRE, EntityRef(eff), 30)
                end
            end
    
            if data.FreezerburnFire and not data.NoTargetFires then
                local fires = REVEL.ENT.LIGHTABLE_FIRE:getInRoom()
                for _, fire in ipairs(fires) do
                    if not data.TargetFire or (data.TargetFire and GetPtrHash(data.TargetFire) == GetPtrHash(fire))   
                    and fire.Position:DistanceSquared(eff.Position) <= (eff.Size + fire.Size) ^ 2 then
                        if data.Super then
                            numFiresToActivate = math.max(numFiresToActivate, #data.SyncSuperFires)
                            pendingFires[#pendingFires + 1] = {Fire = fire, Duration = data.SuperFireDuration, ShutdownAfter = data.ShutdownAfterSuper, ShootTime = 15}
                            REVEL.FadeEntity(eff, 15)
                            data.NoTargetFires = true
                            data.Friction = 0.3
                        else
                            if REVEL.Glacier.IsLightableFireOn(fire) then
                                for i = -1, 1, 2 do
                                    shootBulletFire(eff.SpawnerEntity, fire.Position, eff.Velocity:Rotated(45 * i), nil, true, nil, nil, eff.Velocity, 15)
                                end
                                REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
                                data.NoTargetFires = true
                            else
                                data.NoTargetFires = true
                                REVEL.Glacier.ActivateLightableFire(fire)
                                data.Friction = 0.3
                                REVEL.FadeEntity(eff, 15)
                            end
                        end
                    end
                end
            end

            if data.EndVelocity then
                eff.Velocity = REVEL.Lerp2Clamp(data.StartVelocity, data.EndVelocity, data.TimeToEndVel, data.TimeToEndVelStart, 0)
                data.TimeToEndVel = data.TimeToEndVel - 1
                if data.TimeToEndVel < 0 then
                    data.EndVelocity = nil
                end
            end
    
            if data.Friction then
                eff.Velocity = eff.Velocity * data.Friction
                if data.EndVelocity then
                    data.EndVelocity = data.EndVelocity * data.Friction
                end
            end
    
            if data.Shrinking then
                if not data.Scale then
                    data.Scale = 1
                    data.OriginalSize = eff.Size
                end
    
                data.Scale = data.Scale - (data.ShrinkSpeed or 0.02)
    
                if data.Scale <= 0 then
                    eff:Remove()
                else
                    eff.Size = data.OriginalSize * data.Scale
                    eff.SpriteScale = Vector.One * data.Scale
                end
            end
    
            if not REVEL.room:IsPositionInRoom(eff.Position, -256) then
                eff:Remove()
            end
        end
    end, EffectVariant.LADDER) -- Used by narc 1 / data.SpecialFire
    
    
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if #pendingFires == numFiresToActivate then
            for _, fireData in pairs(pendingFires) do
                local fire = fireData.Fire
                if REVEL.Glacier.IsLightableFireOn(fire) then
                    local toPlay = "SuperFlickeringStart" .. ((fire:GetData().Type == 1) and "" or fire:GetData().Type)
                    fire:GetData().FloorEffect:GetSprite():Play(toPlay, true)
                    fire:GetSprite():Play(toPlay, true)
                    fire:GetData().ShutdownAfterSuper = fireData.ShutdownAfter
                    fire:GetData().SuperFireCooldown = fireData.Duration
                else
                    REVEL.Glacier.ActivateLightableFire(fire, nil, nil, fireData.Duration, fireData.ShutdownAfter)
                end
                fire:GetData().SuperFireTime = fireData.ShootTime
            end

            pendingFires = {}
            numFiresToActivate = -1
        end
    end)

    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
        pendingFires = {}
        numFiresToActivate = -1
    end)
end