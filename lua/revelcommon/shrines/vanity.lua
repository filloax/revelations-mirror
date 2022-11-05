local StageAPICallbacks = require "lua.revelcommon.enums.StageAPICallbacks"
local RevCallbacks      = require "lua.revelcommon.enums.RevCallbacks"
local RevRoomType       = require "lua.revelcommon.enums.RevRoomType"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- There is another
local InputSequence = {
    {Action = ButtonAction.ACTION_DOWN},
    {Action = ButtonAction.ACTION_DOWN},
    {Action = ButtonAction.ACTION_DOWN},
    {Action = ButtonAction.ACTION_LEFT},
    {Action = ButtonAction.ACTION_RIGHT},
    {Action = ButtonAction.ACTION_ITEM, Key = Keyboard.KEY_SPACE},
}

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.PRANK_SHOP.id,
    Variant = REVEL.ENT.PRANK_SHOP.variant,
    UpdateSubType = true,
})

local RewardKinds = {
    PICKUP = 0,
    COLLECTIBLE = 1,
    DEVIL_ROOM_TELEPORT = 2,
}

-- Config prices in shrines.lua
-- Weight is also affected by how close to the player's amount
-- the price is
local PactRewardItems = {
    {
        Kind = RewardKinds.PICKUP,
        Price = REVEL.ShrineBalance.PickupPrice,
        IsRandom = true, 
        BaseEntity = {Type = 5, Variant = 0, SubType = 4}, --random pickup (no chest item or trinket)
        Amount = REVEL.ShrineBalance.PickupAmount,
        Weight = 4.5,
    },
    {
        Kind = RewardKinds.PICKUP,
        Price = REVEL.ShrineBalance.TrinketPrice,
        IsRandom = true, 
        BaseEntity = {Type = 5, Variant = 350, SubType = 0}, --random trinket
        Weight = 1,
    },
    {
        Kind = RewardKinds.COLLECTIBLE,
        Price = REVEL.ShrineBalance.ShopItemPrice,
        Pool = ItemPoolType.POOL_SHOP,
        Weight = 2.5,
    },
    {
        Kind = RewardKinds.COLLECTIBLE,
        Price = REVEL.ShrineBalance.TreasureItemPrice,
        Pool = ItemPoolType.POOL_TREASURE,
        Weight = 1,
    },
    {
        Kind = RewardKinds.COLLECTIBLE,
        Price = REVEL.ShrineBalance.DevilItemPrice,
        Pool = ItemPoolType.POOL_DEVIL,
        Weight = 1,
    },
    {
        Kind = RewardKinds.COLLECTIBLE,
        Price = REVEL.ShrineBalance.AngelItemPrice,
        Pool = ItemPoolType.POOL_ANGEL,
        Weight = 0.5,
    },
    {
        Kind = RewardKinds.DEVIL_ROOM_TELEPORT,
        Price = REVEL.ShrineBalance.DevilRoomTeleportPrice,
        Weight = 2,
    },
}

--[[
<group Name="Random Collectibles">
    <entity ID="5" Variant="100" Subtype="0" Name="Random Collectible" Image="Entities/Items/5.100.0 - Random.png"/>
    <entity ID="5" Variant="150" Subtype="0" Name="Random Shop Item" Image="Entities/Items/5.150.0 - Random.png"/>
    <entity ID="5" Variant="350" Subtype="0" Name="Random Trinket" Image="Entities/5.350.0 - Trinket.png"/>
</group>
<group Name="Random All Pickups">
    <entity ID="5" Variant="0" Subtype="0" Name="Pickup" Image="Entities/5.0.0 - Pickup.png"/>
    <entity ID="5" Variant="0" Subtype="1" Name="Pickup (not chest or item)" Image="Entities/5.0.1 - Pickup.png"/>
    <entity ID="5" Variant="0" Subtype="2" Name="Pickup (not item)" Image="Entities/5.0.2 - Pickup.png"/>
    <entity ID="5" Variant="0" Subtype="3" Name="Greed Pickup (no chest, item, or coin)" Image="Entities/5.0.3 - Pickup.png"/>
    <entity ID="5" Variant="0" Subtype="4" Name="Pickup (no chest, item, or trinket)" Image="Entities/5.0.4 - Pickup.png"/>
</group>
<entity ID="5" Image="Entities/5.10.0 - RHeart.png" Name="Random Heart" Subtype="0" Variant="10"/>
<entity ID="5" Image="Entities/5.20.0 - RCoin.png" Name="Random Coin" Subtype="0" Variant="20"/>
<entity ID="5" Image="Entities/5.30.0 - RKey.png" Name="Random Key" Subtype="0" Variant="30"/>
<entity ID="5" Image="Entities/5.40.0 - RBomb.png" Name="Random Bomb" Subtype="0" Variant="40"/>
<entity ID="5" Image="Entities/5.90.1 - Lil' Battery.png" Name="Lil' Battery" Subtype="0" Variant="90"/>
<entity ID="5" Image="Entities/5.70.0 - Random Pill.png" Name="Random Pill" Subtype="0" Variant="70"/>
<entity ID="5" Image="Entities/5.301.0 - Random Rune.png" Name="Random Rune" Subtype="0" Variant="301"/>
<entity ID="5" Image="Entities/5.300.0 - Random Card.png" Name="Random Card" Subtype="0" Variant="300"/>
]]

local BASE_PICKUP_HUD_POS = Vector(43, 33)
local TAINTED_PICKUP_OFFSET = Vector(0, 7.5) --example, tainted ???
local TAINTED_ISAAC_OFFSET = Vector(0, 24)
local JACOB_ESAU_OFFSET = Vector(0, 14)
local PICKUP_SPRITE_OFFSET = Vector(-7, 7.5)

local PICKUP_TEXT_COLOR = KColor(1, 1, 1, 1)
local PRICE_COLOR = Color(1, 1, 0.25, 1)
local PRICE_DISCOUNT_COLOR = Color(1, 0, 0, 1)
-- local LIGHTNING_SPAWN_COLOR = Color(0,0,0,1, 1, 1, 0.25)

REVEL.VanityTextColor = PRICE_COLOR

local MUSIC_BPM = 115

local VanityShopRoomGfx = StageAPI.RoomGfx(BackdropType.SHOP, StageAPI.BaseGridGfx.Basement)

local PickupFont = Font()
PickupFont:Load("font/pftempestasevencondensed.fnt")

-- Always loaded sprite, used in UI
local PickupSprite = Sprite()
PickupSprite:Load("gfx/ui/vanity.anm2", true)
PickupSprite:Play("default", true)

local PriceSpriteParams = {
    ID = "Vanity_PriceSprite",
    Anm2 = "gfx/005.150_shop item.anm2",
    Animation = "NumbersWhite",
    Color = PRICE_COLOR,
}

local PriceVanitySpriteParams = {
    ID = "Vanity_PriceVanitySprite",
    Anm2 = "gfx/effects/revelcommon/vanity_shop.anm2",
    Animation = "default",
    Color = PRICE_COLOR,
}

local RewardRNG = REVEL.RNG()

local ShopMusicStartTime = -1

local GoToVanityShop

local TriggeredMorshuThisRoom = false
local TriggeredMorshu2ThisRoom = false
local MorshuPlaying = false
local ShowMorshuAnim2

-- Manually handle to only spawn base entity and spawn floor renderer off of it
-- StageAPI.AddEntityPersistenceData({
--     Type = REVEL.ENT.PACT_SHOP.id,
--     Variant = REVEL.ENT.PACT_SHOP.variant
-- })

function REVEL.AddShrineVanity(amount)
    revel.data.run.vanity = math.max(revel.data.run.vanity + amount, 0)
end

function REVEL.GetShrineVanity()
    return revel.data.run.vanity
end

local DoingDevilRoomTeleport = false

local function TeleportToDevilRoom(player)
    -- player = player or REVEL.player
    -- local pos = player.Position
    -- revel.data.run.level.vShopDevilRoomTeleportPos = {pos.X, pos.Y}
    -- revel.data.run.level.didVshopDevilRoomTeleport = true
    DoingDevilRoomTeleport = true
    player:UseCard(Card.CARD_JOKER, BitOr(UseFlag.USE_NOANIM, UseFlag.USE_NOANNOUNCER))
end

local lastChapter = -1
if REVEL.IsReloading() then
    lastChapter = REVEL.GetStageChapter()
end

local function shrineVanity_NewLevel()
    local chapter = REVEL.GetStageChapter()

    if not REVEL.IsRevelStage() and REVEL.GetShrineVanity() > 0 then
        -- Changed chapter and got out of rev stage, reset currency
        if chapter ~= lastChapter then
            REVEL.DebugStringMinor("Left rev path, removing all vanity...")
            REVEL.AddShrineVanity(-REVEL.GetShrineVanity())
        -- Same chapter, just reduce the reward obtained from two-stage pacts
        -- into a single-stage one
        else
            -- Subtract currency depending on what pacts you have that
            -- give two-stage rewards
            REVEL.DebugStringMinor("Left rev path mid chapter, removing vanity to match single-stage pact values...")
            for _, activeShrine in ipairs(revel.data.run.activeShrines) do
                if not activeShrine.isOneChapter then
                    REVEL.AddShrineVanity(activeShrine.oneChapterValue - activeShrine.value)
                end
            end
        end
    end

    lastChapter = REVEL.GetStageChapter()
end

local didEIDOffset = false

local function shrineVanityHUD_PostRender()
    if not REVEL.ShouldRenderHudElements()
    or revel.data.run.vanity == 0
    then
        if EID and didEIDOffset then
            EID:removeTextPosModifier("rev-pact-vanity")
            didEIDOffset = false
        end

        return
    end

    if EID and not didEIDOffset then
        EID:addTextPosModifier("rev-pact-vanity", Vector(0, 10))
        didEIDOffset = true
    end

    local pos = REVEL.GetScreenTopLeft() + BASE_PICKUP_HUD_POS

    if REVEL.player:GetPlayerType() == PlayerType.PLAYER_XXX_B then
        pos = pos + TAINTED_PICKUP_OFFSET
    elseif REVEL.player:GetPlayerType() == PlayerType.PLAYER_ISAAC_B then
        pos = pos + TAINTED_ISAAC_OFFSET
    elseif REVEL.player:GetPlayerType() == PlayerType.PLAYER_JACOB then
        pos = pos + JACOB_ESAU_OFFSET
    end

    local textPos = pos + REVEL.GetHudTextOffset()

    PickupSprite:Render(pos + PICKUP_SPRITE_OFFSET)
    PickupFont:DrawString(("%02d"):format(revel.data.run.vanity), textPos.X, textPos.Y, PICKUP_TEXT_COLOR)
end

local function ShouldRemoveReward(kind)
    local removeReward = false
    local existingPactShops = REVEL.ENT.PACT_SHOP:getInRoom()
    for _, effect in ipairs(existingPactShops) do
        local edata = effect:GetData()
        if edata.Reward and edata.Reward.Kind == kind then
            removeReward = true
            break
        end
    end
    return removeReward
