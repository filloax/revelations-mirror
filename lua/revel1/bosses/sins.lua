local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.SpawnFallingStalactrite(pos, vel, parent)
	local stalactrite = REVEL.ENT.STALACTRITE:spawn(pos, vel, parent)
	stalactrite:GetSprite():Play("JumpDown", true)
	stalactrite:GetData().State = "JumpDown"
	stalactrite:GetData().Init = true
	stalactrite:GetData().Invulnerable = true
	stalactrite.SplatColor = REVEL.WaterSplatColor
	stalactrite.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	stalactrite:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	stalactrite:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
	stalactrite:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	return stalactrite
end

local MaxTrite = 1
local MaxStalactite = 5
local MaxSnowball = 2

local WalkAnims = {Horizontal = "WalkHori", Vertical = "WalkVert"}
local GreedStartSpeed = 5

local function GetOverlayColoration(r, g, b)
    return Color(r / 135, g / 135, b / 135, 1,conv255ToFloat( 0, 0, 0))
end


-------------------
-- GLACIER GREED --
-------------------

do
local function greed_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() then return end
	local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

	if npc.State == NpcState.STATE_SUMMON or npc.State == NpcState.STATE_ATTACK then
		npc.State = NpcState.STATE_MOVE
	end

	if npc.State == NpcState.STATE_MOVE and not data.GreedDash and not data.GreedShot and not data.GreedSummon and not sprite:IsPlaying("Appear") and npc.FrameCount > 30 then
		local d = target.Position-npc.Position
		if (math.abs(d.X) <= 5 and math.abs(d.Y) <= 200 or math.abs(d.Y) <= 5 and math.abs(d.X) <= 200) then
			data.GreedDash = true
			if math.abs(d.X) > math.abs(d.Y) then
				if d.X < 0 then
					data.GreedDashDir = Vector(-GreedStartSpeed,0)
					sprite:Play("WalkHori", true)
					sprite.FlipX = true
				else
					data.GreedDashDir = Vector(GreedStartSpeed,0)
					sprite:Play("WalkHori", true)
					sprite.FlipX = false
				end
			else
				if d.Y < 0 then
					data.GreedDashDir = Vector(0,-GreedStartSpeed)
					sprite:Play("WalkVert", true)
					sprite.FlipX = true
				else
					data.GreedDashDir = Vector(0,GreedStartSpeed)
					sprite:Play("WalkVert", true)
					sprite.FlipX = false
				end
			end
			sprite.PlaybackSpeed = 1.2
		end
	end

	if data.GreedDash then
		local l = data.GreedDashDir:Length()
		if l < GreedStartSpeed*2.3 then
			data.GreedDashDir = data.GreedDashDir * 1.07
		end
		npc.Velocity = data.GreedDashDir
		REVEL.AnimateWalkFrame(sprite, data.GreedDashDir, WalkAnims)
		sprite.PlaybackSpeed = REVEL.Lerp2Clamp(1.2, 1.5, l * 1.07, GreedStartSpeed, GreedStartSpeed*1.3)

		for i = 1, 3 do
			local grid
			if i == 1 then
				grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position+npc.Velocity+npc.Velocity:Resized(npc.Size)))
			elseif i == 2 then
				grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position+npc.Velocity))
			else
				grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position))
			end

			if grid and grid.Desc.Type ~= GridEntityType.GRID_DECORATION and not REVEL.IsGridBroken(grid) then
				data.GreedDash = false
				data.GreedShot = true
				npc.Velocity = Vector.Zero
				if data.GreedDashDir.X < -1 then
					sprite:Play("Attack01Hori", true)
					sprite.FlipX = false
				elseif data.GreedDashDir.X > 1 then
					sprite:Play("Attack01Hori", true)
					sprite.FlipX = true
				elseif data.GreedDashDir.Y < -1 then
					sprite:Play("Attack01Down", true)
					sprite.FlipX = true
				else
					sprite:Play("Attack01Up", true)
					sprite.FlipX = false
				end
				sprite.PlaybackSpeed = 1
				break
			end
		end
		return true
	end

	if data.GreedShot then
		npc.Velocity = Vector.Zero
		if sprite:GetFrame() == 5 then
			npc:FireProjectiles(npc.Position, data.GreedDashDir:Resized(10)*-1, 3+npc.Variant*2, ProjectileParams())
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
		end
		if sprite:IsFinished("Attack01Hori") or sprite:IsFinished("Attack01Down") or sprite:IsFinished("Attack01Up") then
			data.GreedShot = false
		end
		return true
	end

	if data.GreedSummon then
		npc.Velocity = Vector.Zero
		if sprite:GetFrame() == 4 then
			if npc.Variant == 1 then
				Isaac.Spawn(EntityType.ENTITY_KEEPER, 0, 0, npc.Position+Vector(5,10), Vector.Zero, npc)
				Isaac.Spawn(EntityType.ENTITY_KEEPER, 0, 0, npc.Position+Vector(-5,10), Vector.Zero, npc)
			else
				Isaac.Spawn(EntityType.ENTITY_KEEPER, 0, 0, npc.Position+Vector(0,10), Vector.Zero, npc)
			end
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SUMMONSOUND, 0.6, 0, false, 1)
		end
		if sprite:IsFinished("Attack02") then
			data.GreedSummon = false
		end
		return true
	end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, greed_PreNpcUpdate, EntityType.ENTITY_GREED)	
