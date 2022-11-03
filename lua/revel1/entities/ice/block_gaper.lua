local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------------
-- BLOCKHEAD GAPER --
---------------------

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
    if npc.Variant == REVEL.ENT.BLOCKHEAD.variant or npc.Variant == REVEL.ENT.CARDINAL_BLOCKHEAD.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.SplatColor = REVEL.WaterSplatColor
    elseif npc.Variant == REVEL.ENT.YELLOW_BLOCKHEAD.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.SplatColor = REVEL.YellowSplatColor
        local sprite = npc:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/blockhead_gaper_yellow_2.png")
        sprite:LoadGraphics()
    elseif npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc.SplatColor = REVEL.YellowSplatColor
        local sprite = npc:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/blockhead_gaper_yellow.png")
        sprite:LoadGraphics()
    end
end, REVEL.ENT.BLOCKHEAD.id)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.BLOCKHEAD.variant
    or npc.Variant == REVEL.ENT.CARDINAL_BLOCKHEAD.variant
    or npc.Variant == REVEL.ENT.YELLOW_BLOCKHEAD.variant
    or npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant then
        local isCardinal = npc.Variant == REVEL.ENT.CARDINAL_BLOCKHEAD.variant or npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant
        local isYellow = npc.Variant == REVEL.ENT.YELLOW_BLOCKHEAD.variant or npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant
        local iceVariant = REVEL.IceGibType.DEFAULT
        if isYellow then
            iceVariant = REVEL.IceGibType.YELLOW
        end

        local player = npc:GetPlayerTarget()
        local sprite, data = npc:GetSprite(), npc:GetData()
        npc.StateFrame = npc.StateFrame + 1
        npc.Velocity = npc.Velocity:Resized(15 * npc.Friction)

        local doBreak = false

        if npc.FrameCount >= 7 then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            for i,e in ipairs(REVEL.roomEnemies) do
                if e.HitPoints > 0 and e.Type ~= REVEL.ENT.BLOCKHEAD.id and e.Position:Distance(npc.Position) <= 30 then
                    if isYellow and REVEL.ENT.FLURRY_HEAD and (e.Type == REVEL.ENT.FLURRY_HEAD.id or e.Type == REVEL.ENT.FLURRY_BODY.id or e.Type == REVEL.ENT.FLURRY_FROZEN_BODY.id) then --additional check in case flurry is later removed
                        data.Shatter = true
                        e:TakeDamage(e.MaxHitPoints / 30, 0, EntityRef(npc), 0)
                        doBreak = true
                        break
                    elseif not e:IsBoss() then
                        e:TakeDamage(999, 0, EntityRef(npc), 0)
                    end
                end
            end
        end

        if npc.StateFrame >= 3 and npc.Velocity:Length() > 0.1 then
            if isYellow then
                REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
            else
                REVEL.SpawnIceCreep(npc.Position, npc)
            end
            npc.StateFrame = 0
        end

        if doBreak or npc:IsDead() or npc:HasMortalDamage() or npc:CollidesWithGrid() or (player and player.Position:DistanceSquared(npc.Position) <= 19*19) then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            for i=1, 6 do
                REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), npc, iceVariant)
            end

            local angleOffset = isCardinal and 0 or 45
            for angle = 0, 270, 90 do
                local proj = Isaac.Spawn(9, 4, 0, npc.Position, Vector.FromAngle(angle + angleOffset):Resized(12), npc)
                if isYellow then
                    proj:GetSprite().Color = REVEL.PissColor
                end
            end

            local enemy = npc:ToNPC()
            if enemy then
                enemy:Morph(EntityType.ENTITY_HORF, 0, 0, -1)
                enemy.HitPoints = enemy.MaxHitPoints
                REVEL.ForceReplacement(enemy, "Glacier")
                enemy.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                enemy:GetData().FromBlockGaper = true
            end
        end
    end
end, REVEL.ENT.BLOCKHEAD.id)

