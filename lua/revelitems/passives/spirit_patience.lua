local RevCallbacks = require("lua.revelcommon.enums.RevCallbacks")

return function()

------------------------
-- SPIRIT OF PATIENCE --
------------------------

--[[
When you stand still, start shooting lasers every (MaxFireDelay*1.5) at the nearest enemy.
]]
revel.patience = {
    color = Color(0, 1, 1, 1, conv255ToFloat(0, 180, 255)),
    delMult = 1.2 -- mult of maxfiredelay from the player's
}

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.PATIENCE:PlayerHasCollectible(player) then
        local data = player:GetData()
        if not data.patienceCnt then
            data.patienceCnt = 5
            data.patienceDel = 0
        end

        if player:GetMovementDirection() == Direction.NO_DIRECTION then
            if data.patienceCnt <= 0 then
                if data.patienceCnt == 0 then
                    data.patienceCnt = -1
                    SFXManager():Play(REVEL.SFX.SPIRIT_OF_PATIENCE_OPEN_EYE,
                                        1, 0, false, 1)
                    player:TryRemoveNullCostume(REVEL.COSTUME.PATIENCE[1])
                    player:AddNullCostume(REVEL.COSTUME.PATIENCE[2])
                end

                -- FIRE
                if data.patienceDel <= 0 and not data.Frozen then
                    data.patienceDel =
                        player.MaxFireDelay * revel.patience.delMult

                    local t = REVEL.getClosestEnemy(player, false, true,
                                                    true, true)

                    if t then
                        local lazur =
                            player:FireTechLaser(player.Position,
                                                    LaserOffset.LASER_TRACTOR_BEAM_OFFSET,
                                                    t.Position -
                                                        player.Position, false,
                                                    true)
                        lazur:GetSprite().Color = revel.patience.color
                    end
                else
                    data.patienceDel = data.patienceDel - 1
                end
            else
                if data.patienceCnt == 4 then
                    player:AddNullCostume(REVEL.COSTUME.PATIENCE[1])
                end

                data.patienceCnt = data.patienceCnt - 1
            end

        else
            if data.patienceCnt < 0 then
                player:TryRemoveNullCostume(REVEL.COSTUME.PATIENCE[2])
            elseif data.patienceCnt < 5 then
                player:TryRemoveNullCostume(REVEL.COSTUME.PATIENCE[1])
            end
            data.patienceCnt = 5
        end
    end
end)

end
