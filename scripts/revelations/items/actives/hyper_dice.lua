local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
local PlayerVariant     = require("scripts.revelations.common.enums.PlayerVariant")

return function()

----------------
-- HYPER DICE --
----------------

REVEL.HyperDiceRerolling = false

local ShouldAddCharge
local SameRoomType = true
local SpawnItem
local SpawnItemCharged
local PlayerUsing
local SpawnItemPlayer
local SpawnItemPosition

revel:AddCallback(ModCallbacks.MC_POST_RENDER , function()
    if ShouldAddCharge then
        if REVEL.ITEM.HYPER_DICE:PlayerHasCollectible(ShouldAddCharge) then
            ShouldAddCharge:SetActiveCharge(12)
            REVEL.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE)
        end
        ShouldAddCharge = nil
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) and player.Variant == PlayerVariant.PLAYER then
        -- deal with butter
        if player:HasTrinket(TrinketType.TRINKET_BUTTER) then
            SpawnItem = itemID
            SpawnItemCharged = false
            REVEL.DelayFunction(function()
                SpawnItemPlayer = player

                local hyperDices = Isaac.FindByType(5, 100, itemID, false, false)
                local noChargeDices = {}
                if #hyperDices > 0 then
                    for i=1, #hyperDices do
                        if hyperDices[i]:ToPickup().Charge == 0 then
                            noChargeDices[#noChargeDices+1] = hyperDices[i]
                        end
                    end
                end

                if #noChargeDices > 0 then
                    local diceToRemove = REVEL.getClosestInTable(noChargeDices, player)
                    SpawnItemPosition = diceToRemove.Position
                    diceToRemove:Remove()
                else
                    local voids = Isaac.FindByType(5, 100, CollectibleType.COLLECTIBLE_VOID, false, false)
                    local noChargeVoids = {}
                    if #voids > 0 then
                        for i=1, #voids do
                            if voids[i]:ToPickup().Charge == 0 then
                                noChargeVoids[#noChargeVoids+1] = voids[i]
                            end
                        end
                    end

                    if #noChargeVoids > 0 then
                        local voidToRemove = REVEL.getClosestInTable(noChargeVoids, player)
                        SpawnItemPosition = voidToRemove.Position
                        voidToRemove:Remove()

                        SpawnItem = CollectibleType.COLLECTIBLE_VOID
                    end
                end
            end, 1, nil, true, false)
        end

        -- effect
        local room = REVEL.room
        if room:GetType() ~= RoomType.ROOM_DEFAULT 
        and not StageAPI.InOrTransitioningToExtraRoom() 
        and not revel.data.run.hyperDiceCorrupted then
            REVEL.game:ShakeScreen(30 + math.random(math.floor(revel.data.run.hyperDiceChance / 2), revel.data.run.hyperDiceChance))

            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                for i=1, 3 do
                    local dice = {
                        CollectibleType.COLLECTIBLE_D6,
                        CollectibleType.COLLECTIBLE_D7,
                        CollectibleType.COLLECTIBLE_D8,
                        CollectibleType.COLLECTIBLE_D10,
                        CollectibleType.COLLECTIBLE_D12,
                    }
                    player:AddWisp(dice[math.random(1,#dice)], player.Position)
                end
            end

            if math.random(1, 100) <= revel.data.run.hyperDiceChance * 4 then
                AddPixelation = math.random(math.floor(revel.data.run.hyperDiceChance / 2), revel.data.run.hyperDiceChance)
            end

            if math.random(1, 100) <= revel.data.run.hyperDiceChance * 4 then
                REVEL.game:Darken(math.random(math.floor(revel.data.run.hyperDiceChance / 2), revel.data.run.hyperDiceChance) / 100, math.random(math.floor(revel.data.run.hyperDiceChance / 2), revel.data.run.hyperDiceChance))
            end

            if math.random(1, 100) <= revel.data.run.hyperDiceChance * 2 then
                local consumables = {player:GetNumCoins(), player:GetNumBombs(), player:GetNumKeys()}

                player:AddCoins(-consumables[1])
                player:AddBombs(-consumables[2])
                player:AddKeys(-consumables[3])

                consumables = REVEL.Shuffle(consumables)
                for i, num in ipairs(consumables) do
                    if i == 1 then
                        player:AddCoins(num)
                    elseif i == 2 then
                        player:AddBombs(num)
                    else
                        player:AddKeys(num)
                    end
                end
            end

            if math.random(1, 100) <= revel.data.run.hyperDiceChance then
                revel.data.run.hyperDiceCorrupted = true

                REVEL.sfx:Play(REVEL.SFX.HYPER_DICE, 1, 0, false, 0.2)
                REVEL.AnimateGiantbook("gfx/ui/giantbook/giantbook_hyperdice_corrupt.png")

                local eff = math.random(1, 2)
                if eff == 1 then
                    Isaac.ExecuteCommand("goto s.error")
                else
                    player:UseActiveItem(CollectibleType.COLLECTIBLE_D4, false, true, true, false)
                end

                if player:HasCollectible(itemID) then
                    player:RemoveCollectible(itemID)
                end
            else
                REVEL.sfx:Play(REVEL.SFX.HYPER_DICE, 1, 0, false, 1 + (math.random(-revel.data.run.hyperDiceChance, revel.data.run.hyperDiceChance) * 0.01))
                if revel.data.run.hyperDiceChance < 1 then
                    revel.data.run.hyperDiceChance = 1
                else
                    revel.data.run.hyperDiceChance = revel.data.run.hyperDiceChance * 2
                end

                PlayerUsing = player

                -- play the giantbook effect
                REVEL.AnimateGiantbook("gfx/ui/giantbook/giantbook_hyperdice.png")
            end

            return true
        else
            if player:GetActiveItem() == REVEL.ITEM.HYPER_DICE.id or SpawnItem then
                ShouldAddCharge = player
                SpawnItemCharged = true
            end
            REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 1, 0, false, 1)
        end
    end
end, REVEL.ITEM.HYPER_DICE.id)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if AddPixelation then -- crashes if used in POST_RENDER
        REVEL.game:AddPixelation(AddPixelation)
        AddPixelation = nil
    end

    local playerMoved = false
    if PlayerUsing then
        local player = PlayerUsing

        -- creating the new room layout
        local seed = player:GetCollectibleRNG(REVEL.ITEM.HYPER_DICE.id):Next()
        if SameRoomType then
            StageAPI.SetRoomFromList(REVEL.RoomLists.SpecialRooms, REVEL.room:GetType(), true, false, true, seed)
        else
            REVEL.HyperDiceRerolling = true
            StageAPI.SetRoomFromList(REVEL.RoomLists.SpecialRooms, nil, true, false, true, seed)
            REVEL.HyperDiceRerolling = false
        end

        StageAPI.ReprocessRoomGrids()

        for i=1, REVEL.room:GetGridSize() do
            local grid = REVEL.room:GetGridEntity(i)
            if grid ~= nil then
                grid:PostInit()
            end
        end

        local roomID = StageAPI.GetCurrentRoomID()
        local items = REVEL.GetRoomNotablePickups()
        local shouldExist = #items - revel.data.run.level.notablePickupsTakenFromRoom[roomID]
        for i, item in ipairs(items) do
            if shouldExist < i then
                item:Remove()
            end
        end

        revel.data.run.level.notablePickupsInRoom[roomID] = shouldExist

        local lastPos = player.Position
        player.Position = REVEL.room:GetClampedPosition(REVEL.room:GetDoorSlotPosition(REVEL.level.EnterDoor), 16)
        if lastPos:Distance(player.Position) > 60 then
            playerMoved = true
        end

        PlayerUsing = nil
    end

    -- spawn item from butter
    if SpawnItemPlayer then
        local player = SpawnItemPlayer

        if SpawnItem then
            if not SpawnItemPosition or playerMoved then
                SpawnItemPosition = REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true)
            end
            
            local keeperBExists = false
            for _,player in ipairs(REVEL.players) do
                if player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
                    keeperBExists = true
                    break
                end
            end
            
            local spawnedItem
            if keeperBExists then
                spawnedItem = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, SpawnItem, SpawnItemPosition, Vector.Zero, player):ToPickup()
                spawnedItem.Price = 15
                spawnedItem.AutoUpdatePrice = true
            else
                spawnedItem = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, SpawnItem, SpawnItemPosition, Vector.Zero, player):ToPickup()
            end
            
            if not SpawnItemCharged or SpawnItem == CollectibleType.COLLECTIBLE_VOID then
                spawnedItem.Charge = 0
            end
        end

        SpawnItemPlayer = nil
        SpawnItem = nil
        SpawnItemCharged = false
        SpawnItemPosition = nil
    end
end)

local C_INT_MAX = 2147483647

local recusions = 0

-- Avoid getting hyper dice again if corrupted
revel:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, function(_, selectedCollectible, itemPoolType, decrease, seed)
    if revel.data.run.hyperDiceCorrupted 
    and selectedCollectible == REVEL.ITEM.HYPER_DICE.id
    and recusions < 15
    then
        recusions = recusions + 1
        local newItem = REVEL.pool:GetCollectible(itemPoolType, false, (seed * 50 + 195) % C_INT_MAX)
        recusions = recusions - 1

        return newItem
    end
end)

---@param player EntityPlayer
---@param playerID integer
---@param itemID CollectibleType
---@param isD4Effect boolean
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 0, function(player, playerID, itemID, isD4Effect)
    if revel.data.run.hyperDiceCorrupted then
        player:RemoveCollectible(itemID)
    end
end, REVEL.ITEM.HYPER_DICE.id)

end