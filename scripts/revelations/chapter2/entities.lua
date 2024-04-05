local SubModules = {
	"scripts.revelations.chapter2.entities.init",

	'scripts.revelations.chapter2.entities.bips.basic',
	'scripts.revelations.chapter2.entities.bips.cannonbip',
	'scripts.revelations.chapter2.entities.bips.sandshaper',
	'scripts.revelations.chapter2.entities.bips.sandstorm',
	'scripts.revelations.chapter2.entities.bips.slambip',
	'scripts.revelations.chapter2.entities.bips.snipebip',
	'scripts.revelations.chapter2.entities.bips.trenchbip',
	
	'scripts.revelations.chapter2.entities.ragfolk.homing_gusher',
	'scripts.revelations.chapter2.entities.ragfolk.ragtag',
	'scripts.revelations.chapter2.entities.ragfolk.rag_bony',
	'scripts.revelations.chapter2.entities.ragfolk.rag_drifty',
	'scripts.revelations.chapter2.entities.ragfolk.rag_fatty',
	'scripts.revelations.chapter2.entities.ragfolk.rag_gaper',
	'scripts.revelations.chapter2.entities.ragfolk.rag_trite',
	'scripts.revelations.chapter2.entities.ragfolk.ragma',
	'scripts.revelations.chapter2.entities.ragfolk.ragurge',
	'scripts.revelations.chapter2.entities.ragfolk.wretcher',

	'scripts.revelations.chapter2.entities.rezzers.anima',
	'scripts.revelations.chapter2.entities.rezzers.necragmancer',

	'scripts.revelations.chapter2.entities.stage.button_masher',
	'scripts.revelations.chapter2.entities.stage.stone_creep',
	'scripts.revelations.chapter2.entities.stage.urny',

	'scripts.revelations.chapter2.entities.unique.antlion',
	'scripts.revelations.chapter2.entities.unique.antlion_baby',
	'scripts.revelations.chapter2.entities.unique.arrowhead',
	'scripts.revelations.chapter2.entities.unique.dune',
	'scripts.revelations.chapter2.entities.unique.firecaller',
	'scripts.revelations.chapter2.entities.unique.innard',
	'scripts.revelations.chapter2.entities.unique.locust',
	'scripts.revelations.chapter2.entities.unique.peashy',
	'scripts.revelations.chapter2.entities.unique.pyramidhead',
	'scripts.revelations.chapter2.entities.unique.sand_worm',
	'scripts.revelations.chapter2.entities.unique.tile_monger',
	'scripts.revelations.chapter2.entities.unique.jackal',
	'scripts.revelations.chapter2.entities.unique.gilded_jackal',
	'scripts.revelations.chapter2.entities.unique.stabstack',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Chapter 2 Entities!")

end