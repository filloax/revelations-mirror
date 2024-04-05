local SubModules = {
    "scripts.revelations.chapter2.bosses.aragnid",
    "scripts.revelations.chapter2.bosses.catastrophe",
    "scripts.revelations.chapter2.bosses.maxwell",
    "scripts.revelations.chapter2.bosses.sandy",
    "scripts.revelations.chapter2.bosses.sarcophaguts",
    "scripts.revelations.chapter2.bosses.mirror",
    "scripts.revelations.chapter2.bosses.sins",
    "scripts.revelations.chapter2.bosses.dungo",
    "scripts.revelations.chapter2.bosses.ragtime",
  }

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Chapter 2)!")
end