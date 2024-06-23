local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

local function EnqueueList(orig, new)
    for i = #new, 1, -1 do
        table.insert(orig, 1, new[i])
    end
end

function REVEL.SpawnHaemoProjectile(pos, vel, spawner, color)
    local projectile = Isaac.Spawn(9, 0, 0, pos, vel, spawner):ToProjectile()
    projectile.FallingSpeed = -30
    projectile.FallingAccel = 2
    projectile.Height = -10
    --projectile:Update()
    REVEL.GetData(projectile).IsHaemo = true
	REVEL.GetData(projectile).HaemoColor = color
    local projsprite = projectile:GetSprite()
    -- projsprite:Load("gfx/projectiles/002.035_balloon tear.anm2",true)
    -- projsprite:Play("RegularTear6", true)
    --projsprite:ReplaceSpritesheet(0, "gfx/projectiles/tears_balloon.png")
    --projsprite:LoadGraphics()
    projectile.Scale = 2.5
    return projectile
end

REVEL.WiliwawAnimations = {}
REVEL.WiliwawAnimationsText = {}

function REVEL.SpawnWilliwawAnimation(anim, name)
	local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, REVEL.player.Position, Vector.Zero, nil)
	eff:GetSprite():Load("gfx/bosses/revel1/williwaw/williwaw.anm2", true)
	eff:GetSprite():SetFrame("Idle", 0)
	table.insert(REVEL.WiliwawAnimations, {eff, anim})
	table.insert(REVEL.WiliwawAnimationsText, {name, Isaac.WorldToScreen(REVEL.player.Position + Vector(-50,-10))})
end

--[[REVEL.PlayWilliwawAnimationsCounter = nil

function REVEL.PlayWilliwawAnimations()
	REVEL.PlayWilliwawAnimationsCounter = -1
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	for _,v in ipairs(REVEL.WiliwawAnimationsText) do
		Isaac.RenderText(v[1], v[2].X, v[2].Y, 255, 255, 255, 255)
	end
	
	if REVEL.PlayWilliwawAnimationsCounter then
		REVEL.PlayWilliwawAnimationsCounter = REVEL.PlayWilliwawAnimationsCounter + 1/60
		Isaac.RenderText(tostring(math.floor(REVEL.PlayWilliwawAnimationsCounter*100)/100), 210, 10, 255, 255, 255, 255)
		if math.floor(REVEL.PlayWilliwawAnimationsCounter*100) == 0 then
			for _,v in ipairs(REVEL.WiliwawAnimations) do
				v[1]:GetSprite():Play(v[2], true)
			end
		end
	end
end)]]

function REVEL.SpawnWilliwawClone(pos, vel, spawner)
	local clone = Isaac.Spawn(REVEL.ENT.WILLIWAW.id, REVEL.ENT.WILLIWAW.variant, 1, pos, vel, spawner)
	REVEL.GetData(clone).IsWilliwawClone = true
	clone:GetSprite():ReplaceSpritesheet(0, REVEL.WilliwawBalance.CloneSpritesheet)
	clone:GetSprite():LoadGraphics()
	clone.MaxHitPoints = 0
	clone.HitPoints = 0
	clone.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	clone:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
	clone:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	clone.Parent = spawner
	clone:Update()
	
	return clone
end

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    if not REVEL.GetData(proj).IsHaemo then return end

    if proj.FrameCount % 5 == 0 then
        local trail = Isaac.Spawn(1000, EffectVariant.HAEMO_TRAIL, 0, proj.Position, Vector.Zero, proj)
        trail:GetSprite().Offset = Vector(0, proj.Height * 0.75)
		if REVEL.GetData(proj).HaemoColor then
			trail:GetSprite().Color = REVEL.GetData(proj).HaemoColor
		end
    end
    if proj:IsDead() then
        local projnum = math.random(6, 8)
        for i = 1, projnum do
            local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, proj.Position,
                    Vector(1,0):Rotated((i * 360/projnum) + math.random(-15, 15)) * math.random(5, 8),
                                  proj):ToProjectile()
            p.FallingSpeed = -1 * math.random(15, 20)
            p.FallingAccel = 2
            p.Scale = math.random(7, 15)/10
            -- p:GetSprite():ReplaceSpritesheet(0, "gfx/projectiles/tears_balloon.png")
            -- p:GetSprite():LoadGraphics()
            local eff = Isaac.Spawn(1000, 14, 1, p.Position, Vector.Zero, p)
			eff:GetSprite().Color = REVEL.GetData(proj).HaemoColor
        end
    end
end)

REVEL.WilliwawDisableChill = false

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
	if npc.Variant ~= REVEL.ENT.WILLIWAW.variant and npc.SubType == 0 then return end
	REVEL.WilliwawDisableChill = true
end, REVEL.ENT.WILLIWAW.id)

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, function(newRoom)
	REVEL.WilliwawDisableChill = false
end)

local function QueueAction(npc, data, action, insert)
	if type(action) == "string" then
		if insert then
			table.insert(data.ActionQueue, insert, data.bal[action])
		else
			table.insert(data.ActionQueue, data.bal[action])
		end
		-- REVEL.DebugLog("Queued " .. action .. "!", #data.ActionQueue, data.IsWilliwawClone and "is clone" or "not clone")
	else
		if insert then
			table.insert(data.ActionQueue, insert, action)
		else
			table.insert(data.ActionQueue, action)
		end
		-- local info = debug.getinfo(action)
		-- REVEL.DebugLog("Queued action! @line:" .. info.linedefined .. "-" .. info.lastlinedefined, #data.ActionQueue, data.IsWilliwawClone and "is clone" or "not clone")
	end
end

REVEL.WilliwawBalance = {
    Sfx = {
		BLOW_END = REVEL.SFX.WILLIWAW.BLOW_END,
		BLOW_LOOP = REVEL.SFX.WILLIWAW.BLOW_LOOP,
		BLOW_START = REVEL.SFX.WILLIWAW.BLOW_START,
		CLONE_CREATED = REVEL.SFX.WILLIWAW.CLONE_CREATED,
		CRACKING = REVEL.SFX.WILLIWAW.CRACKING,
		CREATE_CLONE = REVEL.SFX.WILLIWAW.CREATE_CLONE,
		DASH = REVEL.SFX.WILLIWAW.DASH,
		DEATH_CLONE = REVEL.SFX.WILLIWAW.DEATH_CLONE,
		DEATH = REVEL.SFX.WILLIWAW.DEATH,
		INTRO = REVEL.SFX.WILLIWAW.INTRO,
		INTRO_SHAKING = REVEL.SFX.WILLIWAW.INTRO_SHAKING,
		RECEIVE_ICICLE = REVEL.SFX.WILLIWAW.RECEIVE_ICICLE,
		REFORM = REVEL.SFX.WILLIWAW.REFORM,
		SHOOT_ICICLE = REVEL.SFX.WILLIWAW.SHOOT_ICICLE,
		SHOOT = REVEL.SFX.WILLIWAW.SHOOT,
		SLOW_DRIZZLE_SHOOT = REVEL.SFX.WILLIWAW.SLOW_DRIZZLE_SHOOT,
		SNOWFLAKE_SNIPE = REVEL.SFX.WILLIWAW.SNOWFLAKE_SNIPE
    },
	SfxVolume = 1,

    Mass = 400,
    BaseFriction = 0.6,
    MaxTrackingFrames = 1,
    Speed = 6,
    WanderMaxTime = 30,
	CrackedSpritesheet = "gfx/bosses/revel1/williwaw/williwaw_cracked.png",
	CloneSpritesheet = "gfx/bosses/revel1/williwaw/williwaw_clone.png",
	CloneSoundPitch = 1.3,
	SnowflakeDeathPctDmg = 0.01,
	SnowflakeHitPoints = 1,

	HpPctPhase1 = 0.65,
	HpPctPhase2 = 0.30,

	-- IdleWaitMin = 0,
	-- IdleWaitMax = 0,
	IdleWaitWithClone = {Min = 10, Max = 30},
	
	IntroShakeDelay = 30,
	IntroSnowflakeInterval = 10,
	IntroSnowflakeSpeed = 6,
	IntroNumSnowflakesNeeded = 5,
	IntroFadeOutSnowflakesTime = 10,

    ChargeSpeed = 20,
    ChargeMaxTime = 600,
    ChargeInsideThreshold = 80,
    ChargeFriction = 0.7,

    SlowDrizzleSpeed = 8,
    SlowDrizzleTravelTime = 45,
    SlowDrizzleNumArms = 3,
    SlowDrizzleNumArmProjectiles = 4,
    SlowDrizzleCurveStrength = 0.011,
    SlowDrizzleProjSpeed = 7,
    SlowDrizzleArmLaunchWait = 8,
    SlowDrizzleShootInterval = 4,
	SlowDrizzleHaemoColor = Color(0, 0, 0, 1,conv255ToFloat( 29, 84, 148)),

    RainDashProjInterval = 2,
    RainDashFreezeProjRadius = 35,
    RainDashProjFireInterval = 20,
	RainDashAuraDisappearWait = 20,
	RainDashProjNum = {Min = 9, Max = 12},
	RainDashPreferedDistanceFromClone = 160,
	
    SnowflakeSnipingFlakeCount = 6,
    SnowflakeSnipingSpeed = 1,
	SnowflakeSnipingOrbitRadius = 60,
    SnowflakeSnipingSlipperiness = 0.97,
    SnowflakeSnipingTime = math.floor(3.5 * 30),
    SnowflakeSnipingReformWait = 30,
	
	BeastWindsSnowflakePatterns = {
		[0] = { -- 0 is used as last snowflake wave
			Length = 1,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5}, {X=0,Y=6}}
		},
		{
			Length = 3,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=2}, {X=0,Y=4}, {X=0,Y=6},
			{X=2,Y=1}, {X=2,Y=3}, {X=2,Y=5}}
		},
		{
			Length = 5,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5},
			{X=4,Y=6}, {X=4,Y=5}, {X=4,Y=4}, {X=4,Y=3}, {X=4,Y=2}}
		},
		{
			Length = 1,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=5}, {X=0,Y=6}, {X=0,Y=7}}
		},
		{
			Length = 1,
			Snowflakes = {{X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5}, {X=0,Y=6}}
		},
		{
			Length = 3,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=3}, {X=0,Y=6},
			{X=2,Y=1}, {X=2,Y=2}, {X=2,Y=4}, {X=2,Y=5}}
		},
		{
			Length = 3,
			Snowflakes = {{X=0,Y=0}, {X=1,Y=1}, {X=2,Y=2},
			{X=0,Y=6}, {X=1,Y=5}, {X=2,Y=4}}
		},
		{
			Length = 4,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4},
			{X=2,Y=6}, {X=3,Y=5}, {X=3,Y=4}, {X=4,Y=3}, {X=4,Y=2}}
		}
	},
	BeastWindsCloneSnowflakePatterns = {
		[0] = { -- 0 is used as last snowflake wave
			Length = 1,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5}, {X=0,Y=6}}
		},
		{
			Length = 3,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=2}, {X=0,Y=4}, {X=0,Y=6},
			{X=2,Y=1}, {X=2,Y=5}}
		},
		{
			Length = 5,
			Snowflakes = {{X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5},
			{X=4,Y=7}, {X=4,Y=6}, {X=4,Y=1}, {X=4,Y=0}}
		},
		{
			Length = 1,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=5}, {X=0,Y=6}, {X=0,Y=7}}
		},
		{
			Length = 1,
			Snowflakes = {{X=0,Y=2}, {X=0,Y=3}, {X=0,Y=4}, {X=0,Y=5}}
		},
		{
			Length = 3,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=3}, {X=0,Y=6},
			{X=2,Y=1}, {X=2,Y=5}}
		},
		{
			Length = 3,
			Snowflakes = {{X=1,Y=1}, {X=2,Y=2},
			{X=1,Y=5}, {X=2,Y=4}}
		},
		{
			Length = 4,
			Snowflakes = {{X=0,Y=0}, {X=0,Y=1}, {X=0,Y=2}, {X=0,Y=3},
			{X=2,Y=6}, {X=3,Y=5}, {X=3,Y=4}, {X=4,Y=3}}
		}
	},
	BeastWindsSnowflakeSpeed = 200 / 30, -- 5 grids per second
	BeastWindsTimeBetweenPatterns = 20,
	BeastWindsGrillOWispTime = 180,
	BeastWindsCloneGrillOWispTime = 60,
	BeastWindsBonusWispInterval = 15,
	BeastWindsFramesPerSinWave = 120,
	
	CrackedWaitTime = 15,
	CrackedNumHitProjectiles = 8,
	CrackedBreakProjectilesSpeed = 8,
	
	SteamOutNumClonesPhase2 = 1,
	SteamOutNumClonesPhase3 = 5,
	
	CloneCorralMaxOrbittingSpeed = 4,
	CloneCorralMaxRadius = 220,
	CloneCorralMinRadius = 140,
	CloneCorralShrinkTime = 60,
	CloneCorralOrbitingTime = {Min = 275, Max = 400},
	CloneCorralShootingDelay = {Min = 20, Max = 40},
	
	GatewaySnipingSlowdownTime = 45,
	GatewaySnipingOrbittingSpeed = 3.6,
	GatewaySnipingFlakeCount = 5,
	-- GatewaySnipingCloneFlakeCount = 3,
	GatewaySnipingSnowflakeTime = 135,
	GatewaySnipingSnowflakeAttackMaxRadius = 130,
	GatewaySnipingSnowflakeAttackMinRadius = 80,
	GatewaySnipingMinRadius = 20,
	
	CloneDeathInterval = 20,
	DeathMaxOrbittingSpeed = 10,
	DeathOrbitAcceleration = 0.5,

