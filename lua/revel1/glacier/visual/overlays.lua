local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevSettings       = require("lua.revelcommon.enums.RevSettings")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    local cloud, snow, heavy = "gfx/backdrop/revel1/glacier/cloud.anm2", "gfx/backdrop/revel1/glacier/snow.anm2", "gfx/backdrop/revel1/glacier/snow_heavy.anm2"
    REVEL.OVERLAY = {
        Glacier1 = StageAPI.Overlay(cloud, Vector(1,1)),
        Glacier2 = StageAPI.Overlay(cloud, Vector(0.66,0.66), Vector(-10,-10)),
        Glacier3 = StageAPI.Overlay(cloud, Vector(-0.66,0.66), Vector(-2,-2)),
        Glacier4 = StageAPI.Overlay(snow, Vector(0,1)),
        Glacier5 = StageAPI.Overlay(snow, Vector(0.66,0.66), Vector(-10,-10)),
        Glacier6 = StageAPI.Overlay(snow, Vector(-0.66,0.66), Vector(-2,-2)),
        Glacier7 = StageAPI.Overlay(heavy, Vector(3,1.5)),
        Glacier8 = StageAPI.Overlay(heavy, Vector(-1.00,1.00), Vector(-10,-10)),
        Glacier9 = StageAPI.Overlay(heavy, Vector(-0.66,1.36), Vector(-2,-2))
    }

    local ChillOverlays = {
        REVEL.OVERLAY.Glacier1,
        REVEL.OVERLAY.Glacier2,
        REVEL.OVERLAY.Glacier3
    }
    
    local ChillFadingOverlays = {
        REVEL.OVERLAY.Glacier1
    }
    
    local GlacierNormalOverlays = {
        REVEL.OVERLAY.Glacier2,
        REVEL.OVERLAY.Glacier3
    }
    
    local ChillSnowOverlays = REVEL.ConcatTables(ChillOverlays, {
        REVEL.OVERLAY.Glacier5,
        REVEL.OVERLAY.Glacier6,
        REVEL.OVERLAY.Glacier7
    })
    
    local ChillFadingSnowOverlays = REVEL.ConcatTables(ChillFadingOverlays, {
        REVEL.OVERLAY.Glacier7
    })
    
    local GlacierNormalSnowOverlays = REVEL.ConcatTables(GlacierNormalOverlays, {
        REVEL.OVERLAY.Glacier4,
        REVEL.OVERLAY.Glacier5,
        REVEL.OVERLAY.Glacier6
    })
    
    function REVEL.GetChillOverlays()
        if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY then
            return ChillSnowOverlays
        else
            return ChillOverlays
        end
    end
    
    function REVEL.GetChillFadingOverlays()
        if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY then
            return ChillFadingSnowOverlays
        else
            return ChillFadingOverlays
        end
    end
    
    function REVEL.GetGlacierNormalOverlays()
        if revel.data.snowflakesMode == RevSettings.SNOW_MODE_BOTH or revel.data.snowflakesMode == RevSettings.SNOW_MODE_OVERLAY then
            return GlacierNormalSnowOverlays
        else
            return GlacierNormalOverlays
        end
    end

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1,  function(newRoom, revisited)
        local roomType = StageAPI.GetCurrentRoomType()
        if REVEL.STAGE.Glacier:IsStage() and (REVEL.includes(REVEL.GlacierGfxRoomTypes, roomType) or not StageAPI.InExtraRoom) then
            if REVEL.includes(REVEL.ChillRoomTypes, roomType) and not REVEL.IsChilly(newRoom) then
                for _, overlay in ipairs(ChillFadingSnowOverlays) do
                    overlay:SetAlpha(0)
                end
            else
                for _, overlay in ipairs(ChillFadingSnowOverlays) do
                    overlay:SetAlpha(1)
                end
            end
        end
    end)    

    StageAPI.AddCallback("Revelations", "PRE_TRANSITION_RENDER", 1, function()
        if revel.data and revel.data.overlaysMode == 3 then --the if revel.data is to prevent logspam in case the mod is reloaded ingame and it errors
            return
        end
    
        if not StageAPI.IsHUDAnimationPlaying() then
            local room = REVEL.room
            local level = REVEL.game:GetLevel()
            local listIndex = StageAPI.GetCurrentListIndex()
    
            local roomType = StageAPI.GetCurrentRoomType()
            if REVEL.STAGE.Glacier:IsStage() and (REVEL.includes(REVEL.GlacierGfxRoomTypes, roomType) or not StageAPI.InExtraRoom) then
                if (REVEL.includes(REVEL.ChillRoomTypes, roomType) or REVEL.DukeAuraStartup) then
                    if REVEL.DukeAuraStartup then
                        for _, overlay in ipairs(REVEL.GetChillFadingOverlays()) do
                            overlay:SetAlpha(REVEL.DukeAuraStartup / 120)
                        end
                    end
    
                    for _, overlay in ipairs(REVEL.GetChillOverlays()) do
                        if not ((HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_DARKNESS) or revel.data.overlaysMode == 2) 
                        and overlay.Sprite:GetFilename() == cloud) then
                            overlay:Render(false, REVEL.room:GetRenderScrollOffset())
                        end
                    end
                else
                    for _, overlay in ipairs(REVEL.GetGlacierNormalOverlays()) do
                        if not ((HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_DARKNESS) or revel.data.overlaysMode == 2) 
                        and overlay.Sprite:GetFilename() == cloud) then
                            overlay:Render(false, REVEL.room:GetRenderScrollOffset())
                        end
                    end
                end
            end
        end
    end)    
end

REVEL.PcallWorkaroundBreakFunction()