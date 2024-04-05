return function()

local EllipseOffset = {Vector(-15,0), Vector(0, -5), Vector(15, 0), Vector(0, 5)}

local MaxDark = 0.7
local MaxBeamAngle = 30
local SpotlightRadius = Vector(92, 34)
local MinRadius = Vector(40, 20)
local BeamHeight = 200

local DarkAroundRenderer = nil

local degToRad = math.pi/180
local function getEllipsePos(center, xr, yr, angle)
    -- REVEL.DebugToString(center, xr, yr, angle, Vector(math.cos(angle*degToRad) * xr, math.sin(angle*degToRad) * yr))
    return center + Vector(math.cos(angle*degToRad) * xr, math.sin(angle*degToRad) * yr)
end

local function GetDarknessAlphaMult(spot)
    local data = REVEL.GetData(spot)
    if data.IgnoreDarkness then
        return 1
    else
        return REVEL.Saturate(REVEL.GetRelativeDarkness() / (MaxDark - REVEL.BaseGameDarkness))
    end
end

function REVEL.SpawnSpotlight(color, pos, fadein, darkAround, invisibleSpot, ignoreDarkness)
    if ignoreDarkness == nil and darkAround then ignoreDarkness = true end

    local spot = StageAPI.SpawnFloorEffect(pos, Vector.Zero, nil, "gfx/effects/revelcommon/spotlight.anm2", true)
    local data, sprite = REVEL.GetData(spot), spot:GetSprite()

    data.IgnoreDarkness = ignoreDarkness
    data.Color = REVEL.CloneColor(color)
    local ca = REVEL.ChangeSingleColorVal(data.Color, nil,nil,nil, data.Color.A * GetDarknessAlphaMult(spot))
    spot.Color = ca

    if invisibleSpot then
        sprite:ReplaceSpritesheet(0, "gfx/ui/none.png")
        sprite:LoadGraphics()
    end

    if darkAround then
        data.DarkAroundSprite = Sprite()
        data.DarkAroundSprite:Load(sprite:GetFilename(), true)
        data.DarkAroundSprite:Play("Beam Focus", true)
        data.DarkAroundSprite:Update()

        if not (DarkAroundRenderer and DarkAroundRenderer.Ref) then
            local renderer = REVEL.ENT.DECORATION:spawn(REVEL.room:GetBottomRightPos() + Vector(200, 200), Vector.Zero)
            REVEL.GetData(renderer).DarkAroundSpotlightRenderer = true
            renderer:GetSprite():Load("gfx/blank.anm2", true)   
            DarkAroundRenderer = EntityPtr(renderer)
        end
    end

    -- data.Lights = {}
    -- if revel.data.cLightSetting == 2 then
    --     for i = 1, 4 do
    --         data.Lights[i] = REVEL.SpawnLight(pos + EllipseOffset[i], color, 0.8, true)
    --     end
    -- else
    --     data.Lights[1] = REVEL.SpawnLight(pos, color, 1.3, true)
    -- end
    -- for i,v in ipairs(data.Lights) do
    --     v.Color = Color.Lerp(REVEL.NO_COLOR, color, REVEL.Saturate(2*REVEL.GetRelativeDarkness() / (MaxDark - REVEL.BaseGameDarkness)))
    -- end

    local beam = REVEL.ENT.SPOTLIGHT_BEAM:spawn(pos, Vector.Zero, spot)
    beam.Color = ca
    beam:GetSprite():Load("gfx/effects/revelcommon/spotlight.anm2", true)
    if fadein then
        spot:GetSprite():Play("Spot Fadein", true)
        beam:GetSprite():Play("Beam Fadein", true)
    else
        spot:GetSprite():Play("Spot", true)
        beam:GetSprite():Play("Beam", true)
    end

    local c = REVEL.room:GetCenterPos()
    local halfw = REVEL.room:GetBottomRightPos().X - c.X
    local cdist = REVEL.dist(c.X, spot.Position.X)
    if spot.Position.X < c.X then
        beam:GetSprite().Rotation = REVEL.Lerp2Clamp(0, MaxBeamAngle, cdist, 0, halfw)
    else
        beam:GetSprite().Rotation = -REVEL.Lerp2Clamp(0, MaxBeamAngle, cdist, 0, halfw)
    end

    data.SpotlightRadius = SpotlightRadius

    data.Beam = EntityPtr(beam)
    REVEL.GetData(beam).Spot = EntityPtr(spot)

    return spot
end

function REVEL.SpawnMovingSpotlight(color, xr, yr, startAngle, speed, fadein, center, darkAround, invisibleSpot, ignoreDarkness)
    xr = xr or 0
    yr = yr or 0
    startAngle = startAngle or 0
    speed = speed or 5
    center = center or REVEL.room:GetCenterPos()

    local spot = REVEL.SpawnSpotlight(color, getEllipsePos(center, xr, yr, startAngle), fadein, darkAround, invisibleSpot, ignoreDarkness)
    local data = REVEL.GetData(spot)

    data.MoveRadius = Vector(xr, yr)
    data.RadSpeed = speed
    data.Angle = startAngle
    data.Center = center

    return spot
