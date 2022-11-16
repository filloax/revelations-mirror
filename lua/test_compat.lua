local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

if not StageAPI.InTestMode then return end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(room, isFirstLoad)
    if not (room.RoomType == RoomType.ROOM_BOSS and StageAPI.InTestRoom()) then return end

    for list, bossList in pairs(REVEL.Bosses) do
        for _, boss in ipairs(bossList) do
            if (Isaac.CountEntities(nil, boss.Entity.Type, boss.Entity.Variant or -1, boss.Entity.SubType or -1) or 0) > 0 then
                StageAPI.SetCurrentBossRoomInPlace(boss.Name, room)
                return
            end
        end
    end
end)

end