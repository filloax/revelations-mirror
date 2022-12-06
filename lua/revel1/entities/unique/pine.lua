local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Pine & Pinecone

local bal = {
    --pine
    attackIntMin = 40,
    attackIntMax = 80,
    shotMaxDist = 400,
    shotPower = 10,

    --pinecone
    orbitSpeed = 6,
    orbitDist = 30,
    panicDashDist = 40,
    panicDashInterval = 15,
}

local function pineProcessing(npc, newRoom)
    local data = npc:GetData()

    data.pineGang = data.pineGang or {}
    data.pineIndices = data.pineIndices or {}

    data.npcIndex = REVEL.room:GetGridIndex(npc.Position)

    if not newRoom then
        newRoom = StageAPI.GetCurrentRoom()
    end

    if newRoom then
        local groups = newRoom.Metadata:GroupsWithIndex(data.npcIndex)

        if #groups > 0 then
            local indices = newRoom.Metadata:IndicesInGroup(groups[1])
            data.pineIndices = indices
        end
    end

    local radius = 100
    if Isaac.CountEntities(nil, REVEL.ENT.PINE.id, REVEL.ENT.PINE.variant) == 1 or #data.pineIndices > 0 then
        radius = 1000
    end

    local count = 1
    for _, ent in ipairs(Isaac.FindInRadius(npc.Position, radius, EntityPartition.ENEMY)) do
        local check = false
        if ent.Type == REVEL.ENT.PINECONE.id and
        ent.Variant == REVEL.ENT.PINECONE.variant then
            if #data.pineIndices > 0 then
                local entIndex = REVEL.room:GetGridIndex(ent.Position)
                for _, index in ipairs(data.pineIndices) do
                    if entIndex == index then
                        table.insert(data.pineGang, EntityPtr(ent))
                        check = true
                    end
                end
            elseif not ent:GetData().pineParent then
                table.insert(data.pineGang, EntityPtr(ent))
                check = true
            end

            if check then
                ent:GetData().pineParent = EntityPtr(npc)
                ent:GetData().pineCount = count
                ent:GetData().pineFormPos = ent.Position - npc.Position
                count = count + 1
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)

    --PINE
    if npc.Variant == REVEL.ENT.PINE.variant then
        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or npc:HasEntityFlags(EntityFlag.FLAG_CHARM)
        local isConfused = npc:HasEntityFlags(EntityFlag.FLAG_CONFUSION) or npc:HasEntityFlags(EntityFlag.FLAG_FEAR)

        if not data.init then
            data.state = "Idle"
            data.substate = "Orbit"
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

            if REVEL.room:GetFrameCount() > 10 then
                pineProcessing(npc)
            end

            data.pineGang = data.pineGang or {}
            data.pineIndices = data.pineIndices or {}

            data.StartPos = npc.Position
            data.HoverPos = npc.StartPos

            data.spinDir = 1
            if npc.SubType >= 2 then
                data.spinDir = -1
            end

            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            data.init = true
        else
            if not data.spawnedGuy and (npc.SubType == 1 or npc.SubType == 3) then
                local cone = Isaac.Spawn(REVEL.ENT.PINECONE.id,REVEL.ENT.PINECONE.variant,0,npc.Position,Vector.Zero,npc)
                table.insert(data.pineGang, EntityPtr(cone))
                cone:GetData().pineParent = EntityPtr(npc)
                cone:GetData().pineCount = #data.pineGang
                cone:GetData().pineFormPos = Vector.Zero
                cone:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                data.spawnedGuy = true
            end

            if #data.pineGang > 0 then
                for i, entPtr in ipairs(data.pineGang) do
                    local ent = entPtr.Ref

                    if ent then
                        local entData = ent:GetData()

                        if isFriendly then
                            ent:AddCharmed(EntityRef(npc), 2)
                        end

                        if data.substate == "Orbit" then
                            if not entData.angle then
                                entData.angle = (360 / #data.pineGang)*i
                            else
                                entData.angle = entData.angle + (bal.orbitSpeed+3)*data.spinDir
                                ent.Velocity = ((npc.Position + REVEL.GetOrbitOffset(entData.angle * (math.pi / 180), bal.orbitDist)) - ent.Position) / 2
                                local len = ent.Velocity:Length()
                                if len > 10 then
                                    ent.Velocity = (ent.Velocity / len) * 10
                                end
                            end
                        elseif data.substate == "Formation" then
                            entData.pineFormPos = entData.pineFormPos or (ent.Position - npc.Position)
                            local pos = REVEL.Lerp(ent.Position,npc.Position + entData.pineFormPos, 0.2)
                            ent.Velocity = pos - ent.Position
                            --ent.Velocity = Vector.Zero
                            entData.angle = nil

                            if sprite:IsEventTriggered("Shoot") then
                                entData.pivotDist = entData.pineFormPos:Length()
                                entData.pivotAngle = entData.pineFormPos:GetAngleDegrees()
                                data.shotPivot = npc.Position
                                data.shotVec = (target.Position-npc.Position):Resized(bal.shotPower)
                                data.shotLength = math.min((target.Position-npc.Position):Length(),bal.shotMaxDist)
                            end

                        elseif data.substate == "Shoot" then
                            if entData.pivotAngle and entData.pivotDist then
                                if entData.pivotDist > 0.1 then
                                    entData.pivotAngle = entData.pivotAngle + bal.orbitSpeed*data.spinDir
                                    ent.Velocity = ((data.shotPivot + REVEL.GetOrbitOffset(entData.pivotAngle * (math.pi / 180), entData.pivotDist)) - ent.Position) / 2
                                elseif entData.pivotDist < 0.1 then
                                    ent.Velocity = (data.shotPivot - ent.Position) / 4
                                end
                            end
                        end
                    end
                end
            end

            if data.substate == "Shoot" and data.shotPivot then
                local shotLength = (data.shotLength * 4) / (bal.shotPower)
                if not data.shotTimer then
                    data.shotTimer = shotLength
                elseif data.shotTimer > 0 then
                    data.shotPivot = data.shotPivot + REVEL.Lerp2Clamp(data.shotVec, -data.shotVec, data.shotTimer, shotLength, 0)
                    data.shotTimer = data.shotTimer - 1
                else
                    data.shotTimer = nil
                    REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 1, 0, false, 1)
                    data.substate = "Orbit"
                end

                if #data.pineGang <= 0 then
                    data.shotTimer = nil
                    data.substate = "Orbit"
                end
            end
        end

        if data.state == "Idle" then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle")
            end

            if data.substate == "Orbit" and #data.pineGang > 0 and not isConfused then
                if not data.attackTimer then
                    data.attackTimer = math.random(bal.attackIntMin,bal.attackIntMax)
                elseif data.attackTimer > 0 then
                    data.attackTimer = data.attackTimer - 1
                else
                    data.attackTimer = nil
                    data.state = "Attack"
                end
            end

            if data.substate == "Orbit" then
                if not data.hoverTimer then
                    data.HoverPos = data.StartPos + Vector(30,0):Rotated(math.random(360))
                    if #data.pineGang <= 0 then
                        data.HoverPos = npc.Position + (target.Position - npc.Position):Resized(60)
                    elseif REVEL.room:GetGridCollisionAtPos(data.HoverPos) > 1 then
                        data.HoverPos = npc.Position
                    end
                    data.hoverTimer = math.random(20,50)
                elseif data.hoverTimer > 0 then
                    local pos = REVEL.Lerp(npc.Position,data.HoverPos,0.05)
                    npc.Velocity = pos - npc.Position
                    data.hoverTimer = data.hoverTimer - 1
                else
                    data.hoverTimer = nil
                end
            end

        elseif data.state == "Attack" then
            if sprite:IsFinished("Attack") then
                data.state = "Idle"
            end

            if sprite:IsEventTriggered("GroupUp") then
                REVEL.sfx:Play(SoundEffect.SOUND_SKIN_PULL, 0.6, 0, false, 0.8+math.random()*0.2)
                data.substate = "Formation"
            end

            if sprite:IsEventTriggered("Shoot") then
                REVEL.sfx:Play(REVEL.SFX.ICE_THROW, 1, 0, false, 1.1+math.random()*0.2)
                data.substate = "Shoot"
            end

            if not sprite:IsPlaying("Attack") then
                sprite:Play("Attack")
            end

            npc.Velocity = npc.Velocity * 0.8
        end

    -- PINECONE
    elseif npc.Variant == REVEL.ENT.PINECONE.variant then

        local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()

        local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or npc:HasEntityFlags(EntityFlag.FLAG_CHARM)

        if not data.init then
            data.state = "Idle"
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            data.init = true
        end

        if isFriendly then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        end

        if data.state == "Idle" then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle")
            end

            if data.pineParent then
                local pine = data.pineParent.Ref

                if pine:IsDead() then
                    data.state = "Panic"
                end
            else
                if REVEL.room:GetFrameCount() > 10 then
                    data.state = "Panic"
                end
                npc.Velocity = Vector.Zero
            end
        elseif data.state == "Panic" then
            data.pineParent = nil
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

            if not sprite:IsPlaying("Panic") then
                sprite:Play("Panic")
            end

            if REVEL.room:GetFrameCount() % bal.panicDashInterval == 0 then
                data.PanicPos = npc.Position + Vector(bal.panicDashDist,0):Rotated(math.random(360))
                if REVEL.room:GetGridCollisionAtPos(data.PanicPos) > 0 then
                    data.PanicPos = npc.Position + (target.Position - npc.Position):Resized(bal.panicDashDist):Rotated(math.random(-60,60))
                end
            end

            if data.PanicPos then
                local pos = REVEL.Lerp(npc.Position,data.PanicPos,0.3)
                npc.Velocity = pos - npc.Position
            end
        end
        
    end
