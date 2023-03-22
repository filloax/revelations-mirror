REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- Fiend Folio --
-----------------

local function LoadFiendFolioCompat(typeLoaded)
    if not FiendFolio then return end

    --Tomb Rooms
    local ffRooms = {}
    local ffSRooms = {}
    for _, name in ipairs(REVEL.RoomEditors) do
        local rooms = REVEL.GetRoomsIfExistent("revel2.ff.tomb_"..name)
        local SRooms = REVEL.GetRoomsIfExistent("revel2.ff.tomb_special_"..name)
        if rooms then
            table.insert(ffRooms,{Name = name.."(FF)", Rooms = rooms})
        end
        if SRooms then
            table.insert(ffSRooms,{Name = name.."(FF)", Rooms = rooms})
        end
    end

    for _, roomName in ipairs(ffRooms) do
        REVEL.RoomLists.Tomb:AddRooms(roomName)
    end
    for _, roomName in ipairs(ffSRooms) do
        REVEL.RoomLists.TombSpecial:AddRooms(roomName)
    end

    --Tomb Reskins
    REVEL.mixin(REVEL.EntityReplacements["Tomb"].Replacements, {
        [21] = {
            [FiendFolio.FF.CreepyMaggot.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/creepymaggot_tomb",
                },
            }
        },
        [114] = {
            [FiendFolio.FF.Frowny.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/Frowny_tomb",
                },
            }
        },
        [115] = {
            [FiendFolio.FF.Edema.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_edema_tomb",
                },
            }
        },
        [155] = {
            [FiendFolio.FF.WeaverSr.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/weaver-2_tomb",
                },
            }
        },
        
        [160] = {
            [FiendFolio.FF.Centipede.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_centipede_tomb",
                },
            },
            [FiendFolio.FF.MilkTooth.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_babytooth_tomb",
                },
            },
            [FiendFolio.FF.Carrier.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_carrier_tomb",
                },
            },
            [FiendFolio.FF.SuperGrimace.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/super_grimace_tomb",
                },
            }
        },
        [227] = {
            [FiendFolio.FF.MrBones.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/welcomeaboardmatey_tomb",
                    [1] = "reskins/ff/rattlemebones_tomb",
                },
            }
        },
        [244] = {
            [FiendFolio.FF.BoneWorm.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/boneworm_tomb",
                },
            }
        },
        [750] = {
            [FiendFolio.FF.Ragurge.Var] = {
                ANM2 = "reskins/ff/monster_ragurge_tomb",
            },
            [FiendFolio.FF.Unpawtunate.Var] = {
                ANM2 = "reskins/ff/kitty kannon_tomb",
            },
            [FiendFolio.FF.UnpawtunateSkull.Var] = {
                ANM2 = "reskins/ff/kitty skull_tomb",
            },
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