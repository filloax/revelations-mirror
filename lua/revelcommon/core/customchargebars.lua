local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

----------------
-- Custom bar --
----------------

-- Rep half-deprecated this, but yellow charge bars
-- are still a use case


local CHARGE_POS = {
    Vector(38, 17), --top left
    Vector(-142, 16) + Vector(18, 1), --values taken from TrueMP
    Vector(103, -16) + Vector(18, 1),
    Vector(-150, -16) + Vector(18, 1)
}

FULL_CHARGE_OFFSET = Vector(-18, -1)

local OffsetFuncs = { --since getscreencenter can change
    "GetScreenTopLeft",
    "GetScreenTopRight",
    "GetScreenBottomLeft",
    "GetScreenBottomRight"
}

local CHARGE_SH = 3 --height from where the green starts from top
local CHARGE_FH = 27 --pixel height from start of bar sprite (including transparent segment) to bottommost green pixel
local CHARGE_H = CHARGE_FH - CHARGE_SH

local EXTRA_2_COLOR = Color(1,1,1,1,conv255ToFloat(0,0,255))

local YELLOW_OUTLINE_COLOR = REVEL.YELLOW_OUTLINE_COLOR

local barItemsMaxCharge = {}
local manageCharge = {}
local barItemColors = {}
local batteryInfluence = {}
local barOverlays = {1, 2, 3, 4, 6, 12}
local barBlink = {0,0,0,0}

local debug8on = false

-- Load sprites on a run basis, so they're not loaded if you never get any item that uses them

local chargeBarEmpty = REVEL.LazyLoadRunSprite{
    ID = "ccb_chargeBarEmpty",
    Anm2 = "gfx/ui/ui_chargebar.anm2",
    Animation = "BarEmpty",
}

local chargeBar = REVEL.LazyLoadRunSprite{
    ID = "ccb_chargeBar",
    Anm2 = "gfx/ui/ui_chargebar.anm2",
    Animation = "BarFull",
}

local chargeBarExtra = REVEL.LazyLoadRunSprite{
    ID = "ccb_chargeBarExtra",
    Anm2 = "gfx/ui/ui_chargebar.anm2",
    Animation = "BarFull",
    Color = Color(1,1,1,1, 1,0,0),
}

local chargeBarExtra2 = REVEL.LazyLoadRunSprite{
    ID = "ccb_chargeBarExtra2",
    Anm2 = "gfx/ui/ui_chargebar.anm2",
    Animation = "BarFull",
    Color = EXTRA_2_COLOR,
}

local fullCharge = {}
for i=1, 4 do
    --texture to be replaced by the white full charge outline
    fullCharge[i] = REVEL.LazyLoadRunSprite{
        ID = "ccb_fullCharge" .. i,
        Anm2 = "gfx/ui/active_item.anm2",
        OnCreate = function(sprite)
            sprite:SetFrame("On", 0)
        end,
    }
end

local chargeBarColor = {
    Color.Default,
    Color.Default,
    Color.Default,
    Color.Default
}

local chargeBarOverlay = {}

for pid = 0, 3 do
    chargeBarOverlay[pid] = REVEL.LazyLoadRunSprite{
        ID = "ccb_chargeBarOverlay" .. pid,
        Anm2 = "gfx/ui/ui_chargebar.anm2",
    }
end

local function initPlayer(p)
    local data = p:GetData()

    data.__chargeMax = {}
    data.__chargeMaxBase = {}
    data.__prevChargeMaxBase = 0
    data.__prevItem = 0
    data.__batMult = 1

    local playerID = REVEL.GetPlayerID(p)
    if not revel.data.run.customActiveCharge[playerID] then
        revel.data.run.customActiveCharge[playerID] = {}
        revel:saveData()
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, p)
    if not p:GetData().__chargeMax then
        initPlayer(p) --fallback
    end
end)

revel:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, p)
    initPlayer(p)
end)