end

---If the price is between the tryPrice +- the two tresholds edges
-- for each treshold
---@param price number
---@param tryPrice number
---@param underTreshold? number
---@param overTreshold? number
---@param underTresholdSecondary? number
---@param overTresholdSecondary? number
---@return boolean matchesPrimary, boolean matchesSecondary
local function MatchesTresholds(price, tryPrice, underTreshold, overTreshold, underTresholdSecondary, overTresholdSecondary)
    local matchesPrimary = (not underTreshold or price >= tryPrice - underTreshold)
        and (not overTreshold or price <= tryPrice + overTreshold)
    local matchesSecondary = (not underTresholdSecondary or price >= tryPrice - underTresholdSecondary)
        and (not overTresholdSecondary or price <= tryPrice + overTresholdSecondary)

    return matchesPrimary and matchesSecondary, matchesSecondary
end

local function ChooseRewardRandom(tryPrice, underTreshold, overTreshold, underTresholdSecondary, overTresholdSecondary)
    local removeDevilTeleport = ShouldRemoveReward(RewardKinds.DEVIL_ROOM_TELEPORT)
    
    local prevWeights = {}
    if removeDevilTeleport then
        for i, reward in ipairs(PactRewardItems) do
            if reward.Kind == RewardKinds.DEVIL_ROOM_TELEPORT then
                prevWeights[i] = reward.Weight
                reward.Weight = 0
            end
        end
    end

    -- set weight of stuff below/above tresholds
    -- to 0 only if there are valid rewards
    if underTreshold or overTreshold then
        -- If doesn't have vanity, ignore price tresholds to avoid stageAPI bugging
        if tryPrice == 0 then
            return ChooseRewardRandom()
        end

        local hasValidPrimary, hasValidSecondary
        for i, reward in ipairs(PactRewardItems) do
            if reward.Weight > 0 then
                local match1, match2 = MatchesTresholds(reward.Price, tryPrice, underTreshold, overTreshold, 
                        underTresholdSecondary, overTresholdSecondary)
                if match1 then
                    hasValidPrimary = true
                    hasValidSecondary = true
                    break
                elseif match2 then
                    hasValidSecondary = true
                end
            end
        end
        if hasValidPrimary then
            for i, reward in ipairs(PactRewardItems) do
                local matches1, _ = MatchesTresholds(reward.Price, tryPrice, underTreshold, overTreshold, 
                    underTresholdSecondary, overTresholdSecondary)
                if reward.Weight > 0 and not matches1 then
                    prevWeights[i] = reward.Weight
                    reward.Weight = 0
                end
            end
        elseif hasValidSecondary then
            for i, reward in ipairs(PactRewardItems) do
                local _, matches2 = MatchesTresholds(reward.Price, tryPrice, underTreshold, overTreshold, 
                    underTresholdSecondary, overTresholdSecondary)
                if reward.Weight > 0 and not matches2 then
                    prevWeights[i] = reward.Weight
                    reward.Weight = 0
                end
            end
        end
    end

    -- for performance when debug is off, as using debugstringminor would run the map+filter
    -- regardless
    if REVEL.DEBUG then
        REVEL.DebugToString(("R: Avaiable rewards for price %d: %s"):format(tryPrice or 0,
            REVEL.ToString(REVEL.map(
                REVEL.filter(PactRewardItems, function(v) return v.Weight > 0 end),
                function(v) return ("[K%d | P%d | W%.1f]"):format(v.Kind, v.Price, v.Weight) end
            ))
        ))
    end

    local out = StageAPI.WeightedRNG(PactRewardItems, RewardRNG, "Weight")

    for i, weight in pairs(prevWeights) do
        PactRewardItems[i].Weight = weight
    end

    return out
end

local function GetMaxRewardForPrice(tryPrice)
    -- If doesn't have vanity, go random to avoid stageAPI bugging
    if tryPrice == 0 then
        return ChooseRewardRandom()
    end

    local removeDevilTeleport = ShouldRemoveReward(RewardKinds.DEVIL_ROOM_TELEPORT)

    local maxPrice, maxPriceRewards = nil, {}
    for i, reward in ipairs(PactRewardItems) do
        if reward.Price <= tryPrice 
        and (not removeDevilTeleport or reward.Kind ~= RewardKinds.DEVIL_ROOM_TELEPORT) then
            if not maxPrice or reward.Price > maxPrice then
                maxPriceRewards = {reward}
                maxPrice = reward.Price
            elseif reward.Price == maxPrice then
                maxPriceRewards[#maxPriceRewards+1] = reward
            end
        end
    end

    if REVEL.DEBUG then
        REVEL.DebugToString(("M: Available rewards for price %d: %s"):format(tryPrice, 
            REVEL.ToString(REVEL.map(maxPriceRewards, function(v) return ("[K%d | P%d]"):format(v.Kind, v.Price) end))
        ))
    end

    return StageAPI.WeightedRNG(maxPriceRewards, RewardRNG, "Weight")
end

local function CreateNewRewardSubtype(getReward, ...)
    local reward
    if type(getReward) == "table" then
        reward = REVEL.CopyTable(reward)
    else
        reward = getReward(...)
    end
    local idx = #revel.data.run.level.shrineRewards + 1
    revel.data.run.level.shrineRewards[idx] = REVEL.CopyTable(reward)
    return idx
end

-- Taken from capsule anm2 example anim
local CapsulePickupOffsets = {
    Vector(1, -7),
    Vector(7, -14),
    Vector(-4, -14),
}

-- Taken from various pickup anm2s
local CapsulePickupOffsetPerPickup = {
    [PickupVariant.PICKUP_BOMB] = Vector(0, 2 - 9 + 4), --additional offset cause bombs big
    [PickupVariant.PICKUP_HEART] = Vector(0, -1 - 4),
    [PickupVariant.PICKUP_PILL] = Vector(0, -4),
    [PickupVariant.PICKUP_COIN] = Vector(0, -4),
    [PickupVariant.PICKUP_KEY] = Vector(0, 2 - 9),
    [PickupVariant.PICKUP_LIL_BATTERY] = Vector(0, -6),
    [PickupVariant.PICKUP_TAROTCARD] = Vector(0, 2 - 8),
}

local function GetCapsuleSlotOffset(i)
    if i>3 then
        return nil
    end
    return CapsulePickupOffsets[i]
end

local function GetPickupOffset(pickup, i)
    local offset = GetCapsuleSlotOffset(i) 
    if offset then
        return GetCapsuleSlotOffset(i) 
        - (CapsulePickupOffsetPerPickup[pickup.Variant] or Vector.Zero)
    end
    return nil
end

-- [var] = {[subtype]}
local BlacklistedPickups = {
    [PickupVariant.PICKUP_BOMB] = {
        [BombSubType.BOMB_TROLL] = true,
        [BombSubType.BOMB_SUPERTROLL] = true,
        [BombSubType.BOMB_GOLDENTROLL] = true,
    }
}

local CapsuleSkins = {
    "pink",
    "green",
    "red",
    "yellow",
}

local function SetVanityCollectible(effect, itemType)
    local sprite, data = effect:GetSprite(), effect:GetData()

    local configItem = REVEL.config:GetCollectible(itemType)

    local itemSprite = configItem.GfxFileName

    local hasBlind = REVEL.IsThereCurse(LevelCurse.CURSE_OF_BLIND)
    if hasBlind then
        itemSprite = "gfx/items/collectibles/questionmark.png"
    end

    sprite:Load("gfx/005.100_collectible.anm2", false)
    sprite:ReplaceSpritesheet(1, itemSprite)
    sprite:LoadGraphics()
    sprite:Play("ShopIdle", true)

    if EID then
        data.EID_Description = REVEL.GetEidItemDesc(itemType)
    end
end

local function rewardShop_Init(_, effect)
    local data, sprite = effect:GetData(), effect:GetSprite()

    if effect.SubType == 0 then
        effect.SubType = CreateNewRewardSubtype(ChooseRewardRandom)
    end

    local listIndex = tostring(StageAPI.GetCurrentRoomID())
    if not revel.data.run.level.shrineRewardRooms[listIndex] then
        revel.data.run.level.shrineRewardRooms[listIndex] = {}
    end
    local roomPersistData = revel.data.run.level.shrineRewardRooms[listIndex]
    local idx = tostring(REVEL.room:GetGridIndex(effect.Position))
    if not roomPersistData[idx] then
        roomPersistData[idx] = effect.SubType
    end

    local reward = revel.data.run.level.shrineRewards[effect.SubType]
    local rewardData = {}
    data.RewardData = rewardData

    if not reward then
        error(("No vanity reward for subtype %d!"):format(effect.SubType))
    end
    
    rewardData.Sprites = {}
    rewardData.SpriteOffsets = {}

    if reward.Kind == RewardKinds.PICKUP then
        if not reward.Entities then
            reward.Entities = {}
            for i = 1, reward.Amount or 1 do
                -- Use vanilla random pickup entities
                local baseSubType = reward.BaseEntity.SubType or 0
                local rewardEntity, isGood
                -- try spawning until you don't get a blacklisted pickup type (mainly troll bombs)
                repeat
                    rewardEntity = Isaac.Spawn(
                        reward.BaseEntity.Type, reward.BaseEntity.Variant, baseSubType,
                        effect.Position, Vector.Zero, effect
                    )
                    isGood = (baseSubType ~= 0 and reward.BaseEntity.Variant ~= 0) or not (
                            BlacklistedPickups[rewardEntity.Variant] 
                            and BlacklistedPickups[rewardEntity.Variant][rewardEntity.SubType]
                        )

                    -- max 1 bomb item
                    if isGood and rewardEntity.Variant == PickupVariant.PICKUP_BOMB
                    and REVEL.some(reward.Entities, function(ent2)
                        return ent2.Variant == PickupVariant.PICKUP_BOMB
                    end) then
                        isGood = false
                    end

                    if not isGood then
                        rewardEntity:Remove()
                    end
                until isGood
                reward.Entities[#reward.Entities+1] = {
                    Type = rewardEntity.Type, 
                    Variant = rewardEntity.Variant, 
                    SubType = rewardEntity.SubType
                }

                local rewardSprite = rewardEntity:GetSprite()
                rewardData.Sprites[i] = Sprite()
                rewardData.Sprites[i]:Load(rewardSprite:GetFilename(), false)

                if rewardEntity.Variant == PickupVariant.PICKUP_TRINKET then
                    local configTrinket = REVEL.config:GetTrinket(rewardEntity.SubType)
                    local spritesheet = configTrinket.GfxFileName
                    rewardData.Sprites[i]:ReplaceSpritesheet(0, spritesheet)
                end
                rewardData.Sprites[i]:LoadGraphics()
                rewardData.Sprites[i]:Play("Idle", true) --rewardSprite:GetAnimation(), true)

                rewardEntity:Remove()
            end

        else
            for i, entityDef in ipairs(reward.Entities) do
                local rewardEntity = Isaac.Spawn(
                    entityDef.Type, entityDef.Variant, entityDef.SubType,
                    effect.Position, Vector.Zero, effect
                )

                local rewardSprite = rewardEntity:GetSprite()
                rewardData.Sprites[i] = Sprite()
                rewardData.Sprites[i]:Load(rewardSprite:GetFilename(), false)

                if rewardEntity.Variant == PickupVariant.PICKUP_TRINKET then
                    local configTrinket = REVEL.config:GetTrinket(rewardEntity.SubType)
                    local spritesheet = configTrinket.GfxFileName
                    rewardData.Sprites[i]:ReplaceSpritesheet(0, spritesheet)
                end
                rewardData.Sprites[i]:LoadGraphics()
                rewardData.Sprites[i]:Play("Idle", true) --rewardSprite:GetAnimation(), true)

                rewardEntity:Remove()
            end
        end

        -- If there are bombs, put them at the front for 
        -- fitting in the capsule purposes
        local bombIndex = REVEL.findKey(reward.Entities, function(ent2)
            return ent2.Variant == PickupVariant.PICKUP_BOMB
        end)
        if bombIndex then
            local rewardEntityData = table.remove(reward.Entities, bombIndex)
            local entSprite = table.remove(rewardData.Sprites, bombIndex)
            table.insert(reward.Entities, 1, rewardEntityData)
            table.insert(rewardData.Sprites, 1, entSprite)
        end

        for i = 1, #reward.Entities do
            if reward.Amount == 1 then
                rewardData.SpriteOffsets[i] = Vector.Zero
            else
                rewardData.SpriteOffsets[i] = GetPickupOffset(reward.Entities[i], i)
            end
        end

        if reward.Amount and reward.Amount > 1 then
            data.CapsuleSprite = Sprite()
            data.CapsuleSprite:Load("gfx/effects/revelcommon/capsule.anm2", false)
            local rng = REVEL.RNG()
            rng:SetSeed(effect.InitSeed, 40)
            local skin = rng:RandomInt(5)
            if skin ~= 0 then -- 0 = blue (base) skin, no replacement
                data.CapsuleSprite:ReplaceSpritesheet(0, "gfx/effects/revelcommon/capsule_" .. CapsuleSkins[skin] .. ".png")
                data.CapsuleSprite:ReplaceSpritesheet(2, "gfx/effects/revelcommon/capsule_" .. CapsuleSkins[skin] .. ".png")
            end
            data.CapsuleSkin = skin
            data.CapsuleSprite:LoadGraphics()
            data.CapsuleSprite:SetFrame("Idle", 0)
        end

        reward.IsRandom = nil
    elseif reward.Kind == RewardKinds.COLLECTIBLE then
        local rewardItem = reward.Item
        if not rewardItem then
            rewardItem = REVEL.pool:GetCollectible(reward.Pool, true)
            reward.Item = rewardItem
        end
        SetVanityCollectible(effect, rewardItem)
    elseif reward.Kind == RewardKinds.DEVIL_ROOM_TELEPORT then
        sprite:Load("gfx/effects/revelcommon/devil_room_teleport.anm2", false)
        sprite:ReplaceSpritesheet(1, "gfx/effects/revelcommon/devil_room_teleport.png")
        sprite:LoadGraphics()
        sprite:Play("Idle", true)
    end

    data.Reward = reward
    data.Price = reward.Price

    if revel.data.run.prankDiscount[REVEL.GetStageChapter()] == 1 then
        data.Price = data.Price - REVEL.ShrineBalance.PrankVanityDiscount
        data.Discounted = true
    end

    if data.Reward.Item then
        local itemConfig = Isaac:GetItemConfig():GetCollectible(data.Reward.Item)
        if itemConfig.Quality >= 4 then
            data.Price = data.Price + RewardRNG:RandomInt(2)+2
        elseif itemConfig.Quality == 3 then
            data.Price = data.Price + RewardRNG:RandomInt(2)
        elseif itemConfig.Quality == 2 then
            data.Price = data.Price - RewardRNG:RandomInt(2)
        elseif itemConfig.Quality <= 1 then
            data.Price = data.Price - RewardRNG:RandomInt(2)+1
        end
        data.Price = math.max(1,data.Price)
    end

    for i, player in ipairs(REVEL.players) do
        -- REVEL.DebugStringMinor(effect.Index, player.Position:Distance(effect.Position), 40 + player.Size)
        if player.Position:DistanceSquared(effect.Position) < (40 + player.Size) ^ 2 then
            -- REVEL.DebugStringMinor(effect.Index, "wait")
            data.WaitingPlayer = true
            break
        end
    end
