local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local shared            = require("lua.revelcommon.dante.shared")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local PhylacterySwitch
local PhylacteryAddCharge
local PhylacteryTransferring
local PhylacteryTransferringPosition

function REVEL.Dante.GetPhylactery(player)
    if REVEL.PHYLACTERY_POCKET then
        return player:GetActiveItem(ActiveSlot.SLOT_POCKET)
    else
        return player:GetActiveItem()
    end
end

function REVEL.Dante.SetPhylactery(player, item)
    if REVEL.PHYLACTERY_POCKET then
        player:SetPocketActiveItem(item, ActiveSlot.SLOT_POCKET, false)
        player:DischargeActiveItem(ActiveSlot.SLOT_POCKET)
    else
        player:AddCollectible(item, 0, false)
    end
end

function REVEL.Dante.IsPhylacteryCharged(player)
    local isPhylacteryCharged = false
    local phylactery = REVEL.config:GetCollectible(REVEL.ITEM.PHYLACTERY.id)

    if REVEL.PHYLACTERY_POCKET then
        isPhylacteryCharged = player:NeedsCharge(ActiveSlot.SLOT_POCKET)
    else
        isPhylacteryCharged = player:NeedsCharge()

        if not isPhylacteryCharged and player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == REVEL.ITEM.PHYLACTERY.id then
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then
                isPhylacteryCharged = player:GetActiveCharge(ActiveSlot.SLOT_SECONDARY) + player:GetBatteryCharge(ActiveSlot.SLOT_SECONDARY) == phylactery.MaxCharges * 2
            else
                isPhylacteryCharged = player:GetActiveCharge(ActiveSlot.SLOT_SECONDARY) == phylactery.MaxCharges
            end
        end
    end

    return isPhylacteryCharged
end

function REVEL.Dante.GetPhylacteryActiveSlot()
    return REVEL.PHYLACTERY_POCKET and ActiveSlot.SLOT_POCKET or ActiveSlot.SLOT_PRIMARY
end

function REVEL.Dante.GetPhylacteryCharge(player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then
        return player:GetActiveCharge(REVEL.Dante.GetPhylacteryActiveSlot()) + player:GetBatteryCharge(REVEL.Dante.GetPhylacteryActiveSlot())
    else
        return player:GetActiveCharge(REVEL.Dante.GetPhylacteryActiveSlot())
    end
end

function REVEL.Dante.SlotHasCardOrPill(player, slot)
    return player:GetCard(slot) > 0 or player:GetPill(slot) > 0
end

function REVEL.Dante.GetPocketActiveSlot(player)
    if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
        return -1
    end

    local i = 0
    while REVEL.Dante.SlotHasCardOrPill(player, i) do
        i = i + 1
    end
    return i
end


function REVEL.SetCurrentPocketToActive(player)
    local pocketActiveSlot = REVEL.Dante.GetPocketActiveSlot(player)
    if pocketActiveSlot > 0 then
        REVEL.ForceInput(player, ButtonAction.ACTION_DROP, true)
        REVEL.DelayFunction(1, function() REVEL.SetCurrentPocketToActive(player) end)
    end
end



revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    fam:AddToFollowers()
end, REVEL.ENT.PHYLACTERY.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    local phils = REVEL.ENT.PHYLACTERY:getInRoom()
    for _, phil in pairs(phils) do
        phil:GetData().Light = REVEL.SpawnLightAtEnt(phil, Color(0, 0.5, 1, 1,conv255ToFloat( 0, 80, 255)), 1, Vector(0, -15))
        phil:GetData().LightSize = 1
        phil:GetData().LightSizeStart = 1
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local data = fam:GetData()
    if not data.AbsorbingItem then
        fam:FollowParent()
    else
        fam.Velocity = fam.Velocity * 0.8
    end

    if data.Light then
        data.LightSize = math.max(data.LightSizeStart, data.LightSize * 0.95)
        REVEL.ScaleEntity(data.Light, {SpriteScale = Vector.One * data.LightSize})
    end

    local sprite = fam:GetSprite()
    if not sprite:IsPlaying("Absorb") and not sprite:IsPlaying("NearItem") and not sprite:IsPlaying("Idle") then
        sprite:Play("Idle", true)
    end
end, REVEL.ENT.PHYLACTERY.variant)

