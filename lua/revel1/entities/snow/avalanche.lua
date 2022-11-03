local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Avalanche
local bal = {
    SpawnCooldown = {Min = 30, Max = 70},
    EnemyHealthScale = 0.5,
    EnemySizeScale = 0.75,
    AngleVariation = {Min = 25, Max = 45}, -- slight directional offset from straight down based on facing direction
    DefaultSpawnCap = 3,
    DefaultNumSpawned = 1,
    SnowballSpawnCap = 10,
    SnowballNumSpawned = 4,
    SpawnToStopDuration = 26, --from anm2
    DeathNumSpawned = 1,
    DamageOnSpawn = {Min = 1, Max = 3.5},
}

local function SpawnEntity(npc, spawnData)
    local data = npc:GetData()
    local ent = REVEL.SpawnEntCoffin(spawnData.Type, spawnData.Variant, 0, npc.Position + REVEL.VEC_DOWN * 2, REVEL.VEC_DOWN:Rotated(math.random(bal.AngleVariation.Min, bal.AngleVariation.Max) * data.AngleMulti) * 3, npc)
    ent.SpawnerEntity = npc
    REVEL.ScaleEntity(ent, {SpriteScale = bal.EnemySizeScale, SizeScale = bal.EnemySizeScale, HealthScale = bal.EnemyHealthScale, ScaleChildren = true})
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.AVALANCHE:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.Init then
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc.SplatColor = REVEL.SnowSplatColor

        data.Cooldown = math.random(bal.SpawnCooldown.Min, bal.SpawnCooldown.Max) / 2
        data.Position = npc.Position

        local currentRoom = StageAPI.GetCurrentRoom()
        local index = REVEL.room:GetGridIndex(npc.Position)

        data.SpawnData = currentRoom.Metadata:Search{Index = index, Name = "AvalancheSpawnData"}[1]
        data.SpawnData = data.SpawnData and data.SpawnData.AvalancheSpawn

        local dirs = currentRoom.Metadata:GetDirections(index)
        local dirAngle = dirs and dirs[1]
        if dirAngle then
            local direction = REVEL.GetDirectionFromAngle(dirAngle)
            if direction == Direction.RIGHT then
                sprite.FlipX = true
            elseif direction ~= Direction.LEFT then
                local centerPos = REVEL.room:GetCenterPos()
                if npc.Position.X == centerPos.X then
                    sprite.FlipX = npc:GetPlayerTarget().Position.X > npc.Position.X
                else
                    sprite.FlipX = centerPos.X > npc.Position.X
                end
            end
        end

        data.AngleMulti = (sprite.FlipX and -1) or 1

        data.Init = true
    end

    npc.Friction = 0.1
    npc.Velocity = data.Position - npc.Position

    local spawned = Isaac.CountEntities(npc, EntityType.ENTITY_NULL, -1, -1) or 0 --data.SpawnData.Type, data.SpawnData.Variant, -1)
    local spawnCap, spawnsPerAnim = bal.DefaultSpawnCap, bal.DefaultNumSpawned
    local anim = "MouthOpen"

    if REVEL.ENT.SNOWBALL:isEnt(data.SpawnData) then
        spawnCap = bal.SnowballSpawnCap
        spawnsPerAnim = bal.SnowballNumSpawned
        anim = "MouthOpenLong"
    end

    if sprite:IsEventTriggered("Cough") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 0.7, 0, false, 0.5)
    end

    if not data.SpawnData then
        anim = "Idle"
        sprite:Play("Idle", true)
    end

    if sprite:IsFinished("Appear") then
        sprite:Play("Idle", true)
    end
    if sprite:IsPlaying("MouthOpen") then
        if sprite:IsEventTriggered("Spawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_0, 0.8, 0, false, 0.7)
            local dmg = REVEL.GetFromMinMax(bal.DamageOnSpawn)
            if dmg > 0 then
                npc:TakeDamage(dmg, 0, EntityRef(npc), 5)
            end
            REVEL.game:ShakeScreen(8)
            local toSpawn = math.max(0, math.min(spawned + spawnsPerAnim, spawnCap) - spawned)
            for i = 1, toSpawn do
                SpawnEntity(npc, data.SpawnData)
            end
        end
    elseif sprite:IsPlaying("MouthOpenLong") then
        if sprite:IsEventTriggered("Spawn") then
            SpawnEntity(npc, data.SpawnData)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_ROAR_1, 0.8, 0, false, 0.7)
        end
        if sprite:WasEventTriggered("Spawn") and not sprite:WasEventTriggered("SpawnStop") then
            REVEL.game:ShakeScreen(5)
            if npc.FrameCount % 5 == 0 and data.SpawnedThisAnim < spawnsPerAnim and spawned < spawnCap then
                data.SpawnedThisAnim = data.SpawnedThisAnim + 1
                SpawnEntity(npc, data.SpawnData)
            end
        end
        if sprite:IsEventTriggered("SpawnStop") then
            local dmg = REVEL.GetFromMinMax(bal.DamageOnSpawn)
            if dmg > 0 then
                npc:TakeDamage(dmg, 0, EntityRef(npc), 5)
            end
        end
    elseif sprite:IsFinished(anim) then
        sprite:Play("Idle", true)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        data.Cooldown = math.random(bal.SpawnCooldown.Min, bal.SpawnCooldown.Max)
    elseif sprite:IsPlaying("Idle") then
        if spawned < spawnCap or data.Cooldown > 10 then
            data.Cooldown = data.Cooldown - 1
            if data.Cooldown <= 0 then
                sprite:Play(anim, true)
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                data.SpawnedThisAnim = 0
            end
        end
    end
end, REVEL.ENT.AVALANCHE.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc)
    if not REVEL.ENT.AVALANCHE:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()
    for i = 1, bal.DeathNumSpawned do
        local ent = Isaac.Spawn(data.SpawnData.Type, data.SpawnData.Variant, 0, npc.Position + REVEL.VEC_RIGHT * (math.random(10) - 5), Vector.Zero, npc)
    end
end, REVEL.ENT.AVALANCHE.id)

StageAPI.AddCallback("Revelations", "PRE_SELECT_ENTITY_LIST", 5, function(entityList, spawnIndex, entityMeta)
    local avalanche = nil
    for i, entityInfo in ipairs(entityList) do
        if REVEL.ENT.AVALANCHE:isEnt(entityInfo) then
            avalanche = table.remove(entityList, i)
        end
    end

    if avalanche then
        local newList = { avalanche }

        local spawn = entityList[StageAPI.Random(1, #entityList, StageAPI.RoomLoadRNG)]
        local meta =  entityMeta:AddMetadataEntity(spawnIndex, "AvalancheSpawnData")
        meta.AvalancheSpawn = spawn

        return nil, newList, true
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()