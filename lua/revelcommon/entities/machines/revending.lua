local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Revending machine

REVEL.RegisterMachine(REVEL.ENT.REVENDING_MACHINE)

local Chances = {
    Default = 50,
    -- Treasure = 45, (actually 100 - devil/angel - default)
    MinDevilAngel = 1, MaxDevilAngel = 8,
    MinAngel = 20, MaxAngel = 95, --chance for angel when its angel/devil
}

local Prices = {
    Revelations = 20,
    Treasure = 20,
    Devil = 30,
    Angel = 30,
}

local RESTOCK_EXPLODE_CHANCE_START   = 0
local RESTOCK_EXPLODE_CHANCE_END     = 60 / 100
local RESTOCK_EXPLODE_CHANCE_MAX_NUM = 5

local TypeSprites = {
    Revelations = "gfx/grid/revelcommon/revending_machine.png", --default
    Treasure = "gfx/grid/revelcommon/revending_machine_treasure.png",
    Devil = "gfx/grid/revelcommon/revending_machine_devil.png",
    Angel = "gfx/grid/revelcommon/revending_machine_angel.png",
}

local TypePools = {
    -- Revelations = set via function because rerolls
    Treasure = ItemPoolType.POOL_TREASURE,
    Devil = ItemPoolType.POOL_DEVIL,
    Angel = ItemPoolType.POOL_ANGEL,
}

local RevelShopPool = REVEL.filter(REVEL.ITEM, function(v)
    return not v.exclusive and not v.trinket
end)

local priceFont = Font()
priceFont:Load("font/teammeatfont10.fnt")
local priceColor = KColor(0,0,0,1)
local priceColorDiscount = KColor(0.5,0,0,1)

local PriceAnimNull = {
    IdleSale = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
    Initiate = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(15, -24), Vector(17, -21), Vector(13, -28), Vector(13, -27), Vector(14, -26)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
    Idle = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
    InitiateSale = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(15, -24), Vector(17, -21), Vector(13, -28), Vector(13, -27), Vector(14, -26)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
    InitiateFull = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(15, -24), Vector(17, -21), Vector(19, -22), Vector(22, -21), Vector(25, -19), Vector(27, -15), Vector(27, -10)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
    InitiateFullSale = {
        Offset = {Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(14, -26), Vector(15, -24), Vector(17, -21), Vector(19, -22), Vector(22, -21), Vector(25, -19), Vector(27, -15), Vector(28, -10)},
        Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100)}
    },
}
local PriceAnims = REVEL.keys(PriceAnimNull)

function REVEL.GetNextShopIndex()
    local ind = 0
    for _, pickup in ipairs(REVEL.roomPickups) do
        pickup = pickup:ToPickup()
        if pickup and pickup.ShopItemId and pickup.ShopItemId >= ind then
            ind = pickup.ShopItemId + 1
        end
    end

    return ind
end

function REVEL.GetShopItemIndex(ignore)
    if ignore then
        ignore = GetPtrHash(ignore)
    end

    for _, pickup in ipairs(REVEL.roomPickups) do
        pickup = pickup:ToPickup()
        if pickup and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.ShopItemId and (not ignore or GetPtrHash(pickup) ~= ignore) then
            return pickup.ShopItemId
        end
    end
end

local function SetRunData(ent, name, val)
    local saveStr = REVEL.level:GetCurrentRoomIndex() .. "-" .. REVEL.room:GetGridIndex(ent.Position)
    revel.data.run.level.revendingMachineData[saveStr] = revel.data.run.level.revendingMachineData[saveStr] or {}
    revel.data.run.level.revendingMachineData[saveStr][name] = val
end

local function GetRunData(ent, name)
    local saveStr = REVEL.level:GetCurrentRoomIndex() .. "-" .. REVEL.room:GetGridIndex(ent.Position)
    revel.data.run.level.revendingMachineData[saveStr] = revel.data.run.level.revendingMachineData[saveStr] or {}

    return revel.data.run.level.revendingMachineData[saveStr][name]
end

