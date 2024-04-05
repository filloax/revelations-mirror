local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local PlayerVariant     = require("scripts.revelations.common.enums.PlayerVariant")

return function()

-------------------
-- GHASTLY FLAME --
-------------------

--[[
Active Item.
Devil Pool. Treasure Pool.
Fires a homing purple flame, similar to other candle items. It will track enemies and deal moderate damage. If a tick from the flame is the killing blow, the sprite of the item changes to show the captured soul. The next use of the item summons a purple flaming ghost that will actively pursue enemies, similar to Meat Boy. It leaves a small purple fire trail in it's wake. The ghost lasts 20 seconds, and cannot be killed. 2 Room Charge.
]]

REVEL.GhastlyFlame = {
    lastDir = {Vector.Zero, Vector.Zero, Vector.Zero, Vector.Zero},
    flames = {},
    flameSeeds = {},
    ghostFlames = {},
    flameSpeed = 9,
    flameSpeedEnd = 4,
    flameColor = Color(1, 1, 1, 0.65, conv255ToFloat(0, 0, 0)),
    lightColor = Color(0, 0, 0, 1, conv255ToFloat(50, 10, 241)),
    flameLife = 80,
    defaultEnt = {Type = EntityType.ENTITY_GAPER, Variant = 0, SubType = 0},
    blacklist = {},
    ghostLife = 550,
    ghostCandleOffset = {Vector(-1, -25), Vector(2, -28), Vector(4, -23)}
}

revel:AddCallback(ModCallbacks.MC_USE_ITEM,
                    function(_, itemID, itemRNG, player, useFlags, activeSlot,
                            customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) 
    and player.Variant == PlayerVariant.PLAYER 
    and player:GetActiveItem() == itemID 
    and (itemID == REVEL.ITEM.GFLAME.id or itemID == REVEL.ITEM.GFLAME2.id) then
        REVEL.ToggleShowActive(player, true)
    end
end)

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, p)
    local data = REVEL.GetData(p)
    local id = REVEL.GetShowingActive(p)

    if (id == REVEL.ITEM.GFLAME.id or id == REVEL.ITEM.GFLAME2.id) and
        p:GetFireDirection() ~= Direction.NO_DIRECTION then
        REVEL.HideActive(p)
        REVEL.ConsumeActiveCharge(p)

        if id == REVEL.ITEM.GFLAME.id then
            REVEL.GhastlyFlame.fireFlame(p)
        else
            local npc = REVEL.ENT.GHOST:spawn(
                p.Position + REVEL.GetCorrectedFiringInput(p) * 32, 
                Vector.Zero,
                p
            )

            p:RemoveCollectible(REVEL.ITEM.GFLAME2.id)
            p:AddCollectible(REVEL.ITEM.GFLAME.id, 0, false)
        end

        if p:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
            p:AddWisp(REVEL.ITEM.GFLAME.id, p.Position)
        end
    end
end)

