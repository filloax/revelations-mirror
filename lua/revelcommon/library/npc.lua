REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- do each update, ideally before doing velocity updates 
-- (which is why this isn't a one off function that registers a callback) 
-- undoVelocityChanges: if true, undoes velocity changes due to knockback
-- Returns: knockback velocity if it was undone, nil otherwise
function REVEL.ApplyKnockbackImmunity(npc, undoVelocityChanges)
    local data = npc:GetData()

    if not data.__InitKnockbackImmunity then
        data.__InitKnockbackImmunity = true
        data.__PrevKnockbackVelocity = npc.Velocity
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        -- REVEL.DebugStringMinor("[Knockback immunity] applied to ", npc)
    end

    if npc:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
        npc:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
        if undoVelocityChanges then
            local velocityDiff = npc.Velocity - data.__PrevKnockbackVelocity
            -- REVEL.DebugStringMinor("[Knockback immunity] Resetting velocity to", data.__PrevKnockbackVelocity, "from", npc.Velocity, "for npc", npc)
            npc.Velocity = data.__PrevKnockbackVelocity
            return velocityDiff
        end
    end

    data.__PrevKnockbackVelocity = npc.Velocity
end

end

REVEL.PcallWorkaroundBreakFunction()