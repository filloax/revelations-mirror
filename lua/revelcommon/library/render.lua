REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.IsRenderPassNormal()
    local renderMode = REVEL.room:GetRenderMode()

    return renderMode == RenderMode.RENDER_NORMAL 
        or renderMode == RenderMode.RENDER_WATER_ABOVE
        or renderMode == RenderMode.RENDER_NULL -- MC_POST_RENDER
end

function REVEL.IsRenderPassReflection()
    local renderMode = REVEL.room:GetRenderMode()
    return renderMode == RenderMode.RENDER_WATER_REFLECT
end

-- Normal in normal rooms, 
-- below water in water rooms
function REVEL.IsRenderPassFloor(fakeFloor)
    local renderMode = REVEL.room:GetRenderMode()

    if fakeFloor then
        return renderMode == RenderMode.RENDER_NORMAL 
            or renderMode == RenderMode.RENDER_WATER_REFLECT
    else
        return renderMode == RenderMode.RENDER_NORMAL 
            or renderMode == RenderMode.RENDER_WATER_REFRACT
    end
end

-- not boss screen, transition, etc
function REVEL.ShouldRenderHudElements()
    return REVEL.NotBossOrNightmare() 
        and REVEL.game:GetHUD():IsVisible()
end

-- mainly screenshake
function REVEL.GetHudTextOffset()
    return REVEL.game.ScreenShakeOffset
end

end