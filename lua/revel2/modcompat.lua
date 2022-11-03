REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- Fiend Folio --
-----------------

local function LoadFiendFolioCompat(typeLoaded)
    if not FiendFolio then return end

    --Tomb Rooms
    REVEL.SimpleAddRoomsSet("Tomb", "Tomb", nil, "revel2.ff.tomb_", REVEL.RoomEditors, {"Test"})
    REVEL.SimpleAddRoomsSet("TombSpecial", "TombSpecial", nil, "revel2.ff.tomb_special_", REVEL.RoomEditors, {"Test"})

    --Tomb Reskins
    REVEL.mixin(REVEL.EntityReplacements["Tomb"].Replacements, {
        [FiendFolio.FF.WeaverSr.ID] = {
            [FiendFolio.FF.WeaverSr.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/weaver-2_tomb",
                },
            }
        },
        [FiendFolio.FF.Centipede.ID] = {
            [FiendFolio.FF.Centipede.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_centipede_tomb",
                },
            }
        },
        [FiendFolio.FF.Ragurge.ID] = {
            [FiendFolio.FF.Ragurge.Var] = {
                ANM2 = "reskins/ff/monster_ragurge_tomb",
            }
        },
    }, true)

    REVEL.mixin(REVEL.RAG_FAMILY, {
        [FiendFolio.FF.Ragurge.ID] = {FiendFolio.FF.Ragurge.Var}
    }, true)

    REVEL.mixin(REVEL.TypeToRagAnim,{
        [FiendFolio.FF.Ragurge.ID] = {"Ragurge"}
    }, true)

    REVEL.FiendFolioCompatLoaded = REVEL.FiendFolioCompatLoaded or {}
    REVEL.FiendFolioCompatLoaded[typeLoaded] = true
end

local loadType = 3
if FiendFolio then
    LoadFiendFolioCompat(loadType)
else
    revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        if FiendFolio and not (REVEL.FiendFolioCompatLoaded or REVEL.FiendFolioCompatLoaded[loadType]) then
            LoadFiendFolioCompat(loadType)
        end
    end)
end

Isaac.DebugString("Revelations: Loaded Mod Compatibility for Chapter 2!")
end
REVEL.PcallWorkaroundBreakFunction()