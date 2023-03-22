local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------
--SANDY--
---------
do

local sandyBalance = {
    Champions = {Jeffrey = "Default", War = "Default"},

	Spritesheet = {Default = "gfx/bosses/revel2/sandy/sandy.png", Jeffrey = "gfx/bosses/revel2/sandy/jeffrey.png", War = "gfx/bosses/revel2/sandy/sandy_champion.png"},
	Revive = {Default = true, Jeffrey = false, War = false},

    JeffreyPercentFightTime = {Default = 0.25, Jeffrey = false, War = false},

	DamageModifier = {Default = 1, Jeffrey = 0.6},
	HealthModifier = {Default = 1, War = 1.5},

	ForceWarIntro = {Default = false, War = true},
	NoJeffreySpawns = {Default = false, War = true},

	SandholeAttackWeights = {
		Default = {
			SpitRocks = 5
		},
		War = {
			SpitRocks = 5,
			WarProjectiles = 3,
			WarBombs = 2
		}
	},

	SandholeRocksCanHitCoffins = {Default = true, War = false},

	DeathFallbackFramesSinceDeath = 10 * 30,
}

local enableSandyBossMusic = false

local function sandyRoom_PostSelectBossMusic(stage, musicID, isCleared, rng)
	if musicID == REVEL.SFX.TOMB_BOSS and StageAPI.GetCurrentRoomType() == RevRoomType.BOSS_SANDY and not isCleared and not enableSandyBossMusic then
		return REVEL.SFX.BLANK_MUSIC
	end
end

local function killNearbyBabies(npc, data, position, radius)
	position = position or npc.Position
	radius = radius or 30
	for i,ent in ipairs(Isaac.FindInRadius(position, radius, EntityPartition.ENEMY)) do
		if ent.Type ~= REVEL.ENT.SANDY.id and ent.Variant ~= REVEL.ENT.SANDY.variant then
			if (ent.Type == REVEL.ENT.ANTLION_BABY.id and ent.Variant == REVEL.ENT.ANTLION_BABY.variant) then
				ent:Kill()
			elseif (ent.Type == REVEL.ENT.ANTLION_EGG.id and ent.Variant == REVEL.ENT.ANTLION_EGG.variant) then
				REVEL.BreakEgg(ent)
			elseif ent.Type == EntityType.ENTITY_WAR and ent:GetData().SandyParent and GetPtrHash(ent:GetData().SandyParent) == GetPtrHash(npc) then
				if ent.Variant == 10 then
					revel.data.sandySeenWarIntro = true
					StageAPI.GetBossData("Sandy").Portrait = "gfx/ui/boss/revel2/sandy_portrait.png"
					StageAPI.GetBossData("Sandy").Bossname = "gfx/ui/boss/revel2/sandy_name.png"
					ent:Kill()
					data.AteWar = true
					enableSandyBossMusic = true
				elseif data.KillingWar then
					ent:Kill()
					data.AteWar = true
					data.KillingWar = false
				end
			else
				ent:TakeDamage(3, 0, EntityRef(npc), 0)
			end
		end
	end
end

local function setSandyOppositePos(npc, data, targetPos, horizontal, speed)
	local targetPosFromCenter = targetPos - REVEL.room:GetCenterPos()
	if horizontal then
		local leftPos = REVEL.room:GetClampedPosition(Vector(REVEL.room:GetTopLeftPos().X, targetPos.Y), 40)
		local rightPos = REVEL.room:GetClampedPosition(Vector(REVEL.room:GetBottomRightPos().X, targetPos.Y), 40)
		if targetPosFromCenter.X > 0 then
			data.BurrowPos = leftPos
			data.OppositePos = rightPos
		else
			data.BurrowPos = rightPos
			data.OppositePos = leftPos
			data.SetFlipXAtAttackInit = true
		end
		data.AttackExtra = " Side"
		local toOppositeVelocity = (data.OppositePos - data.BurrowPos):Normalized()
		local toTargetVelocity = (targetPos - data.BurrowPos):Normalized()
		data.VelocityToOpposite = Vector(toOppositeVelocity.X * speed, toTargetVelocity.Y)
	else
		local topPos = REVEL.room:GetClampedPosition(Vector(targetPos.X, REVEL.room:GetTopLeftPos().Y), 40)
		local bottomPos = REVEL.room:GetClampedPosition(Vector(targetPos.X, REVEL.room:GetBottomRightPos().Y), 40)
		if targetPosFromCenter.Y > 0 then
			data.BurrowPos = topPos
			data.OppositePos = bottomPos
			data.AttackExtra = " Down"
		else
			data.BurrowPos = bottomPos
			data.OppositePos = topPos
			data.AttackExtra = " Up"
		end
		local toOppositeVelocity = (data.OppositePos - data.BurrowPos):Normalized()
		local toTargetVelocity = (targetPos - data.BurrowPos):Normalized()
		data.VelocityToOpposite = Vector(toTargetVelocity.X, toOppositeVelocity.Y * speed)
	end
end

local function spawnRandomEgg(noJeffrey, npc)
	local egg = Isaac.Spawn(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, 0, REVEL.room:GetClampedPosition(Isaac.GetRandomPosition(), 40), Vector.Zero, npc)
	local eggData, eggSprite = egg:GetData(), egg:GetSprite()
	eggData.OnlyBreak = true
	if noJeffrey then
		eggData.NoJeffrey = true
	end
	eggSprite:Play("Emerge", true)
end