local function StageOneRemoval(npc)
    if REVEL.room:IsFirstVisit() and REVEL.room:GetFrameCount() == 0 and REVEL.room:GetType() == RoomType.ROOM_SHOP then
        if REVEL.level:GetStage() % 2 ~= 0 then
            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom then
                local str = string.match(currentRoom.Layout.Name,"revend")
                if str ~= "revend" then
                    npc:Remove()
                end
            end
        end
    end
end

-- Choose type
function REVEL.InitializeRevendingMachine(machine, data)
    -- StageOneRemoval(machine)

    data.Type = GetRunData(machine, "Type")
    if not data.Type then
        local devilAngelChance = REVEL.Lerp2Clamp(Chances.MinDevilAngel, Chances.MaxDevilAngel, REVEL.room:GetDevilRoomChance())
        local angelChance = 0.5 --REVEL.Lerp2Clamp(Chances.MinAngel, Chances.MaxAngel, REVEL.level:GetAngelRoomChance()) / 100 doesn't work in ab+

        local defaultNumber = Chances.Default / 100
        local devilAngelNumber = (Chances.Default + devilAngelChance) / 100

        local rng = REVEL.RNG()
        rng:SetSeed(REVEL.room:GetSpawnSeed(), REVEL.room:GetGridIndex(machine.Position))
        local num = rng:RandomFloat()

        if num <= defaultNumber then
            data.Type = "Revelations"
        elseif num <= devilAngelNumber then
            if rng:RandomFloat() <= angelChance then
                data.Type = "Angel"
            else
                data.Type = "Devil"
            end
        else
            data.Type = "Treasure"
        end
    end
    SetRunData(machine, "Type", data.Type)

    if not data.Price then
        data.Price = GetRunData(machine, "Price")
        data.Discount = GetRunData(machine, "Discount")
        if not data.Price then
            local isGlacierOne = REVEL.STAGE.Glacier:IsStage() and (REVEL.STAGE.Glacier:IsStage(true) or HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH))
            if isGlacierOne or REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_STEAM_SALE) then
                data.Price = math.floor(Prices[data.Type] / 2)
                data.Discount = true
            else
                data.Price = Prices[data.Type]
            end
        end
    end
    SetRunData(machine, "Price", data.Price)
    SetRunData(machine, "Discount", data.Discount)

    REVEL.ChooseRevelShopItem(machine, data)
end

function REVEL.ResetMachineSprite(machine, data)
    local config = REVEL.config:GetCollectible(machine.SubType)
    local gfx = config.GfxFileName
    local sprite = machine:GetSprite()
    sprite:ReplaceSpritesheet(3, gfx)

    if not data.Type then
        data.Type = GetRunData(machine, "Type")
        if not data.Type then
            REVEL.DebugLog("Warning: no revending machine type set")
        end
    end

    if not data.Price then
        data.Price = GetRunData(machine, "Price")
        data.Discount = GetRunData(machine, "Discount")
    end

    if data.Type and data.Type ~= "Revelations" then
        for i = 0, 4 do
            if i ~= 3 then
                sprite:ReplaceSpritesheet(i, TypeSprites[data.Type])
            end
        end
    end 

    sprite:LoadGraphics()

    if data.Discount then
        sprite:Play("IdleSale", true)
    else
        sprite:Play("Idle", true)
    end
end

