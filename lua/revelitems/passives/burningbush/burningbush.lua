local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local BushLagAdjGlobals = require("lua.revelitems.passives.burningbush.BushLagAdjGlobals")
local BushCfg           = include("lua.revelitems.passives.burningbush.BushCfg")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--[[
Fire a jet of fire, with a cooldown, instead of tears
]]


--How various factors affect burning bush stats
--prev = stat before getting modified, x = current factor
BushCfg.StatInfluence = {
    PlayerStatOrder = { --just in case
        "TearRange", "MaxFireDelay", "ShotSpeed", "Damage"
    },
    --x is the value of each stat
    PlayerStat = {
        TearRange = {
            Life = function(player, prev, x)
                return prev * x / BushCfg.DefaultTearRange
            end
    },
    MaxFireDelay = {
        MaxFuel = function(player, prev, x)
            return prev * REVEL.Lerp3PointClamp(1.6, 1, 0.8, x, 5, BushCfg.DefaultMaxFiredelay, 50)
        end,
        FuelChargeSpeed = function(player, prev, x)
            return prev * REVEL.Lerp3PointClamp(3  , 1, 0.5, x, 5, BushCfg.DefaultMaxFiredelay, 50)
        end,
        DmgMult = function(player, prev, x)
            return prev * REVEL.Lerp(1, BushCfg.DefaultMaxFiredelay / x, BushCfg.FiredelayDamageInfluence)
        end,
        BurnTickDelay = function(player, prev, x)
            return prev * REVEL.Lerp3PointClamp(0.2, 1, 1.5, x, 5, BushCfg.DefaultMaxFiredelay, 18)
        end,
        FiresPerUpdate = function(player, prev, x)
            return prev * REVEL.Lerp3PointClamp(2.1, 1, 0.15, x, 1, BushCfg.DefaultMaxFiredelay, 100)
        end
    },
    ShotSpeed = {
        Life = function(player, prev, x)
            return prev + REVEL.Lerp(0, (x - 1) * 25, 0.2)
        end,
        AvgShotSpeed = function(player, prev, x)
            return prev * REVEL.Lerp(1, x, BushCfg.ShotSpeedInfluence)
        end,
        ConeAngleMult = function(player, prev, x)
            return prev * REVEL.Lerp3PointClamp(1.5, 1, 0.3, x, 0.6, 1, 1.4)
        end
    },
    Damage = {
        BaseDamage = function(player, prev, x)
            if x <= 3.5 then
                return x
            end

            local stats = player:GetData().BushStats
            local tearrateIncrease = BushCfg.DefaultMaxFiredelay / stats.FiresPerUpdate
            return REVEL.Lerp2Clamp(3.5, x, 2 / tearrateIncrease)
        end
    }
    },
    --x is the amount of each item
    Item = {
        [CollectibleType.COLLECTIBLE_20_20] = {
            DmgMult = function(player, prev, x)
                return prev * (1 + x)
            end,
            ScaleMult = function(player, prev, x)
                return prev * 1.2
            end,
            MaxHeadOffset = function(player, prev, x)
                return prev + 7
            end
        },
        [CollectibleType.COLLECTIBLE_IPECAC] = {
            Requires = function(player, x) return player:HasWeaponType(WeaponType.WEAPON_TEARS) end,
            DmgMult = function(player, prev, x) return prev * 3 end,
            ScaleMult = function(player, prev, x) return prev * 1.5 end
        },
        [CollectibleType.COLLECTIBLE_MOMS_KNIFE] = {
            Requires = function(player, x) return player:HasWeaponType(WeaponType.WEAPON_KNIFE) end,
            DmgMult = function(player, prev, x) return prev * 3 end,
            ScaleMult = function(player, prev, x) return prev * 1.5 end
        },
        [CollectibleType.COLLECTIBLE_FIRE_MIND] = {
            DmgMult = function(player, prev) return prev * 2 end
        },
        [CollectibleType.COLLECTIBLE_CONTINUUM] = {
            Life = function(player, prev) return prev * 2 end
        },
        [REVEL.ITEM.MINT_GUM.id] = { --also has custom sprite effects on ShootFireTear
            ScaleMult = function(player, prev) return prev * 1.1 end
        },
        [CollectibleType.COLLECTIBLE_MARKED] = {
            -- reduce damage, remove cooldown due to forced shooting
            NoCooldown = function(player, prev) return true end,
            FiresPerUpdate = function(player, prev) return prev * 0.8 end,
        },
    },
    --x is not used
    WeaponType = {
        [WeaponType.WEAPON_LUDOVICO_TECHNIQUE] = {
            DmgMult = function(player, prev) return prev * 2.5 end,
            ScaleMult = function(player, prev) return prev + 0.2 end
        },
        [WeaponType.WEAPON_BRIMSTONE] = {
            DmgMult = function(player, prev)
                    if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
                        return prev * 0.6
                    else
                        return prev * 3
                    end
                end
        }
    },
    --x is the stream amount, these are only applied if there is more than 1 stream
    Streams = {
        DmgMult = function(player, prev, x)
            --damage is increased as less fires are in a single stream the more streams you have, for lag reasons
                return prev * x / 1.2
            end,
        ScaleMult = function(player, prev, x)
                return prev * 1.1
            end,
        MultiShotAngle = function(player, prev, x)
                return prev * 3 / x
            end
    },
    Character = {
        [REVEL.CHAR.DANTE.Type] = {
            Requires = function(player)
                return REVEL.IsDanteCharon(player)
            end,
            Life = function(player, prev)
                return prev * 1.8 --reduced by lamp
            end
        },
        [PlayerType.PLAYER_THEFORGOTTEN] = {
            Life = function(player, prev)
                return prev * 0.8
            end,
            FiresPerUpdate = function(player, prev)
                return prev * 0.3
            end
        },
    }
}

