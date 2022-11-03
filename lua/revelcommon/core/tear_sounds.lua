local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- This doesn't work on Repentance due to
-- custom sounds not working, meaning tears
-- are just silent for now

--[[
Basically, when you want to replace the tear impact sound for whatever reason, stopping it is wonky and doesn't awlays work, 
sometimes letting parts of it play, and also stopping the player's own sounds (when what you want to stop is for instance a monsnow tear)
So, we replace the sound with our own custom one, make all the various SFXManager function calls that would play and stop tearimpacts 
use the custom sound instead, and also play it when it would normally play (tear death) except for our own exceptions, like monsnow tears
]]

--TEARS
if not revelOldRemoveFunc then
    ---@diagnostic disable-next-line: lowercase-global
    revelOldRemoveFunc = APIOverride.GetCurrentClassFunction(EntityTear, "Remove") --fix sound being played for tears that are manually removed too
    --needs to be a global or it gets reset on reload
    APIOverride.OverrideClassFunction(EntityTear, "Remove", function(e)
            --REVEL.DebugToString({"Removed", e.Type})
        e:GetData().__manuallyRemoved = true
        revelOldRemoveFunc(e)
    end)
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    local shouldPlay,data = true, ent:GetData()

    local ret = StageAPI.CallCallbacks(RevCallbacks.PRE_TEARIMPACTS_SOUND, true, ent, data, ent:GetSprite())
    local vol = 0.8
    if ret ~= nil and ret == false then
        shouldPlay = false
    elseif type(ret) == 'number' then
        vol = ret
    end
  
    if shouldPlay and not data.__manuallyRemoved and not REVEL.game:IsPaused() then
      REVEL.sfx:Play(REVEL.SFX.TEARIMPACTS, vol, 0, false, 0.95 + math.random()*0.1)
      REVEL.sfx:Play(REVEL.SFX.SPLATTER, 0.3 * vol / 0.8, 0, false, 1)
  --    REVEL.DebugToString("Played tearImpacts!")
    end
  end, EntityType.ENTITY_TEAR)

StageAPI.AddCallback("Revelations", RevCallbacks.TEAR_UPDATE_INIT, 1,  function(tear) --not using tears_fire so this works on first update and so after all TEARS_FIRE callbacks
    local shouldPlay, data = true, tear:GetData()
  

    local ret = StageAPI.CallCallbacks(RevCallbacks.PRE_TEARS_FIRE_SOUND, true, tear, data, tear:GetSprite())

    local vol = 0.6
    if ret ~= nil and ret == false then
        shouldPlay = false
    elseif type(ret) == 'number' then
        vol = ret
    end
  
    if shouldPlay then
        REVEL.sfx:Play(REVEL.SFX.TEARS_FIRE, vol, 0, false, 1)
    end
end)

--handle default game tears
StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARIMPACTS_SOUND, 0, function(tear, data, sprite)
    local variant = tear.Variant

    return (variant >= 0
    and variant ~= TearVariant.TOOTH
    and variant ~= TearVariant.BOBS_HEAD
    and variant ~= TearVariant.CHAOS_CARD
    and variant ~= TearVariant.NAIL
    and variant ~= TearVariant.DIAMOND
    and variant ~= TearVariant.COIN
    and variant ~= TearVariant.STONE
    and variant ~= TearVariant.NAIL_BLOOD
    and variant ~= TearVariant.RAZOR
    and variant ~= TearVariant.BONE
    and variant ~= TearVariant.BLACK_TOOTH
    and variant <= 38)
end)

--PROJECTILES
if not revelOldRemoveFunc then
    ---@diagnostic disable-next-line: lowercase-global
    revelOldRemoveFunc = APIOverride.GetCurrentClassFunction(EntityProjectile, "Remove") --fix sound being played for tears that are manually removed too
        --needs to be a global or it gets reset on reload
        APIOverride.OverrideClassFunction(EntityProjectile, "Remove", function(e)
            --REVEL.DebugToString({"Removed", e.Type})
        e:GetData().__manuallyRemoved = true
        revelOldRemoveFunc(e)
    end)
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    local shouldPlay,data = true, ent:GetData()
  
    local ret = StageAPI.CallCallbacks("REV_PRE_PROJIMPACTS_SOUND", true, ent:ToProjectile(), data, ent:GetSprite())
    if ret == false then
        shouldPlay = false
    end
  
    if shouldPlay and not data.__manuallyRemoved and not REVEL.game:IsPaused() then
      local volMult = type(ret) == "number" and ret or 1
      REVEL.sfx:Play(REVEL.SFX.SPLATTER, 0.3 * volMult, 0, false, 1)
  --    REVEL.DebugToString("Played projImpacts!")
    end
end, EntityType.ENTITY_PROJECTILE)
  
--handle default game projectiles
StageAPI.AddCallback("Revelations", RevCallbacks.PRE_PROJIMPACTS_SOUND, 0, function(proj, data, sprite)
    local variant = proj.Variant

    return (variant >= 0
    and variant ~= ProjectileVariant.PROJECTILE_BONE
    and variant ~= ProjectileVariant.PROJECTILE_FIRE
    and variant ~= ProjectileVariant.PROJECTILE_COIN
    and variant <= 7)
end)
    
end

REVEL.PcallWorkaroundBreakFunction()