return function()

local monsnow_angle = {}
local monsnow_tear_angle = {}

local monsnowProjectileVariant = ProjectileVariant.PROJECTILE_TEAR

local monsnowProjectile = ProjectileParams()
monsnowProjectile.Variant = monsnowProjectileVariant
monsnowProjectile.Scale = 4

local monsnowFallingProjectile = ProjectileParams()
monsnowFallingProjectile.HeightModifier = -300
monsnowFallingProjectile.Variant = monsnowProjectileVariant
monsnowFallingProjectile.FallingAccelModifier = 0.6
monsnowFallingProjectile.VelocityMulti = 0.5

local function monsnow_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.MONSNOW.variant then
        return
    end

    local data,spr = npc:GetData(), npc:GetSprite()

    local room = REVEL.room
    npc.SplatColor = REVEL.SnowSplatColor
    local player = npc:GetPlayerTarget()

    if not data.Init then
        data.IsChampion = false --REVEL.IsChampion(npc)
        --REVEL.SetScaledBossHP(npc)
        if data.IsChampion then
            npc.MaxHitPoints = npc.MaxHitPoints * 1.13
            --npc.MaxHitPoints = math.max(npc.MaxHitPoints, REVEL.EstimateDPS(REVEL.player) * 26)
            npc.HitPoints = npc.MaxHitPoints
            spr:ReplaceSpritesheet(0, "gfx/bosses/revel1/monsnow/monsnow_champion.png")
            spr:LoadGraphics()
        else
            --npc.MaxHitPoints = math.max(npc.MaxHitPoints, REVEL.EstimateDPS(REVEL.player) * 23)
            --npc.HitPoints = npc.MaxHitPoints
        end

        data.Init = true
    end

    if spr:IsPlaying("Roll Horizontal") or spr:IsPlaying("Roll Diagonal") or spr:IsPlaying("RollBackwards") then
        local crushableEnemies = Isaac.FindByType(REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant, -1, false, false)
        if data.IsChampion and npc.State == 23 or npc.State == 26 then
            crushableEnemies = REVEL.ConcatTables(crushableEnemies, Isaac.FindByType(REVEL.ENT.ROLLING_SNOWBALL.id, REVEL.ENT.ROLLING_SNOWBALL.variant, -1, false, false))
        end

        for _, enemy in ipairs(crushableEnemies) do
            if enemy.Position:Distance(npc.Position) < enemy.Size + npc.Size + 12 then
                for i = 1, math.random(2, 4) do
                    local projectile = npc:FireBossProjectiles(1, Vector.Zero, 8, monsnowProjectile)
                    local pdata = projectile:GetData()
                    projectile.Velocity = projectile.Velocity * 0.5
                    projectile.Position = enemy.Position
                    pdata.Flomp = true
                    pdata.ChangeToSnow = true
                    pdata.RandomizeScaleSmall = true
                end
                enemy:Kill()
            end
        end

        local frequency = 9
        if data.IsChampion then
            frequency = 12
        end

        if npc.FrameCount % frequency == 0 then
            local creep = REVEL.SpawnIceCreep(npc.Position, npc)
            REVEL.UpdateCreepSize(creep, creep.Size * 3, true)
        end
    end

    for k,v in pairs(REVEL.roomProjectiles) do
        if v.SpawnerType == REVEL.ENT.MONSNOW.id and v.SpawnerVariant == REVEL.ENT.MONSNOW.variant then
            if v.Variant == ProjectileVariant.PROJECTILE_NORMAL then
                v:Remove()
            end
        end
    end

    if npc.FrameCount == 1 then
        data.AttackChoiceMade = 0
    end

    if spr:IsFinished("Roll Start") then
        data.RollFrame = 0
        data.TearFrame = 0
        npc.State = 21
    elseif spr:IsFinished("Roll End") then
        data.AttackChoiceMade = 0
        npc.State = 3
    elseif spr:IsFinished("Taunt") or spr:IsFinished("Walk") then
        data.AttackChoiceMade = 0
    end

    if npc.State ~= data.PreviousState then
        local state = npc.State
        if state == NpcState.STATE_JUMP or state == NpcState.STATE_MOVE or state == NpcState.STATE_ATTACK then
            if data.IsChampion then
                npc.State = 20
            else
                local dipCount = Isaac.CountEntities(nil, REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant, -1) or 0
                if dipCount >= 5 and (math.random() > 0.2 or dipCount >= 7) then
                    npc.State = 20
                else
                    if state == NpcState.STATE_MOVE and math.random() > 0.65 then
                        local atk = math.random(1, 4)
                        if atk == 1 then
                            spr:Play("JumpUp", true)
                            npc.State = NpcState.STATE_JUMP
                        else
                            spr:Play("Taunt", true)
                            npc.State = NpcState.STATE_ATTACK
                        end
                    elseif state == NpcState.STATE_JUMP and math.random() > 0.65 then
                        spr:Play("Taunt", true)
                        npc.State = NpcState.STATE_ATTACK
                    end
                end
            end
        end

        data.PreviousState = npc.State
    end

    if npc.State == 20 then
        local angle = (player.Position - npc.Position):GetAngleDegrees()
        if angle >= -90 and angle <= 90 then -- Left
            spr.FlipX = true
        elseif angle >= 90 or angle <= -90 then -- Right
            spr.FlipX = false
        end
        if not spr:IsPlaying("Roll Start") then
            spr:Play("Roll Start", true)
        end
        data.ChaseDirections = {}
        local dir = player.Position - npc.Position
        for i = 1, 6 do
            data.ChaseDirections[i] = dir
        end
    elseif npc.State == 21 then
        if npc.Velocity:Length() < 10 then
            local dir = data.ChaseDirections[#data.ChaseDirections]
            data.ChaseDirections[#data.ChaseDirections] = nil
            table.insert(data.ChaseDirections, 1, player.Position - npc.Position)

            local speed = 8
            if data.IsChampion then
                speed = 7
            end

            npc.Velocity = dir:Resized(speed)
            data.TearFrame = data.TearFrame + 1
            data.RollFrame = data.RollFrame + 1
            if data.RollFrame >= 100 and math.random(1, 20) == 1 then
                npc:SetColor(Color(0, 0, 0, 1,conv255ToFloat( 255, 255, 255)), 15, 999, true, false)
                npc.State = 24
                npc.Velocity = Vector.Zero
                data.ChargeFrames = 0
            end
        end
    elseif npc.State == 24 then
        spr.PlaybackSpeed = 0.6
        npc.Velocity = (player.Position - npc.Position):Resized(6)


        data.ChargeFrames = data.ChargeFrames + 1
        if data.ChargeFrames == 20 then
            data.ChargeToward = (player.Position - npc.Position):Resized(14)
            npc.State = 23
        end
    elseif npc.State == 23 then
        spr.PlaybackSpeed = 4
        npc.Velocity = data.ChargeToward
        if not REVEL.room:IsPositionInRoom(npc.Position + npc.Velocity * 2, 32) then
            spr.PlaybackSpeed = 1
            if data.IsChampion then
                local shooter = Isaac.Spawn(REVEL.ENT.MONSNOW.id, REVEL.ENT.MONSNOW.variant, 0, Vector.Zero, Vector.Zero, nil):ToNPC()
                local spawns = 0
                local enemies = REVEL.room:GetAliveEnemiesCount()
                if enemies >= 6 then
                    spawns = 3
                end

                if enemies >= 9 then
                    spawns = 5
                end

                for i = 1, math.random(25, 35) do
                    monsnowFallingProjectile.VelocityMulti = math.random(400, 1200) * 0.001
                    local rotation = math.random(-90, 90)
                    local diff = math.abs(rotation * 1.75) + 150
                    shooter.Position = npc.Position + (data.ChargeToward):Rotated(rotation):Resized(diff)
                    local pdata = shooter:FireBossProjectiles(1, npc.Position, 8, monsnowFallingProjectile):GetData()
                    if math.random(1, 6) == 1 then
                        pdata.SpawnIceCreep = true
                    end

                    pdata.Flomp = true
                    pdata.ChangeToSnow = true
                    pdata.RandomizeScale = true

                    if math.random(1, 13) == 1 and spawns < 5 then
                        if math.random(1, 4) == 1 then
                            pdata.SpawnSnowball = true
                            pdata.SnowballUpgradeDelay = math.random(50, 100)
                            pdata.SnowballNoUpgradeTwice = true
                        else
                            pdata.SpawnDip = true
                        end

                        spawns = spawns + 1
                    end
                end

                shooter:Remove()

                npc.Velocity = (-data.ChargeToward) * 1.2
                data.RollFrame = 0
                data.bounces = math.random(2, 3)
                spr.PlaybackSpeed = 4
                npc.State = 26
            else
                for i = 1, math.random(19, 27) do
                    local pdata = npc:FireBossProjectiles(1, Vector.Zero, 6, monsnowProjectile):GetData()
                    pdata.Flomp = true
                    pdata.ChangeToSnow = true
                    pdata.RandomizeScale = true
                end

                npc.Velocity = Vector.Zero
                data.ChaseDirections = nil
                npc.State = 22
            end
        end
    elseif npc.State == 25 then -- taper down
        npc.Velocity = npc.Velocity * 0.97
        data.ChaseDirections[#data.ChaseDirections] = nil
        table.insert(data.ChaseDirections, 1, player.Position - npc.Position)
        if npc.Velocity:Length() < 2 then
            npc.State = 21
        end
    elseif npc.State == 26 then -- rebound
        spr.PlaybackSpeed = 4
        npc.Velocity = npc.Velocity:Resized(14)
        local off = npc.Position + npc.Velocity * 2
        local clamped = room:GetClampedPosition(off, 32)
        local changed
        if clamped.X ~= off.X then
            npc.Velocity = Vector(-npc.Velocity.X, npc.Velocity.Y)
            changed = true
        end

        if clamped.Y ~= off.Y then
            npc.Velocity = Vector(npc.Velocity.X, -npc.Velocity.Y)
            changed = true
        end

        if changed then
            data.bounces = data.bounces - 1
            if data.bounces <= 0 then
                spr.PlaybackSpeed = 1
                data.bounces = nil
                npc.State = 25
            end
        end
    elseif npc.State == 22 then
        npc.Velocity = Vector.Zero
        local angle = (player.Position - npc.Position):GetAngleDegrees()
        if angle >= -90 and angle <= 90 then -- Left
            spr.FlipX = true
        elseif angle >= 90 or angle <= -90 then -- Right
            spr.FlipX = false
        end
        if not spr:IsPlaying("Roll End") then
            spr:Play("Roll End", true)
        end
    end

    if npc.State == 21 or npc.State == 24 or npc.State == 23 or npc.State == 25 or npc.State == 26 then
        if npc.Velocity.Y < 0 and math.abs(npc.Velocity.Y) > math.abs(npc.Velocity.X) then
            REVEL.PlayIfNot(spr, "RollBackwards")
        else
            npc:AnimWalkFrame("Roll Horizontal", "Roll Diagonal", 1)
        end
    end

    if spr:IsEventTriggered("Land") then
        if npc.State == 20 then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            npc.Velocity = Vector.FromAngle((player.Position - npc.Position):GetAngleDegrees()):Resized(7)
        elseif npc.State == 22 then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
        elseif spr:IsPlaying("JumpDown") then
            REVEL.game:ShakeScreen(10)
            for i = 1, math.random(19, 27) do
                monsnowFallingProjectile.VelocityMulti = math.random(300, 800) * 0.001
                local pdata = npc:FireBossProjectiles(1, Vector.Zero, 8, monsnowFallingProjectile):GetData()
                pdata.SpawnIceCreep = true
                pdata.Flomp = true
                pdata.ChangeToSnow = true
                pdata.RandomizeScale = true
                if math.random(1, 15) == 1 then
                    pdata.SpawnDip = true
                end
            end
        end
    elseif spr:IsEventTriggered("Shoot") then
        for i = 1, math.random(2, 3) do
            local projectile = npc:FireBossProjectiles(1, player.Position, 0, monsnowProjectile)
            local pdata = projectile:GetData()
            pdata.Snowballing = true
            pdata.SpawnDip = true
            pdata.ChangeToSnow = true
            pdata.Flomp = true
            projectile.Scale = 1.5 + math.random(-20, 20) * 0.01
            projectile.Height = projectile.Height - 20
            projectile.Velocity = projectile.Velocity * 0.75
        end
    elseif spr:IsEventTriggered("Grunt") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOSS_LITE_ROAR, 1, 0, false, 1)
        if npc.State == 20 then
            npc.Velocity = (player.Position - npc.Position):Resized(8)
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, monsnow_NpcUpdate, REVEL.ENT.MONSNOW.id)

-- Glacier monstro replacement
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, vel, spawner, seed)
    if type == EntityType.ENTITY_MONSTRO and REVEL.STAGE.Glacier:IsStage() then
        return {REVEL.ENT.MONSNOW.id, REVEL.ENT.MONSNOW.variant, 0, seed}
    end
end)

local monsnowBloodShootColor = Color(1, 1, 1, 0.6, 0.05, 0.05, 0.3)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    local groundSubtype = 3
    local bigBloodSubtype = 4
    local cloudSubtype = 5


    if effect.SubType == groundSubtype 
    or effect.SubType == bigBloodSubtype
    or effect.SubType == cloudSubtype
    then
        -- for some reason FindInRadius doesn't work for all of them (even if testing with GetRoomEntities worked)
        -- regardless of partition, so let's find by type
        local monsnows = REVEL.ENT.MONSNOW:getInRoom()
        local closest = REVEL.getClosestInTable(monsnows, effect)
        if closest and closest.Position:DistanceSquared(effect.Position) < 1 then
            if effect.SubType == groundSubtype then
                effect:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/effect_010_poof02_b_blood_glacier.png")
            elseif effect.SubType == bigBloodSubtype then
                effect:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/effect_010_poof02_c_blood_glacier.png")
            elseif effect.SubType == cloudSubtype then
                effect:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/effect_010_poof02_bloodcloud_glacier.png")
            end
            effect:GetSprite():LoadGraphics()
            effect.Color = monsnowBloodShootColor
            effect.SpawnerEntity = closest
        end
    end
end, EffectVariant.POOF02)

end