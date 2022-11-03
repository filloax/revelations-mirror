local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
--------------
-- ICE TRAY --
--------------

--[[
Shoot ice cubes that after falling slide on the ground.
]]

local bal = {CreepFrequency = 5}

local bloodyTearVariants = {
    [TearVariant.BLOOD] = true,
    [TearVariant.CUPID_BLOOD] = true,
    [TearVariant.PUPULA_BLOOD] = true,
    [TearVariant.GODS_FLESH_BLOOD] = true,
    [TearVariant.NAIL_BLOOD] = true,
    [TearVariant.GLAUCOMA_BLOOD] = true,
    [TearVariant.BELIAL] = true,
    [TearVariant.EYE_BLOOD] = true,
    [TearVariant.BALLOON] = true,
    [TearVariant.BALLOON_BRIMSTONE] = true,
    [TearVariant.BALLOON_BOMB] = true
}

local function isBloodyTearVariant(tearVariant)
    return bloodyTearVariants[tearVariant]
end

local baloonTearVariants = {
    [TearVariant.BALLOON] = true,
    [TearVariant.BALLOON_BRIMSTONE] = true,
    [TearVariant.BALLOON_BOMB] = true
}

local function isBalloonTearVariant(tearVariant)
    return baloonTearVariants[tearVariant]
end

local shouldNotReplaceVariants = {
    [TearVariant.TOOTH] = true,
    [TearVariant.BLACK_TOOTH] = true,
    [TearVariant.SCHYTHE] = true,
    [TearVariant.NAIL] = true,
    [TearVariant.NAIL_BLOOD] = true,
    [TearVariant.DIAMOND] = true,
    [TearVariant.COIN] = true,
    [TearVariant.STONE] = true,
    [TearVariant.BOOGER] = true,
    [TearVariant.EGG] = true,
    [TearVariant.RAZOR] = true,
    [TearVariant.BONE] = true,
    [TearVariant.NEEDLE] = true,
    [TearVariant.BELIAL] = true
}

local function shouldReplaceVariant(tearVariant)
    return not shouldNotReplaceVariants[tearVariant]
end

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 0, function(e, data, spr, player, split)
    if REVEL.ITEM.ICETRAY:PlayerHasCollectible(player) and e.SpawnerType == 1 
    and e.Variant ~= TearVariant.CHAOS_CARD 
    and e.Variant ~= TearVariant.BOBS_HEAD 
    and not e:HasTearFlags(TearFlags.TEAR_LUDOVICO) 
    and not data.BurningBush and not player:GetData().FiringFireTear then
        data.OldIceTrayVariant = e.Variant
        data.icetrayCheck = true
        data.icetrayIsBloody = isBloodyTearVariant(data.OldIceTrayVariant)
        if shouldReplaceVariant(data.OldIceTrayVariant) then
            e.Variant = TearVariant.STONE
            spr:Load("gfx/effects/revelcommon/ice_tray_tears.anm2", true)
            if isBalloonTearVariant(data.OldIceTrayVariant) then
                spr:ReplaceSpritesheet(0, "gfx/effects/revelcommon/ice_tray_tears_balloon.png")
                spr:LoadGraphics()
            elseif data.icetrayIsBloody then
                spr:ReplaceSpritesheet(0, "gfx/effects/revelcommon/ice_tray_tears_bloody.png")
                spr:LoadGraphics()
            end
        end

        e.FallingAcceleration = 0.6
        data.icetray = true
        data.icetrayTimeout = data.icetrayTimeout or player.TearRange / 3

        if split then -- spawned from split shot item
            e.Height = -7
            e.FallingSpeed = -3
            if split.Cricket then data.icetrayTimeout = 10 end
        end
    end
end)

REVEL.ITEM.ICETRAY:addCostumeCondition(function(player)
    return not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player)
end)

local blocking = REVEL.toSet({
    GridCollisionClass.COLLISION_SOLID, GridCollisionClass.COLLISION_WALL,
    GridCollisionClass.COLLISION_WALL_EXCEPT_PLAYER
})

