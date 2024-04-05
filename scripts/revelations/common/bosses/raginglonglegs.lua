local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()


local raginglonglegsBalance = {
	Champions = {Bomb = "Default"}, --bomb is champion

	Animation = {
		Default = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs.anm2",
		Bomb = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs_champion.anm2"
	},

	Spritesheets = {
		Default = {
			[1] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs.png",
			[2] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs2.png",
			[3] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs3.png"
		},
		Bomb = {
			[1] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs_champion.png",
			[2] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs2_champion.png",
			[3] = "gfx/bosses/revelcommon/raginglonglegs/raginglonglegs3_champion.png"
		}
	},

	AttackWeights = {
		Default = {
			[0] = { -- 0 = all phases
				ThrowSpiders = 5,
				SpawnTickingSpider = 5,
				ShootBlood = 3
			},
			[2] = {
				Combust = 7,
				CombustSpawn = 7
			}
		},
		Bomb = {
			[0] = { -- 0 = all phases
				SpawnTickingSpider = 3,
				ShootBlood = 3
			},
			[1] = {
				LayEgg = 6
			},
			[2] = {
				LayEgg = 6,
				BombExplode = 6
			},
			[3] = {
				BombExplode = 6
			}
		}
	},

	HealthMultiplier = {Default = 1.0, Bomb = 1.0},

	SpiderLimit = {Default = 2},
	TickingSpiderLimit = {Default = 1},
	SackLimit = {Default = 0, Bomb = 6},
	SacksSpawnSpiders = {Default = false},
	FireLimit = {Default = 10},

	SpawnFiresAtDashStart = {Default = true, Bomb = false},
	SpawnDuringDash = {Default = 1, Bomb = 2}, -- 0 = nothing, 1 = fire, 2 = bomb sacks
	SpawnDuringDashMinWaitTime = {Default = 10, Bomb = 40},
	SpawnDuringDashMaxWaitTime = {Default = 30, Bomb = 50},
	DashLength = {Default = 100, Bomb = 150},

	CanSpawnFlamingSpiders = {Default = true, Bomb = false},

	ExplosionDamagePercent = {Default = 0.08, Bomb = 0.01},
	ExplosionDamagePercentNearDeath = {Default = 0.01, Bomb = 0.01},

	ExplodeOnDeath = {Default = false, Bomb = true},
	IgniteSacksOnDeath = {Default = false, Bomb = true}
}


--------------------
--RAGING LONG LEGS--
--------------------
do

StageAPI.AddBossToBaseFloorPool({BossID = "Raging Long Legs", Weight = 2}, LevelStage.STAGE1_1, StageType.STAGETYPE_AFTERBIRTH)

local function canOverlayPlay(sprite)
	if sprite:IsPlaying("Appear") or sprite:IsPlaying("CombustSpawn") or sprite:IsPlaying("Combust") or sprite:IsPlaying("BombExplode") or sprite:IsPlaying("BombExplode Dash") or sprite:IsPlaying("LayEgg") or sprite:IsPlaying("DashStart") or sprite:IsPlaying("DashEnd") or sprite:IsPlaying("Death") then
		return false
	end
	return true
end

local function amountRagingFires()
	local amountFires = 0
	for i, fire in ipairs(Isaac.FindByType(1000, EffectVariant.HOT_BOMB_FIRE, -1, false, false)) do
		if REVEL.GetData(fire).IsExtinguishableFire then
			amountFires = amountFires + 1
		end
	end
	return amountFires
end

