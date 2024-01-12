local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

--Scale entity, since base game doesn't work in single npc updates

local ScaledEnts = {}

---@class CustomScaleData
---@field SpriteScale number | Vector # percent | Vector
---@field SizeScale number # percent
---@field HealthScale number # percent
---@field ScaleChildren boolean

---@param entity any #Entity
---@param customScaleData CustomScaleData
function REVEL.ScaleEntity(entity, customScaleData)
    local data = entity:GetData()
    local hash = GetPtrHash(entity)

    if not ScaledEnts[hash] then
        ScaledEnts[hash] = entity
    end

    if type(customScaleData.SpriteScale) == "number" then
        customScaleData.SpriteScale = Vector.One * customScaleData.SpriteScale
    end

    entity.Size = entity.Size * (customScaleData.SizeScale or 1)

    local hp, maxHp = entity.HitPoints, entity.MaxHitPoints
    local minHp = 0
    hp = hp - minHp
    maxHp = maxHp - minHp

    local percentHP = hp / maxHp
    entity.MaxHitPoints = maxHp * (customScaleData.HealthScale or 1)
    entity.HitPoints = minHp + entity.MaxHitPoints * percentHP
    entity.MaxHitPoints = entity.MaxHitPoints + minHp

    data.CustomScaleData = customScaleData
end

function REVEL.ScaleChildEntity(parent, child)
    local data = parent:GetData()
    if data.CustomScaleData and data.CustomScaleData.ScaleChildren then
        REVEL.ScaleEntity(child, data.CustomScaleData)
    end
end

local function scaleEntityPostUpdate()
    for hash, ent in pairs(ScaledEnts) do
        if not ent:Exists() then
            ScaledEnts[hash] = nil
        elseif ent:GetData().CustomScaleData.SpriteScale then
            local doSetScale = true

            if ent.Type == EntityType.ENTITY_LASER then
                local laser = ent:ToLaser()
                if laser.Timeout < 0 then
                    local dieScaleMult = REVEL.Lerp2Clamp(1, 0, laser.Timeout, 0, -20)
                    ent.SpriteScale = ent:GetData().CustomScaleData.SpriteScale * dieScaleMult
                    doSetScale = false
                end
            end

            if doSetScale then
                ent.SpriteScale = ent:GetData().CustomScaleData.SpriteScale
            end
        end
    end
end

local function scaleEntityPostNewRoom()
    ScaledEnts = {}
end

local function scaleEntityNpcInit(npc)
    local parent = npc.SpawnerEntity or npc.Parent
    if parent then
        REVEL.ScaleChildEntity(parent, npc)
    end
end


revel:AddCallback(ModCallbacks.MC_POST_UPDATE, scaleEntityPostUpdate)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, scaleEntityPostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, scaleEntityNpcInit)

end