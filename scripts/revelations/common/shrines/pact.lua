local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")

return function()

local HudSettingsMinimapAPI = {
    -- minimapAPI map width varies, is there a way to check it?
    SHRINE_ICONS_HUD_OFFSET = Vector(-100, 8), -- from top right
    HUD_ROW_WIDTH = 3,
    HUD_ROW_DIR = REVEL.VEC_DOWN,
    HUD_COLUMN_OFFSET = 0,
    HUD_ROW_OFFSET = 0,
    HUD_ICON_SIZE = 16,
    HUD_LARGE_OFFSET = Vector(-58, 0),
}

local HudSettingsVanilla = {
    SHRINE_ICONS_HUD_OFFSET = Vector(-67, 8), -- from top right
    HUD_ROW_WIDTH = 3, --more than 3 won't fit with more curses/map effects
    HUD_ROW_DIR = REVEL.VEC_DOWN,
    HUD_COLUMN_OFFSET = 0,
    HUD_ROW_OFFSET = 0,
    HUD_ICON_SIZE = 16,
    HUD_LARGE_OFFSET = Vector(-64, 0),
}

local ActiveShrinesSet = {}
local ShrineCommonParents = {}

---@type table<string, RevShrine>
REVEL.Shrines = {
    --[[
    gratuity = {
        Name = "gratuity",
        OnTrigger = function,
        CanDoorsOpen = function
    }
    ]]
}

---@type table<string, ShrineSet>
REVEL.ShrineSets = {

}

REVEL.CommonShrines = {

}

local RevBossRoomTypes = {
    RoomType.ROOM_BOSS,
    RevRoomType.BOSS_SANDY,
    RevRoomType.TRAP_BOSS,
    RevRoomType.TRAP_BOSS_MAXWELL,
    RevRoomType.TRAP_BOSS_SARCOPHAGUTS,
    RevRoomType.ICE_BOSS,
    RevRoomType.MIRROR,
}
RevBossRoomTypes = REVEL.toSet(RevBossRoomTypes)

---@param shrine string
---@param allowBoss? boolean
---@param allowVanity? boolean
---@return boolean isActive
---@return integer activeAmount
function REVEL.IsShrineEffectActive(shrine, allowBoss, allowVanity)
    local rtype = StageAPI.GetCurrentRoomType()
    if ActiveShrinesSet[shrine] 
    and ( allowBoss or not RevBossRoomTypes[rtype] )
    and (allowVanity or (
        rtype ~= RevRoomType.VANITY
        and rtype ~= RevRoomType.CASINO
    ))
    then
        return true, ActiveShrinesSet[shrine]
    else
        return false, 0
    end
end

---@class ShrineSet
---@field Prefix string
---@field Suffix string
---@field Lightning string
---@field OutlineColor Color
---@field PlaquePath string
---@field PlaqueTextColors string
---@field Stage CustomStage?

---@param name string
---@param prefix string
---@param suffix string
---@param lightning string
---@param outlineColor Color
---@param plaquePath string
---@param plaqueTextColors {Base: KColor, Light: KColor, Name: KColor, NameLight: KColor}
---@param stage? CustomStage
function REVEL.AddShrineSet(name, prefix, suffix, lightning, outlineColor, plaquePath, plaqueTextColors, stage)
    REVEL.ShrineSets[name] = {
        Prefix = prefix or "", 
        Suffix = suffix or ".png", 
        Lightning = lightning, 
        OutlineColor = outlineColor,
        PlaquePath = plaquePath,
        PlaqueTextColors = plaqueTextColors,
        Stage = stage,
    }
end

-- inverted set
local NameShrineSets = {}

---@class RevShrine
---@field Name string @used as id when checking if present
---@field DisplayName string
---@field Description string
---@field EID_Description table
---@field Sprite string @sprite filename to use if different from name
---@field PreTrigger fun(npc: EntityNPC): boolean @returns if the trigger should be cancelled
---@field OnTrigger fun(npc: EntityNPC)
---@field TriggerExternal fun()
---@field CanDoorsOpen fun(): boolean
---@field Value integer
---@field ValueOneChapter integer
---@field AlwaysOneChapter boolean
---@field RemoveOnStageEnd boolean
---@field Repeatable boolean
---@field MaxRepeats integer
---@field Requires fun(): boolean
---@field HudIconFrame integer @frame on the ui animation (uses shrine set name for which animation)
---@field Set string
---@field Weight integer? 

