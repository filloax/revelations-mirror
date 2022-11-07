local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
-- Tomb sloth

local MaxSlothEnemies = 6

local function tombSloth_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage()
    or npc.Variant >= 2 then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if sprite:IsFinished("Attack") then
        npc.State = NpcState.STATE_MOVE
    end
    if npc.State == NpcState.STATE_ATTACK then -- black creep
        npc.Velocity = Vector.Zero
        if sprite:IsEventTriggered("Attack") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_2, 0.7, 0, false, 1)
            data.creeptotarget = (target.Position - npc.Position):Normalized()
        end
        local frame = sprite:GetFrame()
        if sprite:WasEventTriggered("Attack") and frame <= 14 then
            if not data.creeptotarget then
                data.creeptotarget = (target.Position - npc.Position):Normalized()
            end
            
            Isaac.Spawn(
                EntityType.ENTITY_EFFECT, 
                EffectVariant.CREEP_BLACK, 
                0, 
                npc.Position + data.creeptotarget * (frame - 3) * 20
                    + Vector(math.random()-0.5,math.random()-0.5) * 10, 
                Vector.Zero, 
                npc
            )
        end
        return true
    elseif npc.State == NpcState.STATE_ATTACK2 then -- spawn innards or shoot spider at innard
        npc.Velocity = Vector.Zero
        local innards = Isaac.FindByType(REVEL.ENT.INNARD.id, REVEL.ENT.INNARD.variant, -1, false, false)
        local spiders = Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)
        if #spiders + #innards > MaxSlothEnemies or npc.StateFrame == 1 and math.random() > 2 / math.max(1, #spiders) then
            npc.State = NpcState.STATE_ATTACK
            return true
        end
        if sprite:IsEventTriggered("Attack") then
            if #innards == 0 then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SUMMONSOUND, 0.7, 0, false, 1)
                Isaac.Spawn(REVEL.ENT.INNARD.id, REVEL.ENT.INNARD.variant, 0, npc.Position+Vector(0,10), Vector.Zero, npc)
            else
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_2, 0.7, 0, false, 1)
                EntityNPC.ThrowSpider(npc.Position, npc, innards[1].Position, npc.Variant == 1, -10)
                if not innards[1]:GetData().FramesUntilDeath then
                    innards[1]:GetData().FramesUntilDeath = 25
                end
            end
        end
        return true
    end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombSloth_PreUpdate, EntityType.ENTITY_SLOTH)

-- Tomb Gluttony

local GluttonyFrames = {
	OPEN_START = 28,
	OPEN_END = 72,
	SHOOT_START = 30,
	SHOOT_END = 72,
}

---@param npc EntityNPC
local function tombGluttony_Init(_, npc)
	if not REVEL.STAGE.Tomb:IsStage() then return end

	npc.MaxHitPoints = npc.MaxHitPoints * 0.75
	npc.HitPoints = npc.MaxHitPoints
end