end

local function rewardShop_PostUpdate(_, effect)
    local data, sprite = effect:GetData(), effect:GetSprite()
    local collected, player

    -- Spawned near player, wait for players to leave before looking for buyers
    if data.WaitingPlayer then
        -- REVEL.DebugStringMinor(effect.Index, "test1")
        for i, player in ipairs(REVEL.players) do
            -- REVEL.DebugStringMinor(effect.Index, "check", player.Position:Distance(effect.Position), 60 + player.Size)
            if player.Position:DistanceSquared(effect.Position) < (60 + player.Size) ^ 2 then
                -- REVEL.DebugStringMinor(effect.Index, "test2")
                return
            end
        end
        -- REVEL.DebugStringMinor(effect.Index, "test3")
        data.WaitingPlayer = nil
    end
    
    local disable = false
    if data.Reward.Kind == RewardKinds.DEVIL_ROOM_TELEPORT then
        for _, chest in ipairs(REVEL.ENT.MIRROR_FIRE_CHEST:getInRoom()) do
            if chest:GetSprite():GetAnimation() == "Opened" then
                disable = true
                break
            end
        end
    end

    if disable and not data.Disabled then
        effect.Color = Color(1,1,1, 0.5)
    elseif not disable and data.Disabled then
        effect.Color = Color.Default
    end

    data.Disabled = disable

    if not data.Touched
    and not disable
    and (
        REVEL.GetShrineVanity() >= data.Price
        or (TriggeredMorshuThisRoom and not TriggeredMorshu2ThisRoom)
    ) then
        for i, player2 in ipairs(REVEL.players) do
            if player2.Position:DistanceSquared(effect.Position) < (20 + player2.Size) ^ 2 then
                if REVEL.GetShrineVanity() >= data.Price then
                    collected = true
                    player = player2
                    data.ToucherPlayer = EntityPtr(player)
                elseif TriggeredMorshuThisRoom and not TriggeredMorshu2ThisRoom and not MorshuPlaying then
                    ShowMorshuAnim2()
                    TriggeredMorshu2ThisRoom = true
                end
                break
            end
        end
    end

    local doSpawn = false
    local capsuleSpawn = false

    if collected and not data.Touched then
        data.Touched = true
        REVEL.DebugStringMinor(("Vanity shop %d sub %d: collected, reward: %s")
            :format(REVEL.room:GetGridIndex(effect.Position), effect.SubType, ("[K%d | P%d]"):format(data.Reward.Kind, data.Reward.Price)))

        doSpawn = true
        REVEL.AddShrineVanity(-data.Price)

        local listIndex = tostring(StageAPI.GetCurrentRoomID())
        local roomPersistData = revel.data.run.level.shrineRewardRooms[listIndex]
        local idx = tostring(REVEL.room:GetGridIndex(effect.Position))
        roomPersistData[idx] = nil

        data.SpawnCapsuleDecoration = not not data.CapsuleSprite

        if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_RESTOCK) then
            REVEL.DebugStringMinor(("Player has restock, spawning another vanity shop item at %s from %d..."):format(idx, effect.SubType))
            Isaac.Spawn(REVEL.ENT.PACT_SHOP.id, REVEL.ENT.PACT_SHOP.variant, 0, effect.Position, Vector.Zero, effect)
            data.SpawnCapsuleDecoration = false
        end

        if data.CapsuleSprite then
            doSpawn = false
            data.CapsuleSprite:Play("Pop", true)
        end
    end

    if data.CapsuleSprite then
        data.CapsuleSprite:Update()
        if data.CapsuleSprite:IsEventTriggered("Pop") then
            REVEL.sfx:Play(SoundEffect.SOUND_PLOP)
            doSpawn = true
            capsuleSpawn = true
            data.Reward.Sprites = nil
        end
        if data.CapsuleSprite:IsFinished("Pop")
        and not data.DoNotRemove
        then
            effect:Remove()
        end
    end

    if doSpawn then
        ---@cast player EntityPlayer
        player = player or (data.ToucherPlayer and data.ToucherPlayer.Ref)

        local doNotRemove = false

        if data.Reward.Kind == RewardKinds.PICKUP then
            for i = 1, data.Reward.Amount or 1 do
                local toSpawn = data.Reward.Entities[i]
                local dir = RandomVector()

                local pos = player.Position
                local vel = Vector.Zero
                if capsuleSpawn then
                    pos = effect.Position + dir * math.random(2, 10)
                    vel = dir * (math.random() * 1 + 0.5)
                end

                ---@type EntityPickup
                local entity = Isaac.Spawn(
                    toSpawn.Type, 
                    toSpawn.Variant, 
                    toSpawn.SubType or 0, 
                    pos, 
                    vel, 
                    effect
                ):ToPickup()
                entity:GetSprite():Play("Appear", true)
                entity:GetSprite():SetFrame(5)
                entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                if capsuleSpawn then
                    entity.Timeout = -1
                    entity.Wait = 5
                end
            end
            data.RewardData.Sprites = {}
            data.StopRenderingPrice = true
        elseif data.Reward.Kind == RewardKinds.COLLECTIBLE then
            local configItem = REVEL.config:GetCollectible(data.Reward.Item)
            if configItem.Type == ItemType.ITEM_ACTIVE then
                local activeItem = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)
                if activeItem > 0 then
                    local coll = Isaac.Spawn(
                        EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, activeItem,
                        effect.Position, Vector.Zero,
                        nil
                    ):ToPickup()
                    coll.Wait = 60
                    
                    -- just in case
                    player:RemoveCollectible(activeItem)
                end
            end

            player:AddCollectible(data.Reward.Item, configItem.MaxCharges)
            player:AnimateCollectible(data.Reward.Item)
            REVEL.game:GetHUD():ShowItemText(player, configItem)
            REVEL.sfx:Play(SoundEffect["SOUND_POWERUP" .. math.random(1, 3)])
        elseif data.Reward.Kind == RewardKinds.DEVIL_ROOM_TELEPORT then
            TeleportToDevilRoom(player)
            doNotRemove = true
        end

        if data.SpawnCapsuleDecoration then
            local skin = data.CapsuleSkin
            REVEL.SpawnDecorationFromTable(effect.Position, Vector.Zero, {
                Sprite = data.CapsuleSprite:GetFilename(),
                Anim = "Popped_Idle",
                RemoveOnAnimEnd = false,
                Start = function(e, data2, sprite2)
                    if skin ~= 0 then
                        sprite2:ReplaceSpritesheet(0, "gfx/effects/revelcommon/capsule_" .. CapsuleSkins[skin] .. ".png")
                        sprite2:ReplaceSpritesheet(2, "gfx/effects/revelcommon/capsule_" .. CapsuleSkins[skin] .. ".png")
                        sprite2:LoadGraphics()
                    end
                end,
            })
        end

        if not capsuleSpawn then
            if not doNotRemove then
                effect:Remove()
            end
        else
            data.DoNotRemove = doNotRemove
        end
    end
