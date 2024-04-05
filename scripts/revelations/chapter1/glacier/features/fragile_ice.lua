local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local ShrineTypes       = require("scripts.revelations.common.enums.ShrineTypes")

return function()

-- Spawning logic is in ice_pits.lua, for
-- better coordination 

local ReformingIcePits = {}

function REVEL.TriggerPitfall(player, position)
    local data = REVEL.GetData(player)

    REVEL.DebugStringMinor("Triggered pit fall")

    if not data.Pitfalling then
        data.Pitfalling = true
        player.Velocity = Vector.Zero
        player.Position = position or player.Position

        if data.TotalFrozen then
            data.TotalFrozenSprite:Play("Fall" .. REVEL.dirToString[data.TotalFreezeDir], true)
            data.TotalFrozenSprite.PlaybackSpeed = 2
            data.FrozenPitfalling = true
        else
            player:AnimatePitfallIn()
        end
    end
end

local function UpdateGrids()
    local gfx = StageAPI.GetCurrentRoom().Data.RoomGfx
    local grids = gfx.Grids
    StageAPI.ChangeGrids(grids)
end

local function ConvertFragileIceToPit(grid, grindex)
    grid:Destroy(true)
    
    local fragileIcePits = StageAPI.GetCustomGrids(grindex, REVEL.GRIDENT.FRAGILE_ICE.Name)
    for _,fragileIce in ipairs(fragileIcePits) do
        fragileIce:Remove(true)
    end
    
    Isaac.GridSpawn(GridEntityType.GRID_PIT, 0, REVEL.room:GetGridPosition(grindex), true)
    UpdateGrids()
end

local function ConvertPitToFragileIce(grindex, noRoomUpdate)
    REVEL.PreventGridBreakSound(grindex)
    REVEL.room:RemoveGridEntity(grindex, 0, true)
    if not noRoomUpdate then
        REVEL.room:Update()
    end
    REVEL.DelayFunction(2, function()
        -- right now Isaac.GridSpawn, used by StageAPI custom grids, 
        -- is bugged and won't remove grid entities before adding
        -- them even with force = true
        REVEL.GRIDENT.FRAGILE_ICE:Spawn(grindex, true, false, {RegeneratingInvuln = 10})
        UpdateGrids()
    end, nil, true)
end

function REVEL.RegenIcePit(grindex, noRoomUpdate)
    if REVEL.room:GetGridEntity(grindex) and REVEL.room:GetGridEntity(grindex):ToPit() then
        REVEL.SpawnDecoration(REVEL.room:GetGridPosition(grindex), Vector.Zero, {
            Sprite = REVEL.GRIDENT.FRAGILE_ICE.Anm2,
            Anim = "Reform",
            Start = function(effect, data, sprite)
                if REVEL.game.Difficulty == Difficulty.DIFFICULTY_HARD then
                    sprite:ReplaceSpritesheet(1, "gfx/ui/none.png")
                    sprite:LoadGraphics()
                end
            end,
            Update = function(effect, data, sprite)
                if sprite:IsEventTriggered("Reform") then
                    ConvertPitToFragileIce(grindex, noRoomUpdate)
                end
            end,
        })
    end
end

-- exported to main glacier.lua to manually set order
function REVEL.FragileiceRoomLoad(newRoom, revisited)
    if newRoom.PersistentData.FragileIce then
        local remove = {}
        for strindex, isRandom in pairs(newRoom.PersistentData.FragileIce) do
            local index = tonumber(strindex)
            if REVEL.room:IsFirstVisit() then
                if isRandom == 0 or REVEL.room:GetGridCollision(index) == GridCollisionClass.COLLISION_NONE then --avoid random-spawning on braziers and the like
                    REVEL.GRIDENT.FRAGILE_ICE:Spawn(index, true, false)
                else
                    remove[strindex] = true
                end
            else --check if it was still a pit when changing room
                local grid = REVEL.room:GetGridEntity(index)
                if grid and grid:ToPit() then
                    REVEL.RegenIcePit(index, true)
                end
            end
        end
        for strindex, _ in pairs(remove) do
            newRoom.PersistentData.FragileIce[strindex] = nil
        end
    end
end

local IcePitState = {
    INIT = 0,
    CRACKING = 1,
    CRACKED = 2,
    FLASHING = 3,
    BREAKING = 4,
    BROKEN = 5,
    PIT = 6,
}

