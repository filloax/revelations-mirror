local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")

return function()

-- Callbacks
-- REV_PRE_RENDER_ENTITY_REFLECTION: (entity, sprite, offset) specify type optionally, return false to not render (still calls POST)
-- REV_POST_RENDER_ENTITY_REFLECTION: (entity, sprite, offset) specify type optionally

-- Huge Thanks to Dead for making the reflections possible

local mirrorFloorSprite = REVEL.LazyLoadRoomSprite{
    ID = "mirrorFloorSprite",
}

local TransparentMirrorBackdrop = {
    Walls = {"gfx/backdrop/revel1/mirror/mirror_floor_transparent.png"}
}

local reflectionPositionOffset = Vector(0, -32)

local roomHasReflections = false

function REVEL.AddReflections(alpha, renderMirrorFloor, renderMirrorOverlays)
    if not roomHasReflections then
        local refMan = StageAPI.SpawnFloorEffect(REVEL.room:GetTopLeftPos() + reflectionPositionOffset, nil, nil, nil, nil, REVEL.ENT.REF_MAN.variant)
        refMan.RenderZOffset = 0
        REVEL.GetData(refMan).alphaMult = alpha
        REVEL.GetData(refMan).refMngr = true
        REVEL.GetData(refMan).RenderMirrorFloor = renderMirrorFloor
        REVEL.GetData(refMan).RenderMirrorOverlays = renderMirrorOverlays
        REVEL.GetData(refMan).mirrorFloorSpritePosition = REVEL.room:GetTopLeftPos() --StageAPI.LoadBackdropSprite(mirrorFloorSprite, TransparentMirrorBackdrop, 2)
        mirrorFloorSprite:Load("gfx/backdrop/revel1/mirror/MirrorAlpha_FloorBackdrop.anm2", true)
        mirrorFloorSprite:Play(StageAPI.ShapeToName[REVEL.room:GetRoomShape()], true)

        roomHasReflections = true
    else
        REVEL.DebugLog("Warn: tried adding reflections twice")
    end
end

function REVEL.HasReflectionsInRoom()
    return roomHasReflections
end

local justCalled = false
local groundGrids = {
    GridEntityType.GRID_SPIDERWEB,
    GridEntityType.GRID_DECORATION,
    GridEntityType.GRID_DOOR,
    GridEntityType.GRID_TRAPDOOR,
    GridEntityType.GRID_PRESSURE_PLATE,
    GridEntityType.GRID_PIT,
    GridEntityType.GRID_SPIKES,
    GridEntityType.GRID_SPIKES_ONOFF,
    GridEntityType.GRID_WALL
}

local noReflectEntities = {
    [EntityType.ENTITY_LASER] = {
        [-1] = true
    },
    [EntityType.ENTITY_EFFECT] = {
        [EffectVariant.BRIMSTONE_SWIRL] = true,
        [EffectVariant.LASER_IMPACT] = true,
        [EffectVariant.LADDER] = true,

        [EffectVariant.CREEP_BLACK] = true,
        [EffectVariant.CREEP_BROWN] = true,
        [EffectVariant.CREEP_GREEN] = true,
        [EffectVariant.CREEP_RED] = true,
        [EffectVariant.CREEP_SLIPPERY_BROWN] = true,
        [EffectVariant.CREEP_WHITE] = true,
        [EffectVariant.CREEP_YELLOW] = true,
        [EffectVariant.PLAYER_CREEP_BLACK] = true,
        [EffectVariant.PLAYER_CREEP_BLACKPOWDER] = true,
        [EffectVariant.PLAYER_CREEP_GREEN] = true,
        [EffectVariant.PLAYER_CREEP_HOLYWATER] = true,
        [EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL] = true,
        [EffectVariant.PLAYER_CREEP_LEMON_MISHAP] = true,
        [EffectVariant.PLAYER_CREEP_LEMON_PARTY] = true,
        [EffectVariant.PLAYER_CREEP_PUDDLE_MILK] = true,
        [EffectVariant.PLAYER_CREEP_RED] = true,
        [EffectVariant.PLAYER_CREEP_WHITE] = true
    }
}

local layerZeroEntities = {
    [EntityType.ENTITY_FAMILIAR] = {
        [FamiliarVariant.SAMSONS_CHAINS] = true,
        [FamiliarVariant.GEMINI] = true
    }
}