local function killNearbySacks(npc, data, position, radius)
	position = position or npc.Position
	radius = radius or 30
	for i,ent in ipairs(Isaac.FindInRadius(position, radius, EntityPartition.ENEMY)) do
		if ent.Type == REVEL.ENT.BOMB_SACK.id and ent.Variant == REVEL.ENT.BOMB_SACK.variant and ent.HitPoints >= ent.MaxHitPoints and ent.FrameCount > 4 then
			local spiderCount = Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0

			local spawnSpiders = 1
			if spiderCount >= data.bal.SpiderLimit then
				spawnSpiders = math.random(0,1)
			end

			for i=1, spawnSpiders do
				EntityNPC.ThrowSpider(ent.Position, ent, ent.Position + RandomVector() * math.random(1, 40), false, 0)
			end

			ent:Kill()
		end
	end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant == REVEL.ENT.RAGING_LONG_LEGS.variant then
		local data, sprite, target = REVEL.GetData(npc), npc:GetSprite(), npc:GetPlayerTarget()

		if sprite:IsPlaying("Appear") then
			npc.Velocity = npc.Velocity * 0.8
		elseif sprite:IsPlaying("Death") or npc:IsDead() then
			sprite:RemoveOverlay()
			if data.StartedRagingDashSounds then
				data.StartedRagingDashSounds = false
				REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP)
				REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_END, 1, 0, false, 1)
			end
		else
			if not data.Init then
				sprite:PlayOverlay("LegsIdle", true)
				sprite:Play("HeadIdle", true)
				sprite:SetOverlayRenderPriority(true)

				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS

				data.LegsState = "Idle"
				data.HeadState = "Idle"
				data.Phase = 1

				data.IsChampion = REVEL.IsChampion(npc)

				--sets balance
				if data.IsChampion then
					data.bal = REVEL.GetBossBalance(raginglonglegsBalance, "Bomb")
				else
					data.bal = REVEL.GetBossBalance(raginglonglegsBalance, "Default")
				end

				--applies health multiplier
				npc.MaxHitPoints = npc.MaxHitPoints * data.bal.HealthMultiplier
				npc.HitPoints = npc.MaxHitPoints

				--applies anm2
				sprite:Load(data.bal.Animation, false)

				--applies spritesheet
				for layer=0, 3 do
					sprite:ReplaceSpritesheet(layer, data.bal.Spritesheets[data.Phase])
				end
				sprite:LoadGraphics()

				data.Init = true
			end

			REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

			if data.LegsState == "Idle" then
				-- sprite.FlipX = npc.Position.X > target.Position.X
				npc.Velocity = npc.Velocity * 0.8
				if data.HeadState ~= "Charge" then
					if not sprite:IsOverlayPlaying("LegsIdle") and canOverlayPlay(sprite) then
						sprite:PlayOverlay("LegsIdle", true)
					end
					if not data.IdleTimer then
						data.IdleTimer = 10
					end
					data.IdleTimer = data.IdleTimer - 1
					if data.IdleTimer <= 0 and (data.HeadState ~= "Attack" or data.Phase > 1) then
						data.LegsState = "Moving"
						if canOverlayPlay(sprite) then
							sprite:PlayOverlay("LegsMove" .. data.Phase, true)
						end
					end
				end
			elseif data.LegsState == "Moving" then
				-- sprite.FlipX = npc.Velocity.X > 0
				if not data.Path or (data.HeadState == "Attack" and data.Phase == 1) then
					data.IdleTimer = nil
					data.LegsState = "Idle"
					if canOverlayPlay(sprite) then
						sprite:PlayOverlay("LegsIdle", true)
					end
				else
					if not sprite:IsOverlayPlaying("LegsMove" .. data.Phase) and canOverlayPlay(sprite) then
						sprite:PlayOverlay("LegsMove" .. data.Phase, true)
					end
					local speedModifier = 1
					if target:ToPlayer() then
						speedModifier = target:ToPlayer().MoveSpeed
						if speedModifier > 1 then
							speedModifier = 1
						end
					end
                    local speed
                    if data.Phase > 1 then
                        speed = 0.7
                    else
                        speed = 0.5
                    end

                    speed = speed * speedModifier
					REVEL.FollowPath(npc, speed, data.Path, true, 0.9)
				end
			elseif data.LegsState == "Dash" then
				if (sprite:IsPlaying("DashStart") and sprite:WasEventTriggered("Dash")) or sprite:IsPlaying("DashLoop") or sprite:IsPlaying("ThrowSpiders Dash") or sprite:IsPlaying("ShootBlood Dash") or sprite:IsPlaying("SpawnTickingSpider Dash") or (sprite:IsPlaying("DashEnd") and not sprite:WasEventTriggered("Stop")) then
					if data.Path then
						local speedModifier = 1
						if target:ToPlayer() then
							speedModifier = target:ToPlayer().MoveSpeed
							if speedModifier > 1 then
								speedModifier = 1
							end
						end
						local speed = 0.9 * speedModifier
						REVEL.FollowPath(npc, speed, data.Path, true, 0.9)

						if not sprite:IsOverlayPlaying("LegsMove3") and canOverlayPlay(sprite) then
							sprite:PlayOverlay("LegsMove3", true)
						end

						if data.bal.SpawnDuringDash > 0 then
							if not data.DashFireCountdown then
								data.DashFireCountdown = math.random(data.bal.SpawnDuringDashMinWaitTime,data.bal.SpawnDuringDashMaxWaitTime)
							end
							data.DashFireCountdown = data.DashFireCountdown - 1

							if data.DashFireCountdown <= 0 then
								data.DashFireCountdown = nil

								if data.bal.SpawnDuringDash == 1 then
									REVEL.SpawnExtinguishableFire(Vector(npc.Position.X + math.random(-30,30), npc.Position.Y + math.random(-30,30)), (-npc.Velocity * 0.5) + RandomVector() * 2, npc, true)
								elseif data.bal.SpawnDuringDash == 2 then
									local bombSackCount = Isaac.CountEntities(nil, REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, -1) or 0
									if bombSackCount < data.bal.SackLimit or math.random(1,math.floor(bombSackCount*0.5)) == 1 then
										local spawnSubtype = 1
										if data.bal.SacksSpawnSpiders then
											spawnSubtype = 0
										end
										Isaac.Spawn(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, spawnSubtype, npc.Position, Vector.Zero, npc)
									end
								end
							end
						end

						killNearbySacks(npc, data, npc.Position + npc.Velocity, 50)
					else
						npc.Velocity = npc.Velocity * 0.8
						if not sprite:IsOverlayPlaying("LegsIdle") and canOverlayPlay(sprite) then
							sprite:PlayOverlay("LegsIdle", true)
						end
					end
				else
					npc.Velocity = npc.Velocity * 0.8
				end
				if sprite:IsEventTriggered("Dash") then
					if not data.StartedRagingDashSounds then
						REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_RAGE)
						REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_START, 1, 0, false, 1)
						REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP, 1, 0, true, 1)
						data.StartedRagingDashSounds = true
					end

					if data.Phase > 1 then
						for layer=0, 3 do
							sprite:ReplaceSpritesheet(layer, data.bal.Spritesheets[data.Phase])
						end
						sprite:LoadGraphics()
					end

					Isaac.Explode(npc.Position, npc, 1)
					for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
						if explosion.FrameCount <= 0 and npc.Position:Distance(explosion.Position) < 10 then
							explosion.SpawnerType = npc.Type
							explosion.SpawnerVariant = npc.Variant
						end
					end

					if data.bal.SpawnFiresAtDashStart then
						local fireCount = Isaac.CountEntities(npc, 1000,  EffectVariant.HOT_BOMB_FIRE, 1)
						for i=1, math.random(3,5) do
							REVEL.SpawnExtinguishableFire(npc.Position, Vector(math.random(5,12),0):Rotated(math.random(-180,180)), npc)
							if fireCount > data.bal.FireLimit then
								break
							else
								fireCount = fireCount + 1
							end
						end
					end
				end
				if sprite:IsFinished("DashStart") then
					sprite:Play("DashLoop", true)
					sprite:PlayOverlay("LegsMove3", true)
					data.HeadState = "Idle"
					data.AttackCountdown = nil
				end
				if data.Phase ~= 3 and sprite:IsPlaying("DashLoop") then
					if not data.DashCountdown then
						data.DashCountdown = data.bal.DashLength
					end
					data.DashCountdown = data.DashCountdown - 1
					if data.DashCountdown <= 0 then
						sprite:Play("DashEnd", true)
						sprite:RemoveOverlay()
					end
				end
				if sprite:IsEventTriggered("Stop") then
					data.StartedRagingDashSounds = false
					REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP)
					REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_END, 1, 0, false, 1)
				end
				if sprite:IsFinished("DashEnd") then
					data.LegsState = "Idle"
					if canOverlayPlay(sprite) then
						sprite:PlayOverlay("LegsIdle", true)
					end
				end
			end

			if data.LegsState ~= "Dash" or (data.Phase == 3 and not (sprite:IsPlaying("DashStart") or sprite:IsPlaying("DashEnd"))) then
				if data.HeadState == "Idle" then
					if data.LegsState == "Dash" then
						if not sprite:IsPlaying("DashLoop") then
							sprite:Play("DashLoop", true)
						end
					else
						if not sprite:IsPlaying("HeadIdle") then
							sprite:Play("HeadIdle", true)
						end
					end

					if not data.AttackCountdown then
                        data.AttackCountdown = math.random(90, 130)
                        if data.Phase == 2 then
                            data.AttackCountdown = data.AttackCountdown - 40
                        end
					end

                    if not data.Weights then
						data.Weights = {}

						if data.bal.AttackWeights[0] then
							data.Weights = REVEL.FillTable(data.Weights, data.bal.AttackWeights[0])
						end

						if data.bal.AttackWeights[data.Phase] then
							data.Weights = REVEL.FillTable(data.Weights, data.bal.AttackWeights[data.Phase])
						end
                    end

                    data.AttackCountdown = data.AttackCountdown - 1

                    if data.AttackCountdown <= 0 and (data.LegsState ~= "Dash" or data.Phase == 3) then
                        data.AttackCountdown = nil
                        local spiderCount = Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0
                        local tickingSpiderCount = Isaac.CountEntities(nil, EntityType.ENTITY_TICKING_SPIDER, -1, -1) or 0
                        local bombSackCount = Isaac.CountEntities(nil, REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, -1) or 0
                        local fireCount = amountRagingFires()
                        local spawnCount = (spiderCount * 0.75) + tickingSpiderCount + bombSackCount + (fireCount * 0.5)

                        local attacks = {
                            ThrowSpiders = data.Weights.ThrowSpiders,
                            SpawnTickingSpider = data.Weights.SpawnTickingSpider,
                            ShootBlood = data.Weights.ShootBlood,
                            Combust = data.Weights.Combust,
                            CombustSpawn = data.Weights.CombustSpawn,
                            BombExplode = data.Weights.BombExplode,
                            LayEgg = data.Weights.LayEgg
                        }

						if attacks.ThrowSpiders and attacks.ThrowSpiders > 0 then
							if spiderCount <= 1 then
								attacks.ThrowSpiders = attacks.ThrowSpiders + 1
							elseif spiderCount >= data.bal.SpiderLimit or spawnCount >= 10 then
								attacks.ThrowSpiders = 0
							elseif spiderCount >= math.ceil(data.bal.SpiderLimit/2) or spawnCount >= 6 then
								attacks.ThrowSpiders = attacks.ThrowSpiders - 1
							end
						end

						if attacks.SpawnTickingSpider and attacks.SpawnTickingSpider > 0 then
							if tickingSpiderCount == 0 then
								attacks.SpawnTickingSpider = attacks.SpawnTickingSpider + 1
							elseif tickingSpiderCount >= data.bal.TickingSpiderLimit or spawnCount >= 8 then
								attacks.SpawnTickingSpider = 0
							elseif tickingSpiderCount >= math.ceil(data.bal.TickingSpiderLimit/2) or spawnCount >= 4 then
								attacks.SpawnTickingSpider = attacks.SpawnTickingSpider - 1
							end
						end

                        if attacks.Combust and attacks.Combust > 0 then
                            if fireCount <= 5 then
                                attacks.Combust = attacks.Combust + 1
                            elseif fireCount >= 8 or spawnCount >= 12 then
                                attacks.Combust = attacks.Combust - 1
                            end
                        end

						if attacks.BombExplode and attacks.BombExplode > 0 then
                            if bombSackCount <= 0 then
                                attacks.BombExplode = 0
                            elseif bombSackCount >= 5 then
                                attacks.BombExplode = attacks.BombExplode + 2
                            elseif bombSackCount >= 3 then
                                attacks.BombExplode = attacks.BombExplode + 1
                            end
						end

						if attacks.LayEgg and attacks.LayEgg > 0 then
							if bombSackCount > data.bal.SackLimit then
								attacks.LayEgg = attacks.LayEgg - 2
							elseif bombSackCount <= 1 then
								attacks.LayEgg = attacks.LayEgg + 4
							elseif bombSackCount <= data.bal.SackLimit then
								attacks.LayEgg = attacks.LayEgg + 2
							end
						end

                        local attack = REVEL.WeightedRandom(attacks)
						if attack == nil then
							attack = "ShootBlood"
						end

						local isChargeAttack = attack == "Combust" or attack == "CombustSpawn" or attack == "BombExplode" or attack == "LayEgg"

                        if data.Weights[attack] then
                            if isChargeAttack and data.Weights[attack] > 4 then
                                data.Weights[attack] = data.Weights[attack] - 2
                            end

                            data.Weights[attack] = math.max(1, data.Weights[attack] - 1)
                        end

                        if not isChargeAttack then
                            data.HeadState = "Attack"
                            data.Attack = attack

                            local dash = ""
                            if data.LegsState == "Dash" then
                                dash = " Dash"
                            end
                            sprite:Play(attack .. dash, true)
                        else
                            data.HeadState = "Charge"
                            data.LegsState = "Idle"
                            data.Attack = attack

                            local dash = ""
                            if data.Phase == 3 then
                                dash = " Dash"
                            end
                            sprite:Play(attack .. dash, true)
                            sprite:RemoveOverlay()

                            data.IdleTimer = nil
                            npc.Velocity = Vector.Zero

							if data.Attack ~= "LayEgg" then
								REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_RAGE, 1, 0, false, 1)
							end

							if data.Attack == "BombExplode" then
								REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_LAND, 1, 0, false, 1)
								for _, bombSack in ipairs(Isaac.FindByType(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, -1, false, true)) do
									bombSack = bombSack:ToNPC()
									local sackData, sackSprite = REVEL.GetData(bombSack), bombSack:GetSprite()
									if not sackData.Ignited and not sackData.Exploded then
										-- REVEL.sfx:NpcPlay(bombSack, SoundEffect.SOUND_FETUS_LAND, 0.5, 0, false, 1)
										sackData.Ignited = true
									end
								end
							end
                        end
                    end
				elseif data.HeadState == "Attack" then
					if sprite:IsEventTriggered("Spawn") then
						if data.Attack == "SpawnTickingSpider" then -- SpawnTickingSpider
							REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_GURGLE, 1, 0, false, 1.2)
							local tickingSpider = Isaac.Spawn(EntityType.ENTITY_TICKING_SPIDER, 0, 0, npc.Position, Vector.Zero, npc)
							tickingSpider:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            if data.LegsState == "Dash" and data.bal.CanSpawnFlamingSpiders then
                                REVEL.GetData(tickingSpider).IsFlamingSpider = true
                            end
						else -- ThrowSpiders
							REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1.2)
							for i=1, 2 do
								EntityNPC.ThrowSpider(npc.Position, npc, target.Position + RandomVector() * math.random(1, 40), false, 10)
							end

                            if data.LegsState == "Dash" and data.bal.CanSpawnFlamingSpiders then
                                for _, spider in ipairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, true)) do
                                    if spider.FrameCount <= 1 then
                                        if spider.SpawnerType == npc.Type and spider.SpawnerVariant == npc.Variant then --SpawnerEntity is nil even though i provided the spawner in the throwspider function above, ugh
                                            REVEL.GetData(spider).IsFlamingSpider = true
                                        end
                                    end
                                end
                            end
						end
					end

					if sprite:IsEventTriggered("Shoot") then -- ShootBlood
						REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 1)
						npc:FireProjectiles(npc.Position, Vector(10,0), 8, ProjectileParams())
					end

					local dash = ""
					if data.LegsState == "Dash" then
						dash = " Dash"
					end
					if sprite:IsFinished(data.Attack .. dash) then
						data.HeadState = "Idle"
						if data.LegsState == "Dash" then
							sprite:Play("DashLoop", true)
						else
							sprite:Play("HeadIdle", true)
						end
					end
				elseif data.HeadState == "Charge" then
					if sprite:IsEventTriggered("Spawn") then -- CombustSpawn
						REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_RAGE)
						if data.Phase < 3 then
							REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP, 1, 0, false, 1)
						end
						REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1.2)

						for i=1, 3 do
							EntityNPC.ThrowSpider(npc.Position, npc, target.Position + RandomVector() * math.random(1, 40), false, 10)
						end

						if data.bal.CanSpawnFlamingSpiders then
							for _, spider in ipairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, true)) do
								if spider.FrameCount <= 1 then
									if spider.SpawnerType == npc.Type and spider.SpawnerVariant == npc.Variant then --SpawnerEntity is nil even though i provided the spawner in the throwspider function above, ugh
										REVEL.GetData(spider).IsFlamingSpider = true
									end
								end
							end
						end
					end

					if sprite:IsEventTriggered("Lay") then -- LayEgg
						REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SPIDER_COUGH, 1, 0, false, 1)

						local spawnSubtype = 1
						if data.bal.SacksSpawnSpiders then
							spawnSubtype = 0
						end
						local bombSack = Isaac.Spawn(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, spawnSubtype, npc.Position, Vector.Zero, npc)
						bombSack:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

						bombSack.HitPoints = bombSack.MaxHitPoints
					end

					if sprite:IsEventTriggered("Explode") then
						Isaac.Explode(npc.Position, npc, 1)
						for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
							if explosion.FrameCount <= 0 and npc.Position:Distance(explosion.Position) < 10 then
								explosion.SpawnerType = npc.Type
								explosion.SpawnerVariant = npc.Variant
							end
						end

						if data.Attack == "BombExplode" then -- BombExplode
							--[[
							for _, bombSack in ipairs(Isaac.FindByType(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, -1, false, true)) do
								bombSack:Kill()
								Isaac.Explode(bombSack.Position, bombSack, 1)
							end
							]]
						else -- Combust
							local fireCount = Isaac.CountEntities(npc, 1000,  EffectVariant.HOT_BOMB_FIRE, 1)
							for i=1, math.random(5,7) do
								REVEL.SpawnExtinguishableFire(npc.Position, Vector(math.random(5,12),0):Rotated(math.random(-180,180)), npc)
								if fireCount > data.bal.FireLimit then
									break
								else
									fireCount = fireCount + 1
								end
							end
						end
					end

					if (sprite:IsEventTriggered("Stop") or sprite:IsEventTriggered("Explode")) then
						REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_RAGE)
						if data.Phase < 3 then
							REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP)
							REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_END, 1, 0, false, 1)
						end
					end

					local dash = ""
					if data.Phase == 3 then
						dash = " Dash"
					end
					if sprite:IsFinished(data.Attack .. dash) then
						data.HeadState = "Idle"
						if data.Phase < 3 then
							sprite:Play("HeadIdle", true)
							sprite:PlayOverlay("LegsIdle", true)
						else
							data.LegsState = "Dash"
							sprite:Play("DashLoop", true)
						end
					end
				end
			end

			if (data.Phase < 3 and npc.HitPoints <= npc.MaxHitPoints * 0.25) or (data.Phase < 2 and npc.HitPoints <= npc.MaxHitPoints * 0.75) then
				data.Phase = data.Phase + 1
                data.Weights = nil
				data.LegsState = "Dash"
				sprite:Play("DashStart", true)
				sprite:RemoveOverlay()
				REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_RAGE, 1, 0, false, 1)
			end
		end

		if sprite:IsEventTriggered("Dust") then
			local origVelocity = Vector(10,0)
			for i=1, 12 do
				local velocity = origVelocity:Resized(math.random(500,800)*0.01)
				velocity = velocity:Rotated(30*i)
				local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, npc.Position, velocity, npc)
				dust.SpriteOffset = Vector(0,-40)
				dust.SpriteScale = Vector(1,1) * (math.random(100,150)*0.01)
				local extraUpdates = math.random(0,2)
				if extraUpdates > 0 then
					for i=1, extraUpdates do
						dust:Update()
					end
				end
			end
		end

		if npc.FrameCount%5 == 0 then
			if sprite:IsPlaying("DashLoop")
			or sprite:IsPlaying("ThrowSpiders Dash")
			or sprite:IsPlaying("ShootBlood Dash")
			or sprite:IsPlaying("SpawnTickingSpider Dash") then
				for i=1, 2 do
					if math.random(1,2) == 1 then
						local steam = REVEL.SpawnDecoration(npc.Position + Vector(math.random(-35, 35), 0), npc.Velocity * 0.9, "Steam" .. math.random(1,3), "gfx/effects/revelcommon/steam.anm2", nil, 30)
						steam.SpriteOffset = Vector(0,math.random(-55,-25))
					end
				end
			end
		end
	end
