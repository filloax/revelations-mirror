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

local Bell = {
    Effects = {
        SECRET_FORCE_ITEM = 1,
        MACHINE_ITEMS = 2,
        MACHINE_DIMES = 3,
        NO_DAMAGE_BOSS_CHOICE = 4,
        ANKH = 5,
        SHOP_CRAWLSPACE = 6,
    },
    -- 6 and 5 got switched due to the stage requirement
    clueAnims = {
        "01SecretRoom", "02Slots", "03Pennies", "04Bosses", "06BlueBaby",
        "05Crawlspace"
    },
    SlotItems = {
        {CollectibleType.COLLECTIBLE_DOLLAR}, {
            CollectibleType.COLLECTIBLE_BLOOD_BAG,
            CollectibleType.COLLECTIBLE_IV_BAG,
            CollectibleType.COLLECTIBLE_IV_BAG,
            CollectibleType.COLLECTIBLE_IV_BAG
        }, {CollectibleType.COLLECTIBLE_CRYSTAL_BALL}
    },
}

REVEL.HeavenlyBell = {}

local function BellEffFromStage(stage, maxEffId, player, offset)
    player = player or REVEL.player
    local stageSeed = REVEL.game:GetSeeds():GetStageSeed(stage)
    local playerId = REVEL.GetPlayerID(player)
    local rng = REVEL.RNG()
    rng:SetSeed(stageSeed * playerId, 40 + (offset or 0))
    return rng:RandomInt(maxEffId) + 1
end

function REVEL.HeavenlyBell.AddBellEffect(player)
    player = player or REVEL.player
    local currentEffectNum = #revel.data.run.bellEffect
    local effect

    if REVEL.level:GetAbsoluteStage() < LevelStage.STAGE4_1 then
        effect = BellEffFromStage(REVEL.level:GetStage(), 6, player, currentEffectNum)
    else
        effect = BellEffFromStage(REVEL.level:GetStage(), 5, player, currentEffectNum)
    end

    table.insert(revel.data.run.bellEffect, {effect, REVEL.GetPlayerID(player)})

    if effect == Bell.Effects.ANKH then
        local hadAnkh = player:HasCollectible(CollectibleType.COLLECTIBLE_ANKH)
        player:AddCollectible(CollectibleType.COLLECTIBLE_ANKH, 0, false)
        if not hadAnkh then
            player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_ANKH))
        end
    end

    REVEL.DebugToString("[REVEL] Added Heavenly Bell effect", effect, REVEL.getKeyFromValue(Bell.Effects, effect))

    return effect
end

function REVEL.HeavenlyBell.HasBellEffect(effId)
    return REVEL.some(revel.data.run.bellEffect, function(v, _, _) return v[1] == effId end)
end

function REVEL.HeavenlyBell.GetPlayersIDsWithEffect(effId)
    local ownerIds = {}
    for _, v in ipairs(revel.data.run.bellEffect) do
        if v[1] == effId then
            ownerIds[#ownerIds + 1] = v[2]
        end
    end
    return ownerIds
end

function REVEL.HeavenlyBell.GetEffectsOfPlayer(player)
    local effects = {}
    local playerId = REVEL.GetPlayerID(player)
    for _, v in ipairs(revel.data.run.bellEffect) do
        if v[2] == playerId then
            effects[#effects + 1] = v[1]
        end
    end
    return effects
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, loaded)
    for _, player in ipairs(REVEL.players) do
        -- do not check for item presence, as this covers other things that add
        -- the effect too (like Bell Shard)
        local effects = REVEL.HeavenlyBell.GetEffectsOfPlayer(player)
        if effects[1] then
            REVEL.HeavenlyBell.PlayClue(player, effects[1])

            -- Show eventual other effects delayed
            for i = 2, #effects do
                REVEL.DelayFunction(function()
                    REVEL.HeavenlyBell.PlayClue(player, effects[i])
                end, (i - 1) * 60)
            end
        end
    end
end)

