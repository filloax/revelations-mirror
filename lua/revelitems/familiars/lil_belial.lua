local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks            = require("lua.revelcommon.enums.RevCallbacks")

return function()
----------------
-- LIL BELIAL --
----------------

REVEL.LilBelialSlowdownEffectiveness = {
    [REVEL.ENT.CHUCK.id] = {
        [REVEL.ENT.CHUCK.variant] = 0.5
    },
    [REVEL.ENT.FREEZER_BURN.id] = {
        [REVEL.ENT.FREEZER_BURN.variant] = 0.25
    }
}

revel.lilbelial = {}

local FAIL_GRACE_PERIOD = 5

local stalkedEnms = {Num = 0} --shared between lil belials, structure is [InitSeed] = ent

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(REVEL.ENT.LIL_BELIAL.variant, REVEL.ITEM.LIL_BELIAL:GetCollectibleNum(player) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1), RNG())
    end
end)

local function killDeathsListQuest()

    for _, player in ipairs(REVEL.players) do

        local numLists = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DEATH_LIST)
        if numLists > 0 then

            for i=1, numLists do
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_DEATH_LIST)
            end

            REVEL.DelayFunction(function(playerToAdd, amountLists)
                for i=1, amountLists do
                    playerToAdd:AddCollectible(CollectibleType.COLLECTIBLE_DEATH_LIST, 0, false)
                end
            end, 1, {player, numLists}, false, false)

        end
    end

end

local function lilBelialReward(e, data)
    --default lil belial reward
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0, Isaac.GetFreeNearPosition(e.Position, 5), Vector.Zero, e)

    --deaths list synergy reward
    if data.HasDeathsList then

        local variant, subtype
        local spawnRandom = math.random(1,6)
        if spawnRandom == 1 then
            variant, subtype = PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL
        elseif spawnRandom == 2 then
            variant, subtype = PickupVariant.PICKUP_PILL, 0
        elseif spawnRandom == 3 then
            variant, subtype = PickupVariant.PICKUP_KEY, 0
        elseif spawnRandom == 4 then
            variant, subtype = PickupVariant.PICKUP_BOMB, 0
        elseif spawnRandom == 5 then
            variant, subtype = PickupVariant.PICKUP_COIN, CoinSubType.COIN_NICKEL
        end

        if spawnRandom == 6 then
            local cache
            local statRandom = math.random(1,6)
            local message = ""

            local player = e:ToFamiliar().Player
            local runStats = revel.data.run.stats[REVEL.GetPlayerID(player)]

            if statRandom == 1 then
                runStats.Damage = runStats.Damage + 1
                cache = CacheFlag.CACHE_DAMAGE
                message = "Damage Up"
            elseif statRandom == 2 then
                runStats.MaxFireDelay = runStats.MaxFireDelay - 1
                cache = CacheFlag.CACHE_FIREDELAY
                message = "Tears Up"
            elseif statRandom == 3 then
                runStats.ShotSpeed = runStats.ShotSpeed + 0.2
                cache = CacheFlag.CACHE_SHOTSPEED
                message = "Shot Speed Up"
            elseif statRandom == 4 then
                runStats.TearFallingSpeed = runStats.TearFallingSpeed + 0.5
                cache = CacheFlag.CACHE_RANGE
                message = "Range Up"
            elseif statRandom == 5 then
                runStats.MoveSpeed = runStats.MoveSpeed + 0.2
                cache = CacheFlag.CACHE_SPEED
                message = "Speed Up"
            elseif statRandom == 6 then
                runStats.Luck = runStats.Luck + 1
                cache = CacheFlag.CACHE_LUCK
                message = "Luck Up"
            end
            for _, player in ipairs(REVEL.players) do
                player:AddCacheFlags(cache)
                player:EvaluateItems()
                player:AnimateHappy()
                StageAPI.PlayTextStreak(message)
            end
        else
            Isaac.Spawn(EntityType.ENTITY_PICKUP, variant, subtype, Isaac.GetFreeNearPosition(e.Position, 5), Vector.Zero, e)
        end

    end

end

local BlacklistEntities = REVEL.toSet {
    EntityType.ENTITY_STONEHEAD,
    EntityType.ENTITY_STONE_EYE,
    EntityType.ENTITY_CONSTANT_STONE_SHOOTER,
    EntityType.ENTITY_BRIMSTONE_HEAD,
    EntityType.ENTITY_STONEY,
    EntityType.ENTITY_GAPING_MAW,
    EntityType.ENTITY_BROKEN_GAPING_MAW,
    REVEL.ENT.BROTHER_BLOODY.id,
}

