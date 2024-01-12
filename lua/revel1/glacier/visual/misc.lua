local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

function REVEL.SpawnFootprint(player, anm2)
    if player:IsFlying() or not player.Visible then return end
    if player:GetData().OnDuneTile then return end

    local data = player:GetData()
    if data.LastFootprintPosition and data.LastFootprintPosition:DistanceSquared(player.Position) < 8 ^ 2 then
        return
    end

    local offset
    if math.abs(player.Velocity.Y) >= math.abs(player.Velocity.X) then
        offset = Vector(2, 0)
    else
        offset = Vector(0, 2)
    end

    if data.FootprintAlternate then
        offset = -offset
    end

    data.FootprintAlternate = not data.FootprintAlternate
    data.LastFootprintPosition = player.Position

    local eff = StageAPI.SpawnFloorEffect(player.Position + offset, Vector.Zero, nil, anm2, true)
    eff:GetData().Footprint = true
    eff:GetSprite():Play("idle", true)
end

local FootprintsEnabled = true

---Resets on new room
---@param val boolean
function REVEL.Glacier.SetFootprintsEnabledForRoom(val)
    FootprintsEnabled = val
end

local function footprintPostNewRoom()
    FootprintsEnabled = true
    for _, player in ipairs(REVEL.players) do
        local data = player:GetData()
        data.LastFootprintPosition = nil
        data.FootprintAlternate = nil
    end
end

local function footprintPostPeffectUpdate(_, player)
    if REVEL.room:GetFrameCount() % 3 ~= 0 then return end

    if REVEL.STAGE.Glacier:IsStage() and FootprintsEnabled then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.SnowFloorRoomTypes, currentRoomType) then
            REVEL.SpawnFootprint(player, "gfx/effects/revel1/snow_footprint.anm2")
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, footprintPostNewRoom)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, footprintPostPeffectUpdate)

    

function REVEL.SpawnLandingDust(entity, oldZVelocity, fromPit, rtint, gtint, btint)
    if fromPit and not (fromPit and fromPit.CollisionClass == GridCollisionClass.GRIDCOLL_NONE) then
        return
    end

    -- temp, debug a weird issue
    if type(oldZVelocity) == "table" then
        REVEL.DebugLog("error: oldZVelocity is table:", REVEL.ShallowTableToString(oldZVelocity))
    end

    local origDustVelocity = Vector(10,0)
    local velocity = math.ceil(math.abs(oldZVelocity))
    local dustAmount = math.min(14, math.max(8, (velocity+2)))
    local dustSize = math.min(150, math.max(80, (velocity+2)*10))
    for i=1, dustAmount do
        local dustVelocity = origDustVelocity:Resized(math.random(500,800)*0.01)
        dustVelocity = dustVelocity:Rotated((360/dustAmount)*i)
        local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, entity.Position, dustVelocity, entity)
        local darkMod = math.random(-20,20)
        dust.Color = Color(1, 1, 1, 1,conv255ToFloat( rtint+darkMod, gtint+darkMod, btint+darkMod))
        dust.SpriteScale = Vector(1,1) * (math.random(dustSize-10,dustSize+10)*0.01)
        local extraUpdates = math.random(0,2)
        if extraUpdates > 0 then
            for i=1, extraUpdates do
                dust:Update()
            end
        end
    end
end

revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, entity, airMovementData, fromPit, oldZVelocity)
    if REVEL.STAGE.Glacier:IsStage() then
        local currentRoomType = StageAPI.GetCurrentRoomType()
        if REVEL.includes(REVEL.SnowFloorRoomTypes, currentRoomType) then
            REVEL.SpawnLandingDust(entity, oldZVelocity, fromPit, 110, 110, 200)
        end
    end
end, EntityType.ENTITY_PLAYER)

    
REVEL.BlueBloodImmunity = {
	[EntityType.ENTITY_POOTER] = true,
	[EntityType.ENTITY_KEEPER] = true,
	[EntityType.ENTITY_SPIDER] = true,
	-- [EntityType.ENTITY_THE_HAUNT] = true,
	[EntityType.ENTITY_MINISTRO] = true,
	[EntityType.ENTITY_BLISTER] = true,
	[EntityType.ENTITY_FIREPLACE] = true
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if not eff:GetData().GlacierReskinCheck then
		if (REVEL.STAGE.Glacier:IsStage()
        and not REVEL.BlueBloodImmunity[eff.SpawnerType] and eff.SpawnerType >= 10 and eff.SpawnerType <= 999)
        or eff:GetData().ForceGlacierSkin then
            eff.Color = Color.Default
			eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/frost_bulletatlas.png")
			eff:GetSprite():LoadGraphics()
		end
		eff:GetData().GlacierReskinCheck = true
	end
end, EffectVariant.BLOOD_PARTICLE)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if not eff:GetData().GlacierReskinCheck then
		if (REVEL.STAGE.Glacier:IsStage()
        and not REVEL.BlueBloodImmunity[eff.SpawnerType] and eff.SpawnerType >= 10 and eff.SpawnerType <= 999)
        or eff:GetData().ForceGlacierSkin then
			eff.Color = REVEL.WaterSplatColor
		end
		eff:GetData().GlacierReskinCheck = true
	end
end, EffectVariant.BLOOD_SPLAT)

REVEL.BluePoopImmunity = {
	[EntityType.ENTITY_DIP] = true
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if not eff:GetData().GlacierReskinCheck then
		if REVEL.STAGE.Glacier:IsStage() and not eff:GetData().NoGibOverride
		and not REVEL.BluePoopImmunity[eff.SpawnerType] then
			eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/glacier_poop_gibs.png")
			eff:GetSprite():LoadGraphics()
		end
		eff:GetData().GlacierReskinCheck = true
	end
end, EffectVariant.POOP_PARTICLE)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
	if not eff:GetData().GlacierReskinCheck then
		if REVEL.STAGE.Glacier:IsStage() and not eff:GetData().NoGibOverride
		and not REVEL.BluePoopImmunity[eff.SpawnerType] then
			eff:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/glacier_poop_poof.png")
			eff:GetSprite():LoadGraphics()
		end
		eff:GetData().GlacierReskinCheck = true
	end
end, EffectVariant.POOP_EXPLOSION)

--glacier bony projectiles
revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, function(_, pro)
    if REVEL.STAGE.Glacier:IsStage() then
        if pro.Variant == ProjectileVariant.PROJECTILE_BONE and pro.SpawnerType == EntityType.ENTITY_BONY and pro.SpawnerVariant == 0 then
            local data = pro:GetData()
            data.IsGlacierBone = true
            local sprite = pro:GetSprite()
            sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/reskins/glacier_bony_projectile.png")
            sprite:LoadGraphics()
            pro:Update()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Variant == ProjectileVariant.PROJECTILE_BONE then
        local data = ent:GetData()
        if data.IsGlacierBone then
            for _, eff in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, -1, false, false)) do
                if eff.Position:Distance(ent.Position) < 5 and eff.FrameCount <= 1 then
                    local effSprite = eff:GetSprite()
                    effSprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/reskins/glacier_bony_projectile_gibs.png")
                    effSprite:LoadGraphics()
                end
            end
        end
    end
end, EntityType.ENTITY_PROJECTILE)

end