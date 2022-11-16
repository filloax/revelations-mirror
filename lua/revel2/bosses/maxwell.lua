local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local MaxwellBalance = {
    Champions = {Craxwell = "Default", Ruthless = "Default"},

    -- Maxwell's Iconic Crazy Dynamic Hopping System
    ---@type table<string, MaxwellHop>
    Hops = {
        Start = {
            Anim = "Hop Start",
            Fall = "Hop Start Fall",
            TriggerTrapdoors = true,
            Duration = 14,
            Start = -12,
            End = -6,
            Peak = -32,
            TimeToPeak = 5,
            TimeFromPeak = 8
        },
        Shoot = {
            Anim = "Hop Shoot",
            Fall = "Hop Middle Fall",
            TriggerTrapdoors = true,
            SlamDunk = true,
            Duration = 37,
            Start = -6,
            StartSprung = -24,
            End = -6,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 13
        },
        Middle = { -- used for champ & in finale
            Anim = "Hop Middle",
            Fall = "Hop Middle Fall",
            TriggerTrapdoors = true,
            SlamDunk = true,
            Duration = 37,
            Start = -6,
            StartSprung = -24,
            End = -6,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 13
        },
        End = {
            Anim = "Hop End",
            Duration = 14,
            Start = -12,
            End = -6,
            Peak = -32,
            TimeToPeak = 5,
            TimeFromPeak = 8
        },
        BubblePopBefore = {
            Anim = "Hop Bubble Pop 1",
            SlamDunk = true,
            Duration = 23,
            Start = -6,
            End = -12 + -24,
            Peak = -52 + -24,
            TimeToPeak = 11,
            TimeFromPeak = 8
        },
        BubblePopAfter = {
            Anim = "Hop Bubble Pop 2",
            Fall = "Hop Middle Fall",
            TriggerTrapdoors = true,
            SlamDunk = true,
            Duration = 19,
            Start = -12 + -24,
            End = -6,
            Peak = -62 + -24,
            TimeToPeak = 6, -- either peak of 62 and time of 6 or peak of 60 and time of 4, not sure.
            TimeFromPeak = 12 -- try 6 if this doesn't work well
        },
        MessageStart = {
            TriggerTrapdoors = true,
            Duration = 14,
            Start = -6,
            End = -6,
            Peak = -32,
            TimeToPeak = 5,
            TimeFromPeak = 8
        },
        MessageStartChampion = {
            Duration = 14,
            Start = -6,
            End = 0,
            Peak = -32,
            TimeToPeak = 5,
            TimeFromPeak = 8
        },
        MessageMiddle = {
            Duration = 37,
            Start = -6,
            StartSprung = -24,
            End = -24,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 13
        },
        CraxwellAltOne = {
            Anim = "Champion Hop Alt 1",
            Fall = "Hop Start Fall",
            TriggerTrapdoors = true,
            Duration = 37,
            Start = -6,
            StartSprung = -24,
            End = -6,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 13
        },
        CraxwellAltTwo = {
            Anim = "Champion Hop Alt 2",
            Fall = "Champion Hop Alt 2 Fall",
            TriggerTrapdoors = true,
            Duration = 37,
            Start = -6,
            StartSprung = -24,
            End = -6,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 13
        },
        Bomb = {
            Anim = "Champion Hop Bomb",
            Fall = "Hop Middle Fall",
            TriggerTrapdoors = true,
            SlamDunk = true,
            Duration = 72,
            Start = -6,
            StartSprung = -24,
            End = -6,
            Peak = -52,
            TimeToPeak = 14,
            TimeFromPeak = 6
        }
    },

    HopDefaultAccel = 2.5, -- these are exponential modifiers to the hop peak interpolation. Decelerates when reaching peak, accelerates when leaving peak.
    HopDefaultDecel = 2.5,

    SlamDunkHitboxY = 55,

    ShootHeightHop = -60,
    ProjectileCount = {
        DefaultShot = 4,
        DoubleHop = {Default = 4, Ruthless = 6},
        PortalHop = {Default = 3, Ruthless = 5},
        JumpRope = {Default = 1, Ruthless = 2},
        BrimstoneBarrier = 2,
        ArrowSpecial = 2,
        BubbleBlast = 10
    },
    ProjectileSpeed = {
        DefaultShot = 10,
        DoubleHop = 11,
        PortalHop = 9.5,
        JumpRope = 8,
        BubbleBlast = 11.75
    },
    ShootCone = {
        DefaultShot = 12.5,
        DoubleHop = {Default = 12.5, Ruthless = 20},
        PortalHop = {Default = 35, Ruthless = 60},
        BrimstoneBarrier = 20,
        BubbleBlast = 37.5
    }, -- projectiles go from -cone to +cone degrees
    FloorBounceCount = {
        DefaultShot = 4,
        DoubleHop = {Default = 4, Ruthless = 8},
        PortalHop = {Default = 4, Ruthless = 8},
        JumpRope = 6,
        ArrowSpecial = 6,
        BubbleBlast = 3
    },
    WallBounce = {
        DefaultShot = true,
        PortalHop = {Default = true, Ruthless = false},
        GrandFinale = {Default = false, Ruthless = true}
    },
    InfiniteWallBounce = {
        DefaultShot = {Default = false, Ruthless = true},
        PortalHop = false,
        BubbleBlast = false
    },
    FromDoor = {
        DefaultShot = false,
        JumpRope = true
    },

    BubbleHeight = -24,
    BubblePopSplashProjectiles = 12,
    BubblePopSplashTrajectoryModifier = 10,
    BubblePopProjectileBounces = {
        Default = {2, 3, 4, 6, 8, 10, 12, 15},
        Ruthless = {3, 4, 6, 8, 12, 15, 25, 25, 25}
    },
    BubblePopProjectileSpeed = 7,

    InitialAttackCooldown = {
        Default = 10,
        Ruthless = 0,
        Craxwell = 30
    },

    -- Attacks
    Cycle = {
        Default = {
            {
                Attacks = {
                    DoubleHop = 1
                },
                Repeat = {
                    Min = 0,
                    Max = 1
                },
                CooldownBetween = 20,
                IsHop = true
            },
            {
                Attacks = {
                    ThinkingWithPortals = 1,
                    Elevator = 1
                },
                CooldownAfter = 60,
                IsHop = true
            },
            {
                Attacks = {
                    BulletYell = 1,
                    BombTheSpot = 1
                },
                CooldownAfter = 30,
                WaitIdleDoors = true,
                WaitIdleTraps = true,
                WaitEnemies = true,
            },
            {
                Attacks = {
                    JumpRope = 1
                },
                WaitIdleDoors = true,
                WaitIdleTraps = true,
                WaitEnemies = true
            },
            {
                Attacks = {
                    BubblePop = 1
                },
                IsHop = true
            }
        },
        Ruthless = {
            {
                Attacks = {
                    DoubleHop = 1
                },
                Repeat = {
                    Min = 0,
                    Max = 1
                },
                CooldownBetween = 10,
                IsHop = true
            },
            {
                Attacks = {
                    ThinkingWithPortals = 1
                },
                Repeat = {
                    Min = 0,
                    Max = 1
                },
                CooldownBetween = 45,
                IsHop = true,
                WaitEnemies = true
            },
            {
                Attacks = {
                    Elevator = 1
                },
                CooldownBetween = 45,
                CooldownAfter = 60,
                IsHop = true
            },
            {
                Attacks = {
                    BulletYell = 1,
                    BombTheSpot = 1
                },
                CooldownAfter = 30,
                WaitIdleDoors = true,
                WaitIdleTraps = true,
                WaitEnemies = true,
            },
            {
                Attacks = {
                    JumpRope = 1
                },
                WaitIdleDoors = true,
                WaitIdleTraps = true,
                WaitEnemies = true
            },
            {
                Attacks = {
                    BubblePop = 1,
                    BubbleBlast = 1
                },
                IsHop = true,
                NotHop = {BubbleBlast = true}
            },
            {
                Attacks = {
                    ThinkingWithPortals = 1,
                    Elevator = 1,
                    DoubleHop = 1
                },
                CooldownBetween = 45,
                IsHop = true
            }
        },
        Craxwell = {
            {
                Attacks = {
                    DoubleHop = 1
                },
                Repeat = {
                    Min = 0,
                    Max = 1
                },
            },
            {
                Attacks = {
                    ThinkingWithPortals = 1,
                    Elevator = 1
                },
                CooldownAfter = 60,
                IsFall = true
            },
            {
                Attacks = {
                    DoubleHop = 1
                }
            },
            {
                Attacks = {
                    TrapSmash = 1,
                    Seesaw = 1
                },
                WaitIdleDoors = true,
                CooldownAfter = 30
            },
            {
                Attacks = {
                    BrimstoneBarrier = 1
                },
                WaitIdleDoors = true,
                WaitIdleTraps = true,
                WaitEnemies = true,
                CooldownAfter = 20
            },
            {
                Attacks = {
                    BubblePop = 1
                }
            }
        },
    },
    -- If enabled, will always be used
    -- DebugCycle = {
    --     {
    --         Attacks = {
    --             JumpRope = 1
    --         },
    --         WaitIdleDoors = true,
    --         WaitIdleTraps = true,
    --         WaitEnemies = true
    --     },
    --     {
    --         Attacks = {
    --             BubblePop = 1
    --         },
    --         IsHop = true
    --     },
    -- },

    AttackCycleDefaultCooldownBetween = 20,
    AttackCycleDefaultCooldown = 40,

    AttackCycleNonRepeatWeight = 10, -- multiplies the weight of every attack that isn't the last used attack in this cycle by this amount
    SideAttackNonRepeatWeightMulti = 3,
    CycleStartCheck = function(data, bal, curCycleSegment, _, _, doors, trapdoors)
        local isOkay = true
        if curCycleSegment.WaitIdleDoors then
            for _, door in ipairs(doors) do
                if door:GetData().State ~= "Idle" then
                    isOkay = false
                end
            end
        end

        local shouldBeTraps
        if curCycleSegment.WaitEnemies then
            local enemyCount = 0
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsVulnerableEnemy() and not enemy:IsBoss() and not REVEL.ENT.MAXWELL_DOOR:isEnt(enemy) 
                and enemy:IsActiveEnemy(false) and not enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) then
                    enemyCount = enemyCount + 1
                end
            end

            if enemyCount ~= 0 then
                isOkay = false
                shouldBeTraps = true
                for _, trap in ipairs(trapdoors) do
                    if trap:GetData().State ~= "Trap" and trap:GetData().State ~= "Trap Switch" and trap:GetData().TargetState ~= "Trap" then
                        trap:GetData().TargetState = "Trap"
                        trap:GetData().NewTrap = bal.EnemyKillingTraps[math.random(1, #bal.EnemyKillingTraps)]
                    end
                end
            end
        end

        if shouldBeTraps then
            if not data.DoorsTrackPlayer then
                for _, door in ipairs(doors) do
                    if not door:GetData().TopDoor and door:GetData().State == "Idle" then
                        door:GetSprite():Play("Door Move Closed", true)
                    end
                end

                data.DoorsTrackPlayer = true
            end
        else
            data.DoorsTrackPlayer = nil
            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetData().TargetState = "IdleNoMove"
                end
            end
        end

        if curCycleSegment.WaitIdleTraps then
            for _, trap in ipairs(trapdoors) do
                if trap:GetData().State ~= "Spring" and trap:GetData().State ~= "Spring Triggered" then
                    if not trap:GetData().TargetState and not shouldBeTraps then
                        trap:GetData().TargetState = "Spring"
                    end
                    isOkay = false
                end
            end
        end

        return isOkay
    end,

    EnemyKillingTraps = {"Arrow", "Fire", "Boulder"},

    PortalHops = {
        Default = {
            Min = 4,
            Max = 5
        },
        Ruthless = {
            Min = 5,
            Max = 6
        }
    },

    IdleBeforeHop = {
        Default = 20,
        Ruthless = 10
    },

    SideAttacks = {
        TrollBombs = {
            Default = 2,
            Ruthless = 3
        },
        BigBall = 1,
        CurvingFan = 1,
        Whip = {
            Default = 1,
            Ruthless = 2
        }
    },

    SideAttackBombs = {
        Default = {
            Min = 3,
            Max = 3
        },
        Ruthless = {
            Min = 4,
            Max = 4
        }
    },

    SideAttackCooldown = {
        Default = {
            Min = 40,
            Max = 60
        },
        Ruthless = {
            Min = 25,
            Max = 40
        }
    },

    WhipDuration = 55,
    WhipBreatheDistanceFromCenter = {Default = 0.15, Ruthless = .2},
    WhipBreatheDuration = {
        Default = 7,
        Ruthless = 5
    },
    WhipProjectileVelocity = {
        Default = 15,
        Ruthless = 11
    },
    WhipProjectileFrequency = 2,
    WhipProjectileAngles = {
        Left = 184,
        Right = -4
    },
    WhipShotOffsetX = Vector(8, 0),

    TopDoorYOffset = Vector(0, 24),

    BulletYellDuration = {
        Min = 240,
        Max = 360
    },
    BulletYellTraps = {"Arrow", "Fire", "Boulder", "Enemies"},
    BulletYellTrapSwitchTime = {
        Min = 60,
        Max = 90
    },

    BombTheSpotIdle = 0,
    BombTheSpotIdleAfter = 40,
    BombTheSpotBombs = {
        Default = {
            Min = 3,
            Max = 3
        },
        Ruthless = {
            Min = 3,
            Max = 4
        }
    },
    BombTheSpotRepeats = {
        Min = 4,
        Max = 5
    },
    BombTheSpotOffset = {
        Left = Vector(26, 18),
        Right = Vector(-26, 18)
    },
    BombTheSpotDamagePerFrame = 1 / 30 / 9, -- % of max HP dealt every frame before the bounce trigger when you step on max in bomb the spot.
    BombTheSpotJukeChance = 4, -- 1/this number chance that max does the same trapdoor twice in a row
    BombTheSpotTraps = {"Arrow", "Fire", "Boulder"},

    JumpRopeCycleTime = {
        Default = {
            Min = 50,
            Max = 100
        },
        Ruthless = {
            Min = 35,
            Max = 80
        }
    },
    JumpRopeJumpSpeedCap = { -- number of cycles at which cycle speed caps
        Default = 4,
        Ruthless = 3
    },
    JumpRopeAccel = 1.25,
    JumpRopeDecel = 1.25,
    DoorEdgeThreshold = 20,
    JumpRopeNumPasses = {
        Default = {
            Min = 5,
            Max = 5
        },
        Ruthless = {
            Min = 6,
            Max = 8
        }
    },
    JumpRopeBrimstoneOffset = 30,
    JumpRopeSpringBlockRadius = 50,
    JumpRopeStartBulletCooldown = {Default = 40, Ruthless = 15},
    JumpRopeBulletCooldown = {Default = 15, Ruthless = 0},

    GrandFinaleCycleTime = {
        Default = 165,
        Ruthless = 135,
        Craxwell = 120
    },
    GrandFinaleIdleTime = {
        Default = 30,
        Ruthless = 10
    },
    GrandFinaleHopTrigger = { -- % of the way through a brim cycle that max enters his door / jumps across for craxwell
        Default = 0.8,
        Ruthless = 0.9,
        Craxwell = 0.3
    },
    GrandFinaleProjectileBounces = {
        Default = {2, 3, 4, 6, 8, 8, 10, 12, 15},
        Ruthless = {3, 4, 4, 5, 5, 6, 6, 7, 8, 10, 12, 15}
    },
    GrandFinaleBrimstoneSplashThreshold = 10,
    GrandFinaleThreshold = {
        Default = 0.25,
        Ruthless = 0.3,
        Craxwell = 0.2
    },

    ImmuneToFlags = {
        EntityFlag.FLAG_SLOW,
        EntityFlag.FLAG_FREEZE,
        EntityFlag.FLAG_CONFUSION
    },

    SpitMessageTime = {
        Default = 30 * 20,
        Craxwell = 30 * 10
    },
    SpitMessage = {
        Default = {"Took you a while", "-Maxwell"},
        Craxwell = {"oh, come on", "-Craxwell"}
    },

    ElevatorEnemies = {
        ARROWHEAD = 1,
        RAG_GAPER = 2,
        RAG_BONY = 2
    },

    ElevatorEnemyToAnimName = {
        ARROWHEAD = "Arrowhead",
        RAG_GAPER = "Gaper",
        RAG_BONY = "Bony"
    },

    TrapdoorRadius = 30,
    TrapdoorRadiusRaised = 56,
    TrapdoorPitfallRadius = 20,
    TrapdoorRaisedHeight = -23,
    TrapdoorRaisedTriggerHeight = -33,
    TrapdoorCenterOffset = 120,
    TrapdoorPushedSpringCooldown = 10,

    SpringCooldown = nil,
    MaxwellSpringCooldown = {
        Default = 30,
        Ruthless = 45,
        Craxwell = 45
    },

    IsCraxwell = {
        Default = false,
        Craxwell = true
    },
    CraxwellIntroDelay = 15,

    CraxwellSeesawLowerCooldown = 25,

    SeesawSpecialBombFrame = 30,
    SeesawSpecialBombHeight = -300,
    SeesawSpecialMaxwellFrame = 60,
    SeesawSpecialDamage = 1 / 30,
    SeesawFlingIdleTime = 35,
    SeesawFlingBombTime = 15,

    SeesawRepeats = {
        Min = 4,
        Max = 5
    },
    SeesawTraps = {"Arrow", "Fire", "Boulder", "Enemies"},

    TrapSmashDuration = {
        Min = 240,
        Max = 360
    },
    TrapSmashTraps = {"Arrow", "Fire", "Boulder"},

    BrimstoneBarrierDuration = {
        Min = 480,
        Max = 540
    },
    BrimstoneBarrierAttacks = {
        Boulder = 1,
        Arrow = 1,
        Fire = 1
    },
    BarrierAttackNonRepeatMulti = 10,
    SpecialBoulderCount = 3,
    SpecialFlameTrapCooldownMult = 4,
    SpecialArrowAngles = {-45, -20, 20, 45},

    FlameTrapCooldownMult = {
        Default = 1.6,
        Ruthless = 1.7,
        Craxwell = 1.8
    },

    CraxwellIdleHops = {
        Middle = 4,
        --CraxwellAltOne = 3,
        CraxwellAltTwo = 1
    },

    CraxwellNonHopIdleAnims = {
        "Champion Hop From Pit",
        "Champion Hop From Elevator"
    },

    CraxwellBombHopHeight = {0, -16, -28},

    HealthMulti = {
        Default = false,
        Ruthless = 1.1,
        Craxwell = 1.25
    },

    Spritesheet = {
        Default = false,
        Craxwell = "gfx/bosses/revel2/maxwell/craxwell.png",
		Ruthless = "gfx/bosses/revel2/maxwell/maxwell_ruthless.png"
    },
    TrapSpritesheet = {
        Default = false,
        Ruthless = "gfx/bosses/revel2/maxwell/maxwell_trapdoor_ruthless.png"
    },
    DoorSpritesheet = {
        Default = false,
        Craxwell = "gfx/bosses/revel2/maxwell/craxwell_doors.png"
    },
    SkipTopDoorSheet = true,

    CoffinEnemies = {
        Default = {RAG_GAPER = 1, RAG_BONY = 1},
        Ruthless = {RAG_GAPER = 1, RAG_BONY = 1, RAG_DRIFTY = 1}
    },

    AttackNames = {
        DoubleHop = "Double Hop",
        ThinkingWithPortals = "Thinking With Portals",
        Elevator = "Elevator",
        BulletYell = "Bullet Yell",
        BombTheSpot = "Bomb The Spot",
        JumpRope = "Jump Rope",
        BubblePop = "Bubble Pop",
        GrandFinale = "Grand Finale",
        TrapSmash = "Trap Smash",
        Seesaw = "Seesaw",
        BrimstoneBarrier = "Brimstone Barrier",
        BubbleBlast = "Bubble Blast",

        -- Side Attacks
        TrollBombs = "Troll Bombs",
        BigBall = "Big Bouncing Ball",
        CurvingFan = "Curving Fan",
        Whip = "Bullet Whip"
    },

    BlenderDeath = true,
    BlenderDeathFrames = 320,
    BlenderKillMaxwellAt = 60,
    Sounds = {
        -- Traps
        ChangePit = {Sound = REVEL.SFX.COFFIN_OPEN, Volume = 0.6},
        Spring = {Sound = REVEL.SFX.SPRING, Pitch = 0.95, PitchVariance = 0.1},
        ActivateTrap = {Sound = REVEL.SFX.ACTIVATE_TRAP},
        Blender = {Sound = REVEL.SFX.MAXWELL_BLENDER_DEATH},

        -- Doors
        FireStart = {Sound = REVEL.SFX.FIRE_START, Volume = 0.3},
        FireStop = {Sound = REVEL.SFX.FIRE_END, Volume = 0.3},
        DoorShoot = {Sound = SoundEffect.SOUND_STONESHOOT, Volume = 1, Pitch = 2},
        DoorBreak = {Sound = REVEL.SFX.BOULDER_BREAK},
        BrimstoneTell = {Sound = REVEL.SFX.MAXWELL_BRIMSTONE_TELL},
        ShootBubble = {Sound = REVEL.SFX.MAXWELL_BUBBLE_SHOOT},
        PopBubble = {Sound = REVEL.SFX.MAXWELL_BUBBLE_POP},

        -- Maxwell
        ThrowBomb = {{Sound = REVEL.SFX.MAXWELL_LAUGH, Volume = 0.8, PitchVariance = 0.1}, {Sound = SoundEffect.SOUND_SHELLGAME, Volume = 0.4}},
        SlamDunk = {Sound = REVEL.SFX.MAXWELL_SLAM_DUNK},
        SlamDunkImpact = {Sound = REVEL.SFX.MAXWELL_SLAM_DUNK_IMPACT},
        Crushed = {Sound = REVEL.SFX.MAXWELL_SQUISH, Volume = 1.1},
        LongFall = {{Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS, Volume = 0.5}, {Sound = REVEL.SFX.MAXWELL_SQUISH, Volume = 1.1}},
        ChampionLand = {Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS, Volume = 0.7},
        Portal1 = {Sound = REVEL.SFX.MAXWELL_PORTAL1, Volume = 0.8},
        Portal2 = {Sound = REVEL.SFX.MAXWELL_PORTAL2, Volume = 0.8},
        Elevator = {Sound = REVEL.SFX.ELEVATOR, Volume = 0.8},
        Shoot = {Sound = REVEL.SFX.MAXWELL_ATTACK, Volume = 1, PitchVariance = 0.06},
        ShootFromDoor = {Sound = REVEL.SFX.MAXWELL_COUGH, Volume = 1, PitchVariance = 0.06},
        ShootBig = {Sound = REVEL.SFX.MAXWELL_COUGH, Pitch = 0.9},
        Breathe = {Sound = REVEL.SFX.MAXWELL_INHALE, Volume = 1, Pitch = 1.1},
        -- FinaleStart
        -- ChangePhase
        -- Flung
    }
}

REVEL.MaxwellBalance = MaxwellBalance

---@class MaxwellHop
---@field Anim string
---@field Fall string
---@field TriggerTrapdoors boolean
---@field SlamDunk boolean
---@field Duration integer
---@field Start integer
---@field StartSprung integer
---@field End integer
---@field Peak integer
---@field TimeToPeak integer
---@field TimeFromPeak integer
---@field Accel number
---@field Decel number

---@param frame integer
---@param hop MaxwellHop
---@param sprung? boolean
---@return number
local function GetMaxwellHopHeight(frame, hop, sprung)
    if frame <= hop.TimeToPeak then
        local inverted = 1 - (frame / hop.TimeToPeak)
        inverted = inverted ^ (hop.Decel or MaxwellBalance.HopDefaultDecel)
        local start = hop.Start
        if sprung and hop.StartSprung then
            start = hop.StartSprung
        end

        return REVEL.Lerp(start, hop.Peak, 1 - inverted)
    elseif hop.Duration - frame > hop.TimeFromPeak then
        return hop.Peak
    else
        local timeSincePeak = hop.TimeFromPeak - (hop.Duration - frame)
        return REVEL.Lerp(hop.Peak, hop.End, (timeSincePeak / hop.TimeFromPeak) ^ (hop.Accel or MaxwellBalance.HopDefaultAccel))
    end
end

---@param npc EntityNPC
---@param data table
---@param trapdoors EntityNPC[]
---@param setSpringCooldown? integer
local function MaxwellTriggerSpringsFast(npc, data, trapdoors, setSpringCooldown)
    for _, trapdoor in ipairs(trapdoors) do
        if (trapdoor:GetData().State == "Spring" or trapdoor:GetData().State == "Spring Shaking") and trapdoor.Position:DistanceSquared(npc.Position) < 8 ^ 2 then
            data.Sprung = true
            trapdoor:GetData().State = "Spring Triggered"
            trapdoor:GetData().SpringCollidingPlayers = true
            if setSpringCooldown then
                trapdoor:GetData().SpringCooldown = setSpringCooldown
            end

            trapdoor:GetSprite():Play("Trap Spring Trigger Fast", true)
        end
    end
end

---@param npc EntityNPC
---@param data table
local function TotalCancelHop(npc, data)
    npc.SpriteOffset = Vector.Zero
    data.CurrentSpriteOffset = nil
    data.TargetSpriteOffset = nil
    data.InterpolationFrame = nil
    data.Arcs = nil
    data.Hopping = nil
end

---@param npc EntityNPC
---@param spriteOrFrame Sprite | integer
---@param data? table
---@param trapdoors? Entity[]
---@param setSpringCooldown? integer
---@param balanceTable? table
---@return MaxwellHop
---@return boolean
local function ManageHoppingObject(npc, spriteOrFrame, data, trapdoors, setSpringCooldown, balanceTable)
    data = data or npc:GetData()
    balanceTable = balanceTable or data.bal or MaxwellBalance
    trapdoors = trapdoors or REVEL.ENT.MAXWELL_TRAP:getInRoom()

    local arc = data.Arcs[1]
    ---@diagnostic disable-next-line: need-check-nil
    local hopData = balanceTable.Hops[arc.HopType]
    local frame, sprite

    if type(spriteOrFrame) == "number" then
        frame = spriteOrFrame
        sprite = nil
    else
        sprite = spriteOrFrame
        frame = nil
    end

    if sprite then
        if data.NewArc or (not sprite:IsPlaying(hopData.Anim) and not sprite:IsFinished(hopData.Anim)) then
            sprite:Play(hopData.Anim, true)
        end

        frame = sprite:GetFrame()
    end

    if arc.StartPos and arc.EndPos then
        npc.Velocity = REVEL.Lerp(arc.StartPos, arc.EndPos, frame / hopData.Duration) - npc.Position
    end

    data.InterpolationFrame = true
    data.CurrentSpriteOffset = npc.SpriteOffset
    data.TargetSpriteOffset = Vector(0, GetMaxwellHopHeight(frame, hopData, data.Sprung))
    data.NewArc = nil

    if (sprite and sprite:IsFinished(hopData.Anim)) or (not sprite and frame == hopData.Duration) then
        table.remove(data.Arcs, 1)
        data.Sprung = nil
        if data.Arcs[1] == "Fall" then
            data.Arcs = {}
            if sprite then
                sprite:Play(hopData.Fall, true)
            end
        elseif hopData.TriggerTrapdoors then
            MaxwellTriggerSpringsFast(npc, data, trapdoors, setSpringCooldown)
        end

        if #data.Arcs == 0 then
            TotalCancelHop(npc, data)
        end

        data.NewArc = true

        return hopData, true
    end

    return hopData, false
end

---@param laser EntityLaser
---@param trapdoors EntityNPC[]
---@param data table
---@param laserXOrY number
---@param laserPos Vector
local function TrapdoorsBlockLaser(laser, trapdoors, data, laserXOrY, laserPos)
    for _, trapdoor in ipairs(trapdoors) do
        if trapdoor:GetSprite():IsPlaying("Trap Spring Trigger") then
            local isDown = laser.Angle == 90
            if not isDown and math.abs(laserXOrY - trapdoor.Position.Y) < data.bal.JumpRopeSpringBlockRadius then
                laser:SetMaxDistance(math.abs(laserPos.X - trapdoor.Position.X) - data.bal.TrapdoorRadius)
            elseif isDown and math.abs(laserXOrY - trapdoor.Position.X) < data.bal.JumpRopeSpringBlockRadius then
                laser:SetMaxDistance(math.abs(laserPos.Y - trapdoor.Position.Y) - data.bal.TrapdoorRadius)
            end
        end
    end
end

---@param start number
---@param target number
---@param cycleTime integer
---@param cycleLength integer
---@param accel number
---@param decel number
---@param halfPass? boolean
---@return number progress
---@return number cycleLength
local function CalculateJumpRopeProgress(start, target, cycleTime, cycleLength, accel, decel, halfPass)
    if halfPass then
        cycleLength = cycleLength / 2
    end

    local cycleProgress = math.min(1, cycleTime / cycleLength) ^ accel
    local invertedCycleProgress = 1 - cycleProgress
    invertedCycleProgress = invertedCycleProgress ^ decel

    return REVEL.Lerp(start, target, 1 - invertedCycleProgress), cycleLength
end

local function IsBelowFinaleThreshold(npc, data)
    return npc.HitPoints < npc.MaxHitPoints * data.bal.GrandFinaleThreshold
end

local triggeredBossMusic = false

REVEL.PushBlacklist[REVEL.ENT.MAXWELL.id] = {REVEL.ENT.MAXWELL.variant}

StageAPI.AddCallback("Revelations", "POST_SELECT_BOSS_MUSIC", 1, function(stage, musicID, isCleared, rng)
    if musicID == REVEL.SFX.TOMB_BOSS and StageAPI.GetCurrentRoomType() == RevRoomType.TRAP_BOSS_MAXWELL and not isCleared and not triggeredBossMusic then
        return REVEL.SFX.WIND
    elseif musicID == REVEL.SFX.TOMB_BOSS and StageAPI.GetCurrentRoomType() == RevRoomType.TRAP_BOSS_MAXWELL and REVEL.MaxwellReplacementMusic then
        return REVEL.MaxwellReplacementMusic
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)

    triggeredBossMusic = false

    if StageAPI.GetCurrentRoomType() == RevRoomType.TRAP_BOSS_MAXWELL 
    and REVEL.room:IsClear()
    and not REVEL.level:IsAscent()
    then
        local c, br, tl = REVEL.room:GetCenterPos(), REVEL.room:GetBottomRightPos(), REVEL.room:GetTopLeftPos()
        local t1 = REVEL.ENT.MAXWELL_TRAP:spawn( Vector( c.X - MaxwellBalance.TrapdoorCenterOffset , c.Y), Vector.Zero, nil) --center-left
        t1:GetData().State = "Spring"
        t1:GetSprite():SetFrame("Spring", 0)
        local t2 = REVEL.ENT.MAXWELL_TRAP:spawn( Vector( c.X + MaxwellBalance.TrapdoorCenterOffset , c.Y), Vector.Zero, nil) --center-right
        t2:GetData().State = "Spring"
        t2:GetSprite():SetFrame("Spring", 0)

        t1:GetData().bal = REVEL.GetBossBalance(MaxwellBalance, "Default")
        t2:GetData().bal = REVEL.GetBossBalance(MaxwellBalance, "Default")
        t1:GetData().LeftTrapdoor = true
        t2:GetSprite().FlipX = true
        t1:GetData().Opposite = t2
        t2:GetData().Opposite = t1
    end
end)

