local ShrineTypes = require("scripts.revelations.common.enums.ShrineTypes")
local RandomPickupSubtype = require("scripts.revelations.common.enums.RandomPickupSubtype")
local StageAPICallbacks   = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks        = require("scripts.revelations.common.enums.RevCallbacks")

return function()

REVEL.AddCommonShrine {
    Name = ShrineTypes.MISCHIEF,
    DisplayName = "Mischief",
    Description = "More pranks",
    Sprite = "gratuity",
    HudIconFrame = 0,
}

REVEL.AddCommonShrine {
    Name = ShrineTypes.CHAMPIONS,
    DisplayName = "Champions",
    Description = "Everything is\nterrible!",
    Repeatable = true,
    MaxRepeats = REVEL.ShrineBalance.ChampionMaxAmount,
    EID_Description = {
        Name = "Champions",
        Description = "Rev enemies can now become champions"
            .. "#Bosses will have a higher chance to become champions"
            .. "#Taking this multiple times will increase the chance"
    },
    Sprite = "champions",
    HudIconFrame = 1,
}

local PunishmentCollectibleBlacklist = {
    -- Quest items 
    CollectibleType.COLLECTIBLE_KEY_PIECE_1,
    CollectibleType.COLLECTIBLE_KEY_PIECE_2,
    CollectibleType.COLLECTIBLE_BROKEN_SHOVEL_1,
    CollectibleType.COLLECTIBLE_BROKEN_SHOVEL_2,
    CollectibleType.COLLECTIBLE_MOMS_SHOVEL,
    CollectibleType.COLLECTIBLE_KNIFE_PIECE_1,
    CollectibleType.COLLECTIBLE_KNIFE_PIECE_2,
    CollectibleType.COLLECTIBLE_POLAROID,
    CollectibleType.COLLECTIBLE_NEGATIVE,
    CollectibleType.COLLECTIBLE_DADS_NOTE,
    -- Rev quest items
    REVEL.ITEM.MIRROR.id,
    REVEL.ITEM.MIRROR2.id,
}
PunishmentCollectibleBlacklist = REVEL.toSet(PunishmentCollectibleBlacklist)

local PunishmentCharCollectibleBlacklist = {
    [PlayerType.PLAYER_ISAAC] = {
        CollectibleType.COLLECTIBLE_D6,
    },
    [PlayerType.PLAYER_MAGDALENA] = {
        CollectibleType.COLLECTIBLE_YUM_HEART,
    },
    [PlayerType.PLAYER_CAIN] = {
        CollectibleType.COLLECTIBLE_LUCKY_FOOT,
    },
    [PlayerType.PLAYER_JUDAS] = {
        CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL,
    },
    [PlayerType.PLAYER_BLUEBABY] = {
        CollectibleType.COLLECTIBLE_POOP,
    },
    [PlayerType.PLAYER_EVE] = {
        CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON,
        CollectibleType.COLLECTIBLE_DEAD_BIRD,
        CollectibleType.COLLECTIBLE_RAZOR_BLADE,
    },
    [PlayerType.PLAYER_SAMSON] = {
        CollectibleType.COLLECTIBLE_BLOODY_LUST,
    },
    [PlayerType.PLAYER_LAZARUS] = {
        CollectibleType.COLLECTIBLE_ANEMIC,
    },
    [PlayerType.PLAYER_LAZARUS2] = {
        CollectibleType.COLLECTIBLE_ANEMIC,
    },
    [PlayerType.PLAYER_THELOST] = {
        CollectibleType.COLLECTIBLE_ETERNAL_D6,
        CollectibleType.COLLECTIBLE_HOLY_MANTLE,
    },
    [PlayerType.PLAYER_LILITH] = {
        CollectibleType.COLLECTIBLE_INCUBUS,
        CollectibleType.COLLECTIBLE_CAMBION_CONCEPTION,
        CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS,
    },
    [PlayerType.PLAYER_KEEPER] = {
        CollectibleType.COLLECTIBLE_WOODEN_NICKEL,
    },
    [PlayerType.PLAYER_APOLLYON] = {
        CollectibleType.COLLECTIBLE_VOID,
    },
    [PlayerType.PLAYER_BETHANY] = {
        CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES,
    },
    [REVEL.CHAR.DANTE] = {
        CollectibleType.COLLECTIBLE_SCHOOLBAG,
        CollectibleType.COLLECTIBLE_MOMS_PURSE,
        CollectibleType.COLLECTIBLE_POLYDACTYLY,
    },
}
for k, v in pairs(PunishmentCharCollectibleBlacklist) do
    PunishmentCharCollectibleBlacklist[k] = REVEL.toSet(v)