end, REVEL.ENT.RAGING_LONG_LEGS.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
	if ent.Variant == REVEL.ENT.RAGING_LONG_LEGS.variant and not REVEL.game:IsPaused() and ent:IsDead() then
		local origVelocity = Vector(10,0)
		for i=1, 12 do
			local velocity = origVelocity:Resized(math.random(500,800)*0.01)
			velocity = velocity:Rotated(30*i)
			local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, ent.Position, velocity, ent)
			dust.SpriteOffset = Vector(0,-10)
			dust.SpriteScale = Vector(1,1) * (math.random(100,150)*0.01)
			local extraUpdates = math.random(0,2)
			if extraUpdates > 0 then
				for i=1, extraUpdates do
					dust:Update()
				end
			end
		end
	end
end, REVEL.ENT.RAGING_LONG_LEGS.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source)
	if ent.Variant == REVEL.ENT.RAGING_LONG_LEGS.variant then
		local data = REVEL.GetData(ent)

		if source and source.Type == 1000 and source.Variant == EffectVariant.HOT_BOMB_FIRE then
			for i, fire in ipairs(Isaac.FindByType(1000, EffectVariant.HOT_BOMB_FIRE, -1, false, false)) do
				if GetPtrHash(source.Entity) == GetPtrHash(fire) then
					local fireData = REVEL.GetData(fire)
					if fireData.IsExtinguishableFire then
						return false
					end
				end
			end
		end

		if data.bal.ExplosionDamagePercent or (data.bal.ExplosionDamagePercentNearDeath and data.Phase == 3) then
			local explosionDamagePercent = data.bal.ExplosionDamagePercent
			if data.bal.ExplosionDamagePercentNearDeath and data.Phase == 3 then
				explosionDamagePercent = data.bal.ExplosionDamagePercentNearDeath
			end
			if HasBit(flags, DamageFlag.DAMAGE_EXPLOSION) 
			and (not source or (
				source and source.Type ~= EntityType.ENTITY_BOMBDROP and source.Type ~= EntityType.ENTITY_PLAYER
				and not REVEL.GetPlayerFromDmgSrc(source)
			))
			then
				ent.HitPoints = ent.HitPoints + amount - (ent.MaxHitPoints * explosionDamagePercent)
			end
		end

		if ent.HitPoints - amount - REVEL.GetDamageBuffer(ent) <= 0 and not data.DidDeathEffects then
			if data.bal.ExplodeOnDeath then
				REVEL.DelayFunction(function()
					Isaac.Explode(ent.Position, ent, 1)
					for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
						if explosion.FrameCount <= 0 and ent.Position:Distance(explosion.Position) < 10 then
							explosion.SpawnerType = ent.Type
							explosion.SpawnerVariant = ent.Variant
						end
					end
				end, 42, nil, true)
			end

			if data.bal.IgniteSacksOnDeath then
				for _, bombSack in ipairs(Isaac.FindByType(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, -1, false, true)) do
					bombSack = bombSack:ToNPC()
					local sackData, sackSprite = REVEL.GetData(bombSack), bombSack:GetSprite()
					if not sackData.Ignited and not sackData.Exploded then
						REVEL.sfx:NpcPlay(bombSack, SoundEffect.SOUND_FETUS_LAND, 0.5, 0, false, 1)
						sackData.Ignited = true
					end
				end
			end

			data.DidDeathEffects = true
		end
	end
