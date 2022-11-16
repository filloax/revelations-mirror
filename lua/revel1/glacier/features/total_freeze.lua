local PitState = require("lua.revelcommon.enums.PitState")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
--Total frozen player mechanic

local PlayerTypeSprites = {
    [PlayerType.PLAYER_THEFORGOTTEN]   = "gfx/effects/revel1/player_frozenfull_forgotten.png",
    [PlayerType.PLAYER_THEFORGOTTEN_B] = "gfx/effects/revel1/player_frozenfull_forgotten.png",
    [PlayerType.PLAYER_APOLLYON]   = "gfx/effects/revel1/player_frozenfull_apollyon.png",
    [PlayerType.PLAYER_APOLLYON_B] = "gfx/effects/revel1/player_frozenfull_apollyon.png",
    [PlayerType.PLAYER_BLUEBABY]   = "gfx/effects/revel1/player_frozenfull_bluebaby.png",
    [PlayerType.PLAYER_BLUEBABY_B] = "gfx/effects/revel1/player_frozenfull_bluebaby.png",
    [PlayerType.PLAYER_KEEPER]   = "gfx/effects/revel1/player_frozenfull_keeper.png",
    [PlayerType.PLAYER_KEEPER_B] = "gfx/effects/revel1/player_frozenfull_keeper.png",
    [PlayerType.PLAYER_BLACKJUDAS] = "gfx/effects/revel1/player_frozenfull_shadow.png",
    Default = "gfx/effects/revel1/player_frozenfull.png",
}

function REVEL.Glacier.CanBeTotalFrozen(player)
    return player:GetPlayerType() ~= PlayerType.PLAYER_THESOUL
end

function REVEL.Glacier.TotalFreezePlayer(player, direction, speed, forceGrid, requireIcePit, noPitfall, pitFallWater)
    local data = player:GetData()

    if requireIcePit == nil then requireIcePit = true end

    if not data.Pitfalling then
        local enumDirection

        if type(direction) == "number" then
            enumDirection = direction
            direction = REVEL.dirToVel[direction]
        else
            enumDirection = REVEL.GetDirectionFromVelocity(direction)
        end

        data.TotalFreezeDir = enumDirection

        if not REVEL.Glacier.CanBeTotalFrozen(player) then
            -- REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, true)

            -- player = REVEL.players[REVEL.GetPlayerID(player)]
            -- data = player:GetData()
            return
        end

        if data.NoFreezeGrid then return end

        if player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
            data.Bone.Visible = false
        end

        if not data.TotalFrozen then
            data.TotalFrozen = true
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_FREEZE, 0.7, 0, false, 0.95)
            REVEL.SpawnMeltEffect(player.Position, false, true)

            if not data.TotalFrozenSprite then
                data.TotalFrozenSprite = Sprite()
                data.TotalFrozenSprite:Load("gfx/effects/revel1/player_frozenfull.anm2", false)
                local ptype = player:GetPlayerType()
                if PlayerTypeSprites[ptype] then
                    data.TotalFrozenSprite:ReplaceSpritesheet(0, PlayerTypeSprites[ptype])
                else
                    data.TotalFrozenSprite:ReplaceSpritesheet(0, PlayerTypeSprites.Default)
                end
                data.TotalFrozenSprite:LoadGraphics()
            end

            data.TFPrevState = {
                Color = REVEL.CloneColor(player.Color),
                EntityCollisionClass = player.EntityCollisionClass,
                GridCollisionClass = player.GridCollisionClass,
                CanFly = player.CanFly
            }

            player.Color = REVEL.NO_COLOR
            REVEL.LockPlayerControls(player, "TotalFreeze")
            player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
            player.CanFly = false

            data.TotalFrozenSprite:Play(REVEL.dirToString[enumDirection], true)
        end

        if forceGrid then
            local gridPos = REVEL.room:GetGridPosition(forceGrid)

            if enumDirection == Direction.LEFT or enumDirection == Direction.RIGHT then
                player.Position = Vector(player.Position.X + player.Size * (enumDirection == Direction.RIGHT and 1 or -1), gridPos.Y)
            else
                player.Position = Vector(gridPos.X, player.Position.Y + player.Size * (enumDirection == Direction.DOWN and 1 or -1))
            end
        end

        if data.RequireIcePit == nil then
            data.RequireIcePit = requireIcePit
        else
            data.RequireIcePit = data.RequireIcePit and requireIcePit
        end

        data.FrozenVelocity = direction * speed
        player.Velocity = data.FrozenVelocity

        data.FrozenPitFallOn = not noPitfall

        data.FrozenPitFallWater = pitFallWater

        -- if not data.TFPrevCollision then
        --     data.TFPrevCollision = player.EntityCollisionClass
        --     player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        -- end
    end
end

--Can't use collision class if we want pickups to work
REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, collider)
    if collider.Type == 1 and npc.Type ~= REVEL.ENT.ICE_HAZARD_GAPER.id and collider:GetData().TotalFrozen then
        return true
    end
end)

REVEL.AddBrokenCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(_, player, collider)
    if not (collider.Type == 5 or collider.Type == REVEL.ENT.ICE_HAZARD_GAPER.id) and player:GetData().TotalFrozen then
        return true
    end
end)

