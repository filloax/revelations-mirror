local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------
-- STALACTITE --
----------------
local bal = {
    FallDelay = 20,
}

StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_SPAWN_ENTITY, 1, function(ent)
    if ent.Type == REVEL.ENT.STALACTITE.id and ent.Variant == REVEL.ENT.STALACTITE.variant then
        local npc = ent:ToNPC()
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:GetData().type = math.random(1, 3)
        npc:GetData().init = true
        npc:GetData().spawnedTarget = true
        npc.State = NpcState.STATE_MOVE
        npc.CollisionDamage = 0
        npc:GetSprite():Play("Idle" .. npc:GetData().type, true)
    end
end)

local TargetDeco = {
    Sprite = "gfx/1000.030_dr. fetus target.anm2",
    Anim = "Blink",
    RemoveOnAnimEnd = false,
    Update = function(eff)
        local data, sprite = eff:GetData(), eff:GetSprite()

        if math.floor(eff.FrameCount / 2) % 2 == 0 then --just playing the anim was weird for some reason, also for setting color if needed since base sprite is red only
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat( 0, 120, 255))
        else
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat( 0, 60, 120))
        end

        if not (data.Stalactite and data.Stalactite:Exists()) and not data.noRequireStalactite then
            eff:Remove()
        end

        if eff.Timeout == 0 then
            eff:Remove()
        end
    end
}
local TargetDeco2 = {
    Sprite = "gfx/effects/revel1/target_stalactite.anm2",
    Anim = "Blink",
    RemoveOnAnimEnd = false,
    Update = function(eff)
        local data, sprite = eff:GetData(), eff:GetSprite()

        if math.floor(eff.FrameCount / 2) % 2 == 0 then --just playing the anim was weird for some reason, also for setting color if needed since base sprite is red only
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat( 0, 120, 255))
        else
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat( 0, 60, 120))
        end

        if not (data.Stalactite and data.Stalactite:Exists()) and not data.noRequireStalactite then
            eff:Remove()
        end

        if eff.Timeout == 0 then
            eff:Remove()
        end
    end
}
local TargetDecoCoal = {
    Sprite = "gfx/effects/revel1/target_stalactite.anm2",
    Anim = "Blink",
    RemoveOnAnimEnd = false,
    Update = function(eff)
        local data, sprite = eff:GetData(), eff:GetSprite()

        if math.floor(eff.FrameCount / 2) % 2 == 0 then --just playing the anim was weird for some reason, also for setting color if needed since base sprite is red only
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat(255, 131, 1))
        else
            sprite.Color = Color(0, 0, 0, 1, conv255ToFloat(128, 65, 0))
        end

        if not (data.Stalactite and data.Stalactite:Exists()) and not data.noRequireStalactite then
            eff:Remove()
        end

        if eff.Timeout == 0 then
            eff:Remove()
        end
    end
}

REVEL.StalactiteTargetDeco = TargetDeco
REVEL.StalactiteTargetDeco2 = TargetDeco2

