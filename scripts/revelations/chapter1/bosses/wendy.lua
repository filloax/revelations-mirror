local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevSettings       = require("scripts.revelations.common.enums.RevSettings")

return function()

REVEL.WendyStormOverlayActive = false
REVEL.WendyInRoomLoad = false
REVEL.WendyStormFadingoutTimer = 0

--[[ Wendy States:
	-- Snow Stalking --
		wendy starts off in this phase. she'll aimlessly walks around the room, invisibly, only detectable by her footprints
	-- Dash --
		after a while snow stalking wendy will set herself up for a surprise dash attack, horizontally aligning herself with the player and stopping her dash just before hitting the wall
	-- Hide And Seek --
		after that dash, wendy goes to the snowpiles, destroying them to reveal some enemies, or if it's the last remaining snowpile she'll hide in it
	-- Hiding In Snowpile --
		while hiding in the snowpile there is a snowstorm going on, the snowstorm stops when all snowpile enemies are killed and the player will have to attack the right snowpile.
		if the player chooses the wrong snowpile wendy will do a dangerous snowball attack towards the player, if the player chooses the right snowpile, wendy will be stunned. wendy will return to snow stalking either way
	-- Spikey Time --
		at 2/3 health wendy will begin to pound the ground, uncovering stalagmites which gets pulled up every groundpound. when fully uncovered they damage the player and block tears. wendy will go back to snow stalking
	-- Whirlwind (snowballs) --
		at 1/3 health wendy will spin around like crazy forming a whirlwind. the snowpiles get destroyed revealing many snowballs which get pulled into the whirlwind.
		depending on the amount of snowballs absorbed wendy will fire out snowballs in all directions. when all snowballs are consumed wendy will start going for the stalagmites
	-- Whirlwind (stalagmites) --
		wendy will go from stalagmite to stalagmite, sucking them up and shortly after firing them as projectiles straight towards the player.
		when all stalagmites are fired off wendy will go back to spikey time but in whirlwind form, after which she will activate her whirlwind phase again, constantly looping between the two
]]

REVEL.WendyBalance = {
	Champions = {Chocolate = "Default"},
	Skin = {Default = "", Chocolate = "gfx/bosses/revel1/wendy/Wendy_Chocolate.png"},
	MaxHP = {Default = 250, Chocolate = 166},
	
	DistanceWalkedBeforeFootprint = 50,
	DistanceFeetToCenterBody = 20,
	FootprintFramesUntilFadeOut = 30,
	DamageReductionOnSneak = 0.5, -- 0 is no dmg reduction, 1 is full damage reduction
	
	FramesSneakingBeforeDash = 80,
	DashDistanceFromWallBeforeStopping = 100,
	DashVelocity = 20,
	
	VelocityKeptWhileSneaking = 0.8,
	SneakingVelocity = 1.6,
	PlayerAvoidanceVelocity = 0.15,
	
	StunDuration = 105,
	
	SnowballVariant = ProjectileVariant.PROJECTILE_TEAR,
	SnowballSpritesheet = "gfx/effects/revel1/snowball_projectiles.png",
	SnowballsInSnowpile = {
		Default = function() return math.random(10,15) end,
		Chocolate = function() return math.random(5,6) end
	},
	SnowballsInSnowpileMaxHeight = 40,
	SnowballKeptVelocityToWhirlwind = 0.8,
	SnowballVelocityToWhirlwind = 1.7,
	FramesBeforeSnowballFired = {Default=4, Chocolate=9},
	FramesBeforeSnowballAttack = 30,
	SnowballVelocity = {
		Default = function() return math.random(7,11) end,
		Chocolate = function() return math.random(7,9) end
	},
	NumSnowballsWendySnowpileAttack = function() return math.random(15,20) end,
	SnowballsWendySnowpileAttackVelocity = function() return math.random(15,21) end,
	SnowballsWendySnowpileAttackAngleOffset = 8,
	
	WhirlwindDistanceFromCenter = 30,
	WhirlwindKeptVelocity = 0.92,
	WhirlwindVelocity = 0.65,

	NumStalagmites = 6,
	StalagmiteProjVelocity = 12,
	StalagmiteProjHeight = 16,
	
	SnowpileMaxHP = {Default = 60, Chocolate = 42},
	SnowpileRegenTime = {Default = 90, Chocolate = -1},
	PostSnowstormSnowpileDmgMult = {Default = 10, Chocolate = 1},
	
	-- Champion only
	StrawberrySnowballSpritesheet = "gfx/effects/revel1/snowball_strawberry_projectiles.png",
	PissSnowballSpritesheet = "gfx/effects/revel1/snowball_piss_projectiles.png",
	ChocolateSnowballSpritesheet = "gfx/effects/revel1/snowball_chocolate_projectiles.png",
	SnowpileStrawberrySprite = "gfx/bosses/revel1/wendy/Wendy_Strawberry_Snowpile.png",
	SnowpilePissSprite = "gfx/bosses/revel1/wendy/Wendy_Piss_Snowpile.png",
	
	ChampionHealSnowPilePercentage = 0.75,
	ChampionNumDipsInSnowpile = function() return 3 end,
	ChampionWhiteIceCreamShotFrequency = 5,
	NumStrawberryProjectiles = 6,
	ChampionStrawberryIceCreamShotFrequency = 60,
	StrawberryVolleyRadius = 80,
	NumPissShots = 6,
	PissLineStartPosDistanceFromTarget = function() return math.random(40,80) end,
	PissLineLength = function() return math.random(160,200) end,
	PissLineShotFrequency = 3,
	ChampionPissIceCreamLineFrequency = 60,
	
	NumChocolateShotsInWhirlwind = 9,
	ChampionWhirlwindShotAngleOffset = 10,
	
	IceCreamShowerNumLooseProjectiles = function() return math.random(5,7) end,
	IceCreamShowerProjectileStartingHeight = -700,
	IceCreamShowerProjectileFallingAccel = function() return 1 + math.random() end,
	IceCreamShowerProjectileVelocity = function() return math.random()*0.5 end,
	IceCreamShowerMaxProjectileRadiusFromTarget = 25,
	IceCreamShowerSnowPileRegenTime = 20,

	Sounds = {
		GroundPound = {Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS},
		-- Vanish = {Sound = SoundEffect.SOUND_MONSTER_ROAR_1},
		DashStart = {Sound = REVEL.SFX.WENDY.DASH_START, Volume = 1},
		DashEnd = {Sound = REVEL.SFX.WENDY.DASH_END, Volume = 0.5},
		StunStart = {Sound = REVEL.SFX.WENDY.STUN_START},
		Stun = {Sound = REVEL.SFX.BIRD_STUN, Volume = 0.5, Loop = true},
		WhirlwindStart = {Sound = REVEL.SFX.SNOWSTORM},
		WhirlwindLoop = {Sound = SoundEffect.SOUND_ULTRA_GREED_SPINNING, Volume = 0.5, Loop = true},
		WhirlwindShootIce = {Sound = SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, Pitch = 1},
		WhirlwindShoot = {Sound = SoundEffect.SOUND_BLOODSHOOT},
		Death = {Sound = REVEL.SFX.WENDY.DEATH, Volume = 1},
		Intro = {Sound = REVEL.SFX.WENDY.INTRO},
		-- IntroPop = {Sound = REVEL.SFX.SNOWBALL_BREAK},
		-- IntroGrowl = {Sound = SoundEffect.SOUND_MONSTER_YELL_B, Volume = 0.8, Pitch = 0.95},
		FootStep = {Sound = REVEL.SFX.SNOW_STEP, Volume = 0.25},
		SkullToDust = {Sound = REVEL.SFX.DUST_SCATTER, Volume = 1},
	},
}

REVEL.WendySnowPileMonsters = {
	{ent=REVEL.ENT.YELLOW_SNOW, points = 2},
	{ent=REVEL.ENT.YELLOW_SNOWBALL, points = 1.5},
	{ent=REVEL.ENT.ROLLING_SNOWBALL, points = 3},
	{ent=REVEL.ENT.SNOWBALL, points = 1}
}

function REVEL.SpawnWendySnowPileMonsters(snowpile)
	local points = 4
	local monsters = {}
	while true do
		local monster = REVEL.WendySnowPileMonsters[math.random(#REVEL.WendySnowPileMonsters)]
		if points - monster.points >= 0 then
			points = points - monster.points
			local ent = Isaac.Spawn(monster.ent.id, monster.ent.variant, 0, snowpile.Position+Vector(math.random(-20,20),math.random(-20,20)), Vector.Zero, snowpile)
			table.insert(monsters, ent)
		else
			break
		end
	end
	return monsters
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	REVEL.WendyStormOverlayActive = false
	if REVEL.sfx:IsPlaying(REVEL.SFX.BIRD_STUN) then
		REVEL.sfx:Stop(REVEL.SFX.BIRD_STUN)
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
	if npc.Variant == REVEL.ENT.WENDY_SNOWPILE.variant then
		REVEL.GetData(npc).RegenTimer = 0
		npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
	end
end, REVEL.ENT.WENDY.id)

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
	local sprite,data = npc:GetSprite(), REVEL.GetData(npc)
	if npc.Variant == REVEL.ENT.WENDY.variant then
		npc:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
		
		data.IsChampion = REVEL.IsChampion(npc)
		if data.IsChampion then
			data.bal = REVEL.GetBossBalance(REVEL.WendyBalance, 'Chocolate')
		else
			data.bal = REVEL.GetBossBalance(REVEL.WendyBalance, 'Default')
		end
		
		if data.bal.Skin ~= "" then
			for i=0, 10 do
				sprite:ReplaceSpritesheet(i, data.bal.Skin)
			end
			sprite:LoadGraphics()
		end
		npc.CollisionDamage = 0
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
		StageAPI.ChangeRoomGfx(REVEL.GlacierChillFreezerBurnRoomGfx)
		npc.MaxHitPoints = data.bal.MaxHP
		npc.HitPoints = data.bal.MaxHP
		npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
		REVEL.SetScaledBossHP(npc)
		REVEL.WendyInRoomLoad = true

		if REVEL.room:GetType() ~= RoomType.ROOM_BOSS then -- in case the boss isn't spawned in a boss room (debug console etc.) spawn in the snowpiles
			if REVEL.room:GetDoor(DoorSlot.UP0) then
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(97), Vector.Zero, npc)
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(32), Vector.Zero, npc)
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(42), Vector.Zero, npc)
			else
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(37), Vector.Zero, npc)
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(92), Vector.Zero, npc)
				Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, REVEL.room:GetGridPosition(102), Vector.Zero, npc)
			end
		end
		
		REVEL.AssignSnowpilesToWendy(npc)
		
		data.SpawnStalagmites = function() -- sets up the stalagmites for the spikey time phase, they are invisble until that phase
			data.Stalagmites = {}
			for i=1, data.bal.NumStalagmites do
				local pos
				local i2 = 0
				while i2 ~= 100 do
					pos = REVEL.room:GetRandomPosition(60)
					for _, snowpile in ipairs(data.Snowpiles) do
						if (pos-snowpile.Position):LengthSquared() <= 1600 then
							pos = pos+(pos-snowpile.Position):Resized(40)
							break
						end
					end
					
					local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(pos))
					if not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or REVEL.IsGridBroken(grid) then
						break
					end
					i2 = i2 + 1
				end
				if i2 == 100 then -- prevents infinite loop if there somehow isn't enough space for stalagmites available
					break
				end
				local stalagmite = Isaac.Spawn(REVEL.ENT.WENDY_STALAGMITE.id, REVEL.ENT.WENDY_STALAGMITE.variant, 0, pos, Vector.Zero, npc)
				stalagmite.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				stalagmite.Visible = false
				REVEL.GetData(stalagmite).Wendy = npc
				stalagmite:GetSprite().PlaybackSpeed = 0
				stalagmite:GetSprite():Play("Emerge", true)
				stalagmite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				table.insert(data.Stalagmites, stalagmite)
			end
		end
		data.SpawnStalagmites()
		
	elseif npc.Variant == REVEL.ENT.WENDY_SNOWPILE.variant then
		npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
		
	elseif npc.Variant == REVEL.ENT.WENDY_STALAGMITE.variant then
		npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_TARGET)
	end
