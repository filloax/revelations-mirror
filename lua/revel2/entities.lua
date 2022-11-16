local SubModules = {
	"lua.revel2.entities.init",

	'lua.revel2.entities.bips.basic',
	'lua.revel2.entities.bips.cannonbip',
	'lua.revel2.entities.bips.sandshaper',
	'lua.revel2.entities.bips.slambip',
	'lua.revel2.entities.bips.snipebip',
	'lua.revel2.entities.bips.trenchbip',
	
	'lua.revel2.entities.ragfolk.homing_gusher',
	'lua.revel2.entities.ragfolk.ragtag',
	'lua.revel2.entities.ragfolk.rag_bony',
	'lua.revel2.entities.ragfolk.rag_drifty',
	'lua.revel2.entities.ragfolk.rag_fatty',
	'lua.revel2.entities.ragfolk.rag_gaper',
	'lua.revel2.entities.ragfolk.rag_trite',
	'lua.revel2.entities.ragfolk.ragma',
	'lua.revel2.entities.ragfolk.ragurge',
	'lua.revel2.entities.ragfolk.wretcher',

	'lua.revel2.entities.rezzers.anima',
	'lua.revel2.entities.rezzers.necragmancer',

	'lua.revel2.entities.stage.button_masher',
	'lua.revel2.entities.stage.stone_creep',
	'lua.revel2.entities.stage.urny',

	'lua.revel2.entities.unique.antlion',
	'lua.revel2.entities.unique.antlion_baby',
	'lua.revel2.entities.unique.arrowhead',
	'lua.revel2.entities.unique.dune',
	'lua.revel2.entities.unique.firecaller',
	'lua.revel2.entities.unique.innard',
	'lua.revel2.entities.unique.locust',
	'lua.revel2.entities.unique.peashy',
	'lua.revel2.entities.unique.pyramidhead',
	'lua.revel2.entities.unique.sand_worm',
	'lua.revel2.entities.unique.tile_monger',
	'lua.revel2.entities.unique.jackal',
	'lua.revel2.entities.unique.gilded_jackal',
	'lua.revel2.entities.unique.stabstack',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Chapter 2 Entities!")

end