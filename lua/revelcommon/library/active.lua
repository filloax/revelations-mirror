REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local playerAnims = {
    "Pickup", "Hit", "Appear", "Death", "Sad", "Happy", "TeleportUp", "TeleportDown", "WalkDir", "HeadDir", "Trapdoor", "Jump",
    "Glitch", "LiftItem", "HideItem", "UseItem", "LostDeath", "FallIn", "HoleDeath", "JumpOut", "PickupWalkDir", "LightTravel"
}

for i, animName in ripairs(playerAnims) do
    if animName:sub(-3) == "Dir" then
        table.remove(playerAnims, i)
        for _, dirName in pairs(REVEL.dirToString) do
            table.insert(playerAnims, animName:sub(1, -4) .. dirName)
        end
    end
end

function REVEL.IsShowingItem(player)
    return REVEL.MultiAnimOnCheck(player:GetSprite(), "LiftItem", "PickupWalkDown", "PickupWalkUp", "PickupWalkLeft", "PickupWalkRight")
end

--Show active until active button is pressed again

function REVEL.ShowActive(player)
    local data = player:GetData()

    data.LastShownItem = player:GetActiveItem()
    player:AnimateCollectible(data.LastShownItem, "LiftItem", "PlayerPickup")
    player.FireDelay = 15
end

function REVEL.HideActive(player)
    local data = player:GetData()
    local id = player:GetActiveItem()

    player:AnimateCollectible(id, "HideItem", "PlayerPickup")
    data.LastShownItem = nil
    player.FireDelay = player.MaxFireDelay
end

local function showActivePlayerUpdate(_, player)
    local data = player:GetData()
    if data.LastShownItem and REVEL.IsShowingItem(player) then
        player.FireDelay = 15
    end
end

function REVEL.RefundActiveCharge(player)
    REVEL.DelayFunction(1, function() player:SetActiveCharge(player:GetActiveCharge() + REVEL.config:GetCollectible(player:GetActiveItem()).MaxCharges) end)
end

function REVEL.ConsumeActiveCharge(player)
    player:SetActiveCharge(player:GetActiveCharge() - REVEL.config:GetCollectible(player:GetActiveItem()).MaxCharges)
end

function REVEL.ToggleShowActive(player, refundCharge)
    local data = player:GetData()
    if refundCharge then
        REVEL.RefundActiveCharge(player)
    end
    if data.LastShownItem and REVEL.IsShowingItem(player) then
        REVEL.HideActive(player)
        return false
    else
        REVEL.ShowActive(player)
        return true
    end
end

function REVEL.GetShowingActive(player)
    return REVEL.IsShowingItem(player) and player:GetData().LastShownItem
end
  
revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, showActivePlayerUpdate)

end