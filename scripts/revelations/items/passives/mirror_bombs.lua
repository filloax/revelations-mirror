local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Mirror Bombs

REVEL.ITEM.MIRROR_BOMBS:addPickupCallback(function (player, playerID, itemID, isD4Effect, firstTimeObtained)
    if firstTimeObtained then
        player:AddBombs(5)
    end
end)

--[[
backdrops
basement = 1
cellar = 2
burning = 3

caves = 4
catacombs = 5
flooded = 6

depths = 7
necropolis = 8
dank = 9

womb = 10
utero = 11
scarred = 12
blue = 13

sheol = 14
cathedral = 15

dark = 16
chest = 17

megasatan = 18
library = 19
shop = 20
isaac's = 21
barren = 22
secret = 23
dice = 24
arcade = 25
error = 26
bluewombentrance = 27
ultragreedshop = 28
crawlspace = 29

NEW --------------------

sacrifice = 30
downpour = 31
mines = 32
mausoleum = 33
corpse = 34
planetarium = 35

downpourentrace = 36
minesentrance = 37
mausoleumentrance = 38
corpseentrance = 39

mausoleum2 = 40
mausoleum3 = 41
mausoleum4 = 42

corpse2 = 43
corpse3 = 44

dross = 45
ashpit = 46
gehenna = 47
mortis = 48

isaacsbedroom = 49
hallway = 50
momsbedroom = 51
closet = 52
closetb = 53
dogma = 54

gideondungeon = 55
rotgundungeon = 56
beastdungeon = 57

mineshaft = 58
ashpitshaft = 59
darkcloset = 60
]]

local bombFlags = {
    "TEAR_BURN",
    "TEAR_SAD_BOMB",
    "TEAR_GLITTER_BOMB",
    "TEAR_BUTT_BOMB",
    "TEAR_STICKY",
    "TEAR_SPECTRAL",
    "TEAR_HOMING",
    "TEAR_POISON"
}

