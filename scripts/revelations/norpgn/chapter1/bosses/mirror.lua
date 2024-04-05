local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

return function()

local Narc = {
    WalkFrame = 0,
    SpawnOffset = Vector(0,84),
    LastAnim = "WalkDown",
    MusicStartTimePhase1 = 4270, --in ms
    MusicStartTime = 26181, --in ms
    ReflectionDieAnimDur = 8, -- in frames
    NarcBreakEventTime = 30, -- in frames
    Directions = {
        Right = Vector(1, 0),
        Left = Vector(-1, 0),
        Down = Vector(0, 1),
        Up = Vector(0, -1)
    },
    MinDistance = 140, -- Stays (Direction * Distance) away from the player, adds VerticalDistanceOffset if moving vertically.
    MaxDistance = 220,
    VerticalDistanceOffset = -50,
    MinDistanceResetTimer = 5,
    MaxDistanceResetTimer = 20,
    TearDodgeThreshold = 2.5, -- Multiplies tear / laser size by threshold, then checks if colliding. If so, dodge.
    LaserDodgeThreshold = 6,
    TearDodgeStrength = 3, -- When dodging a tear / laser, moves away a distance of (objSize * dodgeStrength)
    LaserDodgeStrength = 10,
    BombThrowVel = 12,
    BombDodgeRadius = 100, -- Checks if within (BombDodgeRadius * bomb.RadiusMultiplier * BombDodgeRadiusMultiplier) + npc.Size of a bomb, if so, dodge by moving to the edge of that radius.
    BombDodgeRadiusMultiplier = 3,
    BombSelfDamage = 20,
    BaseSpeedMulti = 0.9, -- PlayerSpeed * BaseSpeedMulti = BaseSpeed
    PhaseTwoSpeedMulti = 1.5, -- BaseSpeed * PhaseTwoSpeedMulti = BaseSpeedPhaseTwo
    Deaccel = 0.9, -- Multiplies velocity by this, then adds direction resized to BaseSpeed[PhaseTwo]
    MaxFireDelay = 30,
    FireDelayAttackMulti = 1.5, -- FireDelay multiplied by this is added to the boss immediately after using an attack.
    HomingTime = 600, -- How long Telepathy for Dummies lasts
    EyeOffsets = {
        HeadUp = {
            Left = Vector(-7, -15),
            Right = Vector(6, -15)
        },
        HeadDown = {
            Left = Vector(6, -10),
            Right = Vector(-7, -10)
        },
        HeadRight = {
            Left = Vector(2, -8),
            Right = Vector(2, -2)
        },
        HeadLeft = {
            Left = Vector(-2, -2),
            Right = Vector(-2, -8)
        }
    },
    ShootFrame = 4, -- as events in overlays don't work
}
local walkAnims = {"WalkDown", "WalkUp", "WalkLeft", "WalkRight"}

function Narc.NarcNotStomping(sprite)
  --  REVEL.DebugToString({sprite:GetAnimation(), "Frame", sprite:GetFrame()})
  return not sprite:WasEventTriggered("Stomp") or (sprite:WasEventTriggered("Walk") and not sprite:WasEventTriggered("Stomp2"))
end

function Narc.AnimWalkFrame(vel, spr, data)
  if vel.X ~= 0 and vel.Y ~= 0 then
    if math.abs(vel.X) > math.abs(vel.Y) then
      if vel.X < 0 and not spr:IsPlaying("WalkLeft") then
        spr:Play("WalkLeft", true)
        REVEL.SkipAnimFrames(spr, Narc.WalkFrame+1)
      elseif vel.X > 0 and not spr:IsPlaying("WalkRight") then
        spr:Play("WalkRight", true)
        REVEL.SkipAnimFrames(spr, Narc.WalkFrame+1)
      end
    else
      if vel.Y < 0 and not spr:IsPlaying("WalkUp") then
        spr:Play("WalkUp", true)
        REVEL.SkipAnimFrames(spr, Narc.WalkFrame+1)
      elseif vel.Y > 0 and not spr:IsPlaying("WalkDown") then
        spr:Play("WalkDown", true)
        REVEL.SkipAnimFrames(spr, Narc.WalkFrame+1)
      end
    end
  else
    local playingWalkAnim
    for i,v in ipairs(walkAnims) do
      if spr:IsPlaying(v) then playingWalkAnim = true end
    end

    if not playingWalkAnim then
      spr:Play(Narc.LastAnim, true)
      REVEL.SkipAnimFrames(spr, Narc.WalkFrame+1)
    end
  end
  Narc.WalkFrame = spr:GetFrame()
  Narc.LastAnim = spr:GetAnimation()
end

function Narc.SpawnMirrorCrack(npc, scale, timeMult)
    local mc = Isaac.Spawn(1000, 8, 0, npc.Position, Vector.Zero, npc)
    local spr = mc:GetSprite()
    scale = scale or 1
    timeMult = timeMult or 1
    spr:Load("gfx/bosses/revel1/narcissus/narcissus_first_phase.anm2", true)
    spr:Play("UsingTammysHead", true)
    spr:ReplaceSpritesheet(15, "gfx/backdrop/none.png")
    spr:ReplaceSpritesheet(12, "gfx/backdrop/none.png")
    spr:ReplaceSpritesheet(23, "gfx/backdrop/none.png")
    spr:ReplaceSpritesheet(4, "gfx/backdrop/none.png")
    spr:LoadGraphics()
    spr.Scale = Vector(scale, scale)
    mc:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
    REVEL.GetData(mc).noReflection = true

    REVEL.FadeEntity(mc, 50*timeMult, 50*timeMult)
end

function Narc.GetFacingDirection(npc, target)
    local dir
    local diffX, diffY = target.Position.X - npc.Position.X, target.Position.Y - npc.Position.Y
    if math.abs(diffX) > math.abs(diffY) then
        if diffX < 0 then
            dir = Narc.Directions.Left
        else
            dir = Narc.Directions.Right
        end
    else
        if diffY < 0 then
            dir = Narc.Directions.Up
        else
            dir = Narc.Directions.Down
        end
    end

    return dir
end