end, REVEL.ENT.WENDY.id)

---@param wendy Entity
---@return boolean success False if Wendy hasn't run her first update yet
function REVEL.AssignSnowpilesToWendy(wendy)
	local data = REVEL.GetData(wendy)
	if not data.bal then
		return false
	end

	if data.AssignedSnowpiles then
		return true --success as it already assigned stuff
	end

	local ChocolateSnowpileVariants  = {"WhiteIceCream", "StrawberryIceCream", "PissIceCream"}
	REVEL.Shuffle(ChocolateSnowpileVariants)
	data.Snowpiles = Isaac.FindByType(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, false, false)
	for i, snowpile in ipairs(data.Snowpiles) do
		local snowpile_data = REVEL.GetData(snowpile)
		snowpile_data.Wendy = wendy
		snowpile_data.bal = data.bal
		snowpile_data.ShouldWaitForInit = nil
		snowpile.MaxHitPoints = data.bal.SnowpileMaxHP
		snowpile.HitPoints = data.bal.SnowpileMaxHP
		snowpile:GetSprite().FlipX = math.random(0,1) == 1
		if data.IsChampion then
			local snowpile_type = (i - 1) % #ChocolateSnowpileVariants + 1
			snowpile_data[ChocolateSnowpileVariants[snowpile_type]] = true
			REVEL.DebugLog("TEST Snowpile", i, snowpile_type, ChocolateSnowpileVariants[snowpile_type])
			if snowpile_data.StrawberryIceCream then
				snowpile:GetSprite():ReplaceSpritesheet(0, data.bal.SnowpileStrawberrySprite)
				snowpile:GetSprite():LoadGraphics()
			elseif snowpile_data.PissIceCream then
				snowpile:GetSprite():ReplaceSpritesheet(0, data.bal.SnowpilePissSprite)
				snowpile:GetSprite():LoadGraphics()
			end
		end
	end

	data.AssignedSnowpiles = true
	
	return true
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom)
	if REVEL.WendyInRoomLoad then
		if (Isaac.CountEntities(nil, REVEL.ENT.WENDY.id, REVEL.ENT.WENDY.variant, -1) or 0) > 0 then
			StageAPI.ChangeRoomGfx(REVEL.GlacierChillFreezerBurnRoomGfx)
		end
		REVEL.WendyInRoomLoad = false
	end
end)

