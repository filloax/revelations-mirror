local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
-------------------------
-- BLUE-AMBERED SPIDER --
-------------------------
StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(npc)
    if npc.Variant == REVEL.ENT.FROZEN_SPIDER.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    elseif npc.Variant == REVEL.ENT.YELLOW_FROZEN_SPIDER.variant then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        local sprite = npc:GetSprite()
        sprite:ReplaceSpritesheet(0, "gfx/monsters/revel1/iced_spider_yellow.png")
        sprite:LoadGraphics()
    end
end, REVEL.ENT.FROZEN_SPIDER.id)

local function breakSpider(npc, iceVariant)
    REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
    for i=1, 3 do
        REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), npc, iceVariant)
    end
    npc:ClearEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
    npc:Morph(EntityType.ENTITY_SPIDER, 0, 0, -1)
    npc.HitPoints = npc.MaxHitPoints
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant == REVEL.ENT.FROZEN_SPIDER.variant or npc.Variant == REVEL.ENT.YELLOW_FROZEN_SPIDER.variant then
        local isYellow = npc.Variant == REVEL.ENT.YELLOW_FROZEN_SPIDER.variant
        local iceVariant = REVEL.IceGibType.DEFAULT
        if isYellow then
            iceVariant = REVEL.IceGibType.YELLOW
        end

        local sprite, data = npc:GetSprite()

        npc:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)

        npc.StateFrame = npc.StateFrame + 1

        if not sprite:IsPlaying("Idle") then
            sprite:Play("Idle", true)
        end

        if npc.StateFrame >= 12 and npc.Velocity ~= Vector(0, 0) then
            if isYellow then
                REVEL.SpawnCreep(EffectVariant.CREEP_YELLOW, 0, npc.Position, npc, false)
            else
                REVEL.SpawnIceCreep(npc.Position, npc)
            end
            npc.StateFrame = 0
        end

        if npc:CollidesWithGrid() then
            breakSpider(npc, iceVariant)
        elseif npc:IsDead() then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            for i=1, 3 do
                REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), npc, iceVariant)
            end
        end
    end
end, REVEL.ENT.FROZEN_SPIDER.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, dmg)
    if npc.Variant ~= REVEL.ENT.FROZEN_SPIDER.variant
    or npc.HitPoints - dmg - REVEL.GetDamageBuffer(npc) > 0 then return end --only mortal damage

    local isYellow = npc.Variant == REVEL.ENT.YELLOW_FROZEN_SPIDER.variant
    local iceVariant = REVEL.IceGibType.DEFAULT
    if isYellow then
        iceVariant = REVEL.IceGibType.YELLOW
    end

    breakSpider(npc:ToNPC(), iceVariant)
    return false
end, REVEL.ENT.FROZEN_SPIDER.id)

end