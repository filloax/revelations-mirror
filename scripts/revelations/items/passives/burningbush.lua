local SubModules = REVEL.PrefixAll("scripts.revelations.items.passives.burningbush.", {
    'burningBush',
    'bushSynergies',
})
local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)
end