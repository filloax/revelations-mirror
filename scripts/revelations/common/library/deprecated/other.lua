return function ()
    

local callbacksCompareArg = {
    [ModCallbacks.MC_USE_ITEM] = true,
    [ModCallbacks.MC_USE_CARD] = true,
    [ModCallbacks.MC_USE_PILL] = true,
    [ModCallbacks.MC_PRE_USE_ITEM] = true
}
local callbacksCompareTypeArg = {
    [ModCallbacks.MC_NPC_UPDATE] = true,
    [ModCallbacks.MC_ENTITY_TAKE_DMG] = true,
    [ModCallbacks.MC_POST_NPC_INIT] = true,
    [ModCallbacks.MC_POST_NPC_RENDER] = true,
    [ModCallbacks.MC_POST_NPC_DEATH] = true,
    [ModCallbacks.MC_PRE_NPC_COLLISION] = true,
    [ModCallbacks.MC_POST_ENTITY_REMOVE] = true,
    [ModCallbacks.MC_POST_ENTITY_KILL] = true,
    [ModCallbacks.MC_PRE_NPC_UPDATE] = true
}
local callbacksCompareVariantArg = {
    [ModCallbacks.MC_FAMILIAR_UPDATE] = true,
    [ModCallbacks.MC_FAMILIAR_INIT] = true,
    [ModCallbacks.MC_POST_FAMILIAR_RENDER] = true,
    [ModCallbacks.MC_PRE_FAMILIAR_COLLISION] = true,
    [ModCallbacks.MC_POST_PICKUP_INIT] = true,
    [ModCallbacks.MC_POST_PICKUP_UPDATE] = true,
    [ModCallbacks.MC_POST_PICKUP_RENDER] = true,
    [ModCallbacks.MC_PRE_PICKUP_COLLISION] = true,
    [ModCallbacks.MC_POST_TEAR_INIT] = true,
    [ModCallbacks.MC_POST_TEAR_UPDATE] = true,
    [ModCallbacks.MC_POST_TEAR_RENDER] = true,
    [ModCallbacks.MC_PRE_TEAR_COLLISION] = true,
    [ModCallbacks.MC_POST_PROJECTILE_INIT] = true,
    [ModCallbacks.MC_POST_PROJECTILE_UPDATE] = true,
    [ModCallbacks.MC_POST_PROJECTILE_RENDER] = true,
    [ModCallbacks.MC_PRE_PROJECTILE_COLLISION] = true,
    [ModCallbacks.MC_POST_LASER_INIT] = true,
    [ModCallbacks.MC_POST_LASER_UPDATE] = true,
    [ModCallbacks.MC_POST_LASER_RENDER] = true,
    [ModCallbacks.MC_POST_KNIFE_INIT] = true,
    [ModCallbacks.MC_POST_KNIFE_UPDATE] = true,
    [ModCallbacks.MC_POST_KNIFE_RENDER] = true,
    [ModCallbacks.MC_PRE_KNIFE_COLLISION] = true,
    [ModCallbacks.MC_POST_EFFECT_INIT] = true,
    [ModCallbacks.MC_POST_EFFECT_UPDATE] = true,
    [ModCallbacks.MC_POST_EFFECT_RENDER] = true,
    [ModCallbacks.MC_POST_BOMB_INIT] = true,
    [ModCallbacks.MC_POST_BOMB_UPDATE] = true,
    [ModCallbacks.MC_POST_BOMB_RENDER] = true,
    [ModCallbacks.MC_PRE_BOMB_COLLISION] = true
}

local brokenCallbacks = {}

---@deprecated No longer needed
function REVEL.AddBrokenCallback(callbackId, fn, arg)
    if not brokenCallbacks[callbackId] then
        brokenCallbacks[callbackId] = {}
    end

    if not brokenCallbacks[callbackId].AddedCallback then
        revel:AddCallback(callbackId, function(...)
            local args = {...}
            --args[1] is the mod reference
            --args[2] would be the entity or item id
            for _, callback in ipairs(brokenCallbacks[callbackId]) do
                if not callback.Arg
                or (callback.Arg
                    and ((callbacksCompareArg[callbackId] and args[2] == callback.Arg)
                    or (callbacksCompareTypeArg[callbackId] and args[2].Type == callback.Arg)
                    or (callbacksCompareVariantArg[callbackId] and args[2].Variant == callback.Arg))
                ) then
                    local ret = callback.Function(...)
                    if ret ~= nil then
                        return ret
                    end
                end
            end
        end)
        brokenCallbacks[callbackId].AddedCallback = true
    end

    brokenCallbacks[callbackId][#brokenCallbacks[callbackId] + 1] = {
        Function = fn,
        Arg = arg
    }
end

end