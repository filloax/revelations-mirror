--[[
Christmas stocking
All the goodies you wanted
Trinket.
-Pickups that drop have a chance to be replaced by the one you have the least of. So let's say you have 
5 pennies, 2 bombs, and 0 keys, stuff that drops are likely to turn into keys.
-The greater difference there is between pickup numbers, the higher chance of getting the one with the smallest number
-Won't replace chests or cards and such
-Hearts get replaced only if you're at full HP
~~-If it's a double pickup that gets replaced, the one that it turns into would also be double~~
(last one isn't explicitly done, but if you just replace "random coin" with "random key" the 
chances for double items overall stay the same, you just move the roll earlier)
]]

REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()

local CHANCE_LOW = 25 / 100
local CHANCE_HIGH = 75 / 100
local HIGH_NUM = 15

local WhitelistedVariants = {
    PickupVariant.PICKUP_HEART,
    PickupVariant.PICKUP_COIN,
    PickupVariant.PICKUP_KEY,
    PickupVariant.PICKUP_BOMB,
}
WhitelistedVariants = REVEL.toSet(WhitelistedVariants)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, etype, variant, subtype, position, velocity, spawner, seed)
    if etype ~= EntityType.ENTITY_PICKUP
    or not WhitelistedVariants[variant]
    then return end

    local player = REVEL.GetRandomPlayerWithTrinket(REVEL.ITEM.XMAS_STOCKING.id)

    if not player then return end

    local numCoins = player:GetNumCoins()
    local numBombs = player:GetNumBombs()
    local numKeys = player:GetNumKeys()
    local values = {
        {PickupVariant.PICKUP_COIN, numCoins}, 
        {PickupVariant.PICKUP_BOMB, numBombs}, 
        {PickupVariant.PICKUP_KEY, numKeys},
    }
    -- sort by value as we need best and second best to compare
    table.sort(values, function(a, b)
        return a[2] < b[2]
    end)

    local lowest, lowestVal = values[1][1], values[1][2]
    local secondLowestDiff = values[2][2] - lowestVal

    local chanceToReplace = REVEL.Lerp2Clamp(CHANCE_LOW, CHANCE_HIGH, secondLowestDiff, 1, HIGH_NUM)

    local rng = REVEL.RNG()
    rng:SetSeed(seed, 40)

    if rng:RandomFloat() < chanceToReplace then
        local canReplaceHearts = true
        for _, player2 in ipairs(REVEL.players) do
            if player2:GetHearts() < player2:GetMaxHearts() then
                canReplaceHearts = false
                break
            end
        end

        if not canReplaceHearts and variant == PickupVariant.PICKUP_HEART then
            return
        end

        REVEL.DebugStringMinor("[REVEL] Xmas Stocking | Replaced", variant, "with", lowest)

        return {
            etype,
            lowest,
            0,
            seed
        }
    end
end)

end