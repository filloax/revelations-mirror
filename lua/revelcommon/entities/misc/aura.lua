REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------
-- AURA --
----------
-- Includes projectile holding

local auraOffset = Vector(0, -12)
local spriteSize = 256;
local auraScale = Vector(3 * 56 / (114 * spriteSize), 3 * 56 / (114 * spriteSize))

function REVEL.SpawnAura(radius, position, color, spawner, follow, isFireAura, fire, instantRemove, chillFade, time)
    local aura = Isaac.Spawn(
        REVEL.ENT.DECORATION.id, REVEL.ENT.DECORATION.variant, 0, 
        position, Vector.Zero, spawner
    ):ToEffect()
    local sprite, data = aura:GetSprite(), aura:GetData()
    data.Radius = radius or 114
    data.Spawner = spawner
    sprite:Load("gfx/effects/revel1/brainfreeze_aura.anm2", false) --used for auras originally
    sprite:ReplaceSpritesheet(0, "gfx/effects/revel1/brainfreeze_aura.png")
    sprite:LoadGraphics()
    sprite:Play("Idle", true)
    if color then
        aura.Color = color
        aura:SetColor(color, -1, 1, false, false)
    end
    aura.Parent = spawner
    sprite.Scale = auraScale * data.Radius
    sprite.Offset = auraOffset
    data.IsAura = true
    data.IsFireAura = isFireAura
    data.Fire = fire
    data.InstantRemove = instantRemove
    data.ChillFade = chillFade
    data.Time = time or -1

    if follow and spawner then
        aura:FollowParent(spawner)
    end

    return aura, sprite, data
end

function REVEL.AuraExpandFade(aura, time, finalRadius)
    local data = aura:GetData()
    data.StartFade = true
    REVEL.FadeEntity(aura, time or 5)
    REVEL.AuraLerpToRadius(aura, finalRadius, time or 5)
end

function REVEL.AuraLerpToRadius(aura, newRadius, time)
    local data = aura:GetData()
    data.LerpToRadius = newRadius
    data.LerpToRadiusTime = time
    data.LerpToRadiusTimeStart = time
    data.LerpStartRadius = data.Radius
end

function REVEL.UpdateAuraRadius(aura, newRadius)
    REVEL.Assert(aura, "UpdateAuraRadius | aura nil!", 2)
    REVEL.Assert(newRadius, "UpdateAuraRadius | newRadius nil!", 2)

    if newRadius < 0 then
        newRadius = 0
    end

    aura:GetData().Radius = newRadius
    aura:GetSprite().Scale = auraScale * newRadius
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data = eff:GetData()
    if data.IsAura then
        if data.IsFireAura and data.Fire then
            local sprite = data.Fire:GetSprite()
            if sprite:IsPlaying("Flickering") or sprite:IsPlaying("Flickering2") or sprite:IsPlaying("Flickering3") then
                eff.Visible = true
            else
                eff.Visible = false
            end
        end

        if data.Time > 0 then
            data.Time = data.Time - 1
        end

        if data.Time == 0 or (data.Spawner and (data.Spawner:IsDead() or not data.Spawner:Exists())) then
            if data.InstantRemove then
                eff:Remove()
            else
                REVEL.UpdateAuraRadius(eff, data.Radius - math.floor(data.Radius / 15) - 1)
                if data.Radius <= 0 then
                    eff:Remove()
                end
            end
        end

        if data.ChillFade and not data.StartFade and not REVEL.ShouldUseWarmthAuras() then
            data.StartFade = true
            REVEL.FadeEntity(eff, REVEL.DEFAULT_CHILL_FADE_TIME)
        end

        if data.LerpToRadius then
            data.LerpToRadiusTime = data.LerpToRadiusTime - 1
            REVEL.UpdateAuraRadius(eff, REVEL.Lerp2Clamp(data.LerpToRadius, data.LerpStartRadius, data.LerpToRadiusTime, 0, data.LerpToRadiusTimeStart))
            if data.LerpToRadiusTime <= 0 then
                data.LerpToRadius = nil
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff, renderOffset)
    local data = eff:GetData()
    if data.IsAura then
        if (data.Spawner and not data.Spawner:GetData().NoAuraRerender) or (data.ForceSourceSprite and data.SourceSpritePosition) then
            local sourceSprite = data.ForceSourceSprite or data.Spawner:GetData().AuraSourceSprite or data.Spawner:GetSprite()
            if type(sourceSprite) == "table" then
                for _, sourceSprite in ipairs(sourceSprite) do
                    sourceSprite:Render(Isaac.WorldToScreen(data.SourceSpritePosition or data.Spawner.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            else
                sourceSprite:Render(Isaac.WorldToScreen(data.SourceSpritePosition or data.Spawner.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
        if data.RenderOnTop then
            for _, entity in pairs(data.RenderOnTop) do
                entity:GetSprite():Render(Isaac.WorldToScreen(entity.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
    end
end, REVEL.ENT.DECORATION.variant)

-- Brainfreeze-esque projectiles
function REVEL.HoldAuraProjectile(proj, aura)
    local data = proj:GetData()
    data.HeldByAura = aura
    data.Aura = aura
    data.AuraRadius = aura:GetData().Radius
    data.StartVel = proj.Velocity
    data.StartHeight = proj.Height
end

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    local data = proj:GetData()

    if data.HeldByAura then
        if not data.StartSpd then
            data.StartSpd = data.StartVel:Length()
        end

        if not data.HeldByAura:GetData().StartFade then
            proj.Height = data.StartHeight
            local dist = data.HeldByAura.Position:DistanceSquared(proj.Position)
            proj.Velocity = proj.Velocity:Resized(REVEL.Lerp2Clamp(data.StartSpd, 0, dist, 0, data.AuraRadius^2 * 0.8))
        else
            proj.Velocity = data.StartVel
            data.HeldByAura = nil
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()