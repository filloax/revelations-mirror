local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

------------
-- TUSKY --
------------
REVEL.ENT.TUSKY.Balance = {
    WanderSpeed = 3,
    WanderTimer = 50,
    WanderWait = 6,
    ChargeThreshold = 5,
    ChargeSpeed = 10,
    TripTimeout = 20,
    EnemyDamage = 7,
    RiderAnims = {"Walk", "Idle", "Charge_Start_Side", "Charge_Side", "Charge_Start_Down", "Charge_Down", "Charge_Start_Up", "Charge_Up", "Hit_Side", "Hit_Down", "Hit_Up", "Appear"},
    RiderSprites = {[REVEL.ENT.SNOWBALL.id] = "tusky_rider_snowball", [REVEL.ENT.SNOWBOB.id] = "tusky_rider_snowbob", [EntityType.ENTITY_GAPER] = "tusky_rider_gaper"},
    RiderVariants = {[REVEL.ENT.SNOWBALL.id] = 1, [REVEL.ENT.SNOWBOB.id] = 4, [EntityType.ENTITY_GAPER] = 3},
    Riders = {
        {Type = REVEL.ENT.SNOWBALL.id, Variant = REVEL.ENT.SNOWBALL.variant},
        {Type = REVEL.ENT.SNOWBOB.id, Variant = REVEL.ENT.SNOWBOB.variant},
        {Type = EntityType.ENTITY_GAPER, Variant = 0},
        {Type = EntityType.ENTITY_GAPER, Variant = 1},
    },
    RandomRiderChance = 0.5, --chance to spawn a rider with the random rider or no rider metaentity
    PinkChance = 0.05,
}

revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, ent)
    if not REVEL.ENT.TUSKY:isEnt(npc) then return end

    local data = REVEL.GetData(npc)
    if not data.State == 'Charging' then return end

    if ent:IsVulnerableEnemy()
    and not REVEL.ENT.TUSKY:isEnt(ent)
    and not (REVEL.GetData(ent).TuskySpawner and GetPtrHash(npc) == GetPtrHash(REVEL.GetData(ent).TuskySpawner))
    and not (npc.SpawnerEntity and GetPtrHash(npc.SpawnerEntity) == GetPtrHash(ent)) then
        ent:TakeDamage(data.bal.EnemyDamage, 0, EntityRef(npc), 60)
    end
end, REVEL.ENT.TUSKY.id)

local function SpawnRider(npc, data, velocity)
    local rider = Isaac.Spawn(data.Rider.Type, data.Rider.Variant, 0, npc.Position, Vector.Zero, npc)
    rider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    REVEL.GetData(rider).TuskySpawner = npc
    local l = velocity:Length()
    if l > 0 then
        REVEL.PushEnt(rider, l, velocity / l, 9)
    end

    if REVEL.ENT.SNOWBOB:isEnt(data.Rider) then
        REVEL.GetData(rider).bobskin = data.RiderVariant
    else
        REVEL.GetData(rider).ForceSpriteVariant = data.RiderVariant
    end

    data.Rider = nil
end

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, amt, flags, src, frames)
    if not REVEL.ENT.TUSKY:isEnt(npc) then return end

    local data = REVEL.GetData(npc)

    if HasBit(flags, DamageFlag.DAMAGE_EXPLOSION) then
        if not data.FakeDamage then
            data.FakeDamage = true
            npc:TakeDamage(amt * 0.5, flags, src, frames)
            data.FakeDamage = false
            return false
        end
    end

    if npc.HitPoints - amt - REVEL.GetDamageBuffer(npc) <= 0 and data.Rider then
        SpawnRider(npc, data, npc.Velocity)
    end
end, REVEL.ENT.TUSKY.id)

local RiderAnimSuffix = {"", "2", "3", "4"}

