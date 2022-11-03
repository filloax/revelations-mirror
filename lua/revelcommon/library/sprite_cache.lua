local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Since too many mods = memory issues, try to offer tools
-- to make removing unused sprites easier

---@alias RevSpriteCache.ID any

---@class SpriteProxy : Sprite

local SpriteFunctionNames = {
    "PlayOverlay", "IsPlaying", "GetFilename", "IsOverlayPlaying", 
    "SetAnimation", "WasEventTriggered","SetFrame", "IsEventTriggered", 
    "IsLoaded", "RemoveOverlay", "SetOverlayAnimation", "SetLayerFrame", 
    "ReplaceSpritesheet", "GetDefaultAnimationName", "GetFrame", "Reset", 
    "Render", "SetOverlayFrame", "Play", "SetLastFrame", 
    "GetLayerCount", "GetOverlayAnimation", "SetOverlayRenderPriority", "Update", 
    "Stop", "IsOverlayFinished", "RenderLayer", "GetDefaultAnimation", 
    "Load", "GetTexel", "GetOverlayFrame", "IsFinished", 
    "LoadGraphics", "Reload", "GetAnimation", "PlayRandom",     
}

---@param getSprite fun(): Sprite
---@return SpriteProxy
local function MakeSpriteProxy(getSprite)
    local proxy = {}
    for _, key in ipairs(SpriteFunctionNames) do
        proxy[key] = function(self, ...)
            local sprite = getSprite()
            return sprite[key](sprite, ...)
        end
    end

    setmetatable(proxy, {
        __index = function(self, key)
            return getSprite()[key]
        end,
        __newindex = function(self, key, value)
            getSprite()[key] = value
        end,
    })

    return proxy
end

--#region RoomSprite

---@class RoomSprite.Params
---@field ID RevSpriteCache.ID
---@field Anm2 string?
---@field Animation string?
---@field Color Color?
---@field Scale Vector?
---@field Offset Vector?
---@field PlaybackSpeed number?
---@field OnCreate (fun(sprite: Sprite))?

---@type table<RevSpriteCache.ID, Sprite>
local RoomSprites = {}

-- handle reload
if REV_RELOAD_PERSIST.RoomSprites and Isaac.GetPlayer(0) then
    RoomSprites = REV_RELOAD_PERSIST.RoomSprites
end
REV_RELOAD_PERSIST.RoomSprites = RoomSprites

---@param params RoomSprite.Params
---@return Sprite
function REVEL.RoomSprite(params)
    REVEL.Assert(type(params) == "table", "Params need to be in a table", 2)
    REVEL.Assert(params.ID, "Params need an ID", 2)

    local id = params.ID
    if not RoomSprites[id] then
        local sprite = Sprite()
        if params.Anm2 then
            sprite:Load(params.Anm2, true)
            if params.Animation then
                sprite:Play(params.Animation, true)
            end
            if params.Color then
                sprite.Color = params.Color
            end
            if params.Scale then
                sprite.Scale = params.Scale
            end
            if params.Offset then
                sprite.Offset = params.Offset
            end

            if params.PlaybackSpeed then
                sprite.PlaybackSpeed = params.PlaybackSpeed
            end
        end
        if params.OnCreate then
            params.OnCreate(sprite)
        end
        RoomSprites[id] = sprite

        REVEL.DebugStringMinor("Created room sprite with id", id)
    end

    return RoomSprites[id]
end

---Returns object that acts like sprite and is only actually 
-- instanced when indexed
-- Meaning you can use it as a sprite but the instance lasts only for a room
---@param params RoomSprite.Params
function REVEL.LazyLoadRoomSprite(params)
    return MakeSpriteProxy(function() 
        return REVEL.RoomSprite(params) 
    end)
end

---@param id RevSpriteCache.ID | RoomSprite.Params
---@return Sprite?
function REVEL.GetRoomSprite(id)
    if type(id) == "table" then 
        id = id.ID 
    end
    return RoomSprites[id]
end

---@param id RevSpriteCache.ID
---@return boolean had
function REVEL.ClearRoomSprite(id)
    local had = not not RoomSprites[id]
    RoomSprites[id] = nil
    return had
end

local function roomSprite_PostNewRoom()
    RoomSprites = {}
    REV_RELOAD_PERSIST.RoomSprites = RoomSprites
end

--#endregion RoomSprite

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 0, roomSprite_PostNewRoom)

    
end

REVEL.PcallWorkaroundBreakFunction()