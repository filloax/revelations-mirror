local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ProjectilesMode   = require("lua.revelcommon.enums.ProjectilesMode")

return function()

-- Firecaller

--Tomb has homing, glacier doesn't

local function getFireCallers()
    return REVEL.ConcatTables(REVEL.ENT.FIRECALLER:getInRoom(), REVEL.ENT.FIRECALLER_GLACIER:getInRoom())
end

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.FIRECALLER.variant and npc.Variant ~= REVEL.ENT.FIRECALLER_GLACIER.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if not data.Init then
        REVEL.SpawnLightAtEnt(npc, Color(1, 1, 0, 1,conv255ToFloat( 255, 96, 0)), 2.5, Vector(0, -20))
        REVEL.SetWarmAura(npc)

        data.Init = true
    end

    REVEL.SpawnFireParticles(npc, -40, 20)

    if not REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_BURNING) then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.FIRE_BURNING, 1, 0, true, 1)
    end

    if REVEL.ENT.FIRECALLER:isEnt(npc) then
        npc.SplatColor = REVEL.PurpleRagSplatColor
    else
        npc.SplatColor = Color(0, 0, 0, 1,conv255ToFloat( 255, 125, 0))
    end

    if not data.IsFlame then
        local validFires = {}
        local closeToPlayer = {}

        if REVEL.ENT.FIRECALLER:isEnt(npc) then
            for _, brazier in ipairs(Isaac.FindByType(REVEL.ENT.CORNER_BRAZIER.id, REVEL.ENT.CORNER_BRAZIER.variant, -1, false, false)) do
                local bSprite = brazier:GetSprite()
                if not bSprite:IsPlaying("FlickerPurple") then
                    validFires[#validFires + 1] = {Position = brazier.Position, Entity = brazier}
                    if brazier.Position:DistanceSquared(target.Position) < 160 ^ 2 then
                        closeToPlayer[#closeToPlayer + 1] = validFires[#validFires]
                    end
                end
            end
        else
            local braziers = StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.BRAZIER.Name)

            for _, brazier in pairs(braziers) do
                local grid = REVEL.room:GetGridEntity(brazier.GridIndex)
                if not grid:GetSprite():IsPlaying("FlickerRed") then
                    local pos = REVEL.room:GetGridPosition(brazier.GridIndex)
                    validFires[#validFires + 1] = {GridEntity = grid, Position = pos}
                    if pos:DistanceSquared(target.Position) < 160 ^ 2 then
                        closeToPlayer[#closeToPlayer + 1] = validFires[#validFires]
                    end
                end
            end

            for _, grillo in pairs(REVEL.ENT.GRILL_O_WISP:getInRoom()) do
                local gSprite = grillo:GetSprite()
                if not gSprite:IsPlaying("FlickerRed") then
                    validFires[#validFires + 1] = {Entity = grillo, Position = grillo.Position}
                    if grillo.Position:DistanceSquared(target.Position) < 160 ^ 2 then
                        closeToPlayer[#closeToPlayer + 1] = validFires[#validFires]
                    end
                end
            end

            for _, lightableFire in pairs(REVEL.ENT.LIGHTABLE_FIRE:getInRoom()) do
                if REVEL.Glacier.IsLightableFireOn(lightableFire) then
                    local fSprite = lightableFire:GetSprite()
                    if not fSprite:IsPlaying("FlickerRed") then
                        validFires[#validFires + 1] = {Entity = lightableFire, Position = lightableFire.Position}
                        if lightableFire.Position:DistanceSquared(target.Position) < 160 ^ 2 then
                            closeToPlayer[#closeToPlayer + 1] = validFires[#validFires]
                        end
                    end
                end
            end
        end

        for _, fireplace in ipairs(Isaac.FindByType(EntityType.ENTITY_FIREPLACE, -1, -1, false, false)) do
            local fSprite = fireplace:GetSprite()
            
            if REVEL.MultiPlayingCheck(fSprite, "Flickering", "Flickering2", "Flickering3") 
            and not fireplace:GetData().IsFirecallerFire 
            and not fireplace:GetData().LightableFireFire 
            then
                validFires[#validFires + 1] = {Entity = fireplace, Position = fireplace.Position}
                if fireplace.Position:DistanceSquared(target.Position) < 160 ^ 2 then
                    closeToPlayer[#closeToPlayer + 1] = validFires[#validFires]
                end
            end
        end

        if sprite:IsFinished("IgniteFast") or not data.AttackCooldown then
            data.AttackCooldown = math.random(20, 30)
        end

        if not sprite:IsPlaying("IgniteFast") then
            REVEL.MoveRandomly(npc, 90, 15, 25, 0.3, 0.85, target.Position)
            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})

            data.AttackCooldown = data.AttackCooldown - 1

            if data.AttackCooldown <= 0 and #closeToPlayer > 0 then
                sprite:Play("IgniteFast", true)
                data.AttackCooldown = math.random(20, 30)
            end
        else
            sprite.PlaybackSpeed = 1
        end

        if not (sprite:IsPlaying("WalkHori") or sprite:IsPlaying("WalkVert")) then
            npc.Velocity = npc.Velocity * 0.85
        end

        if sprite:IsEventTriggered("Shoot") and #validFires > 0 then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 0.8, 0, false, 1)

            --[[
            for _, flameTrap in ipairs(Isaac.FindByType(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, -1, false, false)) do
                local fData = flameTrap:GetData()
                fData.HomingCooldown = 24
            end
            ]]

            local activate
            if #closeToPlayer > 0 then
                activate = closeToPlayer[math.random(1, #closeToPlayer)]
            else
                local closeDist
                for _, fire in ipairs(validFires) do
                    local dist = fire.Position:DistanceSquared(target.Position)
                    if not closeDist or dist < closeDist then
                        closeDist = dist
                        activate = fire
                    end
                end
            end

            local isEntity = not activate.GridEntity

            local fSprite, fData
            if activate.Entity then
                activate = activate.Entity
                fSprite, fData = activate:GetSprite(), activate:GetData()
            elseif activate.GridEntity then
                activate = activate.GridEntity
                fSprite, fData = activate:GetSprite(), REVEL.GetTempGridData(activate:GetGridIndex())
            end

            fData.FireCallerTarget = target
            fData.FireCallerSource = EntityPtr(npc)
            fData.HomingProjectiles = REVEL.ENT.FIRECALLER:isEnt(npc) or (activate.Type == EntityType.ENTITY_FIREPLACE and activate.Variant == 3)

            if isEntity and activate.Type == EntityType.ENTITY_FIREPLACE then
                local animation = nil
                if fSprite:IsPlaying("Flickering") then
                    animation = "Flickering"
                elseif fSprite:IsPlaying("Flickering2") then
                    animation = "Flickering2"
                elseif fSprite:IsPlaying("Flickering3") then
                    animation = "Flickering3"
                end

                if animation then
                    fData.IsFirecallerFire = true

                    local animationFile
                    --Tomb
                    if REVEL.ENT.FIRECALLER:isEnt(npc) then
                        animationFile = "gfx/effects/revel2/fireplace_normal_flickerpurple.anm2"
                        if activate.Variant == 1 then
                            animationFile = "gfx/effects/revel2/fireplace_red_flickerpurple.anm2"
                        elseif activate.Variant == 2 then
                            animationFile = "gfx/effects/revel2/fireplace_blue_flickerpurple.anm2"
                        elseif activate.Variant == 3 then
                            animationFile = "gfx/effects/revel2/fireplace_purple_flickerpurple.anm2"
                        end
                    else --Glacier
                        animationFile = "gfx/effects/revel1/fireplace_normal_flickerred.anm2"
                        if activate.Variant == 1 then
                            animationFile = "gfx/effects/revel1/fireplace_red_flickerred.anm2"
                        elseif activate.Variant == 2 then
                            animationFile = "gfx/effects/revel1/fireplace_blue_flickerred.anm2"
                        elseif activate.Variant == 3 then
                            animationFile = "gfx/effects/revel2/fireplace_purple_flickerpurple.anm2"
                        end
                    end

                    fSprite:Load(animationFile, true)
                    fSprite:Play(animation, true)

                    fData.ResetFrame = true

                    activate:ToNPC().State = NpcState.STATE_INIT
                    activate:Update()
                end
            else
                if REVEL.ENT.FIRECALLER:isEnt(npc) then
                    fSprite:Play("FlickerPurple", true)
                elseif isEntity and REVEL.ENT.LIGHTABLE_FIRE:isEnt(activate) then
                    fSprite:Play("FlickerRed" .. fData.TypeSuffix, true)
                else
                    fSprite:Play("FlickerRed", true)
                end
            end
        end
    else
        sprite.PlaybackSpeed = 1
        if sprite:IsEventTriggered("Explode") then
            data.HasExploded = true
            local isRemainingFirecaller
            local firecallers = getFireCallers()
            for _, firecaller in ipairs(firecallers) do
                if not firecaller:GetData().HasExploded then
                    isRemainingFirecaller = true
                end
            end

            -- Death burst (Tomb)

            if not isRemainingFirecaller and REVEL.ENT.FIRECALLER:isEnt(npc) then
                for _, fire in ipairs(Isaac.FindByType(EntityType.ENTITY_FIREPLACE, -1, -1, false, false)) do
                    if fire.HitPoints > 1 then
                        local pos = fire.Position
                        local speed = 8
                        local mode = ProjectilesMode.CROSS
                        local params = ProjectileParams()
                        params.VelocityMulti = 0.9
                        params.Variant = ProjectileVariant.PROJECTILE_FIRE
                        params.Color = Color(1, 0.7, 1, 0.5)
                        params.Scale = 0.6
                        params.Acceleration = -3
                            
                        npc:FireProjectiles(pos, Vector(speed, 0), mode, params)

                        fire:Die()
                    end
                end
            end

            npc:BloodExplode()
        end

        if sprite:IsFinished("BecomeFire") or sprite:IsFinished("IgniteBecomeFire") or sprite:IsFinished("FireShoot") then
            sprite:Play("Fire", true)
        end

        if not data.FlameFrames then
            data.FlameFrames = 0
        end

        data.FlameFrames = data.FlameFrames + 1
        if data.FlameFrames % 45 == 0 and target.Position:DistanceSquared(npc.Position) < 150 ^ 2 then
            sprite:Play("FireShoot", true)
        end

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1)
            local speed = REVEL.ENT.FIRECALLER:isEnt(npc) and 12 or 9.5
            local projectile = REVEL.SpawnNPCProjectile(npc, (target.Position - npc.Position):Resized(speed))
            projectile:GetData().NoFrostyProjectile = true
            if REVEL.ENT.FIRECALLER:isEnt(npc) then --tomb
                projectile.ProjectileFlags = BitOr(projectile.ProjectileFlags, ProjectileFlags.SMART)
            end
        end

        npc.Velocity = Vector.Zero
    end
end, REVEL.ENT.FIRECALLER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags)
    if e.Variant == REVEL.ENT.FIRECALLER.variant or e.Variant == REVEL.ENT.FIRECALLER_GLACIER.variant then
        if HasBit(flags, DamageFlag.DAMAGE_FIRE) then
            return false
        end

        if e.HitPoints - amount - REVEL.GetDamageBuffer(e) < 0 and e:GetSprite():IsPlaying("IgniteBecomeFire") then
            e.HitPoints = 0
            return false
        end

        if e.HitPoints - amount - REVEL.GetDamageBuffer(e) < 0 and not e:GetData().IsFlame then
            local heal = REVEL.ENT.FIRECALLER:isEnt(e) and 15 or 10
            e.HitPoints = heal + amount
            e:GetData().IsFlame = true
            e:GetSprite():Play("IgniteBecomeFire", true)
        end
    end
end, REVEL.ENT.FIRECALLER.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    local firecallers = getFireCallers()
    if #firecallers == 1 then
        if REVEL.sfx:IsPlaying(REVEL.SFX.FIRE_BURNING) then
            REVEL.sfx:Stop(REVEL.SFX.FIRE_BURNING)
        end
    end
    REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
    
    if REVEL.ENT.FIRECALLER_GLACIER:isEnt(npc) then
        local grillos = REVEL.ENT.GRILL_O_WISP:getInRoom()
        for _, entity in ipairs(grillos) do
            local firecallerSrc = entity:GetData().FireCallerSource and entity:GetData().FireCallerSource.Ref
            if firecallerSrc and GetPtrHash(firecallerSrc) == GetPtrHash(npc) then
                entity:GetData().FireCallerSource = nil
                entity:GetData().FireCallerTarget = nil
                entity:ToNPC().State = NpcState.STATE_MOVE
            end
        end
    end
end, REVEL.ENT.FIRECALLER.id)

local function fireFirecallerProjectile(source, data, nocolltime, npc)
    local pos = source.Position + Vector(0, 24)
    local projectile = Isaac.Spawn(
        EntityType.ENTITY_PROJECTILE, 
        ProjectileVariant.PROJECTILE_NORMAL, 
        0, 
        pos, 
        (data.FireCallerTarget.Position - pos):Resized(8), 
        npc
    ):ToProjectile()
    projectile:GetData().NoFrostyProjectile = true

    if data.HomingProjectiles then
        projectile.ProjectileFlags = ProjectileFlags.SMART
    end

    projectile.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    projectile.FallingAccel = -0.05
    projectile:GetData().BrazierProjectile = true
    projectile:GetData().NoCollTime = nocolltime or 4
    projectile:Update()
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local sprite, data = npc:GetSprite(), npc:GetData()
    if data.IsFirecallerFire then
        -- Sometimes fires start past the shoot frame, for some reason
        if data.ResetFrame then
            sprite:SetFrame(0)
            data.ResetFrame = nil
        end

        if sprite:IsEventTriggered("Shoot") and data.FireCallerTarget then
            fireFirecallerProjectile(npc, data)
        end

        local animation
        if sprite:IsFinished("Flickering") then
            animation = "Flickering"
        elseif sprite:IsFinished("Flickering2") then
            animation = "Flickering2"
        elseif sprite:IsFinished("Flickering3") then
            animation = "Flickering3"
        end

        if animation then
            local animationFile = "gfx/033.000_fireplace.anm2"
            if npc.Variant == 1 then
                animationFile = "gfx/033.001_red fireplace.anm2"
            elseif npc.Variant == 2 then
                animationFile = "gfx/033.002_blue fireplace.anm2"
            elseif npc.Variant == 3 then
                animationFile = "gfx/033.003_purple fireplace.anm2"
            end

            sprite:Load(animationFile, true)
            sprite:Play(animation, true)

            npc.State = NpcState.STATE_INIT
            npc:Update()

            data.IsFirecallerFire = false
        end
    end
end, EntityType.ENTITY_FIREPLACE)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite, data = eff:GetSprite(), eff:GetData()
    if sprite:IsEventTriggered("Shoot") and data.FireCallerTarget then
        fireFirecallerProjectile(eff, data, 15)
    end

    if sprite:IsFinished("FlickerPurple") then
        sprite:Play("Idle", true)
    end
end, REVEL.ENT.CORNER_BRAZIER.variant)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.GRILL_O_WISP:isEnt(npc) then return end
    local sprite, data = npc:GetSprite(), npc:GetData()

    if sprite:IsEventTriggered("Shoot") and data.FireCallerTarget then
        fireFirecallerProjectile(npc, data)
    end

    if sprite:IsFinished("FlickerRed") then
        sprite:Play("Idle", true)
    end
end, REVEL.ENT.GRILL_O_WISP.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.LIGHTABLE_FIRE:isEnt(npc) then return end
    local sprite, data = npc:GetSprite(), npc:GetData()

    if sprite:IsPlaying("FlickerRed" .. data.TypeSuffix)
    and sprite:IsEventTriggered("Shoot") and data.FireCallerTarget then
        fireFirecallerProjectile(npc, data)
    end

    if sprite:IsFinished("FlickerRed" .. data.TypeSuffix) then
        sprite:Play("Flickering" .. data.TypeSuffix, true)
    end
end, REVEL.ENT.LIGHTABLE_FIRE.id)

StageAPI.AddCallback("Revelations", "POST_CUSTOM_GRID_UPDATE", 1, function(customGrid)
    local grid = customGrid.GridEntity
    local grindex = customGrid.GridIndex
    local sprite, data = grid:GetSprite(), REVEL.GetTempGridData(grindex)

    if sprite:IsEventTriggered("Shoot") and data.FireCallerTarget then
        fireFirecallerProjectile(grid, data)
    end

    if sprite:IsFinished("FlickerRed") then
        sprite:Play("Flickering", true)
    end
end, REVEL.GRIDENT.BRAZIER.Name)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    local data = pro:GetData()
    if data.BrazierProjectile then
        if pro.FrameCount > (data.NoCollTime or 4) then
            pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
        else
            pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        end
        pro.HomingStrength = 0.3
    end
end)

end