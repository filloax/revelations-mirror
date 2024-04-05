local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

---------------
-- MUSIC BOX --
---------------

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    local data = REVEL.GetData(player)
    if data.ActiveHymnEffects then
        for i=1, data.ActiveHymnEffects do
            if flag == CacheFlag.CACHE_SHOTSPEED then
                player.ShotSpeed = player.ShotSpeed - 2
            end
            if flag == CacheFlag.CACHE_DAMAGE then
                player.Damage = player.Damage + 2
            end
            if flag == CacheFlag.CACHE_TEARFLAG then
                player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_HOMING)
            end
        end
    end
    if data.ActiveSambaEffects then
        for i=1, data.ActiveSambaEffects do
            if flag == CacheFlag.CACHE_SPEED then
                player.MoveSpeed = player.MoveSpeed + 0.3
            end
            if flag == CacheFlag.CACHE_FIREDELAY then
                player.MaxFireDelay = player.MaxFireDelay - 2
            end
            if flag == CacheFlag.CACHE_TEARFLAG then
                player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_SPECTRAL)
                player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_PIERCING)
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    local spawnLocation = player.Position
    if HasBit(useFlags, UseFlag.USE_CARBATTERY) then
        spawnLocation = spawnLocation + (RandomVector()*50)
    end
    spawnLocation = REVEL.room:GetClampedPosition(spawnLocation,0)

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, spawnLocation, Vector.Zero, player)
    Isaac.Spawn(REVEL.ENT.MUSIC_BOX.id, REVEL.ENT.MUSIC_BOX.variant, 0, spawnLocation, Vector.Zero, player)
end, REVEL.ITEM.MUSIC_BOX.id)

