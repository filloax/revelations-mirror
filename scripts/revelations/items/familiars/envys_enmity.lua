local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local KnifeSubtype      = require("scripts.revelations.common.enums.KnifeSubtype")

return function()

-------------------
-- ENVY'S ENMITY --
-------------------


local function enmityStageCache(player, collectibleAmount, variant, numSplits, prevSplits)
    local num = ((collectibleAmount * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)) + (prevSplits * 2)) - numSplits
    local rng = REVEL.RNG()
    rng:SetSeed(math.random(10000), 0)
    player:CheckFamiliar(variant, num, rng:GetRNG())
end

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local data = REVEL.GetData(player)
        data.EnvyEnmnityNumSplits_1 = data.EnvyEnmnityNumSplits_1 or 0
        data.EnvyEnmnityNumSplits_2 = data.EnvyEnmnityNumSplits_2 or 0
        data.EnvyEnmnityNumSplits_3 = data.EnvyEnmnityNumSplits_3 or 0
        enmityStageCache(player, REVEL.ITEM.ENVYS_ENMITY:GetCollectibleNum(player), REVEL.ENT.ENVYS_ENMITY_HEAD_1.variant, data.EnvyEnmnityNumSplits_1, 0)
        enmityStageCache(player, 0, REVEL.ENT.ENVYS_ENMITY_HEAD_2.variant, data.EnvyEnmnityNumSplits_2, data.EnvyEnmnityNumSplits_1)
        enmityStageCache(player, 0, REVEL.ENT.ENVYS_ENMITY_HEAD_3.variant, data.EnvyEnmnityNumSplits_3, data.EnvyEnmnityNumSplits_2)
        enmityStageCache(player, 0, REVEL.ENT.ENVYS_ENMITY_HEAD_4.variant, 0, data.EnvyEnmnityNumSplits_3)
    end
end)

