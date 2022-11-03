REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
----------------
-- 3D VECTORS --
----------------
--[[
3D vectors. Can do operations with them like normal vectors,
including == to check if a vectors' coordinate are the same to another vector,
and create them either with
    Vec3(x,y,z) -> returns a 3d vector (x,y,z)
or
    Vec3(xyz) -> returns a 3d vector(xyz, xyz, xyz)
or
    Vec3(x, yz) or Vec3(xy, z) where xy or yz are vanilla 2d vectors

They can be indexed like so (where vec is a 3d vector):
    vec[1] or vec.X returns vec's X coordinate
    vec[2] or vec.Y returns vec's Y coordinate
    vec[3] or vec.Z returns vec's Z coordinate
    vec.XY returns a vanilla 2d vector Vector(X, Y) using the 3d vector's x and y
    You can also use other combinations to create 2d vectors, like vec.XZ, vec.YY, etc.

DOT, CROSS, ANGLE FUNCTIONS ARE NYI

Multiplication also works with other vectors:
    local vec = Vec3(1,2,3)
    vec * 2; --returns (2,4,6)
    vec * Vec3(3,2,4) --returns (1*3=3, 2*2=4, 3*4 = 12)
Avaiable functions are all the vanilla vector ones (cpu-heavy math operations will be slower than the vanilla C++ counterpart):
    :Clamp() and Clamped() also have an additional minZ and maxZ
    :Dot() returns vector dot product
    :Cross(second) just returns another vector, as per normal vector cross multiplication
    :Normalized(), :Resized(), return length as their 2nd arg; :Normalize(), :Resize() as their first
    :GetAngleDegrees(axis), gets the angle from the corresponding axis (can be "X","Y","Z" or 1,2,3)
    :AngleBetweenDegrees(second) gets the angle from another vector
    :RotateDegrees(axis, angle) rotates the vector around the axis (can be "X","Y","Z" or 1,2,3) with the angle
    :RotatedDegrees(axis, angle) returns the vector rotated around the axis (can be "X","Y","Z" or 1,2,3) with the angle
    :Rotate(axis, angle) as above but with radians
    :Rotated(axis, angle) as above but with radians
Other functions are
    :Clone() returns another object with the same coords
]]

---@class Vec3
---@field X number
---@field Y number
---@field Z number
local _Vec3Meta = {0,0,0}

---@type fun(X: number, Y: number, Z: number): Vec3
---@overload fun(X: number, YZ: Vector): Vec3
---@overload fun(XY: Vector, Z: number): Vec3
---@overload fun(XYZ: number): Vec3
function _Vec3Meta:New(...)
    local args = {...}
    local new = {}
    if #args == 1 then
        new[1],new[2],new[3] = args[1], args[1], args[1]
    elseif #args == 2 then
        if type(args[1]) == 'number' then
            if args[2].X then
                new[1] = args[1]
                new[2], new[3] = args[2].X, args[2].Y
            else
                error("Wrong argument type in Vec3() constructor!", 2)
            end
        elseif type(args[2]) == 'number' then
            if args[1].X then
                new[1], new[2] = args[1].X, args[1].Y
                new[3] = args[2]
            else
                error("Wrong argument type in Vec3() constructor!", 2)
            end
        else
            error("Wrong argument amount in Vec3() constructor!", 2)
        end
    elseif #args == 3 then
        for i,v in ipairs(args) do
            new[i] = v
        end
    else
        error("Wrong argument amount in Vec3() constructor!", 2)
    end

    if new[1] == nil then
        error("New Vec3 X is nil!", 2)
    end
    if new[2] == nil then
        error("New Vec3 Y is nil!", 2)
    end
    if new[3] == nil then
        error("New Vec3 Z is nil!", 2)
    end

    new = setmetatable(new, self)
    return new
end

---@type fun(X: number, Y: number, Z: number): Vec3
---@overload fun(X: number, YZ: Vector): Vec3
---@overload fun(XY: Vector, Z: number): Vec3
---@overload fun(XYZ: number): Vec3
function _G.Vec3(...)
    return _Vec3Meta:New(...)
end

