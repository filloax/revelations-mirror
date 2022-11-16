local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local shared            = require("lua.revelcommon.dante.shared")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local incubusShootAnims = {
    "FloatShootDown",
    "FloatShootSide",
    "FloatShootUp",
    "ShootDown",
    "ShootSide",
    "ShootUp"
}

local incubusChargeAnims = {
    "ChargeDown",
    "ChargeSide",
    "ChargeUp",
    "FloatChargeDown",
    "FloatChargeSide",
    "FloatChargeUp"
}

local incubusChargeShootAnims = {
    "Shoot2Down",
    "Shoot2Side",
    "Shoot2Up"
}

local freezeHeadAnimations = {
    "HeadDown",
    "HeadLeft",
    "HeadRight",
    "HeadUp",
    "Freeze",
    "Melt"
}

local function MergeRoomCharacterUpdate(effect, data, sprite, player, pdata)
    if data.StickPlayerToThisPosition then
        player.Position = data.StickPlayerToThisPosition
    end

    if effect.FrameCount > 4 and not data.HighFiving then
        if player.CanFly then
            effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        else
            effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        end

        local leftSide = false
        local leftPos = player.Position + Vector(-70,0)
        local rightPos = player.Position + Vector(70,0)
        if leftPos:Distance(effect.Position) < rightPos:Distance(effect.Position) then
            leftSide = true
        end

        local gotoPos
        if leftSide then
            gotoPos = leftPos
        else
            gotoPos = rightPos
        end

        if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, effect) then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, effect)
        end
        data.UsePlayerMap = true
        data.TargetIndex = REVEL.room:GetGridIndex(gotoPos)

        if not data.Path or data.IsAngry then
            gotoPos = player.Position
            data.TargetIndex = REVEL.room:GetGridIndex(gotoPos)
        end

        local distanceToGoto = effect.Position:Distance(gotoPos)

        local movementFriction = 0.65
        local movementResized = 3.5

        if data.IsAngry or distanceToGoto > 450 then
            movementFriction = 0.65
            movementResized = 6.5
        elseif distanceToGoto > 300 then
            movementFriction = 0.65
            movementResized = 5.5
        elseif distanceToGoto > 150 then
            movementFriction = 0.65
            movementResized = 4.5
        end

        if distanceToGoto < 20 then
            effect.Velocity = (effect.Velocity * movementFriction) + (gotoPos - effect.Position):Resized(movementResized)
        elseif data.Path then
            REVEL.FollowPath(effect, movementResized, data.Path, true, movementFriction, not player.CanFly, true, player.CanFly, false)
        end

        if effect.FrameCount > 100 and not data.Path then
            effect.Position = REVEL.room:FindFreePickupSpawnPosition(player.Position, 60, true)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, effect.Position, Vector.Zero, effect)
        end

        if revel.data.run.dante.OtherInventory and revel.data.run.dante.OtherInventory.position and revel.data.run.dante.OtherInventory.position.X then
            revel.data.run.dante.OtherInventory.position = {X = effect.Position.X, Y = effect.Position.Y}
        end
        if not data.IsAngry and distanceToGoto < 20 then
            shared.PlayerControlsDisabled = true
        end

        if (data.IsAngry and distanceToGoto < 20) or distanceToGoto < 5 then
            data.HighFiving = true

            if not data.IsAngry then
                data.StickPlayerToThisPosition = player.Position
                player.Velocity = Vector.Zero

                effect.Velocity = Vector.Zero
                effect.Position = player.Position

                if (leftSide and revel.data.run.dante.IsDante) or (not leftSide and not revel.data.run.dante.IsDante) then
                    sprite.FlipX = true
                end

                sprite:Load("gfx/characters/revelcommon/character_charon_meetup.anm2", true)
                if revel.data.run.dante.IsDante then
                    sprite:Play("DanteStart", true)
                else
                    sprite:Play("CharonStart", true)
                end

                player.Visible = false
            end
        end

    end

    if sprite:IsEventTriggered("HighFive") then
        REVEL.sfx:Play(REVEL.SFX.CHARON_HIGH_FIVE, 1, 0, false, 1)

        if not revel.data.run.dante.FirstMerge then
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DIME, REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, player)
            revel.data.run.dante.FirstMerge = true
        end
    end

    if sprite:IsFinished("DanteStart") or sprite:IsFinished("CharonStart") or (data.HighFiving and data.IsAngry) 
    or effect.FrameCount > 150 then
        data.HighFiving = false

        effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

        local startDirection
        if data.IsAngry then
            data.IsAngry = false
        else
            if sprite.FlipX then
                effect.Position = player.Position + Vector(-30,0)
                startDirection = Direction.LEFT
            else
                effect.Position = player.Position + Vector(30,0)
                startDirection = Direction.RIGHT
            end

            sprite.FlipX = false

            data.StickPlayerToThisPosition = nil
            shared.PlayerControlsDisabled = false

            player.Visible = true
        end

        data.ForceSetAnimation = true

        pdata.CharonIncubusSpawnLocation = effect.Position
        REVEL.Dante.Merge(player, false)

        if not data.IsAngry then
            REVEL.Dante.SwitchPartnerDirection(startDirection)
        end
    end
