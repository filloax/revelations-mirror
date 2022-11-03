REVEL.SimpleAddRoomsSet("Tomb", "Tomb", nil, "revel2.tomb_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("TombShrines", "TombShrines", nil, "revel2.tomb_shrines_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("TombEntrance", "TombEntrance", nil, "revel2.tomb_entrance_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("TombFlamingTombs", "TombFlamingTombs", nil, "revel2.tomb_flamingtombs_", REVEL.RoomEditors, {"Test"})

REVEL.AddRoomsIfPossible("Sinami", "Sinami", nil, "revel1.sins.sinami")

REVEL.SimpleAddRoomsSet("TombSpecial", "TombSpecial", nil, "revel2.tomb_special_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("TombChallenge", "TombChallenge", nil, "revel2.tomb_challenge_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("TombBossChallenge", "TombBossChallenge", nil, "revel2.tomb_boss_challenge_", REVEL.RoomEditors, {"Test"})

REVEL.Bosses.ChapterTwo = {
    {
        Name = "Catastrophe",
        Portrait = "gfx/ui/boss/revel2/catastrophe_portrait.png",
        Bossname = "gfx/ui/boss/revel2/catastrophe_name.png",
        RoomKeyPrefix = "Catastrophe",
        FilePrefix = "catastrophe_",
        Entity = REVEL.GetBossEntityData("Catastrophe Yarn (Spawner)", "Catastrophe Placeholder"),
        Bestiary = "catastrophe.png",
        Stage = "Tomb",
        Variants = {"Normal", "Champion"}
    },
    {
        Name = "Maxwell",
        Portrait = "gfx/ui/boss/revel2/maxwell_portrait.png",
        Bossname = "gfx/ui/boss/revel2/maxwell_name.png",
        RoomKeyPrefix = "Maxwell",
        FilePrefix = "maxwell_",
        Entity = REVEL.GetBossEntityData("Maxwell"),
        Shapes = {RoomShape.ROOMSHAPE_1x1},
        Bestiary = "maxwell.png",
        Stage = "Tomb",
        Variants = {"Normal", "Champion", "Ruthless"}
    },
    {
        Name = "Aragnid",
        Portrait = "gfx/ui/boss/revel2/aragnid_portrait.png",
        Bossname = "gfx/ui/boss/revel2/aragnid_name.png",
        RoomKeyPrefix = "Aragnid",
        FilePrefix = "aragnid_",
        Entity = REVEL.GetBossEntityData("Aragnid"),
        Bestiary = "aragnid.png",
        Stage = "Tomb",
        Variants = {"Normal", "Champion", "Ruthless"}
    },
	{
		Name = "Sarcophaguts",
		Portrait = "gfx/ui/boss/revel2/sarcophaguts_portrait.png",
		Bossname = "gfx/ui/boss/revel2/sarcophaguts_name.png",
        RoomKeyPrefix = "Sarcophaguts",
        FilePrefix = "sarcophaguts_",
		Entity = REVEL.GetBossEntityData("Sarcophaguts"),
        Bestiary = "sarcophaguts.png",
        Stage = "Tomb",
        Variants = {"Normal", "Champion"}
	},
	{
		Name = "Sandy",
		Portrait = "gfx/ui/boss/revel2/sandy_portrait.png",
		Bossname = "gfx/ui/boss/revel2/sandy_name.png",
        FilePrefix = "sandy_",
		Entity = REVEL.GetBossEntityData("Sandy"),
        Horseman = true,
        Bestiary = "sandy.png",
        Stage = "Tomb",
        Variants = {"Normal", "Champion"}
	},
    {
        Name = "Dungo",
        IsMiniboss = true,
        FilePrefix = "dungo_",
        Entity = REVEL.GetBossEntityData("Dungo"),
        Weight = 1,
        Bestiary = "dungo.png",
        Stage = "Tomb",
        Variants = {"Normal"}
    },
    {
        Name = "Ragtime",
        IsMiniboss = true,
        FilePrefix = "ragtime_",
        Entity = REVEL.GetBossEntityData("Ragtime"),
        Weight = 1,
        Bestiary = "ragtime.png",
        Stage = "Tomb",
        Variants = {"Normal"}
    },
    {
        Name = "Narcissus 2",
        Bestiary = "narc2.png",
        Portrait = "gfx/ui/boss/revel2/narcissus2_portrait.png",
		Bossname = "gfx/ui/boss/revel2/narcissus2_name.png",
        Entity = REVEL.GetBossEntityData("Narcissus 2"),
        Stage = "Tomb",
        Variants = {"Normal"},
        Mirror = true,
        IsMiniboss = true,
        NoStageAPI = true
    }
}

for _, boss in ipairs(REVEL.Bosses.ChapterTwo) do
    boss.RoomKeyPrefix = boss.RoomKeyPrefix or boss.ListName or boss.Name
    boss.ListName = boss.ListName or boss.RoomKeyPrefix or boss.Name
end

REVEL.extend(REVEL.BossMenuSegments, {REVEL.Bosses.ChapterTwo, "gfx/ui/bestiary/revel2/", "TOMB_CHAMPIONS", "chapter two"})

REVEL.TombBosses = {
    "Catastrophe",
    "Maxwell",
    "Aragnid",
    "Sarcophaguts",
    "Sandy"
}

REVEL.TombElites = {
    "Dungo",
    "Ragtime",
}

REVEL.AddBossRooms("ChapterTwo", "tomb", "revel2.bosses.", REVEL.RoomEditors)

REVEL.AddSinRooms("ChapterTwo", "revel2.sins.", REVEL.RoomEditors)

--REVEL.AddGenericBossFiles(REVEL.Bosses.ChapterTwo, "Revel2Boss", nil, "revel2.bosses.", REVEL.RoomEditors, {"Test"})
--REVEL.PreloadBossRooms(REVEL.Bosses.ChapterTwo, "Revel2Boss", nil, "revel2.bosses.", REVEL.RoomEditors, {"Test"})

REVEL.PcallWorkaroundBreakFunction()
