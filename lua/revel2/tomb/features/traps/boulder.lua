local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

REVEL.TrapTypes.BoulderTrap = {
    OnSpawn = function(tile, data, index)
        local vec = Vector.FromAngle(data.TrapData.Angle)
        local boulderPos, boulderVel = REVEL.room:GetClampedPosition(tile.Position + (vec * 10000), 0), -vec * 10
        data.BoulderPosition = boulderPos
        data.BoulderVelocity = boulderVel
    end,
    OnTrigger = function(tile, data, player)
        local grindex = REVEL.room:GetGridIndex(tile.Position)
        local currentRoom = StageAPI.GetCurrentRoom()
        local invertOffset = currentRoom.Metadata:Has{Index = grindex, Name = "BoulderOffset"}
        local boulder = REVEL.SpawnSandBoulder(data.BoulderPosition, data.BoulderVelocity, nil, invertOffset)
        boulder:GetData().NoHitPlayer = data.TrapIsPositiveEffect
    end,
    IsValidRandomSpawn = function(index)
        local pos = REVEL.room:GetGridPosition(index)
        local bottomright = REVEL.room:GetBottomRightPos()
        local topleft = REVEL.room:GetTopLeftPos()
        local validDirections = {}

        local fitsHorizontal = (pos.Y > topleft.Y + 100 and pos.Y < bottomright.Y - 100)
        local fitsVertical = (pos.X > topleft.X + 100 and pos.X < bottomright.X - 100)
        if fitsHorizontal then
            if pos.X > topleft.X + 200 then
                validDirections[#validDirections + 1] = 180
            end

            if pos.X < bottomright.X - 200 then
                validDirections[#validDirections + 1] = 0
            end
        end

        if fitsVertical then
            if pos.Y > topleft.Y + 200 then
                validDirections[#validDirections + 1] = 270
            end

            if pos.Y < bottomright.Y - 200 then
                validDirections[#validDirections + 1] = 90
            end
        end

        if #validDirections > 0 then
            local dir = validDirections[math.random(1, #validDirections)]
            return {
                Angle = dir
            }
        else
            return false
        end
    end,
    Cooldown = 300,
    Animation = "Boulder"
}
    
local rollVariants = {
    "",
    " 2",
    " 3",
    " 4"
}

local boulderOffsetHori = Vector(0, -20)
local boulderOffsetVert = Vector(20, 0)
function REVEL.SpawnSandBoulder(position, velocity, offset, invertOffset)
    if not offset then
        if math.abs(velocity.X ) < math.abs(velocity.Y) then
            offset = boulderOffsetVert
        else
            offset = boulderOffsetHori
        end

        if invertOffset then
            offset = -offset
        end
    end

    local eff = Isaac.Spawn(REVEL.ENT.SAND_BOULDER.id, REVEL.ENT.SAND_BOULDER.variant, 0, position + offset, velocity, nil)
    eff:AddEntityFlags(BitOr(EntityFlag.FLAG_NO_STATUS_EFFECTS, EntityFlag.FLAG_NO_KNOCKBACK, EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK))
    if math.abs(velocity.X) > math.abs(velocity.Y) then
        if velocity.X < 0 then
            eff:GetSprite():Play("Roll Start 3", true)
        else
            eff:GetSprite():Play("Roll Start", true)
        end
    else
        if velocity.Y < 0 then
            eff:GetSprite():Play("Roll Start 4", true)
        else
            eff:GetSprite():Play("Roll Start 2", true)
        end
    end
    
    eff:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)

    eff.CollisionDamage = 68.75

    return eff
end

local function boulderDustUpdate(eff, data, sprite)
    local scale = REVEL.Lerp2(0.5, 2, data.fadeOut, data.fadeOutMax, 0)
    -- REVEL.DebugToConsole(eff.Index, data.fadeOut, data.fadeOutMax, scale)
    eff.SpriteScale = Vector.One * scale
end

local function boulderDustStart(eff, data, sprite)
    sprite.Rotation = math.random(359)
    boulderDustUpdate(eff, data, sprite)
end

REVEL.BoulderDust = {
    Sprite = "gfx/1000.052_dust cloud.anm2",
    Anim = "Clouds",
    SetFrame = 0,
    Update = boulderDustUpdate,
    Start = boulderDustStart,
    FadeOut = 30,
    Time = 2,
    Color = Color(1,1,1, 0.3,conv255ToFloat( 0,0,0))
}

-- REV_POST_BOULDER_IMPACT(boulder, ent, isGrid)
-- ent is set if colliding with entity, gridentity as appropriate
-- return true if the boulder should be destroyed (if entity set)
-- or if it should spawn urny from ceiling if unset (colliding with wall)

---@param boulder Entity
---@param ent? Entity
---@param isGrid? boolean
---@return boolean isDead
---@return boolean spawnUrny
---@return boolean handled
local function OnBoulderImpact(boulder, ent, isGrid)
    local wallCollision = not ent
    local isDead = wallCollision
    local spawnUrny = false
    local handled = false

    local callbacks = StageAPI.GetCallbacks(RevCallbacks.POST_BOULDER_IMPACT)
    for k, callback in ipairs(callbacks) do
        local success, ret = StageAPI.TryCallback(callback, boulder, ent, isGrid)
        if success then
            if wallCollision then
                spawnUrny = spawnUrny or ret
            else
                isDead = isDead or ret
            end
            handled = handled or ret ~= nil
        end
    end
    return isDead, spawnUrny, handled
end

local function CheckBoulderCollision(boulder, ent, data, radius)
    return ent.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and
            (not data.HitByBoulder or data.HitByBoulder < ent.FrameCount) and
            ent.Position:DistanceSquared(boulder.Position) < (40 + radius) ^ 2
end

local slotVariantsToExplode = {
    [1] = true,
    [2] = true,
    [3] = true,
    [8] = true,
    [10] = true,
    [11] = true,
    [12] = true
}
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    local sprite, data = eff:GetSprite(), eff:GetData()
    if data.IsCrushingBoulder then
        if sprite:IsEventTriggered("ScreenShake") then
            REVEL.sfx:Play(REVEL.SFX.BOULDER_THUMP, 1, 0, false, 1)
            REVEL.game:ShakeScreen(20)
            for _, enemy in ipairs(REVEL.roomEnemies) do
                if enemy:IsVulnerableEnemy() and enemy.Position:DistanceSquared(eff.Position) < (60 + enemy.Size) ^ 2 and (not enemy:GetData().HitByBoulder or enemy:GetData().HitByBoulder < enemy.FrameCount) then
                    enemy:GetData().HitByBoulder = enemy.FrameCount + 30
                    enemy:TakeDamage(data.IsCrushingBoulder, 0, EntityRef(eff), 0)
                end
            end
        end

        if sprite:IsFinished("Crush") then
            REVEL.SpawnDecoration(eff.Position, Vector.Zero, "Death", sprite:GetFilename(), eff, -1000, -1)
            eff:Remove()
        end

        return
    end

    local isRolling
    local onGround = not data.bHeight or data.bHeight > -10
    for _, variant in ipairs(rollVariants) do
        if sprite:IsFinished("Roll Start" .. variant) or sprite:IsFinished("Roll Start Small" .. variant) then
            sprite:Play("Rolling" .. variant, true)
        end

        if sprite:IsPlaying("Rolling" .. variant) and onGround then
            isRolling = true
        end
    end

    if isRolling then
        if not REVEL.sfx:IsPlaying(REVEL.SFX.BOULDER_ROLL) then
            REVEL.sfx:Play(REVEL.SFX.BOULDER_ROLL, 1, 0, false, 1)
        end
    end

    if sprite:IsEventTriggered("ScreenShake") then
        REVEL.sfx:Play(REVEL.SFX.BOULDER_THUMP, 1, 0, false, 1)
        REVEL.game:ShakeScreen(20)
    end

    local isDead
    if onGround then
        for _, npc in ipairs(REVEL.roomEnemies) do
            local ndata = npc:GetData()
            if CheckBoulderCollision(eff, npc, ndata, npc.Size) then
                ndata.HitByBoulder = npc.FrameCount+30

                local dead, spawnUrny, handled = OnBoulderImpact(eff, npc, false)
                isDead = isDead or dead

                if not handled then
                    npc:TakeDamage(eff.CollisionDamage, 0, EntityRef(eff), 0)
                end
            end
        end

        if not data.NoHitPlayer then
            for _,player in ipairs(REVEL.players) do
                local pdata = player:GetData()
                if CheckBoulderCollision(eff, player, pdata, 0) then
                    pdata.HitByBoulder = player.FrameCount+30

                    local dead, spawnUrny, handled = OnBoulderImpact(eff, player, false)
                    isDead = isDead or dead

                    if not handled then
                        player:TakeDamage(1, 0, EntityRef(player), 0)
                    end
                end
            end
        end

        for _,slot in ipairs(Isaac.FindByType(EntityType.ENTITY_SLOT, -1, -1, false, false)) do
            local sdata = slot:GetData()
            if CheckBoulderCollision(eff, slot, sdata, 0) then
                sdata.HitByBoulder = slot.FrameCount+30

                local dead, spawnUrny, handled = OnBoulderImpact(eff, slot, false)
                isDead = isDead or dead

                if not handled then
                    if slot.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_GROUND then
                        if slotVariantsToExplode[slot.Variant] then
                            Isaac.Explode(slot.Position, eff, 0)
                        else
                            slot:TakeDamage(0, DamageFlag.DAMAGE_EXPLOSION, EntityRef(eff), 0)
                        end
                    end
                end
            end
        end
        
        local alignedpositions = {Vector(20,20),Vector(-20,20),Vector(20,-20),Vector(-20,-20)}
        for _,v in ipairs(alignedpositions) do
            local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(v+eff.Position))
            if grid then
                local dead, spawnUrny, handled = OnBoulderImpact(eff, grid, true)
                isDead = isDead or dead

                if not handled then
                    if REVEL.CanGridBeDestroyed(grid) then
                        grid:Destroy()
                    end
                end
            end
        end

        if eff.FrameCount % 4 == 0 then
            REVEL.SpawnDecorationFromTable(eff.Position, Vector.Zero, REVEL.BoulderDust)
        end
    end
    local grid = REVEL.room:GetGridEntity(REVEL.room:GetGridIndex(eff.Position+eff.Velocity))
    local doSpawnUrny, doFallingRocks
    if grid and (grid.Desc.Type == GridEntityType.GRID_WALL or grid.Desc.Type == GridEntityType.GRID_DOOR) then
        local spawnUrny, handled

        isDead, spawnUrny, handled = OnBoulderImpact(eff)
        doSpawnUrny = doSpawnUrny or spawnUrny

        -- didn't specify anything (default behavior)
        -- or already spawning urny
        if (not handled or doSpawnUrny) 
        and doSpawnUrny then
            local count = 1
            local shape = REVEL.room:GetRoomShape()
            if shape == RoomShape.ROOMSHAPE_IH 
            or shape == RoomShape.ROOMSHAPE_IV 
            or shape == RoomShape.ROOMSHAPE_IIH 
            or shape == RoomShape.ROOMSHAPE_IIV 
            then
                count = 0
            elseif shape ~= RoomShape.ROOMSHAPE_1x1 then
                count = 2
            end

            doSpawnUrny = count > 0 and REVEL.ENT.URNY:countInRoom() < count
        end

        doFallingRocks = REVEL.IsShrineEffectActive(ShrineTypes.PERIL)
    end

    if doSpawnUrny then
        local urny = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, eff.Position, Vector.Zero, nil)
        urny:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        urny:GetSprite():Load("gfx/monsters/revel2/urny.anm2", true)
        urny:GetSprite():SetFrame("Idle", 0)
        urny:GetSprite().Offset = Vector(0,-600)
        urny:GetData().UrnyFallingEffect = true
    end

    -- Peril effect
    if doFallingRocks then
        local target
        for _, player in ipairs(REVEL.players) do
            if player then
                target = player
                break
            end
        end

        if target then
            local rand = math.random(10,15)
            for i = 1, rand do
                local pos = REVEL.Lerp(eff.Position,target.Position,0.5) 
                + Vector.One:Resized(math.random(5,20)*i):Rotated(math.random(360))

                if (pos-target.Position):Length() > 20 then
                    local proj = Isaac.Spawn(9, 9, 0, pos, Vector.Zero, eff):ToProjectile()
                    proj.Height = -230 + -30*i
                    proj.FallingAccel = 2
                    proj.FallingSpeed = -40 + math.random(-10,10)
                end
            end
        end
    end

    if isDead then
        REVEL.game:ShakeScreen(10)
        REVEL.sfx:Play(REVEL.SFX.BOULDER_BREAK, 1, 0, false, 1)

        for i=1, math.random(3,7) do
            local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, eff.Position, Vector(math.random()-0.5,math.random()-0.5)*10, eff)
            rock:Update()
        end

        REVEL.SpawnDecoration(eff.Position, Vector.Zero, "Death", sprite:GetFilename(), eff, -1000, -1)
        eff:Remove()

        local boulders = REVEL.ENT.SAND_BOULDER:getInRoom()
        local boulderRolling = REVEL.some(boulders, function(b)
            if GetPtrHash(b) == GetPtrHash(eff) then return false end

            local sprite = b:GetSprite()
            return REVEL.some(rollVariants, function(anim) return sprite:IsPlaying('Rolling' .. anim) end)
        end)

        if not boulderRolling then
            REVEL.sfx:Stop(REVEL.SFX.BOULDER_ROLL)
        end
    end
end, REVEL.ENT.SAND_BOULDER.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, eff)
    if eff:GetData().UrnyFallingEffect then
        if eff.FrameCount <= 20 then
            eff:GetSprite().Offset = Vector(0, -600+(30*eff.FrameCount))
        else
            local urny = Isaac.Spawn(REVEL.ENT.URNY.id, REVEL.ENT.URNY.variant, 0, eff.Position, Vector.Zero, nil)
            urny:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
            urny:GetData().AlwaysActive = true
            eff:Remove()
        end
    end
end, 6)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    REVEL.sfx:Stop(REVEL.SFX.BOULDER_ROLL)
end)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, ent)
    if ent.Variant == REVEL.ENT.SAND_BOULDER.variant then
        local boulders = Isaac.FindByType(EntityType.ENTITY_EFFECT, REVEL.ENT.SAND_BOULDER.variant, -1, false, false)
        local boulderRolling = false
        for _,v in ipairs(boulders) do
            if GetPtrHash(v) ~= GetPtrHash(ent) then
                local sprite = v:GetSprite()
                for _, variant in ipairs(rollVariants) do
                    if sprite:IsPlaying("Rolling" .. variant) then
                        boulderRolling = true
                        break
                    end
                end
            end

            if boulderRolling then
                break
            end
        end
        if not boulderRolling then
            REVEL.sfx:Stop(REVEL.SFX.BOULDER_ROLL)
        end
    end
end, REVEL.ENT.SAND_BOULDER.id)

end