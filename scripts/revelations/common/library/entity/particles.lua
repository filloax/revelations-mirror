local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()


---------------------
-- PARTICLE SYSTEM --
---------------------

--[[
    Particle system, to create particle effects. Main classes are Particle (which defines the properties of a single particle type, its sprite/life/weight/etc),
    Emitter (with various subclasses depending on the emission shape/method, and also defining the initial speed/direction) and
    PartSystem, which defines the overall gravity and physics of a certain effect.
    All 3 are in the global REVP table.
    All three objects are not connected to a particular ingame entity: they only define different properties of a certain effect; the single instances of the effects
    (for example, particles coming out of burning bush) are done through calling a function on the emitter at a certain position. So, in the burning bush spraks example,
    you wouldn't need to dynamycally create emitters for every player, but just call your desired particle emit function at each player's position.

    ParticleType class:
        REVEL.ParticleType

    Constructor: REVEL.ParticleType(string name, string anm2, number life, number variants, number fadeOutStart, 
            number fadeInEnd, bool dieOnLand, number removeOnDeath, Color baseColor, number weight, number frictionMult)
        example: local myPart = REVP.Particle("gfx/effects/myparticle.anm2", 15, 1, 3)
    Alternate constructor: REVEL.ParticleType.FromTable(tbl) or REVEL.ParticleType.FromTable{...}, where tbl or {...} is a table that contains the fields to set in the new object. Blank fields will be default.

    Fields:
        Name: used for debug
        Anm2: the path to the anm2 file that will be loaded for each particle. Ideally the particles should be centered on the origin, and be small (they're particles).
        BaseLife: how many frames the particles lasts. Can be further adjusted with fadeins/fadeouts and randomization using functions defined below.
        Variants: how many variants of the particle animations there are. They should be named "Particle1","Particle2", etc, or be different frames of the animation specified in AnimationName if it is set.
        FadeOutStart: 0 to 1, at which part of a particle lifetime it starts fading out, use 0 for no fadeout
        FadeInEnd: 0 to 1, at which part of a particle lifetime it finishes fading in, 1 for no fadein
        DieOnLand: if the particle should get removed after landing
        RemoveOnDeath: 1 is default, particle entity is removed on death. 0 for it to exist, and 2 for it to become a floor entity.
        BaseColor: default color of the particle, default is (1,1,1,1,0,0,0)
        Weight: multiplier for how much gravity affects this particle. 1 is default.
        FrictionMult: multiplier for the friction (both air and ground), meaning higher than 1 is higher friction and 1- is lower

        not in constructor
        BaseOffset: always add this to SpriteOffset
        Bounce: if it should bounce off the floor, 0 for no bounce, 0-1 for the strength of the bounce relative to the touching floor speed
        OrientToMotion: if true, rotation won't be increased with time but instead the particle will be rotated such that the side that points right at rotation = RestingRotation points towards the movement direction
        AbsoluteSpeed: Rotation speed won't depend on z velocity
        StartScale
        EndScale
        ScaleRandom
        RemoveOutOfRoom: will be removed only when out of the room, life doesn't count down when inside, 
            value is minimum offset (default false -> inactive)
        RestingRotation: rotation (degrees) at which the particle stops when still
        LifeRandom: How much life can change relative to baselife (ie with this at 0.1, a particle can 
            start with a life from baselife - 10% to baselife + 10%)
        ColorRandom: How much color can change relative to basecolor (as with liferandom, also this 
            changes r g and b separately)
        HueRandom: randomly changes color hue by this amount, applies before ColorRandom
        AnimationName: if set, the variants will be picked from the frames of an animation (with the 
            name set) instead of playing a random animation between Particle1 and Particle<Variants>, 
            to allow using vanilla particle files
        WindInfluence: multiplier for how strongly the wind affects the particle
        GetWindInfluenceOverTime = function(self, life, lifeMax, particleEntity, partData)
        Spritesheet: if "default", doesn't replace the anm2 spritesheet. Else replaces layer 0 to the 
            path in this field.
        AnimNum: if set, random frames from a random anim will be picked, with Variants as the 
            (identical for each anim) frame amount and AnimNum as the number of animations
        AnimPrefix: defaults to "Particle", used if AnimationName is not set and so multiple animations are used
        RenderNormallyWithEntity: if particle gets rendered by an entity for priority reasons, setting
            this to true will render the particle also normally, lagging more but enabling the use of glow
            layers that require normal entity rendering to work

        Make sure to add new fields to the ---@class ParticleTypeArgs below

    Methods:
        :Spawn(PartSystem system, Vec3 pos, Vec3 vel, [Entity renderer])
        :SetLife(baseLife, random)
        :SetColor(baseColor, random, hueRandom)
        :SetScaleOverLife(func) sets the function that gets the particles' scale over its life 
          (function should take (self, life, lifeMax) as arguments, and return the scale multiplier)
        :SetAlphaOverLife(func) sets the function that gets the particles' opacity over its life 
          (function should take (self, life, lifeMax) as arguments, and return the opacity)
        :SetAnm2(sprite, variants, animName)
        :SetSpritesheet(spritesheet)

    PartSystem class:
        REVEL.PartSystem

        Constructor: REVEL.PartSystem(string name, number gravity, number airFriction, Vec3 wind, 
            number groundFriction, bool clamped, bool autoUpdate)
        Alternate constructor: REVEL.PartSystem.FromTable(tbl) or REVEL.PartSystem.FromTable{...}, where tbl or {...} is a table 
        that contains the fields to set in the new object. Blank fields will be default.

    Fields:
        Name
        Gravity
        AirFriction
        Wind
        GroundFriction
        Clamped: default false
        AutoUpdate: default true

        not in constructor
        Turbulence = default false, if random turbulence is enabled for the field
        TurbulenceReangleMinTime = default 20
        TurbulenceReangleMaxTime = default 45
        TurbulenceMaxAngleXYZ = default (30,30,30)
        vec2 TopLeftClamp: corner of possible positions, leave -1 to use room
        vec2 BotRightClamp: corner of possible positions, leave -1 to use room
        vec2 RoomClampOffset: if using room clamp, added to top left and subtracted from bottom right

    Emitter classes:
        REVEL.Emitter

        Constructor: REVEL.Emitter()
        Base point emitter.

        Methods:

    REVEL.Emitter:EmitParticlesPerSec(ParticleType type, PartSystem system, Vec3 pos, 
        Vec3 vel, number partPerSecond, number velRand, number velSpread)

        velRand is the relative amount of how much the velocity's length can vary i.e. 0 makes it always the same length, 
        1 can make it from 0 length to double length (+/- 100%)
        velSpread is, in degrees, how much the velocity's angle can vary aka the angle between the 2 furthest possible velocities.
        partPerSecond is how many particles are spawned every second, counted separately for each emitter object

    REVEL.Emitter:EmitParticlesNum(ParticleType type, PartSystem system, Vec3 pos, 
        Vec3 vel, number amount, number velRand, number velSpread)

        velRand is the relative amount of how much the velocity's length can vary i.e. 0 makes it always the same 
        length, 1 can make it from 0 length to double length (+/- 100%)
        velSpread is, in degrees, how much the velocity's angle can vary aka the angle between 
        the 2 furthest possible velocities.
        Yes, 360 degrees / 2pi rad results in a laggier sphere of possible directions.
        amount is how many particles are spawned

]]

local FramesPerSecond = 30
--how many particles are fired with reduced particles on
--only applies to ParticlesPerSec, as ParticlesNum is supposed to be used on burst firing
local ReducedParticlesFreqMult = 0.3
local Vec3 = _G.Vec3

local roomHasFloorParticleRenderer = false
local particlesToRenderOnFloor = {}

local RoomTL = Vector.Zero
local RoomBR = Vector.One
local RoomC = Vector.Zero

--PARTICLE TYPES
do
    ---@type fun(name, anm2, life?, variants?, fadeOutStart?, fadeInEnd?, dieOnLand?, removeOnDeath?, baseColor?, weight?, frictionMult?, restingRotation?): ParticleType
    REVEL.ParticleType = nil

    ---@class ParticleType
    REVEL.ParticleType = StageAPI.Class("RevParticle")

    function REVEL.ParticleType:Init(name, anm2, life, variants, fadeOutStart, fadeInEnd, dieOnLand, removeOnDeath, baseColor, weight, frictionMult, restingRotation)
        self.Name = name
        self.Anm2 = anm2
        self.Spritesheet = "default"
        self.BaseLife = life or 60
        self.Variants = variants or 1
        self.FadeOutStart = fadeOutStart or 0
        self.FadeInEnd = fadeInEnd or 1
        if dieOnLand == nil then dieOnLand = false end
        self.DieOnLand = dieOnLand
        self.RemoveOnDeath = removeOnDeath or 1
        self.BaseColor = baseColor or Color.Default
        self.Weight = weight or 1
        self.FrictionMult = frictionMult or 1

        self.BaseOffset = Vector.Zero
        self.AbsoluteSpeed = false
        self.OrientToMotion = false
        self.RemoveOutOfRoom = false
        self.StartScale = 1
        self.EndScale = 1
        self.ScaleRandom = 0
        self.GetScaleOverLife = function(self, life, lifeMax)
            return REVEL.Lerp2Clamp(self.StartScale, self.EndScale, life, lifeMax, 0)
        end
        self.GetAlphaOverLife = function(self, life, lifeMax)
            local alpha = 1
            if self.FadeInEnd < 1 then
                alpha = REVEL.Lerp2Clamp(alpha, 0, life, lifeMax * self.FadeInEnd, lifeMax)
            end
            if self.FadeOutStart > 0 then
                alpha = REVEL.Lerp2Clamp(alpha, 0, life, lifeMax * self.FadeOutStart, 0)
            end
            return alpha
        end
        self.WindInfluence = 1
        self.GetWindInfluenceOverTime = function(self, life, lifeMax, particleEntity, partData)
            return 1
        end
        self.RestingRotation = 0
        self.LifeRandom = 0
        self.ColorRandom = 0
        self.HueRandom = 0
        self.RotationSpeedMult = 1
        self.Bounce = 0
        self.AnimationName = ""
        self.AnimPrefix = "Particle"
        self.AnimNum = -1
        self.RenderNormallyWithEntity = false
    end

    ---@class ParticleTypeArgs
    ---@field Name string
    ---@field Anm2 string
    ---@field BaseLife integer?
    ---@field Variants integer?
    ---@field FadeOutStart number?
    ---@field FadeInEnd number?
    ---@field DieOnLand boolean?
    ---@field RemoveOnDeath boolean?
    ---@field BaseColor Color?
    ---@field Weight number?
    ---@field FrictionMult number?
    ---@field BaseOffset Vector?
    ---@field Bounce number?
    ---@field OrientToMotion boolean?
    ---@field AbsoluteSpeed boolean?
    ---@field StartScale number?
    ---@field EndScale number?
    ---@field ScaleRandom number?
    ---@field RemoveOutOfRoom boolean | number | nil
    ---@field RestingRotation number?
    ---@field LifeRandom number?
    ---@field ColorRandom number?
    ---@field HueRandom number?
    ---@field AnimationName string?
    ---@field WindInfluence number?
    ---@field GetWindInfluenceOverTime (fun(self, life: integer, lifeMax: integer, particleEntity: Entity, partData: table): number)?
    ---@field Spritesheet string?
    ---@field AnimNum integer?
    ---@field AnimPrefix string?
    ---@field RenderNormallyWithEntity boolean?

    ---@param tbl ParticleTypeArgs
    ---@return ParticleType
    function REVEL.ParticleType.FromTable(tbl)
        local out = REVEL.ParticleType(tbl.Name, tbl.Anm2)

        for k,_ in pairs(out) do
            if tbl[k] ~= nil then
                out[k] = tbl[k]
            end
        end

        return out
    end

    ---@param system ParticleSystem
    ---@param pos Vec3
    ---@param vel Vec3
    ---@param parent? Entity
    ---@param entityRenderer? Entity
    ---@return Entity|unknown
    function REVEL.ParticleType:Spawn(system, pos, vel, parent, entityRenderer)
        REVEL.Assert(system, "Tried spawning particle without system", 2)

        local part = Isaac.Spawn(REVEL.ENT.PARTICLE.id, REVEL.ENT.PARTICLE.variant, 0, pos.XY, Vector.Zero, nil)
        local spr, data = part:GetSprite(), REVEL.GetData(part)

        local life = self:GetRandomLife()
        data.PartData = {
            Type = self,
            Life = life,
            StartLife = life,
            Variant = self:GetRandomVariant(),
            AnimVariant = self:GetAnimVariant(),
            Position = pos,
            Velocity = vel,
            Scale = self:GetRandomScale(),
            Color = self:GetRandomColor(),
            ChangeColor = false,
            RotationSpeedMult = self.RotationSpeedMult,
            Rotation = 0,
            WindInfluence = self.WindInfluence,
            Parent = parent,
            System = system,
        }

        if parent and parent:Exists() then
            data.PartData.Position = Vec3(parent.Position, 0) - pos
        else
            data.PartData.Parent = nil
        end

        if self.OrientToMotion then
            data.PartData.Rotation = system:GetRotation(data.PartData)
        end

        if system.Turbulence then
            data.PartData.Wind = system.Wind:Clone()
            for i=1, 3 do
                if system.TurbulenceMaxAngleXYZ[i] ~= 0 then
                    data.PartData.Wind:RotateDegrees(i, (math.random() * 2 - 1) * system.TurbulenceMaxAngleXYZ[i])
                end
            end
            data.PartData.TurbulenceReangleTime = system.TurbulenceReangleMinTime + math.random(system.TurbulenceReangleMaxTime - system.TurbulenceReangleMinTime)
        end

        system:CollidePart(data.PartData)

        part.Position = data.PartData.Position.XY
        part.SpriteOffset = system:GetPartPerspectiveOffset(pos) + self.BaseOffset
        part.SpriteScale = Vector.One * data.PartData.Scale

        if self.Spritesheet ~= "default" then
            spr:Load(self.Anm2, false)
            spr:ReplaceSpritesheet(0, self.Spritesheet)
            spr:LoadGraphics()
        else
            spr:Load(self.Anm2, true)
        end

        if self.AnimationName == "" then
            if self.AnimNum > 0 then
                spr:SetFrame(self.AnimPrefix .. data.PartData.AnimVariant, data.PartData.Variant)
            else
                spr:Play(self.AnimPrefix .. data.PartData.Variant, true)
            end
        else
            spr:SetFrame(self.AnimationName, data.PartData.Variant)
        end
        spr.Rotation = self.RestingRotation
        spr.Color = data.PartData.Color

        if entityRenderer then
            part.Visible = self.RenderNormallyWithEntity
            data.PartData.RenderedByEnt = EntityPtr(entityRenderer)
            if not REVEL.GetData(entityRenderer).ParticlesToRender then
                REVEL.GetData(entityRenderer).ParticlesToRender = {}
            end
            REVEL.GetData(entityRenderer).ParticlesToRender[GetPtrHash(part)] = EntityPtr(part)
        end
    
        -- system.Particles[#system.Particles+1] = part
        return part
    end

    function REVEL.ParticleType:SetAnm2(anm2, variants, animName)
        self.Anm2 = anm2
        self.Variants = variants
        self.AnimationName = animName
    end

    function REVEL.ParticleType:SetSpritesheet(sheet)
        self.Spritesheet = sheet
    end

    function REVEL.ParticleType:SetLife(baseLife, random)
        self.BaseLife = baseLife or self.BaseLife
        self.LifeRandom = random or self.LifeRandom
    end

    function REVEL.ParticleType:SetColor(baseColor, random, hueRandom)
        self.BaseColor = baseColor or self.BaseColor
        self.ColorRandom = random or self.ColorRandom
        self.HueRandom = hueRandom or self.HueRandom
    end

    function REVEL.ParticleType:SetScaleOverLife(func)
        self.GetScaleOverLife = func
    end

    function REVEL.ParticleType:SetAlphaOverLife(func)
        self.GetAlphaOverLife = func
    end

    function REVEL.ParticleType:GetRandomLife()
        return self.BaseLife * math.max(0, (1 + (math.random() * self.LifeRandom * 2) - self.LifeRandom) )
    end

    function REVEL.ParticleType:GetRandomVariant()
        return math.random(1, self.Variants)
    end

    function REVEL.ParticleType:GetAnimVariant()
        if self.AnimNum > 0 then
            return math.random(1, self.AnimNum)
        end
    end

    function REVEL.ParticleType:GetRandomScale()
        return math.max(0, (1 + (math.random() * self.ScaleRandom * 2) - self.ScaleRandom) )
    end

    function REVEL.ParticleType:GetRandomColor()
        local color = REVEL.CloneColor(self.BaseColor)

        if self.HueRandom > 0 then
            local h, s, v = rgbToHsv(color.R, color.G, color.B)
            h = (math.random() * 2 - 1) * self.HueRandom
            local r, g, b = hsvToRgb(h % 1, s, v)
            color.R = r
            color.G = g
            color.B = b
        end

        if self.ColorRandom > 0 then
            color.R = color.R * math.max(0, (1 + (math.random() * self.ColorRandom * 2) - self.ColorRandom) )
            color.G = color.G * math.max(0, (1 + (math.random() * self.ColorRandom * 2) - self.ColorRandom) )
            color.B = color.B * math.max(0, (1 + (math.random() * self.ColorRandom * 2) - self.ColorRandom) )
        end

        return color
    end

end

local function spawnFloorParticleRenderer()
    local eff = StageAPI.SpawnFloorEffect(REVEL.room:GetTopLeftPos())
    REVEL.GetData(eff).FloorParticleRenderer = true
    roomHasFloorParticleRenderer = true
end

--SYSTEMS
do
    ---@type fun(name, gravity?, airFriction?, wind?, wallFriction?, groundFriction?, groundHeight?, clamped?, autoUpdate?): ParticleSystem
    REVEL.PartSystem = nil

    ---@class ParticleSystem
    REVEL.PartSystem = StageAPI.Class("PartSystem")
    REVEL.PartSystems = {}
    REVEL.PartSystemsByName = {}
    REVEL.PartSystemsAutoUpdate = {}

    function REVEL.PartSystem:Init(name, gravity, airFriction, wind, wallFriction, groundFriction, groundHeight, clamped, autoUpdate)
        self.Name = name
        self.Gravity = gravity or 3
        self.GravityVector = Vec3(0,0, self.Gravity)
        self.AirFriction = airFriction or 1
        self.Wind = wind or REVEL.VEC3_ZERO
        self.GroundFriction = groundFriction or 0
        self.WallFriction = wallFriction or 0.2
        self.GroundHeight = groundHeight or 0
        if clamped == nil then clamped = false end
        self.Clamped = clamped
        if autoUpdate == nil then autoUpdate = true end
        self.AutoUpdate = autoUpdate

        self.TopLeftClamp = -1
        self.BotRightClamp = -1
        self.RoomClampOffset = Vector.Zero --subtracted from bottom right, added to top left

        self.PerspectiveTweak = false --see the perspective function
        self.Turbulence = false
        self.TurbulenceMaxAngleXYZ = REVEL.VEC3_ONE
        self.TurbulenceReangleMinTime = 0
        self.TurbulenceReangleMaxTime = 0
    

        self.Particles = {} --array

        table.insert(REVEL.PartSystems, self)
        REVEL.PartSystemsByName[name] = self

        if autoUpdate then
            table.insert(REVEL.PartSystemsAutoUpdate, self)
        end
    end

    function REVEL.PartSystem:UpdateAutoUpdate()
        local isIn = REVEL.some(REVEL.PartSystemsAutoUpdate, function(that) return self.Name == that.Name end)
        if self.AutoUpdate and not isIn then
            table.insert(REVEL.PartSystemsAutoUpdate, self)
        elseif (not self.AutoUpdate) and isIn then
            REVEL.PartSystemsAutoUpdate = REVEL.filter(REVEL.PartSystemsAutoUpdate, function(that) return self.Name ~= that.Name end)
        end
    end

    ---@class PartSystemArgs
    ---@field Name string
    ---@field Gravity number?
    ---@field AirFriction number?
    ---@field Wind Vec3?
    ---@field GroundFriction number?
    ---@field Clamped boolean?
    ---@field AutoUpdate boolean?
    ---@field Turbulence boolean?
    ---@field TurbulenceReangleMinTime integer?
    ---@field TurbulenceReangleMaxTime integer?
    ---@field TurbulenceMaxAngleXYZ Vec3?
    ---@field TopLeftClamp Vector?
    ---@field BotRightClamp Vector?
    ---@field RoomClampOffset Vector?

    ---@param tbl PartSystemArgs
    ---@return ParticleSystem
    function REVEL.PartSystem.FromTable(tbl)
        local out = REVEL.PartSystem(tbl.Name)

        for k,_ in pairs(out) do
            if tbl[k] ~= nil then
                out[k] = tbl[k]
            end
        end
        out.GravityVector = Vec3(0,0, out.Gravity)
        out:UpdateAutoUpdate()

        return out
    end

    -- Unused
    --[[
    function REVEL.PartSystem:Update()
        if #self.Particles ~= 0 then
            for i = #self.Particles, 1, -1 do --faster than ipairs when it needs to be done a lot of times per frame
                local part = self.Particles[i]
                if not part:Exists() then
                    table.remove(self.Particles, i)
                else
                    local alive = self:UpdateParticle(part, i)
                    if not alive then
                        local renderer = REVEL.GetData(part).PartData.RenderedByEnt and REVEL.GetData(part).PartData.RenderedByEnt.Ref
                        if renderer then
                            REVEL.GetData(renderer).ParticlesToRender[GetPtrHash(part)] = nil
                        end
                        particlesToRenderOnFloor[GetPtrHash(part)] = nil

                        local shouldRemove = REVEL.GetData(part).PartData.Type.RemoveOnDeath
                        if shouldRemove == 1 then
                            part:Remove()
                        elseif shouldRemove == 2 then
                            part.Visible = true
                            part:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
                        end
                        table.remove(self.Particles, i)
                    end
                end
            end
        end
    end

    -- Unused
    function REVEL.PartSystem:RunInterpolation()
        if not REVEL.game:IsPaused() then
            if #self.Particles ~= 0 then
                for i = #self.Particles, 1, -1 do
                    self:InterpolateParticle(self.Particles[i])
                end
            end
        end
    end
    ]]

    function REVEL.PartSystem:UpdatePartColor(part, color)
        local pdata = REVEL.GetData(part).PartData
        pdata.Color = color
        pdata.ChangeColor = true
    end

    function REVEL.PartSystem:GetRotation(pdata)
        if pdata.Type.OrientToMotion then
            local dir2d = self:Get2dPos(pdata.Position + pdata.Velocity) - self:Get2dPos(pdata.Position)

            return dir2d:GetAngleDegrees()
        elseif pdata.Type.AbsoluteSpeed then
            return (pdata.Rotation + pdata.RotationSpeedMult)%360
        else
            return (pdata.Rotation + math.abs(pdata.Velocity.Z) * pdata.RotationSpeedMult)%360
        end
    end

    function REVEL.PartSystem:UpdateParticle(part, i) --return false if the particle is dead
        local pdata, spr = REVEL.GetData(part).PartData, part:GetSprite()

        if not pdata.Type.RemoveOutOfRoom 
        or pdata.Life > pdata.StartLife * pdata.Type.FadeInEnd 
        or REVEL.IsOutOfRoomBy(part.Position + part.SpriteOffset * REVEL.SCREEN_TO_WORLD_RATIO, pdata.Type.RemoveOutOfRoom) then
            pdata.Life = pdata.Life - 1
        end

        if pdata.Life <= 0 or (pdata.Position.Z >= self.GroundHeight and pdata.Type.DieOnLand) then
            return false
        end

        local alpha = pdata.Type:GetAlphaOverLife(pdata.Life, pdata.StartLife)

        if pdata.ChangeColor or alpha ~= pdata.prevAlpha then
            -- spr.Color = pdata.Color
            -- spr.Color.A = pdata.Color.A * alpha not doable for some reason as it says member A doesn't exist wtf
            local color = REVEL.CloneColor(pdata.Color)
            color.A = color.A * alpha
            spr.Color = color
        end

        pdata.prevAlpha = alpha

        part.SpriteScale = Vector.One * (pdata.Type:GetScaleOverLife(pdata.Life, pdata.StartLife) * pdata.Scale)

        -- part.Position = pdata.Position.XY
        -- part.Velocity = pdata.Velocity.XY
        -- part.SpriteOffset = Vector(0, pdata.Position.Z)

        pdata.Rotation = self:GetRotation(pdata)
        spr.Rotation = pdata.Rotation

        local wind = self.Wind

        if not pdata.prevWind then pdata.prevWind = REVEL.VEC3_ZERO end

        if self.Turbulence then
            pdata.TurbulenceReangleTime = pdata.TurbulenceReangleTime - 1
            if pdata.TurbulenceReangleTime < 0 then
                pdata.TurbulenceReangleTime = self.TurbulenceReangleMinTime + math.random(self.TurbulenceReangleMaxTime - self.TurbulenceReangleMinTime)

                for i=1, 3 do
                    if self.TurbulenceMaxAngleXYZ[i] ~= 0 then
                        if self.Wind ~= REVEL.VEC3_ZERO then
                            pdata.Wind = self.Wind:RotatedDegrees(i, (math.random() * 2 - 1) * self.TurbulenceMaxAngleXYZ[i])
                        end
                        pdata.Velocity:RotateDegrees(i, (math.random() * 2 - 1) * self.TurbulenceMaxAngleXYZ[i])
                    end
                end
            end
            wind = pdata.Wind
        end

        local normalVelocityUpdate = true

        local wi = pdata.Type:GetWindInfluenceOverTime(pdata.Life, pdata.StartLife, part, pdata)

        local renderer = pdata.RenderedByEnt and pdata.RenderedByEnt.Ref

        if pdata.Velocity.Z >= 0 and pdata.Position.Z >= self.GroundHeight then --if on ground and not floating away
            if pdata.Type.Bounce == 0 then
                pdata.Velocity = (pdata.Velocity + wind * wi) * self.GroundFriction * pdata.Type.FrictionMult

                if pdata.Rotation - self.Gravity <= 0 then --if rotation was just increased past starting point
                    pdata.Rotation = 0
                end

                if not pdata.WasGrounded then
                    part.Visible = false
                    if renderer then
                        REVEL.GetData(pdata.RenderedByEnt).ParticlesToRender[GetPtrHash(part)] = nil
                    end

                    particlesToRenderOnFloor[GetPtrHash(part)] = part
                    -- REVEL.DebugToConsole("grounded")
                    pdata.WasGrounded = true

                    if not roomHasFloorParticleRenderer then
                        spawnFloorParticleRenderer()
                    end
                end

                normalVelocityUpdate = false
            else
                pdata.Velocity[3] = -pdata.Velocity.Z
                pdata.Velocity = pdata.Velocity * pdata.Type.Bounce
            end
        elseif pdata.WasGrounded then
            particlesToRenderOnFloor[GetPtrHash(part)] = nil
            if renderer then
                REVEL.GetData(renderer).ParticlesToRender[GetPtrHash(part)] = EntityPtr(part)
            end
            if not renderer or pdata.Type.RenderNormallyWithEntity then
                part.Visible = true
            end
            pdata.WasGrounded = false
        elseif pdata.RenderedByEnt and not renderer then
            pdata.RenderedByEnt = nil
            pdata.Visible = true
        end

        if normalVelocityUpdate then
            local friction = self.AirFriction
            if pdata.Colliding then
                friction = self.WallFriction
            end

            pdata.Velocity = pdata.Velocity * friction * pdata.Type.FrictionMult + self.GravityVector * pdata.Type.Weight + wind * wi - (pdata.prevWind * 0.5)

            if pdata.WasGrounded then
                particlesToRenderOnFloor[GetPtrHash(part)] = nil
                if pdata.RenderedByEnt then
                    REVEL.GetData(pdata.RenderedByEnt).ParticlesToRender[GetPtrHash(part)] = EntityPtr(part)
                end
                if not pdata.RenderedByEnt or pdata.Type.RenderNormallyWithEntity then
                    part.Visible = true
                end
                pdata.WasGrounded = false
            end
        end

        spr.Rotation = pdata.Type.RestingRotation + pdata.Rotation

        pdata.prevWind = wind

        return true
    end

    function REVEL.PartSystem:CollidePart(pdata, applyFriction)
        local colliding = false
        local prevZ, prevX, prevY = pdata.Position.Z, pdata.Position.X, pdata.Position.Y
        pdata.Position.Z = math.min(pdata.Position.Z, self.GroundHeight)
        if prevZ ~= pdata.Position.Z then
            colliding = true
        end

        if self.Clamped then
            if self.TopLeftClamp == -1 then
                local tl, br = REVEL.room:GetTopLeftPos() + self.RoomClampOffset, REVEL.room:GetBottomRightPos() - self.RoomClampOffset
                pdata.Position.XY = pdata.Position.XY:Clamped(tl.X, tl.Y, br.X, br.Y)
            else
                pdata.Position.XY = pdata.Position.XY:Clamped(self.TopLeftClamp.X, self.TopLeftClamp.Y, self.BotRightClamp.X, self.BotRightClamp.Y)
            end
        end
        if REVEL.dist(prevX, pdata.Position.X) > 0.001 or REVEL.dist(prevY, pdata.Position.Y) > 0.001 then
            colliding = true
        end
        if applyFriction then
            pdata.Colliding = colliding
        end
    end

    local WallAngle = math.pi/3 --angle at which the vanilla room walls seem to be slanted at due to perspective (used for better collision w walls), where 0 would be perpendicular from the floor
    local SinWallAngle = math.sin(WallAngle)
    function REVEL.PartSystem:GetPartPerspectiveOffset(pos3D)
        local worldToScreenMult = REVEL.WORLD_TO_SCREEN_RATIO
        -- should be used for ambience particles or ones that 
        -- are not spawned by something that has a certainposition 
        -- in game (else the offset would make it look offset from its source)
        if self.PerspectiveTweak then 
            local cDist = pos3D.XY - RoomC
            local perspXAngle = REVEL.Lerp2(0, WallAngle, math.abs(cDist.X), 0, RoomBR.X - RoomC.X )

            local t = REVEL.Saturate((pos3D.Y - RoomTL.Y) / (RoomBR.Y - RoomTL.Y))
            -- The idea is: at top to center y, yoffset is equal to height/zpos; at bottom, it should be sin(angle) * -zpos
            -- not perfectly accurate but looks kinda goodish
            local yOffsetMult = REVEL.ClampedLerp(1, -SinWallAngle, t*2-1)
            return Vector(-pos3D.Z * math.sin(perspXAngle) * sign(cDist.X), pos3D.Z * yOffsetMult ) * worldToScreenMult
        else
            return Vector(0, pos3D.Z * worldToScreenMult)
        end
    end

    function REVEL.PartSystem:Get2dPos(pos3D)
        return Isaac.WorldToScreen(pos3D.XY) + self:GetPartPerspectiveOffset(pos3D)
    end

    function REVEL.PartSystem:InterpolateParticle(part)
        local pdata = REVEL.GetData(part).PartData
        pdata.Position = pdata.Position + pdata.Velocity/2 --3d pos and vel (vel /2 cause 60fps)
        self:CollidePart(pdata, true)

        part.Position = pdata.Position.XY
        part.SpriteOffset = self:GetPartPerspectiveOffset(pdata.Position) + pdata.Type.BaseOffset * REVEL.WORLD_TO_SCREEN_RATIO

        if pdata.Parent and pdata.Parent:Exists() then
            part.Position = part.Position + pdata.Parent.Position
        end
    end
end

--EMITTERS
do
    ---@type fun(): ParticleEmitter
    REVEL.Emitter = nil

    ---@class ParticleEmitter
    ---@field GetPosition? fun(self, fromPos: Vec3): Vec3
    REVEL.Emitter = StageAPI.Class("PartEmitter", true)
    ---@type ParticleEmitter[]
    REVEL.Emitters = {}

    local ClearEmitTimeTimerStart = 5

    function REVEL.Emitter:Init()
        self.NextEmitTime = -1
        self.ClearEmitTime = ClearEmitTimeTimerStart
        table.insert(REVEL.Emitters, self)
    end

    function REVEL.Emitter:GetDirLength(vel)
        local dir, length
        if self.lastVel == vel then
            dir = self.lastDir --as not to calculate equal speeds more times
            length = self.lastLength
        else
            dir, length = vel:Normalized()
        end
        self.lastVel = vel
        self.lastDir = dir
        self.lastLength = length
        return dir, length
    end

    REVEL.Emitter.InheritInit = REVEL.Emitter.Init

    local function GetVelocityFromSpread(dir, length, velSpread)
        local vel

        if velSpread == 360 then --100% random angle, no need for geometry fuckery when we can just use RandomVec3()
            vel = RandomVec3() * length
        else
            velSpread = math.pi * velSpread / 180

            local perp1
            if not (dir.Y == 0 and dir.Z == 0) then
                perp1 = dir:Cross(REVEL.VEC3_X)
            else --if dir is parallel to x SetMaxDistance
                perp1 = REVEL.VEC3_Y --no need for cross product, if dir is parallel to x axis any other axis vector is perpendicular to dir
            end

            --perp1 y, perp2 -x

            local perp2 = dir:Cross(perp1)

            local randInPerpPlane = RandomVector() --random 2d vector in the perpendicular plane to the base direction

            --get the absolute 3d coordinates of the above vector from the 3d ones relative from the plane
            --that has perp1 and perp2 as X and Y axii resepctively

            local displace = perp1 * randInPerpPlane.X  + perp2 * randInPerpPlane.Y

            local angle = (math.random() - 0.5) * velSpread
            displace:Resize(length * math.sin(angle))
            vel = dir * (length * math.cos(angle)) + displace
        end

        return vel
    end

    ---@param type ParticleType
    ---@param system ParticleSystem
    ---@param pos Vector | Vec3
    ---@param vel Vector | Vec3
    ---@param amount? integer
    ---@param velRand? number
    ---@param velSpread? number
    ---@param parent? Entity
    ---@param zoffset? number
    ---@param entityRenderer? Entity
    function REVEL.Emitter:EmitParticlesNum(type, system, pos, vel, amount, velRand, velSpread, parent, zoffset, entityRenderer)
        if not pos.Z then
            pos = Vec3(pos, 0)
        end
        if not vel.Z then
            vel = Vec3(vel, 0)
        end
        amount = amount or 1
        velRand = velRand or 0
        if revel.data.particlesOn > 0 then
            for i=1, amount do
                local thisVel = vel:Clone()

                if velSpread then
                    local dir, length = self:GetDirLength(thisVel)

                    if length > 0.01 then
                        thisVel = GetVelocityFromSpread(dir, length, velSpread)
                    end
                end
                local velMultRand = 1 + (2 * math.random() - 1) * velRand
                thisVel = thisVel * velMultRand

                -- to have a random position for each particle for the
                -- shaped emitters
                if self.GetPosition then
                    pos = self:GetPosition(pos)
                end

                local part = type:Spawn(system, pos, thisVel, parent, entityRenderer)
                part.DepthOffset = zoffset or 0
            end
        end
    end

    -- If the period is this times the average period between particles, it must mean
    -- there was a period of time where the emitter just didn't shoot, so reset it to 
    -- avoid it spamming a lot of particles to "catch up" to the big delay
    -- local MAX_TIME_BETWEEN_PARTICLES_MULT = 20

    ---@param type ParticleType
    ---@param system ParticleSystem
    ---@param pos Vec3 emitter center pos
    ---@param vel Vec3 base particle velocity
    ---@param freq number frequency in particles/second
    ---@param velRand? number velocity randomness, 1: up to -100% and +100% from base speed, 0 unaltered
    ---@param velSpread? number velocity direction spread, in degrees. It's a 3d angle. 0 for no spread, 360 for fully random direction, inbetween starts from base vel
    ---@param parent? Entity
    ---@param zoffset? number base isaac RenderZOffset
    ---@param entityRenderer? Entity if should render above this entity, after its render
    ---@param freqRand? number frequency randomness, 0 is no random, 1: up to +100% and -100%
    function REVEL.Emitter:EmitParticlesPerSec(type, system, pos, vel, freq, velRand, velSpread, parent, zoffset, entityRenderer, freqRand)
        --how many ms are between each particle
        local period = 1000/(freq * ((revel.data.particlesOn == 2) and 1 or ReducedParticlesFreqMult))
        local time = Isaac.GetTime() --in ms
        local particlesToShoot = 0

        -- Too much time between calls, reset
        -- if self.NextEmitTime ~= -1 
        -- and time - self.NextEmitTime > period * MAX_TIME_BETWEEN_PARTICLES_MULT
        -- then
        --     self.NextEmitTime = -1
        -- end

        if self.NextEmitTime == -1 then
            local periodRandom = 1 + math.random() * (freqRand or 0) * 2
            self.NextEmitTime = time + period * periodRandom
            particlesToShoot = 1
        else
            --in case frequency is high enough for multiple particles to be spawned each frame
            while time >= self.NextEmitTime do
                self.NextEmitTime = self.NextEmitTime + period
                particlesToShoot = particlesToShoot + 1
            end
        end

        if particlesToShoot ~= 0 then
            self:EmitParticlesNum(type, system, pos, vel, particlesToShoot, velRand, velSpread, parent, zoffset, entityRenderer)
        end

        self.ClearEmitTime = ClearEmitTimeTimerStart
    end

    ---@param entity Entity
    ---@param emitter ParticleEmitter
    ---@param key any
    function REVEL.AddEntityParticleEmitter(entity, emitter, key)
        local data = REVEL.GetData(entity)
        if not data.Emitters then
            data.Emitters = {}
        end
        data.Emitters[key] = emitter
    end

    ---@param entity Entity
    ---@param key any
    ---@return boolean
    function REVEL.HasEntityParticleEmitter(entity, key)
        local data = REVEL.GetData(entity)
        if not data.Emitters then
            return false
        end
        return not not data.Emitters[key]
    end

    ---@param entity Entity
    ---@param key any
    ---@return ParticleEmitter
    function REVEL.GetEntityParticleEmitter(entity, key)
        local data = REVEL.GetData(entity)
        if not data.Emitters then
            return nil
        end
        return data.Emitters[key]
    end

    ---@param entity Entity
    ---@param key any
    ---@return boolean
    function REVEL.RemoveEntityParticleEmitter(entity, key)
        local data = REVEL.GetData(entity)
        if not data.Emitters then
            return false
        end
        local e = data.Emitters[key]
        if not e then
            return false
        end
        REVEL.RemoveEmitter(e)
        return true
    end

    function REVEL.RemoveEmitter(emitter)
        local index = REVEL.indexOf(REVEL.Emitters, emitter)
        table.remove(REVEL.Emitters, index)
    end

    ---@param x number
    ---@param y number
    ---@param z number
    ---@return BoxEmitter
    function REVEL.BoxEmitter(x, y, z)
    end

    ---@class BoxEmitter : ParticleEmitter
    REVEL.BoxEmitter = REVEL.Emitter()

    --Can use just 1 arg for cubic box
    function REVEL.BoxEmitter:Init(x, y, z)
        REVEL.Emitter.Init(self)
        self.SizeX = x
        self.SizeY = y or x
        self.SizeZ = z or x
    end

    --position is the center of the box in X/Y, and the bottom in Z
    function REVEL.BoxEmitter:GetPosition(origPos)
        return origPos + Vec3( (math.random() - 0.5) * self.SizeX / 2, (math.random() - 0.5) * self.SizeY / 2, -math.random() * self.SizeZ)
    end

    function REVEL.BoxEmitter:SetSizeToRoom()
        local tl, br = REVEL.room:GetTopLeftPos(), REVEL.room:GetBottomRightPos()
        self.SizeX = br.X - tl.X
        self.SizeY = br.Y - tl.Y
    end

    ---@type fun(radius: number): SphereEmitter
    REVEL.SphereEmitter = nil

    ---@class SphereEmitter : ParticleEmitter
    REVEL.SphereEmitter = REVEL.Emitter()

    function REVEL.SphereEmitter:Init(radius)
        REVEL.Emitter.Init(self)
        self.Radius = radius
    end

    function REVEL.SphereEmitter:SetRadius(r)
        self.Radius = r
    end

    function REVEL.SphereEmitter:GetPosition(origPos)
        return origPos + (RandomVec3() * self.Radius)
    end

    ---@type fun(radius: number, lookDir?: Vec3): HalfSphereEmitter
    REVEL.HalfSphereEmitter = nil

    ---@class HalfSphereEmitter : SphereEmitter
    REVEL.HalfSphereEmitter = REVEL.SphereEmitter(-1)

    function REVEL.HalfSphereEmitter:Init(radius, lookDir)
        REVEL.SphereEmitter.Init(self, radius)
        self.LookDir = lookDir
    end

    function REVEL.HalfSphereEmitter:SetLookDir(lookDir)
        if not REVEL.IsVec3(lookDir) then
            error("HalfSphereEmitter:SetLookDir | lookDir must be Vec3", 2)
        end

        self.LookDir = lookDir
    end

    function REVEL.HalfSphereEmitter:GetOffset()
        assert(self.LookDir, "LookDir not set yet! Call SetLookDir before spawning particles with HalfSphereEmitter")
    
        local dir = self.LookDir
        local offset = RandomVec3()
        if dir:Dot(offset) < 0 then --flip offset if its more than 90° off the direction
            offset = -offset
        end
        return offset * self.Radius
    end

    function REVEL.HalfSphereEmitter:GetPosition(origPos)
        local offset = self:GetOffset()
        return origPos + offset
    end

    ---@type fun(width: number): LineEmitter
    REVEL.LineEmitter = nil

    ---@class LineEmitter : ParticleEmitter
    REVEL.LineEmitter = REVEL.Emitter()

    --Can use just 1 arg for cubic box
    function REVEL.LineEmitter:Init(width)
        REVEL.Emitter.Init(self)
        self.Width = width
    end

    function REVEL.LineEmitter:SetWidth(width)
        self.Width = width
    end

    local function Vec3Lerp(a, b, x)
        if REVEL.IsVec3(a) then
            return Vec3(
                REVEL.Lerp(a[1], b[1], x),
                REVEL.Lerp(a[2], b[2], x),
                REVEL.Lerp(a[3], b[3], x)
            )
        else
            return Vec3(
                REVEL.Lerp(a.X, b.X, x),
                REVEL.Lerp(a.Y, b.Y, x),
                0
            )
        end
    end

    --position is the center of the box in X/Y, and the bottom in Z
    function REVEL.LineEmitter:EmitParticlesPerSec(type, system, pos1, pos2, vel, freq, velRand, velSpread, entityRenderer, freqRand)
        local pos = Vec3Lerp(pos1, pos2, math.random())
        pos = pos + RandomVec3() * self.Width -- more of a radius, but result more or less the same and more optimized
        REVEL.Emitter.EmitParticlesPerSec(self, type, system, pos, vel, freq, velRand, velSpread, entityRenderer, freqRand)
    end

    -- since it cannot use GetPosition due to different args, using EmitParticlesNum will spawn multiple particles
    -- in the same position
    function REVEL.LineEmitter:EmitParticlesNum(type, system, pos1, pos2, vel, freq, velRand, velSpread, entityRenderer)
        local pos = Vec3Lerp(pos1, pos2, math.random())
        pos = pos + RandomVec3() * self.Width -- more of a radius, but result more or less the same and more optimized
        REVEL.Emitter.EmitParticlesNum(self, type, system, pos, vel, freq, velRand, velSpread, entityRenderer)
    end
end
    

-- General purpose systems
-- To avoid redefining a normal gravity/low gravity
-- system with the same properties every time

REVEL.ParticleSystems = {
    Basic = REVEL.PartSystem.FromTable {
        Name = "Basic",
        Gravity = 0.5,
        AirFriction = 0.95,
    },
    BasicClamped = REVEL.PartSystem.FromTable {
        Name = "Basic Clamped",
        Gravity = 0.5,
        AirFriction = 0.95,
        Clamped = true,
        RoomClampOffset = Vector(4, 4),
    },
    LowGravity = REVEL.PartSystem.FromTable {
        Name = "Low Gravity",
        Gravity = 0.01,
        AirFriction = 0.95
    },
    NoGravity = REVEL.PartSystem.FromTable {
        Name = "No Gravity",
        Gravity = 0,
        AirFriction = 0.95
    },
}

--Simplified functions for common use

local SimpleEmitter = REVEL.Emitter()
local SimpleParticleType = REVEL.ParticleType.FromTable{
    Name = "Simple Particle",
    Anm2 =    "gfx/blank.anm2",
    BaseLife = 9999,
    FadeOutStart = 0.1,
    LifeRandom = 0,
    Variants = 1
}

function SimpleParticleType:GetAlphaOverLife()
    return 1
end

local SimpleSystem = REVEL.PartSystem.FromTable{
    Name = "Simple System",
    Gravity = 0.5,
    AirFriction = 1,
    Clamped = true
}

--anm2 needs to have a "Idle" anim where each frame is a different particle
function REVEL.ParticleBurst(pos3, vel3, amount, anm2, frameNum, animName, angle, sprite, color, scale, life)
    local type = SimpleParticleType()
    type:SetColor(color or Color.Default, 0)
    type:SetAnm2(anm2, frameNum, animName)
    type:SetSpritesheet(sprite or "default")
    type:SetScaleOverLife(function() return scale or 1 end)
    type:SetLife(life or 9999, 0)

    SimpleEmitter:EmitParticlesNum(type, SimpleSystem, pos3, vel3, amount, 0.2, (angle or 0))
end

do
    REVEL.ENABLE_PARTICLE_TEST = true
    if REVEL.DEBUG and REVEL.ENABLE_PARTICLE_TEST then
        revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
            local pos = Input.GetMousePosition(true)
            if REVEL.IsMouseBtnTriggered(Mouse.MOUSE_BUTTON_1) then
                REVEL.ParticleBurst(Vec3(pos, -20), Vec3(0, 0, -4), 5, "gfx/1000.066_ember particle.anm2", 8, "Idle", 45)
                -- SimpleEmitter:EmitParticlesNum(PuckImpactParticle, SimpleSystem, Vec3(pos, -20), Vec3(0, 0, -4), 5, 0.2, (25 or 0) * math.pi / 180)
            end
        end)
    end
end

function REVEL.RemoveParticlesOfType(particleType)
    local particles = REVEL.ENT.PARTICLE:getInRoom()

    for _, effect in ipairs(particles) do
        local pdata = REVEL.GetData(effect).PartData
        if pdata and pdata.Type == particleType then
            effect:Remove()
        end
    end
end

-- Callbacks

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, function()
    roomHasFloorParticleRenderer = false
    particlesToRenderOnFloor = {}
    -- for _,system in ipairs(REVEL.PartSystems) do
    --     system.Particles = {}
    -- end

    RoomTL = REVEL.room:GetTopLeftPos()
    RoomBR = REVEL.room:GetBottomRightPos()
    RoomC = REVEL.room:GetCenterPos()
end)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, function()
    for _, entity in pairs(REVEL.roomEntities) do
        if REVEL.GetData(entity).Emitters then
            for k, emitter in pairs(REVEL.GetData(entity).Emitters) do
                table.insert(REVEL.Emitters, emitter)
            end
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    local data = REVEL.GetData(effect)
    local pdata = data.PartData

    if pdata then
        local system = pdata.System

        if not pdata.StopUpdating then
            local alive = system:UpdateParticle(effect)
            if not alive then
                local renderer = pdata.RenderedByEnt and pdata.RenderedByEnt.Ref
                if renderer and REVEL.GetData(renderer).ParticlesToRender then
                    REVEL.GetData(renderer).ParticlesToRender[GetPtrHash(effect)] = nil
                end
                particlesToRenderOnFloor[GetPtrHash(effect)] = nil

                local shouldRemove = pdata.Type.RemoveOnDeath
                if shouldRemove == 1 then
                    effect:Remove()
                elseif shouldRemove == 2 then
                    effect.Visible = true
                    effect:AddEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)
                end

                pdata.StopUpdating = true
            end
        end
    end
