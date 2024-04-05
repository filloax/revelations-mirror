local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-------------------
-- LOVERS LIBIDO --
-------------------

--[[
Whenever a non-payment Pedestal spawns, it grows legs and attempts to scuttle away from the player.
They can be fired upon, but not killed. Landing a tear causes them to slow down slightly, making
them easier to catch. When the player reaches the pedestal, they receive the item, alongside a
"Smooch" SFX, followed by a comical "Pop" SFX, with a random trinket popping out the backside of Isaac.
]]

local LoversLibAlwaysAffected = true -- If the lover's libido pedestal gets affected by the effect regardless of having the item
local RunAwayFromOtherPedestals = true

local pathMap = REVEL.NewPathMapFromTable("Lust Flee Enemies", {
    GetTargetSets = function()
        local targetSets = {}
        local playerTargets = {}
        for _, player in ipairs(REVEL.players) do
            playerTargets[#playerTargets + 1] = REVEL.room:GetGridIndex(player.Position)
        end

        local loversItems = Isaac.FindByType(
            REVEL.ENT.LOVERS_LIB_PD.id,
            REVEL.ENT.LOVERS_LIB_PD.variant,
            -1, 
            true
        )

        if #loversItems > 1 and RunAwayFromOtherPedestals then
            for i, ent in ipairs(loversItems) do
                local data = REVEL.GetData(ent)
                data.TargetSetIndex = i
                -- Add other lover's libido pedestals to the targets to run away from
                targetSets[i] = {
                    Targets = REVEL.ConcatTables(
                        playerTargets, 
                        REVEL.map(
                            REVEL.filter(loversItems, function(otherPedestal)
                                return GetPtrHash(otherPedestal) ~= GetPtrHash(ent)
                            end), 
                            function(otherPedestal)
                                return REVEL.room:GetGridIndex(otherPedestal.Position)
                            end
                        )
                    ),
                    Force = true
                }
            end
        elseif #loversItems >= 1 then
            local data = REVEL.GetData(loversItems[1])
            data.TargetSetIndex = 1
            targetSets[1] = {Targets = playerTargets}
        end

        return targetSets
    end,

    GetInverseCollisions = function()
        local inverseCollisions = {}
        for i = 0, REVEL.room:GetGridSize() do
            if REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(i), 0) then
                inverseCollisions[i] = REVEL.room:GetGridCollision(i) == 0
            end
        end

        return inverseCollisions
    end,

    OnPathUpdate = function(map)
        local loversItems = Isaac.FindByType(
            REVEL.ENT.LOVERS_LIB_PD.id,
            REVEL.ENT.LOVERS_LIB_PD.variant,
            -1, 
            true
        )

        for _, ent in ipairs(loversItems) do
            local data = REVEL.GetData(ent)
            data.TargId = map.TargetMapSets[data.TargetSetIndex]
                                .FarthestIndex
            data.Path, data.PathLength =
                REVEL.GeneratePathAStar(
                    REVEL.room:GetGridIndex(ent.Position),
                    map.TargetMapSets[data.TargetSetIndex].FarthestIndex)
        end
    end
})

local hidelist = {} -- grid ids, since rerolling resets everything but position
local ignorelist = {}

