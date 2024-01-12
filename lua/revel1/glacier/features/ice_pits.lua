local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

return function()

local FragilityIceSpawnRNG = REVEL.RNG()

function REVEL.LoadIcePits(frames, fragileFrames)
    for strindex, frame in pairs(frames) do
        local index = tonumber(strindex)
        for i = 1, 2 do
            local e = Isaac.Spawn(StageAPI.E.GenericEffect.T, StageAPI.E.GenericEffect.V, 0, REVEL.room:GetGridPosition(index) + Vector(2, 3), Vector.Zero, nil)
            local spr = e:GetSprite()
            if i == 1 then
                spr:Load("stageapi/pit.anm2", false)
                spr:SetFrame("pit", frame)
                e:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
            else
                spr:Load("gfx/grid/grid_pit_water.anm2", true)
                spr:Play("highlights", true)
                spr.PlaybackSpeed = math.random() + 0.5
            end
            e:GetData().IcePit = true

            local currentRoom = StageAPI.GetCurrentRoom()

            local roomType = REVEL.room:GetType()
            if REVEL.includes(REVEL.SnowFloorRoomTypes, StageAPI.GetCurrentRoomType())
            -- Do not use chill sprite when just triggered chill shrine
            and not (REVEL.room:IsFirstVisit() and currentRoom and currentRoom.PersistentData.ChillShrine) then
                spr:ReplaceSpritesheet(0, "gfx/grid/revel1/glacier_chill_ice_pit.png")
            elseif roomType == RoomType.ROOM_CHALLENGE or roomType == RoomType.ROOM_CURSE or roomType == RoomType.ROOM_SACRIFICE then
                spr:ReplaceSpritesheet(0, "gfx/grid/revel1/challenge_ice_pit.png")
            elseif roomType == RoomType.ROOM_SECRET then
                spr:ReplaceSpritesheet(0, "gfx/grid/revel1/secret_ice_pit.png")
            else
                spr:ReplaceSpritesheet(0, "gfx/grid/revel1/glacier_ice_pit.png")
            end

            spr:LoadGraphics()
            break -- highlights not functional at the moment, need to be worked out
        end
    end
end

function REVEL.GenerateRandomFragileIce(room, iceIndices)
    local width = room.Layout.Width
    
    local surroundedIceIndices = {}
    for i, isIce in pairs(iceIndices) do
        if isIce and not Isaac.FindInRadius(REVEL.room:GetGridPosition(i), 5) then
            local adj = {
                i - 1,
                i + 1,
                i - width,
                i + width,
                i - width - 1,
                i - width + 1,
                i + width - 1,
                i + width + 1
            }

            local surrounded = REVEL.every(adj, function(ind) return iceIndices[ind] end)

            if surrounded then
                surroundedIceIndices[#surroundedIceIndices + 1] = i
            end
        end
    end

    REVEL.Shuffle(surroundedIceIndices)

    local fragileIceChance = 3

    for _, i in ipairs(surroundedIceIndices) do
        local adj = {
            i - 1,
            i + 1,
            i - width,
            i + width,
            i - width - 1,
            i - width + 1,
            i + width - 1,
            i + width + 1
        }

        local hasAdj = REVEL.some(adj, function(ind)
            return room.PersistentData.FragileIce and room.PersistentData.FragileIce[tostring(ind)]
        end)

        if not hasAdj and StageAPI.Random(1, fragileIceChance, FragilityIceSpawnRNG) <= 2 then
            fragileIceChance = fragileIceChance + 3
            room.PersistentData.FragileIce = room.PersistentData.FragileIce or {}
            room.PersistentData.FragileIce[tostring(i)] = 1
        end
    end
end
    
local function icepitsPostRoomInit(newRoom)
    if REVEL.STAGE.Glacier:IsStage() then
        if newRoom.Layout.Name and string.sub(string.lower(newRoom.Layout.Name), 1, 5) == "chill" then
            newRoom:SetTypeOverride(RevRoomType.CHILL)
        end

        local noFragilityIceIndices = newRoom.Metadata:Search{Name = "No Fragilicy Forced Ice", IndexBooleanTable = true}
        local iceIndices = newRoom.Metadata:Search{Name = "Ice Pit", IndexBooleanTable = true}
        local fragileIceIndices = newRoom.Metadata:Search{Name = "Fragile Ice Pit", IndexBooleanTable = true}

        for index, _ in pairs(fragileIceIndices) do
            newRoom.PersistentData.FragileIce = newRoom.PersistentData.FragileIce or {}
            newRoom.PersistentData.FragileIce[tostring(index)] = 0
            if not iceIndices[index] then
                iceIndices[index] = true
            end
        end

        -- random thin ice turned off for now
        if REVEL.IsShrineEffectActive(ShrineTypes.FRAGILITY) and newRoom.RoomType == RoomType.ROOM_DEFAULT
        and REVEL.room:IsFirstVisit()
        and (not StageAPI.InExtraRoom() or newRoom.LayoutName == "StageAPITest") and not newRoom.PersistentData.IsSinami then
            FragilityIceSpawnRNG:SetSeed(newRoom.Seed, 0)
            local spawnExtraIce = StageAPI.Random(1, 3, FragilityIceSpawnRNG) == 1
            local width = newRoom.Layout.Width

            --don't spawn if there are big blowies, mammies, puck
            spawnExtraIce = spawnExtraIce and not StageAPI.DoesLayoutContainEntities(newRoom.Layout, REVEL.GlacierBalance.FragilityIceEntityBlacklist)

            for i = 0, width * newRoom.Layout.Height do
                if newRoom:IsGridIndexFree(i, true, false) and StageAPI.IsIndexInLayout(newRoom.Layout, i) then
                    if not iceIndices[i] and not noFragilityIceIndices[i] and spawnExtraIce then
                        local adj = {
                            i - 1,
                            i + 1,
                            i - width,
                            i + width
                        }

                        local noAdj = true
                        for _, ind in ipairs(adj) do
                            if not newRoom:IsGridIndexFree(i, true, false) then
                                noAdj = false
                                break
                            end
                        end

                        if noAdj then
                            iceIndices[i] = true
                        end
                    end
                end
            end

            if REVEL.GlacierBalance.FragilityFragileIce then
                REVEL.GenerateRandomFragileIce(newRoom, iceIndices)
            end
        end

        --TODO

        newRoom.PersistentData.IcePitFrames = StageAPI.GetPitFramesFromIndices(iceIndices, newRoom.Layout.Width, newRoom.Layout.Height, true)

        if not newRoom.PersistentData.SnowPitFrames then
            newRoom.PersistentData.SnowPitFrames = {}
        end
    end
end

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, icepitsPostRoomInit)

end