end

---@param entity Entity
---@param renderOffset Vector
---@param price? integer
---@param pos? Vector
---@param replaceOffset? Vector
function REVEL.RenderVanityPrice(entity, renderOffset, price, pos, replaceOffset)
    local data = entity:GetData()

    local renderPos = Isaac.WorldToScreen((pos or entity.Position) + (replaceOffset or Vector(0, -4)))
        + renderOffset - REVEL.room:GetRenderScrollOffset()

    local priceStr = tostring(price or data.Price)
    -- local width = #priceStr * 16

    local priceSprite = REVEL.RoomSprite(PriceSpriteParams)
    local priceVanitySprite = REVEL.RoomSprite(PriceVanitySpriteParams)

    if data.Discounted then
        priceSprite.Color = PRICE_DISCOUNT_COLOR
        priceVanitySprite.Color = PRICE_DISCOUNT_COLOR
    else
        priceSprite.Color = PRICE_COLOR
        priceVanitySprite.Color = PRICE_COLOR
    end

    for i = 1, #priceStr do
        local frame = tonumber(priceStr:sub(i, i))
        priceSprite:SetFrame(frame)
        priceSprite:RenderLayer(i - #priceStr + 1, renderPos)
    end

    --[[
        lungh 1: 1 -> 1
        lungh 2: 1 -> 0
                2 -> 1
    ]]

    priceVanitySprite:Render(renderPos + Vector(10, 12))
end

local function rewardShop_PostRender(_, effect, renderOffset)
    local data = effect:GetData()
    local reward = data.Reward
    local rewardData = data.RewardData

    if data.CapsuleSprite then
        local pos = Isaac.WorldToScreen(effect.Position)
            + renderOffset - REVEL.room:GetRenderScrollOffset()
        data.CapsuleSprite:RenderLayer(0, pos)
    end

    if rewardData.Sprites then
        for i, sprite in ripairs(rewardData.Sprites) do
            if rewardData.SpriteOffsets[i] then
                local pos = Isaac.WorldToScreen(effect.Position) + rewardData.SpriteOffsets[i]
                -- local pos = Isaac.WorldToScreen(effect.Position) + GetPickupOffset(i) 
                --     - CapsulePickupOffsetPerPickup[reward.Entities[i].Variant]
                    + renderOffset - REVEL.room:GetRenderScrollOffset()
                sprite:Render(pos)
            end
        end
    end

    if data.CapsuleSprite then
        local pos = Isaac.WorldToScreen(effect.Position)
            + renderOffset - REVEL.room:GetRenderScrollOffset()
        data.CapsuleSprite:RenderLayer(2, pos)
        data.CapsuleSprite:RenderLayer(3, pos)
    end

    -- Price text & vanity icon
    if not data.StopRenderingPrice and not data.Disabled then
        REVEL.RenderVanityPrice(effect, renderOffset)
    end
end

local function rewardShop_NewRoom()
    RewardRNG:SetSeed(REVEL.room:GetAwardSeed(), 38)

    if DoingDevilRoomTeleport then
        DoingDevilRoomTeleport = false
    -- elseif revel.data.run.level.didVshopDevilRoomTeleport then
    --     revel.data.run.level.didVshopDevilRoomTeleport = false
    --     local pos = Vector(
    --         revel.data.run.level.vShopDevilRoomTeleportPos[1],
    --         revel.data.run.level.vShopDevilRoomTeleportPos[2]                
    --     )
    --     GoToVanityShop(pos, true)
    end
end

REVEL.Rerolls.RegisterAsCollectible({
    IsRerollable = function(entity)
        return entity:GetData().Reward.Kind == RewardKinds.COLLECTIBLE
            and entity:GetData().Reward.Item
    end,
    GetItemId = function(entity)
        return entity:GetData().Reward.Item
    end,
    GetPersistId = function(entity)
        return tostring(entity.SubType)
    end,
    GetPool = function(entity)
        return entity:GetData().Reward.Pool
    end,
    DoReroll = function(entity, newItem)
        local data = entity:GetData()
        local reward = data.Reward
        reward.Item = newItem
        SetVanityCollectible(entity, newItem)
    end,
}, REVEL.ENT.PACT_SHOP)


-- Room and trapdoor on boss end

local TRAPDOOR_POS = Vector(40 * 2, 40 * 1)
local SHOP_ROOM_ID = "RevelationsVanityShop"
local SHOP_ITEM_META_NAME = "Vanity Shop Item"
local TRAPDOOR_SUBTYPE = 0
local TRAPDOOR_LADDER_SUBTYPE = 1
local TRAPDOOR_RENDERER_SUBTYPE = 2

local function SetupShopBackdrop()
    for i = 1, 2 do
        local eff = REVEL.ENT.DECORATION:spawn(REVEL.room:GetTopLeftPos(), Vector.Zero, nil)
        local sprite = eff:GetSprite()
        
        sprite:Load("gfx/backdrop/revelcommon/prank_shop_backdrop.anm2", true)

        if i == 1 then
            sprite:Play("base", true)

            eff:AddEntityFlags(BitOr(EntityFlag.FLAG_RENDER_FLOOR, EntityFlag.FLAG_RENDER_WALL))
        else
            sprite:Play("items_all", true)

            eff.Position = eff.Position - Vector(60, 60)
            eff.SpriteOffset = Vector(60, 60) * REVEL.WORLD_TO_SCREEN_RATIO
        end
    end
end

REVEL.PrankShopShader = REVEL.CCShader("PrankShop")
local s = REVEL.PrankShopShader
s:Set3WayWeight(400, 14, 4)
s:SetTemp(32)
s:SetTintShadows(0, 0.1, 0.15)
s:SetContrast(0.02)
s:SetSaturation(0.15)
s:SetRGB(1.35, 1.18, 1)
s:SetBrightness(0.15)

function s:OnUpdate()
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        self.Active = 1
    else
        self.Active = 0
    end
end

local function SetupShop(firstVisit)
    local tl = REVEL.room:GetTopLeftPos()
    local w = REVEL.room:GetGridWidth()
    
    SetupShopBackdrop()

    local ladder = Isaac.Spawn(
        REVEL.ENT.VANITY_TRAPDOOR.id, REVEL.ENT.VANITY_TRAPDOOR.variant, TRAPDOOR_LADDER_SUBTYPE,
        REVEL.GetGridPositionAtPos(tl + TRAPDOOR_POS), Vector.Zero, 
        nil
    )

    if firstVisit then
        local croom = StageAPI.GetCurrentRoom()

        -- Use metaentity to decide subtype before spawning
        local pactShopItems = croom.Metadata:Search{Name = SHOP_ITEM_META_NAME}

        for i, metaEntity in ipairs(pactShopItems) do
            local index = metaEntity.Index
            local pos = REVEL.room:GetGridPosition(index)

            -- left: completely random at or below current vanity
            -- middle: max affordable
            -- right: close to current, above more likely than below
            local rewardSubtype

            if i == 1 then
                -- get max reward
                rewardSubtype = CreateNewRewardSubtype(GetMaxRewardForPrice, REVEL.GetShrineVanity())
            elseif i == math.min(3, #pactShopItems) then
                if REVEL.GetShrineVanity() < REVEL.ShrineBalance.HighestPrice and RewardRNG:RandomFloat() < 0.65 then
                    -- pick one between +0 and +3 vanity if available
                    rewardSubtype = CreateNewRewardSubtype(ChooseRewardRandom, REVEL.GetShrineVanity(), 0, 3, 3, 3)
                else
                    -- pick one between -2 and -1 vanity
                    rewardSubtype = CreateNewRewardSubtype(ChooseRewardRandom, REVEL.GetShrineVanity(), 2, -1)
                end
            else
                -- random reward up to +0 vanity
                rewardSubtype = CreateNewRewardSubtype(ChooseRewardRandom, REVEL.GetShrineVanity(), nil, 0)
            end

            REVEL.DebugStringMinor(("Vanity: chosen reward %d, price %d (subtype %d) for index %d"):format(
                revel.data.run.level.shrineRewards[rewardSubtype].Kind, 
                revel.data.run.level.shrineRewards[rewardSubtype].Price, 
                rewardSubtype, 
                REVEL.room:GetGridIndex(pos)
            ))

            local pactShop = Isaac.Spawn(REVEL.ENT.PACT_SHOP.id, REVEL.ENT.PACT_SHOP.variant, rewardSubtype, pos, Vector.Zero, nil)
        end

        REVEL.DebugStringMinor("Setup vanity shop")
    else       
        local listIndex = tostring(StageAPI.GetCurrentRoomID())
        if revel.data.run.level.shrineRewardRooms[listIndex] then
            for idx, subtype in pairs(revel.data.run.level.shrineRewardRooms[listIndex]) do
                local pos = REVEL.room:GetGridPosition(tonumber(idx))
                Isaac.Spawn(REVEL.ENT.PACT_SHOP.id, REVEL.ENT.PACT_SHOP.variant, subtype, pos, Vector.Zero, nil)
                -- REVEL.DebugStringMinor("Respawning vanity shop subtype", subtype, "idx", idx)
            end
        end
    end
end

local PRANK_SHOP_EMPTY_SUBTYPE = 10

local function prankShop_Init(_, npc)
    if not REVEL.ENT.PRANK_SHOP:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    -- default is glacier
    if REVEL.STAGE.Tomb:IsStage() then
        sprite:Load("gfx/monsters/revel2/prank_stand_tomb.anm2", true)
    end

    data.Position = npc.Position
    npc.Mass = 500

    npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

    if revel.data.run.prankDiscount[REVEL.GetStageChapter()] then
        npc.SubType = PRANK_SHOP_EMPTY_SUBTYPE
    end

    if npc.SubType ~= PRANK_SHOP_EMPTY_SUBTYPE then
        sprite:Play("Idle", true)
    else
        sprite:Play("Empty", true)
    end
end

local function prankShop_Update(_, npc)
    if not REVEL.ENT.PRANK_SHOP:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    npc.Velocity = data.Position - npc.Position
    
    if npc.SubType ~= PRANK_SHOP_EMPTY_SUBTYPE then
        if not REVEL.MultiPlayingCheck(sprite, "Wheel_Win", "Wheel_Lose") then
            if REVEL.music:GetCurrentMusicID() == REVEL.SFX.VANITY_SHOP then
                local animDuration = 35
                local headBopFrame = 4
                local bopsPerAnimLoop = 2
                local beatsPerBop = 1
                local beatDuration = 60000 / MUSIC_BPM
                local musicTime = Isaac.GetTime() - ShopMusicStartTime

                local beatProgress = musicTime % (beatDuration * bopsPerAnimLoop * beatsPerBop)
                local frame = math.floor(beatProgress * animDuration / (beatDuration * bopsPerAnimLoop * beatsPerBop)
                    + headBopFrame) % animDuration

                sprite:SetFrame("Idle", frame)
            else
                REVEL.PlayIfNot(sprite, "Idle", true)
            end
        end

        local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)
        local exploded = false
        for _, e in ipairs(explosions) do
            if e.Position:DistanceSquared(npc.Position) < 80 ^ 2 then
                exploded = true
                break
            end
        end

        if exploded then
            npc.SubType = PRANK_SHOP_EMPTY_SUBTYPE
            sprite:Play("Death", true)
            StageAPI.GetCurrentRoom():SavePersistentEntities()
        end

        if sprite:IsEventTriggered("Clap") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_CLAP, 0.75, 0, false, 1)
        end
        if sprite:IsEventTriggered("Laugh") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BROWNIE_LAUGH, 1, 0, false, 1.1)
        end
    else
        if sprite:IsPlaying("Death") and sprite:IsEventTriggered("Spawn") then
            REVEL.SpawnDecorationFromTable(npc.Position + Vector(0, -0.01), Vector.Zero, {
                Sprite = sprite:GetFilename(),
                SkipFrames = sprite:GetFrame(),
                Anim = "Death",
                Update = function(_, _, sprite2)
                    if sprite2:IsEventTriggered("Whistle") then
                        REVEL.sfx:Play(REVEL.SFX.CALL_WHISTLE)
                    end
                    if sprite2:IsEventTriggered("Raspberry") then
                        REVEL.sfx:Play(SoundEffect.SOUND_FART)
                    end
                end,
            })
            sprite:Play("Empty", true)
        elseif not sprite:IsPlaying("Death") and not IsAnimOn(sprite, "Empty") then
            sprite:Play("Empty", true)
        end
    end