end

---@param effect EntityEffect
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local data, sprite = effect:GetData(), effect:GetSprite()
    if data.Charon and REVEL.IsDanteCharon(data.Charon) then
        local player = data.Charon
        local pdata = player:GetData()

        local fsprite, isStandardShooting, isCharging, isFloatCharging, isChargeShooting, forceSetAnimation
        if data.CharonIncubus then
            effect.SpriteScale = Vector(revel.data.run.dante.OtherInventory.spriteScale.X, revel.data.run.dante.OtherInventory.spriteScale.Y)
            local nextPos
            if pdata.JustSwitched then
                if not pdata.JustSwitchedTimer then
                    pdata.JustSwitchedTimer = 0
                end

                pdata.JustSwitchedTimer = pdata.JustSwitchedTimer + 1

                nextPos = REVEL.Lerp(effect.Position, data.CharonIncubus.Position, REVEL.Lerp(0.3, 0.9, pdata.JustSwitchedTimer / 45))

                if effect.Position:DistanceSquared(data.CharonIncubus.Position) < 4 ^ 2 or pdata.JustSwitchedTimer >= 45 then
                    pdata.JustSwitched = nil
                    pdata.JustSwitchedTimer = nil
                end
            else
                nextPos = REVEL.Lerp(effect.Position, data.CharonIncubus.Position, 0.9)
            end

            if REVEL.IsCrawlspace() then
                local x, y = nextPos.X, player.Position.Y
                local toPlayer = sign(player.Position.X - x)
                --stay at a distance of at least 10 from the wall
                if REVEL.room:GetGridCollisionAtPos( Vector(x - toPlayer * 10, y) ) ~= GridCollisionClass.COLLISION_NONE then --add collision in hub/crawlspaces
                    local i = 1
                    while REVEL.room:GetGridCollisionAtPos( Vector(x + toPlayer * (i - 10), y) ) ~= GridCollisionClass.COLLISION_NONE and i < 200 do
                        i = i + 1
                    end
                    x = x + toPlayer * (i - 10)
                end
                nextPos = Vector(x, y)
            end

            effect.Velocity = (nextPos - effect.Position)

            fsprite = data.CharonIncubus:GetSprite()
            for _, shootAnim in ipairs(incubusShootAnims) do
                if fsprite:IsPlaying(shootAnim) or fsprite:IsFinished(shootAnim) then
                    isStandardShooting = true
                    break
                end
            end

            for _, chargeAnim in ipairs(incubusChargeAnims) do
                if fsprite:IsPlaying(chargeAnim) or fsprite:IsFinished(chargeAnim) then
                    if string.sub(chargeAnim, 1, 5) == "Float" then
                        isFloatCharging = true
                    end

                    isCharging = true
                    break
                end
            end

            for _, chargeShootAnim in ipairs(incubusChargeShootAnims) do
                if fsprite:IsPlaying(chargeShootAnim) or fsprite:IsFinished(chargeShootAnim) then
                    isChargeShooting = true
                    break
                end
            end
        else
            MergeRoomCharacterUpdate(effect, data, sprite, player, pdata)
            forceSetAnimation = data.ForceSetAnimation
            data.ForceSetAnimation = nil
        end

        -- Shared sprite handling between charon incubus and merge room effect
        if not data.HighFiving then
            local headDirName
            if data.CharonIncubus then
                local headDir = pdata.IncubusDirection
                if headDir then
                    if headDir == Direction.DOWN then
                        headDirName = "Down"
                    elseif headDir == Direction.UP then
                        headDirName = "Up"
                    elseif headDir == Direction.LEFT then
                        headDirName = "Left"
                    elseif headDir == Direction.RIGHT then
                        headDirName = "Right"
                    end
                end
            end

            if data.CharonIncubus then
                if isStandardShooting and pdata.DanteLastCharging then
                    isStandardShooting = nil
                    isChargeShooting = true
                end
            end

            local filename = sprite:GetFilename()
            if forceSetAnimation then
                filename = ""
            end
            if not revel.data.run.dante.IsDante and not data.CharonIncubus then

                if player.CanFly and filename ~= "gfx/characters/revelcommon/character_dante_flight.anm2" then
                    sprite:Load("gfx/characters/revelcommon/character_dante_flight.anm2", true)
                elseif not player.CanFly and filename ~= "gfx/characters/revelcommon/character_dante.anm2" then
                    sprite:Load("gfx/characters/revelcommon/character_dante.anm2", true)
                end

                if shared.SkippedOtherChar then
                    sprite:ReplaceSpritesheet(1, "gfx/characters/revelcommon/costumes/character_dante_angry.png")
                    sprite:LoadGraphics()
                    data.IsAngry = true
                end

            else

                if player.CanFly and filename ~= "gfx/characters/revelcommon/character_charon_flight.anm2" then
                    sprite:Load("gfx/characters/revelcommon/character_charon_flight.anm2", true)
                elseif not player.CanFly and filename ~= "gfx/characters/revelcommon/character_charon.anm2" then
                    sprite:Load("gfx/characters/revelcommon/character_charon.anm2", true)
                end

                if shared.SkippedOtherChar then
                    sprite:ReplaceSpritesheet(1, "gfx/characters/revelcommon/costumes/character_charon_angry.png")
                    sprite:LoadGraphics()
                    data.IsAngry = true
                end

            end

            local length = effect.Velocity:LengthSquared()
            if length > 2 ^ 2 or player.CanFly then
                if length > 2 ^ 2 then
                    REVEL.AnimateWalkFrame(sprite, effect.Velocity, {
                        Left = "WalkLeft",
                        Right = "WalkRight",
                        Up = "WalkUp",
                        Down = "WalkDown"
                    })
                elseif not sprite:IsPlaying("WalkDown") then
                    sprite:Play("WalkDown", true)
                end
            else
                sprite:SetFrame("WalkDown", 0)
                if not headDirName then
                    headDirName = "Down"
                end
            end

            if not headDirName then
                if sprite:IsPlaying("WalkDown") then
                    headDirName = "Down"
                elseif sprite:IsPlaying("WalkUp") then
                    headDirName = "Up"
                elseif sprite:IsPlaying("WalkLeft") then
                    headDirName = "Left"
                elseif sprite:IsPlaying("WalkRight") then
                    headDirName = "Right"
                end
            end

            if data.CharonIncubus then
                pdata.DanteLastCharging = nil
                if isStandardShooting and data.CharonIncubus:GetData().ShouldShoot then
                    sprite:SetOverlayFrame("Head" .. headDirName, 3)
                elseif isCharging then
                    local frame = fsprite:GetFrame()
                    local percent = frame / 14
                    if isFloatCharging then
                        percent = frame / 29
                    end

                    frame = math.floor(REVEL.Lerp(0, 17, percent))
                    sprite:SetOverlayFrame("Head" .. headDirName .. "Charge", frame)
                    pdata.DanteLastCharging = true
                elseif isChargeShooting and data.CharonIncubus:GetData().ShouldShoot then
                    sprite:SetOverlayFrame("Head" .. headDirName .. "Shoot", 1)
                    pdata.DanteLastCharging = true
                else
                    sprite:SetOverlayFrame("Head" .. headDirName, 1)
                end
            else
                sprite:SetOverlayFrame("Head" .. headDirName, 1)
            end

            if data.IsAngry and effect.FrameCount%5 == 0 then
                for i=1, 2 do
                    if math.random(1,2) == 1 then
                        local steam = REVEL.SpawnDecoration(effect.Position + Vector(math.random(-15, 15), 0), effect.Velocity * 0.9, "Steam" .. math.random(1,3), "gfx/effects/revelcommon/steam.anm2", nil, 30)
                        steam.SpriteOffset = Vector(0,math.random(-35,-5))
                    end
                end
            end
        end
    end
