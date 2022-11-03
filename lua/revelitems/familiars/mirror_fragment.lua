local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
------------------
-- MIRROR FRAGMENT --
------------------

-- Rotates above player's head, spins up while firing, launches on release
-- Depending on how much it has been charged, changes launch distance
-- When both are on the ground, they fire lasers between themselves when enemies pass through them

local SpinStage1 = 55 -- at 10 firedelay
local SpinStage2 = 110
local LerpDur = 5
local FloatToSpinDur = 5
local wColor = Color(1.3, 1.3, 1.3, 1, conv255ToFloat(255, 255, 255))
-- local slowColor = Color(0.9,0.8,1.2,1,conv255ToFloat(50,50,50))
local laserColor = Color(0, 1.5, 1.5, 1, conv255ToFloat(0, 230, 255))
local deadColor = Color(0.588, 0.588, 0.549, 1, conv255ToFloat(0, 0, 0))
local laserOffset = Vector(0, -10)
local laserCoolMax = 28 -- min time betweek lasers
local maxShots = 4
local enmDetectWidth = 5
local deadColorLerp = 5
local spinAnimLen = 23

local frags = {}
local stuckFrags = {}
local spinFrags = {}
local maxSpinFrags = 2

local function UpdateFrags()
    stuckFrags = {}
    spinFrags = {}
    frags = Isaac.FindByType(REVEL.ENT.MIRROR2.id, REVEL.ENT.MIRROR2.variant, -1, false, false)
    for i, v in ipairs(frags) do
        local data = v:GetData()
        if data.State == "Stuck" then
            local i = #stuckFrags + 1
            stuckFrags[i] = v
            data.stuckId = i
        elseif data.State == "Spin" and #spinFrags < maxSpinFrags then -- only used for syncing the animations, so FloatToSpin is not included as thats checked for in IsSpinFree only for more than 2 fragments purpose
            data.spinId = #spinFrags + 1
            spinFrags[data.spinId] = v
        end
    end
end

local function isSpinFree(fam, frags)
    local count = 0
    for i, v in ipairs(frags) do
        if fam.InitSeed ~= v.InitSeed 
        and (v:GetData().State == "Spin" or v:GetData().State == "FloatToSpin") then
            count = count + 1
            if count >= 2 then return false end
        end
    end
    return true
end

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local familiarMult = player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1
        player:CheckFamiliar(
            REVEL.ENT.MIRROR2.variant,
            2 * REVEL.ITEM.MIRROR2:GetCollectibleNum(player) * familiarMult, 
            RNG()
        )
    end
end)

local function StartSpin(fam, spr, data)
    data.State = "Spin"
    spr:Play("Spin", true)
    fam:RemoveFromFollowers()
    UpdateFrags()
    local next = spinFrags[data.spinId % #spinFrags + 1]
    if next then
        -- skip so that the new fragment is opposite to the old one
        REVEL.SkipAnimFrames(spr, next:GetSprite():GetFrame() + spinAnimLen / 2)
        data.spinCount = next:GetData().spinCount
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()
    fam.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    fam:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    data.spinCount = 0
    data.deadCount = deadColorLerp
end, REVEL.ENT.MIRROR2.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    UpdateFrags()
    for i, fam in ipairs(frags) do
        fam = fam:ToFamiliar()
        local spr, data = fam:GetSprite(), fam:GetData()
        data.spinId = nil
        if i <= 2 then
            StartSpin(fam, spr, data)
        else
            spr:Play("Float", true)
            data.State = "Follow"
            fam:AddToFollowers()
        end
        data.dead = false
        spr.Color = Color.Default
        data.deadCount = deadColorLerp
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.game:GetFrameCount() % 3 == 0 then UpdateFrags() end
end)

