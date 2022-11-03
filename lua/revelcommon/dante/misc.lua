local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local shared            = require("lua.revelcommon.dante.shared")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local singleGridOffset = Vector(40, 0)
revel:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) then
        if pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY then
            local active = REVEL.Dante.GetPhylactery(player)
            local holdingPhylactery = active == REVEL.ITEM.PHYLACTERY.id or active == REVEL.ITEM.PHYLACTERY_MERGED.id or active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id or active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id

            -- Prevent battery pickup if the active item is charged, to prevent charging
            -- pocket item
            local doWait = not REVEL.PHYLACTERY_POCKET and holdingPhylactery
            if not player:NeedsCharge(ActiveSlot.SLOT_PRIMARY) or player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == 0
            or player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY) >= REVEL.config:GetCollectible(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)).MaxCharges then
                doWait = true
            end

            if doWait then
                pickup.Wait = 10
            end
        elseif pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            local active = REVEL.Dante.GetPhylactery(player)
            local holdingPhylactery = active == REVEL.ITEM.PHYLACTERY.id or active == REVEL.ITEM.PHYLACTERY_MERGED.id or active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM.id or active == REVEL.ITEM.PHYLACTERY_PICKUP_ITEM_CHARGE.id
            if REVEL.CharonFullBan[pickup.SubType]
            or (
            not REVEL.PHYLACTERY_POCKET 
            and pickup.SubType > 0 
            and REVEL.config:GetCollectible(pickup.SubType).Type == ItemType.ITEM_ACTIVE
            and holdingPhylactery
            and (
            not player:HasCollectible(CollectibleType.COLLECTIBLE_SCHOOLBAG)
            or player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) > 0
            )) then
                pickup.Wait = 10
            end

            local data = pickup:GetData()
            if data.CharonBossChoice and not data.CharonOtherChoiceSpawned then
                data.CharonOtherChoiceSpawned = true
                local newpickup = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, pickup.Position - singleGridOffset, Vector.Zero, REVEL.player)
                newpickup:GetData().CharonBossChoice = true
                newpickup:GetData().CharonOtherChoiceSpawned = true
                local repickup = Isaac.Spawn(pickup.Type, pickup.Variant, pickup.SubType, pickup.Position + singleGridOffset, Vector.Zero, REVEL.player)
                repickup:GetData().CharonBossChoice = true
                repickup:GetData().CharonOtherChoiceSpawned = true
                pickup:Remove()
            end

            if pickup:GetData().CharonBossChoice and pickup.SubType == 0 then
                pickup:GetData().CharonBossChoice = nil
                local otherCollectibles = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)
                for _, collectible in ipairs(otherCollectibles) do
                    if collectible:GetData().CharonBossChoice and collectible.SubType ~= 0 then
                        collectible:GetData().CharonBossChoice = nil
                        --[[
                        local item = REVEL.config:GetCollectible(collectible.SubType)
                        if REVEL.Dante.IsInventoryManagedItem(collectible.SubType, item) then
                            REVEL.Dante.AddCollectibleToOtherPlayer(REVEL.player, false, item, collectible.Position)
                        end

                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, collectible.Position, Vector.Zero, nil)
                        collectible:Remove()
                        ]]
                    end
                end
            end
        elseif not revel.data.run.dante.IsCombined and pickup.Variant == PickupVariant.PICKUP_HEART then
            local totalHearts = math.floor(player:GetMaxHearts() / 2 + player:GetSoulHearts() / 2) + player:GetBoneHearts()
            if totalHearts >= 6 
            and not (
                pickup.SubType == HeartSubType.HEART_HALF 
                or pickup.SubType == HeartSubType.HEART_SCARED 
                or pickup.SubType == HeartSubType.HEART_FULL 
                or pickup.SubType == HeartSubType.HEART_BLENDED 
                or pickup.SubType == HeartSubType.HEART_DOUBLEPACK 
                or pickup.SubType == HeartSubType.HEART_ETERNAL 
                or pickup.SubType == HeartSubType.HEART_BLACK 
                or pickup.SubType == HeartSubType.HEART_GOLDEN
            ) then
                pickup.Wait = 10
            end
        end
    end
    if REVEL.HasBrokenOarEffect(player) then
        if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            if REVEL.OarFullBan[pickup.SubType] then
                pickup.Wait = 10
            end
        end
    end
end)

local isUnclearedBossRoom
revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    isUnclearedBossRoom = not REVEL.room:IsClear() and REVEL.room:GetType() == RoomType.ROOM_BOSS 
        and ((REVEL.level:GetRoomByIdx(REVEL.level:GetCurrentRoomIndex()).ListIndex == REVEL.level:GetLastBossRoomListIndex()) 
            or (REVEL.level:GetStage() == LevelStage.STAGE3_1 and HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH))
        )