local function stalactite_NpcUpdate(_, npc)
    if not REVEL.ENT.STALACTITE:isEnt(npc)
    and not REVEL.ENT.STALACTITE_SMALL:isEnt(npc)
    and not REVEL.ENT.COAL_SHARD:isEnt(npc)
    then
        return
    end

    local spr,data = npc:GetSprite(), npc:GetData()

    if not data.init then
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        npc.State = NpcState.STATE_IDLE
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        local anim
        if npc.Variant ~= REVEL.ENT.COAL_SHARD.variant then
            data.type = math.random(1,3)
            anim = "JumpDown" .. data.type
        else
            anim = "Land"
            if data.DontShoot == nil then data.DontShoot = true end
        end
        spr:SetFrame(anim, 0)
        REVEL.DelayFunction(function()
            spr:Play(anim, true)
            data.startedFall = true
        end, bal.FallDelay)

        data.init = true
    end
    if revel.data.stalactiteTargetsOn == 1 and not data.spawnedTarget then
        if npc.Variant == REVEL.ENT.COAL_SHARD.variant then
            data.target = REVEL.SpawnDecorationFromTable(npc.Position, Vector.Zero, TargetDecoCoal)
        elseif data.usesFetusTarget then
            data.target = REVEL.SpawnDecorationFromTable(npc.Position, Vector.Zero, TargetDeco)
        else
            data.target = REVEL.SpawnDecorationFromTable(npc.Position, Vector.Zero, TargetDeco2)
        end
        data.spawnedTarget = true
        data.target:GetData().Stalactite = npc
    end

    data.ShotSpeed = data.ShotSpeed or 10
    if REVEL.game.Difficulty ~= Difficulty.DIFFICULTY_HARD then
        data.ShotSpeed = 8
    end 

    npc.SplatColor = REVEL.SnowSplatColor

    if npc.Variant == REVEL.ENT.STALACTITE.variant then
        if npc.State == NpcState.STATE_IDLE then
            if not spr:WasEventTriggered("Collision") then
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            else
                npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end
            if (spr:IsFinished("JumpDown"..data.type) and data.startedFall) or spr:IsFinished("Freeze" .. data.type) then
                if spr:IsFinished("Freeze" .. data.type) then
                    npc:Die()
                else
                    npc.State = NpcState.STATE_MOVE
                    npc:GetSprite():Play("Idle"..(data.type + (npc:GetData().stretch and 3 or 0)), true)
                end
            end
        elseif npc.State == NpcState.STATE_MOVE then
            if data.StalagmightSpawned then
                if not data.Creep then
                    data.Creep = REVEL.SpawnIceCreep(npc.Position, npc, true):ToEffect()
                    REVEL.UpdateCreepSize(data.Creep, data.StalagmightCreepRadius)
                end

                data.Creep:SetTimeout(80)
            end

            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if npc:GetSprite():IsEventTriggered("Shoot") then
            if data.StalagmightSpawned then
                data.Creep = REVEL.SpawnIceCreep(npc.Position, npc, true):ToEffect()
                REVEL.UpdateCreepSize(data.Creep, data.StalagmightCreepRadius)
            end
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
            if not data.DontShootStart and not data.DontShoot then
                for i = 1, 4 do
                    Isaac.Spawn(9, 4, 0, npc.Position, Vector.FromAngle(i * 90) * data.ShotSpeed, npc)
                end
            end
            if data.target then
                data.target:Remove()
                data.target = nil
            end
        --npc.State = NpcState.STATE_MOVE
        elseif npc:GetSprite():IsEventTriggered("Collisioff") then --already fallen, remove collision damage
            npc.CollisionDamage = 0
        end

    elseif npc.Variant == REVEL.ENT.STALACTITE_SMALL.variant then
        --[[
        if not npc.Visible then
            npc:GetSprite():Stop()
            if npc:GetData().Timer then
                npc:GetData().Timer = npc:GetData().Timer - 1
                if npc:GetData().Timer <= 0 then
                    npc:GetData().Timer = nil
                    npc.Visible = true
                end
            end
        end
        ]]

        if not spr:WasEventTriggered("Collision") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        else
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if spr:IsEventTriggered("Shoot") then
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc:Kill()
            if data.target then
                data.target:Remove()
                data.target = nil
            end
        end
    
    elseif npc.Variant == REVEL.ENT.COAL_SHARD.variant then
        if spr:IsEventTriggered("Collision") then

            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1)
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_FLAMETHROWER_END, 1, 0, false, 1)
            local radius = REVEL.GetChillWarmRadius() * 0.8
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.CollisionDamage = 1

            REVEL.SetWarmAura(npc, radius)
            data.StartFrame = npc.FrameCount
            data.BaseRadius = radius

            if data.target then
                data.target:Remove()
                data.target = nil
            end
        end

        if REVEL.GetWarmAuraData(npc) then
            local flickerFrame = npc.FrameCount - data.StartFrame
            local flickerPct = (math.sin(flickerFrame* 0.1) + 1) / 2

            local newRadius = REVEL.Lerp(data.BaseRadius, data.BaseRadius * 1.2, flickerPct)
            REVEL.SetWarmAura(npc, newRadius)
        end

        if spr:IsFinished("Land") and data.startedFall then spr:Play("Ground_Idle", true) end
    end

    if npc:IsDead() then
        if npc.Variant ~= REVEL.ENT.COAL_SHARD.variant then
            REVEL.sfx:NpcPlay(npc, REVEL.SFX.MINT_GUM_BREAK, 1, 0, false, 1)
            local iceVariant = REVEL.IceGibType.DEFAULT
            if data.IsDarkIce then
                iceVariant = REVEL.IceGibType.DARK
            end
            for i=1, 6 do
                REVEL.SpawnIceRockGib(npc.Position, Vector.FromAngle(1*math.random(0, 360)):Resized(math.random(1, 5)), npc, iceVariant)
            end
        else
            REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_ROCK_CRUMBLE, 1, 0, false, 1)
            for i = 1, math.random(3, 5) do
                local particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, npc.Position + Vector.FromAngle(math.random(0,359))*npc.Size*math.random(), Vector.FromAngle(math.random(0,359))*math.random(), npc)
                particle:GetSprite().Color = Color(1, 0.75, 0.33, 1, conv255ToFloat(64, 32, 0))
            end
        end
        if not data.DontShoot and not data.DontShootEnd then
            local startAngle = 0
            if data.StartAngle then
                startAngle = data.StartAngle
            elseif REVEL.ENT.STALACTITE:isEnt(npc) then
                startAngle = 45
            end
            local shotNum = data.ShotNum or 4

            for i = 1, shotNum do
                Isaac.Spawn(9, 4, 0, npc.Position, Vector.FromAngle(i * 360 / shotNum + startAngle) * data.ShotSpeed, npc)
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, stalactite_NpcUpdate, REVEL.ENT.STALACTITE.id)

end

REVEL.PcallWorkaroundBreakFunction()