local SpikeState = require "lua.revelcommon.enums.SpikeState"

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
--    OOPS!    --
-----------------

local function eString(type, var)
    return type .. "." .. var
end

local bombEnemies = {
    forceExplode = {
        eString(REVEL.ENT.CANNONBIP.id, REVEL.ENT.CANNONBIP.variant),
        eString(EntityType.ENTITY_MIGRAINE, 0), --migraine
        eString(EntityType.ENTITY_FLY_BOMB, 0), --fly bomb
        eString(EntityType.ENTITY_FLY_BOMB, 1), --eternal fly bomb
        eString(EntityType.ENTITY_FARTIGAN, 0), --fartigan
        eString(EntityType.ENTITY_BLASTER, 0), --blaster
    },
    kill = {
        eString(REVEL.ENT.DEMOBIP.id, REVEL.ENT.DEMOBIP.variant),
        eString(EntityType.ENTITY_MULLIGAN, 2), --mulliboom
        eString(EntityType.ENTITY_BOOMFLY, 0), --boomfly
        eString(EntityType.ENTITY_BOOMFLY, 2), --drowned boomfly
        eString(EntityType.ENTITY_BOOMFLY, 5), --sick boomfly
        eString(EntityType.ENTITY_BOOMFLY, 6), --tainted boomfly
        eString(EntityType.ENTITY_POISON_MIND, 0), --poison mind
        eString(EntityType.ENTITY_LEECH, 1), --kamikaze leech
        eString(EntityType.ENTITY_LEECH, 2), --holy leech
        eString(EntityType.ENTITY_TICKING_SPIDER, 0), --ticking spider
        eString(EntityType.ENTITY_BLACK_BONY, 0), --black bony
        eString(EntityType.ENTITY_BLACK_MAW, 0), --black maw
        eString(EntityType.ENTITY_POOFER, 0), --poofer
        eString(EntityType.ENTITY_POOT_MINE, 0), --poot mine
        eString(EntityType.ENTITY_ULTRA_COIN, 2), --greed coin
    }
}

if REVEL.FiendFolioCompatLoaded then
    REVEL.mixin(bombEnemies.forceExplode, {
        eString(FiendFolio.FF.Commission.ID, FiendFolio.FF.Commission.Var),
        eString(FiendFolio.FF.Blasted.ID, FiendFolio.FF.Blasted.Var),
    }, true)
    REVEL.mixin(bombEnemies.kill, {
        eString(FiendFolio.FF.Powderkeg.ID, FiendFolio.FF.Powderkeg.Var),
        eString(FiendFolio.FF.Mullikaboom.ID, FiendFolio.FF.Mullikaboom.Var),
        eString(FiendFolio.FF.Blastcore.ID, FiendFolio.FF.Blastcore.Var),
        eString(FiendFolio.FF.Rufus.ID, FiendFolio.FF.Rufus.Var),
        eString(FiendFolio.FF.Splodum.ID, FiendFolio.FF.Splodum.Var),
        eString(FiendFolio.FF.Boiler.ID, FiendFolio.FF.Boiler.Var),
        eString(FiendFolio.FF.ReheatedTickingFly.ID, FiendFolio.FF.ReheatedTickingFly.Var),
    }, true)
