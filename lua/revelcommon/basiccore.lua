local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local PlayerVariant     = require("lua.revelcommon.enums.PlayerVariant")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---@return Entity[]
REVEL.GetRoomEntities = function() return REVEL.roomEntities end
---@return EntityTear[]
REVEL.GetRoomTears = function() return REVEL.roomTears end
---@return EntityFamiliar[]
REVEL.GetRoomFamiliars = function() return REVEL.roomFamiliars end
---@return EntityPickup[]
REVEL.GetRoomPickups = function() return REVEL.roomPickups end
---@return EntityBomb[]
REVEL.GetRoomBombdrops = function() return REVEL.roomBombdrops end
---@return Entity[]
REVEL.GetRoomSlots = function() return REVEL.roomSlots end
---@return EntityLaser[]
REVEL.GetRoomLasers = function() return REVEL.roomLasers end
---@return EntityKnife[]
REVEL.GetRoomKnives = function() return REVEL.roomKnives end
---@return EntityProjectile[]
REVEL.GetRoomProjectiles = function() return REVEL.roomProjectiles end
---@return EntityNPC[]
REVEL.GetRoomEnemies = function() return REVEL.roomEnemies end
---@return EntityNPC[]
REVEL.GetRoomNPCs = function() return REVEL.roomNPCs end
---@return EntityNPC[]
REVEL.GetRoomFires = function() return REVEL.roomFires end
---@return EntityEffect[]
REVEL.GetRoomEffects = function() return REVEL.roomEffects end

REVEL.dirToVel = {
        [-1] = Vector(0,0),
        [0] = Vector(-1,0),
        [1] = Vector(0,-1),
        [2] = Vector(1,0),
        [3] = Vector(0,1),
    }

REVEL.dirToShootAction = {
        [0] = ButtonAction.ACTION_SHOOTLEFT,
        [1] = ButtonAction.ACTION_SHOOTUP,
        [2] = ButtonAction.ACTION_SHOOTRIGHT,
        [3] = ButtonAction.ACTION_SHOOTDOWN,
    }

REVEL.dirToString = {
    [0] = "Left",
    [1] = "Up",
    [2] = "Right",
    [3] = "Down",
}

REVEL.stringToDir = {
    ["Left"] = 0,
    ["Up"] = 1,
    ["Right"] = 2,
    ["Down"] = 3,
}

REVEL.dirToAngle = {
    [0] = 180,
    [1] = -90,
    [2] = 0,
    [3] = 90,
}

REVEL.dirStringToVector = {
    Right = Vector(1, 0),
    Left = Vector(-1, 0),
    Down = Vector(0, 1),
    Up = Vector(0, -1),
}

REVEL.VEC_RIGHT = Vector(1,0)
REVEL.VEC_UP = Vector(0, -1)
REVEL.VEC_LEFT = Vector(-1, 0)
REVEL.VEC_DOWN = Vector(0, 1)
REVEL.VEC_DEF_ROOM_SIZE = Vector(520, 280)
REVEL.DEF_INVISIBLE = Color(1,1,1,0,conv255ToFloat(0,0,0))
REVEL.COLOR_W = Color(1,1,1,1,conv255ToFloat(255,255,255))
REVEL.COLOR_B = Color(0,0,0,1,conv255ToFloat(0,0,0))
REVEL.LOWA_COLOR = Color(1,1,1,0.15,conv255ToFloat(0,0,0))
REVEL.NO_COLOR = Color(0,0,0,0,conv255ToFloat(0,0,0))
REVEL.CHILL_COLOR = Color(1,1,1,1,conv255ToFloat(0,90,150))
REVEL.CHILL_COLOR_LOWA = Color(1,1,1,0.15,conv255ToFloat(0,90,150))
REVEL.HOMING_COLOR = Color(0.375,0,0.5,1,conv255ToFloat(75,0,100)) --Color(0.4,0.15,0.15,1,conv255ToFloat(70,0,115))
REVEL.SPECTRAL_COLOR = Color(1.5,2.0,2.0,0.5,conv255ToFloat(0,0,0))
REVEL.TAR_COLOR = Color(0.15,0.15,0.15,1,conv255ToFloat(0,0,0))
REVEL.HURT_COLOR = Color(0.5,0.5,0.5,1.0,conv255ToFloat(200,0,0))
REVEL.YELLOW_OUTLINE_COLOR = Color(0, 0, 0, 1,conv255ToFloat( -255 + 255, -255 + 200, -255 + 20))
REVEL.WORLD_TO_SCREEN_RATIO = 26 / 40
REVEL.SCREEN_TO_WORLD_RATIO = 40 / 26