local function spawnDirtChunk(npc, amount, speed, dontSpawnEgg, aimAtCoffins)
	speed = speed or 3
	local data, target = npc:GetData(), npc:GetPlayerTarget()
	if not dontSpawnEgg and data.IsRevived and (amount > 1 or math.random(1,3) == 3) and (Isaac.CountEntities(nil, REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1) or 0) < 3 then
		amount = amount - 1
		local egg = Isaac.Spawn(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, 0, npc.Position, Vector.Zero, npc)
		local eggData = egg:GetData()
		eggData.IsThrownEgg = true
		eggData.TimedBreak = true
		eggData.OnlyBreak = true
		eggData.ZPosition = data.ZPosition or 0
		eggData.ZPosition = eggData.ZPosition + 10
		if data.bal.NoJeffreySpawns then
			eggData.NoJeffrey = true
		end
	end
	for i=1, amount do
		local velocity = RandomVector() * speed
		local fallingSpeed = math.random(1200, 1600) * -0.01
		local coffinToActivate = nil
		if aimAtCoffins then
			local targetPosFromCenter = target.Position - REVEL.room:GetCenterPos()
			local coffins = {}
			for _, coffin in ipairs(Isaac.FindByType(REVEL.ENT.CORNER_COFFIN.id, REVEL.ENT.CORNER_COFFIN.variant, -1, false, false)) do
				local coffinSprite = coffin:GetSprite()
				if targetPosFromCenter.X < 0 then
					if coffinSprite.Rotation < 0 or coffinSprite.Rotation > 180 then
						coffins[#coffins+1] = coffin
					end
				else
					if not (coffinSprite.Rotation < 0 or coffinSprite.Rotation > 180) then
						coffins[#coffins+1] = coffin
					end
				end
			end
			if #coffins > 0 then
				local coffinToHit = math.random(1, #coffins)
				coffinToActivate = coffins[coffinToHit]

				local shootAtPos = coffinToActivate.Position
				local coffinToActivateSprite = coffinToActivate:GetSprite()
				if coffinToActivateSprite.Rotation < -90 or coffinToActivateSprite.Rotation > 90 then
					shootAtPos = shootAtPos + Vector(0,40)
				end
				velocity = (shootAtPos - npc.Position) * 0.05

				fallingSpeed = -12
				aimAtCoffins = false

				data.SandholePosStart = REVEL.room:GetCenterPos()
				if coffinToActivateSprite.Rotation < 0 or coffinToActivateSprite.Rotation > 180 then
					data.SandholePosEnd = REVEL.room:GetCenterPos() + Vector(120,0)
				else
					data.SandholePosEnd = REVEL.room:GetCenterPos() + Vector(-120,0)
				end
				data.ActivatedCoffins = true
				data.ActivatingCoffins = true
			end
		end
		local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, velocity, npc):ToProjectile()
		local psprite = proj:GetSprite()
		psprite:ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
        psprite:LoadGraphics()

		local pdata = proj:GetData()
		pdata.ChangeToDirtChunk = true
		if coffinToActivate then
			pdata.CoffinToActivate = coffinToActivate
		else
			pdata.SpawnAntlionBaby = true
			if data.IsChampion then
				pdata.NoJeffreySpawn = true
			end
		end
		proj.Scale = proj.Scale * (math.random(200, 300) * 0.01)
		proj.FallingSpeed = fallingSpeed
		proj.FallingAccel = 0.5
	end
end

local function spitSandyWar(sandy, position, velocity, animation, noHorse)
	local variant = 0
	if noHorse then
		variant = 10
	end
	local war = Isaac.Spawn(EntityType.ENTITY_WAR, variant, 0, (position or sandy.Position), (velocity or Vector.Zero), sandy):ToNPC()
	local warData, warSprite = war:GetData(), war:GetSprite()
	if war.SubType ~= 0 then
		war.SubType = 0
		warSprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
		war.Scale = 1
	end

	war:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	war:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
	war.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	war.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

	warData.SandyParent = sandy

	REVEL.ZPos.SetData(war, {
		ZVelocity = 3,
		ZPosition = 65,
		Gravity = 0.08,
		DoRotation = false,
		DisableCollision = false,
		EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.DONT_HANDLE,
		BounceFromGrid = false,
		LandFromGrid = false,
		PoofInPits = false,
		DisableAI = true
	})
	REVEL.ZPos.UpdateEntity(war)

	if noHorse then
		warSprite:Load("gfx/bosses/revel2/sandy/sandy_war_without_horse.anm2", true)
	else
		warSprite:Load("gfx/bosses/revel2/sandy/sandy_war.anm2", true)
	end
	warSprite:Play((animation or "InAir"), true)
	war.RenderZOffset = sandy.RenderZOffset + 1

	return war
end

local function chooseSandyAttack(npc, data, sprite, target)
	npc.RenderZOffset = data.InitRenderZOffset
	data.SetFlipXAtAttackInit = false
	data.AttackExtra = ""
	data.BurrowPos = Vector.Zero
	data.OppositePos = Vector.Zero
	data.VelocityToOpposite = Vector.Zero

	local attacks = {}
	local healthPercentage = math.ceil((npc.HitPoints / npc.MaxHitPoints)*100)
	if healthPercentage > 65 or healthPercentage <= 5 or data.IsRevived then
		if (data.BasicAttackCounter > -2 or (data.IsChampion and not data.AteWar)) and healthPercentage > 5 then
			local oppositePosition = target.Position
			if data.IsChampion and not data.AteWar then
				for i,war in ipairs(Isaac.FindByType(EntityType.ENTITY_WAR, 0, -1, false, true)) do
					local warData = war:GetData()
					if warData.SandyParent and GetPtrHash(warData.SandyParent) == GetPtrHash(npc) then
						if data.AttacksAfterWarSpawn >= 2 then
							target = war
						end
						if war.Velocity.X > 0 then
							oppositePosition = Vector(REVEL.room:GetTopLeftPos().X, target.Position.Y)
						else
							oppositePosition = Vector(REVEL.room:GetBottomRightPos().X, target.Position.Y)
						end
						break
					end
				end
			end
			if not data.LastAttack or data.LastAttack ~= "Jump" then --JUMP
				attacks[#attacks+1] = function()
					data.BasicAttackCounter = data.BasicAttackCounter - 1
					data.BurrowTimer = math.random(20,30)
					data.BurrowPos = oppositePosition + Vector(math.random(-30,30), math.random(-30,30))
					data.Attack = "Jump"
					if (data.LastAttack and math.random(1,2) == 2) then --jump side
						data.BurrowTimer = math.random(40,60)
						local speed = 12
						if data.IsRevived then
							speed = 16
						end
						local roomShape = REVEL.room:GetRoomShape()
						if roomShape == RoomShape.ROOMSHAPE_IH
						or roomShape == RoomShape.ROOMSHAPE_2x1
						or roomShape == RoomShape.ROOMSHAPE_IIH
						or roomShape == RoomShape.ROOMSHAPE_2x2 then
							speed = math.ceil(speed * 1.5)
						end
						setSandyOppositePos(npc, data, oppositePosition, true, speed)
					end
				end
			end
			if data.LastAttack and data.LastAttack ~= "Dash" then --DASH
				attacks[#attacks+1] = function()
					data.BasicAttackCounter = data.BasicAttackCounter - 1
					data.BurrowTimer = math.random(40,60)
					data.Attack = "Dash"
					local speed = 12
					if data.IsRevived then
						speed = 16
					end
					-- if math.random(1,2) == 2 then --horizontal dash
						setSandyOppositePos(npc, data, oppositePosition, true, speed)
					-- else --vertical dash
						-- setSandyOppositePos(npc, data, oppositePosition, false, speed)
					-- end
				end
			end
		end
		if (data.BasicAttackCounter <= 0 and (not data.IsChampion or (data.IsChampion and data.AteWar))) or healthPercentage <= 5 then
			-- if data.LastAttack and data.LastAttack ~= "Shriek" then --SHRIEK
				attacks[#attacks+1] = function()
					data.BasicAttackCounter = 2
					data.BurrowTimer = math.random(20,30)
					data.Attack = "Shriek"
					data.BurrowPos = npc.Position
				end
			-- end
		end
	else
		-- if data.LastAttack and data.LastAttack ~= "Sinkhole" then --SINKHOLE
			attacks[#attacks+1] = function()
				data.BasicAttackCounter = 2
				data.BurrowTimer = math.random(20,30)
				data.Attack = "Sinkhole"
				data.BurrowPos = REVEL.room:GetCenterPos()
			end
		-- end
	end

	local attackToDo = math.random(1,#attacks)
	attacks[attackToDo]()
	data.LastAttack = data.Attack
	data.State = "Burrowed"
end

local function initSandyAttack(npc, data, sprite, target)
	if not data.Attack then
		chooseSandyAttack(npc, data, sprite, target)
	end
	npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	sprite.FlipX = data.SetFlipXAtAttackInit
	local healthPercentage = math.ceil((npc.HitPoints / npc.MaxHitPoints)*100)
	if data.Attack == "Jump" then
		data.ZVelocity = 0
		data.ZPosition = 0
		data.Gravity = 0.5
		sprite:Play("Jump" .. data.AttackExtra .. " Start", true)
	elseif data.Attack == "Dash" then
		sprite:Play("Dash" .. data.AttackExtra .. " Start", true)
	elseif data.Attack == "Shriek" then
		if healthPercentage > 5 then
			sprite:Play("Dig Up", true)
		else
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			data.BurrowMovementTimer = 30
			npc.Position = REVEL.room:GetClampedPosition(Isaac.GetRandomPosition(), 10)
		end
		data.SpawnDirtChunkCooldown = 12
		data.ShriekCountdown = 100
		if data.IsChampion then
			data.ShriekCountdown = 60
		end
		if data.IsRevived then
			data.ShriekCountdown = 60
		end
		killNearbyBabies(npc, data)
	elseif data.Attack == "Sinkhole" then
		npc.RenderZOffset = -3000
		sprite:Play("Suck Start", true)
		data.Spits = 0
	else
		data.Attack = "Idle"
		sprite:Play("Dig Up", true)
		killNearbyBabies(npc, data)
	end
	data.State = data.Attack
	data.Attack = nil
end

local function spawnSandyBaby(position, velocity, spawner, noJeffrey)
	local toSpawn = REVEL.ENT.ANTLION_BABY
	if not noJeffrey and math.random(1,10) == 1 and not revel.data.run.jeffreySeen then
		toSpawn = REVEL.ENT.JEFFREY_BABY
		revel.data.run.jeffreySeen = true
	end
	local baby = Isaac.Spawn(toSpawn.id, toSpawn.variant, 0, position, velocity, spawner)
	baby:GetData().IsEnraged = true --does nothing with jeffrey
	return baby
end

local shadowChangeAnims = {
    "Jump Start",
    "Jump Side Start",
    "Jump Land"
}

local function sandy_PreEntitySpawn(_, type, variant, subType, position, velocity, spawner, seed)
	if type == REVEL.ENT.SANDY.id and variant == REVEL.ENT.SANDY.variant and subType ~= 1 then
		return {
			type,
			variant,
			1,
			seed
		}
	end
end


local function sandy_Sandy_NpcUpdate(_, npc)
	if npc.Variant == REVEL.ENT.SANDY.variant then
		local data, sprite, target, healthPercentage = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget(), math.ceil((npc.HitPoints / npc.MaxHitPoints)*100)

		if not data.Init then
			npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_STATUS_EFFECTS)
			npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

			data.IsChampion = REVEL.IsChampion(npc)

			--sets balance
			if data.IsChampion then
				data.bal = REVEL.GetBossBalance(sandyBalance, "War")
			else
				data.bal = REVEL.GetBossBalance(sandyBalance, "Default")
			end

			--applies spritesheet
			for layer=0, 2 do
				sprite:ReplaceSpritesheet(layer, data.bal.Spritesheet)
			end
			sprite:LoadGraphics()

            REVEL.SetScaledBossHP(npc)

			--applies HealthModifier
			if data.bal.HealthModifier and data.bal.HealthModifier ~= 1 then
				npc.MaxHitPoints = npc.MaxHitPoints * data.bal.HealthModifier
			end

			data.OriginalMaxHitPoints = npc.MaxHitPoints
            if data.bal.JeffreyPercentFightTime then
                npc.MaxHitPoints = data.OriginalMaxHitPoints - (data.OriginalMaxHitPoints * data.bal.JeffreyPercentFightTime)
            end

            npc.HitPoints = npc.MaxHitPoints

			data.InitRenderZOffset = npc.RenderZOffset
			data.BasicAttackCounter = 4
			data.StartFightCounter = 0
			data.StartedFight = true
			data.AttacksAfterWarSpawn = 0

			local currentRoom = StageAPI.GetCurrentRoom()
			local boss = nil
			if currentRoom then
				boss = StageAPI.GetBossData(currentRoom.PersistentData.BossID)
			end

			--special intros
			if boss and (boss.Name == "Sandy" or boss.NameTwo == "Sandy") then
				--regular into, sandy spawns ass up and after doing a few things the fight starts
				if revel.data.sandySeenWarIntro and not data.bal.ForceWarIntro then
					npc:AddEntityFlags(EntityFlag.FLAG_HIDE_HP_BAR)
					REVEL.DelayFunction(function()
						-- Adding it immediately early ends the vs screen
						npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
					end, 1, nil, true, true)
					sprite:Play("Ass", true)
					data.State = "Ass"
					data.StartFightCounter = 5
					if npc.CollisionDamage > 0 then
						npc.CollisionDamage = 0
					end
					data.StartedFight = false

					--calm the babies
					for _, baby in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1, false, false)) do
						baby:GetData().IsEnraged = false
					end
					for _, jeffrey in ipairs(Isaac.FindByType(REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, -1, false, false)) do
						jeffrey:GetData().IsRunningAway = true
					end

				--war intro, war spawns in the crying state and sandy jumps up from below, eating war
				else
					sprite:Play("Burrowed Appear", true)

					--spawn war and set him up for this
					local war = Isaac.Spawn(EntityType.ENTITY_WAR, 10, 0, npc.Position, Vector.Zero, npc):ToNPC()
					local warData, warSprite = war:GetData(), war:GetSprite()
					if war.SubType ~= 0 then
						war.SubType = 0
						warSprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
						war.Scale = 1
					end
					warData.SandyParent = npc
					war:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					war:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
					war.State = NpcState.STATE_ATTACK --8, crying
					warSprite:Play("Cry", true)
					war.RenderZOffset = npc.RenderZOffset + 1
					npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

					--set up the attack
					chooseSandyAttack(npc, data, sprite, war)
					data.BurrowTimer = 30

					--empty the room
					for _, baby in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1, false, false)) do
						baby:Remove()
					end
					for _, jeffrey in ipairs(Isaac.FindByType(REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, -1, false, false)) do
						jeffrey:Remove()
					end
					for _, egg in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1, false, false)) do
						egg:Remove()
					end
				end

			--regular intro, plays appear animation, should only happen if sandy spawns outside of a boss room
			else
				sprite:Play("Appear", true)
				data.IdleTimer = math.random(20, 40)
				data.State = "Idle"
			end

			--enrage the babies if the fight started immediately
			if data.StartedFight then
				for _, baby in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1, false, false)) do
					baby:GetData().IsEnraged = true
				end
			end

			data.Init = true
		end

		REVEL.ApplyKnockbackImmunity(npc)

		--shadow handler, morphs sandy to and from the shadow/shadowless subtype when needed
        local noShadow, showShadow = sprite:IsEventTriggered("No Shadow"), sprite:IsEventTriggered("Show Shadow")
        if noShadow or showShadow then
            local playingAnim
            for _, anim in ipairs(shadowChangeAnims) do
                if sprite:IsPlaying(anim) then
                    playingAnim = anim
                end
            end

            local frame = sprite:GetFrame()
            local maxHP = npc.MaxHitPoints
            local hp = npc.HitPoints

            if noShadow and npc.SubType ~= 1 then
                npc:Morph(npc.Type, npc.Variant, 1, -1)
            elseif showShadow and npc.SubType ~= 0 then
                npc:Morph(npc.Type, npc.Variant, 0, -1)
            end

			for layer=0, 2 do
				sprite:ReplaceSpritesheet(layer, data.bal.Spritesheet)
			end
			sprite:LoadGraphics()

            npc.MaxHitPoints = maxHP
            npc.HitPoints = hp

            if playingAnim then
                sprite:Play(playingAnim, true)
                if frame > 0 then
                    for i = 1, frame do
                        sprite:Update()
                    end
                end
            end
        end

		if data.State == "Squirm" then
			npc.Velocity = Vector.Zero
			if sprite:IsEventTriggered("Slam") then
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
				spawnDirtChunk(npc, math.random(2,3))
				if data.IsChampion and data.AteWar then
					local warProjParams = ProjectileParams()
					warProjParams.FallingAccelModifier = warProjParams.FallingAccelModifier + 0.1
					npc:FireProjectiles(npc.Position, Vector(10,0), 8, warProjParams)
				end
			end
			if sprite:IsFinished("Jump Land") then
				sprite:Play("Squirm")
				data.SquirmTimer = math.random(50, 90)
			end
			if sprite:IsPlaying("Squirm") then
				data.SquirmTimer = data.SquirmTimer - 1
				if data.SquirmTimer <= 0 then
					sprite:Play("Squirm End")
					chooseSandyAttack(npc, data, sprite, target)
				end
			end
		elseif data.State == "Ass" then
			npc.Velocity = Vector.Zero
			if data.StartFightCounter <= 0 and not data.StartedFight then
				if npc.CollisionDamage < 1 then
					npc.CollisionDamage = 1
				end
				sprite:Play("Ass End", true)
				enableSandyBossMusic = true
				chooseSandyAttack(npc, data, sprite, target)
				data.StartedFight = true
				npc:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
				for _, baby in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1, false, false)) do
					baby:GetData().IsEnraged = true
				end
			end
		elseif data.State == "Idle" then
			npc.Velocity = Vector.Zero
			if sprite:IsFinished("Appear") or sprite:IsFinished("Dig Up") or sprite:IsFinished("Death Revive") then
				sprite:Play("Idle", true)
			end
			if sprite:IsPlaying("Idle") then
				data.IdleTimer = data.IdleTimer - 1
				if data.IdleTimer <= 0 then
					chooseSandyAttack(npc, data, sprite, target)
					sprite:Play("Dig Down", true)
				end
			end
		elseif data.State == "Burrowed" then
			npc.Velocity = Vector.Zero
			if sprite:IsFinished("Dig Down") or sprite:IsFinished("Suck End") or sprite:IsFinished("Squirm End") or sprite:IsFinished("Ass End") or data.ImmediateBurrow then
				sprite:Play("Burrowed Appear", true)
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				npc.Position = REVEL.room:GetClampedPosition(data.BurrowPos, 40)
				data.ImmediateBurrow = false
				-- for i=1, math.random(7,12) do
					-- REVEL.SpawnSandGibs(data.BurrowPos, RandomVector() * 2)
				-- end
				-- for i=1, math.random(2,5) do
					-- local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, RandomVector(), npc)
					-- rock:Update()
				-- end
			end
			if sprite:IsFinished("Burrowed Appear") then
				sprite:Play("Burrowed Idle")
			end
			if sprite:IsPlaying("Burrowed Idle") then
				data.BurrowTimer = data.BurrowTimer - 1

				local initAttack = false
				if data.IsChampion and not data.AteWar and data.Attack == "Dash" and data.AttackExtra == " Side" then
					local currentWar
					local warIsHere = false
					for i,war in ipairs(Isaac.FindByType(EntityType.ENTITY_WAR, 0, -1, false, true)) do
						local warData = war:GetData()
						if warData.SandyParent and GetPtrHash(warData.SandyParent) == GetPtrHash(npc) and data.AttacksAfterWarSpawn >= 2 then
							currentWar = war
							if warData.IsHere then
								warIsHere = true
							end
							break
						end
					end
					if currentWar then
						data.WaitingForWar = true
						if warIsHere then
							data.WaitingForWar = false
							data.KillingWar = true
							initAttack = true
						end
					elseif data.BurrowTimer <= 0 then
						initAttack = true
					end
				elseif data.BurrowTimer <= 0 then
					initAttack = true
				end

				if initAttack then
					initSandyAttack(npc, data, sprite, target)
				end
			end
		elseif data.State == "Jump" then
			if sprite:IsEventTriggered("Dig Out") then
				killNearbyBabies(npc, data)
				spawnDirtChunk(npc, math.random(2,3))
			end
			if sprite:IsPlaying("Jump Land") or (sprite:IsPlaying("Jump" .. data.AttackExtra .. " Start") and not sprite:WasEventTriggered("Jump")) then
				npc.Velocity = Vector.Zero
			end
			if sprite:IsFinished("Jump" .. data.AttackExtra .. " Start") then
				sprite:Play("Jump" .. data.AttackExtra .. " InAir", true)
			end
			if sprite:IsEventTriggered("Jump") then
				data.ZVelocity = 8
				if data.IsRevived then
					data.ZVelocity = 6
				end
				if data.AttackExtra == " Side" then
					npc.Velocity = data.VelocityToOpposite
					local roomShape = REVEL.room:GetRoomShape()
					if roomShape == RoomShape.ROOMSHAPE_IH
					or roomShape == RoomShape.ROOMSHAPE_2x1
					or roomShape == RoomShape.ROOMSHAPE_IIH
					or roomShape == RoomShape.ROOMSHAPE_2x2 then
						data.Gravity = 0.4
						data.ZVelocity = math.ceil(data.ZVelocity * 1.2)
					end
				else
					npc.Velocity = (target.Position - npc.Position):Normalized()
				end
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			end

			if sprite:IsPlaying("Jump" .. data.AttackExtra .. " InAir 1") or sprite:IsPlaying("Jump" .. data.AttackExtra .. " InAir 2") or sprite:IsPlaying("Jump" .. data.AttackExtra .. " InAir") or (sprite:IsPlaying("Jump" .. data.AttackExtra .. " Start") and sprite:WasEventTriggered("Jump")) then
                if data.ZPosition > 20 then
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                elseif npc.EntityCollisionClass == EntityCollisionClass.ENTCOLL_NONE then
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                end

				data.ZVelocity = data.ZVelocity - data.Gravity
				data.ZPosition = data.ZPosition + data.ZVelocity
				local offset = 0
				if data.AttackExtra == " Side" then
					offset = 40
					npc.Velocity = data.VelocityToOpposite
				end
				if data.ZVelocity < 0 then
					if not sprite:IsPlaying("Jump" .. data.AttackExtra .. " InAir 2") then
						sprite:Play("Jump" .. data.AttackExtra .. " InAir 2")
					end
				else
					if not sprite:IsPlaying("Jump" .. data.AttackExtra .. " InAir 1") then
						sprite:Play("Jump" .. data.AttackExtra .. " InAir 1")
					end
				end
				if data.ZPosition <= 0 then
					data.ZVelocity = 0
					data.ZPosition = 0
					data.Gravity = 0.5
					npc.SpriteRotation = 0
					npc.SpriteOffset = Vector(0,0)

					npc.Velocity = Vector.Zero
					npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

					sprite:Play("Jump Land", true)
					data.State = "Squirm"
					killNearbyBabies(npc, data)

					if data.IsChampion and not data.AteWar then
						data.AttacksAfterWarSpawn = data.AttacksAfterWarSpawn + 1
					end
				else
					npc.SpriteOffset = Vector(0,-(data.ZPosition + offset))
				end
			end
		elseif data.State == "Dash" then
			if sprite:IsPlaying("Dash" .. data.AttackExtra .. " Start") and sprite:IsEventTriggered("Dash Start") then
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_ROAR_0, 1, 0, false, 1)
				data.SpawnDirtChunkCooldown = math.random(10,20)
				data.SpawnTrollBombCooldown = math.random(10,30)
				npc.Velocity = data.VelocityToOpposite
				data.DashStarted = true
			end
			if sprite:IsFinished("Dash" .. data.AttackExtra .. " Start") then
				sprite:Play("Dash" .. data.AttackExtra, true)
			end
			if data.DashStarted then
				if not sprite:IsPlaying("Dash" .. data.AttackExtra .. " End") and not sprite:IsFinished("Dash" .. data.AttackExtra .. " End") then
					npc.Velocity = data.VelocityToOpposite
					local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position + (npc.Velocity*10)))
					if grid and (grid.CollisionClass == GridCollisionClass.COLLISION_WALL or grid.CollisionClass == GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER) then
						sprite:Play("Dash" .. data.AttackExtra .. " End", true)
					end
				end
				data.SpawnDirtChunkCooldown = data.SpawnDirtChunkCooldown - 1
				if data.SpawnDirtChunkCooldown <= 0 then
					data.SpawnDirtChunkCooldown = math.random(10,20)
					spawnDirtChunk(npc, 1)
				end
				if data.IsChampion and data.AteWar then
					data.SpawnTrollBombCooldown = data.SpawnTrollBombCooldown - 1
					if data.SpawnTrollBombCooldown <= 0 then
						data.SpawnTrollBombCooldown = math.random(10,30)
						Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, npc.Position, (target.Position - npc.Position):Normalized() * 10, npc)
					end
				end
				if sprite:IsPlaying("Dash" .. data.AttackExtra .. " End") then
					npc.Velocity = npc.Velocity * 0.8
				end
				if sprite:IsFinished("Dash" .. data.AttackExtra .. " End") then
					npc.Velocity = Vector.Zero
					if data.IsChampion and not data.AteWar then
						data.AttacksAfterWarSpawn = data.AttacksAfterWarSpawn + 1
					end
					chooseSandyAttack(npc, data, sprite, target)
					data.ImmediateBurrow = true
					data.DashStarted = false
				end
			end
			killNearbyBabies(npc, data, npc.Position + npc.Velocity)
		elseif data.State == "Shriek" then
			if sprite:IsPlaying("Tired") then
				npc.Velocity = Vector.Zero
				if healthPercentage > 5 then
					data.TiredCountdown = data.TiredCountdown - 1
					if data.TiredCountdown <= 0 then
						chooseSandyAttack(npc, data, sprite, target)
						sprite:Play("Dig Down", true)
					end
				elseif Isaac.CountEntities(nil, REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1) <= 0 then
					data.SpawnBabyCountdown = data.SpawnBabyCountdown or 10
					data.SpawnBabyCountdown = data.SpawnBabyCountdown - 1
					if data.SpawnBabyCountdown <= 0 then
						data.SpawnBabyCountdown = math.random(30,60)

						local noJeffrey = false
						if data.bal.NoJeffreySpawns then
							noJeffrey = true
						end

						local baby = spawnSandyBaby(REVEL.room:GetClampedPosition(Isaac.GetRandomPosition(), 10), Vector.Zero, npc, noJeffrey)
						baby:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						baby:GetSprite():Play("GroundShake", true)
					end
				end
			elseif sprite:IsPlaying("Shriek") or sprite:IsPlaying("Shriek War Final") or sprite:IsPlaying("Shriek War") then
				npc.Velocity = Vector.Zero
				if sprite:IsEventTriggered("Shriek") then
					REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_HUSH_ROAR, 1, 0, false, 1)
                    local eggs = Isaac.FindByType(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1, false, false)
                    local angeredAmount = 6
                    if #eggs > 6 then
                        angeredAmount = 5
                    elseif #eggs <= 3 then
                        angeredAmount = 7
                    end

					for _, egg in ipairs(eggs) do
                        egg:GetData().Angered = angeredAmount
					end
				end
				if sprite:IsEventTriggered("Spit") then
					REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1, 0, false, 1)
				end
				if sprite:IsEventTriggered("War") then
					data.AteWar = false

					local spawnWarVelocity = RandomVector() * (math.random(-100,100)*0.01)
					if spawnWarVelocity.Y < 0.5 then
						spawnWarVelocity = Vector(spawnWarVelocity.X, math.max(spawnWarVelocity.Y, 0.5))
					end

					local spawnWithoutHorse = false
					if sprite:IsPlaying("Shriek War Final") then
						spawnWithoutHorse = true
					end

					data.AttacksAfterWarSpawn = 0

					local war = spitSandyWar(npc, npc.Position, spawnWarVelocity, "InAir", spawnWithoutHorse)
					REVEL.ZPos.SetData(war, {
						ZVelocity = 6,
						ZPosition = 120,
						Gravity = 0.12,
					})
					REVEL.ZPos.UpdateEntity(war)

					if spawnWithoutHorse then
						war:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
						war.HitPoints = war.HitPoints * 0.1
					end
				end
			elseif data.BurrowMovementTimer or data.SpawningDirtChunks then
				if data.BurrowMovementTimer and data.BurrowMovementTimer > 0 then
					data.BurrowMovementTimer = data.BurrowMovementTimer - 1
					if data.BurrowMovementTimer <= 0 then
						data.SpawningDirtChunks = true
						data.BurrowMovementTimer = nil
						npc.Visible = true
						sprite:Play("Burrowed Appear", true)
					end
				end

				if sprite:IsFinished("Burrowed Appear") then
					sprite:Play("Burrowed Movement")
				end

				local rotate = 100
				for i=1, 25 do
					local checkPos = npc.Position + (npc.Velocity*i)
					local checkPosClamped = REVEL.room:GetClampedPosition(checkPos, 40)
					if checkPos.X ~= checkPosClamped.X or checkPos.Y ~= checkPosClamped.Y then
						rotate = rotate - 1
					end
				end
				npc.Velocity = ((REVEL.room:GetCenterPos() - npc.Position) * 0.15):Rotated(rotate)

				if data.SpawningDirtChunks then
					data.SpawnDirtChunkCooldown = data.SpawnDirtChunkCooldown - 1
					if data.SpawnDirtChunkCooldown <= 0 then
						data.SpawnDirtChunkCooldown = 20
						if data.IsRevived then
							data.SpawnDirtChunkCooldown = 8
						end
                        REVEL.game:ShakeScreen(40)

						local noJeffrey = false
						if data.bal.NoJeffreySpawns then
							noJeffrey = true
						end
						spawnRandomEgg(noJeffrey, npc)
					end
					-- if math.random(1,5) == 1 then
						-- REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2)
						-- if math.random(1,3) == 1 then
							-- local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, RandomVector(), npc)
							-- rock:Update()
						-- end
					-- end

                    REVEL.game:ShakeScreen(2)
					data.ShriekCountdown = data.ShriekCountdown - 1
					if data.ShriekCountdown <= 0 then
						npc.Velocity = Vector.Zero
						npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
						if data.IsChampion and data.AteWar then
							if healthPercentage > 5 then
								sprite:Play("Shriek War", true)
							else
								sprite:Play("Shriek War Final", true)
							end
						else
							sprite:Play("Shriek", true)
						end
						data.SpawningDirtChunks = false
						-- for i=1, math.random(7,12) do
							-- REVEL.SpawnSandGibs(data.BurrowPos, RandomVector() * 2)
						-- end
						-- for i=1, math.random(2,5) do
							-- local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position, RandomVector(), npc)
							-- rock:Update()
						-- end
					end
				end
			else
				npc.Velocity = Vector.Zero
				if sprite:IsFinished("Dig Up") then
					sprite:Play("Growl", true)
				end
				if sprite:IsFinished("Growl") then
					npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					data.BurrowMovementTimer = 30
					npc.Visible = false
				end
				if sprite:IsFinished("Shriek") or sprite:IsFinished("Shriek War") or sprite:IsFinished("Shriek War Final") then
					sprite:Play("Tired", true)
					data.TiredCountdown = math.random(60,100)
					if healthPercentage <= 5 then
						data.didFinalSurfacing = true
					end
				end
			end
		elseif data.State == "Sinkhole" then
			npc.Velocity = Vector.Zero
			if sprite:IsPlaying("Suck Player Loop") then
				data.PlayerSuckFrames = data.PlayerSuckFrames + 1
				if data.PlayerSuckFrames > 200 then
					sprite:Play("Suck Player Spit", true)
				end
			elseif sprite:IsFinished("Suck Player") then
				sprite:Play("Suck Player Loop", true)
				data.PlayerSuckFrames = 0
			elseif not (sprite:IsPlaying("Suck Bomb Spit") or sprite:IsPlaying("Suck Bomb") or sprite:IsPlaying("Suck Player") or sprite:IsPlaying("Suck Player Loop") or sprite:IsPlaying("Suck Player Spit")) then
				local ragEnemyCount = (Isaac.CountEntities(nil, REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant, -1) or 0) + (Isaac.CountEntities(nil,REVEL.ENT.RAG_GAPER_HEAD.id, REVEL.ENT.RAG_GAPER_HEAD.variant, -1) or 0) + (Isaac.CountEntities(nil,REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant, -1) or 0)
				if data.Sinkhole then
					data.SinkholeTimer = data.SinkholeTimer - 1
					if data.SinkholeTimer <= 0 then

						local sandholeAttacks = {
                            SpitRocks = data.bal.SandholeAttackWeights.SpitRocks,
                            WarProjectiles = data.bal.SandholeAttackWeights.WarProjectiles,
                            WarBombs = data.bal.SandholeAttackWeights.WarBombs
                        }

						if data.DidWarSandholeSpit then
							data.DidWarSandholeSpit = false
							sandholeAttacks.WarProjectiles = 0
							sandholeAttacks.WarBombs = 0
						end

						local attack = REVEL.WeightedRandom(sandholeAttacks)
						if attack == nil then
							attack = "SpitRocks"
						end

						data.SinkholeTimer = math.random(50, 80)
						if attack == "SpitRocks" then
							sprite:Play("Suck Spit", true)
						elseif attack == "WarProjectiles" and data.AteWar then
							sprite:Play("Suck War Spit", true)
							data.Spits = 0
							data.DidWarSandholeSpit = true
							data.SandholeWarAttack = 1
						elseif attack == "WarBombs" and data.AteWar then
							sprite:Play("Suck War Spit", true)
							data.Spits = 0
							data.DidWarSandholeSpit = true
							data.SandholeWarAttack = 2
						end
						data.Spits = data.Spits + 1
					end

                    npc.Velocity = (target.Position - npc.Position):Resized(1)

					if not data.IsChampion and data.ActivatedCoffins then
						if ragEnemyCount > 0 then
							data.ActivatingCoffins = false
						end
						if ragEnemyCount <= 0 and not data.ActivatingCoffins then
							data.Spits = -2
							data.ActivatedCoffins = false
						end
					end
				end
				if sprite:IsPlaying("Suck War Spit") then
					if sprite:IsEventTriggered("Spit") then
						REVEL.sfx:NpcPlay(npc, REVEL.SFX.FLASH_BOSS_GURGLE, 1, 0, false, 1)
					end
					if sprite:IsEventTriggered("War") then
						data.AteWar = false
						local attackAnimation = data.SandholeWarAttack or math.random(1,2)
						local war = spitSandyWar(npc, npc.Position, Vector.Zero, "InAir Attack" .. attackAnimation)
						REVEL.ZPos.SetData(war, {DisableAI = false})
						data.SandholeWarAttack = nil
					end
				end
				if sprite:IsPlaying("Suck Spit") and sprite:IsEventTriggered("Spit") then
					local hitCoffins = false
					REVEL.sfx:NpcPlay(npc, REVEL.SFX.FLASH_BOSS_GURGLE, 1, 0, false, 1)
					if data.Spits >= 2 and not data.ActivatedCoffins and data.bal.SandholeRocksCanHitCoffins then
						hitCoffins = true
						data.Spits = 0
					end
					spawnDirtChunk(npc, math.random(2,3), 8, true, hitCoffins)
				end
			end
			if not data.Sinkhole and not sprite:IsPlaying("Suck Start") then
				sprite:Play("Suck", true)
				data.Sinkhole = StageAPI.SpawnFloorEffect(npc.Position, Vector.Zero, nil, "gfx/grid/revel2/traps/trap_sandhole.anm2", true, REVEL.ENT.SAND_HOLE.variant):ToEffect()
				local sinkholeData = data.Sinkhole:GetData()
				sinkholeData.Sandy = npc
				sinkholeData.KillEnemies = true
				sinkholeData.IncreaseEnemyPullForce = true
				sinkholeData.RemoveOnNoSandy = true
				data.Sinkhole:FollowParent(npc)
				data.SinkholeTimer = math.random(30, 50)
				for _, egg in ipairs(Isaac.FindByType(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1, false, false)) do
					REVEL.BreakEgg(egg)
				end
			end

            if data.SinkholeSpewing then
                data.SinkholeSpewing = data.SinkholeSpewing - 1
                for i = 1, 2 do
                    local variant = ProjectileVariant.PROJECTILE_NORMAL
                    if data.EatenBoniesOnly or math.random(1, 3) == 1 then
                        variant = ProjectileVariant.PROJECTILE_BONE
                    end

                    local p = REVEL.SpawnNPCProjectile(npc, RandomVector() * math.random(3, 5), nil, variant)
                    p.Height = math.random(30, 45) * -1
                    p.FallingSpeed = math.random(10, 20) * -1
                    p.FallingAccel = 1
                    p.Scale = ( 1 + ( math.random(0, 6) / 10 ) )
                end

                if data.SinkholeSpewing <= 0 then
                    data.SinkholeSpewing = nil
                    data.EatenBoniesOnly = nil
                end
            end

			if sprite:IsPlaying("Suck Bomb") and sprite:IsEventTriggered("Explode") then
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS1_EXPLOSIONS, 0.75, 0, false, 1)
				npc:TakeDamage(20, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 5)
			end
			if sprite:IsPlaying("Suck Bomb Spit") and sprite:IsEventTriggered("Spit") then
				Isaac.Spawn(EntityType.ENTITY_BOMBDROP, data.AteBombVariant or BombSubType.BOMB_NORMAL, 0, npc.Position, (target.Position - npc.Position):Normalized() * 10, npc)
			end
			if sprite:IsFinished("Suck War Spit") then
				sprite:Play("Suck War Spit Idle", true)
			end
			if sprite:IsFinished("Suck Chomp")
			or sprite:IsFinished("Suck Spit")
			or sprite:IsFinished("Suck Bomb Spit")
			or sprite:IsFinished("Suck Bomb")
			or sprite:IsFinished("Suck Player Spit")
			or sprite:IsFinished("Suck War Spit End") then
				sprite:Play("Suck", true)
			end
			-- if data.Spits >= 5 then
			if healthPercentage <= 5 and (not data.IsChampion or (data.IsChampion and data.AteWar)) then
				sprite:Play("Suck End", true)
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				chooseSandyAttack(npc, data, sprite, target)
				data.Spits = 0
			end
		elseif data.State == "Death" then
			if data.IsRevived and data.DeathTriggerFrame 
			and npc.FrameCount - data.DeathTriggerFrame > data.bal.DeathFallbackFramesSinceDeath then
				REVEL.DebugStringMinor(("Sandy died after waiting %d seconds with fallback")
					:format(math.floor(data.bal.DeathFallbackFramesSinceDeath / 30)))
				npc:Die()
				return
			end

			npc.Velocity = Vector.Zero
			if sprite:IsEventTriggered("Explode") then
				npc:BloodExplode()
				local bloodExplosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 3, npc.Position, Vector.Zero, npc)
				bloodExplosion.RenderZOffset = npc.RenderZOffset + 100
				bloodExplosion.SpriteOffset = Vector(0,-30)
			end
			if sprite:IsFinished("Death Start") then
				if data.IsRevived or not data.bal.Revive or revel.data.run.jeffreyDefeated then
					npc:Kill()
				else
					data.SpawnJeffreyTimer = data.SpawnJeffreyTimer - 1
					if data.SpawnJeffreyTimer <= 0 and (Isaac.CountEntities(nil, REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, -1) or 0) <= 0 then
						local jeffrey = Isaac.Spawn(REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, 0, REVEL.room:GetClampedPosition(Isaac.GetRandomPosition(), 20), Vector.Zero, npc)
						jeffrey:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						jeffrey:GetSprite():Play("Emerge", true)
					end

					if data.doRevival then
						data.IsRevived = true
						data.didFinalSurfacing = false

						sprite:Play("Death Revive", true)
						npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

						data.bal = REVEL.GetBossBalance(sandyBalance, "Jeffrey")

						for layer=0, 2 do
							sprite:ReplaceSpritesheet(layer, data.bal.Spritesheet)
						end
						sprite:LoadGraphics()

                        if data.bal.JeffreyPercentFightTime then
                            npc.MaxHitPoints = data.OriginalMaxHitPoints * data.bal.JeffreyPercentFightTime
                        end

						data.RemainingRevivalHealth = (npc.MaxHitPoints * 0.5) * math.max(0.5,(revel.data.run.jeffreyHealthPercentage*0.01))

						data.IdleTimer = 20
						data.State = "Idle"
					end
				end
			end
		end

		if data.Sinkhole and data.State ~= "Sinkhole" then
			data.Sinkhole:GetSprite():Play("Disappear")
			data.Sinkhole = nil
		end

		if data.IsRevived and data.RemainingRevivalHealth and data.RemainingRevivalHealth > 0 then
			npc.HitPoints = npc.HitPoints + math.min(10, data.RemainingRevivalHealth)
			data.RemainingRevivalHealth = data.RemainingRevivalHealth - 10
			if data.RemainingRevivalHealth <= 0 then
				data.RemainingRevivalHealth = nil
			end
		end

		if sprite:IsEventTriggered("Dig In") then
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1, 0, false, 1)
		end

		if sprite:IsEventTriggered("Dig Out") then
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_BURST_OUT, 1, 0, false, 1)
		end

		if sprite:IsEventTriggered("Growl") then
			local volume = 1
			if data.State == "Ass" then
				volume = 0.4
			end
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_ROAR_0, volume, 0, false, 1)
		end

		if sprite:IsEventTriggered("Head Emerge") then
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATHEADSHOOT, 0.6, 0, false, 1)
		end

		if data.State ~= "Sinkhole" then
			for _, player in ipairs(REVEL.players) do
				local playerData, playerSprite = player:GetData(), player:GetSprite()
				if playerData.SandHoleSucced then
					player.Visible = true
					playerData.SandHoleSucced = false
				end
			end
		end
	end
