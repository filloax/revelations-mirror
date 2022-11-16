local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Brazier

local h,s,v = hsvToRgb(0.05,1, 0.6)
local LIGHT_COLOR = Color(h,s,v, 1,conv255ToFloat( 150,150,150))

---@type table<integer, Entity>
local BrazierEffects = {}

StageAPI.AddCallback("Revelations", "POST_SPAWN_CUSTOM_GRID", 1, function(customGrid)
    local grindex = customGrid.GridIndex
    REVEL.SpawnLight(REVEL.room:GetGridPosition(grindex) - Vector(0,10), Color.Default, 1, false, 1000, EffectVariant.RED_CANDLE_FLAME, 0)
    REVEL.SpawnLight(REVEL.room:GetGridPosition(grindex) - Vector(0,10), LIGHT_COLOR, 2.7)
end, REVEL.GRIDENT.BRAZIER.Name)

StageAPI.AddCallback("Revelations", "POST_CUSTOM_GRID_UPDATE", 1, function(customGrid)
    local grid = customGrid.GridEntity
    local grindex = customGrid.GridIndex
    REVEL.SpawnFireParticles(grid.Position, -30, 20, REVEL.game:GetFrameCount() + grindex)
end, REVEL.GRIDENT.BRAZIER.Name)

-- High priority, after other callbacks affect animations
---@param customGrid CustomGridEntity
StageAPI.AddCallback("Revelations", "POST_CUSTOM_GRID_UPDATE", 1000, function(customGrid)
    local sprite = customGrid.GridEntity:GetSprite()
    local index = customGrid.GridIndex
    if not BrazierEffects[index] then
        BrazierEffects[index] = REVEL.SpawnDecorationFromTable(customGrid.GridEntity.Position, Vector.Zero, {
            Sprite = customGrid.GridConfig.Anm2,
            Anim = sprite:GetAnimation(),
            RemoveOnAnimEnd = false,
        })
    end

    BrazierEffects[index]:GetSprite():SetFrame(sprite:GetAnimation(), sprite:GetFrame())
end, REVEL.GRIDENT.BRAZIER.Name)

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 1, function(currentRoom, firstLoad)
    BrazierEffects = {}
end)
    
end