local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------------
-- HALF CHEWED PONY --
----------------------

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data, sprite = eff:GetData(), eff:GetSprite()

    if not data.Init then
        eff.RenderZOffset = -1100
        data.Init = true
    end

    if sprite:IsFinished("Appear") then
        sprite:Play("Suck Start", true)
    elseif sprite:IsFinished("Suck Start") or sprite:IsFinished("Chomp(Idle)") or sprite:IsFinished("Chomp") then
        if data.AteHorse then
            eff:Remove()
            return
        end
        sprite:Play("Suck", true)
    elseif sprite:IsFinished("Suck End") then
        data.IdleFrames = 0
        sprite:Play("Idle", true)
    end

    if sprite:IsPlaying("Suck") then
        for _, ent in pairs(REVEL.roomEnemies) do
            if ent:IsVulnerableEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                if ent.Position:Distance(eff.Position) <= 25 then
                    sprite:Play("Chomp(Idle)", true)
                end
                ent.Velocity = ent.Velocity+(eff.Position-ent.Position):Normalized()/(ent.Position:Distance(eff.Position)/25)
            end
        end
    elseif sprite:IsPlaying("Idle") then
        data.IdleFrames = data.IdleFrames + 1
        if data.IdleFrames >= 80 then
            sprite:Play("Suck Start", true)
        end
    end

    local chompDamage = 10
    if sprite:IsEventTriggered("Splatter") then
        for _, ent in pairs(REVEL.roomEnemies) do
            if ent:IsVulnerableEnemy() and not ent:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and ent.Position:Distance(eff.Position) <= 25 then
                REVEL.sfx:Play(SoundEffect.SOUND_HEARTOUT)
                if ent.HitPoints <= chompDamage or ent:IsDead() then
                    REVEL.sfx:Play(REVEL.SFX.CRONCH)
                    for i=1, math.random(5,8) do
                        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, ent.Position, Vector.FromAngle(math.random(0, 360)):Resized(math.random(4, 8)), eff):ToTear()
                        t.Height = math.random(30,45) * -1
                        t.FallingSpeed = math.random(10,20) * -1
                        t.FallingAcceleration = 1
                        t.Scale = (1 + (math.random(0,6) / 10))
                        t.CollisionDamage = (1 + (math.random(0,6) / 5))
                    end
                end
                ent:TakeDamage(chompDamage, 0, EntityRef(eff), 0)
            end
        end
    end
end, REVEL.ENT.ANTLION_SUCK.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_,  fam)
    fam:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