---@param npc EntityNPC
local function WendyUpdate(npc)
	local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

	if not data.Init then
		npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR) --make update work for sound events during appear anim
		sprite:Play("Appear", true)
		--REVEL.PlaySound(data.bal.Sounds.Intro)
		data.Init = true
	end

	REVEL.ApplyKnockbackImmunity(npc)

	if sprite:IsPlaying("Appear") then
		if sprite:GetFrame() == 2 then
			REVEL.PlaySound(data.bal.Sounds.Intro)
		end
		--[[if sprite:IsEventTriggered("Pop") then
			REVEL.PlaySound(npc, data.bal.Sounds.IntroPop)
		end
		if sprite:IsEventTriggered("Growl") then
			REVEL.PlaySound(npc, data.bal.Sounds.IntroGrowl)
		end]]
		return
		
	elseif sprite:IsFinished("Appear") then
		data.WendyCurrentFoot = 0
		data.State = "Snow Stalking"
		data.WendyTargetpos = REVEL.room:GetRandomPosition(60)
		data.DistanceWalked = 0
		data.SnowPileEnemies = {}
		data.TimerBetweenStates = 0
		sprite:SetFrame("Idle", 0)
		npc.Visible = false
	end
	
	local ChocolateSnowpileVariants  = {"WhiteIceCream", "StrawberryIceCream", "PissIceCream"}
	for i,snowpile in ipairs(data.Snowpiles) do
		if snowpile:IsDead() and not REVEL.GetData(snowpile).Dying or not snowpile:Exists() then
			local new_snowpile = Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, snowpile.Position, Vector.Zero, nil)
			local snowpile_data = REVEL.GetData(new_snowpile)
			snowpile_data.Wendy = npc
			snowpile_data.bal = data.bal
			new_snowpile.MaxHitPoints = snowpile_data.bal.SnowpileMaxHP
			new_snowpile.HitPoints = snowpile_data.bal.SnowpileMaxHP
			new_snowpile:GetSprite().FlipX = math.random(0,1) == 1
			if data.IsChampion then
				for _,snowpile2 in ipairs(data.Snowpiles) do
					if not snowpile2:IsDead() and snowpile2:Exists() then
						for i2,snowpile_type in ipairs(ChocolateSnowpileVariants) do
							if REVEL.GetData(snowpile2)[snowpile_type] then
								table.remove(ChocolateSnowpileVariants, i2)
							end
						end
					end
				end
				local snowpile_type = ChocolateSnowpileVariants[math.random(#ChocolateSnowpileVariants)]
				snowpile_data[snowpile_type] = true
				if snowpile_data.StrawberryIceCream then
					new_snowpile:GetSprite():ReplaceSpritesheet(0, snowpile_data.bal.SnowpileStrawberrySprite)
					new_snowpile:GetSprite():LoadGraphics()
				elseif snowpile_data.PissIceCream then
					new_snowpile:GetSprite():ReplaceSpritesheet(0, snowpile_data.bal.SnowpilePissSprite)
					new_snowpile:GetSprite():LoadGraphics()
				end
			end
			data.Snowpiles[i] = new_snowpile
			snowpile:Remove()
		end
	end
	
	local total_snowpile_enemies = #data.SnowPileEnemies
	local total_snowpile_enemies_removed = 0
	for i=1, total_snowpile_enemies do
		local ent = data.SnowPileEnemies[i - total_snowpile_enemies_removed]
		if not ent:Exists() or ent:IsDead() or ent:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			table.remove(data.SnowPileEnemies, i - total_snowpile_enemies_removed)
			total_snowpile_enemies_removed = total_snowpile_enemies_removed + 1
		end
	end

	data.TimerBetweenStates = data.TimerBetweenStates+1
	
	if sprite:IsEventTriggered("GroundPound") then
		REVEL.PlaySound(npc, data.bal.Sounds.GroundPound)
		REVEL.game:ShakeScreen(15)
	end

	if data.State == "Snow Stalking" or data.State == "Hide And Seek" then
		if data.SpikeyTime == "Active" then -- starts spikey time phase
			if data.WhirlwindState == "GroundPound" then
				sprite:Play("AttackGroundPound", true)
			else
				sprite:Play("GroundPound", true)
			end
			data.State = "Spikey Time"
			npc.Visible = true
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			npc.Velocity = Vector.Zero
			data.SpikeyTime = "Done"
			data.TimerBetweenStates = 0
		elseif data.WhirlwindTime == "Active" then -- starts whirlwind phase
			if data.WhirlwindState then
				sprite:Play("WhirlwindIdle", true)
				local destroyed_snowpiles = false
				for _,snowpile in ipairs(data.Snowpiles) do
					if snowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
						snowpile:TakeDamage(9999, 0, EntityRef(npc), 0)
						destroyed_snowpiles = true
					end
				end
				
				if destroyed_snowpiles then
					data.WhirlwindState = "Snowpiles"
				else
					if data.IsChampion then
						data.State = "Ice Cream Shower"
						data.TimerBetweenState = 0
						sprite:SetFrame("Idle", 0)
						data.WhirlwindState = nil
						data.StartSnowballAttack = nil
					else
						data.WhirlwindState = "Stalagmites"
						data.StartSnowballAttack = nil
					end
				end
			else
				sprite:Play("WhirlwindStart", true)
			end
			data.State = "Whirlwind"
			npc.Visible = true
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			npc.Velocity = Vector.Zero
			data.WhirlwindTime = "Done"
			data.TimerBetweenStates = 0
		end
	end
	
	if sprite:IsFinished("Idle") then
		-- spawns the foot prints whenever wendy is walking around invisibly
		if (data.State == "Snow Stalking" or data.State == "Hide And Seek" or data.State == "Ice Cream Shower") and data.DistanceWalked >= data.bal.DistanceWalkedBeforeFootprint then
			data.DistanceWalked = data.DistanceWalked-data.bal.DistanceWalkedBeforeFootprint
			local footprintPos = npc.Position+npc.Velocity:Resized(data.bal.DistanceFeetToCenterBody):Rotated(data.WendyCurrentFoot*180+90)
			local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(footprintPos))
			if not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or REVEL.IsGridBroken(grid) then
				local footprint = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, footprintPos, Vector.Zero, npc)
				REVEL.GetData(footprint).IsWendyFootprint = true
				REVEL.GetData(footprint).FootprintFramesUntilFadeOut = data.bal.FootprintFramesUntilFadeOut
				footprint:GetSprite():Load("gfx/bosses/revel1/wendy/Wendy_footprint.anm2", true)
				if npc.Velocity.X ~= 0 and npc.Velocity.Y ~= 0 and math.abs(npc.Velocity.X)/math.abs(npc.Velocity.Y) <= 2 and math.abs(npc.Velocity.X)/math.abs(npc.Velocity.Y) >= 0.5 then
					footprint:GetSprite():Play("Appear2", true)
					if npc.Velocity.X < 0 and npc.Velocity.Y < 0 then footprint:GetSprite().Rotation = 0
					elseif npc.Velocity.X > 0 and npc.Velocity.Y < 0 then footprint:GetSprite().Rotation = 90
					elseif npc.Velocity.X > 0 and npc.Velocity.Y > 0 then footprint:GetSprite().Rotation = 180
					elseif npc.Velocity.X < 0 and npc.Velocity.Y > 0 then footprint:GetSprite().Rotation = 270 end
				else
					footprint:GetSprite():Play("Appear", true)
					if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
						if npc.Velocity.X > 0 then
							footprint:GetSprite().Rotation = 90
						else
							footprint:GetSprite().Rotation = 270
						end
					else
						if npc.Velocity.Y > 0 then
							footprint:GetSprite().Rotation = 180
						else
							footprint:GetSprite().Rotation = 0
						end
					end
				end
				REVEL.PlaySound(data.bal.Sounds.FootStep)
			end
			data.WendyCurrentFoot = data.WendyCurrentFoot+1-(data.WendyCurrentFoot*2)
		end
		
		if data.State == "Snow Stalking" then
			if data.TimerBetweenStates >= data.bal.FramesSneakingBeforeDash then -- gets wendy ready for her dash
				local target_Y = math.min(math.max(REVEL.player.Position.Y, REVEL.room:GetTopLeftPos().Y+npc.Size), REVEL.room:GetBottomRightPos().Y-npc.Size)
				if math.abs(target_Y-npc.Position.Y) <= 10 and (npc.Position-REVEL.player.Position):LengthSquared() >= 20000 then
					data.State = "Dash"
					npc.Velocity = Vector.Zero
					sprite:Play("HorizontalDashStart", true)
					REVEL.PlaySound(npc, data.bal.Sounds.DashStart)
					sprite.FlipX = REVEL.player.Position.X-npc.Position.X < 0
					npc.CollisionDamage = 1
					npc.Visible = true
					data.TimerBetweenStates = 0
					return
				else
					local middleofroomx = REVEL.room:GetCenterPos().X
					if math.abs(REVEL.player.Position.X-300-middleofroomx) < math.abs(REVEL.player.Position.X+300-middleofroomx) then
						data.WendyTargetpos = Vector(REVEL.player.Position.X-300, REVEL.player.Position.Y)
					else
						data.WendyTargetpos = Vector(REVEL.player.Position.X+300, REVEL.player.Position.Y)
					end
				end
			end
			
			-- gets random positions in the room for wendy to walk to in her sneaking around phase
			if ((data.WendyTargetpos-npc.Position):LengthSquared() <= 400 or npc.FrameCount%60 == 0) and data.TimerBetweenStates < data.bal.FramesSneakingBeforeDash then
				local i = 0
				data.DistanceWalked = 0
				while true do
					data.WendyTargetpos = REVEL.room:GetRandomPosition(50)
					if (data.WendyTargetpos.X > npc.Position.X and npc.Velocity.X < 0 or data.WendyTargetpos.X < npc.Position.X and npc.Velocity.X > 0) and (data.WendyTargetpos.Y > npc.Position.Y and npc.Velocity.Y < 0 or data.WendyTargetpos.Y < npc.Position.Y and npc.Velocity.Y > 0) and (data.WendyTargetpos-npc.Position):LengthSquared() >= 125000 or i == 10 then
						break
					end
					i = i+1
				end
			end
			
		elseif data.State == "Hide And Seek" then
			-- wendy goes towards the snowpiles to destroy them or hide in them if it's the last one
			if (data.WendyTargetpos-npc.Position):LengthSquared() <= 1000 then
				local snowpiles = {}
				for _,snowpile in ipairs(data.Snowpiles) do
					if snowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
						table.insert(snowpiles, snowpile)
					end
				end
				local num_snowpiles = #snowpiles
				-- checks if the snowpile still is intact before doing something with it
				if data.CurrentSnowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
					if num_snowpiles == 1 or data.InstantlyHideInSnowpile or data.IsChampion then -- if it's the last snowpile (or if it's chocolate Wendy), hide in it
						data.InstantlyHideInSnowpile = nil
						data.State = "Hiding In Snowpile"
						data.DistanceWalked = 0
						npc.Velocity = Vector.Zero
						npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						npc.Position = data.CurrentSnowpile.Position
						data.CurrentSnowpile:GetSprite():Play("Shake", true)
						data.TimerBetweenStates = 0
						if data.IsChampion then -- if it's chocolate wendy, recover most of the snow piles health
							data.CurrentSnowpile.HitPoints = data.CurrentSnowpile.HitPoints + math.floor((data.CurrentSnowpile.MaxHitPoints - data.CurrentSnowpile.HitPoints)*data.bal.ChampionHealSnowPilePercentage)
						else -- if not, she tries to start the snow storm
							if #data.SnowPileEnemies ~= 0 and not REVEL.WendyStormOverlayActive then -- if there are snowpile enemies alive, starts the snowstorm
								REVEL.WendyStormOverlayActive = true
								if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH
								or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY
								then
									REVEL.OVERLAY.Glacier1:Fade(30,0,1)
									REVEL.OVERLAY.Glacier7:Fade(30,0,1)
								end
								if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH
								or revel.data.snowflakesMode == RevSettings.SNOW_MODE_SHADER
								then
									REVEL.ForceSnowChillShader(true)
								end
								REVEL.WendyStormFadingoutTimer = 0
								REVEL.EnableWindSound(npc)
							end
						end
						
						if REVEL.WendyStormOverlayActive then
							local snowpiles = {}
							for _,snowpile in ipairs(data.Snowpiles) do -- quickly resets the snow piles to their former state because of the snowstorm
								if not snowpile:GetSprite():IsFinished("Idle") and not snowpile:GetSprite():IsPlaying("Shake") then
									snowpile:GetSprite():Play("RegenFast", true)
								end
								snowpile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
								snowpile.HitPoints = snowpile.MaxHitPoints
							end
						end
					else -- if it's not the last snowpile, destroy the snowpile
						data.CurrentSnowpile.HitPoints = data.CurrentSnowpile.MaxHitPoints
						data.CurrentSnowpile:GetSprite():Play("Destroy", true)
						REVEL.GetData(data.CurrentSnowpile).RegenTimer = 0
						data.CurrentSnowpile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						local enemies = REVEL.SpawnWendySnowPileMonsters(data.CurrentSnowpile)
						for _,ent in ipairs(enemies) do
							table.insert(data.SnowPileEnemies, ent)
						end
						for i,snowpile in ipairs(snowpiles) do
							if snowpile.Index == data.CurrentSnowpile.Index then
								table.remove(snowpiles, i)
								break
							end
						end
						-- chooses a new snowpile to go after
						local snowpile = snowpiles[math.random(#snowpiles)]
						data.WendyTargetpos = snowpile.Position
						data.CurrentSnowpile = snowpile
					end
					
				elseif num_snowpiles ~= 0 then -- chooses a new snowpile to go after
					local snowpile = snowpiles[math.random(#snowpiles)]
					data.WendyTargetpos = snowpile.Position
					data.CurrentSnowpile = snowpile
					
				elseif num_snowpiles == 0 then -- if somehow there aren't any snowpiles left because the player destroyed the last one, go back to stalking (or ice cream shower for chocolate wendy)
					if data.IsChampion then
						data.State = "Ice Cream Shower"
						data.TimerBetweenState = 0
						sprite:SetFrame("Idle", 0)
					else
						data.State = "Snow Stalking"
						data.WendyTargetpos = REVEL.room:GetRandomPosition(50)
						data.TimerBetweenStates = 0
					end
				end
			end
			
		elseif data.State == "Hiding In Snowpile" then
			npc.Position = data.CurrentSnowpile.Position
			npc.Velocity = Vector.Zero
		
			if REVEL.WendyStormOverlayActive then
				if #data.SnowPileEnemies == 0 then -- if there aren't any snowpile enemies left, stop the snowstorm
					if REVEL.WendyStormFadingoutTimer == 0 then
						if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH 
						or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY 
						then
							REVEL.OVERLAY.Glacier1:Fade(30, 30, -1)
							REVEL.OVERLAY.Glacier7:Fade(30, 30, -1)
						end
						if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH 
						or revel.data.snowflakesMode == RevSettings.SNOW_MODE_SHADER
						then
							REVEL.ResetForceSnowChillShader()
						end
					end
					REVEL.WendyStormFadingoutTimer = REVEL.WendyStormFadingoutTimer+1
				end
				if REVEL.WendyStormFadingoutTimer == 30 then -- gives the snowstorm time to fade out
					REVEL.WendyStormFadingoutTimer = 0
					REVEL.WendyStormOverlayActive = false
					REVEL.DisableWindSound(npc)
				end
				if REVEL.WendyStormFadingoutTimer == 0 then -- wendy goes out of her hiding spot to look for another snowpile
					if math.random(1,60) == 1 then
						data.State = "Hide And Seek"
						data.CurrentSnowpile:GetSprite():Play("Idle", true)
						local snowpiles = {}
						for _,snowpile in ipairs(data.Snowpiles) do
							if snowpile.Index ~= data.CurrentSnowpile.Index then
								table.insert(snowpiles, snowpile)
							end
						end
						local snowpile = snowpiles[math.random(#snowpiles)]
						data.WendyTargetpos = snowpile.Position
						data.CurrentSnowpile = snowpile
						data.InstantlyHideInSnowpile = true
					end
				end
			end
			
			if data.IsChampion then -- if wendy is a champion, fire snowballs at the player with different patterns depending on the flavor
				local snowpile_sprite, snowpile_data = data.CurrentSnowpile:GetSprite(), REVEL.GetData(data.CurrentSnowpile)
				local spawn_dip, active_snowballs, active_strawberry_snowballs, active_yellow_snowballs
				if math.random(1,60) == 1 then
					spawn_dip = true
					for _,e in ipairs(REVEL.roomEnemies) do
						if e.Type == REVEL.ENT.SNOWBALL.id and e.Variant == REVEL.ENT.SNOWBALL.variant then
							active_snowballs = true
						elseif e.Type == REVEL.ENT.STRAWBERRY_SNOWBALL.id and e.Variant == REVEL.ENT.STRAWBERRY_SNOWBALL.variant then
							active_strawberry_snowballs = true
						elseif e.Type == REVEL.ENT.YELLOW_SNOWBALL.id and e.Variant == REVEL.ENT.YELLOW_SNOWBALL.variant then
							active_yellow_snowballs = true
						end
					end
				end
				
				if snowpile_data.WhiteIceCream then
					if not snowpile_sprite:IsPlaying("Shake") then
						snowpile_sprite:Play("Shake", true)
					end
					if npc.FrameCount%data.bal.ChampionWhiteIceCreamShotFrequency == 0 then
						local target_pos = REVEL.room:GetRandomPosition(0)
						local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, npc.Position, (target_pos-npc.Position) / 45, npc):ToProjectile()
						proj.FallingAccel = 0.8
						proj.FallingSpeed = -35
						REVEL.GetData(proj).IsSnowball = true
						REVEL.GetData(proj).SpawnIceCreep = true
						REVEL.GetData(proj).isFrostyProjectile = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
						proj:GetSprite():LoadGraphics()
						proj:GetSprite():Play("RegularTear"..tostring(math.random(5,7)), true)
						REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.8, 0, false, 1)
					end
					if spawn_dip and not active_snowballs then
						local vec_to_target = npc:GetPlayerTarget().Position - npc.Position
						local ent = Isaac.Spawn(REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant, 0, npc.Position + vec_to_target:Resized(20), Vector.Zero, npc)
						ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					end
					
				elseif snowpile_data.StrawberryIceCream then
					if npc.FrameCount%data.bal.ChampionStrawberryIceCreamShotFrequency == 0 then
						local target = npc:GetPlayerTarget()
						REVEL.sfx:Play(SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1, 0, false, 1)
						snowpile_sprite:Play("WendyHideMad", true)
						for i=1, data.bal.NumStrawberryProjectiles do
							local target_pos = target.Position + Vector.FromAngle(math.random(0,359)):Resized(math.random(0,data.bal.StrawberryVolleyRadius))
							local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, npc.Position, (target_pos-npc.Position) / 45, npc):ToProjectile()
							proj.FallingAccel = 0.8
							proj.FallingSpeed = -35
							REVEL.GetData(proj).IsStrawberry = true
							REVEL.GetData(proj).SpawnStrawberryCreep = true
							REVEL.GetData(proj).isFrostyProjectile = true
							proj:GetSprite():ReplaceSpritesheet(0, data.bal.StrawberrySnowballSpritesheet)
							proj:GetSprite():LoadGraphics()
							proj:GetSprite():Play("RegularTear"..tostring(math.random(5,7)), true)
							local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false)
							creep.Color = REVEL.StrawberryCreepColor
						end
					end
					if spawn_dip and not active_strawberry_snowballs then
						local vec_to_target = npc:GetPlayerTarget().Position - npc.Position
						local ent = Isaac.Spawn(REVEL.ENT.STRAWBERRY_SNOWBALL.id, REVEL.ENT.STRAWBERRY_SNOWBALL.variant, 0, npc.Position + vec_to_target:Resized(20), Vector.Zero, npc)
						ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					end
					
				elseif snowpile_data.PissIceCream then
					data.NumPissShotsLeft = data.NumPissShotsLeft or 0
					if npc.FrameCount%data.bal.ChampionPissIceCreamLineFrequency == 0 then
						snowpile_sprite:Play("WendyHideIdle", true)
						data.NumPissShotsLeft = data.bal.NumPissShots
						local target_pos = npc:GetPlayerTarget().Position
						data.PissLineStart = nil
						while not data.PissLineStart do
							local pos = target_pos + Vector.FromAngle(math.random(0,359))*data.bal.PissLineStartPosDistanceFromTarget()
							if REVEL.room:IsPositionInRoom(pos, 0) then
								data.PissLineStart = pos
							end
						end
						data.LastPissShotPos = data.PissLineStart
						data.PissLineEnd = nil
						local check_to_player = true
						while not data.PissLineEnd do
							local pos
							if check_to_player then
								local target = npc:GetPlayerTarget()
								pos = data.PissLineStart + (target.Position-data.PissLineStart):Resized(data.bal.PissLineLength())
								check_to_player = false
							else
								pos = data.PissLineStart + Vector.FromAngle(math.random(0,359))*data.bal.PissLineLength()
							end
							if REVEL.room:IsPositionInRoom(pos, 0) then
								data.PissLineEnd = pos
							end
						end
					end
					
					if data.NumPissShotsLeft ~= 0 and npc.FrameCount%data.bal.PissLineShotFrequency == 0 then
						data.NumPissShotsLeft = data.NumPissShotsLeft - 1
						local target_pos
						if data.NumPissShotsLeft == 0 then
							target_pos = data.PissLineEnd
						else
							target_pos = data.LastPissShotPos + ((data.PissLineEnd-data.LastPissShotPos) / (data.NumPissShotsLeft+1)):Rotated(math.random(-10,10))
						end
						local proj_pos = npc.Position + Vector(math.random(-20,20), math.random(-3,3))
						local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, proj_pos, (target_pos-proj_pos) / 45, npc):ToProjectile()
						proj.FallingAccel = 0.8
						proj.FallingSpeed = -35
						REVEL.GetData(proj).IsPiss = true
						REVEL.GetData(proj).SpawnPissCreep = true
						REVEL.GetData(proj).isFrostyProjectile = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.PissSnowballSpritesheet)
						proj:GetSprite():LoadGraphics()
						proj:GetSprite():Play("RegularTear"..tostring(math.random(5,7)), true)
						data.LastPissShotPos = target_pos
						REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 0.8, 0, false, 1)
					end
					if spawn_dip and not active_yellow_snowballs then
						local vec_to_target = npc:GetPlayerTarget().Position - npc.Position
						local ent = Isaac.Spawn(REVEL.ENT.YELLOW_SNOWBALL.id, REVEL.ENT.YELLOW_SNOWBALL.variant, 0, npc.Position + vec_to_target:Resized(20), Vector.Zero, npc)
						ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					end
				end
			end
			
		elseif data.State == "Ice Cream Shower" then
			local cpos = REVEL.room:GetCenterPos()
			data.WendyTargetpos = cpos
			if (data.WendyTargetpos-npc.Position):LengthSquared() <= 400 then
				sprite:Play("GroundPound", true)
				npc.Velocity = Vector.Zero
				npc.Visible = true
			end
		end
		
		-- movement towards a target position, wendy kinda tries to avoid bumping into the player too much
		if not REVEL.IsOutOfRoomBy(npc.Position, -60) then
			local disttoplayer = math.max(1000,(npc.Position-REVEL.player.Position):LengthSquared())
			npc.Velocity = npc.Velocity*data.bal.VelocityKeptWhileSneaking+(data.WendyTargetpos-npc.Position):Resized(data.bal.SneakingVelocity)+(npc.Position-npc.TargetPosition):Resized(10000/disttoplayer)*data.bal.PlayerAvoidanceVelocity
		else
			npc.Velocity = npc.Velocity*data.bal.VelocityKeptWhileSneaking+(data.WendyTargetpos-npc.Position):Resized(data.bal.SneakingVelocity)
		end
		local speed = npc.Velocity:Length()
		data.DistanceWalked = data.DistanceWalked+speed
		
	elseif data.State == "Dash" then
		if sprite:IsEventTriggered("DashStart") then
			if data.IsChampion then
				data.ChocolateTrail = true
			end
			npc.Velocity = Vector(data.bal.DashVelocity*(sprite.FlipX and -1 or 1),0)
		elseif sprite:WasEventTriggered("DashStart") then
			npc.Velocity = Vector(data.bal.DashVelocity*(sprite.FlipX and -1 or 1),0)
		end
		if sprite:IsFinished("HorizontalDashStart") then
			sprite:Play("HorizontalDashIdle", true)
		end
		
		if data.ChocolateTrail and npc.FrameCount%2 == 0 then
			local creep = REVEL.SpawnCreep(EffectVariant.CREEP_SLIPPERY_BROWN, 0, npc.Position, npc, false):ToEffect()
			local color = Color(1,1,1,1,conv255ToFloat(0,0,0))
			color:SetColorize(REVEL.ChocolateCreepColorize.R, REVEL.ChocolateCreepColorize.G, REVEL.ChocolateCreepColorize.B, REVEL.ChocolateCreepColorize.A)
			creep:GetSprite().Color = color
			creep:GetSprite().PlaybackSpeed = 0
			creep:SetTimeout(360)
		end
		
		if sprite:IsPlaying("HorizontalDashIdle") then -- stopping the dash just before bumping into the wall
			local checkinggridpos = Vector(npc.Position.X+data.bal.DashDistanceFromWallBeforeStopping,npc.Position.Y)
			if sprite.FlipX then checkinggridpos = Vector(npc.Position.X-data.bal.DashDistanceFromWallBeforeStopping,npc.Position.Y) end
			local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(checkinggridpos))
			local grid2 = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(checkinggridpos + Vector(0,npc.Size)))
			local grid3 = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(checkinggridpos + Vector(0,-npc.Size)))
			
			if grid and grid.Desc.Type == GridEntityType.GRID_WALL
			or grid2 and grid2.Desc.Type == GridEntityType.GRID_WALL
			or grid3 and grid3.Desc.Type == GridEntityType.GRID_WALL
			or npc:CollidesWithGrid() then
				sprite:Play("HorizontalDashEnd", true)
				REVEL.PlaySound(npc, data.bal.Sounds.DashEnd)
				-- REVEL.PlaySound(npc, data.bal.Sounds.Vanish)
				data.ChocolateTrail = false
			else
				npc.Velocity = Vector(data.bal.DashVelocity*(sprite.FlipX and -1 or 1),0)
			end
		end
		if sprite:IsPlaying("HorizontalDashEnd") then
			npc.Velocity = npc.Velocity*0.8
		end
		if sprite:IsFinished("HorizontalDashEnd") then
			local snowpiles = {}
			for _,snowpile in ipairs(data.Snowpiles) do
				if snowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
					table.insert(snowpiles, snowpile)
				end
			end
			if #snowpiles ~= 0 then -- if there are any intact snowpiles, go towards them in the "Hide And Seek" state
				data.State = "Hide And Seek"
				local snowpile = snowpiles[math.random(#snowpiles)]
				data.WendyTargetpos = snowpile.Position
				data.CurrentSnowpile = snowpile
			else -- in case there aren't any intact snowpiles, just go back to snow stalking (or ice cream shower for chocolate wendy)
				if data.IsChampion then
					data.State = "Ice Cream Shower"
				else
					data.State = "Snow Stalking"
					data.WendyTargetpos = REVEL.room:GetRandomPosition(50)
				end
			end
			data.DistanceWalked = 0
			data.TimerBetweenStates = 0
			sprite:SetFrame("Idle", 0)
			npc.CollisionDamage = 0
			npc.Visible = false
			npc.Velocity = Vector.Zero
		end
		
	elseif data.State == "Stunned" then
		if sprite:IsFinished("Stun") then
			sprite:Play("StunIdle", true)
			REVEL.PlaySound(npc, data.bal.Sounds.Stun)
		end
		if data.TimerBetweenStates == data.bal.StunDuration then
			sprite:Play("StunEnd", true)
			REVEL.sfx:Stop(REVEL.SFX.BIRD_STUN)
		end
		if sprite:IsFinished("StunEnd") then
			if data.IsChampion then
				local snowpiles = {}
				for _,snowpile in ipairs(data.Snowpiles) do
					if snowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
						table.insert(snowpiles, snowpile)
					end
				end
				if #snowpiles ~= 0 then -- if there are any intact snowpiles, go towards them in the "Hide And Seek" state
					data.State = "Hide And Seek"
					local snowpile = snowpiles[math.random(#snowpiles)]
					data.WendyTargetpos = snowpile.Position
					data.CurrentSnowpile = snowpile
				else -- in case there aren't any intact snowpiles, just go back to snow stalking
					data.State = "Ice Cream Shower"
				end
			else
				data.State = "Snow Stalking"
				data.WendyTargetpos = REVEL.room:GetRandomPosition(50)
			end
			data.DistanceWalked = 0
			data.TimerBetweenStates = 0
			sprite:SetFrame("Idle", 0)
			npc.CollisionDamage = 0
			npc.Visible = false
		end
		
	elseif data.State == "Spikey Time" then
		if sprite:IsEventTriggered("GroundPound") then -- everytime the ground is pounded, let the stalagmite emerge anim progress until it stops itself again
			for _,stalagmite in ipairs(data.Stalagmites) do
				stalagmite:GetSprite().PlaybackSpeed = 1
				REVEL.GetData(stalagmite).dontchangeplaybackspeedthisframe = true
				stalagmite.Visible = true
			end
		end
		if sprite:IsFinished("GroundPound") or sprite:IsFinished("AttackGroundPound") then -- go back to snow stalking after the ground pounding
			sprite:SetFrame("Idle", 0)
			npc.Visible = false
			data.State = "Snow Stalking"
			data.DistanceWalked = 0
			data.TimerBetweenStates = 0
		end
		
	elseif data.State == "Whirlwind" then
		data.Snowballs = data.Snowballs or {}
		data.SnowballsInWhirlwind = data.SnowballsInWhirlwind or 0
		data.StalagmitesInWhirlwind = data.StalagmitesInWhirlwind or 0
		
		if sprite:IsEventTriggered("WhirlwindStart") then -- destroys all intact snowpiles
			local destroyed_snowpiles = false
			for _,snowpile in ipairs(data.Snowpiles) do
				if snowpile.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
					REVEL.GetData(snowpile).StopSnowballSpawning = true
					snowpile:TakeDamage(9999, 0, EntityRef(npc), 0)
					destroyed_snowpiles = true
				end
			end
			if data.IsChampion then
				data.SnowballsInWhirlwind = data.SnowballsInWhirlwind + data.bal.NumChocolateShotsInWhirlwind
				data.SnowballTypesInWhirlwind = {}
				for i=1, data.bal.NumChocolateShotsInWhirlwind do
					table.insert(data.SnowballTypesInWhirlwind, "Chocolate")
				end
			end
			
			if destroyed_snowpiles then
				data.WhirlwindState = "Snowpiles"
			else
				if data.IsChampion then
					data.State = "Ice Cream Shower"
					data.TimerBetweenState = 0
					sprite:SetFrame("Idle", 0)
					data.WhirlwindState = nil
					data.StartSnowballAttack = nil
				else
					data.WhirlwindState = "Stalagmites"
					data.StartSnowballAttack = nil
				end
			end

			REVEL.PlaySound(data.bal.Sounds.WhirlwindStart)
			REVEL.PlaySound(data.bal.Sounds.WhirlwindLoop)
			REVEL.EnableWindSound(npc, true, 1.5)
		end
		if sprite:IsFinished("WhirlwindStart") then
			sprite:Play("WhirlwindIdle", true)
		end
		
		if data.WhirlwindState == "Snowpiles" then -- the destroyed snowpiles spawn lots of snowballs projectiles which the whirlwind pulls in
			local active_snowballs, active_strawberry_snowballs, active_yellow_snowballs
			if data.IsChampion then
				for _,e in ipairs(REVEL.roomEnemies) do
					if e.Type == REVEL.ENT.SNOWBALL.id and e.Variant == REVEL.ENT.SNOWBALL.variant then
						active_snowballs = true
					elseif e.Type == REVEL.ENT.STRAWBERRY_SNOWBALL.id and e.Variant == REVEL.ENT.STRAWBERRY_SNOWBALL.variant then
						active_strawberry_snowballs = true
					elseif e.Type == REVEL.ENT.YELLOW_SNOWBALL.id and e.Variant == REVEL.ENT.YELLOW_SNOWBALL.variant then
						active_yellow_snowballs = true
					end
				end
			end
			
			for _,snowpile in ipairs(data.Snowpiles) do
				if snowpile:GetSprite():IsEventTriggered("Destroy") then
					local num_snowballs = data.bal.SnowballsInSnowpile()
					for i=1, num_snowballs do
						local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, snowpile.Position+Vector(math.random()-0.5,math.random()-0.5):Resized(math.random()*30), (npc.Position-snowpile.Position):Resized(3), snowpile):ToProjectile()
						proj.FallingSpeed = -5
						proj.FallingAccel = 0
						proj.Height = (math.random()*-data.bal.SnowballsInSnowpileMaxHeight)-5
						if REVEL.GetData(snowpile).StrawberryIceCream then
							REVEL.GetData(proj).IsStrawberry = true
							--REVEL.GetData(proj).SpawnStrawberryCreep = true
							proj:GetSprite():ReplaceSpritesheet(0, data.bal.StrawberrySnowballSpritesheet)
						elseif REVEL.GetData(snowpile).PissIceCream then
							REVEL.GetData(proj).IsPiss = true
							--REVEL.GetData(proj).SpawnPissCreep = true
							proj:GetSprite():ReplaceSpritesheet(0, data.bal.PissSnowballSpritesheet)
						else
							REVEL.GetData(proj).IsSnowball = true
							--REVEL.GetData(proj).SpawnIceCreep = true
							proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
						end
						proj:GetSprite().PlaybackSpeed = 0
						proj:GetSprite():LoadGraphics()
						REVEL.GetData(proj).isFrostyProjectile = true
						REVEL.PlaySound(data.bal.Sounds.WhirlwindShoot)
						table.insert(data.Snowballs, proj)
						data.WhirlwindState = "Snowballs"
					end
					
					if data.IsChampion then -- spawn a flying dip with the right flavor if there is no dip of that flavor in the room yet
						local spawndip = false
						if REVEL.GetData(snowpile).WhiteIceCream and not active_snowballs
						or REVEL.GetData(snowpile).StrawberryIceCream and not active_strawberry_snowballs
						or REVEL.GetData(snowpile).PissIceCream and not active_yellow_snowballs then
							local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, snowpile.Position+Vector(math.random()-0.5,math.random()-0.5):Resized(math.random()*30), (npc.Position-snowpile.Position):Resized(3), snowpile)
							REVEL.GetData(eff).IsFlyingSnowball = true
							REVEL.GetData(eff).FlyingSnowballRotation = math.random(-10,10)
							eff:GetSprite().Rotation = math.random(0,359)
							eff:GetSprite().Offset = Vector(0, (math.random()*-data.bal.SnowballsInSnowpileMaxHeight)-5)
							local eff_sprite = eff:GetSprite()
							eff_sprite.Offset = Vector(0, (math.random()*-data.bal.SnowballsInSnowpileMaxHeight)-5)
							if REVEL.GetData(snowpile).WhiteIceCream then
								eff_sprite:Load("gfx/monsters/revel1/snowball/snowball.anm2", true)
								REVEL.GetData(eff).IsWhiteIceCream = true
							elseif REVEL.GetData(snowpile).StrawberryIceCream then
								eff_sprite:Load("gfx/monsters/revel1/snowball/strawberry_snowball.anm2", true)
								REVEL.GetData(eff).IsStrawberryIceCream = true
							elseif REVEL.GetData(snowpile).PissIceCream then
								eff_sprite:Load("gfx/monsters/revel1/snowball/yellow_snowball.anm2", true)
								REVEL.GetData(eff).IsPissIceCream = true
							end
							eff_sprite:Play("Idle", true)
							table.insert(data.Snowballs, eff)
						end
					end
				end
			end
		end
		
		if data.WhirlwindState == "Snowballs" then
			for i,snowball in ipairs(data.Snowballs) do -- when a snowball gets close to the whirlwind it gets pulled in, adding 3 snowballs to the whirlwind for the next attack
				if not snowball:Exists() then
					table.remove(data.Snowballs, i)
					snowball:Remove()
				elseif (npc.Position-snowball.Position):LengthSquared() <= 1600 then
					table.remove(data.Snowballs, i)
					if data.IsChampion then
						local snowball_data = REVEL.GetData(snowball)
						if snowball_data.IsSnowball then
							table.insert(data.SnowballTypesInWhirlwind, "White")
						elseif snowball_data.IsStrawberry then
							table.insert(data.SnowballTypesInWhirlwind, "Strawberry")
						elseif snowball_data.IsPiss then
							table.insert(data.SnowballTypesInWhirlwind, "Piss")
						elseif snowball_data.IsFlyingSnowball then
							if snowball_data.IsWhiteIceCream then
								table.insert(data.SnowballTypesInWhirlwind, "WhiteSnowball")
							elseif snowball_data.IsStrawberryIceCream then
								table.insert(data.SnowballTypesInWhirlwind, "StrawberrySnowball")
							elseif snowball_data.IsPissIceCream then
								table.insert(data.SnowballTypesInWhirlwind, "PissSnowball")
							end
						end
					end
					snowball:Remove()
					data.SnowballsInWhirlwind = data.SnowballsInWhirlwind+1
				else -- snowball movement towards the whirlwind
					snowball.Velocity = snowball.Velocity*data.bal.SnowballKeptVelocityToWhirlwind+(npc.Position-snowball.Position):Resized(data.bal.SnowballVelocityToWhirlwind)
					if REVEL.GetData(snowball).IsFlyingSnowball then
						snowball:GetSprite().Offset = Vector(0, snowball:GetSprite().Offset.Y - 0.5)
						snowball:GetSprite().Rotation = snowball:GetSprite().Rotation + REVEL.GetData(snowball).FlyingSnowballRotation
					end
				end
			end
			
			if #data.Snowballs == 0 and not data.StartSnowballAttackFrame then -- when all snowballs are pulled in, wait a second before letting them all loose
				data.StartSnowballAttackFrame = data.TimerBetweenStates+data.bal.FramesBeforeSnowballAttack
			end
			if data.TimerBetweenStates == data.StartSnowballAttackFrame then
				data.StartSnowballAttack = true
			end
			
			if data.StartSnowballAttack then -- whirlwind snowball attack, every few frames a snowball will be send into a random direction, until all snowballs are used, after which the stalagmite phase begins
				data.StartSnowballAttackFrame = nil
				if data.SnowballsInWhirlwind ~= 0 and npc.FrameCount%data.bal.FramesBeforeSnowballFired == 0 then
					if data.IsChampion then
						local i = math.random(#data.SnowballTypesInWhirlwind)
						local snowballtype = data.SnowballTypesInWhirlwind[i]
						table.remove(data.SnowballTypesInWhirlwind, i)
						
						local vec_to_target = npc:GetPlayerTarget().Position - npc.Position
						if snowballtype == "White" or snowballtype == "Strawberry" or snowballtype == "Piss" or snowballtype == "Chocolate" then
							local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, npc.Position, vec_to_target:Rotated(math.random(-data.bal.ChampionWhirlwindShotAngleOffset,data.bal.ChampionWhirlwindShotAngleOffset)):Resized(data.bal.SnowballVelocity()), data.Wendy):ToProjectile()
							proj.Height = (math.random()*-data.bal.SnowballsInSnowpileMaxHeight)-10
							proj.FallingSpeed = proj.Height * -2 / vec_to_target:Length()
							proj.FallingAccel = 0
							if snowballtype == "White" then
								REVEL.GetData(proj).IsSnowball = true
								REVEL.GetData(proj).SpawnIceCreep = true
								proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
							elseif snowballtype == "Strawberry" then
								REVEL.GetData(proj).IsStrawberry = true
								REVEL.GetData(proj).SpawnStrawberryCreep = true
								proj:GetSprite():ReplaceSpritesheet(0, data.bal.StrawberrySnowballSpritesheet)
							elseif snowballtype == "Piss" then
								REVEL.GetData(proj).IsPiss = true
								REVEL.GetData(proj).SpawnPissCreep = true
								proj:GetSprite():ReplaceSpritesheet(0, data.bal.PissSnowballSpritesheet)
							elseif snowballtype == "Chocolate" then
								REVEL.GetData(proj).IsChocolate = true
								REVEL.GetData(proj).SpawnChocolateCreep = true
								proj:GetSprite():ReplaceSpritesheet(0, data.bal.ChocolateSnowballSpritesheet)
							end
							proj:GetSprite():LoadGraphics()
							REVEL.GetData(proj).isFrostyProjectile = true
							REVEL.PlaySound(data.bal.Sounds.WhirlwindShoot)

						elseif snowballtype == "WhiteSnowball" or snowballtype == "StrawberrySnowball" or snowballtype == "PissSnowball" then
							local snowball
							if snowballtype == "WhiteSnowball" then
								snowball = REVEL.ENT.SNOWBALL
							elseif snowballtype == "StrawberrySnowball" then
								snowball = REVEL.ENT.STRAWBERRY_SNOWBALL
							elseif snowballtype == "PissSnowball" then
								snowball = REVEL.ENT.YELLOW_SNOWBALL
							end
							local ent = Isaac.Spawn(snowball.id, snowball.variant, 0, npc.Position, vec_to_target/40, npc)
							ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						end
					else
						local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, npc.Position, Vector(math.random()-0.5,math.random()-0.5):Resized(data.bal.SnowballVelocity()), data.Wendy):ToProjectile()
						proj.Height = (math.random()*-data.bal.SnowballsInSnowpileMaxHeight)-10
						REVEL.GetData(proj).isFrostyProjectile = true
						REVEL.GetData(proj).IsSnowball = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
						proj:GetSprite():LoadGraphics()
						REVEL.PlaySound(data.bal.Sounds.WhirlwindShoot)

					end
					data.SnowballsInWhirlwind = data.SnowballsInWhirlwind-1
				elseif data.SnowballsInWhirlwind == 0 then
					if data.IsChampion then
						data.State = "Ice Cream Shower"
						data.TimerBetweenState = 0
						sprite:SetFrame("Idle", 0)
						data.WhirlwindState = nil
						data.StartSnowballAttack = nil
					else
						data.WhirlwindState = "Stalagmites"
						data.StartSnowballAttack = nil
					end
				end
			end
		end
		
		if data.WhirlwindState == "Stalagmites" then
			-- the whirlwind will go to a random stalagmite and suck it up
			if (data.WendyTargetpos-npc.Position):LengthSquared() <= 400 and data.ChosenStalagmite and not data.ChosenStalagmite:GetSprite():IsPlaying("Launch") then
				REVEL.sfx:Play(SoundEffect.SOUND_PLOP,1,0,false,0.7)
				data.ChosenStalagmite:GetSprite():Play("Launch", true)
			end
			if data.ChosenStalagmite and data.ChosenStalagmite:GetSprite():IsEventTriggered("Launch") then
				data.StalagmitesInWhirlwind = data.StalagmitesInWhirlwind+1
				for i,stalagmite in ipairs(data.Stalagmites) do
					if stalagmite.Index == data.ChosenStalagmite.Index then
						table.remove(data.Stalagmites, i)
						break
					end
				end
				data.ChosenStalagmite = nil
			end
			
			-- if there are any stalagmites in the whirlwind, shoot them one by one straight towards the player
			if data.StalagmitesInWhirlwind ~= 0 and not sprite:IsPlaying("Attack") then
				data.StalagmitesInWhirlwind = data.StalagmitesInWhirlwind-1
				sprite:Play("Attack", true)
			end
			if sprite:IsEventTriggered("Attack") then -- creation of a stalagmite projectile
				local flyingstalagmite = Isaac.Spawn(REVEL.ENT.WENDY_STALAGMITE.id, REVEL.ENT.WENDY_STALAGMITE.variant, 1, npc.Position, (REVEL.player.Position-npc.Position):Resized(data.bal.StalagmiteProjVelocity), npc)
				flyingstalagmite.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				flyingstalagmite.GridCollisionClass = GridCollisionClass.COLLISION_NONE
				flyingstalagmite:GetSprite():Play("Flying", true)
				flyingstalagmite:GetSprite().Rotation = flyingstalagmite.Velocity:GetAngleDegrees()+90
				flyingstalagmite:GetSprite().Offset = Vector(0,-data.bal.StalagmiteProjHeight)
				flyingstalagmite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				REVEL.PlaySound(data.bal.Sounds.WhirlwindShootIce)
			end
			
			if sprite:IsFinished("Attack") then -- if all stalagmites are pulled in and fired, go back to spikey time
				if data.StalagmitesInWhirlwind == 0 and #data.Stalagmites == 0 then
					data.SpawnStalagmites()
					data.SpikeyTime = "Active"
					data.State = "Snow Stalking"
					npc.Velocity = Vector.Zero
					data.WhirlwindTime = "Active"
					data.WhirlwindState = "GroundPound"
					return
				else
					sprite:Play("WhirlwindIdle", true)
				end
			end
		end
		
		if data.WhirlwindState == "Stalagmites" then -- in the stalagmite phase, chooses a random stalagmite to go to
			if not data.ChosenStalagmite and #data.Stalagmites ~= 0 then
				data.ChosenStalagmite = data.Stalagmites[math.random(#data.Stalagmites)]
				data.WendyTargetpos = data.ChosenStalagmite.Position
				data.ChosenStalagmite:GetSprite():Play("IdleAngered", true)
			end
		else -- in case of other whirlwind phases, chooses target positions randomly in the middle of the room
			if (data.WendyTargetpos-npc.Position):LengthSquared() <= 400 or data.TimerBetweenStates%60 == 0 then
				local cpos = REVEL.room:GetCenterPos()
				data.WendyTargetpos = cpos+Vector(math.random()-0.5,math.random()-0.5):Resized(math.random()*data.bal.WhirlwindDistanceFromCenter)
			end
		end
		
		if data.WhirlwindState and (not sprite:IsPlaying("WhirlwindStart") or sprite:WasEventTriggered("Whirlwindstart")) and data.State == "Whirlwind" then -- whirlwind movement towards a target position
			npc.Velocity = npc.Velocity*data.bal.WhirlwindKeptVelocity+(data.WendyTargetpos-npc.Position):Resized(data.bal.WhirlwindVelocity)
		end
		
	elseif data.State == "Ice Cream Shower" then			
		if sprite:IsEventTriggered("GroundPound") then
			for _,snowpile in ipairs(data.Snowpiles) do
				for i=1, data.bal.IceCreamShowerNumLooseProjectiles() do
					local vel = Vector.FromAngle(math.random(0,359))*data.bal.IceCreamShowerProjectileVelocity()
					local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, snowpile.Position + Vector.FromAngle(math.random(0,359))*math.random(0,data.bal.IceCreamShowerMaxProjectileRadiusFromTarget), vel, npc):ToProjectile()
					proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					REVEL.GetData(proj).KeepVel = vel
					REVEL.GetData(proj).IgnoreHitOnSpawn = true
					proj.FallingAccel = data.bal.IceCreamShowerProjectileFallingAccel()
					proj.FallingSpeed = 0
					proj.Height = data.bal.IceCreamShowerProjectileStartingHeight
					if REVEL.GetData(snowpile).WhiteIceCream then
						REVEL.GetData(proj).IsSnowball = true
						REVEL.GetData(proj).SpawnIceCreep = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
					elseif REVEL.GetData(snowpile).StrawberryIceCream then
						REVEL.GetData(proj).IsStrawberry = true
						REVEL.GetData(proj).SpawnStrawberryCreep = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.StrawberrySnowballSpritesheet)
					elseif REVEL.GetData(snowpile).PissIceCream then
						REVEL.GetData(proj).IsPiss = true
						REVEL.GetData(proj).SpawnPissCreep = true
						proj:GetSprite():ReplaceSpritesheet(0, data.bal.PissSnowballSpritesheet)
					end
					REVEL.GetData(proj).isFrostyProjectile = true
					proj:GetSprite():LoadGraphics()
					proj:GetSprite():Play("RegularTear"..tostring(math.random(5,7)), true)
					proj:Update()
				end
			end
			local target = npc:GetPlayerTarget()
			for i=1, data.bal.IceCreamShowerNumLooseProjectiles() do
				local vel = Vector.FromAngle(math.random(0,359))*data.bal.IceCreamShowerProjectileVelocity()
				local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, target.Position + Vector.FromAngle(math.random(0,359))*math.random(0,data.bal.IceCreamShowerMaxProjectileRadiusFromTarget), vel, npc):ToProjectile()
				proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				REVEL.GetData(proj).IgnoreHitOnSpawn = true
				REVEL.GetData(proj).KeepVel = vel
				proj.FallingAccel = data.bal.IceCreamShowerProjectileFallingAccel()
				proj.FallingSpeed = 0
				proj.Height = data.bal.IceCreamShowerProjectileStartingHeight
				REVEL.GetData(proj).IsChocolate = true
				REVEL.GetData(proj).SpawnChocolateCreep = true
				REVEL.GetData(proj).ChocolateCreepTimeout = 360
				REVEL.GetData(proj).isFrostyProjectile = true
				proj:GetSprite():ReplaceSpritesheet(0, data.bal.ChocolateSnowballSpritesheet)
				proj:GetSprite():LoadGraphics()
				proj:GetSprite():Play("RegularTear"..tostring(math.random(5,7)), true)
				proj:Update()
			end
			
			if not data.IceCreamShowerRegenTime and sprite:GetFrame() == 39 then
				data.IceCreamShowerRegenTime = data.bal.IceCreamShowerSnowPileRegenTime
				for _,snowpile in ipairs(data.Snowpiles) do
					snowpile:GetSprite().PlaybackSpeed = 2
					REVEL.GetData(snowpile).RegenTimer = 0
				end
			end
		end
		
		if sprite:IsFinished("GroundPound") then
			data.State = "Snow Stalking"
			npc.Visible = false
			sprite:SetFrame("Idle", 0)
			if npc.HitPoints <= npc.MaxHitPoints/2 then
				data.WhirlwindTime = "Active"
			end
		end
		
		if REVEL.sfx:IsPlaying(data.bal.Sounds.WhirlwindLoop.Sound) then
			REVEL.sfx:Stop(data.bal.Sounds.WhirlwindLoop.Sound)
			REVEL.DisableWindSound(npc)
		end
		
		npc.Velocity = Vector.Zero
	end
