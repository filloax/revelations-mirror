local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-------------------
-- HEAVENLY BELL --
-------------------

--[[
    1:All secret rooms have items
    2:Always spawn items when destroying machines
    3:Always spawn dimes when destroying machines
    4:3 pedestals on bosses, you have to choose 1. only activates with no damage taken
    5:On death, respawn as blue baby
    6:Crawlspace always under shopkeeper
    ]]

revel.bell = {
    clueAnims = {
        "01SecretRoom", "02Slots", "03Pennies", "04Bosses", "06BlueBaby",
        "05Crawlspace"
    } -- 6 and 5 got switched due to the stage requirement
}

revel.bell.SlotItems = {
    {CollectibleType.COLLECTIBLE_DOLLAR}, {
        CollectibleType.COLLECTIBLE_BLOOD_BAG,
        CollectibleType.COLLECTIBLE_IV_BAG,
        CollectibleType.COLLECTIBLE_IV_BAG,
        CollectibleType.COLLECTIBLE_IV_BAG
    }, {CollectibleType.COLLECTIBLE_CRYSTAL_BALL}
}

function REVEL.BellEffFromStage(stage, maxEffId, player)
    player = player or REVEL.player
    return math.ceil(((REVEL.game:GetSeeds():GetStageSeed(stage) *
                            REVEL.GetPlayerID(player)) % 100 + 1) / 100 *
                            maxEffId)
end

function REVEL.SetBellEffect(player)
    player = player or REVEL.player
    local pID = REVEL.GetPlayerID(player)

    if REVEL.level:GetAbsoluteStage() < LevelStage.STAGE4_1 then
        revel.data.run.bellEffect[pID] =
            REVEL.BellEffFromStage(REVEL.level:GetStage(), 6, player)
    else
        revel.data.run.bellEffect[pID] =
            REVEL.BellEffFromStage(REVEL.level:GetStage(), 5, player)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, loaded)
    for _, player in ipairs(REVEL.players) do
        if REVEL.ITEM.HEAVENLY_BELL:PlayerHasCollectible(player) then
            revel.bell.PlayClue(player)
        end
    end
end)

function revel.bell.PlayClue(player)
    player = player or REVEL.player
    local pID = REVEL.GetPlayerID(player)
    REVEL.sfx:Play(REVEL.SFX.BELL[revel.data.run.bellEffect[pID]], 1, 0,
                    false, 1)

    if REVEL.game.Difficulty == Difficulty.DIFFICULTY_NORMAL or
        REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED then
        REVEL.SpawnCustomGlow(
            player, revel.bell.clueAnims[revel.data.run.bellEffect[pID]],
            "gfx/itemeffects/revelcommon/bell_clues.anm2",
            60, 
            10
        )
    end
end

function revel.bell.InitEffect(player) -- if the arg is true, don't change anything, only play the visuals and the sfx
    player = player or REVEL.player
    local pID = REVEL.GetPlayerID(player)

    local prevEffect = revel.data.run.bellEffect[REVEL.GetPlayerID(player)]

    REVEL.SetBellEffect(player)

    if revel.data.run.bellEffect[pID] == 5 and prevEffect ~= 5 then
        local hadAnkh = player:HasCollectible(CollectibleType.COLLECTIBLE_ANKH)
        player:AddCollectible(CollectibleType.COLLECTIBLE_ANKH, 0, false)
        if not hadAnkh then
            player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_ANKH))
        end
    elseif revel.data.run.bellEffect[pID] ~= 5 and prevEffect == 5 then
        player:RemoveCollectible(CollectibleType.COLLECTIBLE_ANKH)
    end

    revel.bell.PlayClue(player)

    if REVEL.DEBUG then
        REVEL.DebugToString("Played bell effect " .. revel.data.run.bellEffect[pID])
    end
end

-- on pickup
REVEL.ITEM.HEAVENLY_BELL:addPickupCallback(function(player)
    revel.bell.InitEffect(player)
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    for _, player in ipairs(REVEL.players) do
        if REVEL.ITEM.HEAVENLY_BELL:PlayerHasCollectible(player) then
            revel.bell.InitEffect(player)
        end
    end
end)

