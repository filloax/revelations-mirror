local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local RevRoomType       = require("lua.revelcommon.enums.RevRoomType")

local SubModules = {
    'lua.revel1.glacier.basic',
    'lua.revel1.glacier.shrines',

    'lua.revel1.glacier.features.chill',
    'lua.revel1.glacier.features.brazier',
    'lua.revel1.glacier.features.ice_pits',
    'lua.revel1.glacier.features.fragile_ice',
    'lua.revel1.glacier.features.grids',
    'lua.revel1.glacier.features.slippery',
    'lua.revel1.glacier.features.total_freeze',
    'lua.revel1.glacier.features.snow_tiles',
    'lua.revel1.glacier.features.exploding_snowman',
    'lua.revel1.glacier.features.dante_satan',
    'lua.revel1.glacier.features.dante_mega_satan',

    'lua.revel1.glacier.visual.overlays',
    'lua.revel1.glacier.visual.shaders',
    'lua.revel1.glacier.visual.aurora_borealis',
    'lua.revel1.glacier.visual.misc',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.Glacier = {}

REVEL.RunLoadFunctions(SubLoadFunctions)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_INIT, 2, function(newRoom)
    if REVEL.STAGE.Glacier:IsStage() and newRoom:GetType() == RevRoomType.CHILL then
        if newRoom.RoomType == RoomType.ROOM_CHALLENGE then
            newRoom:SetTypeOverride(RevRoomType.CHILL_CHALLENGE)
		--[[
        elseif newRoom.RoomType == RoomType.ROOM_SECRET then
            newRoom:SetTypeOverride("ChillSecret")
		]]
        elseif newRoom.RoomType == RoomType.ROOM_BOSS then
            newRoom:SetTypeOverride(RevRoomType.CHILL_FREEZER_BURN)
        end
    end
end)


StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1,  function(newRoom, revisited)
    local roomType = StageAPI.GetCurrentRoomType()
    if REVEL.STAGE.Glacier:IsStage() and (REVEL.includes(REVEL.GlacierGfxRoomTypes, roomType) or not StageAPI.InExtraRoom) then
        REVEL.LoadIcePits(newRoom.PersistentData.IcePitFrames)
        REVEL.LoadSnowedTiles(newRoom.PersistentData.SnowedTiles)
        REVEL.FragileiceRoomLoad(newRoom, revisited)
        REVEL.UpdateChill()
    end
end)

local function miscglacierPostNewLevel()
    if REVEL.STAGE.Glacier:IsStage() then
        revel.data.run.isGlacier = true
    elseif revel.data.run.isGlacier then
        revel.data.run.isGlacier = nil
        if not revel.IsAchievementUnlocked("ICETRAY") then
            revel.UnlockAchievement("ICETRAY")
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, miscglacierPostNewLevel)


Isaac.DebugString("Revelations: Loaded Glacier!")
end
REVEL.PcallWorkaroundBreakFunction()