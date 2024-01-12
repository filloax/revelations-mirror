local SubModules = {
    'lua.revelcommon.entities.enemies.aerotoma',
    'lua.revelcommon.entities.enemies.brother_bloody',
    'lua.revelcommon.entities.enemies.chicken',
    'lua.revelcommon.entities.enemies.drifty',
    'lua.revelcommon.entities.enemies.mother_pucker',
    'lua.revelcommon.entities.enemies.smolycephalus',

    'lua.revelcommon.entities.machines.basic',
    'lua.revelcommon.entities.machines.revending',
    'lua.revelcommon.entities.machines.statwheel',
    'lua.revelcommon.entities.machines.rev_restock',

    'lua.revelcommon.entities.misc.aura',
    'lua.revelcommon.entities.misc.decorations',
    'lua.revelcommon.entities.misc.glow',
    'lua.revelcommon.entities.misc.smoly_for_scale',
    'lua.revelcommon.entities.misc.spotlight',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    
REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Generic Entities!")
end