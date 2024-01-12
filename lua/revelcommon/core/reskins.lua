local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

--------------------------
-- RESKINS/REPLACEMENTS --
--------------------------
do
	--[[
	
	--Replace NameOfFloor with the name of the floor, must be something that is valid when checking IsStage()
	REVEL.EntityReplacements["NameOfFloor"] = {

		--Base path to monster reskins unique to this floor.
		MonsterPath = "base/path/to/monster/reskins/",

		--Base path to boss reskins unique to this floor.
		BossPath = "base/path/to/boss/reskins/",

		Replacements = {

			--The entity type this data applies to. -1 can be used to apply to all entity types other than the ones already defined.
			[EntityType] = {

				--The entity variant this data applies to. -1 can be used to apply to all entity variants other than the ones already defined.
				[EntityVariant] = {

					--The entity subtype this data applies to. Optional, if a subtype table isnt here then it will apply to all subtypes. -1 can be used to apply to all entity subtypes other than the ones already defined.
					[EntitySubType] = {

						--Replaces the entity's anm2 file with this one if provided. Do not type in the file extension.
						ANM2 = "Name_Of_Anm2"

						--Entity's sprite layers will be replaced with these spritesheets if provided. Index is layer id. Do not type in the file extension.
						--Putting a table in a layer will make it pick one of the spritesheets randomly.
						SPRITESHEET = {
							[0] = "Name_Of_Spritesheet",
							[1] = {"Random_Spritesheet_1","Random_Spritesheet_2","Random_Spritesheet_3"}
						},

						--The animation to play when replacing this entity.
						ANIMATION = "Name of animation",

						--Animation will be set to this frame instead of playing it if this exists.
						ANIMATION_FRAME = 0,

						--Entity's SplatColor will be set to this if it exists.
						SPLAT_COLOR = Color(0,0,0,0,conv255ToFloat(0,0,0)),

						--Entity will be replaced with a totally new entity with the Type, Variant, and SubType put in here in that order. SubType is optional. Other changes will be lost.
						REPLACE = {10,0,0}
						
						

						--Entity will spawn ice creep if its State attribute is equal to this.
						ICECREEP_STATE = 0

						--Entity will spawn ice creep if it is currently playing this animation.
						ICECREEP_ANIMATION = "Name of animation"

						--Entity will spawn ice creep if a counter that goes up every update is equal to this.
						--Having ICECREEP_STATE will make this counter only go up if the npc is in that state.
						--If ICECREEP_ANIMATION is set, this will instead make it so ice creep is spawned at that frame of the animation.
						ICECREEP_FRAME = 0

						--Entity will spawn ice creep when it dies if this is set to true.
						ICECREEP_DEATH = false
						
						--Any ice creep this entity spawns will be set to this scale if this is set.
						ICECREEP_SCALE = 1.5
						
						

						--Entity will spawn ice creep if its State attribute is equal to this.
						ICECREEP_STATE_2 = 0

						--Entity will spawn ice creep if it is currently playing this animation.
						ICECREEP_ANIMATION_2 = "Name of animation"

						--Entity will spawn ice creep if a counter that goes up every update is equal to this.
						--Having ICECREEP_STATE will make this counter only go up if the npc is in that state.
						--If ICECREEP_ANIMATION is set, this will instead make it so ice creep is spawned at that frame of the animation.
						ICECREEP_FRAME_2 = 0

						--Entity will spawn ice creep when it dies if this is set to true.
						ICECREEP_DEATH_2 = false
						
						--Any ice creep this entity spawns will be set to this scale if this is set.
						ICECREEP_SCALE_2 = 1.5

					}
				}
			},
		|
	}
	]]

	REVEL.EntityReplacements = {}

	local SinTypes = {EntityType.ENTITY_SLOTH, EntityType.ENTITY_LUST, EntityType.ENTITY_WRATH,
	EntityType.ENTITY_GLUTTONY, EntityType.ENTITY_GREED, EntityType.ENTITY_ENVY, EntityType.ENTITY_PRIDE}

	function REVEL.ReplaceEntity(entity, entType, entVariant, entSubType, dontClearFlags)
		if entity and entity:Exists() then

			if entVariant == nil then
				entVariant = 0
			end

			if entSubType == nil then
				entSubType = 0
			end

			local position = entity.Position
			local velocity = entity.Velocity
			local spawner = entity.SpawnerEntity
			local flags = entity:GetEntityFlags()

			entity:Remove()

			local newEntity = Isaac.Spawn(entType, entVariant, entSubType, position, velocity, spawner)

			if not dontClearFlags then
				newEntity:ClearEntityFlags(~0)
			end

			newEntity:AddEntityFlags(flags)

			return newEntity

		end
	end

	---@param npc EntityNPC
	function REVEL.CheckReplacements(npc, onUpdate, overrideStage, skipSin)
		local data = npc:GetData()
		local success = false

		if skipSin and REVEL.includes(SinTypes, npc.Type) then
			return false
		end

		if not data.RevelCheckedReplacement or overrideStage then
			local currentStage = overrideStage
			if not currentStage then
				currentStage = StageAPI.GetCurrentStage()
				if currentStage then
					currentStage = currentStage.Alias or currentStage.Name
				end
			end

			if currentStage and REVEL.EntityReplacements[currentStage] then
				local stageTable = REVEL.EntityReplacements[currentStage]

				local npcType = npc.Type
				local npcVariant = npc.Variant
				local npcSubType = npc.SubType

				--get type data
				local replacementData = stageTable.Replacements[npcType] or stageTable.Replacements[-1]

				if replacementData then

					--get variant data
					replacementData = replacementData[npcVariant] or replacementData[-1]

					if replacementData then

						--get subtype data or this if it doesnt exist
						replacementData = replacementData[npcSubType] or replacementData[-1] or replacementData

					end
				end
				
				--apply the replacement data if we found it
				if replacementData and type(replacementData) == "table" then

					--anm2 replacement
					if replacementData.ANM2 and (not onUpdate or overrideStage) then --dont replace anm2 in update just in case the entity does special coding in the game's first update, generally more compatible
						local sprite = npc:GetSprite()

						local anim = sprite:GetAnimation()
						local ovAnim = sprite:GetOverlayAnimation()

						if npc:IsBoss() then
							sprite:Load(stageTable.BossPath .. replacementData.ANM2 .. ".anm2", true)
						else
							sprite:Load(stageTable.MonsterPath .. replacementData.ANM2 .. ".anm2", true)
						end

						REVEL.DebugStringMinor(("Replaced npc %d.%d anm2 to %s")
							:format(npc.Type, npc.Variant, sprite:GetFilename())
						)

						sprite:Play(anim, true)
						if ovAnim ~= "" then
							sprite:PlayOverlay(ovAnim, true)
						end
					end

					--spritesheet replacement
					if replacementData.SPRITESHEET and not data.__RevReplacedSpritesheet then

						local sprite = npc:GetSprite()

						if npc:IsBoss() then
							for layerIndex, spritesheet in pairs(replacementData.SPRITESHEET) do
								local spritesheetToUse = spritesheet
								if type(spritesheet) == "table" then
									if data.ForceSpriteVariant then
										spritesheetToUse = spritesheet[data.ForceSpriteVariant]
									else
										if npc.SubType > 0 then
											spritesheetToUse = spritesheet[npc.SubType]
										else
											spritesheetToUse = spritesheet[-1]
										end
									end
								end
								if spritesheetToUse then
									REVEL.ReplaceEnemySpritesheet(npc, stageTable.BossPath .. spritesheetToUse, layerIndex)
									REVEL.DebugStringMinor(("Replaced boss %d.%d sprite to %s")
										:format(npc.Type, npc.Variant, stageTable.BossPath .. spritesheetToUse)
									)
									data.__RevReplacedSpritesheet = true
								else
									REVEL.DebugStringMinor(("Reskins: boss %d.%d.%d spritesheetToUse nil! ForceSpriteVariant: %s")
										:format(npc.Type, npc.Variant, npc.SubType, data.ForceSpriteVariant)
									)
								end
							end
						else
							for layerIndex, spritesheet in pairs(replacementData.SPRITESHEET) do
								local spritesheetToUse = spritesheet
								if type(spritesheet) == "table" then
									if data.ForceSpriteVariant then
										spritesheetToUse = spritesheet[data.ForceSpriteVariant]
									else
										spritesheetToUse = spritesheet[math.random(1, #spritesheet)]
									end
								end
								if spritesheetToUse then
									REVEL.ReplaceEnemySpritesheet(npc, stageTable.MonsterPath .. spritesheetToUse, layerIndex)
									REVEL.DebugStringMinor(("Replaced enemy %d.%d sprite to %s")
										:format(npc.Type, npc.Variant, stageTable.MonsterPath .. spritesheetToUse)
									)
									data.__RevReplacedSpritesheet = true
								else
									REVEL.DebugStringMinor(("Reskins: %d.%d.%d spritesheetToUse nil! ForceSpriteVariant: %s")
										:format(npc.Type, npc.Variant, npc.SubType, data.ForceSpriteVariant)
									)
								end
							end
						end
						sprite:LoadGraphics()

					end

					--animation to play
					if replacementData.ANIMATION then

						local sprite = npc:GetSprite()

						if replacementData.ANIMATION_FRAME then
							sprite:SetFrame(replacementData.ANIMATION, replacementData.ANIMATION_FRAME)
						else
							sprite:Play(replacementData.ANIMATION, false)
						end

					end

					--splat color
					if replacementData.SPLAT_COLOR then
						npc.SplatColor = replacementData.SPLAT_COLOR
					end

					--replace entity with other entity
					if replacementData.REPLACE and (onUpdate or overrideStage) then --position is only valid in update
						REVEL.DebugStringMinor(("Replacing entity %d.%d with %d.%d")
							:format(npc.Type, npc.Variant, replacementData.REPLACE[1], replacementData.REPLACE[2])
						)
						REVEL.ReplaceEntity(npc, replacementData.REPLACE[1], replacementData.REPLACE[2], replacementData.REPLACE[3] or 0)
						return
					end

					data.RevelReskin = currentStage
					data.RevelReskinData = REVEL.CopyTable(replacementData)
					success = true

				else
					data.RevelCheckedReplacement = true		
				end

			else
				data.RevelCheckedReplacement = true
			end

			if onUpdate then
				data.RevelCheckedReplacement = true
			end
		end

		return success
	end

	revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, position, velocity, spawner, seed)

		if entType >= 10 and entType < 999 then

			local currentStage = StageAPI.GetCurrentStage()
			if currentStage then
				currentStage = currentStage.Alias or currentStage.Name
			end

			if currentStage and REVEL.EntityReplacements[currentStage] then

				local stageTable = REVEL.EntityReplacements[currentStage]

				--get type data
				local replacementData = stageTable.Replacements[entType] or stageTable.Replacements[-1]

				if replacementData then

					--get variant data
					replacementData = replacementData[entVariant] or replacementData[-1]

					if replacementData then

						--get subtype data or this if it doesnt exist
						replacementData = replacementData[entSubType] or replacementData[-1] or replacementData

					end
				end

				--apply the replacement data if we found it
				if replacementData and type(replacementData) == "table" then

					--replace entity with other entity
					if replacementData.REPLACE then
						return {replacementData.REPLACE[1], replacementData.REPLACE[2], replacementData.REPLACE[3] or 0, seed}
					end

				end

			end

		end

	end)
	
	function REVEL.ForceReplacement(npc, overrideStage)
		npc:GetData().RevelCheckedReplacement = nil
		npc:GetData().__RevReplacedSpritesheet = nil

		return REVEL.CheckReplacements(npc, false, overrideStage, true)
	end

	StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, -5, function(npc)
		REVEL.CheckReplacements(npc)
	end)

	revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)

		REVEL.CheckReplacements(npc, true)
		
		local data, sprite = npc:GetData(), npc:GetSprite()
		if data.RevelReskinData then
			
			--handle entities that morph into different entities
			data.RevelReskinLastType = data.RevelReskinLastType or npc.Type
			data.RevelReskinLastVariant = data.RevelReskinLastVariant or npc.Variant
			data.RevelReskinLastSubType = data.RevelReskinLastSubType or npc.SubType
		
			if data.RevelReskinLastType ~= npc.Type or data.RevelReskinLastVariant ~= npc.Variant or data.RevelReskinLastSubType ~= npc.SubType then
				REVEL.ForceReplacement(npc, data.RevelReskin)
			end

			data.RevelReskinLastType = npc.Type
			data.RevelReskinLastVariant = npc.Variant
			data.RevelReskinLastSubType = npc.SubType

			--ice creep
			
			-----
			--1--
			-----
			do
				local spawnIceCreep = false
				
				if data.RevelReskinData.ICECREEP_ANIMATION then
				
					if sprite:IsPlaying(data.RevelReskinData.ICECREEP_ANIMATION) and (not data.RevelReskinData.ICECREEP_FRAME or (data.RevelReskinData.ICECREEP_FRAME and sprite:GetFrame() == data.RevelReskinData.ICECREEP_FRAME)) then
					
						spawnIceCreep = true
					
					end
					
				elseif data.RevelReskinData.ICECREEP_FRAME and (not data.RevelReskinData.ICECREEP_STATE or (data.RevelReskinData.ICECREEP_STATE and npc.State == data.RevelReskinData.ICECREEP_STATE)) then
					
					data.RevelReskinIceCreepFrame = data.RevelReskinIceCreepFrame or 0
					data.RevelReskinIceCreepFrame = data.RevelReskinIceCreepFrame + 1
					
					if data.RevelReskinIceCreepFrame >= data.RevelReskinData.ICECREEP_FRAME then
					
						spawnIceCreep = true
						
						data.RevelReskinIceCreepFrame = 0
						
					end
					
				end
				
				if npc:IsDead() and data.RevelReskinData.ICECREEP_DEATH then
					spawnIceCreep = true
				end
				
				if spawnIceCreep then
					local creep = REVEL.SpawnIceCreep(npc.Position, npc):ToEffect()
					if data.RevelReskinData.ICECREEP_SCALE then
						REVEL.UpdateCreepSize(creep, creep.Size * data.RevelReskinData.ICECREEP_SCALE, true)
					end
				end
			end
			
			-----
			--2--
			-----
			do
				local spawnIceCreep = false
				
				if data.RevelReskinData.ICECREEP_ANIMATION_2 then
				
					if sprite:IsPlaying(data.RevelReskinData.ICECREEP_ANIMATION_2) and (not data.RevelReskinData.ICECREEP_FRAME_2 or (data.RevelReskinData.ICECREEP_FRAME_2 and sprite:GetFrame() == data.RevelReskinData.ICECREEP_FRAME_2)) then
					
						spawnIceCreep = true
					
					end
					
				elseif data.RevelReskinData.ICECREEP_FRAME_2 and (not data.RevelReskinData.ICECREEP_STATE_2 or (data.RevelReskinData.ICECREEP_STATE_2 and npc.State == data.RevelReskinData.ICECREEP_STATE_2)) then
					
					data.RevelReskinIceCreepFrame = data.RevelReskinIceCreepFrame or 0
					data.RevelReskinIceCreepFrame = data.RevelReskinIceCreepFrame + 1
					
					if data.RevelReskinIceCreepFrame >= data.RevelReskinData.ICECREEP_FRAME_2 then
					
						spawnIceCreep = true
						
						data.RevelReskinIceCreepFrame = 0
						
					end
					
				end
				
				if npc:IsDead() and data.RevelReskinData.ICECREEP_DEATH_2 then
					spawnIceCreep = true
				end
				
				if spawnIceCreep then
					local creep = REVEL.SpawnIceCreep(npc.Position, npc):ToEffect()
					if data.RevelReskinData.ICECREEP_SCALE_2 then
						REVEL.UpdateCreepSize(creep, creep.Size * data.RevelReskinData.ICECREEP_SCALE_2, true)
					end
				end
			end
			
		end
		
	end)

	StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
		for _, npc in ipairs(REVEL.roomEnemies) do
			REVEL.CheckReplacements(npc)
		end
	end)

end


Isaac.DebugString("Revelations: Loaded Reskins/Replacements system!")
end