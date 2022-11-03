REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

StageAPI.AddBossToBaseFloorPool({BossID = "Punker", Weight = 1}, LevelStage.STAGE2_1, StageType.STAGETYPE_ORIGINAL)
StageAPI.AddBossToBaseFloorPool({BossID = "Punker", Weight = 2}, LevelStage.STAGE2_1, StageType.STAGETYPE_AFTERBIRTH)

local punkerBalance = {
    Champions = {Poop = "Default", Ruthless = "Default"},
	Spritesheet = {
		Default = false,
		Poop = "gfx/bosses/revelcommon/punker/punker_poop.png",
		Ruthless = "gfx/bosses/revelcommon/punker/punker_ruthless.png"
	},

    AttackCooldowns = {
        DefaultCooldown = {
            Default = {
                Min = 30,
                Max = 45
            },
            Ruthless = {
                Min = 45,
                Max = 60
            }
        },
        BigShot = {
            Default = {
                Min = 60,
                Max = 75
            },
            Ruthless = {
                Min = 90,
                Max = 105
            }
        },
        CreepStart = {
            Default = {
                Min = 30,
                Max = 45
            },
            Ruthless = {
                Min = 135,
                Max = 150
            }
        },
        StartBrimstone = {
            Min = 60,
            Max = 75
        }
    },

    CreepLength = {
        Default = {
            Min = 120,
            Max = 180
        },
        Poop = {
            Min = 45,
            Max = 90
        },
        Ruthless = {
            Min = -1,
            Max = 0
        }
    },
    CreepFriction = {
        Default = 0.97,
        Poop = 0.98
    },
    CreepAcceleration = {
        Default = 0.35,
        Poop = 0.7
    },
    CreepSpawnFrequency = 5,
    CreepTimeout = {
        Default = 100,
        Poop = 200
    },
    CreepProjectileCount = {
        Min = 12,
        Max = 16
    },
    CreepProjectileSpeed = {
        Min = 4,
        Max = 10
    },
    CreepFinalTimeout = {
        Default = 125,
        Poop = 250,
        Ruthless = 300
    },
    CreepFinalSize = {
        Default = 2,
        Ruthless = 4
    },
    CreepBaitEnding = {
        Default = false,
        Ruthless = true
    },
    CreepBaitBounces = 5,

    DashUpdateAngleFrames = {
        Default = false,
        Ruthless = 8
    },
    DashSkipInbetween = {
        Default = false,
        Ruthless = true
    },
    DashFriction = {
        Default = 0,
        Ruthless = 0.95
    },
    DashAcceleration = {
        Default = 10,
        Ruthless = 1.5
    },
    DashCount = {
        Default = 1,
        Ruthless = 2
    },
    MultiDashCount = {
        Default = 3,
        Ruthless = 4
    },
    DashProjectileFrequency = {
        Default = 2,
        Poop = 4
    },
    DashProjectileVariant = {
        Default = ProjectileVariant.PROJECTILE_NORMAL,
        Poop = ProjectileVariant.PROJECTILE_CORN
    },
    DashProjectileSpread = {
        Default = 30,
        Ruthless = 45
    },
    DashProjectileSpeed = {
        Min = 6,
        Max = 9
    },
    SpawnDashProjectile = function(npc, dir, bal)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
        return Isaac.Spawn(EntityType.ENTITY_PROJECTILE, bal.DashProjectileVariant, 0, npc.Position, dir:Rotated(math.random(-bal.DashProjectileSpread, bal.DashProjectileSpread)) * math.random(bal.DashProjectileSpeed.Min, bal.DashProjectileSpeed.Max), npc)
    end,

    BigShotVelocity = 0.0325,
    BigShotScale = {
        Default = 3.25,
        Poop = 2
    },
    BigShotProjectileCount = {
        Default = 15,
        Poop = 20
    },
    BigShotProjectileMinScale = 1,
    BigShotProjectileMaxExtraScale = 1.1,
    BigShotProjectileFallingSpeed = {
        Default = {
            Min = 7,
            Max = 12
        },
        Poop = {
            Min = 4,
            Max = 11
        }
    },
    BigShotProjectileSpeed = {
        Default = {
            Min = 4,
            Max = 15
        },
        Poop = {
            Min = 4,
            Max = 20
        }
    },
    BigShotProjectileDecel = 0.86,
    PoopBigShotProjectileSpeed = 9,
    BigShotBounces = {
        Default = false,
        Ruthless = 2
    },
    BigShotCreep = {
        Default = false,
        Ruthless = {Size = 2, Timeout = 150}
    },

    BrimstoneRecoil = {
        Default = 2,
        Ruthless = 2.5
    },
    BrimstoneProjectiles = {
        Default = 6,
        Ruthless = 16
    },
    BrimstoneProjectileSpeed = {
        Default = 10,
        Ruthless = 10
    },
    BrimstoneProjectileFallAccel = {
        Default = false,
        Ruthless = -0.035
    },
    BrimstoneProjectileSpread = {
        Default = 90,
        Ruthless = 60
    },

    BasicAttacks = {
        BigShot = {Start = 5, Increase = 1, Decrease = 2, Min = 1},
        CreepStart = {Start = 1, Increase = 1, Decrease = 3},
        StartDash = {Start = 5, Increase = 2, Decrease = 2, Min = 1},
        StartTripleDash = {Start = 1, Increase = 1, Decrease = 4},
        SpecialAttack = {
            Default = {Start = 0, Increase = 0, Decrease = 0},
            Ruthless = {Start = 3, Increase = 2, Decrease = 3}
        }
    },

    -- Ruthless Punker's Special Attack!
    SpecialAttackLength = 35,
    SpecialAttackAngle = {
        StartLeft = 94,
        EndLeft = 150,
        StartRight = 86,
        EndRight = 30,
        FinalLeft = 180,
        FinalRight = 0
    },
    SpecialAttackSpeed = 13,
    SpecialAttackFinalCount = 9,
    SpecialAttackFinalSpread = 45,
    SpecialAttackFallAccel = -0.09,
    SpecialAttackFrequency = 2,
    ConstantCreep = {
        Default = false,
        Ruthless = true
    },
    BouncesIncreaseWithHealth = {
        Default = false,
        Ruthless = 4
    },

    BaseFriction = 0.96,
    IdleFriction = 0.9,
    IdleAcceleration = {
        Default = 0.35,
        Ruthless = 0.45
    },

    -- Punker will slightly favor aligning with the player when moving
    GoodXAlignment = 160,
    GoodYAlignment = 100,
    AlignXReduceY = 0.95,
    AlignXIncreaseX = 0.05,
    AlignYReduceX = 0.95,
    AlignYIncreaseY = 0.05,

    GeneralProjectileDecel = 0.94
}

