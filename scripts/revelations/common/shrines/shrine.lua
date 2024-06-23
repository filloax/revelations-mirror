local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.CURSED_SHRINE.id,
    Variant = REVEL.ENT.CURSED_SHRINE.variant
})

---@param customStage? CustomStage
---@return string
function REVEL.GetShrineSetForStage(customStage)
    customStage = customStage or StageAPI.GetCurrentStage()
    local set
    if StageAPI.IsSameStage(REVEL.STAGE.Glacier, customStage) then
        set = "Glacier"
    elseif StageAPI.IsSameStage(REVEL.STAGE.Tomb, customStage) then
        set = "Tomb"
    end
    return set
end

local function UseReducedStageValue()
    return REVEL.IsLastChapterStage()
        and not REVEL.IsThereCurse(LevelCurse.CURSE_OF_LABYRINTH)
end

local function SetupShrine(shrine, useShrine, useShrineName, shrineSet, setName, noAddToSeenShrines)
    local shrineData, shrineSprite = REVEL.GetData(shrine), shrine:GetSprite()

    shrine:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_STATUS_EFFECTS, EntityFlag.FLAG_NO_TARGET))
    shrineData.Init = true
    shrineData.ShrineSet = setName
    shrine.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
    shrine.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    local gridEnt = REVEL.room:GetGridEntityFromPos(shrine.Position)
    if not gridEnt
    or gridEnt.Desc.Type == GridEntityType.GRID_DECORATION then
        if gridEnt then
            REVEL.room:RemoveGridEntity(REVEL.room:GetGridIndex(shrine.Position), 0, false)
            REVEL.room:Update()
        end

        REVEL.GRIDENT.INVISIBLE_BLOCK:Spawn(REVEL.room:GetGridIndex(shrine.Position), true, false)
    end
        
    if useShrine then
        shrineData.ShrineType = useShrineName
        if not noAddToSeenShrines then
            revel.data.run.level.shrineTypes[#revel.data.run.level.shrineTypes + 1] = useShrineName
        end

        if useShrine.IsTall then
            shrineSprite:Load("gfx/grid/revelcommon/shrines/shrine_tall.anm2", true)
        end

        shrineData.ShrineGfx = shrineSet.Prefix .. (useShrine.Sprite or useShrine.Name) .. shrineSet.Suffix
        shrineSprite:ReplaceSpritesheet(0, shrineData.ShrineGfx)

        local rewardValue = useShrine.Value or REVEL.ShrineBalance.DefaultPactVanity
        if UseReducedStageValue() then
            rewardValue = useShrine.ValueOneChapter or REVEL.ShrineBalance.DefaultPactVanityOneChapter
        end

        shrineData.Value = rewardValue
        shrineData.ValueOneChapter = useShrine.ValueOneChapter or REVEL.ShrineBalance.DefaultPactVanityOneChapter

        if useShrine.EID_Description then
            local eid_Description = REVEL.CopyTable(useShrine.EID_Description)
            eid_Description.Description = eid_Description.Description .. ("#+ %d Vanity"):format(rewardValue)
            shrine:GetData().EID_Description = eid_Description
        end

        if shrineSet.Lightning then
            shrineData.ShrineLightning = shrineSet.Lightning
            shrineSprite:ReplaceSpritesheet(1, shrineSet.Lightning)
        end

        shrineSprite:LoadGraphics()
        if not REVEL.room:IsFirstVisit() then
            shrineSprite:SetFrame("Idle", 1)
            shrineData.Activated = true
        end
    else
        shrineData.ShrineGfx = shrineSet.Prefix .. "blank" .. shrineSet.Suffix
        shrineSprite:ReplaceSpritesheet(0, shrineData.ShrineGfx)
        shrineSprite:LoadGraphics()
        shrineData.Activated = true
    end
end

REVEL.ShrineSelectionRNG = REVEL.RNG()

local function GetRemainingShrineWeights(setName, exclude)
    local shrineSet = REVEL.GetShrineSet(setName)
    local shrineWithWeights = {}
    for _, name in ipairs(shrineSet) do
        local isActive, activeAmount = REVEL.IsShrineEffectActive(name)
        local shrineData = REVEL.Shrines[name]

        if (
            not isActive 
            or (
                shrineData.Repeatable 
                and (not shrineData.MaxRepeats or activeAmount < shrineData.MaxRepeats)
            )
        )
        and (not shrineData.Requires or shrineData.Requires())
        and (not exclude or not REVEL.includes(exclude, name))
        then
            shrineWithWeights[name] = shrineData.Weight or 1
        end
    end

    return shrineWithWeights
end

function REVEL.SetupShrines(setName)
    REVEL.ShrineSelectionRNG:SetSeed(REVEL.room:GetSpawnSeed(), 0)
    local shrineSet = REVEL.GetShrineSet(setName)
    local shrineWithWeights = GetRemainingShrineWeights(setName)

    local croom = StageAPI.GetCurrentRoom()
    local persistData = croom.PersistentData
    persistData.Shrines = persistData.Shrines or {}

    local randomizedShrines = REVEL.WeightedShuffle(shrineWithWeights, REVEL.ShrineSelectionRNG)
    local shrines = REVEL.ENT.CURSED_SHRINE:getInRoom()
    local useNames = REVEL.slice(randomizedShrines, 1, #shrines)
    useNames = REVEL.sort(useNames) --so that the order is fixed in case there are exactly N shrines

    for i, shrine in ipairs(shrines) do
        local grindex = REVEL.room:GetGridIndex(shrine.Position)

        if not persistData.Shrines[grindex] then
            persistData.Shrines[grindex] = useNames[i] or "blank"
        end

        local useShrineName = persistData.Shrines[grindex]
        if useShrineName ~= "blank" then
            local useShrine = REVEL.Shrines[useShrineName]

            SetupShrine(shrine, useShrine, useShrineName, shrineSet, setName)
        else
            SetupShrine(shrine, nil, nil, shrineSet, setName)
        end
    end
end

function REVEL.SpawnShrine(pos, shutdoors, setName, shrineName, noAddToSeenShrines)
    local shrine = REVEL.ENT.CURSED_SHRINE:spawn(pos, Vector.Zero, nil)

    REVEL.GetData(shrine).StartShutDoors = shutdoors
    REVEL.GetData(shrine).ShutDoors = shutdoors

    SetupShrine(shrine, REVEL.Shrines[shrineName], shrineName, REVEL.GetShrineSet(setName), setName, noAddToSeenShrines)

    return shrine
end

REVEL.CurseFont = Font()
REVEL.CurseFont:Load("font/teammeatfont10.fnt")

local PlaqueFont = Font()
PlaqueFont:Load("font/upheaval.fnt") --fallback, assuming failed font loads keep the original font
REVEL.LoadCustomFont(PlaqueFont, "font/incision_upheaval/incision_upheaval.fnt")

-- Trigger all shrines in the room, force champions
local function TriggerMistake()
    local roomShrines = {}

    for _, shrine in ipairs(REVEL.ENT.CURSED_SHRINE:getInRoom()) do
        if not REVEL.GetData(shrine).Activated then
            roomShrines[#roomShrines+1] = REVEL.GetData(shrine).ShrineType
            REVEL.ActivateShrine(REVEL.GetData(shrine).ShrineType, false, shrine:ToNPC())
        end
    end

    local randomShrine = REVEL.WeightedRandom(GetRemainingShrineWeights(REVEL.GetShrineSetForStage(), roomShrines))
    local randomShrineData = REVEL.Shrines[randomShrine]
    REVEL.DebugToString("Selected random shrine for mistake:", randomShrine)

    REVEL.ActivateShrine(randomShrine, false, nil, true)

    REVEL.AddShrineVanity(REVEL.ShrineBalance.MistakeExtra)

    revel.data.run.madeAMistake[REVEL.GetStageChapter()] = true

    -- StageAPI.PlayTextStreak("You've made a mistake", nil, nil, nil, "gfx/ui/effect_cursepaper.png", Vector(124, 14), REVEL.CurseFont, nil, KColor(0, 0, 0, 1))
    REVEL.game:GetHUD():ShowItemText("You've made a mistake", "+ " .. randomShrineData.DisplayName)

    if REVEL.ShrineTooltip then
        REVEL.ShrineTooltip.Streak.Hold = false
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
    if npc.Variant == REVEL.ENT.CURSED_SHRINE.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    end
end, REVEL.ENT.CURSED_SHRINE.id)

REVEL.ShrineTooltipRadius = 60

local lastCancel = nil

function REVEL.ActivateShrine(shrineType, showMessage, npc, doTriggerEvent, customVanity)
    if doTriggerEvent == nil then doTriggerEvent = true end
    
    local shrineData = REVEL.Shrines[shrineType]

    if npc and shrineData.PreTrigger then
        local cancel = shrineData.PreTrigger(npc)
        if cancel then
            if lastCancel ~= GetPtrHash(npc) then --avoid logspam
                REVEL.DebugStringMinor("Shrine activation canceled:", shrineData.Set, shrineData.Name)
                lastCancel = GetPtrHash(npc)
            end
            return false
        end
    end

    if showMessage then
        StageAPI.PlayTextStreak("Pact of " .. (shrineData.DisplayName or shrineData.Name), nil, nil, nil, "gfx/ui/effect_cursepaper.png", Vector(124, 14), REVEL.CurseFont, nil, KColor(0, 0, 0, 1))
    end

    local rewardValue = (npc and REVEL.GetData(npc).Value) or shrineData.Value or REVEL.ShrineBalance.DefaultPactVanity
    local oneChapterValue = (npc and REVEL.GetData(npc).ValueOneChapter) or shrineData.ValueOneChapter or REVEL.ShrineBalance.DefaultPactVanityOneChapter

    table.insert(revel.data.run.activeShrines, {
        name = shrineType,
        value = rewardValue,
        isOneChapter = REVEL.IsLastChapterStage() or shrineData.AlwaysOneChapter,
        removeStageEnd = shrineData.RemoveOnStageEnd,
        oneChapterValue = oneChapterValue,
    })
    REVEL.UpdateActiveShrineSet()

    customVanity = customVanity or nil
    if customVanity ~= nil then
        rewardValue = customVanity
    end
    REVEL.AddShrineVanity(rewardValue)

    REVEL.DebugToString("Shrine activated:", shrineData.Set, shrineData.Name)

    if npc then
        local data = REVEL.GetData(npc)
        data.IsTriggeredShrine = true
        REVEL.sfx:Play(REVEL.SFX.BUFF_LIGHTNING, 1, 0, false, 1)
        if shrineData.OnTrigger then
            shrineData.OnTrigger(npc)
        end

        if shrineData.CanDoorsOpen then
            data.ShutDoors = true
        end

        local croom = StageAPI.GetCurrentRoom()
        if croom then -- starting rooms are not handled by stageapi
            -- not to be confused with entity persistentdata that just specifies the entity gotta persist
            local persistData = croom.PersistentData
            local grindex = REVEL.room:GetGridIndex(npc.Position)

            persistData.ActivatedShrines = persistData.ActivatedShrines or {}
            persistData.ActivatedShrines[#persistData.ActivatedShrines+1] = grindex
        end

        npc:GetSprite():Play("Buff", true)
        data.Activated = true
    end

    return true
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.CURSED_SHRINE.variant then
        return
    end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if not data.LockPosition then
        if npc.Position.Y > REVEL.room:GetCenterPos().Y + 40 then
            npc.SpriteOffset = Vector(0, 16) * 26 / 40
        elseif npc.Position.Y > REVEL.room:GetCenterPos().Y - 40 then
            npc.SpriteOffset = Vector(0, 16) * 26 / 40
        else 
            npc.SpriteOffset = Vector(0, 8) * 26 / 40
        end
        data.LockPosition = npc.Position
    end
    npc.Position = data.LockPosition

    if not data.Init then
        REVEL.SetupShrines(REVEL.GetShrineSetForStage())

        local croom = StageAPI.GetCurrentRoom()
        -- not to be confused with entity persistentdata that just specifies the entity gotta persist
        local persistData = croom.PersistentData
        local grindex = REVEL.room:GetGridIndex(npc.Position)

        data.Activated = persistData.ActivatedShrines and REVEL.includes(persistData.ActivatedShrines, grindex)
    end

    npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

    if not REVEL.room:GetGridEntityFromPos(npc.Position) then
        REVEL.GRIDENT.INVISIBLE_BLOCK:Spawn(REVEL.room:GetGridIndex(npc.Position), true, false)
    end

    if data.ShutDoors ~= data.PrevShutDoors then
        if data.ShutDoors then
            REVEL.ShutDoors()
        end
        data.PrevShutDoors = data.ShutDoors
    end
    if data.ShutDoors then
        REVEL.room:KeepDoorsClosed()
    end

    if not data.Activated then
        if not sprite:IsPlaying("Shine") then
            sprite:SetFrame("Idle", 0)
        end

        if REVEL.ShrineTooltip and REVEL.ShrineTooltip.Streak.Finished then
            REVEL.ShrineTooltip = nil
        end

        local closePlayer = REVEL.find(REVEL.players, function(player)
            return npc.Position:DistanceSquared(player.Position) < (player.Size + npc.Size + REVEL.ShrineTooltipRadius) ^ 2
        end)

		local hasBadEnemy = false
		for _, enemy in ipairs(REVEL.roomEnemies) do
			if REVEL.CanShutDoors(enemy) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
				hasBadEnemy = true
				break
			end
		end

        if not hasBadEnemy and data.HadBadEnemy then
            sprite:Play("Shine", true)
        end
        data.HadBadEnemy = hasBadEnemy

        local madeMistake = false
        local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION)
        for _, explosion in ipairs(explosions) do
            if explosion.Position:DistanceSquared(npc.Position) < (npc.Size + 60) ^ 2 then
                REVEL.DebugToString("Triggered made a mistake")
                TriggerMistake()
                madeMistake = true
                return
            end
        end

        -- don't activate shrines or tooltips with enemies around
        if not closePlayer or hasBadEnemy then
            if REVEL.ShrineTooltip and GetPtrHash(REVEL.ShrineTooltip.Shrine) == GetPtrHash(npc) then
                REVEL.ShrineTooltip.Streak.Hold = false
            end
            return
        end

        local dist = npc.Position:Distance(closePlayer.Position)

        local activated = dist < closePlayer.Size + npc.Size + 3
        local tooltipActivated = dist < closePlayer.Size + npc.Size + REVEL.ShrineTooltipRadius

        if activated then
            local activateSuccess = false
            if data.ShrineType then
                activateSuccess = REVEL.ActivateShrine(data.ShrineType, not madeMistake, npc)
            end

            if activateSuccess and REVEL.ShrineTooltip and GetPtrHash(REVEL.ShrineTooltip.Shrine) == GetPtrHash(npc) then
                REVEL.ShrineTooltip.Streak.Hold = false
            end
        elseif tooltipActivated then
            if REVEL.ShrineTooltip then
                if GetPtrHash(REVEL.ShrineTooltip.Shrine) == GetPtrHash(npc) then
                    REVEL.ShrineTooltip.Dist = dist
                elseif REVEL.ShrineTooltip.Dist > dist then
                    REVEL.ShrineTooltip.Streak.Hold = false
                    REVEL.ShrineTooltip = nil --remove prev tooltip, take ownership
                end
            end

            if not REVEL.ShrineTooltip then
                local renderPos = StageAPI.GetScreenCenterPosition()

                if npc.Position.Y > REVEL.room:GetCenterPos().Y + 40 then
                    renderPos.Y = renderPos.Y - 64
                else
                    renderPos.Y = renderPos.Y * 2 - 128
                end

                local shrineSet = REVEL.ShrineSets[data.ShrineSet]
                local shrineData = REVEL.Shrines[data.ShrineType]

                data.TextLines = {}
                shrineData.Description:gsub("([^\n]+)", function(c) table.insert(data.TextLines, { Text = c }) end)
                if data.Value > 0 then
                    data.TextLines[#data.TextLines+1] = { Text = ("+%d vanity"):format(data.Value) }
                end
                for _, line in pairs(data.TextLines) do
                    line.Width = PlaqueFont:GetStringWidth(line.Text) / 2
                end

                REVEL.ShrineTooltip = {
                    Shrine = npc,
                    Streak = {
                        RevPlaqueData = data, -- used in callback after
                        Text = "", -- manually rendered for effects
                        TextOffset = Vector(0, 16),
                        LineSpacing = 0.7,
                        Spritesheet = shrineSet.PlaquePath .. (revel.data.shadersOn == 1 and '_sh' or '') .. '.png',
                        SpriteOffset = Vector(98, 14),
                        RenderPos = renderPos,
                        HoldFrames = 0,
                        Font = PlaqueFont,
                        Hold = true
                    },
                    Dist = dist
                }
                REVEL.ShrineTooltip.Streak = StageAPI.PlayTextStreak(REVEL.ShrineTooltip.Streak)
            end
        end
    else
        if sprite:IsFinished("Buff") then
            sprite:SetFrame("Idle", 1)
        end

        -- blank leads to not having data.ShrineType
        if not sprite:IsPlaying("Buff") and data.ShrineType then
            local shrineData = REVEL.Shrines[data.ShrineType]
            if not shrineData.CanDoorsOpen or shrineData.CanDoorsOpen() or not data.IsTriggeredShrine then
                data.ShutDoors = false
                npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                if data.ShrineGfx then
                    sprite:ReplaceSpritesheet(0, data.ShrineGfx)
                end

                if data.ShrineLightning then
                    sprite:ReplaceSpritesheet(1, data.ShrineLightning)
                end

                sprite:LoadGraphics()
            end
            sprite:SetFrame("Idle", 1)
        end
    end
end, REVEL.ENT.CURSED_SHRINE.id)

local doingOutline = false
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, offset)
    if not doingOutline and
    REVEL.ShrineTooltip and not REVEL.ShrineTooltip.Streak.Finished
    and GetPtrHash(REVEL.ShrineTooltip.Shrine) == GetPtrHash(npc) then
        doingOutline = true
        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
        local color = REVEL.CloneColor(sprite.Color)
        sprite.Color = REVEL.GetShrineSet(data.ShrineSet).OutlineColor
        for i = 1, 4 do
            npc:Render(Vector.FromAngle(90 * i) * 1.5 + offset)
        end
        sprite.Color = color
        npc:Render(offset)
        doingOutline = false
    end
end, REVEL.ENT.CURSED_SHRINE.id)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STREAK_RENDER, 1, function(streakPos, streakPlaying)
    if streakPlaying.RevPlaqueData then
        local data = streakPlaying.RevPlaqueData
        local shrineSet = REVEL.ShrineSets[data.ShrineSet]
        local shrineData = REVEL.Shrines[data.ShrineType]

        local screenX = StageAPI.GetScreenCenterPosition().X
        local height = streakPlaying.Font:GetLineHeight() 
            * streakPlaying.LineSpacing * streakPlaying.FontScale.Y

        for i, line in ipairs(data.TextLines) do
            line.PositionX = StageAPI.GetTextStreakPosForFrame(streakPlaying.Frame)
                - line.Width + screenX + 0.25
            streakPlaying.Font:DrawStringScaled(line.Text,
                line.PositionX + streakPlaying.TextOffset.X,
                streakPos.Y - 9 + (i - 1) * height  + streakPlaying.TextOffset.Y + 1,
                streakPlaying.FontScale.X, streakPlaying.FontScale.Y,
                shrineSet.PlaqueTextColors.Light,
                0, true
            )
            streakPlaying.Font:DrawStringScaled(line.Text,
                line.PositionX + streakPlaying.TextOffset.X,
                streakPos.Y - 9 + (i - 1) * height  + streakPlaying.TextOffset.Y,
                streakPlaying.FontScale.X, streakPlaying.FontScale.Y,
                shrineSet.PlaqueTextColors.Base,
                0, true
            )
        end

        local name = shrineData.DisplayName
        local nameOffset = Vector(3, -2)
        local nameScale = 1
        local namePositionX = StageAPI.GetTextStreakPosForFrame(streakPlaying.Frame)
            - streakPlaying.Font:GetStringWidth(name) / 2 + screenX + 0.25

        streakPlaying.Font:DrawStringScaled(name,
            namePositionX + nameOffset.X,
            streakPos.Y - 9 + nameOffset.Y + 1,
            nameScale, nameScale,
            shrineSet.PlaqueTextColors.NameLight,
            0, true
        )
        streakPlaying.Font:DrawStringScaled(name,
            namePositionX + nameOffset.X,
            streakPos.Y - 9 + nameOffset.Y,
            nameScale, nameScale,
            shrineSet.PlaqueTextColors.Name,
            0, true
        )
    end