-- Slow Drizzle
-- - Fires 4 very large projectiles 90 degrees apart from each-other
--   - Rotate either clockwise or counterclockwise while moving outward
--   - Stop after N frames
--   - Every M frames spawn a smaller floating projectile at its position if alive
-- - One projectile arm is selected randomly, then projectiles in that arm starting from those closest to the boss are
--   quickly fired at the player.
--   - The big projectile at the end is lobbed slightly and creates a splash of projectiles when it impacts the ground
--   - Repeat until no projectile arms remain.
GoSlowDrizzle = function(n, s, d)
	local function DoArm()
        QueueAction(n, d, function(npc, sprite, data)
            data.SlowDrizzleTimer = data.bal.SlowDrizzleArmLaunchWait - 1
        end, 1)
        QueueAction(n, d, function(npc, sprite, data)
            data.SlowDrizzleTimer = data.SlowDrizzleTimer - 1
            if data.SlowDrizzleTimer > 0 then return false end

            repeat
                data.CurrentArm = table.remove(data.DrizzleProjectiles, math.random(#data.DrizzleProjectiles))
            until not data.CurrentArm or REVEL.some(data.CurrentArm, function(proj) return not proj:IsDead() end)
                  or #data.DrizzleProjectiles == 0

            data.SlowDrizzleTimer = 0
        end, 2)
        QueueAction(n, d, function(npc, sprite, data)
            if not data.CurrentArm then return true end

            data.SlowDrizzleTimer = data.SlowDrizzleTimer + 1
            local interval = math.floor(data.bal.SlowDrizzleShootInterval)
            if data.SlowDrizzleTimer % interval ~= 0 then return false end

            while #data.CurrentArm > 1 do
                local next = table.remove(data.CurrentArm, 2)
                if not next:IsDead() then
                    next.Velocity = (npc:GetPlayerTarget().Position - next.Position):Resized(data.bal.SlowDrizzleProjSpeed)
                    next.FallingSpeed = 0.08
                    next.FallingAccel = 0
                    return false
                end
            end

            if #data.CurrentArm == 1 then
                local next = table.remove(data.CurrentArm, 1)
                next.Velocity = (npc:GetPlayerTarget().Position - next.Position):Resized(data.bal.SlowDrizzleProjSpeed)
                next.FallingSpeed = -15
                next.FallingAccel = 0.6
                return false
            end

            if #data.DrizzleProjectiles > 0 then
                DoArm()
            end
        end, 3)
    end
	QueueAction(n, d, function(npc, sprite, data)
		data.bal.GoSpaceFromSide(npc, sprite, data)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
        sprite:Play('Slow Drizzle Start', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.SLOW_DRIZZLE_SHOOT, data.bal.SfxVolume, 0, false, data.SfxPitch)
    end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
        if not sprite:IsEventTriggered('Shoot') then return false end

        data.DrizzleProjectiles = {}
        local vel = RandomVector() * data.bal.SlowDrizzleSpeed
        local dirFlag = math.random(2) == 1 and ProjectileFlags.CURVE_RIGHT or ProjectileFlags.CURVE_LEFT

        data.SlowDrizzleTimer = data.bal.SlowDrizzleTravelTime
        for i = 1, data.bal.SlowDrizzleNumArms do
            --local proj = REVEL.SpawnHaemoProjectile(npc.Position, vel, npc)
            --local proj = Isaac.Spawn(9, 0, 0, npc.Position, vel, npc):ToProjectile()
            local proj = REVEL.SpawnHaemoProjectile(npc.Position, vel, npc, data.bal.SlowDrizzleHaemoColor)
            proj.FallingSpeed = 0
            proj.FallingAccel = -0.1
            proj.Height = -23
            --proj.Scale = 2
            proj.ProjectileFlags = BitOr( dirFlag, 
                                 ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT, 
                                 ProjectileFlags.CHANGE_VELOCITY_AFTER_TIMEOUT, 
								 ProjectileFlags.NO_WALL_COLLIDE
								)
            proj.CurvingStrength = data.bal.SlowDrizzleCurveStrength
            proj.ChangeFlags = 0
            proj.ChangeVelocity = 0
            proj.ChangeTimeout = data.bal.SlowDrizzleTravelTime
			proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            table.insert(data.DrizzleProjectiles, { proj })

            vel = vel:Rotated(360 / data.bal.SlowDrizzleNumArms)
        end
    end)
    QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
        if sprite:IsFinished('Slow Drizzle Start') then
            sprite:Play('Idle', true)
            sprite:PlayOverlay('Slow Drizzle OverlayIdle', true)
        end

        data.SlowDrizzleTimer = data.SlowDrizzleTimer - 1
        if data.SlowDrizzleTimer == 0 then
            sprite:PlayOverlay('Slow Drizzle OverlayDie', true)
			DoArm()
			npc.Velocity = Vector.Zero
            return true
        end

        local interval = math.floor(data.bal.SlowDrizzleTravelTime / (data.bal.SlowDrizzleNumArmProjectiles + 1))
        if data.SlowDrizzleTimer % interval ~= 0 then return false end

        for _, arm in pairs(data.DrizzleProjectiles) do
            local leader = arm[1]
            if not leader:IsDead() then
                local proj = Isaac.Spawn(9, 0, 0, leader.Position, Vector.Zero, npc):ToProjectile()
                proj.FallingSpeed = 0
                proj.FallingAccel = -0.1
				proj.ProjectileFlags = proj.ProjectileFlags | ProjectileFlags.NO_WALL_COLLIDE
				proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                table.insert(arm, proj)
            end
        end

        return false
    end)
end,

-- Rain Dash
-- - Move to the edge of the room and charge up
-- - Dash rapidly to the opposite side
--   - Leave a large amount of floating projectiles with Brainfreeze auras behind
--   - Projectiles are fired 2-3 at a time until none remain
--   - Auras disappear at this time?
GoRainDash = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
		if not data.IsWilliwawClone and data.CurrentPhase == "Fast & Flurrious" then
			if data.Clones[1] and (data.Clones[1].Position - npc.Position):LengthSquared() > data.bal.RainDashPreferedDistanceFromClone ^ 2 then
				data.bal.GoMoveTowardsEnt(npc, sprite, data, data.Clones[1], data.bal.RainDashPreferedDistanceFromClone)
			end
		end
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.WanderSide = "Vertical"
		if REVEL.room:IsPositionInRoom(npc.Position, 40) then
			data.bal.GoWanderSide(npc, sprite, data)
		else
			npc.Velocity = Vector((data.Target.Position-npc.Position):Resized(data.bal.Speed).X, 0)
		end
	end)

    QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity * 0.9
        data.Stopped = true
        local target = REVEL.room:GetCenterPos()
		data.ChargeUp = npc.Position.Y - target.Y > 0
		data.RainProjCount = REVEL.GetFromMinMax(data.bal.RainDashProjNum)
		data.ChargeVel = Vector(0, data.bal.ChargeSpeed * (data.ChargeUp and -1 or 1))
        sprite:Play('Rain Dash Start', true)
        --Sfx[data.DashWindupSfx or 'DashWindup'](npc)
    end)

    local function FireRainDashProj(npc, data)
		npc.Velocity = npc.Velocity * 0.9
        if npc.FrameCount % data.bal.RainDashProjInterval == 0 and data.RainProjCount > 0 then
            local aura = REVEL.SpawnFreezeAura(data.bal.RainDashFreezeProjRadius, npc.Position, npc, 300)
            local proj = Isaac.Spawn(9, 0, 0, npc.Position, Vector.Zero, npc):ToProjectile()
            proj.DepthOffset = aura.DepthOffset - 100
            REVEL.HoldAuraProjectile(proj, aura)
			table.insert(data.FreezeAuras, aura)
			data.RainProjCount = data.RainProjCount - 1
        end
    end

    QueueAction(n, d, function(npc, sprite, data)
        npc.Velocity = npc.Velocity * 0.9
        local anim = "Rain Dash Start"

		if sprite:IsFinished(anim) then
			REVEL.sfx:NpcPlay(npc, data.bal.Sfx.DASH, data.bal.SfxVolume, 0, false, data.SfxPitch)
		end

        --[[if data.ChargeVel then
            npc.Velocity = data.ChargeVel
            FireRainDashProj(npc, data)
        end]]

        return sprite:IsFinished(anim)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        local anim = "Rain Dash Cont"
        sprite:Play(anim, true)

        npc.Velocity = data.ChargeVel
        FireRainDashProj(npc, data)

        --Sfx.DashCharge(npc)
        data.ChargeTimer = data.bal.ChargeMaxTime
    end)
    QueueAction(n, d, function(npc, sprite, data)
        npc.Velocity = data.ChargeVel
        FireRainDashProj(npc, data)

        data.ChargeTimer = data.ChargeTimer - 1
        if data.ChargeTimer <= 0 or data.RainProjCount <= 0 then return true end

        -- if within a certain distance of being outside the room stop dashing
        local outRoomPos = npc.Position + Vector(0, (data.ChargeUp and -1 or 1) * d.bal.ChargeInsideThreshold)
        return not REVEL.room:IsPositionInRoom(outRoomPos, 0)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        local anim = "Rain Dash End"
        sprite:Play(anim, true)
        --Sfx.DashEnd(npc)
        data.ChargeUp = nil
        npc.Velocity = npc.Velocity * data.bal.ChargeFriction
        FireRainDashProj(npc, data)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        -- quickly slow down during charge end
        local anim = "Rain Dash End"
        if sprite:IsFinished(anim) then
            sprite:Play('Idle', true)
            return true
        end

        local vel = npc.Velocity
        if vel:LengthSquared() > 0.4 then
            npc.Velocity = vel * data.bal.ChargeFriction
        end
        return false
    end)
    QueueAction(n, d, function(npc, sprite, data)
        data.Stopped = data.WasStopped
        data.WasStopped = nil
        data.ChargeVel = nil
		npc.Velocity = Vector.Zero

        data.AurasToShoot = REVEL.shuffle(data.FreezeAuras)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        if #data.AurasToShoot == 0 then
            data.WaitTimer = data.bal.RainDashAuraDisappearWait
            return true
        end

        if npc.FrameCount % data.bal.RainDashProjFireInterval ~= 0 then return false end

        local projectilesLeftToFire = math.random(2, 3)
        for i, aura in ripairs(data.AurasToShoot) do
            if aura:IsDead() then
                table.remove(data.AurasToShoot, i)
            elseif projectilesLeftToFire == 0 then break
            else
                projectilesLeftToFire = projectilesLeftToFire - 1
                table.remove(data.AurasToShoot, i)
                REVEL.ShootAura(aura, npc:GetPlayerTarget(), npc, true)
            end
        end

        return false
    end)
    QueueAction(n, d, function(npc, sprite, data)
        data.WaitTimer = data.WaitTimer - 1
        if data.WaitTimer > 0 then return false end
        data.WaitTimer = nil

        data.AurasToShoot = nil
        for _, aura in pairs(data.FreezeAuras) do
            REVEL.AuraExpandFade(aura, 5, REVEL.GetData(aura).Radius * 1.6)
        end
        data.FreezeAuras = {}
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    end)
end,

