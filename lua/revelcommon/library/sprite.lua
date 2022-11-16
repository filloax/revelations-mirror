REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

function IsAnimOn(sprite, anmName)
    if not sprite then
        error("IsAnimOn: sprite nil", 2)
    elseif not anmName then
        error("IsAnimOn: anmName nil", 2)
    end
    return sprite:IsPlaying(anmName) or sprite:IsFinished(anmName)
end
    
-- Old SkipAnimFrames is still needed if OverlayFrames need to be skipped, 
-- or if the animation needs to get skipped more than it has frames
-- or if events are needed (as SetFrame skips them)
function REVEL.SkipAnimFrames(sprite, frame)
    -- playbackspeed version had some weirdness
    -- with AnimateWalkFrame (check with sasquatch)
    -- local speed = sprite.PlaybackSpeed
    -- sprite.PlaybackSpeed = frame - 1
    -- sprite:Update()
    -- sprite.PlaybackSpeed = speed
    for i = 1, frame do
        sprite:Update()
    end
end

function REVEL.IsOverlayOn(spr, anim)
    return spr:IsOverlayFinished(anim) or spr:IsOverlayPlaying(anim)
end

-- Get current animation sprite is playing (needs list of possible choices)
-- No longer needed with Repentance API, kepp as results were limited by list
-- unlike sprite:GetAnimation()
function REVEL.GetAnimation(sprite, ...)
    local arg = {...}
    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    return REVEL.includes(arg, sprite:GetAnimation())
end

function REVEL.GetAnimationOverlay(sprite, ...)
    local arg = {...}
    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    return REVEL.includes(arg, sprite:GetOverlayAnimation())
end
  
function REVEL.GetSpriteClamps(position, size, boundaryTL, boundaryBR)
    local tlCrop = boundaryTL - position
    local brCrop = (position + size) - boundaryBR
    local x, y
    if brCrop.X <= 0 then
        x = 0
    end

    if brCrop.Y <= 0 then
        y = 0
    end

    if x or y then
        brCrop = Vector(x or brCrop.X, y or brCrop.Y)
    end

    local x, y
    if tlCrop.X <= 0 then
        x = 0
    end

    if tlCrop.Y <= 0 then
        y = 0
    end

    if x or y then
        tlCrop = Vector(x or tlCrop.X, y or tlCrop.Y)
    end

    return tlCrop, brCrop
end

---@class WalkAnims
---@field Left string
---@field Horizontal string
---@field Right string
---@field Up string
---@field Vertical string
---@field Down string

---@param sprite string
---@param velocity Vector
---@param walkAnims WalkAnims
---@param flipWhenRight? boolean
---@param noFlip? boolean
---@param idleAnim? string
function REVEL.AnimateWalkFrame(sprite, velocity, walkAnims, flipWhenRight, noFlip, idleAnim)
    local frame, anim, flip = 0, nil, false

    for _, anim in pairs(walkAnims) do
        if sprite:IsPlaying(anim) then
            frame = sprite:GetFrame() + 1
        end
    end

    local x,y = velocity.X, velocity.Y
    if not idleAnim or math.abs(x) > 0.01 or math.abs(y) > 0.01 then
		if math.abs(x) > math.abs(y) then
			if x < 0 then
				if walkAnims.Left then
					anim = walkAnims.Left
				else
					anim = walkAnims.Horizontal
					if not flipWhenRight and not noFlip then
						flip = true
					end
				end
			else
				if walkAnims.Right then
					anim = walkAnims.Right
				else
					anim = walkAnims.Horizontal
					if flipWhenRight and not noFlip then
						flip = true
					end
				end
			end
		else
			if y < 0 then
				if walkAnims.Up then
					anim = walkAnims.Up
				else
					anim = walkAnims.Vertical
				end
			else
				if walkAnims.Down then
					anim = walkAnims.Down
				else
					anim = walkAnims.Vertical
				end
			end
		end

		sprite.FlipX = flip
		if not sprite:IsPlaying(anim) then
			sprite:Play(anim, true)
			if frame > 0 then
				REVEL.SkipAnimFrames(sprite, frame)
			end
		end
	else
		if (not sprite:IsFinished(idleAnim) or sprite:GetFrame() ~= 0) then
			sprite:SetFrame(idleAnim, 0)
		end
	end
end

function REVEL.AnimateWalkFrameSpeed(sprite, vel, walkAnims, flipWhenRight, noFlip, idleAnim, minSpd, maxSpd)
    local x,y = math.abs(vel.X), math.abs(vel.Y)
    if x > 0.01 or y > 0.01 then
        REVEL.AnimateWalkFrame(sprite, vel, walkAnims, flipWhenRight, noFlip)
        sprite.PlaybackSpeed = REVEL.Lerp(minSpd or 0.5, maxSpd or 1, math.min(1, vel:LengthSquared() / 4 ))
    else
        if idleAnim then
            sprite:Play(idleAnim, true)
            sprite.PlaybackSpeed = 1
        elseif sprite:GetFrame() == 0 then
            sprite.PlaybackSpeed = 0
        end
    end
