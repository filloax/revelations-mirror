local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

local SubModules = {
    'scripts.revelations.chapter1.glacier.basic',
    'scripts.revelations.chapter1.glacier.shrines',

    'scripts.revelations.chapter1.glacier.features.chill',
    'scripts.revelations.chapter1.glacier.features.brazier',
    'scripts.revelations.chapter1.glacier.features.ice_pits',
    'scripts.revelations.chapter1.glacier.features.fragile_ice',
    'scripts.revelations.chapter1.glacier.features.grids',
    'scripts.revelations.chapter1.glacier.features.slippery',
    'scripts.revelations.chapter1.glacier.features.total_freeze',
    'scripts.revelations.chapter1.glacier.features.snow_tiles',
    'scripts.revelations.chapter1.glacier.features.exploding_snowman',
    'scripts.revelations.chapter1.glacier.features.dante_satan',
    'scripts.revelations.chapter1.glacier.features.dante_mega_satan',

    'scripts.revelations.chapter1.glacier.visual.overlays',
    'scripts.revelations.chapter1.glacier.visual.shaders',
    'scripts.revelations.chapter1.glacier.visual.aurora_borealis',
    'scripts.revelations.chapter1.glacier.visual.misc',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

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
        if not REVEL.IsAchievementUnlocked("ICETRAY") then
            REVEL.UnlockAchievement("ICETRAY")
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, miscglacierPostNewLevel)


Isaac.DebugString("Revelations: Loaded Glacier!")
end