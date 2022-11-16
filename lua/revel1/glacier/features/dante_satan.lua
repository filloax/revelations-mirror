local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.DanteSatanLayout = StageAPI.CreateEmptyRoomLayout()
REVEL.DanteSatanLayout.Name = "Dante Satan"
StageAPI.RegisterLayout("Dante Satan", REVEL.DanteSatanLayout)

REVEL.DanteSatanRNG = REVEL.RNG()

---@param newRoom LevelRoom
StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOM_LAYOUT_CHOOSE, -5, function(newRoom)
    if StageAPI.InTestMode then return end

    if REVEL.STAGE.Glacier:IsStage() 
    and newRoom:GetType() == RoomType.ROOM_DEFAULT 
    and REVEL.room:GetType() == RoomType.ROOM_DEFAULT -- check base room, for sarah reasons
    and newRoom.Shape == RoomShape.ROOMSHAPE_1x1 
    and not StageAPI.InExtraRoom() 
    and not revel.data.run.seenDanteSatan then
        local numDoors = 0
        for i = 0, 7 do
            if REVEL.room:GetDoor(i) then
                numDoors = numDoors + 1
                if numDoors > 1 then
                    break
                end
            end
        end

        if numDoors == 1 then
            REVEL.DanteSatanRNG:SetSeed(newRoom.Seed, 0)
            if StageAPI.Random(1, 30, REVEL.DanteSatanRNG) == 1 then
                revel.data.run.seenDanteSatan = true
                return REVEL.DanteSatanLayout
            end
        end
    end
end)

function REVEL.GetDevilPrice(id)
    local devilPrice = REVEL.config:GetCollectible(id).DevilPrice

    local playerHasRedHealth, allPlayersHaveRedHealth
    for _, player in ipairs(REVEL.players) do
        if player:GetMaxHearts() > 0 then
            playerHasRedHealth = true
        else
            allPlayersHaveRedHealth = true
        end
    end

    allPlayersHaveRedHealth = not allPlayersHaveRedHealth

    if allPlayersHaveRedHealth or (playerHasRedHealth and math.random(1, 2) == 1) then
        if devilPrice == 1 then
            return PickupPrice.PRICE_ONE_HEART
        else
            return PickupPrice.PRICE_TWO_HEARTS
        end
    else
        return PickupPrice.PRICE_THREE_SOULHEARTS
    end
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom)
    if newRoom.Layout.Name == REVEL.DanteSatanLayout.Name then
        local devilPos = REVEL.room:GetCenterPos() + Vector(0, -40)
        local devilIndex = REVEL.room:GetGridIndex(devilPos)

        local npc = Isaac.Spawn(
            EntityType.ENTITY_EFFECT, 6, 0, 
            devilPos, Vector.Zero, 
            nil
        )
        npc:GetSprite():Load("gfx/grid/revel1/glacier_dante_satan.anm2", true)
        npc:GetSprite():Play("Default", true)

        for i = -3, 3 do
            Isaac.GridSpawn(GridEntityType.GRID_WALL, 0, REVEL.room:GetGridPosition(devilIndex + i), true)
        end

        if REVEL.room:IsFirstVisit() then
            local id = REVEL.pool:GetCollectible(ItemPoolType.POOL_DEVIL, true, REVEL.room:GetSpawnSeed())

            local keeperBExists = false
            for _,player in ipairs(REVEL.players) do
                if player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
                    keeperBExists = true
                    break
                end
            end

            local pos = REVEL.room:GetGridPosition(devilIndex + REVEL.room:GetGridWidth() * 2)

            if keeperBExists then
                local item = Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id, 
                    pos, Vector.Zero, 
                    nil
                ):ToPickup()
                item.Price = 15
                item.AutoUpdatePrice = true
            else
                local item = Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, id, 
                    pos, Vector.Zero, 
                    nil
                ):ToPickup()
                item.Price = REVEL.GetDevilPrice(id)
                item.AutoUpdatePrice = false
            end
        end
    end
end)

end