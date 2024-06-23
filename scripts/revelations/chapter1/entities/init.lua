local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

REVEL.WaterSplatColor = Color(0, 0.2, 0.8, 1, conv255ToFloat(0,20,70))
REVEL.SnowSplatColor = Color(0.2, 0.45, 1, 1, 0.3, 0.5, 0.7)
REVEL.YellowSplatColor = Color(0,0,0,1, conv255ToFloat(170,170,0))
REVEL.BluePoopSplatColor = Color(0,0,0,1, conv255ToFloat(32,44,65))
REVEL.CoalSplatColor = Color(0,0,0,1, conv255ToFloat(50,50,50))

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.ICE_HAZARD_GAPER.id,
    RemoveOnRemove = true
})

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.GRILL_O_WISP.id,
    Variant = REVEL.ENT.GRILL_O_WISP.variant
})

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.STALACTRITE.id,
    Variant = REVEL.ENT.STALACTRITE.variant
})

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.HOCKEY_PUCK.id,
    Variant = REVEL.ENT.HOCKEY_PUCK.variant
})


--------------------------
-- RESKINS/REPLACEMENTS --
--------------------------
do
    REVEL.EntityReplacements["Glacier"] = {
        MonsterPath = "gfx/monsters/revel1/",
        BossPath = "gfx/bosses/revel1/",
        Replacements = {

            --traps
            [EntityType.ENTITY_POKY] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_poky"
                    }
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_slide"
                    }
                }
            },
            [EntityType.ENTITY_WALL_HUGGER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_wall_hugger"
                    }
                }
            },
            [EntityType.ENTITY_PITFALL] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_pitfall"
                    }
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_pitfall"
                    }
                },
                [2] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_pitfall"
                    }
                }
            },

            --bosses
            [EntityType.ENTITY_FISTULA_BIG] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_fistula"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_FISTULA_MEDIUM] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_fistula"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_FISTULA_SMALL] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_fistula"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_MEGA_FATTY] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = {
                            [-1] = "reskins/glacier_mega_fatty",
                            [1] = "reskins/glacier_mega_fatty_champ_1",
                            [2] = "reskins/glacier_mega_fatty_champ_2",
                        },
                        [1] = {
                            [-1] = "reskins/glacier_mega_fatty",
                            [1] = "reskins/glacier_mega_fatty_champ_1",
                            [2] = "reskins/glacier_mega_fatty_champ_2",
                        },
                        [2] = "reskins/glacier_mega_fatty",
                        [3] = "reskins/glacier_mega_fatty",
                        [4] = "reskins/glacier_mega_fatty",
                        [5] = "reskins/glacier_mega_fatty",
                        [6] = "reskins/glacier_mega_fatty",
                        [7] = "reskins/glacier_mega_fatty"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_MEGA_MAW] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = {
                            [-1] = "reskins/glacier_mega_maw",
                            [1] = "reskins/glacier_mega_maw_champ_1",
                            [2] = "reskins/glacier_mega_maw_champ_2",
                        },
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_LARRYJR] = { --flurry jr
                [0] = {
                    SPRITESHEET = {
                        [0] = {
                            [-1] = "reskins/glacier_larry_jr",
                            [1] = "reskins/glacier_larry_jr_champ_1",
                            [2] = "reskins/glacier_larry_jr_champ_2",
                        },
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            -- [EntityType.ENTITY_MONSTRO] = { --monsnow
            --     [0] = {
            --         SPRITESHEET = {
            --             [0] = "reskins/glacier_monstro"
            --         },
            --         SPLAT_COLOR = REVEL.SnowSplatColor
            --     }
            -- },
            [EntityType.ENTITY_DUKE] = { --duke of flakes
                [0] = {
                SPRITESHEET = {
                    [0] = {
                        [-1] = "reskins/glacier_duke_of_flies",
                        [1] = "reskins/glacier_duke_of_flies_champ_1",
                        [2] = "reskins/glacier_duke_of_flies_champ_2",
                    },
                    [2] = {
                        [-1] = "reskins/glacier_duke_of_flies",
                        [1] = "reskins/glacier_duke_of_flies_champ_1",
                        [2] = "reskins/glacier_duke_of_flies_champ_2",
                    },
                    [3] = {
                        [-1] = "reskins/glacier_duke_of_flies",
                        [1] = "reskins/glacier_duke_of_flies_champ_1",
                        [2] = "reskins/glacier_duke_of_flies_champ_2",
                    },
                },
                SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },

            --sins
            [EntityType.ENTITY_LUST] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_lust"
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_lust"
                }
            },
            [EntityType.ENTITY_WRATH] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_wrath"
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_wrath"
                }
            },
            [EntityType.ENTITY_PRIDE] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_pride",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_pride",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_GREED] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_greed",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_greed",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_SLOTH] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_sloth",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_sloth",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_GLUTTONY] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_gluttony",
                    ANIMATION = "WalkVert",
                    ANIMATION_FRAME = 0,
                    SPLAT_COLOR = REVEL.WaterSplatColor
                },
                [1] = {
                    ANM2 = "reskins/sins/glacier_super_gluttony",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_ENVY] = {
                [0] = {
                    ANM2 = "reskins/sins/glacier_envy",
                    ANIMATION = "Walk0",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [10] = {
                    ANM2 = "reskins/sins/glacier_envy",
                    ANIMATION = "Walk1",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [20] = {
                    ANM2 = "reskins/sins/glacier_envy",
                    ANIMATION = "Walk2",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [30] = {
                    ANM2 = "reskins/sins/glacier_envy",
                    ANIMATION = "Walk3",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },

                [1] = {
                    ANM2 = "reskins/sins/glacier_super_envy",
                    ANIMATION = "Walk0",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [11] = {
                    ANM2 = "reskins/sins/glacier_super_envy",
                    ANIMATION = "Walk1",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [21] = {
                    ANM2 = "reskins/sins/glacier_super_envy",
                    ANIMATION = "Walk2",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                },
                [31] = {
                    ANM2 = "reskins/sins/glacier_super_envy",
                    ANIMATION = "Walk3",
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },

            --monsters
            [EntityType.ENTITY_CHARGER] = {
                [0] = {
                    [-1] = {
                        SPRITESHEET = {
                            [0] = "reskins/glacier_charger"
                        },
                        SPLAT_COLOR = REVEL.WaterSplatColor
                    },
                    [1] = true --does nothing (takes priority over -1)
                }
            },
            [EntityType.ENTITY_MAGGOT] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_maggot"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_KEEPER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_keeper"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_WALL_CREEP] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_wall_creep"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_BONY] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_bony_body",
                        [1] = "reskins/glacier_bony_head"
                    }
                }
            },
            [EntityType.ENTITY_TUMOR] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_tumor"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_ROUND_WORM] = {
                [0] = {
                    ANM2 = "reskins/glacier_round_worm",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_GRUB] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_grub"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_NIGHT_CRAWLER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_night_crawler"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_SPITY] = {
                [0] = {
                    ANM2 = "reskins/glacier_spitty",
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_NULLS] = {
                [0] = {
                    ANM2 = "reskins/glacier_null"
                }
            },
            [EntityType.ENTITY_IMP] = {
                [0] = {
                    ANM2 = "reskins/glacier_imp"
                }
            },
            [EntityType.ENTITY_ONE_TOOTH] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_one_tooth"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [EntityType.ENTITY_BLACK_GLOBIN_HEAD] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_black_globin_head"
                    }
                }
            },
            [EntityType.ENTITY_FATTY] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_fatty",
                        [1] = "reskins/glacier_fatty"
                    }
                }
            },
            [EntityType.ENTITY_GREED_GAPER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_greed_gaper_body",
                        [1] = "reskins/glacier_greed_gaper"
                    },
                    SPLAT_COLOR = REVEL.SnowSplatColor
                }
            },
            [EntityType.ENTITY_GAPER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "frost_bodies_1",
                        [1] = {"reskins/glacier_gaper1","reskins/glacier_gaper2","reskins/glacier_gaper3"}
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_DEATH = true
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "frost_bodies_1",
                        [1] = {"reskins/glacier_gaper1","reskins/glacier_gaper2","reskins/glacier_gaper3"}
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_DEATH = true
                }
            },
            [EntityType.ENTITY_HORF] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_horf"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_DEATH = true
                }
            },
            [EntityType.ENTITY_GUSHER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "frost_bodies_2",
                        [1] = "reskins/effect_bloodgush_glacier",
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_DEATH = true
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "frost_bodies_2",
                        [1] = "reskins/effect_bloodgush_glacier",
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_DEATH = true
                }
            },
            [EntityType.ENTITY_HOPPER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_hopper_leaper"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_ANIMATION = "Hop",
                    ICECREEP_FRAME = 18,
                    -- ICECREEP_SCALE = 1.35
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_trite"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                }
            },
            [EntityType.ENTITY_LEAPER] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_hopper_leaper"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_ANIMATION = "Hop",
                    ICECREEP_FRAME = 18,
                    -- ICECREEP_SCALE = 1.35,
                    ICECREEP_ANIMATION_2 = "BigJumpDown",
                    ICECREEP_FRAME_2 = 20,
                    ICECREEP_SCALE_2 = 2.0
                }
            },
            [EntityType.ENTITY_CLOTTY] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_clotty"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_STATE = 4,
                    ICECREEP_FRAME = 12
                },
                [2] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_iblob"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor,
                    ICECREEP_STATE = 4,
                    ICECREEP_FRAME = 12
                }
            },
            --[[
            [EntityType.ENTITY_DIP] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_dip"
                    },
                    SPLAT_COLOR = REVEL.BluePoopSplatColor
                },
                [1] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_dip_corn"
                    },
                    SPLAT_COLOR = REVEL.BluePoopSplatColor
                }
            },
            ]]
            [REVEL.ENT.DRIFTY.id] = {
                [REVEL.ENT.DRIFTY.variant] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_drifty"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
            [REVEL.ENT.BROTHER_BLOODY.id] = {
                [REVEL.ENT.BROTHER_BLOODY.variant] = {
                    SPRITESHEET = {
                        [0] = "reskins/glacier_brother_bloody"
                    },
                    SPLAT_COLOR = REVEL.WaterSplatColor
                }
            },
        }
    }

    --shopkeepers
    local keeperVariantToAnm2 = {
        [0] = "gfx/effects/revel1/glacier_shopkeeper.anm2",
        [1] = "gfx/effects/revel1/glacier_shopkeeper_hanging.anm2",
        [3] = "gfx/effects/revel1/glacier_shopkeeper_special.anm2",
        [4] = "gfx/effects/revel1/glacier_shopkeeper_hanging_special.anm2"
    }
    revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
        if REVEL.STAGE.Glacier:IsStage() and keeperVariantToAnm2[npc.Variant] and REVEL.room:GetType() ~= RoomType.ROOM_SUPERSECRET then
            npc:GetSprite():Load(keeperVariantToAnm2[npc.Variant], true)
        end
    end, EntityType.ENTITY_SHOPKEEPER)

    --gusher projectiles
    revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
        if REVEL.STAGE.Glacier:IsStage() and proj:IsDead() and proj.SpawnerType == EntityType.ENTITY_GUSHER then
            REVEL.SpawnIceCreep(proj.Position, proj)
        end
    end)

    local horfBloodShootColor = Color(1, 1, 1, 0.6, 0.05, 0.05, 0.3)
    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
        if effect.Variant == EffectVariant.BLOOD_EXPLOSION and REVEL.STAGE.Glacier:IsStage() then
            local horf = Isaac.FindInRadius(effect.Position, 1, EntityPartition.ENEMY)[1]
            if horf and horf.Type == EntityType.ENTITY_HORF then
                effect:GetSprite():ReplaceSpritesheet(4, "gfx/effects/revel1/effect_002_bloodpoof_alt_glacier.png")
                effect:GetSprite():LoadGraphics()
                effect.Color = horfBloodShootColor
                effect.SpawnerEntity = horf
            end
        end
    end)

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
        if REVEL.STAGE.Glacier:IsStage() and effect.SpawnerEntity and effect.SpawnerEntity.Type == EntityType.ENTITY_HORF then --blood explosion
            effect.Color = horfBloodShootColor
        end
    end, EffectVariant.BLOOD_EXPLOSION)