end

function REVEL.AnimateWalkFrameOverlay(sprite, velocity, walkAnims, flipWhenRight, noFlip)
    local anim, flip = 0, nil

    local x, y = velocity.X, velocity.Y
    if math.abs(x) > math.abs(y) then
        if x < 0 then
            if walkAnims.Left then
                anim = walkAnims.Left
            else
                anim = walkAnims.Horizontal
                if not flipWhenRight and not noFlip then
                    flip = true
                end
            end
        else
            if walkAnims.Right then
                anim = walkAnims.Right
            else
                anim = walkAnims.Horizontal
                if flipWhenRight and not noFlip then
                    flip = true
                end
            end
        end
    else
        if y < 0 then
            if walkAnims.Up then
                anim = walkAnims.Up
            else
                anim = walkAnims.Vertical
            end
        else
            if walkAnims.Down then
                anim = walkAnims.Down
            else
                anim = walkAnims.Vertical
            end
        end
    end

    sprite.FlipX = flip
    if not sprite:IsOverlayPlaying(anim) then
        sprite:PlayOverlay(anim, true)
    end
end

function REVEL.AnimateWalkFrameOverlaySpeed(sprite, vel, walkAnims, flipWhenRight, noFlip, idleAnim, minSpd, maxSpd)
    local x,y = math.abs(vel.X), math.abs(vel.Y)
    if x > 0.01 or y > 0.01 then
        REVEL.AnimateWalkFrameOverlay(sprite, vel, walkAnims, flipWhenRight, noFlip)
        sprite.PlaybackSpeed = REVEL.Lerp(minSpd or 0.5, maxSpd or 1, math.min(1, vel:LengthSquared() / 4 ))
    else
        if idleAnim then
            sprite:PlayOverlay(idleAnim, true)
            sprite.PlaybackSpeed = 1
        elseif sprite:GetOverlayFrame() == 0 then
            sprite.PlaybackSpeed = 0
        end
    end
end

function REVEL.MultiFinishCheck(sprite, ...)
    local arg = {...}

    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    for _, anim in pairs(arg) do
        if type(anim) == "table" and REVEL.MultiFinishCheck(sprite, anim) or sprite:IsFinished(anim) then
            return true
        end
    end
    return false
end

function REVEL.MultiPlayingCheck(sprite, ...)
    local arg = {...}

    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    for _, anim in pairs(arg) do
        if type(anim) == "table" and REVEL.MultiPlayingCheck(sprite, anim) or sprite:IsPlaying(anim) then
            return true
        end
    end
    return false
end

function REVEL.MultiAnimOnCheck(sprite, ...)
    return REVEL.MultiFinishCheck(sprite, ...) or REVEL.MultiPlayingCheck(sprite, ...)
end

function REVEL.MultiOverlayFinishCheck(sprite, ...)
    local arg = {...}

    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    for _, anim in pairs(arg) do
        if type(anim) == "table" and REVEL.MultiOverlayFinishCheck(sprite, anim) or sprite:IsOverlayFinished(anim) then
            return true
        end
    end
    return false
end

function REVEL.MultiOverlayPlayingCheck(sprite, ...)
    local arg = {...}

    if type(arg[1]) == "table" then
        arg = arg[1]
    end

    for _, anim in pairs(arg) do
        if type(anim) == "table" and REVEL.MultiOverlayPlayingCheck(sprite, anim) or sprite:IsOverlayPlaying(anim) then
            return true
        end
    end
    return false
end

function REVEL.MultiOverlayAnimOnCheck(sprite, ...)
    return REVEL.MultiOverlayFinishCheck(sprite, ...) or REVEL.MultiOverlayPlayingCheck(sprite, ...)
end