-- Fill autocomplete (lua vscode has its quirks)
if false then
    ---@type EntityPlayer
    REVEL.player = Isaac.GetPlayer(0)

    ---@type EntityPlayer[]
    REVEL.players = {Isaac.GetPlayer(0)}

    ---@type EntityPlayer[]
    REVEL.playersAndBabies = {Isaac.GetPlayer(0)}
end

REVEL.IndexFunctions = {}

---@class RevEntDef.Params
---@field Name string
---@field SubType integer
---@field NoChampion boolean
---@field NoHurtWisps boolean
---@field Height number Used by Airmovement/ZPos code

---@param name string
---@param subtype? integer
---@param params? RevEntDef.Params
---@return RevEntDef
---@overload fun(name: string, params: RevEntDef.Params): RevEntDef
---@overload fun(params: RevEntDef.Params): RevEntDef
function REVEL.ent(name, subtype, params)
    if type(name) == "table" then
        params = name
        name = name.Name
        subtype = params.SubType
    elseif type(subtype) == "table" then
        params = subtype
        subtype = params.SubType
    end

    subtype = subtype or 0

    REVEL.Assert(name, "REVEL.ent | name not specified!", 2)

    ---@class RevEntDef
    local inst = {
        name = name,
        id = Isaac.GetEntityTypeByName(name),
        variant = Isaac.GetEntityVariantByName(name),
        subtype = subtype,
    }

    if inst.id == -1 then error("Tried to register entity with id -1!") end

    ---@param callback ModCallbacks
    ---@param func fun(entity: Entity, ...)
    function inst:addCallback(callback, func) --this only works for callbacks that have entity as the first arg
        revel:AddCallback(callback, function(_, ent, ...)
            if ent.Type == self.id and ent.Variant == self.variant and (ent.SubType == self.subtype or self.subtype == 0) then
                func(ent, ...)
            end
        end)
    end

    ---@param pos Vector
    ---@param vel Vector
    ---@param spawner? Entity
    ---@return Entity
    function inst:spawn(pos, vel, spawner)
        local e = Isaac.Spawn(self.id, self.variant, self.subtype, pos, vel, spawner)
        e.SpawnerEntity = spawner
        return e
    end

    ---@param ent Entity|RevEntDef
    ---@param useSubtype? boolean
    ---@return boolean
    function inst:isEnt(ent, useSubtype)
        if ent and ent.Type then
            return ent ~= nil and ent.Type == inst.id and ent.Variant == inst.variant and (ent.SubType == subtype or not useSubtype)
        elseif ent and ent.id then
            return ent ~= nil and ent.id == inst.id and ent.variant == inst.variant and (ent.subtype == subtype or not useSubtype)
        end
        return false
    end

    ---@param etype integer
    ---@param variant integer
    ---@param subtype? integer
    ---@return boolean
    function inst:matchesSpawn(etype, variant, subtype)
        return etype == self.id
            and variant == self.variant
            and (not subtype or subtype == self.subtype)
    end

    ---@param useSubtype? boolean
    ---@param cache? boolean
    ---@param ignoreFriendly? boolean
    ---@return Entity[]
    function inst:getInRoom(useSubtype, cache, ignoreFriendly)
        return Isaac.FindByType(inst.id, inst.variant, useSubtype and inst.subtype or -1, cache, ignoreFriendly)
    end

    ---@param useSubtype? boolean
    ---@param spawner? Entity
    ---@return integer
    function inst:countInRoom(useSubtype, spawner)
        return Isaac.CountEntities(spawner, inst.id, inst.variant, useSubtype and inst.subtype or -1) or 0
    end

    if params then
        if params.NoHurtWisps then
            -- Maybe check that it is an npc?
            REVEL.MakeNpcWispImmune(inst)
        end
        if params.NoChampion then
            REVEL.BlacklistChampionNpc(inst)
        end
        if params.Height then
            REVEL.RegisterEntityHeight(inst.id, inst.variant, params.Height)
        end
    end

    return inst
