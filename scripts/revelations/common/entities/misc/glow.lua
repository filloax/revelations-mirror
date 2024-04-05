return function()

-----------------------
-- ISAAC CUSTOM GLOW --
-----------------------

--Spawn an effect to act as a sprite behind Isaac
--Default sprite: Dynamo
--Sprite is the path to an anm2
--Time is the timeout for the effect, can be nil or negative for no timeout
--FadeOut is the duration of the fade out after time runs out, can be nil for no fadeout
--Anim is the animation that will be played
function REVEL.SpawnCustomGlow(player, anim, sprite, time, fadeOut)
    player = player or REVEL.player
    anim = anim or "default"
    sprite = sprite or "gfx/itemeffects/revelcommon/dynamo_effect.anm2"

    local eff = REVEL.ENT.GLOW_EFFECT:spawn(player.Position, player.Velocity, player):ToEffect()
    local data = REVEL.GetData(eff)

    --  eff:FollowParent(REVEL.player)
    eff.DepthOffset = -10

    data.time = time or -1
    data.fadeOut = fadeOut or -1
    data.fadeOutMax = fadeOut or -1

    data.customGlowSprite = Sprite()
    data.customGlowSprite:Load(sprite, true)
    data.customGlowSprite:Play(anim, true)

    eff.Parent = player
    eff.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    eff.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    return eff
end

--Update the tear effect thing
REVEL.ENT.GLOW_EFFECT:addCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(eff, renderOffset)
    local data = REVEL.GetData(eff)

    eff.Velocity = ((eff.Parent.Position + eff.Parent.Velocity) - eff.Position) * 1.75
    eff.Friction = eff.Parent.Friction
    eff.SpriteOffset = eff.Parent.SpriteOffset

    if StageAPI.IsOddRenderFrame and not REVEL.game:IsPaused() and data.time and REVEL.IsRenderPassNormal() then
        data.customGlowSprite:Update()
        if data.customGlowSprite:WasEventTriggered("Finish") or (data.time == 0 and data.fadeOut <= 0)then
            eff:Remove()
        elseif data.time > 0 then
            data.time = data.time-1
        elseif data.time == 0 then
            data.fadeOut = data.fadeOut - 1
            data.customGlowSprite.Color = Color(1,1,1,data.fadeOut/data.fadeOutMax,conv255ToFloat(0,0,0))
        end
    end

    if eff:Exists() and eff.Visible and eff.Parent.Visible 
    and not eff.Parent:IsDead() 
    and (not eff.Parent:ToPlayer() or (eff.Parent:ToPlayer() and eff.Parent:ToPlayer():IsExtraAnimationFinished())) then
        data.customGlowSprite:Render(Isaac.WorldToScreen(eff.Parent.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector(0,0), Vector(0,0))
    end
end)

end