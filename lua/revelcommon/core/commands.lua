local RevRoomType = require "lua.revelcommon.enums.RevRoomType"
local RevCallbacks= require "lua.revelcommon.enums.RevCallbacks"

---@type {[string]: {Execute: fun(params: string): (string?), Autocomplete: (AutocompleteType | fun(params: string): table?)?, Aliases: string[]?, Help: string?, Desc: string, Usage: string?, File: string?}}
REVEL.Commands = {}

return function()

------------
--COMMANDS--
------------

local renderEntTypes = false
local entTypesBlacklist = {}

local TryingSin
local MaxSinTries = 150
local renderPos = false

local logSpawns
local logSpawnsBlacklist = {}
local logLuaSpawns
local logLuaSpawnsWhitelist = {}
local PatchSpawn, RestoreSpawn
local logRemoves
local logRemovesBlacklist = {}

---@type PathMap?
local ShowingPathMap = nil
local registeredShowPathMap = false
local showPathMapPostRender

local renderPlayerFrameCount = false

local ForceLag = false

local LoadBoss

local function hasOneFinishedWord(str)
    return str:match("^%s*%w+%s*$") ~= nil
end  

local function entBlacklistAutocomplete(params)
    -- local count = 0
    -- local lastWord
    -- for word in params:gmatch("%S+") do
    --   count = count + 1
    --   lastWord = word
    -- end
    -- if count % 2 == 0 then
    --     return REVEL.concat(REVEL.values(EntityType), REVEL.map(REVEL.ENT, function (ed) return ed.id end))
    -- end
end

