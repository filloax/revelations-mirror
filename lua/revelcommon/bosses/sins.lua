local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RandomPickupSubtype = require("lua.revelcommon.enums.RandomPickupSubtype")
local RevRoomType         = require("lua.revelcommon.enums.RevRoomType")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Snooping in the files, eh?
-- Well then, have a suprise. Try a certain code you can see down below...

local InputSequence = {
    {Action = ButtonAction.ACTION_UP},
    {Action = ButtonAction.ACTION_UP},
    {Action = ButtonAction.ACTION_DOWN},
    {Action = ButtonAction.ACTION_DOWN},
    {Action = ButtonAction.ACTION_LEFT},
    {Action = ButtonAction.ACTION_RIGHT},
    {Action = ButtonAction.ACTION_LEFT},
    {Action = ButtonAction.ACTION_RIGHT},
    {Action = ButtonAction.ACTION_SHOOTRIGHT, Key = Keyboard.KEY_B},
    {Action = ButtonAction.ACTION_SHOOTDOWN, Key = Keyboard.KEY_A},
    {Action = ButtonAction.ACTION_MENUCONFIRM}
}

-- Actual sin code

REVEL.FORCE_SIN_DROP = false

function REVEL.IsSin(e)
	return e.Type >= EntityType.ENTITY_SLOTH and e.Type <= EntityType.ENTITY_PRIDE
end

REVEL.SinMusic = {
    [EntityType.ENTITY_ENVY] = REVEL.SFX.SIN.ENVY,
    [EntityType.ENTITY_GREED] = REVEL.SFX.SIN.GREED,
    [EntityType.ENTITY_GLUTTONY] = REVEL.SFX.SIN.GLUTTONY,
    [EntityType.ENTITY_LUST] = REVEL.SFX.SIN.LUST,
    [EntityType.ENTITY_PRIDE] = REVEL.SFX.SIN.PRIDE,
    [EntityType.ENTITY_SLOTH] = REVEL.SFX.SIN.SLOTH,
    [EntityType.ENTITY_WRATH] = REVEL.SFX.SIN.WRATH
}

REVEL.SinDrops = {
    [EntityType.ENTITY_ENVY] = REVEL.ITEM.ENVYS_ENMITY.id,
    [EntityType.ENTITY_GREED] = REVEL.ITEM.BARG_BURD.id,
    [EntityType.ENTITY_GLUTTONY] = REVEL.ITEM.GUT.id,
    [EntityType.ENTITY_LUST] = REVEL.ITEM.LOVERS_LIB.id,
    [EntityType.ENTITY_PRIDE] = REVEL.ITEM.PRIDES_POSTURING.id,
    [EntityType.ENTITY_SLOTH] = REVEL.ITEM.SLOTHS_SADDLE.id,
    [EntityType.ENTITY_WRATH] = REVEL.ITEM.WRATHS_RAGE.id
}

local function isNotUltraPride(e)
    return not (e.Type == EntityType.ENTITY_SLOTH and e.Variant == 2)
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_MINIBOSS_MUSIC, 1, function()
    if not REVEL.room:IsClear() and (REVEL.STAGE.Glacier:IsStage() or REVEL.STAGE.Tomb:IsStage()) then
        for entid, musicid in pairs(REVEL.SinMusic) do
            local minibosses = Isaac.FindByType(entid, -1, -1, false, false)
            if REVEL.some(minibosses, isNotUltraPride) then
                return musicid
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, t, v, s, pos, vel, spawner, seed)
    if spawner and isNotUltraPride(spawner) and REVEL.SinDrops[spawner.Type] 
    and (REVEL.STAGE.Glacier:IsStage() or REVEL.STAGE.Tomb:IsStage()) and t == EntityType.ENTITY_PICKUP then
        if v ~= PickupVariant.PICKUP_COLLECTIBLE or s ~= REVEL.SinDrops[spawner.Type] then
            return {
                StageAPI.E.DeleteMePickup.T,
                StageAPI.E.DeleteMePickup.V,
                0,
                seed
            }
        end
    end
end)

local sinDropRNG = REVEL.RNG()
for entid,itemid in pairs(REVEL.SinDrops) do
    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
        if isNotUltraPride(npc) 
        and (REVEL.room:GetType() == RoomType.ROOM_MINIBOSS or REVEL.room:GetType() == RoomType.ROOM_SHOP) 
        and (REVEL.STAGE.Glacier:IsStage() or REVEL.STAGE.Tomb:IsStage()) and REVEL.room:GetFrameCount() > 10 then
            local isLastSinDeath = true
            for sinid, _ in pairs(REVEL.SinDrops) do
                local ents = Isaac.FindByType(sinid, -1, -1, false, true)
                ents = REVEL.filter(ents, isNotUltraPride)
                if (sinid == entid and #ents > 1) or (sinid ~= entid and #ents > 0) then
                    isLastSinDeath = false
                    break
                end
            end

            if isLastSinDeath then
                sinDropRNG:SetSeed(REVEL.room:GetSpawnSeed(), 0)
                if not REVEL.AllPlayersHaveCollectible(itemid) 
                and (StageAPI.Random(1, 3, sinDropRNG) == 1 or REVEL.FORCE_SIN_DROP) then
                    local pos = REVEL.room:FindFreePickupSpawnPosition(npc.Position, 20, false)
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemid, pos, Vector.Zero, nil)
                end
            end
        end
    end, entid)