---@param set string
---@param shrine RevShrine
---@param commonShrine? string
function REVEL.AddShrine(set, shrine, commonShrine)
    -- inherit from commonShrine
    if commonShrine then
        if not REVEL.CommonShrines[commonShrine] then
            error("REVEL.AddShrine: no common shrine " .. tostring(commonShrine), 2)
        end
        shrine = REVEL.MergeTables(shrine, REVEL.CommonShrines[commonShrine])
        shrine.CommonBase = commonShrine
        ShrineCommonParents[shrine.Name] = commonShrine
    end

    shrine.Set = set
    REVEL.ShrineSets[set][#REVEL.ShrineSets[set] + 1] = shrine.Name
    REVEL.Shrines[shrine.Name] = shrine
    NameShrineSets[shrine.Name] = set
end

---@param shrine RevShrine
function REVEL.AddCommonShrine(shrine)
    REVEL.CommonShrines[shrine.Name] = shrine
end

function REVEL.GetShrineSet(set)
    if not REVEL.ShrineSets[set] then
        error("REVEL.GetShrineSet | no shrine set named " .. tostring(set), 2)
    end
    return REVEL.ShrineSets[set]
end

function REVEL.UpdateActiveShrineSet()
    ActiveShrinesSet = {}
    for _, activeShrine in ipairs(revel.data.run.activeShrines) do
        ---@type string
        local setName = NameShrineSets[activeShrine.name]
        local set = REVEL.ShrineSets[setName]

        if not set.Stage or set.Stage:IsStage() then
            if ActiveShrinesSet[activeShrine.name] then
                ActiveShrinesSet[activeShrine.name] = ActiveShrinesSet[activeShrine.name] + 1
            else
                ActiveShrinesSet[activeShrine.name] = 1
            end

            if ShrineCommonParents[activeShrine.name] then
                if ActiveShrinesSet[ShrineCommonParents[activeShrine.name]] then
                    ActiveShrinesSet[ShrineCommonParents[activeShrine.name]] = ActiveShrinesSet[ShrineCommonParents[activeShrine.name]] + 1
                else
                    ActiveShrinesSet[ShrineCommonParents[activeShrine.name]] = 1
                end
            end
        end
    end
end

local function shrinePacts_PostNewLevel()
    for i, activeShrine in ripairs(revel.data.run.activeShrines) do
        if activeShrine.removeStageEnd then
            table.remove(revel.data.run.activeShrines, i)
        end
    end
    REVEL.UpdateActiveShrineSet()
end

local shrineSprite = REVEL.LazyLoadLevelSprite{
    ID = "pact_shrineSprite",
    Anm2 = "gfx/ui/shrine_icons.anm2",
}

local function shrinePacts_PostRender()
    if #revel.data.run.activeShrines == 0
    or not REVEL.ShouldRenderHudElements() 
    then
        return
    end

    -- Render HUD Icons

    local s = MinimapAPI and HudSettingsMinimapAPI or HudSettingsVanilla

    local topRight = REVEL.GetScreenTopRight()
    local basePos = topRight + s.SHRINE_ICONS_HUD_OFFSET

    if REVEL.IsMapLarge() then
        basePos = basePos + s.HUD_LARGE_OFFSET
    end

    local isVert = s.HUD_ROW_DIR.X == 0
    local signRow = isVert and sign(s.HUD_ROW_DIR.Y) or sign(s.HUD_ROW_DIR.X)
    local dirCol = isVert and REVEL.VEC_LEFT or REVEL.VEC_DOWN

    local num = 0
    for _, activeShrine in ipairs(revel.data.run.activeShrines) do
        local shrineData = REVEL.Shrines[activeShrine.name]
        local set = NameShrineSets[shrineData.Name]
        local setData = REVEL.ShrineSets[set]

        if shrineData.HudIconFrame and (not setData.Stage or setData.Stage:IsStage()) then
            shrineSprite:SetFrame(set, shrineData.HudIconFrame)
            local x, y = num % s.HUD_ROW_WIDTH, math.floor(num / s.HUD_ROW_WIDTH)
            local offset = s.HUD_ROW_DIR * signRow * s.HUD_ROW_OFFSET * x + dirCol * s.HUD_COLUMN_OFFSET * y
            if isVert then
                offset = offset + Vector(0, signRow * s.HUD_ICON_SIZE * x) + dirCol * s.HUD_ICON_SIZE * y
            else
                offset = offset + Vector(signRow * s.HUD_ICON_SIZE * x, 0) + dirCol * s.HUD_ICON_SIZE * y
            end
            shrineSprite:Render(basePos + offset)

            num = num + 1
        end
    end
end

-- Commands

REVEL.Commands.revpact = {
    Execute = function (params)
        local match = REVEL.find(REVEL.Shrines, function(v)
            return string.lower(v.Name) == string.lower(params) or string.lower(v.DisplayName) == string.lower(params)
        end)
        if match then
            table.insert(revel.data.run.activeShrines, {
                name = match.Name,
                value = 0,
                isOneChapter = REVEL.IsLastChapterStage() or match.AlwaysOneChapter,
                removeStageEnd = match.RemoveOnStageEnd,
                oneChapterValue = 0,
            })
            REVEL.UpdateActiveShrineSet()
            Isaac.ConsoleOutput("Added Pact of " .. tostring(match.DisplayName) .. "!\n")
        else
            REVEL.LogError("Invalid pact name <" .. params .. ">!\n")
        end
    end,
    Autocomplete = function (params)
        local names = {}
        local displayNames = {}
        for _, v in ipairs(REVEL.Shrines) do
            names[#names+1] = v.Name
            displayNames[#displayNames+1] = v.DisplayName
        end

        return REVEL.concat(displayNames, names)
    end,
    Usage = "pactName",
    Desc = "Add a Rev pact",
    Help = "Adds the chosen pact, check ShrineTypes.lua or autocomplete for valid names (common ones are invalid)",
    File = "pact.lua",
}

revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, shrinePacts_PostNewLevel)
StageAPI.AddCallback("Revelations", StageAPICallbacks.POST_HUD_RENDER, 1, shrinePacts_PostRender)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_SAVEDATA_LOAD, 1, REVEL.UpdateActiveShrineSet)

end