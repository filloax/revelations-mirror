local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-------------------
-- GLUTTON'S GUT --
-------------------

--[[
Use to absorb nearby enemies, and their projectiles, then either use again to swallow and gain 1 heart or fire to shoot a projectile, that scales with absorbed enemy hp:
The following numbers are the percent of absorbed enemy hp / (20 + 4 * level stage)
-0.0 (starting point): 1x player damage
-1.0: 6x player damage, screenshake, wide tear spread shot after
-more than 0.5: smaller tear spread shot after
Also, any absorbed enemy projectiles will be fired when the projectile lands.
]]

revel.gut = {
    animDur = {
        SUCK_S = 14,
        SUCK = 60, -- not actual anim dur, but max suck duration
        SUCK_E = 19,
        CHEW = 15, -- minimum time before being able to shoot
        SPIT = 14,
        SWALLOW = 20
    },
    suckTime = 12, -- time it takes for sucking to happen if player stands still
    mouthOffset = Vector(0, -32),
    nextState = { -- for testing purposes
        SUCK_S = "SUCK",
        SUCK = "SUCK_E",
        SUCK_E = "CHEW",
        CHEW = "SPIT",
        SPIT = "SWALLOW",
        SWALLOW = nil
    }
}

local function changeCostume(player, data, nextState)
    if data.gutState then
        player:TryRemoveNullCostume(REVEL.COSTUME.GUT[data.gutState])
    end
    data.gutState = nextState
    if nextState then
        player:AddNullCostume(REVEL.COSTUME.GUT[data.gutState])
    end
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_)
    for i, player in ipairs(REVEL.players) do
        for k, v in pairs(REVEL.COSTUME.GUT) do
            player:TryRemoveNullCostume(v)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM,
                    function(_, itemID, itemRNG, player, useFlags, activeSlot,
                            customVarData)
    if player:GetActiveItem() == itemID and
        not HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        local data = player:GetData()

        if not data.gutState then

            data.gutState = "SUCK_S"
            data.gutFrameCount = 0 -- btw the update is run the frame after, not the same frame
            data.gutHp = 0
            data.gutProjs = {}
            data.gutEnms = {}

            player:AddNullCostume(REVEL.COSTUME.GUT[data.gutState])

        elseif data.gutState == "SUCK" then
            data.forceGutEndSuck = true

        elseif data.gutState == "CHEW" then
            changeCostume(player, data, "SWALLOW")
            data.gutFrameCount = 0
            player:AddHearts(2)
            SFXManager():Play(SoundEffect.SOUND_VAMP_GULP, 1.0, 0, false,
                                1.0)

            if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                player:AddWisp(CollectibleType.COLLECTIBLE_YUM_HEART, player.Position)
            end
        end
    end
end, REVEL.ITEM.GUT.id)

-- damage: 1x player damage - 6x player damage, at size 0 (nothing absorbed, cannot really happen but gives a starting point) - 1 (max)
-- size is from 0 to 1
local function fireGutTear(player, pos, vel, size, projs)
    size = REVEL.Saturate(size)
    local tear =
        Isaac.Spawn(2, TearVariant.BLOOD, 0, pos, vel, player):ToTear()
    local spr, data = tear:GetSprite(), tear:GetData()
    spr:Load("gfx/itemeffects/revelcommon/gluttons_gut_projectile.anm2",
                true)
    spr:Play("Idle", true)
    tear.CollisionDamage = player.Damage * REVEL.Lerp(1, 6, size)
    tear.Height = -30

    if vel.X < 0 then spr.FlipX = true end
    if math.abs(vel.Y) > math.abs(vel.X) then
        if vel.Y > 0 then
            spr.Rotation = 90
        else
            spr.Rotation = -90
        end
    end
    data.gSize = size
    data.projs = projs
    data.Height = tear.Height
    data.__player = player
end

local function keepProjectile(p, owner)
    p.Position = owner.Position
    p.Velocity = owner.Velocity
    p.FallingSpeed = 0
    p.Height = -30