GoWanderSide = function(n, s, d)
    QueueAction(n, d, function(npc, sprite, data)
        data.WasStopped = data.Stopped
        data.Stopped = true
        data.WanderTimer = (data.WanderTimer and data.WanderTimer > 0)
                            and data.WanderTimer or data.bal.WanderMaxTime
    end, 1)
    QueueAction(n, d, function(npc, sprite, data)
        data.WanderTimer = data.WanderTimer - 1
        if data.WanderTimer < 0 then return true end

		if data.WanderSide == "Vertical" then
			local direction = (npc.Position.Y - REVEL.room:GetCenterPos().Y > 0) and 1 or -1
			direction = Vector(0, direction)
			local wanderMove = direction * (data.bal.Speed * 0.8)
			npc.Velocity = npc.Velocity*0.7 + (npc.Velocity + wanderMove):Resized(data.bal.Speed*0.3)

			-- if within 1 grid of the appropriate side of the room, continue
			return not REVEL.room:IsPositionInRoom(npc.Position + direction * 40, 0)
		
		elseif data.WanderSide == "Horizontal" then
			 local direction = (npc.Position.X - REVEL.room:GetCenterPos().X > 0) and 1 or -1
			direction = Vector(direction, 0)
			local wanderMove = direction * (data.bal.Speed * 0.8)
			npc.Velocity = npc.Velocity*0.7 + (npc.Velocity + wanderMove):Resized(data.bal.Speed*0.3)

			-- if within 2 grids of the appropriate side of the room, continue
			return not REVEL.room:IsPositionInRoom(npc.Position + direction * 80, 0)
		end
    end, 2)
    QueueAction(n, d, function(npc, sprite, data)
        data.Stopped = data.WasStopped
        data.WasStopped = nil
        data.WanderTimer = nil
    end, 3)
end,

--get a small distance from the side if you don't want to start close to the wall
GoSpaceFromSide = function(n, s, d)
    QueueAction(n, d, function(npc, sprite, data)
        data.WasStopped = data.Stopped
        data.Stopped = true
        data.WanderTimer = (data.WanderTimer and data.WanderTimer > 0)
                            and data.WanderTimer or data.bal.WanderMaxTime
    end, 1)
   QueueAction(n, d, function(npc, sprite, data)
        data.WanderTimer = data.WanderTimer - 1
        if data.WanderTimer < 0 then return true end

        local wanderMove = (REVEL.room:GetCenterPos() - npc.Position):Resized(data.bal.Speed * 0.8)
        npc.Velocity = npc.Velocity*0.7 + (npc.Velocity + wanderMove):Resized(data.bal.Speed*0.3)

        -- if 1 grid away from wall, continue
        return REVEL.room:IsPositionInRoom(npc.Position, 40)
    end, 2)
    QueueAction(n, d, function(npc, sprite, data)
        data.Stopped = data.WasStopped
        data.WasStopped = nil
        data.WanderTimer = nil
    end, 3)
end,

--move close towards a target ent, up to a certain radius
GoMoveTowardsEnt = function(n, s, d, ent, radius)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.7 + (ent.Position - npc.Position):Resized(data.bal.Speed*0.3)
		
		return (ent.Position - npc.Position):LengthSquared() <= radius ^ 2
	end, 1)
end,

-- Snowflake Sniping
-- - Compress and charge the icicle, then fling it upward
--   - Cloud form bursts into 8 big snowflakes
--   - These are flung out orbiting a central point
--   - Chase after the player with low friction, accelerate over time
--   - It should be hard to escape them without killing a few.
-- - After 2.5-3.5s, snowflakes stop in place
-- - 1s later the icicle falls directly in the middle of them
-- - The remaining snowflakes fly into the icicle and disappear while Williwaw reforms
GoSnowflakeSniping = function(n, s, d)
    QueueAction(n, d, function(npc, sprite, data)
        data.Stopped = true
		npc.Velocity = Vector.Zero
        sprite:Play('Snowflake Sniping Explode', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.SNOWFLAKE_SNIPE, data.bal.SfxVolume, 0, false, data.SfxPitch)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        if sprite:IsEventTriggered('Icicle') then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.SnowflakeTimer = data.bal.SnowflakeSnipingTime

            data.Snowflakes = {}
            for i = 1, data.bal.SnowflakeSnipingFlakeCount do
				-- no hp set option, so do manually
				local snowflake = REVEL.SpawnOrbitingFlake(npc, false, 1, npc.Position, 20, false, data.bal.SnowflakeSnipingOrbitRadius, true)
				snowflake.MaxHitPoints = data.bal.SnowflakeHitPoints
				snowflake.HitPoints = snowflake.MaxHitPoints

                table.insert(data.Snowflakes, snowflake)
            end
        end

        return sprite:IsFinished('Snowflake Sniping Explode')
    end)
    QueueAction(n, d, function(npc, sprite, data)
        data.SnowflakeTimer = data.SnowflakeTimer - 1
        if data.SnowflakeTimer <= 0 and REVEL.room:IsPositionInRoom(npc.Position, 0)then
			npc.Velocity = npc.Velocity*0.9
			
			if npc.Velocity:LengthSquared() < 1 then
				npc.Velocity = Vector.Zero
				data.SnowflakeTimer = data.bal.SnowflakeSnipingReformWait
				return true
			end
        else
			local speed = REVEL.Lerp2Clamp(data.bal.SnowflakeSnipingSpeed, data.bal.SnowflakeSnipingSpeed * 2,
									 1 - data.SnowflakeTimer / data.bal.SnowflakeSnipingTime)
			npc.Velocity = npc.Velocity * data.bal.SnowflakeSnipingSlipperiness + (npc:GetPlayerTarget().Position - npc.Position):Resized(speed*0.2)
		end
	
        return false
    end)
    QueueAction(n, d, function(npc, sprite, data)
        data.SnowflakeTimer = data.SnowflakeTimer - 1
        if data.SnowflakeTimer > 0 then return false end

        sprite:Play('Snowflake Sniping Reform')
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.REFORM, data.bal.SfxVolume, 0, false, data.SfxPitch)
    end)
    QueueAction(n, d, function(npc, sprite, data)
        if sprite:IsEventTriggered('Land') then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

            for _, snowflake in pairs(data.Snowflakes) do
                local sdata = REVEL.GetData(snowflake)
                sdata.MoveState = nil
                sdata.State = 'dummy'
                snowflake.Velocity = (npc.Position - snowflake.Position):Resized(5)
                REVEL.DelayFunction(function() snowflake:Remove() end, 9, nil, true)
            end
        end

        return sprite:IsFinished('Snowflake Sniping Reform')
    end)
    QueueAction(n, d, function(npc, sprite, data)
        sprite:Play('Idle', true)
		data.Orbiters = {}
		data.NumOrbiters = 0
        data.Stopped = false
    end)
