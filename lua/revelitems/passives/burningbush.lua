local SubModules = {
    'lua.revelitems.passives.burningbush.burningbush',
    'lua.revelitems.passives.burningbush.bush_synergies',
}
local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)
end