local KeyToIndex = {X = 1, Y = 2, Z = 3}
function _Vec3Meta:__index(k)
    if KeyToIndex[k] then return rawget(self, KeyToIndex[k]) end
    k = tostring(k)
    local ax1, ax2 = k:sub(1,1), k:sub(2,2)
    --XY, YZ, XZ, etc splicing
    if ax1 and ax2 and KeyToIndex[ax1] and KeyToIndex[ax2] then
        return Vector(self[KeyToIndex[ax1]], self[KeyToIndex[ax2]])
    end

    return rawget(_Vec3Meta, k)
end

function _Vec3Meta:__newindex(k, v)
    -- REVEL.DebugToConsole(k, KeyToIndex[k], v)
    if KeyToIndex[k] then
        rawset(self, KeyToIndex[k], v)
    end
    k = tostring(k)
    local ax1, ax2 = k:sub(1,1), k:sub(2,2)
    --XY, YZ, XZ, etc splicing
    if ax1 and ax2 and KeyToIndex[ax1] and KeyToIndex[ax2] and v.X then
        self[KeyToIndex[ax1]] = v.X
        self[KeyToIndex[ax2]] = v.Y
    end
end

function _Vec3Meta:Clone()
    return _Vec3Meta:New(self[1], self[2], self[3])
end