end

function REVEL.SpawnMultiSpotlights(color, xr, yr, amount, startAngle, speed, fadein, center, sizeMult, ignoreDarkness)
    for i = 1, amount do
        local spot = REVEL.SpawnMovingSpotlight(color, xr, yr, startAngle + 360*i/amount, speed, fadein, center, nil, nil, ignoreDarkness)
        if sizeMult then
            REVEL.SetSpotlightSizeMult(spot, sizeMult)
        end
    end
end

-- Effect: "Slow", "Burn" or "BurnWeak"
function REVEL.SpawnEntSpotlight(color, ent, effect, fadein, darkAround, invisibleSpot, noOverrideLast)
    local spot = REVEL.SpawnSpotlight(color, ent.Position, fadein, darkAround, invisibleSpot)

    if effect then
        REVEL.GetData(spot)[effect] = true
    end

    local data = REVEL.GetData(spot)

    data.Entity = ent
    if not noOverrideLast and REVEL.GetData(ent).LastSpotlight then
        REVEL.GetData(REVEL.GetData(ent).LastSpotlight).StopBeam = true
    end
    REVEL.GetData(ent).LastSpotlight = spot

    return spot
end

function REVEL.FadeoutSpotlight(spot)
    REVEL.GetData(spot).StopBeam = true
end

function REVEL.SetSpotlightSizeMult(spot, sizeMult)
    local data = REVEL.GetData(spot)
    data.SpotlightRadius = SpotlightRadius * sizeMult
    spot.SpriteScale = Vector.One * sizeMult
    -- REVEL.ScaleEntity(spot, {SpriteScale = sizeMult})
end

function REVEL.SetSpotlightColor(spot, color)
    local data, spr = REVEL.GetData(spot), spot:GetSprite()

    local beam = data.Beam.Ref

    data.Color = color

    spr.Color = REVEL.ChangeColorAlpha(data.Color, GetDarknessAlphaMult(spot))
    beam.Color = spr.Color
end

function REVEL.SetSpotlightAlpha(spot, alpha)
    local data = REVEL.GetData(spot)
    
    REVEL.SetSpotlightColor(spot, REVEL.ChangeColorAlpha(data.Color, alpha, true))
end

local function customBurnDamage(e, src, dmg, color, colPct)
    e:TakeDamage(dmg, DamageFlag.DAMAGE_FIRE, EntityRef(player), 10)
    e:SetColor(Color.Lerp(color, Color.Default, 1-colPct), 4, 1, true, true)
end

