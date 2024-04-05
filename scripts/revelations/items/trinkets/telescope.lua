local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
    
-- Telescope
local function ItemPickupTelescope(player)
    if player:HasTrinket(REVEL.ITEM.TELESCOPE.id) then
        player:AddCacheFlags(CacheFlag.CACHE_ALL)
        player:EvaluateItems()
    end
end

local evalZodiacs = {
    CollectibleType.COLLECTIBLE_TAURUS,
    CollectibleType.COLLECTIBLE_CANCER,
    CollectibleType.COLLECTIBLE_CAPRICORN
}

for _, zodiac in ipairs(evalZodiacs) do
    StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 2, ItemPickupTelescope, zodiac)
end

local GridEntitiesForLeo = {}

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, player in ipairs(REVEL.players) do
        local data = REVEL.GetData(player)
        if data.GeminiTriggered then
            data.GeminiTriggered = nil
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            player:EvaluateItems()
        end
    end

    GridEntitiesForLeo = {}
end)

local prevBombs, prevKeys, prevCoins
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if not player:HasTrinket(REVEL.ITEM.TELESCOPE.id) then
        prevBombs, prevKeys, prevCoins = nil, nil, nil
        return
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_PISCES) then
        for _, tear in ipairs(Isaac.FindByType(EntityType.ENTITY_TEAR, -1, -1, false, false)) do
            if not REVEL.GetData(tear).MassSet then
                REVEL.GetData(tear).MassSet = true
                tear.Mass = tear.Mass * 2
            end
        end
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_LIBRA) then
        local bombs, keys, coins = player:GetNumBombs(), player:GetNumKeys(), player:GetNumCoins()
        if prevBombs and prevKeys and prevCoins then
            if math.random(1, 5) == 1 then
                local variant, subtype
                if prevBombs > bombs then
                    if math.random(1, 2) == 1 then
                        variant, subtype = PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY
                    else
                        variant, subtype = PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL
                    end
                end

                if prevKeys > keys then
                    if math.random(1, 2) == 1 then
                        variant, subtype = PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY
                    else
                        variant, subtype = PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL
                    end
                end

                if prevCoins > coins then
                    if math.random(1, 2) == 1 then
                        variant, subtype = PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL
                    else
                        variant, subtype = PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL
                    end
                end

                if variant or subtype then
                    local freePos = REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true)
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, variant, subtype or 0, freePos, Vector.Zero, player)
                end
            end
        end

        prevBombs, prevKeys, prevCoins = bombs, keys, coins
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_AQUARIUS) then
        for _, creep in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, -1, false, false)) do
            if not REVEL.GetData(creep).Largened then
                REVEL.GetData(creep).Largened = true
                REVEL.SetCreepData(creep)
                REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
            end
        end
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_LEO) then
        for grindex, _ in pairs(GridEntitiesForLeo) do
            local grid = REVEL.room:GetGridEntity(grindex)
            if grid and REVEL.IsGridBroken(grid) then
                for i = 1, 4 do
                    player:FireTear(REVEL.room:GetGridPosition(grindex), Vector.FromAngle(i * 90) * 10, true, true, false)
                end

                GridEntitiesForLeo[grindex] = nil
            end
        end

        for i = 0, REVEL.room:GetGridSize() do
            local grid = REVEL.room:GetGridEntity(i)
            if grid and not REVEL.IsGridBroken(grid) then
                GridEntitiesForLeo[i] = true
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, e)
    local has
    for _, player in ipairs(REVEL.players) do
        if player:HasTrinket(REVEL.ITEM.TELESCOPE.id) and player:HasCollectible(CollectibleType.COLLECTIBLE_SCORPIO) then
            has = true
            break
        end
    end

    if e:IsActiveEnemy(true) and not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and e:ToNPC() and not REVEL.GetData(e).__manuallyRemoved and has then
        local creep = REVEL.SpawnCreep(EffectVariant.PLAYER_CREEP_GREEN, 0, e.Position, REVEL.player, false)
        REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(player)
    player = player:ToPlayer()
    if player:HasTrinket(REVEL.ITEM.TELESCOPE.id) then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_VIRGO) then
            local effects = player:GetEffects()
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS, true)
            effects:GetCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS).Cooldown = 210
        end

        if player:HasCollectible(CollectibleType.COLLECTIBLE_GEMINI) then
            REVEL.GetData(player).GeminiTriggered = true
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            player:EvaluateItems()
        end
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags, source, cooldown)
    if source and source.Entity and e:ToNPC() then
        if amount == 18 and HasBit(flags, DamageFlag.DAMAGE_COUNTDOWN) and source.Type == 1 then
            local hasAriesTelescope
            for _, player in ipairs(REVEL.players) do
                if GetPtrHash(player) == GetPtrHash(source.Entity) and player:HasTrinket(REVEL.ITEM.TELESCOPE.id) and player:HasCollectible(CollectibleType.COLLECTIBLE_ARIES) then
                    hasAriesTelescope = true
                    break
                end
            end

            if hasAriesTelescope then
                e:TakeDamage(19, 0, source, 0)
            end
        elseif source.Type == EntityType.ENTITY_TEAR then
            for _, tear in ipairs(Isaac.FindByType(source.Type, source.Variant, source.Entity.SubType, false, false)) do
                if GetPtrHash(tear) == GetPtrHash(source.Entity) then
                    source = tear
                    break
                end
            end

            if source.Parent then
                local p = source.Parent:ToPlayer()
                if p and p:HasTrinket(REVEL.ITEM.TELESCOPE.id) and p:HasCollectible(CollectibleType.COLLECTIBLE_SAGITTARIUS) then
                    source.CollisionDamage = source.CollisionDamage * 1.5
                end
            end
        end
    end