function _Vec3Meta.__eq(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

local function toTwoDigits(x)
    return math.floor(x * 100) / 100
end

function _Vec3Meta:__tostring()
    return "(" .. toTwoDigits(self[1]) .. ", " 
        .. toTwoDigits(self[2]) .. ", " 
        .. toTwoDigits(self[3]) .. ")"
end

function _Vec3Meta.__add(a, b)
    if not a or not b then
        error("Trying to add nil Vec3s", 2)
    end
    return _Vec3Meta:New(a[1] + b[1], a[2] + b[2], a[3] + b[3])
end

function _Vec3Meta:__unm()
    return _Vec3Meta:New(-self[1], -self[2], -self[3])
end

function _Vec3Meta.__sub(a, b)
    if not a or not b then
        error("Trying to subtract nil Vec3s", 2)
    end
    return a + (-b)
end

function _Vec3Meta.__mul(a, b)
    if not a or not b then
        error("Trying to multiply nil Vec3s", 2)
    end
    if type(a) == "number" then
        return _Vec3Meta:New(a * b[1], a * b[2], a * b[3])
    elseif type(b) == "number" then
        return _Vec3Meta:New(a[1] * b, a[2] * b, a[3] * b)
    else --both vectors or something else, but you shouldn't multiply vectors by random objects
        return _Vec3Meta:New(a[1] * b[1], a[2] * b[2], a[3] * b[3])
    end
end

function _Vec3Meta.__div(a, b)
    if type(a) == "number" then
        error("Dividing number by vec3!", 2)
    elseif type(b) == "number" then
        return _Vec3Meta:New(a[1] / b, a[2] / b, a[3] / b)
    else --both vectors or something else, but you shouldn't multiply vectors by random objects
        return _Vec3Meta:New(a[1] / b[1], a[2] / b[2], a[3] / b[3])
    end
end

function _Vec3Meta:LengthSquared()
    return self[1]*self[1] + self[2]*self[2] + self[3]*self[3]
end

function _Vec3Meta:Length()
    return math.sqrt(self:LengthSquared())
end

function _Vec3Meta:DistanceSquared(second)
    return (second - self):LengthSquared()
end

function _Vec3Meta:Distance(second)
    return math.sqrt(self:DistanceSquared(second))
end

function _Vec3Meta:Normalize()
    local l = self:Length()
    for i=1, 3 do
        self[i] = self[i]/l
    end
    return l
end

function _Vec3Meta:Normalized()
    local norm = self:Clone()
    local l = norm:Normalize()
    return norm, l
end

function _Vec3Meta:Resize(newlen)
    local l = self:Length()
    for i=1, 3 do
        self[i] = self[i] * (newlen/l)
    end
    return l
end

function _Vec3Meta:Resized(newlen)
    local res = self:Clone()
    local l = res:Resize(newlen)
    return res, l
end

function _Vec3Meta:Clamp(minx, maxx, miny, maxy, minz, maxz)
    self[1] = REVEL.Clamp(self[1], minx, maxx)
    self[2] = REVEL.Clamp(self[2], miny, maxy)
    self[3] = REVEL.Clamp(self[3], minz, maxz)
end

function _Vec3Meta:Clamped(minx, maxx, miny, maxy, minz, maxz)
    local c = self:Clone()
    c:Clamp(minx, maxx, miny, maxy, minz, maxz)
    return c
end

function _Vec3Meta:Dot(second)
    local out = 0
    for i=1, 3 do
        out = out + self[i] * second[i]
    end
    return out
end

function _Vec3Meta:Cross(second)
    return _Vec3Meta:New(self[2]*second[3] - self[3]*second[2], self[3]*second[1] - self[1]*second[3], self[1]*second[2] - self[2]*second[1])
end

function _Vec3Meta:AngleBetweenDegrees(second)
    local cos = self:Dot(second) / math.sqrt(self:LengthSquared() * second:LengthSquared())
    return math.acos(cos)
end

--Can be called with either 1,2,3 or 'X','Y','Z'
local axisToRemainingAxii = {"YZ","XZ","XY"}
function _Vec3Meta:GetAngleDegrees(axis)
    if KeyToIndex[axis] then axis = KeyToIndex[axis] end
    local component2d = self[axisToRemainingAxii[axis]]
    return component2d:GetAngleDegrees()
end

local function mat3MultWithVec3(A, v) --multiply a 3x3 matrix by a vec3 (returns vec3)
    local out = _Vec3Meta:New(0,0,0)
    for i=1, 3 do
        for j=1, 3 do
            out[i] = out[i] + A[i][j] * v[j]
        end
    end
    return out
end

local angleCache = 0
local cosCache = math.cos(angleCache)
local sinCache = math.sin(angleCache)
local rotMat = {{1,0,0},{0,1,0},{0,0,1}} --to save memory, just edit these instead of making a new table each time
local degToRad = math.pi/180

-- local
function _Vec3Meta:Rotated(axis, angle)
    if KeyToIndex[axis] then axis = KeyToIndex[axis] end
    local cos, sin = cosCache, sinCache

    if angleCache ~= angle then
        angleCache = angle
        cos = math.cos(angle)
        sin = math.sin(angle)
        cosCache = cos
        sinCache = sin
    end
    if axis == 1 then --http://mathworld.wolfram.com/RotationMatrix.html if you have no idea what this is
        rotMat[1][1] = 1        rotMat[1][2] = 0        rotMat[1][3] = 0
        rotMat[2][1] = 0        rotMat[2][2] = cos    rotMat[2][3] = sin
        rotMat[3][1] = 0        rotMat[3][2] = -sin rotMat[3][3] = cos
    elseif axis == 2 then
        rotMat[1][1] = cos    rotMat[1][2] = 0    rotMat[1][3] = -sin
        rotMat[2][1] = 0        rotMat[2][2] = 1    rotMat[2][3] = 0
        rotMat[3][1] = sin    rotMat[3][2] = 0    rotMat[3][3] = cos
    elseif axis == 3 then
        rotMat[1][1] = cos    rotMat[1][2] = sin    rotMat[1][3] = 0
        rotMat[2][1] = -sin rotMat[2][2] = cos    rotMat[2][3] = 0
        rotMat[3][1] = 0        rotMat[3][2] = 0        rotMat[3][3] = 1
    end

    return mat3MultWithVec3(rotMat, self)
end

function _Vec3Meta:Rotate(axis, angle)
    local res = self:Rotated(axis, angle)
    for i=1, 3 do
        self[i] = res[i]
    end
end

function _Vec3Meta:RotateDegrees(axis, angle)
    return self:Rotate(axis, angle * degToRad)
end

function _Vec3Meta:RotatedDegrees(axis, angle)
    return self:Rotated(axis, angle * degToRad)
end

function RandomVec3()
    local angle2Cos = 1 - 2 * math.random()
    local angle2Sin = math.sqrt(1 - angle2Cos * angle2Cos)
    local out = _Vec3Meta:New(RandomVector(), angle2Cos)
    out.X = out.X * angle2Sin
    out.Y = out.Y * angle2Sin

    return out
end

function REVEL.IsVec3(x)
    return type(x) == 'table' and getmetatable(x) == _Vec3Meta
end

REVEL.VEC3_X = _Vec3Meta:New(1,0,0)
REVEL.VEC3_Y = _Vec3Meta:New(0,1,0)
REVEL.VEC3_Z = _Vec3Meta:New(0,0,1)
REVEL.VEC3_ZERO = _Vec3Meta:New(0)
REVEL.VEC3_ONE = _Vec3Meta:New(1)

end

REVEL.PcallWorkaroundBreakFunction()