local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.STAGE.Tomb:IsStage() and math.random(1, 500) == 1 then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
            local pos = REVEL.room:GetRandomPosition(1)
            if REVEL.room:GetGridCollisionAtPos(pos) == 0 then
                REVEL.SpawnDecoration(pos, Vector.Zero, "Idle", "gfx/effects/revel2/sand_drop.anm2", nil, -1000)
            end
        end
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
            REVEL.DuneTileProcessing(player)
            REVEL.SpawnFootprint(player, "gfx/effects/revel2/sand_footprint.anm2", true)
        end
    end
end)

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, entity, airMovementData, fromPit, oldZVelocity)
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
            REVEL.SpawnLandingDust(entity, oldZVelocity, fromPit, 110, 90, 60)
        end
    end
end, EntityType.ENTITY_PLAYER)

end