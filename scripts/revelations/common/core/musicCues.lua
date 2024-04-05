local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Music cues

local RecentlyTriggeredCueClearTime = 2000
local RecentlyTriggeredOrphanedClearTime = 3000 --time before removing a recently triggered clue table for a song that stopped playing

local trackData

local function ResetTrackData()
    trackData.currentTrack = nil
    trackData.currentTrackStartTime = -1
    trackData.currentTrackPauseTime = -1
    trackData.currentCue = {}
    trackData.justTriggeredAnyCue = false
    trackData.justTriggeredCue = {}
    trackData.allCuesTriggeredThisUpdate = {}
    trackData.cuesetsTriggeredThisUpdate = {}
    trackData.recentlyTriggered = {}

    trackData.nextCueActionQueue = {}
    trackData.nextAnyCueActionQueue = {}

    trackData.prevTrackTime = -1

    trackData.prevMusicId = -1
end

--Handle ingame reload (mainly so I don't go mad working on ragtime)
if not _G.__rev_mus_track_data then
    trackData = {}

    ResetTrackData()
    _G.__rev_mus_track_data = trackData
else
    trackData = _G.__rev_mus_track_data
end

---@return MusicCuesTrack
function REVEL.GetMusicCuesTrack()
    return trackData.currentTrack
end

function REVEL.StartMusicCuesTrack(cuesTable, withMusic)
    REVEL.DebugStringMinor("Starting music cues track", cuesTable.Track)

    trackData.currentTrack = cuesTable
    if withMusic then
        REVEL.music:Play(cuesTable.Track, 0)
        REVEL.music:UpdateVolume()
    end
    trackData.currentTrackStartTime = Isaac.GetTime()
    trackData.prevTrackTime = -1

    trackData.currentCue = {}
    trackData.justTriggeredCue = {}
    trackData.nextCueActionQueue = {}
    trackData.nextAnyCueActionQueue = {}
    trackData.recentlyTriggered[cuesTable.Name] = {Any = {}, OrphanedTime = -1}

    for cueSetName, _ in pairs(cuesTable.Cues) do
        if cueSetName == "Any" then error("Invalid cue set name: Any") end
        if cueSetName == "OrphanedTime" then error("Invalid cue set name: OrphanedTime") end

        trackData.currentCue[cueSetName] = 1
        trackData.nextCueActionQueue[cueSetName] = {}
        trackData.recentlyTriggered[cuesTable.Name][cueSetName] = {}
    end
end

function REVEL.StopMusicCuesTrack()
    if trackData.currentTrack and trackData.recentlyTriggered[trackData.currentTrack.Name] then
        REVEL.DebugStringMinor("Stopping music cues track", trackData.currentTrack.Name)

        trackData.recentlyTriggered[trackData.currentTrack.Name].OrphanedTime = Isaac.GetTime() -- mark for deletion, give some time before to allow for impercise trigger checks (ie x ms after trigger)
    end
    ResetTrackData()
end

function REVEL.PauseMusicCuesTrack()
    local time = Isaac.GetTime()
    REVEL.music:Pause()
    trackData.currentTrackPauseTime = time
end

function REVEL.ResumeMusicCuesTrack()
    if trackData.currentTrackPauseTime ~= -1 then
        local time = Isaac.GetTime()
        REVEL.music:Resume()
        trackData.currentTrackStartTime = trackData.currentTrackStartTime + time - trackData.currentTrackPauseTime
        trackData.currentTrackPauseTime = -1
    end
end

function REVEL.GetMusicCuesTrackTime(time)
    local time = time or Isaac.GetTime()

    if not trackData.currentTrack then
        error("GetMusicCuesTrackTime: no track playing!", 2)
    end

    if trackData.currentTrack.Loop then
        return (time - trackData.currentTrackStartTime) % (trackData.currentTrack.Duration)
    else
        return time - trackData.currentTrackStartTime
    end
end

---Return duration between two track times, considering loops if necessary
---@param from integer
---@param to integer
---@return integer
function REVEL.GetMusicCuesTrackDuration(from, to)
    if to >= from then
        return to - from
    else
        return to + trackData.currentTrack.Duration - from
    end
end

function REVEL.IsMusicCuesTrackPlaying(checkTrack, time)
    return trackData.currentTrack and (not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack) and not REVEL.IsMusicCuesTrackFinished(checkTrack, time)
end

function REVEL.IsMusicCuesTrackFinished(checkTrack, time)
    if not trackData.currentTrack then
        return not checkTrack
    end

    local time = time or Isaac.GetTime()
    local isTrack = not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack
    if trackData.currentTrack.Loop then
        local tolerance = 5
        return math.abs((time - trackData.currentTrackStartTime) % (trackData.currentTrack.Duration)) < tolerance and isTrack
    else
        return time - trackData.currentTrackStartTime > trackData.currentTrack.Duration and isTrack
    end
end

--Check if the cue is triggered this frame, with optionally <tolerance> ms of difference;
-- optionally can be pre-supplied with nextCues table (ie from REVEL.GetCuesInTimespan) for better performance than getting it again (if already present)
-- returns music cue time
function REVEL.IsMusicCueTriggered(cueSetName, checkTrack, tolerancePast, toleranceFuture, nextCues)
    if (not tolerancePast or tolerancePast == 0) and (not toleranceFuture or toleranceFuture == 0) then --basic "was triggered this frame" check
        return (not cueSetName and trackData.justTriggeredAnyCue) or (trackData.justTriggeredCue[cueSetName] and (not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack))

    else --more complex: check if the cue is triggered <tolerance> ms before or after the current time
        local time = Isaac.GetTime()

        if not toleranceFuture then toleranceFuture = tolerancePast end

        --Check recently triggered cues
        for trackName, trackRecentTriggers in pairs(trackData.recentlyTriggered) do
            if not checkTrack or checkTrack.Name == trackName then
                for thisCueSetName, setRecentTriggers in pairs(trackRecentTriggers) do
                    if thisCueSetName ~= "OrphanedTime" and (not cueSetName or thisCueSetName == cueSetName) then
                        for _, clueTime in ripairs(setRecentTriggers) do --ripairs cause most recent is the latest added
                            -- REVEL.DebugToConsole("After:", time, clueTime, tolerance)
                            if time <= clueTime.TriggerTime + tolerancePast then --input was done before <tolerance> ms after the last clue
                                    return clueTime.TrackTime
                            end
                        end
                    end
                end
            end
        end

        if REVEL.IsMusicCuesTrackPlaying(checkTrack) then
            local trackTime = REVEL.GetMusicCuesTrackTime(time)

            --Check soon-to-be triggered cues
            local next
            if nextCues then
                next = nextCues[1]
            else
                local cueSet = cueSetName and trackData.currentTrack.Cues[cueSetName] or trackData.currentTrack.AllCues
                local nextCueIndex = REVEL.ClosestBinarySearch(cueSet, trackTime)
                next = cueSet[nextCueIndex]
            end
            if next then
                -- REVEL.DebugToConsole("Before:", time, next, tolerance)
                if trackData.currentTrack.Loop then
                    return (next <= (trackTime + toleranceFuture) % trackData.currentTrack.Duration) and next --return the next's time and not just true
                else
                    return (next <= trackTime + toleranceFuture) and next
                end
            end
        end
    end
end

function REVEL.IsMusicCueTriggeredThisUpdate(cueSetName, checkTrack)
    return (not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack)
        and ((not cueSetName and #trackData.allCuesTriggeredThisUpdate > 0) or (trackData.cuesetsTriggeredThisUpdate[cueSetName]))
end

function REVEL.GetNextMusicCue(cueSetName, checkTrack)
    if not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack then
        local cueSet = cueSetName and trackData.currentTrack.Cues[cueSetName] or trackData.currentTrack.AllCues
        local trackTime = REVEL.GetMusicCuesTrackTime()
        local startIndex = REVEL.ClosestBinarySearch(cueSet, trackTime)

        return cueSet[startIndex]
    end
end

---@param cueSetName string
---@param checkTrack boolean
---@param amount integer
---@param asTimeleft? boolean
---@return integer[]
function REVEL.GetNextMusicCues(cueSetName, checkTrack, amount, asTimeleft)
    if not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack then
        local cueSet = cueSetName and trackData.currentTrack.Cues[cueSetName] or trackData.currentTrack.AllCues
        local trackTime = REVEL.GetMusicCuesTrackTime()
        local startIndex = REVEL.ClosestBinarySearch(cueSet, trackTime)

        local cues = {}

        for i = 0, amount - 1 do
            if startIndex + i <= #cueSet then
                cues[#cues + 1] = cueSet[startIndex + i]
            elseif trackData.currentTrack.Loop then
                local idx = (startIndex + i - 1) % #cueSet + 1
                cues[#cues + 1] = cueSet[idx]
            else
                break
            end
        end

        if asTimeleft then
            return REVEL.map(cues, function(cue)
                return REVEL.GetMusicCuesTrackDuration(trackTime, cue)
            end)
        else
            return cues
        end
    end
    return {}
end

function REVEL.GetMusicCuesTriggeredThisUpdate(cueSetName, checkTrack)
    if not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack then
        if cueSetName then
            return trackData.cuesetsTriggeredThisUpdate[cueSetName] or {}
        else
            return trackData.allCuesTriggeredThisUpdate, trackData.cuesetsTriggeredThisUpdate
        end
    end
    return {}
end

function REVEL.GetCuesInTimespan(timespan, cueSetName, time)
    local trackTime = REVEL.GetMusicCuesTrackTime(time)

    local cueSet = cueSetName and trackData.currentTrack.Cues[cueSetName] or trackData.currentTrack.AllCues

    local startIndex = REVEL.ClosestBinarySearch(cueSet, trackTime)
    local i = startIndex
    local out = {}
    local gotToEnd = false
    
    repeat
        if trackData.currentTrack.Loop then
            gotToEnd = true --TODO IF NEEDED, RIGHT NOW ONLY MIXTAPE (non-loop) USES IT
        else
            if not cueSet[i] or cueSet[i] > trackTime + timespan then
                gotToEnd = true
            else
                out[#out + 1] = cueSet[i]
                i = i + 1
            end
        end
    until gotToEnd

    return out
end

function REVEL.GetPastCuesInTimespan(timespan, useCuesetName, time) --similar to function above, but backwards instead of forwards
    time = time or Isaac.GetTime()
    useCuesetName = useCuesetName or "Any"

    local out = {}
    local trackRecentTriggers = trackData.recentlyTriggered[trackData.currentTrack.Name]
    local setRecentTriggers = trackRecentTriggers[useCuesetName]

    for _, clueTime in ipairs(setRecentTriggers) do --ripairs cause most recent is the latest added
        -- REVEL.DebugToConsole("After:", time, clueTime, tolerance)
        if time - timespan <= clueTime.TriggerTime then --input was done before <tolerance> ms after the last clue
            out[#out+1] = clueTime
        end
    end

    return out
end

local function getTrackTime(v) return v.TrackTime end

function REVEL.GetAllCuesInTimeSpan(timespan, shift, useCuesetName, time) --by default timespan is centered on time, shift shifts the window center
    shift = shift or 0

    return REVEL.ConcatTables(REVEL.map(REVEL.GetPastCuesInTimespan(timespan / 2 - shift, useCuesetName, time), getTrackTime), REVEL.GetCuesInTimespan(timespan / 2 + shift, useCuesetName, time))
end

function REVEL.GetNumCues(track, cueset)
    track = track or trackData.currentTrack

    if cueset then
        return #(track.Cues[cueset])
    else
        local out = 0
        for setname, set in pairs(track.Cues) do
            out = out + #set
        end

        return out
    end
end

function REVEL.DoOnNextCue(action, cueSetName, checkTrack, replaceLast)
    if not checkTrack or REVEL.GetMusicCuesTrack() == checkTrack then
        local queue
        if cueSetName then
            queue = trackData.nextCueActionQueue[cueSetName]
        else
            queue = trackData.nextAnyCueActionQueue
        end
        local i = (replaceLast and #queue > 0) and (#queue) or (#queue + 1)
        queue[i] = action
    end
end

function REVEL.CueDebugPulse()
    IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, REVEL.room:GetCenterPos(), nil, nil, nil, nil, Color(1, 0, 0, 1, 0, 0, 0))
    for i = 0, 10 do
        REVEL.DelayFunction(i, function() IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, REVEL.room:GetCenterPos(), nil, nil, nil, nil, Color(1, 0, 0, 1, 0, 0, 0)) end)
    end
    for i = 11, 15 do
        local a = 1 - (i - 10) / 5
        REVEL.DelayFunction(i, function() IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, REVEL.room:GetCenterPos(), nil, nil, nil, nil, Color(1, 0, 0, a, 0, 0, 0)) end)
    end
end

function REVEL.DoCueDebugNextCue()
    REVEL.DoOnNextCue(function()
        REVEL.CueDebugPulse()
        REVEL.DelayFunction(1, REVEL.DoCueDebugNextCue)
    end)
end

local function musicCues_PostRender()
    local musicId = REVEL.music:GetCurrentMusicID()

    if trackData.prevMusicId ~= musicId then
        trackData.prevMusicId = musicId

        if REVEL.CuesByTrackId[musicId] then
            REVEL.StartMusicCuesTrack(REVEL.CuesByTrackId[musicId])
        else
            REVEL.StopMusicCuesTrack()
        end
    end

    trackData.justTriggeredAnyCue = false

    local time = Isaac.GetTime()

    if trackData.currentTrack and trackData.currentTrackPauseTime < 0 then
        local trackTime = REVEL.GetMusicCuesTrackTime()

        -- if not REVEL.game:IsPaused() then
        --     REVEL.DebugLog("Track time render", trackTime)
        -- end

        for cueSetName, cueSet in pairs(trackData.currentTrack.Cues) do
            if trackTime < trackData.prevTrackTime then --restarted
                trackData.currentCue[cueSetName] = 1
            end

            local cur = trackData.currentCue[cueSetName]

            if trackTime >= cueSet[cur] and (trackData.prevTrackTime < cueSet[cur] or trackData.prevTrackTime > trackTime) then --triggered current cue
                if not trackData.cuesetsTriggeredThisUpdate[cueSetName] then
                    trackData.cuesetsTriggeredThisUpdate[cueSetName] = {}
                end
                trackData.cuesetsTriggeredThisUpdate[cueSetName][#trackData.cuesetsTriggeredThisUpdate[cueSetName] + 1] = cur
                trackData.allCuesTriggeredThisUpdate[#trackData.allCuesTriggeredThisUpdate + 1] = cur

                local trackName = trackData.currentTrack.Name
                local recentlyTrigCuesetTbl = trackData.recentlyTriggered[trackName][cueSetName]
                local recentlyTrigAnyTbl = trackData.recentlyTriggered[trackName].Any

                local cueTbl = {TrackTime = cueSet[cur], TriggerTime = time}

                recentlyTrigCuesetTbl[#recentlyTrigCuesetTbl + 1] = cueTbl --save the time so it can be cleaned up later
                recentlyTrigAnyTbl[#recentlyTrigAnyTbl + 1] = cueTbl

                if not trackData.justTriggeredAnyCue then
                    for i = 1, #trackData.nextAnyCueActionQueue do
                        pcall(trackData.nextAnyCueActionQueue[i])
                    end

                    trackData.nextAnyCueActionQueue = {}
                end

                for i = 1, #trackData.nextCueActionQueue[cueSetName] do
                    pcall(trackData.nextCueActionQueue[cueSetName][i])
                end

                trackData.nextCueActionQueue[cueSetName] = {}

                trackData.justTriggeredAnyCue = true

                -- REVEL.DebugToConsole(cueSetName, cur)

                trackData.currentCue[cueSetName] = (cur % #cueSet) + 1
            else
                trackData.justTriggeredCue[cueSetName] = false
            end
        end

        trackData.prevTrackTime = trackTime
    end

    for originalTrackName, trackRecentTriggers in pairs(trackData.recentlyTriggered) do
        for cuesetName, setRecentTriggers in pairs(trackRecentTriggers) do
            if cuesetName ~= "OrphanedTime" and #setRecentTriggers > 0 then
                repeat
                    -- cue trigger times are added to this table sequentially, so the first one is always the least recent one
                    if time > setRecentTriggers[1].TriggerTime + RecentlyTriggeredCueClearTime then
                        table.remove(setRecentTriggers, 1)
                    end
                until not setRecentTriggers[1] or time <= setRecentTriggers[1].TriggerTime + RecentlyTriggeredCueClearTime
            end
        end

        if not trackData.currentTrack or originalTrackName ~= trackData.currentTrack.Name
        and time > trackRecentTriggers.OrphanedTime + RecentlyTriggeredOrphanedClearTime then --remove track recent triggers
            trackData.recentlyTriggered[originalTrackName] = nil
        end
    end
end

--Music is usually played on POST_RENDER (at least in StageAPI)
revel:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, function()
    for k, _ in pairs(trackData.cuesetsTriggeredThisUpdate) do trackData.cuesetsTriggeredThisUpdate[k] = nil end
    for k, _ in pairs(trackData.allCuesTriggeredThisUpdate) do trackData.allCuesTriggeredThisUpdate[k] = nil end
end)
revel:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, CallbackPriority.LATE, musicCues_PostRender)

end