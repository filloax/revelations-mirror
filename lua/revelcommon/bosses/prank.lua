local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Balance table

local prankBalance = {
    Champions = {Tomb = "Default"},

    SpawnHpTreshold = {
        Default = 0.15,
        Tomb = 0.2,
    },
}

-- Generic Prank Functions

REVEL.Pranks = {
    {
        Entity = REVEL.ENT.PRANK_GLACIER,
        Key = "prank_glacier",
        Shrine = ShrineTypes.MISCHIEF_G,
    },
    {
        Entity = REVEL.ENT.PRANK_TOMB,
        Key = "prank_tomb",
        Shrine = ShrineTypes.MISCHIEF_T,
    }
}

---@param npc Entity
---@return {Entity: RevEntDef, Key: string, Shrine: any} | boolean
function REVEL.IsPrank(npc)
    for _, prank in ipairs(REVEL.Pranks) do
        if prank.Entity:isEnt(npc) then
            return prank
        end
    end

    return false
end

function REVEL.ManagePrankTimer(npc, data)
    data = data or npc:GetData()

    if not data.PrankTimer then
        data.PrankTimer = math.random(250, 400)
    end

    if not data.StartHP then
        data.StartHP = npc.HitPoints
    end

    if npc.HitPoints < data.StartHP - npc.MaxHitPoints * 0.1 and npc.HitPoints < REVEL.GetPrankTargetHP(npc) then
        data.PrankTimer = data.PrankTimer - 5
    elseif npc.HitPoints < data.StartHP - npc.MaxHitPoints * 0.06 and npc.HitPoints < REVEL.GetPrankTargetHP(npc) + npc.MaxHitPoints * 0.06 then
        data.PrankTimer = data.PrankTimer - 3
    end

    if REVEL.GetPrankEnemyDeathTreshold() >= 0.6 then
        data.PrankTimer = data.PrankTimer - 1
    else
        data.PrankTimer = data.PrankTimer - 0.15
    end
end