---@param npc EntityNPC
local function tombGluttony_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if npc.State == NpcState.STATE_ATTACK4 then
        npc.Velocity = Vector.Zero
        local animnames = {"Horiz", "Down", "Up"}
        local playingAny
        for i=1, 3 do
            if sprite:IsFinished("Attack02"..animnames[i]) then
                npc.State = NpcState.STATE_MOVE
            end

            if sprite:IsPlaying("Attack02" .. animnames[i]) then
                playingAny = true
            end
        end

        if not playingAny then
            npc.State = NpcState.STATE_MOVE
        end

        local frame = sprite:GetFrame()
        if frame >= 10 then
            if frame >= GluttonyFrames.SHOOT_START and frame < GluttonyFrames.SHOOT_END then
                if frame == GluttonyFrames.SHOOT_START then
                    local creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
                    REVEL.UpdateCreepSize(creep, creep.Size * 4, true)

                    local tarParams = ProjectileParams()
                    local tarColor = Color(1, 1, 1, 1)
                    tarColor:SetColorize(0.7,0.7,0.75,1)
                    tarParams.Color = tarColor
                    tarParams.VelocityMulti = 0.5
                    npc:FireBossProjectiles(8, Vector.Zero, 10, tarParams)
                end

                for i=1, 3 do
                    for i2=1, 3 do
                        if sprite:IsPlaying("Attack0"..tostring(i2)..animnames[i]) then
                            local animname = animnames[i]
                            local angle
                            if animname == "Horiz" then
                                if npc:GetSprite().FlipX then
                                    angle = 180
                                else
                                    angle = 0
                                end
                            elseif animname == "Down" then
                                angle = 90
                            elseif animname == "Up" then
                                angle = 270
                            end

                            local playerAngle = (target.Position - npc.Position):GetAngleDegrees()
                            local angleDiff = REVEL.GetAngleDifference(angle, playerAngle)
                            angleDiff = math.max(-25, math.min(25, angleDiff))
                            angle = angle - angleDiff

                            angle = angle + math.random(-10, 10)

                            local off = Vector(0, 3)
                            if animname == "Up" then
                                off = -off
                            end

                            local tear = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position + off, Vector.FromAngle(angle) * math.random(8, 13), npc):ToProjectile()
                            tear:GetData().SpawnBlackCreep = true
                            tear.FallingSpeed = -math.random()*13+3
                            tear.FallingAccel = math.random()*0.7+0.1
                            tear:GetSprite().Color = Color(0.1, 0.1, 0.1, 1,conv255ToFloat( 0, 0, 0))

                            if npc.Variant == 1 then
                                local tear2 = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position - off, tear.Velocity*-1, npc):ToProjectile()
                                tear2:GetData().SpawnBlackCreep = true
                                tear2.FallingSpeed = -math.random()*13+3
                                tear2.FallingAccel = math.random()*0.7+0.2
                                tear2:GetSprite().Color = Color(0.1, 0.1, 0.1, 1,conv255ToFloat( 0, 0, 0))
                            end

                            if frame % 2 == 0 then
                                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
                            end
                        end
                    end
                end
            end
        end
    elseif npc.State == NpcState.STATE_ATTACK then
        if sprite:IsFinished("FatAttack") then
            npc.State = NpcState.STATE_MOVE
        elseif not sprite:IsPlaying("FatAttack") then
            sprite:Play("FatAttack", true)
        end

        npc.Velocity = Vector.Zero

        if sprite:IsPlaying("FatAttack") and sprite:GetFrame() == 11 then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_BLACK, 0, npc.Position, npc, false)
            REVEL.UpdateCreepSize(creep, creep.Size * 4, true)

            for i = 1, 8 do
                local tear = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, Vector.FromAngle(i * 45) * 7, npc):ToProjectile()
                tear:GetData().SpawnBlackCreep = true
                tear:GetSprite().Color = Color(0.1, 0.1, 0.1, 1,conv255ToFloat( 0, 0, 0))
            end

            if npc.Variant == 1 then
                local tarParams = ProjectileParams()
                tarParams.Color = Color(0.1, 0.1, 0.1, 1,conv255ToFloat( 0, 0, 0))
                npc:FireBossProjectiles(8, target.Position, 10, tarParams)
            end
        end
    elseif npc.State == NpcState.STATE_MOVE then
        if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        end    
        data.UsePlayerMap = true
        
        data.OnPathUpdate = REVEL.BonyPathUpdate

        if data.Path then
            REVEL.FollowPath(npc, 0.5, data.Path, false, 0.75)
        end

        npc:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

        if not data.AttackCooldown then
            data.AttackCooldown = math.random(20, 60)
        end

        data.AttackCooldown = data.AttackCooldown - 1
        local facing, alignAmount = REVEL.GetAlignment(npc.Position, npc:GetPlayerTarget().Position)
        if alignAmount < 25 then
            data.AttackCooldown = data.AttackCooldown - 1
        end

        if data.AttackCooldown <= 0 then
            data.AttackCooldown = nil
            if alignAmount < 25 and math.random(1, 3) < 3 then
                npc.State = NpcState.STATE_ATTACK4

                if sprite:IsPlaying("WalkHori") then
                    sprite:Play("Attack02Horiz", true)
                else
                    sprite:Play("Attack02" .. facing, true)
                end
            else
                npc.State = NpcState.STATE_ATTACK
            end
        end
    end

    if npc.State ~= NpcState.STATE_INIT then
        return true
    end
