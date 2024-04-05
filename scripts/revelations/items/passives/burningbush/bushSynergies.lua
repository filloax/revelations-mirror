local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local LaserVariant      = require("scripts.revelations.common.enums.LaserVariant")

return function()

local BushCfg           = REVEL.Module("scripts.revelations.items.passives.burningbush.bushCfg")
local BushLagAdjGlobals = REVEL.Module("scripts.revelations.items.passives.burningbush.bushLagAdjGlobals")
    
-- Mom's knife
local offset = Vector(0,13)

revel:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, e)
    if not e.Parent then return end
    local player = e.Parent:ToPlayer()
    if not player or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then return end

    if e:GetKnifeVelocity() > 0 then
        local diff = (e.Position-player.Position)
        local rot = math.random(20)-10
        local fire = REVEL.ShootFireTear(player,
            e.Position+diff:Resized(5):Rotated(rot),
            diff:Resized(math.max(6,e:GetKnifeVelocity()*0.5)):Rotated(rot),
            1, false, 0.65)
        fire.SpriteOffset = offset
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.KNIFE_UPDATE_INIT, 1, function(e)
    local player = e.Parent:ToPlayer()
    if not player or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) or player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then return end

    local spr = e:GetSprite()
    local idle = spr:IsPlaying(spr:GetDefaultAnimationName())

    spr:Load("gfx/effects/revelcommon/burning_knife.anm2", true)
    spr.PlaybackSpeed = 1
    if idle then spr:Play("Idle", true) else spr:Play("Rotation", true) end
end)

--Epic fetus

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    if not (e.Type == EntityType.ENTITY_EFFECT and e.Variant == EffectVariant.ROCKET and e.SpawnerType == 1) then return end
    local player = REVEL.GetData(e).__player
    if not player or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then return end

    local num = REVEL.Lerp3PointClamp(7, 10, 15, player.MaxFireDelay, 20, 10, 5)
    for i=1, num do
        REVEL.ShootFireTear(player, e.Position, RandomVector()*10, 1, false, 0.65)
    end
end)

--DR FETUS
local offset = Vector(0,13)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, e)
    if not e.Parent then return end
    local player = e.Parent:ToPlayer()
    if not player or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then return end

    local data = REVEL.GetData(e)
    data.firesShot = data.firesShot or 0
    e = e:ToBomb()
    if e.IsFetus and data.firesShot < 4 then
        local rot = math.random(20)-10
        local fire = REVEL.ShootFireTear(player,
            e.Position+e.Velocity:Rotated(rot),
            e.Velocity:Resized(math.max(6,e.Velocity:Length()*1.1)):Rotated(rot),
            1, false, 0.65)
        REVEL.GetData(fire).monolith = true
        fire.SpriteOffset = offset
        data.firesShot = data.firesShot + 1
    end
end)

StageAPI.AddCallback("Revelations", "REV_BOMB_UPDATE_INIT", 1, function(e)
    local data = REVEL.GetData(e)
    local spr = e:GetSprite()
    local player = e.Parent and e.Parent:ToPlayer()
    if not e.IsFetus or not player or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then return end

    e.Flags = BitOr(e.Flags, TearFlags.TEAR_BURN)
end)