function revel.bell.GetPlayersWithEffect(effId)
    local ownerIds = {}
    for i = 1, 4 do
        if revel.data.run.bellEffect[i] == effId then
            ownerIds[#ownerIds + 1] = i
        end
    end
    if #ownerIds ~= 0 then return ownerIds end
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    local room, level = REVEL.room, REVEL.game:GetLevel()
    if room:IsFirstVisit()
    and REVEL.OnePlayerHasCollectible(REVEL.ITEM.HEAVENLY_BELL.id) then
        if room:GetType() == RoomType.ROOM_SECRET and
            revel.bell.GetPlayersWithEffect(1) then -- First bell effect, add item to no-item secret rooms
            local hasItem = false

            for i, e in ipairs(REVEL.roomPickups) do
                if e.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    hasItem = true
                end
            end
            if not hasItem then
                -- Spawn item with 0 subtype closest to room center (0 subtype makes it a random item from the room's pool)
                local e = Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0,
                    room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true),
                    Vector.Zero, 
                    nil
                )
                e:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 2, function(room)
    local pIDs = revel.bell.GetPlayersWithEffect(4)

    -- REVEL.DebugToString(pIDs)

    if not pIDs or room:GetType() ~= RoomType.ROOM_BOSS then return end

    local canSpawn = false
    for _, i in ipairs(pIDs) do
        local player = REVEL.players[i]
        if not REVEL.WasPlayerDamagedThisRoom(player) and
            REVEL.ITEM.HEAVENLY_BELL:PlayerHasCollectible(player) then -- 4th bell effect, add another 2 items on boss defeat if no damage taken
            canSpawn = true
        end
    end

    if canSpawn then
        local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)
        for i, e in ipairs(collectibles) do
            e.OptionsPickupIndex = 1;
        end
        for i = 1, 2 do
            local item = Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0,
                room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, false),
                Vector.Zero, 
                nil
            ):ToPickup()
            item.OptionsPickupIndex = 1;
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if not REVEL.OnePlayerHasCollectible(REVEL.ITEM.HEAVENLY_BELL.id) then
        return
    end
    local list2, list3 = revel.bell.GetPlayersWithEffect(2),
                            revel.bell.GetPlayersWithEffect(3)
    if not (list2 or list3) then return end

    local slots = Isaac.FindByType(6)

    for i, e in ipairs(slots) do
        -- IsDead doesn't work with slots
        if e:GetSprite():IsPlaying("Broken") 
        and revel.bell.SlotItems[e.Variant] then
            -- Effect 2, always spawn items on slot break
            if list2 then
                e:Remove()
                local item = Isaac.Spawn(
                    5, 100, revel.bell.SlotItems[e.Variant][math.random(1, #revel.bell.SlotItems[e.Variant])],
                    e.Position, Vector.Zero,
                    nil
                )
                -- it just happens that the frame for the slots in that animation corresponds to 4-e.Variant
                item:GetSprite() :SetOverlayFrame("Alternates", 4 - e.Variant)
            end
            -- Effect 3, always spawn dimes on slot break
            if list3 and not e:GetData().spawnedCoin then
                Isaac.Spawn(
                    5, PickupVariant.PICKUP_COIN, CoinSubType.COIN_DIME, 
                    e.Position, RandomVector() * 3, 
                    nil
                )
                e:GetData().spawnedCoin = true
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flag, src)
    if REVEL.room:GetType() == RoomType.ROOM_SHOP 
    and REVEL.OnePlayerHasCollectible(REVEL.ITEM.HEAVENLY_BELL.id) 
    and revel.bell.GetPlayersWithEffect(6) 
    then
        ent:Remove()
        REVEL.room:SpawnGridEntity(
            REVEL.room:GetGridIndex(ent.Position),
            GridEntityType.GRID_STAIRS, 
            0,
            math.random(10000), 
            0
        )
    end
end, EntityType.ENTITY_SHOPKEEPER)

end

REVEL.PcallWorkaroundBreakFunction()
