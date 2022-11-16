local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--[[
Frozen Famine - 240 HP
Phase 1: (>50% HP)
- Dashes accross the screen like normal, however he tries to swerve into stalactites and break em
- Slams his horse on the ground like a hammer causing
   - 1 small stalactite or a regular stalactite to fall from the ceiling
   - A shockwave towards Isaac + a burst of 8 tears (remove the tears if too tough?)

Phaes 2:
- Dashes accross the screen like normal, however on the second time around he slams into the wall and causing...
   - Causes a small stalactite and a regular stalactite to fall in random spots
   - Does a burst of 8 tears around itself on impact
- Pooter strike

States:
-4=move
-28= recentering as famine AI tends to hug walls
-13=attack (originally spawn fly) anim start
-29=pooter strike
-30=hammer strike
-8=charge anim start
-31=charge pt 2
-32=charge end
]]

local FrostRiderVars = {
    shocks = {}, --shockwave tears
    pooterOffset = Vector(67,0),
    accel = 0.08,
    doesAccel = false
}

local FrostRiderBalance = { --TODO: make the boss use the balance table
    Dash = {
        SpawnStalactites = true,
        StalactiteNum = {
            Default = 3,
            Headless = 1,
        },
        StalactiteDelayFirst = {
            Default = 15,
            Headless = 10,
        },
        StalactiteDelayBetween = 8,
        StalactiteDistanceInLine = {
            Default = 60,
            Headless = 0,
        },
        SpawnInLine = true,
    },
    MaxCertainPooters = 1,
    MaxPooters = 2,
    MaxSpiders = 2,
    MaxSpawnsTotal = 2,
    EmptyIceBlockSpeed = 12,
    PooterIceBlockSpeed = 10,
    SpawnHeadCooldown = {
        Default = -1,
        Headless = 60,
    },
}

local function pickRandomStalactitePos(npc, targetDistMin, targetDistMax, rightMinDistance)
    targetDistMin = targetDistMin or 200
    targetDistMax = targetDistMax or 300
    rightMinDistance = rightMinDistance or 0
    local stalagOffset = RandomVector() * math.random(targetDistMin, targetDistMax)
    local stalagPos = npc:GetPlayerTarget().Position + stalagOffset
    local br = REVEL.room:GetBottomRightPos()

    if stalagPos.X > br.X - rightMinDistance then
        stalagPos = Vector(br.X - rightMinDistance, stalagPos.Y)
    end

    return REVEL.room:GetClampedPosition(stalagPos, 60)
end

local function spawnStalactite(npc, pos, anim, preTarget)
    local stal = REVEL.ENT.STALACTITE:spawn(pos, Vector.Zero, npc)
    if preTarget then
        stal:GetData().spawnedTarget = true
        stal:GetData().target = preTarget
        preTarget:GetData().noRequireStalactite = nil
        preTarget:GetData().Stalactite = stal
    end
    return stal
end

local function spawnStalactiteAtRandomPos(npc, targetDistMin, targetDistMax, rightMinDistance, noTarget)
    return spawnStalactite(npc, REVEL.room:FindFreePickupSpawnPosition(pickRandomStalactitePos(npc, targetDistMin, targetDistMax, rightMinDistance), 0, true), nil, noTarget)
end

local function spawnIcePooter(npc, pos, vel, isEmpty, speed)
    local pooter = REVEL.ENT.ICE_POOTER:spawn(pos, vel, npc)

    pooter:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    pooter:GetSprite():Play("Land", true)

    if isEmpty then
        pooter:GetData().noPooter = true
        pooter:GetSprite():ReplaceSpritesheet(0, "gfx/monsters/revel1/ice_pooter_empty.png")
        pooter:GetSprite():LoadGraphics()
    end
    if speed then
        pooter:GetData().speed = speed
    end

    return pooter
end

local function closestY(tbl, y)
    local closeY
    local closeEnt
    for _, ent in ipairs(tbl) do
        local diff = math.abs(ent.Position.Y - y)
        if not closeY or diff < closeY then
            closeY = diff
            closeEnt = ent
        end
    end
    return closeEnt