local function GetRiderAnim(sprite, bal, variant)
    local baseAnim = sprite:GetAnimation()
    if not baseAnim then
        error("Tusky anim not found!" .. REVEL.TryGetTraceback())
    end
    return baseAnim .. RiderAnimSuffix[variant]
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.TUSKY:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if not data.Init then
        data.bal = REVEL.ENT.TUSKY.Balance

        npc.SplatColor = REVEL.SnowSplatColor

        data.WanderCounter = data.bal.WanderWait
        data.State = 'Idle'

        npc.Friction = 0.6

        local rng = REVEL.RNG()
        rng:SetSeed(npc.InitSeed, 0)

        if rng:RandomFloat() < data.bal.PinkChance then
            sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/tusky/tusky_pink.png")
            sprite:ReplaceSpritesheet(1, "gfx/monsters/revel1/tusky/tusky_pink.png")
            sprite:LoadGraphics()
        end

        local index = REVEL.room:GetGridIndex(npc.Position)
        local croom = StageAPI.GetCurrentRoom()

        if croom then
            local riderMetaents = croom.Metadata:Search{Index = index, Tag = "TuskyRider"}
            if #riderMetaents > 0 then
                local riderMeta = REVEL.randomFrom(riderMetaents, rng)
                if riderMeta.Name == "TuskySpecificRider" then
                    data.Rider = riderMeta.TuskyRider
                elseif riderMeta.Name == "Tusky Random Rider (Force)"
                or (riderMeta.Name == "Tusky Random Rider (Or no rider)" and rng:RandomFloat() < data.bal.RandomRiderChance) then
                    data.Rider = REVEL.randomFrom(data.bal.Riders, rng)
                end
            end
        end

        if npc:HasEntityFlags(EntityFlag.FLAG_APPEAR) then
            if not data.Rider and rng:RandomFloat() > 0.2 then
                sprite:Play("AppearNoRider", true)
                npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                Isaac.Spawn(1000, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, npc)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOG_SCRATCH, 1, 0, false, 0.9+(math.random()*0.2))
            else
                sprite:Play("Appear", true) --so that the GetRiderAnim immediately after catches it
            end
        else --spawned by avalanche
            sprite:Play("Walk", true)
        end

        if data.Rider then
            data.RiderVariant = math.random(1, data.bal.RiderVariants[data.Rider.Type])
            data.RiderSprite = Sprite()
            data.RiderSprite:Load("gfx/monsters/revel1/tusky/" .. data.bal.RiderSprites[data.Rider.Type] .. ".anm2", true)
            local anim = GetRiderAnim(sprite, data.bal, data.RiderVariant)
            data.RiderSprite:Play(anim, true)
            data.LastAnim = anim
        end

        data.Init = true
    end

    if npc.FrameCount == 0 or sprite:IsPlaying("Appear") or sprite:IsPlaying("AppearNoRider") then
        npc.Velocity = npc.Velocity * 0.7
        return
    end

    if data.State == 'Charging' then
        npc.Velocity = data.CurrVel

        local endSlide = false
        if data.Tripping then
            if sprite:IsEventTriggered('Land') then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_BUMP, 0.7, 0, false, 1.2+(math.random()*0.2))
                npc.Velocity = data.ChargeVel
            end

            if sprite:IsFinished('Trip_' .. data.Direction) then
                sprite:Play('Slide_' .. data.Direction, true)
            end

            endSlide = not REVEL.Glacier.CheckIce(npc, StageAPI.GetCurrentRoom())
        elseif npc.Velocity:LengthSquared() > 0.1 then
            if REVEL.Glacier.CheckIce(npc, StageAPI.GetCurrentRoom()) then
                data.Tripping = true
                npc:ClearEntityFlags(BitOr(EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
                npc.Velocity = npc.Velocity * 0.4
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.SWING, 1, 0, false, 0.9+(math.random()*0.2))
                sprite:Play('Trip_' .. data.Direction, true)
            elseif npc.FrameCount % 5 == 0 then
                local e = Isaac.Spawn(1000, EffectVariant.DUST_CLOUD, 0, npc.Position + REVEL.VEC_UP * 10 - npc.Velocity, Vector.Zero, npc):ToEffect()
                e.Timeout = 15
                e.LifeSpan = 22
                e.Color = Color(1, 1, 1, 0.5)
            end
        end

        local impact = false

        local nextGrid

        -- affect grid indexes at the edges of the ent's collider in the direction it's going
        local alignedpositions
        if data.Direction == 'Side' then
            local diff = sign(npc.Velocity.X) * 20
            local x = diff / npc.Size
            nextGrid = REVEL.room:GetGridCollisionAtPos(npc.Position + Vector(diff, 0))
            alignedpositions = { Vector(x, 1), Vector(x, -1) }
        else
            local diff = sign(npc.Velocity.Y) * 20
            local y = diff / npc.Size
            nextGrid = REVEL.room:GetGridCollisionAtPos(npc.Position + Vector(0, diff))
            alignedpositions = { Vector(1, y), Vector(-1, y) }
        end

        for _, off in pairs(alignedpositions) do
            local index = REVEL.room:GetGridIndex(npc.Position + off * npc.Size)
            local grid = REVEL.room:GetGridEntity(index)

            local isBreakableGrid = false
            if grid then
                isBreakableGrid = REVEL.includes({GridEntityType.GRID_ROCK, GridEntityType.GRID_ROCK_ALT,
                GridEntityType.GRID_ROCK_BOMB, GridEntityType.GRID_ROCKT,
                GridEntityType.GRID_POOP}, grid.Desc.Type)
            end

            local didBreak = false
            if not data.Tripping and isBreakableGrid then
                didBreak = REVEL.room:DestroyGrid(index, false)
            end

            if not didBreak and npc:CollidesWithGrid() and nextGrid > GridCollisionClass.COLLISION_NONE then
                if grid and grid.Desc.Type == GridEntityType.GRID_TNT and REVEL.CanGridBeDestroyed(grid) then
                    grid:Hurt(999)
                end
                impact = true
                endSlide = true
            end
        end

        if not npc:CollidesWithGrid() and sprite:IsFinished('Charge_Start_' .. data.Direction) then
            sprite:Play('Charge_' .. data.Direction)
            npc.Velocity = data.ChargeVel
            npc:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
        end

        if endSlide then
            data.State = 'Crashing'
            npc:ClearEntityFlags(BitOr(EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
            if impact then
                npc.Velocity = Vector.Zero
                REVEL.game:ShakeScreen(10)
                REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOG_SLAM, 1, 0, false, 0.9+(math.random()*0.2))
            end
            if data.Tripping then
                data.TripCounter = data.bal.TripTimeout
            else
                sprite:Play('Hit_' .. data.Direction, true)
            end
        end
    elseif data.State == 'Crashing' then
        npc.Velocity = npc.Velocity * 0.7

        if data.Tripping and data.TripCounter then
            data.TripCounter = data.TripCounter - 1
            if data.TripCounter <= 0 then
                sprite:Play('Hop_' .. data.Direction, true)
                data.TripCounter = nil
            elseif sprite:IsFinished('Trip_' .. data.Direction) then
                sprite:Play('Slide_' .. data.Direction, true)
            end
        end

        if sprite:IsFinished((data.Tripping and 'Hop_' or 'Hit_') .. data.Direction) then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOG_OINK, 1, 0, false, 0.9+(math.random()*0.2))
            data.State = 'Idle'
            data.Tripping = nil
            data.WanderCounter = data.bal.WanderWait
        end
    else
        if npc.Velocity.X ~= 0 then
            sprite.FlipX = npc.Velocity.X > 0
        end

        for _, player in ipairs(REVEL.players) do
            local diff = player.Position - npc.Position
            local rush = false
            if math.abs(diff.X) < data.bal.ChargeThreshold then
                data.Direction = diff.Y < 0 and 'Up' or 'Down'
                data.ChargeVel = Vector(0, sign(diff.Y) * data.bal.ChargeSpeed)
                rush = true
            elseif math.abs(diff.Y) < data.bal.ChargeThreshold then
                data.Direction = 'Side'
                data.ChargeVel = Vector(sign(diff.X) * data.bal.ChargeSpeed, 0)
                sprite.FlipX = diff.X > 0
                rush = true
            end

            if rush then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOG_IGNITION, 1, 0, false, 0.9+(math.random()*0.2))
                data.State = 'Charging'
                sprite:Play('Charge_Start_' .. data.Direction)
                npc.Velocity = Vector.Zero
                break
            end
        end

        if npc.FrameCount % 30 == 0 then
            if math.random(1,2) == 1 then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.HOG_OINK, 1, 0, false, 0.9+(math.random()*0.2))
            end
        end

        if data.WanderCounter > 0 then
            data.WanderCounter = data.WanderCounter - 1
        end

        if data.WanderCounter <= 0 then
            if data.State == 'Idle' then
                local target = npc:GetPlayerTarget()
                npc.Velocity = (target.Position - npc.Position)
                                :Resized(data.bal.WanderSpeed)
                                :Rotated(math.random(-20, 20))

                data.WanderCounter = data.bal.WanderTimer
                data.State = 'Wander'
                sprite:Play('Walk', true)
            elseif data.State == 'Wander' then
                npc.Velocity = Vector.Zero
                data.WanderCounter = data.bal.WanderWait
                data.State = 'Idle'
                sprite:Play('Idle', true)
            end
        end
    end

    if data.Rider then
        if sprite:IsEventTriggered("Trip") then
            SpawnRider(npc, data, -npc.Velocity)
        else
            data.RiderSprite:Update()
            local anim = GetRiderAnim(sprite, data.bal, data.RiderVariant)
            if anim ~= data.LastAnim then
                data.RiderSprite:Play(anim, true)
            end
            if sprite:GetFrame() ~= data.RiderSprite:GetFrame() then
                data.RiderSprite:Play(anim, true)
                REVEL.SkipAnimFrames(data.RiderSprite, sprite:GetFrame())
            end
            data.RiderSprite.FlipX = sprite.FlipX
            data.LastAnim = anim
        end
    end

    data.CurrVel = npc.Velocity
