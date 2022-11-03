REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
------------
-- GEICER --
------------
local maxRadius = 300

local function geicer_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.GEICER.variant then

        local data,sprite = npc:GetData(), npc:GetSprite()

        REVEL.ApplyKnockbackImmunity(npc)
        npc.SplatColor = REVEL.SnowSplatColor
        local player = npc:GetPlayerTarget()

        if not data.Init then
            local geicers = REVEL.ENT.GEICER:getInRoom()
            for i, geicer in ipairs(geicers) do
                geicer = geicer:ToNPC()

                local perGeicer = math.floor(75 / #geicers)
                local frame = perGeicer * (i - 1) + math.floor(perGeicer / 2)

                geicer:GetData().Cooldown = frame
                geicer:GetData().Init = true
                geicer.State = NpcState.STATE_MOVE
            end

            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    
            data.Init = true
        end

        npc.Velocity = Vector.Zero

        data.Cooldown = data.Cooldown + 1

        if sprite:IsFinished("Shoot2") then
            npc.State = NpcState.STATE_MOVE
        end

        if npc.State == NpcState.STATE_MOVE then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            if data.Cooldown >= 90 then
                data.Cooldown = 0
                npc.State = NpcState.STATE_ATTACK
            end
        elseif npc.State == NpcState.STATE_ATTACK then
            if not sprite:IsPlaying("Shoot2") then
                sprite:Play("Shoot2", true)
            end
        end

        if sprite:IsEventTriggered("Grunt") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 0.98 + math.random()*0.04)
        elseif sprite:IsEventTriggered("Shoot") then
            -- REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1, 0, false, 1.3 + math.random() * 0.1)
            local diff = player.Position -  npc.Position
            local targ = player.Position
            local dist = diff:Length()
            if dist > maxRadius then
                targ = npc.Position + (diff * (maxRadius / dist))
            end
            local stala = Isaac.Spawn(REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE_SMALL.variant, 0, targ, Vector.Zero, npc)
            stala.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            -- stala.Visible = false
            -- stala:GetData().Timer = 18
        end

    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, geicer_NpcUpdate, REVEL.ENT.GEICER.id)

end

REVEL.PcallWorkaroundBreakFunction()