end


--Sinami

StageAPI.RegisterLayout("GlacierSinami", REVEL.RoomLists.Sinami.All[1])
StageAPI.RegisterLayout("TombSinami", REVEL.RoomLists.Sinami.All[2])

local function trySinami()
    local glacier, tomb = REVEL.STAGE.Glacier:IsStage(), REVEL.STAGE.Tomb:IsStage()
    if tomb or glacier then
        local room
        if glacier then
            room = StageAPI.LevelRoom("GlacierSinami", nil, nil, RoomShape.ROOMSHAPE_2x2, RoomType.ROOM_MINIBOSS, true)
            room:SetTypeOverride(RevRoomType.CHILL)
        elseif tomb then
            room = StageAPI.LevelRoom("TombSinami", nil, nil, RoomShape.ROOMSHAPE_2x2, RoomType.ROOM_MINIBOSS, true)
            room:SetTypeOverride(RevRoomType.TRAP)
        end
        room.PersistentData.IsSinami = true
        room.PersistentData.MusicStatus = 0
		local roomData = StageAPI.GetDefaultLevelMap():AddRoom(room, {RoomID = "Sinami"}, false)
		StageAPI.ExtraRoomTransition(roomData.MapID, nil, nil, StageAPI.DefaultLevelMapID)
		REVEL.GoingToSinami = true
    else
		StageAPI.GetDefaultLevelMap():RemoveRoom({RoomID = "Sinami"})
    end
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	local goodForStage = (REVEL.STAGE.Tomb:IsStage() and (REVEL.DEBUG or not revel.data.run.sinamiBeat.tomb)) 
        or (REVEL.STAGE.Glacier:IsStage() and (REVEL.DEBUG or not revel.data.run.sinamiBeat.glacier))

    if goodForStage and revel.IsAchievementUnlocked("TOMB_CHAMPIONS") and revel.IsAchievementUnlocked("GLACIER_CHAMPIONS") 
    and REVEL.level:GetCurrentRoomIndex() == REVEL.level:GetStartingRoomIndex() and not REVEL.game:IsPaused() then
        for i, player in ipairs(REVEL.players) do
            local data = player:GetData()
            data.seqProg = data.seqProg or 1

			if Input.IsActionTriggered(InputSequence[data.seqProg].Action, player.ControllerIndex) 
            or (InputSequence[data.seqProg].Key and Input.IsButtonTriggered(InputSequence[data.seqProg].Key, 0)) then
				data.seqProg = data.seqProg + 1
                local soundStart = 5

                if data.seqProg >= soundStart then
                    REVEL.sfx:Play(
                        SoundEffect.SOUND_THUMBSUP, 
                        0.5, 0, false, 
                        REVEL.Lerp2Clamp(0.75, 1.25, data.seqProg, soundStart, #InputSequence)
                    )
                    local eff = REVEL.SpawnCustomGlow(
                        player, 
                        "Wave",
                        "gfx/itemeffects/revelcommon/haphephobia_wave.anm2"
                    )
                    eff.Color = Color(1, 1, 1, 1, 0.5, 0.5, 0.5)
                end

				if data.seqProg > #InputSequence then
					trySinami()
					data.seqProg = nil
					if REVEL.STAGE.Glacier:IsStage() then
						revel.data.run.sinamiBeat.glacier = true
					elseif REVEL.STAGE.Tomb:IsStage() then
						revel.data.run.sinamiBeat.tomb = true
					end
				end
			elseif data.seqProg > 1 then
				for action = ButtonAction.ACTION_LEFT, ButtonAction.ACTION_MENUBACK do
					if Input.IsActionTriggered(action, player.ControllerIndex) then
                        if data.seqProg > 4 then
                            REVEL.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 0.5)
                        end
						data.seqProg = 1
                        break
                    end
				end
            end
        end
    end
end)

local Sinamis = {}

