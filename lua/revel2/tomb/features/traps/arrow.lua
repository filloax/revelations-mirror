local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
return function()

REVEL.TrapTypes.ArrowTrap = {
    OnSpawn = function(tile, data, index)
        local rotation = data.TrapData.Rotation
        local pos = tile.Position

        if rotation==90 then pos = Vector(REVEL.room:GetBottomRightPos().X, pos.Y)
        elseif rotation==180 then pos = Vector(pos.X, REVEL.room:GetBottomRightPos().Y)
        elseif rotation==270 then pos = Vector(REVEL.room:GetTopLeftPos().X, pos.Y)
        elseif rotation==0 then pos = Vector(pos.X, REVEL.room:GetTopLeftPos().Y) end

        local alreadyExists
        local spawnPos = pos + (Vector.FromAngle(rotation-90)*5)

        local arrowTraps = Isaac.FindByType(REVEL.ENT.ARROW_TRAP.id, REVEL.ENT.ARROW_TRAP.variant, -1, false, false)
        for _, trap in ipairs(arrowTraps) do
            if REVEL.room:GetGridIndex(trap.Position) == REVEL.room:GetGridIndex(spawnPos) and trap:GetSprite().Rotation == rotation then
                alreadyExists = trap
                break
            end
        end

        if not alreadyExists then
            local eff = Isaac.Spawn(REVEL.ENT.ARROW_TRAP.id, REVEL.ENT.ARROW_TRAP.variant, 0, spawnPos, Vector.Zero, nil)
            eff:GetSprite().Rotation = rotation
            data.ArrowTrap = eff
        else
            data.ArrowTrap = alreadyExists
        end
    end,
    OnTrigger = function(tile, data)
        local adata = data.ArrowTrap:GetData()
        adata.NoHitPlayer = data.TrapIsPositiveEffect
        local sprite = data.ArrowTrap:GetSprite()
        if not sprite:IsPlaying("Shoot") then
            sprite:Play("Shoot", true)
        end
    end,
    OnUpdate = function(tile, data)
        if data.TrapTriggered then
            local adata = data.ArrowTrap:GetData()
            adata.NoHitPlayer = data.TrapIsPositiveEffect
            local sprite = data.ArrowTrap:GetSprite()
            if not sprite:IsPlaying("Shoot") then
                sprite:Play("Shoot", true)
            end
        end
    end,
    IsValidRandomSpawn = function(grindex)
        local nearDoor
        local gpos = REVEL.room:GetGridPosition(grindex)
        local validRotations = {}
        local cornerPositions, edgePositions = REVEL.GetCornerPositions()

        for rotation = 0, 270, 90 do
            local pos
            if rotation==90 then pos = Vector(REVEL.room:GetBottomRightPos().X, gpos.Y)
            elseif rotation==180 then pos = Vector(gpos.X, REVEL.room:GetBottomRightPos().Y)
            elseif rotation==270 then pos = Vector(REVEL.room:GetTopLeftPos().X, gpos.Y)
            elseif rotation==0 then pos = Vector(gpos.X, REVEL.room:GetTopLeftPos().Y) end

            for i = 0, 7 do
                if REVEL.room:GetDoor(i) then
                    if REVEL.room:GetDoor(i).Position:Distance(pos) < 70 then
                        nearDoor = true
                        break
                    end
                end
            end

            if not nearDoor then
                local nearCorner
                for _, corner in ipairs(cornerPositions) do
                    if corner.Position:Distance(pos) < 100 then
                        nearCorner = true
                        break
                    end
                end

                if not nearCorner then
                    validRotations[#validRotations + 1] = rotation
                end
            end
        end

        if #validRotations > 0 then
            local rot = validRotations[math.random(1, #validRotations)]

            return {
                Angle = rot
            }
        else
            return false
        end
    end,
    Animation = "Arrow"
}

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro:GetData().ArrowTrapHitGrids then
        local index = REVEL.room:GetGridIndex(pro.Position)
        local grid = REVEL.room:GetGridEntity(index)
        if grid and not pro:GetData().ArrowTrapHitGrids[index] 
        and (grid.Desc.Type == GridEntityType.GRID_POOP or grid.Desc.Type == GridEntityType.GRID_TNT) 
        and not REVEL.IsGridBroken(grid) then
            pro:GetData().ArrowTrapHitGrids[index] = true
            grid:Hurt(1)
        end
    end
end)

local arrowProjectilePositionOffset = Vector(0, 17)
local arrowProjectileDamage = 14
local arrowProjectilePlayerDamage = 1
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if REVEL.IsShrineEffectActive(ShrineTypes.PERIL) and eff:GetSprite():IsFinished("Shoot") then
        eff:GetSprite():Play("ShootOnce", true)
    end

    if eff:GetSprite():IsEventTriggered("Shootx3") then
        local t = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, eff.Position+(Vector.FromAngle(eff:GetSprite().Rotation+90)*3)+arrowProjectilePositionOffset, (Vector.FromAngle(eff:GetSprite().Rotation+90)*10), eff):ToProjectile()
        t:GetData().IsArrowTrapProjectile = true
        local flags = BitOr(ProjectileFlags.HIT_ENEMIES, ProjectileFlags.NO_WALL_COLLIDE)
        if eff:GetData().NoHitPlayer then
            flags = BitOr(flags, ProjectileFlags.CANT_HIT_PLAYER)
        end

        REVEL.sfx:Play(SoundEffect.SOUND_STONESHOOT, 1, 0, false, 2)

        t:AddProjectileFlags(flags)
        t.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        t.FallingSpeed = 0
        t.FallingAccel = -0.09
        t.Height = -20
        t:GetData().ArrowTrapHitGrids = {}
        t.CollisionDamage = arrowProjectileDamage
    end
end, REVEL.ENT.ARROW_TRAP.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flags, src, invuln)
    if src and src.Entity and src.Entity.Type == EntityType.ENTITY_PROJECTILE and dmg == arrowProjectileDamage then
        ent:TakeDamage(arrowProjectilePlayerDamage, flags, src, invuln)

        return false
    end
end, EntityType.ENTITY_PLAYER)


end