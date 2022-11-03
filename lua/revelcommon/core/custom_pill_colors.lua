local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    -- Custom pill colors
    --[[
        To allow creation of custom pill colors that both replace 
        the room pickup, and the player UI slot
        Each custom color has an ID (arbitrary, string or number), 
        which is registered to be associated to a pill anm2 with the

        REVEL.CustomPill(colorId, anm2)

        function, defined in basiccore.lua as it's used in the definitions file.
        Right now, they are only skins, the effect is the same as the
        base pill color. They can be spawned with

        REVEL.ConvertPillToCustom(pill, colorId)
        REVEL.SpawnCustomPill(colorId, pos, vel, spawner, baseColor)

        and baseColor is used for the effect (if nil, it's random).
    ]]
    -- TODO: the UI rendering part, requires replacing pill anm2s
    -- with blank ones and reimplementing the rendering for various coop
    -- positions

    local function SaveCustomPillRoomData(pill, saveIndex)
        local data = pill:GetData()

        if data.CustomPill then
            local listIndex = tostring(StageAPI.GetCurrentRoomID())
            if not revel.data.run.level.customPillsInRoom[listIndex] then
                revel.data.run.level.customPillsInRoom[listIndex] = {}
            end
            local customPillTbl = revel.data.run.level.customPillsInRoom[listIndex]

            local existingIdx = saveIndex or REVEL.findKey(customPillTbl, function(entry) return GetPtrHash(pill) == entry.Hash end)
            local thisEntry

            if not existingIdx then
                thisEntry = {}
                customPillTbl[#customPillTbl + 1] = thisEntry
            else
                thisEntry = customPillTbl[existingIdx]
            end

            thisEntry.GridIndex = REVEL.room:GetGridIndex(pill.Position) --used to restore on room re-entry
            thisEntry.Hash = GetPtrHash(pill) --used to save in same slot in this function
            thisEntry.BaseColor = pill.SubType --used to restore on room re-entry
            thisEntry.CustomColor = data.CustomPillColor
        end
    end

    local function ClearCustomPillRoomData(pill, saveIndex)
        local data = pill:GetData()

        if data.CustomPill then
            local listIndex = tostring(StageAPI.GetCurrentRoomID())
            if not revel.data.run.level.customPillsInRoom[listIndex] then
                return
            end
            local customPillTbl = revel.data.run.level.customPillsInRoom[listIndex]

            local existingIdx = saveIndex or REVEL.findKey(customPillTbl, function(entry) return GetPtrHash(pill) == entry.Hash end)

            if not existingIdx then
                return
            else
                table.remove(customPillTbl, existingIdx)
            end
        end
    end

    -- local cardEntry, activeEntry = {"Card"}, {"Active"} --optimization?

    local function TrackPlayerPocketInventory(player)
        local data = player:GetData()

        -- means it won't decrease if extra pocket items are removed, but w/e
        -- we loop with GetMaxPocketItems either way
        -- local currentPocketItems = data.CustomPillsPocketInventory or {} 
        local pocketActive1 = player:GetActiveItem(ActiveSlot.SLOT_POCKET)
        local pocketActive2 = player:GetActiveItem(ActiveSlot.SLOT_POCKET2)
        local activesToCheck = (pocketActive1 > 0 and 1 or 0) + (pocketActive2 > 0 and 1 or 0)
        local held = player:GetMaxPocketItems()
        local pillSlots = {}
        local firstFreeSlot

        for i = 0, player:GetMaxPocketItems() - 1 do
            if player:GetCard(i) > 0 then
                -- currentPocketItems[i] = cardEntry
            elseif player:GetPill(i) > 0 then
                -- currentPocketItems[i] = {"Pill", player:GetPill(i)} --we only need the type for pills
                pillSlots[#pillSlots + 1] = i
            elseif pocketActive1 > 0 or pocketActive2 > 0 and activesToCheck > 0 then
                -- currentPocketItems[i] = activeEntry
                activesToCheck = activesToCheck - 1
            else
                held = held - 1
                if not firstFreeSlot then
                    firstFreeSlot = i
                end
            end
        end

        return held, pillSlots, firstFreeSlot --, currentPocketItems
    end

    local function CheckDroppedPills(player, droppedPills)
        if type(droppedPills) ~= "table" then droppedPills = {droppedPills} end

        if REVEL.DEBUG then
            REVEL.DebugLog("Checking dropped pills:", droppedPills)
        end

        local data = player:GetData()

        -- New pill isn't spawned yet, so add player data tag that will be checked 
        -- by pill
        if data.JustDroppedCustomPills then
            data.JustDroppedCustomPills = REVEL.concat(data.JustDroppedCustomPills, table.unpack(droppedPills))
        else
            data.JustDroppedCustomPills = droppedPills
            data.JustDroppedCustomPillsTimer = 2
        end
    end

    local function AddCustomPillPlayerData(player, colorId, baseColor)
        local data = player:GetData()

        local entry = {
            CustomColor = colorId,
            BaseColor = baseColor,
        }

        --[[
        How pocket items move when you pick up a pill
        1. the first pill gets added to slot 0
        2. if you have 1 max pill and no pocket item: 
           if there is a pill in slot 0, it's dropped
        3. if you have 2 max pills and no pocket item:
           if there is a pill in slot 1 it stays there
           and any pills in slot 0 are moved to slot 1,
           if there is a pill in slot 0 but not slot 1 
           it gets moved to slot 1
        4. 2 max pills, pocket item in last slot: same as (2)
        5. 2 max pills, pocket item in slot 1: same as 
           (2) except instead of slot 1, pills go to slot 2
        6. 2 max pills, pocket item in slot 0:
            if both pill slots are full, pocket item gets 
            moved to slot 1, pill in slot 1 is dropped, new
            pill is added to slot 0;
            if there is only a pill in slot 1, it gets moved to 
            slot 2, new pill is in slot 0, item to slot 1

        Can't be arsed to rewrite but everything about pills above
        applies to cards too
        ]]
        
        local playerID = REVEL.GetPlayerID(player)

        -- If had any custom pills before, else there's no need
        -- to do any moving around of data
        if data.HasCustomPills then
            local curPillSlot1 = data.CustomPillsCurPillSlots[1]
            local sslot1 = tostring(curPillSlot1)

            -- Pills in slot 2 are unaffected, if any, so we only need
            -- to do stuff if we have custom pills in the first slot
            if revel.data.run.playerCustomPills[playerID][sslot1] then
                -- If there is a free slot, previous first pill goes there
                if data.CustomPillsFirstFreeSlot then
                    revel.data.run.playerCustomPills[playerID][tostring(data.CustomPillsFirstFreeSlot)] = 
                        revel.data.run.playerCustomPills[playerID][sslot1]
                -- If there isn't, this pill gets dropped
                else
                    CheckDroppedPills(player, revel.data.run.playerCustomPills[playerID][sslot1])
                    revel.data.run.playerCustomPills[playerID][sslot1] = nil
                end
            end
        end


        revel.data.run.playerCustomPills[playerID]['0'] = entry
        data.HasCustomPills = true
    end

    local function UpdateCustomPillPlayerData(player)
        local data = player:GetData()
        local maxPocketItems = player:GetMaxPocketItems()
        local newData = {}
        local checkDropped = {}

        for sslot, entry in pairs(revel.data.run.playerCustomPills[REVEL.GetPlayerID(player)]) do
            local slot = tonumber(sslot)
            local slotPill = player:GetPill(slot)

            -- Matching, do not alter
            if slotPill == entry.BaseColor then
                newData[sslot] = entry

            -- Not found, search another or remove starting from next slot
            else
                local found = false

                for slotOffset = 0, maxPocketItems - 1 do
                    local slot2 = (slot + 1 + slotOffset) % maxPocketItems -- start from next slot
                    local slotPill2 = player:GetPill(slot2)
                    if not newData[slot2] and slotPill2 == entry.BaseColor then
                        local sslot2 = tostring(slot2)
                        newData[sslot2] = entry
                        found = true
                        break
                    end
                end

                if not found then
                    checkDropped[#checkDropped+1] = entry
                end
            end
        end

        local playerID = REVEL.GetPlayerID(player)
        revel.data.run.playerCustomPills[playerID] = newData

        if not next(newData) then
            data.HasCustomPills = false
        end

        if #checkDropped > 0 then
            CheckDroppedPills(player, checkDropped)
        end
    end

    -- Convert a vanilla pill to a custom pill color, 
    -- keeping the effect
    -- * customColor: either color id or table set in definitions
    function REVEL.ConvertPillToCustom(pill, customColor, saveIndex)
        local data, sprite = pill:GetData(), pill:GetSprite()
        local entry, colorId

        if type(customColor) == "table" then
            entry = customColor
            colorId = customColor.ColorId
        else
            colorId = customColor
            if not REVEL.CUSTOM_PILLS_BY_ID[colorId] then
                error("Custom pill color '" .. tostring(colorId) .. "' doesn't exist!")
            end
            entry = REVEL.CUSTOM_PILLS_BY_ID[colorId]
        end

        local anim, frame = sprite:GetAnimation(), sprite:GetFrame()
        sprite:Load(entry.Anm2, true)
        sprite:Play(anim, true)
        sprite:SetFrame(frame)

        data.CustomPill = true
        data.CustomPillColor = colorId
        data.PrevPosition = pill.Position

        SaveCustomPillRoomData(pill, saveIndex)
    end

    -- Spawn a pill with the specified custom color
    -- * customColor: either color id or table set in definitions
    -- * baseColor: needed for effect, random if unspecified
    function REVEL.SpawnCustomPill(customColor, pos, vel, spawner, baseColor)
        local pill = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, baseColor or 0, pos, vel, spawner)
        REVEL.ConvertPillToCustom(pill, customColor)
        return pill
    end

    local function custompillsPostPickupInit(pill)
        local done = false
        for _, player in ipairs(REVEL.players) do
            local data = player:GetData()
            if data.JustDroppedCustomPills then
                for i, droppedPillData in ripairs(data.JustDroppedCustomPills) do
                    if droppedPillData.BaseColor == pill.SubType then
                        REVEL.ConvertPillToCustom(pill, droppedPillData.CustomColor)
                        table.remove(data.JustDroppedCustomPills, i)
                        done = true
                        break
                    end
                end

                if done then
                    break
                end
            end
        end
    end

    local function custompillsPostPickupUpdate(_, pill)
        local sprite, data = pill:GetSprite(), pill:GetData()

        if data.CustomPill then
            if REVEL.room:GetGridIndex(data.PrevPosition) ~= REVEL.room:GetGridIndex(pill.Position) then
                SaveCustomPillRoomData(pill)
                data.PrevPosition = pill.Position
            end
        end
    end

    local function custompillsPostPickupCollect(pickup, player, isPocket)
        if not isPocket then return end

        local data, pdata = pickup:GetData(), player:GetData()
        if data.CustomPill then
            ClearCustomPillRoomData(pickup)
            AddCustomPillPlayerData(player, data.CustomPillColor, pickup.SubType)
        end

        if pdata.HasCustomPills then
            UpdateCustomPillPlayerData(player)
        end
    end

    local function custompillsNewRoom()
        local listIndex = tostring(StageAPI.GetCurrentRoomID())

        if revel.data.run.level.customPillsInRoom[listIndex] then
            local pills = Isaac.FindByType(5, PickupVariant.PICKUP_PILL)
            for i, entry in ripairs(revel.data.run.level.customPillsInRoom[listIndex]) do
                local found = false
                for _, pill in ipairs(pills) do
                    if not pill:GetData().CustomPill and pill.SubType == entry.BaseColor 
                    and REVEL.room:GetGridIndex(pill.Position) == entry.GridIndex then
                        REVEL.ConvertPillToCustom(pill, entry.CustomColor, i)
                        found = true
                        break
                    end
                end

                if not found then
                    table.remove(revel.data.run.level.customPillsInRoom[listIndex], i)
                end
            end
        end
    end

    local function custompillsPostPeffectUpdate(_, player)
        local data = player:GetData()

        if data.HasCustomPills then
            local held, pillSlots, firstFreeSlot = TrackPlayerPocketInventory(player)
            -- data.CustomPillsPocketInventory = currentPocketItems
            data.CustomPillsHeldPocketItems = held
            data.CustomPillsCurPillSlots = pillSlots
            data.CustomPillsFirstFreeSlot = firstFreeSlot

        elseif data.CustomPillsHeldPocketItems then
            data.CustomPillsHeldPocketItems = nil
            data.CustomPillsCurPillSlots = nil
            data.CustomPillsFirstFreeSlot = nil
            data.PrevHeldItems = nil
        end

        if Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
        or (data.PrevMaxPocketItems and player:GetMaxPocketItems() ~= data.PrevMaxPocketItems)
        or (data.PrevHeldItems and data.CustomPillsHeldPocketItems < data.PrevHeldItems) then
            UpdateCustomPillPlayerData(player)
        end

        data.PrevMaxPocketItems = player:GetMaxPocketItems()
        data.PrevHeldItems = data.CustomPillsHeldPocketItems
        
        if data.JustDroppedCustomPillsTimer then
            data.JustDroppedCustomPillsTimer = data.JustDroppedCustomPillsTimer - 1
            if data.JustDroppedCustomPillsTimer <= 0 then
                data.JustDroppedCustomPillsTimer = nil
                data.JustDroppedCustomPills = nil
            end
        end
    end

    StageAPI.AddCallback("Revelations", RevCallbacks.PICKUP_UPDATE_INIT, 1, custompillsPostPickupInit, PickupVariant.PICKUP_PILL)
    revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, custompillsPostPickupUpdate, PickupVariant.PICKUP_PILL)
    StageAPI.AddCallback("Revelations", RevCallbacks.POST_PICKUP_COLLECT, 1, custompillsPostPickupCollect)
    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, custompillsNewRoom)
    revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, custompillsPostPeffectUpdate)
end

REVEL.PcallWorkaroundBreakFunction()