--Brimstone and tech x
do
    local TechxFire = {
        Update = function(fire, data, sprite)
            if not fire.Parent or (fire.Parent and (fire.Parent:IsDead() or not fire.Parent:Exists())) then
                if not data.Fading then
                    REVEL.fadeEntity(fire, 6)
                    data.Fading = true
                end
                fire.Velocity = fire.Velocity * 0.5
            else
                data.Angle = data.Angle + BushCfg.TechxRotationSpeed
                fire.SpriteOffset = REVEL.GetOrbitOffset(data.Angle, data.Distance) + fire.Parent.SpriteOffset - fire.Parent.Velocity
            end
        end,
        RemoveOnAnimEnd = false
    }

    local function GetLaserPlayerWithFire(e)
        local parent = e:GetLastParent()
        parent = parent.SpawnerEntity or parent -- anti gravity doesn't return player as last parent with the function
        local player = parent and parent:ToPlayer()

        if player and REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
            return player
        end
    end

    local BrimstoneLikeLaserVariants = {
        LaserVariant.THICK_RED,
        LaserVariant.SHOOP_DA_WOOP,
        LaserVariant.BRIMTECH,
        LaserVariant.THICK_BROWN,
    }

    ---@param e EntityLaser
    revel:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, e)

        if not REVEL.includes(BrimstoneLikeLaserVariants, e.Variant) then 
            return 
        end
        local player = GetLaserPlayerWithFire(e)

        if not player then return end

        local data = REVEL.GetData(e)

        -- no frame check as anti-gravity lasers are init before
        if not data.__LaserBushInit then
            data.__LaserBushInit = true
            if REVEL.includes(BrimstoneLikeLaserVariants, e.Variant) then --BRIM/SHOOP
                local spr,color = e:GetSprite(),e:GetSprite().Color

                if e.Variant == LaserVariant.SHOOP_DA_WOOP then
                    spr:Load("gfx/effects/revelcommon/burning_brimstone_transparent.anm2", true)
                else
                    spr:Load("gfx/effects/revelcommon/burning_brimstone.anm2", true)
                end
                spr:Play("LargeRedLaser", true)
                spr.PlaybackSpeed = 1
                spr.Color = color

            elseif e:IsCircleLaser() then --Tech x without brimstone
                local spr = e:GetSprite()

                spr.Color = REVEL.NO_COLOR

                for i=1,math.floor(4+e.Radius/6) do
                    local angle = math.pi*2/math.floor(4+e.Radius/6)*i
                    local eff = REVEL.SpawnDecorationFromTable(e.Position, e.Velocity, TechxFire, e)
                    eff.SpriteScale = Vector(0.6,0.6)
                    REVEL.GetData(eff).Angle = angle
                    REVEL.GetData(eff).Distance = e.Radius * 0.6

                    eff.SpriteOffset = REVEL.GetOrbitOffset(angle, REVEL.GetData(eff).Distance) + e.SpriteOffset - e.Velocity
                end
            end

            -- play for both brim and non brim tech x
            if e:IsCircleLaser() then 
                REVEL.sfx:Play(REVEL.SFX.FIRE_END, 0.6, 0, false, 0.5) 
            end
        end

        e = e:ToLaser()
        local data = REVEL.GetData(e)

        -- needs to be brim or shoop da woop
        local stats = REVEL.GetData(player).BushStats

        if not data.bushFireDelay then
            data.bushFireDelay = 0
            data.bushFireTreshold = 1 / (stats.FiresPerUpdate * BushLagAdjGlobals.FirerateMult)
        end

        data.bushFireDelay = data.bushFireDelay + 1

        while data.bushFireDelay >= data.bushFireTreshold do
            data.bushFireDelay = data.bushFireDelay - data.bushFireTreshold
            if e:IsCircleLaser() then --TECH X + BRIM
                local vec = RandomVector()
                local tear = REVEL.ShootFireTear(player, e.Position + vec*(e.Radius*0.7), vec*10, 1, false, 0.65)
                REVEL.GetData(tear).monolith = true
                REVEL.GetData(tear).CustomColor = e:GetSprite().Color
            else
                local pos = Vector(
                    e.Parent.Position.X + (e.EndPoint.X-e.Parent.Position.X)*math.random() ,
                    e.Parent.Position.Y + (e.EndPoint.Y-e.Parent.Position.Y)*math.random() 
                )
                local vel = Vector.FromAngle(e.AngleDegrees - 45 + math.random(90)) * 10
                local tear = REVEL.ShootFireTear(player, pos, vel, 1, false, 0.65)
                REVEL.GetData(tear).monolith = true
                REVEL.GetData(tear).CustomColor = e:GetSprite().Color
            end
        end

        local pos 
        if e:IsCircleLaser() then
            pos = e.Position + RandomVector() * (e.Radius*0.7)
        else
            pos = Vector(
                e.Parent.Position.X + (e.EndPoint.X-e.Parent.Position.X)*math.random() ,
                e.Parent.Position.Y + (e.EndPoint.Y-e.Parent.Position.Y)*math.random() 
            )
        end
        REVEL.SpawnFireParticles(pos, -5, 0, e.FrameCount, nil, 1)
    end)

    REVEL.AddEffectInitCallback(function(e)
        local player = GetLaserPlayerWithFire(e)
        if player and e.SubType == 1 then
            local spr = e:GetSprite()

            local anim = spr:GetAnimation()

            spr:Load("gfx/effects/revelcommon/burning_brimstone_impact.anm2", true)
            spr.Color = e.Parent:GetSprite().Color
            spr:Play(anim, true)
        end
    end, EffectVariant.LASER_IMPACT)

    REVEL.AddEffectInitCallback(function(e)
        local player = GetLaserPlayerWithFire(e)
        if player then
            -- Seems to be hardcoded to red color if color is at default, so just use
            -- a lava like color
            -- local spr = e:GetSprite()
            -- local anim = spr:GetAnimation()
            -- spr:Load("gfx/effects/revelcommon/burning_brimstone_swirl.anm2", true)
            -- spr:Play(anim, true)
            e.Color = Color(1,1,1,1, 0.5, 0.5, 0)
        end 
    end, EffectVariant.BRIMSTONE_SWIRL)
