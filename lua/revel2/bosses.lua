local SubModules = {
    "lua.revel2.bosses.init",
    "lua.revel2.bosses.aragnid",
    "lua.revel2.bosses.catastrophe",
    "lua.revel2.bosses.maxwell",
    "lua.revel2.bosses.sandy",
    "lua.revel2.bosses.sarcophaguts",
    "lua.revel2.bosses.mirror",
    "lua.revel2.bosses.sins",
    "lua.revel2.bosses.dungo",
    "lua.revel2.bosses.ragtime",
  }

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Chapter 2)!")
end