end

------------------
-- GLACIER ENVY --
------------------

do

local function envy_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() then return end
	local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

	if npc.Variant > 1 then
		if not data.Init then
			if npc.Variant%10 == 0 then
				sprite.Offset = Vector(0,-12+math.floor(npc.Variant/5))
			elseif npc.Variant%10 == 1 then
				sprite.Offset = Vector(0,-14+math.floor((npc.Variant-1)/5))
			end
			data.prevflipx = npc.Velocity.X < 0
			data.DashingCounter = 0
			data.Init = true
		end

		if data.DashingCounter ~= 0 then
			data.DashingCounter = data.DashingCounter-1
		end

		if data.prevflipx ~= (npc.Velocity.X < 0) then
			data.prevflipx = npc.Velocity.X < 0
			sprite.Rotation = -sprite.Rotation
		end

		if npc.FrameCount%5 == 0 then
			local creep = REVEL.SpawnIceCreep(npc.Position, npc):ToEffect()
			creep.Timeout = 90
			if npc.Variant%10 == 0 then
				REVEL.UpdateCreepSize(creep, creep.Size * (1-npc.Variant/50), true)
			elseif npc.Variant%10 == 1 then
				REVEL.UpdateCreepSize(creep, creep.Size * (1-npc.Variant/60), true)
			end
		end

		if data.DashingCounter == 0 and math.random(1,npc.Variant*15) == 1 then
			data.DashingCounter = 120
		end

		if data.DashingCounter <= 60 then
			sprite.Rotation = sprite.Rotation+math.abs(npc.Velocity.X*3)
		else
			sprite.Rotation = sprite.Rotation+30
		end

		if data.DashingCounter > 0 then
			if data.DashingCounter > 60 then
				npc.Velocity = npc.Velocity*0.8
				if target.Position.X-npc.Position.X < 0 and not sprite.FlipX then
					sprite.FlipX = not sprite.FlipX
					sprite.Rotation = -sprite.Rotation
				elseif target.Position.X-npc.Position.X > 0 and sprite.FlipX then
					sprite.FlipX = not sprite.FlipX
					sprite.Rotation = -sprite.Rotation
				end
			elseif data.DashingCounter == 60 then
				npc.Velocity = (target.Position-npc.Position):Resized(10)
			else
				npc.Velocity = npc.Velocity:Resized(data.DashingCounter/6)
			end
			if not npc:IsDead() then
				return true
			end
		end
	end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, envy_PreNpcUpdate, EntityType.ENTITY_ENVY)

end

----------------------
-- GLACIER GLUTTONY --
----------------------

do

