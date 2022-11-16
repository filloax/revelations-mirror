local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------
-- DRAMAMINE --
---------------

REVEL.DramamineExplosionDmg = 40
REVEL.DramamineSubType = 152
REVEL.DramamineDisabledTearflags = {TearFlags.TEAR_SHRINK, TearFlags.TEAR_PIERCING, TearFlags.TEAR_PERSISTENT, TearFlags.TEAR_STICKY, TearFlags.TEAR_BOOGER, TearFlags.TEAR_LASERSHOT, TearFlags.TEAR_ABSORB}

function REVEL.SpawnDramamineTear(player, pos)
    return REVEL.TransformTearIntoDramamineTear(player:FireTear(pos, Vector.Zero, false, true, false))
end

function REVEL.TransformTearIntoDramamineTear(tear)
    local data = tear:GetData()
    tear.SubType = REVEL.DramamineSubType
    data.IsDramamineTear = true
    if REVEL.IsHDTearSprite(tear) then
        data.scaleFix = REVEL.VectorMult(tear:GetSprite().Scale, 2.5)
    end
    if HasBit(tear.TearFlags, TearFlags.TEAR_LASERSHOT) then
        local lasers = Isaac.FindByType(EntityType.ENTITY_LASER, -1, -1, false, false)
        for _,laser in ipairs(lasers) do
            if (laser.Position-tear.Position):LengthSquared() < 1 then
                laser.Visible = false
                laser:Remove()
            end
        end
    end
    
    if HasBit(tear.TearFlags, TearFlags.TEAR_ABSORB) then
        data.IsAbsorbingDramamine = true
        data.AbsorbedTears = 0
        tear:GetSprite():Load("gfx/effects/revelcommon/dramamine_hungry_ipecac.anm2", true)
    else
        tear:GetSprite():Load("gfx/effects/revelcommon/dramamine_ipecac.anm2", true)
    end
    
    for _,tearflag in ipairs(REVEL.DramamineDisabledTearflags) do
        tear.TearFlags = BitAnd(tear.TearFlags, ~tearflag)
    end
    tear:GetSprite():Play("IpecacSpawn", true)
    tear.Visible = true
    tear.Size = 15
    tear.FallingSpeed = 0
    tear.FallingAcceleration = -0.1
    tear.Height = -14
    data.DramamineExplode = function(oncollision, bombflags)
        REVEL.game:BombExplosionEffects(tear.Position, REVEL.DramamineExplosionDmg, bombflags or 0, tear.Color, tear, 1, true, true)
        
        for _,e in ipairs(REVEL.roomNPCs) do
            if (e.Position - tear.Position):LengthSquared() <= (e.Size + 100) ^ 2 
            and REVEL.room:CheckLine(e.Position, tear.Position, 2, 0, false, true) then
                local tearflag_to_debuff = {
                    [TearFlags.TEAR_SLOW] = function() e:AddSlowing(EntityRef(tear), 75, 1, Color(1,1,1,1,conv255ToFloat(0,0,0))) end,
                    [TearFlags.TEAR_POISON] = function() e:AddPoison(EntityRef(tear), 60, tear.BaseDamage) end,
                    [TearFlags.TEAR_FREEZE] = function() e:AddFreeze(EntityRef(tear), 60) end,
                    [TearFlags.TEAR_CHARM] = function() e:AddCharmed(EntityRef(tear), 120) end,
                    [TearFlags.TEAR_CONFUSION] = function() e:AddConfusion(EntityRef(tear), 150, false) end,
                    [TearFlags.TEAR_FEAR] = function() e:AddFear(EntityRef(tear), 180) end,
                    [TearFlags.TEAR_BURN] = function() e:AddBurn(EntityRef(tear), 120, tear.BaseDamage/2) end,
                    [TearFlags.TEAR_GODS_FLESH] = function() e:AddShrink(EntityRef(tear), 150) end,
                    [TearFlags.TEAR_PERMANENT_CONFUSION] = function() e:AddConfusion(EntityRef(tear), math.huge, true) end,
                    [TearFlags.TEAR_MIDAS] = function() e:AddMidasFreeze(EntityRef(tear), 105) end
                }
                
                for flag,func in pairs(tearflag_to_debuff) do
                    if HasBit(tear.TearFlags, flag) then
                        func()
                    end
                end
            end
        end
        
        if data.IsAbsorbingDramamine then
            if data.AbsorbedTears ~= 0 then
                local player = tear.Parent:ToPlayer()
                for i=1, 8 do
                    local split_tear = player:FireTear(tear.Position, Vector.FromAngle(i*45)*player.ShotSpeed*10, false, true, false)
                    split_tear.TearFlags = split_tear.TearFlags & ~TearFlags.TEAR_ABSORB
                    split_tear:ChangeVariant(TearVariant.BLOOD)
                    --split_tear:GetSprite():Play("BloodTear" .. tostring(math.floor((data.AbsorbedTears+4)/2)), true)
                    split_tear.Scale = 0.5 + data.AbsorbedTears*0.1
                    split_tear.CollisionDamage = split_tear.BaseDamage * 0.25 * data.AbsorbedTears
                end
            end
        end
        
        local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, tear.Position, Vector.Zero, tear)
        eff:GetData().IsDramamineSplash = true
        eff:GetSprite():Load("gfx/effects/revelcommon/dramamine_ipecac.anm2", true)
        eff:GetSprite():Play("IpecacPop", true)
        eff:GetSprite().Offset = Vector(0, -26)
        eff:GetSprite().Color = tear.Color
        if not oncollision then
            tear:Die()
        end
    end
    return tear
