local RevCallbacks = require("scripts.revelations.common.enums.RevCallbacks")

return function()
---------------
-- Tummy Bug --
---------------

-- Sometimes stop shooting to charge spray of high-arc brown tears
local TummyBug = {
    fullChargeColorT = 20,
    fullPlayerColor = Color(1, 80 / 255, 0, 1, conv255ToFloat(30, 0, 0)),
    currentPlayerColor = Color.Default,
    firstInput = nil,
    tearFSPeed = -20,
    tearBaseSpeed = 5.5,
    tearFAccel = 0.7,
    tearColor = Color(100 / 255, 50 / 255, 0, 1, conv255ToFloat(0, 0, 0))
}

function TummyBug.FireTear(player)
    local vel, data = nil, REVEL.GetData(player)

    if player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) then
        vel = data.tbugInput:Rotated(math.random(20) - 10) 
            * (TummyBug.tearBaseSpeed * player.ShotSpeed 
            * (0.65 + math.random() * 0.7))
    else
        vel = REVEL.dirToVel[data.tbugDir]:Rotated(math.random(20) - 10) 
            * (TummyBug.tearBaseSpeed * player.ShotSpeed 
            * (0.65 + math.random() * 0.7))
    end

    local tear = player:FireTear(player.Position, vel, false, false, false)
    tear.FallingSpeed = TummyBug.tearFSPeed * (0.8 + math.random() * 0.4)
    tear.FallingAcceleration = TummyBug.tearFAccel
    tear:GetSprite().Color = TummyBug.tearColor
    tear.Scale = tear.Scale * 1.3
    tear.CollisionDamage = tear.CollisionDamage * 2
end

TummyBug.nonBlockingCollisions = {
    GridCollisionClass.COLLISION_NONE, GridCollisionClass.COLLISION_OBJECT
}

revel:AddCallback(ModCallbacks.MC_USE_PILL, function(_, pillEffect, player, useFlags)
    if REVEL.ITEM.TBUG:PlayerHasCollectible(player) then
        local dir
        if player:GetFireDirection() ~= Direction.NO_DIRECTION then
            dir = REVEL.dirToVel[player:GetFireDirection()]
        else
            if player:GetMovementDirection() ~= Direction.NO_DIRECTION then
                dir = REVEL.dirToVel[player:GetMovementDirection()]
            else
                dir = REVEL.dirToVel[Direction.DOWN]
            end
        end

        for i = 1, 7 do
            local pos = player.Position + dir * (48 * i)

            if not REVEL.includes(TummyBug.nonBlockingCollisions,
                                REVEL.room:GetGridCollision(
                                    REVEL.room:GetGridIndex(pos))) then
                break
            end

            local c = Isaac.Spawn(1000, EffectVariant.PLAYER_CREEP_GREEN, 0,
                                    pos, Vector.Zero, player):ToEffect()
            c.Timeout = 120
            local mult = math.sqrt(i * 2)
            c.Size = c.Size * mult
            c.SpriteScale = Vector(mult, mult)
            REVEL.GetData(c).tbugCreep = true
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src)
    if src.Entity and src.Entity.Type == 1000 
    and src.Entity.Variant == EffectVariant.PLAYER_CREEP_GREEN 
    and REVEL.OnePlayerHasCollectible(REVEL.ITEM.TBUG.id) 
    then
        local creeps = Isaac.FindByType(
            1000, 
            EffectVariant.PLAYER_CREEP_GREEN,
            -1, 
            false, 
            false
        )

        local player = REVEL.randomFrom(REVEL.filter(REVEL.players, 
            function(p) return p:HasCollectible(REVEL.ITEM.TBUG.id) end)
        )

        for i, c in ipairs(creeps) do
            if c.Index == src.Entity.Index and REVEL.GetData(c).tbugCreep == true then -- if source is tummy bug creep
                -- change damage by updating health to negate vanilla creep damage and add ours, as collisiondamage doesn't work with creep
                e.HitPoints = e.HitPoints + 1 - player.Damage * 0.03
            end
        end
    end
end)

