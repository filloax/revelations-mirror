local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local PitState = require("scripts.revelations.common.enums.PitState")
local RevRoomType = require("scripts.revelations.common.enums.RevRoomType")

return function()

-- wow i'm programming a boss i designed myself, this is kinda cool!

local BOSS_ROOM_TYPE = RevRoomType.ICE_BOSS

-- hope you like ice physics
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_BOSS_ROOM_INIT, 1, function(newRoom, boss)
    if boss.Name == "Prong" or boss.NameTwo == "Prong" then
        newRoom:SetTypeOverride(BOSS_ROOM_TYPE)
    end
end)

local prongBalance = {
    Champions = {Prongerina = "Default"},
    Sprite = {
        Default = "",
        Prongerina = "gfx/bosses/revel1/prong/prong_champ.anm2"
    },

    AttackCycleNonRepeatWeight = 1000,
    SubCycles = {
        InvincibleCoolFriend = {
            {
                Attacks = {
                    CoolFriend = 1
                },
                Visible = true,
                InvincibleWormSpawn = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                }
            }
        },
        CrackKebab = {
            {
                Attacks = {
                    Kebab = 1
                },
                CooldownAfter = {
                    Min = 20,
                    Max = 40
                },
                IdleCooldown = {
                    Min = 20,
                    Max = 40
                }
            }
        },
        PhaseCrackKebab = { -- Technically the entire second phase
            {
                Attacks = {
                    FlopAndCrack = 1
                },
                LShape = true,
                CooldownBetween = 20,
                CooldownAfter = {
                    Min = 60,
                    Max = 80
                }
            },
            {
                Attacks = {
                    BalancingBlock = 1,
                    CoolFriend = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 25
                },
                IdleCooldown = {
                    Min = 15,
                    Max = 35
                }
            },
            {
                Attacks = {
                    BalancingBlock = 2,
                    CoolFriend = 3,
                    HighHail = 1,
                    Kebab = 1
                },
                Visible = true,
                IgnoreLastAttackInCycle = true,
                AvoidLastAttackInGeneral = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 25
                },
                IdleCooldown = {
                    Min = 15,
                    Max = 35
                }
            },
            {
                Attacks = {
                    HighHail = 1,
                    BalancingBlock = 1
                },
                Visible = true,
                Repeat = 2,
                CooldownAfter = {
                    Min = 15,
                    Max = 25
                },
                CooldownBetween = {
                    Min = 10,
                    Max = 20
                },
                IdleCooldown = {
                    Min = 10,
                    Max = 20
                }
            },
            {
                Attacks = {
                    Kebab = 1
                },
                CrackKebab = true,
                AvoidCorner = true,
                NeedsWorm = true,
                CooldownAfter = {
                    Min = 20,
                    Max = 40
                }
            },
            {
                Attacks = {
                    Kebab = 1
                },
                CrackKebab = true,
                NeedsWorm = true,
                CooldownAfter = {
                    Min = 20,
                    Max = 40
                }
            },
            {
                Attacks = {
                    BalancingBlock = 1,
                    CoolFriend = 1,
                    HighHail = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 30,
                    Max = 50
                }
            },
            {
                Attacks = {
                    Refreeze = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 30,
                    Max = 50
                },
                IdleCooldown = {
                    Min = 15,
                    Max = 30
                }
            }
        },
        SuperFlopAndCrack = {
            {
                Attacks = {
                    FlopAndCrack = 1
                },
                UShape = true,
                CooldownBetween = 20,
                CooldownAfter = {
                    Min = 60,
                    Max = 80
                }
            }
        },
        SidesFlopAndCrack = {
            {
                Attacks = {
                    FlopAndCrack = 1
                },
                IIShape = true,
                CooldownBetween = 20,
                CooldownAfter = {
                    Min = 60,
                    Max = 80
                }
            }
        },
        EdgeFlopAndCrack = {
            {
                Attacks = {
                    FlopAndCrack = 1
                },
                CooldownBetween = 20,
                UShapeIfMoreLeft = true,
                ResetFlopPath = true,
                CheckAdjacentUnbroken = true,
                CooldownAfter = {
                    Min = 60,
                    Max = 80
                }
            }
        },
        ChampionMidAttacks = {
            {
                Attacks = {
                    BalancingBlock = 1,
                    CoolFriend = 1,
                    HighHail = 1,
                },
                Visible = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                },
                IdleCooldown = {
                    Min = 20,
                    Max = 40
                }
            },
            {
                Attacks = {
                    NorthernWind = 1
                },
                Visible = true,
                WindMoving = true,
                IgnoreLastAttackInCycle = true,
                AvoidLastAttackInGeneral = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                },
                IdleCooldown = {
                    Min = 30,
                    Max = 50
                }
            },
        }
    },
    BasicCycle = {
        Default = {
            {
                Attacks = {
                    BalancingBlock = 1,
                    CoolFriend = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                },
                IdleCooldown = {
                    Min = 20,
                    Max = 40
                }
            },
            {
                Attacks = {
                    BalancingBlock = 2,
                    CoolFriend = 2,
                    HighHail = 1
                },
                Visible = true,
                IgnoreLastAttackInCycle = true,
                AvoidLastAttackInGeneral = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                },
                IdleCooldown = {
                    Min = 30,
                    Max = 50
                }
            },
            {
                Attacks = {
                    HighHail = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 30,
                    Max = 50
                }
            },
        },
        Prongerina = {
            {
                Attacks = {
                    BalancingBlock = 1,
                    CoolFriend = 1
                },
                Visible = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 30
                },
                IdleCooldown = {
                    Min = 20,
                    Max = 40
                }
            },
            {
                Attacks = {
                    BalancingBlock = 2,
                    CoolFriend = 2,
                    NorthernWind = 1,
                    HighHail = 1,
                },
                Visible = true,
                IgnoreLastAttackInCycle = true,
                AvoidLastAttackInGeneral = true,
                CooldownAfter = {
                    Min = 15,
                    Max = 25
                },
                IdleCooldown = {
                    Min = 30,
                    Max = 50
                }
            },
            {
                Attacks = {
                    HighHail = 1,
                    NorthernWind = 1
                },
                AvoidLastAttackInGeneral = true,
                Visible = true,
                CooldownAfter = {
                    Min = 30,
                    Max = 50
                }
            },
        }
    },
    FinaleCycle = {
        {
            Attacks = {
                FlopAndCrack = 1
            },
            Safety = true,
            CooldownAfter = {
                Min = 60,
                Max = 80
            }
        },
        {
            Attacks = {
                CoolFriend = 1
            },
            Visible = true,
            CooldownAfter = {
                Min = 30,
                Max = 50
            }
        },
        {
            Attacks = {
                Kebab = 1
            },
            CrackKebab = true,
            NeedsWorm = true,
            CooldownAfter = {
                Min = 20,
                Max = 40
            }
        },
        {
            Attacks = {
                BalancingBlock = 1
            },
            Visible = true,
            CooldownAfter = {
                Min = 30,
                Max = 50
            }
        },
        {
            Attacks = {
                CoolFriend = 1,
                HighHail = 1
            },
            Visible = true,
            CooldownAfter = {
                Min = 30,
                Max = 50
            }
        },
        {
            Attacks = {
                HighHail = 1
            },
            Visible = true,
            CooldownAfter = {
                Min = 40,
                Max = 60
            }
        },
        {
            Attacks = {
                Refreeze = 1
            },
            Visible = true,
            CooldownAfter = {
                Min = 30,
                Max = 50
            },
            IdleCooldown = {
                Min = 30,
                Max = 50
            }
        }
    },
    ChampionMidCycle = {
        {
            Attacks = {
                ChampionMidAttacks = 1
            },
            Visible = true,
            Repeat = {Min = 2, Max = 5},
            CooldownAfter = {
                Min = 30,
                Max = 50
            },
        },
        {
            Attacks = {
                Refreeze = 1
            },
            Visible = true,
            RefreezeAll = true,
            CooldownAfter = {
                Min = 30,
                Max = 50
            },
            IdleCooldown = {
                Min = 30,
                Max = 50
            }
        },
        {
            Attacks = {
                FlopAndCrack = 1
            },
            IIShape = true,
            CooldownBetween = 20,
            CooldownAfter = {
                Min = 60,
                Max = 80
            }
        },
    },
    ChampionFinaleCycle = {
        {
            Attacks = {
                ChampionMidAttacks = 1
            },
            Visible = true,
            Repeat = {Min = 5, Max = 8},
            CooldownAfter = {
                Min = 30,
                Max = 50
            },
        },
        {
            Attacks = {
                Refreeze = 1
            },
            Visible = true,
            RefreezeAll = true,
            CooldownAfter = {
                Min = 12,
                Max = 25
            },
            IdleCooldown = {
                Min = 30,
                Max = 50
            }
        },
        {
            Attacks = {
                FlopAndCrack = 1
            },
            UShape = true,
            CooldownBetween = 20,
            CooldownAfter = {
                Min = 60,
                Max = 80
            }
        },
    },
    CycleStartCheck = function(data, bal, curCycleSegment)
        if curCycleSegment.NeedsWorm and REVEL.ENT.ICE_WORM:countInRoom() == 0 then
            REVEL.AddToCycle(data, "InvincibleCoolFriend", 1, true)
        end

        return true
    end,
    PostCycleWeights = function(attacks, data, bal, curCycleSegment, curCycleData)
        if attacks["CoolFriend"] and (REVEL.ENT.ICE_WORM:isEnt(bal.CoolFriendSpawnedEntity) or (not bal.CoolFriendSpawnedEntity.id and REVEL.IsEntIn(bal.CoolFriendSpawnedEntity, REVEL.ENT.ICE_WORM))) then
            if not data.SpawnedFirstIceWorm then
                attacks["CoolFriend"] = 100000
                data.SpawnedFirstIceWorm = true
            elseif REVEL.ENT.ICE_WORM:countInRoom() == 0 then
                attacks["CoolFriend"] = attacks["CoolFriend"] * 2
            end
        end
    end,

    Phases = {
        Default = {
            {Cycle = "BasicCycle"},
            {Threshold = 0.75, Cycle = "FinaleCycle", TriggerSubCycle = "PhaseCrackKebab"}
        },
        Prongerina = {
            {Cycle = "BasicCycle"},
            {Threshold = 0.6, Cycle = "ChampionMidCycle", TriggerSubCycle = "SidesFlopAndCrack"},
            {Threshold = 0.25, Cycle = "ChampionFinaleCycle", TriggerSubCycle = "EdgeFlopAndCrack"},
        },
    },

    InitialAttackCooldown = 30,

    IceHazardVariants = {
        Default = {REVEL.ENT.ICE_HAZARD_GAPER, REVEL.ENT.ICE_HAZARD_HORF, REVEL.ENT.ICE_HAZARD_CLOTTY},
        Prongerina = {REVEL.ENT.ICE_HAZARD_HOPPER, REVEL.ENT.ICE_HAZARD_BROTHER, REVEL.ENT.ICE_HAZARD_CLOTTY},
    },
    HazardFlightTime = 14,
    HazardWobbleTime = 4,
    HazardWobbleIntensity = 10, -- initial wobble
    HazardWobbleSlope = 0.5, -- intensity is multiplied by this each wobble

    FirstJumpLength = 26,
    SecondJumpLength = 26,

    FlopAndCrackAllowKebab = {
        Default = true,
        Prongerina = false,
    },

    KebabSpread = 33,
    KebabSpeed = 10,
    KebabRNG = 2,
    KebabHeal = 0.04,
    KebabBoneNum = 1,
    KebabBoneSpeed = 6,
    KebabBoneAccel = -1,

    CoolFriendSpawnedEntity = {
        Default = REVEL.ENT.ICE_WORM,
        Prongerina = REVEL.ENT.SHY_FLY,
    },
    CoolFriendNumSpawned = 1,

    HighHailUseBomb = {
        Default = false,
        Prongerina = true,
    },

    NorthernWindOffsets = {
        [Direction.LEFT] = Vector(-24, -12) * REVEL.SCREEN_TO_WORLD_RATIO,
        [Direction.UP] = Vector(0, -16) * REVEL.SCREEN_TO_WORLD_RATIO,
        [Direction.RIGHT] = Vector(24, -12) * REVEL.SCREEN_TO_WORLD_RATIO,
        [Direction.DOWN] = Vector(0, -6) * REVEL.SCREEN_TO_WORLD_RATIO,
    },
    NorthernWindDuration = {Min = 45, Max = 90},
    NorthernWindMoveSpeed = 3,
    NorthernWindMoveLimit = 0.6, --of room width/height
    NorthernWindVertWidth = 160,
    NorthernWindHoriHeight = 80,

	Sounds = {
        Default = {
            Throw = {Sound = REVEL.SFX.PRONG.THROW},
            Smile = {Sound = REVEL.SFX.PRONG.SMILE, PitchVariance = 0.1},
            Telekinesis = {Sound = REVEL.SFX.PRONG.TELEKINESIS},
            TelekinesisEnd = {Sound = REVEL.SFX.PRONG.REFREEZE2},
            Refreeze1 = {Sound = REVEL.SFX.PRONG.REFREEZE1},
            Refreeze2 = {Sound = REVEL.SFX.PRONG.REFREEZE2},
            Tired = {Sound = REVEL.SFX.PRONG.TIRED},
            Gulp = {Sound = SoundEffect.SOUND_VAMP_GULP},
            Burp = {Sound = REVEL.SFX.BURP_LONG},
            Whistle = {Sound = SoundEffect.SOUND_DANGLE_WHISTLE},
            Death1 = {Sound = REVEL.SFX.PRONG.DEATH1},
            Death2 = {Sound = REVEL.SFX.PRONG.DEATH2},
            Death3 = {Sound = REVEL.SFX.PRONG.DEATH3},
            LandJump = {Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS},
        },
        Prongerina = {
            Throw = {Sound = REVEL.SFX.PRONG.THROW, Pitch = 1.2},
            Smile = {Sound = REVEL.SFX.PRONG.SMILE, PitchVariance = 0.1, Pitch = 1.2},
            Telekinesis = {Sound = REVEL.SFX.PRONG.TELEKINESIS, Pitch = 1.2},
            TelekinesisEnd = {Sound = REVEL.SFX.PRONG.REFREEZE2, Pitch = 1.2},
            Refreeze1 = {Sound = REVEL.SFX.PRONG.REFREEZE1, Pitch = 1.2},
            Refreeze2 = {Sound = REVEL.SFX.PRONG.REFREEZE2, Pitch = 1.2},
            Tired = {Sound = REVEL.SFX.PRONG.TIRED, Pitch = 1.2},
            Gulp = {Sound = SoundEffect.SOUND_VAMP_GULP},
            Burp = {Sound = REVEL.SFX.BURP_LONG},
            Whistle = {Sound = SoundEffect.SOUND_DANGLE_WHISTLE},
            Death1 = {Sound = REVEL.SFX.PRONG.DEATH1, Pitch = 1.2},
            Death2 = {Sound = REVEL.SFX.PRONG.DEATH2, Pitch = 1.2},
            Death3 = {Sound = REVEL.SFX.PRONG.DEATH3, Pitch = 1.2},
            BreatheIn = {Sound = REVEL.SFX.MOUTH_PULL, Pitch = 1.8, Volume = 0.8},
            LandJump = {Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS},
        }
	},
}

