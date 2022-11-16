local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Rag Bony

local Anm2GlowNull0

function REVEL.GenerateBonyPath(start, map, width, lastMovement, collisionMap) -- bonies prioritize moving in the same direction rather than changing
    width = width or REVEL.room:GetGridWidth()
    local checkIndices = {
        start + 1,
        start - 1,
        start + width,
        start - width
    }

    local path = {}
    local prevIndex = start
    local minimum
    while #checkIndices > 0 do
        local potentialNextIndices = {}
        for _, ind in ipairs(checkIndices) do
            if map[ind] and not REVEL.DoesMapIndexCollide(ind, collisionMap) then
                local potentialExtraScore = map[ind] * 500
                local score = map[ind] * 1000
                if lastMovement and (ind - prevIndex) ~= lastMovement then
                    score = score + potentialExtraScore
                end

                if (not minimum or score < minimum) then
                    minimum = score
                    potentialNextIndices = {ind}
                elseif score == minimum then
                    potentialNextIndices[#potentialNextIndices + 1] = ind
                end
            end
        end

        local nextIndex
        if #potentialNextIndices > 0 then
            nextIndex = potentialNextIndices[math.random(1, #potentialNextIndices)]
        end

        if nextIndex then
            path[#path + 1] = nextIndex
            lastMovement = nextIndex - prevIndex
            prevIndex = nextIndex
            if minimum < 1000 then
                return path, true
            end

            checkIndices = {
                nextIndex + 1,
                nextIndex - 1,
                nextIndex + width,
                nextIndex - width
            }
        else
            if #path > 0 then
                return path, false
            else
                return nil, false
            end
        end
    end
end

function REVEL.BonyPathUpdate(set, npc, map, lastMovement)
    local data = npc:GetData()

    local grindex = REVEL.room:GetGridIndex(npc.Position)
    if not lastMovement then
        if data.Path and data.PathIndex then
            lastMovement = data.Path[data.PathIndex] - grindex
        end
    end

    data.PathIndex = nil
    data.Path = REVEL.GenerateBonyPath(grindex, set.Map, nil, lastMovement, map)
end

local alignmentTrigger = 25

function REVEL.RoarOccasionally(npc, sound, time)
    if (npc.FrameCount + (npc.InitSeed % time)) % time == 0 then
        REVEL.sfx:NpcPlay(npc, sound, 1, 0, false, 1)
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.RAG_BONY.variant then
        return
    end

    npc.SplatColor = REVEL.PurpleRagSplatColor

    local data, sprite = npc:GetData(), npc:GetSprite()
    
    if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    end
    data.UsePlayerMap = true
    data.OnPathUpdate = REVEL.BonyPathUpdate

    if data.Buffed and not data.BuffedInit then
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony_body_buffed.png")
        sprite:LoadGraphics()
        data.BuffedInit = true
    end

    if not data.State then
        data.State = "Walk"
    end
    
    if data.Buffed then
        REVEL.EmitBuffedParticles(npc, Anm2GlowNull0)
    end

    if data.State == "Walk" then
        local target = npc:GetPlayerTarget()
        local facing, alignAmount = REVEL.GetAlignment(npc.Position, target.Position)
        if not (npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and target.Type == EntityType.ENTITY_PLAYER) and alignAmount < alignmentTrigger and target.Position:DistanceSquared(npc.Position) < 300 ^ 2 and REVEL.room:CheckLine(npc.Position, target.Position, 3, 0, false, false) and npc.FrameCount > 30 then
            if data.Buffed then
                data.State = "Shoot2"
                sprite:Play("AttackHomingStart", true)
            else
                data.State = "Shoot"
                data.Direction = facing
                sprite:Play("Attack" .. facing, true)
            end
        else
            if data.Path then
                if data.Buffed then
                    local speed = 0.85

                    REVEL.FollowPath(npc, speed, data.Path, false, 0.75)
                else
                    REVEL.FollowPath(npc, 0.75, data.Path, false, 0.75)
                end
            else
                npc.Velocity = npc.Velocity * 0.75
            end

            if data.Buffed then
                REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                    Left = "WalkLeft",
                    Right = "WalkRight2",
                    Up = "WalkUp",
                    Down = "WalkDown2"
                }, false, false, "WalkDown2")
            else
                REVEL.AnimateWalkFrame(sprite, npc.Velocity, {
                    Left = "WalkLeft",
                    Right = "WalkRight",
                    Up = "WalkUp",
                    Down = "WalkDown"
                }, false, false, "WalkDown")
            end
        end

        REVEL.RoarOccasionally(npc, SoundEffect.SOUND_MONSTER_ROAR_1, 100)
    elseif data.State == "Shoot" then
        npc.Velocity = npc.Velocity * 0.75

        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
            local target = npc:GetPlayerTarget()
            local pro = REVEL.SpawnNPCProjectile(npc, (target.Position - npc.Position):Resized(10), nil, ProjectileVariant.PROJECTILE_BONE)
            local proData = pro:GetData()
            proData.IsRagBone = true
            local proSprite = pro:GetSprite()
            proSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony_projectile.png")
            proSprite:LoadGraphics()
            pro.FallingSpeed = -2
            pro:Update()
        end

        if sprite:IsFinished("Attack" .. data.Direction) then
            data.State = "Walk"
        end
    elseif data.State == "Shoot2" then
        npc.Velocity = npc.Velocity * 0.75
        local target = npc:GetPlayerTarget()
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
            local pro = REVEL.SpawnNPCProjectile(npc, (target.Position - npc.Position):Resized(10), nil, ProjectileVariant.PROJECTILE_BONE)
            local proData = pro:GetData()
            proData.IsRagBone = true
            local proSprite = pro:GetSprite()
            proSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony_projectile_homing.png")
            proSprite:LoadGraphics()
            pro.FallingSpeed = -2
            pro.FallingAccel = -0.085
            pro:Update()
            data.Bone = pro
        end

        if data.Bone then
            if not data.Bone:Exists() or data.Bone:IsDead() then
                sprite:Play("AttackHomingStop", true)
                data.Bone = nil
            else
                if npc:HasEntityFlags(EntityFlag.FLAG_CHARM) or npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                    data.Bone.ProjectileFlags = BitOr(ProjectileFlags.CANT_HIT_PLAYER, ProjectileFlags.HIT_ENEMIES)
                else
                    data.Bone.ProjectileFlags = 0
                end

                local proSpeed = 1.1
                data.Bone.Velocity = data.Bone.Velocity * 0.9 + (target.Position - data.Bone.Position):Resized(proSpeed)
            end
        end

        if sprite:IsFinished("AttackHomingStart") then
            sprite:Play("AttackHomingLoop", true)
        end

        if sprite:IsFinished("AttackHomingStop") then
            data.State = "Walk"
        end
    end

    if npc:IsDead() and (not data.Buffed or (REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and math.random(1, 5) == 1)) and not data.NoRags then
        REVEL.SpawnRevivalRag(npc)
    end

    if npc:IsDead() then
        REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_BONE)
    end
end, REVEL.ENT.RAG_BONY.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Variant == ProjectileVariant.PROJECTILE_BONE then
        local data = ent:GetData()
        if data.IsRagBone then
            for _, eff in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, -1, false, false)) do
                if eff.Position:Distance(ent.Position) < 5 and eff.FrameCount <= 1 then
                    local effSprite = eff:GetSprite()
                    effSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony_projectile_gibs.png")
                    effSprite:LoadGraphics()
                end
            end
        end
    end
