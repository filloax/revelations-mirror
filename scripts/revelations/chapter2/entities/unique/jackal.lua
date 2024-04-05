local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local ProjectilesMode   = require("scripts.revelations.common.enums.ProjectilesMode")

return function()

-- currently use different anm2s altogether to
-- avoid breaking champions
-- TODO: replace with spritesheet replacement when champions w 
-- spritesheet replacement are fixed
local Sprites = {
    Normal = {
        Default = "gfx/monsters/revel2/jackal/jackal.anm2",
        Fancy   = "gfx/monsters/revel2/jackal/jackal_fancy.anm2",
    },
    Buffed = {
        Default = "gfx/monsters/revel2/jackal/jackal_buffed.anm2",
        Fancy   = "gfx/monsters/revel2/jackal/jackal_fancy_buffed.anm2",
    },
}

local FancyChance = 0.1
local BuffDuration = 8 -- seconds

---@param npc EntityNpc
function REVEL.BuffJackal(npc)
    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
    if not data.JackalBuffed then
        data.JackalBuffed = true
        data.BuffTimer = BuffDuration * 30

        npc:SetColor(REVEL.HOMING_COLOR, 30, 10, true, true)
        REVEL.SpawnPurpleThunder(npc)
        local newSprite = data.IsFancy and Sprites.Buffed.Fancy
            or Sprites.Buffed.Default
        local anim = sprite:GetAnimation()
        local frame = sprite:GetFrame()
        sprite:Load(newSprite, true)
        sprite:Play(anim, true)
        sprite:SetFrame(frame)

        sprite.PlaybackSpeed = 1.35 -- faster shooting
    end
end

local function jackal_NpcUpdateInit(npc)
    if not REVEL.ENT.JACKAL:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)

    local rng = REVEL.RNG()
    rng:SetSeed(npc.InitSeed, 40)

    data.IsFancy = rng:RandomFloat() < FancyChance

    if data.IsFancy then
        sprite:Load(Sprites.Normal.Fancy, true)
        sprite:SetFrame("WalkHori", 0)
    end
end

---@param npc EntityNPC
local function jackal_PreNpcUpdate(_, npc)
    if not REVEL.ENT.JACKAL:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), REVEL.GetData(npc)
    local target = npc:GetPlayerTarget()

    if data.JackalBuffed then
        -- boost velocity sort of
        local len = npc.Velocity:Length()
        if len > 2.5 then
            npc.Velocity = npc.Velocity * 1.15
            len = len * 1.15
        end
        if len > 6 then
            REVEL.DashTrailEffect(
                npc, 
                math.floor(REVEL.Lerp2Clamp(6, 3, len, 7.5, 10)), 
                30, 
                Color(1.5, 0.5, 1.5, 0.5)
            )
        end

        data.BuffTimer = data.BuffTimer - 1 
        if data.BuffTimer <= 0 then
            data.BuffTimer = nil
            data.JackalBuffed = nil

            local newSprite = data.IsFancy and Sprites.Normal.Fancy
                or Sprites.Normal.Default
            local anim = sprite:GetAnimation()
            local frame = sprite:GetFrame()
            sprite:Load(newSprite, true)
            sprite:Play(anim, true)
            sprite:SetFrame(frame)
            sprite.PlaybackSpeed = 1

            local num = math.random(3, 7)
            for i = 1, num do
                local e = Isaac.Spawn(
                    1000, 
                    EffectVariant.DUST_CLOUD, 
                    0, 
                    npc.Position + RandomVector() * math.random(5, 20) + Vector(0, -15), 
                    Vector.Zero, 
                    npc
                ):ToEffect()
                e.Timeout = math.random(15, 30)
                e.LifeSpan = e.Timeout
                e.Color = Color(0.75, 0, 0.75, 0.5)
            end
        end
    end

    if npc.State == NpcState.STATE_ATTACK
    and (
        sprite:IsEventTriggered("Shoot")
        or sprite:IsEventTriggered("Shoot2")
    )
    then
        local projSpeed = 9
        if data.JackalBuffed then
            projSpeed = 10.5
        end
        local projMode = ProjectilesMode.TWO_PROJ
        if sprite:IsEventTriggered("Shoot") then
            projMode = ProjectilesMode.SINGLE_PROJ
        end

        local params = ProjectileParams()
        params.BulletFlags = ProjectileFlags.BOUNCE
        params.FallingAccelModifier = -0.08
        if data.JackalBuffed then
            params.FallingAccelModifier = -0.05
        end

        local pos = npc.Position + Vector(0, -10)
        local vel = (target.Position - npc.Position):Resized(projSpeed)

        npc:FireProjectiles(pos, vel, projMode, params)
        REVEL.sfx:NpcPlay(npc, SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0, false, 1)

        return true
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.NPC_UPDATE_INIT, 1, jackal_NpcUpdateInit, REVEL.ENT.JACKAL.id)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, jackal_PreNpcUpdate, REVEL.ENT.JACKAL.id)

end