local DSSInitializerFunction = include("scripts.rev_dssmenucore")

REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()

REVEL.DSS = {
    ModName = "Dead Sea Scrolls (Revelations)",
    DSSCoreVersion = 7,
}

local MenuProvider = {}

local Credits = include("lua.revdss.credits")
local UnlockMenu = include("lua.revdss.unlockmenu")
local BossMenu = include("lua.revdss.bosshall")


-- REV-SPECIFIC MENU FUNCTIONALITY
local function GetRevData()
    if not REVEL.FAILED_LOAD then
        return revel.data
    else
        -- stub, just not to have it break
        -- when the mod is luamod-ed and there are errors
        -- as it leads to useless logspam
        -- with still registered callbacks in other mods
        return {}
    end
end

function MenuProvider.SaveSaveData()
    if not REVEL.FAILED_LOAD then
        revel:saveData()
    end
end

function MenuProvider.GetPaletteSetting()
    return GetRevData().MenuPalette
end

function MenuProvider.SavePaletteSetting(var)
    GetRevData().MenuPalette = var
end

function MenuProvider.GetHudOffsetSetting()
    if not REPENTANCE then
        return GetRevData().HudOffset
    else
        return Options.HUDOffset * 10
    end
end

function MenuProvider.SaveHudOffsetSetting(var)
    if not REPENTANCE then
        GetRevData().HudOffset = var
    end
end

function MenuProvider.GetGamepadToggleSetting()
    return GetRevData().GamepadToggle
end

function MenuProvider.SaveGamepadToggleSetting(var)
    GetRevData().GamepadToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
    return GetRevData().MenuKeybind
end

function MenuProvider.SaveMenuKeybindSetting(var)
    GetRevData().MenuKeybind = var
end

function MenuProvider.GetMenuHintSetting()
    return GetRevData().MenuHint
end

function MenuProvider.SaveMenuHintSetting(var)
    GetRevData().MenuHint = var
end

function MenuProvider.GetMenuBuzzerSetting()
    return GetRevData().MenuBuzzer
end

function MenuProvider.SaveMenuBuzzerSetting(var)
    GetRevData().MenuBuzzer = var
end

function MenuProvider.GetMenusNotified()
    return GetRevData().MenusNotified
end

function MenuProvider.SaveMenusNotified(var)
    GetRevData().MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
    return GetRevData().MenusPoppedUp
end

function MenuProvider.SaveMenusPoppedUp(var)
    GetRevData().MenusPoppedUp = var
end

-- This function returns a table that some useful functions and defaults are stored on
local dssmod = DSSInitializerFunction(REVEL.DSS.ModName, REVEL.DSS.DSSCoreVersion, MenuProvider)

REVEL.DSS.DSSMod = dssmod

local setLatest = false
function REVEL.AddChangelog(title, date, log)
	if not log then
		log = date
		date = nil
	end

	title = title or ""
	date = date or ""
	log = log or ""

    title = string.lower(title)
    date = string.lower(date)
    log = string.lower(log)

    local parsedLog = string.gsub(log, "%*%*", "{FSIZE2}")
    local notify, popup = false, false
	if not setLatest then
		setLatest = true
        notify, popup = true, true
	end

    DeadSeaScrollsMenu.AddChangelog("Revelations", title, parsedLog, {date}, notify, popup)
end

include("lua.revdss.changelogs")

local DefaultMenuSprites = DeadSeaScrollsMenu.GetDefaultMenuSprites()

REVEL.MenuSprites = {
    --UI Sprites
    Shadow = Sprite(),
    Back = Sprite(),
    Face = Sprite(),
    Mask = Sprite(),
    Border = Sprite(),
    Font = Sprite(),
    Symbols = DefaultMenuSprites.Symbols,
}