end

local function FilterPunishmentItems(player, sid)
    local id = tonumber(sid)
    return not PunishmentCollectibleBlacklist[id]
        and player:HasCollectible(id,true) -- avoid some inventory bugs
        and player:GetActiveItem(ActiveSlot.SLOT_POCKET) ~= id
        and player:GetActiveItem(ActiveSlot.SLOT_POCKET2) ~= id
        and not (
            PunishmentCharCollectibleBlacklist[player:GetPlayerType()]
            and PunishmentCharCollectibleBlacklist[player:GetPlayerType()][id]
        )
end

REVEL.AddCommonShrine {
    Name = ShrineTypes.PUNISHMENT,
    DisplayName = "Punishment",
    Description = "Discard your\npossessions",
    Repeatable = true,
    AlwaysOneChapter = true,
    Value = 4,
    ValueOneChapter = 4,
    EID_Description = {
        Name = "Punishment",
        Description = "You lose a random item"
    },
    Sprite = "punishment",
    IsTall = true,
    HudIconFrame = 10,
    Requires = function()
        return REVEL.some(REVEL.players, function(player)
            local inventory = revel.data.run.inventory[REVEL.GetPlayerID(player)]
            local itemCount = revel.data.run.itemCount[REVEL.GetPlayerID(player)]
            for sid, num in pairs(inventory) do
                if not FilterPunishmentItems(player, sid) then
                    itemCount = itemCount - num
                end
            end

            return itemCount > 0
        end)
    end,
    ---@param npc EntityNPC
    PreTrigger = function(npc)
        local closestPlayerWithItems = REVEL.getClosestInTable(REVEL.filter(REVEL.players, function(player)
                local inventory = revel.data.run.inventory[REVEL.GetPlayerID(player)]
                local itemCount = revel.data.run.itemCount[REVEL.GetPlayerID(player)]
                for sid, num in pairs(inventory) do
                    if not FilterPunishmentItems(player, sid) then
                        itemCount = itemCount - num
                    end
                end

                return itemCount > 0
            end), npc)
        if not closestPlayerWithItems then
            return true
        else
            REVEL.GetData(npc).TriggerPlayer = closestPlayerWithItems:ToPlayer()
        end
    end,
    ---@param npc EntityNPC
    OnTrigger = function(npc)
        local player = REVEL.GetData(npc).TriggerPlayer
        local inventory = revel.data.run.inventory[REVEL.GetPlayerID(player)]

        local itemID = tonumber(REVEL.randomFrom(
                REVEL.filter(REVEL.keys(inventory), function(sid)
                    return FilterPunishmentItems(player, sid)
                end)
            ))

        player:RemoveCollectible(itemID)

        local playerPtr = EntityPtr(player)

        REVEL.SpawnDecorationFromTable(player.Position, player.Velocity, {
            Sprite = "gfx/effects/revelcommon/punishment_moms_hand.anm2",
            Anim = "JumpDown",
            RemoveOnAnimEnd = false,
            Start = function(e, data, sprite)
                local configItem = REVEL.config:GetCollectible(itemID)

                e.SpriteOffset = Vector(0, -24)
                sprite:ReplaceSpritesheet(1, configItem.GfxFileName)
                sprite:LoadGraphics()
            end,
            Update = function(e, data, sprite)
                local player2 = playerPtr.Ref

                if not player2 then 
                    e:Remove()
                    return
                end

                e.Position = player2.Position
                e.Velocity = player2.Velocity

                if sprite:IsFinished("JumpDown") then
                    sprite:Play("Grab", true)
                    REVEL.sfx:Play(SoundEffect.SOUND_MOM_VOX_EVILLAUGH)
                    REVEL.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN)
                    player:AnimateSad()
                    player.Velocity = Vector.Zero
                end
                if sprite:IsPlaying("Grab") then
                    -- out of screen by 40
                    if e.Position.Y + e.SpriteOffset.Y * REVEL.SCREEN_TO_WORLD_RATIO < 
                            REVEL.GetScreenTopLeftWorld().Y - 40 then
                        e:Remove()
                    end
                    player.Velocity = Vector.Zero
                end
            end,
        })
    
    end,
}