end,

-- Beast Winds
-- - Move to the left or right side of the room
-- - Blow outward and chill the room
-- - Snowflakes fly in at a constant speed from behind Williwaw in various dodgeable patterns
--   - Disappear when they go off-screen
-- - After 8-10s, a single Grill-o-Wisp flies in at a random Y position
--   - This is followed by an undodgeable wall of snowflakes which are randomly offset on the X axis
--   - The player must use the Grill-o to unfreeze themselves so they can kill some snowflakes and pass through
-- - The attack ends when no snowflakes remain on-screen at this point
GoBeastWinds = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		data.WanderSide = "Horizontal"
		data.bal.GoSpaceFromSide(npc, sprite, data)
		data.bal.GoWanderSide(npc, sprite, data)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		local room = REVEL.room
        data.BeastWindsFlipped = npc.Position.X < room:GetCenterPos().X
		--[[if data.BeastWindsFlipped then
			data.BeastWindsTargetPosition = room:GetGridPosition(62)
		else
			data.BeastWindsTargetPosition = room:GetGridPosition(72)
		end]]
    end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
        sprite:Play('Beast Winds Start', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.BLOW_START, data.bal.SfxVolume, 0, false, data.SfxPitch)
		sprite.FlipX = data.BeastWindsFlipped
    end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		if sprite:IsEventTriggered("Shoot") then
			REVEL.WilliwawDisableChill = false
		end
		
        return sprite:IsFinished('Beast Winds Start', true)
    end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = Vector.Zero
		for _,player in ipairs(REVEL.players) do
			REVEL.ChillFreezePlayer(player, 1, true)
			REVEL.EvaluateChill(player)
		end
		data.TimeUntilNextSnowflakePattern = 0
		if data.IsWilliwawClone then
			data.TimeUntilGrillOWisp = data.bal.BeastWindsCloneGrillOWispTime
		else
			data.TimeUntilGrillOWisp = data.bal.BeastWindsGrillOWispTime
		end
		data.SinWaveCounter = math.asin((npc.Position.Y-REVEL.room:GetCenterPos().Y)/140)
		sprite:Play('Beast Winds Cont', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.BLOW_LOOP, data.bal.SfxVolume, 0, true, data.SfxPitch)
    end)
	QueueAction(n, d, function(npc, sprite, data)
		if data.TimeUntilGrillOWisp == 0 then
			data.GrillOWispsNextWave = true
			data.TimeUntilNextSnowflakePattern = data.TimeUntilNextSnowflakePattern + data.bal.BeastWindsBonusWispInterval
		end
		
		data.SinWaveCounter = data.SinWaveCounter + (math.pi*2)/data.bal.BeastWindsFramesPerSinWave
		local y = REVEL.Clamp((math.sin(data.SinWaveCounter)*140 + REVEL.room:GetCenterPos().Y - npc.Position.Y)*0.5, npc.Velocity.Y-1, npc.Velocity.Y+1)
		npc.Velocity = Vector(0,y)
		
		if not data.LastSnowflakeWave and data.TimeUntilNextSnowflakePattern == 0 then
			local maxSpeed = 1
			for playerNum = 1, REVEL.game:GetNumPlayers() do
				local player = REVEL.game:GetPlayer(playerNum):ToPlayer()
				if maxSpeed > player.MoveSpeed then
					maxSpeed = player.MoveSpeed
				end
			end

			local snowflakeSpeed = data.bal.BeastWindsSnowflakeSpeed
			local timeBetweenPatterns = data.BeastWindsTimeBetweenPatterns
			if maxSpeed <= 0.6 then
				snowflakeSpeed = data.bal.BeastWindsSnowflakeSpeed * 0.8
				timeBetweenPatterns = timeBetweenPatterns * 1.5
			end

			local pattern
			if data.GrillOWispsNextWave then
				snowflakeSpeed = data.bal.BeastWindsSnowflakeSpeed * 0.7
				if data.IsWilliwawClone then
					pattern = data.bal.BeastWindsCloneSnowflakePatterns[0]
				else
					pattern = data.bal.BeastWindsSnowflakePatterns[0]
				end
				sprite:Play("Beast Winds End", true)
				REVEL.sfx:Stop(data.bal.Sfx.BLOW_LOOP)
				REVEL.sfx:NpcPlay(npc, data.bal.Sfx.BLOW_END, data.bal.SfxVolume, 0, false, data.SfxPitch)
				data.GrillOWispsNextWave = false
				data.LastSnowflakeWave = true
				data.TargetWispYPosition = math.random(REVEL.room:GetTopLeftPos().Y+30, REVEL.room:GetBottomRightPos().Y-30)
			else
				if data.IsWilliwawClone then
					pattern = data.bal.BeastWindsCloneSnowflakePatterns[math.random(#data.bal.BeastWindsSnowflakePatterns)]
				else
					pattern = data.bal.BeastWindsSnowflakePatterns[math.random(#data.bal.BeastWindsSnowflakePatterns)]
				end
			end
			
			local patternYScale = (math.random(0,1) - 0.5) * 2 -- either 1 or -1
			local patternXScale = (math.random(0,1) - 0.5) * 2 -- either 1 or -1
			local offset = 120
			if data.IsWilliwawClone then
				offset = 140
			end
			local patternStartPos
			if data.BeastWindsFlipped then
				patternStartPos = Vector(patternXScale == 1 and REVEL.room:GetTopLeftPos().X - offset - pattern.Length*40 or REVEL.room:GetTopLeftPos().X - offset, 
									patternYScale == -1 and REVEL.room:GetBottomRightPos().Y - 20 or REVEL.room:GetTopLeftPos().Y + 20
				)
			else
				patternStartPos = Vector(patternXScale == -1 and REVEL.room:GetBottomRightPos().X + offset + pattern.Length*40 or REVEL.room:GetBottomRightPos().X + offset, 
									patternYScale == -1 and REVEL.room:GetBottomRightPos().Y - 20 or REVEL.room:GetTopLeftPos().Y + 20
				)
			end
			
			for _,pos in ipairs(pattern.Snowflakes) do
				local snowflake = REVEL.SpawnNoChampion(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, 
								patternStartPos + Vector(pos.X*40*patternXScale + math.random(-20,20), pos.Y*40*patternYScale),
								data.BeastWindsFlipped and Vector(snowflakeSpeed, 0) or Vector(-snowflakeSpeed, 0), 
								npc
				)
				snowflake.MaxHitPoints = data.bal.SnowflakeHitPoints
				snowflake.HitPoints = snowflake.MaxHitPoints
				snowflake:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				snowflake:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				REVEL.GetData(snowflake).MoveState = "Projectile"
				REVEL.GetData(snowflake).State = "Projectile"
				REVEL.GetData(snowflake).MaxMarginOutsideRoom = -10000
				REVEL.DelayFunction(function() REVEL.GetData(snowflake).MaxMarginOutsideRoom = -100 end, 15 + math.ceil(pattern.Length*7.5), nil, true)
			end
			
			data.TimeUntilNextSnowflakePattern = pattern.Length * 7.5 + timeBetweenPatterns
		end
		
		if data.TargetWispYPosition then
			npc.Velocity = Vector(0, (data.TargetWispYPosition - npc.Position.Y)*0.25)
		end
		
		if sprite:IsEventTriggered("Wall") then
			data.Wisp = Isaac.Spawn(REVEL.ENT.GRILL_O_WISP.id, REVEL.ENT.GRILL_O_WISP.variant, 0, 
							npc.Position + Vector(data.BeastWindsFlipped and 20 or -20, 0),
							data.BeastWindsFlipped and Vector(data.bal.BeastWindsSnowflakeSpeed*0.8, 0) or Vector(-data.bal.BeastWindsSnowflakeSpeed*0.8, 0), 
							npc
			)
			data.Wisp:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			data.Wisp.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
			REVEL.GetData(data.Wisp).IsProjectile = true
			REVEL.GetData(data.Wisp).ProjectileVelocity = data.Wisp.Velocity
			REVEL.GetData(data.Wisp).MaxMarginOutsideRoom = -120
		end
		
		data.TimeUntilNextSnowflakePattern = math.max(data.TimeUntilNextSnowflakePattern - 1, 0)
		data.TimeUntilGrillOWisp = data.TimeUntilGrillOWisp - 1
		
		return sprite:IsFinished("Beast Winds End")
	end)
	QueueAction(n, d, function(npc, sprite, data)
		sprite:Play("Beast Winds Face", true)
		npc.Velocity = npc.Velocity*0.5
		data.LastSnowflakeWave = false
		data.TargetWispYPosition = nil
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		if not data.Wisp:Exists() or data.Wisp:IsDead() then
			data.Wisp = nil
			REVEL.WilliwawDisableChill = true
		else
			return false
		end
	end)
end,

-- Cracked
-- - Move to the center of the room
-- - Look up, and grimace; a stalactite then falls on him, smashing him into the ground
--   - Splash several projectiles on impact
-- - Rise up, shake for a moment
--  - The fallen stalactite shatters and shoots 8 projectiles in a circle
--   - When it shatters, Williwaw freezes, and a small crack expands on his icicle.
GoCracked = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		--[[local centerPos = REVEL.room:GetCenterPos()
		npc.Velocity = (centerPos - npc.Position):Resized(data.bal.Speed)
		
		return (npc.Position + npc.Velocity - centerPos):LengthSquared() <= (data.bal.Speed*0.5) ^ 2]]
		data.bal.GoSpaceFromSide(npc, sprite, data)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		data.CrackedWaitTime = data.bal.CrackedWaitTime
		
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		data.CrackedWaitTime = data.CrackedWaitTime - 1
		
		if data.CrackedWaitTime == 0 then
			npc.Velocity = Vector.Zero
			sprite:Play("Cracking", true)
			REVEL.sfx:NpcPlay(npc, data.bal.Sfx.CRACKING, data.bal.SfxVolume, 0, false, data.SfxPitch)
			return true
		end
		
		return false
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if sprite:IsEventTriggered("Hit") then
			for i=1, data.bal.CrackedNumHitProjectiles do
				local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, Vector.FromAngle(math.random(0,359))*(math.random()*4 + 3), npc):ToProjectile()
				proj.FallingSpeed = -14 + math.random()*-2
				proj.FallingAccel = 0.9
			end
		end
		if sprite:IsEventTriggered("Break") then
			REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
			for i=1, 8 do
				local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, Vector.FromAngle(i*45)*data.bal.CrackedBreakProjectilesSpeed, npc):ToProjectile()
			end
			sprite:ReplaceSpritesheet(0, data.bal.CrackedSpritesheet)
			sprite:LoadGraphics()
		end
		
		return sprite:IsFinished("Cracking")
	end)
end,

-- Steam Out
-- - Get incredibly angry and expand and boil
-- - Relax and shoot out a number of clones as needed for the current phase.
GoSteamOut = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		--[[local centerPos = REVEL.room:GetCenterPos()
		npc.Velocity = (centerPos - npc.Position):Resized(data.bal.Speed)
		
		return (npc.Position + npc.Velocity - centerPos):LengthSquared() <= (data.bal.Speed*0.5) ^ 2]]
		data.bal.GoSpaceFromSide(npc, sprite, data)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		sprite:Play("Clone Creation Start", true)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = npc.Velocity*0.5
		return sprite:IsFinished("Clone Creation Start")
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = Vector.Zero
		sprite:Play("Clone Creation Cont", true)
		sprite:PlayOverlay("Clone Cloud Overlay", true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.CREATE_CLONE, data.bal.SfxVolume, 0, true, data.SfxPitch)
		data.CloudsSentInSky = 1
		if data.CurrentPhase == "Fast & Flurrious" then
			data.NumClones = data.bal.SteamOutNumClonesPhase2 - #data.Clones
		else
			data.NumClones = data.bal.SteamOutNumClonesPhase3 - #data.Clones
		end
		sprite.PlaybackSpeed = 0.9 + data.NumClones*0.2
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if data.CloudsSentInSky ~= data.NumClones and sprite:IsOverlayFinished("Clone Cloud Overlay") then
			sprite:PlayOverlay("Clone Cloud Overlay", true)
			data.CloudsSentInSky = data.CloudsSentInSky + 1
		end
		
		return data.CloudsSentInSky == data.NumClones and sprite:IsOverlayFinished("Clone Cloud Overlay")
	end)
	QueueAction(n, d, function(npc, sprite, data)
		sprite.PlaybackSpeed = 1
		sprite:RemoveOverlay()
		sprite:Play("Clone Creation End")
		REVEL.sfx:Stop(data.bal.Sfx.CREATE_CLONE)
		for numClones=1, data.NumClones do
			local i = 0
			local pos
			while i ~= 100 do
				pos = REVEL.room:GetRandomPosition(-20)
				if (npc.Position-pos):LengthSquared() > 60 ^ 2 then
					local tooCloseToOtherClone = false
					for _,clone in ipairs(data.Clones) do
						if (clone.Position-pos):LengthSquared() <= 60 ^ 2 then
							tooCloseToOtherClone = true
							break
						end
					end
					
					if not tooCloseToOtherClone then
						break
					end
				end
				i = i + 1
			end
			
			table.insert(data.Clones, REVEL.SpawnWilliwawClone(pos, Vector.Zero, npc))
		end
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if sprite:IsFinished("Clone Creation End") then
			if data.CurrentPhase == "Fast & Flurrious" then
				data.FullyEnteredPhase = 1
			else
				data.FullyEnteredPhase = 2
			end
		end
		return sprite:IsFinished("Clone Creation End")
	end)