local Corners = {1, 3, 6, 8}
local MiddleSegments = {2, 4, 5, 7}

local RoomSegments

local function ResetSegments()
    RoomSegments = {
        {
            TL = Vector(0, 0), -- off of room top left in grids
            Size = Vector(3, 1), -- grids, starting at 0
            Center = Vector(80, 40), -- position offset, from TL
            Crack = "CornerCrack",
            Opposites = {Horizontal = {2, 3}, Vertical = {4, 6}},
            Adjacent = {2, 4},
            Right = 2,
            Down = 4,
        },
        {
            TL = Vector(4, 0),
            Size = Vector(4, 1),
            Center = Vector(100, 40),
            Crack = "HorizontalCrack",
            Adjacent = {1, 9, 3},
            Left = 1,
            Right = 3,
            Down = 9,
        },
        {
            TL = Vector(9, 0),
            Size = Vector(3, 1),
            Center = Vector(80, 40),
            Crack = "CornerCrack",
            Opposites = {Horizontal = {2, 1}, Vertical = {5, 8}},
            Adjacent = {2, 5},
            Left = 2,
            Down = 5,
        },
        {
            TL = Vector(0, 2),
            Size = Vector(3, 2),
            Center = Vector(80, 60),
            Crack = "VerticalCrack",
            Adjacent = {1, 9, 6},
            Up = 1,
            Right = 9,
            Down = 6,
        },
        {
            TL = Vector(9, 2),
            Size = Vector(3, 2),
            Center = Vector(80, 60),
            Crack = "VerticalCrack",
            Adjacent = {3, 9, 8},
            Up = 3,
            Left = 9,
            Down = 8,
        },
        {
            TL = Vector(0, 5),
            Size = Vector(3, 1),
            Center = Vector(80, 40),
            Crack = "CornerCrack",
            Opposites = {Vertical = {4, 1}, Horizontal = {7, 8}},
            Adjacent = {4, 7},
            Up = 4,
            Right = 7,
        },
        {
            TL = Vector(4, 5),
            Size = Vector(4, 1),
            Center = Vector(100, 40),
            Crack = "HorizontalCrack",
            Adjacent = {6, 9, 8},
            Left = 6,
            Up = 9,
            Right = 8,
        },
        {
            TL = Vector(9, 5),
            Size = Vector(3, 1),
            Center = Vector(80, 40),
            Crack = "CornerCrack",
            Opposites = {Vertical = {5, 3}, Horizontal = {7, 6}},
            Adjacent = {5, 7},
            Left = 7,
            Up = 5,
        },
        { -- center segment
            TL = Vector(4, 2),
            Size = Vector(5, 3),
            Center = Vector(100, 60),
            NoFreeze = true,
            Adjacent = {2, 4, 5, 7},
            Left = 4,
            Up = 2,
            Right = 5,
            Down = 7,
        }
    }
end

ResetSegments()

local fastDisappearIceRock = {
    Name = "Ice Rock Particle",
    Anm2 = "gfx/grid/grid_rock.anm2",
    AnimationName = "rubble_alt",
    Spritesheet = "gfx/grid/revel1/glacier_rocks.png",
    Variants = 4,
    BaseLife = 10,
    FadeOutStart = 0.3,
    RotationSpeedMult = 0
}
local iceParticle = REVEL.ParticleType.FromTable(fastDisappearIceRock)

local sizesPre = {CornerCrack = Vector(100, 55), VerticalCrack = Vector(100, 80), HorizontalCrack = Vector(130, 60)}
local Sizes = {}
local Anims = {}
for anim, size in pairs(sizesPre) do
    Sizes[anim] = size
    Sizes[anim .. "Long"] = size
    Anims[#Anims + 1] = anim
    Anims[#Anims + 1] = anim .. "Long"
end

local function SpawnCrackParticles(eff, pos, anim)
    if eff then
        pos = eff.Position
        anim = eff:GetSprite():GetAnimation()
    end
    local size = Sizes[anim]

    for i = 1, 9 do
        local off = Vector(math.random(size.X), math.random(size.Y))
        local vel = (off - size / 2):Resized(math.random(3, 6))
        iceParticle:Spawn(REVEL.IceRockSystem, Vec3(pos + off, -5), Vec3(vel, -5))
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if REVEL.GetData(eff).ProngCrack then
        if eff:GetSprite():IsEventTriggered("Crack") then
            REVEL.sfx:Play(REVEL.SFX.ICE_CRACK, 1, 0, false, 1)
            SpawnCrackParticles(eff)
        end
    end
end, StageAPI.E.FloorEffect.V)

local function CrackSegment(seg, longCrack, noRemoveCrack)
    if type(seg) ~= "table" then
        seg = RoomSegments[seg]
    end

    local crack = seg.Crack
    if crack and longCrack then
        crack = crack .. "Long"
    end

    if not seg.CrackEffect and crack then
        seg.CrackEffect = StageAPI.SpawnFloorEffect(seg.RoomTLPos, Vector.Zero, nil, "gfx/bosses/revel1/prong/big_ice_crack.anm2", true)
        seg.CrackEffect:GetSprite():Play(crack, true)
        REVEL.GetData(seg.CrackEffect).ProngCrack = true
        REVEL.sfx:Play(REVEL.SFX.ICE_CRACK, 1.7, 0, false, 0.6)
        SpawnCrackParticles(seg.CrackEffect)
    end

    if crack and seg.CrackEffect:GetSprite():IsFinished(crack) then
        if not noRemoveCrack then
            seg.CrackEffect:Remove()
        end

        return true
    end
end

local function ForGridInSegment(seg, fn)
    if type(seg) ~= "table" then
        seg = RoomSegments[seg]
    end

    local width = REVEL.room:GetGridWidth()
    local tlX, tlY = seg.RoomTL.X, seg.RoomTL.Y
    for x = 0, seg.Size.X do
        for y = 0, seg.Size.Y do
            local setX, setY = tlX + x, tlY + y
            local index = REVEL.VectorToGrid(setX, setY, width)
            fn(index)
        end
    end

    if seg.CrackEffect then
        seg.CrackEffect:Remove()
        seg.CrackEffect = nil
    end
end

local function UpdateGrids()
    local rtype = StageAPI.GetCurrentRoomType()
    local grids = StageAPI.CurrentStage.RoomGfx[rtype].Grids

    StageAPI.ChangeGrids(grids)
end

local function SpawnBrokenSnowParticles(pos)
    for i = 1, math.random(1, 4) do
        local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, pos, RandomVector() * math.random(1,5), nil)
        REVEL.GetData(eff).NoGibOverride = true
        eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/snow_gibs.png")
        eff:GetSprite():LoadGraphics()
    end
