local GridBreakState = require "lua.revelcommon.enums.GridBreakState"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------
-- SFX --
---------
REVEL.mixin(REVEL.SFX, {
    FLASH_MONSTER_YELL = REVEL.registerSound("REV Flash Monster Yell"),
    FLASH_BOSS_GURGLE = REVEL.registerSound("REV Flash Boss Gurgle"),

    WAKA_WAKA_THEME = REVEL.registerSound("REV Waka Waka Theme"),
    WAKA_WAKA_PICKUP = REVEL.registerSound("REV Waka Waka Pickup"),

    ACTIVATE_TRAP = REVEL.registerSound("REV Activate Trap"),

    COFFIN_OPEN = REVEL.registerSound("REV Coffin Open"),
    COFFIN_CLOSE = REVEL.registerSound("REV Coffin Close"),

    BOULDER_THUMP = REVEL.registerSound("REV Boulder Thump"),
    BOULDER_ROLL = REVEL.registerSound("REV Boulder Roll"),
    BOULDER_BREAK = REVEL.registerSound("REV Boulder Break"),

    BUFF_LIGHTNING = REVEL.registerSound("REV Buff Lightning"),

    LOCUST_BITE = REVEL.registerSound("REV Locust Bite"),
    LOCUST_EAT = REVEL.registerSound("REV Locust Eat Loop"),
    LOCUST_SWARM = REVEL.registerSound("REV Locust Swarm"),

    SPIKE_SHOT = REVEL.registerSound("REV Spike Shot"),
    CRONCH = REVEL.registerSound("REV Cronch"),
    ARROWHEAD_ALERT = REVEL.registerSound("REV Arrowhead Alert"),
    PYRAMIDHEAD_CRY = REVEL.registerSound("REV Pyramidhead Cry"),

    ELEVATOR = REVEL.registerSound("REV Elevator Ding"),
    SPRING = REVEL.registerSound("REV Spring Shoot"),
    MAXWELL_ATTACK = REVEL.registerSound("REV Maxwell Attack"),
    MAXWELL_COUGH = REVEL.registerSound("REV Maxwell Cough"),
    MAXWELL_LAUGH = REVEL.registerSound("REV Maxwell Laugh"),
    MAXWELL_PORTAL1 = REVEL.registerSound("REV Maxwell Portal 1"),
    MAXWELL_PORTAL2 = REVEL.registerSound("REV Maxwell Portal 2"),
    MAXWELL_BLENDER_DEATH = REVEL.registerSound("REV Maxwell Blender Death"),
    MAXWELL_SQUISH = REVEL.registerSound("REV Maxwell Squish"),
    MAXWELL_SLAM_DUNK = REVEL.registerSound("REV Maxwell Slam Dunk"),
    MAXWELL_SLAM_DUNK_IMPACT = REVEL.registerSound("REV Maxwell Slam Dunk Impact"),
    MAXWELL_BUBBLE_SHOOT = REVEL.registerSound("REV Maxwell Bubble Shoot"),
    MAXWELL_BUBBLE_POP = REVEL.registerSound("REV Maxwell Bubble Pop"),
    MAXWELL_BRIMSTONE_TELL = REVEL.registerSound("REV Maxwell Brimstone Tell"),
    MAXWELL_INHALE = REVEL.registerSound("REV Maxwell Inhale"),

    MUSIC_BOX_PLACE = REVEL.registerSound("REV Music Box Place"),
    MUSIC_BOX_BREAK = REVEL.registerSound("REV Music Box Break"),
    MUSIC_BOX_TUNE_LULLABY = REVEL.registerSound("REV Music Box Tune Lullaby"),
    MUSIC_BOX_TUNE_HYMN = REVEL.registerSound("REV Music Box Tune Hymn"),
    MUSIC_BOX_TUNE_SAMBA = REVEL.registerSound("REV Music Box Tune Samba"),
    MUSIC_BOX_TUNE_METAL = REVEL.registerSound("REV Music Box Tune Metal"),

    AIRY_WHOOSH = REVEL.registerSound("REV Airy Whoosh"),
    WHOOSH = REVEL.registerSound("REV Whoosh"),
    SWING = REVEL.registerSound("REV Swing"),
    STONE_ROLL = REVEL.registerSound("REV Stone Roll"),

    ARAGNID_SWING = REVEL.registerSound("REV Aragnid Swing"),
    ARAGNID_WAKEUP = REVEL.registerSound("REV Aragnid Wakeup"),
    ARAGNID_INNARD_LAUNCH = REVEL.registerSound("REV Aragnid Innard Launch"),
    ARAGNID_RUPTURING_SCREAM = REVEL.registerSound("REV Aragnid Rupturing Scream"),
    ARAGNID_MAGIC_SPLASH = REVEL.registerSound("REV Aragnid Magic Splash"),
    ARAGNID_MAGIC_BLOOD_RAIN = REVEL.registerSound("REV Aragnid Magic Blood Rain"),
    ARAGNID_MAGIC_BLOOD_RAIN_LOOP = REVEL.registerSound("REV Aragnid Magic Blood Rain Loop"),
    ARAGNID_DEATH_YELL = REVEL.registerSound("REV Aragnid Death Yell"),

    CATASTROPHE_STRAIN_THEN_RIP_WRAPPINGS = REVEL.registerSound("REV Catastrophe Strain Then Rip Wrappings"),
    CAT_READYING_CLAWS = REVEL.registerSound("REV Cat Readying Claws"),
    CAT_KNOCKING_BALL = REVEL.registerSound("REV Cat Knocking Ball"),
    CATASTROPHE_ATTACK = REVEL.registerSound("REV Catastrophe Attack"),
    CATASTROPHE_COUGH = REVEL.registerSound("REV Catastrophe Cough"),
    CATASTROPHE_DEFEAT = REVEL.registerSound("REV Catastrophe Defeat"),
    CATASTROPHE_DEFEAT_FINAL = REVEL.registerSound("REV Catastrophe Defeat Final"),
    CATASTROPHE_SPAWN = REVEL.registerSound("REV Catastrophe Spawn"),

    DUNGO_CRYOUT = REVEL.registerSound("REV Dungo Cryout"),
    DUNGO_LAND_ON_POOP = REVEL.registerSound("REV Dungo Land on Poop"),
    DUNGO_PHASE_2 = REVEL.registerSound("REV Dungo Phase 2"),
    DUNGO_PLUNGER_ATTACK = REVEL.registerSound("REV Dungo Plunger Attack"),
    DUNGO_POOP_BALL_ROLLING_LOOP = REVEL.registerSound("REV Dungo Poop Ball Rolling Loop"),
    DUNGO_SHOOT_POOP_BALL = REVEL.registerSound("REV Dungo Shoot Poop Ball"),

    SLIDE_WHISTLE = REVEL.registerSound("REV Slide Whistle"),
    CLAP_LOOP = REVEL.registerSound("REV Clapping Loop"),
    CLAP_FADE = REVEL.registerSound("REV Clapping Fade"),

    HATCH_OPEN = REVEL.registerSound("REV Hatch Open"),
    HATCH_CLOSE = REVEL.registerSound("REV Hatch Close"),
    SARCOPHAGUTS_FLASH_1 = REVEL.registerSound("REV Sarcophaguts Flash 1"),
    SARCOPHAGUTS_FLASH_2 = REVEL.registerSound("REV Sarcophaguts Flash 2"),
    SARCOPHAGUTS_HEAD_LAUNCH = REVEL.registerSound("REV Sarcophaguts Head Launch"),

    NARC_GLASS_BREAK_LIGHT = REVEL.registerSound("REV Narc Glass Break Light"),
    NARC_LAUNCHER = REVEL.registerSound("REV Narc Launcher"),
    NARC_WALL_STICK_SHARD_INSTANT = REVEL.registerSound("REV Narc Wall Stick Shard Instant"),
    NARC2_DEATH = REVEL.registerSound("REV Narc2 Death"),
    NARC_MIRROR_WARP = REVEL.registerSound("REV Narc Mirror Warp"),
    NARC_GPOUND = REVEL.registerSound("REV Narc Ground Pound"),
    NARC_FISTPOUND = REVEL.registerSound("REV Narc Fist Pound"),
    NARC_CHEST_SMASH = REVEL.registerSound("REV Narc Chest Smash"),
    NARC_CHEST_POUND = REVEL.registerSound("REV Narc Chest Pound"),
    NARC_POSE = REVEL.registerSound("REV Narc Pose"),

    -- Bips

    BIP_BURROW = REVEL.registerSound("REV Bip Burrow"),
    BIP_CHARGE = REVEL.registerSound("REV Bip Charge"),
    BIP_CRY = REVEL.registerSound("REV Bip Cry"),
    BIP_EMERGE = REVEL.registerSound("REV Bip Emerge"),
    BOB_CRY = REVEL.registerSound("REV Bob Cry"),
    SNIPEBIP_CHARGE = REVEL.registerSound("REV Snipebip Charge"),
    SNIPEBIP_SCOPE = REVEL.registerSound("REV Snipebip Scope"),
    SNIPEBIP_SHOOT = REVEL.registerSound("REV Snipebip Shoot"),
    CANNON_BLAST = REVEL.registerSound("REV Cannon Blast"),
    SAND_PROJ_IMPACT_LARGE = REVEL.registerSound("REV Sand Proj Impact Large"),
    SAND_PROJ_IMPACT = REVEL.registerSound("REV Sand Proj Impact"),

    LOVERS_LIB = REVEL.registerSound("REV Lovers Libido Kiss"),

    TOMB_DOOR_OPEN = REVEL.registerSound("REV Tomb Door Open"),

    -----------
    -- MUSIC --
    -----------

    TOMB = Isaac.GetMusicIdByName("Tomb"),
    TOMB_BOSS = Isaac.GetMusicIdByName("Tomb Boss"),
    TOMB_BOSS_INTRO = Isaac.GetMusicIdByName("Tomb Boss Intro"),
    TOMB_BOSS_OUTRO = Isaac.GetMusicIdByName("Tomb Boss Outro"),
    TOMB_ENTRANCE = Isaac.GetMusicIdByName("Tomb Entrance"),

    MIRROR_BOSS_2 = Isaac.GetMusicIdByName("Mirror Boss 2"),
    MIRROR_BOSS_2_NOINTRO = Isaac.GetMusicIdByName("Mirror Boss 2 No Intro"),
    MIRROR_BOSS_2_OUTRO = Isaac.GetMusicIdByName("Mirror Boss 2 Outro"),

    ELITE2 = Isaac.GetMusicIdByName("Tomb Elite"),
    ELITE_RAGTIME = REVEL.GetMusicAndCues("Tomb Elite Ragtime", "revel2.tomb_elite_boss_ragtime"),
})

