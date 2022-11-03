REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()
    REVEL.InitEarlyCallbacks()

    Isaac.DebugString("Revelations: Loaded Post Load Code!")
end

REVEL.PcallWorkaroundBreakFunction()