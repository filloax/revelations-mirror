REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---@param player? EntityPlayer
---@param ignoreEffects? boolean
---@param onlyActiveShooting? boolean Ignore forced shooting due to marked and other items
function REVEL.IsShooting(player, ignoreEffects, onlyActiveShooting)
    player = player or REVEL.player

    if not ignoreEffects 
    and player:GetData().Frozen or player:GetData().TotalFrozen then
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

--Last input
function REVEL.GetLastFiringInput(player)
    local data = player:GetData()
    return data.__lastFireInput, data.__lastFireDir
end

local function lastFireInputPostPlayerUpdate(_, player)
    local data = player:GetData();
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
local forceInputQueueCount = 0 --inputaction gets quite laggy
local hasCallback = false

local function forceinputInputAction(_, ent, hook, action)
    if not ent or ent.Type ~= 1 then return end

    local data = ent:GetData()
    if data.ForceInputQueues and data.ForceInputQueues[hook] and data.ForceInputQueues[hook][action] then
        local value = data.ForceInputQueues[hook][action].val
        if not data.ForceInputQueues[hook][action].hold then
            forceInputQueueCount = forceInputQueueCount - 1
            data.ForceInputQueues[hook][action] = nil
        end
        return value
    end
end

function REVEL.ForceInput(player, buttonAction, hook, value, holdUntilNextUpdate, holdUntilRemovedID)
    local data = player:GetData()
    if not data.ForceInputQueues then
        data.ForceInputQueues = {}
    end
    if not data.ForceInputQueues[hook] then
        data.ForceInputQueues[hook] = {}
    end
    if holdUntilRemovedID
    and data.ForceInputHoldID 
    and data.ForceInputHoldID[holdUntilRemovedID] then
        REVEL.DebugStringMinor("WARN: There's already a forced input registered with that ID", holdUntilRemovedID)
        return
    end

    data.ForceInputQueues[hook][buttonAction] = {val = value, hold = holdUntilNextUpdate or holdUntilRemovedID}
    forceInputQueueCount = forceInputQueueCount + 1
    if holdUntilNextUpdate then
        data.ForceInputToStop = data.ForceInputToStop or {}

        table.insert(data.ForceInputToStop, {hook = hook, action = buttonAction})
    end
    if holdUntilRemovedID then
        data.ForceInputHoldID = data.ForceInputHoldID or {}
        data.ForceInputHoldID[holdUntilRemovedID] = {hook = hook, action = buttonAction}
    end

    -- Optimization as MC_INPUT_ACTION is ran far too often
    -- and has relatively weight
    if not hasCallback then
        revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, forceinputInputAction)
        hasCallback = true
    end
end

function REVEL.ClearForceInput(player, holdUntilRemovedID)
    local data = player:GetData()
    if data.ForceInputHoldID[holdUntilRemovedID] then
        local toRemove = data.ForceInputHoldID[holdUntilRemovedID]
        if data.ForceInputQueues[toRemove.hook] 
        and data.ForceInputQueues[toRemove.hook][toRemove.action] then
            data.ForceInputQueues[toRemove.hook][toRemove.action] = nil
            data.ForceInputHoldID[holdUntilRemovedID] = nil
            forceInputQueueCount = forceInputQueueCount - 1
        end
    end
end

local function forceinputPlayerUpdate(_, player)
    local data = player:GetData()
    if data.ForceInputQueues and data.ForceInputToStop then
        for i, toRemove in ripairs(data.ForceInputToStop) do
            if data.ForceInputQueues[toRemove.hook] 
            and data.ForceInputQueues[toRemove.hook][toRemove.action] then
                data.ForceInputQueues[toRemove.hook][toRemove.action] = nil
                forceInputQueueCount = forceInputQueueCount - 1
            end
            data.ForceInputToStop[i] = nil
        end
    end
end

local function forceinputCallbackCheckPostUpdate()
    if hasCallback and forceInputQueueCount <= 0 then
        revel:RemoveCallback(ModCallbacks.MC_INPUT_ACTION, forceinputInputAction)
        hasCallback = false
    end
end

local FireDirToAction = {
    [Direction.UP] = ButtonAction.ACTION_SHOOTUP,
    [Direction.DOWN] = ButtonAction.ACTION_SHOOTDOWN,
    [Direction.LEFT] = ButtonAction.ACTION_SHOOTLEFT,
    [Direction.RIGHT] = ButtonAction.ACTION_SHOOTRIGHT
}

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

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, lastFireInputPostPlayerUpdate)
revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, forceinputPlayerUpdate)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, forceinputCallbackCheckPostUpdate)
revel:AddCallback(ModCallbacks.MC_POST_RENDER, mouseBtnTriggeredPostRender)

end