local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"
return function()

-----------------
-- YELLOW SNOW --
-----------------

do
	local EndingTaperStart = 20
	local BuildUpTime = 20
	local MinFireDelay = 3
	local MaxFireDelay = 5
	local PlayerAlignment = 75
    local PlayerAlignmentTrigger = 25
	REVEL.PissColor = Color(1, 1, 0, 1,conv255ToFloat( math.floor(0.175 * 255), math.floor(0.06 * 255), 0))
    local BloodColor = Color(1, 2, 1, 1,conv255ToFloat( 90, 200, 0))

    local function GetYellowSnowTargets()
        local yellowSnows = Isaac.FindByType(REVEL.ENT.YELLOW_SNOW.id, REVEL.ENT.YELLOW_SNOW.variant, -1, false, false)
        local checkedIndicesByID = {}
        local targetSets = {}
        for _, yellowSnow in ipairs(yellowSnows) do
            local data = REVEL.GetData(yellowSnow)
            if data.PathID and data.TargetIndex and data.TargetIndices and (not checkedIndicesByID[data.PathID] or not checkedIndicesByID[data.PathID][data.TargetIndex]) then
                if not checkedIndicesByID[data.PathID] then
                    checkedIndicesByID[data.PathID] = {}
                end

                targetSets[#targetSets + 1] = {Targets = data.TargetIndices, ID = data.PathID}
                checkedIndicesByID[data.PathID][data.TargetIndex] = true
            end
        end

        return targetSets
    end

    local function YellowSnowPathUpdate(map)
        local yellowSnows = Isaac.FindByType(REVEL.ENT.YELLOW_SNOW.id, REVEL.ENT.YELLOW_SNOW.variant, -1, false, false)
        for _, yellowSnow in ipairs(yellowSnows) do
            for _, set in ipairs(map.TargetMapSets) do
                if REVEL.GetData(yellowSnow).PathID == set.ID then
                    REVEL.GetData(yellowSnow).Path = REVEL.GetPathToZero(REVEL.room:GetGridIndex(yellowSnow.Position), set.Map, nil, map)
                    REVEL.GetData(yellowSnow).PathIndex = nil
                end
            end
        end
    end

    local NpcPathMap = REVEL.NewPathMapFromTable("YellowSnow", {
        GetTargetSets = GetYellowSnowTargets,
        GetInverseCollisions = REVEL.GenericChaserPathMap.GetInverseCollisions,
        OnPathUpdate = YellowSnowPathUpdate
    })

    local function yellowSnow_NpcUpdate(_, npc)
        if npc.Variant ~= REVEL.ENT.YELLOW_SNOW.variant or npc.State == NpcState.STATE_APPEAR then
            return
        end

        local target, data, sprite = npc:GetPlayerTarget(), REVEL.GetData(npc), npc:GetSprite()
        local targetIndex = REVEL.room:GetGridIndex(target.Position)

        if not data.Init then
            REVEL.UsePathMap(NpcPathMap, npc)

            data.State = "Idle"
            data.Init = true
        end

        npc.SplatColor = BloodColor

        if data.State == "Idle" then
            data.PathID = "YellowSnow"
            if data.TargetIndex ~= targetIndex or data.RecalculatePath then
                data.TargetIndex = targetIndex
                data.TargetIndices = REVEL.GetAdjacentIndices(targetIndex, 5, true, nil, nil, 2)
            end
        else
            if data.TargetIndex ~= targetIndex or data.RecalculatePath then
                local dir = data.ShootDirectionName
                data.TargetIndex = targetIndex
                data.TargetIndices = REVEL.GetAdjacentIndices(targetIndex, 5, true, nil, nil, 2,
                    dir == "Right",
                    dir == "Left",
                    dir == "Down",
                    dir == "Up"
                )

                data.PathID = "YellowSnow" .. dir
            end
        end

        data.RecalculatePath = nil

        if npc.FrameCount % 10 == 0 then
            REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
        end

        if data.State == "Idle" then
            local facing, alignAmount = REVEL.GetAlignment(npc.Position, target.Position)
            if (data.Path and REVEL.room:GetGridIndex(npc.Position) == data.Path[#data.Path]) or (alignAmount < PlayerAlignmentTrigger and npc.Position:Distance(target.Position) < 150) then
                data.RecalculatePath = true
                data.State = "Shoot"
                data.ShootDirectionName = facing
                data.ShootDirection = REVEL.dirStringToVector[data.ShootDirectionName]
				data.ShootTimer = math.random(90, 120)
				data.BuildUp = 0
				data.FireDelay = 0
				data.Distance = npc.Position:Distance(target.Position)
                sprite.FlipX = data.ShootDirectionName == "Left"
				sprite:Play("ShootStart", true)
            else
                if data.Path then
                    if sprite:WasEventTriggered("MoveStart") and not sprite:WasEventTriggered("MoveEnd") then
        				REVEL.FollowPath(npc, 1.5, data.Path, false)
                    else
                        npc.Velocity = npc.Velocity * 0.9
                    end

                    if sprite:IsEventTriggered("MoveStart") then
                        REVEL.sfx:NpcPlay(npc, REVEL.SFX.YELLOWSNOW_CRAWL, 0.35, 0, false, 0.9 + math.random() * 0.2)
                    end
                    REVEL.AnimateWalkFrame(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"}, false)
                else
                    npc.Velocity = npc.Velocity * 0.9
                    if not sprite:IsPlaying("Idle") then
                        sprite:Play("Idle", true)
                    end
                end
            end
        elseif data.State == "Shoot" then
            if sprite:IsEventTriggered("Stop") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.YELLOWSNOW_RELIEF, 0.65, 0, false, 1)
            end

            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_LITTLE_SPIT, 0.6, 0, false, 1)
            end

            if (sprite:IsEventTriggered("Shoot") or sprite:IsPlaying("ShootLoop")) and data.Path and REVEL.room:GetGridIndex(npc.Position) ~= data.Path[#data.Path] then
                REVEL.FollowPath(npc, 0.5, data.Path, false)
            else
                npc.Velocity = npc.Velocity * 0.9
            end

			if sprite:IsEventTriggered("Shoot") or sprite:IsPlaying("ShootLoop") or (sprite:IsPlaying("ShootEnd") and not sprite:WasEventTriggered("Stop")) then
				data.ShootTimer = data.ShootTimer - 1
				if data.ShootTimer <= EndingTaperStart then
					data.BuildUp = math.max(data.BuildUp - 1, 0)
				else
					data.BuildUp = math.min(data.BuildUp + 1, BuildUpTime)
				end

				data.FireDelay = data.FireDelay - 1

                local velocity = data.ShootDirection * data.Distance * (0.035 + math.random(-100, 100) * 0.00005) * (math.max(data.BuildUp, 5) / BuildUpTime)

                local angleDiff = REVEL.GetAngleDifference(velocity:GetAngleDegrees(), (target.Position - npc.Position):GetAngleDegrees())
                if math.abs(angleDiff) < 45 then
					data.Distance = target.Position:Distance(npc.Position)
				end

				if data.FireDelay <= 0 then
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS2_BUBBLES, 0.35, 0, false, 1.2 + math.random() * 0.2)
                    local clampedDiff = REVEL.ClampNumberSize(-angleDiff, 45)
                    local p = REVEL.SpawnNPCProjectile(npc, velocity:Rotated(clampedDiff + math.random(-2, 2)), nil, ProjectileVariant.PROJECTILE_TEAR)
					p.Height = -10
					p.FallingSpeed = -25
					p.FallingAccel = 1
					p.Color = REVEL.PissColor
                    p.RenderZOffset = npc.RenderZOffset + 100
					data.FireDelay = math.random(MinFireDelay, MaxFireDelay + math.floor((BuildUpTime - data.BuildUp) / 2))
				end

				if data.ShootTimer <= 0 and not sprite:IsPlaying("ShootEnd") then
					sprite:Play("ShootEnd", true)
				end
			end

			if sprite:IsFinished("ShootStart") or sprite:IsFinished("ShootLoop") then
				sprite:Play("ShootLoop", true)
			end

			if sprite:IsFinished("ShootEnd") then
                data.RecalculatePath = true
				data.State = "Idle"
			end

            if not sprite:IsPlaying("ShootStart") and not sprite:IsPlaying("ShootEnd") and not sprite:IsPlaying("ShootLoop") then
                sprite:Play("ShootStart", true)
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, yellowSnow_NpcUpdate, REVEL.ENT.YELLOW_SNOW.id)
end


-- All snowball flavours
-- Yellow: spawn creep on hops, Strawberry: spawn creep on damage (and when thrown), Chocolate: tbd
do
    local Type1BloodColor = {
        [REVEL.ENT.SNOWBALL.variant] = REVEL.SnowSplatColor,
        [REVEL.ENT.STRAWBERRY_SNOWBALL.variant] = Color(1, 1, 1.2, 1,conv255ToFloat( 90, 0, 90)),
    }
    REVEL.StrawberryColor = Color(1, 1, 1, 1,conv255ToFloat( 158, 76, 103))
	--base creep color is 162, 10, 12; strawberry base color is 158, 76, 103; this is to convert one in the other
	REVEL.StrawberryCreepColor = Color((158 / 255) / (162 / 255), (76 / 255) / (10 / 255), (103 / 255) / (12 / 255), 1,conv255ToFloat( 0, 0, 0))

    local function snowball_NpcUpdate(_, npc)
        if not (REVEL.ENT.SNOWBALL:isEnt(npc) or REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(npc)) then return end

        local data = REVEL.GetData(npc)

        npc.SplatColor = Type1BloodColor[npc.Variant]

        if data.ShotByHuffpuff then return end

        local angle = npc.Velocity:GetAngleDegrees()

        if npc.Velocity.X < 0 then
            npc:GetSprite().FlipX = false
        else --Right
            npc:GetSprite().FlipX = true
        end

        if npc.FrameCount == 1 then
            data.HurtFrame = 0
            data.IsHurt = 0
        end

        if data.IsHurt == 1 then
            data.HurtFrame = data.HurtFrame + 1
            if data.HurtFrame >= 30 then
                data.HurtFrame = 0
                data.IsHurt = 0
            end
        end

        if npc:GetSprite():IsFinished("Appear") or npc:GetSprite():IsFinished("Jump") then
            npc.State = NpcState.STATE_MOVE
        elseif npc:GetSprite():IsFinished("Idle") then
            local hop = math.random(1, 2)
            if hop == 1 then
                npc.State = NpcState.STATE_ATTACK
            end
        end

        if npc.State == NpcState.STATE_MOVE then
            if not npc:GetSprite():IsPlaying("Idle") then
                npc:GetSprite():Play("Idle", true)
            end

            npc.Velocity = npc.Velocity * 0.7
        elseif npc.State == NpcState.STATE_ATTACK then
            if not npc:GetSprite():IsPlaying("Jump") then
                npc:GetSprite():Play("Jump", true)
            end
        end

        if npc:GetSprite():IsEventTriggered("Hop") then
			local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(npc.Position))
			if grid and grid.CollisionClass == GridCollisionClass.COLLISION_PIT then
				npc.Velocity = (REVEL.room:FindFreeTilePosition(npc.Position, 0) - npc.Position)/10
			else
				local SnowVelocity = Vector.FromAngle(1*math.random(0, 360))*5
				npc.Velocity = npc.Velocity*0.7 + SnowVelocity
			end
        elseif npc:GetSprite():IsEventTriggered("Creep") then
            npc.Velocity = Vector.Zero
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)

            if REVEL.ENT.SNOWBALL:isEnt(npc) then
                REVEL.SpawnIceCreep(npc.Position, npc)
            end
        end
    end
    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, snowball_NpcUpdate, REVEL.ENT.SNOWBALL.id)

    StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(ent, dmg, flag, source)
        -- Snowball hurt sound
        if REVEL.ENT.SNOWBALL:isEnt(ent) then
            if REVEL.GetData(ent).IsHurt == 0 then
                local snd = math.random(1, 3)
                if snd == 1 then
                    REVEL.sfx:NpcPlay(ent:ToNPC(), SoundEffect.SOUND_BABY_HURT, 1, 0, false, 1)
                    REVEL.GetData(ent).IsHurt = 1
                end
            end

        elseif REVEL.ENT.STRAWBERRY_SNOWBALL:isEnt(ent) then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, ent.Position, ent, true)
            creep.Color = REVEL.StrawberryCreepColor
            if ent.HitPoints - dmg <= 0 then
                REVEL.UpdateCreepSize(creep, creep.Size * 1.8 * 4, true)
            else
                REVEL.UpdateCreepSize(creep, creep.Size * 1.4 * 4, true)
            end
        end
    end, REVEL.ENT.SNOWBALL.id)

    local Type2BloodColor = {
        [REVEL.ENT.YELLOW_SNOWBALL.variant] = Color(1, 2, 1, 1,conv255ToFloat( 90, 200, 0)),
    }

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if not REVEL.ENT.YELLOW_SNOWBALL:isEnt(npc) then
            return
        end

        local data, sprite = REVEL.GetData(npc), npc:GetSprite()

        npc.SplatColor = Type2BloodColor[npc.Variant]

        if data.ShotByHuffpuff then return end

        if sprite:IsEventTriggered("Hop") then
            local hop = math.random(1, 3)

            if hop == 3 then
                local yellowCreep = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_YELLOW, -1, false, false)
                local isCreep
                for _, creep in ipairs(yellowCreep) do
                    if creep.Position:DistanceSquared(npc.Position) < npc.Size ^ 2 then
                        isCreep = true
                        break
                    end
                end

                if not isCreep then
                    hop = math.random(1, 2)
                end
            end

            if hop == 1 then
                data.Velocity = (npc:GetPlayerTarget().Position - npc.Position):Resized(2)
            elseif hop == 2 then
                data.Velocity = RandomVector() * 2
            else
                data.Velocity = Vector.Zero
            end
        end

        if sprite:IsEventTriggered("Creep") and not sprite:IsPlaying("Land") then
            local eff = Isaac.Spawn(
                EntityType.ENTITY_EFFECT, EffectVariant.CREEP_YELLOW, 0, 
                npc.Position, Vector.Zero, 
                npc
            )
            if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                eff.Color = Color(1,1,1, 1, 0.5, 1, 0)
            end
        end
        if sprite:IsEventTriggered("Creep") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_JUMPS, 0.7, 0, false, 1)
        end

        if sprite:WasEventTriggered("Hop") and not sprite:WasEventTriggered("Creep") then
            npc.Velocity = npc.Velocity * 0.6 + data.Velocity
        else
            npc.Velocity = npc.Velocity * 0.6
        end

        if sprite:IsFinished("LeadJump") or sprite:IsFinished("QuickJump") then
            if math.random(1, 3) == 1 then
                sprite:Play("Land", true)
            else
                sprite:Play("QuickJump", true)
            end
        end

        if sprite:IsFinished("Appear") or sprite:IsFinished("Land") then
            sprite:Play("Idle", true)
        end

        if sprite:IsFinished("Idle") then
            sprite:Play("Idle", true)
        end

        if sprite:IsPlaying("Idle") then
            if not data.JumpCooldown then
                data.JumpCooldown = math.random(10, 20)
            end

            data.JumpCooldown = data.JumpCooldown - 1
            if data.JumpCooldown <= 0 then
                sprite:Play("LeadJump", true)
                data.JumpCooldown = math.random(10, 20)
            end
        end
    end, REVEL.ENT.YELLOW_SNOWBALL.id)
end

end