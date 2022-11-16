local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-------------------
-- Friendly Fire --
-------------------

-- Fire immunity, shooty fires target enemies
REVEL.FriendlyFire = {
    fireDelay = 40,
    friendlyColor = {
        [1] = Color(1.2, 1, 1.6, 1, conv255ToFloat(25, 25, 25)),
        [3] = Color(1.8, 1, 1.8, 1, conv255ToFloat(25, 25, 25)),
    },
    bossRoomsBlacklisted = {
        "Prong",
    }
}

-- Cannot use main callback aas return would return only this func, not the whole callback
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, _, _, flag, src)
    --  if src.Entity then REVEL.DebugToString({flag, src.Entity.Type, REVEL.ITEM.FFIRE:PlayerHasCollectible(REVEL.player)}) end
    if (flag == DamageFlag.DAMAGE_FIRE or (src.Entity and
        (
            src.Entity.Type == 33 or
            (src.Entity.Type == 9 and src.Entity.Variant == ProjectileVariant.PROJECTILE_FIRE)
        )
    )) 
    and REVEL.ITEM.FFIRE:PlayerHasCollectible(REVEL.player) 
    then
        return false
    end
end, 1)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    local currentRoom = StageAPI.GetCurrentRoom()
    if REVEL.room:GetType() == RoomType.ROOM_BOSS 
    and currentRoom and currentRoom.PersistentData.BossID then
        for _, bossName in ipairs(REVEL.FriendlyFire.bossRoomsBlacklisted) do
            if StageAPI.GetBossData(currentRoom.PersistentData.BossID).Name == bossName then 
                return 
            end
        end
    end

    if REVEL.room:IsFirstVisit()
    and REVEL.OnePlayerHasCollectible(REVEL.ITEM.FFIRE.id)
    and not StageAPI.InExtraRoom() and not REVEL.room:IsClear() then
        local isEmpty = true
        local freeIndices = {}

        local gridDiagonalHalfLength = math.ceil(40 * math.sqrt(2) / 2)

        for index = 0, REVEL.room:GetGridSize() do
            local grid, pos = REVEL.room:GetGridEntity(index),
                REVEL.room:GetGridPosition(index)
            if REVEL.room:IsPositionInRoom(pos, 0) then
                if grid then
                    isEmpty = false
                else
                    local isValid = index ~= 37
                    local entityPartition = EntityPartition.ENEMY | EntityPartition.PICKUP
                    local nearEntities = Isaac.FindInRadius(pos, gridDiagonalHalfLength, entityPartition)
                    for _, entity in ipairs(nearEntities) do
                        local index2 = REVEL.room:GetGridIndex(entity.Position)
                        if index2 == index then
                            isValid = false
                            break
                        end
                    end

                    if isValid then
                        freeIndices[#freeIndices + 1] = pos
                    end
                end
            end
        end

        -- if rooms has grid entities (to prevent spawning fires in empty rooms)
        if not isEmpty and #freeIndices > 0 then
            REVEL.Shuffle(freeIndices)
            local collectibleNum = REVEL.GetCollectibleSum(REVEL.ITEM.FFIRE.id)
            local numFires = math.min(
                math.random(collectibleNum, collectibleNum * 2), 
                #freeIndices
            )
            for i = 1, numFires do
                local pos = freeIndices[i]
                local fire = Isaac.Spawn(
                    33, 1, 0, 
                    pos, Vector.Zero,
                    REVEL.GetRandomPlayerWithItem(REVEL.ITEM.FFIRE.id)
                )
            end

            local roomFires = Isaac.FindByType(EntityType.ENTITY_FIREPLACE)

            for i, fire in ipairs(roomFires) do
                if math.random() > 0.75 
                and (fire.Variant == 0 or fire.Variant == 2) 
                then
                    fire:ToNPC():Morph(fire.Type, fire.Variant + 1, fire.SubType, -1)
                end
            end
        end
    end
end)

-- Replace projectiles with tears with the same gfx that target closest enemy
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function(_, e)
    if e.SpawnerType == 33 
    and REVEL.OnePlayerHasCollectible(REVEL.ITEM.FFIRE.id) then
        e:Remove()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.OnePlayerHasCollectible(REVEL.ITEM.FFIRE.id) then
        local roomFires = Isaac.FindByType(EntityType.ENTITY_FIREPLACE)
        for i, fire in ipairs(roomFires) do
            local spr, data = fire:GetSprite(), fire:GetData()
            if REVEL.MultiPlayingCheck(spr, "Dissapear", "Dissapear2", "Dissapear3") 
            and spr:GetFrame() == 1
            then
                data.lerpForwards = false

                local rng = REVEL.RNG()
                rng:SetSeed(fire.InitSeed, 50)

                if rng:RandomInt(6) == 0 then
                    local hasReward = false
                    local pos = fire.Position
                    local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP)
                    for _, pickup in ipairs(pickups) do
                        if pickup.FrameCount == 0
                        and pickup.Position:DistanceSquared(pos) < 100
                        then
                            hasReward = true
                            break
                        end
                    end

                    if not hasReward then
                        Isaac.Spawn(
                            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_FULL, 
                            fire.Position, Vector.Zero, 
                            fire
                        )    
                    end
                end
           end


            if fire.Variant == 1 or fire.Variant == 3 then
                if not data.ffInit 
                and not REVEL.MultiAnimOnCheck(spr, "NoFire", "NoFire2", "NoFire3")
                then
                    data.ffInit = true
                    data.lerpTime = 0
                    data.firedelay = REVEL.FriendlyFire.fireDelay
                    data.lerpForwards = true
                end

                data.lerpTime = data.lerpTime or 0

                spr.Color = Color.Lerp(
                    Color.Default, 
                    REVEL.FriendlyFire.friendlyColor[fire.Variant],
                    data.lerpTime
                )

                if data.lerpForwards then
                    data.lerpTime = math.min(1, data.lerpTime + 0.07)
                else
                    data.lerpTime = math.max(0, data.lerpTime - 0.07)
                end

                if data.firedelay and data.firedelay > 0 then
                    data.firedelay = data.firedelay - 1
                elseif data.firedelay and data.firedelay <= 0 
                and REVEL.MultiPlayingCheck(spr, "Flickering", "Flickering2", "Flickering3") 
                then
                    local targ = REVEL.getClosestEnemy(fire, true, false, true, true)

                    if targ then
                        data.firedelay = REVEL.FriendlyFire.fireDelay
                        local dir = (targ.Velocity + targ.Position - fire.Position):Normalized()
                        local tear = Isaac.Spawn(
                            2, TearVariant.BLOOD, 0,
                            fire.Position + dir * (fire.Size + 3), dir * 11, 
                            fire
                        ):ToTear()

                        -- e:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER | ProjectileFlags.ANY_HEIGHT_ENTITY_HIT | ProjectileFlags.HIT_ENEMIES)
                        tear.Target = targ
                        tear:GetData().ffire = true

                        if fire.Variant == 3 then
                            tear.Scale = tear.Scale * 1.2
                            tear.TearFlags = BitOr(tear.TearFlags, TearFlags.TEAR_HOMING)
                            tear:GetSprite().Color = REVEL.HOMING_COLOR
                        end
                    end
                end
            end
        end
    end
end)

end