local ShootActions = {
    ButtonAction.ACTION_SHOOTLEFT,
    ButtonAction.ACTION_SHOOTUP,
    ButtonAction.ACTION_SHOOTRIGHT,
    ButtonAction.ACTION_SHOOTDOWN,
}

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    local spr, data = player:GetSprite(), REVEL.GetData(player)

    if not REVEL.ITEM.TBUG:PlayerHasCollectible(player) then
        if data.tbugCharge then
            data.tbugCurColor = Color(1, 1, 1, 1, conv255ToFloat(0, 0, 0))
            player:SetColor(data.tbugCurColor, 2, 3, false, true)
            data.tbugCurColor = nil
            data.tbugCharge = nil
            data.tbugMaxCharge = nil
            data.tbugDir = nil
            for _, action in ipairs(ShootActions) do
                REVEL.ClearForceInput(player, "tbugg" .. action)
                REVEL.ClearForceInput(player, "tbugp" .. action)
            end
        end

        return
    end

    if not data.tbugCharge then
        data.tbugCharge = 0
        data.tbugMaxCharge = 300 + math.random(150)
        data.tbugCurColor = Color(1, 1, 1, 1, conv255ToFloat(0, 0, 0))
        data.tbugDir = Direction.NO_DIRECTION
    end

    -- if REVEL.DEBUG and IDebug then IDebug.RenderUntilNext("RevDebug1", IDebug.RenderTextByEntity, player, data.tbugCharge.." / "..data.tbugMaxCharge) end

    if REVEL.IsShooting(player) or data.tbugCharge < 0 then

        if data.tbugCharge < data.tbugMaxCharge then
            data.tbugCharge = data.tbugCharge + 1

            if data.tbugCharge < 0 then --shooting after puke
                player.FireDelay = player.MaxFireDelay
        
                -- REVEL.ForceInput(player, REVEL.dirToShootAction[data.tbugDir], InputHook.GET_ACTION_VALUE, 1, true)
                -- REVEL.ForceInput(player, REVEL.dirToShootAction[data.tbugDir], InputHook.IS_ACTION_PRESSED, true, true)
                -- for dir=0, 3 do --directions from 0(left) to 3(down)
                --     if dir ~= data.tbugDir then
                --         REVEL.ForceInput(player, REVEL.dirToShootAction[dir], InputHook.GET_ACTION_VALUE, 0, true)
                --         REVEL.ForceInput(player, REVEL.dirToShootAction[dir], InputHook.IS_ACTION_PRESSED, false, true)
                --     end
                -- end
    
                if data.tbugCharge % 4 == 0 then
                    TummyBug.FireTear(player)
                end
            elseif data.tbugCharge == 0 then
                for _, action in ipairs(ShootActions) do
                    REVEL.ClearForceInput(player, "tbugg" .. action)
                    REVEL.ClearForceInput(player, "tbugp" .. action)
                end
            end
        else -- fully charged, glow
            if not data.tbugFChargeFrame then
                data.tbugFChargeFrame = player.FrameCount
            end

            local sinStage = math.sin(
                (-math.pi / 2 + player.FrameCount - data.tbugFChargeFrame) 
                / TummyBug.fullChargeColorT
            ) / 2 + 0.5 -- oscillates from 0 to 1, #maths

            --      REVEL.DebugToString({player.FrameCount-data.tbugFChargeFrame,sinStage})

            data.tbugCurColor:SetTint(
                1, 
                1 - sinStage * (1 - TummyBug.fullPlayerColor.G),
                1 - sinStage * (1 - TummyBug.fullPlayerColor.B),
                1
            )
            data.tbugCurColor:SetOffset(
                sinStage * TummyBug.fullPlayerColor.RO,
                0, 
                0
            )
            --      player:GetSprite().Color = data.tbugCurColor
            player:SetColor(data.tbugCurColor, 2, 3, false, true)

            player.FireDelay = player.MaxFireDelay

            data.tbugDir = player:GetHeadDirection()
            if player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) then
                data.tbugInput = player:GetShootingInput()
            end
        end

    -- not shooting/released
    elseif data.tbugCharge >= data.tbugMaxCharge and not data.Frozen then -- FIRE
        REVEL.sfx:Play(REVEL.SFX.TUMMY_BUG_VOMIT, 1, 0, false, 1)
        data.tbugFChargeFrame = nil
        --      player:GetSprite().Color = Color.Default
        data.tbugMaxCharge = 300 + math.random(150)

        local tearAmount = 4 + math.random(5) 
            + math.max(0, math.floor((10 - player.MaxFireDelay) / 2))
        data.tbugCharge = -4 * tearAmount

        TummyBug.FireTear(player)

        if data.tbugDir then
            for _, action in ipairs(ShootActions) do
                if action == REVEL.dirToShootAction[data.tbugDir] then
                    REVEL.ForceInput(player, action, InputHook.GET_ACTION_VALUE, 1, false, "tbugg" .. action)
                    REVEL.ForceInput(player, action, InputHook.IS_ACTION_PRESSED, true, false, "tbugp" .. action)
                else
                    REVEL.ForceInput(player, action, InputHook.GET_ACTION_VALUE, 0, false, "tbugg" .. action)
                    REVEL.ForceInput(player, action, InputHook.IS_ACTION_PRESSED, false, false, "tbugp" .. action)
                end
            end
        end
    end
end)

end