function REVEL.CheckPrankablePickups(npc)
    local prankablePickups = {}
    for _, pickup in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, -1, -1, false, false)) do
        if pickup.Variant >= 50 and pickup.Variant <= 60 then
            if pickup.Variant == PickupVariant.PICKUP_CHEST or pickup.Variant == PickupVariant.PICKUP_REDCHEST then
                if (pickup:GetSprite():IsPlaying("Idle") or pickup:GetSprite():IsFinished("Idle")) and not pickup:IsDead() then
                    prankablePickups[#prankablePickups + 1] = pickup
                end
            end
        else
            if (pickup.Variant < 100 or pickup.Variant == PickupVariant.PICKUP_TAROTCARD or pickup.Variant == PickupVariant.PICKUP_TRINKET) and not pickup:IsDead() then
                prankablePickups[#prankablePickups + 1] = pickup
            end
        end
    end

    if npc then
        local prankType = REVEL.IsPrank(npc)
        local closestPrankable, minDist
        if #prankablePickups > 0 then
            for i, pickup in ripairs(prankablePickups) do
                local pickupGone
                local dist = pickup.Position:DistanceSquared(npc.Position)

                if prankType then
                    if dist < (pickup.Size + npc.Size) ^ 2 then
                        if pickup.Variant == PickupVariant.PICKUP_CHEST or pickup.Variant == PickupVariant.PICKUP_REDCHEST then
                            pickup:ToPickup():TryOpenChest()
                        else
                            pickup:GetSprite():Play("Collect", true)
                            revel.data.run[prankType.Key].pickups[#revel.data.run[prankType.Key].pickups + 1] = {pickup.Variant, pickup.SubType}
                            npc:GetData().StolenPickup = true
                            pickup:ToPickup():PlayPickupSound()
                            pickup:Die()
                        end

                        pickupGone = true
                    end
                end

                if not pickupGone then
                    if not minDist or dist < minDist then
                        minDist = dist
                        closestPrankable = pickup
                    end
                end
            end
        end

        return closestPrankable, minDist, prankablePickups
    else
        return prankablePickups
    end
end

local RoomHasPrank = false

--Enemy hp treshold, explored rooms

local hpTresTotal = 0
local hpTresCurrent = 0
local trackedMaxHealth = {} --some enemies change max hp (morphing etc)

local function countsForTreshold(e)
    return (e:IsActiveEnemy(false) or (not e:Exists() and e:ToNPC())) and not (e.Type == REVEL.ENT.PRANK_GLACIER.id or e:GetData().__friendly or e:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
end

local function getTresholdWeight(ent, maxHp, hp)
    maxHp = maxHp or ent.MaxHitPoints
    if ent:IsBoss() then
        if not hp then
            ent:GetData().PrevTrackedHealthPrank = hp
        end

        return (hp or ent.HitPoints) * 3 / maxHp
    elseif maxHp > 10 then
        return 2
    elseif maxHp == 0 then
        return 0
    else
        return 1
    end
end

function REVEL.GetPrankEnemyDeathTreshold()
    if hpTresTotal == 0 or Isaac.CountEntities(nil, REVEL.ENT.CURSED_SHRINE.id) > 0 then
        return 0.5 --in no enemy rooms, prank spawns and stays at 50% treshold
    else
        return hpTresCurrent / hpTresTotal
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    hpTresTotal = 0
    hpTresCurrent = 0
    trackedMaxHealth = {}
    for _, ent in pairs(REVEL.roomEnemies) do
        if countsForTreshold(ent) then
            hpTresTotal = hpTresTotal + getTresholdWeight(ent)
            trackedMaxHealth[ent.InitSeed] = ent.MaxHitPoints
        end
    end

    --If room starts already clear, set treshold at 50% from start (so that prank can spawn in preclear rooms)
    if REVEL.room:IsClear() then
        hpTresCurrent = hpTresTotal
        hpTresTotal = hpTresTotal * 2
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if countsForTreshold(ent) then
        hpTresCurrent = hpTresCurrent + getTresholdWeight(ent)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, function(ent)
    if countsForTreshold(ent) then
        hpTresTotal = hpTresTotal + getTresholdWeight(ent)
        trackedMaxHealth[ent.InitSeed] = ent.MaxHitPoints
    end
end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, ent)
    if countsForTreshold(ent) and trackedMaxHealth[ent.InitSeed] ~= ent.MaxHitPoints then
        if not trackedMaxHealth[ent.InitSeed] then trackedMaxHealth[ent.InitSeed] = 0 end
        local diff = getTresholdWeight(ent) - getTresholdWeight(ent, trackedMaxHealth[ent.InitSeed], ent:GetData().PrevTrackedHealthPrank)
        hpTresTotal = hpTresTotal + diff
        trackedMaxHealth[ent.InitSeed] = ent.MaxHitPoints
    end
end)

local lastLevelSeed = -1
local exploredRooms = 0

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    if REVEL.level:GetDungeonPlacementSeed() ~= lastLevelSeed then
        lastLevelSeed = REVEL.level:GetDungeonPlacementSeed()
        revel.data.run.exploredRooms = 0
    end

    if REVEL.room:IsFirstVisit() then
        revel.data.run.exploredRooms = revel.data.run.exploredRooms + 1
    end
end)

function REVEL.GetExploredRoomsPct()
    return revel.data.run.exploredRooms / REVEL.level:GetRooms().Size
end

function REVEL.GetPrankTargetHP(prank)
    return prank.MaxHitPoints * (1 - REVEL.GetExploredRoomsPct())
end

--Prank healthbar

local Bar = REVEL.LazyLoadLevelSprite{
    ID = "prankBar",
    Anm2 = "gfx/ui/ui_prankhealthbar.anm2",
    Animation = "Empty",
}
local HP = REVEL.LazyLoadLevelSprite{
    ID = "prankHP",
    Anm2 = "gfx/ui/ui_prankhealthbar.anm2",
    Animation = "Full",
}

local HpWidth = 111
local BarOffset = Vector(0, -15) --from screen bottom center
local BarOffsetBoss = Vector(0, -34) --from screen bottom center
local BaseColor = Color(230/255, 20/255, 0, 1,conv255ToFloat(0,0,0))
local HurtColor = BaseColor
local HurtColor2 = Color(148/255, 13/255, 0, 1,conv255ToFloat(0,0,0))
local HealColor = Color(236/255, 123/255, 0, 1,conv255ToFloat(0,0,0))
local HealColor2 = Color(175/255, 85/255, 0, 1,conv255ToFloat(0,0,0))

local prevPct = 1
local flashCount = 0
local healing = 0

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    healing = math.max(0, healing - 1)
    flashCount = math.max(0, flashCount - 1)
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if RoomHasPrank and REVEL.game:GetHUD():IsVisible() then
        local bot = Vector(REVEL.GetScreenCenterPosition().X, REVEL.GetScreenBottomRight().Y)
        local pranks = REVEL.filter(Isaac.FindByType(REVEL.ENT.PRANK_TOMB.id), REVEL.IsPrank)
        local totHp, totMaxHp = 0, 0
        local renderBar = false

        for _, prank in ipairs(pranks) do
            if prank:GetData().State ~= "InitialPile" then
                totHp = totHp + prank.HitPoints
                totMaxHp = totMaxHp + prank.MaxHitPoints
                renderBar = true
            end
        end

        if renderBar then
            local offset = BarOffset
            if REVEL.room:GetAliveBossesCount() > 0 then
                offset = BarOffsetBoss
            end

            local pct = totHp / totMaxHp
            if pct < prevPct then
                flashCount = 10
            elseif pct > prevPct then
                flashCount = 10
                healing = flashCount
            end

            local color = BaseColor
            if flashCount > 0 then
                if healing > 0 then
                    if flashCount % 2 == 0 then
                        color = HealColor
                    else
                        color = HealColor2
                    end
                else
                    if flashCount % 2 == 0 then
                        color = HurtColor
                    else
                        color = HurtColor2
                    end
                end
            end
            HP.Color = color

            Bar:Render(bot+offset, Vector.Zero, Vector.Zero)
            HP:Render(bot+offset, Vector.Zero, Vector((1 - pct) * HpWidth, 0))

            prevPct = pct
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    RoomHasPrank = false
end)

