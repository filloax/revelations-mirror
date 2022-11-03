local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-----------
-- GEODE --
-----------

REVEL.ITEM.GEODE:addPickupCallback(function(player)
    Isaac.Spawn(
        EntityType.ENTITY_PICKUP, 
        PickupVariant.PICKUP_TAROTCARD, 
        REVEL.game:GetItemPool():GetCard(REVEL.game.TimeCounter, false, true, true), 
        REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true), 
        Vector.Zero, 
        nil
    )
end)

local function GeodeCheck(position, lessParticles)
    local hasGeode = false
    for _, player in ipairs(REVEL.players) do
        if REVEL.ITEM.GEODE:PlayerHasCollectible(player) then
            hasGeode = true
            break
        end
    end
    
    if hasGeode then
        local soulheart_pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, false, false)
        local replaced = false
        for _, soulheart in ipairs(soulheart_pickups) do
            if soulheart.FrameCount == 0 and (position - soulheart.Position):LengthSquared() < 400 then
                local rune = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, REVEL.game:GetItemPool():GetCard(REVEL.game.TimeCounter, false, true, true), soulheart.Position, soulheart.Velocity, nil)
                soulheart:Remove()
                replaced = true
                
                for i=1, 2 do
                    local particle = Isaac.Spawn(
                        EntityType.ENTITY_EFFECT,
                        EffectVariant.POOP_PARTICLE, 
                        0, 
                        position + Vector(math.random()-0.5,math.random()-0.5)*40, 
                        Vector.FromAngle(math.random(0,359))*math.random(), 
                        nil
                    )
                    particle:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revelcommon/geode_gibs.png")
                    particle:GetSprite():LoadGraphics()
                    particle:GetData().IsGeodeParticle = true
                end
            end
        end

        if replaced then
            local num1, num2 = 15, 25
            if lessParticles then
                num1, num2 = 5, 8
            end

            for i = num1, num2 do
                local dir = RandomVector()
                REVEL.SpawnParticleGibs(
                    "gfx/effects/revelcommon/geode_particle.anm2", 
                    position + dir * math.random(10, 20), 
                    dir * math.random(1, 3)
                )
            end
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROCK_BREAK, 1, function(grid)
    if grid.Desc.Type == GridEntityType.GRID_ROCKT or grid.Desc.Type == GridEntityType.GRID_ROCK_SS then
        GeodeCheck(grid.Position)
    end
end)

local TINTED_ROCK_SPIDER_VARIANT = 1

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
    if entity.Variant == TINTED_ROCK_SPIDER_VARIANT then
        GeodeCheck(entity.Position, true)
    end
end, EntityType.ENTITY_ROCK_SPIDER)

end

REVEL.PcallWorkaroundBreakFunction()