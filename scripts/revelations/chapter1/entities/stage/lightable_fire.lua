local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

return function()

--Lightable fire
local TypeSuffix = {"", "2", "3"}

local EnableTimeAfterPlayerStep = 1
local FireBurstTime = 25
local FireEnableTime = 18 --frames
local BigScale = 1.5
local WaitForPlayer = false

local FireDuration = 300

local flashAlpha = 0

local flashedThisRoom = false
local flashedThisRoomAll = false

local BaseLayersFloor = {0, 3, 4}
local BaseLayersFlame  = {3}
local DisableLayersFloor = {1, 2, 5}
local DisableLayersFlame = {0, 3, 4}

StageAPI.AddEntityPersistenceData({
    Type = REVEL.ENT.LIGHTABLE_FIRE.id,
    Variant = REVEL.ENT.LIGHTABLE_FIRE.variant
})

local function initFire(fire)
    local sprite, data = fire:GetSprite(), REVEL.GetData(fire)

    fire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    fire:AddEntityFlags(EntityFlag.FLAG_DONT_OVERWRITE)
    fire:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
    fire:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    fire:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
    fire:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    fire:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

    data.Type = math.random(1, 3)
    data.TypeSuffix = TypeSuffix[data.Type]

    data.FloorEffect = StageAPI.SpawnFloorEffect(fire.Position, fire.Velocity, fire, sprite:GetFilename(), false)

    -- Remove fire if room was left with lightable fire on, which would make the blue fire respawn and be visible
    local closeEnts = Isaac.FindInRadius(fire.Position, 5, -1)
    for _, e in pairs(closeEnts) do
        if e.Type == 33 then
            e:Remove()
        end
    end

    local isFreezerBurn = StageAPI.GetCurrentRoomType() == RevRoomType.CHILL_FREEZER_BURN or REVEL.ENT.FREEZER_BURN:countInRoom() > 0

    if isFreezerBurn then
        sprite:Load("gfx/effects/revel1/lightable_fire_boss.anm2", false)
        data.FloorEffect:GetSprite():Load(sprite:GetFilename(), false)
    elseif REVEL.IsChillRoom() then
        for _, layer in pairs(BaseLayersFloor) do
            data.FloorEffect:GetSprite():ReplaceSpritesheet(layer, "gfx/effects/revel1/lightable_fire_base_chill.png")
        end
        for _, layer in pairs(BaseLayersFlame) do
            sprite:ReplaceSpritesheet(layer, "gfx/effects/revel1/lightable_fire_base_chill.png")
        end
    end

    for _, layer in pairs(DisableLayersFloor) do
        data.FloorEffect:GetSprite():ReplaceSpritesheet(layer, "gfx/ui/none.png")
    end
    for _, layer in pairs(DisableLayersFlame) do
        sprite:ReplaceSpritesheet(layer, "gfx/ui/none.png")
    end

    sprite:LoadGraphics()
    data.FloorEffect:GetSprite():LoadGraphics()

    if isFreezerBurn then
        local boss = REVEL.ENT.FREEZER_BURN:getInRoom()[1]
        data.FreezerBurn = boss
        if boss then
            if not REVEL.GetData(boss).IsChampion then
                REVEL.Glacier.ActivateLightableFire(fire, true)
            else
                local toplay = "Idle" .. data.TypeSuffix
                data.FloorEffect:GetSprite():Play(toplay, true)
                sprite:Play(toplay, true)
                data.Enabled = false
            end
        else
            local toplay = "Idle" .. data.TypeSuffix
            data.FloorEffect:GetSprite():Play(toplay, true)
            sprite:Play(toplay, true)
            data.Enabled = false
            data.FreezerBurnOff = true
        end

        fire.Friction = 0.01
        fire.Mass = 999999
        data.Position = fire.Position
    else
        local toplay = "Idle" .. data.TypeSuffix
        data.FloorEffect:GetSprite():Play(toplay, true)
        sprite:Play(toplay, true)

        -- Remove fire if room was left with lightable fire on, which would make the blue fire respawn and be visible
        local closeEnts = Isaac.FindInRadius(fire.Position, 5, -1)
        for _, e in pairs(closeEnts) do
            if e.Type == 33 then
                e:Remove()
            end
        end

        data.Enabled = false
    end

    data.Init = true
