return function()

-- Frost Shooter / Medium Blowy
local FreezeDistanceGrids = 4
local SnowParticleOffset = {[0] = Vector(-10, -5), Vector(0, 0), Vector(8, -5), Vector(0, -6)}

local windBaseAlpha = 0.4
local WindStartSprite = REVEL.LazyLoadRoomSprite{
    ID = "fs_WindStartSprite",
    Anm2 = "gfx/effects/revel1/freeze_laser.anm2",
    Animation = "Start",
}
local WindLineSprite = REVEL.LazyLoadRoomSprite{
    ID = "fs_WindLineSprite",
    Anm2 = "gfx/effects/revel1/freeze_laser.anm2",
    Animation = "Middle",
}
local WindEndSprite = REVEL.LazyLoadRoomSprite{
    ID = "fs_WindEndSprite",
    Anm2 = "gfx/effects/revel1/freeze_laser.anm2",
    Animation = "End",
}

local lastWindUpdate = -1

local WindSpriteOffset = {[0] = Vector(-4, -5), Vector(0, -11), Vector(4, -5), Vector(1, -9)}

local function initEnt(npc)
    local data, sprite = REVEL.GetData(npc), npc:GetSprite()

    local room = StageAPI.GetCurrentRoom()
    local dirs = room and room.Metadata:GetDirections(REVEL.room:GetGridIndex(npc.Position))
    local dirAngle = dirs and dirs[1]
    if dirAngle then
        data.Direction = REVEL.GetDirectionFromAngle(dirAngle)
        npc.SubType = data.Direction
    else
        data.Direction = npc.SubType
    end

    data.DirVector = REVEL.dirToVel[data.Direction]

    npc.State = NpcState.STATE_ATTACK2
    sprite:Play("StartShoot" .. REVEL.dirToString[data.Direction], true)

    data.FreezeRange = FreezeDistanceGrids

    local firstGrid = REVEL.room:GetGridIndex(npc.Position + data.DirVector * 40)
    local lastGrid = REVEL.room:GetGridIndex(npc.Position + data.DirVector * 40 * data.FreezeRange)

    data.FreezeAreaTL = REVEL.room:GetGridPosition(math.min(firstGrid, lastGrid)) - Vector(20, 20)
    data.FreezeAreaBR = REVEL.room:GetGridPosition(math.max(firstGrid, lastGrid)) + Vector(20, 20)

    lastWindUpdate = -1

    data.Init = true
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
    if not REVEL.ENT.FROST_SHOOTER:isEnt(npc) then return end

    local data, sprite = REVEL.GetData(npc), npc:GetSprite()

    if REVEL.game:GetFrameCount() > lastWindUpdate then
        WindStartSprite:Update()
        WindLineSprite:Update()
        WindEndSprite:Update()
        lastWindUpdate = REVEL.game:GetFrameCount()
    end
    
    -- Currently grimaces seem to have 60 fps updates
    if data.LastUpdateFrame == REVEL.game:GetFrameCount() then
        return
    end
    data.LastUpdateFrame = REVEL.game:GetFrameCount()

    if npc.State ~= NpcState.STATE_INIT and not data.Init then
        initEnt(npc)
    end

    if npc.State == NpcState.STATE_ATTACK then
        npc.State = NpcState.STATE_ATTACK2
        sprite:Play("StartShoot" .. REVEL.dirToString[data.Direction], true)

    elseif npc.State == NpcState.STATE_ATTACK2 then
        if sprite:IsFinished("StartShoot" .. REVEL.dirToString[data.Direction]) then
            sprite:Play("Shoot" .. REVEL.dirToString[data.Direction], true)
            REVEL.EnableWindSound(npc)
        end

        if sprite:IsPlaying("Shoot".. REVEL.dirToString[data.Direction]) then
            if npc.FrameCount % 10 == 0 then
                local dir = data.DirVector--:Rotated(-5 + math.random(10))
                local pos = npc.Position + dir * 3 + data.DirVector:Rotated(90) * (math.random(-5, 5))
                local snowp = Isaac.Spawn(1000, REVEL.ENT.SNOW_PARTICLE.variant, 0, pos, dir * 5, npc)
                snowp:GetSprite():Play("FadeNoExpand", true)
                snowp:GetSprite().Offset = SnowParticleOffset[data.Direction]
                REVEL.GetData(snowp).Rot = math.random()*20-10

                if REVEL.IsChilly() then
                    snowp.Color = Color(1.01, 1.5, 1.4, 1.5,conv255ToFloat( 0, 0, 0))
                else
                    snowp.Color = Color(1, 1, 1, 0.9,conv255ToFloat( 0, 0, 0))
                end
            end

            if data.FreezeAreaTL then
                for _, player in ipairs(REVEL.players) do
                    if player.Position.X > data.FreezeAreaTL.X and player.Position.Y > data.FreezeAreaTL.Y
                            and player.Position.X < data.FreezeAreaBR.X and player.Position.Y < data.FreezeAreaBR.Y then
                        REVEL.ChillFreezePlayer(player:ToPlayer(), true, REVEL.GlacierBalance.DarkIceInChill)
                    end
                end
            end

            if not data.WindAlpha then
                data.WindAlpha = 0
                data.WindAppearCount = 0
                data.WindAlphaEnd = 1
            elseif data.WindAppearCount < 20 then
                data.WindAppearCount = data.WindAppearCount + 1
                data.WindAlpha = data.WindAppearCount * windBaseAlpha / 20
            end
        end
    elseif npc.State == NpcState.STATE_SPECIAL then
        if not data.WindFadeCount then
            data.WindFadeCount = 40
        elseif data.WindFadeCount > 0 then
            data.WindFadeCount = data.WindFadeCount - 1

            if data.WindFadeCount == 0 then
                REVEL.DisableWindSound(npc)
            end

            data.WindAlpha = data.WindFadeCount * windBaseAlpha / 40
        end
    end