end

-- Round Worm (unique animations for appearing out of ice)

local ROUND_WORM_BASE_SPRITE = "gfx/monsters/revel1/reskins/glacier_round_worm"
local ROUND_WORM_ICE_SPRITE = "gfx/monsters/revel1/reskins/glacier_round_worm_ice"

---@param npc EntityNPC
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == 0 and REVEL.STAGE.Glacier:IsStage() and StageAPI.GetCurrentRoom() then
        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
        local onIceTile = REVEL.Glacier.CheckIce(npc, StageAPI.GetCurrentRoom(), true)

        if not data.RoundWormOnIce and onIceTile then
            for i = 0, 3 do
                REVEL.ReplaceEnemySpritesheet(npc, ROUND_WORM_ICE_SPRITE, i, false)
            end
            sprite:LoadGraphics()
            data.RoundWormOnIce = true            
        elseif data.RoundWormOnIce and not onIceTile then
            for i = 0, 3 do
                REVEL.ReplaceEnemySpritesheet(npc, ROUND_WORM_BASE_SPRITE, i, false)
            end
            sprite:LoadGraphics()
            data.RoundWormOnIce = false
        end
    end
end, EntityType.ENTITY_ROUND_WORM)


-----------------------
-- FROSTY PROJECTILE --
-----------------------

