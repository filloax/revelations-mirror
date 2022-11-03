REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.IsOutOfRoomBy(pos, by)
    local tl, br = REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
    return tl.X-pos.X > by or tl.Y-pos.Y > by or pos.X-br.X > by or pos.Y-br.Y > by
end
      
function REVEL.GetGoodPosition(startPos, positions, offset, far)
    offset = offset or Vector.Zero
    local goodPos
    local goodDist
    local goodIndex
    for ind, pos in ipairs(positions) do
        local dist = startPos:Distance(pos + offset)
        local valid
        if goodDist then
            if far then
                valid = dist > goodDist
            else
                valid = dist < goodDist
            end
        end

        if not goodDist or valid then
            goodDist = dist
            goodPos = pos
            goodIndex = ind
        end
    end

    return goodPos, goodIndex, goodDist
end

function REVEL.GetGridPositionAtPos(pos)
    if REVEL.room:IsPositionInRoom(pos, 0) then
        return REVEL.room:GetGridPosition(REVEL.room:GetGridIndex(pos))
    else
        local x = pos.X - (pos.X % 40)
        if pos.X % 40 > 20 then
            x = x + 40
        end
    
        local y = pos.Y - (pos.Y % 40)
        if pos.Y % 40 > 20 then
            y = y + 40
        end
    
        return Vector(x, y)
    end
end

function REVEL.GetRoomCorners()
    return REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
end

function REVEL.GetRoomSize()
    local tl, br = REVEL.GetRoomCorners()
    return br.X - tl.X, br.Y - tl.Y
end
  
function REVEL.IsPositionInRectNums(pos, minX, minY, maxX, maxY)
    return pos.X > minX and pos.Y > minY and pos.X < maxX and pos.Y < maxY
end
  
function REVEL.IsPositionInRect(pos, rectTL, rectBR)
    if not rectTL or not rectBR then
        error("IsPositionInRect: rectTL or rectBR nil:" .. REVEL.ToStringMulti(rectTL, rectBR), 2)
    end
    return REVEL.IsPositionInRectNums(pos, rectTL.X, rectTL.Y, rectBR.X, rectBR.Y)
end
  
function REVEL.GetRoomRadialPosition(angle, margin)
    margin = margin or 0

    local c, tl, br = REVEL.room:GetCenterPos(), REVEL.GetRoomCorners()
    local w, h = br.X - tl.X - margin * 2, br.Y - tl.Y - margin * 2

    return c + REVEL.GetPointOnRectFromAngle(angle, w, h)
end

--Source: https://gist.github.com/GiriB/320a4c22ab3483d0ec6500edb957380e , edited
function REVEL.IsInPolygon(pos, ...)
    local isIn = false
    local poly = {...}
  
    if type(poly[1]) == "table" then
        poly = poly[1]
    end
  
    local p1x = poly[1].X
    local p1y = poly[1].Y
  
    for i=0, #poly do
        local p2x = poly[((i)%#poly)+1].X
        local p2y = poly[((i)%#poly)+1].Y
        
        if pos.Y > math.min(p1y, p2y) then
            if pos.Y <= math.max(p1y, p2y) then
                if pos.X <= math.max(p1x, p2x) then
                    local xinters
                    if p1y ~= p2y then
                        xinters = (pos.Y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    end
                    if p1x == p2x or pos.X <= xinters then
                        isIn = not isIn
                    end
                end
            end
        end
        p1x, p1y = p2x, p2y	
    end
  
    return isIn
end

---@param fromIndex integer
---@param checkEntities? boolean default: true
---@param checkGrids? boolean default: true
---@param entityTables? Entity[]|Entity[][] Specific entity tables to check against
---@param entityPartition? EntityPartition Entity partition to check with, not needed if using entityTables
---@param includeDecorations? boolean
---@return integer?
function REVEL.FindFreeIndex(fromIndex, checkEntities, checkGrids, entityTables, entityPartition, includeDecorations)

    REVEL.Assert(checkEntities and (entityTables or entityPartition), "FindFreeIndex | needs entityTables and/or entityPartition with checkEntities set", 2)

    if checkEntities == nil then 
        checkEntities = true 
        if not entityPartition and not entityTables then
            entityPartition = EntityPartition.ENEMY | EntityPartition.PICKUP
        end
    end
    if checkGrids == nil then checkGrids = true end

    local checked = {}
    local toCheck = {fromIndex}

    local gridDiagonalHalfLength = math.ceil(40 * math.sqrt(2) / 2)

    while #toCheck > 0 do
        local newToCheck = {}
        local added = {}
        for _, index in ipairs(toCheck) do
            checked[index] = true

            local isFree = true

            if checkGrids then
                local grid = REVEL.room:GetGridEntity(index)
                if grid and (includeDecorations or grid:GetType() ~= GridEntityType.GRID_DECORATION) then
                    isFree = false
                end
            end

            if isFree and checkEntities then
                local pos = REVEL.room:GetGridPosition(index)
                if entityPartition then
                    -- search entities in circle that includes grid index
                    local nearEntities = Isaac.FindInRadius(pos, gridDiagonalHalfLength, entityPartition)
                    for _, entity in ipairs(nearEntities) do
                        local index2 = REVEL.room:GetGridIndex(entity.Position)
                        if index2 == index then
                            isFree = false
                            break
                        end
                    end
                end
                if entityTables then
                    if entityTables[1] and entityTables[1].Type then
                        entityTables = {entityTables}
                    end
                    for _, entityTable in ipairs(entityTables) do
                        for _, entity in ipairs(entityTable) do
                            local index2 = REVEL.room:GetGridIndex(entity.Position)
                            if index2 == index then
                                isFree = false
                                break
                            end
                        end
                    end
                end
            end

            if isFree then
                return index
            else
                local w = REVEL.room:GetGridWidth()
                local adjacent = {
                    index - w - 1,
                    index - w,
                    index - w + 1,
                    index - 1,
                    index + 1,
                    index + w - 1,
                    index + w,
                    index + w + 1,
                }
                for _, adj in ipairs(adjacent) do
                    if not checked[adj]
                    and not added[adj]
                    and REVEL.room:IsPositionInRoom(REVEL.room:GetGridPosition(adj), 0)
                    then
                        newToCheck[#newToCheck+1] = adj
                        added[adj] = true
                    end
                end
            end
        end
        toCheck = newToCheck
    end
end

end

REVEL.PcallWorkaroundBreakFunction()