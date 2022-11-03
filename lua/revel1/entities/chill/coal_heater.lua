REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- COAL HEATER --
-----------------
local maxRadius = 300
local minCooldown = 90
local maxCooldown = 110

local MaxShards = 2

local HeaterHasAura = false

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.COAL_HEATER.variant then return end
    local data, sprite = npc:GetData(), npc:GetSprite()
    if not data.Init then
        local coalHeaters = Isaac.FindByType(REVEL.ENT.COAL_HEATER.id, REVEL.ENT.COAL_HEATER.variant, -1, false, true)
        local num_coalHeaters = #coalHeaters
        for i, coalHeater in ipairs(coalHeaters) do
            local chdata = coalHeater:GetData()
            chdata.FireCooldown = (1 - (i/num_coalHeaters)) * (maxCooldown * 0.5) + 1
            coalHeater.SplatColor = REVEL.CoalSplatColor
            coalHeater:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))

            chdata.Init = true
        end
    end
    REVEL.ApplyKnockbackImmunity(npc)

    if sprite:IsFinished("Appear") then
        sprite:Play("Idle", true)
    end

    if sprite:IsPlaying("Idle") then
        data.FireCooldown = data.FireCooldown - 1
    end
    if data.FireCooldown <= 0 and Isaac.CountEntities(npc) < MaxShards then
        data.FireCooldown = math.random(minCooldown, maxCooldown)
        sprite:Play("Attack", true)
        local radius = REVEL.GetChillWarmRadius()*1.5
        if HeaterHasAura and REVEL.ShouldUseWarmthAuras() then
            REVEL.SetWarmAura(npc, radius)
        end
    end

    if sprite:IsEventTriggered("Grunt") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 0.98 + math.random()*0.04)

    elseif sprite:IsEventTriggered("Shoot") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1, 0, false, 1.3 + math.random() * 0.1)
        ---@type Vector
        local target_position = npc:GetPlayerTarget().Position
        if (target_position - npc.Position):LengthSquared() > maxRadius ^ 2 then
            target_position = npc.Position + (target_position - npc.Position):Resized(maxRadius)
        end
        -- data.AttackPosition = target_position

        if HeaterHasAura and REVEL.ShouldUseWarmthAuras() then
            REVEL.RemoveWarmAura(npc)
       end

        local stala = REVEL.ENT.COAL_SHARD:spawn(target_position, Vector.Zero, npc)
        stala.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

    elseif sprite:IsFinished("Attack") then
        sprite:Play("Idle", true)
    end
    npc.Velocity = Vector.Zero

    if npc:IsDead() then
        if not data.CoalHeaterDied then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 1, 0, false, 1)
            for i=1, math.random(3,5) do
                local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position + Vector.FromAngle(math.random(0,359))*npc.Size*math.random(), Vector.FromAngle(math.random(0,359))*math.random(), npc)
                particle:GetSprite().Color = Color(0.3,0.3,0.3,1,conv255ToFloat(0,0,0))
            end
            if REVEL.IsChilly() then
                Isaac.Spawn(REVEL.ENT.GRILL_O_WISP.id, REVEL.ENT.GRILL_O_WISP.variant, 0, npc.Position, Vector.Zero, npc)
            end
            data.CoalHeaterDied = true
        end
    end
end, REVEL.ENT.COAL_HEATER.id)

end

REVEL.PcallWorkaroundBreakFunction()