REVEL.BurningBush = {}

function REVEL.BurningBush.HasWeapon(player)
    if not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then
        return false
    end

    if REVEL.HasWeaponTypeInList(player, BushCfg.WeaponTypeFiringBlacklist)
    or BushCfg.PlayerTypeFiringBlacklist[player:GetPlayerType()]
    or (player:HasWeaponType(WeaponType.WEAPON_TEARS) and REVEL.HasCollectibleInList(player, BushCfg.ItemWithTearsFiringBlacklist))
    or player:GetData().robot
    or (player:GetPlayerType() ~= PlayerType.PLAYER_THEFORGOTTEN and player:HasWeaponType(WeaponType.WEAPON_BONE)) then
        return false
    elseif not (player.CanShoot and not player:GetData().Frozen) then
        return false
    end

    return true
end

function REVEL.BurningBush.GetDps(player)
    local stats = player:GetData().BushStats

    local dps = stats.BaseDamage * stats.DmgMult * stats.FiresPerUpdate * 30 --doesn't take ground fires and the burning effect into account

    dps = dps * 1.5 --to offset for burning damage and small fires, cannot account for that exactly

    return dps
end

local function burningbush_PreEstimateDps(player)
    if REVEL.BurningBush.HasWeapon(player) then
        return REVEL.BurningBush.GetDps(player)
    end
end
StageAPI.AddCallback("Revelations", RevCallbacks.PRE_ESTIMATE_DPS, 1, burningbush_PreEstimateDps)

REVEL.ITEM.BURNBUSH:addCostumeCondition(function(player)
    return not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
end)

function REVEL.BurningBush.UsesFireTears(player)
    return REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) 
        or (
            player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER) 
            and REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player)
        )
end

local function applyStatList(statList, player, data, x)
    for stat, func in pairs(statList) do
        if stat ~= "Requires" then
            if data.BushStats[stat] ~= nil then
                data.BushStats[stat] = func(player, data.BushStats[stat], x)

            else
                error("Trying to set non-existing burning bush stat! Stat: " .. stat)
            end
        end
    end
end

--To be run after cache eval of the relevant stats
local function updateStats(player)
    local data = player:GetData()

    if not data.BushStats then data.BushStats = {} end

    for stat, base in pairs(BushCfg.BaseStats) do
        data.BushStats[stat] = base
    end

    data.BushStats.Streams = REVEL.GetMultiShotNum(player, true)

    for _, statKey in ipairs(BushCfg.StatInfluence.PlayerStatOrder) do
        local stats = BushCfg.StatInfluence.PlayerStat[statKey]
        if player[statKey] and (not stats.Requires or stats.Requires(player, player[statKey])) then
            applyStatList(stats, player, data, player[statKey])
        elseif not player[statKey] then
            error("Using non-existing stat as a key for burning bush balance! Stat: " .. tostring(statKey))
        end
    end

    for itemID, stats in pairs(BushCfg.StatInfluence.Item) do
        local x = player:GetCollectibleNum(itemID)
        if x > 0 and (not stats.Requires or stats.Requires(player, x)) then
            applyStatList(stats, player, data, x)
        end
    end

    for wType, stats in pairs(BushCfg.StatInfluence.WeaponType) do
        if player:HasWeaponType(wType) and (not stats.Requires or stats.Requires(player, 1)) then
            applyStatList(stats, player, data, 1)
        end
    end

    for playerType, stats in pairs(BushCfg.StatInfluence.Character) do
        if player:GetPlayerType() == playerType and (not stats.Requires or stats.Requires(player)) then
            applyStatList(stats, player, data, 1)
        end
    end

    if data.BushStats.Streams > 1 then
        applyStatList(BushCfg.StatInfluence.Streams, player, data, data.BushStats.Streams)
    end

    data.BushStats.FiresPerUpdate = data.BushStats.FiresPerUpdate * BushCfg.FirerateToDamageRatio
    data.BushStats.DmgMult = data.BushStats.DmgMult / BushCfg.FirerateToDamageRatio
    data.BushStats.ScaleMult = REVEL.Lerp(data.BushStats.ScaleMult, data.BushStats.ScaleMult / BushCfg.FirerateToDamageRatio, 0.2)

    data.BushStats.FiresPerUpdate = math.min(BushCfg.MaxFiresPerUpdate, data.BushStats.FiresPerUpdate)
end

function REVEL.BurningBush.ForceStatRecalc(player)
    updateStats(player)
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, function()
    for _, player in ipairs(REVEL.players) do
        updateStats(player)
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    if REVEL.BurningBush.UsesFireTears(player) then
        if flag ~= CacheFlag.CACHE_LUCK and REVEL.includes(BushCfg.StatAffectingCacheflags, flag) then --luck is last to run
            player:AddCacheFlags(CacheFlag.CACHE_LUCK)
        else
            updateStats(player)
        end
    end
end)

