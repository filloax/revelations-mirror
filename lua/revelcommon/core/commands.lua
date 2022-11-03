local RevRoomType = require "lua.revelcommon.enums.RevRoomType"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------
--COMMANDS--
------------
local commandsList = [[> rhelp: print this list

in this file:
> revprint <lua value> [<lua value>...]
  prints values with DebugLog(), can be any lua expression
> test
  toggles test mode, which gives pickups, debug 3/4, and map items
> soundtest <name or sound id>
  like playsfx, but can also play sounds using the SoundEffect table name (uses SoundEffect.SOUND_<name>)
> rmirror [tomb|t|glacier|g|d] [lost]
  goes to mirror of glacier or tomb if specified
  goes to mirror door room if 'd'
  if t or g, lost makes boss fight play as if entering
  door in lost mode (extra reward)
> enttypes
  toggles rendering of entity types and variants next to them
> revperformance|rperf mod_folder_name
  enables rev performance metrics, which will print timing of all
  mod callbacks every 5 seconds (paused or unpaused) to the log
  plus an exponential average on game exit
  Requires the mod folder name you'd use with luamod to be passed
  as a parameter
> logspawns [<bl_type bl_variant>...]
  toggles logging every entity spawn, can specify types and variants 
  to blacklist like this 
  'logspawns 1000 1 10 0' to blacklist 1000.1 and 10.0
> logluaspawns [<wl_type wl_variant>...]
  toggles logging every entity spawned via Isaac.Spawn, optionally
  can specify a whitelist of entities to log
> logremoves [<bl_type bl_variant>...]
  toggles logging every entity remove, can specify types and variants 
  to blacklist like this 
  'logremoves 1000 1 10 0' to blacklist 1000.1 and 10.0
> debugmode
  toggles debug and test mode (additional printing in console)
> playmus <music id>
  plays specified music id
> spawntrock
  spawns tinted rock in random room position
> resetcolor
  resets player color tint to default
> hudtoggle
  toggle HUD, can also press H for same effect while 
  REVEL.DEBUG_MODE is on (that's the case for the 
  git branches, if you're a rev tester)
> loadout [<stageNum>=3]
  gives amount of items appropriate for stageNum
> estimatedps
  prints estimated player DPS
> sintest
  tries Sinami
> dumproomlists
  prints all room lists in the log
> printroomlists
  prints all room lists in the console
> dumprooms <roomList>
  prints all rooms in the speicified room list
> refreshfams
  re-calculates player familiars
> buff
  buffs all rag enemies in the room
> testpos
  toogles rendering player position
> printlvlmap
  prints level map with room ids
> givefam [<amount>=1]
  adds an amount of random familiars for testing interactions with custom ones
> attacknames
  toggles rendering boss attack names as text streaks
> ruthlessmode
  toggles ruthless mode
> smolyscale
  toggles spawning dummy in starting rooms
> greenscreen
  replaces stage background with a green screen, useful for recording videos where you need to edit out the background
> showpathmap none|<name>
  renders the specified path map
> debugstring <value>
> playerframes
  toggles rendering player framecount next to the player
  useful for testing things like firedelay between vanilla
  features
> lag
  start lagging, to test low fps

in unlocks.lua:
> revunlock [list|print | *|all | <unlockName>]
  list|print: prints all unlockables
  *|all: unlocks all unlockables
  <unlockName>: unlocks specified unlockable
> revlock [list|print | *|all | <unlockName>]
  as above but for locking

in dante.lua:
> charonswitch
  switches between Charon and Dante
> charonmerge
  merges Charon and Dante
> charonmode
  Toggles charon firing switch mode between fire or movement keys

in hubroom.lua:
> togglehubdoor | thub
  toggles spawning of hub trapdoor

in revelcommon/bosses/init.lua
> forcechampionstate [yes|true|on | no|false|off]
  on: always spawn champion bosses
  off: never do
  nothing: reset to normal behavior

in revelcommon/shrines/champions.lua
> forcechampions | fchamp
  toggle forcing rev enemy champions

in customchargebars.lua
> rdebug 8
  like debug 8 but for custom charge bar items

in shaders.lua:
> shaderdebug <value>
  set shader debug mode (includes off, grayscale, before/after, etc)
> drawshadermask | drawsm
  shader mask tool, used to draw tomb masks to later save (needs specific shaders enabled in xml)
> colordebug | clrdbg
  render color palette for color correction testing

in revelcommon/shrines/vanity.lua
> vanityshop | vshop
  teleport to the vanity shop for pact rewards
> addvanity | addv <number>
  adds Vanity to the player

in revelcommon/shrines/pact.lua
> revpact <pactname>
  adds the chosen pact, check ShrineTypes.lua
  for valid names (common ones are not valid)
]]

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

local showingPathMap = nil
local registeredShowPathMap = false
local showPathMapPostRender

local renderPlayerFrameCount = false

local ForceLag = false

local function commands_ExecuteCmd(_, cmd, params)
    local level = REVEL.game:GetLevel()
    params = tostring(params)
    if cmd == "rhelp" then
        Isaac.ConsoleOutput(commandsList)
        Isaac.ConsoleOutput("Check log for more readable list!\n")
        Isaac.DebugString(commandsList)
    elseif cmd == "revprint" then
        load("REVEL.DebugLog(" .. params .. ")")()
    elseif cmd == 'debugstring' then
        REVEL.DebugToString(_G[params])
    elseif cmd == 'test' then
        Isaac.ExecuteCommand('debug 3')
        Isaac.ExecuteCommand('chapi nodmg') -- custom health api makes debug 3 not work
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
    elseif cmd == "revperformance" or cmd == "rperf" then
        REV_FORCE_DEBUG_METRICS = true --check main.lua
        Isaac.ConsoleOutput("Now reload the mod using the 'luamod <folder name>' command!\n")
    elseif cmd == "soundtest" then
        local sfx = tonumber(params) or SoundEffect['SOUND_' .. string.upper(params)]
        REVEL.sfx:Play(sfx, 1, 0, false, 1)
    elseif cmd == "rmirror" then
        local args = {}
        for w in params:gmatch("%S+") do args[#args+1] = w end

        local doLostMode = args[2] == "lost"

        if args[1] == 'd' then
            REVEL.SafeRoomTransition(revel.data.run.level.mirrorDoorRoomIndex, true)
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
    elseif cmd == "enttypes" then
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
    elseif cmd == "logspawns" then
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
    elseif cmd == "logluaspawns" then
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
    elseif cmd == "logremoves" then
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
    elseif cmd == "debugmode" then
        if REVEL.DEBUG then
            REVEL.DEBUG = false
            REVEL.Testmode = false
        else
            REVEL.DEBUG = true
            REVEL.Testmode = true
        end
    elseif cmd == "playmus" then
        if tonumber(params) then
            MusicManager():Play(tonumber(params), 0.1)
            MusicManager():UpdateVolume()
            REVEL.DebugToString({"Console: Played", params})
        end
    elseif cmd == "spawntrock" then
        local i = REVEL.room:GetRandomTileIndex(math.random(1999))
        local c = 0
        while not REVEL.IsGridIndexFree(i, 16) and c < 1000 do
            i = REVEL.room:GetRandomTileIndex(math.random(1999))
            c = c + 1
        end

        Isaac.GridSpawn(GridEntityType.GRID_ROCKT, 0, REVEL.room:GetGridPosition(i), true)
    elseif cmd == "resetcolor" then
        REVEL.player:GetSprite().Color = Color.Default
    elseif cmd == 'hudtoggle' then
        local visible = REVEL.game:GetHUD():IsVisible()
        REVEL.game:GetHUD():SetVisible(not visible)
        Isaac.ConsoleOutput("Set HUD to " .. (visible and "hidden" or "visible") .. "\n")
        Isaac.DebugString("Set HUD to " .. (visible and "hidden" or "visible"))
    elseif cmd == "loadout" then
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
    elseif cmd == "estimatedps" then
        Isaac.ConsoleOutput(tostring(REVEL.EstimateDPS(REVEL.player)))
    elseif cmd == "sintest" then
        TryingSin = 0
    elseif cmd == "dumproomlists" then
        REVEL.DebugToString(REVEL.TableToStringEnter(REVEL.GetRoomsListNames()))
        REVEL.DebugToConsole("Printed room list names in the log")
    elseif cmd == "printroomlists" then
        Isaac.ConsoleOutput(REVEL.TableToStringEnter(REVEL.GetRoomsListNames()))
        REVEL.DebugToConsole(" Printed room list names")
    elseif cmd == "dumprooms" then
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
    elseif cmd == "refreshfams" or cmd == "reffam" then
        for i,p in ipairs(REVEL.players) do
            p:AddCacheFlags(CacheFlag.CACHE_FAMILIARS)
            p:EvaluateItems()
        end
    elseif cmd == "buff" then
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if REVEL.IsEntityRevivable(entity) then
                REVEL.BuffEntity(entity)
            end
        end
    elseif cmd == "testpos" then
        renderPos = not renderPos
    elseif cmd == "printlvlmap" then
        Isaac.ConsoleOutput("Printed level map in the log!\n")
        REVEL.PrintLevelMap()
    elseif cmd == "givefam" then --adds an amount of random familiars for testing interactions with custom ones
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
    elseif cmd == "attacknames" then
        REVEL.AnnounceAttackNames = not REVEL.AnnounceAttackNames
    elseif cmd == "ruthlessmode" then
        REVEL.RuthlessMode = not REVEL.RuthlessMode
    elseif cmd == "smolyscale" then
        if REVEL.SmolycephalusForScale then
            REVEL.SmolycephalusForScale = false
        else
            REVEL.SmolycephalusForScale = true
            if tonumber(params) then
                REVEL.SmolycephalusForScale = tonumber(params)
            end
        end
        REVEL.DebugLog("Set to " .. tostring(REVEL.SmolycephalusForScale))
    elseif cmd == "greenscreen" then
        local renderer = StageAPI.SpawnFloorEffect()
        renderer.RenderZOffset = 10000
        renderer:GetData().GreenScreen = true
    elseif cmd == "showpathmap" then
        if params == "none" then
            if registeredShowPathMap then
                revel:RemoveCallback(ModCallbacks.MC_POST_RENDER, showPathMapPostRender)
                registeredShowPathMap = false
            end
            showingPathMap = nil
            Isaac.ConsoleOutput("Hiding path maps\n")
        elseif params ~= "" then
            if not REVEL.PathMaps[params] then
                Isaac.ConsoleOutput(("No such path map '%s'\n"):format(params))
                return
            end

            if not registeredShowPathMap then
                revel:AddCallback(ModCallbacks.MC_POST_RENDER, showPathMapPostRender)
            end
            showingPathMap = REVEL.PathMaps[params]
            Isaac.ConsoleOutput(("Showing path map %s, target set 1\n"):format(params))
        end
    elseif cmd == "playerframes" then
        renderPlayerFrameCount = not renderPlayerFrameCount
    elseif cmd == "lag" then
        ForceLag = not ForceLag
        if ForceLag then
            Isaac.ConsoleOutput("Enabled forced lag!\n")
            Isaac.DebugString("Enabled forced lag!")
        else
            Isaac.ConsoleOutput("Disabled forced lag!\n")
            Isaac.DebugString("Disabled forced lag!")
        end
    end
end

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, commands_ExecuteCmd)

function showPathMapPostRender()
    if showingPathMap then
        if showingPathMap.TargetMapSets[1] then
            local map = showingPathMap.TargetMapSets[1].Map
            for i = 0, REVEL.room:GetGridSize() do
                local pos = Isaac.WorldToScreen(REVEL.room:GetGridPosition(i))
                if map[i] then
                    Isaac.RenderText(tostring(map[i]), pos.X, pos.Y, 255, 255, 255, 255)
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
                local pos = Isaac.WorldToRenderPosition(e.Position)
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

Isaac.DebugString("Revelations: Loaded Commands!")
end
REVEL.PcallWorkaroundBreakFunction()