end

local function BreakSnowBridgesInSegment(seg, noPitfall)
    local broke = false
    local brokeGrids = {}
    
    ForGridInSegment(seg, function(index)
        local brokenSnowTile = REVEL.Glacier.RemoveSnowTile(index)
        if brokenSnowTile then
            local grid = REVEL.room:GetGridEntity(index)
            if grid and grid.Desc.Type == GridEntityType.GRID_PIT and grid.State == PitState.PIT_BRIDGE then
                broke = true
                brokeGrids[index] = true
            end
            SpawnBrokenSnowParticles(REVEL.room:GetGridPosition(index))
        end
    end)

    for _, player in ipairs(REVEL.players) do
        if brokeGrids[REVEL.room:GetGridIndex(player.Position)] then
            REVEL.ZPos.StartPlayerPitfall(player:ToPlayer(), nil,
                REVEL.room:GetGridIndex(Isaac.GetFreeNearPosition(player.Position, 0))
            )
        end
    end

    for _, ent in ipairs(REVEL.roomEnemies) do
        if ent:Exists() and not ent:IsBoss() and brokeGrids[REVEL.room:GetGridIndex(ent.Position)] and not REVEL.ENT.BROTHER_BLOODY:isEnt(ent) then
            ent:Die()
        end
    end

    if broke then
        REVEL.sfx:Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.25, 0, false, 2)
    end
end

local function BreakSegment(seg, npc)
    local breakingGrids = {}
    local pitfallPlayers = true

    BreakSnowBridgesInSegment(seg, not pitfallPlayers)

    if not seg.Broken then
        SpawnCrackParticles(nil, seg.RoomTLPos, seg.Crack)

        ForGridInSegment(seg, function(index)
            breakingGrids[index] = true
            Isaac.GridSpawn(GridEntityType.GRID_PIT, 0, REVEL.room:GetGridPosition(index), true)
        end)

        for _, ent in ipairs(REVEL.roomEnemies) do
            if not ent:IsBoss() and breakingGrids[REVEL.room:GetGridIndex(ent.Position)] and not REVEL.ENT.BROTHER_BLOODY:isEnt(ent) then
                ent:Die()
            end
        end

        local hazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)
        for _, ent in ipairs(hazards) do
            if breakingGrids[REVEL.room:GetGridIndex(ent.Position)] then
                REVEL.ZPos.SetData(ent, {
                    ZPosition = 120,
                    ZVelocity = 10, 
                    Gravity = 1,
                    Bounce = 0,
                })
                REVEL.GetData(ent).HazardStart = ent.Position
                REVEL.GetData(ent).HazardTarget = Isaac.GetFreeNearPosition(npc:GetPlayerTarget().Position, 0)
                REVEL.GetData(ent).HazardTime = 0
                REVEL.GetData(ent).HazardFlightTime = REVEL.GetData(npc).bal.HazardFlightTime
                REVEL.GetData(ent).NoBreak = true

                ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                ent.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

                REVEL.ZPos.UpdateEntity(ent)
            end
        end

        for _, player in ipairs(REVEL.players) do
            if breakingGrids[REVEL.room:GetGridIndex(player.Position)] then
                REVEL.SpringPlayer(player)
            end
        end

        UpdateGrids()

        REVEL.sfx:Play(REVEL.SFX.ICE_BREAK_LARGE, 1, 0, false, 1)

        pitfallPlayers = false
    end

    seg.Broken = true
end

local function FreezeSegment(seg, updateGrids)
    if seg.GlowEffect then
        seg.GlowEffect:Remove()
        seg.GlowEffect = nil
    end

    ForGridInSegment(seg, function(index)
        REVEL.room:RemoveGridEntity(index, 0, false)

        if math.random() > 0.5 then
        -- local r = math.random(1, 3)
        -- for i = 1, r do
            local pos = REVEL.room:GetGridPosition(index) + RandomVector() * math.random(15, 30)
            local steam = REVEL.SpawnDecoration(pos, REVEL.VEC_UP * 4 + REVEL.VEC_RIGHT * (math.random() * 2 - 1),
                "Steam" .. math.random(1,3), "gfx/effects/revelcommon/steam.anm2", nil, 30)
            steam:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/blue_steam.png")
            steam:GetSprite():ReplaceSpritesheet(1, "gfx/effects/revel1/blue_steam.png")
            steam:GetSprite():LoadGraphics()
        end
    end)
    REVEL.UpdateRoomASAP()

    seg.Broken = false

    if updateGrids then
        REVEL.DelayFunction(UpdateGrids, 1, nil, true)
    end
end

local function RefreezeRoom(verifyState, force, segments, playSound)
    if playSound == nil then playSound = true end

    for _, segment in ipairs(segments or RoomSegments) do
        if not segment.NoFreeze or force then
            if segment.Broken then
                FreezeSegment(segment)
            elseif verifyState then
                local grid = REVEL.room:GetGridEntityFromPos(segment.CenterPos)
                if grid and grid.Desc.Type == GridEntityType.GRID_PIT then
                    FreezeSegment(segment)
                end
            end
        end
    end

    if playSound then
        REVEL.sfx:Play(REVEL.SFX.LOW_FREEZE, 1, 0, false, 1)
        -- REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 1.2, 0, false, 0.8)
    end

    REVEL.DelayFunction(UpdateGrids, 1, nil, true)
end

local function BreakAllSnowBridges()
    for segIndex, _ in ipairs(RoomSegments) do
        BreakSnowBridgesInSegment(segIndex)
    end
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom and currentRoom.PersistentData.SnowedTiles then
        for strIndex, _ in pairs(currentRoom.PersistentData.SnowedTiles) do
            local index = tonumber(strIndex)
            if REVEL.Glacier.RemoveSnowTile(strIndex) then
                SpawnBrokenSnowParticles(REVEL.room:GetGridPosition(index))
            end
        end
    end
end

local function SetSegmentPositions()
    local width = REVEL.room:GetGridWidth()
    local tl = REVEL.room:GetTopLeftPos()
    local tlInd = REVEL.room:GetGridIndex(tl)
    local tlX, tlY = REVEL.GridToVector(tlInd, width)
    for _, segment in ipairs(RoomSegments) do
        segment.RoomTL = segment.TL + Vector(tlX, tlY)
        segment.RoomTLPos = tl + segment.TL * 40
        segment.CenterPos = segment.RoomTLPos + segment.Center
        segment.CrackEffect = nil
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    local currentRoom = StageAPI.GetCurrentRoom()
    local isProng = currentRoom and (currentRoom.PersistentData.BossID == "Prong"
    or (currentRoom.IsExtraRoom and REVEL.ENT.PRONG:countInRoom() > 0))

    if isProng then
        SetSegmentPositions()
        RefreezeRoom(true, nil, nil, false)
    else
        for _, segment in ipairs(RoomSegments) do
            segment.CrackEffect = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    ResetSegments()
end)

local function GetNumUnbroken(segments)
    local numUnbroken = 0
    for _, seg in ipairs(segments or RoomSegments) do
        if not seg.Broken then
            numUnbroken = numUnbroken + 1
        end
    end
    return numUnbroken
end

