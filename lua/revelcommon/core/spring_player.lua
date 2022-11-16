REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function REVEL.SpringPlayer(player, isTutorial, changeInitialHeight)
    local data = player:GetData()
    if data.springHeight or player:GetSprite():IsPlaying("Jump") then return end
    
    if isTutorial then
        data.springFallingSpeed = -5
        data.springFallingAccel = 0.20
    else
        data.springFallingSpeed = -4
        data.springFallingAccel = 0.23
    end
    
    if not data.springSafePosition then
        data.springSafePosition = player.Position
    end
    
    data.springIsTutorial = isTutorial
    if not changeInitialHeight then
        data.springHeight = -15
    else
        data.springHeight = changeInitialHeight
    end
    data.SpringPeaked = false
    data.springStartOffset = REVEL.CloneVec(player.SpriteOffset)
    data.origColl = player.EntityCollisionClass
    data.origGridColl = player.GridCollisionClass
    player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    player.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    --  data.springVel = REVEL.CloneVec(player.Velocity)*0.75
    
    if data.springPitfalling then
        player:StopExtraAnimation()
        player.Visible = true
        REVEL.UnlockPlayerControls(player, "Spring")
        data.springPitfalling = nil
        data.springPitfallingTime = nil
    end
    
    data.JumpWasVisible = player.Visible
    player.Visible = false
    
    local springMan = Isaac.Spawn(REVEL.ENT.SPRING_MANAGER.id, REVEL.ENT.SPRING_MANAGER.variant, 0, player.Position, Vector.Zero, player)
    springMan:GetData().SpringManaging = player
    player:GetData().SpringManager = springMan
    
    --  REVEL.DebugToString("Spring!")
end

revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
    if action == ButtonAction.ACTION_ITEM and hook == InputHook.IS_ACTION_TRIGGERED and entity and entity:GetData().springHeight then
        return false
    end
end)

    
revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local data,spr = player:GetData(), player:GetSprite()
    
    if data.springHeight then
        player.FireDelay = player.MaxFireDelay
    
        local minSpeed = 5.5
        local movement = player:GetMovementVector()
        local velLength = player.Velocity:Length()
        if velLength < minSpeed then
            player.Velocity = REVEL.Lerp(player.Velocity, player.Velocity + movement * (minSpeed - velLength), 0.35)
        end
        --player:MultiplyFriction(1.15)
    
        if not data.SpringManager or not data.SpringManager:Exists() then
            player.SpriteOffset = Vector.Zero
            data.springHeight = nil
            player.EntityCollisionClass = data.origColl
            player.GridCollisionClass = data.origGridColl
            player.Visible = true
            data.SpringManager = nil
            data.springSafePosition = nil
        end
    elseif data.springPitfalling then
        if spr:IsFinished("FallIn") then
            player.Position = data.pitfallPos
            data.maxPitDmg = true
            player:TakeDamage(1, DamageFlag.DAMAGE_PITFALL, EntityRef(data.springPitfalling), 25)
            data.maxPitDmg = false
            player.Visible = false
            player.Velocity = Vector.Zero
            player:StopExtraAnimation()
            data.springPitfallingTime = 15
        
        elseif data.springPitfallingTime and data.springPitfallingTime > 0 then
            data.springPitfallingTime = data.springPitfallingTime - 1
            player.Velocity = Vector.Zero
            --      REVEL.DebugToString(data.springPitfallingTime)
        elseif not IsAnimOn(spr, "JumpOut") and data.springPitfallingTime == 0 then
            --      REVEL.DebugToString("test2")
            player.Visible = true
            player:PlayExtraAnimation("JumpOut")
            player.Velocity = RandomVector() * 15
        elseif spr:IsFinished("JumpOut") then
            player.Visible = true
            REVEL.UnlockPlayerControls(player, "Spring")
            data.springPitfalling = nil
            data.springPitfallingTime = nil
            --      REVEL.DebugToString("test3")
        end
    elseif data.springPitFalling then
        if spr:IsPlaying("JumpOut") or (not spr:IsFinished("FallIn") and not spr:IsPlaying("FallIn")) then
            local pos = data.springSafePosition or player.Position
            player.Position = Isaac.GetFreeNearPosition(pos, 0)
            data.springSafePosition = nil
            data.springPitFalling = nil
        end
    end
end)
    
