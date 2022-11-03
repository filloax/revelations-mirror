local hub2 = require "scripts.hubroom2"

local game = Game()
local sfx = SFXManager()

---@class Hub2.Statue
---@field Id string
---@field SoulDrop Card
---@field TrinketDrop TrinketType
---@field ConsumableCount integer?
---@field WispCount integer?
---@field FlyCount integer?
---@field SpiderCount integer?
---@field ConsumableDrop {Variant: integer?, SubType?: integer}? # Required if ConsumableCount > 0
---@field StatueAnm2 string?
---@field StatueAnimation string?
---@field StatueFrame integer?
---@field AltStatueAnm2 string?
---@field AltStatueAnimation string?
---@field AltStatueFrame integer?
---@field AltConditions (fun(): boolean)?

hub2.Hub2StatuesDropChance = .25
hub2.Hub2StatuesDropSoulChance = .2 -- hub2.Hub2StatuesDropChance first has to be true before this gets called, and such the chance will be lower
hub2.Hub2StatueEffects = {}

---@param statueData Hub2.Statue
function hub2.AddHub2Statue(statueData)
	local index
	for i, statue in ipairs(hub2.Hub2Statues) do
		if statue.Id == statueData.Id then
			index = i
			break
		end
	end
	if not index then
		index = #hub2.Hub2Statues + 1
	end
	hub2.Hub2Statues[index] = statueData
end