-- Masochism

local MasochismWhitelist = {
    PlayerType.PLAYER_KEEPER,
    PlayerType.PLAYER_KEEPER_B,
}

REVEL.AddCommonShrine {
    Name = ShrineTypes.MASOCHISM,
    DisplayName = "Masochism",
    Description = "It hurts",
    Value = 3,
    ValueOneChapter = 2,
    EID_Description = {
        Name = "Masochism",
        Description = "You take full hearts of damage"
    },
    Sprite = "masochism",
    HudIconFrame = 2,
    Requires = function()
        return REVEL.some(REVEL.players, function (player, _, _)
            for _, pType in ipairs(MasochismWhitelist) do
                if player:GetPlayerType() == pType then return false end
            end

            return player:GetEffectiveMaxHearts() + player:GetSoulHearts() > 2
        end)
    end,
}

local function IsMasochismActive()
    return REVEL.IsShrineEffectActive(ShrineTypes.MASOCHISM, true) -- enabled on bosses too
end

local OverridingTakeDamage = false

local SourceBlacklist = {
    [EntityType.ENTITY_DARK_ESAU] = true,
}

local function isInBlacklist(entityRef)
    return entityRef and entityRef.Entity and (
        SourceBlacklist[entityRef.Entity.Type] == true
        or (
            SourceBlacklist[entityRef.Entity.Type]
            and SourceBlacklist[entityRef.Entity.Type][entityRef.Entity.Variant]
        )
    )
end

---@param entity Entity
---@param damage number
---@param flags DamageFlag
---@param source EntityRef
---@param damageCountdown integer
local function masochism_EntityTakeDmg_Player(_, entity, damage, flags, source, damageCountdown)
    if not OverridingTakeDamage 
    and IsMasochismActive() 
    and not isInBlacklist(source)
    and damage < 2 then
        OverridingTakeDamage = true
        entity:TakeDamage(2, flags, source, damageCountdown)
        OverridingTakeDamage = false
        return false
    end
end

-- Scarcity

local SCARCITY_REMOVE_CHANCE = 0.33

local ScarcityWhitelist = {
    [PickupVariant.PICKUP_BOMB] = true,
    [PickupVariant.PICKUP_COIN] = true,
    [PickupVariant.PICKUP_GRAB_BAG] = true,
    [PickupVariant.PICKUP_HEART] = true,
    [PickupVariant.PICKUP_KEY] = true,
    [PickupVariant.PICKUP_TAROTCARD] = true,
    [PickupVariant.PICKUP_PILL] = true,
}

local ForceScarcityRemoval = false

REVEL.AddCommonShrine {
    Name = ShrineTypes.SCARCITY,
    DisplayName = "Scarcity",
    Description = "Vanishing goods",
    EID_Description = {
        Name = "Scarcity",
        Description = "Pickups have a " .. (math.floor(SCARCITY_REMOVE_CHANCE * 100)) .. "% chance to disappear"
    },
    Sprite = "scarcity",
    HudIconFrame = 6,
    OnTrigger = function ()
        ForceScarcityRemoval = true
        local pos = REVEL.room:GetCenterPos()
        for i = 1, 3 do
            local dir = RandomVector()
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.NO_CHEST_ITEM_TRINKET,
                pos + dir * 2, dir * 3, nil
            )
        end
        ForceScarcityRemoval = false
    end,
}

---@param pickup EntityPickup
local function scarcity_PostPickupInit(_, pickup)
    if ScarcityWhitelist[pickup.Variant] and pickup.Price == 0 then
        if REVEL.IsShrineEffectActive(ShrineTypes.SCARCITY) and pickup.SpawnerType ~= EntityType.ENTITY_PLAYER then
            local rng = REVEL.RNG()
            rng:SetSeed(pickup.InitSeed, 40)
            if ForceScarcityRemoval 
            or rng:RandomFloat() < SCARCITY_REMOVE_CHANCE 
            then
                pickup.Color = Color(1,1,1, 0.5)
                pickup.Timeout = 30
                pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                pickup.Wait = 60

                -- Make sure they stay ungrabbable
                local pickupPtr = EntityPtr(pickup)
                REVEL.DelayFunction(1, function()
                    local pickup2 = pickupPtr.Ref and pickupPtr.Ref:ToPickup()
                    if pickup2 then
                        pickup2.Timeout = 30
                        pickup2.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                        pickup2.Wait = 60
                    end
                end)
            end
        end
    end