end

function GoToVanityShop(pos, instant)
    pos = pos or REVEL.room:GetTopLeftPos() + TRAPDOOR_POS

    local defaultMap = StageAPI.GetDefaultLevelMap()
    local extraRoomData = defaultMap:GetRoomDataFromRoomID(SHOP_ROOM_ID)
    local extraRoom
    if not extraRoomData then
        extraRoom = StageAPI.LevelRoom {
            SpawnSeed = REVEL.room:GetSpawnSeed(),
            Shape = RoomShape.ROOMSHAPE_1x1,
            RoomType = RevRoomType.VANITY,
            RoomsList = REVEL.RoomLists.RevelationsVanityShop,
            IsExtraRoom = true,
            Music = REVEL.SFX.VANITY_SHOP,
        }
        extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = SHOP_ROOM_ID})
    else
        ---@type LevelRoom
        extraRoom = defaultMap:GetRoom(extraRoomData)
    end

    local currentRoomData = StageAPI.GetDefaultLevelMap():GetCurrentRoomData()
    local mapId = currentRoomData and currentRoomData.MapID or REVEL.level:GetCurrentRoomIndex()

    extraRoom.PersistentData.FromDoor = "Main"
    extraRoom.PersistentData.ExitRoom = mapId
    extraRoom.PersistentData.ExitRoomPosition = {X = pos.X, Y = pos.Y + 40}
    
    if instant then 
        StageAPI.ExtraRoomTransition(
            extraRoomData.MapID, 
            nil, 
            nil, 
            StageAPI.DefaultLevelMapID, 
            nil, nil,
            pos + Vector(0, 40)
        )
    else
        StageAPI.ExtraRoomTransition(
            extraRoomData.MapID, 
            nil, 
            RoomTransitionAnim.PIXELATION, 
            StageAPI.DefaultLevelMapID, 
            nil, nil,
            pos + Vector(0, 40)
        )
    end
end

-- local LastSpawnedTrapdoor

local function vanityTrapdoor_SpawnCustomGrid(customGrid)
    local index = customGrid.GridIndex
    local persistData = customGrid.PersistentData
    
    local trapdoor = StageAPI.SpawnFloorEffect(
        REVEL.room:GetGridPosition(index), Vector.Zero, nil, 
        "gfx/grid/revelcommon/shrines/prank_trapdoor.anm2", true, REVEL.ENT.VANITY_TRAPDOOR.variant
    )
    trapdoor.SubType = TRAPDOOR_SUBTYPE
    -- LastSpawnedTrapdoor = EntityPtr(trapdoor)

    if REVEL.room:GetGridEntity(index) then
        REVEL.room:RemoveGridEntity(index, 0, false)
        -- REVEL.room:Update()
    end

    trapdoor:GetSprite():Play("Closed", true)

    -- effect renderer for lid to render above entities behind
    local renderer = Isaac.Spawn(
        REVEL.ENT.VANITY_TRAPDOOR.id, REVEL.ENT.VANITY_TRAPDOOR.variant, TRAPDOOR_RENDERER_SUBTYPE,
        trapdoor.Position, Vector.Zero,
        trapdoor
    )
    renderer:GetSprite():Load("gfx/blank.anm2", true)
    renderer:GetData().Trapdoor = EntityPtr(trapdoor)
end

local PlayerExtraAnimations = {
    "LightTravel",
    "FallIn",
    "JumpOut",
    "UseItem",
    "Jump",
    "TeleportUp",
    "TeleportDown",
    "Sad",
    "Happy",
    "Pickup",
}

---@param eff EntityEffect
local function vanityTrapdoor_PostEffectUpdate(_, eff)
    local data, sprite = eff:GetData(), eff:GetSprite()
    if eff.SubType == TRAPDOOR_SUBTYPE then
        if sprite:IsFinished("Open Animation") or sprite:IsFinished("Player Exit") then
            sprite:Play("Opened", true)
        end

        local touched, farEnough
        for _, player in ipairs(REVEL.players) do
            local dist = eff.Position:DistanceSquared(player.Position)
            if dist < (player.Size + 16) ^ 2 and not REVEL.MultiPlayingCheck(player:GetSprite(), PlayerExtraAnimations) then
                touched = player
            elseif dist > (player.Size + 16 + 40) ^ 2 then
                farEnough = true
            end
        end

        if farEnough and sprite:IsFinished("Closed") then
            sprite:Play("Open Animation", true)
        end

        if touched then
            if sprite:IsFinished("Opened") then
                for _, player in ipairs(REVEL.players) do
                    player.Velocity = Vector.Zero
                end

                GoToVanityShop(eff.Position)
                sprite:Play("Player Exit", true)

                data.Touched = true
            end
        end

    elseif eff.SubType == TRAPDOOR_LADDER_SUBTYPE then
        local touched, farEnough
        for _, player in ipairs(REVEL.players) do
            local dist = eff.Position:DistanceSquared(player.Position)
            if dist < (player.Size + 16) ^ 2 and not REVEL.MultiPlayingCheck(player:GetSprite(), PlayerExtraAnimations) then
                touched = player
            elseif dist > (player.Size + 16 + 40) ^ 2 then
                farEnough = true
            end
        end

        if not data.Init then
            data.Init = true

            data.WaitForFarEnough = touched or not farEnough
        end

        if data.WaitForFarEnough and farEnough then
            data.WaitForFarEnough = nil
        end

        if not data.WaitForFarEnough and touched then
            local currentRoom = StageAPI.GetCurrentRoom()
            local exitPos = currentRoom.PersistentData.ExitRoomPosition
            StageAPI.ExtraRoomTransition(
                currentRoom.PersistentData.ExitRoom, 
                nil, 
                RoomTransitionAnim.PIXELATION, 
                nil, nil, nil, 
                Vector(exitPos.X, exitPos.Y)
            )
        end
    end
end

---@param eff EntityEffect
local function vanityTrapdoor_PostEffectRender(_, eff)
    if eff.SubType == TRAPDOOR_RENDERER_SUBTYPE then
        local trapdoor = eff:GetData().Trapdoor.Ref
        if trapdoor then
            trapdoor:GetSprite():RenderLayer(1, Isaac.WorldToScreen(trapdoor.Position))
        end
    end
end

local function vanityRoom_RoomLoad(currentRoom, isFirstLoad, isExtraRoom)
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        SetupShop(isFirstLoad)
        StageAPI.ChangeRoomGfx(VanityShopRoomGfx)
    end
end

local function vanityRoom_PostRender()
    local isShopMusic = REVEL.music:GetCurrentMusicID() == REVEL.SFX.VANITY_SHOP
    if isShopMusic and ShopMusicStartTime < 0 then
        ShopMusicStartTime = Isaac.GetTime()
    elseif not isShopMusic and ShopMusicStartTime >= 0 then
        ShopMusicStartTime = -1
    end
end

local function GetTrapdoorPos()
    local pos = REVEL.room:GetTopLeftPos() + TRAPDOOR_POS
    local idx = REVEL.room:GetGridIndex(pos)

    -- Various entities to exclude
    local traps = REVEL.GetTrapTiles()

    idx = REVEL.FindFreeIndex(idx, true, true, traps)


    return REVEL.room:GetGridPosition(idx)
end

local function vanityTrapdoor_RoomClear()
    if REVEL.room:IsCurrentRoomLastBoss()
    and REVEL.GetShrineVanity() > 0
    and REVEL.IsLastChapterStage() then
        local pos = GetTrapdoorPos()
        REVEL.GRIDENT.VANITY_TRAPDOOR:Spawn(
            REVEL.room:GetGridIndex(pos)
        )
        Isaac.Spawn(1000, EffectVariant.POOF01, 0, pos, Vector.Zero, nil)
        REVEL.DebugStringMinor("Has vanity and is last boss, spawning vanity trapdoor...")
    end
end

--#region MirrorFireChest

-- Anims: Idle, Open, Appear, Opened

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.MIRROR_FIRE_CHEST.id,
    Variant = REVEL.ENT.MIRROR_FIRE_CHEST.variant
})

local function SeenNarcissusThisChapter()
    return REVEL.STAGE.Glacier:IsStage() and revel.data.seenNarcissusGlacier
        or REVEL.STAGE.Tomb:IsStage()    and revel.data.seenNarcissusTomb
end

local function mirrorFireChest_PreEntitySpawn(_, etype, variant, subtype, pos, vel, spawner, seed)
    if REVEL.ENT.MIRROR_FIRE_CHEST:matchesSpawn(etype, variant) 
    and not (
        REVEL.MirrorRoom.StageHasNarcLostBonus()
        and SeenNarcissusThisChapter()
    ) then
        return {
            StageAPI.E.DeleteMeNPC.T,
            StageAPI.E.DeleteMeNPC.V,
            0,
            seed,
        }
    end
end