end,

-- Clone Corral
-- - All Williwaws move to surround the player, then close in to form a fairly wide but inescapable circle
--   and begin rapidly orbiting.
-- - Williwaw prime randomly ejects and transfers their icicle to a clone
-- - Every 1-2s, Williwaw prime fires a large slow-moving projectile at the player
--   - Due to the rapid orbit and tight space it will come from a difficult to discern position and require careful
--     movement to dodge
GoCloneCorral = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		data.CloneCorralRadius = 200
		data.CloneCorralRotation = (npc.Position-data.Target.Position):GetAngleDegrees()
		data.CloneCorralRotationSpeed = 0
		data.CloneCorralShrinkTime = data.bal.CloneCorralShrinkTime
		data.CloneCorralCenterPos = nil
		data.CloneCorralTimeOrbitting = REVEL.GetFromMinMax(data.bal.CloneCorralOrbitingTime)
		data.CloneCorralShootingCounter = math.random(data.bal.CloneCorralShootingDelay.Min, data.bal.CloneCorralShootingDelay.Max)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		local allAtRightPos = true
		local targetPos = data.Target.Position + Vector.FromAngle(data.CloneCorralRotation)*data.CloneCorralRadius
		if (targetPos-npc.Position):LengthSquared() > (data.bal.Speed) ^ 2 then
			npc.Velocity = (targetPos-npc.Position):Resized(data.bal.Speed*2)
			allAtRightPos = false
		else
			npc.Velocity = (targetPos-npc.Position) + data.Target.Velocity
		end
		
		for i,clone in ipairs(data.Clones) do
			targetPos = data.Target.Position + Vector.FromAngle(data.CloneCorralRotation + i*(360/(data.bal.SteamOutNumClonesPhase3+1)))*data.CloneCorralRadius
			if (targetPos-clone.Position):LengthSquared() > (data.bal.Speed) ^ 2 then
				clone.Velocity = (targetPos-clone.Position):Resized(data.bal.Speed*2)
				allAtRightPos = false
			else
				clone.Velocity = (targetPos-clone.Position) + data.Target.Velocity
			end
			
			if (data.Target.Position-clone.Position):LengthSquared() <= 60 ^ 2 then
				clone.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				clone:GetSprite().Color = Color(1,1,1,0.5,conv255ToFloat(1,1,1))
			else
				clone.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				clone:GetSprite().Color = Color(1,1,1,1,conv255ToFloat(1,1,1))
			end
		end
		
		return allAtRightPos
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.CloneCorralShrinkTime = data.CloneCorralShrinkTime - 1
		
		data.CloneCorralRadius = REVEL.Lerp(data.bal.CloneCorralMaxRadius, data.bal.CloneCorralMinRadius, (data.bal.CloneCorralShrinkTime - data.CloneCorralShrinkTime)/data.bal.CloneCorralShrinkTime)
		data.CloneCorralRotationSpeed = REVEL.Lerp(0, data.bal.CloneCorralMaxOrbittingSpeed, (data.bal.CloneCorralShrinkTime - data.CloneCorralShrinkTime)/data.bal.CloneCorralShrinkTime)
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
	
		data.bal.RotateWithClonesAroundTarget(npc, data.Target.Position, data.CloneCorralRotation, data.CloneCorralRadius)
		
		return data.CloneCorralShrinkTime == 0
	end)
	QueueAction(n, d, function(npc, sprite, data)
		--[[if not data.CloneCorralCenterPos then
			data.CloneCorralCenterPos = data.Target.Position
			local lightblue = Color(0,0,0,1,conv255ToFloat(66,206,245))
			
			sprite.Color = lightblue
			
			REVEL.SpawnDecoration(npc.Position, (data.CloneCorralCenterPos - npc.Position):Resized(15), "Idle", "gfx/bosses/revel1/williwaw/williwaw.anm2", nil, 0, 10, nil, nil, 92, nil, lightblue)
			for _,clone in ipairs(data.Clones) do
				clone:GetSprite().Color = lightblue
				REVEL.SpawnDecoration(clone.Position, (data.CloneCorralCenterPos - clone.Position):Resized(15), "Clone Spawn", "gfx/bosses/revel1/williwaw/williwaw.anm2", nil, 0, 10, nil, nil, 92, nil, lightblue)
			end
		else
			sprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
			for _,clone in ipairs(data.Clones) do
				clone:GetSprite().Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
			end
		end]]
		
		if not data.IsCloneCorralShooting and not data.IsCloneCorralIcicleActive then
			data.CloneCorralShootingCounter = data.CloneCorralShootingCounter - 1
			
			if data.CloneCorralShootingCounter == 0 then
				data.IsCloneCorralShooting = true
				sprite:Play("CloneCorral Shoot", true)
				REVEL.sfx:NpcPlay(npc, data.bal.Sfx.SHOOT, data.bal.SfxVolume, 0, false, data.SfxPitch)
				data.CloneCorralShootingCounter = math.random(data.bal.CloneCorralShootingDelay.Min, data.bal.CloneCorralShootingDelay.Max)
				
			elseif math.random(1, 90) == 1 then
				data.IsCloneCorralIcicleActive = true
				sprite:Play("Icicle Pass", true)
				REVEL.sfx:NpcPlay(npc, data.bal.Sfx.SHOOT_ICICLE, data.bal.SfxVolume, 0, false, data.SfxPitch)
			end
		end
		if data.IsCloneCorralShooting then
			if sprite:IsEventTriggered("Shoot") then
				local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, (data.Target.Position-npc.Position):Resized(5), npc):ToProjectile()
				proj.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				proj.Scale = 3
				proj:GetSprite():LoadGraphics()
				proj.FallingAccel = -0.05
				proj.ProjectileFlags = proj.ProjectileFlags | ProjectileFlags.NO_WALL_COLLIDE
			end
			if sprite:IsFinished("CloneCorral Shoot") then
				data.IsCloneCorralShooting = false
				sprite:Play("Idle", true)
			end
		end
		if data.IsCloneCorralIcicleActive then
			if sprite:IsFinished("Icicle Pass") then
				local randomCloneId = math.random(#data.Clones)
				data.CloneCorralRotation = data.CloneCorralRotation + randomCloneId*(360/(data.bal.SteamOutNumClonesPhase3+1))
				
				local williPositions = {}
				local numClones = #data.Clones
				williPositions[numClones + 2 - randomCloneId] = {Position = npc.Position, Velocity = npc.Velocity}
				for i,clone in ipairs(data.Clones) do
					williPositions[(numClones + 1 + i - randomCloneId)%(numClones + 1) + 1] = {Position = clone.Position, Velocity = clone.Velocity}
				end
				
				npc.Position = williPositions[1].Position
				npc.Velocity = williPositions[1].Velocity
				for i,clone in ipairs(data.Clones) do
					clone.Position = williPositions[i + 1].Position
					clone.Velocity = williPositions[i + 1].Velocity
				end
				
				sprite:Play("Icicle Get", true)
				REVEL.sfx:NpcPlay(npc, data.bal.Sfx.RECEIVE_ICICLE, data.bal.SfxVolume, 0, false, data.SfxPitch)
			end
			if sprite:IsFinished("Icicle Get") then
				data.IsCloneCorralIcicleActive = false
				sprite:Play("Idle", true)
			end
		end
		
		data.CloneCorralTimeOrbitting = data.CloneCorralTimeOrbitting - 1
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		
		data.bal.RotateWithClonesAroundTarget(npc, data.Target.Position, data.CloneCorralRotation, data.CloneCorralRadius)
		
		return data.CloneCorralTimeOrbitting <= 0 and not data.IsCloneCorralShooting and not data.IsCloneCorralIcicleActive
	end)
