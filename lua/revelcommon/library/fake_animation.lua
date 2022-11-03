REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local FakeAnimations = {}

function REVEL.CreateFakeAnimation(name, frames)
    FakeAnimations[name] = frames or {}
end

function REVEL.AddFakeAnimationFrames(name, frames)
    if #frames == 0 then
        frames = {frames}
    end

    for _, frame in ipairs(frames) do
        FakeAnimations[name][#FakeAnimations[name] + 1] = frame
    end
end

function REVEL.GetDataFromFakeAnimationFrame(name, frame)
    local animation = FakeAnimations[name]

    local currentFrameDataIndex
    local percentThroughFrame
    local frameNumber = 0
    for i, frameData in ipairs(animation) do
        frameNumber = frameNumber + frameData.Length
        if frame <= frameNumber then
            currentFrameDataIndex = i
            percentThroughFrame = (frameData.Length - (frameNumber - frame)) / frameData.Length
            break
        end
    end

    Isaac.DebugString(tostring(frame) .. ", " .. tostring(percentThroughFrame))

    local currentFrame = animation[currentFrameDataIndex]
    local nextFrame = animation[currentFrameDataIndex + 1]

    local usingAttributes = {}
    for k, v in pairs(currentFrame) do
        usingAttributes[k] = v
    end

    if currentFrame.Interpolate and nextFrame then
        for k, v in pairs(nextFrame) do
            if currentFrame[k] and type(v) ~= "boolean" then
                usingAttributes[k] = REVEL.Lerp(currentFrame[k], v, percentThroughFrame)
            end
        end
    end

    return usingAttributes.Scale, usingAttributes.Position
end

function REVEL.AdjustNPCFromFakeAnimationFrame(npc, name, frame)
    local scale, pos = REVEL.GetDataFromFakeAnimationFrame(name, frame)
    if scale then
        npc.SpriteScale = scale
    end

    if pos then
        npc.SpriteOffset = pos
    end
end

function REVEL.AdjustSpriteFromFakeAnimationFrame(sprite, name, frame)
    local scale, pos = REVEL.GetDataFromFakeAnimationFrame(name, frame)
    if scale then
        sprite.Scale = scale
    end

    if pos then
        sprite.Offset = pos
    end
end


end

REVEL.PcallWorkaroundBreakFunction()