-- Moves Narc and his arm and plays animations.
---@param npc EntityNPC
---@param data any
---@param sprite Sprite
---@param target any
---@param room any
---@param player any
function Narc.Move(npc, data, sprite, target, room, player)
    local notStomping = Narc.NarcNotStomping(sprite)

    if notStomping then
        local walkToward

        if not data.TargetDistance then
            data.TargetDistance = math.random(Narc.MinDistance, Narc.MaxDistance)
            data.DistanceResetTimer = math.random(Narc.MinDistanceResetTimer, Narc.MaxDistanceResetTimer)
        end

        data.DistanceResetTimer = data.DistanceResetTimer - 1
        if data.DistanceResetTimer <= 0 then
            data.TargetDistance = math.random(Narc.MinDistance, Narc.MaxDistance)
            data.DistanceResetTimer = math.random(Narc.MinDistanceResetTimer, Narc.MaxDistanceResetTimer)
        end


        -- Tries to maintain aligned with the player at a varying distance, and prefers being closer to the center to avoid wall hugging and restrict the player.
        local aimTo
        local dist
        for name, offset in pairs(Narc.Directions) do
            local tDist = data.TargetDistance
            if name == "Up" or name == "Down" then
                tDist = tDist + Narc.VerticalDistanceOffset
            end

            local off = target.Position + offset * tDist
            local distance = off:Distance(room:GetCenterPos())
            if not dist or distance < dist then
                dist = distance
                aimTo = off
            end
        end

        if aimTo then
            walkToward = aimTo
        end

        local e = REVEL.roomTears
        for _,v in ipairs(REVEL.roomLasers) do
            table.insert(e, v)
        end

        -- For all Tears and Lasers, if close to colliding with them, aim to move toward a position 90 degrees opposite their velocity / line.
        for _,v in ipairs(e) do
            if v.SpawnerType == EntityType.ENTITY_PLAYER or v.SpawnerType == EntityType.ENTITY_FAMILIAR or not v:ToLaser() then
                if v:ToLaser() then
                    local laser = v:ToLaser()
                    if REVEL.CollidesWithLaser(npc.Position, laser, laser.Size * Narc.LaserDodgeThreshold + npc.Size) then
                        local aimTo
                        if REVEL.LineDistance(npc.Position, laser.Position, laser:GetEndPoint()) < 0 then
                            aimTo = (Vector.FromAngle(laser.Angle + 90) * laser.Size) * Narc.LaserDodgeStrength + npc.Position
                        else
                            aimTo = (Vector.FromAngle(laser.Angle - 90) * laser.Size) * Narc.LaserDodgeStrength + npc.Position
                        end

                        if aimTo then
                            walkToward = aimTo
                        end
                    end
                elseif (v.Position:Distance(npc.Position) <= ((v.Size * Narc.TearDodgeThreshold + npc.Size))) then
                    local aimTo
                    if REVEL.LineDistance(npc.Position, v.Position, v.Position + v.Velocity) < 0 then
                        aimTo = v.Velocity:Rotated(90):Resized(v.Size) * Narc.TearDodgeStrength + npc.Position
                    else
                        aimTo = v.Velocity:Rotated(-90):Resized(v.Size) * Narc.TearDodgeStrength + npc.Position
                    end

                    if aimTo then
                        walkToward = aimTo
                    end
                end
            end
        end

        -- Evades bombs
        for _, v in ipairs(REVEL.roomBombdrops) do
            local bombDodgeRadius = (Narc.BombDodgeRadius * v:ToBomb().RadiusMultiplier * Narc.BombDodgeRadiusMultiplier) + npc.Size
            if v.Type == EntityType.ENTITY_BOMBDROP and v.Position:Distance(npc.Position) < bombDodgeRadius then
                local away = (npc.Position - v.Position)
                walkToward = v.Position + away:Resized(bombDodgeRadius)
            end
        end

        if walkToward and npc.Position:Distance(walkToward) > npc.Size then
            local speed = Narc.BaseSpeedMulti
            if data.Phase2 then
                speed = speed * Narc.PhaseTwoSpeedMulti
            end

            npc.Velocity = npc.Velocity * Narc.Deaccel + (walkToward - npc.Position):Resized(speed)
        else
            npc.Velocity = npc.Velocity * Narc.Deaccel
        end
    else
        npc.Velocity = Vector.Zero
    end

    Narc.AnimWalkFrame(npc.Velocity, sprite, data)

    if sprite:IsEventTriggered("Stomp") or sprite:IsEventTriggered("Stomp2") then
        REVEL.game:ShakeScreen(3)
        Narc.SpawnMirrorCrack(npc, 0.3, 0.3)
        if math.random(3) == 1 then
            REVEL.sfx:Play(REVEL.SFX.NARC.CRACK, 0.4, 0, false, 0.9+math.random()*0.15)
        else
            REVEL.sfx:Play(REVEL.SFX.NARC.STOMP, 0.4, 0, false, 0.9+math.random()*0.15)
        end
    end

    -- SHOOTING
    local dir = Narc.GetFacingDirection(npc, target)

    local inherit
    if dir.X == 0 then
        inherit = Vector(npc.Velocity.X, 0)
    else
        inherit = Vector(0, npc.Velocity.Y)
    end

    local len = inherit:Length()
    if len > 4 then
        inherit = inherit * 4 / len
    end

    local shootVelocity = dir:Resized(data.ShotSpeed) + inherit

    local anim
    if dir.X < 0 then
        anim  = "HeadLeft"
    elseif dir.X > 0 then
        anim = "HeadRight"
    elseif dir.Y < 0 then
        anim = "HeadUp"
    elseif dir.Y > 0 then
        anim = "HeadDown"
    end

    if data.Phase2 then
        local shootAnim = anim .. "_Shoot"

        if REVEL.MultiOverlayPlayingCheck(sprite, "HeadLeft_Shoot", "HeadUp_Shoot", "HeadRight_Shoot", "HeadDown_Shoot") then
            if not sprite:IsOverlayPlaying(shootAnim) then
                sprite:SetOverlayAnimation(shootAnim)
            end

            if sprite:GetOverlayFrame() == Narc.ShootFrame then
                local eyeOffset
                data.LeftEye = not data.LeftEye
                if data.LeftEye then
                    eyeOffset = "Left"
                else
                    eyeOffset = "Right"
                end
                Narc.FireTear(npc, npc.Position + Narc.EyeOffsets[anim][eyeOffset], shootVelocity, player)
                data.FireDelay = data.MaxFireDelay
                REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
            end
        else
            data.FireDelay = data.FireDelay - 1
            if data.FireDelay <= 0 then
                sprite:PlayOverlay(shootAnim, true)
                data.FireDelay = data.MaxFireDelay * 0.5 -- in case it gets interrupted mid anim
            else
                sprite:SetOverlayFrame(anim, 1)
            end
        end
    else
        data.FireDelay = data.FireDelay - 1
        if data.FireDelay <= 3 then
            sprite:SetOverlayFrame(anim, 2)
        else
            sprite:SetOverlayFrame(anim, 1)
        end
    
        if data.FireDelay <= 0 then
            local eyeOffset
            data.LeftEye = not data.LeftEye
            if data.LeftEye then
                eyeOffset = "Left"
            else
                eyeOffset = "Right"
            end
            Narc.FireTear(npc, npc.Position + Narc.EyeOffsets[anim][eyeOffset], shootVelocity, player)
            data.FireDelay = data.MaxFireDelay
            REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
        end
    end
end

