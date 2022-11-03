REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
--[[
	A Huge Thanks to dedChar of the Agony of Isaac Team for making the Dynamic Note Items
	https://github.com/AgonyTeam/DynamicNoteItems
]]

DNI = RegisterMod("Dynamic Note Items", 1)

DNI.LAST_VANILLA_ID = 552 --need a way to get this dynamically
--PauseMenu
DNI.Appeared = false
DNI.PauseMenu = false
DNI.Paused = false
DNI.MenuItems = {
	OPTIONS = 1,
	RESUME = 2,
	EXIT = 3
}
DNI.MenuItem = DNI.MenuItems.RESUME
--[[
DNI.POS_ITEMS_PAUSE = Vector(253, 117) --position of first item
DNI.POS_MY_LIST = Vector(290,135) --item list position
]]

DNI.POS_MY_LIST = Vector(48,0) --item list position
DNI.FIRST_ITEM_OFFSET = Vector(-36, -15) --position of first item

local game = Game()
local function GetScreenCenter()
    local room = Game():GetRoom()
    local shape = room:GetRoomShape()
    local centerOffset = (room:GetCenterPos()) - room:GetTopLeftPos()
    local pos = room:GetCenterPos()
    if centerOffset.X > 260 then
        pos.X = pos.X - 260
    end
    if shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LTL then
        pos.X = pos.X - 260
    end
    if centerOffset.Y > 140 then
        pos.Y = pos.Y - 140
    end
    if shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LTL then
        pos.Y = pos.Y - 140
    end
    return Isaac.WorldToRenderPosition(pos, false)
end

local defaultScale = Vector(480, 270)
local function GetRelativeScreenScale()
	local bottomRight = GetScreenCenter() * 2
	return Vector(bottomRight.X / defaultScale.X, bottomRight.Y / defaultScale.Y)
end

local function GetListRenderCoords()
	local scale = GetRelativeScreenScale()
	return GetScreenCenter() + Vector(DNI.POS_MY_LIST.X * scale.X, DNI.POS_MY_LIST.Y * scale.Y)
end

local function GetFirstItemRenderCoords()
	return GetListRenderCoords() + DNI.FIRST_ITEM_OFFSET
end

--DeathCard

--Renderqueue
local toRender = {
	HUD = Sprite()
}
toRender.HUD:Load("gfx/ui/pausescreen_mystuff.anm2", true) --init hud sprite

function DNI:getCurrentItems() --returns the items the player has
	--[[
	local itemCfg = Isaac.GetItemConfig()
	local numCol = #(itemCfg:GetCollectibles())
	if type(numCol) ~= "number" then
		numCol = 9999 --Mac seems to have trouble with this number thing
	end

	local currList = {}
	local player = Isaac.GetPlayer(0)
	for id = 1, numCol do
		if itemCfg:GetCollectible(id) ~= nil and player:HasCollectible(id) then
			table.insert(currList, id)
		end
	end
	return currList
	]]
	
	local currList = {}
	local player = Isaac.GetPlayer(0)
	if revel and revel.data and revel.data.run.itemHistory[1] then
		for index, itemID in pairs(revel.data.run.itemHistory[1]) do
			if player:HasCollectible(itemID) then
				table.insert(currList, itemID)
			end
		end
	end
	return currList
end

function DNI:getFilename(id) --returns gfx filename without path
	local origGfx = Isaac.GetItemConfig():GetCollectible(id).GfxFileName
	if string.find(origGfx, "gfx/items/collectibles/") then
		local origGfxRootStart, origGfxRootEnd = string.find(origGfx, "gfx/items/collectibles/")
		return string.sub(origGfx, origGfxRootEnd, string.len(origGfx))
	else
		return origGfx:match(".*/(.-).png") .. ".png"
	end
end

function DNI:addNote(id) --adds a note for an item
	local sprite = Sprite()
	if id > DNI.LAST_VANILLA_ID then
		sprite:Load("gfx/ui/dynamicnotes.anm2", false)
		sprite:ReplaceSpritesheet(0, "gfx/ui/deathnotes/" .. DNI:getFilename(id))
		sprite:LoadGraphics()
	else
		sprite:Load("gfx/ui/death screen.anm2", false)
		sprite:ReplaceSpritesheet(6, "gfx/ui/death items.png")
		sprite:LoadGraphics()
	end
	table.insert(toRender, {sprite, id})
