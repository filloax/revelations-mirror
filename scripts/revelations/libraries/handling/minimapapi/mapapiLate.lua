-- Code that depends on other revelations content

return function ()


function REVEL.LoadMinimapAPICompat()
    local revIcons = Sprite()
    revIcons:Load("gfx/ui/rev_custom_icons.anm2", true)
    MinimapAPI:AddIcon("Shrine Room", revIcons, "Shrines", 0)
    MinimapAPI:AddIcon("Mirror Entrance", revIcons, "MirrorEntrance", 0)
    MinimapAPI:AddIcon("Mirror Room", revIcons, "MirrorRoom", 0)
    MinimapAPI:AddIcon("Mirror Room Locked", revIcons, "MirrorRoomLocked", 0)

    local mirrorMapIcons = Sprite()
    mirrorMapIcons:Load("gfx/ui/mirror_room_icon.anm2", true)
    local mirrorMapIconsLarge = Sprite()
    mirrorMapIconsLarge:Load("gfx/ui/mirror_room_icon_big.anm2", true)

    for dir = 0, 3 do
        local shape = "MirrorRoom" .. REVEL.dirToString[dir]
        MinimapAPI.RoomShapeFrames[shape] = {
            small = {
                ["RoomUnvisited"] = {sprite = mirrorMapIcons,anim = "RoomUnvisited",frame = dir},
                ["RoomVisited"] = {sprite = mirrorMapIcons,anim = "RoomVisited",frame = dir},
                ["RoomSemivisited"] = {sprite = mirrorMapIcons,anim = "RoomUnvisited",frame = dir},
                ["RoomCurrent"] = {sprite = mirrorMapIcons,anim = "RoomCurrent",frame = dir},
            },
            large = {
                ["RoomUnvisited"] = {sprite = mirrorMapIconsLarge,anim = "RoomUnvisited",frame = dir},
                ["RoomVisited"] = {sprite = mirrorMapIconsLarge,anim = "RoomVisited",frame = dir},
                ["RoomSemivisited"] = {sprite = mirrorMapIconsLarge,anim = "RoomUnvisited",frame = dir},
                ["RoomCurrent"] = {sprite = mirrorMapIconsLarge,anim = "RoomCurrent",frame = dir},
            },
        }
        
        local function addDir(vec) 
            if dir == 0 or dir == 2 then
            return vec + REVEL.dirToVel[dir] * 0.1 
            else
            return vec + REVEL.dirToVel[dir] * 0.025 
            end
        end

        MinimapAPI.RoomShapeGridPivots[shape] = Vector(0,0)
        MinimapAPI.RoomShapeGridSizes[shape] = Vector(1,1)
        MinimapAPI.RoomShapePositions[shape] = {Vector(0,0)}

        MinimapAPI.RoomShapeIconPositions[1][shape] = REVEL.map(MinimapAPI.RoomShapeIconPositions[1][RoomShape.ROOMSHAPE_1x1], addDir)
        MinimapAPI.RoomShapeIconPositions[2][shape] = REVEL.map(MinimapAPI.RoomShapeIconPositions[2][RoomShape.ROOMSHAPE_1x1], addDir)

        MinimapAPI.LargeRoomShapeIconPositions[1][shape] = REVEL.map(MinimapAPI.LargeRoomShapeIconPositions[1][RoomShape.ROOMSHAPE_1x1], addDir)
        MinimapAPI.LargeRoomShapeIconPositions[2][shape] = REVEL.map(MinimapAPI.LargeRoomShapeIconPositions[2][RoomShape.ROOMSHAPE_1x1], addDir)
        MinimapAPI.LargeRoomShapeIconPositions[3][shape] = REVEL.map(MinimapAPI.LargeRoomShapeIconPositions[3][RoomShape.ROOMSHAPE_1x1], addDir)
        MinimapAPI.RoomShapeAdjacentCoords[shape] = MinimapAPI.RoomShapeAdjacentCoords[RoomShape.ROOMSHAPE_1x1]
        MinimapAPI.RoomShapeDoorCoords[shape] = MinimapAPI.RoomShapeDoorCoords[RoomShape.ROOMSHAPE_1x1]
        MinimapAPI.RoomShapeDoorSlots[shape] = MinimapAPI.RoomShapeDoorSlots[RoomShape.ROOMSHAPE_1x1]
    end

    REVEL.MinimapAPICompatLoaded = true
end

if MinimapAPI then
    REVEL.LoadMinimapAPICompat()
else
    revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, function()
        if MinimapAPI and not REVEL.MinimapAPICompatLoaded then
            REVEL.LoadMinimapAPICompat()
        end
    end)
end


end