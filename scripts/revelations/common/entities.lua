local SubModules = {
    'scripts.revelations.common.entities.enemies.aerotoma',
    'scripts.revelations.common.entities.enemies.brother_bloody',
    'scripts.revelations.common.entities.enemies.chicken',
    'scripts.revelations.common.entities.enemies.drifty',
    'scripts.revelations.common.entities.enemies.mother_pucker',
    'scripts.revelations.common.entities.enemies.smolycephalus',

    'scripts.revelations.common.entities.machines.basic',
    'scripts.revelations.common.entities.machines.revending',
    'scripts.revelations.common.entities.machines.statwheel',
    'scripts.revelations.common.entities.machines.rev_restock',

    'scripts.revelations.common.entities.misc.aura',
    'scripts.revelations.common.entities.misc.decorations',
    'scripts.revelations.common.entities.misc.glow',
    'scripts.revelations.common.entities.misc.smoly_for_scale',
    'scripts.revelations.common.entities.misc.spotlight',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    
REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Generic Entities!")
end