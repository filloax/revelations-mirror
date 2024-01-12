local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

local SpikeState = require("lua.revelcommon.enums.SpikeState")

return function()

REVEL.TrapTypes.SpikeTrap = {
    OnSpawn = function(tile, data, index)
        if data.TrapTriggerCooldown == -1 then
            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom and currentRoom.Data.SpikeTrapSpikes then
                for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                    local grid = REVEL.room:GetGridEntity(grindex)
                    if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES and grid.State ~= SpikeState.SPIKE_ON and isDownAtStart then
                        grid.State = SpikeState.SPIKE_ON
                        local sprite = grid:GetSprite()
                        sprite:SetFrame("Summon", 11)
                    end
                end
            end
        end
    end,
    OnTrigger = function(tile, data, player)
        local currentRoom = StageAPI.GetCurrentRoom()
        -- if REVEL.room:IsClear() and not REVEL.RoomWasClear then
        --     return
        -- end

        if currentRoom and currentRoom.Data.SpikeTrapSpikes then
            for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                local grid = REVEL.room:GetGridEntity(grindex)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES then
                    if isDownAtStart then
                        grid.State = SpikeState.SPIKE_ON
                        local sprite = grid:GetSprite()
                        sprite:Play("Summon", true)
                    else
                        grid.State = SpikeState.SPIKE_OFF
                        local sprite = grid:GetSprite()
                        sprite:Play("Unsummon", true)
                    end
                end
            end
        end

        for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
            local tdata = trap:GetData()
            if tdata.TrapData then
                if tdata.TrapName == "SpikeTrap" then
                    tdata.TrapTriggerCooldown = -1
                elseif tdata.TrapName == "SpikeTrapOffset" then
                    tdata.TrapTriggerCooldown = 0
                end
            end
        end
    end,
    Disable = function()
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.Data.SpikeTrapSpikes then
            for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                local grid = REVEL.room:GetGridEntity(grindex)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES and grid.State ~= SpikeState.SPIKE_ON then
                    grid.State = SpikeState.SPIKE_ON
                    local sprite = grid:GetSprite()
                    sprite:Play("Unsummon", true)
                end
            end
        end


        for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
            local tdata = trap:GetData()
            if tdata.TrapData then
                if tdata.TrapName == "SpikeTrapOffset" then
                    tdata.TrapTriggerCooldown = -2
                elseif tdata.TrapName == "SpikeTrap" then
                    tdata.TrapTriggerCooldown = -2
                end
            end
        end
    end,
    SingleUse = true,
    Animation = "Spike"
}
REVEL.TrapTypes.SpikeTrapOffset = {
    OnSelect = function(trapData, index)
        trapData.Cooldown = -1
    end,
    OnSpawn = function(tile, data, index)
        if data.TrapTriggerCooldown ~= -1 then
            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom and currentRoom.Data.SpikeTrapSpikes then
                for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                    local grid = REVEL.room:GetGridEntity(grindex)
                    if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES and grid.State ~= SpikeState.SPIKE_OFF and not isDownAtStart then
                        grid.State = SpikeState.SPIKE_OFF
                        local sprite = grid:GetSprite()
                        sprite:SetFrame("Unsummon", 11)
                    end
                end
            end
        end
    end,
    OnTrigger = function(tile, data, player)
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.Data.SpikeTrapSpikes then
            for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                local grid = REVEL.room:GetGridEntity(grindex)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES then
                    if not isDownAtStart then
                        grid.State = SpikeState.SPIKE_ON
                        local sprite = grid:GetSprite()
                        sprite:Play("Summon", true)
                    else
                        grid.State = SpikeState.SPIKE_OFF
                        local sprite = grid:GetSprite()
                        sprite:Play("Unsummon", true)
                    end
                end
            end
        end

        for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
            local tdata = trap:GetData()
            if tdata.TrapData then
                if tdata.TrapName == "SpikeTrapOffset" then
                    tdata.TrapTriggerCooldown = -1
                elseif tdata.TrapName == "SpikeTrap" then
                    tdata.TrapTriggerCooldown = 0
                end
            end
        end
    end,
    Disable = function()
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom and currentRoom.Data.SpikeTrapSpikes then
            for grindex, isDownAtStart in pairs(currentRoom.Data.SpikeTrapSpikes) do
                local grid = REVEL.room:GetGridEntity(grindex)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES and grid.State ~= SpikeState.SPIKE_OFF then
                    grid.State = SpikeState.SPIKE_OFF
                    local sprite = grid:GetSprite()
                    sprite:Play("Unsummon", true)
                end
            end
        end


        for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
            local tdata = trap:GetData()
            if tdata.TrapData then
                if tdata.TrapName == "SpikeTrapOffset" then
                    tdata.TrapTriggerCooldown = -2
                elseif tdata.TrapName == "SpikeTrap" then
                    tdata.TrapTriggerCooldown = -2
                end
            end
        end
    end,
    SingleUse = true,
    Animation = "Spike"
}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 0, function(room)
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom then
        for i = 0, room:GetGridSize() do
            local grid = room:GetGridEntity(i)
            if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES 
            and currentRoom.Metadata:Has{Index = i, Name = "DisableOnClear"}
            and not IsAnimOn(grid:GetSprite(), "Unsummon") then
                grid.State = SpikeState.SPIKE_OFF
                local sprite = grid:GetSprite()
                sprite:Play("Unsummon", true)
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.room:IsClear() then
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            for i = 0, REVEL.room:GetGridSize() do
                local grid = REVEL.room:GetGridEntity(i)
                if grid and grid.Desc.Type == GridEntityType.GRID_SPIKES 
                and currentRoom.Metadata:Has{Index = i, Name = "DisableOnClear"} then
                    grid.State = SpikeState.SPIKE_OFF
                    local sprite = grid:GetSprite()
                    sprite:SetFrame("Unsummon", 11)
                end
            end
        end
    end
end)

end