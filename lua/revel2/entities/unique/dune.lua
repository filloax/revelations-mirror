REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Dune

local bal = {
    speed = 12,
    accel = 0.2,
    awaySpeed = 6,
}

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.DUNE.variant then return end

    local d = npc:GetData()
    local sprite = npc:GetSprite()
    local target = npc:GetPlayerTarget()
    local path = npc.Pathfinder
    --local rng = npc:GetDropRNG()

    local isFriendly = npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
    REVEL.DuneTileProcessing(npc, npc.Position + (npc.Velocity*4))

    if target:GetData().OnDuneTile then
        if #REVEL.players > 1 then
            for _, player in ipairs(REVEL.players) do
                if not player:GetData().OnDuneTile then
                    target = player
                end
            end
        end
    end

    if not d.state then
        d.startPos = npc.Position
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite.FlipX = npc.Position.X > target.Position.X

        d.faceDir = "Hori"
        d.speedAnim = ""
        d.deathAnim = "IdleDeath"
        d.state = "Idle"
        d.speed = 0

        if REVEL.room:IsClear() then
            d.startClear = true
        end
    
    elseif d.state == "Idle" then
        if (not sprite:IsPlaying("Idle") and not sprite:IsPlaying("Respawn"))
        or sprite:IsFinished("Respawn") then
            sprite:Play("Idle")
        end

        if not sprite:IsPlaying("Respawn") and not target:GetData().OnDuneTile then
            if target.Position.Y > npc.Position.Y then d.faceDir = "Hori" else d.faceDir = "Vert" end
            sprite:Play("Pop" .. d.faceDir)
            d.state = "Pop"
        end
        npc.Velocity = Vector.Zero

    elseif d.state == "Pop" then
        if sprite:IsEventTriggered("Chase") or sprite:IsFinished("Pop" .. d.faceDir) then
            sprite.FlipX = npc.Position.X > target.Position.X
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
            d.state = "Chase"
        end
        npc.Velocity = Vector.Zero

    elseif d.state == "Chase" then

        if npc.Velocity.Y > 1 then d.faceDir = "Hori" elseif npc.Velocity.Y < -1 then d.faceDir = "Vert" end
        if npc.Velocity.X > 1 then sprite.FlipX = false elseif npc.Velocity.X < -1 then sprite.FlipX = true end

        if npc.Velocity:Length() > 8 then
            d.speedAnim = "_Fast"
        else
            d.speedAnim = ""
        end

        if not sprite:IsPlaying("Walk" .. d.faceDir .. d.speedAnim) then
            sprite:Play("Walk" .. d.faceDir .. d.speedAnim)
        end

        if d.speed < bal.speed then
            d.speed = d.speed + bal.accel
        else
            d.speed = bal.speed
        end

        local targetPos = target.Position+target.Velocity
        d.subTime = d.subTime or 40

        if target:GetData().OnDuneTile then
            targetPos = d.startPos
            if (npc.Position-targetPos):Length() < 30 and d.speed >= bal.awaySpeed then
                d.subTime = 0
            end

            if d.speed > bal.awaySpeed then
                d.speed = bal.awaySpeed
            end

            d.subTime = d.subTime - 1
        end

        if d.OnDuneTile then
            npc.Velocity = (targetPos-npc.Position):Resized(d.speed)
            if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
                npc.Velocity = Vector(0,npc.Velocity.Y)
            elseif math.abs(npc.Velocity.X) < math.abs(npc.Velocity.Y) then
                npc.Velocity = Vector(npc.Velocity.X,0)
            end
            d.subTime = d.subTime - 2
        
        elseif REVEL.room:CheckLine(npc.Position,targetPos,0,900,false,false) then
            npc.Velocity = REVEL.Lerp(npc.Velocity, (targetPos-npc.Position):Resized(d.speed), 0.15)
        else
            path:FindGridPath(targetPos, d.speed*0.15, 900, true)
        end

        if not d.OnDuneTile and not target:GetData().OnDuneTile then
            d.subTime = 40
        end

        if d.subTime <= 0 then
            d.subTime = nil
            d.speed = 0
            d.speedAnim = ""
            sprite:Play("Death" .. d.faceDir)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            d.state = "Burrow"
        end

    elseif d.state == "Burrow" then
        if sprite:IsFinished("Death" .. d.faceDir) then
            sprite:Play("Respawn")
            npc.Position = d.startPos
            sprite.FlipX = npc.Position.X > target.Position.X
            d.state = "Idle"
        end

        npc.Velocity = REVEL.Lerp(npc.Velocity, Vector.Zero, 0.2)

    elseif d.state == "Death" then
        if not sprite:IsPlaying(d.deathAnim) then
            sprite:Play(d.deathAnim)
        end

        if sprite:IsFinished(d.deathAnim) then
            npc:Remove()
        end

        npc.Velocity = REVEL.Lerp(npc.Velocity, Vector.Zero, 0.2)
    end

    if not d.startClear and REVEL.room:IsClear() then
        d.deathAnim = "Death" .. d.faceDir
        if d.state == "Idle" then d.deathAnim = "IdleDeath" end
        d.state = "Death"
    end


end, REVEL.ENT.DUNE.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount)
    if entity.Variant ~= REVEL.ENT.DUNE.variant then return end
    return false
end, REVEL.ENT.DUNE.id)

end

REVEL.PcallWorkaroundBreakFunction()