end

---@class RevPlayerDef
---@field Name string
---@field Tainted boolean
---@field Type integer

---@param name string
---@param tainted? boolean
---@return RevPlayerDef
function REVEL.registerPlayer(name, tainted)
    return {
        Name = name,
        Tainted = tainted,
        Type = Isaac.GetPlayerTypeByName(name, tainted),
    }
end

REVEL.REGISTERED_ITEMS = {} --items by name
REVEL.REGISTERED_ITEM_IDS = {} --items by id
REVEL.ITEMS_MAP = {} --item names saved by "soft id" to allow spawning

REVEL.loadedConfigItems = false

---comment
---@param softId integer
---@param name string
---@param costume? string
---@param exclusive? boolean
---@param power? integer
---@param disable? boolean
---@return RevItemDef
function REVEL.registerItem(softId, name, costume, exclusive, power, disable)
    ---@class RevItemDef
    ---@field ConfigItem any # would be ConfigItem class
    local inst = {
        id = Isaac.GetItemIdByName(name),
        name = name,
        softId = softId,
        item = true,
        exclusive = exclusive,
        power = power,
        disabled = disable,
        costumeConditions = {},
        effectItemBlocklist = {}, -- list of item ids that, when possessed by the player, should disable the item entirely
        effectCharacterBlockset = {}, -- set of character names that block this item's effects
        costumeItemBlocklist = {}, --similar as above, separate in case a mod wants to redo effects for an interaction but keep the costume
        costumeCharacterBlockset = {}, -- the idea being, this would probably be used for synergies/interactions, not outright disabling the item
    }

    if disable then
        inst.exclusive = true
    end

    if inst.id == -1 then error("Tried to register item with id -1!") end

    function inst:addCallback(callback, func) --this only works for callbacks where you can specify the id as an arg in addcallback
        revel:AddCallback(callback, func, self.id)
    end

    function inst:addPickupCallback(func, priority)
            StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, priority or 0, func, self.id)
    end

    function inst:addCostumeCondition(func) --add a function (args: player) to make the costume not appear if it returns false, appear if returns true
        table.insert(self.costumeConditions, func)
    end

    function inst:addItemRerollCondition(func) --see LOCKED ITEMS for definition of main function
        REVEL.AddItemRerollCondition(self.id, func)
    end

    function inst:GetConfigItem() --only returns after game started (for mod compatibility in case mods load after), errors before
        if not REVEL.loadedConfigItems then
            error("Used item:GetConfigItem() before GAME_START!")
        else
            return self.ConfigItem --defined down
        end
    end

    function inst:CanPlayerUseItem(player)
        if not self.effectCharacterBlockset[player:GetPlayerType()] and not REVEL.HasCollectibleInList(player, self.effectItemBlocklist) then
            return StageAPI.CallCallbacksWithParams(RevCallbacks.ITEM_CHECK, true, self.id) ~= false
        else
            return false
        end
    end
    
    -- Used in rev's item callbacks, to check whether to apply the items' effect
    function inst:PlayerHasCollectible(player, ignoreBlacklist)
        if not REVEL.IsValidPlayer(player) then return false end
        return player:HasCollectible(self.id) and (ignoreBlacklist or self:CanPlayerUseItem(player))
    end

    function inst:OnePlayerHasCollectible(ignoreBlacklist)
        local ret
        for _, player in ipairs(REVEL.players) do
            ret = ret or self:PlayerHasCollectible(player, ignoreBlacklist)
        end
        return ret
    end

    function inst:GetCollectibleNum(player, ignoreBlacklist, onlyReal)
        if self:PlayerHasCollectible(player, ignoreBlacklist) then
            return player:GetCollectibleNum(self.id, onlyReal)
        else
            return 0
        end
    end

    -- Call it like :AddBlockingItems(item1, item2, ...) or :AddBlockingItems{item1, item2, ...}
    function inst:AddBlockingItems(...)
        local params = {...}
        if type(params[1]) == "table" then params = params[1] end

        self.effectItemBlocklist = REVEL.ConcatTables(self.effectItemBlocklist, params)
    end

    -- Call it like :AddBlockingItems(item1, item2, ...) or :AddBlockingItems{item1, item2, ...}
    function inst:AddBlockingCharacter(playerType)
        self.effectCharacterBlockset[playerType] = true
    end

    function inst:AddCostumeBlockingItems(...)
        local params = {...}
        if type(params[1]) == "table" then params = params[1] end

        self.costumeItemBlocklist = REVEL.ConcatTables(self.costumeItemBlocklist, params)
    end

    function inst:AddCostumeBlockingCharacter(playerType)
        self.costumeCharacterBlockset[playerType] = true
    end

    if costume then costume = Isaac.GetCostumeIdByPath(costume) end
    if costume ~= -1 and costume then
        inst.costume = costume

        inst:addPickupCallback(function(player)
            local shouldAdd = false
            for i,func in ipairs(inst.costumeConditions) do
                if func(player) then shouldAdd = true end
            end
            shouldAdd = shouldAdd or #inst.costumeConditions == 0
            shouldAdd = shouldAdd and not inst.costumeCharacterBlockset[player:GetPlayerType()] 
                and not REVEL.HasCollectibleInList(player, inst.costumeItemBlocklist)

            if shouldAdd then
                player:AddNullCostume(REVEL.REGISTERED_ITEMS[inst.name].costume)
            end
        end)
    end

    REVEL.REGISTERED_ITEMS[name] = inst
    REVEL.REGISTERED_ITEM_IDS[inst.id] = inst
    REVEL.ITEMS_MAP[softId] = name
    return inst
