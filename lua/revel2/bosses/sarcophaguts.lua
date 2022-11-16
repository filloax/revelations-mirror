local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local tarColor = Color(1, 1, 1, 1)
tarColor:SetColorize(0.7,0.7,0.75,1)

local SarcBalance = {
    Champions = { Tar = 'Default' },

    Spritesheet = { Tar = 'gfx/bosses/revel2/sarcophaguts/tarcophaguts.png' },
    ToplessSpritesheet = { Default = 'gfx/bosses/revel2/sarcophaguts/sarcophagutstopless.png',
                            Tar     = 'gfx/bosses/revel2/sarcophaguts/tarcophagutstopless.png' },
    HeadSpritesheet = { Default = false, Tar = 'gfx/bosses/revel2/sarcophaguts/tarcophagutshead.png' },
    GutsSpritesheet = { Default = false, Tar = 'gfx/bosses/revel2/sarcophaguts/tarcophagutsguts.png' },

    SarcGutSpritesheet = { Default = false, Tar = "gfx/bosses/revel2/sarcophaguts/tarcgut.png" },

    CreepVariant = { Default = EffectVariant.CREEP_RED, Tar = EffectVariant.CREEP_BLACK },
    ShotColor = { Default = Color(1,1,1,1,conv255ToFloat(0,0,0)), Tar = tarColor },

    -- MaxHp = { Default = 200, Tar = 500 },
    -- OuchHp = 160,
    OuchScaling = {TargetLength = 10, Vulnerability = 0.7},
    BoulderDamagePct = 0.15,

    GutsCap = { Default = 4, Tar = 2 }, -- default is used for sarc guts
    SarcGutCap = 4, -- only applies outside Ouch

    -- Applies to all gut spawns regardless of type or attack
    GutHardCap = {
        DefaultRoom = 4,
        BigRoom = 5,
    },

    NumButtons = { Default = 3, Tar = 2 },
    ButtonsStartPressed = { Default = true, Tar = false },
    ButtonSpeed = 2,
    ButtonClickingEntities = {
        Default = { { EntityType.ENTITY_PLAYER } },
        Tar = { { EntityType.ENTITY_PLAYER }, { EntityType.ENTITY_GUTS } },
    },
    RaiseButtons = {
        Default = function(data, raiseAll)
            for _, button in ipairs(data.Buttons) do
                if raiseAll or not button:GetData().RecentlyPressed then
                    button:GetData().ForcePressed = false
                else
                    button:GetData().ForcePressed = true
                end
            end
        end,
        Tar = function(data, _)
            local buttonsLeft = data.bal.DepressedButtons
            local a, b = table.unpack(data.Buttons)
            local adata, bdata = a:GetData(), b:GetData()

            local function isCovered(buttonData) return
                buttonData.CoverEntity and buttonData.CoverEntity:Exists()
            end

            local pressB = adata.ForcePressed and not isCovered(adata) or isCovered(bdata)

            adata.ForcePressed = not pressB
            bdata.ForcePressed = pressB
        end
    },

    VulnerableAnims = { "Open", "Shoot", "BrimstoneStart", "Brimstone" },

    InvulnerableAttacks = {"Blood Pillar", "Bullet Duat"},
    InvulnerableAttacksBeforeChase = 1,

    PopulateQueue = function(stack, data)
        table.insert(stack, "Chase + Splash")
        for i = 1, data.bal.InvulnerableAttacksBeforeChase do
            table.insert(stack, data.bal.InvulnerableAttacks[math.random(1, #data.bal.InvulnerableAttacks)])
        end
    end,

    StartingBoulderHits = 1,
    IncBoulderHits = 1,

    TrackTargetPositionDelay = 6,
    ActiveBrimstone = { Default = true, Tar = false },
    PillarSpeed = 4,
    PillarSpawnWait = 20,
    PillarSpawnInterval = 100,
    PillarLength = 260,
    PillarProjectileInterval = { Default = false, Tar = 5 },
    PillarProjectilePadding = { Default = false, Tar = 30 },

    DuatAttacks = { "RandomGaps", "SpraySweep" },
    DuatsBeforeChase = 3,
    DuatDelay = 30,

    GapTimer = 100,
    GapWait = 10,
    GapInterval = { Default = 20, Tar = 5 },
    GapSize = { Default = 25, Tar = 40 },
    GapSpeed = { Default = 7.5, Tar = 5 },
    GapOffset = {
        Default = function(npc, data, target)
            return data.GapBaseOffset + data.Timer / data.bal.GapTimer * 30 * data.GapDirection
        end,
        Tar = function(npc, data, target)
            return data.GapBaseOffset + data.Timer / data.bal.GapTimer * 30 * data.GapDirection
        end
    },

    SweepTimer = { Default = 50, Tar = 18 },
    SweepTelegraphTimer = { Default = 12, Tar = 8 },
    SweepSpeed = { Default = 9, Tar = 8 },
    SweepFallAccel = { Default = -0.1, Tar = 0.03 },
    SweepAngleOffset = 10,
    SweepTotalTravel = { Default = 200, Tar = 250 },
    SweepInterpExp = { Default = 5, Tar = 2 },

    ChaseTimer = 80,
    ChaseSpeed = 12,

    OuchMagnetizedEntities = {
        Default = { { REVEL.ENT.SARCGUT.id, REVEL.ENT.SARCGUT.variant } },
        Tar = { { REVEL.ENT.SARCGUT.id, REVEL.ENT.SARCGUT.variant }, { EntityType.ENTITY_GUTS } },
    },

    AttackNames = {
        ["Blood Pillar"] = "Blood Pillar",
        ["Bullet Duat"] = "Bullet Duat",
        ChaseNSplash = "Chase and Splash",
        Ouch = "Ouch!",
        RandomGaps = "Random Gaps",
        SpraySweep = "Spray Sweep"
    },

    -- StatesToLogic defined after the state attack functions
    -- due to how lua scopes work
}
    
local tarEmitter = REVEL.Emitter()
local tarEmitter2 = REVEL.Emitter()

local function GetLerp(startVal, endVal, framePeriod, base)
    return {
        Current = (base or 1) * startVal,
        Start = startVal,
        End = endVal,
        TValue = (endVal / startVal) ^ (1 / framePeriod),
        Period = framePeriod,
        ApplyCount = 0
    }
end

local function ApplyLerp(knockback)
    knockback.Current = knockback.Current * knockback.TValue

    knockback.ApplyCount = knockback.ApplyCount + 1
    knockback.Done = knockback.ApplyCount >= knockback.Period

    return knockback.Current
end

local EntityCache = {}
local function GetCachedEntities(type, variant, subtype)
    --if type == EntityType.ENTITY_PLAYER then return REVEL.players end

    variant = variant or -1
    subtype = subtype or -1
    local key = type .. '.' .. variant .. '.' .. subtype

    local cache = EntityCache[key]
    if not cache then
        cache = { Frame = -1 }
        EntityCache[key] = cache
    end

    local frame = REVEL.game:GetFrameCount()
    if cache.Frame ~= frame or not cache.List then
        cache.List = Isaac.FindByType(type, variant, subtype, false, false)
        cache.Frame = frame
    end

    return cache.List
end

local function GetSetOfEntities(entSets)
    return REVEL.reduce(
        REVEL.map(entSets, function(e)
            return GetCachedEntities(table.unpack(e))
        end),
        function(ents, entList)
            return REVEL.concat(ents, table.unpack(entList))
        end, {})
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for _, cache in pairs(EntityCache) do
        cache.List = nil
    end
end)

local function SpawnSarcProjectile(data, pos, vel, spawner)
    local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, pos, vel, spawner)
    p.SpawnerEntity = spawner

    p:GetSprite().Color = data.bal.ShotColor

    return p:ToProjectile()
end

local function SpawnSarcBossProjectiles(data, num, target, trajectory, spawner, params, onEach)
    params = params or ProjectileParams()
    onEach = onEach or function(p) end
    params.Color = data.bal.ShotColor

    for i = 1, num do
        local p = spawner:FireBossProjectiles(1, target, trajectory, params)
        p.SpawnerEntity = spawner
        onEach(p)
    end
end

local function IsAtGutCap(data)
    local count = REVEL.ENT.SARCGUT:countInRoom() + Isaac.CountEntities(nil, EntityType.ENTITY_GUTS, 0, 0)
    local cap = data.bal.GutHardCap.DefaultRoom
    local shape = REVEL.room:GetRoomShape()

    if shape == RoomShape.ROOMSHAPE_1x2
    or shape == RoomShape.ROOMSHAPE_2x1
    or shape == RoomShape.ROOMSHAPE_2x2
    or shape == RoomShape.ROOMSHAPE_LBL
    or shape == RoomShape.ROOMSHAPE_LTL
    or shape == RoomShape.ROOMSHAPE_LBR
    or shape == RoomShape.ROOMSHAPE_LTR
    then
        cap = data.bal.GutHardCap.BigRoom
    end

    return count >= cap
end

local function MakeSarcGut(data, ent)
    if data.bal.SarcGutSpritesheet then
        local sprite = ent:GetSprite()
        sprite:ReplaceSpritesheet(0, data.bal.SarcGutSpritesheet)
        sprite:LoadGraphics()
    end
end

local function SpawnSarcGut(data, pos, vel, spawner)
    if IsAtGutCap(data) then
        return nil
    end

    local sarcgut = REVEL.ENT.SARCGUT:spawn(pos, vel, spawner)
    MakeSarcGut(data, sarcgut)

    sarcgut:GetData().CreepVariant = data.bal.CreepVariant

    return sarcgut
end

local function MakeTarGuts(data, ent)
    local sprite = ent:GetSprite()
    sprite:ReplaceSpritesheet(0, "gfx/bosses/revel2/sarcophaguts/targut.png")
    sprite:LoadGraphics()

    ent:GetData().IsTarGut = true
end

local function SpawnTarGuts(data, pos, vel, spawner)
    if IsAtGutCap(data) then
        return nil
    end

    local gut = Isaac.Spawn(EntityType.ENTITY_GUTS, 0, 0, pos, vel, spawner)
    MakeTarGuts(data, gut)

    gut.MaxHitPoints = 10
    gut.HitPoints = gut.MaxHitPoints

    return gut
end

local function SpawnTarBoy(data, pos, vel, spawner)
    local tarboy = Isaac.Spawn(EntityType.ENTITY_TARBOY, 0, 0, pos, vel, spawner)

    tarboy.MaxHitPoints = 15
    tarboy.HitPoints = tarboy.MaxHitPoints

    return tarboy
end

local function LowerButtons(data)
    for _, button in ipairs(data.Buttons) do
        button:GetData().ForcePressed = true
    end
end

local function ResetButtonPressedHistory(data)
    for _, button in ipairs(data.Buttons) do
        button:GetData().RecentlyPressed = nil
    end
end

local function DuatWait(npc, data, sprite, target)
    if not sprite:IsPlaying("Idle") then
        sprite:Play("Idle")
    end

    data.Timer = data.Timer + 1
    if data.Timer >= data.bal.DuatDelay then
        data.State = "" -- begin next attack
    end
end

local function BulletDuat(npc, data, sprite, target, attackId, timer)
    if data.State == "Bullet Duat" then
        if not (data.ReachedPosition or data.IsAttacking) then
            data.IsAttacking = true
            data.Destination = Vector(REVEL.room:GetCenterPos().X, REVEL.room:GetTopLeftPos().Y + 40)
        end

        -- once position is reached, select attacks and add them to the front of the queue,
        -- then force a dequeue
        -- follow the logic for that attack, then dequeue etc
        -- only base BulletDuat has the pathing and attack queueing logic
        if data.ReachedPosition then
            for i = 1, data.bal.DuatsBeforeChase do
                table.insert(data.AttackQueue, data.bal.DuatAttacks[math.random(1,#data.bal.DuatAttacks)])
                table.insert(data.AttackQueue, "DuatWait")
            end
            table.remove(data.AttackQueue)
            data.State = ""
        end

        return
    end

    if not data.IsAttacking then
        local tellAnim = "Tell" .. attackId
        if not sprite:IsPlaying("Shoot") then
            sprite:Play(tellAnim)
            REVEL.AnnounceAttack(data.bal.AttackNames[data.State])
        end

        if sprite:IsFinished(tellAnim) then
            sprite:Play("Open", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.HATCH_OPEN, 0.8, 0, false, 1)
            data.IsAttacking = true
        end
    end

    if sprite:IsFinished("Open") then -- spawning sarcguts and creep on opening
        data.Timer = 0
        sprite:Play("Shoot", true)

        if data.IsChampion then
            local guts = GetCachedEntities(EntityType.ENTITY_GUTS)
            local tarboy = GetCachedEntities(EntityType.ENTITY_TARBOY)
            if #guts < data.bal.GutsCap then
                local dirs = {Vector(0,5), Vector(5,0), Vector(-5,0)}
                SpawnTarGuts(data, npc.Position + Vector(0,40), dirs[math.random(#dirs)], npc)
            elseif #tarboy < data.bal.GutsCap then
                SpawnTarBoy(data, npc.Position + Vector(0,40), Vector.Zero, npc)
            end
        else
            local numSarcGuts = #GetCachedEntities(REVEL.ENT.SARCGUT.id, REVEL.ENT.SARCGUT.variant)
            local spawnGuts = math.random(2,3)
            spawnGuts = math.min(numSarcGuts + spawnGuts, data.bal.SarcGutCap) - numSarcGuts
            for i = 1, spawnGuts do
                local angle = 30 + (180-(60*(spawnGuts-1)))*(i-1)
                SpawnSarcGut(data, npc.Position+Vector.FromAngle(angle)*50, Vector.Zero, npc)
            end
        end

        local creep = REVEL.SpawnCreep(data.bal.CreepVariant, 0, npc.Position, npc, false):ToEffect()
        REVEL.UpdateCreepSize(creep, creep.Size * 3, true)
        creep.Timeout = timer + 90
    end

    if sprite:IsPlaying("Shoot") then
        data.Timer = data.Timer + 1

        if data.Timer >= timer or
            REVEL.some(REVEL.players, function(player)
                return player.Position:DistanceSquared(npc.Position) <= 90 ^ 2 and REVEL.player.Position.Y < npc.Position.Y
            end) then
            sprite:Play("Close", true)
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.HATCH_CLOSE, 0.8, 0, false, 1)
        end
    end

    if sprite:IsFinished("Close") then
        data.State = ""
    end
end

local function RandomGaps(npc, data, sprite, target)
    BulletDuat(npc, data, sprite, target, 1, data.bal.GapTimer)

    if not data.IsAttacking then
        if data.IsChampion then
            data.GapBaseOffset = (target.Position - npc.Position):GetAngleDegrees() - 90
            data.GapDirection = sign(target.Position.X - REVEL.room:GetCenterPos().X)
        else
            data.GapBaseOffset = 0
            data.GapDirection = sign(math.random() - 0.5)
        end
    end

    if sprite:IsPlaying("Shoot") then
        if (data.Timer + data.bal.GapWait) % data.bal.GapInterval == 0 then
            local offset = data.bal.GapOffset(npc, data, target)
            local gapsize = data.bal.GapSize
            local amountshots = 180 / gapsize + 1
            for i = 1, amountshots do
                local p = SpawnSarcProjectile(data, npc.Position, Vector.FromAngle((i - 1) * gapsize + offset)*data.bal.GapSpeed, npc)
                p.FallingAccel = -0.1
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 0.6, 0, false, 1)
            end
        end
    end
end

local function SpraySweep(npc, data, sprite, target)
    BulletDuat(npc, data, sprite, target, 2, data.bal.SweepTimer + data.bal.SweepTelegraphTimer)

    if not sprite:IsPlaying("Shoot") then
        if data.SpraySweepSide == nil then
            if math.random(0, 1) == 0 then
                data.SpraySweepSide = true
            end
        end

        data.SpraySweepSide = not data.SpraySweepSide
        if data.SpraySweepSide then
            data.ProjectileAngle = -180 + data.bal.SweepAngleOffset
            data.TotalTravel = -data.bal.SweepTotalTravel
        else
            data.ProjectileAngle = -data.bal.SweepAngleOffset
            data.TotalTravel = data.bal.SweepTotalTravel
        end
    end

    if sprite:IsPlaying("Shoot") then
        local addAngle = 0
        local timer = data.Timer - data.bal.SweepTelegraphTimer
        if timer >= 0 then
            local t = timer / data.bal.SweepTimer
            addAngle = REVEL.Lerp(0, data.TotalTravel, t ^ data.bal.SweepInterpExp)
        end

        local p = SpawnSarcProjectile(data, npc.Position, Vector.FromAngle(data.ProjectileAngle + addAngle) * data.bal.SweepSpeed, npc)
        p.FallingAccel = data.bal.SweepFallAccel or p.FallingAccel
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 0.6, 0, false, 1)
    end
end

local function BloodPillarMove(npc, data, sprite, target)
    if not data.IsAttacking then
        data.IsAttacking = true

        local centerPos = REVEL.room:GetCenterPos()
        data.Destination = Vector(80, centerPos.Y)
        if npc.Position.X < centerPos.X then
            data.Destination.X = REVEL.room:GetTopLeftPos().X + data.Destination.X
        else
            data.Destination.X = REVEL.room:GetBottomRightPos().X - data.Destination.X
        end

        table.insert(data.AttackQueue, "BloodPillarAttack")
    end

    if data.ReachedPosition then -- if done travelling
        sprite:Play("FallDown", true)
        data.State = ""
    end
end

local function BloodPillar(npc, data, sprite, target)
    if sprite:IsEventTriggered("falldown") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.8, 0, false, 1)
    end

    if sprite:IsFinished("FallDown") then
        sprite:Play("BrimstoneStart", true)
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.HATCH_OPEN, 0.8, 0, false, 1)
    end

    if sprite:IsFinished("BrimstoneStart") then
        data.Timer = 0
        sprite:Play("Brimstone", true)
		data.AttackPosition = npc.Position
		data.AttackVelocity = npc.Position

		if not data.IsChampion then
			data.AttackBrimstone = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DEVIL, 0, npc.Position, Vector.Zero, npc):ToEffect()
			data.AttackBrimstone:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

			local absprite = data.AttackBrimstone:GetSprite()
			absprite:Load("gfx/1000.096_hushlaser.anm2", true)
			absprite:Play("Start", true)
			data.AttackBrimstone.Visible = false

			if data.bal.ActiveBrimstone then
				absprite.Color = Color(0.6,0,0,0.8,conv255ToFloat(150,0,0))
				data.AttackBrimstone.Visible = true

				data.SpewBrimstone = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HUSH_LASER_UP, 0, npc.Position + Vector(0,3), Vector.Zero, npc):ToEffect()
				data.SpewBrimstone:GetSprite().Offset = Vector(0,-30)
				data.SpewBrimstone:GetSprite().Color = absprite.Color

				REVEL.sfx:NpcPlay(npc, REVEL.SFX.BLOOD_LASER_START, 0.45, 0, false, 1)
				REVEL.sfx:NpcPlay(npc, REVEL.SFX.BLOOD_LASER_LOOP, 0.45, 0, true, 1)
			end
		end
    end

    if data.AttackBrimstone then -- Brimstone follwing player ai
        local absprite = data.AttackBrimstone:GetSprite()
        if absprite:IsFinished("Start") then
            absprite:Play("Loop", true)
        end
        if absprite:IsPlaying("Loop") then
            local targetPos = data.TargetPositions[data.bal.TrackTargetPositionDelay]
            data.AttackBrimstone.Velocity = (targetPos - data.AttackBrimstone.Position):Resized(data.bal.PillarSpeed)
        end

        if data.AttackBrimstone.FrameCount % 5 == 0 and data.AttackBrimstone.Visible then
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, data.bal.CreepVariant, 0, data.AttackBrimstone.Position, Vector.Zero, npc):ToEffect()
            creep.Timeout = 45
        end

        if data.AttackBrimstone.Visible then
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(data.AttackBrimstone.Position) < 15 ^ 2 then
                    player:TakeDamage(1, 0, EntityRef(npc), 0)
                end
            end
        end
		
		data.AttackPosition = data.AttackBrimstone.Position
		data.AttackVelocity = data.AttackBrimstone.Velocity

        if absprite:IsFinished("End") then
            data.AttackBrimstone:Remove()
            data.AttackBrimstone = nil
        end
		
    elseif data.IsChampion and data.AttackPosition then
		local targetPos = data.TargetPositions[data.bal.TrackTargetPositionDelay]
		data.AttackVelocity = (targetPos - data.AttackPosition):Resized(data.bal.PillarSpeed)
		data.AttackPosition = data.AttackPosition + data.AttackVelocity
	end

    if sprite:IsPlaying("Brimstone") then
        data.Timer = data.Timer + 1

        if (data.Timer + data.bal.PillarSpawnWait) % data.bal.PillarSpawnInterval == 0 then
            data.FlyingSarcgut = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DEVIL, 0, npc.Position+Vector(0,6), Vector.Zero, npc)
            data.FlyingSarcgut:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 5, npc.Position-Vector(0,40), Vector.Zero, npc):ToEffect()
            eff.SpriteScale = Vector(0.5,0.5)

            if data.IsChampion then
                eff:SetColor(Color(0,0,0,1), -1, 1, false, false)
            end

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 1, 0, false, 1)

            local fgsprite = data.FlyingSarcgut:GetSprite()
            fgsprite:Load("gfx/bosses/revel2/sarcophaguts/sarcgut.anm2", true)

            local targuts = GetCachedEntities(EntityType.ENTITY_GUTS)
            local changeFunc = (data.IsChampion and #targuts < data.bal.GutsCap) and MakeTarGuts or MakeSarcGut
            changeFunc(data, data.FlyingSarcgut)

            fgsprite:Play("FlyingUp", true)
            fgsprite.Offset = Vector(0,-20)
            data.FlyingSarcgut.DepthOffset = 9999
        end

        if data.Timer == data.bal.PillarLength then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.HATCH_CLOSE, 0.8, 0, false, 1)
            sprite:Play("BrimstoneEnd", true)
			if data.AttackBrimstone then
				data.AttackBrimstone:GetSprite():Play("End", true)
			end
            if data.SpewBrimstone then
                data.SpewBrimstone:Remove()
                data.SpewBrimstone = nil
                REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.BLOOD_LASER_STOP, 0.45, 0, false, 1)
            end
        end

        if data.IsChampion then
            tarEmitter:EmitParticlesPerSec(REVEL.TarParticle1, REVEL.TarPartSystem, Vec3(npc.Position, -28), Vec3(0,0,-5), 15, 0.05, 18)
            tarEmitter2:EmitParticlesPerSec(REVEL.TarParticle2, REVEL.TarPartSystem, Vec3(npc.Position, -28), Vec3(0,0,-8), 20, 0.05, 40)

            if data.Timer % data.bal.PillarProjectileInterval == 0 then
                if data.Timer >= data.bal.PillarProjectilePadding then
                    local proj = SpawnSarcProjectile(data, npc.Position+Vector((math.random()-0.5)*5,(math.random()-0.5)*5+12), Vector(math.random()-0.5,math.random()-0.5), npc)
                    proj:GetData().UpwardsTear = true
                    proj:GetSprite().Offset = Vector(0,-26)
                    proj.FallingSpeed = -5
                    proj.FallingAccel = -4
                end

                if data.Timer <= data.bal.PillarLength - data.bal.PillarProjectilePadding then
                    local proj = SpawnSarcProjectile(data, data.AttackPosition+Vector((math.random()-0.5)*5,(math.random()-0.5)*5), Vector(math.random()-0.5,math.random()-0.5), npc)
                    proj:GetData().DownwardsTear = true
                    proj.Height = -295
                    proj.FallingSpeed = 5
                    proj.FallingAccel = 4
                end
            end
        end

        if data.FlyingSarcgut then -- sarcgut that gets blasted up by the brimstone laser
            local fsprite = data.FlyingSarcgut:GetSprite()
            if fsprite:IsFinished("FlyingUp") then
                fsprite:Play("FlyingDown", true)
                fsprite.Offset = Vector(0,-6)
            end
            if fsprite:IsPlaying("FlyingDown") then

                if not fsprite:WasEventTriggered("Land") then
                    data.FlyingSarcgut.Position = data.AttackPosition-Vector(0,6)
                    data.FlyingSarcgut.Velocity = data.AttackVelocity
                elseif fsprite:IsEventTriggered("Land") then
                    data.FlyingSarcgut.Velocity = Vector.Zero
                    fsprite.Offset = Vector.Zero

                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1.4, 0, false, 1)
                    local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 3, data.AttackPosition, Vector.Zero, npc):ToEffect()
                    eff.SpriteScale = Vector(0.8,0.8)

                    if data.IsChampion then
                        eff:SetColor(Color(0,0,0,1), -1, 1, false, false)
                    end

                    local creep = REVEL.SpawnCreep(data.bal.CreepVariant, 0, data.AttackPosition, npc, false):ToEffect()
                    REVEL.UpdateCreepSize(creep, creep.Size * 2, true)
                    creep.Timeout = 45

                    for i = 1, 4 do
                        SpawnSarcProjectile(data, data.AttackPosition, Vector.FromAngle(i * 90) * 10, npc)
                    end
                end
            elseif fsprite:IsFinished("FlyingDown") then
                local spawnFunc = data.FlyingSarcgut:GetData().IsTarGut and SpawnTarGuts or SpawnSarcGut
                local spawn = spawnFunc(data, data.FlyingSarcgut.Position, Vector.Zero, npc)
                if spawn then
                    spawn:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                end

                data.FlyingSarcgut:Remove()
                data.FlyingSarcgut = nil
            end
        end
    end

    if sprite:IsFinished("BrimstoneEnd") then
        sprite:Play("Recover", true)
    end

    if sprite:IsFinished("Recover") then
        data.State = ""
    end