REVEL.FrostyProjectileImmunity = {
    [EntityType.ENTITY_FIREPLACE] = true,
}

--REPLACE PROJ POOFS
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, function(p, data, spr, spawner, grandpa)
    if REVEL.GetData(spawner).isFrostyProjectile then
        spr:ReplaceSpritesheet(0, "gfx/effects/revel1/frost_bulletatlas.png")
        spr:LoadGraphics()

        if REVEL.GetData(spawner).IsPiss then
            spr.Color = REVEL.YellowSplatColor
        elseif REVEL.GetData(spawner).IsSnowball then
            spr.Color = Color(1,1,1,1,conv255ToFloat(200,200,255))
        elseif REVEL.GetData(spawner).IsStrawberry then
            spr.Color = Color(1,1,1,1,conv255ToFloat(158,76,40))
        elseif REVEL.GetData(spawner).IsChocolate then
            spr.Color = Color(1,1,1,1,conv255ToFloat(255,184,100))
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.PROJECTILE_UPDATE_INIT, 0, function(e)
    local data = REVEL.GetData(e)
    if (e.Variant == 0 and e.SubType == 0 and not data.isFrostyProjectile 
        and REVEL.STAGE.Glacier:IsStage()
        and not REVEL.FrostyProjectileImmunity[e.SpawnerType]
        and not data.NoFrostyProjectile
    )
    or data.ForceGlacierSkin then
        local spr = e:GetSprite()
        spr:ReplaceSpritesheet(0, "gfx/effects/revel1/frost_bulletatlas.png")
        spr:LoadGraphics()
        e.SplatColor = REVEL.WaterSplatColor
        data.isFrostyProjectile = true
    end
