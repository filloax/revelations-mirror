local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

------------------
-- SPONGE BOMBS --
------------------

--[[
Bombs absorb tears/projectiles, and add their damage to the explosion damage.
]]

local Sponge = {
    bombAnims = {"Collect", "Appear", "Pulse", "Explode", "Idle"},
    bombs = {} -- for persistence when switching rooms, GetData() doesn't have that
}

local function SpongeSetBombGFX(bomb)
    local player = REVEL.GetData(bomb).__player
    if not REVEL.ITEM.SPONGE:PlayerHasCollectible(player) then return end
    if not REVEL.BombsGFX[bomb.InitSeed] then -- bomb is new
        REVEL.BombsGFX[bomb.InitSeed] = {}

        REVEL.BombsGFX[bomb.InitSeed].flags = {}
        local flags = bomb:ToBomb().Flags
        local fHoming = HasBit(flags, 1 << 2)
        REVEL.BombsGFX[bomb.InitSeed].flags[1] = fHoming
        local fPoison = HasBit(flags, 1 << 4)
        -- REVEL.BombsGFX[bomb.InitSeed].flags[2] = fPoison
        local fFire = HasBit(flags, 1 << 22)
        REVEL.BombsGFX[bomb.InitSeed].flags[2] = fFire
        local fSad = HasBit(flags, 1 << 28)
        REVEL.BombsGFX[bomb.InitSeed].flags[3] = fSad
        local fButt = HasBit(flags, 1 << 29)
        REVEL.BombsGFX[bomb.InitSeed].flags[4] = fButt
        local fGlitter = HasBit(flags, 1 << 30)
        REVEL.BombsGFX[bomb.InitSeed].flags[5] = fGlitter
        local fFast = player:HasCollectible(
                            CollectibleType.COLLECTIBLE_FAST_BOMBS)
        REVEL.BombsGFX[bomb.InitSeed].flags[6] = fFast
        REVEL.BombsGFX[bomb.InitSeed].flags[7] =
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

        REVEL.BombsGFX[bomb.InitSeed].body = body
    end

    local flags = REVEL.BombsGFX[bomb.InitSeed].flags
    local body = REVEL.BombsGFX[bomb.InitSeed].body
    if REVEL.ITEM.SPONGE:PlayerHasCollectible(player) then
        body = body .. "_" .. Sponge.bombs[bomb.InitSeed].sprSize
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
    local data = REVEL.GetData(e)
    local spr = e:GetSprite()
    local player = REVEL.GetData(e).__player
    if e.SpawnerType ~= 1 or not player or
        not REVEL.ITEM.SPONGE:PlayerHasCollectible(player) or
        REVEL.ITEM.WRATHS_RAGE:PlayerHasCollectible(player) then
        return
    end

    local anim
    for i, v in ipairs(Sponge.bombAnims) do
        if spr:IsPlaying(v) then anim = v end
    end

    if not Sponge.bombs[e.InitSeed] then
        Sponge.bombs[e.InitSeed] = {}
        Sponge.bombs[e.InitSeed].startingDmg = e.ExplosionDamage
        Sponge.bombs[e.InitSeed].startingScale = Vector(0.8, 0.8)
        Sponge.bombs[e.InitSeed].color = Color(1, 1, 1, 1,
                                                        conv255ToFloat(0, 0, 0))
        -- Sponge.bombs[e.InitSeed].sprSize = "A"
    end

    -- this down here is for when you reenter the room
    local mult = 1 +
                        (e.ExplosionDamage -
                            Sponge.bombs[e.InitSeed].startingDmg) ^ 0.65 *
                        0.10
    e.SpriteScale = Sponge.bombs[e.InitSeed].startingScale * mult
    e.RadiusMultiplier = mult ^ 0.5

    if mult <= 1.1 then
        Sponge.bombs[e.InitSeed].sprSize = "A"
    elseif mult <= 1.3 then
        Sponge.bombs[e.InitSeed].sprSize = "B"
    elseif mult <= 1.5 then
        Sponge.bombs[e.InitSeed].sprSize = "C"
    else
        Sponge.bombs[e.InitSeed].sprSize = "D"
    end

    SpongeSetBombGFX(e)

    spr:Play(anim, true)
    spr.Color = Sponge.bombs[e.InitSeed].color
