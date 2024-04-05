return function()

REVEL.ENT = {
    ---- COMMON

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
    SKITTER_G = REVEL.ent("Skitterpill Good", {
        NoChampion = true,
    }),
    SKITTER_B = REVEL.ent("Skitterpill Bad", {
        NoChampion = true,
    }),
    SKITTER_C = REVEL.ent("Skitterpill Card", {
        NoChampion = true,
    }),

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
    SANDSTORM = REVEL.ent("Sandstorm"),

    -- Bosses --
    PUNKER = REVEL.ent("Punker"),
    RAGING_LONG_LEGS = REVEL.ent("Raging Long Legs"),

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

    -- Familiars --
    MIRRORSHARD = REVEL.ent("Mirror Shard"),
    LIL_BELIAL = REVEL.ent("Lil Belial"),
    LIL_FRIDER = REVEL.ent("Lil Frost Rider"),
    SOUL = REVEL.ent("Soul"),

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


    -- Projectiles --
    TRAY_PROJECTILE = REVEL.ent("Tray Projectile", 155),
    
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

    SAND_CASTLE = REVEL.ent("Sand Castle"),
    FLAMING_TOMB = REVEL.ent("Flaming Tomb"),
    
    -- Effects --
    PARTICLE = REVEL.ent("Rev Particle"),
    SPOTLIGHT_BEAM = REVEL.ent("Spotlight"),
    PLAYER_CAMERA_STANDIN = REVEL.ent("Player Camera Placeholder"),
    PACT_SHOP = REVEL.ent("Pact Vanity Shop"),
    SLOT_MANAGER = REVEL.ent("Slot Machine Manager"),

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
}


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

end