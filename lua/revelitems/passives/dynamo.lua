local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------
-- DYNAMO --
------------

--[[
Charge, separate from tears, that shoots tech lasers at all enemies.
Costumes are 1-5 for charging and 6 for shooting
]]
revel.dynamo = {}
revel.dynamo.laserColor = Color(0,0,0,1,conv255ToFloat(200,180,0))
revel.dynamo.fullPlayerColor = Color(1,1,3/5,1,conv255ToFloat(50,50,0))
revel.dynamo.fullChargeColorT = 7 --used for sin period

revel.dynamo.CostumeSprites = {
    "costume_007_dynamo1",
    "costume_007_dynamo2",
    "costume_007_dynamo3",
    "costume_007_dynamo4",
    "costume_007_dynamo5",
    "costume_007_dynamo6",
    "costume_007_dynamo7"
}

function revel:UpdateCostumeCfg()
    revel.dynamo.baseCostumeCfg = REVEL.config:GetNullItem(REVEL.ITEM.DYNAMO.costume)
    revel.dynamo.altCostumeCfg = REVEL.config:GetNullItem(REVEL.COSTUME.DYNAMO_ALT)
end
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, revel.UpdateCostumeCfg)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, revel.UpdateCostumeCfg)

function revel.dynamo.GetCost(player, a)
    local data = player:GetData()
    -- return REVEL.COSTUME.DYNAMO[math.ceil(a * 5 / math.max(65, player.MaxFireDelay * data.dynDelayMult ))]
    return math.ceil(a * 6 / math.max(65, player.MaxFireDelay * data.dynDelayMult ))
end

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    local data = player:GetData()
    if flag == CacheFlag.CACHE_WEAPON and (player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) or player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) or player:GetPlayerType() == PlayerType.PLAYER_AZAZEL) then
        data.dynDelayMult = 8
    else
        data.dynDelayMult = 14
    end
end)

local function fireLaser(player, angle)
    local laser = EntityLaser.ShootAngle(4, player.Position, angle, 4, Vector(0, -16) + Vector(-16, 0):Rotated(angle), player)
    laser.DepthOffset = player.DepthOffset - 1
    laser.RenderZOffset = player.RenderZOffset - 1
    --local lazur = player:FireTechLaser(player.Position, 0, e.Position-player.Position, left, true)
    laser.CollisionDamage = player.Damage
    laser:GetSprite().Color = revel.dynamo.laserColor

    return laser
end

local function setDynamoPhase(player, data, level, alt)
    local spr = "gfx/characters/revelcommon/costumes/"..(revel.dynamo.CostumeSprites[level] or "costume_007_dynamo1")..".png"
    -- REVEL.DebugToString("Using costume", spr, "at level", level, "is alt", alt)
    player:ReplaceCostumeSprite(revel.dynamo.altCostumeCfg, spr, 1)
end

--On render as input works weird on update and inputhook is not required for this
revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player)
    if REVEL.game:IsPaused() 
    or not REVEL.ITEM.DYNAMO:PlayerHasCollectible(player)
    or not REVEL.IsRenderPassNormal() then 
        return 
    end

    local data = player:GetData()
    local data2
    local playerID = REVEL.GetPlayerID(player)
    if player:IsSubPlayer() then
        data2 = REVEL.players[playerID]
    elseif player:GetSubPlayer() then
        data2 = player:GetSubPlayer():GetData()
    end

    --  REVEL.DebugToString({data.dynCharge})
    local isShooting = REVEL.IsShooting(player)

    if REVEL.WasChanged("Dynamo shooting " .. playerID, isShooting) and isShooting then --started shooting
        player:AddNullCostume(REVEL.COSTUME.DYNAMO_ALT) --higher priority costume
    end

    if not data.dynCharge then
        data.dynCColor = Color(1,1,1,1,conv255ToFloat(0,0,0))
        data.dynCharge = 0
    end

    if data.dynCharge < 0 then --cooldown
        data.dynCharge = data.dynCharge + 1

        if data.dynCharge == -30 then
            setDynamoPhase(player, data, 1)
            player:TryRemoveNullCostume(REVEL.COSTUME.DYNAMO_ALT)
        end

    elseif isShooting then
        local maxCharge = math.max(65, math.floor(player.MaxFireDelay*data.dynDelayMult))
        if data.dynCharge < maxCharge then
            data.dynCharge = data.dynCharge + 1

        else --fully charged, glow
            if not data.dynFChargeFrame then data.dynFChargeFrame = player.FrameCount end

            local sinStage = math.sin((player.FrameCount-data.dynFChargeFrame-math.pi/4)/revel.dynamo.fullChargeColorT)/2+0.5 --oscillates from 0 to 1, #maths

            data.dynCColor:SetTint(1, 1, 1 - sinStage * (1 - revel.dynamo.fullPlayerColor.B), 1)
            data.dynCColor:SetOffset(sinStage * revel.dynamo.fullPlayerColor.RO, sinStage * revel.dynamo.fullPlayerColor.GO, 0)
            player:SetColor(data.dynCColor, 5, 5, true, true)
        end

        local costumeSprite = revel.dynamo.GetCost(player, data.dynCharge)

        if costumeSprite ~= data.prevCostumeSprite then
            setDynamoPhase(player, data, revel.dynamo.GetCost(player, data.dynCharge))
            data.prevCostumeSprite = costumeSprite
        end

        if Options.ChargeBars then
            REVEL.SetExtraChargeBarCharge(player, "Dynamo", data.dynCharge, maxCharge, true)
        end
    elseif data.dynCharge >= math.max(65, player.MaxFireDelay*data.dynDelayMult) then --FIRE
        data.dynFChargeFrame = nil
        setDynamoPhase(player, data, 7)
        SFXManager():Play(REVEL.SFX.ELECTRICAL_EXPLOSION, 1, 0, false, 1)
        REVEL.SpawnCustomGlow(player) --no args needed, the dynamo configuration is the default one (spawn discharge sprite)
        data.dynCharge = -40

        if Options.ChargeBars then
            REVEL.RemoveExtraChargeBar(player, "Dynamo")
        end

        local enemies = REVEL.GetNClosestEntities(player.Position, REVEL.roomEnemies, 3, REVEL.IsTargetableEntity, REVEL.IsNotFriendlyEntity, REVEL.IsVulnerableEnemy)

        local lasers = 3
        for i,e in ipairs(enemies) do
            local angle = (e.Position - player.Position):GetAngleDegrees()
            fireLaser(player, angle)
            lasers = lasers - 1
            if lasers <= 0 then
                break
            end
        end

        if lasers > 0 then
            for i = 1, lasers do
                local angle = math.random(1, 360)
                fireLaser(player, angle)
            end
        end
    end

    if data2 then
        data2.dynCColor = data.dynCColor
        data2.dynCharge = data.dynCharge
    end
end)


end

REVEL.PcallWorkaroundBreakFunction()