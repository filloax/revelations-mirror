REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
 
local function FadeIn(ent, length)
    length = length or 4
    local color = ent.Color
    ent:SetColor(Color(color.R,color.G,color.B,0,color.RO,color.GO,color.BO),length,1,true,true)
end

local function IsReallyDead(npc)
    if npc then 
        if npc:ToNPC() ~= nil then
            npc = npc:ToNPC()
            return (npc:IsDead() or npc.State == 18 or (FiendFolio and (FiendFolio:isLeavingStatusCorpse(npc) or FiendFolio:isStatusCorpse(npc))))
        else
            return not npc:Exists()
        end
    end
    return true
end

local function StopSpinSound()
    REVEL.sfx:Stop(SoundEffect.SOUND_ULTRA_GREED_SPINNING)
    REVEL.SandstormLoopingSound = false
end

--Sandstorm
REVEL.SandstormEnts = {
    [REVEL.ENT.SANDBIP.id.." "..REVEL.ENT.SANDBIP.variant] = true,
    [REVEL.ENT.BLOATBIP.id.." "..REVEL.ENT.BLOATBIP.variant] = true,
    [REVEL.ENT.TRENCHBIP.id.." "..REVEL.ENT.TRENCHBIP.variant] = true,
    [REVEL.ENT.DEMOBIP.id.." "..REVEL.ENT.DEMOBIP.variant] = true,
    [REVEL.ENT.CANNONBIP.id.." "..REVEL.ENT.CANNONBIP.variant.." "..0] = true,
    [REVEL.ENT.SNIPEBIP.id.." "..REVEL.ENT.SNIPEBIP.variant] = true,
    [REVEL.ENT.SLAMBIP.id.." "..REVEL.ENT.SLAMBIP.variant] = true,
    [REVEL.ENT.SANDBOB.id.." "..REVEL.ENT.SANDBOB.variant] = true,
    [REVEL.ENT.SANDSHAPER.id.." "..REVEL.ENT.SANDSHAPER.variant] = true,
}

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDSTORM.variant then
        return
    end

    local target, data, sprite = npc:GetPlayerTarget(), npc:GetData(), npc:GetSprite()
    if not data.State then
        data.State = "Idle"
        npc.StateFrame = math.random(30,60)
        npc.SplatColor = REVEL.SandSplatColor
        data.MoveVec = RandomVector():Resized(1.5)
    end

    if data.State == "Idle" then
        npc.StateFrame = npc.StateFrame - 1
        if npc.StateFrame <= 0 then
            data.State = "Spin_Start"
            sprite.FlipX = (math.random(2) == 1)
        end

    elseif data.State == "Spin_Start" then
        if sprite:IsEventTriggered("Sound") then
            npc:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)
        elseif sprite:IsEventTriggered("Spin") then
            data.Spinning = true
        elseif sprite:IsFinished("Spin_Start") then
            data.State = "Spin_Loop"
            npc.StateFrame = math.random(250,300)
        end

    elseif data.State == "Spin_Loop" then
        npc.StateFrame = npc.StateFrame - 1
        if npc.StateFrame <= 0 then
            data.State = "Spin_End"
        end
    
    elseif data.State == "Spin_End" then
        if sprite:IsEventTriggered("Spin") then
            data.Spinning = false
            StopSpinSound()
        elseif sprite:IsFinished("Spin_End") then
            data.State = "Idle"
            npc.StateFrame = math.random(90,180)
        end
    end

    local sandrate = 2
    local sandvel = 4
    if data.Spinning then
        if not REVEL.sfx:IsPlaying(SoundEffect.SOUND_ULTRA_GREED_SPINNING) then
            REVEL.sfx:Play(SoundEffect.SOUND_ULTRA_GREED_SPINNING, 0.5, 0, true)
            REVEL.SandstormLoopingSound = true
        end

        for _, bip in pairs(Isaac.FindInRadius(npc.Position, 300, EntityPartition.ENEMY)) do
            if REVEL.SandstormEnts[bip.Type.." "..bip.Variant] or REVEL.SandstormEnts[bip.Type.." "..bip.Variant.." "..bip.SubType] then
                local bdata = bip:GetData()
                local vec = bip.Position - npc.Position
                local targvec = vec
                if sprite.FlipX then
                    targvec = vec:Rotated(-6)
                else
                    targvec = vec:Rotated(6)
                end
                local idealdist = 60
                if bip.Type == REVEL.ENT.DEMOBIP.id and bip.Variant == REVEL.ENT.DEMOBIP.variant then
                    idealdist = 100
                end
                targvec = targvec:Resized(math.max(targvec:Length()-6, idealdist))
                local targpos = npc.Position + targvec
                local bipvel = targpos - bip.Position
                bipvel = bipvel:Resized(math.min(bipvel:Length(), 7))
                bip.Velocity = REVEL.Lerp(bip.Velocity, bipvel, 0.5)
                bip:GetData().SandstormPulled = true
            end
        end

        if npc.FrameCount % 12 == 0 then
            local spawnpos = npc.Position + (RandomVector() * 60)
            local proj = REVEL.SpawnNPCProjectile(npc, Vector.Zero, spawnpos)
            proj.Scale = 0.5
            proj.Height = -6
            proj.FallingAccel = -0.12
            proj.Parent = npc
            proj:AddProjectileFlags(ProjectileFlags.NO_WALL_COLLIDE)
            proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            proj:GetData().SandProjectile = true
            proj:GetData().IsSandTear = true
            proj:GetData().projType = "Sandstorm"
            proj:GetData().SandstormSpeed = 0.5
            proj:GetData().SandstormSpeedTarget = math.random(2,6) * 0.5
            if sprite.FlipX then
                proj:GetData().SandstormRot = -1
            else
                proj:GetData().SandstormRot = 1
            end
            proj:GetData().SandstormRotTarget = math.random(4,8) * 0.5
            proj:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
            proj:GetSprite():LoadGraphics()
            proj:GetSprite():Play("RegularTear1", true)
            FadeIn(proj, 8)
            proj:Update()
            local sand = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, proj.Position, Vector(0,-2) + proj.Velocity, npc)
            sand.Color = Color(0,0,0,1,conv255ToFloat(60,40,20))
            sand.SpriteScale = Vector(0.8,0.8)
            FadeIn(sand, 3)
            sand:Update()
            sand:GetSprite():Play("Fade4", true)
            local whirl = Isaac.Spawn(1000, EffectVariant.WHIRLPOOL, 1, npc.Position, npc.Velocity, npc):ToEffect()
            whirl.Color = Color(0,0,0,1,conv255ToFloat(60,40,20))
            whirl:FollowParent(npc)
            whirl:GetSprite().FlipX = sprite.FlipX 
            whirl:Update()
        end

        sandrate = 1
        sandvel = 6
        npc.Velocity = REVEL.Lerp(npc.Velocity, (target.Position - npc.Position):Resized(1.5), 0.3)
    else
        sandrate = 2
        sandvel = 4
        if data.State == "Idle" then
            if npc.FrameCount % 20 == 0 then
                data.MoveVec = RandomVector():Resized(1.5)
            end
            npc.Velocity = REVEL.Lerp(npc.Velocity, data.MoveVec, 0.1)
        else
            npc.Velocity = npc.Velocity * 0.7
        end
    end

    if npc.FrameCount % sandrate == 0 then
        local sand = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, npc.Position, RandomVector() * sandvel, npc)
        sand.Color = Color(0,0,0,1,conv255ToFloat(60,40,20))
        sand.SpriteOffset = Vector(0,-20)
        sand:Update()
    end

    if not sprite:IsPlaying(data.State) then
        sprite:Play(data.State, true)
    end