StageAPI.StopOverridingMusic(REVEL.SFX.MIRROR_BOSS_2_OUTRO)

--------------
-- COSTUMES --
--------------
REVEL.mixin(REVEL.COSTUME, {
    GUT = {
        SUCK_S = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_suckstart.anm2"),
        SUCK = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_suck.anm2"),
        SUCK_E = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_suckend.anm2"),
        CHEW = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_chew.anm2"),
        SPIT = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_spit.anm2"),
        SWALLOW = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_gluttonsgut_swallow.anm2")
    },

    CURSED_GRAIL = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_cursedgrail.anm2"),

    HALF_CHEWED_PONY = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_half_chewed_pony.anm2"),

    WRATHS_RAGE2 = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_wrathsrage2.anm2"),
    WRATHS_RAGE3 = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_wrathsrage3.anm2"),
    WRATHS_RAGE4 = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_wrathsrage4.anm2"),
})

--------------
-- ENTITIES --
--------------
REVEL.mixin(REVEL.ENT, {
    -- Bosses --
    CATASTROPHE_CRICKET = REVEL.ent("Cricket (boss)"),
    CATASTROPHE_TAMMY = REVEL.ent("Tammy (boss)"),
    CATASTROPHE_GUPPY = REVEL.ent("Guppy (boss)"),
    CATASTROPHE_MOXIE = REVEL.ent("Moxie (boss)"),
    CATASTROPHE_YARN = REVEL.ent("Catastrophe Yarn (Spawner)"),

    ARAGNID = REVEL.ent("Aragnid"),
    ARAGNID_INNARD = REVEL.ent("Aragnid Innard", {
        NoChampion = true,
    }),
    ARAGNID_RAGS = REVEL.ent("Aragnid Rags", {
        NoChampion = true,
        NoHurtWisps = true,
    }),

    MAXWELL = REVEL.ent("Maxwell"),
    MAXWELL_DOOR = REVEL.ent("Yeller Door", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    MAXWELL_TRAP = REVEL.ent("Maxwell Trapdoor", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    MAXWELL_BUBBLE = REVEL.ent("Maxwell Bubble", {
        NoChampion = true,
    }),

    NARCISSUS_2 = REVEL.ent("Narcissus 2"),
    MEGASHARD = REVEL.ent("Megashard", {
        NoChampion = true,
    }),
    GLASS_SPIKE = REVEL.ent("Glass Spike", {
        NoChampion = true,
    }),
    NARCISSUS_2_NPC = REVEL.ent("Narcissus 2 Generic NPC", {
        NoChampion = true,
    }),
    NARCISSUS_2_EFFECT = REVEL.ent("Narcissus 2 Generic Effect"),

    SARCOPHAGUTS = REVEL.ent("Sarcophaguts"),
    SARCOPHAGUTS_HEAD = REVEL.ent("Sarcophaguts Head"),
    SARCGUT = REVEL.ent("Sarcgut"),

    SANDY = REVEL.ent("Sandy"),
    JEFFREY_BABY = REVEL.ent("Jeffrey"),

    DUNGO = REVEL.ent("Dungo"),
    POOP_BOULDER = REVEL.ent("Poop Boulder", {
        NoChampion = true,
        NoHurtWisps = true,
    }),

    RAGTIME = REVEL.ent("Ragtime"),
    RAG_DANCER = REVEL.ent("Rag Dancer", {
        NoChampion = true,
    }),

    --Enemies
    RAG_TAG = REVEL.ent("Rag Tag"),
    ARROWHEAD = REVEL.ent("Arrowhead"),
    RAG_GAPER = REVEL.ent("Rag Gaper"),
    RAG_GAPER_HEAD = REVEL.ent("Rag Gaper (Head)"),
    RAG_GUSHER = REVEL.ent("Rag Gusher"),
    SANDBOB = REVEL.ent("Sandbob"),
    SANDBIP = REVEL.ent("Sandbip"),
    DEMOBIP = REVEL.ent("Demobip"),
    BLOATBIP = REVEL.ent("Bloatbip"),
    CANNONBIP = REVEL.ent("Cannonbip"),
    CANNONBIP_PROJECTILE = REVEL.ent("Cannonbip", {
        SubType = 10,
        NoChampion = true,
    }),
    SNIPEBIP = REVEL.ent("Snipebip"),
    TRENCHBIP = REVEL.ent("Trenchbip"),
    ANTLION = REVEL.ent("Antlion"),
    PYRAMID_HEAD = REVEL.ent("Pyramid Head"),
    RAG_TRITE = REVEL.ent("Rag Trite"),
    ANIMA = REVEL.ent("Anima", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    LOCUST = REVEL.ent("Locust"),
    RAG_BONY = REVEL.ent("Rag Bony"),
    INNARD = REVEL.ent("Innard"),
    NECRAGMANCER = REVEL.ent("Necragmancer"),
    NECRAGMANCER_NO_SHUT_DOORS = REVEL.ent("Necragmancer No Shut Doors"),
    WRETCHER = REVEL.ent("Wretcher"),
    SANDSHAPER = REVEL.ent("Sandshaper"),
    URNY = REVEL.ent("Urny", {
        NoChampion = true,
    }),
    RAG_FATTY = REVEL.ent("Rag Fatty"),
    FIRECALLER = REVEL.ent("Firecaller (Tomb)"),
    FIRECALLER_GLACIER = REVEL.ent("Firecaller (Glacier)"),
    SAND_WORM = REVEL.ent("Sand Worm"),
    SKITTER_G = REVEL.ent("Skitterpill Good", {
        NoChampion = true,
    }),
    SKITTER_B = REVEL.ent("Skitterpill Bad", {
        NoChampion = true,
    }),
    PEASHY = REVEL.ent("Peashy"),
    PEASHY_NAIL = REVEL.ent("Peashy Nail", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    STONE_CREEP = REVEL.ent("Stone Creep", {
        NoChampion = true,
    }),
    BUTTON_MASHER = REVEL.ent("Button Masher", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    SLAMBIP = REVEL.ent("Slambip"),
    TILE_MONGER = REVEL.ent("Tile Monger"),
    RAG_DRIFTY = REVEL.ent("Rag Drifty"),
    PSEUDO_RAG_DRIFTY = REVEL.ent("Pseudo Rag Drifty"),
    ANTLION_BABY = REVEL.ent("Antlion Baby"),
    ANTLION_EGG = REVEL.ent("Antlion Egg"),
    LOVERS_LIB_PD = REVEL.ent("Lovers Libido Pedestal", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    SKITTER_C = REVEL.ent("Skitterpill Card", {
        NoChampion = true,
    }),
    JACKAL = REVEL.ent("Jackal"),
    JACKAL_GILDED = REVEL.ent("Gilded Jackal", 41),
    STABSTACK = REVEL.ent("Stabstack", {
        NoChampion = true,
    }),
    STABSTACK_PIECE = REVEL.ent("Stabstack Piece", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    STABSTACK_ROLLING = REVEL.ent("Stabstack Rolling Piece", {
        NoChampion = true,
    }),
    RAGMA = REVEL.ent("Ragma"),
    DUNE = REVEL.ent("Dune"),

    --Effects
    REVIVAL_RAG = REVEL.ent("Revival Rag"),
    CHUM = REVEL.ent("Chum"),
    ROBOT = REVEL.ent("Cardboard Robot"),
    PYRAMID_HEAD_TRIANGLE = REVEL.ent("Purple Triangle"),
    WAKAWAKA_FRUIT = REVEL.ent("Waka Waka Fruit"),
    VIRGIL_W = REVEL.ent("Virgil Waiting"),
    ARROW_TRAP = REVEL.ent("Arrow Trap"),
    CORNER_COFFIN = REVEL.ent("Corner Coffin"),
    SAND_BOULDER = REVEL.ent("Sand Boulder"),
    FLAME_TRAP = REVEL.ent("Flame Trap"),
    FLAME_TRAP_FIRE = REVEL.ent("Flame Trap Fire"),
    CORNER_BRAZIER = REVEL.ent("Corner Brazier"),
    MUSIC_BOX = REVEL.ent("Music Box"),
    HALF_CHEWED_PONY = REVEL.ent("Half Chewed Pony Effect"),
    BANDAGE_BABY_BALL = REVEL.ent("Bandage Baby Ball"),
    OPHANIM = REVEL.ent("Ophanim"),
    MOXIE_YARN_BALL = REVEL.ent("Moxie's Yarn Ball"),
    MOXIE_YARN_CAT = REVEL.ent("Moxie's Yarn Cat"),
    SAND_FOOTPRINT = REVEL.ent("Sand Footprint"),
    SPRING_MANAGER = REVEL.ent("Revelations Spring Manager"),
    SAND_HOLE = REVEL.ent("Sand Hole"),
    ANTLION_SUCK = REVEL.ent("Antlion Suck Effect"),
    BRIM_TRAP = REVEL.ent("Brimstone Trap"),
    RAGMA_HELPER = REVEL.ent("Helper for Ragma"),

    --Familiars
    VIRGIL = REVEL.ent("Virgil"),
    GHOST = REVEL.ent("Ghastly Ghost"),
    PHYLACTERY_OLD = REVEL.ent("Phylactery Old"),
    PHYLACTERY = REVEL.ent("Phylactery"),
    CABBAGE = REVEL.ent("Cabbage"),
    ANGRY_GEMINI = REVEL.ent("Angry Gemini Familiar"),
    MIRROR2 = REVEL.ent("Mirror Fragment"),
    CURSED_GRAIL = REVEL.ent("Cursed Grail"),
    BANDAGE_BABY = REVEL.ent("Bandage Baby"),
    LIL_MICHAEL = REVEL.ent("Lil Michael"),
    HUNGRY_GRUB = REVEL.ent("Hungry Grub"),
    ANTLION_CHEWED_PONY = REVEL.ent("Antlion Familiar"),
    ENVYS_ENMITY_HEAD_1 = REVEL.ent("Envy's Enmity Head"),
    ENVYS_ENMITY_HEAD_2 = REVEL.ent("Envy's Enmity Head 2"),
    ENVYS_ENMITY_HEAD_3 = REVEL.ent("Envy's Enmity Head 3"),
    ENVYS_ENMITY_HEAD_4 = REVEL.ent("Envy's Enmity Head 4"),
    LIL_CHARGER = REVEL.ent("Lil' Charger"),
    BARG_BURD = REVEL.ent("Bargainer's Bag"),
    WILLO = REVEL.ent("Willo Familiar"),

    --Other
    SAND_CASTLE = REVEL.ent("Sand Castle"),
    FLAMING_TOMB = REVEL.ent("Flaming Tomb"),
})

REVEL.RAG_FAMILY = {
  [REVEL.ENT.RAG_TRITE.id] = {REVEL.ENT.RAG_TRITE.variant},
  [REVEL.ENT.RAG_TAG.id] = {REVEL.ENT.RAG_TAG.variant},
  [REVEL.ENT.RAG_GAPER.id] = {REVEL.ENT.RAG_GAPER.variant},
  [REVEL.ENT.RAG_GUSHER.id] = {REVEL.ENT.RAG_GUSHER.variant},
  [REVEL.ENT.RAG_BONY.id] = {REVEL.ENT.RAG_BONY.variant},
  [REVEL.ENT.WRETCHER.id] = {REVEL.ENT.WRETCHER.variant},
  [REVEL.ENT.RAG_FATTY.id] = {REVEL.ENT.RAG_FATTY.variant},
  [REVEL.ENT.RAG_DRIFTY.id] = {REVEL.ENT.RAG_DRIFTY.variant},
  [REVEL.ENT.RAGMA.id] = {REVEL.ENT.RAGMA.variant},
}

------------------
-- GRIDENTITIES --
------------------
REVEL.mixin(REVEL.GRIDENT, {
    SAND_CASTLE = StageAPI.CustomGrid("SandCastle", {
		BaseType = GridEntityType.GRID_POOP, 
		Anm2 = "gfx/grid/revel2/sand_castle.anm2", 
		Animation = "Default", 
		OverrideGridSpawns = true, 
		OverrideGridSpawnsState = GridBreakState.BROKEN_POOP,
	}),
    FLAMING_TOMB = StageAPI.CustomGrid("Flaming Tomb", {
        BaseType = GridEntityType.GRID_PILLAR,
        -- Anm2 = "gfx/blank.anm2",
    }),
})

---------------------------
-- STAGEAPI METAENTITIES --
---------------------------

StageAPI.AddMetadataEntities({
    [789] = {
        -- Traps
        [6] = {
            Name = "ArrowTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [7] = {
            Name = "CoffinTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [8] = {
            Name = "BoulderTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [11] = {
            Name = "FlameTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [12] = {
            Name = "SpikeTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [13] = {
            Name = "SpikeTrapOffset",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [15] = {
            Name = "RevivalTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [16] = {
            Name = "BombTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [17] = {
            Name = "BrimstoneTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },

        -- Trap Stackable Modifiers
        [9] = {
            Name = "ObviousTrap"
        },
        [10] = {
            Name = "ForcedTrap"
        },
        [14] = {
            Name = "BadTrap"
        },


        --[[
        -- Removed due to StageAPI metaentity changes
        -- Legacy Direction Modifiers (should behave 100% identically to stageapi modifiers)
        [1] = {
            Name = "Left",
            Group = "Direction",
            ConflictTag = true,
            PreventConflictWith = "PreventDirectionConflict"
        },
        [2] = {
            Name = "Right",
            Group = "Direction",
            ConflictTag = true,
            PreventConflictWith = "PreventDirectionConflict"
        },
        [3] = {
            Name = "Up",
            Group = "Direction",
            ConflictTag = true,
            PreventConflictWith = "PreventDirectionConflict"
        },
        [4] = {
            Name = "Down",
            Group = "Direction",
            ConflictTag = true,
            PreventConflictWith = "PreventDirectionConflict"
        },
        ]]

        -- Extra Metadata
        [50] = {
            Name = "FlameTrapAlwaysActive",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [51] = {
            Name = "FlameTrapTimed",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [52] = {
            Name = "FlameTrapTimedOffset",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [53] = {
            Name = "SpikeTrapSpike",
            Tags = {
                "SpikeTrap"
            },
        },
        [54] = {
            Name = "SpikeTrapSpikeOffset",
            Tags = {
                "SpikeTrap"
            },
        },
        [55] = {
            Name = "BrimstoneTrapTimed",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [56] = {
            Name = "BrimstoneTrapTimedOffset",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [75] = {
            Name = "CoffinBlocker"
        },
        [76] = {
            Name = "RevivalRag"
        },
        [77] = {
            Name = "BoulderOffset"
        },
        [78] = {
            Name = "DisableOnClear"
        },
        [79] = {
            Name = "BrazierBlocker"
        },
        [90] = {
            Name = "ReducedHP"
        },
        [91] = {
            Name = "Championizer"
        },
        [92] = {
            Name = "NoChampion"
        },
        -- [93] = {
        --     Name = "PlayerStartPos"
        -- },
    },
    [199] = {
        [760] = {
            Name = "TrapUnknown"
        },
        [780] = {
            Name = "CoffinPacker",
            BlockEntities = true
        },
        [781] = {
            Name = "RevivalTear"
        },
        [782] = {
            Name = "AntlionAutoemerge"
        },
        [783] = {
            Name = "TileMongerTile"
        },
        [784] = {
            Name = "BombTrapBomb"
        },
        [785] = {
            Name = "ExtraItemSpawn"
        },
        [786] = {
            Name = "ExtinguishableFire"
        },
        [787] = {
            Name = "Anima"
        },
        [750] = {
            Name = "RagtimeBoxDance",
            Tags = {
                "RagtimeDanceCore",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                JumpRotation = {Offset = 8, Length = 2},
            },
        },
        [751] = {
            Name = "RagtimeBoxDancePoint",
            Tags = {
                "RagtimeDanceExtra",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                JumpRotation = {Offset = 8, Length = 2},
            },
        },
        [752] = {
            Name = "RagtimeConga",
            Tags = {
                "RagtimeDanceCore",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                Direction = {Offset = 8, Length = 3},
            },
        },
        [753] = {
            Name = "RagtimeCongaPoint",
            Tags = {
                "RagtimeDanceExtra",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                Direction = {Offset = 8, Length = 3},
                IsEnd = {Offset = 11, Length = 1},
            },
        },
        [754] = {
            Name = "RagtimePlayerSafeSpot",
            Tags = {
                "Ragtime"
            },
        },
        [755] = {
            Name = "Dune Tile",
        },
        [756] = {
            Name = "Flaming Tomb",
            BitValues = {
                Rotation = {Offset = 0, Length = 2},
                Decorative = {Offset = 2, Length = 1},
            },        
        },
    },
    
    --ID-Less, added via code not room editor
    PrankSpawnPoint = {
        Name = "PrankSpawnPoint"
    },
})

-----------------
-- UNLOCKABLES --
-----------------
REVEL.mixin(REVEL.UNLOCKABLES, {
    BANDAGE_BABY = REVEL.unlockable("revel2/bandage_baby.png", REVEL.ITEM.BANDAGE_BABY.id, "beat tomb", "bandage baby"),
    BROKEN_OAR = REVEL.unlockable("revel2/broken_oar.png", REVEL.ITEM.CHARONS_OAR.id, "dante vs mom", "broken oar"),
    DEATH_MASK = REVEL.unlockable("revel2/death_mask.png", REVEL.ITEM.DEATH_MASK.id, "dante vs mom's heart", "death mask"),
    OPHANIM = REVEL.unlockable("revel2/ophanim.png", REVEL.ITEM.OPHANIM.id, "sarah vs mom's heart", "ophanim"),
    LIL_MICHAEL = REVEL.unlockable("revel2/lil_michael.png", REVEL.ITEM.LIL_MICHAEL.id, "sarah vs hush", "lil michael"),
    PILGRIMS_WARD = REVEL.unlockable("revel2/pilgrims_ward.png", REVEL.ITEM.PILGRIMS_WARD.id, "sarah vs ???", "pilgrim's ward"),
    FERRYMANS_TOLL = REVEL.unlockable("revel2/ferrymans_toll.png", REVEL.ITEM.FERRYMANS_TOLL.id, "dante vs ???", "ferryman's toll"),
    GHASTLY_FLAME = REVEL.unlockable("revel2/ghastly_flame.png", REVEL.ITEM.GFLAME.id, "dante vs the lamb", "ghastly flame"),
    WANDERING_SOUL = REVEL.unlockable("revel2/wandering_soul.png", REVEL.ITEM.WANDERING_SOUL.id, "dante vs hush", "wandering soul"),
    MIRROR_BOMBS = REVEL.unlockable("revel2/mirror_bombs.png", REVEL.ITEM.MIRROR_BOMBS.id, "beat my reflection", "mirror bombs"),
    MAX_HORN = REVEL.unlockable("revel2/maxwells_horn.png", REVEL.ITEM.MAX_HORN.id, "beat craxwell", "maxwell's horn", nil, true),
    WILLO = REVEL.unlockable("revel2/willo.png", REVEL.ITEM.WILLO.id, "choose radiance", "willo"),

    TOMB_CHAMPIONS = REVEL.unlockable("revel2/tombchampion.png", nil, "beat tomb bosses", "champions", {sprite = "gfx/ui/achievement/revel2/tomb_champions_icon.png", width = 34, height = 30, scaleX = 2, scaleY = 2}),
})

Isaac.DebugString("Revelations: Loaded Definitions for Chapter 2!")
end
REVEL.PcallWorkaroundBreakFunction()