function REVEL.renderReflection(ent, alpha)
    alpha = alpha or 1
    local data = REVEL.GetData(ent)
    local vanillaData = ent:GetData()
    if not justCalled 
    and not data.noReflection and not vanillaData.noReflection
    and (
        data.forceReflect or vanillaData.forceReflect 
        or (not noReflectEntities[ent.Type] or (not noReflectEntities[ent.Type][-1] and not noReflectEntities[ent.Type][ent.Variant]))
    ) then
        local customReflectionSprite = data.CustomReflectionSprite or vanillaData.CustomReflectionSprite
        local sprite = customReflectionSprite or ent:GetSprite()
        local noFlipReflectionY = data.NoFlipReflectionY or vanillaData.NoFlipReflectionY
        local reflectRenderLayer = data.ReflectRenderLayer or vanillaData.ReflectRenderLayer

        data.reflectOffset = data.reflectOffset or vanillaData.reflectOffset or Vector.Zero

        if not noFlipReflectionY then
            sprite.FlipY = not sprite.FlipY
        end
        local colorOld = REVEL.CloneColor(sprite.Color)

        sprite.Color = REVEL.ChangeColorAlpha(sprite.Color, alpha)

        local doRender = true
        local ret = StageAPI.CallCallbacksWithParams(RevCallbacks.PRE_RENDER_ENTITY_REFLECTION, true, ent.Type, 
            ent, sprite, data.reflectOffset)
        if ret == false then
            doRender = false
        end

        if doRender then
            if not customReflectionSprite and layerZeroEntities[ent.Type] and layerZeroEntities[ent.Type][ent.Variant] then
                sprite:RenderLayer(0, Isaac.WorldToRenderPosition(ent.Position) + data.reflectOffset + REVEL.room:GetRenderScrollOffset())
            else
                if not reflectRenderLayer then
                    sprite:Render(Isaac.WorldToRenderPosition(ent.Position)+data.reflectOffset + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
                else
                    sprite:RenderLayer(reflectRenderLayer, Isaac.WorldToRenderPosition(ent.Position) + data.reflectOffset + REVEL.room:GetRenderScrollOffset())
                end
            end
        end
        
        StageAPI.CallCallbacksWithParams(RevCallbacks.POST_RENDER_ENTITY_REFLECTION, false, ent.Type, 
            ent, sprite, data.reflectOffset, doRender)

        if not noFlipReflectionY then
            sprite.FlipY = not sprite.FlipY
        end
        sprite.Color = colorOld
    end
end

--[[
    NOT NEEDED FOR NOW AS MIRROR ROOM HAS NO GRIDS
    local function renderReflectGrids()
        if not justCalled then
            for i = 1, REVEL.room:GetGridSize() do
                local grid = REVEL.room:GetGridEntity(i)
                if grid then
                    local gridType = grid.Desc.Type
                    if not REVEL.includes(groundGrids, gridType) then
                        local sprite = grid:GetSprite()
                        sprite.FlipY = not sprite.FlipY
                        local colorOld = sprite.Color
                        sprite.Color = Color(colorOld.R, colorOld.G, colorOld.B, colorOld.A * 0.25,conv255ToFloat( colorOld.RO, colorOld.GO, colorOld.BO))
                        sprite:Render(Isaac.WorldToScreen(grid.Position) + Vector(0, 16), Vector.Zero, Vector.Zero)
                        sprite.FlipY = not sprite.FlipY
                        sprite.Color = colorOld
                    end
                end
            end
        end
            end

    local function renderGrids()
        if not justCalled then
            for i = 1, REVEL.room:GetGridSize() do
                local grid = REVEL.room:GetGridEntity(i)
                if grid then
                    local gridType = grid.Desc.Type
                    if not REVEL.includes(groundGrids, gridType) then
                        grid:Render(REVEL.room:GetRenderScrollOffset())
                    end
                end
            end
        end
    end

    local function renderPass(ent)
        if not justCalled then
            justCalled = true
            ent:Render(REVEL.room:GetRenderScrollOffset())
            justCalled = false
        end
    end
]]

local mirrorDeadSprite = REVEL.LazyLoadRoomSprite{
    ID = "mirrorDeadSprite",
    Anm2 = "gfx/backdrop/Floor.anm2",
    OnCreate = function(sprite)
        sprite:ReplaceSpritesheet(0, "gfx/backdrop/revel1/mirror/1x1_mirrordeadoverlay.png")
        sprite:Play("Default", true)
        sprite:LoadGraphics()
    end,
}

local mirrorCrackedSprite = REVEL.LazyLoadRoomSprite{
    ID = "mirrorDeadSprite",
    Anm2 = "gfx/backdrop/revel1/mirror/mirror_crackoverlay.anm2",
    Animation = "Break",
}

function REVEL.GetMirrorDeadSprite()
    return mirrorDeadSprite
end

function REVEL.GetMirrorCrackedSprite()
    return mirrorCrackedSprite
end

local horizontalShineSizeX = 280
local horizontalShineSizeY = 288
local verticalShineSizeX = 443
local verticalShineSizeY = 286
local horizontalShineX = 0
local verticalShineY = 0

local horizontalShineSprite = REVEL.LazyLoadRoomSprite{
    ID = "mirrorHorizontalShineSprite",
    Anm2 = "gfx/backdrop/Floor.anm2",
    OnCreate = function(sprite)
        sprite:ReplaceSpritesheet(0, "gfx/backdrop/revel1/mirror/mirror_horizontalshine.png")
        sprite:Play("Default", true)
        sprite:LoadGraphics()
    end
}

local verticalShineSprite = REVEL.LazyLoadRoomSprite{
    ID = "mirrorVerticalShineSprite",
    Anm2 = "gfx/backdrop/Floor.anm2",
    OnCreate = function(sprite)
        sprite:ReplaceSpritesheet(0, "gfx/backdrop/revel1/mirror/mirror_verticalshine.png")
        sprite:Play("Default", true)
        sprite:LoadGraphics()
    end
}

REVEL.MirrorRoomCracked = false
REVEL.MirrorRoomDead = false
local oddMirrorFrame = false

local NoShineScaleShapes = {RoomShape.ROOMSHAPE_1x1, RoomShape.ROOMSHAPE_IH, RoomShape.ROOMSHAPE_IV}

local function reflectionsManagerPostEffectRender(_, eff)
    local data = REVEL.GetData(eff)
    if data.refMngr and not justCalled and REVEL.IsRenderPassFloor() then
        local floorRenderPosition = Isaac.WorldToRenderPosition(data.mirrorFloorSpritePosition) + REVEL.room:GetRenderScrollOffset()
        if data.RenderMirrorFloor then
            local tl, br = REVEL.GetRoomCorners()
            local roomSizeX = br.X - tl.X
            local roomSizeY = br.Y - tl.Y
            local horizontalShineMax = roomSizeX + horizontalShineSizeX
            local horizontalShineMin = -horizontalShineSizeX
            local verticalShineMax = roomSizeY + verticalShineSizeY
            local verticalShineMin = -verticalShineSizeY

            if not REVEL.includes(NoShineScaleShapes, REVEL.room:GetRoomShape()) then
                horizontalShineSprite.Scale = Vector(1, roomSizeY / horizontalShineSizeY)
                verticalShineSprite.Scale = Vector(roomSizeX / verticalShineSizeX, 1)
            else
                horizontalShineSprite.Scale = Vector.One
                verticalShineSprite.Scale = Vector.One
            end

            if not REVEL.game:IsPaused() then
                horizontalShineX = horizontalShineX + 1
                verticalShineY = verticalShineY + 1
                if horizontalShineX > horizontalShineMax then
                    horizontalShineX = horizontalShineMin
                end

                if verticalShineY > verticalShineMax then
                    verticalShineY = verticalShineMin
                end

                horizontalShineSprite.Offset = Vector(horizontalShineX, 0)
                verticalShineSprite.Offset = Vector(0, verticalShineY)
            end

            horizontalShineSprite:Render(floorRenderPosition, Vector.Zero, Vector.Zero)
            verticalShineSprite:Render(floorRenderPosition, Vector.Zero, Vector.Zero)
        end

        StageAPI.CallCallbacks(RevCallbacks.PRE_RENDER_REFLECTIONS, false)

        if REVEL.STAGE.Tomb:IsStage() then
            REVEL.RenderReflectionsTomb(eff, data)
        else
            for i,ent in ipairs(REVEL.roomEffects) do --render effects before, so they don't overlap stuff
                if ent.Visible and ent.Variant ~= StageAPI.E.Door.V then
                    REVEL.renderReflection(ent, data.alphaMult)
                end
            end

            for i,ent in ipairs(REVEL.roomEntities) do
                if ent.Visible and ent.Type ~= 1000 then
                    REVEL.renderReflection(ent, data.alphaMult)
                end
            end
        end

        StageAPI.CallCallbacks(RevCallbacks.POST_RENDER_REFLECTIONS, false)

        if data.RenderMirrorFloor then
            mirrorFloorSprite:Render(floorRenderPosition, Vector.Zero, Vector.Zero)
        end

        oddMirrorFrame = not oddMirrorFrame

        if data.RenderMirrorOverlays then
            if REVEL.MirrorRoomCracked then
                if oddMirrorFrame then
                    mirrorCrackedSprite:Update()
                end

                mirrorCrackedSprite:Render(floorRenderPosition, Vector.Zero, Vector.Zero)
            end

            if REVEL.MirrorRoomDead then
                if oddMirrorFrame then
                    mirrorDeadSprite:Update()
                end

                mirrorDeadSprite:Render(floorRenderPosition, Vector.Zero, Vector.Zero)
            end
        end

        if REVEL.STAGE.Tomb:IsStage() then
            REVEL.RenderMirrorOverlaysTomb()
        end

        StageAPI.CallCallbacks(RevCallbacks.POST_RENDER_MIRROR_OVERLAYS, false)

    --        renderReflectGrids() --no grids needed
    --        renderGrids()

    --        for _, ent in ipairs(REVEL.roomEntities) do
    --          renderPass(ent)
    --        end
    end
end

local function reflectionsPostNewRoom()
    roomHasReflections = false
end

revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, reflectionsManagerPostEffectRender, REVEL.ENT.REF_MAN.variant)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, reflectionsPostNewRoom)

