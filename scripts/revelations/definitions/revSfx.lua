return function ()

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

    -- TearsFire workaround
    TEARS_FIRE = REVEL.registerSound("REV Custom Tears Fire"),

    -- Gets disabled otherwise in room with no fireplaces
    FIRE_BURNING = REVEL.registerSound("REV Custom Fire Burning"),

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
}
    
end