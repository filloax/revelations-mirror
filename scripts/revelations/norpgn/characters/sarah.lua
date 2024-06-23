local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()
-----------
-- SARAH --
-----------
do

StageAPI.AddPlayerGraphicsInfo(REVEL.CHAR.SARAH.Type, "gfx/ui/stage/revelcommon/sarah_portrait.png", "gfx/ui/boss/revelcommon/sarah_name.png")

function REVEL.IsSarah(player)
    return player:GetPlayerType() == REVEL.CHAR.SARAH.Type and player.Variant == 0 
end

REVEL.AddCharacterUnlock(REVEL.CHAR.SARAH.Type, "PENANCE", LevelStage.STAGE3_2, LevelStage.STAGE3_1, nil, nil, REVEL.IsSarah)
REVEL.AddCharacterUnlock(REVEL.CHAR.SARAH.Type, "PILGRIMS_WARD", LevelStage.STAGE6, nil, StageType.STAGETYPE_WOTL, nil, REVEL.IsSarah)
REVEL.AddCharacterUnlock(REVEL.CHAR.SARAH.Type, "HEAVENLY_BELL", LevelStage.STAGE6, nil, StageType.STAGETYPE_ORIGINAL, nil, REVEL.IsSarah)
REVEL.AddCharacterUnlock(REVEL.CHAR.SARAH.Type, "OPHANIM", LevelStage.STAGE4_2, LevelStage.STAGE4_1, nil, nil, REVEL.IsSarah)
REVEL.AddCharacterUnlock(REVEL.CHAR.SARAH.Type, "LIL_MICHAEL", LevelStage.STAGE4_3, nil, nil, nil, REVEL.IsSarah)

function REVEL.HasPenanceEffect(player)
	return REVEL.IsSarah(player) or player:HasCollectible(REVEL.ITEM.PENANCE.id)
end

function REVEL.SarahInit(player)
	REVEL.pool:RemoveCollectible(REVEL.ITEM.PENANCE.id)
	player:AddEternalHearts(1)
	player:AddKeys(1)
	player:AddNullCostume(REVEL.COSTUME.SARAH)
	-- player:AddNullCostume(REVEL.ITEM.PENANCE.costume)
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
	if not continued then
		for _, player in ipairs(REVEL.players) do
			if REVEL.IsSarah(player) then
				REVEL.SarahInit(player)
			end
		end
	end
end)

local replacedHeartSubTypes = {
	[HeartSubType.HEART_BLENDED] = true,
	[HeartSubType.HEART_SOUL] = true,
	[HeartSubType.HEART_HALF_SOUL] = true
}

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, t, v, s, pos, vel, spawn, seed)
	if t == EntityType.ENTITY_PICKUP and v == PickupVariant.PICKUP_HEART and replacedHeartSubTypes[s] then
        local isSarah = REVEL.some(REVEL.players, function(player)
            return REVEL.IsSarah(player)
        end)

		if isSarah then
            if REVEL.room:IsFirstVisit() then
    			return {
    				t,
    				v,
    				HeartSubType.HEART_BLACK,
    				seed
    			}
            else
                return {
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_COIN,
                    CoinSubType.COIN_PENNY
                }
            end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    local isSarah
    for _, player in ipairs(REVEL.players) do
        if REVEL.IsSarah(player) then
            isSarah = true
            break
        end
    end

    if isSarah and pickup.Variant == PickupVariant.PICKUP_HEART and replacedHeartSubTypes[pickup.SubType] then
        pickup:Morph(pickup.Type, pickup.Variant, HeartSubType.HEART_BLACK, true)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL , function()
    -- Sarah cannot get devil deals.
    for _, player in ipairs(REVEL.players) do
        if REVEL.IsSarah(player) then
            REVEL.level:InitializeDevilAngelRoom(true, false)
        end
    end
end)

do -- Broken Wings
    ------------------
    -- BROKEN WINGS --
    ------------------
    local animBlacklist = {"Pickup", "Hit", "Appear", "Death", "Sad", "Happy", "TeleportUp", "TeleportDown", "Trapdoor", "Jump", "Glitch", "LiftItem", "HideItem", "UseItem", "LostDeath", "FallIn", "HoleDeath", "JumpOut", "PickupWalkDown", "PickupWalkLeft", "PickupWalkUp", "PickupWalkRight", "LightTravel"}

    revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    	-- if the broken wings are active allow flight
        if REVEL.IsSarah(player) then
            if flag == CacheFlag.CACHE_FLYING then
        		if revel.data.run.brokenWingsState[REVEL.GetPlayerID(player)] == 1 then
        			player.CanFly = true
        		end
            elseif flag == CacheFlag.CACHE_FIREDELAY then
                player.MaxFireDelay = math.ceil(player.MaxFireDelay * 0.9)
            end
        end
    end)

    revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
        if REVEL.IsSarah(player) then
            local data = REVEL.GetData(player)
            local wingState = revel.data.run.brokenWingsState[REVEL.GetPlayerID(player)]
            local brokenWings = data.BrokenWings and data.BrokenWings.Ref
            if wingState == 0 and not player.CanFly then
                if not brokenWings or not brokenWings:Exists() then
                    brokenWings = REVEL.SpawnCustomGlow(player, "WalkDownIdle", "gfx/itemeffects/revelcommon/broken_wings.anm2")
                    brokenWings:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_DONT_OVERWRITE | EntityFlag.FLAG_NO_TARGET)
                    data.BrokenWings = EntityPtr(brokenWings)
                else
                    local spr, anim = REVEL.GetData(brokenWings).customGlowSprite, nil

                    local headDir = player:GetHeadDirection()

                    anim = "Walk"..(REVEL.dirToString[headDir or Direction.DOWN] or "Down")

                    local blacklist
                    if REVEL.MultiPlayingCheck(player:GetSprite(), table.unpack(animBlacklist)) then
                        blacklist = true
                    end

                    if REVEL.ZPos.GetPosition(player) > 0 then
                        blacklist = true
                    end

                    if anim and not blacklist then
                      if anim == "WalkUp" then
                        brokenWings.DepthOffset = 10
                      else
                        brokenWings.DepthOffset = -10
                      end

                      if not (spr:IsPlaying(anim) or spr:IsPlaying(anim.."Idle")) then
                        spr:Play(anim.."Idle", true)
                        brokenWings.Position = brokenWings.Parent.Position
                      end

                      if spr:IsPlaying(anim.."Idle") and math.random(60) == 1 then
                        spr:Play(anim)
                      end
                    else
                      spr:Play("Invis", true)
                    end

                    spr.Color = brokenWings.Parent:GetSprite().Color
                    brokenWings.Visible = brokenWings.Parent.Visible
                end
            elseif brokenWings then
                if brokenWings:Exists() then
                    brokenWings:Remove()
                end
                data.BrokenWings = nil
            end
        end
    end)
