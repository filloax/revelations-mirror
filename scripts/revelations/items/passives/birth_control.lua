local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RandomPickupSubtype = require("scripts.revelations.common.enums.RandomPickupSubtype")

return function()
------------------
-- Birth Control --
------------------

--[[
    Items that could use effects that don't have one:
    -king baby
    -wandering soul
]]

-- replace familiars with 0.2 dmg up
local BirthControl = {
    Blacklist = {
        [CollectibleType.COLLECTIBLE_ONE_UP] = true,
        [CollectibleType.COLLECTIBLE_ISAACS_HEART] = true,
        [CollectibleType.COLLECTIBLE_DEAD_CAT] = true,
        [CollectibleType.COLLECTIBLE_KEY_PIECE_1] = true,
        [CollectibleType.COLLECTIBLE_KEY_PIECE_2] = true,
        [CollectibleType.COLLECTIBLE_KNIFE_PIECE_1] = true,
        [CollectibleType.COLLECTIBLE_KNIFE_PIECE_2] = true,
        [CollectibleType.COLLECTIBLE_SPIDER_MOD] = true,
        [CollectibleType.COLLECTIBLE_HALO_OF_FLIES] = true,
        [CollectibleType.COLLECTIBLE_DAMOCLES_PASSIVE] = true,
        [REVEL.ITEM.LIL_BELIAL.id] = true,
        [REVEL.ITEM.MIRROR.id] = true,
        [REVEL.ITEM.MIRROR2.id] = true,
        [REVEL.ITEM.PHYLACTERY.id] = true
    },
    -- Since they are permanent effects, practically no reason not to add them as items
    FamToItem = {
        [CollectibleType.COLLECTIBLE_ROTTEN_BABY] = CollectibleType.COLLECTIBLE_MULLIGAN,
        [CollectibleType.COLLECTIBLE_BOBS_BRAIN] = CollectibleType.COLLECTIBLE_IPECAC,
        [CollectibleType.COLLECTIBLE_GB_BUG] = CollectibleType.COLLECTIBLE_MISSING_NO,
        [CollectibleType.COLLECTIBLE_FARTING_BABY] = CollectibleType.COLLECTIBLE_BLACK_BEAN,
        [CollectibleType.COLLECTIBLE_DRY_BABY] = CollectibleType.COLLECTIBLE_MISSING_PAGE_2,
        [CollectibleType.COLLECTIBLE_LIL_LOKI] = CollectibleType.COLLECTIBLE_LOKIS_HORNS,
        [CollectibleType.COLLECTIBLE_DEPRESSION] = CollectibleType.COLLECTIBLE_AQUARIUS,
        [CollectibleType.COLLECTIBLE_ROBO_BABY] = CollectibleType.COLLECTIBLE_TECHNOLOGY,
        [CollectibleType.COLLECTIBLE_ROBO_BABY_2] = CollectibleType.COLLECTIBLE_TECHNOLOGY_2,
        [CollectibleType.COLLECTIBLE_HARLEQUIN_BABY] = CollectibleType.COLLECTIBLE_THE_WIZ,
        [CollectibleType.COLLECTIBLE_FATES_REWARD] = CollectibleType.COLLECTIBLE_FATE,
        [CollectibleType.COLLECTIBLE_LIL_MONSTRO] = CollectibleType.COLLECTIBLE_MONSTROS_LUNG,
        [CollectibleType.COLLECTIBLE_LIL_BRIMSTONE] = CollectibleType.COLLECTIBLE_BRIMSTONE,
        [CollectibleType.COLLECTIBLE_SERAPHIM] = CollectibleType.COLLECTIBLE_SACRED_HEART,
        [CollectibleType.COLLECTIBLE_RAINBOW_BABY] = CollectibleType.COLLECTIBLE_3_DOLLAR_BILL,
        [CollectibleType.COLLECTIBLE_LIL_DELIRIUM] = CollectibleType.COLLECTIBLE_FRUIT_CAKE,
        [CollectibleType.COLLECTIBLE_LIL_ABADDON] = CollectibleType.COLLECTIBLE_MAW_OF_THE_VOID,
        [CollectibleType.COLLECTIBLE_BOT_FLY] = CollectibleType.COLLECTIBLE_LOST_CONTACT,
        [CollectibleType.COLLECTIBLE_PSY_FLY] = CollectibleType.COLLECTIBLE_SPOON_BENDER,
        [CollectibleType.COLLECTIBLE_INCUBUS] = CollectibleType.COLLECTIBLE_20_20,
        [CollectibleType.COLLECTIBLE_TWISTED_PAIR] = CollectibleType.COLLECTIBLE_20_20,
        [CollectibleType.COLLECTIBLE_INTRUDER] = CollectibleType.COLLECTIBLE_MUTANT_SPIDER,
        [CollectibleType.COLLECTIBLE_BLOODSHOT_EYE] = CollectibleType.COLLECTIBLE_EYE_SORE,
        [CollectibleType.COLLECTIBLE_BIG_FAN] = CollectibleType.COLLECTIBLE_BUCKET_OF_LARD,
        [CollectibleType.COLLECTIBLE_MOMS_RAZOR] = CollectibleType.COLLECTIBLE_BACKSTABBER,
        [CollectibleType.COLLECTIBLE_FREEZER_BABY] = CollectibleType.COLLECTIBLE_URANUS,
        [CollectibleType.COLLECTIBLE_STRAW_MAN] = CollectibleType.COLLECTIBLE_GREEDS_GULLET,
        [REVEL.ITEM.LIL_MICHAEL.id] = CollectibleType.COLLECTIBLE_SPIRIT_SWORD,
        [REVEL.ITEM.LIL_FRIDER.id] = REVEL.ITEM.ICETRAY.id
    },
    FamToStat = {
        [CollectibleType.COLLECTIBLE_BROTHER_BOBBY] = {
            "MaxFireDelay", -1, "add"
        },
        [CollectibleType.COLLECTIBLE_MILK] = {
            "MaxFireDelay", -1, "add"
        },
        [CollectibleType.COLLECTIBLE_PASCHAL_CANDLE] = {
            "MaxFireDelay", -1, "add"
        },
        [CollectibleType.COLLECTIBLE_FRUITY_PLUM] = {
            "MaxFireDelay", 0.5, "mult"
        },
        [CollectibleType.COLLECTIBLE_SISTER_MAGGY] = {
            "Damage", 0.8, "add"
        },
        [CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER] = {
            "Damage", 0.8, "add"
        },
        [CollectibleType.COLLECTIBLE_GUARDIAN_ANGEL] = {
            "MoveSpeed", 0.2, "add"
        },
        [CollectibleType.COLLECTIBLE_YO_LISTEN] = {
            "Luck", 1, "add"
        },
    },
    FamToStatSecondary = {
        [CollectibleType.COLLECTIBLE_FRUITY_PLUM] = {
            "ShotSpeed", 0.75, "mult"
        },
    },
    NoDamageOrRemove = {
        [CollectibleType.COLLECTIBLE_MULTIDIMENSIONAL_BABY] = true,
        [CollectibleType.COLLECTIBLE_SUCCUBUS] = true,
        [CollectibleType.COLLECTIBLE_ANGELIC_PRISM] = true,
        [CollectibleType.COLLECTIBLE_CENSER] = true,
        [CollectibleType.COLLECTIBLE_JUICY_SACK] = true,
        [CollectibleType.COLLECTIBLE_LIL_DUMPY] = true,
        [REVEL.ITEM.WILLO.id] = true
    },
    FlyFams = {
        [CollectibleType.COLLECTIBLE_DISTANT_ADMIRATION] = true,
        [CollectibleType.COLLECTIBLE_FRIEND_ZONE] = true,
        [CollectibleType.COLLECTIBLE_HALO_OF_FLIES] = true,
        [CollectibleType.COLLECTIBLE_FOREVER_ALONE] = true,
        [CollectibleType.COLLECTIBLE_SMART_FLY] = true,
        [CollectibleType.COLLECTIBLE_BEST_BUD] = true,
        [CollectibleType.COLLECTIBLE_BLUEBABYS_ONLY_FRIEND] = true,
        [CollectibleType.COLLECTIBLE_LOST_FLY] = true,
        [CollectibleType.COLLECTIBLE_BIG_FAN] = true,
        [CollectibleType.COLLECTIBLE_OBSESSED_FAN] = true,
        [CollectibleType.COLLECTIBLE_PAPA_FLY] = true,
        [CollectibleType.COLLECTIBLE_ANGRY_FLY] = true,
        [CollectibleType.COLLECTIBLE_BOT_FLY] = true,
        [CollectibleType.COLLECTIBLE_PSY_FLY] = true,
        [CollectibleType.COLLECTIBLE_FRUITY_PLUM] = true,
        [CollectibleType.COLLECTIBLE_BBF] = true,
    },
    SpiderFams = {
        [CollectibleType.COLLECTIBLE_SISSY_LONGLEGS] = true,
        [CollectibleType.COLLECTIBLE_DADDY_LONGLEGS] = true,
        [CollectibleType.COLLECTIBLE_JUICY_SACK] = true,
        [CollectibleType.COLLECTIBLE_TINYTOMA] = true,
        [CollectibleType.COLLECTIBLE_INTRUDER] = true
    },
}