----------------
-- Tomb Prank --
----------------

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.PRANK_TOMB.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    if not data.State then
        if REVEL.room:IsClear() then
            data.NoLeaveOnClear = true
        end

        data.State = "WaitHpTreshold"
        npc.Visible = false
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR | EntityFlag.FLAG_NO_TARGET)
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        data.bal = REVEL.GetBossBalance(prankBalance, "Tomb")
    end

    RoomHasPrank = true

    local treshold = REVEL.GetPrankEnemyDeathTreshold()

    REVEL.ManagePrankTimer(npc, data)

    if sprite:IsEventTriggered("Raspberry") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FART, 1, 0, false, 1)
    elseif sprite:IsEventTriggered("Explode") then
        npc:BloodExplode()
        npc:Remove()
    end

    if sprite:IsEventTriggered("DMG") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1, 0, false, 1)
    elseif sprite:IsEventTriggered("NoDMG") then
        npc.Velocity = Vector.Zero
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1, 0, false, 1)
    end

    if data.State == "WaitHpTreshold" then
        npc.Velocity = Vector.Zero

        -- REVEL.DebugToConsole(treshold, data.bal.SpawnHpTreshold, hpTresTotal, hpTresCurrent, trackedMaxHealth)

        if treshold >= data.bal.SpawnHpTreshold then
            sprite:Play("SubmergedAppear", true)
            data.State = "EnterRoom"
            npc.Visible = true
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
        else
            return
        end
    end

    if data.State == "Idle" then
        data.UsePlayerMap = nil

        if not REVEL.IsUsingPathMap(REVEL.GenericFlyingChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
        end
        data.UsePlayerFlyingMap = true

        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        if not sprite:IsPlaying("Move") then
            sprite:Play("Move", true)
        end

        local targetIndex, movingRandomly, speedOverride
        local closestPrankablePickup, minDist
        if data.PrankTimer > -100 then
            closestPrankablePickup, minDist = REVEL.CheckPrankablePickups(npc)
            if closestPrankablePickup then
                targetIndex = REVEL.room:GetGridIndex(closestPrankablePickup.Position)
                speedOverride = 0.8
            end
        end

        if not closestPrankablePickup then
            local closestTrap, minDist

            if REVEL.includes(REVEL.TombSandGfxRoomTypes, StageAPI.GetCurrentRoomType()) 
            and math.floor(data.PrankTimer) % 5 == 0 
            and math.random(5) == 1 
            and npc.Position:Distance(target.Position) < 150 then
                sprite:Play("Slam", true)
                data.State = "SandSlam"
            else
                for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
                    local tdata = trap:GetData()
                    if tdata.TrapData and not tdata.Pranked and REVEL.IsTrapTriggerable(trap, tdata) then
                        local facing, alignAmount = REVEL.GetAlignment(trap.Position, target.Position)
                        if alignAmount < 50 then
                            local dist = trap.Position:DistanceSquared(npc.Position)
                            if not minDist or dist < minDist then
                                closestTrap = trap
                                minDist = dist
                            end
                        end
                    end
                end

                if closestTrap then
                    targetIndex = REVEL.room:GetGridIndex(closestTrap.Position)
                    if minDist < (npc.Size) ^ 2 then
                        sprite:Play("Slam", true)
                        data.State = "TriggerTrap"
                    end
                else
                    local validCoffin, closestCoffin, minDist
                    if treshold >= 0.5 and REVEL.room:GetAliveEnemiesCount() <= 5 then
                        for _, coffin in ipairs(Isaac.FindByType(REVEL.ENT.CORNER_COFFIN.id, REVEL.ENT.CORNER_COFFIN.variant, -1, false, false)) do
                            local cdata = coffin:GetData()
                            if cdata.IsPathable and not cdata.Pranked and (not cdata.SpawnEnemies or #cdata.SpawnEnemies == 0) then
                                local dist = coffin.Position:DistanceSquared(npc.Position)
                                if dist < 100 ^ 2 then
                                    validCoffin = coffin
                                    break
                                else
                                    if not minDist or dist < minDist then
                                        minDist = dist
                                        closestCoffin = coffin
                                    end
                                end
                            end
                        end
                    end

                    if validCoffin then
                        sprite:Play("Yell", true)
                        data.State = "TriggerCoffin"
                        data.TriggeringCoffin = validCoffin
                    elseif closestCoffin and minDist > 100 ^ 2 and math.random(15) == 1 then
                        targetIndex = REVEL.room:GetGridIndex(closestCoffin.Position)

                        if not data.SteppedOn and data.Path then
                            sprite:Play("Submerge", true)
                            data.State = "DigToCoffin"
                            data.TriggeringCoffin = closestCoffin
                        end
                    else
                        movingRandomly = true
                        data.PrankTimer = data.PrankTimer - 1
                        REVEL.MoveRandomly(npc, 360, 4, 8, 0.4, 0.9, npc.Position)
                    end
                end
            end

            if (data.PrankTimer <= 0 or (REVEL.room:IsClear() and not data.NoLeaveOnClear)) and not sprite:IsPlaying("Emerge") then
                sprite:Play("Leave", true)
                data.State = "LeaveRoom"
            end
        end

        if targetIndex then
            data.TargetIndex = targetIndex
        end

        if data.Path and not movingRandomly then
            REVEL.FollowPath(npc, speedOverride or 0.5, data.Path, true, 0.9, false, true)
        end

        if npc.Velocity:Length() > 2 then sprite.FlipX = npc.Velocity.X < 0 end
    elseif data.State == "LeaveRoom" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsFinished("Leave") then
            revel.data.run.prank_tomb.hp = npc.HitPoints / npc.MaxHitPoints
            npc:Remove()
        end
    elseif data.State == "EnterRoom" then
        if sprite:IsFinished("SubmergedAppear") then
            sprite:Play("Emerge", true)
        end

        if sprite:IsFinished("Emerge") then
            data.State = "Idle"
        end
    elseif data.State == "TriggerTrap" then
        npc.Velocity = npc.Velocity * 0.5
        if sprite:IsEventTriggered("PressButton") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            REVEL.TriggerTrapsInRange(npc.Position, npc.Size + 16, true, true)
            npc.Velocity = Vector.Zero
        end

        if sprite:IsFinished("Slam") then
            data.State = "Idle"
        end
    elseif data.State == "TriggerCoffin" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsEventTriggered("Yell") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_YELL_B, 1, 0, false, 1)
            local cdata = data.TriggeringCoffin:GetData()
            if not cdata.SpawnEnemies or #cdata.SpawnEnemies == 0 then
                cdata.Triggered = true
                cdata.AllFriendly = nil
                cdata.LastFriendly = nil
            end

            cdata.Pranked = true
        end

        if sprite:IsFinished("Yell") then
            data.TriggeringCoffin = nil
            data.State = "Idle"
        end

    elseif data.State == "SandSlam" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsFinished("Slam") then
            data.State = "Idle"
        elseif sprite:IsEventTriggered("Move") then
            npc.Velocity = (target.Position - npc.Position):Resized(15)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FETUS_JUMP, 1, 0, false, 1)
        elseif sprite:IsEventTriggered("PressButton") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1)
            local poof = Isaac.Spawn(1000,16,1,npc.Position,Vector.Zero,npc)
            local poof2 = Isaac.Spawn(1000,16,2,npc.Position,Vector.Zero,npc)
            poof.SpriteScale = Vector(0.9,0.9)
            poof.Color = REVEL.SandSplatColor
            poof2.Color = REVEL.SandSplatColor
            npc.Velocity = npc.Velocity * 0.5
            for i = 1,  REVEL.game:GetNumPlayers() do
                local player = REVEL.game:GetPlayer(i)
                if player and player.Position:Distance(npc.Position) < 100 then
                    player:GetData().PrankSanded = 300
                    player.Velocity = (player.Position - npc.Position):Resized(10)
                end
            end
        end

    elseif data.State == "DigToCoffin" then
        data.UsePlayerFlyingMap = nil

        if not REVEL.IsUsingPathMap(REVEL.GenericChaserPathMap, npc) then
            REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)
        end
        data.UsePlayerMap = true

        if sprite:IsFinished("Submerge") then
            sprite:Play("Submerged", true)
        end

        if sprite:IsPlaying("Submerged") then
            data.TargetIndex = REVEL.room:GetGridIndex(data.TriggeringCoffin.Position)
            if data.Path then
                REVEL.FollowPath(npc, 0.5, data.Path, true, 0.9)
            end

            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < (npc.Size + player.Size) ^ 2 then
                    npc.Velocity = Vector.Zero
                    npc:TakeDamage(math.min(npc.MaxHitPoints / 15, npc.HitPoints + 1), 0, EntityRef(npc), 0)
                    sprite:Play("SteppedOn", true)
                    data.SteppedOn = true
                end
            end

            if npc.Position:DistanceSquared(data.TriggeringCoffin.Position) < 80 ^ 2 then
                sprite:Play("Emerge", true)
            end
        else
            npc.Velocity = npc.Velocity * 0.9
        end

        if sprite:IsFinished("SteppedOn") then
            npc.Position = REVEL.room:FindFreePickupSpawnPosition(npc.Position, 60, true)
            sprite:Play("SubmergedAppear", true)
        end

        if sprite:IsFinished("SubmergedAppear") then
            sprite:Play("Emerge", true)
        end

        if sprite:IsFinished("Emerge") then
            if data.SteppedOn then
                sprite:Play("Move", true)
                data.State = "Stunned"
                data.StunTimer = math.random(75, 120)
            elseif npc.Position:DistanceSquared(data.TriggeringCoffin.Position) < 100 ^ 2 then
                sprite:Play("Yell", true)
                data.State = "TriggerCoffin"
            else
                data.TriggeringCoffin = nil
                data.State = "Idle"
            end
        end
    elseif data.State == "InitialPile" then
        npc.Velocity = Vector.Zero

        if not data.SteppedOn then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(npc.Position) < (npc.Size + player.Size) ^ 2 then
                    npc.Velocity = Vector.Zero
                    npc:TakeDamage(1, 0, EntityRef(npc), 0)
                    sprite:Play("SteppedOn", true)
                    data.SteppedOn = true
                end
            end
        end

        if sprite:IsFinished("SteppedOn") then
            npc.Position = REVEL.room:FindFreePickupSpawnPosition(npc.Position, 60, true)
            sprite:Play("SubmergedAppear", true)
        end

        if sprite:IsFinished("SubmergedAppear") then
            sprite:Play("Emerge", true)
        end

        if sprite:IsFinished("Emerge") then
            sprite:Play("Move", true)
            data.State = "Stunned"
            data.StunTimer = math.random(20, 40)
        end
    elseif data.State == "Stunned" then
        data.StunTimer = data.StunTimer - 1
        REVEL.MoveRandomly(npc, 360, 4, 8, 0.4, 0.9, npc.Position)
        if npc.Velocity:Length() > 2 then sprite.FlipX = npc.Velocity.X < 0 end
        if data.StunTimer <= 0 then
            data.State = "Idle"
        end
    end
