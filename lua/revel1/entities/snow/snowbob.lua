REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------
-- SNOWBOB --
-------------

local function snowbob_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.SNOWBOB.variant then
        npc.SplatColor = REVEL.WaterSplatColor
        local player = npc:GetPlayerTarget()
        local data = npc:GetData()

        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        if data.MoanFrame == nil then data.MoanFrame = 0 end

        if npc.FrameCount <= 1 and not data.bobskin then
            data.bobskin = math.random(1,4)
        end

        if data.bobskin == 1 then
            npc:AnimWalkFrame("WalkHori", "WalkVert", 1)
        elseif data.bobskin <= 4 then
            npc:AnimWalkFrame("WalkHori" .. data.bobskin, "WalkVert" .. data.bobskin, 1)
        end

        if npc.FrameCount >= 5 then
            npc.State = NpcState.STATE_MOVE
        end

        if npc.State == NpcState.STATE_MOVE then
            npc.StateFrame = npc.StateFrame + 1
            if npc.StateFrame == 1 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ANGRY_GURGLE, 1, 0, false, 1)
            end

            if data.Path then
                REVEL.FollowPath(npc, 0.55, data.Path, true, 0.85)
            else
                npc.Velocity = npc.Velocity * 0.9
            end

            data.MoanFrame = data.MoanFrame + 1
            if data.MoanFrame >= 85 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ANGRY_GURGLE, 1, 0, false, 1)
                data.MoanFrame = 0
            end

        end

        if npc:IsDead() then
            local head
            if data.bobskin == 4 then
                head = Isaac.Spawn(REVEL.ENT.SNOWBOB.id, REVEL.ENT.SNOWBOB_HEAD2.variant, 0, npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(3, 5)), npc)
                local b = Isaac.Spawn(9, 1, 0, npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(4, 5)), npc)
                b:ToProjectile().Height = -65
                b:ToProjectile().FallingSpeed = -20
                b:ToProjectile().FallingAccel = 1
            else
                head = Isaac.Spawn(REVEL.ENT.SNOWBOB.id, REVEL.ENT.SNOWBOB_HEAD.variant, 0, npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(3, 5)), npc)
            end

            REVEL.ScaleChildEntity(npc, head)
        end

    elseif npc.Variant == REVEL.ENT.SNOWBOB_HEAD.variant or npc.Variant == REVEL.ENT.SNOWBOB_HEAD2.variant then

        if npc.Variant == REVEL.ENT.SNOWBOB_HEAD2.variant then
            npc:GetSprite():ReplaceSpritesheet(1, "gfx/monsters/revel1/snowbob_bone.png")
            npc:GetSprite():LoadGraphics()
            npc.SplatColor = REVEL.WaterSplatColor
        else
            npc.SplatColor = REVEL.SnowSplatColor
        end

        local player = npc:GetPlayerTarget()
        local angle = (player.Position - npc.Position):GetAngleDegrees()

        if angle >= -90 and angle <= 90 then -- Left
            npc:GetSprite().FlipX = false
        elseif angle >= 90 or angle <= -90 then -- Right
            npc:GetSprite().FlipX = true
        end

        if npc.FrameCount <= 1 then
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            npc.State = NpcState.STATE_IDLE
        end

        if npc:GetSprite():IsFinished("Fly Off") then
            npc.State = NpcState.STATE_MOVE
        end

        if npc.State == NpcState.STATE_IDLE then
            if not npc:GetSprite():IsPlaying("Fly Off") then
                npc:GetSprite():Play("Fly Off", true)
            end
        elseif npc.State == NpcState.STATE_MOVE then
            npc.Velocity = Vector.Zero
            if not npc:GetSprite():IsPlaying("Idle") then
                npc:GetSprite():Play("Idle", true)
            end
            npc.StateFrame = npc.StateFrame + 1
            if npc.StateFrame == 25 then
                npc.State = NpcState.STATE_SUICIDE
            end
        elseif npc.State == NpcState.STATE_SUICIDE then
            npc.Velocity = Vector.Zero
            if not npc:GetSprite():IsPlaying("Explode") then
                npc:GetSprite():Play("Explode", true)
            end
        end

        if npc:GetSprite():IsEventTriggered("Plop") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GOOATTACH0, 1, 0, false, 1)
            npc.Velocity = Vector.Zero
        elseif npc:GetSprite():IsEventTriggered("Shoot") then
            if npc.Variant == REVEL.ENT.SNOWBOB_HEAD2.variant then
                for i=1, 10 do
                    local p =  Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(2, 6)), npc)
                    p:ToProjectile().Height = math.random(30, 60) * -1
                    p:ToProjectile().FallingSpeed = math.random(15, 25) * -1
                    p:ToProjectile().FallingAccel = 1
                    p:ToProjectile().Scale = ( 1 + ( math.random(0, 5) / 10 ) )
                end
            else
                for i=1, 2 do
                    local sb = Isaac.Spawn(REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant, 0, npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(3, 5)), npc)
                    sb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    sb:ToNPC().State = NpcState.STATE_ATTACK3
                    REVEL.ScaleChildEntity(npc, sb)
                end
            end
            npc:Kill()
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, snowbob_NpcUpdate, REVEL.ENT.SNOWBOB.id)

end