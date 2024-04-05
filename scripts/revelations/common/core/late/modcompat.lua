local SubModules = REVEL.PrefixAll("scripts.revelations.common.core.modcompat.", {
    "eid",
    "encyclopedia",
    "fiendfolio",
})

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

REVEL.RunLoadFunctions(SubLoadFunctions)

-- Smaller mod compats

------------------------
-- Music mod callback --
------------------------

if MMC then
    REVEL.musicNoMMC = MusicManager()
    REVEL.music = MMC.Manager()
end


local function compatEnts()

----------------------
-- Potato For Scale --
----------------------

REVEL.COMP_ENTS = {
    POTATO_FOR_SCALE = REVEL.ent("Potato Dummy")
}

end

revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, compatEnts)

if Isaac.GetPlayer(0) then
    compatEnts()
end

------------------------
-- Enhanced Boss Bars --
------------------------

local function eString(ent)
    return ent.id .. "." .. ent.variant
end

local function LoadHPBars()
    if HPBars.BossIgnoreList then
        HPBars.BossIgnoreList[eString(REVEL.ENT.CHUCK_ICE_BLOCK)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_SNOWPILE)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_STALAGMITE)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.WILLIWAW)] = function(entity) 
            if entity.SubType > 0 then return true end end
        HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_SNOWPILE)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.NARCISSUS_MONSTROS_TOOTH)] = function(entity) return true end

        HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_CRICKET)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_TAMMY)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_GUPPY)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_MOXIE)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.ARAGNID_INNARD)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.SARCOPHAGUTS_HEAD)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.JEFFREY_BABY)] = function(entity) return true end
        HPBars.BossIgnoreList[eString(REVEL.ENT.LOVERS_LIB_PD)] = function(entity) return true end
    end
    REVEL.HPBarsCompatLoaded = true
end

if HPBars then
    LoadHPBars()
else
    revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, function()
        if HPBars and not REVEL.HPBarsCompatLoaded then
            LoadHPBars()
        end
    end)
end

Isaac.DebugString("Revelations: Loaded Mod Compatibility!")


end