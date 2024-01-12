local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

------------------
-- SPONGE BOMBS --
------------------

--[[
Bombs absorb tears/projectiles, and add their damage to the explosion damage.
]]

revel.sponge = {
    bombAnims = {"Collect", "Appear", "Pulse", "Explode", "Idle"},
    bombs = {} -- for persistence when switching rooms, GetData() doesn't have that
}
revel.bombsGFX = {}

function revel.setBombGFX(bomb)
    local player = bomb:GetData().__player
    if not revel.bombsGFX[bomb.InitSeed] then -- bomb is new
        revel.bombsGFX[bomb.InitSeed] = {}
        local sprite = bomb:GetSprite()

        if bomb.Variant == BombVariant.BOMB_NORMAL and
        not bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
            if REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(player) then
                if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
                    sprite:ReplaceSpritesheet(0, "gfx/itemeffects/revelcommon/bombs/spritesheets/repentance/mirror_bombs_gold.png")
                else
                    sprite:ReplaceSpritesheet(0, "gfx/itemeffects/revelcommon/bombs/spritesheets/repentance/mirror_bombs.png")
                end
            end
        end

        sprite:LoadGraphics()
    end
end

function revel.spongeSetBombGFX(bomb)
    local player = bomb:GetData().__player
    if not REVEL.ITEM.SPONGE:PlayerHasCollectible(player) then return end
    if not revel.bombsGFX[bomb.InitSeed] then -- bomb is new
        revel.bombsGFX[bomb.InitSeed] = {}

        revel.bombsGFX[bomb.InitSeed].flags = {}
        local flags = bomb:ToBomb().Flags
        local fHoming = HasBit(flags, 1 << 2)
        revel.bombsGFX[bomb.InitSeed].flags[1] = fHoming
        local fPoison = HasBit(flags, 1 << 4)
        -- revel.bombsGFX[bomb.InitSeed].flags[2] = fPoison
        local fFire = HasBit(flags, 1 << 22)
        revel.bombsGFX[bomb.InitSeed].flags[2] = fFire
        local fSad = HasBit(flags, 1 << 28)
        revel.bombsGFX[bomb.InitSeed].flags[3] = fSad
        local fButt = HasBit(flags, 1 << 29)
        revel.bombsGFX[bomb.InitSeed].flags[4] = fButt
        local fGlitter = HasBit(flags, 1 << 30)
        revel.bombsGFX[bomb.InitSeed].flags[5] = fGlitter
        local fFast = player:HasCollectible(
                            CollectibleType.COLLECTIBLE_FAST_BOMBS)
        revel.bombsGFX[bomb.InitSeed].flags[6] = fFast
        revel.bombsGFX[bomb.InitSeed].flags[7] =
            REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(player)

        local body = -1
        if REVEL.ITEM.SPONGE:PlayerHasCollectible(player) then
            if REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(player) then
                body = 23
            elseif fPoison then
                body = 3
            elseif fGlitter then
                body = 5
            else
                body = 1
            end
        elseif REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(player) then
            if fPoison then
                body = 11
            elseif fSad and fButt then
                body = 17
            elseif fSad then
                body = 15
            elseif fButt then
                body = 13
            else
                body = 9
            end
        end
        if player:HasCollectible(CollectibleType.COLLECTIBLE_MR_MEGA) then
            body = body + 1
        end

        revel.bombsGFX[bomb.InitSeed].body = body
    end

    local flags = revel.bombsGFX[bomb.InitSeed].flags
    local body = revel.bombsGFX[bomb.InitSeed].body
    if REVEL.ITEM.SPONGE:PlayerHasCollectible(player) then
        body = body .. "_" .. revel.sponge.bombs[bomb.InitSeed].sprSize
    end

    local sprite = bomb:GetSprite()
    sprite:Load("gfx/itemeffects/revelcommon/bombs/rev_multibomb.anm2",
                false)
    sprite:ReplaceSpritesheet(0,
                                "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/body_" ..
                                    body .. ".png")
    if flags[1] then
        sprite:ReplaceSpritesheet(1,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Homing
    if flags[2] then
        sprite:ReplaceSpritesheet(6,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Fire
    if flags[3] then
        sprite:ReplaceSpritesheet(5,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Sad
    if flags[4] then
        sprite:ReplaceSpritesheet(4,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Butt
    if flags[5] then
        sprite:ReplaceSpritesheet(7,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Glitter
    if flags[6] then
        sprite:ReplaceSpritesheet(2,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Fast
    if flags[7] then
        sprite:ReplaceSpritesheet(3,
                                    "gfx/itemeffects/revelcommon/bombs/spritesheets/regular/effects_" ..
                                        body .. ".png")
    end -- Mirror
    sprite:LoadGraphics()
end

StageAPI.AddCallback("Revelations", RevCallbacks.BOMB_UPDATE_INIT, 1, function(e)
    local data = e:GetData()
    local spr = e:GetSprite()
    local player = e:GetData().__player
    if e.SpawnerType ~= 1 or not player or
        not REVEL.ITEM.SPONGE:PlayerHasCollectible(player) or
        REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        return
    end

    local anim
    for i, v in ipairs(revel.sponge.bombAnims) do
        if spr:IsPlaying(v) then anim = v end
    end

    if not revel.sponge.bombs[e.InitSeed] then
        revel.sponge.bombs[e.InitSeed] = {}
        revel.sponge.bombs[e.InitSeed].startingDmg = e.ExplosionDamage
        revel.sponge.bombs[e.InitSeed].startingScale = Vector(0.8, 0.8)
        revel.sponge.bombs[e.InitSeed].color = Color(1, 1, 1, 1,
                                                        conv255ToFloat(0, 0, 0))
        -- revel.sponge.bombs[e.InitSeed].sprSize = "A"
    end

    -- this down here is for when you reenter the room
    local mult = 1 +
                        (e.ExplosionDamage -
                            revel.sponge.bombs[e.InitSeed].startingDmg) ^ 0.65 *
                        0.10
    e.SpriteScale = revel.sponge.bombs[e.InitSeed].startingScale * mult
    e.RadiusMultiplier = mult ^ 0.5

    if mult <= 1.1 then
        revel.sponge.bombs[e.InitSeed].sprSize = "A"
    elseif mult <= 1.3 then
        revel.sponge.bombs[e.InitSeed].sprSize = "B"
    elseif mult <= 1.5 then
        revel.sponge.bombs[e.InitSeed].sprSize = "C"
    else
        revel.sponge.bombs[e.InitSeed].sprSize = "D"
    end

    revel.spongeSetBombGFX(e)

    spr:Play(anim, true)
    spr.Color = revel.sponge.bombs[e.InitSeed].color
end)

-- on pickup
REVEL.ITEM.SPONGE:addPickupCallback(function (player, playerID, itemID, isD4Effect, firstTimeObtained)
    if firstTimeObtained then
        player:AddBombs(5)
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION,
                        function(_, ent, coll, low)
    if revel.sponge.bombs[coll.InitSeed] then return false end
end)

revel:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION,
                        function(_, ent, coll, low)
    if revel.sponge.bombs[coll.InitSeed] then return false end
end)

function revel.sponge.Absorb(tear, bomb, dmgMult)
    dmgMult = dmgMult or 1
    local c = Isaac.Spawn(1000, 54, 0, bomb.Position, Vector.Zero, bomb) -- 54 = holy water creep
    c.CollisionDamage = 0 -- decorative
    bomb.ExplosionDamage = bomb.ExplosionDamage +
                                math.max(0.5, tear.CollisionDamage) * dmgMult
    SFXManager():Play(REVEL.SFX.SPONGE_SUCK, 1, 0, false, 1)

    -- SYNERGIES (Thanks a lot to Sbody2 for adding many new synergy's gfx (Glitter bombs, Fire mind, Mirror bombs, Bobby-bomb, Fast Bombs, Butt Bombs, MR. MEGA, Fecal Freak))

    local frameAnim -- if the sprite has to be reloaded from bomb flag changes, this is the frame the anim was at to resume it

    local player = tear:GetData().__player

    if player then
        tear = tear:ToTear()
        -- SYNERGIES WITH PLAYER TEARS

        local body = revel.bombsGFX[bomb.InitSeed].body
        body = body .. "_" .. revel.sponge.bombs[bomb.InitSeed].sprSize

        if HasBit(tear.TearFlags, TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP) and
            not revel.sponge.bombs[bomb.InitSeed].mliquid then
            revel.sponge.bombs[bomb.InitSeed].mliquid = true
            revel.sponge.bombs[bomb.InitSeed].color.R =
                revel.sponge.bombs[bomb.InitSeed].color.R * 0.375
            revel.sponge.bombs[bomb.InitSeed].color.GO =
                revel.sponge.bombs[bomb.InitSeed].color.GO + 0.1875
        end
        if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) and
            not revel.sponge.bombs[bomb.InitSeed].ffreak then
            revel.sponge.bombs[bomb.InitSeed].ffreak = true
            frameAnim = bomb:GetSprite():GetFrame()
            bomb.Flags = bomb.Flags | TearFlags.TEAR_BUTT_BOMB
            revel.bombsGFX[bomb.InitSeed].flags[4] = true
        end
        if (HasBit(tear.TearFlags, TearFlags.TEAR_BURN) or
            REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player)) and
            not revel.sponge.bombs[bomb.InitSeed].fmind then
            revel.sponge.bombs[bomb.InitSeed].fmind = true
            frameAnim = bomb:GetSprite():GetFrame()
            bomb.Flags = bomb.Flags | TearFlags.TEAR_BURN
            revel.bombsGFX[bomb.InitSeed].flags[2] = true
        end
        if REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) and
            not revel.sponge.bombs[bomb.InitSeed].mgum then
            revel.sponge.bombs[bomb.InitSeed].mgum = true
            revel.sponge.bombs[bomb.InitSeed].color.R =
                revel.sponge.bombs[bomb.InitSeed].color.R * 0.375
            revel.sponge.bombs[bomb.InitSeed].color.G =
                revel.sponge.bombs[bomb.InitSeed].color.G * 1.125
            revel.sponge.bombs[bomb.InitSeed].color.RO =
                revel.sponge.bombs[bomb.InitSeed].color.RO + 0.125
            revel.sponge.bombs[bomb.InitSeed].color.BO =
                revel.sponge.bombs[bomb.InitSeed].color.BO + 0.75
        end
    end

    tear:Remove()

    local mult = 1 +
                        (bomb.ExplosionDamage -
                            revel.sponge.bombs[bomb.InitSeed].startingDmg) ^
                        0.65 * 0.10
    bomb.SpriteScale = revel.sponge.bombs[bomb.InitSeed].startingScale *
                            mult
    bomb.RadiusMultiplier = mult ^ 0.5

    -- if frameAnim then
    --  bomb:GetSprite():Load("gfx/itemeffects/revelcommon/bombs/rev_multibomb.anm2", false)
    -- end

    local sprSize
    if mult <= 1.1 then
        sprSize = "A"
    elseif mult <= 1.3 then
        sprSize = "B"
    elseif mult <= 1.5 then
        sprSize = "C"
    else
        sprSize = "D"
    end

    if revel.sponge.bombs[bomb.InitSeed].sprSize ~= sprSize or frameAnim then
        frameAnim = bomb:GetSprite():GetFrame()
        revel.sponge.bombs[bomb.InitSeed].sprSize = sprSize
        revel.spongeSetBombGFX(bomb)
    end

    if frameAnim then
        bomb:GetSprite():Play("Pulse", true)
        for i = 1, frameAnim, 1 do -- update the sprite frameAnim times to skip the animation forward, SetFrame makes a freeze frame so it can't be used here
            bomb:GetSprite():Update()
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_BOMB_COLLISION,
                        function(_, bomb, coll, low)
    if not revel.sponge.bombs[bomb.InitSeed] then return end
    if coll.Velocity:Length() >= 3 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT,
                    EffectVariant.TEAR_POOF_VERYSMALL, 0, bomb.Position,
                    Vector.Zero, bomb)
    end
    if coll.Type == 2 then
        revel.sponge.Absorb(coll, bomb)
        return false
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    if revel.sponge.bombs[bomb.InitSeed] then
        -- PROJ COLLISION (bombs normally don't collide with projs)
        for i, proj in ipairs(REVEL.roomProjectiles) do
            if bomb.Position:Distance(proj.Position) < proj.Size + bomb.Size and
                not proj:GetData().spongeBombd then
                revel.sponge.Absorb(proj, bomb, 7)
                Isaac.Spawn(EntityType.ENTITY_EFFECT,
                            EffectVariant.TEAR_POOF_VERYSMALL, 0,
                            bomb.Position, Vector.Zero, bomb)
                proj:GetData().spongeBombd = true -- since they don't immediately vanish with :Die()
            end
        end

        bomb:GetSprite().Color = revel.sponge.bombs[bomb.InitSeed].color
        --    REVEL.DebugToString("Color: ",revel.sponge.bombs[bomb.InitSeed].color, "\n", bomb:GetSprite().Color)

        if bomb:IsDead() then -- KABOOM
            SFXManager():Play(REVEL.SFX.SPONGE_WATER_EXPLOSION, 1, 0, false,
                                1)

            if revel.sponge.bombs[bomb.InitSeed].mliquid then
                local c = Isaac.Spawn(1000, 53, 0, bomb.Position,
                                        Vector.Zero, bomb)
                c.Size = 6 * bomb.RadiusMultiplier
                --        c:GetSprite().Color = Color(0.5,1,0,1,conv255ToFloat(0,70,0))
                revel.sponge.bombs[bomb.InitSeed].mliquid = false
            end

            if revel.sponge.bombs[bomb.InitSeed].ffreak then
                --      bomb.Flags = bomb.Flags | TearFlags.TEAR_BUTT_BOMB
            end
            if revel.sponge.bombs[bomb.InitSeed].ffreak then
                bomb.Flags = bomb.Flags | TearFlags.TEAR_BURN
            end

            revel.sponge.bombs[bomb.InitSeed] = nil
            revel.bombsGFX[bomb.InitSeed] = nil

            --    REVEL.DebugToString("kablooie")
        end
    end
end)

-- ON HIT FOR SYNERGIES
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, __, flag, source)
    if source.Entity and HasBit(flag, DamageFlag.DAMAGE_EXPLOSION) and
        source.Entity.Type == 4 and
        revel.sponge.bombs[source.Entity.InitSeed] then
        if revel.sponge.bombs[source.Entity.InitSeed].mgum then
            npc:GetData().mintGumShot = npc:GetData().mintGumShot + 2
        end
    end
end)

end