end

do -- Penance and Sarah shared
    ---@type table<string, RevSound>
    local Sounds = {
        SIN_SPAWN = {Sound = SoundEffect.SOUND_DEVILROOM_DEAL},
        -- SIN_CHARGE_START = {Sound = SoundEffect.SOUND_MONSTER_YELL_A},
        SIN_CHARGE = {Sound = SoundEffect.SOUND_MONSTER_YELL_A, Volume = 0.8, Pitch = 1.15},
        SIN_COLLECT = {Sound = SoundEffect.SOUND_BOSS2_BUBBLES, Pitch = 0.8},
        COLLECT_HEART = {Sound = SoundEffect.SOUND_THUMBSUP, PitchBase = 0.8, PitchIncrease = 0.1},
        SPAWN_REWARD = {Sound = SoundEffect.SOUND_HOLY},
    }

	function REVEL.GetExtraHearts(player)
		local soulHearts, boneHearts = player:GetSoulHearts(), player:GetBoneHearts()
		-- This is the number of individual hearts shown in the HUD, minus heart containers
		local extraHearts = math.ceil(soulHearts / 2) + boneHearts

		-- Since bone hearts can be inserted anywhere between soul hearts, we need a separate counter to track which soul heart we're currently at
		local currentSoulHeart = 0

		local heartTypes = {}
		for i=0, extraHearts-1 do
			if player:IsBoneHeart(i) then
				heartTypes[#heartTypes + 1] = {Type = "Bone", Position = currentSoulHeart}
			else
				local isBlackHeart = player:IsBlackHeart(currentSoulHeart + 1) -- +1 because only the second half of a black heart is considered black
				if isBlackHeart then
					heartTypes[#heartTypes + 1] = {Type = "Black", Position = currentSoulHeart}
				else
					heartTypes[#heartTypes + 1] = {Type = "Soul", Position = currentSoulHeart}
				end

				-- Move to the next heart
				currentSoulHeart = currentSoulHeart + 2
			end
		end

		return heartTypes
	end

	function REVEL.BringBlackHeartsToFront(player)
		local extraHearts = REVEL.GetExtraHearts(player)

		local movedBlackHearts = 0
		for i, heart in ipairs(extraHearts) do
			if heart.Type == "Black" then
				for i2, heart2 in ipairs(extraHearts) do
					if i2 > i and heart2.Type ~= "Black" then
						player:RemoveBlackHeart(heart.Position + 1)
						movedBlackHearts = movedBlackHearts + 2
						break
					end
				end
			end
		end

		if movedBlackHearts > 0 then
			player:AddSoulHearts(-movedBlackHearts)
			player:AddBlackHearts(movedBlackHearts)
		end
	end

	function REVEL.RemoveAllBlackHearts(player)
		local extraHearts = REVEL.GetExtraHearts(player)

		local removedBlackHearts = 0
        local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
		for i, heart in ipairs(extraHearts) do
			if heart.Type == "Black" and not (removedBlackHearts >= 2 and hasBirthright) then
				player:RemoveBlackHeart(heart.Position + 1)
				removedBlackHearts = removedBlackHearts + 2
			end
		end

		if removedBlackHearts > 0 then
			player:AddSoulHearts(-removedBlackHearts)
		end

		return removedBlackHearts
	end

    function REVEL.RemoveLastBlackHeart(player)
        local extraHearts = REVEL.GetExtraHearts(player)

        local lastBlackHeartPos
        for i, heart in ipairs(extraHearts) do
            if heart.Type == "Black" then
                lastBlackHeartPos = heart.Position + 1
            end
        end

        if lastBlackHeartPos then
            player:RemoveBlackHeart(lastBlackHeartPos)
            player:AddSoulHearts(-2)
        end
    end

    local layouts = {}
    for name, shape in pairs(RoomShape) do
        local layout = StageAPI.CreateEmptyRoomLayout(shape)
        layouts[#layouts + 1] = layout
    end

    REVEL.SarahAngelRoomLayouts = StageAPI.RoomsList("SarahAngelRoom", layouts)

    local function ReaddOutBlackHearts(player)
        if revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] > 0 then
            player:AddBlackHearts(revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)])
            revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] = 0
            REVEL.PlaySound(Sounds.SIN_COLLECT)
        end
    end

    StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
        if REVEL.IsSaveDataLoaded() then
            local hasPenanceEffect
            for _, player in ipairs(REVEL.players) do
                ReaddOutBlackHearts(player)
                hasPenanceEffect = hasPenanceEffect or REVEL.HasPenanceEffect(player)
            end

            if hasPenanceEffect and not REVEL.room:IsFirstVisit() then
                local blackHearts = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, false, false)
                for _, heart in ipairs(blackHearts) do
                    local sin = Isaac.Spawn(REVEL.ENT.PENANCE_SIN.id, REVEL.ENT.PENANCE_SIN.variant, 1, heart.Position, Vector.Zero, nil)
                    sin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    sin.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    sin:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    sin:GetSprite():Play("transform", true)
                    REVEL.GetData(sin).State = "FleeingBlackHeart"
                    REVEL.GetData(sin).Strength = 0
                    heart:Remove()
                end
            end

            if REVEL.room:GetType() == RoomType.ROOM_ANGEL and hasPenanceEffect then
                local currentRoom = StageAPI.GetCurrentRoom()
                if not currentRoom then
                    local angels = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, -1, false, false)
                    local angelPos
                    if #angels == 1 then
                        angelPos = angels[1].Position
                    else
                        angelPos = REVEL.room:GetCenterPos() + Vector(0, -40)
                    end

                    local levelIndex = StageAPI.GetCurrentRoomID()
                    local newRoom = StageAPI.LevelRoom {
                        RoomsList = REVEL.SarahAngelRoomLayouts,
                        LevelIndex = levelIndex,
                    }
                    newRoom.PersistentData.AngelPosition = {X = angelPos.X, Y = angelPos.Y}
                    newRoom:SetTypeOverride(RoomType.ROOM_ANGEL)
                    StageAPI.SetCurrentRoom(newRoom)
                    newRoom:Load()
                    currentRoom = newRoom
                end

                if not revel.data.run.level.destroyedPenanceStatue then
                    local angelPos = Vector(currentRoom.PersistentData.AngelPosition.X, currentRoom.PersistentData.AngelPosition.Y)
                    local penanceAngel = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, angelPos, Vector.Zero, nil)
                    local grid = Isaac.GridSpawn(GridEntityType.GRID_ROCK, 0, angelPos, true)
                    REVEL.GetData(penanceAngel).IsPenanceAngel = true
                    penanceAngel:GetSprite():Load("gfx/effects/revelcommon/penance_angel.anm2", true)
                    penanceAngel:GetSprite():Play("idle", true)
                end
            end
        end
    end)

    revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
        revel.data.run.urielSpawned = true
    end, EntityType.ENTITY_URIEL)

    local orbMaxExtraHeight = -25
    local orbBaseHeight = -10
    local orbMaxAngleChange = 90
    local orbMaxPositionChange = 75

    local function spawnPenanceReward(id, variant, subtype, spawnPos)
        local free = REVEL.room:FindFreePickupSpawnPosition(spawnPos, 0, true)
        Isaac.Spawn(id, variant, subtype or 0, free, Vector.Zero, nil)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, free, Vector.Zero, nil)
        REVEL.PlaySound(Sounds.SPAWN_REWARD)
    end

    function REVEL.GetSinConvergePoint()
        return REVEL.room:GetCenterPos() + (RandomVector() * REVEL.room:GetGridWidth() * 30)
    end

    function REVEL.MakeOrbSinOrb(orb, player, convergePoint, otherOrbs)
        orb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        orb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
        orb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        REVEL.GetData(orb).PenancePlayer = player
        REVEL.GetData(orb).PenanceConvergePoint = convergePoint
        if otherOrbs then
            REVEL.GetData(orb).OtherOrbs = otherOrbs
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
        if not REVEL.GetData(eff).IsPenanceAngel then
            return
        end

        if REVEL.room:GetGridCollisionAtPos(eff.Position) == 0 then
            if revel.data.run.urielSpawned then
                Isaac.Spawn(EntityType.ENTITY_GABRIEL, 0, 0, eff.Position, Vector.Zero, nil)
            else
                Isaac.Spawn(EntityType.ENTITY_URIEL, 0, 0, eff.Position, Vector.Zero, nil)
            end

            revel.data.run.level.destroyedPenanceStatue = true

            REVEL.room:SetClear(false)
            for i = 0, 7 do
                local door = REVEL.room:GetDoor(i)
                if door then
                    door:Close()
                end
            end

            REVEL.music:Play(Music.MUSIC_BOSS, 0)
            REVEL.music:UpdateVolume()

            local data = REVEL.GetData(eff)
            if not data.Orbs then
                data.Orbs = {}
            end

            for i = 1, math.random(1, 2) do
                data.Orbs[#data.Orbs + 1] = Isaac.Spawn(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 0, eff.Position, RandomVector() * math.random(6, 9), nil)
            end

            local playerAtFault
            for _, player in ipairs(REVEL.players) do
                if REVEL.HasPenanceEffect(player) then
                    playerAtFault = player
                    revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] = revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] + 2
                    break
                end
            end

            for _, orb in ipairs(data.Orbs) do
                local convergePoint = REVEL.GetSinConvergePoint()
                REVEL.MakeOrbSinOrb(orb, playerAtFault, convergePoint, {orb})
            end

            eff:Remove()
            return
        end

        if REVEL.room:GetFrameCount() < 30 then
            return
        end

        local data, sprite = REVEL.GetData(eff), eff:GetSprite()
        if revel.data.run.level.penanceHealState == 1 then
            if sprite:IsFinished("convert") then
                revel.data.run.level.penanceHealState = 2
                sprite:Play("idle", true)
            elseif not sprite:IsPlaying("convert") then
                sprite:Play("convert", true)
            elseif sprite:GetFrame() == 18 then
                for _, player in ipairs(REVEL.players) do
                    if REVEL.HasPenanceEffect(player) then
                        player:AddHearts(24)
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, player.Position, Vector.Zero, player)
                    end
                end
            end

            return
        end

        if not data.Orbs then
            data.Orbs = {}
        end

        local hasDuality, hasJudasTongue
        for _, player in ipairs(REVEL.players) do
            if REVEL.HasPenanceEffect(player) then
                hasDuality = hasDuality or player:HasCollectible(CollectibleType.COLLECTIBLE_DUALITY)
                if REVEL.IsSarah(player) then
                    hasJudasTongue = hasJudasTongue or player:HasTrinket(TrinketType.TRINKET_JUDAS_TONGUE)
                end
            end
        end

        local neededOrbs = revel.data.run.penanceTier + 1
        if hasJudasTongue then
            neededOrbs = math.max(1, neededOrbs - 1)
        end

        if #data.Orbs < neededOrbs then
            for _, player in ipairs(REVEL.players) do
                if REVEL.HasPenanceEffect(player) then
                    local pdata = REVEL.GetData(player)
                    if REVEL.GetBlackHearts(player) > 0 and #data.Orbs < neededOrbs then
                        if not pdata.CanTakeBlackHeartFrame or player.FrameCount > pdata.CanTakeBlackHeartFrame then
                            REVEL.RemoveLastBlackHeart(player)
                            pdata.CanTakeBlackHeartFrame = player.FrameCount + 15
                            local orb = Isaac.Spawn(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 0, player.Position, Vector.Zero, nil)
                            orb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                            orb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                            orb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                            REVEL.GetData(orb).PenancePlayer = player
                            data.Orbs[#data.Orbs + 1] = orb
                            local playerID = REVEL.GetPlayerID(player)
                            revel.data.run.penanceBlackHeartsOut[playerID] = revel.data.run.penanceBlackHeartsOut[playerID] + 2
                        end
                    end
                end
            end
        end

        local allOrbsAtTargetPos = true
        for i, orb in ipairs(data.Orbs) do
            local usePercentage
            if i == 1 and neededOrbs == 1 then
                usePercentage = 0.5
            else
                usePercentage = (i - 1) / (neededOrbs - 1)
            end

            local height = Vector(0, orbMaxExtraHeight):Rotated(REVEL.Lerp(-orbMaxAngleChange, orbMaxAngleChange, usePercentage)).Y
            orb.SpriteOffset = REVEL.Lerp(orb.SpriteOffset, Vector(0, height + orbBaseHeight), 0.15)
            local targetPos = Vector(REVEL.Lerp(eff.Position.X - orbMaxPositionChange, eff.Position.X + orbMaxPositionChange, usePercentage), eff.Position.Y)
            orb.Velocity = REVEL.Lerp(orb.Position, targetPos, 0.15) - orb.Position
            if orb.Position:DistanceSquared(targetPos) > orb.Size ^ 2 then
                allOrbsAtTargetPos = false
                REVEL.GetData(orb).WasAtTargetPos = false
            elseif not REVEL.GetData(orb).WasAtTargetPos then
                Sounds.COLLECT_HEART.Pitch = Sounds.COLLECT_HEART.PitchBase + Sounds.COLLECT_HEART.PitchIncrease * (i - 1)
                REVEL.PlaySound(Sounds.COLLECT_HEART)
                REVEL.GetData(orb).WasAtTargetPos = true
            end
        end

        if #data.Orbs == neededOrbs and allOrbsAtTargetPos then
            local sprite = eff:GetSprite()
            if sprite:IsFinished("convert") then
                for _, orb in ipairs(data.Orbs) do
                    local player = REVEL.GetData(orb).PenancePlayer
                    revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] = revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)] - 2
                    orb:GetSprite():Play("pop", true)
                end
                data.Orbs = {}

                local spawnPos = REVEL.room:GetCenterPos() + Vector(0, 40)
                if hasDuality and math.random(1, 2) == 1 then
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, REVEL.pool:GetCollectible(ItemPoolType.POOL_DEVIL, true, REVEL.room:GetAwardSeed()), spawnPos)
                else
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, spawnPos)
                end

                if revel.data.run.penanceTier > 3 then
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, 0, spawnPos)
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, spawnPos)
                elseif revel.data.run.penanceTier > 2 then
                    local isSarah
                    for _, player in ipairs(REVEL.players) do
                        if REVEL.IsSarah(player) then
                            revel.data.run.brokenWingsState[REVEL.GetPlayerID(player)] = 1
                            player:AddCacheFlags(CacheFlag.CACHE_FLYING)
                            player:EvaluateItems()
                            player:AddNullCostume(Isaac.GetCostumeIdByPath("gfx/characters/Fate.anm2"))
                            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, player.Position+Vector(0,-2), Vector.Zero, player)
                            REVEL.sfx:Play(54, 1, 0, false, 1)
                        end
                    end

                    if not isSarah then
                        spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, 0, spawnPos)
                    end
                elseif revel.data.run.penanceTier > 1 then
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, spawnPos)
                elseif revel.data.run.penanceTier > 0 then
                    spawnPenanceReward(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_GOLDEN, spawnPos)
                end

                revel.data.run.penanceTier = math.min(revel.data.run.penanceTier + 1, 4)
                sprite:Play("idle", true)
            elseif not sprite:IsPlaying("convert") then
                sprite:Play("convert", true)
                for _, orb in ipairs(data.Orbs) do
                    orb:GetSprite():Play("convert", true)
                    REVEL.GetData(orb).Converted = true
                end
            end
        end
    end, EffectVariant.ANGEL)

    --[[local penanceSin = {
        BaseDashSpeed = 16,
        MultDashSpeed = 1.75,
        FollowFriction = 0.9,
        BaseFollowSpeed = 0.35,
        MultFollowSpeed = 0.075,
        BaseChargeSpeed = 1.2, -- playbackspeed of charge animation before dash
        MultChargeSpeed = 0.1,
        BaseSize = 1,
        MultSize = 0.05
    }]]

    local penanceSin = {
        DashSpeed = {},
        FollowSpeed = {},
        ChargeSpeed = {},
        SizeScale = {},
    }

    for i = 0, 23 do
        penanceSin.DashSpeed[i+1] = REVEL.Lerp(16, 28, math.min(10, i) / 23)
        penanceSin.FollowSpeed[i+1] = REVEL.Lerp(.55, 2.8, i / 23)
        penanceSin.ChargeSpeed[i+1] = REVEL.Lerp(1.5, 4, math.min(6, i) / 23)
        penanceSin.SizeScale[i+1] = REVEL.Lerp(1, 1.8, i / 23)
    end

    local function GetPenanceSinStrengthMultiplier(npc)
        return math.max(1, REVEL.GetData(npc).Strength)
    end

    local sinParticle = REVEL.ParticleType.FromTable{
        Name = "Sarah Sin Particle",
        Anm2 =  "gfx/effects/revelcommon/black_particle.anm2",
        BaseLife = 15,
        Variants = 6,
        FadeOutStart = 0.3,
        StartScale = 0.9,
        EndScale = 1.1,
        RotationSpeedMult = 0.2
    }
    sinParticle:SetColor(Color(1,1,1,1,conv255ToFloat(15,15,15)), 0.02)

    local sinSystem = REVEL.ParticleSystems.NoGravity

    local sinEmitter = REVEL.SphereEmitter(5)

    local sinCardinalFactor = 0.75 -- the position it moves to is player's + cardinaldir * (distanceToPlayer * sinCardinalFactor). this means that 1 = will only align cardinally and 0 = will move directly to the player
    local fadeLength = 5 -- smooth fade out after dash & in after teleport

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if not REVEL.ENT.PENANCE_ORB:isEnt(npc, true) then return end

        local data, sprite = REVEL.GetData(npc), npc:GetSprite()
        if not data.Init then
            data.Init = true
            npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        end

        if data.PenanceConvergePoint then
            if not sprite:IsPlaying("idle") then
                sprite:Play("idle", true)
            end

            if npc.Position:DistanceSquared(data.PenanceConvergePoint) < npc.Size ^ 2 then
                npc.Velocity = Vector.Zero
                npc.Position = data.PenanceConvergePoint
                data.ReachedConvergePoint = true
                local allOrbsConverged = true
                for _, orb in ipairs(data.OtherOrbs) do
                    if not REVEL.GetData(orb).ReachedConvergePoint then
                        allOrbsConverged = nil
                        break
                    end
                end

                if allOrbsConverged then
                    local sin = REVEL.ENT.PENANCE_SIN:spawn(data.PenanceConvergePoint, Vector.Zero, nil)
                    sin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    sin.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    sin:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    REVEL.GetData(sin).PenancePlayer = data.PenancePlayer
                    REVEL.GetData(sin).Strength = #data.OtherOrbs * 2
                    for _, orb in ipairs(data.OtherOrbs) do -- this includes itself
                        orb:Remove()
                    end
                end
            else
                local convergingPercent = math.min(25, npc.FrameCount) / 25
                npc.Velocity = npc.Velocity * REVEL.Lerp(0.975, 0.9, convergingPercent) + (data.PenanceConvergePoint - npc.Position):Resized(REVEL.Lerp(0.5, 1.5, convergingPercent))
            end
        elseif data.ReturnToPlayer then
            if not sprite:IsPlaying("idle") then
                sprite:Play("idle", true)
            end

            npc.Velocity = npc.Velocity * 0.925 + (data.ReturnToPlayer.Position - npc.Position):Resized(1)
            if data.ReturnToPlayer.Position:DistanceSquared(npc.Position) < (npc.Size + data.ReturnToPlayer.Size) ^ 2 then
                data.ReturnToPlayer:AddBlackHearts(2)
                REVEL.PlaySound(Sounds.SIN_COLLECT)
                revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(data.ReturnToPlayer)] = revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(data.ReturnToPlayer)] - 2
                npc:Remove()
            end
        elseif data.MergeWithSin then
            if not sprite:IsPlaying("idle") then
                sprite:Play("idle", true)
            end

            npc.Velocity = npc.Velocity * 0.925 + (data.MergeWithSin.Position - npc.Position):Resized(1)
            if data.MergeWithSin.Position:DistanceSquared(npc.Position) < (npc.Size + data.MergeWithSin.Size) ^ 2 then
                REVEL.GetData(data.MergeWithSin).Strength = REVEL.GetData(data.MergeWithSin).Strength + 2
                REVEL.GetData(data.MergeWithSin).Health = REVEL.GetData(data.MergeWithSin).Health + 2
                npc:Remove()
            end
        else
            if not data.Converted then
                if not sprite:IsPlaying("idle") then
                    sprite:Play("idle", true)
                end
            else
                if sprite:IsFinished("pop") then
                    npc:Remove()
                end

                if not sprite:IsPlaying("idleblue") and not sprite:IsPlaying("convert") and not sprite:IsPlaying("pop") then
                    sprite:Play("idleblue", true)
                end
            end
        end
    end, REVEL.ENT.PENANCE_ORB.id)

    local ForceTriggerDeath = false

	revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
		if not REVEL.ENT.PENANCE_SIN:isEnt(npc, true) then return end

		local data, sprite = REVEL.GetData(npc), npc:GetSprite()

        if not data.Init then
            data.Init = true
            npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        end

        if not data.State then
            data.State = "Idle"
        end

        if not data.Health then
            data.Health = data.Strength
        end

        local strength = GetPenanceSinStrengthMultiplier(npc)

        if data.State == "Idle" then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            if data.DashFade then
                data.DashFade = data.DashFade - 1
                npc.Color = Color.Lerp(Color.Default, REVEL.DEF_INVISIBLE, data.DashFade / fadeLength)
                if data.DashFade <= 0 then
                    data.DashFade = nil
                    npc.Color = Color.Default
                end
            end

            if REVEL.room:IsClear() or ForceTriggerDeath then
                for i = 1, math.ceil(data.Strength / 2) do
                    local orb = REVEL.ENT.PENANCE_ORB:spawn(npc.Position, npc.Velocity + RandomVector() * math.random(6, 9), nil)
                    orb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    orb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    orb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                    REVEL.GetData(orb).ReturnToPlayer = data.PenancePlayer
                end

                data.State = "Death"
                sprite:Play("pop", true)
            else
                local cardinalTargets = {
                    Vector(0, 1),
                    Vector(0, -1),
                    Vector(1, 0),
                    Vector(-1, 0)
                }

                local closestCardinal, minDist
                for _, dir in ipairs(cardinalTargets) do
                    local dist = (data.PenancePlayer.Position + dir):DistanceSquared(npc.Position)
                    if not minDist or dist < minDist then
                        closestCardinal = dir
                        minDist = dist
                    end
                end

                local targetPos = data.PenancePlayer.Position + closestCardinal * (data.PenancePlayer.Position:Distance(npc.Position) * sinCardinalFactor)

                npc.Velocity = npc.Velocity * 0.9 + (targetPos - npc.Position):Resized(penanceSin.FollowSpeed[strength])
                if REVEL.room:IsPositionInRoom(npc.Position, -16) and (math.abs(npc.Position.X - data.PenancePlayer.Position.X) < 360 and
                math.abs(npc.Position.Y - data.PenancePlayer.Position.Y) < 240) then
                    local facing, alignment = REVEL.GetAlignment(npc.Position, data.PenancePlayer.Position)
                    if alignment < 16 then
                        npc.Velocity = Vector.Zero
                        data.DashDirectionName = facing
                        data.DashDirection = (data.PenancePlayer.Position - npc.Position)
                        data.DashInitialPosition = npc.Position
                        data.DashInitialDistance = data.DashDirection:LengthSquared()
                        if math.abs(data.DashDirection.X) > math.abs(data.DashDirection.Y) then
                            data.DashDirection = Vector(data.DashDirection.X, 0):Resized(penanceSin.DashSpeed[strength])
                        else
                            data.DashDirection = Vector(0, data.DashDirection.Y):Resized(penanceSin.DashSpeed[strength])
                        end

                        data.State = "Dash"
                        sprite:Play("charge", true)
                        sprite.PlaybackSpeed = penanceSin.ChargeSpeed[strength]
                        -- REVEL.PlaySound(npc, SIN_CHARGE_START_SOUND)
                    end
                end
            end
        elseif data.State == "Dash" then
            --if REVEL.room:IsPositionInRoom(npc.Position, -64) then
            --	data.WasInRoom = true
            --end


            if sprite:IsFinished("charge") then
                sprite:Play("Dash" .. data.DashDirectionName, true)
                sprite.PlaybackSpeed = 1
                REVEL.PlaySound(npc, Sounds.SIN_CHARGE)
            end

            if not sprite:IsPlaying("charge") then
                sinEmitter:EmitParticlesPerSec(sinParticle, sinSystem, Vec3(npc.Position, -22), Vec3(-npc.Velocity * 0.15, 0), 70, 0.4, 30)
                REVEL.DashTrailEffect(npc, 2, 8, "Dash" .. data.DashDirectionName)

                if data.PenancePlayer:GetDamageCooldown() <= 0 and npc.Position:DistanceSquared(data.PenancePlayer.Position) < (npc.Size + data.PenancePlayer.Size) ^ 2 then
                    data.PenancePlayer:TakeDamage(1, 0, EntityRef(data.PenancePlayer), 0)
                    data.Health = data.Health - 1
                    data.Strength = data.Strength - 1
                    if data.Strength % 2 == 0 then
                        revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(data.PenancePlayer)] = revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(data.PenancePlayer)] - 2
                    end

                    if data.Health <= 0 then
                        data.State = "Death"
                        sprite:Play("pop", true)
                    end

                end

                local damage = REVEL.level:GetStage() * 1.75
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy:IsVulnerableEnemy() and enemy:IsActiveEnemy(false) and (enemy.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL or enemy.EntityCollisionClass == EntityCollisionClass.ENTCOLL_PLAYEROBJECTS) and npc.Position:DistanceSquared(enemy.Position) < (npc.Size + enemy.Size) ^ 2 then
                        enemy:TakeDamage(damage, 0, EntityRef(npc), 0)
                    end
                end

                npc.Velocity = data.DashDirection
            end

            --if data.WasInRoom and not REVEL.room:IsPositionInRoom(npc.Position, -64) then
            if data.DashInitialPosition:DistanceSquared(npc.Position) > data.DashInitialDistance and not (math.abs(npc.Position.X - data.PenancePlayer.Position.X) < 360 and
            math.abs(npc.Position.Y - data.PenancePlayer.Position.Y) < 240) then
                data.State = "DashFade"
                data.DashFade = 0
                data.DashDirectionName = nil
                data.DashInitialPosition = nil
                data.DashInitialDistance = nil
            end
        elseif data.State == "DashFade" then
            data.DashFade = data.DashFade + 1

            npc.Color = Color.Lerp(Color.Default, REVEL.DEF_INVISIBLE, data.DashFade / fadeLength)
            if data.DashFade >= fadeLength then
                data.State = "Idle"
                data.DashDirection = nil
                npc.Position = data.PenancePlayer.Position + RandomVector() * 520
                npc.Velocity = Vector.Zero
            else
                npc.Velocity = data.DashDirection
            end
        elseif data.State == "Death" then
            if sprite:IsFinished("pop") then
                npc:Remove()
            end
            npc.Velocity = Vector.Zero
        elseif data.State == "FleeingBlackHeart" then
            if not sprite:IsPlaying("transform") and not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            if sprite:IsPlaying("Idle") then
                npc.Velocity = npc.Velocity * 0.95 + (npc.Position - REVEL.player.Position):Resized(0.75)
                if not REVEL.room:IsPositionInRoom(npc.Position, -256) then
                    data.State = "Death"
                    sprite:Play("pop", true)
                end
            end
        end
	end, REVEL.ENT.PENANCE_SIN.id)

    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        ForceTriggerDeath = false

        local sins = Isaac.FindByType(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 1, false, false)
        for _, sin in ipairs(sins) do
            local strength = GetPenanceSinStrengthMultiplier(sin)
            sin.SpriteScale = Vector.One * penanceSin.SizeScale[strength]
            if not REVEL.GetData(sin).OriginalSize then
                REVEL.GetData(sin).OriginalSize = sin.Size
            end
            sin.Size = REVEL.GetData(sin).OriginalSize * penanceSin.SizeScale[strength]
        end
    end)

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
        if not REVEL.IsSaveDataLoaded() then
            return
        end

        if e:ToNPC() and REVEL.room:GetType() == RoomType.ROOM_BOSS and not REVEL.room:IsClear() and REVEL.room:GetAliveEnemiesCount() == 1 and e:CanShutDoors() then
            local hasGoatHeadOrEucharist
            for _, player in ipairs(REVEL.players) do
                if REVEL.HasPenanceEffect(player) and REVEL.GetData(player).ShouldGetDevilDeal == nil then
                    local shouldRemoveCostume = not player:HasCollectible(CollectibleType.COLLECTIBLE_DUALITY)
                    player:AddCollectible(CollectibleType.COLLECTIBLE_DUALITY, 0, false)

                    if shouldRemoveCostume then
                        player:RemoveCostume(REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_DUALITY))
                    end

                    if REVEL.IsSarah(player) then
                        hasGoatHeadOrEucharist = hasGoatHeadOrEucharist or (player:HasCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD) or player:HasCollectible(CollectibleType.COLLECTIBLE_EUCHARIST))
                    end

                    REVEL.GetData(player).FramesSinceDuality = 10
                    local devilRNG = REVEL.level:GetDevilAngelRoomRNG()
                    local devilChance = REVEL.room:GetDevilRoomChance() * 100
                    REVEL.GetData(player).ShouldGetDevilDeal = devilChance > StageAPI.Random(0, 99, devilRNG)
                    local blackHearts = REVEL.GetBlackHearts(player) + revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)]
                    if blackHearts > 0 and not player:HasCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD) then
                        REVEL.AddCollectibleEffect(CollectibleType.COLLECTIBLE_GOAT_HEAD, player)
                        player:RemoveCostume(REVEL.config:GetCollectible(CollectibleType.COLLECTIBLE_GOAT_HEAD))
                    end
                end
            end

            if hasGoatHeadOrEucharist then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, e.Position, RandomVector() * 2, nil)
            end
        end
    end)

    function REVEL.RemoveDevilAngelDoor(slot, isDevil)
        REVEL.room:RemoveDoor(slot)

        if not isDevil then
            REVEL.sfx:Stop(SoundEffect.SOUND_CHOIR_UNLOCK)
        else
            REVEL.sfx:Stop(SoundEffect.SOUND_DEVILROOM_DEAL)
        end

        local clouds = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.DUST_CLOUD, -1, false, false)
        for _, cloud in ipairs(clouds) do
            if cloud.Position:DistanceSquared(REVEL.room:GetDoorSlotPosition(slot)) < 40 ^ 2 then
                cloud:Remove()
            end
        end
    end

	revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
		if REVEL.HasPenanceEffect(player) then
			local data = REVEL.GetData(player)
            if REVEL.room:IsCurrentRoomLastBoss() and REVEL.room:IsClear() and revel.data.run.level.penanceHealState == 0 then
                revel.data.run.level.penanceHealState = 1
            end

            if REVEL.IsSarah(player) then
                local blackHearts = REVEL.GetBlackHearts(player)
                local soulHearts = player:GetSoulHearts()
                local diff = blackHearts - soulHearts
                if diff ~= 0 then
                    player:AddSoulHearts(diff)
                    player:AddBlackHearts(-diff)
                end
            end

			REVEL.BringBlackHeartsToFront(player)
			if data.PenanceTriggered then
                --[[
                local sins = Isaac.FindByType(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 1, false, false)
                local hasSin
                for _, sin in ipairs(sins) do
                    if REVEL.GetData(sin)REVEL.GetPlayerID(.PenancePlayer) == REVEL.GetPlayerID(player) then
                        hasSin = sin
                        break
                    end
                end

                if not hasSin then
    				local convergePoint = REVEL.GetSinConvergePoint()
    				local orbs = {}
    				for i = 1, data.PenanceTriggered do
    					local orb = Isaac.Spawn(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 0, player.Position, RandomVector() * math.random(6, 9), nil)
                        REVEL.MakeOrbSinOrb(orb, player, convergePoint)
    					orbs[#orbs + 1] = orb
    				end

    				for _, orb in ipairs(orbs) do
    					REVEL.GetData(orb).OtherOrbs = orbs
    				end
                else
                    for i = 1, data.PenanceTriggered do
                        local orb = Isaac.Spawn(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 0, player.Position, RandomVector() * math.random(6, 9), nil)
                        orb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                        orb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                        orb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                        REVEL.GetData(orb).MergeWithSin = hasSin
                    end
                end]]

                for i = 1, data.PenanceTriggered do
                    local convergePoint = REVEL.GetSinConvergePoint()
                    local orb = REVEL.ENT.PENANCE_ORB:spawn(player.Position, RandomVector() * math.random(6, 9), nil)
                    REVEL.MakeOrbSinOrb(orb, player, convergePoint)
                    REVEL.GetData(orb).OtherOrbs = {orb}
                end

                REVEL.PlaySound(Sounds.SIN_SPAWN)

                local playerID = REVEL.GetPlayerID(player)
                revel.data.run.penanceBlackHeartsOut[playerID] = revel.data.run.penanceBlackHeartsOut[playerID] + data.PenanceTriggered * 2
				data.PenanceTriggered = nil
			end

            if data.FramesSinceDuality then
                data.FramesSinceDuality = data.FramesSinceDuality - 1
                if player:HasCollectible(CollectibleType.COLLECTIBLE_DUALITY) and data.FramesSinceDuality >= 0 then
                    if REVEL.room:IsClear() then
                        local doorsFound
                        for i = 0, 7 do
                            local door = REVEL.room:GetDoor(i)
                            if door and (door.TargetRoomType == RoomType.ROOM_ANGEL or door.TargetRoomType == RoomType.ROOM_DEVIL) then
                                doorsFound = true
                                local blackHearts = REVEL.GetBlackHearts(player) + revel.data.run.penanceBlackHeartsOut[REVEL.GetPlayerID(player)]
                                if door.TargetRoomType == RoomType.ROOM_ANGEL and blackHearts == 0 then
                                    REVEL.RemoveDevilAngelDoor(i, false)
                                end

                                if door.TargetRoomType == RoomType.ROOM_DEVIL and not data.ShouldGetDevilDeal then
                                    REVEL.RemoveDevilAngelDoor(i, true)
                                end
                            end
                        end

                        if doorsFound then
                            player:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY)
                            -- player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_GOAT_HEAD)
                            data.ShouldGetDevilDeal = nil
                            data.FramesSinceDuality = nil
                        end
                    end
                else
                    player:RemoveCollectible(CollectibleType.COLLECTIBLE_DUALITY)
                    -- player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_GOAT_HEAD) --currently crashes
                    data.ShouldGetDevilDeal = nil
                    data.FramesSinceDuality = nil
                end
            elseif data.ShouldGetDevilDeal ~= nil then
                data.ShouldGetDevilDeal = nil
            end
		end
	end)

	local movedToRedHealth
    StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 0, function(player, amount, flags, source, iframes)
		player = player:ToPlayer()
		if REVEL.HasPenanceEffect(player) then
			if not HasBit(flags, DamageFlag.DAMAGE_FAKE) and not movedToRedHealth and not REVEL.room:IsClear() 
            and not REVEL.PlayerIsLost(player) then
				local removedBlackHearts = REVEL.RemoveAllBlackHearts(player)
				if removedBlackHearts > 0 then
					movedToRedHealth = true
					player:TakeDamage(amount, flags | DamageFlag.DAMAGE_FAKE, source, iframes)
					REVEL.GetData(player).PenanceTriggered = math.ceil(removedBlackHearts / 2)
					movedToRedHealth = nil
					return false
				end
			end
		end
    end, EntityType.ENTITY_PLAYER)

    -- Dogma boss handling

    local DogmaAngelVariant = 2

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if entity.Variant == DogmaAngelVariant then
            ForceTriggerDeath = true
        end
    end, EntityType.ENTITY_DOGMA)

    revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, function(_, npc)
        for _, player in ipairs(REVEL.players) do
            if player:GetPlayerType() == REVEL.CHAR.SARAH.Type then
                ReaddOutBlackHearts(player)
            end
        end

        local sins = Isaac.FindByType(REVEL.ENT.PENANCE_ORB.id, REVEL.ENT.PENANCE_ORB.variant, 1, false, false)
        for _, sin in ipairs(sins) do
            sin:Remove()
        end
    end, EntityType.ENTITY_BEAST)
end

end

Isaac.DebugString("Revelations: Loaded Sarah!")
end