end

--Ipecac

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local player = REVEL.GetData(e).__player
    if not player 
    or REVEL.GetData(e).BurningBush 
    or not (REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) and player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) and e.SpawnerType == 1) 
    then return end
    local stats = REVEL.GetData(player).BushStats

    local r = 5 + math.floor(stats.FiresPerUpdate * 2)
    for i=1, r do
        local fire = REVEL.ShootFireTear(player, e.Position, RandomVector()*10, 1, false, 0.65, nil, 0.5)
        REVEL.GetData(fire).CustomColor = Color(0.5, 1, 0.5, 1,conv255ToFloat( 0, 25, 0))
    end
end, EntityType.ENTITY_TEAR)

--Monstros lung

local function shootLungFireTear(player, position, velocity)
    local fire = REVEL.ShootFireTear(player, position, velocity, 1, true)
    fire.CollisionDamage = player.Damage * 0.4
    fire.SpriteOffset = Vector(0,6)
end

StageAPI.AddCallback("Revelations", "REV_ON_TEAR", 0, function(e, data, spr, player, split)
    if player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) and not split then
        if player:HasCollectible(149) or not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) or data.BurningBush or REVEL.GetData(player).FiringFireTear then return end

        local position = e.Position
        local velocity = e.Velocity
        for i=1, math.random(2,3) do
            position = position + Vector(math.random(-3,3),math.random(-3,3))
            velocity = velocity:Rotated(math.random(-500,500)*0.01) * ((math.random(0,300)*0.001) + 0.85)
            local delay = i-1
            if delay > 0 then
                REVEL.DelayFunction(shootLungFireTear, delay, {player, position, velocity}, true)
            else
                shootLungFireTear(player, position, velocity)
            end
        end
        e:Remove()

        if not REVEL.sfx:IsPlaying(SoundEffect.SOUND_FIRE_RUSH) then
            REVEL.sfx:Play(SoundEffect.SOUND_FIRE_RUSH, 0.5, 0, false, 1)
        end
    end
end)

--Ludovico

---@param tear EntityTear
revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
        local data, sprite = REVEL.GetData(tear), tear:GetSprite()
        local owner = data.__player or data.__parent
        if owner and owner:ToPlayer() and not owner:IsDead() then
            local player = owner:ToPlayer()
            if REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
                local minRadius = 5
                local maxRadius = 20

                --mint gum synergy
                if REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
                    minRadius = 10
                    maxRadius = 35

                    --burning bush + mint gum snowflake ludo sprite
                    if not data.LudoBurningBushMintGum then
                        sprite:Load("gfx/effects/revelcommon/burning_ludo_tears_mint.anm2", true)
                        sprite:Play("RegularTear13", true)
                        sprite.Color = BushCfg.BlueColor

                        sprite.Scale = Vector(1.25,1.25)
                        -- tear.SpriteOffset = Vector(0,20)

                        data.LudoBurningBush = false
                        data.LudoBurningBushMintGum = true
                    end

                else --regular burning bush fire

                    --burning bush ludo tear sprite
                    if not data.LudoBurningBush then
                        if not REVEL.ITEM.ICETRAY:PlayerHasCollectible(player) then
                            sprite:Load("gfx/effects/revelcommon/burning_ludo_tears.anm2", true)
                            sprite:Play("RegularTear13", true)
                            sprite.Color = BushCfg.YellowColor

                            --    sprite.Scale = Vector(0.6,0.6)
                            tear.SpriteOffset = Vector(0,20)
                        end

                        data.LudoBurningBush = true
                    end

                end

                --spawn the fire tears around the ludo tear
                if tear.FrameCount % math.min(math.max(math.floor(player.MaxFireDelay * 0.5),2),10) == 1 then
                    local fire = REVEL.ShootFireTear(player, tear.Position + (RandomVector()*math.random(minRadius,maxRadius)), Vector.Zero, 1, false, 2)
                    if not data.LudoBurningBushMintGum then
                        fire.SpriteOffset = Vector(0,16)
                    end
                end
            end
        end
    end