local function gulpTrinket(trinket, player)
    local trinket_mem = {}
    for i = 1, player:GetMaxTrinkets() do
        local trinket_id = player:GetTrinket(0)
        if trinket_id ~= TrinketType.TRINKET_NULL then
            player:TryRemoveTrinket(trinket_id)
            trinket_mem[#trinket_mem+1] = trinket_id
        end
    end
    
    player:AddTrinket(trinket)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER,UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)

    for _, trinket_id in ipairs(trinket_mem) do
        player:AddTrinket(trinket_id) 
    end
end

-- Contains: {id, function(id, num)}
-- Checked in order
local FamiliarSynergyes = {
    [CollectibleType.COLLECTIBLE_SACK_OF_PENNIES] = function(id, num, player)
        for i = 1, math.random(5, 9) do
            local sub = CoinSubType.COIN_PENNY
            if math.random(1, 5) == 1 then
                sub = CoinSubType.COIN_LUCKYPENNY
            end

            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_COIN, 
                sub,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_SACK_OF_SACKS] = function(id, num, player)
        for i = 1, math.random(3, 5) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_GRAB_BAG, 0,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_RELIC] = function(id, num, player)
        for i = 1, math.random(4, 7) do
            local sub = HeartSubType.HEART_SOUL
            if math.random(1, 3) ~= 1 then
                sub = HeartSubType.HEART_HALF_SOUL
            end

            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_HEART, 
                sub,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_LITTLE_CHAD] = function(id, num, player)
        for i = 1, math.random(5, 9) do
            local sub = HeartSubType.HEART_FULL
            if math.random(1, 3) ~= 1 then
                sub = HeartSubType.HEART_HALF
            end

            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_HEART, 
                sub,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_MYSTERY_SACK] = function(id, num, player)
        for i = 1, math.random(4, 7) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.ANY_PICKUP,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_LIL_CHEST] = function(id, num, player)
        for i = 1, math.random(4, 7) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.ANY_PICKUP,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_ACID_BABY] = function(id, num, player)
        for i = 1, math.random(4, 6) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_RUNE_BAG] = function(id, num, player)
        for i = 1, math.random(4, 6) do
            local rune = REVEL.pool:GetCard(Random(), false, true, true)
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_TAROTCARD,
                rune,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_CHARGED_BABY] = function(id, num, player)
        for i = 1, math.random(3, 5) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, 0,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_BOMB_BAG] = function(id, num, player)
        for i = 1, math.random(4, 7) do
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL,
                REVEL.room:FindFreePickupSpawnPosition(
                    player.Position, 0, true),
                Vector.Zero, 
                player
            )
        end
    end,
    [CollectibleType.COLLECTIBLE_LOST_SOUL] = function(id, num, player)
        if player:GetPlayerType() ~= PlayerType.PLAYER_THELOST and player:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_ALABASTER_BOX, UseFlag.USE_NOANIM)
            --what have i done
            player:ChangePlayerType(PlayerType.PLAYER_THELOST)
        else
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 51,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
        end
    end,
    [CollectibleType.COLLECTIBLE_DARK_BUM] = function(id, num, player)
        for i = 1, math.random(3, 5) do
            local rand = math.random(1,4)
            if rand >= 3 then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 6,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
            elseif rand == 2 then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
            elseif rand == 1 then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, 0,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
            end
        end
    end,
    [CollectibleType.COLLECTIBLE_BUM_FRIEND] = function(id, num, player)
        for i = 1, math.random(4, 7) do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, 0, RandomPickupSubtype.ANY_PICKUP,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
        end
    end,
    [CollectibleType.COLLECTIBLE_KEY_BUM] = function(id, num, player)
        for i = 1, math.random(3, 4) do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_CHEST, 0,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
        end
    end,
    [CollectibleType.COLLECTIBLE_WORM_FRIEND] = function(id, num, player)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 1,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
    end,
    [CollectibleType.COLLECTIBLE_7_SEALS] = function(id, num, player)
        local locusts = {
            TrinketType.TRINKET_LOCUST_OF_FAMINE,
            TrinketType.TRINKET_LOCUST_OF_PESTILENCE,
            TrinketType.TRINKET_LOCUST_OF_WRATH,
            TrinketType.TRINKET_LOCUST_OF_DEATH,
            TrinketType.TRINKET_LOCUST_OF_CONQUEST,
        }
        local rand = math.random(1,5)
        for i = 1, 3 do
            if rand > 5 then rand = 1 end
            if i == 1 then
                gulpTrinket(locusts[rand],player)
            else
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, locusts[rand],
                        REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                        Vector.Zero, player)
            end
            rand = rand + 1
        end
    end,
    [CollectibleType.COLLECTIBLE_STRAW_MAN] = function(id, num, player)
        if player:GetPlayerType() ~= PlayerType.PLAYER_KEEPER and player:GetPlayerType() ~= PlayerType.PLAYER_KEEPER_B then
            player:ChangePlayerType(PlayerType.PLAYER_KEEPER)
        end
    end,
    [CollectibleType.COLLECTIBLE_SWORN_PROTECTOR] = function(id, num, player)
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 4,
                        REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                        Vector.Zero, player)
    end,
    [CollectibleType.COLLECTIBLE_BBF] = function(id, num, player)
        gulpTrinket(TrinketType.TRINKET_SWALLOWED_M80,player)
    end,
}

