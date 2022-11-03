local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-----------------
-- FECAL FREAK --
-----------------

revel.fecalfreak = {}

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 1, function(e, data, spr, player)
    -- gives tears the fecal freak sprite
    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) 
    and e.SpawnerType == 1 then
        if not player:GetData().FiringFireTear then
            spr:Load("gfx/effects/revelcommon/fecal_freak_tear.anm2", true)
            spr:Play("Rotate", true)
            -- to fix this + items with big sprite resolution (and so small ingame scale), without this with ffreak and like mysterious liquid or fire mind you get very small tears
            -- so basically in the first frame it set the size normal then it gets smaller, soo we set it after
            if REVEL.IsHDTearSprite(e) then
                data.scaleFix = e.SpriteScale * 2
            end
            REVEL.sfx:Play(REVEL.SFX.FECAL_FREAK_FART, 0.9, 0, false,
                                0.8 + math.random() * 0.2)
        end
        data.ffreak = true
        REVEL.FFInvertTear(e, player)
    end
end)

function REVEL.FFInvertTear(e, player)
    local data = e:GetData()
    local dir = REVEL.GetDirectionFromVelocity(e.Velocity)
    -- if dir == Direction.LEFT or dir == Direction.RIGHT then
    --     e.Velocity = Vector(-e.Velocity.X + e.Parent.Velocity.X * 2, e.Velocity.Y)
    -- else
    --     e.Velocity = Vector(e.Velocity.X, -e.Velocity.Y + e.Parent.Velocity.Y * 2)
    -- end
    e.Velocity = -e.Velocity + e.Parent.Velocity * 2
    if data.vel then data.vel = e.Velocity end
    e.Position = e.Position + e.Velocity:Resized(player.Size)
end

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, e)
    local data = e:GetData()
    if data.scaleFix then
        e.SpriteScale = data.scaleFix
        data.scaleFix = nil
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_TEAR_POOF_INIT, 1,
                        function(poof, data, spr, parent, grandparent)
    -- gives tear poofs the fecal freak sprite and spawning a poop particle
    -- data gets removed on entity remove(which is when this callback is triggered)
    if parent:GetSprite():GetFilename() == "gfx/effects/revelcommon/fecal_freak_tear.anm2" then
        spr:Load("gfx/effects/revelcommon/fecal_freak_tear.anm2", true)
        spr:Play("Poof", true)
        local gib = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0,
                                poof.Position, Vector.Zero, REVEL.player)
        gib:GetSprite().Color = Color(0.5, 0.5, 0.5, 1, conv255ToFloat(60, 40, 0))
    end
end)

-- MYSTERIOUS LIQUID SYNERGY
StageAPI.AddCallback("Revelations", RevCallbacks.EFFECT_UPDATE_INIT, 1, function(e)
    if e.Variant == 53 and e:GetLastParent().Type == 1 and
        REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(REVEL.player) then
        e:GetSprite().Color = Color(1, 1, 0, 1, conv255ToFloat(75, 0, 0))
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) then
        -- making sure the shotspeed is a negative number
        -- spawns poop particles when the player is walking
        if (player.Velocity.X >= 1 or player.Velocity.Y >= 1) 
        and math.random(1, 30) == 1 then
            local g = Isaac.Spawn(
                1000, 
                EffectVariant.POOP_PARTICLE, 
                0,
                player.Position, 
                Vector.Zero, 
                player
            )
            g:GetSprite().Color = Color(
                0.5, 0.5, 0.5, 1,
                conv255ToFloat(60, 40, 0)
            )
        end

        -- GHOST PEPPER synergy: constant firestream from isaac's ass
        if player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER) 
        and not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) 
        and REVEL.IsShooting() and player.FrameCount % 6 == 0 then
            local input = REVEL.GetCorrectedFiringInput(player) * 10 * REVEL.player.ShotSpeed

            local fire = REVEL.ShootFireTear(
                player, 
                player.Position - input,
                input:Rotated(math.random() * 15 - 7.5) + player.Velocity * 0.5, 
                1, 
                true,
                0.75
            )
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    -- update fecal freak stats
    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 1.5 + 1.5
        end
    end
end)

-- active bean items synergy
revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, itemid, rng, player, useFlags, activeSlot, customVarData)
    --	Isaac.DebugString(tostring(ItemId))

    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) and (itemid == 111 or itemid == 294 or itemid == 351 or itemid == 421) then
        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position,
                                RandomVector() * (player.ShotSpeed * 10),
                                player)
        t:GetSprite():Load("gfx/effects/revelcommon/fecal_freak_tear.anm2",
                            true)
        t:GetSprite():Play("Rotate", true)
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()