end, REVEL.ENT.PRANK_TOMB.id)

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data = player:GetData()
    if data.PrankSanded then
        if data.PrankSanded > 0 then
            data.PrankSanded = data.PrankSanded - 1
            player:SetColor(Color(1,0.6,0.4), 5, 1, true, false)
            if data.PrankSanded % 2 == 0 then
                local sand = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, player.Position, RandomVector() * 4, player)
                sand.Color = Color(0,0,0,1,conv255ToFloat(60,40,20))
                sand.SpriteOffset = (Vector(0,-20 * player.SpriteScale.Y))
                sand.DepthOffset = -80
                sand:Update()
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 1, function(e, data, spr, player)
    if player:GetData().PrankSanded and player:GetData().PrankSanded > 0 and e.SpawnerType == 1 then
        local angle = math.random(8,30)
        if math.random(2) == 1 then
            angle = -angle
        end
        e.Velocity = e.Velocity:Rotated(angle)
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SPAWN_ENTITY, 1, function(info, entityList, index, doGrids, doPersistentOnly, doAutoPersistent, avoidSpawning, persistentPositions)
    for _, prank in ipairs(REVEL.Pranks) do
        if info.Data.Type == prank.Entity.id and info.Data.Variant == prank.Entity.variant then
            if (REVEL.IsShrineEffectActive(prank.Shrine) and doGrids) or StageAPI.InTestMode --[[ prank should only spawn once per valid room ]] then
                local hp = revel.data.run[prank.Key].hp
                if StageAPI.InTestMode then
                    hp = 300
                end
                if hp >= 0 and doGrids then
                    local prank = prank.Entity:spawn(REVEL.room:GetGridPosition(index), Vector.Zero, nil)
                    REVEL.SetScaledBossHP(prank)
                    prank.HitPoints = hp * prank.MaxHitPoints
                end
            else
                local currentRoom = StageAPI.GetCurrentRoom()
                if currentRoom then
                    currentRoom.Metadata:AddMetadataEntity(index, "PrankSpawnPoint")
                end
            end

            return false
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
    if ent.Variant == REVEL.ENT.PRANK_TOMB.variant then
        local data = ent:GetData()

        if ent.HitPoints - REVEL.GetDamageBuffer(ent) > REVEL.GetPrankTargetHP(ent) then
            ent.HitPoints = math.max(ent.HitPoints - amount * 1.5, ent.HitPoints - REVEL.GetDamageBuffer(ent))
        end
    end
