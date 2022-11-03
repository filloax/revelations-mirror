local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

if FiendFolio then

-- Tomb Ragurge

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= FiendFolio.FF.Ragurge.Var then return end
    if not REVEL.STAGE.Tomb:IsStage() then return end

    local data = npc:GetData()
    local sprite = npc:GetSprite()
    local target = npc:GetPlayerTarget()

    data.redsTotal = data.redsTotal or 0
    data.redsTotal = math.max(data.redsTotal,#data.reds)

    if data.Buffed and not data.BuffedInit then
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/reskins/ff/monster_ragurgebody_tomb_buffed.png")
        sprite:ReplaceSpritesheet(1, "gfx/monsters/revel2/reskins/ff/monster_ragurgehead_tomb_buffed.png")
        sprite:LoadGraphics()
        data.BuffedInit = true

    elseif data.Buffed then
        if sprite:IsOverlayPlaying("SuckEnd") then
            sprite:PlayOverlay("SuckSpit")
        elseif sprite:IsOverlayPlaying("SuckSpit") then
            npc.FlipX = target.Position.X < npc.Position.X
            if sprite:GetOverlayFrame() == 28 then
                REVEL.sfx:Play(SoundEffect.SOUND_HEARTOUT)
                REVEL.sfx:Play(REVEL.SFX.FLASH_BOSS_GURGLE)

                for i = 1, math.min(data.redsTotal,10)  do
                    local projectile = npc:FireBossProjectiles(1, target.Position, 0, ProjectileParams())
                    local velocityLength = projectile.Velocity:Length()
                    projectile.Velocity = Vector.FromAngle((target.Position - projectile.Position):GetAngleDegrees() + math.random(-30, 30)) * velocityLength

                    if math.random(1,2) == 1 then
                        projectile:GetData().DriftyDeaccel = math.random(90,99) * 0.01
                        projectile.FallingSpeed = math.random(150,250) * -0.1
                    end
                end

                npc.Velocity = npc.Velocity * 0.9 + (npc.Position-target.Position):Resized(6)
                local p = Isaac.Spawn(9, 0, 0, npc.Position, (target.Position - npc.Position):Resized(12), npc):ToProjectile()
                p.FallingSpeed = -2
                p.FallingAccel = -0.03
                p.Scale = 3
                p:AddProjectileFlags(BitOr(ProjectileFlags.SMART,ProjectileFlags.NO_WALL_COLLIDE))
                data.RagurgeHomingProjectile = p
                p:Update()
            end
        end

        if sprite:IsOverlayFinished("SuckSpit") then
            sprite:PlayOverlay("Head")
            data.redsTotal = 0
        end

        if data.RagurgeHomingProjectile then
            if data.RagurgeHomingProjectile:Exists() and not data.RagurgeHomingProjectile:IsDead() then
                data.RagurgeHomingProjectile.Velocity = data.RagurgeHomingProjectile.Velocity * 0.9 + (target.Position - data.RagurgeHomingProjectile.Position):Resized(0.5)
            else
                data.RagurgeHomingProjectile = nil
            end
        end
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) and not data.SpawnedRag then
        REVEL.SpawnRevivalRag(npc)
        data.SpawnedRag = true
    end

end, FiendFolio.FF.Ragurge.ID)

end

end

REVEL.PcallWorkaroundBreakFunction()