local dirToRot = {
    [Direction.DOWN] = 0,
    [Direction.RIGHT] = -90,
    [Direction.UP] = 180,
    [Direction.LEFT] = 90
}

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, e)
    local data, sprite = e:GetData(), e:GetSprite()

    -- LUDOVICO
    if e:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
        local owner = data.__player or data.__parent
        if owner and owner:ToPlayer() and not owner:IsDead() then
            local player = owner:ToPlayer()
            if REVEL.ITEM.ICETRAY:PlayerHasCollectible(player) then
                -- ice tray ludo tear sprite
                if not data.ludoicetray then
                    sprite:Load("gfx/effects/revelcommon/ice_tray_tears.anm2", true)
                    sprite:Play("Stone6Idle", true)

                    e.SpriteOffset = Vector(0, 14)

                    data.ludoicetray = true
                end

                -- mess with velocity to make it slippery
                e.Velocity = e.Velocity * 1.25

                -- spawn creep
                local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(e.Position))
                if e.FrameCount % bal.CreepFrequency == 0 
                and not (grid and grid:ToPit()) then

                    local creepVariant = EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL
                    if data.icetrayIsBloody then
                        creepVariant = EffectVariant.PLAYER_CREEP_RED
                    end

                    local creeps = Isaac.FindByType(1000, creepVariant, 0, true)

                    local dontSpawnCreep = false
                    for i, creep in ipairs(creeps) do
                        if creep.Position:Distance(e.Position) < 20 
                        and creep.FrameCount <= 30 then
                            dontSpawnCreep = true
                            break
                        end
                    end
                    if not dontSpawnCreep then
                        Isaac.Spawn(1000, creepVariant, 0, e.Position, Vector.Zero, REVEL.player):Update()
                    end

                end
            end
        end

        -- OTHER TEARS
    elseif data.icetray then
        if data.OldIceTrayVariant and e.Variant ~= data.OldIceTrayVariant then
            e.Variant = data.OldIceTrayVariant
        end

        local nonDieHeight = -5
        local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(e.Position))
        if e.Height > nonDieHeight and data.icetrayTimeout >= 0 then
            e.FallingSpeed = 0
            e.Height = nonDieHeight

            if sprite:GetFrame() == 0 then
                sprite.PlaybackSpeed = 0 -- for bones etc
            end

            -- Try spawning creep
            if (e.FrameCount + e.InitSeed) % bal.CreepFrequency == 0 
            and not (grid and grid:ToPit()) then
                local creepVariant =
                    EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL
                if data.icetrayIsBloody then
                    creepVariant = EffectVariant.PLAYER_CREEP_RED
                end

                local dontSpawnCreep = false
                -- Probably more laggy than not doing this check altogether
                -- for i, creep in ipairs(Isaac.FindByType(1000, creepVariant, 0, true)) do
                --     if creep.Position:Distance(e.Position) < 20 and creep.FrameCount <= 30 then --avoid spawning creep here if there are some freshly spawned creeps nearby
                --         dontSpawnCreep = true
                --         break
                --     end
                -- end
                if not dontSpawnCreep then
                    Isaac.Spawn(1000, creepVariant, 0, e.Position, Vector.Zero, REVEL.player):Update() -- spawn holy water creep, :Update() is so it doesn't look red for a frame
                end
            end
        end

        data.icetrayTimeout = data.icetrayTimeout - 1
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, e)
    local data = e:GetData()
    local player = data.__player
    if player and data.ForgottenThrownBone and
        REVEL.ITEM.ICETRAY:PlayerHasCollectible(player) then
        if e:IsFlying() then -- when forgotten throws bone
            if not data.spawnedIce then
                data.spawnedIce = true
                local input, dir = REVEL.GetLastFiringInput(player)
                local charge = REVEL.GetApproximateKnifeCharge(e)
                local spd = REVEL.Lerp2Clamp(8, 12, charge) * player.ShotSpeed
                local ice = REVEL.SpawnFriendlyIceBlock(
                    e.Position,
                    (input * spd) + player.Velocity,
                    player,
                    math.random(30) < REVEL.Lerp2Clamp(1, 3, charge) + player.Luck,
                    player.Damage * REVEL.Lerp2Clamp(1, 2.5,charge)
                )
                ice:GetData().speed = spd
                ice.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                ice:GetData().ignoreGrids = true
                if player:HasCollectible(CollectibleType.COLLECTIBLE_CONTINUUM) then
                    ice:GetData().damageTimer = 80
                    ice:GetData().initDamageTimer = ice:GetData().damageTimer
                    ice:GetData().gridImmunity = true
                end
                local k = REVEL.SpawnDecoration(
                    player.Position,
                    player.Velocity, 
                    "Swing",
                    "gfx/008.001_bone club.anm2",
                    player, 
                    nil, nil, 
                    function()
                        e.Visible = true
                    end
                )
                k:GetSprite().Rotation = dirToRot[dir]
                e.Visible = false
                if dir == Direction.RIGHT then
                    k.RenderZOffset = player.RenderZOffset - 100
                end

                e:Reset()
            end
        else
            data.spawnedIce = false
        end
    end
