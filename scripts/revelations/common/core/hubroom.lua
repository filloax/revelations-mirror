local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local HubDoorLock       = require("scripts.revelations.common.enums.HubDoorLock")
local TrapdoorState     = require("scripts.revelations.common.enums.TrapdoorState")
local RoomTypeExtra     = require("scripts.revelations.common.enums.RoomTypeExtra")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

-- TODO: fix repentance stage

return function()

local crateItemOffset = 10

REVEL.Commands.togglehubdoor = {
    Execute = function (params)
        revel.data.enableStartHub = not revel.data.enableStartHub
        if not revel.data.enableStartHub then
            Isaac.ConsoleOutput("Hub trapdoor disabled.\n")
        else
            Isaac.ConsoleOutput("Hub trapdoor enabled.\n")
        end
    end,
    Desc = "Toggle Legacy Hub trapdoor",
    Help = "Toggles Legacy Hub trapdoor in starting room if legacy hub is enabled in settings",
    File = "hubroom.lua",
    Aliases = {"thub"},
}

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, function(customGrid)
	local index = customGrid.GridIndex
	local persistData = customGrid.PersistentData
	
    local trapdoor = StageAPI.SpawnFloorEffect(REVEL.room:GetGridPosition(index), Vector.Zero, nil, "gfx/backdrop/revelcommon/hubroom/hub_trapdoor.anm2", true, REVEL.ENT.HUB_DECORATION.variant)
    REVEL.GetData(trapdoor).HubTrapdoor = true
    REVEL.GetData(trapdoor).StartingRoomHub = persistData.StartingRoomHub

    if REVEL.room:GetGridEntity(index) then
        REVEL.room:RemoveGridEntity(index, 0, false)
        -- REVEL.room:Update()
    end

    if persistData.StartingRoomHub then
        trapdoor.Position = trapdoor.Position - Vector(20, 20)
        if REVEL.room:IsFirstVisit() then
            trapdoor:GetSprite():Play("Open Animation", true)
        else
            trapdoor:GetSprite():Play("Lock", true)
        end
    else
        trapdoor:GetSprite():Play("Closed", true)
    end
end, REVEL.GRIDENT.HUB_TRAPDOOR.Name)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if not REVEL.game:IsGreedMode() 
    and revel.data.enableStartHub
    and REVEL.level:GetStage() == LevelStage.STAGE1_1 
    and not REVEL.game:GetSeeds():HasSeedEffect(SeedEffect.SEED_INFINITE_BASEMENT) 
    and Isaac.GetChallenge() ~= Challenge.CHALLENGE_BACKASSWARDS 
    and REVEL.level:GetStageType() < StageType.STAGETYPE_REPENTANCE
    and not StageAPI.InNewStage() 
    and not REVEL.Dante.IsOtherRoomCleared()
    and not REVEL.level:IsAscent()
    and REVEL.level:GetCurrentRoomIndex() == REVEL.level:GetStartingRoomIndex() then
        revel.data.run.possiblySkippingFloor = REVEL.room:IsFirstVisit()

        if REVEL.room:IsFirstVisit() then
            REVEL.GRIDENT.HUB_TRAPDOOR:Spawn(
                REVEL.room:GetGridIndex(REVEL.room:GetTopLeftPos() + Vector(40, 40)), 
                nil, 
                false, 
                {StartingRoomHub = true}
            )
        end
    elseif not StageAPI.InExtraRoom() then
        if StageAPI.InNewStage() then
            if revel.data.run.possiblySkippingFloor then
                revel.data.run.skippedFloor = true
            end
        end

        revel.data.run.possiblySkippingFloor = false
    end

    if REVEL.room:GetType() == RoomType.ROOM_TREASURE and revel.data.run.skippedFloor then
        local pos = REVEL.GetExtraItemSpawnPos(true)
        if pos then
            local crate = Isaac.Spawn(REVEL.ENT.HUB_DECORATION.id, REVEL.ENT.HUB_DECORATION.variant, 0, pos + Vector(0, crateItemOffset), Vector.Zero, nil)
            crate:GetSprite():Load("gfx/backdrop/revelcommon/hubroom/lootbox.anm2", true)
            crate:GetSprite():Play("Appear", true)
            REVEL.GetData(crate).HubItemCrate = true
        end

        revel.data.run.skippedFloor = false
    end
end)