local function UpdateSpotlight(spot, beam)
    local data, spr = REVEL.GetData(spot), spot:GetSprite()
    local c = REVEL.room:GetCenterPos()
    local halfw = c.X - REVEL.room:GetTopLeftPos().X
    local darkness = REVEL.Saturate(REVEL.GetRelativeDarkness() / (MaxDark - REVEL.BaseGameDarkness))

    if not IsAnimOn(spr, "Spot Fadeout") then
        spr.Color = REVEL.ChangeColorAlpha(data.Color, GetDarknessAlphaMult(spot))

        if data.MoveRadius then
            data.Angle = data.Angle + data.RadSpeed
            spot.Position = getEllipsePos(data.Center, data.MoveRadius.X, data.MoveRadius.Y, data.Angle)
        elseif data.Entity then
            if data.Entity:Exists() then
                spot.Position = data.ForcePosition or data.Entity.Position
                spot.Velocity = data.ForceVelocity or data.Entity.Velocity
            else
                spot.Velocity = Vector.Zero
            end

            if data.StopBeam 
            or ((data.Entity:IsDead() or not data.Entity:Exists()) and not data.ForceWhenEntDead)
            or (not data.Entity.Visible and not data.ForceWhenEntInvisible) then
                -- REVEL.DebugStringMinor("Stopping spotlight", spot.Index, data.Entity.Type .. "." .. data.Entity.Variant,
                --     data.StopBeam, "-",
                --     data.Entity:IsDead() or not data.Entity:Exists(), data.ForceWhenEntDead,
                --     not data.Entity.Visible, data.ForceWhenEntInvisible
                -- )

                spr:Play("Spot Fadeout", true)
                beam:GetSprite():Play("Beam Fadeout", true)
                local edata = REVEL.GetData(data.Entity)
                if edata.LastSpotlight and edata.LastSpotlight.InitSeed == spot.InitSeed then
                    edata.LastSpotlight = nil
                end
            end
            if darkness > 0.2 * MaxDark then
                if data.Slow then
                    data.Entity:MultiplyFriction(0.87)
                elseif data.BurnWeak and spot.FrameCount % 15 == 0 then
                    customBurnDamage(data.Entity, spot, 1.5, spot.Color, 0.3)
                elseif data.Burn and spot.FrameCount % 3 == 0 then
                    local closeEnms = Isaac.FindInRadius(spot.Position, data.SpotlightRadius.X + 80, EntityPartition.ENEMY)
                    for j,enm in ipairs(closeEnms) do
                        if REVEL.dist(enm.Position.X, spot.Position.X) < enm.Size + data.SpotlightRadius.X 
                        and REVEL.dist(enm.Position.Y, spot.Position.Y) < enm.Size + data.SpotlightRadius.Y then
                            if math.random() > 0.9 then
                                customBurnDamage(enm, spot, 4, spot.Color, 0.5)
                            end
                        end
                    end
                end
            end
        end

        -- if data.Lights[1] then
        --     if revel.data.cLightSetting == 2 then
        --         for j, light in ipairs(data.Lights) do
        --             light.Position = spot.Position + EllipseOffset[j]
        --         end
        --     else
        --         data.Lights[1].Position = spot.Position
        --     end
        --     for j, light in ipairs(data.Lights) do
        --         light.Velocity = spot.Velocity
        --         if not REVEL.room:IsPositionInRoom(light.Position, 0) then
        --             light.Color = REVEL.NO_COLOR
        --         else
        --             light.Color = Color.Lerp(REVEL.NO_COLOR, spr.Color, REVEL.Saturate(2*REVEL.GetRelativeDarkness() / (MaxDark - REVEL.BaseGameDarkness)))
        --         end
        --     end
        -- end

        local cdist = REVEL.dist(c.X, spot.Position.X)
        if spot.Position.X < c.X then
            beam:GetSprite().Rotation = REVEL.Lerp2Clamp(0, MaxBeamAngle, cdist, 0, halfw)
        else
            beam:GetSprite().Rotation = -REVEL.Lerp2Clamp(0, MaxBeamAngle, cdist, 0, halfw)
        end
        beam.Position = spot.Position --Vector(spot.Position.X, math.min(c.Y, spot.Position.Y))
        beam.Color = spr.Color
        beam.SpriteScale = spot.SpriteScale

        if not IsAnimOn(spr, "Spot Fadeout") and data.StopBeam then
            spr:Play("Spot Fadeout", true)
            beam:GetSprite():Play("Beam Fadeout", true)
        end

    -- elseif spr:IsPlaying("Spot Fadeout") then
        -- for j, light in ipairs(data.Lights) do
        --     light.Color = Color.Lerp(light.Color, REVEL.NO_COLOR, 0.6)
        -- end
    elseif spr:IsFinished("Spot Fadeout") then
        -- for j, light in ipairs(data.Lights) do
        --     light:Remove()
        -- end
        beam:Remove()
        spot:Remove()
    end
end

local function spotlightBeamPostUpdate(_, beam)
    local data = REVEL.GetData(beam)

    local spot = data.Spot and data.Spot.Ref

    if spot and spot:Exists() then
        UpdateSpotlight(spot, beam)
    else
        beam:Remove()
    end
end

local function spotlightsPostRender()
    local beams = REVEL.ENT.SPOTLIGHT_BEAM:getInRoom()

    for _, beam in ipairs(beams) do
        local bdata, bsprite = REVEL.GetData(beam), beam:GetSprite()
        local spot = bdata.Spot and bdata.Spot.Ref
        if spot and spot:Exists() then
            local data = REVEL.GetData(spot)
            if data.DarkAroundSprite then
                data.DarkAroundSprite.Color = REVEL.ChangeColorAlpha(Color.Default, beam.Color.A, true)
                data.DarkAroundSprite.Scale = beam.SpriteScale * (data.DarkAroundScale or 1)
                data.DarkAroundSprite.Rotation = bsprite.Rotation
                data.DarkAroundSprite:Render(Isaac.WorldToScreen(beam.Position))
            end
        end
    end
end

local function darkAroundRendererPostRender(_, effect)
    if REVEL.GetData(effect).DarkAroundSpotlightRenderer then
        spotlightsPostRender()
    end
end

-- update on spotlight beam for optimization, as spot is generic floor entity in stageapi
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, spotlightBeamPostUpdate, REVEL.ENT.SPOTLIGHT_BEAM.variant)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, darkAroundRendererPostRender, REVEL.ENT.DECORATION.variant)

function REVEL.SpotTest(x, y, s, c)
    local r, g, b = hsvToRgb(0.6, 0.7, 0.9)
    c = c or 2
    local pos = Vector(65, 40)
    if x then pos = Vector(x,y) end
    for i = 1, c do
        REVEL.SpawnMovingSpotlight(Color(0,0,0,0.9, r, g, b), pos.X, pos.Y, 360*i/c, s or 5)
    end
    r, g, b = hsvToRgb(0.2, 1, 1)
    -- REVEL.SpawnEntSpotlight(Color(0,0,0,1, r, g, b), REVEL.player)
end

end