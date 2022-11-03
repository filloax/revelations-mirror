local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------
-- PRESCRIPTION --
------------------

REVEL.PrescriptionPills = {
    Positive = {
        [PillEffect.PILLEFFECT_BAD_GAS] = true,
        [PillEffect.PILLEFFECT_BALLS_OF_STEEL] = true,
        [PillEffect.PILLEFFECT_BOMBS_ARE_KEYS] = true,
        [PillEffect.PILLEFFECT_HEALTH_UP] = true,
        [PillEffect.PILLEFFECT_PUBERTY] = true,
        [PillEffect.PILLEFFECT_RANGE_UP] = true,
        [PillEffect.PILLEFFECT_SPEED_UP] = true,
        [PillEffect.PILLEFFECT_TEARS_UP] = true,
        [PillEffect.PILLEFFECT_LUCK_UP] = true,
        [PillEffect.PILLEFFECT_PHEROMONES] = true,
        [PillEffect.PILLEFFECT_LEMON_PARTY] = true,
        [PillEffect.PILLEFFECT_PERCS] = true,
        [PillEffect.PILLEFFECT_RELAX] = true,
        [PillEffect.PILLEFFECT_LARGER] = true,
        [PillEffect.PILLEFFECT_SMALLER] = true,
        [PillEffect.PILLEFFECT_INFESTED_EXCLAMATION] = true,
        [PillEffect.PILLEFFECT_INFESTED_QUESTION] = true,
        [PillEffect.PILLEFFECT_POWER] = true,
        [PillEffect.PILLEFFECT_FRIENDS_TILL_THE_END] = true,
        [PillEffect.PILLEFFECT_SOMETHINGS_WRONG] = true,
        [PillEffect.PILLEFFECT_IM_DROWSY] = true,
        [PillEffect.PILLEFFECT_SUNSHINE] = true,
    },
    Negative = {
        [PillEffect.PILLEFFECT_HEALTH_DOWN] = true,
        [PillEffect.PILLEFFECT_I_FOUND_PILLS] = true,
        [PillEffect.PILLEFFECT_RANGE_DOWN] = true,
        [PillEffect.PILLEFFECT_SPEED_DOWN] = true,
        [PillEffect.PILLEFFECT_TEARS_DOWN] = true,
        [PillEffect.PILLEFFECT_LUCK_DOWN] = true,
        [PillEffect.PILLEFFECT_X_LAX] = true,
        [PillEffect.PILLEFFECT_IM_EXCITED] = true
    }
}

REVEL.PrescriptionPillsOppositeVersion = {
    [PillEffect.PILLEFFECT_HEALTH_UP] = PillEffect.PILLEFFECT_HEALTH_DOWN,
    [PillEffect.PILLEFFECT_RANGE_UP] = PillEffect.PILLEFFECT_RANGE_DOWN,
    [PillEffect.PILLEFFECT_SPEED_UP] = PillEffect.PILLEFFECT_SPEED_DOWN,
    [PillEffect.PILLEFFECT_TEARS_UP] = PillEffect.PILLEFFECT_TEARS_DOWN,
    [PillEffect.PILLEFFECT_LUCK_UP] = PillEffect.PILLEFFECT_LUCK_UP,
    [PillEffect.PILLEFFECT_LARGER] = PillEffect.PILLEFFECT_SMALLER,
    [PillEffect.PILLEFFECT_IM_DROWSY] = PillEffect.PILLEFFECT_IM_EXCITED,
    [PillEffect.PILLEFFECT_HEALTH_DOWN] = PillEffect.PILLEFFECT_HEALTH_UP,
    [PillEffect.PILLEFFECT_RANGE_DOWN] = PillEffect.PILLEFFECT_RANGE_UP,
    [PillEffect.PILLEFFECT_SPEED_DOWN] = PillEffect.PILLEFFECT_SPEED_UP,
    [PillEffect.PILLEFFECT_TEARS_DOWN] = PillEffect.PILLEFFECT_TEARS_UP,
    [PillEffect.PILLEFFECT_LUCK_UP] = PillEffect.PILLEFFECT_LUCK_UP,
    [PillEffect.PILLEFFECT_SMALLER] = PillEffect.PILLEFFECT_LARGER,
    [PillEffect.PILLEFFECT_IM_EXCITED] = PillEffect.PILLEFFECT_IM_DROWSY
}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 2, function(player)
    if not player:GetData().PrescriptionPills then
        player:GetData().PrescriptionPills = {}
    end
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0, Isaac.GetFreeNearPosition(player.Position, 1), Vector.Zero, nil)
end, REVEL.ITEM.PRESCRIPTION.id)

