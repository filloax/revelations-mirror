local SubModules = {
    "lua.revel1.bosses.init",
    "lua.revel1.bosses.freezerburn",
    "lua.revel1.bosses.frostrider",
    "lua.revel1.bosses.monsnow",
    "lua.revel1.bosses.stalagmight",
    "lua.revel1.bosses.williwaw",
    "lua.revel1.bosses.mirror",
    "lua.revel1.bosses.sins",
    "lua.revel1.bosses.chuck",
    "lua.revel1.bosses.wendy",
    "lua.revel1.bosses.prong",
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Chapter 1)!")
end

REVEL.PcallWorkaroundBreakFunction()