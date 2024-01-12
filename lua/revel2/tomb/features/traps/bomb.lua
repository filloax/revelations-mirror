return function()

REVEL.TrapTypes.BombTrap = {
    OnTrigger = function(tile, data)
        for i = 0, REVEL.room:GetGridSize() do
            local grid = REVEL.room:GetGridEntity(i)
            if grid and grid.Desc.Type == GridEntityType.GRID_TNT and not REVEL.IsGridBroken(grid) then
                grid:Hurt(999)
            end
        end

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            for _, metaEntity in ipairs(currentRoom.Metadata:Search{Name = "BombTrapBomb"}) do
                local index = metaEntity.Index

                local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, BombVariant.BOMB_TROLL, 0, REVEL.room:GetGridPosition(index), Vector.Zero, nil):ToBomb()
                if data.TrapIsPositiveEffect then
                    bomb.ExplosionDamage = 0
                end
            end
        end
    end,
    SingleUse = true,
    Animation = "Bomb"
}

end