local function gluttony_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() then return end
	local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

	if npc.State == NpcState.STATE_ATTACK2 then
		npc.Velocity = Vector.Zero
		local animnames = {"Horiz", "Down", "Up"}
		for i=1, 3 do
			for i2=1, 3 do
				if sprite:IsFinished("Attack0"..tostring(i2)..animnames[i]) then
					npc.State = NpcState.STATE_MOVE
				end
			end
		end
		local frame = sprite:GetFrame()
		if frame >= 10 then
			if frame == 30 then
				for i=1, 3 do
					for i2=1, 3 do
						if sprite:IsPlaying("Attack0"..tostring(i2)..animnames[i]) then
							local animname = animnames[i]
							local pooter
							if animname == "Horiz" then
								if npc:GetSprite().FlipX then
									local dir = Vector(-10,0)
									pooter = REVEL.ENT.ICE_POOTER:spawn(npc.Position+dir*2, dir:Rotated(math.min(math.max(-15, -(target.Position.Y-npc.Position.Y)/3), 15)), npc)
								else
									local dir = Vector(10,0)
									pooter = REVEL.ENT.ICE_POOTER:spawn(npc.Position+dir*2, dir:Rotated(math.min(math.max(-15, (target.Position.Y-npc.Position.Y)/3), 15)), npc)
								end
							elseif animname == "Down" then
								local dir = Vector(0,10)
								pooter = REVEL.ENT.ICE_POOTER:spawn(npc.Position+dir*2, dir:Rotated(math.min(math.max(-15, -(target.Position.X-npc.Position.X)/3), 15)), npc)
							elseif animname == "Up" then
								local dir = Vector(0,-10)
								pooter = REVEL.ENT.ICE_POOTER:spawn(npc.Position+dir*2, dir:Rotated(math.min(math.max(-15, (target.Position.X-npc.Position.X)/3), 15)), npc)
							end
							if npc.Variant == 1 then
								local pooter2 = REVEL.ENT.ICE_POOTER:spawn(npc.Position-(pooter.Position-npc.Position), pooter.Velocity*-1, npc)
								pooter2:GetSprite():Play("Land", true)
								pooter2:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
								pooter2:GetData().speed = 15
							end
							pooter:GetSprite():Play("Land", true)
							pooter:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
							pooter:GetData().speed = 15
						end
					end
				end
			end
			return true
		end
	end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, gluttony_PreNpcUpdate, EntityType.ENTITY_GLUTTONY)

end

-------------------
-- GLACIER SLOTH --
-------------------

do

local snotProjColor = GetOverlayColoration(52, 93, 89)

local function sloth_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() or npc.Variant >= 2 then return end

	local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

	if sprite:IsFinished("Attack") or sprite:IsFinished("Sneeze") then
		npc.State = NpcState.STATE_MOVE
		data.Sneeze = nil
	end
	if npc.State == NpcState.STATE_ATTACK then -- ice creep projectiles
		npc.Velocity = Vector.Zero

		if sprite:IsEventTriggered("Attack") then
			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 0.8)
			local playerDir = (target.Position - npc.Position):Normalized()
			for i = 1, math.random(6, 8) do
				local projectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, 0, 0, npc.Position, playerDir:Rotated(math.random(-25, 25)), npc):ToProjectile()
				projectile.FallingSpeed = -10 + math.random(-8, 8)
				projectile.FallingAccel = 0.5
				projectile.Velocity = projectile.Velocity * (math.random(20, 90) * 0.1)
				projectile:GetSprite():Load('gfx/projectiles/low_flash_projectile.anm2', true)
				projectile.Scale = 1 + math.random()*0.5
				projectile:GetSprite().Scale = Vector(1,1)*projectile.Scale
				local pdata = projectile:GetData()
				pdata.ColoredProjectile = snotProjColor
				pdata.IsSickieTear = true
				pdata.SpawnerSeed = npc.InitSeed
			end
		end
		return true
	elseif npc.State == NpcState.STATE_ATTACK2 then -- summon snowballs or summon stalactites
		npc.Velocity = Vector.Zero
		local force
		local cTrite, cStal, cSnowball = #REVEL.ENT.STALACTRITE:getInRoom(false, false, true) + #Isaac.FindByType(29, 1, -1, false, true), #REVEL.ENT.STALACTITE:getInRoom(false, false, false), #REVEL.ENT.ROLLING_SNOTBALL:getInRoom(false, false, true)
		if ((cTrite >= MaxTrite) or (cStal >= MaxStalactite)) and (cSnowball >= MaxSnowball) then
			force = 3 --switch over to projs, too much stuff on screen
		elseif (cTrite >= MaxTrite) or (cStal >= MaxStalactite) then
			force = 1
		elseif cSnowball >= MaxSnowball then
			force = 2
		end

		if sprite:GetFrame() == 1 then
			if math.random(4) == 1 or force == 3 then
				if not sprite:IsPlaying("Attack") then
					sprite:Play("Attack",true)
				end
				npc.State = NpcState.STATE_ATTACK --nerf cause he was way too aggressive
				data.Sneeze = nil
			
			elseif force ~= 1 and (force or math.random(1,2)) == 2 then
				if not sprite:IsPlaying("Sneeze") then
					sprite:Play("Sneeze",true)
				end
				data.Sneeze = true
			end
		end

		if sprite:IsEventTriggered("Attack") then
			if not data.Sneeze then
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SUMMONSOUND, 0.7, 0, false, 1)
				REVEL.ENT.ROLLING_SNOTBALL:spawn(npc.Position+Vector(0,10), Vector.Zero, npc)
			else
				local flip
				if sprite.FlipX then flip = -1 else flip = 1 end
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_5, 1, 0, false, 1)
				REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WEIRD_WORM_SPIT, 0.7, 0, false, 1)
					local eff = Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 5, npc.Position - Vector(-25*flip, 45), Vector.Zero, npc)
				local color = Color(1,1,1,1)
				color:SetColorize(0.6,1.2,1,1)
				eff.Color = color
				eff.DepthOffset = 50
				REVEL.game:ShakeScreen(5)
				REVEL.SpawnBlurShockwave(npc.Position)

				local playerDir = (target.Position - npc.Position)
				if npc.Variant == 1 then
					local stalactritepos
					while true do
						stalactritepos = REVEL.room:GetRandomPosition(50)
						if (stalactritepos-target.Position):Length() >= 125 then
							break
						end
					end
					REVEL.SpawnFallingStalactrite(stalactritepos, Vector.Zero, npc)
				end
				for i=1, 4 do
					REVEL.ENT.STALACTITE:spawn(npc.Position+playerDir:Rotated(i*90)/2, Vector.Zero, npc)
				end
			end
		end
		return true
	end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, sloth_PreNpcUpdate, EntityType.ENTITY_SLOTH)