local PreventAltDoorSpawns = false

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    -- The Hub does not appear in greed mode, the BASEMENT seed and the Backasswards challenge
    if HasBit(REVEL.game.Difficulty, Difficulty.DIFFICULTY_GREED) 
    or REVEL.game:GetSeeds():HasSeedEffect(SeedEffect.SEED_INFINITE_BASEMENT) 
    or Isaac.GetChallenge() == Challenge.CHALLENGE_BACKASSWARDS 
    or revel.data.oldHubActive == 2 then
        if PreventAltDoorSpawns then
            PreventAltDoorSpawns = false
        end
        return
    end

    local hubVersion = REVEL.GetHubVersionForStage()
    if hubVersion then
		-- Rooms of RoomType 27 are alt-path transition rooms (not present in RoomType enum)
		if REVEL.room:GetType() ~= RoomTypeExtra.ALT_TRANSITION 
        and (not StageAPI.InExtraRoom() or StageAPI.GetCurrentRoomType() ~= RevRoomType.HUB2D) then
			for i = 0, REVEL.room:GetGridSize() do
				local grid = REVEL.room:GetGridEntity(i)
				if grid and grid.Desc.Type == GridEntityType.GRID_TRAPDOOR and grid:GetSprite():GetFilename() ~= "gfx/grid/voidtrapdoor.anm2" then
					REVEL.room:RemoveGridEntity(i, 0, false)
                    REVEL.room:Update()
					REVEL.GRIDENT.HUB_TRAPDOOR:Spawn(i)
				end
			end
		end

        PreventAltDoorSpawns = REVEL.room:GetType() == RoomType.ROOM_BOSS
        if PreventAltDoorSpawns then
            for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
                local door = REVEL.room:GetDoor(i)
                if door and door.TargetRoomType == RoomTypeExtra.ALT_TRANSITION then
                    -- if barred, remove bars or they'd render
                    if door:CanBlowOpen() and door:IsLocked() then
                        REVEL.DebugStringMinor("Hub room | Removing alt path door bars before hiding it")

                        -- blow open two times, remove wood particles, remove sound
                        door:TryBlowOpen(true, REVEL.player)
                        door:TryBlowOpen(true, REVEL.player)
                        REVEL.sfx:Stop(SoundEffect.SOUND_WOOD_PLANK_BREAK)
                    end

                    door.ExtraVisible = false
                    door:GetSprite().Scale = Vector.Zero
                    door.ExtraVisible = false
                    door:Close(true)
                end
            end
        end
    else
        PreventAltDoorSpawns = false
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, pos, vel, spawner, seed)
    if PreventAltDoorSpawns and type == 1000
    and (variant == EffectVariant.WOOD_PARTICLE or variant == EffectVariant.DUST_CLOUD)
    then
        for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            local door = REVEL.room:GetDoor(i)
            if door and door.TargetRoomType == RoomTypeExtra.ALT_TRANSITION then
                local doorpos = REVEL.room:GetGridPosition(door:GetGridIndex())
                if doorpos:DistanceSquared(pos) < 60*60 then
                    return {
                        StageAPI.E.DeleteMeEffect.T,
                        StageAPI.E.DeleteMeEffect.V,
                        0,
                        seed
                    }
                else
                    return
                end
            end
        end
    end
end)