end

local headOffsets = {
    Vector(-60, 0),
    Vector(60, 0)
}

local aboveBelow = {
    Vector(0, -60),
    Vector(0, 60)
}

local left, right = Vector(-1, 0), Vector(1, 0)
local function frostRider_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.FROST_RIDER.variant then
        return
    end

    local spr, data, target = npc:GetSprite(), npc:GetData(), npc:GetPlayerTarget()
    local stals = Isaac.FindByType(REVEL.ENT.STALACTITE.id, REVEL.ENT.STALACTITE.variant, -1, false, false)

    if not data.Init then
        data.Init = true
        REVEL.SetScaledBossHP(npc)
        --npc.MaxHitPoints = math.max(npc.MaxHitPoints, REVEL.EstimateDPS(REVEL.player) * 13)
        --npc.HitPoints = npc.MaxHitPoints

        data.IsChampion = REVEL.IsChampion(npc)

        if not data.IsChampion then
            -- if REVEL.IsRuthless() then
            --     data.bal = REVEL.GetBossBalance(FrostRiderBalance, "Ruthless")
            -- else
                data.bal = REVEL.GetBossBalance(FrostRiderBalance, "Default")
            -- end
        else
            data.bal = REVEL.GetBossBalance(FrostRiderBalance, "Headless")
        end

        if data.IsChampion then
            npc.MaxHitPoints = npc.MaxHitPoints / 2
            npc.HitPoints = npc.MaxHitPoints
            spr:Load("gfx/bosses/revel1/frost_rider/frost_rider_champion.anm2", true)

            local heads = Isaac.FindByType(REVEL.ENT.FROST_RIDER_HEAD.id, REVEL.ENT.FROST_RIDER_HEAD.variant, -1, false, false)
            local head = heads[1] or
                            REVEL.ENT.FROST_RIDER_HEAD:spawn(REVEL.room:FindFreePickupSpawnPosition(npc.Position, 0, true), Vector.Zero, npc)

            head:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            head.MaxHitPoints = npc.MaxHitPoints
            head.HitPoints = head.MaxHitPoints

            head:GetData().IsChampion = true
            head:GetData().Body = npc
            head:GetData().AttackCooldown = data.bal.SpawnHeadCooldown
            head:GetSprite():Load("gfx/bosses/revel1/frost_rider/frost_rider_champion.anm2", true)
            head:GetSprite():Play("Appear_Head", true)
            data.Head = head
        end

        data.AttackCooldown = math.random(45, 90)

        data.State = "Idle"
    end

    for i,e in ripairs(FrostRiderVars.shocks) do
        if not e:Exists() or e:IsDead() then
            table.remove(FrostRiderVars.shocks, i)
        end
    end

    for i,e in ripairs(stals) do --reverse look (for optimization as were removing stuff from the table) the stalactites table for any ded ones and contact with shockwaves
        for j,t in ripairs(FrostRiderVars.shocks) do
            if e:GetData().type then
                if t.Position:Distance(e.Position) < 32 and (e:GetSprite():IsPlaying("Idle"..e:GetData().type) or e:GetSprite():WasEventTriggered("Collision")) then
                    e:Die()
                    t:Remove()
                    table.remove(FrostRiderVars.shocks, j)
                end
            end
        end

        if not e:Exists() or e:IsDead() then
            table.remove(stals, i)
        end
    end

    if (npc.HitPoints < npc.MaxHitPoints / 3) and not data.IsChampion then
        local explosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, nil)
        explosion.Color = REVEL.IceCreepColor
        local maxHP = npc.MaxHitPoints
        npc:Morph(REVEL.ENT.FROST_RIDER_HEAD.id, REVEL.ENT.FROST_RIDER_HEAD.variant, 0, -1)
        npc:BloodExplode()
        npc.MaxHitPoints = maxHP
        data.IsChampion = nil
        data.State = nil

        return
    end

    data.AttackCooldown = data.AttackCooldown - 1

    local pooterCount = (Isaac.CountEntities(nil, REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_POOTER, -1, -1) or 0)
    local spiderCount = (Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0) + (Isaac.CountEntities(nil, REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, -1) or 0)
    local maxedSpawns = pooterCount + spiderCount >= data.bal.MaxSpawnsTotal
    local stalCount = #stals

    if data.State == "SwingAtHead" and not data.Head and spr:WasEventTriggered("Spawn") then
        npc.Velocity = npc.Velocity * 0.95
    elseif data.State ~= "Idle" and data.State ~= "Dash" then
        npc.Velocity = npc.Velocity * 0.8
    end

    if data.State == "Idle" then
        spr:Play("FullFloat", false)
        if npc.Velocity.X < -2 then
			spr.FlipX = true
		elseif npc.Velocity.X > 2 then
			spr.FlipX = false
		end

        if data.IsChampion and (data.Head and data.Head:Exists() and not data.Head:IsDead()) then
            local head = data.Head
            local hdata = head:GetData()

            -- Aims to have the head between itself and the player
            local preferOffset = REVEL.GetGoodPosition(target.Position, headOffsets, head.Position, true)
            local preferPosition = head.Position + preferOffset
            local aim

            -- If it's farther from its goal position than the opposite of its goal position, smooth movement by going above rather than trying to go straight through.
            local changedToVertical
            if npc.Position:DistanceSquared(preferPosition) > npc.Position:DistanceSquared(head.Position + (-preferOffset)) then
                local preferOffsetVertical = REVEL.GetGoodPosition(npc.Position, aboveBelow, head.Position, false)
                aim = head.Position + preferOffsetVertical
                changedToVertical = true
            else
                aim = preferPosition
            end

            if changedToVertical or npc.Position:Distance(aim) > 32 then
                REVEL.MoveAt(npc, aim, math.random(5, 9) * 0.1, 0.9)
            end

            if data.AttackCooldown <= 0 then
                local attacks = {
                    Dash = 1,
                    None = 30
                }

                local headCount = (Isaac.CountEntities(nil, REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_POOTER, -1, -1) or 0) + (Isaac.CountEntities(nil, REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0)
                if npc.Position:Distance(preferPosition) < 64 and hdata.State == "Idle" then
                    if headCount ~= 0 then
                        if headCount == 1 then
                            attacks.SwingAtHead = 10
                        else
                            attacks.SwingAtHead = 50
                        end
                    end
                end

                if math.abs(target.Position.Y - npc.Position.Y) < npc.Size + target.Size + 24 then
                    attacks.Dash = 4
                end

                local attack = REVEL.WeightedRandom(attacks)

                if attack == "SwingAtHead" then
                    spr:Play("AttackPooter", true)
                    data.Head:GetSprite():Play("HeadWalk", true)
                    hdata.State = "Bouncing"
                    hdata.Hit = nil
                    data.State = "SwingAtHead"
                elseif attack == "Dash" then
                    spr.FlipX = target.Position.X < npc.Position.X
                    spr:Play("AttackDashStart", true)
                    data.State = "Dash"
                end
            end
        elseif data.IsChampion then
            data.Head = nil
            REVEL.MoveRandomly(npc, 20, 5, 10, math.random(7, 11) * 0.1, 0.9)

            if data.AttackCooldown <= 0 then
                local attacks = {
                    SwingAtHead = 2,
                    Dash = 1,
                    Hammer = 1
                }

                if npc.Position:Distance(target.Position) < npc.Size + target.Size + 96 then
                    attacks.SwingAtHead = 15
                end

                if math.abs(target.Position.Y - npc.Position.Y) < npc.Size + target.Size + 24 then
                    attacks.Dash = 4
                end

                local attack = REVEL.WeightedRandom(attacks)

                if attack == "SwingAtHead" then
                    spr:Play("AttackPooter", true)
                    data.State = "SwingAtHead"
                elseif attack == "Dash" then
                    spr.FlipX = target.Position.X < npc.Position.X
                    spr:Play("AttackDashStart", true)
                    data.State = "Dash"
                elseif attack == "Hammer" then
                    spr:Play("AttackHammer", true)
                    data.State = "Hammer"
                end
            end
        else
            REVEL.MoveRandomly(npc, 45, 15, 35, 0.4, 0.9, REVEL.room:GetCenterPos())

            if data.AttackCooldown <= 0 then
                local attacks = {
                    Hammer = 1,
                    SpitPooter = 1
                }

                if stalCount > 3 then
                    attacks.Dash = 2
                end

                if math.abs(target.Position.Y - npc.Position.Y) < npc.Size + target.Size + 24 then
                    attacks.Dash = 2
                end

                local attack = REVEL.WeightedRandom(attacks)
                if attack == "Hammer" then
                    spr:Play("AttackHammer", true)
                    data.State = "Hammer"
                elseif attack == "SpitPooter" then
                    spr:Play("AttackPooter", true)
                    data.State = "Pooter"

                    data.NoPooter = maxedSpawns or not (pooterCount < data.bal.MaxCertainPooters or (data.bal.MaxPooters < 2 and math.random() > 0.5))
                    if data.NoPooter then
                        spr:ReplaceSpritesheet(2, "gfx/monsters/revel1/ice_pooter_empty.png")
                        spr:LoadGraphics()
                    else
                        spr:ReplaceSpritesheet(2, "gfx/monsters/revel1/ice_pooter.png")
                        spr:LoadGraphics()
                    end
                elseif attack == "Dash" then
                    spr.FlipX = target.Position.X < npc.Position.X
                    spr:Play("AttackDashStart", true)
                    data.State = "Dash"
                end
            end
        end
    elseif data.State == "Hammer" then --HAMMA DOWN
        if spr:GetFrame() == 1 then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_5, 1, 0, false, 1)
        end
        if spr:IsEventTriggered("Strike") then
            spawnStalactiteAtRandomPos(npc)
            local dir = (target.Position - npc.Position):Resized(5)
            for i=-1,1,2 do
                local shock = REVEL.SpawnCustomShockwave(npc.Position, dir:Rotated(5 * i), "gfx/effects/revel1/glacier_shockwave.png", nil, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
                table.insert(FrostRiderVars.shocks, shock)
            end

            REVEL.game:ShakeScreen(10)
            REVEL.sfx:Play(48, 1, 0, false, 1)
            REVEL.sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)

            for i, stal in ripairs(stals) do
                if stal.Position:DistanceSquared(npc.Position) < (70) ^ 2 then
                    stal:Die()
                    table.remove(stals, i)
                end
            end
        elseif spr:IsFinished("AttackHammer") then
            data.State = "Idle"
            data.AttackCooldown = math.random(45, 90)
        end
    elseif data.State == "Pooter" then --POOTER SPAWN SWING
        if not spr:WasEventTriggered("Spit")  then --calculate pooter vel
            spr.FlipX = npc.Position.X > npc:GetPlayerTarget().Position.X --unflipped = right
        end

        if spr:IsEventTriggered("Spawn") then
            local angle = (npc:GetPlayerTarget().Position-npc.Position):GetAngleDegrees()
            --velocity should be at most 45° from the sides (ie horizontal line)
            --reminder that vector angles are as follows (examples) in Isaac: (1,0) -> 0° , (0,1) -> 90° , (-1,0) -> 180° (0,-1) -> -90°
            if angle < -45 and not spr.FlipX then
                angle = -45
            elseif angle > 45 and not spr.FlipX then
                angle = 45
            elseif angle > 0 and angle < 135 and spr.FlipX then
                angle = 135
            elseif angle < 0 and angle > -135 and spr.FlipX then
                angle = -135
            end
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 1)

            local e
            local vel = Vector.FromAngle(angle)

            if spr.FlipX then
                spawnIcePooter(npc, npc.Position+Vector(-FrostRiderVars.pooterOffset.X,FrostRiderVars.pooterOffset.Y), vel, data.NoPooter, data.NoPooter and data.bal.EmptyIceBlockSpeed or data.bal.PooterIceBlockSpeed)
            else
                spawnIcePooter(npc, npc.Position+FrostRiderVars.pooterOffset, vel, data.NoPooter, data.NoPooter and data.bal.EmptyIceBlockSpeed or data.bal.PooterIceBlockSpeed)
            end

            data.NoPooter = nil
        elseif spr:IsEventTriggered("Spit") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)
        elseif spr:IsFinished("AttackPooter") then
            data.State = "Idle"
            data.AttackCooldown = math.random(45, 75)
        end
    elseif data.State == "SwingAtHead" then
        if data.Head then
            data.Head:GetData().State = "Bouncing"
        end

        if not data.Head then
            if not spr:WasEventTriggered("Spawn") then
                spr.FlipX = npc.Position.X > target.Position.X --unflipped = right
            end
        else
            if not spr:WasEventTriggered("Swing") then
                spr.FlipX = npc.Position.X > data.Head.Position.X --unflipped = right
            end
        end

        if spr:IsEventTriggered("Spawn") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 1)
            if data.Head then
                local angle = (npc:GetPlayerTarget().Position-npc.Position):GetAngleDegrees()
                --velocity should be at most 45° from the sides (ie horizontal line)
                --reminder that vector angles are as follows (examples) in Isaac: (1,0) -> 0° , (0,1) -> 90° , (-1,0) -> 180° (0,-1) -> -90°
                if angle < -45 and not spr.FlipX then
                    angle = -45
                elseif angle > 45 and not spr.FlipX then
                    angle = 45
                elseif angle > 0 and angle < 135 and spr.FlipX then
                    angle = 135
                elseif angle < 0 and angle > -135 and spr.FlipX then
                    angle = -135
                end

                data.Head.Velocity = Vector.FromAngle(angle) * 12
                data.Head:GetData().Hit = true
            else
                npc.Velocity = (npc:GetPlayerTarget().Position-npc.Position):Resized(14)
            end
        elseif spr:IsEventTriggered("Spit") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.MONSTER_GRUNT_5, 1, 0, false, 1)
            for i = 1, math.random(8, 14) do
                local pro = npc:FireBossProjectiles(1, target.Position, 5, ProjectileParams())
                pro:GetData().FamineSpawned = true
            end
        elseif spr:IsFinished("AttackPooter") then
            data.State = "Idle"
            data.AttackCooldown = math.random(45, 75)
        end
    elseif data.State == "Dash" then
        local tLeft, bRight = REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
        if spr:IsFinished("AttackDashStart") then
            spr:Play("AttackDash", true)
        end

        if spr:IsEventTriggered("Sound") then
            if data.IsChampion then --champion doesn't have a head
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 1)
            else
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
            end
        end

        if spr:IsPlaying("AttackDash") or spr:WasEventTriggered("Dash") then
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            local x
            local y = npc.Velocity.Y * 0.9
            local speed = 16
            if FrostRiderVars.doesAccel and data.PassedOnce then
                speed = math.min(26, speed + data.FramesPassed / 5)
            end

            if spr.FlipX then
                x = -speed
            else
                x = speed
            end

            data.stalTarg = closestY(stals, data.NextDashStartY or npc.Position.Y)
            if data.stalTarg then
                local shouldHome = true
                if data.PassedOnce then
                    if spr.FlipX and (data.stalTarg.Position.X > npc.Position.X) then
                        shouldHome = false
                    elseif not spr.FlipX and (data.stalTarg.Position.X < npc.Position.X) then
                        shouldHome = false
                    end
                end

                if shouldHome then
                    local yDiff = data.stalTarg.Position.Y - npc.Position.Y
                    if math.abs(yDiff) > 0.5 then
                        if yDiff < 0 then
                            yDiff = -0.5
                        else
                            yDiff = 0.5
                        end
                    end

                    y = y + yDiff
                end
            end

            npc.Velocity = Vector(x, y)

            for i,e in ripairs(stals) do --check if smashed against stalactite
                if e.Position:Distance(npc.Position + npc.Velocity * 2) < e.Size + 8 + npc.Size then
                    e:Die()
                    table.remove(stals, i)
                    data.stalTarg = closestY(stals, npc.Position.Y)
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.8
        end

        if not data.PassedOnce then
            if spr.FlipX then
                if npc.Position.X < tLeft.X - 128 then
                    local newY = npc.Position.Y
                    if data.NextDashStartY then
                        newY = data.NextDashStartY
                        data.NextDashStartY = nil
                    end
                    npc.Position = Vector(bRight.X + 128, newY)
                    data.FramesPassed = 0
                    data.PassedOnce = true
                end
            else
                if npc.Position.X > bRight.X + 128 then
                    npc.Position = Vector(tLeft.X - 128, npc.Position.Y)
                    data.FramesPassed = 0
                    data.PassedOnce = true
                end
            end
        else
            data.FramesPassed = data.FramesPassed + 1
            if spr.FlipX then
                if npc.Position.X < tLeft.X + 32 then
                    npc.Velocity = Vector.Zero
                    spr:Play("DashEnd", true)
                    data.State = "DashEnd"
                end
            else
                if npc.Position.X > bRight.X - 32 then
                    npc.Velocity = Vector.Zero
                    spr:Play("DashEnd", true)
                    data.State = "DashEnd"
                end
            end
        end
    elseif data.State == "DashEnd" then
        npc.Velocity = Vector.Zero
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        data.PassedOnce = nil

        if spr:IsEventTriggered("Hit") then
            local off = 0
            if spr.FlipX then
                off = 180
            end

            for i=0, 4 do
                Isaac.Spawn(9, 0, 0, npc.Position, Vector(0,-9):Rotated(-45 * i + off), npc):ToProjectile()
            end

            if data.bal.Dash.SpawnStalactites then
                local firstPos = pickRandomStalactitePos(npc, nil, 400, (data.bal.Dash.StalactiteNum - 1) * (data.bal.Dash.StalactiteDistanceInLine + 10) + 120)
                local firstTarget = REVEL.SpawnDecorationFromTable(firstPos, Vector.Zero, REVEL.StalactiteTargetDeco2)
                firstTarget:GetData().noRequireStalactite = true
                REVEL.DelayFunction(spawnStalactite, data.bal.Dash.StalactiteDelayFirst, {npc, firstPos, nil, firstTarget}, true)

                data.NextDashStartY = firstPos.Y

                if data.bal.Dash.StalactiteNum > 1 then
                    for i = 1, data.bal.Dash.StalactiteNum - 1 do
                        if data.bal.Dash.SpawnInLine then
                            local stalTarget = REVEL.SpawnDecorationFromTable(firstPos + Vector(i * data.bal.Dash.StalactiteDistanceInLine, 0), Vector.Zero, REVEL.StalactiteTargetDeco2)
                            stalTarget:GetData().noRequireStalactite = true
                            REVEL.DelayFunction(spawnStalactite, data.bal.Dash.StalactiteDelayFirst + i * data.bal.Dash.StalactiteDelayBetween, {npc, firstPos + Vector(i * data.bal.Dash.StalactiteDistanceInLine, 0), nil, stalTarget}, true)
                        else
                            REVEL.DelayFunction(spawnStalactiteAtRandomPos, data.bal.Dash.StalactiteDelayFirst + i * data.bal.Dash.StalactiteDelayBetween, {npc, nil, 400}, true)
                        end
                    end
                end
            end

            REVEL.game:ShakeScreen(10)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
        end

        if not spr:IsPlaying("DashEnd") then
            data.State = "Idle"
            data.AttackCooldown = math.random(45, 90)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, frostRider_NpcUpdate, REVEL.ENT.FROST_RIDER.id)