local function InitPickup(e)
    local spr, data = e:GetSprite(), REVEL.GetData(e)

    if e.Variant ~= PickupVariant.PICKUP_COLLECTIBLE
    or not REVEL.room:IsFirstVisit() 
    or e.SubType == CollectibleType.COLLECTIBLE_POLAROID 
    or e.SubType == CollectibleType.COLLECTIBLE_NEGATIVE
    or e.SubType == CollectibleType.COLLECTIBLE_DADS_NOTE then
        return
    end

    if not data.LoversLibidoIgnore 
    and REVEL.includes(ignorelist, REVEL.room:GetGridIndex(e.Position)) then
        data.LoversLibidoIgnore = true
    elseif not data.LoversLibidoIgnore 
    and REVEL.includes(hidelist, REVEL.room:GetGridIndex(e.Position)) then
        e.Visible = false -- make it respawn in case room is reentered
        e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    elseif not e.Touched then
        local isItemWithLoversLib = REVEL.OnePlayerHasCollectible(REVEL.ITEM.LOVERS_LIB.id)
            and (
                REVEL.room:GetType() == RoomType.ROOM_TREASURE
                or REVEL.room:GetType() == RoomType.ROOM_BOSS
            )
        local isLoversLibPedestal = e.SubType == REVEL.ITEM.LOVERS_LIB.id 
            and REVEL.room:GetType() == RoomType.ROOM_MINIBOSS 
            and LoversLibAlwaysAffected
        
        if (isItemWithLoversLib or isLoversLibPedestal)
        and not data.LoversLibidoIgnore 
        and spr:GetOverlayFrame() == 0 
        and not (data.CharonBossChoice and not data.CharonOtherChoiceSpawned)
        then -- basic pedestal
            local npc = REVEL.ENT.LOVERS_LIB_PD:spawn(e.Position, e.Velocity, e)
            local nspr, ndata = npc:GetSprite(), REVEL.GetData(npc)
            local item = REVEL.config:GetCollectible(e.SubType)
            local gfx = item.GfxFileName

            local hasBlind = REVEL.IsThereCurse(LevelCurse.CURSE_OF_BLIND)
            if hasBlind then
                gfx = "gfx/items/collectibles/questionmark.png"
            end

            nspr:ReplaceSpritesheet(1, gfx)
            nspr:LoadGraphics()
            nspr:Play("Idle", true)
            nspr:PlayOverlay("Walk", true)
            ndata.Item = item
            ndata.OrigPickup = e
            ndata.TheresOptions = e.OptionsPickupIndex == 1
            if EID and not hasBlind then
                npc:GetData().EID_Description = REVEL.GetEidItemDesc(e.SubType)
                if not npc:GetData().EID_Description.Name then
                    npc:GetData().EID_Description.Name = item.Name
                end
            end
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

            table.insert(hidelist, REVEL.room:GetGridIndex(e.Position))

            if not REVEL.OnePlayerHasCollectible(REVEL.ITEM.LOVERS_LIB.id) then -- spawned in lust miniboss
                ndata.NotDropTrinket = true
            end

            e.Visible = false -- make it respawn in case room is reentered
            e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end
    end
end

local function loversLibido_PickupUpdateInit(e)
    -- do not run for stageAPI managed rooms, as they will replace it, 
    -- use stageapi's post pickup spawn instead
    if not StageAPI.GetCurrentRoom() then
        InitPickup(e)
    end
end

local function loversLibido_PostSpawnEntity(e)
    if e.Type == EntityType.ENTITY_PICKUP then
        InitPickup(e)
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, loversLibido_PickupUpdateInit)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_ENTITY, 10, loversLibido_PostSpawnEntity)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function()
    local items = Isaac.FindByType(5, 100, -1, false, false)
    for i, e in ipairs(items) do
        if REVEL.includes(hidelist, REVEL.room:GetGridIndex(e.Position)) then
            e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            e.Visible = false
        end
    end
end, CollectibleType.COLLECTIBLE_D6)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    -- if not first visit, all remaining items must have been left over by lover's libido intentionally, or assume so to prevent cheesing trinkets
    ignorelist = {}
    hidelist = {}
    if not REVEL.room:IsFirstVisit() then
        local items = Isaac.FindByType(5, 100, -1, false, false)
        for i, e in ipairs(items) do
            REVEL.GetData(e).LoversLibidoIgnore = true
            table.insert(ignorelist, REVEL.room:GetGridIndex(e.Position))
        end
    end
end)