StageAPI.AddCallback("Hub2.0", "POST_SPAWN_CUSTOM_GRID", 1, function(customGrid)
	local room = game:GetRoom()
	local spawnIndex = customGrid.GridIndex
	local persistData = customGrid.PersistentData
	
	-- check if statue already exists and sync to that
	for _,statueData in ipairs(hub2.data.run.level.hub2Statues) do
		if statueData.Index == spawnIndex then
			persistData.StatueId = statueData.StatueId
			persistData.IsStatueBroken = statueData.IsBroken
		end
	end
	
	if not persistData.StatueId then
		local statueId
		while true do
			statueId = math.random(#hub2.Hub2Statues)
			
			local isDuplicate = false
			for _,statueData in ipairs(hub2.data.run.level.hub2Statues) do
				if statueId == statueData.StatueId then
					isDuplicate = true
					break
				end
			end
			
			if not isDuplicate then
				break
			end
		end
		
		persistData.StatueId = statueId
	end
	
	local eff = Isaac.Spawn(EntityType.ENTITY_EFFECT, 8, 0, room:GetGridPosition(spawnIndex), Vector.Zero, nil)
	eff:GetData().Hub2StatueEffect = true
	local sprite = eff:GetSprite()
	sprite:Load("gfx/backdrop/hubroom_2.0/hub_2.0_statues.anm2", true)

	local c = room:GetCenterPos()
	sprite.FlipX = eff.Position.X > c.X
	sprite.FlipY = eff.Position.Y > c.Y


	table.insert(hub2.Hub2StatueEffects, eff)
	persistData.StatueEffId = #hub2.Hub2StatueEffects
	
	if persistData.IsStatueBroken then
		sprite:SetFrame("Broken", 0)
	else 
		local gotAltStatueFrame = false
		local statue = hub2.Hub2Statues[persistData.StatueId]
		
		if statue.AltStatueFrame then
			if not statue.AltConditions or statue.AltConditions() then
				
				sprite:SetFrame("Idle", statue.AltStatueFrame)
				gotAltStatueFrame = true
			end
			
		elseif statue.AltStatueAnm2 then
			if not statue.AltConditions or statue.AltConditions() then
				
				sprite:Load(statue.AltStatueAnm2, true)
				sprite:Play(statue.AltStatueAnimation or sprite:GetDefaultAnimationName(), true)
			end
		end
		
		if not gotAltStatueFrame then
			if statue.StatueAnm2 then
				sprite:Load(statue.StatueAnm2, true)
				sprite:Play(statue.StatueAnimation or sprite:GetDefaultAnimationName(), true)
			else
				sprite:SetFrame("Idle", statue.StatueFrame)
			end
		end
	end
	
end, hub2.GRIDENT.HUB2_STATUE.Name)

StageAPI.AddCallback("Hub2.0", "POST_CUSTOM_GRID_UPDATE", 1, function(customGrid)
	local room = game:GetRoom()
	local grid = customGrid.GridEntity
	local spawnIndex = customGrid.GridIndex
	local persistData = customGrid.PersistentData
	
	if not persistData.IsStatueBroken then
		---@type Hub2.Statue
		local statue = hub2.Hub2Statues[persistData.StatueId]
		local gridPosition = room:GetGridPosition(spawnIndex)
		local statueBreaks = false
		
		for _,eff in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
			eff = eff:ToEffect()
			if eff and eff.Variant == EffectVariant.BOMB_EXPLOSION then
				local explosionRadius = 100*eff.Scale
				
				if gridPosition:Distance(eff.Position) <= explosionRadius then
					statueBreaks = true
					break
				end
			end
		end
		
		if statueBreaks then
			local sprite = hub2.Hub2StatueEffects[persistData.StatueEffId]:GetSprite()
			
			-- drop loot
			if math.random() <= hub2.Hub2StatuesDropChance then
				-- lucky enough for a soul?
				if hub2.IsCardUnlocked(statue.SoulDrop) and math.random() <= hub2.Hub2StatuesDropSoulChance then
					local dropDirection = Vector.FromAngle(45 + math.random(-30,30))
					dropDirection = Vector(dropDirection.X * (sprite.FlipX and -1 or 1), dropDirection.Y * (sprite.FlipY and -1 or 1))
					
					local card = Isaac.Spawn(
						EntityType.ENTITY_PICKUP, 
						PickupVariant.PICKUP_TAROTCARD, 
						statue.SoulDrop, 
						gridPosition + dropDirection*20,
						dropDirection * (2 + math.random()*2),
						nil
					)
					card:GetData().Hub2StatueDrop = true
				
				-- otherwise, drop trinket
				elseif not hub2.HasTrinketBeenEncounteredThisRun(statue.TrinketDrop) and hub2.IsTrinketUnlocked(statue.TrinketDrop) then
					local dropDirection = Vector.FromAngle(45 + math.random(-30,30))
					dropDirection = Vector(dropDirection.X * (sprite.FlipX and -1 or 1), dropDirection.Y * (sprite.FlipY and -1 or 1))
					
					local trinket = Isaac.Spawn(
						EntityType.ENTITY_PICKUP, 
						PickupVariant.PICKUP_TRINKET, 
						statue.TrinketDrop, 
						gridPosition + dropDirection*20,
						dropDirection * (2 + math.random()*2),
						nil
					)
					trinket:GetData().Hub2StatueDrop = true
				
				else -- if all else fails, drop consumables (or flies, spiders or wisps)
				
					local consumableCount = statue.ConsumableCount or 0
					local wispCount = statue.WispCount or 0
					local flyCount = statue.FlyCount or 0
					local spiderCount = statue.SpiderCount or 0
					
					for i=1, consumableCount do
						local dropDirection = Vector.FromAngle(45 + math.random(-30,30))
						dropDirection = Vector(dropDirection.X * (sprite.FlipX and -1 or 1), dropDirection.Y * (sprite.FlipY and -1 or 1))
						
						local pickup = Isaac.Spawn(
							EntityType.ENTITY_PICKUP, 
							statue.ConsumableDrop.Variant or 0, 
							statue.ConsumableDrop.SubType or 0, 
							gridPosition + dropDirection*20,
							dropDirection * (2 + math.random()*2),
							nil
						)
						pickup:GetData().Hub2StatueDrop = true
					end
					
					if wispCount ~= 0 then
						local numPlayers = game:GetNumPlayers()
						for i=0, numPlayers - 1 do
							local player = Isaac.GetPlayer(i)
							for i=1, math.ceil(wispCount/numPlayers) do
								player:AddWisp(1, gridPosition)
							end
						end
					end
					if flyCount ~= 0 then
						for i=1, flyCount do
							Isaac.Spawn(
								EntityType.ENTITY_FAMILIAR, 
								FamiliarVariant.BLUE_FLY, 
								0, 
								gridPosition + RandomVector()*math.random(0,15),
								Vector.Zero,
								nil
							)
						end
					end
					if spiderCount ~= 0 then
						for i=1, spiderCount do
							local dropDirection = Vector.FromAngle(45 + math.random(-30,30))
							dropDirection = Vector(dropDirection.X * (sprite.FlipX and -1 or 1), dropDirection.Y * (sprite.FlipY and -1 or 1))
							
							Isaac.Spawn(
								EntityType.ENTITY_FAMILIAR, 
								FamiliarVariant.BLUE_SPIDER, 
								0, 
								gridPosition + RandomVector()*math.random(0,15),
								dropDirection * 2.5,
								nil
							)
						end
					end
				end
			end
			
			grid:GetSprite():Load("gfx/grid/grid_rock.anm2", true)
			grid:GetSprite():ReplaceSpritesheet(0, "gfx/grid/rocks_depths.png")
			grid:GetSprite():LoadGraphics()
			sprite:Play("Broken", true)
			persistData.IsStatueBroken = true
			
			sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.8, 0)
			for i=1, math.random(3,5) do
				local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, gridPosition + Vector.FromAngle(math.random(0,359))*20*math.random(), Vector.Zero, nil)
				particle:Update()
				particle.Velocity = Vector.FromAngle(math.random(0,359))*5*math.random()
				particle:GetSprite():Play("rubble_alt", true)
			end
			
			for _,statueData in ipairs(hub2.data.run.level.hub2Statues) do
				if statueData.Index == spawnIndex then
					statueData.IsBroken = true
				end
			end
		end
	end
end, hub2.GRIDENT.HUB2_STATUE.Name)