--Fiend Folio x Birth Control
if REVEL.FiendFolioCompatLoaded then
    REVEL.mixin(BirthControl.NoDamageOrRemove, {
        [FiendFolio.ITEM.COLLECTIBLE.BABY_CRATER] = true,
        [FiendFolio.ITEM.COLLECTIBLE.LIL_LAMB] = true,
        [FiendFolio.ITEM.COLLECTIBLE.DEIMOS] = true,
    }, true)

    REVEL.mixin(BirthControl.SpiderFams, {
        [FiendFolio.ITEM.COLLECTIBLE.MAMA_SPOOTER] = true,
        [FiendFolio.ITEM.COLLECTIBLE.PEACH_CREEP] = true,
    }, true)

    REVEL.mixin(FamiliarSynergyes, {
        [FiendFolio.ITEM.COLLECTIBLE.LIL_FIEND] = function(id, num, player)
            if player:GetPlayerType() ~= FiendFolio.PLAYER.FIEND and player:GetPlayerType() ~= FiendFolio.PLAYER.BIEND then
                player:ChangePlayerType(FiendFolio.PLAYER.FIEND)
            end
        end,
        [FiendFolio.ITEM.COLLECTIBLE.DICE_BAG] = function(id, num, player)
            local dice = {
                Card.GLASS_D6, Card.GLASS_D4, Card.GLASS_D8, Card.GLASS_D100,
                Card.GLASS_D10, Card.GLASS_D20, Card.GLASS_D12, Card.GLASS_SPINDOWN,
                Card.GLASS_AZURITE_SPINDOWN
            }
            for i = 1, math.random(3, 5) do
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, 300, dice[math.random(1,#dice)],
                    REVEL.room:FindFreePickupSpawnPosition(
                        player.Position, 0, true),
                    Vector.Zero, 
                    player
                )
            end
        end,
        [FiendFolio.ITEM.COLLECTIBLE.GREG_THE_EGG] = function(id, num, player)
            REVEL.sfx:Play(SoundEffect.SOUND_BOIL_HATCH,1,1,false,1)
            local babyChoice = REVEL.game:GetItemPool():GetCollectible(ItemPoolType.POOL_BABY_SHOP, true)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, 100, babyChoice,
                REVEL.room:FindFreePickupSpawnPosition(player.Position, 0, true),
                Vector.Zero, player)
        end
    })
