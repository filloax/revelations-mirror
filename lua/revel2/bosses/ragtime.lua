local StageAPICallbacks = require "lua.revelcommon.enums.StageAPICallbacks"
local RevCallbacks      = require "lua.revelcommon.enums.RevCallbacks"
local KnifeVariant      = require "lua.revelcommon.enums.KnifeVariant"
local KnifeSubtype      = require "lua.revelcommon.enums.KnifeSubtype"
local ProjectilesMode   = require "lua.revelcommon.enums.ProjectilesMode"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

    REVEL.Elites.Ragtime = {
        Music = REVEL.SFX.ELITE_RAGTIME.Track,
        ClearMusic = REVEL.SFX.TOMB_BOSS_OUTRO
    }
    
    REVEL.RagtimeBalance = {
        -- How many HP phase 1 has of the total
        -- (consider that phase 2 is harder to hit)
        PhaseHpBalance = 0.66,

        MusicMapSetDefault = "Default",
        MusicMapSetMeasure = "MinorBig",
        MusicMapSetForceLeap = "ForcedLeap",
        MusicMapSetMajorStart = "MajorBig",

        DancerNoCollAnims = {"Leap1", "Leap2"},

        LightsOut = {
            Duration = 160,
            -- the below are the fraction of total duration
            FullDarkOnTime = 25 / 160,
            SpawnTime = 30 / 160,
            FullDarkOffTime = 32 / 160,
            SpotlightEnlargeTime = 60 / 160,
            PlayerCameraMoveTime = 75 / 160,
            PhaseStartTime = 80 / 160,
            SpotlightFadeTime = 0.9,
            NumDances = 2,
        },

        TiredMaxWaitTime = 90,
        TiredMaxDamagePct = 0.2,

        StartProgressAtMeasure = true, --sync attack patterns start on new measures, can be set for each dance pattern too

        BoxDance1 = {
            BeatPattern = {"Idle", "Idle", "Idle", "Idle", "Idle", "Idle", "Move", "Shoot"},
            LeadGoToNextTime = 1, --seconds
            LeadSpeed = 5,
            NumShooters = {Min = 3, Max = 6},
            IdleMovesAround = false,
        },

        Conga1 = {
            BeatPattern = {"Idle", "Move", "Idle", "Move", "Idle", "Move", "Idle", "Shoot"},
            NumDancers = 5,
            NumShooters = {Min = 2, Max = 4},
        },

        BoxDance2 = {
            BeatPattern = {"Idle", "Idle", "Idle", "Move", "Idle", "Idle", "Move", "Shoot"},
            LeadGoToNextTime = 1, --seconds
            LeadSpeed = 5,
            NumShooters = {Min = 3, Max = 5},
            IdleMovesAround = true,
        },

        Conga2 = {
            BeatPattern = {"Move", "Move", "Move", "Shoot"},
            NumDancers = 5,
            NumShooters = {Min = 2, Max = 3},
        },

        DanceOff = {
            TargetDistance = 160,
            ResetHpPcts = {0.5},
            -- both reflect and revive
            AttackCooldown = {Min = 60, Max = 150},
            ReflectAnimDuration = {Min = 20, Max = 60},
            DoTimedReset = true,
            TimedResetTime = 30 * 10,
            DeadDancersForRevive = 6,
            ReviveFramesBeforeBeat = 3,
        },

        Dancers = {
            ShootAngleError = 15,
            ShootSpeed = 10,
            ShootHeightMod = -8,
            ShootFallingSpeedMod = -0.15,
            ShootFallingAccelMod = -0.1,
            HomingStrength = 0.5,
        },

        -- At least max amount of dancers, used
        -- to get safe positions for safe point choice
        CongaUnsafeZoneLength = 5,

        MinVelocityToFlipAnim = 1,

        ReviveAnimSpawnTime = 24,
        DancerHopAnimDuration = 5,
        DancerLeapAnimDuration = 8,

        AnimsWithLeftAlt = {
            Dance_2 = "Dance_2_Left",
            Dance_2_Tired = "Dance_2_Left_Tired",
            Dance_Reflect_Start = "Dance_Reflect_Left_Start",
            Dance_Reflect_Loop  = "Dance_Reflect_Left_Loop",
            Dance_Reflect_Stop  = "Dance_Reflect_Left_Stop",
            WalkHori = "WalkLeft",
        },

        DanceToTired = {
            Dance_1 = "Dance_1_Tired",
            Dance_2 = "Dance_2_Tired",
            Dance_2_Left = "Dance_2_Left_Tired",
            Dance_3 = "Dance_3_Tired",
        },

        Sounds = {
            SpawnPoof = {Sound = SoundEffect.SOUND_FETUS_JUMP, Volume = 0.9, Pitch = 0.75},
            ConfettiPop = {Sound = SoundEffect.SOUND_BOIL_HATCH, Volume = 0.9, Pitch = 1.2},
            ClappingLoop = {Sound = REVEL.SFX.CLAP_LOOP, Loop = true},
            ClappingFade = {Sound = REVEL.SFX.CLAP_FADE},
            Spin = {Sound = SoundEffect.SOUND_ULTRA_GREED_SPINNING, Volume = 0.5, Pitch = 1.2, Loop = true},
            DeathPull = {Sound = REVEL.SFX.SLIDE_WHISTLE},
        },

        SongBPM = 90, -- used for debug
        GoOffBPM = true, -- no custom times depending on song part, but better for reloading with debugs
        MinFpsForBeat = 16, -- below this fps, go into low fps mode
        LowFpsBeatFrames = math.floor(60 * 30 / 90), -- in frames per beat, (1 / beats per frame) = 60 * defaultfps / bpm
    }

    REVEL.RagtimeBalance.AnimsWithLeftAltInverted = {}
    for k, v in pairs(REVEL.RagtimeBalance.AnimsWithLeftAlt) do REVEL.RagtimeBalance.AnimsWithLeftAltInverted[v] = k end

    local DO_IDEBUG = true
    local EXPORT_GLOBALS = REVEL.DEBUG

    local States = {
        HIDDEN = "Hidden",
        APPEAR = "Appear",
        LIGHTS_OUT = "LightsOut",
        LEAD_DANCE = "LeadDance",
        TIRED = "Tired",
        DANCE_OFF = "DanceOff",
        ENCORE = "Encore",
        SHOWS_OVER = "ShowsOver",
    }

    local TargetDeco = {
        Sprite = "gfx/1000.030_dr. fetus target.anm2",
        Anim = "Blink",
        RemoveOnAnimEnd = false,
        Color1 = Color(1, 0, 0),
        Color2 = Color(1, 0, 1),
        Start = function(effect, data, sprite)
            sprite.PlaybackSpeed = 0.5
        end,
        Floor = true,
    }
    
    local TargetGlowDeco = {
        Sprite = "gfx/effects/revelcommon/glow_target.anm2",
        Anim = "Blink",
        RemoveOnAnimEnd = false,
        Color1 = Color(1, 0, 0),
        Color2 = Color(1, 0, 1),
        Start = function(effect, data, sprite)
            sprite.PlaybackSpeed = 0.5
        end,
        Floor = true,
    }

    local ConfettiParticles = REVEL.ParticleType.FromTable{
        Name = "Confetti Particle",
        Anm2 = "gfx/effects/revelcommon/particles_confetti.anm2",
        AnimationName = "particle",
        Variants = 7,
        BaseLife = 90,
        BaseColor = Color(1, 0.2, 0.2),
        HueRandom = 1,
        FadeOutStart = 0.1,
        StartScale = 0.55,
        EndScale = 0.55,
        ScaleRandom = 0.2,
        RotationSpeedMult = 2,
    }

    local ConfettiSystem = REVEL.PartSystem.FromTable{
        Name = "Confetti System",
        Gravity = 0.95,
        AirFriction = 0.97,
        Clamped = true
    }

    local ConfettiEmitter = REVEL.BoxEmitter(15, 10, 5)

    local ForcefullyNotGoOffBpm = false -- changed for first encounter

    -- Classes
    local RagtimeDancesMetadata
    local RagtimeDances
    local BoxDanceData
    local CongaDanceData

    local BoxDance
    local CongaDance

    -- Objects / variables / functions
    local RoomDances -- instance of RagtimeDances updated for each room
    local DanceTypes

    local SpawnDefaultDancer --function(index, dance, isShooter, isLeader)
    local DancerHopIndex -- function(dancer, toIndex, duration, animprefix, shoot, doOnLand)
    local DancerShootWarning -- function(dancer)

    -- Wrappers for music cue functions, in case I need to
    -- make them go off bpm for debug or other purposes
    local IsBeatTriggered -- function()
    local GetTriggeredBeatSets -- function()
    local GetNextBeats -- function(beatSetName, amount)

    local GetIndicesAround --function(index)

    -- Callbacks
    local NewRoomDancesMetadata

    local function MakeClass(tbl, superClass)
        setmetatable(tbl, {
            __call = function(self, ...) 
                local new = {}
                setmetatable(new, {__index = self})
                self.Init(new, ...)
                return new
            end, 
            __index = superClass
        })
        tbl.Base = superClass
        return tbl
    end

    -- Ragtime dances metadata handler, and conversion into own data
    do
        local MetaNameToClassName = {
            RagtimeBoxDance = "BoxDanceData",
            RagtimeConga = "CongaDanceData",
        }
        local ClassNameToClass = {} --Defined after each class


        -- ### RagtimeDancesMetadata ###

        RagtimeDancesMetadata = {}

        -- Work with metaentity subtypes (which are more cluttering in the editor) 
        -- until BR layers are a thing, which will then replace ids on the BR side
        -- (this function will stay the same)
        function RagtimeDancesMetadata:GetAllOfId(danceId, currentRoom)
            currentRoom = currentRoom or StageAPI.GetCurrentRoom()

            return currentRoom.Metadata:Search{
                Tag = "RagtimeDance",
                BitValues = {DanceID = danceId},
            }
        end

        function RagtimeDancesMetadata:SearchByID(danceId, otherParams, currentRoom)
            currentRoom = currentRoom or StageAPI.GetCurrentRoom()

            local params = {
                Tag = "RagtimeDance",
                BitValues = {DanceID = danceId},
            }

            for k, v in pairs(otherParams) do 
                params[k] = v 
            end

            return currentRoom.Metadata:Search(params)
        end

        function RagtimeDancesMetadata:GetDanceId(danceMeta)
            return danceMeta.BitValues.DanceID
        end

        function RagtimeDancesMetadata:GetRoomDanceIds(currentRoom)
            currentRoom = currentRoom or StageAPI.GetCurrentRoom()
            local dances = currentRoom.Metadata:Search{Tag = "RagtimeDanceCore"}

            local ids = {}
            local checked = {}

            for _, danceMeta in ipairs(dances) do
                local id = self:GetDanceId(danceMeta)
                if not checked[id] then
                    checked[id] = true
                    ids[#ids + 1] = id
                end
            end

            return ids
        end


        -- ### RagtimeDances ###

        -- Expects dance classes to have a DanceType field, and a constructor
        -- with a (id, danceMetaentities) signature

        RagtimeDances = MakeClass{
            Dances = nil, --{[id1] = dance1, [id2] = dance2, ...}

            Init = function(self, currentRoom)
                currentRoom = currentRoom or StageAPI.GetCurrentRoom()

                local avaiableIds = RagtimeDancesMetadata:GetRoomDanceIds(currentRoom)

                self.Dances = {}

                for _, id in ipairs(avaiableIds) do
                    local danceMetaCore = RagtimeDancesMetadata:SearchByID(id, {
                        Tag = "RagtimeDanceCore",
                    }, currentRoom)[1]
                    local danceType
                    if danceMetaCore then
                        danceType = MetaNameToClassName[danceMetaCore.Name]
                    end
                    if not danceType then
                        error("Ragtime: didn't specify main dance tile for dance id " .. tostring(id))
                    end

                    local danceMetaentities = RagtimeDancesMetadata:GetAllOfId(id, currentRoom)

                    local dance = ClassNameToClass[danceType](id, danceMetaentities)

                    self.Dances[id] = dance
                end

                self.SafeSpots = {}

                local playerSafeSpotMetaEnts = currentRoom.Metadata:Search{
                    Name = "RagtimePlayerSafeSpot",
                }
        
                -- index: dance id, value: list of indices safe from that dance
                -- close: includes indices adjacent to unsafe indices
                local safeIndicesFromDances = {}
                local safeIndicesFromDancesClose = {}
                local allSafeIndices = {}

                local w = REVEL.room:GetGridWidth()
                local offsets = {
                    -1
                    -w,
                    1,
                    w,
                }

                for id, dance in pairs(self.Dances) do
                    local safeIndices = {}
                    local safeIndicesClose = {}
                    
                    local unsafeIndices = dance:ListUnsafeStartIndices()
                    local closeIndicesMap = {}

                    for _, index in ipairs(unsafeIndices) do
                        for _, offset in pairs(offsets) do
                            local closeIdx = index + offset
                            if not REVEL.includes(unsafeIndices, closeIdx) then
                                closeIndicesMap[closeIdx] = true
                            end
                        end
                    end

                    for _, metaEntity in pairs(playerSafeSpotMetaEnts) do
                        local safespotIndex = metaEntity.Index
                        if not REVEL.includes(unsafeIndices, safespotIndex) then
                            -- Indices that are not close to dangerous index
                            if not closeIndicesMap[safespotIndex] then
                                safeIndices[#safeIndices+1] = safespotIndex
                            end
                            -- Safe indices but still close to dangerous index
                            safeIndicesClose[#safeIndicesClose+1] = safespotIndex
                        end
                    end

                    safeIndicesFromDances[id] = safeIndices
                    safeIndicesFromDancesClose[id] = safeIndicesClose
                end

                for _, metaEntity in pairs(playerSafeSpotMetaEnts) do
                    allSafeIndices[#allSafeIndices+1] = metaEntity.Index
                end

                self.SafeIndicesFromDances = safeIndicesFromDances
                self.SafeIndicesFromDancesClose = safeIndicesFromDancesClose
                self.AllSafeIndices = allSafeIndices
            end,

            GetOfIds = function(self, ids)
                local out = {}
                for _, id in pairs(ids) do
                    out[#out + 1] = self.Dances[id]
                end
                return out
            end,

            GetAvailableTypes = function(self)
                local types = {}

                for id, dance in pairs(self.Dances) do
                    if not REVEL.includes(types, dance.DanceType) then
                        types[#types + 1] = dance.DanceType
                    end
                end

                return types
            end,

            GetAllOfType = function(self, danceType, exceptIds)
                local matching, matchingNoConflicts = {}, {}

                local exceptDances = self:GetOfIds(exceptIds)

                for id, dance in pairs(self.Dances) do
                    if (not danceType or dance.DanceType == danceType) and not (exceptIds and REVEL.includes(exceptIds, dance.ID)) then
                        matching[#matching + 1] = dance

                        if not REVEL.some(exceptDances, function(dance2) return dance2:CheckConflicts(dance) end) then
                            matchingNoConflicts[#matchingNoConflicts + 1] = dance
                        end
                    end
                end

                if #matchingNoConflicts > 0 then
                    return matchingNoConflicts
                else
                    REVEL.DebugStringMinor("No non-conflicting dances found! Checked against " .. REVEL.ToString(exceptIds))
                    return matching
                end
            end,

            GetRandomOfType = function(self, danceType, exceptIds)
                return REVEL.randomFrom(self:GetAllOfType(danceType, exceptIds))
            end,

            GetRandom = function(self, exceptIds)
                return REVEL.randomFrom(self:GetAllOfType(nil, exceptIds))
            end,
        }


        -- ### Abstract Dance Data class

        DanceData = MakeClass{
            ID = -1,
            DanceType = "",

            ListUsedIndices = function(self)
                return {}
            end,

            ListUnsafeStartIndices = function(self)
                return {}
            end,

            -- returns true if the other dance conflicts with this once, 
            -- meaning they share an index
            CheckConflicts = function(self, otherDance)
                local selfIndices, otherIndices = self:ListUsedIndices(), otherDance:ListUsedIndices()
                for _, idx in pairs(selfIndices) do
                    if REVEL.keyOf(otherIndices, idx) then
                        return true
                    end
                end
                return false
            end,
        }

        -- ### BoxDance ###

        BoxDanceData = MakeClass({
            ID = -1,
            DanceType = "BoxDance",
            Start = nil, -- {Index: number, Rotation: number}
            JumpPoints = nil, -- {{Index: number, Rotation: number}, ...}

            Init = function(self, id, danceMetaentities) 
                danceMetaentities = danceMetaentities or RagtimeDancesMetadata:GetAllOfId(id)

                self.ID = id
                self.JumpPoints = {}

                for _, danceMeta in ipairs(danceMetaentities) do
                    if RagtimeDancesMetadata:GetDanceId(danceMeta) ~= id then
                        error("Tried creating box dance set with wrong dance id in metaentity" .. (debug and ("\n" .. debug.traceback()) or ""))
                    end
                    if danceMeta.Name == "RagtimeBoxDance" then
                        self.Start = {
                            Index = danceMeta.Index,
                            Rotation = danceMeta.BitValues.JumpRotation * 90,
                        }
                    elseif danceMeta.Name == "RagtimeBoxDancePoint" then
                        self.JumpPoints[#self.JumpPoints + 1] = {
                            Index = danceMeta.Index,
                            Rotation = danceMeta.BitValues.JumpRotation * 90,
                        }
                    end
                end
            end,

            GetPoints = function(self)
                local out = {self.Start}
                for _, jumpPoint in ipairs(self.JumpPoints) do
                    out[#out + 1] = jumpPoint
                end
                return out
            end,

            GetOtherPoints = function(self, exceptIndices)
                if type(exceptIndices) == "number" then exceptIndices = {exceptIndices} end

                local out = {}
                if not REVEL.includes(exceptIndices, self.Start.Index) then
                    out[#out + 1] = self.Start
                end

                for _, jumpPoint in ipairs(self.JumpPoints) do
                    if not REVEL.includes(exceptIndices, jumpPoint.Index) then
                        out[#out + 1] = jumpPoint
                    end
                end
                return out
            end,

            GetRandomJumpPoint = function(self, exceptIndices)
                if exceptIndices then
                    return REVEL.randomFrom(self:GetOtherPoints(exceptIndices))
                else
                    local maxRand = #self.JumpPoints + 1

                    local r = math.random(maxRand)
                    if r == maxRand then
                        return self.Start
                    else
                        return self.JumpPoints[r]
                    end
                end
            end,

            ListUsedIndices = function(self)
                local out = {}
                local w = REVEL.room:GetGridWidth()
                for _, point in ipairs(self:GetPoints()) do
                    out[#out + 1] = point.Index - w - 1
                    out[#out + 1] = point.Index - w
                    out[#out + 1] = point.Index - w + 1

                    out[#out + 1] = point.Index - 1
                    out[#out + 1] = point.Index
                    out[#out + 1] = point.Index + 1

                    out[#out + 1] = point.Index + w - 1
                    out[#out + 1] = point.Index + w
                    out[#out + 1] = point.Index + w + 1
                end
                return out
            end,

            ListUnsafeStartIndices = function(self)
                local out = {}
                local point = self.Start
                local w = REVEL.room:GetGridWidth()

                out[#out + 1] = point.Index - w - 1
                out[#out + 1] = point.Index - w
                out[#out + 1] = point.Index - w + 1

                out[#out + 1] = point.Index - 1
                out[#out + 1] = point.Index
                out[#out + 1] = point.Index + 1

                out[#out + 1] = point.Index + w - 1
                out[#out + 1] = point.Index + w
                out[#out + 1] = point.Index + w + 1

                return out
            end,
        }, DanceData)
        ClassNameToClass.BoxDanceData = BoxDanceData

        -- ### Conga ###

        CongaDanceData = MakeClass({
            ID = -1,
            DanceType = "Conga",
            Start = nil, -- {Index: number, Direction: number, PointsToIndex: number}
            PathPoints = nil, -- {{Index: number, Direction: number, PointsToIndex: number}, ...}

            Init = function(self, id, danceMetaentities) 
                danceMetaentities = danceMetaentities or RagtimeDancesMetadata:GetAllOfId(id)

                self.ID = id

                local points = {}

                for _, danceMeta in ipairs(danceMetaentities) do
                    if RagtimeDancesMetadata:GetDanceId(danceMeta) ~= id then
                        error("Tried creating conga set with wrong dance id in metaentity" .. (debug and ("\n" .. debug.traceback()) or ""))
                    end
                    if danceMeta.Name == "RagtimeConga" then
                        self.Start = {
                            Index = danceMeta.Index,
                            Direction = (danceMeta.BitValues.Direction * 45 + 90) % 360,
                        }
                    elseif danceMeta.Name == "RagtimeCongaPoint" then
                        points[#points + 1] = {
                            Index = danceMeta.Index,
                            Direction = (danceMeta.BitValues.Direction * 45 + 90) % 360,
                            IsEnd = danceMeta.BitValues.IsEnd ~= 0,
                        }
                    end
                end

                table.insert(points, 1, self.Start)

                for i, point1 in ipairs(points) do
                    for j, point2 in ipairs(points) do
                        if i ~= j and self:IsIndexInDirection(point1.Index, point1.Direction, point2.Index) then
                            point1.PointsToIndex = point2.Index
                            point1.PointsTo = j
                        end
                    end
                    if point1.IsEnd then
                        point1.PointsToIndex = nil
                        point1.PointsTo = nil
                        point1.Direction = -1
                    elseif point1.PointsToIndex == nil then
                        error("Ragtime: Couldn't find target point for conga dance at index " .. point1.Index .. " (direction is " .. point1.Direction .. "°)")
                    end
                end

                for i, point1 in ipairs(points) do
                    if not self.Start.Index == point1.Index and not REVEL.some(points, function(point2) return point2.PointsToIndex == point1.Index end) then
                        REVEL.DebugLog("Warning: Ragtime conga point at index " .. point1.Index .. " isn't pointed at by any other point")
                    end
                end

                self.PathPoints = points
       
                self.Path = {}
                local current = self.Start
                repeat
                    REVEL.extend(self.Path, table.unpack(self:CalcPath(current.Index, current.Direction, current.PointsToIndex)))
                    current = points[current.PointsTo]
                until current.IsEnd or current.Index == self.Start.Index -- ended or looped
                self.PathLoops = not current.IsEnd
            end,

            GetPoints = function(self)
                return self.PathPoints
            end,

            IsIndexInDirection = function(self, fromIndex, direction, checkIndex)
                -- nil = doesn't point to anything = is end tile
                if not direction then return false end

                local dirVector = REVEL.Round(Vector.FromAngle(direction))
                if dirVector.X ~= 0 then dirVector.X = sign(dirVector.X) end
                if dirVector.Y ~= 0 then dirVector.Y = sign(dirVector.Y) end
                
                local w = REVEL.room:GetGridWidth()

                local idx = fromIndex
                repeat  
                    idx = idx + dirVector.Y * w + dirVector.X
                    if idx == checkIndex then
                        return true
                    end
                until not REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(idx), 0)
                return false
            end,

            CalcPath = function(self, fromIndex, dir, toIndex)
                local path = {}

                local dirVector = REVEL.Round(Vector.FromAngle(dir))
                if dirVector.X ~= 0 then dirVector.X = sign(dirVector.X) end
                if dirVector.Y ~= 0 then dirVector.Y = sign(dirVector.Y) end
                local w = REVEL.room:GetGridWidth()

                local idx = fromIndex
                repeat
                    idx = idx + dirVector.Y * w + dirVector.X
                    path[#path + 1] = idx
                until idx == toIndex or not REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(idx), 0)
                if not REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(idx), 0) then
                    error("Ragtime: went out of room when calculating conga path! @" .. REVEL.ToStringMulti(fromIndex, dir, toIndex))
                end
                return path
            end,

            ListUsedIndices = function(self)
                return self.Path
            end,

            
            ListUnsafeStartIndices = function(self)
                local maxNum = REVEL.RagtimeBalance.CongaUnsafeZoneLength

                local out = {}
                
                for i = 1, maxNum do
                    out[#out+1] = self.Path[i]
                end

                return out
            end,
        }, DanceData)
        ClassNameToClass.CongaDanceData = CongaDanceData


        -- Callbacks

        function NewRoomDancesMetadata(currentRoom, isFirstLoad, isRagtimeRoom)
            if isRagtimeRoom then
                RoomDances = RagtimeDances(currentRoom)
                if REVEL.DEBUG then
                    _G.RagTimeRoomDances = RoomDances
                end

                if EXPORT_GLOBALS then
                    _G.RoomDances = RoomDances
                end

                REVEL.DebugStringMinor("RagTime | Loaded RoomDances\n")
            else
                RoomDances = nil
            end
        end
    end

    -- Ragtime dance handlers

    do
        local Dance = MakeClass{
            DanceType = "",
            Data = nil,
            Loop = false,
            Leaded = false,
            _didSetup = false,
            Boss = nil,
            bal = nil,
            bossbal = nil,
            SetupFrame = -1,
            Dancers = {},

            -- Set variables
            Init = function(self, data, boss, bal, loop)
                self.Data = data
                self.Boss = boss
                self.Dancers = {}
                self.bossbal = REVEL.GetData(boss).bal
                self.bal = bal
                if not loop then
                    self.Loop = bal.Loop
                else
                    self.Loop = loop
                end
                self._didSetup = false

                if self.bal.BeatPattern then
                    if #self.bal.BeatPattern % 4 ~= 0 then
                        REVEL.DebugLog("Warning: Ragtime attack pattern is not in multiples of 4, might be weird in the timing; type is", self.DanceType, "id is", self.Data.ID)
                    end

                    if (self.bal.StartProgressAtMeasure ~= nil and self.bal.StartProgressAtMeasure) or self.bossbal.StartProgressAtMeasure then
                        local nextMeasureCue = GetNextBeats(self.bossbal.MusicMapSetMeasure, 1)[1]
                        local nextCues = GetNextBeats(self.bossbal.MusicMapSetDefault, 4)
                        local beatsUntilMeasure = 1 --mind that 1 = next beat is new measure
    
                        while beatsUntilMeasure <= 4 and math.abs(nextCues[beatsUntilMeasure] - nextMeasureCue) > 1 do
                            beatsUntilMeasure = beatsUntilMeasure + 1
                        end
    
                        if beatsUntilMeasure > 4 then
                            REVEL.DebugLog("Warning: Ragtime cannot find next measure start to sync attack pattern; type is", self.DanceType, "id is", self.Data.ID, nextMeasureCue, nextCues)
                        else
                            local measureProgress = 5 - beatsUntilMeasure
                            self.BeatProgress = #self.bal.BeatPattern - 4 + measureProgress
                        end

                        if self.BeatProgress and self.BeatProgress > 1 then
                            self.NoShootUntil1 = true
                        end 
                    end
    
                    if not self.BeatProgress then
                        self.BeatProgress = 1
                    end
                end
            end,

            -- Actually do room affecting stuff (mostly enemy placement)
            Setup = function(self)
                REVEL.DebugStringMinor("Setup dance: type '" .. self.Data.DanceType .. "' ID ''" .. self.Data.ID)
                self._didSetup = true                         
                self.SetupFrame = REVEL.game:GetFrameCount()
            end,

            Update = function(self)
                if IsBeatTriggered() then
                    self:HandleBeat(GetTriggeredBeatSets())
                end   
                
                if self.Leaded and REVEL.GetData(self.Boss).LeadingDance ~= self then
                    REVEL.DebugLog("Warn: ragtime dance set as leaded with the dance not being actually leaded by him")
                end
            end,

            UpdateRagtimeLeader = function(self)
            end,

            HandleBeat = function(self, cuesetsTriggeredThisUpdate)
                -- REVEL.DebugStringMinor("Beat: '" .. REVEL.PrettyPrint(REVEL.keys(cuesetsTriggeredThisUpdate)) .. "'!")

                if self.bal.BeatPattern then
                    local action = self.bal.BeatPattern[self.BeatProgress]
                    local next = self.BeatProgress % #self.bal.BeatPattern + 1 --as usual, since lua arrays start at 0 to loop around you need % before
                    local nextAction = self.bal.BeatPattern[next]
                    if self.NoShootUntil1 and action == "Shoot" then
                        self:HandleDisabledShoot(cuesetsTriggeredThisUpdate, nextAction)
                    elseif action == "Idle" then
                        self:HandleIdle(cuesetsTriggeredThisUpdate, nextAction)
                    elseif action == "Move" then
                        self:HandleMove(cuesetsTriggeredThisUpdate, nextAction)
                    elseif action == "Shoot" then
                        self:HandleShoot(cuesetsTriggeredThisUpdate, nextAction)
                    end

                    if not self.NoShootUntil1 and nextAction == "Shoot" then
                        for _, dancer in ipairs(self.Dancers) do
                            DancerShootWarning(dancer)
                        end
                    end

                    self.BeatProgress = next
                    if self.NoShootUntil1 and self.BeatProgress == 1 then
                        self.NoShootUntil1 = nil
                    end
                end
            end,

            HandleIdle = function(self, cuesetsTriggeredThisUpdate, nextAction)
                -- REVEL.DebugLog("Idle beat!")
            end,

            HandleMove = function(self, cuesetsTriggeredThisUpdate, nextAction)
                -- REVEL.DebugLog("Move beat!")

            end,

            HandleShoot = function(self, cuesetsTriggeredThisUpdate, nextAction)
                -- REVEL.DebugLog("Shoot beat!")
            end,

            HandleDisabledShoot = function(self, cuesetsTriggeredThisUpdate, nextAction)
                -- REVEL.DebugLog("Shoot beat!")
                -- Default behavior, just do idle
                self:HandleIdle(cuesetsTriggeredThisUpdate, nextAction)
            end,

            Remove = function(self)
                REVEL.DebugStringMinor("Removing dance: type '" .. self.Data.DanceType .. "' ID ''" .. self.Data.ID)
            end,

            IsFinished = function(self, setname, cuesetsTriggeredThisUpdate)
                if self.Loop or not self._didSetup then
                    return false
                end
            end,

            ReviveDancers = function(self)
                for i, dancer in ipairs(self.Dancers) do
                    if dancer:IsDead() then
                        local newDancer = self:ReviveDancer(i)
                        if newDancer then
                            REVEL.SpawnPurpleThunder(newDancer)
                            self.Dancers[i] = newDancer
                        end
                    end
                end
                
            end,

            ReviveDancer = function(i)
            end,
        }

        BoxDance = MakeClass({
            DanceType = "BoxDance",
            CurrentIndices = {},
            CurrentDirection = 1,
            CurrentPoint = nil,
            NextPoint = nil,
            UsedPoints = {},
            JumpNextBeat = false,
            DoneLast = false,

            Init = function(self, data, boss, bal, loop)
                self.Base.Init(self, data, boss, bal, loop)
                self.CurrentIndices = {}
                self.CurrentDirection = 1
                self.CurrentPoint = {}
                self.NextPoint = {}
                self.UsedPoints = {}
                self.JumpNextBeat = false
            end,

            Setup = function(self)
                self.Base.Setup(self)

                self.Done = false

                local startPoint = self.Data.Start
                local w = REVEL.room:GetGridWidth()
                self.CurrentIndices = {
                    startPoint.Index - 1 - w, startPoint.Index - w, startPoint.Index + 1 - w, 
                    startPoint.Index + 1, 
                    startPoint.Index + 1 + w, startPoint.Index + w, startPoint.Index - 1 + w, 
                    startPoint.Index - 1, 
                }
                self.CurrentPoint = startPoint
                table.insert(self.UsedPoints, startPoint.Index)

                if DO_IDEBUG and IDebug then
                    IDebug.RenderUntilNext("RTime1", IDebug.RenderCircle, REVEL.room:GetGridPosition(startPoint.Index), nil, nil, nil, nil, Color(1, 0, 1, 0.5))
                end

                self:PickNextPoint()

                self.DancerInfo = {}

                local numShooters = REVEL.GetFromMinMax(self.bal.NumShooters)
                local dancers = REVEL.Range(#self.CurrentIndices)
                REVEL.Shuffle(dancers)
                local shooters = {}
                local leader

                for i = 1, numShooters do
                    shooters[dancers[i]] = true
                end

                if not self.Leaded then
                    leader = dancers[numShooters + 1]
                end

                for i, index in ipairs(self.CurrentIndices) do
                    self.Dancers[#self.Dancers + 1] = self:SpawnDancer(index, i, shooters[i], i == leader)
                    self.DancerInfo[i] = {
                        Shooter = shooters[i],
                        Leader = i == leader,
                        IndexNum = i
                    }
                end

                if self.Leaded then
                    self.Boss.Position = REVEL.room:GetGridPosition(startPoint.Index)
                    REVEL.GetData(self.Boss).BoxDanceIndex = startPoint.Index
                end
            end,

            PickNextPoint = function(self)
                self.NextPoint = nil

                if #self.UsedPoints == #self.Data:GetPoints() then
                    if self.Loop then
                        self.UsedPoints = {self.CurrentPoint.Index}
                    else
                        return
                    end
                end

                local newPoint = self.Data:GetRandomJumpPoint(self.UsedPoints)

                if newPoint then
                    self.NextPoint = newPoint
                    table.insert(self.UsedPoints, newPoint.Index)
                end
            end,

            Update = function(self)
                self.Base.Update(self)

                if self.DoneLastWait then
                    self.DoneLastWait = self.DoneLastWait - 1
                    if self.DoneLastWait <= 0 then
                        self.DoneLastWait = nil
                    end
                end
            end,

            HandleBeat = function(self, cuesetsTriggeredThisUpdate)
                self.Base.HandleBeat(self, cuesetsTriggeredThisUpdate)

                local nextAction = self.bal.BeatPattern[self.BeatProgress]

                if nextAction == "Move" and self.NextPoint then
                    local phase = REVEL.GetData(self.Boss).Phase
                    local decoDefinition = REVEL.GetRelativeDarkness() > 0.1 and TargetGlowDeco or TargetDeco

                    decoDefinition.Color = decoDefinition["Color" .. phase]

                    local nextIndices = GetIndicesAround(self.NextPoint.Index)
                    local rotation = self.NextPoint.Rotation - self.CurrentPoint.Rotation
                    local indexOffset = (rotation / 90 * 2) % 8 

                    -- safeguard
                    if self.WarningTargets then
                        for i, target in ipairs(self.WarningTargets) do
                            target:Remove()
                        end
                    end    

                    self.WarningTargets = {}

                    for _, dancer in ipairs(self.Dancers) do
                        if not dancer:IsDead() then
                            local data = dancer:GetData()

                            local nextNum = (data.IndexNum + indexOffset - 1) % #self.CurrentIndices + 1
                            local index = nextIndices[nextNum]
                            local target = REVEL.SpawnDecorationFromTable(REVEL.room:GetGridPosition(index), Vector.Zero, decoDefinition)
                            self.WarningTargets[#self.WarningTargets+1] = target
                        end
                    end
                end

                if self.BeatProgress >= #self.bal.BeatPattern
                and not self.NextPoint 
                and not self.DoneLast
                then
                    self.DoneLast = true

                    -- if there are 1/2 points, wait before finishing and stand on place a bit
                    local numPoints = #self.Data:GetPoints()
                    if numPoints == 2 then
                        self.DoneLastWait = 30 * 3
                    elseif numPoints == 1 then
                        self.DoneLastWait = 30 * 6
                    end
                end
            end,

            HandleIdle = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleIdle(self)

                -- local justStarted = REVEL.game:GetFrameCount() - self.SetupFrame < 5
                -- if cuesetsTriggeredThisUpdate[self.bossbal.MusicMapSetForceLeap] and not justStarted then
                --     self:HandleMove(cuesetsTriggeredThisUpdate)
                --     return
                -- end

                if cuesetsTriggeredThisUpdate[self.bossbal.MusicMapSetDefault] then
                    if self.bal.IdleMovesAround then
                        for i, dancer in ipairs(self.Dancers) do
                            if not dancer:IsDead() then
                                local index = self.CurrentIndices[dancer:GetData().IndexNum]
                                REVEL.UnlockGridIndex(index)
                            end
                        end
                        
                        for i, dancer in ipairs(self.Dancers) do
                            local indexNum = self.DancerInfo[i].IndexNum
                            local nextNum = (indexNum + self.CurrentDirection - 1) % #self.CurrentIndices + 1
                            self.DancerInfo[i].IndexNum = nextNum
    
                            if not dancer:IsDead() then
                                local data = dancer:GetData()
                                local toIndex = self.CurrentIndices[nextNum]

                                data.IndexNum = nextNum

                                DancerHopIndex(dancer, toIndex)
                            end
                        end
                    else
                        for i, dancer in ipairs(self.Dancers) do
                            if not dancer:IsDead() then
                                -- Hop on place
                                if math.random() < 0.45 then
                                    DancerHopIndex(dancer, self.CurrentIndices[dancer:GetData().IndexNum])
                                end
                            end
                        end
                    end
                end
            end,

            HandleMove = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleMove(self)

                local newPoint = self.NextPoint

                if newPoint then
                    for i, dancer in ipairs(self.Dancers) do
                        if not dancer:IsDead() then
                            local index = self.CurrentIndices[dancer:GetData().IndexNum]
                            REVEL.UnlockGridIndex(index)
                        end
                    end

                    local rotation = newPoint.Rotation - self.CurrentPoint.Rotation
                    local w = REVEL.room:GetGridWidth()
                    self.CurrentIndices = GetIndicesAround(newPoint.Index)
                    self.CurrentPoint = newPoint

                    self:PickNextPoint()

                    -- offset from current index of each dancer, to apply
                    -- the rotation between the jump points
                    local indexOffset = (rotation / 90 * 2) % 8 

                    for i, dancer in ipairs(self.Dancers) do
                        local indexNum = self.DancerInfo[i].IndexNum
                        local nextNum = (indexNum + indexOffset - 1) % #self.CurrentIndices + 1
                        self.DancerInfo[i].IndexNum = nextNum

                        if not dancer:IsDead() then
                            local data = dancer:GetData()
                            local toIndex = self.CurrentIndices[nextNum]

                            data.IndexNum = nextNum

                            DancerHopIndex(dancer, toIndex, self.bossbal.DancerLeapAnimDuration, "Leap", false, function()
                                if self.WarningTargets then
                                    for _, target in ipairs(self.WarningTargets) do
                                        target:Remove()
                                    end
                                    self.WarningTargets = nil
                                end
                            end)

                            if not self.NoShootUntil1 and nextAction == "Shoot" then
                                -- overrides base dance warning duration
                                DancerShootWarning(dancer, self.bossbal.DancerLeapAnimDuration)
                            end
                        end
                    end
                else
                    self:HandleIdle(cuesetsTriggeredThisUpdate)
                end
            end,

            HandleShoot = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleShoot(self)

                for i, dancer in ipairs(self.Dancers) do
                    if not dancer:IsDead() then
                        local data = dancer:GetData()
                        local index = self.CurrentIndices[data.IndexNum]

                        DancerHopIndex(dancer, index, nil, nil, true)
                    end
                end

                if self.Leaded then
                    self.Boss:GetSprite():Play("HatTip", true)
                end
            end,

            UpdateRagtimeLeader = function(self)
                local data, sprite = REVEL.GetData(self.Boss), self.Boss:GetSprite()

                local nextCues = GetNextBeats(self.bossbal.MusicMapSetDefault, #self.bal.BeatPattern)
                local beatsUntilJump -- 1 = next beat
                local nextMoveIndices = REVEL.filter(REVEL.keysOf(self.bal.BeatPattern, "Move"), 
                    function(idx) return idx >= self.BeatProgress end
                )
                if #nextMoveIndices == 0 then
                    local moveIndex = REVEL.indexOf(self.bal.BeatPattern, "Move")
                    if moveIndex then
                        beatsUntilJump = #self.bal.BeatPattern + 1 - self.BeatProgress + moveIndex
                    end
                else
                    beatsUntilJump = math.min(table.unpack(nextMoveIndices)) - self.BeatProgress
                end
                beatsUntilJump = math.max(beatsUntilJump, 1)

                if beatsUntilJump then
                    local resetPath = false
                    local timeForNextLeap = nextCues[beatsUntilJump]

                    if self.NextPoint then
                        local bossIndex = REVEL.room:GetGridIndex(self.Boss.Position)
                        local longPathToNext = REVEL.GeneratePathAStar(bossIndex, self.NextPoint.Index)
                        local pathToNext = REVEL.GetDirectPath(longPathToNext)
                        local nextDist = REVEL.GetPathLength(pathToNext)
                        local speed = math.min(9, nextDist / 30)
                        local timeToGoNext = nextDist / speed * 1000 / 30
                        local waitTime = 250

                        if data.BoxDanceIndex ~= self.NextPoint.Index and timeForNextLeap <= timeToGoNext + waitTime then
                            data.BoxDanceIndex = self.NextPoint.Index
                            data.BoxDancePathToNext = pathToNext
                            data.Speed = speed
                            resetPath = true
                        end
                    else
                        data.Speed = 0
                    end

                    local dancePos = REVEL.room:GetGridPosition(data.BoxDanceIndex)

                    if DO_IDEBUG and IDebug then
                        IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, dancePos, nil, nil, nil, nil, Color(0, 1, 0, 0.1))
                    end

                    local d = dancePos:Distance(self.Boss.Position)
                    local speed = math.min(data.Speed or 5, d)

                    if data.BoxDancePathToNext then
                        if IDebug and DO_IDEBUG then
                            IDebug.RenderListOfGridsUntilNextUpdate(data.BoxDancePathToNext)
                        end
                        local done = REVEL.FollowPath(
                            self.Boss, speed, data.BoxDancePathToNext,
                            true, 0, true, 
                            nil, nil, nil,
                            resetPath
                        )
                        if done then
                            data.BoxDancePathToNext = nil
                            data.PathIndex = nil
                        end
                    else
                        self.Boss.Velocity = (dancePos - self.Boss.Position) * speed / (d + 0.001)
                    end

                    if not sprite:IsPlaying("HatTip") then
                        if self.Boss.Velocity:Length() < 1 then
                            if not REVEL.MultiPlayingCheck(sprite, "Dance_1", "Dance_2", "Dance_3") then
                                local anims = {1, 2, 3}
                                table.remove(anims, data.CurDanceAnim)
                                data.CurDanceAnim = REVEL.randomFrom(anims)
                                sprite:Play("Dance_" .. data.CurDanceAnim, true)        
                            end
                        else
                            REVEL.AnimateWalkFrameSpeed(sprite, self.Boss.Velocity, {Right = "WalkHori", Left = "WalkLeft", Vertical = "WalkVert"})
                        end
                    end
                else
                    self.Boss.Velocity = self.Boss.Velocity * 0.7
                end
            end,

            Remove = function(self)
                self.Base.Remove(self)

                for i, dancer in ipairs(self.Dancers) do
                    dancer:Remove()
                end

                if self.WarningTargets then
                    for i, target in ipairs(self.WarningTargets) do
                        target:Remove()
                    end
                end
            end,

            IsFinished = function(self)
                local baseRet = self.Base.IsFinished(self)
                if baseRet ~= nil then return baseRet end

                return self.DoneLast and not self.DoneLastWait
            end,

            SpawnDancer = function(self, index, indexNum, shooter, leader)
                local dancer = SpawnDefaultDancer(self, index, shooter, leader)

                local data = dancer:GetData()
                data.State = "Stay_Index"
                data.Index = index
                data.IndexNum = indexNum

                dancer.MaxHitPoints = dancer.MaxHitPoints * 0.5
                dancer.HitPoints = dancer.MaxHitPoints

                return dancer
            end,

            ReviveDancer = function(self, i)
                local info = self.DancerInfo[i]

                local index = self.CurrentIndices[info.IndexNum]
                local shooter = not info.Leader and math.random() < 0.33
                local dancer = self:SpawnDancer(index, info.IndexNum, shooter, info.Leader)

                return dancer
            end,
        }, Dance)

        CongaDance = MakeClass({
            DanceType = "Conga",

            Init = function(self, data, boss, bal, loop)
                self.Base.Init(self, data, boss, bal, loop)
            end,

            Setup = function(self)
                self.Base.Setup(self)

                self.Path = self.Data.Path
                self.PathLoops = self.Data.PathLoops

                -- IDebug.ClearRender("rag")
                -- IDebug.RenderListOfGridsUntilCleared(self.Path, "rag")

                self.DancerInfo = {}

                local numDancers = REVEL.GetFromMinMax(self.bal.NumDancers)
                local numShooters = REVEL.GetFromMinMax(self.bal.NumShooters)
                local dancers 
                
                if self.Leaded then
                    dancers = REVEL.Range(numDancers)
                else
                -- Leader always has first place
                    dancers = REVEL.Range(2, numDancers)
                end

                REVEL.Shuffle(dancers)
                local shooters = {}
                for i = 1, numShooters do
                    shooters[dancers[i]] = true
                end

                for i = 1, numDancers do
                    local j = numDancers + 1 - i
                    self.Dancers[#self.Dancers + 1] = self:SpawnDancer(self.Path[j], j, shooters[i], not self.Leaded and i == 1)
                    self.DancerInfo[i] = {
                        Shooter = shooters[i],
                        Leader = not self.Leaded and i == 1,
                        IndexNum = j
                    }
                end
                
                self.CurrentIndex = numDancers
                self.CurrentDirection = 1

                if self.Leaded then
                    self.Boss.Position = REVEL.room:GetGridPosition(self.Path[numDancers + 1])
                    REVEL.GetData(self.Boss).ChangeAnimTimer = nil
                    self.BossPathIndex = numDancers + 1
                end
            end,

            HandleIdle = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleIdle(self, cuesetsTriggeredThisUpdate, nextAction)

                for i, dancer in ipairs(self.Dancers) do
                    if not dancer:IsDead() then
                        -- Hop on place
                        if math.random() < 0.45 then
                            DancerHopIndex(dancer, self.Path[dancer:GetData().IndexNum])
                        end
                    end
                end
            end,

            HandleMove = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleMove(self, cuesetsTriggeredThisUpdate, nextAction)
                self:MoveConga(false)
            end,

            HandleShoot = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleShoot(self, cuesetsTriggeredThisUpdate, nextAction)
                self:MoveConga(true)

                if self.Leaded then
                    self.Boss:GetSprite():Play("HatTip", true)
                    self.ChangeAnimTimer = nil
                end
            end,

            HandleDisabledShoot = function(self, cuesetsTriggeredThisUpdate, nextAction)
                -- move on the first measure if starting in middle
                self:HandleMove(cuesetsTriggeredThisUpdate, nextAction)
            end,

            HandleBeat = function(self, cuesetsTriggeredThisUpdate, nextAction)
                self.Base.HandleBeat(self, cuesetsTriggeredThisUpdate, nextAction)

                if self.DoneCountdown and self.DoneCountdown > 0 then
                    self.DoneCountdown = self.DoneCountdown - 1
                    if self.DoneCountdown <= 0 then
                        self.Done = true
                    end
                end
            end,

            MoveConga = function(self, shoot)
                local reachedEnd = not self.PathLoops and (
                    (self.Dancers[1]:GetData().IndexNum == #self.Path and self.CurrentDirection > 0)
                    or (self.Dancers[1]:GetData().IndexNum == 1 and self.CurrentDirection < 0)
                )
                local doMove = self.Loop or not reachedEnd

                if doMove and self.Leaded 
                and (
                    (self.Done or self.DoneCountdown) 
                    or REVEL.GetData(self.Boss).State == States.TIRED
                )
                then
                    doMove = false
                end

                if doMove then 
                    if self.Leaded then
                        if self.BossPathIndex >= #self.Path and not self.PathLoops then
                            self.BossPathIndex = self.BossPathIndex + 1 -- after path it interpolates from last path indices
                        else
                            self.BossPathIndex = self.BossPathIndex % #self.Path + 1
                        end
                    end
                    -- Assume that self.Loop can't be true at the 
                    -- same time as self.Leaded
                    local increase = self.CurrentDirection
                    if self.Loop and reachedEnd then
                        -- change direction and set current index to the one leading the dancers
                        self.CurrentDirection = -self.CurrentDirection
                        increase = self.CurrentDirection * (#self.Dancers - 1)
                    end
                    -- lua and its goddarn arrays from 1
                    self.CurrentIndex = (self.CurrentIndex + increase - 1) % #self.Path + 1
                end
                
                -- #self.Dancers -1: it starts at #self.Dancers, in case it loops
                -- if leaded, stop the tile before to leave rag time a tile to rest
                local endedPath
                if self.Leaded then 
                    endedPath = self.CurrentIndex == #self.Path - 1
                else
                    endedPath = self.CurrentIndex == #self.Path
                end
                
                if (self.CurrentIndex == #self.Dancers - 1 or endedPath) 
                and not self.DoneCountdown and not self.Done then
                    self.DoneCountdown = 2
                end

                for i, dancer in ipairs(self.Dancers) do
                    if not dancer:IsDead() then
                        local index = self.Path[dancer:GetData().IndexNum]
                        REVEL.UnlockGridIndex(index)
                    end
                end

                for i, dancer in ipairs(self.Dancers) do
                    local indexNum = self.DancerInfo[i].IndexNum
                    local nextNum = (indexNum + self.CurrentDirection - 1) % #self.Path + 1
                    if not doMove then
                        nextNum = indexNum
                    elseif self.Loop and reachedEnd then
                        if i == 1 then --leader
                            nextNum = self.CurrentIndex
                        else -- keep moving in the old direction for 1 beat
                            nextNum = (indexNum - self.CurrentDirection - 1) % #self.Path + 1
                        end
                    end
                    self.DancerInfo[i].IndexNum = nextNum

                    if not dancer:IsDead() then
                        local data = dancer:GetData()
                        local currentIndex = REVEL.room:GetGridIndex(dancer.Position)
                        local toIndex = self.Path[nextNum]

                        data.IndexNum = nextNum
    
                        local animPrefix = "Hop"
                        local duration = nil
                        if currentIndex ~= toIndex and not REVEL.includes(GetIndicesAround(currentIndex), toIndex) then
                            animPrefix = "Leap"
                            duration = self.bossbal.DancerLeapAnimDuration
                        end

                        DancerHopIndex(dancer, toIndex, duration, animPrefix, shoot)
                    end
                end
            end,

            UpdateRagtimeLeader = function(self)
                local data, sprite = REVEL.GetData(self.Boss), self.Boss:GetSprite()
                
                local numAvgPoints = 3

                local nextPointsTotDistance = 0
                local currentIndex, num = self.CurrentIndex, nil
                for i = 1, numAvgPoints do
                    local nextNum = currentIndex % #self.Path + 1
                    nextPointsTotDistance = nextPointsTotDistance + REVEL.room:GetGridPosition(self.Path[currentIndex]):Distance(REVEL.room:GetGridPosition(self.Path[nextNum]))
                    currentIndex = nextNum
                    num = i
                    if nextNum == #self.Path and not self.PathLoops then
                        break
                    end
                end
                local avgDist = nextPointsTotDistance / num

                local nextCuesExact = GetNextBeats(self.bossbal.MusicMapSetDefault, 2, true)
                local timeBetween = nextCuesExact[2] - nextCuesExact[1]
                local avgSpeed = avgDist / (timeBetween * 30 / 1000)

                if self.bal.MovesEachTwoBeats then
                    avgSpeed = avgSpeed / 2
                end

                local targPos
                if self.BossPathIndex > #self.Path then
                    local diff = REVEL.room:GetGridPosition(self.Path[#self.Path]) - REVEL.room:GetGridPosition(self.Path[#self.Path - 1])
                    if math.abs(diff.X) > 0.001 then diff.X = 40 * sign(diff.X) end
                    if math.abs(diff.Y) > 0.001 then diff.Y = 40 * sign(diff.Y) end

                    targPos = REVEL.room:GetGridPosition(self.Path[#self.Path]) + diff * (self.BossPathIndex - #self.Path)
                else
                    targPos = REVEL.room:GetGridPosition(self.Path[self.BossPathIndex])
                end
                local targIndex = REVEL.room:GetGridIndex(targPos)

                local resetPath = false
                -- New target index, recalculate path
                if data.CongaLastTargIndex ~= targIndex then 
                    local bossIndex = REVEL.room:GetGridIndex(self.Boss.Position)
                    local path = REVEL.GeneratePathAStar(bossIndex, targIndex)
                    -- local directPath = REVEL.GetDirectPath(pathToTarg)

                    -- calculate distance and speed based on that? would complicate things a bunch
                    -- with the avg speed above, for now don't

                    if #path == 0 then
                        data.CongaPathToNext = nil
                    else
                        data.CongaPathToNext = path
                        resetPath = true
                    end
                    data.CongaLastTargIndex = targIndex
                end

                local accelMult = 1
                local friction = 0
                local diff = targPos - self.Boss.Position
                local l = diff:Length()

                if data.CongaPathToNext then
                    local done = REVEL.FollowPath(
                        self.Boss, math.min(avgSpeed * accelMult, l), data.CongaPathToNext,
                        true, friction, true,
                        nil, nil, nil,
                        resetPath
                    )
                    if done then
                        data.PathIndex = nil
                        data.CongaPathToNext = nil
                    end
                else
                    self.Boss.Velocity = diff * math.min(avgSpeed * accelMult, l) / math.max(l, 0.001) + self.Boss.Velocity * friction
                end
    
                if not data.ChangeAnimTimer and not sprite:IsPlaying("HatTip") then
                    local anims = {1, 2, 3}
                    if data.PrevAnim then table.remove(anims, data.PrevAnim) end
                    local newAnim = REVEL.randomFrom(anims)
                    sprite:Play("Dance_" .. newAnim, true)
    
                    data.PrevAnim = newAnim
                    data.ChangeAnimTimer = StageAPI.Random(90, 150)
                elseif sprite:IsPlaying("HatTip") then
                    data.ChangeAnimTimer = nil
                end    
            end,

            Remove = function(self)
                self.Base.Remove(self)

                for i, dancer in ipairs(self.Dancers) do
                    dancer:Remove()
                end

                if self.Leaded then
                    REVEL.GetData(self.Boss).CongaLastTargIndex = nil
                end
            end,

            IsFinished = function(self)
                local baseRet = self.Base.IsFinished(self)
                if baseRet ~= nil then return baseRet end

                return self.Done
            end,

            SpawnDancer = function(self, index, indexNum, shooter, leader)
                local dancer = SpawnDefaultDancer(self, index, shooter, leader)

                local data = dancer:GetData()
                data.State = "Stay_Index"
                data.Index = index
                data.IndexNum = indexNum

                return dancer
            end,

            ReviveDancer = function(self, i)
                local info = self.DancerInfo[i]

                local index = self.Path[info.IndexNum]
                local shooter = not info.Leader and math.random() < 0.33
                local dancer = self:SpawnDancer(index, info.IndexNum, shooter, info.Leader)

                return dancer
            end,
        }, Dance)

        DanceTypes = {
            BoxDance = BoxDance,
            Conga = CongaDance,
        }
    end


    -- Npc logic

    local function LeadDance(npc, dance)
        REVEL.GetData(npc).LeadingDance = dance
        dance.Leaded = true
    end

    local function StopLeadingDance(npc)
        REVEL.GetData(npc).LeadingDance.Leaded = false
        REVEL.GetData(npc).LeadingDance = nil
    end

    local function StartDance(npc, phase, forceLoop)
        if not RoomDances then
            error("Ragtime.StartDance | called before RoomDances initialized", 2)
        end

        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
        local currentIds = REVEL.map(data.CurrentDances, function(dance) return dance.Data.ID end)

        local chosenDanceData = RoomDances:GetRandom(currentIds)
        REVEL.DebugStringMinor("Chosen dance", chosenDanceData.DanceType, "from", RoomDances:GetAvailableTypes())
        local dance = DanceTypes[chosenDanceData.DanceType](chosenDanceData, npc, data.bal[chosenDanceData.DanceType .. phase], phase == 2 or forceLoop)
        return dance
    end

    local function ReflectTears(npc)
        -- Search all tears to account for very big tears
        for _, tear in ipairs(REVEL.roomTears) do
            if tear.Position:DistanceSquared(npc.Position) < (npc.Size + tear.Size + 15) ^ 2 then
                local s = tear.Velocity:Length()
                tear.Velocity = (npc:GetPlayerTarget().Position - tear.Position):Resized(s)
            end 
        end

        local closeBullets = Isaac.FindInRadius(npc.Position, npc.Size + 25, EntityPartition.BULLET)
        for _, bullet in ipairs(closeBullets) do
            local s = bullet.Velocity:Length()
            bullet.Velocity = (npc:GetPlayerTarget().Position - bullet.Position):Resized(s):Rotated(math.random(-30, 30))
        end
    end

    local function ResetDances(npc, sprite, data, spawnNew, forceNoLead, forceLoop)
        for _, dance in ipairs(data.CurrentDances) do
            dance:Remove()
        end

        data.CurrentDances = {}

        if spawnNew then
            local amount = REVEL.GetFromMinMax(data.bal.LightsOut.NumDances)
            for i = 1, amount do
                data.CurrentDances[i] = StartDance(npc, data.Phase, forceLoop)
                if i == 1 and data.Phase == 1 and not forceNoLead then
                    LeadDance(npc, data.CurrentDances[i])
                end
                data.CurrentDances[i]:Setup()
            end
        end
    end

    ---@return EntityPlayer[][]
    local function GetPlayerGroups()
        local checked = {}
        local groups = {}

        for _, player in ipairs(REVEL.players) do
            if not checked[GetPtrHash(player)] then
                local group = {player}
                if player:GetOtherTwin() then
                    group[#group+1] = player:GetOtherTwin()
                end
                for _, player2 in ipairs(group) do
                    checked[GetPtrHash(player2)] = true
                end
                
                table.insert(groups, group)
            end
        end

        return groups
    end

    local function GetPlayerSafePositions(dances, num)
        local positions = {}

        if dances and #dances > 0 then
            local safeIndices = {} -- RoomDances.SafeIndicesFromDances
            local safeIndicesClose = {} -- RoomDances.SafeIndicesFromDancesClose
    
            -- Find indices that are safe for all dances
            -- (aka contained in all dances' safe index table)
            for i, dance in ipairs(dances) do
                local id = dance.Data.ID

                if not RoomDances.SafeIndicesFromDances[id] then
                    error("Ragtime: doesn't have safe indices for dance " .. tostring(id))
                end

                local thisSafeIndices = REVEL.toSet(RoomDances.SafeIndicesFromDances[id])
                local thisSafeIndicesClose = REVEL.toSet(RoomDances.SafeIndicesFromDancesClose[id])

                if i == 1 then
                    safeIndices = thisSafeIndices
                    safeIndicesClose = thisSafeIndicesClose
                else
                    -- Remove indices that aren't safe for another dance
                    for prevIndex, _ in pairs(safeIndices) do
                        if not thisSafeIndices[prevIndex] then
                            safeIndices[prevIndex] = nil
                        end
                    end
                    for prevIndex, _ in pairs(safeIndicesClose) do
                        if not thisSafeIndicesClose[prevIndex] then
                            safeIndicesClose[prevIndex] = nil
                        end
                    end
                end
            end

            -- Choose different indices if possible, else reuse them
            local avaiableSafeIndices = REVEL.CopyTable(safeIndices)
            local avaiableSafeIndicesClose = REVEL.CopyTable(safeIndicesClose)

            for i = 1, num do
                local index
                if not REVEL.isEmpty(avaiableSafeIndices) then
                    index = REVEL.RandomFromSet(avaiableSafeIndices)
                    avaiableSafeIndices[index] = nil
                    avaiableSafeIndicesClose[index] = nil
                elseif not REVEL.isEmpty(avaiableSafeIndicesClose) then
                    index = REVEL.RandomFromSet(avaiableSafeIndicesClose)
                    avaiableSafeIndicesClose[index] = nil
                elseif not REVEL.isEmpty(safeIndices) then
                    index = REVEL.RandomFromSet(safeIndices)
                elseif not REVEL.isEmpty(safeIndicesClose) then
                    index = REVEL.RandomFromSet(safeIndicesClose)
                else
                    index = REVEL.room:GetGridIndex(
                        REVEL.room:FindFreePickupSpawnPosition(
                            REVEL.room:GetCenterPos(), 
                            20, 
                            true
                        )
                    )
                    REVEL.DebugStringMinor("Ragtime: Safe index not found! Used random index", index)
                end
                REVEL.DebugStringMinor("Ragtime: selected safe index", index)
                positions[i] = REVEL.room:GetGridPosition(index)
            end
        else
            local safeIndices = RoomDances.AllSafeIndices

            local avaiableSafeIndices = REVEL.toSet(safeIndices)

            for i = 1, num do
                local index
                if not REVEL.isEmpty(avaiableSafeIndices) then
                    index = REVEL.RandomFromSet(avaiableSafeIndices)
                    avaiableSafeIndices[index] = nil
                elseif not REVEL.isEmpty(safeIndices) then
                    index = REVEL.randomFrom(safeIndices)
                else
                    index = REVEL.room:GetGridIndex(
                        REVEL.room:FindFreePickupSpawnPosition(
                            REVEL.room:GetCenterPos(), 
                            20, 
                            true
                        )
                    )
                    REVEL.DebugStringMinor("Ragtime: Safe index not found! Used random index", index)
                end
                REVEL.DebugStringMinor("Ragtime: Selected safe index", index)
                positions[i] = REVEL.room:GetGridPosition(index)
            end
        end

        return positions
    end

    local RagtimeDanceoffMap = REVEL.NewPathMapFromTable("RagtimeDanceoff", {
        GetTargetSets = function()
            local targets = {}
            local ragtimes = REVEL.ENT.RAGTIME:getInRoom()

            for i, npc in ipairs(ragtimes) do
                targets[#targets + 1] = REVEL.room:GetGridIndex(npc:ToNPC():GetPlayerTarget().Position)
            end

            local targetSets = {{Targets = targets}}

            return targetSets
        end,

        GetInverseCollisions = function()
            return REVEL.GetPassableGrids(true, true, false, false)
        end,

        OnPathUpdate = function(map)
            local ragtimes = REVEL.ENT.RAGTIME:getInRoom()

            for _, npc in ipairs(ragtimes) do
                local data = REVEL.GetData(npc)

                if data.Phase == 2 then
                    data.Path = REVEL.GeneratePathAStar(REVEL.room:GetGridIndex(npc.Position), map.TargetMapSets[1].FarthestIndex)
                    data.PathIndex = nil

                    if data.Path and #data.Path == 0 then
                        data.Path = nil
                    end
                end
            end
        end
    })

    local Phase2SpotlightColor = Color(1, 0, 1)
    local LeadDancerSpotlightColor = Color(1, 0, 1, 0.75)
    local AreaSpotlightColor = Color(1, 0, 1, 0.4)

    local function LightsOutSpawn(npc, sprite, data, postDeath)
        -- REVEL.ResumeMusicCuesTrack()

        for _, proj in ipairs(REVEL.roomProjectiles) do
            proj:Remove()
        end
        for _, tear in ipairs(REVEL.roomTears) do
            tear:Remove()
        end

        if data.LeadingDance then
            StopLeadingDance(npc)
        end

        if not postDeath then
            -- Screen is dark, clear previous dances and setup new ones
            ResetDances(npc, sprite, data, not (data.NextFinale or data.NextEncore))
        end

        REVEL.SetTombLightShaderAlpha(0)

        if not postDeath then
            if data.PhaseSwitchOnLight then
                data.PhaseSwitchOnLight = nil
                npc:ClearEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)

                local w, h = REVEL.GetRoomSize()

                REVEL.SpawnMultiSpotlights(AreaSpotlightColor, w * 0.28, h * 0.28, 3, 0, 5, nil, nil, 1.5)       
            end

            local darkAroundSpotlight = data.NextFinale or data.Phase < 2
            -- don't override last to make both lights out spotlight and phase 2 spotlight coexist
            local noOverrideLast = true
            data.Spotlight = EntityPtr(REVEL.SpawnEntSpotlight(Color.Default, npc, nil, false, darkAroundSpotlight, nil, noOverrideLast))
            REVEL.sfx:Play(REVEL.SFX.SPOTLIGHT)

            if data.Phase >= 2 then
                local extraSpotlightCheck = {npc}
                REVEL.extend(extraSpotlightCheck, table.unpack(REVEL.players))
                local rag_dancers = REVEL.ENT.RAG_DANCER:getInRoom()
                for _, entity in ipairs(rag_dancers) do
                    if entity:GetData().IsLeader then
                        extraSpotlightCheck[#extraSpotlightCheck+1] = entity
                    end
                end

                for _, entity in ipairs(extraSpotlightCheck) do
                    if not (entity:GetData().RagtimeExtraSpotlight
                    and entity:GetData().RagtimeExtraSpotlight.Ref) then
                        local color = Color.Default
                        if npc == entity then
                            color = Phase2SpotlightColor
                        elseif REVEL.ENT.RAG_DANCER:isEnt(entity) then
                            color = LeadDancerSpotlightColor
                        end

                        local spotExtra = REVEL.SpawnEntSpotlight(color, entity)
                        if npc == entity then
                            spotExtra:GetData().ForceWhenEntInvisible = true
                        elseif REVEL.ENT.RAG_DANCER:isEnt(entity) then
                            REVEL.SetSpotlightSizeMult(spotExtra, 0.75)
                        end
                        entity:GetData().RagtimeExtraSpotlight = EntityPtr(spotExtra)
                    end
                end
            end
        end

        local players = REVEL.players
        local playerGroups = GetPlayerGroups()
        local safePosNum = #playerGroups
        if data.Phase == 2 then
            safePosNum = safePosNum + 1 --include ragtime
        end

        local playerPositions = GetPlayerSafePositions(data.CurrentDances, safePosNum)

        for i, group in ipairs(playerGroups) do
            for j, player in ipairs(group) do
                local off = Vector((#playerGroups - 1) * 10, 0):Rotated(j * 360 / #playerGroups)
                player.Position = playerPositions[i] + off
            end
        end

        -- local forgottenSkeletons = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.FORGOTTEN_BODY)
        -- for _, skeleton in ipairs(forgottenSkeletons) do
        --     skeleton.Position = skeleton:ToFamiliar().Player.Position
        -- end

        -- boot all forgotten players out of soul mode
        -- as body cannot be moved by lua
        for i, player in ipairs(players) do
            if player:GetPlayerType() == PlayerType.PLAYER_THESOUL 
            and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
            then
                REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, true)
            end
        end
        -- get players again if it changed
        players = REVEL.players

        local knives = Isaac.FindByType(EntityType.ENTITY_KNIFE)
        for _, knife in ipairs(knives) do
            if knife.SpawnerType == EntityType.ENTITY_PLAYER then
                knife.Position = knife.SpawnerEntity.Position
            end
        end

        local firstPlayerExtraSpotlight = players[1]:GetData().RagtimeExtraSpotlight and players[1]:GetData().RagtimeExtraSpotlight.Ref

        if firstPlayerExtraSpotlight then
            firstPlayerExtraSpotlight:GetData().ForcePosition = players[1].Position
            firstPlayerExtraSpotlight:GetData().ForceVelocity = Vector.Zero
            firstPlayerExtraSpotlight:GetData().ForceWhenEntInvisible = players[1].Position
        end

        for _, player in ipairs(players) do
            REVEL.LockPlayerControls(player, "RagtimeLightsout")
        end

        data.FirstPlayerPos = players[1].Position
        REVEL.PlayerCameraMode(players[1])

        players[1].Position = npc.Position

        if not postDeath then
            data.SpotlightStandStill = true
            if data.NextAppear then
                data.NextAppear = nil
                sprite:Play("Appear", true)
                data.State = States.APPEAR
                npc.Visible = true
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                StageAPI.PlayTextStreak(REVEL.player:GetName() .. " VS Ragtime")
                revel.data.ragtimeSeenSpecialIntro = true

                REVEL.PlaySound(data.bal.Sounds.ClappingFade)
            elseif data.NextEncore then
                data.State = States.ENCORE
                data.NextEncore = nil
                npc.Position = data.StartPosition
                npc.HitPoints = math.max(npc.HitPoints, 3)

            elseif data.NextFinale then
                data.State = States.SHOWS_OVER
                data.KeepDark = nil
                data.NextFinale = nil
                npc.Position = data.StartPosition

            elseif data.Phase == 1 then
                -- Change state, timer continues out of state (see above)
                data.State = States.LEAD_DANCE
            else
                npc.Position = playerPositions[#playerPositions]

                if not REVEL.IsUsingPathMap(RagtimeDanceoffMap, npc) then
                    REVEL.UsePathMap(RagtimeDanceoffMap, npc)
                end

                data.State = States.DANCE_OFF
            end
        end
    end

    local function LightsOutFreePlayers(cameraPlayer)
        REVEL.StopPlayerCameraMode(cameraPlayer, true)
        for _, player in ipairs(REVEL.players) do
            REVEL.UnlockPlayerControls(player, "RagtimeLightsout")
        end
    end

    -- postDeath: only spotlight/player/dark stuff
    local function HandleLightsOut(npc, sprite, data, postDeath)
        local lbal = data.bal.LightsOut

        local fullDarkOnTime = math.floor(lbal.Duration * lbal.FullDarkOnTime)
        local spawnTime = math.floor(lbal.Duration * lbal.SpawnTime)
        local fullDarkOffTime = math.floor(lbal.Duration * lbal.FullDarkOffTime)

        -- local playerSpotlightTime = math.floor(lbal.Duration * 0.45)
        local spotlightEnlargeTime = math.floor(lbal.Duration * lbal.SpotlightEnlargeTime)
        local playerCameraMoveTime = math.floor(lbal.Duration * lbal.PlayerCameraMoveTime)
        local phaseStartTime = math.floor(lbal.Duration * lbal.PhaseStartTime)
        local spotlightFadeTime = math.floor(lbal.Duration * lbal.SpotlightFadeTime)

        local deathSpotlightEnlargeSpriteFrame = 83
        local frame = sprite and sprite:GetFrame() --can be called post death without sprite

        if data.State ~= States.SHOWS_OVER or postDeath
        or (frame < deathSpotlightEnlargeSpriteFrame and data.LightsOutTimer < spotlightEnlargeTime) then
            data.LightsOutTimer = data.LightsOutTimer + 1
        end

        -- local baseGameDarkValue = 1
        -- local hasDarkness = REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS)

        -- if data.LightsOutTimer == 1 and hasDarkness then
        --     REVEL.Darken(baseGameDarkValue, lbal.Duration)
        -- end

        if data.LightsOutTimer < spawnTime then
            data.DarkScreenAlpha = REVEL.SmoothStep(data.LightsOutTimer, 0, fullDarkOnTime)
            
            REVEL.SetTombLightShaderAlpha(1 - data.DarkScreenAlpha)

        elseif data.LightsOutTimer == spawnTime then
            LightsOutSpawn(npc, sprite, data, postDeath)

            if REVEL.ENT.RAGTIME:isEnt(npc) then
                npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
                npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
            end
        else
            data.DarkScreenAlpha = 1 - REVEL.SmoothStep(data.LightsOutTimer, spawnTime, fullDarkOffTime)

            if data.LightsOutTimer == fullDarkOffTime 
            and (data.State == States.LEAD_DANCE
            or data.State == States.DANCE_OFF) then
                sprite:Play("HatTip", true)
            end

            if data.LightsOutTimer >= spotlightEnlargeTime then
                local sizeMult = REVEL.Lerp2Clamp(1, 10, data.LightsOutTimer, spotlightEnlargeTime, lbal.Duration)
                -- local dark = REVEL.Lerp2Clamp(baseGameDarkValue, REVEL.BaseGameDarkness, data.LightsOutTimer, spotlightEnlargeTime, lbal.Duration)
                local alpha = REVEL.Lerp2Clamp(1, 0, data.LightsOutTimer, spotlightEnlargeTime, spotlightFadeTime)

                -- if hasDarkness then
                --     REVEL.DarkenSmooth(dark, 3)
                -- end

                -- Only enlarge ragtime spotlight
                local spotlight = data.Spotlight and data.Spotlight.Ref
                if spotlight then
                    spotlight:GetData().DarkAroundScale = sizeMult
                    REVEL.SetSpotlightAlpha(spotlight, alpha)
                end
                REVEL.SetTombLightShaderAlpha(1 - alpha)
            else
                REVEL.SetTombLightShaderAlpha(0)
            end

            if data.FirstPlayerPos then
                REVEL.player.Position = REVEL.Lerp2Clamp(
                    npc.Position,  data.FirstPlayerPos, 
                    data.LightsOutTimer,
                    playerCameraMoveTime, phaseStartTime
                )

                if data.LightsOutTimer == phaseStartTime then
                    if REVEL.ENT.RAGTIME:isEnt(npc) then
                        npc:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
                        npc:ClearEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
                    end

                    LightsOutFreePlayers(REVEL.player)
                    
                    local firstPlayerExtraSpotlight = REVEL.player:GetData().RagtimeExtraSpotlight and REVEL.player:GetData().RagtimeExtraSpotlight.Ref

                    if firstPlayerExtraSpotlight then
                        firstPlayerExtraSpotlight:GetData().ForcePosition = nil
                        firstPlayerExtraSpotlight:GetData().ForceVelocity = nil
                        firstPlayerExtraSpotlight:GetData().ForceWhenEntInvisible = nil
                    end

                    data.FirstPlayerPos = nil
                    data.SpotlightStandStill = nil
                end
            end

            if data.LightsOutTimer >= lbal.Duration then
                if REVEL.ENT.RAGTIME:isEnt(npc) then
                    npc:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
                    npc:ClearEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
                end

                local spotlight = data.Spotlight.Ref
                if spotlight then
                    REVEL.FadeoutSpotlight(spotlight)
                end

                -- just in case it somehow errored earlier
                LightsOutFreePlayers(REVEL.player)

                data.Spotlight = nil
                data.LightsOutTimer = nil
            -- else
            --     REVEL.Darken(baseGameDarkValue, 10)
            end
        end
    end

    local function ReviveDancers(npc, data)
        for _, dance in ipairs(data.CurrentDances) do
            dance:ReviveDancers()
        end
    end

    local function ShouldDoSpecialIntro()
        -- return true
        return not revel.data.ragtimeSeenSpecialIntro
            or REVEL.FORCE_RAGTIME_INTRO
    end

    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if not REVEL.ENT.RAGTIME:isEnt(npc) then return end

        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

        npc.Mass = 150

        if not data.Init then
            -- wait for room init so stageapi can load metaentities
            if REVEL.room:GetFrameCount() > 0 then
                REVEL.SetScaledBossHP(npc)

                data.bal = REVEL.GetBossBalance(REVEL.RagtimeBalance, "Default")

                data.PhaseHP = {
                    npc.MaxHitPoints * data.bal.PhaseHpBalance,
                    npc.MaxHitPoints * (1 - data.bal.PhaseHpBalance),
                }

                npc.MaxHitPoints = data.PhaseHP[1]
                data.PhaseMaxHitPoints = npc.MaxHitPoints
                npc.HitPoints = npc.MaxHitPoints

                npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                data.State = States.HIDDEN
                data.Phase = 1
                data.StartPosition = npc.Position
                data.UseSpecialIntro = ShouldDoSpecialIntro()

                data.CurrentDances = {}

                data.LastSwitchVelocityX = 4

                data.NoMusic = not data.UseSpecialIntro

                if data.UseSpecialIntro then
                    ResetDances(npc, sprite, data, true, true, true)
                    ForcefullyNotGoOffBpm = true
                    npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
                else
                    data.AppearCooldown = 30
                end

                data.Init = true
                REVEL.DebugStringMinor("Initialized Ragtime!")
            else
                npc.Visible = false
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                return
            end
        end

        -- if the timer was started in a phase, make it continue until it ends
        if data.LightsOutTimer then
            HandleLightsOut(npc, sprite, data)
        end

        if data.KeepDark then
            REVEL.Darken(1, 60)
        end

        if math.abs(npc.Velocity.X) > data.bal.MinVelocityToFlipAnim then
            local anim = sprite:GetAnimation()
            if not data.bal.AnimsWithLeftAlt[anim] and not data.bal.AnimsWithLeftAltInverted[anim] then
                sprite.FlipX = npc.Velocity.X < 0
            else
                sprite.FlipX = false
                if npc.Velocity.X < 0 and data.bal.AnimsWithLeftAlt[anim] then
                    sprite:Play(data.bal.AnimsWithLeftAlt[anim], true)
                elseif npc.Velocity.X >= 0 and data.bal.AnimsWithLeftAltInverted[anim] then
                    sprite:Play(data.bal.AnimsWithLeftAltInverted[anim], true)
                end
            end
        end

        -- Placed here to revive before dances are updated, ideally revive is done
        -- when dancers are not hopping
        if sprite:IsEventTriggered("Spawn") and sprite:IsPlaying("Revive") then
            ReviveDancers(npc, data)
            REVEL.DebugStringMinor("Reviving dancers")
        end

        if not data.SpotlightStandStill and data.State ~= States.APPEAR then
            for _, dance in ipairs(data.CurrentDances) do
                dance:Update()
            end
        end

        if npc.HitPoints < data.PhaseMaxHitPoints * 0.05 and not data.PhaseSwitchOnLight
        and data.State ~= States.ENCORE and not data.NextEncore and data.Phase == 1 then
            data.NextEncore = true
            data.State = States.LIGHTS_OUT
            sprite:Play("Tired", true)
            -- elseif data.State ~= States.SHOWS_OVER and not data.NextFinale and data.Phase == 2 then
            --     data.NextFinale = true
            --     data.State = States.LIGHTS_OUT
            --     sprite:Play("Tired", true)
            -- end
        end

        if data.State == States.LIGHTS_OUT then
            if not data.LightsOutTimer then
                data.LightsOutTimer = 0 --see postrender below for the actual dark screen rendering
                -- increased out of phase above, to have everything in the same place
                -- this state mostly serves to keep him still; the full lights out logic
                -- lasts even after state is changed, as that happens at the middle of the counter
                -- going to max
            end

            npc.Velocity = npc.Velocity * 0.7
            
        elseif data.State == States.LEAD_DANCE then
            if data.LeadingDance and not data.SpotlightStandStill then
                data.LeadingDance:UpdateRagtimeLeader()
                if data.LeadingDance:IsFinished() then
                    data.State = States.TIRED
                    data.WaitTime = data.bal.TiredMaxWaitTime
                end
            else
                npc.Velocity = npc.Velocity * 0.8
            end
        elseif data.State == States.DANCE_OFF then
            if not data.StartHP then
                data.StartHP = npc.HitPoints
                data.DanceCounter = 0
                data.AttackCooldown = REVEL.GetFromMinMax(data.bal.DanceOff.AttackCooldown)
                data.ReflectTimer = nil
                data.ReviveWait = nil

                data.ChangeAnimTimer = nil
            end

            local defaultMove = not data.ReflectTimer and not sprite:IsPlaying("Revive") and not data.ReviveWait
            local doMove = not sprite:IsPlaying("Revive")

            local accel = 0.9
            local friction = 0.85
            if data.SpotlightStandStill or not doMove then
                npc.Velocity = npc.Velocity * 0.7
            elseif data.Path 
            and npc:GetPlayerTarget().Position:Distance(npc.Position) < data.bal.DanceOff.TargetDistance then
                REVEL.FollowPath(npc, accel, data.Path, true, friction)
            else
                REVEL.MoveRandomly(npc, 60, 90, 180, accel, friction, npc:GetPlayerTarget().Position, true)
            end

            if sprite:WasEventTriggered("Reflect") and not sprite:WasEventTriggered("StopReflect") then
                ReflectTears(npc)
                if not data.PlayingSpinSound then
                    REVEL.PlaySound(npc, data.bal.Sounds.Spin)
                    data.PlayingSpinSound = true
                end
            elseif data.PlayingSpinSound then
                REVEL.sfx:Stop(data.bal.Sounds.Spin.Sound)
                data.PlayingSpinSound = nil
            end

            if defaultMove then
                if not data.SpotlightStandStill then
                    data.AttackCooldown = data.AttackCooldown - 1
                end

                if data.AttackCooldown > 0 then
                    if data.ChangeAnimTimer then
                        data.ChangeAnimTimer = data.ChangeAnimTimer - 1
                        if data.ChangeAnimTimer <= 0 then
                            data.ChangeAnimTimer = nil
                        end
                    end
    
                    -- or (math.abs((npc.Velocity - data.PrevVelocity):GetAngleDegrees()) > 45 and math.random() < 0.1) then
                    if not data.ChangeAnimTimer 
                    and not sprite:IsPlaying("Dance_Reflect_Stop")
                    and sprite:GetFrame() == 0 or sprite:IsFinished(sprite:GetAnimation()) then
                        local anims = {1, 3} -- 2 has reflect
                        if data.PrevAnim then table.remove(anims, data.PrevAnim) end
                        local newAnim = REVEL.randomFrom(anims)
                        sprite:Play("Dance_" .. newAnim, true)
    
                        data.PrevAnim = newAnim
                        data.ChangeAnimTimer = StageAPI.Random(30, 90)
                    end
                else
                    data.ChangeAnimTimer = nil
    
                    data.AttackCooldown = REVEL.GetFromMinMax(data.bal.DanceOff.AttackCooldown)
    
                    local deadDancers = REVEL.reduce(data.CurrentDances, function(total, dance)
                        return total + #REVEL.filter(dance.Dancers, function(dancer) return dancer:IsDead() end)
                    end, 0)

                    if deadDancers > data.bal.DanceOff.DeadDancersForRevive then
                        local nextCues = GetNextBeats(data.bal.MusicMapSetDefault, 8)

                        local timeToReviveEvent = data.bal.ReviveAnimSpawnTime / (sprite.PlaybackSpeed * 30) * 1000

                        -- Sync anim start so that the revive event is right before a beat,
                        -- to avoid sync problem with dancer hops
                        local waitTime

                        for i, timeToCue in ipairs(nextCues) do
                            if timeToCue > timeToReviveEvent then
                                waitTime = timeToCue - timeToReviveEvent
                            end
                        end

                        if waitTime then
                            local waitFrames = math.floor(waitTime * sprite.PlaybackSpeed * 30 / 1000)
                            data.ReviveWait = waitFrames + data.bal.DanceOff.ReviveFramesBeforeBeat
                        else
                            sprite:Play("Revive", true)
                        end
                    else
                        sprite:Play("Dance_Reflect_Start", true)
                        data.ReflectTimer = REVEL.GetFromMinMax(data.bal.DanceOff.ReflectAnimDuration)
                    end
                end
            end

            if data.ReflectTimer then
                if data.ReflectTimer > 0 then
                    data.ReflectTimer = data.ReflectTimer - 1
                    if REVEL.MultiFinishCheck(sprite, "Dance_Reflect_Start", "Dance_Reflect_Left_Start") then
                        sprite:Play("Dance_Reflect_Loop", true)
                    end
                else
                    data.ReflectTimer = nil

                    sprite:Play("Dance_Reflect_Stop", true)
                end
            end

            if data.ReviveWait then
                if data.ReviveWait > 0 then
                    data.ReviveWait = data.ReviveWait - 1
                else
                    data.ReviveWait = nil

                    sprite:Play("Revive", true)
                end
            end

            data.DanceCounter = data.DanceCounter + 1

            for _, hpPct in ipairs(data.bal.DanceOff.ResetHpPcts) do    
                if npc.HitPoints < data.PhaseMaxHitPoints * hpPct and data.StartHP >= data.PhaseMaxHitPoints * hpPct
                or (data.bal.DanceOff.DoTimedReset and data.DanceCounter > data.bal.DanceOff.TimedResetTime) then
                    data.StartHP = nil
                    data.DanceCounter = nil
                    data.ReflectTimer = nil
                    data.AttackCooldown = nil
                    data.ReviveWait = nil
                    data.State = States.LIGHTS_OUT
                    REVEL.sfx:Stop(data.bal.Sounds.Spin.Sound)

                    sprite:Play("Tired", true)

                    break
                end       
            end

            -- data.PrevVelocity = npc.Velocity
        elseif data.State == States.TIRED then
            if not data.TiredHP then
                data.TiredHP = npc.HitPoints
            end

            local newAnim = data.bal.DanceToTired[sprite:GetAnimation()]
            if not newAnim and sprite:IsPlaying("HatTip") and data.PrevAnim then
                newAnim = data.bal.DanceToTired["Dance_" .. data.PrevAnim]
            end

            if newAnim then
                sprite:Play(newAnim, true)
            elseif not (REVEL.includes(REVEL.values(data.bal.DanceToTired), sprite:GetAnimation()) and sprite:IsPlaying(sprite:GetAnimation())) 
            and not sprite:IsPlaying("Tired") then
                sprite:Play("Tired", true)
            end

            npc.Velocity = npc.Velocity * 0.6

            data.WaitTime = data.WaitTime - 1
            -- When anm2 is done, play some anim here as lights go out
            if data.WaitTime <= 0 and REVEL.every(data.CurrentDances, function(d) return d:IsFinished() end)
            or (data.TiredHP - npc.HitPoints > data.PhaseMaxHitPoints * data.bal.TiredMaxDamagePct) then
                data.WaitTime = nil
                data.TiredHP = nil
                data.State = States.LIGHTS_OUT
            end
        elseif data.State == States.HIDDEN then
            npc.Visible = false
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

            if not data.UseSpecialIntro then
                data.AppearCooldown = data.AppearCooldown - 1
                if data.AppearCooldown <= 0 then
                    npc.Visible = true
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
                    sprite:Play("Appear", true)
                    data.State = States.APPEAR
                    data.AppearCooldown = nil
                end
            else
                local timeToStart = REVEL.GetNextMusicCues(REVEL.RagtimeBalance.MusicMapSetMajorStart, nil, 1, true)[1]
                local framesForSpawn = data.bal.LightsOut.FullDarkOffTime * data.bal.LightsOut.Duration
                if timeToStart <= framesForSpawn * 1000 / 30 then
                    data.State = States.LIGHTS_OUT
                    data.NextAppear = true
                    ForcefullyNotGoOffBpm = false
                end
            end
        elseif data.State == States.APPEAR then
            if sprite:IsEventTriggered("Start") then
                data.NoMusic = nil
            end

            if sprite:IsEventTriggered("Sound") then
                REVEL.PlaySound(data.bal.Sounds.SpawnPoof)
            end

            if sprite:IsFinished("Appear") then
                if data.UseSpecialIntro then
                    data.State = States.LEAD_DANCE
                    npc:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
                else
                    data.NoMusic = nil --fallback
                    data.State = States.LIGHTS_OUT
                end
            end

            npc.Velocity = npc.Velocity * 0.7
        elseif data.State == States.ENCORE then
            if not sprite:IsPlaying("Bow") and not IsAnimOn(sprite, "PhaseTransition") then
                sprite:Play("Bow", true)
                npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
                REVEL.PlaySound(data.bal.Sounds.ClappingLoop)
                -- REVEL.PauseMusicCuesTrack()
            end

            if sprite:IsPlaying("Bow") and npc.FrameCount % 40 == 0 then
                local pos = Vec3(npc.Position, -70)
                local vel = Vec3(0, 0, -8)
                local num = math.random(10, 15)
                local velRand = 0.3
                local velSpread = 45
                ConfettiEmitter:EmitParticlesNum(ConfettiParticles, ConfettiSystem, pos, vel, num, velRand, velSpread)

                REVEL.PlaySound(data.bal.Sounds.ConfettiPop)
            end

            if npc.HitPoints <= 1 and not sprite:IsPlaying("PhaseTransition") then
                sprite:Play("PhaseTransition", true)
            end

            if sprite:IsEventTriggered("Lightning") then
                REVEL.SpawnPurpleThunder(npc)
                REVEL.sfx:Stop(data.bal.Sounds.ClappingLoop.Sound)

                sprite:ReplaceSpritesheet(0, "gfx/bosses/revel2/ragtime/ragtime_revived.png")
                sprite:ReplaceSpritesheet(1, "gfx/bosses/revel2/ragtime/ragtime_revived.png")
                sprite:ReplaceSpritesheet(2, "gfx/bosses/revel2/ragtime/ragtime_revived.png")
                sprite:ReplaceSpritesheet(3, "gfx/bosses/revel2/ragtime/ragtime_revived.png")
                sprite:ReplaceSpritesheet(4, "gfx/bosses/revel2/ragtime/ragtime_body_revived.png")
                sprite:ReplaceSpritesheet(5, "gfx/bosses/revel2/ragtime/ragtime_revived.png")
                sprite:LoadGraphics()

                -- Trigger phase 2
                data.Phase = 2
                npc.HitPoints = data.PhaseHP[data.Phase]
                data.PhaseMaxHitPoints = npc.HitPoints

                -- ~~currently setting max hitpoints bugs out the hp bar~~
                -- intentionally don't update max hp bar so it's obvious that in phase 2 they're less
                -- npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
                -- REVEL.DelayFunction(1, function()
                --     npc:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP)
                -- end)

                REVEL.DebugStringMinor(("Ragtime: started phase 2 with %f max HP, were %f"):format(
                    data.PhaseMaxHitPoints,
                    data.PhaseHP[1]
                ))
            end

            if sprite:IsPlaying("PhaseTransition") and sprite:IsEventTriggered("Start")
            or sprite:IsFinished("PhaseTransition") then
                data.State = States.LIGHTS_OUT --temporary
                data.PhaseSwitchOnLight = true
                data.Phase = 2 -- just in case

                if not REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
                    data.KeepDark = true
                end
            end

            npc.Velocity = npc.Velocity * 0.7
        elseif data.State == States.SHOWS_OVER and not IsAnimOn(sprite, "Death") then
            local spotlight = data.Spotlight and data.Spotlight.Ref
            if spotlight then
                spotlight:GetData().ForceWhenEntDead = true
            end

            npc.HitPoints = 0
            npc:Die() --plays death animation
        end
    end, REVEL.ENT.RAGTIME.id)

    revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
        if not REVEL.ENT.RAGTIME:isEnt(npc) then return end

        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

        if npc.State == NpcState.STATE_DEATH and StageAPI.IsOddRenderFrame then
            if data.LightsOutTimer then
                HandleLightsOut(npc, sprite, data)
            end

            if sprite:IsEventTriggered("Sound") then
                REVEL.PlaySound(data.bal.Sounds.DeathPull)
            end

            if sprite:IsFinished("Death") then
                REVEL.PlaySound(data.bal.Sounds.ClappingFade)
            end
        end
    end, REVEL.ENT.RAGTIME.id)

    local DoingChangedDamage = false

    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, dmg, ...)
        if not REVEL.ENT.RAGTIME:isEnt(npc) or DoingChangedDamage then return end

        local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

        local lbal = data.bal.LightsOut
        local lightsOutPhaseStartTime = math.floor(lbal.Duration * lbal.PhaseStartTime)

        if data.State == States.HIDDEN
        or sprite:IsPlaying("PhaseTransition") and sprite:WasEventTriggered("Lightning")
        or data.LightsOutTimer and data.LightsOutTimer < lightsOutPhaseStartTime
        then
            return false
        end

        if npc.HitPoints - dmg - REVEL.GetDamageBuffer(npc) <= 0 then
            if data.Phase ~= 1 and not data.NextFinale and data.State == States.DANCE_OFF then
                data.NextFinale = true
                data.State = States.LIGHTS_OUT
                sprite:Play("Tired", true)
            end
            if npc.HitPoints - REVEL.GetDamageBuffer(npc) > 1 then
                DoingChangedDamage = true
                npc:TakeDamage(npc.HitPoints - REVEL.GetDamageBuffer(npc) - 1, ...)
                DoingChangedDamage = false
            else
                REVEL.DamageFlash(npc)
            end
            return false
        end
    end, REVEL.ENT.RAGTIME.id)

    local LightsOutPostDeathHandler = {
        Update = function(entity)
            local data = entity:GetData()

            HandleLightsOut(entity, nil, data.OrigData, true)

            if not data.OrigData.LightsOutTimer then
                entity:Remove()
                LightsOutFreePlayers(REVEL.player)
            end
        end,
        Sprite = "gfx/blank.anm2",
        RemoveOnAnimEnd = false,
    }

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
        if not REVEL.ENT.RAGTIME:isEnt(entity) then return end

        local data = REVEL.GetData(entity)

        REVEL.sfx:Stop(data.bal.Sounds.Spin.Sound)

        -- Lights out ran out, spawn effect to finish running it to finish the darken effect, etc
        if data.LightsOutTimer then
            local lightsoutHandler = REVEL.SpawnDecorationFromTable(entity.Position, Vector.Zero, LightsOutPostDeathHandler)
            local hdata = lightsoutHandler:GetData()
            hdata.OrigData = REVEL.CopyTable(data)
        else 
            -- Just in case
            LightsOutFreePlayers(REVEL.player)
        end
    end, REVEL.ENT.RAGTIME.id)


    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, -5, function(stage, musicID, roomType, rng)
        if REVEL.IsEliteRoom("Ragtime") then
            local ragtimes = REVEL.ENT.RAGTIME:getInRoom()
            if #ragtimes > 0 and REVEL.every(ragtimes, function(ent)
                return not ent:IsDead() and REVEL.GetData(ent).NoMusic
            end) then
                return REVEL.SFX.BLANK_MUSIC
            end
        end
    end)

    local function postRenderRagtime()
        local ragtimes = REVEL.ENT.RAGTIME:getInRoom()
        local alpha = 0
        for _, npc in ipairs(ragtimes) do
            local thisAlpha = REVEL.GetData(npc).DarkScreenAlpha or 0
            alpha = math.max(alpha, thisAlpha)
        end

        if alpha > 0 then
            StageAPI.RenderBlackScreen(alpha)
        end
    end

    function SpawnDefaultDancer(dance, index, shooter, leader)
        if shooter and leader then
            error("Can't be both shooter and leader", 2)
        end

        local pos = REVEL.room:GetGridPosition(index)
        local dancer = REVEL.ENT.RAG_DANCER:spawn(pos, Vector.Zero, dance.Boss)

        dancer:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

        local sprite, data = dancer:GetSprite(), dancer:GetData()

        data.Phase = REVEL.GetData(dance.Boss).Phase

        if data.Phase == 2 then
            -- mainly change tint when shooting
            sprite:Load("gfx/bosses/revel2/ragtime/rag_dancer_2.anm2", true)
        end

        data.Dance = dance
        data.DanceType = dance.DanceType
        data.AnimType = math.random(1, 3)
        data.Boss = dance.Boss
        data.bal = REVEL.GetData(data.Boss).bal.Dancers
        data.Suffix = "Blind"
        if shooter then
            data.Suffix = "Shooter"
            data.IsShooter = true
        elseif leader then
            data.Suffix = "Lead"
            data.IsLeader = true
        end

        sprite:Play("Appear" .. data.Suffix .. data.AnimType, true)

        return dancer
    end

    local BloodShootColor = Color(1, 1, 1, 0.6, 0.05, 0.05, 0.3)
    local PurpleShootColor = Color(1, 1, 1, 0.6, 0.05, 0.05, 0.9)

    -- First ones are from sprites
    -- local WarningRedColor = Color(conv255ToFloat(500, 255, 255, 255, 50, 0, 0))
    -- local WarningPurpleColor = Color(conv255ToFloat(300, 220, 300, 255, 50, 0, 50)) 
    local WarningRedColor = Color(500 / 255, 1, 1, 1, 150/255, 50/255, 50/255)
    local WarningPurpleColor = Color(300 / 255, 220 / 255, 300 / 255, 1, 150 / 255, 50 / 255, 150 / 255)

    ---@param npc EntityNPC
    revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
        if not REVEL.ENT.RAG_DANCER:isEnt(npc) then return end

        local sprite, data = npc:GetSprite(), npc:GetData()

        npc.Mass = 150

        -- Shouldn't usually happen while dancers are still present,
        -- but just in case
        if data.Boss:IsDead() or not data.Boss:Exists() then
            if not data.DeathFrame then
                data.DeathFrame = npc.FrameCount + 90
            end
            if npc.FrameCount > data.DeathFrame then
                npc:Die()
            end
            return
        end

        if REVEL.includes(REVEL.GetData(data.Boss).bal.DancerNoCollAnims, sprite:GetAnimation()) then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        end

        local currentAnim = sprite:GetAnimation()

        if REVEL.MultiFinishCheck(sprite, 
            "Appear" .. data.Suffix .. data.AnimType,
            "Land" .. data.Suffix .. data.AnimType
        ) then
            if data.IsLeader and data.LastShoot then
                sprite:Play("Idle" .. data.Suffix .. data.AnimType .. "_Spin", true)
            else
                sprite:Play("Idle" .. data.Suffix .. data.AnimType, true)
            end
        end

        if sprite:IsFinished(currentAnim) and (
            string.starts(currentAnim, "Hop") 
            or string.starts(currentAnim, "Leap" ) 
            or string.starts(currentAnim, "Shoot") 
        ) then
            data.AnimType = math.random(1, 3)
            sprite:Play("Land" .. data.Suffix .. data.AnimType, true)

            if data.DoOnLand then
                data.DoOnLand()
            end
            data.DoOnLand = nil
        end

        if string.starts(currentAnim, "Leap") 
        and not sprite:WasEventTriggered("Shoot")
        and not sprite:WasEventTriggered("Land") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if data.State == "Stay_Index" then
            npc.Velocity = REVEL.room:GetGridPosition(data.Index) - npc.Position
        elseif data.State == "Hop_Index" then
            local toPos = REVEL.room:GetGridPosition(data.Index)
            if not REVEL.LerpEntityPosition(npc, data.FromPos, toPos, data.JumpDuration) then
                data.State = "Stay_Index"
            end
        else
            error("Rag dancer | Invalid state <" .. tostring(data.State) .. ">!")
        end

        if sprite:IsEventTriggered("Shoot") then
            local posOffset = Vector(0, -15)
            local angleError = data.bal.ShootAngleError
            local pos = npc.Position + posOffset
            local vel = (npc:GetPlayerTarget().Position - pos)
                :Resized(data.bal.ShootSpeed)
                :Rotated(math.random() * angleError - angleError / 2)

            local blood = Isaac.Spawn(
                1000, EffectVariant.BLOOD_EXPLOSION, 5, 
                npc.Position + Vector(0, 2), Vector.Zero, 
                npc
            )

            local projParams = ProjectileParams()
            projParams.HeightModifier = data.bal.ShootHeightMod
            projParams.FallingSpeedModifier = data.bal.ShootFallingSpeedMod
            projParams.FallingAccelModifier = data.bal.ShootFallingAccelMod

            if data.Phase == 2 then
                projParams.BulletFlags = SetBit(projParams.BulletFlags, ProjectileFlags.SMART)
                projParams.HomingStrength = data.bal.HomingStrength
                blood.Color = PurpleShootColor
            else
                blood.Color = BloodShootColor
            end

            npc:FireProjectiles(pos, vel, ProjectilesMode.SINGLE_PROJ, projParams)
            REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_BLOODSHOOT)
        end

        if data.WarningCounter then
            local duration = data.WarningCounterDuration
            data.WarningCounter = data.WarningCounter - 1
            local colorPct = REVEL.Lerp3PointClamp(0, 1, 0, data.WarningCounter, 0, duration / 2, duration)
            local color = (data.Phase == 2) and WarningPurpleColor or WarningRedColor
            npc.Color = Color.Lerp(Color.Default, color, colorPct)

            if data.WarningCounter <= 0 then
                npc.Color = Color.Default
                data.WarningCounter = nil
                data.WarningCounterDuration = nil
            end        
        end
    end, REVEL.ENT.RAG_DANCER.id)

    function DancerHopIndex(npc, toIndex, duration, animprefix, shoot, doOnLand)
        animprefix = animprefix or "Hop"

        local sprite, data = npc:GetSprite(), npc:GetData()
        local animSuffix = data.Suffix
        local fromIndex = REVEL.room:GetGridIndex(npc.Position)
        local angle = (REVEL.room:GetGridPosition(toIndex) - npc.Position):GetAngleDegrees() % 360
        local dirSuffix
        local flipX = nil

        if fromIndex == toIndex then --defuault, D
            dirSuffix = "_Down"
        elseif angle < 22.5 or angle > 360 - 22.5 then --R
            dirSuffix = "_Right" 
            flipX = false
        elseif angle < 22.5 + 45     then --DR
            dirSuffix = "_DownRight" 
            flipX = false
        elseif angle < 22.5 + 45 * 2 then --D
            dirSuffix = "_Down" 
        elseif angle < 22.5 + 45 * 3 then --DL
            dirSuffix = "_DownRight" 
            flipX = true
        elseif angle < 22.5 + 45 * 4 then --L
            dirSuffix = "_Right" 
            flipX = true
        elseif angle < 22.5 + 45 * 5 then --TL
            dirSuffix = "_TopRight" 
            flipX = true
        elseif angle < 22.5 + 45 * 6 then --T
            dirSuffix = "_Top" 
            flipX = true
        elseif angle < 22.5 + 45 * 7 then --TR
            dirSuffix = "_TopRight" 
            flipX = false
        end

        if flipX == nil then
            sprite.FlipX = math.random() > 0.5
        else
            sprite.FlipX = flipX
        end

        REVEL.UnlockGridIndex(data.Index)
        REVEL.LockGridIndex(toIndex)

        data.FromPos = npc.Position
        data.Index = toIndex
        data.State = "Hop_Index"
        data.JumpDuration = duration or REVEL.GetData(data.Boss).bal.DancerHopAnimDuration
        data.LastShoot = shoot
        data.DoOnLand = doOnLand

        if shoot and data.IsShooter then
            sprite:Play(animprefix .. "Shoot" .. dirSuffix, true)
        else
            sprite:Play(animprefix .. animSuffix .. dirSuffix, true)
        end
    end

    function DancerShootWarning(npc, duration)
        local data = npc:GetData()
        if data.IsShooter or data.IsLeader then
            data.WarningCounter = duration or REVEL.GetData(data.Boss).bal.DancerHopAnimDuration
            data.WarningCounterDuration = data.WarningCounter
        end
    end


    -- Misc functions

    -- Beat handler stuff
    local beatTriggeredPostUpdate, beatTriggeredNewRoom
    do
        -- handle ingame reload, as the previous function would still be
        -- called by the various dance classes even when local env is reloaded
        local data = {}
        data.beatCount = 0
        data.lastTime = -1
        data.triggeredThisUpdate = false
        data.lowFpsMode = false -- enabled after 90 frames under the treshold
        data.lastLowFpsModeSwitchTime = -1
        data.trackFrames = 0

        local MEASURE_DURATION = 4
        local MAJOR_START_BEAT_DISTANCE = 32 -- for example, first drop

        if REVEL.DEBUG then
            -- reload consistency
            if _G.REV_RAGTIME_BEAT_DATA then
                data = _G.REV_RAGTIME_BEAT_DATA
            else
                _G.REV_RAGTIME_BEAT_DATA = data
            end
        end

        local function UseCuesets()
            return (not (REVEL.RagtimeBalance.GoOffBPM) or ForcefullyNotGoOffBpm)
                and not data.lowFpsMode
        end

        -- Get if a cue is triggered, wrapped in its own function
        -- to be able to simply go off bpm for debug purposes if needed
        function IsBeatTriggered()
            if UseCuesets() then
                return REVEL.IsMusicCueTriggeredThisUpdate(nil, REVEL.SFX.ELITE_RAGTIME)
            elseif REVEL.music:GetCurrentMusicID() == REVEL.SFX.ELITE_RAGTIME.Track then
                return data.triggeredThisUpdate
            else
                return false
            end
        end

        function beatTriggeredNewRoom()
            data.beatCount = 0
        end

        local FpsSmoothedAverage = 30
        local FPS_SMOOTHING = 0.05

        function beatTriggeredPostUpdate()
            if REVEL.music:GetCurrentMusicID() == REVEL.SFX.ELITE_RAGTIME.Track then
                if data.trackFrames == 0 then
                    FpsSmoothedAverage = REVEL.GetFpsEstimate()
                else
                    local fpsEstimate = REVEL.GetFpsEstimate()
                    FpsSmoothedAverage = fpsEstimate * FPS_SMOOTHING + FpsSmoothedAverage * (1 - FPS_SMOOTHING)
                end

                data.trackFrames = data.trackFrames + 1

                local frameCount = REVEL.game:GetFrameCount()

                -- avoid changing often in case of fps fluctuations
                if frameCount - data.lastLowFpsModeSwitchTime > 30 * 5 then
                    if FpsSmoothedAverage < REVEL.RagtimeBalance.MinFpsForBeat and not data.lowFpsMode then
                        data.lowFpsMode = true
                        REVEL.DebugToString("Ragtime: low fps, enabled low fps mode")
                        data.lastLowFpsModeSwitchTime = REVEL.game:GetFrameCount()
                    elseif data.lowFpsMode then
                        data.lowFpsMode = false
                        REVEL.DebugToString("Ragtime: fps high enough again, disabled low fps mode")
                        data.lastLowFpsModeSwitchTime = REVEL.game:GetFrameCount()
                    end
                end

                if not data.lowFpsMode then
                    local trackTime = REVEL.GetMusicCuesTrackTime()
                    local bpm = REVEL.RagtimeBalance.SongBPM
                    local msBetweenBeats = 60000 / bpm
                    local beatProgress = trackTime % msBetweenBeats

                    data.triggeredThisUpdate = false

                    if beatProgress < data.lastTime then
                        data.triggeredThisUpdate = true
                        data.beatCount = data.beatCount + 1
                        data.lastTime = beatProgress 
                    end

                    data.lastTime = beatProgress 
                else
                    data.triggeredThisUpdate = data.trackFrames % REVEL.RagtimeBalance.LowFpsBeatFrames == 0
                    if data.triggeredThisUpdate then
                        data.beatCount = data.beatCount + 1
                    end
                end
            elseif data.trackFrames > 0 then
                data.lowFpsMode = false
                data.trackFrames = 0
            end
        end

        -- Get triggered beat sets
        -- as above, purpose is to be able to go off bpm if needed
        function GetTriggeredBeatSets()
            if UseCuesets() then
                local _, cuesetsTriggeredThisUpdate = REVEL.GetMusicCuesTriggeredThisUpdate(nil, REVEL.SFX.ELITE_RAGTIME)
                return cuesetsTriggeredThisUpdate
            else
                if IsBeatTriggered() then
                    local out = {[REVEL.RagtimeBalance.MusicMapSetDefault] = true}
                    if data.beatCount % MEASURE_DURATION == 0 then
                        out[REVEL.RagtimeBalance.MusicMapSetMeasure] = true
                    end
                    if data.beatCount % MAJOR_START_BEAT_DISTANCE == 0 then
                        out[REVEL.RagtimeBalance.MusicMapSetMajorStart] = true
                    end
                    return out
                else
                    return {}
                end
            end
        end

        ---Get the next beats (optionally of the specified track name)
        -- as time (ms) left until the beat is triggered
        -- Approximate in case of low fps mode
        ---@param beatSetName string
        ---@param amount integer
        ---@param exactTimes? boolean # return table containing track times for the beats instead of time left until the beats
        ---@return integer[]
        function GetNextBeats(beatSetName, amount, exactTimes)
            if UseCuesets() then
                return REVEL.GetNextMusicCues(beatSetName, nil, amount, true)
            elseif not data.lowFpsMode then
                local trackTime = REVEL.GetMusicCuesTrackTime()
                local bpm = REVEL.RagtimeBalance.SongBPM
                local msBetweenBeats = 60000 / bpm

                local times = {}

                for i = 1, amount do
                    local everyBeats = 1
                    if beatSetName == REVEL.RagtimeBalance.MusicMapSetMeasure then
                        everyBeats = MEASURE_DURATION
                    elseif beatSetName == REVEL.RagtimeBalance.MusicMapSetMajorStart then -- every 32, only used as fallback for cues file
                        everyBeats = MAJOR_START_BEAT_DISTANCE
                    end

                    local beatTimeBefore = trackTime - (trackTime % (msBetweenBeats * everyBeats))
                    local nextBeatTime = beatTimeBefore + msBetweenBeats * i * everyBeats
                    times[#times + 1] = nextBeatTime
                end

                if not exactTimes then
                    for i, beatTime in ipairs(times) do
                        times[i] = REVEL.GetMusicCuesTrackDuration(trackTime, beatTime)
                    end
                end

                return times
            else
                local trackTime = REVEL.GetMusicCuesTrackTime()

                -- low fps mode, approximate time estimate
                local cueDistance = 1
                if beatSetName == REVEL.RagtimeBalance.MusicMapSetMeasure then
                    cueDistance = MEASURE_DURATION
                elseif beatSetName == REVEL.RagtimeBalance.MusicMapSetMajorStart then
                    cueDistance = MAJOR_START_BEAT_DISTANCE
                end
                local toNextCue = cueDistance - (data.beatCount % cueDistance)

                local times = {}

                for beatsToCue = toNextCue, toNextCue + cueDistance * amount, cueDistance do
                    -- Estimate time left until cue
                    times[#times+1] = math.floor(beatsToCue * REVEL.RagtimeBalance.LowFpsBeatFrames * 1000 / REVEL.GetFpsEstimate())
                end

                if exactTimes then
                    for i, timeLeft in ipairs(times) do
                        times[i] = (trackTime + timeLeft) % REVEL.GetMusicCuesTrack().Duration
                    end
                end

                return times
            end
        end
    end

    -- Misc functions

    function GetIndicesAround(index)
        local w = REVEL.room:GetGridWidth()
        return {
            index - 1 - w, index - w, index + 1 - w, 
            index + 1, 
            index + 1 + w, index + w, index - 1 + w, 
            index - 1, 
        }
    end

    -- General callbacks

    StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
        ForcefullyNotGoOffBpm = false
    end)

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_ROOM_LOAD, 1, function(currentRoom, isFirstLoad)
        local isRagtimeRoom = REVEL.ENT.RAGTIME:countInRoom() > 0
        NewRoomDancesMetadata(currentRoom, isFirstLoad, isRagtimeRoom)
        beatTriggeredNewRoom()
    end)

    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SELECT_STAGE_MUSIC, 1, function(stage, musicID, roomType, rng)
        if StageAPI.InTestMode and REVEL.ENT.RAGTIME:countInRoom() > 0 and not REVEL.room:IsClear() then
            return REVEL.SFX.ELITE_RAGTIME.Track
        end
    end)   

    StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_PLAY_MINIBOSS_STREAK, 1, function(currentRoom, boss, text)
        if boss.Name == "Ragtime" and ShouldDoSpecialIntro() then
            return false
        end
    end)

    if REVEL.DEBUG then
        if _G.RagTimeRoomDances then
            RoomDances = _G.RagTimeRoomDances
        end
    end

    -- StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, function()
    --     if REVEL.music:GetCurrentMusicID() == REVEL.SFX.ELITE_RAGTIME.Track then
    --         REVEL.StopMusicTrack()
    --     end
    -- end)
    revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        -- In case of BR testing
        if REVEL.music:GetCurrentMusicID() == REVEL.SFX.ELITE_RAGTIME.Track then
            REVEL.StopMusicTrack()
        end
    end)
    
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        local triggeredSets = GetTriggeredBeatSets()
        if DO_IDEBUG and IDebug then
            if IsBeatTriggered() then
                REVEL.CueDebugPulse()
            end
            if triggeredSets["MinorBig"] then
                local p = REVEL.room:GetCenterPos() + Vector(40, 0)
                local c = Color(0, 0, 1)
                IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, p, nil, nil, nil, nil, c)
                for i = 0, 10 do
                    REVEL.DelayFunction(i, function() IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, p, nil, nil, nil, nil, c) end)
                end
                for i = 11, 15 do
                    local a = 1 - (i - 10) / 5
                    REVEL.DelayFunction(i, function() IDebug.RenderUntilNextUpdate(IDebug.RenderCircle, p, nil, nil, nil, nil, Color(c.R, c.G, c.B, c.A * a)) end)
                end
            end
        end

        beatTriggeredPostUpdate()
    end)

    local wasPaused = false

    revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if REVEL.music:GetCurrentMusicID() == REVEL.SFX.ELITE_RAGTIME.Track then
            if not wasPaused and REVEL.game:IsPaused() then
                REVEL.PauseMusicCuesTrack()
                wasPaused = true
            elseif wasPaused and not REVEL.game:IsPaused() then
                REVEL.ResumeMusicCuesTrack()
                wasPaused = false
            end
        end

        postRenderRagtime()
    end)
end