local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
----------------------
-- PRIDES POSTURING --
----------------------

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for _,player in ipairs(REVEL.players) do
        if REVEL.room:IsFirstVisit() and not REVEL.room:IsClear() then
            player:GetData().pridesposturingready = true
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, player, renderOffset)
    if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal()
    and REVEL.ITEM.PRIDES_POSTURING:PlayerHasCollectible(player) and player:GetData().pridesposturingready
    and (Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex)
            or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex)
            or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex)
            or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)
    ) then
        for i=1, 4 do
            EntityLaser.ShootAngle(4, player.Position, 45+i*90, 5, Vector(0,-20), player)
        end
        --[[local had_holymantle = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        if had_holymantle then
            player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
        end]]
        player:TakeDamage(0, 
            BitOr(
                DamageFlag.DAMAGE_FAKE, 
                DamageFlag.DAMAGE_RED_HEARTS 
            ), 
            EntityRef(player), 0
        )
        REVEL.sfx:Play(SoundEffect.SOUND_REDLIGHTNING_ZAP, 0.7, 0, false, 1)
        REVEL.sfx:Stop(SoundEffect.SOUND_ISAAC_HURT_GRUNT)
        
        --[[if had_holymantle then
            player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE, true)
        end]]

        local closestenemy = nil
        local closestdistance = 10000
        for _,e in ipairs(REVEL.roomEnemies) do
            local length = (player.Position-e.Position):Length()
            if length < closestdistance then
                closestenemy = e
                closestdistance = length
            end
        end
        if closestenemy then
            if player:HasCollectible(CollectibleType.COLLECTIBLE_VIRUS) then
                closestenemy:AddPoison(EntityRef(player), 120, 5)
            end
            if player:HasCollectible(CollectibleType.COLLECTIBLE_MIDAS_TOUCH) then
                closestenemy:AddMidasFreeze(EntityRef(player), 120)
            end
            if player:HasCollectible(CollectibleType.COLLECTIBLE_E_COLI) and not closestenemy:IsBoss() then
                if player:HasCollectible(CollectibleType.COLLECTIBLE_MIDAS_TOUCH) then
                    Isaac.Spawn(EntityType.ENTITY_POOP, 1, 0, closestenemy.Position, Vector.Zero, closestenemy)
                else
                    Isaac.Spawn(EntityType.ENTITY_POOP, 0, 0, closestenemy.Position, Vector.Zero, closestenemy)
                end
                closestenemy:Remove()
            end
            if player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_BEAN) then
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 0, player.Position, Vector.Zero, player)
                for _,e in ipairs(REVEL.roomEnemies) do
                    if (player.Position-e.Position):Length() <= 100 then
                        e:TakeDamage(5, 0, EntityRef(player), 0)
                        e:AddPoison(EntityRef(player), 120, 4)
                    end
                end
            end
        end
        player:GetData().pridesposturingready = false
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(_, player, e, low)
    if REVEL.ITEM.PRIDES_POSTURING:PlayerHasCollectible(player) then
        return false
    end
end)


end