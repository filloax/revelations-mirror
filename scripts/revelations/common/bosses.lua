local SubModules = {
    "scripts.revelations.common.bosses.prank",
    "scripts.revelations.common.bosses.sins",
    "scripts.revelations.common.bosses.punker",
    "scripts.revelations.common.bosses.raginglonglegs",
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Common)!")
end