-- Special player reflections

local PlayerCostumes = {
    [PlayerType.PLAYER_MAGDALENA] = {
        Head = "gfx/characters/character_002_magdalenehead.anm2",
    },
    [PlayerType.PLAYER_CAIN] = {
        Head = "gfx/characters/character_003_cainseyepatch.anm2",
    },
    [PlayerType.PLAYER_JUDAS] = {
        Head = "gfx/characters/character_004_judasfez.anm2",
    },
    -- [PlayerType.PLAYER_XXX] = {
    -- },
    [PlayerType.PLAYER_EVE] = {
        Head = "gfx/characters/character_005_evehead.anm2",
    },
    [PlayerType.PLAYER_SAMSON] = {
        Head = "gfx/characters/character_007_samsonhead.anm2",
    },
    [PlayerType.PLAYER_AZAZEL] = {
        Body = "gfx/characters/character_008_azazelhead.anm2",
        Head = "gfx/characters/character_008_azazelhead.anm2",
        WalkAnimLength = 12,
        NoDefaultFly = true,
    },
    [PlayerType.PLAYER_LAZARUS] = {
        Head = "gfx/characters/character_lazarushair1.anm2",
    },
    [PlayerType.PLAYER_LAZARUS2] = {
        Head = "gfx/characters/character_lazarushair2.anm2",
    },
    [PlayerType.PLAYER_EDEN] = {
        Head = "gfx/characters/character_009_edenhair1.anm2",
    },
    [PlayerType.PLAYER_THELOST] = {
        NoDefaultFly = true,
    },
    [PlayerType.PLAYER_LILITH] = {
        Head = "gfx/characters/character_lilithhair.anm2",
    },
    [PlayerType.PLAYER_KEEPER] = {
        Head = "gfx/characters/character_014_keepernoose.anm2",
    },
    [PlayerType.PLAYER_APOLLYON] = {
        Head = "gfx/characters/character_015_apollyonbody.anm2",
        Body = "gfx/characters/character_015_apollyonbody.anm2",
    },
    [PlayerType.PLAYER_THEFORGOTTEN] = {
        Body = "gfx/characters/character_016_theforgottenbody.anm2",
    },
    [PlayerType.PLAYER_THESOUL] = {
        NoDefaultFly = true,
    },
    [PlayerType.PLAYER_BETHANY] = {
        Head = "gfx/characters/character_001x_bethanyhead.anm2",
    },
    [PlayerType.PLAYER_JACOB] = {
        Head = "gfx/characters/character_002x_jacobhead.anm2",
    },
    [PlayerType.PLAYER_ESAU] = {
        Head = "gfx/characters/character_003x_esauhead.anm2",
    },

    [PlayerType.PLAYER_ISAAC_B] = {
        Head = "gfx/characters/character_b01_isaac.anm2",
    },
    [PlayerType.PLAYER_MAGDALENA_B] = {
        Head = "gfx/characters/character_b02_magdalene.anm2",
    },
    [PlayerType.PLAYER_CAIN_B] = {
        Head = "gfx/characters/character_b03_cain.anm2",
    },
    [PlayerType.PLAYER_JUDAS_B] = {
        Head = "gfx/characters/character_b04_judas.anm2",
    },
    [PlayerType.PLAYER_XXX_B] = {
        Head = "gfx/characters/character_b05_bluebaby.anm2",
        Body = "gfx/characters/character_b05_bluebaby.anm2",
    },
    [PlayerType.PLAYER_EVE_B] = {
        Head = "gfx/characters/character_b06_eve.anm2",
    },
    [PlayerType.PLAYER_SAMSON_B] = {
        Head = "gfx/characters/character_b07_samson.anm2",
    },
    [PlayerType.PLAYER_AZAZEL_B] = {
        Head = "gfx/characters/character_b08_azazel.anm2",
    },
    [PlayerType.PLAYER_LAZARUS_B] = {
        Head = "gfx/characters/character_b09_lazarus.anm2",
        Body = "gfx/characters/character_b09_lazarus.anm2",
    },
    [PlayerType.PLAYER_EDEN_B] = {
        Head = "gfx/characters/character_b10_eden.anm2",
    },
    [PlayerType.PLAYER_THELOST_B] = {
        Head = "gfx/characters/character_b11_thelost.anm2",
        NoDefaultFly = true,
    },
    [PlayerType.PLAYER_LILITH_B] = {
        BodyBase = "gfx/characters/character_b12_lilith.anm2",
        Head = "gfx/characters/character_b12_lilith.anm2",
    },
    [PlayerType.PLAYER_KEEPER_B] = {
        Head = "gfx/characters/character_b13_keeper.anm2",
    },
    [PlayerType.PLAYER_APOLLYON_B] = {
        Head = "gfx/characters/character_b14_apollyon.anm2",
        Body = "gfx/characters/character_b14_apollyon.anm2",
    },
    [PlayerType.PLAYER_THEFORGOTTEN_B] = {
        Head = "gfx/characters/character_b15_theforgotten.anm2",
        BodyBase = "gfx/characters/character_b15_theforgotten.anm2",
    },
    [PlayerType.PLAYER_BETHANY_B] = {
        Head = "gfx/characters/character_b16_bethany.anm2",
    },
    [PlayerType.PLAYER_JACOB_B] = {
        Head = "gfx/characters/character_b17_jacob.anm2",
    },
    [PlayerType.PLAYER_LAZARUS2_B] = {
        Head = "gfx/characters/character_b09_lazarus2.anm2",
    },
    [PlayerType.PLAYER_JACOB2_B] = {
        Head = "gfx/characters/character_b17_jacob2.anm2",
    },
    [PlayerType.PLAYER_THESOUL_B] = {
        Head = "gfx/characters/character_b15_thesoul.anm2",
        NoDefaultFly = true,
    },

    [REVEL.CHAR.SARAH.Type] = {
        -- Head = "gfx/characters/revelcommon/character_sarah.anm2",
    },
    [REVEL.CHAR.DANTE.Type] = {
        Body = "gfx/characters/revelcommon/character_dante.anm2",
    },
    [REVEL.CHAR.CHARON.Type] = {
    },
}