end

local indexOffset = 0
function DNI:calcPauseItemPosition(index)
	local indexPos = index - indexOffset
	local itemStartPos = GetFirstItemRenderCoords()
	if toRender[index][2] > DNI.LAST_VANILLA_ID then
		return Vector(itemStartPos.X + math.floor((indexPos-1)/4)*15 + math.floor((indexPos-1)/4), itemStartPos.Y + ((indexPos-1)%4)*15 + ((indexPos-1)%4))
	else
		return Vector(itemStartPos.X - 88 + math.floor((indexPos-1)/4)*15 + math.floor((indexPos-1)/4), itemStartPos.Y + 6 + ((indexPos-1)%4)*15 + ((indexPos-1)%4))
	end
end

local leftArrowVisible = true
local rightArrowVisible = true
function DNI:renderPause() --renders the pause menu list

	if Game():IsPaused() and DNI.PausePressed then
		DNI.PausePressed = false
		DNI.Paused = true
	end

	if DNI.Paused then
		if DNI.PauseMenu then --if in main pause menu
			if Input.IsActionTriggered(ButtonAction.ACTION_MENUUP, REVEL.player.ControllerIndex) then --track cursor movement
				if DNI.MenuItem > DNI.MenuItems.OPTIONS then
					DNI.MenuItem = DNI.MenuItem - 1
				else
					DNI.MenuItem = DNI.MenuItems.EXIT
				end
			elseif Input.IsActionTriggered(ButtonAction.ACTION_MENUDOWN, REVEL.player.ControllerIndex) then
				if DNI.MenuItem < DNI.MenuItems.EXIT then
					DNI.MenuItem = DNI.MenuItem + 1
				else
					DNI.MenuItem = DNI.MenuItems.OPTIONS
				end
			elseif Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, REVEL.player.ControllerIndex) then
				if indexOffset >= 4 then
					indexOffset = indexOffset - 4
				end
			elseif Input.IsActionTriggered(ButtonAction.ACTION_MENURIGHT, REVEL.player.ControllerIndex) then
				if indexOffset < #DNI:getCurrentItems()-24 then
					indexOffset = indexOffset + 4
				end
			elseif Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, REVEL.player.ControllerIndex) then --track enter press, if selected menu is options, make hud invisible
				if DNI.MenuItem == DNI.MenuItems.RESUME then
					toRender.HUD:Play("Dissapear")
				elseif DNI.MenuItem == DNI.MenuItems.OPTIONS then
					toRender.HUD.Color = Color(1,1,1,0,0,0,0)
					DNI.PauseMenu = false
				end
			elseif Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, REVEL.player.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_PAUSE, REVEL.player.ControllerIndex) then --if game is resumed not by pressing enter, make the hud disappear
				toRender.HUD:Play("Dissapear")
			end
		elseif not DNI.PauseMenu and DNI.MenuItem == DNI.MenuItems.RESUME then --reset PauseMenu bool
			DNI.PauseMenu = true
		else --if not in pausemenu
			if Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, REVEL.player.ControllerIndex) then --when reentering pausemenu, make it visible
				DNI.PauseMenu = true
				toRender.HUD.Color = Color(1,1,1,1,0,0,0)
			end
		end
		if not DNI.Appeared and not toRender.HUD:IsPlaying("Dissapear") then
			for _,item in pairs(DNI:getCurrentItems()) do
				DNI:addNote(item) --add all notesprites to the toRender table
			end
			toRender.HUD:Play("Appear")
			DNI.Appeared = true
		elseif toRender.HUD:IsFinished("Appear") and not toRender.HUD:IsPlaying("Dissapear") then
			toRender.HUD:Play("Idle")
		elseif toRender.HUD:IsFinished("Dissapear") then
			DNI.Paused = false
		end
		toRender.HUD:Render(GetListRenderCoords(), Vector(0,0), Vector(0,0))
		toRender.HUD:Update()
		
		local leftArrowShouldBeVisible = false
		local rightArrowShouldBeVisible = false
		for index, spriteTbl in pairs(toRender) do --render note sprites
			if index ~= "HUD" then
				local sprite = spriteTbl[1]
				local id = spriteTbl[2]
				
				if index > indexOffset then
					--play the same anims and color as hud
					if sprite:GetDefaultAnimationName() ~= "Diary" then
						if toRender.HUD:IsPlaying("Appear") and not sprite:IsPlaying("Appear") then
							sprite:Play("Appear")
						elseif toRender.HUD:IsPlaying("Idle") and not sprite:IsPlaying("Idle") then
							sprite:Play("Idle")
						elseif toRender.HUD:IsPlaying("Dissapear") and not sprite:IsPlaying("Disappear") then
							sprite:Play("Disappear")
						end
						sprite.Color = toRender.HUD.Color
					else
						--vanilla items only have one animation, so they need to be handled differently
						if toRender.HUD:IsPlaying("Idle") or (toRender.HUD:IsPlaying("Appear") and toRender.HUD:GetFrame() >= 10) then
							sprite:SetFrame("Diary", id-1)
						elseif toRender.HUD:IsPlaying("Dissapear") then
							toRender[index] = nil
						end
						if not toRender.HUD:IsPlaying("Dissapear") then
							sprite.Color = toRender.HUD.Color
						end
					end
					if toRender[index] ~= nil then
						if index <= indexOffset+24 then
							if sprite:GetDefaultAnimation() ~= "Diary" then
								sprite:RenderLayer(0, DNI:calcPauseItemPosition(index))
							else
								sprite:RenderLayer(6, DNI:calcPauseItemPosition(index))
							end
						else
							rightArrowShouldBeVisible = true
						end
					end
				else
					leftArrowShouldBeVisible = true
				end
				sprite:Update()
			end
		end
		
		if leftArrowShouldBeVisible and not leftArrowVisible then
			leftArrowVisible = true
			toRender.HUD:ReplaceSpritesheet(2, "gfx/ui/pausescreen.png")
			toRender.HUD:LoadGraphics()
		end
		if not leftArrowShouldBeVisible and leftArrowVisible then
			leftArrowVisible = false
			toRender.HUD:ReplaceSpritesheet(2, "gfx/ui/none.png")
			toRender.HUD:LoadGraphics()
		end
		if rightArrowShouldBeVisible and not rightArrowVisible then
			rightArrowVisible = true
			toRender.HUD:ReplaceSpritesheet(3, "gfx/ui/pausescreen.png")
			toRender.HUD:LoadGraphics()
		end
		if not rightArrowShouldBeVisible and rightArrowVisible then
			rightArrowVisible = false
			toRender.HUD:ReplaceSpritesheet(3, "gfx/ui/none.png")
			toRender.HUD:LoadGraphics()
		end
		
	else --reset vars and clear table
		DNI.MenuItem = DNI.MenuItems.RESUME
		DNI.Appeared = false
		DNI.PauseMenu = false
		local tmpHUD = toRender.HUD
		toRender = {HUD = tmpHUD}
		indexOffset = 0
	end
