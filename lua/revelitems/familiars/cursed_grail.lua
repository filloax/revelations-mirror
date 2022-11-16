local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
------------------
-- CURSED GRAIL --
------------------

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local num = ((REVEL.ITEM.CURSED_GRAIL:GetCollectibleNum(player) - (revel.data.run.cursedGrailsFilled[REVEL.GetPlayerID(player)] or 0)) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1))
        local rng = REVEL.RNG()
        rng:SetSeed(math.random(10000), 0)
        player:CheckFamiliar(REVEL.ENT.CURSED_GRAIL.variant, num, rng:GetRNG())
    end
    if flag == CacheFlag.CACHE_DAMAGE then
        for i,familiar in ipairs(Isaac.FindByType(REVEL.ENT.CURSED_GRAIL.id, REVEL.ENT.CURSED_GRAIL.variant, -1, false, false)) do
            if familiar:Exists() then
                ---@type EntityFamiliar
                familiar = familiar:ToFamiliar()
                if familiar.Player and GetPtrHash(familiar.Player) == GetPtrHash(player) then
                    player.Damage = player.Damage + (familiar.Hearts * 0.2)
                end
            end
        end
        player.Damage = player.Damage + ((revel.data.run.cursedGrailsFilled[REVEL.GetPlayerID(player)] or 0) * 3)
    end
    if flag == CacheFlag.CACHE_FLYING then
        if (revel.data.run.cursedGrailsFilled[REVEL.GetPlayerID(player)] or 0) > 0 then
            player.CanFly = true
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    local data, sprite = familiar:GetData(), familiar:GetSprite()

    if not data.Init then
        if familiar.Hearts <= 0 then
            familiar.Hearts = 0
            sprite:Play("Idle", true)
        elseif familiar.Hearts == 1 then
            sprite:Play("Stage1Idle", true)
        elseif familiar.Hearts == 2 then
            sprite:Play("Stage2Idle", true)
        elseif familiar.Hearts == 3 then
            sprite:Play("Stage3Idle", true)
        elseif familiar.Hearts == 4 then
            sprite:Play("Stage4Idle", true)
        elseif familiar.Hearts == 5 then
            sprite:Play("Stage5Idle", true)
        elseif familiar.Hearts >= 6 then
            familiar.Hearts = 6
            sprite:Play("Stage6Fill", true)
        end
        data.Init = true
    end

    if sprite:IsFinished("Stage1Fill") then
        sprite:Play("Stage1Idle", true)
    elseif sprite:IsFinished("Stage2Fill") then
        sprite:Play("Stage2Idle", true)
    elseif sprite:IsFinished("Stage3Fill") then
        sprite:Play("Stage3Idle", true)
    elseif sprite:IsFinished("Stage4Fill") then
        sprite:Play("Stage4Idle", true)
    elseif sprite:IsFinished("Stage5Fill") then
        sprite:Play("Stage5Idle", true)
    elseif sprite:IsFinished("Stage6Fill") then
        familiar:RemoveFromFollowers()
        sprite:Play("Stage6Idle", true)
    end

    if familiar.Player and sprite:IsPlaying("Stage6Idle") then
        local player = familiar.Player
        if not REVEL.LerpEntityPosition(familiar, familiar.Position, player.Position, 10) or familiar.Position:Distance(player.Position) < 10 then
            familiar.Position = player.Position
            familiar.Velocity = Vector.Zero

            familiar:Remove()

            revel.data.run.cursedGrailsFilled[REVEL.GetPlayerID(player)] = revel.data.run.cursedGrailsFilled[REVEL.GetPlayerID(player)] + 1
            player:AddNullCostume(REVEL.COSTUME.CURSED_GRAIL)
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:AddCacheFlags(CacheFlag.CACHE_FLYING)
            player:EvaluateItems()
        end
    else
        local gotoPos = nil

        if REVEL.room:IsClear() then
            local rng = REVEL.RNG()
            rng:SetSeed(math.random(10000), 0)
            local roomIndex = REVEL.level:QueryRoomTypeIndex(RoomType.ROOM_SACRIFICE, true, rng:GetRNG())
            if REVEL.level:GetRoomByIdx(roomIndex).Data.Type == RoomType.ROOM_SACRIFICE then
                if roomIndex == REVEL.level:GetCurrentRoomIndex() then
                    gotoPos = REVEL.room:GetCenterPos() + Vector(50,0)
                else
                    local i, door = REVEL.FindDoorToIdx(roomIndex, false)
                    if door then
                        gotoPos = door.Position
                        if door.Direction == Direction.LEFT then
                            gotoPos = gotoPos + Vector(30,-30)
                        elseif door.Direction == Direction.UP then
                            gotoPos = gotoPos + Vector(30,30)
                        elseif door.Direction == Direction.RIGHT then
                            gotoPos = gotoPos + Vector(-30,-30)
                        elseif door.Direction == Direction.DOWN then
                            gotoPos = gotoPos + Vector(-30,-30)
                        end
                    end
                end
            end
        end

        if gotoPos then
            if data.inFollowers then
                familiar:RemoveFromFollowers()
                data.inFollowers = false
            end
            familiar:FollowPosition(gotoPos)
        else
            if not data.inFollowers then
                familiar:AddToFollowers()
                data.inFollowers = true
            end
            familiar:FollowParent()
        end
    end
end, REVEL.ENT.CURSED_GRAIL.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(entity, amount, flags, source)
    if HasBit(flags, DamageFlag.DAMAGE_SPIKES) then
        if REVEL.room:GetType() == RoomType.ROOM_SACRIFICE then
            local doOnce = false
            for i,familiar in ipairs(Isaac.FindByType(REVEL.ENT.CURSED_GRAIL.id, REVEL.ENT.CURSED_GRAIL.variant, -1, false, false)) do
                if not doOnce then
                    if familiar:Exists() then
                        ---@type EntityFamiliar
                        familiar = familiar:ToFamiliar()
                        if familiar.Player and GetPtrHash(familiar.Player) == GetPtrHash(entity) then
                            local player = familiar.Player

                            familiar.Hearts = familiar.Hearts + 1

                            local sprite = familiar:GetSprite()
                            if familiar.Hearts <= 1 then
                                familiar.Hearts = 1
                                sprite:Play("Stage1Fill", true)
                            elseif familiar.Hearts == 2 then
                                sprite:Play("Stage2Fill", true)
                            elseif familiar.Hearts == 3 then
                                sprite:Play("Stage3Fill", true)
                            elseif familiar.Hearts == 4 then
                                sprite:Play("Stage4Fill", true)
                            elseif familiar.Hearts == 5 then
                                sprite:Play("Stage5Fill", true)
                            elseif familiar.Hearts >= 6 then
                                familiar.Hearts = 6
                                sprite:Play("Stage6Fill", true)
                            end

                            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
                            player:EvaluateItems()

                            doOnce = true
                        end
                    end
                end
            end
        end
    end
end, EntityType.ENTITY_PLAYER)

end