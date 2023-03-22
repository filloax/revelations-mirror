local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local PlayerVariant     = require("lua.revelcommon.enums.PlayerVariant")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---------------------
-- CARDBOARD ROBOT --
---------------------

--[[
Active. 6 room charge.
Item Visual: a cardboard remote.
Costume Visual: two stacked cardboard boxes with a crayon face drawn on the top box, with eye slits cut out.
On use, calls down a cardboard robot that drops from the sky on Isaacs position, causing contact damage and pushing back nearby enemies. Isaac controls the robot from inside, shuffling along. The robot has 1 soul heart of health that temporarily replaces other health. Losing this heart will lose the robot.
For 15 seconds the player gains a short range 7 shot that shotguns out from the eye slits. Persists through rooms. While inside the robot, battery drops become far more common at the end of a room clear, and extend the duration by another 10 seconds.
Upon losing its soul heart, or running out of time, the robot stops moving and flashes three times rapidly. The player can use their active item and a direction to launch the robot as a bomb, while ejecting out the back.
]]

revel.robot = {
    defTimeout = 525,
    defDmgCool = 35,
    tearLife = 13,
    yDiff = 32, -- height distance between player and player inside robot
    spawnDur = 17, -- duration of Spawn animation
    redColor = Color(1, 1, 1, 1, conv255ToFloat(80, 0, 0)),
    flagBlackList = {[TearFlags.TEAR_EXPLOSIVE] = TearFlags.TEAR_POISON}
}

local function spawnRobot(player, firstSpawn)
    local data = player:GetData()
    local robot = REVEL.ENT.ROBOT:spawn(player.Position, Vector.Zero, player)
    local head = Sprite()
    data.robot = robot
    robot:GetData().head = head
    --      data.robotTime = revel.robot.defTimeout
    data.renderRobot = true
    REVEL.ZPos.SetPlayerJumpSprites(player, data.robot:GetSprite(), head)
    robot:GetData().owner = player
    robot:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    robot.Visible = false

    if firstSpawn then
        robot:GetSprite():Play("Spawn", true)

        REVEL.LockPlayerControls(player, "Robot")
        data.RobotExploding = nil

        if player:GetPlayerType() == PlayerType.PLAYER_THESOUL and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
            REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, true)
            local playerID = REVEL.GetPlayerID(player)
            REVEL.LockEntityVisibility(REVEL.players[playerID]:GetData().Bone, "crobot")
        end
        if data.Bone then 
            REVEL.LockEntityVisibility(data.Bone, "crobot")
        end
    else
        robot:GetData().State = "Default"
    end
end

local function startExplosion(robot, player)
    local spr, data = robot:GetSprite(), robot:GetData()

    spr:Play("Pulse", true)
    spr:RemoveOverlay()
    player:GetData().RobotExploding = true
    data.State = "Pulse"
    data.head = nil
    spr.PlaybackSpeed = 1
    spr.Color = Color.Default
    if player:GetData().Bone then
        REVEL.UnlockEntityVisibility(player:GetData().Bone, "crobot")
    end
end

local function deattachRobot(robot, player)
    robot.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
    robot.Velocity = robot.Velocity * 2.3
    REVEL.UnlockEntityVisibility(player, "crobot")
    player.Color = player:GetData().origColor
    player:GetData().origColor = nil
    player:GetData().renderRobot = false
    REVEL.ZPos.ClearPlayerJumpSprites(player)
    player:GetData().robot = nil
    robot.Visible = true
end

revel:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, itemID, itemRNG, player, useFlags, activeSlot, customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY)
    and player.Variant == PlayerVariant.PLAYER then

        local data = player:GetData()

        if not data.robot and (Isaac.CountEntities(nil, REVEL.ENT.ROBOT.id, REVEL.ENT.ROBOT.variant, -1) or 0) <= 0 then
            spawnRobot(player, true)

            if player:GetActiveItem() == itemID then
                player:RemoveCollectible(itemID)
                player:AddCollectible(REVEL.ITEM.ROBOT2.id, 0, false)
                -- REVEL.SetCharge(REVEL.GetMaxCharge(player, false), player, false)
            end

            return true
        end

    end
