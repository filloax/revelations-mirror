REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-- Separate from definitions primarily so that all UNLOCKABLES will already be defined
local ch1DefaultModdata = {
  run = {
    level = {
      room = {},
    },

    
    chillrooms = {},
    chillRoomsInitiallyClear = {},

    NarcissusGlacierDefeated = false,

    seenDanteSatan = false,
  },

  seenNarcissusGlacier = false,
  seenLightableFireRoom = false,
  seenSnowmanRoom = false,
}

REVEL.mixin(REVEL.DEFAULT_MODDATA, ch1DefaultModdata, true)


Isaac.DebugString("Revelations: Loaded Default Save Data for Chapter 1!")
end