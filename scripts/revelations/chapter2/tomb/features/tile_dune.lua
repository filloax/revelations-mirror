local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

return function()

function REVEL.LoadDuneTiles(frames)
    for index, frame in pairs(frames) do
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
            e:GetData().DuneTile = true
            
            if REVEL.includes(REVEL.TombSandGfxRoomTypes , StageAPI.GetCurrentRoomType()) then
                spr:ReplaceSpritesheet(0, "gfx/grid/revel2/tile_dune.png")
            end

            spr:LoadGraphics()
            break
        end
    end
end

local ShouldConvertFrames = not REVEL.HasStageApiVersion("2.30")

local function dunetilesPostRoomInit(newRoom)
    if REVEL.STAGE.Tomb:IsStage() then
        local tileIndices = newRoom.Metadata:Search{Name = "Dune Tile", IndexBooleanTable = true}

        local duneTileFrames = StageAPI.GetPitFramesFromIndices(tileIndices, newRoom.Layout.Width, newRoom.Layout.Height, true, true)
        if ShouldConvertFrames then
            newRoom.PersistentData.DuneTileFrames = {}
            for k, v in pairs(duneTileFrames) do
                newRoom.PersistentData.DuneTileFrames[tonumber(k)] = v
            end
        else
            newRoom.PersistentData.DuneTileFrames = duneTileFrames
        end
    end
end

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, dunetilesPostRoomInit)

function REVEL.CheckDuneTile(ent, pos)
    local currentRoom = StageAPI.GetCurrentRoom()
    pos = pos or ent.Position
    local index = REVEL.room:GetGridIndex(pos)
    if currentRoom and (currentRoom.PersistentData.DuneTileFrames and currentRoom.PersistentData.DuneTileFrames[index]) then
        return true
    end
    return false
end

function REVEL.DuneTileProcessing(ent, pos)
    local onTile = REVEL.CheckDuneTile(ent, pos)
    local data = REVEL.GetData(ent)

    if onTile then
        data.OnDuneTile = true
    else
        data.OnDuneTile = false
        if ent.Type == EntityType.ENTITY_PLAYER 
        and (#REVEL.ENT.DUNE:getInRoom() or 0) > 0 
        and ent.Velocity:Length() > 1
        and ent.FrameCount % 3 == 0 then
            local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, 
            ent.Position-Vector(0,16), Vector(0,-4):Rotated(math.random(-50,50))-ent.Velocity, ent):ToEffect()
            local color = Color(1,1,1,1)
            color:SetColorize(4.5,3.4,2,1)
            dust.Color = color
            dust:GetSprite().PlaybackSpeed = 0.5
            dust.Timeout = 50
        end
    end

    return onTile
end

end