end

---@param npc EntityNPC
local function SnowpileUpdate(npc)
	local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

	if not data.Init then
		data.SpawnPosition = npc.Position
		data.Init = true
	end

	npc.Position = data.SpawnPosition
	npc.Velocity = Vector.Zero
	data.RegenTimer = data.RegenTimer + 1
	
	-- to be set to nil externally by wendy when she calls init
	if data.ShouldWaitForInit then
		return
	end

	if not data.Wendy then
		local wendys = Isaac.FindByType(REVEL.ENT.WENDY.id, REVEL.ENT.WENDY.variant, -1, false, false)
		if wendys[1] then
			local success = not REVEL.AssignSnowpilesToWendy(wendys[1])
			data.ShouldWaitForInit = not success
			return
		else
			return
		end
	end
	
	-- because the player destroyed the wrong snowpile, wendy will shoot a dangerous snowball attack towards the player and she'll go back to snow stalking
	if not REVEL.GetData(data.Wendy).IsChampion and sprite:IsPlaying("WendyHideMad") and sprite:IsEventTriggered("Shoot") then
		for i=1, data.bal.NumSnowballsWendySnowpileAttack() do
			local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, data.bal.SnowballVariant, 0, npc.Position, (REVEL.player.Position-npc.Position):Resized(data.bal.SnowballsWendySnowpileAttackVelocity()):Rotated(math.random(-data.bal.SnowballsWendySnowpileAttackAngleOffset,data.bal.SnowballsWendySnowpileAttackAngleOffset)), data.Wendy):ToProjectile()
			proj.FallingSpeed = math.random()*-25
			proj.FallingAccel = 1
			proj:GetSprite():ReplaceSpritesheet(0, data.bal.SnowballSpritesheet)
			proj:GetSprite().PlaybackSpeed = 0
			proj:GetSprite():LoadGraphics()
			REVEL.GetData(proj).isFrostyProjectile = true
		end
		REVEL.sfx:Play(SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1, 0, false, 1)
		REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.8, 0, false, 1)
		REVEL.GetData(data.Wendy).State = "Snow Stalking"
		REVEL.GetData(data.Wendy).TimerBetweenStates = 0
		data.Wendy.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		data.Wendy.Position = npc.Position
		data.Wendy.Velocity = Vector.Zero
	end
	
	-- snowpiles will slowly regenerate back to their former state
	local regentime = REVEL.GetData(data.Wendy).IceCreamShowerRegenTime or data.bal.SnowpileRegenTime
	if data.RegenTimer == regentime and sprite:IsFinished("Idle2") then
		sprite:Play("Regen1", true)
		data.RegenTimer = 0
	elseif sprite:IsFinished("Regen1") then
		sprite:SetFrame("Regen1Idle", 0)
	elseif data.RegenTimer == regentime and sprite:IsFinished("Regen1Idle") then
		sprite:Play("Regen2", true)
		data.RegenTimer = 0
	elseif sprite:IsFinished("Regen2") then
		sprite:SetFrame("Regen2Idle", 0)
	elseif data.RegenTimer == regentime and sprite:IsFinished("Regen2Idle") then
		sprite:Play("Regen3", true)
		data.RegenTimer = 0
	elseif sprite:IsFinished("Regen3") then
		sprite:SetFrame("Regen3Idle", 0)
	elseif data.RegenTimer == regentime and sprite:IsFinished("Regen3Idle") then
		sprite:Play("RegenFinal", true)
		data.RegenTimer = 0
	elseif sprite:IsPlaying("RegenFinal") and sprite:IsEventTriggered("Regen") then
		npc.HitPoints = npc.MaxHitPoints
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	elseif sprite:IsFinished("RegenFinal") or sprite:IsFinished("RegenFast") then
		sprite:SetFrame("Idle", 0)
		REVEL.GetData(data.Wendy).IceCreamShowerRegenTime = nil
		npc:GetSprite().PlaybackSpeed = 1
	elseif sprite:IsFinished("Shake") then
		sprite:Play("WendyHideIdle", true)
	elseif sprite:IsFinished("Destroy") then
		if REVEL.room:GetGridIndex(npc.Position) == 37 and (data.Wendy:IsDead() or not data.Wendy:Exists()) then
			npc:Remove()
			return
		end
		
		sprite:SetFrame("Idle2", 0)
	end
	
	if data.Wendy:IsDead() or not data.Wendy:Exists() then
		data.RegenTimer = -1
		if not sprite:IsPlaying("Destroy") and not sprite:IsFinished("Idle2") then
			sprite:Play("Destroy", true)
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
	end