end

---@param softId integer
---@return RevItemDef
function REVEL.getItemBySoftId(softId)
    return REVEL.REGISTERED_ITEMS[REVEL.ITEMS_MAP[softId]]
end

REVEL.REGISTERED_TRINKETS = {} --trinkets by name
REVEL.REGISTERED_TRINKET_IDS = {} --trinkets by id
REVEL.TRINKETS_MAP = {} --trinket names saved by "soft id" to allow spawning

---@param softId integer
---@param name string
---@param exclusive? boolean
---@return RevTrinketDef
function REVEL.registerTrinket(softId, name, exclusive)
    ---@class RevTrinketDef
    local inst = {
        id = Isaac.GetTrinketIdByName(name),
        name = name,
        softId = softId,
        trinket = true,
        exclusive = exclusive
    }

    if inst.id == -1 then error("Tried to register trinket with id -1!") end

    REVEL.REGISTERED_TRINKETS[name] = inst
    REVEL.REGISTERED_TRINKET_IDS[inst.id] = inst
    REVEL.TRINKETS_MAP[softId] = name
    return inst
end

---@param softId integer
---@return RevTrinketDef
function REVEL.getTrinketBySoftId(softId)
    return REVEL.REGISTERED_TRINKETS[REVEL.TRINKETS_MAP[softId]]
end

REVEL.UNLOCKABLES_BY_ID = {}

---@param unlockimg string
---@param itemID integer
---@param menuName string
---@param menuLocked string
---@param menuIcon? string
---@param isTrinket? boolean
---@return RevUnlockable
function REVEL.unlockable(unlockimg, itemID, menuName, menuLocked, menuIcon, isTrinket)
    ---@class RevUnlockable
    local obj = {
        img = unlockimg, 
        item = itemID, 
        menuName = menuName, 
        menuLocked = menuLocked, 
        menuIcon = menuIcon,
        isTrinket = isTrinket
    }
    if itemID then
        REVEL.UNLOCKABLES_BY_ID[itemID] = obj
    end
    return obj
end

REVEL.game = Game()
REVEL.config = Isaac.GetItemConfig()

REVEL.music = MusicManager()
REVEL.pool = REVEL.game:GetItemPool()

---@type Level
REVEL.level = nil
---@type Room
REVEL.room = nil

-- true: p1 is > p2
-- In this case: place normal players before coop players
local function playersComp(p1, p2)
    return p1.Variant == PlayerVariant.PLAYER and p2.Variant ~= PlayerVariant.PLAYER
end