for itemId, _ in pairs(BushCfg.StatInfluence.Item) do
    local item = REVEL.config:GetCollectible(itemId)
    local addCallback = false
    for _, flag in ipairs(BushCfg.StatAffectingCacheflags) do
        if not HasBit(item.CacheFlags, flag) then
            addCallback = true
        end
    end

    if addCallback then
        StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 2, function(player)
            if REVEL.BurningBush.UsesFireTears(player) then
                updateStats(player)
            end
        end, itemId)
    end
end

-- function fnum(x)
--   Cfg.MaxFiresPerUpdate = math.max(x, Cfg.MaxFiresPerUpdate)
--   Cfg.BaseStats.FiresPerUpdate = x
--   for _, player in ipairs(REVEL.players) do updateStats(player) end
-- end

local fireParticle = REVEL.ParticleType.FromTable{
    Name = "Burning Bush Spark",
    Anm2 =  "gfx/1000.066_ember particle.anm2",
    BaseLife = 40,
    Variants = 8,
    ScaleRandom = 0.2,
    StartScale = 0.7,
    EndScale = 0.5,
    Turbulence = true,
    TurbulenceReangleMinTime = 5,
    TurbulenceReangleMaxTime = 20,
    TurbulenceMaxAngleXYZ = Vec3(45,35,35),
    AnimationName = "Idle",
    OrientToMotion = true
}
local smokeParticle = REVEL.ParticleType.FromTable{
    Name = "Burning Bush Smoke",
    Anm2 =  "gfx/1000.066_ember particle.anm2",
    BaseColor = Color(0.7, 0.7, 0.7, 0.8,conv255ToFloat( 25, 25, 25)),
    BaseLife = 25,
    Variants = 8,
    ScaleRandom = 0.2,
    StartScale = 0.6,
    EndScale = 0.45,
    Turbulence = true,
    Weight = 0.5,
    TurbulenceReangleMinTime = 9,
    TurbulenceReangleMaxTime = 30,
    TurbulenceMaxAngleXYZ = Vec3(7,7,20),
    AnimationName = "Idle"
}
fireParticle:SetAlphaOverLife(function(self, life, lifeMax)
    return math.cos(life)*0.35+0.65
end)

local fireSystem = REVEL.ParticleSystems.LowGravity

REVEL.FireSystem = fireSystem
REVEL.FireParticle = fireParticle
REVEL.SmokeParticle = smokeParticle

local fireEmitter = REVEL.HalfSphereEmitter(3)
local smokeEmitter = REVEL.Emitter()

local getFireOffset --function(input, player, stream)
local getFireVelocity --function(input, player, stream)
local playEndSfx --function
local spawnPermaFire --function(pos, vel, spawnerFire, sizeMult, lifeMult, noHeight, randomReplace, dmgMultReplace)
local collides --function(fire, pos, vel)
local ShootFireTear --function(player, pos, vel, strengthPct, fromPlayer, lifeMult, dmgMult, scaleMult)

function REVEL.BurningBush.AddCustomBurn(npc, duration, hurtDelay, damage, source)
    local data = npc:GetData()
    if npc:IsVulnerableEnemy() 
    and not (
        npc:HasEntityFlags(EntityFlag.FLAG_BURN) 
        or npc:HasEntityFlags(EntityFlag.FLAG_POISON) 
        or npc:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    ) then
        data.BurnSource = EntityRef(source)
        npc:AddBurn(data.BurnSource, duration, 1)
        if not data.CustomBurn then
            data.BurnDelay = hurtDelay
        end

        data.BurnMaxDelay = hurtDelay
        data.BurnDamage = damage
        data.BurnDuration = duration
        data.CustomBurn = true
    end
end

