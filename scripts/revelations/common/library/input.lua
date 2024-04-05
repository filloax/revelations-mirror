local RevCallbacks = require("scripts.revelations.common.enums.RevCallbacks")

return function()

---@param player? EntityPlayer
---@param ignoreEffects? boolean
---@param onlyActiveShooting? boolean Ignore forced shooting due to marked and other items
function REVEL.IsShooting(player, ignoreEffects, onlyActiveShooting)
    player = player or REVEL.player

    if not ignoreEffects 
    and REVEL.GetData(player).Frozen or REVEL.GetData(player).TotalFrozen then
        return false
    end

    if onlyActiveShooting then
        return Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) 
            or Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) 
            or Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) 
            or Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex)
    else
        local shootingInput = player:GetAimDirection()
        return math.abs(shootingInput.X) > 0.00001 or math.abs(shootingInput.Y) > 0.00001
    end
end

---@param player EntityPlayer
function REVEL.GetCorrectedFiringInput(player)
    if player == nil then
        error("GetCorrectedFiringInput | player nil", 2)
    end
    if player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then
        return player:GetAimDirection()
    else
        return REVEL.dirToVel[player:GetFireDirection()]
    end
end

---@param player EntityPlayer
function REVEL.GetLastFiringInput(player)
    local data = REVEL.GetData(player)
    return data.__lastFireInput, data.__lastFireDir
end

local function lastFireInputPostPlayerUpdate(_, player)
    local data = REVEL.GetData(player);
    if not data.__lastFireDir then
        data.__lastFireDir = Direction.NO_DIRECTION
        data.__lastFireInput = Vector.Zero
    end

    local dir = player:GetFireDirection()
    local input = REVEL.GetCorrectedFiringInput(player)

    if dir ~= Direction.NO_DIRECTION then
        data.__lastFireInput = input
        data.__lastFireDir = dir
    end
end
  
  
--Force input
local ForceInputQueueCount = 0 --inputaction gets quite laggy
local HasCallback = false
local DEBUG_FORCE_INFO = false

local function forceinputInputAction(_, ent, hook, action)
    if not ent or ent.Type ~= 1 then return end

    local data = REVEL.GetData(ent)

    if data.ForceInputQueues 
    and data.ForceInputQueues[hook] 
    and data.ForceInputQueues[hook][action] 
    and #data.ForceInputQueues[hook][action] > 0
    then
        local queue = data.ForceInputQueues[hook][action]
        local value = queue[1].val

        if DEBUG_FORCE_INFO and not REVEL.game:IsPaused() then
            REVEL.DebugLog("Hook status", hook, action, value, data.ForceInputQueues[hook][action], ent.FrameCount)
        end

        -- since only one input in the end can be applied in a queue if there is
        -- more than one element, still check every queued input's conditions for
        -- ending to avoid delays in forced input
        -- In other words, if two different things plan an input to remove on
        -- update end at the same time, only one will be applied but both will be
        -- removed later

        for i, item in ripairs(queue) do
            if not item.hold or (item.removeAfterUpdate and item.time < REVEL.game:GetFrameCount()) then
                table.remove(queue, i)
                ForceInputQueueCount = ForceInputQueueCount - 1
            end
        end

        return value
    end
end

local function ForceInputCallbackCheck()
    if HasCallback and ForceInputQueueCount <= 0 then
        REVEL.DebugStringMinor("Removing force input callback at", REVEL.game:GetFrameCount())
        revel:RemoveCallback(ModCallbacks.MC_INPUT_ACTION, forceinputInputAction)
        HasCallback = false
    end
end