end, REVEL.ENT.PRANK_TOMB.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
	if npc.Variant == REVEL.ENT.PRANK_TOMB.variant and REVEL.IsRenderPassNormal() then
		local data = npc:GetData()
		
		if not data.Dying and npc:HasMortalDamage() then
			npc:GetSprite():Play("Death", true)
            data.State = "Death"
			npc.Velocity = Vector.Zero
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			npc.State = NpcState.STATE_UNIQUE_DEATH
			data.Dying = true
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_SMALL, 1, 0, false, 1)
            data.DeathState = 1
		end

        if data.DeathState == 1 and npc:GetSprite():IsEventTriggered("Land") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
            data.DeathState = 2
        elseif data.DeathState == 2 and npc:GetSprite():IsFinished("Death") then
            local eff = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
            npc:BloodExplode()
            data.DeathState = nil
        end
		
		local prankType = REVEL.IsPrank(npc)
		if revel.data.run[prankType.Key].hp > 0 and data.Dying then
			revel.data.run[prankType.Key].hp = -1
            revel.data.run.prankDiscount[REVEL.GetStageChapter()] = 1
            
			for _, pickup in ipairs(revel.data.run[prankType.Key].pickups) do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, pickup[1], pickup[2], npc.Position, RandomVector(), nil)
			end
		end
	end
end, REVEL.ENT.PRANK_TOMB.id)

-------------------
-- Glacier Prank --
-------------------

--[[

Appears after n enemies have been killed (check balance table)

Attack priorities (from high priority to low priority) [hp treshold required]:
- Flies over to and steals pickups
- Room with ice hazard: kicks it, max once per room [50%]
- Chill room with fire: puts it out, max once every 10 seconds [15%]
- Throw snowball at isaac, if player has not been frozen in last 10 seconds, with 50% chance or
- Ice: either rain ice creep or slam it on the ground [25%]

]]