---@param npc EntityNPC
local function mirrorFireChest_NpcUpdate(_, npc)
    if not REVEL.ENT.MIRROR_FIRE_CHEST:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    local currentRoom = StageAPI.GetCurrentRoom()
    local persistData = currentRoom and currentRoom.PersistentData or data

    if not currentRoom then
        REVEL.DebugToString("WARNING | Mirror Fire Chest spawned out of stageapi room, won't remember payment")
    end


    if not data.Init then
        data.Init = true

        data.Position = npc.Position
        data.Price = REVEL.ShrineBalance.MirrorFireChestPrice

        npc:AddEntityFlags(BitOr(
            EntityFlag.FLAG_NO_TARGET,
            EntityFlag.FLAG_NO_KNOCKBACK,
            EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK
        ))
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

        if persistData.Paid then
            sprite:Play("Opened", true)
        elseif REVEL.room:IsFirstVisit() then
            sprite:Play("Appear", true)
        else
            sprite:Play("Idle", true)
        end
    end

    npc.Velocity = data.Position - npc.Position

    npc.Mass = 50

    if sprite:IsFinished("Appear") then
        sprite:Play("Idle", true)
    end

    if sprite:IsFinished("Open") then
        sprite:Play("Opened", true)
    end

    if (
        not persistData.Paid
        and (
            REVEL.GetShrineVanity() >= data.Price
            or (TriggeredMorshuThisRoom and not TriggeredMorshu2ThisRoom)
        )
    )
    or sprite:IsPlaying("Opened")
    then
        for i, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(npc.Position) < (npc.Size + player.Size) ^ 2 then
                if not persistData.Paid then
                    if REVEL.GetShrineVanity() >= data.Price then
                        persistData.Paid = true
                        sprite:Play("Open", true)
                        REVEL.PlaySound(npc, SoundEffect.SOUND_CHEST_OPEN)
                        REVEL.AddShrineVanity(-data.Price)
                    elseif TriggeredMorshuThisRoom and not TriggeredMorshu2ThisRoom and not MorshuPlaying then
                        ShowMorshuAnim2()
                        TriggeredMorshu2ThisRoom = true
                    end
                elseif sprite:IsPlaying("Opened")
                and not REVEL.PlayerIsLost(player) then
                    -- use soul of the lost to play anim too
                    player:UseCard(Card.CARD_SOUL_LOST, BitOr(UseFlag.USE_NOANNOUNCER, UseFlag.USE_NOANIM))
                    -- player:GetEffects():AddNullEffect(NullItemID.ID_LOST_CURSE, true)
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIREDEATH_HISS, 0.85)

                    local playerRef = EntityPtr(player)

                    -- On exiting vanity shop, readd lost curse
                    REVEL.CallbackOnce(ModCallbacks.MC_POST_NEW_ROOM, function()
                        local player = playerRef.Ref
                        player = player and player:ToPlayer()
                        if player and not REVEL.PlayerIsLost(player) then
                            player:GetEffects():AddNullEffect(NullItemID.ID_LOST_CURSE, true)
                        end
                    end)
                end

                break
            end
        end
    end
end

---@param npc EntityNPC
---@param renderOffset Vector
local function mirrorFireChest_PostNpcRender(_, npc, renderOffset)
    if not REVEL.ENT.MIRROR_FIRE_CHEST:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()
    if sprite:GetAnimation() == "Idle" then
        REVEL.RenderVanityPrice(npc, renderOffset, nil, data.Position, Vector(0, 3))
    end
end

--#endregion MirrorFireChest

-----------------
-- Easter eggs --
-----------------

--#region Morshu

local NO_HUD_TIME = 15

-- Very large sprites, so do weird memory handling
-- mostly to avoid black boxes and cleanup asap

---@type Sprite[]
local MorshuSprites = {}
local LoadedMorshu = {false, false}
-- load only 1 at once as they're big images and isaac has few memory
local SpritesheetSwitchFrame = {
    {
        [0] = {0, "Part1.png"},
        [27] = {1, "Part2.png"},
    },
    {
        [0] = {0, "Part2.png"},
        [33] = {1, "Part3.png"},
    },
}
local FailedLoad = false -- true for duration of anim if load failed

-- late load only if needed for performance
local function LoadMorshuSprite(spriteIndex)
    if not LoadedMorshu[spriteIndex] then
        MorshuSprites[spriteIndex] = Sprite()
        MorshuSprites[spriteIndex].Scale = Vector.One * 1.2
        if spriteIndex == 1 then
            MorshuSprites[spriteIndex]:Load("gfx/effects/revelcommon/pranshu/youwantit.anm2", true)
        elseif spriteIndex == 2 then
            MorshuSprites[spriteIndex]:Load("gfx/effects/revelcommon/pranshu/mmmmmmm.anm2", true)        
        end
        LoadedMorshu[spriteIndex] = true
    end
end

local function UnloadMorshuSprites()
    MorshuSprites = {}
    LoadedMorshu[1] = false
    LoadedMorshu[2] = false
    REVEL.DelayFunction(REVEL.ClearCache, 0)
end

local WasHudOn = false
local PlayingAnim = nil

local function HideHUDAndThings()
    WasHudOn = REVEL.game:GetHUD():IsVisible()
    if WasHudOn then
        REVEL.game:GetHUD():SetVisible(false)
    end

    local makeInvisible = REVEL.ENT.PACT_SHOP:getInRoom()
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.PRANK_SHOP:getInRoom()))
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.VANITY_STATWHEEL:getInRoom()))
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.MIRROR_FIRE_CHEST:getInRoom()))
    for _, player in ipairs(REVEL.players) do 
        makeInvisible[#makeInvisible+1] = player 

        REVEL.LockPlayerControls(player, "Vanity")
    end

    for _, ent in ipairs(makeInvisible) do
        ent:GetData().WasVisible__Vanity = ent.Visible
        ent.Visible = false
    end

    REVEL.music:Pause()
    MorshuPlaying = true
end

local function ShowHUDAndThings()
    REVEL.game:GetHUD():SetVisible(WasHudOn)

    local makeInvisible = REVEL.ENT.PACT_SHOP:getInRoom()
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.PRANK_SHOP:getInRoom()))
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.VANITY_STATWHEEL:getInRoom()))
    REVEL.extend(makeInvisible, table.unpack(REVEL.ENT.MIRROR_FIRE_CHEST:getInRoom()))
    for _, player in ipairs(REVEL.players) do 
        makeInvisible[#makeInvisible+1] = player 

        REVEL.UnlockPlayerControls(player, "Vanity")
    end

    for _, ent in ipairs(makeInvisible) do
        if ent:GetData().WasVisible__Vanity then
            ent.Visible = true
        end
        ent:GetData().WasVisible__Vanity = nil
    end  

    REVEL.music:Resume()
    MorshuPlaying = false
end

-- Big boy images, need special handling

local function ShowMorshuAnim()
    REVEL.ClearCache()
    LoadMorshuSprite(1)
    HideHUDAndThings()

    -- local firstSpriteLayer = SpritesheetSwitchFrame[1][0][1]
    -- local firstSpriteImage = SpritesheetSwitchFrame[1][0][2]

    -- if REVEL.STAGE.Tomb:IsStage() then
    --     MorshuSprites[1]:ReplaceSpritesheet(firstSpriteLayer, "gfx/effects/revelcommon/pranshu/tomb/" .. firstSpriteImage)
    -- else
    --     MorshuSprites[1]:ReplaceSpritesheet(firstSpriteLayer, "gfx/effects/revelcommon/pranshu/glacier/" .. firstSpriteImage)
    -- end

    if REVEL.STAGE.Tomb:IsStage() then
        MorshuSprites[1]:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/tomb/Part1.png")
        MorshuSprites[1]:ReplaceSpritesheet(1, "gfx/effects/revelcommon/pranshu/tomb/Part2.png")
    else
        MorshuSprites[1]:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/glacier/Part1.png")
        MorshuSprites[1]:ReplaceSpritesheet(1, "gfx/effects/revelcommon/pranshu/glacier/Part2.png")
    end
    MorshuSprites[1]:LoadGraphics()

    REVEL.DelayFunction(NO_HUD_TIME, function()
        MorshuSprites[1]:Play("Idle", true)
        REVEL.sfx:Play(REVEL.SFX.MORSHU_1)
        PlayingAnim = 1
    end)

    REVEL.DebugStringMinor("Played morshu easter egg")
end

function ShowMorshuAnim2()
    REVEL.ClearCache()
    LoadMorshuSprite(2)
    HideHUDAndThings()
    
    -- local firstSpriteLayer = SpritesheetSwitchFrame[2][0][1]
    -- local firstSpriteImage = SpritesheetSwitchFrame[2][0][2]

    -- if REVEL.STAGE.Tomb:IsStage() then
    --     MorshuSprites[2]:ReplaceSpritesheet(firstSpriteLayer, "gfx/effects/revelcommon/pranshu/tomb/" .. firstSpriteImage)
    -- else
    --     MorshuSprites[2]:ReplaceSpritesheet(firstSpriteLayer, "gfx/effects/revelcommon/pranshu/glacier/" .. firstSpriteImage)
    -- end
    
    if REVEL.STAGE.Tomb:IsStage() then
        MorshuSprites[2]:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/tomb/Part2.png")
        MorshuSprites[2]:ReplaceSpritesheet(1, "gfx/effects/revelcommon/pranshu/tomb/Part3.png")
    else
        MorshuSprites[2]:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/glacier/Part2.png")
        MorshuSprites[2]:ReplaceSpritesheet(1, "gfx/effects/revelcommon/pranshu/glacier/Part3.png")
    end
    MorshuSprites[2]:LoadGraphics()

    REVEL.DelayFunction(NO_HUD_TIME, function()
        MorshuSprites[2]:Play("Idle", true)
        REVEL.sfx:Play(REVEL.SFX.MORSHU_2)
        PlayingAnim = 2
    end)
end

local OddSpriteFrameUpdate = false

local function morshu_PostUpdate()
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        for i = 1, 2 do
            if PlayingAnim == i then 
                if MorshuSprites[i]:IsPlaying("Idle") then
                    -- MorshuSprites[i]:SetFrame(FRAME or 10)
                    MorshuSprites[i]:Update()

                    if not FailedLoad then    
                        local frame = MorshuSprites[i]:GetFrame()
                        -- if SpritesheetSwitchFrame[i][frame + 1] then
                        --     local layerId = SpritesheetSwitchFrame[i][frame + 1][1]
                        --     local otherLayer = 1 - layerId
                        --     local imageName = SpritesheetSwitchFrame[i][frame + 1][2]
                        --     local spritePrefix = "gfx/effects/revelcommon/pranshu/glacier/"
                        --     if REVEL.STAGE.Tomb:IsStage() then
                        --         spritePrefix = "gfx/effects/revelcommon/pranshu/tomb/"
                        --     end

                        --     -- try to juggle cache
                        --     MorshuSprites[i]:ReplaceSpritesheet(otherLayer, "gfx/ui/none.png")
                        --     MorshuSprites[i]:LoadGraphics()
                        --     REVEL.ClearCache()
                        --     MorshuSprites[i]:ReplaceSpritesheet(layerId, spritePrefix .. imageName)
                        --     MorshuSprites[i]:LoadGraphics()
                        --     REVEL.DebugToString("Swapped sprite at frame", frame, "layerId", layerId, "imageName", imageName)
                        --     replaced = true
                        -- end

                        -- Do not check immediately to make sure the sprite is there if it is
                        local checkAfterFrames = 1

                        -- local tl = Vector(-191, -239)
                        -- center pixel should not be 0,0,0,0, if it is then load failure
                        -- and stop rendering
                        -- only check in change frames to minimize access to gettexel which can make
                        -- the black square issue even worse if spammed
                        if SpritesheetSwitchFrame[i][frame - checkAfterFrames]
                        then
                            local c = Vector(0, -50)
                            local checkLayer = SpritesheetSwitchFrame[i][frame - checkAfterFrames][1]

                            -- weird hardcoding: for some reason sprite 2 layer 0 doesn't work
                            -- and always returns 0,0,0,0, so just do not check there and hope for the best

                            if i ~= 2 or checkLayer ~= 0 then
                                local testTexel = MorshuSprites[i]:GetTexel(c, Vector.Zero, 1, checkLayer)
                                -- REVEL.DebugLog("check", testTexel, checkLayer, MorshuSprites[i])
                                -- _G.MorshuSprites = MorshuSprites 

                                if testTexel.Alpha == 0 then
                                    FailedLoad = true
                                    REVEL.DebugToString("Pranshu: failed loading texture due to too big")
                                end
                            end
                        end
                    end
                else
                    UnloadMorshuSprites()
                    REVEL.DelayFunction(NO_HUD_TIME, ShowHUDAndThings)
                    PlayingAnim = nil
                    FailedLoad = false
                end
            end
        end
    end
end

-- Needs render due to input triggered check
local function morshu_PostRender()
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        if not TriggeredMorshuThisRoom then
            -- check in update due to IsActionTriggered wonkiness
            for _, player in ipairs(REVEL.players) do
                if REVEL.room:GetGridIndex(player.Position) == 46
                and Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex)
                then
                    local bombs = Isaac.FindByType(EntityType.ENTITY_BOMB)
                    local bomb = REVEL.getClosestInTable(bombs, player)
                    if bomb then
                        bomb:GetData().MorshuTrigger = true
                        TriggeredMorshuThisRoom = true
                        MorshuPlaying = true
                        break
                    end
                end
            end
        end
        for i = 1, 2 do
            if PlayingAnim == i then 
                if MorshuSprites[i]:IsPlaying("Idle") then

                    if not FailedLoad then
                        local pos = Vector(REVEL.GetScreenCenterPosition().X, REVEL.GetScreenBottomRight().Y)
                        MorshuSprites[i]:Render(pos)
                    else
                        local pos = REVEL.GetScreenCenterPosition()
                        local lines = {
                            "Loading pranshu failed! The texture is too big for your",
                            "mod loadout, try with less mods. We are very sorry for the",
                            "disappointment. We know you were looking forward to this",
                            "easter egg obtained by placing a bomb in a very specific",
                            "part of a special room; congratulations, by the way! We",
                            "were worried the hint in the rope and latern in the",
                            "side of the shop would have been too hard to understand.",
                            "We are instead glad for users to have caught on that.",
                            "Speaking of, 'SSSAD '"
                        }
                        local yoff = 0
                        for _, line in ipairs(lines) do
                            Isaac.RenderText(line, pos.X - 150, pos.Y - 100 + yoff, 1, 1, 1, 1)
                            yoff = yoff + 12
                        end
                    end
                end
            end
        end
    end
