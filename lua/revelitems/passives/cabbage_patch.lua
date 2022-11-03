local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------------
-- CABBAGE PATCH --
-------------------

--[[
Randomly in any given room, a cabbage will spawn in a grid slot. Doesn’t block enemies or the player. The cabbage will need to be watered via tears to grow. Upon reaching full size, explodes in a green puff that acts as a bomb and spawns a cabbage familiar that will follow Isaac. They are never idle, always hopping cutely around the player. The cabbage has adorable eyes and will fling itself at enemies repeatedly. Damaging them for the players damage *1.5. After throwing itself at an enemy 20 times, it will die, leaving behind half a red heart. There is no cap on how many cabbages you can have active, beyond their constant attempts to kill themselves.
]]

revel.cabbage = {
    spd = 6.5,
    maxHp = 5,
    hopLength = 11, -- between hop and land frames in anim, should be same for Attack and Hop rn
    collisions = {GridCollisionClass.COLLISION_NONE},
    idleSpriteBottom = { -- check revel2_core (pitfalls)
        [{0, 4}] = 1,
        [{5, 6}] = 2,
        [{7, 11}] = 1
    },
    types = {
        cabbage = {Weight = 100, NoCount = true},
        redcabbage = {
            Weight = 3,
            IncreaseByCount = 1,
            NoCount = true,
            ExplosionColor = Color(0.5, 0.02, 0.02, 0.55,
                                    conv255ToFloat(134, 70, 70)),
            ExplodeOnDeath = true,
            SpeedMult = 1.2,
            DamageMult = 2,
            PlaybackSpeed = 1.3
        },
        carrot = {
            Weight = 50,
            IfAny = {
                TearFlags = {TearFlags.TEAR_PIERCING},
                Items = {
                    CollectibleType.COLLECTIBLE_8_INCH_NAILS,
                    CollectibleType.COLLECTIBLE_EUTHANASIA,
                    CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE
                }
            },
            ExplosionColor = REVEL.CustomColor(255, 118, 25, 0.55),
            SpecialAttackAnim = "DrillAttack",
            SelectAttack = function(fam, targ, targPos, canNormal)
                if canNormal and math.random(1, 2) == 1 and targ and
                    targ:IsActiveEnemy(false) then
                    fam:GetSprite():Play("DrillHop")
                    return true
                end
            end,
            Update = function(fam, targ, targPos)
                local sprite = fam:GetSprite()
                if sprite:IsFinished("DrillHop") then
                    sprite:Play("DrillAttack")
                end

                if sprite:IsPlaying("DrillHop") and
                    sprite:IsEventTriggered("Hop") then
                    fam.Velocity = (targPos - fam.Position) / 16
                end

                if sprite:IsPlaying("DrillAttack") then
                    fam:GetData().CanHit = true
                    fam:GetData().HurtMultiplier = 0.05
                    fam:GetData().Damage = fam:GetData().Damage * 0.05
                    fam.Velocity = Vector.Zero
                end
            end
        },
        pepper = {
            Weight = 50,
            IfAny = {
                TearFlags = {TearFlags.TEAR_BURN},
                Items = {
                    REVEL.ITEM.BURNBUSH.id,
                    CollectibleType.COLLECTIBLE_EXPLOSIVO,
                    CollectibleType.COLLECTIBLE_GHOST_PEPPER
                }
            },
            ExplosionColor = Color(0.5, 0.02, 0.02, 0.55,
                                    conv255ToFloat(134, 70, 70)),
            ExplodeOnDeath = true,
            Death = function(fam)
                Isaac.Spawn(EntityType.ENTITY_EFFECT,
                            EffectVariant.HOT_BOMB_FIRE, 0, fam.Position,
                            Vector.Zero, nil)
            end,
            SpeedMult = 1.5,
            DamageMult = 1.5,
            HopLength = 6
        },
        beetroot = {
            Weight = 50,
            IfAny = {
                TearFlags = {TearFlags.TEAR_HOMING},
                Items = {
                    CollectibleType.COLLECTIBLE_MOMS_EYE,
                    CollectibleType.COLLECTIBLE_MOMS_EYESHADOW,
                    CollectibleType.COLLECTIBLE_3_DOLLAR_BILL,
                    CollectibleType.COLLECTIBLE_FRUIT_CAKE
                }
            },
            ExplosionColor = Color(0.5, 0.02, 0.02, 0.55,
                                    conv255ToFloat(134, 70, 70)),
            SpecialAttackAnim = "Shoot",
            SelectAttack = function(fam, targ, targPos, canNormal)
                if targ and math.random(1, 4) == 1 and
                    targ:IsActiveEnemy(false) then
                    fam:GetSprite():Play("Shoot", true)
                    return true
                end
            end,
            Update = function(fam, targ, targPos)
                local sprite = fam:GetSprite()
                if sprite:IsPlaying("Shoot") then
                    if sprite:IsEventTriggered("Shoot") then
                        local tear =
                            Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0,
                                        fam.Position, (targPos -
                                            fam.Position):Resized(10), nil):ToTear()
                        tear.Color = fam.Player.TearColor
                        tear.TearFlags = TearFlags.TEAR_HOMING
                        tear.CollisionDamage = fam:GetData().Damage * 1.5
                    end

                    fam.Velocity = Vector.Zero
                end
            end
        },
        garlic = {
            Weight = 50,
            ExplosionColor = REVEL.CustomColor(211, 211, 211, 0.55),
            IfAny = {
                TearFlags = {TearFlags.TEAR_POISON, TearFlags.TEAR_ACID},
                Items = {
                    CollectibleType.COLLECTIBLE_SULFURIC_ACID,
                    CollectibleType.COLLECTIBLE_MYSTERIOUS_LIQUID,
                    CollectibleType.COLLECTIBLE_SERPENTS_KISS,
                    CollectibleType.COLLECTIBLE_TOXIC_SHOCK,
                    CollectibleType.COLLECTIBLE_BOBS_BRAIN,
                    CollectibleType.COLLECTIBLE_COMMON_COLD,
                    CollectibleType.COLLECTIBLE_SCORPIO,
                    CollectibleType.COLLECTIBLE_DEAD_TOOTH,
                    CollectibleType.COLLECTIBLE_CONTAGION
                }
            },
            Update = function(fam)
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy.Position:DistanceSquared(fam.Position) <
                        (enemy.Size + fam.Size + 40) ^ 2 then
                        enemy:AddPoison(EntityRef(fam), 4,
                                        fam:GetData().Damage / 1.5)
                    end
                end
            end
        },
        pumpkin = {
            Weight = 50,
            ExplosionColor = REVEL.CustomColor(255, 118, 25, 0.55),
            IfAny = {
                TearFlags = {TearFlags.TEAR_FEAR},
                Items = {
                    CollectibleType.COLLECTIBLE_ABADDON,
                    CollectibleType.COLLECTIBLE_COMPOUND_FRACTURE,
                    CollectibleType.COLLECTIBLE_APPLE,
                    CollectibleType.COLLECTIBLE_DARK_MATTER,
                    CollectibleType.COLLECTIBLE_MOMS_PERFUME,
                    CollectibleType.COLLECTIBLE_HOST_HAT
                },
                Characters = {
                    PlayerType.PLAYER_THEFORGOTTEN,
                    PlayerType.PLAYER_THESOUL, PlayerType.PLAYER_XXX,
                    PlayerType.PLAYER_THELOST, PlayerType.PLAYER_KEEPER
                }
            },
            Update = function(fam)
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy.Position:DistanceSquared(fam.Position) <
                        (enemy.Size + fam.Size + 60) ^ 2 then
                        enemy:AddFear(EntityRef(fam), 4)
                    end
                end
            end
        },
        broccoli = {
            Weight = 50,
            IfAny = {
                Items = {
                    CollectibleType.COLLECTIBLE_TECH_5,
                    CollectibleType.COLLECTIBLE_TECHNOLOGY,
                    CollectibleType.COLLECTIBLE_TECHNOLOGY_2,
                    CollectibleType.COLLECTIBLE_TECH_X,
                    CollectibleType.COLLECTIBLE_TECHNOLOGY_ZERO
                }
            },
            SpecialAttackAnim = "ElectricShock",
            SelectAttack = function(fam, targ)
                if math.random(1, 4) == 1 and targ and
                    targ:IsActiveEnemy(false) then
                    fam:GetSprite():Play("ElectricShock", true)
                    return true
                end
            end,
            Update = function(fam)
                local sprite = fam:GetSprite()
                if sprite:IsPlaying("ElectricShock") then
                    fam.Velocity = Vector.Zero
                    local shootLaser =
                        sprite:IsEventTriggered("AttackStart")
                    if not shootLaser and
                        sprite:WasEventTriggered("AttackStart") and
                        not sprite:WasEventTriggered("AttackEnd") then
                        shootLaser = math.random(1, 10) == 1
                    end

                    if shootLaser then
                        local enemies =
                            REVEL.GetNClosestEntities(fam.Position,
                                                        REVEL.roomEnemies, 3,
                                                        REVEL.IsTargetableEntity,
                                                        REVEL.IsNotFriendlyEntity,
                                                        REVEL.IsVulnerableEnemy)
                        if #enemies > 0 then
                            local enemy = enemies[math.random(1, #enemies)]
                            local laser =
                                EntityLaser.ShootAngle(2, fam.Position,
                                                        (enemy.Position -
                                                            fam.Position):GetAngleDegrees(),
                                                        4, Vector(0, -16),
                                                        fam)
                            laser.CollisionDamage =
                                fam:GetData().Damage * 0.22
                        end
                    end
                end
            end
        },
        mustard = {
            Weight = 50,
            IfAny = {
                Items = {
                    CollectibleType.COLLECTIBLE_SACRED_HEART,
                    CollectibleType.COLLECTIBLE_GODHEAD,
                    CollectibleType.COLLECTIBLE_HOLY_LIGHT,
                    CollectibleType.COLLECTIBLE_HOLY_GRAIL,
                    CollectibleType.COLLECTIBLE_HOLY_MANTLE,
                    CollectibleType.COLLECTIBLE_DEAD_DOVE,
                    CollectibleType.COLLECTIBLE_TRISAGION,
                    CollectibleType.COLLECTIBLE_HOLY_WATER
                }
            },
            ExplosionColor = REVEL.CustomColor(72, 209, 204, 0.55),
            Update = function(fam)
                local isSlowing = not fam:GetSprite():IsPlaying("Death")
                local lightDamage = fam:GetSprite():WasEventTriggered(
                                        "LightDamage")
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    local dist =
                        enemy.Position:DistanceSquared(fam.Position)
                    if lightDamage and dist < (enemy.Size + fam.Size + 20) ^
                        2 then
                        enemy:TakeDamage(fam:GetData().Damage * 0.8, 0,
                                            EntityRef(fam), 0)
                    elseif isSlowing and dist < (enemy.Size + fam.Size + 60) ^
                        2 then
                        enemy:AddSlowing(EntityRef(fam), 4, 0.8, Color(1, 1,
                                                                        1, 1,
                                                                        conv255ToFloat(
                                                                            0,
                                                                            0,
                                                                            0)))
                    end
                end
            end,
            Render = function(fam, renderOffset)
                local sprite, data = fam:GetSprite(), fam:GetData()
                if not data.MustardGlow then
                    data.MustardGlow = Sprite()
                    data.MustardGlow:Load(
                        "gfx/familiar/revelcommon/cabbage_patch/veggie/mustard_light.anm2",
                        true)
                    data.MustardGlow:Play("Idle", true)
                end

                if sprite:IsPlaying("Death") and
                    not (data.MustardGlow:IsPlaying("Vanish") or
                        data.MustardGlow:IsFinished("Vanish")) then
                    data.MustardGlow:Play("Vanish", true)
                end

                if not data.MustardGlow:IsPlaying("Idle") and
                    not (data.MustardGlow:IsPlaying("Vanish") or
                        data.MustardGlow:IsFinished("Vanish")) then
                    data.MustardGlow:Play("Idle", true)
                end

                data.MustardGlow:Render(Isaac.WorldToScreen(fam.Position) + renderOffset - REVEL.room:GetRenderScrollOffset())
            end
        },
        tomato = {
            Weight = 50,
            ExplosionColor = Color(0.5, 0.02, 0.02, 0.55,
                                    conv255ToFloat(134, 70, 70)),
            IfAny = {
                Items = {
                    CollectibleType.COLLECTIBLE_BRIMSTONE,
                    CollectibleType.COLLECTIBLE_MEGA_SATANS_BREATH,
                    CollectibleType.COLLECTIBLE_HEAD_OF_KRAMPUS,
                    CollectibleType.COLLECTIBLE_LIL_BRIMSTONE
                },
                Characters = {PlayerType.PLAYER_AZAZEL}
            },
            Death = function(fam)
                for i = 1, 4 do
                    local laser = EntityLaser.ShootAngle(1, fam.Position,
                                                            i * 90, 60,
                                                            Vector.Zero, fam)
                    laser.MaxDistance = 100
                end
            end
        },
        artichoke = {
            Weight = 50,
            IfAny = {Items = {CollectibleType.COLLECTIBLE_MOMS_KNIFE}},
            SpecialAttackAnim = "Shoot",
            SelectAttack = function(fam, targ, targPos, canNormal)
                if targ and math.random(1, 4) == 1 and
                    targ:IsActiveEnemy(false) then
                    fam:GetSprite():Play("Shoot", true)
                    return true
                end
            end,
            Update = function(fam, targ, targPos)
                local sprite, data = fam:GetSprite(), fam:GetData()
                if sprite:IsPlaying("Shoot") then
                    if sprite:IsEventTriggered("Shoot") then
                        data.ArtichokeLeaf =
                            REVEL.SpawnDecoration(fam.Position, (targPos -
                                                        fam.Position) / 10,
                                                    "LeafBlade",
                                                    "gfx/familiar/revelcommon/cabbage_patch/veggie/artichoke_leafblade.anm2",
                                                    nil, -1000)
                        data.ArtichokeLeaf:GetSprite().Rotation =
                            data.ArtichokeLeaf.Velocity:GetAngleDegrees()
                        if data.ArtichokeLeaf.Velocity:LengthSquared() < 5 ^
                            2 then
                            data.ArtichokeLeaf.Velocity = data.ArtichokeLeaf
                                                                .Velocity:Resized(
                                                                5)
                        end
                    end

                    fam.Velocity = Vector.Zero
                end

                if data.ArtichokeLeaf and not data.ArtichokeLeaf:Exists() then
                    data.ArtichokeLeaf = nil
                elseif data.ArtichokeLeaf then
                    for _, enemy in ipairs(REVEL.roomEnemies) do
                        if enemy.Position:DistanceSquared(data.ArtichokeLeaf
                                                                .Position) <
                            (enemy.Size + 10) ^ 2 then
                            enemy:TakeDamage(data.Damage * 0.075, 0,
                                                EntityRef(fam), 0)
                        end
                    end

                    if data.ArtichokeLeaf.FrameCount > 23 then
                        data.ArtichokeLeaf:Remove()
                        data.ArtichokeLeaf = nil
                    elseif data.ArtichokeLeaf.FrameCount > 10 then
                        data.ArtichokeLeaf.Velocity = data.ArtichokeLeaf
                                                            .Velocity * 0.95 +
                                                            (fam.Position -
                                                                data.ArtichokeLeaf
                                                                    .Position):Resized(
                                                                REVEL.Lerp(2,
                                                                            12,
                                                                            (data.ArtichokeLeaf
                                                                                .FrameCount -
                                                                                11) /
                                                                                10))
                        if data.ArtichokeLeaf.Position:DistanceSquared(
                            fam.Position) < (fam.Size + 10) ^ 2 or
                            math.abs(
                                REVEL.GetAngleDifference(
                                    data.ArtichokeLeaf:GetSprite().Rotation,
                                    ((data.ArtichokeLeaf.Position +
                                        data.ArtichokeLeaf.Velocity) -
                                        fam.Position):GetAngleDegrees())) >
                            45 then
                            data.ArtichokeLeaf:Remove()
                            data.ArtichokeLeaf = nil
                        end
                    end
                end
            end
        },
        potato = {
            Weight = 50,
            IfAny = {Items = {CollectibleType.COLLECTIBLE_DR_FETUS}},
            ExplosionColor = REVEL.CustomColor(183, 146, 104, 0.55),
            SpecialDeath = true,
            Update = function(fam)
                local sprite = fam:GetSprite()
                if sprite:IsFinished("IdleMine") or
                    sprite:IsFinished("SovietAirStrike") then
                    sprite:Play("IdleMine", true)
                end

                if sprite:IsPlaying("IdleMine") then
                    fam:GetData().RemoveOnNewRoom = true
                    fam.Velocity = Vector.Zero
                    local trigger
                    for _, enemy in ipairs(REVEL.roomEnemies) do
                        if enemy.Position:DistanceSquared(fam.Position) <
                            (enemy.Size + fam.Size) ^ 2 then
                            trigger = true
                            break
                        end
                    end

                    if trigger then
                        sprite:Play("MineExplode", true)
                    end
                elseif sprite:IsPlaying("MineExplode") then
                    fam:GetData().RemoveOnNewRoom = true
                    fam.Velocity = Vector.Zero
                end

                if sprite:IsFinished("MineExplode") then
                    REVEL.game:BombExplosionEffects(fam.Position, 60, 0,
                                                    Color(1, 1, 1, 1,
                                                            conv255ToFloat(0,
                                                                            0,
                                                                            0)),
                                                    fam.Player, 0.75, true,
                                                    false)
                    Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 0,
                                fam.Position, Vector.Zero, fam)
                    REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.6, 0,
                                    false, 1.05)
                    fam:Remove()
                end
            end,
            DeathUpdate = function(fam)
                local sprite = fam:GetSprite()
                if sprite:IsFinished("Death") then
                    fam:GetData().RemoveOnNewRoom = true
                    sprite:Play("IdleMine", true)
                end
            end
        },
        corn = {
            Weight = 50,
            IfAny = {Items = {CollectibleType.COLLECTIBLE_EPIC_FETUS}},
            SpecialDeath = true,
            Update = function(fam)
                local sprite = fam:GetSprite()
                if sprite:IsFinished("Drop") then
                    REVEL.game:BombExplosionEffects(fam.Position, 60, 0,
                                                    Color(1, 1, 1, 1,
                                                            conv255ToFloat(0,
                                                                            0,
                                                                            0)),
                                                    fam.Player, 0.75, true,
                                                    false)
                    fam:Remove()
                end
            end,
            DeathUpdate = function(fam)
                local sprite = fam:GetSprite()
                if sprite:IsFinished("Death") then
                    sprite:Load(
                        "gfx/familiar/revelcommon/cabbage_patch/veggie/corn_missile.anm2",
                        true)
                    sprite:Play("Drop", true)
                    REVEL.SpawnDecoration(fam.Position, Vector.Zero,
                                            "LeavesIdle",
                                            "gfx/familiar/revelcommon/cabbage_patch/veggie/corn.anm2",
                                            nil, -1000)

                    if #REVEL.roomEnemies == 0 then
                        fam.Position = fam.Player.Position
                    else
                        fam.Position =
                            REVEL.roomEnemies[math.random(1,
                                                            #REVEL.roomEnemies)]
                                .Position
                    end
                end
            end
        },
        ussrpotato = {
            Weight = 40, -- IncreaseByCount includes itself, corn, and potato so it's actually 70 by default
            IncreaseByCount = 10,
            ExplosionColor = REVEL.CustomColor(183, 146, 104, 0.55),
            IfAll = {
                Items = {
                    CollectibleType.COLLECTIBLE_DR_FETUS,
                    CollectibleType.COLLECTIBLE_EPIC_FETUS
                }
            },
            SpawnAnimation = true,
            Death = function()
                for i = 1, 6 do
                    local pos = Isaac.GetFreeNearPosition(
                                    REVEL.room:GetGridPosition(
                                        REVEL.room:GetRandomTileIndex(
                                            math.random(
                                                REVEL.room:GetDecorationSeed()))),
                                    32)
                    local cabb = REVEL.ENT.CABBAGE:spawn(pos, Vector.Zero,
                                                            nil)
                    cabb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    local data = cabb:GetData()
                    data.CabbageType = "potato"
                    data.dead = true
                    data.RemoveOnNewRoom = true
                    local spr = cabb:GetSprite()
                    spr:Load(
                        "gfx/familiar/revelcommon/cabbage_patch/veggie/potato.anm2",
                        true)
                    spr:Play("SovietAirStrike", true)
                end
            end
        }
    }
}

function revel.cabbage.Update(e, data, spr)
    local stageUp = 0
    local owner

    if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or
        REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
        local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT,
                                            EffectVariant.BOMB_EXPLOSION,
                                            -1, false, false)
        for i, e2 in ipairs(explosions) do
            if e2.Position:DistanceSquared(e.Position) < 4000 then
                stageUp = stageUp + 1
                owner = REVEL.GetRandomPlayerWithItems(
                            CollectibleType.COLLECTIBLE_DR_FETUS,
                            CollectibleType.COLLECTIBLE_EPIC_FETUS)
                break
            end
        end
    end

    for i, t in ipairs(REVEL.roomTears) do
        local tdata = t:GetData()
        if t.Position:DistanceSquared(e.Position) < (20 + t.Size) ^ 2 then
            if t:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
                if data.stage + stageUp <= 4 and t.FrameCount % 5 == 0 then
                    stageUp = stageUp + 1
                    owner = tdata.__parent
                end

            elseif tdata.__player and not t:IsDead() then
                t:Die()
                if data.stage + stageUp <= 4 then
                    stageUp = stageUp + 1
                    owner = tdata.__parent
                end
            end
        end
    end

    for i, l in ipairs(REVEL.roomLasers) do
        if (l.Parent and l:GetLastParent().Type == 1) and
            REVEL.CollidesWithLaser(e.Position, l, 20) then
            if data.stage + stageUp <= 4 then
                stageUp = stageUp + 1
                owner = l:GetLastParent():ToPlayer()
                break
            end
        end
    end

    for i, e2 in ipairs(REVEL.roomKnives) do
        if e2.SpawnerType == 1 and e2:IsFlying() and
            e2.Position:DistanceSquared(e.Position) < (20 + e2.Size) ^ 2 then
            if data.stage + stageUp <= 4 then
                stageUp = stageUp + 1
                owner = e2.Parent:ToPlayer()
                break
            end
        end
    end

    data.stage = data.stage + stageUp
    if data.stage <= 4 then
        if not spr:IsPlaying("Lvl" .. data.stage) and
            not spr:IsFinished("Lvl" .. data.stage) and
            not spr:IsPlaying("Lvl" .. (data.stage - 1) .. "Grows") and
            not spr:IsFinished("Lvl" .. (data.stage - 1) .. "Grows") then
            spr:Play("Lvl" .. (data.stage - 1) .. "Grows")
        elseif spr:IsFinished("Lvl" .. (data.stage - 1) .. "Grows") then
            spr:Play("Lvl" .. data.stage, true)
        end
    else
        if not spr:IsPlaying("Lvl4Grows") and
            not spr:IsFinished("Lvl4Grows") then
            spr:Play("Lvl4Grows", true)
        elseif spr:IsFinished("Lvl4Grows") then
            owner = owner or REVEL.player
            local cabb = REVEL.ENT.CABBAGE:spawn(e.Position,
                                                    RandomVector() * 3, owner)
            cabb:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

            local cdata = revel.cabbage.types[data.cabbageType]
            local ndata = cabb:GetData()
            ndata.CabbageType = data.cabbageType
            if data.cabbageType ~= "cabbage" then
                local spr = cabb:GetSprite()

                spr:Load(
                    "gfx/familiar/revelcommon/cabbage_patch/veggie/" ..
                        data.cabbageType .. ".anm2", true)

                if cdata.SpawnAnimation then
                    if cdata.SpawnAnimation == true then
                        spr:Play("Spawn", true)
                    else
                        spr:Play(cdata.SpawnAnimation, true)
                    end
                else
                    spr:Play("Idle", true)
                end

                spr.PlaybackSpeed = cdata.PlaybackSpeed or 1

                if cdata.SpeedMult then
                    ndata.speed = revel.cabbage.spd * cdata.SpeedMult
                end

                ndata.ExplodeOnDeath = cdata.ExplodeOnDeath
            end

            local explosionColor = revel.cabbage.types[data.cabbageType]
                                        .ExplosionColor or
                                        Color(0.02, 0.5, 0.02, 0.55,
                                                conv255ToFloat(70, 134, 70))
            REVEL.game:BombExplosionEffects(e.Position, owner.Damage * 5, 0,
                                            explosionColor, owner, 0.55,
                                            true, false)

            e:Remove()
            return
        end
    end
