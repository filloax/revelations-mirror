local HubDoorLock = require "lua.revelcommon.enums.HubDoorLock"
local StageAPICallbacks = require "lua.revelcommon.enums.StageAPICallbacks"
local RevCallbacks      = require "lua.revelcommon.enums.RevCallbacks"
local RevRoomType       = require "lua.revelcommon.enums.RevRoomType"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
local TombTileBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2", "3"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/trap_", ".png")

local TombTileBackdropBoss = StageAPI.BackdropHelper({
    Walls = {"boss"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/trap_", ".png")

local TombTileBackdropMaxwell = StageAPI.BackdropHelper({
    Walls = {"maxwell"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/trap_", ".png")

local TombTileBackdropSarcophaguts = StageAPI.BackdropHelper({
    Walls = {"sarcophaguts"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/trap_", ".png")

local TombChallengeBackdrop = {
    Walls = {"gfx/backdrop/revel2/tomb/challenge.png"}
}

local TombTrapChallengeBackdrop = {
    Walls = {"gfx/backdrop/revel2/tomb/challenge_trap.png"}
}

local TombSacrificeBackdrop = {
    Walls = {"gfx/backdrop/revel2/tomb/sacrifice.png"}
}


local TombSecretBackdrop = {
    Walls = {"gfx/backdrop/revel2/tomb/entrance_caves.png"}
}

local TombTrapSecretBackdrop = {
    Walls = {"gfx/backdrop/revel2/tomb/entrance_caves.png"}
}


local TombTileGrid = StageAPI.GridGfx()

local TombDoorSprites = {
    Default = "gfx/grid/revel2/doors/tomb.png",
    -- Secret = "gfx/grid/revel2/doors/tomb_hole.png",
    Sacrifice = "gfx/grid/revel2/doors/tomb.png", --PLACEHOLDER, needs a tomb_sacrifice version
    Shop = "gfx/grid/revel2/doors/tomb_shop.png",
    Library = "gfx/grid/revel2/doors/tomb_library.png",
    Treasure = "gfx/grid/revel2/doors/tomb_treasure.png",
    Planetarium = "gfx/grid/revel2/doors/tomb_planetarium.png",
    Boss = "gfx/grid/revel2/doors/tomb_boss.png",
    Ambush = "gfx/grid/revel2/doors/tomb_ambush.png",
    BossAmbush = "gfx/grid/revel2/doors/tomb_boss_ambush.png",
    -- Boarded = "gfx/grid/revel2/doors/glacier.png",
    -- Chest = "gfx/grid/revel2/doors/glacier.png",
    Dice = "gfx/grid/revel2/doors/tomb_diceroom.png",
    Curse = "gfx/grid/revel2/doors/tomb_selfsacrifice.png",
    CurseFlatfile = "gfx/grid/revel2/doors/tomb_selfsacrifice_flatfile.png", -- unused, stageapi WIP
    Devil = "gfx/grid/revel2/doors/tomb_devil.png",
    Angel = "gfx/grid/revel2/doors/tomb_angel.png",
    Arcade = "gfx/grid/revel2/doors/tomb_arcade.png",
}

TombTileGrid:SetDoorSpawns(StageAPI.BaseDoorSpawnList)
TombTileGrid:SetDoorSprites(TombDoorSprites)

TombTileGrid:SetRocks("gfx/grid/revel2/tile_rocks.png")
TombTileGrid:SetPits("gfx/grid/revel2/tile_pit.png", nil, true)
TombTileGrid:SetGrid("gfx/grid/revel2/tomb_clearing_plate.png", GridEntityType.GRID_PRESSURE_PLATE, 0)
TombTileGrid:SetGrid("gfx/grid/revel2/tile_spikes.png", GridEntityType.GRID_SPIKES)
TombTileGrid:SetGrid("gfx/grid/revel2/tile_spikes.png", GridEntityType.GRID_SPIKES_ONOFF)
TombTileGrid:SetDecorations("gfx/grid/revel2/tomb_props.png", "gfx/grid/props_05_depths.anm2", 43)
--TombTileGrid:SetBridges("stageapi/floors/catacombs/grid_bridge_catacombs.png")

local TombChallengeGrid = StageAPI.GridGfx()

TombChallengeGrid:SetDoorSpawns {
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

TombChallengeGrid:SetDoorSprites {
    Devil = "gfx/grid/revel2/doors/tomb_devil.png",
    Ambush = "gfx/grid/revel2/doors/tomb_ambush.png",
    BossAmbush = "gfx/grid/revel2/doors/tomb_boss_ambush.png",
    Curse = "gfx/grid/revel2/doors/tomb_selfsacrifice.png",
    CurseFlatfile = "gfx/grid/revel2/doors/tomb_selfsacrifice_flatfile.png",
}


local TombSecretGrid = StageAPI.GridGfx()
TombSecretGrid:SetRocks("gfx/grid/revel2/secret_jar_rocks.png")

local TombTileRoomGfx = StageAPI.RoomGfx(TombTileBackdrop, TombTileGrid)
local TombTileBossRoomGfx = StageAPI.RoomGfx(TombTileBackdropBoss, TombTileGrid)
local TombTileMaxwellGfx = StageAPI.RoomGfx(TombTileBackdropMaxwell, TombTileGrid)
local TombTileSarcophagutsGfx = StageAPI.RoomGfx(TombTileBackdropSarcophaguts, TombTileGrid)
local TombSacrificeGfx = StageAPI.RoomGfx(TombSacrificeBackdrop, nil)
local TombChallengeGfx = StageAPI.RoomGfx(TombChallengeBackdrop, TombChallengeGrid)
local TombTrapChallengeGfx = StageAPI.RoomGfx(TombTrapChallengeBackdrop, TombChallengeGrid)
local TombSecretGfx = StageAPI.RoomGfx(TombSecretBackdrop, TombSecretGrid)
local TombTrapSecretGfx = StageAPI.RoomGfx(TombTrapSecretBackdrop, TombSecretGrid)

local TombSandBackdrop = StageAPI.BackdropHelper({
    Walls = {"1", "2"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/sand_", ".png")

local TombSandBackdropBoss = StageAPI.BackdropHelper({
    Walls = {"boss"},
    NFloors = {"nfloor"},
    LFloors = {"lfloor"},
    Corners = {"corner"}
}, "gfx/backdrop/revel2/tomb/sand_", ".png")

local TombSandGrid = StageAPI.GridGfx()

TombSandGrid:SetDoorSpawns(StageAPI.BaseDoorSpawnList)
TombSandGrid:SetDoorSprites(TombDoorSprites)

TombSandGrid:SetRocks("gfx/grid/revel2/sand_rocks.png")
TombSandGrid:SetPits("gfx/grid/revel2/sand_pit.png", nil, true)
TombSandGrid:SetGrid("gfx/grid/revel2/tomb_clearing_plate.png", GridEntityType.GRID_PRESSURE_PLATE, 0)
TombSandGrid:SetGrid("gfx/grid/revel2/sand_spikes.png", GridEntityType.GRID_SPIKES)
TombSandGrid:SetGrid("gfx/grid/revel2/sand_spikes.png", GridEntityType.GRID_SPIKES_ONOFF)
TombSandGrid:SetDecorations("gfx/grid/revel2/tomb_props.png", "gfx/grid/props_05_depths.anm2", 43)
-- TombSandGrid:SetBridges("stageapi/floors/catacombs/grid_bridge_catacombs.png")

REVEL.TombSandRoomGfx = StageAPI.RoomGfx(TombSandBackdrop, TombSandGrid)
REVEL.TombSandBossRoomGfx = StageAPI.RoomGfx(TombSandBackdropBoss, TombSandGrid)

REVEL.TombGfxRoomTypes = {
    RoomType.ROOM_DEFAULT, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS, 
    RoomType.ROOM_BOSS, RevRoomType.TRAP, RevRoomType.TRAP_BOSS, RevRoomType.TRAP_BOSS_MAXWELL, 
    RevRoomType.TRAP_BOSS_SARCOPHAGUTS, RevRoomType.BOSS_SANDY,
    RevRoomType.FLAMING_TOMBS,
}
REVEL.TombGfxBrazierOnlyTypes = {
    [RoomType.ROOM_DEVIL] = true,
    [RoomType.ROOM_SACRIFICE] = true,
    [RoomType.ROOM_CURSE] = true,
    [RoomType.ROOM_CHALLENGE] = true,
    [RoomType.ROOM_SECRET] = true,
    [RoomType.ROOM_TREASURE] = true,
    [RoomType.ROOM_MINIBOSS] = true,
    [RoomType.ROOM_BOSS] = true,
    [RevRoomType.TRAP_BOSS] = true,
    [RevRoomType.TRAP_BOSS_MAXWELL] = true,
    [RevRoomType.TRAP_BOSS_SARCOPHAGUTS] = true,
    [RevRoomType.TRAP_CHALLENGE] = true,
    [RevRoomType.TRAP_SECRET] = true
}
REVEL.TombSandGfxRoomTypes = {RoomType.ROOM_DEFAULT, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS, RoomType.ROOM_BOSS, RevRoomType.BOSS_SANDY}
REVEL.TombTrapGfxRoomTypes = {
    RevRoomType.TRAP, RevRoomType.TRAP_CHALLENGE, RevRoomType.TRAP_BOSS, 
    RevRoomType.TRAP_BOSS_MAXWELL, RevRoomType.TRAP_BOSS_SARCOPHAGUTS, RevRoomType.TRAP_SECRET,
    RevRoomType.FLAMING_TOMBS,
}

REVEL.STAGE.Tomb = StageAPI.CustomStage("Tomb")
REVEL.STAGE.Tomb:SetNoChampions(true)
REVEL.STAGE.Tomb:SetRooms({
    [RoomType.ROOM_DEFAULT] = REVEL.RoomLists.Tomb,
    [RoomType.ROOM_TREASURE] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_SHOP] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_CURSE] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_SACRIFICE] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_ERROR] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_ARCADE] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_CHALLENGE] = REVEL.RoomLists.TombSpecial,
    [RoomType.ROOM_SECRET] = REVEL.RoomLists.TombSpecial
})
REVEL.STAGE.Tomb:SetSinRooms("ChapterTwo")
REVEL.STAGE.Tomb:SetChallengeWaves(REVEL.RoomLists.TombChallenge, REVEL.RoomLists.TombBossChallenge)
REVEL.STAGE.Tomb:SetRequireRoomTypeMatching()
REVEL.STAGE.Tomb:SetRoomGfx(REVEL.TombSandRoomGfx, {RoomType.ROOM_DEFAULT, RoomType.ROOM_TREASURE, RoomType.ROOM_MINIBOSS})
REVEL.STAGE.Tomb:SetRoomGfx(REVEL.TombSandBossRoomGfx, {RoomType.ROOM_BOSS, RevRoomType.BOSS_SANDY})
REVEL.STAGE.Tomb:SetRoomGfx(TombTileRoomGfx, {RevRoomType.TRAP, RevRoomType.FLAMING_TOMBS})
REVEL.STAGE.Tomb:SetRoomGfx(TombTileBossRoomGfx, RevRoomType.TRAP_BOSS)
REVEL.STAGE.Tomb:SetRoomGfx(TombTileMaxwellGfx, RevRoomType.TRAP_BOSS_MAXWELL)
REVEL.STAGE.Tomb:SetRoomGfx(TombTileSarcophagutsGfx, RevRoomType.TRAP_BOSS_SARCOPHAGUTS)
REVEL.STAGE.Tomb:SetRoomGfx(TombChallengeGfx, {RoomType.ROOM_DEVIL, RoomType.ROOM_CURSE, RoomType.ROOM_CHALLENGE})
REVEL.STAGE.Tomb:SetRoomGfx(TombTrapChallengeGfx, RevRoomType.TRAP_CHALLENGE)
REVEL.STAGE.Tomb:SetRoomGfx(TombSacrificeGfx, {RoomType.ROOM_SACRIFICE})
REVEL.STAGE.Tomb:SetRoomGfx(TombSecretGfx, {RoomType.ROOM_SECRET})
REVEL.STAGE.Tomb:SetRoomGfx(TombTrapSecretGfx, RevRoomType.TRAP_SECRET)
REVEL.STAGE.Tomb:SetTransitionMusic(REVEL.SFX.TRANSITION)
REVEL.STAGE.Tomb:SetStageMusic(REVEL.SFX.TOMB)
REVEL.STAGE.Tomb:SetMusic(REVEL.SFX.TOMB, {RevRoomType.TRAP})
REVEL.STAGE.Tomb:SetBossMusic(REVEL.SFX.TOMB_BOSS, REVEL.SFX.BOSS_CALM, REVEL.SFX.TOMB_BOSS_INTRO, REVEL.SFX.TOMB_BOSS_OUTRO)
REVEL.STAGE.Tomb:SetChallengeMusic(REVEL.SFX.CHALLENGE, REVEL.SFX.BOSS_CALM, nil, REVEL.SFX.CHALLENGE_END)
REVEL.SetCommonMusicForStage(REVEL.STAGE.Tomb)
REVEL.STAGE.Tomb:SetSpots(
    "gfx/ui/stage/revel2/tomb_boss_spot.png",
    "gfx/ui/stage/revel2/tomb_player_spot.png",
    Color(25/255, 15/255, 5/255, 1, 0, 0, 0)
)
REVEL.STAGE.Tomb:SetBosses(REVEL.TombBosses)

REVEL.STAGE.Tomb:OverrideRockAltEffects(true)
REVEL.STAGE.Tomb:OverrideTrapdoors()

REVEL.STAGE.Tomb:SetTransitionIcon(
    "gfx/ui/stage/revel2/tomb_icon.png",
    "gfx/ui/stage/revel2/tomb_boss_spot.png"
)

REVEL.STAGE.Tomb:SetDisplayName("Tomb I")
REVEL.STAGE.Tomb:SetReplace(StageAPI.StageOverride.CatacombsOne)

REVEL.STAGE.Tomb:SetIsSecondStage(false)
REVEL.STAGE.Tomb:SetStageNumber(4,3)
REVEL.StageDisableLabyrinth(REVEL.STAGE.Tomb)

local tombXL = REVEL.STAGE.Tomb("Tomb XL")
tombXL:SetDisplayName("Tomb XL")
tombXL:SetNextStage({
    NormalStage = true,
    Stage = LevelStage.STAGE3_2
})
tombXL:SetIsSecondStage(true)
tombXL:SetStageNumber(5,3)

REVEL.STAGE.Tomb:SetXLStage(tombXL)

REVEL.STAGE.TombTwo = REVEL.STAGE.Tomb("Tomb 2")
REVEL.STAGE.TombTwo:SetReplace(StageAPI.StageOverride.CatacombsTwo)
REVEL.STAGE.TombTwo:SetDisplayName("Tomb II")
REVEL.STAGE.Tomb:SetNextStage(REVEL.STAGE.TombTwo)
REVEL.STAGE.TombTwo:SetNextStage({
    NormalStage = true,
    Stage = LevelStage.STAGE3_2
})
REVEL.STAGE.TombTwo:SetIsSecondStage(true)
REVEL.STAGE.TombTwo:SetStageNumber(5,4)

-- Sand grids different look in bottom row

do
    local function sandGrids_PreChangeRockGfx(grid, index, usingFilename)
        if REVEL.STAGE.Tomb:IsStage() 
        and REVEL.includes(REVEL.TombSandGfxRoomTypes, StageAPI.GetCurrentRoomType())
        then
            local x, y = StageAPI.GridToVector(index, REVEL.room:GetGridWidth())
            local rshape = REVEL.room:GetRoomShape()
            local upperLRoom = rshape == RoomShape.ROOMSHAPE_LBL or rshape == RoomShape.ROOMSHAPE_LBR
            if y == REVEL.room:GetGridHeight() - 3 -- bottom row
            or (upperLRoom and y == 6 and (
                (rshape == RoomShape.ROOMSHAPE_LBR and x >= 13)
                or (rshape == RoomShape.ROOMSHAPE_LBL and x < 13)
            )) -- l room upper bottom wall
            then
                return "gfx/grid/revel2/sand_rocks_bottomrow.png"
            end
        end
    end

    StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_CHANGE_ROCK_GFX, 0, sandGrids_PreChangeRockGfx, REVEL.STAGE.Tomb)
end

-- Hub Room Access --
do
    REVEL.HubRoomVersions.ChapterTwo = {
        Prefix = "gfx/backdrop/",
        OpenSound = {
            Left = REVEL.SFX.TOMB_DOOR_OPEN
        },
        Stages = {
            {Stage = REVEL.STAGE.Glacier, IsSecondStage = true},
            {Stage = REVEL.STAGE.Tomb, IsSecondStage = false},
            {Stage = LevelStage.STAGE2_1},
            {Stage = LevelStage.STAGE2_2}
        },
        Entering = {
            Left = {
                Early = REVEL.STAGE.Tomb,
                Late = REVEL.STAGE.TombTwo
            },
            Middle = {
                Early = {NormalStage = true, Stage = LevelStage.STAGE2_2, IsSecondStage = true},
                Late = {NormalStage = true, Stage = LevelStage.STAGE3_1}
            },
            Right = {
                Early = {NormalStage = true, Stage = LevelStage.STAGE2_1, IsRepentance = true},
                Late  = {NormalStage = true, Stage = LevelStage.STAGE2_2, IsRepentance = true, IsSecondStage = true},
            }
        },
        Sprites = {
            Left = {"revel2/hubroom/hubdoor_", "tomb"},
            Middle = {
                Early = {"revel2/hubroom/hubdoor_", "caves"},
                Late = {"revel3/hubroom/hubdoor_", "depths"}
            },
            Right = {"revel2/hubroom/hubdoor_", "mines"}
        },
        Locked = {
            Left = {
                Default = HubDoorLock.BOMBS,
                Alt = {
                    Early = HubDoorLock.BOMBS,
                    Late = HubDoorLock.NONE,
                },
            },
            Middle = HubDoorLock.NONE,
            Right = {
                Default = HubDoorLock.BOMBS,
                Alt = {
                    Early = HubDoorLock.BOMBS,
                    Late = HubDoorLock.NONE,
                },
            },
        },
    }

    REVEL.HubRoomVersions.ChapterThree = {
        Prefix = "gfx/backdrop/",
        OpenSound = {
        },
        Stages = {
            {Stage = REVEL.STAGE.Tomb, IsSecondStage = true}
        },
        Entering = {
            Left = {
                Early = {Locked = true},
                Late = {Locked = true, IsSecondStage = true}
            },
            Middle = {
                Early = {NormalStage = true, Stage = LevelStage.STAGE3_2, IsSecondStage = true},
                Late = {NormalStage = true, Stage = LevelStage.STAGE4_1}
            },
            Right = {
                Early = {NormalStage = true, Stage = LevelStage.STAGE3_1, IsRepentance = true},
                Late  = {NormalStage = true, Stage = LevelStage.STAGE3_2, IsRepentance = true, IsSecondStage = true},
            }
        },
        Sprites = {
            Left = {"revel3/hubroom/hubdoor_", "vestige"},
            Middle = {"revel3/hubroom/hubdoor_", "depths"},
            Right = {
                Default = {"revel3/hubroom/hubdoor_", "maus", "_locked"},
                Alt = {
                    Early = {"revel3/hubroom/hubdoor_", "maus", "_locked"},
                    Late = {"revel3/hubroom/hubdoor_", "maus"},
                },
            },
        },
        Locked = {
            Left = HubDoorLock.NONE,
            Middle = HubDoorLock.NONE,
            Right = {
                Default = HubDoorLock.HEARTS,
                Alt = {
                    Early = HubDoorLock.HEARTS,
                    Late = HubDoorLock.NONE,
                },
            },
        }
    }
end
    
end