end)

-- on pickup
REVEL.ITEM.SPONGE:addPickupCallback(function (player, playerID, itemID, isD4Effect, firstTimeObtained)
    if firstTimeObtained then
        player:AddBombs(5)
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, ent, coll, low)
    if Sponge.bombs[coll.InitSeed] then return false end
end)

revel:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, function(_, ent, coll, low)
    if Sponge.bombs[coll.InitSeed] then return false end
end)

function Sponge.Absorb(tear, bomb, dmgMult)
    dmgMult = dmgMult or 1
    local c = Isaac.Spawn(1000, 54, 0, bomb.Position, Vector.Zero, bomb) -- 54 = holy water creep
    c.CollisionDamage = 0 -- decorative
    bomb.ExplosionDamage = bomb.ExplosionDamage +
                                math.max(0.5, tear.CollisionDamage) * dmgMult
    SFXManager():Play(REVEL.SFX.SPONGE_SUCK, 1, 0, false, 1)

    -- SYNERGIES (Thanks a lot to Sbody2 for adding many new synergy's gfx (Glitter bombs, Fire mind, Mirror bombs, Bobby-bomb, Fast Bombs, Butt Bombs, MR. MEGA, Fecal Freak))

    local frameAnim -- if the sprite has to be reloaded from bomb flag changes, this is the frame the anim was at to resume it

    local player = REVEL.GetData(tear).__player

    if player then
        tear = tear:ToTear()
        -- SYNERGIES WITH PLAYER TEARS

        local body = REVEL.BombsGFX[bomb.InitSeed].body
        body = body .. "_" .. Sponge.bombs[bomb.InitSeed].sprSize

        if HasBit(tear.TearFlags, TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP) and
            not Sponge.bombs[bomb.InitSeed].mliquid then
            Sponge.bombs[bomb.InitSeed].mliquid = true
            Sponge.bombs[bomb.InitSeed].color.R =
                Sponge.bombs[bomb.InitSeed].color.R * 0.375
            Sponge.bombs[bomb.InitSeed].color.GO =
                Sponge.bombs[bomb.InitSeed].color.GO + 0.1875
        end
        if REVEL.ITEM.FECAL_FREAK:PlayerHasCollectible(player) and
            not Sponge.bombs[bomb.InitSeed].ffreak then
            Sponge.bombs[bomb.InitSeed].ffreak = true
            frameAnim = bomb:GetSprite():GetFrame()
            bomb.Flags = bomb.Flags | TearFlags.TEAR_BUTT_BOMB
            REVEL.BombsGFX[bomb.InitSeed].flags[4] = true
        end
        if (HasBit(tear.TearFlags, TearFlags.TEAR_BURN) or
            REVEL.ITEM.BURNBUSH:PlayerHasCollectible(player)) and
            not Sponge.bombs[bomb.InitSeed].fmind then
            Sponge.bombs[bomb.InitSeed].fmind = true
            frameAnim = bomb:GetSprite():GetFrame()
            bomb.Flags = bomb.Flags | TearFlags.TEAR_BURN
            REVEL.BombsGFX[bomb.InitSeed].flags[2] = true
        end
        if REVEL.ITEM.MINT_GUM:PlayerHasCollectible(player) and
            not Sponge.bombs[bomb.InitSeed].mgum then
            Sponge.bombs[bomb.InitSeed].mgum = true
            Sponge.bombs[bomb.InitSeed].color.R =
                Sponge.bombs[bomb.InitSeed].color.R * 0.375
            Sponge.bombs[bomb.InitSeed].color.G =
                Sponge.bombs[bomb.InitSeed].color.G * 1.125
            Sponge.bombs[bomb.InitSeed].color.RO =
                Sponge.bombs[bomb.InitSeed].color.RO + 0.125
            Sponge.bombs[bomb.InitSeed].color.BO =
                Sponge.bombs[bomb.InitSeed].color.BO + 0.75
        end
    end

    tear:Remove()

    local mult = 1 +
                        (bomb.ExplosionDamage -
                            Sponge.bombs[bomb.InitSeed].startingDmg) ^
                        0.65 * 0.10
    bomb.SpriteScale = Sponge.bombs[bomb.InitSeed].startingScale *
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

    if Sponge.bombs[bomb.InitSeed].sprSize ~= sprSize or frameAnim then
        frameAnim = bomb:GetSprite():GetFrame()
        Sponge.bombs[bomb.InitSeed].sprSize = sprSize
        SpongeSetBombGFX(bomb)
    end

    if frameAnim then
        bomb:GetSprite():Play("Pulse", true)
        for i = 1, frameAnim, 1 do -- update the sprite frameAnim times to skip the animation forward, SetFrame makes a freeze frame so it can't be used here
            bomb:GetSprite():Update()
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_BOMB_COLLISION, function(_, bomb, coll, low)
    if not Sponge.bombs[bomb.InitSeed] then return end
    if coll.Velocity:Length() >= 3 then
        Isaac.Spawn(EntityType.ENTITY_EFFECT,
                    EffectVariant.TEAR_POOF_VERYSMALL, 0, bomb.Position,
                    Vector.Zero, bomb)
    end
    if coll.Type == 2 then
        Sponge.Absorb(coll, bomb)
        return false
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    if Sponge.bombs[bomb.InitSeed] then
        -- PROJ COLLISION (bombs normally don't collide with projs)
        for i, proj in ipairs(REVEL.roomProjectiles) do
            if bomb.Position:Distance(proj.Position) < proj.Size + bomb.Size and
                not REVEL.GetData(proj).spongeBombd then
                Sponge.Absorb(proj, bomb, 7)
                Isaac.Spawn(EntityType.ENTITY_EFFECT,
                            EffectVariant.TEAR_POOF_VERYSMALL, 0,
                            bomb.Position, Vector.Zero, bomb)
                REVEL.GetData(proj).spongeBombd = true -- since they don't immediately vanish with :Die()
            end
        end

        bomb:GetSprite().Color = Sponge.bombs[bomb.InitSeed].color
        --    REVEL.DebugToString("Color: ",Sponge.bombs[bomb.InitSeed].color, "\n", bomb:GetSprite().Color)

        if bomb:IsDead() then -- KABOOM
            SFXManager():Play(REVEL.SFX.SPONGE_WATER_EXPLOSION, 1, 0, false,
                                1)

            if Sponge.bombs[bomb.InitSeed].mliquid then
                local c = Isaac.Spawn(1000, 53, 0, bomb.Position,
                                        Vector.Zero, bomb)
                c.Size = 6 * bomb.RadiusMultiplier
                --        c:GetSprite().Color = Color(0.5,1,0,1,conv255ToFloat(0,70,0))
                Sponge.bombs[bomb.InitSeed].mliquid = false
            end

            if Sponge.bombs[bomb.InitSeed].ffreak then
                --      bomb.Flags = bomb.Flags | TearFlags.TEAR_BUTT_BOMB
            end
            if Sponge.bombs[bomb.InitSeed].ffreak then
                bomb.Flags = bomb.Flags | TearFlags.TEAR_BURN
            end

            Sponge.bombs[bomb.InitSeed] = nil
            REVEL.BombsGFX[bomb.InitSeed] = nil

            --    REVEL.DebugToString("kablooie")
        end
    end
end)

-- ON HIT FOR SYNERGIES
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc, __, flag, source)
    if source.Entity and HasBit(flag, DamageFlag.DAMAGE_EXPLOSION) and
        source.Entity.Type == 4 and
        Sponge.bombs[source.Entity.InitSeed] then
        if Sponge.bombs[source.Entity.InitSeed].mgum then
            REVEL.GetData(npc).mintGumShot = REVEL.GetData(npc).mintGumShot + 2
        end
    end
end)

end