---@param max EntityNPC
---@param maxData table
local function prepareRoom(max, maxData)
    local trapdoors = REVEL.ENT.MAXWELL_TRAP:getInRoom()
    local doors = REVEL.ENT.MAXWELL_DOOR:getInRoom()

    local c, br, tl = REVEL.room:GetCenterPos(), REVEL.room:GetBottomRightPos(), REVEL.room:GetTopLeftPos()
    if #trapdoors == 0 and #doors == 0 then
        trapdoors[1] = REVEL.ENT.MAXWELL_TRAP:spawn( Vector( c.X - maxData.bal.TrapdoorCenterOffset , c.Y), Vector.Zero, nil) --center-left
        trapdoors[1]:GetData().State = "Spring"

        trapdoors[2] = REVEL.ENT.MAXWELL_TRAP:spawn( Vector( c.X + maxData.bal.TrapdoorCenterOffset , c.Y), Vector.Zero, nil) --center-right
        trapdoors[2]:GetData().State = "Spring Raised"
        trapdoors[2]:GetSprite().FlipX = true

        trapdoors[1]:GetData().Opposite = trapdoors[2]
        trapdoors[2]:GetData().Opposite = trapdoors[1]

        doors[1] = REVEL.ENT.MAXWELL_DOOR:spawn( Vector( tl.X, c.Y), Vector.Zero, nil) --left
        doors[1]:GetSprite().Rotation = -90

        doors[2] = REVEL.ENT.MAXWELL_DOOR:spawn( Vector( br.X, c.Y), Vector.Zero, nil) --right
        doors[2]:GetSprite().Rotation = 90

        doors[1]:GetData().Opposite = doors[2]
        doors[2]:GetData().Opposite = doors[1]

        trapdoors[1]:GetData().CloseDoor = doors[1]
        trapdoors[2]:GetData().CloseDoor = doors[2]

        doors[3] = REVEL.ENT.MAXWELL_DOOR:spawn( Vector( c.X, tl.Y), Vector.Zero, nil) --top

        for i, door in ipairs(doors) do
            local data = door:GetData()
            data.bal = maxData.bal
            data.State = "Idle"

            data.CenterPos = REVEL.CloneVec(door.Position)
            if i == 3 then
                data.TopDoor = true
                data.LeftPos = Vector(tl.X+30, door.Position.Y)
                data.RightPos = Vector(br.X-30, door.Position.Y)
            else
                data.LeftDoor = door:GetSprite().Rotation == -90
                data.TopPos = Vector(door.Position.X, tl.Y+20)
                data.BottomPos = Vector(door.Position.X, br.Y-20)--0.5 grid above bottom row
            end

            door.RenderZOffset = -4900
            door:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        end

        for _, trapdoor in ipairs(trapdoors) do
            local data = trapdoor:GetData()
            data.bal = maxData.bal
            data.LeftTrapdoor = not trapdoor:GetSprite().FlipX
            trapdoor:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom and currentRoom:GetType() == RevRoomType.TRAP_BOSS_MAXWELL then
        for i = 0, 7 do
            local door = REVEL.room:GetDoor(i)
            if door then
                local sprite = door:GetSprite()
                if not REVEL.room:IsClear() then
                    sprite.Scale = Vector.Zero
                else
                    sprite.Scale = Vector.One
                end
            end
        end
    end
end)

---@param npc EntityNPC
---@param data table
---@param target? Entity
---@param attackType string
---@param height? number
---@param notPlaySound? boolean
---@param positionOffset? Vector
---@param dir? Vector
local function shootBounce(npc, data, target, attackType, height, notPlaySound, positionOffset, dir)
    attackType = attackType or "DefaultShot"
    local cone = data.bal.ShootCone[attackType] or data.bal.ShootCone.DefaultShot
    local amnt = data.bal.ProjectileCount[attackType] or data.bal.ProjectileCount.DefaultShot
    if not dir and not target then
        error("shootBounce needs dir or target", 2)
    end

    ---@diagnostic disable-next-line: need-check-nil
    dir = dir or (target.Position + target.Velocity - npc.Position)
    dir = dir:Resized(data.bal.ProjectileSpeed[attackType] or data.bal.ProjectileSpeed.DefaultShot)

    if not notPlaySound then
        if data.bal.FromDoor[attackType] then
            REVEL.PlaySound(data.bal.Sounds.ShootFromDoor)
        else
            REVEL.PlaySound(data.bal.Sounds.Shoot)
        end
    end

  for i=0, amnt - 1 do
    local rot = 0
    if amnt > 1 then rot = REVEL.Lerp(-cone, cone, i / (amnt - 1)) end
    local proj = Isaac.Spawn(9, 0, 0, REVEL.room:GetClampedPosition(npc.Position + (positionOffset or Vector.Zero), 0), dir:Rotated(rot), npc):ToProjectile()
    proj.SpawnerEntity = npc
    if height ~= -1 then
        proj.Height = height or data.bal.ShootHeightHop
    end

    proj.FallingSpeed = 0
    proj:GetData().maxwBounce = data.bal.FloorBounceCount[attackType] or data.bal.FloorBounceCount.DefaultShot
    if data.bal.WallBounce[attackType] ~= nil then
        if not data.bal.WallBounce[attackType] then
            proj:GetData().wallBounced = true
        end
    else
        proj:GetData().wallBounced = not data.bal.WallBounce.DefaultShot
    end

    if data.bal.InfiniteWallBounce[attackType] ~= nil then
        proj:GetData().infiniteWallBounce = data.bal.InfiniteWallBounce[attackType]
    else
        proj:GetData().infiniteWallBounce = data.bal.InfiniteWallBounce.DefaultShot
    end
    --    proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.8, 0, false, 1)
  end
end