end, REVEL.ENT.RAGING_LONG_LEGS.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	if npc.Variant == REVEL.ENT.RAGING_LONG_LEGS.variant then
		local data, sprite = REVEL.GetData(npc), npc:GetSprite()

		sprite:RemoveOverlay()
		if data.StartedRagingDashSounds then
			data.StartedRagingDashSounds = false
			REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP)
			REVEL.sfx:NpcPlay(npc, REVEL.SFX.RAGING_LONG_LEGS_DASH_END, 1, 0, false, 1)
		end

		REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_RAGE)
	end
end, REVEL.ENT.RAGING_LONG_LEGS.id)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_LOOP)
	REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_DASH_END)
	REVEL.sfx:Stop(REVEL.SFX.RAGING_LONG_LEGS_RAGE)
end)

end


---------
--FIRES--
---------
do

function REVEL.SpawnExtinguishableFire(position, velocity, spawner, fastFade, size, fire)
	size = size or 5
	fire = fire or Isaac.Spawn(1000, EffectVariant.HOT_BOMB_FIRE, 1, position, velocity, spawner):ToEffect()
	local fireData = REVEL.GetData(fire)
	fireData.IsExtinguishableFire = true
	fireData.FastFadeFire = fastFade
	fireData.FireSize = size
	return fire
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect)
    local data = REVEL.GetData(effect)
	if data.IsExtinguishableFire and effect.FrameCount <= 7 and REVEL.IsRenderPassNormal() then
		data.RenderedFrameCount = data.RenderedFrameCount or 0
		data.FireSize = data.FireSize or 5

        if effect.FrameCount > data.RenderedFrameCount then
            data.RenderedFrameCount = data.RenderedFrameCount + 0.5
			local spawnSize = Vector(0.2, 0.2)
			local fullSize = Vector(0.25, 0.25) * data.FireSize
			local normalSize = Vector(0.2, 0.2) * data.FireSize
            if data.RenderedFrameCount <= 4 then
                effect.SpriteScale = REVEL.Lerp(spawnSize, fullSize, data.RenderedFrameCount / 4)
            else
                effect.SpriteScale = REVEL.Lerp(fullSize, normalSize, (data.RenderedFrameCount - 4) / 3)
            end
        end
    end