---Force a certain input on this player, overriding any manual input in that hook & action.
---
---Acts similar to using ModCallbacks.MC_INPUT_ACTION, but doesn't need adding a callback
---for simple input and automatically manages adding/removing the callback when unused due
---to its performance impact.
---
---Arguments:
---
---* holdUntilNextUpdate: if set, will keep the input until next frame instead of applying it once.
---* holdUntilRemovedID: if set, will keep the input until [REVEL.ClearForceInput] is called with the same ID.
---@param player any
---@param buttonAction ButtonAction
---@param hook InputHook
---@param value any
---@param holdUntilNextUpdate? boolean
---@param holdUntilRemovedID? any
function REVEL.ForceInput(player, buttonAction, hook, value, holdUntilNextUpdate, holdUntilRemovedID)
    local data = REVEL.GetData(player)

    if holdUntilRemovedID
    and data.ForceInputHoldID 
    and data.ForceInputHoldID[holdUntilRemovedID] then
        REVEL.DebugStringMinor("WARN: There's already a forced input registered with that ID", holdUntilRemovedID)
        return
    end

    data.ForceInputQueues = data.ForceInputQueues or {}
    data.ForceInputQueues[hook] = data.ForceInputQueues[hook] or {}
    data.ForceInputQueues[hook][buttonAction] = data.ForceInputQueues[hook][buttonAction] or {}
    local queue = data.ForceInputQueues[hook][buttonAction]
    queue[#queue+1] = {
        val = value,
        hold = holdUntilNextUpdate or holdUntilRemovedID,
        time = REVEL.game:GetFrameCount(),
        removeAfterUpdate = holdUntilNextUpdate,
        id = holdUntilRemovedID,
    }

    ForceInputQueueCount = ForceInputQueueCount + 1

    if holdUntilRemovedID then
        data.ForceInputHoldID = data.ForceInputHoldID or {}
        data.ForceInputHoldID[holdUntilRemovedID] = {hook = hook, action = buttonAction}
    end

    if DEBUG_FORCE_INFO then
        REVEL.DebugStringMinor("ForceInput", HasCallback, holdUntilNextUpdate, holdUntilRemovedID, REVEL.game:GetFrameCount(), data.ForceInputQueues)
    end

    -- Optimization as MC_INPUT_ACTION is ran far too often
    -- and has relatively weight
    if not HasCallback then
        REVEL.DebugStringMinor("Adding force input callback at", REVEL.game:GetFrameCount())
        revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, forceinputInputAction)
        HasCallback = true
    end
end

---See [REVEL.ForceInput]
---@param player EntityPlayer
---@param holdUntilRemovedID any
function REVEL.ClearForceInput(player, holdUntilRemovedID)
    local data = REVEL.GetData(player)
    if data.ForceInputHoldID[holdUntilRemovedID] then
        local toRemove = data.ForceInputHoldID[holdUntilRemovedID]
        if data.ForceInputQueues[toRemove.hook] 
        and data.ForceInputQueues[toRemove.hook][toRemove.action] then
            local queue = data.ForceInputQueues[toRemove.hook][toRemove.action]
            for i, v in ripairs(queue) do
                if v.id == holdUntilRemovedID then
                    table.remove(queue, i)
                    ForceInputQueueCount = ForceInputQueueCount - 1
                end
            end
            data.ForceInputHoldID[holdUntilRemovedID] = nil
            ForceInputCallbackCheck()
        else
            REVEL.LogError("Couldn't clear input", holdUntilRemovedID, "as not set")
        end
    end
end

---@param player EntityPlayer
---@param action ButtonAction
---@return boolean
function REVEL.HasQueuedForcedInput(player, action)
    local data = REVEL.GetData(player)
    if data.ForceInputQueues then
        for _, queues in pairs(data.ForceInputQueues) do
            if queues[action] and #queues[action] > 0 then
                return true
            end
        end
    end
    return false
end

local FireDirToAction = {
    [Direction.UP] = ButtonAction.ACTION_SHOOTUP,
    [Direction.DOWN] = ButtonAction.ACTION_SHOOTDOWN,
    [Direction.LEFT] = ButtonAction.ACTION_SHOOTLEFT,
    [Direction.RIGHT] = ButtonAction.ACTION_SHOOTRIGHT
}

---@param dir Direction
---@return integer
function REVEL.GetButtonActionFromFireDirection(dir)
    return FireDirToAction[dir]
end
  
--mouse triggered
local wasPressed = {}
local wasPressedList = {}
  
function REVEL.IsMouseBtnTriggered(btn)
    local pressed = Input.IsMouseBtnPressed(btn)

    if pressed and not wasPressed[btn] then
        wasPressed[btn] = #wasPressedList+1
        wasPressedList[#wasPressedList+1] = btn
        return true
    end

    return false
end

local function mouseBtnTriggeredPostRender()
    for i,btn in ripairs(wasPressedList) do
        if not Input.IsMouseBtnPressed(btn) then
            wasPressed[btn] = nil
            wasPressedList[i] = nil
        end
    end
end

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, lastFireInputPostPlayerUpdate)
revel:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, ForceInputCallbackCheck)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, mouseBtnTriggeredPostRender)

end