end, REVEL.ENT.FROST_SHOOTER.id)

-- Temporary, until resource loading is fixed 
-- and grimace variants aren't invisible
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.FROST_SHOOTER:isEnt(npc) then return end

    local sprite = npc:GetSprite()
    sprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
end, REVEL.ENT.FROST_SHOOTER.id)

revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    if REVEL.ENT.FROST_SHOOTER:isEnt(npc) 
    and data.WindAlpha and data.WindAlpha > 0
    and REVEL.IsRenderPassNormal() then
        local baseStartPos = npc.Position + data.DirVector * 40
        local baseEndPos = REVEL.room:GetClampedPosition(baseStartPos + data.DirVector * 40 * (FreezeDistanceGrids - 1), 20)

        local startPos = Isaac.WorldToScreen(baseStartPos) + WindSpriteOffset[data.Direction]
        local endPos = Isaac.WorldToScreen(baseEndPos) + WindSpriteOffset[data.Direction]

        WindStartSprite.Rotation = REVEL.dirToAngle[data.Direction]
        WindStartSprite.Color = Color(1, 1, 1, data.WindAlpha,conv255ToFloat( 0, 0, 0))
        WindStartSprite:Render(startPos, Vector.Zero, Vector.Zero)

        if data.Direction == Direction.UP then
            sprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
        end

        WindLineSprite.Color = Color(1, 1, 1, data.WindAlpha,conv255ToFloat( 0, 0, 0))
        REVEL.DrawRotatedTilingSprite(WindLineSprite, startPos + data.DirVector * 26, endPos, 26)

        WindEndSprite.Color = Color(1, 1, 1, data.WindAlpha,conv255ToFloat( 0, 0, 0))
        WindEndSprite.Rotation = REVEL.dirToAngle[data.Direction]
        WindEndSprite:Render(endPos, Vector.Zero, Vector.Zero)
    end
end, REVEL.ENT.FROST_SHOOTER.id)

end