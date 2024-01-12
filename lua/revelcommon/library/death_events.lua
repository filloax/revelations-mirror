return function()

---@alias Rev.OnDeath.Callback fun(npc: EntityNPC): string?
---@alias Rev.OnDeath.Render fun(npc: EntityNPC, triggeredEventThisFrame: boolean): boolean?

-- Since during death state updates don't run, and keeping the dying npc in the death state is buggy,
-- run updates in death (usually sound events in sprites) during POST_NPC_RENDER
---@param onDeath Rev.OnDeath.Callback
---@param deathRender Rev.OnDeath.Render triggeredEventThisFrame resets every game framecount change, can be used to avoid playing an event twice due to render being at 60fps set it by returning true to the function
---@param npcId EntityType
---@param npcVariant integer
---@overload fun(handler: {OnDeath: Rev.OnDeath.Callback, DeathRender: Rev.OnDeath.Render, Type: EntityType, Variant: integer})
function REVEL.AddDeathEventsCallback(onDeath, deathRender, npcId, npcVariant)
    if type(onDeath) == "table" then
        local tbl = onDeath
        onDeath = tbl.OnDeath
        deathRender = tbl.DeathRender
        npcId = tbl.Type
        npcVariant = tbl.Variant
    end

    revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
        if npc.Variant ~= npcVariant or not REVEL.IsRenderPassNormal() then return end

        local sprite, data = npc:GetSprite(), npc:GetData()

        if not data.__startedDeath and npc:HasMortalDamage() then
            local anim = "Death"
            if onDeath then 
                local ret = onDeath(npc) 
                if ret ~= nil then
                    anim = ret
                end
            end

            sprite:Play(anim, true)
            npc.Velocity = Vector.Zero
            npc.HitPoints = 0
            npc:RemoveStatusEffects()
            npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
            npc.State = NpcState.STATE_UNIQUE_DEATH
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.StartedDeath = true
            data.__startedDeath = true
        end

        if data.__startedDeath and deathRender and not REVEL.game:IsPaused() then
            local triggeredEventThisFrame = deathRender(npc, data.__triggeredEventThisFrame)

            if REVEL.game:GetFrameCount() ~= data.__lastDeathRenderFrame then
                data.__lastDeathRenderFrame = REVEL.game:GetFrameCount()
                data.__triggeredEventThisFrame = nil
            end
            data.__triggeredEventThisFrame = data.__triggeredEventThisFrame or triggeredEventThisFrame
        end
    end, npcId)
end

end