end

-- REVEL.AddCustomBar(REVEL.ITEM.DRAMAMINE.id, 300)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    REVEL.SpawnDramamineTear(player, player.Position)
    
    if HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        REVEL.SpawnDramamineTear(player, player.Position + Vector.FromAngle(math.random(0,359))*15)
    end
    
    return true
end, REVEL.ITEM.DRAMAMINE.id)

revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local data = tear:GetData()
    if not data.DramamineInit then
        if tear.SubType == REVEL.DramamineSubType then
            local tears = Isaac.FindInRadius(tear.Position, 1, EntityPartition.TEAR)
            for _,dramamine_tear in ipairs(tears) do
                if dramamine_tear:GetData().IsDramamineTear then
                    REVEL.TransformTearIntoDramamineTear(dramamine_tear:ToTear())
                end
            end
            tear.Position = tear.Position + Vector.FromAngle(math.random(0,359))*15
            REVEL.TransformTearIntoDramamineTear(tear)
        end
        data.DramamineInit = true
    end
    
    if data.IsDramamineTear then
        local sprite = tear:GetSprite()
        if data.icetray then data.icetray = false end

        if not data.StoppedInitVelocity then
            data.StoppedInitVelocity = true
            tear.Velocity = Vector.Zero
        end
        
        if data.scaleFix then
            tear.SpriteScale = data.scaleFix
            data.scaleFix = nil
        end
        
        if sprite:IsFinished("IpecacSpawn") then
            if data.IsAbsorbingDramamine then
                sprite:Play("RegularTear9")
            else
                sprite:Play("IpecacIdle")
            end
        end
        
        tear.FallingSpeed = 0
        tear.FallingAcceleration = -0.1
        tear.Height = -14
        
        if data.IsAbsorbingDramamine then
            local tears = Isaac.FindInRadius(tear.Position, 25, EntityPartition.TEAR)
            for _,absorbing_tear in ipairs(tears) do
                if absorbing_tear.SubType ~= REVEL.DramamineSubType and HasBit(absorbing_tear:ToTear().TearFlags, TearFlags.TEAR_ABSORB) then
                    absorbing_tear:Remove()
                    data.AbsorbedTears = data.AbsorbedTears + 1
                    if data.AbsorbedTears == 8 then
                        data.DramamineExplode(false)
                    else
                        sprite:Play("RegularTear" .. tostring(9 + math.ceil(data.AbsorbedTears/2)), true)
                    end
                end
            end
        end
        
        if tear:CollidesWithGrid() then
            data.DramamineExplode(false)
            return
        end
    end
end)

REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, tear, collider, low)
    if tear:GetData().IsDramamineTear then
        if collider and collider.Type == EntityType.ENTITY_BOMBDROP then
            return false
        end
        tear:GetData().DramamineExplode(true)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if eff:GetData().IsDramamineSplash then
        if eff:GetSprite():IsFinished("IpecacPop") then
            eff:Remove()
        end
    end
end, 6)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data = eff:GetData()
    if not data.DramamineInit then
        data.DramamineInit = true
        local tears = Isaac.FindInRadius(eff.Position, 100, EntityPartition.TEAR)
        for _,tear in ipairs(tears) do
            local t_data = tear:GetData()
            if t_data.IsDramamineTear then
                t_data.DramamineExplode(false)
            end
        end
    end
end, EffectVariant.BOMB_EXPLOSION)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_TEAR_POOF_INIT, 1, function(poof, data, spr, parent)
    if parent:GetSprite():GetFilename() == "gfx/effects/revelcommon/dramamine_ipecac.anm2"
    or parent:GetSprite():GetFilename() == "gfx/effects/revelcommon/dramamine_hungry_ipecac.anm2" then
        poof:Remove()
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, itemid, rng, player, useFlags, activeSlot, customVarData)
    -- remote detonator synergy
    if itemid == CollectibleType.COLLECTIBLE_REMOTE_DETONATOR then
        local tears = Isaac.FindByType(EntityType.ENTITY_TEAR, -1, -1, false, false)
        for _, tear in ipairs(tears) do
            local t_data = tear:GetData()
            if t_data.IsDramamineTear then
                t_data.DramamineExplode(false, tear.Parent:ToPlayer():GetBombFlags())
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if e.SubType == REVEL.ITEM.DRAMAMINE.id then
        if e:HasMortalDamage() then
            REVEL.SpawnDramamineTear(e.Player, e.Position)
        end
        e.OrbitDistance = Vector(120,120)
    end
end, FamiliarVariant.WISP)
       
end