REVEL.MaxwellPartSystem = REVEL.PartSystem.FromTable{
    Name = "Maxwell System",
    Gravity = 0.7,
    AirFriction = 0.95,
    Clamped = true,
}

REVEL.MaxwellPartType = REVEL.ParticleType.FromTable{
    Name = "Maxwell Splash",
    Anm2 =  "gfx/effects/revelcommon/white_particle.anm2",
    BaseLife = 90,
    Variants = 5,
    DieOnLand = true,
    StartScale = 1.3,
    EndScale = 1.3,
    ScaleRandom = 0.34,
}
REVEL.MaxwellPartType:SetColor(Color(1, 0, 0, 1, conv255ToFloat( 15, 0, 0)), 0.05)

REVEL.MaxEmitter = REVEL.Emitter()

---@param npc EntityNPC
---@param data table
---@param target? Entity
---@param bubbleBlasted? boolean
local function PopBubble(npc, data, target, bubbleBlasted)
    local oldPos = npc.Position
    npc.Position = data.Bubble.Position
    for i=1, 7 do
        Isaac.Spawn(1000, EffectVariant.BLOOD_PARTICLE, 0, data.Bubble.Position + RandomVector() * 7, RandomVector() * 5, npc)
    end
    local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 5, data.Bubble.Position + Vector(0, -40), Vector.Zero, npc)
    eff.SpriteScale = Vector.One * 0.75

    if bubbleBlasted then
        for i = -1, 1, 2 do
            shootBounce(npc, data, target, "BubbleBlast", nil, true, nil, Vector(i, 0))
        end
    else
        npc:FireBossProjectiles(data.bal.BubblePopSplashProjectiles, Vector.Zero, data.bal.BubblePopSplashTrajectoryModifier, ProjectileParams())
        local numProjectiles = #data.bal.BubblePopProjectileBounces
        local angleDiff = 360 / numProjectiles
        local offset = math.random(0, angleDiff)
        local bounceCounts = REVEL.Shuffle(data.bal.BubblePopProjectileBounces)

        for i = 1, numProjectiles do
            REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.6, 0, false, 1)
            local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, Vector.FromAngle(i * angleDiff + offset) * data.bal.BubblePopProjectileSpeed, npc):ToProjectile()
            proj.Height = data.bal.ShootHeightHop
            proj.FallingSpeed = 0
            proj:GetData().maxwBounce = bounceCounts[i]
            proj:GetData().infiniteWallBounce = true
        end
    end

    REVEL.PlaySound(data.bal.Sounds.PopBubble)

    npc.Position = oldPos
    data.Bubble:Remove()
end

---@param npc EntityNPC
---@param spr Sprite
---@param data table
---@param pos Vector
---@param amnt integer
---@param height? number
---@param notClampAngle? boolean
local function shootCurveFan(npc, spr, data, pos, amnt, height, notClampAngle)
    local dir
    local angle = (pos-npc.Position):GetAngleDegrees()
    if notClampAngle then
        dir = (pos-npc.Position):Normalized()
    else
        angle = REVEL.Clamp(angle, 90-30, 90+30)
        dir = Vector.FromAngle(angle)
    end
    local flag
    if angle > 90 then
        flag = ProjectileFlags.CURVE_RIGHT
    else
        flag = ProjectileFlags.CURVE_LEFT
    end

    local shootCone = data.bal.ShootCone.DoubleHop * 2.5

    for i=0, amnt-1 do
        local rotAngle
        if angle > 90 then
            rotAngle = -shootCone / 2 + i * shootCone / (amnt - 1) - 20
        else
            rotAngle = -shootCone / 2 + i * shootCone / (amnt - 1) + 20
        end
        local proj = Isaac.Spawn(9, 0, 0, npc.Position, dir:Rotated(rotAngle)*10, npc):ToProjectile()
        proj.FallingSpeed = 0
        proj.FallingAccel = 0
        proj.Scale = proj.Scale * 1.3
        if height then proj.Height = height end
        proj.CurvingStrength = 0.003
        proj:GetData().maxwBounce = data.bal.FloorBounceCount.CurveFan or data.bal.FloorBounceCount.DoubleHop
        proj:GetData().infiniteWallBounce = data.bal.InfiniteWallBounce.CurveFan or data.bal.InfiniteWallBounce.DoubleHop
        proj:GetData().wallBounced = true
        proj:GetData().noCollTimeout = 5
        proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X

        proj:AddProjectileFlags(flag)
    end
    REVEL.PlaySound(data.bal.Sounds.ShootFromDoor)
end

---@param npc EntityNPC
---@param spr Sprite
---@param data table
---@param target Entity
---@param jumprope? boolean
---@param height? number
---@param notClampAngle? boolean
local function shootBigBall(npc, spr, data, target, jumprope, height, notClampAngle)
    local dir
    local angle = (target.Position-npc.Position):GetAngleDegrees()
    if notClampAngle then
        dir = (target.Position-npc.Position):Normalized()
    else
        angle = REVEL.Clamp(angle, 90-15, 90+15)
        dir = Vector.FromAngle(angle)
    end
    local flag
    if angle < 90 then
        flag = ProjectileFlags.CURVE_RIGHT
    else
        flag = ProjectileFlags.CURVE_LEFT
    end

    local proj = Isaac.Spawn(9, 0, 0, npc.Position, dir*6.5, npc):ToProjectile()
    proj.FallingSpeed = -6
    proj.FallingAccel = 0
    proj.Scale = proj.Scale * 4
    proj.CurvingStrength = 0.0005
    if height then proj.Height = height end
    proj:GetData().noCollTimeout = 5
    proj:GetData().maxBigBall = 3 --mult for bounce
    proj:GetData().maxwBounce = 1
    proj:GetData().fallingAccel = 0.45
    proj:GetData().wallBounced = true
    proj:GetData().maxBigBallJumpRope = jumprope
    proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
    proj.CollisionDamage = 2
    -- proj:GetSprite():ReplaceSpritesheet(0, "gfx/intensebullets.png")
    -- proj:GetSprite():LoadGraphics()
    REVEL.PlaySound(data.bal.Sounds.ShootBig)

    if not jumprope then
        proj:AddProjectileFlags(flag)
    end
end

local function springBomb(bomb, height, fallingSpeed, gravity)
    REVEL.SetEntityAirMovement(bomb, {
        ZPosition = -height,
        Gravity = gravity
    })
    REVEL.AddEntityZVelocity(bomb, -fallingSpeed)
end

