local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local shared            = require("lua.revelcommon.dante.shared")

return function()

function REVEL.Dante.IsMergeRoom()
    return REVEL.level:GetRoomByIdx(REVEL.level:GetCurrentRoomIndex()).ListIndex == REVEL.level:GetRoomByIdx(revel.data.run.dante.OtherRoom).ListIndex 
        or REVEL.room:GetType() == RoomType.ROOM_BOSS
end

local RoomEnemyClearBlacklist = {
    [EntityType.ENTITY_DARK_ESAU] = true,
    [EntityType.ENTITY_MOTHERS_SHADOW] = true
}

local function ClearRoomEnemies()    
    for _, ent in ipairs(REVEL.roomEnemies) do
        if not RoomEnemyClearBlacklist[ent.Type] then
            local persistentData = StageAPI.CheckPersistence(ent.Type, ent.Variant, ent.SubType)
            if (ent and (not persistentData or not persistentData.AutoPersists)) 
            and not (ent:HasEntityFlags(EntityFlag.FLAG_CHARM) 
                or ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
                or ent:HasEntityFlags(EntityFlag.FLAG_PERSISTENT)
            ) then
                ent:Remove()
            end
        end
    end
end

-- Clear charon starting room
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) then
        local isGreed = REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER

        REVEL.Dante.Callbacks.Greed_PostNewLevel(isGreed)

        REVEL.Dante.Reset(player, isGreed, isGreed)
        if (REVEL.level:GetStage() == LevelStage.STAGE4_3 
        or REVEL.level:GetStage() == LevelStage.STAGE8)
        and not isGreed
        then
            REVEL.Dante.Merge(player, isGreed)
        end

        REVEL.Dante.Callbacks.Partner_PostNewLevel()
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) then
		if not revel.data.run.dante.IsCombined then
            local idx = StageAPI.GetCurrentListIndex()

            -- Without this, doors start closed then get opened
            if idx == revel.data.run.level.dante.StartingRoomIndex
            and REVEL.room:IsFirstVisit() then
                REVEL.DebugStringMinor("Dante | Charon starting room first visit, opening...")
                REVEL.OpenDoors(true)

                -- Room is already cleared by loading a stageapi empty layout
                -- in separate_chars.lua; set it to clear immediately to avoid
                -- the event triggering after the active item is discharged in
                -- phylactery.lua
                REVEL.room:SetClear(true)
                REVEL.DelayFunction(REVEL.room.SetClear, 0, {REVEL.room, true})
            end

			if shared.PlayerControlsDisabled then
				player.Visible = true
				shared.PlayerControlsDisabled = false
			end

            REVEL.Dante.Callbacks.Partner_PostNewRoom(player)
            REVEL.Dante.Callbacks.Map_PostNewRoom()
		end
    end
end)

-- Stat and familiar handling
revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amountPhylactery = 0
        if REVEL.IsDanteCharon(player) then
            amountPhylactery = 1
        end

        player:CheckFamiliar(REVEL.ENT.PHYLACTERY.variant, amountPhylactery, RNG())
    end

    if REVEL.IsDanteCharon(player) then
        if not revel.data.run.dante.IsDante or revel.data.run.dante.IsCombined then
            if flag == CacheFlag.CACHE_FIREDELAY then
                player.MaxFireDelay = math.floor(player.MaxFireDelay * 1.8)
            elseif flag == CacheFlag.CACHE_RANGE then
                player.TearRange = player.TearRange / 0.75
            end

            if not revel.data.run.dante.IsCombined and flag == CacheFlag.CACHE_SHOTSPEED then
                local buffCount = REVEL.Dante.GetBuffCount(player)
                if buffCount == 0 then
                    player.ShotSpeed = player.ShotSpeed * 0.6
                elseif buffCount == 1 then
                    player.ShotSpeed = player.ShotSpeed * 0.8
                else
                    player.ShotSpeed = player.ShotSpeed * 1.2
                end
            end
        else
            if flag == CacheFlag.CACHE_DAMAGE then
                player.Damage = player.Damage * 0.7
            elseif flag == CacheFlag.CACHE_FIREDELAY then
                player.MaxFireDelay = math.floor(player.MaxFireDelay * 0.8)
            end
        end

        if flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + 0.2
        elseif flag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange / 0.7
        end
    end
