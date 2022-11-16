REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------------------
-- MISC DECORATIONS EFFECT --
-----------------------------

---@class DecorationConfig
---@field Anim string
---@field Sprite string
---@field Time integer
---@field FadeOut integer
---@field Finish fun(e: EntityEffect, data: table, spr: Sprite)
---@field Update fun(e: EntityEffect, data: table, spr: Sprite)
---@field SetFrame integer
---@field RemoveOnAnimEnd boolean
---@field Color Color
---@field Start fun(e: EntityEffect, data: table, spr: Sprite)
---@field SkipFrames integer
---@field Floor boolean

--[[
    Spawn an effect to play an anm2, that has no impact on the game (unless the func does something), until time runs out or Finish anm2 event is triggered
    When it vanishes (before fade if it's set), it runs func with itself as an arg
    pos, vel: as expected
    parent: will be set as the effect's Parent and will be followed, can be nil
    Anim: the animation that will be played's name
    Sprite: the path to an anm2 (default sprite: Fire)
    Time: the timeout for the effect, can be nil or negative for no timeout
    FadeOut: the duration of the fade out after time runs out, can be nil or negative for no fadeout
    Finish: the func that will be run, can be nil for no func. Args are (e, data, spr)
    Update: function that will be called on update. Args are (e, data, spr)
    SetFrame: sets this frame if specified
    RemoveOnAnimEnd: remove after the animation specified in anim is finished
    Color: if specified, changes color
    Start: function run at start, params (e, data, spr) (meant for being used with the table version of SpawnDecoration, it's not very useful otherwise)
    SkipFrames: animation frames to skip

    Floor: is rendered on floor (via StageAPI, so updates work)
]]
---@param pos Vector
---@param vel Vector
---@param tbl DecorationConfig
---@param parent? Entity
---@return EntityEffect
---@return Sprite
---@return table data
function REVEL.SpawnDecorationFromTable(pos, vel, tbl, parent)
    local eff
    if not tbl.Floor then
        eff = REVEL.ENT.DECORATION:spawn(pos, vel, parent or REVEL.player):ToEffect()
    else
        eff = StageAPI.SpawnFloorEffect(pos, vel, parent or REVEL.player, tbl.Sprite, not not tbl.Sprite, REVEL.ENT.DECORATION.variant):ToEffect()
    end

    local spr = eff:GetSprite()
    local data = eff:GetData()

    if parent then
        eff:FollowParent(parent)
        eff.Parent = parent
    end

    if not tbl.Floor and tbl.Sprite then
        spr:Load(tbl.Sprite, true)
    end

    data.anim = tbl.Anim or "default"
    data.time = tbl.Time or -1
    data.fadeOut = tbl.FadeOut or -1
    data.fadeOutMax = data.fadeOut

    if data.anim ~= "none" then
        if not tbl.SetFrame then
            if (tbl.RemoveOnAnimEnd == nil and data.time < 0)
            or tbl.RemoveOnAnimEnd then
                data.removeOnAnimEnd = true
            end
            spr:Play(data.anim, true)
        else
            spr:SetFrame(data.anim, tbl.SetFrame)
        end
    end
    if tbl.SkipFrames then
        REVEL.SkipAnimFrames(spr, tbl.SkipFrames)
    end

    data.func = tbl.Finish
    data.updatefunc = tbl.Update

    if tbl.Color then
        spr.Color = tbl.Color
    end

    data.managedDecoration = true

    data.DecoTableId = tostring(tbl)

    if tbl.Start then
        tbl.Start(eff, data, spr)
    end

    return eff, spr, data
end

local argsStruct = {}

-- Deprecated, more or less
function REVEL.SpawnDecoration(pos, vel, anim, sprite, parent, time, fadeOut, finish, update, setFrame, removeOnAnimEnd, color, start, skipFrames)
    if type(anim) == "table" then
        return REVEL.SpawnDecorationFromTable(pos, vel, anim, parent)
    end

    if anim == -1 then anim = nil end
    if sprite == -1 then sprite = nil end
    if parent == -1 then parent = nil end
    if time == -1000 then removeOnAnimEnd = true end
    if time == -1 then time = nil end
    if finish == -1 then finish = nil end
    if update == -1 then update = nil end
    if setFrame == -1 then setFrame = nil end
    if removeOnAnimEnd == -1 then removeOnAnimEnd = nil end
    if color == -1 then color = nil end
    if start == -1 then start = nil end
    if skipFrames == -1 then skipFrames = nil end

    argsStruct.Anim = anim
    argsStruct.Sprite = sprite
    argsStruct.Time = time
    argsStruct.FadeOut = fadeOut
    argsStruct.Finish = finish
    argsStruct.Update = update
    argsStruct.SetFrame = setFrame
    argsStruct.RemoveOnAnimEnd = removeOnAnimEnd
    argsStruct.Color = color
    argsStruct.Start = start
    argsStruct.SkipFrames = skipFrames

    return REVEL.SpawnDecorationFromTable(pos, vel, argsStruct, parent)
end

function REVEL.GetDecorationsOfTable(tbl)
    local out = {}
    for _, effect in ipairs(REVEL.roomEffects) do
        if effect:GetData().DecoTableId == tostring(tbl) then
            out[#out + 1] = effect
        end
    end
    return out
end

--Update the effect
REVEL.ENT.DECORATION:addCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(e)
    local data = e:GetData()
    if data.managedDecoration then
    --  REVEL.DebugToString({e.Index, data.time, data.fadeOut})
        local spr = e:GetSprite()
        if data.updatefunc then 
            data.updatefunc(e, data, spr) 
        end
        if spr:WasEventTriggered("Finish") or (data.time == 0 and data.fadeOut <= 0) or (data.removeOnAnimEnd and spr:IsFinished(data.anim)) then
            if data.func then 
                data.func(e, data, spr)
            end
            e:Remove()
        elseif data.time > 0 then
            data.time = data.time-1
        elseif data.time == 0 then
            data.fadeOut = data.fadeOut - 1
            local col = REVEL.CloneColor(spr.Color)
            col.A = col.A * data.fadeOut / data.fadeOutMax
            spr.Color = col
        end
    end
end)

--generic invisible effect
function REVEL.SpawnInvisibleEntity(pos, vel, parent, time, finish, update, start)
    return REVEL.SpawnDecoration(pos, vel, "none", "stageapi/none.anm2", parent, time, -1, finish, update, nil, false, nil, start)
end

--Takes in fields with the same names as the arguments of the above function, but with the initial capitalized (for consistency with similar stuff in the mod)
--Ie Sprite Anim etc
local ArgOrderInvEnt = {"Parent", "Time", "Finish", "Update", "Start"}

function REVEL.SpawnInvisibleEntityFromTable(pos, vel, tbl, parent)
    local args = REVEL.map(ArgOrderInvEnt, function(value)
        if tbl[value] ~= nil then
            return tbl[value]
        else
            return -1 --nil values make table.unpack stop
        end
    end)
    if parent then args[3] = parent end
  
    return REVEL.SpawnInvisibleEntity(pos, vel, table.unpack(args))
end

end