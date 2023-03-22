REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------
-- ARROWHEAD --
---------------

local function arrowhead_NpcUpdate(_, npc)
    if npc.Variant == REVEL.ENT.ARROWHEAD.variant then

        npc.SplatColor = REVEL.PurpleRagSplatColor
        local data, sprite, player = npc:GetData(), npc:GetSprite(), npc:GetPlayerTarget()
        
        REVEL.UsePathMap(REVEL.GenericChaserPathMap, npc)

        if sprite:IsFinished("Appear") or sprite:IsFinished("Rotate2") or not data.Init then --last 2 are for maxwell spawns, that disable appear anim
            data.Angle = Vector.FromAngle(math.random(1, 360))
            data.AngleRecalculateFrame = 0
            data.MaxRecalculateFrames = math.random(20, 60)
            data.IsDamaged = false
            data.State = "Wandering"
            data.Init = true
        elseif sprite:IsFinished("ShootTell") then
            data.State = "Shoot2"
            --   REVEL.sfx:Play(REVEL.SFX.COFFIN_OPEN, 0.4, 0, false, 1.02)
        elseif sprite:IsFinished("Rotate1") then
            data.State = "Shoot3"
            --   REVEL.sfx:Play(REVEL.SFX.COFFIN_OPEN, 0.4, 0, false, 1.02)
        end
        if sprite:IsOverlayFinished("ChaseTell") then
            data.ChaseFrame = 0
            data.State = "Chase"
        end

        if data.State ~= "Wandering" and data.State ~= "Chase" then
            npc.Velocity = npc.Velocity * 0.75
        end

        if data.State == "Wandering" then
            npc:AnimWalkFrame("WalkHori", "WalkVert", 0.7)
            if not sprite:IsOverlayPlaying("Head") then
                sprite:PlayOverlay("Head", true)
            end
            npc.Velocity = npc.Velocity * 0.9 + data.Angle * 0.2
            data.AngleRecalculateFrame = data.AngleRecalculateFrame + 1
            if data.AngleRecalculateFrame >= data.MaxRecalculateFrames or npc:CollidesWithGrid() then
                data.Angle = Vector.FromAngle(math.random(0, 360))
                data.MaxRecalculateFrames = math.random(20, 60)
                data.AngleRecalculateFrame = 0
            end
            if data.IsDamaged then
                data.State = "Chase Start"
            end
        elseif data.State == "Chase Start" then
            npc:AnimWalkFrame("WalkHori", "WalkVert", 1)
            if not sprite:IsOverlayPlaying("ChaseTell") then
                sprite:PlayOverlay("ChaseTell", true)
            end
            if sprite:GetOverlayFrame() == 5 then
                --REVEL.sfx:NpcPlay(npc, REVEL.SFX.ARROWHEAD_ALERT, 1, 0, false, 1)
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.FLASH_MONSTER_YELL, 1, 0, false, 1)
            end
            elseif data.State == "Chase" then
                REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, {Horizontal = "WalkHori", Vertical = "WalkVert"})
            if not sprite:IsOverlayPlaying("Chase") then
                sprite:PlayOverlay("Chase", true)
            end

            if data.Path then
                REVEL.FollowPath(npc, 1, data.Path, true, 0.9)
            else
                npc.Velocity = npc.Velocity * 0.75
            end

            data.ChaseFrame = data.ChaseFrame + 1
            if data.ChaseFrame >= 90 then
                sprite:RemoveOverlay()
                sprite.PlaybackSpeed = 1
                data.State = "Shoot1"
                sprite:Play("ShootTell", true)
            end
        elseif data.State == "Shoot1" then
            if not sprite:IsPlaying("ShootTell") then
                sprite:Play("ShootTell", true)
            end
        elseif data.State == "Shoot2" then
            if not sprite:IsPlaying("Rotate1") then
                sprite:Play("Rotate1", true)
            end
        elseif data.State == "Shoot3" then
            if not sprite:IsPlaying("Rotate2") then
                sprite:Play("Rotate2", true)
            end
        end

        if sprite:IsEventTriggered("shoot") then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.SNIPEBIP_SHOOT, 1, 0, false, 0.7)
            for i=1, 4 do
                if data.State == "Shoot2" then
                    Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(-45+(90*i)):Resized(10), npc)
                else
                    Isaac.Spawn(9, 0, 0, npc.Position, Vector.FromAngle(-90+(90*i)):Resized(10), npc)
                end
            end
        end
    end
end
revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, arrowhead_NpcUpdate, REVEL.ENT.ARROWHEAD.id)

local function arrowhead_EntityTakeDmg(_, ent, dmg, flag, source)
    if ent.Variant == REVEL.ENT.ARROWHEAD.variant then
        ent:GetData().IsDamaged = true
    end
end
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, arrowhead_EntityTakeDmg, REVEL.ENT.ARROWHEAD.id)

end