function REVEL.AddCustomBar(id, maxCharge, manCharge, color, batInfluence)
    if manCharge == nil then manCharge = true end
    color = color or Color.Default

    barItemsMaxCharge[id] = maxCharge
    manageCharge[id] = manCharge
    barItemColors[id] = color
    batteryInfluence[id] = batInfluence or 1
end

function REVEL.SetCharge(a, p, blink, itemId)
    p = p or REVEL.player
    itemId = itemId or p:GetActiveItem()
    if p:IsSubPlayer() then
        p = REVEL.players[REVEL.GetPlayerID(p)]
    end
    local data = p:GetData()
    local stringItemId = tostring(itemId)

    local maxCharge = REVEL.GetMaxCharge(p, false, itemId)

    local playerID = REVEL.GetPlayerID(p)
    local prevCharge = revel.data.run.customActiveCharge[playerID][stringItemId] or maxCharge

    if not a then return end
    revel.data.run.customActiveCharge[playerID][stringItemId] = math.max(0, math.min( maxCharge, a ) )

    if revel.data.run.customActiveCharge[playerID][stringItemId] == 0 then
        local c = 0

        if batteryInfluence[itemId] then
            c = c + p:GetCollectibleNum(CollectibleType.COLLECTIBLE_NINE_VOLT)
            if p:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) then c = c + 1 end

            c = c * batteryInfluence[itemId]
        end

        revel.data.run.customActiveCharge[playerID][stringItemId] = math.min(c, REVEL.GetMaxCharge(p, true, itemId) - 1)
    end

    if (blink == true or blink == nil) and revel.data.run.customActiveCharge[playerID][stringItemId] > prevCharge then
        REVEL.ChargeBlink(p)
        if prevCharge < REVEL.GetMaxCharge(p, true, itemId) and revel.data.run.customActiveCharge[playerID][stringItemId] >= REVEL.GetMaxCharge(p, true, itemId) then
            SFXManager():Play(SoundEffect.SOUND_ITEMRECHARGE, 0.8, 0, false, 1)
        else
            SFXManager():Play(SoundEffect.SOUND_BEEP, 0.8, 0, false, 1)
        end
    end
end

function REVEL.AddCharge(a, p, blink, itemId)
    if REVEL.GetCharge(p, itemId) then
        REVEL.SetCharge(REVEL.GetCharge(p, itemId) + a, p, blink, itemId)
    end
end

function REVEL.AddChargeToBothHeld(a, p, blink)
    REVEL.AddCharge(a, p, blink, p:GetActiveItem())
    if p.SecondaryActiveItem and p.SecondaryActiveItem.Item then
        REVEL.AddCharge(a, p, blink, p.SecondaryActiveItem.Item)
    end
end

function REVEL.ChargeBlink(p)
    barBlink[REVEL.GetPlayerID(p)] = 9
end

function REVEL.GetCharge(p, itemId)
    p = p or REVEL.player
    itemId = itemId or p:GetActiveItem()
    local chargeTbl = revel.data.run.customActiveCharge[REVEL.GetPlayerID(p)]

    if not chargeTbl then
        error("GetCharge: playerID not set yet!", 2)
    end

    return chargeTbl[tostring(itemId)]
end

function REVEL.GetMaxCharge(p, base, itemId)
    if p:IsSubPlayer() then
        p = REVEL.players[REVEL.GetPlayerID(p)]
    end

    itemId = itemId or p:GetActiveItem()

    if not p:GetData().__chargeMaxBase[itemId] then
        p:GetData().__chargeMaxBase[itemId] = barItemsMaxCharge[itemId]
        p:GetData().__chargeMax[itemId] = barItemsMaxCharge[itemId]
    end

    if base then
        return p:GetData().__chargeMaxBase[itemId]
    else
        return p:GetData().__chargeMax[itemId]
    end
end

function REVEL.CalcMaxCharge(a, p)
    if p:IsSubPlayer() then
        p = REVEL.players[REVEL.GetPlayerID(p)]
    end
    local max = math.max( 0 , a )
    local base = max
    if p:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) then
        max = max * (1 + p:GetCollectibleNum(CollectibleType.COLLECTIBLE_BATTERY) )
    end

    return max, base