local TheLostModeCostume = {
    NoDefaultFly = true,
    ReplaceRender = true,
    BodyBaseSprite = "gfx/characters/costumes/character_012_thelost.png",
    Head = "gfx/001.000_player.anm2", -- manually render head
    HeadSprite = "gfx/characters/costumes/character_012_thelost.png",
}

local HeadTransformNulls = {
    [PlayerType.PLAYER_LILITH_B] = {
        WalkDown = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        WalkRight = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        WalkUp = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        WalkLeft = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        PickupWalkDown = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        PickupWalkRight = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        PickupWalkUp = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
        PickupWalkLeft = {
            Offset = {Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0), Vector(0, 0), Vector(0, -2), Vector(0, -3), Vector(0, -3), Vector(0, -3), Vector(0, -4), Vector(0, -4), Vector(0, -3), Vector(0, -2), Vector(0, -2), Vector(0, -1), Vector(0, 0)},
            Scale = {Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98), Vector(110, 90), Vector(105, 95), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(100, 100), Vector(98, 102), Vector(95, 105), Vector(102, 98)}
        },
    },
    [PlayerType.PLAYER_THEFORGOTTEN_B] = {
        WalkLeft = {
            Offset = {Vector(0, 5)},
            Scale = {Vector(100, 100)}
        },
        WalkRight = {
            Offset = {Vector(0, 5)},
            Scale = {Vector(100, 100)}
        },
        WalkUp = {
            Offset = {Vector(0, 5)},
            Scale = {Vector(100, 100)}
        },
        WalkDown = {
            Offset = {Vector(0, 5)},
            Scale = {Vector(100, 100)}
        },
    },
}