end, REVEL.ENT.ANTLION_CHEWED_PONY.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local data, sprite, target = fam:GetData(), fam:GetSprite(), REVEL.getClosestEnemy(fam, false, true, true, true)
    local followingPlayer = false
    if not target then
        target = fam.Player
        followingPlayer = true
    end

    if data.Init == nil then
        fam:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        fam:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        fam.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
        fam.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        data.Shooting = false
        data.AttackFrames = 0
        data.AttackTimer = math.random(90, 110)
        data.AppearTimer = 0
        data.Init = true
        if not sprite:IsPlaying("Emerge") then
            data.AppearTimer = math.random(1, 20)
            sprite:Stop()
        end
    end

    if sprite:IsFinished("Emerge") or sprite:IsFinished("Appear Fly Familiar") or sprite:IsFinished("Spit Fly Familiar") then
        sprite:Play("Idle Fly", true)
    end

    if data.AppearTimer > 0 then
        data.AppearTimer = data.AppearTimer - 1
        if data.AppearTimer <= 0 then
            sprite:Play("Appear Fly Familiar", true)
            fam.Visible = true
        end
    elseif sprite:IsPlaying("Appear Fly Familiar") then
        if sprite:GetFrame() == 15 then
            fam.Velocity = Vector.Zero
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
        end
    elseif sprite:IsPlaying("Emerge") then
        if sprite:GetFrame() == 16 then
            fam.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            REVEL.sfx:Play(SoundEffect.SOUND_MAGGOT_BURST_OUT, 1, 0, false, 1)
        end
    elseif sprite:IsPlaying("Idle Fly") then
        local velocityToSet = Vector.Zero
        if (not followingPlayer and (target.Position:Distance(fam.Position) > 20))
        or (followingPlayer and (target.Position:Distance(fam.Position) > 50)) then
            velocityToSet = (target.Position - fam.Position):Resized(2.75)
        end
        fam.Velocity = REVEL.Lerp(fam.Velocity, velocityToSet, 0.15)

        if not followingPlayer then
            data.AttackFrames = data.AttackFrames + 1
            if target.Position:Distance(fam.Position) <= 250 and data.AttackFrames >= data.AttackTimer then
                data.Angle = (target.Position - fam.Position):GetAngleDegrees()
                sprite:Play("Spit Fly Familiar", true)
                data.AttackFrames = 0
                data.AttackTimer = math.random(90, 110)
            end
        end
    elseif sprite:IsPlaying("Spit Fly Familiar") then
        if sprite:GetFrame() == 18 then
            fam.Velocity = Vector.Zero
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
        end
    end

    if data.Shooting == true then
        local tvariants = {
            TearVariant.BONE,
            TearVariant.BLUE,
            TearVariant.BLOOD
        }
        for i=1, 3 do
            local angle = data.Angle
            local offset = (math.random() ^ 2.1) * 180
            if math.random(1, 2) == 1 then
                offset = -offset
            end

            local t = Isaac.Spawn(EntityType.ENTITY_TEAR, tvariants[math.random(1, 3)], 0, fam.Position, Vector.FromAngle(angle + offset):Resized(math.random(4, 8)), fam):ToTear()
            t.Height = math.random(50, 80) * -1
            t.FallingSpeed = math.random(10, 30) * -1
            t.FallingAcceleration = 1
            t.Scale = 1.2
            t.CollisionDamage = 2.4

            if t.Variant == TearVariant.BLUE then
                local tSprite = t:GetSprite()
                tSprite:ReplaceSpritesheet(0, "gfx/puke_bullets.png")
                tSprite:LoadGraphics()
                t:GetData().IsPukeTear = true
            end
        end
    end

    if sprite:IsEventTriggered("Shoot") then
        REVEL.sfx:Play(SoundEffect.SOUND_BOSS_GURGLE_ROAR, 1, 0, false, 1)
        data.Shooting = true
    elseif sprite:IsEventTriggered("Stop") then
        data.Shooting = false
    end

    for i,proj in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, true)) do
        if fam.Position:Distance(proj.Position) < proj.Size + fam.Size then
            fam:TakeDamage(proj.CollisionDamage, 0, EntityRef(proj), 5)
            proj:Die()
        end
    end

    if fam.HitPoints <= 0 then
        fam:BloodExplode()
        fam:Kill()
    end
end, REVEL.ENT.ANTLION_CHEWED_PONY.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, cooldown)
    if source and source.Entity and source.Entity.Type == REVEL.ENT.ANTLION_CHEWED_PONY.id and source.Entity.Variant == REVEL.ENT.ANTLION_CHEWED_PONY.variant and ent:ToNPC() then
        for _, sourceEnt in ipairs(Isaac.FindByType(source.Type, source.Variant, source.Entity.SubType, false, false)) do
            if GetPtrHash(sourceEnt) == GetPtrHash(source.Entity) then
                sourceEnt:TakeDamage(ent.CollisionDamage, 0, EntityRef(ent), 5)
                break
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_TEAR_POOF_INIT, 1, function(poof, data, spr, parent, grandparent)
    if parent:GetData().IsPukeTear then
        poof:GetSprite().Color = Color(0,0,0,1,conv255ToFloat(125,95,75))
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if REVEL.ITEM.HALF_CHEWED_PONY:PlayerHasCollectible(player) then
        if flag == CacheFlag.CACHE_FLYING then
            player.CanFly = true
        end
        if flag == CacheFlag.CACHE_SPEED then
            if player.MoveSpeed < 1.5 then
                player.MoveSpeed = 1.5
            end
        end
    end

    local data, effects = player:GetData(), player:GetEffects()
    if data.ChewedPonyWasChewed and effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_FATE) then
        if flag == CacheFlag.CACHE_FLYING then
            player.CanFly = true
        end
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()
    if REVEL.ITEM.HALF_CHEWED_PONY:PlayerHasCollectible(player) then
        if not data.HasChewedPony then
            data.HasChewedPony = true
            player:AddNullCostume(REVEL.COSTUME.HALF_CHEWED_PONY)
            player:AddCacheFlags(CacheFlag.CACHE_FLYING)
            player:AddCacheFlags(CacheFlag.CACHE_SPEED)
            player:EvaluateItems()
        end
        if data.ChewedPonyRemoveCooldown and data.ChewedPonyRemoveCooldown > 0 then
            data.ChewedPonyRemoveCooldown = data.ChewedPonyRemoveCooldown - 1
            if data.ChewedPonyRemoveCooldown == 0 then
                player:RemoveCollectible(REVEL.ITEM.HALF_CHEWED_PONY.id)
                Isaac.Spawn(REVEL.ENT.HALF_CHEWED_PONY.id, REVEL.ENT.HALF_CHEWED_PONY.variant, 0, player.Position, Vector.Zero, player)
                data.ChewedPonyWasChewed = true
                local effects = player:GetEffects()
                effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_FATE, true)
                player:AddCacheFlags(CacheFlag.CACHE_FLYING)
                player:EvaluateItems()
            end
        end
    else
        if data.HasChewedPony then
            data.HasChewedPony = false
            player:TryRemoveNullCostume(REVEL.COSTUME.HALF_CHEWED_PONY)
            player:AddCacheFlags(CacheFlag.CACHE_FLYING)
            player:AddCacheFlags(CacheFlag.CACHE_SPEED)
            player:EvaluateItems()
        end
    end

    if data.ChewedPonySpawnAntlionsTimer and data.ChewedPonySpawnAntlionsTimer > 0 then
        data.ChewedPonySpawnAntlionsTimer = data.ChewedPonySpawnAntlionsTimer - 1
        if data.ChewedPonySpawnAntlionsTimer == 0 then
            local playerID = REVEL.GetPlayerID(player)
            for i=1, (revel.data.run.chewedPonysChewed[playerID] or 0) do
                local antlion = Isaac.Spawn(
                    REVEL.ENT.ANTLION_CHEWED_PONY.id, 
                    REVEL.ENT.ANTLION_CHEWED_PONY.variant, 
                    0, 
                    REVEL.room:FindFreePickupSpawnPosition(
                        REVEL.room:GetCenterPos() + Vector(math.random(-50, 50), math.random(-50, 50)), 
                        32, 
                        true
                    ), 
                    Vector.Zero, 
                    player
                ):ToFamiliar()
                local antlionData = antlion:GetData()
                antlionData.Player = player
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    local antlionSuck = Isaac.Spawn(REVEL.ENT.ANTLION_SUCK.id, REVEL.ENT.ANTLION_SUCK.variant, 0, player.Position, Vector.Zero, player)
    REVEL.sfx:Play(SoundEffect.SOUND_SUMMON_POOF)
    local playerID = REVEL.GetPlayerID(player)
    if math.random(1, 20) == 20 then
        local data, antlionSuckData = player:GetData(), antlionSuck:GetData()
        revel.data.run.chewedPonysChewed[playerID] = revel.data.run.chewedPonysChewed[playerID] + 1
        data.ChewedPonyRemoveCooldown = 30
        antlionSuckData.ChewedPonyToFollow = player
    end