REVEL.MenuSprites.Back:Load("gfx/ui/deadseascrolls/revelskin/menu_back.anm2", true)
REVEL.MenuSprites.Face:Load("gfx/ui/deadseascrolls/revelskin/menu_face.anm2", true)
REVEL.MenuSprites.Mask:Load("gfx/ui/deadseascrolls/revelskin/menu_mask.anm2", true)
REVEL.MenuSprites.Border:Load("gfx/ui/deadseascrolls/revelskin/menu_border.anm2", true)
REVEL.MenuSprites.Font:Load("gfx/ui/deadseascrolls/revelskin/menu_font.anm2", true)
REVEL.MenuSprites.Shadow:Load("gfx/ui/deadseascrolls/revelskin/menu_shadow.anm2", true)

local revdirectory = {
	--LEVEL 1
	main = {
		title = 'revelations',
		buttons = {
			{str = 'resume game', action = 'resume'},
			{str = 'settings', dest = 'settings'},
            {str = 'to-do list', dest = 'checklist'},
            {str = 'revelations info', dest = 'info'},
            {str = 'credits', dest = 'credits'},
            dssmod.changelogsButton
		},
        tooltip = dssmod.menuOpenToolTip
	},
	settings = {
		title = 'settings',
		buttons = {
            {
                str = 'better shaders',
                choices = {'on', 'off'},
                tooltip = {strset = {'better for', 'color', 'blindness', 'rarely leads', 'to bugs on', 'some old', 'video cards'}},
                variable = 'ShaderBoostOnOff',
                setting = 2,
                load = function()
                    local cBoostFixOn = revel.data.shaderColorBoostOn2 == 1
                    if cBoostFixOn then
                        return 1
                    else
                        return 2
                    end
                end,
                store = function(var)
                    if var == 1 then
                        revel.data.shaderColorBoostOn2 = 1
                    else
                        revel.data.shaderColorBoostOn2 = 0
                    end
                end
            },
            {
                str = 'sfx volume',
                increment = 1, max = 20,
                variable = "RevSfxVolume",
                slider = true,
                setting = 15,
                load = function()
                    return math.floor(revel.data.volumeMult * 20)
                end,
                store = function(var)
                    revel.data.volumeMult = var / 20
                end,
                tooltip = {strset = {'applies to', 'rev sfx', 'only'}}            
            },
            {
                str = 'charon direct',
                choices = {'fire', 'move'},
                variable = "DanteSwitchMode",
                setting = 1,
                load = function()
                    return revel.data.charonMode + 1
                end,
                store = function(var)
                    revel.data.charonMode = var - 1
                end
            },
            {
                str = 'auto charon',
                choices = {'face doorway', 'off'},
                variable = 'CharonAutoFace',
                setting = 1,
                load = function()
                    return revel.data.charonAutoFace
                end,
                store = function(var)
                    revel.data.charonAutoFace = var
                end
            },
			{
                str = 'old hub',
                choices = {'on', 'off'},
                variable = 'OldHubActive',
				tooltip = {strset = {'note:', '', 'might not', 'properly', 'take effect', 'until you', 'go to the', 'next floor'}},
                setting = 2,
                load = function()
					if not revel.data.oldHubActive then
						revel.data.oldHubActive = 2
					end
                    return revel.data.oldHubActive
                end,
                store = function(var)
                    revel.data.oldHubActive = var
					
					REVEL.SyncHub2IsActive()
                end
            },
            {
                str = 'shaders',
                choices = {'on', 'off'},
                variable = 'ShadersOnOff',
                setting = 1,
                load = function()
                    local areShadersOn = revel.data.shadersOn == 1
                    if areShadersOn then
                        return 1
                    else
                        return 2
                    end
                end,
                store = function(var)
                    if var == 1 then
                        revel.data.shadersOn = 1
                    else
                        revel.data.shadersOn = 0
                    end
                end
            },
            {
                str = 'particles',
                choices = {'on', 'reduced', 'off'},
                variable = 'CustomLightsOnRedOff',
                setting = 1,
                load = function()
                    local setting = revel.data.particlesOn
                    return 3 - setting
                end,
                store = function(var)
                    revel.data.particlesOn = 3 - var
                end
            },
            {
                str = 'glacier snow',
                choices = {'both', 'shader', 'overlay', 'off'},
                tooltip = {strset = {'\'shader\' should', 'be the fastest', 'options on', 'most machines'}},
                variable = 'GlacierSnow',
                setting = 2,
                load = function()
                    return revel.data.snowflakesMode
                end,
                store = function(var)
                    revel.data.snowflakesMode = var
                end
            },
            {
                str = 'custom lights',
                choices = {'on', 'reduced', 'off'},
                variable = 'CustomLightsOnRedOff',
                setting = 1,
                load = function()
                    local cLightsOn = revel.data.cLightSetting
                    if cLightsOn == 2 then
                        return 1
                    elseif cLightsOn == 1 then
                        return 2
                    else
                        return 3
                    end
                end,
                store = function(var)
                    if var == 1 then
                        revel.data.cLightSetting = 2
                    elseif var == 2 then
                        revel.data.cLightSetting = 1
                    else
                        revel.data.cLightSetting = 0
                    end
                end
            },
            {
                str = 'overlays',
                choices = {'on', 'no clouds', 'off'},
                variable = 'OverlaysMode',
                setting = 1,
                load = function()
                    return revel.data.overlaysMode
                end,
                store = function(var)
                    revel.data.overlaysMode = var
                end
            },
            {
                str = 'stalactite tells',
                choices = {'on', 'off'},
                variable = 'StalactiteTargets',
                setting = 1,
                load = function()
                    return revel.data.stalactiteTargetsOn
                end,
                store = function(var)
                    revel.data.stalactiteTargetsOn = var
                end
            },
            {
                str = 'glacier aurora',
                tooltip = {strset = {'at this time', 'of the year?', 'in this part of', 'the country?', 'localized', 'entirely', 'within your', 'basement?'}},
                choices = {'on', 'off'},
                variable = 'GlacierAurora',
                setting = 1,
                load = function()
                    if revel.data.auroraOn == 1 then
                        return 1
                    else
                        return 2
                    end
                end,
                store = function(var)
                    if var == 1 then
                        revel.data.auroraOn = 1
                    else
                        revel.data.auroraOn = 0
                    end
                end
            },
            {
                str = 'item weights',
                tooltip = {strset = {'dynamic:', 'unseen mod', 'items are', 'more common'}},
                choices = {'dynamic', 'vanilla'},
                variable = 'ItemWeights',
                setting = 0,
                load = function()
                    if revel.data.dynamicItemWeights == 1 then
                        return 1
                    else
                        return 2
                    end
                end,
                store = function(var)
                    if var == 1 then
                        revel.data.dynamicItemWeights = 1
                    else
                        revel.data.dynamicItemWeights = 0
                    end
                end
            },
            {
                str = 'clear cache mode',
                tooltip = {strset = {'isaac never', 'clears memory', 'we do it', 'manually to', 'avoid sprite', 'load errors'}},
                choices = {'off', 'every level', 'every room'},
                variable = 'clearCacheMode',
                setting = 2,
                load = function()
                    return revel.data.clearCacheMode + 1
                end,
                store = function(var)
                    revel.data.clearCacheMode = var - 1
                end
            },

            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton,

            {
                str = '',
                nosel = true,
            },
            {
                str = '',
                nosel = true,
            },
            {
                str = 'reset save data',
                tooltip = {strset = {'reset all', 'revelations', 'achievements', 'and unlocks'}},
                dest = 'resetsave',
            },
		},
        tooltip = dssmod.menuOpenToolTip
	},
    checklist = {
        title = 'to-do list',
        fsize = 2,
        buttons = {},
        generate = function(item)
            item.buttons = UnlockMenu.GenerateUnlockMenu(item)
        end,
        tooltip = dssmod.menuOpenToolTip
    },
    info = {
        title = 'revelations info',
        fsize = 2,
        nocursor = true,
        scroller = true,
        buttons = {
            {str = 'notice:'},
            {str = 'revelations requires', clr = 3},
            {str = 'custom stage api', clr = 3},
            {str = 'to run'},
            {str = ''},
            {str = 'revelations also'},
            {str = 'includes the'},
            {str = 'minimapapi mod as'},
            {str = 'of repentance,'},
            {str = 'enabling custom'},
            {str = 'map icons and'},
            {str = 'other minimap'},
            {str = 'features'},
            {str = ''},
            {str = 'you can find all these'},
            {str = 'in the revelations'},
            {str = 'workshop description'},
            {str = ''},
            {str = 'if this is your first'},
            {str = 'launch, you may need'},
            {str = 'to restart once to'},
            {str = 'prevent visual bugs'},
            {str = ''},
            {str = 'stay tuned for'},
            {str = 'chapter 3', clr = 3},
            {str = 'coming "eventually!"'},
            {str = ''},
            {str = 'follow us on twitter:'},
            {str = 'revelationsmod', clr = 3},
            {str = ''},
            {str = 'join us on discord:'},
            {str = 'discord.gg/isaac', clr = 3},
        },
        tooltip = dssmod.menuOpenToolTip
    },
    credits = {
        title = 'credits',
        fsize = 1,
        buttons = {
            {str = "team revelations", nosel = true}
        }
    },
    bosses = {
        title = 'boss hall',
        gridx = 3,
        nocursor = true,
        fsize = 1,
        buttons = {

        },
        generate = function(item, tbl)
            item.buttons = {}
            BossMenu.AddBossMenus(tbl.Directory, item, nil, nil, nil, "character", true, true)
            for _, seg in ipairs(REVEL.BossMenuSegments) do
                BossMenu.AddBossMenus(tbl.Directory, item, seg[1], seg[2], seg[3], seg[4], seg[5])
            end
        end,
        tooltip = {strset = {"come back", "when you've", "encountered", "some bosses!"}, fsize = 2}
    },
    resetsave = {
        title = 'are you sure?',
        buttons = {
            {
                str = 'no',
                tooltip = {strset = {'this will', 'reset all', 'revelations', 'achievements', 'and unlocks.', 'are you sure?'}},
                action = 'back',
            },
            {
                str = 'yes',
                tooltip = {strset = {'this will', 'reset all', 'revelations', 'achievements', 'and unlocks.', 'are you sure?'}},
                func = function() REVEL.ResetSaveData() end, --not yet defined
                action = 'back',
            },
        }
    }
}