end

local function ChaseNSplash(npc, data, sprite, target)
    data.Timer = data.Timer + 1

    if data.BoulderHits >= data.MaxBoulderHits then
        data.BoulderHits = 0
        data.MaxBoulderHits = data.MaxBoulderHits + data.bal.IncBoulderHits
        sprite:Play("Idle", true)
        data.State = ""
        return
    end

    if sprite:IsPlaying("HopLoop") and not data.KnockBack then
        data.Destination = target.Position

        if sprite:IsEventTriggered("HopAirEnd") then -- creep on landing
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, data.bal.CreepVariant, 0, npc.Position, Vector.Zero, npc):ToEffect()
            creep.Timeout = 45
        end

        if data.Timer >= data.bal.ChaseTimer then
            sprite:Play("BloodRelease", true)
            data.Destination = nil
        end
    elseif sprite:IsPlaying("BloodRelease") then
        if sprite:IsEventTriggered("bloodrelease") then
            local creep = REVEL.SpawnCreep(data.bal.CreepVariant, 0, npc.Position, npc, false):ToEffect()
            REVEL.UpdateCreepSize(creep, creep.Size * 3, true)
            creep.Timeout = 50
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.6, 0, false, 1)
        end
    elseif sprite:IsFinished("BloodRelease") then
        sprite:Play("Jump", true)
    elseif sprite:IsPlaying("Jump") then
        if sprite:IsEventTriggered("HopAirEnd") then
            SpawnSarcBossProjectiles(data, 20, Vector.Zero, 10, npc)
            SpawnSarcBossProjectiles(data, 10, target.Position, 0, npc)

            local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 3, npc.Position, Vector.Zero, npc):ToEffect()

            data.MoveButtons = data.IsChampion -- tarc doesn't stop his buttons in chase+splash
            if not data.MoveButtons then
                ResetButtonPressedHistory(data)
                data.bal.RaiseButtons(data, false)
                --for _, button in data.Buttons do
                --    button:GetData().ForcePressed = false
                --end
            else
                eff:SetColor(Color(0,0,0,1), -1, 1, false, false)
            end
        end
    else
        data.Destination = target.Position
        data.Timer = 0
    end
