REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-----------
-- AEGIS --
-----------

local function GetAegisDir(player)
    if player:GetFireDirection() ~= Direction.NO_DIRECTION then
        return player:GetAimDirection():GetAngleDegrees() - 180
    elseif player:GetMovementDirection() ~= Direction.NO_DIRECTION then
        return player:GetMovementVector():GetAngleDegrees() - 180
    else
        return player:GetHeadDirection() * 90
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player)
    if not REVEL.game:IsPaused() and player:GetData().AegisDir and REVEL.IsRenderPassNormal() then
        local data = player:GetData()
        local headDir = GetAegisDir(player)
        data.AegisDir = REVEL.LerpAngleDegrees(data.AegisDir, headDir, 0.3)
        data.AegisShield.Velocity = player.Velocity
        data.AegisShield.Position = REVEL.GetOrbitPosition(player, math.rad(data.AegisDir), 30)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()
    if REVEL.ITEM.AEGIS:PlayerHasCollectible(player) then
        if not data.AegisShield or not data.AegisShield:Exists() then
            data.AegisDir = GetAegisDir(player)
            data.AegisShield = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, REVEL.GetOrbitPosition(player, math.rad(data.AegisDir), 30), Vector.Zero, player)
            data.AegisShield:GetData().IsAegisShield = true
            data.AegisShield.Parent = player
            data.AegisShield:GetSprite():Load("gfx/itemeffects/revelcommon/aegis.anm2", true)
            data.AegisShield:GetSprite():SetFrame("Rotate", 0)
        end

    -- rotating to the right spot
    data.AegisShield:GetSprite():SetFrame("Rotate", math.floor(((player.Position-data.AegisShield.Position):GetAngleDegrees()+180)/30+0.5))
    -- blocking all enemy projectiles
    for i,e in ipairs(REVEL.roomProjectiles) do
        if data.AegisShield.Position:DistanceSquared(e.Position) <= (e.Size + 15) ^ 2 then
                e:Die()
        end
    end
    elseif data.AegisShield then
        if data.AegisShield:Exists() then
            data.AegisShield:Remove()
        end

        data.AegisShield = nil
        data.AegisDir = nil
    end
end)

local aegisNoBlockFlags = {
    DamageFlag.DAMAGE_ACID,
    DamageFlag.DAMAGE_CURSED_DOOR,
    DamageFlag.DAMAGE_FAKE,
    DamageFlag.DAMAGE_DEVIL,
    DamageFlag.DAMAGE_EXPLOSION,
    DamageFlag.DAMAGE_INVINCIBLE,
    DamageFlag.DAMAGE_SPIKES,
    DamageFlag.DAMAGE_TNT,
    DamageFlag.DAMAGE_PITFALL,
    DamageFlag.DAMAGE_RED_HEARTS
}

local aegisNoBlockFullFlags = REVEL.reduce(aegisNoBlockFlags, function(flags, f) return flags | f end, 0)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ply, amount, flags, source, iframes)
    ply = ply:ToPlayer()
    local data = ply:GetData()
    if ply and source and source.Entity and REVEL.ITEM.AEGIS:PlayerHasCollectible(ply) and data.AegisDir then
        if HasBit(flags, aegisNoBlockFullFlags) then
            return
        end

        local enemyAngle = (source.Position - ply.Position):GetAngleDegrees()
        if math.abs(REVEL.GetAngleDifference(enemyAngle, data.AegisDir)) < 45 then
            return false
        end
    end
end, EntityType.ENTITY_PLAYER)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if eff:GetData().IsAegisShield then
        if not eff.Parent or not eff.Parent:Exists() or eff.Parent:IsDead() then
            eff:Remove()
        end
    end
end, 6)


end

REVEL.PcallWorkaroundBreakFunction()