end, REVEL.ENT.PARTICLE.variant)

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect)
    if not REVEL.game:IsPaused() and REVEL.IsRenderPassNormal() then
        local data = REVEL.GetData(effect)
        local pdata = data.PartData

        if pdata then
            local system = pdata.System
        
            if not pdata.StopUpdating then
                system:InterpolateParticle(effect)
            end
        end
    end
end, REVEL.ENT.PARTICLE.variant)

-- Disabled unlikely ones to be used 
-- to not tax more than necessary
local renderCallbacks = {
    ModCallbacks.MC_POST_PLAYER_RENDER,
    -- ModCallbacks.MC_POST_TEAR_RENDER,
    ModCallbacks.MC_POST_FAMILIAR_RENDER,
    -- ModCallbacks.MC_POST_BOMB_RENDER,
    -- ModCallbacks.MC_POST_PICKUP_RENDER,
    -- ModCallbacks.MC_POST_LASER_RENDER,
    -- ModCallbacks.MC_POST_KNIFE_RENDER,
    -- ModCallbacks.MC_POST_PROJECTILE_RENDER,
    ModCallbacks.MC_POST_NPC_RENDER,
    -- ModCallbacks.MC_POST_EFFECT_RENDER,
}

local function particlesEntRendererPostRender(_, entity, renderOffset)
    local data = REVEL.GetData(entity)

    if data.ParticlesToRender then
        for hash, ptr in pairs(data.ParticlesToRender) do
            local part = ptr.Ref
            if part then
                -- IDebug.RenderCircle(Isaac.WorldToScreen(part.Position) + part.SpriteOffset, true, 2)
                part:GetSprite():Render(Isaac.WorldToScreen(part.Position) + renderOffset - REVEL.room:GetRenderScrollOffset())
            else
                data.ParticlesToRender[ptr] = nil
            end
        end
    end