end

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent)
    if ent:GetData().OopsBlockDamage then
        return false
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        local oopsTriggered = false
        for i = 0, REVEL.room:GetGridSize() do
            local grid = REVEL.room:GetGridEntity(i)
            if grid then
                local gtype = grid.Desc.Type
                if gtype == GridEntityType.GRID_ROCK_BOMB and REVEL.CanGridBeDestroyed(grid) then
                    grid:Destroy()
                    oopsTriggered = true
                elseif gtype ==  GridEntityType.GRID_TNT and REVEL.CanGridBeDestroyed(grid) then
                    grid:Hurt(999)
                    oopsTriggered = true
                elseif grid:ToSpikes() and not REVEL.room:GetType() == RoomType.ROOM_SACRIFICE then
                    grid.State = SpikeState.SPIKE_OFF
                    grid:ToSpikes().Timeout = 99999
                    local sprite = grid:GetSprite()
                    local isUp, isWomb
                    for i = 1, 4 do
                        local normal, womb = "Spikes0" .. tostring(i), "WombSpikes0" .. tostring(i)
                        if sprite:IsPlaying(normal) or sprite:IsFinished(normal) or sprite:IsPlaying("Summon") or sprite:IsFinished("Summon") then
                            isUp = true
                            isWomb = false
                        elseif sprite:IsPlaying(womb) or sprite:IsFinished(womb) or sprite:IsPlaying("SummonWomb") or sprite:IsFinished("SummonWomb") then
                            isUp = true
                            isWomb = true
                        end
                    end

                    if isUp then
                        if isWomb then
                            sprite:Play("UnsummonWomb", true)
                        else
                            sprite:Play("Unsummon", true)
                        end
                    end

                    oopsTriggered = true
                elseif grid:ToPressurePlate() then
                    local oldPos = REVEL.player.Position
                    REVEL.player.Position = grid.Position
                    REVEL.player:GetData().OopsBlockDamage = true
                    grid:Update()
                    REVEL.player:GetData().OopsBlockDamage = false
                    REVEL.player.Position = oldPos
                    oopsTriggered = true
                end
            end
        end

        local movableTnt = Isaac.FindByType(EntityType.ENTITY_MOVABLE_TNT, 0)
        local bombs = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB)
        local floorEffects = Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V)

        for _, ent in ipairs(movableTnt) do
            if ent.Type == EntityType.ENTITY_MOVABLE_TNT and ent.Variant == 0 then
                if ent.HitPoints > 0.5 then
                    ent:Die()
                    oopsTriggered = true
                end
            end
        end
        for _, ent in ipairs(bombs) do

            if ent.Type == EntityType.ENTITY_PICKUP and ent.Variant == PickupVariant.PICKUP_BOMB then
                if not (ent.SubType == BombSubType.BOMB_TROLL or ent.SubType == BombSubType.BOMB_SUPERTROLL) then
                    Isaac.Explode(ent.Position, ent, 40)
                    ent:Remove()
                    oopsTriggered = true
                end
            end
        end

        for _, ent in ipairs(Isaac.FindInRadius(player.Position, 1000, EntityPartition.ENEMY)) do
            if REVEL.includes(bombEnemies.kill, eString(ent.Type, ent.Variant)) 
            or (ent:ToNPC() and ent:ToNPC():IsChampion() and ent:ToNPC():GetChampionColorIdx() == ChampionColor.BLACK) then
                if not (ent:IsDead() or ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
                    ent:Kill()
                    oopsTriggered = true
                end
            elseif REVEL.includes(bombEnemies.forceExplode, eString(ent.Type, ent.Variant)) then
                if not (ent:IsDead() or ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
                    Isaac.Explode(ent.Position, ent, 40)
                    ent:Remove()
                    oopsTriggered = true
                end
            end
        end
        for _, ent in ipairs(floorEffects) do
            if ent.Type == StageAPI.E.FloorEffect.T and ent.Variant == StageAPI.E.FloorEffect.V then
                local tdata = ent:GetData()
                if tdata.TrapData and REVEL.IsTrapTriggerable(ent, tdata) then
                    REVEL.TriggerTrap(ent, player, true)
                    oopsTriggered = true
                end
            end
        end

        local d = player:GetData()
        if not oopsTriggered then
            d.oopsTriggerCount = d.oopsTriggerCount or 0
            d.oopsTriggerCount = d.oopsTriggerCount + 1
            if d.oopsTriggerCount > 20 and math.random(1,100) == 1 then
                d.oopsExplodeCount = d.oopsExplodeCount or 0
                d.oopsExplodeCount = d.oopsExplodeCount + 1
                if d.oopsExplodeCount >= 3 and math.random(1,2) == 1 then
                    player:UseActiveItem(CollectibleType.COLLECTIBLE_MAMA_MEGA, UseFlag.USE_NOANIM | UseFlag.USE_NOCOSTUME)
                    if player:GetActiveItem() == itemID then
                        player:AnimateCollectible(itemID)
                        player:RemoveCollectible(itemID)
                    end
                else
                    d.oopsTriggerCount = 0
                    player:UseActiveItem(CollectibleType.COLLECTIBLE_KAMIKAZE, UseFlag.USE_NOANIM | UseFlag.USE_NOCOSTUME)
                end
            
            else
                if player:GetActiveItem() == itemID then
                    REVEL.DelayFunction(function()
                        player:FullCharge()
                        REVEL.sfx:Stop(SoundEffect.SOUND_BATTERYCHARGE)
                    end, 0, nil, false, true)
                end
                REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
            end
        else
            d.oopsTriggerCount = 0
            REVEL.game:ShakeScreen(10)
        end
    end
end, REVEL.ITEM.OOPS.id)

end