end

-------------------
-- GLACIER PRIDE --
-------------------

do

-- local AuroraColors = {
-- 	Color(20 / 255, 232 / 255, 30 / 255),
-- 	Color(0 / 255, 234 / 255, 141 / 255),
-- 	Color(1 / 255, 126 / 255, 213 / 255),
-- 	Color(181 / 255, 61 / 255, 255 / 255),
-- 	Color(141 / 255, 0 / 255, 196 / 255),
-- }

local AuroraHues = {
	123 / 360,
	156 / 360,
	205 / 360,
	277 / 360,
	283 / 360,
}

local AttackDelay = {Min = 60, Max = 100}

local function GetColorAtFrameCount(npc)
	if not npc then return nil end
	-- fallback, no biggie to just use something else if pride dead or otherwise
	local frameCount = npc.FrameCount or REVEL.game:GetFrameCount()
	local hueProgress = 0.5 + 0.5 * math.sin(frameCount / 25)
	local prevIdx = (math.ceil(hueProgress * #AuroraHues) - 2) % #AuroraHues + 1
	local nextIdx =  math.ceil(hueProgress * #AuroraHues)
	-- local prevColor = AuroraHues[prevIdx]
	-- local nextColor = AuroraHues[nextIdx]
	local colorsLerp = (hueProgress * #AuroraHues) % 1
	local hue = REVEL.Lerp(AuroraHues[prevIdx], AuroraHues[nextIdx], colorsLerp)
	-- return Color.Lerp(prevColor, nextColor, colorsLerp)
	return REVEL.HSVtoColor(hue, 1, 1)
end

---@param npc EntityNPC
local function pride_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() or npc.Variant > 1 then return end

	local sprite, data = npc:GetSprite(), npc:GetData()
	
	local color = GetColorAtFrameCount(npc)
	if color then
		npc.Color = color
		local fadedColor = color*Color(1,1,1,0.5)
		REVEL.DashTrailEffect(npc, 4, 90, fadedColor)
	end

	if npc.State == NpcState.STATE_MOVE then
		local moveDir = REVEL.MoveRandomlyAxisAligned(
			npc, 45, 90, 0.5, 0.9, true
		)
		local perpDir = (moveDir + 1) % 4
		local moveWave = math.sin(npc.FrameCount / 5)
		npc.Velocity = npc.Velocity + REVEL.dirToVel[perpDir] * moveWave * 1

		REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
			Down = "WalkDown",
			Up = "WalkUp",
			Horizontal = "WalkHori",
		})

		data.AttackDelay = data.AttackDelay or REVEL.GetFromMinMax(AttackDelay)
		data.AttackDelay = data.AttackDelay - 1
		if data.AttackDelay < 0 then
			data.AttackDelay = nil
			npc.State = math.random() > 0.5 and NpcState.STATE_ATTACK or NpcState.STATE_ATTACK2
			if npc.State == NpcState.STATE_ATTACK then
				sprite:Play("Attack01", true)
			else
				sprite:Play("Attack02", true)
			end
			npc.StateFrame = 0
		else
			return true
		end
	end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, pride_PreNpcUpdate, EntityType.ENTITY_PRIDE)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, dmg, flag, src)
	if not REVEL.STAGE.Glacier:IsStage() then return end
	
	if src.SpawnerType == EntityType.ENTITY_PRIDE then
		return false
	end