local function chooseAttackGlacier(npc, sprite, data, target) --done after no stealables found
    local noAttack

    if (not data.AttackCooldown or data.AttackCooldown <= 0) then
        local targetAngle = (target.Position - npc.Position):GetAngleDegrees()
        local targetDist = target.Position:DistanceSquared(npc.Position)
        local treshold = REVEL.GetPrankEnemyDeathTreshold()

        local kickHazard, closestRainableFireplace, shouldThrowSnowball

        if treshold >= 0.5 and not data.KickedIceHazard then
            for _, enemy in ipairs(REVEL.roomNPCs) do
                if enemy.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
                    kickHazard = enemy
                end
            end
        end

        local minDist
        if treshold >= 0.15 and not kickHazard then
            local fireplaces = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 0, -1, false, false)
            for _, fireplace in ipairs(fireplaces) do
                if fireplace.HitPoints > 1 then
                    local fireplaceTargetDist = target.Position:DistanceSquared(fireplace.Position)
                    if fireplaceTargetDist <= REVEL.GetChillWarmRadius() ^ 2 and (not minDist or fireplaceTargetDist < minDist) then
                        closestRainableFireplace = fireplace
                        minDist = fireplaceTargetDist
                    end
                end
            end
        end

        shouldThrowSnowball = not kickHazard and not closestRainableFireplace
                and (not target:GetData().LastChillMeltFrame or target.FrameCount - target:GetData().LastChillMeltFrame > 8 * 30)
                and not target:GetData().Frozen
                and REVEL.room:CheckLine(npc.Position, target.Position, 3, 0, false, false)
                and (not data.LastThrownSnowball or treshold < 0.25 or math.random() > 0.5)

        data.LastThrownSnowball = shouldThrowSnowball

        if kickHazard then
            data.State = "KickHazard"
            data.HazardToKick = kickHazard
        elseif closestRainableFireplace then
            data.State = "SlamOnFireplace"
            data.Fireplace = closestRainableFireplace
        elseif shouldThrowSnowball then
            data.State = "ThrowSnowball"
            sprite:Play("Throw", true)
        elseif treshold >= 0.25 then
            if math.random() > 0.6 then
                data.State = "MadRaining"
                data.RainTime = math.random(90, 120)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SKIN_PULL, 1, 0, false, 1)
                sprite:Play("RainStart", true)
            else
                data.State = "IceSlam"
            end
        else
            noAttack = true
        end

        if not noAttack then
            data.AttackCooldown = nil
        end
    else
        noAttack = true
    end

    if noAttack then
        REVEL.MoveRandomly(npc, 360, 4, 8, 0.4, 0.9, npc.Position)
        if (data.PrankTimer <= 0 or (REVEL.room:IsClear() and not data.NoLeaveOnClear)) and not sprite:IsPlaying("Appear") then
            sprite:Play("Leave", true)
            data.State = "LeaveRoom"
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if npc.Variant ~= REVEL.ENT.PRANK_GLACIER.variant then
        return
    end

    local data, sprite, target = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
    if not data.State then
         --if enough rooms are explored, or room was already clear, prank stays until the timer is out
        if REVEL.room:IsClear() or REVEL.GetPrankTargetHP(npc) < npc.MaxHitPoints * 0.2 then
            data.NoLeaveOnClear = true
        end

        data.State = "WaitHpTreshold"
        npc.Visible = false
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        npc:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR | EntityFlag.FLAG_NO_TARGET)
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        data.bal = REVEL.GetBossBalance(prankBalance, "Default")
        
        REVEL.UsePathMap(REVEL.GenericFlyingChaserPathMap, npc)
    end

    RoomHasPrank = true

    local treshold = REVEL.GetPrankEnemyDeathTreshold()

    if data.State == "WaitHpTreshold" then
        npc.Velocity = Vector.Zero

        -- REVEL.DebugToConsole(treshold, data.bal.SpawnHpTreshold, hpTresTotal, hpTresCurrent, trackedMaxHealth)

        if treshold >= data.bal.SpawnHpTreshold then
            sprite:Play("Appear", true)
            data.State = "EnterRoom"
            npc.Visible = true
            npc:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
        else
            return
        end
    end

    REVEL.ManagePrankTimer(npc, data)

    if sprite:IsEventTriggered("Raspberry") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FART, 1, 0, false, 1)
    elseif sprite:IsEventTriggered("Laugh") then
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BROWNIE_LAUGH, 1, 0, false, 1.1)
    elseif sprite:IsEventTriggered("Explode") then
        npc:BloodExplode()
        npc:Remove()
    end

    if sprite:IsEventTriggered("Land") then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    end

    if data.State == "RainOnFireplace" or data.State == "SlamOnFireplace" or data.Fireplace then
        if data.Fireplace then
            if data.Fireplace:Exists() then
                if npc.Position:DistanceSquared(data.Fireplace.Position) > (npc.Size + data.Fireplace.Size + 20) ^ 2 then
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                    if data.State ~= "RainOnFireplace" and data.State ~= "SlamOnFireplace" then
                        data.Fireplace = nil
                    end
                else
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                end
            else
                data.Fireplace = nil
            end
        end
    elseif data.State ~= "EnterRoom" then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    local isRaining, isRainingOnFirePlace
    if sprite:WasEventTriggered("Rain") or sprite:IsPlaying("Rain") then
        isRaining = true
        for _, fireplace in ipairs(Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 0, -1, false, false)) do
            if fireplace.HitPoints >= 3.5 and fireplace.Position:DistanceSquared(npc.Position) <= (fireplace.Size + npc.Size) ^ 2 then
                fireplace:TakeDamage(0.5, 0, EntityRef(npc), 0)
                isRainingOnFirePlace = true
            end
        end

        if npc.FrameCount % 3 == 0 and not isRainingOnFirePlace then
            REVEL.SpawnIceCreep(npc.Position, npc)
        end
    end

    if data.AccidentallyHitEnemy then
        if data.AccidentallyHitEnemy:Exists() then
            data.EnemyChaseTimer = data.EnemyChaseTimer or math.random(30, 45)
            data.EnemyChaseTimer = data.EnemyChaseTimer - 1
            data.AccidentallyHitEnemy.Target = npc
            if data.EnemyChaseTimer <= 0 then
                data.AccidentallyHitEnemy = nil
                data.EnemyChaseTimer = nil
            end
        else
            data.AccidentallyHitEnemy = nil
        end
    end

    data.UsePlayerFlyingMap = true

    if sprite:IsEventTriggered("Laugh") then
        --play laugh sfx
    end

    if data.State == "Idle" then
        npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        if not sprite:IsPlaying("Move") and not sprite:IsPlaying("Laugh") then
            sprite:Play("Move", true)
        end

        if data.FrozePlayerFrame then --set in glacier.lua from snowballs
            if npc.FrameCount - data.FrozePlayerFrame <= 20 then
                sprite:Play("Laugh", true)
            end
            data.FrozePlayerFrame = nil
        end

        local targetIndex, movingRandomly, speedOverride
        local closestPrankablePickup
        if data.PrankTimer > -100 then
            closestPrankablePickup = REVEL.CheckPrankablePickups(npc)
            if closestPrankablePickup then
                targetIndex = REVEL.room:GetGridIndex(closestPrankablePickup.Position)
                speedOverride = 0.8
            end
        end

        if not data.AttackCooldown then
            data.AttackCooldown = math.random(25, 35)
        end

        data.AttackCooldown = data.AttackCooldown - 1

        if not closestPrankablePickup then
            chooseAttackGlacier(npc, sprite, data, target)
        end

        if targetIndex then
            data.TargetIndex = targetIndex
        end

        if data.Path and not movingRandomly then
            REVEL.FollowPath(npc, speedOverride or 0.5, data.Path, true, 0.9, false, true)
        end

        if npc.Velocity:Length() > 2 then sprite.FlipX = npc.Velocity.X < 0 end
    elseif data.State == "ThrowSnowball" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsEventTriggered("Shoot") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
            REVEL.ShootChillSnowball(npc, npc.Position, (target.Position - npc.Position):Resized(10), REVEL.GlacierBalance.DarkIceChillDuration)
        end

        if sprite:IsEventTriggered("Sound") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_WORM_SPIT, 0.7, 0, false, 1)
        end

        if sprite:IsFinished("Throw") then
            data.State = "Idle"
        end
    elseif data.State == "RainOnFireplace" then
        npc.Velocity = npc.Velocity * 0.9 + (data.Fireplace.Position - npc.Position):Resized(1)
        if sprite:IsFinished("RainEnd") then
            data.State = "Idle"
        end

        if not isRaining and not sprite:IsPlaying("RainStart") and not sprite:IsPlaying("RainEnd") then
            if not sprite:IsPlaying("Move") then
                sprite:Play("Move", true)
            end

            if data.Fireplace.Position:DistanceSquared(npc.Position) < (npc.Size + data.Fireplace.Size + 10) ^ 2 then
                sprite:Play("RainStart", true)
            end
        else
            if sprite:IsFinished("RainStart") then
                sprite:Play("Rain", true)
            end

            if isRaining and not isRainingOnFirePlace then
                sprite:Play("RainEnd", true)
            end
        end
    elseif data.State == "MadRaining" then
        if sprite:IsFinished("RainStart") then
            sprite:Play("Rain", true)
        end

        if sprite:IsFinished("RainEnd") then
            data.State = "Idle"
        end

        if data.RainTime then
            data.RainTime = data.RainTime - 1
            if data.RainTime <= 0 and not sprite:IsPlaying("RainEnd") then
                data.RainTime = nil
                sprite:Play("RainEnd", true)
            end
        end

        if not data.TargetPosition then
            local off = RandomVector() * 80
            if not REVEL.room:IsPositionInRoom(target.Position + off, 16) then
                off = -off
            end

            data.TargetPosition = target.Position + off
        end

        npc.Velocity = npc.Velocity * 0.92 + (data.TargetPosition - npc.Position):Resized(1)
        if data.TargetPosition:DistanceSquared(npc.Position) < (npc.Size + 20) ^ 2 then
            data.TargetPosition = nil
        end
    elseif data.State == "SlamOnFireplace" then
        local dist = data.Fireplace.Position:Distance(npc.Position)

        if sprite:IsEventTriggered("Land") then
            local fires = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 0, -1, false, false)
            for _, fireplace in ipairs(fires) do
                if fireplace.HitPoints > 1 and fireplace.Position:DistanceSquared(npc.Position) <= (fireplace.Size + npc.Size + 25) ^ 2 then
                    fireplace:TakeDamage(5, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)
                end
            end
            REVEL.game:ShakeScreen(10)
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9, 0, false, 1)
        end
        if sprite:IsFinished("Slam") then
            data.State = "Idle"
        end

        if dist > 40 then
            npc.Velocity = npc.Velocity * 0.9 + (data.Fireplace.Position - npc.Position) * (1 / dist)
        else
            npc.Velocity = npc.Velocity * 0.87

            if not IsAnimOn(sprite, "Slam") then sprite:Play("Slam", true) end
        end
    elseif data.State == "KickHazard" then
        if not data.HazardToKick or not data.HazardToKick:Exists() then
            data.HazardToKick = nil
            data.State = "Idle"
        else
            local dist = data.HazardToKick.Position:Distance(npc.Position)
			local speed = npc.Velocity:Length()

            if sprite:IsEventTriggered("Hit") then
                data.HazardToKick.Velocity = data.HazardToKick.Velocity + (data.HazardToKick.Position - npc.Position):Resized(6)
                data.KickedIceHazard = true
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
            end
            if sprite:IsFinished("IceKick") then
                data.State = "Idle"
            end

            if dist > 30 + speed*10 then
                npc.Velocity = npc.Velocity * 0.9 + (data.HazardToKick.Position - npc.Position) * (1 / dist)
            else
                npc.Velocity = npc.Velocity * 0.87

                if not IsAnimOn(sprite, "IceKick") then
                    sprite.FlipX = data.HazardToKick.Position.X < npc.Position.X
                    sprite:Play("IceKick", true)
                end
            end
        end
    elseif data.State == "IceSlam" then
        local dist = target.Position:Distance(npc.Position)

        if sprite:IsEventTriggered("Land") then
            REVEL.game:ShakeScreen(5)
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.9, 0, false, 1)
            local creep = REVEL.SpawnIceCreep(npc.Position, npc)
            REVEL.UpdateCreepSize(creep, creep.Size * 5.2, true)
            creep:ToEffect():SetTimeout(180)
        end
        if sprite:IsFinished("Slam") then
            data.State = "Idle"
        end

        if dist > 120 and not sprite:IsPlaying("Slam") then
            npc.Velocity = npc.Velocity * 0.9 + (target.Position - npc.Position) * (2 / dist)
        else
            npc.Velocity = npc.Velocity * 0.87

            if not IsAnimOn(sprite, "Slam") then
                sprite:Play("Slam", true)
            end
        end
    elseif data.State == "LeaveRoom" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsFinished("Leave") then
            revel.data.run.prank_glacier.hp = npc.HitPoints / npc.MaxHitPoints
            npc:Remove()
        end
    elseif data.State == "EnterRoom" then
        npc.Velocity = npc.Velocity * 0.9
        if sprite:IsFinished("Appear") then
            data.State = "Idle"
        end
    end