end


-- Grounding (flight removal)

-- to removes the costumes of to prevent weird wing stuff
local PermaFlightCollectibles = {
    CollectibleType.COLLECTIBLE_HOLY_GRAIL,
    -- CollectibleType.COLLECTIBLE_DEAD_DOVE,
    CollectibleType.COLLECTIBLE_FATE,
    CollectibleType.COLLECTIBLE_SPIRIT_NIGHT,
    CollectibleType.COLLECTIBLE_LORD_OF_THE_PIT,
    -- CollectibleType.COLLECTIBLE_TRANSCENDENCE,
}

local TempFlightCollectibles = {
    CollectibleType.COLLECTIBLE_BIBLE,
    CollectibleType.COLLECTIBLE_PONY,
    CollectibleType.COLLECTIBLE_WHITE_PONY,
    CollectibleType.COLLECTIBLE_PINKING_SHEARS,
}

local GroundingBlacklist = {
    PlayerType.PLAYER_THEFORGOTTEN_B,
}

-- No way to detect nullcostumes in general, for now
-- track conditions
local FlyingNullCostumes = {
    Character = {
        [PlayerType.PLAYER_AZAZEL] = {
            Id = NullItemID.ID_AZAZEL,
            Replacement = NullItemID.ID_AZAZEL_B,
            -- Replacement = REVEL.COSTUME.AZAZEL_NOWINGS, -- right now it's charge anim doesn't work, blame API
        },
    },
    -- Would need to detect transformation
    Transformation = {
        -- NullItemID.ID_LORD_OF_THE_FLIES,
        -- NullItemID.ID_GUPPY,
        -- NullItemID.ID_ANGEL,
        -- NullItemID.ID_EVIL_ANGEL,
    }
}

local function PlayerRestoreFlight(player)
    player:AddCacheFlags(CacheFlag.CACHE_FLYING)
    player:EvaluateItems()

    local runData = revel.data.run.pactGrounding[REVEL.GetPlayerID(player)]
    if runData then
        if runData.FlightRemovedCostumes then
            for _, item in ipairs(runData.FlightRemovedCostumes) do
                player:AddCostume(REVEL.config:GetCollectible(item), false)
            end
            runData.FlightRemovedCostumes = nil
        end
        if runData.GroundingRemovedCharCostumes then
            for _, playerType in ipairs(runData.GroundingRemovedCharCostumes) do
                if FlyingNullCostumes.Character[playerType].Id then
                    player:AddNullCostume(FlyingNullCostumes.Character[playerType].Id)
                end
                if FlyingNullCostumes.Character[playerType].Replacement then
                    player:TryRemoveNullCostume(FlyingNullCostumes.Character[playerType].Replacement)
                end
            end
            runData.GroundingRemovedCharCostumes = nil
        end
    end
end

REVEL.AddCommonShrine {
    Name = "grounding",
    DisplayName = "Grounding",
    Description = "Flightless",
    Value = 3,
    ValueOneChapter = 2,
    EID_Description = {
        Name = "Grounding",
        Description = "Flying becomes disabled for this chapter"
    },
    Sprite = "grounding",
    HudIconFrame = 7,
    Requires = function()
        for _, player in ipairs(REVEL.players) do
            if REVEL.includes(GroundingBlacklist, player:GetPlayerType()) then
                return false
            elseif player.CanFly then
                return true
            end

            for _, item in ipairs(TempFlightCollectibles) do
                if player:HasCollectible(item) then
                    return true
                end
            end
        end

        -- No flying players, don't use
        return false
    end,
    PreTrigger = function(shrine)
        for _, player in ipairs(REVEL.players) do

            if player.CanFly then
                player.Position = REVEL.room:FindFreeTilePosition(shrine.Position+Vector(0,16), 30)
                player.Velocity = Vector.Zero
                return false
            end

            for _, item in ipairs(TempFlightCollectibles) do
                if player:HasCollectible(item) then
                    player.Position = REVEL.room:FindFreeTilePosition(shrine.Position+Vector(0,16), 30)
                    player.Velocity = Vector.Zero
                    return false
                end
            end
        end

        -- No flying players, block trigger
        return true
    end,
}