end

local function HeadRelease(npc, data, sprite, target)
    if not data.HasSpawnedSarcophagutsHead then
        data.HasSpawnedSarcophagutsHead = true
        sprite:Play("HeadRelease", true)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.8, 0, false, 1)
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.SARCOPHAGUTS_HEAD_LAUNCH, 1.2, 0, false, 1)
    end

    if sprite:IsEventTriggered("releasehead") then
        local head = REVEL.ENT.SARCOPHAGUTS_HEAD:spawn(npc.Position, Vector.Zero, npc)
        local hsprite = head:GetSprite()
        hsprite:Play("Midair", true)
        hsprite.Offset = Vector(0,-50)
        if data.bal.HeadSpritesheet then
            hsprite:ReplaceSpritesheet(0, data.bal.HeadSpritesheet)
            hsprite:LoadGraphics()
        end
        head:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        head:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK |
                            EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK |
                            EntityFlag.FLAG_NO_STATUS_EFFECTS |
                            EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
        head:GetData().Sarc = npc
        head.Mass = 0
    end

    if sprite:IsFinished("HeadRelease") then
        sprite:ReplaceSpritesheet(0, data.bal.ToplessSpritesheet)
        sprite:LoadGraphics()
        sprite:Play("Recover", true)
    end

    if sprite:IsFinished("Recover") then
        data.BoulderHits = 0
        data.State = ""
    end