-- Usually used by player, but can be reused to make things like Gello/Incubus shoot
local function BurningbushShooterUpdate(entity, data, stats, player, useCostume, setFiredelay)
    if not data.costumeFrame then
        data.bushFuel = stats.MaxFuel
        data.bushFireDelay = 0
        data.costumeProgress = 0
        data.costumeFrame = 0
        data.maxFuelBurst = 0
        data.startSoundTime = -1
    end

    if setFiredelay == nil then setFiredelay = true end

    if not (player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN and player:HasWeaponType(WeaponType.WEAPON_BONE)) 
    and setFiredelay then
        --Prevent normal firing
        entity.FireDelay = 3
    end

    local input = REVEL.GetCorrectedFiringInput(player)
    local avgVel = input * stats.AvgShotSpeed
    local fuelPct = data.bushFuel / stats.MaxFuel

    -- Manage timing here, doesn't use POST_RENDER (probably a familiar or smth)
    if not useCostume then
        if REVEL.IsShooting(player)
        and data.costumeFrame < BushCfg.CostumeFramesNum then
            data.costumeFrame = data.costumeFrame + 1
        elseif not REVEL.IsShooting(player) then
            data.costumeFrame = 0
        end
    end

    if REVEL.IsShooting(player)
    and not data.springHeight
    and not data.DisableBurningBush
    then
        --costume frames managed in post entity render due to costumes messing with head dir
        local time = Isaac.GetTime()

        if data.costumeFrame == BushCfg.PlayStartSoundAtFrame and not data.bushPlayedStartSound then
            REVEL.sfx:Play(REVEL.SFX.FIRE_START, 0.9, 0, false, 1)
            data.startSoundTime = time
            data.bushPlayedStartSound = true
        elseif data.bushPlayedStartSound and time >= data.startSoundTime + BushCfg.StartSoundDurMs and not data.bushPlayedLoopSound then
            data.bushPlayedLoopSound = true
            REVEL.sfx:Play(REVEL.SFX.FIRE_LOOP, 0.83, 0, true, 1)
        end

        --animation finished, shoot
        if data.costumeFrame >= BushCfg.CostumeFramesNum then
            local fuelStrengthPct = REVEL.LinearStep(fuelPct, 0, BushCfg.FuelWeakStartPct)

            if fuelPct == 1 then --max fuel burst
                data.maxFuelBurst = BushCfg.MaxFuelBurstFrameDur
            elseif data.maxFuelBurst > 0 then
                data.maxFuelBurst = data.maxFuelBurst - 1
            end

            --firing frequency
            local treshold = 1 / (
                stats.FiresPerUpdate 
                * REVEL.Lerp2Clamp(BushCfg.WeakFreqMult, 1, fuelStrengthPct, 0, BushCfg.FuelWeakStartPct)
                * BushLagAdjGlobals.FirerateMult * (data.maxFuelBurst > 0 and BushCfg.MaxFuelBurstFirerateMult or 1) 
            )
            data.bushFireDelay = data.bushFireDelay + 1

            while data.bushFireDelay >= treshold do
                data.bushFireDelay = data.bushFireDelay - treshold
                for i=1, stats.Streams do
                    --shoot less tears for multiple shot items, for lag reasons, to compensate for this damage is increased
                    if math.random() < 1.5/stats.Streams or stats.Streams <= 2 then
                        ShootFireTear(player, entity.Position + getFireOffset(input, player, i), getFireVelocity(avgVel, player, i), fuelStrengthPct)
                    end
                end
            end

            fireEmitter:SetLookDir(Vec3(input, 0))
            if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) then
                fireEmitter:EmitParticlesPerSec(fireParticle, fireSystem, Vec3(entity.Position - input * 2, -3), -Vec3(input*6, 0), 15, 0.5, 60)
            else
                fireEmitter:EmitParticlesPerSec(fireParticle, fireSystem, Vec3(entity.Position + input * 2, -17), Vec3(input*6, 0), 15, 0.5, 60)
            end

            if not stats.NoCooldown or fuelPct > 0.5 then
                data.bushFuel = math.max(0, data.bushFuel - 1)
            end
        end
    else
        data.bushFuel = math.min(data.bushFuel + stats.FuelChargeSpeed, stats.MaxFuel)
        if data.costumeFrame > 0 then
            if data.costumeFrame == BushCfg.CostumeFramesNum then
                REVEL.sfx:Play(REVEL.SFX.FIRE_END, 0.85, 0, false, 1)
            end

            if useCostume then
                entity:TryRemoveNullCostume(REVEL.COSTUME.BURNBUSH[data.costumeFrame])
            end
            data.costumeFrame = 0
        end
        if data.bushPlayedLoopSound or data.bushPlayedStartSound then
            REVEL.sfx:Stop(REVEL.SFX.FIRE_START)
            REVEL.sfx:Stop(REVEL.SFX.FIRE_LOOP)
            data.bushPlayedStartSound = false
            data.bushPlayedLoopSound = false
        end
    end

    local lowFuelColor = BushCfg.LowFuelColor
    if REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
        lowFuelColor = BushCfg.LowFuelColorMintGum
    end
    local pColor = REVEL.ColorLerp2Clamp(Color.Default, lowFuelColor, fuelPct, BushCfg.LowFuelColorTime, 0)
    entity:SetColor(pColor, 2, 2, false, true)

    -- REVEL.DebugToConsole("Player update took "..(Isaac.GetTime() - debugTime).."ms")
end

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)

    if not REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) then return end

    local data = player:GetData()
    if not data.BushStats then updateStats(player) end

    if REVEL.BurningBush.HasWeapon(player) then
        BurningbushShooterUpdate(player, data, data.BushStats, player, true)
    end
end)

--workaround due to costumes messing with head dir
revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player)
    if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal() then
        local data = player:GetData()
        if data.costumeFrame and REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) 
        and REVEL.IsShooting(player)
        and not data.DisableBurningBush then
            if data.costumeFrame < BushCfg.CostumeFramesNum then
                if data.costumeFrame == 0 or data.costumeProgress > (BushCfg.CostumeFrameDuration[data.costumeFrame] or 0) then
                    if REVEL.COSTUME.BURNBUSH[data.costumeFrame] then
                        player:TryRemoveNullCostume(REVEL.COSTUME.BURNBUSH[data.costumeFrame])
                    end
                    data.costumeFrame = data.costumeFrame + 1
                    player:AddNullCostume(REVEL.COSTUME.BURNBUSH[data.costumeFrame])
                    data.costumeProgress = 0
                end
                data.costumeProgress = data.costumeProgress + 0.5 --60fps
            end
        end
    end
end)

local ShootingFireTear = false