end

local function sandyRoom_PostBossRoomInit(newRoom, boss)
	if boss.Name == "Sandy" or boss.NameTwo == "Sandy" then
		if not revel.data.sandySeenWarIntro then
			StageAPI.GetBossData("Sandy").Portrait = "gfx/ui/boss/revel2/war_portrait.png"
			StageAPI.GetBossData("Sandy").Bossname = "gfx/ui/boss/revel2/war_name.png"
		end
	end
end

local function sandy_Sandy_EntityTakeDmg(_, ent, amount, flags, source, cooldown)
	if ent.Variant == REVEL.ENT.SANDY.variant then
		local data, sprite = ent:GetData(), ent:GetSprite()

		if data.IsChampion and HasBit(flags, DamageFlag.DAMAGE_EXPLOSION) 
		and source.Type == EntityType.ENTITY_BOMBDROP 
		and source.Variant == BombVariant.BOMB_TROLL then
			ent.HitPoints = ent.HitPoints + (amount * 0.9)
		end

		local damageMod = 1
		if data.bal and data.bal.DamageModifier then
			damageMod = data.bal.DamageModifier
		end

		-- REVEL.DebugStringMinor(("sandy damage | hp %.2f damage %.2f buffer %f")
		-- 	:format(ent.HitPoints, amount, REVEL.GetDamageBuffer(ent)))
		if data.State == "Death" or (sprite:IsPlaying("Death Revive") and ent.HitPoints < ent.MaxHitPoints*0.4) then
			REVEL.DamageFlash(ent)
			return false
		elseif sprite:IsPlaying("Death Revive") then
			damageMod = 0.2
		elseif ent.HitPoints - REVEL.GetDamageBuffer(ent) - amount <= 0 then -- before mortal damage triggers, ideally
			ent.HitPoints = REVEL.GetDamageBuffer(ent) + 1

			if data.didFinalSurfacing or sprite:IsPlaying("Tired") then
				ent.SpriteRotation = 0
				ent.SpriteOffset = Vector(0,0)
				ent.Velocity = Vector.Zero
				data.State = "Death"
				data.DeathTriggerFrame = ent.FrameCount
				sprite:Play("Death Start", true)
				ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				data.SpawnJeffreyTimer = 40
				if data.IsRevived then
					local eggs = Isaac.FindByType(REVEL.ENT.ANTLION_EGG.id, REVEL.ENT.ANTLION_EGG.variant, -1, false, false)
					local angeredAmount = 6
					if #eggs > 6 then
						angeredAmount = 5
					elseif #eggs <= 3 then
						angeredAmount = 7
					end

					for _, egg in ipairs(eggs) do
						egg:GetData().Angered = angeredAmount
					end
				end
			end

			ent:RemoveStatusEffects()

			-- REVEL.DebugStringMinor(("Deadly damage: %f minus %f + %f"):format(ent.HitPoints, amount, REVEL.GetDamageBuffer(ent)))
			REVEL.DamageFlash(ent)
			return false
		elseif not data.StartedFight then
			damageMod = 0.2
			data.StartFightCounter = data.StartFightCounter - math.max(1, math.floor(amount / ent.MaxHitPoints * 50)) --counter decreases by 1 every 2 percent
		elseif data.IsRevived then
			if data.RemainingRevivalHealth and data.RemainingRevivalHealth > 0 and amount >= ent.HitPoints then
				REVEL.DamageFlash(ent)
				return false
			end
		end

		local originalAmount = amount
		if damageMod ~= 1 then
			amount = amount * damageMod
		end

		if damageMod > 1 then
			ent.HitPoints = ent.HitPoints - (amount - originalAmount)
		elseif damageMod < 1 then
			ent.HitPoints = ent.HitPoints + (originalAmount - amount)
		end
	end