local function getEnmityStage(variant)
    local stage = nil
    if variant == REVEL.ENT.ENVYS_ENMITY_HEAD_1.variant then
        stage = 1
    elseif variant == REVEL.ENT.ENVYS_ENMITY_HEAD_2.variant then
        stage = 2
    elseif variant == REVEL.ENT.ENVYS_ENMITY_HEAD_3.variant then
        stage = 3
    elseif variant == REVEL.ENT.ENVYS_ENMITY_HEAD_4.variant then
        stage = 4
    end
    return stage
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, -1, -1, false, false)) do
        if getEnmityStage(familiar.Variant) then
            familiar:Remove()
        end
    end
    for _, player in ipairs(REVEL.players) do
        if REVEL.ITEM.ENVYS_ENMITY:PlayerHasCollectible(player) then
            local data = REVEL.GetData(player)
            data.EnvyEnmnityNumSplits_1 = 0
            data.EnvyEnmnityNumSplits_2 = 0
            data.EnvyEnmnityNumSplits_3 = 0
            player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            player:EvaluateItems()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, familiar)
    local stage = getEnmityStage(familiar.Variant)
    if stage then
        local data, sprite = REVEL.GetData(familiar), familiar:GetSprite()
        data.OrbitSet = nil

        if stage > 1 then
            familiar:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            sprite:Play("Appear" .. tostring(stage), true)
        else
            if REVEL.room:GetFrameCount() < 2 then
                familiar:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end
            sprite:Play("Idle", true)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
    local stage = getEnmityStage(familiar.Variant)
    if stage and familiar.Player then
        local data, sprite = REVEL.GetData(familiar), familiar:GetSprite()

        if not data.IsSuper and familiar.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
            sprite:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/envys_enmity_super.png")
            sprite:LoadGraphics()
        end

        if not (data.EnmitySplitting or sprite:IsPlaying("Split") or sprite:IsPlaying("Split" .. tostring(stage)) or sprite:IsFinished("Split") or sprite:IsFinished("Split" .. tostring(stage))) then
            --set idle animation
            if not (sprite:IsPlaying("Idle") or sprite:IsPlaying("Idle" .. tostring(stage)) or sprite:IsPlaying("Appear") or sprite:IsPlaying("Appear" .. tostring(stage))) then
                if stage == 1 then
                    sprite:Play("Idle", true)
                else
                    sprite:Play("Idle" .. stage, true)
                end
            end

            --set orbit distance
            local orbit = stage-1
            if not data.OrbitSet or (data.OrbitSet and data.OrbitSet ~= orbit) then
                data.OrbitSet = orbit
                familiar:RemoveFromOrbit()
                familiar:AddToOrbit(data.OrbitSet)
            end

            --split enmity if something harmful is near
            if stage < 4 and not (sprite:IsPlaying("Appear") or sprite:IsPlaying("Appear" .. tostring(stage))) then
                local split = false
                local instantSplit = false

                for _, tear in ipairs(Isaac.FindByType(EntityType.ENTITY_TEAR, -1, -1, false, false)) do
                    if familiar.Position:Distance(tear.Position) < tear.Size + familiar.Size then
                        split = true
                        break
                    end
                end
                for _, laser in ipairs(Isaac.FindByType(EntityType.ENTITY_LASER, -1, -1, false, false)) do
                    --tractor beam is variant 7
                    if laser.Variant ~= 7 and REVEL.CollidesWithLaser(familiar.Position, laser:ToLaser(), laser.Size + familiar.Size) then
                        split = true
                        break
                    end
                end
                for _, knife in ipairs(Isaac.FindByType(EntityType.ENTITY_KNIFE, -1, -1, false, false)) do
                    local knifeSprite = knife:GetSprite()
                    if knife.Variant < 1 or knifeSprite:IsPlaying("Spin") then
                        if familiar.Position:Distance(knife.Position) < knife.Size + familiar.Size then
                            split = true
                            break
                        end
                    elseif knife.SubType == KnifeSubtype.SWING then --handle forgotten bone swing
                        if knife.FrameCount > 1 and knife.FrameCount < 9 and knife.Parent then
                            local parent = knife.Parent
                            if parent:ToPlayer() then
                                local player = parent:ToPlayer()

                                --find the center of the swing object
                                ---@type EntityKnife
                                knife = knife:ToKnife()
                                local position = knife.Position
                                local scale = 30
                                if knife.Variant == 2 then --knife + bone
                                    scale = 42
                                end
                                scale = scale * knife.SpriteScale.X
                                local offset = Vector(scale,0)
                                offset = offset:Rotated(knife.Rotation)
                                position = position + offset

                                --envy enmity is inside the swipe
                                if (position - familiar.Position):Length() < familiar.Size + scale then
                                    split = true
                                    break
                                end
                            end
                        end
                    end
                end
                for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
                    if explosion.FrameCount == 1 and familiar.Position:Distance(explosion.Position) < 100 + familiar.Size then
                        split = true
                        instantSplit = true
                        break
                    end
                end

                if split and not data.EnmitySplitting then
                    data.EnmitySplitting = true
                    local stage = getEnmityStage(familiar.Variant)
                    if stage <= 1 then
                        sprite:Play("Split", true)
                    else
                        sprite:Play("Split" .. stage, true)
                    end
                    if instantSplit then
                        sprite:SetLastFrame()
                    end
                end
            end
        end

        --apply orbit distance
        if data.OrbitSet then
            familiar.OrbitDistance = EntityFamiliar.GetOrbitDistance(data.OrbitSet)
            familiar.Velocity = familiar:GetOrbitPosition(familiar.Player.Position - familiar.Player.Velocity) - familiar.Position
        end

        --handle any split that just happened
        if sprite:IsFinished("Split") or sprite:IsFinished("Split" .. tostring(stage)) then
            local playerData = REVEL.GetData(familiar.Player)
            if stage <= 1 then
                playerData.EnvyEnmnityNumSplits_1 = playerData.EnvyEnmnityNumSplits_1 + 1
            elseif stage == 2 then
                playerData.EnvyEnmnityNumSplits_2 = playerData.EnvyEnmnityNumSplits_2 + 1
            elseif stage >= 3 then
                playerData.EnvyEnmnityNumSplits_3 = playerData.EnvyEnmnityNumSplits_3 + 1
            end
            familiar:BloodExplode()
            familiar:Remove()
            familiar.Player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            familiar.Player:EvaluateItems()
        end
    end
end)

end