local laserCount = 0 -- shared between fragments
local laserShots = 0

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()

    if not data.Init then -- since FindByType doesn't include an entity until after its init call, we do that stuff here
        UpdateFrags()
        if isSpinFree(fam, frags) then
            fam.Position = fam.Player.Position
            fam.Velocity = fam.Player.Velocity
            StartSpin(fam, spr, data)
        else
            data.State = "Follow"
            spr:Play("Float", true)
            fam:AddToFollowers()
            UpdateFrags()
        end
        data.Init = true
    end

    if data.State == "Follow" then
        fam:FollowParent()
        if isSpinFree(fam, frags) then
            spr:Play("FloatToSpin", true)
            data.startPos = fam.Position
            fam:RemoveFromFollowers()
            data.State = "FloatToSpin"
            fam.SpriteOffset = Vector.Zero
        end
        fam.SpriteOffset = REVEL.GetYVector(math.sin(fam.FrameCount / 7) * 1.5)

    elseif data.State == "Spin" then
        fam.Velocity = fam.Player.Position - fam.Position
        local spinStageMult = REVEL.Lerp2(0.5, 1, math.min(
                                                fam.Player.MaxFireDelay, 25),
                                            3, 10)
        local spinStage1Scaled = SpinStage1 * spinStageMult
        local spinStage2Scaled = SpinStage2 * spinStageMult

        if fam.FrameCount % 3 == 0 then -- check not so often if there is more than 1 spinning fragment (box of friends for instance)
            if not isSpinFree(fam, frags) then
                data.State = "Follow"
                fam:AddToFollowers()
                spr:Play("Float", true)
            end
        end

        if REVEL.IsShooting(fam.Player) then
            if data.spinCount < spinStage2Scaled + LerpDur then
                data.spinCount = data.spinCount + 1
            end

            local clampedCnt = math.min(data.spinCount, spinStage2Scaled) -- actual count var is used by the white flash fading back to normal after reaching max speed

            -- Speed slightly increases constantly, and also increases a lot on each stage
            local boost1 = REVEL.SmoothLerp2(0, 0.4, clampedCnt,
                                                spinStage1Scaled - LerpDur,
                                                spinStage1Scaled)
            local boost2 = REVEL.SmoothLerp2(0, 0.4, clampedCnt,
                                                spinStage2Scaled - LerpDur,
                                                spinStage2Scaled)

            spr.PlaybackSpeed = REVEL.Lerp2(1, 1.2, clampedCnt, 1, spinStage2Scaled)
                + boost1 + boost2

            local wMultIn
            local wMultOut
            if clampedCnt < spinStage2Scaled - LerpDur then
                wMultIn = REVEL.SmoothStep(data.spinCount,
                                            spinStage1Scaled - LerpDur,
                                            spinStage1Scaled)
                wMultOut = 1 - REVEL.SmoothStep(data.spinCount,
                                                spinStage1Scaled,
                                                spinStage1Scaled + LerpDur)
            else
                wMultIn = REVEL.SmoothStep(data.spinCount,
                                            spinStage2Scaled - LerpDur,
                                            spinStage2Scaled)
                wMultOut = 1 - REVEL.SmoothStep(data.spinCount,
                                                spinStage2Scaled,
                                                spinStage2Scaled + LerpDur)
            end

            if data.spinCount == math.floor(spinStage1Scaled) then
                REVEL.sfx:Play(SoundEffect.SOUND_KEY_DROP0, 0.5, 0,
                                    false, 1.11)
            elseif data.spinCount == math.floor(spinStage2Scaled) then
                REVEL.sfx:Play(SoundEffect.SOUND_KEY_DROP0, 0.5, 0,
                                    false, 1.25)
                spr:ReplaceSpritesheet(0,
                                        "gfx/familiar/revelcommon/familiar_mirrorfragment_fast.png")
                spr:LoadGraphics()
            end

            spr.Color = Color.Lerp(wColor, Color.Default, 1 - wMultIn * wMultOut)
        else
            local distMult = 1
            if data.spinCount >= spinStage2Scaled then
                distMult = 3
            elseif data.spinCount >= spinStage1Scaled then
                distMult = 2
            end

            if data.spinCount > 0 and data.spinId == 1 then
                spr:Play("Launch", true)
                fam.Velocity = REVEL.GetLastFiringInput(fam.Player) * distMult * 13 + fam.Player.Velocity
                data.State = "Launch"
                fam.GridCollisionClass =
                    EntityGridCollisionClass.GRIDCOLL_GROUND

                spr.Color = Color.Default
                data.spinCount = 0
                spr.PlaybackSpeed = 1
                spr:ReplaceSpritesheet(0, "gfx/familiar/revelcommon/familiar_mirrorfragment.png")
                spr:LoadGraphics()
                for i = 2, #spinFrags do
                    spinFrags[i]:GetData().spinCount = 0
                    spinFrags[i]:GetSprite().PlaybackSpeed = 1
                    spinFrags[i].Color = Color.Default
                    spinFrags[i]:GetSprite():ReplaceSpritesheet(0, "gfx/familiar/revelcommon/familiar_mirrorfragment.png")
                    spinFrags[i]:GetSprite():LoadGraphics()
                end
                UpdateFrags() -- reassign spinid
            end
        end

    elseif data.State == "Launch" then
        if spr:WasEventTriggered("Stop") and
            not spr:WasEventTriggered("Stuck") then
            local closeEnms = Isaac.FindInRadius(fam.Position, 35, EntityPartition.ENEMY)
            for i, e in ipairs(closeEnms) do
                if e:IsVulnerableEnemy() and
                    not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and
                    e.Type ~= EntityType.ENTITY_SHOPKEEPER then
                    e:TakeDamage(fam.Player.Damage * 0.7, 0, EntityRef(fam),
                                    5)
                    if not e:IsBoss() then
                        e:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
                    end
                end
            end
        end
        if spr:IsEventTriggered("Stuck") then
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.5, 0, false, 0.7)
        end

        if spr:WasEventTriggered("Stop") then
            fam.Velocity = Vector.Zero
        end
        if spr:IsFinished("Launch") then
            spr:Play("Stuck", true)
            data.State = "Stuck"
            laserShots = 0
            UpdateFrags()
        end

    elseif data.State == "Stuck" then
        if data.dead then
            data.deadCount = math.max(0, data.deadCount - 1)
        else
            data.deadCount = math.min(deadColorLerp, data.deadCount + 1)
        end
        spr.Color = Color.Lerp(deadColor, Color.Default, data.deadCount / deadColorLerp)

        if fam.Player.Position:Distance(fam.Position) < fam.Player.Size + fam.Size then
            if isSpinFree(fam, frags) then
                spr:Play("Pickup", true)
            else
                spr:Play("PickupToFloat", true)
            end
            data.dead = false
            spr.Color = Color.Default
            data.deadCount = deadColorLerp
            data.State = "Pickup"
        end

    elseif data.State == "Pickup" then
        if spr:IsFinished("Pickup") then
            StartSpin(fam, spr, data)
        end
        if spr:IsFinished("PickupToFloat") then
            data.State = "Follow"
            fam:AddToFollowers()
            spr:Play("Float", true)
        end
    elseif data.State == "FloatToSpin" then
        local pos = REVEL.Lerp(data.startPos, fam.Player.Position,
                                spr:GetFrame() / FloatToSpinDur)
        fam.Velocity = pos - fam.Position
        if spr:IsFinished("FloatToSpin") then
            StartSpin(fam, spr, data)
        end
    end