local phylacteryGlow = REVEL.LazyLoadRunSprite{
    ID = "phylacteryGlow",
    Anm2 = "gfx/itemeffects/revelcommon/phylactery_glow.anm2",
    Animation = "Idle",
    Offset = Vector(0, -20),
}
local phylacteryGlowStartScale = Vector(0.1, 0.2)
local phylacteryGlowMaxScale = Vector(0.15, 0.2)
revel:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, function(_, fam, renderOffset)
    local player = fam.Player

    if player:GetData().LastAimDirection and player:GetData().LastAimDirection > -1 
    and not player:GetData().NoShotYet 
    and (not revel.data.run.dante.IsDante or revel.data.run.dante.IsCombined) then
        local bonus = player:GetData().AimBonus or 0
        if bonus > 0 then
            local alpha
            if bonus < 225 then
                alpha = REVEL.Lerp(0.4, 0.8, bonus / 225)
            else
                alpha = 0.8
            end

            phylacteryGlow.Color = Color(1, 1, 1, alpha,conv255ToFloat( 0, 0, 0))
            phylacteryGlow.Scale = REVEL.Lerp(phylacteryGlowStartScale, phylacteryGlowMaxScale, math.min(bonus, 225) / 225)
            phylacteryGlow.Rotation = player:GetData().LastAimDirection * 90 - 270
            phylacteryGlow:Render(Isaac.WorldToScreen(fam.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end
    end
end, REVEL.ENT.PHYLACTERY.variant)

local absorbingItems = {}
local absorbingAccelFrames = 45
local absorbingDelayFrames = 10
local absorbingTargetOffset = Vector(0, -16)

function REVEL.Dante.AddAbsorbingItem(familiar, itemGfx, position)
    local addIndex
    local use
    for _, item in ipairs(absorbingItems) do
        if not item.InUse then
            use = item
        end
    end

    if not use then
        local sprite = Sprite()
        sprite:Load("gfx/005.100_collectible.anm2", false)
        use = {Sprite = sprite}
        addIndex = #absorbingItems + 1
    end

    use.InUse = true
    use.Position = position
    use.Velocity = Vector.Zero
    use.Sprite:ReplaceSpritesheet(1, itemGfx)
    use.Sprite:LoadGraphics()
    use.Sprite:Play("PlayerPickup", true)
    use.Familiar = familiar
    use.FrameCount = 0

    if addIndex then
        absorbingItems[addIndex] = use
    end
end

revel:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, function(_, fam)
    if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal() then
        local data = fam:GetData()
        data.AbsorbingItem = nil
        for i, item in ripairs(absorbingItems) do
            if item.InUse and GetPtrHash(item.Familiar) == GetPtrHash(fam) then
                data.AbsorbingItem = true
                local accel = math.min(30, math.max(0, item.FrameCount - absorbingDelayFrames)) / absorbingAccelFrames

                local renderPos = Isaac.WorldToScreen(item.Position)
                item.Sprite:Render(renderPos, Vector.Zero, Vector.Zero)

                local targPos = fam.Position + absorbingTargetOffset

                if item.Position:DistanceSquared(targPos) < 16 * 16 then
                    item.Position = targPos

                    local sprite = fam:GetSprite()
                    if not sprite:IsPlaying("Absorb") then
                        sprite:Play("Absorb", true)
                    end

                    if sprite:IsEventTriggered("Close") then
                        item.InUse = false
                        if data.Light then
                            data.LightSize = 4
                        end
                    end
                else
                    item.Velocity = REVEL.Lerp(Vector.Zero, (targPos - item.Position):Resized(7), accel)
                    item.Position = item.Position + item.Velocity
                end

                item.FrameCount = item.FrameCount + 1
            end
        end
    end
end, REVEL.ENT.PHYLACTERY.variant)

