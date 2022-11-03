local SubModules = {
	"lua.revel1.entities.init",

	'lua.revel1.entities.chill.brainfreeze',
	'lua.revel1.entities.chill.coal_heater',
	'lua.revel1.entities.chill.draugr',
	'lua.revel1.entities.chill.will_o_wisps',
	
	'lua.revel1.entities.ice.block_gaper',
	'lua.revel1.entities.ice.iced_hive',
	'lua.revel1.entities.ice.ice_spider',
	'lua.revel1.entities.ice.ice_pooter',
	'lua.revel1.entities.ice.stalactrite',

	'lua.revel1.entities.snow.avalanche',
	'lua.revel1.entities.snow.cloudy',
	'lua.revel1.entities.snow.fatsnow',
	'lua.revel1.entities.snow.hice',
	'lua.revel1.entities.snow.huffpuff',
	'lua.revel1.entities.snow.neap_snowballs',
	'lua.revel1.entities.snow.rolling_snowball',
	'lua.revel1.entities.snow.snowbob',
	'lua.revel1.entities.snow.snowflake',
	'lua.revel1.entities.snow.snowst',

	'lua.revel1.entities.stage.big_blowy',
	'lua.revel1.entities.stage.frost_shooter',
	'lua.revel1.entities.stage.hockey_puck',
	'lua.revel1.entities.stage.ice_hazard',
	'lua.revel1.entities.stage.igloo',
	'lua.revel1.entities.stage.lightable_fire',
	'lua.revel1.entities.stage.stalactite',

	'lua.revel1.entities.unique.cryo_fly',
	'lua.revel1.entities.unique.emperor',
	'lua.revel1.entities.unique.geicer',
	'lua.revel1.entities.unique.ice_worm',
	'lua.revel1.entities.unique.sasquatch',
	'lua.revel1.entities.unique.shy_fly',
	'lua.revel1.entities.unique.sickie',
	'lua.revel1.entities.unique.tusky',
	'lua.revel1.entities.unique.harfang',
	'lua.revel1.entities.unique.pine',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Chapter 1 Entities!")
end

REVEL.PcallWorkaroundBreakFunction()