end, EffectVariant.HOT_BOMB_FIRE)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	local data = REVEL.GetData(effect)
	if data.IsExtinguishableFire then
		effect.Velocity = effect.Velocity * 0.95
		if not data.Init then
			effect.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			--effect:GetSprite():Load("gfx/033.010_movable fireplace.anm2", true)
			--effect:GetSprite():Play("Idle")
			data.FireSize = data.FireSize or 5
			data.Init = true
		end

		local fireSlowFadeStart = 30
		local fireFastFadeStart = 200
		local fireSlowFadeDelay = 10
		local fireSlowFadeChance = 10
		local fireFastFadeDelay = 5
		local fireFastFadeChance = 2

		if data.FastFadeFire then
			fireSlowFadeStart = 20
			fireFastFadeStart = 120
			fireSlowFadeDelay = 8
			fireSlowFadeChance = 8
			fireFastFadeDelay = 4
		end

		data.takeDamageCooldown = 0

		local triggerFireDamage = false
		local triggerFireKill = false

		if data.takeDamageCooldown > 0 then
			data.takeDamageCooldown = data.takeDamageCooldown - 1
		else
			--tear damage
			for i,tear in ipairs(Isaac.FindByType(EntityType.ENTITY_TEAR, -1, -1, true)) do
				if effect.Position:Distance(tear.Position) < tear.Size + effect.Size then
					data.takeDamageCooldown = 4
					triggerFireDamage = true
					---@type EntityTear
					tear = tear:ToTear()
					if not tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) and not tear:HasTearFlags(TearFlags.TEAR_PIERCING) then
						tear:Die()
					end
				end
			end

			--laser damage
			for _, laser in ipairs(Isaac.FindByType(EntityType.ENTITY_LASER, -1, -1, false, false)) do
				if REVEL.CollidesWithLaser(effect.Position, laser:ToLaser(), laser.Size + effect.Size) then
					data.takeDamageCooldown = 4
					triggerFireDamage = true
				end
			end

			--knife damage
			for _, knife in ipairs(Isaac.FindByType(EntityType.ENTITY_KNIFE, -1, -1, false, false)) do
				local knifeSprite = knife:GetSprite()
				if knife.Variant < 1 or knifeSprite:IsPlaying("Spin") then
					if effect.Position:Distance(knife.Position) < knife.Size + effect.Size then
						data.takeDamageCooldown = 2
						triggerFireDamage = true
					end
				elseif knife.SubType == 4 then --handle forgotten bone swing
					if knife.FrameCount > 1 and knife.FrameCount < 9 and knife.Parent then
						local parent = knife.Parent
						if parent:ToPlayer() then
							local player = parent:ToPlayer()

							--find the center of the swing object
							---@type EntityKnife
							knife = knife:ToKnife()
							local position = knife.Position
							local scale = 30
							if knife.Variant == 2 then --knife + bone
								scale = 42
							end
							scale = scale * knife.SpriteScale.X
							local offset = Vector(scale,0)
							offset = offset:Rotated(knife.Rotation)
							position = position + offset

							--envy enmity is inside the swipe
							if (position - effect.Position):Length() < effect.Size + scale then
								triggerFireDamage = true
								triggerFireKill = true
							end
						end
					end
				end
			end

			--explosion damage
			for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
				if explosion.FrameCount == 1 and effect.Position:Distance(explosion.Position) < 100 + effect.Size
				and explosion.SpawnerType ~= REVEL.ENT.RAGING_LONG_LEGS.id and explosion.SpawnerVariant ~= REVEL.ENT.RAGING_LONG_LEGS.variant then
					triggerFireDamage = true
					triggerFireKill = true
				end
			end
		end

		if triggerFireDamage then
			if math.random(1,2) == 1 then
				data.FireSize = data.FireSize - 1
			end
			if math.random(1,5) == 1 then
				data.FireSize = data.FireSize - 1
			end
		end

		if (effect.FrameCount > fireFastFadeStart and (effect.FrameCount % fireFastFadeDelay == 2 and math.random(1,fireFastFadeChance) == 1))
		or (effect.FrameCount > fireSlowFadeStart and (effect.FrameCount % fireSlowFadeDelay == 2 and math.random(1,fireSlowFadeChance) == 1)) then
			data.FireSize = data.FireSize - 1
		end

		if data.FireSize <= 0 then
			triggerFireKill = true
		end

		if data.FireSize > 1 then
			--player damage
			for i,player in ipairs(REVEL.players) do
				if effect.Position:Distance(player.Position) < 4*data.FireSize then
					player:TakeDamage(1,DamageFlag.DAMAGE_FIRE,EntityRef(effect),0)
				end
			end
		end

		if effect.FrameCount > 7 then
			effect.SpriteScale = Vector(0.2,0.2) * data.FireSize
			effect.Size = math.max(5, (data.FireSize * 4) - 2)
		end
		if triggerFireKill then
			REVEL.SpawnDecoration(effect.Position, Vector.Zero, "Idle", "gfx/effects/revel2/fire_poof.anm2", effect, 20)
			REVEL.sfx:Play(SoundEffect.SOUND_STEAM_HALFSEC, 0.75, 0, false, 1)
			effect:Remove()
		end
	end