revel:AddCallback(ModCallbacks.MC_USE_PILL, function(_, pillEffect, player, useFlags)
    if REVEL.ITEM.PRESCRIPTION:PlayerHasCollectible(player) then
        local pillColor = nil
        for i=0, 200 do
            if REVEL.pool:GetPillEffect(i) == pillEffect then
                pillColor = i
                break
            end
        end  

        if not player:GetData().PrescriptionPills then
            player:GetData().PrescriptionPills = {}
        end
        if REVEL.PrescriptionPills.Positive[pillEffect] or REVEL.PrescriptionPills.Negative[pillEffect] then
            player:GetData().PrescriptionPills[pillEffect] = pillColor
            if REVEL.PrescriptionPillsOppositeVersion[pillEffect] then
                player:GetData().PrescriptionPills[REVEL.PrescriptionPillsOppositeVersion[pillEffect]] = pillColor
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _,player in ipairs(REVEL.players) do
        if REVEL.ITEM.PRESCRIPTION:PlayerHasCollectible(player) and REVEL.room:IsFirstVisit() then
            local data = player:GetData()
            local pills = {}
            for pilleffect,pillcolor in pairs(data.PrescriptionPills) do
                local total_health = player:GetHearts()+player:GetSoulHearts()+player:GetEternalHearts()
                if pilleffect ~= PillEffect.PILLEFFECT_BAD_TRIP and pilleffect ~= PillEffect.PILLEFFECT_HEALTH_DOWN or total_health > 2 then
                    if REVEL.PrescriptionPills.Positive[pilleffect] and math.random(1,100) <= 4 or REVEL.PrescriptionPills.Negative[pilleffect] and math.random(1,100) <= 3 then
                        table.insert(pills, {Effect = pilleffect, Color = pillcolor})
                    end
                end
            end
            if #pills ~= 0 then
                data.PrescriptionPill = pills[math.random(#pills)]
                data.PrescriptionSprite = Sprite()
                data.PrescriptionSprite:Load("gfx/itemeffects/revelcommon/prescription_effect.anm2", true)
                if REVEL.PrescriptionPills.Positive[data.PrescriptionPill.Effect] then
                    data.PrescriptionSprite:Play("PrescriptionBuff", true)
                elseif REVEL.PrescriptionPills.Negative[data.PrescriptionPill.Effect] then
                    data.PrescriptionSprite:Play("PrescriptionDebuff", true)
                end
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    local data = player:GetData()
    if data.PrescriptionSprite and player.FrameCount%2 == 0 then
        data.PrescriptionSprite:Update()
        data.PrescriptionSprite:LoadGraphics()
        if data.PrescriptionSprite:IsEventTriggered("Sound") then
            player:UsePill(data.PrescriptionPill.Effect, data.PrescriptionPill.Color)
            player:EvaluateItems()
            data.PrescriptionPill = nil
        end
        if data.PrescriptionSprite:IsFinished("PrescriptionBuff") or data.PrescriptionSprite:IsFinished("PrescriptionDebuff") then
            data.PrescriptionSprite = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, renderOffset)
    local data = player:GetData()
    if data.PrescriptionSprite then
        data.PrescriptionSprite:Render(Isaac.WorldToScreen(player.Position+Vector(0,-100)) + renderOffset - REVEL.room:GetRenderScrollOffset())
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()