local function triggerBomb(player, position, backdrop, numShards, isFetus, radiusMultiplier)
    numShards = numShards or (REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR.id) + REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR2.id))
    radiusMultiplier = radiusMultiplier or 1

    --REVEL.DebugToConsole(backdrop)

    if backdrop == BackdropType.BASEMENT 
    or backdrop == BackdropType.ISAAC 
    then
        if not isFetus or math.random(11) == 1 then
            player:AddBlueFlies(3 + (2 * numShards), position, player)
        end
    elseif backdrop == BackdropType.CELLAR
    or backdrop == BackdropType.SHOP
    or backdrop == BackdropType.BARREN
    or backdrop == BackdropType.GREED_SHOP
    or backdrop == BackdropType.SECRET 
    or backdrop == BackdropType.DUNGEON
    or backdrop == BackdropType.DUNGEON_GIDEON
    then
        if not isFetus or math.random(11) == 1 then
            for i = 1, 3 + (2 * numShards) do
                player:AddBlueSpider(position)
            end
        end
    elseif backdrop == BackdropType.CAVES 
    or backdrop == BackdropType.CATACOMBS 
    or backdrop == BackdropType.BLUE_WOMB_PASS 
    then
        if REVEL.STAGE.Glacier:IsStage() and backdrop == 5 then
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if not (enemy:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) or enemy:HasEntityFlags(EntityFlag.FLAG_FREEZE) or enemy:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE) or enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
                    and (not isFetus or enemy.Position:Distance(position) < 120 * radiusMultiplier) then
                    REVEL.GumFreezeEnt(enemy)
                end
            end
        elseif REVEL.STAGE.Tomb:IsStage() and backdrop == 5 then
            local randomEnemy = REVEL.getRandomEnemy(true, true)
            if randomEnemy then
                local boulder = Isaac.Spawn(REVEL.ENT.SAND_BOULDER.id, REVEL.ENT.SAND_BOULDER.variant, 0, randomEnemy.Position, Vector.Zero, player)
                boulder:GetSprite():Play("Crush", true)
                if isFetus then
                    REVEL.GetData(boulder).IsCrushingBoulder = 11
                else
                    REVEL.GetData(boulder).IsCrushingBoulder = 30
                end
            end
        else
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, position, Vector.Zero, nil)
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if not (enemy:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) or enemy:HasEntityFlags(EntityFlag.FLAG_POISON) or enemy:HasEntityFlags(EntityFlag.FLAG_NO_TARGET))
                    and (enemy.Position:Distance(position) < 60 * radiusMultiplier) then
                    enemy:AddPoison(EntityRef(player), 150+(60*numShards), 5+(2*numShards))
                end
            end
        end
    elseif backdrop == BackdropType.DEPTHS 
    or backdrop == BackdropType.NECROPOLIS 
    then
        local min, max, damage = 11, 14, 10 + (4 * numShards)
        if isFetus then
            min, max = 2, 5
            damage = player.Damage * (0.2 * numShards + 1)
        end

        for i = 1, math.random(min, max) do
            local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BONE, 0, position, RandomVector() * math.random(2,8), nil):ToTear()
            tear.FallingSpeed = math.random(-35, -20)
            tear.FallingAcceleration = 1.5
            tear.CollisionDamage = damage
        end
    elseif backdrop == BackdropType.WOMB 
    or backdrop == BackdropType.UTERO 
    or backdrop == BackdropType.SCARRED_WOMB 
    or backdrop == BackdropType.BLUE_WOMB 
    then
        local creep, tearvar
        if backdrop == 13 then
            creep = REVEL.SpawnCreep(EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, position, player, false)
            tearvar = TearVariant.BLUE
        else
            creep = REVEL.SpawnCreep(EffectVariant.PLAYER_CREEP_RED, 0, position, player, false)
            tearvar = TearVariant.BLOOD
        end

        local tearCount = math.min(numShards*4,10)
        if tearCount > 0 then
            local damage, tearScale = 25 + player.Damage, 1.3
            if isFetus then
                damage, tearScale = player.Damage, 1
            end
            for i = 1, tearCount do
                local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, tearvar, 0, position, Vector(11,0):Rotated((360/tearCount)*i), nil):ToTear()
                tear.Scale = tearScale
                tear.CollisionDamage = damage
            end
        end

        REVEL.UpdateCreepSize(creep, creep.Size * 4, true)
    elseif backdrop == BackdropType.SHEOL then
        for i = 1, 4 do
            local laser = EntityLaser.ShootAngle(1, position, i * 90, 30, Vector.Zero, player)
            laser.DisableFollowParent = true
            if numShards < 2 then
                laser.MaxDistance = 100
            end
        end

        if numShards >= 1 then
            for i = 1, 4 do
                local laser = EntityLaser.ShootAngle(1, position, i * 90 + 45, 30, Vector.Zero, player)
                laser.DisableFollowParent = true
                if numShards < 2 then
                    laser.MaxDistance = 100
                end
            end
        end
    elseif backdrop == BackdropType.DARKROOM 
    or backdrop == BackdropType.MEGA_SATAN 
    then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and enemy:IsActiveEnemy(false) then
                if isFetus then
                    enemy:TakeDamage(10 + (5 * numShards), 0, EntityRef(player), 0)
                else
                    enemy:TakeDamage(30 + (5 * numShards), 0, EntityRef(player), 0)
                end
            end
        end
    elseif backdrop == BackdropType.CHEST then
        for i = 0, 7 do
            local door, pos = REVEL.room:GetDoor(i), REVEL.room:GetDoorSlotPosition(i)
            if door and pos:Distance(position) < 100 * radiusMultiplier then
                door:Open()
            end
        end

        for _, pickup in ipairs(REVEL.roomPickups) do
            if pickup.Position:Distance(position) < 100 * radiusMultiplier + pickup.Size then
                pickup:TryOpenChest()
            end
        end

        if numShards >= 2 then
            player:UseActiveItem(CollectibleType.COLLECTIBLE_DADS_KEY, false, false, true, false)
        end
    elseif backdrop == BackdropType.BURNT_BASEMENT then
        local flame = Isaac.Spawn(1000, EffectVariant.RED_CANDLE_FLAME, 0, position, Vector.Zero, player):ToEffect()
        flame.CollisionDamage = 3.5 + (2*numShards)
        flame.Scale = 1 + (0.1*numShards)
    elseif backdrop == BackdropType.FLOODED_CAVES then
        local rand = math.random(1,3)
        local tearCount = 4
        if rand == 3 then tearCount = 6 end

        local damage = 20 + (5 * numShards)
        if isFetus then
            damage = player.Damage * (0.2 * numShards + 1)
        end
        for i = 1, tearCount do
            local tear
            if rand == 2 then
                tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, position, Vector(10,0):Rotated(((360/tearCount)*i)+45), nil):ToTear()
            else
                tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, position, Vector(10,0):Rotated((360/tearCount)*i), nil):ToTear()
            end
            tear.CollisionDamage = damage
            tear.Scale = 1.2 + (0.1 * numShards)
        end

    elseif backdrop == BackdropType.DANK_DEPTHS then
        local creep = REVEL.SpawnCreep(EffectVariant.PLAYER_CREEP_BLACK, 0, position, player, false)
        REVEL.UpdateCreepSize(creep, creep.Size * 4, true)

        local tearCount = math.min(numShards*4,12)
        if tearCount > 0 then
            local damage = 10 + (4 * numShards)
            if isFetus then
                damage = player.Damage * (0.2 * numShards + 1)
            end
            for i = 1, tearCount do
                local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, position, RandomVector() * math.random(3,6), nil):ToTear()
                tear.FallingSpeed = math.random(-35, -20)
                tear.FallingAcceleration = 1.5
                tear.CollisionDamage = damage
                tear.Color = Color(0,0,0,1)
                tear:AddTearFlags(TearFlags.TEAR_SLOW)
            end
        end

    elseif backdrop == BackdropType.DOWNPOUR 
    or backdrop == BackdropType.DOWNPOUR_ENTRANCE 
    or backdrop == BackdropType.DROSS 
    then
        local min, max, damage = 11, 14, 10 + (4 * numShards)
        if isFetus then
            min, max = 2, 5
            damage = player.Damage * (0.2 * numShards + 1)
        end

        local dross, tearType = false, TearVariant.BLUE
        if backdrop == BackdropType.DROSS then
            dross = true
            tearType = TearVariant.BLOOD
        end

        REVEL.sfx:Play(SoundEffect.SOUND_BOSS2INTRO_WATER_EXPLOSION)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 0, position, Vector.Zero, nil)

        for i = 1, math.random(min, max) do
            local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, tearType, 0, position, RandomVector() * math.random(2,8), nil):ToTear()
            tear.FallingSpeed = math.random(-35, -20)
            tear.FallingAcceleration = 1.5
            tear.CollisionDamage = damage
            if dross then 
                local color = Color(1,1,1,1)
                color:SetColorize(2.2,1.6,1.2,1)
                tear:GetSprite().Color = color
            end
        end
    elseif backdrop == BackdropType.MINES
    or backdrop == BackdropType.MINES_ENTRANCE 
    or backdrop == BackdropType.MINES_SHAFT 
    or backdrop == BackdropType.ASHPIT 
    or backdrop == BackdropType.ASHPIT_SHAFT 
    then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, position, Vector.Zero, nil)
        if numShards > 0 then
            local close = REVEL.GetNClosestEntities(position, REVEL.roomEnemies, numShards, REVEL.IsTargetableEntity, REVEL.IsNotFriendlyEntity, REVEL.IsVulnerableEnemy)
            for _, e in ipairs(close) do
                local shock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 0, position, Vector.Zero, nil):ToEffect()
                shock:SetDamageSource(EntityType.ENTITY_PLAYER)
                shock.Rotation = (e.Position - position):GetAngleDegrees()
            end
        end
    elseif backdrop == BackdropType.MAUSOLEUM
    or backdrop == BackdropType.MAUSOLEUM_ENTRANCE 
    or backdrop == BackdropType.MAUSOLEUM2 
    or backdrop == BackdropType.MAUSOLEUM3 
    or backdrop == BackdropType.MAUSOLEUM4 
    or backdrop == BackdropType.GEHENNA 
    then
        local tearCount, rotated, vec = 5, math.random(360), Vector(6,0)
        local spritesheet = "gfx/effects/effect_005_fire_purple.png"
        if isFetus then
            tearCount = 1
            vec = Vector.Zero
        end
        if backdrop == BackdropType.GEHENNA then
            spritesheet = "gfx/effects/effect_005_fire_red.png"
        end
        if REVEL.GhastlyFlame then
            for i = 1, tearCount do
                local flame = REVEL.ENT.DECORATION:spawn(position,Vector(6,0):Rotated(rotated+((360/tearCount)*i)),player)
                flame:GetSprite():ReplaceSpritesheet(0,spritesheet)
                flame.Color = REVEL.GhastlyFlame.flameColor
                flame:GetSprite():LoadGraphics()
                REVEL.GetData(flame).timeMax = 140
                REVEL.GetData(flame).time = REVEL.GetData(flame).timeMax
                REVEL.GetData(flame).homingSpeed = 0
                REVEL.GetData(flame).homingLerp = 1
                flame.CollisionDamage = player.Damage * (1+0.1*(numShards))
                flame.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                local i = #REVEL.GhastlyFlame.flames + 1

                REVEL.GhastlyFlame.flames[i] = flame
                REVEL.GhastlyFlame.flameSeeds[flame.InitSeed] = player
            end
    end
    elseif backdrop == BackdropType.CORPSE
    or backdrop == BackdropType.CORPSE_ENTRANCE 
    or backdrop == BackdropType.CORPSE2 
    or backdrop == BackdropType.CORPSE3 
    or backdrop == BackdropType.MORTIS
    or backdrop == BackdropType.DUNGEON_ROTGUT
    then
        local min, max, damage = 1, 6+(numShards*2), 25 + player.Damage
        if isFetus then
            min, max = 1, 2+(numShards)
            damage = player.Damage
        end
        local tearColor = Color(1,1,1,1)
        tearColor:SetColorize(1,1.4,0.9,1)
        for i = min, max do
            local tear = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, position, RandomVector()*12, nil):ToProjectile()
            tear:GetSprite().Color = tearColor
            tear:AddProjectileFlags(ProjectileFlags.BURST)
            tear:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
            tear:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
            tear.Scale = 2
            tear.CollisionDamage = damage
        end

        local gas = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, position, Vector.Zero, player):ToEffect()
        gas:SetTimeout(200)
    elseif backdrop == BackdropType.ARCADE then
        if not isFetus then
            local rand = math.random(1,10)
            if rand <= 4 + math.min(3,numShards) then
                for i=1, math.random(1,2) do
                    Isaac.Spawn(5, PickupVariant.PICKUP_COIN, 0, position, RandomVector()*2, player)
                end
            end
        end
    elseif backdrop == BackdropType.LIBRARY then
        if not isFetus then
            local rand = math.random(1,10)
            if rand <= 1 + math.min(3,numShards) then
                Isaac.Spawn(5, PickupVariant.PICKUP_TAROTCARD, 0, position, Vector.Zero, player)
            end
        end
    elseif backdrop == BackdropType.SACRIFICE then
        if not isFetus then
            local rand = math.random(1,10)
            if rand <= 1 + math.min(3,numShards) then
                if math.random(2) == 1 then
                    Isaac.Spawn(5, PickupVariant.PICKUP_HEART, 1, position, Vector.Zero, player)
                else
                    Isaac.Spawn(5, PickupVariant.PICKUP_HEART, 2, position, Vector.Zero, player)
                end
            end
        end
    elseif backdrop == BackdropType.PLANETARIUM then
        if not isFetus then
            local rand = math.random(1,10)
            if rand <= 1 + math.min(3,numShards) then
                Isaac.Spawn(5, 301, 0, position, Vector.Zero, player)
            end
        end
    elseif backdrop == BackdropType.DICE then
        if not isFetus then
            local rand = math.random(1,6)
            if rand == 1 then
                player:UseCard(Card.CARD_REVERSE_WHEEL_OF_FORTUNE, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
            else
                REVEL.sfx:Play(SoundEffect.SOUND_THUMBS_DOWN)
            end
        end
    elseif backdrop == BackdropType.ERROR_ROOM then
        if not isFetus then
            local rand = math.random(1,10)
            if rand == 1 then
                local item = Isaac.Spawn(5, 100, 0, position, Vector.Zero, player)
                item:AddEntityFlags(EntityFlag.FLAG_GLITCH)
                item:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            elseif rand <= 4 + math.min(3,numShards) then 
                local pickup = Isaac.Spawn(5, 0, 0, position, Vector.Zero, player)
                pickup:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            else
                local enemy = Isaac.Spawn(math.random(10,18), 0, 0, position, Vector.Zero, player)
                enemy:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            end
        end
    end
end

local bombsTriggered = {}

StageAPI.AddCallback("Revelations", RevCallbacks.BOMB_UPDATE_INIT, 1, function(bomb)
    local data = REVEL.GetData(bomb)
    
    if not (data.__player and REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(data.__player)) then return end
    bombsTriggered[bomb.InitSeed] = nil
    
    if not REVEL.ITEM.SPONGE:PlayerHasCollectible(data.__player) then 
        REVEL.SetBombGFX(bomb) 
    end
    
    --local backdrop = REVEL.room:GetBackdropType()
    --[[local numShards = REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR.id) 
        + REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR2.id)]]
