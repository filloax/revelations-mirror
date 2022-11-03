REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

    local TaintedWarningSprite = REVEL.LazyLoadRoomSprite{
        ID = "TaintedWarning",
        Anm2 = "gfx/ui/achievement/revelcommon/idle_warning.anm2",
        OnCreate = function(sprite)
            sprite:SetFrame("Idle", 0)
        end,
    }

    local DisabledPlayers = {
        [REVEL.CHAR.DANTE_B.Type] = true,
        [REVEL.CHAR.SARAH_B.Type] = true,
    }

    local DoRenderWarning = false

    local function taintedWarningPlayerCheck(_, player)
        if DisabledPlayers[player:GetPlayerType()] then
            DoRenderWarning = true
            player.ControlsEnabled = false
        end
    end

    local function taintedWarningRender()
        if not REVEL.game:IsPaused() and REVEL.game:GetFrameCount() % 20 == 0 then
            DoRenderWarning = false
            for _, player in ipairs(REVEL.players) do
                if DisabledPlayers[player:GetPlayerType()] then
                    DoRenderWarning = true
                    break
                end
            end
        end

        if DoRenderWarning then
            local pos = Isaac.WorldToRenderPosition(REVEL.room:GetCenterPos() + Vector(0, -50))
            
            -- render text below sprite, which should be covered by it unless
            -- the sprite failed to load
            Isaac.RenderText("Warning sprite didn't load correctly!", pos.X - 100, pos.Y, 1, 1, 1, 1)
            Isaac.RenderText("Still, tainted characters are a", pos.X - 100, pos.Y + 20, 1, 1, 1, 1)
            Isaac.RenderText("work in progress.", pos.X - 100, pos.Y + 40, 1, 1, 1, 1)

            TaintedWarningSprite:Render(pos)
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, taintedWarningPlayerCheck)
    revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, taintedWarningPlayerCheck)
    revel:AddCallback(ModCallbacks.MC_POST_RENDER, taintedWarningRender)
end

REVEL.PcallWorkaroundBreakFunction()