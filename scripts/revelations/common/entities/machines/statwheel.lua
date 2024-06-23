local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Revending machine

REVEL.RegisterMachine(REVEL.ENT.VANITY_STATWHEEL)

local bal = {
    Duration = {Min = 40, Max = 70},
    Speed = 28,
    SlowTime = 70,

    StatUps = {
        Damage = REVEL.ShrineBalance.StatwheelStatUps.Damage,
        MaxFireDelay = REVEL.ShrineBalance.StatwheelStatUps.MaxFireDelay,
        Luck = REVEL.ShrineBalance.StatwheelStatUps.Luck,
        MoveSpeed = REVEL.ShrineBalance.StatwheelStatUps.MoveSpeed,
        TearRange = REVEL.ShrineBalance.StatwheelStatUps.TearRange,
        ShotSpeed = REVEL.ShrineBalance.StatwheelStatUps.ShotSpeed,
    },
    StatWeights = {
        Damage = 0.65,
        MaxFireDelay = 0.65,
        Luck = 0.8,
        MoveSpeed = 1,
        TearRange = 1,
        ShotSpeed = 0.5,
    },
    RepeatStatWeightMult = 0.9,
    BlankSpots = {Min = 3, Max = 4},
}

local WHEEL_OFFSET = Vector(0, -34)
local ARROW_OFFSET = Vector(0, -64)

local StatFrames = {
    Damage = 0,
    MaxFireDelay = 1,
    Luck = 2,
    MoveSpeed = 3,
    TearRange = 4,
    ShotSpeed = 5,
}
local StatNames = {
    Damage = "Damage",
    MaxFireDelay = "Tears",
    Luck = "Luck",
    MoveSpeed = "Speed",
    TearRange = "Range",
    ShotSpeed = "Shot speed",
}
local Stats = REVEL.keys(StatFrames)

local NUM_SPOTS = 8
local STAT_ANGLE_OFFSET = -3
local SPOT_EDGE_OFFSET = 45 / 2 --angle from origin to spot edge

local States = {
    IDLE = 0,
    SPINNING = 1,
    REWARD = 2,
}

local function SaveSaveData(machine, data)
    local roomID = StageAPI.GetCurrentRoomID()
    local entityID = REVEL.room:GetGridIndex(machine.Position)

    if not revel.data.run.level.statwheelData[roomID] then
        revel.data.run.level.statwheelData[roomID] = {}
    end

    revel.data.run.level.statwheelData[roomID][entityID] = {
        Spots = REVEL.CopyTable(data.Spots),
        RNGOffset = data.RNG:GetOffset(),
        WheelRotation = data.WheelRotation,
    }
end

local function LoadSaveData(machine)
    local roomID = StageAPI.GetCurrentRoomID()
    local entityID = REVEL.room:GetGridIndex(machine.Position)

    local saveData = revel.data.run.level.statwheelData[roomID] and
        revel.data.run.level.statwheelData[roomID][entityID]

    if saveData then
        local spots = REVEL.CopyTable(saveData.Spots)
        return {
            Spots = spots,
            RNGOffset = saveData.RNGOffset,
            WheelRotation = saveData.WheelRotation,
        }
    end
    return nil
end