if REVEL.Testmode then
    revdirectory.main.buttons[#revdirectory.main.buttons + 1] = {str = 'boss hall', dest = 'bosses'}
end

local revdirectorykey = {
	Item = revdirectory.main,
    Main = 'main',
	Idle = false,
	MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
	Path = {},
}

for _, credit in ipairs(Credits) do
    if type(credit) == "string" then
        revdirectory.credits.buttons[#revdirectory.credits.buttons + 1] = {str = credit, nosel = true}
    else
        for i, part in ipairs(credit) do
            if i ~= 1 then
                if i == 2 then
                    local button = {strpair = {{str = credit[1]}, {str = part}}}
                    if credit.tooltip then
                        if type(credit.tooltip) == "string" then
                            credit.tooltip = {credit.tooltip}
                        end
                        button.tooltip = {strset = credit.tooltip}
                    end
                    revdirectory.credits.buttons[#revdirectory.credits.buttons + 1] = button
                else
                    revdirectory.credits.buttons[#revdirectory.credits.buttons + 1] = {strpair = {{str = ''}, {str = part}}, nosel = true}
                end
            end
        end
    end
end

DeadSeaScrollsMenu.AddMenu("Revelations", {
    Run = dssmod.runMenu, 
    Open = dssmod.openMenu, 
    Close = dssmod.closeMenu, 
    Directory = revdirectory, 
    DirectoryKey = revdirectorykey, 
    MenuSprites = REVEL.MenuSprites
})

DeadSeaScrollsMenu.AddPalettes({
    {
        Name = "ice tray",
        {191, 221, 220},
        {19, 43, 75},
        {23, 26, 33},
    },
    {
        Name = "perilous",
        {142, 110, 74},
        {73, 48, 33},
        {244, 160, 69},
    }
})

if MinimapAPI then
    MinimapAPI:AddDSSMenu(REVEL.DSS.ModName, REVEL.DSS.DSSMod, MenuProvider)
end


Isaac.DebugString("Revelations: Loaded Rev DSS Menu!")
    
end