end


local function sandy_Sandy_PostEntityKill(_, ent)
	if ent.Variant == REVEL.ENT.SANDY.variant and ent:GetData().IsRevived then
		revel.data.run.jeffreyDefeated = true
	end
end


local function sandy_PostProjectileUpdate(_, proj)
    local data, sprite = proj:GetData(), proj:GetSprite()
    if data.ChangeToDirtChunk then
        data.DirtChunk = true
        data.ChangeToDirtChunk = nil
		if math.random(1,2) == 1 then
			data.AirRotation = data.AirRotation or 5
		else
			data.AirRotation = data.AirRotation or -5
		end
		proj.SpriteRotation = math.random(-180,180)
    end
end

local function sandy_PostProjectileRender(_, proj)
	if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal() then
		local data = proj:GetData()
		if data.DirtChunk and data.AirRotation then
			proj.SpriteRotation = proj.SpriteRotation + data.AirRotation
		end
	end
end

local sandyCoffinEnemies = {
    {
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant}
    },
    {
        {REVEL.ENT.RAG_GAPER.id, REVEL.ENT.RAG_GAPER.variant},
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant}
    },
    {
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant},
        {REVEL.ENT.RAG_BONY.id, REVEL.ENT.RAG_BONY.variant},
    }
}