Narc.Attacks = {
    BookOfShadows = {
        Weight = 0,
        DecreaseBy = 6,
        Type = "Main",
        Item = "bookofshadows",
        Check = function(npc, data, target, weight)
            if not data.UsedBookOfShadows and npc.HitPoints < npc.MaxHitPoints / 5 then
                return 6
            end
        end,
        Trigger = function(npc, data)
            data.InvulnerableCouldown = 150
            data.UsedBookOfShadows = true
        end
    },
    Kamikaze = {
        Weight = 0,
        DecreaseBy = 6,
        Type = "Main",
        Item = "kamikaze",
        Check = function(npc, data, target, weight)
            if npc.HitPoints < npc.MaxHitPoints / 8 then
                if data.UsedBookOfShadows then
                    return 4
                else
                    return 1
                end
            end
        end,
        Trigger = function(npc)
            Isaac.Explode(npc.Position, nil, npc.HitPoints + 1)
        end
    },
    GlassCannon = {
        Weight = 0,
        DecreaseBy = 6,
        Type = "Main",
        Item = "glasscannon",
        Check = function(npc, data, target, weight)
            if npc.HitPoints < npc.MaxHitPoints / 8 then
                if data.UsedBookOfShadows then
                    return 6
                else
                    return 1
                end
            end
        end,
        Trigger = function(npc, data, target, player)
            data.UsedGlassCannon = true
            Narc.FireTear(npc, npc.Position, Narc.GetFacingDirection(npc, target) * data.ShotSpeed, player, false, 3, true)
            REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_BULLET_SHOT, 1, 0, false, 1)
        end
    },
    YumHeart = {
        Weight = 0,
        DecreaseBy = 2,
        Type = "Main",
        Item = "yumheart",
        Check = function(npc, data, target, weight)
            if (not data.TimesUsedYumHeart or data.TimesUsedYumHeart < 2) and npc.HitPoints < npc.MaxHitPoints / 3 then
                return 2
            end
        end,
        Trigger = function(npc, data)
            data.TimesUsedYumHeart = data.TimesUsedYumHeart or 0
            data.TimesUsedYumHeart = data.TimesUsedYumHeart + 1
            npc.HitPoints = math.min(npc.HitPoints + npc.MaxHitPoints / 10, npc.MaxHitPoints)
            REVEL.sfx:Play(REVEL.SFX.NARC.HOLY, 0.6, 0, false, 0.85+math.random()*0.15)
            REVEL.sfx:Play(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 0.8)
        end
    },
    Bomb = {
        Weight = 4,
        DecreaseBy = 4,
        Type = "Distractor",
        SpriteType = "Bomb",
        Trigger = function(npc, data, target)
            local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_NORMAL, 0, npc.Position, (target.Position-npc.Position):Resized(Narc.BombThrowVel), npc)
            bomb.Parent = npc
            bomb:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
            bomb:GetSprite():Load("gfx/effects/revel1/mirror_bomb_spiky.anm2", true)
            bomb:GetSprite():Play("Pulse", true)
            REVEL.GetData(bomb).IsMirrorBomb = true
            REVEL.GetData(bomb).Narcissus = npc
            REVEL.GetData(bomb).Height = 25
            REVEL.sfx:Play(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
        end
    },
    ShockwaveRound = {
        Weight = 1,
        DecreaseBy = 1,
        Type = "Main",
        SpriteType = "Shockwave",
        Trigger = function(npc, data)
            REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 1)
            Narc.SpawnMirrorCrack(npc)
            REVEL.game:ShakeScreen(30)
            for num = 1, 12 do
                local dir = Vector.FromAngle(num * 30)
                REVEL.SpawnCustomShockwave(npc.Position + dir * 25, dir * 4, "gfx/effects/revel1/mirror_shockwave.png", 30, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            end
        end
    },
    ShockwaveSuperRound = {
        Weight = 2,
        DecreaseBy = 2,
        Type = "Distractor",
        SpriteType = "Shockwave",
        Trigger = function(npc, data, target)
            REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 1)
            Narc.SpawnMirrorCrack(npc)
            REVEL.game:ShakeScreen(30)
            for i = 1, 6 do
                local dir = Vector.FromAngle(i * 60)
                REVEL.SpawnCustomShockwave(npc.Position + dir * 15, dir * 10, "gfx/effects/revel1/mirror_shockwave.png", nil, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            end
        end
    },
    ShockwaveDirect = {
        Weight = 1,
        DecreaseBy = 1,
        Type = "Main",
        SpriteType = "Shockwave",
        Trigger = function(npc, data, target)
            REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 0.5, 0, false, 1)
            Narc.SpawnMirrorCrack(npc)
            REVEL.game:ShakeScreen(30)
            for num = -2, 2 do
                local dir = Vector.FromAngle(num * 7 + (target.Position - npc.Position):GetAngleDegrees())
                REVEL.SpawnCustomShockwave(npc.Position + dir * 15, dir * 10, "gfx/effects/revel1/mirror_shockwave.png", nil, nil, nil, nil, nil, SoundEffect.SOUND_ROCK_CRUMBLE)
            end
        end
    },
    TammysHead = {
        Weight = 2,
        DecreaseBy = 2,
        Type = "Main",
        Item = "tammyshead",
        Trigger = function(npc, data, target, player)
            for i=1, 8 do
                Narc.FireTear(npc, npc.Position, Vector.FromAngle(i * 45) * data.ShotSpeed, player)
            end
            REVEL.sfx:Play(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
        end
    },
    BoxOfSpiders = {
        Weight = 1,
        DecreaseBy = 1,
        Type = "Distractor",
        Item = "boxofspiders",
        Check = function()
            if #Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, true) >= 3 then
                return 0
            end
        end,
        Trigger = function(npc, data)
            for i = 1, math.random(2, 3) do
                Isaac.Spawn(EntityType.ENTITY_SPIDER, 0, 0, npc.Position + RandomVector() * 15, Vector.Zero, npc)
            end
            REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
        end
    },
    GuppyHead = {
        Weight = 2,
        DecreaseBy = 2,
        Type = "Distractor",
        Item = "guppyshead",
        Check = function()
            if #Isaac.FindByType(EntityType.ENTITY_FLY, -1, -1, false, true) >= 5 then
                return 0
            end
        end,
        Trigger = function(npc, data)
            for i = 1, math.random(3, 4) do
                Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, npc.Position + RandomVector() * 15, Vector.Zero, npc)
            end
            REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
        end
    },
    ShoopDaWhoop = {
        Weight = 1,
        DecreaseBy = 1,
        Type = "Main",
        Item = "shoopdawhoop",
        Check = function(npc)
            if not REVEL.room:IsPositionInRoom(npc.Position, 64) then
                return 0
            end
        end,
        Trigger = function(npc, data, target)
            local dir = Narc.GetFacingDirection(npc, target)
            local t = EntityLaser.ShootAngle(1, npc.Position + Vector(0,-100), dir:GetAngleDegrees(), 20, Vector.Zero, npc)
            t.DepthOffset = -1000
            t.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
            t:GetSprite().Color = Color(0,0,0,1,conv255ToFloat(225,225,255))
            data.ShoopLaser = t
        end,
        Until = function(npc, data)
            if data.ShoopLaser and not data.ShoopLaser:Exists() then
                data.ShoopLaser = nil
                return true
            end
        end
    },
    AnarchistCookbook = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "anarchistscookbook",
        Type = "Distractor",
        Trigger = function(npc, data, target, player, sprite)
            data.BombsToDrop = math.random(3, 4)
            data.BombTimer = math.random(4, 8)
            local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombSubType.BOMB_TROLL, 0, REVEL.room:FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 0, true), Vector.Zero, npc):ToBomb()
            bomb.ExplosionDamage = 1
            bomb.Parent = npc
        end,
        Update = function(npc, data, target, player, sprite)
            if data.BombsToDrop then
                data.BombTimer = data.BombTimer - 1
                if data.BombTimer <= 0 then
                    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombSubType.BOMB_TROLL, 0, REVEL.room:FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 0, true), Vector.Zero, npc):ToBomb()
                    bomb.ExplosionDamage = 1
                    bomb.Parent = npc
                    data.BombTimer = math.random(4, 8)
                    data.BombsToDrop = data.BombsToDrop - 1
                    if data.BombsToDrop <= 0 then
                        data.BombsToDrop = nil
                    end
                end
            end
        end,
        Until = function(npc, data, target, player, sprite)
            if data.BombsToDrop then
                data.BombTimer = data.BombTimer - 1
                if data.BombTimer <= 0 then
                    local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombSubType.BOMB_TROLL, 0, REVEL.room:FindFreePickupSpawnPosition(Isaac.GetRandomPosition(), 0, true), Vector.Zero, npc):ToBomb()
                    bomb.ExplosionDamage = 1
                    bomb.Parent = npc
                    data.BombTimer = math.random(4, 8)
                    data.BombsToDrop = data.BombsToDrop - 1
                    if data.BombsToDrop <= 0 then
                        data.BombsToDrop = nil
                    end
                end
            else
                return true
            end
        end
    },
    MonstrosTooth = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "monstrostooth",
        Types = {"Distractor", "Main"},
        Trigger = function(npc, data, target)
            local monstro = Isaac.Spawn(REVEL.ENT.NARCISSUS_MONSTROS_TOOTH.id, REVEL.ENT.NARCISSUS_MONSTROS_TOOTH.variant, 0, npc.Position, Vector.Zero, npc)
            monstro:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            local msprite, mdata = monstro:GetSprite(), REVEL.GetData(monstro)
            msprite:Play("JumpDown", true)
            mdata.NarcMonstroDecoration = true
            mdata.Target = target
            monstro.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
            monstro.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end
    },
    Teleporter = {
        Weight = 2,
        DecreaseBy = 2,
        Item = "teleport",
        Type = "Distractor",
        Trigger = function(npc, data, target, player, sprite)
            sprite:Play("TeleportUp", true)
            REVEL.sfx:Play(SoundEffect.SOUND_HELL_PORTAL2, 1, 0, false, 1)
        end,
        Update = function(npc, data, target, player, sprite)
            if sprite:IsFinished("TeleportUp") then
                local targetPos = (target.Position - target.Velocity:Normalized():Resized(50))
                if not REVEL.room:IsPositionInRoom(targetPos, 32) then
                    targetPos = REVEL.room:GetCenterPos()
                end

                npc.Position = targetPos
                sprite:Play("TeleportDown", true)
                REVEL.sfx:Play(SoundEffect.SOUND_HELL_PORTAL1, 1, 0, false, 1)
            end

            if sprite:IsFinished("TeleportDown", true) then
                return true
            end
        end
    },
    DoctorsRemote = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "doctorsremote",
        Types = {"Distractor", "Main"},
        Trigger = function(npc, data, target)
            local targetData = REVEL.GetData(Isaac.Spawn(REVEL.ENT.NARCISSUS_DOCTORS_TARGET.id, REVEL.ENT.NARCISSUS_DOCTORS_TARGET.variant, 0, npc.Position, Vector.Zero, npc))
            targetData.Target = target
            targetData.Timer = 80
            targetData.NPC = npc
        end
    },
    TelepathyForDummies = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "telepathyfordummies",
        Type = "Main",
        ChangeWeights = {
            TammysHead = 2
        },
        Check = function(npc, data, target, weight)
            if data.HomingTimer and data.HomingTimer > 0 then
                return 0
            end
        end,
        Trigger = function(npc, data, target)
            data.HomingTimer = Narc.HomingTime
        end
    },
    BobsRottenHead = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "bobsrottenhead",
        Type = "Main",
        Trigger = function(npc, data, target)
            local dir = Narc.GetFacingDirection(npc, target)
            local t = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_TEAR, 0, npc.Position, dir * data.ShotSpeed, npc):ToProjectile()
            REVEL.GetData(t).NarcBobsHead = true
            t:GetSprite():Load("gfx/002.004_bobs head tear.anm2", true)
            t:GetSprite():Play("Idle", true)
            
            REVEL.sfx:Play(SoundEffect.SOUND_SHELLGAME, 0.7, 0, false, 1)
        end
    },
    ButterBean = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "butterbean",
        Types = {"Main", "Distractor"},
        Check = function(npc, data, target)
            local playerInRange
            for _, player in ipairs(REVEL.players) do
                if player.Position:Distance(npc.Position) < 300 then
                    playerInRange = true
                end
            end

            if not playerInRange then
                return 0
            end
        end,
        Trigger = function(npc, data, target)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, npc.Position, Vector.Zero, npc).Color = Color(1.8, 0.7, 1.5, 1,conv255ToFloat( 0, 0, 0))
            REVEL.sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1)

            for _, player in ipairs(REVEL.players) do
                local dist = player.Position:Distance(npc.Position)
                if dist < 300 then -- Strength of push scales down exponentially the further you are from the boss
                    local distanceFromMax = ((300 - dist) / 300)
                    local strength = (distanceFromMax * distanceFromMax) * 20
                    player:AddVelocity((player.Position - npc.Position):Resized(strength))
                    player:AddEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
                end
            end
        end
    },
    BlueCandle = {
        Weight = 1,
        DecreaseBy = 1,
        Item = "bluecandle",
        Type = "Main",
        Trigger = function(npc, data, target)
            local dir = Narc.GetFacingDirection(npc, target)
            local fireEnt = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LADDER, 0, npc.Position, dir * math.random(80, 110) * 0.1, npc)
            fireEnt.Size = 24
            fireEnt.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            local fireData, fireSprite = REVEL.GetData(fireEnt), fireEnt:GetSprite()
            fireData.Scale = 1.5
            fireData.OriginalSize = 24
            fireData.SpecialFire = true
            fireData.Shrinking = true
            fireData.Friction = 0.95
            fireData.ShrinkSpeed = 0.005
            fireSprite:Load("gfx/effects/revel1/freezer_burn_fire.anm2", true)
            fireSprite.Color = Color(0, 1, 1, 1,conv255ToFloat( 0, 0, 255))
            fireSprite:Play("Idle", true)
            REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1)
        end
    }
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data, sprite = REVEL.GetData(eff), eff:GetSprite()
    if data.NarcMonstroDecoration then
        if sprite:IsFinished("JumpUp") then
            eff:Remove()
            return
        end

        if sprite:IsPlaying("JumpDown") and sprite:GetFrame() == 34 then
            Narc.SpawnMirrorCrack(eff)
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            for _, player in ipairs(REVEL.players) do
                if player.Position:Distance(eff.Position) < 50 then
                    player:TakeDamage(1,0,EntityRef(eff),0)
                end
            end
        end

        if sprite:IsPlaying("JumpDown") and sprite:GetFrame() < 25 then
            eff.Velocity = (data.Target.Position - eff.Position):Resized(5)
        else
            eff.Velocity = eff.Velocity * 0.7
        end

        if sprite:IsFinished("JumpDown") then
            sprite:Play("Taunt", true)
        end

        if sprite:IsPlaying("Taunt") and sprite:GetFrame() == 21 then
            local shoot = Isaac.Spawn(EntityType.ENTITY_MONSTRO, 0, 0, eff.Position, Vector.Zero, eff):ToNPC()
            shoot:FireBossProjectiles(16, data.Target.Position, 0, ProjectileParams())
            REVEL.sfx:NpcPlay(shoot, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 1, 0, false, 1)
            shoot:Remove()
        end

        if sprite:IsFinished("Taunt") then
            sprite:Play("JumpUp", true)
        end
    end
