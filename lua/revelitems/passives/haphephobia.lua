REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-----------------
-- HAPHEPHOBIA --
-----------------

--[[
Every tear with a minimum internal cooldown of 1.5 seconds, a force shockwave pulses out from Isaac, travelling a very short distance. Any enemies or hostile tears very close to Isaac in that moment are knocked back, but not damaged. Tied to a soft cooldown on tears.
]]
revel.haph = {
    defRadius = 60,
    defFeather = 120,
    countDefEnt = 7,
    countDef = 45,
    ents = {}
}

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, p)
    local data = p:GetData()
    data.haphCounter = 0
end)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, p)
    local data = p:GetData()
    if data.haphCounter and data.haphCounter ~= 0 then
        data.haphCounter = math.max(0, data.haphCounter - 1)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, p)
    if not REVEL.game:IsPaused()
    and REVEL.ITEM.HAPHEPHOBIA:PlayerHasCollectible(p)
    and p:GetData().haphCounter == 0 
    and REVEL.IsShooting(p) then
        local enemies = Isaac.FindInRadius(p.Position,
                                            revel.haph.defFeather,
                                            EntityPartition.ENEMY)

        for i, e in ipairs(enemies) do
            local dist = e.Position:Distance(p.Position)
            local force = REVEL.Lerp(
                30, 
                1, 
                math.max(0, (dist - revel.haph.defRadius) / 
                    (revel.haph.defFeather - revel.haph.defRadius)
                )
            )
            REVEL.PushEnt(e, force, e.Position - p.Position, revel.haph.countDefEnt, p)
        end

        REVEL.SpawnCustomGlow(
            p, 
            "Wave",
            "gfx/itemeffects/revelcommon/haphephobia_wave.anm2"
        )
        p:GetData().haphCounter = math.max(
            25, 
            math.min(300, revel.haph.countDef * (p.MaxFireDelay / 10))
        )
    end

    --[[
    if REVEL.DEBUG and REVEL.ITEM.HAPHEPHOBIA:PlayerHasCollectible(p) then
    local pos = Isaac.WorldToScreen(p.Position)
    Isaac.RenderText(p:GetData().haphCounter, pos.X + 20, pos.Y - 50, 255, 255, 255, 255)
    end
    ]]
end)

end

REVEL.PcallWorkaroundBreakFunction()
