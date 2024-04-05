REVEL.RoomEditors = {
    "Blorenge", 
    "Koala", 
    "Melon", 
    "Melon2", 
    "piber20",
    "Minichibis", 
    "Dead", 
    "Filloax", 
    "Budj", 
    "Vermin", 
    "Sentinel", 
    "Gummy", 
    "sunil", 
    "erfly", 
    "Pixelo",
    "Pasta",
    "Al",
    "hippo",
    "creeps",
    "grynn",
    "Sin",
    "guwah",
    "chillmunity",
    "comummyty",
    "vanilla",
}

REVEL.AddRoomsIfPossible("SpecialRooms", "SpecialRooms", "Special Rooms", "specialrooms")
REVEL.SimpleAddRoomsSet({"GlacierSpecial","TombSpecial"}, "DefaultSpecial", nil, "revelcommon.default_special_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("RevelationsHub", "RevelationsHub", nil, "revelcommon.hub_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("RevelationsVanityShop", "RevelationsVanityShop", nil, "revelcommon.vanityshop_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("RevelationsVanityCasino", "RevelationsVanityCasino", nil, "revelcommon.vanitycasino_", REVEL.RoomEditors, {"Test"})

local getEntities2 = require("scripts.revelations.common.entities2")
StageAPI.AddEntities2Function(getEntities2)

---@class Rev.BossEntry
---@field Name string
---@field Portrait string
---@field RoomKeyPrefix string
---@field ListName string
---@field FilePrefix string
---@field Entity {Type: integer, FallbackRoomName: string, SubType: integer?, Name: string}
---@field Bestiary string
---@field Stage {Stage: LevelStage, StageType: StageType, NormalStage: boolean?}|string
---@field Variants string[]
---@field Weight integer?
---@field Offset Vector?
---@field Mirror boolean?
---@field IsMiniboss boolean?
---@field NoStageAPI boolean?

---@type table<string, Rev.BossEntry[]>
REVEL.Bosses = {
    Common = {
        {
            Name = "Raging Long Legs",
            Portrait = "gfx/ui/boss/revelcommon/raging_long_legs_portrait.png",
            Bossname = "gfx/ui/boss/revelcommon/raging_long_legs_name.png",
            RoomKeyPrefix = "Raging Long Legs",
            FilePrefix = "raging_long_legs_",
            Entity = REVEL.GetBossEntityData("Raging Long Legs"),
            Bestiary = "raging_long_legs.png",
            Stage = {Stage = LevelStage.STAGE1_1, StageType = StageType.STAGETYPE_AFTERBIRTH, NormalStage = true},
            Variants = {"Normal", "Champion"},
            -- ChampionAchievement = "TOMB_CHAMPIONS"
        },
        {
            Name = "Punker",
            Portrait = "gfx/ui/boss/revelcommon/punker_portrait.png",
            Bossname = "gfx/ui/boss/revelcommon/punker_name.png",
            FilePrefix = "punker_",
            Entity = REVEL.GetBossEntityData("Punker"),
            Bestiary = "punker.png",
            Stage = {Stage = LevelStage.STAGE2_1, NormalStage = true},
            Variants = {"Normal", "Champion", "Ruthless"},
            -- ChampionAchievement = "GLACIER_CHAMPIONS"
        }
    }
}

REVEL.BossMenuSegments = {
    {REVEL.Bosses.Common, "gfx/ui/bestiary/revelcommon/", "GLACIER_CHAMPIONS", "main path", true}
}

for _, boss in ipairs(REVEL.Bosses.Common) do
    boss.RoomKeyPrefix = boss.RoomKeyPrefix or boss.ListName or boss.Name
    boss.ListName = boss.ListName or boss.RoomKeyPrefix or boss.Name
end

REVEL.AddBossRooms("Common", "common", "revelcommon.bosses.", REVEL.RoomEditors)

if MinimapAPI then
    MinimapAPI:RemovePlayerPositionCallback(revel)
end
