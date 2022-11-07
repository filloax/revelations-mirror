local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--------------------
-- ICED HIVE --
--------------------
local function icedHive_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.ICED_HIVE.variant then
        npc.SplatColor = REVEL.WaterSplatColor
        local data, sprite, player, room = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget(), REVEL.room

        if sprite:IsFinished("Appear") or sprite:IsFinished("Attack1") or sprite:IsFinished("Attack2") then
            data.Angle = RandomVector()
            data.AngleRecalculateFrame = 0
            data.MaxRecalculateFrames = 0
            data.State = "Moving"
            npc.StateFrame = 0
            data.MaxStateFrames = math.random(60, 120)
        end

        if data.State == "Moving" then
            npc:AnimWalkFrame("HeadWalk", "WalkVert", 1)
            npc.Velocity = npc.Velocity * 0.6 + data.Angle * 0.5
            data.AngleRecalculateFrame = data.AngleRecalculateFrame + 1
            if data.AngleRecalculateFrame >= data.MaxRecalculateFrames or npc:CollidesWithGrid() then
                if player.Position:Distance(npc.Position) <= 100 then
                    data.Angle = (npc.Position - player.Position):Resized(2.5)
                else
                    data.Angle = Vector.FromAngle(1*math.random(0, 360)):Resized(2.5)
                end
                data.MaxRecalculateFrames = math.random(20, 60)
                data.AngleRecalculateFrame = 0
            end
            npc.StateFrame = npc.StateFrame + 1
            if npc.StateFrame >= data.MaxStateFrames then
                data.MaxStateFrames = math.random(60, 120)
                if ( (Isaac.CountEntities(nil, REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0) + (Isaac.CountEntities(nil, REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_POOTER, -1, -1) or 0) ) >= 4 then
                    data.NoSpawns = true
                    data.State = "Attack1"
                else
                    data.NoSpawns = false
                    if math.random(1, 5) <= 2 then
                        data.State = "Attack1"
                        npc.Velocity = Vector.Zero
                    else
                        npc.Velocity = Vector.Zero
                        data.State = "Attack2"
                    end
                end
            end
        elseif data.State == "Attack1" then
            if not sprite:IsPlaying("Attack1") then
                sprite:Play("Attack1", true)
            end
            sprite.FlipX = npc.Position.X > player.Position.X
            npc.Friction = npc.Friction * 0.85
            npc.Velocity = npc.Velocity * 0.5
        elseif data.State == "Attack2" then
            if not sprite:IsPlaying("Attack2") then
                sprite:Play("Attack2", true)
            end
            sprite.FlipX = npc.Position.X > player.Position.X
            npc.Friction = npc.Friction * 0.85
        end

        if sprite:IsEventTriggered("Sound") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
            data.PooterInMouth = true
        elseif sprite:IsEventTriggered("Shoot") then
            if data.State == "Attack1" then
                for i=1, 6 do
                    local p = Isaac.Spawn(9, REVEL.ENT.TRAY_PROJECTILE.variant, REVEL.ENT.TRAY_PROJECTILE.subtype, npc.Position, (player.Position-npc.Position):Rotated(math.random(-45, 45)):Resized(math.random(35, 55) * 0.1), npc):ToProjectile()
                    p.Height = math.random(20, 35) * -1
                    p.FallingSpeed = math.random(10, 20) * -1
                    p.FallingAccel = 1
                    p.Scale = ( 1 + ( math.random(0, 5) / 10 ) )
                    p.Parent = npc
                end
                if data.NoSpawns == true then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1)
                else
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SPIDER_COUGH, 1, 0, false, 0.95)
                    Isaac.Spawn(REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, 0, npc.Position, (player.Position-npc.Position):Resized(5), npc)
                end
            elseif data.State == "Attack2" then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1.1)
                local dir = (player.Position-npc.Position):Normalized()
                local f = Isaac.Spawn(REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, 0, npc.Position + dir * 8, dir * 6, npc)
                f:GetData().HitCooldown = 5
                f:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                data.PooterInMouth = false
                --npc.Velocity = (player.Position - npc.Position):Resized(8) doesn't work because velocity is constantly set
            end
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, icedHive_NpcUpdate, REVEL.ENT.ICED_HIVE.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc)
    if not REVEL.ENT.ICED_HIVE:isEnt(npc) then return end

    for i = 1, 2 do
        if i == 2 and (math.random(1,2) <= 1 or data.PooterInMouth) then
            local f = Isaac.Spawn(REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, 0, npc.Position, RandomVector() * math.random(3,5), npc)
            f:GetData().HitCooldown = 5
            f:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        else
            Isaac.Spawn(REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, 0, npc.Position, RandomVector() * math.random(3,5), npc)
        end
    end
    for i = 1, 6 do
        local p = Isaac.Spawn(9, REVEL.ENT.TRAY_PROJECTILE.variant, REVEL.ENT.TRAY_PROJECTILE.subtype, npc.Position, RandomVector() * math.random(1,5), npc):ToProjectile()
        p.FallingSpeed = math.random(10, 30) * -1
        p.FallingAccel = 2
        p.Scale = ( 1 + ( math.random(0, 5) / 10 ) )
        p.Parent = npc
    end
end, REVEL.ENT.ICED_HIVE.id)

--REPLACE PROJ POOFS
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, function(p, data, spr, spawner, grandpa)
    if spawner.Type == REVEL.ENT.TRAY_PROJECTILE.id and spawner.Variant == REVEL.ENT.TRAY_PROJECTILE.variant and spawner.SubType == REVEL.ENT.TRAY_PROJECTILE.subtype then
        --as replacing the poof was buggy for some reason, I'll just use the code from ice tray
        REVEL.SpawnDecoration(p.Position, Vector.Zero, "Poof", "gfx/effects/revelcommon/ice_tray_shatter.anm2", p, -1, -1, function(eff)
            local gibs = REVEL.SpawnDecoration(eff.Position, Vector.Zero, "Gibs"..math.random(3), "gfx/effects/revelcommon/ice_tray_gibs.anm2", eff, -1, -1, nil)
            gibs:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
        end)
        p:Remove()
        SFXManager():Play(REVEL.SFX.MINT_GUM_BREAK, 0.5, 0, false, 1.1+math.random()*0.1)
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()