function REVEL.ChooseRevelShopItem(machine, data, item)
    if not item then
        if data.Type == "Revelations" or not data.Type then
            local spawnable = REVEL.filter(RevelShopPool, function(item)
                if REVEL.ShouldRerollItem(item.id) then return false end

                local cannotAdd = REVEL.some(REVEL.players, function(player)
                    return player:HasCollectible(item.id) 
                        or (REVEL.IsDanteCharon(player) and REVEL.STAGE.Glacier:IsStage() and (not item.power or item.power < 1))
                        or (player:GetData().RevendingMachineBlacklist and player:GetData().RevendingMachineBlacklist[item.id])
                end)
                if cannotAdd then return false end

                local alreadyInOtherMachine = REVEL.some(
                    REVEL.ENT.REVENDING_MACHINE:getInRoom(false, false, false), 
                    function (revending)
                        return revending.SubType == item.id
                    end
                )
                if alreadyInOtherMachine then return false end

                return (Isaac.CountEntities(nil, EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item.id) or 0) == 0
            end)

            item = spawnable[math.random(1, #spawnable)].id
        else
            item = REVEL.game:GetItemPool():GetCollectible(TypePools[data.Type], true, REVEL.room:GetSpawnSeed())
        end
    end

    machine.SubType = item
    REVEL.ResetMachineSprite(machine, data)
end

function REVEL.RerollRevendingMachine(machine)
    REVEL.ChooseRevelShopItem(machine, REVEL.GetMachineData(machine))
end

local function revendingMachineInit(machine, data)
    if machine.SubType <= 0 then
        REVEL.InitializeRevendingMachine(machine, data)
    else
        REVEL.ResetMachineSprite(machine, data)
    end

    machine:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    data.pos = machine.Position
end

local function revendingMachineUpdate(machine, data)
    if machine.SubType <= 0 then
        REVEL.InitializeRevendingMachine(machine, data)
    end

    local sprite = machine:GetSprite()

    if data.PickupCooldown then
        data.PickupCooldown = data.PickupCooldown - 1
        if data.PickupCooldown <= 0 then
            data.PickupCooldown = nil
        end
    end

    local blocked = data.PickupCooldown or sprite:IsPlaying("ReClose")

    if not data.Vended and not blocked then
        for _, player in ipairs(REVEL.players) do
            if player:GetNumCoins() >= data.Price and (player.Position:DistanceSquared(machine.Position) < (player.Size + machine.Size) ^ 2) then
                player:AddCoins(-data.Price)
                if data.Price > 7 then
                    sprite:Play("InitiateFull", true)
                    REVEL.sfx:Play(SoundEffect.SOUND_COIN_SLOT, 1, 0, false, 1)
                else
                    sprite:Play("InitiateFullSale", true)
                    REVEL.sfx:Play(SoundEffect.SOUND_COIN_SLOT, 1, 0, false, 1)
                end

                data.Vended = true
                break
            end
        end
    end

    machine:MultiplyFriction(0)
    -- machine.Velocity = data.pos - machine.Position --just in case
    machine.Position = data.pos

    if sprite:IsFinished("Initiate") or sprite:IsFinished("ReClose") then
        sprite:Play("Idle", true)
    end
    if sprite:IsFinished("InitiateSale") then
        sprite:Play("IdleSale", true)
    end
    if sprite:IsFinished("InitiateFull") or sprite:IsFinished("InitiateFullSale") then
        sprite:Play("Prize", true)
    end

    if sprite:IsFinished("Prize") then
        local price = data.Price
        local discount = data.Discount
        local type = data.Type
        machine:Remove()

        local collectible = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, machine.SubType, machine.Position, Vector.Zero, nil)
        local config = REVEL.config:GetCollectible(machine.SubType)
        local gfx = config.GfxFileName
        local collectibleSprite = collectible:GetSprite()
        collectibleSprite:Load("gfx/grid/revelcommon/revending_collectible.anm2", false)
        collectibleSprite:ReplaceSpritesheet(1, gfx)
        collectibleSprite:LoadGraphics()
        collectibleSprite:SetOverlayFrame("Alternates", 0)
        collectibleSprite:Play("Idle", true)
        collectible:GetData().Revended = true
        collectible:GetData().RevendedPrice = price
        collectible:GetData().RevendedDiscount = discount
        collectible:GetData().RevendedType = type
        collectible:GetData().RevendedRestockAmount = data.RestockAmount or 0
    end
end

local function revendingMachineRespawn(machine, newMachine, data)
    REVEL.ChooseRevelShopItem(newMachine, data, machine.SubType)
end

local function revendingMachinePostExplosion(machine, data)
    return false
end

local defOffset = Vector(-9, 2)

local function revendingMachineRender(machine, data, renderOffset)
    local sprite = machine:GetSprite()

    if data.Price then
        local nullData = PriceAnimNull[sprite:GetAnimation()]
        if nullData then
            local pos = Isaac.WorldToScreen(machine.Position) 
                + nullData.Offset[sprite:GetFrame() + 1]
                + defOffset
                + renderOffset - REVEL.room:GetRenderScrollOffset()

            priceFont:DrawStringScaledUTF8(data.Price .. "¢", pos.X, pos.Y, 0.75, 0.75, data.Discount and priceColorDiscount or priceColor, 20, true)
        end
    end
end

local function revendingPostPickupCollectible(_, pickup)
    if pickup:GetData().Revended 
    and REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_RESTOCK) 
    and pickup.SubType == 0 then --picked up sold item
        local restockAmount = pickup:GetData().RevendedRestockAmount + 1
        local explodeChance = REVEL.Lerp2Clamp(
            RESTOCK_EXPLODE_CHANCE_START, RESTOCK_EXPLODE_CHANCE_END, 
            restockAmount, 
            1, RESTOCK_EXPLODE_CHANCE_MAX_NUM
        )
        local rng = REVEL.RNG()
        rng:SetSeed(pickup.InitSeed, 40)
        local doExplode = rng:RandomFloat() < explodeChance

        if not doExplode then
            local newPrice = pickup:GetData().RevendedPrice + 2
            local type = pickup:GetData().RevendedType
            local discounted = pickup:GetData().RevendedDiscount
            pickup:Remove()

            local machine = REVEL.ENT.REVENDING_MACHINE:spawn(pickup.Position, Vector.Zero, nil)
            local data = REVEL.GetMachineData(machine)
            data.PickupCooldown = 30
            data.Price = newPrice
            data.Discount = discounted
            data.RestockAmount = restockAmount
            SetRunData(machine, "Price", newPrice)
            data.Type = type
            revendingMachineUpdate(machine, data)
            machine:GetSprite():Play("ReClose", true)
        elseif not pickup:GetData().Exploded then
            pickup:GetData().Exploded = true
            Isaac.Spawn(1000, EffectVariant.BOMB_EXPLOSION, 1, pickup.Position, Vector.Zero, nil)
            -- TODO: Needs sprites for the frame
            -- pickup:GetSprite():SetOverlayFrame("Alternates", 1)
        end
    end