local PlayerExtraAnimations = {
    "LightTravel",
    "FallIn",
    "JumpOut",
    "UseItem",
    "Jump",
    "TeleportUp",
    "TeleportDown",
    "Sad",
    "Happy",
    "Pickup",
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local data, sprite = REVEL.GetData(eff), eff:GetSprite()
    if data.HubTrapdoor and sprite:IsFinished("Lock") then
        sprite:Play("Locked", true)
    end

    if data.HubTrapdoor and (not data.Touched or data.BeingEntered) and not (sprite:IsPlaying("Lock") or sprite:IsFinished("Locked")) then
        if sprite:IsFinished("Open Animation") or sprite:IsFinished("Player Exit") then
            sprite:Play("Opened", true)
        end

        if sprite:IsFinished("Open AnimationNoLadder") or sprite:IsFinished("Player ExitNoLadder") then
            sprite:Play("OpenedNoLadder", true)
        end

        local touched, farEnough
        for _, player in ipairs(REVEL.players) do
            local dist = eff.Position:DistanceSquared(player.Position)
            if dist < (player.Size + 16) ^ 2 and not REVEL.MultiPlayingCheck(player:GetSprite(), PlayerExtraAnimations) then
                touched = player
            elseif dist > (player.Size + 16 + 40) ^ 2 then
                farEnough = true
            end
        end

        if farEnough and sprite:IsFinished("Closed") then
            sprite:Play("Open AnimationNoLadder", true)
        end

        local transition
        if data.BeingEntered then
            for _, player in ipairs(REVEL.players) do
                player.ControlsCooldown = 5
                player.Velocity = (REVEL.Lerp(player.Position, eff.Position, 0.5) - player.Position) / 2
                if player:IsExtraAnimationFinished() then
                    player.Visible = false
                    transition = true
                end
            end
        elseif touched then
            if sprite:IsFinished("Opened") or sprite:IsFinished("OpenedNoLadder") then
                for _, player in ipairs(REVEL.players) do
                    player.Velocity = Vector.Zero
                end

                if not data.StartingRoomHub then
                    for _, player in ipairs(REVEL.players) do
                        player:AnimateTrapdoor()
                    end

                    data.BeingEntered = true
                else
                    transition = true
                end

                data.Touched = true
            end
        end

        if transition then
            local defaultMap = StageAPI.GetDefaultLevelMap()
            local hubRoomData = defaultMap:GetRoomDataFromRoomID("RevelationsHub")
            local hubRoom
            if not hubRoomData then
                local rng = REVEL.RNG()
                rng:SetSeed(REVEL.room:GetSpawnSeed(), 40)
                local nextSeed = math.max(1,  rng:Next())
                hubRoom = StageAPI.LevelRoom{
                    RoomsList = REVEL.RoomLists.RevelationsHub,
                    SpawnSeed = nextSeed, 
                    Shape = RoomShape.ROOMSHAPE_1x1,
                    RoomType = RevRoomType.HUB2D,
                    IsExtraRoom = true,
                    IgnoreDoors = true,
                }
                hubRoomData = defaultMap:AddRoom(hubRoom, {RoomID = "RevelationsHub"})
            else
                ---@type LevelRoom
                hubRoom = defaultMap:GetRoom(hubRoomData)
            end

            if data.StartingRoomHub then
                hubRoom.PersistentData.HubVersion = "SkipHub"
            else
                hubRoom.PersistentData.HubVersion = REVEL.GetHubVersionForStage()
            end

            hubRoom.PersistentData.FromDoor = "Main"
            hubRoom.PersistentData.ExitRoom = REVEL.level:GetCurrentRoomIndex()
            hubRoom.PersistentData.ExitRoomPosition = {X = eff.Position.X, Y = eff.Position.Y + 80}
            
            StageAPI.ExtraRoomTransition(hubRoomData.MapID, nil, RoomTransitionAnim.PIXELATION, StageAPI.DefaultLevelMapID, DoorSlot.DOWN0)

            if sprite:IsFinished("Opened") then
                sprite:Play("Player Exit", true)
            else
                sprite:Play("Player ExitNoLadder", true)
            end

            data.BeingEntered = nil
        end
    elseif data.HubItemCrate then
        if sprite:IsEventTriggered("Land") then
            REVEL.sfx:Play(SoundEffect.SOUND_CHEST_DROP)
        end

        if sprite:IsEventTriggered("Spawn") then
            local roomDesc = REVEL.level:GetCurrentRoomDesc()
            local isDevilCrown = HasBit(roomDesc.Flags, RoomDescriptor.FLAG_DEVIL_TREASURE)

            local keeperBExists = false
			for _,player in ipairs(REVEL.players) do
				if player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
					keeperBExists = true
					break
				end
			end

            REVEL.sfx:Play(SoundEffect.SOUND_THUMBSUP)

            local item = Isaac.Spawn(
                EntityType.ENTITY_PICKUP, 
                PickupVariant.PICKUP_COLLECTIBLE, 
                0, 
                eff.Position + Vector(0, -crateItemOffset), 
                Vector.Zero, 
                nil
            ):ToPickup()
			
			if keeperBExists then
                item.ShopItemId = -1
				item.Price = 15
				item.AutoUpdatePrice = true
            elseif isDevilCrown then
                item.ShopItemId = -1
                item.Price = REVEL.GetDevilPrice(item.SubType)
                item.AutoUpdatePrice = true
            end
		end

        if sprite:IsFinished("Appear") then
            local crate = StageAPI.SpawnFloorEffect(eff.Position, Vector.Zero, nil, "gfx/backdrop/revelcommon/hubroom/lootbox.anm2", true, REVEL.ENT.HUB_DECORATION.variant)
            crate:GetSprite():Play("FlatOpen", true)
            REVEL.GetData(crate).HubItemCrate = true
            eff:Remove()
        end
    end
end, REVEL.ENT.HUB_DECORATION.variant)

local HubGrid = StageAPI.GridGfx()
HubGrid:SetRocks("stageapi/none.png")

local HubBackdrop = StageAPI.BackdropHelper({
    Walls = {"hubwall"}
}, "gfx/backdrop/revelcommon/hubroom/", ".png")

local HubGfx = StageAPI.RoomGfx(HubBackdrop, HubGrid)

local HubBackdrop = REVEL.LazyLoadRoomSprite{
    ID = "HubBackdrop",
    Anm2 = "gfx/backdrop/revelcommon/hubroom/hub_backdrop.anm2",
}
local HubBackdropHasLadder = true

--local hubCandleGlow = Sprite()
--hubCandleGlow:Load("gfx/backdrop/revelcommon/hubroom/revelations_candleglow.anm2", true)
--hubCandleGlow:Play("Idle", true)

local hubRoomDoorSlots = {
    Left = {
        DoorPosition = Vector(278, 402),
        LastDoor = nil,
        LastBackground = nil
    },
    Middle = {
        DoorPosition = Vector(378, 402),
        LastDoor = nil,
        LastBackground = nil
    },
    Right = {
        DoorPosition = Vector(478, 402),
        LastDoor = nil,
        LastBackground = nil
    }
}

for slot, slotData in pairs(hubRoomDoorSlots) do
    -- revrt to this system once I figure out why
    -- it bugs out the door backgrounds and sprites
--     if not slotData.DoorSprite then
--         slotData.DoorSprite = REVEL.LazyLoadRoomSprite{
--             ID = "hubslot" .. slot .. "DoorSprite",
--             Anm2 = "gfx/backdrop/revelcommon/hubroom/hubdoor.anm2",
--         }
--     end

