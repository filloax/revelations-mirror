
return {
    FirerateToDamageRatio = 1, -- increase to make firerate higher and damage lower, and vice versa, meant to test different settings for lag

    BaseStats = {
        Streams = 1,
        ScaleMult = 1,
        MaxHeadOffset = 8,
        MultiShotAngle = 20,
        Height = -20,
        BaseDamage = 3.5, --ideally should be changed only through player damage, used to scale damage with player damage differently
        DmgMult = 0.1, --can be changed after item stats are applied if FirerateToDamageRatio ~= 1
        ConeAngleMult = 1,
        MaxFuel = 180,
        FuelChargeSpeed = 2,
        BurnTickDelay = 6, --can be float
        AvgShotSpeed = 10,
        Life = 20,
        FiresPerUpdate = 0.9, --can be float, can be changed after item stats are applied if FirerateToDamageRatio ~= 1
        SmallFiresInPathPerFrame = 0.003, --how many small fires *every fire shot* leaves in its path per frame
        BurnDuration = 80,
        NoCooldown = false, -- used by some synergies, like marked
    },

    LifeRandom = 0.1,
    ScaleRandom = 0.25,

    ConeAngle1Shot = 16,
    ConeAngle2Shot = 10,
    ConeAngleMultiShot = 5,
    FiredelayDamageInfluence = 0.5,
    MaxFiresPerUpdate = 2.2,
    ShotSpeedInfluence = 0.5,
    FuelWeakStartPct = 0.2, --at x% fuel tears start getting smaller and weaker
    WeakScaleMult = 0.6,
    WeakFreqMult = 0.2,
    WeakDmgMult = 0.5,
    BurnDamageMult = 0.19, --of player damage
    PermaFireDmgMult = 0.1, --relative to single flame damage
    PermaFireScale = 0.2,
    PermaFireScaleRandom = 0.3,
    PermaFireLife = 90,
    PermaFireShrinkStart = 0.3,
    LagAdjustmentMaxFires = 60, --max fires on screen before lag adjustment kicks in
    SlowDownTime = 0.45,
    LaserFiresPerUpdateMult = 0.4,
    MaxFuelBurstFirerateMult = 2,
    MaxFuelBurstFrameDur = 4,

    BlueColor = Color(0.3, 1, 1, 0.9,conv255ToFloat( 0, 0, 200)),
    BlueEndTime = 0.75,
    YellowColor = Color(1.3, 1, 1, 1,conv255ToFloat( 0, 100, 0)),
    YellowStartTime = 0.4,
    BaseStartScale = 0.65,
    BaseMidScale = 0.85,
    BaseDeathScale = 0.95,
    MidScaleTime = 0.5,
    FadeStartTime = 0.25,
    MaxOpacity = 0.85,
    BaseLightScale = 1.2,
    LightColor = Color(0.7,0.35,0,1,conv255ToFloat(0,0,0)),
    SmokePerSecond = 3, --across all flames

    MintGumPermafireColor = Color(0.5,1.2,0.7,1,conv255ToFloat(0,0,0)),
    CharonColor = Color(1,1.5,1.4,1,conv255ToFloat(40,0,0)),
    FecalFreakSpriteOffset = Vector(0,16),
    LowFuelColor = Color(0.9, 0.5, 0.3, 1,conv255ToFloat( 40, 0, 0)),
    LowFuelColorMintGum = Color(0.2, 0.7, 1.1, 1,conv255ToFloat( 0, 10, 50)),
    LowFuelColorTime = 0.75,
    TechxRotationSpeed = 0.05,
    CostumeFrameDuration = {2, 1, 1, 3, 1}, --last frame is shooting frame so irrelevant
    CostumeFramesNum = 5,
    PlayStartSoundAtFrame = 3,
    StartSoundDurMs = 1846,
    HitSound = SoundEffect.SOUND_FIREDEATH_HISS,
    HitSoundMinDelayMs = 1100,
    FireColorLowerClamp = Color(0.5, 0.5, 0.5, 0,conv255ToFloat( 0,  0,  0)),
    FireColorUpperClamp = Color(1.5, 1.5, 1.5, 1,conv255ToFloat( 80, 80, 80)),

    --Isaac with base stats
    DefaultTearRange = 260,
    DefaultMaxFiredelay = 10,

    PlayerTypeFiringBlacklist = {
        [PlayerType.PLAYER_LILITH_B] = true,
    },
    WeaponTypeFiringBlacklist = {
        WeaponType.WEAPON_KNIFE, 
        WeaponType.WEAPON_BRIMSTONE, 
        WeaponType.WEAPON_LUDOVICO_TECHNIQUE, 
        WeaponType.WEAPON_LASER,
        WeaponType.WEAPON_ROCKETS, 
        WeaponType.WEAPON_BOMBS, 
        WeaponType.WEAPON_MONSTROS_LUNGS, 
        WeaponType.WEAPON_TECH_X,
        WeaponType.WEAPON_UMBILICAL_WHIP,
    },
    ItemWithTearsFiringBlacklist = {
        CollectibleType.COLLECTIBLE_IPECAC,
        CollectibleType.COLLECTIBLE_LACHRYPHAGY,
        CollectibleType.COLLECTIBLE_HAEMOLACRIA,
    },

    StatAffectingCacheflags = {
        CacheFlag.CACHE_FIREDELAY, CacheFlag.CACHE_RANGE, CacheFlag.CACHE_SHOTSPEED
    },

    TearFlagBlackList = {  --false = no replacement, simply removed
        [TearFlags.TEAR_EXPLOSIVE] = TearFlags.TEAR_POISON,
        [TearFlags.TEAR_LASERSHOT] = false,
        [TearFlags.TEAR_BURN] = false,
        [TearFlags.TEAR_MIDAS] = false,
        [TearFlags.TEAR_COIN_DROP] = false,
        [TearFlags.TEAR_GREED_COIN] = false,
        [TearFlags.TEAR_STICKY] = false,
        [TearFlags.TEAR_ABSORB] = false,
    }
}
