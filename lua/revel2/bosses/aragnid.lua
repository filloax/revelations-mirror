local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--[[
REVIVAL Aragnid
- Aragnid's top mouth is replaced by a giant necragmancer eye

- Rather than spitting innards, Aragnid roars, causing exactly the amount of innards and rags aragnid needs to fall from the sky.
This also enrages one existing innard, if there are any.

- Aragnid shoots his magic balls like usual, from the eye instead of spat.
They will home onto the closest innard rag first, then the closest normal rag, then the player.

- Aragnid now screams before magic blood rain, agitating one innard and causing many rags to fall throughout the room.

The rain now tracks the player a bit less severely, so that you can walk around the room rather than hide under the boss.
During the rain, reviving magic balls periodically fall onto the rags near the player.

- Uses these rag enemies:
-- Rag gapers & rag drifties (only these are used in blood rain and frenzy)
-- Rag trites
-- Rarely, wretcher

- The Innards are now killable, each only having about 5% of the boss's hp.
- When innards die, from agitation or being attacked, they leave behind a crumpled rag + guts pile,
and shoot a single revival ball into the air in place of a tear volley.
The revival ball homes in on a random other innard pile if one exists,
otherwise targetting the nearest rag pile to the player or the player itself.

- When innards are killed by aragnid jumping on them,
they leave a rag gaper or rag drifty pile and do not shoot a revival ball

RUTHLESS Aragnid
- rather than chasing the player and then exploding upward, innards charge up and dash rapidly at the player, then hit a wall and explode

- aragnid moves up and down as well as left and right, doing a full circle (oval) every 2 cycles.

- intro aragnid has him swinging high off screen, when the player stands in his shadow it shakes and he slams down, then rises back into position

- innards do not fall or get thrown, instead they emerge from the ground

- whenever the player is beneath aragnid he slams down, leaving a rag fatty rag, then rises back into position and performs magic splash, reviving it.

-- aragnid also performs this if there are no revived rag fatties active

-- aragnid's rag fatties are spawned in phase 2, with a silly intro where the head falls from the sky.

- magic splash balls are fired much faster, but don't actually land. instead they hover in place, rapidly falling onto the player if they ever stand under them.

- when enough magic splash balls are out, aragnid shoots lasers out of his eye to break them.

- for mid and final phases, rather than jumping down, aragnid lowers to the player's level and continues swinging back and forth as innards emerge from the ground and immediately dash. during this time, innards can ram into him while dashing, and he deals contact damage to the player.
]]

local tarColor = Color(1, 1, 1, 1)
tarColor:SetColorize(0.7,0.7,0.75,1)

