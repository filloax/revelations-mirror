REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.TrapTypes.RevivalTrap = {
    OnTrigger = function(tile, data, player)
        local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
        for _, rag in ipairs(rags) do
            REVEL.BuffEntity(rag)
        end
        if (#rags or 0) > 0 then
            REVEL.room:SetClear(false)
            REVEL.ShutDoors()
        end
    end,
    SingleUse = true,
    Animation = "Revive"
}

end