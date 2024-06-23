local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local Dimension         = require("scripts.revelations.common.enums.Dimension")

local Minimap           = REVEL.Module("scripts.revelations.common.library.minimap")

return function()

-- Charon Map rework, now mostly moved to minimap.lua library

local MAP_KEY_CHARON = "Charon"
local MAP_KEY_DANTE = "Dante"


-- If, when playing as D&C, the other character 
-- has cleared this room
function REVEL.Dante.IsOtherRoomCleared(listIndex)
    listIndex = listIndex or StageAPI.GetCurrentRoomID()

    -- in general, original roomdesc clear stays true even if minimap is changed

    if type(listIndex) == "number" then -- normal listindex
        return REVEL.level:GetRooms():Get(listIndex).Clear
    else --stageapi custom room
        local levelRoom = StageAPI.GetLevelRoom(listIndex)
        return levelRoom and levelRoom.RoomDescriptor.Clear
    end
end


-- For debug
function REVEL.Dante.PrintMapDisplayData()
    Minimap.PrintMapDisplayData()
end

---@param changingToDante boolean
function REVEL.Dante.SwitchMap(changingToDante)
    local thisMinimap = changingToDante and MAP_KEY_DANTE or MAP_KEY_CHARON
    local otherMinimap = changingToDante and MAP_KEY_CHARON or MAP_KEY_DANTE

    local thisLevelRoomDisplayData
    if REVEL.DEBUG then
        thisLevelRoomDisplayData = Minimap.GetCurrentLevelRoomsDisplayData()
    end
    Minimap.StoreMinimapData(otherMinimap)
    Minimap.LoadMinimapData(thisMinimap)
    if REVEL.DEBUG then
        REVEL.DebugToString("Dante | Old map display data:")
        Minimap.PrintMapDisplayData(thisLevelRoomDisplayData)
        REVEL.DebugToString("Dante | New map display data:")
        Minimap.PrintMapDisplayData()
    end
end

---@param startsFromDante boolean
function REVEL.Dante.MergeMap(startsFromDante)
    local otherMinimap = startsFromDante and MAP_KEY_CHARON or MAP_KEY_DANTE

    Minimap.LoadMinimapData(otherMinimap, true, true)
end

end