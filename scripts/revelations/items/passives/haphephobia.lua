local RevCallbacks = require("scripts.revelations.common.enums.RevCallbacks")

return function()
-----------------
-- HAPHEPHOBIA --
-----------------

--[[
Every tear with a minimum internal cooldown of 1.5 seconds, a force shockwave pulses out from Isaac, travelling a very short distance. Any enemies or hostile tears very close to Isaac in that moment are knocked back, but not damaged. Tied to a soft cooldown on tears.
]]
local Haphephobia = {
    defRadius = 60,
    defFeather = 120,
    countDefEnt = 7,
    countDef = 45,
    ents = {}
}

revel:AddCallback(RevCallbacks.POST_BASE_PLAYER_INIT, function(_, p)
    local data = REVEL.GetData(p)
    data.haphCounter = 0
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, p)
    local data = REVEL.GetData(p)
    if data.haphCounter and data.haphCounter ~= 0 then
        data.haphCounter = math.max(0, data.haphCounter - 1)
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, p)
    if not REVEL.game:IsPaused()
    and REVEL.ITEM.HAPHEPHOBIA:PlayerHasCollectible(p)
    and REVEL.GetData(p).haphCounter == 0 
    and REVEL.IsShooting(p) then
        local enemies = Isaac.FindInRadius(p.Position,
                                            Haphephobia.defFeather,
                                            EntityPartition.ENEMY)

        for i, e in ipairs(enemies) do
            local dist = e.Position:Distance(p.Position)
            local force = REVEL.Lerp(
                30, 
                1, 
                math.max(0, (dist - Haphephobia.defRadius) / 
                    (Haphephobia.defFeather - Haphephobia.defRadius)
                )
            )
            REVEL.PushEnt(e, force, e.Position - p.Position, Haphephobia.countDefEnt, p)
        end

        REVEL.SpawnCustomGlow(
            p, 
            "Wave",
            "gfx/itemeffects/revelcommon/haphephobia_wave.anm2"
        )
        REVEL.GetData(p).haphCounter = math.max(
            25, 
            math.min(300, Haphephobia.countDef * (p.MaxFireDelay / 10))
        )
    end

    --[[
    if REVEL.DEBUG and REVEL.ITEM.HAPHEPHOBIA:PlayerHasCollectible(p) then
    local pos = Isaac.WorldToScreen(p.Position)
    Isaac.RenderText(REVEL.GetData(p).haphCounter, pos.X + 20, pos.Y - 50, 255, 255, 255, 255)
    end
    ]]
end)

end