--SHOOT FIRE TEAR
---comment
---@param player? EntityPlayer
---@param pos Vector
---@param vel Vector
---@param strengthPct? number
---@param fromPlayer? boolean
---@param lifeMult? number
---@param dmgMult? number
---@param scaleMult? number
---@return EntityTear
function ShootFireTear(player, pos, vel, strengthPct, fromPlayer, lifeMult, dmgMult, scaleMult)
    player = player or REVEL.player
    dmgMult = dmgMult or 1
    lifeMult = lifeMult or 1
    strengthPct = strengthPct or 1
    scaleMult = scaleMult or 1
    if fromPlayer == nil and player then fromPlayer = true end

    local pdata = player:GetData()
    if not pdata.BushStats then
        updateStats(player)
    end
    local stats = pdata.BushStats

    pdata.FiringFireTear = true

    -- flags done before shooting, since some
    -- flags need to never be there else 
    -- the vfx stays even after removing the flag 
    -- (like TEAR_BURN)

    local origFlags = BitSet128(player.TearFlags.l, player.TearFlags.h)
    for flag, replacement in pairs(BushCfg.TearFlagBlackList) do
        if HasBit(player.TearFlags, flag) then
            player.TearFlags = ClearBit(player.TearFlags, flag)
            if replacement then
                player.TearFlags = BitOr(player.TearFlags, replacement)
            end
        end
    end
    player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_SPECTRAL, TearFlags.TEAR_PIERCING)

    ShootingFireTear = true
    local fire = player:FireTear(pos, vel, false, false, false)
    ShootingFireTear = false

    player.TearFlags = origFlags

    pdata.FiringFireTear = false

    fire:ChangeVariant(TearVariant.BLUE)

    local wasHd = REVEL.IsHDTearSprite(fire)
    local data, sprite = fire:GetData(), fire:GetSprite()

    data.OrigTearFlags = origFlags

    data.MintGumFire = REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player)
    data.IceTrayFire = REVEL.ITEM.ICETRAY:PlayerHasCollectible(player)

    if data.MintGumFire then --mint gum synergy
        sprite:Load("gfx/effects/revelcommon/mint_gum_burning_bush_tears.anm2", true)
        sprite.Rotation = math.random()*90
        data.Rotation = sprite.Rotation
        data.MintGumSprite = true

    elseif data.IceTrayFire then --ice tray synergy, steam
        sprite:Load("gfx/effects/revelcommon/burning_tears_ice_tray.anm2", true)
        data.IceTrayFrame = math.random(0, 2)
        sprite:SetFrame("RegularTear1", data.IceTrayFrame)
        data.IceTraySprite = true
        scaleMult = scaleMult * 1.5

    else --default tear
        sprite:Load("gfx/effects/revelcommon/burning_tears.anm2", false)
        if REVEL.Dante.IsCharon(player) then
            sprite:ReplaceSpritesheet(0, "gfx/effects/effect_005_fire_blue.png")
        end
        sprite:LoadGraphics()
        sprite.Rotation = 0
        data.Rotation = 0
    end

    data.ScaleMult = stats.ScaleMult * BushLagAdjGlobals.ScaleMult * REVEL.Lerp(1, math.random()*2, BushCfg.ScaleRandom)
                    * REVEL.Lerp(BushCfg.WeakScaleMult, 1, strengthPct) * scaleMult
    local tempMult = 1
    if wasHd then
        data.ScaleMult = data.ScaleMult * 2.5
        tempMult = 1 / 2.5
    end
    local scale = BushCfg.BaseStartScale * data.ScaleMult

    data.DmgMult = stats.DmgMult * BushLagAdjGlobals.DmgMult * REVEL.Lerp(BushCfg.WeakDmgMult, 1, strengthPct) * dmgMult
    data.StartVelocity = vel
    data.Life = stats.Life * REVEL.Lerp(1, math.random()*2, BushCfg.LifeRandom) * lifeMult
    data.StartLife = data.Life
    data.Height = stats.Height
    data.BaseSize = fire.Size
    data.BaseDamage = stats.BaseDamage
    data.SmallFireMaxDelay = 1 / stats.SmallFiresInPathPerFrame
    data.SmallFireDelay = math.random() * data.SmallFireMaxDelay
    -- Might have been set by on tear callbacks
    if not data.CustomColor then
        data.CustomColor = REVEL.ClampColor(fire.Color, BushCfg.FireColorLowerClamp, BushCfg.FireColorUpperClamp)
    end

    sprite:Play("RegularTear1", true)
    fire.SpriteScale = Vector.One * scale * tempMult
    fire.SplatColor = REVEL.NO_COLOR
    fire.Color = (data.MintGumSprite or data.IceTraySprite) and (data.CustomColor or Color.Default) or BushCfg.BlueColor

    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) and fromPlayer then --fecal freak synergy
        fire.SpriteOffset = BushCfg.FecalFreakSpriteOffset
    end

    fire.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    fire.Size = fire.Size * scale
    fire.CollisionDamage = data.BaseDamage * data.DmgMult
    fire.Height = data.Height

    if revel.data.cLightSetting == 2 then
        data.Light = REVEL.SpawnLightAtEnt(fire, (data.CustomColor ~= nil) and BushCfg.LightColor * data.CustomColor or BushCfg.LightColor, BushCfg.BaseLightScale, Vector(0, fire.Height), true)
    end

    data.BurningBush = true
    data.revelTearInit = true
    data.__alphaInit = true --to prevent this tear being overridden by alphaapi mods
    data.__player = player

    return fire
end

-- Common enough to leave in main table

REVEL.ShootFireTear = ShootFireTear

function REVEL.BurningBush.IsShootingFireTear()
    return ShootingFireTear
end

local lastDebugFrame = -1