--     if not slotData.BackgroundSprite then
--         slotData.BackgroundSprite = REVEL.LazyLoadRoomSprite{
--             ID = "hubslot" .. slot .. "BackgroundSprite",
--             Anm2 = "gfx/backdrop/revelcommon/hubroom/hubdoor_background.anm2",
--         }
--     end
    if not slotData.DoorSprite then
        slotData.DoorSprite = Sprite()
        slotData.DoorSprite:Load("gfx/backdrop/revelcommon/hubroom/hubdoor.anm2", true)
    end

    if not slotData.BackgroundSprite then
        slotData.BackgroundSprite = Sprite()
        slotData.BackgroundSprite:Load("gfx/backdrop/revelcommon/hubroom/hubdoor_background.anm2", true)
    end

    if not slotData.BackgroundPosition then
        slotData.BackgroundPosition = slotData.DoorPosition + Vector(-48, -226)
    end
end

local buttonSprite = REVEL.LazyLoadRoomSprite{
    ID = "HubButton",
    Anm2 = "gfx/ui/buttons.anm2",
    OnCreate = function(sprite)
        sprite:SetFrame("XboxOne", 5)
    end,
}

REVEL.HubRoomVersions = {}

local function GetNextStage(levelStage)
    return levelStage + 1
end

function REVEL.GetHubVersionForStage()
    local outVersion
    -- dante and charon no longer have special treatment since 
    -- they don't get perma-labyrinth anymore
    -- local isCharon = REVEL.IsDanteCharon(REVEL.player)
    local isCharon = false
    for version, verData in pairs(REVEL.HubRoomVersions) do
        if verData.Stages then
            for _, stage in ipairs(verData.Stages) do
                if type(stage.Stage) == "number" then
                    local stageType = REVEL.level:GetStageType()
                    local isRepentanceStage = stageType == StageType.STAGETYPE_REPENTANCE 
                        or stageType == StageType.STAGETYPE_REPENTANCE_B
                    local levelStage = REVEL.level:GetStage()
                    local checkStage = isRepentanceStage and GetNextStage(levelStage) or levelStage

                    if not StageAPI.InNewStage() and checkStage == stage.Stage then
                        outVersion = version
                        break
                    end
                elseif stage.Stage.IsStage then
                    if stage.Stage:IsStage() and (stage.IsSecondStage == nil or StageAPI.GetCurrentStage().IsSecondStage == stage.IsSecondStage) then
                        outVersion = version
                        break
                    end
                else
                    error("Hub room 1 | Stage entry inside REVEL.HubRoomVersions." .. version .. " is not a LevelStage or CustomStage")
                end
            end
        end
    end

    return outVersion
end

local hubMachine = REVEL.LazyLoadRoomSprite{
    ID = "HubMachine",
    Anm2 = "gfx/backdrop/revelcommon/hubroom/lootbox_hub.anm2",
}

local hubMachinePosition = Vector(378.5, 404)

local StageTransitionWorkaroundFakePlayer

local function StartStageTransitionWorkaround()
    -- Uses forget me now to forge stage transition
    -- For some reason the player has a bugged sprite the first frame (and in the fadein)
    -- after the transition when using it, and no way around it apparently, so create a fake
    -- player to use the item and avoid the problem and remove it ASAP after; cannot remove 
    -- it immediately since it starts the new stage and it requires game to not be paused
    local fakePlayer = REVEL.NewPlayer(PlayerType.PLAYER_ISAAC, 0, REVEL.player)
    REVEL.game:GetHUD():AssignPlayerHUDs()

    fakePlayer.Visible = false
    -- reset to visible on new level, apparently
    fakePlayer:SetColor(Color(0,0,0,0), 999, 999, false, true)

    fakePlayer:UseActiveItem(CollectibleType.COLLECTIBLE_FORGET_ME_NOW, false, false, true, false, 0)
    fakePlayer:StopExtraAnimation()
    StageTransitionWorkaroundFakePlayer = EntityPtr(fakePlayer)
end