local function sandy_Proj_PostEntityRemove(_, ent)
    local data = ent:GetData()
    if data.SpawnAntlionBaby and REVEL.room:IsPositionInRoom(ent.Position, -24) then
		--if (Isaac.CountEntities(nil, REVEL.ENT.ANTLION_BABY.id, REVEL.ENT.ANTLION_BABY.variant, -1) or 0) < 4 then
			local baby = spawnSandyBaby(REVEL.room:GetClampedPosition(ent.Position, 10), Vector.Zero, ent, data.NoJeffreySpawn)
			baby:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			baby:GetSprite():Play("GroundShake", true)
		--end
    end
	if data.CoffinToActivate then
		local cdata = data.CoffinToActivate:GetData()
		cdata.SpawnEnemies = {}
        local enemies =  sandyCoffinEnemies[math.random(1,#sandyCoffinEnemies)]
        for _, enemy in ipairs(enemies) do
            cdata.SpawnEnemies[#cdata.SpawnEnemies + 1] = enemy
        end

		cdata.Triggered = true
	end
end

local function sandy_Sandy_PostEntityRemove(_, ent)
	if REVEL.ENT.SANDY:isEnt(ent) then
		local data = ent:GetData()
		if data.Sinkhole then
			data.Sinkhole:Remove()
		end
	end
end

local function sandy_PostProjPoofInit(poof, data, sprite, spawner, grandpa)
	if spawner.Variant == ProjectileVariant.PROJECTILE_NORMAL and spawner:GetData().DirtChunk then
		-- REVEL.sfx:Play(SoundEffect.SOUND_SMB_LARGE_CHEWS_4, 0.75, 0, false, 1)
		-- sprite:ReplaceSpritesheet(0, "gfx/effects/revel2/sand_projectile_poof.png")
		-- sprite:LoadGraphics()
		poof:Remove()
	end
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_BOSS_MUSIC, 1, sandyRoom_PostSelectBossMusic)
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, sandy_PreEntitySpawn)
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, sandy_Sandy_NpcUpdate, REVEL.ENT.SANDY.id)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_BOSS_ROOM_INIT, 1, sandyRoom_PostBossRoomInit)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, sandy_Sandy_EntityTakeDmg, REVEL.ENT.SANDY.id)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, sandy_Sandy_PostEntityKill, REVEL.ENT.SANDY.id)
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, sandy_PostProjectileUpdate)
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, sandy_PostProjectileRender)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, sandy_Proj_PostEntityRemove, EntityType.ENTITY_PROJECTILE)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, sandy_Sandy_PostEntityRemove, REVEL.ENT.SANDY.id)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, sandy_PostProjPoofInit)