---@param player EntityPlayer
local function grounding_PostPlayerUpdate(_, player)
    local data = REVEL.GetData(player)
    if REVEL.IsShrineEffectActive(ShrineTypes.GROUNDING, true) then
        if player.CanFly then --reset flight
            player.CanFly = false
            player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
            
            revel.data.run.pactGrounding[REVEL.GetPlayerID(player)] = revel.data.run.pactGrounding[REVEL.GetPlayerID(player)] or {}
            local runData = revel.data.run.pactGrounding[REVEL.GetPlayerID(player)]

            if not runData.FlightRemovedCostumes then
                runData.FlightRemovedCostumes = {}
            end
            for _, item in ipairs(PermaFlightCollectibles) do
                if player:HasCollectible(item) then
                    player:RemoveCostume(REVEL.config:GetCollectible(item))
                    if not REVEL.includes(runData.FlightRemovedCostumes, item) then
                        table.insert(runData.FlightRemovedCostumes, item)
                    end
                end
            end
            for _, item in ipairs(TempFlightCollectibles) do
                if player:HasCollectible(item) then
                    player:RemoveCostume(REVEL.config:GetCollectible(item))
                end
            end

            if not runData.GroundingRemovedCharCostumes then
                runData.GroundingRemovedCharCostumes = {}
            end
            local playerType = player:GetPlayerType()
            if FlyingNullCostumes.Character[playerType] then
                if FlyingNullCostumes.Character[playerType].Id then
                    player:TryRemoveNullCostume(FlyingNullCostumes.Character[playerType].Id)
                end
                if not REVEL.includes(runData.GroundingRemovedCharCostumes, playerType) then
                    if FlyingNullCostumes.Character[playerType].Replacement then
                        player:AddNullCostume(FlyingNullCostumes.Character[playerType].Replacement)
                    end
                    table.insert(runData.GroundingRemovedCharCostumes, playerType)
                end
            end

            data.AppliedPactGrounding = true
            REVEL.DebugStringMinor("Pact of Grounding | removed flight")
        end
    elseif data.AppliedPactGrounding then
        PlayerRestoreFlight(player)
        data.AppliedPactGrounding = nil
        REVEL.DebugStringMinor("Pact of Grounding | restored flight")
    end
end

-- Purgatory
-- Spawns ghosts that go after Isaac and explode

local PURGATORY_SPAWN_CHANCE = 0.075
local PURGATORY_CHILD_MODIFIER = 0.5

local PURGATORY_SOUL_WAVE_FREQ_MUL = 0.33
local PURGATORY_SOUL_WAVE_SIZE = 1
local PURGATORY_SOUL_TRAIL_OFFSET = Vector(0, -19)

local PurgatoryEntityBlacklist = {
    [REVEL.ENT.PURGATORY_ENEMY.id] = {
        [REVEL.ENT.PURGATORY_ENEMY.variant] = true,
    },
    [REVEL.ENT.PEASHY_NAIL.id] = {
        [REVEL.ENT.PEASHY_NAIL.variant] = true,
    },
    [REVEL.ENT.CHILL_O_WISP.id] = {
        [REVEL.ENT.CHILL_O_WISP.variant] = true,
    }
}

-- Added for pacers then unused as I realized
-- they aren't spawned but morphed,
-- may still be useful
local PurgatoryChildEntityBlacklist = {
}

REVEL.AddCommonShrine {
    Name = ShrineTypes.PURGATORY,
    DisplayName = "Purgatory",
    Description = "Visitors from\nbelow",
    EID_Description = {
        Name = "Purgatory",
        Description = "Enemies have a " .. (math.floor(PURGATORY_SPAWN_CHANCE * 100)) .. "% chance of spawning"
            .. " ghosts that chase Isaac and explode"
            .. "#this chance is halved for enemies spawned by other enemies"
    },
    OnTrigger = function()
        local door
        for i = 0, 7 do
            if REVEL.room:GetDoor(i) then
                door = REVEL.room:GetDoor(i)
                break
            end
        end

        if door then
            local pos = REVEL.room:FindFreePickupSpawnPosition(door.Position, 0, true)

            local entity

            if REVEL.STAGE.Tomb:IsStage() then
                entity = Isaac.Spawn(REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant, 0, pos, Vector.Zero, nil)
            else
                entity = Isaac.Spawn(EntityType.ENTITY_GAPER, 0, 0, pos, Vector.Zero, nil)
            end

            REVEL.GetData(entity).ForcePurgatoryPactSpawn = true
        end
    end,
    CanDoorsOpen = function()
        for _, e in ipairs(REVEL.roomEnemies) do
            if REVEL.GetData(e).ForcePurgatoryPactSpawn then
                return false
            end
            if REVEL.ENT.PURGATORY_ENEMY:isEnt(e) then
                return false
            end
        end
        return true
    end,
    Sprite = "purgatory",
    HudIconFrame = 8,
}