local function statWheel_PostMachineInit(machine, data)
    local sprite = machine:GetSprite()

    data.Position = machine.Position
    data.FirstLoss = false
    data.WheelSprite = Sprite()
    data.WheelSprite:Load(sprite:GetFilename(), true)
    data.WheelSprite:Play("Idle", true)
    data.ArrowSprite = Sprite()
    data.ArrowSprite:Load(sprite:GetFilename(), true)
    data.ArrowSprite:Play("Arrow", true)
    sprite:Play("Base")

    local saveData = LoadSaveData(machine)

    data.RNG = REVEL.RNG()
    ---@diagnostic disable-next-line: need-check-nil
    data.RNG:SetSeed(machine.InitSeed, saveData and saveData.RNGOffset or 40)

    if not saveData then
        local numBlankSpots = REVEL.GetFromMinMax(bal.BlankSpots, data.RNG)
        data.Spots = {}
        for i = 1, numBlankSpots do
            data.Spots[i] = "Blank"
        end

        local weights = REVEL.CopyTable(bal.StatWeights)
        for i = 1, NUM_SPOTS - numBlankSpots do
            local chosenStat = REVEL.WeightedRandom(weights, data.RNG)
            weights[chosenStat] = weights[chosenStat] * bal.RepeatStatWeightMult
            data.Spots[#data.Spots+1] = chosenStat
        end

        data.Spots = REVEL.Shuffle(data.Spots, data.RNG)

        data.WheelRotation = 0

        SaveSaveData(machine, data)
    else
        data.Spots = saveData.Spots
        data.WheelRotation = saveData.WheelRotation
    end

    data.State = States.IDLE
end

local function statwheel_PostMachineUpdate(machine, data)
    local triggered = false

    if data.State == States.IDLE and REVEL.GetShrineVanity() >= REVEL.ShrineBalance.StatwheelPrice then
        for i, player in ipairs(REVEL.players) do
            if player.Position:DistanceSquared(machine.Position) < (machine.Size + player.Size) ^ 2 then
                data.TriggerPlayer = player
                triggered = true
                break
            end
        end
    end

    if triggered then
        data.State = States.SPINNING
        data.Timer = 0
        data.SpinDuration = REVEL.GetFromMinMax(bal.Duration, data.RNG) + bal.SlowTime
        REVEL.AddShrineVanity(-REVEL.ShrineBalance.StatwheelPrice)
        REVEL.sfx:Play(SoundEffect.SOUND_SHELLGAME)
    end

    if data.State == States.SPINNING then
        data.Timer = data.Timer + 1
        local speed = bal.Speed *
            REVEL.Lerp2Clamp(0, 1, data.Timer, 0, 8) * 
            REVEL.Lerp2Clamp(1, 0, data.Timer, data.SpinDuration - bal.SlowTime, data.SpinDuration) ^ 2
        data.WheelRotation = (data.WheelRotation + speed) % 360

        if data.Timer >= data.SpinDuration then
            data.Timer = 0
            data.State = States.REWARD

            local endSpot = math.ceil((360 - data.WheelRotation + SPOT_EDGE_OFFSET) % 360 / 360 * #data.Spots)
            REVEL.DebugStringMinor("Stat wheel end spot:", data.WheelRotation, endSpot, data.Spots[endSpot])
            data.WinSpot = endSpot
            data.WinSpotColor = Color.Default

            if data.Spots[endSpot] == "Blank" then -- Lose
                REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
                data.TriggerPlayer:PlayExtraAnimation("Sad")
                if REVEL.GetShrineVanity() == 0 or not data.FirstLoss then
                    REVEL.forEach(REVEL.ENT.PRANK_SHOP:getInRoom(), function(e)
                        if not IsAnimOn(e:GetSprite(), "Empty") then
                            e:GetSprite():Play("Wheel_Lose", true)
                        end
                    end)
                end
                data.FirstLoss = true
            else -- Win
                REVEL.sfx:Play(SoundEffect.SOUND_THUMBSUP)
                data.TriggerPlayer:PlayExtraAnimation("Happy")
                REVEL.forEach(REVEL.ENT.PRANK_SHOP:getInRoom(), function(e)
                    if not IsAnimOn(e:GetSprite(), "Empty") then
                        e:GetSprite():Play("Wheel_Win", true)
                    end
                end)

                local runStats = revel.data.run.stats[REVEL.GetPlayerID(data.TriggerPlayer)]
                runStats[data.Spots[data.WinSpot]] = 
                    runStats[data.Spots[data.WinSpot]] + bal.StatUps[data.Spots[data.WinSpot]]
                data.TriggerPlayer:AddCacheFlags(REVEL.StatFlags[data.Spots[data.WinSpot]])
                data.TriggerPlayer:EvaluateItems()

                REVEL.DelayFunction(function()
                    StageAPI.PlayTextStreak(("%s up!"):format(StatNames[data.Spots[data.WinSpot]]))
                end, 20)
            end
        end
    elseif data.State == States.REWARD then
        data.Timer = data.Timer + 1

        if math.floor(data.Timer / 2) % 2 == 0 then
            data.WinSpotColor = Color.Default
        else
            data.WinSpotColor = Color(1,1,1,1, 0.25, 0.25, 0.25)
        end

        if data.Timer >= 45 then
            data.Timer = nil
            data.State = States.IDLE
            data.Spots[data.WinSpot] = "Blank"
            data.WinSpot = nil
            SaveSaveData(machine, data)
        end
    end
end

local function statwheel_PostMachineRender(machine, data, renderOffset)
    local basePos = Isaac.WorldToScreen(machine.Position)
        + renderOffset - REVEL.room:GetRenderScrollOffset()

    data.WheelSprite.Color = Color.Default
    data.WheelSprite:SetFrame("Idle", 0)
    data.WheelSprite.Rotation = data.WheelRotation
    data.WheelSprite:Render(basePos + WHEEL_OFFSET)

    -- print circle at spot 1
    -- IDebug.RenderCircle(basePos + WHEEL_OFFSET + Vector.FromAngle(data.WheelRotation + STAT_ANGLE_OFFSET - 90) * 25, true, 5)

    for i, stat in ipairs(data.Spots) do
        if stat ~= "Blank" then
            local frame = StatFrames[stat]
            data.WheelSprite:SetFrame("Icons", frame)
            data.WheelSprite.Rotation = data.WheelRotation + STAT_ANGLE_OFFSET + (i - 1) * 360 / #data.Spots

            if i == data.WinSpot then
                data.WheelSprite.Color = data.WinSpotColor
            else
                data.WheelSprite.Color = Color.Default
            end

            data.WheelSprite:Render(basePos + WHEEL_OFFSET)
        end
    end

    local spotProgress = ((data.WheelRotation + SPOT_EDGE_OFFSET) % (360 / #data.Spots)) / (360 / #data.Spots)
    local triggerAreaWidth = 0.1
    data.PrevSpotProgress = data.PrevSpotProgress or 0

    if spotProgress < triggerAreaWidth / 2
    or spotProgress > 1 - triggerAreaWidth / 2
    or data.PrevSpotProgress > spotProgress then
        if data.ArrowSprite.Rotation == 0 and not REVEL.game:IsPaused() then
            REVEL.sfx:Play(SoundEffect.SOUND_BEEP, 0.5)
        end

        data.ArrowSprite.Rotation = 10
    else
        data.ArrowSprite.Rotation = 0
    end
    data.PrevSpotProgress = spotProgress
    data.ArrowSprite:Render(basePos + ARROW_OFFSET)

    -- Price rendering
    REVEL.RenderVanityPrice(machine, renderOffset, REVEL.ShrineBalance.StatwheelPrice, data.Position, Vector(0, 1))
end

local function statwheel_PostMachineExplode(machine, data)
    return false
end

local function statwheel_PostMachineRespawn(machine, newMachine, data)
    newMachine:GetSprite():Play("Base", true)
end

-- Workaround for init not existing and so the machine setting up looks later
local function statwheel_PostRoomLoad(currentRoom, isFirstLoad, isExtraRoom)
    -- if isFirstLoad then
    local statwheelMetaents = currentRoom.Metadata:Search{ Name = "Vanity Statwheel Init Workaround" }
    local roomStatwheels

    for i, metaEntity in ipairs(statwheelMetaents) do
        local index = metaEntity.Index
        local pos = REVEL.room:GetGridPosition(index)

        roomStatwheels = roomStatwheels or REVEL.ENT.VANITY_STATWHEEL:getInRoom()
        local closest = REVEL.getClosestInTableFromPos(roomStatwheels, pos)
        local machine
        if closest and closest.Position:DistanceSquared(pos) < 5 then
            machine = closest
        else
            machine = REVEL.ENT.VANITY_STATWHEEL:spawn(pos, Vector.Zero)
            REVEL.DebugStringMinor("Spawning statwheel at", REVEL.room:GetGridIndex(pos))
        end
        REVEL.TryMachineInit(machine)
    end
    -- end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_EXPLODE, 1, statwheel_PostMachineExplode, REVEL.ENT.VANITY_STATWHEEL.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_RESPAWN, 1, statwheel_PostMachineRespawn, REVEL.ENT.VANITY_STATWHEEL.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_INIT, 1, statWheel_PostMachineInit, REVEL.ENT.VANITY_STATWHEEL.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_UPDATE, 1, statwheel_PostMachineUpdate, REVEL.ENT.VANITY_STATWHEEL.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_MACHINE_RENDER, 1, statwheel_PostMachineRender, REVEL.ENT.VANITY_STATWHEEL.variant)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, statwheel_PostRoomLoad)

end