end

---@param npc EntityNPC
local function StalagmiteUpdate(npc)
	local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

	if npc.SubType == 0 then -- subtype 0, the stalagmite stuck in the ground
		npc.Velocity = Vector.Zero
		
		if sprite:IsPlaying("Emerge") then -- let the animation stop at certain keyframes to make the stalagmite emerge in waves
			if not data.dontchangeplaybackspeedthisframe and (sprite:GetFrame() == 7 or sprite:GetFrame() == 11) then
				sprite.PlaybackSpeed = 0
			end
			if data.dontchangeplaybackspeedthisframe then
				data.dontchangeplaybackspeedthisframe = false
			end
		end
		
		if sprite:IsEventTriggered("Launch") then -- the stalagmite being sucked up by the whirlwind
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
		if sprite:IsFinished("Launch") then
			npc:Remove()
		end
		
		-- the stalagmite fully uncovered, beginning to be a threat to the player
		if sprite:IsFinished("Emerge") and npc.EntityCollisionClass == EntityCollisionClass.ENTCOLL_NONE then
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		end
	elseif npc.SubType == 1 then -- subtype 1, the stalagmite fired at the player
		for _,player in ipairs(REVEL.players) do -- damages the player whenever the player gets too close
			if (player.Position-npc.Position):LengthSquared() <= 1225 then
				player:TakeDamage(1, 0, EntityRef(npc), 20)
			end
		end
		-- the stalagmite breaks whenever it hits the side of the room
		if REVEL.IsOutOfRoomBy(npc.Position, 0) and not (sprite:IsPlaying("FlyingBreak") or sprite:IsFinished("FlyingBreak")) then
			sprite:Play("FlyingBreak", true)
			SFXManager():Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 0.9+math.random()*0.1)
			for i = 1, math.random(1, 8) do
				local eff = Isaac.Spawn(1000, EffectVariant.POOP_PARTICLE, 0, npc.Position + Vector(0, REVEL.ZPos.GetPosition(npc)), RandomVector() * math.random(1,5), npc)
				REVEL.GetData(eff).NoGibOverride = true
				eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/snow_gibs.png")
				eff:GetSprite():LoadGraphics()
			end
		end
		if sprite:IsFinished("FlyingBreak") then
			npc:Remove()
		end
	end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant == REVEL.ENT.WENDY.variant then
		WendyUpdate(npc)
	elseif npc.Variant == REVEL.ENT.WENDY_SNOWPILE.variant then
		SnowpileUpdate(npc)
	elseif npc.Variant == REVEL.ENT.WENDY_STALAGMITE.variant then
		StalagmiteUpdate(npc)
	end
