-- Library related to boss handling

local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function ()

REVEL.RuthlessMode = false -- for fun!

REVEL.BossDebug = REVEL.DEBUG
    

-- Attack name announcing (for fun and testing)
REVEL.AnnounceAttackNames = false
function REVEL.AnnounceAttack(name)
    if REVEL.AnnounceAttackNames and name ~= "" then
        StageAPI.PlayTextStreak({
            Text = name,
            Spritesheet = "stageapi/none.png",
            RenderPos = Vector(240, 238)
        })
    end
end

---------------
-- CHAMPIONS --
---------------

do
    local OldGlacierBossNames = {
      ["Frost Rider"] = "FrostRider",
      ["Duke of Flakes"] = "Duke",
      ["Freezer Burn"] = "FreezerBurn"
    }


    -- LayoutFilter contains a filter for the boss affected by the achievements, to be used with StageAPI.DoesLayoutContainEntities
    ---@type table<string, {Name: string, Bosses: table, LayoutFilter: EntityDef[]}>
    local champAchievements = {
        Glacier = { Name = "GLACIER_CHAMPIONS", Bosses = REVEL.copy(REVEL.Bosses.ChapterOne) },
        Tomb    = { Name = "TOMB_CHAMPIONS",    Bosses = REVEL.copy(REVEL.Bosses.ChapterTwo) }
    }

    for _, boss in ipairs(REVEL.Bosses.Common) do
        for _, achieve in pairs(champAchievements) do
            if boss.ChampionAchievement == achieve.Name then
                achieve.Bosses[#achieve.Bosses + 1] = boss
            end
        end
    end

    for _, champAchievement in pairs(champAchievements) do
        champAchievement.Bosses = REVEL.filter(champAchievement.Bosses, function(boss) return not boss.IsMiniboss end)
        champAchievement.LayoutFilter = REVEL.map(champAchievement.Bosses, function(boss)
            return { Type = boss.Entity.Type, Variant = boss.Entity.Variant, SubType = boss.Entity.SubType }
        end)
    end

    revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
        if not REVEL.IsSaveDataLoaded() or REVEL.game:IsPaused() or e.Type == 1000 then
            return
        end

        if not (e:ToNPC() and e:ToNPC():IsBoss()) then
            return
        end

        for _, champAchievement in pairs(champAchievements) do

            if not REVEL.IsAchievementUnlocked(champAchievement.Name) then
                local unbeatenBosses = false
                for i, boss in ipairs(champAchievement.Bosses) do
                    local name = boss.Name
                    local ent = boss.DeathTriggerEntity or boss.Entity
                    local isChapterBoss = StageAPI.DoesEntityDataMatchParameters(ent, e)
                    revel.data.BossesBeaten[name] = revel.data.BossesBeaten[name] or isChapterBoss
                    -- REVEL.DebugToConsole(name, isChapterBoss, e.Type, e.Variant )

                    if not (revel.data.BossesBeaten[name]) then
                        unbeatenBosses = true
                    end

                    -- REVEL.DebugToConsole(isChapterBoss, boss.Name, name, revel.data.BossesBeaten[name])
                end

                if not unbeatenBosses then
                    REVEL.UnlockAchievement(champAchievement.Name)
                end
            end

        end
    end)

    local forceChampionState = nil

    REVEL.ForceNextChampion = nil
    REVEL.ForceNextRuthless = nil
    
    StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_CHECK_VALID_ROOM, 10, function(layout) -- high priority because it should run later to stop rooms from spawning
        local championizers = StageAPI.CountLayoutEntities(layout, {{Type = 789, Variant = 91}})
        local noChampions = StageAPI.CountLayoutEntities(layout, {{Type = 789, Variant = 92}})
        if championizers == 0 and noChampions == 0 then return end

        local fcs = nil
        if REVEL.ForceNextChampion ~= nil or REVEL.ForceNextRuthless ~= nil then
            fcs = REVEL.ForceNextChampion == true or REVEL.ForceNextRuthless == true
        elseif type(forceChampionState) == "boolean" then
            fcs = forceChampionState
        end

        if fcs == true and noChampions > 0 then
            return false
        elseif fcs == false and championizers > 0 then
            return false
        end

        for stage, champAchievement in pairs(champAchievements) do
            if noChampions > 0 and REVEL.STAGE[stage]:IsStage() 
            and revel.data.run.madeAMistake[REVEL.GetStageChapter(REVEL.STAGE[stage])] then
                return false
            end

            if not REVEL.IsAchievementUnlocked(champAchievement.Name)
            and championizers > 0 then
                local champBosses = StageAPI.CountLayoutEntities(layout, champAchievement.LayoutFilter)
                if champBosses > 0 then
                    return false
                end
            end
        end
    end)

    REVEL.Commands.forcechampionstate = {
        Execute = function (params)
    		if params == "yes" or params == "true" or params == "on" then
    			forceChampionState = true
    			print("Champions will now always appear")
    		elseif params == "no" or params == "false" or params == "off" then
    			forceChampionState = false
    			print("Champions will now never appear")
    		else
    			forceChampionState = nil
    			print("Cleared force champion state")
    		end
        end,
        Autocomplete = function (params)
            return {"yes", "true", "on", "no", "false", "off"}
        end,
        Aliases = {"fcs"},
        Usage = "[<yes|true|on|no|false|off>]",
        Desc = "Force rev champion boss spawning",
        Help = "yes|true|on: Always spawn rev bosses as champions\nno|false|off: Never spawn rev bosses as champions\n[blank]: Reset to normal behavior",
        File = "revelcommon/bosses/init.lua",
    }

    revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd, params)
    	if cmd == "forcechampionstate" or cmd == "fcs" then
    	end
    end)

    function REVEL.IsChampion(npc)
        if not npc then return false end

        if REVEL.GetData(npc).IsChampion ~= nil then return REVEL.GetData(npc).IsChampion end

        if REVEL.ForceNextChampion ~= nil then
            local val = REVEL.ForceNextChampion
            REVEL.ForceNextChampion = nil
            return val
        end

        if type(forceChampionState) == "boolean" then
            return forceChampionState
        end

        -- force champion state if using a meta entity
        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            local index = REVEL.room:GetGridIndex(npc.Position)
            if currentRoom.Metadata:Has{Index = index, Name = "Championizer"} then
                return true
            elseif currentRoom.Metadata:Has{Index = index, Name = "NoChampion"} then
                return false
            end
        end

        for stage, champAchievement in pairs(champAchievements) do
            if REVEL.IsAchievementUnlocked(champAchievement.Name)
            and REVEL.some(champAchievement.LayoutFilter, function(param)
                return StageAPI.DoesEntityDataMatchParameters(param, npc)
            end) then
                local chance = REVEL.GetRevBossChampionChance()

                local rng = REVEL.RNG()
                rng:SetSeed(npc.InitSeed, 38)
                return rng:RandomFloat() < chance
            end
        end

        return false
    end

    function REVEL.IsRuthless()
        if REVEL.ForceNextRuthless then
            REVEL.ForceNextRuthless = nil
            return true
        end

        return REVEL.RuthlessMode
    end
end

----------------
-- HP SCALING --
----------------

