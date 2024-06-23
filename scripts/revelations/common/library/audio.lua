return function()


local musicFadeTime = 0
local fadeTimeStart = 0
local volumeStart = 0
local startFadeMusic = 0

function REVEL.MusicFadeOut(time, startingvolume)
    musicFadeTime = time
    fadeTimeStart = time
    volumeStart = startingvolume
    startFadeMusic = REVEL.music:GetCurrentMusicID()
end

local function musicfadeoutPostUpdate()
    if REVEL.music:GetCurrentMusicID() ~= startFadeMusic then
        musicFadeTime = 0
    end

    if musicFadeTime > 0 then
        musicFadeTime = math.max(0, musicFadeTime - 1)
        REVEL.music:VolumeSlide(musicFadeTime*volumeStart/fadeTimeStart)
        REVEL.music:UpdateVolume()
    end
end

---@class RevSound
---@field Sound SoundEffect
---@field Volume number
---@field Delay integer
---@field Loop boolean
---@field Pitch number
---@field PitchVariance number
---@field NegativeVariance boolean

---@overload fun(npc: EntityNPC, sounds: RevSound[])
---@overload fun(sounds: RevSound[])
---@overload fun(npc: EntityNPC, sound: RevSound)
---@overload fun(sound: RevSound)
---@overload fun(npc: EntityNPC, soundId: number, volume: number, frameDelay: integer, loop: boolean, pitch: number)
---@overload fun(soundId: number, volume: number, frameDelay: integer, loop: boolean, pitch: number)
function REVEL.PlaySound(...) -- A simpler method to play sounds, allows ordered or paired tables.
    local args = {...}

    for i = 1, 6 do -- table.remove won't work to move values down if values inbetween are nil
        if args[i] == nil then
            args[i] = -1111
        end
    end

    local npc, tbl

    if type(args[1]) == "userdata" and args[1].Type then
        npc = args[1]:ToNPC()
        table.remove(args, 1)
    end

    if type(args[1]) == "table" then
        tbl = args[1]
        table.remove(args, 1)
        if type(tbl[1]) == "table" then
            for _, sound in ipairs(tbl) do
                if npc then
                    REVEL.PlaySound(npc, sound)
                else
                    REVEL.PlaySound(sound)
                end
            end

            return
        end
    elseif args[1] == -1111 then
        return
    end

    for i, v in ipairs(args) do
        if v == -1111 then
            args[i] = nil
        end
    end

    local soundArgs = REVEL.copy(args)
    if tbl then
        if #tbl > 0 then
            soundArgs = tbl
        else
            soundArgs = {tbl.Sound, tbl.Volume, tbl.Delay, tbl.Loop, tbl.Pitch}
        end

        -- If there are any remaining args after npc and table are removed, they override volume, delay, loop, and pitch
        for i = 1, 4 do
            if args[i] ~= nil then
                soundArgs[i + 1] = args[i]
            end
        end
    end

    soundArgs[2] = soundArgs[2] or 1
    soundArgs[3] = soundArgs[3] or 0
    soundArgs[4] = soundArgs[4] or false
    soundArgs[5] = soundArgs[5] or 1

    if tbl and tbl.PitchVariance then
        local variance = math.random()
        if tbl.NegativeVariance then
            variance = variance - 0.5
        end

        soundArgs[5] = soundArgs[5] + variance * tbl.PitchVariance
    end

    if npc then
        REVEL.sfx:NpcPlay(npc, table.unpack(soundArgs))
    else
        REVEL.sfx:Play(table.unpack(soundArgs))
    end
end

---Stop current playing track to allow replacing in StageAPI floors
-- meant to stop tracks that cannot be overridden by stageapi
---@param musicId? Music optionally check music to stop
function REVEL.StopMusicTrack(musicId)
    if not musicId or REVEL.music:GetCurrentMusicID() == musicId then
        -- Play arbitrary music with volume 0
        -- music has to be overridable by StageAPI
        REVEL.music:Play(Music.MUSIC_BASEMENT, 0)
    end
end

---Plays jingle and stops it when entering the next room
---@param musicId Music
function REVEL.PlayJingleForRoom(musicId, volume)
    if REPENTOGON then
        REVEL.music:PlayJingle(musicId)
    else
        REVEL.music:Play(musicId, Options.MusicVolume)
        REVEL.CallbackOnce(ModCallbacks.MC_POST_NEW_ROOM, function()
            REVEL.StopMusicTrack(musicId)
        end)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, musicfadeoutPostUpdate)

end