function revel:FireTearUpdate(fire)
    local sprite, data = fire:GetSprite(), fire:GetData()
    if not data.BurningBush then return end

    -- local debugTime = Isaac.GetTime()

    fire.Height = data.Height

    data.Life = data.Life - 1

    if data.Life <= 0 then
        fire:Remove()
        return
    end

    local pct = data.Life / data.StartLife

    local scale = data.ScaleMult * REVEL.Lerp3PointClamp(BushCfg.BaseStartScale, BushCfg.BaseMidScale, BushCfg.BaseDeathScale, pct,
                                                        1, BushCfg.MidScaleTime, 0)
    data.SetScale = scale --for some reason, changing spritescale only works in POST_UPDATE, see the callback below for that
    fire.Size = data.BaseSize * scale

    local midColor = data.CustomColor or Color.Default
    local color
    if not data.MintGumSprite and not data.IceTraySprite then
        color = REVEL.ColorLerp2Clamp(BushCfg.BlueColor, midColor, pct, 1, BushCfg.BlueEndTime)
        color = REVEL.ColorLerp2Clamp(color, BushCfg.YellowColor, pct, BushCfg.YellowStartTime, 0)
    else
        color = REVEL.CloneColor(midColor)
    end
    local alpha = REVEL.Lerp2Clamp(BushCfg.MaxOpacity, 0, pct, BushCfg.FadeStartTime, 0)
    color.A = alpha
    fire.Color = color

    if data.Rotation then 
        sprite.Rotation = data.Rotation 
    end
    if data.IceTraySprite then
        local frameProgress = math.min(2, REVEL.Round(REVEL.Lerp2Clamp(0, 3, alpha / BushCfg.MaxOpacity, 1, 0)))
        sprite:SetFrame("RegularTear1", data.IceTrayFrame + frameProgress * 3)
    end

    --Velocity and collision

    if pct < BushCfg.SlowDownTime then
        fire.Velocity = fire.Velocity * 0.9
    end

    if not data.Collided and collides(fire) then
        fire.Velocity = Vector.Zero
        REVEL.FireTearDie(fire)
        data.Collided = true
    end

    --Melt ice hazards
    if REVEL.STAGE.Glacier:IsStage() then
        local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, true, false)
        for _, hazard in ipairs(iceHazards) do
            local minDist = fire.Size + hazard.Size
            if not hazard:GetData().LockedInPlace and hazard.Position:DistanceSquared(fire.Position) < minDist*minDist then
                REVEL.MeltEntity(hazard)
            end
        end
    end

    local grid = REVEL.room:GetGridEntityFromPos(fire.Position)

    --leave small fires
    if not grid or grid.CollisionClass == GridCollisionClass.COLLISION_NONE then
        data.SmallFireDelay = data.SmallFireDelay + 1
        local treshold = data.SmallFireMaxDelay / BushLagAdjGlobals.PermaFireRateMult
        
        if data.SmallFireDelay >= treshold and data.IceTrayFire then
            Isaac.Spawn(1000, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, fire.Position, Vector.Zero, data.__player):Update()
        end

        while data.SmallFireDelay >= treshold do
            data.SmallFireDelay = data.SmallFireDelay - treshold
            spawnPermaFire(fire.Position, fire.Velocity * 0.6, fire)
        end
    end

    smokeEmitter:EmitParticlesPerSec(smokeParticle, fireSystem, Vec3(fire.Position, fire.Height), Vec3(fire.Velocity * 0.1, -3),
        BushCfg.SmokePerSecond * BushLagAdjGlobals.SmokeRateMult, 0.2, 30)

    -- if lastDebugFrame ~= REVEL.game:GetFrameCount() then
    --   REVEL.DebugToConsole("Fire #"..fire.Index.." update took "..(Isaac.GetTime() - debugTime).."ms")
    --   lastDebugFrame = REVEL.game:GetFrameCount()
    -- end
end

function REVEL.FireTearDie(fire)
    local data = fire:GetData()
    data.Life = data.StartLife * BushCfg.MidScaleTime
end

-- revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, revel.FireTearUpdate)

local lastHitsoundTime = -1

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG , function(_,  e, dmg, flag, srcRef, invuln)
    local data = e:GetData()
    if not e:ToNPC() then return end
    local player, src = REVEL.GetPlayerFromDmgSrc(srcRef)

    if player then
        local stats = player:GetData().BushStats
        if src.Type == 2 then
            local sData = src:GetData()

            if sData.BurningBush then
                local time = Isaac.GetTime()
                if BitAnd(sData.OrigTearFlags, TearFlags.TEAR_GREED_COIN) > 0 
                and math.random() * 80 <= REVEL.Lerp3PointClamp(0.5, 1, 3.5, player.Luck, -4, 0, 12) then
                    Isaac.Spawn(5, PickupVariant.PICKUP_COIN, 0, e.Position, Vector.Zero, player)
                end
                --Custom burn
                REVEL.BurningBush.AddCustomBurn(e, stats.BurnDuration, stats.BurnTickDelay, player.Damage * BushCfg.BurnDamageMult, player)
                REVEL.PushEnt(e, 0.15, src.Velocity, 3)

                if time - lastHitsoundTime > BushCfg.HitSoundMinDelayMs then
                    lastHitsoundTime = time
                    REVEL.sfx:Play(BushCfg.HitSound, 0.75, 0, false, 0.95 + math.random() * 0.1)
                end
            end

        elseif (src.Type == EntityType.ENTITY_LASER or src.Type == 1) 
        and REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player) 
        and (player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) or player:HasWeaponType(WeaponType.WEAPON_LASER) 
                or player:HasWeaponType(WeaponType.WEAPON_TECH_X)) then
            REVEL.BurningBush.AddCustomBurn(e, stats.BurnDuration / 2, stats.BurnTickDelay, player.Damage, player)
        end
    end
    if HasBit(flag, DamageFlag.DAMAGE_POISON_BURN) and data.CustomBurn and not data.TakingCustomBurnDamage then
        return false
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    local data = npc:GetData()
    if not data.CustomBurn then return end

    if npc:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    or npc:IsDead()
    or npc:HasMortalDamage()
    then
        data.CustomBurn = nil
        return
    end

    data.BurnDelay = data.BurnDelay - 1
    while data.BurnDelay <= 0 do
        data.BurnDelay = data.BurnDelay + data.BurnMaxDelay
        data.TakingCustomBurnDamage = true
        if npc:IsVulnerableEnemy() and npc.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
            npc:TakeDamage(data.BurnDamage, DamageFlag.DAMAGE_POISON_BURN, data.BurnSource, 5)
        end
        data.TakingCustomBurnDamage = false
    end

    data.BurnDuration = data.BurnDuration - 1
    if data.BurnDuration <= 0 then
        data.CustomBurn = nil
    end