end, REVEL.ENT.WENDY.id)

local function SnowpileDeath(snowpile)
	local data = REVEL.GetData(snowpile)
	snowpile.HitPoints = 0
	snowpile:GetSprite():Play("Destroy", true)
	data.RegenTimer = 0
	snowpile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	REVEL.sfx:Play(SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1.8)
	if REVEL.GetData(data.Wendy).State == "Hiding In Snowpile" then
		if snowpile.Index == REVEL.GetData(data.Wendy).CurrentSnowpile.Index then
			REVEL.GetData(data.Wendy).State = "Stunned"
			REVEL.GetData(data.Wendy).TimerBetweenStates = 0
			data.Wendy:GetSprite():Play("Stun", true)
			REVEL.PlaySound(snowpile, data.bal.Sounds.StunStart)
			data.Wendy:GetSprite().FlipX = (data.Wendy:ToNPC():GetPlayerTarget().Position.X - data.Wendy.Position.X) > 0
			data.Wendy.Visible = true
			data.Wendy.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			data.Wendy.Position = snowpile.Position
			data.Wendy.Velocity = Vector.Zero
		elseif not REVEL.GetData(data.Wendy).IsChampion then
			REVEL.GetData(data.Wendy).CurrentSnowpile:GetSprite():Play("WendyHideMad", true)
		end
	end
	
	if REVEL.GetData(data.Wendy).IsChampion then
		if not data.StopSnowballSpawning then
			local snowball
			if data.StrawberryIceCream then
				snowball = REVEL.ENT.STRAWBERRY_SNOWBALL
			elseif data.PissIceCream then
				snowball = REVEL.ENT.YELLOW_SNOWBALL
			elseif data.WhiteIceCream then
				snowball = REVEL.ENT.SNOWBALL
			end
			for i=1, data.bal.ChampionNumDipsInSnowpile() do
				local snowball = Isaac.Spawn(snowball.id, snowball.variant, 0, snowpile.Position + Vector.FromAngle(math.random(0,359))*math.random(15,25), Vector.Zero, snowpile)
			end
		else
			data.StopSnowballSpawning = false
		end
	end
	snowpile:RemoveStatusEffects()
	data.Dying = true
	snowpile.State = NpcState.STATE_UNIQUE_DEATH
