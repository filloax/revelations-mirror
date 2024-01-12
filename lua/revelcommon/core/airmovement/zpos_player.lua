local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
return function()

function REVEL.SpringPlayer(player, isTutorial, changeInitialHeight)
	if REVEL.ZPos.GetPosition(player) > 0
	or player:GetSprite():IsPlaying("Jump") then
		return 
	end
	
	if isTutorial then
		REVEL.ZPos.SetData(player, {
			ZVelocity = 5,
			Gravity = 0.20,
			ZPosition = changeInitialHeight or 15,
		})
	else
		REVEL.ZPos.SetData(player, {
			ZVelocity = 4,
			Gravity = 0.23,
			ZPosition = changeInitialHeight or 15,
		})
	end
end
      
--do special handling for the player
local function ResetPlayerAirMovementData(player)
	REVEL.ZPos.SetData(player, {
		Gravity = 0.23,
		DisableCollision = true,
		BounceFromGrid = true,
		BounceFromGridZVelocity = 4,
		LandFromGrid = false,
		PoofInPits = true
	})
end

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
	RoomHasNPCAirMovement = false

	for _, player in ipairs(REVEL.players) do
		ResetPlayerAirMovementData(player)
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	ResetPlayerAirMovementData(player)
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
	local data, sprite = REVEL.GetData(player), player:GetSprite()
	if data.ZposPitfalling then
        if sprite:IsFinished("FallIn") then
            data.TakingPitDamage = true
            player:TakeDamage(1, DamageFlag.DAMAGE_PITFALL, EntityRef(player), 25)
            data.TakingPitDamage = nil
            REVEL.LockEntityVisibility(player, "ZposPitfall")
            player.Velocity = Vector.Zero
            player:StopExtraAnimation()
            data.ZposPitfallingTime = 15
        
        elseif data.ZposPitfallingTime then
            data.ZposPitfallingTime = data.ZposPitfallingTime - 1
            player.Velocity = Vector.Zero
			if data.ZposPitfallingTime <= 0 then
				data.ZposPitfallingTime = nil
				REVEL.UnlockEntityVisibility(player, "ZposPitfall")
                player:AnimatePitfallOut()
			end
		elseif sprite:IsPlaying("JumpOut") then
            if sprite:GetFrame() >= 10 
            and not data.ZposPitfallingJumpedOut then
                player.Position = REVEL.room:GetGridPosition(data.ZposSafeGroundIndex)
                data.ZposPitfallingJumpedOut = true
				REVEL.DebugStringMinor("Moved player to safe position", player.Position, REVEL.room:GetGridIndex(player.Position))
            end
        elseif sprite:IsFinished("JumpOut") then
            data.ZposPitfalling = nil
			data.ZposPitfallingJumpedOut = nil
			REVEL.UnlockPlayerControls(player, "ZposPitfalling")
        end
	end
end)

local function SpawnZposManager(player)
	local data = REVEL.GetData(player)
	local zposManager = data.ZPosManager and data.ZPosManager.Ref
	if not zposManager then
		zposManager = REVEL.ENT.SPRING_MANAGER:spawn(player.Position, Vector.Zero, player)
		zposManager:GetData().OwnerPlayer = EntityPtr(player)
		data.ZPosManager = EntityPtr(zposManager)
	end
end

---@param airMovementData AirMovementData
revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_UPDATE, function(_, entity, airMovementData)
	local data = REVEL.GetData(entity)
	-- If nothing is overriding player pre update gfx
	if (airMovementData.ZPosition ~= 0 or airMovementData.ZVelocity ~= 0)
	and data.ZposReachedPlayerDefaultPreGfx
	then
		SpawnZposManager(entity)
		REVEL.LockEntityVisibility(entity, "ZPos")
	else
		if REVEL.room:GetGridCollisionAtPos(entity.Position) == GridCollisionClass.COLLISION_NONE then
			data.ZposSafeGroundIndex = REVEL.room:GetGridIndex(entity.Position)
		end
		REVEL.UnlockEntityVisibility(entity, "ZPos")
	end
end, EntityType.ENTITY_PLAYER)

-- Double check to see if something is overriding player's gfx update

revel:AddPriorityCallback(RevCallbacks.PRE_ZPOS_UPDATE_GFX, CallbackPriority.EARLY, function(_, entity, airMovementData)
	local data = REVEL.GetData(entity)
	data.ZposReachedPlayerDefaultPreGfx = false
end, EntityType.ENTITY_PLAYER)

