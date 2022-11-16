REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------------
-- SMOLYCEPHALUS --
-------------------

local function smolycephalus_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.SMOLYCEPHALUS.variant then

        local player = npc:GetPlayerTarget()
        local path = npc.Pathfinder
        local angle = (player.Position - npc.Position):GetAngleDegrees()
        local data, sprite = npc:GetData(), npc:GetSprite()

        if not data.State then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.State = "DigDown"
            data.StateFrame = 0
            data.TimeOut = math.random(25,50)
        end

        if data.StateFrame >= data.TimeOut then
            data.TimeOut = math.random(50,75)
            data.State = "DigDown"
            data.StateFrame = 0
        elseif sprite:IsFinished("Attack") then
            data.State = "Idle"
        elseif sprite:IsFinished("GoUnder") then
            data.State = "Move"
        end

        if data.State == "Idle" then
            npc.Velocity = Vector.Zero
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end
            data.StateFrame = data.StateFrame + 1
        elseif data.State == "DigDown" then
            npc.Velocity = Vector.Zero
            if not sprite:IsPlaying("GoUnder") then
                sprite:Play("GoUnder", true)
            end
        elseif data.State == "Move" then
            path:FindGridPath(player.Position, 2, 1, false)
            npc.Velocity = npc.Velocity:Resized(7)
            data.StateFrame = data.StateFrame + 1

            if not sprite:IsPlaying("Dirt") then
                sprite:Play("Dirt", true)
            end

            if npc.Position:Distance(player.Position) <= 75 or data.StateFrame >= data.TimeOut then
                data.State = "Attack"
                data.TimeOut = math.random(25,50)
                data.StateFrame = 0
            end
        elseif data.State == "Attack" then
            npc.Velocity = Vector.Zero
            if not sprite:IsPlaying("Attack") then
                sprite:Play("Attack", true)
            end
        end

        if sprite:IsEventTriggered("Emerge") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_BURST_OUT, 1, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        elseif sprite:IsEventTriggered("Burrow") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        elseif sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
            local par = ProjectileParams()
            par.FallingAccelModifier = 0.05
            par.FallingSpeedModifier = 0.1
            par.VelocityMulti = 8
            for i=1,8 do
                npc:FireProjectiles(npc.Position, Vector.FromAngle(45*i), 0, par)
            end
        elseif sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop") and npc.FrameCount%2 == 0 then
            local params = ProjectileParams()
            params.FallingSpeedModifier = math.random(-28, -24)
            params.FallingAccelModifier = 1.2
            local velocity = (player.Position - npc.Position):Rotated(math.random(-10, 10)) * 0.04 * (math.random(6, 16) * 0.1)
            local length = velocity:Length()
            if length > 12 then
                velocity = (velocity / length) * 12
            end

            npc:FireProjectiles(npc.Position, velocity, 0, params)
        end

    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, smolycephalus_NpcUpdate, REVEL.ENT.SMOLYCEPHALUS.id)

end