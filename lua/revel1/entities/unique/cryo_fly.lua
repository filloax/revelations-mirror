REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--Cryo Fly
local radius = 90
local icePlusDistance = 1

--Needs LoadIcePits() called after to work
local function IceGrid(room, index, grid, changedFrames)
    changedFrames = changedFrames or {} --gets changed as a side-effect if not created now

    local pos = REVEL.room:GetGridPosition(index)

    if (not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION or grid.Desc.Type == GridEntityType.GRID_PIT) and StageAPI.GetCurrentRoom() and StageAPI.GetCurrentRoom().PersistentData.IcePitFrames then
        local width = REVEL.room:GetGridWidth()
        local height = REVEL.room:GetGridHeight()
        local newPitFrames = {}
        for strindex, frame in pairs(room.PersistentData.IcePitFrames) do
            newPitFrames[tonumber(strindex)] = frame
        end
        newPitFrames[index] = true
        room.PersistentData.IcePitFrames = StageAPI.GetPitFramesFromIndices(newPitFrames, width, height, true)

        local r = math.random(0, 2)
        for i = 1, r do
            local pos2 = REVEL.room:GetGridPosition(index) + RandomVector() * math.random(15, 30)
            local steam = REVEL.SpawnDecoration(pos2, REVEL.VEC_UP * 4 + REVEL.VEC_RIGHT * (math.random() * 2 - 1),
                "Steam" .. math.random(1,3), "gfx/effects/revelcommon/steam.anm2", nil, 30)
            steam:GetSprite():ReplaceSpritesheet(0, "gfx/effects/revel1/blue_steam.png")
            steam:GetSprite():ReplaceSpritesheet(1, "gfx/effects/revel1/blue_steam.png")
            steam:GetSprite():LoadGraphics()
        end

        --indices that were changed
        local adjIndices = {index - width - 1, index - width, index - width + 1,
                        index - 1, index, index + 1,
                        index + width - 1, index + width, index + width + 1}
        for _, index in pairs(adjIndices) do
            changedFrames[index] = room.PersistentData.IcePitFrames[tostring(index)]
        end

        local genEffects = Isaac.FindByType(StageAPI.E.GenericEffect.T, StageAPI.E.GenericEffect.V, -1, false, false)
        for _, effect in pairs(genEffects) do
            if effect:GetData().IcePit and REVEL.includes(adjIndices, REVEL.room:GetGridIndex(effect.Position)) then
                effect:Remove()
            end
        end

        if grid and grid.Desc.Type == GridEntityType.GRID_PIT then
            -- grid:Destroy(true)
            REVEL.room:RemoveGridEntity(index, 0, false)
            REVEL.UpdateRoomASAP()
        end
    end
end

local function ReloadIcePits(room, changedFrames)
    local gfx = room.Data.RoomGfx
    local grids = gfx.Grids
    -- StageAPI.ChangeGrids(grids)

    REVEL.DelayFunction(1, StageAPI.ChangeGrids, {grids})

    REVEL.LoadIcePits(changedFrames)
end

-- NPC data is wonky in death post NPC render, so
-- handle it separately
---@type table<integer, table>
local DeathData = {}

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.CRYO_FLY:isEnt(npc) or not REVEL.IsRenderPassNormal() then return end

    local sprite = npc:GetSprite()
    local deathData = DeathData[GetPtrHash(npc)]
    if not deathData then
        deathData = {}
        DeathData[GetPtrHash(npc)] = deathData
    end

    if not deathData.Dying and npc:HasMortalDamage() then
        npc.SplatColor = REVEL.NO_COLOR
        npc.HitPoints = 0
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        sprite:Play("Death", true)
        npc:RemoveStatusEffects()
        REVEL.sfx:Play(SoundEffect.SOUND_SKIN_PULL, 0.9, 0, false, 1)
        deathData.Dying = true
        npc.State = NpcState.STATE_UNIQUE_DEATH
    end

    if deathData.Dying and not IsAnimOn(sprite, "Death") then
        if not deathData.Retried then
            sprite:Play("Death", true)
            deathData.Retried = true
        end
    end

    if sprite:IsPlaying("Death") then
        npc.Velocity = Vector.Zero

        if not deathData.Exploded and sprite:IsEventTriggered("Explode") then
            deathData.Exploded = true

            -- freeze shit
            -- local boom = REVEL.SpawnDecoration(npc.Position, Vector.Zero, "Boom", "gfx/effects/revel1/frost_explosion.anm2")
            -- boom.SpriteScale = Vector.One * 1.3
            -- boom.Color = Color(0.7, 0.9, 1, 1,conv255ToFloat( 0, 40, 50))
            -- boom.SpriteOffset = Vector(0, -15)
            REVEL.sfx:Play(REVEL.SFX.LOW_FREEZE, 1, 0, false, 1)
            REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 1, 0, false, 1)

            local closeEnemies = Isaac.FindInRadius(npc.Position, radius, EntityPartition.ENEMY)
            for _, enemy in ipairs(closeEnemies) do
                REVEL.MorphToIceHazard(enemy, 5)
            end
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < radius^2 then
                    REVEL.ChillFreezePlayer(player, true, REVEL.GlacierBalance.DarkIceInChill)
                end
            end

            local room = StageAPI.GetCurrentRoom()

            if room and not npc:GetData().AllIce then
                local changedFrames = {}

                --Add ice tile to current grid, plus + shape around it
                for i = 0, icePlusDistance do
                    for dir = 0, (i == 0 and 0 or 3) do
                        local index = REVEL.room:GetGridIndex(npc.Position + REVEL.dirToVel[dir] * (40 * i))
                        local grid = REVEL.room:GetGridEntity(index)

                        IceGrid(room, index, grid, changedFrames)
                    end
                end

                ReloadIcePits(room, changedFrames)
            end

    
            -- Spawn effect so that npc already counts as dead, and shadow doesn't show
            local effect = REVEL.ENT.DECORATION:spawn(npc.Position, Vector.Zero, nil)
            local esprite = effect:GetSprite()
            esprite:Load(sprite:GetFilename(), true)
            esprite:Play(sprite:GetAnimation(), true)
            esprite:SetFrame(sprite:GetFrame())
    
            --REVEL.TriggerChumBucket(npc)
            npc:Remove()
            return
        end
        return true
    end
end, REVEL.ENT.CRYO_FLY.id)

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    DeathData = {}
end)

end