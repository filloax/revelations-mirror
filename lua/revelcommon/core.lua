local SubModules = {
    'lua.revelcommon.core.clearcache',
    'lua.revelcommon.core.update_shared',
    'lua.revelcommon.core.callbacks',
    'lua.revelcommon.core.misc',

    'lua.revelcommon.core.inventory',
    'lua.revelcommon.core.unlocks',

    'lua.revelcommon.core.dynamic_item_weights',
    'lua.revelcommon.core.airmovement',
    'lua.revelcommon.core.customchargebars',
    'lua.revelcommon.core.lights',
    'lua.revelcommon.core.vec3d',
    'lua.revelcommon.core.particles',
    'lua.revelcommon.core.pathfinding',
    'lua.revelcommon.core.reflections',
    'lua.revelcommon.core.reskins',
    'lua.revelcommon.core.shaders',
    'lua.revelcommon.core.tear_sounds',
    'lua.revelcommon.core.custom_pill_colors',
    'lua.revelcommon.core.spring_player',
    'lua.revelcommon.core.music_cues',
    'lua.revelcommon.core.vanilla_music',
    'lua.revelcommon.core.rerollables',

    'lua.revelcommon.core.commands',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Core!")
end