end, REVEL.ENT.NARCISSUS_MONSTROS_TOOTH.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data, sprite = REVEL.GetData(eff), eff:GetSprite()
    sprite:Play("Blink", false)
    if not data.Rocket then
        data.Timer = data.Timer - 1
        if data.Timer <= 0 then
            data.Rocket = Isaac.Spawn(REVEL.ENT.NARCISSUS_DOCTORS_ROCKET.id, REVEL.ENT.NARCISSUS_DOCTORS_ROCKET.variant, 0, eff.Position, Vector.Zero, nil)
            data.Rocket:GetSprite():Play("Falling", true)
            REVEL.GetData(data.Rocket).Height = -300
            data.Rocket.SpriteOffset = Vector(0, REVEL.GetData(data.Rocket).Height)
        end

        eff.Velocity = eff.Velocity * 0.925 + (data.Target.Position - eff.Position):Resized(1)
    else
        data.Rocket.Position = eff.Position
        data.Rocket:GetSprite():Play("Falling", false)
        local rdata = REVEL.GetData(data.Rocket)
        rdata.Height = rdata.Height + 30
        if rdata.Height >= -5 then
            Isaac.Explode(eff.Position, data.NPC, 20)
            Narc.SpawnMirrorCrack(eff)
            eff:Remove()
            data.Rocket:Remove()
        else
            data.Rocket.SpriteOffset = Vector(0, rdata.Height)
            eff.Velocity = Vector.Zero
        end
    end
