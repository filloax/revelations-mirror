return function()
------------------
-- PERSEVERANCE --
------------------

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source)
    if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() then
        local entityData = entity:GetData()
        if not entityData.TakingPerseveranceDamage and source and source.Entity then
            local player = REVEL.GetPlayerFromDmgSrc(source)
            if player and REVEL.ITEM.PERSEVERANCE:PlayerHasCollectible(player) then

                local playerData = player:GetData()

                local currentFrame = Isaac.GetFrameCount()

                if playerData.PerseveranceEntity and GetPtrHash(playerData.PerseveranceEntity) == GetPtrHash(entity) then

                    entityData.PerseverancePercentage = entityData.PerseverancePercentage or 0
                    entityData.PerseveranceLastDamageBuff = entityData.PerseveranceLastDamageBuff or 0

                    if entityData.PerseveranceLastDamageBuff + 10 <= currentFrame then
                        entityData.PerseveranceLastDamageBuff = currentFrame
                        for i=1, player:GetCollectibleNum(REVEL.ITEM.PERSEVERANCE.id) do
                            entityData.PerseverancePercentage = entityData.PerseverancePercentage + 5
                        end
                    end

                    if entityData.PerseverancePercentage > 0 then
                        local percentCap = 100
                        if entity:IsBoss() then
                            percentCap = 50
                        end
                        entityData.PerseverancePercentage = math.min(entityData.PerseverancePercentage,percentCap)

                        REVEL.sfx:Play(REVEL.SFX.CHARON_CRIT, 0.4, 0, false, ((entityData.PerseverancePercentage*0.005)+0.5))
                        REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.4, 0, false, 1)
                        local extraDamage = amount * (entityData.PerseverancePercentage * 0.01)
                        -- entity.HitPoints = entity.HitPoints - extraDamage
                        entityData.TakingPerseveranceDamage = true
                        entity:TakeDamage(extraDamage, flags, EntityRef(entity), 0)
                        entityData.TakingPerseveranceDamage = false
                    end
                else
                    entityData.PerseverancePercentage = 0
                end

                playerData.PerseveranceEntity = entity
                entityData.PerseveranceAnimation = entityData.PerseveranceAnimation or 1

                if not entityData.PerseveranceSprite then
                    entityData.PerseveranceSprite = Sprite()
                    entityData.PerseveranceSprite:Load("gfx/itemeffects/revelcommon/perseverance.anm2", true)
                    entityData.PerseveranceSprite:Play("Appear", true)
                end
                
                local newAnimation = math.max(math.min(1 + math.floor(((1 - entity.HitPoints/entity.MaxHitPoints)*6)), 6), 1)
                if entityData.PerseveranceAnimation ~= newAnimation then
                    entityData.PerseveranceAnimation = newAnimation
                    if not entityData.PerseveranceSprite:IsPlaying("Appear") and not entityData.PerseveranceSprite:IsPlaying("Disappear") then
                        entityData.PerseveranceSprite:SetFrame("Idle" .. tostring(entityData.PerseveranceAnimation), 0)
                    end
                end
                
                local colorTint = entityData.PerseverancePercentage
                local colorTintFloat = math.max(0.5, 1 - (colorTint/255))
                entityData.PerseveranceSprite.Color = Color(1,colorTintFloat,colorTintFloat,1,conv255ToFloat(colorTint,0,0))
                entityData.PerseveranceSprite.Scale = Vector(1,1) * ((entityData.PerseverancePercentage*0.005)+1)
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local npcData = npc:GetData()
    if npcData.PerseverancePercentage then
        if not npcData.PerseveranceSprite then
            npcData.PerseveranceSprite = Sprite()
            npcData.PerseveranceSprite:Load("gfx/itemeffects/revelcommon/perseverance.anm2", true)
            npcData.PerseveranceSprite:Play("Appear", true)
        end
        npcData.PerseveranceSprite:Update()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    local npcData = npc:GetData()
    if npcData.PerseverancePercentage then
        if not npcData.PerseveranceSprite then
            npcData.PerseveranceSprite = Sprite()
            npcData.PerseveranceSprite:Load("gfx/itemeffects/revelcommon/perseverance.anm2", true)
            npcData.PerseveranceSprite:Play("Appear", true)
        end

        local foundPlayer = false
        for i, player in ipairs(REVEL.players) do
            local playerData = player:GetData()
            if playerData.PerseveranceEntity then
                if GetPtrHash(playerData.PerseveranceEntity) == GetPtrHash(npc) then
                    foundPlayer = true
                end
            end
        end

        if npcData.PerseveranceSprite:IsFinished("Appear") then
            npcData.PerseveranceSprite:SetFrame("Idle" .. tostring(npcData.PerseveranceAnimation or 1), 0)
        elseif npcData.PerseveranceSprite:IsFinished("Disappear") then
            npcData.PerseveranceSprite = nil
            npcData.PerseverancePercentage = nil
            return
        elseif not foundPlayer and not npcData.PerseveranceSprite:IsPlaying("Disappear") and not npcData.PerseveranceSprite:IsFinished("Disappear") then
            npcData.PerseveranceSprite:Play("Disappear", true)
            npcData.PerseverancePercentage = 0
        end

        if foundPlayer or npcData.PerseveranceSprite:IsPlaying("Disappear") then
            npcData.PerseveranceSprite:Render(Isaac.WorldToScreen(npc.Position + Vector(0, npc.Size * -5)) + renderOffset - REVEL.room:GetRenderScrollOffset())
        end
    end
end)

end