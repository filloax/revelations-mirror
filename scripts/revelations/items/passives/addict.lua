local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
------------
-- ADDICT --
------------

local killAllPills = false
local removeAllPills = false
local maxCount = 5 -- +1 for every extra item instance
local usedPill = 2 -- 0: not used 1: used 2: not used, in cleared room
local pillTimeout = true
local goodChanceBase = 0.1
local goodVsNeutralWeigth = 2
local goodChanceCap = 0.5
local roomsWithoutSkitterCards = 0

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    killAllPills = false
    removeAllPills = false
    pillTimeout = true

    if not REVEL.OnePlayerHasCollectible(REVEL.ITEM.ADDICT.id) then
        return
    end

    local hasStarterDeck = REVEL.OnePlayerHasCollectible(
                                CollectibleType.COLLECTIBLE_STARTER_DECK)
    local sum = REVEL.GetCollectibleSum(REVEL.ITEM.ADDICT.id)

    if usedPill == 0 then
        revel.data.run.addictCount =
            math.min(maxCount - 1 + sum, revel.data.run.addictCount + sum)
    elseif usedPill == 1 then
        revel.data.run.addictCount = 0
    end

    local okEnemiesLeft = false
    if REVEL.room:IsFirstVisit() then
        for i, e in ipairs(REVEL.roomEnemies) do
            if e:IsVulnerableEnemy() and not e:IsInvincible() and
                not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and
                REVEL.CanShutDoors(e) then
                okEnemiesLeft = true
                break
            end
        end

        if okEnemiesLeft and hasStarterDeck and roomsWithoutSkitterCards < 3 and
            math.random(1, 100) > 40 then
            okEnemiesLeft = false
            roomsWithoutSkitterCards = roomsWithoutSkitterCards + 1
        end
    end

    if okEnemiesLeft then
        roomsWithoutSkitterCards = 0
        usedPill = 0

        if revel.data.run.addictCount > 0 then
            for i = 1, sum + revel.data.run.addictCount - 1 do
                -- get random position in other half of the room
                local tl, br, c, ppos = REVEL.room:GetTopLeftPos(),
                                        REVEL.room:GetBottomRightPos(),
                                        REVEL.room:GetCenterPos(),
                                        REVEL.player.Position
                local x, y
                if ppos.X - tl.X > br.X - ppos.X then -- on right half
                    x = math.random(tl.X, c.X)
                else
                    x = math.random(c.X, br.X)
                end
                if ppos.Y - tl.Y > br.Y - ppos.Y then -- on bottom half
                    y = math.random(tl.Y, c.Y)
                else
                    y = math.random(c.Y, br.Y)
                end
                local pos = Isaac.GetFreeNearPosition(Vector(x, y), 40)

                if hasStarterDeck then
                    REVEL.ENT.SKITTER_C:spawn(pos, Vector.Zero, nil)
                elseif math.random() <
                    REVEL.Lerp2(goodChanceBase, goodChanceCap,
                                revel.data.run.addictCount, 0,
                                maxCount - 1 + sum) then
                    REVEL.ENT.SKITTER_G:spawn(pos, Vector.Zero, nil)
                else
                    REVEL.ENT.SKITTER_B:spawn(pos, Vector.Zero, nil)
                end
            end
        end
    else
        usedPill = 2
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local hasNotableEnemies = false
    for i, npc in pairs(REVEL.roomNPCs) do
        if REVEL.CanShutDoors(npc) and
        not (npc.Type == REVEL.ENT.SKITTER_G.id and
        (REVEL.ENT.SKITTER_G.variant == npc.Variant or
        REVEL.ENT.SKITTER_B.variant == npc.Variant or
        REVEL.ENT.SKITTER_C.variant == npc.Variant)) then
            hasNotableEnemies = true
            break
        end
    end
    if not hasNotableEnemies then removeAllPills = true end
end)

revel:AddCallback(ModCallbacks.MC_USE_PILL, function()
    if not REVEL.OnePlayerHasCollectible(
        CollectibleType.COLLECTIBLE_STARTER_DECK) then usedPill = 1 end
    pillTimeout = false
    killAllPills = true
end)

revel:AddCallback(ModCallbacks.MC_USE_CARD, function()
    if REVEL.OnePlayerHasCollectible(
        CollectibleType.COLLECTIBLE_STARTER_DECK) then usedPill = 1 end
end)

-- Skitterpill Good
local function goodUpdate(npc, spr, data, player)
    data.cooldown = data.cooldown - 1
    if data.cooldown == -4 then
        data.cooldown = 8
        spr:Play("Fly", true)
    end

    if data.cooldown > 0 then
        npc.Pathfinder:EvadeTarget(player.Position)
        data.Dir = REVEL.CloneVec(npc.Velocity):Resized(6.5)
        npc.Velocity = data.Dir
        -- if colliding
        local gridCol = REVEL.room:GetGridCollisionAtPos(npc.Velocity +
                                                                npc.Position)
        if gridCol == GridCollisionClass.COLLISION_WALL or gridCol ==
            GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER then
            npc.Velocity = npc.Velocity * 0.5
            data.cooldown = 1
        end
    elseif data.cooldown <= 0 then
        npc.Velocity = npc.Velocity * 0.95
    end