end, REVEL.ENT.NARCISSUS_DOCTORS_TARGET.variant)

for k, v in pairs(Narc.Attacks) do
    v.Name = k
    if not v.SpriteType then
        v.SpriteType = "Item"
    end
end

Narc.AttackSpriteTypes = {
    Item = {
        OnActivate = function(npc, data, sprite, attack)
            sprite:ReplaceSpritesheet(3, "gfx/bosses/revel1/narcissus/items/" .. attack.Item .. ".png")
            sprite:LoadGraphics()
            data.FireDelay = Narc.MaxFireDelay * Narc.FireDelayAttackMulti
        end,
        Anim = "UseItem",
        EndAnim = "UseItemEnd",
        Trigger = "Item"
    },
    Bomb = {
        OnActivate = function(npc, data)
            data.FireDelay = Narc.MaxFireDelay * Narc.FireDelayAttackMulti
        end,
        Anim = "ThrowBomb",
        Trigger = "ThrowBomb"
    },
    Shockwave = {
        OnActivate = function(npc, data)
            data.FireDelay = Narc.MaxFireDelay * Narc.FireDelayAttackMulti
        end,
        Anim = "Smash",
        EndAnim = "SmashRelease",
        Trigger = "Shockwave"
    }
}

Narc.Patterns = {
    {"Distractor", "Main", Weight = 3},
    {"Distractor", "Pause", "Main", Weight = 3},
    {"Distractor", "Main", "Main", Weight = 1},
    {"Distractor", "Pause", "Main", "Main", Weight = 2}
}

Narc.TotalPatternWeight = 0
for _, pattern in ipairs(Narc.Patterns) do
    Narc.TotalPatternWeight = Narc.TotalPatternWeight + pattern.Weight
end