end, REVEL.ITEM.HALF_CHEWED_PONY.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Variant == REVEL.ENT.ANTLION_SUCK.variant then
        local data = ent:GetData()
        if data.ChewedPonyToFollow then
            local antlion = Isaac.Spawn(REVEL.ENT.ANTLION_CHEWED_PONY.id, REVEL.ENT.ANTLION_CHEWED_PONY.variant, 0, ent.Position, Vector.Zero, data.ChewedPonyToFollow):ToFamiliar()
            local antlionData, antlionSprite = antlion:GetData(), antlion:GetSprite()
            antlionData.Player = data.ChewedPonyToFollow
            antlionSprite:Play("Emerge", true)
        end
    end
end, REVEL.ENT.ANTLION_SUCK.id)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for i, player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.ChewedPonyWasChewed then
            data.ChewedPonyWasChewed = false
            player:AddCacheFlags(CacheFlag.CACHE_FLYING)
            player:EvaluateItems()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    for i, antlion in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_CHEWED_PONY.id, REVEL.ENT.ANTLION_CHEWED_PONY.variant, -1, false, false)) do
        antlion:Remove()
    end

    for i, player in ipairs(REVEL.players) do
        local playerID = REVEL.GetPlayerID(player)
        if (revel.data.run.chewedPonysChewed[playerID] or 0) > 0 then
            local data = player:GetData()
            data.ChewedPonySpawnAntlionsTimer = 2
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    for i, antlionSuck in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_SUCK.id, REVEL.ENT.ANTLION_SUCK.variant, -1, false, false)) do
        local antlionSuckData = antlionSuck:GetData()
        if antlionSuckData.ChewedPonyToFollow then
            if not REVEL.LerpEntityPosition(effect, effect.Position, antlionSuck.Position, 60) or effect.Position:Distance(antlionSuck.Position) < 15 then
                local antlionSuckSprite = antlionSuck:GetSprite()
                antlionSuckData.AteHorse = true
                antlionSuckSprite:Play("Chomp(Idle)", true)
                effect:Remove()
                REVEL.sfx:Play(REVEL.SFX.CRONCH)
                break
            end
        end
    end
end, REVEL.ENT.HALF_CHEWED_PONY.variant)

end