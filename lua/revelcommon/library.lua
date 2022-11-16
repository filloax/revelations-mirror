local SubModules = {
    'lua.revelcommon.library.callback',
    'lua.revelcommon.library.sprite_cache',
    'lua.revelcommon.library.achievement_ui',
    'lua.revelcommon.library.active',
    'lua.revelcommon.library.audio',
    'lua.revelcommon.library.card',
    'lua.revelcommon.library.character_unlock',
    'lua.revelcommon.library.collectible',
    'lua.revelcommon.library.trinket',
    'lua.revelcommon.library.collision',
    'lua.revelcommon.library.color',
    'lua.revelcommon.library.death_events',
    'lua.revelcommon.library.debug',
    'lua.revelcommon.library.direction',
    'lua.revelcommon.library.entity',
    'lua.revelcommon.library.fake_animation',
    'lua.revelcommon.library.game',
    'lua.revelcommon.library.giantbook',
    'lua.revelcommon.library.grid',
    'lua.revelcommon.library.input',
    'lua.revelcommon.library.lerp',
    'lua.revelcommon.library.level',
    'lua.revelcommon.library.math',
    'lua.revelcommon.library.npc',
    'lua.revelcommon.library.npc_movement',
    'lua.revelcommon.library.orbit',
    'lua.revelcommon.library.pickup',
    'lua.revelcommon.library.bomb',
    'lua.revelcommon.library.pill',
    'lua.revelcommon.library.player',
    'lua.revelcommon.library.player_cutscene',
    'lua.revelcommon.library.position',
    'lua.revelcommon.library.projectile',
    'lua.revelcommon.library.effect',
    'lua.revelcommon.library.random',
    'lua.revelcommon.library.room',
    'lua.revelcommon.library.scale_entity',
    'lua.revelcommon.library.screen_size',
    'lua.revelcommon.library.shockwave',
    'lua.revelcommon.library.sprite',
    'lua.revelcommon.library.table',
    'lua.revelcommon.library.vector',
    'lua.revelcommon.library.visual',
    'lua.revelcommon.library.was_changed',
    'lua.revelcommon.library.render',
    'lua.revelcommon.library.vanilla_achievements',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Main Library!")

end