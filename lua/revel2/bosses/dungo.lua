REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--[[
    TODO tweaks

- boulders should spawn in a line to begin with to avoid snapping
- probably should avoid falling on grids or break them

- add splash gibs for when the balls land (and maybe when he stomps on them too)
- splash gibs and spawn a fart or something when the balls die, its underwhelming as is
- i think the shockwaves should move quicker since they look stiff and unthreatening as is
    - maybe make them move in straighter, more predictable patterns to compensate
- recolor the 2nd phase’s farts red
- the marker for where the balls land should blink
- spew poop gibs(that quickly disappear to stop it from getting too messy) from behind the last ball to make it look like it’s rolling... better??
- as the balls take damage they can shed poop gibs that quickly disappear (like greedier)
]]

REVEL.Elites.Dungo = {
    Music = REVEL.SFX.ELITE2,
    ClearMusic = REVEL.SFX.TOMB_BOSS_OUTRO
}

function REVEL.DungoSetUpTargets(dungo, amounttargets, color)
	local targets = {}
	for i=1, amounttargets do
		local pos
		local length = 2000
		local topleft = REVEL.room:GetTopLeftPos()
		local bottomright = REVEL.room:GetBottomRightPos()
		local targetpos = Vector(math.min(math.max(REVEL.player.Position.X, topleft.X+40), bottomright.X-40),math.min(math.max(REVEL.player.Position.Y, topleft.Y+40), bottomright.Y-40))
		while true do
			pos = REVEL.room:GetRandomPosition(0)
            local nearothertarget = REVEL.some(targets, function(t) return (t.Position-pos):LengthSquared() <= 40 ^ 2 end)

			if not nearothertarget and REVEL.room:IsPositionInRoom(pos, -40) and (targetpos-pos):LengthSquared() <= length then
				local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(pos))
				if not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or REVEL.IsGridBroken(grid) then
					break
				end
			end
			length = length+50
		end
		local target = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, pos, Vector.Zero, dungo)
		target:GetSprite():Load("gfx/1000.030_dr. fetus target.anm2", true)
		target:GetSprite():Play("Idle", true)
		target:GetSprite().Color = color
		table.insert(targets, target)
	end
	return targets
end