end, REVEL.ENT.PRANK_GLACIER.id)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, pro)
    if pro:GetData().PrankSnowball and not pro:IsDead() then
        if not pro:GetData().PrankSnowball:Exists() then
            pro:GetData().PrankSnowball = nil
        else
            local hitEntity
            for _, enemy in ipairs(REVEL.roomNPCs) do
                if (enemy.Type ~= REVEL.ENT.PRANK_GLACIER.id or enemy.Variant ~= REVEL.ENT.PRANK_GLACIER.variant) and enemy:IsActiveEnemy(false) and not enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and enemy.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL and enemy.Position:DistanceSquared(pro.Position) < (enemy.Size + pro.Size) ^ 2 then
                    hitEntity = enemy
                end
            end

            for _, player in ipairs(REVEL.players) do
                if player.Position:DistanceSquared(pro.Position) < (player.Size + pro.Size) ^ 2 then
                    hitEntity = player
                end
            end

            if hitEntity then
                hitEntity.Velocity = hitEntity.Velocity + pro.Velocity
                if hitEntity.Type ~= EntityType.ENTITY_PLAYER and hitEntity.Type ~= REVEL.ENT.ICE_HAZARD_GAPER.id then
                    pro:GetData().PrankSnowball:GetData().AccidentallyHitEnemy = hitEntity
                end

                pro:Die()
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount, flags, source, countdown)
    if ent.Variant == REVEL.ENT.PRANK_GLACIER.variant then
        if ent.HitPoints - REVEL.GetDamageBuffer(ent) > REVEL.GetPrankTargetHP(ent) then
            ent.HitPoints = math.max(ent.HitPoints - amount * 1.5, ent.HitPoints - REVEL.GetDamageBuffer(ent))
        end
    end