---@param customGrid CustomGridEntity
local function fragileicePostSpawnCustomGrid(customGrid)
    local spawnIndex = customGrid.GridIndex
    local grid = customGrid.GridEntity
    local persistData = customGrid.PersistentData
    -- if persistData.Cracked or persistData.Broken or (persistData.State and persistData.State > 0) then
    --     ConvertFragileIceToPit(grid, spawnIndex)
    --     return
    -- end

    persistData.State = IcePitState.INIT
    persistData.Player = nil

    if not grid then
        -- Workaround: force it until the bug is figured out
        REVEL.DebugToString("Warning: Fragile ice | " .. spawnIndex .. " grid nil, grid is: '" .. REVEL.ToString(customGrid) 
            .. "', spawning another decoration grid entity")
        grid = Isaac.GridSpawn(GridEntityType.GRID_DECORATION, 0, REVEL.room:GetGridPosition(spawnIndex), false)
        -- error(spawnIndex .. " grid nil, grid is: '" .. REVEL.ToString(customGrid) .. "'" .. REVEL.game:GetFrameCount())
    end

    local sprite = grid:GetSprite()
    sprite:Play("Start", true)

    if REVEL.game.Difficulty == Difficulty.DIFFICULTY_HARD then
        sprite:ReplaceSpritesheet(1, "gfx/ui/none.png")
        sprite:LoadGraphics()
    end
end

local function fragileicePostCustomGridUpdate(customGrid)
    local grid = customGrid.GridEntity
    local grindex = customGrid.GridIndex
    local persistData = customGrid.PersistentData
    
    if persistData.Player and REVEL.room:GetGridIndex(persistData.Player.Position) ~= grindex then
        persistData.Player = nil
    end

    if persistData.RegeneratingInvuln then
        persistData.RegeneratingInvuln = persistData.RegeneratingInvuln - 1
        if persistData.RegeneratingInvuln < 0 then
            persistData.RegeneratingInvuln = nil
        end
        return
    end

    -- public apis
    if persistData.Broken and persistData.State < IcePitState.BREAKING then
        persistData.State = IcePitState.BREAKING
    elseif persistData.Cracked and persistData.State < IcePitState.CRACKING then
        persistData.State = IcePitState.CRACKING
    elseif persistData.Flashing and persistData.State < IcePitState.FLASHING then
        persistData.State = IcePitState.FLASHING
    end

    local sprite = grid:GetSprite()

    if persistData.State == IcePitState.CRACKING then
        persistData.Cracked = true
        REVEL.sfx:Play(SoundEffect.SOUND_BONE_SNAP, 0.9, 0, false, 0.98 + math.random() * 0.05)
        persistData.State = IcePitState.CRACKED
        sprite:Play("Crack", true)

        if REVEL.IsShrineEffectActive(ShrineTypes.FRAGILITY) then
            persistData.BreakCounter = 20
        end
    elseif persistData.State == IcePitState.CRACKED then
        if not persistData.Player then
            persistData.State = IcePitState.BREAKING
            persistData.BreakCounter = nil
        end

        if persistData.BreakCounter then
            persistData.BreakCounter = persistData.BreakCounter - 1
            if persistData.BreakCounter <= 0 then
                persistData.State = IcePitState.BREAKING
                persistData.BreakCounter = nil
            end
        end
    elseif persistData.State == IcePitState.BREAKING then
        REVEL.sfx:Play(REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 0.9 + math.random() * 0.05)

        sprite:Play("Shatter", true)

        persistData.Broken = true
        persistData.State = IcePitState.BROKEN
    elseif persistData.State == IcePitState.BROKEN then
        if sprite:IsEventTriggered("Pit") then
            persistData.State = IcePitState.PIT

            -- onetime check for players to fall in
            for _, player in ipairs(REVEL.players) do
                if not player.CanFly and player.Position:DistanceSquared(grid.Position) < 20 ^ 2 then
                    REVEL.TriggerPitfall(player,grid.Position)
                end
            end

            --complete animation since the grid gets replaced by a pit
            REVEL.SpawnDecoration(grid.Position, Vector.Zero, {
                Anim = "Shatter", 
                Sprite = sprite:GetFilename(), 
                RemoveOnAnimEnd = true, 
                SkipFrames = sprite:GetFrame(),
                Start = function(effect, data, sprite)
                    if REVEL.game.Difficulty == Difficulty.DIFFICULTY_HARD then
                        sprite:ReplaceSpritesheet(1, "gfx/ui/none.png")
                        sprite:LoadGraphics()
                    end
                end,
            })
            ConvertFragileIceToPit(grid, grindex)

            if REVEL.GlacierBalance.FragileIceReformTime > 0 or REVEL.GlacierBalance.FragileIceRoomClearReformTime > 0 then
                ReformingIcePits[#ReformingIcePits + 1] = {
                    Index = grindex,
                    Time = (REVEL.GlacierBalance.FragileIceReformTime > 0) and REVEL.GlacierBalance.FragileIceReformTime,
                }
            end
        end
    elseif persistData.State == IcePitState.FLASHING then
        if sprite:IsFinished("Flashing") then
            persistData.Flashing = false
            persistData.Broken = true
        elseif not sprite:IsPlaying("Flashing") then 
            REVEL.sfx:Play(SoundEffect.SOUND_BONE_SNAP, 0.9, 0, false, 0.98 + math.random() * 0.05)
            sprite:Play("Flashing", true) 
        end
    end
end