local function SetSlotData(usingHubData)
    local stageType = REVEL.level:GetStageType()
    local isRepentanceStage = stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B

    local isEarly = "Late"
    if StageAPI.InNewStage() then
        local currentStage = StageAPI.GetCurrentStage()
        ---@diagnostic disable-next-line: need-check-nil
        if currentStage.IsSecondStage then
            isEarly = "Early"
        end
    elseif ((REVEL.level:GetStage() % 2 == 1) ~= isRepentanceStage)
    and not HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH) then
        isEarly = "Early"
    end
    
    local stageTypeKey = "Default"
    if REVEL.IsRevelStage() 
    or REVEL.level:GetStageType() == StageType.STAGETYPE_REPENTANCE
    or REVEL.level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B
    then
        stageTypeKey = "Alt"
    end

    local validSlots = {}

    for slot, slotData in pairs(hubRoomDoorSlots) do
        local sheet = usingHubData.Sprites[slot]
        if sheet then
            validSlots[#validSlots + 1] = slot
            if sheet.Alt then
                sheet = sheet[stageTypeKey]
            end
            if sheet.Early then
                sheet = sheet[isEarly]
            end

            local doorSheet = usingHubData.Prefix .. sheet[1] .. sheet[2] .. (sheet[3] or "") .. ".png"
            local backgroundSheet = usingHubData.Prefix .. sheet[1] .. "background_" .. sheet[2] .. ".png"

            if slotData.LastDoor ~= doorSheet then
                for i = 0, 2 do
                    slotData.DoorSprite:ReplaceSpritesheet(i, doorSheet)
                end

                slotData.DoorSprite:LoadGraphics()
                slotData.LastDoor = doorSheet
            end

            if slotData.LastBackground ~= backgroundSheet then
                slotData.BackgroundSprite:ReplaceSpritesheet(0, backgroundSheet)
                slotData.BackgroundSprite:LoadGraphics()
                slotData.LastBackground = backgroundSheet
            end

            local entering = usingHubData.Entering[slot]
            if entering.Early then
                entering = entering[isEarly]
            end

            slotData.Entering = entering

            local locked = usingHubData.Locked[slot]
            if type(locked) == "table" and locked.Alt then
                locked = locked[stageTypeKey]
            end
            if type(locked) == "table" and locked.Early then
                locked = locked[isEarly]
            end

            slotData.Locked = locked
        end
    end

    return validSlots
end

local function SlotUpdate(usingHubData, slot, slotData, sprite, data)
    sprite:Update()

    if slotData.Entering and not slotData.Entering.Locked then
        if sprite:IsFinished("Open") then
            sprite:Play("Opened")
        end

        if sprite:IsFinished("Closed") then
            if slotData.Locked == HubDoorLock.NONE then
                if usingHubData.OpenSound and usingHubData.OpenSound[slot] then
                    REVEL.sfx:Play(usingHubData.OpenSound[slot], 0.5, 0, false, 1)
                end

                sprite:Play("Open", true)
            end
        end
    end

    if slotData.Entering.IsSecondStage then
        sprite:PlayOverlay("SignTwo", true)
    else
        sprite:PlayOverlay("SignOne", true)
    end

    if REVEL.MultiAnimOnCheck(sprite, "ClosedPlanks1", "ClosedPlanks2") then
        data.AlreadyHadThisExplosion = data.AlreadyHadThisExplosion or {}

        local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)
        local exploded = false
        local pos = slotData.DoorPosition
        for _, e in ipairs(explosions) do
            local id = tostring(GetPtrHash(e)) .. tostring(e.InitSeed)
            if e.Position:DistanceSquared(pos) < 80 ^ 2
            and not data.AlreadyHadThisExplosion[id] then
                exploded = true
                data.AlreadyHadThisExplosion[id] = true
                break
            end
        end

        if exploded then
            if IsAnimOn(sprite, "ClosedPlanks2") then
                sprite:Play("ClosedPlanks1", true)
            elseif IsAnimOn(sprite, "ClosedPlanks1") then
                sprite:Play("Open", true)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, eff)
    if REVEL.GetData(eff).HubRenderer and REVEL.IsRenderPassNormal() then
        local renderPos = Isaac.WorldToScreen(REVEL.room:GetTopLeftPos() - Vector(40, 40))

        local musicId = REVEL.music:GetCurrentMusicID()
        if StageAPI.CanOverrideMusic(musicId) then -- hub room music makes this returns false, among others
            REVEL.music:Play(REVEL.MUSIC.HUB_ROOM_STINGER, 0)
            REVEL.music:Queue(REVEL.MUSIC.HUB_ROOM)
            REVEL.music:UpdateVolume()
        end

        local data = REVEL.GetData(eff)
        local version = data.HubVersion
        local usingHubData = REVEL.HubRoomVersions[version]

        if usingHubData.Ladder and not HubBackdropHasLadder then
            HubBackdrop:ReplaceSpritesheet(1, "gfx/backdrop/revelcommon/hubroom/revelations_hubforeground.png")
            HubBackdrop:LoadGraphics()
            HubBackdropHasLadder = true
        elseif not usingHubData.Ladder and HubBackdropHasLadder then
            HubBackdrop:ReplaceSpritesheet(1, "gfx/backdrop/revelcommon/hubroom/revelations_hubforeground_noladder.png")
            HubBackdrop:LoadGraphics()
            HubBackdropHasLadder = false
        end

        local validSlots = SetSlotData(usingHubData)

        HubBackdrop:SetFrame("Idle", 0)
        HubBackdrop:RenderLayer(0, renderPos)

        for _, slot in ipairs(validSlots) do
            local slotData = hubRoomDoorSlots[slot]
            slotData.BackgroundSprite:Render(Isaac.WorldToScreen(slotData.BackgroundPosition), Vector.Zero, Vector.Zero)
        end

        HubBackdrop:RenderLayer(1, renderPos)

        --hubCandleGlow:Render(renderPos, Vector.Zero, Vector.Zero)

        if usingHubData.HasHubMachine then
            if StageAPI.IsOddRenderFrame and not REVEL.game:IsPaused() then
                --hubCandleGlow:Update()
                hubMachine:Update()
            end

            if hubMachine:IsEventTriggered("Land") then
                REVEL.sfx:Play(SoundEffect.SOUND_FETUS_LAND, 0.55, 0, false, 1)
            end
            if hubMachine:IsEventTriggered("Snap") then
                REVEL.sfx:Play(SoundEffect.SOUND_BOIL_HATCH, 0.33, 0, false, 1.05)
            end

            hubMachine:Render(Isaac.WorldToScreen(hubMachinePosition), Vector.Zero, Vector.Zero)
        end

        for _, slot in ipairs(validSlots) do
            local slotData = hubRoomDoorSlots[slot]
            local sprite = slotData.DoorSprite
            if StageAPI.IsOddRenderFrame and not REVEL.game:IsPaused() then
                SlotUpdate(usingHubData, slot, slotData, sprite, data.SlotTempData[slot])
            end

            if sprite:IsEventTriggered("Slam") then
                REVEL.game:ShakeScreen(5)
            end

            local renderButton
            if slotData.Entering and not slotData.Entering.Locked then
                local startedTransition
                for _, player in ipairs(REVEL.players) do
                    local keyPrice = 1
                    local heartsPrice = 4
                    local canPay = slotData.Locked == HubDoorLock.NONE
                        or (slotData.Locked == HubDoorLock.BOMBS and REVEL.MultiAnimOnCheck(sprite, "Open", "Opened"))
                        or (slotData.Locked == HubDoorLock.KEY and player:GetNumKeys() >= keyPrice)
                        or (slotData.Locked == HubDoorLock.HEARTS and player:GetHearts() + player:GetSoulHearts() > heartsPrice)

                    if not REVEL.GetData(player).EnteringHubDoor 
                    and player:GetPlayerType() ~= PlayerType.PLAYER_ESAU
                    and player.Position:DistanceSquared(slotData.DoorPosition) < (player.Size + 16) ^ 2 then
                        renderButton = true
                        if Input.IsActionTriggered(ButtonAction.ACTION_UP, player.ControllerIndex) then
                            if canPay then
                                local playOpen = false
                                if slotData.Locked == HubDoorLock.KEY then
                                    player:AddKeys(-keyPrice)
                                    playOpen = true
                                    REVEL.sfx:Play(SoundEffect.SOUND_UNLOCK00)
                                elseif slotData.Locked == HubDoorLock.HEARTS then
                                    if not REVEL.PlayerIsLost(player) then
                                        -- cannot use addhearts as it affects
                                        -- non red hearts the same way normally for maus
                                        player:TakeDamage(
                                            heartsPrice, 
                                            BitOr(
                                                DamageFlag.DAMAGE_NO_PENALTIES, 
                                                -- DamageFlag.DAMAGE_DEVIL, 
                                                DamageFlag.DAMAGE_INVINCIBLE,
                                                DamageFlag.DAMAGE_NO_MODIFIERS
                                            ),
                                            EntityRef(eff),
                                            0
                                        )
                                        REVEL.sfx:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT)
                                    end
                                    REVEL.sfx:Play(SoundEffect.SOUND_UNLOCK00)
                                    playOpen = true
                                end

                                if playOpen then
                                    if usingHubData.OpenSound and usingHubData.OpenSound[slot] then
                                        REVEL.sfx:Play(usingHubData.OpenSound[slot], 0.5, 0, false, 1)
                                    end
            
                                    sprite:Play("Open", true)
                                end

                                startedTransition = true
                                REVEL.GetData(player).EnteringHubDoor = {Slot = slot, Delay = 16}
                                REVEL.GetData(player).HubJumpTargetPosition = slotData.DoorPosition + Vector(0, -20)
                                
                                player:AnimateTrapdoor()

                                if usingHubData.HasHubMachine then
                                    if not hubMachine:IsPlaying("Fall2") and not hubMachine:IsFinished("Fall2") then
                                        hubMachine:Play("Fall2", true)
                                    end
                                end
                            else
                                REVEL.sfx:Play(SoundEffect.SOUND_BIRD_FLAP, 1, 0, false, 0.75)
                            end
                        end
                    end

                    if startedTransition then
                        for _, player in ipairs(REVEL.players) do
                            player.Velocity = Vector.Zero
                        end
                    end
                end
            end

            sprite:Render(Isaac.WorldToScreen(slotData.DoorPosition), Vector.Zero, Vector.Zero)

            if renderButton then
                local floatY = Vector(0, 3):Rotated((REVEL.game:GetFrameCount() * 2.5) % 360).Y
                buttonSprite:Render(Isaac.WorldToScreen(slotData.DoorPosition + Vector(0, -80)) + Vector(0, floatY), Vector.Zero, Vector.Zero)
            end
        end
    end