end, REVEL.ENT.SANDSTORM.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDSTORM.variant then
        return
    end

    for i=1, math.random(5,8) do
        REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
    end
    StopSpinSound()
end, REVEL.ENT.SANDSTORM.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SANDSTORM.variant then
        return
    end

    StopSpinSound()
end, REVEL.ENT.SANDSTORM.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    local data = proj:GetData()
    local accel = 1.05
    if data.projType == "Sandstorm" then
        if proj.FrameCount > 150 or not (proj.Parent and proj.Parent:Exists() and proj.Parent:GetData().Spinning) then
            proj.Velocity = proj.Velocity * 0.95
            proj.FallingAccel = 0.04
        else
            local vec = proj.Position - proj.Parent.Position
            local targvec = vec
            if proj.Parent:GetSprite().FlipX then
                if data.SandstormRot > -data.SandstormRotTarget then
                    data.SandstormRot = -math.abs(data.SandstormRot * accel)
                end
                targvec = vec:Rotated(data.SandstormRot)
            else
                if data.SandstormRot < data.SandstormRotTarget then
                    data.SandstormRot = data.SandstormRot * accel
                end
                targvec = vec:Rotated(data.SandstormRot)
            end
            if data.SandstormSpeed < data.SandstormSpeedTarget then
                data.SandstormSpeed = data.SandstormSpeed * accel
            end
            targvec = targvec:Resized(targvec:Length()+data.SandstormSpeed)
            local targpos = proj.Parent.Position + targvec
            local projvel = targpos - proj.Position
            proj.Velocity = projvel:Resized(math.min(projvel:Length(), 8))

            if proj.FrameCount > 8 then
                proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            else
                proj.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            end
        end
    end
end)

end