end)

-- Snowball / Ice Creep Projectiles
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, e)
    local data, sprite = REVEL.GetData(e), e:GetSprite()
    if data.ChangeToSnow then
        sprite:ReplaceSpritesheet(0, "gfx/effects/revel1/snowball_projectiles.png")
        sprite:LoadGraphics()
        data.ChangeToSnow = false
        data.IsSnow = true
    end

    if data.RandomizeScale then
        e.Scale = math.random(200, 400) * 0.01
        data.RandomizeScale = false
    end

    if data.RandomizeScaleSmall then
        e.Scale = math.random(50, 150) * 0.01
        data.RandomizeScaleSmall = false
    end

    if data.Snowballing and e.Scale < 4 then
        e:AddScale(0.05)
        sprite:LoadGraphics()
    end
end)

REVEL.ChocolateCreepColorize = {R=2,G=1.44,B=0.96,A=1}

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    if not REVEL.game:IsPaused() then
        local data = REVEL.GetData(e)
        if data.SpawnIceCreep then
            local creep = REVEL.SpawnIceCreep(e.Position, e.SpawnerEntity)
            if data.IceCreepTimeout then
                creep:ToEffect():SetTimeout(data.IceCreepTimeout)
            end

            if data.IceCreepScaleMulti then
                REVEL.UpdateCreepSize(creep, creep.Size * data.IceCreepScaleMulti, true)
            end
        end

        if data.SpawnStrawberryCreep then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, e.Position, e, false)
            creep.Color = REVEL.StrawberryCreepColor
            if data.StrawberryCreepTimeout then
                creep:ToEffect():SetTimeout(data.StrawberryCreepTimeout)
            end

            if data.StrawberryCreepScaleMulti then
                REVEL.UpdateCreepSize(creep, creep.Size * data.StrawberryCreepScaleMulti, true)
            end
        end

        if data.SpawnPissCreep then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, e.Position, e, false)
            if data.PissCreepTimeout then
                creep:ToEffect():SetTimeout(data.PissCreepTimeout)
            end

            if data.PissCreepScaleMulti then
                REVEL.UpdateCreepSize(creep, creep.Size * data.PissCreepScaleMulti, true)
            end
        end

        if data.SpawnChocolateCreep then
            local creep = REVEL.SpawnCreep(EffectVariant.CREEP_SLIPPERY_BROWN, 0, e.Position, e, false):ToEffect()
            local color = Color(1,1,1,1,conv255ToFloat(0,0,0))
            color:SetColorize(REVEL.ChocolateCreepColorize.R, REVEL.ChocolateCreepColorize.G, REVEL.ChocolateCreepColorize.B, REVEL.ChocolateCreepColorize.A)
            creep:GetSprite().Color = color
            creep:GetSprite().PlaybackSpeed = 0
            if data.ChocolateCreepTimeout then
                creep:SetTimeout(data.ChocolateCreepTimeout)
            end

            if data.ChocolateCreepScaleMulti then
                REVEL.UpdateCreepSize(creep, creep.Size * data.ChocolateCreepScaleMulti, true)
            end
        end

        if data.Flomp then
            REVEL.sfx:Play(REVEL.SFX.SNOWBALL_BREAK, 0.6, 0, false, math.random()*0.15+0.85)
        end

        if data.SpawnDip or data.SpawnFlake or data.SpawnSnowball then
            if REVEL.room:IsPositionInRoom(e.Position, -16) then
                local ent
                if data.SpawnDip then
                    ent = Isaac.Spawn(REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant, 0, REVEL.room:GetClampedPosition(e.Position, 16), Vector.Zero, e.SpawnerEntity)
                    ent:ToNPC().State = 9
                    if data.SpawnDipParent then
                        ent.SpawnerEntity = data.SpawnDipParent
                    end
                elseif data.SpawnSnowball then
                    ent = Isaac.Spawn(REVEL.ENT.ROLLING_SNOWBALL.id, REVEL.ENT.ROLLING_SNOWBALL.variant, 0, REVEL.room:GetClampedPosition(e.Position, 16), Vector.Zero, e.SpawnerEntity)
                    REVEL.GetData(ent).SlowerUpgrade = data.SnowballUpgradeDelay
                    REVEL.GetData(ent).NoUpgradeTwice = data.SnowballNoUpgradeTwice
                else
                    ent = Isaac.Spawn(REVEL.ENT.SNOW_FLAKE.id, REVEL.ENT.SNOW_FLAKE.variant, 0, REVEL.room:GetClampedPosition(e.Position, 16), Vector.Zero, e.SpawnerEntity)
                end

                if data.SpawnScaleData then
                    REVEL.ScaleEntity(ent, data.SpawnScaleData)
                end

                ent:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                local eff = Isaac.Spawn(1000, EffectVariant.TEAR_POOF_A, 0, e.Position, Vector.Zero, e.SpawnerEntity)
                eff.Color = Color(1.15,1.1,0.95,1,conv255ToFloat(0,0,0))
                eff.DepthOffset = -20
            end
        end
    end