do
    ---@class __HPScalingBalance # just to make autocomplete work
    ---@field ItemPowerModifier RevItemPowerModifier[]
    REVEL.HPScalingBalance = {
        -- Item Power Modifier, a multiplier on DPS
        ItemPowerModifier = { -- Iterated through in order, adding to a variable that DPS is multiplied by at the end
            {Collectible = CollectibleType.COLLECTIBLE_GODHEAD, Multi = .5, OnlyWeapons = {WeaponType.WEAPON_TEARS, WeaponType.WEAPON_MONSTROS_LUNGS, WeaponType.WEAPON_LUDOVICO_TECHNIQUE}, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_CHOCOLATE_MILK, Multi = .25, OnlyWeapons = {WeaponType.WEAPON_TEARS}, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_HAEMOLACRIA, Multi = .5, OnlyWeapons = {WeaponType.WEAPON_TEARS}, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_LACHRYPHAGY, Multi = .15, OnlyWeapons = {WeaponType.WEAPON_TEARS}, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_SUCCUBUS, Multi = .2, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_STYE, Multi = .05, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_PEEPER, Multi = .05, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_HOLY_LIGHT, Multi = .15, AntiTags = {"BlockRevGeneral"}, Priority = 0},
            {Collectible = CollectibleType.COLLECTIBLE_BLOOD_CLOT, Add = 0.5, AntiTags = {"BlockRevGeneral"}, Priority = 5},
            {Collectible = CollectibleType.COLLECTIBLE_CHEMICAL_PEEL, Add = 1, AntiTags = {"BlockRevGeneral"}, Priority = 5},

            -- Poison Damage
            {Collectible = CollectibleType.COLLECTIBLE_IPECAC, Multi = .2, Tag = "Poison", AntiTags = {"BlockRevPoison"}, Priority = 10},
            {Collectible = CollectibleType.COLLECTIBLE_SERPENTS_KISS, Multi = .15, Tag = "Poison", AntiTags = {"Poison", "BlockRevPoison"}, Priority = 11},
            {Collectible = CollectibleType.COLLECTIBLE_SCORPIO, Multi = .33, Tag = "Poison", AntiTags = {"Poison", "BlockRevPoison"}, Priority = 12},
            {Collectible = CollectibleType.COLLECTIBLE_COMMON_COLD, Multi = .15, Tag = "Poison", AntiTags = {"Poison", "BlockRevPoison"}, Priority = 13},

            -- Extra Tear Items
            {Collectible = CollectibleType.COLLECTIBLE_LEAD_PENCIL, Multi = 1.05, MultiplyMulti = true, AntiWeapons = {WeaponType.WEAPON_KNIFE}, Stacks = "ExtraTear", AntiTags = {"BlockRevExtraTear"}, Priority = 20},
            {Collectible = CollectibleType.COLLECTIBLE_MONSTROS_LUNG, Multi = 4, MultiplyMulti = true, AntiWeapons = {WeaponType.WEAPON_KNIFE}, Stacks = "ExtraTear", AntiTags = {"BlockRevExtraTear"}, Priority = 20},
            {Collectible = CollectibleType.COLLECTIBLE_20_20, MultiPerItem = 1.5, MultiplyMulti = true, Stacks = "ExtraTear", AntiTags = {"BlockRevExtraTear"}, Priority = 20},
            {Collectible = CollectibleType.COLLECTIBLE_MUTANT_SPIDER, MultiPerItem = 3, MultiplyMulti = true, Stacks = "ExtraTear", AntiTags = {"BlockRevExtraTear"}, Priority = 20},
            {Collectible = CollectibleType.COLLECTIBLE_INNER_EYE, MultiPerItem = 2.5, MultiplyMulti = true, Stacks = "ExtraTear", AntiTags = {"BlockRevExtraTear"}, Priority = 20},

            {Collectible = CollectibleType.COLLECTIBLE_INCUBUS, Multi = .75, MultiPerItem = .75, MultiplyMulti = true, AntiTags = {"BlockRevIncubus"}, Priority = 25},
            {Collectible = CollectibleType.COLLECTIBLE_TWISTED_PAIR, Multi = .75, MultiPerItem = .75, MultiplyMulti = true, AntiTags = {"BlockRevIncubus"}, Priority = 25},

            -- Extra Damage that does not scale with more tears
            {Collectible = CollectibleType.COLLECTIBLE_TECH_5, Multi = .33, AntiTags = {"BlockRevGeneral"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_TECHNOLOGY_2, Multi = .25, AntiTags = {"BlockRevGeneral"}, Priority = 30},

            -- Special character effects
            {OnlyCharacters = {PlayerType.PLAYER_MAGDALENA_B}, Add = function(player)
                -- about 9 frames delay between slaps
                local slapDPS = player.Damage * 6 * 30 / 9
                return slapDPS * 0.2
            end, Priority = 35},
            {OnlyCharacters = {PlayerType.PLAYER_AZAZEL_B}, Multi = 0.35, Priority = 35},

            -- Familiars
            {Collectible = CollectibleType.COLLECTIBLE_ROTTEN_BABY, Multi = .4, AntiTags = {"BlockRevFamiliars"}, Priority = 30}, -- scales w/ player damage
            {Collectible = CollectibleType.COLLECTIBLE_FATES_REWARD, Multi = .25, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_PAPA_FLY, Multi = .25, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_LIL_BRIMSTONE, Add = 10, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_LIL_ABADDON, Add = 7, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_BROTHER_BOBBY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_SISTER_MAGGY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_FREEZER_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_MONGO_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_ROBO_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_ROBO_BABY_2, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_GHOST_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_HARLEQUIN_BABY, Add = 2, AntiTags = {"BlockRevFamiliars"}, Priority = 30}, -- shots deal 4 damage per second, but hard to aim
            {Collectible = CollectibleType.COLLECTIBLE_SERAPHIM, Add = 10, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_LITTLE_STEVEN, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_LIL_LOKI, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_RAINBOW_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_LIL_MONSTRO, Add = 10, AntiTags = {"BlockRevFamiliars"}, Priority = 30},
            {Collectible = CollectibleType.COLLECTIBLE_DEMON_BABY, Add = 3.5, AntiTags = {"BlockRevFamiliars"}, Priority = 30}, -- shots deal 3 damage, shoots 3 times per second but misses a lot
            {Collectible = CollectibleType.COLLECTIBLE_LIL_DELIRIUM, Add = 4, AntiTags = {"BlockRevFamiliars"}, Priority = 30},

            -- Multipliers on all damage dealt come last.
            -- (lazy load functions as file is defined later)
            {Multi = 1.65, MultiplyMulti = true, Tag = "CharonMerged", AntiTags = {"BlockRevCharon"}, OnlyIf = function() return {REVEL.Dante.IsMerged} end, Priority = 100},
            {Multi = 2.5, MultiplyMulti = true, AntiTags = {"CharonMerged", "BlockRevCharon"}, OnlyIf = function() return {REVEL.Dante.IsDante} end, Priority = 101},
        },

        -- Bomb / Orbital Damage (Deals damage based on a percentage of damage the boss is expected to take per second. For instance, bombs here would deal 10 seconds worth of damage to the boss.)
        BombMaxDamage = 12,
        BombMinDamage = 6,
        BombTapering = 0.75, -- bomb damage is multiplied by this for each bomb used, until it reaches BombMinDamage.
        OrbitalMaxDamage = 0.15,
        OrbitalDamageDivide = 4, -- orbital damage is divided by this, then multiplied by OrbitalMaxDamage
        ScaledOrbitals = { -- some have special damage rules
            [FamiliarVariant.SACRIFICIAL_DAGGER] = true, -- 15 Damage / Frame Base Game

            [FamiliarVariant.BALL_OF_BANDAGES_1] = true, -- 7 Damage / Frame Base Game
            [FamiliarVariant.BALL_OF_BANDAGES_2] = true,
            [FamiliarVariant.CUBE_OF_MEAT_1] = true,
            [FamiliarVariant.CUBE_OF_MEAT_2] = true,
            [FamiliarVariant.LOST_FLY] = true,
            [FamiliarVariant.SWORN_PROTECTOR] = true,

            [FamiliarVariant.DISTANT_ADMIRATION] = true, -- 5 Damage / Frame Base Game
            [FamiliarVariant.BEST_BUD] = true,

            [FamiliarVariant.FRIEND_ZONE] = true, -- 3 Damage / Frame Base Game

            [FamiliarVariant.FOREVER_ALONE] = true, -- 2 Damage / Frame Base Game
            [FamiliarVariant.BIG_FAN] = true,
            [FamiliarVariant.BLOODSHOT_EYE] = true,
            [FamiliarVariant.ANGRY_FLY] = true,

            [FamiliarVariant.SMART_FLY] = true, -- 1.5 Damage / Frame Base Game
            [FamiliarVariant.MOMS_RAZOR] = 0.04, -- technically deals 20% player damage

            -- SPECIAL CASES (NON-ORBITAL)
            [FamiliarVariant.BLUEBABYS_ONLY_FRIEND] = true, -- 2.5 damage / frame base game
            [FamiliarVariant.CUBE_OF_MEAT_3] = true, -- 3.5 damage / frame base game
            [FamiliarVariant.CUBE_OF_MEAT_4] = true, -- 5.5 damage / frame base game
            [FamiliarVariant.BALL_OF_BANDAGES_3] = true, -- 3.5 damage / frame base game
            [FamiliarVariant.BALL_OF_BANDAGES_4] = true, -- 5.5 damage / frame base game
            [FamiliarVariant.ISAACS_BODY] = true, -- 5.5 damage / frame base game
            [FamiliarVariant.DADDY_LONGLEGS] = 1.5,
            [FamiliarVariant.BOBS_BRAIN] = 3,
            [FamiliarVariant.BBF] = 3,
            [FamiliarVariant.ABYSS_LOCUST] = function()
                local countLocusts = Isaac.CountEntities(nil,EntityType.ENTITY_FAMILIAR,FamiliarVariant.ABYSS_LOCUST,-1)
                return (0.5
                    / math.max(1,countLocusts)) + (countLocusts*REVEL.HPScalingBalance.AbyssLocustIncrement)
            end,
        },

        -- Fight time is reduced for characters that are harder to play
        CharacterDifficultyCompensation = {
            [PlayerType.PLAYER_THELOST] = 1.25,
            [PlayerType.PLAYER_KEEPER_B] = 1.25,
            [PlayerType.PLAYER_THELOST_B] = 1.5,
        },

        -- Estimation Balance

        --[[

        Brimstone
        Deals player Damage each frame the laser is active
        Laser lasts 12-13 frames at random, but can be cut short by pressing shoot.
        Laser can be shot every MaxFireDelay frames, but charging it while the laser is active will result in cancelling the current laser, so optimal play adds the laser's duration to MaxFireDelay

        ]]

        BrimstoneDuration = { -- Since the laser can randomly last 9 or 10 frames, or be cancelled early by the player. We should estimate High for fireDelay purposes, and estimate Low for damage frames, so that it's lenient to the player.
            High = 10,
            Low = 7
        },
        BrimstoneFireDelayAdd = 10, -- it takes some time to react to the laser fading and press the button again, so let's give the player some leniency there

        --[[

        Mom's Knife
        Deals 2x player Damage each frame when not thrown
        When thrown, damage is equal to Lerp(2x Damage, 6x Damage, KnifePlayerDistance / KnifeMaxRange) per frame, capped at both ends.
        Must be held for MaxFireDelay frames to be thrown, much more to get higher range.
        Usually hits enemies 3-4 times when thrown, more often the larger the enemy.

        ]]

        KnifeDamageMulti = 4 * 3, -- halfway between min and max when thrown x times each enemy is hit low end
        KnifeFireDelayAdd = 15, -- longest throws have the knife in the air for about a second, so this is halfway between min and max throw time.

        --[[

        The Bone
        Deals 3x player damage each time it is swung
        Deals 1.5x player damage twice per enemy hit when thrown
        Swings are exactly MaxFireDelay apart
        Throws require holding the fire key for at least MaxFireDelay time after a Swing, for minimum distance

        Since it cannot be held down, we should add some flat FireDelay to make it fair to players that can't magically hit the fire button on the dot every time.

        ]]

        BoneFireDelayMulti = 2, -- before add, considering to throw it you need to hold the button down for twice firedelay i think this is fair
        BoneFireDelayAdd = 3,
        BoneDamageMulti = 3,

        --[[
        Notched Axe
        Deals 3x player damage each time it is swung
        Swings are exactly MaxFireDelay apart

        Since it cannot be held down, we should add some flat FireDelay to make it fair to players that can't magically hit the fire button on the dot every time.
        ]]

        NotchedAxeDelayAdd = 3,
        NotchedAxeDamageMulti = 3,

        --[[
        Spirit Sword
        Deals 3x player damage + 3.5 each time it is swung
            Swings *do not have a minimum delay*
        Shoots projectile with damage +2 Damage when swung at
        full health
            This happens with minimum delay of MaxFireDelay * 2
        Spin deals 8xdamage + 10, and reflects projectiles with
        4x damage + 4
            Spin cooldown is MaxFireDelay * 4
        ]]

        SpiritSwordSwingRate = 10, -- arbitrary, considering an average-ish number of buttom mashes
        SpiritSwordProjectileDelayMulti = 2,
        SpiritSwordSpinDelayMulti = 4,
        SpiritSwordSpinDelayAdd = 5, -- to account for not being able to be frame-perfect in holding down
        SpiritSwordDamageMulti = 3,
        SpiritSwordDamageAdd = 3.5,
        SpiritSwordProjectileDamageMulti = 1,
        SpiritSwordProjectileDamageAdd = 2,
        SpiritSwordSpinDamageMulti = 8,
        SpiritSwordSpinDamageAdd = 10,
        SpiritSwordSpinReflectDamageMulti = 4, -- won't be impactful on dps calc, but still nice to have
        SpiritSwordSpinReflectDamageAdd = 4,

        --[[

        Dr. Fetus
        Deals (5x Damage) + 30 Damage per bomb explosion
        Easily hurts the player when multiple bombs are fired at the same spot, due to flinging bombs backward

        ]]

        DrFetusDamageMultiplier = 5,
        DrFetusDamageAdd = 30,
        DrFetusSafeFireDelay = 35, -- since you will sometimes not want to hold down the shoot button below this firedelay
        DrFetusFireDelayLerp = 0.75,

        --[[

        Epic Fetus
        Deals 20x Damage per explosion
        Target exists for 40 frames before spawning the rocket, but the rocket takes 10 frames to land and cause an explosion
        FireDelay only counts down once the rocket from the last firing is gone

        ]]

        EpicFetusFireDelayAdd = 60, -- the time the target and rocket exist and thus firedelay is not counting down + some extra reaction time frames since you usually won't be holding down the fire button once you've already got the target over an enemy
        EpicFetusDamageMultiplier = 20,

        --[[

        Tech X
        Deals player Damage each frame to enemies in contact with the laser (usually about 5 times)
        Must be charged at least MaxFireDelay frames

        ]]

        TechXFireDelayAdd = 10,
        TechXDamageMultiplier = 3,

        --[[

        Gello

        ]]

        GelloWhipFireDelayMulti = 2, -- from testing seems to be this
        GelloWhipFireDelayAdd = 3, -- leniency for no frame perfection since it cannot be held down
        GelloFireDelayMulti = 1,
        GelloWhipDamageMulti = 3,
        GelloDamageMulti = 1,

        --[[

        C-Section

        ]]

        CSectionFireDelayAdd = 10,
        CSectionDamageMultiplier = 5,

        --[[

        Abyss

        ]]

        AbyssLocustIncrement = 0.02,
    }

    local EstimateDPSSpiritSword
    local EstimateDPSUmbilicalWhip

    ---@param player EntityPlayer
    ---@return number
    function REVEL.EstimateDPS(player)
        local altDPS = StageAPI.CallCallbacks(RevCallbacks.PRE_ESTIMATE_DPS, true, player)
        if altDPS then
            return altDPS
        end

        local fireDelay = player.MaxFireDelay + 1

        -- special dps calculation for some items due to 
        -- different attack types with different damage&speed
        if player:HasWeaponType(WeaponType.WEAPON_SPIRIT_SWORD) then
            return EstimateDPSSpiritSword(player, fireDelay)
        elseif player:GetPlayerType() == PlayerType.PLAYER_LILITH_B then -- weapon type doesn't seem to work
        -- elseif player:HasWeaponType(WeaponType.WEAPON_UMBILICAL_WHIP) then
            return EstimateDPSUmbilicalWhip(player, fireDelay)
        end

        if player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
            fireDelay = fireDelay + REVEL.HPScalingBalance.BrimstoneDuration.High + REVEL.HPScalingBalance.BrimstoneFireDelayAdd
        elseif player:HasWeaponType(WeaponType.WEAPON_ROCKETS) then
            fireDelay = fireDelay + REVEL.HPScalingBalance.EpicFetusFireDelayAdd -- time target exists
        elseif player:HasWeaponType(WeaponType.WEAPON_BOMBS) and fireDelay < REVEL.HPScalingBalance.DrFetusSafeFireDelay then
            fireDelay = REVEL.Lerp(fireDelay, REVEL.HPScalingBalance.DrFetusSafeFireDelay, REVEL.HPScalingBalance.DrFetusFireDelayLerp)
        elseif player:HasWeaponType(WeaponType.WEAPON_BONE) then
            local swingRate = fireDelay + REVEL.HPScalingBalance.BoneFireDelayAdd
            local throwRate = (fireDelay * REVEL.HPScalingBalance.BoneFireDelayMulti) + REVEL.HPScalingBalance.BoneFireDelayAdd
            fireDelay = REVEL.Lerp(throwRate, swingRate, 0.666)
        elseif player:HasWeaponType(WeaponType.WEAPON_NOTCHED_AXE) then
            local swingRate = fireDelay + REVEL.HPScalingBalance.NotchedAxeDelayAdd
            fireDelay = swingRate
        elseif player:HasWeaponType(WeaponType.WEAPON_KNIFE) then
            fireDelay = fireDelay + REVEL.HPScalingBalance.KnifeFireDelayAdd
        elseif player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            fireDelay = fireDelay + REVEL.HPScalingBalance.TechXFireDelayAdd
        elseif player:HasWeaponType(WeaponType.WEAPON_FETUS) then
            fireDelay = fireDelay + REVEL.HPScalingBalance.CSectionFireDelayAdd
        end

        local firePerSecond = 30 / fireDelay
        if player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
            return (player.Damage * REVEL.HPScalingBalance.BrimstoneDuration.Low * firePerSecond)
        elseif player:HasWeaponType(WeaponType.WEAPON_KNIFE) then
            return player.Damage * REVEL.HPScalingBalance.KnifeDamageMulti * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_ROCKETS) then
            return player.Damage * REVEL.HPScalingBalance.EpicFetusDamageMultiplier * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
            return ((player.Damage * REVEL.HPScalingBalance.DrFetusDamageMultiplier) + REVEL.HPScalingBalance.DrFetusDamageAdd) * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_BONE) then
            return player.Damage * REVEL.HPScalingBalance.BoneDamageMulti * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_NOTCHED_AXE) then
            return player.Damage * REVEL.HPScalingBalance.NotchedAxeDamageMulti * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            return player.Damage * REVEL.HPScalingBalance.TechXDamageMultiplier * firePerSecond
        elseif player:HasWeaponType(WeaponType.WEAPON_FETUS) then
            return player.Damage * REVEL.HPScalingBalance.CSectionDamageMultiplier * firePerSecond
        else
            return player.Damage * firePerSecond
        end
    end

    function EstimateDPSSpiritSword(player, fireDelay)
        local swingRate = REVEL.HPScalingBalance.SpiritSwordSwingRate
        local fireRate = fireDelay
            * REVEL.HPScalingBalance.SpiritSwordProjectileDelayMulti
        local spinRate = fireDelay * REVEL.HPScalingBalance.SpiritSwordSpinDelayMulti
            + REVEL.HPScalingBalance.SpiritSwordSpinDelayAdd
        -- Reflections should barely affect dps
        local reflectRate = spinRate

        local swingPerSecond = 30 / swingRate
        local firePerSecond = 30 / fireRate
        -- if player has no red hearts, then consider projectile to always shoot
        -- else 15%: consider player to be at max HP for this amount of time
        -- on average, cannot use HP as they vary and this needs to be
        -- calculated once per bossfight
        if player:GetMaxHearts() ~= 0 then
            firePerSecond = firePerSecond * 0.15
        end

        local spinPerSecond = 30 / fireRate
        local reflectPerSecond = 30 / reflectRate

        local reflectAffectPct = 0.05

        local swingDps = swingPerSecond * player.Damage * REVEL.HPScalingBalance.SpiritSwordDamageMulti
            + REVEL.HPScalingBalance.SpiritSwordDamageAdd
        local fireDps = firePerSecond * player.Damage * REVEL.HPScalingBalance.SpiritSwordProjectileDamageMulti
            + REVEL.HPScalingBalance.SpiritSwordProjectileDamageAdd
        local spinDps = spinPerSecond * player.Damage * REVEL.HPScalingBalance.SpiritSwordSpinDamageMulti
            + REVEL.HPScalingBalance.SpiritSwordSpinDamageAdd
            + (
                reflectPerSecond * player.Damage * REVEL.HPScalingBalance.SpiritSwordSpinReflectDamageMulti
                + REVEL.HPScalingBalance.SpiritSwordSpinReflectDamageAdd
            ) * reflectAffectPct

        return REVEL.Lerp(swingDps + fireDps, spinDps, 0.25)
    end

    function EstimateDPSUmbilicalWhip(player, fireDelay)
        local shootRate = fireDelay * REVEL.HPScalingBalance.GelloFireDelayMulti
        local whipRate = fireDelay * REVEL.HPScalingBalance.GelloWhipFireDelayMulti
            + REVEL.HPScalingBalance.GelloWhipFireDelayAdd

        local shootPerSecond = 30 / shootRate
        local whipPerSecond = 30 / whipRate

        local shootDps = shootPerSecond * player.Damage * REVEL.HPScalingBalance.GelloDamageMulti
        local whipDps = whipPerSecond * (
            player.Damage * REVEL.HPScalingBalance.GelloWhipDamageMulti --whip damage
            + player.Damage -- tear shooting damage
        )

        -- Assume most damage is coming from whips,
        -- spamming shoot will also make gello shoot
        return whipDps * 0.9 + shootDps * 0.4
    end

    local function getAveragePowerForFloorCount(floorCount) -- PLACEHOLDER, should probably use a lookup table or something.
        return 10 + floorCount * 2.5
    end

    ---@class RevItemPowerModifier
    ---@field Add number | fun(player: EntityPlayer): number
    ---@field Multi number | fun(player: EntityPlayer): number
    ---@field MultiPerItem number
    ---@field Priority integer
    ---@field Collectible CollectibleType
    ---@field OnlyWeapons WeaponType[]
    ---@field OnlyCharacters PlayerType[]
    ---@field OnlyIf table<fun(player: EntityPlayer): boolean> | fun(): table<fun(player: EntityPlayer): boolean>
    ---@field OnlyTags any[]
    ---@field AntiWeapons WeaponType[]
    ---@field AntiCharacters PlayerType[]
    ---@field AntiIf table<fun(player: EntityPlayer): boolean> | fun(): table<fun(player: EntityPlayer): boolean>
    ---@field AntiTags any[]
    ---@field Tag any
    ---@field Stacks any
    ---@field MultiplyMulti boolean
    ---@field private Resolved boolean
    ---@field private WasEffectiveLast boolean

    ---@param player EntityPlayer
    ---@param val number | fun(player: EntityPlayer): number
    ---@return number
    local function getVal(player, val)
        if type(val) == "function" then
            return val(player)
        else
            return val
        end
    end

    ---@param player EntityPlayer
    ---@param orderedMods table<integer, RevItemPowerModifier>
    ---@param modifier number
    ---@param add number
    ---@param tags any[]
    ---@param noStacking? boolean
    function REVEL.ResolveItemModifierStack(player, orderedMods, modifier, add, tags, noStacking) -- assumes already prioritized
        for _, item in ipairs(orderedMods) do
            if not item.Resolved then
                local effective = true
                local numHeld = 1
                if item.Collectible then
                    numHeld = player:GetCollectibleNum(item.Collectible)
					if item.Collectible == CollectibleType.COLLECTIBLE_INNER_EYE and player:GetPlayerType() == PlayerType.PLAYER_KEEPER then
						numHeld = numHeld + 1
					end
					if item.Collectible == CollectibleType.COLLECTIBLE_MUTANT_SPIDER and player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
						numHeld = numHeld + 1
					end
                    if item.Collectible == CollectibleType.COLLECTIBLE_INCUBUS and player:GetPlayerType() == PlayerType.PLAYER_LILITH then
						numHeld = math.max(0,numHeld - 1)
					end
                    if numHeld == 0 then
                        effective = false
                    end
                end

                if item.OnlyWeapons and effective then
                    effective = false
                    for _, weapon in ipairs(item.OnlyWeapons) do
                        if player:HasWeaponType(weapon) then
                            effective = true
                        end
                    end
                end

                if item.OnlyCharacters and effective then
                    effective = false
                    for _, ptype in ipairs(item.OnlyCharacters) do
                        if player:GetPlayerType() == ptype then
                            effective = true
                            break
                        end
                    end
                end

                if item.OnlyIf and effective then
                    if type(item.OnlyIf) == "function" then
                        item.OnlyIf = item.OnlyIf()
                    end

                    effective = false
                    for _, func in ipairs(item.OnlyIf) do
                        if func(player) then
                            effective = true
                            break
                        end
                    end
                end

                if item.OnlyTags and effective then
                    effective = false
                    for _, tag in ipairs(item.OnlyTags) do
                        if tags[tag] then
                            effective = true
                            break
                        end
                    end
                end

                if item.AntiWeapons and effective then
                    for _, weapon in ipairs(item.AntiWeapons) do
                        if player:HasWeaponType(weapon) then
                            effective = false
                        end
                    end
                end

                if item.AntiCharacters and effective then
                    for _, ptype in ipairs(item.AntiCharacters) do
                        if player:GetPlayerType() == ptype then
                            effective = false
                            break
                        end
                    end
                end

                if item.AntiIf and effective then
                    if type(item.AntiIf) == "function" then
                        item.AntiIf = item.AntiIf()
                    end

                    for _, func in ipairs(item.AntiIf) do
                        if func(player) then
                            effective = false
                            break
                        end
                    end
                end

                if item.AntiTags and effective then -- NOTE that the effective tag system only works for previously applied tags. You cannot have something ineffective if something ahead of it is effective, so set priority right!
                    for _, tag in ipairs(item.AntiTags) do
                        if tags[tag] then
                            effective = false
                        end
                    end
                end

                if effective then
                    if item.Tag then
                        tags[item.Tag] = true
                    end

                    if item.Stacks and not noStacking then
                        local stacksWith = {}
                        for _, mod2 in ipairs(orderedMods) do
                            if mod2.Stacks == item.Stacks then
                                stacksWith[#stacksWith + 1] = mod2
                            end
                        end

                        local stackMulti, stackAdd = REVEL.ResolveItemModifierStack(player, stacksWith, 0, 0, tags, true)
                        if item.MultiplyMulti then
                            modifier = modifier * stackMulti
                            add = add * stackMulti
                        else
                            modifier = modifier + stackMulti
                        end

                        add = add + stackAdd
                    else
                        item.WasEffectiveLast = effective
                        item.Resolved = true

                        local itemModifier = getVal(player, item.Multi) or 0
                        add = add + (getVal(player, item.Add) or 0)
                        if item.MultiPerItem then
                            itemModifier = itemModifier + item.MultiPerItem * numHeld
                        end

                        if item.MultiplyMulti and not item.Stacks then -- MultiplyMulti is resolved differently for stacking items, so that they don't multiply eachother
                            modifier = modifier * itemModifier
                            add = add * itemModifier
                        else
                            modifier = modifier + itemModifier
                        end
                    end
                end
            end
        end

        return modifier, add
    end

    function REVEL.GetItemPowerModifier(player)
        local modifier, add = 1, 0
        local tags = {}
        local orderedMods = {}
        for _, item in ipairs(REVEL.HPScalingBalance.ItemPowerModifier) do
            item.Resolved = nil
            item.WasEffectiveLast = nil

            local insPoint = #orderedMods + 1
            for i, mod2 in ipairs(orderedMods) do
                if item.Priority < mod2.Priority then
                    insPoint = i
                    break
                end
            end

            table.insert(orderedMods, insPoint, item)
        end

        modifier, add = REVEL.ResolveItemModifierStack(player, orderedMods, modifier, add, tags)

        if REVEL.BossDebug then
            Isaac.ConsoleOutput("Item Power Modifier: x" .. tostring(modifier) .. ", +" .. tostring(add) .. "\n")
        end

        return modifier, add
    end

    local fightPerfectLength -- Length of fight if every shot lands, used in debugging
    function REVEL.GetScaledBossHP(targetLength, vulnerability, npc, noPrint)
        if (not targetLength or not vulnerability) and npc then
            if REVEL.BossTargetTimeTable[npc.Type] then
                local bossData = REVEL.BossTargetTimeTable[npc.Type][npc.Variant] or REVEL.BossTargetTimeTable[npc.Type][-1] or REVEL.BossTargetTimeTable[npc.Type]
                targetLength, vulnerability = bossData.TargetLength, bossData.Vulnerability
            end
        end

        local averagePower = getAveragePowerForFloorCount(REVEL.level:GetStage())
        if StageAPI and StageAPI.InNewStage() then
            local stageNumber = StageAPI.GetCurrentStage().StageNumber
            if stageNumber then
                averagePower = getAveragePowerForFloorCount(stageNumber)
            end
        end

        local characterDifficulty = 1 -- highest difficulty counts
        local functionalPower = 0
        for _, player in ipairs(REVEL.players) do
            local modifier, add = REVEL.GetItemPowerModifier(player)
            functionalPower = functionalPower + (REVEL.EstimateDPS(player) * modifier) + add

            local characterDiff = REVEL.HPScalingBalance.CharacterDifficultyCompensation[player:GetPlayerType()]
            if characterDiff and characterDiff > characterDifficulty then
                characterDifficulty = characterDiff
            end
        end


        local powerTargetPercent = characterDifficulty / vulnerability / targetLength
        local averageMaxHitPoints = (1 / powerTargetPercent) * averagePower

        local functionalPowerComparison = functionalPower / averagePower

        local powerComparisionSlowerRisePoint = 16.5
        local scaledPowerComparison
        -- At functionalPowerComparison >= 16.5, the curve starts going down again, eventually going into negatives, so use a different curve
        if functionalPowerComparison <= powerComparisionSlowerRisePoint then
            scaledPowerComparison = ((functionalPowerComparison ^ 2) / -100) + (functionalPowerComparison * .33) + .66
        else
            scaledPowerComparison = math.log(functionalPowerComparison ^ 2.7781 + 0.7199) / math.log(10)
        end

        local scaledLength = targetLength / scaledPowerComparison
        local scaledHP = (averageMaxHitPoints * functionalPowerComparison) / scaledPowerComparison

        if REVEL.BossDebug and not noPrint then
            local function out(s) 
                Isaac.ConsoleOutput(s .. "\n") 
                Isaac.DebugString(s)
            end

            out("Average/Estimated DPS: " .. tostring(math.floor(averagePower * 100) / 100) .. "/" .. tostring(math.floor(functionalPower * 100) / 100))

            if functionalPowerComparison >= powerComparisionSlowerRisePoint then
                out("Estimated dps ratio above slower rise point")
            end

            fightPerfectLength = scaledHP / functionalPower
            out("Scaled HP to " .. tostring(math.ceil(scaledHP)) .. "! Scaled/Target Length: " .. tostring(math.ceil(scaledLength)) .. "/" .. tostring(targetLength) .. " seconds.")
            out("Projected Perfect Length: " .. tostring(math.ceil(fightPerfectLength)) .. " seconds.")

            local noScalingLength = averageMaxHitPoints / functionalPower
            out("Estimated Length w/o Scaling: " .. tostring(math.ceil(noScalingLength)) .. " seconds.")
        end

        return scaledHP, scaledHP / scaledLength, scaledLength, targetLength
    end

    function REVEL.SetScaledBossHP(npc, targetLength, vulnerability, hp, hpPerSecond, expectedLength, noPrint)
        if REVEL.DEBUG_NO_SCALING then return end

        if not hp or not hpPerSecond then
            hp, hpPerSecond, expectedLength, targetLength = REVEL.GetScaledBossHP(targetLength, vulnerability, npc, noPrint)
        end

        npc.MaxHitPoints = hp
        npc.HitPoints = npc.MaxHitPoints
        REVEL.GetData(npc).HPScaled = hpPerSecond
    end

    function REVEL.SetScaledBossSpawnHP(npc, spawn, percentHP, maxHP)
        if percentHP then
            spawn.MaxHitPoints = (maxHP or npc.MaxHitPoints) * percentHP
            spawn.HitPoints = spawn.MaxHitPoints
        end

        REVEL.GetData(spawn).HPScaled = REVEL.GetData(npc).HPScaled
    end

    local callingRescaledDamage
    revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, iframes)
        local hpPerSecond = REVEL.GetData(ent).HPScaled
        if ent and hpPerSecond and source and not callingRescaledDamage then
            local dealBombDamage
            if source.Type == EntityType.ENTITY_TEAR and source.Entity then
                if HasBit(flags, TearFlags.TEAR_STICKY) then
                    dealBombDamage = true

                    callingRescaledDamage = true
                    ent:TakeDamage(amount - 60, flags, source, iframes)
                    callingRescaledDamage = nil
                end
            elseif source.Type == EntityType.ENTITY_BOMBDROP and not source.Entity.Parent then
                dealBombDamage = true
            elseif source.Type == EntityType.ENTITY_FAMILIAR and REVEL.HPScalingBalance.ScaledOrbitals[source.Variant] then
                callingRescaledDamage = true

                if type(REVEL.HPScalingBalance.ScaledOrbitals[source.Variant]) == "number" then
                    ent:TakeDamage(hpPerSecond * REVEL.HPScalingBalance.ScaledOrbitals[source.Variant], flags, source, iframes)
                else
                    local percentHP = (amount / REVEL.HPScalingBalance.OrbitalDamageDivide) * REVEL.HPScalingBalance.OrbitalMaxDamage
                    ent:TakeDamage(hpPerSecond * percentHP, flags, source, iframes)
                end

                callingRescaledDamage = nil

                return false
            end

            if dealBombDamage then
                local bombScaling = REVEL.GetData(ent).BombScaling or 1
                local bombDamage = hpPerSecond * REVEL.HPScalingBalance.BombMaxDamage

                bombDamage = bombDamage * 2 * (REVEL.HPScalingBalance.BombTapering ^ bombScaling)

                bombDamage = math.max(bombDamage, hpPerSecond * REVEL.HPScalingBalance.BombMinDamage)

                callingRescaledDamage = true
                ent:TakeDamage(bombDamage, flags, source, iframes)
                callingRescaledDamage = nil

                REVEL.GetData(ent).BombScaling = bombScaling + 1
                return false
            end
        end
    end)

    if REVEL.BossDebug then
        local bossRoomStartTime
        local playerDamageTaken
        StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 1, function()
            local currentRoom = StageAPI.GetCurrentRoom()
            if (REVEL.room:GetType() == RoomType.ROOM_BOSS or StageAPI.GetCurrentRoomType() == "Mirror" or (currentRoom and currentRoom.PersistentData.BossID)) then
                if REVEL.room:GetAliveBossesCount() == 0 then
                    bossRoomStartTime = -1
                else
                    bossRoomStartTime = REVEL.game:GetFrameCount()
                end

                playerDamageTaken = 0
            else
                bossRoomStartTime = nil
                playerDamageTaken = nil
            end
        end)

        StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(e, amount, flags)
            if playerDamageTaken and not HasBit(flags, DamageFlag.DAMAGE_FAKE) then
                playerDamageTaken = playerDamageTaken + 1
            end
        end, EntityType.ENTITY_PLAYER)

        revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
            if bossRoomStartTime == -1 then
                if REVEL.room:GetAliveBossesCount() ~= 0 then
                    bossRoomStartTime = REVEL.game:GetFrameCount()
                end
            elseif REVEL.room:GetAliveBossesCount() == 0 and bossRoomStartTime then
                local elapsed = REVEL.game:GetFrameCount() - bossRoomStartTime
                Isaac.ConsoleOutput("Elapsed Frames: " .. tostring(elapsed) .. ", Seconds: " .. tostring(math.ceil(elapsed / 30)) .. "\n")
                Isaac.ConsoleOutput("Got hit " .. tostring(playerDamageTaken) .. " times\n")

                if fightPerfectLength then
                    local vulnerabilityPercent = ((fightPerfectLength * 30) / elapsed) * 100
                    Isaac.ConsoleOutput("Boss died at " .. tostring(math.floor(vulnerabilityPercent)) .. "% perfect DPS output speed.\n")
                end

                bossRoomStartTime = nil
                playerDamageTaken = nil
                fightPerfectLength = nil
            end
        end)
    end

