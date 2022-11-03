local SubModules = {
    'lua.revelcommon.dante.basic',
    'lua.revelcommon.dante.phylactery',
    'lua.revelcommon.dante.separate_chars',
    'lua.revelcommon.dante.main_logic',
    'lua.revelcommon.dante.map',
    'lua.revelcommon.dante.partner',
    'lua.revelcommon.dante.charon_oar',
    'lua.revelcommon.dante.dante_book',
    'lua.revelcommon.dante.misc',
    'lua.revelcommon.dante.birthright',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Charon!")
end
REVEL.PcallWorkaroundBreakFunction()