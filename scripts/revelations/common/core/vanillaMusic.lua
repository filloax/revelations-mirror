local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Replacement for vanilla special room tracks
-- in rev floors with custom ones (from Afterlife OST,
-- used with permission)

-- Music handled by StageAPI
-- Shop, secret, miniboss

---@param stage CustomStage
function REVEL.SetCommonMusicForStage(stage)
    stage:SetMusic(REVEL.MUSIC.SHOP, RoomType.ROOM_SHOP)
    stage:SetMusic(REVEL.MUSIC.SECRET, RoomType.ROOM_SECRET)
    stage:SetMusic(REVEL.MUSIC.SECRET, RoomType.ROOM_SUPERSECRET)
    -- Set in sin file via callback

    stage:SetMinibossMusic(Music.MUSIC_BOSS, REVEL.MUSIC.BOSS_CALM)
end

-- Treasure
-- Use Repentogon to handle jingles

local VanillaTreasureJingles = {
    Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_0,
    Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_1,
    Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_2,
    Music.MUSIC_JINGLE_TREASUREROOM_ENTRY_3,
}

local function vanillaMusic_TreasureJingle_PreMusicPlay(_, id, volume_FadeRate, isFade)
    if REVEL.IsRevelStage() then
       
        local jingle = REVEL.randomFrom(REVEL.MUSIC.TREASURE)
        REVEL.DebugStringMinor("Playing rev treasure jingle", jingle, "was", id)
        return jingle
    end
end

-- local function vanillaMusic_TreasureJingle_PostNewRoom()
--     REVEL.DelayFunction(function()
--         if REVEL.IsRevelStage() and REVEL.room:GetType() == RoomType.ROOM_TREASURE
--         and REVEL.room:IsFirstVisit() then
--             local jingle = REVEL.randomFrom(REVEL.MUSIC.TREASURE)
--             REVEL.DebugLog("Playing rev treasure jingle", jingle)
--             REVEL.music:StopJingle()
--             REVEL.music:PlayJingle(jingle)
--         end
--     end, 0)
-- end

for _, jingle in ipairs(VanillaTreasureJingles) do
    revel:AddCallback(ModCallbacks.MC_PRE_MUSIC_PLAY_JINGLE, vanillaMusic_TreasureJingle_PreMusicPlay, jingle)
end

-- revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, vanillaMusic_TreasureJingle_PostNewRoom)

end