end

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, tombGluttony_Init, EntityType.ENTITY_GLUTTONY)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombGluttony_PreUpdate, EntityType.ENTITY_GLUTTONY)

local function tombGluttony_BoulderImpact(boulder, npc, isGrid)
	npc:TakeDamage(npc.MaxHitPoints * 0.21, 0, EntityRef(boulder), 0)
	return true
end

local DoingModifiedDamage = false
local softDamageColor = Color(1,1,1,1,conv255ToFloat(55,15,15))

---@param e Entity
---@param dmg number
---@param flag integer
---@param src EntityRef
---@param invuln integer
---@return boolean?
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    if DoingModifiedDamage then
        return
    end

    if REVEL.STAGE.Tomb:IsStage() 
	and (not src or src.Type ~= REVEL.ENT.SAND_BOULDER.id or src.Variant ~= REVEL.ENT.SAND_BOULDER.variant) then
		local npc = e:ToNPC()
		local sprite, data = npc:GetSprite(), npc:GetData()
		local frame = sprite:GetFrame()

        if HasBit(flag, DamageFlag.DAMAGE_SPIKES) then 
            return false
        end

        local damageMod = 0.33

		if npc.State == NpcState.STATE_ATTACK4 and frame >= 10
		and frame >= GluttonyFrames.OPEN_START and frame < GluttonyFrames.OPEN_END then 
            damageMod = 1.5
		end

        if damageMod ~= 1 then
            DoingModifiedDamage = true
            e:TakeDamage(dmg * damageMod, flag, src, invuln)
            DoingModifiedDamage = false

            if damageMod < 1 then
                REVEL.sfx:NpcPlay(e:ToNPC(), SoundEffect.SOUND_MEAT_IMPACTS, 0.5, 0, false, 1.5)
                e:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
                e:SetColor(softDamageColor, 3, 50, true, false)
                REVEL.DelayFunction(1, function() e:ClearEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE) end, nil, true)
            end
            return false
        end
    end
end, EntityType.ENTITY_GLUTTONY)


local function tombPride_BoulderImpact(boulder, npc, isGrid)
	npc:TakeDamage(npc.MaxHitPoints * 0.1, 0, EntityRef(boulder), 0)
	return false
end


revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local data = e:GetData()
    if data.SpawnBlackCreep then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, e.Position, Vector.Zero, e)
        if data.BlackCreepTimeout then
            creep:ToEffect():SetTimeout(data.BlackCreepTimeout)
        end

        if data.BlackCreepScaleMulti then
            REVEL.UpdateCreepSize(creep, creep.Size * data.BlackCreepScaleMulti, true)
        end
    end
end, EntityType.ENTITY_PROJECTILE)


-- Tomb Lust

local function tombLust_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if not data.LustInit then
        npc.MaxHitPoints = npc.MaxHitPoints / 2
        npc.HitPoints = npc.MaxHitPoints
        data.LustInit = true
    end
    -- if data.RevBall and (not data.RevBall:Exists() or data.RevBall:IsDead()) then
    --     npc:Remove()
    -- end

    return data.Ragged
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombLust_PreUpdate, EntityType.ENTITY_LUST)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    local data = e:GetData()

    if REVEL.STAGE.Tomb:IsStage() then
        if not data.Ragged then
            if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0 and not data.Buffed then
                e.HitPoints = 0
                e.Visible = false
                e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                data.Ragged = true
                e:BloodExplode()
                e.Velocity = Vector.Zero

                local rag, rdata, rspr = REVEL.SpawnRevivalRag(e)
                rdata.OnRevive = function(rag, revivedEntity)
                    e:Remove()
                end

                local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, REVEL.room:GetCenterPos() + RandomVector() * (REVEL.room:GetGridWidth() * 40), Vector.Zero, nil):ToProjectile()
                proj:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                proj.Size = proj.Size * 4
                --proj:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_magicball.anm2", true)
                --proj:GetSprite():Play("Idle", true)
                proj.Color = Color(1,1,1,1,0.5,0,0.3)
                proj.Scale = 2.5
                proj.Height = -20
                proj.FallingSpeed = 0
                proj.FallingAccel = -0.1
                proj.RenderZOffset = 100001
                proj.ProjectileFlags = ProjectileFlags.SMART
                proj:GetData().LustBall = true --Code for ball is in entities2, with the rev shrine/ragmancer stuff
                proj:Update()
                proj.ProjectileFlags = 0
                proj:GetData().PurpleColor = proj.Color
                --proj.Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
                proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

                return false
            end
        else
            return false
        end
    end
