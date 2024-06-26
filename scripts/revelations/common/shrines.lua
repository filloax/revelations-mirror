local SubModules = {
    "scripts.revelations.common.shrines.pact",
    "scripts.revelations.common.shrines.shrine",
    "scripts.revelations.common.shrines.room",
    "scripts.revelations.common.shrines.vanity",
    "scripts.revelations.common.shrines.commonshrines",
    "scripts.revelations.common.shrines.champions",
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.ShrineBalance = {
    DefaultPactVanity = 2,
    DefaultPactVanityOneChapter = 1,
    MistakeExtra = 1,

    PickupPrice = 1,
    TrinketPrice = 1,
    ShopItemPrice = 2,
    TreasureItemPrice = 3,
    AngelItemPrice = 5,
    DevilItemPrice = 4,
    DevilRoomTeleportPrice = 3,
    PrankVanityDiscount = 1,
    StatwheelPrice = 1,
    MirrorFireChestPrice = 1,

    HighestPrice = 6,

    PickupAmount = 5,

    StatwheelStatUps = {
        Damage = 0.6,
        MaxFireDelay = -1,
        Luck = 1,
        MoveSpeed = 0.2,
        TearRange = 40 * 1, --1 tiles
        ShotSpeed = 0.3,
    },

    ChampionChanceIncreaseBase = 20,
    ChampionChanceIncreaseMax = 70,
    ChampionMaxAmount = 3,
}

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Shrines!")
end