end)

revel:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    local data = REVEL.GetData(bomb)
    if not (data.__player and REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(data.__player)) then return end

    local numShards = REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR.id) + REVEL.GetCollectibleSum(REVEL.ITEM.MIRROR2.id)

    local backdrop = REVEL.room:GetBackdropType()

    if not backdrop then
        backdrop = 1
    end

    if not bomb:IsDead() and backdrop == BackdropType.CATHEDRAL then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy.Position:Distance(bomb.Position) < 100 * bomb.RadiusMultiplier + enemy.Size then
                enemy:TakeDamage(0.5 + (0.5 * numShards), 0, EntityRef(bomb), 0)
            end
        end
    end

    if backdrop == BackdropType.ERROR_ROOM then
        if bomb.FrameCount >= 40 then
            bombsTriggered[bomb.InitSeed] = true
            triggerBomb(data.__player, bomb.Position, backdrop, numShards, bomb.IsFetus, bomb.RadiusMultiplier)
            REVEL.BombsGFX[bomb.InitSeed] = nil
            bomb:Remove()
        end
    end

    if bomb:IsDead() and not bombsTriggered[bomb.InitSeed] then
        bombsTriggered[bomb.InitSeed] = true
        triggerBomb(data.__player, bomb.Position, backdrop, numShards, bomb.IsFetus, bomb.RadiusMultiplier)
        REVEL.BombsGFX[bomb.InitSeed] = nil
    end