end, EntityType.ENTITY_LUST)

-- Tomb Pride

local PrideBombFrames = {
    [0] = {6, 11, 16, 22},
    [1] = {11, 16}
}

local PrideBombSoundFrame = 17
    
local function tombPride_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if not data.PrideInit then
        data.TriggeredTraps = {}
        data.PrideInit = true
    end

    if sprite:IsEventTriggered("Land") then
        REVEL.TriggerTrapsInRange(npc.Position, npc.Size + 16, true, true)
    end

    -- if npc.State == NpcState.STATE_MOVE then
    --     npc.State = NpcState.STATE_SUMMON
    -- else
    if npc.State == NpcState.STATE_ATTACK2 then
        npc.State = NpcState.STATE_SUMMON2
    end
    -- if npc.State == NpcState.STATE_SUMMON then
    --     npc.Pathfinder:MoveRandomlyAxisAligned(5, false)
    -- else
    if npc.State == NpcState.STATE_SUMMON2 then
        -- npc.Velocity = npc.Velocity * 0.6
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GURG_BARF, 0.7, 0, false, 1)
        end
        
        if sprite:IsPlaying("Attack02") and sprite:GetFrame() == PrideBombSoundFrame then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.7, 0, false, 1)
        end

        if sprite:IsPlaying("Attack02") and REVEL.includes(PrideBombFrames[npc.Variant], sprite:GetFrame()) then
            local pos
            local traps = REVEL.GetFilteredArray(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false), function(ent)
                local edata = ent:GetData()
                return edata.TrapData and not data.TriggeredTraps[ent.InitSeed] and REVEL.IsTrapTriggerable(ent, edata)
            end)
            if #traps > 0 and math.random() > 0.6 then
                local trap = REVEL.randomFrom(traps)
                data.TriggeredTraps[trap.InitSeed] = true
                pos = trap.Position
            else
                pos = Isaac.GetFreeNearPosition(Isaac.GetRandomPosition(), 40)
            end

            if npc.Variant == 0 then
                Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, pos, Vector.Zero, npc)
            else --if champion, spawn mega troll bomb slightly further away so that it triggers the trap when moving close to the player
                local player = REVEL.getClosestInTableFromPos(REVEL.players, pos)
                local diff = pos - player.Position
                local dist = diff:Length()
                pos = player.Position + diff * ((dist + 60) / dist)
                Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_SUPERTROLL, 0, pos, Vector.Zero, npc)
            end
        elseif sprite:IsFinished("Attack02") then
            data.TriggeredTraps = {}
            npc.State = NpcState.STATE_MOVE
        end
    end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombPride_PreUpdate, EntityType.ENTITY_PRIDE)

revel:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, e)
    local flameTraps = Isaac.FindByType(REVEL.ENT.FLAME_TRAP.id, REVEL.ENT.FLAME_TRAP.variant, -1, false, false)
    local arrowTraps = Isaac.FindByType(REVEL.ENT.ARROW_TRAP.id, REVEL.ENT.ARROW_TRAP.variant, -1, false, false)
    if (#flameTraps > 0 or #arrowTraps > 0) and REVEL.STAGE.Tomb:IsStage() and e.Parent and e.Parent.Type == EntityType.ENTITY_PRIDE then
        for _, trap in ipairs(flameTraps) do
            if REVEL.CollidesWithLaser(trap.Position, e, 6) then
                local data = trap:GetData()
                data.NoHitPlayer = false
                data.DeactivateAt = trap.FrameCount + 150

                local sprite = trap:GetSprite()
                if not sprite:IsPlaying("Shoot") then
                    sprite:Play("Shoot", true)
                end
            end
        end

        for _, trap in ipairs(arrowTraps) do
            if REVEL.CollidesWithLaser(trap.Position, e, 18) then
                local data = trap:GetData()
                data.NoHitPlayer = false

                local sprite = trap:GetSprite()
                if not sprite:IsPlaying("Shoot") then
                    sprite:Play("Shoot", true)
                end
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, b)
    if b.SpawnerType == EntityType.ENTITY_PRIDE and (b:GetSprite():WasEventTriggered("DropSound") or b:GetSprite():IsPlaying("Pulse")) then
        REVEL.TriggerTrapsInRange(b.Position, b.Size + 5)
    end