end,
RotateWithClonesAroundTarget = function(npc, centerPos, rotation, radius, numClones)
	local targetPos = centerPos + Vector.FromAngle(rotation)*radius
	local data = REVEL.GetData(npc)
	npc.Velocity = (targetPos-npc.Position) * 0.2
	if numClones then
		for i=1, numClones do
			local clone = REVEL.GetData(npc).Clones[i]
			if clone and clone:Exists() then
				targetPos = centerPos + Vector.FromAngle(rotation + i*(360/(data.bal.SteamOutNumClonesPhase3+1)))*radius
				clone.Velocity = (targetPos-clone.Position) * 0.2
			end
		end
	else
		for i,clone in ipairs(REVEL.GetData(npc).Clones) do
			targetPos = centerPos + Vector.FromAngle(rotation + i*(360/(data.bal.SteamOutNumClonesPhase3+1)))*radius
			clone.Velocity = (targetPos-clone.Position) * 0.2
		end
	end
end,

-- Gateway Sniping
-- - From Clone Corral, all Williwaws slow down as Williwaw prime charges up like in Snowflake Sniping
-- - Williwaw prime flings his icicle into the air and bursts into the SS formation but following the current orbit
-- - These snowflakes cover the same or greater size than Williwaw prime
--   - you still cannot escape without killing a few and dodging through them
-- - The remaining clones (and snowflake center) slowly close in, restricting the player space until they manage to kill
--   the snowflakes and escape
-- - After 3-4s or the player escapes, Williwaw’s icicle falls into the center of the snowflakes and Williwaw reforms like
--   in SS
-- - After reform, all Williwaws quickly move inward, shrinking the circle
--   - Causes unavoidable damage to any player that did not escape through the snowflakes
GoGatewaySniping = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		data.GatewaySnipingSlowdownTime = data.bal.GatewaySnipingSlowdownTime
		
		data.CloneCorralCenterPos = data.Target.Position
		local lightblue = Color(0,0,0,1,conv255ToFloat(66,206,245))
		
		sprite.Color = lightblue
		
		REVEL.SpawnDecoration(npc.Position, (data.CloneCorralCenterPos - npc.Position):Resized(15), "Idle", "gfx/bosses/revel1/williwaw/williwaw.anm2", nil, 0, 10, nil, nil, 92, nil, lightblue)
		for _,clone in ipairs(data.Clones) do
			clone:GetSprite().Color = lightblue
			REVEL.SpawnDecoration(clone.Position, (data.CloneCorralCenterPos - clone.Position):Resized(15), "Clone Spawn", "gfx/bosses/revel1/williwaw/williwaw.anm2", nil, 0, 10, nil, nil, 92, nil, lightblue)
		end

		for _, player in ipairs(REVEL.players) do
			player:SetColor(lightblue, 60, 1, true, false)
		end
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.GatewaySnipingSlowdownTime = data.GatewaySnipingSlowdownTime - 1
		
		sprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
		for _,clone in ipairs(data.Clones) do
			clone:GetSprite().Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
		end

		for _, player in ipairs(REVEL.players) do
			player.Velocity = player.Velocity * 0.25
		end
		
		data.CloneCorralRotationSpeed = REVEL.Lerp(data.bal.CloneCorralMaxOrbittingSpeed, data.bal.GatewaySnipingOrbittingSpeed, (data.bal.GatewaySnipingSlowdownTime - data.GatewaySnipingSlowdownTime)/data.bal.GatewaySnipingSlowdownTime)
		data.CloneCorralRadius = REVEL.Lerp(data.bal.CloneCorralMinRadius, data.bal.GatewaySnipingSnowflakeAttackMaxRadius, (data.bal.GatewaySnipingSlowdownTime - data.GatewaySnipingSlowdownTime)/data.bal.GatewaySnipingSlowdownTime)
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
		return data.GatewaySnipingSlowdownTime <= 0
	end)
	QueueAction(n, d, function(npc, sprite, data)
		sprite:Play('Snowflake Sniping Explode', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.SNOWFLAKE_SNIPE, data.bal.SfxVolume, 0, false, data.SfxPitch)
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if sprite:IsEventTriggered('Icicle') then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.SnowflakeTimer = data.bal.GatewaySnipingSnowflakeTime

            data.Snowflakes = {}
            for i = 1, data.bal.GatewaySnipingFlakeCount do
				local snowflake = REVEL.SpawnOrbitingFlake(npc, false, 1, npc.Position, 20, false, 50, true, 10)
				snowflake.MaxHitPoints = data.bal.SnowflakeHitPoints
				snowflake.HitPoints = snowflake.MaxHitPoints

                table.insert(data.Snowflakes, snowflake)
            end
			
			--[[for _,clone in ipairs(data.Clones) do
				REVEL.GetData(clone).Snowflakes = {}
				for i = 1, data.bal.GatewaySnipingCloneFlakeCount do
					table.insert(REVEL.GetData(clone).Snowflakes,
						REVEL.SpawnOrbitingFlake(clone, false, 1, clone.Position, 20, false, 40, true, 10))
				end
			end]]
        end
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)

        return sprite:IsFinished('Snowflake Sniping Explode')
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.SnowflakeTimer = data.SnowflakeTimer - 1
	
		data.CloneCorralRadius = REVEL.Lerp(data.bal.GatewaySnipingSnowflakeAttackMaxRadius, data.bal.GatewaySnipingSnowflakeAttackMinRadius, (data.bal.GatewaySnipingSnowflakeTime - data.SnowflakeTimer)/data.bal.GatewaySnipingSnowflakeTime)
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
		return data.SnowflakeTimer <= 0 or (data.Target.Position-data.CloneCorralCenterPos):LengthSquared() >= (data.bal.GatewaySnipingSnowflakeAttackMaxRadius + 10) ^ 2
	end)
	QueueAction(n, d, function(npc, sprite, data)
		sprite:Play('Snowflake Sniping Reform', true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.REFORM, data.bal.SfxVolume, 0, false, data.SfxPitch)
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
		
		if sprite:IsEventTriggered('Land') then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

            for _, snowflake in pairs(data.Snowflakes) do
                local sdata = REVEL.GetData(snowflake)
                sdata.MoveState = nil
                sdata.State = 'dummy'
				snowflake.Velocity = (npc.Position - snowflake.Position):Resized(5)
                REVEL.DelayFunction(function() snowflake:Remove() end, 11, nil, true)
            end
			--[[for _,clone in ipairs(data.Clones) do
				for _, snowflake in pairs(REVEL.GetData(clone).Snowflakes) do
					local sdata = REVEL.GetData(snowflake)
					sdata.MoveState = nil
					sdata.State = 'dummy'
					snowflake.Velocity = (clone.Position - snowflake.Position):Resized(5)
					REVEL.DelayFunction(function() snowflake:Remove() end, 11, nil, true)
				end
			end]]
			
		elseif sprite:WasEventTriggered('Land') then
			for _, snowflake in pairs(data.Snowflakes) do
				if snowflake:Exists() then
					snowflake.Position = snowflake.Position + npc.Velocity
				end
			end
			--[[for _,clone in ipairs(data.Clones) do
				for _, snowflake in pairs(REVEL.GetData(clone).Snowflakes) do
					if snowflake:Exists() then
						snowflake.Position = snowflake.Position + clone.Velocity
					end
				end
			end]]
		end

        return sprite:IsFinished('Snowflake Sniping Reform')
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.CloneCorralRadius = data.CloneCorralRadius - 4
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.CloneCorralCenterPos, data.CloneCorralRotation, data.CloneCorralRadius)
		data.Snowflakes = {}
		--[[for _,clone in ipairs(data.Clones) do
			local cdata = REVEL.GetData(clone)
			cdata.Snowflakes = {}
			cdata.Orbiters = {}
			cdata.NumOrbiters = 0
		end]]
		data.Orbiters = {}
		data.NumOrbiters = 0
		
		return data.CloneCorralRadius <= data.bal.GatewaySnipingMinRadius
	end)
end,

-- Intro:
-- - Icicle is floating in the middle of the room
-- - Several invulnerable snowflakes fly in toward it from outside the screen, getting absorbed when they touch it
-- - When ~5 have reached it, he forms
GoIntro = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		data.ShakeDelay = 0
		data.Snowflakes = {}
		data.TotalSnowflakesAbsorbed = 0
		data.FadeOutSnowflakesTime = data.bal.IntroFadeOutSnowflakesTime
		data.IntroPosition = npc.Position

		sprite:Play("Spawn Idle", true)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.ShakeDelay = data.ShakeDelay + 1
		
		npc.Velocity = data.IntroPosition - npc.Position
		
		return data.bal.IntroShakeDelay < data.ShakeDelay
	end)
	QueueAction(n, d, function(npc, sprite, data)
		sprite:Play("Spawn Snowflake", true)
		npc.Velocity = data.IntroPosition - npc.Position
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.INTRO_SHAKING, data.bal.SfxVolume, 0, false, data.SfxPitch)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if npc.FrameCount%data.bal.IntroSnowflakeInterval == data.bal.IntroSnowflakeInterval - 1 then
			local angle = math.random(0, 359)
			local snowflake = REVEL.SpawnNoChampion(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, npc.Position + Vector.FromAngle(angle)*420, Vector.FromAngle(angle-180)*data.bal.IntroSnowflakeSpeed, npc)
			snowflake:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			snowflake:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
			REVEL.GetData(snowflake).MoveState = "Projectile"
			REVEL.GetData(snowflake).State = "Projectile"
			REVEL.GetData(snowflake).MaxMarginOutsideRoom = -10000
			snowflake.MaxHitPoints = 0
			snowflake.HitPoints = 0
			
			table.insert(data.Snowflakes, snowflake)
		end
		
		for i,snowflake in ipairs(data.Snowflakes) do
			snowflake.Velocity = (npc.Position - snowflake.Position):Resized(data.bal.IntroSnowflakeSpeed)
			if (snowflake.Position-npc.Position):LengthSquared() <= (data.bal.IntroSnowflakeSpeed*0.5) ^ 2 then
				snowflake:Remove()
				npc.HitPoints = npc.HitPoints + npc.MaxHitPoints / (data.bal.IntroNumSnowflakesNeeded*2)
				table.remove(data.Snowflakes, i)
				data.TotalSnowflakesAbsorbed = data.TotalSnowflakesAbsorbed + 1
				
				if data.TotalSnowflakesAbsorbed == data.bal.IntroNumSnowflakesNeeded - 1 then -- quickfix to get the intro timing right
					REVEL.sfx:NpcPlay(npc, data.bal.Sfx.INTRO, data.bal.SfxVolume, 0, false, data.SfxPitch)
				end
				
				break
				
			elseif (snowflake.Position-npc.Position):LengthSquared() <= 30 ^ 2 then
				snowflake:GetSprite().Color = Color(1, 1, 1, (snowflake.Position-npc.Position):Length()/30,conv255ToFloat( 0, 0, 0))
			end
		end
					
		npc.Velocity = data.IntroPosition - npc.Position

		return data.TotalSnowflakesAbsorbed >= data.bal.IntroNumSnowflakesNeeded
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.FadeOutSnowflakesTime = data.FadeOutSnowflakesTime - 1
		
		for _,snowflake in ipairs(data.Snowflakes) do
			snowflake:GetSprite().Color = Color(1, 1, 1, data.FadeOutSnowflakesTime*0.1,conv255ToFloat( 0, 0, 0))
		end
					
		npc.Velocity = data.IntroPosition - npc.Position

		return data.FadeOutSnowflakesTime == 1
	end)
	QueueAction(n, d, function(npc, sprite, data)
		for _,snowflake in ipairs(data.Snowflakes) do
			snowflake:Remove()
		end
		data.Snowflakes = {}
		sprite:Play("Spawn Start", true)
					
		npc.Velocity = data.IntroPosition - npc.Position
	end)
	QueueAction(n, d, function(npc, sprite, data)		
		npc.Velocity = data.IntroPosition - npc.Position

		local isDone = sprite:IsFinished("Spawn Start", true)
		if isDone then
			data.IntroPosition = nil
		end

		return isDone
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.CurrentPhase = "Snow & Steady"
		data.FullyEnteredPhase = 0
	end)