local function GetPlayersAndSetIDs(includeCoopBabies)
    local allPlayers = {}
    for i = 1, REVEL.game:GetNumPlayers() do
        allPlayers[i] = Isaac.GetPlayer(i - 1)
    end

    -- Place babies after normal players
    table.sort(allPlayers, playersComp)

    local players = {}
    local numNormalPlayers = 0
    for i, player in ipairs(allPlayers) do
        local isNormal = player.Variant == PlayerVariant.PLAYER
        if isNormal then
            numNormalPlayers = numNormalPlayers + 1
        end
        if isNormal or includeCoopBabies then
            local playerId = i
            if not isNormal and numNormalPlayers < 4 then
                playerId = playerId + (4 - numNormalPlayers)
            end
            players[playerId] = player
            REVEL.GetData(player).playerID = playerId
            if players[playerId]:GetSubPlayer() then
                REVEL.GetData(players[playerId]:GetSubPlayer()).playerID = playerId
            end

            if players[playerId]:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN and REVEL.roomKnives then
                for j,v in ipairs(REVEL.roomKnives) do
                    if v and v.Variant == 1 and v.Parent then
                        if v.Parent.InitSeed == players[playerId].InitSeed then
                        players[playerId]:GetData().Bone = v
                        v:GetData().__player = players[playerId]
                        v:GetData().ForgottenThrownBone = true
                        end
                    end
                end
            end
        end
    end

    return players
end

-- FOR STABILITY WE SHOULD NO LONGER STORE THE PLAYER AT ALL, AS THIS CAN LEAD TO ADVERSE EFFECTS WITH CO-OP PLAYERS, 
-- WHO CAN JOIN OUT AT ANY TIME AND CAUSE A GAME CRASH WHEN USED.
-- player and players are still used, just always mapping to a function.
setmetatable(REVEL,
{
    __index = function(self, k)
        if k == "room" then
            error("[REVEL] Tried to access room before first setting, this shouldn't happen" .. REVEL.TryGetTraceback(false, true), 2)
        elseif k == "level" then
            error("[REVEL] Tried to access level before first setting, this shouldn't happen" .. REVEL.TryGetTraceback(false, true), 2)

        elseif k == "player" then
			local player = Isaac.GetPlayer(0)
            return player

        elseif k == "players" then
            return GetPlayersAndSetIDs(false)
        elseif k == "playersAndBabies" then
            return GetPlayersAndSetIDs(true)
        elseif k == "alivePlayers" then
            local players = self.players -- calls "players" metaindex defined above

            return players

		elseif k == "collectiblesSize" then
			revel:UpdateCollSize()
			return self[k]
        elseif self.IndexFunctions[k] then
            return self.IndexFunctions[k]()
        end
    end
})

-- SfxManager wrapper and REVEL.registerSound
-- mostly used for tweaks to all sounds
-- Like in the Repentance patch, where all 
-- custom sounds have been reported to be louder
-- Also has an extra NpcPlay function 
-- to emulate npc:PlaySound while doing the same thing
do
    local sfxManager = SFXManager()

    local RevSfxManager = {
        BaseManager = sfxManager,
        CustomSoundsVolumeMult = 1,
    }

    REVEL.sfx = RevSfxManager

    local revSoundsMap = {}
    local revSoundsVolumeMult = {}

    -- Returns sound id, can optionally specify a
    -- volume multiplier for all uses of this sound in the mod
    function REVEL.registerSound(name, volumemult)
        local id = Isaac.GetSoundIdByName(name)
        revSoundsMap[id] = name

        if volumemult then
            revSoundsVolumeMult[id] = volumemult
        end

        return id
    end

    function RevSfxManager:_getVolumeMult(id)
        if revSoundsMap[id] then
            return self.CustomSoundsVolumeMult * (revSoundsVolumeMult[id] or 1) * (revel.data.volumeMult or 1)
        else
            return 1
        end
    end

    function RevSfxManager:Play(id, volume, frameDelay, loop, pitch, pan)
        if revSoundsMap[id] and REVEL.LOG_SOUNDS then
            REVEL.DebugToString("Played sound " .. id .. ", '" .. revSoundsMap[id] .. "'")
        end

        self.BaseManager:Play(id, (volume or 1) * self:_getVolumeMult(id), frameDelay, loop, pitch, pan)
    end

    ---@param npc EntityNPC
    ---@param id integer
    ---@param volume? number
    ---@param frameDelay? integer
    ---@param loop? boolean
    ---@param pitch? number
    function RevSfxManager:NpcPlay(npc, id, volume, frameDelay, loop, pitch)
        npc:PlaySound(id, (volume or 1) * self:_getVolumeMult(id), frameDelay or 0, loop == true, pitch or 1)
    end

    function RevSfxManager:AdjustPitch(id, pitch)
        self.BaseManager:AdjustPitch(id, pitch)
    end

    function RevSfxManager:AdjustVolume(id, volume)
        self.BaseManager:AdjustVolume(id, (volume or 1) * self:_getVolumeMult(id))
    end

    function RevSfxManager:GetAmbientSoundVolume(id)
        return self.BaseManager:GetAmbientSoundVolume(id) / self:_getVolumeMult(id)
    end

    function RevSfxManager:IsPlaying(id)
        return self.BaseManager:IsPlaying(id)
    end

    function RevSfxManager:Preload(id)
        self.BaseManager:Preload(id)
    end

    function RevSfxManager:SetAmbientSound(id, volume, pitch)
        if revSoundsMap[id] then
            self.BaseManager:SetAmbientSound(id, (volume or 1) * self:_getVolumeMult(id), pitch)
        else
            self.BaseManager:SetAmbientSound(id, volume, pitch)
        end
    end

    function RevSfxManager:Stop(id)
        self.BaseManager:Stop(id)
    end

    function RevSfxManager:StopLoopingSounds()
        self.BaseManager:StopLoopingSounds()
    end