end

function REVEL.CanRevelShop()
    return REVEL.room:GetType() == RoomType.ROOM_SHOP and not REVEL.game:IsGreedMode() and REVEL.IsRevelStage() and not revel.data.run.level.revelShopSpawned
end

function REVEL.RevelShop(force, fromNewRoom)
    if force or REVEL.CanRevelShop() then
        local pos = REVEL.room:GetGridPosition(25)
        -- in case of member card, etc
        pos = REVEL.room:FindFreePickupSpawnPosition(pos)

        if not fromNewRoom then
            REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 1)

            local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pos, Vector.Zero, nil)
            poof:GetSprite():Play("Poof_Large", true)
        end

        local machine = REVEL.ENT.REVENDING_MACHINE:spawn(pos, Vector.Zero, nil)
        revendingMachineUpdate(machine, REVEL.GetMachineData(machine))

        revel.data.run.level.revelShopSpawned = true
    end
end

local function revendingGreedPostEntityKill(_, e)
    if REVEL.CanRevelShop() then
        REVEL.DelayFunction(REVEL.RevelShop, 10, true, true)
    end
end


revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, revendingPostPickupCollectible, PickupVariant.PICKUP_COLLECTIBLE)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_INIT, 1, revendingMachineInit, REVEL.ENT.REVENDING_MACHINE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_UPDATE, 1, revendingMachineUpdate, REVEL.ENT.REVENDING_MACHINE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_RENDER, 1, revendingMachineRender, REVEL.ENT.REVENDING_MACHINE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_EXPLODE, 1, revendingMachinePostExplosion, REVEL.ENT.REVENDING_MACHINE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_RESPAWN, 1, revendingMachineRespawn, REVEL.ENT.REVENDING_MACHINE.variant)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, revendingGreedPostEntityKill, EntityType.ENTITY_GREED)

end

REVEL.PcallWorkaroundBreakFunction()