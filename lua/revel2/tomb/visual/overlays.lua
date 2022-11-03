local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.OVERLAY.Tomb1 = StageAPI.Overlay("gfx/backdrop/revel2/tomb/dust_cloud.anm2", Vector(0.66,0.66), Vector(-10,-10))
REVEL.OVERLAY.Tomb2 = StageAPI.Overlay("gfx/backdrop/revel2/tomb/dust_cloud.anm2", Vector(-0.66,0.66), Vector(-2,-2))

local TombOverlays = {
    REVEL.OVERLAY.Tomb1,
    REVEL.OVERLAY.Tomb2
}

-- local tombglow = Sprite()
-- tombglow:Load("gfx/backdrop/revel2/tomb/glow.anm2", true)
-- tombglow:SetFrame("idle", 0)

StageAPI.AddCallback("Revelations", "PRE_TRANSITION_RENDER", 1, function()
    if REVEL.STAGE.Tomb:IsStage() and not StageAPI.IsHUDAnimationPlaying() then
        for _, overlay in ipairs(TombOverlays) do
            overlay:Render(false, REVEL.room:GetRenderScrollOffset())
        end

        --[[
        if REVEL.room:GetRoomShape() == RoomShape.ROOMSHAPE_1x1 then
            tombglow:Render(REVEL.room:GetCenterPos(), Vector.Zero, Vector.Zero)
        end]]
    end
end)
    
end

REVEL.PcallWorkaroundBreakFunction()