local function ShootBigProjectile(shooting, target, bal, spawner)
    local dir = target.Position - shooting.Position
    local p

    if bal.Champion == "Poop" then
        p = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_CORN, 0, shooting.Position, dir * bal.BigShotVelocity, spawner or shooting):ToProjectile()
        p:GetData().PunkerPoopShot = true
    else
        p = Isaac.Spawn(9, 0, 0, shooting.Position, dir * bal.BigShotVelocity, spawner or shooting):ToProjectile()
        p:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revelcommon/intense_projectiles.png")
        p:GetSprite():LoadGraphics()
        p:GetData().PunkerBigShot = true
    end

    p:GetData().bal = bal
    p.Scale = bal.BigShotScale
    p.SpawnerEntity = spawner or shooting
    p.Height = -75
    p.FallingSpeed = -20
    p.FallingAccel = 1
    return p, dir
end

local function punker_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.PUNKER.variant then
        return
    end

    npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    local room = REVEL.room
    local liveEnemies = room:GetAliveEnemiesCount()
    local player = npc:GetPlayerTarget()
    local data, sprite = npc:GetData(), npc:GetSprite()

    data.AttackCooldown = data.AttackCooldown or 0

    data.OddFrame = not data.OddFrame

    if not data.Init then
        data.Init = true
        data.State = "Idle"
        data.IsChampion = REVEL.IsChampion(npc)
        if not data.IsChampion then
            if REVEL.IsRuthless() then
                data.bal = REVEL.GetBossBalance(punkerBalance, "Ruthless")
            else
                data.bal = REVEL.GetBossBalance(punkerBalance, "Default")
            end
        else
            data.bal = REVEL.GetBossBalance(punkerBalance, "Poop")
        end

		if data.bal.Spritesheet then
			sprite:ReplaceSpritesheet(0, data.bal.Spritesheet)
			sprite:LoadGraphics()
		end

        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    end

    if data.State ~= "Idle" and data.State ~= "Creep" then
        npc.Velocity = npc.Velocity * data.bal.BaseFriction
    end

    if data.IsChampion then
        for _, dip in ipairs(Isaac.FindByType(EntityType.ENTITY_DIP, 2, -1, false, false)) do
            if dip.FrameCount > 5 and dip.Position:Distance(npc.Position) < npc.Size + dip.Size + 8 then
                dip:Kill()
                local creep = REVEL.SpawnSlipperyCreep(dip.Position, npc, false)
                REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
                creep:ToEffect():SetTimeout(500)
            end
        end

        for _, projectile in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_CORN, -1, false, false)) do
            if projectile:GetData().PunkerSuperPoop then
                if projectile.FrameCount % 4 == 0 then
                    Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_CORN, 0, projectile.Position, Vector.Zero, npc)
                end

                local dir = player.Position - projectile.Position
                projectile:AddVelocity(dir:Resized(0.1))
            end
        end

        if data.CornMines then
            for i, mine in ripairs(data.CornMines) do
                if mine:IsDead() or not mine:Exists() then
                    table.remove(data.CornMines, i)
                else
                    if mine.FrameCount > 10 then
                        mine.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                    end
                end
            end
        end

        if data.TimeSinceHurl then
            data.TimeSinceHurl = data.TimeSinceHurl + 1
        end
    end

    if data.bal.ConstantCreep and npc.FrameCount % data.bal.CreepSpawnFrequency == 0 then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, npc.Position, Vector.Zero, npc)
        creep:ToEffect():SetTimeout(data.bal.CreepTimeout)
    end

    if data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        local playerDiff = player.Position - npc.Position
        local playerDist = playerDiff:Length()

        npc.Velocity = npc.Velocity * data.bal.IdleFriction + (playerDiff / playerDist) * data.bal.IdleAcceleration

        local alignX = math.abs(playerDiff.X)
        local alignY = math.abs(playerDiff.Y)
        if alignX > data.bal.GoodXAlignment or alignY > data.bal.GoodYAlignment then
            if math.abs(alignX - data.bal.GoodXAlignment) > math.abs(alignY - data.bal.GoodYAlignment) then
                npc.Velocity = Vector(npc.Velocity.X + npc.Velocity.X * data.bal.AlignXIncreaseX, npc.Velocity.Y * data.bal.AlignXReduceY)
            else
                npc.Velocity = Vector(npc.Velocity.X * data.bal.AlignYReduceX, npc.Velocity.Y + npc.Velocity.Y * data.bal.AlignYIncreaseY)
            end
        end

        if data.AttackCooldown <= 0 then
            local attacks = {
                StartBrimstone = 0,
                BigShot = 0,
                SpitPucker = 0,
                StartTripleDash = 0,
                StartDash = 0,
                CreepStart = 0,
                StartHurl = 0
            }

            if not data.BasicAttackWeights then
                data.BasicAttackWeights = {}
                for attack, weightData in pairs(data.bal.BasicAttacks) do
                    data.BasicAttackWeights[attack] = weightData.Start
                end
            end

            for attack, weight in pairs(data.BasicAttackWeights) do
                attacks[attack] = weight
            end

            if playerDist < 135 then
                attacks.CreepStart = attacks.CreepStart + 2
            end

            if not room:IsPositionInRoom(npc.Position, 64) or playerDist > 300 then
                attacks.StartDash = attacks.StartDash + 2
                attacks.StartTripleDash = attacks.StartTripleDash + 2
            end

            if data.IsChampion then
                if math.abs(playerDiff.X) < 80 then
                    attacks.SpitPucker = 8
                elseif liveEnemies < 3 then
                    attacks.StartDash = attacks.StartDash + 2
                    attacks.StartTripleDash = attacks.StartTripleDash + 1
                    if liveEnemies < 2 then
                        attacks.StartTripleDash = attacks.StartTripleDash + 3
                    end
                end

                if not data.TimeSinceHurl or data.TimeSinceHurl > 250 then
                    attacks.StartHurl = 6
                end

                if liveEnemies < 5 then
                    attacks.StartDash = attacks.StartDash + 1
                    attacks.StartTripleDash = attacks.StartTripleDash + 1
                end

                if liveEnemies > 5 then
                    attacks.CreepStart = attacks.CreepStart + 2
                elseif liveEnemies < 3 then
                    attacks.CreepStart = 0
                end
            else
                if liveEnemies < 2 then
                    attacks.SpitPucker = 8
                else
                    attacks.StartDash = attacks.StartDash + 2
                    attacks.StartTripleDash = attacks.StartTripleDash + 1
                    if math.random(2) == 1 then
                        attacks.StartTripleDash = attacks.StartTripleDash + 3
                    end
                end

                if math.abs(playerDiff.Y) < 80 then
                    attacks.StartBrimstone = 10
                end

                if data.bal.Champion == "Ruthless" then
                    if npc.Position.Y > REVEL.room:GetCenterPos().Y then
                        attacks.SpecialAttack = 0
                    end
                end
            end

            local atk = REVEL.WeightedRandom(attacks)

            for attack, weight in pairs(data.BasicAttackWeights) do
                local bal = data.bal.BasicAttacks[attack]
                if atk == attack then
                    data.BasicAttackWeights[attack] = data.BasicAttackWeights[attack] - bal.Decrease
                    if bal.Min then
                        data.BasicAttackWeights[attack] = math.max(data.BasicAttackWeights[attack], bal.Min)
                    end
                else
                    data.BasicAttackWeights[attack] = data.BasicAttackWeights[attack] + bal.Increase
                end
            end

            local cooldown = data.bal.AttackCooldowns[atk] or data.bal.AttackCooldowns.DefaultCooldown
            data.AttackCooldown = math.random(cooldown.Min, cooldown.Max)

            data.State = atk

            if atk == "StartTripleDash" then
                data.Dashes = data.bal.MultiDashCount
                data.State = "StartDash"
            elseif atk == "StartDash" then
                data.Dashes = data.bal.DashCount
            elseif atk == "StartBrimstone" or atk == "StartHurl" then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LOW_INHALE, 1, 0, false, 1)
                if player.Position.X < npc.Position.X then
                    data.BrimstoneDirection = "Left"
                else
                    data.BrimstoneDirection = "Right"
                end
            elseif atk == "SpecialAttack" then
                if player.Position.X < npc.Position.X then
                    data.PanDirection = "Left"
                else
                    data.PanDirection = "Right"
                end
            end

            data.SpawnedInDash = 0
        else
            data.AttackCooldown = data.AttackCooldown - 1
        end
    elseif data.State == "SpecialAttack" then
        local isEnding = REVEL.MultiPlayingCheck(sprite, "AttackSpecialLeftEnd", "AttackSpecialRightEnd")
        if REVEL.MultiFinishCheck(sprite, "AttackSpecialLeftEnd", "AttackSpecialRightEnd") then
            data.State = "Idle"
        elseif not isEnding then
            if sprite:IsFinished("AttackSpecialStart") then
                sprite:Play("AttackSpecialDown", true)
            end

            if not REVEL.MultiPlayingCheck(sprite, "AttackSpecialStart", "AttackSpecialDown", "AttackSpecial" .. data.PanDirection) then
                sprite:Play("AttackSpecialStart", true)
            end

            if sprite:WasEventTriggered("Shoot") or not sprite:IsPlaying("AttackSpecialStart") then
                if not data.AttackDuration then
                    data.AttackDuration = 0
                end

                local startAngle = data.bal.SpecialAttackAngle["Start" .. data.PanDirection]
                local endAngle = data.bal.SpecialAttackAngle["End" .. data.PanDirection]
                local percent = data.AttackDuration / data.bal.SpecialAttackLength
                local angle = REVEL.Lerp(startAngle, endAngle, percent)

                if percent > 0.5 and sprite:IsPlaying("AttackSpecialDown") then
                    sprite:Play("AttackSpecial" .. data.PanDirection, true)
                end

                if percent >= 1 then
                    sprite:Play("AttackSpecial" .. data.PanDirection .. "End", true)

                    for i = 0, data.bal.SpecialAttackFinalCount - 1 do
                        local angleOff = REVEL.Lerp(-data.bal.SpecialAttackFinalSpread, data.bal.SpecialAttackFinalSpread, i / (data.bal.SpecialAttackFinalCount - 1))
                        angle = data.bal.SpecialAttackAngle["Final" .. data.PanDirection]
                        local dir = Vector.FromAngle(angle):Rotated(angleOff)
                        local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.DashProjectileVariant, 0, npc.Position, dir * data.bal.SpecialAttackSpeed, npc):ToProjectile()
                        p.FallingAccel = data.bal.SpecialAttackFallAccel
                        p:GetData().NoDecel = true
                    end

                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
                    data.AttackDuration = nil
                else
                    if npc.FrameCount % data.bal.SpecialAttackFrequency == 0 then
                        local dir = Vector.FromAngle(angle)
                        npc.Velocity = npc.Velocity * data.bal.DashFriction + dir * -data.bal.DashAcceleration

                        local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.DashProjectileVariant, 0, npc.Position + dir * 8, dir * data.bal.SpecialAttackSpeed, npc):ToProjectile()
                        p.FallingAccel = data.bal.SpecialAttackFallAccel
                        p:GetData().NoDecel = true

                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
                    end

                    data.AttackDuration = data.AttackDuration + 1
                end
            else
                if player.Position.X < npc.Position.X then
                    data.PanDirection = "Left"
                else
                    data.PanDirection = "Right"
                end
            end
        end
    elseif data.State == "StartHurl" then
        if REVEL.PlayUntilFinished(sprite, "Attack2 " .. data.BrimstoneDirection .. " Start") then
            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
                local angle = 0
                if data.BrimstoneDirection == "Left" then
                    angle = 180
                end

                local dir = Vector.FromAngle(angle)

                local mainProjectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_CORN, 0, npc.Position, dir * 12, npc):ToProjectile()
                mainProjectile.SpawnerEntity = npc
                mainProjectile:AddScale(1)
                mainProjectile.Size = mainProjectile.Size * 3
                mainProjectile.SpriteScale = Vector.One * 3
                mainProjectile.FallingSpeed = 0
                mainProjectile.FallingAccel = -0.05
                mainProjectile:GetData().PunkerSuperPoop = true
                mainProjectile:GetData().bal = data.bal

                npc:AddVelocity(-dir * 10)
            end
        else
            data.TimeSinceHurl = 0
            data.State = "EndHurl"
        end
    elseif data.State == "EndHurl" then
        if not REVEL.PlayUntilFinished(sprite, "Attack2 " .. data.BrimstoneDirection .. " End") then
            data.TimeSinceHurl = 0
            data.BrimstoneDirection = nil
            data.State = "Idle"
        end
    elseif data.State == "StartBrimstone" then
        if REVEL.PlayUntilFinished(sprite, "Attack2 " .. data.BrimstoneDirection .. " Start") then
            if sprite:IsEventTriggered("Shoot") then
                local angle = 0
                if data.BrimstoneDirection == "Left" then
                    angle = 180
                end

                data.LaserDirection = Vector.FromAngle(angle)
                local offset = Vector(-4 * data.LaserDirection.X, -37)
                data.Laser = EntityLaser.ShootAngle(1, npc.Position, angle, 4, offset, npc)

                local endPoint = EntityLaser.CalculateEndPoint(npc.Position, data.LaserDirection, offset, npc, 0) - data.LaserDirection * 15
                local startAngle = (angle + 180) - data.bal.BrimstoneProjectileSpread

                for i = 0, data.bal.BrimstoneProjectiles do
                    local angle = startAngle + (((data.bal.BrimstoneProjectileSpread * 2) / (data.bal.BrimstoneProjectiles - 1)) * i)
                    local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, endPoint, Vector.FromAngle(angle) * data.bal.BrimstoneProjectileSpeed, nil):ToProjectile()
                    if data.bal.BrimstoneProjectileFallAccel then
                        p.FallingAccel = data.bal.BrimstoneProjectileFallAccel
                    end
                end

                data.Laser.DepthOffset = npc.DepthOffset - 1
                data.Laser.RenderZOffset = npc.RenderZOffset - 1
            end

            if sprite:WasEventTriggered("Shoot") and data.Laser then
                npc:AddVelocity(-data.LaserDirection * data.bal.BrimstoneRecoil)
                data.Laser:SetTimeout(4)
            end
        else
            data.State = "Brimstone"
        end
    elseif data.State == "Brimstone" then
        if not sprite:IsPlaying("Attack2 " .. data.BrimstoneDirection .. " Loop") then
            sprite:Play("Attack2 " .. data.BrimstoneDirection .. " Loop", true)
        end

        npc:AddVelocity(-data.LaserDirection * data.bal.BrimstoneRecoil)
        data.Laser:SetTimeout(4)

        if not room:IsPositionInRoom(npc.Position + -data.LaserDirection * 8, 32) then
            local params = ProjectileParams()
            params.VelocityMulti = 1.2
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            npc:FireBossProjectiles(16, Vector.Zero, 0, params)
            data.State = "BrimstoneEnd"
        end
    elseif data.State == "BrimstoneEnd" then
        if REVEL.PlayUntilFinished(sprite, "Attack2 " .. data.BrimstoneDirection .. " End") then
            if not sprite:WasEventTriggered("Stop") then
                npc:AddVelocity(-data.LaserDirection * 2)
                data.Laser:SetTimeout(4)
            else
                data.Laser = nil
                data.LaserDirection = nil
            end
        else
            data.Laser = nil
            data.LaserDirection = nil
            data.BrimstoneDirection = nil
            data.State = "Idle"
        end
    elseif data.State == "BigShot" then
        if not REVEL.PlayUntilFinished(sprite, "Attack1") then
            data.State = "Idle"
        end
    elseif data.State == "StartDash" then
        data.SpawnedInDash = 0
        if not REVEL.PlayUntilFinished(sprite, "DashStart") then
            data.State = "Dash"
        end
    elseif data.State == "Dash" then
        data.DashFrames = data.DashFrames or 0
        data.DashFrames = data.DashFrames + 1
        if data.bal.DashUpdateAngleFrames and data.DashFrames < data.bal.DashUpdateAngleFrames then
            data.RecordedPos = (player.Position - npc.Position):GetAngleDegrees()
            data.ReversedPos = data.RecordedPos + 180
        end

        local wasOriginallyDash = REVEL.MultiPlayingCheck(sprite, "Dash Left", "Dash Up", "Dash Right", "Dash Down")
        local animChange
        local frame = sprite:GetFrame()
        if data.RecordedPos <= 45 and data.RecordedPos >= -45 then -- Right
            if not sprite:IsPlaying("Dash Left") then
                sprite:Play("Dash Left", true)
                animChange = true
            end
        elseif data.RecordedPos <= 135 and data.RecordedPos >= 45 then -- Down
            if not sprite:IsPlaying("Dash Up") then
                sprite:Play("Dash Up", true)
                animChange = true
            end
        elseif data.RecordedPos <= -135 or data.RecordedPos >= 135 then -- Left
            if not sprite:IsPlaying("Dash Right") then
                sprite:Play("Dash Right", true)
                animChange = true
            end
        elseif data.RecordedPos <= -45 and data.RecordedPos >= -135 then -- Up
            if not sprite:IsPlaying("Dash Down") then
                sprite:Play("Dash Down", true)
                animChange = true
            end
        end

        if wasOriginallyDash and animChange and frame > 0 then
            for i = 1, frame do
                sprite:Update()
            end
        end

        if data.IsChampion then
            if data.SpawnedInDash < 3 and sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop") and math.random(1, 5) == 1 then
                local dir = Vector.FromAngle(data.ReversedPos) * 10
                local dip = Isaac.Spawn(EntityType.ENTITY_DIP, 2, 0, npc.Position + dir * 4, dir, npc)
                dip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                data.SpawnedInDash = data.SpawnedInDash + 1
            end
        --[[else
            if liveEnemies < 3 and sprite:IsEventTriggered("Shoot") then
                local dir = Vector.FromAngle(data.ReversedPos) * 10
                local puck = Isaac.Spawn(REVEL.ENT.PUCKER.id, REVEL.ENT.PUCKER.variant, 0, npc.Position + dir * 4, dir, npc)
                puck:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                puck.MaxHitPoints = puck.MaxHitPoints*0.5
                puck.HitPoints = puck.MaxHitPoints
            end]]
        end

        if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop") then
            npc.Velocity = npc.Velocity * data.bal.DashFriction + Vector.FromAngle(data.RecordedPos) * data.bal.DashAcceleration

            if npc.FrameCount % data.bal.DashProjectileFrequency == 0 then
                local dir = Vector.FromAngle(data.ReversedPos)
                data.bal.SpawnDashProjectile(npc, dir, data.bal)
            end
        end
    elseif data.State == "InbetweenDash" then
        data.SpawnedInDash = 0
        if REVEL.MultiFinishCheck(sprite, "Dash Left", "Dash Up", "Dash Right", "Dash Down") then
            data.State = "Dash"
        end
    elseif data.State == "EndDash" then
        if not REVEL.PlayUntilFinished(sprite, "DashEnd") then
            data.State = "Idle"
        end

        npc.Velocity = npc.Velocity * 0.96
    elseif data.State == "SpitPucker" then
        if REVEL.PlayUntilFinished(sprite, "Attack4") then
            if sprite:IsEventTriggered("Grunt") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1)
            end

            if data.IsChampion then
                if sprite:IsEventTriggered("Shoot") then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GURG_BARF, 1, 0, false, 1)
                    local dir = Vector(0, -1) * 15
                    npc.Velocity = dir
                    local dip = Isaac.Spawn(EntityType.ENTITY_DIP, 2, 0, npc.Position - dir * 3, -dir, npc)
                    dip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                end

                if data.SpawnedInDash < 3 and sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Dont Shoot") and math.random(1, 3) == 1 then
                    local dir = Vector(0, 1) * 10
                    local dip = Isaac.Spawn(EntityType.ENTITY_DIP, 2, 0, npc.Position + dir * 4, dir, npc)
                    dip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    data.SpawnedInDash = data.SpawnedInDash + 1
                end
            else
                if liveEnemies < 3 and sprite:IsEventTriggered("Shoot") then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GURG_BARF, 1, 0, false, 1)
                    local dir = Vector(0, -1) * 15
                    local puck = Isaac.Spawn(REVEL.ENT.PUCKER.id, REVEL.ENT.PUCKER.variant, 0, npc.Position - dir * 3, -dir, npc)
                    puck:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    --[[puck.MaxHitPoints = puck.MaxHitPoints*0.5
                    puck.HitPoints = puck.MaxHitPoints]]
                end
            end

            if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Dont Shoot") and npc.FrameCount % data.bal.DashProjectileFrequency == 0 then
                local dir = Vector(0, 1)
                npc.Velocity = npc.Velocity * data.bal.DashFriction + dir * -data.bal.DashAcceleration
                data.bal.SpawnDashProjectile(npc, dir, data.bal)
            end
        else
            data.State = "Idle"
        end
    elseif data.State == "CreepStart" then
        if not REVEL.PlayUntilFinished(sprite, "Attack3 Start") then
            data.State = "Creep"
            data.CreepEndTimer = math.random(data.bal.CreepLength.Min, data.bal.CreepLength.Max)
        end
    elseif data.State == "Creep" then
        if not sprite:IsPlaying("Attack3 Loop") then
            sprite:Play("Attack3 Loop", true)
        end

        local dir = player.Position - npc.Position
        npc.Velocity = npc.Velocity * data.bal.CreepFriction + dir:Resized(data.bal.CreepAcceleration)
        if npc.FrameCount % data.bal.CreepSpawnFrequency == 0 then
            local creep
            if data.IsChampion then
                creep = REVEL.SpawnSlipperyCreep(npc.Position, npc, false)
            else
                creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, npc.Position, Vector.Zero, npc)
            end

            creep:ToEffect():SetTimeout(data.bal.CreepTimeout)
        end

        data.CreepEndTimer = data.CreepEndTimer - 1
        if data.CreepEndTimer <= 0 then
            if data.bal.CreepBaitEnding then
                data.State = "CreepEndBait"
            else
                data.State = "CreepEnd"
            end
        end
    elseif data.State == "CreepEnd" then
        if not REVEL.PlayUntilFinished(sprite, "Attack3 End") then
            data.State = "Idle"
        end
    elseif data.State == "CreepEndBait" then
        if not REVEL.PlayUntilFinished(sprite, "Attack3 End Bait") then
            data.State = "Idle"
        end
    end

    if sprite:IsEventTriggered("Grunt") then
        if data.State == "BigShot" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LOW_INHALE, 1, 0, false, 1)
            npc.Velocity = (player.Position-npc.Position):Normalized()*1.5
        elseif npc.State == "StartTripleDash" then
            local snd = math.random(2)
            if snd == 1 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_1, 1, 0, false, 1)
            elseif snd == 2 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_2, 1, 0, false, 1)
            end
        elseif data.State == "SpitPucker" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1)
        elseif data.State == "CreepEnd" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
        end
    elseif sprite:IsEventTriggered("Stop") then
        data.Dashes = data.Dashes or 0
        data.DashFrames = 0
        data.Dashes = data.Dashes - 1
        if data.Dashes > 0 then
            if data.bal.DashSkipInbetween then
                data.State = "Dash"
                sprite:Stop()
                data.RecordedPos = (player.Position - npc.Position):GetAngleDegrees()
                data.ReversedPos = data.RecordedPos + 180
            else
                data.State = "InbetweenDash"
            end
        else
            data.State = "EndDash"
        end
    elseif sprite:IsEventTriggered("Shoot") then
        if data.State == "BigShot" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
            local p, dir = ShootBigProjectile(npc, player, data.bal)
            p:GetData().Target = player

            if data.bal.CreepBaitBounces then
                p:GetData().Bounces = data.bal.BigShotBounces
                if data.bal.BouncesIncreaseWithHealth then
                    local extraBounces = math.floor(data.bal.BouncesIncreaseWithHealth - (npc.HitPoints / (npc.MaxHitPoints / data.bal.BouncesIncreaseWithHealth)))
                    p:GetData().Bounces = p:GetData().Bounces + extraBounces
                end
            end

            npc.Velocity = (-dir:Normalized()) * 6
        elseif data.State == "CreepStart" or data.State == "CreepEnd" or data.State == "CreepEndBait" then
            if data.State == "CreepStart" then
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            elseif data.State == "CreepEnd" or data.State == "CreepEndBait" then
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 1, 0, false, 1)
            end

            if data.State == "CreepEndBait" then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
                local p, dir = ShootBigProjectile(npc, player, data.bal)
                p:GetData().Target = player
                npc.Velocity = (-dir:Normalized()) * 6
                if data.bal.CreepBaitBounces then
                    p:GetData().Bounces = data.bal.CreepBaitBounces
                    if data.bal.BouncesIncreaseWithHealth then
                        local extraBounces = math.floor(data.bal.BouncesIncreaseWithHealth - (npc.HitPoints / (npc.MaxHitPoints / data.bal.BouncesIncreaseWithHealth)))
                        p:GetData().Bounces = p:GetData().Bounces + extraBounces
                    end
                end
            end

            local params = ProjectileParams()
            if data.IsChampion then
                params.Variant = ProjectileVariant.PROJECTILE_CORN
            end

            for i = 1, math.random(data.bal.CreepProjectileSpeed.Min, data.bal.CreepProjectileSpeed.Max) do
                local p = npc:FireBossProjectiles(1, Vector.Zero, 0, params)
                p.Velocity = RandomVector() * math.random(data.bal.CreepProjectileSpeed.Min, data.bal.CreepProjectileSpeed.Max)
            end

            if data.State == "CreepEnd" or data.State == "CreepEndBait" then
                local creep
                if data.IsChampion then
                    creep = REVEL.SpawnSlipperyCreep(npc.Position, npc, false)

                    if not data.CornMines then
                        data.CornMines = {}
                    end

                    data.CornMines[#data.CornMines + 1] = Isaac.Spawn(EntityType.ENTITY_CORN_MINE, 0, 0, npc.Position, Vector.Zero, npc)
                    data.CornMines[#data.CornMines].EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                else
                    creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc):ToEffect()
                end

                REVEL.UpdateCreepSize(creep, creep.Size * data.bal.CreepFinalSize, true)
                creep:ToEffect():SetTimeout(data.bal.CreepFinalTimeout)
            end
        end
    elseif sprite:IsEventTriggered("Record") then
        data.RecordedPos = (player.Position - npc.Position):GetAngleDegrees()
        data.ReversedPos = data.RecordedPos + 180
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, punker_NpcUpdate, REVEL.ENT.PUNKER.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    -- Punker update
    if (pro.SpawnerType == REVEL.ENT.PUNKER.id and pro.SpawnerVariant == REVEL.ENT.PUNKER.variant) or (pro.SpawnerType == REVEL.ENT.MOTHER_PUCKER.id and pro.SpawnerVariant == REVEL.ENT.MOTHER_PUCKER.variant) then
        local data = pro:GetData()
        if data.Target and not data.Target:Exists() then
            data.Target = nil
        end

        if data.PunkerBigShotgun then
            pro.Velocity = pro.Velocity * data.bal.BigShotProjectileDecel
            if data.PunkerPoopShotgun and pro.FallingSpeed > 0 then
                pro.FallingSpeed = 0.5
            end
        elseif not data.PunkerBigShot and not data.PunkerPoopShot and not data.PunkerSuperPoop and not data.NoDecel then
            if not data.bal then
                data.bal = REVEL.GetBossBalance(punkerBalance, "Default")
            end

            pro.Velocity = pro.Velocity * data.bal.GeneralProjectileDecel
        elseif pro:IsDead() then
            if data.PunkerBigShot then
                local bal = data.bal
                if not bal then
                    bal = REVEL.GetBossBalance(punkerBalance, "Default")
                end

                pro:BloodExplode()
                for i = 1, bal.BigShotProjectileCount do
                    local npro = Isaac.Spawn(9, 0, 0, REVEL.room:GetClampedPosition(pro.Position, 0), RandomVector() * math.random(bal.BigShotProjectileSpeed.Min, bal.BigShotProjectileSpeed.Max), pro.SpawnerEntity):ToProjectile()
                    npro.Scale = math.random() * bal.BigShotProjectileMaxExtraScale + bal.BigShotProjectileMinScale
                    npro.FallingSpeed = math.random(bal.BigShotProjectileFallingSpeed.Min, bal.BigShotProjectileFallingSpeed.Max) * -1
                    npro:GetData().PunkerBigShotgun = true
                    npro:GetData().bal = bal
                end

                if bal.BigShotBounces and data.Target then
                    if bal.BigShotCreep then
                        local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, pro.Position, pro):ToEffect()
                        REVEL.UpdateCreepSize(creep, creep.Size * bal.BigShotCreep.Size, true)
                        creep:ToEffect():SetTimeout(bal.BigShotCreep.Timeout)
                    end

                    if not data.Bounces then
                        data.Bounces = bal.BigShotBounces
                    end

                    if data.Bounces > 0 then
                        local p = ShootBigProjectile(pro, data.Target, bal, pro.SpawnerEntity)
                        p:GetData().Target = data.Target
                        p:GetData().Bounces = data.Bounces - 1
                    end
                end
            elseif data.PunkerSuperPoop then
                local bal = data.bal
                REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.7, 0, false, 1)
                for i = 1, bal.BigShotProjectileCount do
                    local npro = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_CORN, 0, REVEL.room:GetClampedPosition(pro.Position, 10), (-pro.Velocity):Normalized():Rotated(math.random(-90, 90)) * math.random(bal.BigShotProjectileSpeed.Min, bal.BigShotProjectileSpeed.Max), pro.SpawnerEntity):ToProjectile()
                    npro.Scale = math.random(1, 2)
                    npro.FallingSpeed = math.random(bal.BigShotProjectileFallingSpeed.Min, bal.BigShotProjectileFallingSpeed.Max) * -1
                    npro:GetData().PunkerBigShotgun = true
                    npro:GetData().PunkerPoopShotgun = true
                    npro:GetData().bal = bal
                end
            elseif data.PunkerPoopShot then
                REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.7, 0, false, 1)
                local off = math.random(1, 360)
                for i = 1, 5 do
                    Isaac.Spawn(9, ProjectileVariant.PROJECTILE_CORN, 0, pro.Position, Vector.FromAngle(i * 72 + off) * data.bal.PoopBigShotProjectileSpeed, nil)
                end

                Isaac.Spawn(EntityType.ENTITY_CORN_MINE, 0, 0, pro.Position, Vector.Zero, nil)
            end
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()