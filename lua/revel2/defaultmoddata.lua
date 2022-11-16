REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-- Separate from definitions primarily so that all UNLOCKABLES will already be defined
local ch2DefaultModData = {
  run = {
    level = {
        room = {

        },
		tombMausoleumDoorPayments = 0
    },

    NarcissusTombDefeated = false,

    isTomb = false,
    prank_glacier = {
        hp = -1,
        pickups = {}
    },
    prank_tomb = {
        hp = -1,
        pickups = {}
    },


    jeffreyDefeated = false,
    jeffreySeen = false,
    jeffreyHealthPercentage = 100,
  },

  sandySeenWarIntro = false,
  ragtimeSeenSpecialIntro = false,
  seenNarcissusTomb = false,
  seenDuneRoom = false,
}

REVEL.mixin(REVEL.DEFAULT_MODDATA, ch2DefaultModData, true)


Isaac.DebugString("Revelations: Loaded Default Save Data for Chapter 2!")
end