end, EntityType.ENTITY_PRIDE)

StageAPI.AddCallback("Revelations", RevCallbacks.LASER_UPDATE_INIT, 1, function(e)
	if REVEL.STAGE.Glacier:IsStage() and e.Parent and e.Parent.Type == EntityType.ENTITY_PRIDE then
		e.Color = e.Parent.Color

		-- REVEL.ShootAura(data.Aura, player, npc)
		local endp = e:GetEndPoint()
		local dist = (endp-e.Position):Length()
		local dir = (endp-e.Position)/dist
		local d = dist
		local pos

		repeat
			d = d - 40
			pos = e.Position + (dir * d)
		until d <= 0 or REVEL.room:GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_NONE

		local color = REVEL.ChangeColorAlpha(GetColorAtFrameCount(e.Parent), 0.6)

		REVEL.SpawnFreezeAura(80, pos, e.Parent, 70, false, color)
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
	if bomb.SpawnerType == EntityType.ENTITY_PRIDE and REVEL.STAGE.Glacier:IsStage() then
		local data = bomb:GetData()
		if not data.SpriteChange then
			bomb:GetSprite():Load("gfx/bosses/revel1/reskins/sins/bomb_pride.anm2", true)
			bomb:GetSprite():Play("Appear",true)
			data.SpriteChange = true
		else

			local pride = Isaac.FindByType(EntityType.ENTITY_PRIDE, -1, -1, true, false)[1]
			if pride then
				bomb.Parent = pride
				bomb.Color = pride.Color
			end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, e)
	if e.Variant == EffectVariant.BOMB_EXPLOSION and REVEL.STAGE.Glacier:IsStage() then
		local bomb = Isaac.FindInRadius(e.Position, 1, -1)[1]
		if bomb and bomb.SpawnerType == EntityType.ENTITY_PRIDE then
			local pride = Isaac.FindByType(EntityType.ENTITY_PRIDE, -1, -1, true, false)[1]
			if pride then
				local color = REVEL.ChangeColorAlpha(GetColorAtFrameCount(pride), 0.6)
				REVEL.SpawnFreezeAura(60, e.Position, pride, 70, false, color)
			end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
	local data = e:GetData()
	if data.IsFreezeAura and data.Spawner and data.Spawner.Type == EntityType.ENTITY_PRIDE then
		REVEL.FreezeAura(e, true)
		if data.Time == 1 then
			REVEL.ShootAura(e, REVEL.getClosestInTable(REVEL.players, e), data.Spawner)
		end
	end
end)

end

-------------------
-- GLACIER LUST  --
-------------------

do

local function lust_PreNpcUpdate(_, npc)
	if not REVEL.STAGE.Glacier:IsStage() then return end
	local sprite,data,target = npc:GetSprite(),npc:GetData(),npc:GetPlayerTarget()

	if data.Headless then
		if npc.Variant == 1 then
			npc:MultiplyFriction(0.9)
		end

		if npc.FrameCount % 2 == 0 then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, npc.Position, npc, false):ToEffect()
            REVEL.UpdateCreepSize(creep,creep.Size*0.6)
			creep.Timeout = 5
			creep.Color = REVEL.WaterSplatColor
		end	
	end