end, REVEL.ENT.MIRROR2.variant)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if #stuckFrags < 2 then return end

    if laserCount > 0 then
        laserCount = laserCount - 1
        return
    end
    if laserShots >= maxShots then return end

    local enmCrossing = false

    for i, fam in ipairs(stuckFrags) do
        local data = fam:GetData()
        local prev = stuckFrags[((data.stuckId - 2) % #stuckFrags) + 1]
        local dir = prev.Position + laserOffset - fam.Position
        for j, e in ipairs(REVEL.roomEnemies) do
            if e:IsVulnerableEnemy() 
            and not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) 
            and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
            and not e:IsInvincible() 
            and REVEL.CollidesWithLine(e.Position, prev.Position, fam.Position, enmDetectWidth) then
                enmCrossing = true
                break
            end
        end
    end

    if enmCrossing then
        for i, fam in ipairs(stuckFrags) do
            if not (i == 1 and #stuckFrags == 2) then -- with 2 frags, only one needs to shoot for them to e connected
                fam = fam:ToFamiliar()
                local spr, data = fam:GetSprite(), fam:GetData()
                local prev = stuckFrags[((data.stuckId - 2) % #stuckFrags) + 1]
                local dir = prev.Position + laserOffset - fam.Position
                local angle = dir:GetAngleDegrees()
                local dist = dir:Length()

                local laser = EntityLaser.ShootAngle(2, fam.Position, angle, 3, laserOffset, fam)
                laser:GetSprite().Color = laserColor
                laser:SetMaxDistance(dist)
                laser.OneHit = true
                laser.CollisionDamage = fam.Player.Damage
                laser.Parent = fam

                laserCount = laserCoolMax

                data.dead = false -- reawaken any dead fragments in case of relaunch
                prev:GetData().dead = false
            end
        end

        laserShots = laserShots + 1
        if laserShots >= maxShots then
            for i, fam in ipairs(stuckFrags) do
                local data = fam:GetData()
                data.dead = true
            end
        end
    end
end)

--[[
REVEL.ITEM.MIRROR2:addPickupCallback(function()
    for i, p in ipairs(REVEL.players) do
        if REVEL.ITEM.MIRROR:PlayerHasCollectible(p) then
            p:RemoveCollectible(REVEL.ITEM.MIRROR.id, 1)
            return --so if players somehow got 2 they get to keep 1
        end
    end
end)
]]

end

REVEL.PcallWorkaroundBreakFunction()