end

-- Music cues
-- Goes here as definitions call the REVEL.GetMusicAndCues function

do
    REVEL.CuesByTrackId = {}

    ---@class MusicCuesTrack
    ---@field Track integer
    ---@field Name string
    ---@field Cues table<string, integer[]>
    ---@field AllCues integer[]
    ---@field Duration integer

    --Returns a table: {Track = <music id>, Duration = <track duration>, Cues = {<cue track 1> = <table>, [<cue track 2> = table ...]}, Name = <track name>}
    ---@param trackName string
    ---@param cuesFilePath string
    ---@return MusicCuesTrack
    function REVEL.GetMusicAndCues(trackName, cuesFilePath)
        local trackId = Isaac.GetMusicIdByName(trackName)
        local cuesTable = include("resources.music." .. cuesFilePath)
        
        local ret = {Track = trackId, Name = trackName, Cues = cuesTable.Cues, Duration = cuesTable.Duration}

        ret.AllCues = {}

        for _, cueSet in pairs(ret.Cues) do
            for __, cueTime in ipairs(cueSet) do
                local i, done = 1, false
                while not done do
                    if ret.AllCues[i] == cueTime or ret.AllCues[i+1] == cueTime then
                        done = true --don't add the time to the common table, there's already one
                    elseif not ret.AllCues[i] or ret.AllCues[i] > cueTime then
                        done = true
                        table.insert(ret.AllCues, i, cueTime)
                    else
                        i = i + 1
                    end
                end
            end
        end

        if cuesTable.Loop == nil then
            ret.Loop = true
        else
            ret.Loop = cuesTable.Loop
        end

        REVEL.CuesByTrackId[trackId] = ret

        return ret
    end
end

REVEL.CUSTOM_PILLS_BY_ID = {}

---@class CustomPillDef
---@field ColorId integer
---@field Anm2 string

--- Custom pill definitions
---@param colorId integer
---@param anm2 string
---@return CustomPillDef
function REVEL.CustomPill(colorId, anm2)
    local entry = {
        ColorId = colorId,
        Anm2 = anm2,
    }
    REVEL.CUSTOM_PILLS_BY_ID[colorId] = entry
    return entry
end

-- RNG class Wrapper
-- Currently only checks if seed is 0, in which case it
-- warns and uses 1

do

local RandomFuncs = {
    "Next",
    "RandomFloat",
    "RandomInt",
}

local SHIFT_MAX = 80
local C_INT_MAX = 2147483647


