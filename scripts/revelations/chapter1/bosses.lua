local SubModules = {
    "scripts.revelations.chapter1.bosses.freezerburn",
    "scripts.revelations.chapter1.bosses.frostrider",
    "scripts.revelations.chapter1.bosses.monsnow",
    "scripts.revelations.chapter1.bosses.stalagmight",
    "scripts.revelations.chapter1.bosses.williwaw",
    "scripts.revelations.chapter1.bosses.mirror",
    "scripts.revelations.chapter1.bosses.sins",
    "scripts.revelations.chapter1.bosses.chuck",
    "scripts.revelations.chapter1.bosses.wendy",
    "scripts.revelations.chapter1.bosses.prong",
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Chapter 1)!")
end