end

-----------
--JEFFREY--
-----------
do

local spriteFrameToJeffreyHeight = {
    [0] = -1,
    [1] = -1,
    [2] = -2,
    [3] = -4,
    [4] = -4,
    [5] = -4,
    [6] = -4,
    [7] = -4,
    [8] = -2,
    [9] = -1,
    [10] = 0,
    [11] = 1,
    [12] = 2,
    [13] = 4
}

--[[
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subType, position, velocity, spawner, seed)
	if type == REVEL.ENT.JEFFREY_BABY.id and variant == REVEL.ENT.JEFFREY_BABY.variant and (Isaac.CountEntities(nil, REVEL.ENT.JEFFREY_BABY.id, REVEL.ENT.JEFFREY_BABY.variant, -1) or 0) > 0 then
		return {
			REVEL.ENT.ANTLION_BABY.id,
			REVEL.ENT.ANTLION_BABY.variant,
			subType,
			seed
		}
	end
end)
]]

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant == REVEL.ENT.JEFFREY_BABY.variant then
		local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

		if not data.Init then
			npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
            REVEL.SetScaledBossHP(npc, nil, nil, nil, nil, nil, true)
            npc.HitPoints = npc.MaxHitPoints * (revel.data.run.jeffreyHealthPercentage*0.01)
			revel.data.run.jeffreySeen = true
			data.BurrowCounter = 0
			data.IsRunningAway = false
			npc.SpriteOffset = Vector(0,-14)
			if not npc:HasEntityFlags(EntityFlag.FLAG_APPEAR) and not sprite:IsPlaying("Appear") and not sprite:IsPlaying("Emerge") and not sprite:IsPlaying("GroundShake") then
				sprite:Play("Walk", true)
			end
			if sprite:IsPlaying("GroundShake") then
				data.GroundShakeTimer = data.GroundShakeTimer or 20
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end
			data.Init = true
		end

    	REVEL.ApplyKnockbackImmunity(npc)

		if sprite:IsFinished("Appear") or sprite:IsFinished("Emerge") then
			sprite:Play("Walk", true)
		end

		if sprite:IsPlaying("GroundShake") then
			data.GroundShakeTimer = data.GroundShakeTimer - 1
			if data.GroundShakeTimer <= 0 then
				sprite:Play("Emerge", true)
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end
		elseif sprite:IsPlaying("Walk") then
			local sandy = nil
			local velocityToSet = target.Position - npc.Position
			local frictionToSet = 0.95
			local speedToSet = 0.35
			if data.IsRunningAway then
				velocityToSet = npc.Position - target.Position
			end
			for i,entity in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, false)) do
				local entityData = entity:GetData()
				if entityData.State == "Death" then
					sandy = entity
					velocityToSet = sandy.Position - npc.Position
					frictionToSet = 0.45
					speedToSet = 1.5
					break
				end
			end

			npc.Velocity = (npc.Velocity * frictionToSet) + (velocityToSet):Resized(speedToSet)

			if sandy then
				if npc.CollisionDamage < 1 then
					npc.CollisionDamage = 1
				end
				if not npc:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK) then
					npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				end
				if sandy.Position:Distance(npc.Position) <= 20 then
					data.SandyToRevive = sandy
					sprite:Play("StartRevive", true)
					npc.RenderZOffset = sandy.RenderZOffset + 100
					npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				elseif sandy.Position:Distance(npc.Position) <= 50 then
					npc.SpriteOffset = Vector(0,npc.SpriteOffset.Y-2)
				elseif sandy.Position:Distance(npc.Position) <= 150 then
					npc.SpriteOffset = Vector(0,npc.SpriteOffset.Y-1)
				end
			elseif data.IsRunningAway then
				if npc.CollisionDamage > 0 then
					npc.CollisionDamage = 0
				end
				if npc.FrameCount % 10 == 5 and math.random(1,3) == 1 then
					data.BurrowCounter = data.BurrowCounter + 1
				end
				if data.BurrowCounter >= 4 and not (sprite:IsPlaying("Burrow") or sprite:IsFinished("Burrow")) then
					sprite:Play("Burrow", true)
				end
			else
				if npc.CollisionDamage < 1 then
					npc.CollisionDamage = 1
				end
			end
		elseif sprite:IsPlaying("StartRevive") then
			REVEL.LerpEntityPosition(npc, npc.Position, data.SandyToRevive.Position, 10)
			npc.SpriteOffset = Vector(0,npc.SpriteOffset.Y + (spriteFrameToJeffreyHeight[sprite:GetFrame()] or 0))
		elseif sprite:IsPlaying("FlyDownLoop") then
			npc.Velocity = Vector.Zero
			npc.SpriteOffset = Vector(0,npc.SpriteOffset.Y+6)
			if npc.SpriteOffset.Y >= -40 then
				local sandyData, sandySprite = data.SandyToRevive:GetData(), data.SandyToRevive:GetSprite()
				if sandySprite:IsPlaying("Death Revive") then
					if sandySprite:WasEventTriggered("Baby Enter") then
						REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.6, 0, false, 1)
						REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 0.7, 0, false, 1)
						npc:Remove()
						return
					end
				else
					sandyData.doRevival = true
				end
			end
			if npc.SpriteOffset.Y >= 0 then
				sprite:Play("Burrow")
			end
		else
			npc.Velocity = Vector.Zero
		end

		if sprite:IsFinished("Burrow") then
			npc:Remove()
		end

		if sprite:IsFinished("StartRevive") then
			sprite:Play("FlyDownLoop", true)
		end

		revel.data.run.jeffreyHealthPercentage = math.ceil((npc.HitPoints / npc.MaxHitPoints)*100)
	end
end, REVEL.ENT.JEFFREY_BABY.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
	if ent.Variant == REVEL.ENT.JEFFREY_BABY.variant then
		local data = ent:GetData()
		if data.BurrowCounter then
			data.IsRunningAway = true

			data.BurrowCounter = data.BurrowCounter + 1
			if (amount / ent.MaxHitPoints) >= ent.MaxHitPoints * 0.05 then --taken more than 5% damage
				data.BurrowCounter = data.BurrowCounter + 1
			end
		end
	end
end, REVEL.ENT.JEFFREY_BABY.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
	if entity.Variant == REVEL.ENT.JEFFREY_BABY.variant then
		revel.data.run.jeffreyDefeated = true
	end
end, REVEL.ENT.JEFFREY_BABY.id)

end

-------------
--SAND HOLE--
-------------
do

local function sandyCanBeUsed(sandy, ignoreAnimations)
	if sandy and sandy:Exists() then
		local data, sprite = sandy:GetData(), sandy:GetSprite()
		if data.State == "Sinkhole"
		and (ignoreAnimations or not (
				sprite:IsPlaying("Suck Bomb Spit")
				or sprite:IsPlaying("Suck Bomb")
				or sprite:IsPlaying("Suck Player")
				or sprite:IsPlaying("Suck Player Loop")
				or sprite:IsPlaying("Suck Player Spit")
				or sprite:IsPlaying("Suck War Spit")
				or sprite:IsPlaying("Suck War Spit Idle")
				or sprite:IsPlaying("Suck War Spit End"))) then
			return true
		end
	end
	return false
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, eff)
	local sprite, data = eff:GetSprite(), eff:GetData()
	if not data.Init then
		eff.SpriteScale = Vector(0,0)
		sprite:Play("Appear")
		data.Init = true
	end