---@param e Entity
local function isGoodTarget(e)
    return not e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
        and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
        and not e:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN)
        and e:IsVulnerableEnemy()
        and e:IsActiveEnemy(false)
        and e.MaxHitPoints > 0
        and not BlacklistEntities[e.Type]
end

local function getTargets()
    return REVEL.filter(REVEL.roomEnemies, isGoodTarget)
end

local function chooseTarget(e, spr, data, targets)
    targets = targets or getTargets()

    if data.stalkedIndex then
        stalkedEnms[data.stalkedIndex] = nil
        stalkedEnms.Num = stalkedEnms.Num - 1
        data.stalkedIndex = nil
    end

    if #targets ~= 0 and #targets ~= stalkedEnms.Num and not REVEL.room:IsClear() then
        data.State = "Stalk"
        if data.HasDeathsList then
            spr:Play("StalkStart", true)
        else
            spr:Play("Stalk", true)
        end
        -- REVEL.DebugToString({targets})
        repeat
            local i = math.random(#targets)
            local t = targets[i]
            if not stalkedEnms[t.InitSeed] then
                data.stalkedIndex = t.InitSeed
                stalkedEnms[t.InitSeed] = t
                stalkedEnms.Num = stalkedEnms.Num + 1
                t:GetData().lilbelial = e
            else
                table.remove(targets, i)
            end
        until data.stalkedIndex or #targets == 0
        -- REVEL.DebugToString(data.stalkedIndex)
    end

    if not data.stalkedIndex then
        data.State = "Idle"
        spr:Play("Idle", true)
    end
end

revel:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(_, e)
    local spr, data = e:GetSprite(), e:GetData()
    spr:Play("Idle", true)
    spr.Offset = Vector(0, -30)
    e.DepthOffset = 9999

    chooseTarget(e, spr, data)
end, REVEL.ENT.LIL_BELIAL.variant)

local function newRoom(_, isReload)
    stalkedEnms = {Num = 0}
    local lilBs = Isaac.FindByType(REVEL.ENT.LIL_BELIAL.id, REVEL.ENT.LIL_BELIAL.variant, -1, false, false)
    for i, e in ipairs(lilBs) do
        local spr, data = e:GetSprite(), e:GetData()
        local targets = getTargets()
        if not isReload then
            if spr:IsPlaying("Reward") then
                lilBelialReward(e, data)
            end
            data.rewardedThisRoom = #targets == 0
            data.stalkedIndex = nil
        end
        chooseTarget(e:ToFamiliar(), spr, data, targets)
    end
end
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_STAGEAPI_NEW_ROOM, 1, newRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 2, newRoom)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 2, function()
    local lilBs = Isaac.FindByType(REVEL.ENT.LIL_BELIAL.id, REVEL.ENT.LIL_BELIAL.variant, -1, false, false)
    local play = false
    for i, e in ipairs(lilBs) do
        local spr, data = e:GetSprite(), e:GetData()
        if data.State ~= "Fail" and not data.rewardedThisRoom then
            play = true
            data.State = "Score"
            spr:Play("Reward", true)
        end
    end

    if play then
        REVEL.sfx:Play(REVEL.SFX.LIL_BELIAL_REWARD, 0.75, 0, false, 1)
        REVEL.sfx:Play(SoundEffect.SOUND_THUMBSUP, 0.75, 0, false, 1)
    end
end)

revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    local room = REVEL.room
    local spr, data = e:GetSprite(), e:GetData()

    if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_DEATH_LIST) then

        for _, deathList in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.DEATH_SKULL, -1, false)) do
            deathList:Remove()
        end

        if not data.HasDeathsList and data.State == "Idle" then
            data.HasDeathsList = true
            spr:Load("gfx/familiar/revelcommon/little_belial_skull.anm2", true)
            spr:Play("Idle", true)
        end

    elseif data.HasDeathsList and data.State == "Idle" then
        data.HasDeathsList = false
        spr:Load("gfx/familiar/revelcommon/little_belial.anm2", true)
        spr:Play("Idle", true)
    end

    if data.State == "Idle" or data.State == "Fail" then
        if spr:IsFinished("FailStart") then
            spr:Play("Fail")
        end
        e.Velocity = (e.Player.Position-e.Position):Rotated(e.Index % 4 * 15)*0.3

    elseif data.State == "Stalk" then
        if spr:IsFinished("StalkStart") then
            spr:Play("Stalk")
        end
        local targ = stalkedEnms[data.stalkedIndex]
        e.Velocity = (targ.Position-e.Position)*0.3

        local friction
        if e.Player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_OF_BELIAL) then --EYE OF BELIAL SYNERGY
            friction = 0.5
        else
            friction = 0.75
        end
        if REVEL.LilBelialSlowdownEffectiveness[targ.Type] and REVEL.LilBelialSlowdownEffectiveness[targ.Type][targ.Variant] then
            friction = 1 - ((1 - friction) * REVEL.LilBelialSlowdownEffectiveness[targ.Type][targ.Variant])
        end
        targ:MultiplyFriction(friction)

        -- Grace period for simultaneous kills
        local triggeredFail = false
        if data.FailTimer then
            data.FailTimer = data.FailTimer - 1
            if data.FailTimer <= 0 then
                triggeredFail = true
                data.FailTimer = nil
                data.State = "Fail"
                if data.HasDeathsList then
                    spr:Play("FailStart", true)
                else
                    spr:Play("Fail", true)
                end

                --REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
                killDeathsListQuest()
            end
        end

        local completed = false

        if not triggeredFail then
            local killedTarget = not targ:Exists() or targ:IsDead() 
                or targ:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN)
            if killedTarget then
                data.State = "Score"
                data.FailTimer = nil
                data.LastScoreTime = e.FrameCount
    
                if #getTargets() ~= 0 then
                    REVEL.sfx:Play(REVEL.SFX.LIL_BELIAL_REWARD, 0.75, 0, false, 1)
                    spr:Play("Score", true)
                else
                    completed = true
                end
    
            -- Target was good and isn't anymore
            elseif not isGoodTarget(targ) then
                chooseTarget(e, spr, data)

                -- If would go to idle (aka no good targets left)
                -- then complete quest
                if data.State == "Idle" then
                    completed = true
                end
            end
        end

        if completed then
            REVEL.sfx:Play(REVEL.SFX.LIL_BELIAL_REWARD, 0.75, 0, false, 1)
            REVEL.sfx:Play(SoundEffect.SOUND_THUMBSUP, 0.75, 0, false, 1)
            local lilBs = Isaac.FindByType(REVEL.ENT.LIL_BELIAL.id, REVEL.ENT.LIL_BELIAL.variant, -1, false, false)
            for i,v in ipairs(lilBs) do --multi rewards
                v:GetSprite():Play("Reward", true)
                v:GetData().State = "Score"
                v:GetData().rewardedThisRoom = true
            end
                
            killDeathsListQuest()
        end
    elseif data.State == "Score" then
        e.Velocity = Vector.Zero
        if spr:IsFinished("Score") then
            chooseTarget(e, spr, data)
        elseif spr:IsFinished("Reward") then
            data.State = "Idle"
            spr:Play("Idle", true)
        end

        if spr:IsEventTriggered("Reward") then
            lilBelialReward(e, data)
        end
    end
end, REVEL.ENT.LIL_BELIAL.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG , function(_,    e, dmg, flag, src, invuln)
    if stalkedEnms.Num > 0 and isGoodTarget(e) then
        if src.Entity and (src.Entity.SpawnerType == 1 or src.Entity.Type == 1) then
            local data = e:GetData()
            if e.HitPoints - dmg - REVEL.GetDamageBuffer(e) <= 0
            and not stalkedEnms[e.InitSeed]
            and not (src.Entity.Type == 3 and (src.Entity.Variant == 43 or src.Entity.Variant == 73))
            then
                local lilBs = Isaac.FindByType(REVEL.ENT.LIL_BELIAL.id, REVEL.ENT.LIL_BELIAL.variant, -1, true, false)
                for i,v in ipairs(lilBs) do
                    local bdata = v:GetData()
                    if bdata.State ~= "Fail" and not bdata.FailTimer
                    and not (bdata.LastScoreTime and v.FrameCount - bdata.LastScoreTime <= FAIL_GRACE_PERIOD)
                    then
                        -- Grace period for simultaneous kills 
                        bdata.FailTimer = FAIL_GRACE_PERIOD
                    end
                end
            elseif e.HitPoints - dmg - REVEL.GetDamageBuffer(e) > 0 and stalkedEnms[e.InitSeed] then
                local edata = e:GetData()

                if not edata.damageBonusLilbelial then
                    local dmg
                    if REVEL.OnePlayerHasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL) then --BOOK OF BELIAL SYNERGY
                        dmg = 4.5
                    else
                        dmg = 1.5
                    end
                    edata.damageBonusLilbelial = true
                    e:TakeDamage(dmg, flag, src, invuln)
                end
                if edata.damageBonusLilbelial then
                    edata.damageBonusLilbelial = false
                end
            end
        end
    end
end)

end