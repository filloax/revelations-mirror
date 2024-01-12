return function()

-- copied from the original mod support; credit: TaigaTreant
if CustomGameOver then
    local EnemyFrames = CustomGameOver.Entity.EnemyFrames
	local BossFrames = CustomGameOver.Entity.BossFrames
	local CustomSprites = CustomGameOver.Entity.CustomSprites
    local Offsets = CustomGameOver.Entity.Offsets
	local GetVariantID = function(ent) return CustomGameOver.Functions.GetVariantID(ent.id, ent.variant) end
    local GetSubTypeID = function(ent) return CustomGameOver.Functions.GetSubTypeID(ent.id, ent.variant, ent.subtype) end

    -- This function is used to make sure that definitions set by other mods are not overwritten.
	local function setIfNotExists(tbl, id, val)
		if tbl[id] == nil then
			tbl[id] = val
		end
	end

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FREEZER_BURN), "revel1/freezer_burn.png") -- Freezer Burn
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FREEZER_BURN_HEAD), "revel1/freezer_burn.png") -- Freezer Burn Head

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOW_FLAKE), "revel1/snow_flake.png") -- Snow Flake
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOW_FLAKE_BIG), "revel1/big_snow_flake.png") -- Big Snow Flake
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MONSNOW), "revel1/monsnow.png") -- Monsnow
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.DUKE_OF_FLAKES), "revel1/duke_of_flakes.png") -- The Duke of Flakes
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.STALAGMITE), "revel1/stalagmight.png") -- Stalagmight
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.STALAGMITE_2), "revel1/stalagmight.png") -- Stalagmight 2
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.STALAGMITE_SPIKE), "revel1/stalagmight.png") -- Stalagmight Spike

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.NARCISSUS), "revel1/narc1.png") -- Narc1
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.NARCISSUS_MONSTROS_TOOTH), "revel1/narc1.png") -- Monstro tooth for narc
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.NARCISSUS_DOCTORS_ROCKET), "revel1/narc1.png") -- Doctors remote rocket for narc

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOWBALL), "revel1/snowball.png") -- Snowball
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_SNOWBALL), "revel1/yellowsnowball.png") -- Yellow Snowball
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.STRAWBERRY_SNOWBALL), "revel1/strawberrysnowball.png") -- Yellow Snowball
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.BLOCKHEAD), "revel1/block_gaper.png") -- Blockhead
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CARDINAL_BLOCKHEAD), "revel1/cardinal_block_gaper.png") -- Cardinal Blockhead
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_BLOCKHEAD), "revel1/block_gaper.png") -- Yellow Blockhead
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD), "revel1/cardinal_block_gaper.png") -- Yellow Cardinal Blockhead
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.BLOCK_GAPER), "revel1/block_gaper.png") -- Block Gaper
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CARDINAL_BLOCK_GAPER), "revel1/cardinal_block_gaper.png") -- Cardinal Block Gaper
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_BLOCK_GAPER), "revel1/block_gaper.png") -- Yellow Block Gaper
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER), "revel1/cardinal_block_gaper.png") -- Yellow Cardinal Block Gaper
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.GEICER), "revel1/geicer.png") -- Geicer

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FROZEN_SPIDER), "revel1/blue_ambered_spider.png") -- Iced Spider
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.YELLOW_FROZEN_SPIDER), "revel1/blue_ambered_spider.png") -- Yellow Iced Spider

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FLURRY_BODY), "revel1/flurry_jr.png") -- Flurry Jr. Body
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FLURRY_HEAD), "revel1/flurry_jr.png") -- Flurry Jr. Head
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FLURRY_FROZEN_BODY), "revel1/flurry_jr.png") -- Flurry Jr. Body Frozen

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.DRIFTY), "revelcommon/drifty.png") -- Drifty

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.HICE), "revel1/hice.png") -- Hice
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CLOUDY), "revel1/cloudy.png") -- Cloudy
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SMOLYCEPHALUS), "revelcommon/smolycephalus.png") -- Smolycephalus
	-- Ice Hazard Gaper?
	-- Ice Hazard Drifty?
	-- Ice Hazard I.Blob?
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PUNKER), "revelcommon/punker.png") -- Punker
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PUCKER), "revelcommon/pucker.png") -- Pucker
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.BRAINFREEZE), "revel1/brainfreeze.png") -- Brainfreeze
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.ROLLING_SNOWBALL), "revel1/rolling_snowball.png") -- Rolling Snowball
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOWBOB), "revel1/snowbob.png") -- Snowbob
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOWBOB_HEAD), "revel1/snowbob.png") -- Snowbob Head
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOWBOB_HEAD2), "revel1/snowbob.png") -- Snowbob Head (tears)
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FATSNOW), "revel1/fatsnow.png") -- Fatsnow
	
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SNOWST), "revel1/snowst.png") -- Snowst
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SICKIE), "revel1/sickie.png") -- Sickie
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SHY_FLY), "revel1/shyfly.png") -- Shy Fly
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CRYO_FLY), "revel1/cryofly.png") -- Cryo Fly
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SASQUATCH), "revel1/sasquatch.png") -- Sasquatch
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.TUSKY), "revel1/tusky.png") -- Tusky
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.HUFFPUFF), "revel1/huffpuff.png") -- HuffPuff
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.EMPEROR), "revel1/emperor.png") -- Emperor
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.COAL_HEATER), "revel1/coalheater.png") -- Coal Heater
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.AVALANCHE), "revel1/avalanche.png") -- Avalanche
	
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.JAUGR), "revel1/jaugr.png") -- Jaugr
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.HAUGR), "revel1/haugr.png") -- Haugr
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.DRAUGR), "revel1/draugr.png") -- Draugr
	-- Chill O Wisp?
	-- Grill O Wisp?
	
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FLURRY_ICE_BLOCK), "revel1/flurry_jr.png") -- Flurry Ice Block
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FLURRY_ICE_BLOCK_YELLOW), "revel1/flurry_jr.png") -- Flurry Ice Block Yellow

	-- Brother Bloody

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FROST_RIDER), "revel1/frost_rider.png") -- Frost Rider
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FROST_RIDER_HEAD), "revel1/frost_rider.png") -- Frost Rider 2
	
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.WENDY), "revel1/wendy.png") -- Wendy
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.WENDY_SNOWPILE), "revel1/wendy.png") -- Wendy Snowpile
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.WENDY_STALAGMITE), "revel1/wendy.png") -- Wendy Stalagmite
	
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PRONG), "revel1/prong.png") -- Prong
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PRONG_STATUE), "revel1/prong.png") -- Prong Statue
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PRONG_ICE_BOMB), "revel1/prong.png") -- Prong Ice Bomb

    -- Ice Pooter

    -- Iced Hive
	-- Stalactrite
	-- Ice Worm
	-- Yellow Snow

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.LIGHTABLE_FIRE), "revel1/lightablefire.png") -- Freezer Burn Fireplace

	-- Rag Tag
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.ARROWHEAD), "revel2/arrowhead.png") -- Arrowhead
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_GAPER), "revel2/raggaper.png") -- Rag Gaper
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_GAPER_HEAD), "revel2/raggaper.png") -- Rag Gaper Head
	-- Rag Gusher
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SANDBOB), "revel2/sandbob.png") -- Sandbob
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SANDBIP), "revel2/sandbip.png") -- Sandbip
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.DEMOBIP), "revel2/demobip.png") -- Demobip
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.BLOATBIP), "revel2/bloatbip.png") -- Bloatbip
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.ANTLION), "revel2/antlion.png") -- Antlion

	-- Catastrophe
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CATASTROPHE_CRICKET), "revel2/catastrophe.png") -- Cricket
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CATASTROPHE_TAMMY), "revel2/catastrophe.png") -- Tammy
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CATASTROPHE_GUPPY), "revel2/catastrophe.png") -- Guppy
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CATASTROPHE_MOXIE), "revel2/catastrophe.png") -- Moxie
		-- Yarn?

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PYRAMID_HEAD), "revel2/pyramidhead.png") -- Pyramid Head
	-- Arrow Trap
	-- Sand Boulder
	-- Flame Trap
		-- Flame Trap Fire
	-- Aragnid
		-- Aragnid Innard
	-- Anima
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.LOCUST), "revel2/locust.png") -- Locust
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_BONY), "revel2/ragbony.png") -- Rag Bony
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MOTHER_PUCKER), "revelcommon/motherpucker.png") -- Mother Pucker
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.AEROTOMA), "revelcommon/aerotoma.png") -- Aerotoma
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_TRITE), "revel2/ragtrite.png") -- Rag Trite
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.INNARD), "revel2/innard.png") -- Innard

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MAXWELL), "revel2/maxwell.png") -- Maxwell
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MAXWELL_DOOR), "revel2/maxwell.png") -- Maxwell Door
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MAXWELL_TRAP), "revel2/maxwell.png") -- Maxwell Trap

    -- Necragmanger
		-- Necragmanger (No shut doors)
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.WRETCHER), "revel2/wretcher.png") -- Wretcher
	-- Sandshaper
	-- Prank
	-- Prank (Glacier)
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.URNY), "revel2/urny.png") -- Urny
	-- Cannonbip
		-- Cannonbip Projectile
	-- Snipebip
	-- Trenchbip
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_FATTY), "revel2/ragfatty.png") -- Rag Fatty

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.NARCISSUS_2), "revel2/narc2.png") -- Narc 2
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.MEGASHARD), "revel2/narc2.png") -- Narc 2 Megashard
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.GLASS_SPIKE), "revel2/narc2.png")-- Narc 2 Spike
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.NARCISSUS_2_NPC), "revel2/narc2.png") -- Narc 2 NPC

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FIRECALLER_GLACIER), "revel1/firecaller.png") -- Firecaller (Glacier)
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.FIRECALLER), "revel1/firecaller.png") -- Firecaller (Tomb)

	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SARCOPHAGUTS), "revel2/sarcophaguts.png") -- Sarcophaguts
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SARCOPHAGUTS_HEAD), "revel2/sarcophaguts.png") -- Sarc Head
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SARCGUT), "revel2/sarcophaguts.png") -- Sarcgut

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SAND_WORM), "revel2/sandworm.png") -- Sand Worm
	-- Skitterpill Good
		-- Card Variant?
	-- Skitterpill Bad
		-- Card Variant?
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PEASHY), "revel2/peashy.png") -- Peashy
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PEASHY_NAIL), "revel2/peashy.png") -- Peashy Nail
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CHICKEN), "revelcommon/chicken.png") -- Chicken
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.BUTTON_MASHER), "revel2/buttonmasher.png") -- Button Masher
	-- Slambip
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAGING_LONG_LEGS), "revelcommon/raging_long_legs.png") -- Raging Long Legs
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.TILE_MONGER), "revel2/tilemonger.png") -- Tile Monger
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.RAG_DRIFTY), "revel2/ragdrifty.png") -- Rag Drifty
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.PSEUDO_RAG_DRIFTY), "revel2/pseudoragdrifty.png") -- Pseudo Rag Drifty
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.ANTLION_BABY), "revel2/antlionBABY.png") -- Antlion Baby

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.SANDY), "revel2/sandy.png") -- Sandy
		-- Sandy (no shadow)

	-- Jeffrey (Baby)?
	-- Sandhole trap?
	-- Small grill o wisp?
	-- Ice Hazard Brother Bloody?

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CHUCK), "revel1/chuck.png") -- Chuck
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.CHUCK_ICE_BLOCK), "revel1/chuck.png") -- Chuck Ice Block

    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.DUNGO), "revel2/dungo.png") -- Dungo
	setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.POOP_BOULDER), "revel2/dungo.png") -- Poop Boulder*

    -- Bomb Sack
    setIfNotExists(CustomSprites, GetVariantID(REVEL.ENT.STONE_CREEP), "revel2/stonecreep.png") -- Stone Creep

    Isaac.DebugString("Revelations: Loaded Custom Game Over support!")
end

end