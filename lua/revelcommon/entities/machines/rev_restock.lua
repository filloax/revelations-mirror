local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
return function()
    
-- Revelations Restock Machine
local function restockPreEntitySpawn(_, t, v, s, pos, vel, spawner, seed)
    if t == EntityType.ENTITY_SLOT and v == 10 and (REVEL.STAGE.Glacier:IsStage() or REVEL.STAGE.Tomb:IsStage()) then -- restock machine
        return {
            REVEL.ENT.RESTOCK_MACHINE.id,
            REVEL.ENT.RESTOCK_MACHINE.variant,
            s,
            seed
        }
    end
end

REVEL.RegisterMachine(REVEL.ENT.RESTOCK_MACHINE)

local keepAnimationsAfterExplosion = {
    "Death",
    "Initiate"
}

local function RestockMachineRestock()
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom then
        local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false)
        local shopItemIDs = {}
        local collectibles = {}
        for _, pickup in ipairs(pickups) do
            if pickup:ToPickup().Price ~= 0 then
                shopItemIDs[#shopItemIDs + 1] = pickup:ToPickup().ShopItemId
                pickup:Remove()
            elseif pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= 0 then
                collectibles[#collectibles + 1] = pickup
            end
        end

        local spawnEntities = currentRoom.SpawnEntities
        local spawnedShopItems
        for index, entList in pairs(spawnEntities) do
            for _, ent in ipairs(entList) do
                if ent.Data.Type == EntityType.ENTITY_PICKUP and ent.Data.Variant == PickupVariant.PICKUP_SHOPITEM then
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, REVEL.room:GetGridPosition(index), Vector.Zero, nil)
                    local pickup = Isaac.Spawn(ent.Data.Type, ent.Data.Variant, ent.Data.SubType or 0, REVEL.room:GetGridPosition(index), Vector.Zero, nil):ToPickup()
                    if shopItemIDs[1] then
                        pickup.ShopItemId = shopItemIDs[1]
                        table.remove(shopItemIDs, 1)
                    end
                    spawnedShopItems = true
                end
            end
        end

        if not spawnedShopItems then
            for _, collectible in ipairs(collectibles) do
                collectible:ToPickup():Morph(collectible.Type, collectible.Variant, 0, true)
            end
        end

        local revendingMachines = REVEL.ENT.REVENDING_MACHINE:getInRoom()
        for _, machine in ipairs(revendingMachines) do
            if not machine:GetSprite():IsPlaying("Prize") then
                REVEL.RerollRevendingMachine(machine)
            end
        end
    else
        REVEL.DebugLog("Warning: Revelations restock machines used in normal level, won't work")
    end
end

local function RestockMachineUpdate(machine, data)
    local sprite = machine:GetSprite()
    local restockVars = revel.data.run.level.localRestockVars[tostring(machine.InitSeed)]

    if not data.PostInit then
        machine:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        data.Position = machine.Position
        data.PostInit = true
        if not restockVars then
            restockVars = {
                Payout = revel.data.run.globalRestockPayout,
                BreakChance = 0
            }
        end
        data.RNG = REVEL.RNG()
        data.RNG:SetSeed(machine.InitSeed, 0)
        data.State = "Idle"
    end

    --[[
    machine:MultiplyFriction(0)
    machine.Position = data.Position
    ]]

    local restock
    if data.State == "Idle" then
        if not data.PayTimer or data.PayTimer < machine.FrameCount then
            for _, player in ipairs(REVEL.players) do
                if player:GetNumCoins() > 0 and (player.Position:DistanceSquared(machine.Position) < (player.Size + machine.Size) ^ 2) then
                    player:AddCoins(-1)
                    sprite:PlayOverlay("CoinInsert")
                    REVEL.sfx:Play(SoundEffect.SOUND_COIN_SLOT, 1, 0, false, 1)
                    if StageAPI.Random(1, restockVars.Payout, data.RNG) == 1 then
                        data.WillPay = true
                        if StageAPI.Random(0, 99, data.RNG) < restockVars.BreakChance then
                            data.WillBreak = true
                        else
                            if restockVars.BreakChance < 90 then
                                restockVars.BreakChance = restockVars.BreakChance + 10
                            end
                        end
                    else
                        restockVars.Payout = math.max(2, restockVars.Payout - 1)
                    end

                    data.State = "InsertedCoin"
                    data.PayTimer = machine.FrameCount + 20
                end
            end
        end
    elseif data.State == "InsertedCoin" then
        if sprite:IsOverlayFinished("CoinInsert") then
            sprite:RemoveOverlay()
            if data.WillPay then
                restock = true
                if data.WillBreak then
                    Isaac.Spawn(1000, EffectVariant.BOMB_EXPLOSION, 1, data.Position, Vector.Zero, machine)
                else
                    sprite:Play("Initiate", true)
                end
                data.WillPay = nil
                data.State = "Restocked"
            else
                sprite:Play("Idle", true)
                data.State = "Idle"
            end
        end
    elseif data.State == "Restocked" then
        sprite:Play("Idle", true)
        data.State = "Idle"
    end

    if restock then
        --revel.data.run.globalRestockPayout = revel.data.run.globalRestockPayout + 8
        restockVars.Payout = revel.data.run.globalRestockPayout
        RestockMachineRestock()
    end

    revel.data.run.level.localRestockVars[tostring(machine.InitSeed)] = restockVars
end

local function RestockMachinePostExplosion(machine, data)
    RestockMachineRestock()
    local coinDrop = data.RNG:RandomInt(4)
    for i = 0, coinDrop do
        REVEL.SpawnSlotRewardPickup(PickupVariant.PICKUP_COIN, 0, machine.Position, RandomVector() * 2, nil)
    end

    machine:GetSprite():Play("Death", true)
end

--revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, restockPreEntitySpawn)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_UPDATE, 1, RestockMachineUpdate, REVEL.ENT.RESTOCK_MACHINE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_EXPLODE, 1, RestockMachinePostExplosion, REVEL.ENT.RESTOCK_MACHINE.variant)

end