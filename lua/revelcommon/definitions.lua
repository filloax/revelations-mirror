return function()

---------------
-- ALL CHARACTERS --
---------------
REVEL.CHAR = {
    DANTE = REVEL.registerPlayer("Dante", false),
    CHARON = REVEL.registerPlayer("Charon", false),
    SARAH = REVEL.registerPlayer("Sarah", false),
    DANTE_B = REVEL.registerPlayer("Dante", true),
    SARAH_B = REVEL.registerPlayer("Sarah", true),
}

------------------
-- ALL ENTITIES --
------------------
---@type table<string, RevEntDef>
REVEL.ENT = {
    -- Bosses --
    PUNKER = REVEL.ent("Punker"),
    RAGING_LONG_LEGS = REVEL.ent("Raging Long Legs"),

    -- Enemies --
    DRIFTY = REVEL.ent("Drifty"),
    SMOLYCEPHALUS = REVEL.ent("Smolycephalus"),
    PUCKER = REVEL.ent("Pucker"),
    BROTHER_BLOODY = REVEL.ent("Brother Bloody"),
    MOTHER_PUCKER = REVEL.ent("Mother Pucker"),
    AEROTOMA = REVEL.ent("Aerotoma"),
    BOMB_SACK = REVEL.ent("Bomb Sack"),
    PRANK_TOMB = REVEL.ent("Prank (Tomb)", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    PRANK_GLACIER = REVEL.ent("Prank (Glacier)", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    CHICKEN = REVEL.ent("Chicken"),
    SMOLYCEPHALUS_FOR_SCALE = REVEL.ent("Smolycephalus For Scale", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    PURGATORY_ENEMY = REVEL.ent("Purgatory Soul (Enemy)", {
        NoChampion = true, 
    }),

    -- Character --
    PENANCE_ORB = REVEL.ent("Penance Orb", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    PENANCE_SIN = REVEL.ent("Penance Sin", {
        SubType = 1,
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    DANTE_BOOK = REVEL.ent("Dante Book"),
    DANTE = REVEL.ent("Dante"),
    CHARON_DOOR_CHAINS = REVEL.ent("Charon Door Chains"),

    -- Effects --
    PARTICLE = REVEL.ent("Rev Particle"),
    SPOTLIGHT_BEAM = REVEL.ent("Spotlight"),
    PLAYER_CAMERA_STANDIN = REVEL.ent("Player Camera Placeholder"),
    PACT_SHOP = REVEL.ent("Pact Vanity Shop"),
    SLOT_MANAGER = REVEL.ent("Slot Machine Manager"),

    -- Other
    SELF_REMOVING_ENTITY = REVEL.ent("Self Removing Entity"),
    CURSED_SHRINE = REVEL.ent("Cursed Shrine", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    PRANK_SHOP = REVEL.ent("Prank Shop", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    MIRROR_FIRE_CHEST = REVEL.ent("Mirror Fire Chest", {
        NoChampion = true, 
        NoHurtWisps = true,
    }),
    REVENDING_MACHINE = REVEL.ent("Revending Machine"),
    VANITY_STATWHEEL = REVEL.ent("Vanity Statwheel"),
    HUB_DECORATION = REVEL.ent("Revelations Hub Decoration"),
    VANITY_TRAPDOOR = REVEL.ent("Revelations Vanity Trapdoor"),
    RESTOCK_MACHINE = REVEL.ent("Revelations Restock Machine"),
}

StageAPI.AddMetadataEntities{
    [199] = {
        [745] = {
            Name = "Disable Random Special Rock Spawn",
        },
        [746] = {
            Name = "Vanity Shop Item",
        },
        [747] = {
            Name = "Vanity Statwheel Init Workaround",
        },
        [748] = {
            Name = "Test - Airmovement Ground Level",
            BitValues = {
                GroundLevel = {ValueOffset = -32768, Length = 16},
            },
        }
    }
}

----------------------
-- ALL GRIDENTITIES --
----------------------
---@type table<string, CustomGrid>
REVEL.GRIDENT = {
    INVISIBLE_BLOCK = StageAPI.CustomGrid("Invisible Block", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "stageapi/none.anm2", 
		Animation = "None"
	}),
    VANITY_TRAPDOOR = StageAPI.CustomGrid("Revelations Vanity Trapdoor"),
    HUB_TRAPDOOR = StageAPI.CustomGrid("Revelations Hub Trapdoor"),
}

------------------
-- ALL COSTUMES --
------------------
REVEL.COSTUME = {
    SARAH = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/character_sarah.anm2"),

    -- DANTE = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/character_dante.anm2"),
    CHARON_HAIR = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/character_charon_hair.anm2"),
    DANTE_HAIR = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/character_dante_hair.anm2"),
    BROKEN_OAR = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/item_brokenoar.anm2"),

    SMBLADE_NOBLADE = Isaac.GetCostumeIdByPath("gfx/characters/revelcommon/costume_supermeatblade_noblade.anm2"),

    AZAZEL_NOWINGS = Isaac.GetCostumeIdByPath("gfx/characters/character_008_azazelbody_nowings.anm2"),
}

---------------
-- ALL ITEMS --
---------------

---@type table<string, RevItemDef|RevTrinketDef>
REVEL.ITEM = {
    -- Passive --
    HEAVENLY_BELL = REVEL.registerItem(1, "Heavenly Bell"),
    MINT_GUM = REVEL.registerItem(2, "Mint Gum", nil, nil, 1),
    FECAL_FREAK = REVEL.registerItem(3, "Fecal Freak", nil, nil, 1),
    LIL_BELIAL = REVEL.registerItem(4, "Lil Belial", nil),
    AEGIS = REVEL.registerItem(5, "Aegis", nil, nil, 1),
    BIRTHDAY_CANDLE = REVEL.registerItem(6, "Birthday Candle"),
    DYNAMO = REVEL.registerItem(7, "Dynamo", "gfx/characters/revelcommon/dynamo.anm2", nil, 1),
    BURNBUSH = REVEL.registerItem(8, "Burning Bush", "gfx/characters/revelcommon/bbush_nofire.anm2", nil, 1),
    PENANCE = REVEL.registerItem(9, "Penance"),
    ICETRAY = REVEL.registerItem(10, "Ice Tray"),
    CLEANER = REVEL.registerItem(11, "Window Cleaner"),
    SPONGE = REVEL.registerItem(12, "Sponge Bombs"),
    PATIENCE = REVEL.registerItem(13, "Spirit of Patience", "gfx/characters/revelcommon/spiritofpatience.anm2", nil, 1),
    TAMPON = REVEL.registerItem(14, "Cotton Bud"),
    BCONTROL = REVEL.registerItem(15, "Birth Control"),
    TBUG = REVEL.registerItem(16, "Tummy Bug", nil, nil, 1),
    FFIRE = REVEL.registerItem(17, "Friendly Fire"),

    WANDERING_SOUL = REVEL.registerItem(22, "Wandering Soul", nil, nil, 1),
    CABBAGE_PATCH = REVEL.registerItem(23, "Cabbage Patch", nil, nil, 1),
    HAPHEPHOBIA = REVEL.registerItem(24, "Haphephobia"),
    FERRYMANS_TOLL = REVEL.registerItem(25, "Ferryman's Toll"),
    DEATH_MASK = REVEL.registerItem(26, "Death Mask"),
    MIRROR_BOMBS = REVEL.registerItem(27, "Mirror Bombs"),
    CHARONS_OAR = REVEL.registerItem(28, "Broken Oar", "gfx/characters/revelcommon/item_brokenoar.anm2"),
    PERSEVERANCE = REVEL.registerItem(29, "Perseverance", nil, nil, 1),
    ADDICT = REVEL.registerItem(30, "Addict"),
    OPHANIM = REVEL.registerItem(31, "Ophanim", nil, nil, 1),
    PILGRIMS_WARD = REVEL.registerItem(32, "Pilgrim's Ward", nil, nil, 1),
    WRATHS_RAGE = REVEL.registerItem(33, "Wrath's Rage", "gfx/characters/revelcommon/item_wrathsrage1.anm2"),
    PRIDES_POSTURING = REVEL.registerItem(34, "Pride's Posturing"),
    SLOTHS_SADDLE = REVEL.registerItem(35, "Sloth's Saddle", nil, true),
    LOVERS_LIB = REVEL.registerItem(36, "Lover's Libido", nil, true),
    PRESCRIPTION = REVEL.registerItem(65, "Prescription", nil),
	GEODE = REVEL.registerItem(66, "Geode", nil),
	NOT_A_BULLET = REVEL.registerItem(67, "Not a Bullet", nil),
    
	-- Active --
    MONOLITH = REVEL.registerItem(18, "The Monolith", nil),
    HYPER_DICE = REVEL.registerItem(19, "Hyper Dice", nil, true),

    CHUM = REVEL.registerItem(37, "Chum Bucket", nil),
    ROBOT = REVEL.registerItem(38, "Cardboard Robot", nil),
    ROBOT2 = REVEL.registerItem(39, "Cardboard Robot (flipped)", nil, true),
    GFLAME = REVEL.registerItem(40, "Ghastly Flame", nil),
    GFLAME2 = REVEL.registerItem(41, "Ghastly Flame (lit)", nil, true),
    --PHYLACTERY_OLD = REVEL.registerItem("Phylactery Old", nil, true),
    PHYLACTERY = REVEL.registerItem(42, "Phylactery", nil, true),
    PHYLACTERY_MERGED = REVEL.registerItem(43, "Phylactery ", nil, true),
    PHYLACTERY_PICKUP_ITEM = REVEL.registerItem(44, "Phylactery  ", nil, true),
    PHYLACTERY_PICKUP_ITEM_CHARGE = REVEL.registerItem(45, "Phylactery   ", nil, true),
    WAKA_WAKA = REVEL.registerItem(46, "Waka Waka", nil),
    OOPS = REVEL.registerItem(47, "Oops!", nil),
    GUT = REVEL.registerItem(48, "Glutton's Gut", "gfx/characters/revelcommon/item_gluttonsgut_normal.anm2", true),
    MOXIE = REVEL.registerItem(49, "Moxie's Paw", nil),
    MUSIC_BOX = REVEL.registerItem(50, "Music Box", nil),
    HALF_CHEWED_PONY = REVEL.registerItem(51, "Half Chewed Pony", nil, true),
    MOXIE_YARN = REVEL.registerItem(52, "Moxie's Yarn", nil),

    SMBLADE_UNUSED = REVEL.registerItem(64, "Super Meat Blade", "gfx/characters/revelcommon/costume_supermeatblade.anm2"),
    SMBLADE = REVEL.registerItem(63, "Super Meat Blade ", "gfx/characters/revelcommon/costume_supermeatblade.anm2"),
	DRAMAMINE = REVEL.registerItem(62, "Dramamine", nil),
    
	-- Familiar --
    MIRROR = REVEL.registerItem(20, "Mirror Shard", nil, true),
    LIL_FRIDER = REVEL.registerItem(21, "Lil Frost Rider", nil, true),

    VIRGIL = REVEL.registerItem(53, "Virgil", nil),
    MIRROR2 = REVEL.registerItem(54, "Mirror Fragment", nil, true),
    CURSED_GRAIL = REVEL.registerItem(55, "Cursed Grail", nil),
    BANDAGE_BABY = REVEL.registerItem(56, "Bandage Baby", nil, nil, 1),
    LIL_MICHAEL = REVEL.registerItem(57, "Lil Michael", nil, nil, 1),
    HUNGRY_GRUB = REVEL.registerItem(58, "Hungry Grub", nil, nil, 1),
    ENVYS_ENMITY = REVEL.registerItem(59, "Envy's Enmity", nil, nil, 1),
    BARG_BURD = REVEL.registerItem(60, "Bargainer's Burden", nil, nil, 1),
    WILLO = REVEL.registerItem(61, "Willo", nil),

    -- Trinket --
    SPARE_CHANGE = REVEL.registerTrinket(1, "Spare Change", nil),
    LIBRARY_CARD = REVEL.registerTrinket(2, "Library Card", nil),
    ARCHAEOLOGY = REVEL.registerTrinket(3, "Archaeology", nil),
    GAGREFLEX = REVEL.registerTrinket(4, "Gag Reflex", nil),

    TELESCOPE = REVEL.registerTrinket(5, "Telescope", nil),
    SCRATCHED_SACK = REVEL.registerTrinket(6, "Scratched Sack", nil),
    MAX_HORN = REVEL.registerTrinket(7, "Maxwell's Horn", nil),
    MEMORY_CAP = REVEL.registerTrinket(8, "Memory Cap", nil),
    -- why is it shortened to Xmas in english anyways
    XMAS_STOCKING = REVEL.registerTrinket(9, "Christmas Stocking", nil),
}

---------------------
-- ALL POCKETITEMS --
---------------------
REVEL.POCKETITEM = {
    -- Cards --
    LOTTERY_TICKET = {
        Id = Isaac.GetCardIdByName("55_LotteryTicket"),
        Announcer = REVEL.registerSound("REV Announcer Lottery Ticket"),
    },
    BELL_SHARD = {
        Id = Isaac.GetCardIdByName("BellShard"),
        Announcer = REVEL.registerSound("REV Announcer Bell Shard"),
    },

    -- Pill effects --
}

------------------
-- CUSTOM PILLS --
------------------
REVEL.CUSTOM_PILLS = {
}

----------------
-- ALL CURSES --
----------------
REVEL.CURSE = {}

-------------
-- ALL SFX --
-------------
REVEL.SFX = {
    TEARIMPACTS = REVEL.registerSound("REV Custom Tearimpacts"),
    SPLATTER = REVEL.registerSound("REV Custom Splatter"),

    ANGELIC_SARAH = REVEL.registerSound("REV Angelic Sarah"),
    ANGELIC_SARAH_OFF = REVEL.registerSound("REV Angelic Sarah off"),

    -- Charon
    CHARON_SPLASH_LITTLE = REVEL.registerSound("REV Charon Splash Little"),
    CHARON_SPLASH_MEDIUM = REVEL.registerSound("REV Charon Splash Medium"),
    CHARON_SPLASH_LARGE = REVEL.registerSound("REV Charon Splash Large"),
    CHARON_LANTERN_SWITCH = REVEL.registerSound("REV Charon Lantern Switch"),
    CHARON_POWER_DOWN = REVEL.registerSound("REV Charon Lantern Power Down"),
    CHARON_BOOK_SLAM = REVEL.registerSound("REV Charon Book Slam"),
    CHARON_BOOK_READY = REVEL.registerSound("REV Charon Book Ready"),
    CHARON_CRIT = REVEL.registerSound("REV Dante Crit"),
    CHARON_HIGH_FIVE = REVEL.registerSound("REV Charon High Five"),

    -- Looping brimstone
    BLOOD_LASER_LOOP = REVEL.registerSound("REV Blood Laser Loop"),
    BLOOD_LASER_START = REVEL.registerSound("REV Blood Laser Start"),
    BLOOD_LASER_STOP_SHORT = REVEL.registerSound("REV Blood Laser Stop Short"),
    BLOOD_LASER_STOP = REVEL.registerSound("REV Blood Laser Stop"),

    RAGING_LONG_LEGS_RAGE = REVEL.registerSound("REV Raging Long Legs Rage"),
    RAGING_LONG_LEGS_DASH_END = REVEL.registerSound("REV Raging Long Legs Dash End"),
    RAGING_LONG_LEGS_DASH_LOOP = REVEL.registerSound("REV Raging Long Legs Dash Loop"),
    RAGING_LONG_LEGS_DASH_START = REVEL.registerSound("REV Raging Long Legs Dash Start"),

    MEATBLADE = {
        BASE = REVEL.registerSound("REV Meatblade Loop Base"),
        REVEL.registerSound("REV Meatblade Loop Lv1"),
        REVEL.registerSound("REV Meatblade Loop Lv2"),
        REVEL.registerSound("REV Meatblade Loop Lv3"),
    },

    CALL_WHISTLE = REVEL.registerSound("REV Call Whistle"),
    MORSHU_1 = REVEL.registerSound("REV Morshu 1"),
    MORSHU_2 = REVEL.registerSound("REV Morshu 2"),
    SPOTLIGHT = REVEL.registerSound("REV Spotlight"),
    BLOOD_SAP = REVEL.registerSound("REV Blood Sap"),
    SPECIAL_NARC_REWARD = REVEL.registerSound("REV Special Narc Reward"),

    -- TearsFire workaround
    TEARS_FIRE = REVEL.registerSound("REV Custom Tears Fire"),

    -- Gets disabled otherwise in room with no fireplaces
    FIRE_BURNING = REVEL.registerSound("REV Custom Fire Burning"),

    -- Music
    TRANSITION = Isaac.GetMusicIdByName("Transition Stinger"),
    WIND = Isaac.GetMusicIdByName("AmbientWind"),
    SIN = {
        SLOTH = Isaac.GetMusicIdByName("Sloth Sin"),
        ENVY = Isaac.GetMusicIdByName("Envy Sin"),
        GLUTTONY = Isaac.GetMusicIdByName("Gluttony Sin"),
        GREED = Isaac.GetMusicIdByName("Greed Sin"),
        LUST = Isaac.GetMusicIdByName("Lust Sin"),
        PRIDE = Isaac.GetMusicIdByName("Pride Sin"),
        WRATH = Isaac.GetMusicIdByName("Wrath Sin"),
        ALL = Isaac.GetMusicIdByName("All Sins")
    },

    HUB_ROOM = Isaac.GetMusicIdByName("Revelations Hub Room"),
    HUB_ROOM_STINGER = Isaac.GetMusicIdByName("Revelations Hub Room Stinger"),
    VANITY_SHOP = Isaac.GetMusicIdByName("Revelations Vanity Bazaar"),
    VANITY_CASINO = Isaac.GetMusicIdByName("Revelations Vanity Casino"),

    -- Vanilla replacement
    SHOP = Isaac.GetMusicIdByName("Revelations Shop"),
    SECRET = Isaac.GetMusicIdByName("Revelations Secret Room"),
    SECRET_JINGLE = Isaac.GetMusicIdByName("Revelations Secret Room Jingle"),
    CHALLENGE = Isaac.GetMusicIdByName("Revelations Challenge Room"),
    CHALLENGE_END = Isaac.GetMusicIdByName("Revelations Challenge Room End"),
    BOSS_CALM = Isaac.GetMusicIdByName("Revelations Boss Calm"),
    TREASURE = {
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 1"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 2"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 3"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 4"),
    },

    BLANK_MUSIC = Isaac.GetMusicIdByName("blank")
}

StageAPI.StopOverridingMusic(REVEL.SFX.HUB_ROOM_STINGER)
StageAPI.StopOverridingMusic(REVEL.SFX.HUB_ROOM)
StageAPI.StopOverridingMusic(REVEL.SFX.SECRET_JINGLE)

--------------------
-- ALL CHALLENGES --
--------------------
REVEL.CHALLENGE = {}

----------------------
-- ALL ACHIEVEMENTS --
----------------------
REVEL.UNLOCKABLES = {}

------------------
-- ALL OVERLAYS --
------------------
REVEL.OVERLAY = {}

----------------
-- ALL STAGES --
----------------
---@type table<string, CustomStage>
REVEL.STAGE = {}

Isaac.DebugString("Revelations: Loaded Definitions for Chapter 1!")
end