end)


local charonOnlyLockEnteringRoomTypes = {
    RoomType.ROOM_BOSS,
    RoomType.ROOM_CURSE,
    RoomType.ROOM_DEFAULT,
    RoomType.ROOM_CHALLENGE,
    RoomType.ROOM_MINIBOSS
}

local charonOnlyLockInsideRoomTypes = {
    RoomType.ROOM_BOSS,
    RoomType.ROOM_DEFAULT,
    RoomType.ROOM_CHALLENGE,
    RoomType.ROOM_MINIBOSS
}

local doorChainEntities = {}
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    doorChainEntities = {}
end)

local function addRandomRevelActive(player)
	local revelActives = REVEL.filter(REVEL.ITEM, function(item)
		if item.exclusive or item.trinket then return false end

		if REVEL.config:GetCollectible(item.id).Type ~= ItemType.ITEM_ACTIVE then return false end

		if REVEL.ShouldRerollItem(item.id) then return false end

		if player:HasCollectible(item.id) then return false end

		return true
	end)

	local itemID = revelActives[math.random(1, #revelActives)].id
	player:AddCollectible(itemID, REVEL.config:GetCollectible(itemID).MaxCharges, true)
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) then
        local data = player:GetData()
        local isGreed = REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER

        if player:GetMaxHearts() > 2 and not revel.data.run.dante.RedHeartPrioritySet and not revel.data.run.dante.IsCombined then
            revel.data.run.dante.RedHeartPrioritizeDante = revel.data.run.dante.IsDante
            revel.data.run.dante.RedHeartPrioritySet = true
        end

        REVEL.Dante.Callbacks.Phylactery_PostUpdate(player, data)

        local setIncubusDirection = REVEL.Dante.GetPartnerSwitchingDirection()

        data.WasDanteCharon = true

        if not revel.data.run.dante.IsCombined then
            if not isGreed then
                local isPhylacteryCharged = (
                        REVEL.Dante.GetPhylactery(player) == REVEL.ITEM.PHYLACTERY.id 
                        and not REVEL.Dante.IsPhylacteryCharged(player)
                    ) or shared.PhylacterySwitch

                for i = 0, 7 do
                    local door = REVEL.room:GetDoor(i)
                    if door and door:IsOpen() then
                        local isLocked = door.TargetRoomType == RoomType.ROOM_BOSS
                        if not isLocked and isPhylacteryCharged 
                        and REVEL.includes(charonOnlyLockInsideRoomTypes, door.CurrentRoomType) 
                        then
                            for _, rt in ipairs(charonOnlyLockEnteringRoomTypes) do
                                if door.TargetRoomType == rt then
                                    isLocked = true
                                end
                            end
                        end

                        if isLocked then
                            door:Close()
                            if not doorChainEntities[i] then
                                doorChainEntities[i] = REVEL.ENT.CHARON_DOOR_CHAINS:spawn(REVEL.room:GetDoorSlotPosition(i), Vector.Zero, nil)
                                doorChainEntities[i]:GetSprite().Rotation = door:GetSprite().Rotation
                                doorChainEntities[i]:GetSprite().Offset = Vector(0, 15):Rotated(door:GetSprite().Rotation)
                                -- Hack to disable reflections for entity, see POST_EFFECT_RENDER below
                                doorChainEntities[i].Color = REVEL.NO_COLOR
                                REVEL.SpawnLightAtEnt(doorChainEntities[i], Color(0, 0.5, 1, 1,conv255ToFloat( 0, 80, 255)), 1)
                            end
                        end
                    end
                end
            end

            if not revel.data.run.dante.IsDante then
                if player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG) then
                    player:RemoveCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG)
                end
            end

            for item, _ in pairs(REVEL.CharonFullBan) do
                if item ~= CollectibleType.COLLECTIBLE_SCHOOLBAG and player:HasCollectible(item, true) then
                    player:RemoveCollectible(item, true)
                end
            end

            if data.CharonIncubus then
                if data.CharonIncubus:Exists() then
                    data.CharonIncubus:Remove()
                end

                data.CharonIncubus = nil
            end
        else
            if player.FireDelay <= player.MaxFireDelay and player.FireDelay >= (player.MaxFireDelay - 1) then
                player.FireDelay = math.floor((player.MaxFireDelay / 1.8) * 0.8)
            end
        end

        REVEL.Dante.Callbacks.Partner_PostUpdate(player, data, setIncubusDirection)
        REVEL.Dante.Callbacks.DanteBook_PostUpdate(player, data)

        for slot, doorChainEntity in pairs(doorChainEntities) do
            if not doorChainEntity:Exists() then
                doorChainEntities[slot] = nil
            end

            local sprite = doorChainEntity:GetSprite()
            if sprite:IsFinished("Appear") then
                sprite:Play("Idle", true)
            end

            local door = REVEL.room:GetDoor(slot)
            if not door then
                doorChainEntity:Remove()
                doorChainEntities[slot] = nil
            elseif door:IsOpen() and not (sprite:IsPlaying("Vanish") or sprite:IsFinished("Vanish")) then
                sprite:Play("Vanish", true)
            elseif not door:IsOpen() and not (sprite:IsPlaying("Appear") or sprite:IsPlaying("Idle")) then
                sprite:Play("Appear", true)
            end
        end

        REVEL.Dante.Callbacks.Map_PostUpdate(player)
    elseif player:GetData().WasDanteCharon then
        player:GetData().WasDanteCharon = nil
        if not revel.data.run.dante.IsCombined then
            REVEL.Dante.Merge(player, false)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY.id)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id)
        end

        if not player:HasCollectible(REVEL.ITEM.CHARONS_OAR.id) then
            player:TryRemoveNullCostume(REVEL.COSTUME.BROKEN_OAR)
        end

        player:TryRemoveNullCostume(REVEL.COSTUME.CHARON_HAIR)
        player:TryRemoveNullCostume(REVEL.COSTUME.DANTE)
        player:TryRemoveNullCostume(REVEL.COSTUME.DANTE_HAIR)

        revel.data.run.dante.OtherRoom = -1
        revel.data.run.dante.OtherInventory = {
            hearts = REVEL.Dante.GetDefaultHealth(),
            secondActive = {
                id = -1,
                charge = -1
            },
            position = {X = false, Y = false},
            items = {},
            spriteScale = {X = 1, Y = 1},
            sizeMulti = {X = 1, Y = 1},
            trinket = -1,
            card = -1,
            pill = -1
        }
        revel.data.run.dante.IsCombined = false
        revel.data.run.dante.IsDante = false
        revel.data.run.dante.IsInitialized = false
        revel.data.run.dante.FirstMerge = false
	else
        if player:HasCollectible(REVEL.ITEM.PHYLACTERY.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY.id)
			addRandomRevelActive(player)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_MERGED.id)
			addRandomRevelActive(player)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id)
			addRandomRevelActive(player)
        end

        if player:HasCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id) then
            player:RemoveCollectible(REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id)
			addRandomRevelActive(player)
        end
    end

	if REVEL.HasBrokenOarEffect(player) then
		for item, _ in pairs(REVEL.OarFullBan) do
			if player:HasCollectible(item) then
				player:RemoveCollectible(item)
			end
		end
	end
end)


-- Hack to disable reflections for door chains
-- since .Visible = false would not allow POST_EFFECT_RENDER
-- to work, to allow not rendering chains when its the reflection pass
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect, renderOffset)
    if REVEL.IsRenderPassNormal() then
        effect.Color = Color.Default
        local pos = Isaac.WorldToScreen(effect.Position)
        effect:GetSprite():Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset())
        effect.Color = REVEL.NO_COLOR
    end
end, REVEL.ENT.CHARON_DOOR_CHAINS.variant)


end