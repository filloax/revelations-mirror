local SubModules = {
    -- sprite cache and entity data should be loaded before other things
    "scripts.revelations.common.library.spriteCache",
    'scripts.revelations.common.library.entity.entityData',
  
    'scripts.revelations.common.library.math.math',
    'scripts.revelations.common.library.math.vector',
    'scripts.revelations.common.library.math.vec3d',
    'scripts.revelations.common.library.math.direction',
    'scripts.revelations.common.library.math.collision',

    'scripts.revelations.common.library.achievements',
    'scripts.revelations.common.library.audio',
    'scripts.revelations.common.library.color',

    'scripts.revelations.common.library.callbacks.callbacks',
    'scripts.revelations.common.library.callbacks.tearSounds',

    'scripts.revelations.common.library.entity.entity',
    'scripts.revelations.common.library.entity.player',
    'scripts.revelations.common.library.entity.bomb',
    'scripts.revelations.common.library.entity.pickup',
    'scripts.revelations.common.library.entity.rerollables',
    'scripts.revelations.common.library.entity.knife',
    'scripts.revelations.common.library.entity.projectile',
    'scripts.revelations.common.library.entity.npc',
    'scripts.revelations.common.library.entity.reskins',
    'scripts.revelations.common.library.entity.pathfinding',
    'scripts.revelations.common.library.entity.boss',
    'scripts.revelations.common.library.entity.effect',
    'scripts.revelations.common.library.entity.particles',

    'scripts.revelations.common.library.airmovement.airmovement',

    'scripts.revelations.common.library.items.items',
    'scripts.revelations.common.library.items.pocketItems',
    'scripts.revelations.common.library.items.customchargebars',
    'scripts.revelations.common.library.items.inventory',

    'scripts.revelations.common.library.minimap',
    'scripts.revelations.common.library.reflections',
    'scripts.revelations.common.library.shaders',
    'scripts.revelations.common.library.utils',
    'scripts.revelations.common.library.gameMisc',
    'scripts.revelations.common.library.room',
    'scripts.revelations.common.library.level',
    'scripts.revelations.common.library.input',
    'scripts.revelations.common.library.position',
    'scripts.revelations.common.library.random',
    'scripts.revelations.common.library.sprite',
    'scripts.revelations.common.library.table',
    'scripts.revelations.common.library.hud',
    'scripts.revelations.common.library.debug',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Main Library!")

end