end)

function REVEL.IsPrideRoom() --used in tomb.lua
    if REVEL.STAGE.Tomb:IsStage() then
        local prides = Isaac.FindByType(EntityType.ENTITY_PRIDE, -1, -1, false, false)
        return #prides > 0
    end
    return false
end

-- Tomb envy

local function tombEnvy_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if npc.Variant > 1 then
        if not REVEL.TombEnvyRotatePos then
            REVEL.TombEnvyRotatePos = npc.Position
        end

        if not data.Init then
            table.insert(REVEL.TombEnvys, npc)
            data.Init = true
        end

        if data.TombEnvyPos then
            npc.Velocity = npc.Velocity*0.7+(data.TombEnvyPos-npc.Position):Resized(math.min(2, (data.TombEnvyPos-npc.Position):Length()))
        end

        if not npc:IsDead() and npc.FrameCount > 2 then
            return true
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombEnvy_PreUpdate, EntityType.ENTITY_ENVY)

REVEL.TombEnvys = {}

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    REVEL.TombEnvyRotatePos = nil
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.TombEnvyRotatePos then
        REVEL.TombEnvyRotatePos = REVEL.TombEnvyRotatePos+(REVEL.player.Position-REVEL.TombEnvyRotatePos):Resized(2.5)
        REVEL.TombEnvyRotation = REVEL.TombEnvyRotation or 0
        REVEL.TombEnvyRotation = REVEL.TombEnvyRotation+3

        for i,e in ipairs(REVEL.TombEnvys) do
            if not e:Exists() or e:IsDead() then
                table.remove(REVEL.TombEnvys, i)
            end
        end

        for i,e in ipairs(REVEL.TombEnvys) do
            e:GetData().TombEnvyPos = REVEL.TombEnvyRotatePos+Vector.FromAngle(360/#REVEL.TombEnvys*i+REVEL.TombEnvyRotation):Resized(20+#REVEL.TombEnvys*10)
        end
    end
end)

-- Tomb Greed