end

---@param player EntityPlayer
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 1, function(player, pind)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
        if REVEL.DEBUG then
            REVEL.DebugToString("Ran pickup callback for bcontrol!")
        end

        local shouldEvalCache

        for id, num in pairs(revel.data.run.inventory[pind]) do
            if id then
                local item = REVEL.config:GetCollectible(id)

                if id == CollectibleType.COLLECTIBLE_BFFS and num >= 1 
                and player:HasCollectible(id, true) then
                    for i = 1, num do
                        player:RemoveCollectible(id)
                        player:AddCollectible(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM, 0, false)
                    end
                end

                local runStats = revel.data.run.stats[REVEL.GetPlayerID(player)]

                if item.Type == ItemType.ITEM_FAMILIAR 
                and not BirthControl.Blacklist[id] 
                and num >= 1 
                and not (
                    player:GetPlayerType() == PlayerType.PLAYER_LILITH 
                    and id == CollectibleType.COLLECTIBLE_INCUBUS
                ) 
                 -- the HasCollectible is in case the inventoyr got scrambled without the amount 
                 -- changing by something other than D4/100 (eg dice rooms) since that cannot be detected
                and player:HasCollectible(id, true) 
                then

                    REVEL.sfx:Play(SoundEffect.SOUND_VAMP_GULP)
                    if not BirthControl.NoDamageOrRemove[id] then
                        for i = 1, num do
                            player:RemoveCollectible(id)
                            runStats.Damage = runStats.Damage + 0.2
                        end
                    end

                    if tonumber(revel.data.run.bcSynergyes[id]) then
                        revel.data.run.bcSynergyes[id] = revel.data.run.bcSynergyes[id] + 1
                    end

                    if BirthControl.FamToItem[id] then
                        player:AddCollectible(BirthControl.FamToItem[id], 0, true)
                    end

                    if BirthControl.FamToStat[id] then
                        if BirthControl.FamToStat[id][3] == "mult" then
                            runStats.mult[BirthControl.FamToStat[id][1]] = runStats.mult[BirthControl.FamToStat[id][1]] * BirthControl.FamToStat[id][2]
                        else
                            runStats[BirthControl.FamToStat[id][1]] = runStats[BirthControl.FamToStat[id][1]] + BirthControl.FamToStat[id][2]
                        end
                    end

                    if BirthControl.FamToStatSecondary[id] then
                        if BirthControl.FamToStatSecondary[id][3] == "mult" then
                            runStats.mult[BirthControl.FamToStatSecondary[id][1]] = runStats.mult[BirthControl.FamToStatSecondary[id][1]] * BirthControl.FamToStatSecondary[id][2]
                        else
                            runStats[BirthControl.FamToStatSecondary[id][1]] = runStats[BirthControl.FamToStatSecondary[id][1]] + BirthControl.FamToStatSecondary[id][2]
                        end
                    end

                    if BirthControl.FlyFams[id] then
                        local r = math.random(5) + 2
                        player:AddBlueFlies(r, player.Position, player)
                    end

                    if BirthControl.SpiderFams[id] then
                        local r = math.random(4) + 2
                        for i = 1, r do
                            player:AddBlueSpider(player.Position)
                        end
                    end

                    if FamiliarSynergyes[id] then
                        FamiliarSynergyes[id](id, num, player)
                    end

                    shouldEvalCache = true
                end
            end
        end

        -- reevaluate items to remove familiars and add damage
        if shouldEvalCache then
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE |
                                        CacheFlag.CACHE_FIREDELAY |
                                        CacheFlag.CACHE_FAMILIARS |
                                        CacheFlag.CACHE_SPEED |
                                        CacheFlag.CACHE_LUCK |
                                        CacheFlag.CACHE_SHOTSPEED |
                                        CacheFlag.CACHE_TEARCOLOR)
            player:EvaluateItems()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        --    e.Position = e.Player.Position + REVEL.GetCorrectedFiringInput(e.Player) * 3
        e.Visible = false
        e.Velocity = (e.Player.Position + REVEL.GetCorrectedFiringInput(e.Player) * 3) - e.Position
    end