local function frostRiderPhase2_NpcUpdate(_, npc)
    local data, spr, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    npc.SplatColor = REVEL.SnowSplatColor

    if data.State ~= "Bouncing" and not data.StartBounce then
        data.Hit = nil
        data.TaperDown = nil
        data.Bounces = nil
    end

    if data.State ~= "Bouncing" and (REVEL.MultiFinishCheck(spr, "HeadAttack", "HeadAttack2", "HeadAttack3") or not data.State) then
        if data.StartBounce then
            data.Hit = true
            data.State = "Bouncing"
        else
            data.State = "Idle"
        end
    end

    if data.State == "Bouncing" and not data.Hit and not data.EndlessBounce and (not data.Body:Exists() or data.Body:IsDead() or data.Body.Type ~= REVEL.ENT.FROST_RIDER.id) then
        data.State = "Idle"
    end

    if data.IsChampion and not data.ChampionPhase2 and (not data.Body:Exists() or data.Body:IsDead() or data.Body.Type ~= REVEL.ENT.FROST_RIDER.id) then
        data.ChampionPhase2 = true
    end

    if not data.bal then
        data.bal = REVEL.GetBossBalance(FrostRiderBalance, data.IsChampion and "Headless" or "Default")
    end

    if npc.FrameCount % 8 == 0 then
        REVEL.SpawnIceCreep(npc.Position, npc)
    end

    local poots, spids = (Isaac.CountEntities(nil, REVEL.ENT.ICE_POOTER.id, REVEL.ENT.ICE_POOTER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_POOTER, -1, -1) or 0), (Isaac.CountEntities(nil, REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, -1) or 0) + (Isaac.CountEntities(nil, EntityType.ENTITY_SPIDER, -1, -1) or 0)
    local pootCap, spiderCap = data.bal.MaxPooters, data.bal.MaxSpiders

    if data.State == "Idle" then
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        if not data.IsChampion or npc.FrameCount > 30 then
            REVEL.MoveAt(npc, target.Position, 0.3, 0.9)
        end
        spr.FlipX = target.Position.X < npc.Position.X

        if not REVEL.MultiPlayingCheck(spr, "HeadWalk", "Appear_Head") then
            spr:Play("HeadWalk", true)
        end

        if not data.AttackCooldown or data.AttackCooldown <= 0 then
            local cap = 20
            if data.IsChampion then
                if data.ChampionPhase2 then
                    cap = 15
                else
                    cap = 30
                end
            end

            if math.random(1, cap) == 1 then
                local atk = math.random(1, 3)

                local maxedSpawns = poots + spids >= data.bal.MaxSpawnsTotal

                if atk == 1 and (poots == 0 or spids == 0) then
                    if poots == 0 and spids == 0 then
                        atk = math.random(2, 3)
                    elseif poots == 0 then
                        atk = 3
                    else
                        atk = math.random() > 0.5 and 1 or 3
                    end
                end

                if atk == 2 and maxedSpawns then
                    atk = math.random() > 0.5 and 1 or 3
                end

                if data.ChampionPhase2 then
                    data.StartBounce = true
                end

                if atk == 1 then
                    data.State = "Projectiles"
                    spr:Play("HeadAttack", true)
                elseif atk == 2 then
                    data.State = "Spider"
                    spr:Play("HeadAttack2", true)
                else
                    data.State = "Pooter"
                    spr:Play("HeadAttack3", true)
                end
            end
        else
            data.AttackCooldown = data.AttackCooldown - 1
        end
    elseif data.State == "Bouncing" or (data.StartBounce and spr:WasEventTriggered("Shoot")) then
        if data.State == "Bouncing" and not spr:IsPlaying("HeadWalk") then
            spr:Play("HeadWalk", true)
        end

        spr.FlipX = npc.Velocity.X > 0

        if not data.Hit then
            npc.Velocity = npc.Velocity * 0.5
        elseif not data.TaperDown then
            npc.Velocity = npc.Velocity:Resized(14)
        end

        if not data.Bounces then
            data.Bounces = 2
        end

        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS

        local forward = npc.Position
        local clamp = REVEL.room:GetClampedPosition(forward, 8)
        if clamp.X ~= forward.X then
            npc.Velocity = Vector(-npc.Velocity.X, npc.Velocity.Y)
            data.Bounces = data.Bounces - 1
        end

        if clamp.Y ~= forward.Y then
            npc.Velocity = Vector(npc.Velocity.X, -npc.Velocity.Y)
            data.Bounces = data.Bounces - 1
        end

        for i,e in ipairs(REVEL.roomEnemies) do
            if not e:IsDead() and e.HitPoints ~= 0 and e.Index ~= npc.Index and forward:Distance(e.Position) < e.Size+npc.Size then
                npc.Velocity = (npc.Position - e.Position):Resized(14)
                data.Bounces = data.Bounces - 1
                if e.Type == REVEL.ENT.STALACTITE.id and e.Variant == REVEL.ENT.STALACTITE.variant 
                and e:ToNPC().State == NpcState.STATE_MOVE then
                    e:Die()
                elseif e.Type ~= REVEL.ENT.FROST_RIDER.id and e.Type ~= REVEL.ENT.FROST_RIDER_HEAD.id then
                    e:TakeDamage(10, 0, EntityRef(npc), 0)
                end
            end
        end

        if data.Bounces <= 0 then
            data.TaperDown = true
        end

        if data.EndlessBounce then
            data.TaperDown = nil
        end

        if data.TaperDown then
            npc.Velocity = npc.Velocity * 0.9
            if npc.Velocity:Length() < 2 then
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                data.State = "Idle"
                data.TaperDown = nil
                data.Hit = nil
                data.Bounces = nil
                data.StartBounce = nil
            end
        end
    else
        if not spr:WasEventTriggered("Shoot") then
            spr.FlipX = target.Position.X < npc.Position.X
        end

        npc.Velocity = npc.Velocity * 0.5
    end

    if spr:IsEventTriggered("Shoot") then
        if data.IsChampion then
            data.AttackCooldown = 40
        else
            data.AttackCooldown = 20
        end

        local dir = (target.Position - npc.Position):Normalized()
        if data.State == "Projectiles" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_0, 1, 0, false, 1)
            for i = 1, math.random(14, 18) do
               local pro = npc:FireBossProjectiles(1, target.Position, 0, ProjectileParams())
               pro:GetData().FamineSpawned = true
            end
        elseif data.State == "Spider" then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_0, 1, 0, false, 1)
            for i = 1, math.random(8, 12) do
               local pro = npc:FireBossProjectiles(1, target.Position, 0, ProjectileParams())
               pro.Velocity = pro.Velocity * 0.75
               pro:GetData().FamineSpawned = true
            end

            Isaac.Spawn(REVEL.ENT.FROZEN_SPIDER.id, REVEL.ENT.FROZEN_SPIDER.variant, 0, npc.Position + dir * npc.Size * 1.5, dir * 5, npc)
        elseif data.State == "Pooter" then
            local isEmpty = not (poots < data.bal.MaxCertainPooters or (poots < data.bal.MaxPooters and math.random() > 0.5))

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_0, 1, 0, false, 1)
            local pooter = spawnIcePooter(npc, npc.Position + dir * npc.Size * 1.5, dir * 6, isEmpty, isEmpty and data.bal.EmptyIceBlockSpeed or data.bal.PooterIceBlockSpeed)
            pooter:GetData().HitCooldown = 5
        end

        if data.StartBounce then
            data.Hit = true
            data.Bounces = math.random(3, 4)
            npc.Velocity = -dir * 10
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, frostRiderPhase2_NpcUpdate, REVEL.ENT.FROST_RIDER_HEAD.id)

--frost rider reward
local lilFrostRiderChance = 50
local horsemanItemChance = 50
local canGrantFrostRiderReward = false
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	canGrantFrostRiderReward = false
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	canGrantFrostRiderReward = true
end, REVEL.ENT.FROST_RIDER.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	canGrantFrostRiderReward = true
end, REVEL.ENT.FROST_RIDER_HEAD.id)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, velocity, spawner, seed)
	if canGrantFrostRiderReward and type == 5 and variant == 100 then
		canGrantFrostRiderReward = false
		local currentRoom = StageAPI.GetCurrentRoom()
		local boss = nil
		if currentRoom then
			boss = StageAPI.GetBossData(currentRoom.PersistentData.BossID)
		end
		if boss and (boss.Name == "Frost Rider" or boss.NameTwo == "Frost Rider") then
			local rng = REVEL.RNG()
			rng:SetSeed(seed, 0)
			if not REVEL.OnePlayerHasCollectible(REVEL.ITEM.LIL_FRIDER.id) and rng:RandomInt(100)+1 <= lilFrostRiderChance then
				return {type, variant, REVEL.ITEM.LIL_FRIDER.id, seed}
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