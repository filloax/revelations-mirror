REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
---------------
-- WAKA WAKA --
---------------

--[[
Active Item.
Treasure Pool.
Turns all projectiles into fruit that give you small permanent stat ups, the fruit last for only 5 seconds.
]]

local WakaWakaFruits = {
    {
        Gfx = "gfx/itemeffects/revelcommon/waka_waka_banana.png",
        ID = "Banana",
        Cache = CacheFlag.CACHE_SPEED,
        Weight = 2
    },
    {
        Gfx = "gfx/itemeffects/revelcommon/waka_waka_cherry.png",
        ID = "Cherry",
        Cache = CacheFlag.CACHE_DAMAGE,
        Weight = 3
    },
    {
        Gfx = "gfx/itemeffects/revelcommon/waka_waka_lemon.png",
        ID = "Lemon",
        Cache = CacheFlag.CACHE_RANGE,
        Weight = 2
    },
    {
        Gfx = "gfx/itemeffects/revelcommon/waka_waka_orange.png",
        ID = "Orange",
        Cache = CacheFlag.CACHE_SHOTSPEED,
        Weight = 2
    }
}

local WakaWakaSumWeights = 0
for _, fruit in ipairs(WakaWakaFruits) do
    WakaWakaSumWeights = WakaWakaSumWeights + fruit.Weight
end

local WakaWakaFruitDecay = 150
local WakaWakaBlinkMaxFrequency = 1
local WakaWakaBlinkMinFrequency = 10
local WakaWakaBlinkStartTime = 60

local gamekid = REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_GAMEKID)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        for _,t in ipairs(REVEL.roomProjectiles) do
            if REVEL.room:IsPositionInRoom(t.Position, 0) then
                local fruit = Isaac.Spawn(REVEL.ENT.WAKAWAKA_FRUIT.id, REVEL.ENT.WAKAWAKA_FRUIT.variant, 0, t.Position, Vector.Zero, nil)
                local fdata = StageAPI.WeightedRNG(WakaWakaFruits, nil, "Weight", WakaWakaSumWeights)
                if fdata.Gfx then
                    fruit:GetSprite():ReplaceSpritesheet(0, fdata.Gfx)
                    fruit:GetSprite():LoadGraphics()
                end

                fruit:GetData().FruitID = fdata.ID
                fruit:GetData().Flag = fdata.Cache
                t:Remove()
            end
        end
        player:GetData().WakaWakaTime = WakaWakaFruitDecay * 2
        player:AddCostume(gamekid, false)
        player:ReplaceCostumeSprite(gamekid, "gfx/itemeffects/revelcommon/waka_waka_head.png", 0)
        player:GetSprite():PlayOverlay("HeadRight", true)
        REVEL.music:Pause()
        REVEL.sfx:Play(REVEL.SFX.WAKA_WAKA_THEME, 1, 0, false, 1)
        return true
    end
end, REVEL.ITEM.WAKA_WAKA.id)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite = eff:GetSprite()
    if sprite:IsFinished("Collect") then
        eff:Remove()
    end

    if sprite:IsFinished("Appear") or sprite:IsFinished("Idle") then
        sprite:Play("Idle", true)
    end

    if not sprite:IsPlaying("Collect") then
        local timeLeft = WakaWakaFruitDecay - eff.FrameCount
        if timeLeft < 0 then
            eff:Remove()
        else
            if timeLeft < WakaWakaBlinkStartTime and not eff:GetSprite():IsPlaying("Collect") then
                local frequency = math.floor(REVEL.Lerp(WakaWakaBlinkMaxFrequency, WakaWakaBlinkMinFrequency, timeLeft / WakaWakaBlinkStartTime))
                if eff.FrameCount % frequency == 0 then
                    eff.Visible = false
                else
                    eff.Visible = true
                end
            else
                eff.Visible = true
            end
        end
    end
end, REVEL.ENT.WAKAWAKA_FRUIT.variant)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    local fruits = Isaac.CountEntities(nil, REVEL.ENT.WAKAWAKA_FRUIT.id, REVEL.ENT.WAKAWAKA_FRUIT.variant, -1) or 0
    for i, player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.WakaWakaTime and data.WakaWakaTime > 0 then
            if fruits < 1 then
                REVEL.sfx:Stop(REVEL.SFX.WAKA_WAKA_THEME)
                data.WakaWakaTime = 0
            end
            data.WakaWakaTime = data.WakaWakaTime - 1
        elseif data.WakaWakaTime then
            player:RemoveCostume(gamekid)
            REVEL.music:Resume()
            data.WakaWakaTime = nil
        end
    end
end)

function revel:UpdateFruits()
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        for i,fruit in ipairs(Isaac.FindByType(REVEL.ENT.WAKAWAKA_FRUIT.id, REVEL.ENT.WAKAWAKA_FRUIT.variant, -1, false, false)) do
            if not fruit:GetSprite():IsPlaying("Collect") and fruit.Position:DistanceSquared(player.Position) < (25 * 25) then
                if not data.WakaWakaStats then data.WakaWakaStats = {} end
                local id = fruit:GetData().FruitID
                if not data.WakaWakaStats[id] then
                    data.WakaWakaStats[id] = 0
                end
                data.WakaWakaStats[id] = data.WakaWakaStats[id] + 1

                REVEL.sfx:Play(REVEL.SFX.WAKA_WAKA_PICKUP, 1, 0, false, 1)

                player:AddCacheFlags(fruit:GetData().Flag)
                player:EvaluateItems()
                fruit:GetSprite():Play("Collect", true)

                if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                    local wisp = player:AddWisp(REVEL.ITEM.WAKA_WAKA.id, player.Position)
                    if wisp then
                        local color = Color(1,1,1,1)
                        if id == "Cherry" then
                            color:SetColorize(1,0,0,1)
                        elseif id == "Orange" then
                            color:SetColorize(1,0.6,0,1)
                        elseif id == "Lemon" then
                            color:SetColorize(1,1,0,1)
                        elseif id == "Banana" then
                            color:SetColorize(0.9,1,0,1)
                        end
                        wisp.Color = color
                    end
                end
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    for _, player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.WakaWakaStats then
            data.WakaWakaStats = nil
            player:AddCacheFlags(CacheFlag.CACHE_ALL)
            player:EvaluateItems()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    local data = player:GetData()
    if data.WakaWakaStats then
        if flag == CacheFlag.CACHE_DAMAGE and data.WakaWakaStats["Cherry"] then
            player.Damage = player.Damage + data.WakaWakaStats["Cherry"] * 0.1
        elseif flag == CacheFlag.CACHE_SHOTSPEED and data.WakaWakaStats["Orange"] then
            player.ShotSpeed = player.ShotSpeed+data.WakaWakaStats["Orange"] * 0.05
        elseif flag == CacheFlag.CACHE_RANGE and data.WakaWakaStats["Lemon"] then
            player.TearRange = player.TearRange+data.WakaWakaStats["Lemon"]
        elseif flag == CacheFlag.CACHE_SPEED and data.WakaWakaStats["Banana"] then
            player.MoveSpeed = player.MoveSpeed+data.WakaWakaStats["Banana"] * 0.05
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, revel.UpdateFruits)

revel:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, e, c)
    if e.SubType == REVEL.ITEM.WAKA_WAKA.id then
        if e.Player:GetData().WakaWakaTime and e.Player:GetData().WakaWakaTime > 0 then
            if c and c:IsVulnerableEnemy() or c.Type == EntityType.ENTITY_PROJECTILE then
                c:TakeDamage(1, 0, EntityRef(e), 0)
                return false
            end
        end
    end
end, FamiliarVariant.WISP)

end