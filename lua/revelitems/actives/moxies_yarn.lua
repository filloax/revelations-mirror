local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------------
-- MOXIE'S YARN --
------------------

local potentialYarnCats = {
    "moxie",
    "tammy",
    "cricket",
    "guppy"
}

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if player:GetActiveItem() == itemID then
        local data = player:GetData()

        local isFreeCat
        for _, catName in ipairs(potentialYarnCats) do
            if not data.CurrentCats or not data.CurrentCats[catName] then
                isFreeCat = true
                break
            end
        end

        REVEL.RefundActiveCharge(player)

        if isFreeCat then
            REVEL.ToggleShowActive(player)
        end
    end
end, REVEL.ITEM.MOXIE_YARN.id)

for _, name in ipairs(potentialYarnCats) do
    potentialYarnCats[name] = {
        Name = name,
        Anm2 = "gfx/bosses/revel2/catastrophe/" .. name .. ".anm2"
    }
end

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()

    if REVEL.GetShowingActive(player) == REVEL.ITEM.MOXIE_YARN.id then
        local fireDirection = player:GetFireDirection()
        if fireDirection ~= Direction.NO_DIRECTION then
            REVEL.HideActive(player)
        REVEL.ConsumeActiveCharge(player)

            local velocity = Vector.Zero
            if fireDirection == Direction.LEFT then
                velocity = Vector(-12,0)
            elseif fireDirection == Direction.UP then
                velocity = Vector(0,-12)
            elseif fireDirection == Direction.RIGHT then
                velocity = Vector(12,0)
            elseif fireDirection == Direction.DOWN then
                velocity = Vector(0,12)
            end

            data.isHoldingMoxiesYarn = false

            local catNames = {}

            for _, catName in ipairs(potentialYarnCats) do
                if not data.CurrentCats or not data.CurrentCats[catName] then
                    catNames[#catNames + 1] = catName
                end
            end

            if #catNames > 0 then
                local ball = Isaac.Spawn(REVEL.ENT.MOXIE_YARN_BALL.id, REVEL.ENT.MOXIE_YARN_BALL.variant, 0, player.Position, velocity, player)
                ball:GetSprite():Play("Fall", true)
                ball.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

                local selectedCatName = catNames[math.random(1, #catNames)]

                local cat = Isaac.Spawn(REVEL.ENT.MOXIE_YARN_CAT.id, REVEL.ENT.MOXIE_YARN_CAT.variant, 0, REVEL.room:GetCenterPos() + RandomVector() * 500, Vector.Zero, player)
                cat:GetData().Name = selectedCatName
                cat:GetData().Yarn = ball
                cat:GetData().Player = player
                cat:GetData().State = "InitialReachYarn"
                cat:GetSprite():Load(potentialYarnCats[selectedCatName].Anm2, true)
                cat:GetSprite():Play("Idle", true)
                cat.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

                if not data.CurrentCats then
                    data.CurrentCats = {}
                end

                data.CurrentCats[selectedCatName] = {
                    HitPoints = 100,
                    Timer = 30 * 45
                }
            end
        end
    end

    if data.CurrentCats then
        for name, catData in pairs(data.CurrentCats) do
            catData.Timer = catData.Timer - 1
            if catData.Timer <= 0 or not catData.HitPoints or catData.HitPoints < 0 then
                data.CurrentCats[name] = nil
            end
        end

        if not next(data.CurrentCats) then
            data.CurrentCats = nil
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    for _, player in ipairs(REVEL.players) do
        local currentCats = player:GetData().CurrentCats
        if currentCats then
            local ball = Isaac.Spawn(REVEL.ENT.MOXIE_YARN_BALL.id, REVEL.ENT.MOXIE_YARN_BALL.variant, 0, Isaac.GetFreeNearPosition(player.Position, 40), Vector.Zero, player)
            ball.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

            for name, catData in pairs(currentCats) do
                local cat = Isaac.Spawn(REVEL.ENT.MOXIE_YARN_CAT.id, REVEL.ENT.MOXIE_YARN_CAT.variant, 0, player.Position + RandomVector() * math.random(40, 80), Vector.Zero, player)
                cat:GetData().Name = name
                cat:GetData().Yarn = ball
                cat:GetData().Player = player
                cat:GetData().State = "Idle"
                cat:GetSprite():Load(potentialYarnCats[name].Anm2, true)
                cat.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local data, sprite = effect:GetData(), effect:GetSprite()
    if not sprite:IsPlaying("Fall") then
        REVEL.AnimateWalkFrame(sprite, effect.Velocity, {
            Right = "RollRight",
            Left = "RollLeft",
            Up = "RollUp",
            Down = "RollDown"
        })
        sprite.PlaybackSpeed = REVEL.Lerp(0, 1, effect.Velocity:LengthSquared() / 5 ^ 2)
        if effect.Velocity:LengthSquared() > 10 then
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and enemy.Position:DistanceSquared(effect.Position) < (effect.Size + enemy.Size) ^ 2 then
                    enemy:TakeDamage(5, 0, EntityRef(effect), 0)
                    if data.LastHitBy and data.LastHitBy:Exists() and data.LastHitBy:GetData().State ~= "Wrapped" and data.LastHitBy:GetData().State ~= "Dead" then
                        enemy:GetData().HitByMoxieYarnCat = data.Cat
                        enemy:GetData().HitByMoxieYarnCatTimer = nil
                    end
                end
            end
        end

        for _, projectile in ipairs(REVEL.roomProjectiles) do
            if projectile.Position:DistanceSquared(effect.Position) < (effect.Size + projectile.Size) ^ 2 then
                projectile:Die()
            end
        end

        for _, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(effect.Position) < (effect.Size + player.Size) ^ 2 then
                effect:AddVelocity((effect.Position - player.Position):Resized(player.Velocity:Length() * 2))
                effect:GetData().LastHitBy = player
            end
        end
    end

    if sprite:IsEventTriggered("Land") then
        effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
    end

    effect.Velocity = effect.Velocity * 0.975
end, REVEL.ENT.MOXIE_YARN_BALL.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data, sprite = eff:GetData(), eff:GetSprite()

    eff.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    local endTammyChase
    if data.State == "InitialReachYarn" then
        if not sprite:IsPlaying("Swipe") then
            sprite:Play("Swipe", true)
            REVEL.sfx:Play(REVEL.SFX.CAT_READYING_CLAWS,0.3)
        end

        eff.Velocity = eff.Velocity * 0.9
    elseif data.State == "ReachedYarn" then
        if not sprite:IsPlaying("Swipe") then
            data.State = "Idle"
        end

        eff.Velocity = eff.Velocity * 0.9
    elseif data.State == "Idle" then
        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        local target = REVEL.getClosestEnemy(eff, false, true, true, true)
        if target then
            local targetDist, yarnDist = target.Position:DistanceSquared(eff.Position), data.Yarn.Position:DistanceSquared(eff.Position)
            if targetDist > yarnDist then
                local targetDiff = eff.Position - (target.Position + target.Velocity * 40)
                local targetDiffNormal = targetDiff:Normalized()
                local idealYarnPos = data.Yarn.Position + targetDiffNormal * (eff.Size + data.Yarn.Size)
                if eff.Position:DistanceSquared(idealYarnPos) < (eff.Size + data.Yarn.Size) ^ 2 then
                    data.State = "YarnSwipe"
                    sprite:Play("SwipeOnce", true)
                    REVEL.sfx:Play(REVEL.SFX.CAT_READYING_CLAWS,0.3)
                else
                    eff.Velocity = eff.Velocity * 0.9 + (idealYarnPos - eff.Position):Resized(0.6 + math.random() * 0.2)
                end
            else
                if targetDist < 50 ^ 2 then
                    eff.Velocity = eff.Velocity * 0.9 + (eff.Position - target.Position):Resized(0.6 + math.random() * 0.2)
                elseif targetDist < 150 ^ 2 then
                    data.State = "Swipe"
                    sprite:Play("SwipeOnce", true)
                    REVEL.sfx:Play(REVEL.SFX.CAT_READYING_CLAWS,0.3)
                else
                    eff.Velocity = eff.Velocity * 0.9 + (target.Position - eff.Position):Resized(0.3 + math.random() * 0.2)
                end
            end

            if data.State == "Idle" then
                if not data.AttackCooldown then
                    data.AttackCooldown = math.random(45, 75)
                end

                data.AttackCooldown = data.AttackCooldown - 1
                if data.AttackCooldown <= 0 then
                    if data.Name == "cricket" then
                        if targetDist < yarnDist and targetDist > 150 ^ 2 then
                            data.State = "CricketShoot"
                            sprite:Play("Shoot", true)
                        end
                    elseif data.Name == "tammy" then
                        if targetDist > 200 ^ 2 then
                            data.State = "TammyChase"
                            sprite:Play("ChaseStart", true)
                        end
                    elseif data.Name == "moxie" then
                        if yarnDist > 75 ^ 2 and yarnDist < targetDist then
                            data.State = "MoxieSpin"
                            sprite:Play("SpinStart", true)
                        end
                    elseif data.Name == "guppy" then
                        if targetDist < yarnDist and targetDist > 150 ^ 2 then
                            data.State = "GuppyShoot"
                            sprite:Play("Shoot", true)
                        end
                    end

                    if data.State ~= "Idle" then
                        data.AttackCooldown = math.random(45, 75)
                    end
                end
            end
        else
            if eff.Position:DistanceSquared(data.Player.Position) > 150 ^ 2 then
                eff.Velocity = eff.Velocity * 0.9 + (data.Player.Position - eff.Position):Resized(0.3 + math.random() * 0.2)
            else
                eff.Velocity = eff.Velocity * 0.9
            end
        end
    elseif data.State == "Swipe" or data.State == "YarnSwipe" then
        if sprite:IsFinished("SwipeOnce") then
            data.State = "Idle"
        end

        eff.Velocity = eff.Velocity * 0.9
    elseif data.State == "Dead" then
        eff.Velocity = Vector.Zero
        if sprite:IsFinished("SpecialDie") then
            eff:Remove()
        end
    elseif data.State == "GuppyShoot" then
        if sprite:IsFinished("Shoot") then
            data.State = "Idle"
        end

        if sprite:IsEventTriggered("Shoot") then
            for i = -1, 1 do
                local target = REVEL.getClosestEnemy(eff, false, true, true, true) or data.Player
                local fly = data.Player:AddBlueFlies(1, eff.Position, target)
                fly.Velocity = (target.Position - fly.Position):Resized(10):Rotated(45 * i)
            end
            REVEL.sfx:Play(REVEL.SFX.CATASTROPHE_COUGH,0.8)
        end

        eff.Velocity = eff.Velocity * 0.9
    elseif data.State == "CricketShoot" then
        if sprite:IsFinished("Shoot") then
            data.State = "Idle"
        end

        if sprite:IsEventTriggered("Shoot") then
            local target = REVEL.getClosestEnemy(eff, false, true, true, true)
            if target then
                data.HomingTear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, eff.Position, (target.Position - eff.Position):Resized(10), eff):ToTear()
                data.HomingTear.TearFlags = TearFlags.TEAR_HOMING | TearFlags.TEAR_SPECTRAL
                data.HomingTear.Scale = 2
                data.HomingTear:Update()
            end
            REVEL.sfx:Play(REVEL.SFX.CATASTROPHE_ATTACK,0.8)
        end

        eff.Velocity = eff.Velocity * 0.9
    elseif data.State == "MoxieSpin" then
        if sprite:IsFinished("SpinStart") then
            data.SpinTimer = 150
            sprite:Play("SpinLoop", true)
        end

        if sprite:IsPlaying("SpinLoop") or sprite:WasEventTriggered("SpinStart") or (sprite:IsPlaying("SpinEnd") and not sprite:WasEventTriggered("SpinStop")) then
            local target = REVEL.getClosestEnemy(eff, false, true, true, true)
            if not target then
                if sprite:IsPlaying("SpinLoop") then
                    sprite:Play("SpinEnd", true)
                end

                eff.Velocity = eff.Velocity * 0.9
            else
                local targetDiff = eff.Position - target.Position
                local targetDiffNormal = targetDiff:Normalized()
                local targPos = data.Yarn.Position + targetDiffNormal * (eff.Size + data.Yarn.Size)

                if data.TimeBetweenHits then
                    data.TimeBetweenHits = data.TimeBetweenHits - 1
                    if data.TimeBetweenHits <= 0 then
                        data.TimeBetweenHits = nil
                    end
                end

                eff.Velocity = eff.Velocity * 0.95 + (targPos - eff.Position):Resized(1)

                if not data.TimeBetweenHits and data.Yarn.Position:DistanceSquared(eff.Position) < 60 ^ 2 then
                    data.Yarn.Velocity = (target.Position - data.Yarn.Position):Resized(18)
                    data.Yarn:GetData().LastHitBy = eff
                    data.TimeBetweenHits = 10
                    REVEL.sfx:Play(REVEL.SFX.CAT_KNOCKING_BALL)
                end

                if sprite:IsPlaying("SpinLoop") then
                    data.SpinTimer = data.SpinTimer - 1
                    if data.SpinTimer <= 0 then
                        data.SpinTimer = nil
                        sprite:Play("SpinEnd", true)
                    end
                end
            end
        else
            eff.Velocity = eff.Velocity * 0.9
        end

        if sprite:IsFinished("SpinEnd") then
            data.State = "Idle"
        end
    elseif data.State == "TammyChase" then
        local target = REVEL.getClosestEnemy(eff, false, true, true, true)
        if sprite:IsFinished("ChaseStart") then
            REVEL.sfx:Play(REVEL.SFX.CATASTROPHE_ATTACK,0.8)
        end

        if not sprite:IsPlaying("ChaseStart") then
            if not target then
                data.State = "Idle"
            else
                eff.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                local anim = "ChaseLoopRight"
                if target.Position.X < eff.Position.X then
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

                if eff:CollidesWithGrid() then
                    endTammyChase = true
                else
                    eff.Velocity = eff.Velocity * 0.95 + (target.Position - eff.Position):Resized(1)
                end
            end
        else
            if target then
                eff.Velocity = eff.Velocity * 0.9 + (target.Position - eff.Position):Resized(0.1)
            else
                eff.Velocity = eff.Velocity * 0.9
            end
        end
    elseif data.State == "Wrapped" then
        eff.Velocity = Vector.Zero
        if not sprite:IsPlaying("WrapUp") and not sprite:IsPlaying("WrappedIdle") then
            sprite:Play("WrappedIdle", true)
        end
    end

    if data.State ~= "Dead" and data.State ~= "Wrapped" then
        if data.HomingTear then
            if data.HomingTear:Exists() and not data.HomingTear:IsDead() then
                local target = REVEL.getClosestEnemy(data.HomingTear, false, true, true, true)
                if target then
                    data.HomingTear.Velocity = data.HomingTear.Velocity * 0.9 + (target.Position - data.HomingTear.Position):Resized(1.1)
                end
            else
                data.HomingTear = nil
            end
        end

        local pdata = data.Player:GetData()
        if not pdata.CurrentCats or not pdata.CurrentCats[data.Name] then
            endTammyChase = nil
            data.State = "Wrapped"
            eff.Velocity = Vector.Zero
            sprite:Play("WrapUp", true)
            REVEL.sfx:Play(REVEL.SFX.CATASTROPHE_DEFEAT)
        else
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and enemy.Position:DistanceSquared(eff.Position) < (eff.Size + enemy.Size) ^ 2 then
                    local damage = 1
                    if data.State == "TammyChase" and not sprite:IsPlaying("ChaseStart") then
                        damage = 10
                        endTammyChase = true
                    else
                        if eff.Velocity:LengthSquared() > 7 ^ 2 then
                            damage = 2.5
                        else
                            pdata.CurrentCats[data.Name].HitPoints = pdata.CurrentCats[data.Name].HitPoints - 1
                        end
                    end

                    enemy:TakeDamage(damage, 0, EntityRef(eff), 0)
                    enemy:GetData().HitByMoxieYarnCat = eff
                    enemy:GetData().HitByMoxieYarnCatTimer = nil
                end
            end

            for _, projectile in ipairs(REVEL.roomProjectiles) do
                if projectile.Position:DistanceSquared(eff.Position) < (eff.Size + projectile.Size) ^ 2 then
                    projectile:Die()
                    pdata.CurrentCats[data.Name].HitPoints = pdata.CurrentCats[data.Name].HitPoints - 1
                end
            end

            if pdata.CurrentCats[data.Name].HitPoints and pdata.CurrentCats[data.Name].HitPoints < 0 then
                endTammyChase = nil
                data.State = "Dead"
                sprite:Play("SpecialDie", true)
                REVEL.sfx:Play(REVEL.SFX.CATASTROPHE_DEFEAT)
                pdata.CurrentCats[data.Name].HitPoints = nil
            end

            if endTammyChase then
                REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
                REVEL.game:ShakeScreen(10)
                for i = 1, 8 do
                    Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, eff.Position, Vector.FromAngle(45 * i) * 10, eff)
                end
                data.State = "Idle"
            end

            if data.State ~= "MoxieSpin" and eff.Velocity:LengthSquared() > 7 ^ 2 and data.Yarn.Position:DistanceSquared(eff.Position) < (eff.Size + data.Yarn.Size) ^ 2 then
                data.Yarn.Velocity = eff.Velocity:Resized(18)
                data.Yarn:GetData().LastHitBy = eff
                if data.State == "InitialReachYarn" then
                    data.State = "ReachedYarn"
                end
                REVEL.sfx:Play(REVEL.SFX.CAT_KNOCKING_BALL)
            end

            if sprite:IsEventTriggered("Swipe") then
                local target = REVEL.getClosestEnemy(eff, false, true, true, true)
                if data.State == "InitialReachYarn" or data.State == "YarnSwipe" or not target then
                    eff.Velocity = (data.Yarn.Position - eff.Position):Resized(14)
                else
                    eff.Velocity = (target.Position - eff.Position):Resized(14)
                end
                REVEL.sfx:Play(REVEL.SFX.WHOOSH,0.8)
            end
        end
    end
end, REVEL.ENT.MOXIE_YARN_CAT.variant)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc:GetData().HitByMoxieYarnCat then
        local data = npc:GetData()
        if not data.HitByMoxieYarnCat:Exists() or data.HitByMoxieYarnCat:GetData().State == "Wrapped" or data.HitByMoxieYarnCat:GetData().State == "Dead" then
            data.HitByMoxieYarnCat = nil
            data.HitByMoxieYarnCatTimer = nil
        else
            npc.Target = data.HitByMoxieYarnCat
            if not data.HitByMoxieYarnCatTimer then
                data.HitByMoxieYarnCatTimer = 150
            else
                data.HitByMoxieYarnCatTimer = data.HitByMoxieYarnCatTimer - 1
                if data.HitByMoxieYarnCatTimer <= 0 then
                    data.HitByMoxieYarnCat = nil
                    data.HitByMoxieYarnCatTimer = nil
                end
            end
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()