end, REVEL.ITEM.ROBOT.id)

revel:AddCallback(ModCallbacks.MC_USE_ITEM,
                    function(_, itemID, itemRNG, player, useFlags, activeSlot,
                            customVarData)
    if not HasBit(useFlags, UseFlag.USE_CARBATTERY) and player.Variant == PlayerVariant.PLAYER then

        local data = player:GetData()

        if data.robot and data.robot:GetData().State == "Default" then
            REVEL.SetCharge(0, player, false)
            return true
        end

    end
end, REVEL.ITEM.ROBOT2.id)

REVEL.AddCustomBar(REVEL.ITEM.ROBOT2.id, revel.robot.defTimeout, true, nil, 0)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    for i, player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.robot then -- had robot last room
            data.robot:Remove()

            if not data.RobotExploding then
                spawnRobot(player, false)
            else
                REVEL.UnlockEntityVisibility(player, "crobot")
                player.Color = data.origColor
                data.robot = nil
            end
        end
    end
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 2, function(room)
    for i, p in ipairs(REVEL.players) do
        if p:GetData().robot then
            REVEL.AddCharge(REVEL.GetMaxCharge(p, true) * 0.3, p, true)
        end
    end
end)

function revel.robot.AnimWalkFrame(dir, spr, data)
    if REVEL.dirToString[dir] then
        if not spr:IsPlaying("Walk" .. REVEL.dirToString[dir]) then
            spr:Play("Walk" .. REVEL.dirToString[dir], true)
            REVEL.SkipAnimFrames(spr, data.WalkFrame + 1)
        end
    else
        spr:Play("Idle", true)
    end

    data.WalkFrame = spr:GetFrame()
end

function revel.robot.AnimArmFrame(dir, spr, data)
    if not dir or dir == Direction.NO_DIRECTION then
        dir = Direction.DOWN
    end
    if REVEL.dirToString[dir] then
        if not IsAnimOn(spr, "Arm" .. REVEL.dirToString[dir]) then
            spr:Play("Arm" .. REVEL.dirToString[dir], true)
        end
    end
end

revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, function(_, p)
    local data = p:GetData()

    if p:GetActiveItem() == REVEL.ITEM.ROBOT2.id then
        if data.robot then
            REVEL.ChargeYellowOn(p)
            if data.Bone then             
                REVEL.LockEntityVisibility(data.Bone, "crobot")
            end
        else
            REVEL.SetCharge(REVEL.GetMaxCharge(p, false), p, false)
            if REVEL.ITEM.ROBOT2:PlayerHasCollectible(p) then
                p:RemoveCollectible(REVEL.ITEM.ROBOT2.id)
                p:AddCollectible(REVEL.ITEM.ROBOT.id, 0, false)
            end
        end
    end

    if p:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
        if data.robot and not data.crobotDisabledDrop then
            REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, false, nil, REVEL.ITEM.ROBOT2.id)
            data.crobotDisabledDrop = true
        elseif not data.robot and data.crobotDisabledDrop then
            REVEL.ClearForceInput(player, REVEL.ITEM.ROBOT2.id)
            data.crobotDisabledDrop = nil
        end
    end

    local robot2max = REVEL.CalcMaxCharge(revel.robot.defTimeout, p) -- for first pickup with battery, would have only green bar at first pickup else
    if p:GetActiveItem() == REVEL.ITEM.ROBOT.id and
        REVEL.GetCharge(p, REVEL.ITEM.ROBOT2.id) ~= robot2max then
        REVEL.SetCharge(robot2max, p, false, REVEL.ITEM.ROBOT2.id)
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function(_, p, renderOffset)
    local data = p:GetData()
    local robot = data.robot
    if robot and data.renderRobot then
        robot:GetSprite():Render(Isaac.WorldToScreen(p.Position) + renderOffset - REVEL.room:GetRenderScrollOffset())
        if robot:GetData().head then
            robot:GetData().head:Render(Isaac.WorldToScreen(p.Position) + renderOffset - REVEL.room:GetRenderScrollOffset())
        end
    end
