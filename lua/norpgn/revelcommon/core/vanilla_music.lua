local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Replacement for vanilla special room tracks
-- in rev floors with custom ones (from Afterlife OST,
-- used with permission)

-- Music handled by StageAPI
-- Shop, secret, miniboss

---@param stage CustomStage
function REVEL.SetCommonMusicForStage(stage)
    stage:SetMusic(REVEL.SFX.SHOP, RoomType.ROOM_SHOP)
    stage:SetMusic(REVEL.SFX.SECRET, RoomType.ROOM_SECRET)
    stage:SetMusic(REVEL.SFX.SECRET, RoomType.ROOM_SUPERSECRET)
    -- Set in sin file via callback

    -- TEMP: remove if when PR merged
    if stage.SetMinibossMusic then
        stage:SetMinibossMusic(Music.MUSIC_BOSS, REVEL.SFX.BOSS_CALM)
    end
end

-- Treasure
-- Play manually as vanilla ver is a sound, so requires special handling

-- local VanillaTreasureJingles = {
--     Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_0,
--     Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_1,
--     Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_2,
--     Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_3,
-- }

-- local function vanillaMusicTreasureJingle_PostNewRoom()
--     if REVEL.IsRevelStage()
--     and REVEL.room:GetType() == RoomType.ROOM_TREASURE
--     and REVEL.room:IsFirstVisit() 
--     and (REVEL.game:IsGreedMode() or REVEL.level:GetStage() ~= LevelStage.STAGE4_3) 
--     and not REVEL.room:IsMirrorWorld()
--     and not REVEL.level:IsAscent() then
--         REVEL.forEach(VanillaTreasureJingles, function(v) REVEL.sfx:Stop(v) end)
--         local jingle = REVEL.randomFrom(REVEL.SFX.TREASURE)
--         REVEL.music:Play(jingle, Options.MusicVolume)
--     end
-- end

-- revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, vanillaMusicTreasureJingle_PostNewRoom)

--[[
-- StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, 1, function(currentStage, musicID, roomType, roomRNG)
--     if REVEL.IsRevelStage() and roomType == RoomType.ROOM_TREASURE then
--         REVEL.DebugLog("Current track:", musicID)
--     end
--     -- musicID, shouldLayer, shouldQueue, disregardNonOverride
-- end)


    -- MMC base doc:
    --     The function can:

    --     Return a track Id to play that instead.
    --     Return jingle Id, track Id to play a jingle and queue the track.
    --     Return 0 to prevent the track from playing, and allow the current one to continue
    --     Return -1 to stop all music
    --     Return nil to continue to internal code
    -- This will only have returning one/multiple tracks or nil work


local MUSIC_MOD_CALLBACK_PRESENT = not not MMC
local ALT_SIMPLE_STAGEAPI_CALLBACK = "REV_MUSIC_MOD_CALLBACK_SIMPLE"

-- -- (mod, trackId, <isQueued: not present in simple alt version>)
-- -- Either uses MMC if present or use POST_RENDER/POST_NEW_ROOM
-- -- Return a track id to play that instead, 
-- -- multiple to play them in sequence
-- -- Can pass track ids as args to only run when those tracks are playing
local function AddVanillaMusicCallbackWrapper(fn, ...)
    if MUSIC_MOD_CALLBACK_PRESENT then
        MMC.AddMusicCallback(revel, fn, ...)
    else
        StageAPI.AddCallback("Revelations", ALT_SIMPLE_STAGEAPI_CALLBACK, 0, fn, ...)
    end
end

if not MUSIC_MOD_CALLBACK_PRESENT then
    local function RunCallbacks(musicId)
        REVEL.DebugStringMinor("Running music callbacks with: " .. tostring(musicId))

        local newMusicId1, newMusicId2
        local callbacks = StageAPI.GetCallbacks(ALT_SIMPLE_STAGEAPI_CALLBACK)

        for _, callback in ipairs(callbacks) do
            if not callback.Params[1] or REVEL.includes(callback.Params, musicId) then
                local ret1, ret2 = callback.Function(revel, musicId)
                if ret1 ~= nil then
                    newMusicId1, newMusicId2 = ret1, ret2
                    return
                end
            end
        end

        if newMusicId1 then
            REVEL.DebugStringMinor("Replacing music " .. tostring(musicId) .. " with " .. tostring(newMusicId1))
            REVEL.music:Play(newMusicId1, Options.MusicVolume)
            if newMusicId2 then
                REVEL.music:Queue(newMusicId2)
            end
        end
    end

    local PrevMusic = nil

    local function vanillaMusicCallback_PostRender()
        local musicId = REVEL.music:GetCurrentMusicID()
    
        if PrevMusic ~= musicId then
            RunCallbacks(musicId)
            PrevMusic = musicId
        end
    end

    local function vanillaMusicCallback_PostNewRoom()
        local musicId = REVEL.music:GetCurrentMusicID()
    
        RunCallbacks(musicId)
        PrevMusic = musicId
    end

    -- revel:AddCallback(ModCallbacks.MC_POST_RENDER, vanillaMusicCallback_PostRender)
    -- revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, vanillaMusicCallback_PostNewRoom)
end

]]

end