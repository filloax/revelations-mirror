local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
return function()

-- Ophanim

local function OphanimShoot(player, ophanim, data, sprite)
    local frame = sprite:GetFrame()
    sprite:Play("IdleShoot", true)
    if frame > 0 then
        for i = 1, frame do
            sprite:Update()
        end
    end
    data.OphanimShotRecently = 6
    data.OphanimTimesShot = 0

    local startAngle = REVEL.Lerp(0, 90, frame / 11)

    for i = 1, 4 do
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, player.Position, Vector.FromAngle(i * 90 + startAngle) * 10, nil):ToTear()
        REVEL.GetData(tear).OphanimTear = true
    end
end

---@param player EntityPlayer
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local data = REVEL.GetData(player)
    if not REVEL.ITEM.OPHANIM:PlayerHasCollectible(player) then
        if data.Ophanim then
            if data.Ophanim:Exists() then
                data.Ophanim:Remove()
            end

            data.Ophanim = nil
            data.OphanimTimesShot = nil
            data.OphanimShotRecently = nil
            data.OphanimTakenDamage = nil
            data.OphanimCanShoot = nil
        end

        return
    end

    if not data.Ophanim or not data.Ophanim:Exists() then
        data.Ophanim = Isaac.Spawn(REVEL.ENT.OPHANIM.id, REVEL.ENT.OPHANIM.variant, 0, player.Position, Vector.Zero, nil):ToEffect()
        data.Ophanim.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        data.OphanimTimesShot = 0
        data.OphanimShotRecently = 0
        data.OphanimTakenDamage = nil
        data.OphanimCanShoot = nil
    end

    local toFollow = player
    if data.CameraMode then
        ---@type CameraModeData
        local cameraData = data.Camera
        toFollow = cameraData.StandinEffect:Exists() and cameraData.StandinEffect
    end

    local ophanim, sprite = data.Ophanim, data.Ophanim:GetSprite()
    if not data.OphanimTakenDamage then
        ophanim.Velocity = toFollow.Position - ophanim.Position
        if data.OphanimShotRecently > 0 then
            data.OphanimShotRecently = data.OphanimShotRecently - 1
            if data.OphanimShotRecently <= 0 then
                local frame = sprite:GetFrame()
                sprite:Play("Idle", true)
                if frame > 0 then
                    for i = 1, frame do
                        sprite:Update()
                    end
                end
            end
        end

        local chargedShot = player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE)
            or player:HasWeaponType(WeaponType.WEAPON_KNIFE)
            or player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS)
            or player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) -- not really charged but treat the same for synergy
            or player:HasWeaponType(WeaponType.WEAPON_TEARS) and player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK)

        if REVEL.IsShooting(player) then
            if chargedShot then
                local MaxDelay = 50
                data.OphanimShootDelay = (data.OphanimShootDelay or MaxDelay) - 1
                if data.OphanimShootDelay <= 0 then
                    data.OphanimShootDelay = MaxDelay
                    OphanimShoot(player, ophanim, data, sprite)
                end
            else
                if player.FireDelay < 1 then
                    data.OphanimCanShoot = true
                elseif data.OphanimCanShoot then
                    data.OphanimCanShoot = nil
                    data.OphanimTimesShot = data.OphanimTimesShot + 1
                    if data.OphanimTimesShot == 2 then
                        OphanimShoot(player, ophanim, data, sprite)
                    end
                end
            end
        end
    else
        if data.OphanimTakenDamage == 0 then
            local closestEnemy = REVEL.getClosestEnemy(player, false, true, true, true)
            if closestEnemy then
                ophanim.Velocity = (closestEnemy.Position - ophanim.Position):Resized(12)
            else
                ophanim.Velocity = RandomVector() * 12
            end

            sprite:Play("AttackLoop", true)
            data.OphanimTakenDamage = 1
            data.OphanimBounced = nil
        elseif data.OphanimTakenDamage == 1 then
            local clamp = REVEL.room:GetClampedPosition(ophanim.Position, 0)
            local bounceX, bounceY
            if clamp.X ~= ophanim.Position.X then
                bounceX = true
            end

            if clamp.Y ~= ophanim.Position.Y then
                bounceY = true
            end

            if bounceX or bounceY then
                if bounceX then
                    ophanim.Velocity = Vector(-ophanim.Velocity.X, ophanim.Velocity.Y)
                end

                if bounceY then
                    ophanim.Velocity = Vector(ophanim.Velocity.X, -ophanim.Velocity.Y)
                end

                if not data.OphanimBounced then
                    data.OphanimBounced = true
                else
                    data.OphanimTakenDamage = 2
                end
            end
        elseif data.OphanimTakenDamage == 2 then
            ophanim.Velocity = ophanim.Velocity * 0.9 + (toFollow.Position - ophanim.Position):Resized(2)
            if ophanim.Position:DistanceSquared(toFollow.Position) <= 12 ^ 2 then
                data.OphanimTakenDamage = nil
                sprite:Play("Idle", true)
            end
        end

        if sprite:IsEventTriggered("Shoot") then
            local startAngle = REVEL.Lerp(0, 90, sprite:GetFrame() / 11)

            for i = 1, 4 do
                local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, ophanim.Position, Vector.FromAngle(i * 90 + startAngle) * 10, nil):ToTear()
                REVEL.GetData(tear).OphanimTear = true
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if REVEL.GetData(tear).OphanimTear then
        tear.Velocity = tear.Velocity:Rotated(-10)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(e)
    local player = e:ToPlayer()
    if player and REVEL.ITEM.OPHANIM:PlayerHasCollectible(player) and not REVEL.GetData(player).OphanimTakenDamage then
        REVEL.GetData(player).OphanimTakenDamage = 0
    end
end, EntityType.ENTITY_PLAYER)
  
end