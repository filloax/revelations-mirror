return function()

--------------------
-- Lottery Ticket --
--------------------

local lotterySwitchTimerFast = 2
local lotterySwitchTimer = 4
local lotterySwitchTimerSlow = 6
local lotteryTicketPicksRandom = true
local lotteryTicketNumExtraItems = 4
revel:AddCallback(ModCallbacks.MC_USE_CARD, function(_, cardID, player, useFlags)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        local items = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)
        local seed = REVEL.room:GetSpawnSeed()
        local poolType = REVEL.pool:GetPoolForRoom(REVEL.room:GetType(), seed)

        if poolType == -1 then
            poolType = ItemPoolType.POOL_TREASURE
        end

        for _, item in ipairs(items) do
            local data = REVEL.GetData(item)
            data.LotteryTicketRerolls = {item.SubType}
            for i = 1, lotteryTicketNumExtraItems do
                data.LotteryTicketRerolls[#data.LotteryTicketRerolls + 1] = REVEL.pool:GetCollectible(poolType, true, seed)
            end
        end
    end

    --[[
    REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)

    local pos = Isaac.GetFreeNearPosition(REVEL.player.Position, 50)

    local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pos, Vector.Zero, player)
    poof:GetSprite():Play("Poof_Large", true)

    Isaac.Spawn(EntityType.ENTITY_SLOT, 10, 0, pos, Vector.Zero, player)
    ]]
end, REVEL.POCKETITEM.LOTTERY_TICKET.Id)

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, item)
    local data = REVEL.GetData(item)
    if data.LotteryTicketRerolls and (not data.RerollDelay or data.RerollDelay < REVEL.game:GetFrameCount()) and item.SubType ~= 0 then
        local lotteryRerolls, index, wait = data.LotteryTicketRerolls, data.LotteryTicketRerollIndex, item.Wait

        if lotteryTicketPicksRandom then
            index = math.random(1, #data.LotteryTicketRerolls)
        else
            if not index then
                index = 1
            end

            index = index + 1

            if not lotteryRerolls[index] then
                index = 1
            end
        end

        local id = lotteryRerolls[index]
        item:Morph(item.Type, item.Variant, id, true)
        REVEL.GetData(item).LotteryTicketRerolls = lotteryRerolls

        if not lotteryTicketPicksRandom then
            REVEL.GetData(item).LotteryTicketRerollIndex = index
        end

        local slowed, sped
        for _, player in ipairs(REVEL.players) do
            if player:HasCollectible(CollectibleType.COLLECTIBLE_STOP_WATCH) and REVEL.WasPlayerDamagedThisRoom(player) then
                slowed = true
                break
            elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BROKEN_WATCH) then
                if REVEL.room:GetBrokenWatchState() == 2 then
                    sped = true
                    break
                elseif REVEL.room:GetBrokenWatchState() == 1 then
                    slowed = true
                    break
                end
            end
        end

        if slowed then
            REVEL.GetData(item).RerollDelay = REVEL.game:GetFrameCount() + lotterySwitchTimerSlow
        elseif sped then
            REVEL.GetData(item).RerollDelay = REVEL.game:GetFrameCount() + lotterySwitchTimerFast
        else
            REVEL.GetData(item).RerollDelay = REVEL.game:GetFrameCount() + lotterySwitchTimer
        end

        item.Wait = wait
    end
end, PickupVariant.PICKUP_COLLECTIBLE)

end