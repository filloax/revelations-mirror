local PitState = require("lua.revelcommon.enums.PitState")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local SNOW_TILE_GROUND = 1
local SNOW_TILE_PIT = 2

function REVEL.Glacier.SnowTile(index)
    local grid = REVEL.room:GetGridEntity(index)
    if grid and grid.Desc.Type == GridEntityType.GRID_WALL then return end

    local numIndex, strIndex

    if type(index) ~= "string" then 
        numIndex = math.floor(index)
        strIndex = tostring(numIndex)
    else
        strIndex = index
        numIndex = math.floor(tonumber(index))
    end

    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom then
        if not currentRoom.PersistentData.SnowedTiles then currentRoom.PersistentData.SnowedTiles = {} end

        local fragileIce = StageAPI.GetCustomGrid(numIndex, REVEL.GRIDENT.FRAGILE_ICE.Name)
        if fragileIce then
            fragileIce:Remove(false)
        end
        if currentRoom.PersistentData.FragileIce then
            currentRoom.PersistentData.FragileIce[strIndex] = nil
        end

        local iceWorms = REVEL.ENT.ICE_WORM:getInRoom()
        for _, e in ipairs(iceWorms) do
            if tostring(REVEL.room:GetGridIndex(e.Position)) == numIndex then
                e:Kill()
            end
        end

        local val = SNOW_TILE_GROUND
        if grid and grid.Desc.Type == GridEntityType.GRID_PIT
        and grid.State ~= PitState.PIT_BRIDGE then
            val = SNOW_TILE_PIT

            grid:ToPit():MakeBridge(grid)
        end

        if not currentRoom.PersistentData.SnowedTiles[strIndex] then
            currentRoom.PersistentData.SnowedTiles[strIndex] = val
            return true
        else --just update type, not a new snow tile though
            currentRoom.PersistentData.SnowedTiles[strIndex] = val
        end
    end

    return false
end

function REVEL.Glacier.RemoveSnowTile(index)
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom.PersistentData.SnowedTiles then
        local strIndex
        local numIndex

        if type(index) == "string" then 
            strIndex = index
            numIndex = math.floor(tonumber(strIndex))
        else
            numIndex = math.floor(index)
            strIndex = tostring(index)
        end
        -- REVEL.DebugLog("RemoveSnowTile", index, strIndex, currentRoom.PersistentData.SnowedTiles[strIndex])

        if currentRoom.PersistentData.SnowedTiles[strIndex] then 
            if currentRoom.PersistentData.SnowedTiles[strIndex] == SNOW_TILE_PIT then
                local grid = REVEL.room:GetGridEntity(numIndex)
                    
                if grid and grid.Desc.Type == GridEntityType.GRID_PIT and grid.State == PitState.PIT_BRIDGE then
                    grid.State = PitState.PIT_NORMAL
                    grid.CollisionClass = GridCollisionClass.COLLISION_PIT
                    StageAPI.BridgedPits[numIndex] = nil
                end
            end

            currentRoom.PersistentData.SnowedTiles[strIndex] = nil
            return true
        end
    end

    return false
end

-- local function SpawnIceSnowTileEffect(index)
--     local e = Isaac.Spawn(StageAPI.E.GenericEffect.T, StageAPI.E.GenericEffect.V, 0, REVEL.room:GetGridPosition(index), Vector.Zero, nil)
--     e:GetData().IsSnowedTileEffect = true
--     local sprite = e:GetSprite()
--     sprite:Load("stageapi/pit.anm2", false)
--     sprite:ReplaceSpritesheet(1, "gfx/grid/revel1/glacier_chill_rocks.png")
--     sprite:LoadGraphics()
--     sprite:SetFrame("pit", 0)
--     -- e.RenderZOffset = -10000
--     return e
-- end

-- There were some render priority issues using floor
-- couldn't solve for some reason, so fuck it, custom renderer
-- in the corner
local SnowTileSpriteParams = {
    ID = "snowtile",
    Anm2 = "stageapi/pit.anm2",
    OnCreate = function(sprite)
        sprite:ReplaceSpritesheet(1, "gfx/grid/revel1/glacier_chill_rocks.png")
        sprite:LoadGraphics()
        sprite:SetFrame("pit", 0)
    end,
}

local SpawnedSnowRenderer = false

local function TrySpawnSnowRenderer()
    if not SpawnedSnowRenderer then
        REVEL.ENT.SNOW_TILE_RENDERER:spawn(REVEL.room:GetTopLeftPos() - Vector(40, 40), Vector.Zero)
        SpawnedSnowRenderer = true
    end
end

local function SpawnIceSnowTileEffectGround(index)
    -- local e = SpawnIceSnowTileEffect(index)
    -- e:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
    -- local e = StageAPI.SpawnFloorEffect(REVEL.room:GetGridPosition(index), Vector.Zero, nil, "stageapi/pit.anm2")
    -- e:GetSprite():ReplaceSpritesheet(1, "gfx/grid/revel1/glacier_chill_rocks.png")
    -- e:GetSprite():LoadGraphics()
    -- e:GetSprite():SetFrame("pit", 0)
    -- REVEL.DebugLog("ground")
    -- return e
    TrySpawnSnowRenderer()
end