end

local function morshu_PostEntityRemove(_, entity)
    if entity:GetData().MorshuTrigger then
        ShowMorshuAnim()
    end
end

local function morshu_PostNewRoom()
    TriggeredMorshuThisRoom = false
    TriggeredMorshu2ThisRoom = false
    OddSpriteFrameUpdate = false
    PlayingAnim = nil
end

local function morshu_player_EntityTakeDmg(_, player)
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY
    and player:GetData().WasVisible__Vanity ~= nil 
    then
        return false
    end
end

--#endregion Morshu

-- Casino night room (yes)

--#region CasinoNight

REVEL.SUPER_FUN_MUSIC = Music.MUSIC_CREDITS_ALT
REVEL.SUPER_FUN_PITCH = 1.5

local CASINO_NIGHT_ROOM_ID = "CasinoNightVanity"

local SpawnedDoorOutline = false
local SeqProg = {}
local LastSeqPress
local ShowingFunScreen = false
local FinishedFunScreenFade = false

local CasinoNightShader = REVEL.CCShader("CasinoNight")
local s = CasinoNightShader
s:Set3WayWeight(400, 14, 4)
s:SetTemp(45)
s:SetTintShadows(0, 0.1, 0.15)
s:SetContrast(0.1)
s:SetSaturation(0.20)
s:SetRGB(1.35, 1.18, 1)
s:SetBrightness(0.1)

local DARK_AMOUNT = 0.8

function s:OnUpdate()
    self.Active = StageAPI.GetCurrentRoomType() == RevRoomType.CASINO and 1 or 0
end

local WasCasinoRoom = false

local function casinoNight_PostUpdate()
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY
    and not SpawnedDoorOutline then
        local slot = DoorSlot.UP0
        local pos = REVEL.room:GetDoorSlotPosition(slot)
        if REVEL.GetCustomDoorBySlot(slot) then
            return
        end

        if not REVEL.room:GetDoor(slot) then
            for _, player in ipairs(REVEL.players) do
                if (
                    player:HasCollectible(CollectibleType.COLLECTIBLE_RED_KEY)
                    or player:GetCard(0) == Card.CARD_CRACKED_KEY
                ) and player.Position:DistanceSquared(pos) < 160 ^ 2
                then
                    SpawnedDoorOutline = true
                    Isaac.Spawn(
                        1000, EffectVariant.DOOR_OUTLINE, 0,
                        pos + Vector(0, 24), Vector.Zero, nil
                    )
                end
            end
        end
    elseif StageAPI.GetCurrentRoomType() == RevRoomType.CASINO and WasCasinoRoom then
        REVEL.Darken(DARK_AMOUNT, 100)
    end
end

local CASINO_DOOR_TYPE = "CasinoDoor"

local CasinoDoor = StageAPI.CustomDoor(
    CASINO_DOOR_TYPE, 
    "gfx/grid/door_01_normaldoor.anm2", 
    nil, nil, nil, nil, 
    false,
    true
)

local function redDoor_PostSpawnCustomDoor(door, data, sprite, doorData, customGrid, force, respawning)
    for i = 0, 4 do
        sprite:ReplaceSpritesheet(i, "gfx/grid/revelcommon/doors/prank_casino_door.png")
    end
    sprite:LoadGraphics()
end

local function SpawnCasinoDoor()
    local defaultMap = StageAPI.GetDefaultLevelMap()
    local extraRoomData = defaultMap:GetRoomDataFromRoomID(CASINO_NIGHT_ROOM_ID)
    local extraRoom
    if not extraRoomData then
        extraRoom = StageAPI.LevelRoom {
            SpawnSeed = REVEL.room:GetSpawnSeed() + 2,
            Shape = RoomShape.ROOMSHAPE_1x1,
            RoomType = RevRoomType.CASINO,
            RoomsList = REVEL.RoomLists.RevelationsVanityCasino,
            IsExtraRoom = true,
            Music = REVEL.SFX.VANITY_CASINO
        }
        extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = CASINO_NIGHT_ROOM_ID})
    else
        extraRoom = defaultMap:GetRoom(extraRoomData)
    end
    StageAPI.SpawnCustomDoor(DoorSlot.UP0, extraRoomData.MapID, StageAPI.DefaultLevelMapID, CASINO_DOOR_TYPE)
end

---@param itemType CollectibleType
---@param rng RNG
---@param player EntityPlayer
---@param useFlags UseFlag
---@param activeSlot ActiveSlot
---@return boolean | nil | {Discharge: boolean, Remove: boolean, ShowAnim: boolean}
local function casinoNight_RedKey_UseItem(_, itemType, rng, player, useFlags, activeSlot)
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        local pos = REVEL.room:GetDoorSlotPosition(DoorSlot.UP0)
        local index = REVEL.room:GetGridIndex(pos)
        local customDoors = StageAPI.GetCustomDoors()
        
        for _, door in ipairs(customDoors) do
            if door.GridIndex == index then
                return
            end
        end

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom.PersistentData.HasCasinoDoor then
            return
        end

        if player.Position:DistanceSquared(pos) < 160 ^ 2 then
            local doorOutlines = Isaac.FindByType(1000, EffectVariant.DOOR_OUTLINE)
            for _, doorOutline in ipairs(doorOutlines) do
                if doorOutline.Position:DistanceSquared(pos) < 80^2 then
                    doorOutline:Remove()
                end
            end

            SpawnCasinoDoor()
            REVEL.sfx:Play(SoundEffect.SOUND_UNLOCK00)
            REVEL.PlayJingleForRoom(REVEL.SFX.SECRET_JINGLE)
            REVEL.music:Queue(REVEL.SFX.VANITY_SHOP)
            currentRoom.PersistentData.HasCasinoDoor = true

            REVEL.DebugStringMinor("Spawned vanity casino door")

            return {
                Discharge = true,
                ShowAnim = true,
            }
        end
    end
end

local SuperFunSpriteParams = {
    Anm2 = "gfx/effects/revelcommon/pranshu/even_better/super_fun.anm2",
    Animation = "base",
}
local BaseSpriteSize = Vector(720, 504)
local ShowedFunTime = -1

local function ShowFunScreen()
    local superFunSprite = REVEL.RoomSprite(SuperFunSpriteParams)

    if REVEL.STAGE.Glacier:IsStage() then
        superFunSprite:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/even_better/fun_glacier.png")
    elseif REVEL.STAGE.Tomb:IsStage() then
        superFunSprite:ReplaceSpritesheet(0, "gfx/effects/revelcommon/pranshu/even_better/fun_tomb.png")
    end
    superFunSprite:LoadGraphics()
    local screenHeight = REVEL.GetScreenBottomRight().Y
    superFunSprite.Scale = Vector.One / BaseSpriteSize.Y * screenHeight
    REVEL.music:PitchSlide(REVEL.SUPER_FUN_PITCH)

    for _, player in ipairs(REVEL.players) do
        REVEL.LockPlayerControls(player, "SuperFun")
    end

    ShowedFunTime = Isaac.GetTime()
    ShowingFunScreen = true
    FinishedFunScreenFade = false
    REVEL.FadeOut(30, true, 1)
end

---@param player EntityPlayer
local function casinoNight_PostPlayerRender(_, player)
    -- Workaround for use item callbacks not working with red key
    if not REVEL.game:IsPaused()
    and StageAPI.GetCurrentRoomType() == RevRoomType.VANITY
    then
        local usedRedKey = false
        if player:HasCollectible(CollectibleType.COLLECTIBLE_RED_KEY)
        and player:GetActiveCharge() >= REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_RED_KEY).MaxCharges
        and Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex)
        then
            usedRedKey = true
            player:AnimateCollectible(CollectibleType.COLLECTIBLE_RED_KEY)
            player:DischargeActiveItem()
        elseif player:GetCard(0) == Card.CARD_CRACKED_KEY
        and Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
        then
            usedRedKey = true
            player:AnimateCard(Card.CARD_CRACKED_KEY)
            player:SetCard(0, Card.CARD_NULL)
        end
    
        if usedRedKey then
            -- Nil ununused stuff, no need to fake it
            casinoNight_RedKey_UseItem(_, CollectibleType.COLLECTIBLE_RED_KEY, nil, player, nil, nil)
        end
    end