end

local function Break(npc, data, sprite, target)
    if not (sprite:IsPlaying("Break") or sprite:IsFinished("Break")) then
        sprite:Play("Break", true)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 1, 0, false, 1)
    end
    data.MoveButtons = true
    if data.AttackBrimstone then
        data.AttackBrimstone:Remove()
        data.AttackBrimstone = nil
    end
    if data.SpewBrimstone then
        data.SpewBrimstone:Remove()
        data.SpewBrimstone = nil
        REVEL.sfx:Stop(REVEL.SFX.BLOOD_LASER_LOOP)
        REVEL.sfx:Play(REVEL.SFX.BLOOD_LASER_STOP, 0.6, 0, false, 1)
    end
    if sprite:IsFinished("Break") then
        table.insert(data.AttackQueue, "Ouch")
        data.State = ""
    end
end

local function Ouch(npc, data, sprite, target)
    if not data.IsAttacking then
        -- npc.MaxHitPoints = data.bal.OuchHp
        REVEL.SetScaledBossHP(npc, data.bal.OuchScaling.TargetLength, data.bal.OuchScaling.Vulnerability, nil, nil, nil, true)
        npc.HitPoints = npc.MaxHitPoints

        REVEL.AnnounceAttack(data.bal.AttackNames.Ouch)
        sprite:Load("gfx/bosses/revel2/sarcophaguts/sarcophagutsgut.anm2", true)
        if data.bal.GutsSpritesheet then
            sprite:ReplaceSpritesheet(0, data.bal.GutsSpritesheet)
            sprite:LoadGraphics()
        end

        local eff = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()

        if not data.IsChampion then
            data.bal.RaiseButtons(data, true)
        else
            eff:SetColor(Color(0,0,0,1), -1, 1, false, false)
        end

        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 1, 0, false, 1)

        sprite:Play("GutSpawn", true)

        data.IsAttacking = true
    end

    npc.CollisionDamage = 1
    npc.Velocity = (target.Position - npc.Position):Resized(2)

    if npc.FrameCount % 10 == 0 then
        local creep = REVEL.SpawnCreep(data.bal.CreepVariant, 0, npc.Position + RandomVector() * math.random(40), npc, false):ToEffect()
        REVEL.UpdateCreepSize(creep, creep.Size * math.ceil(math.random(3)), true)
        creep.Timeout = 10
    end

    if sprite:IsFinished("GutSpawn") then
        sprite:Play("GutWalk2", true)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 0.6, 0, false, 1)
    end

    local guts = GetSetOfEntities(data.bal.OuchMagnetizedEntities)

    local pullstrength
    local frameAmt
    if sprite:IsPlaying("GutWalk") then --Push
        frameAmt = 40
        pullstrength = (sprite:GetFrame()-frameAmt)*(frameAmt*0.01)
        pullstrength = pullstrength*0.25
    elseif sprite:IsPlaying("GutWalk2") then --Suck
        frameAmt = 60
        pullstrength = sprite:GetFrame()*(frameAmt*0.01)
        pullstrength = math.min(8,pullstrength*0.5)
    else
        pullstrength = 0
    end

    if pullstrength ~= 0 then
        for _,e in ipairs(guts) do
            if e.Type ~= EntityType.ENTITY_GUTS then
                if e.Position:Distance(npc.Position) < 35 and pullstrength > 0 then
                    e.Velocity = npc.Velocity
                else
                    e.Position = e.Position+(npc.Position-e.Position):Resized(pullstrength)
                end
            end
        end
    end

    if #guts < data.bal.GutsCap and math.random() * #guts <= 0.04 then
        local targuts = GetCachedEntities(EntityType.ENTITY_GUTS)
        local spawnFunc = (data.IsChampion and #targuts < data.bal.GutsCap) and SpawnTarGuts or SpawnSarcGut
        spawnFunc(data, npc.Position + RandomVector()*15, Vector.Zero, npc)
    end

    if sprite:IsFinished("GutWalk") then
        sprite:Play("GutWalk2", true)
    end
    if sprite:IsFinished("GutWalk2") then
        sprite:Play("GutWalk")
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 0.6, 0, false, 1)
    end

    if sprite:IsEventTriggered("gutland") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 1, 0, false, 1)
    end