end

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
	if not REVEL.IsRenderPassNormal() then return end

	local data = REVEL.GetData(npc)
	if npc.Variant == REVEL.ENT.WENDY_SNOWPILE.variant then
		if data.Wendy and not data.Dying and npc:HasMortalDamage() then
			SnowpileDeath(npc)
		end
		
		local sprite = npc:GetSprite()
		if data.Dying and sprite:IsFinished("Destroy") then
			local new_snowpile = Isaac.Spawn(REVEL.ENT.WENDY_SNOWPILE.id, REVEL.ENT.WENDY_SNOWPILE.variant, 0, npc.Position, Vector.Zero, nil)
			local snowpile_data = REVEL.GetData(new_snowpile)
			for k,v in pairs(data) do
				snowpile_data[k] = v
			end
			snowpile_data.Dying = false
			new_snowpile.MaxHitPoints = snowpile_data.bal.SnowpileMaxHP
			new_snowpile.HitPoints = snowpile_data.bal.SnowpileMaxHP
			new_snowpile:GetSprite().FlipX = sprite.FlipX
			new_snowpile.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			if REVEL.GetData(data.Wendy).IsChampion then
				if data.StrawberryIceCream then
					snowpile_data.StrawberryIceCream = true
					new_snowpile:GetSprite():ReplaceSpritesheet(0, snowpile_data.bal.SnowpileStrawberrySprite)
					new_snowpile:GetSprite():LoadGraphics()
				elseif data.PissIceCream then
					snowpile_data.PissIceCream = true
					new_snowpile:GetSprite():ReplaceSpritesheet(0, snowpile_data.bal.SnowpilePissSprite)
					new_snowpile:GetSprite():LoadGraphics()
				else
					snowpile_data.WhiteIceCream = true
				end
			end
			for i,snowpile in ipairs(REVEL.GetData(data.Wendy).Snowpiles) do
				if snowpile.Index == npc.Index then
					REVEL.GetData(data.Wendy).Snowpiles[i] = new_snowpile
					break
				end
			end
			new_snowpile:GetSprite():SetFrame("Idle2", 0)
			npc:Remove()
			return
		end
	end