end, REVEL.ENT.HUB_DECORATION.variant)

-- for ugly StartStageTransition workaround, can be deleted once fixed
revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, Type, variant, subType, pos, vel, spawner, seed)
	if Type == EntityType.ENTITY_EFFECT and variant == EffectVariant.POOF01 then
		if StageAPI.InExtraRoom() and StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D then
			for _,player in ipairs(REVEL.players) do
				if REVEL.GetData(player).EnteringHubDoor then
					return {
                            StageAPI.E.DeleteMeEffect.T,
                            StageAPI.E.DeleteMeEffect.V,
                            0,
                            seed
                        }
				end
			end
		end
	end
end)

revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
    if action == ButtonAction.ACTION_UP 
    and StageAPI.InExtraRoom() 
    and StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D 
    and entity and entity:ToPlayer() 
    and not entity:ToPlayer().CanFly then
        local x = REVEL.GridToVector(REVEL.room:GetGridIndex(entity.Position))
        local currentRoom = StageAPI.GetCurrentRoom()
        if x ~= 1 or not REVEL.HubRoomVersions[currentRoom.PersistentData.HubVersion].Ladder then
            if hook == InputHook.GET_ACTION_VALUE then
                return 0
            else
                return false
            end
        end
    end
end)

local function hubRoomPlayerUpdate(player, currentRoom)
    local enteringHubDoor = REVEL.GetData(player).EnteringHubDoor
    if enteringHubDoor and enteringHubDoor.Delay then
		local slotData = hubRoomDoorSlots[enteringHubDoor.Slot]

        player.Velocity = REVEL.Lerp(player.Position, REVEL.GetData(player).HubJumpTargetPosition, 0.5) - player.Position
        if player:IsExtraAnimationFinished() then
            player.Visible = false

            local doorSprite = slotData.DoorSprite
            if not (doorSprite:IsPlaying("Close") or doorSprite:IsFinished("Close")) then
                doorSprite:Play("Close", true)
                REVEL.sfx:Play(SoundEffect.SOUND_DOOR_HEAVY_CLOSE, 1, 0, false, 1)
            end

            enteringHubDoor.Delay = enteringHubDoor.Delay - 1
            if enteringHubDoor.Delay < 0 then
                if not StageAPI.InNewStage() and slotData.Entering.NormalStage then
                    if slotData.Entering.IsRepentance then
                        local levelStage = slotData.Entering.Stage
                        local stageType = REVEL.SimulateStageTransitionStageType(levelStage + levelStage%2, true)
                
                        REVEL.level:SetStage(levelStage, stageType)
                    else
                        REVEL.level:SetNextStage()
                    end

                    -- StartStageTransition is completely broken atm, workaround is used instead
					-- REVEL.game:StartStageTransition(false, -1)
					StartStageTransitionWorkaround()
                else
                    if slotData.Entering.IsRepentance then
                        local levelStage = slotData.Entering.Stage
                        local stageType = REVEL.SimulateStageTransitionStageType(levelStage + levelStage%2, true)
                        slotData.Entering.StageType = stageType
                    end

                    StageAPI.GotoCustomStage(slotData.Entering, true)
                end

                enteringHubDoor.Delay = nil
            end
        end

        player.ControlsCooldown = 2
        for _, player2 in ipairs(REVEL.players) do
            if not REVEL.GetData(player2).EnteringHubDoor then
                player2.Velocity = Vector.Zero
                player2.ControlsCooldown = 2
            end
        end
    elseif not REVEL.room:IsPositionInRoom(player.Position, -20) then
        for _, player in ipairs(REVEL.players) do
            player.Velocity = Vector.Zero
        end
        StageAPI.ExtraRoomTransition(currentRoom.PersistentData.ExitRoom, nil, RoomTransitionAnim.PIXELATION, nil, nil, nil, Vector(currentRoom.PersistentData.ExitRoomPosition.X, currentRoom.PersistentData.ExitRoomPosition.Y))
    else
        if not player.CanFly then
            local x = REVEL.GridToVector(REVEL.room:GetGridIndex(player.Position))
            if x ~= 1 or not REVEL.HubRoomVersions[currentRoom.PersistentData.HubVersion].Ladder then
                player.Velocity = player.Velocity + Vector(0, 2)
            end
        end
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    for _, player in ipairs(REVEL.players) do
        if REVEL.GetData(player).EnteringHubDoor then
            REVEL.GetData(player).EnteringHubDoor = nil
            REVEL.GetData(player).HubJumpTargetPosition = nil
            player.Visible = true

            local fakePlayer = StageTransitionWorkaroundFakePlayer and StageTransitionWorkaroundFakePlayer.Ref
            if fakePlayer then
                ---@type EntityPlayer
                fakePlayer = fakePlayer:ToPlayer()
                REVEL.RemoveExtraPlayer(fakePlayer)
                if #REVEL.players == 1 then
                    REVEL.players[1].Position = REVEL.room:GetCenterPos()
                end
            end

            StageTransitionWorkaroundFakePlayer = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function() -- PEFFECT won't work because extra animations halt it
    if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D then
        local currentRoom = StageAPI.GetCurrentRoom()
        for _, player in ipairs(REVEL.players) do
            if currentRoom.Data.SetPlayerPosAgain then
                player.Position = REVEL.room:GetGridPosition(2) + Vector(0, 40)
            end

            hubRoomPlayerUpdate(player, currentRoom)
        end

        currentRoom.Data.SetPlayerPosAgain = nil
    end
