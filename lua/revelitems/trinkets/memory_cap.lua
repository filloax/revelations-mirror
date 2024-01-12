--Idea inspired by bean thank you

local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

----------------
-- MEMORY CAP --
----------------

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.FrameCount == 0 then
        if REVEL.OnePlayerHasTrinket(REVEL.ITEM.MEMORY_CAP.id) then
            if REVEL.room:IsFirstVisit() and not npc:GetData().MemoryCapped
            and npc:IsVulnerableEnemy() and not npc:IsBoss() 
            and not npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
            and not npc:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
            and not npc:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
            and npc.EntityCollisionClass > 0
            and npc.Type ~= EntityType.ENTITY_FIREPLACE then
                local rng = npc:GetDropRNG()
                if rng:RandomFloat() <= 0.12 then
                    npc:GetData().MemoryCapped = true
                    for i = 0, 10 do
                        npc:GetSprite():ReplaceSpritesheet(i,"gfx/effects/revelcommon/pranshu/even_better/fun_glacier.png")
                    end
                    npc:GetSprite():LoadGraphics()
                    local color = Color(1,1,1,1)
                    color:SetColorize(0,0,0,1)
                    npc.Color = color
                end
            end
        end
    end

    if npc:GetData().MemoryCapped then
        local color = Color(1,1,1,1)
        color:SetColorize(0,0,0,1)
        npc.Color = color

        if npc.FrameCount % 10 == 0 then
            local particle = Isaac.Spawn(1000, EffectVariant.EMBER_PARTICLE, 0, npc.Position, RandomVector():Resized(3), npc):ToEffect()
            particle.Color = color
            particle.SpriteScale = Vector(4,4)
            particle.SpriteOffset = Vector(-8,-30)
            particle.Timeout = 10
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, ent)
    if npc:GetData().MemoryCapped then
        if ent.Type == EntityType.ENTITY_PLAYER then
            npc:Remove()

            local mult = ent:ToPlayer():GetTrinketMultiplier(REVEL.ITEM.MEMORY_CAP.id)

            if ent:GetData().MemoryCapped then
                ent:GetData().MemoryCapped.Timer = ent:GetData().MemoryCapped.Timer + (50 * mult)
            else
                ent:GetData().MemoryCapped = {}
                ent:GetData().MemoryCapped.Timer = 150 + (50 * mult)
                ent:GetData().MemoryCapped.Sprite = Sprite()
                ent:GetData().MemoryCapped.Sprite:Load("gfx/effects/revelcommon/player_blackout.anm2",true)
                ent:GetData().MemoryCapped.Sprite:Play("Idle",true)
                ent:GetData().MemoryCapped.Sprite.Scale = ent.SpriteScale*1.05
            end

            REVEL.sfx:Play(SoundEffect.SOUND_EDEN_GLITCH)

            return false
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc)
    if npc:GetData().MemoryCapped and npc.Type == EntityType.ENTITY_PLAYER then
        return false
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, npc)
    if npc:GetData().MemoryCapped then
        if npc:GetData().MemoryCapped.Timer > 0 then
            npc:GetData().MemoryCapped.Timer = npc:GetData().MemoryCapped.Timer - 1
        else
            npc:GetData().MemoryCapped = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, pro)
    if pro.FrameCount == 0 and pro.SpawnerEntity and pro.SpawnerEntity:GetData().MemoryCapped then
        pro:GetSprite():ReplaceSpritesheet(0,"gfx/effects/revelcommon/pranshu/even_better/fun_glacier.png")
        pro:GetSprite():LoadGraphics()
        local color = Color(1,1,1,1)
        color:SetColorize(0,0,0,1)
        pro.Color = color
        pro.SpriteScale = Vector(0.5,0.5)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, renderOffset)
    if player:GetData().MemoryCapped then
        player:GetData().MemoryCapped.Sprite:Render(Isaac.WorldToScreen(player.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end)

end