end

for _, callback in ipairs(renderCallbacks) do
    revel:AddCallback(callback, particlesEntRendererPostRender)
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, function(_, effect, renderOffset)
    if REVEL.GetData(effect).FloorParticleRenderer and REVEL.IsRenderPassFloor() then
        local cnt = 0
        for _, part in pairs(particlesToRenderOnFloor) do
            part:GetSprite():Render(Isaac.WorldToScreen(part.Position) + part.SpriteOffset + renderOffset - REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            cnt = cnt + 1
        end
    end
end, StageAPI.E.FloorEffect.V)

revel:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
    local data = REVEL.GetData(entity)

    if data.Emitters then
        for k, emitter in pairs(data.Emitters) do
            REVEL.RemoveEmitter(emitter)
        end
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    -- for _,system in ipairs(REVEL.PartSystemsAutoUpdate) do
    --     system:Update()
    -- end

    for i, emit in ipairs(REVEL.Emitters) do
        if emit.ClearEmitTime <= 0 then
            emit.NextEmitTime = - 1
        else
            emit.ClearEmitTime = emit.ClearEmitTime - 1
        end
    end
end)

local wasPaused

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    -- if not REVEL.game:IsPaused() then
    --     for _,system in ipairs(REVEL.PartSystemsAutoUpdate) do
    --         system:Render()
    --     end
    -- end

    if not wasPaused and REVEL.game:IsPaused() then
        wasPaused = true
        for i = 1, #REVEL.Emitters do
            REVEL.Emitters[i].NextEmitTime = -1
        end
    elseif wasPaused and not REVEL.game:IsPaused() then
        wasPaused = false
    end
end)


Isaac.DebugString("Revelations: Loaded Particles!")
end