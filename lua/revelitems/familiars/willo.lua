local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- WILLO
--[[
Drifts from being slightly repelled by the player, but provides them with a stat bonus that increases the longer they stay in its aura, and resets when leaving it. Launches a strong homing tear at any enemy that hits Isaac.
]]

local Diag = { -- optimization
    Vector.FromAngle(45) * 4, 
    Vector.FromAngle(135) * 4,
    Vector.FromAngle(-45) * 4, 
    Vector.FromAngle(-135) * 4
}
local AuraColor = Color(1, 0.5, 1, 0.08, conv255ToFloat(90, 0, 100))
local r, g, b = hsvToRgb(0.95, 0.9, 0.6)
local LightColor = Color(r, g, b, 1, conv255ToFloat(150, 150, 150))
local Radius = 100

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag & CacheFlag.CACHE_FAMILIARS > 0 then
        local num = (REVEL.ITEM.WILLO:GetCollectibleNum(player)) 
            * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        local rng = REVEL.RNG()
        rng:SetSeed(math.random(635), 0)
        player:CheckFamiliar(REVEL.ENT.WILLO.variant, num, rng:GetRNG())
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, fam)
    fam.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    fam.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    fam:GetData().aura = REVEL.SpawnAura(
        Radius, 
        fam.Position, 
        AuraColor, 
        fam, 
        true
    )
    REVEL.SpawnLightAtEnt(fam, LightColor, 2.5, Vector(0, -15))
end, REVEL.ENT.WILLO.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    local willos = REVEL.ENT.WILLO:getInRoom()
    for _, fam in ipairs(willos) do
        local data = fam:GetData()
        data.aura = REVEL.SpawnAura(
            Radius, 
            fam.Position, 
            AuraColor, 
            fam,
            true
        )
        REVEL.SpawnLightAtEnt(fam, LightColor, 2.5, Vector(0, -15))
        fam.Position = REVEL.room:GetRandomPosition(40)
        fam.Velocity = Diag[math.random(1, 4)]
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    local willos = REVEL.ENT.WILLO:getInRoom()
    for _, fam in ipairs(willos) do
        fam.Position = REVEL.room:GetRandomPosition(40)
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, fam)
    local spr, data = fam:GetSprite(), fam:GetData()

    if REVEL.room:GetFrameCount() > 5 then
        for _, player in ipairs(REVEL.players) do
            local dist = player.Position:Distance(fam.Position)
            if dist <= Radius then
                REVEL.Warm(player, nil, true, true)
                for _,v in ipairs(REVEL.roomLasers) do
                    if v.SpawnerEntity.Index == player.Index then
                        v:SetHomingType(2)
                        v.Color = REVEL.HOMING_COLOR
                    end
                end
            end
            if not data.BControl then
                if dist <= 200 then
                    fam.Velocity = fam.Velocity + (fam.Position - player.Position) 
                        * (REVEL.Lerp2Clamp(0.1, 0, dist, 40, 200) / dist)
                else -- go back to closest 45° angle
                    local angle = fam.Velocity:GetAngleDegrees()
                    local rotateClockwise -- rotating clockwise reduces the angle
                    if angle > -180 and angle < -90 then
                        rotateClockwise = angle > -135
                    elseif angle >= -90 and angle < 0 then
                        rotateClockwise = angle > -45
                    elseif angle >= 0 and angle < 90 then
                        rotateClockwise = angle > 45
                    elseif angle >= 90 and angle < 180 then
                        rotateClockwise = angle > 135
                    end
                    fam.Velocity = fam.Velocity 
                        + Vector.FromAngle(angle + 90 
                            * (rotateClockwise and -1 or 1)) * 0.1
                end
            end
        end
    end

    if not data.BControl then
        -- FLY AROUND
        local vel = REVEL.CloneVec(fam.Velocity)
        if vel.X < 0 then vel.X = vel.X * -1 end
        if vel.Y < 0 then vel.Y = vel.Y * -1 end
        if vel.X + vel.Y <= 1 then 
            fam.Velocity = Diag[math.random(1, 4)]
        end

        if spr:IsPlaying("Attack") and spr:IsEventTriggered("Shoot") and
            data.LastTarget and data.LastTarget:Exists() then
            for i=1,5 do
                local tear = Isaac.Spawn(2, 0, 0, fam.Position, 
                (data.LastTarget.Position - fam.Position):Resized(8+4*math.random()):Rotated(math.random(-60,60)), fam):ToTear()
                tear.TearFlags = BitOr(tear.TearFlags, TearFlags.TEAR_HOMING, TearFlags.TEAR_SPECTRAL)
                tear.CollisionDamage = REVEL.Lerp(3.5, fam.Player.Damage, 0.5)
                tear.Color = REVEL.HOMING_COLOR
                tear.FallingSpeed = math.random(-16,-4)
                tear.Target = data.LastTarget
            end
        end
        if spr:IsFinished("Attack") then 
            spr:Play("Idle", true) 
        end

        -- unstuck check
        local index = REVEL.room:GetGridIndex(fam.Position)
        if data.LastGridIndex == index then
            data.FramesInSameTile = (data.FramesInSameTile or 0) + 1
            if data.FramesInSameTile >= 60 then
                fam.Velocity = REVEL.room:GetCenterPos() - fam.Position
                REVEL.DebugStringMinor("Willo: was stuck, trying to displace")
                data.FramesInSameTile = 0
            end
        else
            data.LastGridIndex = index
            data.FramesInSameTile = 0
        end

        fam.Velocity = fam.Velocity:Resized(3.5)
    else
        fam.Position = fam.Player.Position
        fam:GetSprite().Color = Color(1,1,1,0)
    end
end, REVEL.ENT.WILLO.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(player, dmg, flag, src)
    player = player:ToPlayer()
    if player and REVEL.ITEM.WILLO:PlayerHasCollectible(player) and src and
        src.Entity then
        local willos = REVEL.ENT.WILLO:getInRoom()
        for _, willo in ipairs(willos) do
            ---@type EntityFamiliar
            willo = willo:ToFamiliar()
            if not willo:GetSprite():IsPlaying("Attack") and
                GetPtrHash(willo.Player) == GetPtrHash(player) then
                willo:GetSprite():Play("Attack", true)
                willo:GetData().LastTarget = REVEL.GetEntFromRef(src)
            end
        end
    end
end, 1)

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 2, function(tear, data, sprite, player)
    if REVEL.OnePlayerHasCollectible(REVEL.ITEM.WILLO.id, true) and player then
        local willos = REVEL.ENT.WILLO:getInRoom()
        for _, fam in ipairs(willos) do
            local dist = player.Position:Distance(fam.Position)
            if dist <= Radius then
                tear:AddTearFlags(TearFlags.TEAR_HOMING)
                tear:GetSprite().Color = player.TearColor * REVEL.HOMING_COLOR
            end
        end
    end
end)

end
