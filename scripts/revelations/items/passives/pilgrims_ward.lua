local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Pilgrim's Ward

local size = 32
local baseSize = 128
local scale = size / baseSize

local lastPlayerMapUpdateFrame

local function SpawnSigil()
    local positions = {}
    local totalWeight = 0
    for i = 0, REVEL.room:GetGridSize() do
        local doPlayerMapUpdate = lastPlayerMapUpdateFrame ~= REVEL.game:GetFrameCount()
        if REVEL.AnyPlayerCanReachIndex(i, doPlayerMapUpdate) then
            lastPlayerMapUpdateFrame = REVEL.game:GetFrameCount()
            
            local pos = REVEL.room:GetGridPosition(i)
            if REVEL.room:IsPositionInRoom(pos, 60) then
                local minDist
                for _, player in ipairs(REVEL.players) do
                    local dist = player.Position:DistanceSquared(pos)
                    if not minDist or dist < minDist then
                        minDist = dist
                    end
                end

                totalWeight = totalWeight + minDist
                positions[#positions + 1] = {pos, minDist}
            end
        end
    end

    local pos = StageAPI.WeightedRNG(positions, nil, nil, totalWeight)

    local sigil = StageAPI.SpawnFloorEffect(pos, Vector.Zero, nil, "gfx/itemeffects/revelcommon/pilgrims_ward_sigil.anm2", true)
    REVEL.GetData(sigil).PilgrimsWardSigil = true
    sigil:GetSprite():Play("Spawn", true)
    sigil.SpriteScale = Vector.One * scale
    sigil.Size = size
    REVEL.GetData(sigil).PilgrimsWardLight = REVEL.SpawnDecoration(pos, Vector.Zero, "Spawn", "gfx/itemeffects/revelcommon/pilgrims_ward_light.anm2", nil, -1)
    REVEL.GetData(sigil).PilgrimsWardLight.SpriteScale = Vector.One * scale * 1.05
    REVEL.GetData(sigil).PilgrimsWardLight.SpriteOffset = Vector(8, 8) * scale
    REVEL.GetData(sigil).PilgrimsWardLight.Color = Color(1, 1, 1, 0.2,conv255ToFloat( 0, 0, 0))
end

local updatingPlayerMap = false

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if not REVEL.room:IsClear() then
        local numWards = 0
        for _, player in ipairs(REVEL.players) do
            if REVEL.ITEM.PILGRIMS_WARD:PlayerHasCollectible(player) then
                numWards = numWards + player:GetCollectibleNum(REVEL.ITEM.PILGRIMS_WARD.id)
            end
        end
    
        if numWards > 0 then
            for i = 1, numWards do
                SpawnSigil()
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if REVEL.GetData(eff).PilgrimsWardSigil then
        local data, sprite = REVEL.GetData(eff), eff:GetSprite()
        if sprite:IsFinished("Activate") then
            SpawnSigil()
            eff:Remove()
        elseif not sprite:IsPlaying("Spawn") and not sprite:IsPlaying("Activate") then
            if not sprite:IsPlaying("Idle") then
                sprite:Play("Idle", true)
            end

            local touched
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(eff.Position) < (size + player.Size) ^ 2 then
                    touched = player
                    break
                end
            end

            if touched then
                sprite:Play("Activate", true)
                local laser = touched:SpawnMawOfVoid(15)
                local radius = laser.Radius * 1.5
                local closestEnemy = REVEL.getClosestEnemy(eff, false, true, true, true)
                if closestEnemy then
                    radius = closestEnemy.Position:Distance(eff.Position)
                end
                laser.Radius = radius
                laser.TearFlags = BitOr(touched.TearFlags, TearFlags.TEAR_HOMING)
                REVEL.GetData(laser).PilgrimsWardLaser = true
                laser:SetBlackHpDropChance(0)
                laser:GetSprite():ReplaceSpritesheet(0, "gfx/itemeffects/revelcommon/pilgrims_ward_laser.png")
                laser:GetSprite():LoadGraphics()
                laser.DisableFollowParent = true
                laser.Position = eff.Position
                laser:Update()
                if data.PilgrimsWardLight and data.PilgrimsWardLight:Exists() then
                    data.PilgrimsWardLight:GetSprite():Play("Activate", true)
                    REVEL.GetData(data.PilgrimsWardLight).anim = "Activate"
                    REVEL.GetData(data.PilgrimsWardLight).time = -1000
                end
            end
        end
    end
end, StageAPI.E.FloorEffect.V)
    
end