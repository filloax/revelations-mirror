local hub2 = require "scripts.hubroom2"

local game = Game()

-- SFX --

hub2.SFX = {
	HUB_ROOM = Isaac.GetMusicIdByName("Hub Room 2.0"),
}

StageAPI.StopOverridingMusic(hub2.SFX.HUB_ROOM)

-- GRIDS --

hub2.GRIDENT = {
	HUB2_STATUE = StageAPI.CustomGrid("Hub2 Statue", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "stageapi/none.anm2", 
		Animation = "None"
	})
}

-- HUB --

hub2.VanillaHub2Quads = {
	[LevelStage.STAGE1_1] = "cellar",
	[LevelStage.STAGE1_2] = "cellar",
	[LevelStage.STAGE2_1] = "caves",
	[LevelStage.STAGE2_2] = "caves",
	[LevelStage.STAGE3_1] = "depths",
	[LevelStage.STAGE3_2] = "depths"
}

hub2.RepHub2Quads = {
	[LevelStage.STAGE1_1] = "downpour",
	[LevelStage.STAGE1_2] = "downpour",
	[LevelStage.STAGE2_1] = "mines",
	[LevelStage.STAGE2_2] = "mines",
	[LevelStage.STAGE3_1] = "mausoleum",
	[LevelStage.STAGE3_2] = "mausoleum"
}

hub2.RepHub2Doors = {
	Downpour = "gfx/grid/door_downpour.anm2",
	Mines = "gfx/grid/door_mines.anm2",
	Mausoleum = "gfx/grid/door_mausoleum.anm2"
}

hub2.Hub2TrapdoorSpots = {
	[DoorSlot.LEFT0] = 62,
	[DoorSlot.UP0] = 37,
	[DoorSlot.RIGHT0] = 72,
	[DoorSlot.DOWN0] = 97
}

hub2.Hub2CustomTrapdoors = {
	Downpour = {
		Anm2 = "gfx/grid/trapdoor_downpour.anm2",
		StageType = "rep",
		Stage = LevelStage.STAGE1_2
	},
	Mines = {
		Anm2 = "gfx/grid/trapdoor_mines.anm2",
		StageType = "rep",
		Stage = LevelStage.STAGE2_2
	},
	Mausoleum = {
		Anm2 = "gfx/grid/trapdoor_mausoleum.anm2",
		StageType = "rep",
		Stage = LevelStage.STAGE3_2
	}
}

-- STATUES --