end, REVEL.ENT.WENDY.id)

REVEL.AddDeathEventsCallback{
	OnDeath = function(npc)
		local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
		if REVEL.sfx:IsPlaying(REVEL.SFX.BIRD_STUN) then
			REVEL.sfx:Stop(REVEL.SFX.BIRD_STUN)
		end

		npc.Visible = true
		
		if data.Stalagmites then
			for _,stalagmite in ipairs(data.Stalagmites) do
				stalagmite:GetSprite():Play("Launch", true)
			end
		end
		if data.Snowballs then
			for _,snowball in ipairs(data.Snowballs) do
				if snowball.Type == EntityType.ENTITY_PROJECTILE then
					snowball:Die()
				else
					snowball:Remove()
				end
			end
		end

		REVEL.DisableWindSound(npc)
		REVEL.PlaySound(data.bal.Sounds.Death)
	end,
	DeathRender = function (npc, triggeredEventThisFrame)
		local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
		if IsAnimOn(sprite, "Death") and not triggeredEventThisFrame then
			local justTriggered
			if data.bal.Sounds.WhirlwindLoop then
				REVEL.sfx:Stop(data.bal.Sounds.WhirlwindLoop.Sound)
				REVEL.DisableWindSound(npc)
			end
			if sprite:IsEventTriggered("SkullBurn") then
				REVEL.PlaySound(data.bal.Sounds.SkullToDust)
				justTriggered = true
			end
			if sprite:IsFinished("Death") and not triggeredEventThisFrame then
				npc:Die()
				justTriggered = true
			end
			return justTriggered
		end
	end,
	Type = REVEL.ENT.WENDY.id,
	Variant = REVEL.ENT.WENDY.variant,
}

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
	local data = REVEL.GetData(e)
	if e.Variant == REVEL.ENT.WENDY_SNOWPILE.variant then
	
		if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0 then
			SnowpileDeath(e:ToNPC())
		end
		
		if REVEL.WendyStormOverlayActive or e.EntityCollisionClass == EntityCollisionClass.ENTCOLL_NONE then -- snowpiles are invincible whenever the storm is active or when they're destroyed
			return false
		end
		if not data.DmgIsSnowstormMultDmg and REVEL.GetData(data.Wendy).State == "Hiding In Snowpile" and data.bal.PostSnowstormSnowpileDmgMult ~= 1 then -- snowpiles are 5 times as vulnerable whenever the snowstorm is finished
			data.DmgIsSnowstormMultDmg = true
			e:TakeDamage(dmg*(data.bal.PostSnowstormSnowpileDmgMult-1), flag, src, invuln)
			data.DmgIsSnowstormMultDmg = false
		end
		
	elseif e.Variant == REVEL.ENT.WENDY.variant then
		local sprite = e:GetSprite()
		if e.EntityCollisionClass == EntityCollisionClass.ENTCOLL_NONE or sprite:IsPlaying("Appear") and not sprite:WasEventTriggered("Pop") then -- invincible when hiding, or before popping out when appearing
			return false
		end
	
		if not e.Visible then -- damage reduction when sneaking
			e.HitPoints = e.HitPoints + (dmg*data.bal.DamageReductionOnSneak)
		end

		if e:GetSprite():IsPlaying("GroundPound") or e:GetSprite():IsPlaying("WhirlwindStart") then
			local dmgReduction = dmg*0.5
			e.HitPoints = math.min(e.HitPoints + dmgReduction, e.MaxHitPoints)
		end
		
		if not data.IsChampion then
			if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) 
					<= e.MaxHitPoints*0.7 and not data.SpikeyTime then -- on 2/3 health, start spikey time
				data.SpikeyTime = "Active"
			elseif e.HitPoints - dmg - REVEL.GetDamageBuffer(e) 
					<= e.MaxHitPoints*0.4 and not data.WhirlwindTime then -- on 1/3 health, start whirlwind
				data.WhirlwindTime = "Active"
			end
		end
	end
end, REVEL.ENT.WENDY.id)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff) -- wendy footprint effect
	if REVEL.GetData(eff).IsWendyFootprint then
		local sprite = eff:GetSprite()
		if sprite:IsFinished("Appear") then 
			sprite:SetFrame("Idle", 0) 
		elseif sprite:IsFinished("Appear2") then 
			sprite:SetFrame("Idle2", 0) 
		end
		if eff.FrameCount == REVEL.GetData(eff).FootprintFramesUntilFadeOut then
			if sprite:IsFinished("Idle") then
				sprite:Play("Disappear", true)
			elseif sprite:IsFinished("Idle2") then
				sprite:Play("Disappear2", true)
			end
		end
		if sprite:IsFinished("Disappear") or sprite:IsFinished("Disappear2") then
			eff:Remove()
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function() -- snowstorm overlay
	if REVEL.WendyStormOverlayActive
	and (
		revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH
		or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY
	) then
		REVEL.OVERLAY.Glacier1:Render()
		REVEL.OVERLAY.Glacier7:Render()
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
	if REVEL.GetData(proj).KeepVel then
		proj.Velocity = REVEL.GetData(proj).KeepVel
	end
end)

revel:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, function(_, proj, coll, low)
	if REVEL.GetData(proj).IgnoreHitOnSpawn and proj.FrameCount <= 5 then
		return false
	end
end)

end