end

local function SpawnAusiliaryFire(owner)
    -- use fire to make enemies use proper pathfinding
    local auxFire = Isaac.Spawn(33, 2, 0, owner.Position, Vector.Zero, owner)
    auxFire.Visible = false
    REVEL.GetData(auxFire).LightableFireFire = owner
    -- fallback for visible, as it apparently doesn't work
    -- (likely mod interaction?)
    auxFire.Color = Color(0, 0, 0, 0)
    return auxFire
end

function REVEL.Glacier.ActivateLightableFire(fire, immediate, noanim, super, shutdownAfterSuper)
    local sprite, data = fire:GetSprite(), REVEL.GetData(fire)
    local floorSprite = data.FloorEffect:GetSprite()

    if not data.Init and not immediate then
        initFire(fire)
    end

    data.ShutdownAfterSuper = data.ShutdownAfterSuper or shutdownAfterSuper

    if not noanim then
        local toplay = immediate and ("Flickering" .. data.TypeSuffix) or ("Firestart" .. data.TypeSuffix)

        if super then
            toplay = "SuperFirestart" .. data.TypeSuffix
            data.SuperFireCooldown = super or data.SuperFireCooldown
        end

        sprite:Play(toplay, true)
        floorSprite:Play(toplay, true)
    end

    if immediate then
        data.Fire = SpawnAusiliaryFire(fire)
        data.Enabled = true

        if data.FreezerBurn then
            fire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end
    end
end

function REVEL.Glacier.ShutdownLightableFire(fire, immediate)
    local sprite, data = fire:GetSprite(), REVEL.GetData(fire)

    if not data.Init then
        initFire(fire)
    end

    local floorSprite
    if data.FloorEffect then --not there if called in new room (freezer burn)
        floorSprite = data.FloorEffect:GetSprite()
    end

    if data.Enabled then
        data.Enabled = false
        data.Fire:Remove()
        data.Fire = nil

        if immediate then
            sprite:Play("Idle" .. data.TypeSuffix, true)
            if floorSprite then floorSprite:Play("Idle" .. data.TypeSuffix, true) end
        else
            sprite:Play("Disappear" .. data.TypeSuffix, true)
            if floorSprite then floorSprite:Play("Disappear" .. data.TypeSuffix, true) end
        end

        fire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    end
end

function REVEL.Glacier.IsLightableFireOn(fire)
    return REVEL.GetData(fire).Enabled
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    local lightableFires = REVEL.ENT.LIGHTABLE_FIRE:getInRoom(false, false, false)
    flashAlpha = 0
    flashedThisRoom = false
    flashedThisRoomAll = false

    for _, fire in pairs(lightableFires) do if not REVEL.GetData(fire).Init then initFire(fire) end end
end)