end

local PlantDeco = {
    Anim = "Lvl1",
    Sprite = "set in function",
    Update = revel.cabbage.Update,
    RemoveOnAnimEnd = false
}

function REVEL.PlayerMeetsRequirements(player, tbl)
    if tbl.IfAny and not tbl.IfAll then
        return REVEL.PlayerMeetsRequirements(player, tbl.IfAny)
    elseif tbl.IfAll and not tbl.IfAny then
        local _, hasAll = REVEL.PlayerMeetsRequirements(player, tbl.IfAll)
        return hasAll
    elseif tbl.IfAny and tbl.IfAll then
        local hasAny, _ = REVEL.PlayerMeetsRequirements(player, tbl.IfAny)
        local _, hasAll = REVEL.PlayerMeetsRequirements(player, tbl.IfAll)
        return hasAny and hasAll
    end

    local hasAll = true
    local hasAny = false
    if tbl.Items then
        for _, item in ipairs(tbl.Items) do
            if player:HasCollectible(item) then
                hasAny = true
            else
                hasAll = false
            end
        end
    end

    if tbl.TearFlags then
        for _, tf in ipairs(tbl.TearFlags) do
            if HasBit(player.TearFlags, tf) then
                hasAny = true
            else
                hasAll = false
            end
        end
    end

    if tbl.Characters then
        for _, char in ipairs(tbl.Characters) do
            if player:GetPlayerType() == char then
                hasAny = true
            else
                hasAll = false
            end
        end
    end

    if not hasAny and hasAll then hasAll = false end

    return hasAny, hasAll