revel:AddPriorityCallback(RevCallbacks.PRE_ZPOS_UPDATE_GFX, CallbackPriority.LATE, function(_, entity, airMovementData)
	local data = REVEL.GetData(entity)
	data.ZposReachedPlayerDefaultPreGfx = true
	return false
end, EntityType.ENTITY_PLAYER)

local function RenderJumpingPlayer(player, renderOffset)
    local pos = Isaac.WorldToRenderPosition(player.Position) 
		+ player.SpriteOffset
        + Vector(0, -REVEL.ZPos.GetPosition(player)) * REVEL.SCREEN_TO_WORLD_RATIO
        + renderOffset -- - REVEL.room:GetRenderScrollOffset()
    local customJumpSprites = REVEL.GetData(player).CustomJumpSprites

	local data = REVEL.GetData(player)
	if not data.ZposReachedPlayerDefaultPreGfx then return end

    if customJumpSprites then
        for _, sprite in ipairs(customJumpSprites) do
            sprite:Render(pos, Vector.Zero, Vector.Zero)
        end
    else
        local wasInvisible = not player.Visible
        player.Visible = true
        player:RenderGlow(pos)
        player:RenderBody(pos)
        player:RenderHead(pos)
        player:RenderTop(pos)
        player.Visible = not wasInvisible
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect, renderOffset)
	local data = effect:GetData()
	local player = data.OwnerPlayer and data.OwnerPlayer.Ref
    if player then
		player = player:ToPlayer()
        effect.Position = player.Position
		effect.Velocity = player.Velocity

		if REVEL.ZPos.GetPosition(player) ~= 0 or REVEL.ZPos.GetVelocity(player) ~= 0 then
			RenderJumpingPlayer(player, renderOffset)
        end
    else
		effect:Remove()
	end
end, REVEL.ENT.SPRING_MANAGER.variant)

function REVEL.ZPos.StartPlayerPitfall(player, grid, safeIndex)
	local data = REVEL.GetData(player)

	data.ZposSafeGroundIndex = safeIndex or data.ZposSafeGroundIndex or REVEL.room:GetGridIndex(player.Position)
	REVEL.LockPlayerControls(player, "ZposPitfalling")
	if grid then
		player.Position = grid.Position
	end
	player:AnimatePitfallIn()
	data.ZposPitfalling = true
end

---@param landFromGrid GridEntity
revel:AddCallback(RevCallbacks.POST_ENTITY_ZPOS_LAND, function(_, entity, airMovementData, landFromGrid, oldZSpeed)
	local data = REVEL.GetData(entity)

	if landFromGrid then
		local canFly = entity:ToPlayer().CanFly
		if canFly then
			airMovementData.ZVelocity = 0
		end
		if landFromGrid.CollisionClass == GridCollisionClass.COLLISION_PIT then
			airMovementData.ZVelocity = 0
			airMovementData.ZPosition = REVEL.ZPos.GetGroundLevel(entity)
			if not canFly then
				REVEL.ZPos.StartPlayerPitfall(player:ToPlayer(), landFromGrid)
				REVEL.DebugStringMinor("Player fell in pit at", landFromGrid:GetGridIndex())
			end
			return false
		end
	end
	if math.abs(oldZSpeed) > 1.5 then
		REVEL.sfx:Play(SoundEffect.SOUND_SCAMPER, 0.5, 0, false, 1)
	end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
    if action == ButtonAction.ACTION_ITEM and hook == InputHook.IS_ACTION_TRIGGERED 
	and REVEL.ZPos.GetPosition(entity) > 0 then
        return false
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player,  amount, flags, source, cooldown)
    local data = REVEL.GetData(player)
    if data.ZposPitfalling and not data.TakingPitDamage then
        return false
    end
end, EntityType.ENTITY_PLAYER)


--#region Deprecated

---@deprecated Will not be needed with the new stuff
function REVEL.ZPos.SetPlayerJumpSprites(player, ...)
    local data = REVEL.GetData(player)

    data.CustomJumpSprites = {...}
end

---@deprecated Will not be needed with the new stuff
function REVEL.ZPos.ClearPlayerJumpSprites(player)
    REVEL.GetData(player).CustomJumpSprites = nil
end

--#endregion

end