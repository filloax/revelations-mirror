REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Stone Creep

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.STONE_CREEP.variant then
        return
    end

    local d = npc:GetData()
    local s = npc:GetSprite()

    if not d.init then
        d.init = true
        d.statetime = 0
        d.laststate = 0
        d.dir = Vector(0, 1):Rotated(npc.SpriteRotation)
    end

    if (npc.State == NpcState.STATE_ATTACK and d.statetime == 0) 
    or (npc.State == NpcState.STATE_MOVE and d.statetime == 10) then
        npc.State = 101
        s:Play("Shoot", true)
    end

    if npc.State == NpcState.STATE_MOVE then
        npc.StateFrame = 99
    end

    if s:IsEventTriggered("Shoot") then
        npc:FireProjectiles(npc.Position + (d.dir * 3), d.dir * 10, 0, ProjectileParams())
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WORM_SPIT, 0.7, 0, false, 1.2)
    end

    if s:IsFinished("Shoot") then
        npc.State = NpcState.STATE_MOVE
    end

    if d.laststate ~= npc.State then
        d.laststate = npc.State
        d.statetime = 0
    else
        d.statetime = d.statetime + 1
    end

    npc.Velocity = npc.Velocity * 1.35

    if npc.State == 102 and (s:IsPlaying("Death") or s:IsFinished("Death")) then
        npc.Velocity = Vector.Zero
        if s:IsEventTriggered("Explosion") then
            for i = 1, math.random(2, 4) do
                local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, RandomVector() * math.random(2, 6), npc)
                rock:Update()
            end
        end

        if s:IsFinished("Death") then
            npc:Remove()
            REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.6, 0, false, 1)
        end
    elseif REVEL.room:IsClear() then
        npc.State = 102
        s:Play("Death", true)
    end
end, REVEL.ENT.STONE_CREEP.id)

end