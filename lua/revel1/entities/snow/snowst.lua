REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

------------
-- SNOWST --
------------
local direction_names = {"Down", "Up", "Right", "Left"}

local SNOW_DIP_CAP = 3

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if npc.Type == REVEL.ENT.SNOWST.id and npc.Variant == REVEL.ENT.SNOWST.variant then
        npc.SplatColor = REVEL.SnowSplatColor
        local sprite, data = npc:GetSprite(), npc:GetData()
        data.NumFramesInvisible = data.NumFramesInvisible or 0
        data.NumFramesShrieking = data.NumFramesShrieking or 0
        data.MaxNumFramesShrieking = 39

        if not data.Init then -- init
            sprite:Play("AppearDown", true)
            data.SkipNextShoot = true
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

            data.Init = true
        end

        if not data.IsShrieking then
            if data.IsInvisible then
                data.NumFramesInvisible = data.NumFramesInvisible+1
            end

            for _,dir in ipairs(direction_names) do
                if sprite:IsFinished("Appear"..dir) then
                    if data.SkipNextShoot then -- in case of first appearance where he doesn't shoot
                        sprite:Play("Disappear"..dir, true)
                        data.SkipNextShoot = false
                    else
                        sprite:Play("Shoot"..dir, true)
                    end
                    break
                end
            end

            -- turn unhittable after disappearing/shooting
            for _,dir in ipairs(direction_names) do
                if sprite:IsFinished("Disappear"..dir) or sprite:IsFinished("Shoot"..dir) then
                    data.IsInvisible = true
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    npc.Position = Vector(-100,-100)
                end
                if sprite:IsEventTriggered("Shoot") then
                    data.IsInvisible = true
                    npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                end
            end

            -- after 3 seconds of being unhittable he gets ready to teleport
            if data.NumFramesInvisible >= math.max(60, 90 - (npc.FrameCount/20)) then
                local target_pos = npc:GetPlayerTarget().Position
                for i=1, 5 do -- tries to teleport 5 times a frame in case he doesn't find a good spot
                    local r_vec = Vector((math.random()-0.5)*90,(math.random()-0.5)*90)
                    local new_pos, dir
                    if math.abs(r_vec.Y) > math.abs(r_vec.X) then
                        if r_vec.Y > 0 then -- teleport down
                            new_pos = Vector(target_pos.X+r_vec.X, target_pos.Y+120)
                            dir = "Up"
                        else -- teleport up
                            new_pos = Vector(target_pos.X+r_vec.X, target_pos.Y-120)
                            dir = "Down"
                        end
                    else
                        if r_vec.X > 0 then -- teleport right
                            new_pos = Vector(target_pos.X+120, target_pos.Y+r_vec.Y)
                            dir = "Left"
                        else -- teleport left
                            new_pos = Vector(target_pos.X-120, target_pos.Y+r_vec.Y)
                            dir = "Right"
                        end
                    end

                    if new_pos and REVEL.room:CheckLine(new_pos, target_pos, 0, 0, false, true) then
                        npc.Position = new_pos
                        sprite:Play("Appear"..dir, true)
                        data.IsInvisible = false
                        data.NumFramesInvisible = 0
                        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
                        data.SavedTargetPos = target_pos
                        break
                    end
                end
            end

            if sprite:IsEventTriggered("Shoot") then
                local spawndip = {false, false, false, false}
                local num_dips = Isaac.CountEntities(nil, REVEL.ENT.SNOWBALL.id, REVEL.ENT.SNOWBALL.variant)
                if num_dips < SNOW_DIP_CAP then
                    for i=1, math.random(1,2) do
                        while true do
                            local r = math.random(1,4)
                            if not spawndip[r] then
                                spawndip[r] = true
                                break
                            end
                        end
                    end
                end

                for i=1, 4 do
                    local proj = REVEL.ShootChillSnowball(
                        npc, 
                        npc.Position, 
                        (data.SavedTargetPos-npc.Position):Resized(8+math.random()*6):Rotated((math.random()-0.5)*30), 
                        30
                    )
                    if spawndip[i] then
                        proj:GetData().SpawnDip = true
                    end
                    proj:GetData().SnowstProjectile = true
                    proj:GetData().ProjectileSize = math.random(7,9)
                    proj.Height = -20
                    proj.FallingSpeed = -6+math.random()*-4
                    proj.FallingAccel = 0.7+math.random()*0.5
                end
                REVEL.sfx:Play(SoundEffect.SOUND_WEIRD_WORM_SPIT, 0.7, 0, false, 1)
            end
        end

        npc.Velocity = Vector.Zero
        return true
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, function(_, proj)
    local data = proj:GetData()
    if data.SnowstProjectile then
        proj:GetSprite():SetFrame("RegularTear"..tostring(proj:GetData().ProjectileSize), 0)
        if data.SpawnDip then
            for _,player in ipairs(REVEL.players) do
                if (player.Position-proj.Position):LengthSquared() <= 900 then
                    data.SpawnDip = false
                end
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if npc.Variant == REVEL.ENT.SNOWST.variant and REVEL.IsRenderPassNormal() then
        local sprite, data = npc:GetSprite(), npc:GetData()
        if not data.Dying and npc:HasMortalDamage() then
            data.IsShrieking = true
            sprite:Play("ShriekStart", true)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            data.Dying = true
            npc.State = NpcState.STATE_UNIQUE_DEATH
        end

        if data.IsShrieking and data.NumFramesShrieking then
            data.NumFramesShrieking = data.NumFramesShrieking + 0.5

            if sprite:IsFinished("ShriekStart") then
                sprite:Play("ShriekLoop", true)
            end

            if data.NumFramesShrieking % 1 == 0 and sprite:IsEventTriggered("Shriek") then
                REVEL.game:ShakeScreen(8)
                REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_THE_FORSAKEN_SCREAM, 1.7, 0, false, 2)
            end

            -- causes random ice pits to crack when he shrieks
            if sprite:IsPlaying("ShriekLoop") or sprite:IsPlaying("ShriekStart") and sprite:WasEventTriggered("Shriek") then
                if not data.FragileIce then
                    data.FragileIce = REVEL.filter(StageAPI.GetCustomGrids(nil, REVEL.GRIDENT.FRAGILE_ICE.Name), function(grid)
                        return not grid.PersistentData.Broken and not grid.PersistentData.Regenerating
                    end)
                end
                if math.random(1,4) == 1 and #data.FragileIce ~= 0 then
                    --jello
                    local ice = table.remove(data.FragileIce, math.random(#data.FragileIce))
                    if StageAPI.IsCustomGrid(ice.Index, ice.Name) then
                        ice.PersistentData.Flashing = true
                    end
                end
            end

            if data.NumFramesShrieking == data.MaxNumFramesShrieking then
                sprite:Play("ShriekEnd", true)
            end

            if sprite:IsFinished("ShriekEnd") then
                npc:Remove()
                --REVEL.TriggerChumBucket(npc)
            end
        end
    end
end, REVEL.ENT.SNOWST.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, dmg)
    if ent.Variant == REVEL.ENT.SNOWST.variant then
        if ent:GetData().IsShrieking then
            return false
        end
    end
end, REVEL.ENT.SNOWST.id)

end