local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

-- Draugr / Haugr / Jaugr / Juniaugr
local draugrBalance = {
    Champions = {Haugr = "Default", Jaugr = "Default"},
    Speed = {
        Default = 0.65,
        Haugr = 0.35,
        Jaugr = 0.45,
        Juniaugr = 1,
    },
    GrilloEmptySpeed = {
        Default = 0.75,
        Haugr = 0.4,
        Juniaugr = 1,
    },
    DashSpeed = {
        Default = -1,
        Jaugr = 20,
    },
    -- ChaseGrilloSpeed = {
    --     Default =
    -- },
    EatSpeed = {
        Default = 5,
        Haugr = 3,
    },
    WalkAnims = {Horizontal = "WalkHori", Vertical = "WalkVert"},
    HeadAnims = {Horizontal = "WalkHoriHead", Vertical = "WalkVertHead"},
    EatDistance = {
        Default = 20,
        Haugr = 40,
    },
    TargetDistance = {
        Default = -1,
        Haugr = 70,
    },
    ChillRadiusMult = 1,
    GrilloRadiusMult = {
        Default = 1,
    },
    GrilloFixedRadius = {
        Default = -1,
        Haugr = 100,
    },
    CanEatChillo = {
        Default = true,
        Haugr = false,
    },
    CanEatGrillo = {
        Default = true,
        Jaugr = false,
    },
    Variants = {
        Default = {
            {},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_koala_empty.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_bai_empty3.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz_empty4.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz2_empty5.png"},
        },
        Haugr = {
        },
        Jaugr = {
        },
        Juniaugr = {
        },
    },
    ChilloSkin = {
        Default = {
            {[1] = "gfx/monsters/revel1/draugr/draugr_head_chillo_1.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_koala_chillo.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_bai_chillo3.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz_chillo4.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz2_chillo5.png"},
        },
        Haugr = {
        },
        Jaugr = {
        },
        Juniaugr = {
            {[0] = "gfx/monsters/revel1/draugr/juniaugr_chillo.png"}
        },
    },
    GrilloSkin = { --add quartz draugr
        Default = {
            {[1] = "gfx/monsters/revel1/draugr/draugr_head_grillo_1.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_koala_grillo.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_bai_grillo3.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz_grillo4.png"},
            {[1] = "gfx/monsters/revel1/draugr/draugr_variant_head_qz2_grillo5.png"},
        },
        Haugr = {
        },
        Jaugr = {
        },
        Juniaugr = {
            {[0] = "gfx/monsters/revel1/draugr/juniaugr_grillo.png"}
        },
    },
    ChilloGlow = {
        Default = {
            "gfx/monsters/revel1/draugr/draugr_head_chillo_glow_1.png",
            "gfx/monsters/revel1/draugr/draugr_variant_koala_chillo_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_bai_chillo3_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_qz_chillo4_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_qz2_chillo5_glow.png",
        },
        Haugr = {
        },
        Jaugr = {

        },
    },
    GrilloGlow = {
        Default = {
            "gfx/monsters/revel1/draugr/draugr_head_grillo_glow_1.png",
            "gfx/monsters/revel1/draugr/draugr_variant_koala_grillo_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_bai_grillo3_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_qz_grillo4_glow.png",
            "gfx/monsters/revel1/draugr/draugr_variant_head_qz2_grillo5_glow.png",
        },
        Haugr = {
        },
        Jaugr = {
        },
    },
    GlowAlpha = 1,
    GlowAlphaFlickerAmp = 0.35,
    GlowAlphaFlickerFreq = 0.6,

    JaugrBatAnims = {"PunchBat", "PunchBat2"},
    PunchDistance = 20,
    PunchDistanceHori = 50,
    DashCooldown = {Min = 60, Max = 90},
    DashMinDistance = 180,
    JaugrDashStopsAtHazards = false,
    JaugrSpikedHazards = true,
}

local HaugrFireSpriteWalkOffset = {0,0, 0,0, 0,0, 0,0, 0,0, 0,-1.5, -3,-2.5, -2,-1, 0,0, 0,0, 0,0, 0,0, 0,0, 0,0, 0,-1.5, -3,-2.5, -2,-1, 0,0}

local function indexFromEnt(ent) return REVEL.room:GetGridIndex(ent.Position) end

local function isDraugrHolding(npc, entDefinition) --assumes all held entities are of the same type
    local data = npc:GetData()
    return data.Holding and #data.Holding > 0 and entDefinition:isEnt(data.Holding[1])
end

