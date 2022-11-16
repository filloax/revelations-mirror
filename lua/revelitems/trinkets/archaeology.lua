local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-----------------
-- Archaeology --
-----------------

--2x chance of finding special stuff from rocks/pots/mushrooms/etc
--.drop's indexes are the stage ids (for Stage I)
--Since there is no way of editing drop chances for them, and changing luck would affect other stuff, I'll "just" have a fixed chance (cannot use exactly 2x as I dunno the vanilla one) to spawn the thing they'd spawn normally on rock break, on top of the vanilla mechanic

revel.arch = {
    drop = { --{weight, min, max, func}
        [LevelStage.STAGE1_1] = {
             --coins
            {
                Weight = 13, 
                Amount = {Min = 1, Max = 3},
                Drop = function(grid)
                    Isaac.Spawn(
                        5, 20, 1, 
                        grid.Position + RandomVector() * 3, RandomVector() * 3, nil
                    )
                end
            },
            --quarter
            {
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 100, CollectibleType.COLLECTIBLE_QUARTER, 
                        grid.Position, Vector.Zero, nil
                    )
                end
            },
            --swallowed
            {
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 350, TrinketType.TRINKET_SWALLOWED_PENNY, 
                        grid.Position, Vector.Zero, nil
                    ) 
                end
            }
        },

        [LevelStage.STAGE2_1] = {
            --pills
            {
                Weight = 15,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 70, 0, 
                        grid.Position + RandomVector() * 3, RandomVector() * 3, nil
                    ) 
                end 
            }, 
            --liberty cap
            { 
                Weight = 2,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 350, TrinketType.TRINKET_LIBERTY_CAP, 
                        grid.Position, Vector.Zero, nil
                    ) 
                end 
            },
             --magic mush
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM) then
                        Isaac.Spawn(
                            5, 100, CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end 
            },
            --mini mush
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_MINI_MUSH) then
                        Isaac.Spawn(
                            5, 100, CollectibleType.COLLECTIBLE_MINI_MUSH, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end
            }
        },

        [LevelStage.STAGE3_1] = {
            --tarot card/rune
            {
                Weight = 10,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 300, 0, 
                        grid.Position, Vector.Zero, nil
                    ) 
                end 
            }, 
            --black hearts
            {
                Weight = 6,
                Amount = {Min = 1, Max = 2},
                Drop = function(grid) 
                    Isaac.Spawn(
                        5, 10, 6, 
                        grid.Position + RandomVector() * 3, RandomVector() * 3, nil
                    ) 
                end 
            }, 
            --dry baby
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_DRY_BABY) then
                        Isaac.Spawn(
                            5, 100, CollectibleType.COLLECTIBLE_DRY_BABY, 
                            grid.Position, Vector.Zero, nil
                        )   
                    end
                end 
            }, 
            --ghost baby
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_GHOST_BABY) then
                        Isaac.Spawn(
                            5, 100, CollectibleType.COLLECTIBLE_GHOST_BABY, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end 
            } 
        },

        [LevelStage.STAGE4_1] = {
            --heart
            { 
                Weight = 10,
                Amount = {Min = 1, Max = 2},
                Drop = function(grid) 
                    Isaac.Spawn(
                        3, 10, 1, 
                        grid.Position + RandomVector() * 3, RandomVector() * 3, nil
                    ) 
                end 
            }, 
             --blood clot
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) then
                        Isaac.Spawn(
                            3, 100, CollectibleType.COLLECTIBLE_BLOOD_CLOT, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end 
            },
            --placenta
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_PLACENTA) then
                        Isaac.Spawn(
                            3, 100, CollectibleType.COLLECTIBLE_PLACENTA, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end 
            }, 
            --harl baby
            { 
                Weight = 1,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    if not REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_HARLEQUIN_BABY) then
                        Isaac.Spawn(
                            3, 100, CollectibleType.COLLECTIBLE_HARLEQUIN_BABY, 
                            grid.Position, Vector.Zero, nil
                        )
                    end
                end 
            }, 
            --umb. cord
            { 
                Weight = 2,
                Amount = {Min = 1, Max = 1},
                Drop = function(grid) 
                    Isaac.Spawn(
                        3, 350, TrinketType.TRINKET_UMBILICAL_CORD, 
                        grid.Position, Vector.Zero, nil
                    ) 
                end 
            },
        }
    }
}

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROCK_BREAK, 1, function(grid)
    --  REVEL.DebugToString({getmetatable(grid:GetType()), grid:GetGridIndex()})
    local stage = REVEL.level:GetAbsoluteStage()
    local hasArch
    for _, player in ipairs(REVEL.players) do
        if player:HasTrinket(REVEL.ITEM.ARCHAEOLOGY.id) then
            hasArch = true
            break
        end
    end

    if hasArch and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT and math.random() < 0.3 then
        local drop
        if revel.arch.drop[stage] then
            drop = StageAPI.WeightedRNG(revel.arch.drop[stage], nil, "Weight")
        elseif revel.arch.drop[stage - 1] then
            drop = StageAPI.WeightedRNG(revel.arch.drop[stage - 1], nil, "Weight")
        else
            return --couldn't find drop for this stage
        end

        local amount = REVEL.GetFromMinMax(drop.Amount)

        for i = 1, amount do
            drop.Drop(grid)
        end
    end
end)

end