end)


local lastPlayerPosUpdateRoomID
local setShrineRoomNext = false

local function AddShrineRoomIcon(mroom)
    if mroom and not REVEL.includes(mroom.PermanentIcons, "Shrine Room") then
        table.insert(mroom.PermanentIcons, "Shrine Room")
    end
end

local function shrineMinimapPostMapPosUpdate(room, pos)
    if StageAPI.GetCurrentRoomID() ~= lastPlayerPosUpdateRoomID then
        if setShrineRoomNext then
            AddShrineRoomIcon(MinimapAPI:GetCurrentRoom())
            setShrineRoomNext = false
        end

        lastPlayerPosUpdateRoomID = StageAPI.GetCurrentRoomID()
    end
end

if MinimapAPI then
    MinimapAPI:AddPlayerPositionCallback("Revelations", shrineMinimapPostMapPosUpdate)
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    setShrineRoomNext = false

    if REVEL.ShrineTooltip then
        REVEL.ShrineTooltip.Streak.Hold = false
    end
    REVEL.ShrineTooltip = nil

    if REVEL.ENT.CURSED_SHRINE:countInRoom() > 0 then
        --In case we want compass compatibility this needs to go to NEW_LEVEL somehow
        if REVEL.room:IsFirstVisit() and MinimapAPI then
            if StageAPI.GetCurrentRoomID() == lastPlayerPosUpdateRoomID then
                AddShrineRoomIcon(MinimapAPI:GetCurrentRoom())
            else
                setShrineRoomNext = true
            end
        end

        if REVEL.STAGE.Glacier:IsStage() then
            REVEL.SetupShrines("Glacier")
        elseif REVEL.STAGE.Tomb:IsStage() then
            REVEL.SetupShrines("Tomb")
        end
    end
end)

end