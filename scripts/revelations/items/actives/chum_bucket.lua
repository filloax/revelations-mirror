local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-----------------
-- CHUM BUCKET --
-----------------

--[[
Active. Quick charge similar to candle.
All enemies except flies, passively leave small mounds of body parts, (blobs of meat) on death. Using the Chum Bucket causes all blobs in the room to fire one of three random tears on each use, at the closest enemy to each blob.
- Red tear. Standard player damage.
- Bone. Standard player damage, but acts as bone fracture on impact.
- Tooth. 3x player damage.
Corpses do not disappear. Essentially becoming stationary turrets that fire on item use. The item is intended to snowball as more and more enemies die in a room and result in more and more turrets.
-note- a cap on bodies may be needed if performance issues occur.
]]

local Chum = {
    gfxTypes = 5,
    defSize = 13, -- gaper size
    chums = {},
    blacklist = {
        [EntityType.ENTITY_FLY] = true,
        [EntityType.ENTITY_ATTACKFLY] = true,
        [EntityType.ENTITY_RING_OF_FLIES] = true,
        [EntityType.ENTITY_DART_FLY] = true,
        [EntityType.ENTITY_PORTAL] = true,
        [EntityType.ENTITY_ULTRA_COIN] = true
    },
    blacklistRev = {REVEL.ENT.PEASHY_NAIL}
}

---@param e Entity
function REVEL.TriggerChumBucket(e)
    if e:IsActiveEnemy(true) 
    and e:ToNPC() and not Chum.blacklist[e.Type] 
    and not REVEL.some(Chum.blacklistRev,
        function(v) return v:isEnt(e) end) 
    and not REVEL.GetData(e).__manuallyRemoved 
    and REVEL.ITEM.CHUM:OnePlayerHasCollectible() then
        local chum = REVEL.ENT.CHUM:spawn(e.Position, Vector.Zero, e)
        REVEL.GetData(chum).ctype = math.random(Chum.gfxTypes)
        chum:GetSprite():Play("Spawn" .. REVEL.GetData(chum).ctype, true)
        chum.Size = e.Size
        local mult =
            math.max(0.6, math.sqrt(chum.Size / Chum.defSize))
        chum.SpriteScale = Vector(mult, mult)
        table.insert(Chum.chums, chum)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, e) 
    if REVEL.ITEM.CHUM:OnePlayerHasCollectible() then
        REVEL.TriggerChumBucket(e)
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, e, c) 
    if REVEL.GetData(e).ChumBucketPlayer then
        if c and c:IsVulnerableEnemy() and c.HitPoints <= e.BaseDamage then
            local p = REVEL.GetData(e).ChumBucketPlayer
            if p:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                p:AddWisp(REVEL.ITEM.CHUM.id, p.Position)
            end
        end
    end
end)

-- REVEL.AddCustomBar(REVEL.ITEM.CHUM.id, 110)

revel:AddCallback(ModCallbacks.MC_USE_ITEM,
                    function(_, itemID, itemRNG, player, useFlags, activeSlot,
                            customVarData)
    for i, c in ipairs(Chum.chums) do
        c:GetSprite():Play("Shoot" .. REVEL.GetData(c).ctype, true)
        REVEL.GetData(c).LastPlayer = player
    end

    local wisps = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, REVEL.ITEM.CHUM.id)
    for _, wisp in ipairs(wisps) do
        if wisp:ToFamiliar() then
            local targ = REVEL.getClosestEnemy(wisp, true, true, true, true)
            local dir

            if targ then
                dir = (targ.Position + targ.Velocity - wisp.Position):Resized(9.5)
            else
                dir = RandomVector() * 9.5
            end
            wisp:ToFamiliar():FireProjectile(dir:Normalized())
        end
    end

    return true
end, REVEL.ITEM.CHUM.id)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
    local spr, data = e:GetSprite(), REVEL.GetData(e)

    if spr:IsEventTriggered("Shoot") then
        local targ = REVEL.getClosestEnemy(e, true, true, true, true)
        local dir

        if targ then
            dir = (targ.Position + targ.Velocity - e.Position):Resized(9.5)
        else
            dir = RandomVector() * 9.5
        end

        local r = math.random(3)
        local p = REVEL.GetData(e).LastPlayer or REVEL.GetRandomPlayer()
        local t
        if r == 3 then
            t =
                Isaac.Spawn(2, TearVariant.BLOOD, 0, e.Position, dir, e):ToTear()
            t.CollisionDamage = p.Damage
            t.FallingSpeed = -math.random(6) - 4
            t.Scale = 0.6 + math.random() * 0.2
        elseif r == 2 then
            t =
                Isaac.Spawn(2, TearVariant.BONE, 0, e.Position, dir, e):ToTear()
            t.CollisionDamage = p.Damage
            t.FallingSpeed = -math.random(6) - 4
            t.TearFlags = t.TearFlags | TearFlags.TEAR_BONE
            t.Scale = 0.7 + math.random() * 0.3
        else
            t =
                Isaac.Spawn(2, TearVariant.TOOTH, 0, e.Position, dir, e):ToTear()
            t.CollisionDamage = p.Damage * 3
            t.FallingSpeed = -math.random(3) - 4
            t.Scale = 0.8 + math.random() * 0.2
        end
        t.Scale = math.min(t.Scale * e.SpriteScale.X, 1.25)
        t.Height = -5
        REVEL.GetData(t).ChumBucketPlayer = p

    elseif spr:IsFinished("Shoot" .. data.ctype) or
        spr:IsFinished("Spawn" .. data.ctype) then
        spr:Play("Idle" .. data.ctype, true)
    end
end, REVEL.ENT.CHUM.variant)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1,
                    function() Chum.chums = {} end)

if Isaac.GetPlayer(0) then -- mod reloaded
    Chum.chums = Isaac.FindByType(REVEL.ENT.CHUM.id,
                                        REVEL.ENT.CHUM.variant, -1, false,
                                        false)
end

end