REVEL.LightableFireBulletColor = Color(1, 1, 1, 1,conv255ToFloat( 255, 180, 0))

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.LIGHTABLE_FIRE:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if not data.Init then
        initFire(npc)
    end

    local floorSprite = data.FloorEffect:GetSprite()

    if data.Fire and data.Fire.Variant == 3 then --fire got autoreplaced to purple by base game
        data.Fire:Remove()
        data.Fire = SpawnAusiliaryFire(npc)
    end

    if not data.FreezerBurn and not data.FreezerBurnOff then
        local justEnabled = false
        if not data.EnableTimer and not data.Enabled and not IsAnimOn(sprite, "Firestart" .. data.TypeSuffix) then
            local foundPlayer = false

            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < (player.Size + 15) ^ 2 then
                    if WaitForPlayer then
                        data.EnableTimerOnPlayerLeave = true
                    else
                        data.EnableTimer = EnableTimeAfterPlayerStep
                    end
                    foundPlayer = true
                    break
                end
            end

            if not foundPlayer and data.EnableTimerOnPlayerLeave then
                data.EnableTimerOnPlayerLeave = nil
                data.EnableTimer = 5
            end

            if npc.FrameCount % 20 == 1 then
                Isaac.Spawn(1000, EffectVariant.EMBER_PARTICLE, 0, npc.Position + Vector((math.random() * 2 - 1) * 20, -6), Vector.FromAngle(-90 + math.random(-25, 25)) * 5, npc)
            end
        end

        if data.EnableTimer and not data.Enabled then
            if data.EnableTimer <= 0 then
                data.EnableTimer = nil
                data.Duration = FireDuration

                justEnabled = true
            else
                data.EnableTimer = data.EnableTimer - 1
            end
        end

        if data.IceCreepQueue and #data.IceCreepQueue > 0 then
            for i, pos in ripairs(data.IceCreepQueue) do
                REVEL.SpawnIceCreep(pos)
                data.IceCreepQueue[i] = nil
            end
        end

        if justEnabled then --flash animation
            sprite:Play("Firestart" .. data.TypeSuffix, true)
            floorSprite:Play("Firestart" .. data.TypeSuffix, true)
            data.FireStartTime = npc.FrameCount

            local doScreenFlash = not flashedThisRoom

            flashedThisRoom = true

            if not doScreenFlash and not flashedThisRoomAll then
                local lightableFires = REVEL.ENT.LIGHTABLE_FIRE:getInRoom(false, false, false)

                local allEnabled = true

                for _, fire in ipairs(lightableFires) do
                    if GetPtrHash(fire) ~= GetPtrHash(npc) and not REVEL.GetData(fire).Enabled then
                        allEnabled = false
                        break
                    end
                end

                if allEnabled then
                    flashedThisRoomAll = true
                    doScreenFlash = true
                end
            end

            data.DoScreenFlash = doScreenFlash
        end

        if sprite:IsPlaying("Flickering" .. data.TypeSuffix) then
            data.Duration = data.Duration - 1
            if data.Duration <= 0 then
                data.Duration = nil
                REVEL.Glacier.ShutdownLightableFire(npc)
            end
        end

        if data.DoScreenFlash then
            local time = npc.FrameCount - data.FireStartTime
            flashAlpha = REVEL.SmoothLerp2(0, 1, time, FireBurstTime - 5, FireBurstTime) *
                REVEL.SmoothLerp2(1, 0, time, FireBurstTime, FireBurstTime + 20)

            if time >= FireBurstTime + 20 then
                data.DoScreenFlash = nil
                data.FireStartTime = nil
            end
        end
    elseif data.FreezerBurn then
        npc.Velocity = data.Position - npc.Position

        if sprite:IsEventTriggered("Shoot") then
            local startAngle = (not data.LastWasAxisAligned) and 0 or 45
            data.LastWasAxisAligned = not data.LastWasAxisAligned

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 0.9)

            for i = 1, 4 do
                local f = REVEL.ShootFreezerBurnFire(npc, npc.Position, Vector.FromAngle(startAngle + i * 90) * 6, 0.75, nil, nil, nil, nil, true)
                f.Color = REVEL.LightableFireBulletColor
            end

            if data.FireSpawnMarkers then
                for i = 1, #data.FireSpawnMarkers do
                    data.FireSpawnMarkers[i]:Remove()
                end
                data.FireSpawnMarkers = nil
            end

            for i = 1, math.random(12, 16) do
                Isaac.Spawn(1000, EffectVariant.EMBER_PARTICLE, 0, npc.Position + Vector((math.random() * 2 - 1) * 20, -6), Vector.FromAngle(-90 + math.random(-25, 25)) * 5, npc)
            end
        end

        if REVEL.MultiFinishCheck(sprite, "SuperFirestart" .. data.TypeSuffix, "SuperFlickeringStart" .. data.TypeSuffix) then
            data.SuperFireTime = data.SuperFireCooldown
            sprite:Play("SuperFlickering" .. data.TypeSuffix, true)
            floorSprite:Play("SuperFlickering" .. data.TypeSuffix, true)
        elseif sprite:IsPlaying("SuperFlickeringShoot" .. data.TypeSuffix) then
            data.SuperFireTime = data.SuperFireTime - 1
        elseif sprite:IsFinished("SuperFlickeringShoot" .. data.TypeSuffix) then
            sprite:Play("SuperFlickering" .. data.TypeSuffix, true)
            floorSprite:Play("SuperFlickering" .. data.TypeSuffix, true)
        elseif IsAnimOn(sprite, "SuperFlickering" .. data.TypeSuffix) then

            sprite.PlaybackSpeed = 1.3
            data.SuperFireTime = data.SuperFireTime - 1

            if data.SuperFireTime % (data.SuperFireShootTime or 30) == 0 and data.SuperFireTime > 0 then
                sprite:Play("SuperFlickeringShoot" .. data.TypeSuffix, true)
                floorSprite:Play("SuperFlickeringShoot" .. data.TypeSuffix, true)

                local startAngle = (not data.LastWasAxisAligned) and 0 or 45
                --[[
                    data.FireSpawnMarkers = {}
                    for i = 1, 4 do
                        data.FireSpawnMarkers[i] = REVEL.SpawnDecoration(npc.Position + Vector.FromAngle(startAngle + i * 90) * 40, Vector.Zero, "Idle", "gfx/effects/revel1/freezer_burn_fire.anm2", nil, nil, nil, nil, nil, 0)
                        data.FireSpawnMarkers[i].Color = REVEL.LightableFireBulletColor
                        data.FireSpawnMarkers[i].SpriteScale = Vector.One * 0.75
                    end
                ]]
                for i = 1, 4 do
                    local pos = npc.Position + Vector.FromAngle(startAngle + i * 90) * 40
                    local eff = Isaac.Spawn(1000, EffectVariant.ULTRA_GREED_BLING, 0, pos, Vector.Zero, npc)
                    eff.Color = Color(1, 0.75, 0, 1,conv255ToFloat( 0, 0, 0))
                    eff.SpriteScale = Vector.One * 1.5
                    eff:GetSprite().PlaybackSpeed = 0.5
                end
            end

            if sprite:IsFinished("SuperFlickering" .. data.TypeSuffix) then
                if data.SuperFireTime <= 0 then
                    if data.ShutdownAfterSuper then
                        REVEL.Glacier.ShutdownLightableFire(npc)
                        data.ShutdownAfterSuper = nil
                    else
                        sprite:Play("SuperFlickeringEnd" .. data.TypeSuffix, true)
                        floorSprite:Play("SuperFlickeringEnd" .. data.TypeSuffix, true)
                    end
                    data.LastWasAxisAligned = nil
                    data.SuperFireTime = nil
                    if data.FireSpawnMarkers then
                        for i = 1, #data.FireSpawnMarkers do
                            data.FireSpawnMarkers[i]:Remove()
                        end
                        data.FireSpawnMarkers = nil
                    end
                else
                    sprite:Play("SuperFlickering" .. data.TypeSuffix, true)
                    floorSprite:Play("SuperFlickering" .. data.TypeSuffix, true)
                end
            end
        elseif sprite:IsFinished("SuperFlickeringEnd" .. data.TypeSuffix) then
            sprite.PlaybackSpeed = 1
            sprite:Play("Flickering" .. data.TypeSuffix, true)
            floorSprite:Play("Flickering" .. data.TypeSuffix, true)
        end
    end

    --Freezerburn and normal room common AI
    if REVEL.MultiPlayingCheck(sprite, "Firestart" .. data.TypeSuffix, "SuperFirestart" .. data.TypeSuffix) then
        if sprite:WasEventTriggered("HeatStart") and not sprite:WasEventTriggered("FireSpawn") then
            REVEL.SpawnFireParticles(npc, -2, 20)
        end

        if sprite:IsEventTriggered("FireSpawn") then
            REVEL.sfx:Play(REVEL.SFX.FLAME_BURST, 0.9, 0, false, 1)
            REVEL.Glacier.ActivateLightableFire(npc, true, true)
        end

        --Big flame, melt all ice blocks, activate fire
        if sprite:IsEventTriggered("MaxFire") then
            for i = 0, REVEL.room:GetGridSize() do
                local grid = REVEL.room:GetGridEntity(i)
                if grid and grid.Desc.Type == GridEntityType.GRID_ROCK_ALT and REVEL.CanGridBeDestroyed(grid) then
                    REVEL.PreventGridBreakSound(i)
                    REVEL.PreventGridItemDrop(i)
                    REVEL.PreventGridNegativeEffects(i)
                    REVEL.room:DestroyGrid(i, true)
                    REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(i))

                    data.IceCreepQueue = data.IceCreepQueue or {}
                    table.insert(data.IceCreepQueue, REVEL.room:GetGridPosition(i)) --for some reason immediately spawning it doesn't work
                end
                if grid and StageAPI.IsCustomGrid(i, REVEL.GRIDENT.TOUGH_ICE.Name) then
                    grid:GetSprite().Color = Color(2,2,2,1,0.5,0.5,0.5)
                end
            end            
        end

    elseif sprite:IsFinished("Firestart" .. data.TypeSuffix) then
        sprite:Play("Flickering" .. data.TypeSuffix, true)
        floorSprite:Play("Flickering" .. data.TypeSuffix, true)
    elseif sprite:IsFinished("Disappear" .. data.TypeSuffix, true) then
        sprite:Play("Idle" .. data.TypeSuffix, true)
        floorSprite:Play("Idle" .. data.TypeSuffix, true)
    end

    -- data.FireSprite:Update()