end, REVEL.ENT.DANTE.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, dante, renderOffset)
    local data, danteSprite = dante:GetData(), dante:GetSprite()
    if data.CharonIncubus and data.Charon and data.Charon:GetData().FrozenSprite then
        local player = data.Charon
        local pdata = player:GetData()
        local isRenderPassNormal = REVEL.IsRenderPassNormal()
        if pdata.FrozenSprite and not pdata.FrozenSprite:IsFinished("Melt") and player:IsExtraAnimationFinished() then
            local headDir = player:GetData().IncubusDirection
            local headDirName
            if headDir == Direction.DOWN then
                headDirName = "Down"
            elseif headDir == Direction.UP then
                headDirName = "Up"
            elseif headDir == Direction.LEFT then
                headDirName = "Left"
            elseif headDir == Direction.RIGHT then
                headDirName = "Right"
            end

            if not pdata.FrozenSprite:IsPlaying("Melt") and not pdata.FrozenSprite:IsPlaying("Freeze")
            and isRenderPassNormal then
                local frame, previousAnim, playing = pdata.FrozenSprite:GetFrame()
                for _, anim in ipairs(freezeHeadAnimations) do
                    local playingAnimation = pdata.FrozenSprite:IsPlaying(anim)
                    if playingAnimation or pdata.FrozenSprite:IsFinished(anim) then
                        previousAnim = anim
                        playing = playingAnimation
                        break
                    end
                end

                local useFrame = 0
                if player:GetFireDirection() ~= Direction.NO_DIRECTION then
                    useFrame = 3
                end

                pdata.FrozenSprite:SetFrame("Head" .. headDirName, useFrame)
                pdata.FrozenSprite:Render(Isaac.WorldToScreen(dante.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)

                if not playing then
                    pdata.FrozenSprite:SetFrame(previousAnim, frame)
                else
                    pdata.FrozenSprite:Play(previousAnim, true)
                    if frame > 0 then
                        for i = 1, frame do
                            pdata.FrozenSprite:Update()
                        end
                    end
                end
            else
                pdata.FrozenSprite:Render(Isaac.WorldToScreen(dante.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
    end
end, REVEL.ENT.DANTE.variant)

---@param player EntityPlayer
---@param data table
---@param setIncubusDirection? Direction
function REVEL.Dante.Callbacks.Partner_PostUpdate(player, data, setIncubusDirection)
    if revel.data.run.dante.IsCombined then
        ---@type Entity
        local incubus = data.CharonIncubus
        if not incubus or not incubus:Exists() then
            incubus = Isaac.Spawn(
                EntityType.ENTITY_FAMILIAR, 
                FamiliarVariant.INCUBUS, 
                0, 
                data.CharonIncubusSpawnLocation or player.Position, 
                Vector.Zero, 
                player
            )
            incubus.Visible = false
            incubus:GetSprite():LoadGraphics()
            incubus:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            incubus:GetData().Charon = player
            data.CharonIncubus = incubus
            data.CharonIncubusSpawnLocation = nil
            
            -- Prevent shooting if just spawned, to avoid things
            -- like envy's enmity that have many cache evals
            -- from turning charon into a minigun
            incubus:GetData().ShootingCooldown = math.min(player.FireDelay * 2.25, player.MaxFireDelay)
        end

        if incubus then
            if not data.Dante or not data.Dante:Exists() then
                data.Dante = Isaac.Spawn(REVEL.ENT.DANTE.id, REVEL.ENT.DANTE.variant, 0, data.CharonIncubus.Position, Vector.Zero, player)
            end

            data.Dante:GetData().CharonIncubus = incubus
            data.Dante:GetData().Charon = player

            local fdata = incubus:GetData()
            if not data.IncubusDirection then
                data.IncubusDirection = player:GetFireDirection()
            end

            if setIncubusDirection then
                data.IncubusDirection = setIncubusDirection
                data.JustSwitched = true
            else
                data.AimBonus = data.AimBonus + 1
            end

            if data.IncubusDirection == Direction.NO_DIRECTION then
                data.IncubusDirection = 3
            end

            local angle = data.IncubusDirection * 90 - 180
            local plangle = player:GetFireDirection() * 90 - 180

            incubus:ToFamiliar():RemoveFromFollowers()
            incubus.Position = player.Position + Vector.FromAngle(angle) * 25
            fdata.CharonIncubusAngle = angle
            fdata.CharonIncubusChangeAngle = angle - plangle
            --fdata.ShouldShoot = data.IncubusDirection ~= player:GetFireDirection()
            fdata.ShouldShoot = true

            if fdata.ShootingCooldown then
                fdata.ShootingCooldown = fdata.ShootingCooldown - 1
                if fdata.ShootingCooldown <= 0 then
                    fdata.ShootingCooldown = nil
                else
                    fdata.ShouldShoot = false
                end
            end

            if data.IncubusDirection == player:GetFireDirection() then
                player.FireDelay = player.MaxFireDelay
                data.DisableBurningBush = true
            else
                data.DisableBurningBush = nil
            end

            if data.IncubusDirection ~= data.LastAimDirection and fdata.ShouldShoot then
                if player:GetFireDirection() ~= Direction.NO_DIRECTION then
                    if not data.NoShotYet then
                        if data.AimBonus >= 53 then
                            REVEL.sfx:Play(REVEL.SFX.CHARON_POWER_DOWN, 1, 0, false, 1)
                        else
                            REVEL.sfx:Play(REVEL.SFX.CHARON_LANTERN_SWITCH, 1, 0, false, 1)
                        end
                        data.AimBonus = 0
                    else
                        data.NoShotYet = nil
                    end
                end
            end

            if player:GetFireDirection() ~= Direction.NO_DIRECTION and fdata.ShouldShoot then
                data.LastAimDirection = data.IncubusDirection
                data.NoShotYet = nil
            end
        end
    end

    if data.Dante and not data.Dante:Exists() then
        data.Dante = nil
    end
end

function REVEL.Dante.Callbacks.Partner_PostNewLevel()
	shared.PreviouslyEnteredOtherCharRoom = false
	shared.SkippedOtherChar = false
end

---@param player EntityPlayer
function REVEL.Dante.Callbacks.Partner_PostNewRoom(player)
    if REVEL.Dante.IsMergeRoom() then
        local position = player.Position
        if revel.data.run.dante.OtherInventory and revel.data.run.dante.OtherInventory.position and revel.data.run.dante.OtherInventory.position.X then
            position = Vector(revel.data.run.dante.OtherInventory.position.X, revel.data.run.dante.OtherInventory.position.Y)
        end

        local data = player:GetData()
        data.Dante = Isaac.Spawn(REVEL.ENT.DANTE.id, REVEL.ENT.DANTE.variant, 0, position, Vector.Zero, nil)
        data.Dante:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        data.Dante:GetData().Charon = player

        shared.PreviouslyEnteredOtherCharRoom = true

    elseif shared.PreviouslyEnteredOtherCharRoom then
        shared.PreviouslyEnteredOtherCharRoom = false
        shared.SkippedOtherChar = true
    end

    local roomDesc = REVEL.level:GetRoomByIdx(REVEL.level:GetCurrentRoomIndex())
    if not revel.data.run.level.dante.RepFailsafe and roomDesc.Data.Subtype == 1 
    and StageAPI.GetCurrentListIndex() == revel.data.run.level.dante.StartingRoomIndex then
        if REVEL.level:GetStage() == LevelStage.STAGE1_2 and REVEL.level:GetStageType() > 3 then
            --white fire
            local pos = REVEL.room:FindFreeTilePosition(REVEL.room:GetGridPosition(1), 30)
            Isaac.Spawn(EntityType.ENTITY_FIREPLACE, 4, 0, pos , Vector.Zero, nil)
        end
        if REVEL.level:GetStage() == LevelStage.STAGE2_2 and REVEL.level:GetStageType() > 3 then
            --mines button
            REVEL.room:SpawnGridEntity(16, GridEntityType.GRID_PRESSURE_PLATE, 3, REVEL.level:GetCurrentRoomDesc().SpawnSeed, 0)
        end
        revel.data.run.level.dante.RepFailsafe = true
    end
end

-- Check if incubus check works for non tears
revel:AddCallback(ModCallbacks.MC_POST_LASER_RENDER, function(_, laser)
    if laser.Parent and laser.Parent.Type == EntityType.ENTITY_FAMILIAR
    and REVEL.IsRenderPassNormal() 
    and laser.Parent.Variant == FamiliarVariant.INCUBUS 
    and not laser:GetData().CharonIncubusModify 
    and laser.Parent:GetData().CharonIncubusAngle 
    and laser:IsCircleLaser() then
        if not laser.Parent:GetData().ShouldShoot then
            laser:Remove()
        else
            laser:GetData().CharonIncubusModify = true
            local player = laser.Parent:GetData().Charon
            local fireDir = player:GetFireDirection()
            local movementInheritance = player:GetTearMovementInheritance(laser.Velocity)
            local relativePosition = laser.Position - laser.Parent.Position
            laser.Velocity = laser.Velocity - movementInheritance
            laser.Position = laser.Parent.Position + relativePosition:Rotated(laser.Parent:GetData().CharonIncubusChangeAngle)
            laser.Velocity = laser.Velocity:Length() * Vector.FromAngle(laser.Parent:GetData().CharonIncubusChangeAngle + 90)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, laser)
    if laser.Parent and laser.Parent.Type == EntityType.ENTITY_FAMILIAR and laser.Parent.Variant == FamiliarVariant.INCUBUS and not laser:GetData().CharonIncubusModify and laser.Parent:GetData().CharonIncubusAngle and not laser:IsCircleLaser() then
        if not laser.Parent:GetData().ShouldShoot then
            laser:Remove()
        else
            laser:GetData().CharonIncubusModify = true
            laser.AngleDegrees = laser.Parent:GetData().CharonIncubusChangeAngle + laser.AngleDegrees
            laser.FirstUpdate = true
            local posDifference = laser.Position - laser.Parent.Position
            laser.Position = laser.Parent.Position + posDifference:Rotated(laser.Parent:GetData().CharonIncubusChangeAngle)
            laser.EndPoint = EntityLaser.CalculateEndPoint(laser.Position, Vector.FromAngle(laser.Angle), laser.ParentOffset, laser.Parent, laser.Size)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, function(_, tear)
    if REVEL.IsRenderPassNormal()
    and REVEL.IncludesIncubusTear(tear) and not tear:GetData().CharonIncubusModify 
    and not tear:GetData().oarTear 
    and tear.Parent:GetData().CharonIncubusAngle then
        if not tear.Parent:GetData().ShouldShoot then
            tear:Remove()
        else
            tear:GetData().CharonIncubusModify = true
            local player = tear.Parent:GetData().Charon
            local fireDir = player:GetFireDirection()
            local movementInheritance = player:GetTearMovementInheritance(tear.Velocity)
            local relativePosition = tear.Position - tear.Parent.Position
            tear.Velocity = tear.Velocity - movementInheritance
            tear.Position = tear.Parent.Position + relativePosition:Rotated(tear.Parent:GetData().CharonIncubusChangeAngle)
            tear.Velocity = tear.Velocity:Rotated(tear.Parent:GetData().CharonIncubusChangeAngle)
            local buffCount, extraTears, knockbackMulti, damagePercent = REVEL.Dante.CalculateBuff(player:ToPlayer())
            REVEL.CharonsOarConvertTear(tear, player, knockbackMulti, extraTears, buffCount, damagePercent)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, function(_, bomb)
    if REVEL.IsRenderPassNormal()
    and bomb.Parent and bomb.Parent.Type == EntityType.ENTITY_FAMILIAR and bomb.Parent.Variant == FamiliarVariant.INCUBUS 
    and not bomb:GetData().CharonIncubusModify 
    and bomb.Parent:GetData().CharonIncubusAngle then
        if not bomb.Parent:GetData().ShouldShoot then
            bomb:Remove()
        else
            bomb:GetData().CharonIncubusModify = true
            local player = bomb.Parent:GetData().Charon
            local fireDir = player:GetFireDirection()
            local movementInheritance = player:GetTearMovementInheritance(bomb.Velocity)
            local relativePosition = bomb.Position - bomb.Parent.Position
            bomb.Velocity = bomb.Velocity - movementInheritance
            bomb.Position = bomb.Parent.Position + relativePosition:Rotated(bomb.Parent:GetData().CharonIncubusChangeAngle)
            bomb.Velocity = bomb.Velocity:Rotated(bomb.Parent:GetData().CharonIncubusChangeAngle)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, knife)
    if knife.Parent and knife.Parent.Type == EntityType.ENTITY_FAMILIAR and knife.Parent.Variant == FamiliarVariant.INCUBUS and knife.Parent:GetData().CharonIncubusAngle and knife.IsFlying then
        if not knife.Parent:GetData().ShouldShoot then
            knife:Reset()
        else
            knife.Rotation = knife.Parent:GetData().CharonIncubusAngle
        end
    end
end)


end