local PoopCapByRoomType = {
    [RoomShape.ROOMSHAPE_1x1] = 4,
    [RoomShape.ROOMSHAPE_IH] = 1,
    [RoomShape.ROOMSHAPE_IV] = 1,
    [RoomShape.ROOMSHAPE_IIH] = 4,
    [RoomShape.ROOMSHAPE_IIV] = 4,
    [RoomShape.ROOMSHAPE_1x2] = 7,
    [RoomShape.ROOMSHAPE_2x1] = 7,
    [RoomShape.ROOMSHAPE_2x2] = 15,
    [RoomShape.ROOMSHAPE_LTL] = 10,
    [RoomShape.ROOMSHAPE_LTR] = 10,
    [RoomShape.ROOMSHAPE_LBL] = 10,
    [RoomShape.ROOMSHAPE_LBR] = 10,
}

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant ~= REVEL.ENT.DUNGO.variant then return end

	local sprite,data = npc:GetSprite(),npc:GetData()

    if not data.Init then
        data.PoopTargets = {}
		---@type Entity[]
        data.PoopBoulders = {}
        data.BoulderPrevMovement = {}
        data.ExplodingPoops = {}
        data.ExplodingRedPoops = 0
        data.JumpChance = 60
        data.PoopSpeed = 8.5
        data.PoopSpawningChance = 30
        data.RedPoopCap = PoopCapByRoomType[REVEL.room:GetRoomShape()] or 10
        data.MaxBoulders = 3
        REVEL.SetScaledBossHP(npc)
        data.TotalHealth = npc.MaxHitPoints
        data.Phase = 1

		npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
		npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		npc.MaxHitPoints = data.TotalHealth / 2
		npc.HitPoints = npc.MaxHitPoints
		for _,player in ipairs(REVEL.players) do
			if player.Luck >= 4 then
				data.GoldenPoopBoulder = math.random(1,data.MaxBoulders)
				break
			end
		end
		data.Init = true
		npc.Mass = 80
	end

	REVEL.ApplyKnockbackImmunity(npc)

	if sprite:IsEventTriggered("Land") then
		REVEL.game:ShakeScreen(2)
		REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND , 1, 0, false, 1)
	end
	if sprite:IsEventTriggered("Jump") then
		REVEL.sfx:NpcPlay(npc, REVEL.SFX.SWING, 0.8, 0, false, 1)
	end
	if sprite:IsEventTriggered("Phase2") then
		REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_PHASE_2, 0.8, 0, false, 1)
	end
	if sprite:IsEventTriggered("Explode") then
		REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_PLUNGER_ATTACK, 0.8, 0, false, 1)
	end
	if sprite:IsEventTriggered("Shoot") then
		REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_SHOOT_POOP_BALL, 0.8, 0, false, 1)
	end
	if sprite:IsEventTriggered("Cry") then
		REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_CRYOUT, 0.7, 0, false, 1)
	end

	if sprite:IsFinished("Appear") and npc.FrameCount > 5 then -- setting up targets
        sprite:Play("ShootPoop", true)
        data.State = "Intro"
		data.PoopTargets = REVEL.DungoSetUpTargets(npc, data.MaxBoulders, Color(0, 0, 0, 1,conv255ToFloat(200, 30, 30)))
	end

	if sprite:IsPlaying("ShootPoop") then
		npc.Velocity = npc.Velocity * 0.8
	end

    if sprite:IsFinished("ShootPoop") or sprite:IsFinished("ShootPoop2") then
        data.State = "MountingPoop"
		data.RunningAwayFromPlayer = true
	end

	if data.RunningAwayFromPlayer then -- running while boulders are falling down
		npc.Velocity = (npc.Position-npc:GetPlayerTarget().Position):Resized(5)
		if math.abs(npc.Velocity.X) < math.abs(npc.Velocity.Y) then
			if npc.Velocity.Y > 0 and not sprite:IsPlaying("WalkDown") then
				sprite:Play("WalkDown", true)
			elseif npc.Velocity.Y < 0 and not sprite:IsPlaying("WalkUp") then
				sprite:Play("WalkUp", true)
			end
		elseif math.abs(npc.Velocity.X) >= math.abs(npc.Velocity.Y) and not sprite:IsPlaying("WalkHori") then
			sprite:Play("WalkHori", true)
		end
		sprite.FlipX = npc.Velocity.X < 0

		if data.FallingBoulder and (data.FallingBoulder:GetSprite():IsFinished("Roll Start") or not data.FallingBoulder:Exists()) then
			data.FallingBoulder:GetSprite().PlaybackSpeed = 0
			data.FallingBoulder = nil
			if #data.PoopTargets == 0 then
                sprite:Play("JumpOnFull", true)
                data.State = "JumpingOnBoulder"
				data.RunningAwayFromPlayer = false
			end
		end
		if data.FallingBoulder and data.FallingBoulder:GetSprite():IsEventTriggered("ScreenShake") then
			data.FallingBoulder.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_LAND_ON_POOP, 1, 0, false, 1)
            REVEL.game:ShakeScreen(10)
		end
		if not data.FallingBoulder and #data.PoopTargets ~= 0 then
			data.FallingBoulder = Isaac.Spawn(REVEL.ENT.POOP_BOULDER.id, REVEL.ENT.POOP_BOULDER.variant, 0, data.PoopTargets[#data.PoopTargets].Position, Vector.Zero, npc)
			data.FallingBoulder:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			data.FallingBoulder:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
			data.FallingBoulder:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
			data.FallingBoulder:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
			data.FallingBoulder.Mass = 80

            local bdata, bsprite = data.FallingBoulder:GetData(), data.FallingBoulder:GetSprite()
            bdata.Dungo = npc
            if data.Phase == 2 then
                bdata.IsRedPoopBoulder = true
                local sheet
                if data.GoldenPoopBoulder and #data.PoopTargets == data.GoldenPoopBoulder then
                    sheet = "gfx/bosses/revel2/dungo/poop_boulder_gold.png"
                    bdata.IsGoldenPoopBoulder = true
                else
                    sheet = "gfx/bosses/revel2/dungo/poop_boulder_red.png"
                end

                bsprite:ReplaceSpritesheet(2, sheet) -- not sure why the dungo anm2 has 3 layers but w/e
                bsprite:LoadGraphics()
            end

            bsprite:Play("Roll Start", true)
            REVEL.SetScaledBossSpawnHP(npc, data.FallingBoulder, 1 / 6, data.TotalHealth)
			data.PoopTargets[#data.PoopTargets]:Remove()
			table.remove(data.PoopTargets, #data.PoopTargets)
			table.insert(data.PoopBoulders, data.FallingBoulder)
		end
	end

	if sprite:IsFinished("StopWalkHori") then
		sprite:Play("Plunger", true)
	end
	if sprite:IsPlaying("Plunger") and sprite:IsEventTriggered("Explode") then -- activate poops exploding
		data.PoopsAreExploding = true
		data.PoopsExplodingCountdown = 30
	end
	if sprite:IsFinished("Plunger") then
		sprite:Play("WalkHori", true)
		data.BouldersStop = false
		if data.Phase == 2 then
			data.PlungerDelay = 280
		end
		data.PoopBoulders[1].Velocity = (data.BoulderPrevMovement[1]-data.BoulderPrevMovement[2]):Resized(data.PoopSpeed)
	end

	if data.PoopsAreExploding then -- poops exploding one by one
		for _,gridindex in ipairs(data.ExplodingPoops) do
			local poop = REVEL.room:GetGridEntity(gridindex)
			if poop then
				local spr = poop:GetSprite()
				if poop.Desc.Type == GridEntityType.GRID_POOP and poop.State ~= 1000 then
					if npc.FrameCount%10 == 0 then
						spr:ReplaceSpritesheet(0, "gfx/grid/revel2/blink_poop.png")
						spr:LoadGraphics()
						
					elseif npc.FrameCount%10 == 1 then
						--Isaac.ConsoleOutput(tostring(poop:GetVariant()))
						if poop:GetVariant() == 0 then
							spr:ReplaceSpritesheet(0, "gfx/grid/grid_poop_1.png")
						else
							spr:ReplaceSpritesheet(0, "gfx/grid/grid_poop_red_1.png")
						end
						spr:LoadGraphics()
					end
				elseif poop.Desc.Type == GridEntityType.GRID_POOP and (npc.FrameCount + 1)%10 == 0 then
					if poop:GetVariant() == 0 then
						spr:ReplaceSpritesheet(0, "gfx/grid/grid_poop_1.png")
					else
						spr:ReplaceSpritesheet(0, "gfx/grid/grid_poop_red_1.png")
					end
					spr:LoadGraphics()
				end
			end
		end
		data.PoopsExplodingCountdown = data.PoopsExplodingCountdown-1

		if npc.FrameCount%5 == 1 and data.PoopsExplodingCountdown <= 0 then
			local poops = {}
			for _,gridindex in ipairs(data.ExplodingPoops) do
				local poop = REVEL.room:GetGridEntity(gridindex)
				if poop and poop.Desc.Type == GridEntityType.GRID_POOP and poop.State ~= 1000 then
					table.insert(poops, poop)
				end
			end
			if #poops > 0 and data.PoopsExplodingCountdown > -60 then
				local r = math.random(1,#poops)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, poops[r].Position, Vector.Zero, nil)
				for _,player in ipairs(REVEL.players) do
					if (player.Position-poops[r].Position):LengthSquared() <= 3000 then
						player:TakeDamage(1, 0, EntityRef(npc), 30)
					end
				end

				local amountprojs, startangle, projvariant
				-- RED
				if poops[r].Desc.Variant == 1 then
					amountprojs = 6
					startangle = 0 --math.random(0,360/amountprojs-1)
					projvariant = ProjectileVariant.PROJECTILE_NORMAL
				-- NORMAL
				else
					amountprojs = 4
					startangle = 0
					projvariant = ProjectileVariant.PROJECTILE_PUKE
				end

				for i=1, amountprojs do
					local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, projvariant, 0, poops[r].Position, Vector.FromAngle(startangle+360/amountprojs*i)*(8), nil)
					--[[if poops[r].Desc.Variant == 1 then
						proj:GetData().BouncingProjectile = true
						proj:ToProjectile().ProjectileFlags = ProjectileFlags.NO_WALL_COLLIDE
					end]]
				end

				poops[r]:Destroy(true)
				--[[if poops[r].Desc.Variant == 1 then
					REVEL.room:RemoveGridEntity(poops[r]:GetGridIndex(), 0, false)
				end]]
			else
				data.PoopsAreExploding = false
			end
		end
	end

	if sprite:IsPlaying("JumpOnFull") then -- jump towards the first boulder to start the train
		if sprite:IsEventTriggered("Jump") then
			if data.PoopBoulders[1] then
				npc.Velocity = (data.PoopBoulders[1].Position+Vector(0,3)-npc.Position)/22
				sprite.Offset = Vector(0,-40)
			end
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		end
		if sprite:IsEventTriggered("Land") then
			REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_LAND_ON_POOP, 0.8, 0, false, 1)
            npc.Velocity = Vector.Zero
            REVEL.game:ShakeScreen(2)
			data.HPGrab = npc.HitPoints
		end
		if sprite:WasEventTriggered("Land") then
            npc.Velocity = Vector.Zero
			for i, boulder in ripairs(data.PoopBoulders) do
				if not boulder:IsDead() and boulder:Exists() then
					boulder.Velocity = Vector.Zero
				end
			end
		end
	end
    if sprite:IsFinished("JumpOnFull") then
        data.State = "OnPoops"
		sprite:Play("WalkHori", true)
		data.CurrentBoulder = data.PoopBoulders[1]
		if data.CurrentBoulder then --if boulders not already killed by player somehow
			data.CurrentBoulder:GetData().OnRightPos = true

			local dir
			if data.Phase == 2 then
				dir = npc:GetPlayerTarget().Position - npc.Position
				dir = dir:Rotated(math.random(-30, 30))
			else
				dir = Vector(2*(math.random(0,1)-0.5),(math.random(0,1)-0.5))
				dir = Vector(sign(dir.X), sign(dir.Y) * 0.3)
			end
			data.CurrentBoulder.Velocity = dir:Resized(data.PoopSpeed)

			data.BoulderPrevMovement = {}
			for i=1, (data.MaxBoulders-1)*10+1 do
				local topleft = REVEL.room:GetTopLeftPos()
				local bottomright = REVEL.room:GetBottomRightPos()
				local x = data.PoopBoulders[1].Position.X+data.PoopBoulders[1].Velocity.X*-i
				local y = data.PoopBoulders[1].Position.Y+data.PoopBoulders[1].Velocity.Y*-i
				data.BoulderPrevMovement[i] = Vector(math.min(math.max(x, topleft.X), bottomright.X), math.min(math.max(y, topleft.Y), bottomright.Y))
			end
			data.BouldersRolling = true
		end
	end

    if sprite:IsFinished("FallOffStart") then -- when the last boulder was broken
		sprite:Play("FallOffLoop", true)
	end
	if sprite:IsPlaying("FallOffLoop") then
		sprite.Offset = Vector(0,sprite.Offset.Y+20.1)
		if sprite.Offset.Y >= 0 then
			sprite.Offset = Vector(0,0)
			sprite:Play("FallOffEnd"..tostring(data.Phase-1), true)
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			data.BouldersRolling = false
			data.BouldersStop = false
		end
	end
    if sprite:IsFinished("FallOffEnd1") then
        data.State = "MidPoint"
		sprite:Play("ShootPoop2", true)
		data.PoopTargets = REVEL.DungoSetUpTargets(npc, data.MaxBoulders, Color(0, 0, 0, 1,conv255ToFloat(200, 30, 30)))
	end
    if sprite:IsFinished("FallOffEnd2") then
        data.State = "End"
		sprite:Play("Cry", true)
	end

	local isjumping = REVEL.MultiPlayingCheck(sprite, "Jump3", "Jump2", "Jump1", "FallOffStart", "FallOffLoop")

	if isjumping and not REVEL.MultiPlayingCheck(sprite, "FallOffStart", "FallOffLoop") then -- jump to other boulder
		local frame = sprite:GetFrame()
		if frame >= 7 and frame < 31 then
			npc.Velocity = (data.CurrentBoulder.Position+Vector(0,3)-npc.Position)/math.abs(frame-31)+data.CurrentBoulder.Velocity
		elseif frame > 31 then
			npc.Position = data.CurrentBoulder.Position+Vector(0,3)
			npc.Velocity = data.CurrentBoulder.Velocity
		end
		if sprite:IsEventTriggered("Land") then
			REVEL.sfx:NpcPlay(npc, REVEL.SFX.DUNGO_LAND_ON_POOP, 0.8, 0, false, 1)
			REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.8, 0, false, 1)
			local dir = (data.CurrentBoulder.Velocity):GetAngleDegrees()+90
			for i=1, 2 do
                REVEL.SpawnDungoShockwave(npc.Position+Vector.FromAngle(dir)*60, dir)
                REVEL.game:ShakeScreen(5)
				dir=dir-180
			end
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, npc.Position, Vector.Zero, nil)
		end
	end
	if REVEL.MultiFinishCheck(sprite, "Jump1", "Jump2", "Jump3") then
		sprite:Play("WalkHori", true)
		if data.CurrentBoulder:GetData().DieWhenJumpedOn then
			for _,boulder in ipairs(data.PoopBoulders) do
                if GetPtrHash(boulder) ~= GetPtrHash(data.CurrentBoulder) then
					boulder.HitPoints = boulder.HitPoints+(boulder.MaxHitPoints-boulder.HitPoints)/2
				end
			end
			data.CurrentBoulder:Die()
		end
		data.BouldersStop = false
		if data.PoopBoulders[1] then
			if data.BoulderPrevMovement[1] and data.BoulderPrevMovement[2] then
				data.PoopBoulders[1].Velocity = (data.BoulderPrevMovement[1] - data.BoulderPrevMovement[2]):Resized(data.PoopSpeed)
			else
				data.PoopBoulders[1].Velocity = data.PoopBoulders[1].Velocity * 0.9
			end
		end
	end

	local iswalking = REVEL.MultiPlayingCheck(sprite, "WalkHori", "WalkHori2", "WalkDown2", "WalkUp2")

	for i,boulder in ripairs(data.PoopBoulders) do -- check for missing boulders
		if boulder:IsDead() or not boulder:Exists() then
			boulder:GetSprite().PlaybackSpeed = 1
			table.remove(data.PoopBoulders, i)

			REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
			local eff = Isaac.Spawn(1000, EffectVariant.POOF02, 1, boulder.Position, Vector.Zero, npc)
			eff.SpriteScale = Vector.One * 0.8
			if data.Phase == 2 then
				eff.Color = Color(0.7,0.1,0.2,1)
			else
				eff.Color = Color(0.5,0.4,0.3,1)
			end
		elseif boulder:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN) then
			boulder:Kill()
			table.remove(data.PoopBoulders, i)
		end
	end

    data.BouldersStop = data.BouldersStop or (#data.PoopBoulders == 0 and iswalking and not data.RunningAwayFromPlayer)

	if data.BouldersRolling then
		if not data.BouldersStop then
			if not data.BoulderLoopPlaying then
				data.BoulderLoopPlaying = true
				REVEL.sfx:Play(REVEL.SFX.DUNGO_POOP_BALL_ROLLING_LOOP, 0.6, 0, true, 1)
			end
			local bprevmovelength = #data.BoulderPrevMovement
			for i=1, bprevmovelength do
				if i ~= 1 then
					local ri = bprevmovelength-i
					data.BoulderPrevMovement[ri+1] = data.BoulderPrevMovement[ri]
				end
            end
			data.BoulderPrevMovement[1] = data.PoopBoulders[1] and data.PoopBoulders[1].Position or data.BoulderPrevMovement[1]
		elseif data.BoulderLoopPlaying then
			data.BoulderLoopPlaying = false
			REVEL.sfx:Stop(REVEL.SFX.DUNGO_POOP_BALL_ROLLING_LOOP)
		end
	
        for i, boulder in ipairs(data.PoopBoulders) do -- train boulder movement
			if not data.BouldersStop then
				if i ~= 1 then
					boulder.Velocity = (data.BoulderPrevMovement[(i-1)*10]-boulder.Position):Resized(math.min((data.BoulderPrevMovement[(i-1)*10]-boulder.Position):Length(), 10))
                else
                    local boulderData = boulder:GetData()
                    boulderData.CurrentVel = boulderData.CurrentVel or Vector.One * (data.PoopSpeed or 4)

                    if boulder:CollidesWithGrid() then
                        -- given the velocity after response, guess the normal based on what direction the velocity shifted
                        local normal = REVEL.GetCardinal((boulder.Velocity - boulderData.CurrentVel):Normalized())

                        boulder.Velocity = boulderData.CurrentVel
                        boulder.Velocity = boulder.Velocity - normal * (2 * boulder.Velocity:Dot(normal)) -- reflect the velocity along the normal
                        boulder.Velocity = Vector(sign(boulder.Velocity.X), sign(boulder.Velocity.Y) * 0.3) -- add horizontal bias, velocity will be properly scal
                        REVEL.game:ShakeScreen(5)
                    end

					local lengthBeforeTargeting = boulder.Velocity:Length()
					if lengthBeforeTargeting < 1 then -- somehow stopped, kick in some random cardinal direction
						boulder.Velocity = Vector.FromAngle(45 + 90 * math.random(4)) * data.PoopSpeed
					else
                    	boulder.Velocity = boulder.Velocity * (data.PoopSpeed / lengthBeforeTargeting)
					end

					local angle = (npc:GetPlayerTarget().Position - boulder.Position):GetAngleDegrees() - boulder.Velocity:GetAngleDegrees()
					boulder.Velocity = boulder.Velocity:Rotated(1 * sign(angle)) -- rotate slightly towards target each frame

                    if data.Phase == 2 then
                        -- don't spawn creep if the only boulder left is gold
                        if npc.FrameCount % 11 == 0
                        and not (#data.PoopBoulders == 1 and boulder:GetData().IsGoldenPoopBoulder) then
                            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, boulder.Position, npc, false)
                            REVEL.UpdateCreepSize(creep, creep.Size * 1.5, true)
                            creep:ToEffect():SetTimeout(50)
                        end
                    end

					if not boulderData.CurrentVel or boulder.Velocity:LengthSquared() > 1 then
                    	boulderData.CurrentVel = boulder.Velocity
					end


					data.CoffinDelay = data.CoffinDelay or 0
					if data.CoffinDelay > 0 then
						data.CoffinDelay = data.CoffinDelay - 1
					else
						-- activating cornercoffins
						local cornercoffins = REVEL.ENT.CORNER_COFFIN:getInRoom()
						for _,coffin in ipairs(cornercoffins) do
							if coffin.Position:DistanceSquared(boulder.Position) <= 30 ^ 2 then
								local cdata = coffin:GetData()
								if not cdata.SpawnEnemies or #cdata.SpawnEnemies == 0 then
									cdata.Triggered = true
									cdata.AllFriendly = nil
									cdata.LastFriendly = nil
									data.CoffinDelay = 200
								end
							end
						end
					end

					-- activating traptiles
					for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
						local tdata = trap:GetData()
						if tdata.TrapData and REVEL.IsTrapTriggerable(trap, tdata) then
							if REVEL.room:GetGridIndex(trap.Position) == REVEL.room:GetGridIndex(boulder.Position) then
								REVEL.TriggerTrap(trap, REVEL.player)
							end
						end
					end

					for _,gridindex in ipairs(data.ExplodingPoops) do -- destroy poops on contact
						local poop = REVEL.room:GetGridEntity(gridindex)
						if poop and poop.Desc.Type == GridEntityType.GRID_POOP and poop.State ~= 1000 then
							if poop.Position:DistanceSquared(boulder.Position+boulder.Velocity:Resized(10)) <= 3000 then
								poop:Destroy()
							end
						end
					end
				end

				if i == #data.PoopBoulders then -- last boulder spawning poop
                    if math.random(1,data.PoopSpawningChance) == 1 then
                        if boulder:GetData().IsGoldenPoopBoulder then
                            local gridindex = REVEL.room:GetGridIndex(boulder.Position + boulder.Velocity:Resized(-40))
                            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, REVEL.room:GetGridPosition(gridindex), Vector.Zero, boulder)
							-- damage boulder, to prevent exploits
							boulder:TakeDamage(boulder.MaxHitPoints / 25, 0, EntityRef(boulder), 10)
                        else
                            local gridindex = REVEL.room:GetGridIndex(boulder.Position + boulder.Velocity:Resized(-70))
                            local grid = REVEL.room:GetGridEntity(gridindex)

							data.RedPoopCount = data.RedPoopCount or 0
                            if (not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or REVEL.IsGridBroken(grid))
                            and data.RedPoopCount <= data.RedPoopCap then

                                local poop = Isaac.GridSpawn(GridEntityType.GRID_POOP, data.Phase-1, REVEL.room:GetGridPosition(gridindex), true)
                                --table.insert(revel.RemovePoopPickupPositions, poop.Position)
                                REVEL.sfx:Play(SoundEffect.SOUND_PLOP, 0.5, 0, false, 1)
                                table.insert(data.ExplodingPoops, gridindex)

                                if data.Phase == 2 then 
									data.ExplodingRedPoops = data.ExplodingRedPoops + 1 
									data.RedPoopCount = data.RedPoopCount + 1
								end
							end
						end
					end
				end
			else
				boulder.Velocity = Vector.Zero
			end

			if boulder.Velocity:LengthSquared() > 1 then
				if math.abs(boulder.Velocity.X) > math.abs(boulder.Velocity.Y) then
					if boulder.Velocity.X > 0 and not boulder:GetSprite():IsPlaying("Rolling") then
						boulder:GetSprite():Play("Rolling", true)
					elseif boulder.Velocity.X < 0 and not boulder:GetSprite():IsPlaying("Rolling 3") then
						boulder:GetSprite():Play("Rolling 3", true)
					end
				else
					if boulder.Velocity.Y > 0 and not boulder:GetSprite():IsPlaying("Rolling 2") then
						boulder:GetSprite():Play("Rolling 2", true)
					elseif boulder.Velocity.Y < 0 and not boulder:GetSprite():IsPlaying("Rolling 4") then
						boulder:GetSprite():Play("Rolling 4", true)
					end
				end
				boulder:GetSprite().PlaybackSpeed = boulder.Velocity:Length()/10
			else
				boulder:GetSprite().PlaybackSpeed = 0
			end
		end

		data.PlungerDelay = data.PlungerDelay or 0
		if data.PlungerDelay > 0 then
			data.PlungerDelay = data.PlungerDelay - 1
		end

		-- plunger attack
		if not sprite:IsPlaying("StopWalkHori") and not sprite:IsPlaying("Plunger") 
		and not data.PoopsAreExploding and not isjumping and data.PlungerDelay <= 0 then
			local numactivepoops = 0
			for _,gridindex in ipairs(data.ExplodingPoops) do
				local poop = REVEL.room:GetGridEntity(gridindex)
				if poop and poop.Desc.Type == GridEntityType.GRID_POOP and poop.State ~= 1000 then
					numactivepoops = numactivepoops+1
				end
			end
			if numactivepoops >= 6 then
				data.BouldersStop = true
				for _,boulder in ipairs(data.PoopBoulders) do
					boulder.Velocity = Vector.Zero
				end
				if iswalking then
					if sprite:IsPlaying("WalkDown2") then
						sprite:Play("StopWalkDown", true)
					elseif sprite:IsPlaying("WalkUp2") then
						sprite:Play("StopWalkUp", true)
					else
						sprite:Play("StopWalkHori", true)
					end
					REVEL.game:ShakeScreen(5)
					npc.Velocity = Vector.Zero
					iswalking = false
				else
					sprite:Play("Plunger")
				end
			end
		end

		if data.CurrentBoulder then -- dungo staying on boulder
			if (data.CurrentBoulder:IsDead() or not data.CurrentBoulder:Exists()) and not isjumping then
				if #data.PoopBoulders == 0 then
					data.Phase = data.Phase+1
					data.PoopTargets = {}
					data.PoopBoulders = {}
					data.BoulderPrevMovement = {}
					data.CurrentBoulder = nil
					sprite:Play("FallOffStart", true)
					npc.Velocity = Vector.Zero
				else
					sprite:Play("Jump3", true)
					data.CurrentBoulder = data.PoopBoulders[math.random(1,#data.PoopBoulders)]
				end
			elseif iswalking then
				npc.Position = data.CurrentBoulder.Position+Vector(0,3)
				npc.Velocity = data.CurrentBoulder.Velocity

				if data.Phase == 2 then
					if math.abs(data.CurrentBoulder.Velocity.X) < math.abs(data.CurrentBoulder.Velocity.Y) then
						if data.CurrentBoulder.Velocity.Y > 0 and not sprite:IsPlaying("WalkDown2") then
							sprite:Play("WalkDown2", true)
						elseif data.CurrentBoulder.Velocity.Y < 0 and not sprite:IsPlaying("WalkUp2") then
							sprite:Play("WalkUp2", true)
						end
					elseif math.abs(data.CurrentBoulder.Velocity.X) >= math.abs(data.CurrentBoulder.Velocity.Y) and not sprite:IsPlaying("WalkHori2") then
						sprite:Play("WalkHori2", true)
					end
				end
				sprite.FlipX = data.CurrentBoulder.Velocity.X < 0

				if #data.PoopBoulders ~= 1 and (REVEL.player.Position-npc.Position):LengthSquared() <= 30000 and math.random(1,data.JumpChance) == 1 then
					sprite:Play("Jump"..tostring(math.random(1,2)), true)
					local newboulder
					while true do
						newboulder = math.random(1,#data.PoopBoulders)
						if data.PoopBoulders[newboulder].Index ~= data.CurrentBoulder.Index then
							break
						end
					end
					data.CurrentBoulder = data.PoopBoulders[newboulder]
				end
			end
		end
	elseif data.BoulderLoopPlaying then
		data.BoulderLoopPlaying = false
		REVEL.sfx:Stop(REVEL.SFX.DUNGO_POOP_BALL_ROLLING_LOOP)
	end
	
	if data.PoopBoulders and data.HPGrab then
		if #data.PoopBoulders > 0 then
			local boulderhp = 0
			for i,boulder in ipairs(data.PoopBoulders) do
				boulderhp = boulderhp + boulder.HitPoints
			end
			local realHP = data.HPGrab*0.6
			if data.Phase == 2 then
				realHP = data.HPGrab*0.3
			end
			npc.HitPoints = math.min(npc.MaxHitPoints,realHP + boulderhp*0.4)
		else
			data.HPGrab = nil
		end
	end

	-- Failsafe in case boulders are destroyed wrong
	-- I'd feel safer operating a nuclear reactor in goddarn fukushima than relying on this
	if not data.CurrentBoulder and #data.PoopBoulders == 0 and not isjumping and iswalking and not sprite:IsPlaying("FallOffStart") and
			(not data.FrameFailsafeGotTriggeredLastTime or npc.FrameCount - data.FrameFailsafeGotTriggeredLastTime > 15) then
		-- REVEL.DebugLog(REVEL.TableToStringEnter(data))
		data.Phase = math.min(3, data.Phase+1)
		data.PoopTargets = {}
		data.PoopBoulders = {}
		data.BoulderPrevMovement = {}
		data.FrameFailsafeGotTriggeredLastTime = npc.FrameCount
		sprite:Play("FallOffStart", true)
		npc.Velocity = Vector.Zero
		REVEL.DebugToString("Dungo failsafe triggered! Phase:", data.Phase)
	end

	if data.State == "End" then
		npc.Velocity = npc.Velocity * 0.9
	end

	if npc:IsDead() then
		for _,boulder in ipairs(data.PoopBoulders) do
			boulder:GetSprite().PlaybackSpeed = 1
			boulder:Die()
		end
		data.PoopBoulders = {}
		for _,target in ipairs(data.PoopTargets) do
			target:Remove()
		end
		data.PoopTargets = {}
	end
end, REVEL.ENT.DUNGO.id)

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	if npc.Variant ~= REVEL.ENT.POOP_BOULDER.variant then return end
	
	REVEL.ApplyKnockbackImmunity(npc)
end, REVEL.ENT.POOP_BOULDER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
	if e.Variant ~= REVEL.ENT.POOP_BOULDER.variant then return end

	if src and src.Type == 0 and src.Variant == 0 then -- stops damage from red poops
		return false
	end

    local data = e:GetData()
    local dungo = data.Dungo
    local dungoData = dungo:GetData()
    if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0 then -- stop boulder from dying while dungo is jumping towards it
        local isjumpingtoboulder = false

        local boulder = dungoData.CurrentBoulder
        if boulder and GetPtrHash(boulder) == GetPtrHash(e) then
            local ds = dungo:GetSprite()
            if ds:IsPlaying("Jump1") or ds:IsPlaying("Jump2") or ds:IsPlaying("Jump3") then
                isjumpingtoboulder = true
            end
        end

		if isjumpingtoboulder then
			data.DieWhenJumpedOn = true
			e:TakeDamage(e.HitPoints - REVEL.GetDamageBuffer(e) - 1, 0, src, invuln)
			return false
		end

		for _,boulder in ipairs(dungoData) do
			if GetPtrHash(boulder) ~= GetPtrHash(e) then
				boulder.HitPoints = boulder.HitPoints+(boulder.MaxHitPoints-boulder.HitPoints)/2
			end
		end
	end

	if not dungoData.CurrentBoulder and not data.ReducedDamage then
		data.ReducedDamage = true
		e:TakeDamage(dmg/5, flag, src, invuln)
		return false
	end
	if data.ReducedDamage then
		data.ReducedDamage = false
	end
end, REVEL.ENT.POOP_BOULDER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src, invuln)
    if e.Variant ~= REVEL.ENT.DUNGO.variant then return end

    local data = e:GetData()
    if data.State == "Intro" or data.State == "MidPoint" then
		local dmgReduction = dmg*0.8
		e.HitPoints = math.min(e.HitPoints + dmgReduction, e.MaxHitPoints)
    end

	if data.Phase ~= 3 then
		e.HitPoints = e.HitPoints + (dmg - math.min(dmg, (e.HitPoints - REVEL.GetDamageBuffer(e)) / 2))
	end
end, REVEL.ENT.DUNGO.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
	if npc.Variant ~= REVEL.ENT.DUNGO.variant or not REVEL.IsRenderPassNormal() then return end
	local data, sprite = npc:GetData(), npc:GetSprite()
	
	if not data.Dying and npc:HasMortalDamage() then
		sprite:Play("Die")
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		data.Dying = true
		npc.State = NpcState.STATE_UNIQUE_DEATH
	end
	
	if IsAnimOn(sprite, "Die") then
		if not data.Died and sprite:IsEventTriggered("Death") then
			npc:BloodExplode()
			npc:Die()
			local bloodExplosion = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()
			local color = Color(1,1,1,1)
            color:SetColorize(1.4,1,0.4,1)
			bloodExplosion:SetColor(color, -1, 1, false, false)
        	REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
			data.Died = true
		end
	end
end, REVEL.ENT.DUNGO.id)