end)

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, function(newRoom)
    if newRoom.RoomType == RevRoomType.HUB2D then
        newRoom.Data.PreventDoorFix = true
        newRoom.Data.RoomGfx = HubGfx
    end
end)

StageAPI.AddCallback("Revelations", "PRE_SPAWN_GRID", 1, function(gridData)
    if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D then
        if gridData.Type == GridEntityType.GRID_ROCKB then
            Isaac.GridSpawn(GridEntityType.GRID_WALL, 0, REVEL.room:GetGridPosition(gridData.Index), true)
            return false
        end
    end
end)

local function randomHubPos()
  return Vector(240 + math.random(520 - 240), 200 + math.random(373 - 200))
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(newRoom, revisited)
    if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D then
        REVEL.room:RemoveGridEntity(2, 0, false) -- hole for ladder
        -- REVEL.room:Update()

        for _, player in ipairs(REVEL.players) do
            player.Position = REVEL.room:GetGridPosition(2) + Vector(0, 40)
            player.Visible = true
        end

        newRoom.Data.SetPlayerPosAgain = true -- on save and continue, something appears to force the player to be next to a door after POST_ROOM_LOAD is called

        hubMachine:Play("Idle", true)

        local r = 2 + math.random(2)
        for i = 1, r do
            Isaac.Spawn(1000, EffectVariant.WISP, 0, randomHubPos(), Vector.Zero, REVEL.player)
        end

        local spritePos = REVEL.room:GetCenterPos()
        local entityPos = REVEL.room:GetTopLeftPos() - Vector(80, 80) --for priority
        local spriteOffset = (spritePos - entityPos) * REVEL.WORLD_TO_SCREEN_RATIO

        local hubRenderer = REVEL.ENT.HUB_DECORATION:spawn(
            entityPos, 
            Vector.Zero, 
            nil
        )
        hubRenderer.SpriteOffset = spriteOffset
        hubRenderer:GetSprite():Load("gfx/blank.anm2", true)
        hubRenderer.RenderZOffset = -10000
        REVEL.GetData(hubRenderer).HubRenderer = true

        REVEL.GetData(hubRenderer).HubVersion = newRoom.PersistentData.HubVersion
        REVEL.GetData(hubRenderer).SlotTempData = {
            Left = {},
            Middle = {},
            Right = {},
        }

        SetSlotData(REVEL.HubRoomVersions[newRoom.PersistentData.HubVersion])

        for slot, slotData in pairs(hubRoomDoorSlots) do
            if slotData.Locked == HubDoorLock.BOMBS then
                slotData.DoorSprite:Play("ClosedPlanks2", true)
            else
                slotData.DoorSprite:Play("Closed", true)
            end
            slotData.BackgroundSprite:Play("Idle", true)
        end
    end