end, FamiliarVariant.MULTIDIMENSIONAL_BABY)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        if not REVEL.GetData(e).SpriteReplace then
            REVEL.GetData(e).SpriteReplace = true
            local spr = e:GetSprite()
            spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
            spr:LoadGraphics()
        end

        e.Position = e.Player.Position
    end
end, FamiliarVariant.SUCCUBUS)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        if not REVEL.GetData(e).SpriteReplace then
            REVEL.GetData(e).SpriteReplace = true
            local spr = e:GetSprite()
            spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
            spr:LoadGraphics()
        end

        e.Position = e.Player.Position
    end
end, FamiliarVariant.CENSER)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        if not REVEL.GetData(e).SpriteReplace then
            REVEL.GetData(e).SpriteReplace = true
            local spr = e:GetSprite()
            spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
            spr:LoadGraphics()
        end

        e.Position = e.Player.Position
    end
end, FamiliarVariant.JUICY_SACK)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        if not REVEL.GetData(e).SpriteReplace then
            REVEL.GetData(e).SpriteReplace = true
            local spr = e:GetSprite()
            spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
            spr:LoadGraphics()
        end

        e.Position = e.Player.Position
    end
end, FamiliarVariant.LIL_DUMPY)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
        if not REVEL.GetData(e).BControl then
            REVEL.GetData(e).BControl = true 
        end
    end
