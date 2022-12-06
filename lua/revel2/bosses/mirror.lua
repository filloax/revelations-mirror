local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RandomPickupSubtype = require("lua.revelcommon.enums.RandomPickupSubtype")
local RevRoomType         = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local MusicPlayStartTime = -1

do -- Mirror Room
    function REVEL.RenderReflectionsTomb(eff, data)
        for i, ent in ipairs(REVEL.roomEffects) do --render effects before, so they don't overlap stuff
            if (ent.Visible or ent:GetData().ForceReflection) and ent.Variant ~= StageAPI.E.Door.V and not ent:GetData().NoReflect then
                REVEL.renderReflection(ent, data.alphaMult)
            end
        end

        local lateRenders = {}
        for i, ent in ipairs(REVEL.roomEntities) do
            if (ent.Visible or ent:GetData().ForceReflection) and ent.Type ~= 1000 and ent.Type ~= 1 and not ent:GetData().NoReflect then
                if ent:GetData().LateReflection then
                    lateRenders[#lateRenders + 1] = ent
                else
                    REVEL.renderReflection(ent, data.alphaMult)
                    if ent.Type == REVEL.ENT.NARCISSUS_2.id and ent.Variant == REVEL.ENT.NARCISSUS_2.variant then
                        REVEL.PostNarcissusReflectionRender(ent:ToNPC())
                    end
                end
            end
        end

        for _, ent in ipairs(lateRenders) do
            REVEL.renderReflection(ent, data.alphaMult)
            if ent.Type == REVEL.ENT.NARCISSUS_2.id and ent.Variant == REVEL.ENT.NARCISSUS_2.variant then
                REVEL.PostNarcissusReflectionRender(ent:ToNPC())
            end
        end
    end

    local SpikeCrackSprite = REVEL.LazyLoadRoomSprite{
        ID = "mirror2_SpikeCrack",
        Anm2 = "gfx/bosses/revel2/narcissus_2/glass_spike.anm2",
        OnCreate = function(sprite)
            for i = 0, 1 do
                sprite:ReplaceSpritesheet(i, "gfx/bosses/revel2/narcissus_2/glass_spike_cracks.png")
            end
            sprite:LoadGraphics()
        end,
    }

    function REVEL.RenderMirrorOverlaysTomb()
        local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
        for _, spike in ipairs(glassSpikes) do
            if spike.Visible and spike:GetData().Animation then
                SpikeCrackSprite.Scale = spike.SpriteScale
                SpikeCrackSprite.Color = spike.Color
                SpikeCrackSprite:SetFrame(spike:GetData().Animation, spike:GetSprite():GetFrame())
                SpikeCrackSprite:Render(Isaac.WorldToRenderPosition(spike.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
    end

    local TombMirrorBackdrop = {
        Walls = {"gfx/backdrop/revel2/mirror/mirror.png"}
    }

    function REVEL.TombLoadMirrorRoom()
        StageAPI.SetBossEncountered("Narcissus 2")
        StageAPI.ChangeBackdrop(TombMirrorBackdrop)
        REVEL.AddReflections(1, true, false)
        if not revel.data.run.NarcissusTombDefeated then
            local narc = Isaac.Spawn(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, 0, REVEL.player.Position, Vector.Zero, nil)
            REVEL.room:SetClear(false)

            if revel.data.seenNarcissusTomb then
                REVEL.DebugStringMinor("Playing narc 2 VS screen")
                local narcBoss = REVEL.find(REVEL.Bosses.ChapterTwo, 
                    function(boss) return boss.Name == "Narcissus 2" end)
                REVEL.music:Play(REVEL.SFX.MIRROR_BOSS_JINGLE, Options.MusicVolume)
                REVEL.PlayBossAnimationNoPause(narcBoss, function() --on skip
                    REVEL.StopMusicTrack(REVEL.SFX.MIRROR_BOSS_JINGLE)
                end)
            end
        end
    end

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, 1, function(stage, musicID, roomType, rng)
        if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR and REVEL.STAGE.Tomb:IsStage() then
            if not revel.data.run.NarcissusTombDefeated then
                return REVEL.SFX.MIRROR_BOSS_2
            else
                return REVEL.SFX.BOSS_CALM
            end
        end
    end)

    local WasPlaying = false

    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local musicID = REVEL.music:GetCurrentMusicID()
        if musicID == REVEL.SFX.MIRROR_BOSS_2 and not WasPlaying then
            MusicPlayStartTime = Isaac.GetTime()
            WasPlaying = true
        elseif musicID ~= REVEL.SFX.MIRROR_BOSS_2 and WasPlaying then
            MusicPlayStartTime = -1
            WasPlaying = false
        end
    end)
end


do -- Narcissus 2
    local megashardMinimumDistance = 30
    local lineDefaultScale = Vector(1, 1)
    local damagingLaserDefaultScale = Vector(1, 1)
    local triangleDefaultScale = Vector(0.25, 0.35)
    local circleDefaultScale = Vector(0.5, 0.5)
    local narc2Balance = {
        GroundPoundPlayerStun = 10,
        AboveMirrorWalkSpeed = 1.1,
        AboveMirrorWalkFriction = 0.8,
        TargetPlayerDistance = 125,
        TargetPlayerDistanceWhileExploding = 175,

        PunchPlayerTargetDistance = 100,
        PunchChestTargetDistance = 100,

        PostExplodeCooldown = 25,
        PostEmergeCooldown = {
            Min = 35,
            Max = 45
        },
        PostAttackCooldown = {
            Min = 35,
            Max = 45
        },

        DirectAttacks = {
            "GroundPound",
            "Punch",
            "Bomb"
        },

        PunchSpikeAlign = 40,
        PunchTooCloseToCenter = 80, -- if narc is too close to the center, he'll punch to try to get to a side for easier baiting

        LaserChainWaitAfterEmerging = 30 * 8,
        LaserChainWaitAfterLaserChain = 30 * 2.5,
        PhaseThresholds = {.7, .4, .15},
        SkipFinalPhaseTime = 30 * 190, -- if you take 3 minutes to fight the boss (+10 second intro), skip the final mirror phase
        SkipFinalPhaseHits = 6,
        LaserChainIntervals = {30, 35, 40, 50}, -- based on # of glass spikes still up
        LaserChainLength = 5,

        -- Items
        SamsonsChainsEffectDistance = {
            Min = 100,
            Max = 125
        },
        SamsonsChainsEffectPower = {
            Min = 1,
            Max = 0.9
        },

        -- Glass Spikes & Megashards
        DangerousGlowColor = Color(1, 1, 1, 1,conv255ToFloat( 255, 0, 0)),
        DangerousGlowFadeIn = 10,
        DangerousGlowFadeOut = 10,
        LaserChainLaser = {
            FadeIn = 5,
            PulseIn = 3,
            PulseHold = 5,
            PulseOut = 4,
            PulseStartScale = Vector(1, 0.25),
            PulseScale = Vector(1, 1),
            PulseEndScale = Vector(1, 0),
            PulseColor = Color(1, 0, 0, 1,conv255ToFloat( 0, 0, 0)),
            Color = Color(1, 0, 0, 0.5,conv255ToFloat( 0, 0, 0)),
            FadedColor = Color(1, 0, 0, 0,conv255ToFloat( 0, 0, 0))
        },

        GlassSpikeShake = {
            Min = 20,
            Max = 30
        },
        GlassSpikePhaseShake = {
            Min = 40,
            Max = 50
        },
        GlassSpikeTutorialShake = 15,
        GlassSpikeShakeEndBuffer = 15, -- new lasers don't appear within this many frames of shake stopping
        GlassSpikeLaser = {
            FadeIn = 5,
            FadeOut = 5,
            Color = Color(1, 1, 1, 0.5,conv255ToFloat( 255, 0, 0)),
            HealColor = Color(1, 1, 1, 0.2,conv255ToFloat( 255, 215, 0)),
            Offset = Vector(0, -24),
            HealNarcOffset = Vector(0, -40)
        },
        GlassSpikeBurstOffset = ((192 / 26) * 40) * 0.35,
        GlassSpikeSunburstCenter = {
            AddRotation = 1,
            PulseIn = 4,
            PulseOut = 3,
            InitialPulseStartScale = Vector(0.1, 0.1),
            InitialPulseScale = Vector(0.75, 0.75),
            InitialPulseEndScale = Vector(0.5, 0.5),
            FinalPulseStartScale = Vector(0.5, 0.5),
            FinalPulseScale = Vector(0.75, 0.75),
            FinalPulseEndScale = Vector(0.5, 0.5),
            Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0)),
            Offset = Vector(0, -24)
        },
        GlassSpikeSunburst = {
            FadeIn = 5,
            FadeOut = 2,
            Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0)),
            Offset = Vector(0, -24)
        },
        GlassSpikeNumMegashards = 6,
        GlassSpikeAngleVariance = 5,
        GlassSpikeMaxAngleOff = 45,

        GlassSpikeRoomClamp = {
            X = 40,
            Y = 0
        },
        GlassSpikeScale = 1,

        GlassSpikeHealFrequency = 240,
        GlassSpikeHealingLength = 30,
        GlassSpikeFlashFadeTime = 10,
        GlassSpikeHealWhenLower = {0.015, 0.035, 0.075, 0.15},
        GlassSpikeHealWhenHigher = 0.002,
        GlassSpikeHealColor = Color(1, 1, 1, 1,conv255ToFloat( 255, 215, 0)),
        GlassSpikeBombBounceVelMult = 0.25,

        AttackNames = {
            GroundPound = "Ground Pound",
            Punch = "Lunge Punch",
            Bomb = "Bomb Crunch",
            LaserChain = "Laser Chain",
            DiveOut = "Dive Out",
            DiveIn = "Shattering",
            ChestPunch = "Gathering"
        },

        GlassSpikeHitPoints = 0.4,

        ItemHitPoints = { -- in percent of boss hp
            Planet = 0.15,
            Hairball = 0.12,
            Chain = 0.16,
            Shade = 0.15,
            Robobaby = 0.07,
            DeadBird = 0.025,
            Vampire = 0.1 -- heal
        },
        BombDamage = 0.05
    }

    local LaserTell = REVEL.LazyLoadRoomSprite{
        ID = "narc2_LaserTell",
        Anm2 = "gfx/bosses/revel2/narcissus_2/damaging_laser_tell.anm2",
    }

    local DamagingLaser = REVEL.LazyLoadRoomSprite{
        ID = "narc2_DamagingLaser",
        Anm2 = "gfx/bosses/revel2/narcissus_2/damaging_laser.anm2",
    }

    local HealingLaser = REVEL.LazyLoadRoomSprite{
        ID = "narc2_HealingLaser",
        Anm2 = "gfx/bosses/revel2/narcissus_2/healing_laser.anm2",
    }

    local SunburstRay = REVEL.LazyLoadRoomSprite{
        ID = "narc2_SunburstRay",
        Anm2 = "gfx/bosses/revel2/narcissus_2/sunburst_ray.anm2",
    }

    local SunburstCore = REVEL.LazyLoadRoomSprite{
        ID = "narc2_SunburstCore",
        Anm2 = "gfx/bosses/revel2/narcissus_2/sunburst_core.anm2",
    }

    local function timerLerpUpdate(tbl, key, noStart)
        if not noStart and not tbl[key .. "Start"] then
            tbl[key .. "Start"] = tbl[key]
        end

        tbl[key] = tbl[key] - 1
        if tbl[key] <= 0 then
            tbl[key] = nil
            return true
        end
    end

    local function updateFade(fadeData)
        if fadeData.ScaleIn then
            timerLerpUpdate(fadeData, "ScaleIn")
        end

        fadeData.Pulsed = nil
        if fadeData.PulseIn then
            if timerLerpUpdate(fadeData, "PulseIn") then
                fadeData.Pulsed = true
            end
        elseif fadeData.PulseHold then
            fadeData.Pulsed = true
            timerLerpUpdate(fadeData, "PulseHold", true)
        elseif fadeData.PulseOut then
            if timerLerpUpdate(fadeData, "PulseOut") then
                if fadeData.PulseFinal then
                    fadeData.Faded = true
                end
            end
        end

        if fadeData.FadeIn then
            timerLerpUpdate(fadeData, "FadeIn")
        elseif fadeData.FadeOut then
            if timerLerpUpdate(fadeData, "FadeOut") then
                fadeData.Faded = true
            end
        end
    end

    local function timerLerp(tbl, lerpKey, val1, val2)
        if not tbl[lerpKey .. "Start"] then
            tbl[lerpKey .. "Start"] = tbl[lerpKey]
        end

        local percent = (tbl[lerpKey .. "Start"] - tbl[lerpKey]) / tbl[lerpKey .. "Start"]
        if type(val1) == "userdata" and val1.R then
            return Color.Lerp(val1, val2, percent)
        else
            return REVEL.Lerp(val1, val2, percent)
        end
    end

    local function getFadeColor(fadeData, defScale)
        local fadedColor = fadeData.FadedColor or REVEL.DEF_INVISIBLE
        if fadeData.FadeToVisible then
            fadedColor = Color.Default
        end

        defScale = fadeData.Scale or defScale

        local color, scale = fadeData.Color, defScale


        if fadeData.ScaleIn then
            scale = timerLerp(fadeData, "ScaleIn", fadeData.ScaleStart, defScale)
        end

        if fadeData.FadeIn then
            color = timerLerp(fadeData, "FadeIn", fadedColor, fadeData.Color)
        elseif fadeData.FadeOut then
            color = timerLerp(fadeData, "FadeOut", fadeData.Color, fadedColor)
        end

        if fadeData.PulseIn then
            if fadeData.PulseColor then
                color = timerLerp(fadeData, "PulseIn", fadeData.Color, fadeData.PulseColor)
            end

            if fadeData.PulseScale then
                scale = timerLerp(fadeData, "PulseIn", fadeData.PulseStartScale or defScale, fadeData.PulseScale)
            end
        elseif fadeData.PulseHold then
            color = fadeData.PulseColor or color
            scale = fadeData.PulseScale or scale
        elseif fadeData.PulseOut then
            if fadeData.PulseColor then
                color = fadeData.PulseColor
            end

            if fadeData.PulseScale then
                scale = timerLerp(fadeData, "PulseOut", fadeData.PulseScale, fadeData.PulseEndScale)
            end
        end

        if fadeData.Faded then
            return fadedColor, scale
        else
            return color, scale
        end
    end

    local function updateLaser(laserData)
        if laserData.AddRotation then
            if not laserData.Rotation then
                laserData.Rotation = 0
            end

            laserData.Rotation = (laserData.Rotation + laserData.AddRotation) % 360
        end

        if not laserData.Frame then
            laserData.Frame = -1
        end

        laserData.Frame = laserData.Frame + 1

        local maxFrame
        if laserData.Damaging then
            if not laserData.PulseInStart and not laserData.Pulsed and not laserData.PulseOutStart then
                maxFrame = 3
            else
                maxFrame = 5
            end
        elseif laserData.Sunburst then
            maxFrame = 11
        elseif laserData.SunburstCenter then
            maxFrame = 7
        else
            maxFrame = 8
        end

        updateFade(laserData)

        if laserData.Frame > maxFrame then
            laserData.Frame = 0
            return true
        end
    end

    local function renderLaser(laserData, startPos, endPos)
        startPos = Isaac.WorldToRenderPosition(startPos)
        endPos = Isaac.WorldToRenderPosition(endPos)

        if laserData.Damaging then
            local color, scale = getFadeColor(laserData, damagingLaserDefaultScale)
            if (laserData.PulseInStart or laserData.Pulsed or laserData.PulseOutStart) then
                DamagingLaser.Color = color
                DamagingLaser.Scale = scale

                DamagingLaser:SetFrame("Line", laserData.Frame or 0)
                REVEL.DrawRotatedTilingSprite(DamagingLaser, startPos, endPos, 96, 16, 16)

                DamagingLaser:SetFrame("End", laserData.Frame or 0)
                REVEL.DrawRotatedTilingCapSprites(DamagingLaser, startPos, endPos, 8)
            else
                LaserTell.Color = color
                LaserTell.Scale = scale

                LaserTell:SetFrame("Line", laserData.Frame or 0)
                REVEL.DrawRotatedTilingSprite(LaserTell, startPos, endPos, 32)
            end
        else
            local color, scale = getFadeColor(laserData, lineDefaultScale)
            HealingLaser.Color = color
            HealingLaser.Scale = scale

            HealingLaser:SetFrame("Line", laserData.Frame or 0)
            REVEL.DrawRotatedTilingSprite(HealingLaser, startPos, endPos, 96, 16, 16)

            HealingLaser:SetFrame("Start", laserData.Frame or 0)
            REVEL.DrawRotatedTilingCapSprites(HealingLaser, startPos, endPos, 8, false)

            HealingLaser:SetFrame("End", laserData.Frame or 0)
            REVEL.DrawRotatedTilingCapSprites(HealingLaser, startPos, endPos, 8, true)
        end
    end

    local function renderSunburst(burstData, pos, angle)
        local color, scale = getFadeColor(burstData, triangleDefaultScale)
        SunburstRay.Color = color
        SunburstRay.Scale = scale
        SunburstRay.Rotation = angle + 90

        local tempPos = pos
        local endPos = tempPos
        local dirVector = Vector.FromAngle(angle)
        while REVEL.room:IsPositionInRoom(tempPos, -5) do
            endPos = tempPos
            tempPos = tempPos + dirVector * 10
        end

        SunburstRay:SetFrame("Idle", burstData.Frame)
        SunburstRay:Render(Isaac.WorldToRenderPosition(pos), Vector.Zero, Vector.Zero)
    end

    local function renderSunburstCenter(burstData, pos, bursting)
        local color, scale = getFadeColor(burstData, circleDefaultScale)
        SunburstCore.Color = color
        SunburstCore.Scale = scale
        SunburstCore.Rotation = burstData.Rotation or 0

        if bursting then
            SunburstCore:SetFrame("Burst", burstData.Frame)
        else
            SunburstCore:SetFrame("Idle", burstData.Frame)
        end

        SunburstCore:Render(Isaac.WorldToRenderPosition(pos), Vector.Zero, Vector.Zero)
    end

    local function renderSunbursts(sunburstCenter, sunbursts, pos, curTime, burstOffset)
        if sunburstCenter then
            renderSunburstCenter(sunburstCenter, pos, sunburstCenter.AnimOut)
        end

        if sunbursts then
            for _, burst in ipairs(sunbursts) do
                if not curTime or curTime < burst.Appear then
                    renderSunburst(burst, pos + Vector.FromAngle(burst.Angle) * burstOffset, burst.Angle)
                end
            end
        end
    end

    local function BreakAllSpikes(instant, phasechange, noshards)
        for i, glassSpike in ipairs(Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)) do
            if instant or i == 1 then
                glassSpike:GetData().Destroyed = true
                glassSpike:GetData().NoMegashards = noshards or glassSpike:GetData().NoMegashards
                glassSpike:GetData().PhaseDestroyed = phasechange or glassSpike:GetData().PhaseDestroyed
            else
                REVEL.DelayFunction(function()
                    glassSpike:GetData().Destroyed = true
                    glassSpike:GetData().NoMegashards = noshards or glassSpike:GetData().NoMegashards
                    glassSpike:GetData().PhaseDestroyed = phasechange or glassSpike:GetData().PhaseDestroyed
                end, (i - 1) * 25, nil, true)
            end
        end
        for _, shock in ipairs(Isaac.FindByType(REVEL.ENT.CUSTOM_SHOCKWAVE.id, REVEL.ENT.CUSTOM_SHOCKWAVE.variant, -1, false, false)) do
            shock:Remove()
        end
    end

    local function updateEntityGlow(entity, glowData)
        updateFade(glowData)
        entity.Color = getFadeColor(glowData)
    end

    local function GetCurrentWalkDir(sprite)
        if sprite:IsPlaying("WalkLeft") or sprite:IsFinished("WalkLeft") then
            return "Left"
        elseif sprite:IsPlaying("WalkRight") or sprite:IsFinished("WalkRight") then
            return "Right"
        elseif sprite:IsPlaying("WalkUp") or sprite:IsFinished("WalkUp") then
            return "Up"
        elseif sprite:IsPlaying("WalkDown") or sprite:IsFinished("WalkDown") then
            return "Down"
        end
    end

    local function AnimateNarcissus2Walking(npc, sprite, targetPos, shouldFreezeTowardPlayer)
        if not shouldFreezeTowardPlayer then
            REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                Up = "WalkUp",
                Down = "WalkDown",
                Left = "WalkLeft",
                Right = "WalkRight"
            })
        else
            npc.Velocity = npc.Velocity * 0.8
            local diff = targetPos - npc.Position
            if math.abs(diff.X) > math.abs(diff.Y) then
                if diff.X < 0 then
                    sprite:SetFrame("WalkLeft", 0)
                else
                    sprite:SetFrame("WalkRight", 0)
                end
            else
                if diff.Y < 0 then
                    sprite:SetFrame("WalkUp", 0)
                else
                    sprite:SetFrame("WalkDown", 0)
                end
            end
        end

        return GetCurrentWalkDir(sprite)
    end

    local function Narcissus2Punch(npc, sprite, data, targetPos, chestPunch)
        local targetPositions
        if not chestPunch then
            targetPositions = {
                targetPos + Vector(data.bal.PunchPlayerTargetDistance, 0),
                targetPos - Vector(data.bal.PunchPlayerTargetDistance, 0)
            }
        else
            targetPositions = {
                targetPos + Vector(data.bal.PunchChestTargetDistance, 0),
                targetPos - Vector(data.bal.PunchChestTargetDistance, 0)
            }
        end
        --[[ = {
            targetPos + Vector(50, 0),
            targetPos - Vector(50, 0)
        }]]

        local closest, closestDist
        for _, pos in ipairs(targetPositions) do
            if REVEL.room:IsPositionInRoom(pos, 0) then
                local dist = pos:DistanceSquared(npc.Position)
                if not closestDist or dist < closestDist then
                    closestDist = dist
                    closest = pos
                end
            end
        end

        local facing, align = REVEL.GetAlignment(npc.Position, targetPos)

        if closestDist > 32 ^ 2 and data.StateFrame < 60 and not ((facing == "Left" or facing == "Right") and align < 32) then
            npc.Velocity = npc.Velocity * 0.8 + (closest - npc.Position):Resized(1.2)
        else
            sprite:RemoveOverlay()
            data.HeadState = nil
            sprite:Play("PunchStart", true)
            sprite.FlipX = targetPos.X < npc.Position.X
            if chestPunch then
                data.State = "ChestPunch"
            else
                data.State = "Punch"
            end

            data.PunchPrep = nil
            return true
        end
    end

    local Narcissus2ItemSprites = {}
    local function AddNarcissus2Item(item, pos)
        local useSprite, alreadyHasGfx, usingSpriteIndex
        for i, spriteData in ipairs(Narcissus2ItemSprites) do
            if not spriteData.InUse then
                useSprite = spriteData.Sprite
                usingSpriteIndex = i
                if spriteData.Gfx == item then
                    alreadyHasGfx = true
                    break
                end
            end
        end

        if not useSprite then
            useSprite = Sprite()
            useSprite:Load("gfx/bosses/revel2/narcissus_2/item.anm2", true)
            useSprite.Scale = Vector(1, -1)
            usingSpriteIndex = #Narcissus2ItemSprites + 1
        end

        if not alreadyHasGfx then
            useSprite:ReplaceSpritesheet(0, "gfx/bosses/revel2/narcissus_2/items/" .. item .. ".png")
            useSprite:LoadGraphics()
        end

        useSprite:Play("PlayerPickupSparkle", true)
        Narcissus2ItemSprites[usingSpriteIndex] = {
            Sprite = useSprite,
            Gfx = item,
            Position = pos,
            InUse = true
        }

        return usingSpriteIndex
    end

    function REVEL.PostNarcissusReflectionRender(npc)
        local data = npc:GetData()
        if data.UsingItemIndices then
            if not REVEL.game:IsPaused() then
                for _, item in ipairs(data.UsingItemIndices) do
                    local spriteData = Narcissus2ItemSprites[item]
                    if spriteData.TargetPosition then
                        spriteData.Position = REVEL.Lerp(spriteData.Position, spriteData.TargetPosition, 0.1)
                    end

                    if StageAPI.IsOddRenderFrame then
                        spriteData.Sprite:Update()
                        if spriteData.Sprite:IsFinished("Disappear") then
                            spriteData.InUse = false
                        end
                    end
                end
            end

            local inUse
            for _, item in ipairs(data.UsingItemIndices) do
                local spriteData = Narcissus2ItemSprites[item]
                if spriteData.InUse then
                    spriteData.Sprite:Render(Isaac.WorldToRenderPosition(spriteData.Position), Vector.Zero, Vector.Zero)
                    inUse = true
                end
            end

            if not inUse then
                data.UsingItemIndices = nil
            end
        end
    end

    local function FireMegashard(pos, vel, npc)
        local megashard = Isaac.Spawn(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, 0, pos, vel, npc)
        megashard:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        megashard.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        megashard.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        return megashard
    end

    local Narcissus2ItemEffects = {
        Individual = {
            TinyPlanet = {
                Gfx = "tiny_planet",
                OnTrigger = function(npc, data)
                    local planet = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, REVEL.room:GetCenterPos() + RandomVector() * 600, Vector.Zero, nil)
                    planet.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    planet:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    planet:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/tiny_planet.anm2", true)
                    planet:GetSprite():Play("Float", true)
                    REVEL.SetScaledBossSpawnHP(npc, planet, data.bal.ItemHitPoints.Planet)
                    planet:GetData().TinyPlanet = true
                    planet:GetData().SetSize = 13
                end
            },
            GuppysHairball = {
                Gfx = "guppys_hairball",
                KeepActive = true,
                OnTrigger = function(npc, data)
                    local hairball = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, npc.Position + RandomVector() * 30, Vector.Zero, nil)
                    hairball:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/guppys_hairball.anm2", true)
                    hairball:GetSprite():Play("Float5", true)
                    REVEL.SetScaledBossSpawnHP(npc, hairball, data.bal.ItemHitPoints.Hairball)
                    hairball:GetData().GuppysHairball = true
                    hairball:GetData().Narcissus = npc
                    hairball:GetData().SetSize = 15
                end
            },
            BobbyBombs = {
                Gfx = "bobby_bomb",
                WhenActive = function(npc, data)
                    if not data.NumBobbies then
                        data.NumBobbies = 0
                    end

                    if npc.FrameCount % 30 == 0 then
                        local bomb = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, Isaac.GetRandomPosition(), Vector.Zero, nil)
                        bomb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        bomb:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
                        bomb:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
                        bomb:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/bobby_bomb.anm2", true)
                        bomb:GetSprite():Play("Appear", true)
                        bomb:GetData().BobbyBomb = true
                        bomb:GetData().Invulnerable = true
                        bomb:GetData().SetSize = 13
                        bomb.CollisionDamage = 0
                        bomb.Mass = 1
                        data.NumBobbies = data.NumBobbies + 1
                        if data.NumBobbies >= 5 then
                            data.NumBobbies = nil
                            return false
                        end
                    end

                    return true
                end
            }
        },
        Passive = {
            CaffeinePill = {
                Gfx = "caffeine_pill",
                WhenActiveExternal = function(npc)
                    npc.SpriteScale = Vector(0.8, 0.8)
                    npc.SizeMulti = Vector(0.8, 0.8)
                end,
                OnEnd = function(npc)
                    npc.SpriteScale = Vector(1, 1)
                    npc.SizeMulti = Vector(1, 1)
                end
            },
            Magneto = {
                Gfx = "magneto",
                WhenActive = function(npc)
                    for _, player in ipairs(REVEL.players) do
                        player:AddVelocity((npc.Position - player.Position):Resized(0.2))
                    end
                end
            },
            SamsonsChains = {
                Gfx = "samsons_chains",
                OnTrigger = function(npc, data, sprite, target)
                    local chain = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, target.Position + RandomVector() * 30, Vector.Zero, nil)
                    chain:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/samsons_chains.anm2", true)
                    chain:GetSprite():Play("Idle", true)
                    REVEL.SetScaledBossSpawnHP(npc, chain, data.bal.ItemHitPoints.Chain)
                    chain.CollisionDamage = 0
                    chain:GetData().bal = data.bal
                    chain:GetData().SamsonsChains = true
                    chain:GetData().SetSize = 15
                    chain:GetData().Target = target
                    data.SamsonsChains = chain
                end,
                OnEnd = function(npc, data)
                    if data.SamsonsChains:Exists() then
                        data.SamsonsChains:Remove()
                    end

                    data.SamsonsChains = nil
                end
            },
            CharmOfTheVampire = {
                Gfx = "charm_of_the_vampire",
                PlayerTakeDamage = function(player, amount, flags, source, frames, npc, data)
                    if not data.VampireUses or data.VampireUses < 3 then
                        if not data.VampireUses then
                            data.VampireUses = 0
                        end

                        data.VampireUses = data.VampireUses + 1
                        npc.HitPoints = npc.HitPoints + npc.MaxHitPoints * data.bal.ItemHitPoints.Vampire
                        local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, npc.Position, Vector.Zero, nil)
                        REVEL.sfx:Play(REVEL.SFX.NARC.HOLY, 0.6, 0, false, 0.85+math.random()*0.15)
                        REVEL.sfx:Play(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 0.8)
                        effect.Visible = npc.Visible
                        effect.SpriteOffset = Vector(0, -80)
                        effect:GetData().ForceReflection = true
                    end
                end,
                OnEnd = function(npc, data)
                    data.VampireUses = nil
                end
            },
            CurseOfTheTower = {
                Gfx = "curse_of_the_tower",
                OnTrigger = function(npc, data)
                    data.TowerTakenDamage = nil
                end,
                BossTakeDamage = function(npc, amount, flags, source, frames, data)
                    if not data.TowerTakenDamage then
                        data.TowerTakenDamage = 45
                        Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, Isaac.GetRandomPosition(), Vector.Zero, npc)
                    end
                end,
                WhenActive = function(npc, data)
                    if data.TowerTakenDamage then
                        data.TowerTakenDamage = data.TowerTakenDamage - 1
                        if data.TowerTakenDamage <= 0 then
                            data.TowerTakenDamage = nil
                        end
                    end
                end
            },
            Shade = {
                Gfx = "shade",
                OnTrigger = function(npc, data)
                    local shade = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, npc.Position, Vector.Zero, nil)
                    shade:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    shade:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/shade.anm2", true)
                    shade:GetSprite():SetFrame("WalkDown", 0)
                    REVEL.SetScaledBossSpawnHP(npc, shade, data.bal.ItemHitPoints.Shade)
                    shade:GetData().Shade = true
                    shade:GetData().SetSize = 15
                    shade.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    shade.Visible = false
                    data.Shade = shade
                end,
                PlayerTakeDamage = function(player, _, _, _, _, _, data)
                    if data.Shade and data.Shade:Exists() and data.Shade.EntityCollisionClass == EntityCollisionClass.ENTCOLL_PLAYERONLY and data.Shade.Position:DistanceSquared(player.Position) <= (player.Size + data.Shade.Size) ^ 2 then
                        data.Shade:Remove()
                        REVEL.sfx:Play(SoundEffect.SOUND_SUMMON_POOF)
                        local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, player.Position, Vector.Zero, player):ToEffect()
                        poof.SpriteScale = Vector(0.5,0.5)
                        poof.Color = Color(0,0,0,1)
                        data.Shade = nil
                    end
                end,
                OnEnd = function(npc, data)
                    if data.Shade and data.Shade:Exists() then
                        data.Shade:Remove()
                    end
                    data.Shade = nil
                end
            }
        },
        Modifier = {
            RubberCement = {
                Gfx = "rubber_cement",
                ShockwaveSpawn = function(shock)
                    shock.Velocity = shock.Velocity:Rotated(90)
                    shock.Velocity = shock.Velocity*0.9
                    shock:GetData().Color = Color(1.5,1.5,1.5,1,0.2,0.2,0.2)
                end,
                ShockwaveCollide = function(shock)
                    if not shock:GetData().BouncePosition then
                        local clamp = REVEL.room:GetClampedPosition(shock.Position, 32)
                        if shock.Position.X ~= clamp.X then
                            shock.Velocity = Vector(-shock.Velocity.X, shock.Velocity.Y)
                        end

                        if shock.Position.Y ~= clamp.Y then
                            shock.Velocity = Vector(shock.Velocity.X, -shock.Velocity.Y)
                        end

                        shock:GetData().BouncePosition = shock.Position
                        return false
                    elseif shock:GetData().BouncePosition:DistanceSquared(shock.Position) < 32 ^ 2 then
                        return false
                    end
                end
            },
            SpoonBender = {
                Gfx = "spoon_bender",
                ShockwaveSpawn = function(shock)
                    shock:GetData().Color = Color(1.4,0.6,1.8,1,0.1,0,0.2)
                end,
                ShockwaveCollide = function(shock, initialDir, corner)
                    if shock.Position:DistanceSquared(corner.Position) > 32 ^ 2 then
                        shock:GetData().Collided = true
                        return false
                    end
                end,
                ShockwaveUpdate = function(shock, initialDir, corner, npc, data, sprite, target)
                    if shock.FrameCount < 60 and not shock:GetData().Collided then
                        if shock.Position:DistanceSquared(target.Position) < 150 ^ 2 then
                            local rotated = shock.Velocity:GetAngleDegrees()-(target.Position - shock.Position):GetAngleDegrees()
                            local num = (rotated > 0 and 1) or (rotated == 0 and 0) or -1
                            shock.Velocity = shock.Velocity:Rotated(3 * -num)
                        end
                    else
                        if not shock:GetData().Reset then
                            shock.Velocity = (corner.Position - shock.Position):Resized(10)
                            shock:GetData().Reset = true
                        end
                    end
                end
            }
        },
        Concurrent = {
            RoboBaby2 = {
                Gfx = "robo_baby_2",
                OnTrigger = function(npc, data, sprite, target)
                    for i = 1, 2 do
                        local robo = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, REVEL.room:GetCenterPos() + RandomVector() * 600, Vector.Zero, nil)
                        robo.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                        robo:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        robo:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/robo_baby_2.anm2", true)
                        robo:GetSprite():Play("FloatDown", true)
                        REVEL.SetScaledBossSpawnHP(npc, robo, data.bal.ItemHitPoints.Robobaby)
                        robo:GetData().RoboBaby = true
                        robo:GetData().SetSize = 13
                    end
                end
            },
            DeadBird = {
                Gfx = "dead_bird",
                WhenActive = function(npc, data, sprite, target)
                    if not data.NumBirds then
                        data.NumBirds = 0
                    end

                    if npc.FrameCount % 30 == 0 then
                        local bird = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, REVEL.room:GetCenterPos() + RandomVector() * 500, Vector.Zero, nil)
                        bird:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        bird:GetSprite():Load("gfx/003.014_dead bird.anm2", false)
                        bird:GetSprite():ReplaceSpritesheet(0, "gfx/bosses/revel2/narcissus_2/items/effects/dead_bird.png")
                        bird:GetSprite():LoadGraphics()
                        bird:GetSprite():Play("Flying", true)
                        bird:GetData().DeadBird = true
                        bird.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                        REVEL.SetScaledBossSpawnHP(npc, bird, data.bal.ItemHitPoints.DeadBird)
                        bird:GetData().SetSize = 13
                        bird:GetData().FlyOffset = math.random(1, 30)
                        data.NumBirds = data.NumBirds + 1
                        if data.NumBirds >= 8 then
                            data.NumBirds = nil
                            return false
                        end
                    end

                    return true
                end
            }
        }
        --[[
        "analog_stick",
        "bobby_bomb",
        "tiny_planet",
        "the_wafer",
        "magneto"]]
    }

    local Narcissus2Items = {}
    for k, v in pairs(Narcissus2ItemEffects) do
        if not Narcissus2Items[k] then
            Narcissus2Items[k] = {}
        end

        for k2, v2 in pairs(v) do
            Narcissus2Items[k][#Narcissus2Items[k] + 1] = k2
            for k3, v3 in pairs(v2) do
                if type(v3) == "function" and k3 ~= "OnTrigger" then
                    v2.KeepActive = true
                end
            end

            v2.Name = k2
            v2.ItemType = k
        end
    end

    local function GetActiveEffects(effects)
        local activeEffects = {}
        for k, v in pairs(effects) do
            activeEffects[#activeEffects + 1] = Narcissus2ItemEffects[v][k]
        end

        return activeEffects
    end

    local NarcissusPhaseItems = {
        { -- phase 1
            {Individual = 1, Modifier = 1},
            {Concurrent = 1}
        },
        { -- phase 2
            {Individual = 1, Modifier = 1, Passive = 1},
            {Concurrent = 1, Passive = 1}
        },
        { -- phase 3
            {Individual = 1, Modifier = 1, Passive = 2},
            {Concurrent = 1, Modifier = 1, Passive = 1}
        }
    }

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        for _, narcissus in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)) do
            local npc = narcissus:ToNPC()
            local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

            if data.ActiveItems then
                for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                    if item.WhenActiveExternal then
                        item.WhenActiveExternal(npc, data, sprite, target)
                    end
                end
            end
        end
    end)

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= REVEL.ENT.NARCISSUS_2_NPC.variant then
            return
        end

        if Isaac.CountEntities(nil, REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1) == 0 then
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, nil)
            npc:Remove()
            return
        end

        local data, target = npc:GetData(), npc:GetPlayerTarget()
        if data.SetSize then
            npc.Size = data.SetSize
        end

        if data.TinyPlanet then
            data.StopDiveOut = true
            if not data.Projectiles then
                data.Projectiles = {}
            end

            if #data.Projectiles < 5 then
                for i = 1, 5 - #data.Projectiles do
                    local pro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, Vector.Zero, nil):ToProjectile()
                    pro:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    pro:GetData().Angle = math.random(1, 360)
                    pro:GetData().OrbitSpeed = math.random(1, 3)
                    pro:GetData().TinyPlanet = true
                    pro.Scale = 1.5
                    data.Projectiles[#data.Projectiles + 1] = pro
                end
            end

            for i, pro in ripairs(data.Projectiles) do
                if not pro:Exists() then
                    table.remove(data.Projectiles, i)
                else
                    pro.Height = -30
                    pro:GetData().Angle = pro:GetData().Angle + pro:GetData().OrbitSpeed
                    pro.Velocity = ((npc.Position + REVEL.GetOrbitOffset(pro:GetData().Angle * (math.pi / 180), i * 30)) - pro.Position) / 2
                    local len = pro.Velocity:Length()
                    if len > 10 then
                        pro.Velocity = (pro.Velocity / len) * 10
                    end
                end
            end

            npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position):Resized(0.5)
        elseif data.GuppysHairball then
            data.StopDiveOut = true
            local otherHairballs = Isaac.FindByType(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, -1, false, false)
            for _, hairball in ipairs(otherHairballs) do
                if GetPtrHash(hairball) ~= GetPtrHash(npc) and hairball:GetData().GuppysHairball and npc.Position:DistanceSquared(hairball.Position) < (npc.Size + hairball.Size) ^ 2 then
                    local diff = hairball.Position - npc.Position
                    hairball.Velocity = diff * 0.25
                    npc.Velocity = -(diff * 0.25)
                end
            end

            if npc.HitPoints < npc.MaxHitPoints * 0.5 and npc:GetSprite():IsPlaying("Float5") then
                for i = 1, 2 do
                    local hairball = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, 0, npc.Position, Vector.Zero, nil)
                    hairball:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    hairball:GetSprite():Load("gfx/bosses/revel2/narcissus_2/items/effects/guppys_hairball.anm2", true)
                    hairball:GetSprite():Play("Float3", true)
                    hairball.MaxHitPoints = npc.MaxHitPoints * 0.5
                    hairball.HitPoints = hairball.MaxHitPoints
                    hairball:GetData().GuppysHairball = true
                    hairball:GetData().Narcissus = data.Narcissus
                    hairball:GetData().SetSize = 13
                end

                data.SetSize = 13
                npc.MaxHitPoints = npc.MaxHitPoints * 0.5
                npc.HitPoints = npc.MaxHitPoints
                npc:BloodExplode()
                npc:GetSprite():Play("Float3", true)
            end

            npc.Velocity = npc.Velocity * 0.98 + (data.Narcissus.Position - npc.Position):Resized(0.5)
        elseif data.SamsonsChains then
            local dist = data.Target.Position:Distance(npc.Position)
            if dist > data.bal.SamsonsChainsEffectDistance.Min then
                local power = REVEL.Lerp(data.bal.SamsonsChainsEffectPower.Min, data.bal.SamsonsChainsEffectPower.Max, math.min(dist, data.bal.SamsonsChainsEffectDistance.Max) / data.bal.SamsonsChainsEffectDistance.Max)
                npc.Velocity = (data.Target.Position - npc.Position):Resized(data.Target.Velocity:Length() * power)
                data.Target.Velocity = data.Target.Velocity * power
            else
                npc.Velocity = npc.Velocity * 0.8
            end
        elseif data.BobbyBomb then
            data.StopDiveOut = true
            npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position):Resized(0.35)
            if npc:GetSprite():IsFinished("Appear") then
                npc:GetSprite():Play("Pulse", true)
            end

            if npc:GetSprite():IsFinished("Pulse") then
                Isaac.Explode(npc.Position, npc, 20)
                npc:Remove()
            end
        elseif data.RoboBaby then
            data.ConcurrentActive = true
            local directions = {
                Down = Vector(0, -150),
                Up = Vector(0, 150),
                Side = Vector(-150, 0),
                Side2 = Vector(150, 0)
            }

            local npcs = Isaac.FindByType(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, -1, false, false)
            local roboBabies = {}
            for _, baby in ipairs(npcs) do
                if (GetPtrHash(baby) ~= GetPtrHash(npc)) and baby:GetData().RoboBaby and baby:GetData().Direction and directions[baby:GetData().Direction] then
                    directions[baby:GetData().Direction] = nil
                end

                if baby:GetData().RoboBaby then
                    roboBabies[#roboBabies + 1] = baby
                end
            end

            if #roboBabies < 2 then
                data.StopDiveOut = nil
            else
                data.StopDiveOut = true
            end

            local closest, closestDist
            for name, dir in pairs(directions) do
                local pos = target.Position + dir
                if REVEL.room:IsPositionInRoom(pos, 0) then
                    local dist = pos:DistanceSquared(npc.Position)
                    if not closestDist or dist < closestDist then
                        closest = name
                        closestDist = dist
                    end
                end
            end

            local facing, align = REVEL.GetAlignment(npc.Position, target.Position)
            if facing == "Left" then
                facing = "Side2"
            elseif facing == "Right" then
                facing = "Side"
            end

            if closest and not data.WaitShoot then
                data.Direction = closest
                local pos = directions[closest] + target.Position
                npc.Velocity = npc.Velocity * 0.9 + (pos - npc.Position):Resized(1)
                local sprite = npc:GetSprite()
                if not sprite:IsPlaying("Float" .. facing) then
                    local frame = sprite:GetFrame()
                    sprite:Play("Float" .. facing, true)
                    for i = 0, frame do
                        sprite:Update()
                    end
                end

                if align <= 16 and REVEL.room:IsPositionInRoom(npc.Position, 0) then
                    data.WaitShoot = 20
                    data.ShootDirection = facing
                end
            elseif data.WaitShoot then
                npc.Velocity = Vector.Zero
                data.WaitShoot = data.WaitShoot - 1

                local sprite = npc:GetSprite()
                if data.WaitShoot <= -15 then
                    data.WaitShoot = nil
                elseif data.WaitShoot <= 0 then
                    if data.WaitShoot == 0 then
                        local angle
                        if data.ShootDirection == "Side" then
                            angle = 0
                        elseif data.ShootDirection == "Down" then
                            angle = 90
                        elseif data.ShootDirection == "Side2" then
                            angle = 180
                        else
                            angle = 270
                        end

                        local laser = EntityLaser.ShootAngle(2, npc.Position, angle, 4, Vector(0, -24), npc)
                        if data.ShootDirection == "Down" then
                            laser.DepthOffset = 10
                        end
                    end

                    if not sprite:IsPlaying("FloatShoot" .. data.ShootDirection) then
                        local frame = sprite:GetFrame()
                        sprite:Play("FloatShoot" .. data.ShootDirection, true)
                        for i = 0, frame do
                            sprite:Update()
                        end
                    end
                else
                    if not sprite:IsPlaying("Float" .. data.ShootDirection) then
                        local frame = sprite:GetFrame()
                        sprite:Play("Float" .. data.ShootDirection, true)
                        for i = 0, frame do
                            sprite:Update()
                        end
                    end
                end
            end
        elseif data.DeadBird then
            data.ConcurrentActive = true
            if not REVEL.room:IsPositionInRoom(npc.Position, 0) then
                data.StopDiveOut = true
            else
                data.StopDiveOut = nil
            end

            if (npc.FrameCount + data.FlyOffset) % 30 < 25 then
                npc.Velocity = (target.Position - npc.Position):Resized(6)
            else
                npc.Velocity = Vector.Zero
            end
        elseif data.Shade then
            if not data.TargetPositions then
                data.TargetPositions = {}
            end

            table.insert(data.TargetPositions, 1, target.Position)
            data.TargetPositions[46] = nil

            if data.TargetPositions[45] then
                if not data.StartFrame then
                    npc.Visible = true
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    npc.Position = data.TargetPositions[45]
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector.Zero, nil)
                    data.StartFrame = npc.FrameCount
                elseif npc.FrameCount > data.StartFrame + 15 then
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                end

                npc.Velocity = data.TargetPositions[45] - npc.Position
                if npc.Velocity:LengthSquared() > 1 ^ 2 then
                    REVEL.AnimateWalkFrame(npc:GetSprite(), npc.Velocity, {
                        Down = "WalkDown",
                        Up = "WalkUp",
                        Horizontal = "WalkHori"
                    })
                else
                    npc:GetSprite():SetFrame("WalkDown", 0)
                end

                if npc:IsDead() then
                    REVEL.sfx:Play(SoundEffect.SOUND_SUMMON_POOF)
                    local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, npc.Position, Vector.Zero, npc):ToEffect()
                    poof.SpriteScale = Vector(0.5,0.5)
                    poof.Color = Color(0,0,0,1)
                end
            else
                npc.Velocity = Vector.Zero
            end
        end
    end, REVEL.ENT.NARCISSUS_2_NPC.id)

    local SamsonChainSprite = REVEL.LazyLoadRoomSprite{
        ID = "narc2_SamsonChain",
        Anm2 = "gfx/bosses/revel2/narcissus_2/items/effects/samsons_chains.anm2",
        Animation = "Chain",
        Offset = Vector(0, -8),
    }

    revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
        if npc.Variant ~= REVEL.ENT.NARCISSUS_2_NPC.variant then
            return
        end

        local data = npc:GetData()
        if data.SamsonsChains then
            local targetDiff = (data.Target.Position - npc.Position) / 10
            for i = 1, 10 do
                SamsonChainSprite:Render(Isaac.WorldToRenderPosition(npc.Position + targetDiff * i) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end
    end, REVEL.ENT.NARCISSUS_2_NPC.id)

    revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
        if pro:GetData().TinyPlanet then
            pro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            pro.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            for _, player in ipairs(REVEL.players) do
                if pro.Position:DistanceSquared(player.Position) < (player.Size + pro.Size) ^ 2 then
                    player:TakeDamage(1, 0, EntityRef(pro), 0)
                end
            end
        end
    end)

    local function GetNarcissusSpeedMulti(npc, data)
        if data.ActiveItems and data.ActiveItems.CaffeinePill then
            return 1.5
        else
            return 1
        end
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= REVEL.ENT.NARCISSUS_2.variant then
            return
        end

        if npc:HasMortalDamage() and not npc:GetData().Death then
            REVEL.sfx:Play(REVEL.SFX.NARC2_DEATH, 1, 0, false, 1)
            npc:GetData().Death = true
        end
    end, REVEL.ENT.NARCISSUS_2.id)

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= REVEL.ENT.NARCISSUS_2.variant then
            return
        end

        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        if not data.bal then
            data.bal = REVEL.GetBossBalance(narc2Balance, "Default")
        end

        if not data.Init then
            if not REVEL.HasReflectionsInRoom() then
                REVEL.AddReflections(1, true, false)
            end

            REVEL.SetScaledBossHP(npc)
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.Visible = false
            data.FollowingPlayer = REVEL.player
            data.LateReflection = true
            data.ForceReflection = true
            data.State = "ActAsReflection"
            data.StartTime = Isaac.GetTime()

            local tutorialSpike = REVEL.ENT.GLASS_SPIKE:spawn(REVEL.room:GetCenterPos(), Vector.Zero, npc)
            tutorialSpike:GetData().TutorialSpike = true
            tutorialSpike.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            tutorialSpike.Visible = false
            tutorialSpike:GetData().ForceReflection = true
            tutorialSpike:GetSprite():Play("appear", true)
            tutorialSpike:GetData().Animation = "appear"
            tutorialSpike:GetData().bal = data.bal
            tutorialSpike:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            data.TutorialSpike = tutorialSpike

            data.PushData = {
                ForceMult = 0.5,
                TimeMult = 0.1,
            }

            data.Init = true
        end

        if not data.State then
            data.State = "Idle"
            data.HeadState = "Idle"
            data.TimesUsedAttacks = {}
        end

        if data.AttackCooldown and ((data.State == "Idle" or data.State == "MirrorIdle") and (not data.HeadState or data.HeadState == "Idle") and not data.PunchPrep) then
            data.AttackCooldown = data.AttackCooldown - 1
            if data.AttackCooldown <= 0 then
                data.AttackCooldown = nil
            end
        end

        if data.TimeSinceEmerging then
            data.TimeSinceEmerging = data.TimeSinceEmerging + 1
        end

        if data.TimeSinceLaserChain then
            data.TimeSinceLaserChain = data.TimeSinceLaserChain + 1
        end

        if not data.LastState or data.State ~= data.LastState then
            data.LastState = data.State
            data.StateFrame = 0
        else
            data.StateFrame = data.StateFrame + 1
        end

        if data.Chest and not data.Chest:Exists() then
            data.Chest = nil
        end

        local blockMirrorDiveOut
        if data.ActiveItems then
            for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                if item.WhenActive then
                    local ret = item.WhenActive(npc, data, sprite, target)
                    if ret == true then
                        blockMirrorDiveOut = true
                    elseif ret == false then
                        data.ActiveItems[item.Name] = nil
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Roar") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC.ROAR, 1, 0, false, 1)
        end
        if sprite:IsEventTriggered("Land") then
            REVEL.sfx:Play(REVEL.SFX.NARC.STOMP, 1.2, 0, false, 0.9+math.random()*0.15)
        end
        if sprite:IsEventTriggered("Stomp") then
            REVEL.sfx:Play(REVEL.SFX.NARC.STOMP, 0.6, 0, false, 0.9+math.random()*0.15)
        end
        if sprite:IsEventTriggered("LandIntro") then
            REVEL.sfx:Play(REVEL.SFX.NARC_GPOUND, 1.2, 0, false, 0.9+math.random()*0.15)
        end
        if sprite:IsEventTriggered("LandGPound") then
            REVEL.sfx:Play(REVEL.SFX.NARC_FISTPOUND, 1.6, 0, false, 0.9+math.random()*0.15)
        end
        if sprite:IsEventTriggered("Jump") then
            REVEL.sfx:Play(REVEL.SFX.WHOOSH, 0.6, 0, false, 1)
        end
        if sprite:IsEventTriggered("Crunch") then
            REVEL.sfx:Play(REVEL.SFX.NARC.CRACK, 1, 0, false, 1)
        end
        if sprite:IsEventTriggered("Explode") then
            REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 0.75)
        end
        if sprite:IsEventTriggered("WarpSound") then
            REVEL.sfx:Play(REVEL.SFX.NARC_MIRROR_WARP, 0.7, 0, false, 0.97+math.random()*0.6)
        end
        if sprite:IsEventTriggered("Chest Pound") then
            data.chestPoundNum = data.chestPoundNum or -1
            data.chestPoundNum = (data.chestPoundNum + 1) % 2
            REVEL.sfx:Play(REVEL.SFX.NARC_CHEST_POUND, 1, 0, false, 1 - data.chestPoundNum * 0.03)
        end
        if sprite:IsEventTriggered("Pose") then
            if data.State == "GroundPound" then
                REVEL.sfx:Play(REVEL.SFX.NARC_POSE, 1.2, 0, false, 0.9+math.random()*0.15)
            else
                REVEL.sfx:Play(REVEL.SFX.WHOOSH, 1, 0, false, 1)
            end
        end

        local walkDir

        if data.State == "MirrorDiveOut" then
            npc.Velocity = npc.Velocity * 0.8
            if sprite:IsFinished("Dive In2") then
                sprite:Play("Dive Out", true)
            end

            if sprite:IsFinished("Dive Intro") then
                sprite:Play("Dive Out Intro", true)
                revel.data.seenNarcissusTomb = true
            end

            if sprite:IsEventTriggered("DiveOut") then
                npc.Visible = true
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

                data.PhaseStartingHP = npc.HitPoints

                for cornerNum, corner in ipairs(REVEL.GetCornerPositions()) do
                    local diff = corner.Position - npc.Position
                    local shockSpawned = REVEL.SpawnCustomShockwave(npc.Position, diff:Resized(7), "gfx/effects/revel1/mirror_shockwave.png", nil, EntityGridCollisionClass.GRIDCOLL_NONE, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE, function(shock)
                        local noSpike
                        if data.ActiveItems then
                            for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                                if item.ShockwaveCollide then
                                    local ret = item.ShockwaveCollide(shock, diff, corner, npc, data, sprite, target)
                                    if ret == false then
                                        noSpike = true
                                    end
                                end
                            end
                        end

                        if not noSpike then
                            local clampX = REVEL.room:GetClampedPosition(corner.Position, data.bal.GlassSpikeRoomClamp.X).X
                            local clampY = REVEL.room:GetClampedPosition(corner.Position, data.bal.GlassSpikeRoomClamp.Y).Y
                            local spike = Isaac.Spawn(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, 0, Vector(clampX, clampY), Vector.Zero, nil)

                            spike:GetData().bal = data.bal
                            spike:GetData().Corner = corner.Position
                            spike:GetData().MegashardDirection = REVEL.room:GetClampedPosition(corner.Position, 64) - corner.Position
                            spike:GetData().HealDelay = cornerNum * (data.bal.GlassSpikeHealFrequency / 4)
                            spike:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            spike:GetSprite():Play("appear", true)
                            spike:GetData().Animation = "appear"
                            REVEL.SetScaledBossSpawnHP(npc, spike, data.bal.GlassSpikeHitPoints)
                            shock:Remove()
                        end
                    end, function(shock)
                        if data.ActiveItems then
                            for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                                if item.ShockwaveUpdate then
                                    item.ShockwaveUpdate(shock, diff, corner, npc, data, sprite, target)
                                end
                            end
                        end
                        shock:GetSprite().PlaybackSpeed = 1.5
                    end, function(shock)
                        return not REVEL.room:IsPositionInRoom(shock.Position, 16)
                    end)

                    if data.ActiveItems then
                        for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                            if item.ShockwaveSpawn then
                                item.ShockwaveSpawn(shockSpawned, diff, corner, npc, data, sprite, target)
                            end
                        end
                    end
                end

                local offset = math.random() * 360
                for i = 1, 5 do
                    FireMegashard(npc.Position, Vector.FromAngle(i * 72 + offset) * 11, npc)
                end
            end

            if sprite:IsFinished("Dive Out") or sprite:IsFinished("Dive Out Intro") then
                data.TimeSinceEmerging = 0
                data.TimesUsedAttacks = {}
                data.AttackCooldown = math.random(data.bal.PostEmergeCooldown.Min, data.bal.PostEmergeCooldown.Max)
                data.State = "Idle"
                data.HeadState = "Idle"
                sprite:Play("Idle", true)
            end
        elseif data.State == "DiveIn" then
            npc.Velocity = npc.Velocity * 0.8
            if sprite:IsEventTriggered("DiveIn") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                npc.Visible = false

                if data.ActiveItems then
                    for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                        if item.OnEnd then
                            item.OnEnd(npc, data, sprite, target)
                        end
                    end
                    data.ActiveItems = nil
                end
            end

			if sprite:IsEventTriggered("Grunt") then
				REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_GLASS_BREAK_LIGHT, 0.6, 0, false, 1)
			end

            if sprite:IsEventTriggered("Roar") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC.ROAR, 1, 0, false, 1)
                BreakAllSpikes(false, true)

                for i, megashard in ipairs(Isaac.FindByType(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, -1, false, false)) do
                    megashard:GetData().Destroyed = true
                end
            end

            if sprite:IsFinished("Dive In") then
                sprite:Play("Dive Out2", true)
            end

            if sprite:IsFinished("Dive Out2") then
                data.State = "MirrorInitial"
                sprite:Play("Idle", true)
                REVEL.AnnounceAttack(data.bal.AttackNames.ChestPunch)
            end
        elseif data.State == "WaitForMirrorDiveOut" then
            if not data.TimeWaiting then
                data.TimeWaiting = 0
            end

            data.TimeWaiting = data.TimeWaiting + 1

            if data.TimeWaiting >= 75 then
                sprite:Play("Dive In2", true)
                data.State = "MirrorDiveOut"
                REVEL.AnnounceAttack(data.bal.AttackNames.DiveOut)
                data.TimeWaiting = nil
            end
        elseif data.State == "ActAsReflection" then -- intro phase, different anm2. acts as isaac's reflection, then jumps away, and jumps in as narc.
            local time = Isaac.GetTime()
            if data.TutorialBomb and not data.TutorialBomb:Exists() then
                data.TutorialBomb = nil
            end

            -- data.StartTime is in case music is different for some reason, 
            -- otherwise check music start time which might be later
            local actualStartTime = math.max(data.StartTime, MusicPlayStartTime)

            if time > actualStartTime + 9000 then
                if data.TutorialSpike and not data.TutorialSpike:GetData().Destroyed then
                    data.TutorialSpike:Remove()
                    data.TutorialSpike = nil
                end

                if data.TutorialBomb then
                    data.TutorialBomb:Remove()
                end

                data.LateReflection = nil

                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                sprite:Load("gfx/bosses/revel2/narcissus_2/narcissus_2.anm2", true)
                data.State = "MirrorDiveOut"
                sprite:Play("Dive Intro", true)
                npc.Position = REVEL.room:GetCenterPos()
            elseif time > actualStartTime + 7500 then
                npc.Velocity = Vector.Zero
                if sprite:IsFinished("ReflectionEscape") then
                    if data.TutorialSpike and not data.TutorialSpike:GetData().Destroyed then
                        data.TutorialSpike:Remove()
                        data.TutorialSpike = nil
                    end

                    if data.TutorialBomb then
                        data.TutorialBomb:Remove()
                    end

                    data.LateReflection = nil

                    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
                    sprite:Load("gfx/bosses/revel2/narcissus_2/narcissus_2.anm2", true)
                    data.State = "MirrorDiveOut"
                    sprite:Play("Dive Intro", true)
                    npc.Position = REVEL.room:GetCenterPos()
                else
                    if not sprite:IsPlaying("ReflectionEscape") then
                        sprite:Play("ReflectionEscape", true)
                        sprite:RemoveOverlay()
                    end
                end
            else
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                local following
                local followingPlayer = data.FollowingPlayer
                if time > actualStartTime + 4000 then
                    if time > actualStartTime + 6000 and not data.TutorialBombShot then
                        local bombPos = npc.Position + (npc.Position - data.TutorialSpike.Position):Resized(600)
                        local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_NORMAL, 0, bombPos, (data.TutorialSpike.Position - bombPos):Resized(40), npc)
                        bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                        bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                        bomb.Visible = false
                        bomb:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
                        bomb:GetSprite():Load("gfx/effects/revel1/mirror_bomb_spiky.anm2", true)
                        bomb:GetSprite():Play("Pulse", true)
                        bomb:GetData().IsMirrorBomb = true
                        bomb:GetData().ForceReflection = true
                        bomb:GetData().Narcissus = npc
                        bomb:GetData().Height = 25
                        bomb:GetData().TutorialBomb = true
                        REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_LAUNCHER, 0.6, 0, false, 1)
                        data.TutorialBomb = bomb
                        data.TutorialBombShot = true
                    end

                    if time > actualStartTime + 6700 and data.TutorialBomb and REVEL.room:IsPositionInRoom(npc.Position, 40) then
                        if not data.EscapeDirection then
                            if math.random(1, 2) == 1 then
                                data.EscapeDirection = -1
                            else
                                data.EscapeDirection = 1
                            end
                        end

                        npc.Velocity = npc.Velocity * 0.9 + data.TutorialBomb.Velocity:Rotated(data.EscapeDirection * 90):Resized(followingPlayer.MoveSpeed * 0.9)
                    elseif not data.EscapeDirection and npc.Position:DistanceSquared(data.TutorialSpike.Position) > (followingPlayer.Size + data.TutorialSpike.Size + 80) ^ 2 then
                        npc.Velocity = npc.Velocity * 0.9 + (data.TutorialSpike.Position - npc.Position):Resized(followingPlayer.MoveSpeed * 0.9)
                    else
                        npc.Velocity = npc.Velocity * 0.8
                    end
                else
                    following = true
                end

                local directions = {
                    "Up",
                    "Down",
                    "Left",
                    "Right"
                }

                local setSpriteWalkFrame, setSpriteHeadFrame
                if following then
                    local followingSprite = followingPlayer:GetSprite()
                    npc.Velocity = followingPlayer.Position - npc.Position
                    for _, dir in ipairs(directions) do
                        if followingSprite:IsPlaying("Walk" .. dir) or followingSprite:IsFinished("Walk" .. dir) then
                            setSpriteWalkFrame = true
                            sprite:SetFrame("Walk" .. dir, followingSprite:GetFrame())
                        end

                        if followingSprite:IsOverlayPlaying("Head" .. dir) or followingSprite:IsOverlayFinished("Head" .. dir) then
                            setSpriteHeadFrame = true
                            sprite:SetOverlayFrame("Head" .. dir, followingSprite:GetOverlayFrame())
                        end
                    end
                end

                if not setSpriteHeadFrame then
                    if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
                        if npc.Velocity.X > 0 then
                            sprite:SetOverlayFrame("HeadRight", 0)
                        else
                            sprite:SetOverlayFrame("HeadLeft", 0)
                        end
                    else
                        if npc.Velocity.Y > 0 then
                            sprite:SetOverlayFrame("HeadDown", 0)
                        else
                            sprite:SetOverlayFrame("HeadUp", 0)
                        end
                    end
                end

                if not setSpriteWalkFrame then
                    if npc.Velocity:LengthSquared() < 1 then
                        sprite:SetFrame("WalkDown", 0)
                        sprite:SetOverlayFrame("HeadDown", 0)
                    else
                        REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                            Up = "WalkUp",
                            Down = "WalkDown",
                            Left = "WalkLeft",
                            Right = "WalkRight"
                        })
                    end
                end
            end
        elseif data.State == "MirrorPrepareForDiveOut" then
            local centerPos = REVEL.room:GetCenterPos()
            if npc.Position:DistanceSquared(centerPos) > npc.Size ^ 2 then
                npc.Velocity = npc.Velocity * 0.8 + (centerPos - npc.Position):Resized(1.4 * GetNarcissusSpeedMulti(npc, data))
                data.HeadState = "Idle"
                walkDir = AnimateNarcissus2Walking(npc, sprite, target.Position, false)
            else
                npc.Velocity = npc.Velocity * 0.8
                sprite:Play("Dive In2", true)
                sprite:RemoveOverlay()
                data.HeadState = nil
                data.State = "MirrorDiveOut"
                REVEL.AnnounceAttack(data.bal.AttackNames.DiveOut)
            end
        elseif data.State == "MirrorIdle" then
            local diveOut = true
            for _, entity in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, -1, false, false)) do
                if entity:GetData().StopDiveOut then
                    diveOut = false
                end
            end

            local shouldFreeze
            if npc.Position:DistanceSquared(target.Position) > target.Size ^ 2 then
                npc.Velocity = npc.Velocity * 0.8 + (target.Position - npc.Position):Resized(1.4 * GetNarcissusSpeedMulti(npc, data))
            else
                npc.Velocity = npc.Velocity * 0.8
                shouldFreeze = true
            end

            data.HeadState = "Idle"
            walkDir = AnimateNarcissus2Walking(npc, sprite, target.Position, shouldFreeze)

            if diveOut and not blockMirrorDiveOut then
                data.State = "MirrorPrepareForDiveOut"
            end
        elseif data.State == "MirrorInitial" then
            if not data.Chest or not data.Chest:Exists() then
                data.State = "MirrorPrepareForDiveOut"
                return
            end

            local cancel = Narcissus2Punch(npc, sprite, data, data.Chest.Position + Vector(0, -40), true)
            if not cancel then
                data.HeadState = "Idle"
                walkDir = AnimateNarcissus2Walking(npc, sprite, data.Chest.Position, false)
            end
        elseif data.State == "MirrorCollectItems" then
            if not data.UsingItems then
                data.UsingItems = {}
                data.UsingItemNames = {}
                data.ItemGoal = NarcissusPhaseItems[data.Phase][math.random(1, #NarcissusPhaseItems[data.Phase])]
                data.ItemNum = {}
                for name, goalNum in pairs(data.ItemGoal) do
                    data.ItemNum[name] = 0
                end
            end

            local totalItems = 0
            local totalPrimary = 0
            for name, goalNum in pairs(data.ItemGoal) do
                totalItems = totalItems + goalNum
                if name == "Individual" or name == "Concurrent" then
                    totalPrimary = totalPrimary + goalNum
                end
            end

            local currentItems = 0
            local currentPrimary = 0
            for name, num in pairs(data.ItemNum) do
                currentItems = currentItems + num
                if name == "Individual" or name == "Concurrent" then
                    currentPrimary = currentPrimary + num
                end
            end

            if (not data.UsingItemIndices or #data.UsingItemIndices < totalItems) and data.Chest then
                if not data.UsingItemIndices then
                    data.UsingItemIndices = {}
                end

                local item
                local primaryItemStartPoint = (totalItems - totalPrimary / 2) / 2
                if currentItems >= math.floor(primaryItemStartPoint) and currentPrimary < totalPrimary then
                    if data.ItemNum.Individual and data.ItemNum.Individual < data.ItemGoal.Individual then
                        local validItems = {}
                        for _, name in ipairs(Narcissus2Items.Individual) do
                            if not data.UsingItemNames[name] then
                                validItems[#validItems + 1] = name
                            end
                        end

                        local itemName = validItems[math.random(1, #validItems)]
                        data.UsingItemNames[itemName] = true
                        item = Narcissus2ItemEffects.Individual[itemName]
                        data.ItemNum.Individual = data.ItemNum.Individual + 1
                    else
                        local validItems = {}
                        for _, name in ipairs(Narcissus2Items.Concurrent) do
                            if not data.UsingItemNames[name] then
                                validItems[#validItems + 1] = name
                            end
                        end

                        local itemName = validItems[math.random(1, #validItems)]
                        data.UsingItemNames[itemName] = true
                        item = Narcissus2ItemEffects.Concurrent[itemName]
                        data.ItemNum.Concurrent = data.ItemNum.Concurrent + 1
                    end
                else
                    if data.ItemNum.Modifier and data.ItemNum.Modifier < data.ItemGoal.Modifier then
                        local validItems = {}
                        for _, name in ipairs(Narcissus2Items.Modifier) do
                            if not data.UsingItemNames[name] then
                                validItems[#validItems + 1] = name
                            end
                        end

                        local itemName = validItems[math.random(1, #validItems)]
                        data.UsingItemNames[itemName] = true
                        item = Narcissus2ItemEffects.Modifier[itemName]
                        data.ItemNum.Modifier = data.ItemNum.Modifier + 1
                    elseif data.ItemNum.Passive and data.ItemNum.Passive < data.ItemGoal.Passive then
                        local validItems = {}
                        for _, name in ipairs(Narcissus2Items.Passive) do
                            if not data.UsingItemNames[name] then
                                validItems[#validItems + 1] = name
                            end
                        end

                        local itemName = validItems[math.random(1, #validItems)]
                        data.UsingItemNames[itemName] = true
                        item = Narcissus2ItemEffects.Passive[itemName]
                        data.ItemNum.Passive = data.ItemNum.Passive + 1
                    end
                end
                data.UsingItems[#data.UsingItems + 1] = item

                local index = AddNarcissus2Item(item.Gfx, data.Chest.Position + Vector(0, 80))
                data.UsingItemIndices[#data.UsingItemIndices + 1] = index
                Narcissus2ItemSprites[index].TargetPosition = npc.Position + Vector(0, 150)
            end

            if sprite:IsEventTriggered("Roar") then
			          REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC.ROAR, 1, 0, false, 1)

                if data.UsingItemIndices then
                    for i = 1, #data.UsingItemIndices do
                        local spriteData = Narcissus2ItemSprites[data.UsingItemIndices[i]]
                        local relativeToHalf = i - (#data.UsingItemIndices / 2) - 0.5
                        spriteData.TargetPosition = npc.Position + Vector(0, 150):Rotated(relativeToHalf * 20)
                    end

                    data.ActiveItems = {}
                    for _, item in ipairs(data.UsingItems) do
                        if item.OnTrigger then
                            item.OnTrigger(npc, data, sprite, target)
                        end

                        if item.KeepActive then
                            data.ActiveItems[item.Name] = item.ItemType
                        end
                    end
                end

                if data.Chest then
                    data.Chest:GetSprite():Play("Disappear", true)
                end
            end

            if sprite:IsFinished("Items") then
                if data.UsingItemIndices then
                    for _, index in ipairs(data.UsingItemIndices) do
                        Narcissus2ItemSprites[index].Sprite:Play("Disappear", true)
                        Narcissus2ItemSprites[index].TargetPosition = npc.Position + Vector(0, 50)
                    end
                end

                data.State = "MirrorIdle"

                if data.Chest then
                    data.Chest:Remove()
                    data.Chest = nil
                end
            end
        elseif data.State == "Idle" then
            local isSpikeExploding, isLaserChainActive
            local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
            for _, spike in ipairs(glassSpikes) do
                if spike:GetData().Destroyed then
                    isSpikeExploding = true
                elseif spike:GetData().MaxChainDelay then
                    isLaserChainActive = true
                end
            end

            local megashards = Isaac.FindByType(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, -1, false, false)
            for _, shard in ipairs(megashards) do
                if shard:GetData().MaxChainDelay then
                    isLaserChainActive = true
                    break
                end
            end

            local isConcurrentActive
            for _, entity in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2_NPC.id, REVEL.ENT.NARCISSUS_2_NPC.variant, -1, false, false)) do
                if entity:GetData().ConcurrentActive then
                    isConcurrentActive = true
                    break
                end
            end

            if isLaserChainActive then
                data.TimeSinceLaserChain = 0
            end

            if isSpikeExploding and (not data.AttackCooldown or data.AttackCooldown < 15) then
                data.AttackCooldown = data.bal.PostExplodeCooldown
            end

            local topLeft = REVEL.room:GetTopLeftPos()
            local roomSize = REVEL.room:GetBottomRightPos() - topLeft
            local shouldFreezeTowardPlayer = data.FreezeTowardPlayer
            local cancel
            if data.PunchPrep then
                cancel = Narcissus2Punch(npc, sprite, data, target.Position, false)
            else
                if data.ChangingPhase then
                    if npc.Position:DistanceSquared(REVEL.room:GetCenterPos()) > 16 ^ 2 then
                        npc.Velocity = npc.Velocity * data.bal.AboveMirrorWalkFriction + (REVEL.room:GetCenterPos() - npc.Position):Resized(data.bal.AboveMirrorWalkSpeed * GetNarcissusSpeedMulti(npc, data))
                    end
                else
                    local dist = data.bal.TargetPlayerDistance
                    if isSpikeExploding then
                        dist = data.bal.TargetPlayerDistanceWhileExploding
                    end

                    shouldFreezeTowardPlayer = shouldFreezeTowardPlayer or npc.Position:DistanceSquared(target.Position) < dist ^ 2
                    if not shouldFreezeTowardPlayer then
                        local targetPosition = target.Position + (npc.Position - target.Position):Resized(dist)
                        local roomRelativePosition = targetPosition - topLeft
                        -- narc 2 will stay in the middle fifth column of the room
                        local roomPartition = 5
                        local halfRoomPartition = roomPartition / 2
                        local roomPartitionX = roomSize.X / roomPartition
                        if roomRelativePosition.X < roomPartitionX * math.floor(halfRoomPartition) then
                            targetPosition = Vector(topLeft.X + roomPartitionX * math.floor(halfRoomPartition), targetPosition.Y)
                        elseif roomRelativePosition.X > roomPartitionX * math.ceil(halfRoomPartition) then
                            targetPosition = Vector(topLeft.X + roomPartitionX * math.ceil(halfRoomPartition), targetPosition.Y)
                        end

                        if math.abs(REVEL.GetAngleDifference((targetPosition - npc.Position):GetAngleDegrees(), (target.Position - npc.Position):GetAngleDegrees())) >= 90 then
                            shouldFreezeTowardPlayer = true
                        else
                            npc.Velocity = npc.Velocity * data.bal.AboveMirrorWalkFriction + (targetPosition - npc.Position):Resized(data.bal.AboveMirrorWalkSpeed * GetNarcissusSpeedMulti(npc, data))
                        end
                    end
                end
            end

            if not cancel then
                walkDir = AnimateNarcissus2Walking(npc, sprite, target.Position, shouldFreezeTowardPlayer)
                if not data.PunchPrep and not data.ChangingPhase then
                    local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
                    local changingPhase

                    for i, phaseThreshold in ipairs(data.bal.PhaseThresholds) do
                        if (not data.Phase or data.Phase < i) and npc.HitPoints < npc.MaxHitPoints * phaseThreshold then
                            if i == #data.bal.PhaseThresholds then
                                if data.PlayerHits and data.PlayerHits >= data.bal.SkipFinalPhaseHits then
                                    break
                                elseif npc.FrameCount > data.bal.SkipFinalPhaseTime then
                                    break
                                end
                            end

                            data.Phase = i
                            changingPhase = true

                            break
                        end
                    end

                    if changingPhase then
                        sprite:RemoveOverlay()
                        data.HeadState = nil
                        sprite:Play("Dive In", true)
                        data.State = "DiveIn"
                        REVEL.AnnounceAttack(data.bal.AttackNames.DiveIn)
                        local chest = Isaac.Spawn(REVEL.ENT.NARCISSUS_2_EFFECT.id, REVEL.ENT.NARCISSUS_2_EFFECT.variant, 0, REVEL.room:GetCenterPos() + Vector(0, -20), Vector.Zero, nil)
                        chest:GetSprite():Load("gfx/bosses/revel2/narcissus_2/glass_chest.anm2", true)
                        chest:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        chest:GetSprite():Play("Appear", true)
                        chest.Visible = false
                        chest:GetData().ForceReflection = true
                        chest:GetData().IsNarcissusChest = true
                        data.Chest = chest
                    end

                    if not data.AttackCooldown and walkDir and not changingPhase then
                        local attacks = {}

                        for _, attack in ipairs(data.bal.DirectAttacks) do
                            local weight = 10
                            if data.TimesUsedAttacks[attack] then
                                weight = math.max(3, weight - data.TimesUsedAttacks[attack])
                            end

                            if data.LastAttack == attack then
                                weight = weight - 3
                            end

                            if attack ~= "GroundPound" or not isConcurrentActive then
                                attacks[attack] = weight
                            end
                        end

                        if #glassSpikes > 0 then -- Spike Destruction Weighting
                            local center = REVEL.room:GetCenterPos()
                            local isOnLeft = npc.Position.X < center.X
                            local isSpikeOnSide, isSpikeOppositeSide
                            local isAlignedSpike
                            for _, spike in ipairs(glassSpikes) do
                                local spikeIsOnLeft = spike.Position.X < center.X
                                if isOnLeft ~= spikeIsOnLeft then
                                    isSpikeOppositeSide = true
                                else
                                    isSpikeOnSide = true
                                end

                                if math.abs(spike.Position.Y - npc.Position.Y) <= data.bal.PunchSpikeAlign then
                                    isAlignedSpike = true
                                end
                            end

                            if (isSpikeOnSide and not isSpikeOppositeSide) or isAlignedSpike or math.abs(npc.Position.X - center.X) <= data.bal.PunchTooCloseToCenter then
                                attacks["Punch"] = attacks["Punch"] + 5
                            else
                                attacks["Bomb"] = attacks["Bomb"] + 4
                            end

                            local roomRelativePosition = npc.Position - topLeft
                            if (roomRelativePosition.Y < roomSize.Y / 4 or roomRelativePosition.Y > (roomSize.Y / 4) * 3) then
                                attacks["Punch"] = attacks["Punch"] + 4
                            else
                                attacks["Bomb"] = attacks["Bomb"] + 4
                            end
                        end

                        if data.Phase and data.Phase >= 1 and not isConcurrentActive and data.LastAttack ~= "LaserChain" and data.TimeSinceEmerging > data.bal.LaserChainWaitAfterEmerging and #glassSpikes > 0 and (not data.TimeSinceLaserChain or data.TimeSinceLaserChain > data.bal.LaserChainWaitAfterLaserChain) then
                            attacks["LaserChain"] = 5
                        end

                        if not data.DestroyedGlassSpike then
                            local playerAngle = (target.Position - npc.Position):GetAngleDegrees()
                            for _, spike in ipairs(glassSpikes) do
                                local spikeAngle = (spike.Position - npc.Position):GetAngleDegrees()
                                local diff = math.abs(REVEL.GetAngleDifference(playerAngle, spikeAngle))
                                if diff < 45 then
                                    attacks["Bomb"] = 999
                                end
                            end
                        end

                        data.AttackCooldown = math.random(data.bal.PostAttackCooldown.Min, data.bal.PostAttackCooldown.Max)

                        local attack = REVEL.WeightedRandom(attacks)
                        REVEL.AnnounceAttack(data.bal.AttackNames[attack])
                        if attack == "Bomb" then
                            sprite:SetOverlayFrame("Bomb" .. walkDir, 0)
                            data.HeadState = "Bomb"
                        elseif attack == "GroundPound" then
                            sprite:RemoveOverlay()
                            data.HeadState = nil
                            sprite:Play("GroundPound", true)
                            data.State = "GroundPound"
                        elseif attack == "Punch" then
                            data.StateFrame = 0
                            data.PunchPrep = true
                        elseif attack == "LaserChain" then
                            sprite:RemoveOverlay()
                            data.HeadState = nil
                            sprite:Play("StartLaserChain", true)
                            data.State = "LaserChain"
                        end

                        data.LastAttack = attack
                        if not data.TimesUsedAttacks[attack] then
                            data.TimesUsedAttacks[attack] = 0
                        end
                        data.TimesUsedAttacks[attack] = data.TimesUsedAttacks[attack] + 1
                    end
                end
            end
        elseif data.State == "Punch" or data.State == "ChestPunch" then
            if data.State == "ChestPunch" and (not data.Chest or not data.Chest:Exists()) then
                data.State = "Punch"
                data.OriginallyChestPunch = true
            end

            if sprite:IsFinished("PunchStart") then
                sprite:Play("Punch", true)
            end

            if sprite:IsPlaying("Punch") then
                if sprite:IsEventTriggered("DiveIn") then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC.ROAR_S, 1, 0, false, 1)

                    if sprite.FlipX then
                        data.PunchDirection = Vector(-40, 0)
                    else
                        data.PunchDirection = Vector(40, 0)
                    end

                    if data.State == "Punch" and not data.OriginallyChestPunch then
                        REVEL.sfx:Play(SoundEffect.SOUND_SWORD_SPIN, 1, 0, false, 1)
                    elseif data.State == "ChestPunch" then
		                    REVEL.sfx:Play(SoundEffect.SOUND_METAL_BLOCKBREAK, 0.5, 0, false, 1)
		                    REVEL.sfx:Play(REVEL.SFX.NARC_CHEST_SMASH, 0.8, 0, false, 1)
                    end
                end

                if data.PunchDirection then
                    local endPunch

                    local clamp = REVEL.room:GetClampedPosition(npc.Position, 32)
                    if (clamp.X < npc.Position.X and data.PunchDirection.X >= 0) or (clamp.X > npc.Position.X and data.PunchDirection.X <= 0) then
                        if not data.OriginallyChestPunch then
                            for i = -1, 1 do
                                FireMegashard(npc.Position, data.PunchDirection:Rotated(180 + i * 30) * 0.28, npc)
                            end
                        end
                        endPunch = true
                    end

                    if data.State == "Punch" and not data.OriginallyChestPunch then
                        local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
                        for _, spike in ipairs(glassSpikes) do
                            if spike.Position:DistanceSquared(npc.Position) < (npc.Size + spike.Size) ^ 2 then
                                spike:GetData().Destroyed = true
                                endPunch = true
                            end
                        end
                    elseif data.State == "ChestPunch" then
                        if npc.Position:DistanceSquared(data.Chest.Position) < (npc.Size + 100 + data.Chest.Size) ^ 2 then
                            data.Chest:GetSprite():Play("Open", true)
                            endPunch = true
                        end
                    end

                    if npc.Visible then
                        REVEL.DashTrailEffect(npc, 2, 20, "Punch")
                    end

                    if endPunch then
                        REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS,0.8,0,false,1.2)
                        REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_GLASS_BREAK_LIGHT, 0.8, 0, false, 1)
                        REVEL.game:ShakeScreen(15)
                        npc.Velocity = Vector.Zero
                        data.PunchDirection = nil
                    end
                end

                if sprite:GetOverlayFrame() > 9 then
                    npc.Velocity = npc.Velocity * 0.8
                    data.PunchDirection = nil
                elseif data.PunchDirection then
                    npc.Velocity = data.PunchDirection
                end
            else
                npc.Velocity = npc.Velocity * 0.8
                if sprite:IsFinished("Punch") then
                    sprite.FlipX = false
                    if data.State == "Punch" and not data.OriginallyChestPunch then
                        data.State = "Idle"
                        data.HeadState = "Idle"
                    elseif data.State == "ChestPunch" then
                        data.State = "MirrorCollectItems"
                        data.UsingItems = nil
                        sprite:Play("Items", true)
                        REVEL.sfx:Play(REVEL.SFX.NARC.POWERUP, 1, 0, false, 1)
                    elseif data.OriginallyChestPunch then
                        data.State = "MirrorPrepareForDiveOut"
                    end

                    data.OriginallyChestPunch = nil
                    data.PunchDirection = nil
                else
                    if data.State == "ChestPunch" then
                        sprite.FlipX = data.Chest.Position.X < npc.Position.X
                    end
                end
            end
        elseif data.State == "GroundPound" then
            npc.Velocity = Vector.Zero
            if sprite:IsEventTriggered("LandGPound") and not data.FirstLand then
                for _, player in ipairs(REVEL.players) do
                    player.Velocity = (player.Position - npc.Position):Resized(15)
                    player:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
                    player:GetData().PoundedByNarcissus = -data.bal.GroundPoundPlayerStun
                end

                local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
                for _, spike in ipairs(glassSpikes) do
                    if spike.Position:DistanceSquared(npc.Position) < (npc.Size * 4 + spike.Size) ^ 2 then
                        spike:GetData().Destroyed = true
                    end
                end

                --[[for num = 1, 12 do
                    local dir = Vector.FromAngle(num * 30)
                    REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 8, "gfx/effects/revel1/mirror_shockwave.png", 10)
                end]]

                REVEL.game:ShakeScreen(20)
                local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, npc.Position, Vector.Zero, npc):ToEffect()
			    poof.SpriteScale = Vector(1.5,1.5)
                poof.Color = Color(4,4,4.5,0.5)

                data.FirstLand = true
            end

            if sprite:IsFinished("GroundPound") then
                data.FirstLand = nil
                data.State = "Idle"
                data.HeadState = "Idle"
            end
        elseif data.State == "LaserChain" then
            npc.Velocity = Vector.Zero
            if sprite:IsEventTriggered("Roar") then
                local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
                for _, spike in ipairs(glassSpikes) do
                    spike:GetData().MaxChainDelay = data.bal.LaserChainIntervals[#glassSpikes]
                end
            end

            if sprite:IsFinished("StartLaserChain") then
                data.FirstLand = nil
                data.State = "Idle"
                data.HeadState = "Idle"
            end
        end

        if data.HeadState then
            if walkDir == "Up" then
                sprite:SetOverlayRenderPriority(true)
            else
                sprite:SetOverlayRenderPriority(false)
            end

            if data.HeadState == "Idle" then
                if walkDir then
                    sprite:PlayOverlay("Face" .. walkDir, true)
                else
                    sprite:RemoveOverlay()
                end
            elseif data.HeadState == "Bomb" then
                sprite:SetOverlayFrame("Bomb" .. walkDir, sprite:GetOverlayFrame() + 1)
                if sprite:GetOverlayFrame() == 26 or sprite:GetOverlayFrame() == 10 then
                    REVEL.sfx:Play(REVEL.SFX.NARC.CRACK, 1, 0, false, 1)
                end

                if sprite:GetOverlayFrame() == 53 then
                    data.HeadState = "Idle"
                    data.FreezeTowardPlayer = nil
                elseif sprite:GetOverlayFrame() == 39 then
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC.ROAR_S, 1, 0, false, 1)
                    data.FreezeTowardPlayer = true
                    local shootAngle = (target.Position - npc.Position):GetAngleDegrees()
                    if not data.DestroyedGlassSpike then
                        local glassSpikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
                        for _, spike in ipairs(glassSpikes) do
                            local spikeAngle = (spike.Position - npc.Position):GetAngleDegrees()
                            local diff = math.abs(REVEL.GetAngleDifference(shootAngle, spikeAngle))
                            if diff < 30 then
                                shootAngle = spikeAngle
                            end
                        end
                    end

                    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_NORMAL, 0, npc.Position, Vector.FromAngle(shootAngle) * 16, npc)
                    bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    bomb:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
                    bomb:GetSprite():Load("gfx/effects/revel1/mirror_bomb_spiky.anm2", true)
                    bomb:GetSprite():Play("Pulse", true)
                    bomb:GetData().IsMirrorBomb = true
                    bomb:GetData().Narcissus = npc
                    bomb:GetData().Height = 25
                    bomb:ToBomb().ExplosionDamage = npc.MaxHitPoints * data.bal.BombDamage
                    bomb:ToBomb():SetExplosionCountdown(30)
                    REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_LAUNCHER, 0.6, 0, false, 1)
                end
            end
        end

        if npc.Visible then
            if sprite:IsEventTriggered("Jump") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end

            if sprite:IsEventTriggered("Land") or sprite:IsEventTriggered("LandGPound") or sprite:IsEventTriggered("LandIntro") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end
        end

        if npc:IsDead() then
            sprite:RemoveOverlay()
        end
    end, REVEL.ENT.NARCISSUS_2.id)

    local function isMegashardOpposite(npc, megashard)
        local data, mdata = npc:GetData(), megashard:GetData()
        if mdata.LockPosition then
            local isMegashard = REVEL.ENT.MEGASHARD:isEnt(npc)
            local mRotation = mdata.TargetRotation
            if isMegashard then
                return math.abs(REVEL.GetAngleDifference(mRotation, data.TargetRotation)) == 180
            else
                return math.abs(REVEL.GetAngleDifference(mRotation, data.MegashardDirection:GetAngleDegrees())) <= 45
            end
        end

        return false
    end

    local function laserChainUpdate(npc, data, isShard)
        if data.SelectedShard and not data.SelectedShard:Exists() then
            if data.Glow then
                data.Glow.FadeOut = data.bal.DangerousGlowFadeOut
            end

            data.ChainLaser = nil
            data.ChainDelay = nil
            data.MaxChainDelay = nil
            data.IsLaserTarget = nil
            return
        end

        if not data.SelectedShard then
            local validShards = {}
            for _, megashard in ipairs(Isaac.FindByType(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, -1, false, false)) do
                if isMegashardOpposite(npc, megashard) and not megashard:GetData().IsLaserTarget then
                    validShards[#validShards + 1] = megashard
                end
            end

            if #validShards > 0 then
                data.SelectedShard = validShards[math.random(1, #validShards)]
                data.SelectedShard:GetData().bal = data.bal
                data.SelectedShard:GetData().IsLaserTarget = npc
            else
                if data.Glow then
                    data.Glow.FadeOut = data.bal.DangerousGlowFadeOut
                end

                data.MaxChainDelay = nil
            end
        else
            if not data.ChainDelay then
                data.ChainDelay = data.MaxChainDelay
                data.ChainLaser = {Damaging = true, Color = data.bal.LaserChainLaser.Color, FadedColor = data.bal.LaserChainLaser.FadedColor, FadeIn = data.MaxChainDelay, PulseStartScale = data.bal.LaserChainLaser.PulseStartScale, PulseScale = data.bal.LaserChainLaser.PulseScale, PulseEndScale = data.bal.LaserChainLaser.PulseEndScale, PulseColor = data.bal.LaserChainLaser.PulseColor}
                data.Glow = {Color = data.bal.DangerousGlowColor, FadeIn = data.bal.DangerousGlowFadeIn, FadeToVisible = true}
                data.SelectedShard:GetData().Glow = {Color = data.bal.DangerousGlowColor, FadeIn = data.bal.DangerousGlowFadeIn, FadeToVisible = true}
            end

            data.ChainDelay = data.ChainDelay - 1
            if data.ChainDelay <= 0 then
                if not data.LaserChainLength then
                    data.LaserChainLength = data.bal.LaserChainLength
                end

                data.LaserChainLength = data.LaserChainLength - 1
                if data.LaserChainLength > 0 then
                    data.SelectedShard:GetData().MaxChainDelay = data.MaxChainDelay
                    data.SelectedShard:GetData().LaserChainLength = data.LaserChainLength
                else
                    data.SelectedShard:GetData().Glow.FadeOut = data.bal.DangerousGlowFadeOut
                    data.SelectedShard:GetData().IsLaserTarget = nil
                    data.SelectedShard:GetData().LaserChainLength = nil
                end

                REVEL.sfx:Play(SoundEffect.SOUND_BLOOD_LASER_SMALL)

                data.ChainLaser.PulseIn = data.bal.LaserChainLaser.PulseIn
                data.ChainLaser.PulseHold = data.bal.LaserChainLaser.PulseHold
                data.ChainLaser.PulseOut = data.bal.LaserChainLaser.PulseOut
                data.ChainLaser.PulseFinal = true
                data.Glow.FadeOut = data.bal.DangerousGlowFadeOut
                data.ChainDelay = nil
                data.MaxChainDelay = nil
                data.IsLaserTarget = nil
                data.LaserChainLength = nil
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= REVEL.ENT.MEGASHARD.variant then
            return
        end

        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

        local data, sprite = npc:GetData(), npc:GetSprite()
        local destroyed = data.Destroyed
        for _, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size) ^ 2 then
                player:TakeDamage(1, 0, EntityRef(npc), 0)
                destroyed = true
            end
        end

        if data.LockPosition then
            for _, explosion in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)) do
                if explosion.Position:DistanceSquared(npc.Position) < 100 ^ 2 then
                    destroyed = true
                end
            end
        end

        if destroyed then
            REVEL.SpawnDecoration(npc.Position, Vector.Zero, "Poof", "gfx/effects/revel1/mirror_tear_poof.anm2", npc, -1000, -1)
            npc:Remove()
            return
        end

        if not data.Variant then
            npc.PositionOffset = Vector(0, -16)
            data.NoFlipReflectionY = true
            data.Variant = tostring(math.random(1, 3))
        end

        if npc.Velocity:LengthSquared() > 2 ^ 2 then
            if not sprite:IsPlaying("flying" .. data.Variant) then
                sprite:Play("flying" .. data.Variant, true)
            end
            sprite.Rotation = npc.Velocity:GetAngleDegrees()
        end

        local clamped = REVEL.room:GetClampedPosition(npc.Position, 0)
        if not data.LockPosition and (clamped.X ~= npc.Position.X or clamped.Y ~= npc.Position.Y) then
            local diff = npc.Position - clamped
            local diffangle = diff:GetAngleDegrees()
            local velangle = npc.Velocity:GetAngleDegrees()
            if math.abs(REVEL.GetAngleDifference(diffangle, velangle)) < 46 or data.NoBounce then
                npc.Velocity = Vector.Zero
                data.LockPosition = clamped
                data.NoReflect = true
                if clamped.X ~= npc.Position.X then
                    if clamped.X > npc.Position.X then
                        data.TargetRotation = 180
                    else
                        data.TargetRotation = 0
                    end
                elseif clamped.Y > npc.Position.Y then
                    npc.PositionOffset = Vector.Zero
                    data.TargetRotation = -90
                else
                    npc.PositionOffset = Vector.Zero
                    data.TargetRotation = 90
                end

                for _, megashard in ipairs(Isaac.FindByType(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, -1, false, false)) do
                    if GetPtrHash(megashard) ~= GetPtrHash(npc) and megashard:GetData().LockPosition and megashard:GetData().LockPosition:DistanceSquared(data.LockPosition) < megashardMinimumDistance ^ 2 then
                        megashard:GetData().Destroyed = true
                    end
                end

                REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_WALL_STICK_SHARD_INSTANT, 0.6, 0, false, 1)
                sprite:Play("embed" .. data.Variant)

                npc.Position = clamped
            else
                if clamped.X ~= npc.Position.X then
                    npc.Velocity = Vector(-npc.Velocity.X, npc.Velocity.Y)
                end

                if clamped.Y ~= npc.Position.Y then
                    npc.Velocity = Vector(npc.Velocity.X, -npc.Velocity.Y)
                end
            end
        end

        if data.TargetRotation and sprite.Rotation ~= data.TargetRotation then
            sprite.Rotation = REVEL.LerpAngleDegrees(sprite.Rotation, data.TargetRotation, 0.7)
        end

        if sprite:IsFinished("embed" .. data.Variant) then
            sprite:Play("idle" .. data.Variant)
        end

        if data.LockPosition then
            npc.Position = data.LockPosition
            npc.Velocity = Vector.Zero
            npc.Mass = 1000
            npc.Size = 7
        end

        if data.IsLaserTarget and not data.IsLaserTarget:Exists() then
            data.IsLaserTarget = nil
        end

        if data.Glow then
            if not data.SelectedShard and not data.IsLaserTarget and not data.Glow.FadeOut then
                data.Glow.FadeOut = data.bal.DangerousGlowFadeOut
            end

            updateEntityGlow(npc, data.Glow)
            if data.Glow.Faded then
                data.Glow = nil
            end
        else
            npc.Color = Color.Default
        end

        if data.ChainLaser then
            updateLaser(data.ChainLaser)
            if data.ChainLaser.Faded then
                data.ChainLaser = nil
                data.SelectedShard = nil
            elseif data.ChainLaser.Pulsed and data.SelectedShard then
                for _, player in ipairs(REVEL.players) do
                    if REVEL.CollidesWithLine(player.Position, npc.Position, data.SelectedShard.Position, player.Size / 2) then
                        player:TakeDamage(1, DamageFlag.DAMAGE_LASER, EntityRef(npc), 0)
                    end
                end
            end
        end

        if data.MaxChainDelay then
            laserChainUpdate(npc, data, true)
        end
    end, REVEL.ENT.MEGASHARD.id)

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
        if npc.Variant == REVEL.ENT.NARCISSUS_2.variant and REVEL.room:GetFrameCount() > 5 and not REVEL.game:IsPaused() then
            if not revel.data.run.NarcissusTombDefeated then
                revel.data.run.NarcissusTombDefeated = true
                REVEL.MirrorRoom.SpawnNextMirror(npc)
            end

  			if not REVEL.IsAchievementUnlocked("MIRROR_BOMBS") then
  				REVEL.UnlockAchievement("MIRROR_BOMBS")
  			end

            for i, megashard in ipairs(Isaac.FindByType(REVEL.ENT.MEGASHARD.id, REVEL.ENT.MEGASHARD.variant, -1, false, false)) do
                megashard:GetData().Destroyed = true
            end

            BreakAllSpikes(false, false, true)

            REVEL.PlayJingleForRoom(REVEL.SFX.MIRROR_BOSS_2_OUTRO)
            REVEL.music:Queue(Music.MUSIC_BOSS_OVER)    
            
            -- flaming tombs if beaten in lost mode

            local currentRoom = StageAPI.GetCurrentRoom()

            if currentRoom.PersistentData.TheLostMirrorBoss then
                REVEL.FlamingTombs.SpawnDoor(true)
                if Options.MusicVolume > 0 then
                    -- play as sound to play both this and boss over
                    REVEL.sfx:Play(REVEL.SFX.SPECIAL_NARC_REWARD, Options.MusicVolume)
                end
            end
        end
    end, REVEL.ENT.NARCISSUS_2.id)

	revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
		if npc.Variant == REVEL.ENT.MEGASHARD.variant and not REVEL.game:IsPaused() then
			REVEL.sfx:Play(REVEL.SFX.NARC_GLASS_BREAK_LIGHT, 0.6, 0, false, 1)
		end
	end, REVEL.ENT.MEGASHARD.id)

    revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if player:GetData().PoundedByNarcissus then
            local data = player:GetData()
            if data.PoundedByNarcissus < 0 then
                if not REVEL.room:IsPositionInRoom(player.Position, 16) then
                    player.Velocity = Vector.Zero
                    data.PoundedByNarcissus = math.abs(data.PoundedByNarcissus)
                elseif player.Velocity:LengthSquared() < 10 then
                    data.PoundedByNarcissus = nil
                end
            else
                player.Velocity = Vector.Zero
                data.PoundedByNarcissus = data.PoundedByNarcissus - 1
                if data.PoundedByNarcissus % 4 < 2 then
                    player:GetSprite().Offset = Vector(-1, 0)
                else
                    player:GetSprite().Offset = Vector(1, 0)
                end

                if data.PoundedByNarcissus <= 0 then
                    player:GetSprite().Offset = Vector(0, 0)
                    data.PoundedByNarcissus = nil
                end
            end
        end
    end)

    local function GetNPCLaserConnection(npc, data)
        data = data or npc:GetData()
        local isGlassSpike = REVEL.ENT.GLASS_SPIKE:isEnt(npc)
        if isGlassSpike then
            return npc.Position + data.bal.GlassSpikeLaser.Offset
        else
            local rotation = npc:GetSprite().Rotation
            return npc.Position + npc.PositionOffset + Vector.FromAngle(rotation) * -8
        end
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if npc.Variant ~= REVEL.ENT.GLASS_SPIKE.variant then
            return
        end

        local sprite, data = npc:GetSprite(), npc:GetData()
        if not data.LockPosition then
            data.LockPosition = npc.Position
        else
            npc.Position = data.LockPosition
        end

        if data.TutorialSpike then
            data.NoMegashards = true
        end

        if sprite:IsEventTriggered("explode") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_GLASS_BREAK_LIGHT, 1.8, 0, false, 0.8)
            data.Glow = nil
        end

        if sprite:IsFinished("shatter") or sprite:IsFinished("shattershort") then
            npc:Remove()
            return
        end

        if data.Glow then
            updateEntityGlow(npc, data.Glow)
            if data.Glow.Faded then
                data.Glow = nil
            end
        else
            npc.Color = Color.Default
        end

        if data.ChainLaser then
            updateLaser(data.ChainLaser)
            if data.ChainLaser.Faded then
                data.ChainLaser = nil
                data.SelectedShard = nil
            elseif data.ChainLaser.Pulsed and data.SelectedShard then
                for _, player in ipairs(REVEL.players) do
                    if REVEL.CollidesWithLine(player.Position, npc.Position, data.SelectedShard.Position, player.Size / 2) then
                        player:TakeDamage(1, DamageFlag.DAMAGE_LASER, EntityRef(npc), 0)
                    end
                end
            end
        end

        if data.Destroyed then
            if not sprite:IsPlaying("shake") and not sprite:IsPlaying("shatter") and not sprite:IsPlaying("shattershort") then
                if data.NoMegashards and not data.TutorialSpike then
                    data.Animation = "shatter"
                    sprite:Play("shatter", true)
                else
                    if data.TutorialSpike then
                        data.ShakeTime = data.bal.GlassSpikeTutorialShake
                    end

                    data.Animation = "shake"
                    sprite:Play("shake", true)
                end
                npc:TakeDamage(npc.HitPoints,0,EntityRef(npc),0)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.NARC_GLASS_BREAK_LIGHT, 1.5, 0, false, 1)
            end

            if not data.ShakeTime and not sprite:IsPlaying("shatter") then
                if data.PhaseDestroyed then
                    data.ShakeTime = math.random(data.bal.GlassSpikePhaseShake.Min, data.bal.GlassSpikePhaseShake.Max)
                else
                    data.ShakeTime = math.random(data.bal.GlassSpikeShake.Min, data.bal.GlassSpikeShake.Max)
                end

                if not data.NoMegashards then
                    data.SunburstCenter = {AddRotation = data.bal.GlassSpikeSunburstCenter.AddRotation, Rotation = math.random(0, 359), Color = data.bal.GlassSpikeSunburstCenter.Color}
                    data.SunburstCenter.PulseIn = data.bal.GlassSpikeSunburstCenter.PulseIn
                    data.SunburstCenter.PulseOut = data.bal.GlassSpikeSunburstCenter.PulseOut
                    data.SunburstCenter.PulseStartScale = data.bal.GlassSpikeSunburstCenter.InitialPulseStartScale
                    data.SunburstCenter.PulseScale = data.bal.GlassSpikeSunburstCenter.InitialPulseScale
                    data.SunburstCenter.PulseEndScale = data.bal.GlassSpikeSunburstCenter.InitialPulseEndScale
                    data.Sunbursts = {}
                    data.SunburstTracers = {}
                    local baseAngle = data.MegashardDirection:GetAngleDegrees()
                    for i = 1, data.bal.GlassSpikeNumMegashards do
                        local angle = REVEL.Lerp(-data.bal.GlassSpikeMaxAngleOff, data.bal.GlassSpikeMaxAngleOff, (i - 1) / (data.bal.GlassSpikeNumMegashards - 1)) + baseAngle + math.random(-data.bal.GlassSpikeAngleVariance, data.bal.GlassSpikeAngleVariance)
                        data.Sunbursts[#data.Sunbursts + 1] = {Angle = angle, FadeIn = data.bal.GlassSpikeSunburst.FadeIn, Color = data.bal.GlassSpikeSunburst.Color}
                        local laserPos = GetNPCLaserConnection(npc, data)
                        local tracer = REVEL.MakeLaserTracerAngle(laserPos + Vector(0, -20), 99, angle)
                        local tracerExt = REVEL.SpawnLaserTracerExtension(tracer, 100, 0.9)
                        data.SunburstTracers[#data.SunburstTracers+1] = EntityPtr(tracer)
                        data.SunburstTracers[#data.SunburstTracers+1] = EntityPtr(tracerExt)
                    end

                    REVEL.Shuffle(data.Sunbursts)
                    for i, sunburst in ipairs(data.Sunbursts) do
                        sunburst.Appear = math.floor((i / #data.Sunbursts) * (data.ShakeTime - data.bal.GlassSpikeShakeEndBuffer))
                    end
                end
            end

            if data.ShakeTime then
                data.ShakeTime = data.ShakeTime - 1
                if data.ShakeTime <= 0 then
                    data.Animation = "shatter"
                    sprite:Play("shatter", true)
                    data.ShakeTime = nil
                end
            end

            if not data.NoMegashards then
                if sprite:IsEventTriggered("explode") then
                    for _, narcissus in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)) do
                        narcissus:GetData().DestroyedGlassSpike = true
                    end

                    for _, burst in ipairs(data.Sunbursts) do
                        local ms = FireMegashard(npc.Position, Vector.FromAngle(burst.Angle) * 25, npc)
                        ms:GetData().NoBounce = true
                        burst.FadeOut = data.bal.GlassSpikeSunburst.FadeOut
                    end
                    for _, tracerPtr in ipairs(data.SunburstTracers) do
                        local tracer = tracerPtr.Ref
                        if tracer then
                            tracer:Remove()
                        end
                    end
                    data.SunburstTracers = nil
                end

                for i, burst in StageAPI.ReverseIterate(data.Sunbursts) do
                    if not data.ShakeTime or (data.ShakeTime <= burst.Appear) then
                        updateLaser(burst)
                        if burst.Faded then
                            table.remove(data.Sunbursts, i)
                        end
                    end
                end

                if data.SunburstCenter then
                    local animOver = updateLaser(data.SunburstCenter)
                    if data.SunburstCenter.AnimOut and animOver then
                        data.SunburstCenter = nil
                    elseif data.SunburstCenter.PulseFinal and data.SunburstCenter.Faded then
                        data.SunburstCenter.Faded = nil
                        data.SunburstCenter.AnimOut = true
                        data.SunburstCenter.Frame = 0
                    elseif #data.Sunbursts == 0 and not data.SunburstCenter.PulseFinal then
                        data.SunburstCenter.PulseIn = data.bal.GlassSpikeSunburstCenter.PulseIn
                        data.SunburstCenter.PulseOut = data.bal.GlassSpikeSunburstCenter.PulseOut
                        data.SunburstCenter.PulseStartScale = data.bal.GlassSpikeSunburstCenter.FinalPulseStartScale
                        data.SunburstCenter.PulseScale = data.bal.GlassSpikeSunburstCenter.FinalPulseScale
                        data.SunburstCenter.PulseEndScale = data.bal.GlassSpikeSunburstCenter.FinalPulseEndScale
                        data.SunburstCenter.PulseFinal = true
                    end
                end
            end
        elseif data.MaxChainDelay then
            laserChainUpdate(npc, data, false)
        else
            if not sprite:IsPlaying("appear") and not sprite:IsPlaying("idle") then
                data.Animation = "idle"
                sprite:Play("idle", true)
            end

            local bombs = Isaac.FindByType(EntityType.ENTITY_BOMBDROP, -1, -1, false, false)
            for _, bomb in ipairs(bombs) do
                if bomb.Velocity:LengthSquared() > 5 ^ 2 and bomb.Position:DistanceSquared(npc.Position) < (npc.Size + bomb.Size) ^ 2 then
                    bomb.Velocity = (npc:GetPlayerTarget().Position - bomb.Position):Resized(bomb.Velocity:Length() * data.bal.GlassSpikeBombBounceVelMult)
                end
            end

            for _, player in ipairs(REVEL.players) do
                if player:GetData().PoundedByNarcissus or player.Velocity:LengthSquared() > 9 ^ 2 then
                    if player.Position:DistanceSquared(npc.Position) < (player.Size + npc.Size) ^ 2 then
                        data.Destroyed = true
                    end
                end
            end

            if data.HealingLaser then
                updateLaser(data.HealingLaser)
            end

            if data.HealDelay then
                data.HealDelay = data.HealDelay - 1
                local numSpikes = math.min(4, #Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false))
                if numSpikes == 4 then
                    data.HealDelay = data.HealDelay - 1
                end

                if data.HealDelay <= 0 then
                    data.HealDelay = data.bal.GlassSpikeHealFrequency
                    data.Healing = data.bal.GlassSpikeHealingLength
                end

                if data.Healing then
                    data.Healing = data.Healing - 1
                    if data.Healing >= 0 then
                        local multi = 1 / data.bal.GlassSpikeHealingLength
                        for _, narcissus in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)) do
                            if narcissus.HitPoints < narcissus.MaxHitPoints and not narcissus:GetData().Death and narcissus:GetData().PhaseStartingHP then
                                local heal
                                if narcissus.HitPoints < narcissus:GetData().PhaseStartingHP then
                                    heal = narcissus.MaxHitPoints * data.bal.GlassSpikeHealWhenLower[numSpikes]
                                elseif narcissus.HitPoints < narcissus.MaxHitPoints then
                                    heal = narcissus.MaxHitPoints * data.bal.GlassSpikeHealWhenHigher
                                end

                                narcissus.HitPoints = math.min(narcissus.MaxHitPoints, narcissus.HitPoints + (heal * multi))
                            end
                        end

                        if not data.HealingLaser then
                            data.HealingLaser = {Color = data.bal.GlassSpikeLaser.HealColor, FadeIn = data.bal.GlassSpikeLaser.FadeIn}
                        end

                        if not data.Glow then
                            data.Glow = {Color = data.bal.GlassSpikeHealColor, FadeToVisible = true}
                        end
                    else
                        if not data.HealingLaser.Faded and not data.HealingLaser.FadeOut then
                            data.HealingLaser.FadeOut = data.bal.GlassSpikeFlashFadeTime
                        end

                        if data.Glow and not data.Glow.Faded and not data.Glow.FadeOut then
                            data.Glow.FadeOut = data.bal.GlassSpikeFlashFadeTime
                        end

                        if not data.Glow or data.Glow.Faded then
                            data.Healing = nil
                        end
                    end
                elseif data.HealingLaser then
                    data.HealingLaser = nil
                end
            end
        end
    end, REVEL.ENT.GLASS_SPIKE.id)

    local function Narc2LasersRender(npc)
        local isGlassSpike = REVEL.ENT.GLASS_SPIKE:isEnt(npc)
        local isMegashard = REVEL.ENT.MEGASHARD:isEnt(npc)
        if not isGlassSpike and not isMegashard then
            return
        end

        local data = npc:GetData()
        local laserStart = GetNPCLaserConnection(npc, data)

        if isGlassSpike then
            if data.Sunbursts then
                renderSunbursts(data.SunburstCenter, data.Sunbursts, laserStart, data.ShakeTime, data.bal.GlassSpikeBurstOffset)
            end

            if data.HealingLaser and not data.Destroyed then
                for _, narcissus in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)) do
                    renderLaser(data.HealingLaser, laserStart, narcissus.Position + data.bal.GlassSpikeLaser.HealNarcOffset)
                end
            end
        end

        if data.ChainLaser then
            renderLaser(data.ChainLaser, laserStart, GetNPCLaserConnection(data.SelectedShard))
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local narc2Ents = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, -1, -1, false)
        for _, ent in ipairs(narc2Ents) do
            Narc2LasersRender(ent)
        end
    end)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags)
        if e.Variant == REVEL.ENT.GLASS_SPIKE.variant then
            if HasBit(flags, DamageFlag.DAMAGE_EXPLOSION) then
                e:GetData().Destroyed = true
                return false
            end

            if e.HitPoints - amount - REVEL.GetDamageBuffer(e) <= 0 then
                e.HitPoints = REVEL.GetDamageBuffer(e)
                e.MaxHitPoints = 0
                e:GetData().Destroyed = true
                return false
            end

            if e:GetData().Destroyed then
                local flashRed, flashDuration = Color(1,0.5,0.5,1,150,0,0), 3
			    e:SetColor(flashRed, flashDuration, 1, false, false)
                return false
            end
        end
    end, REVEL.ENT.GLASS_SPIKE.id)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags)
        if e.Variant == REVEL.ENT.NARCISSUS_2_NPC.variant then
            if e:GetData().Invulnerable then
                return false
            end
        end
    end, REVEL.ENT.NARCISSUS_2_NPC.id)

    StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(e, amount, flags, source, frames)
        local narcissus = Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)
        if #narcissus > 0 then
            for _, npc in ipairs(narcissus) do
                local data = npc:GetData()
                if not data.PlayerHits then
                    data.PlayerHits = 0
                end

                data.PlayerHits = data.PlayerHits + 1

                if data.ActiveItems then
                    for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                        if item.PlayerTakeDamage then
                            item.PlayerTakeDamage(e, amount, flags, source, frames, npc, data, npc:GetSprite(), npc:ToNPC():GetPlayerTarget())
                        end
                    end
                end
            end
        end
    end, EntityType.ENTITY_PLAYER)

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e, amount, flags, source, frames)
        if e.Variant == REVEL.ENT.NARCISSUS_2.variant then
            local data = e:GetData()

            if data.ActiveItems then
                for _, item in ipairs(GetActiveEffects(data.ActiveItems)) do
                    if item.BossTakeDamage then
                        item.BossTakeDamage(e, amount, flags, source, frames, data, e:GetSprite(), e:ToNPC():GetPlayerTarget())
                    end
                end
            end

            if data.State == "MirrorInitial" 
            or data.State == "MirrorIdle" 
            or data.State == "MirrorPrepareForDiveOut" 
            or data.State == "MirrorCollectItems" 
            or data.State == "WaitForMirrorDiveOut" 
            or data.State == "ActAsReflection" 
            or data.State == "ChestPunch" 
            then
                return false
            elseif REVEL.ENT.GLASS_SPIKE:countInRoom() >= 4
            or REVEL.ENT.CUSTOM_SHOCKWAVE:countInRoom() >= 4
            or e:GetSprite():IsPlaying("Dive Out") then -- narc 2 takes reduced damage before a pillar has been destroyed
                local dmgReduction = amount * 0.8
		        e.HitPoints = math.min(e.HitPoints + dmgReduction, e.MaxHitPoints)
            end
        end
    end, REVEL.ENT.NARCISSUS_2.id)

    if narc2Balance.GlassSpikeScale ~= 1 then
        revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
            local spikes = Isaac.FindByType(REVEL.ENT.GLASS_SPIKE.id, REVEL.ENT.GLASS_SPIKE.variant, -1, false, false)
            for _, spike in ipairs(spikes) do
                spike.SpriteScale = Vector.One * spike:GetData().bal.GlassSpikeScale
            end
        end)
    end

    function REVEL.GetNarc2Chest()
        local narcEffects = Isaac.FindByType(REVEL.ENT.NARCISSUS_2_EFFECT.id, REVEL.ENT.NARCISSUS_2_EFFECT.variant, -1, false, false)
        for _, eff in ipairs(narcEffects) do
            if eff:GetData().IsNarcissusChest then
                return eff
            end
        end
    end

    function REVEL.RuinNarc2Items()
        for _, narcissus in ipairs(Isaac.FindByType(REVEL.ENT.NARCISSUS_2.id, REVEL.ENT.NARCISSUS_2.variant, -1, false, false)) do
            if narcissus:GetData().UsingItemIndices then
                for _, index in ipairs(narcissus:GetData().UsingItemIndices) do
                    local spriteData = Narcissus2ItemSprites[index]
                    spriteData.Gfx = "breakfast"
                    spriteData.Sprite:ReplaceSpritesheet(0, "gfx/bosses/revel2/narcissus_2/items/breakfast.png")
                    spriteData.Sprite:LoadGraphics()
                end

                narcissus:GetData().UsingItems = {}
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, id)
        if id == CollectibleType.COLLECTIBLE_D20 or id == CollectibleType.COLLECTIBLE_D100 or id == CollectibleType.COLLECTIBLE_MOVING_BOX or id == CollectibleType.COLLECTIBLE_COMPOST or id == CollectibleType.COLLECTIBLE_CROOKED_PENNY then
            local chest = REVEL.GetNarc2Chest()
            if chest then
                if id == CollectibleType.COLLECTIBLE_D20 or id == CollectibleType.COLLECTIBLE_D100 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.NO_ITEM, chest.Position, RandomVector() * 2, nil)
                elseif id == CollectibleType.COLLECTIBLE_COMPOST then
                    REVEL.player:AddBlueFlies(3, chest.Position, REVEL.player)
                end

                chest:Remove()
            end
        end

        if id == CollectibleType.COLLECTIBLE_D6 or id == CollectibleType.COLLECTIBLE_D100 then
            REVEL.RuinNarc2Items()
        end
    end)

    revel:AddCallback(ModCallbacks.MC_USE_CARD, function(_, card)
        if card == Card.CARD_ACE_OF_CLUBS or card == Card.CARD_ACE_OF_DIAMONDS or card == Card.CARD_ACE_OF_HEARTS or card == Card.CARD_ACE_OF_SPADES or card == Card.CARD_DICE_SHARD or card == Card.RUNE_BLACK then
            local chest = REVEL.GetNarc2Chest()
            if chest then
                if card == Card.CARD_ACE_OF_CLUBS then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0, chest.Position, RandomVector() * 2, nil)
                elseif card == Card.CARD_ACE_OF_DIAMONDS then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, chest.Position, RandomVector() * 2, nil)
                elseif card == Card.CARD_ACE_OF_HEARTS then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, chest.Position, RandomVector() * 2, nil)
                elseif card == Card.CARD_ACE_OF_SPADES then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, 0, chest.Position, RandomVector() * 2, nil)
                elseif card == Card.CARD_DICE_SHARD then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.NO_ITEM, chest.Position, RandomVector() * 2, nil)
                elseif card == Card.RUNE_BLACK then
                    REVEL.player:AddBlueFlies(3, chest.Position, REVEL.player)
                end

                chest:Remove()
            end
        end

        if card == Card.CARD_DICE_SHARD or card == Card.RUNE_PERTHRO then
            REVEL.RuinNarc2Items()
        end
    end)
end

Isaac.DebugString("Revelations: Loaded Mirror for Chapter 2!")
end