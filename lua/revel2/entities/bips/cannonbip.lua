local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Cannonbip
local function destroyBipProjectile(entity)
    for i=1, math.random(6, 10) do
        local p = Isaac.Spawn(9, 0, 0, entity.Position, Vector.FromAngle(math.random(0, 360)) * (math.random(180, 240) * 0.01), entity):ToProjectile()
        p.Scale = -0.1
        p.FallingSpeed = math.random(1500, 2500) * -0.01
        p.FallingAccel = 1.5

        local pSprite = p:GetSprite()
        pSprite:ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
        pSprite:LoadGraphics()

        local pData = p:GetData()
        pData.IsSandTear = true
    end

    for i=1, math.random(2,3) do
        REVEL.SpawnSandGibs(entity.Position, RandomVector() * 2, entity)
    end

    local poof = Isaac.Spawn(1000, EffectVariant.POOF02, 1, entity.Position, Vector.Zero, entity)
    poof.SpriteScale = Vector.One * 0.6
    poof.Color = Color(0.8,0.8,0.65,1)

    REVEL.sfx:Play(SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1.8)
    local bip = REVEL.ENT.DEMOBIP:spawn(entity.Position, Vector.Zero, entity)
    bip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

    entity:Remove()
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.CANNONBIP.variant then
        return
    end

    local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

    if npc.SubType ~= 10 then
        if not data.SandstormPulled then
            npc.Velocity = Vector.Zero
        end

        if not data.Init then
            npc.SplatColor = REVEL.SandSplatColor
            sprite:Play("Idle", true)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            data.State = "Idle"
            data.ShootTimer = math.random(60, 90)
            data.Init = true
        end

        if data.State == "Idle" then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            if not data.ShootTimer then
                data.ShootTimer = 60
            end

            data.ShootTimer = data.ShootTimer - 1

            if data.ShootTimer <= 0 then
                sprite:Play("Shoot", true)
                data.State = "Shooting"
            end
        elseif data.State == "Shooting" then
            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.CANNON_BLAST, 1.5, 0, false, 1)
                local pbip = REVEL.ENT.CANNONBIP_PROJECTILE:spawn(npc.Position, Vector.Zero, npc)

                local pbipData = pbip:GetData()
                pbip:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                pbip:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
                pbip.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
                pbip.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                REVEL.ZPos.SetData(pbip, {
                    ZVelocity = 10,
                    ZPosition = 10,
                    Gravity = 0.25,
                    TerminalVelocity = 0,
                    Bounce = 0,
                    DoRotation = true,
                    RotationOffset = 9,
                    DisableCollision = true,
                    CollisionOffset = 40,
                    BounceFromGrid = false,
                    LandFromGrid = true,
                    PoofInPits = true,
                    DisableAI = false
                })
                pbipData.Init = true

                local pbipSprite = pbip:GetSprite()
                pbipSprite:Play("InAir", true)

                pbipData.Origin = npc.Position
                pbipData.Target = player.Position + RandomVector() * math.random(0, 39)
            end
            if sprite:IsFinished("Shoot") then
                sprite:Play("Idle2", true)
                data.State = "ReloadIdle"
                data.ReloadTimer = 60
            end
        elseif data.State == "ReloadIdle" then
            if not sprite:IsPlaying("Idle2") then
                sprite:Play("Idle2", true)
            end

            if not data.ReloadTimer then
                data.ReloadTimer = 60
            end

            data.ReloadTimer = data.ReloadTimer - 1

            if data.ReloadTimer <= 0 then
                sprite:Play("Reload", true)
                data.State = "Reloading"
                data.ReloadTimer = nil
            end
        elseif data.State == "Reloading" then
            --if sprite:IsEventTriggered("Reload") then
                --nothing yet, will probably be used to play a sound
            --end
            if sprite:IsFinished("Reload") then
                sprite:Play("Idle", true)
                data.State = "Idle"
                data.ShootTimer = math.random(60, 90)
            end
        end
    else --projectile
        if not data.Init then
            npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
            REVEL.ZPos.SetData(npc, {
                Gravity = 0.25,
                TerminalVelocity = 0,
                Bounce = 0,
                DoRotation = true,
                RotationOffset = 9,
                DisableCollision = true,
                CollisionOffset = 40,
                BounceFromGrid = false,
                LandFromGrid = true,
                PoofInPits = true,
                DisableAI = false
            })
            data.Init = true
        end
        if not sprite:IsPlaying("InAir") then
            sprite:Play("InAir", true)
        end

        if data.Origin and data.Target then
            if not REVEL.LerpEntityPosition(npc, data.Origin, data.Target, 40) then
                data.Origin = nil
                data.Target = nil
            end
        end
    end
    data.SandstormPulled = false
end, REVEL.ENT.CANNONBIP.id)

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, entity, airMovementData, fromPit)
    if not REVEL.ENT.CANNONBIP_PROJECTILE:isEnt(entity, true) and not (fromPit and fromPit.CollisionClass == GridCollisionClass.COLLISION_PIT) then
        return
    end

    destroyBipProjectile(entity)
end, REVEL.ENT.CANNONBIP.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source)
    if source and REVEL.ENT.CANNONBIP:isEnt(source) then
        for i, pbip in ipairs(Isaac.FindByType(REVEL.ENT.CANNONBIP.id, REVEL.ENT.CANNONBIP.variant, -1, false, false)) do
            if GetPtrHash(source.Entity) == GetPtrHash(pbip) then
                if pbip.SubType == 10 then
                    destroyBipProjectile(pbip)
                end
            end
        end
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if npc.Variant == REVEL.ENT.CANNONBIP.variant then
        for i=1, math.random(3,4) do
            REVEL.SpawnSandGibs(npc.Position, RandomVector() * 2, npc)
        end
    end
end, REVEL.ENT.CANNONBIP.id)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, function(p, data, spr, spawner, grandpa)
    if spawner.Variant == ProjectileVariant.PROJECTILE_NORMAL and spawner:GetData().IsSandTear then
        REVEL.sfx:Play(REVEL.SFX.SAND_PROJ_IMPACT, 1, 0, false, 1)
        spr:ReplaceSpritesheet(0, "gfx/effects/revel2/sand_bulletatlas.png")
        spr:LoadGraphics()
    end
end)

end