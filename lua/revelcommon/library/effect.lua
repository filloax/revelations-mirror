REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local DefaultTracerOffset = Vector(0, -20) -- hardcoded offset within the laser tracers

---@param position Vector
---@param duration integer
---@param direction Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
local function SpawnDeathsHeadTracer(position, duration, direction, color, parent, scale)
    local effect = Isaac.Spawn(1000, EffectVariant.GENERIC_TRACER, 0, position, Vector.Zero, parent):ToEffect()
    effect.PositionOffset = -DefaultTracerOffset
    local data = effect:GetData()
    effect.LifeSpan = duration
    effect.Timeout  = effect.LifeSpan
    effect.TargetPosition = direction -- tracers use relative position from their start pos
    if color then
        effect.Color = color
    end
    if parent then
        effect.Parent = parent
        effect:FollowParent(parent)
    end
    if scale then
        if type(scale) == "number" then
            effect.SpriteScale = Vector.One * scale
        else
            effect.SpriteScale = scale
        end
    end

    -- It flashes at full opacity for a frame
    -- go around it this way
    effect:Update()

    return effect
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param direction Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracerAngleDir(position, duration, direction, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracerAngleDir: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracerAngleDir: duration nil!", 2)
    REVEL.Assert(direction, "MakeLaserTracerAngleDir: direction nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, direction, color, parent, scale)
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param targetPosition Vector # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracer(position, duration, targetPosition, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracer: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracer: duration nil!", 2)
    REVEL.Assert(targetPosition, "MakeLaserTracer: targetPosition nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, targetPosition - position, color, parent, scale)
end

---Spawns a Death's Head tracer with simplifed params
-- Warning: this will end up at a fixed length depending on direction due to vanilla logic
---@param position Vector
---@param duration integer
---@param angle number # absolute room position, unlike the tracer property which is relative to the start
---@param color? Color
---@param parent? Entity
---@param scale? number | Vector
---@return EntityEffect
function REVEL.MakeLaserTracerAngle(position, duration, angle, color, parent, scale)
    REVEL.Assert(position, "MakeLaserTracerAngle: position nil!", 2)
    REVEL.Assert(duration, "MakeLaserTracerAngle: duration nil!", 2)
    REVEL.Assert(angle, "MakeLaserTracerAngle: angle nil!", 2)

    return SpawnDeathsHeadTracer(position, duration, Vector.FromAngle(angle), color, parent, scale)
end

---comment
---@param parent EntityEffect
---@param offset number
---@param scale? number | Vector
---@return EntityEffect
function REVEL.SpawnLaserTracerExtension(parent, offset, scale)
    REVEL.Assert(parent, "SpawnLaserTracerExtension: parent nil!", 2)
    REVEL.Assert(offset, "SpawnLaserTracerExtension: offset nil!", 2)

    local pos = parent.Position + parent.TargetPosition:Resized(offset)
    local e = SpawnDeathsHeadTracer(
        pos, 
        parent.LifeSpan, 
        parent.TargetPosition, 
        parent.Color, 
        nil, 
        parent.SpriteScale * (scale or 1)
    )
    e.Timeout = parent.Timeout

    e:GetData().TracerExtension = {
        Parent = parent,
        Offset = offset,
    }

    return e
end

---@param effect EntityEffect
local function tracerExtension_PostEffectUpdate(_, effect)
    local data = effect:GetData()

    if data.TracerExtension then
        ---@type EntityEffect
        local parent = data.TracerExtension.Parent

        effect.Timeout = parent.Timeout
        effect.Color = parent.Color

        effect.TargetPosition = parent.TargetPosition

        effect.Position = parent.Position + parent.TargetPosition:Resized(data.TracerExtension.Offset)

        effect.Velocity = parent.Velocity
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, tracerExtension_PostEffectUpdate, EffectVariant.GENERIC_TRACER)

end