local PressurePlateState = require("lua.revelcommon.enums.PressurePlateState")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
-- Urny

local function isClearExceptUrnies()
    for i, npc in pairs(REVEL.roomNPCs) do
        if REVEL.CanShutDoors(npc) and npc.Type ~= REVEL.ENT.URNY.id then
            return false
        end
    end
    for i=0, REVEL.room:GetGridSize() do
        local grid = REVEL.room:GetGridEntity(i)
        if grid and grid:ToPressurePlate() and grid:GetVariant() == 0 and grid.State ~= PressurePlateState.PLATE_PRESSED then
            return false
        end
    end
    return true
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.URNY.variant then
        return
    end

    local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.Init then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:AddEntityFlags(BitOr(
            EntityFlag.FLAG_NO_KNOCKBACK,
            EntityFlag.FLAG_NO_STATUS_EFFECTS,
            EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK,
            EntityFlag.FLAG_NO_TARGET
        ))
        sprite:Play("Appear", true)
        data.Init = true
        data.Triggered = false
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    end

    data.UsePlayerMap = true

    if sprite:IsFinished("Appear") then
        npc.Velocity = npc.Velocity * 0
        sprite:Play("Idle", true)
        data.State = "Idle"
    end

    if data.ForceLaunch == 2 and data.State ~= "Launching" and data.State ~= "InAir" then
        sprite:Play("Launch", true)
        data.State = "Launching"
    end

    if data.State == "Idle" then
        npc.Velocity = npc.Velocity * 0

        if isClearExceptUrnies() then
            local oneIsLaunching = false
            local urnyCount = 0
            for i, urny in ipairs(Isaac.FindByType(REVEL.ENT.URNY.id, REVEL.ENT.URNY.variant, -1, false, false)) do
                local urnyData = urny:GetData()
                if urnyData.State == "Launching" then
                    oneIsLaunching = true
                elseif urnyData.State ~= "InAir" then
                    urnyCount = urnyCount + 1
                end
            end
            data.urniesInRoom = urnyCount
            if not oneIsLaunching then
                sprite:Play("Launch", true)
                data.State = "Launching"
            end
        else
            if player.Position:Distance(npc.Position) <= 100 then
                data.Triggered = true
            end

            if data.Triggered or data.AlwaysActive then
                if data.Path then
                    npc:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
                    sprite:Play("Move", true)
                    data.SpitCooldown = 2
                    data.State = "Moving"
                elseif npc.FrameCount % 50 == 0 and player.Position:Distance(npc.Position) <= 100 then
                    sprite:Play("Shoot", true)
                    data.State = "Coughing"
                end
            end
        end
    elseif data.State == "Moving" then
        if not sprite:IsPlaying("Move") then
            sprite:Play("Move", true)
        end
        sprite.FlipX = npc.Position.X > player.Position.X

        local frame = sprite:GetFrame()
        if frame > 5 and frame < 12 then
            npc.Velocity = npc.Velocity * 0.9

            if data.Path then
                REVEL.FollowPath(npc, 3, data.Path, true, 0.5)
            end
        else
            npc.Velocity = npc.Velocity * 0.5

            if frame == 17 then
                if isClearExceptUrnies() then
                    local oneIsLaunching = false
                    local urnyCount = 0
                    for i, urny in ipairs(Isaac.FindByType(REVEL.ENT.URNY.id, REVEL.ENT.URNY.variant, -1, false, false)) do
                        local urnyData = urny:GetData()
                        if urnyData.State == "Launching" then
                            oneIsLaunching = true
                        elseif urnyData.State ~= "InAir" then
                            urnyCount = urnyCount + 1
                        end
                    end
                    data.urniesInRoom = urnyCount
                    if oneIsLaunching then
                        sprite:Play("Idle", true)
                        data.State = "Idle"
                    else
                        sprite:Play("Launch", true)
                        data.State = "Launching"
                    end
                else
                    if not data.SpitCooldown then
                        data.SpitCooldown = 2
                    end

                    if (data.SpitCooldown <= 0 and player.Position:Distance(npc.Position) <= 100) or not data.Path then
                        sprite:Play("Shoot", true)
                        data.State = "Coughing"
                    elseif data.SpitCooldown > 0 then
                        data.SpitCooldown = data.SpitCooldown - 1
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Land") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 1, 0, false, 1)
        end
    elseif data.State == "Coughing" then
        sprite.FlipX = npc.Position.X > player.Position.X
        npc.Velocity = npc.Velocity * 0.5

        if sprite:IsEventTriggered("Target") then
            data.TargetVec = (player.Position - npc.Position):Normalized()
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)

            local normalized = data.TargetVec or (player.Position - npc.Position):Normalized()
            for i = 1, math.random(4, 6) do
                local p = Isaac.Spawn(9, 0, 0, npc.Position, normalized:Rotated(math.random(-3000, 3000) * 0.01) * (math.random(500, 2000) * 0.01), npc):ToProjectile()
                p.Scale = p.Scale * math.random(20, 150) * 0.01
                p.FallingSpeed = math.random(200, 600) * -0.01
            end
        end
        if sprite:IsFinished("Shoot") then
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            data.Triggered = false
            sprite:Play("Idle", true)
            data.State = "Idle"
        elseif not sprite:IsPlaying("Shoot") then
            sprite:Play("Shoot", true)
        end
    elseif data.State == "Launching" then
        sprite.FlipX = npc.Position.X > player.Position.X
        npc.Velocity = npc.Velocity * 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

        if not sprite:IsPlaying("Launch") then
            sprite:Play("Launch", true)
        end

        if sprite:IsEventTriggered("Flash") then
            npc:SetColor(Color(1.2, 1, 1, 1, 0.6, 0.2, 0.2), 20, 1, true, false)
            data.urniesInRoom = data.urniesInRoom or 1
            if data.urniesInRoom == 0 then data.urniesInRoom = 1 end
            local sfxPitch = 1.1 - math.min(0.3,0.05*data.urniesInRoom)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BEEP, 0.8, 0, false, sfxPitch)
        end

        if sprite:IsEventTriggered("Target") then
            data.TargetVec = (player.Position - npc.Position):Normalized()
        end

        if sprite:IsEventTriggered("InAirStart") then
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
            data.State = "InAir"

            data.Distance = player.Position:Distance(npc.Position)
            if data.Distance < 100 then
                data.Distance = 100
            end
            data.InitialDistance = data.Distance

            data.NormalizedVelocity = data.TargetVec or (player.Position - npc.Position):Normalized()
            npc.Velocity = data.NormalizedVelocity * 16

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1.2)

            npc.CollisionDamage = 1
        end
    elseif data.State == "InAir" then
        sprite.FlipX = npc.Velocity.X < 0
        if sprite:IsFinished("Launch") or (not sprite:IsPlaying("InAir") and not sprite:IsPlaying("Launch")) then
            sprite:Play("InAir", true)
            npc.SpriteOffset = Vector(0,-8)
        end

        if data.Distance then
            if data.Distance > 0 then
                data.Distance = data.Distance - 15

                if data.Distance <= 15 then
                    npc.SpriteOffset = Vector(0,0)
                elseif data.Distance <= 30 then
                    npc.SpriteOffset = Vector(0,-2)
                elseif data.Distance <= 45 then
                    npc.SpriteOffset = Vector(0,-4)
                elseif data.Distance <= 60 then
                    npc.SpriteOffset = Vector(0,-6)
                end
            else
                npc.SpriteOffset = Vector(0,0)
                local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position))
                if grid and grid.CollisionClass == GridCollisionClass.COLLISION_PIT then
                    data.PoofMe = true
                else
                    data.DestroyMe = true
                end
            end
        end

        local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position + npc.Velocity))
        if grid and grid.CollisionClass ~= GridCollisionClass.COLLISION_NONE and grid.CollisionClass ~= GridCollisionClass.COLLISION_PIT then
            data.DestroyMe = true
        end

        if npc.Velocity:Length() < 1 then
            data.NormalizedVelocity = (player.Position - npc.Position):Normalized()
            npc.Velocity = data.NormalizedVelocity * 15
            npc.CollisionDamage = 1
        end
    elseif not sprite:IsPlaying("Appear") then
        npc.Velocity = npc.Velocity * 0
        sprite:Play("Idle", true)
        data.State = "Idle"
    end

    for i, boulder in ipairs(Isaac.FindByType(REVEL.ENT.SAND_BOULDER.id, REVEL.ENT.SAND_BOULDER.variant, -1, false, false)) do
        if npc.Position:Distance(boulder.Position) < 50 then
            data.DestroyMe = true
        end
    end

    if data.PoofMe then
        local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc)
        npc:Remove()
    elseif data.DestroyMe then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 1, 0, false, 1)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_POT_BREAK, 0.5, 0, false, 1)
        sprite:Play("Death", true)
        for i = 1, 5 do
            local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, Vector.FromAngle(math.random(0, 360)) * (math.random(200, 1000) * 0.01), npc)
            rock:Update()
        end

        for i = 1, math.random(8, 12) do
            local p = Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(math.random(0, 360)) * (math.random(200, 2400) * 0.01), npc):ToProjectile()
            p.Scale = p.Scale * math.random(40, 180) * 0.01
            p.FallingSpeed = math.random(200, 600) * -0.01
            local pData = p:GetData()
            pData.SlowerUrnyProjectile = true
        end

        npc:Die()
    end
end, REVEL.ENT.URNY.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source)
    if ent.Variant == REVEL.ENT.URNY.variant then
        local data = ent:GetData()
        data.Triggered = true
        return false
    end
end, REVEL.ENT.URNY.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source)
    if source and source.Type == REVEL.ENT.URNY.id and source.Variant == REVEL.ENT.URNY.variant then
        for i, urny in ipairs(Isaac.FindByType(REVEL.ENT.URNY.id, REVEL.ENT.URNY.variant, -1, false, false)) do
            if GetPtrHash(source.Entity) == GetPtrHash(urny) then
                local data = urny:GetData()
                if data.State == "InAir" then
                    data.DestroyMe = true
                end
            end
        end
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro.SpawnerType == REVEL.ENT.URNY.id and pro.SpawnerVariant == REVEL.ENT.URNY.variant then
        pro.Velocity = pro.Velocity * 0.9
        local data = pro:GetData()
        if data.SlowerUrnyProjectile then
            pro.Velocity = pro.Velocity * 0.85
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()