local function tombGreed_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    data.GreedNumCoins = data.GreedNumCoins or math.random(4,6)
    -- REVEL.DebugToConsole(npc.State, sprite:GetAnimation())

    if npc.State == NpcState.STATE_ATTACK then
        if not REVEL.MultiPlayingCheck(sprite, "WalkHori", "WalkVert") then
            local mode = 3
            if npc.Variant == 1 then mode = 5 end
            local frame = sprite:GetFrame()
            if frame == 5 then
                if sprite:IsPlaying("Attack01Hori") then
                    if sprite.FlipX then
                        npc:FireProjectiles(npc.Position, Vector(-10,0), mode, ProjectileParams())
                    else
                        npc:FireProjectiles(npc.Position, Vector(10,0), mode, ProjectileParams())
                    end
                elseif sprite:IsPlaying("Attack01Down") then
                    npc:FireProjectiles(npc.Position, Vector(0,10), mode, ProjectileParams())
                elseif sprite:IsPlaying("Attack01Up") then
                    npc:FireProjectiles(npc.Position, Vector(0,-10), mode, ProjectileParams())
                end
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
            end
            if sprite:IsFinished("Attack01Hori") or sprite:IsFinished("Attack01Down") or sprite:IsFinished("Attack01Up") then
                npc.State = NpcState.STATE_MOVE
            end
            if frame > 2 then
                npc.Velocity = Vector.Zero
                return true
            end
        end
    end

    if npc.State == NpcState.STATE_SUMMON then
        if data.GreedNumCoins > 1 then
            data.GreedSummon = true
            npc.State = NpcState.STATE_SUMMON
            sprite:Play("Attack02", true)
            data.GreedNumCoins = data.GreedNumCoins-1
            npc.Velocity = Vector.Zero
        else
            npc.State = NpcState.STATE_MOVE
        end
    end

    if data.GreedSummon then
        npc.Velocity = Vector.Zero
        if sprite:GetFrame() == 4 then
            for i=1, 2 do
                local ultra_coin = Isaac.Spawn(EntityType.ENTITY_ULTRA_COIN, 0, 0, npc.Position+Vector.FromAngle(math.random(0,359))*20, Vector.Zero, npc):ToNPC()
                ultra_coin:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                ultra_coin:GetData().TombGreedSpinningCoin = true
                if npc.Variant == 1 then
                    ultra_coin:GetData().TombGreedBombCoin = true
                end
                ultra_coin.Size = ultra_coin.Size/2
                ultra_coin.Scale = 0.6
                ultra_coin.MaxHitPoints = 9
                ultra_coin.HitPoints = 9
                ultra_coin:Update()
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SUMMONSOUND, 0.6, 0, false, 1)
            end
        end
        if sprite:IsFinished("Attack02") then
            data.GreedSummon = false
            npc.State = NpcState.STATE_MOVE
        end
        return true
    end

    for _,player in ipairs(REVEL.players) do
        if player:GetData().TombGreedCurrentCoins and player:GetData().TombGreedCurrentCoins ~= player:GetNumCoins() then
            data.GreedNumCoins = data.GreedNumCoins+1
        end
        player:GetData().TombGreedCurrentCoins = player:GetNumCoins()
    end
end

local function tombUltraCoin_PreUpdate(_, npc)
    if not REVEL.STAGE.Tomb:IsStage() then return end
    local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

    if data.TombGreedSpinningCoin then
        if not data.Init then
            if data.TombGreedBombCoin then
                sprite:Play("AppearBomb", true)
            else
                sprite:Play("AppearNeutral", true)
            end
            data.Init = true
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.Velocity = Vector.Zero
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ULTRA_GREED_COINS_FALLING, 0.5, 0, false, 1)
        end

        if sprite:IsFinished("AppearNeutral") then
            sprite:Play("SpinningNeutral", true)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end
        if sprite:IsFinished("AppearBomb") then
            sprite:Play("SpinningBomb", true)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if sprite:IsPlaying("SpinningNeutral") or sprite:IsPlaying("SpinningBomb") then
            npc.Velocity = npc.Velocity*0.95+(target.Position-npc.Position):Resized(0.4)
        end

        if sprite:IsPlaying("Crumble") then
            npc.Velocity = Vector.Zero
        end

        if sprite:IsFinished("Crumble") then
            npc:Remove()
        end

        return true
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombGreed_PreUpdate, EntityType.ENTITY_GREED)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, tombUltraCoin_PreUpdate, EntityType.ENTITY_ULTRA_COIN)

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
    if REVEL.STAGE.Tomb:IsStage() then
        if pickup.FrameCount == 1 and pickup.Variant == PickupVariant.PICKUP_COIN and pickup.SpawnerType == EntityType.ENTITY_GREED then
            pickup:Remove()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if REVEL.STAGE.Tomb:IsStage() and REVEL.IsRenderPassNormal() then
        local data = npc:GetData()
        if not data.Dying and npc:HasMortalDamage() then
            npc.HitPoints = 0
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.Velocity = Vector.Zero
            npc:GetSprite():Play("Crumble", true)
            if data.TombGreedBombCoin then
                Isaac.Explode(npc.Position, npc, 10)
            end
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY, 0.5, 0, false, 1)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, npc.Position, Vector(math.random()-0.5,math.random()-0.5)*10, npc)
            data.Dying = true
            npc.State = NpcState.STATE_UNIQUE_DEATH
        end
    end