function REVEL.Dante.PhylacteryRoomSwitch()
    local curRoom = REVEL.level:GetCurrentRoomIndex()
    if revel.data.run.dante.OtherRoom >= 0 and curRoom >= 0 then
        REVEL.DebugStringMinor("Dante | Doing switch...")
        local player = REVEL.player

        local newX, newY = StageAPI.GridToVector(revel.data.run.dante.OtherRoom, 13)
        local oldX, oldY = StageAPI.GridToVector(curRoom, 13)
        local direction = Direction.NO_DIRECTION
        if math.abs(oldX - newX) > math.abs(oldY - newY) then
            if newX > oldX then
                direction = Direction.RIGHT
            else
                direction = Direction.LEFT
            end
        else
            if newY > oldY then
                direction = Direction.DOWN
            else
                direction = Direction.UP
            end
        end

        if revel.data.run.dante.OtherInventory.position.X then
            PhylacteryTransferringPosition = Vector(revel.data.run.dante.OtherInventory.position.X, revel.data.run.dante.OtherInventory.position.Y)
        else
            PhylacteryTransferringPosition = nil
        end

        revel.data.run.dante.OtherInventory.position = {X = player.Position.X, Y = player.Position.Y}

        REVEL.room:Update()

        REVEL.SafeRoomTransition(revel.data.run.dante.OtherRoom, false, direction, RoomTransitionAnim.FORGOTTEN_TELEPORT)

        revel.data.run.dante.OtherRoom = curRoom

        PhylacteryTransferring = true
    end
end

---@param player EntityPlayer
---@param data table
function REVEL.Dante.Callbacks.Phylactery_PostUpdate(player, data)
    local checkId = REVEL.ITEM.PHYLACTERY.id
    local isGreed = REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER
    if revel.data.run.dante.IsCombined or isGreed then
        checkId = REVEL.ITEM.PHYLACTERY_MERGED.id
    end

    if not player:HasCollectible(checkId) 
    and not player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id) 
    and not player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id) then
        local phylacteries = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, checkId, false, false)
        for _, phylactery in ipairs(phylacteries) do
            phylactery:Remove()
        end

        player:AddCollectible(checkId, 999, false)
    end

    if PhylacterySwitch then
        REVEL.Dante.PhylacteryRoomSwitch()
        player:DischargeActiveItem(REVEL.Dante.GetPhylacteryActiveSlot())
        PhylacterySwitch = nil
    end

    if PhylacteryAddCharge then
        player:FullCharge(REVEL.Dante.GetPhylacteryActiveSlot())
        PhylacteryAddCharge = nil
    end

    if not revel.data.run.dante.IsDante and not revel.data.run.dante.IsCombined then
        local aimdirection = player:GetFireDirection()
        if data.LastAimDirection then
            data.AimBonus = data.AimBonus + 1
        end

        if aimdirection ~= Direction.NO_DIRECTION then
            if data.LastAimDirection ~= aimdirection then
                if not data.NoShotYet then
                    if data.AimBonus >= 53 then
                        REVEL.sfx:Play(REVEL.SFX.CHARON_POWER_DOWN, 1, 0, false, 1)
                    else
                        REVEL.sfx:Play(REVEL.SFX.CHARON_LANTERN_SWITCH, 1, 0, false, 1)
                    end
                    data.AimBonus = 0
                end

                data.LastAimDirection = aimdirection
            end

            local buffCount = REVEL.Dante.GetBuffCount(player)
            if data.LastCharonBuff ~= buffCount then
                data.LastCharonBuff = buffCount
                player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
                player:EvaluateItems()
            end

            data.NoShotYet = nil
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 15, function()
    local player = REVEL.player

    if not revel.data.run.dante.IsDante or revel.data.run.dante.IsCombined then
        player:GetData().NoShotYet = true
        player:GetData().AimBonus = 1000
    end

    if revel.data.run.dante.IsCombined and revel.data.charonAutoFace == 1 then
        REVEL.Dante.SwitchPartnerDirection(player:GetHeadDirection())
    end

    if PhylacteryTransferring then
        REVEL.DebugStringMinor("Dante | New room after switch, switching map & inventory and discharging item...")

        REVEL.Dante.InventorySwitch(player)
        player:DischargeActiveItem(REVEL.Dante.GetPhylacteryActiveSlot())
        REVEL.Dante.SwitchMap()

        if PhylacteryTransferringPosition then
            for _, player in ipairs(REVEL.players) do
                player.Position = PhylacteryTransferringPosition
            end
            PhylacteryTransferringPosition = nil
        end
        PhylacteryTransferring = nil
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player)
    if not PhylacteryAddCharge and not PhylacterySwitch then
        local isGivingItem = (REVEL.IsDanteCharon(player) and player:IsHoldingItem() and player.QueuedItem)
        if not revel.data.run.dante.IsCombined and not isGivingItem then
            if not REVEL.room:IsAmbushActive() then
                PhylacterySwitch = true
                return true
            else
                REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75)
                return {Discharge = false, ShowAnim = false}
            end
        elseif isGivingItem then
            PhylacteryAddCharge = true
        end
    end