function REVEL.GhastlyFlame.fireFlame(player)
    local flame = REVEL.ENT.DECORATION:spawn(
        player.Position,
        REVEL.GetCorrectedFiringInput(player) * REVEL.GhastlyFlame.flameSpeed,
        player
    )
    --  flame:GetSprite():Load("gfx/grid/effect_005_fire.anm2", false)
    flame:GetSprite():ReplaceSpritesheet(0, "gfx/effects/effect_005_fire_purple.png")
    flame.Color = REVEL.GhastlyFlame.flameColor
    flame:GetSprite():LoadGraphics()
    --  flame:GetSprite():Play("FireStage00", true)
    REVEL.GetData(flame).timeMax = REVEL.GhastlyFlame.flameLife
    REVEL.GetData(flame).time = REVEL.GetData(flame).timeMax
    REVEL.GetData(flame).homingSpeed = 0
    REVEL.GetData(flame).homingLerp = 1
    flame.CollisionDamage = player.Damage * 2.5
    flame.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

    local i = #REVEL.GhastlyFlame.flames + 1

    REVEL.GhastlyFlame.flames[i] = flame
    REVEL.GhastlyFlame.flameSeeds[flame.InitSeed] = player
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i, v in ripairs(REVEL.GhastlyFlame.flames) do
        local data = REVEL.GetData(v)

        local speed = REVEL.Lerp(REVEL.GhastlyFlame.flameSpeedEnd,
                                    REVEL.GhastlyFlame.flameSpeed,
                                    data.time / data.timeMax)

        local targ = REVEL.getClosestEnemy(v, true, true, true, true)
        if targ and targ.Position:Distance(v.Position) < 150 then
            data.homingLerp = math.min(data.homingLerp + 0.1, 1)
            v.Velocity = v.Velocity +
                                (targ.Position - v.Position):Resized(
                                    REVEL.Lerp(0, speed / 5, data.homingLerp))

        else
            v.Velocity = v.Velocity * 0.95
            data.homingLerp = math.max(data.homingLerp - 0.06, 0)
        end

        local l = v.Velocity:Length()

        if l > speed then v.Velocity = v.Velocity * (speed / l) end

        if data.time > 25 then
            data.time = data.time - 1

            if data.time >= data.timeMax - 25 then
                local m = REVEL.Lerp(1, 0.5, (data.time -
                data.timeMax + 25) / 25)
                v.SpriteScale = Vector(m, m)
                v.SizeMulti = Vector(m, m)
            end

            if v.FrameCount % 3 == 0 then
                local closeEnms = Isaac.FindInRadius(v.Position, v.Size + 8, EntityPartition.ENEMY)
                for i, enm in ipairs(closeEnms) do
                    if enm.Position:Distance(v.Position) < enm.Size + v.Size +
                        3 then
                        enm:TakeDamage(v.CollisionDamage, 0, EntityRef(v), 2)
                        if math.random() > 0.9 then
                            enm:AddBurn(EntityRef(v), 30, 2)
                        end
                        REVEL.sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS,
                                        0.7, 0, false, 1)
                    end
                end
            end
        elseif data.time > 0 then
            local m = REVEL.Lerp(1.5, 1, data.time / 25)
            v.SpriteScale = Vector(m, m)
            v.SizeMulti = Vector(m, m)
            v.Color = Color.Lerp(REVEL.NO_COLOR, REVEL.GhastlyFlame.flameColor,
                                    data.time / 25)
            data.time = data.time - 1
        else
            REVEL.GhastlyFlame.flameSeeds[v.InitSeed] = nil
            v:Remove()
            table.remove(REVEL.GhastlyFlame.flames, i)
        end
    end

    for i, v in ripairs(REVEL.GhastlyFlame.ghostFlames) do
        if v:IsDead() or not v:Exists() then
            table.remove(REVEL.GhastlyFlame.ghostFlames, i)
        end

        local data = REVEL.GetData(v)

        if v.FrameCount <= 10 then
            v.SpriteScale = REVEL.Lerp(REVEL.SquareVec(0.1),
                                        REVEL.SquareVec(0.55),
                                        v.FrameCount / 10)
        end

        if data.height and data.height < 0 then
            data.fallingSpeed = data.fallingSpeed + 1.2
            data.height = math.min(0, data.height + data.fallingSpeed)

            v.SpriteOffset = Vector(0, data.height)
        else -- if data.height == 0 then
            v.Velocity = Vector.Zero
        end

        if v.FrameCount == 150 then REVEL.FadeEntity(v, 30) end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, e)
    local data, spr = REVEL.GetData(e), e:GetSprite()

    data.type = math.random(3)

    spr.Color = Color(1, 1, 1, 0.9, conv255ToFloat(0, 0, 0))
    spr:Play("appear" .. data.type, true)

    e:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    e.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

    if REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
        data.light = REVEL.SpawnLightAtEnt(e, REVEL.GhastlyFlame.lightColor, 1.3)
    end
end, REVEL.ENT.GHOST.variant)