end

function DNI:triggerPauseMenu(ent, inHook, btnAction) --for better pause detection
	if ent == nil and inHook == 0 and btnAction == 16 and not Game():IsPaused() and (Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, REVEL.player.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_PAUSE, REVEL.player.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK, REVEL.player.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_PAUSE, REVEL.player.ControllerIndex)) then
		DNI.PausePressed = true
		-- if the game is paused, the only input the game (besides menu navigation) listens to is if you're holding R to restart the run
		-- this in combination with the IsActionTriggered functions is used to make sure that the menu only loads when pressing one of the two pause buttons.
		-- originally I used Game():IsPaused(), but that appears to also trigger in many other scenarios like:
			--While a GiantBook animation is playing
			--In the Console
			--Between rooms
	end
end

function DNI:reset() --resets vars
	if Game():GetFrameCount() <= 1 or not Game():IsPaused() then
		DNI.Appeared = false
		DNI.PauseMenu = false
		DNI.Paused = false
		DNI.PausePressed = false
		DNI.MenuItem = DNI.MenuItems.RESUME
		indexOffset = 0
	end
end

DNI:AddCallback(ModCallbacks.MC_POST_UPDATE, DNI.reset)
DNI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DNI.reset)
DNI:AddCallback(ModCallbacks.MC_INPUT_ACTION, DNI.triggerPauseMenu)
DNI:AddCallback(ModCallbacks.MC_POST_RENDER, DNI.renderPause)

Isaac.DebugString("Revelations: Loaded DynamicNoteItems!")
end
REVEL.PcallWorkaroundBreakFunction()