end

-- Skitterpill Bad
local function badUpdate(npc, spr, data, player)
    data.cooldown = data.cooldown - 1
    if data.cooldown == -4 then
        data.cooldown = 20
        npc.Pathfinder:FindGridPath(player.Position, 1, 0, true)
        data.Dir = REVEL.CloneVec(npc.Velocity):Resized(7.1)
        spr:Play("Walk", true)
    end

    if data.cooldown > 0 then
        npc.Velocity = data.Dir
        local dist1 = player.Position:DistanceSquared(npc.Position)
        local dist2 = player.Position:DistanceSquared(npc.Position +
                                                            npc.Velocity)
        -- if colliding or going away from player
        if REVEL.room:GetGridCollisionAtPos(npc.Velocity + npc.Position) ~=
            GridCollisionClass.COLLISION_NONE or dist1 + 50 < dist2 then
            data.cooldown = 1
        end
    elseif data.cooldown <= 0 then
        npc.Velocity = npc.Velocity * 0.55
        spr:Play("Idle", true)
    end
end

-- Skitterpill Card
local function cardUpdate(npc, spr, data, player)
    data.cooldown = data.cooldown - 1
    if data.cooldown == -4 then
        data.cooldown = 8
        spr:Play("Fly", true)
    end

    if data.cooldown > 0 then
        npc.Velocity = npc.Velocity + (player.Position - npc.Position)
        data.Dir = REVEL.CloneVec(npc.Velocity):Resized(6.1)
        npc.Velocity = data.Dir
        local dist1 = player.Position:DistanceSquared(npc.Position)
        local dist2 = player.Position:DistanceSquared(npc.Position +
                                                            npc.Velocity)
        local gridCol = REVEL.room:GetGridCollisionAtPos(npc.Velocity +
                                                                npc.Position)
        -- if colliding or going away from player
        if gridCol == GridCollisionClass.COLLISION_WALL or gridCol ==
            GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER or dist1 + 50 <
            dist2 then
            npc.Velocity = npc.Velocity * 0.5
            data.cooldown = 1
        end
    elseif data.cooldown <= 0 then
        npc.Velocity = npc.Velocity * 0.95
    end
end

-- Skitterpill All
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if REVEL.ENT.SKITTER_G.variant ~= npc.Variant and
        REVEL.ENT.SKITTER_B.variant ~= npc.Variant and
        REVEL.ENT.SKITTER_C.variant ~= npc.Variant then return end
    local spr, data, player = npc:GetSprite(), REVEL.GetData(npc),
                                npc:GetPlayerTarget()

    if not data.Init then
        data.cooldown = 0
        data.Init = true
    end

    if removeAllPills then
        Isaac.Spawn(1000, EffectVariant.POOF01, 0, npc.Position,Vector.Zero, npc)
        npc:Remove()
        return
    end

    if killAllPills then
        npc:Kill()
        return
    end

    if npc.Variant == REVEL.ENT.SKITTER_B.variant then
        badUpdate(npc, spr, data, player)
    elseif npc.Variant == REVEL.ENT.SKITTER_G.variant then
        goodUpdate(npc, spr, data, player)
    elseif npc.Variant == REVEL.ENT.SKITTER_C.variant then
        cardUpdate(npc, spr, data, player)
    end
end, REVEL.ENT.SKITTER_G.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL,
                    function(_, ent, dmg, flag, source)
    local var, sub
    if ent.Variant == REVEL.ENT.SKITTER_G.variant then
        var, sub = PickupVariant.PICKUP_PILL,
                    REVEL.GetRandomNonBadPill(goodVsNeutralWeigth)
    elseif ent.Variant == REVEL.ENT.SKITTER_B.variant then
        var, sub = PickupVariant.PICKUP_PILL, REVEL.GetRandomBadPill()
    elseif ent.Variant == REVEL.ENT.SKITTER_C.variant then
        var, sub = PickupVariant.PICKUP_TAROTCARD,
                    REVEL.GetRandomTarotCard(true)
        killAllPills = true -- only allow one card reward
    else
        return
    end

    Isaac.Spawn(5, var, sub, ent.Position, Vector.Zero, ent)
end, REVEL.ENT.SKITTER_G.id)


revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if pillTimeout and pickup.Variant == PickupVariant.PICKUP_PILL and
    pickup.SpawnerType == REVEL.ENT.SKITTER_G.id and
    (pickup.SpawnerVariant == REVEL.ENT.SKITTER_G.variant or
    pickup.SpawnerVariant == REVEL.ENT.SKITTER_B.variant or
    pickup.SpawnerVariant == REVEL.ENT.SKITTER_C.variant) then
        pickup.Timeout = 60
        pickup.Wait = 20
    end
end)

end
