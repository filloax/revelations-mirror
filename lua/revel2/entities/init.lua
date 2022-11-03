local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.PurpleRagSplatColor = Color(1,1,1,1,conv255ToFloat(0,0,120))
REVEL.SandSplatColor = Color(0,0,0,1,conv255ToFloat(90,65,40))
	
-------------
-- REVIVAL --
-------------

do
    local purple = Color(0, 0, 0, 1,conv255ToFloat( 155, 90, 174))

    function REVEL.SpawnPurpleThunder(ent)
        REVEL.SpawnThunder(ent, purple)
    end

    REVEL.TypeToRagAnim = {
		[REVEL.ENT.RAG_GAPER.id] = {"Gaper"},
		[REVEL.ENT.RAG_TAG.id] = {"Ragtag"},
		[REVEL.ENT.RAG_FATTY.id] = {"Fatty"},
		[REVEL.ENT.RAG_TRITE.id] = {"Trite"},
		[REVEL.ENT.RAG_BONY.id] = {"Bony"},
		[REVEL.ENT.WRETCHER.id] = {"Wretcher1", "Wretcher2"},
		[REVEL.ENT.RAG_DRIFTY.id] = {"Drifty"},
		[REVEL.ENT.ARAGNID_INNARD.id] = {"Innard"},
		[EntityType.ENTITY_LUST] = {"Lust"},
		[REVEL.ENT.RAGMA.id] = {"Ragma"}
    }

    function REVEL.SpawnRevivalRag(npc, id, variant, subtype, position)
        if variant == false then variant = 0 end
        if subtype == false then subtype = 0 end
        local rag = Isaac.Spawn(REVEL.ENT.REVIVAL_RAG.id, REVEL.ENT.REVIVAL_RAG.variant, 0, position or npc.Position, Vector.Zero, npc)
        local data, spr = rag:GetData(), rag:GetSprite()
        data.SpawnID = id or npc.Type
        data.SpawnVariant = variant or npc.Variant
        data.SpawnSubtype = subtype or npc.SubType

        if REVEL.TypeToRagAnim[data.SpawnID] then
			local anim = REVEL.TypeToRagAnim[data.SpawnID][math.random(#REVEL.TypeToRagAnim[data.SpawnID])]
			if data.SpawnID == EntityType.ENTITY_LUST and data.SpawnVariant == 1 then
				anim = "Super Lust"
				data.NoSpriteRecheck = true
			end

			spr:Play(anim, true)
        end
        return rag, data, spr
    end

	StageAPI.AddCallback("Revelations", "PRE_SPAWN_ENTITY", 1, function(info, entityList, index, doGrids, doPersistentOnly, doAutoPersistent, avoidSpawning, persistentPositions)
		local currentRoom = StageAPI.GetCurrentRoom()
		if currentRoom and currentRoom.Metadata:Has{Index = index, Name = "RevivalRag"} then
			REVEL.SpawnRevivalRag(nil, info.Data.Type, info.Data.Variant, info.Data.SubType, REVEL.room:GetGridPosition(index))
	
			return false
		end
	end)
	
    function REVEL.BuffEntity(npc)
        local s
        if npc.Type == REVEL.ENT.REVIVAL_RAG.id and npc.Variant == REVEL.ENT.REVIVAL_RAG.variant then
            local data = npc:GetData()
            REVEL.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
            if not data.SpawnID or not data.SpawnVariant or not data.SpawnSubtype then
                REVEL.DebugLog("Buff entity spawn id not found!", data.SpawnID, data.SpawnVariant, data.SpawnSubtype, " ")
                return nil
            end

            s = Isaac.Spawn(data.SpawnID, data.SpawnVariant or 0, data.SpawnSubtype or 0, npc.Position, Vector.Zero, npc)
            if data.SpecialAppear then
                s:GetData().SpecialAppear = data.SpecialAppear
            end

            if s.Type == REVEL.ENT.RAG_TRITE.id and s.Variant == REVEL.ENT.RAG_TRITE.variant and s.SubType == 231 then
                s:GetData().MorphedFromRagTrite = true
            end

            if data.OnRevive then data.OnRevive(npc, s) end

            npc:Remove()
        else
            s = npc
        end

        s:GetData().Buffed = true
        REVEL.SpawnPurpleThunder(s)
        return s
    end

    function REVEL.IsEntityBuffable(npc)
        return REVEL.IsTypeVariantInList(npc, REVEL.RAG_FAMILY) and not npc:GetData().Buffed and not npc:GetData().Anima
    end

    function REVEL.IsEntityRevivable(npc)
        return (npc.Type == REVEL.ENT.REVIVAL_RAG.id and npc.Variant == REVEL.ENT.REVIVAL_RAG.variant) or REVEL.IsEntityBuffable(npc)
    end

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, npc)
        local data = npc:GetData()
        if data.FallingSpeed and REVEL.IsRenderPassNormal() then
            local height = npc.SpriteOffset.Y
            if height < 0 then
                height = height + data.FallingSpeed
                data.FallingSpeed = data.FallingSpeed + data.FallingAcceleration
            else
                REVEL.sfx:Play(SoundEffect.SOUND_MEAT_IMPACTS, 0.8, 0, false, 1)
                data.FallingSpeed = nil
                data.FallingAcceleration = nil
            end

            npc.SpriteOffset = Vector(0, math.min(height, 0))
        end
    end, REVEL.ENT.REVIVAL_RAG.variant)

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, npc)
        local data, sprite = npc:GetData(), npc:GetSprite()
        npc.DepthOffset = -30

        if data.Init == nil then
            npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
            npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.State = "Idle"
            data.Init = 1
            if REVEL.TypeToRagAnim[data.SpawnID] and not data.NoSpriteRecheck then
            sprite:Play(REVEL.TypeToRagAnim[data.SpawnID][math.random(#REVEL.TypeToRagAnim[data.SpawnID])], true)
            end

            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom and currentRoom.Metadata:Has{Index = REVEL.room:GetGridIndex(npc.Position), Name = "RevivalTear"} 
			and not REVEL.room:IsClear() then
                data.RevivalTear = true

				if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
					REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
				end
				data.UsePlayerMap = true
				
                sprite:PlayOverlay("RevivalBall", true)
            end
        end

        if data.MagicBallTargeted and not data.MagicBallTargeted:Exists() then
            data.MagicBallTargeted = nil
        end

        if data.RevivalTear then
            data.TargetIndices = {}
            for _, player in ipairs(REVEL.players) do
                data.TargetIndices[#data.TargetIndices + 1] = REVEL.room:GetGridIndex(player.Position)
            end

            if sprite:IsOverlayFinished("RevivalBallDrop") then
                data.State = "Revive"
            elseif data.Path and not sprite:IsOverlayPlaying("RevivalBallDrop") then
                sprite:PlayOverlay("RevivalBallDrop", true)
            end
        end

        if data.State == "Revive" then
            REVEL.BuffEntity(npc)
        end
    end, REVEL.ENT.REVIVAL_RAG.variant)

	local BuffedParticles = REVEL.ParticleType.FromTable{
		Name = "RevivalParticles",
		Anm2 =  "gfx/effects/revelcommon/glow_ember_particle.anm2",
		AnimationName = "Idle",
		BaseOffset = Vector(-2, -2),
		Variants = 8,
		ScaleRandom = 0.2,
		StartScale = 1,
		EndScale = 0.5,
		BaseLife = 12,
		DieOnLand = false,
		Turbulence = true,
		TurbulenceReangleMinTime = 10,
		TurbulenceReangleMaxTime = 30,
		TurbulenceMaxAngleXYZ = Vec3(45,35,35),
		RenderNormallyWithEntity = true, -- to use glow
	}
	BuffedParticles:SetColor(Color(0.25, 0, 0.41, 1, 0.2, 0, 0.31), 0)
	
	local BuffedSystem = REVEL.PartSystem.FromTable{
		Name = "Revival System",
		Gravity = 0.02,
		AirFriction = 0.95,
		GroundFriction = 0.95,
		Clamped = true,
	}

	local function BuffParticlesAnimCheck(npc, emitter, anim, frame, anm2NullTable)
		if anm2NullTable[anim] then
			frame = math.min(frame, #anm2NullTable[anim].Visible)
		end

		if anm2NullTable[anim] and anm2NullTable[anim].Visible[frame] then
			local off = REVEL.VectorMult(anm2NullTable[anim].Offset[frame] * 40 / 26, npc.SpriteScale)

			local pos = Vec3(
				npc.Position.X + off.X + npc.SpriteOffset.X * 40 / 26 * npc.SpriteScale.X, 
				npc.Position.Y + npc.SpriteOffset.Y * 40 / 26 * npc.SpriteScale.Y, 
				off.Y
			)
			local vel = Vec3(-npc.Velocity * 0.5 + REVEL.VEC_LEFT * 1, -3)
			local partsPerSec = REVEL.Lerp2Clamp(15, 35, npc.Velocity:Length(), 5, 10) / (nullsNum or 1)
			local velocityRandom = 0
			local angleSpread = 45

			emitter:EmitParticlesPerSec(
				BuffedParticles,
				BuffedSystem, 
				pos, 
				vel, 
				partsPerSec, 
				velocityRandom, 
				angleSpread,
				nil,
				nil,
				npc
			)
		end
	end
	
	-- Fun thing is, the particles per second are shared between
	-- more calls of this function from different nulls
	-- Since data.Emitter is shared
	---@param npc EntityNPC
	---@param anm2NullTable table
	function REVEL.EmitBuffedParticles(npc, anm2NullTable)
		local sprite, data = npc:GetSprite(), npc:GetData()

		if not data.RagEmitter then
			data.RagEmitter = {}
		end
		if not data.RagEmitter[anm2NullTable] then
			data.RagEmitter[anm2NullTable] = REVEL.Emitter()
		end
		local emitter = data.RagEmitter[anm2NullTable]

		BuffParticlesAnimCheck(
			npc, emitter, 
			sprite:GetAnimation(), 
			sprite:GetFrame() + 1, 
			anm2NullTable
		)
		BuffParticlesAnimCheck(
			npc, emitter, 
			sprite:GetOverlayAnimation(), 
			sprite:GetOverlayFrame() + 1, 
			anm2NullTable
		)
	end
end

--------------------------
-- RESKINS/REPLACEMENTS --
--------------------------
do
	REVEL.EntityReplacements["Tomb"] = {
		MonsterPath = "gfx/monsters/revel2/",
		BossPath = "gfx/bosses/revel2/",
		Replacements = {

			--traps
            [EntityType.ENTITY_STONEHEAD] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_stone_head"
					}
				}
			},
			[EntityType.ENTITY_CONSTANT_STONE_SHOOTER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_constant_stone_shooter"
					}
				},
				[10] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_cross_turret"
					}
				},
				[11] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_cross_turret"
					}
				}
            },
			[EntityType.ENTITY_GAPING_MAW] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_gaping_maw"
					}
				}
			},
			[EntityType.ENTITY_BROKEN_GAPING_MAW] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_broken_gaping_maw"
					}
				}
			},
			[EntityType.ENTITY_POKY] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_poky"
					}
				},
				[1] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_slide"
					}
				}
			},
			[EntityType.ENTITY_WALL_HUGGER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_wall_hugger"
					}
				}
			},
			[EntityType.ENTITY_STONEY] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_stoney",
						[1] = "reskins/tomb_stoney"
					}
				},
				[10] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_stoney",
						[1] = "reskins/tomb_cross_turret_head"
					}
				}
			},
			[EntityType.ENTITY_VIS] = {
				-- Chubber
				[2] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_chubber",
						[1] = "reskins/tomb_chubber",
					},
				},
				-- Chubber projectile
				[22] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_chubberworm",
					},
				}
			},

			--bosses
			[EntityType.ENTITY_MEGA_FATTY] = {
				[0] = {
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_mega_fatty",
                            [1] = "reskins/tomb_mega_fatty_champ_1",
                            [2] = "reskins/tomb_mega_fatty_champ_2",
                        },
                        [1] = {
                            [-1] = "reskins/tomb_mega_fatty",
                            [1] = "reskins/tomb_mega_fatty_champ_1",
                            [2] = "reskins/tomb_mega_fatty_champ_2",
                        },
						[2] = "reskins/tomb_mega_fatty",
						[3] = "reskins/tomb_mega_fatty",
						[4] = "reskins/tomb_mega_fatty",
						[5] = "reskins/tomb_mega_fatty",
						[6] = "reskins/tomb_mega_fatty",
						[7] = "reskins/tomb_mega_fatty"
					},
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},
			[EntityType.ENTITY_FISTULA_BIG] = {
				[0] = {
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_fistula",
                            [1] = "reskins/tomb_fistula_champ_1",
                        },
					}
				}
			},
			[EntityType.ENTITY_FISTULA_MEDIUM] = {
				[0] = {
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_fistula",
                            [1] = "reskins/tomb_fistula_champ_1",
                        },
					}
				}
			},
			[EntityType.ENTITY_FISTULA_SMALL] = {
				[0] = {
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_fistula",
                            [1] = "reskins/tomb_fistula_champ_1",
                        },
					}
				}
			},
			[EntityType.ENTITY_THE_HAUNT] = {
				[0] = {
					ANM2 = "reskins/tomb_the_haunt",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor,
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_the_haunt",
                            [1] = "reskins/tomb_the_haunt_champ_1",
                            [2] = "reskins/tomb_the_haunt_champ_2",
                        },
					}
				},
				[10] = {
					ANM2 = "reskins/tomb_lil_haunt",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},
			[EntityType.ENTITY_MEGA_MAW] = {
				[0] = {
					SPRITESHEET = {
						[0] = {
                            [-1] = "reskins/tomb_mega_maw",
                            [1] = "reskins/tomb_mega_maw_champ_1",
                            [2] = "reskins/tomb_mega_maw_champ_2",
                        },
					},
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},

			--sins
			[EntityType.ENTITY_SLOTH] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_sloth"
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_sloth"
				}
			},
			[EntityType.ENTITY_GLUTTONY] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_gluttony",
					ANIMATION = "WalkVert",
					ANIMATION_FRAME = 0
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_gluttony",
					ANIMATION = "WalkVert",
					ANIMATION_FRAME = 0
				}
			},
			[EntityType.ENTITY_ENVY] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_envy",
					ANIMATION = "Walk0",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[10] = {
					ANM2 = "reskins/sins/tomb_envy",
					ANIMATION = "Walk1",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[20] = {
					ANM2 = "reskins/sins/tomb_envy",
					ANIMATION = "Walk2",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[30] = {
					ANM2 = "reskins/sins/tomb_envy",
					ANIMATION = "Walk3",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},

				[1] = {
					ANM2 = "reskins/sins/tomb_super_envy",
					ANIMATION = "Walk0",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[11] = {
					ANM2 = "reskins/sins/tomb_super_envy",
					ANIMATION = "Walk1",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[21] = {
					ANM2 = "reskins/sins/tomb_super_envy",
					ANIMATION = "Walk2",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[31] = {
					ANM2 = "reskins/sins/tomb_super_envy",
					ANIMATION = "Walk3",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},
			[EntityType.ENTITY_GREED] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_greed"
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_greed"
				}
			},
			[EntityType.ENTITY_WRATH] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_wrath"
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_wrath"
				}
			},
			[EntityType.ENTITY_LUST] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_lust",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_lust",
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},
			[EntityType.ENTITY_PRIDE] = {
				[0] = {
					ANM2 = "reskins/sins/tomb_pride"
				},
				[1] = {
					ANM2 = "reskins/sins/tomb_super_pride"
				}
			},

			--monsters
			[EntityType.ENTITY_NULLS] = {
				[0] = {
					ANM2 = "reskins/tomb_null"
				}
			},
			[EntityType.ENTITY_IMP] = {
				[0] = {
					ANM2 = "reskins/tomb_imp",
					SPLAT_COLOR = REVEL.SandSplatColor
				}
			},
			[EntityType.ENTITY_CHARGER] = {
				[0] = {
					[-1] = {
						SPRITESHEET = {
							[0] = "reskins/tomb_charger"
						}
					},
					[1] = true --does nothing (takes priority over -1)
				}
			},
			[EntityType.ENTITY_MAGGOT] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_maggot"
					}
				}
			},
			[EntityType.ENTITY_SPITY] = {
				[0] = {
					ANM2 = "reskins/tomb_spitty"
				}
			},
			[EntityType.ENTITY_GREED_GAPER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_greed_gaper_body",
						[1] = "reskins/tomb_greed_gaper"
					},
					SPLAT_COLOR = REVEL.PurpleRagSplatColor
				}
			},
			[EntityType.ENTITY_GRUB] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_grub"
					}
				}
			},
			[EntityType.ENTITY_WALL_CREEP] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_wall_creep"
					}
				}
			},
			[EntityType.ENTITY_BLIND_CREEP] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_blind_creep"
					}
				}
			},
			[EntityType.ENTITY_BONY] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_bony_body",
                        [1] = "reskins/tomb_bony_head"
					}
				}
			},
			[EntityType.ENTITY_ONE_TOOTH] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/tomb_one_tooth"
					}
				}
			},
			[EntityType.ENTITY_FAT_BAT] = {
                [0] = {
                    SPRITESHEET = {
                        [0] = "reskins/tomb_fat_bat"
					}
				}
			},
			[EntityType.ENTITY_KEEPER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_keeper"
					}
				}
			},
			[EntityType.ENTITY_ROUND_WORM] = {
				[0] = {
					ANM2 = "reskins/tomb_round_worm"
				}
			},
			[EntityType.ENTITY_NIGHT_CRAWLER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_night_crawler"
					}
				}
			},
			[EntityType.ENTITY_TUMOR] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_tumor"
					}
				}
			},
			[EntityType.ENTITY_BLACK_GLOBIN_HEAD] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_black_globin_head"
					}
				}
			},
			[EntityType.ENTITY_HOPPER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_hopper_leaper"
					}
				}
			},
			[EntityType.ENTITY_LEAPER] = {
				[0] = {
					SPRITESHEET = {
						[0] = "reskins/tomb_hopper_leaper"
					}
				}
			},
			[EntityType.ENTITY_FLAMINGHOPPER] = {
				[0] = {
					SPRITESHEET = {
						[1] = "reskins/tomb_flaming_hopper"
					}
				}
			}

		}
	}

	--pitfalls in its own callback because it has trap room and sand room versions
	StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
		if REVEL.STAGE.Tomb:IsStage() then
			local currentRoomType = StageAPI.GetCurrentRoomType()
			if REVEL.includes(REVEL.TombTrapGfxRoomTypes, currentRoomType) then
				local sprite = npc:GetSprite()
				sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/reskins/tomb_pitfall_trap.png")
				sprite:LoadGraphics()
			else
				local sprite = npc:GetSprite()
				sprite:ReplaceSpritesheet(0, "gfx/monsters/revel2/reskins/tomb_pitfall.png")
				sprite:LoadGraphics()
			end
		end
	end, EntityType.ENTITY_PITFALL)

	--shopkeepers
	local keeperVariantToAnm2 = {
		[0] = "gfx/effects/revel2/tomb_shopkeeper.anm2",
		[1] = "gfx/effects/revel2/tomb_shopkeeper_hanging.anm2",
		[3] = "gfx/effects/revel2/tomb_shopkeeper_special.anm2",
		[4] = "gfx/effects/revel2/tomb_shopkeeper_hanging_special.anm2"
	}
	revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
		if REVEL.STAGE.Tomb:IsStage() and keeperVariantToAnm2[npc.Variant] and REVEL.room:GetType() ~= RoomType.ROOM_SUPERSECRET then
			npc:GetSprite():Load(keeperVariantToAnm2[npc.Variant], true)
		end
	end, EntityType.ENTITY_SHOPKEEPER)
end

end

REVEL.PcallWorkaroundBreakFunction()