end)

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup)
    if REVEL.IsDanteCharon(REVEL.player) and REVEL.room:IsClear() 
    and isUnclearedBossRoom and REVEL.level:GetStage() ~= LevelStage.STAGE3_2 
    and (REVEL.level:GetStage() ~= LevelStage.STAGE3_1 
        or not HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH) 
        or REVEL.level:GetRoomByIdx(REVEL.level:GetCurrentRoomIndex()).ListIndex ~= REVEL.level:GetLastBossRoomListIndex()
    ) then
        pickup:GetData().CharonBossChoice = true
        isUnclearedBossRoom = false
    end
end, PickupVariant.PICKUP_COLLECTIBLE)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, function()
    isUnclearedBossRoom = false
    if REVEL.IsDanteCharon(REVEL.player) and REVEL.room:GetType() == RoomType.ROOM_TREASURE and REVEL.room:IsFirstVisit() then
        if (REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER) 
        and REVEL.room:GetDoor(DoorSlot.UP0) then
            local pickup = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, -1, false, false)[1]
            if pickup then
                pickup:GetData().CharonBossChoice = true
            end
        end

        if not revel.data.run.dante.SpawnedHealthUp then
            REVEL.AddItemToRoom(CollectibleType.COLLECTIBLE_HEART)
            revel.data.run.dante.SpawnedHealthUp = true
        end
    end
end)




local previousGreedWave
local wavesCount = -1

-- Charon room controls
StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 55, function()
    local levelStage, stageType = REVEL.level:GetStage(), REVEL.level:GetStageType()

    -- first floor, or first rev/alt floor if skipped with hub
    local isStageGood = (
            levelStage == LevelStage.STAGE1_1 and (
                revel.data.run.skippedFloor 
                or (stageType ~= StageType.STAGETYPE_REPENTANCE and stageType ~= StageType.STAGETYPE_REPENTANCE_B)
            )
        ) or (revel.data.run.skippedFloor 
            and REVEL.STAGE.Glacier:IsStage() and not StageAPI.GetCurrentStage().IsSecondStage
        )
    
    if isStageGood
    and StageAPI.GetCurrentListIndex() == revel.data.run.level.dante.StartingRoomIndex then
        local backdropEntity = REVEL.ENT.DECORATION:spawn(REVEL.room:GetCenterPos(), Vector.Zero)
        backdropEntity:GetSprite():Load("gfx/backdrop/revelcommon/charon_controls.anm2", true)
        backdropEntity:GetSprite():Play("Charon", true)

        if REVEL.STAGE.Glacier:IsStage() then
            backdropEntity.Color = Color(0.75,1,1,1, 0.25, 0.25, 0.25)
        elseif stageType == StageType.STAGETYPE_AFTERBIRTH then
            backdropEntity.Color = Color(0.5,0.5, 0.5)
        else
            backdropEntity.Color = Color.Default
        end

        backdropEntity:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
    end
end)

-- Greed wave handling
function REVEL.Dante.Callbacks.Greed_PostNewLevel(isGreed)
    previousGreedWave = nil
    if isGreed then
        previousGreedWave = REVEL.level.GreedModeWave
        wavesCount = -1
    end
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    local player = REVEL.player
    if REVEL.IsDanteCharon(player) and previousGreedWave then
        local wave = REVEL.level.GreedModeWave
        if wave > previousGreedWave then
            previousGreedWave = wave
            wavesCount = wavesCount + 1

            local shouldBeCombined
            if REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED and wave > 8 then
                shouldBeCombined = true
            elseif wave > 9 then
                shouldBeCombined = true
            end

            if shouldBeCombined then
                if not revel.data.run.dante.IsCombined then
                    REVEL.Dante.Merge(player, true)
                end

                wavesCount = 0
            else
                if wavesCount >= 2 then
                    REVEL.Dante.InventorySwitch(player)

                    if not revel.data.run.dante.IsDante or revel.data.run.dante.IsCombined then
                        player:GetData().NoShotYet = true
                        player:GetData().AimBonus = 1000
                    end

                    wavesCount = 0
                end
            end
        end
    end
end)

shared.PlayerControlsDisabled = false
revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
	if shared.PlayerControlsDisabled and entity and entity:ToPlayer() and REVEL.IsDanteCharon(entity:ToPlayer()) then
		if action == ButtonAction.ACTION_LEFT
		or action == ButtonAction.ACTION_RIGHT
		or action == ButtonAction.ACTION_UP
		or action == ButtonAction.ACTION_DOWN
		or action == ButtonAction.ACTION_SHOOTLEFT
		or action == ButtonAction.ACTION_SHOOTRIGHT
		or action == ButtonAction.ACTION_SHOOTUP
		or action == ButtonAction.ACTION_SHOOTDOWN
		or action == ButtonAction.ACTION_BOMB
		or action == ButtonAction.ACTION_ITEM
		or action == ButtonAction.ACTION_PILLCARD
		or action == ButtonAction.ACTION_DROP then
            if hook == InputHook.GET_ACTION_VALUE then
                return 0
            else
				return false
			end
		end
	end