function REVEL.HeavenlyBell.PlayClue(player, effId)
    player = player or REVEL.player
    REVEL.sfx:Play(REVEL.SFX.BELL[effId])

    if REVEL.game.Difficulty == Difficulty.DIFFICULTY_NORMAL 
    or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED 
    then
        REVEL.SpawnCustomGlow(
            player, Bell.clueAnims[effId],
            "gfx/itemeffects/revelcommon/bell_clues.anm2",
            60, 
            10
        )
    end
end

-- on pickup
REVEL.ITEM.HEAVENLY_BELL:addPickupCallback(function(player)
    local effect = REVEL.HeavenlyBell.AddBellEffect(player)
    REVEL.HeavenlyBell.PlayClue(player, effect)
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    for _, v in ipairs(revel.data.run.bellEffect) do
        -- this currently misses players that were present in last level
        -- but were removed after because run reload without player 2 joininh
        -- before new level; dare I saw that's one edge of a case
        if v[1] == Bell.Effects.ANKH then
            local player = REVEL.players[v[2]]
            if player then
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_ANKH)
            end
        end
    end

    -- manual reset instead of using level table to allow to check
    -- for previous level effects like above
    revel.data.run.bellEffect = {}

    for _, player in ipairs(REVEL.players) do
        local bellNum = REVEL.ITEM.HEAVENLY_BELL:GetCollectibleNum(player)
        for i = 1, bellNum do
            local effect = REVEL.HeavenlyBell.AddBellEffect(player)
            if i == 1 then
                REVEL.HeavenlyBell.PlayClue(player, effect)
            else
                REVEL.DelayFunction(function()
                    REVEL.HeavenlyBell.PlayClue(player, effect)
                end, (i - 1) * 60)
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    local room, level = REVEL.room, REVEL.game:GetLevel()
    if room:IsFirstVisit() and REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.SECRET_FORCE_ITEM) then
        -- First bell effect, add item to no-item secret rooms
        if room:GetType() == RoomType.ROOM_SECRET 
        and REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.SECRET_FORCE_ITEM) then
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
    -- 4th bell effect, add another 2 items on boss defeat if no damage taken
    if not REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.NO_DAMAGE_BOSS_CHOICE) 
    or room:GetType() ~= RoomType.ROOM_BOSS 
    then 
        return 
    end

    local pIDs = REVEL.HeavenlyBell.GetPlayersIDsWithEffect(Bell.Effects.NO_DAMAGE_BOSS_CHOICE)
    local canSpawn = false
    for _, i in ipairs(pIDs) do
        local player = REVEL.players[i]
        if not REVEL.WasPlayerDamagedThisRoom(player) then 
            canSpawn = true
        end
    end

    if canSpawn then
        local collectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)
        for i, e in ipairs(collectibles) do
            e:ToPickup().OptionsPickupIndex = 1
        end
        for i = 1, 2 do
            local item = Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0,
                room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, false),
                Vector.Zero, 
                nil
            ):ToPickup()
            item.OptionsPickupIndex = 1
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if #revel.data.run.bellEffect == 0 then return end

    local hasDimeEffect = REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.MACHINE_DIMES)
    local hasItemEffect = REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.MACHINE_ITEMS)

    if not hasDimeEffect and not hasItemEffect then return end

    local slots = Isaac.FindByType(EntityType.ENTITY_SLOT)

    for i, e in ipairs(slots) do
        -- IsDead doesn't work with slots
        if e:GetSprite():IsPlaying("Broken") 
        and Bell.SlotItems[e.Variant] then
            -- Effect 2, always spawn items on slot break
            if hasItemEffect then
                e:Remove()
                local item = Isaac.Spawn(
                    5, 100, Bell.SlotItems[e.Variant][math.random(1, #Bell.SlotItems[e.Variant])],
                    e.Position, Vector.Zero,
                    nil
                )
                -- it just happens that the frame for the slots in that animation corresponds to 4-e.Variant
                item:GetSprite() :SetOverlayFrame("Alternates", 4 - e.Variant)
            end
            -- Effect 3, always spawn dimes on slot break
            if hasDimeEffect and not e:GetData().spawnedCoin then
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
    and REVEL.HeavenlyBell.HasBellEffect(Bell.Effects.SHOP_CRAWLSPACE) 
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