end)

---@param pos Vector
---@param vel Vector
---@param spawnerFire EntityTear
---@param sizeMult? number
---@param lifeMult? number
---@param noHeight? boolean
---@param randomReplace? number
---@param dmgMultReplace? number
function spawnPermaFire(pos, vel, spawnerFire, sizeMult, lifeMult, noHeight, randomReplace, dmgMultReplace)
    local player
    local sdata = spawnerFire:GetData()
    if spawnerFire.Type == 1 then
        player = spawnerFire
        spawnerFire = nil
    else
        player = sdata.__player
    end

    sizeMult = sizeMult or 1
    lifeMult = lifeMult or 1

    local permaFire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, pos, vel, player):ToEffect()
    local data, sprite = permaFire:GetData(), permaFire:GetSprite()
    data.BurningBushPermaFire = true
    data.PermaFireSize = permaFire.Size * sizeMult
    data.PermaFireScale = BushCfg.PermaFireScale * sizeMult * REVEL.Lerp(1, math.random()*2, randomReplace or BushCfg.PermaFireScaleRandom)
    data.Life = BushCfg.PermaFireLife * lifeMult
    data.StartLife = data.Life

    if not noHeight then
        assert(spawnerFire, "with player as spawnerFire noHeight must be true")

        data.Height = spawnerFire.Height
        data.FallingSpeed = 0
        data.FallingAcceleration = 0.4
    end

    permaFire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
    permaFire.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
    permaFire.Color = sdata.CustomColor or player.TearColor

    if REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) then
        sprite:ReplaceSpritesheet(0, "gfx/effects/effect_005_fire_blue.png")
        sprite:LoadGraphics()
        permaFire.Color = permaFire.Color * BushCfg.MintGumPermafireColor
    elseif REVEL.Dante.IsCharon(player) then
        sprite:ReplaceSpritesheet(0, "gfx/effects/effect_005_fire_blue.png")
        sprite:LoadGraphics()
        permaFire.Color = permaFire.Color * BushCfg.CharonColor
    end

    if data.Height then
        permaFire.SpriteOffset = Vector(0, data.Height)
    end
    permaFire.Size = data.PermaFireSize * data.PermaFireScale
    permaFire.SpriteScale = Vector.One * data.PermaFireScale
    if spawnerFire then
        permaFire.CollisionDamage = spawnerFire.CollisionDamage * (dmgMultReplace or BushCfg.PermaFireDmgMult)
    else
        local stats = player:GetData().BushStats

        permaFire.CollisionDamage = stats.BaseDamage * stats.DmgMult * (dmgMultReplace or BushCfg.PermaFireDmgMult)
    end
end

REVEL.BurningBush.SpawnPermaFire = spawnPermaFire

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data = eff:GetData()
    if data.BurningBushPermaFire then
        data.Life = data.Life - 1
        if data.Life <= 0 then
            eff:Remove()
            return
        end

        local pct = data.Life / data.StartLife

        if pct <= BushCfg.PermaFireShrinkStart then
            local scale = REVEL.Lerp2Clamp(0, data.PermaFireScale, pct, 0, BushCfg.PermaFireShrinkStart)
            eff.Size = data.PermaFireSize * scale
            eff.SpriteScale = Vector.One * scale
        end

        if data.Height and data.Height < 0 then
            data.FallingSpeed = data.FallingSpeed + data.FallingAcceleration
            data.Height = math.min(0, data.Height + data.FallingSpeed)
            eff.SpriteOffset = Vector(0, data.Height)
            eff.Velocity = eff.Velocity * 0.85
        else
            eff.Velocity = eff.Velocity * 0.6
        end
    end
end)

local function isCollidingGrid(fire, grid)
    return grid and (
            (grid:ToRock() and not REVEL.IsGridBroken(grid)) 
            or grid.Desc.Type == GridEntityType.GRID_DOOR 
            or grid.Desc.Type == GridEntityType.GRID_WALL
        ) 
        and (
            math.abs(grid.Position.X - fire.Position.X) < 17 
            or math.abs(grid.Position.Y - fire.Position.Y) < 17
        )
end

local function isGridIndexInRoom(index) --excludes border walls, since the borders have a different treatment
    local width = REVEL.room:GetGridWidth()
    local height = REVEL.room:GetGridHeight()
    local x, y = StageAPI.GridToVector(index, width)

    return x > 0 and x < width - 1 and y > 0 and y < height - 1