---@type {[string]: {Execute: fun(params: string): (string?), Autocomplete: (AutocompleteType | fun(params: string): table?)?, Aliases: string[]?, Help: string?, Desc: string, Usage: string?, File: string?}}
local Commands = {
    rhelp = {
        Execute = function (params)
            local infos = {}
            for baseCommand, commandData in pairs(REVEL.Commands) do
                local cmdInfo = "> " .. baseCommand
                if commandData.Aliases then
                    cmdInfo = cmdInfo .. " (" .. table.concat(commandData.Aliases, ", ") .. ")"
                end
                if commandData.Usage then
                    cmdInfo = cmdInfo .. " " .. commandData.Usage
                end
                cmdInfo = cmdInfo .. "\n\t" .. commandData.Desc
                if commandData.Help then
                    cmdInfo = cmdInfo .. "\n\t" .. commandData.Help
                end
                if commandData.File then
                    cmdInfo = cmdInfo .. "\n\t[In " .. commandData.File .. "]"
                end
                infos[#infos+1] = cmdInfo
            end
            local list = table.concat(infos, "\n")

            Isaac.ConsoleOutput(list)
            if not REPENTOGON then
                Isaac.ConsoleOutput("Use the Repentogon mod for a better command experience, with autocomplete and help.\n")
            end
            Isaac.ConsoleOutput("Check log for more readable list!\n")
            Isaac.DebugString(list)
        end,
        Desc = "List Revelations commands",
        Help = "Print a list of Revelations commands",
    },
    revprint = {
        Execute = function (params)
            if tonumber(params:split()[1]) then
                local split = params:split()
                local maxrecurse = tonumber(split[1])
                local maxrecursePrev = REVEL.TO_STRING_MAX_RECURSE
                REVEL.TO_STRING_MAX_RECURSE = maxrecurse
                table.remove(split, 1)
                local otherParams = table.concat(split, " ")
                load("REVEL.DebugLog(" .. otherParams .. ")")()
                REVEL.TO_STRING_MAX_RECURSE = maxrecursePrev
            else
                load("REVEL.DebugLog(" .. params .. ")")()
            end
        end,
        Desc = "Prints values",
        Usage = "<luaExpression> [,<luaExpression> [...]]",
        Help = "nPrints values, can be any lua expression, or multiple ones split by comma",
    },
    test = {
        Execute = function (params)
            Isaac.ExecuteCommand('debug 3')
            -- Isaac.ExecuteCommand('chapi nodmg') -- custom health api makes debug 3 not work
            Isaac.ExecuteCommand('debug 4')
            local items = {
                CollectibleType.COLLECTIBLE_COMPASS,
                CollectibleType.COLLECTIBLE_BLUE_MAP,
                CollectibleType.COLLECTIBLE_TREASURE_MAP,
            }
            for _, item in ipairs(items) do
                if not REVEL.player:HasCollectible(item) then
                    REVEL.player:AddCollectible(item, 0, false)
                end
            end
            REVEL.player:AddKeys(99)
            REVEL.player:AddBombs(99)
            REVEL.player:AddCoins(99)
        end,
        Desc = "Godmode",
        Help = "Toggles test mode, which gives pickups, debug 3/4, and map items",
    },
    revperformance = {
        Execute = function (params)
            REV_FORCE_DEBUG_METRICS = true --check main.lua
            Isaac.ConsoleOutput("Now reload the mod using the 'luamod <folder name>' command!\n")
        end,
        Aliases = {"rperf"},
        Desc = "Enables performance metrics",
        Help = "Enables rev performance metrics, which will print timing of all mod callbacks every 5 seconds (paused or unpaused) to the log, plus an exponential average on game exit. Requires luamod to be executed after",
    },
    soundtest = {
        Execute = function (params)
            local sfx = tonumber(params) or SoundEffect['SOUND_' .. string.upper(params)]
            REVEL.sfx:Play(sfx, 1, 0, false, 1)
        end,
        Desc = "Play sounds from name",
        Usage = "soundName|soundId",
        Help = "Like playsfx, but can also play sounds using the SoundEffect table name (uses SoundEffect.SOUND_<soundName>)",
        Autocomplete = function (params)
            local out = {}
            for k, _ in pairs(SoundEffect) do
                out[#out+1] = k:gsub("SOUND_", "")
            end
            return out
        end,
    },
    rmirror = {
        Execute = function (params)
            local args = {}
            for w in params:gmatch("%S+") do args[#args+1] = w end
    
            local doLostMode = args[2] == "lost"
    
            if args[1] == 'd' then
                if revel.data.run.level.mirrorDoorRoomIndex >= 0 then
                    REVEL.SafeRoomTransition(revel.data.run.level.mirrorDoorRoomIndex, true)
                else
                    REVEL.DebugLog("No mirror room in this floor!")
                end
            else
                local validDoors = {}
                for i = 0, 7 do
                    if REVEL.room:IsDoorSlotAllowed(i) then
                        validDoors[#validDoors + 1] = i
                    end
                end
    
                if args[1] == "tomb" or args[1] == "t" then
                    if not REVEL.STAGE.Tomb:IsStage() then
                        StageAPI.GotoCustomStage(REVEL.STAGE.Tomb, false)
                    end
                else
                    if not REVEL.STAGE.Glacier:IsStage() then
                        StageAPI.GotoCustomStage(REVEL.STAGE.Glacier, false)
                    end
                end
    
                -- wait for level gen
                REVEL.DelayFunction(1, function()
                    local defaultMap = StageAPI.GetDefaultLevelMap()
                    local roomData = defaultMap:GetRoomDataFromRoomID(REVEL.MirrorRoom.RoomId)
                    if roomData then
                        ---@type LevelRoom
                        local mirrorRoom = defaultMap:GetRoom(roomData)
                    
                        if doLostMode then
                            mirrorRoom.PersistentData.TheLostMirrorBoss = true
                        end
            
                        StageAPI.ExtraRoomTransition(
                            roomData.MapID, nil, 
                            doLostMode and RoomTransitionAnim.FADE_MIRROR or RoomTransitionAnim.FADE, 
                            StageAPI.DefaultLevelMapID
                        )
                    else
                        REVEL.DebugLog("No mirror room in this floor!")
                    end
                end)
            end
        end,
        Autocomplete = function (params)
            if hasOneFinishedWord(params) then
                return {"lost"}
            else
                return {"tomb", "t", "glacier", "g", "d"}
            end
        end,
        Desc = "Teleport to Rev mirror room",
        Usage = "tomb|t|glacier|g|d [lost]",
        Help = "Goes to mirror of glacier or tomb if specified; goes to mirror door room if 'd'; if t or g, lost makes boss fight play as if entering door in lost mode (extra reward)",
    },
    enttypes = {
        Execute = function (params)
            if renderEntTypes then
                renderEntTypes = false
                --return "Disabled rendering entity types and spawners"
            else
                renderEntTypes = true
                --return "Enabled rendering entity types and spawners"
            end
    
            entTypesBlacklist = {
                {Type = 1000, Variant = 7}, --by default block footprints
            }
            if params ~= "" then
                local t
                for str in string.gmatch(params, "([^%s]+)") do
                    if not t then
                        t = str
                    else
                        entTypesBlacklist[#entTypesBlacklist + 1] = {Type = tonumber(t), Variant = tonumber(str)}
                        t = nil
                    end
                end
    
                Isaac.ConsoleOutput("Blacklisted: ".. REVEL.ToString(entTypesBlacklist))
            end
        end,
        Autocomplete = entBlacklistAutocomplete,
        Desc = "Render entity types",
        Usage = "[etype evariant [...]]",
        Help = "Toggles rendering of entity types and variants next to them. Can blacklist entity types and variants to prevent this to applying to them, blocks footprints by default.",
    },
    logspawns = {
        Execute = function (params)
            if logSpawns then
                logSpawns = false
                Isaac.ConsoleOutput("Disabled logging entity spawns\n")
            else
                logSpawns = true
                Isaac.ConsoleOutput("Enabled logging entity spawns\n")
            end
    
            logSpawnsBlacklist = {
                {Type = 1000, Variant = 7}, --by default block footprints
            }
            if params ~= "" then
                local t
                for str in string.gmatch(params, "([^%s]+)") do
                    if not t then
                        t = str
                    else
                        logSpawnsBlacklist[#logSpawnsBlacklist + 1] = {Type = tonumber(t), Variant = tonumber(str)}
                        t = nil
                    end
                end
    
                Isaac.ConsoleOutput("Blacklisted: ".. REVEL.ToString(logSpawnsBlacklist))
            end
        end,
        Autocomplete = entBlacklistAutocomplete,
        Desc = "Log entity spawns",
        Usage = "[etype evariant [...]]",
        Help = "Toggles logging every entity spawn. Can specify types and variants to block, by default blocks footprints.",
    },
    logluaspawns = {
        Execute = function (params)
            if logLuaSpawns then
                logLuaSpawns = false
                RestoreSpawn()
                Isaac.ConsoleOutput("Disabled logging Isaac.Spawn\n")
            else
                logLuaSpawns = true
                PatchSpawn()
                Isaac.ConsoleOutput("Enabled logging Isaac.Spawn. REMEMBER TO DISABLE THIS BEFORE USING luamod\n")
    
                logLuaSpawnsWhitelist = {}
                if params ~= "" then
                    local t
                    for str in string.gmatch(params, "([^%s]+)") do
                        if not t then
                            t = str
                        else
                            logLuaSpawnsWhitelist[#logLuaSpawnsWhitelist + 1] = {Type = tonumber(t), Variant = tonumber(str)}
                            t = nil
                        end
                    end
    
                    Isaac.ConsoleOutput("Whitelisted: ".. REVEL.ToString(logLuaSpawnsWhitelist))
                end
            end
        end,
        Autocomplete = entBlacklistAutocomplete,
        Desc = "Log Lua entity spawns",
        Usage = "[etype evariant [...]]",
        Help = "Toggles logging every entity spawned via Isaac.Spawn. Can specify an allow-list of entities to log",
    },
    logremoves = {
        Execute = function (params)
            if logRemoves then
                logRemoves = false
                Isaac.ConsoleOutput("Disabled logging entity removes\n")
            else
                logRemoves = true
                Isaac.ConsoleOutput("Enabled logging entity removes\n")
            end
    
            logRemovesBlacklist = {}
            if params ~= "" then
                local t
                for str in string.gmatch(params, "([^%s]+)") do
                    if not t then
                        t = str
                    else
                        logRemovesBlacklist[#logRemovesBlacklist + 1] = {Type = tonumber(t), Variant = tonumber(str)}
                        t = nil
                    end
                end
            end
        end,
        Autocomplete = entBlacklistAutocomplete,
        Desc = "Log every entity removal",
        Usage = "[etype evariant [...]]",
        Help = "Toggles logging every entity remove, can specify types and variants to blacklist as in logspawns",
    },
    rdebugmode = {
        Execute = function (params)
            if REVEL.DEBUG then
                REVEL.DEBUG = false
                REVEL.Testmode = false
            else
                REVEL.DEBUG = true
                REVEL.Testmode = true
            end
        end,
        Desc = "Additional Rev console output",
        Help = "Toggles Rev debug and test mode (additional printing in console)",
    },
    playmus = {
        Execute = function (params)
            if tonumber(params) then
                MusicManager():Play(tonumber(params), 0.1)
                MusicManager():UpdateVolume()
                REVEL.DebugToString({"Console: Played", params})
            end
        end,
        Autocomplete = function (params)
            return REVEL.map(Music, function (val, key, list)
                return {tostring(val), key:gsub("MUSIC_", "")}
            end)
        end,
        Desc = "Play music",
        Usage = "musicId",
        Help = "Plays specified music id"
    },
    spawntrock = {
        Execute = function (params)
            local i = REVEL.room:GetRandomTileIndex(math.random(1999))
            local c = 0
            while not REVEL.IsGridIndexFree(i, 16) and c < 1000 do
                i = REVEL.room:GetRandomTileIndex(math.random(1999))
                c = c + 1
            end
    
            Isaac.GridSpawn(GridEntityType.GRID_ROCKT, 0, REVEL.room:GetGridPosition(i), true)
        end,
        Desc = "Spawn tinted rock",
        Help = "Spawns tinted rock in random room position"
    },
    resetcolor = {
        Execute = function (params)
            REVEL.player:GetSprite().Color = Color.Default
        end,
        Desc = "Reset player color",
        Help = "Resets player color tint to default"
    },
    hudtoggle = {
        Execute = function (params)
            local visible = REVEL.game:GetHUD():IsVisible()
            REVEL.game:GetHUD():SetVisible(not visible)
            Isaac.ConsoleOutput("Set HUD to " .. (visible and "hidden" or "visible") .. "\n")
            Isaac.DebugString("Set HUD to " .. (visible and "hidden" or "visible"))
        end,
        Desc = "Toggle HUD visibility",
        Help = "Toggle HUD, can also press H for same effect while REVEL.DEBUG_MODE is on (that's the case for the git branches, if you're a rev tester)"
    },
    loadout = {
        Execute = function (params)
            local stageNum = tonumber(params) or 3
            local treasure = math.min(6, stageNum)
            local boss = math.min(8, stageNum)
            if stageNum >= 6 then
                boss = boss - 1
            end
    
            if stageNum >= 8 then
                boss = boss - 1
            end
    
            boss, treasure = math.random(boss - 1, boss), math.random(treasure - 1, treasure)
    
            for i = 1, treasure do
                REVEL.player:AddCollectible(REVEL.pool:GetCollectible(ItemPoolType.POOL_TREASURE, true, Random()), 999, true)
            end
    
            for i = 1, boss do
                REVEL.player:AddCollectible(REVEL.pool:GetCollectible(ItemPoolType.POOL_BOSS, true, Random()), 999, true)
            end
        end,
        Desc = "Give random items",
        Usage = "[stageNum{=3}]",
        Help = "Gives amount of items appropriate for stageNum",
    },
    estimatedps = {
        Execute = function (params)
            Isaac.ConsoleOutput(tostring(REVEL.EstimateDPS(REVEL.player)))
        end,
        Desc = "Print DPS",
        Help = "Prints estimated player DPS",
    },
    sintest = {
        Execute = function (params)
            TryingSin = 0
        end,
        Desc = "Go to a sin room",
        Help = "Tries to go to a sin room",
    },
    dumproomlists = {
        Execute = function (params)
            REVEL.DebugToString(REVEL.TableToStringEnter(REVEL.GetRoomsListNames()))
            REVEL.DebugToConsole("Printed room list names in the log")
        end,
        Desc = "Log room lists",
        Help = "Prints all room lists in the log"
    },
    printroomlists = {
        Execute = function (params)
            Isaac.ConsoleOutput(REVEL.TableToStringEnter(REVEL.GetRoomsListNames()))
            REVEL.DebugToConsole("Printed room list names")
        end,
        Desc = "Print room lists",
        Help = "Prints all room lists in the console"
    },
    dumprooms = {
        Execute = function (params)
            local listName = string.gsub(params, "_", " ")
            local list = StageAPI.RoomsLists[listName]
            if list then
                local rooms = {}
                for _, room in ipairs(list.All) do table.insert(rooms, room.Name) end
                REVEL.DebugToString(REVEL.TableToStringEnter(rooms))
                REVEL.DebugToConsole("Printed room names in the log")
            else
                REVEL.DebugToConsole("List doesn't exist")
            end
        end,
        Autocomplete = function(params)
            return REVEL.GetRoomsListNames()
        end,
        Desc = "Log rooms in list",
        Usage = "listName",
        Help = "Prints all rooms in the specified room list"
    },
    refreshfams = {
        Execute = function (params)
            for i,p in ipairs(REVEL.players) do
                p:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
                p:EvaluateItems()
            end
        end,
        Aliases = {"reffams"},
        Desc = "Re-calculates player familiars",
        Help = "Re-calculates player familiars"
    },
    buffrag = {
        Execute = function (params)
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                if REVEL.IsEntityRevivable(entity) then
                    REVEL.BuffEntity(entity)
                end
            end
        end,
        Aliases = {"buff"},
        Desc = "Buffs rag enemies",
        Help = "Buffs all rag enemies in the room",
    },
    testpos = {
        Execute = function (params)
            renderPos = not renderPos
        end,
        Desc = "Render player coordinates",
        Help = "Toggles rendering player position coordinates"
    },
    printlvlmap = {
        Execute = function (params)
            Isaac.ConsoleOutput("Printed level map in the log!\n")
            REVEL.PrintLevelMap()
        end,
        Desc = "Log level map",
        Help = "Prints level map with room IDs in the log",
    },
    givefam = {
        Execute = function (params)
            local num = tonumber(params) or 1
            local added = {}
            for i = 1, num do
                local id
                repeat id = math.random(REVEL.collectiblesSize)
                until REVEL.config:GetCollectible(id) and REVEL.config:GetCollectible(id).Type == ItemType.ITEM_FAMILIAR
                added[#added + 1] = REVEL.config:GetCollectible(id).Name
    
                REVEL.player:AddCollectible(id, 0, false)
            end
    
            REVEL.DebugToConsole("Added", table.unpack(added))
        end,
        Usage = "[num{=1}]",
        Help = "Adds specified amount of random familiars for testing interactions during item development",
        Desc = "Add random familiars",
    },
    attacknames = {
        Execute = function (params)
            REVEL.AnnounceAttackNames = not REVEL.AnnounceAttackNames
        end,
        Help = "Makes some rev bosses render attack names as text streaks",
        Desc = "Show rev boss attack names",
    },
    ruthlessmode = {
        Execute = function (params)
            REVEL.RuthlessMode = not REVEL.RuthlessMode
        end,
        Help = "Toggles ruthless mode, forcing all bosses with a ruthless version to use it",
        Desc = "Toggle rev boss ruthless mode",
    },
    smolyscale = {
        Execute = function (params)
            if REVEL.SmolycephalusForScale then
                REVEL.SmolycephalusForScale = false
            else
                REVEL.SmolycephalusForScale = true
                if tonumber(params) then
                    REVEL.SmolycephalusForScale = tonumber(params)
                end
            end
            REVEL.DebugLog("Set to " .. tostring(REVEL.SmolycephalusForScale))
        end,
        Help = "Spawns a dummy for DPS testing in all starting rooms",
        Desc = "DPS check dummy",
    },
    greenscreen = {
        Execute = function (params)
            local renderer = StageAPI.SpawnFloorEffect()
            renderer.RenderZOffset = 10000
            renderer:GetData().GreenScreen = true
        end,
        Help = "Replaces stage background with a green screen, useful for recording videos where you need to edit out the background",
        Desc = "Green background",
    },
    showpathmap = {
        Execute = function (params)
            if params == "none" then
                if registeredShowPathMap then
                    revel:RemoveCallback(ModCallbacks.MC_POST_RENDER, showPathMapPostRender)
                    registeredShowPathMap = false
                end
                ShowingPathMap = nil
                Isaac.ConsoleOutput("Hiding path maps\n")
            elseif params ~= "" then
                if not REVEL.PathMaps[params] then
                    Isaac.ConsoleOutput(("No such path map '%s'\n"):format(params))
                    return
                end
    
                if not registeredShowPathMap then
                    revel:AddCallback(ModCallbacks.MC_POST_RENDER, showPathMapPostRender)
                end
                ShowingPathMap = REVEL.PathMaps[params]
                Isaac.ConsoleOutput(("Showing path map %s, target set 1\n"):format(params))
            end
        end,
        Autocomplete = function (params)
            local out = REVEL.keys(REVEL.PathMaps)
            table.insert(out, 1, "none")
            return out
        end,
        Help = "Renders the specified Rev path map for monster pathfinding",
        Usage = "pathmapName|<none>",
        Desc = "Rev Pathmap debugging",
    },
    playerframes = {
        Execute = function (params)
            renderPlayerFrameCount = not renderPlayerFrameCount
        end,
        Help = "Toggles rendering player FrameCount next to the player. Useful for testing things like firedelay between vanilla features",
        Desc = "Render player framecount",
    },
    lag = {
        Execute = function (params)
            ForceLag = not ForceLag
            if ForceLag then
                Isaac.ConsoleOutput("Enabled forced lag!\n")
                Isaac.DebugString("Enabled forced lag!")
            else
                Isaac.ConsoleOutput("Disabled forced lag!\n")
                Isaac.DebugString("Disabled forced lag!")
            end
        end,
        Help = "Start lagging, to test low fps",
        Desc = "Force lag",
    },
    rboss = {
        Execute = function (params)
            LoadBoss(params)
        end,
        Autocomplete = function(params)
            local bossNames = {}
            for chapter, bosses in pairs(REVEL.Bosses) do
                for _, bossdata in ipairs(bosses) do
                    bossNames[#bossNames+1] = bossdata.Name
                end
            end
            return bossNames 
        end,
        Usage = "bossName",
        Help = "Starts a test fight with specified Rev boss, not case sensitive",
        Desc = "Go to rev boss",
    },
}

REVEL.mixin(REVEL.Commands, Commands)

-- Run every time in case another part of code added a command/changed things
local function GetAliasTable()
    local aliasTable = {}

    for baseCommand, commandData in pairs(REVEL.Commands) do
        aliasTable[baseCommand] = commandData
        if commandData.Aliases then
            for _, alias in ipairs(commandData.Aliases) do
                aliasTable[alias] = commandData
            end
        end
    end

    return aliasTable
end

local function commands_ExecuteCmd(_, cmd, params)
    local level = REVEL.game:GetLevel()
    params = tostring(params)

    local aliasTable = GetAliasTable()
    local commandData = aliasTable[cmd]

    if commandData then
        return commandData.Execute(params)
    end
end

local function RegisterCommands()
    for baseCommand, commandData in pairs(REVEL.Commands) do
        REVEL.Assert(commandData.Desc, "Command " .. tostring(baseCommand) .. " doesn't have a Desc!")
        REVEL.Assert(commandData.Execute, "Command " .. tostring(baseCommand) .. " doesn't have a Execute func!")

        local aliases = commandData.Aliases or {}
        local autocompleteType = AutocompleteType.NONE
        if type(commandData.Autocomplete) == "function" then
            autocompleteType = AutocompleteType.CUSTOM
        elseif commandData.Autocomplete then
            autocompleteType = commandData.Autocomplete
        end
        local help = commandData.Desc .. "\n" .. "Usage: " .. baseCommand

        if commandData.Usage then 
            help = help .. " " .. commandData.Usage 
        end
        if commandData.Help then 
            help = help .. "\n" .. commandData.Help 
        end
        if commandData.Aliases then
            help = help .. "\nAliases: " .. REVEL.ToString(commandData.Aliases)
        end

        Console.RegisterCommand(baseCommand, commandData.Desc, help, true, autocompleteType)

        for _, alias in ipairs(aliases) do
            Console.RegisterCommand(alias, commandData.Desc, help, true, autocompleteType)
        end
    end
end

local function RegisterAutocomplete()
    local aliasTable = GetAliasTable()

    for alias, commandData in pairs(aliasTable) do
        if type(commandData.Autocomplete) == "function" then
            revel:AddCallback(ModCallbacks.MC_CONSOLE_AUTOCOMPLETE, function (_, cmd, params)
                return commandData.Autocomplete(params)
            end, alias)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, commands_ExecuteCmd)

if REPENTOGON then
    local REGISTERED = false
    local function tryRegister()
        if not REGISTERED then
            RegisterCommands()
            RegisterAutocomplete()
            REGISTERED = true
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, tryRegister)
    StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 0, tryRegister)
end

----------------------------
-- Specific command logic
----------------------------

local PathmapFont = Font()
PathmapFont:Load("font/pftempestasevencondensed.fnt")
local PathmapFontColor = KColor(1,1,1,1)

function showPathMapPostRender()
    if ShowingPathMap then
        if ShowingPathMap.TargetMapSets[1] then
            local sideCollisions = ShowingPathMap.GetSideCollisions and ShowingPathMap.GetSideCollisions()
            local map = ShowingPathMap.TargetMapSets[1].Map
            for i = 0, REVEL.room:GetGridSize() do
                local pos = REVEL.room:GetGridPosition(i)
                local rpos = Isaac.WorldToScreen(pos)
                if map[i] then
                    local valstr = tostring(map[i])
                    local w = PathmapFont:GetStringWidth(valstr)
                    PathmapFont:DrawString(valstr, rpos.X - w / 2, rpos.Y, PathmapFontColor)

                    if sideCollisions 
                    and IDebug
                    and sideCollisions[i]
                    then
                        local border = 2

                        for dir = 0, 3 do
                            if sideCollisions[i][dir] then
                                local par = REVEL.dirToVel[dir]
                                local perp = REVEL.dirToVel[(dir + 1) % 4]
                                local vec1 = pos + par * (20 - border) + perp * 20
                                local vec2 = pos + par * (20 - border) - perp * 20
                                local tl = Vector(math.min(vec1.X, vec2.X), math.min(vec1.Y, vec2.Y))
                                local br = Vector(math.max(vec1.X, vec2.X), math.max(vec1.Y, vec2.Y))

                                IDebug.RenderLine(tl, br, false, Color(0, 0, 1))
                            end
                        end
                    end
                end
            end
        end
    end
end

local function commandsPostRender()
    if renderEntTypes then
        for i, e in ipairs(REVEL.roomEntities) do
            local blacklisted = false
            for _, v in ipairs(entTypesBlacklist) do
                if v.Type == e.Type and v.Variant == e.Variant then
                    blacklisted = true
                    break
                end
            end

            if not blacklisted then
                local pos = Isaac.WorldToScreen(e.Position)
                Isaac.RenderText((e.Type..";"..e.Variant..";"..e.SubType), pos.X, pos.Y, 255, 255, 255, 255)
                -- if e.SpawnerEntity then
                --     Isaac.RenderText((e.SpawnerType..";"..e.SpawnerVariant..";"..e.SpawnerEntity.SubType), pos.X, pos.Y+15, 255, 255, 255, 255)
                -- end
            end
        end
    end

    if renderPos then
        local pos = Input.GetMousePosition(true)
        local pos2 = Isaac.WorldToScreen(pos)
        Isaac.RenderText(pos.X.."; "..pos.Y, pos2.X, pos2.Y+30, 255,255,255,255)
    end

    if renderPlayerFrameCount then
        for _, player in ipairs(REVEL.players) do
            local pos = Isaac.WorldToScreen(player.Position + Vector(25, -45))
            Isaac.RenderText(player.FrameCount, pos.X, pos.Y, 255, 255, 255, 255)
        end
    end

    if TryingSin then
        local roomsList = REVEL.level:GetRooms()
        local hasRoom
        for i = 0, roomsList.Size do
            local roomDesc = roomsList:Get(i)
            if roomDesc and roomDesc.Data.Type == RoomType.ROOM_MINIBOSS
            and roomDesc.Data.Variant >= 2000 and roomDesc.Data.Variant <= 2164 then -- glacier sin room first and last variants
                hasRoom = true
            end
        end

        if not hasRoom then
            TryingSin = TryingSin + 1
            if TryingSin > MaxSinTries then
                TryingSin = nil
                REVEL.DebugToConsole("Couldn't find sin room floor!")
            else
                local stagesToTry = { REVEL.STAGE.Glacier, REVEL.STAGE.Tomb }
                if not REVEL.some(stagesToTry, function(stage)
                    if stage:IsStage() then
                        StageAPI.GotoCustomStage(stage, false)
                        return true
                    end
                    return false
                end) then
                    REVEL.DebugToConsole("cstage to the rev stage you'd like to test, then try again")
                    TryingSin = nil
                end
            end
        else
            REVEL.DebugToConsole("Found sin room floor!")
            TryingSin = nil
        end
    end

    -- Check H for toggle hud
    if REVEL.DEBUG and not REVEL.game:IsPaused()
    and Input.IsButtonTriggered(Keyboard.KEY_H, 0) then
        Isaac.ExecuteCommand("hudtoggle")
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subtype, position, velocity, spawner, seed)
    if logSpawns then
        local blacklisted = false
        for _, v in ipairs(logSpawnsBlacklist) do
            if v.Type == type and v.Variant == variant then
                blacklisted = true
                break
            end
        end

        if not blacklisted then
            REVEL.DebugLog("s: Spawning " .. type .. "." .. variant .. "." .. subtype 
              .. " at " .. REVEL.room:GetGridIndex(position) .. "\n\tspawner is " .. REVEL.ToString(spawner))
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
    if logRemoves then
        local blacklisted = false
        for _, v in ipairs(logRemovesBlacklist) do
            if v.Type == entity.Type and v.Variant == entity.Variant then
                blacklisted = true
                break
            end
        end

        if not blacklisted then
            REVEL.DebugLog("s: Removed " .. REVEL.ToString(entity) .. "\n\tspawner is " .. REVEL.ToString(entity.SpawnerEntity))
        end
    end
end)

local greenScreen = REVEL.LazyLoadRoomSprite{
    ID = "GreenScreen",
    Anm2 = "gfx/backdrop/Black.anm2",
    Animation = "Default",
    Color = Color(1,1,1,1,conv255ToFloat(0, 255, 0)),
}

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, e)
    local data = e:GetData()
    if data.GreenScreen and REVEL.IsRenderPassNormal() then
        greenScreen:Render(REVEL.GetScreenTopLeft(), Vector.Zero, Vector.Zero)
    end
end)

local OldIsaacSpawn

local function IsaacSpawnOverride(type, variant, subtype, position, velocity, spawner)
    local entity = OldIsaacSpawn(type, variant, subtype, position, velocity, spawner)

    local log = true
    if #logLuaSpawnsWhitelist > 0 then
        log = false
        for _, v in ipairs(logLuaSpawnsWhitelist) do
            if v.Type == entity.Type and v.Variant == entity.Variant then
                log = true
                break
            end
        end
    end

    if log then
        REVEL.DebugLog("Isaac.Spawn(" .. type .. ", " .. variant .. ", " .. subtype .. ", " 
            .. REVEL.ToString(position) .. ", " .. REVEL.ToString(velocity) .. ", " .. REVEL.ToString(spawner)
            .. "\n Traceback: " .. REVEL.TryGetTraceback(true, true)
        )
    end

    return entity
end

function PatchSpawn()
    OldIsaacSpawn = Isaac.Spawn
    Isaac.Spawn = IsaacSpawnOverride
end

function RestoreSpawn()
    Isaac.Spawn = OldIsaacSpawn
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, commandsPostRender)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if ForceLag then
        for i = 1, 10^(5.4 + math.random()*1.4) do
            local a = i^10^5
        end
    end
end)

function LoadBoss(name)
    local boss
    for chapter, bosses in pairs(REVEL.Bosses) do
        for _, bossdata in ipairs(bosses) do
            if string.lower(bossdata.Name) == string.lower(name) then
                boss = bossdata
            end
        end
    end

    if not boss then
        if REPENTOGON then
            Console.PrintError("Unknown boss " .. tostring(name))
        else
            REVEL.DebugToConsole("Unknown boss", name)
        end
        return
    end

    local stage
    if type(boss.Stage) ~= "table" then
        stage = REVEL.STAGE[boss.Stage]
    else
        stage = boss.Stage
    end

    StageAPI.GotoCustomStage(stage, false, false)

    -- if boss.Shapes then
    --     ForceNextBossShapes = {}
    --     for _, shape in ipairs(boss.Shapes) do
    --         ForceNextBossShapes[shape] = true
    --     end
    -- else
    --     ForceNextBossShapes = nil
    -- end

    if boss.Mirror then
        local mirrorRoom = StageAPI.LevelRoom("MirrorRoom", nil, REVEL.room:GetSpawnSeed(), RoomShape.ROOMSHAPE_1x1, RoomType.ROOM_DEFAULT, true)
        mirrorRoom.TypeOverride = "Mirror"
        local roomData = StageAPI.GetDefaultLevelMap():AddRoom(mirrorRoom, {RoomID = "RevelationsBossHall"})

        StageAPI.ExtraRoomTransition(roomData.MapID, nil, RoomTransitionAnim.FADE, StageAPI.DefaultLevelMapID, mirrorRoom.Layout.Doors[StageAPI.Random(1, #mirrorRoom.Layout.Doors)].Slot)
    else
        local bossRoom = StageAPI.GenerateBossRoom(boss.Name, nil, nil, nil, nil, 2, nil, true, -1, true)

        if not bossRoom then
            if REPENTOGON then
                Console.PrintError("Error in creating room for " .. tostring(name))
            else
                REVEL.DebugToConsole("Error in creating room for", name)
            end
            return
        end

        local doors = {}
        for _, door in ipairs(bossRoom.Layout.Doors) do
            if door.Exists then
                doors[#doors + 1] = door.Slot
            end
        end
        
        local roomData = StageAPI.GetDefaultLevelMap():AddRoom(bossRoom, {RoomID = "RevelationsBossHall"})

        if boss.IsMiniboss then
            bossRoom.RoomType = RoomType.ROOM_DEFAULT
        else
            bossRoom.RoomType = RoomType.ROOM_BOSS
        end
        
        StageAPI.ExtraRoomTransition(roomData.MapID, nil, RoomTransitionAnim.FADE, StageAPI.DefaultLevelMapID, doors[StageAPI.Random(1, #doors)])

        -- if not boss.IsMiniboss then
        --     LoadingBossFromMenu = boss
        -- end
    end

    -- ForceNextBossShapes = nil
end


Isaac.DebugString("Revelations: Loaded Commands!")
end