local function purgatory_PostEntityKill(_, npc)
    if REVEL.IsShrineEffectActive(ShrineTypes.PURGATORY)
    and npc:ToNPC() -- exclude some familiars like wisps
    and not REVEL.IsTypeVariantInMap(npc, PurgatoryEntityBlacklist)
    and not (
        npc.SpawnerType and npc.SpawnerType >= 10 and npc.SpawnerType ~= 1000
        and REVEL.IsTypeVariantInMap(npc, PurgatoryChildEntityBlacklist)
    )
    then
        local rng = REVEL.RNG()
        rng:SetSeed(npc.InitSeed, 40)
        local chance = PURGATORY_SPAWN_CHANCE
        if npc.SpawnerType and npc.SpawnerType >= 10 and npc.SpawnerType ~= 1000 then
            chance = chance * PURGATORY_CHILD_MODIFIER
        end

        if REVEL.PURGATORY_DEBUG then
            chance = 1
        end

        if rng:RandomFloat() < chance 
        or REVEL.GetData(npc).ForcePurgatoryPactSpawn
        then
            -- wait a frame to check for morph
            -- for example: gaper -> gusher
            local npcPtr = EntityPtr(npc)
            local pos = npc.Position
            REVEL.DelayFunction(1, function()
                local npc2 = npcPtr.Ref
                -- If entity actually died
                if not npc2 or npc2:IsDead() then
                    local e = REVEL.ENT.PURGATORY_ENEMY:spawn(pos, Vector.Zero, npc)
                    e:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    e:GetSprite():Play("Appear", true)
                    REVEL.sfx:Play(SoundEffect.SOUND_DEVILROOM_DEAL, 1, 0, false, 1.1)
                end
            end)
        end
    end
end

---@param npc EntityNPC
local function purgatory_soul_NpcUpdate(_, npc)
    if not REVEL.ENT.PURGATORY_ENEMY:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    local closestPlayer = npc:GetPlayerTarget()
    local distSquared = closestPlayer.Position:DistanceSquared(npc.Position)

    local closestDir = (closestPlayer.Position - npc.Position):Normalized()

    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    local trail
    if data.Trail then
        trail = data.Trail and data.Trail.Ref:ToEffect()
    end

    if sprite:IsFinished("Appear") then
        sprite:Play("Charge")
        REVEL.sfx:Play(SoundEffect.SOUND_SWORD_SPIN, 0.5, 0, false, 0.5)
        trail = REVEL.SpawnTrailEffect(npc, Color(1, 0, 0), PURGATORY_SOUL_TRAIL_OFFSET, 2)
        data.Trail = EntityPtr(trail)

        npc.Velocity = closestDir * 12
    end

    if IsAnimOn(sprite, "Charge") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
        if distSquared < (npc.Size + closestPlayer.Size + 5) ^ 2 then
            closestPlayer:TakeDamage(1, 0, EntityRef(npc), 10)
            local explosionGhostSubtype = 1
            Isaac.Spawn(
                1000, EffectVariant.ENEMY_GHOST, explosionGhostSubtype, 
                npc.Position, 
                Vector.Zero, 
                npc
            )
            REVEL.sfx:Play(SoundEffect.SOUND_DEMON_HIT)
            npc:Die()
            trail:Remove()

            return
        end

        npc.SpriteOffset = Vector(0, math.sin(npc.FrameCount * PURGATORY_SOUL_WAVE_FREQ_MUL) * PURGATORY_SOUL_WAVE_SIZE)

        local _, perpendicularDir = REVEL.GetVectorComponents(closestDir, npc.Velocity, 1)

        npc.Velocity = npc.Velocity + perpendicularDir * 0.5
    else
        npc.Velocity = npc.Velocity * 0.1
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end

    if REVEL.IsOutOfRoomBy(npc.Position, 160) then
        npc:Remove()
        trail:Remove()
    end
