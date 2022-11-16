REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Triggers an effect of heavenly bell for the floor

revel:AddCallback(ModCallbacks.MC_USE_CARD, function(_, cardID, player, useFlags)
    local effect = REVEL.HeavenlyBell.AddBellEffect(player)
    if HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        REVEL.DelayFunction(function()
            REVEL.HeavenlyBell.PlayClue(player, effect)
        end, 60)
    else
        REVEL.HeavenlyBell.PlayClue(player, effect)
    end
end, REVEL.POCKETITEM.BELL_SHARD.Id)
    
end