end, EntityType.ENTITY_ULTRA_COIN)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if REVEL.STAGE.Tomb:IsStage() and REVEL.IsRenderPassNormal() then
        local data = npc:GetData()
        if not data.Dying and npc:HasMortalDamage() then
            for i=1, data.GreedNumCoins or 0 do
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, npc.Position, Vector(math.random()-0.5,math.random()-0.5)*10, npc)
            end
            local ultra_coins =  Isaac.FindByType(EntityType.ENTITY_ULTRA_COIN, -1, -1, false, false)
            for _,ultra_coin in ipairs(ultra_coins) do
                ultra_coin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                ultra_coin.Velocity = Vector.Zero
                ultra_coin:GetSprite():Play("Crumble", true)
                REVEL.sfx:NpcPlay(ultra_coin:ToNPC(), SoundEffect.SOUND_ULTRA_GREED_COIN_DESTROY, 0.5, 0, false, 1)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 1, ultra_coin.Position, Vector(math.random()-0.5,math.random()-0.5)*10, ultra_coin)
            end
            data.Dying = true
        end
    end
end, EntityType.ENTITY_GREED)

-- Tomb wrath

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    if not REVEL.STAGE.Tomb:IsStage() or bomb.SpawnerType ~= EntityType.ENTITY_WRATH then return end

    local data = bomb:GetData()
    data.deadframes = data.deadframes or 0
    if not data.norag and (not data.closestrag or not data.closestrag:Exists()) then
        bomb:GetSprite().Color = Color(0.75,0.75,0.75,1,conv255ToFloat(50,17,67))
        local rags = Isaac.FindByType(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, -1, false, false)
        data.closestrag = REVEL.getClosestInTable(rags, bomb)

        if not data.closestrag then
            data.norag = true
        end
    end

    if not data.norag then
        local add = 0
        if bomb.Variant == BombVariant.BOMB_SUPERTROLL then
            add = 1
        end
        bomb.Velocity = bomb.Velocity*0.9+(data.closestrag.Position-bomb.Position):Resized(0.5 + add)
    end

    if bomb:IsDead() and not data.exploded then
        local radius = 40
        if bomb.Variant == BombVariant.BOMB_SUPERTROLL then
            radius = 70
        end

        if not data.norag and data.closestrag and data.closestrag.Position:Distance(bomb.Position) <= 40 then
            REVEL.BuffEntity(data.closestrag)
        end
        data.exploded = true
    end
end)

-- General callbacks

StageAPI.AddCallback("Revelations", RevCallbacks.POST_BOULDER_IMPACT, 0, function(boulder, npc, isGrid)
    if isGrid or not npc or not REVEL.STAGE.Tomb:IsStage() then return end

    if npc.Type == EntityType.ENTITY_GLUTTONY then
        return tombGluttony_BoulderImpact(boulder, npc, isGrid)
    elseif StageAPI.GetCurrentRoom()
	and StageAPI.GetCurrentRoom().PersistentData.IsSinami
	and REVEL.IsSin(npc) then
        npc:TakeDamage(npc.MaxHitPoints * 0.05, 0, EntityRef(boulder), 0)
        return false
    elseif npc.Type == EntityType.ENTITY_PRIDE then
		return tombPride_BoulderImpact(boulder, npc, isGrid)
    end
end)


-- Sinami music
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    local room = StageAPI.GetCurrentRoom()
    if room and room.PersistentData.IsSinami and room.PersistentData.MusicStatus == 1 then
        REVEL.music:EnableLayer()
        REVEL.music:UpdateVolume()
    end
end)

StageAPI.AddCallback("Revelations", "POST_SELECT_STAGE_MUSIC", 1, function(stage, musicID, roomType, rng)
    local room = StageAPI.GetCurrentRoom()
    local sinamiBeat
    if REVEL.STAGE.Glacier:IsStage() then
        sinamiBeat = revel.data.run.sinamiBeat.glacier
    elseif REVEL.STAGE.Tomb:IsStage() then
        sinamiBeat = revel.data.run.sinamiBeat.tomb
    end
    if sinamiBeat and room and room.PersistentData.IsSinami then
        if room.PersistentData.MusicStatus == 1 then
            return REVEL.SFX.SIN.ALL
        else
            return nil
        end
    end
end)


Isaac.DebugString("Revelations: Loaded Sins for Chapter 2!")
end
REVEL.PcallWorkaroundBreakFunction()