--both path maps (ignore fire and avoid fire) use the same logic for singular draugr processing after deciding
--if that draugr avoids fire or not
local function processDraugrTargetsForMap(draugr, targetSets, grillosAndFires, chillos, ...)
    local data = draugr:GetData()
    local targetingChilloOrGrillo
    local draugrTables = {...}

    local i = #targetSets + 1

    if not (data.Holding and #data.Holding > 0) then
        if data.bal.CanEatGrillo and not grillosAndFires then
            local grillos = REVEL.ENT.GRILL_O_WISP:getInRoom()
            local fires = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 0, -1, false, false)
            local firesRed = Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 1, -1, false, false)

            grillosAndFires = grillos

            for i = 1, #fires + #firesRed do
                local fire = (i <= #fires) and fires[i] or firesRed[i - #fires]

                -- REVEL.DebugToConsole(REVEL.room:GetGridIndex(fire.Position), fire.HitPoints)

                if fire.HitPoints > 1 then
                    grillosAndFires[#grillosAndFires + 1] = fire
                end
            end
        end

        chillos = chillos or (data.bal.CanEatChillo and REVEL.ENT.CHILL_O_WISP:getInRoom()) --no need to get chillos if they aren't needed

        if data.bal.CanEatGrillo and grillosAndFires and #grillosAndFires > 0 then
            if data.bal.TargetDistance > 0 then
                targetSets[i] = {Targets = REVEL.flatmap(grillosAndFires, function(grillo)
                    if grillo.Position:DistanceSquared(draugr.Position) < data.bal.TargetDistance * data.bal.TargetDistance then
                        return indexFromEnt(grillo)
                    end
                end)}
                targetingChilloOrGrillo = #targetSets[i].Targets > 0
            else
                targetSets[i] = {Targets = REVEL.map(grillosAndFires, indexFromEnt)}
                targetingChilloOrGrillo = true
            end
        elseif data.bal.CanEatChillo and chillos and #chillos > 0 then
            if data.bal.TargetDistance > 0 then
                targetSets[i] = {Targets = REVEL.flatmap(chillos, function(chillo)
                    if chillo.Position:DistanceSquared(draugr.Position) < data.bal.TargetDistance * data.bal.TargetDistance then
                        return indexFromEnt(chillo)
                    end
                end)}
                targetingChilloOrGrillo = #targetSets[i].Targets > 0
            else
                targetSets[i] = {Targets = REVEL.map(chillos, indexFromEnt)}
                targetingChilloOrGrillo = true
            end
        end
    end

    if not targetingChilloOrGrillo then
        if REVEL.ENT.DRAUGR:isEnt(draugr) and isDraugrHolding(draugr, REVEL.ENT.GRILL_O_WISP) then --run away from other draugr too
            local targets = {}

            for _, draugrs in ipairs(draugrTables) do
                for __, d2 in ipairs(draugrs) do
                    if GetPtrHash(d2) ~= GetPtrHash(draugr) then
                        targets[#targets+1] = indexFromEnt(d2)
                    end
                end            
            end 

            targetSets[i] = {Targets = targets}
        end
        targetSets[i] = targetSets[i] or {Targets = {}}
        targetSets[i].Targets[#targetSets[i].Targets + 1] = indexFromEnt(draugr:ToNPC():GetPlayerTarget())
    end

    -- REVEL.DebugToString(targetingChilloOrGrillo, targetSets[i])

    data.TargetSetIndex = i

    --return grillo/chillo tables since they're needed for the loop, and the reference gets changed if they were nil at at start
    return grillosAndFires, chillos
end

local function draugrAvoidsFire(draugr)
    local data = draugr:GetData()

    return (data.Holding and #data.Holding > 0 and not REVEL.ENT.HAUGR:isEnt(draugr)) or not data.bal.CanEatGrillo
end

local function ShouldRunAway(draugr)
    return (REVEL.ENT.DRAUGR:isEnt(draugr) or REVEL.ENT.JUNIAUGR:isEnt(draugr)) and isDraugrHolding(draugr, REVEL.ENT.GRILL_O_WISP)
end

--Used by draugr and haugr
local DraugrIgnoreFireMap = REVEL.NewPathMapFromTable("DraugrIgnoreFire", {
    GetTargetSets = function()
        local targetSets = {}
        local grillosAndFires, chillos
        local draugrs, haugrs, juniaugrs = REVEL.ENT.DRAUGR:getInRoom(), REVEL.ENT.HAUGR:getInRoom(), REVEL.ENT.JUNIAUGR:getInRoom()

        for i, draugr, _ in REVEL.MultiTableIterate(draugrs, haugrs, juniaugrs) do
            if not draugrAvoidsFire(draugr) then
                local rgrillosAndFires, rchillos = processDraugrTargetsForMap(draugr, targetSets, grillosAndFires, chillos, draugrs, haugrs, juniaugrs)
                grillosAndFires = rgrillosAndFires
                chillos = rchillos
                draugr:GetData().UsingAvoidFireMap = false
            end
        end

        return targetSets
    end,

    GetInverseCollisions = function()
        return REVEL.GetPassableGrids(true, true, false, true) --ignore fire (4th arg=true)
    end,

    OnPathUpdate = function(map)
        local draugrs = Isaac.FindByType(REVEL.ENT.DRAUGR.id, -1, -1, false, false)

        for _, draugr in pairs(draugrs) do
            local data = draugr:GetData()

            if not data.UsingAvoidFireMap then

                data.Path = nil
                data.PathIndex = nil

                if data.TargetSetIndex and map.TargetMapSets[data.TargetSetIndex] then
                    local runAway = ShouldRunAway(draugr)

                    if runAway and map.TargetMapSets[data.TargetSetIndex].FarthestIndex then
                        data.Path = REVEL.GeneratePathAStar(REVEL.room:GetGridIndex(draugr.Position), map.TargetMapSets[data.TargetSetIndex].FarthestIndex)
                    elseif not runAway then
                        data.Path = REVEL.GetPathToZero(REVEL.room:GetGridIndex(draugr.Position), map.TargetMapSets[data.TargetSetIndex].Map, nil, map)
                    end

                    if data.Path and #data.Path == 0 then
                        data.Path = nil
                    end
                end
            end
        end
    end
})

local DraugrAvoidFireMap = REVEL.NewPathMapFromTable("DraugrAvoidFire", {
    GetTargetSets = function()
        local targetSets = {}
        local grillosAndFires, chillos
        local draugrs, haugrs, jaugrs, juniaugrs = REVEL.ENT.DRAUGR:getInRoom(), REVEL.ENT.HAUGR:getInRoom(), REVEL.ENT.JAUGR:getInRoom(), REVEL.ENT.JUNIAUGR:getInRoom()

        for i, draugr, _ in REVEL.MultiTableIterate(draugrs, haugrs, jaugrs, juniaugrs) do
            if draugrAvoidsFire(draugr) then
                local rgrillosAndFires, rchillos = processDraugrTargetsForMap(draugr, targetSets, grillosAndFires, chillos, draugrs, haugrs, juniaugrs)
                grillosAndFires = rgrillosAndFires
                chillos = rchillos
                draugr:GetData().UsingAvoidFireMap = true
            end
        end

        return targetSets
    end,

    GetInverseCollisions = function()
        return REVEL.GetPassableGrids(true, true, false, false) --don't ignore fire (4th arg=false)
    end,

    OnPathUpdate = function(map)
        local draugrs, jaugrs, juniaugrs = REVEL.ENT.DRAUGR:getInRoom(), REVEL.ENT.JAUGR:getInRoom(), REVEL.ENT.JUNIAUGR:getInRoom()

        for _, draugr in REVEL.MultiTableIterate(draugrs, jaugrs, juniaugrs) do
            local data = draugr:GetData()

            if data.UsingAvoidFireMap then
                data.Path = nil
                data.PathIndex = nil

                if data.TargetSetIndex and map.TargetMapSets[data.TargetSetIndex] then
                    local runAway = ShouldRunAway(draugr)

                    if runAway and map.TargetMapSets[data.TargetSetIndex].FarthestIndex then
                        data.Path = REVEL.GeneratePathAStar(REVEL.room:GetGridIndex(draugr.Position), map.TargetMapSets[data.TargetSetIndex].FarthestIndex)
                    elseif not runAway then
                        data.Path = REVEL.GetPathToZero(REVEL.room:GetGridIndex(draugr.Position), map.TargetMapSets[data.TargetSetIndex].Map, nil, map)
                    end

                    if data.Path and #data.Path == 0 then
                        data.Path = nil
                    end
                end
            end
        end
    end
})

local function draugrPathMapFireplaceEntityTakeDmg(_, ent, dmg)
    if ent.HitPoints - dmg <= 1 and REVEL.ENT.DRAUGR:countInRoom() + REVEL.ENT.HAUGR:countInRoom() + REVEL.ENT.JUNIAUGR:countInRoom() > 0 then
        REVEL.UpdatePathMap(DraugrIgnoreFireMap, true)
        REVEL.UpdatePathMap(DraugrAvoidFireMap, true)
    end
end

local StartChilledSubtype = 1
local StartGrilledSubtype = 2
local StartGrilledSmallSubType = 3

local function getBalanceByVariant(npcOrVariant)
    local variant = type(npcOrVariant) == 'number' and npcOrVariant or npcOrVariant.Variant

    if variant == REVEL.ENT.HAUGR.variant then
        return REVEL.GetBossBalance(draugrBalance, "Haugr")
    elseif variant == REVEL.ENT.JAUGR.variant then
        return REVEL.GetBossBalance(draugrBalance, "Jaugr")
    elseif variant == REVEL.ENT.JUNIAUGR.variant then
        return REVEL.GetBossBalance(draugrBalance, "Juniaugr")
    end
    return REVEL.GetBossBalance(draugrBalance, "Default")
end

local function loadSkin(npc, headSkin, glowSkin)
    local sprite, data = npc:GetSprite(), npc:GetData()

    if headSkin and headSkin[data.Variant] then
        for layer, spritesheet in pairs(headSkin[data.Variant]) do
            sprite:ReplaceSpritesheet(layer, spritesheet)
            data.HeadSprite:ReplaceSpritesheet(layer, spritesheet)
        end

        sprite:LoadGraphics()
        data.HeadSprite:LoadGraphics()
    end

    if glowSkin and data.GlowSprite and glowSkin[data.Variant] and not data.NoReplaceGlowSpritesheet then
        data.GlowSprite:ReplaceSpritesheet(0, glowSkin[data.Variant])
        data.GlowSprite:LoadGraphics()
        data.GlowSpriteOn = true
    end
end

---@param npc EntityNPC
---@param entity Entity
local function eat(npc, entity)
    local sprite, data = npc:GetSprite(), npc:GetData()

    local useAura = not REVEL.ENT.JAUGR:isEnt(npc)
    local doRemove = true

    data.Holding = data.Holding or {}
    local index = #data.Holding + 1
    if REVEL.ENT.JUNIAUGR:isEnt(npc) then
        data.Holding[index] = {Type = data.Eating.Type, Variant = data.Eating.Variant,  SubType = 1}
    else
        data.Holding[index] = {Type = data.Eating.Type, Variant = data.Eating.Variant,  SubType = data.Eating.SubType}
    end
    local ateGrillo, ateChillo

    if entity.Type == 33 then
        data.Holding[index] = {Type = REVEL.ENT.GRILL_O_WISP.id, Variant = REVEL.ENT.GRILL_O_WISP.variant, SubType = 1}
        local radius = REVEL.GetChillWarmRadius()
        if data.bal.GrilloFixedRadius > 0 then
            -- data.PrevRadius = radius
            radius = data.bal.GrilloFixedRadius
        end
        if data.bal.GrilloRadiusMult > 0 then
            radius = radius * data.bal.GrilloRadiusMult
        end

        if not REVEL.ENT.HAUGR:isEnt(npc) then --haugr don't get a smaller radius w tiny grillos
            radius = radius * 0.6
        end
        if useAura then
            local auraData = REVEL.SetWarmAura(npc, radius, not not data.Aura)
        end

        if entity:GetData().aura then
            entity:GetData().aura:Remove()
        end

        entity:GetData().SpawnedGrillo = true --prevent grillo spawn
        entity:TakeDamage(99, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)

        ateGrillo = true
        doRemove = false
    elseif REVEL.ENT.GRILL_O_WISP:isEnt(entity) then
        if useAura then
            local eatenAuraData = REVEL.GetWarmAuraData(entity)
            eatenAuraData = eatenAuraData or {
                Radius = REVEL.GetChillWarmRadius(),
            }
            if data.bal.GrilloFixedRadius > 0 then
                eatenAuraData.Radius = data.bal.GrilloFixedRadius
            end
            if data.bal.GrilloRadiusMult > 0 then
                eatenAuraData.Radius = eatenAuraData.Radius * data.bal.GrilloRadiusMult
            end
            if REVEL.ENT.JUNIAUGR:isEnt(npc) and data.Eating.SubType == 0 then 
                eatenAuraData.Radius = eatenAuraData.Radius * 0.6
            end
            local auraData = REVEL.SetWarmAura(npc, eatenAuraData)
            if auraData.Aura and auraData.Aura.Ref then
                if data.Aura then
                    data.Aura:Remove()
                end
                data.Aura = auraData.Aura.Ref
            end
            if data.Aura then
                REVEL.UpdateAuraRadius(data.Aura, auraData.Radius)
                data.Aura.Position = npc.Position
            end
        end

        ateGrillo = true
    elseif REVEL.ENT.CHILL_O_WISP:isEnt(entity) then
        if useAura then
            local eatenAuraData = REVEL.GetChillAuraData(entity)
            if eatenAuraData then
                eatenAuraData.Radius = eatenAuraData.Radius * data.bal.ChillRadiusMult
                if REVEL.ENT.JUNIAUGR:isEnt(npc) and data.Eating.SubType == 0 then 
                    eatenAuraData.Radius = eatenAuraData.Radius * 0.7
                end
                local auraData = REVEL.SetChillAura(npc, eatenAuraData)

                if data.Aura and auraData.Aura.Ref then
                    data.Aura:Remove()
                end
                data.Aura = auraData.Aura.Ref
                REVEL.UpdateAuraRadius(data.Aura, auraData.Radius)
            else
                local radius = entity:GetData().radius or REVEL.GetChillFreezeRadius()
                radius = radius * data.bal.ChillRadiusMult
                if REVEL.ENT.JUNIAUGR:isEnt(npc) and data.Eating.SubType == 0 then 
                    radius = radius * 0.7
                end
                local auraData = REVEL.SetChillAura(
                    npc, 
                    radius,
                    not not data.Aura
                )
                if data.Aura and auraData.Aura.Ref then
                    data.Aura:Remove()
                end
                data.Aura = auraData.Aura.Ref
            end
        end

        ateChillo = true
    end

    if entity:GetData().aura then
        entity:GetData().aura:Remove()
    end

    loadSkin(npc, (ateGrillo and data.bal.GrilloSkin) or (ateChillo and data.bal.ChilloSkin), (ateGrillo and data.bal.GrilloGlow) or (ateChillo and data.bal.ChilloGlow))

    if data.FireSprite and not data.RenderFireSprite then
        data.RenderFireSprite = true
        data.FireSprite:Play("Fire_Appear", true)
    end

    if data.Aura then
        data.Aura:GetData().Spawner = npc
        data.Aura.Parent = npc
    end

    if doRemove then
        entity:Remove()
    end
end

--Draugr and Haugr update
local function draugrHaugrNpcUpdate(_, npc)

    if not (REVEL.ENT.DRAUGR:isEnt(npc) or REVEL.ENT.HAUGR:isEnt(npc) or REVEL.ENT.JUNIAUGR:isEnt(npc)) then return end

    npc.SplatColor = REVEL.CoalSplatColor

    local player = npc:GetPlayerTarget()
    local sprite, data = npc:GetSprite(), npc:GetData()

    if not data.bal then
        data.bal = getBalanceByVariant(npc)
    end

    data.HeadSprite:Update()
    data.HeadSprite.Color = npc.Color
    data.HeadSprite.Scale = npc.SpriteScale
    if data.GlowSprite then
        data.GlowSprite:Update()
        data.GlowSprite.Color = npc.Color
    end

    if REVEL.ENT.JUNIAUGR:isEnt(npc) then
        if data.HeadSprite:IsPlaying("Eat") then
            sprite:Play("Empty", true)
        elseif data.HeadSprite:IsFinished("Eat") then
            sprite:SetFrame("WalkVert", 0)
        else
            REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, data.bal.WalkAnims)
        end
    else
        REVEL.AnimateWalkFrameSpeed(sprite, npc.Velocity, data.bal.WalkAnims)
    end

    local speed = data.bal.Speed

    if not isDraugrHolding(npc, REVEL.ENT.CHILL_O_WISP) then
        speed = data.bal.GrilloEmptySpeed
    end

    local avoidsFire = draugrAvoidsFire(npc)
    if avoidsFire and not REVEL.IsUsingPathMap(DraugrAvoidFireMap, npc) then
        REVEL.UsePathMap(DraugrAvoidFireMap, npc)
        REVEL.StopUsingPathMap(DraugrIgnoreFireMap, npc)
    elseif not avoidsFire and not REVEL.IsUsingPathMap(DraugrIgnoreFireMap, npc) then
        REVEL.UsePathMap(DraugrIgnoreFireMap, npc)
        REVEL.StopUsingPathMap(DraugrAvoidFireMap, npc)
    end

    local runAway = ShouldRunAway(npc)
    if data.Path and not (runAway and #data.Path <= 3) and not data.HeadSprite:IsPlaying("Eat") then
        REVEL.FollowPath(npc, speed, data.Path, true, 0.85)
        REVEL.AnimateWalkFrameSpeed(data.HeadSprite, npc.Velocity, data.bal.HeadAnims, false, true)
    elseif data.HeadSprite:IsPlaying("Eat") then
        if data.Eating then
            local vel = (data.Eating.Position - npc.Position)
            local l = vel:Length()
            if l > data.bal.EatSpeed then vel = vel * (data.bal.EatSpeed / l) end
            npc.Velocity = vel

            data.Eating.Velocity = Vector.Zero

            data.HeadSprite.FlipX = data.Eating.Position.X < npc.Position.X

            if data.HeadSprite:IsEventTriggered("Chomp") and data.Eating and data.Eating:Exists() then
                eat(npc, data.Eating)
                data.Eating = nil
                
            end
        else
            npc.Velocity = Vector.Zero
        end
    else
        local targetPos = data.Path and REVEL.room:GetGridPosition(data.Path[#data.Path]) or npc.Position
        REVEL.MoveRandomly(npc, 90, 45, 100, data.bal.Speed, 0.85, targetPos, true)
        REVEL.AnimateWalkFrameSpeed(data.HeadSprite, npc.Velocity, data.bal.HeadAnims, false, true)
    end

    if data.Holding and #data.Holding > 0 then
        data.RenderOnTopParticles = data.RenderOnTopParticles or {}
        local part
        local height = -35
        local dist = 20
        if REVEL.ENT.JUNIAUGR:isEnt(npc) then
            height = -20
            dist = 10
        end

        if isDraugrHolding(npc, REVEL.ENT.GRILL_O_WISP) then
            part = REVEL.SpawnFireParticles(npc, height, dist)
        elseif isDraugrHolding(npc, REVEL.ENT.CHILL_O_WISP) then
            part = REVEL.SpawnFireParticles(npc, height, dist, nil, REVEL.EmberParticleBlue.Spritesheet)
        end

        if part then
            data.RenderOnTopParticles [#data.RenderOnTopParticles + 1] = part
        end

        if data.Aura then 
            data.Aura:GetData().RenderOnTop = data.RenderOnTopParticles
        end
    end

    local chillAuraData = REVEL.GetChillAuraData(npc)
    if chillAuraData then
        local includesWarmAura = REVEL.IncludesWarmAura(npc)
        if not includesWarmAura and not chillAuraData.Enabled then
            REVEL.EnableChillAura(npc)
        elseif includesWarmAura and chillAuraData.Enabled then
            REVEL.DisableChillAura(npc)
        end
    end

    if not data.Eating and not data.HeadSprite:IsPlaying("Eat") and not ((REVEL.ENT.DRAUGR:isEnt(npc) or REVEL.ENT.JUNIAUGR:isEnt(npc)) and data.Holding and #data.Holding > 0) then
        local eatable = {}
        if data.bal.CanEatChillo then
            eatable = REVEL.ENT.CHILL_O_WISP:getInRoom()
        end
        if data.bal.CanEatGrillo then
            local grillos, fires, firesRed = REVEL.ENT.GRILL_O_WISP:getInRoom(), Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 0, -1, false, false), Isaac.FindByType(EntityType.ENTITY_FIREPLACE, 1, -1, false, false)

            eatable = REVEL.ConcatTables(eatable, grillos)

            for i = 1, #fires + #firesRed do
                local fire = (i <= #fires) and fires[i] or firesRed[i - #fires]

                -- REVEL.DebugToConsole(REVEL.room:GetGridIndex(fire.Position), fire.HitPoints)

                if fire.HitPoints > 1 then
                    eatable[#eatable + 1] = fire
                end
            end
        end

        for _, entity in ipairs(eatable) do
            if not entity:GetData().BeingEaten and npc.Position:DistanceSquared(entity.Position) < (entity.Size + data.bal.EatDistance) ^ 2 then
                -- sprite:Play("Eat", true)
                data.HeadSprite:Play("Eat", true)
                data.Eating = entity
                REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_MUNCH, 1, 0, false, 0.9+(math.random()*0.2))
                data.Eating:GetData().StayStill = true
                data.Eating:GetData().BeingEaten = true
                break
            end
        end
    end

    local bodyAnim = sprite:GetAnimation()
    local headAnim = data.HeadSprite:GetAnimation()
    local headFrame = data.HeadSprite:GetFrame()

    if data.RenderFireSprite then
        data.FireSprite:Update()

        if data.FireSprite:IsFinished("Fire_Appear") then
            data.FireSprite:Play("Fire_Idle", true)
        end
        data.FireSprite.Offset = Vector(0, HaugrFireSpriteWalkOffset[sprite:GetFrame() + 1])
    end

    if data.GlowSprite and headAnim and not IsAnimOn(data.GlowSprite, headAnim) then
        data.GlowSprite:Play(headAnim, true)
        REVEL.SkipAnimFrames(data.GlowSprite, headFrame)
    end
    if data.GlowSprite then
        data.GlowSprite.PlaybackSpeed = data.HeadSprite.PlaybackSpeed
    end

    if npc:HasEntityFlags(EntityFlag.FLAG_ICE) then
        npc:ClearEntityFlags(EntityFlag.FLAG_ICE)
    end
end

local SoundCooldown = {Min = 80, Max = 100}
local currentSoundCooldown = REVEL.GetFromMinMax(SoundCooldown)

local function draugrPostNewRoom()
    local numd, numh, numj = REVEL.ENT.DRAUGR:countInRoom(), REVEL.ENT.HAUGR:countInRoom(), REVEL.ENT.JUNIAUGR:countInRoom()
    local tot = numd + numh + numj
    if tot > 0 then
        currentSoundCooldown = REVEL.GetFromMinMax(SoundCooldown) * REVEL.Lerp2Clamp(0.35, 1, tot, 6, 2)
    end
end

local function draugrPostUpdate()
    local numd, numh, numj = REVEL.ENT.DRAUGR:countInRoom(), REVEL.ENT.HAUGR:countInRoom(), REVEL.ENT.JUNIAUGR:countInRoom()
    local tot = numd + numh + numj
    if tot > 0 then
        if currentSoundCooldown <= 0 then
            local draugrs, haugrs, juniaugrs = REVEL.ENT.DRAUGR:getInRoom(), REVEL.ENT.HAUGR:getInRoom(), REVEL.ENT.JUNIAUGR:getInRoom()
            local i = math.random(tot)
            local pitch = 1
            if i > #haugrs then
                pitch = 1.5
            elseif i > #draugrs then
                pitch = 0.8
            end
            REVEL.sfx:Play(REVEL.SFX.DRAUGR, 1.25, 0, false, pitch)

            currentSoundCooldown = REVEL.GetFromMinMax(SoundCooldown) * REVEL.Lerp2Clamp(0.55, 1, tot, 6, 2)
        else
            currentSoundCooldown = currentSoundCooldown - 1
        end
    end
end

local function isHazardHittableJaugr(entity, jaugr)
    -- if entity.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
    --     REVEL.DebugToConsole(entity:GetData().LockedInPlaceTime, jaugr:GetData().LastFrozenEntitySeed ~= entity.InitSeed, REVEL.room:CheckLine(entity.Position, jaugr:GetPlayerTarget().Position, 0, 1000, false, false))
    -- end
    return entity.Type == REVEL.ENT.ICE_HAZARD_GAPER.id and not entity:GetData().LockedInPlaceTime
    -- Only throw last frozen entity if it can be thrown directly at the player
    and (jaugr:GetData().LastFrozenEntitySeed ~= entity.InitSeed or REVEL.room:CheckLine(entity.Position, jaugr:GetPlayerTarget().Position, 0, 1000, false, false))
end

local function getIsHittableJaugr(jaugr)
    return function(entity)
        return isHazardHittableJaugr(entity, jaugr)
        or REVEL.GetIceHazardForEnt(entity) and not (REVEL.ENT.BROTHER_BLOODY:isEnt(entity) and REVEL.ENT.JAUGR:isEnt(entity:GetData().Host))
    end
end

local function getIsHazardHittableJaugr(jaugr)
    return function(entity)
        return isHazardHittableJaugr(entity, jaugr)
    end
end

local function isCloseEnough(npc, data, entity, distSquared)
    return math.abs(entity.Position.X - npc.Position.X) <= data.bal.PunchDistanceHori 
    and math.abs(entity.Position.Y - npc.Position.Y) <= data.bal.PunchDistance
    or distSquared <= (data.bal.PunchDistance * data.bal.PunchDistance)
end

--Jaugr update
---@param npc EntityNPC
local function jaugrNpcUpdate(_, npc)
    if not REVEL.ENT.JAUGR:isEnt(npc) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    local isChilled = isDraugrHolding(npc, REVEL.ENT.CHILL_O_WISP)
    local animSuffix = isChilled and "_Chillo" or ""

    npc.SplatColor = REVEL.CoalSplatColor

    if not data.State then
        data.DontRenderHeadSprite = true
        data.State = "Walk"
        npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        sprite:Play("Appear" .. animSuffix, true)
        REVEL.UsePathMap(DraugrAvoidFireMap, npc)
    end

    if sprite:IsPlaying("Appear" .. animSuffix) then
        return
    end

    data.HeadSprite:Update()
    data.HeadSprite.Scale = npc.SpriteScale
    data.HeadSprite.Color = sprite.Color

    local playerTarget = npc:GetPlayerTarget()

    if sprite:IsFinished("Appear") then
        data.DontRenderHeadSprite = nil
    end

    if sprite:IsEventTriggered("Laugh") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.JAUGR_LAUGH, 1.3, 0, false, 1)
    end
    if sprite:IsEventTriggered("Punch") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.JAUGR_HIT, 1.1, 0, false, 1)
    end
    if sprite:IsEventTriggered("Dash") then
        REVEL.sfx:NpcPlay(npc, REVEL.SFX.JAUGR_DASH, 1.1, 0, false, 1)
        REVEL.sfx:NpcPlay(npc,SoundEffect.SOUND_SWORD_SPIN,0.8,0,false,0.8)
    end

    if data.State == "Walk" and npc.FrameCount > 5 then
        local dashDir, punchTarget
        local chasingChillo = data.Path and not isChilled and REVEL.ENT.CHILL_O_WISP:countInRoom() > 0

        if data.DashCooldown then
            data.DashCooldown = data.DashCooldown - 1
            if data.DashCooldown <= 0 then
                data.DashCooldown = nil
            end
        end

        if npc.FrameCount > 30 and not data.PunchCooldown and not data.Eating then
            local closeEnts = Isaac.FindInRadius(npc.Position + npc.Velocity, npc.Size + 20 + data.bal.DashSpeed, -1)
            local closeHittableEnts
            if isChilled and math.random() < 0.075 then --chance to give a shit about freezable enemies if not dashing
                closeHittableEnts = REVEL.filter(closeEnts, getIsHittableJaugr(npc))
            else
                closeHittableEnts = REVEL.filter(closeEnts, getIsHazardHittableJaugr(npc))
            end

            local closest, closestDistSquared
            for _, entity in pairs(closeHittableEnts) do
                local distSquared = npc.Position:DistanceSquared(entity.Position)
                if isCloseEnough(npc, data, entity, distSquared)
                and (not closestDistSquared or distSquared < closestDistSquared) then
                    closest = entity
                    closestDistSquared = distSquared
                end
            end

            if closest then
                punchTarget = closest
            end

            if not closest and not data.DashCooldown then
                local hazards = Isaac.FindByType(REVEL.ENT.ICE_HAZARD_GAPER.id, -1, -1, false, false)

                for _, hazard in pairs(hazards) do
                    if not chasingChillo and isHazardHittableJaugr(hazard, npc) and REVEL.dist(npc.Position.Y, hazard.Position.Y) < npc.Size + hazard.Size
                    and npc.Position:DistanceSquared(hazard.Position) > data.bal.DashMinDistance ^ 2
                    and REVEL.room:CheckLine(npc.Position, hazard.Position, 0, 1000, false, false) then
                        dashDir = hazard.Position.X - npc.Position.X
                        data.DashTargeting = hazard
                        break
                    end
                end

                if not dashDir then
                    for _, player in ipairs(REVEL.players) do
                        if REVEL.dist(npc.Position.Y, player.Position.Y) < npc.Size + player.Size
                        and npc.Position:DistanceSquared(player.Position) > data.bal.DashMinDistance ^ 2
                        and REVEL.room:CheckLine(npc.Position, player.Position, 0, 1000, false, false) then
                            dashDir = player.Position.X - npc.Position.X
                            break
                        end
                    end
                end
            end
        elseif data.PunchCooldown then
            data.PunchCooldown = data.PunchCooldown - 1
            if data.PunchCooldown <= 0 then data.PunchCooldown = nil end
        end

        if punchTarget then
            data.DontRenderHeadSprite = true
            data.Punching = punchTarget
            data.Punching:GetData().JaugrStunned = npc
            if data.Punching.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
                sprite:Play(data.bal.JaugrBatAnims[math.random(1, 2)] .. animSuffix, true)
            else
                sprite:Play("PunchFreeze" .. animSuffix, true)
            end
            sprite.FlipX = npc.Position.X > data.Punching.Position.X
            data.State = "Attack"
        elseif dashDir then
            data.State = "Dash"
            sprite:Play("DashStart" .. animSuffix, true)
            sprite.FlipX = dashDir < 0
            data.PunchDir = dashDir < 0 and REVEL.VEC_LEFT or REVEL.VEC_RIGHT
            data.DontRenderHeadSprite = true
            -- data.PunchCooldown = 35
            data.DashCooldown = REVEL.GetFromMinMax(data.bal.DashCooldown)
        else
            if not data.Path then
                REVEL.MoveRandomly(npc, 90, 25, 60, data.bal.Speed, 0.9, playerTarget.Position, true)
            else
                REVEL.FollowPath(npc, data.bal.Speed, data.Path, true, 0.9)
            end

            REVEL.AnimateWalkFrame(sprite, npc.Velocity, data.bal.WalkAnims)
            -- REVEL.AnimateWalkFrame(data.HeadSprite, npc.Velocity, data.bal.HeadAnims, false, true)
            data.HeadSprite.FlipX = sprite.FlipX
            local anim = sprite:GetAnimation()
            if anim and not IsAnimOn(data.HeadSprite, anim .. "Head" .. animSuffix) then
                data.HeadSprite:Play(anim .. "Head" .. animSuffix, true)
                REVEL.SkipAnimFrames(data.HeadSprite, sprite:GetFrame())
            end
            data.DontRenderHeadSprite = nil

            if not data.Eating and not isChilled then
                local eatable = REVEL.ENT.CHILL_O_WISP:getInRoom()

                for _, entity in ipairs(eatable) do
                    if entity:Exists() and not entity:GetData().BeingEaten and npc.Position:DistanceSquared(entity.Position) < (entity.Size + data.bal.EatDistance) ^ 2 then
                        sprite:Play("Eat", true)
                        entity:GetData().StayStill = true
                        entity:GetData().BeingEaten = true
                        data.Eating = entity
                        data.DontRenderHeadSprite = true
                        REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_MUNCH, 1, 0, false, 0.9+(math.random()*0.2))
                        data.State = "Attack"
                        break
                    end
                end
            end
        end
    elseif data.State == "Dash" then
        if sprite:IsFinished("DashStart" .. animSuffix) then
            sprite:Play("DashLoop" .. animSuffix, true)
        end
        if sprite:IsEventTriggered("Dash") then
            data.DashStartFrame = npc.FrameCount
        end
        if sprite:IsPlaying("DashLoop" .. animSuffix) or sprite:WasEventTriggered("Dash") then
            npc.Velocity = npc.Velocity * 0.6
            if npc:CollidesWithGrid() then
                sprite:Play("DashEnd" .. animSuffix, true)
            else
                npc.Velocity = data.PunchDir * data.bal.DashSpeed
                REVEL.DashTrailEffect(npc, 2, 8, "DashLoop" .. animSuffix)

                if not sprite:IsPlaying("DashPunch" .. animSuffix) then
                    local closeEnts = Isaac.FindInRadius(npc.Position + npc.Velocity, npc.Size + 20 + data.bal.DashSpeed, -1)
                    local closeHittableEnts
                    if isChilled then
                        closeHittableEnts = REVEL.filter(closeEnts, getIsHittableJaugr(npc))
                    else
                        closeHittableEnts = REVEL.filter(closeEnts, getIsHazardHittableJaugr(npc))
                    end

                    local closest, closestDistSquared
                    for _, entity in pairs(closeHittableEnts) do
                        local distSquared = npc.Position:DistanceSquared(entity.Position)
                        if isCloseEnough(npc, data, entity, distSquared) and (entity.Position.X > npc.Position.X) == (npc.Velocity.X > 0)
                        and (entity.Type ~= REVEL.ENT.ICE_HAZARD_GAPER.id or data.bal.JaugrDashStopsAtHazards)
                        and (npc.FrameCount - data.DashStartFrame < entity.FrameCount)
                        and (not closestDistSquared or distSquared < closestDistSquared) then
                            closest = entity
                            closestDistSquared = distSquared
                        end
                    end

                    if closest then
                        data.Punching = closest
                        data.Punching:GetData().JaugrStunned = npc
                        if isChilled then
                            sprite:Play("DashPunch" .. animSuffix, true)
                            data.State = "Attack"
                        else
                            sprite:Play("DashEnd" .. animSuffix, true)
                        end
                    end
                end
            end
        else
            npc.Velocity = npc.Velocity * 0.6
        end

        if sprite:IsFinished("DashEnd" .. animSuffix) then
            if data.Punching then
                if data.Punching.Type == REVEL.ENT.ICE_HAZARD_GAPER.id then
                    sprite:Play(data.bal.JaugrBatAnims[math.random(1, 2)] .. animSuffix, true)
                else
                    sprite:Play("PunchFreeze" .. animSuffix, true)
                end
                sprite.FlipX = npc.Position.X > data.Punching.Position.X
                data.State = "Attack"
            else
                data.State = "Walk"
            end
        elseif not REVEL.MultiPlayingCheckSuffix(sprite, {"DashStart", "DashLoop", "DashEnd", "DashPunch"}, animSuffix) then
            data.State = "Walk"
        end
    elseif data.State == "Attack" then
        if REVEL.MultiPlayingCheckSuffix(sprite, data.bal.JaugrBatAnims, animSuffix) then
            npc.Velocity = Vector.Zero
            if sprite:IsEventTriggered("Punch") and data.Punching and data.Punching:Exists() then --and data.Punching.Position:DistanceSquared(npc.Position) < (80) ^ 2 then
                data.Punching.Velocity = (playerTarget.Position - data.Punching.Position):Resized(13)
                local prevClass = data.Punching.EntityCollisionClass
                local ent = data.Punching
                data.Punching.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                REVEL.DelayFunction(5, function()
                    ent.EntityCollisionClass = prevClass
                end)
                if REVEL.MultiPlayingCheck(sprite, "PunchBat2", "PunchBat2_Chillo") then --if kicking, make the kicked hazard go in the proper direction
                    if (data.Punching.Velocity.X > 0) == sprite.FlipX then --if going opposite direction than kick
                        data.Punching.Velocity = Vector(-data.Punching.Velocity.X, data.Punching.Velocity.Y)
                    end
                end

                REVEL.sfx:NpcPlay(npc, REVEL.SFX.ICE_BUMP, 0.9, 0, false, 1.2+(math.random()*0.2))
                data.Punching:GetData().JaugrStunned = nil
                data.Punching:GetData().LockedInPlaceTime = nil --in case immediately punched
                data.Punching = nil
            end
        elseif REVEL.MultiPlayingCheck(sprite, "PunchFreeze" .. animSuffix, "DashPunch" .. animSuffix) then
            npc.Velocity = Vector.Zero
            if data.Punching and data.Punching:Exists() then
                data.Punching.Velocity = data.Punching.Velocity * 0.5
            end

            if sprite:WasEventTriggered("Punch") and not data.Punched and data.Punching and data.Punching:Exists() and data.Punching:ToNPC() then --and data.Punching.Position:DistanceSquared(npc.Position) < (80) ^ 2 then
                if REVEL.MorphToIceHazard(data.Punching, 50, data.bal.JaugrSpikedHazards) then
                    data.LastFrozenEntitySeed = data.Punching.InitSeed
                    data.Punched = true
                    if REVEL.room:CheckLine(data.Punching.Position, playerTarget.Position, 0, 1000, false, false) then --immediately punch hazard at player
                        data.ImmediatelyPunchHazard = true
                    else
                        data.Punching:GetData().JaugrStunned = nil
                        data.Punching = nil
                    end
                end
            end
        elseif sprite:IsPlaying("Eat") then
            npc.Velocity = Vector.Zero
            if data.Eating then
                data.Eating.Velocity = Vector.Zero
            end

            if sprite:IsEventTriggered("Chomp") then
                eat(npc, data.Eating)
                data.Eating = nil
            end
        end

        if not REVEL.MultiPlayingCheckSuffix(sprite, {"PunchBat", "PunchBat2", "PunchFreeze", "DashPunch", "Eat"}, animSuffix) and not sprite:IsPlaying("Eat") then
            data.Punched = nil
            if data.ImmediatelyPunchHazard then
                if (npc.Position.X > playerTarget.Position.X) == (npc.Position.X > data.Punching.Position.X) then --if on opposite side of hazard to player, kick it
                    sprite:Play("PunchBat2" .. animSuffix, true)
                else
                    sprite:Play("PunchBat" .. animSuffix, true)
                end

                sprite.FlipX = npc.Position.X > data.Punching.Position.X
                data.ImmediatelyPunchHazard = nil
            else
                if data.Punching then
                    data.Punching:GetData().JaugrStunned = nil
                    data.Punching = nil
                end

                data.State = "Walk"
            end
        end
    end

    if npc:HasEntityFlags(EntityFlag.FLAG_ICE) then
        npc:ClearEntityFlags(EntityFlag.FLAG_ICE)
    end
end

local function jaugrStunnedPreNpcUpdate(_, npc)
    local data = npc:GetData()

    if data.JaugrStunned then
        if not data.JaugrStunned:Exists() then
            data.JaugrStunned = nil
            return
        end
        npc.Velocity = npc.Velocity * 0.5
        if npc.Type ~= REVEL.ENT.ICE_HAZARD_GAPER.id then
            npc:AddConfusion(EntityRef(data.JaugrStunned), 2, true)
        end

        return true
    end
end

--Initalize draugr as full if placed in same tile as grillos/chillos
local function draugrPreSelectEntityList(entityList, spawnIndex, entityMeta)
    local chilloIndex, grilloIndex, isSmallGrillo

    for i, entityInfo in ipairs(entityList) do
        if REVEL.ENT.CHILL_O_WISP:isEnt(entityInfo) then
            chilloIndex = i
        elseif REVEL.ENT.GRILL_O_WISP:isEnt(entityInfo) then
            grilloIndex = i
            isSmallGrillo = entityInfo.SubType == 1
        end
    end

    local changed = false
    if chilloIndex or grilloIndex then
        local remove = {}
        for _, entityInfo in ripairs(entityList) do
            if REVEL.ENT.DRAUGR:isEnt(entityInfo) or REVEL.ENT.JAUGR:isEnt(entityInfo) or REVEL.ENT.HAUGR:isEnt(entityInfo) or REVEL.ENT.JUNIAUGR:isEnt(entityInfo) then
                local bal = getBalanceByVariant(entityInfo.Variant)
                --set some flags to spawn the draugr initialized
                if bal.CanEatChillo and chilloIndex then
                    entityInfo.SubType = StartChilledSubtype
                    remove[#remove + 1] = chilloIndex
                elseif bal.CanEatGrillo and grilloIndex then
                    entityInfo.SubType = isSmallGrillo and StartGrilledSmallSubType or StartGrilledSubtype
                    remove[#remove + 1] = grilloIndex
                end
            end
        end

        changed = #remove > 0
        for _, toRemoveIndex in ipairs(remove) do table.remove(entityList, toRemoveIndex) end
    end

    if changed then
        return nil, entityList, true
    end
end

local function draugrPostNpcInit(_, npc)
    if not (REVEL.ENT.DRAUGR:isEnt(npc) or REVEL.ENT.HAUGR:isEnt(npc) or REVEL.ENT.JAUGR:isEnt(npc) or REVEL.ENT.JUNIAUGR:isEnt(npc)) then return end

    local sprite, data = npc:GetSprite(), npc:GetData()

    data.bal = getBalanceByVariant(npc)

    data.HeadSprite = Sprite()
    if REVEL.ENT.DRAUGR:isEnt(npc) then
        data.HeadSprite:Load("gfx/monsters/revel1/draugr/draugr.anm2", false)
        data.GlowSprite = Sprite()
        data.GlowSprite:Load("gfx/monsters/revel1/draugr/draugr_glow.anm2", false)
    elseif REVEL.ENT.HAUGR:isEnt(npc) then
        data.HeadSprite:Load("gfx/monsters/revel1/draugr/haugr.anm2", false)
        data.FireSprite = Sprite()
        data.FireSprite:Load("gfx/monsters/revel1/draugr/haugr.anm2", true)
        data.RenderFireSprite = false
        data.TopSprite = Sprite()
        data.TopSprite:Load("gfx/monsters/revel1/draugr/haugr.anm2", true)
        data.TopSpriteHead = Sprite() --I'd use overlays but they have different flip
        data.TopSpriteHead:Load("gfx/monsters/revel1/draugr/haugr.anm2", true)
        -- data.GlowSprite = Sprite()
        -- data.GlowSprite:Load("gfx/monsters/revel1/draugr/haugr_glow.anm2", true)
        -- data.GlowSprite.Color = Color(1, 1, 1, 0.25,conv255ToFloat( 0, 0, 0))
        -- data.NoReplaceGlowSpritesheet = true
    elseif REVEL.ENT.JAUGR:isEnt(npc) then
        data.HeadSprite:Load("gfx/monsters/revel1/draugr/jaugr.anm2", false)
        -- data.GlowSprite:Load("gfx/monsters/revel1/draugr/draugr_glow.anm2", false)
    elseif REVEL.ENT.JUNIAUGR:isEnt(npc) then
        data.HeadSprite:Load("gfx/monsters/revel1/draugr/juniaugr.anm2", false)
        --[[data.GlowSprite = Sprite()
        data.GlowSprite:Load("gfx/monsters/revel1/draugr/draugr_glow.anm2", false)]]
    end

    data.Variant = #data.bal.Variants > 0 and math.random(#data.bal.Variants) or 1

    if data.Variant ~= 1 then --not default
        for layer, spritesheet in pairs(data.bal.Variants[data.Variant]) do
            sprite:ReplaceSpritesheet(layer, spritesheet)
            data.HeadSprite:ReplaceSpritesheet(layer, spritesheet)
        end
    end

    data.HeadSprite:LoadGraphics()

    data.HeadSprite:Play("WalkHoriHead", true)

    data.AuraSourceSprite = {sprite, data.HeadSprite, data.GlowSprite}
    data.NoAuraRerender = not data.GlowSprite

    if npc.SubType == StartChilledSubtype then
        local useAura = not REVEL.ENT.JAUGR:isEnt(npc)
        data.Holding = {{Type = REVEL.ENT.CHILL_O_WISP.id, Variant = REVEL.ENT.CHILL_O_WISP.variant}}
        if npc.SubType == StartGrilledSmallSubType or REVEL.ENT.JUNIAUGR:isEnt(npc) then
            data.Holding[1].SubType = 1
        end
        if useAura then
            radius = REVEL.GetChillFreezeRadius() * data.bal.ChillRadiusMult
            if REVEL.ENT.JUNIAUGR:isEnt(npc) then
                radius = radius * 0.6
            end
            local auraData = REVEL.SetChillAura(npc, radius)
            data.Aura = auraData.Aura.Ref
        end
    elseif npc.SubType == StartGrilledSubtype or npc.SubType == StartGrilledSmallSubType then
        data.Holding = {{Type = REVEL.ENT.GRILL_O_WISP.id, Variant = REVEL.ENT.GRILL_O_WISP.variant}}
        local radius = REVEL.GetChillWarmRadius()
        if npc.SubType == StartGrilledSmallSubType or REVEL.ENT.JUNIAUGR:isEnt(npc) then
            radius = radius * 0.6
            data.Holding[1].SubType = 1
        end

        local auraData = REVEL.SetWarmAura(npc, radius)
        data.Aura = auraData.Aura.Ref
    end

    local headSkin = ((npc.SubType == StartGrilledSubtype or npc.SubType == StartGrilledSmallSubType) and data.bal.GrilloSkin) or
        (npc.SubType == StartChilledSubtype and data.bal.ChilloSkin)
    local glowSkin = ((npc.SubType == StartGrilledSubtype or npc.SubType == StartGrilledSmallSubType) and data.bal.GrilloGlow) or
    (npc.SubType == StartChilledSubtype and data.bal.ChilloGlow)
    loadSkin(npc, headSkin, glowSkin)
end

local function draugrPostNpcRender(_, npc, renderOffset)
    local sprite, data = npc:GetSprite(), npc:GetData()

    local doUpdate = REVEL.IsRenderPassNormal()

    if data.HeadSprite then
        if doUpdate then
            data.HeadSprite.Color = sprite.Color
        end

        if not data.DontRenderHeadSprite then
            data.HeadSprite:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end
    end
    if data.RenderFireSprite then
        if doUpdate then
            data.FireSprite.Scale = npc.SpriteScale
        end

        data.FireSprite:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end
    if data.GlowSprite and data.GlowSpriteOn then
        if doUpdate then
            local alpha = data.bal.GlowAlpha - data.bal.GlowAlphaFlickerAmp * (0.5 + math.sin(npc.FrameCount * data.bal.GlowAlphaFlickerFreq) / 2)
            data.GlowSprite.Color = REVEL.ChangeSingleColorVal(sprite.Color, nil,nil,nil, alpha)
        end
        
        if not data.DontRenderHeadSprite then
            data.GlowSprite:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end
    end
    if data.RenderFireSprite then
        if doUpdate then
            local bodyAnim = sprite:GetAnimation()
            local headAnim = data.HeadSprite:GetAnimation()
            data.TopSprite.Scale = npc.SpriteScale
            data.TopSprite:SetFrame(bodyAnim .. "_Ribs", sprite:GetFrame())
            data.TopSprite.FlipX = sprite.FlipX
            data.TopSpriteHead.Scale = npc.SpriteScale
            data.TopSpriteHead:SetFrame(headAnim .. "_Top", data.HeadSprite:GetFrame())
            data.TopSpriteHead.FlipX = data.HeadSprite.FlipX
        end
        data.TopSprite:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        data.TopSpriteHead:Render(Isaac.WorldToScreen(npc.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
    end

    if data.RenderOnTopParticles then
        for i, part in ripairs(data.RenderOnTopParticles) do
            if not data.Aura then
                part:Render(Isaac.WorldToScreen(part.Position) + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
            if part.FrameCount > 35 then
                table.remove(data.RenderOnTopParticles, i)
            end
        end
    end
end

local function SpawnBonyDustClouds(entity)
    local num = math.random(5, 10)
    for i = 1, num do
        local e = Isaac.Spawn(1000, EffectVariant.DUST_CLOUD, 0, entity.Position + RandomVector() * math.random(1, 20), Vector.Zero, entity):ToEffect()
        e.Timeout = math.random(15, 30)
        e.LifeSpan = e.Timeout
        e.Color = Color(0.5, 0.5, 0.5, 0.75)
    end
end

local function draugrPostEntityKill(_, entity)
    --[[REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
    REVEL.sfx:Play(SoundEffect.SOUND_DEATH_BURST_BONE)]]
    SpawnBonyDustClouds(entity)
end

local function draugrPostEntityRemove(_, entity)
    local data = entity:GetData()

    if REVEL.ENT.JAUGR:isEnt(entity) and isDraugrHolding(entity, REVEL.ENT.CHILL_O_WISP) then
        REVEL.ENT.CHILL_O_WISP:spawn(entity.Position, Vector.Zero, entity)
    elseif data.Holding and #data.Holding > 0 then
        for _, heldData in pairs(data.Holding) do
            local held = Isaac.Spawn(heldData.Type, heldData.Variant, heldData.SubType or 0, entity.Position, Vector.Zero, entity)
        end
    elseif data.Eating then
        data.Eating:GetData().BeingEaten = nil
        data.Eating:GetData().StayStill = nil
    end
end

local function draugrEntityTakeDmg(_, entity, dmg, flag, src, count)
    if (REVEL.ENT.DRAUGR:isEnt(entity) or REVEL.ENT.HAUGR:isEnt(entity) or REVEL.ENT.JUNIAUGR:isEnt(entity)) and src and src.Entity and src.Entity.Type == 33 then
        return false
    end
end


revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, draugrPathMapFireplaceEntityTakeDmg, 33)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, draugrHaugrNpcUpdate, REVEL.ENT.DRAUGR.id)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_STAGEAPI_NEW_ROOM_WRAPPER, 1, draugrPostNewRoom)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, draugrPostUpdate)

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, jaugrNpcUpdate, REVEL.ENT.JAUGR.id)
revel:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, jaugrStunnedPreNpcUpdate)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_SELECT_ENTITY_LIST, 0, draugrPreSelectEntityList)
revel:AddCallback(ModCallbacks.MC_POST_NPC_INIT, draugrPostNpcInit)
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, draugrPostNpcRender, REVEL.ENT.DRAUGR.id)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, draugrPostEntityKill, REVEL.ENT.DRAUGR.id)
revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, draugrPostEntityRemove, REVEL.ENT.DRAUGR.id)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, draugrEntityTakeDmg, REVEL.ENT.DRAUGR.id)

end