end

local function purgatory_soul_PostNpcRender(_, npc)
    if not REVEL.ENT.PURGATORY_ENEMY:isEnt(npc) then return end

    local sprite = npc:GetSprite()

    if IsAnimOn(sprite, "Charge") then
        local offset = npc.SpriteOffset

        -- head back outline, behind everything
        sprite:SetFrame("Charge", 5)
        sprite:RenderLayer(1, Isaac.WorldToScreen(npc.Position))

        REVEL.RenderGhostTrail(npc, sprite, 
            "Charge", 
            0, 1, 
            4,
            true,
            function(segment, numSegments, effect)
                local vel = effect.Velocity
                local len = vel:Length()
                local useLen = math.min(len * 5, 20)

                local waveOffset = Vector(0, math.sin((npc.FrameCount - segment) * PURGATORY_SOUL_WAVE_FREQ_MUL) * PURGATORY_SOUL_WAVE_SIZE)

                return waveOffset - vel * (useLen / len * segment / numSegments * REVEL.WORLD_TO_SCREEN_RATIO)
            end
        )
        if npc.Velocity.Y < 0 then
            sprite:SetFrame("Charge", 5)
            sprite:RenderLayer(0, Isaac.WorldToScreen(npc.Position))
        else
            sprite:SetFrame("Charge", 4)
            sprite:RenderLayer(0, Isaac.WorldToScreen(npc.Position))
        end
    end
end

-- Bleeding

--#region Bleeding

local BLEED_TIME = 40 * 30 -- 40 seconds

local BleedBlacklist = {
    PlayerType.PLAYER_KEEPER,
    PlayerType.PLAYER_KEEPER_B,
    PlayerType.PLAYER_MAGDALENE_B,
}

REVEL.AddCommonShrine {
    Name = ShrineTypes.BLEEDING,
    DisplayName = "Hemorrhage",
    Description = "Bleed me dry",
    RemoveOnStageEnd = true,
    EID_Description = {
        Name = "Hemorrhage",
        Description = "Red health drains over time"
        .. "#Only lasts for the floor"
    },
    Sprite = "bleeding",
    HudIconFrame = 9,
    Requires = function()
        return REVEL.some(REVEL.players, function (player, _, _)
            for _, pType in ipairs(BleedBlacklist) do
                if player:GetPlayerType() == pType then return false end
            end

            return player:GetMaxHearts() > 2
        end)
    end,
}

local function bleeding_PostPlayerUpdate(_, player)
    local data = REVEL.GetData(player)
    if REVEL.IsShrineEffectActive(ShrineTypes.BLEEDING, true) then
        data.PactBleedingTimer = data.PactBleedingTimer or BLEED_TIME

        if data.AppliedPactBleeding == nil then
            data.PactBleedingTimer = BLEED_TIME*0.5
        end

        if player:GetHearts() > 1 
        and not REVEL.PlayerIsLost(player)
        then
            if data.PactBleedingTimer > 0 then
                data.PactBleedingTimer = data.PactBleedingTimer - 1
                if data.PactBleedingTimer < 200 then
                    local mult = (-data.PactBleedingTimer+200)*0.005
                    local color = Color.Lerp(Color(1+(3*mult),1-(0.6*mult),1-(0.6*mult),1),player:GetSprite().Color,0.5)
                    player:SetColor(color, 1, 1, false, false)
                end
            else
                --[[local dFlags = DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_NO_PENALTIES
                player:TakeDamage(1,dFlags,EntityRef(player),0)]]
                player:AddHearts(-1)

                REVEL.sfx:Play(REVEL.SFX.BLOOD_SAP)
                REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS,0.5)
                player:BloodExplode()
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, player.Position, Vector.Zero, player)
                for _=1,4 do
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_PARTICLE, 0, player.Position, Vector.Zero, player)
                end
                player:SetColor(Color(5,0,0,1,0.5,0,0), 20, 2, true, false)

                data.PactBleedingTimer = nil
            end
        end
        data.AppliedPactBleeding = true
    elseif data.AppliedPactBleeding then
        data.PactBleedingTimer = nil
        data.AppliedPactBleeding = nil
    end
end

-- Mitosis