end, REVEL.ITEM.PHYLACTERY.id)

function REVEL.Dante.GetMovingCharacterDirection(player)
    if revel.data.charonMode == 0 then
        return player:GetFireDirection()
    else
        return player:GetMovementDirection()
    end
end

local phylacteryIncubusSwitching = nil
revel:AddCallback(ModCallbacks.MC_USE_ITEM, function()
    local player = REVEL.player
    if not phylacteryIncubusSwitching then
        local isGivingItem = (REVEL.IsDanteCharon(player) and player:IsHoldingItem() and player.QueuedItem)
        if not isGivingItem then
            local changeDir = REVEL.Dante.GetMovingCharacterDirection(player)
            if changeDir ~= Direction.NO_DIRECTION then
                if changeDir ~= player:GetData().IncubusDirection then
                    phylacteryIncubusSwitching = changeDir
                end
            else
                phylacteryIncubusSwitching = true
                player:AnimateCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id, "LiftItem", "PlayerPickup")
            end
        end
    else
        phylacteryIncubusSwitching = nil
        player:AnimateCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id, "HideItem", "PlayerPickup")
    end
end, REVEL.ITEM.PHYLACTERY_MERGED.id)

function REVEL.Dante.SwitchPartnerDirection(dir)
    phylacteryIncubusSwitching = dir
end

function REVEL.Dante.GetPartnerSwitchingDirection()
    local setIncubusDirection
    if phylacteryIncubusSwitching then
        if type(phylacteryIncubusSwitching) ~= "boolean" then
            setIncubusDirection = phylacteryIncubusSwitching
            phylacteryIncubusSwitching = nil
        else
            local player = REVEL.player
            local changeDir = REVEL.Dante.GetMovingCharacterDirection(player)
            if changeDir ~= Direction.NO_DIRECTION and changeDir ~= player:GetData().IncubusDirection then
                setIncubusDirection = changeDir
                player:AnimateCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id, "HideItem", "PlayerPickup")
                phylacteryIncubusSwitching = nil
            end
        end
    end
    return setIncubusDirection
end

local phylacteryHudSprite = REVEL.LazyLoadRunSprite{
    ID = "phylacteryHudSprite",
    Anm2 = "gfx/items/collectibles/revelcommon/phylactery_absorb.anm2",
    Animation = "Idle",
}