end)

-------------------------------
-- SIMPLIFIED COLOR FUNCTION --
-------------------------------

function REVEL.CustomColor(r, g, b, a)
    return Color( (r/255), (g/255), (b/255), a or 1,conv255ToFloat( math.ceil(r/3), math.ceil(g/3), math.ceil(b/3)) )
end


--------------
-- ICE GIBS --
--------------
do
    local defaultIceRock = {
        Name = "Ice Rock Particle",
        Anm2 = "gfx/grid/grid_rock.anm2",
        AnimationName = "rubble_alt",
        Spritesheet = "gfx/grid/revel1/glacier_rocks.png",
        Variants = 4,
        BaseLife = 180,
        FadeOutStart = 0.1,
        RotationSpeedMult = 0
    }
    local yellowIceRock = REVEL.CopyTable(defaultIceRock)
    yellowIceRock.Spritesheet = "gfx/grid/revel1/glacier_rocks_yellow_ice.png"
    local darkIceRock = REVEL.CopyTable(defaultIceRock)
    darkIceRock.Spritesheet = "gfx/grid/revel1/glacier_rocks_dark_ice.png"

    local iceRockParticle = REVEL.ParticleType.FromTable(defaultIceRock)
    local iceRockParticleYellow = REVEL.ParticleType.FromTable(yellowIceRock)
    local iceRockParticleDark = REVEL.ParticleType.FromTable(darkIceRock)

    REVEL.IceRockSystem = REVEL.PartSystem.FromTable{
        Name = "Ice Rock Particle System",
        Gravity = 1.5,
        AirFriction = 0.95,
        GroundFriction = 0,
        Clamped = true
    }

    REVEL.IceGibType = {
        DEFAULT = 0,
        YELLOW = 1,
        DARK = 2
    }

    function REVEL.SpawnIceRockGib(position, velocity, spawner, iceType, persist)
        iceType = iceType or REVEL.IceGibType.DEFAULT

        if persist then

            local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, position, velocity, spawner)
            rock:Update()

            local spritesheet = "gfx/grid/revel1/glacier_rocks.png"
            if iceType == REVEL.IceGibType.YELLOW then
                spritesheet = "gfx/grid/revel1/glacier_rocks_yellow_ice.png"
            elseif iceType == REVEL.IceGibType.DARK then
                spritesheet = "gfx/grid/revel1/glacier_rocks_dark_ice.png"
            end

            local rockSprite = rock:GetSprite()
            rockSprite:ReplaceSpritesheet(0, spritesheet)
            rockSprite:LoadGraphics()
            rockSprite:SetFrame("rubble_alt", math.random(0,3))

            return rock

        else

            if iceType == REVEL.IceGibType.YELLOW then
                iceRockParticleYellow:Spawn(REVEL.IceRockSystem, Vec3(position,-5), Vec3(velocity,-10))
            elseif iceType == REVEL.IceGibType.DARK then
                iceRockParticleDark:Spawn(REVEL.IceRockSystem, Vec3(position,-5), Vec3(velocity,-10))
            else
                iceRockParticle:Spawn(REVEL.IceRockSystem, Vec3(position,-5), Vec3(velocity,-10))
            end
        end
    end
end

