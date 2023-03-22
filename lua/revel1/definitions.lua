local GridBreakState = require "lua.revelcommon.enums.GridBreakState"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------
-- ALL ENTITIES --
------------------
REVEL.mixin(REVEL.ENT, {
    -- Bosses --
    FREEZER_BURN = REVEL.ent("Freezer Burn"),
    FREEZER_BURN_HEAD = REVEL.ent("Freezer Burn Head"),
    MONSNOW = REVEL.ent("Monsnow"),
    DUKE_OF_FLAKES = REVEL.ent("Duke of Flakes"),
    STALAGMITE = REVEL.ent("Stalagmight"),
    STALAGMITE_SPIKE = REVEL.ent("Stalagmight Spike", {
        NoChampion = true,
    }),
    STALAGMITE_2 = REVEL.ent("Stalagmight 2"),
    WILLIWAW = REVEL.ent("Williwaw"),
    NARCISSUS = REVEL.ent("Narcissus"),
    NARCISSUS_MONSTROS_TOOTH = REVEL.ent("Monstro's Tooth (Narcissus Fight)", {
        NoChampion = true,
    }),
    NARCISSUS_DOCTORS_TARGET = REVEL.ent("Doctor's Target (Narcissus Fight)", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    NARCISSUS_DOCTORS_ROCKET = REVEL.ent("Doctor's Rocket (Narcissus Fight)", {
        NoChampion = true,
    }),
    CUSTOM_SHOCKWAVE = REVEL.ent("Revelations Custom Shockwave"),
    FLURRY_HEAD = REVEL.ent("Flurry Head"),
    FLURRY_BODY = REVEL.ent("Flurry Body"),
    FLURRY_FROZEN_BODY = REVEL.ent("Flurry Frozen Body"),
    FLURRY_ICE_BLOCK = REVEL.ent("Flurry Ice Block", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    FLURRY_ICE_BLOCK_YELLOW = REVEL.ent("Flurry Ice Block Yellow", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    FROST_RIDER = REVEL.ent("Frost Rider"),
    FROST_RIDER_HEAD = REVEL.ent("Frost Rider Phase 2"),
    ICE_POOTER = REVEL.ent("Ice Pooter", {
        NoChampion = true,
    }),

    CHUCK = REVEL.ent("Chuck"),
    CHUCK_ICE_BLOCK = REVEL.ent("Chuck Ice Block", {
        NoChampion = true,
    }),
  
	WENDY = REVEL.ent("Wendy"),
	WENDY_SNOWPILE = REVEL.ent("Wendy SnowPile", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
	WENDY_STALAGMITE = REVEL.ent("Wendy Stalagmite", {
        NoChampion = true,
        NoHurtWisps = true,
    }),

    PRONG = REVEL.ent("Prong"),
    PRONG_STATUE = REVEL.ent("Prong Statue", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    PRONG_ICE_BOMB = REVEL.ent("Prong Ice Bomb", {
        NoChampion = true,
        NoHurtWisps = true,
    }),

    -- Enemies --
    SNOW_FLAKE = REVEL.ent("Snow Flake", {
        NoChampion = true,
    }),
    SNOW_FLAKE_BIG = REVEL.ent("Big Snow Flake", {
        NoChampion = true,
    }),
    STALACTITE = REVEL.ent("Ice Stalactite", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    STALACTITE_SMALL = REVEL.ent("Smallactite", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    FROZEN_SPIDER = REVEL.ent("Iced Spider"),
    YELLOW_FROZEN_SPIDER = REVEL.ent("Yellow Iced Spider"),
    SNOWBALL = REVEL.ent("Snowball"),
    BLOCKHEAD = REVEL.ent("Blockhead", {
        NoChampion = true,
    }),
    CARDINAL_BLOCKHEAD = REVEL.ent("Cardinal Blockhead", {
        NoChampion = true,
    }),
    YELLOW_BLOCKHEAD = REVEL.ent("Yellow Blockhead", {
        NoChampion = true,
    }),
    YELLOW_CARDINAL_BLOCKHEAD = REVEL.ent("Yellow Cardinal Blockhead", {
        NoChampion = true,
    }),
    BLOCK_GAPER = REVEL.ent("Block Gaper"),
    CARDINAL_BLOCK_GAPER = REVEL.ent("Cardinal Block Gaper"),
    YELLOW_BLOCK_GAPER = REVEL.ent("Yellow Block Gaper"),
    YELLOW_CARDINAL_BLOCK_GAPER = REVEL.ent("Yellow Cardinal Block Gaper"),
    BLOCK_BLOCK_BLOCK_GAPER = REVEL.ent("Block Block Block Gaper"),
    GEICER = REVEL.ent("Geicer"),
    HICE = REVEL.ent("Hice"),
    CLOUDY = REVEL.ent("Cloudy"),
    BRAINFREEZE = REVEL.ent("Brainfreeze"),
    ROLLING_SNOWBALL = REVEL.ent("Rolling Snowball"),
    ROLLING_SNOTBALL = REVEL.ent("Snot Rocket"),
    SNOWBOB = REVEL.ent("Snowbob"),
    SNOWBOB_HEAD = REVEL.ent("Snowbob Head", {
        NoChampion = true,
    }),
    SNOWBOB_HEAD2 = REVEL.ent("Snowbob Head (Tears)", {
        NoChampion = true,
    }),
    FATSNOW = REVEL.ent("Fatsnow"),
    CHILL_O_WISP = REVEL.ent("Chill O' Wisp", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    GRILL_O_WISP = REVEL.ent("Grill O' Wisp", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_WRAITH = REVEL.ent("Ice Wraith", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_WRAITH_BODY = REVEL.ent("Ice Wraith", {
        SubType = 1,
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICED_HIVE = REVEL.ent("Iced Hive"),
    STALACTRITE = REVEL.ent("Stalactrite", {
        NoChampion = true,
    }),
    ICE_WORM = REVEL.ent("Ice Worm"),
    YELLOW_SNOW = REVEL.ent("Yellow Snow"),
    YELLOW_SNOWBALL = REVEL.ent("Yellow Snowball"),
    STRAWBERRY_SNOWBALL = REVEL.ent("Strawberry Snowball"),
    SICKIE = REVEL.ent("Sickie"),
    BIG_BLOWY = REVEL.ent("Big Blowy", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    IGLOO = REVEL.ent("Igloo", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    FROST_SHOOTER = REVEL.ent("Frost Shooter", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    DRAUGR = REVEL.ent("Draugr"),
    HAUGR = REVEL.ent("Haugr"),
    JAUGR = REVEL.ent("Jaugr"),
    JUNIAUGR = REVEL.ent("Juniaugr"),
    SASQUATCH = REVEL.ent("Sasquatch"),
    ICE_BLOCK = REVEL.ent("Ice Block", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    AVALANCHE = REVEL.ent("Avalanche", {
        NoChampion = true,
    }),
    SNOWST = REVEL.ent("Snowst"),
    HOCKEY_PUCK = REVEL.ent("Hockey Puck", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    SHY_FLY = REVEL.ent("Shy Fly", {
        NoChampion = true,
    }),
    CRYO_FLY = REVEL.ent("Cryo Fly", {
        NoChampion = true,
    }),
    HUFFPUFF = REVEL.ent("Huffpuff"),
    TUSKY = REVEL.ent("Tusky", {
        NoChampion = true,
    }),
    EMPEROR = REVEL.ent("Emperor"),
	COAL_HEATER = REVEL.ent("Coal Heater"),
	COAL_SHARD = REVEL.ent("Coal Shard", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    HARFANG = REVEL.ent("Harfang"),
    PINE = REVEL.ent("Pine"),
    PINECONE = REVEL.ent("Pinecone"),

    -- Ice Hazard variants --
    ICE_HAZARD_GAPER = REVEL.ent("Ice Hazard Gaper", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_HORF = REVEL.ent("Ice Hazard Horf", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_HOPPER = REVEL.ent("Ice Hazard Hopper", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_DRIFTY = REVEL.ent("Ice Hazard Drifty", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_CLOTTY = REVEL.ent("Ice Hazard Clotty", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_BROTHER = REVEL.ent("Ice Hazard Brother Bloody", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_BOMB = REVEL.ent("Ice Hazard Troll Bomb", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_IBLOB = REVEL.ent("Ice Hazard I.Blob", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    ICE_HAZARD_EMPTY = REVEL.ent("Ice Hazard Empty", {
        NoChampion = true,
        NoHurtWisps = true,
    }),

    -- Familiars --
    MIRRORSHARD = REVEL.ent("Mirror Shard"),
    LIL_BELIAL = REVEL.ent("Lil Belial"),
    LIL_FRIDER = REVEL.ent("Lil Frost Rider"),
    SOUL = REVEL.ent("Soul"),

    -- Projectiles --
    TRAY_PROJECTILE = REVEL.ent("Tray Projectile", 155),

    -- Effects --
    ICE_CREEP = REVEL.ent("Ice Creep"),
    MONOLITH = REVEL.ent("Monolith"),
    AEGIS = REVEL.ent("Aegis"),
    GLOW_EFFECT = REVEL.ent("Revel Glow Effect1"),
    DECORATION = REVEL.ent("Revel Decoration1"),
    SNOW_PARTICLE = REVEL.ent("Snow Particle"),
    REF_MAN = REVEL.ent("Reflection Manager"),
    ITEM_SPAWN_HELPER = REVEL.ent("Item Spawn Helper"),
    TRINKET_SPAWN_HELPER = REVEL.ent("Trinket Spawn Helper"),
    LIGHTABLE_FIRE = REVEL.ent("Lightable Fire", {
        NoChampion = true,
        NoHurtWisps = true,
    }),
    SNOW_TILE_RENDERER = REVEL.ent("Snow Tile Renderer"),
})


----------------------
-- ALL GRIDENTITIES --
----------------------
REVEL.mixin(REVEL.GRIDENT, {
    BRAZIER = StageAPI.CustomGrid("Brazier", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "gfx/effects/revel1/brazier.anm2", 
		Animation = "Flickering",
        SpawnerEntity = {
            Type = 656,
            Variant = 6,
        },
	}),
    FRAGILE_ICE = StageAPI.CustomGrid("Fragile Ice", {
		BaseType = GridEntityType.GRID_DECORATION, 
		Anm2 = "gfx/grid/revel1/ice_crack.anm2", 
		Animation = "Start",
		ForceSpawning = true
	}),
    TOUGH_ICE = StageAPI.CustomGrid("Tough Ice", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "gfx/effects/revel1/tough_ice.anm2", 
		Animation = "Idle", 
		Frame = 1, 
		VariantFrames = 4,
        SpawnerEntity = {
            Type = 656,
            Variant = 7,
        },
	}),
    EXPLODING_SNOWMAN = StageAPI.CustomGrid("Exploding Snowman", {
		BaseType = GridEntityType.GRID_POOP, 
		Anm2 = "gfx/grid/revel1/exploding_snowman.anm2", 
		Animation = "Idle", 
		OverrideGridSpawns = true, 
		OverrideGridSpawnsState = GridBreakState.BROKEN_POOP,
        SpawnerEntity = {
            Type = 199,
            Variant = 740,
        }
	}),
    FROZEN_BODY = StageAPI.CustomGrid("Inferno Frozen Body", {
        BaseType = GridEntityType.GRID_ROCK_ALT,
        Anm2 = "gfx/grid/revel1/frozen_bodies.anm2",
        Animation = "Bodies",
        VariantFrames = 12,
        OverrideGridSpawns = true,
        OverrideGridSpawnsState = GridBreakState.BROKEN_ROCK,
        SpawnerEntity = {
            Type = 199,
            Variant = 741,
        },
    }),
})

---------------------------
-- STAGEAPI METAENTITIES --
---------------------------

StageAPI.AddMetadataEntities{
    [625] = {
        [274] = {
            Name = "Ice Pit",
        },
        [275] = {
            Name = "Fragile Ice Pit",
        },
        [276] = {
            Name = "No Fragility Forced Ice",
        },
    },
    [770] = { --metadata for handier check (ice blocks are always the same entity)
        [1011] = {
            Tags = {"ChuckIceBlock"},
            Name = "Chuck Ice Block (Cracked)",
        },
        [1012] = {
            Tags = {"ChuckIceBlock"},
            Name = "Chuck Ice Sphere",
        },
    },
    [789] = {
        [150] = {
            Name = "AlwaysOnStalagSpike",
        },
    },
    [199] = {
        [742] = {
            Name = "Dante Mega Satan",
        },
        [787] = {
            Name = "Tusky Random Rider (Or no rider)",
            Tags = {
                "TuskyRider"
            }
        },
        [788] = {
            Name = "Tusky Random Rider (Force)",
            Tags = {
                "TuskyRider"
            }
        },
    },
    --ID-Less, added via code not room editor
    TuskySpecificRider = {
        Name = "TuskySpecificRider",
        Tags = {
            "TuskyRider"
        }
    },
    AvalancheSpawnData = {
        Name = "AvalancheSpawnData",
    },
}

------------------
-- ALL COSTUMES --
------------------
REVEL.mixin(REVEL.COSTUME, {
    DYNAMO_ALT = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/dynamo_alt.anm2"),
    BURNING_BUSH_NOFIRE = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush_nofire.anm2"),
    BURNBUSH = {
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush1.anm2"),
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush2.anm2"),
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush3.anm2"),
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush4.anm2"),
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/bbush_fire_head.anm2")
    },
    PATIENCE = {
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/spiritofpatience_opening.anm2"),
        Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/spiritofpatience_active.anm2")
    }
})

-------------
-- ALL SFX --
-------------
REVEL.mixin(REVEL.SFX, {
    -- Sounds
    BELL = {
        REVEL.registerSound("REV Secret Bell"),
        REVEL.registerSound("REV Machine Bell"),
        REVEL.registerSound("REV Penny Bell"),
        REVEL.registerSound("REV Boss Bell"),
        REVEL.registerSound("REV Blue Baby Bell"),
        REVEL.registerSound("REV Keeper Bell")
    },

    NARC = {
        BREAK = REVEL.registerSound("REV Narc Break"),
        CRACK = REVEL.registerSound("REV Narc Crack"),
        GATHER = REVEL.registerSound("REV Narc Gather"),
        ROAR = REVEL.registerSound("REV Narc Roar"),
        ROAR_S = REVEL.registerSound("REV Narc Roar Short"),
        STOMP = REVEL.registerSound("REV Narc Stomp"),
        HOLY = REVEL.registerSound("REV Narc Holy"),
        POWERUP = REVEL.registerSound("REV Narc Powerup"),
    },

    GLACIER_DOOR_OPEN = REVEL.registerSound("REV Glacier Door Opens"),
    MINT_GUM_BREAK = REVEL.registerSound("REV Mint Gum Break", 0.8),
    MINT_GUM_FREEZE = REVEL.registerSound("REV Mint Gum Freeze", 0.8),
    FIRE_START = REVEL.registerSound("REV Fire Start"),
    FIRE_LOOP = REVEL.registerSound("REV Fire Loop"),
    FIRE_END = REVEL.registerSound("REV Fire End"),
    MOUTH_PULL = REVEL.registerSound("REV Mouth Pull"),
    GLASS_BREAK = REVEL.registerSound("REV Glass Break"),
    ELECTRICAL_EXPLOSION = REVEL.registerSound("REV Electrical Explosion"),
    MONOLITH_TEAR_CONVERT = REVEL.registerSound("REV Monolith Tear Convert"),
    SPONGE_SUCK = REVEL.registerSound("REV Sponge Suck"),
    SPONGE_WATER_EXPLOSION = REVEL.registerSound("REV Sponge Water Explosion"),
    FECAL_FREAK_FART = REVEL.registerSound("REV Fecal Freak Fart"),
    TUMMY_BUG_VOMIT = REVEL.registerSound("REV Tummy Bug Vomit"),
    HYPER_DICE = REVEL.registerSound("REV Hyper Dice"),
    SPIRIT_OF_PATIENCE_OPEN_EYE = REVEL.registerSound("REV Spirit of Patience Open Eye"),
    LIL_BELIAL_KILL = REVEL.registerSound("REV Lil Belial Kill"),
    LIL_BELIAL_REWARD = REVEL.registerSound("REV Lil Belial Reward"),
    SNOWBALL_BREAK = REVEL.registerSound("REV Snowball Break"),
    SNOWBALL = REVEL.registerSound("REV Snowball Roll"),
    SNOWSTORM = REVEL.registerSound("REV Snowstorm"),
    INHALE = REVEL.registerSound("REV Inhale"),
    YELLOWSNOW_CRAWL = REVEL.registerSound("REV Yellow Snow Crawl"),
    YELLOWSNOW_RELIEF = REVEL.registerSound("REV Yellow Snow Relief"),
    ICE_CRACK = REVEL.registerSound("REV Ice Crack"),
    BRAINFREEZE = {
        ATTACK = REVEL.registerSound("REV Brainfreeze Attack", 0.66),
        BUL_STOP = REVEL.registerSound("REV Brainfreeze Bulletstop", 0.66),
        DEAD = REVEL.registerSound("REV Brainfreeze Dead", 0.66),
        AURA_LOOP = REVEL.registerSound("REV Brainfreeze Aura Loop", 0.66),
        CHARGE = REVEL.registerSound("REV Brainfreeze Charge", 0.66)
    },
    ICE_WORM_BOUNCE = REVEL.registerSound("REV Ice Worm Bounce"),
    FLAME_BURST = REVEL.registerSound("REV Flame Burst"),
    STALAG_SPIKES = REVEL.registerSound("REV Stalagmight Spikes"),
    STALAG_STALAGMITE = REVEL.registerSound("REV Stalagmight Stalagmite"),
    HOCKEY_HIT = REVEL.registerSound("REV Hockey Hit"),
    EMPEROR_ANGRY = REVEL.registerSound("REV Emperor Angry"),
    CHUCK = {
        JUMP = REVEL.registerSound("REV Chuck Jump"),
        LIFT = REVEL.registerSound("REV Chuck Lift"),
        LAUGH = REVEL.registerSound("REV Chuck Laugh"),
        BONK = REVEL.registerSound("REV Chuck Bonk"),
        OW = REVEL.registerSound("REV Chuck Ow"),
        DEAD = REVEL.registerSound("REV Chuck Dead"),
        ANGRY = REVEL.registerSound("REV Chuck Angry"),
    },
    BIRD_STUN = REVEL.registerSound("REV Bird Stun"),
    SNOWSTORM_LOOP = REVEL.registerSound("REV Snowstorm Loop"),
    WIND_LOOP = REVEL.registerSound("REV Wind Loop"),
    WINDSTRONG_LOOP = REVEL.registerSound("REV Strong Wind Loop"),
    WATER_SPLASH = REVEL.registerSound("REV Water Splash"),
    WATER_SPLASH_HEAVY = REVEL.registerSound("REV Water Splash Heavy"),
    ICE_BREAK_LARGE = REVEL.registerSound("REV Ice Break Large", 0.8),
    ICE_BUMP = REVEL.registerSound("REV Ice Bump"),
    SNOW_STEP = REVEL.registerSound("REV Snow Step"),
    LOW_FREEZE = REVEL.registerSound("REV Low Freeze"),
    BURP_LONG = REVEL.registerSound("REV Burp Long"),
    PRONG = {
        SMILE = REVEL.registerSound("REV Prong Smile"),
        THROW = REVEL.registerSound("REV Prong Throw"),
        TELEKINESIS = REVEL.registerSound("REV Prong Telekinesis"),
        REFREEZE1 =  REVEL.registerSound("REV Prong Refreeze 1"),
        REFREEZE2 =  REVEL.registerSound("REV Prong Refreeze 2"),
        TIRED = REVEL.registerSound("REV Prong Tired"),
        DEATH1 = REVEL.registerSound("REV Prong Death 1"),
        DEATH2 = REVEL.registerSound("REV Prong Death 2"),
        DEATH3 = REVEL.registerSound("REV Prong Death 3"),
    },
    DRAUGR = REVEL.registerSound("REV Draugr Idle"),
    JAUGR_HIT = REVEL.registerSound("REV Jaugr Hit"),
    JAUGR_LAUGH = REVEL.registerSound("REV Jaugr Laugh"),
    JAUGR_DASH = REVEL.registerSound("REV Jaugr Dash"),
	BREAKING_SNOWFLAKE = REVEL.registerSound("REV Breaking Snowflake"),
	WILLIWAW = {
		BLOW_END = REVEL.registerSound("REV Williwaw Blow End"),
		BLOW_LOOP = REVEL.registerSound("REV Williwaw Blow Loop"),
		BLOW_START = REVEL.registerSound("REV Williwaw Blow Start"),
		CLONE_CREATED = REVEL.registerSound("REV Williwaw Clone Created"),
		CRACKING = REVEL.registerSound("REV Williwaw Cracking"),
		CREATE_CLONE = REVEL.registerSound("REV Williwaw Create Clone"),
		DASH = REVEL.registerSound("REV Williwaw Dash"),
		DEATH_CLONE = REVEL.registerSound("REV Williwaw Death Clone"),
		DEATH = REVEL.registerSound("REV Williwaw Death"),
		INTRO = REVEL.registerSound("REV Williwaw Intro"),
		INTRO_SHAKING = REVEL.registerSound("REV Williwaw Intro Shaking"),
		RECEIVE_ICICLE = REVEL.registerSound("REV Williwaw Receive Icicle"),
		REFORM = REVEL.registerSound("REV Williwaw Reform"),
		SHOOT_ICICLE = REVEL.registerSound("REV Williwaw Shoot Icicle"),
		SHOOT = REVEL.registerSound("REV Williwaw Shoot"),
		SLOW_DRIZZLE_SHOOT = REVEL.registerSound("REV Williwaw Slow Drizzle Shoot"),
		SNOWFLAKE_SNIPE = REVEL.registerSound("REV Williwaw Snowflake Snipe")
    },
    FIRE_BURN_FAST = REVEL.registerSound("REV Fire Burn Fast"),
    DUST_SCATTER = REVEL.registerSound("REV Dust Scatter"),
	WENDY = {
		DASH_END = REVEL.registerSound("REV Wendy Dash End"),
		DASH_START = REVEL.registerSound("REV Wendy Dash Start"),
		DEATH = REVEL.registerSound("REV Wendy Death"),
		INTRO = REVEL.registerSound("REV Wendy Intro"),
		STUN_START = REVEL.registerSound("REV Wendy Stun Start")
	},
    HOG_SCRATCH = REVEL.registerSound("REV Hog Scratch"),
    HOG_SLAM = REVEL.registerSound("REV Hog Slam"),
    HOG_OINK = REVEL.registerSound("REV Hog Oink"),
    HOG_IGNITION = REVEL.registerSound("REV Hog Ignition"),
    ICE_MUNCH = REVEL.registerSound("REV Ice Munch"),
    ICE_THROW = REVEL.registerSound("REV Ice Throw"),
    ICE_BEAM = REVEL.registerSound("REV Ice Beam"),
    OWL_UP = REVEL.registerSound("REV Owl Up"),
    OWL_OUT = REVEL.registerSound("REV Owl Out"),

    -- Music
    GLACIER = Isaac.GetMusicIdByName("Glacier"),
    GLACIER_BOSS = Isaac.GetMusicIdByName("Glacier Boss"),
    GLACIER_BOSS_INTRO = Isaac.GetMusicIdByName("Glacier Boss Intro"),
    GLACIER_BOSS_OUTRO = Isaac.GetMusicIdByName("Glacier Boss Outro"),
    MIRROR_BOSS_JINGLE = Isaac.GetMusicIdByName("Mirror Boss Jingle"),
    MIRROR_BOSS_NOINTRO = Isaac.GetMusicIdByName("Mirror Boss No Intro"),
    MIRROR_BOSS = Isaac.GetMusicIdByName("Mirror Boss"),
    MIRROR_BOSS_OUTRO = Isaac.GetMusicIdByName("Mirror Boss Outro"),
    MIRROR_DOOR_OPENS = Isaac.GetMusicIdByName("Mirror Door Opens"),
    GLACIER_ENTRANCE = Isaac.GetMusicIdByName("Glacier Entrance"),
    ELITE1 = Isaac.GetMusicIdByName("Glacier Elite")
})

StageAPI.StopOverridingMusic(REVEL.SFX.MIRROR_DOOR_OPENS)
StageAPI.StopOverridingMusic(REVEL.SFX.MIRROR_BOSS_OUTRO)
StageAPI.StopOverridingMusic(REVEL.SFX.MIRROR_BOSS_JINGLE)

----------------------
-- ALL ACHIEVEMENTS --
----------------------
REVEL.mixin(REVEL.UNLOCKABLES, {
    PENANCE = REVEL.unlockable("revel1/penance.png", REVEL.ITEM.PENANCE.id, "sarah vs mom", "penance"),
    HEAVENLY_BELL = REVEL.unlockable("revel1/heavenly_bell.png", REVEL.ITEM.HEAVENLY_BELL.id, "sarah vs the lamb", "heavenly bell"),
    ICETRAY = REVEL.unlockable("revel1/ice_tray.png", REVEL.ITEM.ICETRAY.id, "beat glacier", "ice tray"),

    GLACIER_CHAMPIONS = REVEL.unlockable("revel1/glacier_champions.png", nil, "beat glacier bosses", "champions", {sprite = "gfx/ui/achievement/revel1/glacier_champions_icon.png", width = 37, height = 35, scaleX = 2, scaleY = 2}),
})

Isaac.DebugString("Revelations: Loaded Definitions for Chapter 1!")
end