local resumeMusic = 0
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local sprite, data = effect:GetSprite(), REVEL.GetData(effect)

    if not data.StartedSong then
        REVEL.music:Pause()
        REVEL.music:DisableLayer()
        REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_PLACE, 1, 0, false, 1)
        local song = math.random(1, 4)
        if song == 1 then
            sprite:Play("LullabyStart", true)
        elseif song == 2 then
            sprite:Play("HymnStart", true)
        elseif song == 3 then
            sprite:Play("SambaStart", true)
        elseif song == 4 then
            sprite:Play("MetalStart", true)
        end
        data.StartedSong = true
    end

    if sprite:IsPlaying("LullabyLoop") then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local enemyData, enemySprite = REVEL.GetData(enemy), enemy:GetSprite()
                if not enemyData.OriginalFriction then
                    enemyData.OriginalFriction = enemy.Friction
                end
                if not enemyData.Sleepy then
                    enemyData.Sleepy = 100
                end
                if not enemy:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
                    enemyData.Sleepy = enemyData.Sleepy - 1
                    enemy.Friction = enemyData.OriginalFriction * (enemyData.Sleepy * 0.01)
                end
                if enemy:IsBoss() and enemyData.Sleepy <= 30 then
                    enemyData.Sleepy = 30
                elseif enemyData.Sleepy <= 0 then
                    if not enemyData.OriginalColor then
                        enemyData.OriginalColor = enemySprite.Color
                    end
                    enemySprite.Color = Color(0.5,0.5,0.5,1,conv255ToFloat(100,100,100))
                    enemy:AddEntityFlags(EntityFlag.FLAG_FREEZE)
                    enemyData.Sleepy = 100
                end
            end
        end
    elseif sprite:IsPlaying("HymnLoop") then
        local amountHymns = 0
        local musicBoxes = Isaac.FindByType(REVEL.ENT.MUSIC_BOX.id, REVEL.ENT.MUSIC_BOX.variant, -1, true)
        for i, musicBox in ipairs(musicBoxes) do
            if musicBox:GetSprite():IsPlaying("HymnLoop") then
                amountHymns = amountHymns + 1
            end
        end
        for i, player in ipairs(REVEL.players) do
            local playerData = REVEL.GetData(player)
            if not playerData.ActiveHymnEffects then
                playerData.ActiveHymnEffects = 0
            end
            if playerData.ActiveHymnEffects ~= amountHymns then
                playerData.ActiveHymnEffects = amountHymns
                player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
                player:EvaluateItems()
            end
        end
    elseif sprite:IsPlaying("SambaLoop") then
        local amountSambas = 0
        local musicBoxes = Isaac.FindByType(REVEL.ENT.MUSIC_BOX.id, REVEL.ENT.MUSIC_BOX.variant, -1, true)
        for i, musicBox in ipairs(musicBoxes) do
            if musicBox:GetSprite():IsPlaying("SambaLoop") then
                amountSambas = amountSambas + 1
            end
        end
        for i, player in ipairs(REVEL.players) do
            local playerData = REVEL.GetData(player)
            if not playerData.ActiveSambaEffects then
                playerData.ActiveSambaEffects = 0
            end
            if playerData.ActiveSambaEffects ~= amountSambas then
                playerData.ActiveSambaEffects = amountSambas
                player:AddCacheFlags(CacheFlag.CACHE_SPEED)
                player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
                player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
                player:EvaluateItems()
            end
        end
    elseif sprite:IsPlaying("MetalLoop") then
        for _, enemy in ipairs(REVEL.roomEnemies) do
            if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not enemy:IsBoss() and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local enemyData, enemySprite = REVEL.GetData(enemy), enemy:GetSprite()
                if enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) then
                    if not enemyData.CharmedFromMetal then
                        enemyData.WasAlreadyCharmed = true
                    end
                elseif not enemyData.WasAlreadyCharmed then
                    enemyData.WasAlreadyCharmed = false
                    if not enemyData.OriginalColor then
                        enemyData.OriginalColor = enemySprite.Color
                    end
                    enemySprite.Color = Color(1,0.8,0.8,1,conv255ToFloat(100,0,0))
                    enemy:AddEntityFlags(EntityFlag.FLAG_CHARM)
                    enemyData.CharmedFromMetal = true
                end
            end
        end
    end

    if data.PlayingSongCountdown then
        data.PlayingSongCountdown = data.PlayingSongCountdown - 1
        if data.PlayingSongCountdown <= 0 then
            if sprite:IsPlaying("HymnLoop") then
                for i, player in ipairs(REVEL.players) do
                    local playerData = REVEL.GetData(player)
                    if playerData.ActiveHymnEffects then
                        playerData.ActiveHymnEffects = playerData.ActiveHymnEffects - 1
                        player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
                        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                        player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
                        player:EvaluateItems()
                    end
                end
            elseif sprite:IsPlaying("SambaLoop") then
                for i, player in ipairs(REVEL.players) do
                    local playerData = REVEL.GetData(player)
                    if playerData.ActiveSambaEffects then
                        playerData.ActiveSambaEffects = playerData.ActiveSambaEffects - 1
                        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
                        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
                        player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
                        player:EvaluateItems()
                    end
                end
            elseif sprite:IsPlaying("MetalLoop") then
                for _, enemy in ipairs(REVEL.roomEnemies) do
                    if enemy:IsActiveEnemy(false) and enemy:IsVulnerableEnemy() and not enemy:IsBoss() and not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                        local enemyData, enemySprite = REVEL.GetData(enemy), enemy:GetSprite()
                        if enemyData.CharmedFromMetal then
                            enemy:ClearEntityFlags(EntityFlag.FLAG_CHARM)
                            if enemyData.OriginalColor then
                                enemySprite.Color = enemyData.OriginalColor
                            end
                        end
                    end
                end
            end
            REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_BREAK, 1, 0, false, 1)
            for i = 1, 3 do
                local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, effect.Position, Vector.FromAngle(math.random(0, 360)) * (math.random(100, 500) * 0.01), effect)
                rock:Update()
            end
            effect:Remove()
        end
    end

    if sprite:IsFinished("LullabyStart") then
        sprite:Play("LullabyLoop", true)
        sprite.PlaybackSpeed = 0.5
        REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_TUNE_LULLABY, 1, 0, false, 1)
        data.PlayingSongCountdown = 260
        resumeMusic = data.PlayingSongCountdown + 20
    elseif sprite:IsFinished("HymnStart") then
        sprite:Play("HymnLoop", true)
        sprite.PlaybackSpeed = 1.2
        REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_TUNE_HYMN, 1, 0, false, 1)
        data.PlayingSongCountdown = 320
        resumeMusic = data.PlayingSongCountdown + 20
    elseif sprite:IsFinished("SambaStart") then
        sprite:Play("SambaLoop", true)
        sprite.PlaybackSpeed = 1.2
        REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_TUNE_SAMBA, 1, 0, false, 1)
        data.PlayingSongCountdown = 300
        resumeMusic = data.PlayingSongCountdown + 20
    elseif sprite:IsFinished("MetalStart") then
        sprite:Play("MetalLoop", true)
        sprite.PlaybackSpeed = 1.5
        REVEL.sfx:Play(REVEL.SFX.MUSIC_BOX_TUNE_METAL, 1, 0, false, 1)
        data.PlayingSongCountdown = 300
        resumeMusic = data.PlayingSongCountdown + 20
    end