function REVEL.Glacier.TotalFrozenBreak(player, noFx, skipIFrames)
    local data = player:GetData()

    if data.TotalFrozen then
        for key, val in pairs(data.TFPrevState) do
            player[key] = val
        end
        data.TFPrevState = nil
        REVEL.UnlockPlayerControls(player, "TotalFreeze")

        player.FireDelay = 0

        data.Frozen = false
        data.ForceFrozenTime = nil
        data.GlacierChill = 0

        data.AfterTotalFrozenTimer = not skipIFrames and 30 or nil

        if data.Bone then
            data.Bone.Visible = true
        end

        data.NoFreezeGrid = REVEL.room:GetGridIndex(player.Position)

        data.TotalFrozen = nil
        data.FrozenVelocity = nil

        local l = player.Velocity:Length()
        if l > 0.3 then
            player.Velocity = player.Velocity * (0.3/l)
        end

        if not noFx then
            REVEL.SpawnMeltEffect(player.Position, false, true)
            for i = 1, 8 do
                REVEL.SpawnIceRockGib(player.Position - Vector(0, math.random(20)), RandomVector() * math.random(1, 5), player)
            end
            REVEL.sfx:Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
        end
    end
end

---@param gridIndex integer
---@param requireIce boolean
---@param player? EntityPlayer
---@return boolean breaks
---@return boolean isPit
function REVEL.Glacier.GridBreaksTotalFreeze(gridIndex, requireIce, player)
    local grid = REVEL.room:GetGridEntity(gridIndex)

    local isIce = REVEL.Glacier.IsIceIndex(gridIndex)

    if grid then
        local isPit = grid.Desc.Type == GridEntityType.GRID_PIT and grid.State ~= PitState.PIT_BRIDGE
        local isBroke = REVEL.IsGridBroken(grid)
        --local isPassableLock = grid.Desc.Type == GridEntityType.GRID_LOCK and ((player and player:GetNumKeys() > 0) or IsAnimOn(grid:GetSprite(), "Breaking"))
        local isPassableLock = false

        -- if grid.Desc.Type == GridEntityType.GRID_LOCK then
        --     REVEL.DebugToConsole("A", grid.State, player and player:GetNumKeys() > 0, IsAnimOn(grid:GetSprite(), "Breaking"))
        -- end

        local breaks = isPit or not (isBroke or grid.CollisionClass == GridCollisionClass.COLLISION_NONE or isPassableLock)

        return breaks or (not isIce and requireIce), isPit
    end

    return requireIce and not isIce, false
end

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()

    if data.NoFreezeGrid and REVEL.room:GetGridIndex(player.Position) ~= data.NoFreezeGrid then
        data.NoFreezeGrid = nil
    end

    if data.TotalFrozen then
        if not data.Pitfalling then
            local gridIndex = REVEL.room:GetGridIndex(player.Position)
            local nextGridIndex = REVEL.room:GetGridIndex(player.Position + data.FrozenVelocity:Resized(player.Size * 1.1))

            local _,            isPit     = REVEL.Glacier.GridBreaksTotalFreeze(gridIndex, data.RequireIcePit, player)
            local breaksFreeze, nextIsPit = REVEL.Glacier.GridBreaksTotalFreeze(nextGridIndex, data.RequireIcePit, player)

            local takeDamage

            local stalagSpikes = REVEL.ENT.STALAGMITE_SPIKE:getInRoom()

            for _, spike in pairs(stalagSpikes) do
                if spike.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and spike.Position:DistanceSquared(player.Position) < (spike.Size + player.Size)^2 then
                    breaksFreeze = true
                    takeDamage = spike
                    spike:GetSprite():Play("Explode" .. spike:GetData().randomnum, false)
                    spike:GetData().DontShootThisTime = true
                end
            end

            player.Velocity = data.FrozenVelocity

            if not data.NoBreakThisFrame then
                if isPit and data.FrozenPitFallOn then
                    if REVEL.IsMidGridInDirection(gridIndex, player.Position, player.Velocity,
                                                    math.abs(player.Velocity.Y) > 0.1, 10) then
                        REVEL.TriggerPitfall(player)

                        if data.FrozenPitFallWater then
                            REVEL.sfx:Play(REVEL.SFX.WATER_SPLASH, 1, 0, false, 1)

                            local e = Isaac.Spawn(1000, EffectVariant.WATER_SPLASH, 0, player.Position, Vector.Zero, player):ToEffect()

                            local r = math.random(12, 25)

                            for i = 1, r do
                                local v = RandomVector()
                                local e = Isaac.Spawn(1000, EffectVariant.WATER_SPLASH, 1, player.Position + v * math.random(10, 40), v * math.random(3, 8), player)
                            end
                        end
                    end
                elseif breaksFreeze and (not data.FrozenPitFallOn or not nextIsPit) then
                    REVEL.Glacier.TotalFrozenBreak(player)
                    if takeDamage then
                        data.FrozenDamage = true
                        player:TakeDamage(1, 0, EntityRef(takeDamage), 15)
                        data.FrozenDamage = nil
                    end
                end
            else
                data.NoBreakThisFrame = nil
            end
        end

        if data.TotalFrozen then
            player.Color = REVEL.NO_COLOR
            data.TotalFrozenSprite:Update()
        end
    elseif data.AfterTotalFrozenTimer then
        data.AfterTotalFrozenTimer = data.AfterTotalFrozenTimer - 1
        if data.AfterTotalFrozenTimer <= 0 then
            data.AfterTotalFrozenTimer = nil
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, renderOffset)
    local data = player:GetData()

    if data.TotalFrozen then
        data.TotalFrozenSprite:Render(Isaac.WorldToScreen(player.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player, dmg)
    local data = player:GetData()

    if (data.TotalFrozen or data.AfterTotalFrozenTimer) and not data.FrozenDamage then
        return false
    end
end, 1)

end