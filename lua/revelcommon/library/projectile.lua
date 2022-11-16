local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


function REVEL.SpawnNPCProjectile(npc, velocity, position, variant, subtype)
    local pro = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, variant or ProjectileVariant.PROJECTILE_NORMAL, subtype or 0, position or npc.Position, velocity or Vector.Zero, npc):ToProjectile()
    pro.Parent = npc
    if npc:HasEntityFlags(EntityFlag.FLAG_CHARM) or npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        pro.ProjectileFlags = BitOr(ProjectileFlags.CANT_HIT_PLAYER, ProjectileFlags.HIT_ENEMIES)
    end
    return pro
end

-- Fires a spread of monstro shots within a somewhat reliable cone
-- spawner - spawner npc
-- num, target, trajectory, params - see FireBossProjectiles
-- spreadDist - the width of the 'base' of the cone, centered on the target
-- setup - optional function that takes (projectile) and allows for additional config as they spawn
---@param spawner EntityNPC
---@param num integer
---@param target Entity
---@param trajectory integer
---@param params ProjectileParams
---@param spreadDist number
---@param setup fun(projectile: EntityProjectile)
function REVEL.SpreadBossProjectiles(spawner, num, target, trajectory, params, spreadDist, setup)
    setup = setup or function(projectile) end
  
    local bet = target - spawner.Position
  
    local disp = bet:Normalized()
    local y = disp.Y
    disp.Y = disp.X
    disp.X = -y
    disp.X = -y
  
    local currDist = -spreadDist * 0.5
    for i=1,num do
        local dist = currDist
  
        -- t(1-t) from 0 to 1 has an arc length of ~1
        -- this graph changes most slowly towards 0 and 1
        -- with greater change in the middle
        -- this leads to more projectiles (with natural boss proj jitter)
        -- fired towards the edges with fewer in the middle
        local t = i / (num - 1)
        currDist = currDist + spreadDist * t * (1 - t)
  
        local proj = spawner:FireBossProjectiles(1, target + disp * dist, trajectory, params)
        proj.SpawnerEntity = spawner
        proj.SpawnerType = spawner.Type
        proj.SpawnerVariant = spawner.Variant
        setup(proj)
    end
end

-- Better Projectile overlays
local projectileOverlay = REVEL.LazyLoadRoomSprite{
    ID = "lib_projectileOverlay",
    Anm2 = "gfx/effects/projectileoverlay.anm2",
}

local function projectileOverlaysPostProjRender(_, pro, renderOffset)
    local color = pro:GetData().ColoredProjectile
    if color then
        projectileOverlay.Color = color
        projectileOverlay.Scale = pro.SpriteScale
        local sprite = pro:GetSprite()
        projectileOverlay.Rotation = sprite.Rotation
        projectileOverlay.Offset = sprite.Offset
        local animation
        for i = 1, 13 do
            local anim = "RegularTear" .. tostring(i)
            if sprite:IsPlaying(anim) or sprite:IsFinished(anim) then
                animation = anim
                break
            end
        end

        if animation then
            projectileOverlay:SetFrame(animation, sprite:GetFrame())
            projectileOverlay:Render(Isaac.WorldToScreen(pro.Position + pro.PositionOffset) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end
    end
end

local projectileOverlayPoof = REVEL.LazyLoadRoomSprite{
    ID = "lib_projectileOverlayPoof",
    Anm2 = "gfx/effects/projectileoverlay_poof.anm2",
}

--REPLACE PROJ POOFS
local function projectileOverlayPostPoofInit(poof, data, sprite, spawner, grandpa)
    local color = spawner:GetData().ColoredProjectile
    if spawner.Variant == ProjectileVariant.PROJECTILE_NORMAL and color then
        data.ColoredPoof = color
    end
end

local function projectileOverlayPostEffectRender(_, poof, renderOffset)
    local color = poof:GetData().ColoredPoof
    if color then
        projectileOverlayPoof.Color = color
        projectileOverlayPoof.Scale = poof.SpriteScale
        local sprite = poof:GetSprite()
        projectileOverlayPoof.Rotation = sprite.Rotation
        projectileOverlayPoof.Offset = sprite.Offset

        projectileOverlayPoof:SetFrame('Poof', sprite:GetFrame())
        projectileOverlayPoof:Render(Isaac.WorldToScreen(poof.Position + poof.PositionOffset) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PROJECTILE_RENDER, projectileOverlaysPostProjRender)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_PROJ_POOF_INIT, 1, projectileOverlayPostPoofInit)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, projectileOverlayPostEffectRender)

end