end

-- Boss / Champion Balance Tables
--[[

Using this system makes basic balance changes very simple, especially for champions.
Ideally you can have the balance table and the boss code open in two tabs to add to the balance table whenever needed while making the boss.

Example:

local balanceTable = {
    Champions = {Champion = "Default", ChampionTwo = "Champion"}, -- defines inheritance, ChampionID = InheritsFrom, defaults to Default
    Var = 1,
    Var = {Default = 1, Champion = 2}, -- tables are still ok, so long as none of their keys match champion ids
    Var = {Default = 1, Champion = 2, ChampionTwo = "Default"}, -- if a variable is a string that matches another key in the table, it'll map to that
    Var = {Foo = {Default = 1, Champion = 2}, Bar = 1} -- works recursively too
}

REVEL.GetBossBalance(balanceTable, championID) will then compile the balance table, which you can then save to entity data

]]

function REVEL.GetBossBalanceRecurse(balanceTable, championID)
    local outTbl = {}
    for key, var in pairs(balanceTable) do
        if type(var) ~= "table" or key == "Champions" then
            outTbl[key] = var
        else
            local inherit = championID

            local hasChampionVar
            while hasChampionVar == nil do
                if var[inherit] ~= nil then
                    if type(var[inherit]) == "string" and var[var[inherit]] and var[inherit] ~= var[var[inherit]] then
                        inherit = var[inherit]
                    else
                        if type(var[inherit]) == "table" then
                            outTbl[key] = REVEL.GetBossBalanceRecurse(var[inherit], championID)
                        else
                            outTbl[key] = var[inherit]
                        end

                        hasChampionVar = true
                    end
                else
                    if balanceTable.Champions and balanceTable.Champions[inherit] then
                        inherit = balanceTable.Champions[inherit]
                    elseif inherit ~= "Default" then
                        inherit = "Default"
                    else
                        hasChampionVar = false
                    end
                end
            end

            if not hasChampionVar then
                outTbl[key] = REVEL.GetBossBalanceRecurse(var, championID)
            end
        end
    end

    return outTbl
