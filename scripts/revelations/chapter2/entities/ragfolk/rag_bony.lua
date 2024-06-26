local ShrineTypes = require "scripts.revelations.common.enums.ShrineTypes"
return function()

-- Rag Bony

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
    local data = REVEL.GetData(npc)

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

    local data, sprite = REVEL.GetData(npc), npc:GetSprite()
    
    REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
    data.OnPathUpdate = REVEL.BonyPathUpdate

    if data.Buffed and not data.BuffedInit then
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony/rag_bony_body_buffed.png")
        sprite:LoadGraphics()
        data.BuffedInit = true
    end

    if not data.State then
        data.State = "Walk"
    end
    
    if data.Buffed then
        REVEL.EmitBuffedParticles(npc)
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
            local proData = REVEL.GetData(pro)
            proData.IsRagBone = true
            local proSprite = pro:GetSprite()
            proSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony/rag_bony_projectile.png")
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
            local proData = REVEL.GetData(pro)
            proData.IsRagBone = true
            local proSprite = pro:GetSprite()
            proSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony/rag_bony_projectile_homing.png")
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
        local data = REVEL.GetData(ent)
        if data.IsRagBone then
            for _, eff in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, -1, false, false)) do
                if eff.Position:Distance(ent.Position) < 5 and eff.FrameCount <= 1 then
                    local effSprite = eff:GetSprite()
                    effSprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/rag_bony/rag_bony_projectile_gibs.png")
                    effSprite:LoadGraphics()
                end
            end
        end
    end
end, EntityType.ENTITY_PROJECTILE)

end