local function GetSinBeatNum()
    local sinBeatNum = REVEL.reduce(revel.data.run.sinamiBeat, function(total, val) return total + (val and 1 or 0) end, 0)
    if REVEL.STAGE.Glacier:IsStage() and revel.data.run.sinamiBeat.glacier
    or REVEL.STAGE.Tomb:IsStage() and revel.data.run.sinamiBeat.tomb
    then
        sinBeatNum = sinBeatNum - 1
    end
    return sinBeatNum
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(room, revisited, isExtraRoom)
    Sinamis = {}
    if isExtraRoom and room.PersistentData.IsSinami and (REVEL.DEBUG or not revisited) then
        local sinBeatNum = GetSinBeatNum()

        local offset = math.random(0, 6)
        --first sin type is sloth
        for i=0, 6 do
            local isSuper = sinBeatNum >= 1
            local type = EntityType.ENTITY_SLOTH + (offset + i) % 7
            local pos = REVEL.room:GetCenterPos() + Vector.FromAngle(i*360/7) * 200
            local sin = Isaac.Spawn(type, isSuper and 1 or 0, 0, pos, Vector.Zero, nil)
            sin:GetSprite():Play(sin:GetSprite():GetDefaultAnimation(), 0)
            sin:AddEntityFlags(EntityFlag.FLAG_FREEZE)
            sin:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            sin.Color = Color(0.5,0.5,0.5,1,conv255ToFloat(20,20,20))
            table.insert(Sinamis, sin)
        end

        REVEL.music:Pause()

        local num = #REVEL.players
        for i, player in ipairs(REVEL.players) do
            player.Position = REVEL.room:GetCenterPos() + Vector.FromAngle(i*360/num) * (num > 1 and 40 or 0)
		end
		REVEL.GoingToSinami = false
    -- elseif not isExtraRoom then
    --     StageAPI.GetDefaultLevelMap():RemoveRoom({RoomID = "Sinami"})
    end
end)

local TimerToTransitionOut
local SpawnedReward = false
local StoppedMus = false

local showing

local function rewardUpdate(e, data, spr)
	if not data.collected then
		for i,p in ipairs(REVEL.players) do
			if p.Position:Distance(e.Position) < p.Size + 20 then
				spr:Play("Collect", true)
				data.collected = true
                REVEL.AnimateAchievement("gfx/truecoop/versusscreen/playernames_ghost/soul.png")
                showing = true
            end
		end
	end
	if spr:IsFinished("Collect") then
		e:Remove()
	end
end

local doneShowingReward
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local rendering = REVEL.GetShowingAchievement()
    if showing and not rendering then
        showing = false
        doneShowingReward = true
    end
end)

local noEnmLeftFrame = nil --for lust and envy, leave some time in case they didn't all die

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local room = StageAPI.GetCurrentRoom()
    if room and room.PersistentData.IsSinami then
        if REVEL.room:GetFrameCount() == 60 then
            for _, sin in ipairs(Sinamis) do
                sin.Color = Color.Default
                sin:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
                sin:AddEntityFlags(EntityFlag.FLAG_APPEAR)
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, sin.Position, Vector.Zero, nil)
            end
            REVEL.music:Resume()
            room.PersistentData.MusicStatus = 1
            REVEL.sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.6, 0, false, 1)
        end

        local sinLeft = false
        local enmLeft = false
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if REVEL.IsSin(enemy) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                sinLeft = true
            end
            enmLeft = enmLeft or (not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY))
		end

		local rags = REVEL.ENT.REVIVAL_RAG:getInRoom(false, false, false)
		for _, rag in ipairs(rags) do
			if rag:GetData().SpawnID == EntityType.ENTITY_LUST then
				sinLeft = true
				break
			end
		end

        if not sinLeft then
			if not enmLeft then
				if not noEnmLeftFrame then
					noEnmLeftFrame = REVEL.game:GetFrameCount()
				elseif not SpawnedReward and REVEL.game:GetFrameCount() - noEnmLeftFrame > 5 then
					local reward = REVEL.SpawnDecoration(
						REVEL.room:GetCenterPos(),
						Vector.Zero,
						"Appear",
						"gfx/effects/revel2/message.anm2",
						nil, nil, nil, nil,
						rewardUpdate,
						nil,
						false)

					SpawnedReward = true
				end
			else
				noEnmLeftFrame = nil
            end

			if not StoppedMus then
				room.PersistentData.MusicStatus = 2
				REVEL.music:Play(Music.MUSIC_JINGLE_BOSS_OVER, 0.1)
				REVEL.music:Queue(REVEL.SFX.WIND)
				REVEL.music:UpdateVolume()
				StoppedMus = true
			end
		else
			noEnmLeftFrame = nil
		end

		if doneShowingReward then
			TimerToTransitionOut = TimerToTransitionOut or 3
			doneShowingReward = nil
		end

        if TimerToTransitionOut then
            TimerToTransitionOut = TimerToTransitionOut - 1
            if TimerToTransitionOut < 0 then
                TimerToTransitionOut = nil
                StageAPI.ExtraRoomTransition(StageAPI.LastNonExtraRoom)
                for i, player in ipairs(REVEL.players) do
                    player:AddHearts(24)
                end

                REVEL.DelayFunction(5, function()
                    for i = 1, math.floor(3.5 * math.min(GetSinBeatNum() + 1, 3)) do
                        local subtype = RandomPickupSubtype.NO_ITEM
                        if i == 1 then
                            subtype = RandomPickupSubtype.ANY_PICKUP
                        end
                        local pos = REVEL.room:FindFreePickupSpawnPosition(REVEL.room:GetCenterPos(), 20, true)
                        Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, subtype, pos, Vector.Zero, nil)
                    end
                end)
            end
        end
    else
        TimerToTransitionOut = nil
        SpawnedReward = false
        StoppedMus = false
    end
end)

end
REVEL.PcallWorkaroundBreakFunction()