end, EffectVariant.HOT_BOMB_FIRE)

end


-------------------
--FLAMING SPIDERS--
-------------------
do

local flamableSpiders = {
	EntityType.ENTITY_SPIDER,
	EntityType.ENTITY_BIGSPIDER,
	EntityType.ENTITY_TICKING_SPIDER,
	EntityType.ENTITY_SPIDER_L2,
}

local BurningStatusSprite = REVEL.LazyLoadRoomSprite{
	ID = "rllBurnStatus",
	Anm2 = "gfx/statuseffects.anm2",
	Animation = "Burning",
}

local LastBurningStatusUpdateFrame = -1

local function flamingSpiderRender(_, npc, offset)
	local data, sprite = REVEL.GetData(npc), npc:GetSprite()
	if data.IsFlamingSpider then
		if npc.Visible then
			if LastBurningStatusUpdateFrame ~= REVEL.game:GetFrameCount() then
				BurningStatusSprite:Update()
				LastBurningStatusUpdateFrame = REVEL.game:GetFrameCount()
			end
			BurningStatusSprite:Render(Isaac.WorldToScreen((npc.Position - Vector(0,-46)) + Vector(0, npc.Size * -5)) + offset, Vector.Zero, Vector.Zero)
			if REVEL.IsRenderPassNormal() then
				local fireColors = {}
				fireColors[1] = Color(1,1,0.8,1,conv255ToFloat(45,0,0))
				fireColors[2] = Color(1,1,0.6,1,conv255ToFloat(90,0,0))
				fireColors[3] = Color(1,1,0.8,1,conv255ToFloat(70,25,0))
				fireColors[4] = Color(1,1,0.8,1,conv255ToFloat(50,50,0))
				fireColors[5] = Color(1,1,0.8,1,conv255ToFloat(25,25,0))
				sprite.Color = fireColors[npc.FrameCount%6] or Color(1,1,1,1,conv255ToFloat(0,0,0))
			end
		end
    end