end)

local function ChainLaser(pos, angle, maxDistance, randAngle,
                            setDepthOffset, spawner, lasers, maxChain,
                            numChains, damage, color)
    numChains = numChains or 0

    if maxChain and numChains > maxChain then return false end

    local nextPos = pos + Vector.FromAngle(angle) * maxDistance
    local nearestEnemy
    local nearestDist
    for _, enemy in ipairs(REVEL.roomEnemies) do
        if enemy:IsVulnerableEnemy() and
            not enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) and
            enemy:IsActiveEnemy(false) and not enemy:GetData().ChainedTo then
            local dist = enemy.Position:Distance(nextPos)
            if not nearestDist or dist < nearestDist then
                nearestEnemy = enemy
                nearestDist = dist
            end
        end
    end

    if nearestDist and nearestDist <= maxDistance then
        nearestEnemy:GetData().ChainedTo = true
        local nextAngle = angle + math.random(-randAngle, randAngle)
        local laser = EntityLaser.ShootAngle(2, nextPos, nextAngle, 3,
                                                Vector.Zero, spawner)
        laser.MaxDistance = maxDistance
        laser.CollisionDamage = damage
        laser.Color = color

        if setDepthOffset then laser.DepthOffset = 100 end

        lasers[#lasers + 1] = laser

        return ChainLaser(nextPos, nextAngle, maxDistance, randAngle,
                            setDepthOffset, spawner, lasers, maxChain,
                            numChains + 1, damage, color)
    else
        for _, enemy in ipairs(REVEL.roomEnemies) do
            enemy:GetData().ChainedTo = false
        end

        return false
    end
end

local function ShootArcLaser(pos, angle, numRandom, maxDistance, randAngle,
                                setDepthOffset, spawner, lasers, noLastRandom,
                                maxChain, damage, color)
    local fromPos, fromAngle = pos, angle
    for i = 1, numRandom do
        if ChainLaser(fromPos, fromAngle, maxDistance, randAngle,
                        setDepthOffset, spawner, lasers, maxChain, nil,
                        damage, color) then
            break
        elseif not noLastRandom or i ~= numRandom then
            local laser = EntityLaser.ShootAngle(2, fromPos, fromAngle, 3,
                                                    Vector.Zero, spawner)
            laser.MaxDistance = maxDistance
            laser.CollisionDamage = damage
            laser.Color = color

            if setDepthOffset then laser.DepthOffset = 100 end

            lasers[#lasers + 1] = laser

            fromPos, fromAngle = pos + Vector.FromAngle(fromAngle) * 50,
                                    fromAngle +
                                        math.random(-randAngle, randAngle)
        end
    end
end

local crobotLaserColor = Color(0, 0, 0, 1, conv255ToFloat(0, 128, 128))

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, e)
    if e.Variant ~= REVEL.ENT.ROBOT.variant then return end

    local spr, data = e:GetSprite(), e:GetData()
    local ownerdata = data.owner:GetData()

    if not data.init then
        data.WalkFrame = 0
        data.FireDelay = 0
        data.dmgCool = 0
        data.redColorCool = 0
        data.head:Load(spr:GetFilename(), true)

        if not data.State then data.State = "Spawn" end -- set in NEW_ROOM too

        data.init = true
    end

    if data.State == "Spawn" then
        e.Position = data.owner.Position
        e.Velocity = data.owner.Velocity

        if spr:IsEventTriggered("Land") then
            ownerdata.origColor = REVEL.CloneColor(data.owner.Color)
            data.owner.Color = REVEL.NO_COLOR
            REVEL.sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.5, 0,
                            false, 1)
            REVEL.game:ShakeScreen(15)
            local ents = Isaac.FindInRadius(e.Position, 64,
                                            EntityPartition.ENEMY)
            for i, v in ipairs(ents) do
                v:TakeDamage(75, DamageFlag.DAMAGE_EXPLOSION,
                                EntityRef(data.owner), 10)
            end
        elseif spr:IsEventTriggered("HideItem") then
            data.owner:AnimateCollectible(REVEL.ITEM.ROBOT.id, "HideItem",
                                            "PlayerPickup")
        end

        if spr:IsFinished("Spawn") then
            REVEL.UnlockPlayerControls(data.owner, "Robot")
            data.State = "Default"
        end

    elseif data.State == "Default" then
        e.Position = data.owner.Position
        e.Velocity = data.owner.Velocity

        spr.PlaybackSpeed = e.Velocity:Length() / 2

        local time = REVEL.GetCharge(data.owner, REVEL.ITEM.ROBOT2.id)

        if not REVEL.ITEM.ROBOT:PlayerHasCollectible(data.owner) and
            not REVEL.ITEM.ROBOT2:PlayerHasCollectible(data.owner) then
            time = 0
        end

        data.owner.FireDelay = 25

        if data.dmgCool > 1 then
            data.dmgCool = data.dmgCool - 1
            if math.floor(data.dmgCool / 2) % 2 == 0 then
                spr.Color = REVEL.NO_COLOR
            else
                spr.Color = Color.Default
            end

        elseif data.dmgCool == 1 then
            data.dmgCool = 0
            spr.Color = Color.Default
        end

        if time == 0 then
            startExplosion(e, data.owner)
            REVEL.SetCharge(REVEL.GetMaxCharge(data.owner, false),
                            data.owner, false)
            if REVEL.ITEM.ROBOT2:PlayerHasCollectible(data.owner) then
                data.owner:RemoveCollectible(REVEL.ITEM.ROBOT2.id)
                data.owner:AddCollectible(REVEL.ITEM.ROBOT.id, 0, false)
            end
            if data.owner:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
                for i=1, 2 do
                    data.owner:AddWisp(REVEL.ITEM.ROBOT.id, data.owner.Position)
                end
            end
            return

        else
            REVEL.AddCharge(-1, data.owner, false, REVEL.ITEM.ROBOT2.id)

            if time < 45 then
                if math.floor(time / 3) % 2 == 0 then
                    spr.Color = revel.robot.redColor
                else
                    spr.Color = Color.Default
                end
            elseif data.dmgCool == 0 then
                spr.Color = Color.Default
            end
        end

        if data.redColorCool > 0 then
            data.redColorCool = data.redColorCool - 1
            spr.Color = revel.robot.redColor
        end

        revel.robot.AnimWalkFrame(data.owner:GetMovementDirection(), spr,
                                    data)

        if data.head then -- it gets removed just before jumping
            data.head:Update()

            local input
            local firedir = data.owner:GetFireDirection()
            if REVEL.player:HasCollectible(465) then -- analog stick synergy
                input = data.owner:GetShootingInput() *
                            (10 * data.owner.ShotSpeed)
            else
                input = REVEL.dirToVel[firedir] *
                            (10 * data.owner.ShotSpeed)
            end

            if (input.X ~= 0 or input.Y ~= 0) and REVEL.dirToString[firedir] then
                if not data.head:IsPlaying("FireArm" ..
                                                REVEL.dirToString[firedir]) then
                    data.head:Play("FireArm" .. REVEL.dirToString[firedir],
                                    true)
                end

                if not data.Lasers then data.Lasers = {} end

                if data.LastInput then
                    if math.abs(data.LastInput:GetAngleDegrees() -
                                    input:GetAngleDegrees()) >= 90 then
                        for _, laser in ipairs(data.Lasers) do
                            laser:SetTimeout(2)
                        end

                        data.Lasers = {}
                    end
                end

                for i, laser in ripairs(data.Lasers) do
                    if not laser:Exists() then
                        table.remove(data.Lasers, i)
                    end
                end

                data.LastInput = input

                local xOff, yOff = 0, 0
                if firedir == Direction.DOWN or firedir == Direction.UP then
                    xOff = math.random(-8, 8)
                else
                    yOff = math.random(-2, 2)
                end

                local pos = e.Position + Vector(xOff, -47 + yOff)
                local langle = input:GetAngleDegrees() +
                                    math.random(-30, 30)

                ShootArcLaser(pos, langle, 3, 50, 45,
                                firedir == Direction.DOWN, data.owner,
                                data.Lasers, true, nil,
                                1.6 + (0.2 * REVEL.level:GetStage()),
                                crobotLaserColor)
            elseif input.X == 0 and input.Y == 0 then
                revel.robot.AnimArmFrame(data.owner:GetMovementDirection(),
                                            data.head, data)
            end

            if data.FireDelay > 0 then
                data.FireDelay = data.FireDelay - 1
            end
        end

    elseif data.State == "Pulse" then
        if not spr:WasEventTriggered("Jump") then
            e.Position = data.owner.Position
            e.Velocity = data.owner.Velocity

        elseif spr:IsEventTriggered("Boom") then
            ownerdata.robot = nil
            e:Remove()
            REVEL.game:BombExplosionEffects(e.Position,
                                            100, 0,
                                            Color(1, 1, 1, 1,
                                                    conv255ToFloat(0, 0, 0)),
                                            e, 1, true, true)

        elseif spr:IsEventTriggered("Jump") then
            deattachRobot(e, data.owner)

        elseif spr:WasEventTriggered("Land") then
            e.Velocity = Vector.Zero
        end

        if REVEL.room:GetGridCollisionAtPos(e.Velocity + e.Position) ==
            GridCollisionClass.COLLISION_PIT then
            e.Velocity = Vector.Zero
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,
                    function(_, e, dmg, flag, src)
    local pdata = e:GetData()
    local robot = pdata.robot
    if robot and not HasBit(flag, DamageFlag.DAMAGE_FAKE) then
        local data = robot:GetData()
        if data.State == "Spawn" or (data.dmgCool and data.dmgCool > 0) then
            return false
        else
            REVEL.sfx:Play(SoundEffect.SOUND_SLOTSPAWN, 0.7, 0, false, 0.9)
            data.dmgCool = revel.robot.defDmgCool
            data.redColorCool = 3
            REVEL.AddCharge(-(revel.robot.defTimeout / 4), e:ToPlayer(),
                            false)
            return false
        end
    end
end, 1)

-- Virtues wisp
revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, e)
    if e.SubType == REVEL.ITEM.ROBOT.id then
        local data = e:GetData()
        local input
        local firedir = e.Player:GetFireDirection()
        if REVEL.player:HasCollectible(465) then -- analog stick synergy
            input = e.Player:GetShootingInput() *
                        (10 * e.Player.ShotSpeed)
        else
            input = REVEL.dirToVel[firedir] *
                        (10 * e.Player.ShotSpeed)
        end

        if (input.X ~= 0 or input.Y ~= 0) and REVEL.dirToString[firedir] and e.FrameCount%4 == 0 then
            local xOff, yOff = 0, 0
            if firedir == Direction.DOWN or firedir == Direction.UP then
                xOff = math.random(-8, 8)
            else
                yOff = math.random(-2, 2)
            end

            local pos = e.Position + Vector(xOff, -16 + yOff)
            local langle = input:GetAngleDegrees() +
                                math.random(-30, 30)

            local laser = EntityLaser.ShootAngle(2, pos, langle, 3,
                                                    Vector.Zero, e.Player)
            laser.MaxDistance = 80
            laser.CollisionDamage = 3
            laser.Color = crobotLaserColor

        end

    end
end, FamiliarVariant.WISP)

end