end)

-- Dante ink tears and percing shots for charon

StageAPI.AddCallback("Revelations", RevCallbacks.ON_TEAR, 1, function(tear, data, sprite, player, split)
    if player and REVEL.Dante.IsDante(player) and not REVEL.IncludesIncubusTear(tear) then
        --tear.Color = Color(40 / 255, 40 / 255, 80 / 255, 1,conv255ToFloat( 0, 0, 0))
        local tearFilename = sprite:GetFilename()
        if tearFilename == "gfx/002.000_Tear.anm2" or tearFilename == "gfx/002.001_Blood Tear.anm2" then
            sprite:ReplaceSpritesheet(0, "gfx/effects/revelcommon/ink_tears.png")
            sprite:LoadGraphics()
        end
        tear:GetData().DanteInkTear = true

        -- Synergyes

        -- Burning bush
        if REVEL.BurningBush.IsShootingFireTear() then
            tear:GetData().CustomColor = Color(0.3, 0.3, 0.5)
            tear:GetData().NoInkCreep = true
        end
    end
end)

---@param tear EntityTear
StageAPI.AddCallback("Revelations", RevCallbacks.TEAR_UPDATE_INIT, 1, function(tear)
    ---@type EntityPlayer
    local player = tear:GetData().__player
    if player and REVEL.Dante.IsDante(player) then
        local sprite = tear:GetSprite()
        local tearFilename = sprite:GetFilename()
        if tearFilename == "gfx/002.000_Tear.anm2" or tearFilename == "gfx/002.001_Blood Tear.anm2" then
            sprite:ReplaceSpritesheet(0, "gfx/effects/revelcommon/ink_tears.png")
            sprite:LoadGraphics()
        end
        tear:GetData().DanteInkTear = true
    end
end)

local TarEmitter = REVEL.SphereEmitter(5)

---@param tear EntityTear
revel:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local data = tear:GetData()
    if data.CharonPiercingEnemies then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE 
            and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK) 
            and not enemy:HasEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK) 
            and enemy.Position:DistanceSquared(tear.Position) < ((tear.Size + enemy.Size) ^ 2) 
            and not data.CharonPiercingEnemies[GetPtrHash(enemy)] then
                local usemass = math.min(65, math.max(enemy.Mass, 5))
                local multi = 1
                if enemy:IsBoss() then
                    multi = 0.4
                end

                enemy.Velocity = REVEL.Lerp(enemy.Velocity, tear.Velocity * data.KnockbackMultiplier * multi, math.min(.5, 100 / usemass))
                data.CharonPiercingEnemies[GetPtrHash(enemy)] = true
            end
        end
    elseif data.DanteInkTear and not data.NoInkCreep then
        local leaveCreepBehind = tear:HasTearFlags(TearFlags.TEAR_LUDOVICO)

        if leaveCreepBehind then
            TarEmitter:SetRadius(tear.Scale * 3)
            TarEmitter:EmitParticlesPerSec(
                REVEL.TarParticle2, 
                REVEL.TarPartSystem, 
                Vec3(tear.Position, tear.Height), 
                REVEL.VEC3_ZERO, 
                5, 
                0.05, 
                18
            )

            if tear.FrameCount % 5 == 0 then
                Isaac.Spawn(
                    EntityType.ENTITY_EFFECT, 
                    EffectVariant.PLAYER_CREEP_BLACK, 
                    0, 
                    REVEL.room:GetClampedPosition(tear.Position, 8), 
                    Vector.Zero, 
                    nil
                ):ToEffect():SetTimeout(15)
            end
        end

        if tear:IsDead() then
            Isaac.Spawn(
                EntityType.ENTITY_EFFECT, 
                EffectVariant.PLAYER_CREEP_BLACK, 
                0, 
                REVEL.room:GetClampedPosition(tear.Position, 8), 
                Vector.Zero, 
                nil
            ):ToEffect():SetTimeout(25)
            data.DanteInkTear = nil
        end
    end
end)

---@param entity Entity
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, dmg, flag, source, invuln)
    if source.Entity and source.Entity.Type == 2 
    and REVEL.GetEntFromRef(source):GetData().DanteInkTear
    and entity:IsVulnerableEnemy()
    and not entity:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    and not entity:HasEntityFlags(EntityFlag.FLAG_SLOW)
    then
        if math.random() < 0.5 then
            entity:AddSlowing(source, 50, 0.5, Color(0.5, 0.5, 0.5))
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, tear)
    if tear:GetData().DanteInkTear and not tear:GetData().NoInkCreep then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, REVEL.room:GetClampedPosition(tear.Position, 8), Vector.Zero, nil):ToEffect():SetTimeout(25)
    end
end, EntityType.ENTITY_TEAR)

end
REVEL.PcallWorkaroundBreakFunction()