-- prevent horf insta shooting
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if npc:GetData().FromBlockGaper and npc.FrameCount <= 30 then
        local sprite = npc:GetSprite()
        if sprite:IsPlaying("Attack") then
            sprite:Play("Shake", true)
        end
    end
end, EntityType.ENTITY_HORF)

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
    if npc.Variant == REVEL.ENT.BLOCK_GAPER.variant or npc.Variant == REVEL.ENT.CARDINAL_BLOCK_GAPER.variant then
        npc.SplatColor = REVEL.WaterSplatColor
    elseif npc.Variant == REVEL.ENT.YELLOW_BLOCK_GAPER.variant then
        npc.SplatColor = REVEL.WaterSplatColor
        local sprite = npc:GetSprite()
        sprite:ReplaceSpritesheet(1, "gfx/monsters/revel1/blockhead_gaper_yellow_2.png")
        sprite:LoadGraphics()
    elseif npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant then
        npc.SplatColor = REVEL.WaterSplatColor
        local sprite = npc:GetSprite()
        sprite:ReplaceSpritesheet(1, "gfx/monsters/revel1/blockhead_gaper_yellow.png")
        sprite:LoadGraphics()
    end

    if npc.Variant == REVEL.ENT.BLOCK_BLOCK_BLOCK_GAPER.variant then
        local sprite, data = npc:GetSprite(), npc:GetData()
        npc.SplatColor = REVEL.WaterSplatColor
        if not data.init then
            data.headStack = {}
            local stack = 2 + npc.SubType
            for i=1, stack do
                local ySnow = (math.random(1,5) == 1)
                local rType = (math.random(1,2) == 1)

                local variant
                if rType then
                    variant = REVEL.ENT.BLOCK_GAPER.variant
                    if ySnow then variant = REVEL.ENT.YELLOW_BLOCK_GAPER.variant end
                else
                    variant = REVEL.ENT.CARDINAL_BLOCK_GAPER.variant
                    if ySnow then variant = REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant end
                end
                table.insert(data.headStack,variant)
            end

            data.init = true
        end
    end
end, REVEL.ENT.BLOCK_GAPER.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if REVEL.ENT.BLOCK_BLOCK_BLOCK_GAPER:isEnt(npc) and REVEL.IsRenderPassNormal() then
        local data, sprite = npc:GetData(), npc:GetSprite()
        if data.headStack then
            if not data.headSprites then
                data.headSprites = {}
                for i=1, #data.headStack do
                    local headSprite = Sprite()
                    headSprite:Load("gfx/monsters/revel1/blockblockblockhead_gaper.anm2", true)
                    local anim = "Block_Head"
                    if data.headStack[i] == REVEL.ENT.BLOCK_GAPER.variant then
                        anim = "Block_Head2"
                    elseif data.headStack[i] == REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant then
                        anim = "Block_Head3"
                    elseif data.headStack[i] == REVEL.ENT.YELLOW_BLOCK_GAPER.variant then
                        anim = "Block_Head4"
                    end
                    headSprite:Play(anim,true)
                    data.headSprites[i] = headSprite
                end
            else
                for i=0, #data.headStack-1 do
                    local pos = npc.Position-Vector(0,32*i)
                    data.headSprites[i+1]:Render(Isaac.WorldToRenderPosition(pos) + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                end
            end
        end
    end
end, REVEL.ENT.BLOCK_GAPER.id)