end
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, lust_PreNpcUpdate, EntityType.ENTITY_LUST)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(npc, dmg, flag, src, invuln)
	if not npc:GetData().Headless and REVEL.STAGE.Glacier:IsStage() 
	and npc.HitPoints - dmg - REVEL.GetDamageBuffer(npc) <= npc.MaxHitPoints / 2 then
		local vel
		if src.Entity then
			vel = (npc.Position - src.Entity.Position):Resized(5)
		else
			vel = RandomVector()*5
		end

		local head = REVEL.ENT.ICE_POOTER:spawn(npc.Position, vel, npc)
		head:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		head:GetData().Lust = npc
		npc:GetData().Headless = true

		if npc.Variant == 1 then
			npc:GetSprite():Load("gfx/bosses/revel1/reskins/sins/glacier_super_lust_nohead.anm2", true)
			head:GetSprite():Load("gfx/bosses/revel1/reskins/sins/glacier_super_lust_head.anm2", true)
			head.Size = 15
			head:GetData().speed = 7
		else
			npc:GetSprite():Load("gfx/bosses/revel1/reskins/sins/glacier_lust_nohead.anm2", true)
			npc:GetSprite():PlayOverlay("Blood", true)
			head:GetSprite():Load("gfx/bosses/revel1/reskins/sins/glacier_lust_head.anm2", true)
			head.Size = 13
		end
		head:GetSprite():Play("Land", true)
	end
end, EntityType.ENTITY_LUST)

end

--------------------
-- GLACIER GREED  --
--------------------

do

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, dmg, flag, src, invuln)
	if REVEL.STAGE.Glacier:IsStage() then
		if src and src.Entity and src.Entity.Type == EntityType.ENTITY_FIREPLACE then
			local fireplaces = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, -1, -1, false, false)
			for _,fireplace in ipairs(fireplaces) do
				if fireplace.Index == src.Entity.Index then
					fireplace:Die()
					break
				end
			end
			npc:GetData().GreedDash = false
			npc:GetData().GreedShot = false
			npc:GetData().GreedSummon = true
			npc.Velocity = Vector.Zero
			npc:GetSprite():Play("Attack02", true)
			npc:TakeDamage(npc.MaxHitPoints/5, 0, EntityRef(npc), 0)
			return false
		end
	end
end, EntityType.ENTITY_GREED)

end

--------------------
-- GLACIER WRATH  --
--------------------

do

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
	if REVEL.STAGE.Glacier:IsStage() and bomb.SpawnerType == EntityType.ENTITY_WRATH then
		local data = bomb:GetData()
		if not data.Init then
			bomb:AddTearFlags(TearFlags.TEAR_BURN)
			data.Init = true
		end
		for _,player in ipairs(REVEL.players) do
			if (player.Position-bomb.Position):LengthSquared() <= 900 then
				player:TakeDamage(1, DamageFlag.DAMAGE_FIRE, EntityRef(bomb), 30)
			end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, bomb)
	if REVEL.STAGE.Glacier:IsStage() and bomb.SpawnerType == EntityType.ENTITY_WRATH then
		local fire = REVEL.filter(Isaac.FindInRadius(bomb.Position, 40, -1),
			function(e) return e.Type == EntityType.ENTITY_FIREPLACE and e.Variant == 10 end)[1]
		fire:GetData().radius = REVEL.GetChillWarmRadius()
	end
end, EntityType.ENTITY_BOMBDROP)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if eff:GetData().WrathBombFire then
		for _,player in ipairs(REVEL.players) do
			if (player.Position - eff.Position):LengthSquared() <= 900 then
				player:TakeDamage(1, DamageFlag.DAMAGE_FIRE, EntityRef(eff), 30)
			end
			REVEL.SetWarmAura(eff, eff:GetData().radius)
		end
		if eff.FrameCount == 120 then
			eff:Remove()
		end
	end
end, 6)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
	if REVEL.STAGE.Glacier:IsStage() then
		REVEL.ENT.GRILL_O_WISP:spawn(ent.Position, Vector.Zero, ent)
	end
end, EntityType.ENTITY_WRATH)

end

Isaac.DebugString("Revelations: Loaded Sins for Chapter 1!")
end