end

function REVEL.GetBossBalance(balanceTable, championID)
    local outTbl = REVEL.GetBossBalanceRecurse(balanceTable, championID)

    outTbl.Champion = championID

    if balanceTable.Init and type(balanceTable.Init) == "function" then
        balanceTable.Init(outTbl, championID, balanceTable)
    end

    return outTbl
end

-- Attack Cycle System
--[[

Originally created for Maxwell, this system pairs well with the balance table to create consistent
attack patterns like Aragnid's alternating and random count magic splash and scream attacks by
providing simple weight, repeat attack, and cooldown management, alongside supporting arbitrary functions
called throughout the attack selection process.

Each Cycle or Subcycle is comprised of several cycle segments, which are simply entries in an array.
Cycle segments by default start at 1, then increment each time Repeats run out,
but they can also be jumped to at any time via their index in the array.

Note that the cycle system DOES NOT decrement or check cooldown directly! It should be used primarily
for attack selection, reacting to the selected attack and deciding if an attack should happen at all
should be kept separate.

It also uses the following data variables, so make sure you aren't:
CycleSegment = { -- cycle segment index, last index is the current subcycle, first is always the main cycle. indices after the first are {name, value} arrays.
    {
        Repeats = 2,
        Index = 1
    },
    {
        Repeats = 1,
        SubCycle = "DoubleDoubleHop",
        Index = 1
    }
}
LastAttackInCycle -- last attack by cycle segment index, by default the system will avoid using the same attack in the same cycle twice in a row if possible
LastAttackInGeneral -- last attack overall, by default the system does not avoid using the same attack overall twice in a row, but it can be set to

BalanceTable = { -- A balance table is not strictly necessary but most bosses should be using one and it *is* necessary for globally default cooldowns and functions, as well as Subcycles
    AttackCycleDefaultCooldown = 20,
    AttackCycleDefaultCooldownBetween = 20,
    AttackCycleDefaultCooldownAfterAttack = { -- You can specify default cooldowns for after the final repeat of each attack here, note that this overrides all non-specific CooldownAfter variables.
        DoubleHop = 30
    },
    AttackCycleDefaultCooldownBetweenAttack = { -- Same as above, but for between attacks rather than final
        Elevator = 40
    },
    AttackCycleNonRepeatWeight = 10, -- In order to avoid repeating attacks in cycles (or in general), the weight of every attack that was not the last attack in cycle or in general is multiplied by this number.
    IncreaseSubcycleIndexOnChildEnd = false, --In case you want sub-subcyles to increase the origin cycle's Index (default false since existing bosses have been implemented without this)
    SubCycles = { -- A subcycle is a nested cycle, for when an attack consists of doing something multiple times or multiple different but consistent attacks.
        DoubleDoubleHop = {
            {
                Attacks = { -- Base attack weight, can be modified later.
                    DoubleHop = 1
                },
                Repeat = 1, -- Repeat can be nil for no repeat, a number to repeat that number of times, a min and max to select randomly between two points, or a table to select randomly from the table's contents
                CooldownBetween = 20, -- CooldownBetween is the cooldown between repeats, defaults to AttackCycleDefaultCooldownBetween or 0.
                IsHop = true -- Any extra data can be included in each cycle segment if needed
            }
        }
    },
    Cycle = { -- You can have as many primary cycles as you want, to change based on health thresholds or such. Is passed into the ManageAttackCycle function to allow changing.
        {
            Attacks = {
                DoubleDoubleHop = 1, -- If an attack name matches a subcycle's, the attack will be treated as one
                ThinkingWithPortals = 1
            },
            Repeat = {
                Min = 0,
                Max = 1
            },
            IgnoreLastAttackInCycle = true, -- ignores the last attack in the cycle and will allow doing the same attack twice in a row
            CooldownBetweenByAttack = { -- CooldownBetween and CooldownAfter can be based on the attack, rather than the same for each. Also works for SubCycles!
                DoubleDoubleHop = 40,
                ThinkingWithPortals = 20
            },
            IsHop = true
        },
        {
            Attacks = {
                ThinkingWithPortals = 1,
                Elevator = 1
            },
            AvoidLastAttackInGeneral = true,
            NonRepeatWeight = 2, -- Overrides AttackCycleNonRepeatWeight for this segment
            Repeat = {3, 5},
            CooldownAfter = 60, -- CooldownAfter is the cooldown after the cycle segment and all repeats, defaults to AttackCycleDefaultCooldown or 0.
            IsHop = true
        }
    }
}

]]

