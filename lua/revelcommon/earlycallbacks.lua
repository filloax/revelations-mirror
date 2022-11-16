REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.EarlyCallbacks = {}

-- entity type/equivalent params in callbacks
-- that early-loaded callbacks use, specified here
-- before InitEarlyCallbacks to be able to already
-- add the callbacks in the mod
local OrderTypes = {
    EntityTakeDmg = {
        -1,
        1,
    },
    PostNPCInit = {

    },
}

-- add callbacks for each champion entity type
for etype, _ in pairs(REVEL.GetChampionableEntityIds()) do
    OrderTypes.PostNPCInit[#OrderTypes.PostNPCInit+1] = etype
end


local Order

function REVEL.InitEarlyCallbacks()
    Order = {
        EntityTakeDmg = {
            [-1] = {
                REVEL.EarlyCallbacks.trackDamageBuffer_Early_EntityTakeDmg,
            },
            [1] = {
                REVEL.EarlyCallbacks.masochism_EntityTakeDmg_Player,
            },
        },
        PostPlayerInit = {
            REVEL.EarlyCallbacks.runLoaded_PostPlayerInit,
        },
        PostNPCInit = {
            
        },
    }

    for etype, func in pairs(REVEL.EarlyCallbacks.revNpcChampions_PostNpcInit) do
        if not Order.PostNPCInit[etype] then
            Order.PostNPCInit[etype] = {}
        end

        table.insert(Order.PostNPCInit[etype], func)
    end
end

local function RunCallbacks(tbl, breakOnFirstReturn, ...)
    local ret
    for _, callback in ipairs(tbl) do
        local success
        success, ret = pcall(callback, revel, ...)
        if not success then
            REVEL.DebugLog(tostring(ret), REVEL.TryGetTraceback(false, true))
        elseif ret ~= nil and breakOnFirstReturn then
            return ret
        end
    end
    return ret
end

-- no param callbacks

local function early_PostPlayerInit(_)
    RunCallbacks(Order.PostPlayerInit, false)
end

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, early_PostPlayerInit)

-- param callbacks

for _, param in ipairs(OrderTypes.EntityTakeDmg) do
    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, damage, flags, source, damageCountdown)
        return RunCallbacks(Order.EntityTakeDmg[param], true, entity, damage, flags, source, damageCountdown)
    end, param)
end

for _, param in ipairs(OrderTypes.PostNPCInit) do
    revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
        RunCallbacks(Order.PostNPCInit[param], false, npc)
    end, param)
end

Isaac.DebugString("Revelations: Loaded early callbacks!")

end