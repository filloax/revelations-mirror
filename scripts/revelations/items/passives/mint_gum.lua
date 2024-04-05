local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
--------------
-- MINT GUM --
--------------

--[[
    Shoot frost tears that slow enemies, on fifth hit enemies get frozen.
    ]]

local MintGum = {}
MintGum.defFreezeHits = 5 -- hits required to freeze something
MintGum.defCooldownMult = 1 -- cooldown before unfreezing is multiplied by this
MintGum.freezeAgain = 40 -- cooldown before enemy can be frozen again
MintGum.frozenEnts = {}

local MIN_FRICTION = 0.8
local EnabledInBosses = 1 -- 0: no bosses at all, 1: only aesthetic (chance of using frozen skin) and slows projectiles 2: works normally with boss nerfs

local parentEntityLists = {
    FreezeParent = {
        [EntityType.ENTITY_MRMAW] = {0, 2, OnlyParent = true}, -- normal mr maw body, red mr maw body
        [EntityType.ENTITY_GRUB] = {0},
        [EntityType.ENTITY_LARRYJR] = {0, 1},
        [EntityType.ENTITY_BUTTLICKER] = {0},
        [EntityType.ENTITY_SWINGER] = {1},
        [EntityType.ENTITY_GEMINI] = {1, 11}
    },

    FreezeChild = {
        [EntityType.ENTITY_GRUB] = {0},
        [EntityType.ENTITY_LARRYJR] = {0, 1},
        [EntityType.ENTITY_BUTTLICKER] = {0},
        [EntityType.ENTITY_SWINGER] = {0},
        [EntityType.ENTITY_GEMINI] = {0, 10},
        [EntityType.ENTITY_HEART] = {0}
    },

    UpdateParentOnDeath = {[EntityType.ENTITY_SWINGER] = {1}},

    UpdateChildOnDeath = {
        [EntityType.ENTITY_SWINGER] = {0},
        [EntityType.ENTITY_HEART] = {0}
    }
}

local EntityBlacklist = {
    [REVEL.ENT.FROZEN_SPIDER.id] = {
        [REVEL.ENT.FROZEN_SPIDER.variant] = true
    }
}

REVEL.MintgumParentEntityLists = parentEntityLists

local function getColor(shots, maxHits)
    return Color(1, 1, 1, 1, conv255ToFloat(0, math.floor(shots * 90 / maxHits), math.floor(shots * 150 / maxHits)))
end

local function getFrictionMult(shots, maxHits)
    return REVEL.Lerp2Clamp(MIN_FRICTION, 1, shots, maxHits, 0)
end

function REVEL.GumHitEnt(e, maxHits, cooldownMult, noParents, noChildren, asBoss)
    if EntityBlacklist[e.Type] and EntityBlacklist[e.Type][e.Variant] then
        return
    end

    if not noParents and e.Parent and parentEntityLists.FreezeParent[e.Type] and
        REVEL.includes(parentEntityLists.FreezeParent[e.Type], e.Variant) then
        REVEL.GumHitEnt(e.Parent, maxHits, cooldownMult, false, true)
        asBoss = e.Parent:IsBoss()

        if parentEntityLists.FreezeParent[e.Type].OnlyParent then
            return
        end
    end
    if not noChildren and e.Child and parentEntityLists.FreezeChild[e.Type] and
        REVEL.includes(parentEntityLists.FreezeChild[e.Type], e.Variant) then
        REVEL.GumHitEnt(e.Child, maxHits, cooldownMult, true, false, e:IsBoss())
    end

    local spr, data = e:GetSprite(), REVEL.GetData(e)

    if (e:IsBoss() or asBoss) and EnabledInBosses == 0 then return end

    maxHits = maxHits or MintGum.defFreezeHits
    cooldownMult = cooldownMult or MintGum.defCooldownMult
    data.mintGumShot = data.mintGumShot or 0


    if not data.MintgumFrozen 
    and (data.freezeCooldown == 0 or not data.freezeCooldown) 
    then
        if data.mintGumShot < maxHits then
            data.mintGumTimeOut = 40 * cooldownMult
            if asBoss or e:IsBoss() then
                if EnabledInBosses == 2 then
                    data.mintGumTimeOut = data.mintGumTimeOut * 0.6
                end
                data.mintGumConsiderBoss = true
            end
            e:SetColor(getColor(data.mintGumShot, maxHits), data.mintGumTimeOut, 99, true, true)
        elseif data.mintGumShot == maxHits then
            REVEL.GumFreezeEnt(e, spr, data)
        end

        data.mintGumShot = math.min(data.mintGumShot + 1, maxHits)
    end
    data.mintGumMaxShots = maxHits
