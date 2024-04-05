local GridBreakState = require "scripts.revelations.common.enums.GridBreakState"

return function ()

---@type table<string, CustomGrid>
REVEL.GRIDENT = {
    INVISIBLE_BLOCK = StageAPI.CustomGrid("Invisible Block", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "stageapi/none.anm2", 
		Animation = "None"
	}),
    VANITY_TRAPDOOR = StageAPI.CustomGrid("Revelations Vanity Trapdoor"),
    HUB_TRAPDOOR = StageAPI.CustomGrid("Revelations Hub Trapdoor"),

    BRAZIER = StageAPI.CustomGrid("Brazier", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "gfx/effects/revel1/brazier.anm2", 
		Animation = "Flickering",
        SpawnerEntity = {
            Type = 656,
            Variant = 6,
        },
	}),
    FRAGILE_ICE = StageAPI.CustomGrid("Fragile Ice", {
		BaseType = GridEntityType.GRID_DECORATION, 
		Anm2 = "gfx/grid/revel1/ice_crack.anm2", 
		Animation = "Start",
		ForceSpawning = true
	}),
    TOUGH_ICE = StageAPI.CustomGrid("Tough Ice", {
		BaseType = GridEntityType.GRID_ROCKB, 
		Anm2 = "gfx/effects/revel1/tough_ice.anm2", 
		Animation = "Idle", 
		Frame = 1, 
		VariantFrames = 4,
        SpawnerEntity = {
            Type = 656,
            Variant = 7,
        },
	}),
    EXPLODING_SNOWMAN = StageAPI.CustomGrid("Exploding Snowman", {
		BaseType = GridEntityType.GRID_POOP, 
		Anm2 = "gfx/grid/revel1/exploding_snowman.anm2", 
		Animation = "Idle", 
		OverrideGridSpawns = true, 
		OverrideGridSpawnsState = GridBreakState.BROKEN_POOP,
        SpawnerEntity = {
            Type = 199,
            Variant = 740,
        }
	}),
    FROZEN_BODY = StageAPI.CustomGrid("Inferno Frozen Body", {
        BaseType = GridEntityType.GRID_ROCK_ALT,
        Anm2 = "gfx/grid/revel1/frozen_bodies.anm2",
        Animation = "Bodies",
        VariantFrames = 12,
        OverrideGridSpawns = true,
        OverrideGridSpawnsState = GridBreakState.BROKEN_ROCK,
        SpawnerEntity = {
            Type = 199,
            Variant = 741,
        },
    }),

    SAND_CASTLE = StageAPI.CustomGrid("SandCastle", {
		BaseType = GridEntityType.GRID_POOP, 
		Anm2 = "gfx/grid/revel2/sand_castle.anm2", 
		Animation = "Default", 
		OverrideGridSpawns = true, 
		OverrideGridSpawnsState = GridBreakState.BROKEN_POOP,
	}),
    FLAMING_TOMB = StageAPI.CustomGrid("Flaming Tomb", {
        BaseType = GridEntityType.GRID_PILLAR,
        -- Anm2 = "gfx/blank.anm2",
    }),
}

end