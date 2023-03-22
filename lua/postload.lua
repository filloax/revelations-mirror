local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"

REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()
    -- TEMPORARY: CHECK WHICH REV CALLBACK BREAKS THE CALL STACK
    -- WHEN IT SHOULDN'T
    --#region CheckReturns
    if not _G.REV_CHECK_NO_RETURN_CALLBACKS then
        local AffectOtherMods = false --REVEL.DEBUG

        local CallbacksWithReturn = {
            ModCallbacks.MC_USE_ITEM,
            ModCallbacks.MC_ENTITY_TAKE_DMG, 
            ModCallbacks.MC_POST_CURSE_EVAL,
            ModCallbacks.MC_INPUT_ACTION,
            ModCallbacks.MC_GET_CARD,
            ModCallbacks.MC_GET_SHADER_PARAMS,
            ModCallbacks.MC_EXECUTE_CMD,
            ModCallbacks.MC_PRE_USE_ITEM,
            ModCallbacks.MC_PRE_ENTITY_SPAWN,
            ModCallbacks.MC_PRE_FAMILIAR_COLLISION,
            ModCallbacks.MC_PRE_NPC_COLLISION,
            ModCallbacks.MC_PRE_PLAYER_COLLISION,
            ModCallbacks.MC_POST_PICKUP_SELECTION,
            ModCallbacks.MC_PRE_PICKUP_COLLISION,
            ModCallbacks.MC_PRE_TEAR_COLLISION,
            ModCallbacks.MC_PRE_PROJECTILE_COLLISION,
            ModCallbacks.MC_PRE_KNIFE_COLLISION,
            ModCallbacks.MC_PRE_BOMB_COLLISION,
            ModCallbacks.MC_PRE_GET_COLLECTIBLE,
            ModCallbacks.MC_POST_GET_COLLECTIBLE,
            ModCallbacks.MC_GET_PILL_COLOR,
            ModCallbacks.MC_GET_PILL_EFFECT,
            ModCallbacks.MC_GET_TRINKET,
            ModCallbacks.MC_PRE_NPC_UPDATE,
            ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD,
            ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN,
            ModCallbacks.MC_PRE_ENTITY_DEVOLVE,
        }

        local CallbacksWithoutReturn = {}
        for k, callbackId in pairs(ModCallbacks) do
            if not REVEL.includes(CallbacksWithReturn, callbackId) then
                CallbacksWithoutReturn[#CallbacksWithoutReturn+1] = callbackId
            end
        end

        for _, callbackId in ipairs(CallbacksWithoutReturn) do
            local callbacks = Isaac.GetCallbacks(callbackId)
            for _, callback in ipairs(callbacks) do
                if AffectOtherMods or callback.Mod == revel then
                    local origFunc = callback.Function

                    callback.Function = function(...)
                        local ret = origFunc(...)

                        if ret ~= nil then
                            REVEL.DebugLog("Function from mod", callback.Mod.Name, "returned a value in callback", callbackId, "when it shouldn't:", ret)
                            if debug then
                                local info = debug.getinfo(origFunc)
                                REVEL.DebugLog("Func from", info.source, "@" .. tostring(info.linedefined))
                            end
                        end
                    end
                end
            end
        end

        _G.REV_CHECK_NO_RETURN_CALLBACKS = true
    end
    --#rendregion

    Isaac.RunCallback(RevCallbacks.POST_LOAD)

    Isaac.DebugString("Revelations: Loaded Post Load Code!")
end