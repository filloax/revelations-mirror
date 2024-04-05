local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")

-- BOSS HALL --

local ForceNextBossShapes = nil
local ForceNextRoomDifficulty = nil

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CHECK_VALID_ROOM, 0, function(layout)
    -- champion state checked in revel1/entities.lua

    if ForceNextBossShapes and not ForceNextBossShapes[layout.Shape] then
        return false
    end

    if ForceNextRoomDifficulty then
        local useDifficulty = layout.Difficulty
        if useDifficulty > 3 then
            useDifficulty = useDifficulty / 5
        end

        if (ForceNextRoomDifficulty > 0 and useDifficulty ~= ForceNextRoomDifficulty) or (ForceNextRoomDifficulty < 0 and useDifficulty == -ForceNextRoomDifficulty) then
            return false
        end
    end
end)

local LoadingBossFromMenu = nil
local function LoadBossFromMenu(_, menu)
    local boss
    for chapter, bosses in pairs(REVEL.Bosses) do
        for _, bossdata in ipairs(bosses) do
            if string.lower(bossdata.Name) == menu.title then
                boss = bossdata
            end
        end
    end

    local stage
    if type(boss.Stage) ~= "table" then
        stage = REVEL.STAGE[boss.Stage]
    else
        stage = boss.Stage
    end

    StageAPI.GotoCustomStage(stage, false, false)

    REVEL.ForceNextChampion = nil
    REVEL.ForceNextRuthless = nil
    ForceNextRoomDifficulty = nil

    local roomDifficulty
    for _, button in ipairs(menu.buttons) do
        if button.str == 'variant' then
            local selected = button.choices[button.setting]
            if selected ~= "champion" then
                REVEL.ForceNextChampion = false
                if selected == "ruthless" then
                    REVEL.ForceNextRuthless = true
                end
            else
                REVEL.ForceNextChampion = true
            end
        elseif button.str == "rooms" then
            local selected = button.choices[button.setting]
            if selected ~= "all" then
                if selected == "basic" then
                    ForceNextRoomDifficulty = 1
                elseif selected == "except basic" then
                    ForceNextRoomDifficulty = -1
                elseif selected == "tricky" then
                    ForceNextRoomDifficulty = 3
                elseif selected == "except tricky" then
                    ForceNextRoomDifficulty = -3
                end
            end
        elseif button.str == 'items' then
            if button.setting == 2 then
                REVEL.player:AddCollectible(CollectibleType.COLLECTIBLE_SAD_ONION, 0, false)
                if REVEL.level:GetStage() > LevelStage.STAGE1_2 and not REVEL.STAGE.Glacier:IsStage() then
                    REVEL.player:AddCollectible(CollectibleType.COLLECTIBLE_MEAT, 0, false)
                end
            end
        end
    end

    if boss.Shapes then
        ForceNextBossShapes = {}
        for _, shape in ipairs(boss.Shapes) do
            ForceNextBossShapes[shape] = true
        end
    else
        ForceNextBossShapes = nil
    end

    if boss.Mirror then
        local mirrorRoom = StageAPI.LevelRoom("MirrorRoom", nil, REVEL.room:GetSpawnSeed(), RoomShape.ROOMSHAPE_1x1, RoomType.ROOM_DEFAULT, true)
        mirrorRoom.TypeOverride = "Mirror"
        local roomData = StageAPI.GetDefaultLevelMap():AddRoom(mirrorRoom, {RoomID = "RevelationsBossHall"})

        StageAPI.ExtraRoomTransition(roomData.MapID, nil, RoomTransitionAnim.FADE, StageAPI.DefaultLevelMapID, mirrorRoom.Layout.Doors[StageAPI.Random(1, #mirrorRoom.Layout.Doors)].Slot)
    else
        local bossRoom = StageAPI.GenerateBossRoom(boss.Name, nil, nil, nil, nil, 2, nil, true, -1, true)
        local doors = {}
        for _, door in ipairs(bossRoom.Layout.Doors) do
            if door.Exists then
                doors[#doors + 1] = door.Slot
            end
        end
        
        local roomData = StageAPI.GetDefaultLevelMap():AddRoom(bossRoom, {RoomID = "RevelationsBossHall"})

        if boss.IsMiniboss then
            bossRoom.RoomType = RoomType.ROOM_DEFAULT
        else
            bossRoom.RoomType = RoomType.ROOM_BOSS
        end
        
        StageAPI.ExtraRoomTransition(roomData.MapID, nil, RoomTransitionAnim.FADE, StageAPI.DefaultLevelMapID, doors[StageAPI.Random(1, #doors)])

        if not boss.IsMiniboss then
            LoadingBossFromMenu = boss
        end
    end

    ForceNextBossShapes = nil
    ForceNextRoomDifficulty = nil
end

local function ChangeBossVariant(variantButton, item)
    for _, button in ipairs(item.buttons) do
        if button.str == "rooms" then
            local currentSelection = button.choices[button.setting]
            if variantButton.choices[variantButton.setting] == "normal" then
                button.choices = button.normalChoices
            else
                button.choices = button.champChoices
            end

            local selectionIndex = 1
            for i, choice in ipairs(button.choices) do
                if choice == currentSelection then
                    selectionIndex = i
                end
            end

            button.setting = selectionIndex
        end
    end
end

local bossHallCharacters = {
    {"isaac", "0"}, 
    {"cain", "2"}, 
    {"lazarus", "8"}, 
    {"forgotten", "16", {"the", "forgotten"}}, 
    {"lost", "10", {"the", "lost"}}
}
local bossHallCharacterButton = {
    spr = {width = 48, height = 48}, 
    character = "isaac", 
    tooltip = {strset = {"isaac"}, fsize = 2}, 
    colorselect = true, 
    usemenuclr = true, 
    usecolorize = true, 
    palcolor = 1, 
    fullrow = true
}
for i, character in ipairs(bossHallCharacters) do
    local sprite = Sprite()
    sprite:Load("gfx/ui/bestiary/revel1/characters/character_icon.anm2", true)
    if character[1] ~= "isaac" then
        sprite:ReplaceSpritesheet(0, "gfx/ui/bestiary/revel1/characters/" .. character[1] .. ".png")
        sprite:LoadGraphics()
    end

    sprite:SetFrame("Idle", 0)
    if bossHallCharacterButton.character == character[1] then
        bossHallCharacterButton.spr.sprite = sprite
    end

    bossHallCharacters[character[1]] = sprite
end

function bossHallCharacterButton.func(characterbutton)
    local charindex
    for i, character in ipairs(bossHallCharacters) do
        if character[1] == characterbutton.character then
            charindex = i
            break
        end
    end

    charindex = (charindex % #bossHallCharacters) + 1
    characterbutton.character = bossHallCharacters[charindex][1]
    characterbutton.tooltip = {
        strset = bossHallCharacters[charindex][3] or {bossHallCharacters[charindex][1]},
        fsize = 2
    }
    characterbutton.spr.sprite = bossHallCharacters[characterbutton.character]
end

function bossHallCharacterButton.changefunc(characterbutton)
    local playerType = REVEL.player:GetPlayerType()
    local characterData
    for _, character in ipairs(bossHallCharacters) do
        if character[1] == characterbutton.character then
            characterData = character
            break
        end
    end

    if playerType ~= tonumber(characterData[2]) then
        Isaac.ExecuteCommand("restart " .. characterData[2])
    end
end

local bossBestiarySprites = {}

local function AddBossMenus(revdirectory, item, bosses, bestiaryprefix, championachieve, header, buffer, characterpicker, encounteredlist)
    if header then
        item.buttons[#item.buttons + 1] = {str = header, fsize = 2, nosel = true, fullrow = true}
    end

    if characterpicker then
        item.buttons[#item.buttons + 1] = bossHallCharacterButton
    end

    if bosses then
        for _, boss in ipairs(bosses) do
            local button
            local encountered = (encounteredlist == true or (encounteredlist ~= nil and encounteredlist[boss.Name])) or revel.data.BossesEncountered[boss.Name] or REVEL.Testmode

            if boss.Bestiary then
                local sprite = bossBestiarySprites[boss.Bestiary]
                if not sprite then
                    sprite = Sprite()
                    sprite:Load("gfx/ui/bestiary/bestiary_icon.anm2", true)

                    if encountered then
                        sprite:ReplaceSpritesheet(0, bestiaryprefix .. boss.Bestiary)
                    else
                        sprite:ReplaceSpritesheet(0, bestiaryprefix .. "boss_shadows/" .. boss.Bestiary)
                    end

                    sprite:LoadGraphics()
                    sprite:SetFrame("Idle", 0)
                    bossBestiarySprites[boss.Bestiary] = sprite
                end

                button = {spr = {sprite = sprite, width = 64, height = 48}, colorselect = true, usemenuclr = true, usecolorize = true, palcolor = 1}
            else
                button = {strset = {}, colorselect = true, halign = 1}
            end

            local strset = {}
            for word in boss.Name:gmatch("%S+") do strset[#strset + 1] = string.lower(word) end

            if encountered then
                button.tooltip = {strset = strset, fsize = 2}
            else
                button.tooltip = revdirectory.bosses.tooltip
            end

            if not revel.data.RuthlessMenuUnlocked then
                button.tooltip.hintletter = "r"
                revdirectory.bosses.tooltip.hintletter = "r"
            else
                button.tooltip.hintletter = nil
                revdirectory.bosses.tooltip.hintletter = nil
            end

            if button.strset then
                button.strset = strset
            end

            local bossmenu = {
                title = string.lower(boss.Name),
                buttons = {
                    {str = 'items', choices = {'off', 'on'}, setting = 1},
                    {str = 'fight!', action = 'resume', func = LoadBossFromMenu}
                },
                tooltip = REVEL.DSS.DSSMod.menuOpenToolTip,
            }

            if boss.Rooms then
                local normalChoices = {'all'}
                local champChoices = {'all'}
                local hasBasic, hasTricky, champHasBasic, champHasTricky
                for _, room in ipairs(boss.Rooms.All) do
                    local championizers = StageAPI.CountLayoutEntities(room, {{Type = 789, Variant = 91}})
                    local nochampions = StageAPI.CountLayoutEntities(room, {{Type = 789, Variant = 92}})
                    if room.Difficulty == 1 then
                        if championizers == 0 then
                            hasBasic = true
                        end

                        if nochampions == 0 then
                            champHasBasic = true
                        end
                    elseif room.Difficulty == 3 then
                        if championizers == 0 then
                            hasTricky = true
                        end

                        if nochampions == 0 then
                            champHasTricky = true
                        end
                    end
                end

                if hasBasic then
                    normalChoices[#normalChoices + 1] = "basic"
                    normalChoices[#normalChoices + 1] = "except basic"
                end

                if champHasBasic then
                    champChoices[#champChoices + 1] = "basic"
                    champChoices[#champChoices + 1] = "except basic"
                end

                if hasTricky then
                    normalChoices[#normalChoices + 1] = "tricky"
                    normalChoices[#normalChoices + 1] = "except tricky"
                end

                if champHasTricky then
                    champChoices[#champChoices + 1] = "tricky"
                    champChoices[#champChoices + 1] = "except tricky"
                end

                table.insert(bossmenu.buttons, 1, {str = 'rooms', choices = normalChoices, normalChoices = normalChoices, champChoices = champChoices, setting = 1})
            end

            if boss.Variants then
                table.insert(bossmenu.buttons, 1, {str = 'variant', choices = {}, setting = 1, changefunc = ChangeBossVariant})
                for _, variant in ipairs(boss.Variants) do
                    local pass = true
                    if variant == "Champion" then
                        pass = not championachieve or REVEL.IsAchievementUnlocked(boss.ChampionAchievement or championachieve) or REVEL.Testmode
                    elseif variant == "Ruthless" then
                        pass = revel.data.RuthlessMenuUnlocked or REVEL.Testmode
                    end

                    if pass then
                        bossmenu.buttons[1].choices[#bossmenu.buttons[1].choices + 1] = string.lower(variant)
                    end
                end
            end

            --[[
            if boss.BestiarySprite then
                local sprite = Sprite()
                sprite:Load(boss.BestiarySprite.File, true)
                sprite:SetFrame(boss.BestiarySprite.Anim, boss.BestiarySprite.Frame)
                table.insert(bossmenu.buttons, 1, {spr = {sprite = sprite, width = boss.BestiarySprite.Width, height = boss.BestiarySprite.Height, centery = true}, nosel = true})
            end]]

            revdirectory[string.lower(boss.Name)] = bossmenu

            if encountered then
                button.dest = string.lower(boss.Name)
            end

            item.buttons[#item.buttons + 1] = button
        end
    end

    if buffer then
        item.buttons[#item.buttons + 1] = {str = "", fsize = 1, nosel = true, fullrow = true}
    end
end

local bossHallChallenge = Isaac.GetChallengeIdByName("Rev Boss Practice")
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if LoadingBossFromMenu then
        StageAPI.PlayBossAnimation(LoadingBossFromMenu)
        LoadingBossFromMenu = nil
    end

    for chapter, bosses in pairs(REVEL.Bosses) do
        for _, boss in ipairs(bosses) do
            if not revel.data.BossesEncountered[boss.Name] and StageAPI.GetBossEncountered(boss.Name) then
                revel.data.BossesEncountered[boss.Name] = true
            end
        end
    end

    for boss, beaten in pairs(revel.data.BossesBeaten) do
        if not revel.data.BossesEncountered[boss] and beaten then
            revel.data.BossesEncountered[boss] = true
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if Isaac.GetChallenge() == bossHallChallenge then
        DeadSeaScrollsMenu.OpenMenuToPath("Revelations", "bosses", nil, true)
    else
        -- FIRST TIME PLAYING WARNING
        if not revel.data.firstRunWarning then
            -- open rev to the info page, then enter the main page once it is closed
            DeadSeaScrollsMenu.QueueMenuOpen("Revelations", "info", 50)
            DeadSeaScrollsMenu.QueueMenuOpen("Revelations", "main", 49)
    		revel.data.firstRunWarning = true
    	end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_CURSE_EVAL, function()
    if Isaac.GetChallenge() == bossHallChallenge then
        return LevelCurse.CURSE_OF_THE_LOST
    end
end)

local holdRTime = 0
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if Isaac.GetChallenge() == bossHallChallenge then
        if REVEL.room:IsClear() and REVEL.level:GetCurrentRoomIndex() ~= REVEL.level:GetStartingRoomIndex() and REVEL.room:GetFrameCount() > 30 * 10 then
            REVEL.game:FinishChallenge()
        end

        if not revel.data.RuthlessMenuUnlocked then
            if Input.IsButtonPressed(Keyboard.KEY_R, REVEL.player.ControllerIndex) then
                holdRTime = holdRTime + 1
            else
                holdRTime = 0
            end

            if holdRTime > 60 * 10 then
                revel.data.RuthlessMenuUnlocked = true
                REVEL.PlaySound(SoundEffect.SOUND_SATAN_APPEAR)
                DeadSeaScrollsMenu.OpenMenuToPath("Revelations", "bosses", nil, true)
            end
        end
    end
end)

return {
    AddBossMenus = AddBossMenus
}