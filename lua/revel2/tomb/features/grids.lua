local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.LocustDestroyedGrids = {}

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    REVEL.LocustDestroyedGrids = {}
end)

StageAPI.AddCallback("Revelations", "POST_OVERRIDDEN_GRID_BREAK", 1, function(grindex, grid, shroomData)
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoom = StageAPI.GetCurrentRoom()

        if grid:GetType() == GridEntityType.GRID_ROCK_ALT then
            REVEL.sfx:Stop(SoundEffect.SOUND_MUSHROOM_POOF)
            REVEL.sfx:Stop(SoundEffect.SOUND_MUSHROOM_POOF_2)
            REVEL.sfx:Play(SoundEffect.SOUND_POT_BREAK_2, 1, 0, false, 1)
        end

        local spawnedItem, spawnedFart, spawnedPickup
        if shroomData then
            for _, spawn in ipairs(shroomData) do
                if spawn.Type == EntityType.ENTITY_PICKUP and spawn.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    spawnedItem = true
                    break
                end

                if spawn.Type == EntityType.ENTITY_PICKUP and spawn.Variant == PickupVariant.PICKUP_PILL then
                    spawnedPickup = true
                    break
                end

                if spawn.Type == EntityType.ENTITY_EFFECT and spawn.Variant == EffectVariant.FART then
                    spawnedFart = true
                    break
                end
            end
        end

        local disableRockSpawn = currentRoom.Metadata:Has{Index = grindex, Name = "Disable Random Special Rock Spawn"}
        if spawnedItem then
            -- bandage baby
            if REVEL.IsAchievementUnlocked("BANDAGE_BABY") then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, REVEL.ITEM.BANDAGE_BABY.id, REVEL.room:GetGridPosition(grindex), Vector.Zero, nil)
            end
        elseif spawnedFart and not REVEL.LocustDestroyedGrids[grindex] and not disableRockSpawn then
            -- spawn enemy (don't want a locust softlock)
            --REVEL.ENT.INNARD:spawn(REVEL.room:GetGridPosition(grindex), Vector.Zero, nil)
        elseif spawnedPickup then
            local times = REVEL.RNG():RandomInt(2)+1
			for i = 1, times do
				local vec = Vector(1,0):Rotated(REVEL.RNG():RandomInt(360)+1)
				local coin = Isaac.Spawn(5, PickupVariant.PICKUP_COIN, 0, REVEL.room:GetGridPosition(grindex), vec, nil):ToPickup()
			end
        end

        if REVEL.LocustDestroyedGrids[grindex] then
            REVEL.LocustDestroyedGrids[grindex] = nil
        end
    end
end)

StageAPI.AddCallback("Revelations", "PRE_SPAWN_GRID", 1, function(gridEntry, gridInformation, entitySets, rng)
    if REVEL.STAGE.Tomb:IsStage() then
        if gridEntry.Type == GridEntityType.GRID_ROCK then
            return REVEL.TintedAltBombRockChance(gridEntry, rng)
        end
    end
end)
    
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if REVEL.STAGE.Tomb:IsStage() and REVEL.includes(REVEL.TombGfxRoomTypes, StageAPI.GetCurrentRoomType()) then
        eff:GetSprite():ReplaceSpritesheet(0, "gfx/grid/revel2/tile_rocks.png")
        eff:GetSprite():LoadGraphics()
    end
end, EffectVariant.ROCK_PARTICLE)

end

REVEL.PcallWorkaroundBreakFunction()