function REVEL.BeheadIceBlockGaper(npc, persist, forceVariant)
    local variant = forceVariant or npc.Variant
    local isYellow = variant == REVEL.ENT.YELLOW_BLOCK_GAPER.variant or variant == REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant
    local iceVariant = REVEL.IceGibType.DEFAULT
    if isYellow then
        iceVariant = REVEL.IceGibType.YELLOW
    end

    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_GOOATTACH0, 1, 0, false, 1)
    if not npc:GetData().BeheadNoSpawn then
        local player = npc:GetPlayerTarget()
        local targPos = player and player.Position or Isaac.GetRandomPosition()

        if variant == REVEL.ENT.BLOCK_GAPER.variant or variant == REVEL.ENT.YELLOW_BLOCK_GAPER.variant then
            local spawnVariant = REVEL.ENT.BLOCKHEAD.variant
            if isYellow then
                spawnVariant = REVEL.ENT.YELLOW_BLOCKHEAD.variant
            end

            local block = Isaac.Spawn(REVEL.ENT.BLOCKHEAD.id, spawnVariant, 0, npc.Position, (npc.Position - targPos):Resized(15), npc)
            block.SpawnerEntity = npc
            block.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        elseif variant == REVEL.ENT.CARDINAL_BLOCK_GAPER.variant or variant == REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant then
            local spawnVariant = REVEL.ENT.CARDINAL_BLOCKHEAD.variant
            if isYellow then
                spawnVariant = REVEL.ENT.YELLOW_CARDINAL_BLOCKHEAD.variant
            end

            local angle = (targPos - npc.Position):GetAngleDegrees()
            local block
            if angle <= 45 and angle >= -45 then -- Right
                block = Isaac.Spawn(REVEL.ENT.BLOCKHEAD.id, spawnVariant, 0, npc.Position, Vector.FromAngle(180) * 15, npc)
            elseif angle <= 135 and angle >= 45 then -- Down
                block = Isaac.Spawn(REVEL.ENT.BLOCKHEAD.id, spawnVariant, 0, npc.Position, Vector.FromAngle(270) * 15, npc)
            elseif angle <= -135 or angle >= 135 then -- Left
                block = Isaac.Spawn(REVEL.ENT.BLOCKHEAD.id, spawnVariant, 0, npc.Position, Vector.FromAngle(360) * 15, npc)
            elseif angle <= -45 and angle >= -135 then -- Up
                block = Isaac.Spawn(REVEL.ENT.BLOCKHEAD.id, spawnVariant, 0, npc.Position, Vector.FromAngle(90) * 15, npc)
            end

            if block then
                block.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                block.SpawnerEntity = npc
            end
        end
    end

    if not persist then
        npc:Die()

        REVEL.DelayFunction(1, function() 
            for _, gusher in ipairs(Isaac.FindByType(EntityType.ENTITY_GUSHER)) do
                REVEL.ForceReplacement(gusher, "Glacier")
            end
        end, nil, true)
    end
end 

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(npc, dmg)
    if not (
           npc.Variant == REVEL.ENT.BLOCK_GAPER.variant
        or npc.Variant == REVEL.ENT.CARDINAL_BLOCK_GAPER.variant
        or npc.Variant == REVEL.ENT.YELLOW_BLOCK_GAPER.variant
        or npc.Variant == REVEL.ENT.YELLOW_CARDINAL_BLOCK_GAPER.variant
        --or npc.Variant == REVEL.ENT.BLOCK_BLOCK_BLOCK_GAPER.variant
    )
    or npc.HitPoints - dmg - REVEL.GetDamageBuffer(npc) > 0 then return end --only mortal damage

    npc = npc:ToNPC()

    REVEL.BeheadIceBlockGaper(npc)
    npc.HitPoints = dmg + REVEL.GetDamageBuffer(npc)
end, REVEL.ENT.BLOCK_GAPER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, dmg, flag, src)
    if not npc.Variant == REVEL.ENT.BLOCK_BLOCK_BLOCK_GAPER.variant
    or npc.HitPoints - dmg - REVEL.GetDamageBuffer(npc) > 0 then return end

    npc = npc:ToNPC()
    local data = npc:GetData()

    if data.headStack and #data.headStack > 0 then
        local variant = data.headStack[1]
        table.remove(data.headStack,1)
        if data.headSprites[1] then table.remove(data.headSprites,1) end
        if #data.headStack > 0 then
            npc.HitPoints = npc.MaxHitPoints
            REVEL.BeheadIceBlockGaper(npc, true, variant)
            npc:BloodExplode()
            return false
        else
            REVEL.BeheadIceBlockGaper(npc, false, variant)
        end
    end

end, REVEL.ENT.BLOCK_GAPER.id)

end

REVEL.PcallWorkaroundBreakFunction()