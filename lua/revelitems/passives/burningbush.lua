local SubModules = {
    'lua.revelitems.passives.burningbush.burningbush',
    'lua.revelitems.passives.burningbush.bush_synergies',
}
local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    REVEL.RunLoadFunctions(SubLoadFunctions)
end