local function AddSuffixToStringTable(strings, suffix)
    local out = {}
    for _, str in pairs(strings) do
        if type(str) == "table" then
            for _, str2 in pairs(str) do
                out[#out + 1] = str2 .. suffix
            end
        else
            out[#out + 1] = str .. suffix
        end
    end
    return out
end

function REVEL.MultiFinishCheckSuffix(sprite, anims, suffixes)
    if suffixes == "" or not suffixes then
        return REVEL.MultiFinishCheck(sprite, anims)
    end
    if type(suffixes) == "string" then suffixes = {suffixes} end
    for _, suffix in ipairs(suffixes) do
        if REVEL.MultiFinishCheck(sprite, AddSuffixToStringTable(anims, suffix)) then
            return true
        end
    end
    return false
end

function REVEL.MultiPlayingCheckSuffix(sprite, anims, suffixes)
    if suffixes == "" or not suffixes then
        return REVEL.MultiPlayingCheck(sprite, anims)
    end
    if type(suffixes) == "string" then suffixes = {suffixes} end
    for _, suffix in ipairs(suffixes) do
        if REVEL.MultiPlayingCheck(sprite, AddSuffixToStringTable(anims, suffix)) then
            return true
        end
    end
    return false
end

function REVEL.MultiAnimOnCheckSuffix(sprite, anims, suffixes)
    return REVEL.MultiFinishCheckSuffix(sprite, anims, suffixes) or REVEL.MultiPlayingCheckSuffix(sprite, anims, suffixes)
end

--[[
TO BE USED IN PLACE OF THINGS LIKE THIS

if sprite:IsFinished("Attack4") then
    data.State = "Idle"
elseif not sprite:IsPlaying("Attack4") then
    sprite:Play("Attack4", true)
else
    if sprite:IsEventTriggered("Grunt") then
    end
end

NOW

if REVEL.PlayUntilFinished(sprite, "Attack4") then
    if sprite:IsEventTriggered("Grunt") then
    end
else
    data.State = "Idle"
end

]]

function REVEL.PlayUntilFinished(sprite, anim)
    if sprite:IsFinished(anim) then
        return false
    else
        if not sprite:IsPlaying(anim) then
            sprite:Play(anim, true)
        end

        return true
    end
end

function REVEL.PlayIfNot(sprite, anim, force)
    if force == nil then force = true end
    if not sprite:IsPlaying(anim) then
        sprite:Play(anim, force)
    end
end

function REVEL.DrawRotatedTilingSprite(sprite, pos1, pos2, tileLength, cutStart, cutEnd)
    local diff = pos2 - pos1
    local length = diff:Length()
    local angle = diff:GetAngleDegrees()
    local norm = diff / length

    if cutStart then
        pos1 = pos1 + norm * cutStart
        length = length - cutStart
    end

    if cutEnd then
        length = length - cutEnd
    end

    sprite.Rotation = angle

    local numRenders = math.ceil(length / tileLength)
    local remainingLength = length % tileLength
    local addVector = Vector(tileLength, 0):Rotated(angle)

    for i = 0, numRenders - 1 do
        local rpos = pos1 + addVector * i
        local bottomrightclamp = Vector.Zero
        if i == numRenders - 1 and remainingLength > 0 then
            bottomrightclamp = Vector(tileLength - remainingLength, 0)
        end

        sprite:Render(rpos, Vector.Zero, bottomrightclamp)
    end
end

function REVEL.DrawRotatedTilingCapSprites(sprite, pos1, pos2, offset, startEndOnly)
    local diff = pos2 - pos1
    local length = diff:Length()
    local angle = diff:GetAngleDegrees()
    local norm = diff / length

    if startEndOnly == false or startEndOnly == nil then
        sprite.Rotation = angle
        sprite:Render(pos1 + norm * offset, Vector.Zero, Vector.Zero)
    end

    if startEndOnly == true or startEndOnly == nil then
        sprite.Rotation = angle + 180
        sprite:Render(pos2 - norm * offset, Vector.Zero, Vector.Zero)
    end
end

function REVEL.GetAnimLength(sprite)
    local frame = sprite:GetFrame()

    sprite:SetLastFrame()
    local out = sprite:GetFrame()
    sprite:SetFrame(frame)
    
    return out
end

-- Replace champion spritesheet, credits: gwahavel

local SpritesheetlessChamps = {
    [ChampionColor.FLICKER] = true,
    [ChampionColor.CAMO] = true,
    [ChampionColor.TINY] = true,
    [ChampionColor.GIANT] = true,
    [ChampionColor.SIZE_PULSE] = true,
    [ChampionColor.KING] = true,
}

---Replace spritesheets while working with champion sheets
---@param npc any
---@param filepath string
---@param layer integer
---@param loadGraphics? boolean
function REVEL.ReplaceEnemySpritesheet(npc, filepath, layer, loadGraphics) --Leave the ".png" OUT!!!
    layer = layer or 0
    loadGraphics = loadGraphics or true
    npc = npc:ToNPC()
    local sprite = npc:GetSprite()
    if npc:IsChampion() and not SpritesheetlessChamps[npc:GetChampionColorIdx()] then
        filepath = filepath .. "_champion"
    end
    filepath = filepath .. ".png"
    sprite:ReplaceSpritesheet(layer, filepath)
    if loadGraphics then
        sprite:LoadGraphics()
    end
end

end