end)

local gibPart = REVEL.ParticleType.FromTable {
    Name = "Ice Tray Gibs",
    Anm2 = "gfx/effects/revelcommon/ice_tray_particles.anm2",
    BaseLife = 60,
    Variants = 7,
    DieOnLand = true,
    RemoveOnDeath = 2 -- set as floor entity on death
}
local gibPartRed = REVEL.ParticleType.FromTable {
    Name = "Ice Tray Gibs Bloody",
    Anm2 = "gfx/effects/revelcommon/ice_tray_particles.anm2",
    Spritesheet = "gfx/effects/revelcommon/ice_tray_gibs_bloody.png",
    BaseLife = 60,
    Variants = 7,
    DieOnLand = true,
    RemoveOnDeath = 2 -- set as floor entity on death
}
local system = REVEL.ParticleSystems.BasicClamped
local emitter = REVEL.Emitter()

local deadTearsThisSecond = 0
local deadTearsPerSecAvgExp = 0
local lastCheck = 0

StageAPI.AddCallback("Revelations", RevCallbacks.POST_TEAR_POOF_INIT, 0, function(poof, data, spr, parent, grandparent)
    local parentData = parent:GetData()
    if parentData.icetray then
        deadTearsThisSecond = deadTearsThisSecond + 1

        REVEL.sfx:Play(
            REVEL.SFX.MINT_GUM_BREAK, 
            REVEL.Lerp2Clamp(0.4, 0.15, deadTearsPerSecAvgExp, 0, 5),
            0, 
            false, 
            0.9 + math.random() * 0.1
        )

        if not REVEL.IsOutOfRoomBy(parent.Position, 55) 
        and deadTearsThisSecond <= 8 and deadTearsPerSecAvgExp <= 8 then -- this is laggy if done often, and will cause crashes
            if parentData.icetrayIsBloody then
                emitter:EmitParticlesNum(
                    gibPartRed, 
                    system,
                    Vec3(parent.Position, parent:ToTear().Height),
                    Vec3(0, 0, -2.5),
                    2 + math.random(3), 
                    1.1, 
                    45
                )
            else
                emitter:EmitParticlesNum(
                    gibPart, 
                    system, 
                    Vec3(parent.Position, parent:ToTear().Height),
                    Vec3(0, 0, -2.5),
                    2 + math.random(3), 
                    1.1, 
                    45
                )
            end
        end

        spr:Load("gfx/effects/revelcommon/ice_tray_shatter.anm2", true)
        if parentData.icetrayIsBloody then
            spr:ReplaceSpritesheet(0, "gfx/effects/revelcommon/ice_tray_shatter_bloody.png")
            spr:LoadGraphics()
        end
        spr:Play("Poof", true)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.OnePlayerHasCollectible(REVEL.ITEM.ICETRAY.id) and
        Isaac.GetTime() >= lastCheck + 1000 then
        deadTearsPerSecAvgExp = REVEL.Lerp(deadTearsPerSecAvgExp, deadTearsThisSecond, 0.25)
        deadTearsThisSecond = 0
        lastCheck = Isaac.GetTime()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local data = e:GetData()
    if e.Variant == EffectVariant.ROCKET and data.__player and
        REVEL.ITEM.ICETRAY:PlayerHasCollectible(data.__player) then
        local creep = Isaac.Spawn(1000, 54, 0, e.Position, Vector.Zero, data.__player):ToEffect()
        creep:Update()
        creep:SetTimeout(140)
    end
end, 1000)

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARIMPACTS_SOUND, 1, function(t, data, spr) 
    return not data.icetray 
end)

end

REVEL.PcallWorkaroundBreakFunction()
