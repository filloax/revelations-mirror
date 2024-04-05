return function()

-- Button Masher

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.BUTTON_MASHER.variant then
        return
    end

    local d = REVEL.GetData(npc)
    local s = npc:GetSprite()

    if not d.init then
        d.init = true
        if s:IsPlaying("No-Spikes") then
            s:SetLastFrame()
        end
    end

    d.timer = math.max(0, (d.timer or 0) - 1)

    if d.ForcePressFrame then
        s:SetFrame("Press", d.ForcePressFrame)
        d.ForcePressFrame = d.ForcePressFrame + 1
        if d.ForcePressFrame > 8 then
            d.ForcePressFrame = nil
        end
    end

    if not s:IsPlaying("No-Spikes") and not s:IsFinished("No-Spikes") then
        local trap = REVEL.TriggerTrapsInRange(npc.Position, 15, false, false, true)
        if trap and (trap ~= d.trap or d.timer == 0) then
            d.ForcePressFrame = 0
            d.trap = trap
            d.timer = 20
            if REVEL.GetData(trap).TrapName == "BoulderTrap" then
            REVEL.GetData(trap).TrapTriggerCooldown = 30
            end
        end
    end
end, REVEL.ENT.BUTTON_MASHER.id)

end