end, REVEL.ENT.LIGHTABLE_FIRE.id)

-- revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
--   if not REVEL.ENT.LIGHTABLE_FIRE:isEnt(npc) then return end

--   local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

--   if data.EnableAnimation or data.Enabled or data.DisableAnimation then
--       data.FireSprite.Scale = Vector.One * data.FireScale
--       data.FireSprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
--   end
-- end, REVEL.ENT.LIGHTABLE_FIRE.id)

local FlashShader = REVEL.CCShader("Lightable Fires Flash")
FlashShader:SetRGB(1.5, 1.3, 1)
FlashShader:SetLightness(0.3)

function FlashShader:OnUpdate()
    self.Active = flashAlpha
end

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent)
    if REVEL.GetData(ent).LightableFireFire then
        return false
    end
end, EntityType.ENTITY_FIREPLACE)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent)
    if REVEL.ENT.LIGHTABLE_FIRE:isEnt(ent) then
        return false
    end
end, REVEL.ENT.LIGHTABLE_FIRE.id)

--Tough Ice

StageAPI.AddCallback("StageAPI", StageAPICallbacks.POST_CUSTOM_GRID_UPDATE, 1, function(customGrid)
    local spawnIndex = customGrid.GridIndex
    local lightableFires = REVEL.ENT.LIGHTABLE_FIRE:getInRoom(false, false, false)

    local allEnabled = #lightableFires > 0 and REVEL.every(lightableFires, function(fire)
        return REVEL.GetData(fire).Enabled
    end)

    local grid = REVEL.room:GetGridEntity(spawnIndex)
    if grid and grid:GetSprite().Color.R > 1.1 then
        grid:GetSprite().Color = Color.Lerp(Color(0.9,0.9,0.9),grid:GetSprite().Color, 0.9)
    end

    if allEnabled then
        REVEL.room:RemoveGridEntity(spawnIndex, 0, false)
        -- REVEL.UpdateRoomASAP()
        REVEL.SpawnMeltEffect(REVEL.room:GetGridPosition(spawnIndex))
    end
end, REVEL.GRIDENT.TOUGH_ICE.Name)

end