---------------
-- ICE CREEP --
---------------
do
    REVEL.IceCreepColor = Color(0, 0, 0, 1,conv255ToFloat( 94, 145, 176))
    REVEL.IceCreepColorChill = Color(0, 0, 0, 1,conv255ToFloat( 45, 80, 120))
    local animSets = {
        Blood = {},
        SmallBlood = {},
        BigBlood = {},
        BiggestBlood = {}
    }

    for k, tbl in pairs(animSets) do
        for i = 1, 6 do
            animSets[k][i] = k .. "0" .. tostring(i)
        end
    end

    function REVEL.SetCreepData(effect)
        for _, animSet in pairs(animSets) do
            for i, anim in ipairs(animSet) do
                if effect:GetSprite():IsPlaying(anim) or effect:GetSprite():IsFinished(anim) then
                    REVEL.GetData(effect).Animation = "0" .. tostring(i)
                    break
                end
            end
        end

        if effect.Size > 0 then
            REVEL.GetData(effect).OriginalSize = effect.Size
            REVEL.GetData(effect).RelativeSpriteScale = effect.SpriteScale / effect.Size
        else
            REVEL.DebugStringMinor("[WARN] Tried to use SetCreepData on 0 Size creep, will ignore it in creep handling")
        end
    end

    function REVEL.SpawnCreep(variant, subtype, pos, parent, big)
        --[[for _,player in ipairs(REVEL.players) do
            local effects = player:GetEffects()
            if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) then
                REVEL.GetData(player).HadHolyMantle = true
                effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
            end
        end]]

        local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, variant, subtype, pos, Vector.Zero, parent)
        effect:Update()

        if big then
            effect.SpriteScale = effect.SpriteScale / 4
        end

        REVEL.SetCreepData(effect)

        if big then
            local sprite = effect:GetSprite()
            local frame = sprite:GetFrame()
            sprite:Play("BiggestBlood" .. REVEL.GetData(effect).Animation, true)
            if frame > 0 then
                for i = 1, frame do
                    sprite:Update()
                end
            end
        end

        --[[for _,player in ipairs(REVEL.players) do
            local effects = player:GetEffects()
            if REVEL.GetData(player).HadHolyMantle and not effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) then
                effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE, true)
            end
            REVEL.GetData(player).HadHolyMantle = nil
        end]]

        return effect
    end

    function REVEL.SpawnSlipperyCreep(pos, parent, big)
        return REVEL.SpawnCreep(EffectVariant.CREEP_SLIPPERY_BROWN, 0, pos, parent, big)
    end

    local function UpdateIceCreepColor(e)
        local pct = 0 --REVEL.GetChillShaderPct()
        if REVEL.includes(REVEL.ChillRoomTypes, StageAPI.GetCurrentRoomType())
        or (StageAPI.GetCurrentRoom()
        and StageAPI.GetCurrentRoom().PersistentData.BossID
        and StageAPI.GetBossData(StageAPI.GetCurrentRoom().PersistentData.BossID).Name == "Wendy") then
            pct = 1
        end
        if pct ~= REVEL.GetData(e).prevChillPct then
            -- if revel.data.shadersOn == 0 then
            --   e.Color = REVEL.IceCreepColor
            -- else
            e.Color = Color.Lerp(REVEL.IceCreepColor, REVEL.IceCreepColorChill, pct)
            -- end
        end

        REVEL.GetData(e).prevChillPct = pct
    end

    function REVEL.SpawnIceCreep(pos, parent, big)
        local effect = REVEL.SpawnCreep(EffectVariant.CREEP_RED, 0, pos, parent, big)
        UpdateIceCreepColor(effect)
        REVEL.GetData(effect).icecreep = true
        effect.Variant = REVEL.ENT.ICE_CREEP.variant
        return effect
    end

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
        if REVEL.GetData(e).icecreep then
            if e.Timeout <= 0 then
                local data = REVEL.GetData(e)
                data.StartColor = data.StartColor or e.Color
                data.StartScale = data.StartScale or e.SpriteScale
                data.Fading = data.Fading or 30
                data.Fading = data.Fading - 1
                e.SpriteScale = REVEL.Lerp(Vector.One, Vector.One / 2, (30 - data.Fading) / 30)
                e.Color = Color.Lerp(data.StartColor, REVEL.ChangeSingleColorVal(data.StartColor, nil, nil, nil, 0), (30 - data.Fading) / 30)
                if data.Fading <= 0 then
                    e:Remove()
                end
            else
                UpdateIceCreepColor(e)
            end
        end
    end, REVEL.ENT.ICE_CREEP.variant)

    function REVEL.UpdateCreepSize(creep, size, changeAnim)
        local data, sprite = REVEL.GetData(creep), creep:GetSprite()
        if data.OriginalSize and data.RelativeSpriteScale and data.Animation then
            local scale = data.RelativeSpriteScale * size
            if changeAnim then
                local originalFrame = sprite:GetFrame()
                local anim
                if size <= data.OriginalSize / 2 then
                    scale = scale * 2
                    anim = "SmallBlood" .. data.Animation
                elseif size >= data.OriginalSize * 4 then
                    scale = scale / 4
                    anim = "BiggestBlood" .. data.Animation
                elseif size >= data.OriginalSize * 2 then
                    scale = scale / 2
                    anim = "BigBlood" .. data.Animation
                else
                    anim = "Blood" .. data.Animation
                end

                sprite:Play(anim, true)
                if originalFrame > 0 then
                    for i = 1, originalFrame do
                        sprite:Update()
                    end
                end
            end

            creep.SpriteScale = scale
            creep.Size = size
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARIMPACTS_SOUND, 2, function(tear, data, sprite)
    if data.Flomp then
        return false
    end
    return true
