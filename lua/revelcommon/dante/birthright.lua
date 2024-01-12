local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Birthright

local function whitelistGenComp(a, b)
    return a.id < b.id
end

-- returns { [string id] = 1 or 2 }, where 1 if the item belongs to dante, 2 for charon
function REVEL.Dante.GenerateBirthrightWhitelist(player, charonInventory)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
        local numToWhitelist = 3

        local stageSeed = REVEL.game:GetSeeds():GetStageSeed(REVEL.level:GetStage())
        if REVEL.STAGE.Glacier:IsStage() then
            stageSeed = stageSeed + 55
        elseif REVEL.STAGE.Tomb:IsStage() then
            stageSeed = stageSeed + 75
        end
        local birthrightRng = REVEL.RNG()
        birthrightRng:SetSeed(stageSeed, 17)

        local inventory = revel.data.run.inventory[REVEL.GetPlayerID(player)]
        local inventoryList = {}

        for sid, num in pairs(inventory) do
            local id = tonumber(sid)
            if REVEL.Dante.IsInventoryManagedItem(id) and not REVEL.CharonFullBan[id] then
                local ownerIsCharon = charonInventory[sid] ~= nil and charonInventory[sid] ~= 0
                inventoryList[#inventoryList+1] = {id = id, owner = ownerIsCharon and 2 or 1}
            end
        end

        table.sort(inventoryList, whitelistGenComp)

        local whitelist = {}
        local i = 1

        while i <= numToWhitelist and #inventoryList > 0 do
            local entry = table.remove(
                inventoryList, 
                StageAPI.Random(1, #inventoryList, birthrightRng)
            )
            whitelist[tostring(entry.id)] = entry.owner
            i = i + 1
        end

        return whitelist
    else
        return {}
    end
end

function REVEL.Dante.GetBirthrightWhitelist(player)
    return revel.data.run.dante.BirthrightWhitelist
end

end