---@param npc EntityNPC
---@param spr Sprite
---@param data table
---@param atTrapdoor? boolean
---@param offsetDist? number
---@param spd? number
---@param y? number
local function throwBomb(npc, spr, data, atTrapdoor, offsetDist, spd, y)
    spd = spd or 14
    offsetDist = offsetDist or 8
    y= y or -5
    local targ
    if atTrapdoor then
        if data.MaxTrapdoor then
            targ = data.MaxTrapdoor:GetData().Opposite.Position
        else
            local trapdoors = REVEL.ENT.MAXWELL_TRAP:getInRoom()
            targ = trapdoors[math.random(1, #trapdoors)].Position
        end
    else
        targ = npc:GetPlayerTarget().Position
    end

    local dir = (targ - npc.Position):Normalized()

    local b = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, npc.Position+dir*offsetDist, dir*spd, npc):ToBomb()
    b.SpawnerEntity = npc
    b.SpawnerType = npc.Type
    b:GetData().maxw = true
    b:GetSprite():Play("Pulse", true)
    b:SetExplosionCountdown(38)
    springBomb(b, y, -3, 0.5)
    b.Visible = false --fixes weird bug with the bombs appearing on the ground for a single frame
    REVEL.DelayFunction(function()
        b.Visible = true
    end, 1)
    b.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    return b
end

-- NEW MAXWELL CODE START --

---@param doors EntityNPC[]
---@return EntityNPC
local function PickJumpDoor(doors)
    local validDoors = {}
    local alreadyTooClose
    for _, door in ipairs(doors) do
        if not door:GetData().TopDoor then
            local tooClose
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(door.Position) <= 100 ^ 2 then
                    tooClose = true
                    break
                end
            end

            if not tooClose or alreadyTooClose then
                validDoors[#validDoors + 1] = door
            else
                alreadyTooClose = true
            end
        end
    end

    return validDoors[math.random(1, #validDoors)]
end

---@param startDoor EntityNPC
---@param trapdoors Entity[]
---@return Entity first
---@return Entity second
local function GetTrapdoorOrder(startDoor, trapdoors)
    local isLeftDoor = startDoor:GetData().LeftDoor

    local first, second
    for _, trapdoor in ipairs(trapdoors) do
        local isLeftTrapdoor = trapdoor:GetData().LeftTrapdoor
        if isLeftTrapdoor == isLeftDoor then
            first = trapdoor
        else
            second = trapdoor
        end
    end

    return first, second
end

---@param door EntityNPC
---@param target Entity | Vector
---@param offset? Vector
---@param offset2? Vector
---@return EntityPtr[] tracers
local function CreateLaserTell(door, target, offset, offset2)
    local targetPos
    if target.X then
        targetPos = target
    else
        targetPos = target.Position
    end

    local tracers = {}
    local tracer = REVEL.MakeLaserTracer(
        door.Position + (offset or Vector.Zero), 
        90,
        targetPos + (offset2 or Vector.Zero),
        Color(0.9, 0, 0, 1), 
        nil, 
        2
    )
    tracers[#tracers + 1] = EntityPtr(tracer)

    if math.abs(targetPos.X - door.Position.X) > 200 then
        tracers[#tracers + 1] = EntityPtr(REVEL.SpawnLaserTracerExtension(tracer, 200))
    end

    return tracers
end

local function RemoveLaserTracers(data)
    if data.BrimstoneTellTracers then
        for _, ptr in ipairs(data.BrimstoneTellTracers) do
            if ptr.Ref then 
                ptr.Ref:Remove() 
            end
        end
        data.BrimstoneTellTracers = nil
    end
end
    
---@param npc EntityNPC
local function maxwell_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.MAXWELL.variant then return end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    if not data.Init then
        data.IsChampion = REVEL.IsChampion(npc)

        data.FlameTrapPassThrough = true

        if data.IsChampion then
            data.bal = REVEL.GetBossBalance(MaxwellBalance, "Craxwell")
        else
            if REVEL.IsRuthless() then
                data.bal = REVEL.GetBossBalance(MaxwellBalance, "Ruthless")
            else
                data.bal = REVEL.GetBossBalance(MaxwellBalance, "Default")
            end
        end

        if data.bal.DebugCycle then
            data.bal.Cycle = data.bal.DebugCycle
        end

        data.State = "WaitForPlayer"

        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite:Play("Invisible", true)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

        prepareRoom(npc, data)

        local topDoor, leftDoor
        for _, door in ipairs(REVEL.ENT.MAXWELL_DOOR:getInRoom()) do
            if data.bal.DoorSpritesheet and (not data.bal.SkipTopDoorSheet or not door:GetData().TopDoor) then
                for i = 0, 1 do
                    door:GetSprite():ReplaceSpritesheet(i, data.bal.DoorSpritesheet)
                end
                door:GetSprite():LoadGraphics()
            end

            door:GetSprite():Play("Door Closed", true)
            if door:GetData().TopDoor then
                topDoor = door
            elseif door:GetData().LeftDoor then
                leftDoor = door
            end
        end

        data.TopDoor = topDoor
        data.LeftDoor = leftDoor

        local leftTrap
        for _, trapdoor in ipairs(REVEL.ENT.MAXWELL_TRAP:getInRoom()) do
            if data.bal.TrapSpritesheet then
                for i = 0, 2 do
                    trapdoor:GetSprite():ReplaceSpritesheet(i, data.bal.TrapSpritesheet)
                end
                trapdoor:GetSprite():LoadGraphics()
            end

            if trapdoor:GetData().LeftTrapdoor then
                if data.bal.IsCraxwell then
                    trapdoor:GetData().BrokenSpring = true
                end

                leftTrap = trapdoor
            end
        end

        data.LeftTrap = leftTrap

        if data.bal.Spritesheet then
            for i = 0, 1 do
                sprite:ReplaceSpritesheet(i, data.bal.Spritesheet)
            end

            sprite:LoadGraphics()
        end

        if data.bal.HealthMulti then
            npc.MaxHitPoints = npc.MaxHitPoints * data.bal.HealthMulti
            npc.HitPoints = npc.MaxHitPoints
        end

        REVEL.SetScaledBossHP(npc)
        data.Init = true
    end

    for _, enemy in ipairs(REVEL.roomEnemies) do
        enemy:GetData().NoRags = true
        if enemy.Position.X ~= enemy.Position.X and enemy.Position.Y ~= enemy.Position.Y then
            enemy:Kill()
        end
    end

    for _, flag in ipairs(data.bal.ImmuneToFlags) do
        npc:ClearEntityFlags(flag)
    end

    local doors = REVEL.ENT.MAXWELL_DOOR:getInRoom()
    local trapdoors = REVEL.ENT.MAXWELL_TRAP:getInRoom()

    if sprite:IsFinished("Exit") then
        sprite:Play("Invisible", true)
    end

    if sprite:IsFinished("Invisible") or sprite:IsPlaying("Invisible") then
        npc.Visible = false
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    else
        npc.Visible = true
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    triggeredBossMusic = true
    if data.State == "WaitForPlayer" then
        npc.Visible = false
        triggeredBossMusic = false
        local isRaisedSpring, isShakingSpring
        for _, trapdoor in ipairs(trapdoors) do
            trapdoor:GetData().IsTutorial = true
            if trapdoor:GetData().State == "Spring Raised" then
                isRaisedSpring = true
            elseif trapdoor:GetData().State == "Spring Shaking" then
                isShakingSpring = true
            end
        end

        local fightProgress = not isRaisedSpring
        if data.bal.IsCraxwell then
            fightProgress = isShakingSpring
        end

        if fightProgress then
            data.WaitTime = nil
            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().IsTutorial = nil
            end

            if data.bal.IsCraxwell then
                data.State = "ChampionIntro"
                data.IdleTime = data.bal.CraxwellIntroDelay
            else
                data.AttackCooldown = data.bal.InitialAttackCooldown
                data.State = "Idle"
            end
        else
            if not data.WaitTime then
                data.WaitTime = 0
            else
                data.WaitTime = data.WaitTime + 1
            end

            if data.WaitTime == data.bal.SpitMessageTime then
                data.LeftDoor:GetData().State = "SpitMessage"
                data.LeftDoor:GetSprite():Play("Door Hop Start", true)
            end
        end
    elseif data.State == "ChampionIntro" then
        if data.IdleTime then
            data.IdleTime = data.IdleTime - 1
            if data.IdleTime <= 0 then
                npc.Position = data.LeftTrap:GetData().Opposite.Position
                sprite:Play("Champion Intro Drop", true)
                data.IdleTime = nil
            end
        end

        if sprite:IsEventTriggered("Spawn") then
            REVEL.PlaySound(data.bal.Sounds.ChampionLand)

            local raisedSpring = data.LeftTrap:GetData().Opposite
            raisedSpring:GetSprite():Play("Trap Spring Raised Trigger", true)
            raisedSpring:GetData().State = "Spring Triggered"

            data.LeftTrap:GetSprite():Play("Trap Spring Raise", true)
            data.LeftTrap:GetData().State = "Spring Raised"
            data.LeftTrap:GetData().SpringCollidingPlayers = true
            data.LeftTrap:GetData().LowerCooldown = data.bal.CraxwellSeesawLowerCooldown
            data.CurrentTrap = raisedSpring
        end

        if sprite:IsFinished("Champion Intro Drop") then
            data.AttackCooldown = data.bal.InitialAttackCooldown
            data.State = "IdleChampion"
        end
    elseif data.State == "Idle" then
        sprite.FlipX = false
        if sprite:IsPlaying("Invisible") or sprite:IsFinished("Invisible") then
            if data.AttackCooldown then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            elseif IsBelowFinaleThreshold(npc, data) then
                REVEL.AnnounceAttack(data.bal.AttackNames.GrandFinale)
                data.AttackInit = nil
                data.State = "GrandFinale"
                REVEL.PlaySound(data.bal.Sounds.FinaleStart)
            else
                local curCycle, isAttacking, attack, cooldown, changedPhase = REVEL.ManageAttackCycle(data, data.bal, nil, doors, trapdoors)
                if isAttacking then
                    if changedPhase then
                        REVEL.PlaySound(data.bal.Sounds.ChangePhase)
                    end

                    data.AttackCooldown = cooldown
                    data.AttackInit = nil

                    if curCycle.IsHop and (not curCycle.NotHop or not curCycle.NotHop[attack]) then
                        data.State = "HopPrep"
                        data.NextState = attack
                        data.StartDoor = PickJumpDoor(doors)
                        data.StartDoor:GetSprite():Play("Door Hop Start", true)
                        npc.Position = data.StartDoor.Position
                        sprite:Play("Enter", true)
                    else
                        REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                        data.State = attack
                    end
                end
            end
        end
    elseif data.State == "IdleChampion" then
        if data.AttackCooldown then
            data.AttackCooldown = data.AttackCooldown - 1
            if data.AttackCooldown <= 0 then
                data.AttackCooldown = nil
            end
        end

        local isPlayingNonHopIdle
        for _, anim in ipairs(data.bal.CraxwellNonHopIdleAnims) do
            if sprite:IsPlaying(anim) then
                isPlayingNonHopIdle = true
            end

            if sprite:IsFinished(anim) then
                MaxwellTriggerSpringsFast(npc, data, trapdoors, data.bal.MaxwellSpringCooldown)
            end
        end

        if data.CurrentTrap:GetData().Opposite:GetData().JustHitFromRaised then
            REVEL.AnnounceAttack(data.bal.AttackNames.Seesaw)
            data.AttackInit = nil
            data.State = "Seesaw"

            REVEL.JumpToCycle(data, 5, nil, nil, "Seesaw")

            data.SeesawSpecial = 0
            sprite:Play("Champion Seesaw Fling", true)
            REVEL.PlaySound(data.bal.Sounds.Flung)
            data.CurrentTrap:GetSprite():Play("Trap Spring Trigger", true)
            data.CurrentTrap:GetData().State = "Spring Triggered"
            data.CurrentTrap:GetData().SpringCollidingPlayers = true
            data.CurrentTrap:GetData().TargetState = "Trap"
            data.CurrentTrap:GetData().NewTrap = data.bal.SeesawTraps[math.random(1, #data.bal.SeesawTraps)]
            data.CurrentTrap:GetData().Opposite:GetData().TargetState = "Trap"
            data.CurrentTrap:GetData().Opposite:GetData().NewTrap = data.bal.SeesawTraps[math.random(1, #data.bal.SeesawTraps)]
            TotalCancelHop(npc, data)
        elseif not data.Hopping and not isPlayingNonHopIdle then
            data.Dunked = nil
            data.Hopping = true
            data.Arcs = {
                {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position}
            }

            if not data.AttackCooldown then
                if IsBelowFinaleThreshold(npc, data) then
                    REVEL.PlaySound(data.bal.Sounds.FinaleStart)
                    REVEL.AnnounceAttack(data.bal.AttackNames.GrandFinale)
                    data.AttackInit = nil
                    data.State = "GrandFinale"
                else
                    local curCycle, isAttacking, attack, cooldown, changedPhase = REVEL.ManageAttackCycle(data, data.bal, nil, doors, trapdoors)
                    if isAttacking then
                        if changedPhase then
                            REVEL.PlaySound(data.bal.Sounds.ChangePhase)
                        end

                        data.AttackCooldown = cooldown
                        data.AttackInit = nil

                        REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                        if curCycle.IsFall then
                            for _, trapdoor in ipairs(trapdoors) do
                                trapdoor:GetData().TargetState = "Pit"
                            end

                            data.Arcs[#data.Arcs + 1] = "Fall"
                        end

                        data.State = attack
                    end
                end
            end
        end

        sprite.FlipX = not data.CurrentTrap:GetSprite().FlipX
    elseif data.State == "Seesaw" then
        if not data.AttackInit then
            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Move Closed", true)
                end
            end

            data.DoorsTrackPlayer = true
            data.AttackInit = true
        end

        if data.SeesawSpecial then
            data.SeesawSpecial = data.SeesawSpecial + 1
            if sprite:IsFinished("Champion Seesaw Fling") then
                sprite:Play("Invisible", true)
            end

            if data.SeesawSpecial == data.bal.SeesawSpecialBombFrame then
                data.CurrentTrap = trapdoors[math.random(1, #trapdoors)]

                local b = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, data.CurrentTrap:GetData().Opposite.Position, Vector.Zero, npc):ToBomb()
                b.SpawnerEntity = npc
                b.SpawnerType = npc.Type
                b:GetData().maxw = true
                b:GetSprite():Play("Pulse", true)
                b:SetExplosionCountdown(58)
                springBomb(b, data.bal.SeesawSpecialBombHeight, -3, 0.5)
                b.Visible = false --fixes weird bug with the bombs appearing on the ground for a single frame
                REVEL.DelayFunction(function()
                    b.Visible = true
                end, 1)
                b.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end

            if data.SeesawSpecial == data.bal.SeesawSpecialMaxwellFrame then
                data.SwappingTraps = nil
                npc.Position = data.CurrentTrap.Position
                sprite:Play("Champion Seesaw Land", true)
                data.SeesawSpecial = nil
            end
        else
            local oppositeTrap = data.CurrentTrap:GetData().Opposite
            if not data.Hopping then
                if sprite:IsPlaying("Champion Seesaw Land") then
                    if sprite:IsEventTriggered("Land") then
                        REVEL.PlaySound(data.bal.Sounds.LongFall)
                        npc:TakeDamage(npc.MaxHitPoints * data.bal.SeesawSpecialDamage, 0, EntityRef(npc), 0)
                        data.CurrentTrap:GetData().TriggerTrap = true
                    end
                else
                    if not data.NumRepeats then
                        data.NumRepeats = math.random(data.bal.SeesawRepeats.Min, data.bal.SeesawRepeats.Max)
                    end

                    data.NumRepeats = data.NumRepeats - 1
                    if data.NumRepeats <= 0 or IsBelowFinaleThreshold(npc, data) then
                        data.NumRepeats = nil
                        data.State = "IdleChampion"
                        if data.SwappingTraps then
                            data.CurrentTrap = oppositeTrap
                        end

                        data.Bombs = nil
                        data.SwappingTraps = nil

                        data.DoorsTrackPlayer = nil
                        for _, door in ipairs(doors) do
                            if not door:GetData().TopDoor then
                                door:GetData().TargetState = "IdleNoMove"
                            end
                        end

                        for _, trapdoor in ipairs(trapdoors) do
                            trapdoor:GetData().TargetState = "Spring"
                        end
                    else
                        data.Dunked = nil
                        data.Hopping = true
                        if data.SwappingTraps then
                            oppositeTrap = data.CurrentTrap
                            data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                            data.CurrentTrap:GetSprite():Play("Trap Door Shake", true)
                            data.CurrentTrap:GetData().State = "Spring Shaking"

                            oppositeTrap:GetSprite():Play("Trap Spring Raise", true)
                            oppositeTrap:GetData().State = "Spring Raised"
                            oppositeTrap:GetData().SpringCollidingPlayers = true
                            oppositeTrap:GetData().LowerCooldown = data.bal.CraxwellSeesawLowerCooldown
                            oppositeTrap:GetData().TargetState = "Trap"
                            oppositeTrap:GetData().NewTrap = data.bal.SeesawTraps[math.random(1, #data.bal.SeesawTraps)]
                        else
                            data.CurrentTrap:GetData().TargetState = "Spring"
                            oppositeTrap:GetData().TargetState = "Trap"
                            oppositeTrap:GetData().NewTrap = data.bal.SeesawTraps[math.random(1, #data.bal.SeesawTraps)]
                        end

                        data.Arcs = {
                            {HopType = "Bomb", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position},
                            {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position},
                            {HopType = "Middle", StartPos = data.CurrentTrap.Position, EndPos = oppositeTrap.Position}
                        }

                        if data.SwappingTraps then
                            table.insert(data.Arcs, 1, {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position})
                        end

                        data.Bombs = 1
                    end
                end
            elseif oppositeTrap:GetData().JustHitFromRaised then
                data.SeesawSpecial = 0
                sprite:Play("Champion Seesaw Fling", true)
                REVEL.PlaySound(data.bal.Sounds.Flung)
                data.CurrentTrap:GetSprite():Play("Trap Spring Trigger", true)
                data.CurrentTrap:GetData().State = "Spring Triggered"
                data.CurrentTrap:GetData().SpringCollidingPlayers = true
                data.CurrentTrap:GetData().TargetState = "Trap"
                data.CurrentTrap:GetData().NewTrap = data.bal.SeesawTraps[math.random(1, #data.bal.SeesawTraps)]
                TotalCancelHop(npc, data)
            elseif sprite:IsFinished("Champion Hop Bomb") then
                oppositeTrap:GetData().TargetState = "Spring"
                data.SwappingTraps = true
            end

            if sprite:IsEventTriggered("Shoot") then
                data.MaxTrapdoor = data.CurrentTrap
                throwBomb(npc, sprite, data, data.Bombs == 1, nil, nil, npc.SpriteOffset.Y + data.bal.CraxwellBombHopHeight[data.Bombs])
                REVEL.PlaySound(data.bal.Sounds.ThrowBomb)
                data.MaxTrapdoor = nil
                data.Bombs = data.Bombs + 1
            end
        end

        sprite.FlipX = not data.CurrentTrap:GetSprite().FlipX
    elseif data.State == "TrapSmash" then
        if not data.AttackInit then
            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Move Closed", true)
                end
            end

            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Trap"
                trapdoor:GetData().NewTrap = data.bal.TrapSmashTraps[math.random(1, #data.bal.TrapSmashTraps)]
            end

            data.DoorsTrackPlayer = true
            data.AttackDuration = math.random(data.bal.TrapSmashDuration.Min, data.bal.TrapSmashDuration.Max)
            data.AttackInit = true
        end

        data.AttackDuration = data.AttackDuration - 1

        if not data.Hopping then
            if data.AttackDuration <= 0 or IsBelowFinaleThreshold(npc, data) then
                if data.SwappingTraps then
                    data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                end

                for _, door in ipairs(doors) do
                    if not door:GetData().TopDoor then
                        door:GetData().TargetState = "IdleNoMove"
                    end
                end

                for _, trapdoor in ipairs(trapdoors) do
                    trapdoor:GetData().TargetState = "Spring"
                end

                data.AttackDuration = nil
                data.DoorsTrackPlayer = nil
                data.SwappingTraps = nil
                data.State = "IdleChampion"
            else
                data.Dunked = nil
                data.Hopping = true
                if data.SwappingTraps then
                    data.CurrentTrap:GetData().TargetState = "Trap"
                    data.CurrentTrap:GetData().NewTrap = data.bal.TrapSmashTraps[math.random(1, #data.bal.TrapSmashTraps)]
                    data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                end

                data.SwappingTraps = true
                data.Arcs = {
                    {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position}
                }
            end
        end

        if data.NewArc then
            data.CurrentTrap:GetData().TriggerTrap = true
        end

        sprite.FlipX = not data.CurrentTrap:GetSprite().FlipX
    elseif data.State == "BrimstoneBarrier" then
        local doorSprite, doorData = data.TopDoor:GetSprite(), data.TopDoor:GetData()
        if not data.AttackInit then
            doorSprite:Play("Door Brimstone Start", true)

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Move Closed", true)
                end
            end

            data.DoorsTrackPlayer = true
            data.AttackDuration = math.random(data.bal.BrimstoneBarrierDuration.Min, data.bal.BrimstoneBarrierDuration.Max)
            data.AttackInit = true

            local roomHeight = REVEL.room:GetBottomRightPos().Y - REVEL.room:GetTopLeftPos().Y

            data.BrimstoneTellTracers = CreateLaserTell(data.TopDoor, data.TopDoor.Position + Vector(0, roomHeight), Vector(0, -20))
        end

        if doorSprite:IsEventTriggered("Brimstone Tell") then
            REVEL.PlaySound(data.bal.Sounds.BrimstoneTell)
        end

        if doorSprite:IsEventTriggered("Brimstone Start") then
            data.Laser = EntityLaser.ShootAngle(1, data.TopDoor.Position, doorSprite.Rotation + 90, 4, Vector.FromAngle(doorSprite.Rotation - 90) * data.bal.JumpRopeBrimstoneOffset, data.TopDoor)
            --REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_START, 0.6, 0, false, 1)
            REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_LOOP, 0.35, 0, true, 1)
            RemoveLaserTracers(data)
        end

        if data.Laser then
            data.Laser:SetTimeout(4)
        end

        local ongoingAttack
        for _, door in ipairs(doors) do
            if door:GetData().SpecialTrap then
                ongoingAttack = true
            end
        end

        data.AttackDuration = data.AttackDuration - 1
        if IsBelowFinaleThreshold(npc, data) then
            data.AttackDuration = 0
        end

        if data.AttackDuration <= 0 and data.Laser and not ongoingAttack then
            REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
            REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_STOP_SHORT, 0.6, 0, false, 1)
            data.Laser = nil
            doorSprite:Play("Door Brimstone End Queasy", true)
            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Spring"
            end
        end

        if doorSprite:IsEventTriggered("Door Shoot") then
            REVEL.PlaySound(data.bal.Sounds.ShootBubble)
            data.Bubble = REVEL.ENT.MAXWELL_BUBBLE:spawn(data.TopDoor.Position + Vector.FromAngle(doorSprite.Rotation + 90) * 20, Vector.Zero, nil)
        end

        if not data.Hopping then
            local playersOnLeft = 0
            local center = REVEL.room:GetCenterPos()
            for _, player in ipairs(REVEL.players) do
                if player.Position.X < center.X then
                    playersOnLeft = playersOnLeft + 1
                end
            end

            if data.SwappingTraps then
                data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                data.SwappingTraps = nil
            end

            data.Dunked = nil
            data.Hopping = true
            data.DoorsTrackPlayer = true

            if not data.Laser then
                data.Arcs = {
                    {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position}
                }
                data.DoorsTrackPlayer = nil
                if doorSprite:WasEventTriggered("Door Shoot") then
                    for _, door in ipairs(doors) do
                        if not door:GetData().TopDoor then
                            door:GetData().TargetState = "IdleNoMove"
                        end
                    end

                    data.AttackDuration = nil
                    data.State = "IdleChampion"
                end
            elseif (playersOnLeft > (#REVEL.players - playersOnLeft) and data.CurrentTrap:GetData().LeftTrapdoor) or (playersOnLeft < (#REVEL.players - playersOnLeft) and not data.CurrentTrap:GetData().LeftTrapdoor) then -- switch sides if the player is on the same side
                data.Arcs = {
                    {HopType = "Shoot", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position}
                }
                data.CurrentTrap:GetData().TargetState = "Spring"
                data.SwappingTraps = true
            else
                if ongoingAttack then
                    data.Arcs = {
                        {HopType = "Shoot", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position}
                    }
                else
                    local attacks = {}
                    for attack, weight in pairs(data.bal.BrimstoneBarrierAttacks) do
                        if attack == data.LastBrimstoneBarrierAttack then
                            attacks[attack] = weight
                        else
                            attacks[attack] = weight * data.bal.BarrierAttackNonRepeatMulti
                        end
                    end

                    local attack = REVEL.WeightedRandom(attacks)
                    data.LastBrimstoneBarrierAttack = attack
                    data.CurrentTrap:GetData().TargetState = "Trap"
                    data.CurrentTrap:GetData().NewTrap = attack
                    data.CurrentTrap:GetData().SpecialTrap = 0
                    if attack == "Arrow" then
                        data.DoorsTrackPlayer = nil
                    end

                    data.Arcs = {
                        {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position},
                        {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position}
                    }
                end
            end
        end

        if data.NewArc then
            data.CurrentTrap:GetData().TriggerTrap = true
        end

        if sprite:IsEventTriggered("Shoot") then
            if data.SwappingTraps then
                shootBounce(npc, data, target, "DoubleHop")
            else
                shootBounce(npc, data, target, "BrimstoneBarrier")
            end
        end

        sprite.FlipX = not data.CurrentTrap:GetSprite().FlipX
    elseif data.State == "HopPrep" then
        if sprite:IsFinished("Enter") then
            if data.NextState == "ThinkingWithPortals" or data.NextState == "Elevator" then
                for _, trapdoor in ipairs(trapdoors) do
                    trapdoor:GetData().TargetState = "Pit"
                end
            end

            data.IdleTime = data.bal.IdleBeforeHop
            sprite:Play("Idle", true)
        end

        if data.PlayerFellInto then
            data.SkipHop = data.PlayerFellInto
        end

        if sprite:IsPlaying("Idle") then
            data.IdleTime = data.IdleTime - 1
            if data.IdleTime <= 0 then
                sprite.FlipX = data.StartDoor:GetData().LeftDoor
                if data.SkipHop then
                    data.Hopping = true

                    local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)
                    data.Arcs = {
                        {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                        "Fall"
                    }
                else
                    REVEL.AnnounceAttack(data.bal.AttackNames[data.NextState])
                    data.State = data.NextState
                    data.IdleTime = nil
                    data.NextState = nil
                    data.AttackInit = nil
                end
            end
        end

        if data.SkipHop and sprite:IsFinished("Hop Start Fall") then
            data.StartDoor:GetSprite():Play("Door Hop End", true)
            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Spring"
            end

            data.State = "Idle"
            data.SkipHop = nil
            sprite:Play("Invisible", true)
        end
    elseif data.State == "DoubleHop" then
        if not data.AttackInit then
            if data.bal.IsCraxwell then
                data.Arcs[#data.Arcs + 1] = {HopType = "Shoot", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position}
                data.Arcs[#data.Arcs + 1] = {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap:GetData().Opposite.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position}
            else
                data.Hopping = true

                local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)
                data.Arcs = {
                    {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                    {HopType = "Shoot", StartPos = first.Position, EndPos = second.Position},
                    {HopType = "End", StartPos = second.Position, EndPos = data.StartDoor:GetData().Opposite.Position}
                }
            end

            data.AttackInit = true
        end

        if data.Hopping and sprite:IsEventTriggered("Shoot") then
            shootBounce(npc, data, target, "DoubleHop")
        end

        if data.Arcs and #data.Arcs == 1 then -- last arc
            if data.bal.IsCraxwell then
                data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                data.State = "IdleChampion"
            else
                local endDoor = data.StartDoor:GetData().Opposite
                if not endDoor:GetSprite():IsPlaying("Door Hop Start") and not endDoor:GetSprite():IsFinished("Door Hop Start") then
                    endDoor:GetSprite():Play("Door Hop Start", true)
                end
            end
        end

        if not sprite:IsPlaying("Enter") and not data.Hopping then
            npc.Position = data.StartDoor:GetData().Opposite.Position
            sprite:Play("Exit", true)
            data.State = "Idle"

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Hop End", true)
                end
            end
        end
    elseif data.State == "BubblePop" then
        if not data.AttackInit then
            local bubblePos = REVEL.room:GetCenterPos()

            if data.bal.IsCraxwell then
                data.Arcs[#data.Arcs + 1] = {HopType = "BubblePopBefore", StartPos = data.CurrentTrap.Position, EndPos = bubblePos}
                data.Arcs[#data.Arcs + 1] = {HopType = "BubblePopAfter", StartPos = bubblePos, EndPos = data.CurrentTrap:GetData().Opposite.Position}
            else
                data.Hopping = true

                local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)
                data.Arcs = {
                    {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                    {HopType = "BubblePopBefore", StartPos = first.Position, EndPos = bubblePos},
                    {HopType = "BubblePopAfter", StartPos = bubblePos, EndPos = second.Position},
                    {HopType = "End", StartPos = second.Position, EndPos = data.StartDoor:GetData().Opposite.Position}
                }
            end

            data.AttackInit = true
        end

        if data.Arcs and #data.Arcs == 1 then -- last arc
            if not data.bal.IsCraxwell then
                local endDoor = data.StartDoor:GetData().Opposite
                if not endDoor:GetSprite():IsPlaying("Door Hop Start") and not endDoor:GetSprite():IsFinished("Door Hop Start") then
                    endDoor:GetSprite():Play("Door Hop Start", true)
                end
            end
        end

        if sprite:IsEventTriggered("Pop") then
            PopBubble(npc, data)
        end

        if data.bal.IsCraxwell and sprite:IsFinished("Hop Bubble Pop 2") then
            data.CurrentTrap = data.CurrentTrap:GetData().Opposite
            data.State = "IdleChampion"
        elseif not sprite:IsPlaying("Enter") and not data.Hopping then
            npc.Position = data.StartDoor:GetData().Opposite.Position
            sprite:Play("Exit", true)
            data.State = "Idle"

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Hop End", true)
                end
            end
        end
    elseif data.State == "BubbleBlast" then
        local doorSprite, doorData = data.TopDoor:GetSprite(), data.TopDoor:GetData()
        if not data.AttackInit then
            doorSprite:Play("Door Brimstone Start", true)
            data.AttackInit = true

            local roomHeight = REVEL.room:GetBottomRightPos().Y - REVEL.room:GetTopLeftPos().Y

            data.BrimstoneTellTracers = CreateLaserTell(data.TopDoor, data.TopDoor.Position + Vector(0, roomHeight), Vector(0, -20))
        end

        if doorSprite:IsEventTriggered("Brimstone Tell") then
            REVEL.PlaySound(data.bal.Sounds.BrimstoneTell)
        end

        if doorSprite:IsEventTriggered("Brimstone Start") then
            EntityLaser.ShootAngle(1, data.TopDoor.Position, doorSprite.Rotation + 90, 4, Vector.FromAngle(doorSprite.Rotation - 90) * data.bal.JumpRopeBrimstoneOffset, data.TopDoor)
            PopBubble(npc, data, target, true)
            
            RemoveLaserTracers(data)
        end

        if doorSprite:IsFinished("Door Brimstone Start") then
            doorSprite:Play("Door Brimstone End", true)
        end

        if doorSprite:IsFinished("Door Brimstone End") then
            data.State = "Idle"
        end
    elseif data.State == "ThinkingWithPortals" then
        if not data.AttackInit then
            if not data.bal.IsCraxwell then
                data.Hopping = true

                local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)
                data.Arcs = {
                    {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                    "Fall"
                }

                data.EmergeTrapdoor = second
            else
                data.EmergeTrapdoor = data.CurrentTrap:GetData().Opposite
            end

            data.PortalHops = math.random(data.bal.PortalHops.Min, data.bal.PortalHops.Max)

            data.EmergeTrapdoor:GetData().Opposite:GetData().BluePortal = true
            data.EmergeTrapdoor:GetData().BluePortal = nil

            data.AttackInit = true
        end

        local startPortaling
        if sprite:IsFinished("Hop Start Fall") or sprite:IsFinished("Hop Middle Fall") or sprite:IsFinished("Champion Hop Alt 2 Fall") then
            if data.StartDoor then
                data.StartDoor:GetSprite():Play("Door Hop End", true)
            end

            for _, trapdoor in ipairs(trapdoors) do
                if trapdoor:GetData().BluePortal then
                    trapdoor:GetSprite():Play("Trap Door Portal2", true)
                else
                    trapdoor:GetSprite():Play("Trap Door Portal", true)
                end
            end

            startPortaling = true
        end

        if sprite:IsEventTriggered("Shoot") then
            shootBounce(npc, data, target, "PortalHop")
        end

        if data.PlayerFellInto then
            data.PortalHops = 0
        end

        if sprite:IsFinished("Hop Portal 1") or sprite:IsFinished("Hop Portal 2") or startPortaling then
            data.PortalHops = data.PortalHops - 1
            if data.PortalHops < 0 or IsBelowFinaleThreshold(npc, data) then
                for _, trapdoor in ipairs(trapdoors) do
                    local anim
                    if trapdoor:GetData().BluePortal then
                        anim = "Trap Door Portal2 Off"
                    else
                        anim = "Trap Door Portal Off"
                    end

                    trapdoor:GetSprite():Play(anim, true)
                    trapdoor:GetData().TargetState = "Spring"
                    trapdoor:GetData().WaitForAnim = anim
                end

                data.PortalHops = nil

                if data.bal.IsCraxwell then
                    sprite:Play("Champion Hop From Pit", true)
                    data.State = "IdleChampion"
                    npc.Position = data.EmergeTrapdoor.Position
                    data.CurrentTrap = data.EmergeTrapdoor
                else
                    sprite:Play("Invisible", true)
                    data.State = "Idle"
                end
            else
                if startPortaling or sprite:IsFinished("Hop Portal 1") then
                    REVEL.PlaySound(data.bal.Sounds.Portal1)
                    sprite:Play("Hop Portal 2", true)
                else
                    REVEL.PlaySound(data.bal.Sounds.Portal2)
                    sprite:Play("Hop Portal 1", true)
                end

                npc.Position = data.EmergeTrapdoor.Position
                data.EmergeTrapdoor = data.EmergeTrapdoor:GetData().Opposite
            end
        end
    elseif data.State == "Elevator" then
        if not data.AttackInit then
            if not data.bal.IsCraxwell then
                data.Hopping = true

                local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)
                data.Arcs = {
                    {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                    "Fall"
                }
            end

            data.AttackInit = true
        end

        if sprite:IsFinished("Hop Start Fall") or sprite:IsFinished("Hop Middle Fall") or sprite:IsFinished("Champion Hop Alt 2 Fall") then
            if not data.bal.IsCraxwell then
                data.StartDoor:GetSprite():Play("Door Hop End", true)
            end

            if data.PlayerFellInto and not data.ElevatorStarted then
                data.NoElevator = true
            end

            if not data.NoElevator then
                local randomEnemyTrapdoors = trapdoors
                if data.bal.IsCraxwell then
                    randomEnemyTrapdoors = {data.CurrentTrap}
                    local maxwellTrapdoor = data.CurrentTrap:GetData().Opposite
                    maxwellTrapdoor:GetSprite():Play("Trap Door Rise Elevator Maxwell", true)
                    maxwellTrapdoor:GetData().State = "Pit Rising"
                    maxwellTrapdoor:GetData().Enemy = "Maxwell"
                end

                for _, trapdoor in ipairs(randomEnemyTrapdoors) do
                    local enemy = REVEL.WeightedRandom(data.bal.ElevatorEnemies)
                    trapdoor:GetData().Enemy = enemy
                    trapdoor:GetData().State = "Pit Rising"
                    trapdoor:GetSprite():Play("Trap Door Rise Elevator " .. data.bal.ElevatorEnemyToAnimName[enemy], true)
                end

                data.ElevatorStarted = true
            else
                for _, trapdoor in ipairs(trapdoors) do
                    trapdoor:GetData().TargetState = "Spring"
                end

                data.NoElevator = nil

                if data.bal.IsCraxwell then
                    sprite:Play("Champion Hop From Pit", true)
                    data.State = "IdleChampion"
                else
                    data.State = "Idle"
                end
            end

            if not sprite:IsPlaying("Champion Hop From Pit") then
                sprite:Play("Invisible", true)
            end
        end

        if sprite:IsFinished("Invisible") then
            local trapdoorSummonsDone = false
            for _, trapdoor in ipairs(trapdoors) do
                local enemy = trapdoor:GetData().Enemy
                if enemy then
                    if trapdoor:GetSprite():IsEventTriggered("Ding") then
                        REVEL.PlaySound(data.bal.Sounds.Elevator)
                    end

                    if enemy == "Maxwell" then
                        if trapdoor:GetSprite():IsFinished("Trap Door Rise Elevator Maxwell") then
                            trapdoor:GetData().Enemy = nil
                            trapdoor:GetData().State = "Spring"
                            data.State = "IdleChampion"
                            data.CurrentTrap = trapdoor
                            npc.Position = data.CurrentTrap.Position
                            sprite:Play("Champion Hop From Elevator", true)
                        end
                    elseif trapdoor:GetSprite():IsFinished("Trap Door Rise Elevator " .. data.bal.ElevatorEnemyToAnimName[enemy]) then
                        local enm = REVEL.ENT[enemy]:spawn(trapdoor.Position, Vector.Zero, npc)
                        enm:GetData().NoRags = true
                        enm:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        trapdoor:GetData().Enemy = nil
                        trapdoor:GetData().State = "Spring"
                        trapdoorSummonsDone = true
                    end
                end
            end

            if not data.bal.IsCraxwell and trapdoorSummonsDone then
                data.State = "Idle"
            end
        end
    elseif data.State == "BulletYell" then
        if not data.AttackInit then
            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Trap"
                trapdoor:GetData().NewTrap = data.bal.BulletYellTraps[math.random(1, #data.bal.BulletYellTraps)]
                trapdoor:GetData().SwitchTime = math.random(data.bal.BulletYellTrapSwitchTime.Min, data.bal.BulletYellTrapSwitchTime.Max)
            end

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Move Closed", true)
                end
            end

            data.AttackDuration = math.random(data.bal.BulletYellDuration.Min, data.bal.BulletYellDuration.Max)
            data.SideAttack = "Idle"
            data.SideAttackCooldown = math.random(data.bal.SideAttackCooldown.Min, data.bal.SideAttackCooldown.Max)
            data.EndSideAttack = nil
            data.DoorsTrackPlayer = true
            data.AttackInit = true
        end

        for _, trapdoor in ipairs(trapdoors) do
            trapdoor:GetData().SwitchTime = trapdoor:GetData().SwitchTime - 1
            if trapdoor:GetData().SwitchTime <= 0 and trapdoor:GetSprite():GetFrame() == 0 then
                trapdoor:GetData().TargetState = "Trap"
                trapdoor:GetData().NewTrap = data.bal.BulletYellTraps[math.random(1, #data.bal.BulletYellTraps)]
                trapdoor:GetData().SwitchTime = math.random(data.bal.BulletYellTrapSwitchTime.Min, data.bal.BulletYellTrapSwitchTime.Max)
            end
        end

        if data.SideAttack == "Idle" then
            data.SideAttackCooldown = data.SideAttackCooldown - 1
            if data.SideAttackCooldown <= 0 then
                data.SideAttackCooldown = math.random(data.bal.SideAttackCooldown.Min, data.bal.SideAttackCooldown.Max)
                local attacks = {}
                for attack, weight in pairs(data.bal.SideAttacks) do
                    if data.LastSideAttack == attack then
                        attacks[attack] = weight
                    else
                        attacks[attack] = weight * data.bal.SideAttackNonRepeatWeightMulti
                    end
                end

                data.SideAttack = REVEL.WeightedRandom(attacks)
                REVEL.AnnounceAttack(data.bal.AttackNames[data.SideAttack])
                data.SideAttackInit = 1
            end
        end

        data.AttackDuration = data.AttackDuration - 1
        if IsBelowFinaleThreshold(npc, data) then
            data.AttackDuration = 0
        end

        if data.AttackDuration <= 0 and (not data.SideAttack or data.SideAttack == "Idle") then
            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().SwitchTime = nil
                trapdoor:GetData().TargetState = "Spring"
            end

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetData().TargetState = "IdleNoMove"
                end
            end

            data.DoorsTrackPlayer = nil
            data.AttackDuration = nil
            data.EndSideAttack = true
            data.State = "Idle"
        end
    elseif data.State == "BombTheSpot" then
        if not data.AttackInit then
            data.NumRepeats = math.random(data.bal.BombTheSpotRepeats.Min, data.bal.BombTheSpotRepeats.Max)

            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TriggerBoth = true
            end

            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetSprite():Play("Door Move Closed", true)
                end
            end

            data.DoorsTrackPlayer = true
            data.AttackInit = true
        end

        if data.MaxTrapdoor then
            local off = data.bal.BombTheSpotOffset.Right
            if data.MaxTrapdoor:GetData().LeftTrapdoor then
                off = data.bal.BombTheSpotOffset.Left
            end

            npc.Position = data.MaxTrapdoor.Position + off
            local tsprite, tdata = data.MaxTrapdoor:GetSprite(), data.MaxTrapdoor:GetData()
            if tsprite:IsFinished("Trap Switch Bomb") then
                data.BombCooldown = data.bal.BombTheSpotIdle
                data.NumBombs = REVEL.GetFromMinMax(data.bal.BombTheSpotBombs)
                if data.NumBombs > 1 then
                    data.TrapBomb = math.random(1, data.NumBombs - 1)
                else
                    data.TrapBomb = 1
                end
                tsprite:Play("Trap Door Bomb Idle", true)
            end

            if tsprite:IsPlaying("Trap Door Bomb Idle") then
                data.BombCooldown = data.BombCooldown - 1
                if data.BombCooldown <= 0 then
                    data.BombCooldown = nil
                    tsprite:Play("Trap Door Bomb Shoot", true)
                end
            end

            if tsprite:IsEventTriggered("Bomb") then
                REVEL.PlaySound(data.bal.Sounds.ThrowBomb)
                throwBomb(npc, sprite, data, data.NumBombs == data.TrapBomb, 3, 11.5)
            end

            if tsprite:IsPlaying("Trap Door Bomb Trigger") and not tsprite:WasEventTriggered("Bounce") then
                npc:TakeDamage(npc.MaxHitPoints * data.bal.BombTheSpotDamagePerFrame, 0, EntityRef(target), 0)
            end

            if tsprite:IsFinished("Trap Door Bomb Shoot") or tsprite:IsFinished("Trap Door Bomb Trigger") then
                if data.NumBombs then -- he can be squashed before he has a chance to load this
                    data.NumBombs = data.NumBombs - 1
                end

                if not data.NumBombs or data.NumBombs <= 0 or tsprite:IsFinished("Trap Door Bomb Trigger") then
                    data.TrapBomb = nil
                    data.NumBombs = nil

                    if not tsprite:IsFinished("Trap Door Bomb Trigger") then
                        tdata.State = "Spring Triggered"
                        tsprite:Play("Trap Door Bomb Close", true)
                    end

                    data.MaxTrapdoor = nil
                    data.NumRepeats = data.NumRepeats - 1
                    data.BombCooldown = data.bal.BombTheSpotIdleAfter
                else
                    tsprite:Play("Trap Door Bomb Shoot", true)
                end
            end
        else
            local isBusy
            if data.BombCooldown then
                isBusy = true
                data.BombCooldown = data.BombCooldown - 1
                if data.BombCooldown <= 0 then
                    if data.NumRepeats <= 0 or IsBelowFinaleThreshold(npc, data) then
                        for _, trapdoor in ipairs(trapdoors) do
                            trapdoor:GetData().TargetState = "Spring"
                            trapdoor:GetData().TriggerBoth = nil
                        end

                        for _, door in ipairs(doors) do
                            if not door:GetData().TopDoor then
                                door:GetData().TargetState = "IdleNoMove"
                            end
                        end

                        data.DoorsTrackPlayer = nil
                        data.PreviousMaxTrapdoor = nil
                        data.State = "Idle"
                        isBusy = true
                    end

                    data.BombCooldown = nil
                end
            end

            for _, trapdoor in ipairs(trapdoors) do
                if (trapdoor:GetData().State ~= "Spring" and trapdoor:GetData().State ~= "Trap") or trapdoor:GetSprite():GetFrame() ~= 0 then
                    isBusy = true
                end
            end

            if not isBusy then
                local maxTrapdoor
                if data.PreviousMaxTrapdoor then
                    if math.random(1, data.bal.BombTheSpotJukeChance) == 1 then
                        maxTrapdoor = data.PreviousMaxTrapdoor
                    else
                        maxTrapdoor = data.PreviousMaxTrapdoor:GetData().Opposite
                    end

                    data.PreviousMaxTrapdoor = nil
                else
                    maxTrapdoor = trapdoors[math.random(1, #trapdoors)]
                end

                maxTrapdoor:GetData().State = "Occupied"
                maxTrapdoor:GetSprite():Play("Trap Switch Bomb", true)

                data.MaxTrapdoor = maxTrapdoor
                data.PreviousMaxTrapdoor = maxTrapdoor

                local otherTrapdoor = maxTrapdoor:GetData().Opposite
                otherTrapdoor:GetData().TargetState = "Trap"
                otherTrapdoor:GetData().NewTrap = data.bal.BombTheSpotTraps[math.random(1, #data.bal.BombTheSpotTraps)]
            end
        end
    elseif data.State == "JumpRope" then
        if not data.AttackInit then
            local firstDoorBrimstone = math.random(1, 2) == 1
            for _, door in ipairs(doors) do
                if not door:GetData().TopDoor then
                    door:GetData().BrimstoneDoor = firstDoorBrimstone

                    if firstDoorBrimstone then
                        data.BrimstoneDoor = door
                        door:GetSprite():Play("Door Brimstone Start", true)
                    end

                    firstDoorBrimstone = not firstDoorBrimstone
                end
            end

            local otherDoor = REVEL.find(doors, function(door)
                return not door:GetData().BrimstoneDoor
                    and not door:GetData().TopDoor
            end)
            data.BrimstoneTellTracers = CreateLaserTell(data.BrimstoneDoor, otherDoor, Vector(0, -20), Vector(0, -20))

            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Spring"
            end

            data.RequiredJumps = math.random(data.bal.JumpRopeNumPasses.Min, data.bal.JumpRopeNumPasses.Max)
            data.AttackInit = true
        end

        if IsBelowFinaleThreshold(npc, data) and data.RequiredJumps then
            data.RequiredJumps = 0
        end

        local topLeft = REVEL.room:GetTopLeftPos()
        local bottomRight = REVEL.room:GetBottomRightPos()
        local center = REVEL.room:GetCenterPos()
        local doorY = center.Y
        if data.Laser then
            data.Laser:SetTimeout(4)

            data.Laser:SetMaxDistance(0)

            if data.CycleTime then
                data.CycleTime = data.CycleTime + 1

                local cycleLength = REVEL.Lerp(data.bal.JumpRopeCycleTime.Max, data.bal.JumpRopeCycleTime.Min, math.min(data.NumPasses, data.bal.JumpRopeJumpSpeedCap) / data.bal.JumpRopeJumpSpeedCap)
                doorY, cycleLength = CalculateJumpRopeProgress(data.StartY, data.TargetY, data.CycleTime, cycleLength, data.bal.JumpRopeAccel, data.bal.JumpRopeDecel, data.HalfPass)

                if data.CycleTime >= cycleLength then
                    data.NumPasses = data.NumPasses + 1
                    data.HalfPass = nil
                    if not data.RequiredJumps then
                        data.NumPasses = nil
                        data.StartY = nil
                        data.TargetY = nil
                        data.CycleTime = nil
                        data.EndSideAttack = true

                        data.Laser:SetTimeout(1)

                        REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
                        REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_STOP_SHORT, 0.6, 0, false, 1)

                        for _, door in ipairs(doors) do
                            local doorSprite, doorData = door:GetSprite(), door:GetData()
                            if not doorData.TopDoor then
                                if doorData.BrimstoneDoor then
                                    doorSprite:Play("Door Brimstone End", true)
                                else
                                    doorSprite:Play("Door Brimstone2 End", true)
                                end
                            end
                        end
                    else
                        data.CycleTime = 0
                        if doorY > center.Y then
                            data.StartY = bottomRight.Y - data.bal.DoorEdgeThreshold
                            data.TargetY = topLeft.Y + data.bal.DoorEdgeThreshold
                        else
                            data.StartY = topLeft.Y + data.bal.DoorEdgeThreshold
                            data.TargetY = bottomRight.Y - data.bal.DoorEdgeThreshold
                        end

                        if data.NumPasses >= data.RequiredJumps then
                            data.HalfPass = true
                            data.TargetY = center.Y
                            data.RequiredJumps = nil
                        end
                    end
                end
            end

            if data.Laser then
                TrapdoorsBlockLaser(data.Laser, trapdoors, data, doorY, data.BrimstoneDoor.Position)
            end

            if data.Laser and not data.CycleTime then
                data.Laser = nil
            end
        end

        data.CustomDoorMovement = true

        local doorPositions = {} --1: shooting door

        for _, door in ipairs(doors) do
            if not door:GetData().TopDoor then
                local doorSprite, doorData = door:GetSprite(), door:GetData()

                door.Velocity = Vector(door.Position.X, doorY) - door.Position

                if doorData.BrimstoneDoor then
                    table.insert(doorPositions, 1, door.Position)

                    if doorSprite:IsEventTriggered("Brimstone Tell") then
                        REVEL.PlaySound(data.bal.Sounds.BrimstoneTell)
                    end

                    if doorSprite:IsEventTriggered("Brimstone Start") then
                        data.SideAttack = "Shoot"
                        data.EndSideAttack = nil
                        data.IdleTime = data.bal.JumpRopeStartBulletCooldown

                        data.Laser = EntityLaser.ShootAngle(1, door.Position, doorSprite.Rotation + 90, 4, Vector.FromAngle(doorSprite.Rotation - 90) * data.bal.JumpRopeBrimstoneOffset, door)
                        REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_LOOP, 0.35, 0, true, 1)

                        data.NumPasses = 0

                        local numTop = 0
                        for _, player in ipairs(REVEL.players) do
                            if player.Position.Y < center.Y then
                                numTop = numTop + 1
                            end
                        end

                        if numTop > #REVEL.players - numTop then -- move down if players are on the top half of the room
                            data.StartY = center.Y
                            data.TargetY = bottomRight.Y - data.bal.DoorEdgeThreshold
                        else
                            data.StartY = center.Y
                            data.TargetY = topLeft.Y + data.bal.DoorEdgeThreshold
                        end

                        data.HalfPass = true

                        data.CycleTime = 0

                        doorData.Opposite:GetSprite():Play("Door Brimstone2 Start", true)
                        
                        RemoveLaserTracers(data)
                    end

                    if doorSprite:IsFinished("Door Brimstone Start") then
                        doorSprite:Play("Door Brimstone Loop", true)
                    end
                else
                    doorPositions[#doorPositions+1] = door.Position

                    if doorSprite:IsFinished("Door Brimstone2 Start") then
                        doorSprite:Play("Door Brimstone2 Loop", true)
                    end

                    if doorSprite:IsEventTriggered("Door Shoot") then
                        REVEL.PlaySound(data.bal.Sounds.ShootBubble)
                        data.Bubble = REVEL.ENT.MAXWELL_BUBBLE:spawn(door.Position + Vector.FromAngle(doorSprite.Rotation + 90) * 20, Vector.Zero, nil)
                    end

                    if doorSprite:IsFinished("Door Brimstone2 End") then
                        data.CustomDoorMovement = nil
                        data.State = "Idle"
                    end
                end
            end
        end
    elseif data.State == "GrandFinale" then
        if not data.AttackInit then
            data.TopDoor:GetSprite():Play("Door Brimstone Start", true)

            for _, trapdoor in ipairs(trapdoors) do
                trapdoor:GetData().TargetState = "Spring"
            end

            local roomHeight = REVEL.room:GetBottomRightPos().Y - REVEL.room:GetTopLeftPos().Y

            data.BrimstoneTellTracers = CreateLaserTell(data.TopDoor, data.TopDoor.Position + Vector(0, roomHeight), Vector(0, -20))

            data.AttackInit = true
        end

        if data.Death and sprite:IsFinished("Hop Start Fall") or sprite:IsFinished("Hop Middle Fall") then
            data.TopDoor.Velocity = Vector.Zero
            data.TopDoor:GetSprite():Play("Door Brimstone End", true)
            REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
            REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_STOP_SHORT, 0.6, 0, false, 1)
            data.DeathTrapdoor:GetData().Blender = true
            data.DeathTrapdoor:GetData().KillingMaxwell = npc
            data.DeathTrapdoor:GetData().Collision = "All"
            data.State = "Death"
            return
        end

        local topLeft = REVEL.room:GetTopLeftPos()
        local bottomRight = REVEL.room:GetBottomRightPos()
        local center = REVEL.room:GetCenterPos()
        local doorX = center.X
        local cycleLength
        if data.Laser then
            data.Laser:SetTimeout(4)

            data.Laser:SetMaxDistance(0)

            if data.CycleTime then
                data.CycleTime = data.CycleTime + 1

                doorX, cycleLength = CalculateJumpRopeProgress(data.StartX, data.TargetX, data.CycleTime, data.bal.GrandFinaleCycleTime, data.bal.JumpRopeAccel, data.bal.JumpRopeDecel, data.HalfPass)

                if data.bal.IsCraxwell then
                    if not data.Hopping and (data.CycleTime >= data.bal.GrandFinaleHopTrigger * cycleLength) then
                        if data.SwappingTraps then
                            data.CurrentTrap = data.CurrentTrap:GetData().Opposite
                            data.SwappingTraps = nil
                        end

                        if (data.TargetX < data.StartX and data.CurrentTrap:GetData().LeftTrapdoor) or (data.TargetX > data.StartX and not data.CurrentTrap:GetData().LeftTrapdoor) then
                            data.Dunked = nil
                            data.Hopping = true

                            if data.Death then
                                data.DeathTrapdoor = data.CurrentTrap:GetData().Opposite
                                data.DeathTrapdoor:GetData().TargetState = "Pit"
                                data.DeathHop = true
                                data.Arcs = {
                                    {HopType = "Middle", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position},
                                    "Fall"
                                }
                            else
                                data.Arcs = {
                                    {HopType = "Middle", StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap:GetData().Opposite.Position}
                                }
                            end

                            data.SwappingTraps = true
                        end
                    end
                else
                    if not data.HopFinale and (data.CycleTime >= data.bal.GrandFinaleHopTrigger * cycleLength) then
                        local leftDoor
                        for _, door in ipairs(doors) do
                            if door:GetData().LeftDoor then
                                leftDoor = door
                            end
                        end

                        local jumpDoor
                        if doorX > center.X then
                            jumpDoor = leftDoor:GetData().Opposite
                        else
                            jumpDoor = leftDoor
                        end

                        data.HopFinale = true
                        data.StartDoor = jumpDoor
                        npc.Position = jumpDoor.Position
                        jumpDoor:GetSprite():Play("Door Hop Start", true)
                        sprite:Play("Enter", true)
                        data.IdleTime = data.bal.GrandFinaleIdleTime
                    end
                end

                if data.CycleTime >= cycleLength then
                    data.HalfPass = nil
                    data.CycleTime = 0

                    if doorX > center.X then
                        data.StartX = bottomRight.X - data.bal.DoorEdgeThreshold
                        data.TargetX = topLeft.X + data.bal.DoorEdgeThreshold
                    else
                        data.StartX = topLeft.X + data.bal.DoorEdgeThreshold
                        data.TargetX = bottomRight.X - data.bal.DoorEdgeThreshold
                    end
                end
            end

            TrapdoorsBlockLaser(data.Laser, trapdoors, data, doorX, data.TopDoor.Position)
        end

        if data.bal.IsCraxwell and not data.Hopping and not data.DeathHop then
            if data.SwappingTraps then
                data.CurrentTrap = data.CurrentTrap:GetData().Opposite
            end

            data.SwappingTraps = nil
            data.Dunked = nil
            data.Hopping = true
            data.Arcs = {
                {HopType = REVEL.WeightedRandom(data.bal.CraxwellIdleHops), StartPos = data.CurrentTrap.Position, EndPos = data.CurrentTrap.Position}
            }
        end

        if data.bal.IsCraxwell then
            sprite.FlipX = not data.CurrentTrap:GetSprite().FlipX
        end

        if data.HopFinale then
            if data.IdleTime then
                if sprite:IsFinished("Enter") then
                    sprite:Play("Idle", true)
                end

                data.IdleTime = data.IdleTime - 1
                if data.IdleTime <= 0 then
                    local first, second = GetTrapdoorOrder(data.StartDoor, trapdoors)

                    if data.Death then
                        second:GetData().TargetState = "Pit"
                        data.DeathHop = true
                        data.DeathTrapdoor = second
                        data.Arcs = {
                            {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                            {HopType = "Middle", StartPos = first.Position, EndPos = second.Position},
                            "Fall"
                        }
                    else
                        data.Arcs = {
                            {HopType = "Start", StartPos = data.StartDoor.Position, EndPos = first.Position},
                            {HopType = "Middle", StartPos = first.Position, EndPos = second.Position},
                            {HopType = "End", StartPos = second.Position, EndPos = data.StartDoor:GetData().Opposite.Position}
                        }
                    end

                    sprite.FlipX = data.StartDoor:GetData().LeftDoor
                    data.Hopping = true
                    data.IdleTime = nil
                end
            end

            if data.Arcs and #data.Arcs == 1 and not data.DeathHop then -- last arc
                local endDoor = data.StartDoor:GetData().Opposite
                if not endDoor:GetSprite():IsPlaying("Door Hop Start") and not endDoor:GetSprite():IsFinished("Door Hop Start") then
                    endDoor:GetSprite():Play("Door Hop Start", true)
                end
            end

            if data.Hopping and not data.BrimstoneSplashed and math.abs(doorX - npc.Position.X) < data.bal.GrandFinaleBrimstoneSplashThreshold then
                local params = ProjectileParams()
                params.VelocityMulti = 1.25
                local bounceCounts = REVEL.Shuffle(data.bal.GrandFinaleProjectileBounces)
                for i = 1, #data.bal.GrandFinaleProjectileBounces do
                    local vec = REVEL.room:GetCenterPos() + Vector(math.random(-10,10),math.random(-30,30))
                    if i >= math.floor(#data.bal.GrandFinaleProjectileBounces*0.75) then
                        vec = target.Position
                    end
                    local pro = npc:FireBossProjectiles(1, vec, 0, params)
                    if data.bal.WallBounce["GrandFinale"] ~= nil then
                        if not data.bal.WallBounce["GrandFinale"] then
                            pro:GetData().wallBounced = true
                        end
                    end
                    pro:GetData().maxwBounce = bounceCounts[i]
                end

                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 0.7, 0, false, 1)
                local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 5, npc.Position, Vector.Zero, npc)
                eff.SpriteScale = Vector.One * 0.4

                REVEL.MaxEmitter:EmitParticlesNum(REVEL.MaxwellPartType, REVEL.MaxwellPartSystem,
                  Vec3(npc.Position, -28), Vec3(npc.Velocity.X*1.2,0,-4), 5 + math.random(4), 0.05, 45)
                REVEL.MaxEmitter:EmitParticlesNum(REVEL.MaxwellPartType, REVEL.MaxwellPartSystem,
                  Vec3(npc.Position, -28), Vec3(npc.Velocity.X*2,0,-6), 2 + math.random(3), 0.05, 45)

                data.BrimstoneSplashed = true
            end

            if not data.IdleTime and not data.Hopping and not data.DeathHop then
                npc.Position = data.StartDoor:GetData().Opposite.Position
                sprite:Play("Exit", true)
                data.HopFinale = nil
                data.BrimstoneSplashed = nil

                for _, door in ipairs(doors) do
                    if not door:GetData().TopDoor then
                        door:GetSprite():Play("Door Hop End", true)
                    end
                end
            end
        end

        local doorSprite, doorData = data.TopDoor:GetSprite(), data.TopDoor:GetData()

        data.TopDoor.Velocity = Vector(doorX, data.TopDoor.Position.Y) - data.TopDoor.Position
        if doorSprite:IsEventTriggered("Brimstone Tell") then
            REVEL.PlaySound(data.bal.Sounds.BrimstoneTell)
        end

        if doorSprite:IsEventTriggered("Brimstone Start") then
            data.Laser = EntityLaser.ShootAngle(1, data.TopDoor.Position, doorSprite.Rotation + 90, 4, Vector.FromAngle(doorSprite.Rotation - 90) * data.bal.JumpRopeBrimstoneOffset, data.TopDoor)
            REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_LOOP, 0.35, 0, true, 1)

            local numLeft = 0
            for _, player in ipairs(REVEL.players) do
                if player.Position.X < center.X then
                    numLeft = numLeft + 1
                end
            end

            if numLeft > #REVEL.players - numLeft then -- move right if players are on the left half of the room
                data.StartX = center.X
                data.TargetX = bottomRight.X - data.bal.DoorEdgeThreshold
            else
                data.StartX = center.X
                data.TargetX = topLeft.X + data.bal.DoorEdgeThreshold
            end

            data.HalfPass = true

            data.CycleTime = 0

            if data.Bubble then
                PopBubble(npc, data)
            end

            RemoveLaserTracers(data)
        end

        if doorSprite:IsFinished("Door Brimstone Start") then
            doorSprite:Play("Door Brimstone Loop", true)
        end
    end

    if data.Bubble and not data.Bubble:Exists() then
        data.Bubble = nil
    elseif data.Bubble then
        if data.Bubble:GetSprite():IsFinished("Bubble Spawn") then
            data.Bubble:GetSprite():Play("Bubble Idle", true)
        end

        data.Bubble.Velocity = REVEL.Lerp(data.Bubble.Position, REVEL.room:GetCenterPos() + Vector(0, -1), 0.1) - data.Bubble.Position
        data.Bubble.SpriteOffset = REVEL.Lerp(data.Bubble.SpriteOffset, Vector(0, data.bal.BubbleHeight), 0.1)
    end

    if data.SideAttack then
        npc.Position = data.TopDoor.Position
        if not data.SideAttackInit then
            data.TopDoor:GetSprite():Play("Door Hop Start", true)
            sprite:Play("Enter", true)

            data.SideAttackInit = 1
        end

        if sprite:IsFinished("Enter") then
            sprite:Play("Idle", true)
        end

        if data.SideAttack == "Idle" then
            if not sprite:IsPlaying("Enter") and not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            if data.EndSideAttack then
                data.SideAttack = nil
            end
        elseif data.SideAttack == "TrollBombs" then
            if data.SideAttackInit == 1 then
                data.NumBombs = math.random(data.bal.SideAttackBombs.Min, data.bal.SideAttackBombs.Max)
                data.Side = math.random(1, 2)
                data.SideAttackInit = 2
            end

            if sprite:IsFinished("Enter") or sprite:IsPlaying("Idle") then
                sprite:Play("Bomb Start " .. tostring(data.Side), true)
            end

            if sprite:IsFinished("Bomb Start " .. tostring(data.Side)) then
                sprite:Play("Bomb" .. tostring(data.Side), true)
            end

            if sprite:IsEventTriggered("Bomb") then
                throwBomb(npc, sprite, data)
                REVEL.PlaySound(data.bal.Sounds.ThrowBomb)
            end

            if sprite:IsFinished("Bomb" .. tostring(data.Side)) then
                data.Side = (data.Side % 2) + 1
                data.NumBombs = data.NumBombs - 1
                if data.NumBombs <= 0 then
                    data.SideAttack = "Idle"
                    data.NumBombs = nil
                    data.Side = nil
                else
                    sprite:Play("Bomb" .. tostring(data.Side), true)
                end
            end
        elseif data.SideAttack == "BigBall" then
            if sprite:IsFinished("Enter") or sprite:IsPlaying("Idle") then
                sprite:Play("ShootBigBall", true)
            end

            if sprite:IsEventTriggered("Shoot") then
                shootBigBall(npc, sprite, data, target)
            end

            if sprite:IsFinished("ShootBigBall") then
                data.SideAttack = "Idle"
            end
        elseif data.SideAttack == "CurvingFan" then
            if sprite:IsFinished("Enter") or sprite:IsPlaying("Idle") then
                data.CurveFanTarget = nil
                sprite:Play("ShootFan", true)
            end

            if sprite:IsEventTriggered("Shoot") then
                data.CurveFanTarget = data.CurveFanTarget or target.Position
                shootCurveFan(npc, sprite, data, data.CurveFanTarget, 2)
            end

            if sprite:IsFinished("ShootFan") then
                data.SideAttack = "Idle"
            end
        elseif data.SideAttack == "Whip" then
            if sprite:IsFinished("Enter") or sprite:IsPlaying("Idle") then
                data.WhipDuration = 0
                data.StartDirection = math.random(0, 1)
                local halfDuration = data.bal.WhipDuration / 2
                local relativeDist = data.bal.WhipDuration * data.bal.WhipBreatheDistanceFromCenter
                data.BreatheStart = math.random(math.floor(halfDuration - relativeDist), math.ceil(halfDuration + relativeDist))
                sprite:Play("ShootWhip Start", true)
            end

            if sprite:IsFinished("ShootWhip Start") or sprite:IsPlaying("ShootWhip Right") or sprite:IsPlaying("ShootWhip Left") or sprite:IsPlaying("BreatheIn") then
                if data.WhipDuration == data.BreatheStart then
                    sprite:Play("BreatheIn", true)
                    REVEL.PlaySound(data.bal.Sounds.Breathe)
                end

                if not sprite:IsPlaying("BreatheIn") or (data.WhipDuration > data.BreatheStart + data.bal.WhipBreatheDuration) then
                    local angle
                    if data.StartDirection == 0 then
                        angle = REVEL.Lerp(data.bal.WhipProjectileAngles.Left, data.bal.WhipProjectileAngles.Right, data.WhipDuration / data.bal.WhipDuration)
                    else
                        angle = REVEL.Lerp(data.bal.WhipProjectileAngles.Right, data.bal.WhipProjectileAngles.Left, data.WhipDuration / data.bal.WhipDuration)
                    end

                    local dir = Vector.FromAngle(angle)
                    if dir.X < 0 and not sprite:IsPlaying("ShootWhip Left") then
                        sprite:Play("ShootWhip Left", true)
                    elseif dir.X > 0 and not sprite:IsPlaying("ShootWhip Right") then
                        sprite:Play("ShootWhip Right", true)
                    end

                    if npc.FrameCount % data.bal.WhipProjectileFrequency == 0 then
                        local p = Isaac.Spawn(9, 0, 0, npc.Position + data.bal.TopDoorYOffset + (data.bal.WhipShotOffsetX * sign(dir.X)), dir * data.bal.WhipProjectileVelocity, npc):ToProjectile()
                        p.Scale = p.Scale * 1.1
                        p:GetData().maxwBounce = 4
                        p:GetData().wallBounced = true
                        p:GetData().noCollTimeout = 5
                        p:GetData().velMult = 0.99
                        p:GetData().velMultTime = 7
                        p.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 0.7, 0, false, 1)
                    end
                end

                data.WhipDuration = data.WhipDuration + 1
                if data.WhipDuration > data.bal.WhipDuration then
                    data.WhipDuration = nil
                    data.StartDirection = nil
                    data.BreatheStart = nil
                    sprite:Play("ShootWhip End", true)
                end
            end

            if sprite:IsFinished("ShootWhip End") then
                data.SideAttack = "Idle"
            end
        elseif data.SideAttack == "Shoot" then
            if sprite:IsFinished("Enter") or sprite:IsFinished("ShootQuick1") or sprite:IsFinished("ShootQuick2") then
                sprite:Play("Idle", true)
            end

            if sprite:IsPlaying("Idle") then
                if data.EndSideAttack then
                    data.IdleTime = nil
                    data.ShootDir = nil
                    data.SideAttack = "Idle"
                else
                    if not data.IdleTime then
                        data.IdleTime = data.bal.JumpRopeBulletCooldown
                    end

                    data.IdleTime = data.IdleTime - 1
                    if data.IdleTime <= 0 then
                        data.IdleTime = data.bal.JumpRopeBulletCooldown
                        if data.ShootDir then
                            data.ShootDir = (data.ShootDir % 2) + 1
                        else
                            data.ShootDir = math.random(1, 2)
                        end

                        sprite:Play("ShootQuick" .. tostring(data.ShootDir), true)
                    end
                end
            end

            if sprite:IsEventTriggered("Shoot") then
                shootBounce(npc, data, target, "JumpRope", -1, nil, data.bal.TopDoorYOffset)
            end
        end
    elseif data.SideAttackInit then
        sprite:Play("Exit", true)
        data.TopDoor:GetSprite():Play("Door Hop End", true)
        data.SideAttackInit = nil
    end

    for _, door in ipairs(doors) do
        if not door:GetData().TopDoor then
            local newPos
            if data.DoorsTrackPlayer then
                local topLeft, bottomRight = REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
                local targYClamped = math.min(target.Position.Y, bottomRight.Y - data.bal.DoorEdgeThreshold)
                targYClamped = math.max(targYClamped, topLeft.Y + data.bal.DoorEdgeThreshold)
                newPos = Vector(door.Position.X, REVEL.Lerp(door.Position, Vector(target.Position.X, targYClamped), 0.05).Y)
            elseif not data.CustomDoorMovement then
                newPos = Vector(door.Position.X, REVEL.Lerp(door.Position, REVEL.room:GetCenterPos(), 0.1).Y)
            end

            if newPos then
                door.Velocity = newPos - door.Position
            end
        end
    end

    data.PlayerFellInto = nil

    if data.Dunking then
        npc.Velocity = Vector.Zero
        for _, dunking in ipairs(data.Dunking) do
            dunking.Position = npc.Position + data.DunkingDirection * 35
        end

        if sprite:IsEventTriggered("Dunk") then
            REVEL.sfx:Play(SoundEffect.SOUND_MUSHROOM_POOF, 1, 0, false, 1.1)
            for _, dunking in ipairs(data.Dunking) do
                dunking:GetData().springFallingSpeed = 2.5
                dunking:GetData().springFallingAccel = 0.75
                dunking:GetData().gotDunkedOn = true
                dunking:GetData().dunker = EntityPtr(npc)
                dunking:GetData().maxwellDunking = nil
            end
        end

        if sprite:IsFinished("Slam Dunk") then
            data.Dunking = nil
            sprite:Play(data.PreviousAnim, true)

            if data.PreviousAnimFrames > 0 then
                for i = 1, data.PreviousAnimFrames do
                    sprite:Update()
                end
            end

            data.PreviousAnim = nil
            data.PreviousAnimFrames = nil
        end
    elseif data.Hopping then
        local springCooldown = data.bal.MaxwellSpringCooldown
        if data.State == "GrandFinale" then
            springCooldown = nil
        end

        local hopData, finishedArc = ManageHoppingObject(npc, sprite, data, trapdoors, springCooldown)

        if not finishedArc and hopData.SlamDunk and not data.Dunked then
            local dunking = {}
            local y = npc.SpriteOffset.Y
            for _, player in ipairs(REVEL.players) do
                local playerY = player:GetData().springHeight
                if playerY and math.abs(playerY - y) <= data.bal.SlamDunkHitboxY and npc.Position:DistanceSquared(player.Position) < (npc.Size + 35) ^ 2 then
                    dunking[#dunking + 1] = player
                end
            end

            if #dunking > 0 then
                for _, player in ipairs(dunking) do
                    player:GetData().maxwellDunking = true
                end

                data.PreviousAnim = hopData.Anim
                data.PreviousAnimFrames = sprite:GetFrame()
                data.Dunking = dunking
                data.DunkingDirection = npc.Velocity:Normalized()
                data.Dunked = true
                sprite:Play("Slam Dunk", true)
                REVEL.PlaySound(data.bal.Sounds.SlamDunk)
            end
        end
    else
        data.Dunked = nil
        npc.SpriteOffset = Vector.Zero
        npc.Velocity = Vector.Zero
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, maxwell_NpcUpdate, REVEL.ENT.MAXWELL.id)

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant ~= REVEL.ENT.MAXWELL.variant or not REVEL.IsRenderPassNormal() then return end

    local data = npc:GetData()
    if data.Hopping and data.CurrentSpriteOffset and data.TargetSpriteOffset then
        if data.InterpolationFrame then
            npc.SpriteOffset = REVEL.Lerp(data.CurrentSpriteOffset, data.TargetSpriteOffset, 0.5)
            data.InterpolationFrame = nil
        else
            npc.SpriteOffset = data.TargetSpriteOffset
        end
    end
end, REVEL.ENT.MAXWELL.id)

---@param npc Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param invuln integer
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, amount, flags, source, invuln)
    if npc.Variant ~= REVEL.ENT.MAXWELL.variant then return end
    if source.Entity then
        if source.Type == EntityType.ENTITY_BOMBDROP then
            for i,b in ipairs(REVEL.roomBombdrops) do
                if GetPtrHash(b) == GetPtrHash(source.Entity) and b:GetData().maxw then
                    return false
                end
            end
        elseif source.Type == EntityType.ENTITY_PROJECTILE then
            return false
        end
    end

    if npc.HitPoints - amount - REVEL.GetDamageBuffer(npc) <= 0 and npc:GetData().bal and npc:GetData().bal.BlenderDeath then
        if not REVEL.IsAchievementUnlocked("MAX_HORN") and npc:GetData().bal.IsCraxwell then
            REVEL.UnlockAchievement("MAX_HORN")
        end

        local deathframe = npc:GetData().Death
        if not deathframe then
            deathframe = REVEL.game:GetFrameCount()
            npc:GetData().Death = deathframe
        end

        if REVEL.game:GetFrameCount() < deathframe + 30 * 10 then
            npc.HitPoints = 1
            return false
        end
    end
end, REVEL.ENT.MAXWELL.id)

---@param npc EntityNPC
---@param collider Entity
REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, collider)
    if npc.Type ~= REVEL.ENT.MAXWELL.id or npc.Variant ~= REVEL.ENT.MAXWELL.variant then return end
    if collider:ToPlayer() then
        local sprite = npc:GetSprite()
        if (not sprite:WasEventTriggered("CollOff") or sprite:WasEventTriggered("CollOn")) and npc.CollisionDamage > 0 then
            collider:TakeDamage(npc.CollisionDamage, 0, EntityRef(npc), 0)
        end

        return true
    elseif collider:ToProjectile() then
        return true
    end
end)

---@param p EntityProjectile
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, p)
  local data,spr = p:GetData(),p:GetSprite()

  if data.noCollTimeout then
    data.noCollTimeout = data.noCollTimeout - 1
    if data.noCollTimeout == 0 then
      p.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
      data.noCollTimeout = nil
    else
      p.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
    end
  end

  if data.maxwBounce == 0 and data.maxBigBall and not REVEL.room:IsPositionInRoom(p.Position + p.Velocity, 8) then
    for i=1, 7 do
        Isaac.Spawn(1000, EffectVariant.BLOOD_PARTICLE, 0, p.Position + RandomVector() * 7, RandomVector() * 5, p)
    end
    local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 5, p.Position + Vector(0, -40), Vector.Zero, p)
    eff.SpriteScale = Vector.One * 0.6
    p:Remove()
  end

  if data.velMultTime then
    p.Velocity = p.Velocity * data.velMult
  end

  if data.maxBigBall then --incase it dies for other reasons (pulled by maws for instance)
    if p:IsDead() then
      if not data.maxBigBallJumpRope then
        for i=0, 5 do --0,1,2 left, 3,4,5 right
          local angle = (i%3) * 18/2 --towards right, 0 to 18
          local dir = Vector.FromAngle(-angle) --+angle would lead downwards
          if i < 3 then --flip for left
            dir = Vector(-dir.X, dir.Y)
          end

          REVEL.sfx:Play(REVEL.SFX.MAXWELL_BUBBLE_POP, 1, 0, false, 1)

          local proj2 = Isaac.Spawn(9, 0, 0, p.Position, dir*6, p.SpawnerEntity):ToProjectile()
          proj2.Height = p.Height
          proj2.FallingSpeed = 0
          proj2.Scale = 1.5
          proj2:GetData().maxwBounce = 4
          proj2:GetData().noCollTimeout = 5
          proj2:GetData().wallBounced = true
          proj2.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_X
        end
      end

      data.maxBigball = nil
    elseif p.FrameCount % 3 == 0 and p.Height > -60 then
      local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, p.Position, p, false):ToEffect()
      REVEL.UpdateCreepSize(creep, creep.Size * REVEL.Lerp2(1.3, 3, p.Height, -60, -8), true)
      creep.Timeout = 15
    end
  end

  if data.maxwBounce then
    p.FallingSpeed = p.FallingSpeed + (data.fallingAccel or 1.5)

    if p.Height + p.FallingSpeed > -8 and data.maxwBounce ~= 0 then
      p.FallingSpeed = -p.FallingSpeed*(data.maxBigBall or 1)
      data.maxwBounce = data.maxwBounce - 1
    end

    if (not data.wallBounced or data.infiniteWallBounce) and not data.noCollTimeout then
      local nextP = p.Position + p.Velocity
      local clamp = REVEL.room:GetClampedPosition(p.Position + p.Velocity, 0)
      local flipX, flipY = 1, 1
      if clamp.X ~= nextP.X then
          flipX = -1
      end

      if clamp.Y ~= nextP.Y then
          flipY = -1
      end

      if flipX ~= 1 or flipY ~= 1 then
        p.Velocity = Vector(p.Velocity.X * flipX, p.Velocity.Y * flipY)
        data.wallBounced = true
      end
    end

  elseif data.MaxBubble then
    local c = REVEL.room:GetCenterPos()
    local centerDist = math.abs(p.Position.X - c.X)
    local speedMult = REVEL.SmoothStep(centerDist, 0, 50)

    if centerDist < 50 then
      p:MultiplyFriction(speedMult)
    end

    p.Height = data.h
    p.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    p.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    if spr:IsFinished("Bubble Spawn") then
      spr:Play("Bubble Idle", true)
    elseif spr:IsFinished("Bubble Pop") then
      for i=1, 7 do
        Isaac.Spawn(1000, EffectVariant.BLOOD_PARTICLE, 0, p.Position + RandomVector() * 7, RandomVector() * 5, p)
      end
      p:Remove()
    end

  elseif data.BubbleBullet and p.FrameCount < 20 then
    p.FallingSpeed = 0
  end
end)

---@param e Entity
---@param targ Entity
---@param collPoint Vector
---@param targRad number
---@param eRad number
local function manageCollision(e, targ, collPoint, targRad, eRad)
    local diff = e.Position + e.Velocity - targ.Position
    if REVEL.VecEquals(diff,collPoint) then --inside of trapdoor
        targ.Velocity = -diff:Resized(7)
    else
        local targToCollPoint = diff + collPoint
        local collDist = targToCollPoint:Length()
        local par, perp, parL = REVEL.GetVectorComponents(targ.Velocity, targToCollPoint, nil, collDist)
        -- REVEL.DebugToString({"Point", collPoint, "playerToCollPoint", playerToCollPoint, "Dist", collDist, "Vel", p.Velocity, "p size", p.Size, "par", par, "perp", perp, "parL", parL, "par edit", par * (-collDist / parL), "final", par+perp})

        par = par * ((collDist-targRad) / parL) --resize parallel component of velocity so that it goes outwards from the trapdoor

        targ.Velocity = par + perp
    end
end

---@param e Entity
local function springBoulder(e)
    if REVEL.GetEntityZPosition(e) > 0 then return end

    REVEL.SetEntityAirMovement(e, {
        ZPosition = 15,
        Gravity = 0.23
    })
    REVEL.AddEntityZVelocity(e, 4)
end

---@param effect EntityEffect
local function maxwell_Trapdoor_PostEffectUpdate(_, effect)
    local data, sprite = effect:GetData(), effect:GetSprite()

    local playerOverRaised
    if not data.Collision then
        if data.State == "Spring Raised" then
            data.Collision = "Unless Jumping"
        else
            data.Collision = "None"
        end
    elseif data.Collision ~= "None" then
        local collidables = {}
        if data.Collision ~= "Except Player" then
            for _, player in ipairs(REVEL.players) do
                collidables[#collidables + 1] = player
            end
        end

        for _, enemy in ipairs(REVEL.roomEnemies) do
            if not REVEL.ENT.MAXWELL:isEnt(enemy) then
                collidables[#collidables + 1] = enemy
            end
        end

        for _, collidable in ipairs(collidables) do
            local collPoint = REVEL.GetCollisionCircleSquare(collidable.Position + collidable.Velocity, effect.Position, collidable.Size, data.bal.TrapdoorRadius+15)
            if collPoint then --if colliding
                local shouldCollide = true
                if collidable.Type == EntityType.ENTITY_PLAYER and data.Collision == "Unless Jumping" then
                    local springHeight = collidable:GetData().springHeight
                    if springHeight then
                        if springHeight <= data.bal.TrapdoorRaisedHeight or not collidable:GetData().SpringPeaked then
                            shouldCollide = false
                        end

                        if springHeight >= data.bal.TrapdoorRaisedTriggerHeight and collidable:GetData().SpringPeaked then
                            playerOverRaised = true
                        end
                    end
                end

                if shouldCollide then
                    manageCollision(effect, collidable, collPoint, collidable.Size, data.bal.TrapdoorRadius+15)
                end
            end
        end
    end

    if data.State == "Spring Raised" then
        effect.RenderZOffset = -4900
    else
        effect.RenderZOffset = -16000
    end

    if data.TargetState then
        if data.WaitForAnim then
            if not sprite:IsPlaying(data.WaitForAnim) or sprite:IsFinished(data.WaitForAnim) then
                data.WaitForAnim = nil
            end
        elseif data.TargetState == "Pit" then
            if data.State == "Spring" then
                data.State = "Pit"
                sprite:Play("Trap Door Lower Spring", true)
                REVEL.PlaySound(data.bal.Sounds.ChangePit)
            elseif data.State == "Trap" then
                data.State = "Trap Switch"
                data.From = data.Trap
                data.To = "Spring"
                sprite:Play("Trap Switch Off " .. data.From, true)
            end
        elseif data.TargetState == "Spring" then
            if data.State == "Pit" then
                if not sprite:IsPlaying("Trap Door Lower Spring") and not sprite:IsPlaying("Trap Door Lower") then
                    data.State = "Pit Rising"
                    sprite:Play("Trap Door Rise Spring", true)
                    REVEL.PlaySound(data.bal.Sounds.ChangePit)
                end
            elseif data.State == "Trap" then
                data.State = "Trap Switch"
                data.From = data.Trap
                data.To = "Spring"
                sprite:Play("Trap Switch Off " .. data.From, true)
            end
        elseif data.TargetState == "Trap" then
            if data.State == "Spring" then
                data.State = "Trap Switch"
                data.From = "Spring"
                data.To = data.NewTrap
                data.NewTrap = nil
                sprite:Play("Trap Switch Off " .. data.From, true)
            elseif data.State == "Pit" then
                data.State = "Pit Rising"
                data.NextState = "Spring"
                sprite:Play("Trap Door Rise Spring", true)
                REVEL.PlaySound(data.bal.Sounds.ChangePit)
            elseif data.State == "Trap" and data.NewTrap then
                data.State = "Trap Switch"
                data.From = data.Trap
                data.To = data.NewTrap
                data.NewTrap = nil
                sprite:Play("Trap Switch Off " .. data.From, true)
            end
        end

        if data.State == data.TargetState then
            data.TargetState = nil
        end
    end

    if not sprite:WasEventTriggered("Bounce") then
        data.PlayedBounce = nil
    end

    if sprite:IsEventTriggered("Bounce") or (sprite:WasEventTriggered("Bounce") and not data.PlayedBounce) then
        data.PlayedBounce = true
        REVEL.PlaySound(data.bal.Sounds.Spring)
    end

    if data.State ~= "Spring" and data.State ~= "Spring Triggered" then
        if #REVEL.ENT.MAXWELL:getInRoom() == 0 and (data.State ~= "Pit" or not data.Blender) then
            data.TargetState = "Spring"
        end
    end

    if data.SpringCollidingPlayers then
        for _, player in ipairs(REVEL.players) do
            if not player:GetData().springHeight and not player:GetSprite():IsPlaying("Jump") then
                local collPoint = REVEL.GetCollisionCircleSquare(player.Position + player.Velocity, effect.Position, player.Size, data.bal.TrapdoorRadius+15)
                if collPoint then
                    data.WaitForStepOff = true
                    REVEL.SpringPlayer(player, data.IsTutorial)
                end
            end
        end

        data.SpringCollidingPlayers = nil
    end

    data.JustHitFromRaised = nil

    if data.State ~= "Spring" and data.State ~= "Spring Triggered" then
        data.SpringCooldown = nil
    end

    if data.State ~= "Trap" then
        if data.State ~= "Trap Switch" and data.TargetState ~= "Trap" then
            data.SpecialTrap = nil
        end

        data.TriggerTrap = nil
    end

    if data.State == "Spring" then
        data.Collision = "None"
        if data.SpringCooldown then
            data.SpringCooldown = data.SpringCooldown - 1
            if data.SpringCooldown <= 0 then
                data.SpringCooldown = nil
            end

            sprite:SetFrame("Trap Spring", 1)
        else
            for _, player in ipairs(REVEL.players) do
                if not player:GetData().springHeight and not player:GetSprite():IsPlaying("Jump") then
                    local collPoint = REVEL.GetCollisionCircleSquare(player.Position + player.Velocity, effect.Position, player.Size, data.bal.TrapdoorRadius+15)
                    if collPoint then
                        if not data.WaitForStepOff then
                            REVEL.PlaySound(data.bal.Sounds.ActivateTrap)
                            if data.BrokenSpring then
                                sprite:Play("Trap Door Shake", true)
                                data.State = "Spring Shaking"
                                data.BrokenSpring = nil
                            else
                                data.WaitForStepOff = true
                                REVEL.SpringPlayer(player, data.IsTutorial)
                                sprite:Play("Trap Spring Trigger", true)
                                data.State = "Spring Triggered"
                            end
                        end
                    else
                        data.WaitForStepOff = nil
                    end
                elseif data.WaitForStepOff and not REVEL.GetCollisionCircleSquare(player.Position + player.Velocity, effect.Position, player.Size, data.bal.TrapdoorRadius+15) then
                    data.WaitForStepOff = nil
                end
            end

            if data.State == "Spring" then
                if data.WaitForStepOff then
                    sprite:SetFrame("Trap Spring", 1)
                else
                    sprite:SetFrame("Trap Spring", 0)
                end
            end
        end
    elseif data.State == "Spring Triggered" then
        if not sprite:IsPlaying("Trap Spring Trigger") and not sprite:IsPlaying("Trap Spring Trigger Fast") and not sprite:IsPlaying("Trap Spring Raised Trigger") and not sprite:IsPlaying("Trap Door Bomb Close") and not sprite:IsPlaying("Trap Door Bomb Trigger") then
            if not data.SpringCooldown then
                data.SpringCooldown = data.bal.SpringCooldown
            end

            data.State = "Spring"
        end
    elseif data.State == "Spring Raised" then
        data.Collision = "Unless Jumping"
        sprite:SetFrame("Trap Spring Raised", 0)
        if data.LowerCooldown then
            data.LowerCooldown = data.LowerCooldown - 1
        end

        if playerOverRaised or (data.LowerCooldown and data.LowerCooldown <= 0) then
            REVEL.PlaySound(data.bal.Sounds.ActivateTrap)
            data.SpringCooldown = data.bal.TrapdoorPushedSpringCooldown
            data.LowerCooldown = nil
            data.State = "Spring Triggered"
            data.JustHitFromRaised = playerOverRaised
            data.WaitForStepOff = true
            data.Collision = "None"
            sprite:Play("Trap Spring Raised Trigger", true)
        end
    elseif data.State == "Pit Rising" then
        data.Collision = "None"
        if sprite:IsFinished("Trap Door Rise") or sprite:IsFinished("Trap Door Rise Spring") then
            data.State = data.NextState or data.TargetState or "Spring"
            data.NextState = nil
        end
    elseif data.State == "Pit" then
        if not data.Blender then
            data.Collision = "Except Player"
        else
            data.Collision = "All"
        end

        if sprite:IsFinished("Trap Door Lower") or sprite:IsFinished("Trap Door Lower Spring") then
            sprite:Play("Trap Door", true)
        end

        if sprite:IsFinished("Trap Door Blender Off") then
            data.Blender = nil
        end

        if data.Blender and not data.BlenderFrames and data.KillingMaxwell and (sprite:IsPlaying("Trap Door") or sprite:IsFinished("Trap Door")) then
            REVEL.PlaySound(data.bal.Sounds.Blender)
            data.BlenderFrames = 0
            sprite:Play("Trap Door Blender", true)
        end

        if data.BlenderFrames then
            data.BlenderFrames = data.BlenderFrames + 1
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_PARTICLE, 0, effect.Position + RandomVector() * 20, RandomVector() * math.random(3, 9), data.KillingMaxwell)
            if data.BlenderFrames >= data.bal.BlenderKillMaxwellAt and data.KillingMaxwell then
                data.KillingMaxwell:Die()
                data.KillingMaxwell = nil
            end

            if data.BlenderFrames >= data.bal.BlenderDeathFrames then
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, effect.Position, Vector.Zero, data.KillingMaxwell)
                sprite:Play("Trap Door Blender Off", true)
                data.BlenderFrames = nil
            end
        end

        for _, player in ipairs(REVEL.players) do
            if not player:GetData().springPitfalling and REVEL.GetCollisionCircleSquare(player.Position, effect.Position, 1, data.bal.TrapdoorRadius + 15) and not player:GetData().springHeight and not player:GetSprite():IsPlaying("Jump") then --if player is completely inside pit
                local maxwells = REVEL.ENT.MAXWELL:getInRoom()

                for _, maxwell in ipairs(maxwells) do
                    maxwell:GetData().PlayerFellInto = effect
                end

                player:PlayExtraAnimation("FallIn")
                local pos = (player.Position - effect.Position):Clamped(-data.bal.TrapdoorPitfallRadius, -data.bal.TrapdoorPitfallRadius, data.bal.TrapdoorPitfallRadius, data.bal.TrapdoorPitfallRadius)
                player:GetData().pitfallPos = effect.Position + pos
                player.Position = effect.Position + pos
                player:GetData().springPitfalling = maxwells[1]
                REVEL.LockPlayerControls(player, "Spring")
                player.Velocity = Vector.Zero
            end
        end
    elseif data.State == "Trap Switch" then
        data.Collision = "None"
        if sprite:IsFinished("Trap Switch Off " .. data.From) then
            sprite:Play("Trap Switch In " .. data.To, true)
        end

        if sprite:IsFinished("Trap Switch In " .. data.To) then
            data.Trap = data.To
            if data.To == "Spring" then
                data.State = "Spring"
            else
                data.State = "Trap"
            end

            data.From = nil
            data.To = nil
        end
    elseif data.State == "Trap" then
        data.Collision = "None"

        local isPressable = data.CloseDoor:GetData().State == "Idle"
        if data.TriggerBoth then
            isPressable = isPressable and data.CloseDoor:GetData().Opposite:GetData().State == "Idle"
        end

        if data.SpecialTrap == 0 then
            isPressable = true
        elseif data.SpecialTrap == 1 then
            isPressable = false
        end

        if isPressable then
            sprite:SetFrame("Trap " .. data.Trap, 0)

            local steppedOn
            local collidables = Isaac.FindByType(EntityType.ENTITY_BOMBDROP, -1, -1, false, false)
            for _, player in ipairs(REVEL.players) do
                if not player:GetSprite():IsPlaying("Jump") and not player:GetData().springHeight then
                    collidables[#collidables + 1] = player
                end
            end

            for _, collidable in ipairs(collidables) do
                if REVEL.GetEntityZPosition(collidable) == 0 and not collidable:GetData().springHeight then
                    local collPoint = REVEL.GetCollisionCircleSquare(collidable.Position + collidable.Velocity, effect.Position, collidable.Size, data.bal.TrapdoorRadius+15)
                    if collPoint then
                        steppedOn = true
                    end
                end
            end

            if steppedOn or data.TriggerTrap then
                REVEL.PlaySound(data.bal.Sounds.ActivateTrap)
                data.CloseDoor:GetData().TargetState = data.Trap
                data.CloseDoor:GetData().SpecialTrap = not not data.SpecialTrap
                if data.TriggerBoth then
                    data.CloseDoor:GetData().Opposite:GetData().TargetState = data.Trap
                end

                if data.SpecialTrap then
                    data.SpecialTrap = 1
                end
            end
        else
            sprite:SetFrame("Trap " .. data.Trap, 1)
        end

        data.TriggerTrap = nil
    elseif data.State == "Occupied" then
        if not sprite:IsPlaying("Trap Door Bomb Trigger") then
            for _, player in ipairs(REVEL.players) do
                if not player:GetData().springHeight and not player:GetSprite():IsPlaying("Jump") then
                    local collPoint = REVEL.GetCollisionCircleSquare(player.Position + player.Velocity, effect.Position, player.Size, data.bal.TrapdoorRadius+15)
                    if collPoint then
                        local fromMaxSide = (data.LeftTrapdoor and player.Position.X > effect.Position.X + data.bal.TrapdoorRadius) or (not data.LeftTrapdoor and player.Position.X < effect.Position.X - data.bal.TrapdoorRadius)
                        if not fromMaxSide then
                            REVEL.PlaySound(data.bal.Sounds.ActivateTrap)
                            sprite:Play("Trap Door Bomb Trigger", true)
                            REVEL.PlaySound(data.bal.Sounds.Crushed)
                        else
                            manageCollision(effect, player, collPoint, player.Size, data.bal.TrapdoorRadius+15)
                        end
                    end
                end
            end
        elseif sprite:IsEventTriggered("Bounce") then
            sprite.Color = Color.Default
            for _, player in ipairs(REVEL.players) do
                if not player:GetData().springHeight then
                    local collPoint = REVEL.GetCollisionCircleSquare(player.Position + player.Velocity, effect.Position, player.Size, data.bal.TrapdoorRadius+15)
                    if collPoint then
                        REVEL.SpringPlayer(player)
                    end
                end
            end

            data.State = "Spring Triggered"
        else
            sprite.Color = REVEL.HURT_COLOR
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, maxwell_Trapdoor_PostEffectUpdate, REVEL.ENT.MAXWELL_TRAP.variant)

---@param e EntityEffect
---@param data table
---@param spr Sprite
local function tutorialMessageUpdate(e, data, spr)
    if data.Arcs then
        if not data.EndHeight then
            data.EndHeight = MaxwellBalance.Hops[data.Arcs[#data.Arcs].HopType].End
        end

        data.HopFrame = data.HopFrame or 0
        data.HopFrame = data.HopFrame + 1
        local hopData, finishedArc = ManageHoppingObject(e, data.HopFrame, data)
        if finishedArc then
            data.HopFrame = 0
            if not data.Arcs then
                data.HopFrame = nil
                e.Velocity = Vector.Zero
            end
        end

        e.SpriteOffset = data.TargetSpriteOffset or Vector(0, data.EndHeight)
    else
        e.Velocity = Vector.Zero
        e.SpriteOffset = Vector(0, data.EndHeight)
        if not data.Collected then
            local forceCollect
            if data.Trapdoor:GetData().State ~= data.TrapdoorState then
                forceCollect = true
            end

            for i,p in ipairs(REVEL.players) do
                if p.Position:Distance(e.Position) < p.Size + 20 or forceCollect then
                    spr:Play("Collect", true)
                    data.Collected = true
                    StageAPI.PlayTextStreak(data.Message[1], data.Message[2], Vector(50,14), Vector.One*0.6, "gfx/ui/larger_cursepaper.png", Vector(124, 14), REVEL.CurseFont, REVEL.CurseFont, KColor(0, 0, 0, 1))
                    REVEL.sfx:Play(SoundEffect.SOUND_SHELLGAME, 0.7, 0, false, 1)
                    break
                end
            end
        end
    end

    e.SpriteOffset = Vector(6, e.SpriteOffset.Y)

    if spr:IsFinished("Collect") then
        e:Remove()
    end
end

---@param npc EntityNPC
local function maxwell_Door_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.MAXWELL_DOOR.variant then return end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.Init then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        data.Init = true
    end

    REVEL.ApplyKnockbackImmunity(npc)
    if data.TopDoor then
        local targetPos = npc.Position + npc.Velocity
        local correctedPos = Vector(
            REVEL.Clamp(targetPos.X, data.LeftPos.X, data.RightPos.X),
            data.LeftPos.Y
        )
        npc.Velocity = correctedPos - npc.Position
    else
        local targetPos = npc.Position + npc.Velocity
        local correctedPos = Vector(
            data.TopPos.X,
            REVEL.Clamp(targetPos.Y, data.TopPos.Y, data.BottomPos.Y)
        )
        npc.Velocity = correctedPos - npc.Position
    end

    local maxwell = REVEL.ENT.MAXWELL:getInRoom()[1]
    if not maxwell then
        npc.Velocity = Vector.Zero
        if data.State == "Idle" then
            sprite:Play("Fade", true)
            data.State = "Death"
        end
    end

    if data.TargetState then
        if data.State == "Idle" then
            if data.TargetState == "Arrow" then
                sprite:Play("Door Arrow", true)
                data.State = "Arrow"
            elseif data.TargetState == "Fire" then
                sprite:Play("Door Fire", true)
                data.State = "Fire"
            elseif data.TargetState == "Boulder" then
                sprite:Play("Door Boulder", true)
                data.State = "Boulder"
            elseif data.TargetState == "Enemies" then
                sprite:Play("Door Enemies", true)
                data.State = "Enemies"
            elseif data.TargetState == "IdleNoMove" then
                data.TargetState = nil
                if sprite:IsPlaying("Door Move Closed") then
                    sprite:Play("Door Closed", true)
                end
            end
        end

        if data.TargetState == data.State then
            data.TargetState = nil
        end
    end

    if data.State == "Arrow" then
        if sprite:IsFinished("Door Arrow") then
            sprite:Play("Door Move Closed", true)
            data.State = "Idle"
            data.SpecialTrap = nil
            data.Angles = nil
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.PlaySound(data.bal.Sounds.DoorShoot)
            if data.SpecialTrap then
                if not data.Angles then
                    data.Angles = {}
                    local angles = REVEL.Shuffle(data.bal.SpecialArrowAngles)
                    for _, angle in ipairs(angles) do
                        data.Angles[#data.Angles + 1] = angle
                    end
                end

                local dir = Vector.FromAngle(sprite.Rotation + 90 + data.Angles[#data.Angles])
                shootBounce(npc, data, nil, "ArrowSpecial", -1, true, dir * 20, dir)

                data.Angles[#data.Angles] = nil
            else
                local p = Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(sprite.Rotation + 90) * 11, npc):ToProjectile()
                p.ProjectileFlags = ProjectileFlags.HIT_ENEMIES
                p.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
            end
        end
    elseif data.State == "Fire" then
        if sprite:IsFinished("Door Fire") then
            sprite:Play("Door Move Closed", true)
            data.State = "Idle"
            data.SpecialTrap = nil
        end

        if sprite:IsEventTriggered("Shoot") then
            if not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_START) and not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_LOOP) then
                REVEL.PlaySound(data.bal.Sounds.FireStart)
            end
        end

        if sprite:IsEventTriggered("Stop") then
            REVEL.PlaySound(data.bal.Sounds.FireStop)
        end

        if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop") and npc.FrameCount%2 == 0 then
            local cooldownMult = data.bal.FlameTrapCooldownMult
            if data.SpecialTrap then
                cooldownMult = data.bal.SpecialFlameTrapCooldownMult
            end

            REVEL.ShootFlameTrap(npc, sprite.Rotation, false, 1.3, 9, cooldownMult)
        end
    elseif data.State == "Boulder" then
        if sprite:IsFinished("Door Boulder") or sprite:IsFinished("Door Boulder End") then
            sprite:Play("Door Move Closed", true)
            data.State = "Idle"
        end

        if sprite:IsFinished("Door Boulder Repeat") then
            data.BoulderCount = data.BoulderCount or 0
            data.BoulderCount = data.BoulderCount + 1
            if data.BoulderCount >= data.bal.SpecialBoulderCount - 1 then
                data.BoulderCount = nil
                data.SpecialTrap = nil
                sprite:Play("Door Boulder End", true)
            else
                sprite:Play("Door Boulder Repeat", true)
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            if data.SpecialTrap and sprite:IsPlaying("Door Boulder") then
                sprite:Play("Door Boulder Repeat", true)
                sprite:Update()
            end

            local pos = REVEL.room:GetClampedPosition(npc.Position, 0)
            local b = REVEL.SpawnSandBoulder(pos, (Vector.FromAngle(sprite.Rotation + 90) * 9))
            b:GetSprite():Play("Roll Start Small", true)
        end
    elseif data.State == "Enemies" then
        if sprite:IsFinished("Door Enemies") then
            sprite:Play("Door Move Closed", true)
            data.State = "Idle"
        end

        if sprite:IsEventTriggered("Spawn") then
            local r = math.random(55,125)
            local enm = REVEL.WeightedRandom(data.bal.CoffinEnemies)
            local ent = REVEL.SpawnEntCoffin(REVEL.ENT[enm].id, REVEL.ENT[enm].variant, 0, npc.Position, npc.Velocity + (Vector.FromAngle(sprite.Rotation + r) * 10), npc)
            ent:GetData().NoRags = true
        end
    elseif data.State == "SpitMessage" then
        if sprite:IsFinished("Door Hop Start") then
            local msg = REVEL.SpawnDecorationFromTable(npc.Position, Vector.Zero, {
                Anim = "Idle",
                Sprite = "gfx/bosses/revel2/maxwell/tutorial_card.anm2",
                Update = tutorialMessageUpdate,
                RemoveOnAnimEnd = false,
            })

            local first, second = GetTrapdoorOrder(npc, REVEL.ENT.MAXWELL_TRAP:getInRoom())
            msg:GetData().Message = data.bal.SpitMessage
            if data.bal.IsCraxwell then
                msg:GetData().Trapdoor = first
                msg:GetData().Arcs = {
                    {HopType = "MessageStartChampion", StartPos = npc.Position, EndPos = first.Position}
                }
            else
                msg:GetData().Trapdoor = second
                msg:GetData().Arcs = {
                    {HopType = "MessageStart", StartPos = npc.Position, EndPos = first.Position},
                    {HopType = "MessageMiddle", StartPos = first.Position, EndPos = second.Position}
                }
            end
            msg:GetData().TrapdoorState = msg:GetData().Trapdoor:GetData().State
            REVEL.PlaySound(data.bal.Sounds.DoorShoot)

            sprite:Play("Door Hop End", true)
            data.State = "Idle"
        end
    elseif data.State == "Death" then
        if sprite:IsFinished("Fade") then
            sprite:Play("Death", true)
        end

        if sprite:IsFinished("Death") then
            REVEL.PlaySound(data.bal.Sounds.DoorBreak)
            for i=1, 4 do
                local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, RandomVector() * math.random(1, 5), nil)
                rock:Update()
            end

            npc:Remove()
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, maxwell_Door_NpcUpdate, REVEL.ENT.MAXWELL_DOOR.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e)
    if e.Variant == REVEL.ENT.MAXWELL_DOOR.variant then return false end
end, REVEL.ENT.MAXWELL_DOOR.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant ~= REVEL.ENT.MAXWELL.variant then return end
    REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
    if npc:GetData().Laser then
        REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_STOP_SHORT, 0.6, 0, false, 1)
    end
end, REVEL.ENT.MAXWELL.id)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_BOULDER_IMPACT, 2, function(boulder, npc, isGrid)
    if isGrid or not REVEL.ENT.MAXWELL:isEnt(npc) then return end

    if not npc:GetData().Hopping then
        npc:TakeDamage(npc.MaxHitPoints * 0.1, 0, EntityRef(boulder), 0)
    end

    return false
end)

REVEL.MaxwellBalance = MaxwellBalance

end