local SubModules = {
    "lua.revelcommon.bosses.init",
    "lua.revelcommon.bosses.prank",
    "lua.revelcommon.bosses.sins",
    "lua.revelcommon.bosses.punker",
    "lua.revelcommon.bosses.raginglonglegs",
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Bosses (Common)!")
end