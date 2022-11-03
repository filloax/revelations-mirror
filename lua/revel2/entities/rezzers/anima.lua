local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------
-- ANIMA --
-----------

local radSpeed = math.pi/48
local speedSlow = 5.5
local speed = 6.5
local dieableStates = {"Move Default", "GoTo Skull"}

local function skullUpdate(ent)
    local spr = ent:GetSprite()

    if spr:IsFinished("DropSkull") then
        spr:Play("SkullIdle", true)
    end

    if IsAnimOn(spr, "SkullIdle") then
        local booms = Isaac.FindByType(1000, EffectVariant.BOMB_EXPLOSION, -1, true)
        for i,v in ipairs(booms) do
            if v.Position:Distance(ent.Position) < 10 + v:ToEffect().Scale*36 then
                REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.3, 0, false, 1)
                REVEL.SpawnSandGibs(ent.Position)
                ent:Remove()
                break
            end
        end
    end
end

local function skullFinish(ent)
    REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.3, 0, false, 1)
    REVEL.SpawnSandGibs(ent.Position)
    local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, ent.Position, Vector.Zero, nil)
    poof.SpriteScale = Vector.One * 0.6
end

local function isUnbuffedRagFamily(ent)
    return REVEL.RAG_FAMILY[ent.Type] and not ent:GetData().Buffed
end