function REVEL.JumpToCycle(data, index, subcycle, subindex, attack, forceAttack, noCountForCycle)
    data.Cycle = {{Index = index}}
    if subcycle then
        data.Cycle[#data.Cycle + 1] = {Index = subindex, SubCycle = subcycle, NoCountForCycle = noCountForCycle}
    end

    if attack then
        if not forceAttack then -- act as if the attack has already been performed
            if not data.LastAttackInCycle then
                data.LastAttackInCycle = {}
            end

            local cycleID = subcycle or "Primary"
            if not data.LastAttackInCycle[cycleID] then
                data.LastAttackInCycle[cycleID] = {}
            end

            data.LastAttackInCycle[cycleID][subindex or index] = attack
            data.LastAttackInGeneral = attack
        else
            data.ForceNextCycleAttack = attack
        end
    end
end

function REVEL.AddToCycle(data, subcycle, subindex, noCountForCycle)
    data.Cycle[#data.Cycle + 1] = {Index = subindex, SubCycle = subcycle, NoCountForCycle = noCountForCycle}
end

function REVEL.SetCurrentCycleRepeats(data, repeats)
    data.Cycle[#data.Cycle].Repeats = repeats or data.Cycle[#data.Cycle].InitialRepeats
end

function REVEL.GetAttackForCycle(data, bal, curCycleSegment, curCycleData, curCycle, primaryCycle, ...)
    if not data.LastAttackInCycle then
        data.LastAttackInCycle = {}
    end

    local cycleID = curCycleData.SubCycle or "Primary"
    if not data.LastAttackInCycle[cycleID] then
        data.LastAttackInCycle[cycleID] = {}
    end

    local attackOutOfRepeats = (curCycleData.InitialRepeats - curCycleData.Repeats) + 1 -- 1 = the initial attack, 2 = the first repeat, 3 = the second repeat, etc

    local attack
    if bal.PreCycleSelectAttack then
        attack = bal.PreCycleSelectAttack(data, bal, curCycleSegment, curCycleData, ...)
    end

    if not attack then
        if data.ForceNextCycleAttack then
            attack = data.ForceNextCycleAttack
            data.ForceNextCycleAttack = nil
        elseif curCycleSegment.AttackOrder and curCycleSegment.AttackOrder[attackOutOfRepeats] then
            attack = curCycleSegment.AttackOrder[attackOutOfRepeats]
        else
            local attacks = {}
            for attack, weight in pairs(curCycleSegment.Attacks) do
                if weight then
                    if (curCycleSegment.NonRepeatWeight or bal.AttackCycleNonRepeatWeight) and
                    ((not curCycleSegment.IgnoreLastAttackInCycle and attack ~= data.LastAttackInCycle[cycleID][curCycleData.Index])
                    or (curCycleSegment.AvoidLastAttackInGeneral and attack ~= data.LastAttackInGeneral)) then
                        attacks[attack] = weight * (curCycleSegment.NonRepeatWeight or bal.AttackCycleNonRepeatWeight)
                    else
                        attacks[attack] = weight
                    end
                end
            end

            if bal.PostCycleWeights then
                bal.PostCycleWeights(attacks, data, bal, curCycleSegment, curCycleData, ...)
            end

            attack = REVEL.WeightedRandom(attacks)
        end
    end

    data.LastAttackInCycle[cycleID][curCycleData.Index] = attack

    if bal.SubCycles and bal.SubCycles[attack] then
        data.Cycle[#data.Cycle + 1] = {Index = 1, SubCycle = attack}
        curCycleSegment, curCycleData, curCycle = REVEL.GetCurrentCycleSegment(data, bal, primaryCycle)
        attack, curCycleSegment, curCycleData, curCycle = REVEL.GetAttackForCycle(data, bal, curCycleSegment, curCycleData, curCycle, primaryCycle, ...)
    else
        data.LastAttackInGeneral = attack
    end

    return attack, curCycleSegment, curCycleData, curCycle
end

function REVEL.GetCurrentCycleSegment(data, bal, primaryCycle)
    if not data.Cycle then
        data.Cycle = {{Index = 1}}
    end

    local curCycle = primaryCycle
    local cycleData = data.Cycle[#data.Cycle]

    if cycleData.SubCycle then
        curCycle = bal.SubCycles[cycleData.SubCycle]
    end

    local cycleSegment = curCycle[cycleData.Index]

    if not cycleData.Repeats then
        if not cycleSegment.Repeat then
            cycleData.Repeats = 0
            cycleData.InitialRepeats = 0
        else
            if type(cycleSegment.Repeat) == "number" then
                cycleData.Repeats = cycleSegment.Repeat
            elseif #cycleSegment.Repeat > 0 then
                cycleData.Repeats = cycleSegment.Repeat[math.random(1, #cycleSegment.Repeat)]
            elseif cycleSegment.Repeat.Min then
                cycleData.Repeats = math.random(cycleSegment.Repeat.Min, cycleSegment.Repeat.Max)
            end
        end

        cycleData.InitialRepeats = cycleData.Repeats
    end

    return cycleSegment, cycleData, curCycle
end

function REVEL.GetCurrentCycleAttackCooldown(bal, curCycleSegment, curCycleData, attack, attackFromEndedSubCycle)
    local cooldown
    local cooldownAfterByAttack = curCycleSegment.CooldownAfterByAttack or bal.AttackCycleDefaultCooldownAfterAttack
    local cooldownBetweenByAttack = curCycleSegment.CooldownBetweenByAttack or bal.AttackCycleDefaultCooldownBetweenAttack
    if not curCycleData.Repeats then
        if cooldownAfterByAttack then
            cooldown = cooldownAfterByAttack[attackFromEndedSubCycle or attack]
        end

        if not cooldown then
            cooldown = curCycleSegment.CooldownAfter or bal.AttackCycleDefaultCooldown
        end
    else
        if cooldownBetweenByAttack then
            cooldown = cooldownBetweenByAttack[attackFromEndedSubCycle or attack]
        end

        if not cooldown then
            cooldown = curCycleSegment.CooldownBetween or bal.AttackCycleDefaultCooldownBetween
        end
    end

    if cooldown and type(cooldown) ~= "number" then
        if cooldown.Min then
            cooldown = math.random(cooldown.Min, cooldown.Max)
        end
    end

    return cooldown
end

function REVEL.ManageAttackCycle(data, bal, primaryCycle, ...)
    primaryCycle = primaryCycle or bal.Cycle
    local curCycleSegment, curCycleData, curCycle

    if bal.CycleStartCheck then -- We have to re-get this stuff anyway since cyclestartcheck might change it, so let's only do it when it needs to be passed into CycleStartCheck
        curCycleSegment, curCycleData, curCycle = REVEL.GetCurrentCycleSegment(data, bal, primaryCycle)
    end

    if not bal.CycleStartCheck or bal.CycleStartCheck(data, bal, curCycleSegment, primaryCycle, curCycle, ...) then
        curCycleSegment, curCycleData, curCycle = REVEL.GetCurrentCycleSegment(data, bal, primaryCycle)

        -- When a subcycle ends, the cooldown used should be the cycle above's, and vice versa for when a subcycle starts.
        -- This means that we need to grab new cycle segment / index data a few times throughout, hence the GetCurrentCycleSegment function.
        local attack = nil
        attack, curCycleSegment, curCycleData, curCycle = REVEL.GetAttackForCycle(data, bal, curCycleSegment, curCycleData, curCycle, primaryCycle, ...)

        local attackCycleSegment = curCycleSegment

        -- Attack selection happens before repeat handling because cycle data can change during repeat handling.
        local changedPhase = false
        local attackFromEndedSubCycle
        local countsForCycle = true
        if curCycleData.SubCycle then
            if curCycleData.Repeats <= 0 then
                changedPhase = true

                curCycleData.Index = curCycleData.Index + 1
                curCycleData.Repeats = nil
                if curCycleData.Index > #curCycle then
                    if curCycleData.SubCycle then
                        if curCycleData.NoCountForCycle then
                            countsForCycle = false
                        end

                        data.Cycle[#data.Cycle] = nil
                        attackFromEndedSubCycle = curCycleData.SubCycle
                        curCycleSegment, curCycleData, curCycle = REVEL.GetCurrentCycleSegment(data, bal, primaryCycle)

                        if bal.IncreaseSubcycleIndexOnChildEnd and curCycleData.SubCycle then
                            curCycleData.Index = curCycleData.Index + 1
                            curCycleData.Repeats = nil
                        end
                    end
                end
            else
                curCycleData.Repeats = curCycleData.Repeats - 1
            end
        end

        if not curCycleData.SubCycle and countsForCycle then
            if curCycleData.Repeats <= 0 then
                changedPhase = true

                curCycleData.Index = curCycleData.Index + 1
                curCycleData.Repeats = nil
                if curCycleData.Index > #curCycle then
                    curCycleData.Index = 1
                end
            else
                curCycleData.Repeats = curCycleData.Repeats - 1
            end
        end

        local baseCooldownOn = curCycleSegment
        if not countsForCycle and attackFromEndedSubCycle then
            attackFromEndedSubCycle = nil
            baseCooldownOn = attackCycleSegment
        end

        local cooldown = REVEL.GetCurrentCycleAttackCooldown(bal, baseCooldownOn, curCycleData, attack, attackFromEndedSubCycle)

        return attackCycleSegment, true, attack, cooldown, changedPhase
    end

    return curCycle, false
end


-- Attack Weighting System (largely redundant due to cycle system)
--[[

Weight tables are arranged {
    AttackName = Weight
}

local attackWeightBalance = {
    Initial = weightTable,
    Min = weightTable, -- minimum weight per attack
    Max = weightTable, -- maximum weight per attack
    Remove = { -- can also add, using negative numbers
        AttackName = Weight, -- removes an amount of weight from itself when used
        AttackName = {AttackName = Weight, AttackName = Weight} -- removes an amount of weight from a set of other attacks when used
    }, -- when an attack is selected, removes this amount from its weight
    Reset = {
        AttackName = AttackName, -- resets a specific attack or set of attacks to their initial weight
        AttackName = {AttackName, AttackName},
        AttackName = {AttackName = amount}, -- sets a specific attack to a specific weight
        AttackName = true -- true resets everything to its initial weight
    }
}

REVEL.SelectBossWeightedAttack(currentAttackWeights, attackWeightBalance, forceAttacks, forceWeights) -- modifies the currentAttackWeights table, returns the attack name

]]

function REVEL.SelectBossWeightedAttack(currentAttackWeights, attackWeightBalance, forceAttacks, forceWeights)
    if attackWeightBalance.Initial and not next(currentAttackWeights) then
        for k, v in pairs(attackWeightBalance.Initial) do
            currentAttackWeights[k] = v
        end
    end

    local usingWeights = currentAttackWeights

    if forceAttacks or forceWeights then
        usingWeights = {}
        if forceAttacks then
            if type(forceAttacks) ~= "table" then
                forceAttacks = {forceAttacks}
            end

            for _, attack in ipairs(forceAttacks) do
                usingWeights[attack] = currentAttackWeights[attack]
            end
        end

        if forceWeights then
            for attack, weight in pairs(forceWeights) do
                usingWeights[attack] = weight
            end
        end
    end

    local atk = REVEL.WeightedRandom(usingWeights)

    if attackWeightBalance.Remove and attackWeightBalance.Remove[atk] then
        if type(attackWeightBalance.Remove[atk]) == "number" then
            currentAttackWeights[atk] = currentAttackWeights[atk] - attackWeightBalance.Remove[atk]
        else
            for k, v in pairs(attackWeightBalance.Remove[atk]) do
                currentAttackWeights[k] = currentAttackWeights[k] - v
            end
        end
    end

    if attackWeightBalance.Min then
        for k, v in pairs(currentAttackWeights) do
            if attackWeightBalance.Min[k] and currentAttackWeights[k] < attackWeightBalance.Min[k] then
                currentAttackWeights[k] = attackWeightBalance.Min[k]
            end
        end
    end

    if attackWeightBalance.Max then
        for k, v in pairs(currentAttackWeights) do
            if attackWeightBalance.Max[k] and currentAttackWeights[k] > attackWeightBalance.Max[k] then
                currentAttackWeights[k] = attackWeightBalance.Max[k]
            end
        end
    end

    if attackWeightBalance.Reset and attackWeightBalance.Reset[atk] then
        if attackWeightBalance.Reset[atk] == true then
            for k, v in pairs(attackWeightBalance.Initial) do
                currentAttackWeights[k] = v
            end
        elseif type(attackWeightBalance.Reset[atk]) == "string" then
            currentAttackWeights[attackWeightBalance.Reset[atk]] = attackWeightBalance.Initial[attackWeightBalance.Reset[atk]]
        else
            if #attackWeightBalance.Reset[atk] > 0 then
                for _, v in ipairs(attackWeightBalance.Reset[atk]) do
                    currentAttackWeights[v] = attackWeightBalance.Initial[v]
                end
            else
                for k, v in pairs(attackWeightBalance.Reset[atk]) do
                    currentAttackWeights[k] = v
                end
            end
        end
    end

    return atk
end


end