local function JumpPosition(npc, segments, attack)
    local numBroken = 0
    for i, segment in ipairs(segments) do
        if segment.Broken then
            numBroken = numBroken + 1
        end
    end

    if numBroken == 0 then
        REVEL.DebugToString("No broken segments found, room loading error?")
        if REVEL.GetData(npc).IsChampion then
            BreakSegment(1, npc)
            BreakSegment(3, npc)
            BreakSegment(6, npc)
            BreakSegment(8, npc)
            numBroken = 4
        else
            BreakSegment(9, npc)
            numBroken = 1
        end
    end

    local jumpPositions = {}
    for i, segment in ipairs(segments) do
        if segment.Broken then
            local numUnbroken
            local valid
            for _, seg in ipairs(segment.Adjacent) do -- can only appear on spaces adjacent to non-broken spaces, so he's easy to hit
                if not segments[seg].Broken or attack == "Refreeze" or attack == "NorthernWind" then
                    if attack == "NorthernWind" then
                        numUnbroken = GetNumUnbroken(segments)
                    end
                    if not (attack == "NorthernWind" and numUnbroken > 2 and segments[seg].Broken) then
                        valid = true
                    end
                end
            end

            if attack == "Refreeze" and not segment.NoFreeze then
                valid = false
            end

            if attack == "NorthernWind" and segment.Crack ~= "CornerCrack" then
                valid = false
            end

            if valid and attack == "NorthernWind" then
                numUnbroken = numUnbroken or GetNumUnbroken(segments)
                if numUnbroken <= 2 then --if low unbrokens egments, pick one adjacent only to broken ones to give space
                    for _, adjIndex in ipairs(segment.Adjacent) do
                        if not segments[adjIndex].Broken then
                            valid = false
                            break
                        end
                    end
                end
            end

            if valid then
                if not segment.CenterPos then
                    SetSegmentPositions()
                end
                jumpPositions[#jumpPositions + 1] = {Pos = segment.CenterPos, Index = i}
            end
        end
    end

    if #jumpPositions > 0 then
        local currentSegment = math.random(1, #jumpPositions)
        npc.Position = jumpPositions[currentSegment].Pos
        REVEL.GetData(npc).CurrentPositionSegment = jumpPositions[currentSegment].Index
    else
        REVEL.DebugLog("Warning: no positions to jump to! Reloaded?\n", segments)
    end
end

local function IsInSegment(entityOrPos, seg)
    if type(seg) == "number" then seg = RoomSegments[seg] end

    return REVEL.IsPositionInRect(entityOrPos.Position or entityOrPos,
        seg.RoomTLPos,
        seg.RoomTLPos + seg.Center * 2
    )
end

local function GetSegmentAtPos(pos)
    for segIndex, seg in ipairs(RoomSegments) do
        if IsInSegment(pos, seg) then
            return segIndex
        end
    end
end

local function GetCurrentSegment(entity)
    local data = REVEL.GetData(entity)

    if data.CurrentPositionSegment then
        if IsInSegment(entity, data.CurrentPositionSegment) then
            return data.CurrentPositionSegment
        end
        for _, adjSeg in ipairs(RoomSegments[data.CurrentPositionSegment].Adjacent) do
            if IsInSegment(entity, adjSeg) then
                return adjSeg
            end
        end
    end
    return GetSegmentAtPos(entity.Position)
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.PRONG.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if not data.Init then
        data.IsChampion = REVEL.IsChampion(npc)

        if data.IsChampion then
            data.bal = REVEL.GetBossBalance(prongBalance, "Prongerina")
        else
            data.bal = REVEL.GetBossBalance(prongBalance, "Default")
        end

        npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
        REVEL.SetScaledBossHP(npc)

        if not data.IsChampion then
            for _, roomSegment in ipairs(RoomSegments) do
                roomSegment.Broken = false
            end

            RoomSegments[9].Broken = true
        else
            for i, roomSegment in ipairs(RoomSegments) do
                roomSegment.Broken = REVEL.includes(Corners, i)
                roomSegment.NoFreeze = roomSegment.Broken
            end

            RoomSegments[9].NoFreeze = false
        end

        data.RoomSegments = RoomSegments

        if data.bal.Sprite ~= "" then
            sprite:Load(data.bal.Sprite, true)
        end

        data.State = "Appear"

        data.Phase = 1
        data.AttackCooldown = data.bal.InitialAttackCooldown

        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.Visible = false
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        for _, worm in ipairs(REVEL.ENT.ICE_WORM:getInRoom()) do
            REVEL.GetData(worm).AllIce = true
        end

        for _, fly in ipairs(REVEL.ENT.CRYO_FLY:getInRoom()) do
            REVEL.GetData(fly).AllIce = true
        end

        -- if REVEL.room:GetGridCollisionAtPos(npc.Position) ~= GridCollisionClass.COLLISION_PIT then
            JumpPosition(npc, RoomSegments)
        -- end

        data.Init = true
    end

    if IsAnimOn(sprite, "Death") then
        npc.Velocity = Vector.Zero
        npc.HitPoints = 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if sprite:IsEventTriggered("Break") then
            REVEL.sfx:Play(REVEL.SFX.ICE_CRACK, 1, 0, false, 0.6)

            if not data.CrackCounter then
                REVEL.PlaySound(npc, data.bal.Sounds.Death1)
                data.CrackCounter = 1
            else
                data.CrackCounter = data.CrackCounter + 1
                if data.bal.Sounds["Death" .. data.CrackCounter] then
                    REVEL.PlaySound(npc, data.bal.Sounds["Death" .. data.CrackCounter])
                end
            end
        end

        if sprite:IsEventTriggered("Freeze") then
            RefreezeRoom(true, true)
        end

        if sprite:IsFinished("Death") then
            -- REVEL.SpawnDecoration(npc.Position, Vector.Zero, "Statue", sprite:GetFilename(), nil, nil, nil, nil, nil, 0)
            local s = REVEL.ENT.PRONG_STATUE:spawn(npc.Position, Vector.Zero, npc)

            if data.bal.Sprite ~= "" then
                s:GetSprite():Load(data.bal.Sprite, true)
            end

            s:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            s:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
            s:GetSprite():Play("Statue", true)
            s:GetSprite().FlipX = sprite.FlipX
            REVEL.GetData(s).Pos = npc.Position
            npc.Visible = false
            npc.SplatColor = REVEL.NO_COLOR
            npc:Die()
        end

        return
    end

    if data.StartedDeath then --interrupted death anim somehow
        npc:Die()
        return
    end

    if sprite:IsEventTriggered("Submerge") then
        npc.Visible = false
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if REVEL.MultiPlayingCheck(sprite, "JumpHori2", "JumpVert2") then
            REVEL.sfx:Play(REVEL.SFX.WATER_SPLASH_HEAVY, 1, 0, false, 1)
        else
            REVEL.sfx:Play(REVEL.SFX.WATER_SPLASH, 1, 0, false, 1)

            --Only trigger if not doing jump and crack, since there the position is different than the currentpositionsegment
            if data.CurrentPositionSegment then
                BreakSnowBridgesInSegment(data.CurrentPositionSegment)
                -- REVEL.DebugToConsole("test", data.CurrentPositionSegment)
            end
        end

        local e = Isaac.Spawn(1000, EffectVariant.WATER_SPLASH, 0, npc.Position, Vector.Zero, npc):ToEffect()
        e.SpriteScale = Vector.One * 1.7

        local r = math.random(12, 25)

        for i = 1, r do
            local v = RandomVector()
            local e = Isaac.Spawn(1000, EffectVariant.WATER_SPLASH, 1, npc.Position + v * math.random(10, 40), v * math.random(3, 8), npc)
        end
    end

    if sprite:IsEventTriggered("Emerge") and npc.Visible then
        REVEL.sfx:Play(REVEL.SFX.WATER_SPLASH, 1, 0, false, 1)

        local r = math.random(12, 25)

        for i = 1, r do
            local v = RandomVector()
            local e = Isaac.Spawn(1000, EffectVariant.WATER_SPLASH, 1, npc.Position + v * math.random(10, 40), v * math.random(3, 8), npc)
        end

        if data.CurrentPositionSegment then
            BreakSnowBridgesInSegment(data.CurrentPositionSegment)
            -- REVEL.DebugToConsole("test2", data.CurrentPositionSegment)
        end
    end

    if data.State ~= "FlopAndCrack" then
        npc.Velocity = Vector.Zero
    end

    if sprite:IsEventTriggered("Whistle") then
        REVEL.PlaySound(npc, data.bal.Sounds.Whistle)
    end

    if sprite:IsEventTriggered("HappyDuh") then
        REVEL.PlaySound(npc, data.bal.Sounds.Smile)
    end

    if sprite:IsEventTriggered("Land") then
        REVEL.PlaySound(data.bal.Sounds.LandJump)
    end

    if data.State == "Appear" then
        npc.Velocity = Vector.Zero

        if not data.Emerged then
            local emerge
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(REVEL.room:GetCenterPos()) < (75 + npc.Size + player.Size) ^ 2
                or player.Position:DistanceSquared(npc.Position) < (75 + npc.Size + player.Size) ^ 2 then
                    emerge = true
                    break
                end
            end

            if emerge then
                sprite:Play("Appear", true)
                data.Emerged = true
                npc.Visible = true
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end
        elseif sprite:IsFinished("Appear") then
            data.State = "Idle"
        end
    elseif data.State == "Idle" then
        local diving = sprite:IsPlaying("Dive") or sprite:IsPlaying("Dive2") or sprite:IsPlaying("TiredDive")
        local idle = sprite:IsPlaying("Idle") or sprite:IsPlaying("Idle2") or sprite:IsPlaying("Tired") or sprite:IsFinished("Idle") or sprite:IsFinished("Idle2") or sprite:IsFinished("Tired")
        if idle or diving then
            if sprite:IsFinished("Idle") then
                sprite:Play("Idle", true)
            elseif sprite:IsFinished("Idle2") then
                sprite:Play("Idle2", true)
            elseif sprite:IsFinished("Tired") then
                sprite:Play("Tired", true)
            end

            if data.IdleCooldown then
                data.IdleCooldown = data.IdleCooldown - 1
                if data.IdleCooldown <= 0 then
                    data.IdleCooldown = nil
                end
            elseif not diving then
                if sprite:IsPlaying("Idle") then
                    sprite:Play("Dive", true)
                elseif sprite:IsPlaying("Idle2") then
                    sprite:Play("Dive2", true)
                elseif sprite:IsPlaying("Tired") then
                    sprite:Play("TiredDive", true)
                end
            end
        elseif data.AttackCooldown then
            data.AttackCooldown = data.AttackCooldown - 1
            if data.AttackCooldown <= 0 then
                data.AttackCooldown = nil
            end
        else
            local phaseShifting
            if data.Phase < #data.bal.Phases then
                for i = data.Phase + 1, #data.bal.Phases do
                    if npc.HitPoints <= npc.MaxHitPoints * data.bal.Phases[i].Threshold then
                        data.Phase = i
                        if data.bal.Phases[i].TriggerSubCycle then
                            data.FlopAndCrackPath = nil
                            data.FlopCrackContinuingSegment = nil
                            phaseShifting = true
                            REVEL.JumpToCycle(data, 1, data.bal.Phases[i].TriggerSubCycle, 1, nil, nil, true)
                        end
                    end
                end
            end

            local curCycleSegment, isAttacking, attack, cooldown, changedCycleSegment

            if data.FlopCrackContinuingSegment and data.FlopAndCrackPath then
                curCycleSegment = data.FlopCrackContinuingSegment
                isAttacking = true
                attack = "FlopAndCrack"
                cooldown = 0
                changedCycleSegment = false
                REVEL.DebugToString("Prong | Continuing flop and crack:", data.FlopAndCrackPath)
            elseif not phaseShifting and REVEL.room:GetGridCollisionAtPos(npc:GetPlayerTarget().Position) ~= GridCollisionClass.COLLISION_NONE then
                isAttacking = true
                attack = "EmperorsHail"
                cooldown = 0
                curCycleSegment = {Visible = true}
            else
                curCycleSegment, isAttacking, attack, cooldown, changedCycleSegment = REVEL.ManageAttackCycle(data, data.bal, data.bal[data.bal.Phases[data.Phase].Cycle])
            end

            if isAttacking then
                data.State = attack

                JumpPosition(npc, RoomSegments, attack)

                if attack == "CoolFriend" then
                    sprite:Play("Spawn", true)
                elseif attack == "BalancingBlock" then
                    sprite:Play("Balance", true)
                elseif attack == "HighHail" then
                    sprite:Play("Stalactite", true)
                elseif attack == "EmperorsHail" then
                    data.AttackTimer = 0
                    sprite:Play("StalactiteStart", true)
                elseif attack == "FlopAndCrack" then
                    data.AllowKebab = data.bal.FlopAndCrackAllowKebab
                    if curCycleSegment.ResetFlopPath and not data.FlopCrackContinuingSegment then
                        data.FlopAndCrackPath = nil
                    end

                    if not data.FlopAndCrackPath then
                        local path = {}
                        local direction = math.random(0, 1)

                        local validCorners = Corners
                        if curCycleSegment.Safety then -- in order to ensure that the choice won't force the player to pick a random safe line, don't split the map
                            validCorners = {}
                            for _, corner in ipairs(Corners) do
                                local seg = RoomSegments[corner]
                                if not seg.Broken then
                                    local valid
                                    for _, segInd in ipairs(seg.Adjacent) do
                                        if RoomSegments[segInd].Broken then
                                            valid = true
                                            break
                                        end
                                    end

                                    if valid then
                                        validCorners[#validCorners + 1] = corner
                                    end
                                end
                            end
                        end

                        local corner = validCorners[math.random(1, #validCorners)]
                        path[#path + 1] = corner
                        local cdata = RoomSegments[corner]

                        if curCycleSegment.Safety or curCycleSegment.CheckAdjacentUnbroken then
                            if RoomSegments[cdata.Opposites.Horizontal[1]].Broken then
                                direction = 0
                            elseif RoomSegments[cdata.Opposites.Vertical[1]].Broken then
                                direction = 1
                            end
                        end

                        local segs
                        if direction == 1 then segs = cdata.Opposites.Horizontal else segs = cdata.Opposites.Vertical end
                        for _, seg in ipairs(segs) do
                            path[#path + 1] = seg
                        end

                        local doUShape = curCycleSegment.UShape

                        if curCycleSegment.UShapeIfMoreLeft and not doUShape then
                            local numUnbroken = 0
                            for _, idx in ipairs(MiddleSegments) do
                                local seg = RoomSegments[idx]
                                if not seg.Broken then
                                    numUnbroken = numUnbroken + 1
                                end
                            end

                            if numUnbroken > 2 then
                                doUShape = true
                            end
                        end

                        if curCycleSegment.LShape or doUShape then
                            local c2data = RoomSegments[path[#path]]
                            if direction == 1 then segs = c2data.Opposites.Vertical else segs = c2data.Opposites.Horizontal end
                            for _, seg in ipairs(segs) do
                                path[#path + 1] = seg
                            end

                            if doUShape then
                                local c3data = RoomSegments[path[#path]]
                                if direction == 1 then segs = c3data.Opposites.Horizontal else segs = c3data.Opposites.Vertical end
                                for _, seg in ipairs(segs) do
                                    path[#path + 1] = seg
                                end
                            end
                        elseif curCycleSegment.IIShape then --remove two parallel lines of ice at room opposites
                            local c2data = RoomSegments[path[#path]]
                            local first

                            if direction == 1 then first = c2data.Opposites.Vertical[#c2data.Opposites.Vertical] else first = c2data.Opposites.Horizontal[#c2data.Opposites.Horizontal] end
                            path[#path + 1] = first

                            local c3data = RoomSegments[first]
                            local segs
                            if direction == 1 then segs = c3data.Opposites.Horizontal else segs = c3data.Opposites.Vertical end
                            for _, seg in ipairs(segs) do
                                path[#path + 1] = seg
                            end

                            data.DoingIIShape = true
                        end

                        REVEL.DebugToString("Prong | crack path:", path)

                        data.FlopAndCrackPath = path
                        data.FlopCrackContinuingSegment = curCycleSegment
                    end
                elseif attack == "Kebab" then
                    if curCycleSegment.Visible then
                        sprite:Play("Kebab", true)
                    elseif curCycleSegment.CrackKebab then
                        local intactSegments = {}
                        for _, segment in ipairs(RoomSegments) do
                            if (not curCycleSegment.AvoidCorner or segment.Crack ~= "CornerCrack") and not segment.Broken then
                                intactSegments[#intactSegments + 1] = segment
                            end
                        end

                        local destroySegment = intactSegments[math.random(1, #intactSegments)]
                        data.CrackKebab = {TargetPos = destroySegment.CenterPos, Segment = destroySegment}
                    end
                elseif attack == "Refreeze" then
                    data.RefreezeAll = curCycleSegment.RefreezeAll
                    sprite:Play("Refreeze", true)
                elseif attack == "NorthernWind" then
                    local dir, dirString

                    if curCycleSegment.WindMoving then
                        data.WindMoving = true

                        local currentSeg = RoomSegments[data.CurrentPositionSegment]

                        local valid = {}
                        local bestShootSide

                        -- Valid directions are ones where there are 2 broken segments, aka a full row of broken segments
                        -- Also it should move alongside the unbroken ones, so at least 2/3 of the adjacent segments should be unbroken
                        for checkDir = 0, 3 do
                            local checkDirStr = REVEL.dirToString[checkDir]

                            local row = {data.CurrentPositionSegment}

                            if currentSeg[checkDirStr] and RoomSegments[currentSeg[checkDirStr]].Broken then
                                local next = RoomSegments[currentSeg[checkDirStr]]
                                row[#row + 1] = currentSeg[checkDirStr]
                                if next[checkDirStr] and RoomSegments[next[checkDirStr]].Broken then
                                    row[#row + 1] = next[checkDirStr]
                                end
                            end

                            local numOneSide, numOtherSide = 0, 0

                            local perpDir1, perpDir2 = (checkDir + 1) % 4, (checkDir - 1) % 4

                            if #row >= 3 then --full broken segment row
                                for _, rowSeg in ipairs(row) do
                                    local adjDir1, adjDir2 = RoomSegments[rowSeg][REVEL.dirToString[perpDir1]], RoomSegments[rowSeg][REVEL.dirToString[perpDir2]]
                                    if adjDir1 and not RoomSegments[adjDir1].Broken then
                                        numOneSide = numOneSide + 1
                                    end
                                    if adjDir2 and not RoomSegments[adjDir2].Broken then
                                        numOtherSide = numOtherSide + 1
                                    end
                                end
                            end

                            if numOneSide >= 2 or numOtherSide >= 2 then
                                valid[#valid + 1] = checkDir
                                bestShootSide = numOneSide > numOtherSide and perpDir1 or perpDir2
                            end
                        end

                        if #valid > 0 then
                            local moveDir = REVEL.randomFrom(valid)
                            dir = bestShootSide

                            data.BlowMoveDir = moveDir
                            data.BlowMoveVel = REVEL.dirToVel[moveDir] * data.bal.NorthernWindMoveSpeed
                            data.BlowStartPos = npc.Position
                        else
                            data.WindMoving = nil
                        end
                    end
                    if not data.WindMoving then
                        dir = REVEL.GetDirectionFromVelocity(npc:GetPlayerTarget().Position - npc.Position)
                        data.BlowDuration = REVEL.GetFromMinMax(data.bal.NorthernWindDuration)
                    end

                    dirString = dir % 2 == 0 and "Hori" or REVEL.dirToString[dir]
                    sprite:Play("Blow" .. dirString .. "Start", true)
                    sprite.FlipX = dir == Direction.RIGHT

                    data.BlowDir = dir
                    data.BlowDirString = dirString
                end

                data.InvincibleWormSpawn = curCycleSegment.InvincibleWormSpawn

                if curCycleSegment.Visible then
                    npc.Visible = true
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                end

                data.AttackCooldown = cooldown

                if curCycleSegment.IdleCooldownByAttack then
                    data.IdleCooldown = curCycleSegment.IdleCooldownByAttack[attack] or curCycleSegment.IdleCooldown
                else
                    data.IdleCooldown = curCycleSegment.IdleCooldown
                end

                if type(data.IdleCooldown) == "table" then
                    data.IdleCooldown = math.random(data.IdleCooldown.Min, data.IdleCooldown.Max)
                end
            end
        end
    elseif data.State == "CoolFriend" then
        if sprite:IsEventTriggered("Spawn") then
            local numToSpawn = REVEL.GetFromMinMax(data.bal.CoolFriendNumSpawned)
            for i = 1, numToSpawn do
                local toSpawn = data.bal.CoolFriendSpawnedEntity.id and data.bal.CoolFriendSpawnedEntity or REVEL.randomFrom(data.bal.CoolFriendSpawnedEntity)

                if data.InvincibleWormSpawn then
                    toSpawn = REVEL.ENT.ICE_WORM
                end

                if REVEL.ENT.ICE_WORM:isEnt(toSpawn) then
                    local worm = toSpawn:spawn(npc:GetPlayerTarget().Position, Vector.Zero, npc)
                    REVEL.GetData(worm).AllIce = true
                    worm:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    worm:GetSprite():Play("Arise", true)
                    REVEL.GetData(worm).State = "Arise"
                    -- REVEL.sfx:Play(REVEL.SFX.ICE_WORM_BOUNCE, 1.3, 0, false, 1.1)
                    if data.InvincibleWormSpawn then
                        REVEL.GetData(worm).InvulnerableWithEntity = npc
                        data.InvincibleWormSpawn = nil
                    end
                else
                    local toCenter = REVEL.room:GetCenterPos() - npc.Position
                    local dir = math.random() < 0.5 and REVEL.GetXVector(toCenter) or REVEL.GetYVector(toCenter)
                    local ent = toSpawn:spawn(npc.Position + dir:Resized(npc.Size + 40), Vector.Zero, npc)
                    REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
                end
            end
        end

        if sprite:IsFinished("Spawn") then
            sprite:Play("Idle", true)
            data.State = "Idle"
        end
    elseif data.State == "BalancingBlock" then
        if not data.IceHazard then
            local hazardType = data.bal.IceHazardVariants[math.random(1, #data.bal.IceHazardVariants)]
            local hazard = hazardType:spawn(npc.Position + Vector(0, 1), Vector.Zero, npc):ToNPC()
            hazard:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            hazard.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            hazard.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            REVEL.GetData(hazard).NoBreak = true

            REVEL.ZPos.SetData(hazard, {
                ZPosition = 125, 
                ZVelocity = 5, 
                Gravity = 0.5,
                Bounce = 0,
            })
            REVEL.ZPos.UpdateEntity(hazard)
            data.IceHazard = hazard
        elseif sprite:WasEventTriggered("Catch") and not sprite:WasEventTriggered("Drop") then
            local hsprite = data.IceHazard:GetSprite()
            if not data.HazardWobbleTime then
                data.HazardWobbleTime = 0
                data.HazardWobbleStart = 0
                data.HazardWobbleIntensity = data.bal.HazardWobbleIntensity
                data.HazardWobbleDirection = math.random(0, 1)
                if data.HazardWobbleDirection == 0 then
                    data.HazardWobbleDirection = -1
                end
            end

            data.HazardWobbleTime = data.HazardWobbleTime + 1
            hsprite.Rotation = REVEL.Lerp(data.HazardWobbleStart, data.HazardWobbleIntensity * data.HazardWobbleDirection, data.HazardWobbleTime / data.bal.HazardWobbleTime)
            if data.HazardWobbleTime >= data.bal.HazardWobbleTime then
                data.HazardWobbleTime = 0
                data.HazardWobbleStart = hsprite.Rotation
                data.HazardWobbleDirection = data.HazardWobbleDirection * -1
                data.HazardWobbleIntensity = data.HazardWobbleIntensity * data.bal.HazardWobbleSlope
            end

            REVEL.ZPos.SetData(data.IceHazard, {
                ZPosition = 160, 
                ZVelocity = 0, 
                Gravity = 0,
                Bounce = 0,
            })
        elseif sprite:IsEventTriggered("Drop") then
            data.IceHazard:GetSprite().Rotation = 0
            data.HazardWobbleTime = nil
            REVEL.ZPos.SetData(data.IceHazard, {
                ZPosition = 160, 
                ZVelocity = 0, 
                Gravity = 0.5,
                Bounce = 0,
            })
        elseif sprite:IsEventTriggered("Spawn") then
            REVEL.ZPos.SetData(data.IceHazard, {
                ZPosition = 120, 
                ZVelocity = 10, 
                Gravity = 1,
                Bounce = 0,
            })
            REVEL.GetData(data.IceHazard).HazardStart = data.IceHazard.Position
            REVEL.GetData(data.IceHazard).HazardTarget = Isaac.GetFreeNearPosition(npc:GetPlayerTarget().Position, 0)
            REVEL.GetData(data.IceHazard).HazardTime = 0
            REVEL.GetData(data.IceHazard).HazardFlightTime = data.bal.HazardFlightTime
            REVEL.PlaySound(npc, data.bal.Sounds.Throw)
        end

        if sprite:IsFinished("Balance") then
            sprite:Play("Idle", true)
        end

        if sprite:IsFinished("Idle") then
            sprite:Play("Idle", true)

            if not data.HazardTime then
                data.IceHazard = nil
                data.State = "Idle"
            end
        end
    elseif data.State == "HighHail" then
        if sprite:IsEventTriggered("Freeze") then
            if not data.bal.HighHailUseBomb then
                local stalactite = REVEL.ENT.STALACTITE:spawn(npc:GetPlayerTarget().Position, Vector.Zero, npc):ToNPC()
                stalactite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                stalactite.State = 3
                stalactite.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                stalactite.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                REVEL.GetData(stalactite).type = math.random(1, 3)
                REVEL.GetData(stalactite).DontShootEnd = true
                stalactite:GetSprite():Play("Freeze"..REVEL.GetData(stalactite).type, true)
                REVEL.GetData(stalactite).init = true
                REVEL.SpawnMeltEffect(stalactite.Position + REVEL.VEC_UP * 60, false)
            else
                local bomb = REVEL.ENT.PRONG_ICE_BOMB:spawn(npc:GetPlayerTarget().Position, Vector.Zero, npc):ToNPC()
                ---@cast bomb EntityNPC
                bomb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                bomb:GetSprite():Play("Fall" .. math.random(1, 3), true)

                local target = Isaac.Spawn(1000, EffectVariant.TARGET, 0, bomb.Position, Vector.Zero, bomb)
                REVEL.GetData(bomb).Target = target

                REVEL.SpawnMeltEffect(bomb.Position + REVEL.VEC_UP * 60, false)
            end

            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 1.2, 0, false, 0.8)
            REVEL.PlaySound(npc, data.bal.Sounds.Telekinesis)
        end

        if sprite:IsEventTriggered("Drop") then
            REVEL.sfx:Stop(data.bal.Sounds.Telekinesis.Sound)
            REVEL.PlaySound(npc, data.bal.Sounds.TelekinesisEnd)
        end

        if sprite:IsFinished("Stalactite") then
            data.State = "Idle"
        end
    elseif data.State == "EmperorsHail" then -- try flying now, nerds.
        data.StalactiteHailTimer = data.StalactiteHailTimer or 8
        data.StalactiteHailTimer = data.StalactiteHailTimer - 1
        data.AttackTimer = data.AttackTimer + 1

        if sprite:IsEventTriggered("Freeze") then
            REVEL.PlaySound(npc, data.bal.Sounds.Telekinesis)
        end

        if sprite:IsFinished("StalactiteStart") or sprite:IsFinished("StalactiteLoop") then
            sprite:Play("StalactiteLoop", true)
        end

        if (sprite:WasEventTriggered("Freeze") or sprite:IsPlaying("StalactiteLoop")) and data.StalactiteHailTimer <= 0 then
            if not data.bal.HighHailUseBomb then
                local stalactite = REVEL.ENT.STALACTITE:spawn(npc:GetPlayerTarget().Position, Vector.Zero, npc):ToNPC()
                stalactite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                stalactite.State = 3
                stalactite.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                stalactite.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                REVEL.GetData(stalactite).type = math.random(1, 3)
                REVEL.GetData(stalactite).DontShootEnd = true
                stalactite:GetSprite():Play("Freeze"..REVEL.GetData(stalactite).type, true)
                REVEL.GetData(stalactite).init = true
                REVEL.SpawnMeltEffect(stalactite.Position + REVEL.VEC_UP * 60, false)
            else
                local bomb = REVEL.ENT.PRONG_ICE_BOMB:spawn(npc:GetPlayerTarget().Position, Vector.Zero, npc):ToNPC()
                bomb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                bomb:GetSprite():Play("Fall" .. math.random(1, 3), true)

                local target = Isaac.Spawn(1000, EffectVariant.TARGET, 0, bomb.Position, Vector.Zero, bomb)
                REVEL.GetData(bomb).Target = target

                REVEL.SpawnMeltEffect(bomb.Position + REVEL.VEC_UP * 60, false)
            end

            data.StalactiteHailTimer = nil
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 1.2, 0, false, 0.8)
        end

        if sprite:IsPlaying("StalactiteLoop") and (REVEL.room:GetGridCollisionAtPos(npc:GetPlayerTarget().Position) == GridCollisionClass.COLLISION_NONE or data.AttackTimer > 150) then
            sprite:Play("StalactiteEnd", true)
        end

        if sprite:IsEventTriggered("Drop") then
            REVEL.sfx:Stop(data.bal.Sounds.Telekinesis.Sound)
            REVEL.PlaySound(npc, data.bal.Sounds.TelekinesisEnd)
        end

        if sprite:IsFinished("StalactiteEnd") then
            data.State = "Idle"
        end
    elseif data.State == "Kebab" then
        local cutShort
        if data.CrackKebab then
            if not data.DeliciousWorm or not data.DeliciousWorm:Exists() then
                local iceWorms = REVEL.ENT.ICE_WORM:getInRoom()
                if #iceWorms > 0 then
                    data.DeliciousWorm = iceWorms[math.random(1, #iceWorms)]
                    REVEL.GetData(data.DeliciousWorm).InvulnerableWithEntity = npc
                else
                    cutShort = true
                end
            end

            if not cutShort then
                REVEL.GetData(data.DeliciousWorm).ForceNextPosition = data.CrackKebab.TargetPos

                if data.DeliciousWorm.Position:DistanceSquared(data.CrackKebab.TargetPos) < 40 ^ 2 then
                    if CrackSegment(data.CrackKebab.Segment, true) then
                        BreakSegment(data.CrackKebab.Segment, npc)
                        npc.Position = data.CrackKebab.TargetPos
                        data.CurrentPositionSegment = data.CrackKebab.Segment
                        data.DeliciousWorm = nil
                        data.CrackKebab = nil
                        sprite:Play("Kebab", true)
                        npc.Visible = true
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            if not data.FirstShoot then
                npc.HitPoints = math.min(npc.HitPoints + npc.MaxHitPoints * data.bal.KebabHeal, npc.MaxHitPoints)
                REVEL.PlaySound(npc, data.bal.Sounds.Gulp)

                data.FirstShoot = true
            else
                if not data.SecondShoot then
                    REVEL.PlaySound(npc, data.bal.Sounds.Burp)
                    data.SecondShoot = true
                end

                REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)

                local target = npc:GetPlayerTarget()

                data.FirstTargetPos = data.FirstTargetPos or target.Position
                local targetPos = REVEL.Lerp(data.FirstTargetPos, target.Position, 0.25)

                local randomRot = math.random(0, data.bal.KebabRNG * 2) - data.bal.KebabRNG

                local bones = {}
                local bonesNum = 0

                repeat
                    local i = math.random(1, 3) - 2
                    if not bones[i] then
                        bones[i] = true
                        bonesNum = bonesNum + 1
                    end
                until bonesNum >= data.bal.KebabBoneNum

                for i = -1, 1 do
                    local pos = npc.Position
                    local vel
                    if bones[i] then
                        vel = (targetPos - npc.Position):Resized(data.bal.KebabBoneSpeed):Rotated((i * data.bal.KebabSpread) + randomRot)
                    else
                        vel = (targetPos - npc.Position):Resized(data.bal.KebabSpeed):Rotated((i * data.bal.KebabSpread) + randomRot)
                    end
                    if i == 0 then
                        pos = pos + vel * 4
                    end

                    local p
                    if bones[i] then
                        p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_BONE, 0, pos, vel, npc):ToProjectile()
                    else
                        p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, pos, vel, npc):ToProjectile()
                        p.Acceleration = data.bal.KebabBoneAccel
                    end
                    p.FallingSpeed = -1.5
                end
            end
        end

        if sprite:IsFinished("Kebab") or cutShort then
            data.FirstShoot = nil
            data.SecondShoot = nil
            data.DeliciousWorm = nil
            data.CrackKebab = nil
            data.FirstTargetPos = nil

            if not cutShort then
                sprite:Play("Idle2", true)
            end

            data.State = "Idle"
        end
    elseif data.State == "FlopAndCrack" then
        local first, second, third = RoomSegments[data.FlopAndCrackPath[1]], RoomSegments[data.FlopAndCrackPath[2]], RoomSegments[data.FlopAndCrackPath[3]]
        local firstPos, secondPos, thirdPos = first.CenterPos, second.CenterPos, third.CenterPos

        local kebabing
        if not data.Hopping then
            if not first.Broken then
                if data.AllowKebab then
                    local iceWorms = REVEL.ENT.ICE_WORM:getInRoom()
                    if #iceWorms > 0 then
                        kebabing = true
                    end
                end

                if not kebabing then
                    if CrackSegment(first, true) then
                        BreakSegment(first, npc)
                    end
                end
            end

            if first.Broken then
                if first.Opposites.Horizontal[1] == third.Opposites.Horizontal[1] then
                    sprite.FlipX = thirdPos.X > firstPos.X
                    sprite:Play("JumpHori1", true)
                else
                    sprite:Play("JumpVert1", true)
                end

                npc.Position = firstPos
                data.CurrentPositionSegment = data.FlopAndCrackPath[1]
                npc.Visible = true
                data.Hopping = true
            end
        end

        if sprite:IsPlaying("JumpHori1") or sprite:IsPlaying("JumpVert1") then
            if sprite:IsEventTriggered("Emerge") and second.Broken then
                FreezeSegment(second, true)
            end

            if sprite:IsEventTriggered("Land") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                CrackSegment(second)
            end

            if not sprite:WasEventTriggered("Land") then
                npc.Velocity = REVEL.Lerp(firstPos, secondPos, sprite:GetFrame() / data.bal.FirstJumpLength) - npc.Position
            else
                npc.Velocity = Vector.Zero
            end
        elseif sprite:IsFinished("JumpHori1") or sprite:IsFinished("JumpVert1") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            BreakSegment(second, npc)
            if sprite:IsFinished("JumpHori1") then
                sprite:Play("JumpHori2", true)
            elseif sprite:IsFinished("JumpVert1") then
                sprite:Play("JumpVert2", true)
            end
        elseif sprite:IsPlaying("JumpHori2") or sprite:IsPlaying("JumpVert2") then
            if sprite:IsEventTriggered("Break") then
                BreakSegment(third, npc)
                BreakAllSnowBridges()
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                REVEL.game:ShakeScreen(10)
            end

            if not sprite:WasEventTriggered("Break") then
                npc.Velocity = REVEL.Lerp(secondPos, thirdPos, sprite:GetFrame() / data.bal.FirstJumpLength) - npc.Position
            else
                npc.Velocity = Vector.Zero
            end
        else
            npc.Velocity = Vector.Zero
        end

        if kebabing then
            data.State = "Idle"
            data.CrackKebab = {TargetPos = firstPos, Segment = first}

            REVEL.SetCurrentCycleRepeats(data) -- reset repeats and add kebab as a subcycle so that it will be the next attack and then come right back to this.
            REVEL.AddToCycle(data, "CrackKebab", 1)
        elseif sprite:IsFinished("JumpHori2") or sprite:IsFinished("JumpVert2") then
            sprite.FlipX = false
            table.remove(data.FlopAndCrackPath, 1)
            table.remove(data.FlopAndCrackPath, 1)

            if data.DoingIIShape then
                -- landing point and starting point of next do not coincide, remove landing point too
                table.remove(data.FlopAndCrackPath, 1)
                data.DoingIIShape = nil
            end

            if #data.FlopAndCrackPath < 3 then
                if #data.FlopAndCrackPath > 0 then
                    REVEL.DebugToString(("Prong | Jump path left to do but less than 3 points (%d), stopping early")
                        :format(#data.FlopAndCrackPath))
                end
                data.FlopAndCrackPath = nil
                data.FlopCrackContinuingSegment = nil
            end

            data.Hopping = nil
            data.State = "Idle"
        end
    elseif data.State == "Refreeze" then
        if sprite:IsEventTriggered("SoundStart") then
            if sprite:WasEventTriggered("Freeze") then
                REVEL.PlaySound(npc, data.bal.Sounds.Tired)
            else
                REVEL.PlaySound(npc, data.bal.Sounds.Refreeze1)
            end
        end

        if sprite:IsEventTriggered("FreezeStart") then
            local freezeSegs = {}

            if data.RefreezeAll then
                local curSeg
                for _, segment in ipairs(RoomSegments) do
                    if not segment.NoFreeze then
                        freezeSegs[#freezeSegs + 1] = segment
                    end
                end
            else
                local curSeg
                for _, segment in ipairs(RoomSegments) do
                    if segment.Crack and not segment.Broken then
                        curSeg = segment
                    end
                end

                if curSeg.Crack ~= "CornerCrack" then
                    local closeCorners = {}
                    local closeCornersNoFreeze = {}
                    for _, segInd in ipairs(curSeg.Adjacent) do
                        if RoomSegments[segInd].Crack == "CornerCrack" then
                            if not RoomSegments[segInd].NoFreeze then
                                closeCorners[#closeCorners + 1] = RoomSegments[segInd]
                            else
                                closeCornersNoFreeze[#closeCornersNoFreeze + 1] = RoomSegments[segInd]
                            end
                        end
                    end

                    if #closeCorners > 0 then
                        curSeg = closeCorners[math.random(1, #closeCorners)]
                        freezeSegs[#freezeSegs + 1] = curSeg
                    elseif #closeCornersNoFreeze > 0 then
                        curSeg = closeCornersNoFreeze[math.random(1, #closeCornersNoFreeze)]
                    end
                end

                for k, segInds in pairs(curSeg.Opposites) do
                    for _, segInd in ipairs(segInds) do
                        if not RoomSegments[segInd].NoFreeze then
                            freezeSegs[#freezeSegs + 1] = RoomSegments[segInd]
                        end
                    end
                end
            end

            for _, seg in pairs(freezeSegs) do
                if seg.Broken then
                    seg.GlowEffect = REVEL.SpawnDecoration(seg.RoomTLPos, Vector.Zero, seg.Crack, "gfx/bosses/revel1/prong/pit_refreeze_glow.anm2", nil, nil, nil, nil, nil, nil, false)
                end
            end

            data.FreezeSegs = freezeSegs
        end

        if sprite:IsEventTriggered("Freeze") then
            REVEL.sfx:Stop(data.bal.Sounds.Refreeze1.Sound)
            REVEL.PlaySound(npc, data.bal.Sounds.Refreeze2)
            RefreezeRoom(nil, nil, data.FreezeSegs)
            data.FreezeSegs = nil
        end

        if sprite:IsFinished("Refreeze") then
            data.State = "Idle"
            sprite:Play("Tired", true)
        end

    elseif data.State == "NorthernWind" then
        if sprite:IsFinished("Blow" .. data.BlowDirString .. "Start") then
            sprite:Play("Blow" .. data.BlowDirString, true)
        end

        data.Blowing = sprite:WasEventTriggered("BlowStart") or sprite:IsPlaying("Blow" .. data.BlowDirString) or (sprite:IsPlaying("Blow" .. data.BlowDirString .. "End") and not sprite:WasEventTriggered("BlowEnd"))

        if sprite:IsEventTriggered("BlowStart") then
            REVEL.EnableWindSound(npc, true, 1.5)
        end
        if sprite:IsEventTriggered("BlowEnd") then
            REVEL.DisableWindSound(npc)
        end
        if sprite:IsEventTriggered("SoundStart") then
            REVEL.PlaySound(npc, data.bal.Sounds.BreatheIn)
        end

        if data.Blowing then
            local posStartGfx = npc.Position + data.bal.NorthernWindOffsets[data.BlowDir]
            local dirVec = REVEL.dirToVel[data.BlowDir]
            local currentSeg = GetCurrentSegment(npc)
            local ended = false

            if not data.WindMoving then
                --If prong stays still, affect an entire segment at once
                local affectedSegments =  {}
                for segIndex, seg in ipairs(RoomSegments) do
                    if data.BlowDir % 2 == 0 and seg.TL.Y == RoomSegments[currentSeg].TL.Y
                    or data.BlowDir % 2 == 1 and seg.TL.X == RoomSegments[currentSeg].TL.X then
                        affectedSegments[segIndex] = true
                    end
                end

                local checkSegment = currentSeg
                local checked = {}
                local lastSegInDirection

                repeat
                    if RoomSegments[checkSegment][REVEL.dirToString[data.BlowDir]] then
                        checkSegment = RoomSegments[checkSegment][REVEL.dirToString[data.BlowDir]]
                    else
                        lastSegInDirection = checkSegment
                    end
                until lastSegInDirection

                for _, player in ipairs(REVEL.players) do
                    local playerSeg = GetCurrentSegment(player)
                    if affectedSegments[playerSeg] 
                    and not REVEL.GetData(player).TotalFrozen 
                    and not REVEL.GetData(player).FrozenPitFalling 
                    and REVEL.Glacier.CheckIce(player)
                    then
                        REVEL.Glacier.TotalFreezePlayer(player, data.BlowDir, 8, nil, true, false, true)

                        for _, adjSeg in pairs(RoomSegments[lastSegInDirection].Adjacent) do
                            if not affectedSegments[adjSeg] then
                                REVEL.GetData(player).PitfallForceResurfacePosition = REVEL.Lerp(RoomSegments[adjSeg].CenterPos, RoomSegments[playerSeg].CenterPos, 0.33)
                                break
                            end
                        end
                    end
                end

                local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)

                for _, hazard in pairs(iceHazards) do
                    local hazardSeg = GetCurrentSegment(hazard)
                    if affectedSegments[hazardSeg] then
                        hazard.Velocity = hazard.Velocity + (hazard.Position - npc.Position):Resized(5)
                    end
                end
            else
                if not IsAnimOn(sprite, "Blow" .. data.BlowDirString .. "End") then
                    npc.Velocity = data.BlowMoveVel

                    local checkCollPos = npc.Position + data.BlowMoveVel:Resized(npc.Size + 70)

                    data.CurrentPositionSegment = GetCurrentSegment(npc)

                    if not REVEL.room:IsPositionInRoom(checkCollPos, 20) then
                        ended = true
                    else
                        local checkSeg = GetSegmentAtPos(checkCollPos)
                        if checkSeg and not RoomSegments[checkSeg].Broken then
                            ended = true
                        end

                        local width = (data.BlowMoveDir % 2 == 0 and REVEL.room:GetGridWidth() or REVEL.room:GetGridHeight()) * 40

                        if not ended and data.BlowStartPos:DistanceSquared(npc.Position) > (width * data.bal.NorthernWindMoveLimit) ^ 2 then
                            ended = true
                        end
                    end
                else
                    npc.Velocity = npc.Velocity * 0.8
                end

                --affect 3 tiles high area for hori, 4 tiles wide for vert
                local affectedAreaTL, affectedAreaBR
                local tl, br = REVEL.GetRoomCorners()

                if data.BlowDir % 2 == 0 then --hori
                    affectedAreaTL = Vector(tl.X, posStartGfx.Y - data.bal.NorthernWindHoriHeight / 2)
                    affectedAreaBR = Vector(br.X, posStartGfx.Y + data.bal.NorthernWindHoriHeight / 2)
                else
                    affectedAreaTL = Vector(posStartGfx.X - data.bal.NorthernWindVertWidth / 2, tl.Y)
                    affectedAreaBR = Vector(posStartGfx.X + data.bal.NorthernWindVertWidth / 2, br.Y)
                end

                for _, player in ipairs(REVEL.players) do
                    if REVEL.IsPositionInRect(player.Position, affectedAreaTL, affectedAreaBR) then
                        if not REVEL.GetData(player).TotalFrozen and not REVEL.GetData(player).FrozenPitFalling then
                            if REVEL.Glacier.CheckIce(player) then
                                REVEL.Glacier.TotalFreezePlayer(player, data.BlowDir, 8, nil, true, false, true)
                            end
                        else
                            REVEL.GetData(player).TFWaitFrameForResurface = player.FrameCount + 5 --wait resurfacing until prong has passed the area
                        end
                    end
                end

                local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)

                for _, hazard in pairs(iceHazards) do
                    if REVEL.IsPositionInRect(hazard.Position, affectedAreaTL, affectedAreaBR) then
                        hazard.Velocity = hazard.Velocity + (hazard.Position - npc.Position):Resized(5)
                    end
                end

                if npc.FrameCount % 5 == 0 then
                    BreakSnowBridgesInSegment(data.CurrentPositionSegment)
                end
            end

            if math.random(2) == 1 then
                local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, posStartGfx + dirVec:Rotated(90) * math.random(-40, 40), dirVec * math.random(8, 16), npc)
                snowp:GetSprite():Play("Fade", true)
                -- snowp:GetSprite().Offset = Vector(0,-25)
                REVEL.GetData(snowp).Rot = math.random() * 20 - 10
            end

            if data.BlowDuration then
                data.BlowDuration = data.BlowDuration - 1
                ended = data.BlowDuration <= 0
            end
            if ended and not IsAnimOn(sprite, "Blow" .. data.BlowDirString .. "End") then
                sprite:Play("Blow" .. data.BlowDirString .. "End", true)
            end
        end

        if sprite:IsFinished("Blow" .. data.BlowDirString .. "End") then
            sprite:Play("Dive", true)
        end
        if sprite:IsFinished("Dive") then
            data.State = "Idle"
            data.BlowDir = nil
            data.BlowDirString = nil
            data.BlowDuration = nil
            data.Blowing = nil
            sprite.FlipX = false
        end
    end
end, REVEL.ENT.PRONG.id)

REVEL.AddDeathEventsCallback(function(npc)
    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
    npc.Visible = true
    data.Death = true
    REVEL.DisableWindSound(npc)
    if data.IceHazard then
        data.IceHazard:Die()
    end
end,
function (npc, triggeredEventThisFrame)
    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
    if IsAnimOn(sprite, "Death") then
        local justTriggered
        if sprite:IsEventTriggered("Break") and not triggeredEventThisFrame then
            REVEL.sfx:Play(REVEL.SFX.ICE_CRACK, 1, 0, false, 0.6)
            justTriggered = true

            if not data.CrackCounter then
                REVEL.PlaySound(npc, data.bal.Sounds.Death1)
                data.CrackCounter = 1
            else
                data.CrackCounter = data.CrackCounter + 1
                if data.bal.Sounds["Death" .. data.CrackCounter] then
                    REVEL.PlaySound(npc, data.bal.Sounds["Death" .. data.CrackCounter])
                end
            end
        end

        if sprite:IsEventTriggered("Freeze") and not triggeredEventThisFrame then
            RefreezeRoom(true, true)
            justTriggered = true
        end

        if sprite:IsFinished("Death") and not triggeredEventThisFrame then
            justTriggered = true

            -- REVEL.SpawnDecoration(npc.Position, Vector.Zero, "Statue", sprite:GetFilename(), nil, nil, nil, nil, nil, 0)
            local s = REVEL.ENT.PRONG_STATUE:spawn(npc.Position, Vector.Zero, npc)

            if data.bal.Sprite ~= "" then
                s:GetSprite():Load(data.bal.Sprite, true)
            end

            s:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            s:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
            s:GetSprite():Play("Statue", true)
            s:GetSprite().FlipX = sprite.FlipX
            REVEL.GetData(s).Pos = npc.Position
            npc.Visible = false
            npc.SplatColor = REVEL.NO_COLOR
            npc:Die()
        end
        return justTriggered
    end
end, REVEL.ENT.PRONG.id, REVEL.ENT.PRONG.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flag)
    if REVEL.ENT.PRONG:isEnt(ent) and REVEL.GetData(ent).State == "Appear" then
        local dmgReduction = amount * 0.8
		ent.HitPoints = math.min(ent.HitPoints + dmgReduction, ent.MaxHitPoints)
    end
end, REVEL.ENT.PRONG.id)

local windAnimSpeed = 1.3
local windBaseAlpha = 0.75
local windScale = 1.5

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
        ID = "Prong_WindSprite" .. i,
        Anm2 = "gfx/effects/revel1/icewind_laser_offset.anm2",
        Animation = animation,
        Color = Color(1, 1, 1, windBaseAlpha),
        PlaybackSpeed = windAnimSpeed,
        Scale = Vector.One * windScale,
    }
end

local lastUpdated

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if REVEL.ENT.PRONG:isEnt(npc) and REVEL.IsRenderPassNormal() then
        local data, sprite = REVEL.GetData(npc), npc:GetSprite()

        if data.State == "NorthernWind" and data.Blowing and not data.Death then
            if not lastUpdated or REVEL.game:GetFrameCount() > lastUpdated then
                for i = 1, 3 do windSprite[i]:Update() end
                lastUpdated = REVEL.game:GetFrameCount()
            end

            local offset = data.bal.NorthernWindOffsets[data.BlowDir]
            local vecDir = REVEL.dirToVel[data.BlowDir]

            local startPos = npc.Position + offset
            local farPos = startPos + vecDir * 600
            local endPos = REVEL.room:GetClampedPosition(farPos, 15 + 26 * windScale)

            if data.BlowDir % 2 == 0 then
                endPos = Vector(endPos.X, farPos.Y)
            else
                endPos = Vector(farPos.X, endPos.Y)
            end

            startPos = Isaac.WorldToScreen(startPos)
            endPos = Isaac.WorldToScreen(endPos)

            local lineStartPos = startPos + (endPos - startPos):Resized(26 * windScale)
            local angle = REVEL.dirToAngle[data.BlowDir]

            windSprite[1].Rotation = angle
            windSprite[1]:Render(startPos, Vector.Zero, Vector.Zero)
            REVEL.DrawRotatedTilingSprite(windSprite[2], lineStartPos, endPos, 26 * windScale)
            windSprite[3].Rotation = angle
            windSprite[3]:Render(endPos, Vector.Zero, Vector.Zero)

            if data.BlowDir == Direction.UP then --render npc above blow
                sprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
            end
        end
    elseif REVEL.ENT.PRONG_STATUE:isEnt(npc) then
        local data, sprite = REVEL.GetData(npc), npc:GetSprite()

        npc.Position = data.Pos
        npc.Velocity = Vector.Zero

        sprite.Color = Color.Default
        sprite:Render(Isaac.WorldToScreen(data.Pos), Vector.Zero, Vector.Zero)
        sprite.Color = REVEL.NO_COLOR
    end
end, REVEL.ENT.PRONG.id)

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    lastUpdated = nil
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.PRONG.variant then return end

    RefreezeRoom(true, true, nil, false)
end, REVEL.ENT.PRONG.id)


--prevent room segments getting messed up on reload and also reload balance while at it
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, function()
    local prongs = REVEL.ENT.PRONG:getInRoom()

    if #prongs > 0 then
        local npc = prongs[1]:ToNPC()
        RoomSegments = REVEL.GetData(npc).RoomSegments
        REVEL.GetData(npc).bal = REVEL.GetBossBalance(prongBalance, REVEL.GetData(npc).IsChampion and "Prongerina" or "Default")
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.PRONG_ICE_BOMB:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

    if not data.Init then
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        data.Init = true
    end

    if data.Target then
        REVEL.PlayIfNot(data.Target:GetSprite(), "Blink")
    end

    if sprite:IsEventTriggered("Explode") then
        Isaac.Explode(npc.Position, npc, 2)
        REVEL.game:ShakeScreen(15)
        BreakAllSnowBridges()

        if data.Target then
            data.Target:Remove()
        end

        npc:Remove()
    end
end, REVEL.ENT.PRONG_ICE_BOMB.id)

-- mega bombs handling

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    if StageAPI.GetCurrentRoomType() == BOSS_ROOM_TYPE
    and REVEL.IsGigaBomb(bomb)
    then
        local sprite, data = bomb:GetSprite(), REVEL.GetData(bomb)
        -- track pits, restore them on explosion

        if sprite:IsPlaying("Pulse") then
            data.TileIsPit = {}
            local interestedIndices = REVEL.GetGigaBombTiles(bomb.Position)

            for _, index in ipairs(interestedIndices) do
                local grid = REVEL.room:GetGridEntity(index)
                if grid then
                    data.TileIsPit[index] = grid:GetType() == GridEntityType.GRID_PIT
                else
                    data.TileIsPit[index] = false
                end
            end

        -- On explosion
        elseif IsAnimOn(sprite, "Explode") and sprite:GetFrame() == 0 then
            if data.TileIsPit then
                for index, wasPit in pairs(data.TileIsPit) do
                    local grid = REVEL.room:GetGridEntity(index)
                    if not wasPit and (grid and grid:GetType() == GridEntityType.GRID_PIT) then
                        REVEL.room:RemoveGridEntity(index, 0, false)
                    
                        -- if math.random() > 0.5 then
                            local pos = REVEL.room:GetGridPosition(index) + RandomVector() * math.random(15, 30)
                            local steam = REVEL.SpawnDecoration(pos, REVEL.VEC_UP * 4 + REVEL.VEC_RIGHT * (math.random() * 2 - 1),
                                "Steam" .. math.random(1,3), "gfx/effects/revelcommon/steam.anm2", nil, 30)
                            steam:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/blue_steam.png")
                            steam:GetSprite():ReplaceSpritesheet(1, "gfx/effects/revel1/blue_steam.png")
                            steam:GetSprite():LoadGraphics()
                        -- end
                        REVEL.UpdateRoomASAP()
                    end
                end
                REVEL.DelayFunction(UpdateGrids, 1, nil, true)
            end
        end
    end
end)

end