end)

--Hub shader

REVEL.HubShader = REVEL.CCShader("Da Hub")
local s = REVEL.HubShader
s:Set3WayWeight(320, 7.5, 3.5)
s:SetTemp(12)
s:SetTintShadows(0.6, 0.7, 0.3)
s:SetHighlights{
  Temperature = 3
}
s:SetContrast(0.001)
s:SetLightness(-0.001)
s:SetSaturation(-0.07)
-- s:SetColorBoostSelection(0.15, 0.151, 0.15, 0.6)
-- s:SetColBoostRGB(1.06, 1.04, 0.99)
-- s:SetColBoostSat(0.1)

function REVEL.HubShader:OnUpdate()
  if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D then
    self.Active = 1
  else
    self.Active = 0
  end
end

REVEL.AntiBB_Sh = REVEL.CCShader("Burning basement compensation")
s = REVEL.AntiBB_Sh
s:SetLevels(4/255,3/255,0.07)
s:SetRGB(0.91,0.97,1.02)
s:SetContrast(0.012)
s:SetSaturation(-0.05)
s:SetShadows{
  RGB = {0.9,0.9,1.03},
  Temperature = 12.5,
  Brightness = 0.05
}
s:SetMidtones{
  RGB = {0.99,0.95,1.04},
}
s:SetTemp(5)
s:SetBrightness(0.67)
s:SetLightness(0.01)

function REVEL.AntiBB_Sh:OnUpdate()
  if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D and not StageAPI.InNewStage() and REVEL.game:GetLevel():GetStageType() == StageType.STAGETYPE_AFTERBIRTH and (REVEL.game:GetLevel():GetStage() == LevelStage.STAGE1_1 or REVEL.game:GetLevel():GetStage() == LevelStage.STAGE1_2) then
    self.Active = 1
    REVEL.HubShader:SetUseColorBoost(false)
  else
    REVEL.HubShader:SetUseColorBoost(true)
    self.Active = 0
  end
end

REVEL.Caves_Sh = REVEL.CCShader("Caves compensation")
REVEL.Caves_Sh:SetLevels(0,0,0.05)
REVEL.Caves_Sh:SetExposure(0.01)

function REVEL.Caves_Sh:OnUpdate()
  if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D and not StageAPI.InNewStage() and (REVEL.game:GetLevel():GetStage() == LevelStage.STAGE2_1 or REVEL.game:GetLevel():GetStage() == LevelStage.STAGE2_2) then
    self.Active = 1
  else
    self.Active = 0
  end
end

-- REVEL.FCaves_Sh = REVEL.CCShader("Flooded Caves compensation")
-- REVEL.FCaves_Sh:SetRGB(1, 0.85, 0.75)
--
-- function REVEL.FCaves_Sh:OnUpdate()
--   if StageAPI.GetCurrentRoomType() == RevRoomType.HUB2D and not StageAPI.InNewStage() and REVEL.game:GetLevel():GetStageType() == StageType.STAGETYPE_AFTERBIRTH and (REVEL.game:GetLevel():GetStage() == LevelStage.STAGE2_1 or REVEL.game:GetLevel():GetStage() == LevelStage.STAGE2_2) then
--     self.Active = 1
--   else
--     self.Active = 0
--   end
-- end

Isaac.DebugString("Revelations: Loaded Hub Room!")
end