end

-- Important note: this is used lower below, and was originally used in two 
-- places of sarc's AI, then removed in an overhaul but left in one of the 2 
-- places: likely implies bad things other than this, for now will just readd it
local function MoveSarcophagutsTrackEntity(ent, sarcdata)
    local _, edges = REVEL.GetCornerPositions()
    local data = ent:GetData()
    local nextEdgeIndex = (data.CurrentEdgeIndex % #edges) + 1
    local nextEdge = edges[nextEdgeIndex]

    ent.Velocity = (nextEdge.Position - ent.Position):Resized(sarcdata.bal.ButtonSpeed)
    if nextEdge.Position:DistanceSquared(ent.Position) < sarcdata.bal.ButtonSpeed ^ 2 then
        data.CurrentEdgeIndex = nextEdgeIndex
    end
end

-- Define here due to how lua scopes work
SarcBalance.StatesToLogic = {
    ["Blood Pillar"] = BloodPillarMove,
    ["BloodPillarAttack"] = BloodPillar,
    ["Bullet Duat"] = BulletDuat,
    ["DuatWait"] = DuatWait,
    ["RandomGaps"] = RandomGaps,
    ["SpraySweep"] = SpraySweep,
    ["Chase + Splash"] = ChaseNSplash,
    ["Break"] = Break,
    ["HeadRelease"] = HeadRelease,
    ["Ouch"] = Ouch,
}

do -- debug track rendering
    local function SarcophagutsTrackRenderingInstructions()
        local instructions = {}
        local corners, _, lPosition = REVEL.GetCornerPositions()
        local cornerCopy = {}
        for _, corner in ipairs(corners) do
            cornerCopy[#cornerCopy + 1] = {
                Position = corner.Position,
                Index = corner.Index,
                Rotation = corner.Rotation + 45
            }
        end

        if lPosition then
            cornerCopy[#cornerCopy + 1] = {
                Position = lPosition.Position,
                Index = lPosition.Index,
                Rotation = lPosition.Rotation + 45
            }
        end

        local width = REVEL.room:GetGridWidth()
        for _, corner in ipairs(cornerCopy) do
            local cX, cY = REVEL.GridToVector(corner.Index)
            for _, corner2 in ipairs(cornerCopy) do
                if corner2.Index ~= corner.Index then
                    local c2X, c2Y = REVEL.GridToVector(corner2.Index)
                    local isValidLink
                    if cX == c2X and not corner.HasX and not corner2.HasX then
                        corner.HasX = true
                        corner2.HasX = true
                        isValidLink = true
                    elseif cY == c2Y and not corner.HasY and not corner2.HasY then
                        corner.HasY = true
                        corner2.HasY = true
                        isValidLink = true
                    end

                    if isValidLink then
                        local diff = (corner2.Position - corner.Position):Resized(12)
                        instructions[#instructions + 1] = {
                            Render = "Line",
                            Position = corner.Position + diff,
                            EndPosition = corner2.Position - diff
                        }
                    end
                end
            end

            instructions[#instructions + 1] = {
                Render = "Corner",
                Position = corner.Position,
                Rotation = corner.Rotation
            }
        end

        return instructions
    end

    local TrackSprite = REVEL.LazyLoadRoomSprite {
        ID = "sarc_TrackSprite",
        Anm2 = "gfx/bosses/revel2/sarcophaguts/buttontrack.anm2",
        Animation = "Corner",
    }

    local function SarcophagutsTrackRender(instructions, renderOffset)
        for _, instruction in ipairs(instructions) do
            if instruction.Render == "Corner" then
                TrackSprite:SetFrame("Corner", 0)
                TrackSprite.Rotation = instruction.Rotation
                TrackSprite:Render(Isaac.WorldToScreen(instruction.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            else
                TrackSprite:SetFrame("Line", 0)
                REVEL.DrawRotatedTilingSprite(
                    TrackSprite, 
                    Isaac.WorldToScreen(instruction.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), 
                    Isaac.WorldToScreen(instruction.EndPosition) + renderOffset - REVEL.room:GetRenderScrollOffset(), 
                    258
                )
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff, renderOffset)
        local data = eff:GetData()
        if data.SarcophagutsTrackInstructions and REVEL.IsRenderPassNormal() then
            SarcophagutsTrackRender(data.SarcophagutsTrackInstructions, renderOffset)
        end
    end, StageAPI.E.FloorEffect.V)
end

-- buttons travel in a direction, and its boulder direction is that rotated 90deg clockwise
-- the button travels in a direction until it hits a solid grid, then it rotates 90deg clockwise
-- buttons remain unpressed unless force pressed, in which case they do nothing
-- buttons can be pressed by some subset of entities configurable in the balance table
-- if a button is unpressed and one of these entities is on top of it, it becomes pressed,
-- which triggers its effect. The button will not unpress until there are no boulders in the room.
-- force pressed buttons will not rise until un-force pressed
local function UpdateButton(button, clickers, sarcdata, lowerButtons)
    local data = button:GetData()

    local nextIndex = REVEL.room:GetGridIndex(button.Position + data.Direction * 20)
    if REVEL.room:GetGridCollision(nextIndex) ~= GridCollisionClass.COLLISION_NONE then
        data.Direction = data.BoulderDir
        data.BoulderDir = data.BoulderDir:Rotated(90)
    end

    local pressed = data.ForcePressed or lowerButtons
    if data.CoverEntity and data.CoverEntity:Exists() then
        data.CoverEntity.Position = button.Position
        pressed = true
    end
    if not pressed then
        pressed = REVEL.some(clickers, function(ent)
            return ent.Position:DistanceSquared(button.Position) <= (20 ^ 2)
        end)

        if not data.justRaised then
            button:SetColor(Color(1, 1, 1, 1, 0.6, 0.6, 0.6), 20, 1, true, false)
            Isaac.Spawn(1000, EffectVariant.POOF01, 2, button.Position, Vector.Zero, button):ToEffect()
            if not REVEL.sfx:IsPlaying(SoundEffect.SOUND_SUMMONSOUND) then
                REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.6, 0, false, 1)
            end
            data.justRaised = true
        end
    end

    local clicked = false
    if pressed ~= data.WasPressed then
        button:GetSprite():SetFrame("Boss", pressed and 1 or 0)
        data.WasPressed = pressed

        clicked = not (lowerButtons or data.ForcePressed) and pressed
        if clicked then
            local boulderPos = REVEL.room:GetClampedPosition(button.Position + data.BoulderDir * 10000, 0)
            REVEL.SpawnSandBoulder(boulderPos, data.BoulderDir * -10)
            data.RecentlyPressed = true
            data.justRaised = false
        end
    end

    button.Velocity = Vector.Zero
    if sarcdata.MoveButtons then
        button.Position = button.Position + data.Direction * sarcdata.bal.ButtonSpeed
    else
        button.Position = button.Position + data.Direction * (sarcdata.bal.ButtonSpeed*0.5)
    end

    return clicked
