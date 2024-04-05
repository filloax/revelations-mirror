local SubModules = {
	"scripts.revelations.chapter1.entities.init",

	'scripts.revelations.chapter1.entities.chill.brainfreeze',
	'scripts.revelations.chapter1.entities.chill.coal_heater',
	'scripts.revelations.chapter1.entities.chill.draugr',
	'scripts.revelations.chapter1.entities.chill.will_o_wisps',
	
	'scripts.revelations.chapter1.entities.ice.block_gaper',
	'scripts.revelations.chapter1.entities.ice.iced_hive',
	'scripts.revelations.chapter1.entities.ice.ice_spider',
	'scripts.revelations.chapter1.entities.ice.ice_pooter',
	'scripts.revelations.chapter1.entities.ice.stalactrite',

	'scripts.revelations.chapter1.entities.snow.avalanche',
	'scripts.revelations.chapter1.entities.snow.cloudy',
	'scripts.revelations.chapter1.entities.snow.fatsnow',
	'scripts.revelations.chapter1.entities.snow.hice',
	'scripts.revelations.chapter1.entities.snow.huffpuff',
	'scripts.revelations.chapter1.entities.snow.neap_snowballs',
	'scripts.revelations.chapter1.entities.snow.rolling_snowball',
	'scripts.revelations.chapter1.entities.snow.snowbob',
	'scripts.revelations.chapter1.entities.snow.snowflake',
	'scripts.revelations.chapter1.entities.snow.snowst',

	'scripts.revelations.chapter1.entities.stage.big_blowy',
	'scripts.revelations.chapter1.entities.stage.frost_shooter',
	'scripts.revelations.chapter1.entities.stage.hockey_puck',
	'scripts.revelations.chapter1.entities.stage.ice_hazard',
	'scripts.revelations.chapter1.entities.stage.igloo',
	'scripts.revelations.chapter1.entities.stage.lightable_fire',
	'scripts.revelations.chapter1.entities.stage.stalactite',

	'scripts.revelations.chapter1.entities.unique.cryo_fly',
	'scripts.revelations.chapter1.entities.unique.emperor',
	'scripts.revelations.chapter1.entities.unique.geicer',
	'scripts.revelations.chapter1.entities.unique.ice_worm',
	'scripts.revelations.chapter1.entities.unique.sasquatch',
	'scripts.revelations.chapter1.entities.unique.shy_fly',
	'scripts.revelations.chapter1.entities.unique.sickie',
	'scripts.revelations.chapter1.entities.unique.tusky',
	'scripts.revelations.chapter1.entities.unique.harfang',
	'scripts.revelations.chapter1.entities.unique.pine',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Chapter 1 Entities!")
end