end

function REVEL.PickCabbageType(player, allTypes)
    local possibleTypes = {}
    local totalWeight = 0
    local totalCount = 0
    local increaseByCount = {}
    for ctype, ctable in pairs(revel.cabbage.types) do
        if (not ctable.IfAny and not ctable.IfAll) or
            REVEL.PlayerMeetsRequirements(player, ctable) or allTypes then
            totalWeight = totalWeight + ctable.Weight
            possibleTypes[#possibleTypes + 1] = {ctype, ctable.Weight}
            if ctable.IncreaseByCount then
                increaseByCount[#increaseByCount] = {ctype, #possibleTypes}
            end

            if not ctable.NoCount then
                totalCount = totalCount + 1
            end
        end
    end

    for _, ctype in ipairs(increaseByCount) do
        totalWeight = totalWeight +
                            revel.cabbage.types[ctype[1]].IncreaseByCount *
                            totalCount
        possibleTypes[ctype[2]][2] =
            possibleTypes[ctype[2]][2] +
                revel.cabbage.types[ctype[1]].IncreaseByCount * totalCount
    end

    return StageAPI.WeightedRNG(possibleTypes, nil, nil, totalWeight)
end

function REVEL.SpawnCabbagePatch(player) -- for use with lua command
    local pos = Isaac.GetFreeNearPosition(
                    REVEL.room:GetGridPosition(
                        REVEL.room:GetRandomTileIndex(math.random(
                                                            REVEL.room:GetDecorationSeed()))),
                    32)

    local cabbageType = REVEL.PickCabbageType(player or REVEL.player)

    PlantDeco.Sprite = "gfx/familiar/revelcommon/cabbage_patch/sprout/" ..
                            cabbageType .. ".anm2"
    local deco = REVEL.SpawnDecorationFromTable(pos, Vector.Zero, PlantDeco)
    deco:GetData().cabbageType = cabbageType
    deco:GetData().stage = 1
end

function REVEL.SpawnCabbageRandom(player) -- again, for lua command
    local pos = Isaac.GetFreeNearPosition(
                    REVEL.room:GetGridPosition(
                        REVEL.room:GetRandomTileIndex(math.random(
                                                            REVEL.room:GetDecorationSeed()))),
                    32)

    local cabbageType = REVEL.PickCabbageType(player or REVEL.player, true)

    PlantDeco.Sprite = "gfx/familiar/revelcommon/cabbage_patch/sprout/" ..
                            cabbageType .. ".anm2"
    local deco = REVEL.SpawnDecorationFromTable(pos, Vector.Zero, PlantDeco)
    deco:GetData().cabbageType = cabbageType
    deco:GetData().stage = 1
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    if REVEL.room:IsFirstVisit() and not StageAPI.InExtraRoom() then
        for _, player in ipairs(REVEL.players) do
            local cabbageCount = player:GetCollectibleNum(REVEL.ITEM
                                                                .CABBAGE_PATCH
                                                                .id)
            if cabbageCount > 0 and
                REVEL.ITEM.CABBAGE_PATCH:PlayerHasCollectible(player) then -- also check if the item isn't disabled by conditions with :PlayerHasCollectible
                for i = 1, cabbageCount do
                    REVEL.SpawnCabbagePatch(player)
                end
            end
        end

        for _, cabbage in ipairs(Isaac.FindByType(REVEL.ENT.CABBAGE.id,
                                                    REVEL.ENT.CABBAGE.variant,
                                                    -1, false, false)) do
            if cabbage:GetData().RemoveOnNewRoom or cabbage:GetData().dead then
                cabbage:Remove()
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, e)
    e.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
    local spr, data = e:GetSprite(), e:GetData()

    spr:Play("Hop", true)

    data.hp = revel.cabbage.maxHp
    data.rest = false
end, REVEL.ENT.CABBAGE.variant)