local Speed = 1.7

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, e)
    if e.Variant ~= REVEL.ENT.LOVERS_LIB_PD.variant then return end
    local spr, data = e:GetSprite(), REVEL.GetData(e)
    local walk = true

    if not data.Init then
        e.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        data.dmgCount = 0
        data.spazOutTimer = 0
        data.Init = true
    end

    if data.Item.ID ~= data.OrigPickup.SubType then -- rerolled
        data.Item = REVEL.config:GetCollectible(data.OrigPickup.SubType)

        local gfx = data.Item.GfxFileName
        local hasBlind = REVEL.IsThereCurse(LevelCurse.CURSE_OF_BLIND)
        if hasBlind then
            gfx = "gfx/items/collectibles/questionmark.png"
        end

        if EID and not hasBlind then
            e:GetData().EID_Description = REVEL.GetEidItemDesc(data.Item.ID)
            if not e:GetData().EID_Description.Name then
                local itemConfig = REVEL.config:GetCollectible(data.Item.ID)
                e:GetData().EID_Description.Name = itemConfig.Name
            end
        end
        
        spr:ReplaceSpritesheet(1, gfx)
        spr:LoadGraphics()
    end

    if not data.pop then

        if not data.OrigPickup:Exists() then
            e:Remove()
            return
        end

        for i, p in ipairs(REVEL.players) do
            if p.Position:DistanceSquared(e.Position) < (e.Size + p.Size + 2) ^ 2 then
                spr:Play("Empty", true)
                if p:GetActiveItem() and data.Item.Type ==
                    ItemType.ITEM_ACTIVE then
                    local dropActive = Isaac.Spawn(5, 100,
                                                    p:GetActiveItem(),
                                                    p.Position, Vector.Zero,
                                                    p)
                    REVEL.GetData(dropActive).LoversLibidoIgnore = true
                    table.insert(ignorelist, REVEL.room:GetGridIndex(
                                        dropActive.Position))
                end

                p:StopExtraAnimation()
                REVEL.game:GetHUD():ShowItemText(p, data.Item)
                p:AnimateCollectible(data.Item.ID, "Pickup", "PlayerPickup")
                p:QueueItem(data.Item, data.Item.MaxCharges, false)
                REVEL.sfx:Play(SoundEffect.SOUND_CHOIR_UNLOCK, 0.8, 0,
                                false, 1)
                REVEL.sfx:Play(REVEL.SFX.LOVERS_LIB, 0.8, 0, false, 1)

                data.OrigPickup:Remove()

                if data.TheresOptions then
                    local loversItems =
                        Isaac.FindByType(REVEL.ENT.LOVERS_LIB_PD.id,
                                            REVEL.ENT.LOVERS_LIB_PD.variant,
                                            -1, true)

                    for _, ent in ipairs(loversItems) do
                        local edata = REVEL.GetData(ent)
                        if edata.TheresOptions and ent.Index ~= e.Index then
                            Isaac.Spawn(1000, EffectVariant.POOF01, 0,
                                        ent.Position, Vector.Zero, ent)
                            REVEL.GetData(ent).OrigPickup:Remove()
                            ent:Remove()
                        end
                    end
                end

                data.pop = true
                data.popPlayer = p
                e.Velocity = Vector.Zero
                spr:RemoveOverlay()
                spr:Play("Pop", true)
                spr.PlaybackSpeed = 1

                break
            end
        end
    else
        e.Velocity = Vector.Zero
        if spr:IsFinished("Pop") then
            if not data.NotDropTrinket then
                Isaac.Spawn(
                    5, 
                    PickupVariant.PICKUP_TRINKET, 
                    0, 
                    e.Position,
                    (e.Position - data.popPlayer.Position):Resized(6), 
                    e
                )
            end
            Isaac.Spawn(1000, EffectVariant.POOF01, 0, e.Position,
                        Vector.Zero, e)
            e:Remove()
        end
        walk = false
    end

    if walk then
        if not REVEL.IsUsingPathMap(pathMap, e) then
            REVEL.UsePathMap(pathMap, e)
        end

        local speedMult = REVEL.Lerp2Clamp(1, 0.3, data.dmgCount, 0, 12)
        if data.spazOutTimer > 0 then
            spr.PlaybackSpeed = 3
            data.spazOutTimer = data.spazOutTimer - 1
        else
            spr.PlaybackSpeed = (speedMult + 0.15) * 0.5 + 0.6
        end

        if data.Path and data.Path[1] and data.TargId then
            local pos = REVEL.room:GetGridPosition(data.TargId)
            if not REVEL.room:CheckLine(e.Position, pos, 0, 1, false, false) then
                pos = REVEL.room:GetGridPosition(data.Path[1])
            end
            e.Velocity = e.Velocity * 0.9 +
                                (pos - e.Position):Resized(Speed * speedMult)
        else
            REVEL.MoveRandomly(e, 5, 15, 20, Speed * speedMult, 0.9,
                                REVEL.room:GetCenterPos())
        end
    end
end, REVEL.ENT.LOVERS_LIB_PD.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg)
    if e.Variant ~= REVEL.ENT.LOVERS_LIB_PD.variant then return end
    local spr, data = e:GetSprite(), REVEL.GetData(e)

    data.dmgCount = data.dmgCount + dmg
    data.spazOutTimer = 6
    e:SetColor(Color(1,1,1,1,-0.2,-0.2,0.1), 20, 1, true, false)
    return false
end, REVEL.ENT.LOVERS_LIB_PD.id)

end