end

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, e)
    local data = e:GetData()
    if data.gSize then e.Height = data.Height end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local data = e:GetData()
    if data.gSize then
        if data.gSize > 0.5 then
            local projAmnt = 4
            local dmgMult = 1
            if data.gSize == 1 then
                REVEL.game:ShakeScreen(15)
                REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.7, 0,
                                false, 1.0)
                projAmnt = 8
                dmgMult = 2.5
            end
            for i = 1, projAmnt do
                local angle = i * 360 / projAmnt + 45
                local dir = Vector.FromAngle(angle)
                local t = Isaac.Spawn(2, TearVariant.BLOOD, 0,
                                        e.Position + dir * (35), dir * 10,
                                        data.__player)
                t.CollisionDamage =
                    (data.__player and data.__player.Damage or 3.50) *
                        dmgMult
            end
        end
        if data.projs and #data.projs ~= 0 then
            for i, v in ipairs(data.projs) do
                local vel = RandomVector() * math.random(8, 11)
                local pos = e.Position + vel:Resized(35)
                local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, v[1],
                                        v[2], pos, vel, data.__player):ToProjectile()

                p.EntityCollisionClass =
                    EntityCollisionClass.ENTCOLL_ENEMIES
                p:AddProjectileFlags(
                    ProjectileFlags.ANY_HEIGHT_ENTITY_HIT |
                        ProjectileFlags.HIT_ENEMIES |
                        ProjectileFlags.CANT_HIT_PLAYER | v[4])
                p.Color = v[3]
                p.SpriteScale = v[2]
                p:GetSprite().Rotation = 0

                p.CollisionDamage = data.__player.Damage * 1.5

                p.Height = revel.gut.mouthOffset.Y
                p.FallingSpeed = -2 - math.random(6)
                p.FallingAccel = -p.FallingSpeed / 20 + 0.04
            end
        end
    end
end, 2)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_TEAR_POOF_INIT, 0,
                        function(poof, data, spr, parent, grandparent)
    --  REVEL.DebugToString({parent:GetSprite():GetFilename(), parent:GetSprite().SpriteScale})

    if parent:GetSprite():GetFilename() ==
        "gfx/itemeffects/revelcommon/gluttons_gut_projectile.anm2" then -- data gets removed on entity remove(which is when this callback is triggered)
        spr:Load("gfx/itemeffects/revelcommon/gluttons_gut_projectile.anm2",
                    true)
        poof.SpriteScale = parent.SpriteScale
        spr:Play("Hit", true)
    end
end)

local function getMaxGutHp() return 20 + 4 * REVEL.level:GetStage() end

local function absorbEntity(e, player, data)
    local absorbing
    local edata = e:GetData()
    if e:ToProjectile() then
        e = e:ToProjectile()
        e.FallingSpeed = 0
        e.FallingAccel = 0
        edata.startHeight = math.min(edata.startHeight or e.Height,
                                        -(8 + e.Size))
        e.Height = edata.startHeight
    end

    if not edata.gutAbsorbing then
        e.Velocity = e.Velocity + (player.Position - e.Position):Resized(3)
        local diff = (player.Position + revel.gut.mouthOffset -
                            e.SpriteOffset) - e.Position -- distance to final render pos
        local dist = diff:LengthSquared()

        if dist < 16000 then
            edata.gutAbsorbing = true
            absorbing = true

            if (not e.Height) and e:IsBoss() then -- if is boss, spawn projectile to be absorbed instead
                local param = ProjectileParams()
                param.Scale = param.Scale * 3
                local p = e:ToNPC():FireBossProjectiles(1, player.Position,
                                                        1, param)
                --        p.SpriteScale = Vector.One * 2
                --        p.SpriteOffset = REVEL.GetYVector(- 32 + e.SpriteOffset.Y)
                local pdata = p:GetData()
                pdata.gutBossTear = true
            else
                edata.startScale = Vector(e.SpriteScale.X, e.SpriteScale.Y)

                edata.prevDist = dist
                edata.startDist = dist

                edata.pos = Vector(e.Position.X, e.Position.Y)
                edata.spd = 3

                e.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                e.GridCollisionClass =
                    EntityGridCollisionClass.GRIDCOLL_NONE
                e.Visible = false
                e:AddEntityFlags(EntityFlag.FLAG_FREEZE)
                e.Velocity = Vector.Zero
                e.Position = REVEL.room:GetTopLeftPos() - Vector(40, 40)
                edata.gutAngle = 0
                edata.gutAngleSpeed = 0
                edata.gutAngleDir = sign(e.Position.X - player.Position.X)

                if e.ProjectileFlags then
                    e:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
                end

                table.insert(data.gutEnms, e)
            end
        end
    else
        absorbing = true
    end

    return absorbing