end

local function tryGlacierSkin(npc)
    if math.random() > 0.5 and REVEL.GetData(npc).RevelReskin ~= "Glacier" then -- and not npc:IsBoss() then --turn to frost variant
        return REVEL.ForceReplacement(npc, "Glacier")
    end
end

function REVEL.GumFreezeEnt(e, spr, data)
    data = data or REVEL.GetData(e)
    spr = spr or e:GetSprite()

    if data.mintGumConsiderBoss and EnabledInBosses == 1 then -- just reskin
        if tryGlacierSkin(e) then
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 1, 0, false, 1)
            REVEL.SpawnMeltEffect(e.Position)
        end
        data.mintGumTimeOut = data.mintGumTimeOut * 2.2
    else
        spr.Color = REVEL.CHILL_COLOR
        e:AddEntityFlags(EntityFlag.FLAG_FREEZE)
        if data.mintGumConsiderBoss or e:IsBoss() then
            data.mintGumTimeOut = 40
        else
            data.mintGumTimeOut = 120
        end
        REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 1, 0, false, 1)
        table.insert(MintGum.frozenEnts, e)
    end
    data.MintgumFrozen = true
end

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    local data = REVEL.GetData(e)

    if REVEL.OnePlayerHasCollectible(REVEL.ITEM.MINT_GUM.id) 
    and src.Entity 
    and (src.Entity.Type == 1 or (src.Entity.SpawnerType == 1 and src.Entity.Type ~= EntityType.ENTITY_FAMILIAR)) 
    and e:IsVulnerableEnemy() 
    and e.Type ~= REVEL.ENT.FLURRY_HEAD.id 
    then
        local player = REVEL.GetPlayerFromDmgSrc(src)
        if player and REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
            local freezeHits
            if e:IsBoss() then
                freezeHits = REVEL.GetData(player).freezeHits + 5
            else
                freezeHits = REVEL.GetData(player).freezeHits
            end

            REVEL.GumHitEnt(e, freezeHits, REVEL.GetData(player).mintCooldownMult)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, e)
    local data = REVEL.GetData(e)
    if data.mintGumTimeOut and data.mintGumShot and data.mintGumTimeOut >= 0 then
        if data.mintGumTimeOut > 0 then
            data.mintGumTimeOut = math.max(0, data.mintGumTimeOut - 1)
            if not data.mintGumConsiderBoss or EnabledInBosses == 2 then -- in the case the effect is only graphical for bosses, reset the skin chance
                e:MultiplyFriction(getFrictionMult(data.mintGumShot,
                                                    data.mintGumMaxShots))
            end
        elseif data.mintGumTimeOut == 0 then
            data.mintGumTimeOut = -1
            data.mintGumShot = 0
            if data.mintGumConsiderBoss and EnabledInBosses == 1 then -- in the case the effect is only graphical for bosses, reset the skin chance
                data.MintgumFrozen = false
            end
        end
    end
    if data.freezeCooldown then
        data.freezeCooldown = math.max(0, data.freezeCooldown - 1)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.PROJECTILE_UPDATE_INIT, 1, function(projectile)
    local owner = projectile.SpawnerEntity or projectile.Parent
    if not owner or not owner:Exists() then return end

    local odata = REVEL.GetData(owner)
    local data = REVEL.GetData(projectile)

    if odata.mintGumShot and odata.mintGumTimeOut and odata.mintGumShot > 0 and
        odata.mintGumTimeOut > 0 then
        data.MintGumSlowed = getFrictionMult(odata.mintGumShot, odata.mintGumMaxShots) ^ 2
        data.MintGumColor = REVEL.ColorMult(projectile.Color,getColor(odata.mintGumShot, odata.mintGumMaxShots))
        projectile:SetColor(data.MintGumColor, 7, 50, true, true)

        projectile.Velocity = projectile.Velocity * data.MintGumSlowed
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, projectile)
    local data = REVEL.GetData(projectile)
    if data.MintGumSlowed and data.MintGumColor then
        -- projectile.Velocity = projectile.Velocity * data.MintGumSlowed
        projectile:SetColor(data.MintGumColor, 7, 50, true, true)
    end