end)

local geminiRNG = REVEL.RNG()
revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if player:HasTrinket(REVEL.ITEM.TELESCOPE.id) then
        if flag == CacheFlag.CACHE_SPEED and player:HasCollectible(CollectibleType.COLLECTIBLE_TAURUS) then
            player.MoveSpeed = player.MoveSpeed + 0.3
        elseif flag == CacheFlag.CACHE_FIREDELAY and player:HasCollectible(CollectibleType.COLLECTIBLE_CANCER) then
            player.MaxFireDelay = player.MaxFireDelay - 2
        elseif flag == CacheFlag.CACHE_LUCK and player:HasCollectible(CollectibleType.COLLECTIBLE_CAPRICORN) then
            player.Luck = player.Luck + 1
        end
    end

    if flag == CacheFlag.CACHE_FAMILIARS then
        if REVEL.GetData(player).GeminiTriggered and player:HasTrinket(REVEL.ITEM.TELESCOPE.id) then
            local numGeminis = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_GEMINI) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            player:CheckFamiliar(FamiliarVariant.GEMINI, 0, geminiRNG:GetRNG())
            player:CheckFamiliar(REVEL.ENT.ANGRY_GEMINI.variant, numGeminis, geminiRNG:GetRNG())
        else
            player:CheckFamiliar(REVEL.ENT.ANGRY_GEMINI.variant, 0, geminiRNG:GetRNG())
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    local sprite = familiar:GetSprite()

    if sprite:IsFinished("Rage") then
        sprite:Play("Walk02", true)
    end

    if not sprite:IsPlaying("Rage") and not sprite:IsPlaying("Walk02") then
        sprite:Play("Rage", true)
    end

    local closest = REVEL.getClosestEnemy(familiar, false, true, true, true)
    if closest then
        familiar.Velocity = familiar.Velocity * 0.95 + (closest.Position - familiar.Position):Resized(1)
    elseif familiar.Player then
        familiar.Velocity = familiar.Velocity * 0.95 + (familiar.Player.Position - familiar.Position):Resized(1)
    else
        familiar.Velocity = familiar.Velocity * 0.95
    end

    sprite.FlipX = familiar.Velocity.X < 0
end, REVEL.ENT.ANGRY_GEMINI.variant)

end