end, REVEL.ENT.MUSIC_BOX.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for i, player in ipairs(REVEL.players) do
        local playerData = REVEL.GetData(player)
        if playerData.ActiveHymnEffects then
            playerData.ActiveHymnEffects = 0
            player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
            player:EvaluateItems()
        end
        if playerData.ActiveSambaEffects then
            playerData.ActiveSambaEffects = 0
            player:AddCacheFlags(CacheFlag.CACHE_SPEED)
            player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            player:AddCacheFlags(CacheFlag.CACHE_TEARFLAG)
            player:EvaluateItems()
        end
    end
    if resumeMusic > 0 then
        resumeMusic = 0
        REVEL.sfx:Stop(REVEL.SFX.MUSIC_BOX_TUNE_LULLABY)
        REVEL.sfx:Stop(REVEL.SFX.MUSIC_BOX_TUNE_HYMN)
        REVEL.sfx:Stop(REVEL.SFX.MUSIC_BOX_TUNE_SAMBA)
        REVEL.sfx:Stop(REVEL.SFX.MUSIC_BOX_TUNE_METAL)
        REVEL.music:Resume()
    end
end)

local sleepyStatusSprite = REVEL.LazyLoadRunSprite{
    ID = "musicbox_sleepy",
    Anm2 = "gfx/itemeffects/revelcommon/sleepy.anm2",
    Animation = "Sleepy",
}
local LastSleepyUpdateFrame = -1

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if resumeMusic > 0 then
        resumeMusic = resumeMusic - 1
        if resumeMusic <= 0 then
            REVEL.music:Resume()
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc, renderOffset)
    local data = REVEL.GetData(npc)
    if data.Sleepy then
        if data.Sleepy == 100 and npc:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
            if npc.Visible then
                if LastSleepyUpdateFrame ~= REVEL.game:GetFrameCount() then
                    LastSleepyUpdateFrame = REVEL.game:GetFrameCount()
                    sleepyStatusSprite:Update()
                end
                sleepyStatusSprite:Render(Isaac.WorldToScreen(npc.Position + Vector(0, npc.Size * -5)) + renderOffset - REVEL.room:GetRenderScrollOffset())
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source)
    local data, sprite = REVEL.GetData(entity), entity:GetSprite()
    if data.Sleepy then
        if data.Sleepy == 100 and entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) then
            entity:ClearEntityFlags(EntityFlag.FLAG_FREEZE)
            if data.OriginalFriction then
                entity.Friction = data.OriginalFriction
            end
            if data.OriginalColor then
                sprite.Color = data.OriginalColor
            end
        end
        if data.Sleepy < 100 then
            data.Sleepy = 100
        end
    end
end)


end