function Narc.SelectAttacks(npc, data, target)
    local possibleAttacks = {}
    for _, attack in pairs(Narc.Attacks) do
        local weight = attack.Weight
        if attack.Check then
            local result = attack.Check(npc, data, target, weight)
            if result ~= nil then
                weight = result
            end
        end

        if weight and weight > 0 then
            possibleAttacks[attack.Name] = {Weight = weight, Attack = attack}
        end
    end

    local pattern = StageAPI.WeightedRNG(Narc.Patterns, nil, "Weight", Narc.TotalPatternWeight)
    local attacks = {}
    for _, attackType in ipairs(pattern) do
        if attackType == "Pause" then
            attacks[#attacks + 1] = "Pause"
        else
            local weight = 0
            local attacksOfType = {}
            for name, attack in pairs(possibleAttacks) do
                if attack.Attack.Type == attackType or attack.Attack.Types and REVEL.includes(attack.Attack.Types, attackType) then
                    attacksOfType[#attacksOfType + 1] = {Attack = attack.Attack, Weight = attack.Weight}
                    weight = weight + attack.Weight
                end
            end

            if #attacksOfType > 0 then
                local selectedAttack = StageAPI.WeightedRNG(attacksOfType, nil, "Weight", weight)
                if selectedAttack.Attack.ChangeWeights then
                    for name, weight in pairs(selectedAttack.Attack.ChangeWeights) do
                        if possibleAttacks[name] then
                            possibleAttacks[name].Weight = possibleAttacks[name].Weight + weight
                        end
                    end
                end
                possibleAttacks[selectedAttack.Attack.Name].Weight 
                    = possibleAttacks[selectedAttack.Attack.Name].Weight 
                        - (possibleAttacks[selectedAttack.Attack.Name].Attack.DecreaseBy or 0)
                attacks[#attacks + 1] = selectedAttack.Attack
            end
        end
    end

    return attacks
end

function Narc.StartAttack(npc, data, target, sprite, attack)
    local attackSpriteData = Narc.AttackSpriteTypes[attack.SpriteType]
    if attackSpriteData.OnActivate then
        attackSpriteData.OnActivate(npc, data, sprite, attack)
    end

    sprite:RemoveOverlay()
    sprite:Play(attackSpriteData.Anim, true)
end

-- Returns true when attack ends
function Narc.EnactAttack(npc, data, target, sprite, attack, player)
    npc.Velocity = npc.Velocity * 0.5
    local attackSpriteData = Narc.AttackSpriteTypes[attack.SpriteType]

    if attack.Trigger and sprite:IsEventTriggered(attackSpriteData.Trigger) then
        attack.Trigger(npc, data, target, player, sprite)
    end

    if attack.Update then
        if attack.Update(npc, data, target, player, sprite) then
            return true
        end
    end

    if sprite:IsFinished(attackSpriteData.Anim) then
        if not attack.Until or attack.Until(npc, data, target, player, sprite) then
            if not attackSpriteData.EndAnim then
                return true
            else
                sprite:Play(attackSpriteData.EndAnim, true)
            end
        end
    end

    if attackSpriteData.EndAnim and sprite:IsFinished(attackSpriteData.EndAnim) then
        return true
    end
end

local MusicPlayStartTime = -1
local SkipPhase1Music = false


local function narc1_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.NARCISSUS.variant then
        return
    end

    local data, sprite, target = REVEL.GetData(npc), npc:GetSprite(), npc:GetPlayerTarget()
    local player
    if target:ToPlayer() then
        player = target:ToPlayer()
    else
        player = REVEL.player
    end

    local room = REVEL.room
    if not data.Init then
        if not REVEL.HasReflectionsInRoom() then
            REVEL.AddReflections(1, true, true)
        end

        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        sprite:Play("Appear")

        REVEL.SetScaledBossHP(npc)
        --npc.MaxHitPoints = math.max(200, REVEL.EstimateDPS(player) * 20)
        --npc.HitPoints = npc.MaxHitPoints

        data.ShotSpeed = 10

        data.MaxFireDelay = Narc.MaxFireDelay
        data.FireDelay = data.MaxFireDelay
        data.State = "Appear"
        data.deathCounter = 105 --for death fallback
        data.InvulnerableCouldown = 0
        data.Init = true
    end

    if data.HomingTimer then
        data.HomingTimer = data.HomingTimer - 1
    end

    local timeSinceMusicStart = Isaac.GetTime() - MusicPlayStartTime
    local bossMusicStartTimecode = Narc.MusicStartTime - (Narc.NarcBreakEventTime + Narc.ReflectionDieAnimDur) * 1000 / 30

    --If boss music is about to start, kill Isaac reflection and spawn narciccus
    if timeSinceMusicStart >= bossMusicStartTimecode and not data.Phase2 and not data.timedSuicide then
        sprite:Play("Die", false)
        sprite:RemoveOverlay()
        data.State = "Appear"
        npc.Velocity = Vector.Zero
        data.timedSuicide = true
    end

    -- Appear state, run through twice, at fight start and when Narcissus enters phase two.
    if data.State == "Appear" then
        npc.Velocity = Vector.Zero
        if sprite:IsFinished("Appear") then
            data.State = "Idle"
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            data.reflectOffset = Vector.Zero
            data.ReflectRenderLayer = nil
            sprite.Offset = Vector.Zero

            if data.Phase2 then
                revel.data.seenNarcissusGlacier = true
            end
        end

        if sprite:IsPlaying("Appear") and not data.Phase2 then
            if sprite:GetFrame() == 68 then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end
        end

        if sprite:IsPlaying("Appear") and data.Phase2 then
            local oy = math.max( 12 - math.max(0, sprite:GetFrame()-32), 0 ) * -52 / 12
            data.reflectOffset = Vector(0, oy)
            data.ReflectRenderLayer = 1
        end

        if sprite:IsFinished("Die")  then
            if not data.Phase2 then
                data.Phase2 = true
                sprite:Load("gfx/bosses/revel1/narcissus/narcissus.anm2", true)
                sprite:Play("Appear", true)

                if data.Light then
                REVEL.GetData(data.Light).LightOffset = Vector(0, -35)
                end

                sprite.Offset = Vector(0,-32)
                npc.Position = REVEL.room:GetCenterPos()+Narc.SpawnOffset
                npc.Velocity = Vector.Zero
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

            elseif data.Phase2 then
                npc:Remove()
            end
        end

        if sprite:IsEventTriggered("Break") then
            if data.SkipIntro and sprite:IsPlaying("Appear") then
                SkipPhase1Music = true
            end
            REVEL.sfx:Play(REVEL.SFX.NARC.BREAK, 0.8, 0, false, 1)
        elseif sprite:IsEventTriggered("Stomp") then
            REVEL.game:ShakeScreen(30)
            REVEL.sfx:Play(REVEL.SFX.NARC.STOMP, 1, 0, false, 1)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        elseif sprite:IsEventTriggered("Roar") then
            REVEL.sfx:Play(REVEL.SFX.NARC.ROAR, 1, 0, false, 1)
        elseif sprite:IsEventTriggered("Crack") then
            REVEL.sfx:Play(REVEL.SFX.NARC.CRACK, 0.8, 0, false, 1)
        end
    end

    if data.Phase2 then
        if not data.MoveTimer then
            data.MoveTimer = math.random(100, 200)
        end

        data.MoveTimer = data.MoveTimer - 1
    end

    -- Idle / Move for a time from 150 to 300 frames, and select an attack afterward.
    if data.State == "Idle" then
        Narc.Move(npc, data, sprite, target, room, player)
        if data.Phase2 and data.MoveTimer <= 0 then -- Attack Selection + Start
            --[[

            3 main forms of attack: Distractor, Main, and Pause
            Distractor attacks include spawning enemies and throwing bombs, and work best to add extra threat to other attacks.
            Main Attacks are directed at the player and pose an immediate threat, or work well with restricted areas that the distractors create.
            Pause is simply the Idle moving and shooting state.

            Usually attacks are Distractor then Main, but sometimes more rarely they're Distractor, then Pause, then Main

            Attacks in both the main and distractor pools will not be selected twice.

            ]]
            data.Attacks = Narc.SelectAttacks(npc, data, target)
            if #data.Attacks > 0 then
                if data.Attacks[1] ~= "Pause" then
                    Narc.StartAttack(npc, data, target, sprite, data.Attacks[1])
                else
                    data.MoveTimer = math.random(25, 45)
                end
                data.State = "Attack"
            end
        end
    elseif data.State == "Attack" then
        if data.Attacks[1] ~= "Pause" then
            local ended = Narc.EnactAttack(npc, data, target, sprite, data.Attacks[1], player)
            if ended then
                table.remove(data.Attacks, 1)
                if #data.Attacks > 0 then
                    if data.Attacks[1] ~= "Pause" then
                        Narc.StartAttack(npc, data, target, sprite, data.Attacks[1])
                    else
                        data.MoveTimer = math.random(25, 45)
                    end
                else
                    data.MoveTimer = math.random(100, 200)
                    data.State = "Idle"
                end
            end
        else
            Narc.Move(npc, data, sprite, target, room, player)
            if data.MoveTimer <= 0 then
                table.remove(data.Attacks, 1)
                if #data.Attacks > 0 then
                    if data.Attacks[1] ~= "Pause" then
                        Narc.StartAttack(npc, data, target, sprite, data.Attacks[1])
                    else
                        data.MoveTimer = math.random(25, 45)
                    end
                else
                    data.MoveTimer = math.random(100, 200)
                    data.State = "Idle"
                end
            end
        end
    end

    if data.InvulnerableCouldown and data.InvulnerableCouldown > 0 then
        data.InvulnerableCouldown = data.InvulnerableCouldown-1
    end

    if sprite:IsEventTriggered("Powerup") then
        REVEL.sfx:Play(REVEL.SFX.NARC.POWERUP, 1, 0, false, 1)
    end

    --no matter what, if at 0 HP due to whatever WACKY then die after 2 sec and force death after 4 and force removal after 7
    if npc.HitPoints <= 0 and not IsAnimOn(sprite, "Die") then
        if data.deathCounter > 0 then
            if data.deathCounter == 75 then
                sprite:Play("Die", true)
                sprite:RemoveOverlay()
                data.State = "Appear"
                npc.Velocity = Vector.Zero
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end

            if data.deathCounter == 45 then
                npc:Die()
            end

            data.deathCounter = data.deathCounter - 1
        else
            npc:Remove()
        end
    end
end

Narc.BubbleSprite = REVEL.LazyLoadRoomSprite{
    ID = "Narc2_BubbleSprite",
    Anm2 = "gfx/effects/revel1/mirror_book_of_shadows.anm2",
    Animation = "Shine",
    Offset = Vector(0, -3),
}
Narc.BubbleOddFrame = false

Narc.ArmSprite = REVEL.LazyLoadRoomSprite{
    ID = "Narc2_ArmSprite",
    Anm2 = "gfx/bosses/revel1/narcissus/narcissus.anm2",
    Animation = "BigArm",
    Offset = Vector(0, 5),
}

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER , function(_, npc, offset)
    if npc.Variant ~= REVEL.ENT.NARCISSUS.variant or not REVEL.IsRenderPassNormal() then return end

    local data, sprite = REVEL.GetData(npc), npc:GetSprite()

    if data.Phase2 and not data.Dying and npc:HasMortalDamage() then
        sprite:Play("Die")
        sprite:RemoveOverlay()
        data.State = "Appear"
        npc.Velocity = Vector.Zero
        npc.HitPoints = 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:RemoveStatusEffects()
        data.Dying = true
        npc.State = NpcState.STATE_UNIQUE_DEATH
    end

    if data.Dying then
        data.DeathRenderCounter = data.DeathRenderCounter and (data.DeathRenderCounter + 1) or 1
        if data.DeathRenderCounter%2 == 1 then

            if sprite:IsEventTriggered("Break") then
                REVEL.sfx:Play(REVEL.SFX.NARC.BREAK, 0.8)
            elseif sprite:IsEventTriggered("Crack") then
                REVEL.sfx:Play(REVEL.SFX.NARC.CRACK, 0.8, 0, false, 1)
            end
        end
    end

    if sprite:IsFinished("Die") then
        if data.Phase2 then
            npc:Remove()
        end
    end

    Narc.OddFrame = not Narc.OddFrame and not REVEL.game:IsPaused()
    if Narc.OddFrame then
        Narc.ArmSprite:Update()
    end

    if data.Phase2 and sprite:IsPlaying("WalkLeft") then
        Narc.ArmSprite.Color = sprite.Color
        Narc.ArmSprite:Render(Isaac.WorldToRenderPosition(npc.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end

    if data.InvulnerableCouldown and data.InvulnerableCouldown > 0 then
        if Narc.OddFrame then
            Narc.BubbleSprite:Update()
        end

        Narc.BubbleSprite:Render(Isaac.WorldToRenderPosition(npc.Position) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end, REVEL.ENT.NARCISSUS.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
    if not (npc.Variant == REVEL.ENT.NARCISSUS.variant and REVEL.room:GetFrameCount() > 5 and not REVEL.game:IsPaused()) then return end

    REVEL.SpawnDecoration(npc.Position, Vector.Zero, "DeathGibs", "gfx/bosses/revel1/narcissus/narcissus.anm2")

    if not revel.data.run.NarcissusGlacierDefeated then
        revel.data.run.NarcissusGlacierDefeated = true
        REVEL.MirrorRoom.SpawnNextMirror(npc)
    end
    
    if not REVEL.IsAchievementUnlocked("MIRROR_BOMBS") then
        REVEL.UnlockAchievement("MIRROR_BOMBS")
    end

    REVEL.MirrorRoomDead = true
    REVEL.GetMirrorDeadSprite():Play("FadeIn", true)

    REVEL.PlayJingleForRoom(REVEL.MUSIC.MIRROR_BOSS_OUTRO)
    REVEL.music:Queue(Music.MUSIC_BOSS_OVER)

    -- dante satan if beaten in lost mode

    local currentRoom = StageAPI.GetCurrentRoom()

    if currentRoom.PersistentData.TheLostMirrorBoss then
        REVEL.DanteSatan2.SpawnDoor(true)
        REVEL.PlayJingleForRoom(REVEL.MUSIC.SPECIAL_NARC_REWARD_JINGLE)
    end
end, REVEL.ENT.NARCISSUS.id)

local spoonBenderColor = Color(0.4, 0.15, 0.15, 1,conv255ToFloat( math.floor(0.27843138575554 * 255), 0, math.floor(0.45490199327469 * 255)))

function Narc.FireTear(npc, pos, vel, player, normalLook, scale, isLarge)
    local t = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_TEAR, 0, pos, vel, npc):ToProjectile()
    local data, spr = REVEL.GetData(t), t:GetSprite()
    t.SpawnerType = npc.Type
    t.SpawnerVariant = npc.Variant
    t.Parent = npc
    t.Target = player
    if scale then
        t.Scale = scale
        t:AddScale(0)
    end

    if REVEL.GetData(npc).Phase2 then
    t.Height = t.Height-20
    else
    t.Height = t.Height-5
    end

    t.HomingStrength = t.HomingStrength / 3
    if REVEL.GetData(npc).HomingTimer and REVEL.GetData(npc).HomingTimer > 0 then
        spr.Color = spoonBenderColor
        t:AddProjectileFlags(ProjectileFlags.SMART)
    end

    if not normalLook then
        if isLarge then
            spr:Load("gfx/effects/revel1/mirror_tear_large.anm2", true)
            spr:Play("Rotate6", true)
        else
            spr:Load("gfx/effects/revel1/mirror_tear.anm2", true)
            spr:Play("Rotate"..tostring(math.random(1,4)))
        end
    end
end

--REPLACE PROJ POOFS
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, function(p, data, spr, spawner, grandpa)
    local fname = spawner:GetSprite():GetFilename()
    if fname == "gfx/effects/revel1/mirror_tear.anm2" or fname == "gfx/effects/revel1/mirror_tear_large.anm2" then
        --    spr:Load("gfx/mirror_tear_poof.anm2", true)
        --    spr:Play("Poof", true)
        local e = REVEL.SpawnDecoration(p.Position, Vector.Zero, "Poof", "gfx/effects/revel1/mirror_tear_poof.anm2", p, -1000, -1, nil, nil, nil, true)
        p:Remove()
        e.SpriteOffset = Vector(0, spawner.Height)
    end

    if REVEL.GetData(spawner).NarcBobsHead then
        p:Remove()
    end
end)

local function narc1_Narc_EntTakeDmg(_, e, dmg, flag, src, invuln)
    if e:GetSprite():IsPlaying("Appear") or e:GetSprite():IsPlaying("Die") or REVEL.GetData(e).InvulnerableCouldown ~= 0 then
        return false
    elseif not REVEL.GetData(e).Phase2 
    and e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= e.MaxHitPoints * 0.85 then
        e.HitPoints = e.MaxHitPoints*0.85
        e:GetSprite():Play("Die")
        e:GetSprite():RemoveOverlay()
        REVEL.GetData(e).State = "Appear"
        REVEL.GetData(e).SkipIntro = true
        e.Velocity = Vector.Zero
        REVEL.MusicFadeOut(Narc.NarcBreakEventTime + Narc.ReflectionDieAnimDur, 0.1)
    end

    if REVEL.GetData(e).UsedGlassCannon then
        REVEL.GetData(e).UsedGlassCannon = false
        local dmgInduction = dmg*5.0
		e.HitPoints = math.min(e.HitPoints - dmgInduction, e.MaxHitPoints)
        REVEL.sfx:Play(SoundEffect.SOUND_GLASS_BREAK, 1, 0, false, 1)
    end

    if HasBit(flag, DamageFlag.DAMAGE_EXPLOSION) and dmg <= 2 then
        local bombDmg = Narc.BombSelfDamage
        e.HitPoints = math.min(e.HitPoints - bombDmg, e.MaxHitPoints)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE , function(_, bomb)
    local data = REVEL.GetData(bomb)
    if data.IsMirrorBomb then
        if bomb.FrameCount <= 10 then
            bomb.Mass = 600
        else
            bomb.Mass = 6
        end

        data.Height = data.Height-(bomb.FrameCount/4)
        if data.Height < 0 then data.Height = 0 end
        bomb:GetSprite().Offset = Vector(0, -data.Height)

        if data.TutorialBomb and bomb.FrameCount >= 45 then
            local glassSpikes = REVEL.ENT.GLASS_SPIKE:getInRoom(-1, false, false)
            for _, spike in ipairs(glassSpikes) do
                REVEL.GetData(spike).Destroyed = true
            end

            REVEL.game:ShakeScreen(20)
            local explosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0, bomb.Position, Vector.Zero, nil)
            explosion.Visible = false
            REVEL.GetData(explosion).ForceReflection = true

            bomb:Remove()
        end

        if bomb:IsDead() and data.Narcissus and not data.MirrorTears and not data.TutorialBomb then
            data.MirrorTears = true
            Narc.SpawnMirrorCrack(bomb)

            local shotspeed = REVEL.GetData(data.Narcissus).ShotSpeed
            if not shotspeed then
                shotspeed = 10
            end

            for i=0, 5 do
                Narc.FireTear(data.Narcissus, bomb.Position, Vector.FromAngle(i * 60) * shotspeed, REVEL.player)
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Type == EntityType.ENTITY_PROJECTILE and REVEL.GetData(ent).NarcBobsHead then
        REVEL.game:BombExplosionEffects(ent.Position, 20, TearFlags.TEAR_POISON, Color(0.02, 0.5, 0.02, 1,conv255ToFloat( 0, 84, 0)), ent, 1, true, true)
        local gas = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, ent.Position, Vector.Zero, ent):ToEffect()
        gas.Timeout = 200
        Narc.SpawnMirrorCrack(ent)
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, narc1_NpcUpdate, REVEL.ENT.NARCISSUS.id)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, narc1_Narc_EntTakeDmg, REVEL.ENT.NARCISSUS.id)