end,
GoCloneIntro = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		sprite:Play("Clone Spawn", true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.CLONE_CREATED, data.bal.SfxVolume, 0, false, data.SfxPitch)
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end)
	QueueAction(n, d, function(npc, sprite, data)
		if sprite:IsEventTriggered("Land") then
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		end
		
		return sprite:IsFinished("Clone Spawn")
	end)
end,

-- Death
-- - Williwaw and his clones orbit rapidly like in Clone Corral as their forms disintegrate
-- - Williwaw prime disintegrates last
-- - His icicle falls to the ground and shatters, ending the fight
GoDeath = function(n, s, d)
	QueueAction(n, d, function(npc, sprite, data)
		data.DeathTimer = 0
		data.NumClones = #data.Clones
		data.CloneCorralRadius = data.CloneCorralRadius or 200
		data.CloneCorralRotation = data.CloneCorralRotation or (npc.Position-data.Target.Position):GetAngleDegrees()
		data.CloneCorralRotationSpeed = data.CloneCorralRotationSpeed or 0
		--data.CloneCorralCenterPos = data.CloneCorralCenterPos or data.Target.Position
		data.ShockLevel = 0
		
		npc.CollisionDamage = 0
		for _,clone in ipairs(data.Clones) do
			clone.CollisionDamage = 0
		end
		
		if data.Snowflakes then
			for i,snowflake in pairs(data.Snowflakes) do
				snowflake:Die()
			end
			data.Snowflakes = nil
		end
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.Target.Position, data.CloneCorralRotation, data.CloneCorralRadius, data.NumClones)
	end)
	QueueAction(n, d, function(npc, sprite, data)
		data.DeathTimer = data.DeathTimer + 1
		
		if data.CloneCorralRotationSpeed ~= data.bal.DeathMaxOrbittingSpeed then
			data.CloneCorralRotationSpeed = math.max(math.min(data.bal.DeathMaxOrbittingSpeed, data.CloneCorralRotationSpeed + data.bal.DeathOrbitAcceleration), data.CloneCorralRotationSpeed - data.bal.DeathOrbitAcceleration)
		end
		
		local aliveClones = {}
		for i=1, data.NumClones do
			local clone = data.Clones[i]
			if clone then
				if not clone:Exists() then
					data.Clones[i] = nil
					
				elseif not clone:IsDead() and not REVEL.GetData(clone).IsDying then
					table.insert(aliveClones, clone)
				end
			end
		end
		
		if data.DeathTimer%data.bal.CloneDeathInterval == 1 then
			local numAliveClones = #aliveClones
			if numAliveClones ~= 0 then
				local clone = aliveClones[math.random(numAliveClones)]
				
				if numAliveClones == 1 then
					clone:GetSprite():Play("DeathClone03", true)
				else
					clone:GetSprite():Play("DeathClone0102", true)
				end
				REVEL.sfx:NpcPlay(clone:ToNPC(), data.bal.Sfx.DEATH_CLONE, data.bal.SfxVolume, 0, false, data.SfxPitch)
				clone:ToNPC().State = NpcState.STATE_UNIQUE_DEATH
				REVEL.GetData(clone).IsDying = true
				data.ShockLevel = math.min(data.ShockLevel + 1, 4)
			end
			
			if data.ShockLevel > 0 then
				npc:GetSprite():Play("Shock0" .. tostring(data.ShockLevel), true)
				for i=1, data.NumClones do
					local clone = data.Clones[i]
					if clone and not REVEL.GetData(clone).IsDying and not clone:IsDead() and clone:Exists() then
						REVEL.GetData(clone).DisableIdleAnimation = true
						clone:GetSprite():Play("Shock0" .. tostring(data.ShockLevel), true)
					end
				end
			end
		end
		
		data.CloneCorralRotation = data.CloneCorralRotation + data.CloneCorralRotationSpeed
		data.bal.RotateWithClonesAroundTarget(npc, data.Target.Position, data.CloneCorralRotation, data.CloneCorralRadius, data.NumClones)
		
		return data.DeathTimer >= data.bal.CloneDeathInterval * data.NumClones 
	end)
	QueueAction(n, d, function(npc, sprite, data)
		npc.Velocity = Vector.Zero
		npc.Position = REVEL.room:GetClampedPosition(npc.Position, npc.Size)
		
		sprite:Play("DeathMain", true)
		REVEL.sfx:NpcPlay(npc, data.bal.Sfx.DEATH, data.bal.SfxVolume, 0, false, data.SfxPitch)
		npc.State = NpcState.STATE_UNIQUE_DEATH
	end)
end,

--[[Snow & Steady:
- Perform either 2-3 sets of Rain Dash or performs Slow Drizzle, then performs whichever wasn’t performed first.
- Perform Beast Winds
- Repeat
- At 60% HP, perform Cracked, then Steam Out, spawning one clone

Fast & Flurrious
- Williwaw and his clone perform 1-2 synchronized Rain Dashes
- Williwaw prime performs Snowflake Sniping
  - Clone performs more Rain Dashes or Slow Drizzle
- Clone then performs Beast Winds
  - Williwaw prime performs Snowflake Sniping and Rain Dash occasionally until it ends
- Repeat
- At 15% HP, perform Steam Out, spawning three more clones; Williwaw now has 4 clones

Snow Clone
- Perform Clone Corral for 6-8 seconds
- Perform Gateway Sniping
- Repeat until death


    ]]

    GoIdle = function(n, s, d)
        QueueAction(n, d, function(npc, sprite, data)
			if not data.DisableIdleAnimation and not sprite:IsPlaying("Idle", true) then
				sprite:Play("Idle", true)
			end
            --data.IdleWait = math.random(data.bal.IdleWaitMin, data.bal.IdleWaitMax)
        end)
		QueueAction(n, d, function(npc, sprite, data)
			-- Shouldn't be out of room when idle
			if (not data.IsWilliwawClone and not REVEL.room:IsPositionInRoom(npc.Position, -npc.Size)) or data.GoBackToRoom then
				npc.Velocity = (REVEL.room:GetCenterPos() - npc.Position):Resized(data.bal.Speed * 2)
				if not data.GoBackToRoom then
					data.GoBackToRoom = true
				elseif REVEL.room:IsPositionInRoom(npc.Position, npc.Size + 60) then
					data.GoBackToRoom = nil
				end
			end

			if data.IdleWait then
				data.IdleWait = data.IdleWait - 1
				if data.IdleWait <= 0 then
					data.IdleWait = nil 
				end
			end
            return not data.IdleWait and not data.GoBackToRoom
        end)
        QueueAction(n, d, function(npc, sprite, data)
			if data.CurrentPhase == "Snow & Steady" and npc.HitPoints/npc.MaxHitPoints <= data.bal.HpPctPhase1 then
				data.CurrentPhase = "Fast & Flurrious"
				data.didBeastWinds = nil
				data.ActionQueue = {}
				QueueAction(npc, data, 'GoCracked')
				QueueAction(npc, data, 'GoSteamOut')
			end
			if data.CurrentPhase == "Fast & Flurrious" and npc.HitPoints/npc.MaxHitPoints <= data.bal.HpPctPhase2 then
				data.CurrentPhase = "Snow Clone"
				data.IdleWait = nil
				data.ActionQueue = {}
				QueueAction(npc, data, 'GoSteamOut')
				data.bal.AddIdleWait(npc, data, nil)
			end
			if data.IsWilliwawClone and data.CurrentPhase ~= "Snow Clone" and REVEL.GetData(npc.Parent).CurrentPhase == "Snow Clone" then
				data.CurrentPhase = "Snow Clone"
				data.IdleWait = nil
				data.ActionQueue = {}
			end

			-- --I think this is a good way to do it, shouldn't break anything afaik?
			-- if data.AdditionalAttackCooldown then
			-- 	data.AdditionalAttackCooldown = data.AdditionalAttackCooldown - 1
			-- 	if data.AdditionalAttackCooldown <= 0 then
			-- 		data.AdditionalAttackCooldown = nil
			-- 	else
			-- 		return
			-- 	end
			-- end

			if data.ActionQueue[1] == nil and data.CurrentAttacks[1] then
				if #data.RecentAttacks > 3 then
					table.remove(data.RecentAttacks)
				end

				local weights = {}
				local attacks = {}
				for attack, weight in pairs(data.CurrentAttacks) do
					weights[attack] = weight
					table.insert(attacks, attack)
				end

				for i, attack in ipairs(data.RecentAttacks) do
					weights[attack] = weights[attack] * 0.8 / i
				end

				-- select the attack
				if REVEL.isEmpty(attacks) then
					error('Empty attacks table!')
				end

				local r = math.random(0, 10 * #attacks)
				local attackPicked
				repeat
					for attack, weight in pairs(weights) do
						weight = weight * 10
						if r < weight then
							attackPicked = attack
							break
						end
						r = r - weight
					end
				until r < 0 or attackPicked

				attackPicked = attackPicked or attacks[1]

				QueueAction(npc, data, 'Go' .. attackPicked)
				table.insert(data.RecentAttacks, 1, attackPicked)
			end
			
			if data.CurrentPhase == "Snow & Steady" and data.ActionQueue[1] == nil then
				if math.random(1,2) == 1 then
					QueueAction(npc, data, 'GoSlowDrizzle')
					QueueAction(npc, data, 'GoIdle')
					for i=1, math.random(2,3) do
						QueueAction(npc, data, 'GoRainDash')
						QueueAction(npc, data, 'GoIdle')
					end
				else
					for i=1, math.random(2,3) do
						QueueAction(npc, data, 'GoRainDash')
						QueueAction(npc, data, 'GoIdle')
					end
					QueueAction(npc, data, 'GoSlowDrizzle')
					QueueAction(npc, data, 'GoIdle')
				end
				
				if not data.didBeastWinds then
					QueueAction(npc, data, 'GoBeastWinds')
					data.didBeastWinds = true
				end
				
				return
			end
			
			if data.CurrentPhase == "Fast & Flurrious" and data.ActionQueue[1] == nil and not data.IsWilliwawClone then
				for i=1, math.random(1,2) do
					QueueAction(npc, data, 'GoRainDash')
					data.bal.AddIdleWait(npc, data, REVEL.GetFromMinMax(data.bal.IdleWaitWithClone))
					QueueAction(npc, data, 'GoIdle')

					QueueAction(data.Clones[1], REVEL.GetData(data.Clones[1]), 'GoRainDash')
					data.bal.AddIdleWait(data.Clones[1], REVEL.GetData(data.Clones[1]), REVEL.GetFromMinMax(data.bal.IdleWaitWithClone))
					QueueAction(data.Clones[1], REVEL.GetData(data.Clones[1]), 'GoIdle')
				end
				
				QueueAction(npc, data, 'GoSnowflakeSniping')
				data.bal.AddIdleWait(npc, data, REVEL.GetFromMinMax(data.bal.IdleWaitWithClone))

				REVEL.GetData(data.Clones[1]).CurrentAttacks = {['RainDash'] = 1, ['SlowDrizzle'] = 1}
				data.bal.AddIdleWait(data.Clones[1], REVEL.GetData(data.Clones[1]), REVEL.GetFromMinMax(data.bal.IdleWaitWithClone))
				
				table.insert(data.ActionQueue, function()
					REVEL.GetData(data.Clones[1]).CurrentAttacks = {}
					data.CurrentAttacks = {['SnowflakeSniping'] = 1, ['RainDash'] = 1}
					data.bal.AddIdleWait(npc, data, REVEL.GetFromMinMax(data.bal.IdleWaitWithClone))
					QueueAction(data.Clones[1], REVEL.GetData(data.Clones[1]), 'GoBeastWinds')
					table.insert(REVEL.GetData(data.Clones[1]).ActionQueue, function()
						data.CurrentAttacks = {}
					end)
				end)
			end
			
			if data.CurrentPhase == "Snow Clone" and data.ActionQueue[1] == nil and not data.IsWilliwawClone then
				local clonesAreReady = true
				for i, clone in ipairs(data.Clones) do
					if REVEL.GetData(clone).ActionQueue[3] then
						clonesAreReady = false
						break
					end
				end

				if clonesAreReady then
					QueueAction(npc, data, 'GoCloneCorral')
					QueueAction(npc, data, 'GoGatewaySniping')
				else 
					return false --wait for clones to be ready, fixes a hang in regrouping 
				end
			end
						
			-- REVEL.DebugLog(data.CurrentPhase, data.IsWilliwawClone, data.IdleWait, data.ActionQueue)
        end)
	end,
	AddIdleWait = function(n, d, time)
		--double insert cause its supposed to be called inbetween inserting GoX into queue, which themselves insert things into queue
		QueueAction(n, d, function(npc, sprite, data)
			table.insert(data.ActionQueue, function(npc2, sprite2, data2)
				data2.IdleWait = time
			end)
        end)
	end,
}