end

function collides(fire)
    local data = fire:GetData()

    local nextPos = fire.Position + fire.Velocity
    local tl, br = REVEL.GetRoomCorners()
    local index = REVEL.room:GetGridIndex(nextPos)
    local grid = REVEL.room:GetGridEntity(index)

    local isIceBlock
    --Melt ice blocks
    if REVEL.STAGE.Glacier:IsStage() and REVEL.includes(REVEL.GlacierGfxRoomTypes, StageAPI.GetCurrentRoomType()) then
        if grid and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT and not REVEL.IsGridBroken(grid) then
            REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(index))
            REVEL.room:DestroyGrid(index, true)
            isIceBlock = true
        end
    end

    --if it's a wall, or a unbroken rock, or a door
    if BitAnd(data.OrigTearFlags, BitOr(TearFlags.TEAR_SPECTRAL, TearFlags.TEAR_CONTINUUM)) <= TearFlags.TEAR_NORMAL
    and (fire.Position.X < tl.X or fire.Position.X > br.X or fire.Position.Y < tl.Y or fire.Position.Y > br.Y+21 
            or (isGridIndexInRoom(index) and isCollidingGrid(fire, grid) and not isIceBlock)) then
        return true
    end
end


StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARS_FIRE_SOUND, 0, function(ent, data, spr)
    if ShootingFireTear then
        return false
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARIMPACTS_SOUND, 0, function(ent, data, spr)
    if data.BurningBush then
        return false
    end
end)

function getFireVelocity(avgVel, player, stream, radiusMult)
    radiusMult = radiusMult or 1
    stream = stream or 1
    local stats = player:GetData().BushStats
    local angle
    if stats.Streams == 1 then
        local coneAngle = math.floor(BushCfg.ConeAngle1Shot * stats.ConeAngleMult)
        angle = -coneAngle / 2 + math.random(coneAngle)
    elseif stats.Streams == 2 then
        local coneAngle = math.floor(BushCfg.ConeAngle2Shot * stats.ConeAngleMult)
        angle = -coneAngle / 2 + math.random(coneAngle) + 45 * (stream == 1 and 1 or -1)
    elseif stats.Streams > 2 then
        local coneAngle = math.floor(BushCfg.ConeAngleMultiShot * stats.ConeAngleMult)
        local totalAngle = (stats.Streams - 1) * stats.MultiShotAngle
        angle = -coneAngle / 2 + math.random(coneAngle) - totalAngle * 0.5 + (stream - 1) * stats.MultiShotAngle
    end

    return avgVel:Rotated(angle) + (player.Velocity*0.5)
end

function getFireOffset(input, player, stream)
    stream = stream or 1
    local stats = player:GetData().BushStats
    local angle = player:GetFireDirection()*90

    if stats.Streams == 2 then --the wiz, as 20/20 is a buff
        angle = angle + 45 * (stream == 1 and 1 or -1)
    elseif stats.Streams > 2 then
        local totalAngle = (stats.Streams - 1) * stats.MultiShotAngle
        angle = angle -totalAngle * 0.5 + (stream - 1) * stats.MultiShotAngle
    end

    if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) then
        return -(input*15 + Vector(0, -stats.MaxHeadOffset + math.random(stats.MaxHeadOffset * 2)):Rotated(angle))
    else
        return input*10 + Vector(0, -stats.MaxHeadOffset + math.random(stats.MaxHeadOffset * 2)):Rotated(angle)
    end
end

--Lag adjustment, SpriteScale set and trisagion fix

local prevFiresNum

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local debugTime = Isaac.GetTime()

    --lag adjustment: reduce fire rate and increase tear dmg/size for more tears
    local fires = REVEL.filter(REVEL.roomTears, function(tear) return tear:GetData().BurningBush end)
    for _, fire in ipairs(fires) do
        revel:FireTearUpdate(fire)

        if fire:GetData().SetScale then
            fire.SpriteScale = Vector.One * fire:GetData().SetScale
        end
        --Remove that goddarn trisagion
        if HasBit(fire.TearFlags, TearFlags.TEAR_LASER) then
            ClearBit(fire.TearFlags, TearFlags.TEAR_LASER)
        end
    end

    -- REVEL.DebugToConsole("Fires update took "..(Isaac.GetTime() - debugTime).."ms")

    if #fires ~= prevFiresNum then
        if #fires > BushCfg.LagAdjustmentMaxFires then
            local amount = (#fires - BushCfg.LagAdjustmentMaxFires + 1) ^ 0.15
            local invAmount = 1 / amount
            BushLagAdjGlobals.ScaleMult = amount
            BushLagAdjGlobals.FirerateMult = invAmount
            BushLagAdjGlobals.DmgMult = amount
            BushLagAdjGlobals.PermaFireRateMult = math.min(invAmount, 1)
            BushLagAdjGlobals.SmokeRateMult = REVEL.Lerp(invAmount, 1, 0.5)
        else
            BushLagAdjGlobals.ScaleMult = 1
            BushLagAdjGlobals.FirerateMult = 1
            BushLagAdjGlobals.DmgMult = 1
            BushLagAdjGlobals.PermaFireRateMult = 1
            BushLagAdjGlobals.SmokeRateMult = 1
        end

        prevFiresNum = #fires
    end
end)

end