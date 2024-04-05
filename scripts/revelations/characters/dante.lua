local SubModules = REVEL.PrefixAll("scripts.revelations.characters.dante.", {
    'basic',
    'phylactery',
    'separate_chars',
    'main_logic',
    'map',
    'partner',
    'charon_oar',
    'dante_book',
    'misc',
    'birthright',
})

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.RunLoadFunctions(SubLoadFunctions)

Isaac.DebugString("Revelations: Loaded Dante & Charon!")
end