end)

local toRemove = {}

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if #MintGum.frozenEnts == 0 then return end

    -- Countdown on frozen enemies, as they don't call npcUpdates
    local e, data
    for i = #MintGum.frozenEnts, 1, -1 do -- count downwards to allow for better table removing
        e = MintGum.frozenEnts[i]
        if not toRemove[GetPtrHash(e)] and not e:IsDead() and e:Exists() and
            e.HitPoints > 0 then
            data = REVEL.GetData(e)

            if data.mintGumTimeOut and data.mintGumTimeOut > 0 then
                data.mintGumTimeOut = data.mintGumTimeOut - 1
                e:SetColor(REVEL.CHILL_COLOR, 1, 1, false, true) -- to prevent replacing the "got hit" red color
            elseif data.mintGumTimeOut == 0 or not data.mintGumTimeOut then
                e:SetColor(REVEL.CHILL_COLOR, 10, 1, true, true)
                data.mintGumTimeOut = -1
                data.mintGumShot = 0
                if data.mintGumConsiderBoss or e:IsBoss() then
                    data.freezeCooldown = MintGum.freezeAgain * 3
                else
                    data.freezeCooldown = MintGum.freezeAgain
                end

                data.MintgumFrozen = false
                e:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                REVEL.sfx:NpcPlay(e:ToNPC(), REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
                table.remove(MintGum.frozenEnts, i)
                tryGlacierSkin(e)
            end
        else
            if e:Exists() then
                e:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                if e.Parent and e.Parent:Exists() and
                    parentEntityLists.UpdateParentOnDeath[e.Type] and
                    REVEL.includes(
                        parentEntityLists.UpdateParentOnDeath[e.Type],
                        e.Variant) then
                    e.Parent:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                    e.Parent:Update()
                end
                if e.Child and e.Child:Exists() and
                    parentEntityLists.UpdateChildOnDeath[e.Type] and
                    REVEL.includes(parentEntityLists.UpdateChildOnDeath[e.Type],
                                e.Variant) then
                    e.Child:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                    e.Child:Update()
                end

                e:Update()
                REVEL.MeltEntity(e)
            end

            if toRemove[GetPtrHash(e)] then
                toRemove[GetPtrHash(e)] = nil
            end
            table.remove(MintGum.frozenEnts, i)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_TEARCOLOR and
        REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
        if not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
            player.TearColor = Color(0.5, 0.9, 0.9, 1, conv255ToFloat(0, 0, 0))
        end
        player.LaserColor = Color(0, 1, 1, 1, conv255ToFloat(0, 70, 100))
    elseif flag == CacheFlag.CACHE_WEAPON and
        REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
        local data = REVEL.GetData(player)
        data.freezeHits = MintGum.defFreezeHits
        data.mintCooldownMult = MintGum.defCooldownMult

        -- Continuous damage items
        if REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
            data.freezeHits = 70
        elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) or
            player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_2) or
            player:HasWeaponType(WeaponType.WEAPON_KNIFE) then
            data.freezeHits = 10
            -- Lesser continuous damage (ie less easy to continuously attack an enemy with)
        elseif player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) or
            player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            data.freezeHits = 7
            -- Reduced speed stuff that usually increases your damage a lot
        elseif player:HasWeaponType(WeaponType.WEAPON_ROCKETS) or
            player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
            data.freezeHits = 3
            data.mintCooldownMult = data.mintCooldownMult * 2
        elseif REVEL.HasBrokenOarEffect(player) then
            data.freezeHits = 20
        end
    end
end)

end