---@return RevRNG
function REVEL.RNG()
    -- private fields
    local trackOffset = 0
    local base = RNG()

    ---@class RevRNG : RNG
    local customRNG = {
    }

    function customRNG:SetSeed(seed, shiftIdx)
        seed = seed % C_INT_MAX
        shiftIdx = shiftIdx % SHIFT_MAX
        if seed == 0 then
            if REVEL.PRINT_SEED_WARNING then
                REVEL.DebugToString("[REVEL] WARN: Tried to set RNG seed to 0, using 1", REVEL.TryGetCallInfo(3))
            end
            seed = 1
        end
        if REVEL.PRINT_SEED then
            REVEL.DebugToString("[REVEL] DEBUG: Setting new RNG seed to", seed, REVEL.TryGetCallInfo(3))
        end
        base:SetSeed(seed, shiftIdx)
    end

    function customRNG:GetRNG()
        return base
    end

    function customRNG:GetOffset()
        return trackOffset
    end

    for _, name in ipairs(RandomFuncs) do
        customRNG[name] = function(self, ...)
            trackOffset = trackOffset + 1
            return base[name](base, ...)
        end
    end

    function customRNG:GetSeed()
        return base:GetSeed()
    end

    -- local baseMetatable = getmetatable(customRNG.Base)
    local newMetatable = {}

    -- for k, v in pairs(baseMetatable) do
    --     newMetatable[k] = v
    -- end

    function newMetatable.__index(self, key)
        return base[key]
    end

    setmetatable(customRNG, newMetatable)

    return customRNG
end

end

-- Wisp immunity

--#region WispImmunity

WispImmuneNPCs = {}

local wispImmunity_PreNpcCollision

---@param etype EntityType
---@param variant? integer
---@overload fun(entDef: RevEntDef)
function REVEL.MakeNpcWispImmune(etype, variant)
    if type(etype) == "table" then
        variant = etype.variant
        etype = etype.id
    end

    if not WispImmuneNPCs[etype] then
        revel:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, wispImmunity_PreNpcCollision, etype)
    end

    if variant then
        WispImmuneNPCs[etype] = WispImmuneNPCs[etype] or {}
        WispImmuneNPCs[etype][variant] = true
    else
        WispImmuneNPCs[etype] = true
    end
end

---@param npc EntityNPC
---@param collider Entity
---@param low boolean
---@return boolean? ignoreCollision
function wispImmunity_PreNpcCollision(_, npc, collider, low)
    if collider.Type == EntityType.ENTITY_FAMILIAR 
    and (
        collider.Variant == FamiliarVariant.WISP 
        or collider.Variant == FamiliarVariant.ITEM_WISP
    ) 
    and (
        WispImmuneNPCs[npc.Type] == true
        or WispImmuneNPCs[npc.Type] and WispImmuneNPCs[npc.Type][npc.Variant]
    )
    then
        -- Ignore collision
        return true
    end
end

---@param familiar EntityFamiliar
---@param collider Entity
---@param low boolean
---@return boolean? ignoreCollision
local function wispImmunity_PreFamiliarCollision(_, familiar, collider, low)
    if WispImmuneNPCs[collider.Type] == true
    or WispImmuneNPCs[collider.Type] and WispImmuneNPCs[collider.Type][collider.Variant]
    then
        -- Ignore collision
        return true
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, wispImmunity_PreFamiliarCollision, FamiliarVariant.WISP)
revel:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, wispImmunity_PreFamiliarCollision, FamiliarVariant.ITEM_WISP)

--#endregion

--#region Height
--Entity height, used by Airmovement/Zpos

---@type table<integer, table<integer, table<integer, number>>>
local EntityHeight = {}

---@param etype integer
---@param evariant integer
---@param esubtype integer
---@param height number
---@overload fun(etype: integer, evariant: integer, height: number)
---@overload fun(etype: integer, height: number)
function REVEL.RegisterEntityHeight(etype, evariant, esubtype, height)
    if not height then
        if esubtype then
            height = esubtype
            esubtype = -1
        elseif evariant then
            height = evariant
            evariant = -1
            esubtype = -1
        else
            error("RegisterEntityHeight | needs to specify at least 2 values", 2)
        end
    end

    EntityHeight[etype] = EntityHeight[etype] or {}
    EntityHeight[etype][evariant] = EntityHeight[etype][evariant] or {}
    EntityHeight[etype][evariant][esubtype] = height
end

---@param entity Entity
--@return number
function REVEL.GetEntityHeight(entity)
    local varTable = EntityHeight[entity.Type] and (
        EntityHeight[entity.Type][entity.Variant]
        or EntityHeight[entity.Type][-1]
    )
    if varTable and (varTable[entity.SubType] or varTable[-1]) then
        return varTable[entity.SubType] or varTable[-1]
    end
    -- default to Size
    return entity.Size
end

--#endregion

Isaac.DebugString("Revelations: Loaded Definitions Initialization!")
end