local defaultFlyCostume = "gfx/characters/184_holy grail.anm2"
local defaultFlyAnimLength = 42
local blankTable = {}

local LostPlayerTypes = {
    PlayerType.PLAYER_THELOST,
    PlayerType.PLAYER_THELOST_B,
    PlayerType.PLAYER_JACOB2_B,
    PlayerType.PLAYER_THESOUL_B,
}

local function GetCostumeData(player)
    local ptype = player:GetPlayerType()
    local costumeData = PlayerCostumes[ptype] or blankTable

    -- lost mode, replace sprite
    if not REVEL.includes(LostPlayerTypes, ptype)
    and REVEL.PlayerIsLost(player) 
    then
        costumeData = TheLostModeCostume
    end

    return costumeData
end

local function playerPreReflection(entity, sprite, offset)
    local player, data = entity:ToPlayer(), REVEL.GetData(entity)
    local costumeData = GetCostumeData(player)

    if (costumeData or player.CanFly) and player.Visible then
        local costumeData = GetCostumeData(player)
        local doRender
        if costumeData.ReplaceRender then
            doRender = false
        end

        if costumeData.BodyBase or costumeData.BodyBaseSprite then
            if not data.__reflectionBodyBaseSprite then
                data.__reflectionBodyBaseSprite = Sprite()
                data.__reflectionBodyBaseSprite:Load(costumeData.BodyBase or sprite:GetFilename(), false)
                if costumeData.BodyBaseSprite then
                    for layer = 0, 14 do
                        data.__reflectionBodyBaseSprite:ReplaceSpritesheet(layer, costumeData.BodyBaseSprite)
                    end
                end
                data.__reflectionBodyBaseSprite:LoadGraphics()
                data.__reflectionBodyBaseSprite.FlipY = true    
            end

            data.__reflectionBodyBaseSprite:SetFrame(sprite:GetAnimation(), sprite:GetFrame())
            data.__reflectionBodyBaseSprite.Color = sprite.Color

            if sprite:GetAnimation() ~= "WalkUp" then
                data.__reflectionBodyBaseSprite:Render(Isaac.WorldToRenderPosition(player.Position) + offset + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            end
        end

        local useDefaultFlight = player.CanFly and not costumeData.NoDefaultFly

        if costumeData.Body or useDefaultFlight then
            --if no body fly sprite but can fly, use a generic flying sprite
            local anm2 = useDefaultFlight and defaultFlyCostume or costumeData.Body 

            if useDefaultFlight then
                data.__defaultFlyAnim = true
                doRender = false
            end

            if not data.__reflectionBodySprite then
                data.__reflectionBodySprite = Sprite()
                data.__reflectionBodySprite:Load(anm2, true)
                data.__reflectionBodySprite.FlipY = true
            end
        elseif not costumeData.Body and not useDefaultFlight and data.__reflectionBodySprite then
            data.__reflectionBodySprite = nil
            data.__defaultFlyAnim = nil
        end

        if not data.__reflectionHairSprite and costumeData.Head then
            data.__reflectionHairSprite = Sprite()
            data.__reflectionHairSprite:Load(costumeData.Head, false)
            if costumeData.HeadSprite then
                for layer = 0, 14 do
                    data.__reflectionHairSprite:ReplaceSpritesheet(layer, costumeData.HeadSprite)
                end
            end
            data.__reflectionHairSprite:LoadGraphics()
            data.__reflectionHairSprite.FlipY = true
        end

        return doRender
    end
end

local function playerPostReflection(entity, sprite, offset)
    local player, data = entity:ToPlayer(), REVEL.GetData(entity)
    local costumeData = GetCostumeData(player)
    local ptype = player:GetPlayerType()

    if (costumeData or (player.CanFly and data.__defaultFlyAnim)) and player.Visible then           
        if data.__reflectionBodyBaseSprite and sprite:GetAnimation() == "WalkUp" then
            data.__reflectionBodyBaseSprite:Render(Isaac.WorldToRenderPosition(player.Position) + offset + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
        end

        if data.__reflectionBodySprite then
            local animLen = costumeData.WalkAnimLength or (data.__defaultFlyAnim and defaultFlyAnimLength) or REVEL.GetAnimLength(sprite)
            data.__reflectionBodySprite:SetFrame(sprite:GetAnimation(), (sprite:GetFrame() + math.floor(data.__reflectionBodyFrameOffset or 0)) % animLen)
            data.__reflectionBodySprite.Color = sprite.Color

            data.__reflectionBodySprite:Render(Isaac.WorldToRenderPosition(player.Position) + offset + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)

            -- Rerender head to avoid covering it w body
            local anim, frame = sprite:GetAnimation(), sprite:GetFrame()
            sprite:SetFrame("LightTravel", 35) --invisible frame for base sprite, leave only overlay
            sprite:Render(Isaac.WorldToRenderPosition(player.Position) + offset + REVEL.room:GetRenderScrollOffset(), Vector.Zero, Vector.Zero)
            sprite:Play(anim, true)
            sprite:SetFrame(frame) --skip frames without freezing
        end

        if data.__reflectionHairSprite then
            local transformOffset = Vector.Zero

            if HeadTransformNulls[ptype] then
                local anim, frame = sprite:GetAnimation(), sprite:GetFrame()
                if HeadTransformNulls[ptype][anim] then
                    local index = math.min(#HeadTransformNulls[ptype][anim].Scale, frame + 1)
                    data.__reflectionHairSprite.Scale = HeadTransformNulls[ptype][anim].Scale[index] * 0.01
                    transformOffset = -HeadTransformNulls[ptype][anim].Offset[index]
                else
                    data.__reflectionHairSprite.Scale = Vector.One
                end
            end

            if sprite:GetOverlayAnimation() ~= "" then --only render for animations with separate Head
                data.__reflectionHairSprite:SetFrame(sprite:GetOverlayAnimation(), sprite:GetOverlayFrame())
                data.__reflectionHairSprite.Color = sprite.Color
    
                data.__reflectionHairSprite:Render(Isaac.WorldToRenderPosition(player.Position) 
                        + offset + REVEL.room:GetRenderScrollOffset() + transformOffset, 
                    Vector.Zero, Vector.Zero)
            end  
        end
    end
end

-- use proper fly anim frame, since
-- when player flies but stays still the frame you get with
-- Sprite:GetFrame() is wrong in that case
local function reflectionPostPlayerUpdate(_, player)
    local sprite, data = player:GetSprite(), REVEL.GetData(player)

    if REVEL.HasReflectionsInRoom() and data.__reflectionBodySprite and player.CanFly 
    and player:GetMovementDirection() == Direction.NO_DIRECTION then
        local costumeData = PlayerCostumes[player:GetPlayerType()] or blankTable
        local animLen = costumeData.WalkAnimLength or (data.__defaultFlyAnim and defaultFlyAnimLength) or REVEL.GetAnimLength(sprite)

        data.__reflectionBodyFrameOffset = data.__reflectionBodyFrameOffset or math.floor(animLen) / 2
        data.__reflectionBodyFrameOffset = (data.__reflectionBodyFrameOffset + sprite.PlaybackSpeed) % animLen
    elseif data.__reflectionBodyFrameOffset then
        data.__reflectionBodyFrameOffset = nil
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.PRE_RENDER_ENTITY_REFLECTION, 1, playerPreReflection, 1)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_RENDER_ENTITY_REFLECTION, 1, playerPostReflection, 1)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, reflectionPostPlayerUpdate)

end