local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
            REVEL.DuneTileProcessing(player)
            REVEL.SpawnFootprint(player, "gfx/effects/revel2/sand_footprint.anm2")
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if eff:GetData().Footprint then
        if eff.FrameCount > 30 then
            eff.Color = Color.Lerp(Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0)), Color(1, 1, 1, 0,conv255ToFloat( 0, 0, 0)), (eff.FrameCount - 30) / 30)
        end

        if eff.FrameCount > 60 then
            eff:Remove()
        end
    end
end, StageAPI.E.FloorEffect.V)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_AIR_MOVEMENT_LAND, 2, function(entity, airMovementData, fromPit)
    if REVEL.STAGE.Tomb:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.TombSandGfxRoomTypes, currentRoomType) then
            REVEL.SpawnLandingDust(entity, airMovementData, fromPit, 110, 90, 60)
        end
    end
end, EntityType.ENTITY_PLAYER)

end

REVEL.PcallWorkaroundBreakFunction()