end
for i=1, #flamableSpiders do
	revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, flamingSpiderRender, flamableSpiders[i])
end

local function flamingSpiderUpdate(_, npc)
	local data, sprite = REVEL.GetData(npc), npc:GetSprite()
	if not data.FlamingSpiderInit then
		local currentRoom = StageAPI.GetCurrentRoom()
		if currentRoom and currentRoom.Metadata:Has{Index = REVEL.room:GetGridIndex(npc.Position), Name = "ExtinguishableFire"} then
			data.IsFlamingSpider = true
		end
		if data.IsFlamingSpider then
			npc.MaxHitPoints = npc.MaxHitPoints*0.5
			npc.HitPoints = npc.MaxHitPoints
		end

		data.FlamingSpiderInit = true
	end
	if data.IsFlamingSpider then
		if npc.Velocity:Length() > 1 then
			if sprite:IsPlaying("Walk") then
				npc.Velocity = npc.Velocity * 1.2
			else
				npc.Velocity = npc.Velocity * 0.9
			end
		end

		if npc.FrameCount % 60 == 50 then
			npc:TakeDamage(3, 0, EntityRef(npc), 0)
		end

		if npc.Type == EntityType.ENTITY_TICKING_SPIDER and not data.InAir then
			if not (sprite:IsPlaying("Jump") and sprite:IsPlaying("InAir")) and npc.HitPoints <= npc.MaxHitPoints * 0.3 then
				local target = npc:GetPlayerTarget()
				data.InAir = true
				npc.Velocity = ((target.Position + (target.Velocity * 2)) - npc.Position):Normalized() * 10
				sprite:Play("Jump", true)
			end
		end
	end
end
for i=1, #flamableSpiders do
	revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, flamingSpiderUpdate, flamableSpiders[i])
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	local data, sprite = REVEL.GetData(npc), npc:GetSprite()
	if data.IsFlamingSpider and data.InAir then
		if sprite:WasEventTriggered("Land") then
			npc:Kill()
		end
		return true
	end
end, EntityType.ENTITY_TICKING_SPIDER)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
	local data = REVEL.GetData(entity)
	if data.IsFlamingSpider then
		if data.InAir then
			Isaac.Explode(entity.Position, entity, 1)
		end
		local fire = REVEL.SpawnExtinguishableFire(entity.Position, Vector.Zero, entity)
	end
end, EntityType.ENTITY_TICKING_SPIDER)

local function burnSpiderFromDamage(_, entity, amount, flags, source)
	local data = REVEL.GetData(entity)
	if not data.IsFlamingSpider then
		if source and source.Type == 1000 and source.Variant == EffectVariant.HOT_BOMB_FIRE then
			for i, fire in ipairs(Isaac.FindByType(1000, EffectVariant.HOT_BOMB_FIRE, -1, false, false)) do
				--[[
				if GetPtrHash(source.Entity) == GetPtrHash(fire) then
					local fireData = REVEL.GetData(fire)
					if fireData.IsExtinguishableFire then
					]]
						fire:Remove()
						data.IsFlamingSpider = true
						return false
					--[[
					end
				end
				]]
			end
		end
	elseif HasBit(flags, DamageFlag.DAMAGE_FIRE) then
		return false
	end
end
for i=1, #flamableSpiders do
	revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, burnSpiderFromDamage, flamableSpiders[i])
end

end


-------------
--BOMB SACK--
-------------
do

local function isClearExceptBombSacksAndSpiders()
	local isClearExceptBombSacksAndSpiders = true

	for i, entity in pairs(REVEL.roomNPCs) do
		if isClearExceptBombSacksAndSpiders 
		and REVEL.CanShutDoors(entity) 
		and entity.Type ~= REVEL.ENT.BOMB_SACK.id 
		and entity.Type ~= EntityType.ENTITY_SPIDER then
			isClearExceptBombSacksAndSpiders = false
		end
	end

	return isClearExceptBombSacksAndSpiders
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	if npc.Variant == REVEL.ENT.BOMB_SACK.variant then
		local data = REVEL.GetData(npc)

		if not data.SpiderLimit then
			if npc.SubType == 1 then
				data.SpiderLimit = 0
			else
				data.SpiderLimit = REVEL.GetBossBalance(raginglonglegsBalance, "Bomb").SpiderLimit
			end
		end

		local spiderCount = Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0
		if npc.State == NpcState.STATE_ATTACK and (spiderCount >= data.SpiderLimit or data.Ignited or data.Exploded or isClearExceptBombSacksAndSpiders()) then
			npc.State = NpcState.STATE_IDLE
			return true
		end
	end