end, REVEL.ENT.SAND_HOLE.variant)

--[[
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and #Isaac.FindByType(REVEL.ENT.SAND_HOLE.id, REVEL.ENT.SAND_HOLE.variant, -1, false, false) == 0 then
        local hole = StageAPI.SpawnFloorEffect(Input.GetMousePosition(true), Vector.Zero, nil, "gfx/grid/revel2/traps/trap_sandhole.anm2", true, REVEL.ENT.SAND_HOLE.variant) --Isaac.Spawn(REVEL.ENT.SAND_HOLE.id, REVEL.ENT.SAND_HOLE.variant, 0, Input.GetMousePosition(true), Vector.Zero, nil)
        hole:GetData().MouseHole = true
    end
end)]]

local function clampVectorValues(v, clamp)
    if math.abs(v.X) > clamp then
        if v.X > 0 then
            v = Vector(clamp, v.Y)
        else
            v = Vector(-clamp, v.Y)
        end
    end

    if math.abs(v.Y) > clamp then
        if v.Y > 0 then
            v = Vector(v.X, clamp)
        else
            v = Vector(v.X, -clamp)
        end
    end

    return v
end

local sandHoleOverallScale = 1.4
local layerOneColor = Color.Default
local finalLayerColor = Color(0.7, 0.7, 0.7, 1,conv255ToFloat( 0, 0, 0))
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff, renderOffset)
    local sprite, data = eff:GetSprite(), eff:GetData()
	local isRenderPassNormal = REVEL.IsRenderPassNormal()
    if data.Layers then
        for i, pos in ipairs(data.Layers) do
            if i ~= #data.Layers - 1 then
				if isRenderPassNormal then
					local scale = ((#data.Layers - i) / #data.Layers)
					sprite.Scale = Vector.One * scale * sandHoleOverallScale
					local colorScale = scale
					sprite.Color = Color.Lerp(finalLayerColor, layerOneColor, colorScale)
				end

                local worldToScreen = Isaac.WorldToScreen(pos)
                sprite:Render(worldToScreen + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
    end
end, REVEL.ENT.SAND_HOLE.variant)

local sandHoleEffectBlacklist = {
    [EffectVariant.CREEP_RED] = true,
    [EffectVariant.CREEP_GREEN] = true,
    [EffectVariant.CREEP_YELLOW] = true,
    [EffectVariant.CREEP_WHITE] = true,
    [EffectVariant.CREEP_BLACK] = true,
    [EffectVariant.PLAYER_CREEP_LEMON_MISHAP] = true,
    [EffectVariant.PLAYER_CREEP_HOLYWATER] = true,
    [EffectVariant.PLAYER_CREEP_WHITE] = true,
    [EffectVariant.PLAYER_CREEP_BLACK] = true,
    [EffectVariant.PLAYER_CREEP_RED] = true,
    [EffectVariant.PLAYER_CREEP_GREEN] = true,
    [EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL] = true,
    [EffectVariant.CREEP_BROWN] = true,
    [EffectVariant.PLAYER_CREEP_LEMON_PARTY] = true,
    [EffectVariant.PLAYER_CREEP_PUDDLE_MILK] = true,
    [EffectVariant.CREEP_SLIPPERY_BROWN] = true,
    [REVEL.ENT.ICE_CREEP.variant] = true,
    [REVEL.ENT.REVIVAL_RAG.variant] = true
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	local sprite, data = eff:GetSprite(), eff:GetData()
	if not data.Init then
		--eff.RenderZOffset = -11000
		eff.SpriteScale = Vector(0,0)
		sprite:Play("Appear")
		data.Init = true
	end

    if not data.Layers then
        data.Layers = {}
        for i = 1, 7 do
            data.Layers[i] = eff.Position
        end
    end

    for i, pos in ipairs(data.Layers) do
        local scale = (#data.Layers - i) / #data.Layers
        if i == #data.Layers then
            data.Layers[i] = eff.Position
        else
            data.Layers[i] = REVEL.Lerp(pos, data.Layers[i + 1], 0.1)
        end
    end

    if data.MouseHole then
        local mousePos = Input.GetMousePosition(true)
        eff.Position = REVEL.Lerp(eff.Position, mousePos, 0.1)
    end

	if sprite:IsPlaying("Idle") and not data.MouseHole then
        local sandHoleSize = 165 * sandHoleOverallScale
        local sandHoleSizeSquared = sandHoleSize ^ 2
		for _, ent in ipairs(REVEL.roomEntities) do
			if (ent.Type == EntityType.ENTITY_PLAYER or ent:IsActiveEnemy(false) or ent.Type == EntityType.ENTITY_BOMBDROP) and ent.Type ~= REVEL.ENT.SANDY.id and ent:Exists() and not ent:IsFlying() then
                local entData, entSprite = ent:GetData(), ent:GetSprite()

                if data.IncreaseEnemyPullForce then
                    entData.LifetimeSinceSandhole = entData.LifetimeSinceSandhole or 0
                    entData.LifetimeSinceSandhole = entData.LifetimeSinceSandhole + 1
                end

				if ent.Type == EntityType.ENTITY_PLAYER then
					if entData.SandHoleSucced then
						if entSprite:IsFinished("FallIn") then
							ent.Visible = false
						end
						if entSprite:IsPlaying("JumpOut") then
							local frame = entSprite:GetFrame()
							if frame == 1 then
								ent.Visible = true
								if sandyCanBeUsed(data.Sandy, true) then
									data.Sandy:GetSprite():Play("Suck Player Spit")
								end
							elseif frame == 2 then
								local toPos = entData.SandHoleLastSafePos or Isaac.GetRandomPosition()
								ent.Velocity = (toPos - ent.Position) * 0.15
							elseif frame == 14 then
								entData.SandHoleSucced = false
							end
						end
					end
				end

				if not entData.SandHoleSucced then
                    local distance = ent.Position:DistanceSquared(data.Layers[1])

					if (ent.Type == REVEL.ENT.JEFFREY_BABY.id or ent.Type == REVEL.ENT.ANTLION_BABY.id) and sandyCanBeUsed(data.Sandy) and data.Sandy.Position:Distance(ent.Position) <= 115 then
						if not (entSprite:IsPlaying("Burrow") or entSprite:IsFinished("Burrow")) then
							entSprite:Play("Burrow", true)
						end
					else
						if ent.Type == EntityType.ENTITY_PLAYER and distance >= sandHoleSizeSquared then
							entData.SandHoleLastSafePos = ent.Position
						end

						local pullForce = 0.1
						if ent.Type == EntityType.ENTITY_PLAYER and not (distance >= sandHoleSizeSquared) then
							local distanceSqrt = math.sqrt(distance)
							if distanceSqrt <= sandHoleSize * 0.8 then
								pullForce = 0.1
							else
								pullForce = REVEL.Lerp(0.1, 10, ((sandHoleSize - distanceSqrt) / (sandHoleSize - distanceSqrt * 0.8)) ^ 3)
							end
						else
							pullForce = 0.1
						end

						if sandyCanBeUsed(data.Sandy) and (ent.Type == EntityType.ENTITY_PLAYER or (data.KillEnemies and ent:IsActiveEnemy(false)) or ent.Type == EntityType.ENTITY_BOMBDROP) then
							if ent.Position:DistanceSquared(eff.Position) <= (data.Sandy.Size + ent.Size + 5) ^ 2 then
								if not entData.SandHoleLastCollisionClass then
									entData.SandHoleLastCollisionClass = ent.EntityCollisionClass
								end
								if ent.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
									ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
								end
								pullForce = pullForce * 3
							elseif entData.SandHoleLastCollisionClass and entData.SandHoleLastCollisionClass ~= ent.EntityCollisionClass then
								ent.EntityCollisionClass = entData.SandHoleLastCollisionClass
								entData.SandHoleLastCollisionClass = nil
							end
						end

						if ent.Position:DistanceSquared(eff.Position) < (data.Sandy.Size * 0.5 + ent.Size) ^ 2 then
							if ent.Type == EntityType.ENTITY_PLAYER then
								entData.SandHoleSucced = true
								ent.Velocity = Vector.Zero
								ent:ToPlayer():AnimatePitfallIn()
								if sandyCanBeUsed(data.Sandy) then
									data.Sandy:GetSprite():Play("Suck Player")
								end
							elseif ent:IsActiveEnemy(false) and not (ent.Type == REVEL.ENT.JEFFREY_BABY.id or ent.Type == REVEL.ENT.ANTLION_BABY.id) then
								local sandyData = data.Sandy:GetData()
								sandyData.SinkholeSpewing = (sandyData.SinkholeSpewing or 0) + math.random(5, 8)
								local isBony = ent.Type == REVEL.ENT.RAG_BONY.id and ent.Variant == REVEL.ENT.RAG_BONY.variant
								if sandyData.EatenBoniesOnly == nil then
									sandyData.EatenBoniesOnly = isBony
								elseif sandyData.EatenBoniesOnly and not isBony then
									sandyData.EatenBoniesOnly = false
								end

								if not isBony then
									Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, eff.Position, Vector.Zero, data.Sandy)
								end

								ent:BloodExplode()

								if data.KillEnemies then
									if sandyCanBeUsed(data.Sandy) then
										data.Sandy:GetSprite():Play("Suck Chomp")
									end
									REVEL.sfx:Play(REVEL.SFX.CRONCH, 1, 0, false, 1)
									ent:Kill()
								else
									ent:TakeDamage(2, 0, EntityRef(eff), 5)
								end
							elseif ent.Type == EntityType.ENTITY_BOMBDROP and ent.FrameCount >= 2 then
								if sandyCanBeUsed(data.Sandy) then
									local sandyData = data.Sandy:GetData()
									sandyData.AteBombVariant = ent.Variant
									if not sandyData.SwallowedBomb or ent.Variant == BombVariant.BOMB_TROLL or REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
										data.Sandy:GetSprite():Play("Suck Bomb")
										sandyData.SwallowedBomb = true
									else
										data.Sandy:GetSprite():Play("Suck Bomb Spit")
									end
								end
								ent:Remove()
							end
						else
							if data.IncreaseEnemyPullForce and ent:IsActiveEnemy(false) and entData.LifetimeSinceSandhole and not (ent.Type == REVEL.ENT.JEFFREY_BABY.id or ent.Type == REVEL.ENT.ANTLION_BABY.id) then
								pullForce = pullForce * (1 + (math.min(entData.LifetimeSinceSandhole, 150)*0.02))
							end

							pullForce = math.max(pullForce, pullForce * ent.Velocity:Length() / 2)
							ent.Velocity = ent.Velocity + ((eff.Position - ent.Position):Normalized() * pullForce)
						end
					end
				end
			elseif ent.Type == EntityType.ENTITY_EFFECT and sandHoleEffectBlacklist[ent.Variant] then
                local distance = ent.Position:DistanceSquared(eff.Position)
                if distance <= sandHoleSize ^ 2 then
					ent:Remove()
				end
			end
		end
	end

	if sprite:IsFinished("Appear") then
		sprite:Play("Idle", true)
	end

	if sprite:IsFinished("Disappear") then
		eff:Remove()
	end

	if data.RemoveOnNoSandy and (not data.Sandy or (data.Sandy and (not data.Sandy:Exists() or data.Sandy:IsDead()))) then
		sprite:Play("Disappear", true)
	end
end, REVEL.ENT.SAND_HOLE.variant)

end

-------
--WAR--
-------
do

local function spawnRandomBombAroundPosition(pos, minDist, maxDist, velocity, parent)
	pos = pos or REVEL.room:GetCenterPos()
	minDist = minDist or 10
	maxDist = maxDist or 1000

	local vec = RandomVector()

	local testMaxDist = 10
	for i=1,100 do
		if testMaxDist > maxDist then
			break
		end

		local gridCol = REVEL.room:GetGridCollisionAtPos(pos + (vec * testMaxDist))
		if gridCol == GridCollisionClass.COLLISION_WALL or gridCol == GridCollisionClass.COLLISION_WALL then
			maxDist = math.min((testMaxDist-10), maxDist)
			break
		end

		testMaxDist = testMaxDist + 10
	end

	local dist = math.random(minDist, maxDist)

	return Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, REVEL.room:FindFreePickupSpawnPosition(pos+(vec*dist), 0, true), velocity or Vector.Zero, parent):ToBomb()
end

revel:AddCallback(RevCallbacks.PRE_ENTITY_ZPOS_UPDATE, function(_, ent, airMovementData)
	local data, sprite = ent:GetData(), ent:GetSprite()
	if ent.Variant ~= 10 and data.SandyParent then
		if sprite:IsPlaying("InAir Cry") or sprite:IsPlaying("InAir Attack1") or sprite:IsPlaying("InAir Attack2") then
			if airMovementData.ZVelocity < 0 and airMovementData.ZPosition <= 50 then
				for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, true)) do
					if GetPtrHash(data.SandyParent) == GetPtrHash(sandy) then
						local sandyData, sandySprite = sandy:GetData(), sandy:GetSprite()
						sandyData.AteWar = true
						if sandyData.State == "Sinkhole" then
							sandySprite:Play("Suck War Spit End")
							ent:Remove()
							return false
						end
					end
				end
			end
		end
	end
