return function()
    
--code in mirror.lua
function REVEL.SpawnCustomShockwave(pos, vel, gfx, timeout, collision, spawnrate, minVarianceEachSpawn, maxVarianceEachSpawn, soundEachSpawn, onCollide, onUpdate, specialCollisionCheck)
    local lead = Isaac.Spawn(REVEL.ENT.CUSTOM_SHOCKWAVE.id, REVEL.ENT.CUSTOM_SHOCKWAVE.variant, 0, pos, vel, nil)
    spawnrate = spawnrate or math.floor(lead.Size / (vel:Length() / 2))
    collision = collision or EntityGridCollisionClass.GRIDCOLL_GROUND
    lead.Size = math.floor(lead.Size * 1.5)
    lead.GridCollisionClass = collision
    lead.Visible = false
    local ldata = lead:GetData()
    ldata.LeadShockwave = true
    ldata.Spawnrate = spawnrate
    ldata.Timeout = timeout
    ldata.Gfx = gfx
    ldata.MinVarianceEachSpawn = minVarianceEachSpawn
    ldata.MaxVarianceEachSpawn = maxVarianceEachSpawn
    ldata.SoundEachSpawn = soundEachSpawn
    ldata.OnCollide = onCollide
    ldata.OnUpdate = onUpdate
    ldata.SpecialCollisionCheck = specialCollisionCheck
    return lead
end

--for effects :CollidesWithGrid seemsto only work with walls used with effects
local function schockwaveCollides(eff)
    if eff:CollidesWithGrid() then return true end

    for i = 1, 2 do
        local pos
        if i == 1 then
            pos = eff.Position
        else
            pos = eff.Position + eff.Velocity
        end

        local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(pos))

        if grid and grid.Desc.Type == GridEntityType.GRID_PIT then
            return true
        end
    end

    return false
end

local function shockwavePostEffectUpdate(_, eff)
    local data = eff:GetData()
    if data.LeadShockwave then
        if data.OnUpdate then
            data.OnUpdate(eff)
        end

        if data.Timeout then
            data.Timeout = data.Timeout - 1
            if data.Timeout <= 0 then
                eff:Remove()
                return
            end
        end

        local collided
        if (data.SpecialCollisionCheck and data.SpecialCollisionCheck(eff)) or (not data.SpecialCollisionCheck and schockwaveCollides(eff)) then
            collided = true
            if data.OnCollide then
                local ret = data.OnCollide(eff)
                if ret == false or not eff:Exists() then
                    return
                end
            else
                eff:Remove()
                return
            end
        end

        if eff.FrameCount % data.Spawnrate == 0 and not collided then
            local shock = Isaac.Spawn(REVEL.ENT.CUSTOM_SHOCKWAVE.id, REVEL.ENT.CUSTOM_SHOCKWAVE.variant, 0, eff.Position, Vector.Zero, nil)
            shock:GetData().IgnoreRocks = data.IgnoreRocks
            if data.Gfx then
                local sprite = shock:GetSprite()
                sprite:ReplaceSpritesheet(0, data.Gfx)
                sprite:LoadGraphics()
            end

            if data.Color then
                local sprite = shock:GetSprite()
                sprite.Color = data.Color
                shock:GetData().Color = data.Color
            end

            if data.MinVarianceEachSpawn then
                local min, max = data.MinVarianceEachSpawn, data.MaxVarianceEachSpawn
                if not max then
                    max = min
                    min = -min
                end

                eff.Velocity = eff.Velocity:Rotated(math.random(min, max))
            end

            if data.SoundEachSpawn then
                REVEL.sfx:Play(data.SoundEachSpawn, 0.25, 0, false, 1)
            end
        end
    else
        local sprite = eff:GetSprite()
        for _, player in ipairs(REVEL.players) do
            if player.Position:Distance(eff.Position) < player.Size + eff.Size then
                player:TakeDamage(1, DamageFlag.DAMAGE_EXPLOSION, EntityRef(eff), 0)
            end
        end

        if sprite:IsFinished("Break") then
            eff:Remove()
        end

        if not data.IgnoreRocks then
            local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(eff.Position))
            if grid and grid:ToRock() then
                grid:Destroy(false)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, shockwavePostEffectUpdate, REVEL.ENT.CUSTOM_SHOCKWAVE.variant)

end