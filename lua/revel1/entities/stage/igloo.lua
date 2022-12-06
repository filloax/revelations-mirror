REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--Grimice / Igloo
local ProjectileOffset = Vector.Zero
local ProjectileSpeed = 12
local FireDelay = 24
local MaxRange = 800
local MaxRangeSquared = MaxRange ^ 2

local RotationFrames = 12 --starts from 0 in the anim
local RotationStartAngle = 90
local RotationAnimClockwise = false

local Offsets = {
    Vector(0, 11),
    Vector(7, 9),
    Vector(15, 6),
    Vector(25, 3),
    Vector(22, -8),
    Vector(15, -16),
    Vector(0, -18),
    Vector(-15, -15),
    Vector(-22, -5),
    Vector(-24, 2),
    Vector(-16, 7),
    Vector(-7, 10),
}
for i, offset in ipairs(Offsets) do Offsets[i] = offset * REVEL.SCREEN_TO_WORLD_RATIO end --game coords from sprite coords

local ShootAnims = {}
for i = 1, RotationFrames do ShootAnims[i] = "Shoot" .. i end

--Uses grimace type for grid like collisions, and so cannot disable vanilla AI completely due to it making those collisions work
local function iglooUpdate(_, npc)
    if not REVEL.ENT.IGLOO:isEnt(npc) then return end

    local data, sprite = npc:GetData(), npc:GetSprite()

    if not data.Init then
        data.FireDelay = FireDelay
        data.Init = true
    end

    if npc.State ~= NpcState.STATE_INIT then
        npc.State = NpcState.STATE_ATTACK2
    end

    -- Currently grimaces seem to have 60 fps updates
    if data.LastUpdateFrame == REVEL.game:GetFrameCount() then
        return
    end
    data.LastUpdateFrame = REVEL.game:GetFrameCount()

    if REVEL.room:IsClear() or data.Finish then
        if not data.Finish then
            data.Finish = true
            sprite:Play("Die", true)
        end
    else
        local player = npc:GetPlayerTarget()

        local angle = (player.Position - npc.Position):GetAngleDegrees()
        local frame = math.floor(1 + (angle - RotationStartAngle) / (360 / RotationFrames) - 1) % RotationFrames

        if not RotationAnimClockwise then
            frame = RotationFrames - frame - 1
        end

        local shootAnim = "Shoot" .. (frame + 1)
        local currentShootAnim = sprite:GetAnimation()

        if REVEL.includes(ShootAnims, currentShootAnim) and sprite:IsFinished(currentShootAnim) then
            data.FireDelay = FireDelay
        end

        if sprite:IsEventTriggered("Shoot") then
            local vel = Vector.FromAngle(angle) * ProjectileSpeed
            REVEL.ShootChillSnowball(npc, npc.Position + Offsets[frame + 1], vel, REVEL.GlacierBalance.DarkIceChillDuration)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_BIRD_FLAP , 0.5, 0, false, 1.5)
        end

        if currentShootAnim and sprite:IsPlaying(currentShootAnim) then
            if currentShootAnim ~= shootAnim then
                local animFrame = sprite:GetFrame()
                sprite:Play(shootAnim, true)
                sprite:SetFrame(animFrame)
            end
        else
            sprite:SetFrame("Spin", frame)
        end

        if data.FireDelay < 0 then
            if not IsAnimOn(sprite, shootAnim) 
            and player.Position:DistanceSquared(npc.Position) < MaxRangeSquared 
            and REVEL.room:CheckLine(npc.Position, player.Position, 3) then
                sprite:Play(shootAnim, true)
            end
        else
            data.FireDelay = data.FireDelay - 1
        end

        data.Finishing = nil
    end
end

-- Temporary, until resource loading is fixed 
-- and grimace variants aren't invisible
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, function(_, npc)
    if not REVEL.ENT.IGLOO:isEnt(npc) then return end

    local data, sprite = npc:GetData(), npc:GetSprite()
    sprite:Render(Isaac.WorldToScreen(npc.Position), Vector.Zero, Vector.Zero)
end, REVEL.ENT.IGLOO.id)

-- revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, entType, entVariant, entSubType, position, velocity, spawner, seed)
--   if entType == 9 and entVariant ~= ProjectileVariant.PROJECTILE_TEAR and spawner and REVEL.ENT.IGLOO:isEnt(spawner) then
--         return {
--           StageAPI.E.DeleteMeProjectile.T,
--           StageAPI.E.DeleteMeProjectile.V,
--           0,
--           seed
--         }
--     end
-- end)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, iglooUpdate, REVEL.ENT.IGLOO.id)

end