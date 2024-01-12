local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

---@param player EntityPlayer
---@param data table
function REVEL.Dante.Callbacks.DanteBook_PostUpdate(player, data)
    if revel.data.run.dante.IsDante or revel.data.run.dante.IsCombined then
        local fireDir = player:GetFireDirection()
        if fireDir ~= Direction.NO_DIRECTION then
            data.DanteBookDirection = fireDir
        end

        if not data.DanteBookDirection or data.DanteBookDirection < 0 then
            data.DanteBookDirection = Direction.DOWN
        end

        if data.DanteBashCooldown then
            data.DanteBashCooldown = data.DanteBashCooldown - 1
            if data.DanteBashCooldown <= 0 then
                local shieldDir = data.DanteBookDirection
                local shieldPosOffsetFrom = data.CharonIncubus or player
                local shieldangle = shieldDir * 90 - 180
                if not data.DanteBook then
                    data.DanteBook = Isaac.Spawn(REVEL.ENT.DANTE_BOOK.id, REVEL.ENT.DANTE_BOOK.variant, 0, shieldPosOffsetFrom.Position + Vector.FromAngle(shieldangle) * 20, Vector.Zero, player)
                    if shieldDir ~= Direction.UP then
                        data.DanteBook.RenderZOffset = player.RenderZOffset + 10
                    else
                        data.DanteBook.RenderZOffset = player.RenderZOffset - 10
                    end

                    local shieldSprite = data.DanteBook:GetSprite()
                    if shieldDir == Direction.DOWN then
                        shieldSprite:Play("ChargedDown", true)
                    elseif shieldDir == Direction.UP then
                        shieldSprite:Play("ChargedUp", true)
                    elseif shieldDir == Direction.RIGHT then
                        shieldSprite:Play("ChargedRight", true)
                    elseif shieldDir == Direction.LEFT then
                        shieldSprite:Play("ChargedLeft", true)
                    end

                    REVEL.sfx:Play(REVEL.SFX.CHARON_BOOK_READY, 0.75, 0, false, 1)
                end

                data.DanteBashCooldown = nil
            end
        end

        local fireDir = player:GetFireDirection()
        if fireDir == Direction.NO_DIRECTION then
            data.NotShootingLastFrame = true
        else
            if data.NotShootingLastFrame and not data.DanteBashCooldown then
                fireDir = data.DanteBookDirection
                local shieldPosOffsetFrom = player
                local shieldangle = fireDir * 90 - 180
                if not data.DanteBook then
                    data.DanteBook = Isaac.Spawn(REVEL.ENT.DANTE_BOOK.id, REVEL.ENT.DANTE_BOOK.variant, 0, shieldPosOffsetFrom.Position + Vector.FromAngle(shieldangle) * 20, Vector.Zero, player)
                    if fireDir ~= Direction.UP then
                        data.DanteBook.RenderZOffset = player.RenderZOffset + 10
                    else
                        data.DanteBook.RenderZOffset = player.RenderZOffset - 10
                    end
                end

                local shieldSprite = data.DanteBook:GetSprite()

                if fireDir == Direction.DOWN then
                    shieldSprite:Play("SmashDown", true)
                elseif fireDir == Direction.UP then
                    shieldSprite:Play("SmashUp", true)
                elseif fireDir == Direction.RIGHT then
                    shieldSprite:Play("SmashRight", true)
                elseif fireDir == Direction.LEFT then
                    shieldSprite:Play("SmashLeft", true)
                end

                REVEL.sfx:Play(REVEL.SFX.CHARON_BOOK_SLAM, 1, 0, false, 1+math.random()*0.07)

                local shieldRange = 80
                if data.IncubusDirection and data.IncubusDirection == fireDir then
                    shieldRange = shieldRange * 1.3
                end

                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and enemy.Position:DistanceSquared(shieldPosOffsetFrom.Position) < (enemy.Size + shieldRange) ^ 2 then
                        local enemyangle = (enemy.Position - shieldPosOffsetFrom.Position):GetAngleDegrees()
                        if math.abs(REVEL.GetAngleDifference(enemyangle, shieldangle)) < 70 then
                            REVEL.PushEnt(enemy, 14, (enemy.Position - shieldPosOffsetFrom.Position), 11, player, function(ent, edata)
                                if ent:CollidesWithGrid() then
                                    edata.entPushCount = 0
                                    ent:TakeDamage(REVEL.EstimateDPS(player), 0, EntityRef(player), 0)
                                    REVEL.sfx:Play(REVEL.SFX.CHARON_CRIT, 0.7, 0, false, 0.75)
                                    REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.4, 0, false, 1)
                                end
                            end)

                            enemy:GetData().DanteSigilEffect = 300
                            enemy:GetData().DanteSigilEffectPlayer = player
                        end
                    end
                end

                data.DanteBashCooldown = 60
            end

            data.NotShootingLastFrame = false
        end
    else
        data.DanteBashCooldown = nil
    end

    if data.DanteBook and not data.DanteBook:Exists() then
        data.DanteBook = nil
    elseif data.DanteBook then
        local shieldSprite = data.DanteBook:GetSprite()
        if not REVEL.MultiPlayingCheck(shieldSprite, "SmashDown", "SmashUp", 
                "SmashRight", "SmashLeft", "ChargedDown", "ChargedUp", 
                "ChargedRight", "ChargedLeft") then
            data.DanteBook:Remove()
            data.DanteBook = nil
        else
            local following = player
            local angle = data.DanteBookDirection * 90 - 180
            data.DanteBook.Velocity = ((following.Position + Vector.FromAngle(angle) * 20) - data.DanteBook.Position) / 2
        end
    end