end, REVEL.ENT.PRANK_GLACIER.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
	if npc.Variant == REVEL.ENT.PRANK_GLACIER.variant and REVEL.IsRenderPassNormal() then
		local data = npc:GetData()
		
		if not data.Dying and npc:HasMortalDamage() then
			npc:GetSprite():Play("Death", true)
            data.State = "Death"
			npc.Velocity = Vector.Zero
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			npc.State = NpcState.STATE_UNIQUE_DEATH
			data.Dying = true
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_SMALL, 1, 0, false, 1)
            data.DeathState = 1
		end

        if data.DeathState == 1 and npc:GetSprite():IsEventTriggered("Hit") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.WILLIWAW.DEATH_CLONE, 0.8, 0, false, 1.1)
            data.DeathState = 2
        elseif data.DeathState == 2 and npc:GetSprite():IsEventTriggered("Land") then
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
            data.DeathState = 3
        elseif data.DeathState == 3 and npc:GetSprite():IsFinished("Death") then
            npc.SplatColor = REVEL.WaterSplatColor
            local eff = Isaac.Spawn(1000, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, npc.Position, Vector.Zero, npc):ToEffect()
            eff:GetSprite().Color = npc.SplatColor
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
            npc:BloodExplode()
            data.DeathState = nil
        end
		
		local prankType = REVEL.IsPrank(npc)
		if revel.data.run[prankType.Key].hp > 0 and data.Dying then
			revel.data.run[prankType.Key].hp = -1
            revel.data.run.prankDiscount[REVEL.GetStageChapter()] = 1
            
			for _, pickup in ipairs(revel.data.run[prankType.Key].pickups) do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, pickup[1], pickup[2], npc.Position, RandomVector(), nil)
			end
		end
	end
end, REVEL.ENT.PRANK_GLACIER.id)

end