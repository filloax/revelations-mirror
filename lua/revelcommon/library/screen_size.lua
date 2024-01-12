return function()

function REVEL.GetScreenCenterPosition()
    return Vector(Isaac.GetScreenWidth()  / 2, Isaac.GetScreenHeight() / 2)
end

function REVEL.GetBottomRightNoOffset()
    return Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
end

function REVEL.GetBottomLeftNoOffset()
    return Vector(0, REVEL.GetBottomRightNoOffset().Y)
end

function REVEL.GetTopRightNoOffset()
    return Vector(REVEL.GetBottomRightNoOffset().X, 0)
end

function REVEL.GetTopLeftNoOffset()
    return Vector.Zero
end

function REVEL.GetHUDOffset()
    return Options.HUDOffset
end

local HudOffsetMult = Vector(20, 12)

---@return Vector
function REVEL.GetScreenBottomRight()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = -HudOffsetMult * offset

    return REVEL.GetBottomRightNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenBottomLeft()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * Vector(1, -1) * offset

    return REVEL.GetBottomLeftNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenTopRight()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * Vector(-1, 1) * offset

    return REVEL.GetTopRightNoOffset() + hudOffset
end

---@return Vector
function REVEL.GetScreenTopLeft()
    local offset = REVEL.GetHUDOffset()
    local hudOffset = HudOffsetMult * offset

    return REVEL.GetTopLeftNoOffset() + hudOffset
end

function REVEL.NormScreenVector(v) --normalize render position vector based on screensize, so that 0;0 is top left, 1;1 is bottom right
    local screenSize = REVEL.GetScreenCenterPosition()*2
    return Vector(v.X / screenSize.X, v.Y / screenSize.Y)
end
  
function REVEL.NormScreenVectorX(v) --normalize render position vector based on screensize X, so that 0 is left and 1 is right, while top is 0 and bottom is height/width (useful for things where you want the same measure unit on x and y)
    local screenSize = REVEL.GetScreenCenterPosition()*2
    return Vector(v.X / screenSize.X, v.Y / screenSize.X)
end

function REVEL.GetScreenCenterPositionWorld() --credits to alphaapi
    --TODO: make it properly work in non-square rooms
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
    return pos
end

function REVEL.GetScreenTopLeftWorld()
    return Isaac.ScreenToWorld(REVEL.GetTopLeftNoOffset())
end

--Isaac,ScreenToWorld currently works _very_ weirdly (likely a bug) and only transforms coords properly in (0,0) (aka, the only vector that properly gets transformed is that one)
--So, top left screen corner works, bottom right will have to make do without it
--This right now only works in normal rooms
function REVEL.GetScreenBottomRightWorld()
    local TL = REVEL.GetScreenTopLeftWorld()
    return TL + (REVEL.GetScreenCenterPositionWorld() - TL) * 2
end

--return TL, BR
function REVEL.GetScreenCornersWorld()
    return REVEL.GetScreenTopLeftWorld(), REVEL.GetScreenBottomRightWorld()
end

function REVEL.IsPositionInScreen(pos)
    return REVEL.IsPositionInRect(pos, REVEL.GetScreenCornersWorld())
end

end