end, REVEL.ENT.BOMB_SACK.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	if npc.Variant == REVEL.ENT.BOMB_SACK.variant then
		local data, sprite = REVEL.GetData(npc), npc:GetSprite()

		if not data.Init then
			data.NoBrotherOrbit = true
			data.Init = true
		end

		if not data.LastHitPoints then
			data.LastHitPoints = npc.HitPoints
		end

		if npc.HitPoints > data.LastHitPoints and npc.HitPoints < npc.MaxHitPoints then
			local healthAdded = npc.HitPoints - data.LastHitPoints
			npc.HitPoints = npc.HitPoints - (healthAdded/2)
		end

		if not data.Ignited and not data.Exploded then
			if npc:HasEntityFlags(EntityFlag.FLAG_BURN) then
				data.Ignited = true
			end
		end

		if data.Ignited and not data.Exploded then
			if not data.IgnitedFrame then
				data.IgnitedFrame = ((sprite:GetFrame()*4)-1) + math.random(0,10)
			end
			if data.IgnitedFrame >= 59 then
				Isaac.Explode(npc.Position, npc, 1)
				data.Ignited = false
				data.Exploded = true
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			else
				data.IgnitedFrame = data.IgnitedFrame + 1
			end
			npc.HitPoints = npc.MaxHitPoints - math.floor(math.min(data.IgnitedFrame*0.25, npc.MaxHitPoints - 5))
			sprite:SetFrame("Pulse", data.IgnitedFrame)
		end

		if data.Exploded then
			if not data.ExplodedFrame then
				data.ExplodedFrame = -1
			end
			if data.ExplodedFrame >= 5 then
				npc:Remove()
			else
				data.ExplodedFrame = data.ExplodedFrame + 1
			end
			sprite:SetFrame("Explode", data.ExplodedFrame)
		end

		data.LastHitPoints = npc.HitPoints
	end
end, REVEL.ENT.BOMB_SACK.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source)
	local data = REVEL.GetData(entity)
	if not data.Ignited and not data.Exploded then
		if source and source.Type == 1000 and source.Variant == EffectVariant.HOT_BOMB_FIRE then
			for i, fire in ipairs(Isaac.FindByType(1000, EffectVariant.HOT_BOMB_FIRE, -1, false, false)) do
				fire:Remove()
				data.Ignited = true
				return false
			end
		elseif HasBit(flags, DamageFlag.DAMAGE_FIRE) then
			data.Ignited = true
			return false
		end
	end
end, REVEL.ENT.BOMB_SACK.id)

revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, collider)
	if collider then
		local data = REVEL.GetData(npc)
		if not data.Ignited and not data.Exploded then
			if REVEL.GetData(collider).IsFlamingSpider then
				data.Ignited = true
			elseif collider:HasEntityFlags(EntityFlag.FLAG_BURN) then
				data.Ignited = true
			elseif collider.Type == EntityType.ENTITY_FIREPLACE then
				data.Ignited = true
			elseif collider.Type == EntityType.ENTITY_FLAMINGHOPPER then
				data.Ignited = true
			elseif (collider.Type == EntityType.ENTITY_GAPER or collider.Type == EntityType.ENTITY_FATTY or collider.Type == EntityType.ENTITY_SKINNY) and collider.Variant == 2 then
				data.Ignited = true
			end
		end
	end
end, REVEL.ENT.BOMB_SACK.id)

end


--temporary custom spawns
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, velocity, spawner, seed)
	if type == 1000 and variant == EffectVariant.HOT_BOMB_FIRE then
		local deleteMe = false
		if subtype == 178 then
			REVEL.SpawnExtinguishableFire(pos, velocity, spawner)
			deleteMe = true
		elseif subtype == 179 then
			local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, pos, velocity, spawner)
			REVEL.GetData(spider).IsFlamingSpider = true
			deleteMe = true
		elseif subtype == 180 then
			local spider = Isaac.Spawn(EntityType.ENTITY_BIGSPIDER, 0, 0, pos, velocity, spawner)
			REVEL.GetData(spider).IsFlamingSpider = true
			deleteMe = true
		elseif subtype == 181 then
			local spider = Isaac.Spawn(EntityType.ENTITY_TICKING_SPIDER, 0, 0, pos, velocity, spawner)
			REVEL.GetData(spider).IsFlamingSpider = true
			deleteMe = true
		elseif subtype == 182 then
			local spider = Isaac.Spawn(EntityType.ENTITY_SPIDER_L2, 0, 0, pos, velocity, spawner)
			REVEL.GetData(spider).IsFlamingSpider = true
			deleteMe = true
		elseif subtype == 183 then
			local sack = Isaac.Spawn(REVEL.ENT.BOMB_SACK.id, REVEL.ENT.BOMB_SACK.variant, 1, pos, velocity, spawner)
			sack:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			sack.HitPoints = sack.MaxHitPoints
			REVEL.GetData(sack).Ignited = true
			deleteMe = true
		end
		if deleteMe then
			return {StageAPI.E.DeleteMeEffect.T, StageAPI.E.DeleteMeEffect.V, 0, seed}
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
	if REVEL.room:GetType() == RoomType.ROOM_BOSSRUSH then
        local rng = npc:GetDropRNG()
        if rng:RandomFloat() > 0.5 then
            local champion = npc.SubType > 0
            npc:Morph(REVEL.ENT.RAGING_LONG_LEGS.id, REVEL.ENT.RAGING_LONG_LEGS.variant, 0, -1)
            if champion then
                REVEL.GetData(npc).IsChampion = true
            end
        end
	end
end, EntityType.ENTITY_WIDOW)

end