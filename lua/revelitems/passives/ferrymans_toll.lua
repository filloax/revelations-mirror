REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
---------------------
-- Ferryman's Toll --
---------------------

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if DetailedRespawn and not REVEL.DRes_FerrymansTollIdx then
        REVEL.DRes_FerrymansTollIdx = #DetailedRespawn.Respawns + 1
        DetailedRespawn.AddCustomRespawn({
            Name = "Ferryman's Toll",
            ItemId = REVEL.ITEM.FERRYMANS_TOLL.id,
            Condition = function(player)
            local isKeeper = player:GetPlayerType() == PlayerType.PLAYER_KEEPER
            return REVEL.ITEM.FERRYMANS_TOLL:PlayerHasCollectible(player) and revel.data.run.ferrymanRevives and (isKeeper and revel.data.run.ferrymanRevives[1] < 4 or revel.data.run.ferrymanRevives[1] < 3)
            end,
            AdditionalText = "33c"
        }, REVEL.DRes_FerrymansTollIdx)
    end

    local toll
    local player = Isaac.GetPlayer(0) -- player 1 only as DetailedRespawn doesn't support true coop yet
    local isCharon = REVEL.IsDanteCharon(player)
    local isKeeper = player:GetPlayerType() == PlayerType.PLAYER_KEEPER
    local timesRevived = revel.data.run.ferrymanRevives[1]

    if isKeeper then
        toll = (timesRevived + 1) * 25
        if toll == 100 then
            toll = 99
        end
    else
        toll = (timesRevived + 1) * 33
    end
    if DetailedRespawn then
        DetailedRespawn.Respawns[REVEL.DRes_FerrymansTollIdx].AdditionalText = tostring(toll) .. "c"
    end
end)

local charonOffset = Vector(0, -40)
REVEL.ITEM.FERRYMANS_TOLL:addPickupCallback(function(player)
    for i = 1, 2 do
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, player)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for pind, player in ipairs(REVEL.players) do
        if REVEL.ITEM.FERRYMANS_TOLL:PlayerHasCollectible(player) then
            local data = player:GetData()
            if player:IsDead() and player:GetExtraLives() == 0 then
                if not data.FerrymanDeathTimer then
                    data.FerrymanDeathTimer = 0
                else
                    data.FerrymanDeathTimer = data.FerrymanDeathTimer + 1
                end

                if data.FerrymanDeathTimer >= 55 then
                    local toll
                    local isCharon = REVEL.IsDanteCharon(player)
                    local isKeeper = player:GetPlayerType() == PlayerType.PLAYER_KEEPER
                    local timesRevived = revel.data.run.ferrymanRevives[pind]

                    if isKeeper then
                        toll = (timesRevived + 1) * 25
                        if toll == 100 then
                            toll = 99
                        end
                    else
                        toll = (timesRevived + 1) * 33
                    end

                    if player:GetNumCoins() >= toll then
                        player:Revive()
                        player:AddHearts(12)
                        REVEL.SafeRoomTransition(REVEL.level:GetStartingRoomIndex(), true)
                        player:AnimateAppear()
                        player.Position = REVEL.room:GetCenterPos()
                        player.ControlsCooldown = 90
                        if not isCharon then
                            player:AddCoins(-toll)
                            REVEL.SpawnDecoration(player.Position + charonOffset, Vector.Zero, "UseToll", "gfx/itemeffects/revelcommon/ferryman.anm2", nil, -1000)
                        else
                            player:AnimateCollectible(REVEL.ITEM.FERRYMANS_TOLL.id, "UseItem", "PlayerPickup")
                        end

                        revel.data.run.ferrymanRevives[pind] = revel.data.run.ferrymanRevives[pind] + 1
                        REVEL.FadeIn(45)

                        if DetailedRespawn and REVEL.DRes_FerrymansTollIdx then
                            timesRevived = revel.data.run.ferrymanRevives[pind]
                            if isKeeper then
                                toll = (timesRevived + 1) * 25
                                if toll == 100 then
                                    toll = 99
                                end
                            else
                                toll = (timesRevived + 1) * 33
                            end
                            DetailedRespawn.Respawns[REVEL.DRes_FerrymansTollIdx].AdditionalText = tostring(toll) .. "c"
                        end
                    end

                    data.FerrymanDeathTimer = nil
                end
            else
                data.FerrymanDeathTimer = nil
            end
        end
    end
end)

end