end)

local bombHalo = REVEL.LazyLoadLevelSprite{
    ID = "mb_bombHalo",
    Anm2 = "gfx/tearhalo.anm2",
    Animation = "Idle",
}
local LastBombHaloUpdateFrame = -1
local relativeScale = Vector(1, 1) / 100

revel:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, function(_, bomb, renderOffset)
    local data = REVEL.GetData(bomb)
    if REVEL.room:GetBackdropType() ~= BackdropType.CATHEDRAL 
    or not (data.__player and REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(data.__player)) 
    then
        return
    end

    if LastBombHaloUpdateFrame ~= REVEL.game:GetFrameCount() then
        bombHalo:Update()
        LastBombHaloUpdateFrame = REVEL.game:GetFrameCount()
    end

    if not bomb:IsDead() then
        bombHalo.Scale = relativeScale * 100 * bomb.RadiusMultiplier
        bombHalo:Render(Isaac.WorldToScreen(bomb.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, e)
    local data = REVEL.GetData(e)
    if e.Variant == EffectVariant.ROCKET 
    and data.__player 
    and REVEL.ITEM.MIRROR_BOMBS:PlayerHasCollectible(data.__player) then
        triggerBomb(data.__player, e.Position, REVEL.room:GetBackdropType(), nil, true)
    end
end, 1000)
end