end, REVEL.ENT.PINE.id)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, isFirstVisit, isExtraRoom)
    local pines = Isaac.FindByType(REVEL.ENT.PINE.id, REVEL.ENT.PINE.variant, -1, false, false)

    if #pines > 0 then
        for _, npc in ipairs(pines) do
            pineProcessing(npc, newRoom)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, amt, flag, src)
    if npc.Variant == REVEL.ENT.PINE.variant then
        if src then
            if src.Type == REVEL.ENT.PINECONE.id and src.Variant == REVEL.ENT.PINECONE.variant then
                return false
            end
        end

    elseif npc.Variant == REVEL.ENT.PINECONE.variant then
        if npc.HitPoints - amt > 0 then return end

        if src then
            if src.Type == REVEL.ENT.PINE.id and src.Variant == REVEL.ENT.PINE.variant then
                return false
            end
        end

        local data = npc:GetData()

        if data.pineParent and data.pineCount then
            local pine = data.pineParent.Ref
            local pData = pine:GetData()

            if pData.pineGang[data.pineCount] then
                local startIndex = data.pineCount
                table.remove(pData.pineGang,data.pineCount)
                for _, entPtr in ipairs(pData.pineGang) do
                    local ent = entPtr.Ref
                    if ent then
                        if ent:GetData().pineCount > startIndex then
                            ent:GetData().pineCount = ent:GetData().pineCount - 1
                        end
                    end
                end
            end
        end
    end