end

local function ProcessStates(npc, data, sprite, target)
    repeat
        if data.State == "" then
            if #data.AttackQueue == 0 then
                data.bal.PopulateQueue(data.AttackQueue, data)
            end
            data.State = table.remove(data.AttackQueue)
            data.ReachedPosition = false
            data.IsAttacking = nil
            data.Destination = nil
            data.AttackDestination = nil
            data.Timer = 0
        end

        if data.State then
            --REVEL.DebugLog(data.State)
            data.bal.StatesToLogic[data.State](npc, data, sprite, target)
        end
    until data.State ~= ""
end

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
    if npc.Variant ~= REVEL.ENT.SARCOPHAGUTS.variant then return end

    npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end, REVEL.ENT.SARCOPHAGUTS.id)

-- Current Bugs
-- Buttons don't start moving again after being pressed
-- Buttons are unpressed immediately after all boulders are gone

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.SARCOPHAGUTS.variant then
        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
		
		if npc:HasMortalDamage() then
			return
		end

        REVEL.ApplyKnockbackImmunity(npc)

        if not data.State then
            --[[
            local buttontrack = StageAPI.SpawnFloorEffect(REVEL.room:GetTopLeftPos(), Vector.Zero)
            buttontrack:GetData().SarcophagutsTrackInstructions = SarcophagutsTrackRenderingInstructions()]]

            data.IsChampion = REVEL.IsChampion(npc)
            if data.IsChampion then
                data.bal = REVEL.GetBossBalance(SarcBalance, 'Tar')
                sprite:ReplaceSpritesheet(0, data.bal.Spritesheet)
                sprite:LoadGraphics()
            else
                data.bal = REVEL.GetBossBalance(SarcBalance, 'Default')
            end

            local _, edges = REVEL.GetCornerPositions()
            local centerPos = REVEL.room:GetCenterPos()
            local hdims = (REVEL.room:GetBottomRightPos() - REVEL.room:GetTopLeftPos()) * 0.5

            local buttonInc = math.floor(#edges / data.bal.NumButtons)
            local currentEdgeIndex = math.random(1, buttonInc)

            data.Buttons = {}
            for i = 1, data.bal.NumButtons do
                local edge = edges[currentEdgeIndex]

                local button = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LADDER, 0, edge.Position, Vector.Zero, npc)
                local buttonData = button:GetData()

                local offset = centerPos - edge.Position
                offset.X = offset.X / hdims.X
                offset.Y = offset.Y / hdims.Y
                buttonData.BoulderDir = REVEL.GetCardinal(offset:Normalized())
                buttonData.Direction = buttonData.BoulderDir:Rotated(-90)
                buttonData.WasPressed = true

                local bSprite = button:GetSprite()
                bSprite:Load("gfx/grid/revel2/traps/traptiles.anm2", true)
                bSprite:SetFrame("Boss", 1)

                table.insert(data.Buttons, button)
                currentEdgeIndex = currentEdgeIndex + buttonInc
            end

            if data.bal.ButtonsStartPressed then
                LowerButtons(data)
            else
                data.bal.RaiseButtons(data, true)
            end

            data.MoveButtons = true

            data.TargetPositions = {}

            data.AttackQueue = {}
            data.State = ""

            data.BoulderHits = 0
            data.MaxBoulderHits = data.bal.StartingBoulderHits

            -- npc.MaxHitPoints = data.bal.MaxHp
            REVEL.SetScaledBossHP(npc, nil, data.bal.BaseVulnerability)

            npc.HitPoints = npc.MaxHitPoints
        end

        table.insert(data.TargetPositions, 1, target.Position)
        data.TargetPositions[data.bal.TrackTargetPositionDelay + 1] = nil

        -- if no boulders in the room, raise some number of random buttons
        local boulders = REVEL.ENT.SAND_BOULDER:getInRoom()
        if #boulders > 0 then
            if data.IsChampion then
                local creeps = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, -1, false, false)
                for _, boulder in ipairs(boulders) do
                    local nearCreep = REVEL.some(creeps, function(creep)
                        return boulder.Position:DistanceSquared(creep.Position) <= creep.Size ^ 2
                    end)

                    if nearCreep then
                        SpawnSarcBossProjectiles(data, 1, Vector.Zero, 10, npc, nil, function(proj)
                            proj.Position = boulder.Position
                        end)
                    end
                end
            end
        end

        local buttonClickers = GetSetOfEntities(data.bal.ButtonClickingEntities)

        local buttonsPressed = #boulders > 0

        local someButtonClicked = false
        if data.Buttons then
            for _, button in ipairs(data.Buttons) do
                someButtonClicked = UpdateButton(button, buttonClickers, data, buttonsPressed) or someButtonClicked
            end
        end

        if someButtonClicked then
            data.MoveButtons = true
            data.bal.RaiseButtons(data, data.State == "Ouch")
        end

        if data.State ~= "Ouch" then -- bouncing tears off
            local invuln = not REVEL.some(data.bal.VulnerableAnims, function(anim) return sprite:IsPlaying(anim) end)
            for _,t in ipairs(REVEL.roomTears) do
                if invuln then
                    if (t.Position + t.Velocity):DistanceSquared(npc.Position) <= 30 ^ 2 
                    and not t:HasTearFlags(TearFlags.TEAR_EXPLOSIVE) then
                        t.Velocity = (t.Position-npc.Position):Resized(t.Velocity:Length())
                    end
                end
            end
        end

        npc.Velocity = Vector.Zero

        if data.KnockBack then
            npc.Velocity = ApplyLerp(data.KnockBack)
            if data.KnockBack.Done then data.KnockBack = nil end
        else
            if data.Destination and data.IsAttacking
            and (not sprite:IsPlaying("HopLoop") or sprite:IsEventTriggered("HopEnd")) then
                local dist = npc.Position:DistanceSquared(data.Destination)
                if dist <= 100 ^ 2 then
                    data.AttackDestination = data.Destination
                    data.Destination = nil
                end
            end

            if data.Destination then
                if not sprite:IsPlaying("HopLoop") then
                    sprite:Play("HopLoop", true)
                end

                if sprite:WasEventTriggered("HopAirStart") and not sprite:WasEventTriggered("HopAirEnd") then -- when sarc is in the air
                    npc.Velocity = (data.Destination - npc.Position):Resized(data.bal.ChaseSpeed)
                end
            end

            if sprite:IsPlaying("HopLoop") and sprite:IsEventTriggered("HopAirEnd") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.6, 0, false, 1)
                REVEL.game:ShakeScreen(5)
            end

            if data.AttackDestination and sprite:IsFinished("Jump") then
                local dist = npc.Position:DistanceSquared(data.AttackDestination)
                if dist <= 6 ^ 2 then
                    data.IsAttacking = nil
                    data.AttackDestination = nil
                    data.ReachedPosition = true
                    sprite:Play("Idle")
                end
            end

            if data.AttackDestination then
                if not sprite:IsPlaying("Jump") then
                    sprite:Play("Jump", true)
                    local JumpHopLength = 9
                    data.JumpVelocity = (data.AttackDestination - npc.Position) / JumpHopLength
                end

                if sprite:WasEventTriggered("HopAirStart") and not sprite:WasEventTriggered("HopAirEnd") then
                    npc.Velocity = data.JumpVelocity
                end
            end

            if sprite:IsEventTriggered("Sound") then
                if sprite:IsPlaying("Tell1") then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.SARCOPHAGUTS_FLASH_1, 1.3, 0, false, 1)
                elseif sprite:IsPlaying("Tell2") then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.SARCOPHAGUTS_FLASH_2, 1.3, 0, false, 1)
                end
            end

            if sprite:IsPlaying("Jump") and sprite:IsEventTriggered("HopAirEnd") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 1, 0, false, 1)
                REVEL.game:ShakeScreen(10)

                for _, urny in ipairs(REVEL.ENT.URNY:getInRoom()) do
                    local udata = urny:GetData()
                    if data.State == "Chase + Splash" then
                        udata.ForceLaunch = (udata.ForceLaunch or 0) + 1
                    else
                        udata.ForceLaunch = 2
                    end
                end
            end
        end

        ProcessStates(npc, data, sprite, target)

    elseif npc.Variant == REVEL.ENT.SARCOPHAGUTS_HEAD.variant then -- Sarcophaguts Head
		
        local data = npc:GetData()
        if not data.Sarc or not data.Sarc:Exists() or data.Sarc:IsDead() then
            npc:Die()
            return
        end

        REVEL.ApplyKnockbackImmunity(npc)

        local sarcdata, sprite = data.Sarc:GetData(), npc:GetSprite()

        if (sarcdata.MoveButtons or sarcdata.IsChampion) and data.CurrentEdgeIndex then
            MoveSarcophagutsTrackEntity(npc, sarcdata) --this function doesn't exist, yet it never broke anything? investigate
        else
            npc.Velocity = Vector.Zero
        end

        if npc.FrameCount <= 20 then
            sprite.Offset = Vector(0,sprite.Offset.Y-50)
            if npc.FrameCount == 10 then
                local i = math.random(1, #sarcdata.Buttons)
                local button = sarcdata.Buttons[i]
                button:GetData().CoverEntity = npc
                npc.Position = button.Position
            end
        elseif npc.FrameCount <= 41 then
            sprite.Offset = Vector(0,sprite.Offset.Y+50)
            if npc.FrameCount == 41 then
                sprite.Offset = Vector.Zero
                sprite:Play("Land", true)
                npc.Mass = 3
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1.4, 0, false, 1)
            end
        end

        if data.Sarc:GetSprite():IsPlaying("Tell1") and not sprite:IsPlaying("Tell1") then
            sprite:Play("Tell1", true)
        end
        if data.Sarc:GetSprite():IsPlaying("Tell2") and not sprite:IsPlaying("Tell2") then
            sprite:Play("Tell2", true)
        end
        
        if (npc.FrameCount-80)%100 == 0 and not sprite:IsPlaying("Tell1") and not sprite:IsPlaying("Tell2") 
        and npc.Position:Distance(npc:GetPlayerTarget().Position) < 200 then
            sprite:Play("Shoot", true)
        end

        if sprite:IsFinished("Land") or sprite:IsFinished("Shoot") or sprite:IsFinished("Tell1") or sprite:IsFinished("Tell2") then
            sprite:Play("Idle", true)
        end

        if sprite:IsEventTriggered("shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 0.6, 0, false, 1)
            SpawnSarcProjectile(sarcdata, npc.Position, (npc:GetPlayerTarget().Position - npc.Position):Resized(8), data.Sarc)
        end
    end
end, REVEL.ENT.SARCOPHAGUTS.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    if e.Variant == REVEL.ENT.SARCOPHAGUTS.variant then
        local data,sprite = e:GetData(),e:GetSprite()
		if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0 then
            if data.State == "Ouch" then -- dead for real
                if data.Buttons then
                    for _, button in ipairs(data.Buttons) do
                        button:GetData().ForcePressed = true
                        UpdateButton(button, {}, data)
                    end

                    data.Buttons = nil
                    data.MoveButtons = nil
                end
                return
            else
                data.AttackQueue = { "Break" }
                data.State = ""
                e.Velocity = Vector.Zero
                e.HitPoints = REVEL.GetDamageBuffer(e) + dmg
                return false
            end
        end

        if data.State == "Ouch" then
            return
        end

        if REVEL.ENT.SAND_BOULDER:isEnt(src) then
            if e.HitPoints <= e.MaxHitPoints/2 and not data.HasSpawnedSarcophagutsHead and not data.AttackBrimstone then
                data.AttackQueue = { "HeadRelease" }
                data.State = ""
            elseif data.State == "Chase + Splash" then
                data.BoulderHits = data.BoulderHits + 1
            end

            data.KnockBack = GetLerp(12, 4, 5, (e.Position - src.Position):Normalized())
            return true
        end

        if not REVEL.ENT.SARCOPHAGUTS_HEAD:isEnt(src) and
        not REVEL.some(data.bal.VulnerableAnims, function(anim) return sprite:IsPlaying(anim) end) then
            return false
        elseif data.State == "BloodPillarAttack" 
        and flag ~= flag | DamageFlag.DAMAGE_CLONES then
            e:TakeDamage(dmg * 0.5, DamageFlag.DAMAGE_CLONES, src, invuln)
            return false
        end

    elseif e.Variant == REVEL.ENT.SARCOPHAGUTS_HEAD.variant then
        e.HitPoints = e.MaxHitPoints + dmg
        if not IsAnimOn(e:GetSprite(), "Midair") then
            e:GetData().Sarc:TakeDamage(dmg * 0.2, flag, EntityRef(e), invuln)
        end
    end
end, REVEL.ENT.SARCOPHAGUTS.id)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_BOULDER_IMPACT, 0, function(boulder, npc, isGrid)
    if isGrid then return end

    if not npc then -- on miss
        local sarcs = REVEL.ENT.SARCOPHAGUTS:getInRoom()
        if #sarcs == 0 then return end

        local champ = REVEL.find(sarcs, function(sarc) return sarc:GetData().IsChampion end)
        if not champ then
            return true -- if not a champ, spawn urnies
        end

        -- if a champ, spawn tarboy
        local creep = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, -1, false, false)
        local tarboy = GetCachedEntities(EntityType.ENTITY_TARBOY)
        if math.random() <= 0.2 and #creep > 0 and #tarboy < 2 then
            SpawnTarBoy(champ:GetData(), creep[math.random(#creep)].Position, Vector.Zero, champ)
        end

        return false
    end

    if not REVEL.ENT.SARCOPHAGUTS:isEnt(npc) then return end

    local data = npc:GetData()

    npc:TakeDamage(npc.MaxHitPoints * data.bal.BoulderDamagePct, 0, EntityRef(boulder), 0)

    local data = npc:GetData()
    if data.IsChampion then
        -- on hit, spawn one or two guts
        local targuts = GetCachedEntities(EntityType.ENTITY_GUTS)
        if #targuts < data.bal.GutsCap then
            for i=1, math.random(1,2) do
                SpawnTarGuts(data, npc.Position+Vector.FromAngle(math.random(0,359))*50, Vector.Zero, npc)
            end
        end
    end

    return true
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SARCOPHAGUTS.variant then return end
    REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
    npc:BloodExplode()
end, REVEL.ENT.SARCOPHAGUTS.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    if not REVEL.ENT.SARCOPHAGUTS:isEnt(proj.SpawnerEntity) then return end

    if proj:GetData().UpwardsTear and proj.FrameCount >= 45 then
        proj:Remove()
    end

    if proj.SpawnerEntity:GetData().IsChampion and proj:IsDead() and
    not REVEL.IsOutOfRoomBy(proj.Position, -10) and proj.Height > -50 then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, proj.Position, Vector.Zero, proj):ToEffect()
        creep.Timeout = 45
    end
end)

--------------
-- SARCGUT --
--------------

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
    if npc.Variant == REVEL.ENT.SARCGUT.variant then
        npc.Velocity = RandomVector()*2
    end
end, REVEL.ENT.SARCGUT.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SARCGUT.variant then return end

    if not npc:GetSprite():IsPlaying("Walk") then
        npc:GetSprite():Play("Walk", true)
    end

    if npc.FrameCount % 10 == 0 then
        local creepVar = npc:GetData().CreepVariant
        if creepVar then
            local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, creepVar, 0, npc.Position, Vector.Zero, npc):ToEffect()
            creep.Timeout = 30
        else
            --REVEL.DebugLog('Bad sarc gut!', 'Dead:', npc:IsDead(), 'Exists:', npc:Exists(), npc:GetData())
        end
    end

    if math.random(120) == 1 or npc.Velocity.X == 0 and npc.Velocity.Y == 0 then
        npc.Velocity = RandomVector()*2
    end

    npc.Velocity = npc.Velocity:Resized(2)
end, REVEL.ENT.SARCGUT.id)

-------------
-- TARGUTS --
-------------

REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, collider)
    if not collider then return end

    if collider.Type == EntityType.ENTITY_GUTS then
        return true
    end
end, REVEL.ENT.SARCOPHAGUTS.id)

end