--#region Mitosis

local MITOSIS_CHANCE = 0.3
local MITOSIS_BOOSTED_CHANCE = 0.6

local MitosisEntityBlacklist = {
    [EntityType.ENTITY_FIREPLACE] = true,
    [REVEL.ENT.CHILL_O_WISP.id] = {
        [REVEL.ENT.CHILL_O_WISP.variant] = true,
    },
    -- Static enemies, looks weird when mitosed
    [REVEL.ENT.GEICER.id] = {
        [REVEL.ENT.GEICER.variant] = true,
        [REVEL.ENT.COAL_HEATER.variant] = true,
    },
    [REVEL.ENT.AVALANCHE.id] = {
        [REVEL.ENT.AVALANCHE.variant] = true,
    },
    [REVEL.ENT.PINE.id] = {
        [REVEL.ENT.PINE.variant] = true,
        [REVEL.ENT.PINECONE.variant] = true,
    },
    [REVEL.ENT.RAGMA.id] = {
        [REVEL.ENT.RAGMA.variant] = true,
    },
    [REVEL.ENT.STALACTITE.id] = {
        [REVEL.ENT.STALACTITE.variant] = true,
    },
    [REVEL.ENT.GLASS_SPIKE.id] = {
        [REVEL.ENT.GLASS_SPIKE.variant] = true,
    },
    [REVEL.ENT.ANTLION.id] = {
        [REVEL.ENT.ANTLION.variant] = true,
    },
    [REVEL.ENT.TILE_MONGER.id] = {
        [REVEL.ENT.TILE_MONGER.variant] = true,
    }
}

REVEL.AddCommonShrine {
    Name = ShrineTypes.MITOSIS,
    DisplayName = "Mitosis",
    Description = "Strength in\nnumbers",
    EID_Description = {
        Name = "Mitosis",
        Description = "Enemies have a chance to become doubled"
        .. "#Taking this multiple times will increase the chance"
    },
    Repeatable = true,
    MaxRepeats = 2,
    Sprite = "mitosis",
    IsTall = true,
    HudIconFrame = 12,
}

local function mitosis_PostNpcInit(npc)
    if REVEL.IsShrineEffectActive(ShrineTypes.MITOSIS, true)
    and not (npc.SpawnerType and npc.SpawnerType >= 10 and npc.SpawnerType ~= 1000) 
    and npc.MaxHitPoints > 0
    and npc:IsVulnerableEnemy() and not npc:IsBoss() and npc:ToNPC()
    and not REVEL.IsTypeVariantInMap(npc, MitosisEntityBlacklist)
    and not npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
    and not npc:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) then
        local dpsMax = 7
        for _, player in ipairs(REVEL.players) do
            local dps = REVEL.EstimateDPS(player)
            if not dpsMax or dps > dpsMax then
                dpsMax = dps
            end
        end

        local chance = MITOSIS_CHANCE
        local _, shrineAmount = REVEL.IsShrineEffectActive(ShrineTypes.MITOSIS, true)
        if shrineAmount > 1 then chance = MITOSIS_BOOSTED_CHANCE end

        if dpsMax and dpsMax > npc.MaxHitPoints * 0.4 then
            if npc:GetDropRNG():RandomFloat() < chance then
                local double = Isaac.Spawn(npc.Type, npc.Variant, npc.SubType, npc.Position+Vector(10,0):Rotated(math.random(360)), Vector.Zero, npc)

                if double then
                    double:SetColor(Color(1,1,1,1,1,1,1),30, 1, true, false)
                end
            end
        end
    end
end

--#endregion

-- Callbacks

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, scarcity_PostPickupInit)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, grounding_PostPlayerUpdate)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, bleeding_PostPlayerUpdate)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, purgatory_PostEntityKill)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, purgatory_soul_NpcUpdate, REVEL.ENT.PURGATORY_ENEMY.id)
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, purgatory_soul_PostNpcRender, REVEL.ENT.PURGATORY_ENEMY.id)
StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 90, mitosis_PostNpcInit)
-- StageAPI.AddCallback("Revelations", "POST_STAGEAPI_NEW_ROOM_WRAPPER", 1, grounding_PostNewRoom)

-- call early to avoid running other callbacks more than necessary
revel:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.EARLY, masochism_EntityTakeDmg_Player, EntityType.ENTITY_PLAYER)



end