function REVEL.SpawnDustParticles(position, numParticles, spawner, color, velMin, velMax, scaleMin, scaleMax)
    local offset = math.random(0, 359)
    velMin = velMin or 500
    velMax = velMax or 800
    scaleMin = scaleMin or 100
    scaleMax = scaleMax or 150
    color = color or Color(1, 1, 1, 1,conv255ToFloat( 110, 90, 60))
    for i = 1, numParticles do
        local dustVelocity = Vector.FromAngle(offset + i * (360 / numParticles)) * math.random(velMin, velMax) * 0.01
        local dust = Isaac.Spawn(1000, EffectVariant.DARK_BALL_SMOKE_PARTICLE, 0, position, dustVelocity, spawner)
        dust.Color = color
        dust.SpriteScale = Vector(1, 1) * (math.random(scaleMin, scaleMax) * 0.01)
        local extraUpdates = math.random(0,2)
        if extraUpdates > 0 then
            for i=1, extraUpdates do
                dust:Update()
            end
        end
    end
end

local function RenderJumpingPlayer(player, data, renderOffset)
    local pos = Isaac.WorldToRenderPosition(player.Position) 
        + (Vector(data.springStartOffset.X, data.springStartOffset.Y + data.springHeight) * REVEL.SCREEN_TO_WORLD_RATIO) 
        + renderOffset -- - REVEL.room:GetRenderScrollOffset()
    if data.CustomJumpSprites then
        for _, sprite in ipairs(data.CustomJumpSprites) do
            sprite:Render(pos, Vector.Zero, Vector.Zero)
        end
    else
        player.Visible = true
        player:RenderGlow(pos)
        player:RenderBody(pos)
        player:RenderHead(pos)
        player:RenderTop(pos)
    end
end

--this 1 needs 60fps (using effect as player is invisible during jump, thus render is not called)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, e, renderOffset)
    if e:GetData().SpringManaging then
        local player = e:GetData().SpringManaging
        e.Position = player.Position
        local data = player:GetData()
    
        --Sprint jump management
        if data.springHeight and not data.maxPitDmg then
            if REVEL.IsRenderPassNormal() then
                if not REVEL.game:IsPaused() and not data.maxwellDunking then
                    data.springFallingSpeed = data.springFallingSpeed + data.springFallingAccel
                    if data.springFallingSpeed > 0 then
                        data.SpringPeaked = true
                    end
                    data.springHeight = math.min(0, data.springHeight + data.springFallingSpeed)
                end
        
                if Isaac.CountEntities(nil, REVEL.ENT.MAXWELL.id, REVEL.ENT.MAXWELL.variant, -1) < 1 then
                    data.gotDunkedOn = nil
                    data.maxwellDunking = nil
                end
        
                if data.gotDunkedOn then
                    player.Velocity = player.Velocity * 0.2
                end
        
                if data.maxwellDunking then
                    player.Velocity = Vector.Zero
                end
        
                RenderJumpingPlayer(player, data, renderOffset)
        
                player.Visible = false
        
                if data.springHeight == 0 and data.springFallingSpeed > 0 then
                    data.springHeight = nil
                    data.SpringPeaked = nil
                    data.SpringManager = nil
                    player.EntityCollisionClass = data.origColl
                    player.GridCollisionClass = data.origGridColl
                    player.Visible = data.JumpWasVisible
            
                    if data.gotDunkedOn then
                        -- local poof = Isaac.Spawn(1000, EffectVariant.POOF01, 0, player.Position, Vector.Zero, nil)
                        -- poof.Color = Color(0.8, 0.65, 0.2, 1,conv255ToFloat( 0, 0, 0))
                        -- poof.RenderZOffset = player.RenderZOffset + 75
                        local dunker = data.dunker and data.dunker.Ref

                        REVEL.SpawnDustParticles(player.Position, 12, player)
            
                        data.gotDunkedOn = false
                        data.dunker = nil
                        
                        REVEL.PlaySound(REVEL.MaxwellBalance.Sounds.SlamDunkImpact)
                        player:TakeDamage(1, 0, dunker and EntityRef(dunker), 15)
                    end
            
                    e:Remove()
            
                    if not player.CanFly and REVEL.room:GetGridCollisionAtPos(player.Position) ~= 0 then
                        local grid = REVEL.room:GetGridEntityFromPos(player.Position)
                        if grid and grid.Desc.Type == GridEntityType.GRID_PIT then
                            player:AnimatePitfallIn()
                            player:GetData().springPitFalling = true
                        else
                            REVEL.SpringPlayer(player, false, 0)
                            REVEL.sfx:Play(SoundEffect.SOUND_SCAMPER, 0.5, 0, false, 1)
                        end
                    else
                        data.springSafePosition = nil
                        REVEL.sfx:Play(SoundEffect.SOUND_SCAMPER, 0.5, 0, false, 1)
                    end
                elseif data.springHeight > -11 then
                    player.EntityCollisionClass = data.origColl
                else
                    player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                end
            else
                RenderJumpingPlayer(player, data, renderOffset)
            end
        end
    end
end, REVEL.ENT.SPRING_MANAGER.variant)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player,  amount, flags, source, cooldown)
    local data = player:GetData()
    if data.springPitfalling and not data.maxPitDmg then
        return false
    end
end, 1)
  
end