end)

-- Freeze aura
do
    local freezeAuraColor = Color(0.28, 0.6, 1, 0.6,conv255ToFloat( 18, 30, 64))
    local freezeAuraLightColor = Color(0.28, 0.6, 1, 1,conv255ToFloat( 36, 60, 128))
    local updatedAuraThisFrame = -1

    ---comment
    ---@param radius number
    ---@param position Vector
    ---@param spawner Entity
    ---@param time integer
    ---@param notPlaySound? boolean
    ---@param color? Color
    ---@return EntityEffect
    ---@return Sprite
    ---@return table
    function REVEL.SpawnFreezeAura(radius, position, spawner, time, notPlaySound, color)
        local aura, sprite, data  = REVEL.SpawnAura(radius, position, color or freezeAuraColor, spawner, nil, nil, nil, nil, nil, time)
        data.IsFreezeAura = true
        REVEL.SpawnLightAtEnt(aura, freezeAuraLightColor, 2.5, Vector(0, -3))

        if not notPlaySound and updatedAuraThisFrame < 1 then --if should play sound and there aren't other freeze auras on screen already
            REVEL.sfx:Play(REVEL.SFX.BRAINFREEZE.AURA_LOOP, 1, 0, true, 1)
        end

        return aura, sprite, data
    end

    local TearToBulletFlags = {
        [TearFlags.TEAR_EXPLOSIVE] = ProjectileFlags.EXPLODE,
        [TearFlags.TEAR_SPECTRAL] = ProjectileFlags.GHOST,
        [TearFlags.TEAR_HOMING] = ProjectileFlags.SMART,
        [TearFlags.TEAR_WIGGLE] = ProjectileFlags.WIGGLE,
        [TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP] = ProjectileFlags.ACID_GREEN,
        [TearFlags.TEAR_CONTINUUM] = ProjectileFlags.CONTINUUM,
        [TearFlags.TEAR_GREED_COIN] = ProjectileFlags.GREED
    }

    local TearToProjectileVariants = {
        [TearVariant.BONE] = ProjectileVariant.PROJECTILE_BONE,
        [TearVariant.BLUE] = ProjectileVariant.PROJECTILE_TEAR,
        [TearVariant.BLOOD] = ProjectileVariant.PROJECTILE_NORMAL,
        [TearVariant.CUPID_BLUE] = ProjectileVariant.PROJECTILE_TEAR,
        [TearVariant.PUPULA] = ProjectileVariant.PROJECTILE_TEAR
    }

    function REVEL.AuraReflectTear(entity, target, npc)
        local projectile, tear = entity:ToProjectile(), entity:ToTear()
        local casted = projectile or tear

        local height = casted.Height
        local fallingspeed = casted.FallingSpeed
        local projflags = ProjectileFlags.ANY_HEIGHT_ENTITY_HIT
        local scale = casted.Scale
        local variant
        local fallingaccel
        local holyShot
        local bush = REVEL.GetData(entity).BurningBush

        if tear then
            fallingaccel = casted.FallingAcceleration
        else
            fallingaccel = casted.FallingAccel
        end

        if REVEL.GetData(entity).HolyShot then
            holyShot = true
        end

        if projectile then
            variant = casted.Variant
            projflags = BitOr(projflags, casted.ProjectileFlags)
        else
            for tflag, pflag in pairs(TearToBulletFlags) do
                if HasBit(casted.TearFlags, tflag) then
                    projflags = BitOr(projflags, pflag)
                end
            end

            if HasBit(casted.TearFlags, TearFlags.TEAR_LIGHT_FROM_HEAVEN) then
                holyShot = true
            end

            variant = TearToProjectileVariants[casted.Variant] or ProjectileVariant.PROJECTILE_NORMAL
        end

        local spawnReflectProj = true

        if bush then
            spawnReflectProj = spawnReflectProj and math.random() > 0.5
        end

        if spawnReflectProj then
            local vel = (target.Position - entity.Position):Resized(math.random(60, 90) * 0.1)
            local nprojectile = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, variant, 0, entity.Position, vel, npc):ToProjectile()
            nprojectile.Color = casted.Color
            nprojectile.Height = height
            nprojectile.FallingSpeed = fallingspeed - 10
            nprojectile.FallingAccel = fallingaccel + 0.3
            nprojectile.Scale = scale
            nprojectile.ProjectileFlags = projflags
            REVEL.GetData(nprojectile).AlreadyFrozen = true
            if holyShot then
                REVEL.GetData(nprojectile).HolyShot = true
            end
            if bush then
                nprojectile:GetSprite():Load("gfx/effects/revelcommon/burning_tears.anm2", true)
            end
        end
        if tear and bush and not spawnReflectProj then
            REVEL.FireTearDie(tear)
        end

        entity:Remove()
    end

    revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
        if pro:IsDead() and REVEL.GetData(pro).HolyShot then
            Isaac.Spawn(1000, 19, 0, pro.Position, Vector.Zero, pro)
        end
    end)

    local frozenColorOffset = Color(1,1,1,1,conv255ToFloat(0,90,150))
    function REVEL.FreezeAura(aura, chillPlayer, skipFrozen, shootTimer, strength, strengthHoming, notPlaySound)
        strength = strength or 0.85
        strengthHoming = strengthHoming or 0.5
        local data = REVEL.GetData(aura)
        local potentiallyFrozen = REVEL.ConcatTables(REVEL.roomTears, REVEL.roomProjectiles)
        for _, entity in ipairs(potentiallyFrozen) do
            local edata = REVEL.GetData(entity)
            if not (skipFrozen and REVEL.GetData(entity).AlreadyFrozen)
            and (not edata.Aura or GetPtrHash(edata.Aura) == GetPtrHash(aura))
            and entity.Position:Distance(aura.Position) <= data.Radius then
                edata.FrozenTimer = edata.FrozenTimer or 0
                edata.FrozenTimer = edata.FrozenTimer + 1
                edata.AuraFrozen = true
                edata.Aura = aura

                entity.Color = frozenColorOffset

                local casted = entity:ToProjectile() or entity:ToTear()

                if casted.TearFlags and HasBit(casted.TearFlags, TearFlags.TEAR_HOMING) then
                    entity.Velocity = entity.Velocity * strengthHoming
                else
                    entity.Velocity = entity.Velocity * strength
                end

                if entity.Velocity:LengthSquared() < 1 and not REVEL.GetData(entity).PlayedStopSound then
                REVEL.sfx:Play(REVEL.SFX.BRAINFREEZE.BUL_STOP, 0.7, 0, false, 1)
                REVEL.GetData(entity).PlayedStopSound = true
                end

                if shootTimer and edata.FrozenTimer >= shootTimer then
                    local target = data.Spawner:GetPlayerTarget() or REVEL.getClosestInTable(REVEL.players, data.Spawner)
                    REVEL.AuraReflectTear(entity, target, data.Spawner)
                end
            end
        end

        if chillPlayer then
            for _, player in ipairs(REVEL.players) do
                if player.Position:Distance(aura.Position) <= data.Radius then
                    REVEL.Freeze(player)
                end
            end
        end
        if not notPlaySound then
            updatedAuraThisFrame = 1
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if updatedAuraThisFrame == 1 then
            updatedAuraThisFrame = 0
        elseif updatedAuraThisFrame == 0 then
            REVEL.sfx:Stop(REVEL.SFX.BRAINFREEZE.AURA_LOOP)
            updatedAuraThisFrame = -1
        end
    end)

    local function UpdateFrozenBullet(_, ent)
        local data = REVEL.GetData(ent)
        if data.AuraFrozen and data.Aura:Exists() and not data.Aura:IsDead()
        and REVEL.IsRenderPassNormal() then
            data.OldHeight = data.OldHeight or ent.Height
            ent.Height = data.OldHeight
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, UpdateFrozenBullet)
    revel:AddCallback(ModCallbacks.MC_POST_TEAR_RENDER, UpdateFrozenBullet)

    function REVEL.ShootAura(aura, target, npc, skipFade)
        local data = REVEL.GetData(aura)
        local potentiallyFrozen = REVEL.ConcatTables(REVEL.roomTears, REVEL.roomProjectiles)
        for _, entity in ipairs(potentiallyFrozen) do
            local edata = REVEL.GetData(entity)
            if edata.AuraFrozen and GetPtrHash(edata.Aura) == GetPtrHash(aura) then
                REVEL.AuraReflectTear(entity, target, npc)
            end
        end

        if not skipFade then
            REVEL.AuraExpandFade(aura, 5, data.Radius * 1.6)
        end
    end
end

local function doorClosePostNewRoom()
    REVEL.GlacierDoorCloseDoneThisRoom = false
end

local function doorCloseCleanAward()
    if REVEL.GlacierDoorCloseDoneThisRoom and REVEL.room:GetType() == RoomType.ROOM_DEFAULT then
        return true
    end
end

local function snowParticles_PostEffectUpdate(_, e)
    if e.Variant == REVEL.ENT.SNOW_PARTICLE.variant then
        if REVEL.MultiFinishCheck(e:GetSprite(), "Fade", "FadeNoExpand", "Appear", "AppearNoExpand") then
            e:Remove()
        elseif REVEL.GetData(e).Rot then
            e:GetSprite().Rotation = e:GetSprite().Rotation+REVEL.GetData(e).Rot
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, snowParticles_PostEffectUpdate, REVEL.ENT.SNOW_PARTICLE.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, doorClosePostNewRoom)
revel:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, doorCloseCleanAward)


end