-- TODO replace with custom shockwave
function REVEL.SpawnDungoGroundBreak(pos)
    local groundbreak = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, pos, Vector.Zero, nil)
    local sprite = groundbreak:GetSprite()
	groundbreak:GetData().IsDungoGroundBreak = true
	sprite:Load("gfx/1000.062_groundbreak.anm2", true)
	sprite:ReplaceSpritesheet(0, "gfx/effects/revel2/tomb_shockwave.png")
	sprite:LoadGraphics()
    sprite:Play("Break", true)

    local radius
	if math.random(1,5) == 1 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, pos, Vector.Zero, nil)
		radius = 3000
	else
		radius = 625
    end

    for _,player in ipairs(REVEL.players) do
        if player.Position:DistanceSquared(pos) <= radius then
			player:TakeDamage(1, 0, EntityRef(groundbreak), 30)
		end
	end
end

function REVEL.SpawnDungoShockwave(pos, dir)
	local shockwave = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, pos, Vector.Zero, nil)
	shockwave:GetData().IsDungoShockwave = true
	shockwave:GetData().Direction = dir or math.random(0,359)
	shockwave.Visible = false
	REVEL.SpawnDungoGroundBreak(pos)
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if eff:GetData().IsDungoShockwave then
		if eff.FrameCount ~= 0 and eff.FrameCount%5 == 0 then
			local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(eff.Position))
			eff.Position = eff.Position+Vector.FromAngle(eff:GetData().Direction)*30
			eff:GetData().Direction = eff:GetData().Direction+math.random(-30,30)
			if (not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or REVEL.IsGridBroken(grid)) and REVEL.room:IsPositionInRoom(eff.Position, 0) then
				REVEL.SpawnDungoGroundBreak(eff.Position)
			else
				eff:Remove()
			end
		end
	elseif eff:GetData().IsDungoGroundBreak then
		if eff:GetSprite():IsFinished("Break") then
			eff:Remove()
		end
	end
