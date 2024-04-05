require("scripts.minimapapi.init")
local MinimapAPI = require("scripts.minimapapi")

local REV_MINIMAPAPI_VERSION = "Revelations"

local function IsRevVersion()
    return MinimapAPI.BranchVersion == REV_MINIMAPAPI_VERSION or MinimapAPI.Version == REV_MINIMAPAPI_VERSION
end

if IsRevVersion() then
    MinimapAPI.DisableSaving = true

    Isaac.DebugString("Revelations: Using integrated MinimapAPI")
end

function REVEL.UsingIntegratedMinimapAPI()
    return IsRevVersion()
end

---@param menuExit? boolean
function REVEL.GetMinimapAPISaveData(menuExit)
    if IsRevVersion() then
        return MinimapAPI:GetSaveTable(menuExit)
    end
end

---@param data table
---@param loadedFromSave? boolean
function REVEL.LoadMinimapAPISaveData(data, loadedFromSave)
    if IsRevVersion() then
        MinimapAPI:LoadSaveTable(data.minimapapi, loadedFromSave)
    end
end

-- Copied from config_menu.lua, as it's private
-- cannot change just configpreset as it's normal
-- behavior is loading these settings, and all of that
-- is local to MinimapAPI
local VanillaPresetSettings = {
    ShowIcons = true,
    ShowPickupIcons = true,
    ShowShadows = true,
    ShowCurrentRoomItems = false,
    MapFrameWidth = 50,
    MapFrameHeight = 45,
    PositionX = 4,
    PositionY = 4,
    DisplayMode = 2,
    ShowLevelFlags = true,
    SmoothSlidingSpeed = 1,
    HideInCombat = 1,
    HideInInvalidRoom = true,
    OverrideVoid = false,
    DisplayExploredRooms = false,
    AllowToggleLargeMap = true,
    AllowToggleSmallMap = false,
    AllowToggleBoundedMap = true,
    AllowToggleNoMap = false,
    PickupNoGrouping = false,
    ShowGridDistances = false,
    HighlightFurthestRoom = false,
    VanillaSecretRoomDisplay = true,
}

---@param data table
function REVEL.LoadMinimapAPIFirstLoad(data)
    if IsRevVersion() then
        -- set default config to vanilla map
        local vanillaMapPresetIndex = 2
        MinimapAPI.Config.ConfigPreset = vanillaMapPresetIndex
        for k, v in pairs(VanillaPresetSettings) do
            MinimapAPI.Config[k] = v
        end

        data.minimapapi.Config = REVEL.CopyTable(MinimapAPI.Config)

        REVEL.DebugStringMinor("Revelations: Loaded rev default minimapAPI config values")
    end
end