--Since the item doesn't actually have a ingame sprite, gotta render the outline manually
local phylacterHudOutline = REVEL.LazyLoadRunSprite{
    ID = "phylacterHudOutline",
    Anm2 = "gfx/items/collectibles/revelcommon/phylactery_absorb.anm2",
    Animation = "Outline",
    Color = REVEL.YELLOW_OUTLINE_COLOR,
}

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    local player = REVEL.player
	local data = player:GetData()
	local active = REVEL.Dante.GetPhylactery(player)
	local isActivePhylacteryPickup = active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id or active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id
	if not REVEL.game:IsPaused() then
		if REVEL.IsDanteCharon(player) then
            if Isaac.GetFrameCount() % 2 == 0 then
                phylacteryHudSprite:Update()
                if phylacteryHudSprite:IsFinished("NearItem") then
                    phylacteryHudSprite:Play("Idle")
                end
            end
                
			if not revel.data.run.dante.IsCombined then
				REVEL.Dante.CapHealth(player, 6)
			end

			local isHoldingItem = player:IsHoldingItem() and player.QueuedItem and player.QueuedItem.Item 
                and REVEL.Dante.IsInventoryManagedItem(nil, player.QueuedItem.Item)

			if (active == REVEL.ITEM.PHYLACTERY.id or active == REVEL.ITEM.PHYLACTERY_MERGED.id) and isHoldingItem then
				player:RemoveCollectible(active)
				local charge = player:GetActiveCharge(REVEL.Dante.GetPhylacteryActiveSlot()) + player:GetBatteryCharge(REVEL.Dante.GetPhylacteryActiveSlot())
				if active == REVEL.ITEM.PHYLACTERY.id then
                    REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id)
				else
                    REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id)
				end
                REVEL.SetCurrentPocketToActive(player) -- make sure player can use the phylactery switch in time by setting current pocket

                player:SetActiveCharge(charge, REVEL.Dante.GetPhylacteryActiveSlot())

				local phylactery = Isaac.FindByType(REVEL.ENT.PHYLACTERY.id, REVEL.ENT.PHYLACTERY.variant, -1, false, false)[1]
				phylactery:GetSprite():Play("NearItem", true)

                phylacteryHudSprite:Play("NearItem", true)

			elseif isActivePhylacteryPickup and not isHoldingItem then
				player:RemoveCollectible(active)
				local charge = player:GetActiveCharge(REVEL.Dante.GetPhylacteryActiveSlot()) + player:GetBatteryCharge(REVEL.Dante.GetPhylacteryActiveSlot())
				if revel.data.run.dante.IsCombined or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED 
                or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER then
                    REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY_MERGED.id)
				else
                    REVEL.Dante.SetPhylactery(player, REVEL.ITEM.PHYLACTERY.id)
				end
                player:SetActiveCharge(charge, REVEL.Dante.GetPhylacteryActiveSlot())
			end

            local action = REVEL.PHYLACTERY_POCKET and ButtonAction.ACTION_PILLCARD or ButtonAction.ACTION_ITEM

			if isHoldingItem and isActivePhylacteryPickup and Input.IsActionTriggered(action, player.ControllerIndex) then
				local item = player.QueuedItem.Item
				REVEL.Dante.AddCollectibleToOtherPlayer(player, true, item)
				player:PlayExtraAnimation("HideItem")

				local phylactery = Isaac.FindByType(REVEL.ENT.PHYLACTERY.id, REVEL.ENT.PHYLACTERY.variant, -1, false, false)[1]
				local phySprite = phylactery:GetSprite()
				if phySprite:IsPlaying("NearItem") then
					phySprite:Play("Idle", true)
				end

				phylacteryHudSprite:Play("Idle")
			end
		end
	end

	if isActivePhylacteryPickup or data.LastActiveWasPhylacteryPickup then
		local pos = REVEL.GetScreenBottomRight() + Vector(-20, -14)
        local playerID = REVEL.GetPlayerID(player)

        -- wrong coop positions, cannot really test for right ones rn tho
		if playerID == 2 then
			pos = REVEL.GetScreenTopRight() + Vector(-126, 16)
		elseif playerID == 3 then
			pos = REVEL.GetScreenBottomLeft() + Vector(103, -16)
		elseif playerID == 4 then
			pos = REVEL.GetScreenBottomRight() + Vector(-150, -16)
		end

        phylacterHudOutline:Render(pos, Vector.Zero, Vector.Zero)

		phylacteryHudSprite:Render(pos, Vector.Zero, Vector.Zero)
	end

	data.LastActiveWasPhylacteryPickup = isActivePhylacteryPickup
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function()
    PhylacteryAddCharge = true
end, REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id)

revel:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    PhylacteryTransferring = nil
end)

end
REVEL.PcallWorkaroundBreakFunction()