REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


function REVEL.GetExtraItemSpawnPos(relocateExisting)
    local currentRoom = StageAPI.GetCurrentRoom()
    local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)
    local crates = Isaac.FindByType(REVEL.ENT.HUB_DECORATION.id, REVEL.ENT.HUB_DECORATION.variant, -1, false, false)
    for _, crate in ipairs(crates) do
        if crate:GetData().HubItemCrate then
            collectibles[#collectibles + 1] = crate
        end
    end

    if currentRoom then
        for _, metaEntity in ipairs(currentRoom.Metadata:Search{Name = "ExtraItemSpawn"}) do
            local index = metaEntity.Index

            local spotTaken
            for _, coll in ipairs(collectibles) do
                if REVEL.room:GetGridIndex(coll.Position) == index then
                    spotTaken = true
                    break
                end
            end

            if not spotTaken then
                --Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id or 0, REVEL.room:GetGridPosition(index), Vector.Zero, nil)
                return REVEL.room:GetGridPosition(index)
            end
        end
    end

    local centerPos = REVEL.room:GetCenterPos()
    local isCenterTaken = REVEL.room:GetGridCollisionAtPos(centerPos) ~= 0
    local collectibleAtCenter
    if not isCenterTaken then
        for _, collectible in ipairs(collectibles) do
            if collectible.Position:DistanceSquared(centerPos) < collectible.Size ^ 2 then
                isCenterTaken = true
                collectibleAtCenter = collectible
            end
        end
    end

    if not isCenterTaken then
        return centerPos --Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id or 0, centerPos, Vector.Zero, nil)
    else
        local off = Vector(-80, 0)
        local offStep = Vector(-40, 0)
        for i = 0, 9 do
            for sign = -1, 1, 2 do
                local offset = (off + offStep * i) * sign
                if REVEL.room:IsPositionInRoom(centerPos + offset, 0) and REVEL.room:GetGridCollisionAtPos(centerPos + offset) == 0 and (not collectibleAtCenter or (REVEL.room:IsPositionInRoom(centerPos - offset, 0) and REVEL.room:GetGridCollisionAtPos(centerPos - offset) == 0)) then
                    --Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id or 0, centerPos + offset, Vector.Zero, nil)
                    local isValid = true
                    for _, coll in ipairs(collectibles) do
                        if coll.Position:DistanceSquared(centerPos + offset) < coll.Size ^ 2 or (relocateExisting and collectibleAtCenter and coll.Position:DistanceSquared(centerPos - offset) < coll.Size ^ 2) then
                            isValid = false
                            break
                        end
                    end

                    if isValid then
                        if relocateExisting and collectibleAtCenter then
                            collectibleAtCenter.Position = centerPos - offset
                        end

                        return centerPos + offset
                    end
                end
            end
        end
    end
end

function REVEL.AddItemToRoom(id)
    local pos = REVEL.GetExtraItemSpawnPos(true)
    if pos then
        local keeperBExists = false
        for _,player in ipairs(REVEL.players) do
            if player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
                keeperBExists = true
                break
            end
        end

        local roomDesc = REVEL.level:GetCurrentRoomDesc()
        local isDevilCrown = HasBit(roomDesc.Flags, RoomDescriptor.FLAG_DEVIL_TREASURE)
        local item = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id or 0, pos, Vector.Zero, nil):ToPickup()
   
        if keeperBExists then
            item.ShopItemId = -1
            item.Price = 15
            item.AutoUpdatePrice = true
        elseif isDevilCrown then
            item.ShopItemId = -1
            item.Price = REVEL.GetDevilPrice(item.SubType)
            item.AutoUpdatePrice = true
        end
    end
end


end