end

local fullBossTearColor = Color(0.75, 1, 1, 1, conv255ToFloat(120, 60, 0))

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for j, player in ipairs(REVEL.players) do -- why not use PEFFECT_UPDATE? scale is wonky outside of POST_UPDATE

        local data = player:GetData()

        if data.gutState then -- and REVEL.ITEM.GUT:PlayerHasCollectible(player)
            player.FireDelay = player.MaxFireDelay

            data.gutFrameCount = data.gutFrameCount + 1
            local finish = data.gutFrameCount >=
                                revel.gut.animDur[data.gutState] -- for brevity, since it's going to be used a lot

            for i, e in ripairs(data.gutEnms) do
                if e:IsDead() or not e:Exists() then
                    table.remove(data.gutEnms, i)
                else

                    local edata = e:GetData()

                    e.EntityCollisionClass =
                        EntityCollisionClass.ENTCOLL_NONE

                    local diff = (player.Position + revel.gut.mouthOffset -
                                        e.SpriteOffset) - edata.pos
                    local dist = diff:LengthSquared()

                    if dist > 36 then
                        edata.gutAngleSpeed =
                            math.min(25, math.max(-25, edata.gutAngleSpeed +
                                                        3 * edata.gutAngleDir))
                        edata.gutAngle = edata.gutAngle +
                                                edata.gutAngleSpeed
                        e:GetSprite().Rotation = edata.gutAngle

                        -- 13 = gaper size, so by default its 0.15 for gaper-sized ents
                        e.SpriteScale =
                            REVEL.Lerp(Vector.One * 0.15, edata.startScale,
                                        math.max(dist, edata.prevDist) /
                                            edata.startDist)
                        e.RenderZOffset = player.RenderZOffset + 55

                        if dist < edata.prevDist then
                            edata.prevDist = dist
                        end
                        if e.Height then
                            e.Height = edata.startHeight
                            e.FallingSpeed = 0
                            e.FallingAccel = 0
                            if edata.gutBossTear then
                                e.Color =
                                    Color.Lerp(Color.Default,
                                                fullBossTearColor, math.sin(
                                                    e.FrameCount * 4) / 2 + 1)
                            end
                        end
                    else
                        if edata.gutBossTear or
                            not (e.Type == EntityType.ENTITY_PROJECTILE) then
                            if edata.gutBossTear then
                                data.gutHp = getMaxGutHp() + 1
                            else
                                data.gutHp = data.gutHp + e.HitPoints
                            end
                            e.Position = player.Position +
                                                revel.gut.mouthOffset
                            e:BloodExplode()
                            e:Remove()

                            table.remove(data.gutEnms, i)
                        else
                            data.gutHp = data.gutHp +
                                                math.max(e.CollisionDamage, 1.5)
                            table.remove(data.gutEnms, i)
                            table.insert(data.gutProjs, {
                                e.Variant, e.SubType, e.Color,
                                e.ProjectileFlags
                            })
                            e:Remove()
                        end
                        REVEL.sfx:Play(SoundEffect.SOUND_MEAT_JUMPS, 0.6, 0,
                                        false, 1)
                    end
                end
            end

            if data.gutState == "SUCK_S" and finish then
                changeCostume(player, data, "SUCK")

            elseif data.gutState == "SUCK" then
                for i, e in ipairs(REVEL.roomEnemies) do
                    if not (e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) or
                        e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or
                        e:IsDead()) and not e:GetData().absorbed and
                        e.Position:DistanceSquared(player.Position) < 80000 then -- ~6 tiles
                        absorbEntity(e, player, data)
                    end
                end

                for i, e in ipairs(REVEL.roomProjectiles) do
                    if e.SpawnerType ~= 1 and not e:GetData().absorbed and
                        not HasBit(e.ProjectileFlags,
                                    ProjectileFlags.HIT_ENEMIES) then
                        absorbEntity(e, player, data)
                    end
                end

                if #data.gutEnms == 0 and
                    (finish or data.gutHp > getMaxGutHp() or
                        data.forceGutEndSuck) then
                    changeCostume(player, data, "SUCK_E")
                    data.forceGutEndSuck = false
                end

            elseif data.gutState == "SUCK_E" and finish then
                if data.gutHp ~= 0 or #data.gutProjs ~= 0 then
                    changeCostume(player, data, "CHEW")
                    player:SetActiveCharge(
                        player:GetActiveCharge() +
                            REVEL.config:GetCollectible(REVEL.ITEM.GUT.id)
                                .MaxCharges)
                else
                    changeCostume(player, data, nil)
                end
            elseif data.gutState == "CHEW" and finish then
                if REVEL.IsShooting(player, false, true) then
                    local input = REVEL.AxisAlignVector(player:GetShootingInput()):Normalized()
                    player:SetActiveCharge(
                        player:GetActiveCharge() -
                            REVEL.config:GetCollectible(REVEL.ITEM.GUT.id)
                                .MaxCharges)
                    data.gutAction =
                        REVEL.dirToShootAction[player:GetFireDirection()]
                    changeCostume(player, data, "SPIT")
                    local maxHp = getMaxGutHp()

                    SFXManager():Play(SoundEffect.SOUND_BOSS_LITE_GURGLE,
                                        1.05, 0, false, 1.00)
                    local vel = player.Velocity + input:Resized(11)
                    local l = vel:Length()
                    if l < 10 then
                        vel = vel * (10 / l)
                    end
                    fireGutTear(player,
                                player.Position + input:Resized(2.5), vel,
                                data.gutHp / maxHp, data.gutProjs)

                    if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                        local wispNum = math.min(math.floor(REVEL.Lerp(1, 6, data.gutHp / maxHp)/2),8)
                        for i = 1, wispNum do
                            player:AddWisp(REVEL.ITEM.GUT.id, player.Position)
                        end
                    end

                    data.gutProjs = {}

                    data.gutAction = nil
                end

            elseif data.gutState == "SPIT" and finish then
                changeCostume(player, data, nil)

            elseif data.gutState == "SWALLOW" and finish then
                changeCostume(player, data, nil)
            end

            if data.gutState ~= data.prevGutState then
                data.gutFrameCount = 0
            end

            data.prevGutState = data.gutState
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, renderOffset)
    local data = player:GetData()
    if data.gutEnms then
        for i, e in ipairs(data.gutEnms) do
            local edata = e:GetData()

            edata.spd = edata.spd + 0.25
            local diff = (player.Position + revel.gut.mouthOffset -
                e.SpriteOffset) - edata.pos

            local l = diff:Length()
            if l > edata.spd then
                diff = diff * (edata.spd / l)
            end

            edata.pos = edata.pos + diff

            e:GetSprite():Render(Isaac.WorldToScreen(edata.pos) + renderOffset - REVEL.room:GetRenderScrollOffset())
            -- IDebug.RenderCircle( edata.pos+Vector(0,-32), 5, nil, nil, Color(1,0,0,1,conv255ToFloat(0,0,0)))
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for i, p in ipairs(REVEL.players) do
        local data = p:GetData()
        data.gutProjs = {}
        data.gutEnms = {}
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()