end)

-- Lachryphagy

StageAPI.AddCallback("Revelations", "REV_ON_TEAR", 1, function(e, data, spr, player, split)
    if not split and not REVEL.GetData(player).FiringFireTear and HasBit(e.TearFlags, TearFlags.TEAR_ABSORB) and REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then --lacryphage tear
        e.Color = Color(0.4, 0.35, 0.25)
        data.CheckBushLachryphagy = true

        --tear variant for blood tears spawned by lacryphagy gets set after init, so we need to do this to distinguish them
        REVEL.DelayFunction(1, function()
            if e.Variant == TearVariant.BLOOD then
                local position = e.Position
                local velocity = e.Velocity
                for i=1, math.random(1,2) do
                    position = position + Vector(math.random(-3,3),math.random(-3,3))
                    velocity = velocity:Rotated(math.random(-500,500)*0.01) * ((math.random(0,300)*0.001) + 0.85)
                    local delay = i-1
                    if delay > 0 then
                        REVEL.DelayFunction(shootLungFireTear, delay, {player, position, velocity}, true)
                    else
                        local sizeMult = e.Scale / 1.5
                        REVEL.ShootFireTear(player, position, velocity, sizeMult, player, 0.75, sizeMult, sizeMult)
                    end
                end

                if not REVEL.sfx:IsPlaying(SoundEffect.SOUND_FIRE_RUSH) then
                    REVEL.sfx:Play(SoundEffect.SOUND_FIRE_RUSH, 0.5, 0, false, 1)
                end
    
                e:Remove()
            else
                data.ExplodeIntoFlames = true
            end
            data.CheckBushLachryphagy = nil
        end)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local data = REVEL.GetData(e)
    if data.ExplodeIntoFlames then
        local closeTears = Isaac.FindInRadius(e.Position, 40, EntityPartition.TEAR)
        local wasProbablyAbsorbed = REVEL.some(closeTears, function(otherTear) return otherTear.Index ~= e.Index and otherTear.Variant == TearVariant.HUNGRY end)
        if not wasProbablyAbsorbed then
            local mult = REVEL.Lerp2Clamp(0.5, 1.5, e:ToTear().Scale, 1, 2.5)
            REVEL.BurningBush.SpawnPermaFire(e.Position, Vector.Zero, data.__player, mult * 5, 0.75, true, 0, mult)
        end
    end
end, 2)

-- Haemolacria

do
    --Can get messy with some combos (example: haemolacria + lachryphagy + tear detonator), since reimplementing some of the items in the combos
    --would be the only "good" solution lets cap it instead
    local splitTearFiresThisSecond = 0
    local splitTearFiresPerSecAvgExp = 0
    local lastCheck = 0

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
        local data = REVEL.GetData(e)
        if e.Variant == EffectVariant.ROCKET and data.__player and REVEL.ITEM.ICETRAY:PlayerHasCollectible(data.__player) then
            local creep = Isaac.Spawn(1000, 54, 0, e.Position, Vector.Zero, data.__player):ToEffect()
            creep:Update()
            creep:SetTimeout(140)
        end
    end, 1000)

    StageAPI.AddCallback("Revelations", "REV_ON_TEAR", 1, function(e, data, spr, player, split)
        if split and split.Haemolacria and REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
            for i=1, math.random(1,2) do
                if splitTearFiresThisSecond < 20 and splitTearFiresPerSecAvgExp < 35 then
                    local fire = REVEL.ShootFireTear(player, e.Position, e.Velocity:Rotated(math.random(15) - 7.5), 1, false, 0.5)
                    splitTearFiresThisSecond = splitTearFiresThisSecond + 1
                end
            end

            if splitTearFiresThisSecond < 20 and splitTearFiresPerSecAvgExp < 35 then
                local num = math.random(0, math.floor(4 * BushLagAdjGlobals.PermaFireRateMult))

                for i = 1, num do
                    REVEL.BurningBush.SpawnPermaFire(e.Position, e.Velocity:Rotated(math.random(30) - 15) * 0.5, player, nil, nil, true)
                end
            end

            e:Remove()
        end
    end)
        
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if REVEL.ITEM.BURNBUSH:OnePlayerHasCollectible() and Isaac.GetTime() >= lastCheck + 1000 then
            splitTearFiresPerSecAvgExp = REVEL.Lerp(splitTearFiresPerSecAvgExp, splitTearFiresThisSecond, 0.25)
            splitTearFiresThisSecond = 0
            lastCheck = Isaac.GetTime()
        end
    end)
