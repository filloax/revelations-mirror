local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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

revel.chum = {
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
    and e:ToNPC() and not revel.chum.blacklist[e.Type] 
    and not REVEL.some(revel.chum.blacklistRev,
        function(v) return v:isEnt(e) end) 
    and not e:GetData().__manuallyRemoved 
    and REVEL.ITEM.CHUM:OnePlayerHasCollectible() then
        local chum = REVEL.ENT.CHUM:spawn(e.Position, Vector.Zero, e)
        chum:GetData().ctype = math.random(revel.chum.gfxTypes)
        chum:GetSprite():Play("Spawn" .. chum:GetData().ctype, true)
        chum.Size = e.Size
        local mult =
            math.max(0.6, math.sqrt(chum.Size / revel.chum.defSize))
        chum.SpriteScale = Vector(mult, mult)
        table.insert(revel.chum.chums, chum)
    end
end

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, e) 
    if REVEL.ITEM.CHUM:OnePlayerHasCollectible() then
        REVEL.TriggerChumBucket(e)
    end
end)

revel:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, e, c) 
    if e:GetData().ChumBucketPlayer then
        if c and c:IsVulnerableEnemy() and c.HitPoints <= e.BaseDamage then
            local p = e:GetData().ChumBucketPlayer
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
    for i, c in ipairs(revel.chum.chums) do
        c:GetSprite():Play("Shoot" .. c:GetData().ctype, true)
        c:GetData().LastPlayer = player
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
    if e.Variant ~= REVEL.ENT.CHUM.variant then return end

    local spr, data = e:GetSprite(), e:GetData()

    if spr:IsEventTriggered("Shoot") then
        local targ = REVEL.getClosestEnemy(e, true, true, true, true)
        local dir

        if targ then
            dir = (targ.Position + targ.Velocity - e.Position):Resized(9.5)
        else
            dir = RandomVector() * 9.5
        end

        local r = math.random(3)
        local p = e:GetData().LastPlayer or REVEL.GetRandomPlayer()
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
        t:GetData().ChumBucketPlayer = p

    elseif spr:IsFinished("Shoot" .. data.ctype) or
        spr:IsFinished("Spawn" .. data.ctype) then
        spr:Play("Idle" .. data.ctype, true)
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1,
                    function() revel.chum.chums = {} end)

if Isaac.GetPlayer(0) then -- mod reloaded
    revel.chum.chums = Isaac.FindByType(REVEL.ENT.CHUM.id,
                                        REVEL.ENT.CHUM.variant, -1, false,
                                        false)
end

end

REVEL.PcallWorkaroundBreakFunction()
