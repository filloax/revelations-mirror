local HubDoorLock = require "lua.revelcommon.enums.HubDoorLock"
local RevRoomType = require "lua.revelcommon.enums.RevRoomType"

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    REVEL.GlacierBalance = {
        ChillTimeToFreeze = {
            LowSpeed = 360,
            HighSpeed = 120,
            EndHigh = 0.8,
            EndLow = 0.2
        },
    
        DefaultWarmRadius = 100,
        DefaultFreezeRadius = 60,
    
        ChillShrineWarmthMod = 0.75,
        ChillShrineFreezeMod = 1.25,
    
        ChillColor = Color(0.5, 0.6, 0.8, 1.0, conv255ToFloat( 0, 40, 80)),
    
        IceSlipperiness = 0.6,
        IceVelocityThreshold = 6, -- if position or velocity changes by this amount, ice slipperiness is reset
        IcePositionThreshold = 40,
    
        ExplodingSnowmanRadius = 40 * 2.5,
    
        DarkIceChillDuration = 70,
        DarkIceInChill = false,
    
        FragilityIceEntityBlacklist = {
            {Type = REVEL.ENT.TUSKY.id, Variant = REVEL.ENT.TUSKY.variant},
            {Type = REVEL.ENT.BIG_BLOWY.id, Variant = REVEL.ENT.BIG_BLOWY.variant},
            {Type = REVEL.ENT.HOCKEY_PUCK.id, Variant = REVEL.ENT.HOCKEY_PUCK.variant},
        },
        FragilityFragileIce = true,
        FragileIceReformTime = 7 * 30, --7 seconds, set to 0 to disable reforming
        FragileIceRoomClearReformTime = 2 * 30, --time after room clear when all fragile ice spots get cleared, set to 0 to not do anything special on room clear
    }
    
    REVEL.STAGE = REVEL.STAGE or {}
    
    local GlacierGrid = StageAPI.GridGfx()

    ---@type DoorSprites
    local GlacierDoorSprites = {
        Default = "gfx/grid/revel1/doors/glacier.png",
        Secret = "gfx/grid/revel1/doors/glacier_hole.png",
        Sacrifice = "gfx/grid/revel1/doors/glacier_sacrifice.png",
        Shop = "gfx/grid/revel1/doors/glacier_shop.png",
        Library = "gfx/grid/revel1/doors/glacier_library.png",
        Treasure = "gfx/grid/revel1/doors/glacier_treasure.png",
        Planetarium = "gfx/grid/revel1/doors/glacier_planetarium.png",
        Boss = "gfx/grid/revel1/doors/glacier_boss.png",
        Ambush = "gfx/grid/revel1/doors/glacier_ambush.png",
        BossAmbush = "gfx/grid/revel1/doors/glacier_boss_ambush.png",
        -- Boarded = "gfx/grid/revel1/doors/glacier.png",
        -- Chest = "gfx/grid/revel1/doors/glacier.png",
        Dice = "gfx/grid/revel1/doors/glacier_dice.png",
        Curse = "gfx/grid/revel1/doors/glacier_selfsacrifice.png",
        CurseFlatfile = "gfx/grid/revel1/doors/glacier_selfsacrifice_flatfile.png",
        Devil = "gfx/grid/revel1/doors/glacier_devil.png",
        Angel = "gfx/grid/revel1/doors/glacier_angel.png",
        Arcade = "gfx/grid/revel1/doors/glacier_arcade.png",
    }

    GlacierGrid:SetDoorSpawns(StageAPI.BaseDoorSpawnList)
    GlacierGrid:SetDoorSprites(GlacierDoorSprites)

    GlacierGrid:SetRocks("gfx/grid/revel1/glacier_rocks.png")
    GlacierGrid:SetPits("gfx/grid/revel1/glacier_pit.png", nil, true)
    GlacierGrid:SetDecorations("gfx/grid/revel1/glacier_props.png")
    GlacierGrid:SetGrid("gfx/grid/revel1/glacier_poop.png", GridEntityType.GRID_POOP, StageAPI.PoopVariant.Normal)
    GlacierGrid:SetGrid("gfx/grid/revel1/glacier_poop_corn.png", GridEntityType.GRID_POOP, StageAPI.PoopVariant.Eternal)
    GlacierGrid:SetGrid("gfx/grid/revel1/glacier_grid_locks.png", GridEntityType.GRID_LOCK)
    --GlacierGrid:SetBridges("gfx/grid/revel1/glacier_bridge.png")
    REVEL.GlacierGrid = GlacierGrid
    
    local GlacierBackdrop = StageAPI.BackdropHelper({
        Walls = {"1", "2", "3"},
        NFloors = {"nfloor"},
        LFloors = {"lfloor"},
        Corners = {"corner"}
    }, "gfx/backdrop/revel1/glacier/main_", ".png")
    
    local GlacierBackdropBoss = StageAPI.BackdropHelper({
        Walls = {"boss"},
        NFloors = {"nfloor"},
        LFloors = {"lfloor"},
        Corners = {"corner"}
    }, "gfx/backdrop/revel1/glacier/main_", ".png")
    
    local GlacierBackdropBossChill = StageAPI.BackdropHelper({
        Walls = {"boss"},
        NFloors = {"nfloor"},
        LFloors = {"lfloor"},
        Corners = {"corner"}
    }, "gfx/backdrop/revel1/glacier/chill_", ".png")
    
    local GlacierChallengeBackdrop = StageAPI.BackdropHelper({
        Walls = {"challenge"},
        NFloors = {"challenge_nfloor"},
        LFloors = {"main_lfloor"},
        Corners = {"main_corner"}
    }, "gfx/backdrop/revel1/glacier/", ".png")
    
    local GlacierChillChallengeBackdrop = {
        Walls = {"gfx/backdrop/revel1/glacier/challenge_chill.png"}
    }
    
    local GlacierSacrificeBackdrop = StageAPI.BackdropHelper({
        Walls = {"sacrifice"},
        NFloors = {"sacrifice_nfloor"},
        LFloors = {"main_lfloor"},
        Corners = {"main_corner"}
    }, "gfx/backdrop/revel1/glacier/", ".png")
    
    local GlacierSecretBackdrop = {
        Walls = {"gfx/backdrop/revel1/glacier/secret.png"}
    }
    
    --[[
    local GlacierChillSecretBackdrop = {
        Walls = {"gfx/backdrop/revel1/glacier/secret_chill.png"}
    }
    ]]
    
    local GlacierCellarBackdrop = StageAPI.BackdropHelper({
        Walls = {"cellar"}
    }, "gfx/backdrop/revel1/glacier/", ".png")
    
    local GlacierBasementBackdrop = StageAPI.BackdropHelper({
        Walls = {"basement"}
    }, "gfx/backdrop/revel1/glacier/", ".png")
    
    local GlacierCellarGfx = StageAPI.RoomGfx(GlacierCellarBackdrop, GlacierGrid)
    local GlacierBasementGfx = StageAPI.RoomGfx(GlacierBasementBackdrop, GlacierGrid)
    
    REVEL.GlacierRoomGfx = StageAPI.RoomGfx(GlacierBackdrop, GlacierGrid)
    
    local GlacierChillGrid = StageAPI.GridGfx()    
    
    GlacierChillGrid:SetDoorSpawns(StageAPI.BaseDoorSpawnList)
    GlacierChillGrid:SetDoorSprites(GlacierDoorSprites)

    GlacierChillGrid:SetRocks("gfx/grid/revel1/glacier_chill_rocks.png")
    GlacierChillGrid:SetPits("gfx/grid/revel1/glacier_chill_pit.png", nil, true)
    GlacierChillGrid:SetDecorations("gfx/grid/revel1/glacier_props.png")
    GlacierChillGrid:SetGrid("gfx/grid/revel1/glacier_poop.png", GridEntityType.GRID_POOP, StageAPI.PoopVariant.Normal)
    GlacierChillGrid:SetGrid("gfx/grid/revel1/glacier_poop_corn.png", GridEntityType.GRID_POOP, StageAPI.PoopVariant.Eternal)
    -- GlacierChillGrid:SetBridges("gfx/grid/revel1/glacier_bridge.png")
    
    local GlacierChillBackdrop = StageAPI.BackdropHelper({
        Walls = {"1", "2"},
        NFloors = {"nfloor"},
        LFloors = {"lfloor"},
        Corners = {"corner"}
    }, "gfx/backdrop/revel1/glacier/chill_", ".png")
    
    local GlacierChallengeGrid = StageAPI.GridGfx()

    GlacierChallengeGrid:SetDoorSpawns {
        {
            Sprite = "Devil",
            RequireEither = {RoomType.ROOM_DEVIL}
        },
        {
            Sprite = "Ambush",
            RequireEither = {RoomType.ROOM_CHALLENGE},
            NotEither = {RoomType.ROOM_SECRET, RoomType.ROOM_SUPERSECRET}
        },
        {
            Sprite = "BossAmbush",
            RequireEither = {RoomType.ROOM_CHALLENGE}, 
            NotEither = {RoomType.ROOM_SECRET, RoomType.ROOM_SUPERSECRET}, 
            IsBossAmbush = true
        },
        {
            Sprite = "CurseFlatfile",
            RequireEither = {RoomType.ROOM_CURSE}, 
            NotEither = {RoomType.ROOM_SECRET, RoomType.ROOM_SUPERSECRET},
            RequireVarData = 1,
        },    
        {
            Sprite = "Curse",
            RequireEither = {RoomType.ROOM_CURSE}, 
            NotEither = {RoomType.ROOM_SECRET, RoomType.ROOM_SUPERSECRET}
        },    
    }

    GlacierChallengeGrid:SetDoorSprites {
        Devil = "gfx/grid/revel1/doors/glacier_devil_inside.png",
        Ambush = "gfx/grid/revel1/doors/glacier_ambush_inside.png",
        BossAmbush = "gfx/grid/revel1/doors/glacier_boss_ambush_inside.png",
        Curse = "gfx/grid/revel1/doors/glacier_selfsacrifice_inside.png",
        CurseFlatfile = "gfx/grid/revel1/doors/glacier_selfsacrifice_inside_flatfile.png",
    }
    
    local GlacierSecretGrid = StageAPI.GridGfx()
    GlacierSecretGrid:SetRocks("gfx/grid/revel1/secret_ice_rocks.png")
    
    local GlacierIceGrid = GlacierGrid()
    GlacierIceGrid:SetPits("gfx/grid/revel1/prong_pit.png", nil, true)
    
    local GlacierBackdropBossIce = StageAPI.BackdropHelper({
        Walls = {"ice_boss"},
        NFloors = {"main_nfloor"},
        LFloors = {"main_lfloor"},
        Corners = {"main_corner"}
    }, "gfx/backdrop/revel1/glacier/", ".png")
    
    REVEL.GlacierChillRoomGfx = StageAPI.RoomGfx(GlacierChillBackdrop, GlacierChillGrid)
    REVEL.GlacierBossRoomGfx = StageAPI.RoomGfx(GlacierBackdropBoss, GlacierGrid)
    REVEL.GlacierIceBossRoomGfx = StageAPI.RoomGfx(GlacierBackdropBossIce, GlacierIceGrid)
    REVEL.GlacierChillFreezerBurnRoomGfx = StageAPI.RoomGfx(GlacierBackdropBossChill, GlacierChillGrid)
    REVEL.GlacierChallengeRoomGfx = StageAPI.RoomGfx(GlacierChallengeBackdrop, GlacierChallengeGrid)
    REVEL.GlacierChillChallengeRoomGfx = StageAPI.RoomGfx(GlacierChillChallengeBackdrop, GlacierChallengeGrid)
    REVEL.GlacierSacrificeRoomGfx = StageAPI.RoomGfx(GlacierSacrificeBackdrop, nil)
    REVEL.GlacierSecretRoomGfx = StageAPI.RoomGfx(GlacierSecretBackdrop, GlacierSecretGrid)
    -- REVEL.GlacierChillSecretRoomGfx = StageAPI.RoomGfx(GlacierChillSecretBackdrop, GlacierSecretGrid)
    
    REVEL.GlacierGfxRoomTypes = {
        RoomType.ROOM_DEFAULT, 
        RoomType.ROOM_TREASURE, 
        RoomType.ROOM_MINIBOSS, 
        RoomType.ROOM_BOSS, 
        RoomType.ROOM_CURSE, 
        RoomType.ROOM_SACRIFICE, 
        RoomType.ROOM_SECRET, 
        RoomType.ROOM_CHALLENGE, 
        RevRoomType.CHILL, 
        RevRoomType.CHILL_CHALLENGE, 
        RevRoomType.CHILL_FREEZER_BURN, 
        RevRoomType.ICE_BOSS,
        RevRoomType.DANTE_MEGA_SATAN,
    } --, "ChillSecret"
    REVEL.ChillRoomTypes = { RevRoomType.CHILL, RevRoomType.CHILL_CHALLENGE, RevRoomType.CHILL_FREEZER_BURN } --, "ChillSecret"
    REVEL.SnowFloorRoomTypes = { RevRoomType.CHILL, RevRoomType.CHILL_CHALLENGE, RevRoomType.CHILL_FREEZER_BURN } --, "ChillSecret"
    
    REVEL.STAGE.Glacier = StageAPI.CustomStage("Glacier")
    REVEL.STAGE.Glacier:SetNoChampions(true)
    REVEL.STAGE.Glacier:SetRooms({
        [RoomType.ROOM_DEFAULT] = REVEL.RoomLists.Glacier,
        [RoomType.ROOM_TREASURE] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_SHOP] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_CURSE] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_SACRIFICE] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_ERROR] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_ARCADE] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_CHALLENGE] = REVEL.RoomLists.GlacierSpecial,
        [RoomType.ROOM_SECRET] = REVEL.RoomLists.GlacierSpecial
    })
    REVEL.STAGE.Glacier:SetSinRooms("ChapterOne", true)
    REVEL.STAGE.Glacier:SetChallengeWaves(REVEL.RoomLists.GlacierChallenge, REVEL.RoomLists.GlacierBossChallenge)
    REVEL.STAGE.Glacier:SetRequireRoomTypeMatching()
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierRoomGfx, {RoomType.ROOM_DEFAULT, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS})
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierBossRoomGfx, {RoomType.ROOM_BOSS})
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierChillFreezerBurnRoomGfx, RevRoomType.CHILL_FREEZER_BURN)
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierIceBossRoomGfx, {RevRoomType.ICE_BOSS, RevRoomType.DANTE_MEGA_SATAN})
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierChallengeRoomGfx, {RoomType.ROOM_DEVIL, RoomType.ROOM_CURSE, RoomType.ROOM_CHALLENGE})
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierChillChallengeRoomGfx, RevRoomType.CHILL_CHALLENGE)
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierSacrificeRoomGfx, {RoomType.ROOM_SACRIFICE})
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierSecretRoomGfx, {RoomType.ROOM_SECRET})
    -- REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierChillSecretRoomGfx, "ChillSecret")
    REVEL.STAGE.Glacier:SetRoomGfx(REVEL.GlacierChillRoomGfx, RevRoomType.CHILL)
    REVEL.STAGE.Glacier:SetTransitionMusic(REVEL.SFX.TRANSITION)
    REVEL.STAGE.Glacier:SetStageMusic(REVEL.SFX.GLACIER)
    REVEL.STAGE.Glacier:SetMusic(REVEL.SFX.GLACIER, {RevRoomType.CHILL})
    REVEL.STAGE.Glacier:SetChallengeMusic(REVEL.SFX.CHALLENGE, REVEL.SFX.BOSS_CALM, nil, REVEL.SFX.CHALLENGE_END)
    REVEL.STAGE.Glacier:SetBossMusic(REVEL.SFX.GLACIER_BOSS, REVEL.SFX.BOSS_CALM, REVEL.SFX.GLACIER_BOSS_INTRO, REVEL.SFX.GLACIER_BOSS_OUTRO)
    REVEL.SetCommonMusicForStage(REVEL.STAGE.Glacier)
    REVEL.STAGE.Glacier:SetBosses(REVEL.GlacierBosses)
    REVEL.STAGE.Glacier:SetSpots(
        "gfx/ui/stage/revel1/glacier_boss_spot.png", 
        "gfx/ui/stage/revel1/glacier_player_spot.png",
        Color(8/255, 15/255, 40/255, 1, 0, 0, 0)
    )
    REVEL.STAGE.Glacier:SetRenderStartingRoomControls(true)
    REVEL.STAGE.Glacier:SetFloorTextColor(Color(0,0,0,1,conv255ToFloat(85,120,155)))
    REVEL.STAGE.Glacier:SetTrueCoopSpots("gfx/truecoop/versusscreen/playerspots/glacier_2.png", "gfx/truecoop/versusscreen/playerspots/glacier_4.png", "gfx/truecoop/versusscreen/playerspots/glacier_3.png")
    REVEL.STAGE.Glacier:OverrideRockAltEffects({RoomType.ROOM_DEFAULT, RevRoomType.CHILL, RoomType.ROOM_BOSS, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS, RoomType.ROOM_SECRET}) --, "ChillSecret"
    REVEL.STAGE.Glacier:OverrideTrapdoors()
    REVEL.STAGE.Glacier:SetTransitionIcon(
        "gfx/ui/stage/revel1/glacier_icon.png", 
        "gfx/ui/stage/revel1/glacier_boss_spot.png"
    )
    
    REVEL.STAGE.Glacier:SetDisplayName("Glacier I")
    
    REVEL.STAGE.Glacier:SetIsSecondStage(false)
    REVEL.STAGE.Glacier:SetStageNumber(2)
    
    local glacierXL = REVEL.STAGE.Glacier("Glacier XL")
    glacierXL:SetDisplayName("Glacier XL")
    glacierXL:SetNextStage({
        NormalStage = true,
        Stage = LevelStage.STAGE2_2
    })
    glacierXL:SetIsSecondStage(true)
    glacierXL:SetStageNumber(3)
    
    REVEL.STAGE.Glacier:SetXLStage(glacierXL)
    
    REVEL.STAGE.GlacierTwo = REVEL.STAGE.Glacier("Glacier 2")
    REVEL.STAGE.GlacierTwo:SetReplace(StageAPI.StageOverride.CatacombsTwo)
    REVEL.STAGE.GlacierTwo:SetDisplayName("Glacier II")
    REVEL.STAGE.Glacier:SetNextStage(REVEL.STAGE.GlacierTwo)
    REVEL.STAGE.GlacierTwo:SetNextStage({
        NormalStage = true,
        Stage = LevelStage.STAGE2_2
    })
    REVEL.STAGE.GlacierTwo:SetIsSecondStage(true)
    REVEL.STAGE.GlacierTwo:SetRenderStartingRoomControls(false)
    REVEL.STAGE.GlacierTwo:SetStageNumber(3)

    REVEL.STAGE.Glacier:SetLevelgenStage(LevelStage.STAGE1_2)
    REVEL.STAGE.GlacierTwo:SetLevelgenStage(LevelStage.STAGE2_1)
    REVEL.StageAddLabyrinthChance(REVEL.STAGE.Glacier)
    REVEL.StageDisableLabyrinth(REVEL.STAGE.GlacierTwo)

        
    -- Hub Room Access --
    do
        REVEL.HubRoomVersions.SkipHub = {
            HasHubMachine = true,
            Ladder = true,
            Prefix = "gfx/backdrop/",
            OpenSound = {
                Left = SoundEffect.SOUND_DOOR_HEAVY_OPEN -- glacier door opens is a stinger and wouldn't fit alongside the hub room stinger very well
            },
            Entering = {
                Left = REVEL.STAGE.Glacier,
                Right = {NormalStage = true, Stage = LevelStage.STAGE1_1, IsRepentance = true},
            },
            Sprites = {
                Left = {"revel1/hubroom/hubdoor_", "glacier"},
                Right = {"revel1/hubroom/hubdoor_", "downpour"}
            },
            Locked = {
                Left = HubDoorLock.NONE,
                Right = HubDoorLock.NONE,
            }
        }

        REVEL.HubRoomVersions.ChapterOne = {
            Prefix = "gfx/backdrop/",
            OpenSound = {
                Left = SoundEffect.SOUND_DOOR_HEAVY_OPEN -- glacier door opens is a stinger and wouldn't fit alongside the hub room stinger very well
            },
            Stages = {
                {Stage = REVEL.STAGE.Glacier, IsSecondStage = false},
                {Stage = LevelStage.STAGE1_1},
                {Stage = LevelStage.STAGE1_2}
            },
            Entering = {
                Left = {
                    Early = REVEL.STAGE.Glacier,
                    Late = REVEL.STAGE.GlacierTwo
                },
                Middle = {
                    Early = {NormalStage = true, Stage = LevelStage.STAGE1_2, IsSecondStage = true},
                    Late = {NormalStage = true, Stage = LevelStage.STAGE2_1}
                },
                Right = {
                    Early = {NormalStage = true, Stage = LevelStage.STAGE1_1, IsRepentance = true},
                    Late  = {NormalStage = true, Stage = LevelStage.STAGE1_2, IsRepentance = true, IsSecondStage = true}
                }
            },
            Sprites = {
                Left = {
                    Default = {"revel1/hubroom/hubdoor_", "glacier", "_locked"},
                    Alt = {
                        Early = {"revel1/hubroom/hubdoor_", "glacier"},
                        Late = {"revel1/hubroom/hubdoor_", "glacier", "_locked"},
                    },
                },
                Middle = {
                    Early = {"revel1/hubroom/hubdoor_", "basement"},
                    Late = {"revel2/hubroom/hubdoor_", "caves"}
                },
                Right = {
                    Default = {"revel1/hubroom/hubdoor_", "downpour", "_locked"},
                    Alt = {
                        Early = {"revel1/hubroom/hubdoor_", "downpour"},
                        Late = {"revel1/hubroom/hubdoor_", "downpour", "_locked"},
                    },
                },
            },
            Locked = {
                Left = {
                    Default = HubDoorLock.KEY,
                    Alt = {
                        Early = HubDoorLock.KEY,
                        Late = HubDoorLock.NONE,
                    },
                },
                Middle = HubDoorLock.NONE,
                Right = {
                    Default = HubDoorLock.KEY,
                    Alt = {
                        Early = HubDoorLock.KEY,
                        Late = HubDoorLock.NONE,
                    },
                },
            },
        }
    end
end

REVEL.PcallWorkaroundBreakFunction()