end, EntityType.ENTITY_WAR)

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, ent, airMovementData, fromPit)
	local data, sprite = ent:GetData(), ent:GetSprite()
	if data.SandyParent then
		ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		if ent.Variant == 10 then
			ent.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			ent:ToNPC().State = NpcState.STATE_ATTACK --8, crying
			sprite:Play("Land", true)
		else
			if sprite:IsPlaying("InAir Cry") or sprite:IsPlaying("InAir Attack1") or sprite:IsPlaying("InAir Attack2") then
				for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, true)) do
					if GetPtrHash(data.SandyParent) == GetPtrHash(sandy) then
						local sandyData = sandy:GetData()
						if sandyData.State == "Shriek" then --just in case a war from the sandhole phase persists after sandy goes into her final shriek phase
							local newWar = Isaac.Spawn(EntityType.ENTITY_WAR, 10, 0, ent.Position, Vector.Zero, sandy):ToNPC()
							local newWarData, newWarSprite = newWar:GetData(), newWar:GetSprite()
							if newWar.SubType ~= 0 then
								newWar.SubType = 0
								newWarSprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
								newWar.Scale = 1
							end

							newWar:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

							newWarData.SandyParent = sandy

							newWarSprite:Load("gfx/bosses/revel2/sandy/sandy_war_without_horse.anm2", true)
							newWarSprite:Play("InAir", true)
							newWar.RenderZOffset = ent.RenderZOffset

							newWar.HitPoints = ent.HitPoints

							newWar.State = NpcState.STATE_ATTACK --8, crying
							newWarSprite:Play("Land", true)
						else --just in case the war somehow misses falling into sandy's mouth
							sandyData.AteWar = true
						end
					end
				end
				ent:Remove()
				return false
			else
				sprite:Play("Land", true)
				ent:ToNPC().State = NpcState.STATE_JUMP
			end
		end
	end
end, EntityType.ENTITY_WAR)

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	local data, sprite = npc:GetData(), npc:GetSprite()
	if npc.Variant ~= 10 and data.SandyParent then
		if sprite:IsFinished("InAir Attack1") or sprite:IsFinished("InAir Attack2") then
			sprite:Play("InAir Cry", true)
		end
		if sprite:IsPlaying("InAir Cry") or sprite:IsPlaying("InAir Attack1") or sprite:IsPlaying("InAir Attack2") then
			for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, true)) do
				if GetPtrHash(data.SandyParent) == GetPtrHash(sandy) then
					npc.Position = sandy.Position
				end
			end

			if sprite:IsEventTriggered("Attack") then
				if sprite:IsPlaying("InAir Attack1") then
					REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)
					local warProjParams = ProjectileParams()
					warProjParams.HeightModifier = warProjParams.HeightModifier - 80
					warProjParams.FallingAccelModifier = warProjParams.FallingAccelModifier + 0.5
					npc:FireProjectiles(npc.Position, Vector(8,0), 8, warProjParams)
				elseif sprite:IsPlaying("InAir Attack2") then
					REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 1)

					local startingFrame = 10
					for i=1, math.random(4,5) do
						REVEL.DelayFunction(spawnRandomBombAroundPosition, startingFrame, {npc.Position, 100, 250, Vector.Zero, npc}, true)
						startingFrame = startingFrame + 3
					end
				end
			end

			return true
		end
	end
end, EntityType.ENTITY_WAR)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	local data, sprite = npc:GetData(), npc:GetSprite()
	if data.SandyParent then
		if npc.Variant == 10 then
			if sprite:IsFinished("Land") then
				npc.State = NpcState.STATE_MOVE
			end
			if npc.State == NpcState.STATE_MOVE then
				npc.Velocity = npc.Velocity * 0.9
			end
		elseif not sprite:IsPlaying("InAir Cry") and not sprite:IsPlaying("InAir Attack1") and not sprite:IsPlaying("InAir Attack2") then
			data.LastPosition = data.LastPosition or npc.Position
			data.Loops = data.Loops or 0

			if npc.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			end

			if sprite:IsPlaying("Land") then
				npc.Velocity = Vector.Zero
				if sprite:IsEventTriggered("Attack") then
					REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 1)
				end
			end

			if sprite:IsPlaying("Dash") and npc.State ~= NpcState.STATE_ATTACK2 then
				npc.State = NpcState.STATE_ATTACK2
			end
			if npc.State == NpcState.STATE_ATTACK2 then
				if npc.Position.X > data.LastPosition.X + 100 or npc.Position.X < data.LastPosition.X - 100 then
					data.Loops = data.Loops + 1
					data.IsHere = false
					local yPos = Isaac.GetRandomPosition().Y

					for i,sandy in ipairs(Isaac.FindByType(REVEL.ENT.SANDY.id, REVEL.ENT.SANDY.variant, -1, false, true)) do
						if GetPtrHash(data.SandyParent) == GetPtrHash(sandy) then
							local sandyData = sandy:GetData()
							if sandyData.State == "Sinkhole" then
								sandyData.AteWar = true
								npc:Remove()
								return
							end
							if sandyData.WaitingForWar then
								yPos = sandy.Position.Y
								data.IsHere = true
								break
							end
						end
					end

					npc.Position = Vector(npc.Position.X, yPos)

					sprite.Color = Color(1,1,1,1,conv255ToFloat(0,0,0))
					npc.Scale = 1
				end
				data.LastPosition = npc.Position
			end
		end
	end
end, EntityType.ENTITY_WAR)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, cooldown)
	local data = ent:GetData()
	if data.SandyParent and data.SandyParent:Exists() then
		local sandyHealthPercentage = math.ceil((data.SandyParent.HitPoints / data.SandyParent.MaxHitPoints)*100)
		if sandyHealthPercentage > 5 then
			local hp = ent.HitPoints
			ent.HitPoints = ent.MaxHitPoints
			if amount + REVEL.GetDamageBuffer(ent) >= hp then
				return false
			end
		end
	end
end, EntityType.ENTITY_WAR)

end

----------
--REWARD--
----------
do

local chewedPonyChance = 100
local horsemanItemChance = 50
local canGrantSandyReward = false
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	canGrantSandyReward = false
	if not revel.data.sandySeenWarIntro then
		chewedPonyChance = 100
	else
		chewedPonyChance = 20
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	canGrantSandyReward = true
end, REVEL.ENT.SANDY.id)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, velocity, spawner, seed)
	if canGrantSandyReward and type == 5 and variant == 100 then
		canGrantSandyReward = false
		local currentRoom = StageAPI.GetCurrentRoom()
		local boss = nil
		if currentRoom then
			boss = StageAPI.GetBossData(currentRoom.PersistentData.BossID)
		end
		if boss and (boss.Name == "Sandy" or boss.NameTwo == "Sandy") then
			local rng = REVEL.RNG()
			rng:SetSeed(seed, 0)
			if not REVEL.OnePlayerHasCollectible(REVEL.ITEM.HALF_CHEWED_PONY.id) and rng:RandomInt(100)+1 <= chewedPonyChance then
				return {type, variant, REVEL.ITEM.HALF_CHEWED_PONY.id, seed}
			elseif rng:RandomInt(100)+1 <= horsemanItemChance then
				if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES) then
					return {type, variant, CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES, seed}
				else
					return {type, variant, CollectibleType.COLLECTIBLE_CUBE_OF_MEAT, seed}
				end
			end
		end
	end
end)

end

end