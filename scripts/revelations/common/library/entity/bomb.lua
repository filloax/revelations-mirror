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

REVEL.BombsGFX = {}

function REVEL.SetBombGFX(bomb)
    local player = REVEL.GetData(bomb).__player
    if not REVEL.BombsGFX[bomb.InitSeed] then -- bomb is new
        REVEL.BombsGFX[bomb.InitSeed] = {}
        local sprite = bomb:GetSprite()

        if bomb.Variant == BombVariant.BOMB_NORMAL and
        not bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
            if REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(player) then
                if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
                    sprite:ReplaceSpritesheet(0, "gfx/itemeffects/revelcommon/bombs/spritesheets/repentance/mirror_bombs_gold.png")
                else
                    sprite:ReplaceSpritesheet(0, "gfx/itemeffects/revelcommon/bombs/spritesheets/repentance/mirror_bombs.png")
                end
            end
        end

        sprite:LoadGraphics()
    end
end


end