local aragnidBalance = {
    -- 1: regular aragnid  2: ruthless aragnid  3: lovely aragnid  4: skinless aragnid  5: sailor aragnid  6: anime aragnid
    Champions = {Revival = "Default", Ruthless = "Default"},

    FinalArmorMod = {Default = 1},
    IntroArmorMod = .4,

    SwingFrames = {Default = 120, Ruthless = 80},
    SwingHeight = {Default = -60, Ruthless = -70},
    MaxExtraHeight = 10,
    HalfDistanceX = {Default = 120, Ruthless = 110},
    HalfDistanceY = {Default = 0, Ruthless = 30},

    HighJumpAirFrames = 30,
    LowJumpAirFrames = 32 - 13,
    RisingAddHeight = -60,
    FallingOffset = -300,
    FallingSpeed = 8,
    FallingAcceleration = {Default = 0.2, Ruthless = 0.3},

    InitialInnardCount = {Default = 3, Revival = 4},

    InnardSpawnRate = 11,
    InnardAvoidCenterX = {Default = 80},
    InnardAvoidCenterY = {Default = 40},
    InnardCreepFadeTime = 210,
    InnardCreepNum = 9,
    InnardCreepAngleAdd = 200,
    InnardCreepDistance = 25, --45,
    InnardCreepAppearTime = 12, --15,

    InnardExplosionFuse = {Default = 240, Revival = 0}, --120,
    InnardSeekSpeed = {Default = 4.5},
    InnardAccelTime = {Default = 40},

    InnardMinimumDistance = 60, --80, -- from eachother

    ProjectileHeightToHit = {
        Low = 30,
        High = -30
    },
    InnardBurstBlockingSizeMulti = 1.75, -- if distance to projectile < projectile.Size + npc.Size * InnardBurstBlockingSizeMulti, aragnid blocks the burst
    InnardFuseMultiWhenHit = 0.85, -- whenever aragnid is hit by an innard burst, the global innard explosion fuse is multiplied by this
    InnardFuseMinimum = {Default = 60, Revival = 0}, --30,
    InnardBurstDamagePctPerProjectile = 0.165,

    BloodRainInitialAngleOffset = 180, -- projectiles are formed at this angle offset from the line between the boss and the player, so 180 means anywhere on the opposite side of the boss. lerps up to 360 over StartupTime
    BloodRainMinProjectileDistance = 50, -- projectiles start spawning this far from the player, lerps to 0 over startup time
    BloodRainMaxProjectileDistance = 70, --100,
    BloodRainTime = 460, --510,
    BloodRainStartupTime = {Default = 150, Revival = 150},
    BloodRainMaxProjectiles = 1,
    BloodRainMaxProjectilesRate = {Default = 1, Revival = 2},
    BloodRainMinProjectilesRate = 15,
    BloodRainFallingSpeedMin = {Default = 15, Revival = 12},
    BloodRainFallingSpeedMax = {Default = 20, Revival = 16}, --25,
    BloodRainFallingAccel = {Default = 1.2, Revival = 1.1}, --0.9,
    BloodRainStartHeightMin = -350, ---300,
    BloodRainStartHeightMax = -250, ---200,
    BloodRainBlockingSizeMulti = 4, -- if distance to projectile < projectile.Size + npc.Size * BloodRainBlockingSizeMulti, aragnid blocks the rain
    BloodRainDamagePerProjectile = .5,
    BloodRainChanceForProjectileToDamage = 10,
    BloodRainMagicBallRate = {Default = false, Revival = 45},

    RagAnchorOffset = Vector(0, -1000),
    RagAragnidOffset = Vector(15, 0),
    RagIndividualLength = 192,

    TarColor = tarColor,

    AragnidLobFallingSpeedMin = -4.075,
    AragnidLobFallingSpeedMax = -3.925,
    AragnidLobFallingAccel = {Default = 0.20, Ruthless = 0.25},
    AragnidLobStartHeightMin = -25, -- start height is added to spriteoffset.Y
    AragnidLobStartHeightMax = -15,
    AragnidLobVelocityMulti = 0.045,
    AragnidLobVelocityMultiInAir = 0.035,

    AragnidFunkyFallingSpeed = -2,
    AragnidFunkyFallingAccel = 0.08,
    AragnidFunkyFallingSpeedMax = {Default = 4, Ruthless = 8},
    AragnidFunkyTargetDelay = 25,

    AragnidSplashVelocityMult = 1.25,

    ThrowSpiders = {Default = 1, Ruthless = 0},
    ThrowSpidersDuringFrenzy = {Default = 1, Ruthless = 0},

    FrenzyOneThreshold = {Default = .65, Revival = .7, Ruthless = .75},
    FrenzyTwoThreshold = {Default = .3, Revival = .35, Ruthless = .25},

    TwoPi = math.pi * 2,
    Init = function(bal)
        bal.CosModifier = bal.TwoPi / bal.SwingFrames
    end,

    -- CYCLE / ATTACK WEIGHTS
    SubCycles = {
        MagicSplashOnly = {
            {
                Attacks = {
                    MagicSplash = 1
                },
                Repeat = {
                    Default = {Min = 1, Max = 2},
                    Revival = 1,
                    Ruthless = {Min = 3, Max = 4}
                },
                CooldownBetween = {
                    Default = {Min = 15, Max = 30},
                    Ruthless = {Min = 5, Max = 10}
                }
            }
        },
        RupturingScreamOnly = {
            {
                Attacks = {
                    RupturingScream = 1
                },
                Repeat = {Min = 0, Max = 1},
                CooldownBetween = {Min = 45, Max = 60}
            }
        },
        RupturingSplashing = {
            {
                Attacks = {
                    MagicSplash = 1,
                    RupturingScream = 1
                },
                AttackOrder = {"MagicSplash"},
                Repeat = {
                    Default = {2, 4},
                    Ruthless = {4, 6}
                },
                NonRepeatWeight = 100,
                CooldownBetweenByAttack = {
                    MagicSplash = {
                        Default = {Min = 15, Max = 30},
                        Ruthless = {Min = 5, Max = 10}
                    },
                    RupturingScream = {Min = 45, Max = 60}
                }
            }
        },
        MagicBloodRainScreams = {
            {
                Attacks = {
                    MagicBloodRain = 1
                },
                CooldownAfter = 150
            },
            {
                Attacks = {
                    RupturingScream = 1
                },
                Repeat = {Min = 1, Max = 2},
                CooldownBetween = {Min = 15, Max = 30}
            }
        },
        SwingingSlamIntoMagicSplash = {
            {
                AttackOrder = {"SwingingSlam", "MagicSplash"},
                Repeat = 1,
                CooldownBetween = 5
            }
        }
    },
    SwingCycle = {
        {
            Attacks = {
                MagicSplashOnly = 1,
                RupturingScreamOnly = 1
            },
            MaintainInnards = true,
            CheckLaserEyes = true,
            CheckSlam = true,
            NonRepeatWeight = 3,
            CooldownAfterByAttack = {
                RupturingScreamOnly = {Min = 90, Max = 120},
                MagicSplashOnly = {
                    Default = {Min = 60, Max = 90},
                    Revival = {Min = 75, Max = 90},
                    Ruthless = {Min = 45, Max = 60}
                },
                MagicSplash = {Min = 15, Max = 30},
                InnardLaunch = {Min = 30, Max = 45},
                LaserEyes = {Min = 60, Max = 90},
                SwingingSlamIntoMagicSplash = {Min = 75, Max = 100}
            }
        }
    },
    SecondSwingCycle = {
        {
            Attacks = {
                RupturingSplashing = 3,
                MagicBloodRainScreams = {
                    Default = 1,
                    Revival = false,
                    Ruthless = false
                }
            },
            NonRepeatWeight = 2,
            MaintainInnards = true,
            CheckLaserEyes = true,
            CheckSlam = true,
            CooldownAfterByAttack = {
                MagicBloodRainScreams = {Min = 90, Max = 120},
                RupturingSplashing = {
                    Default = {Min = 60, Max = 90},
                    Revival = {Min = 75, Max = 90},
                    Ruthless = {Min = 45, Max = 60}
                },
                MagicSplash = {Min = 15, Max = 30},
                InnardLaunch = {Min = 30, Max = 45},
                LaserEyes = {Min = 60, Max = 90},
                SwingingSlamIntoMagicSplash = {Min = 75, Max = 100}
            }
        }
    },
    SwingCycleFrenzy = {
        {
            Attacks = {
                RupturingScream = 1
            },
            Repeat = {Min = 1, Max = 2},
            CooldownBetween = {Min = 15, Max = 25},
            CooldownAfter = {Min = 45, Max = 75}
        }
    },
    SwingCycleFinale = {
        {
            Attacks = {
                InnardBarrage = 1
            },
            CooldownAfter = {Min = 140, Max = 160}
        },
        {
            Attacks = {
                MagicSplash = 1
            },
            Repeat = {Min = 3, Max = 4},
            CooldownBetween = {Min = 5, Max = 10},
            CooldownAfter = {Min = 45, Max = 75}
        }
    },
    PreCycleSelectAttack = function(data, bal, curCycleSegment, curCycleData, npc, innards)
        if curCycleSegment.MaintainInnards then
            if #innards < data.TargetInnardCount then
                if bal.RupturingScreamReplaceInnardLaunch then
                    local rags = bal.GetInnardRags()
                    if #rags > 0 then
                        return "MagicSplash"
                    else
                        return "RupturingScream"
                    end
                else
                    return "InnardLaunch"
                end
            elseif bal.RupturingScreamRagTypes and (Isaac.CountEntities(nil, REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1) or 0) < 3 then
                return "RupturingScream"
            end
        end

        if bal.Champion == "Ruthless" then
            if curCycleSegment.CheckLaserEyes then
                local laserables = 0
                local projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, false, false)
                for _, projectile in ipairs(projectiles) do
                    local data = projectile:GetData()
                    if data.MagicSplash and projectile:ToProjectile().Height > bal.MagicSplashHoverHeight then
                        laserables = laserables + 1
                    end
                end

                if laserables >= 5 then
                    return "LaserEyes"
                end
            end

            if curCycleSegment.CheckSlam then
                for _, player in ipairs(REVEL.players) do
                    if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size) ^ 2 then
                        return "SwingingSlamIntoMagicSplash"
                    end
                end

                local ragFatties = REVEL.ENT.RAG_FATTY:countInRoom()
                local rags = REVEL.ENT.REVIVAL_RAG:getInRoom()
                for _, rag in ipairs(rags) do
                    if rag:GetData().SpawnID == REVEL.ENT.RAG_FATTY.id and rag:GetData().SpawnVariant == REVEL.ENT.RAG_FATTY.variant then
                        ragFatties = ragFatties + 1
                    end
                end

                if ragFatties == 0 then
                    return "SwingingSlamIntoMagicSplash"
                end
            end
        end
    end,

    -- REVIVAL
    GetInnardRags = function()
        local innardRags = {}
        local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
        for _, rag in ipairs(rags) do
            if rag:GetData().SpawnID == REVEL.ENT.ARAGNID_INNARD.id and rag:GetData().SpawnVariant == REVEL.ENT.ARAGNID_INNARD.variant then
                innardRags[#innardRags + 1] = rag
            end
        end

        return innardRags
    end,

    MagicSplashAngle = {
        Default = 15,
        Revival = 5,
        Ruthless = 10
    },

    GlobalCooldownMult = {Default = 1},
    SplashSeeksRags = {Default = false, Revival = true, Ruthless = true},

    DoRupturingScream = {Default = true, Revival = false},
    DoMagicBloodRain = {Default = true},

    InnardCrushSpawnsRags = {Default = false, Revival = true},

    RupturingScreamReplaceInnardLaunch = {Default = false, Revival = true},

    InnardHealthPercentage = {Default = 1, Revival = 0.04},

    InnardMagicBallReplaceSpider = {Default = false, Revival = true},

    SkipFrenzyFirstHighJump = {Default = false, Revival = true},

    NoMagicBloodRainScreams = {Default = false, Revival = true},

    EternalMagicBloodRain = {Default = false, Revival = true},

    RupturingScreamInFrenzy = {Default = false, Revival = true},

    MaxActiveRagEnemies = {Default = -1, Revival = 1, Ruthless = 1000},

    InnardCrushRagTypes = {
        Default = false,
        Revival = {
            {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
            {REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant}
        }
    },

    RupturingScreamRagTypes = {
        Default = false,
        Revival = {
            {Entity = {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant}, Weight = 6},
            {Entity = {REVEL.ENT.RAG_DRIFTY.id, REVEL.ENT.RAG_DRIFTY.variant}, Weight = 6},
            {Entity = {REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant}, Weight = 8}
        }
    },

    -- RUTHLESS
    InnardDashSpeed = {Default = false, Ruthless = 22.5},
    InnardDashRadial = {
        TotalProjectiles = 24,
        RadialProjectiles = 9,
        RadialSpeed = 10
    },
    InnardDashImpactPercent = 0.025,
    NoLobInnards = {Default = false, Ruthless = true},
    MagicSplashHoverHeight = {Default = false, Ruthless = -80},
    MagicSplashHoverDistance = 70,
    MagicSplashBalls = 1,
    MagicSplashHoming = {
        Rag = {
            Friction = 0.9,
            Speed = 0.85
        },
        Player = {
            Friction = 0.94,
            Speed = {Default = 0.7, Ruthless = 0.2}
        }
    },
    LaserEyesCooldown = {Min = 10, Max = 15},
    IntroSwingHeight = {Default = false, Ruthless = -300},
    FrenzySwingHeight = {Default = false, Ruthless = -10},
    GeneralTargetInnards = 4,
    FrenzyOneTargetInnards = {Default = 7, Ruthless = 10},
    TiredThreshold = {Default = false, Ruthless = 0.1},

    -- GENERAL
    Sounds = {
        Jump = REVEL.SFX.WHOOSH,
        Land = SoundEffect.SOUND_FETUS_LAND,
        Wakeup = REVEL.SFX.ARAGNID_WAKEUP,
        InnardLaunch = REVEL.SFX.ARAGNID_INNARD_LAUNCH,
        MagicSplash = REVEL.SFX.ARAGNID_MAGIC_SPLASH,
        RupturingScream = REVEL.SFX.ARAGNID_RUPTURING_SCREAM,
        RainStart = REVEL.SFX.ARAGNID_MAGIC_BLOOD_RAIN,
        RainLoop = REVEL.SFX.ARAGNID_MAGIC_BLOOD_RAIN_LOOP,
        Swing = REVEL.SFX.ARAGNID_SWING,
        DeathYell = REVEL.SFX.ARAGNID_DEATH_YELL,

        InnardSpewStart = SoundEffect.SOUND_ANIMAL_SQUISH
    },
    AttackNames = {
        MagicSplash = "Magic Splash",
        MagicSplashRevive = "Magic Splash",
        InnardLaunch = "Innard Launch",
        MagicBloodRain = "Magic Blood Rain",
        RupturingScream = "Rupturing Scream",
        LowJump = "Low Jump",
        HighJump = "High Jump",

        LaserEyes = "Laser Eyes!",
        LowKicks = "Low Kicks",
        SwingingSlam = "Swinging Slam"
    }
}

local purpleInvisible = REVEL.CustomColor(146, 39, 143, 0)
local purpleVisible = REVEL.CustomColor(146, 39, 143, 1)
local invisible = Color(1, 1, 1, 0,conv255ToFloat( 0, 0, 0))
local visible = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
local nothing, full = Vector.Zero, Vector.One

local tarProjectileParams = ProjectileParams()
tarProjectileParams.Color = aragnidBalance.TarColor
tarProjectileParams.FallingSpeedModifier = -.5
tarProjectileParams.FallingAccelModifier = .8
tarProjectileParams.VelocityMulti = .6

local function GetValidPositions(positions, margin, marginInRoom, roomCenter)
    marginInRoom = marginInRoom or 0
    local validPositions = {}
    for i = 0, REVEL.room:GetGridSize() do
        local gpos = REVEL.room:GetGridPosition(i)
        if REVEL.room:IsPositionInRoom(gpos, marginInRoom) then
            local valid = true

            if roomCenter then
                if gpos.Y > roomCenter.Y - 20 and gpos.Y < roomCenter.Y + 20 then
                    valid = false
                end
            end

            local closestAvoidDist
            if valid then
                for _, pos in ipairs(positions) do
                    local dist = pos:DistanceSquared(gpos)
                    if dist < margin ^ 2 then
                        if not closestAvoidDist or dist < closestAvoidDist then
                            closestAvoidDist = dist
                        end

                        valid = false
                    end
                end
            end

            if valid then
                local weight
                if closestAvoidDist then
                    weight = math.floor(math.sqrt(closestAvoidDist) / 20)
                else
                    weight = 1
                end

                validPositions[#validPositions + 1] = {Position = gpos, Weight = weight}
            end
        end
    end

    return validPositions
end

local function RandomFloat(min, max)
    if min and max then
        return (math.random() * (max - min)) + min
    elseif min ~= nil then
        return math.random() * min
    end
    return math.random()
end

local function GetAragnidLob(funky, posA, posB, swinging, extraHeight, bal)
    local multi = bal.AragnidLobVelocityMulti
    if swinging then
        multi = bal.AragnidLobVelocityMultiInAir
    end

    local vel = (posB - posA) * multi
    local speed, accel = 0, 0
    if funky then
      speed = bal.AragnidFunkyFallingSpeed
      accel = bal.AragnidFunkyFallingAccel
    else
      speed = RandomFloat(bal.AragnidLobFallingSpeedMin, bal.AragnidLobFallingSpeedMax)
      accel = bal.AragnidLobFallingAccel
    end
    return vel, RandomFloat(bal.AragnidLobStartHeightMin, bal.AragnidLobStartHeightMax) + (extraHeight or 0), speed, accel
end

local function GetJumpableInnards()
    local jumpable = Isaac.FindByType(REVEL.ENT.INNARD.id, REVEL.ENT.INNARD.variant, -1, nil, nil)
    local aragnidInnards = Isaac.FindByType(REVEL.ENT.ARAGNID_INNARD.id, REVEL.ENT.ARAGNID_INNARD.variant, -1, nil, nil)
    for _, innard in ipairs(aragnidInnards) do
        if not innard:GetData().AgitatedFrame then
            jumpable[#jumpable + 1] = innard
        end
    end

    return jumpable
end

local function KillNearbyInnards(npc)
    local innards = GetJumpableInnards()
    for _, innard in ipairs(innards) do
        if innard.Position:DistanceSquared(npc.Position) < (npc.Size + innard.Size) ^  2 then
            local bal = innard:GetData().bal
            if bal and bal.InnardCrushSpawnsRags then
                local spawn = bal.InnardCrushRagTypes[math.random(1, #bal.InnardCrushRagTypes)]
                REVEL.SpawnRevivalRag(nil, spawn[1], spawn[2], 0, innard.Position)
            end

            innard:Kill()
        end
    end
end

local function GetAvoidInnardPositions(npc, data, innards, rags)
    local avoid = {}
    if data.Swinging then
      --melon: trying to keep the center of the room free while arag is swinging
      local center = REVEL.room:GetCenterPos()
      for i = 0, REVEL.room:GetGridSize() do
        local gpos = REVEL.room:GetGridPosition(i)
        if math.abs(gpos.X - center.X) < data.bal.InnardAvoidCenterX and math.abs(gpos.Y - center.Y) < data.bal.InnardAvoidCenterY then
          avoid[#avoid + 1] = gpos
        end
      end
    else
        avoid[#avoid + 1] = npc.Position
    end

    for _, innard in ipairs(innards) do
        avoid[#avoid + 1] = innard.Position
    end

    for _, rag in ipairs(rags or Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)) do
        if rag:GetData().SpawnID == REVEL.ENT.ARAGNID_INNARD.id and rag:GetData().SpawnVariant == REVEL.ENT.ARAGNID_INNARD.variant then
            avoid[#avoid + 1] = rag.Position
        end
    end

    return avoid
end

local function SpawnInnard(npc, data, pos, vel, height, fallSpeed, fallAccel)
    local innard = Isaac.Spawn(REVEL.ENT.ARAGNID_INNARD.id, REVEL.ENT.ARAGNID_INNARD.variant, 0, pos, vel or Vector.Zero, nil)
    innard:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
    innard:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    local idata = innard:GetData()
    idata.Aragnid = npc

    if height ~= false then
        fallSpeed = fallSpeed or RandomFloat(data.bal.AragnidLobFallingSpeedMin, data.bal.AragnidLobFallingSpeedMax)
        fallAccel = fallAccel or data.bal.AragnidLobFallingAccel
        innard.SpriteOffset = Vector(0, height)
        idata.FallingSpeed = fallSpeed
        idata.FallingAcceleration = fallAccel
        innard:GetSprite():Play("Falling", true)
    else
        innard:GetSprite():Play("Emerge", true)
    end

    return innard
end

local function RagEnemyCountsDouble(spawnID, spawnVariant)
    return (spawnID == REVEL.ENT.RAG_FATTY.id and spawnVariant == REVEL.ENT.RAG_FATTY.variant)
    or (spawnID == REVEL.ENT.WRETCHER.id and spawnVariant == REVEL.ENT.WRETCHER.variant)
    or (spawnID == REVEL.ENT.RAG_DRIFTY.id and spawnVariant == REVEL.ENT.RAG_DRIFTY.variant)
end

local function GetRagEnemiesCount(getRagCount, rags)
    local ragEnemies = {}

    local ragCount = 0

    if getRagCount then
        rags = rags or Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
        for _, rag in ipairs(rags) do
            local isInnard = rag:GetData().SpawnID == REVEL.ENT.ARAGNID_INNARD.id and rag:GetData().SpawnVariant == REVEL.ENT.ARAGNID_INNARD.variant
            if not isInnard and rag:GetData().MagicBallTargeted then
                ragCount = ragCount + 1

                local spawnID, spawnVariant = rag:GetData().SpawnID, rag:GetData().SpawnVariant
                if RagEnemyCountsDouble(spawnID, spawnVariant) then
                    ragCount = ragCount + 1
                end
            end
        end
    end

    for id, variants in pairs(REVEL.RAG_FAMILY) do
        for _, variant in ipairs(variants) do
            local enemies = Isaac.FindByType(id, variant, -1, false, false)
            for _, enemy in ipairs(enemies) do
                if RagEnemyCountsDouble(enemy.Type, enemy.Variant) then
                    ragCount = ragCount + 2
                else
                    ragCount = ragCount + 1
                end

                ragEnemies[#ragEnemies + 1] = enemy
            end
        end
    end

    return ragCount
end

local function GetMagicBallTargetRag(targetPlayer, avoidPosition, bal)
    local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
    local minDistRag, minDist, minIsInnard

    local ragEnemyCount = GetRagEnemiesCount(true, rags)

    for _, rag in ipairs(rags) do
        local spawnID, spawnVariant = rag:GetData().SpawnID, rag:GetData().SpawnVariant
        local isInnard = spawnID == REVEL.ENT.ARAGNID_INNARD.id and spawnVariant == REVEL.ENT.ARAGNID_INNARD.variant
        if (isInnard or not minIsInnard) and (not avoidPosition or avoidPosition:DistanceSquared(rag.Position) > 20 ^ 2) and not rag:GetData().MagicBallTargeted and (isInnard or ragEnemyCount < bal.MaxActiveRagEnemies) then
            if not RagEnemyCountsDouble(spawnID, spawnVariant) or ragEnemyCount == 0 then
                local dist = rag.Position:DistanceSquared(targetPlayer.Position)
                if not minDist or dist < minDist or (isInnard and not minIsInnard) then
                    minDist = dist
                    minDistRag = rag
                    minIsInnard = isInnard
                end
            end
        end
    end

    return minDistRag
end

local function ShootMagicBall(npc, data, addHeight, position, bloodRain, offset)
    local targetPlayer = npc:GetPlayerTarget()
    local targetPos, targetRag
    if data.bal.SplashSeeksRags then
        local rag = GetMagicBallTargetRag(targetPlayer, npc.Position, data.bal)
        if rag then
            targetPos = rag.Position
            targetRag = rag
        end
    end

    targetPos = targetPos or npc:GetPlayerTarget().Position

    if offset then
        targetPos = targetPos + offset
    end

    if bloodRain then
        position = targetPos
    end

    local vel, height, fallSpeed, fallAccel = GetAragnidLob(true, position or npc.Position, REVEL.room:GetClampedPosition(targetPos, 32), data.Swinging, addHeight or npc.SpriteOffset.Y, data.bal)
    local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, position or npc.Position, vel, nil):ToProjectile()
    proj:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    proj.Size = proj.Size * 4
    proj:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_magicball.anm2", true)
    proj:GetSprite():Play("Idle", true)
    proj.Height = height

    if bloodRain then
        proj.FallingSpeed = data.bal.BloodRainFallingSpeedMin
        proj.FallingAccel = data.bal.BloodRainFallingAccel
        proj:GetData().NoSplash = true
        proj:GetData().NoHome = true
        proj:GetData().BloodRain = true
        proj.Velocity = Vector.Zero
    else
        proj.FallingSpeed = fallSpeed * 10
        proj.FallingAccel = fallAccel * 5
    end

    proj.RenderZOffset = 100001
    proj.ProjectileFlags = ProjectileFlags.SMART
    proj:GetData().MagicSplash = true
    proj:GetData().FallingSpeedMax = data.bal.AragnidFunkyFallingSpeedMax
    proj:GetData().Player = targetPlayer

    if targetRag then
        targetRag:GetData().MagicBallTargeted = proj
    end

    proj:GetData().Rag = targetRag
    proj:GetData().bal = data.bal
    proj:Update()
    proj.ProjectileFlags = 0
    proj:GetData().PurpleColor = proj.Color
    proj.Color = visible
end

REVEL.PushBlacklist[REVEL.ENT.ARAGNID.id] = {REVEL.ENT.ARAGNID.variant}

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ARAGNID.variant then
        return
    end

    local sprite, data = npc:GetSprite(), npc:GetData()
    sprite:SetOverlayRenderPriority(true)
    if sprite:IsEventTriggered("Jump") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    elseif sprite:IsEventTriggered("Land") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    if not data.Init then
        npc.SplatColor = REVEL.PurpleRagSplatColor
        if REVEL.IsRuthless() then
            data.bal = REVEL.GetBossBalance(aragnidBalance, "Ruthless")
            npc:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_champion.anm2", false)
            for i = 0, 4 do
                if i ~= 2 then -- laser
                    npc:GetSprite():ReplaceSpritesheet(i, "gfx/bosses/revel2/aragnid/ruthless_aragnid.png")
                end
            end

            npc:GetSprite():LoadGraphics()
            npc:GetSprite():Play("IdleWeak", true)
            data.RagsRevived = true
        elseif REVEL.IsChampion(npc) then
            data.bal = REVEL.GetBossBalance(aragnidBalance, "Revival")
            npc:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_champion.anm2", true)
            npc:GetSprite():Play("IdleWeak", true)
            data.RagsRevived = true
        else
            data.bal = REVEL.GetBossBalance(aragnidBalance, "Default")
        end

        data.InnardFuse = data.bal.InnardExplosionFuse
        data.RoomCenter = REVEL.room:GetCenterPos()
        data.Rags = Isaac.Spawn(REVEL.ENT.ARAGNID_RAGS.id, REVEL.ENT.ARAGNID_RAGS.variant, 0, Vector.Zero, Vector.Zero, nil)
        data.Rags:GetData().Aragnid = npc
        data.Rags:GetData().bal = data.bal
        data.Rags:GetData().Anchor = data.RoomCenter + data.bal.RagAnchorOffset
        data.ArmorMod = data.bal.FinalArmorMod * data.bal.IntroArmorMod
        data.State = "Weak Idle"

        if data.bal.IntroSwingHeight then
            sprite:Play("Invisible", true)
            data.State = "Intro Swinging"
            npc.SpriteOffset = Vector(0, data.bal.IntroSwingHeight)
            data.Swinging = true
            data.SwingHeight = data.bal.IntroSwingHeight
            data.TargetSwingHeight = data.bal.IntroSwingHeight
            data.FirstJump = true
            data.WeakEnd = true
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        end

        data.Init = true
        REVEL.SetScaledBossHP(npc)
        --npc.MaxHitPoints = math.max(npc.MaxHitPoints, REVEL.EstimateDPS(REVEL.player) * 40)
        --npc.HitPoints = npc.MaxHitPoints
    end

    data.NumInnardsRelayedDamageInFrame = 0

    if data.BloodRainTime then
        local startupPercent = math.floor(math.min(data.bal.BloodRainStartupTime, data.BloodRainTime) / data.bal.BloodRainStartupTime)
        local projectileRate = REVEL.Lerp(data.bal.BloodRainMinProjectilesRate, data.bal.BloodRainMaxProjectilesRate, startupPercent)
        if npc.FrameCount % projectileRate == 0 then
            local target = npc:GetPlayerTarget()
            local diffAngle = (target.Position - npc.Position):GetAngleDegrees()

            local maxAngleOffset = REVEL.Lerp(data.bal.BloodRainInitialAngleOffset, 360, startupPercent)
            local minDist = REVEL.Lerp(data.bal.BloodRainMinProjectileDistance, 0, startupPercent)

            for i = 1, data.bal.BloodRainMaxProjectiles do
                local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, target.Position + Vector.FromAngle(diffAngle + math.random(0, maxAngleOffset)) * math.random(minDist, data.bal.BloodRainMaxProjectileDistance), Vector.Zero, nil):ToProjectile()
                local fallSpeed = RandomFloat(data.bal.BloodRainFallingSpeedMin, data.bal.BloodRainFallingSpeedMax)
                local fallAccel = data.bal.BloodRainFallingAccel
                proj.Height = math.random(data.bal.BloodRainStartHeightMin, data.bal.BloodRainStartHeightMax)
                proj.FallingSpeed = fallSpeed
                proj.FallingAccel = fallAccel
                proj.ProjectileFlags = ProjectileFlags.SMART
                proj.HomingStrength = 0.4
                proj:Update()
                proj.ProjectileFlags = 0
                proj:Update()
                proj:GetData().BloodRain = true
            end
        end

        if data.bal.BloodRainMagicBallRate then
            if npc.FrameCount % data.bal.BloodRainMagicBallRate == 0 then
                ShootMagicBall(npc, data, math.random(data.bal.BloodRainStartHeightMin, data.bal.BloodRainStartHeightMax), nil, true)
            end
        end

        data.BloodRainTime = data.BloodRainTime + 1
        if data.BloodRainTime >= data.bal.BloodRainTime and not data.bal.EternalMagicBloodRain then
            REVEL.sfx:Stop(data.bal.Sounds.RainLoop)
            data.BloodRainTime = nil
        end
    end

    local shouldHitProjectiles = data.Swinging or (((not sprite:IsPlaying("BigJump") and not sprite:IsPlaying("BigJumpDown")) or (not sprite:WasEventTriggered("Jump") or sprite:WasEventTriggered("Land"))) and not sprite:IsPlaying("Invisible"))

    if shouldHitProjectiles then
        local projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, false)
        local height = npc.SpriteOffset.Y
        if sprite:IsPlaying("Jump") and sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Land") then
            height = -50
        end

        for _, projectile in ipairs(projectiles) do
            ---@type EntityProjectile
            projectile = projectile:ToProjectile()
            local pdata = projectile:GetData()
            if not projectile:IsDead()
            and (pdata.Innard or pdata.BloodRain)
            and projectile.Height < height + data.bal.ProjectileHeightToHit.Low
            and projectile.Height > height + data.bal.ProjectileHeightToHit.High
            and projectile.Position.Y < npc.Position.Y + npc.Size + projectile.Size
            and (
                (pdata.Innard and projectile.Position:DistanceSquared(npc.Position) < (projectile.Size + npc.Size * data.bal.InnardBurstBlockingSizeMulti) ^ 2)
                or (pdata.BloodRain and projectile.Position:DistanceSquared(npc.Position) < (projectile.Size + npc.Size * data.bal.BloodRainBlockingSizeMulti) ^ 2)
            ) then
                if pdata.Innard then
                    local idata = pdata.Innard:GetData()
                    if not idata.AragnidHits then
                        idata.AragnidHits = 0
                    end

                    idata.AragnidHits = idata.AragnidHits + 1
                    if idata.AragnidHits == 4 then
                        data.InnardFuse = math.max(data.InnardFuse * data.bal.InnardFuseMultiWhenHit, data.bal.InnardFuseMinimum)
                    end

                    npc:TakeDamage(data.bal.InnardBurstDamagePctPerProjectile * npc.MaxHitPoints * 0.01, 0, EntityRef(projectile), 0)
                else
                    if math.random(1, data.bal.BloodRainChanceForProjectileToDamage) == 1 then
                        npc:TakeDamage(data.bal.BloodRainDamagePerProjectile, 0, EntityRef(projectile), 0)
                    end
                end

                projectile:Die()
            end
        end
    end

    local innards = Isaac.FindByType(REVEL.ENT.ARAGNID_INNARD.id, REVEL.ENT.ARAGNID_INNARD.variant, -1, false, false)

    local activeInnards, inactiveInnards, veryInactiveInnards = {}, {}, {}
    for _, innard in ipairs(innards) do
        local isprite = innard:GetSprite()
        if isprite:IsPlaying("SpewLoop") or isprite:IsPlaying("SpewStart") or isprite:IsFinished("SpewStart") or isprite:IsFinished("SpewLoop") or innard:GetData().GoingToStart then
            activeInnards[#activeInnards + 1] = innard
        elseif isprite:IsPlaying("Hide") then
            local data = innard:GetData()
            if not data.LastHideTime or REVEL.game:GetFrameCount() > data.LastHideTime + data.bal.InnardCreepFadeTime then
                veryInactiveInnards[#veryInactiveInnards + 1] = innard
            else
                inactiveInnards[#inactiveInnards + 1] = innard
            end
        elseif isprite:IsPlaying("SpewEnd") then
            inactiveInnards[#inactiveInnards + 1] = innard
        end
    end

    if #activeInnards < 2 and #inactiveInnards + #veryInactiveInnards > 0 then
        for i = 1, 2 - #activeInnards do
            local activate
            if #veryInactiveInnards > 0 then
                local select = math.random(1, #veryInactiveInnards)
                activate = veryInactiveInnards[select]
                table.remove(veryInactiveInnards, select)
            else
                local select = math.random(1, #inactiveInnards)
                activate = inactiveInnards[select]
                table.remove(inactiveInnards, select)
            end

            local asprite = activate:GetSprite()
            if asprite:IsPlaying("SpewEnd") then
                activate:GetData().GoingToStart = true
            else
                activate:GetSprite():Play("SpewStart", true)
                REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
            end

            if #inactiveInnards + #veryInactiveInnards == 0 then
                break
            end
        end
    end

    -- Weak / Intro State
    if data.State == "Weak Idle" then
        sprite:Play("IdleWeak", false)
        if npc.HitPoints < npc.MaxHitPoints and not data.NoWakeUp then
            if not data.FirstJump then
                data.FirstJump = true
                sprite:Play("JumpWeak", true)
                data.State = "Weak Jump"
                REVEL.sfx:NpcPlay(npc, data.bal.Sounds.Wakeup, 0.8, 0, false, 1)
            elseif not data.WeakEnd then
                if data.bal.RupturingScreamReplaceInnardLaunch then
                    sprite:Play("RupturingScreamGround", true)
                    data.State = "Rupturing Scream"
                    REVEL.AnnounceAttack(data.bal.AttackNames.RupturingScream)
                else
                    sprite:Play("InnardLaunchGround", true)
                    data.State = "Innard Launch"
                    REVEL.AnnounceAttack(data.bal.AttackNames.InnardLaunch)
                end
            else
                sprite:Play("BigJump", true)
                data.State = "Jump To Swing"
                data.ArmorMod = data.bal.FinalArmorMod
                if data.bal.BigJumpSpawnTrite then
                    REVEL.sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, .7)
                    local trite = Isaac.Spawn(REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant, 0, npc.Position, Vector(0, 0), npc)
                end
            end
        end
    elseif data.State == "Intro Swinging" then
        for _, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size) ^ 2 then
                data.State = "Swing Idle"
                data.AttackCooldown = 0
                REVEL.JumpToCycle(data, 1, "SwingingSlamIntoMagicSplash", 1)
                break
            end
        end
    elseif data.State == "Weak Jump" then
        if sprite:IsFinished("JumpWeak") or sprite:IsFinished("JumpIntoWeak") then
            sprite:Play("IdleWeak", true)
            data.State = "Weak Idle"
        end
    elseif data.State == "Swing Idle" then
        if not sprite:IsPlaying("IdleHang") then
            sprite:Play("IdleHang", true)
        end

        if data.AttackCooldown then
            data.AttackCooldown = data.AttackCooldown - 1
        else
            data.AttackCooldown = math.random(30, 45)
        end

        if data.AttackCooldown <= 0 then
            if npc.HitPoints < npc.MaxHitPoints * data.bal.FrenzyOneThreshold and not data.FrenzyOne then
                data.TargetInnardCount = data.bal.FrenzyOneTargetInnards
            else
                data.TargetInnardCount = data.bal.GeneralTargetInnards
            end

            if npc.HitPoints < npc.MaxHitPoints * data.bal.FrenzyTwoThreshold then
                data.FrenzyTwo = true
                if data.BloodRainTime then
                    REVEL.sfx:Stop(data.bal.Sounds.RainLoop)
                    data.BloodRainTime = nil
                end

                if data.bal.FrenzySwingHeight then
                    data.TargetSwingHeight = data.bal.FrenzySwingHeight
                    data.State = "Swing Frenzy Idle"
                else
                    data.State = "Jump From Swing"
                    sprite:Play("BigJumpNoMove", true)
                    sprite:RemoveOverlay()
                end
            elseif npc.HitPoints < npc.MaxHitPoints * data.bal.FrenzyOneThreshold and not data.FrenzyOne and #innards >= data.TargetInnardCount then
                data.FrenzyOne = true
                if data.bal.FrenzySwingHeight then
                    data.TargetSwingHeight = data.bal.FrenzySwingHeight
                    data.State = "Swing Frenzy Idle"
                else
                    data.State = "Jump From Swing"
                    sprite:Play("BigJumpNoMove", true)
                    sprite:RemoveOverlay()
                end
            else
                local usingCycle = (data.FrenzyOne and data.bal.SecondSwingCycle) or data.bal.SwingCycle
                local curCycleSegment, isAttacking, attack, cooldown = REVEL.ManageAttackCycle(data, data.bal, usingCycle, npc, innards)
                if isAttacking then
                    REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                    if attack == "RupturingScream" then
                        data.State = "Rupturing Scream"
                        sprite:Play("RupturingScream", true)
                    elseif attack == "MagicSplash" then
                        data.State = "Magic Splash"
                        sprite:Play("MagicSplash", true)
                    elseif attack == "InnardLaunch" then
                        data.State = "Innard Launch"
                        sprite:Play("InnardLaunch", true)
                    elseif attack == "MagicBloodRain" then
                        data.UsedMagicBloodRain = true
                        data.State = "Magic Blood Rain"
                        sprite:Play("MagicBloodRain", true)
                    elseif attack == "LaserEyes" then
                        data.State = "Laser Eyes"
                        sprite:Play("LaserEyes", true)
                    elseif attack == "SwingingSlam" then
                        data.State = "Swinging Slam"
                        sprite:Play("SwingingSlam", true)
                    end

                    if attack == "RupturingScream" and data.bal.RupturingScreamReplaceInnardLaunch then
                        data.InnardsToSpawn = math.max((data.TargetInnardCount - #innards) + 1, 0)
                    elseif attack == "InnardLaunch" then
                        if data.bal.Champion == "Ruthless" then
                            data.InnardsToSpawn = math.max(data.TargetInnardCount - #innards, 1)
                        else
                            data.InnardsToSpawn = math.max(math.min(data.TargetInnardCount - #innards, 3), 2)
                        end
                    end

                    data.ReturnState = "Swing Idle"
                    data.AttackCooldown = cooldown
                end
            end
        end
    elseif data.State == "Swing Frenzy Idle" then
        data.TargetSwingHeight = data.bal.FrenzySwingHeight

        if data.SwingHeight > -30 then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end

        if data.InnardBarrage then
            data.InnardSpawnCooldown = (data.InnardSpawnCooldown or 0) - 1
            data.InnardRageCooldown = (data.InnardRageCooldown or 0) - 1
            if #innards < 3 and data.InnardSpawnCooldown <= 0 then
                local spawnCount = math.random(1, 3)
                local avoid = GetAvoidInnardPositions(npc, data, innards)
                for i = 1, spawnCount do
                    local positions = GetValidPositions(avoid, data.bal.InnardMinimumDistance, 32, data.RoomCenter)

                    local pos = StageAPI.WeightedRNG(positions, nil, "Weight").Position + (RandomVector() * RandomFloat(20))

                    SpawnInnard(npc, data, pos, nil, false)
                    avoid[#avoid + 1] = pos
                end

                data.InnardSpawnCooldown = math.random(15, 30)
            end

            if #innards > 1 and data.InnardRageCooldown <= 0 then
                local validInnards = {}
                for _, innard in ipairs(innards) do
                    local isprite = innard:GetSprite()
                    if (isprite:IsPlaying("SpewStart") or isprite:IsPlaying("SpewLoop") or isprite:IsPlaying("Hide")) and not innard:GetData().AgitatedFrame then
                        validInnards[#validInnards + 1] = innard
                    end
                end

                if #validInnards > 0 then
                    local activate = validInnards[math.random(1, #validInnards)]
                    if activate then
                        if activate:GetSprite():IsPlaying("Hide") then
                            activate:GetSprite():Play("SpewStart", true)
                            REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
                        end

                        activate:GetData().AgitatedFrame = REVEL.game:GetFrameCount() + data.InnardFuse
                        activate:GetData().StartMoveFrame = REVEL.game:GetFrameCount()
                    end
                end

                data.InnardRageCooldown = math.random(25, 45)
            end
        end

        if data.FrenzyTwo and data.bal.TiredThreshold and npc.HitPoints <= npc.MaxHitPoints * data.bal.TiredThreshold then
            data.NoWakeUp = true
            data.Swinging = nil
            data.SwingHeight = nil
            npc.SpriteOffset = Vector.Zero
            data.State = "Weak Jump"
            data.AttackCooldown = 1000
            sprite:Play("JumpIntoWeak", true)
            sprite:RemoveOverlay()
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            data.InnardBarrage = nil
            if not data.FrenzyTwo and #innards <= 2 then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                data.State = "Swing Idle"
                data.TargetSwingHeight = data.bal.SwingHeight
            else
                local usingCycle = (data.FrenzyTwo and data.bal.SwingCycleFinale) or data.bal.SwingCycleFrenzy
                local curCycleSegment, isAttacking, attack, cooldown = REVEL.ManageAttackCycle(data, data.bal, usingCycle, npc, innards)
                if isAttacking then
                    REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                    if attack == "RupturingScream" then
                        data.State = "Rupturing Scream"
                        sprite:Play("RupturingScream", true)
                    elseif attack == "MagicSplash" then
                        data.State = "Magic Splash"
                        sprite:Play("MagicSplash", true)
                    elseif attack == "InnardBarrage" then
                        data.InnardBarrage = true
                    end

                    data.ReturnState = "Swing Frenzy Idle"
                    data.AttackCooldown = cooldown
                end
            end
        end
    elseif data.State == "Ground Idle" then
        if not sprite:IsPlaying("IdleGround") then
            sprite:Play("IdleGround", true)
        end
        if npc.HitPoints > npc.MaxHitPoints * data.bal.FrenzyTwoThreshold then -- Frenzy one. Alternating High Jump Splash & Magic Splash
            if #innards > 2 then
                if not data.bal.SkipFrenzyFirstHighJump then
                    data.LastWasHighJump = not data.LastWasHighJump
                end

                if not data.LastWasHighJump then
                    data.State = "High Jump"
                    sprite:Play("BigJump", true)
                    REVEL.AnnounceAttack(data.bal.AttackNames.HighJump)
                else
                    if data.bal.RupturingScreamInFrenzy and GetRagEnemiesCount(true) >= data.bal.MaxActiveRagEnemies then
                        data.State = "Rupturing Scream"
                        data.ReturnState = "Ground Idle"
                        sprite:Play("RupturingScreamGround", true)
                        data.InnardsToSpawn = 0
                        REVEL.AnnounceAttack(data.bal.AttackNames.RupturingScream)
                    else
                        data.State = "Magic Splash"
                        data.ReturnState = "Ground Idle"
                        sprite:Play("MagicSplashGround", true)
                        REVEL.AnnounceAttack(data.bal.AttackNames.MagicSplash)
                    end
                end

                if data.bal.SkipFrenzyFirstHighJump then
                    data.LastWasHighJump = not data.LastWasHighJump
                end
            else
                if data.bal.DoMagicBloodRain then
                    REVEL.JumpToCycle(data, 1, "MagicBloodRainScreams", 1)
                end

                data.AttackCooldown = nil
                sprite:Play("BigJump", true)
                data.State = "Jump To Swing"
            end
        else -- Frenzy two. Does High Jump Splash, Low Jump Splash, Magic Splash, or Rupturing Scream, followed immediately by innard launch. Uses rupturing scream if there are more than 3 innards, and innard launch if there are less than 2.
            if data.PrimaryAttack or #innards < 2 then
                data.PrimaryAttack = nil
                data.InnardsToSpawn = math.random(2, 3)
                if data.bal.RupturingScreamReplaceInnardLaunch then
                    local innardRags = data.bal.GetInnardRags()
                    if #innardRags > 0 then
                        data.State = "Magic Splash"
                        sprite:Play("MagicSplashGround", true)
                        REVEL.AnnounceAttack(data.bal.AttackNames.MagicSplash)
                    else
                        data.InnardsToSpawn = data.InnardsToSpawn + 1
                        data.State = "Rupturing Scream"
                        sprite:Play("RupturingScreamGround", true)
                        REVEL.AnnounceAttack(data.bal.AttackNames.RupturingScream)
                    end
                else
                    data.State = "Innard Launch"
                    sprite:Play("InnardLaunchGround", true)
                    REVEL.AnnounceAttack(data.bal.AttackNames.InnardLaunch)
                end

                data.ReturnState = "Ground Idle"
            else
                local attacks

                if #innards > 3 then
                    attacks = {
                       HighJump = 4,
                       LowJump = 6,
                       RupturingScream = (data.bal.DoRupturingScream and 3) or 0,
                    }
                else
                    data.PrimaryAttack = true
                    attacks = {
                        HighJump = 1,
                        LowJump = 1,
                        RupturingScream = (data.bal.DoRupturingScream and 1) or 0,
                        MagicSplash = 1
                    }
                end

                if data.bal.RupturingScreamReplaceInnardLaunch then
                    attacks.MagicSplash = 2
                end

                local attack = REVEL.WeightedRandom(attacks)
                REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                if attack == "HighJump" then
                    data.State = "High Jump"
                    sprite:Play("BigJump", true)
                elseif attack == "MagicSplash" then
                    data.State = "Magic Splash"
                    data.ReturnState = "Ground Idle"
                    sprite:Play("MagicSplashGround", true)
                elseif attack == "RupturingScream" then
                    data.State = "Rupturing Scream"
                    data.ReturnState = "Ground Idle"
                    sprite:Play("RupturingScreamGround", true)
                elseif attack == "LowJump" then
                    data.State = "Low Jump"
                    data.StartPos = npc.Position
                    local validInnards = GetJumpableInnards()
                    data.TargetInnardPosition = validInnards[math.random(1, #validInnards)].Position
                    sprite:Play("Jump", true)
                end
            end
        end
    elseif data.State == "Innard Launch" then
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.InnardLaunch, 0.8, 0, false, 1)

            local avoid = GetAvoidInnardPositions(npc, data, innards)
            for i = 1, data.InnardsToSpawn or data.bal.InitialInnardCount do
                local positions = GetValidPositions(avoid, data.bal.InnardMinimumDistance, 32, data.RoomCenter)

                local pos = StageAPI.WeightedRNG(positions, nil, "Weight").Position + (RandomVector() * RandomFloat(20))

                local ipos, vel, height, fallSpeed, fallAccel
                if not data.bal.NoLobInnards then
                    ipos = npc.Position
                    vel, height, fallSpeed, fallAccel = GetAragnidLob(false, npc.Position, pos, data.Swinging, npc.SpriteOffset.Y, data.bal)
                else
                    ipos = pos
                    height = false
                end

                SpawnInnard(npc, data, ipos, vel, height, fallSpeed, fallAccel)
                avoid[#avoid + 1] = pos
            end
        end

        if sprite:IsFinished("InnardLaunch") or sprite:IsFinished("InnardLaunchGround") then
            data.InnardsToSpawn = nil
            if not data.WeakEnd then
                data.WeakEnd = true
                data.State = "Weak Idle"
            else
                data.State = data.ReturnState
            end
        end
    elseif data.State == "Magic Blood Rain" then
        if sprite:IsEventTriggered("Shoot") then
            data.BloodRainTime = 0
            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.RainStart, 0.8, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.RainLoop, 0.6, 0, true, 1)
        end

        if sprite:IsFinished("MagicBloodRain") then
            data.State = data.ReturnState
        end
    elseif data.State == "Magic Splash" then
        if sprite:IsEventTriggered("Shoot") then
            if data.bal.MagicSplashBalls == 1 then
                ShootMagicBall(npc, data)
            else
                for i = 1, data.bal.MagicSplashBalls do
                    ShootMagicBall(npc, data, nil, nil, nil, RandomVector() * 120)
                end
            end

            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.MagicSplash, 0.4, 0, false, 0.95 + math.random()*0.1)
        end

        if sprite:IsFinished("MagicSplash") or sprite:IsFinished("MagicSplashGround") then
            data.State = data.ReturnState
        end
    elseif data.State == "Rupturing Scream" then
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.RupturingScream, 0.8, 0, false, 1)
            local validInnards = {}
            local buffedInnards = {}
            for _, innard in ipairs(innards) do
                local isprite = innard:GetSprite()
                if (isprite:IsPlaying("SpewStart") or isprite:IsPlaying("SpewLoop") or isprite:IsPlaying("Hide")) and not innard:GetData().AgitatedFrame then
                    validInnards[#validInnards + 1] = innard
                    if innard:GetData().Buffed then
                        buffedInnards[#buffedInnards + 1] = innard
                    end
                end
            end

            local activate
            if #buffedInnards > 0 then
                activate = buffedInnards[math.random(1, #buffedInnards)]
            elseif #validInnards > 0 then
                activate = validInnards[math.random(1, #validInnards)]
            end

            if activate then
                if activate:GetSprite():IsPlaying("Hide") then
                    activate:GetSprite():Play("SpewStart", true)
                    REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
                end

                activate:GetData().AgitatedFrame = REVEL.game:GetFrameCount() + data.InnardFuse
                activate:GetData().StartMoveFrame = REVEL.game:GetFrameCount()
            end

            if data.bal.RupturingScreamReplaceInnardLaunch then
                local avoid = GetAvoidInnardPositions(npc, data, innards)
                if not data.InnardsToSpawn or data.InnardsToSpawn > 0 then
                    for i = 1, data.InnardsToSpawn or data.bal.InitialInnardCount do
                        local positions = GetValidPositions(avoid, data.bal.InnardMinimumDistance, 32, data.RoomCenter)

                        local pos = StageAPI.WeightedRNG(positions, nil, "Weight").Position + (RandomVector() * RandomFloat(20))

                        local vel, height, fallSpeed, fallAccel = GetAragnidLob(false, pos, pos, false, -250, data.bal)
                        fallSpeed = fallAccel * 10
                        SpawnInnard(npc, data, pos, Vector.Zero, height, fallSpeed, fallAccel)
                        avoid[#avoid + 1] = pos
                    end

                    data.InnardsToSpawn = nil
                end

                if data.bal.RupturingScreamRagTypes then
                    local ragCount = Isaac.CountEntities(nil, REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1) or 0
                    local spawnRagCount
                    if ragCount == 0 then
                        spawnRagCount = 3
                    elseif ragCount < 3 then
                        spawnRagCount = 2
                    end

                    if spawnRagCount then
                        for i = 1, spawnRagCount do
                            local positions = GetValidPositions(avoid, data.bal.InnardMinimumDistance, 32, data.RoomCenter)
                            local pos = StageAPI.WeightedRNG(positions, nil, "Weight").Position + (RandomVector() * RandomFloat(20))

                            local ragType = StageAPI.WeightedRNG(data.bal.RupturingScreamRagTypes, nil, "Weight").Entity

                            local vel, height, fallSpeed, fallAccel = GetAragnidLob(false, pos, pos, false, -250, data.bal)
                            fallSpeed = fallAccel * 10
                            local rag, rdata = REVEL.SpawnRevivalRag(nil, ragType[1], ragType[2], 0, pos)
                            rdata.FallingSpeed = fallSpeed
                            rdata.FallingAcceleration = fallAccel
                            rag.SpriteOffset = Vector(0, height)

                            avoid[#avoid + 1] = pos
                        end
                    end
                end
            end
        end

        if sprite:IsFinished("RupturingScream") or sprite:IsFinished("RupturingScreamGround") then
            if not data.WeakEnd then
                data.WeakEnd = true
                data.State = "Weak Idle"
            else
                data.State = data.ReturnState
            end
        end
    elseif data.State == "Laser Eyes" then
        if sprite:IsFinished("LaserEyes") then
            sprite:Play("LaserEyesLoop", true)
        end

        if not data.LaserEyesCooldown then
            data.LaserEyesCooldown = math.random(data.bal.LaserEyesCooldown.Min, data.bal.LaserEyesCooldown.Max)
        end

        if sprite:WasEventTriggered("Shoot") or sprite:IsPlaying("LaserEyesLoop") then
            data.LaserEyesCooldown = data.LaserEyesCooldown - 1
        end

        if data.LaserEyesCooldown <= 0 then
            local laserables = {}
            local projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, false, false)
            for _, projectile in ipairs(projectiles) do
                local data = projectile:GetData()
                if data.MagicSplash and projectile:ToProjectile().Height > data.bal.MagicSplashHoverHeight then
                    laserables[#laserables + 1] = projectile
                end
            end

            if #laserables > 0 then
                local detonate = laserables[math.random(1, #laserables)]:ToProjectile()
                local laserTarget = detonate.Position + Vector(0, detonate.Height - (npc.SpriteOffset.Y - 70))
                local laser = EntityLaser.ShootAngle(2, npc.Position + Vector(0, 1), (laserTarget - npc.Position):GetAngleDegrees(), 4, Vector(0, npc.SpriteOffset.Y - 70), npc)
                laser.DepthOffset = 1000
                laser.Color = REVEL.PurpleRagSplatColor
                laser:SetMaxDistance(laserTarget:Distance(npc.Position))

                local radialOffset = math.random() * 360
                for i = 1, 7 do
                    local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, detonate.Position, Vector.Zero, nil):ToProjectile()
                    proj.ProjectileFlags = ProjectileFlags.SMART
                    proj.Velocity = Vector.FromAngle(radialOffset + (i / 7) * 360) * 11
                    proj:Update()
                end

                detonate:Die()
            else
                sprite:Play("LaserEyesEnd", true)
            end

            data.LaserEyesCooldown = nil
        end

        if sprite:IsFinished("LaserEyesEnd") then
            data.State = data.ReturnState
            data.LaserEyesCooldown = nil
        end
    elseif data.State == "Swinging Slam" then
        data.GroundPound = true
        data.Swinging = nil
        data.Falling = nil

        if sprite:IsEventTriggered("Shoot") then
            data.GroundPoundFrames = 0
            data.InitialPoundHeight = data.SwingHeight
            data.TargetSwingHeight = data.bal.SwingHeight
        end

        if sprite:IsEventTriggered("Land") then
            local rag = REVEL.SpawnRevivalRag(npc, REVEL.ENT.RAG_FATTY.id, REVEL.ENT.RAG_FATTY.variant, 0)
            rag:GetData().SpecialAppear = {NoCreep = true, NoJump = true}
            data.GroundPoundFrames = 0
        end

        if data.GroundPoundFrames then
            if not sprite:WasEventTriggered("Land") then
                data.GroundPoundFrames = data.GroundPoundFrames + 1
                data.SwingHeight = REVEL.Lerp(data.InitialPoundHeight, 0, data.GroundPoundFrames / 4)
            elseif sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("ShootEnd") then
                data.GroundPoundFrames = data.GroundPoundFrames + 1
                data.SwingHeight = REVEL.Lerp(0, data.TargetSwingHeight, data.GroundPoundFrames / 5)
            end
        end

        if sprite:IsFinished("SwingingSlam") then
            data.State = data.ReturnState
            data.Swinging = true
            data.GroundPound = nil
            data.GroundPoundFrames = nil
            data.InitialPoundHeight = nil
        end
    elseif data.State == "Jump To Swing" then
        if sprite:IsFinished("BigJump") then
            sprite:Play("IdleHang", true)
            data.SwingHeight = data.bal.FallingOffset
            npc.SpriteOffset = Vector(0, data.SwingHeight)
            data.FallingSpeed = data.bal.FallingSpeed
            data.FallingAcceleration = data.bal.FallingAcceleration
            data.Falling = true
            data.SwingFrame = 0
            data.State = "Swing Idle"
        end
    elseif data.State == "Jump From Swing" then
        if sprite:IsFinished("BigJumpNoMove") then
            sprite:Play("Invisible", true)
            npc.SpriteOffset = Vector.Zero
            data.StartPos = npc.Position
            local validInnards = GetJumpableInnards()
            if #validInnards == 0 then
                data.TargetInnardPosition = Isaac.GetRandomPosition()
            else
                data.TargetInnardPosition = validInnards[math.random(1, #validInnards)].Position
            end

            data.State = "High Jump In Air"
            data.Falling = nil
            data.Swinging = nil
            data.SwingHeight = nil
        end
    elseif data.State == "High Jump" then
        if sprite:IsFinished("BigJump") then
            sprite:Play("Invisible", true)
            data.StartPos = npc.Position
            local validInnards = GetJumpableInnards()
            if #validInnards == 0 then
                data.TargetInnardPosition = Isaac.GetRandomPosition()
            else
                data.TargetInnardPosition = validInnards[math.random(1, #validInnards)].Position
            end

            data.State = "High Jump In Air"

            if data.bal.BigJumpSpawnTrite then
                local trites = Isaac.FindByType(REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant, -1, false, false)
                if #trites < 4 then
                    REVEL.sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, .7)
                    local trite = Isaac.Spawn(REVEL.ENT.RAG_TRITE.id, REVEL.ENT.RAG_TRITE.variant, 0, npc.Position, Vector(0, 0), npc)
                end
            end
        end
    elseif data.State == "High Jump In Air" then
        data.Moving = true
        if not data.JumpFrames then
            data.JumpFrames = 0
        end

        local pos = REVEL.Lerp(data.StartPos, data.TargetInnardPosition, data.JumpFrames / data.bal.HighJumpAirFrames)
        npc.Velocity = (pos - npc.Position) / 2

        if data.JumpFrames == data.bal.HighJumpAirFrames then
            data.JumpFrames = nil
            npc.RenderZOffset = 0
            sprite:Play("BigJumpDown", true)
            data.Moving = nil
            data.State = "High Jump Down"
        else
            data.JumpFrames = data.JumpFrames + 1
        end
    elseif data.State == "High Jump Down" then
        npc.Velocity = Vector.Zero
        if sprite:IsEventTriggered("Land") then
            KillNearbyInnards(npc)
            npc:FireBossProjectiles(10, Vector.Zero, 0, tarProjectileParams)

            if data.bal.BigJumpSplashIsaac then
              local magicSplashBurst = ProjectileParams()
              local player = npc:GetPlayerTarget()
              magicSplashBurst.VelocityMulti = 1
              for i = 1, 7 do
                  local projectile = npc:FireBossProjectiles(1, player.Position, 0, magicSplashBurst)
                  local velocityLength = projectile.Velocity:Length() * data.bal.AragnidSplashVelocityMult
                  projectile.Velocity = Vector.FromAngle((player.Position - projectile.Position):GetAngleDegrees() + RandomFloat(-12, 12)) * velocityLength
                  tarProjectileParams.FallingSpeedModifier = -.4
                  tarProjectileParams.FallingAccelModifier = 1
                  projectile.Color = data.bal.TarColor
                  projectile:Update()
                  projectile.ProjectileFlags = 0
              end
            end
        end

        if sprite:IsFinished("BigJumpDown") then
            sprite:Play("IdleGround", true)
            data.State = "Ground Idle"
        end
    elseif data.State == "Low Jump" then
        if sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Land") then
            data.Moving = true
            if not data.JumpFrames then
                data.JumpFrames = 0
            end

            local pos = REVEL.Lerp(data.StartPos, data.TargetInnardPosition, data.JumpFrames / data.bal.LowJumpAirFrames)
            npc.Velocity = (pos - npc.Position) / 2
            data.JumpFrames = data.JumpFrames + 1
        end

        if sprite:IsEventTriggered("Land") then
            data.Moving = nil
            KillNearbyInnards(npc)
            npc:FireBossProjectiles(10, Vector.Zero, 0, tarProjectileParams)
        end

        if sprite:IsFinished("Jump") then
            data.JumpFrames = nil
            data.Moving = nil
            data.State = "Ground Idle"
        end
    end

    if data.Swinging or data.Falling or data.GroundPound then
        data.SwingHeight = data.SwingHeight or 0
        data.SwingFrame = data.SwingFrame or 0
        data.TargetSwingHeight = data.TargetSwingHeight or data.bal.SwingHeight

        data.InterpolationFrame = true

        local waveHeight = math.cos(data.bal.CosModifier * 2 * data.SwingFrame)
        local targetHeight = -(data.bal.MaxExtraHeight / 2 + (data.bal.MaxExtraHeight / 2 * waveHeight)) + data.TargetSwingHeight

        if data.Falling then
            data.SwingHeight = math.min(data.SwingHeight + data.FallingSpeed, targetHeight)
            data.FallingSpeed = data.FallingSpeed + data.FallingAcceleration

            if data.SwingHeight == targetHeight then
                data.Falling = nil
                data.Swinging = true
            end
        elseif data.State == "Jump From Swing" and sprite:WasEventTriggered("Jump") then
            data.SwingHeight = data.SwingHeight + data.bal.RisingAddHeight
        elseif data.Swinging then
            if math.abs(targetHeight - data.SwingHeight) < 5 then
                data.SwingHeight = targetHeight
            else
                data.SwingHeight = REVEL.Lerp(data.SwingHeight, targetHeight, 0.1)
            end

            data.SwingFrame = data.SwingFrame + 1
        end

        if data.State ~= "Jump From Swing" then
            local wave = math.cos(data.bal.CosModifier * data.SwingFrame)
            local targetX = data.bal.HalfDistanceX * wave

            local waveY = math.sin(data.bal.CosModifier * data.SwingFrame)
            local targetY = data.bal.HalfDistanceY * waveY

            local targetPos = Vector(data.RoomCenter.X + targetX, data.RoomCenter.Y + targetY)
            if data.Falling then
                npc.Velocity = (REVEL.Lerp(npc.Position, targetPos, 0.2) - npc.Position) / 2
            else
                npc.Velocity = (targetPos - npc.Position) / 2
            end

            if not (sprite:IsOverlayPlaying("LegSwayLeftStart") or sprite:IsOverlayPlaying("LegSwayRightStart")) then
                local isLeftPlaying = sprite:IsOverlayPlaying("LegSwayLeft") or sprite:IsOverlayFinished("LegSwayLeft")
                local isRightPlaying = sprite:IsOverlayPlaying("LegSwayRight") or sprite:IsOverlayFinished("LegSwayRight")
                if targetX > 0 then
                    if not isLeftPlaying then
                        if isRightPlaying then
                            sprite:PlayOverlay("LegSwayLeftStart", true)
                            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.Swing, 0.6, 0, false, 1)
                        else
                            sprite:PlayOverlay("LegSwayLeft", true)
                        end
                    end
                else
                    if not isRightPlaying then
                        if isLeftPlaying then
                            sprite:PlayOverlay("LegSwayRightStart", true)
                            REVEL.sfx:NpcPlay(npc, data.bal.Sounds.Swing, 0.6, 0, false, 1)
                        else
                            sprite:PlayOverlay("LegSwayRight", true)
                        end
                    end
                end
            end
        end

        npc.RenderZOffset = 100000
    elseif not data.Moving then
        npc.Velocity = Vector.Zero
    end

    if sprite:IsEventTriggered("Jump") then
        REVEL.sfx:NpcPlay(npc, data.bal.Sounds.Jump, 0.8, 0, false, 1)
    end

    if sprite:IsEventTriggered("Land") then
        REVEL.sfx:NpcPlay(npc, data.bal.Sounds.Land, 1, 0, false, 1)
    end

    if npc:IsDead() then
        for i, innard in ipairs(innards) do
            innard:GetData().SelfAgitate = i * 30
        end
    end

    data.Rags.RenderZOffset = npc.RenderZOffset - 1
end, REVEL.ENT.ARAGNID.id)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local aragnids = Isaac.FindByType(REVEL.ENT.ARAGNID.id, REVEL.ENT.ARAGNID.variant, -1, false, false)
    for _, aragnid in ipairs(aragnids) do
        local sprite = aragnid:GetSprite()
        if sprite:IsPlaying("Death") then
            local npc = aragnid:ToNPC()
            if sprite:IsEventTriggered("Yell") then
                REVEL.sfx:NpcPlay(npc, aragnid:GetData().bal.Sounds.DeathYell, 0.7, 0, false, 1)
            end

            if sprite:WasEventTriggered("BloodExplode") and not sprite:WasEventTriggered("Explosion") then
                npc:BloodExplode()
            end

            if sprite:IsEventTriggered("Explosion") then
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc)
            end
        end
    end
end)

-- Aragnid Swing
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ARAGNID.variant 
    or REVEL.game:IsPaused() or not npc:GetData().Init
    or not REVEL.IsRenderPassNormal() then
        return
    end

    local sprite, data = npc:GetSprite(), npc:GetData()
    if data.SwingHeight then
        if data.InterpolationFrame then
            npc.SpriteOffset = REVEL.Lerp(npc.SpriteOffset, Vector(0, data.SwingHeight), 0.5)
            data.InterpolationFrame = false
        else
            npc.SpriteOffset = Vector(0, data.SwingHeight)
        end
    end
end, REVEL.ENT.ARAGNID.id)

local magicSplashBurst = ProjectileParams()
magicSplashBurst.VelocityMulti = 1.05
magicSplashBurst.BulletFlags = ProjectileFlags.SMART
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    local data = pro:GetData()
    if data.MagicSplash then
        pro.RenderZOffset = 100001

        if not data.NoHome then
            local homingData, target = data.bal.MagicSplashHoming.Player, data.Player
            if data.Rag then
                homingData, target = data.bal.MagicSplashHoming.Rag, data.Rag
            end

            pro.Velocity = pro.Velocity * homingData.Friction + (target.Position - pro.Position):Resized(homingData.Speed)
        end

        if pro.FallingSpeed > 0 and not data.BloodRain then
            pro.FallingAccel = math.min(data.FallingSpeedMax, pro.FallingAccel * 1.15)
        end

        if data.bal.MagicSplashHoverHeight and not data.Rag then
            if not data.PlayerTriggered then
                pro.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                if pro.Height > data.bal.MagicSplashHoverHeight and pro.FallingSpeed > 0 then
                    data.NoHome = true
                    pro.Velocity = Vector.Zero
                    pro.FallingAccel = -0.1
                    pro.FallingSpeed = 0.1
                    local hoverCycle = math.cos(data.bal.TwoPi / 30 * pro.FrameCount)
                    pro.Height = REVEL.Lerp(pro.Height, data.bal.MagicSplashHoverHeight + 5 + (hoverCycle * 5), 0.3)

                    for _, player in ipairs(REVEL.players) do
                        if player.Position:DistanceSquared(pro.Position) < data.bal.MagicSplashHoverDistance ^ 2 then
                            data.PlayerTriggered = true
                            pro.FallingAccel = data.bal.AragnidFunkyFallingAccel
                            pro.FallingSpeed = data.bal.AragnidFunkyFallingSpeed
                        end
                    end
                end
            end
        end

        local targetDelay = data.bal.AragnidFunkyTargetDelay
        if pro.Height > 0-(targetDelay+50) and pro.Height < 0-targetDelay then
            data.TargetVec = data.Player.Position - pro.Position
        end

        if pro:IsDead() then
            if data.Rag then
                REVEL.BuffEntity(data.Rag)
            end

            pro.Color = data.PurpleColor
            REVEL.sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 0.3, 0, false, 1)

            if not data.NoSplash and not data.Rag then
                local npc = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, REVEL.room:GetClampedPosition(pro.Position, 0), Vector.Zero, nil):ToNPC()
                for i = 1, 10 do
                    REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.6, 0, false, 1)
                    local projectile = npc:FireBossProjectiles(1, data.Player.Position, 0, magicSplashBurst)
                    local velocityLength = projectile.Velocity:Length() * data.bal.AragnidSplashVelocityMult
                    data.TargetVec = data.TargetVec or (data.Player.Position - pro.Position)
                    projectile.Velocity = Vector.FromAngle(data.TargetVec:GetAngleDegrees() + RandomFloat(-data.bal.MagicSplashAngle, data.bal.MagicSplashAngle)) * velocityLength
                    projectile:Update()
                    projectile.ProjectileFlags = 0
                end

                npc:Remove()
            end
        end
    end
end)

-- Aragnid Rag Rendering. Effect entity that renders rags from an anchor point to directly behind aragnid.
local AragnidRags = REVEL.LazyLoadRoomSprite{
    ID = "arag_rags",
    Anm2 = "gfx/bosses/revel2/aragnid/aragnid_rags.anm2",
    Animation = "Idle",
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff)
    if not REVEL.IsRenderPassNormal() then return end

    local data = eff:GetData()
    local npc = data.Aragnid
    if data.Aragnid and data.Aragnid:Exists() then
        local anim = "Idle"
        if npc:GetData().RagsRevived then
            anim = "IdleChampion"
        end
        if data.Aragnid:GetData().Falling or data.Aragnid:GetData().Swinging or data.Aragnid:GetData().GroundPound then
            local renderPosition = Isaac.WorldToScreen(npc.Position) + npc.SpriteOffset
            for i = -1, 1, 2 do
                if i == 1 then
                    AragnidRags:SetFrame(anim, 1)
                else
                    AragnidRags:SetFrame(anim, 0)
                end

                local rpos = renderPosition + data.bal.RagAragnidOffset * i
                AragnidRags.Rotation = (Isaac.WorldToScreen(data.Anchor) - rpos):GetAngleDegrees()
                AragnidRags:Render(rpos, Vector.Zero, Vector.Zero)
                --DrawRotatedTilingSprite(aragnidRags, Isaac.WorldToScreen(data.Anchor), renderPosition + aragnid.RagAragnidOffset * i, aragnid.RagIndividualLength)
            end
        end
    else
        eff:Remove()
    end
end, REVEL.ENT.ARAGNID_RAGS.variant)

-- Aragnid Innard
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ARAGNID_INNARD.variant then
        return
    end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Init then
        if not data.Aragnid then
            data.Aragnid = Isaac.FindByType(REVEL.ENT.ARAGNID.id, REVEL.ENT.ARAGNID.variant, -1, false, false)[1]
            if not data.Aragnid then
                npc:Remove()
                return
            end
        end

        data.bal = data.Aragnid:GetData().bal

        npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:ClearEntityFlags(EntityFlag.FLAG_CHARM)
        npc:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
        npc:ClearEntityFlags(EntityFlag.FLAG_PERSISTENT)

        npc.SplatColor = data.bal.TarColor

        REVEL.SetScaledBossSpawnHP(data.Aragnid, npc, data.bal.InnardHealthPercentage)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        data.StartMoveFrame = 0

        if data.Buffed then
            for i = 0, 1 do
                sprite:ReplaceSpritesheet(i, "gfx/bosses/revel2/aragnid/aragnid_innard_buffed.png")
            end

            sprite:LoadGraphics()
        end

        if not sprite:IsPlaying("Falling") and not sprite:IsPlaying("Emerge") then
            sprite:Play("Hide", true)
        end

        data.Init = true
    end

    if sprite:IsFinished("Land") or sprite:IsFinished("Emerge") then
        sprite:Play("Hide", true)
    end

    if sprite:IsFinished("SpewStart") then
        data.CreepsSpawned = nil
        sprite:Play("SpewLoop", true)
    end

    if sprite:IsFinished("SpewEnd") then
        if data.GoingToStart then
            data.GoingToStart = nil
            sprite:Play("SpewStart", true)
            REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
        else
            sprite:Play("Hide", true)
        end
    end

    if sprite:IsEventTriggered("Pop") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    elseif sprite:IsEventTriggered("Hide") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end

    if not data.AgitatedFrame and (data.SelfAgitate or #Isaac.FindByType(REVEL.ENT.ARAGNID.id, REVEL.ENT.ARAGNID.variant, -1, false, false) < 1) then
        if data.SelfAgitate and data.SelfAgitate > 0 then
            data.SelfAgitate = data.SelfAgitate - 1
        else
            data.AgitatedFrame = REVEL.game:GetFrameCount() + 60
            if sprite:IsPlaying("Hide") then
                sprite:Play("SpewStart", true)
                REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
            end

            data.SelfAgitate = nil
        end
    end

    if data.AgitatedFrame and sprite:IsPlaying("Hide") then
        sprite:Play("SpewStart", true)
        REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
    end

    if sprite:IsPlaying("SpewLoop") and sprite:GetFrame() == 0 then
        REVEL.sfx:Play(SoundEffect.SOUND_BOSS2_BUBBLES, 0.25, 0, false, 1)
    end

    if sprite:IsPlaying("SpewLoop") or sprite:IsPlaying("Explode") or sprite:IsFinished("Explode") or sprite:IsPlaying("Chase") or sprite:IsPlaying("Charge") or sprite:IsFinished("Charge") then
        local data = npc:GetData()
        if not data.AgitatedFrame then
            if not data.CreepsSpawned then
                data.CreepsSpawned = 0
                data.InitialAngle = math.random(1, 360)
            end

            if npc.FrameCount % data.bal.InnardSpawnRate == 0 and data.CreepsSpawned <= data.bal.InnardCreepNum then
                local pos
                if data.CreepsSpawned == 0 then
                    pos = npc.Position
                else
                    pos = npc.Position + (Vector.FromAngle(data.InitialAngle + data.CreepsSpawned * data.bal.InnardCreepAngleAdd) * data.bal.InnardCreepDistance)
                end

                data.CreepsSpawned = data.CreepsSpawned + 1

                if not data.Creeps then
                    data.Creeps = {}
                end

                local creep
                creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, pos, npc, false)
                --[[if data.Buffed then
                    creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, pos, npc, false)
                else
                    creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, pos, npc, false)
                end]]

                REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
                creep:ToEffect():SetTimeout(data.bal.InnardCreepNum - data.CreepsSpawned * data.bal.InnardSpawnRate + data.bal.InnardCreepFadeTime)

                data.Creeps[#data.Creeps + 1] = creep
            end

            if data.Creeps then
                for i, creep in ipairs(data.Creeps) do
                    local frame = creep.FrameCount
                    if creep:Exists() and frame <= data.bal.InnardCreepAppearTime then
                        if data.Buffed then
                            creep.Color = Color.Lerp(purpleInvisible, purpleVisible, frame / data.bal.InnardCreepAppearTime)
                        else
                            creep.Color = Color.Lerp(invisible, visible, frame / data.bal.InnardCreepAppearTime)
                        end
                        creep.SpriteScale = REVEL.Lerp(nothing, full, frame / data.bal.InnardCreepAppearTime)
                    else
                        table.remove(data.Creeps, i)
                    end
                end
            end

            if data.CreepsSpawned >= data.bal.InnardCreepNum and #data.Creeps == 0 then
                data.LastHideTime = REVEL.game:GetFrameCount()
                sprite:Play("SpewEnd", true)
                REVEL.sfx:Play(data.bal.Sounds.InnardSpewStart, 0.6, 0, false, 1)
            end
        else
            if sprite:IsFinished("Explode") then
                if not data.bal.InnardMagicBallReplaceSpider then
                    local count = data.bal.ThrowSpiders

                    if count > 0 then
                        for i = 1, count do
                            EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + RandomVector() * RandomFloat(50, 100), false, 0)
                        end
                    end
                else
                    if not data.Buffed then
                        REVEL.SpawnRevivalRag(npc, REVEL.ENT.ARAGNID_INNARD.id, REVEL.ENT.ARAGNID_INNARD.variant, 0)
                    elseif not data.Aragnid or not data.Aragnid:GetData().BloodRainTime then
                        ShootMagicBall(npc, data, 15)
                        REVEL.sfx:Play(data.bal.Sounds.MagicSplash, 0.6, 0, false, 1)
                    end
                end

                npc:Kill()
            elseif not sprite:IsPlaying("Explode") then
                if data.bal.InnardDashSpeed then
                    if sprite:IsFinished("Charge") then
                        sprite:Play("Chase", true)
                    elseif not sprite:IsPlaying("Chase") and not sprite:IsPlaying("Charge") then
                        sprite:Play("Charge", true)
                    end

                    if sprite:IsPlaying("Chase") then
                        local target = npc:GetPlayerTarget()
                        if not data.DashDirection then
                            data.DashDirection = (target.Position - npc.Position):Resized(data.bal.InnardDashSpeed)
                        end

                        npc.Velocity = data.DashDirection
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                        npc.CollisionDamage = 1

                        local collidesWithPlayer
                        for _, player in ipairs(REVEL.players) do
                            if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size + 10) ^ 2 then
                                collidesWithPlayer = true
                                break
                            end
                        end

                        if data.Aragnid and data.Aragnid.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
                            if data.Aragnid.Position:DistanceSquared(npc.Position) < (data.Aragnid.Size + npc.Size + 10) ^ 2 then
                                data.Aragnid:TakeDamage(data.bal.InnardDashImpactPercent, 0, EntityRef(npc), 0)
                                collidesWithPlayer = true
                            end
                        end

                        if npc:CollidesWithGrid() or collidesWithPlayer then
                            local radialOffset = math.random() * 360
                            for i = 1, data.bal.InnardDashRadial.TotalProjectiles do
                                local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, Vector.Zero, nil):ToProjectile()
                                proj:GetData().Innard = npc
                                proj.Color = data.bal.TarColor

                                if i > data.bal.InnardDashRadial.RadialProjectiles then
                                    proj.Position = proj.Position + RandomVector() * RandomFloat(10)
                                    proj.Velocity = RandomVector() * RandomFloat(2)
                                    proj.FallingSpeed = math.random(-80, -30)
                                    proj.FallingAccel = 1.5
                                else
                                    proj.Velocity = Vector.FromAngle(radialOffset + (i / data.bal.InnardDashRadial.RadialProjectiles) * 360) * data.bal.InnardDashRadial.RadialSpeed
                                end

                                proj:Update()
                            end

                            npc:Kill()
                        end
                    else
                        npc.Velocity = Vector.Zero
                    end
                else
                    if not sprite:IsPlaying("Chase") then
                        sprite:Play("Chase", true)
                    end

                    --melon: squirmy, accelerating movement
                    local target = npc:GetPlayerTarget()
                    local speedwiggle = (Vector(3, 0):Rotated((npc.FrameCount * 50) % 360)).X -- cosine for pro
                    local speedmod = .5 + (math.min(data.bal.InnardAccelTime, (REVEL.game:GetFrameCount() - data.StartMoveFrame)) / (data.bal.InnardAccelTime / .5))

                    npc.Velocity = (target.Position - npc.Position):Resized((data.bal.InnardSeekSpeed + speedwiggle) * speedmod)
                    if (REVEL.game:GetFrameCount() > data.AgitatedFrame) then
                        REVEL.sfx:Play(SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
                        sprite:Play("Explode", true)
                    end

                    npc.CollisionDamage = 1
                end
            elseif not data.Buffed or not data.Aragnid or not data.Aragnid:GetData().BloodRainTime then
                local proj = Isaac.Spawn(
                    EntityType.ENTITY_PROJECTILE, 
                    ProjectileVariant.PROJECTILE_NORMAL, 
                    0, npc.Position + RandomVector() * RandomFloat(10), 
                    RandomVector() * RandomFloat(2), 
                    nil
                ):ToProjectile()
                proj:GetData().Innard = npc

                if data.Buffed then
                    proj.ProjectileFlags = ProjectileFlags.SMART
                    proj.HomingStrength = 0.4
                else
                    proj.Color = data.bal.TarColor
                end

                proj.FallingSpeed = math.random(-80, -30)
                proj.FallingAccel = 1.5
                proj:Update()
                npc.Velocity = Vector.Zero
                npc.CollisionDamage = 0
            end
        end
    end
end, REVEL.ENT.ARAGNID_INNARD.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant ~= REVEL.ENT.ARAGNID_INNARD.variant or REVEL.game:IsPaused()
    or not REVEL.IsRenderPassNormal() then
        return
    end

    local sprite = npc:GetSprite()
    if sprite:IsPlaying("Falling") then
        local data = npc:GetData()
        local height = npc.SpriteOffset.Y
        if height < 0 then
            height = height + data.FallingSpeed
            data.FallingSpeed = data.FallingSpeed + data.FallingAcceleration
        else
            sprite:Play("Land", true)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 0.8, 0, false, 1)
        end

        npc.SpriteOffset = Vector(0, math.min(height, 0))
    else
        npc.Velocity = Vector.Zero
    end
end, REVEL.ENT.ARAGNID_INNARD.id)

local innardRelayedDamage
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, cooldown)
    if ent.Variant == REVEL.ENT.ARAGNID_INNARD.variant then
        if not ent:GetData().AgitatedFrame then
            if ent:GetData().Aragnid then
                local aragnid = ent:GetData().Aragnid
                local adata = aragnid:GetData()

                if adata.NumInnardsRelayedDamageInFrame and adata.NumInnardsRelayedDamageInFrame < 1 then
                    innardRelayedDamage = true
                    ent:GetData().Aragnid:TakeDamage(amount, flags, source, cooldown)
                    innardRelayedDamage = nil
                    adata.NumInnardsRelayedDamageInFrame = adata.NumInnardsRelayedDamageInFrame + 1
                end
            end

            if ent.HitPoints - amount - REVEL.GetDamageBuffer(ent) <= 0 then
                ent:GetData().AgitatedFrame = -1000
                return false
            end
        else
            ent:GetData().AgitatedFrame = -1000
            return false
        end
    end
end, REVEL.ENT.ARAGNID_INNARD.id)

local bloodRainDoubledDamage
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, cooldown)
    if ent.Variant == REVEL.ENT.ARAGNID.variant then
        local data = ent:GetData()
        if (not innardRelayedDamage or (data.bal.EternalMagicBloodRain and data.BloodRainTime)) and not bloodRainDoubledDamage then
          local armormod = data.ArmorMod or 1
          innardRelayedDamage = true
          bloodRainDoubledDamage = true

          if data.bal.EternalMagicBloodRain and data.BloodRainTime then
              armormod = 2
          end

		  local dmg = math.min(amount * 0.75 * armormod, ent.HitPoints - REVEL.GetDamageBuffer(ent) - 1)
		  ent.HitPoints = ent.HitPoints - dmg
          --ent:TakeDamage(amount * 0.75 * armormod, flags, source, cooldown)
          innardRelayedDamage = nil
          bloodRainDoubledDamage = nil
        end
    end
end, REVEL.ENT.ARAGNID.id)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function() -- just in case
    REVEL.sfx:Stop(aragnidBalance.Sounds.RainLoop)
end)

end
REVEL.PcallWorkaroundBreakFunction()