end, REVEL.ENT.TUSKY.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    if not REVEL.ENT.TUSKY:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if data.Rider then
        if not REVEL.game:IsPaused() 
        and (npc.FrameCount == 0 or sprite:IsPlaying("Appear"))
        and REVEL.IsRenderPassNormal() then
            if not data.LastUpdate then
                data.RiderSprite:Update()
                data.LastUpdate = true
            else
                data.LastUpdate = nil
            end
        end

        local pos = Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset()
        if not REVEL.ENT.SNOWBALL:isEnt(data.Rider) then
            data.RiderSprite:RenderLayer(3, pos)
            data.RiderSprite:RenderLayer(2, pos)
            sprite:Render(pos, Vector.Zero, Vector.Zero)
            data.RiderSprite:RenderLayer(0, pos)
            data.RiderSprite:RenderLayer(1, pos)
        else
            data.RiderSprite:RenderLayer(1, pos)
            data.RiderSprite:RenderLayer(0, pos)
            sprite:Render(pos, Vector.Zero, Vector.Zero)
            data.RiderSprite:RenderLayer(2, pos)
        end
    end
end, REVEL.ENT.TUSKY.id)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SELECT_ENTITY_LIST, 0, function(entityList, spawnIndex, entityMeta)
    local tusky = nil
    for i, entityInfo in ipairs(entityList) do
        if REVEL.ENT.TUSKY:isEnt(entityInfo) then
            tusky = entityInfo
            break
        end
    end

    if tusky then
        local prevLen = #entityList
        local validRiders = {}

        for i, entityInfo in ripairs(entityList) do
            for _, possibleRider in pairs(REVEL.ENT.TUSKY.Balance.Riders) do
                if entityInfo.Type == possibleRider.Type and entityInfo.Variant == possibleRider.Variant then
                    validRiders[#validRiders + 1] = entityInfo
                    table.remove(entityList, i)
                end
            end
        end

        local rider
        if #validRiders > 1 then
            rider = validRiders[StageAPI.Random(1, #validRiders, StageAPI.RoomLoadRNG)]
        else
            rider = validRiders[1]
        end

        if rider then
            local metaEntity = entityMeta:AddMetadataEntity(spawnIndex, "TuskySpecificRider")
            metaEntity.TuskyRider = rider
        end

        if #entityList ~= prevLen then
            return nil, entityList, true
        end
    end
end)

end