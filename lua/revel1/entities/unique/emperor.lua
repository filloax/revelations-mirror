return function()

-- Emperor
local bal = {
    -- WalkAnims = {Horizontal = "WalkHori", Up = "WalkUp", Down = "WalkDown"},
    SlideAnims = {Horizontal = "SlideHori", Up = "SlideUp", Down = "SlideDown"},
    SlideAnimsStart = {Horizontal = "SlideHori_Start", Up = "SlideUp_Start", Down = "SlideDown_Start"},
    SlideAccel = 0.82,
    SlideFriction = 0.97,
    ResetTimeAfterHit = 0,
}

local function slideAllEmperors(target)
    local emps = REVEL.ENT.EMPEROR:getInRoom()
    local resetUpTo = -1

    for i, npc in ipairs(emps) do
        local data, sprite = npc:GetData(), npc:GetSprite()
        target = target or npc:ToNPC():GetPlayerTarget()

        local dir = REVEL.dirToVel[REVEL.GetDirectionFromVelocity(target.Position - npc.Position)] --axis aligned vector

        if sprite:IsPlaying("Appear") or npc.FrameCount == 0 or data.State ~= "Walk" or not REVEL.room:CheckLine(npc.Position, npc.Position + dir * 40, 3, 0, false, false) then --grid too close, can't slide
            return false
        end
    end

    --No emperor is blocked, do slide
    for i, npc in ipairs(emps) do
        local data, sprite = npc:GetData(), npc:GetSprite()
        target = target or npc:ToNPC():GetPlayerTarget()

        local dir = REVEL.dirToVel[REVEL.GetDirectionFromVelocity(target.Position - npc.Position)] --axis aligned vector

        data.SlideDir = dir
        data.State = "Slide"
        data.SlideCounter = 150 --5 seconds, fallback in case they get stuck
        REVEL.AnimateWalkFrame(sprite, dir, bal.SlideAnimsStart, true)
        npc.Velocity = npc.Velocity * 0.5 + data.SlideDir * bal.SlideAccel * 1.5
    end

    REVEL.sfx:Play(REVEL.SFX.EMPEROR_ANGRY, 1.35, 0, false, 1)

    return true
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.EMPEROR:isEnt(npc) then return end

    local data, sprite = npc:GetData(), npc:GetSprite()
    local target = npc:GetPlayerTarget()

    if not data.Init then
        data.NextRetry = -1
        data.State = "Walk"
        data.Init = true

        npc.SplatColor = REVEL.WaterSplatColor
    end

    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

    if sprite:IsPlaying("Appear") or npc.FrameCount == 0 then return end

    if sprite:IsEventTriggered("Step") then
        REVEL.sfx:Play(SoundEffect.SOUND_MEAT_IMPACTS, 0.25, 0, false, 1.6 + math.random()*0.1)
    end

    if data.State == "Walk" then
        if not REVEL.MultiPlayingCheck(sprite, "SlideHori_End", "SlideDown_End", "SlideUp_End") then
            REVEL.MoveRandomlyAxisAligned(npc, 15, 45, 0.6, 0.8, true)

            REVEL.PlayIfNot(sprite, "WalkDown")

            sprite.FlipX = npc.Velocity.X < 0
        end

        if npc.FrameCount > data.NextRetry
        and (math.abs(target.Position.X - npc.Position.X) < 18 or math.abs(target.Position.Y - npc.Position.Y) < 18)
        and REVEL.room:CheckLine(npc.Position, target.Position, 3, 0, false, false) then
            if not slideAllEmperors(target) then
                data.NextRetry = npc.FrameCount + 15
            end
        end
    elseif data.State == "Slide" then
        local still = false
        for _, anim in pairs(bal.SlideAnims) do
            if sprite:IsFinished(anim .. "_Start") then
                sprite:Play(anim, true)
            end
            if sprite:IsPlaying(anim .. "_Start") and not sprite:WasEventTriggered("Land") then
                still = true
            end
            if sprite:IsEventTriggered("Land") then
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 0.4, 0, false, 1)
            end
        end

        if still then
            npc.Velocity = npc.Velocity * 0.9
        elseif REVEL.Glacier.CheckIce(npc) then
            npc.Velocity = npc.Velocity + data.SlideDir * bal.SlideAccel
        else
            npc.Velocity = npc.Velocity * bal.SlideFriction + data.SlideDir * bal.SlideAccel
        end

        -- IDebug.RenderUntilNextUpdate(IDebug.RenderLine, npc.Position, npc.Position + data.SlideDir * 80)

        data.SlideCounter = data.SlideCounter - 1

        local finish = npc:CollidesWithGrid() or data.SlideCounter <= 0

        if not data.ResetTime and bal.ResetTimeAfterHit > 0 and finish then
            data.ResetTime = npc.FrameCount + bal.ResetTimeAfterHit
        elseif (data.ResetTime and npc.FrameCount > data.ResetTime) or (finish and bal.ResetTimeAfterHit <= 0) then
            data.State = "Walk"
            for _, anim in pairs(bal.SlideAnims) do
                if sprite:IsPlaying(anim) then
                    sprite:Play(anim .. "_End", true)
                    REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEAT_IMPACTS, 0.4, 0, false, 1.2)
                end
            end
            data.ResetTime = nil
        end
    end

    -- REVEL.DebugToConsole(data.State, sprite:GetAnimation())
end, REVEL.ENT.EMPEROR.id)

end