REVEL.SimpleAddRoomsSet("Glacier", "Glacier", nil, "revel1.glacier_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierShrines", "GlacierShrines", nil, "revel1.glacier_shrines_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierEntrance", "GlacierEntrance", nil, "revel1.glacier_entrance_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierSpecial", "GlacierSpecial", nil, "revel1.glacier_special_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierChallenge", "GlacierChallenge", nil, "revel1.glacier_challenge_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierBossChallenge", "GlacierBossChallenge", nil, "revel1.glacier_boss_challenge_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierDanteSatan2", "GlacierDanteSatan2", nil, "revel1.glacier_dantesatan2_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierLightableFire", "GlacierLightableFire", nil, "revel1.glacier_lightablefire_", REVEL.RoomEditors, {"Test"})
REVEL.SimpleAddRoomsSet("GlacierSnowman", "GlacierSnowman", nil, "revel1.glacier_snowman_", REVEL.RoomEditors, {"Test"})

REVEL.Bosses.ChapterOne = {
    --[[
    {
        Name = "Monsnow",
        Portrait = "gfx/ui/boss/revel1/monsnow_portrait.png",
        Bossname = "gfx/ui/boss/revel1/monsnow_name.png",
        FilePrefix = "monsnow_",
        Entity = REVEL.GetBossEntityData("Monsnow"),
        Bestiary = "monsnow.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
    ]]
    --[[
    {
        Name = "Duke of Flakes",
        Portrait = "gfx/ui/boss/revel1/duke_of_flakes_portrait.png",
        Bossname = "gfx/ui/boss/revel1/duke_of_flakes_name.png",
        FilePrefix = "duke_of_flakes_",
        Entity = REVEL.GetBossEntityData("Duke of Flakes", "Duke of Flakes Placeholder"),
        Bestiary = "duke_of_flakes.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
    ]]
    --[[
    {
        Name = "Flurry",
        Portrait = "gfx/ui/boss/revel1/flurry_portrait.png",
        Bossname = "gfx/ui/boss/revel1/flurry_name.png",
        FilePrefix = "flurry_",
        Entity = REVEL.GetBossEntityData("Flurry Head", "Flurry Placeholder"),
        Bestiary = "flurry_jr.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
    ]]
    {
        Name = "Prong",
        Portrait = "gfx/ui/boss/revel1/prong_portrait.png",
        Bossname = "gfx/ui/boss/revel1/prong_name.png",
        FilePrefix = "prong_",
        Entity = REVEL.GetBossEntityData("Prong", "Prong Placeholder"),
        Bestiary = "prong.png",
        Stage = "Glacier",
        Offset = Vector(0, -32),
        Variants = {"Normal", "Champion"}
    },
    {
        Name = "Frost Rider",
        Portrait = "gfx/ui/boss/revel1/frost_rider_portrait.png",
        Bossname = "gfx/ui/boss/revel1/frost_rider_name.png",
        FilePrefix = "frost_rider_",
        Entity = REVEL.GetBossEntityData("Frost Rider"),
        Horseman = true,
        DeathTriggerEntity = REVEL.GetBossEntityData("Frost Rider Phase 2"),
        Bestiary = "frost_rider.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
    {
        Name = "Stalagmight",
        Portrait = "gfx/ui/boss/revel1/stalagmight_portrait.png",
        Bossname = "gfx/ui/boss/revel1/stalagmight_name.png",
        FilePrefix = "stalagmight_",
        Entity = REVEL.GetBossEntityData("Stalagmight"),
        DeathTriggerEntity = REVEL.GetBossEntityData("Stalagmight 2"),
        Bestiary = "stalagmight.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
    {
        Name = "Freezer Burn",
        Portrait = "gfx/ui/boss/revel1/freezer_burn_portrait.png",
        Bossname = "gfx/ui/boss/revel1/freezer_burn_name.png",
        RoomKeyPrefix = "FreezerBurn",
        FilePrefix = "freezer_burn_",
        Entity = REVEL.GetBossEntityData("Freezer Burn"),
        Bestiary = "freezer_burn.png",
        Stage = "Glacier",
        Variants = {"Normal", "Champion"}
    },
	{
        Name = "Wendy",
		Portrait = "gfx/ui/boss/revel1/wendy_portrait.png",
		Bossname = "gfx/ui/boss/revel1/wendy_name.png",
		RoomKeyPrefix = "Wendy",
		FilePrefix = "wendy_",
		Entity = REVEL.GetBossEntityData("Wendy"),
		Bestiary = "wendy.png",
		Stage = "Glacier",
		Variants = {"Normal", "Champion"}
    },
	{
        Name = "Williwaw",
		Portrait = "gfx/ui/boss/revel1/williwaw_portrait.png",
		Bossname = "gfx/ui/boss/revel1/williwaw_name.png",
		RoomKeyPrefix = "Williwaw",
		FilePrefix = "williwaw_",
		Entity = REVEL.GetBossEntityData("Williwaw"),
		Bestiary = "williwaw.png",
		Stage = "Glacier",
		Variants = {"Normal"}
    },
    {
        Name = "Chuck",
        IsMiniboss = true,
        FilePrefix = "chuck_",
        Entity = REVEL.GetBossEntityData("Chuck"),
        Weight = 1,
        Bestiary = "chuck.png",
        Stage = "Glacier",
        Variants = {"Normal"}
    },
    {
        Name = "Narcissus 1",
        Portrait = "gfx/ui/boss/revel1/narcissus_portrait.png",
		Bossname = "gfx/ui/boss/revel1/narcissus_name.png",
        Bestiary = "narc1.png",
        Entity = REVEL.GetBossEntityData("Narcissus"),
        Stage = "Glacier",
        Variants = {"Normal"},
        Mirror = true,
        IsMiniboss = true,
        NoStageAPI = true

	}
}

for _, boss in ipairs(REVEL.Bosses.ChapterOne) do
    boss.RoomKeyPrefix = boss.RoomKeyPrefix or boss.ListName or boss.Name
    boss.ListName = boss.ListName or boss.RoomKeyPrefix or boss.Name
end

REVEL.extend(REVEL.BossMenuSegments, {REVEL.Bosses.ChapterOne, "gfx/ui/bestiary/revel1/", "GLACIER_CHAMPIONS", "chapter one", true})

REVEL.GlacierBosses = {
    -- "Monsnow",
    -- "Duke of Flakes",
    -- "Flurry",
    "Frost Rider",
    "Stalagmight",
    "Freezer Burn",
	"Wendy",
    "Prong",
	"Williwaw"
}

REVEL.GlacierElites = {
    "Chuck"
}

REVEL.SinFilenames = {
    "envy_",
    "greed_",
    "lust_",
    "pride_",
    "wrath_",
    "sloth_",
    "gluttony_",
    "sins_"
}

REVEL.AddBossRooms("ChapterOne", "glacier", "revel1.bosses.", REVEL.RoomEditors)

REVEL.AddSinRooms("ChapterOne", "revel1.sins.", REVEL.RoomEditors)

--REVEL.AddGenericBossFiles(REVEL.Bosses.ChapterOne, "Revel1Boss", nil, "revel1.bosses.", REVEL.RoomEditors, {"Test"})

-- this will, for instance, set REVEL.Rooms["Revel1BossFreezerBurnBlorenge"] to require("resources.luarooms.revel1.bosses.freezer_burn_blorenge") if it exists.
--REVEL.PreloadBossRooms(REVEL.Bosses.ChapterOne, "Revel1Boss", nil, "revel1.bosses.", REVEL.RoomEditors, {"Test"})