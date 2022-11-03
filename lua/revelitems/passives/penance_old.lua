REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-------------
-- PENANCE --
-------------
-- Old version

revel.penance = {}
-- won't bother changing this instance of Sprite() as it's unused anyways
revel.penanceSprite = Sprite() -- giantbook effect for penance
revel.penanceSprite:Load("gfx/ui/giantbook/giantbook.anm2", true)
revel.penanceSprite:ReplaceSpritesheet(0, "gfx/ui/giantbook/giantbook_penance.png")
revel.penanceSprite:Play("Idle", true)
revel.penanceSpritePlay = false

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if not StageAPI.IsHUDAnimationPlaying() then
        revel.penanceSprite:Update()
        revel.penanceSprite:LoadGraphics()
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_RENDER , function()
    -- giantbook animation will play if revel.penanceSpritePlay is true
    if revel.penanceSpritePlay then
        revel.penanceSpritePlay = false
        revel.penanceSprite:Play("Appear", true)
    end
    -- setting the giantbook effect to invisible
    if revel.penanceSprite:IsFinished("Appear") then
        revel.penanceSprite:Play("Idle", true)
        -- rendering the giantbook effect
    elseif revel.penanceSprite:IsPlaying("Appear") and not StageAPI.IsHUDAnimationPlaying() then
        revel.penanceSprite:Render(REVEL.GetScreenCenterPosition(), Vector.Zero, Vector.Zero)
    end
end)

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE , function(_, player, flag)
    -- updating penance stats
    if REVEL.ITEM.PENANCE:PlayerHasCollectible(player) or player:GetPlayerType() == REVEL.CHAR.SARAH.Type then
        local penanceStats = revel.data.run.penance[REVEL.GetPlayerID(player)]
        if flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed+math.min(0.6,penanceStats.sh)
        elseif flag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck+penanceStats.gh
        elseif flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage+penanceStats.bh
        elseif flag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange + (math.min(math.max(0,penanceStats.sh - 0.6), 1) * 35)
        elseif flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + math.max(0, penanceStats.sh - 1.6)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    for _, player in ipairs(REVEL.players) do
        -- changes soul, black and golden hearts into stats at the start of the floor
        if REVEL.ITEM.PENANCE:PlayerHasCollectible(player) or player:GetPlayerType() == REVEL.CHAR.SARAH.Type then
            local penanceStats = revel.data.run.penance[REVEL.GetPlayerID(player)]

            if player:GetGoldenHearts() > 0 or player:GetSoulHearts() > 0 then
                revel.penanceSpritePlay = true
            end

            penanceStats.gh = penanceStats.gh + player:GetGoldenHearts()
            player:AddGoldenHearts(-player:GetGoldenHearts())

            if player:GetHearts() > 0 or (player:GetPlayerType() == PlayerType.PLAYER_XXX and player:GetSoulHearts() > 12) then
                local soul, black = REVEL.GetNonBlackSoulHearts(player), REVEL.GetBlackHearts(player)
                if player:GetPlayerType() ~= PlayerType.PLAYER_XXX then
                    penanceStats.sh = penanceStats.sh+(soul*0.05)
                    penanceStats.bh = penanceStats.bh+(black*0.15)
                    player:AddSoulHearts(-soul - black)
                else --might work wonky with black hearts in the first 6 hearts
                    penanceStats.sh = penanceStats.sh+(math.max(0, soul - 12)*0.05)
                    penanceStats.bh = penanceStats.bh+(black*0.15)
                    player:AddSoulHearts(12-player:GetSoulHearts())
                end
            end

            player:AddCacheFlags(CacheFlag.CACHE_ALL)
            player:EvaluateItems()
        end
    end
end)

REVEL.ITEM.PENANCE:addCostumeCondition(function(player) --make costume not appear for Sarah
    return not player:GetPlayerType() == REVEL.CHAR.SARAH.Type
end)


end

REVEL.PcallWorkaroundBreakFunction()