end, EntityType.ENTITY_PROJECTILE)

Anm2GlowNull0 = {
    WalkDown2 = {
        Offset = {Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17), Vector(-6, -17)},
        Scale = {Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    WalkRight2 = {
        Offset = {Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17), Vector(5, -17)},
        Scale = {Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    AttackHomingStart = {
        Offset = {Vector(-6, -18), Vector(-5, -22), Vector(-4, -25), Vector(-6, -20), Vector(-8, -15), Vector(-7, -18), Vector(-6, -21), Vector(-6, -20), Vector(-7, -19), Vector(-6, -20), Vector(-6, -20), Vector(-6, -20), Vector(-6, -20), Vector(-6, -19), Vector(-6, -18), Vector(-6, -18), Vector(-7, -17), Vector(-6, -19), Vector(-6, -20), Vector(-5, -22), Vector(-5, -20), Vector(-5, -18), Vector(-9, -11), Vector(-8, -12), Vector(-7, -13), Vector(-7, -13), Vector(-7, -13), Vector(-7, -13)},
        Scale = {Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(28, 28), Vector(30, 30), Vector(40, 40), Vector(50, 50), Vector(42, 42), Vector(35, 35), Vector(30, 30), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    AttackHomingLoop = {
        Offset = {Vector(-6, -14), Vector(-6, -14), Vector(-6, -14), Vector(-6, -13), Vector(-6, -13), Vector(-6, -13), Vector(-6, -14), Vector(-6, -14), Vector(-6, -14), Vector(-6, -14), Vector(-6, -14), Vector(-6, -13), Vector(-6, -13), Vector(-6, -13), Vector(-6, -14), Vector(-6, -14), Vector(-6, -14), Vector(-6, -14)},
        Scale = {Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
    AttackHomingStop = {
        Offset = {Vector(-7, -13), Vector(-7, -12), Vector(-7, -12), Vector(-6, -16), Vector(-6, -19), Vector(-6, -17), Vector(-7, -15), Vector(-7, -16), Vector(-6, -17), Vector(-6, -18), Vector(-6, -18), Vector(-6, -17), Vector(-6, -17)},
        Scale = {Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25), Vector(25, 25)},
        Alpha = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255},
        Visible = {true, true, true, true, true, true, true, true, true, true, true, true, true}
    },
}

end