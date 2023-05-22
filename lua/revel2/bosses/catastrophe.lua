local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local catBalance = {
    Champions = {RIPGuppy = "Default"},

    Pitch = {
        [REVEL.ENT.CATASTROPHE_GUPPY.variant] = 1,
        [REVEL.ENT.CATASTROPHE_TAMMY.variant] = 1.2,
        [REVEL.ENT.CATASTROPHE_MOXIE.variant] = 0.9,
        [REVEL.ENT.CATASTROPHE_CRICKET.variant] = 0.8
    },
    Sounds = {
        ReadyClaws = {Sound = REVEL.SFX.CAT_READYING_CLAWS, Volume = 0.6, PitchVariance = 0.06},
        Swipe = {Sound = REVEL.SFX.WHOOSH, Volume = 0.6},
        HitYarn = {Sound = REVEL.SFX.CAT_KNOCKING_BALL, PitchVariance = 0.06},
        Release = {Sound = REVEL.SFX.WHOOSH, Volume = 0.8},
        Spin = {Sound = SoundEffect.SOUND_ULTRA_GREED_SPINNING, Volume = 0.6},
        Land = {Sound = SoundEffect.SOUND_FETUS_LAND, Volume = 0.8},
        Cough = {Sound = REVEL.SFX.CATASTROPHE_COUGH},
        Attack = {Sound = REVEL.SFX.CATASTROPHE_ATTACK},
        Defeat = {Sound = REVEL.SFX.CATASTROPHE_DEFEAT},
        FinalDefeat = {Sound = REVEL.SFX.CATASTROPHE_DEFEAT_FINAL},
        RipWrappings = {Sound = REVEL.SFX.CATASTROPHE_STRAIN_THEN_RIP_WRAPPINGS, Volume = 0.8},
        Spawn = {Sound = REVEL.SFX.CATASTROPHE_SPAWN},
        Impact = {Sound = SoundEffect.SOUND_FORESTBOSS_STOMPS}
    }
}

local function IsCat(variant)
    return (variant == REVEL.ENT.CATASTROPHE_CRICKET.variant or variant == REVEL.ENT.CATASTROPHE_TAMMY.variant or variant == REVEL.ENT.CATASTROPHE_GUPPY.variant or variant == REVEL.ENT.CATASTROPHE_MOXIE.variant)
end

