return function()

------------------
-- PYRAMID HEAD --
------------------

local pyramidParams = ProjectileParams()
pyramidParams.Variant = ProjectileVariant.PROJECTILE_TEAR
pyramidParams.BulletFlags = ProjectileFlags.NO_WALL_COLLIDE

local function pyramidHead_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.PYRAMID_HEAD.variant then
        local data, sprite, player, pf = REVEL.GetData(npc), npc:GetSprite(), npc:GetPlayerTarget(), npc.Pathfinder

        -- Initialize
        if data.Init == nil then
            npc.SplatColor = Color(0.5,0.5,0.5,1,conv255ToFloat(0,0,0))

            data.bubble = Sprite()
            data.bubble:Load("gfx/monsters/revel2/pyramid_head/pyramid_head_shield.anm2", true)
            data.bubble:Play("Shine", true)
            data.bubble.Offset = Vector(0, -9) * npc.SpriteScale.Y
            data.bubble.Scale = (Vector.One * npc.SpriteScale) * 0.75
            sprite:Play("Rise",true)

            data.Init = true
        end

        data.shouldUpdateBubble = true

        if data.State ~= "Rise" and data.State ~= "Walk" and data.State ~= "Attack01" and data.State ~= "ShieldGone" and data.State ~= "AttackTell" then
            data.Shielded = false
            data.Appeared = true
        end

        -- Sprite finish events
        if sprite:IsFinished("Rise") or sprite:IsFinished("Attack01") then
            if sprite:IsFinished("Rise") then
                data.Shielded = true
                data.Appeared = true
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BISHOP_HIT, 1, 0, false, 1)
                npc:SetColor(Color(1,1,1,1,conv255ToFloat(123,43,127)), 10, 1, true, false)
            end
            data.AttackTimer = math.random(90, 150)
            data.AttackFrames = 0
            data.State = "Walk"
        elseif sprite:IsFinished("ShieldGone") or sprite:IsFinished("Shoot") then
            if sprite:IsFinished("ShieldGone") then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.PYRAMIDHEAD_CRY, 1, 0, false, 1)
                data.CryTimer = math.random(120, 240)
                data.CryFrames = 0
            end
            data.ShootTimer = math.random(45, 70)
            data.ShootFrames = 0
            data.State = "Walk2"
        elseif sprite:IsFinished("AttackTell") then
            data.State = "Attack01"
        end

        if data.State ~= "Walk" and data.State ~= "Walk2" and data.State ~= "Shoot" then
            npc.Velocity = npc.Velocity * 0.95
        end

        -- AI states
        if data.State == "Walk" then
            npc.Velocity = npc.Velocity * 0.95 + (player.Position - npc.Position):Resized(0.05)

            data.AttackFrames = data.AttackFrames + 1
            if data.AttackFrames >= data.AttackTimer then
                npc.Velocity = Vector.Zero
                data.State = "AttackTell"
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BOO_MAD, 1, 0, false, 1.1)
            end
        elseif data.State == "Walk2" or data.State == "Shoot" then
            pf:EvadeTarget(player.Position)
            npc.Velocity = npc.Velocity * 1.05

            data.CryFrames = data.CryFrames + 1
            if data.CryFrames >= data.CryTimer then
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.PYRAMIDHEAD_CRY, 1, 0, false, 1)
                data.CryTimer = math.random(120, 240)
                data.CryFrames = 0
            end

            data.ShootFrames = data.ShootFrames + 1
            if data.ShootFrames >= data.ShootTimer then
                data.State = "Shoot"
            end
        end

            -- Animation handler + check alive enemies
        if data.State ~= nil then
            if not sprite:IsPlaying(data.State) then
                sprite:Play(data.State, true)
            end

            if data.Shielded == true then
                local stayShielded
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if (enemy.Type ~= REVEL.ENT.PYRAMID_HEAD.id or enemy.Variant ~= REVEL.ENT.PYRAMID_HEAD.variant) and enemy.CanShutDoors then
                        stayShielded = true
                        break
                    end
                end

                if not stayShielded then
                    npc.Velocity = Vector(0, 0)
                    data.Shielded = false
                    data.State = "ShieldGone"
                    for k, v in pairs(REVEL.roomEnemies) do
                        if REVEL.GetData(v).Mark ~= nil then
                            REVEL.GetData(v).Mark:Remove()
                            REVEL.GetData(v).Mark = nil
                        end
                    end
                end
            end
        end

        -- Event triggers
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0, false, 1)
            npc:FireProjectiles(npc.Position, (player.Position - npc.Position):Resized(9), 2, pyramidParams)
        elseif sprite:IsEventTriggered("Attack") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GHOST_SHOOT, 1, 0, false, 1.1)
            for k, v in pairs(REVEL.roomEnemies) do
                if REVEL.GetData(v).Mark ~= nil then
                local p = Isaac.Spawn(9, 0, 0, v.Position, (player.Position - v.Position):Resized(9), npc):ToProjectile()
                p.FallingSpeed = -2
                p:AddProjectileFlags(ProjectileFlags.SMART)
                p.HomingStrength = 0.7
                p.Scale = 1.5
                v:SetColor(Color(1,1,1,1,conv255ToFloat(123,43,127)), 20, 1, true, false)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
                end
            end
            npc:SetColor(Color(1,1,1,1,conv255ToFloat(123,43,127)), 20, 1, true, false)
        end

        -- Add triangle sprite on vulnerable enemies
        if data.Shielded == true then
            for k, v in pairs(REVEL.roomEnemies) do
                if v:IsVulnerableEnemy() and not v:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) 
                and not v:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and v.Type ~= REVEL.ENT.PYRAMID_HEAD.id 
                and REVEL.GetData(v).Mark == nil then
                REVEL.GetData(v).Mark = Isaac.Spawn(1000, REVEL.ENT.PYRAMID_HEAD_TRIANGLE.variant, 0, v.Position - Vector(0, ( v.Size * 5 )), Vector (0, 0), nil)
                REVEL.GetData(v).Mark:ToEffect():FollowParent(v)
                end
            end
        end

    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, pyramidHead_NpcUpdate, REVEL.ENT.PYRAMID_HEAD.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    if npc.Variant ~= REVEL.ENT.PYRAMID_HEAD.variant then
        return
    end

    local data = REVEL.GetData(npc)
    if data.Shielded and data.bubble then
        if data.shouldUpdateBubble and REVEL.IsRenderPassNormal() then
            data.shouldUpdateBubble = nil
            data.bubble:Update()
        end

        data.bubble:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end, REVEL.ENT.PYRAMID_HEAD.id)

local function pyramidHeadDamage_EntityTakeDmg(_, ent, dmg, flag, source)
    if ent.Variant == REVEL.ENT.PYRAMID_HEAD.variant then
        if REVEL.GetData(ent).Shielded == true or not REVEL.GetData(ent).Appeared then
            return false
        end
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, pyramidHeadDamage_EntityTakeDmg, REVEL.ENT.PYRAMID_HEAD.id)

local function pyramidHead_Triangle_PostEffectUpdate(_, eff)
    if not eff.Parent or not eff.Parent:Exists() then
        eff:Remove()
    end
end
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, pyramidHead_Triangle_PostEffectUpdate, REVEL.ENT.PYRAMID_HEAD_TRIANGLE.variant)

end