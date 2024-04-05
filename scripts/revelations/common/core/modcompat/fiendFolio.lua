return function ()
    
-----------------
-- Fiend Folio --
-----------------


local function LoadFiendFolioCompatCh1()
    if not FiendFolio then return end

    --Glacier Rooms
    local ffRooms = {}
    local ffSRooms = {}
    for _, name in ipairs(REVEL.RoomEditors) do
        local rooms = REVEL.GetRoomsIfExistent("revel1.ff.glacier_"..name)
        local SRooms = REVEL.GetRoomsIfExistent("revel1.ff.glacier_special_"..name)
        if rooms then
            table.insert(ffRooms,{Name = name.."(FF)", Rooms = rooms})
        end
        if SRooms then
            table.insert(ffSRooms,{Name = name.."(FF)", Rooms = rooms})
        end
    end

    for _, roomName in ipairs(ffRooms) do
        REVEL.RoomLists.Glacier:AddRooms(roomName)
    end
    for _, roomName in ipairs(ffSRooms) do
        REVEL.RoomLists.GlacierSpecial:AddRooms(roomName)
    end

    --Glacier Reskins
    REVEL.mixin(REVEL.EntityReplacements["Glacier"].Replacements, {
        [15] = {
            [FiendFolio.FF.Drumstick.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_drumstick_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor,
            }
        },
        [115] = {
            [FiendFolio.FF.Edema.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_edema_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            }
        },
        [151] = {
            [FiendFolio.FF.Wimpy.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/wimpynew_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            }
        },
        [155] = {
            [FiendFolio.FF.Weaver.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/weaver_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor,
            }
        },
        [160] = {
            [FiendFolio.FF.Haunted.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_hauntedbody_glacier",
                    [1] = "reskins/ff/monster_hauntedhead_glacier"
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.Yawner.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_yawnerhead_glacier",
                    [1] = "reskins/ff/monster_yawnerbody_glacier"
                },
                SPLAT_COLOR = REVEL.SnowSplatColor
            },
            [FiendFolio.FF.Slim.Var] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/ff/slim_full_glacier",
                        [1] = "reskins/ff/slim_full_glacier",
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
                [2] = {
                    SPRITESHEET = {
                        [0] = "reskins/ff/limb_glacier",
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
            },
            [FiendFolio.FF.Meatwad.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/meatwad_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.MrHorf.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/glacier_greed_gaper_body",
                    [1] = "reskins/ff/monster_mrhorfhead_glacier",
                    [2] = "reskins/ff/monster_mrhorf_glacier"
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.MrHorfHead.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/glacier_horf",
                    [1] = "reskins/ff/monster_mrhorfhead_glacier",
                    [2] = "reskins/ff/monster_mrhorf_glacier"
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.Matte.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_matte_glacier",
                    [1] = "reskins/ff/monster_matte_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.Spitum.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_spitum_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
        },
        [450] = {
            [FiendFolio.FF.Fish.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/fishygaper_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
            },
            [FiendFolio.FF.Shirk.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/monster_shirk_glacier",
                },
                SPLAT_COLOR = REVEL.SnowSplatColor
            }
        },
        [666] = {
            [FiendFolio.FF.DrinkWorm.Var] = {
                SPRITESHEET = {
                    [0] = "reskins/ff/drink_worm_glacier",
                },
                SPLAT_COLOR = REVEL.WaterSplatColor,
            }
        },
    }, true)
end

local function LoadFiendFolioCompatCh2()
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
end

local LoadedFFCompat = false
if FiendFolio then
    LoadFiendFolioCompatCh1()
    LoadFiendFolioCompatCh2()
    LoadedFFCompat = true
else
    revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, function()
        if FiendFolio and not LoadedFFCompat then
            LoadFiendFolioCompatCh1()
            LoadFiendFolioCompatCh2()
            LoadedFFCompat = true
        end
    end)
end

end