---@type Hub2.Statue[]
hub2.Hub2Statues = {
	{ -- Isaac
		StatueFrame = 0,
		TrinketDrop = TrinketType.TRINKET_ISAACS_HEAD,
		SoulDrop = Card.CARD_SOUL_ISAAC,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.CARD_DICE_SHARD}
	},
	{ -- Samson
		StatueFrame = 1,
		TrinketDrop = TrinketType.TRINKET_SAMSONS_LOCK,
		SoulDrop = Card.CARD_SOUL_SAMSON,
		ConsumableCount = 2,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_BOMB}
	},
	{ -- Keeper
		StatueFrame = 2,
		TrinketDrop = TrinketType.TRINKET_KEEPERS_BARGAIN,
		SoulDrop = Card.CARD_SOUL_KEEPER,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME}
	},
	{ -- Magdalene
		StatueFrame = 4,
		TrinketDrop = TrinketType.TRINKET_MAGGYS_FAITH,
		SoulDrop = Card.CARD_SOUL_MAGDALENE,
		ConsumableCount = 3,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_FULL}
	},
	{ -- Azazel
		StatueFrame = 5,
		TrinketDrop = TrinketType.TRINKET_AZAZELS_STUMP,
		SoulDrop = Card.CARD_SOUL_AZAZEL,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_BLACK}
	},
	{ -- Apollyon
		StatueFrame = 6,
		TrinketDrop = TrinketType.TRINKET_APOLLYONS_BEST_FRIEND,
		SoulDrop = Card.CARD_SOUL_APOLLYON,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.RUNE_BLACK}
	},
	{ -- Cain
		StatueFrame = 8,
		TrinketDrop = TrinketType.TRINKET_CAINS_EYE,
		SoulDrop = Card.CARD_SOUL_CAIN,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_LUCKYPENNY}
	},
	{ -- Lazarus
		StatueFrame = 9,
		AltStatueFrame = 24,
		--TrinketDrop = TrinketType.TRINKET_,
		SoulDrop = Card.CARD_SOUL_LAZARUS,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_PILL},
		AltConditions = function()
			for i=0, game:GetNumPlayers() - 1 do
				local player = Isaac.GetPlayer(i)
				if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2 then
					return true
				end
			end
			
			return false
		end
	},
	{ -- Forgotten
		StatueFrame = 10,
		TrinketDrop = TrinketType.TRINKET_FINGER_BONE,
		SoulDrop = Card.CARD_SOUL_FORGOTTEN,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_BONE}
	},
	{ -- Judas
		StatueFrame = 12,
		TrinketDrop = TrinketType.TRINKET_JUDAS_TONGUE,
		SoulDrop = Card.CARD_SOUL_JUDAS,
		ConsumableCount = 3,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_COIN}
	},
	{ -- Eden
		StatueFrame = 13,
		TrinketDrop = TrinketType.TRINKET_M,
		SoulDrop = Card.CARD_SOUL_EDEN,
		ConsumableCount = 1,
		ConsumableDrop = {} -- random pickup
	},
	{ -- Bethany
		StatueFrame = 14,
		TrinketDrop = TrinketType.TRINKET_BETHS_FAITH,
		SoulDrop = Card.CARD_SOUL_BETHANY,
		WispCount = 4
	},
	{ -- Blue Baby
		StatueFrame = 16,
		TrinketDrop = TrinketType.TRINKET_SOUL,
		SoulDrop = Card.CARD_SOUL_BLUEBABY,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_SOUL}
	},
	{ -- The Lost
		StatueFrame = 17,
		TrinketDrop = TrinketType.TRINKET_WOODEN_CROSS,
		SoulDrop = Card.CARD_SOUL_LOST,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.CARD_HOLY}
	},
	{ -- Jacob
		StatueFrame = 18,
		TrinketDrop = TrinketType.TRINKET_THE_TWINS,
		SoulDrop = Card.CARD_SOUL_JACOB,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.CARD_SUN}
	},
	{ -- Eve
		StatueFrame = 20,
		TrinketDrop = TrinketType.TRINKET_EVES_BIRD_FOOT,
		SoulDrop = Card.CARD_SOUL_EVE,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_HEART, SubType = HeartSubType.HEART_BLENDED}
	},
	{ -- Lilith
		StatueFrame = 21,
		TrinketDrop = TrinketType.TRINKET_ADOPTION_PAPERS,
		SoulDrop = Card.CARD_SOUL_LILITH,
		FlyCount = 5,
		SpiderCount = 5
	},
	{ -- Esau
		StatueFrame = 22,
		TrinketDrop = TrinketType.TRINKET_THE_TWINS,
		SoulDrop = Card.CARD_SOUL_JACOB,
		ConsumableCount = 1,
		ConsumableDrop = {Variant = PickupVariant.PICKUP_TAROTCARD, SubType = Card.CARD_MOON}
	},
}

--[[
statueData = {
	-- sprite of the statue (can either be done using the anm2, or a statue frame explained below)
	StatueAnm2 = String,
	StatueAnimation = String, -- takes default animation if not set
	
	-- statue frames can be used instead of an anm2 if it needs one of the vanilla statue frames
	StatueFrame = Integer,
	AltStatueFrame = Integer,
	
	-- alt sprite of the statue if AltConditions returns true (optional)
	AltStatueAnm2 = String,
	AltStatueAnimation = String, -- takes default animation if not set
	AltConditions = Function,
	
	-- statue drops (optional, 25% chance)
	TrinketDrop = TrinketType Enum, -- default drop normally, if set, unlocked en not encountered already by the player
	SoulDrop = Card Enum, -- rare drop, 20% chance to drop if set and unlocked by the player
	ConsumableCount = Integer, -- the number of ConsumableDrop (field below) drops
	ConsumableDrop = {Variant = PickupVariant Enum, SubType = Integer} -- Variant and SubType can be left out for randomizing the consumable
	WispCount = Integer -- Statue drops a number of wisps as consumables drop
	FlyCount = Integer -- Statue drops a number of blue flies as consumables drop
	SpiderCount = Integer -- Statue drops a number of blue spiders as consumables drop
}
]]