end

function REVEL.SetMaxCharge(a, p, itemId)
    p = p or REVEL.player
    local data = p:GetData()
    itemId = itemId or p:GetActiveItem()

    data.__chargeMax[itemId], data.__chargeMaxBase[itemId] = REVEL.CalcMaxCharge(a, p)
end

function REVEL.SetBatteryChargeMult(p, mult)
    p:GetData().__batMult = mult
end

function REVEL.SetBarColor(p, color)
    chargeBarColor[REVEL.GetPlayerID(p)] = color
end

local yellowOn = {false, false, false, false}
local yellowBlink = {false, false, false, false}

function REVEL.ChargeYellowOn(player) -- do every peffect update frame
    yellowOn[REVEL.GetPlayerID(player)] = true
end

function REVEL.ChargeYellowBlink(player) -- do every peffect update frame
    REVEL.ChargeYellowOn(player)
    yellowBlink[REVEL.GetPlayerID(player)] = true
end

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, p)
    local data = p:GetData()
    local playerID = REVEL.GetPlayerID(p)

    yellowOn[playerID] = false
    yellowBlink[playerID] = false

    if barItemsMaxCharge[p:GetActiveItem()] then
        if debug8on then
            REVEL.SetCharge(REVEL.GetMaxCharge(p, true), p, true)
        end

        if barBlink[playerID] > 0 then
            barBlink[playerID] = barBlink[playerID] - 1
        end

        if REVEL.GetCharge(p) < REVEL.GetMaxCharge(p, false) then
            local batteries = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, -1, false)

            for i,e in ipairs(batteries) do
                local bdata = e:GetData()
                if barItemsMaxCharge[p:GetActiveItem()] and not e:IsDead() and e.Position:Distance(p.Position) <= p.Size + e.Size then
                    e:GetSprite():Play("Collect", true)
                    e:Die()
                    REVEL.AddCharge(REVEL.GetMaxCharge(p, true) * data.__batMult, p, true)
                end
            end
        end
    end
end)

