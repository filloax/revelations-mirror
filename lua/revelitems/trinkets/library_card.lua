REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
------------------
-- LIBRARY CARD --
------------------
-- unlocks all library doors if the player has the library card trinket

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local room = REVEL.room
    if REVEL.OnePlayerHasTrinket(REVEL.ITEM.LIBRARY_CARD.id) then
        for i=0, 8 do
            local door = room:GetDoor(i)
            if door ~= nil and door.TargetRoomType == RoomType.ROOM_LIBRARY and door:IsLocked() and room:IsClear() then
                door:TryUnlock(true)
            end
        end
    end
end)

end