local disappearDur = 6

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    local data, spr = REVEL.GetData(e), e:GetSprite()

    if e.FrameCount == REVEL.GhastlyFlame.ghostLife then
        e.Velocity = Vector.Zero
        spr:Play("disappear" .. data.type, true)
    end

    if spr:IsFinished("appear" .. data.type) then
        spr:Play("idle" .. data.type, true)

    elseif spr:IsFinished("disappear" .. data.type) then
        e:Remove()
        return
    end

    if (not data.light or not data.light:Exists()) and
        REVEL.IsThereCurse(LevelCurse.CURSE_OF_DARKNESS) then
        data.light = REVEL.SpawnLightAtEnt(e, REVEL.GhastlyFlame.lightColor, 1.5)
    end

    if spr:IsPlaying("idle" .. data.type) then
        local targ = REVEL.getClosestEnemy(e, false, true, true, true)

        if targ then
            local pos = targ.Position

            if math.abs(pos.X - e.Position.X) < 48 then -- come closer horizontally before than vertically, for looks I guess idk just wanted to do that lol
                e.Velocity = e.Velocity + (pos - e.Position):Resized(0.5)
            else
                local closerpos = pos +
                                        Vector(0, 32 *
                                                    sign(pos.Y - e.Position.Y)) -- get position at same X as target pos but just slightly towards him in Y
                e.Velocity = e.Velocity +
                                    (closerpos - e.Position):Resized(0.5)
            end

            local length = e.Velocity:Length()
            if length > 5 then
                e.Velocity = e.Velocity * (5 / length)
            end
        else
            REVEL.MoveRandomly(e, 20, 35, 40, math.random(3, 5) * 0.1, 0.9,
                                e.Player.Position)
        end

        if e.FrameCount % 20 == 0 then
            local flame = Isaac.Spawn(1000, EffectVariant.RED_CANDLE_FLAME,
                                        0, e.Position +
                                            REVEL.GetXVector(
                                                REVEL.GhastlyFlame.ghostCandleOffset[data.type]),
                                        RandomVector() * 2, e)

            flame:GetSprite():ReplaceSpritesheet(0,
                                                    "gfx/effects/effect_005_fire_purple.png")
            flame.Color = REVEL.GhastlyFlame.flameColor
            flame:GetSprite():LoadGraphics()

            REVEL.GetData(flame).height =
                REVEL.GhastlyFlame.ghostCandleOffset[data.type].Y
            REVEL.GetData(flame).fallingSpeed = -5
            flame.SpriteOffset = REVEL.GetYVector(REVEL.GhastlyFlame
                                                        .ghostCandleOffset[data.type])
            flame.SpriteScale = REVEL.SquareVec(0.1)
            flame.CollisionDamage = e.Player.Damage * 0.2
            flame.EntityCollisionClass =
                EntityCollisionClass.ENTCOLL_ENEMIES

            table.insert(REVEL.GhastlyFlame.ghostFlames, flame)
        end

        if e.FrameCount % 2 == 0 then
            local closeEnms = Isaac.FindInRadius(e.Position, e.Size + 8, EntityPartition.ENEMY)
            for i, enm in ipairs(closeEnms) do
                if enm.Position:Distance(e.Position) < enm.Size + e.Size + 3 then
                    enm:TakeDamage(2.2, 0, EntityRef(e), 2)
                    if math.random() > 0.6 then
                        enm:AddBurn(EntityRef(e), 30, 2)
                    end
                end
            end
        end
    end
end, REVEL.ENT.GHOST.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    REVEL.GhastlyFlame.flames = {}
    REVEL.GhastlyFlame.flameSeeds = {}
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,
                    function(_, e, dmg, flag, src)
    if e:ToNPC() and e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0 and src.Entity and
        REVEL.GhastlyFlame.flameSeeds[src.Entity.InitSeed] then
        local player = REVEL.GhastlyFlame.flameSeeds[src.Entity.InitSeed]
        local id = player:GetActiveItem()
        local data = REVEL.GetData(player)

        if id == REVEL.ITEM.GFLAME.id then
            player:RemoveCollectible(REVEL.ITEM.GFLAME.id)
            player:AddCollectible(REVEL.ITEM.GFLAME2.id, 0, false)
        end
    end
end)

end
