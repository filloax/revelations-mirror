return function()

local GigaBombVariants = {
    [BombVariant.BOMB_GIGA] = true,
    [BombVariant.BOMB_ROCKET_GIGA] = true,
}

function REVEL.IsGigaBomb(bomb)
    return GigaBombVariants[bomb.Variant]
end

---@param indexOrPos integer | Vector
---@return table
function REVEL.GetGigaBombTiles(indexOrPos)
    if type(indexOrPos) ~= "number" then
        indexOrPos = REVEL.room:GetGridIndex(indexOrPos)
    end

    local w = REVEL.room:GetGridWidth()

    return {
        indexOrPos - 2 * w,
        indexOrPos - w - 1,
        indexOrPos - w,
        indexOrPos - w + 1,
        indexOrPos - 2,
        indexOrPos - 1,
        indexOrPos,
        indexOrPos + 1,
        indexOrPos + 2,
        indexOrPos + w - 1,
        indexOrPos + w,
        indexOrPos + w + 1,
        indexOrPos + 2 * w,
    }
end

end