--Can't use POST_PLAYER_RENDER as that renders below the overlay
local function playerRender(p)
    local id = p:GetActiveItem()
    local data = p:GetData()
    local playerID = REVEL.GetPlayerID(p)

    if barItemsMaxCharge[id] and REVEL.IsRenderPassNormal() then

        if id ~= data.__prevItem then
            data.__prevItem = id

            if not REVEL.GetMaxCharge(p, true, id) then
                REVEL.SetMaxCharge(barItemsMaxCharge[id], p, id)
            end

            --Change active full charge outline sprite
            local itemgfx = REVEL.config:GetCollectible(id).GfxFileName
            for i = 0, 4 do
                    fullCharge[playerID]:ReplaceSpritesheet(i, itemgfx)
            end

            fullCharge[playerID]:LoadGraphics()

            local prev = REVEL.GetCharge(p, id)

            if not prev then
                REVEL.SetCharge(barItemsMaxCharge[id], p)
            end

            REVEL.SetBarColor(p, barItemColors[id])
        end

        if not REVEL.game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) then

            local pos = CHARGE_POS[playerID] + REVEL[ OffsetFuncs[playerID] ]()
            local color = chargeBarColor[playerID]

            local charge = REVEL.GetCharge(p)
            local chargeBase = REVEL.GetMaxCharge(p, true)
            local chargeMax = REVEL.GetMaxCharge(p, false)

            if yellowOn[playerID] then
                if not yellowBlink[playerID] or REVEL.game:GetFrameCount() % 2 == 0 then
                    fullCharge[playerID].Color = YELLOW_OUTLINE_COLOR
                    fullCharge[playerID]:Render(pos + FULL_CHARGE_OFFSET, Vector.Zero, Vector.Zero)
                end
            elseif charge >= chargeBase then
                fullCharge[playerID].Color = Color.Default
                fullCharge[playerID]:Render(pos + FULL_CHARGE_OFFSET, Vector.Zero, Vector.Zero)
            end

            chargeBarEmpty:Render(pos, Vector.Zero, Vector.Zero)

            if barBlink[REVEL.GetPlayerID(p)] % 2 == 0 then
                local clamp = CHARGE_SH + CHARGE_H * math.max(0, 1 - charge / chargeBase)

                chargeBar.Color = color
                chargeBar:Render(pos, Vector(0,clamp), Vector.Zero)

                if charge > chargeBase then
                    local clamp = CHARGE_SH + CHARGE_H * math.max(0, 2 - charge / chargeBase)

                    chargeBarExtra.Color = color
                    chargeBarExtra:Render(pos, Vector(0,clamp), Vector.Zero)
                end
                if charge > chargeBase*2 then
                    local clamp = CHARGE_SH + CHARGE_H * math.max(0, 3 - charge / chargeBase)
                    chargeBarExtra2.Color = color * EXTRA_2_COLOR
                    chargeBarExtra2:Render(pos, Vector(0,clamp), Vector.Zero)
                end
            end

            if chargeBase ~= data.__prevChargeMaxBase then
                if REVEL.includes(barOverlays, chargeBase) then
                    chargeBarOverlay[playerID]:Play("BarOverlay"..chargeBase, true)
                else
                    chargeBarOverlay[playerID]:Play("BarOverlay1",true)
                end

                data.__prevChargeMaxBase = chargeBase
            end

            chargeBarOverlay[playerID]:Render(pos, Vector.Zero, Vector.Zero)
        end

    elseif yellowOn[playerID] then
        if id ~= data.__prevItem then
            data.__prevItem = id

            --Change active full charge outline sprite
            local itemgfx = REVEL.config:GetCollectible(id).GfxFileName
            for i = 0, 4 do
                    fullCharge[playerID]:ReplaceSpritesheet(i, itemgfx)
            end

            fullCharge[playerID]:LoadGraphics()
        end

        if not yellowBlink[playerID] or REVEL.game:GetFrameCount() % 2 == 0 then
            fullCharge[playerID].Color = YELLOW_OUTLINE_COLOR
            local pos = CHARGE_POS[playerID] + REVEL[ OffsetFuncs[playerID] ]()
            fullCharge[playerID]:Render(pos + FULL_CHARGE_OFFSET, Vector.Zero, Vector.Zero)
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if REVEL.NotBossOrNightmare() then
        for i, p in ipairs(REVEL.players) do
            playerRender(p)
        end
    end
end)

--recalculate max charge on battery pickup
StageAPI.AddCallback("Revelations", RevCallbacks.POST_ITEM_PICKUP, 0, function(p)
    local id = p:GetActiveItem()

    if not barItemsMaxCharge[id] then return end

    REVEL.SetMaxCharge(barItemsMaxCharge[id], p)
end, CollectibleType.COLLECTIBLE_BATTERY)

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, function(p)
    p = p:ToPlayer()

    if p:HasCollectible(CollectibleType.COLLECTIBLE_HABIT) then
        REVEL.AddChargeToBothHeld(1, p, true)
    end
end, 1)

function REVEL.AddChargeToAll()
    for i, p in ipairs(REVEL.players) do
        REVEL.AddChargeToBothHeld(1, p, true)
    end
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ROOM_CLEAR, 1, REVEL.AddChargeToAll)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_GREED_CLEAR, 1, REVEL.AddChargeToAll)

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd, params)
    if cmd == 'rdebug' and params == "8" then
        debug8on = not debug8on
    end
end)

if Isaac.GetPlayer(0) then
    for i,p in ipairs(REVEL.players) do
        local data = p:GetData()

        data.__prevItem = 0
        data.__prevChargeMaxBase = 0

        local id = p:GetActiveItem()
    end
end


Isaac.DebugString("Revelations: Loaded Custom Charge Bars!")
end
REVEL.PcallWorkaroundBreakFunction()