end, REVEL.ENT.WILLO.variant)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    local player = e.Player
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) 
    and not (
        player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) 
        or player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE)
        or player:HasWeaponType(WeaponType.WEAPON_LASER) 
        or player:HasWeaponType(WeaponType.WEAPON_ROCKETS)
    ) then
        if not REVEL.GetData(e).BirthControlled then
            e.Visible = false
            e.OrbitDistance = Vector.Zero
            REVEL.GetData(e).BirthControlled = true
        end
    elseif REVEL.GetData(e).BirthControlled then
        e.Visible = true
        e.OrbitDistance = EntityFamiliar.GetOrbitDistance(4)
        REVEL.GetData(e).BirthControlled = nil
    end
end, FamiliarVariant.ANGELIC_PRISM)

if REVEL.FiendFolioCompatLoaded then
    revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
        if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
            if not REVEL.GetData(e).SpriteReplace then
                REVEL.GetData(e).SpriteReplace = true
                local spr = e:GetSprite()
                spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
                spr:LoadGraphics()
            end
    
            e.Position = e.Player.Position
        end
    end, FiendFolio.ITEM.FAMILIAR.LIL_LAMB)

    revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
        if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
            if not REVEL.GetData(e).SpriteReplace then
                REVEL.GetData(e).SpriteReplace = true
                local spr = e:GetSprite()
                spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
                spr:LoadGraphics()
            end
    
            e.Position = e.Player.Position
        end
    end, FiendFolio.ITEM.FAMILIAR.BABY_CRATER)

    revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
        if REVEL.ITEM.BCONTROL:PlayerHasCollectible(e.Player) then
            if not REVEL.GetData(e).SpriteReplace then
                REVEL.GetData(e).SpriteReplace = true
                local spr = e:GetSprite()
                spr:ReplaceSpritesheet(0, "gfx/ui/none.png")
                spr:LoadGraphics()
            end
    
            e.Position = e.Player.Position
        end
    end, FiendFolio.ITEM.FAMILIAR.DEIMOS)