local function anima_NpcUpdate(_, npc)
    if npc.Variant ~= REVEL.ENT.ANIMA.variant then return end
    local data, spr = npc:GetData(), npc:GetSprite()

    local ragNpcs

    if not data.Init then
        if data.ForcePossess then
            data.State = "Possess"
            spr:Play("Possess", true)
        else
            data.State = "Spawn"
        end
        data.angle = math.pi/2
        data.FrameCount = 0
        data.prevState = "Spawn"

        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

        data.Init = true
    end

    if data.State == "Spawn" then
        if spr:IsFinished("Appear") then
            spr:Play("Move", true)
            data.State = "Move Default"
        end
    elseif data.State == "Move Default" then
        if spr:IsFinished("PickupSkull") then
            spr:Play("Move", true)
        elseif not spr:IsPlaying("PickupSkull") then

            ragNpcs = REVEL.GetFilteredArray(REVEL.roomEnemies, isUnbuffedRagFamily)

            if data.FrameCount > 60 and #ragNpcs ~= 0 then
                data.targ = ragNpcs[math.random(#ragNpcs)]
                data.targ:GetData().Anima = npc
                data.State = "GoTo Host"
            end

            REVEL.MoveRandomly(npc, 60, 9, 19, speedSlow*0.05, 0.95)
        end

    elseif data.State == "GoTo Host" then
        local targ = data.targ

        if (targ:IsDead() or not targ:Exists()) or (targ:GetData().Anima.InitSeed ~= npc.InitSeed) then --if dead or targeted simultaneously as another anima
            data.State = "Move Default"
        else
            local diff = targ.Position-npc.Position
            local step, angle = 6, 45

            if data.FrameCount > 50 then
                step = REVEL.ClampedLerp(step, step*2, (data.FrameCount-50)/50)
                angle = REVEL.ClampedLerp(angle, angle * 0.25, (data.FrameCount-50)/50)
            end

            if diff:Length() < npc.Size+targ.Size then
                data.State = "Possess"
                spr:Play("Possess", true)
            end

            if data.FrameCount > 100 then
                REVEL.MoveAt(npc, targ.Position, speed*0.2, 0.8)
            else
                REVEL.CurvedPathAngle(npc, data, targ.Position, angle, 40, step, 0.8, speed * 0.2)
            end
        end

    elseif data.State == "Possess" then
        local targ = data.targ

        if targ:IsDead() or not targ:Exists() then
            data.State = "Move Default"
            spr:Play("Move", true)
        else
            npc:MultiplyFriction(0.85)
            targ:MultiplyFriction(0)
            if spr:IsEventTriggered("Possess") then
                REVEL.BuffEntity(targ)
            elseif spr:IsFinished("Possess") then
                data.State = "Buffing"
                data.Skull = REVEL.SpawnDecoration(npc.Position, Vector.Zero, "SkullIdle", "gfx/monsters/revel2/anima.anm2", nil, nil, nil, skullFinish, skullUpdate, nil, false)
            end
        end

    elseif data.State == "Buffing" then
        local targ = data.targ
        npc.Velocity = Vector.Zero
        npc.Position = targ.Position

        if targ:IsDead() or not targ:Exists() or data.Skull:IsDead() or not data.Skull:Exists() then
            data.State = "GoTo Skull"

            if targ:Exists() then
                targ:GetData().Buffed = false
                targ:GetData().Anima = nil
            end

            spr:Play("Exit", true)
        end

    elseif data.State == "GoTo Skull" then
        if data.Skull:IsDead() or not data.Skull:Exists() then
            spr:Play("Death")
            data.State = "Death"
        end

        if spr:IsPlaying("Exit") and data.targ:Exists() then
            data.targ:MultiplyFriction(0)

        elseif spr:IsFinished("Exit") then
            spr:Play("Move2", true)

        elseif spr:IsFinished("Possess2") then
            spr:Play("PickupSkull", true)
            npc.Position = data.Skull.Position
            data.Skull:Remove()
            data.Skull = nil
            data.State = "Move Default"

        elseif spr:IsPlaying("Move2") then
            local diff = data.Skull.Position-npc.Position

            REVEL.CurvedPathAngle(npc, data, data.Skull.Position, 45, 40, 3, 0.8, speed * 0.2)

            if diff:Length() < 10 then
                npc.Velocity = Vector.Zero
                spr:Play("Possess2", true)
            end
        end

    elseif data.State == "Death" then
        if spr:IsFinished("Death") then
            if data.Skull then
                data.Skull:GetSprite():Play("SkullDeath", true)
            end
            npc:Remove()
        end
    end

    if (REVEL.room:IsClear() and REVEL.includes(dieableStates, data.State)) then
        if not ragNpcs then ragNpcs = REVEL.GetFilteredArray(REVEL.roomEnemies, isUnbuffedRagFamily) end --might have been already defined, no need to do twice

        -- REVEL.DebugToConsole(#ragNpcs)

        if #ragNpcs == 0 then
            if data.State == "Move Default" then --drop skull, die
                data.Skull = REVEL.SpawnDecoration(npc.Position, Vector.Zero, "DropSkull", "gfx/monsters/revel2/anima.anm2", nil, nil, nil, skullFinish, skullUpdate, nil, false)
                spr:Play("Death")
                data.State = "Death"
            elseif data.State == "GoTo Skull" then
                spr:Play("Death")
                data.State = "Death"
            end
        end
    end

    if data.State ~= data.prevState then
        data.FrameCount = 0
    else
        data.FrameCount = data.FrameCount + 1
    end

    data.prevState = data.State
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, anima_NpcUpdate, REVEL.ENT.ANIMA.id)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SELECT_ENTITY_LIST, 1, function(entityList, index, entityMeta)
    if #entityList > 1 and StageAPI.CurrentlyInitializing and entityMeta then
        local hasRagFamily, hasAnima
        for ind, entData in ipairs(entityList) do
            if entData.Type == REVEL.ENT.ANIMA.id and entData.Variant == REVEL.ENT.ANIMA.variant then
                hasAnima = true
            elseif REVEL.RAG_FAMILY[entData.Type] then
                for _, var in ipairs(REVEL.RAG_FAMILY[entData.Type]) do
                    if var == entData.Variant then
                        hasRagFamily = true
                        break
                    end
                end
            end
        end

        if hasRagFamily and hasAnima then
            local retEntityList = {}
            for ind, entData in ipairs(entityList) do
                if not (entData.Type == REVEL.ENT.ANIMA.id and entData.Variant == REVEL.ENT.ANIMA.variant) then
                    retEntityList[#retEntityList + 1] = entData
                end
            end

            if not entityMeta[index] then
                entityMeta[index] = {}
            end

            entityMeta:AddMetadataEntity(index, "Anima")
            REVEL.DebugStringMinor("Set anima flag for index", index)

            return nil, retEntityList, true
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not npc:GetData().AnimaChecked then
        npc:GetData().AnimaChecked = true
        local ragfamily = REVEL.RAG_FAMILY[npc.Type]
        if ragfamily then
            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom then
                local index = REVEL.room:GetGridIndex(npc.Position)
                if currentRoom.Metadata:Has{Index = index, Name = "Anima"} then
                    local isAnimaEntity
                    for _, var in ipairs(ragfamily) do
                        if npc.Variant == var then
                            isAnimaEntity = true
                            break
                        end
                    end

                    if isAnimaEntity then
                        local anima = Isaac.Spawn(REVEL.ENT.ANIMA.id, REVEL.ENT.ANIMA.variant, 0, npc.Position, Vector.Zero, nil)
                        anima:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        local adata = anima:GetData()
                        adata.targ = npc
                        adata.ForcePossess = true

                        local ndata = npc:GetData()
                        ndata.Buffed = true
                        ndata.Anima = anima
                    end
                end
            end
        end
    end
end)

end

REVEL.PcallWorkaroundBreakFunction()