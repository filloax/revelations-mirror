local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

local SubModules = {
    'scripts.revelations.chapter2.tomb.basic',
    'scripts.revelations.chapter2.tomb.shrines',

    'scripts.revelations.chapter2.tomb.features.grids',
    'scripts.revelations.chapter2.tomb.features.sand_castles',
    'scripts.revelations.chapter2.tomb.features.tile_dune',
    'scripts.revelations.chapter2.tomb.features.flame_tombs',

    'scripts.revelations.chapter2.tomb.features.traps',
    'scripts.revelations.chapter2.tomb.features.traps.arrow',
    'scripts.revelations.chapter2.tomb.features.traps.bomb',
    'scripts.revelations.chapter2.tomb.features.traps.boulder',
    'scripts.revelations.chapter2.tomb.features.traps.brimstone',
    'scripts.revelations.chapter2.tomb.features.traps.coffin',
    'scripts.revelations.chapter2.tomb.features.traps.flame',
    'scripts.revelations.chapter2.tomb.features.traps.revival',
    'scripts.revelations.chapter2.tomb.features.traps.spike',

    'scripts.revelations.chapter2.tomb.visual.overlays',
    'scripts.revelations.chapter2.tomb.visual.shaders',
    'scripts.revelations.chapter2.tomb.visual.misc',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

-- The stage definiton is located here instead of the revel2_definitions file. Using the exact line below in the definitions file won't work; Tomb will somehow be "nil" even though the definition seems valid.
-- This doesn't break the definition. You can use it in other lua files (i.e. "if StageSystem.GetCurrentStage() == REVEL.STAGE.Tomb.Id then") and it'll still work without issue.
return function()


REVEL.RunLoadFunctions(SubLoadFunctions)

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 1, function(newRoom)
    if REVEL.STAGE.Tomb:IsStage() and (newRoom.RoomType == RoomType.ROOM_DEFAULT or newRoom.RoomType == RoomType.ROOM_BOSS or not StageAPI.InExtraRoom) then
        if newRoom.Layout.Name and string.sub(string.lower(newRoom.Layout.Name), 1, 4) == "trap" then
            newRoom:SetTypeOverride(RevRoomType.TRAP)
        end
    end
end)

StageAPI.AddCallback("Revelations", "POST_ROOM_INIT", 2, function(newRoom)
    if REVEL.STAGE.Tomb:IsStage() and newRoom:GetType() == RevRoomType.TRAP then
		if newRoom.RoomType == RoomType.ROOM_CHALLENGE then
			newRoom:SetTypeOverride(RevRoomType.TRAP_CHALLENGE)
		--[[
		elseif newRoom.RoomType == RoomType.ROOM_SECRET then
			newRoom:SetTypeOverride(RevRoomType.TRAP_SECRET)
		]]
		end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1,  function(newRoom, revisited)
    local roomType = StageAPI.GetCurrentRoomType()
    if REVEL.STAGE.Tomb:IsStage() and (REVEL.includes(REVEL.TombSandGfxRoomTypes, roomType) or not StageAPI.InExtraRoom) then
        REVEL.LoadDuneTiles(newRoom.PersistentData.DuneTileFrames)
    end
end)

StageAPI.AddCallback("Revelations", "POST_BOSS_ROOM_INIT", 1, function(newRoom, boss)
    if boss.Name == "Maxwell" or boss.NameTwo == "Maxwell" then
        newRoom:SetTypeOverride(RevRoomType.TRAP_BOSS_MAXWELL)
    elseif boss.Name == "Sarcophaguts" or boss.NameTwo == "Sarcophaguts" then
        newRoom:SetTypeOverride(RevRoomType.TRAP_BOSS_SARCOPHAGUTS)
    elseif boss.Name == "Sandy" or boss.NameTwo == "Sandy" then
        newRoom:SetTypeOverride(RevRoomType.BOSS_SANDY)
    end
end)


revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    if REVEL.STAGE.Tomb:IsStage() then
        revel.data.run.isTomb = true
    elseif revel.data.run.isTomb then
        revel.data.run.isTomb = nil
        if not REVEL.IsAchievementUnlocked("BANDAGE_BABY") then
            REVEL.UnlockAchievement("BANDAGE_BABY")
        end
    end
end)

Isaac.DebugString("Revelations: Loaded Tomb!")
end