-----------------
-- MIRROR ROOM --
-----------------
do
    local GlacierMirrorBackdrop = {
        Walls = {"gfx/backdrop/revel1/mirror/mirror.png"}
    }

    local didVSScreen = false

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, isFirstLoad)
        if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR then
            REVEL.MirrorRoomCracked = nil
            REVEL.MirrorRoomDead = nil

            if REVEL.STAGE.Tomb:IsStage() then
                REVEL.TombLoadMirrorRoom()
            elseif REVEL.STAGE.Glacier:IsStage() then
                StageAPI.SetBossEncountered("Narcissus 1")
                StageAPI.ChangeBackdrop(GlacierMirrorBackdrop)
                REVEL.AddReflections(1, true, true)

                if revel.data.run.NarcissusGlacierDefeated then
                    REVEL.GetMirrorDeadSprite():Play("Default", true)
                    REVEL.MirrorRoomDead =  true

                    REVEL.GetMirrorCrackedSprite():SetFrame("Break", 90)
                    REVEL.MirrorRoomCracked = true
                elseif revel.data.seenNarcissusGlacier then
                    REVEL.DebugStringMinor("Playing narc 1 VS screen")
                    local narcBoss = REVEL.find(REVEL.Bosses.ChapterOne, 
                        function(boss) return boss.Name == "Narcissus 1" end)
                    REVEL.music:Play(REVEL.MUSIC.MIRROR_BOSS_JINGLE, Options.MusicVolume)
                    REVEL.PlayBossAnimationNoPause(narcBoss, function() --on skip
                        REVEL.StopMusicTrack(REVEL.MUSIC.MIRROR_BOSS_JINGLE)
                    end)
                end

                didVSScreen = true
            end
        end
    end)

    local WasPlayingMusic = false
    local StartedMusicInRoom = -1

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, 1, function(stage, musicID, roomType, rng)
        if StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR and REVEL.STAGE.Glacier:IsStage() then
            local currentMusicID = REVEL.music:GetCurrentMusicID()
            local replaced = false

            if currentMusicID == REVEL.MUSIC.MIRROR_BOSS_JINGLE and not StageAPI.PlayingBossSprite then
                REVEL.DebugStringMinor("Stopping narc VS screen track as it ended...")
                REVEL.StopMusicTrack()
                replaced = true
            end

            if (StageAPI.CanOverrideMusic(currentMusicID) or replaced)
            and didVSScreen
            and not revel.data.run.NarcissusGlacierDefeated then
                if not WasPlayingMusic then
                    WasPlayingMusic = true
                    StartedMusicInRoom = StageAPI.GetCurrentRoomID()
                    MusicPlayStartTime = Isaac.GetTime()
                    REVEL.DebugToString("Started narc music...")
                end

                if SkipPhase1Music then
                    return REVEL.MUSIC.MIRROR_BOSS_NOINTRO
                else
                    return REVEL.MUSIC.MIRROR_BOSS
                end
            elseif WasPlayingMusic then
                WasPlayingMusic = false
                SkipPhase1Music = false
                MusicPlayStartTime = -1
                StartedMusicInRoom = -1
            end

            if not WasPlayingMusic
            and revel.data.run.NarcissusGlacierDefeated then
                return REVEL.MUSIC.BOSS_CALM
            end
        elseif WasPlayingMusic then
            WasPlayingMusic = false
            SkipPhase1Music = false
            MusicPlayStartTime = -1
            StartedMusicInRoom = -1
        end
    end)

    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
        didVSScreen = false
    end)

    local function mirrorRoomPostUpdate()
        local room = REVEL.room
        local level = REVEL.game:GetLevel()

        if not revel.data.run.NarcissusGlacierDefeated and REVEL.STAGE.Glacier:IsStage() and StageAPI.GetCurrentRoomType() == RevRoomType.MIRROR then
            --If music trigger is passed
            local timeSinceMusicStart = Isaac.GetTime() - MusicPlayStartTime

            local spawnTimePassed = timeSinceMusicStart >= Narc.MusicStartTimePhase1 and
                (timeSinceMusicStart < Narc.MusicStartTime - 3000 
                    or timeSinceMusicStart >= Narc.MusicStartTime)

            if StartedMusicInRoom == StageAPI.GetCurrentRoomID() and room:GetFrameCount() > 5
            and spawnTimePassed
            and Isaac.CountEntities(nil, REVEL.ENT.NARCISSUS.id, REVEL.ENT.NARCISSUS.variant, -1) == 0 then
                local off = Vector(-15, 35)
                local narcissus = Isaac.Spawn(REVEL.ENT.NARCISSUS.id, REVEL.ENT.NARCISSUS.variant, 0, room:GetCenterPos() + off, Vector.Zero, nil)
                REVEL.room:SetClear(false)

                --If past proper boss music, skip isaac's reflection intro
                if timeSinceMusicStart >= Narc.MusicStartTime then
                    REVEL.GetData(narcissus).Phase2 = true
                    local spr = narcissus:GetSprite()
                    spr:Load("gfx/bosses/revel1/narcissus/narcissus.anm2", true)
                    spr:Play("Appear", true)
                    spr.Offset = Vector(0,-32)
                    narcissus.Position = REVEL.room:GetCenterPos() + Narc.SpawnOffset
                end

                REVEL.MirrorRoomCracked = true

                REVEL.GetMirrorCrackedSprite():Play("Break", true)
                REVEL.game:ShakeScreen(30)
                if Options.MusicVolume > 0 then
                    REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 0.33)
                else
                    REVEL.sfx:Play(REVEL.SFX.GLASS_BREAK, 1)
                end
                REVEL.GetData(narcissus).Light = REVEL.SpawnLightAtEnt(narcissus, Color.Default, 1.5, Vector(0, -20))

                if REVEL.DEBUG then
                    if timeSinceMusicStart >= Narc.MusicStartTime then
                        REVEL.DebugToString("Spawned narcissus reflection (phase 2, late music trigger)")
                    else
                        REVEL.DebugToString("Spawned narcissus reflection normally (phase 1, music trigger)")
                    end
                end
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, mirrorRoomPostUpdate)
end

end