end

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    -- Isaac.DebugString("2")
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
        if flag == CacheFlag.CACHE_TEARCOLOR then
            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_GHOST_BABY] > 0 then
                player.TearColor = player.TearColor * REVEL.SPECTRAL_COLOR
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_LITTLE_STEVEN] > 0 then
                player.TearColor = player.TearColor * REVEL.HOMING_COLOR
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_LITTLE_GISH] > 0 then
                player.TearColor = player.TearColor * REVEL.TAR_COLOR
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_INTRUDER] > 0 then
                player.TearColor = player.TearColor * REVEL.SPECTRAL_COLOR
            end

            if player:HasTrinket(TrinketType.TRINKET_BABY_BENDER) then
                player.TearColor = player.TearColor * REVEL.HOMING_COLOR
            end
        elseif flag == CacheFlag.CACHE_TEARFLAG then
            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_GHOST_BABY] > 0 then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_SPECTRAL
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_LITTLE_STEVEN] > 0 then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_HOMING
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_LITTLE_GISH] > 0 then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_GISH
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_INTRUDER] > 0 then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_SLOW
            end

            if player:HasTrinket(TrinketType.TRINKET_BABY_BENDER) then
                player.TearFlags = player.TearFlags | TearFlags.TEAR_HOMING
            end
        elseif flag == CacheFlag.CACHE_FIREDELAY then
            if player:HasCollectible(CollectibleType.COLLECTIBLE_ANGELIC_PRISM) 
            and not (
                player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) 
                or player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE)
                or player:HasWeaponType(WeaponType.WEAPON_LASER) 
                or player:HasWeaponType(WeaponType.WEAPON_ROCKETS)
            ) then
                player.MaxFireDelay = math.ceil(player.MaxFireDelay * 1.75)
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM] > 0 then
                if REVEL.room:GetType() == RoomType.ROOM_BOSS then
                    player.MaxFireDelay = math.ceil(player.MaxFireDelay * 0.5)
                end
            end
        elseif flag == CacheFlag.CACHE_DAMAGE then
            if revel.data.run.bcSynergyes[REVEL.ITEM.ENVYS_ENMITY.id] > 0 then
                local data = player:GetData()
                data.bcEnvyEnmnitySplits = data.bcEnvyEnmnitySplits or 0
                if data.bcEnvyEnmnitySplits > 0 then
                    local damageToAdd = 1
                    for i = 1, data.bcEnvyEnmnitySplits do
                        damageToAdd = damageToAdd * 2
                    end
                    damageToAdd = (damageToAdd * revel.data.run.bcSynergyes[REVEL.ITEM.ENVYS_ENMITY.id]) 
                        - revel.data.run.bcSynergyes[REVEL.ITEM.ENVYS_ENMITY.id]
                    damageToAdd = damageToAdd * 0.2
                    player.Damage = player.Damage + damageToAdd
                end
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM] > 0 then
                if REVEL.room:GetType() == RoomType.ROOM_BOSS then
                    player.Damage = player.Damage * 2
                end
            end
        elseif flag == CacheFlag.CACHE_SPEED then
            if player:HasTrinket(TrinketType.TRINKET_CHILD_LEASH) then
                player.MoveSpeed = 1
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(_)
    if REVEL.room:IsFirstVisit() then
        for _, player in ipairs(REVEL.players) do
            if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
                if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_HALLOWED_GROUND] > 0 then
                    local index, grid
                    for i=1, 3 do
                        index = REVEL.room:GetRandomTileIndex(i*math.random(10,100))
                        grid = REVEL.room:GetGridEntity(index)
                        if grid then
                            break
                        end
                    end
                    if grid then
                        grid:Destroy(true)
                        REVEL.room:SpawnGridEntity(index, 14, 6, REVEL.level:GetCurrentRoomDesc().SpawnSeed, 0)
                    end
                end
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(ent, amount, flags, source, countdown)
    local player = ent:ToPlayer()
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
        if revel.data.run.bcSynergyes[REVEL.ITEM.ENVYS_ENMITY.id] > 0 then
            local data = player:GetData()
            data.bcEnvyEnmnitySplits = data.bcEnvyEnmnitySplits or 0
            data.bcEnvyEnmnitySplits = data.bcEnvyEnmnitySplits + 1
            data.bcEnvyEnmnitySplits = math.min(data.bcEnvyEnmnitySplits, 3)
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end

        --[[if REVEL.FiendFolioCompatLoaded then
            if revel.data.run.bcSynergyes[FiendFolio.ITEM.COLLECTIBLE.ROBOBABY3] > 0 then
                for i = 45, 360, 45 do
                    local laser = EntityLaser.ShootAngle(2, player.Position, i, 3, Vector(0, -20), player)
                    laser.CollisionDamage = 3.5
                    laser:Update()
                end
            end
        end]]
    end