local function GetFunctionInfo(func)
	if not func then
		error("GetFunctionInfo: func nil", 2)
	end
	if debug then
		local info = debug.getinfo(func)
		local src_name = string.gsub(info.short_src, '\\', '/')
		local thirdLastSlashIndex = (src_name:match('^.*()/.+/.+/') or 0) + 1
		local name = string.sub(src_name, thirdLastSlashIndex, #src_name)
		return name .. " @line:" .. info.linedefined
	end
	return tostring(func)
end 

local function PrintFunctionInfo(func, context)
	if debug then
		REVEL.DebugToString((context or "") .. ": Running: '" .. GetFunctionInfo(func) .. "'")
	end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.WILLIWAW:isEnt(npc) then return end

    local sprite = npc:GetSprite()
    local d = REVEL.GetData(npc)

    if not d.init then
        --npc.SpriteOffset = Vector(0,-5)

        d.bal = REVEL.WilliwawBalance
        d.ActionQueue = {}
        d.RecentAttacks = {}
        d.CurrentAction = nil
		d.CurrentPhase = "Intro"
		d.WanderSide = "Vertical"

        d.Phase = 1
        d.CurrentAttacks = {}

        d.TargetPositions = {}

        d.FreezeAuras = {}
		
		d.Clones = {}

        npc.Mass = d.bal.Mass
        npc.Friction = d.bal.BaseFriction
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		
		d.SfxPitch = 1
		
		if not d.IsWilliwawClone then
			REVEL.SetScaledBossHP(npc)
			npc.HitPoints = npc.MaxHitPoints*0.5
			npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
			d.bal.GoIntro(npc, sprite, d)
			d.BeastWindsTimeBetweenPatterns = d.bal.BeastWindsTimeBetweenPatterns
		else
			d.bal.GoCloneIntro(npc, sprite, d)
			d.BeastWindsTimeBetweenPatterns = d.bal.BeastWindsTimeBetweenPatterns + (d.bal.BeastWindsTimeBetweenPatterns*0.25)
			d.SfxPitch = d.bal.CloneSoundPitch
		end

        d.init = true
    end
	
    REVEL.ApplyKnockbackImmunity(npc, true)

	d.Target = npc:GetPlayerTarget()
	
	--Fallback in case willywaw dies unexpectedly
	if d.IsWilliwawClone and not (npc.Parent and npc.Parent:Exists()) then
		sprite:Play("DeathClone0102", true)
		npc.State = NpcState.STATE_UNIQUE_DEATH
		d.IsDying = true
		return
	end

    for _, aura in pairs(d.FreezeAuras) do
        REVEL.FreezeAura(aura, true, true)
    end

    table.insert(d.TargetPositions, 1, d.Target.Position)
	d.TargetPositions[d.bal.MaxTrackingFrames + 1] = nil

    if #d.ActionQueue == 0 then
		QueueAction(npc, d, 'GoIdle')
    end

    if d.CurrentAction == nil then
        d.CurrentAction = table.remove(d.ActionQueue, 1)
    end

	local previousVelocity = REVEL.CloneVec(npc.Velocity)
	local previousPosition = REVEL.CloneVec(npc.Position)

	-- PrintFunctionInfo(d.CurrentAction, ("Current action %s"):format(d.IsWilliwawClone and "(clone)" or "       "))

	local repeatAction = d.CurrentAction(npc, sprite, d) == false

	-- REVEL.DebugStringMinor("Action done")

	--[[
	-- if position didn't change, forcefully hold it to avoid knockback item bugs
	if previousPosition:DistanceSquared(npc.Position) < 0.01 
	and (previousVelocity:DistanceSquared(npc.Velocity) < 0.01 and previousVelocity:LengthSquared() < 0.01) then
		npc.Velocity = npc.Velocity * 0.5
		npc.Position = previousPosition
	end
	]]

    if not repeatAction then
        d.CurrentAction = nil
    end
	
	if d.Snowflakes then -- check for snowflakes that died, damages Williwaw
		for i,snowflake in pairs(d.Snowflakes) do
			if snowflake:IsDead() and snowflake:Exists() then
				npc:TakeDamage(npc.MaxHitPoints * d.bal.SnowflakeDeathPctDmg, 0, EntityRef(snowflake), 0)
				table.remove(d.Snowflakes, i)
				break
			end
		end
	end
end, REVEL.ENT.WILLIWAW.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg, flags, src, invuln)
	if ent.Variant ~= REVEL.ENT.WILLIWAW.variant then return end
	local data = REVEL.GetData(ent)

	if not data.FullyEnteredPhase and ent.FrameCount > 200 then
		data.FullyEnteredPhase = 3
	end
	
	if data.IsDying then
		return false
		
	elseif (not data.FullyEnteredPhase)
	or (ent.HitPoints/ent.MaxHitPoints <= data.bal.HpPctPhase1 and data.FullyEnteredPhase < 1)
	or (ent.HitPoints/ent.MaxHitPoints <= data.bal.HpPctPhase2 and data.FullyEnteredPhase < 2) then
		local dmgReduction = dmg*0.6
		ent.HitPoints = math.min(ent.HitPoints + dmgReduction, ent.MaxHitPoints)
	
	elseif data.FullyEnteredPhase == 3 then
		dmg = dmg*3
	end
	
	if ent.HitPoints - dmg - REVEL.GetDamageBuffer(ent) <= 0 then
		data.IsDying = true
		data.ActionQueue = {}
		data.CurrentAction = nil
		QueueAction(ent, data, 'GoDeath')
		ent.HitPoints = REVEL.GetDamageBuffer(ent) + dmg + 1
	end
end, REVEL.ENT.WILLIWAW.id)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	REVEL.sfx:Stop(REVEL.WilliwawBalance.Sfx.BLOW_LOOP)
	REVEL.sfx:Stop(REVEL.WilliwawBalance.Sfx.CREATE_CLONE)
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
	if ent.Variant ~= REVEL.ENT.WILLIWAW.variant then return end
	
	REVEL.sfx:Stop(REVEL.WilliwawBalance.Sfx.BLOW_LOOP)
	REVEL.sfx:Stop(REVEL.WilliwawBalance.Sfx.CREATE_CLONE)
end, REVEL.ENT.WILLIWAW.id)

-- Debugging by reloading ingame
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, function()
    local wills = REVEL.ENT.WILLIWAW:getInRoom()

	for _, npc in ipairs(wills) do
        REVEL.GetData(npc).bal = REVEL.GetBossBalance(REVEL.WilliwawBalance, "Default") --change when adding champion
	end
end)

end