end, REVEL.ENT.PINE.id)

REVEL.AddDeathEventsCallback {
    OnDeath = function(npc)
        local data = npc:GetData()
        npc.Velocity = Vector.Zero
    end,
    DeathRender = function (npc, triggeredEventThisFrame)
        local sprite, data = npc:GetSprite(), npc:GetData()
        if IsAnimOn(sprite, "Death") and not triggeredEventThisFrame then
            local justTriggered

            if sprite:IsFinished("Death") then
                npc:Kill()
                justTriggered = true
            end
            return justTriggered
        end
    end, 
    Type = REVEL.ENT.PINE.id, 
    Variant = REVEL.ENT.PINE.variant,
}


REVEL.AddDeathEventsCallback {
    OnDeath = function(npc)
        local data = npc:GetData()
        npc.Velocity = Vector.Zero
    end,
    DeathRender = function (npc, triggeredEventThisFrame)
        local sprite, data = npc:GetSprite(), npc:GetData()
        if IsAnimOn(sprite, "Death") and not triggeredEventThisFrame then
            local justTriggered

            if sprite:IsFinished("Death") then
                npc:Kill()
                justTriggered = true
            end
            return justTriggered
        end
    end, 
    Type = REVEL.ENT.PINECONE.id, 
    Variant = REVEL.ENT.PINECONE.variant,
}
end