local volume = 0.3

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    local spr, data = e:GetSprite(), e:GetData()

    local cdata = revel.cabbage.types[data.CabbageType]
    local targ = REVEL.getClosestEnemy(e, false, true, true, true)
    local targPos = data.targPos

    if targ and not targPos then
        targPos = targ.Position + targ.Velocity
    elseif not targPos then
        targPos = e.Player.Position -- possibly replace with following position
    end
    --    if not data.isFollower then
    --      data.isFollower = true
    --      e:AddToFollowers()
    --    end

    if data.RemoveOnNewRoom or data.dead then
        if not data.CurrentRoom then
            data.CurrentRoom = REVEL.level:GetCurrentRoomIndex()
        end

        if REVEL.level:GetCurrentRoomIndex() ~= data.CurrentRoom then
            e:Remove()
        end
    end

    data.Damage = e.Player.Damage * 1.5 * (cdata.DamageMult or 1)

    data.CanHit = false

    data.NoHurt = false
    data.HurtMultiplier = nil

    if not spr:IsPlaying("Attack") then data.rest = false end

    if spr:IsPlaying("Attack") and not data.rest and not data.dead then
        data.CanHit = true
    end

    if cdata.Update then cdata.Update(e, targ, targPos) end

    if spr:IsPlaying("Spawn") or
        (cdata.SpawnAnimation and cdata.SpawnAnimation ~= true and
            spr:IsPlaying(cdata.SpawnAnimation)) then
        e.Velocity = Vector.Zero
    end

    if spr:IsPlaying("Death") or
        (spr:IsFinished("Death") and cdata.SpecialDeath) then
        if cdata.DeathUpdate then cdata.DeathUpdate(e) end
        e.Velocity = Vector.Zero
    elseif spr:IsFinished("Death") and not cdata.SpecialDeath then
        if cdata.Death then cdata.Death(e) end

        if data.ExplodeOnDeath then
            REVEL.game:BombExplosionEffects(e.Position, e.Player.Damage * 5,
                                            0, cdata.DeathExplosionColor or
                                                Color(0.5, 0.02, 0.02, 1,
                                                        conv255ToFloat(134,
                                                                        70, 70)),
                                            e, 0.75, true, true)
        end
        Isaac.Spawn(1000, EffectVariant.BLOOD_EXPLOSION, 0, e.Position,
                    Vector.Zero, e)

        REVEL.sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 0.6, 0, false, 1.05)
        e:Remove()
    elseif data.rest and not spr:IsPlaying("Attack") then
        if spr:IsFinished("Attack") then spr:Play("Idle", true) end
    elseif (spr:IsFinished("Attack") or spr:IsFinished("Idle") or
        spr:IsFinished("Hop") or
        (cdata.SpecialAttackAnim and spr:IsFinished(cdata.SpecialAttackAnim))) then
        data.targPos = nil

        local noNormal
        local canNormal =
            targ and targPos:DistanceSquared(e.Position) < 80 ^ 2 and
                REVEL.room:CheckLine(e.Position, targPos, 1, 1, false, false)
        if cdata.SelectAttack then
            noNormal = cdata.SelectAttack(e, targ, targPos, canNormal)
        end

        if not noNormal and canNormal then
            spr:Play("Attack", true)
            data.targPos = targPos
        end
    end

    if spr:IsPlaying("Attack") then
        if spr:IsEventTriggered("Hop") then
            REVEL.sfx:Play(SoundEffect.SOUND_CHILD_ANGRY_ROAR, 0.8, 0,
                            false, 1.1)
            e.Velocity = (targPos - e.Position) /
                                (cdata.HopLength or revel.cabbage.hopLength)
            data.targPos = nil
        elseif spr:WasEventTriggered("Land") then
            e.Velocity = Vector.Zero
        end
    elseif spr:IsFinished("Attack") or
        (cdata.SpecialAttackAnim and spr:IsFinished(cdata.SpecialAttackAnim)) then
        spr:Play("Idle", true)
    end

    if spr:IsFinished("Idle") or spr:IsFinished("Spawn") then
        if not data.pitFalling then
            spr:Play("Hop", true)
        else
            spr:Play("Idle", true)
        end
    end

    if spr:IsPlaying("Hop") or spr:IsFinished("Hop") then
        if spr:IsEventTriggered("Hop") then
            REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, volume, 0, false,
                            1.1)
            local pos

            if REVEL.room:CheckLine(e.Position, targPos, 1, 1, false, false) then
                pos = targPos
            elseif REVEL.room:GetGridCollisionAtPos(targPos) ~=
                GridCollisionClass.COLLISION_PIT then -- can pathfind through pits, not at pits
                local id, tid = REVEL.room:GetGridIndex(e.Position),
                                REVEL.room:GetGridIndex(targPos)
                local path = REVEL.GeneratePathAStar(id, tid, revel.cabbage
                                                            .collisions) -- check revel1_library
                if path then
                    pos = REVEL.room:GetGridPosition(path[1])
                end
            end

            if pos then
                e.Velocity = (pos - e.Position):Resized(data.speed or
                                                            revel.cabbage
                                                                .spd)
                                    :Rotated(math.random(15) - 7.5)
            else
                e.Velocity = RandomVector() *
                                    (data.speed or revel.cabbage.spd)
            end

        elseif spr:IsEventTriggered("Land") then
            REVEL.sfx:Play(SoundEffect.SOUND_ANIMAL_SQUISH, volume, 0,
                            false, 1.1)
        end

        if not spr:WasEventTriggered("Hop") or spr:WasEventTriggered("Land") then
            e.Velocity = Vector.Zero
        end

        if spr:IsFinished("Hop") then
            if math.random(2) == 1 then
                spr:Play("Idle", true)
                data.idleTimer = math.random(10)
            else
                spr:Play("Hop", true)
            end
        end
    elseif spr:IsPlaying("Idle") and not data.pitFalling then
        e.Velocity = Vector.Zero

        if data.idleTimer then
            data.idleTimer = data.idleTimer - 1
            if data.idleTimer <= 0 then
                data.idleTimer = nil
                spr:Play("Hop", true)
            end
        end
    end

    if data.CanHit then
        local closeEnms = Isaac.FindInRadius(e.Position,
                                                32 * (data.speed or 1),
                                                EntityPartition.ENEMY)
        for i, enm in ipairs(closeEnms) do
            if enm.Type ~= 33 and enm:IsVulnerableEnemy() and
                not enm:HasEntityFlags(EntityFlag.FLAG_NO_TARGET) and
                not enm:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and
                enm:IsActiveEnemy(false) and
                enm.Position:DistanceSquared(e.Position) <
                (e.Size + enm.Size) ^ 2 then
                enm:TakeDamage(data.Damage, 0, EntityRef(e), 5)
                data.rest = true
                if not data.NoHurt and enm.Type ~=
                    REVEL.COMP_ENTS.POTATO_FOR_SCALE.id then
                    data.hp = data.hp - 1 * (data.HurtMultiplier or 1)
                    if data.hp <= 0 then
                        spr:Play("Death")
                        data.dead = true
                    end
                end
            end
        end
    end

    local fams = Isaac.FindInRadius(e.Position, e.Velocity.X + e.Velocity.Y,
                                    EntityPartition.FAMILIAR)
    for i, fam in ipairs(fams) do
        if fam.InitSeed ~= e.InitSeed and fam.Variant ==
            REVEL.ENT.CABBAGE.variant then
            local dist = e.Position:Distance(fam.Position)
            if dist ~= 0 and dist < e.Size + fam.Size then
                local _, perpVel = REVEL.GetVectorComponents(e.Velocity,
                                                                (fam.Position -
                                                                    e.Position))
                e.Velocity = (e.Position - fam.Position):Resized(fam.Size /
                                                                        2) +
                                    perpVel
            elseif dist == 0 then
                e.Velocity = RandomVector() * fam.Size
            end
        end
    end
end, REVEL.ENT.CABBAGE.variant)

revel:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, function(_, fam, renderOffset)
    local data = fam:GetData()
    if revel.cabbage.types[data.CabbageType].Render then
        revel.cabbage.types[data.CabbageType].Render(fam, renderOffset)
    end
end, REVEL.ENT.CABBAGE.variant)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local cabbages = Isaac.FindByType(3, REVEL.ENT.CABBAGE.variant, -1,
                                        false, false)
    volume = REVEL.Lerp2Clamp(0.3, 0.1, #cabbages, 1, 10)
end)

end

REVEL.PcallWorkaroundBreakFunction()
