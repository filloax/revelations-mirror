local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Smolycephalus For Scale
REVEL.SmolycephalusForScale = false
StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.SmolycephalusForScale and REVEL.level:GetCurrentRoomIndex() == REVEL.level:GetStartingRoomIndex() then
        local smoly = REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE:spawn(REVEL.room:GetBottomRightPos() - Vector(60, 60), Vector.Zero, nil)
        smoly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    end
end)

local healthbarBackScale = Vector(1, 4)
local healthbarScale = Vector(1, 2)
local line = REVEL.LazyLoadRoomSprite{
    ID = "smolyScaleLine",
    Anm2 = "gfx/effects/revel2/black_line.anm2",
    Animation = "Idle",
}

local smolySumSeconds = 10
local smolyBurrowSeconds = 5
local maxDamageInstancesRendered = 10

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.variant or not REVEL.IsRenderPassNormal() then
        return
    end

    npc.Velocity = Vector.Zero
    npc.Friction = 0
    npc.Mass = 10000

    local renderPos = Isaac.WorldToScreen(npc.Position)
    local data, sprite = npc:GetData(), npc:GetSprite()
    if sprite:IsPlaying("GoUnder") or sprite:IsPlaying("Emerge") then
        return
    elseif sprite:IsFinished("GoUnder") then
        sprite:Play("Emerge", true)
        return
    elseif sprite:IsFinished("Emerge") or sprite:IsFinished("Idle") or sprite:IsFinished("Hit") then
        sprite:Play("Idle", true)
    end

    if type(REVEL.SmolycephalusForScale) ~= "boolean" and REVEL.SmolycephalusForScale ~= data.SmolyTargetFightLength then
        data.SmolyTargetFightLength = REVEL.SmolycephalusForScale
    end

    if data.SmolyTargetFightLength and not data.MaxHitPoints then
        local scaledHP, hpPerSecond, scaledLength = REVEL.GetScaledBossHP(data.SmolyTargetFightLength, 1)
        data.HPScaled = hpPerSecond
        data.MaxHitPoints = scaledHP
        data.SmolyHitPoints = data.MaxHitPoints
    end

    if not data.DamageTaken then
        data.DamageTaken = {}
    end

    local killedFrame
    if data.LastDamageTaken then
        for _, amount in ipairs(data.LastDamageTaken) do
            data.DamageTaken[#data.DamageTaken + 1] = {amount, npc.FrameCount}
            if data.SmolyHitPoints then
                if not data.FirstDamaged then
                    data.FirstDamaged = npc.FrameCount
                end

                data.SmolyHitPoints = data.SmolyHitPoints - amount
                if data.SmolyHitPoints <= 0 then
                    killedFrame = npc.FrameCount
                end
            end
        end

        data.LastDamageTaken = nil
    end

    if killedFrame then
        local timeElapsed = killedFrame - data.FirstDamaged
        Isaac.ConsoleOutput("Killed in " .. tostring(timeElapsed) .. " frames! (" .. tostring(math.floor(timeElapsed / 30)) .. " seconds)\n")
        data.FirstDamaged = nil
        data.SmolyHitPoints = data.MaxHitPoints
    end

    if data.SmolyHitPoints and data.MaxHitPoints then
        local lstart, lend = renderPos + Vector(-16, 20), renderPos + Vector(16, 20)
        line.Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
        line.Scale = healthbarBackScale
        REVEL.DrawRotatedTilingSprite(line, lstart + Vector(-1, 0), lend + Vector(1, 0), 512)
        line.Color = Color(1, 1, 1, 1,conv255ToFloat( 255, 0, 0))
        line.Scale = healthbarScale
        REVEL.DrawRotatedTilingSprite(line, lstart, REVEL.Lerp(lstart, lend, data.SmolyHitPoints / data.MaxHitPoints), 512)
    end

    local totalDamage = 0
    for _, amount in ipairs(data.DamageTaken) do
        totalDamage = totalDamage + amount[1]
    end

    local secondsNotSummed = 0
    local perSecond = {}
    for i = 30, 30 * smolySumSeconds, 30 do
        local ind = i / 30
        perSecond[ind] = 0
        local hasDamageAfter
        for _, amount in ipairs(data.DamageTaken) do
            local diff = npc.FrameCount - amount[2]
            if diff >= i - 30 and diff < i then
                perSecond[ind] = perSecond[ind] + amount[1]
            elseif diff >= i then
                hasDamageAfter = true
            end
        end

        if not hasDamageAfter then
            perSecond[ind] = 0
        end

        if perSecond[ind] > 0 then
            secondsNotSummed = 0
        else
            secondsNotSummed = secondsNotSummed + 1
        end
    end

    local averageLastSeconds = 0
    for i, second in ipairs(perSecond) do
        averageLastSeconds = averageLastSeconds + second
    end

    averageLastSeconds = averageLastSeconds / math.max(smolySumSeconds - secondsNotSummed, 1)


    local instancesRendered = 0
    local countingRepeats = {Of = nil, Count = 0}
    for i, amount in StageAPI.ReverseIterate(data.DamageTaken) do
        if i == #data.DamageTaken then
            local text = tostring(#data.DamageTaken) .. " INS"
            instancesRendered = instancesRendered + 1
            Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y - 12 * instancesRendered, 255, 255, 255, 255)
        end

        if not countingRepeats.Of then
            local text = tostring(amount[1]) .. " @" .. tostring(amount[2]):sub(-3)
            instancesRendered = instancesRendered + 1
            Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y - 12 * instancesRendered, 255, 255, 255, 255)
        else
            if countingRepeats.Of == amount[1] then
                countingRepeats.Count = countingRepeats.Count + 1
            end

            if i == 1 or countingRepeats.Of ~= amount[1] then
                local text = tostring(countingRepeats.Of) .. " x" .. tostring(countingRepeats.Count)
                instancesRendered = instancesRendered + 1
                Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y - 12 * instancesRendered, 255, 255, 255, 255)
                break
            end
        end

        if instancesRendered == maxDamageInstancesRendered and not countingRepeats.Of then
            countingRepeats.Of = amount[1]
            countingRepeats.Count = 1
        end
    end

    if #data.DamageTaken > 0 and (npc.FrameCount - data.DamageTaken[#data.DamageTaken][2]) > 30 * smolyBurrowSeconds then
        sprite:Play("GoUnder", true)
        data.DamageTaken = nil
        data.MaxHitPoints = nil
    end

    local round = math.floor(averageLastSeconds * 100) / 100
    local text = tostring(round) .. " DPS"
    Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y, 255, 255, 255, 255)
    local text = tostring(totalDamage) .. " TOT"
    Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y + 12, 255, 255, 255, 255)
    local round = math.floor(REVEL.EstimateDPS(REVEL.player) * 100) / 100
    local text = tostring(round) .. " EST"
    Isaac.RenderText(text, renderPos.X - (string.len(text) / 2) * 5, renderPos.Y + 24, 255, 255, 255, 255)
end, REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, amount, flags, source, iframes)
    if npc.Variant ~= REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.variant then
        return
    end

    local data, sprite = npc:GetData(), npc:GetSprite()
    if sprite:IsPlaying("Idle") or sprite:IsPlaying("Hit") then
        sprite:Play("Hit", true)
    end

    if not data.LastDamageTaken then
        data.LastDamageTaken = {}
    end

    data.LastDamageTaken[#data.LastDamageTaken + 1] = amount

    npc.HitPoints = npc.HitPoints + amount
end, REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.id)

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.variant then
        return
    end
    npc:GetData().SmolyHitPoints = npc.HitPoints

end, REVEL.ENT.SMOLYCEPHALUS_FOR_SCALE.id)


end