end, 8)

--[[local function IsFreeGrid(pos)
	local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(pos))
	return not grid or grid.CollisionClass == GridCollisionClass.COLLISION_NONE or grid.CollisionClass == GridCollisionClass.COLLISION_PIT
end

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj) -- bouncing projectile logic
	if proj:GetData().BouncingProjectile then
		if not IsFreeGrid(proj.Position+proj.Velocity) then
			if IsFreeGrid(proj.Position+Vector(proj.Velocity.X*-1,proj.Velocity.Y)) then
				proj.Velocity = Vector(proj.Velocity.X*-1,proj.Velocity.Y)
			elseif IsFreeGrid(proj.Position+Vector(proj.Velocity.X,proj.Velocity.Y*-1)) then
				proj.Velocity = Vector(proj.Velocity.X,proj.Velocity.Y*-1)
			else
				proj.Velocity = Vector(proj.Velocity.X*-1,proj.Velocity.Y*-1)
			end
		end
	end
end)]]

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, dmg, flag, src)
    local data = e:GetData()
	if REVEL.ENT.POOP_BOULDER:isEnt(e) and not data.FakingDamage then
		local dungo = data.Dungo
		if dungo and dungo:GetData().RunningAwayFromPlayer or dungo:GetData().State == "JumpingOnBoulder" then
			data.FakingDamage = true
			e:TakeDamage(0.01, DamageFlag.DAMAGE_FAKE, src, 0)
			data.FakingDamage = false
			return false
		end
	end
end, REVEL.ENT.POOP_BOULDER.id)

local NormalPoopSprites = {"grid_poop_1.png", "grid_poop_2.png", "grid_poop_3.png"}

local function ConvertRevPoopToNormal(grid)
	if type(grid) == "number" then grid = REVEL.room:GetGridEntity(grid) end
	if not grid or grid.Desc.Type ~= GridEntityType.GRID_POOP then return end

	if grid:GetVariant() == 1 then
		grid:SetVariant(0)

		local sprite = grid:GetSprite()
		sprite:ReplaceSpritesheet(0, "gfx/grid/" .. REVEL.randomFrom(NormalPoopSprites))
		sprite:LoadGraphics()

		Isaac.Spawn(1000, EffectVariant.POOF01, 0, REVEL.room:GetGridPosition(grid:GetGridIndex()), Vector.Zero, nil)
	end
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
	if npc.Variant ~= REVEL.ENT.DUNGO.variant then return end
	local data, sprite = npc:GetData(), npc:GetSprite()

	--Turn all red poops into normal poops
	for i = 0, REVEL.room:GetGridSize() do
		ConvertRevPoopToNormal(i)
	end
end, REVEL.ENT.DUNGO.id)

end
REVEL.PcallWorkaroundBreakFunction()