end

-- Tainted lilith / Gello
do
    local function burnbushGelloUpdate(_, familiar)
        local data = REVEL.GetData(familiar)

        if REVEL.ITEM.BURNBUSH:PlayerHasCollectible(familiar.Player)
        and familiar.FrameCount < 15 then --temp, only when launched
            -- Have gello shoot
            -- kind of tricky, for now just have fire tears and flames shot
            -- like with the mom's knife synergy as a temporary synergy
            -- until a way to improve the animation and
            -- remove vanilla tears is done (other priorities in fixing rn)
            -- BurningbushShooterUpdate(familiar, data, REVEL.GetData(familiar.Player).BushStats, familiar.Player, false, false)

            local player = familiar.Player

            if not data.ShootInput then
                local input = REVEL.GetCorrectedFiringInput(player)
                data.ShootInput = input
            end

            -- TEMP
            local l = familiar.Velocity:Length()
            if l > 2 and familiar.Velocity:Dot(data.ShootInput) > 0 then
                local dir = (familiar.Position - player.Position):Normalized() * 0.5 + data.ShootInput * 0.5
                local rot = math.random(20) - 10
                local fire = REVEL.ShootFireTear(player,
                    familiar.Position + dir:Rotated(rot) * 5,
                    dir:Rotated(rot) * (math.max(6, l * 0.2)),
                    1, false, 0.65) 
            end
        end
    end

    local function burnbushGelloTempEvalCache(_, player, flag)
        if REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player)
        and (player:GetPlayerType() == PlayerType.PLAYER_LILITH_B or player:HasCollectible(CollectibleType.COLLECTIBLE_GELLO))
        and BitAnd(flag, CacheFlag.CACHE_TEARFLAG) > 0 then
            player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_BURN)
        end
    end


    revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, burnbushGelloUpdate)
    revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, burnbushGelloTempEvalCache)

    -- revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, t, v, s, pos, vel, spawner, seed)
    --     if t == 2 and spawner and spawner.Type == 1 
    --     and spawner:ToPlayer():HasCollectible(REVEL.ITEM.BURNBUSH.id)
    --     and (spawner:ToPlayer():HasWeaponType(WeaponType.WEAPON_UMBILICAL_WHIP) 
    --                 or spawner:ToPlayer():GetPlayerType() == PlayerType.PLAYER_LILITH_B) then
    --         local gello, distSq = REVEL.getClosestInTableFromPos(Isaac.FindByType(3, FamiliarVariant.UMBILICAL_BABY), pos)
    --         REVEL.DebugLog(gello, distSq, pos, gello.Position)
    --         if gello and distSq < 5 then
    --             return {
    --                 StageAPI.E.DeleteMePickup.T,
    --                 StageAPI.E.DeleteMePickup.V,
    --                 0,
    --                 seed
    --             }
    --         end
    --     end
    -- end)
end

-- Tammy's head
do
    local function burnbushTammysHeadUseItem(_, itemId, rng, player, useFlags)
        if REVEL.BurningBush.HasWeapon(player) then
            for angle = 0, 315, 45 do
                local dir = Vector.FromAngle(angle)
                local num = math.random(3, 5)
                for i = 1, num do
                    local fire = REVEL.ShootFireTear(player, player.Position, dir:Rotated(math.random(-15, 15)) * math.random(5, 8),
                        nil, nil, nil, nil, 1.2)
                    fire.CollisionDamage = fire.CollisionDamage + 25 / num
                end
            end

            player:AnimateCollectible(itemId, "UseItem")

            return true
        end
    end

    revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, burnbushTammysHeadUseItem, CollectibleType.COLLECTIBLE_TAMMYS_HEAD)
end

end