local function fragileicePostRoomClear()
    if REVEL.GlacierBalance.FragileIceRoomClearReformTime > 0 then
        REVEL.DelayFunction(REVEL.GlacierBalance.FragileIceRoomClearReformTime, function()
            for i, v in ipairs(ReformingIcePits) do
                REVEL.RegenIcePit(v.Index, true)
            end
            if #ReformingIcePits > 0 then
                REVEL.room:Update()
            end
            ReformingIcePits = {}
        end, nil, true)
    end
end

-- Init doesn't trigger for every room
local function fragileicePostNewRoom()
    if #ReformingIcePits > 0 then
        ReformingIcePits = {}
    end
end

local function fragileicePostUpdate()
    if REVEL.GlacierBalance.FragileIceReformTime > 0 then
        for i, v in ripairs(ReformingIcePits) do
            local continue = false

            local currentRoom = StageAPI.GetCurrentRoom()
            if currentRoom.PersistentData.SnowedTiles
            and currentRoom.PersistentData.SnowedTiles[tostring(v.Index)] then
                table.remove(ReformingIcePits, i)
                continue = true    
            end
            
            if not continue then
                v.Time = v.Time - 1
                if v.Time <= 0 then
                    REVEL.RegenIcePit(v.Index)
                    table.remove(ReformingIcePits, i)
                end
            end
        end
    end
end

local function fragileicePostPlayerUpdate(_, player)
    if player.CanFly then return end
    if not REVEL.STAGE.Glacier:IsStage() then return end

    local currentRoom = StageAPI.GetCurrentRoom()
    local onIce = REVEL.Glacier.RunIcePhysics(player, currentRoom)

    local data = REVEL.GetData(player)
    local index = REVEL.room:GetGridIndex(player.Position)

    local fragileIce = StageAPI.GetCustomGrid(index, REVEL.GRIDENT.FRAGILE_ICE.Name)

    if onIce and fragileIce then
        local iceState = fragileIce.PersistentData
        if iceState.Player and GetPtrHash(iceState.Player) ~= GetPtrHash(player) then
            iceState.Broken = true
            iceState.Player = nil
        elseif iceState.State == 0 then
            iceState.Cracked = true
            iceState.Player = player
        end
    end

    if not data.Pitfalling and not fragileIce and not REVEL.IsBigBlowyTrack(index) then
        data.LastIndexSafeFromPitfall = index
    end

    if data.Pitfalling then
        player.Velocity = Vector.Zero

        if data.FrozenPitfalling then
            if not data.TFPFellFrame and data.TotalFrozenSprite and data.TotalFrozenSprite:IsFinished("Fall" .. REVEL.dirToString[data.TotalFreezeDir]) then
                data.FrozenDamage = true
                player:TakeDamage(1, DamageFlag.DAMAGE_PITFALL, EntityRef(player), 15)
                data.FrozenDamage = nil
                player.Velocity = Vector.Zero
                data.TFPFellFrame = player.FrameCount
            end

            if data.TFPFellFrame and player.FrameCount - data.TFPFellFrame > 25
            and not (data.TFWaitFrameForResurface and player.FrameCount < data.TFWaitFrameForResurface) then
                REVEL.Glacier.TotalFrozenBreak(player, true)
                player:AnimatePitfallOut()
                data.FrozenPitfalling = nil
                data.TFPFellFrame = nil
            end
        else
            local sprite = player:GetSprite()

            -- REVEL.DebugLog(player, sprite, data.LastIndexSafeFromPitfall, sprite:IsPlaying("JumpOut"), sprite:GetFrame() >= 10 , data.PitfallingJumpedOut)

            -- A note on JumpOut: when pitfall is triggered above a pit, 
            -- it immediately skips over to frame 14 without playing the rest of the animation

            if sprite:GetAnimation() == "JumpOut" and sprite:GetFrame() >= 10 
            and not data.PitfallingJumpedOut then
                if data.LastIndexSafeFromPitfall then
                    local targPos = REVEL.room:GetGridPosition(data.LastIndexSafeFromPitfall)

                    if data.PitfallForceResurfacePosition then
                        targPos = data.PitfallForceResurfacePosition
                    end

                    -- player.Velocity = (targPos - player.Position) * 0.1
                    player.Position = targPos
                end
                data.PitfallForceResurfacePosition = nil
                data.PitfallingJumpedOut = true
            end

            if player:IsExtraAnimationFinished() then
                data.Pitfalling = nil
                data.PitfallingJumpedOut = nil
            end
        end
    end

end

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_CUSTOM_GRID, 1, fragileicePostSpawnCustomGrid, REVEL.GRIDENT.FRAGILE_ICE.Name)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 1, fragileicePostCustomGridUpdate, REVEL.GRIDENT.FRAGILE_ICE.Name)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 1, fragileicePostRoomClear)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, fragileicePostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, fragileicePostUpdate)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, fragileicePostPlayerUpdate)

end