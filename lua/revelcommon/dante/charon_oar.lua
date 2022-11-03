local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.OarFullBan = {
    [CollectibleType.COLLECTIBLE_CRICKETS_BODY] = true,
    [CollectibleType.COLLECTIBLE_LACHRYPHAGY] = true,
}

local CHARON_MAX_EXTRA_TEARS = 5

local fireTearJustCalled
function REVEL.CharonsOarConvertTear(tear, player, knockbackMulti, numExtraTears, buffCount, tearDamagePercent)
    numExtraTears = numExtraTears or CHARON_MAX_EXTRA_TEARS - 1
    -- REVEL.sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)
   tear:GetData().oarTear = true
   if not buffCount or buffCount == 0 then
        REVEL.sfx:Play(REVEL.SFX.CHARON_SPLASH_LITTLE, 1, 0, false, 1)
    elseif buffCount == 1 then
        REVEL.sfx:Play(REVEL.SFX.CHARON_SPLASH_MEDIUM, 1, 0, false, 1)
    else
        REVEL.sfx:Play(REVEL.SFX.CHARON_SPLASH_LARGE, 1, 0, false, 1)
    end

    tear.FallingSpeed = tear.FallingSpeed + tear.Height / 10
    tear.Height = -5
    if tearDamagePercent then
        tear.CollisionDamage = tear.CollisionDamage * tearDamagePercent
    else
        tear.CollisionDamage = tear.CollisionDamage / (numExtraTears - 1)
    end

    local innerSpread = 5
    local outerSpread = 15
    if knockbackMulti then
        if buffCount then
            if buffCount > 0 then
                tear.Scale = tear.Scale + (0.2 * buffCount)
            end

            if buffCount == 0 then
                outerSpread = math.floor(outerSpread * 1.5 * 0.75)
                innerSpread = math.floor(innerSpread * 2.5 * 0.75)
                if revel.data.run.dante.IsCombined then
                    tear.Velocity = tear.Velocity * 0.6
                end
            elseif buffCount == 1 then
                outerSpread = math.floor(outerSpread * 1.25 * 0.75)
                innerSpread = math.floor(innerSpread * 1.75 * 0.75)
                if revel.data.run.dante.IsCombined then
                    tear.Velocity = tear.Velocity * 0.8
                end
            elseif buffCount == 2 then
                outerSpread = math.floor(outerSpread * 0.66 * 0.85)
                if revel.data.run.dante.IsCombined then
                    tear.Velocity = tear.Velocity * 1.2
                end
            end
        end
    end

    local vel, scale = tear.Velocity, tear.Scale

    for i = 1, numExtraTears + 1 do
        fireTearJustCalled = true

        local newTear
        if i ~= 1 then
            newTear = player:ToPlayer():FireTear(tear.Position, vel, false, false, false)
        else
            newTear = tear
        end

        if knockbackMulti then
            newTear:GetData().KnockbackMultiplier = knockbackMulti --/ (numCharonExtraTears - 2)
            newTear:GetData().CharonPiercingEnemies = {}
            newTear.TearFlags = BitOr(newTear.TearFlags, TearFlags.TEAR_PIERCING)
        end

        newTear:GetData().CharonsOarCheck = true

        if i ~= 1 then
            newTear.FallingSpeed = tear.FallingSpeed
            newTear.Height = tear.Height
            newTear.CollisionDamage = tear.CollisionDamage
        end

        fireTearJustCalled = nil
        local angle, percent
        if i > 1 and i < numExtraTears + 1 then
            newTear.Velocity = newTear.Velocity * (((math.random() - 0.5) * 0.15) + 1)
            newTear.Scale = scale - (math.random() * 0.2)
            angle = REVEL.Lerp(-innerSpread, innerSpread, (i - 2) / (numExtraTears - 2))
        else
            angle = REVEL.Lerp(-outerSpread, outerSpread, (i - 1) / (numExtraTears))
            newTear.Scale = scale * 0.75
        end
        newTear.Velocity = newTear.Velocity:Rotated(angle)

		if player:HasCollectible(REVEL.ITEM.FECAL_FREAK.id) and i ~= 1 then
			REVEL.FFInvertTear(newTear, player)
		end

		newTear:GetData().oarTear = true
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_TEARS_FIRE_SOUND, 0, function(ent, data, spr)
    if data.oarTear then
        return false
    end
end)

---@return 0|1|2
function REVEL.Dante.GetBuffCount(player)
    local bonus = player:GetData().AimBonus or 0
    local buffCount = 0
    if bonus >= 225 then
        buffCount = 2
    elseif bonus >= 53 then
        buffCount = 1
    end

    return buffCount
end


---@param player EntityPlayer
---@return integer buffCount
---@return integer oarNumExtraTears
---@return number knockbackMulti
---@return number damagePercent
function REVEL.Dante.CalculateBuff(player)
    if not revel.data.run.dante.IsCombined then
        if player:GetData().NoShotYet then
            player:GetData().LastAimDirection = player:GetFireDirection()
        end

        if player:GetData().LastAimDirection ~= player:GetFireDirection() then
            player:GetData().AimBonus = 0
            player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
            player:EvaluateItems()
        end
    end

    local buffCount = REVEL.Dante.GetBuffCount(player)
    local oarNumExtraTears = CHARON_MAX_EXTRA_TEARS
    oarNumExtraTears = oarNumExtraTears - 2 + buffCount
    local knockbackMulti = (1.25 + buffCount / 3) / (CHARON_MAX_EXTRA_TEARS - 3)
    local damagePercent = 1 / (CHARON_MAX_EXTRA_TEARS - 3)

    return buffCount, oarNumExtraTears, knockbackMulti, damagePercent
end

function REVEL.HasBrokenOarEffect(player)
    return player:HasCollectible(REVEL.ITEM.CHARONS_OAR.id) or (REVEL.IsDanteCharon(player) and (revel.data.run.dante.IsCombined or not revel.data.run.dante.IsDante))
end

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 1, function(tear, data, sprite, player, split)
    local applyOar, knockbackMulti, buffCount, damagePercent
    local oarNumExtraTears = CHARON_MAX_EXTRA_TEARS - 1
    if player then
        if REVEL.IsDanteCharon(player) and not fireTearJustCalled then
            if not revel.data.run.dante.IsDante and not split then
                buffCount, oarNumExtraTears, knockbackMulti, damagePercent = REVEL.Dante.CalculateBuff(player)
                if player:HasCollectible(REVEL.ITEM.CHARONS_OAR.id) then
                    oarNumExtraTears = oarNumExtraTears + 2
                end

                applyOar = true
            end
        elseif player:HasCollectible(REVEL.ITEM.CHARONS_OAR.id) then
            applyOar = true
        end

		applyOar = applyOar and not player:HasCollectible(REVEL.ITEM.BURNBUSH.id)
    end

    if applyOar and not fireTearJustCalled and not split then
        REVEL.CharonsOarConvertTear(tear, player, knockbackMulti, oarNumExtraTears, buffCount, damagePercent)
    end
end)

end
REVEL.PcallWorkaroundBreakFunction()