local function InitCats(npc, yarn)
    local cats = {npc}

	if not npc or npc.Variant ~= REVEL.ENT.CATASTROPHE_CRICKET.variant then
		cats[#cats + 1] = Isaac.Spawn(REVEL.ENT.CATASTROPHE_CRICKET.id, REVEL.ENT.CATASTROPHE_CRICKET.variant, 0, Vector.Zero, Vector.Zero, nil)
		if not npc then
			npc = cats[1]
		end
	end

	if npc.Variant ~= REVEL.ENT.CATASTROPHE_TAMMY.variant then
		cats[#cats + 1] = Isaac.Spawn(REVEL.ENT.CATASTROPHE_TAMMY.id, REVEL.ENT.CATASTROPHE_TAMMY.variant, 0, Vector.Zero, Vector.Zero, nil)
	end

	if npc.Variant ~= REVEL.ENT.CATASTROPHE_GUPPY.variant then
		cats[#cats + 1] = Isaac.Spawn(REVEL.ENT.CATASTROPHE_GUPPY.id, REVEL.ENT.CATASTROPHE_GUPPY.variant, 0, Vector.Zero, Vector.Zero, nil)
	end

	if npc.Variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
		cats[#cats + 1] = Isaac.Spawn(REVEL.ENT.CATASTROPHE_MOXIE.id, REVEL.ENT.CATASTROPHE_MOXIE.variant, 0, Vector.Zero, Vector.Zero, nil)
	end

	REVEL.Shuffle(cats)

	if not yarn then
		local yarnPos = REVEL.room:GetCenterPos()
		yarn = Isaac.Spawn(REVEL.ENT.CATASTROPHE_YARN.id, REVEL.ENT.CATASTROPHE_YARN.variant, 0, yarnPos, Vector.Zero, nil)
		yarn:GetData().CatsInitialized = true
		if npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			yarn:AddEntityFlags(EntityFlag.FLAG_CHARM | EntityFlag.FLAG_FRIENDLY)
		end
    end
    
    local isChampion = REVEL.IsChampion(yarn)

    yarn:GetData().IsChampion = isChampion

    if yarn:GetData().IsChampion then
        yarn:GetData().bal = REVEL.GetBossBalance(catBalance, "RIPGuppy")
    else
        yarn:GetData().bal = REVEL.GetBossBalance(catBalance, "Default")
    end

	local totalCatHP = 0
    local corners = REVEL.GetCornerPositions()
    for i, cat in ipairs(cats) do
        cat:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        cat:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        local cdata = cat:GetData()
        cdata.Leader = npc
        cdata.Yarn = yarn
        cdata.bal = yarn:GetData().bal
        --REVEL.PlaySound(cat, cdata.bal.Sounds.Spawn, nil, nil, nil, cdata.bal.Pitch[cat.Variant])
        cdata.Cats = cats
        totalCatHP = totalCatHP + cat.MaxHitPoints
        cat:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
        cdata.Wrapped = true
        cdata.Invulnerable = true
        cdata.State = "Wrapped"
        cdata.AttackCooldown = math.random(10, 20)
		cdata.Corner = corners[i].Position
        cdata.IsChampion = isChampion
		cat.Position = cdata.Corner

        if isChampion then
            cdata.AllCatsPhaseTwo = true
            cdata.PhaseTwo = true
            if cat.Variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                cdata.ChampionGuppy = true
                cat:GetSprite():Load("gfx/bosses/revel2/catastrophe/guppy_urn.anm2", true)
                cat:GetSprite():Play("Idle", true)
            end
        end
    end

	local newCatHP, hpPerSecond, scaledLength = REVEL.GetScaledBossHP(nil, nil, yarn)
    for i, cat in pairs(cats) do
        local hpPercent = (cat.MaxHitPoints / totalCatHP)
        REVEL.SetScaledBossHP(cat, nil, nil, newCatHP * hpPercent, hpPerSecond, scaledLength)
        
        cat.MaxHitPoints = cat.MaxHitPoints + 100
        cat.HitPoints = cat.MaxHitPoints

        if isChampion and cat.Variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
            cat.HitPoints = 100
        end
    end

    npc:GetData().IsLeader = true
end

local function SetBMinCooldown(cats, cooldown)
    for _, cat in ipairs(cats) do
        if not cat:GetData().AttackBCooldown or cat:GetData().AttackBCooldown < cooldown then
            cat:GetData().AttackBCooldown = cooldown
        end
    end
end

local function SetMinAttackCooldown(cats, cooldown)
    for _, cat in ipairs(cats) do
        if not cat:GetData().AttackCooldown or cat:GetData().AttackCooldown < cooldown then
            cat:GetData().AttackCooldown = cooldown
        end
    end
end

local bAnimations = {
    "BrimstoneStart",
    "BrimstoneUpLoop",
    "BrimstoneLeftLoop",
    "BrimstoneRightLoop",
    "FlyBall",
    "ChaseStart",
    "ChaseLoopLeft",
    "ChaseLoopRight",
    "Howl",
    "FlyUp",
    "FlyLoop",
    "FlyDown",
    "SpinStart",
    "SpinLoop",
    "SpinEnd"
}
local function IsBAttackActive(cats)
    for _, anim in ipairs(bAnimations) do
        for _, cat in ipairs(cats) do
            if cat:GetSprite():IsPlaying(anim) then
                return true
            end
        end
    end
end

---@param npc EntityNPC
local function CatastropheYarnUpdate(npc)
    npc:GetData().Invulnerable = true
    if not npc:HasEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS) then
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
    end

    if not (npc.Velocity:LengthSquared() > 0) then
        if not npc:GetData().Touched and not npc:GetSprite():IsPlaying("Untouched") then
            npc:GetSprite():Play("Untouched", true)
        end
    else
        npc:GetData().Touched = true
    end

    npc.Velocity = npc.Velocity * 0.975

    if npc:GetData().Touched then
        npc:GetSprite().PlaybackSpeed = REVEL.Lerp(0, 1, npc.Velocity:LengthSquared() / 5 ^ 2)

        REVEL.AnimateWalkFrame(npc:GetSprite(), npc.Velocity, {
            Right = "RollRight",
            Left = "RollLeft",
            Up = "RollUp",
            Down = "RollDown"
        })
    end

    if npc.Velocity:LengthSquared() > 10 then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy.Type ~= REVEL.ENT.CATASTROPHE_YARN.id and not enemy:IsBoss() and enemy:IsVulnerableEnemy() and enemy.Position:DistanceSquared(npc.Position) < (npc.Size + enemy.Size) ^ 2 then
                enemy:TakeDamage(10, 0, EntityRef(npc), 0)
            end
        end
    else
        npc:GetData().LastStruckByCat = nil
    end

    for _, projectile in ipairs(REVEL.roomProjectiles) do
        if projectile.Position:DistanceSquared(npc.Position) < (npc.Size + projectile.Size) ^ 2 then
            projectile:Die()
        end
    end

    if npc:GetData().LastStruckByCat then
        npc.CollisionDamage = 1
    else
        npc.CollisionDamage = 0
    end

    if not npc:GetData().CatsInitialized then
        InitCats(nil, npc)
        npc:GetData().CatsInitialized = true
    end

    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS

    if npc.CollisionDamage > 0 then
        REVEL.DashTrailEffect(npc, 3, 10, Color(1,1,1, 0.25))
        local colorPct = (math.sin(npc.FrameCount) * 0.5 + 0.5) * 0.86
        local color = Color(
            REVEL.Lerp(1, 0.5, colorPct),
            REVEL.Lerp(1, 0.5, colorPct),
            REVEL.Lerp(1, 0.5, colorPct),
            1, 
            colorPct * 0.5, colorPct * 0.2, colorPct * 0.2
        )
        npc:SetColor(color, 2, 10, false, true)
    else
        npc:SetColor(Color.Default, 2, 11, false, true)
    end

    if npc:GetData().IsChampion then
        if not npc:GetData().HPCalculated then
            local hp = 0
            for _, cat in ipairs(Isaac.FindByType(REVEL.ENT.CATASTROPHE_CRICKET.id, -1, -1, false, false)) do
                if cat.HitPoints > 100 and IsCat(cat.Variant) then
                    hp = hp + (cat.HitPoints - 100)
                end
            end

            npc.MaxHitPoints = hp
            npc.HitPoints = hp
            npc:GetData().HPCalculated = true
        end

        if npc.HitPoints <= 0 then
            npc:Die()
        end
    else
        local maxHp, hp = 0, 0
        local areAllCatsDead = true
        for _, cat in ipairs(Isaac.FindByType(REVEL.ENT.CATASTROPHE_CRICKET.id, -1, -1, false, false)) do
            if cat.HitPoints > 100 and IsCat(cat.Variant) then
                maxHp = maxHp + (cat.MaxHitPoints - 100)
                hp = hp + (cat.HitPoints - 100)
                areAllCatsDead = false
            end
        end

        npc.MaxHitPoints = maxHp
        npc.HitPoints = hp

        if areAllCatsDead then
            npc:Die()
        end
    end
end

local function catastrophe_NpcUpdate(_, npc)
    if not IsCat(npc.Variant) then
        if npc.Variant == REVEL.ENT.CATASTROPHE_YARN.variant then
            CatastropheYarnUpdate(npc)
        end

        return
    end

    -- Local stuff
    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    -- Init
    if not data.State then
        InitCats(npc, nil)
    end

    if (not data.Yarn or not data.Yarn:Exists()) and npc.HitPoints > 100 then
        npc.HitPoints = 100
        npc.CollisionDamage = 0
        data.Invulnerable = true
        data.Wrapped = true
        if data.State ~= "WrapUp" and data.State ~= "Wrapped" then
            REVEL.PlaySound(npc, data.bal.Sounds.FinalDefeat, nil, nil, nil, data.bal.Pitch[npc.Variant])
			REVEL.sfx:Stop(SoundEffect.SOUND_ULTRA_GREED_SPINNING)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_SMALL, 0.7, 0, false, 1)
            local p = Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc)
            p:SetColor(Color(0.2,0.1,0.1,1), -1, 1, false, false)
            data.State = "WrapUp"
            sprite:Play("WrapUp", true)
        end
    end

    REVEL.ApplyKnockbackImmunity(npc)

    local amDeadCat = npc.HitPoints <= 100
    local isSwipingCat, allInitialized = false, true
    local catsInPhaseTwo = 0
    local activeCats, inactiveCats, validToWake = {}, {}, {}
    if not amDeadCat then
        for i, cat in ripairs(data.Cats) do
            if not cat:Exists() or cat.HitPoints <= 100 then
                table.remove(data.Cats, i)
            else
                if not cat:GetSprite():IsPlaying("Appear") then
                    local cdata, csprite = cat:GetData(), cat:GetSprite()
                    if csprite:IsPlaying("Swipe") then
                        isSwipingCat = true
                    end

                    if not cdata.State then
                        allInitialized = false
                    end

                    if cdata.PhaseTwo then
                        catsInPhaseTwo = catsInPhaseTwo + 1
                    end

                    if cdata.Wrapped then
                        if ((not cdata.PhaseTwo and not cdata.LastWrapped) or data.AllCatsPhaseTwo) and cdata.State == "Wrapped" then
                            validToWake[#validToWake + 1] = cat
                        end

                        inactiveCats[#inactiveCats + 1] = cat
                    else
                        activeCats[#activeCats + 1] = cat
                    end
                else
                    allInitialized = false
                end
            end
        end
    end

    if not amDeadCat and (not data.Leader or not data.Leader:Exists() or data.Leader.HitPoints <= 100) then
        data.IsLeader = true
        for _, cat in ipairs(data.Cats) do
            local cdata = cat:GetData()
            cdata.Leader = npc
        end
    end

    if not amDeadCat and catsInPhaseTwo == #data.Cats and not data.AllCatsPhaseTwo then
        for _, cat in ipairs(data.Cats) do
            cat:GetData().AllCatsPhaseTwo = true
        end
    end

    if not amDeadCat and data.IsLeader then
        if not data.FightStarted and data.Yarn then
            if data.Yarn.Velocity:LengthSquared() > 0 then
                for _, cat in ipairs(data.Cats) do
                    cat:GetData().FightStarted = true
                end
            end
        else
            local shouldBeOut = 2
            if data.AllCatsPhaseTwo and allInitialized then
                shouldBeOut = 4

                if not isSwipingCat and not data.IsChampion then
                    local canSwipe = {}
                    for _, cat in ipairs(data.Cats) do
                        local cdata, csprite = cat:GetData(), cat:GetSprite()
                        if cdata.State == "Idle" and csprite:IsPlaying("Idle") then
                            canSwipe[#canSwipe + 1] = cat
                        end
                    end

                    if #canSwipe > 0 then
                        local cat = canSwipe[math.random(1, #canSwipe)]
                        cat:GetData().State = "Swipe"
                        cat:GetSprite():Play("Swipe", true)
						if cat.Variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
                            REVEL.PlaySound(cat, data.bal.Sounds.ReadyClaws)
						end
                    end
                end
            end

            if #activeCats < shouldBeOut and #validToWake > 0 and allInitialized then
                local numNeeded = shouldBeOut - #activeCats
                REVEL.Shuffle(validToWake)
                for i = 1, math.min(#validToWake, numNeeded) do
                    local cat = validToWake[i]
                    cat:GetSprite():Play("Release", true)
                    cat:GetData().Wrapped = false
                    cat:GetData().State = "Idle"
                end

                for _, cat in ipairs(data.Cats) do
                    cat:GetData().LastWrapped = nil
                end
            end
        end
    end

    if not data.IsMoving then
        npc.Velocity = npc.Velocity * 0.9
    end

    data.IsMoving = nil

    if not amDeadCat and data.CricketHomingProjectile then
        if data.CricketHomingProjectile:Exists() and not data.CricketHomingProjectile:IsDead() then
            data.CricketHomingProjectile.Velocity = data.CricketHomingProjectile.Velocity * 0.9 + (target.Position - data.CricketHomingProjectile.Position):Resized(1.1)
        else
            data.CricketHomingProjectile = nil
        end
    end

    if sprite:IsEventTriggered("Release") then
        REVEL.PlaySound(npc, data.bal.Sounds.Release)
    end
	if sprite:IsEventTriggered("SpinStart") then
        REVEL.PlaySound(npc, data.bal.Sounds.Spin)
	end
	if sprite:IsEventTriggered("SpinStop") then
		REVEL.sfx:Stop(data.bal.Sounds.Spin.Sound)
	end
	if sprite:IsEventTriggered("Land") then
        REVEL.PlaySound(npc, data.bal.Sounds.Land)
	end

    if data.State == "Wrapped" then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.CollisionDamage = 0
        data.Invulnerable = true

        npc.Velocity = (REVEL.Lerp(npc.Position, data.Corner, 0.2) - npc.Position) / 2

		if not data.ChampionGuppy and not sprite:IsPlaying("WrappedIdle") and not sprite:IsPlaying("WrapUp") then
            sprite:Play("WrappedIdle", true)
        end
    elseif data.State == "WrapUp" then
        data.Wrapped = true
        if sprite:IsEventTriggered("Release") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.CollisionDamage = 0
            data.Invulnerable = true
        end

        if sprite:WasEventTriggered("Release") then
            npc.Velocity = (REVEL.Lerp(npc.Position, data.Corner, 0.2) - npc.Position) / 2
            data.IsMoving = true
        end

        if sprite:IsFinished("WrapUp") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.State = "Wrapped"
        end
    elseif data.State == "Idle" then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.CollisionDamage = 1

        if sprite:IsEventTriggered("Release") then
            data.Invulnerable = false
        end

        if sprite:WasEventTriggered("Release") then
            data.IsMoving = true
            npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position):Resized(0.3)
        end

        if not sprite:IsPlaying("Idle") and not sprite:IsPlaying("Release") then
            sprite:Play("Idle", true)
        end

        if sprite:IsPlaying("Idle") then
            data.Invulnerable = false
            local variant = npc.Variant
            local targetDiff = npc.Position - target.Position
            local targetDiffNormal = targetDiff:Normalized()
            local idealYarnPos = data.Yarn.Position + targetDiffNormal * (npc.Size + data.Yarn.Size)

            local catsCloseToAlign
            local numIdeallyAligned = 0

            if data.IsChampion then
                local numAlign = 0
                for _, cat in ipairs(activeCats) do
                    local facing, align = REVEL.GetAlignment(cat.Position, target.Position)
                    if align < 60 then
                        numAlign = numAlign + 1
                    end

                    if align < 30 then
                        numIdeallyAligned = numIdeallyAligned + 1
                    end
                end

                if numAlign >= 2 then
                    catsCloseToAlign = true
                end
            end

            if variant == REVEL.ENT.CATASTROPHE_CRICKET.variant then
                npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position):Resized(0.3)
            elseif variant == REVEL.ENT.CATASTROPHE_TAMMY.variant or catsCloseToAlign then
                if data.IsChampion then
                    local usingDiff
                    if math.abs(targetDiff.X) < math.abs(targetDiff.Y) then
                        usingDiff = Vector(targetDiff.X, 0)
                    else
                        usingDiff = Vector(0, targetDiff.Y)
                    end

                    usingDiff:Resize(135)
                    REVEL.MoveRandomly(npc, 20, 6, 12, 0.2, 0.9, target.Position + usingDiff)
                else
                    local diffResized = targetDiffNormal * 135
                    local valid
                    while not valid do
                        local pos = target.Position + diffResized
                        if REVEL.room:IsPositionInRoom(pos, 0) then
                            valid = true
                        else
                            diffResized = diffResized:Rotated(5)
                        end
                    end
                    local target = target.Position + diffResized
                    REVEL.MoveRandomly(npc, 20, 6, 12, 0.2, 0.9, target)
                end
            elseif variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                local diffResized = targetDiffNormal * 200
                local valid
                while not valid do
                    local pos = target.Position + diffResized
                    if REVEL.room:IsPositionInRoom(pos, 0) then
                        valid = true
                    else
                        diffResized = diffResized:Rotated(5)
                    end
                end
                local target = target.Position + diffResized
                REVEL.MoveRandomly(npc, 20, 6, 12, 0.2, 0.9, target)
            elseif variant == REVEL.ENT.CATASTROPHE_MOXIE.variant then
                npc.Velocity = npc.Velocity * 0.9 + (idealYarnPos - npc.Position):Resized(0.6)
            end

            if data.AttackBCooldown then
                data.AttackBCooldown = data.AttackBCooldown - 1
            end

            if data.AttackCooldown then
                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    data.AttackCooldown = nil
                end
            else
                local attacks = {}

                if variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
                    if variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                        attacks.Shoot = 2
                    else
                        attacks.Shoot = 3
                    end
                end

                if not data.AllCatsPhaseTwo and not isSwipingCat and variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
                    attacks.Swipe = 1
                end

                if (variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant and target.Position:DistanceSquared(npc.Position) <= 120 ^ 2) or npc.Position:DistanceSquared(idealYarnPos) < (npc.Size + data.Yarn.Size) ^ 2 then
                    attacks.SwipeOnce = 4
                end

                local noSpecial
                if #activeCats > 1 and catsCloseToAlign then
                    for _, cat in ipairs(activeCats) do
                        if cat.Variant == REVEL.ENT.CATASTROPHE_TAMMY.variant then
                            noSpecial = true
                        end
                    end
                end

                if noSpecial then
                    attacks.DoNothing = 16
                elseif data.IsChampion and not isSwipingCat and variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
                    attacks.Swipe = 3
                end

                if not IsBAttackActive(data.Cats) and (not data.AttackBCooldown or data.AttackBCooldown <= 0) then
                    if (variant == REVEL.ENT.CATASTROPHE_CRICKET.variant or variant == REVEL.ENT.CATASTROPHE_TAMMY.variant) then
                        if target.Position:Distance(npc.Position) > 100 and not noSpecial then
                            attacks.Chase = 2
                        end

                        if variant == REVEL.ENT.CATASTROPHE_TAMMY.variant and #activeCats ~= 1 then
                            attacks.TammyHowl = 2

                            if numIdeallyAligned == #activeCats then
                                attacks.TammyHowl = 9
                            end
                        end
                    elseif variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                        local flies = Isaac.CountEntities(npc, EntityType.ENTITY_ATTACKFLY, -1, -1) or 0
                        local maxBallFlies = 9
                        if #activeCats > 2 then
                            maxBallFlies = 6
                        end

                        if flies < maxBallFlies then
                            attacks.FlyBall = 2
                        end

                        if #activeCats > 1 and data.PreviousAttack ~= "GuppyBrimstone" then
                            attacks.GuppyBrimstone = 2
                        end
                    elseif variant == REVEL.ENT.CATASTROPHE_MOXIE.variant and data.PreviousAttack ~= "Spin" and data.PreviousAttack ~= "SpinSpecial" and not noSpecial then
                        attacks.Spin = 2
                        if #activeCats > 2 then
                            attacks.SpinSpecial = 2
                        end

                        if data.IsChampion and #activeCats > 1 then
                            attacks.SpinSpecial = 4
                            attacks.Spin = 0
                        end
                    end
                end

                if variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                    local flies = Isaac.CountEntities(npc, EntityType.ENTITY_ATTACKFLY, -1, -1) or 0
                    local maxFlies = 7
                    if #activeCats > 2 then
                        maxFlies = 4
                    end

                    if flies >= maxFlies then
                        attacks.Shoot = nil
                    end
                end

                local hasAttack = next(attacks)

                if hasAttack then
                    if data.PreviousAttack then
                        if attacks[data.PreviousAttack] then
                            attacks[data.PreviousAttack] = math.max(1, attacks[data.PreviousAttack] - 2)
                        end
                    end

                    local attack = REVEL.WeightedRandom(attacks)

                    if attack == "Shoot" then
                        sprite:Play("Shoot", true)
                        data.State = "Shoot"

                        if variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                            data.AttackCooldown = math.random(50, 80)
                        elseif variant == REVEL.ENT.CATASTROPHE_TAMMY.variant then
                            data.NumShots = nil
                            data.AttackCooldown = math.random(60, 90)
                        end
                    elseif attack == "Swipe" then
                        sprite:Play("Swipe", true)
                        data.State = "Swipe"
						if variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
                            REVEL.PlaySound(npc, data.bal.Sounds.ReadyClaws)
						end
                    elseif attack == "SwipeOnce" then
                        sprite:Play("SwipeOnce", true)
                        data.State = "Swipe"
						if variant ~= REVEL.ENT.CATASTROPHE_MOXIE.variant then
							REVEL.PlaySound(npc, data.bal.Sounds.ReadyClaws)
						end
                        if variant == REVEL.ENT.CATASTROPHE_MOXIE.variant then
                            data.AttackCooldown = 15
                        end
                    elseif attack == "FlyBall" then
                        sprite:Play("FlyBall", true)
                        data.State = "FlyBall"
                        data.AttackCooldown = math.random(50, 80)
                        SetBMinCooldown(data.Cats, 75)
                        data.AttackBCooldown = 150
                    elseif attack == "Chase" then
                        if variant == REVEL.ENT.CATASTROPHE_CRICKET.variant then
                            data.State = "CricketFly"
                            sprite:Play("FlyUp", true)
                        else
                            data.State = "TammyChase"
                            sprite:Play("ChaseStart", true)
                        end

                        REVEL.PlaySound(npc, data.bal.Sounds.Attack, nil, nil, nil, data.bal.Pitch[npc.Variant])

                        data.AttackCooldown = math.random(60, 90)
                        SetBMinCooldown(data.Cats, 75)
                    elseif attack == "Spin" or attack == "SpinSpecial" then
                        if attack == "SpinSpecial" then
                            data.SpinSpecial = true
                        end

                        data.State = "MoxieSpin"
                        sprite:Play("SpinStart", true)
                        data.AttackCooldown = math.random(60, 90)
                        SetBMinCooldown(data.Cats, 75)
                        data.AttackBCooldown = 150
                    elseif attack == "TammyHowl" then
                        data.State = "TammyHowl"
                        sprite:Play("Howl", true)
                        data.AttackCooldown = math.random(60, 90)
                        SetBMinCooldown(data.Cats, 45)
                    elseif attack == "GuppyBrimstone" then
                        data.State = "GuppyBrimstone"
                        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MOUTH_FULL, 0.7, 0, false, 1.1)
                        sprite:Play("BrimstoneStart", true)
                        data.AttackCooldown = math.random(60, 90)
                        SetBMinCooldown(data.Cats, 75)
                    elseif attack == "DoNothing" then
                        data.AttackCooldown = 5
                    end

                    data.PreviousAttack = attack

                    if attack and not data.AttackCooldown then
                        data.AttackCooldown = math.random(30, 60)
                    end

                    if data.AttackCooldown and attack ~= "DoNothing" then
                        if data.IsChampion then
                            SetMinAttackCooldown(data.Cats, math.floor(data.AttackCooldown * 0.5))
                        else
                            SetMinAttackCooldown(data.Cats, math.floor(data.AttackCooldown * 0.75))
                        end
                    end
                end
            end

            data.IsMoving = true
        end
    elseif data.State == "Swipe" then
        if sprite:IsEventTriggered("Swipe") then
            local targ = target.Position

            local targetDiff = npc.Position - target.Position
            local idealYarnPos = data.Yarn.Position + targetDiff:Resized(npc.Size + data.Yarn.Size)

            if npc.Position:DistanceSquared(idealYarnPos) < (npc.Size + data.Yarn.Size) ^ 2 then
                targ = data.Yarn.Position
                REVEL.PlaySound(npc, data.bal.Sounds.HitYarn)
            end

            npc.Velocity = (targ - npc.Position):Resized(14)
            REVEL.PlaySound(npc, data.bal.Sounds.Swipe)
        end

        if sprite:WasEventTriggered("Swipe") then
            if npc.Velocity:LengthSquared() > 7 ^ 2 then
                if data.Yarn.Position:DistanceSquared(npc.Position) < (npc.Size + data.Yarn.Size) ^ 2 then
                    data.Yarn:GetData().LastStruckByCat = true
                    data.Yarn.Velocity = npc.Velocity:Resized(18)

                    if not data.HitYarnSound then
                        data.HitYarnSound = true
                        REVEL.PlaySound(npc, data.bal.Sounds.HitYarn)
                    end
                end
            end
        else
            data.HitYarnSound = nil
        end

        if sprite:IsFinished("Swipe") or sprite:IsFinished("SwipeOnce") then
            data.State = "Idle"
        end
    elseif data.State == "Shoot" then
        if sprite:IsEventTriggered("Shoot") then
            local variant = npc.Variant
            if variant == REVEL.ENT.CATASTROPHE_GUPPY.variant then
                REVEL.PlaySound(npc, data.bal.Sounds.Cough, nil, nil, nil, data.bal.Pitch[npc.Variant])
                local dir = (target.Position - npc.Position):Resized(17.5)
                for i = -1, 1 do
                    local fly = Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, npc.Position, dir:Rotated(45 * i), npc)
                    fly.SpawnerEntity = npc
                    fly.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    fly:GetData().CatastropheSpawned = true
                    fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                end
            elseif variant == REVEL.ENT.CATASTROPHE_CRICKET.variant then
                REVEL.PlaySound(npc, data.bal.Sounds.Cough, nil, nil, nil, data.bal.Pitch[npc.Variant])
                npc.Velocity = npc.Velocity * 0.9 + (npc.Position-target.Position):Resized(6)
                local p = Isaac.Spawn(9, 0, 0, npc.Position, (target.Position - npc.Position):Resized(12), npc):ToProjectile()
                p.FallingSpeed = -2
                p.FallingAccel = -0.04
                p.Scale = 3
                p:AddProjectileFlags(ProjectileFlags.SMART)
                p:Update()
                p.ProjectileFlags = 0
                data.CricketHomingProjectile = p
            else
                if not data.NumShots then
                    data.NumShots = 0
                end

                data.NumShots = data.NumShots + 1
                if data.NumShots == 1 then
                    REVEL.PlaySound(npc, data.bal.Sounds.Attack, nil, nil, nil, data.bal.Pitch[npc.Variant])
                    REVEL.PlaySound(npc, SoundEffect.SOUND_BLOODSHOOT, 0.7, 0, false, 1)
                    for i=1, 4 do
                        Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(90 * i) * 10, npc)
                    end
                elseif data.NumShots == 2 then
                    REVEL.PlaySound(npc, data.bal.Sounds.Attack, nil, nil, nil, data.bal.Pitch[npc.Variant])
                    REVEL.PlaySound(npc, SoundEffect.SOUND_BLOODSHOOT, 0.7, 0, false, 1)
                    for i=1, 4 do
                        Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(45 + 90 * i) * 10, npc)
                    end
                elseif data.NumShots == 3 then
                    REVEL.PlaySound(npc, data.bal.Sounds.Cough, nil, nil, nil, data.bal.Pitch[npc.Variant])
                    for i=1, 8 do
                        Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(45  *i) * 10, npc)
                    end

                    data.NumShots = nil
                end
            end
        end

        if sprite:IsFinished("Shoot") then
            data.State = "Idle"
        end
    elseif data.State == "TammyChase" then
        if sprite:IsFinished("ChaseStart") then
            REVEL.PlaySound(npc, data.bal.Sounds.Attack, nil, nil, nil, data.bal.Pitch[npc.Variant])
        end

        if not sprite:IsPlaying("ChaseStart") then
            local anim = "ChaseLoopRight"
            if target.Position.X < npc.Position.X then
                anim = "ChaseLoopLeft"
            end

            if not sprite:IsPlaying(anim) then
                local frame = 0
                if sprite:IsPlaying("ChaseLoopLeft") or sprite:IsPlaying("ChaseLoopRight") then
                    frame = sprite:GetFrame()
                end

                sprite:Play(anim, true)

                if frame > 0 then
                    for i = 1, frame do
                        sprite:Update()
                    end
                end
            end

            data.IsMoving = true
            if npc:CollidesWithGrid() then
                REVEL.PlaySound(npc, data.bal.Sounds.Impact)
                REVEL.PlaySound(npc, SoundEffect.SOUND_BLOODSHOOT, 0.7, 0, false, 1)
                REVEL.game:ShakeScreen(10)
                for i=1, 8 do
                    Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(45 * i) * 10, npc)
                end
                data.State = "Idle"
            else
                npc.Velocity = npc.Velocity * 0.95 + (target.Position - npc.Position):Resized(1)
            end
        end
    elseif data.State == "CricketFly" then
        if sprite:IsEventTriggered("Shockwave") then
            REVEL.PlaySound(npc, data.bal.Sounds.Impact)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            for num = 1, 15 do
                local dir = Vector.FromAngle(num * 24)
                REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 4, nil, 25, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            end

            if data.Yarn.Position:DistanceSquared(npc.Position) < 100 ^ 2 then
                data.Yarn:GetData().LastStruckByCat = true
                data.Yarn.Velocity = (data.Yarn.Position - npc.Position):Resized(18)
                REVEL.PlaySound(npc, data.bal.Sounds.HitYarn)
            end
        end

        if sprite:IsEventTriggered("Flystart") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end

        if sprite:IsFinished("FlyUp") then
            sprite:Play("FlyLoop", true)
        end

        if sprite:IsPlaying("FlyLoop") or sprite:IsFinished("FlyLoop") then
            data.IsMoving = true
            npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position):Resized(0.8)
            if not data.FlyTimer then
                data.FlyTimer = 50
            end

            data.FlyTimer = data.FlyTimer - 1
            if data.FlyTimer <= 0 then
                npc.Velocity = Vector.Zero
                sprite:Play("FlyDown", true)
                data.FlyTimer = nil
            end
        end

        if sprite:IsFinished("FlyDown") then
            data.State = "Idle"
        end
    elseif data.State == "FlyBall" then
        if sprite:IsEventTriggered("Shoot") then
            REVEL.PlaySound(npc, data.bal.Sounds.Cough, nil, nil, nil, data.bal.Pitch[npc.Variant])
            local diff = (target.Position - npc.Position)
            local dist = diff:Length()
            local dir = (diff / dist) * 12
            local time = (dist / 12)
            local min, max = 4, 5
            if #activeCats > 2 then
                min, max = 2, 3
            end

            for i = 1, math.random(min, max) do
                local pos = npc.Position + RandomVector() * math.random() * 25
                local fly = Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, pos, dir, npc)
                fly.SpawnerEntity = npc
                fly.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                local fdata = fly:GetData()
                fdata.FallingSpeed = -3
                fdata.FallingAccel = 0.5
                fdata.CatastropheFlyDirection = dir
                fdata.CatastropheRelativeCenter = (pos - npc.Position):Resized(16)
                fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end
        end

        if sprite:IsFinished("FlyBall") then
            data.State = "Idle"
        end
    elseif data.State == "MoxieSpin" then
        if sprite:IsFinished("SpinStart") then
            data.SpinTimer = 150
            sprite:Play("SpinLoop", true)
        end

        if sprite:IsPlaying("SpinLoop") or sprite:WasEventTriggered("SpinStart") or (sprite:IsPlaying("SpinEnd") and not sprite:WasEventTriggered("SpinStop")) then
            data.IsMoving = true
            local targPos
            if not data.SpinSpecial or #activeCats == 1 then
                local targetDiff = npc.Position - target.Position
                local targetDiffNormal = targetDiff:Normalized()
                targPos = data.Yarn.Position + targetDiffNormal * (npc.Size + data.Yarn.Size)
            else
                if not data.HelpingCat or not data.HelpingCat:Exists() or not data.HelpTimer then
                    local validCats = {}
                    for _, cat in ipairs(activeCats) do
                        if GetPtrHash(cat) ~= GetPtrHash(npc) then
                            validCats[#validCats + 1] = cat
                        end
                    end

                    if #validCats > 0 then
                        data.HelpTimer = math.random(45, 90)
                        data.HelpingCat = validCats[math.random(1, #validCats)]
                    end
                end

                if data.HelpingCat then
                    local halfHelpTargetDiff = (target.Position - data.HelpingCat.Position) / 2
                    local len = halfHelpTargetDiff:Length()
                    if len > 80 then
                        halfHelpTargetDiff = (halfHelpTargetDiff / len) * 80
                    end

                    targPos = data.HelpingCat.Position + halfHelpTargetDiff
                end
            end

            if data.HelpTimer then
                data.HelpTimer = data.HelpTimer - 1
                if data.HelpTimer <= 0 then
                    data.HelpTimer = nil
                end
            end

            if data.TimeBetweenHits then
                data.TimeBetweenHits = data.TimeBetweenHits - 1
                if data.TimeBetweenHits <= 0 then
                    data.TimeBetweenHits = nil
                end
            end

            --[[for _, tear in ipairs(REVEL.roomTears) do
                if tear.Position:DistanceSquared(npc.Position) <= (tear.Size + 60) ^ 2 then
                    REVEL.AuraReflectTear(tear, target, npc)
                end
            end]]

            if data.SpinSpecial then
                npc.Velocity = npc.Velocity * 0.95 + (targPos - npc.Position):Resized(0.75)
            else
                npc.Velocity = npc.Velocity * 0.95 + (targPos - npc.Position):Resized(1)
            end

            if not data.TimeBetweenHits and data.Yarn.Position:DistanceSquared(npc.Position) < 60 ^ 2 then
                data.Yarn:GetData().LastStruckByCat = true
                local vec = ((target.Position-(target.Velocity:Resized(2))) - data.Yarn.Position):Resized(15)
                data.Yarn.Velocity = vec
                data.TimeBetweenHits = 10
                REVEL.PlaySound(npc, data.bal.Sounds.HitYarn)
            end

            if sprite:IsPlaying("SpinLoop") then
                data.SpinTimer = data.SpinTimer - 1
                if data.SpinTimer <= 0 then
                    data.SpinTimer = nil
                    sprite:Play("SpinEnd", true)
                end
            end
        end

        if sprite:IsFinished("SpinEnd") then
            data.SpinSpecial = nil
            data.State = "Idle"
        end
    elseif data.State == "TammyHowl" then
        if sprite:IsEventTriggered("Howl") then
            REVEL.PlaySound(npc, data.bal.Sounds.Attack, nil, nil, nil, data.bal.Pitch[npc.Variant])
            REVEL.PlaySound(npc, SoundEffect.SOUND_BLOODSHOOT, 0.7, 0, false, 1)
            for _, cat in ipairs(activeCats) do
                for i = 1, 4 do
                    Isaac.Spawn(9, 0, 0, cat.Position, Vector.FromAngle(90 * i) * 8, cat)
                end
            end
        end

        if sprite:IsFinished("Howl") then
            data.State = "Idle"
        end
    elseif data.State == "GuppyBrimstone" then
        if sprite:IsEventTriggered("Shoot") then
            local targetCat
            if #activeCats == 2 then
                for _, cat in ipairs(activeCats) do
                    if GetPtrHash(cat) ~= GetPtrHash(npc) then
                        targetCat = cat
                        break
                    end
                end
            else
                local validCats = {}
                for _, cat in ipairs(activeCats) do
                    if cat.Variant == REVEL.ENT.CATASTROPHE_MOXIE.variant then
                        targetCat = cat
                        break
                    elseif GetPtrHash(cat) ~= GetPtrHash(npc) then
                        validCats[#validCats + 1] = cat
                    end
                end

                if not targetCat and #validCats > 0 then
                    targetCat = validCats[math.random(1, #validCats)]
                end
            end

            local direction
            if targetCat.Position.Y < npc.Position.Y then
                direction = "Up"
            elseif targetCat.Position.X > npc.Position.X then
                direction = "Right"
            else
                direction = "Left"
            end

            local xOffset = 0
            if direction == "Right" then
                xOffset = 10
            elseif direction == "Left" then
                xOffset = -10
            end

            local angle = (targetCat.Position - npc.Position):GetAngleDegrees()
            data.Brimstone = EntityLaser.ShootAngle(1, npc.Position, angle, 60, Vector(xOffset, -50), npc)
            data.Brimstone.DepthOffset = 100
			local brimSprite = data.Brimstone:GetSprite()
            local laserColor = Color(1,1,1,1)
            laserColor:SetColorize(5,5,5,1)
            data.Brimstone:SetColor(laserColor, -1, 1, false, false)
            brimSprite:ReplaceSpritesheet(0, "gfx/effects/revel2/brimfly.png")
            brimSprite:ReplaceSpritesheet(1, "gfx/effects/revel2/brimfly.png")
            brimSprite:LoadGraphics()
			brimSprite:Play("LargeRedLaser", true)
			brimSprite.PlaybackSpeed = 1

            if direction == "Up" then
                data.Brimstone.DepthOffset = -100
            end

            data.Direction = direction
        end

        data.Direction = data.Direction or "Left"

        if sprite:IsFinished("BrimstoneStart") then
            sprite:Play("Brimstone" .. data.Direction .. "Loop", true)
        end

        if not sprite:IsPlaying("BrimstoneStart") and not data.Brimstone:Exists() then
            data.Direction = nil
            data.Brimstone = nil
            data.State = "Idle"
        end
    end

    if data.Brimstone and data.State ~= "GuppyBrimstone" then
        data.Brimstone:Remove()
    end

    if not data.Threshold then
        data.Threshold = (npc.MaxHitPoints - 100) * 0.67
    end

    if catsInPhaseTwo == #data.Cats - 1 then
        data.PhaseTwo = true
    end

    if not data.Wrapped and data.TimeSinceLastSwap then
        data.TimeSinceLastSwap = data.TimeSinceLastSwap + 1
    end

    if data.Invulnerable and not npc:HasEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS) then
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
    elseif not data.Invulnerable and npc:HasEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS) then
        npc:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
    end

	if sprite:IsEventTriggered("RipWrappings") then
        --REVEL.PlaySound(npc, data.bal.Sounds.Spawn, nil, nil, nil, data.bal.Pitch[npc.Variant])
        REVEL.PlaySound(npc, data.bal.Sounds.RipWrappings)
	end

    -- Transition to phase 2
    local shouldTransition

    if not data.PhaseTwo and (((npc.HitPoints - 100) <= data.Threshold and (not data.TimeSinceLastSwap or data.TimeSinceLastSwap > 240)) or (npc.HitPoints - 100) <= (npc.MaxHitPoints - 100) / 4) then
        data.Threshold = data.Threshold - ((npc.MaxHitPoints - 100) * 0.33)
        if (npc.HitPoints - 100) <= ((npc.MaxHitPoints - 100) / 4) then
            data.PhaseTwo = true
        end

        if not (catsInPhaseTwo + 1 == #data.Cats - 1) then
            REVEL.PlaySound(npc, data.bal.Sounds.Defeat, nil, nil, nil, data.bal.Pitch[npc.Variant])
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_SMALL, 0.7, 0, false, 1)
            local p = Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc)
            p:SetColor(Color(0.2,0.1,0.1,1), -1, 1, false, false)
            data.TimeSinceLastSwap = 0
            data.State = "WrapUp"
            data.LastWrapped = true
            data.Wrapped = true
            data.AttackCooldown = math.random(10, 20)
            sprite:Play("WrapUp", true)
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, catastrophe_NpcUpdate, REVEL.ENT.CATASTROPHE_CRICKET.id)

REVEL.AddEffectInitCallback(function(effect)
	local parent = effect:GetLastParent()
	if effect.SubType == 1 and parent and parent.Type == REVEL.ENT.CATASTROPHE_CRICKET.id then
		local sprite = effect:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/effects/revel2/brimfly_impact.png")
        sprite:LoadGraphics()
        sprite.Color = effect.Parent:GetColor()
	end
end, EffectVariant.LASER_IMPACT)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if data.CatastropheSpawned then
        local requireFrame = 10
        if type(data.CatastropheSpawned) ~= "boolean" then
            requireFrame = data.CatastropheSpawned
        end

        if npc.FrameCount > requireFrame then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.CatastropheSpawned = nil
        end
    elseif data.CatastropheFlyDirection then
        npc.Velocity = data.CatastropheFlyDirection
        local height = math.min(0, npc.SpriteOffset.Y + data.FallingSpeed)
        data.FallingSpeed = data.FallingSpeed + data.FallingAccel

        npc.SpriteOffset = Vector(0, height)
        if height == 0 then
            npc.Velocity = -data.CatastropheRelativeCenter
            data.CatastropheSpawned = npc.FrameCount + 13
            data.CatastropheFlyDirection = nil
        end
    end
end, EntityType.ENTITY_ATTACKFLY)

local function catastrophe_EntTakeDamage(_, ent, dmg, flag, source)
    if ent:GetData().Invulnerable then
        if ent.Variant == REVEL.ENT.CATASTROPHE_YARN.variant then
            REVEL.PlaySound(ent, ent:GetData().bal.Sounds.HitYarn)
        elseif not ent:GetData().ChampionGuppy then
            REVEL.BishopShieldEffect(ent, Vector(0,-15), Vector.One * 1.1)
        end

        return false
    elseif IsCat(ent.Variant) then
        if ent.HitPoints - dmg - REVEL.GetDamageBuffer(ent) <= 100 then
            ent.HitPoints = 100
            ent.CollisionDamage = 0
            local data = ent:GetData()
    		data.Invulnerable = true
            data.Wrapped = true
            if data.State ~= "WrapUp" and data.State ~= "Wrapped" then
                REVEL.PlaySound(ent, data.bal.Sounds.FinalDefeat, nil, nil, nil, data.bal.Pitch[ent.Variant])
    			REVEL.sfx:Stop(SoundEffect.SOUND_ULTRA_GREED_SPINNING)
        		data.State = "WrapUp"
        		ent:GetSprite():Play("WrapUp", true)
            end

    		return false
        elseif ent:GetData().IsChampion then
            ent.HitPoints = ent.HitPoints + dmg
            ent:GetData().Yarn.HitPoints = ent:GetData().Yarn.HitPoints - dmg
        end
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, catastrophe_EntTakeDamage, REVEL.ENT.CATASTROPHE_CRICKET.id)

