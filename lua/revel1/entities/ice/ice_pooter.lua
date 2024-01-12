return function()


function REVEL.SpawnFriendlyIceBlock(pos, vel, spawner, pooter, dmg)
    local e = REVEL.ENT.ICE_POOTER:spawn(pos, vel, spawner)
    local sprite, data = e:GetSprite(), e:GetData()
    e:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    sprite:Play("Land", true)
    data.vel = vel
    data.friendly = true
    e:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
    e.CollisionDamage = dmg
    data.Damage = dmg
    data.ReducedCreep = true

    if not pooter then
        data.noPooter = true
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/ice_pooter_empty.png")
        sprite:LoadGraphics()
    end

    return e
end

local function IcePooterDie(npc, spr, data)
    REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
    spr:Play("Break", true)
    npc:Die()
    for i=1, 6 do
        REVEL.SpawnIceRockGib(npc.Position, RandomVector():Resized(math.random(1, 5)), npc)
    end
end

local function IcePooterHit(npc, spr, data)
    if not data.HitCooldown or data.HitCooldown <= 0 then
        if not data.hitwall and not data.SingleHit then
            spr:Play("Hit", true)
            data.hitwall = true
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 1)
        else
            IcePooterDie(npc, spr, data)
            if not data.noPooter then
                local p = Isaac.Spawn(EntityType.ENTITY_POOTER, 0, 0, npc.Position, Vector.Zero, npc.SpawnerEntity)
                p:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                p:GetData().IcePooter = true
                if data.friendly then
                    p:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
                    p:AddEntityFlags(EntityFlag.FLAG_CHARM)
                end
            end

            if data.TearBlast then
                for angle = 0, 315, 45 do
                    Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(angle) * 10, npc)
                end
            end
        end
    end
end

local function icepooterPooterPreUpdate(_, npc)
    if npc:GetData().IcePooter and npc.FrameCount <= 30 then
        if npc.State == NpcState.STATE_ATTACK then
            npc.State = NpcState.STATE_MOVE
        end
    end
end

local function icePooter_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.ICE_POOTER.variant then return end
    local spr,data = npc:GetSprite(), npc:GetData()


    if data.HitCooldown then
        data.HitCooldown = data.HitCooldown - 1
    end

    if not data.Init then
        data.prevVel = npc.Velocity
        npc:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_DEATH_TRIGGER)
        npc.SplatColor = REVEL.SnowSplatColor
        if data.friendly then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        end
        data.speed = data.speed or 8
        data.Init = true
    end

    npc.Velocity = npc.Velocity:Resized(data.speed)

    if spr:IsFinished("Land") then
        if data.hitwall then
            spr:Play("Slide 2", false)
        else
            spr:Play("Slide", false)
        end
    end

    if spr:IsEventTriggered("Creep") then
        if data.Lust and data.Lust.Variant == 1 then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.9, 0, false, 1)
        else
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 0.6, 0, false, 1)
        end
    end

    local creepPeriod = 3
    if data.ReducedCreep then
        creepPeriod = 12
    end

    if npc.FrameCount % creepPeriod == 0 then
        -- REVEL.DebugToConsole(data.Lust, data.Lust and data.Lust.Variant == 1)
        if data.friendly then
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, npc.Position, Vector.Zero, nil)
            creep.Color = REVEL.IceCreepColor
        elseif not (data.Lust and data.Lust.Variant == 1) then
            REVEL.SpawnIceCreep(npc.Position, npc.SpawnerEntity)
        end
    end

    if npc.FrameCount % 15 == 0 and data.Lust and data.Lust.Variant == 1 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, npc.Position, Vector.Zero, nil)
    end

    --  REVEL.DebugToString({npc.Index, data.hitwall, data.hitCooldown, data.vel, npc.Velocity, npc.Position})
    local forward = npc.Position + npc.Velocity * 2
    local nextGridId, gridId = REVEL.room:GetGridIndex(forward), REVEL.room:GetGridIndex(npc.Position)

    local hit
    if data.ignoreGrids then
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    else
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
    end
    if not data.gridImmunity and (data.prevVel.X * npc.Velocity.X < 0 or data.prevVel.Y * npc.Velocity.Y < 0) then
        hit = true
    end

    for i,e in ipairs(REVEL.roomEnemies) do
        if not e:IsDead() and not data.IgnoreMonsters and e.HitPoints ~= 0 and e:IsActiveEnemy(false) and e.Index ~= npc.Index and npc.Position:DistanceSquared(e.Position) < (e.Size+npc.Size+10)^2 then
            npc.Velocity = (npc.Position - e.Position):Resized(data.speed)
            hit = true
            if data.friendly then
                e:TakeDamage(data.Damage or e.CollisionDamage, 0, EntityRef(npc), 5)
            end
            if e.Type == REVEL.ENT.STALACTITE.id and e.Variant == REVEL.ENT.STALACTITE.variant 
            and e:ToNPC().State == NpcState.STATE_MOVE then
                e:Die()
            end
        elseif (not data.HitCooldown or data.HitCooldown <= 0) and
        (e.Type == EntityType.ENTITY_KNIFE and e.Variant == 1 and e.SubType == 4)
        and (npc.Position + npc.Velocity):DistanceSquared(e.Position) < (e.Size+npc.Size)^2 then --bone slash
            npc.Velocity = (npc.Position - e.Position):Resized(data.speed)
        end
    end

    if data.damageTimer then
        data.damageTimer = data.damageTimer - 1
        if data.damageTimer < 0 then
            data.damageTimer = data.initDamageTimer
            hit = true
        end
    end

    if hit and not data.Lust then
        IcePooterHit(npc, spr, data)
    end

    if data.Lust and (data.Lust:IsDead() or not data.Lust:Exists()) then
        IcePooterDie(npc, spr, data)
    end

    data.prevVel = REVEL.CloneVec(npc.Velocity)
end

-- prevent pooter insta shooting
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if npc:GetData().IcePooter and npc.FrameCount <= 30 then
        local sprite = npc:GetSprite()
        if sprite:IsPlaying("Attack") then
            sprite:Play("Fly", true)
        end
    end
end, EntityType.ENTITY_POOTER)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, icePooter_NpcUpdate, REVEL.ENT.ICE_POOTER.id)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, icepooterPooterPreUpdate, EntityType.ENTITY_POOTER)

end