end

local AddedCallback = false

-- for optimization, as it's a rarely used thing
local function CheckUseitemWorkaroundCallback()
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY
    and not AddedCallback then
        AddedCallback = true
        revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, casinoNight_PostPlayerRender)
    elseif StageAPI.GetCurrentRoomType() ~= RevRoomType.VANITY
    and AddedCallback then
        AddedCallback = false
        revel:RemoveCallback(ModCallbacks.MC_POST_PLAYER_RENDER, casinoNight_PostPlayerRender)
    end
end

local function SetupCasinoBackdrop()
    for i = 1, 2 do
        local eff = REVEL.ENT.DECORATION:spawn(REVEL.room:GetTopLeftPos(), Vector.Zero, nil)
        local sprite = eff:GetSprite()
        
        sprite:Load("gfx/backdrop/revelcommon/prank_shop_backdrop.anm2", false)
        sprite:ReplaceSpritesheet(0, "gfx/backdrop/revelcommon/meme/prank_shop_casino_base.png")
        sprite:ReplaceSpritesheet(1, "gfx/backdrop/revelcommon/meme/prank_shop_casino_items.png")
        sprite:LoadGraphics()

        if i == 1 then
            sprite:Play("base", true)

            eff:AddEntityFlags(BitOr(EntityFlag.FLAG_RENDER_FLOOR, EntityFlag.FLAG_RENDER_WALL))
        else
            sprite:Play("items_all", true)

            eff.Position = eff.Position - Vector(60, 60)
            eff.SpriteOffset = Vector(60, 60) * REVEL.WORLD_TO_SCREEN_RATIO
        end
    end
end

local EntitiesToLight = {
    [REVEL.ENT.VANITY_STATWHEEL.id] = {REVEL.ENT.VANITY_STATWHEEL.variant}
}
local LightColors = {
    REVEL.HSVtoColor(0, 1, 1),
    REVEL.HSVtoColor(55 / 360, 1, 1),
    REVEL.HSVtoColor(219 / 360, 1, 1),
}

local function casinoNight_RoomLoad(currentRoom, isFirstLoad, isExtraRoom)
    if StageAPI.GetCurrentRoomType() == RevRoomType.VANITY then
        SpawnedDoorOutline = currentRoom.PersistentData.HasCasinoDoor
    elseif StageAPI.GetCurrentRoomType() == RevRoomType.CASINO then
        SeqProg = {}

        -- blank, backdrop rendered manually
        StageAPI.ChangeRoomGfx(VanityShopRoomGfx)
        SetupCasinoBackdrop()
        
        -- Spotlights!
        local w, h = REVEL.GetRoomSize()
        REVEL.SpawnMultiSpotlights(Color(0.5, 0.75, 1, 0.5), w * 0.28, h * 0.28, 2, 0, 3, nil, nil, nil, true)

        -- Lights

        for id, variants in pairs(EntitiesToLight) do
            for _, variant in ipairs(variants) do
                local ents = Isaac.FindByType(id, variant)
                for _, entity in ipairs(ents) do
                    REVEL.SpawnLightAtEnt(entity, REVEL.randomFrom(LightColors), 2, nil, nil, true)
                end
            end
        end

        WasCasinoRoom = true
        REVEL.Darken(DARK_AMOUNT, 100)

        if isFirstLoad then
            local defaultMap = StageAPI.GetDefaultLevelMap()
            local extraRoomData = defaultMap:GetRoomDataFromRoomID(SHOP_ROOM_ID)
            -- check if it exists just in case (reloads and whatnot)
            if not extraRoomData then
                local extraRoom = StageAPI.LevelRoom {
                    SpawnSeed = REVEL.room:GetSpawnSeed() - 2,
                    Shape = RoomShape.ROOMSHAPE_1x1,
                    RoomType = RevRoomType.VANITY,
                    RoomsList = REVEL.RoomLists.RevelationsVanityShop,
                    IsExtraRoom = true,
                    Music = REVEL.SFX.VANITY_SHOP
                }
                extraRoomData = defaultMap:AddRoom(extraRoom, {RoomID = SHOP_ROOM_ID})
            end

            StageAPI.SpawnCustomDoor(DoorSlot.DOWN0, extraRoomData.MapID, StageAPI.DefaultLevelMapID, CASINO_DOOR_TYPE)
        end
    elseif WasCasinoRoom then
        WasCasinoRoom = false
        REVEL.Darken(0, 0)
    end
end

---@param currentRoom LevelRoom
local function casinoNight_PostSelectRoomMusic(currentRoom, musicID, baseRoomType, roomId, rng)
    if currentRoom:GetType() == RevRoomType.CASINO and ShowingFunScreen then
        if FinishedFunScreenFade then
            return REVEL.SUPER_FUN_MUSIC
        else
            return REVEL.SFX.BLANK_MUSIC
        end
    end
end

local function superFun_PostRender()
    if StageAPI.GetCurrentRoomType() ~= RevRoomType.CASINO then return end

    if ShowingFunScreen then
        if REVEL.IsFullyFaded() then
            REVEL.FadeIn(15)
            FinishedFunScreenFade = true
        end

        if FinishedFunScreenFade and Isaac.GetTime() - ShowedFunTime > 200 then
            StageAPI.RenderBlackScreen(1)
            local superFunSprite = REVEL.RoomSprite(SuperFunSpriteParams)
            superFunSprite:Render(REVEL.GetScreenCenterPosition())

            for _, player in ipairs(REVEL.players) do
                if Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex)
                or Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, player.ControllerIndex)
                or Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex)
                or REVEL.game:IsPaused()
                then
                    ShowingFunScreen = false
                    REVEL.music:ResetPitch()

                    for _, player2 in ipairs(REVEL.players) do
                        REVEL.UnlockPlayerControls(player2, "SuperFun")
                    end

                    if REVEL.DoingScreenFade() then
                        REVEL.FadeIn(15)
                    end

                    break
                end
            end
        end
    elseif not REVEL.game:IsPaused() then
        for _, player in ipairs(REVEL.players) do
            local seqProg = SeqProg[REVEL.GetPlayerID(player)] or 1
            local soundStart = 4

            if (
                Input.IsActionTriggered(InputSequence[seqProg].Action, player.ControllerIndex) 
                or (InputSequence[seqProg].Key and Input.IsButtonTriggered(InputSequence[seqProg].Key, 0))
            )
            and (not LastSeqPress or Isaac.GetTime() - LastSeqPress < 3000)
            then
                seqProg = seqProg + 1
                LastSeqPress = Isaac.GetTime()
    
                if seqProg >= soundStart then
                    REVEL.sfx:Play(
                        SoundEffect.SOUND_THUMBSUP, 
                        0.5, 0, false, 
                        REVEL.Lerp2Clamp(0.75, 1.25, seqProg, soundStart, #InputSequence)
                    )
                    local eff = REVEL.SpawnCustomGlow(
                        player, 
                        "Wave",
                        "gfx/itemeffects/revelcommon/haphephobia_wave.anm2"
                    )
                    eff.Color = Color(1, 1, 1, 1, 0.5, 0.5, 0.5)
                end
    
                if seqProg > #InputSequence then
                    ShowFunScreen()
                    seqProg = nil
                    LastSeqPress = nil
                end
            elseif seqProg > 1 then
                LastSeqPress = nil
                for action = ButtonAction.ACTION_LEFT, ButtonAction.ACTION_MENUBACK do
                    if Input.IsActionTriggered(action, player.ControllerIndex) then
                        if seqProg >= soundStart then
                            REVEL.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 0.5)
                        end
                        seqProg = nil
                        break
                    end
                end
            end
    
            SeqProg[REVEL.GetPlayerID(player)] = seqProg    
        end
    end
end

local function superFun_Player_EntityTakeDmg()
    if ShowingFunScreen then
        return false
    end
end

--#endregion CasinoNight

-- Commands

local function vanity_ExecuteCmd(_, command, params)
    if command == "vanityshop" or command == "vshop" then
        GoToVanityShop(nil, true)
    elseif command == "addvanity" or command == "addv" then
        local x = tonumber(params)
        if not x then
            error("addvanity needs a number!")
        end
        REVEL.AddShrineVanity(x)
        REVEL.DebugLog(("Added %d vanity"):format(x))
    end
end

-- Callbacks

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, casinoNight_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, morshu_PostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, shrineVanity_NewLevel)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, morshu_PostRender)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, shrineVanityHUD_PostRender)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, vanityRoom_PostRender)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_HUD_RENDER, 0, superFun_PostRender)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, rewardShop_Init, REVEL.ENT.PACT_SHOP.variant)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, rewardShop_PostUpdate, REVEL.ENT.PACT_SHOP.variant)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, rewardShop_PostRender, REVEL.ENT.PACT_SHOP.variant)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, vanityTrapdoor_PostEffectUpdate, REVEL.ENT.VANITY_TRAPDOOR.variant)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, vanityTrapdoor_PostEffectRender, REVEL.ENT.VANITY_TRAPDOOR.variant)

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, prankShop_Init, REVEL.ENT.PRANK_SHOP.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, prankShop_Update, REVEL.ENT.PRANK_SHOP.id)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, mirrorFireChest_NpcUpdate, REVEL.ENT.MIRROR_FIRE_CHEST.id)
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mirrorFireChest_PostNpcRender, REVEL.ENT.MIRROR_FIRE_CHEST.id)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mirrorFireChest_PreEntitySpawn)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, morshu_player_EntityTakeDmg, EntityType.ENTITY_PLAYER)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, superFun_Player_EntityTakeDmg, EntityType.ENTITY_PLAYER)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, morshu_PostEntityRemove, EntityType.ENTITY_BOMB)

-- Doesn't work with red key without a fitting door slot for now
-- revel:AddCallback(ModCallbacks.MC_USE_ITEM, casinoNight_RedKey_UseItem, CollectibleType.COLLECTIBLE_RED_KEY)
-- Temporary: check for adding the workaround callback
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, CheckUseitemWorkaroundCallback)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, CheckUseitemWorkaroundCallback)

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, rewardShop_NewRoom)
-- revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, vanityTrapdoor_NewRoom)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, morshu_PostNewRoom)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_DOOR, 1, redDoor_PostSpawnCustomDoor, CASINO_DOOR_TYPE)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_ROOM_MUSIC, 1, casinoNight_PostSelectRoomMusic)    
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, vanityTrapdoor_SpawnCustomGrid, REVEL.GRIDENT.VANITY_TRAPDOOR.Name)    
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 1, vanityTrapdoor_RoomClear)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, vanityRoom_RoomLoad)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, casinoNight_RoomLoad)

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, vanity_ExecuteCmd)


end
REVEL.PcallWorkaroundBreakFunction()