local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local SnowmenEffects = {}

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function(currentRoom, firstLoad)
    SnowmenEffects = {}
end)

local function UpdateExplodingSnowmanSprite(grid, persistData)
    local index = grid:GetGridIndex()
    if not SnowmenEffects[index] then
        SnowmenEffects[index] = REVEL.SpawnDecorationFromTable(grid.Position, Vector.Zero, {
            Sprite = "gfx/grid/revel1/exploding_snowman.anm2",
            Anim = "Idle",
            RemoveOnAnimEnd = false,
        })
    end
    local eff = SnowmenEffects[index]
    local effSprite = eff:GetSprite()

    local sprite = grid:GetSprite()
    
    effSprite.FlipX = sprite.FlipX

    if persistData.Exploded then
        sprite:Play("Blown", true)
        effSprite:Play("Blown", true)
    elseif math.floor( REVEL.GetPoopDamagePct(grid) * 4 ) == 3 then
        sprite:Play("ReadyToExplode", true)
        effSprite:Play("ReadyToExplode", true)
    elseif REVEL.GetPoopDamagePct(grid) > 0 then
        sprite:Play("IdleMedium", true)
        effSprite:Play("IdleMedium", true)
    else
        sprite:Play("Idle", true)
        effSprite:Play("Idle", true)
    end
end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, function(customGrid)
    UpdateExplodingSnowmanSprite(customGrid.GridEntity, customGrid.PersistentData)
end, REVEL.GRIDENT.EXPLODING_SNOWMAN.Name)

---@param customGrid CustomGridEntity
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 1, function(customGrid)
    local grid = customGrid.GridEntity
    local persistData = customGrid.PersistentData
    local grindex = customGrid.GridIndex
    
    if not persistData.Exploded 
    and (
        REVEL.IsGridBroken(grid)
        or grid:GetType() ~= GridEntityType.GRID_POOP -- fallback in case the grid is somehow replaced
    ) then
        persistData.Exploded = true

        local gpos = REVEL.room:GetGridPosition(grindex)
        REVEL.Glacier.SnowExplosion(gpos, REVEL.GlacierBalance.ExplodingSnowmanRadius)

        -- for i = 1, 7 do
        --     local off = 360 / 7
        --     local vel = Vector.FromAngle(i * off + off * math.random()) * math.random() * 5
        --     local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, gpos, vel, nil)
        --     snowp:GetSprite():Play("Appear", true)
        --     snowp:GetSprite().Offset = Vector(0,-25)
        --     snowp:GetData().Rot = math.random()*20-10
        -- end

    end

    UpdateExplodingSnowmanSprite(grid, persistData)
end, REVEL.GRIDENT.EXPLODING_SNOWMAN.Name)

end