local function SpawnSnowTileBridge(grid, index)
    -- StageAPI.CheckBridge(grid, index, "gfx/grid/revel1/glacier_chill_rocks.png")
    -- grid:GetSprite().Offset = Vector.Zero
    -- Since bridges seem to have a weird cutoff problem rn, let's just use the effect for those too
    -- return SpawnIceSnowTileEffect(index)
    TrySpawnSnowRenderer()
end

function REVEL.Glacier.SnowExplosion(pos, radius, effectScale, triggerStalactrites, playSound)
    effectScale = effectScale or 1.2
    radius = radius or REVEL.GlacierBalance.ExplodingSnowmanRadius
    if triggerStalactrites == nil then triggerStalactrites = true end
    if playSound == nil then playSound = true end

    if effectScale > 0 then
        local boom = REVEL.SpawnDecoration(pos, Vector.Zero, "Boom", "gfx/effects/revel1/frost_explosion.anm2")
        boom.SpriteScale = Vector.One * effectScale
    end
    REVEL.game:ShakeScreen(16)
    if playSound then
        REVEL.sfx:Play(SoundEffect.SOUND_MUSHROOM_POOF, 1.2, 0, false, 0.8)
    end

    local currentRoom = StageAPI.GetCurrentRoom()
    local isProng = currentRoom and (currentRoom.PersistentData.BossID == "Prong"
        or (currentRoom.IsExtraRoom and REVEL.ENT.PRONG:countInRoom() > 0))

    if (currentRoom and currentRoom.PersistentData.IcePitFrames) or isProng then
        local indicesToCheck = currentRoom.PersistentData.IcePitFrames

        if isProng then
            indicesToCheck = {}

            local startX, startY = REVEL.GridToVector(REVEL.room:GetGridIndex(pos - Vector(radius, radius)))
            local endX, endY = REVEL.GridToVector(REVEL.room:GetGridIndex(pos + Vector(radius, radius)))
            local startGridPos = Vector(startX, startY)
            local endGridPos = Vector(endX, endY)

            for gridX = startGridPos.X, endGridPos.X do
                for gridY = startGridPos.Y, endGridPos.Y do
                    local index = REVEL.VectorToGrid(gridX, gridY)
                    indicesToCheck[index] = true
                end
            end
        end

        for index, _ in pairs(indicesToCheck) do
            if REVEL.room:GetGridPosition(index):DistanceSquared(pos) < radius ^ 2 then
                if REVEL.Glacier.SnowTile(index) then
                    SpawnIceSnowTileEffectGround(index)
                end
            end
        end
    end

    for i = REVEL.room:GetGridSize(), 0, -1 do
        local grid = REVEL.room:GetGridEntity(i)
        if grid and grid.Desc.Type == GridEntityType.GRID_PIT and grid.State ~= PitState.PIT_BRIDGE 
        and REVEL.room:GetGridPosition(i):DistanceSquared(pos) < radius ^ 2 then
            if REVEL.Glacier.SnowTile(i) then
                SpawnSnowTileBridge(grid, i)
            end
        end
    end

    local iceHazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, true, false)
    for _, hazard in ipairs(iceHazards) do
        if hazard.Position:DistanceSquared(pos) < radius ^ 2 then
            hazard.Velocity = hazard.Velocity + (hazard.Position - pos):Resized(7)
        end
    end

    if triggerStalactrites then
        local stalactrites = REVEL.ENT.STALACTRITE:getInRoom()
        for _, trite in ipairs(stalactrites) do
            trite:GetData().StalactriteTriggered = true
        end
    end

    local fires = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, -1, -1, false, false)
    for _, fire in ipairs(fires) do
        if fire.Variant < 2 and fire.Position:DistanceSquared(pos) < radius ^ 2 then
            fire.HitPoints = 1
            fire:TakeDamage(1, 0, EntityRef(REVEL.player), 0)
        end
    end
end

function REVEL.LoadSnowedTiles(snowedTiles)
    if not snowedTiles then return end

    for strindex, type in pairs(snowedTiles) do
        local index = tonumber(strindex)
        if type == 1 then --was ice pit
            SpawnIceSnowTileEffectGround(index)
            --e:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
            -- REVEL.DelayFunction(0, function() e:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR) end, {}, true, true)
        elseif type == 2 then --was pit
            local grid = REVEL.room:GetGridEntity(index)
            if grid then
                SpawnSnowTileBridge(grid, index)
            end
        end
    end
end

local function snowTile_PostEffectRender(_, effect, renderOffset)
    local currentRoom = StageAPI.GetCurrentRoom()
    if currentRoom and currentRoom.PersistentData.SnowedTiles then
        local snowTileSprite = REVEL.LevelSprite(SnowTileSpriteParams)
        local offset = -REVEL.game.ScreenShakeOffset
        for strindex, _ in pairs(currentRoom.PersistentData.SnowedTiles) do
            local index = tonumber(strindex)
            local pos = REVEL.room:GetGridPosition(index)
            local screenPos = Isaac.WorldToScreen(pos) 
            snowTileSprite:Render(screenPos + offset)
        end
    end
end

local function snowTile_PostNewRoom()
    SpawnedSnowRenderer = false
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, snowTile_PostEffectRender, REVEL.ENT.SNOW_TILE_RENDERER.variant)
revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, snowTile_PostNewRoom)


end