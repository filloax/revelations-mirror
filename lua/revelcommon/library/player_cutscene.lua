REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--Valid table keys:
--TargetPositions = {position list, in order}
--Timeout
--DoOnEnd = function(player, data)
function REVEL.DoPlayerCutscene(player, tbl)
    local data = player:GetData()
    data.RevCutsceneData = tbl
end

function REVEL.CancelPlayerCutscene(player)
    player:GetData().RevCutsceneData = nil
end

local function playerCutscenePostPlayerUpdate(_, player)
    local data = player:GetData()
    local cdata = data.RevCutsceneData

    if cdata then
        local ended
        if cdata.Timeout then
            cdata.Timeout = cdata.Timeout - 1
            ended = cdata.Timeout <= 0
        end

        if not ended and cdata.TargetPositions then
            local targ = cdata.TargetPositions[1]
            if player.Position:DistanceSquared(targ) <= (player.Size + 10) ^ 2 then
                table.remove(cdata.TargetPositions, 1)
                ended = #cdata.TargetPositions < 1
            else
                local toTargDir = (targ - player.Position):Normalized() --inverted cause inputs are inverted for some reason
                
                --works with just 2 dirs
                REVEL.ForceInput(player, ButtonAction.ACTION_RIGHT, InputHook.GET_ACTION_VALUE, toTargDir.X, true)
                -- REVEL.ForceInput(player, ButtonAction.ACTION_LEFT, InputHook.GET_ACTION_VALUE, xl, true)
                REVEL.ForceInput(player, ButtonAction.ACTION_DOWN, InputHook.GET_ACTION_VALUE, toTargDir.Y, true)
                -- REVEL.ForceInput(player, ButtonAction.ACTION_UP, InputHook.GET_ACTION_VALUE, yu, true)
            end
        end

        if ended then
            data.RevCutsceneData = nil
            if cdata.DoOnEnd then
                cdata.DoOnEnd(player, data)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, playerCutscenePostPlayerUpdate)

end
REVEL.PcallWorkaroundBreakFunction()