--catastrophe reward
local catItemChance = 50
local canGrantCatastropheReward = false
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	canGrantCatastropheReward = false
end)
revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	canGrantCatastropheReward = true
end, REVEL.ENT.CATASTROPHE_YARN.id)

local CatItems = {
	CollectibleType.COLLECTIBLE_MAXS_HEAD,
	CollectibleType.COLLECTIBLE_TAMMYS_HEAD,
	CollectibleType.COLLECTIBLE_DEAD_CAT,
	CollectibleType.COLLECTIBLE_GUPPYS_PAW,
	CollectibleType.COLLECTIBLE_GUPPYS_TAIL,
	CollectibleType.COLLECTIBLE_GUPPYS_HEAD,
	CollectibleType.COLLECTIBLE_GUPPYS_HAIRBALL,
	CollectibleType.COLLECTIBLE_GUPPYS_COLLAR,
	CollectibleType.COLLECTIBLE_CRICKETS_BODY,
	REVEL.ITEM.MOXIE.id,
	REVEL.ITEM.MOXIE_YARN.id
}
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, velocity, spawner, seed)
	if canGrantCatastropheReward and type == 5 and variant == 100 then
		canGrantCatastropheReward = false
		local currentRoom = StageAPI.GetCurrentRoom()
		local boss = nil
		if currentRoom then
			boss = StageAPI.GetBossData(currentRoom.PersistentData.BossID)
		end
		if boss and (boss.Name == "Catastrophe" or boss.NameTwo == "Catastrophe") then
			local rng = REVEL.RNG()
			rng:SetSeed(seed, 0)
			if rng:RandomInt(100)+1 <= catItemChance then
				local spawnableCatItems = {}
				for i=1, #CatItems do
					if not REVEL.OnePlayerHasCollectible(CatItems[i]) then
						spawnableCatItems[#spawnableCatItems+1] = CatItems[i]
					end
				end
				if #spawnableCatItems > 0 then
					return {type, variant, spawnableCatItems[rng:RandomInt(#spawnableCatItems-1)+1], seed}
				end
			end
		end
	end
end)

end