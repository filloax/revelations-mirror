local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Ophanim

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()
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

        if player.FireDelay <= 0 then
            data.OphanimCanShoot = true
        elseif data.OphanimCanShoot then
            data.OphanimCanShoot = nil
            data.OphanimTimesShot = data.OphanimTimesShot + 1
            if data.OphanimTimesShot == 2 then
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
                    tear:GetData().OphanimTear = true
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
                tear:GetData().OphanimTear = true
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if tear:GetData().OphanimTear then
        tear.Velocity = tear.Velocity:Rotated(-10)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(e)
    local player = e:ToPlayer()
    if player and REVEL.ITEM.OPHANIM:PlayerHasCollectible(player) and not player:GetData().OphanimTakenDamage then
        player:GetData().OphanimTakenDamage = 0
    end
end, EntityType.ENTITY_PLAYER)
  
end

REVEL.PcallWorkaroundBreakFunction()