end, EntityType.ENTITY_PLAYER)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _, player in ipairs(REVEL.players) do
        if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
            if revel.data.run.bcSynergyes[REVEL.ITEM.ENVYS_ENMITY.id] > 0 then
                local data = player:GetData()
                data.bcEnvyEnmnitySplits = 0
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:EvaluateItems()
            end

            if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM] > 0 then
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
                player:EvaluateItems()
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 2,
                        function(tear, data, sprite, player)
    if player and REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
        local bandageBabyNum = revel.data.run.bcSynergyes[REVEL.ITEM.BANDAGE_BABY.id]
        if bandageBabyNum > 0 then
            local data = REVEL.GetData(player)

            local startingShotsTilBandageBall = 10 - ((bandageBabyNum - 1) * 2)
            data.ShotsTilBandageBall = data.ShotsTilBandageBall or startingShotsTilBandageBall
            data.LastBandageBallShotTime = data.LastBandageBallShotTime or Isaac.GetFrameCount()

            if Isaac.CountEntities(nil, REVEL.ENT.BANDAGE_BABY_BALL.id, REVEL.ENT.BANDAGE_BABY_BALL.variant) < 3 then
                data.ShotsTilBandageBall = data.ShotsTilBandageBall - 1

                if data.ShotsTilBandageBall <= 0 and Isaac.GetFrameCount() > data.LastBandageBallShotTime + 90 then
                    data.ShotsTilBandageBall = startingShotsTilBandageBall
                    data.LastBandageBallShotTime = Isaac.GetFrameCount()

                    local ball = REVEL.ENT.BANDAGE_BABY_BALL:spawn(
                        player.Position, tear.Velocity,
                        player
                    )
                    REVEL.sfx:Play(SoundEffect.SOUND_FETUS_JUMP, 0.9)

                    REVEL.ZPos.SetData(ball, {
                        ZVelocity = 2,
                        ZPosition = 10,
                        Gravity = 0.1,
                        Bounce = 0,
                        DoRotation = true,
                        RotationOffset = 56,
                        DisableCollision = false,
                        EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.DONT_HANDLE,
                        BounceFromGrid = false,
                        LandFromGrid = false
                    })
                    REVEL.ZPos.UpdateEntity(ball)
                    REVEL.GetData(ball).Init = true

                    tear:Remove()
                end
            else
                data.ShotsTilBandageBall = 0
            end
        end

        -- if revel.data.run.bcSynergyes[REVEL.ITEM.WILLO.id] > 0 then
        --     if math.random(1,10) <= math.max(1,math.min(5,(player.Luck/2))) then
        --         tear:AddTearFlags(TearFlags.TEAR_HOMING)
        --         tear:GetSprite().Color = player.TearColor * REVEL.HOMING_COLOR
        --     end
        -- end

        if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_FRUITY_PLUM] > 0 then
            tear.Scale = tear.Scale * math.random(8,12)/10
            tear.Velocity = tear.Velocity:Rotated(math.random(-10,10))
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, tear, collider)
    if tear.SpawnerEntity then
        local player = tear.SpawnerEntity:ToPlayer()
        if player then
            if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
                if revel.data.run.bcSynergyes[CollectibleType.COLLECTIBLE_HOLY_WATER] > 0 then
                    if math.random(1,10) == 1 then
                        if (Isaac.CountEntities(player, 1000,EffectVariant.PLAYER_CREEP_HOLYWATER, -1) or 0) < 1 then
                            REVEL.sfx:Play(SoundEffect.SOUND_GLASS_BREAK)
                            REVEL.SpawnCreep(EffectVariant.PLAYER_CREEP_HOLYWATER, 0, tear.Position, player, false)
                        end
                    end
                end
            end
        end
    end
end)

local extensionCordColor = Color(0, 0, 0, 1, conv255ToFloat(200, 150, 20))
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, player)
    if REVEL.ITEM.BCONTROL:PlayerHasCollectible(player) then
        local data = REVEL.GetData(player)

        if data.bcHadBabyBender == nil then
            data.bcHadBabyBender = false
        end
        if data.bcHadBabyBender ~= player:HasTrinket(TrinketType.TRINKET_BABY_BENDER) then
            data.bcHadBabyBender = player:HasTrinket(TrinketType.TRINKET_BABY_BENDER)
            player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG | CacheFlag.CACHE_TEARCOLOR)
            player:EvaluateItems()
        end

        if player:HasTrinket(TrinketType.TRINKET_DUCT_TAPE) then
            if player:GetMovementVector():Length() <= 0 then
                player.Velocity = player.Velocity * 0
            end
        end

        if data.bcHadChildLeash == nil then
            data.bcHadChildLeash = false
        end
        if data.bcHadChildLeash ~=
            player:HasTrinket(TrinketType.TRINKET_CHILD_LEASH) then
            data.bcHadChildLeash = player:HasTrinket(TrinketType.TRINKET_CHILD_LEASH)
            player:AddCacheFlags(CacheFlag.CACHE_SPEED)
            player:EvaluateItems()
        end

        if player:HasTrinket(TrinketType.TRINKET_EXTENSION_CORD) then
            data.bcExtensionCordLaserFireCountdown = data.bcExtensionCordLaserFireCountdown 
                or math.random(30, 120)
            data.bcExtensionCordLaserFireCountdown = data.bcExtensionCordLaserFireCountdown - 1

            if data.bcExtensionCordLaserFireCountdown <= 0 then
                data.bcExtensionCordLaserFireCountdown = nil

                local closeEnemy = REVEL.getClosestEnemy(player, false, true, true, true)
                if closeEnemy then
                    local laser = player:FireTechLaser(
                        player.Position, LaserOffset.LASER_TECH5_OFFSET, 
                        closeEnemy.Position - player.Position,
                        false, true
                    )
                    laser:GetSprite().Color = extensionCordColor
                end
            end
        end
    end
end)

end
