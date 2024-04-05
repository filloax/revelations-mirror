local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local ProjectilesMode   = require("scripts.revelations.common.enums.ProjectilesMode")
local LaserVariant      = require("scripts.revelations.common.enums.LaserVariant")

return function()

---@param npc EntityNPC
local function jackalGilded_PreNpcUpdate(_, npc)
    if not REVEL.ENT.JACKAL_GILDED:isEnt(npc, true) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
    local target = npc:GetPlayerTarget()

    if npc.State == NpcState.STATE_ATTACK
    and (
        sprite:IsEventTriggered("Shoot")
        or sprite:IsEventTriggered("Shoot2")
    )
    then
        local projSpeed = 9
        local projMode = ProjectilesMode.THREE_PROJ
        if sprite:IsEventTriggered("Shoot") then
            projMode = ProjectilesMode.TWO_PROJ
        end

        local params = ProjectileParams()
        params.BulletFlags = BitOr(
            ProjectileFlags.BOUNCE
        )
        params.FallingAccelModifier = -0.12

        local pos = npc.Position + Vector(0, -10)
        local vel = (target.Position - npc.Position):Resized(projSpeed)

        npc:FireProjectiles(pos, vel, projMode, params)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_GRUNT_0)

        return true
    elseif npc.State == NpcState.STATE_ATTACK2 then
        if sprite:IsEventTriggered("Shoot") then
            return true
        end

        local baseLaserPos = npc.Position + Vector(0, -20)
        local laserOff =  Vector(0, -20)
        local laserNum = 2

        if sprite:IsEventTriggered("ShootTell") then
            local angles = {}
            local targets = {}
            local tracers = {}

            local jackals = REVEL.ENT.JACKAL:getInRoom()
            jackals = REVEL.sort(jackals, function(e1, e2) 
                return e1.Position:DistanceSquared(npc.Position) < 
                    e2.Position:DistanceSquared(npc.Position)
            end)
            local nonBuffedJackals = REVEL.filter(jackals, function(e)
                return not REVEL.GetData(e).JackalBuffed
            end)

            for i = 1, laserNum do
                local targetPos, angle
                if #jackals == 0 and REVEL.isEmpty(angles) then
                    angle = 0
                elseif #nonBuffedJackals >= i then
                    targetPos = nonBuffedJackals[i].Position
                    targets[i] = EntityPtr(nonBuffedJackals[i])
                elseif #jackals >= i then
                    targetPos = jackals[i].Position
                    targets[i] = EntityPtr(jackals[i])
                else
                    angle = angles[i - 1] + 180
                end
                if not angle then
                    angle = (targetPos - baseLaserPos):GetAngleDegrees()
                else
                    targetPos = REVEL.room:GetClampedPosition(baseLaserPos + Vector.FromAngle(angle) * 400, 0)
                end

                local timeout = 28
                local tracer = REVEL.MakeLaserTracer(
                    baseLaserPos + laserOff + Vector(0, 0),
                    timeout, 
                    targetPos + laserOff + Vector(0, 0), 
                    Color(0.75, 0, 0.75),
                    npc, 
                    2
                )

                angles[i] = angle
                tracers[i] = EntityPtr(tracer)
            end

            data.ShootAngles = angles
            data.ShootTargets = targets
            data.ShootTracers = tracers
        end

        if data.ShootTargets then
            for i = 1, laserNum do
                if data.ShootTargets[i] and data.ShootTargets[i].Ref then
                    local target = data.ShootTargets[i].Ref
                    local diff = target.Position - npc.Position
                    data.ShootAngles[i] = diff:GetAngleDegrees()

                    local tracer = data.ShootTracers[i] and data.ShootTracers[i].Ref
                    if tracer then
                        tracer.TargetPosition = diff
                    end
                end
            end
        end

        if sprite:IsEventTriggered("Shoot2") then
            local duration = 10

            for i = 1, laserNum do
                local angle = data.ShootAngles[i]
                local target = data.ShootTargets[i] and data.ShootTargets[i].Ref
                local tracer = data.ShootTracers[i] and data.ShootTracers[i].Ref

                local laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, baseLaserPos, angle, duration, laserOff, npc)
                laser.Color = REVEL.HOMING_COLOR
                -- like black goat lasers
                REVEL.ScaleEntity(laser, {
                    SpriteScale = 0.75,
                    SizeScale = 0.75,
                })

                if tracer then
                    tracer:Remove()
                end
                if REVEL.ENT.JACKAL:isEnt(target) then
                    REVEL.BuffJackal(target:ToNPC())
                end
            end

            data.ShootTargets = nil
            data.ShootAngles = nil
            data.ShootTracers = nil

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MONSTER_ROAR_0, 1, 0, false, 0.95)
            
            return true
        end
    end
end

revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, jackalGilded_PreNpcUpdate, REVEL.ENT.JACKAL_GILDED.id)

end