end

local redColor = Color(0.8,0.5,0.5,1,conv255ToFloat(180,30,0))

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if data.DanteSigilEffect then
        npc:SetColor(redColor, 2, 5, true, true)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc)
    if npc:GetData().DanteSigilEffectPlayer then
        local player = npc:GetData().DanteSigilEffectPlayer
        if player:GetData().DanteBashCooldown then
            player:GetData().DanteBashCooldown = player:GetData().DanteBashCooldown - 40
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    local data = npc:GetData()
    local isRenderPassNormal = REVEL.IsRenderPassNormal()

    if data.DanteSigilEffect then
        if not data.DanteSigilEffectEntity or not data.DanteSigilEffectEntity:Exists() then
            data.DanteSigilEffectEntity = Isaac.Spawn(StageAPI.E.GenericEffect.T, StageAPI.E.GenericEffect.V, 0, npc.Position, Vector.Zero, nil)
            data.DanteSigilEffectEntity:GetSprite():Load("gfx/itemeffects/revelcommon/dante_sigil.anm2", true)
            data.DanteSigilEffectEntity:GetSprite():Play("Appear", true)
            data.DanteSigilEffectEntity.Visible = false
            data.DanteSigilEffectEntity:GetData().IsDanteSigil = true
            data.DanteSigilEffectEntity:GetData().Owner = npc
        end

        if not REVEL.game:IsPaused() and isRenderPassNormal then
            data.DanteSigilEffect = data.DanteSigilEffect - 1
            if data.DanteSigilEffect <= 0 then
                data.DanteSigilEffect = nil
                data.DanteSigilEffectPlayer = nil
            end
        end
    end

    if data.DanteSigilEffectEntity then
        if data.DanteSigilEffectEntity:Exists() then
            local sigilSprite = data.DanteSigilEffectEntity:GetSprite()
            if sigilSprite:IsFinished("Appear") then
                sigilSprite:Play("Idle", true)
            end

            if sigilSprite:IsFinished("Disappear") then
                data.DanteSigilEffectEntity:Remove()
            else
                if not data.DanteSigilEffect and not sigilSprite:IsPlaying("Disappear") then
                    sigilSprite:Play("Disappear", true)
                end

                if npc.Visible then
                    sigilSprite:Render(Isaac.WorldToScreen(npc.Position + Vector(0, npc.Size * -5)) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            end
        else
            data.DanteSigilEffectEntity = nil
        end
    end
end)

local justCalledTakeDamage
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags, source, iframes)
    local data = e:GetData()
    if data.DanteSigilEffect and not justCalledTakeDamage and not HasBit(flags, DamageFlag.DAMAGE_CLONES) and not e.Parent then
        justCalledTakeDamage = true
        local newAmount = amount
        if revel.data.run.dante.IsCombined then
            newAmount = amount * 0.65
        else
            newAmount = amount * 1.5
        end

        if e.FrameCount - (data.danteLastBleedFrame or 0) > 5 then
            for i=1, 3 do
            Isaac.Spawn(1000, EffectVariant.BLOOD_PARTICLE, 0, e.Position + RandomVector() * 3, RandomVector() * 5, e)
            end
            data.danteLastBleedFrame = e.FrameCount
            REVEL.sfx:Play(REVEL.SFX.CHARON_CRIT, 0.5, 0, false, 1)
            REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.4, 0, false, 1)
        end

        e:TakeDamage(newAmount, flags, source, iframes)
        justCalledTakeDamage = nil
    end
end)

-- Fallback for the sigil getting stuck sometimes, not necessary most times
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
    local sprite, data = e:GetSprite(), e:GetData()
    if data.IsDanteSigil then
        if not data.Owner:Exists() or data.Owner:IsDead() then
            if sprite:IsFinished("Disappear") then
                e:Remove()
            elseif not sprite:IsPlaying("Disappear") then
                if not data.DisappearCountdown then
                    data.DisappearCountdown = 30
                else
                    data.DisappearCountdown = data.DisappearCountdown - 1
                    if data.DisappearCountdown <= 0 then
                        sprite:Play("Disappear", true) 
                    end
                end
            end
        end
    end
end, StageAPI.E.GenericEffect.V)

end