-- Different loading as these definitions need to already be there when the mod starts loading

local GetFolderName = require("revfoldername")

function REVEL.tlen(t)
    local c = 0
    for k,_ in pairs(t) do c = c+1 end
    return c
end

--Made by filloax for both genesis and revelations, and his mods, this aint plagiarizing
--Returns a clone of source when called with no second arg, or a clone of source with, for fields not in source, the target's fields
---@generic T : table
---@param source T
---@param target? T
---@return T
function REVEL.CopyTable(source,target)
    if not source then
        error("REVEL.CopyTable | source nil!", 2)
    end

    local output = {}

    if not target --This needs to be done, to prevent errors when using a nil as a table
    or type(target) ~= "table" 
    then
        for k,v in pairs(source) do --For every variable in target (not in source as it might not have variables added in a new version)
            -- REVEL.DebugToString({"1In:", k, type(v), v})
            if type(source[k]) == "table" then --If the value of the variable is also a table, we need to do this again. (Actually, I'm not sure, but to be safe, do this)
                output[k] = REVEL.CopyTable(v)
            else
                output[k] = v --If the value of k isn't a table, just copy it over to the output.
            end
            -- REVEL.DebugToString({"1Out:", k, type(output[k]), output[k]})
        end
    else
        -- First copy form source, to cover variables not in target
        for k,v in pairs(source) do
            if type(source[k]) == "table" then
                output[k] = REVEL.CopyTable(
                    source[k],  
                    type(target[k]) == "table" and target[k]
                )
            else
                output[k] = v
            end
        end

        for k,v in pairs(target) do --For every variable in target (not in source as it might not have variables added in a new version)
            if source[k] == nil or type(source[k]) ~= type(target[k]) then --If the source contains the variable and is up to date
                if type(target[k]) == "table" then --If the value of the variable is also a table, we need to do this again. (Actually, I'm not sure, but to be safe, do this)
                    output[k] = REVEL.CopyTable({},target[k])
                else
                    output[k] = target[k] --If the value of k isn't a table, just copy it over to the output.
                end
            end
        end
    end

    return output
end

if REVEL.DEBUG then
    -- test copy tables as it already broke a bunch of times
    -- in the dev cycle, make sure it doesn't

    local res = REVEL.CopyTable({a = 1, b = 3, c = 5}, {a = 2, d = 6})
    assert(res.a == 1, "value is " .. tostring(res.a))
    assert(res.b == 3, "value is " .. tostring(res.b))
    assert(res.c == 5, "value is " .. tostring(res.c))
    assert(res.d == 6, "value is " .. tostring(res.d))

    local resSingle = REVEL.CopyTable({b = 2, c = 3})
    assert(resSingle.a == nil, "value is " .. tostring(resSingle.a))
    assert(resSingle.b == 2, "value is " .. tostring(resSingle.b))
    assert(resSingle.c == 3, "value is " .. tostring(resSingle.c))
end

-- Returns a new table with fields from both tables. 
-- For fields included in both, returns the one in primary
function REVEL.MergeTables(primary, secondary)
    if not secondary then
        return REVEL.CopyTable(primary)
    end

    local output = {}

    for k, primaryVal in pairs(primary) do
        local secondaryVal = secondary[k]

        if type(primaryVal) ~= "table" then
            output[k] = primaryVal
        elseif not secondaryVal or type(secondaryVal) ~= "table" then
            output[k] = REVEL.CopyTable(primaryVal)
        else
            output[k] = REVEL.MergeTables(primaryVal, secondaryVal)
        end
    end

    for k, secondaryVal in pairs(secondary) do
        local primaryVal = primary[k]

        if not primaryVal then
            output[k] = secondaryVal
        end
    end

    return output
end

---@diagnostic disable-next-line: lowercase-global
function table_val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v,"[^'\"]",""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
        return REVEL.ToString(v)
    end
end

---@diagnostic disable-next-line: lowercase-global
function table_key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. table_val_to_str(k) .. "]"
    end
end

---@diagnostic disable-next-line: lowercase-global
function table_tostring(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table_val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result,
            table_key_to_str(k) .. "=" .. table_val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end

function Bit(p)
    if not p then
        error("Bit128 | p nil: " .. tostring(p), 2)
    end
    return 2 ^ (p - 1)
end

function Bit128(p)
    if not p then
        error("Bit128 | p nil: " .. tostring(p), 2)
    end
    if p < 64 then
        return BitSet128(Bit(p), 0)
    else
        return BitSet128(0, Bit(p - 64 + 1))
    end
end

function HasBit(x, p)
    if not x or not p then
        error("HasBit | x or p nil: " .. tostring(x) .. ":" .. tostring(p), 2)
    end
    return (x & p) > 0
end

function SetBit(x, p)
    if not x or not p then
        error("HasBit | x or p nil: " .. tostring(x) .. ":" .. tostring(p), 2)
    end
    return x | p
end

function ClearBit(x, p)
    if not x or not p then
        error("HasBit | x or p nil: " .. tostring(x) .. ":" .. tostring(p), 2)
    end
    return (~p) & x
end

function BitAnd(x, p)
    if not x or not p then
        error("HasBit | x or p nil: " .. tostring(x) .. ":" .. tostring(p), 2)
    end
    return x & p
end 

function BitOr(x, ...)
    if not x then
        error("HasBit | x nil: " .. tostring(x), 2)
    end
    local args = {...}
    for _, p in ipairs(args) do
        x = x | p
    end
    return x
end

---@diagnostic disable-next-line: lowercase-global
function sign(a)
    if a > 0 then
        return 1
    elseif a < 0 then
        return -1
    elseif a == 0 then
        return 0
    end
end

-- REMOVE WHEN ALL REFERENCES REMOVED IN ALL BRANCHES
---@diagnostic disable-next-line: lowercase-global
function floatTo255()
    error("floatTo255 DEPRECATED\n", 2)
end

---@diagnostic disable-next-line: lowercase-global
function conv255ToFloat(...)
    local args = {...}
    for i,v in ipairs(args) do
        args[i] = v / 255
    end
    return table.unpack(args)
end

local function EntToString(v)
    -- %s to handle nils with EntityRef
    return REVEL.ToStringMulti(("(%s.%s.%s Pos: %s  %s  Vel: %s  Seed: %s)")
        :format(v.Type, v.Variant, v.SubType, REVEL.room:GetGridIndex(v.Position), v.Position, v.Velocity, v.InitSeed)
    )
end

REVEL.ShortHandVector = true
REVEL.ShortHandColor = true

local function roundToTwoDecimals(x)
    if math.abs(x) < 0.001 then
        x = 0
    else
        x = math.floor(100 * x) / 100
    end
    return x
end

local function shortenFloatsToString(...)
    local arg = {...}
    for i,v in ipairs(arg) do
        arg[i] = roundToTwoDecimals(arg[i])
    end
    return table.unpack(arg)
end

local UserDataToString = {
    Vector = function(v)
        if REVEL.ShortHandVector then
            return "V:( ".. roundToTwoDecimals(v.X) .." , ".. roundToTwoDecimals(v.Y) .." )"
        else
            return "V:( ".. v.X.." , "..v.Y.." )"
        end
    end,
    KColor = function(v)
        local r, g, b, a = shortenFloatsToString(v.Red, v.Green, v.Blue, v.Alpha)
        return "(" .. r .. ", " .. g .. ", " .. b .. ", " .. a .. ")"
    end,
    Color = function(v)
        if REVEL.ShortHandColor then
            local r, g, b, a, ro, bo, go = shortenFloatsToString(v.R, v.G, v.B, v.A, v.RO, v.BO, v.GO)
            return REVEL.ToStringMulti("C:(", r ..", "..g ..", "..b..", "..a .. ", " .. ro..", "..go..", "..bo, ")")
        else
            return REVEL.ToStringMulti("C:(", v.R .. ", " .. v.G .. ", " .. v.B .. ", " .. v.A .. ", " ..
                v.RO .. ", " .. v.GO .. ", " .. v.BO, ")")
        end
    end,
    Entity = EntToString,
    EntityPickup = EntToString,
    EntityPlayer = EntToString,
    EntityNPC = EntToString,
    EntityFamiliar = EntToString,
    EntityLaser = EntToString,
    EntityKnife = EntToString,
    EntityBomb = EntToString,
    EntityEffect = EntToString,
    EntityTear = EntToString,
    EntityProjectile = EntToString,
    EntityRef = EntToString,

    GridEntityDesc = function(v)
        return REVEL.ToStringMulti("GD:(", v.Type .. "." .. v.Variant, "State:", v.State, "VarData:", v.VarData, "Spawn Seed:", v.SpawnSeed, ")")
    end,

    RoomDescriptor = function(v)
        return REVEL.ToStringMulti('RD:(', v.GridIndex .. ' (' .. (v.GridIndex % 13) .. ',' .. math.floor(v.GridIndex / 13) .. ')', v.Data, ')')
    end,

    ['const Room'] = function(v) -- room descriptor data
        return REVEL.ToStringMulti('RDD:(', v.Type, v.Variant, v.Subtype, v.Shape, ')')
    end,

    BitSet128 = function(v)
        local out = "["
        for i = 1, 126 do
            if HasBit(v, Bit128(i)) then
                if out ~= "[" then
                    out = out .. ", "
                end
                out = out .. (i - 1)
            end
        end
        out = out .. "]"
        return out
    end,

    Sprite = function(v)
        return "(" .. v:GetFilename() .. ": " .. v:GetAnimation() .. "[" .. v:GetFrame() .. "])"
    end,

    ---@param v GridEntity
    GridEntity = function(v)
        return "(" .. v:GetGridIndex() .. " " .. REVEL.ToString(v.Desc) .. ")"
    end,

    ---@param v GridEntityDoor
    GridEntityDoor = function(v)
        return "(" .. tostring(v.Slot) .. ", " .. tostring(v.CurrentRoomType).. " -> " 
            .. tostring(v.TargetRoomType) .. "[" .. tostring(v.TargetRoomIndex) .. "], " 
            .. v:GetGridIndex() .. " " .. REVEL.ToString(v.Desc) .. ")"
    end,
}

do

local tmp = {}
for type, toStr in pairs(UserDataToString) do
    tmp[type] = toStr
    tmp['const ' .. type] = function(v)
        return 'CONST ' .. toStr(v)
    end
end
UserDataToString = tmp

end

function REVEL.ToString(v)
    if type(v) == "userdata" then
        local meta = getmetatable(v)
        if meta == nil then
            v = "[userdata]"
        else
            local tostr = UserDataToString[meta.__type]
            v = REVEL.ToStringMulti(meta.__type, tostr and tostr(v) or '???')
        end
    end
    if tostring(v) == "" then v = "[empty]" end
    if v == nil then v = '[nil]' end
    if type(v) == "table" then 
        -- REVEL.IsVec3 is nil during mod load
        if REVEL.IsVec3 and REVEL.IsVec3(v) then
            v = tostring(v)
        else
            v = table_tostring(v) 
        end
    end

    return tostring(v)
end

function REVEL.ToStringMulti(...)
    local a, arg, len = "", {...}, select("#", ...)

    for i=1,len do
      local str = REVEL.ToString(arg[i])
      a = a..str.." "
    end

    if a == "" then a = "[nil]" end
    return a
end

function REVEL.DebugToConsole(...)
    local a = REVEL.ToStringMulti(...)
    a = a.."@"..REVEL.game:GetFrameCount().."\n"
    Isaac.ConsoleOutput(a)
end

function REVEL.DebugStringMinor(...)
    if REVEL.DEBUG then
        REVEL.DebugToString(...)
    end
end

function REVEL.DebugMinorNotPaused(...)
    if REVEL.DEBUG and not REVEL.game:IsPaused() then
        REVEL.DebugToString(...)
    end
end

function REVEL.DebugToString(...)
    local a = REVEL.ToStringMulti(...)
    a = a.."@"..REVEL.game:GetFrameCount()
    Isaac.DebugString(a)
end

function REVEL.DebugLog(...)
    local a = REVEL.ToStringMulti(...)
    a = a.."@"..REVEL.game:GetFrameCount()
    Isaac.DebugString(a)
    Isaac.ConsoleOutput(a.."\n")
end

function REVEL.getKeyFromValue(t, a)
    if t == nil then
        error("getKeyFromValue: table nil", 2)
    end
    for k,v in pairs(t) do
      if v == a then return k end
    end
end

local function ripairs_it(t,i)
    i=i-1
    local v=t[i]
    if v==nil then return v end
    return i,v
end

---@diagnostic disable-next-line: lowercase-global
function ripairs(t)
    if t == nil then
        error("attempt to use ripairs on a nil table", 2)
    end
    --REVEL.DebugToString(t)
    return ripairs_it, t, #t+1
end

---Sort list by keys
---@generic V
---@param list V[]
---@param comp? fun(V, V): boolean # takes v1, v2 belonging to list and returns true if v1 < v2 (see lua table.sort doc)
---@return V[]
function REVEL.sort(list, comp)
    if list == nil then
        error("attempt to use sort on a nil table", 2)
    end

    local res = {}
    for k, v in ipairs(list) do res[k] = v end
    table.sort(res, comp)
    return res
end

---Sort list by keys
---@generic K, V
---@param tbl table<K, V>
---@return {[1]: K, [2]: V}[]
function REVEL.sortKeys(tbl)
    if tbl == nil then
        error("attempt to use sortKeys on a nil table", 2)
    end

    local res = REVEL.keys(tbl)
    table.sort(res)
    return REVEL.flatmap(res, function(k) return { k, tbl[k] } end)
end

---Returns list with elements returned by func for each element 
---@generic K, V, R
---@param list table<K, V>
---@param func fun(val: V, key: K, list: table): R
---@return table<K, R>
function REVEL.map(list, func)
    if list == nil then
        error("attempt to use map on a nil table", 2)
    elseif func == nil then
        error("map: func nil", 2)
    end

    local res = {}
    for k, v in pairs(list) do res[k] = func(v, k, list) end
    return res
end

---Returns list with elements returned by func for each element 
---and in a flat list
---@generic K, V, R
---@param list table<K, V>
---@param func fun(val: V, key: K, list: table): R
---@return R[]
function REVEL.flatmap(list, func)
    if list == nil then
        error("attempt to use flatmap on a nil table", 2)
    elseif func == nil then
        error("flatmap: func nil", 2)
    end

    local res = {}
    for k, v in pairs(list) do
        local ret = func(v, k, list)
        if ret ~= nil then
            table.insert(res, ret)
        end
    end
    return res
end

---Returns list without elements where pred returns false; 
---use for non-list tables, since this will muck with length
---@generic K, V
---@param list table<K, V>
---@param pred fun(val: V, key: K, list: table): boolean
---@return table<K, V>
function REVEL.pfilter(list, pred)
    if list == nil then
        error("attempt to use pfilter on a nil table", 2)
    elseif pred == nil then
        error("pfilter: pred nil", 2)
    end

    local res = {}
    for k, v in pairs(list) do
        ---@diagnostic disable-next-line: need-check-nil
        if pred(v, k, list) then
            res[k] = v
        end
    end
    return res
end

---Returns list without elements where pred returns false
---@generic K, V
---@param tbl table<K, V>
---@param pred fun(val: V, key: K, tbl: table): boolean
---@return V[]
function REVEL.filter(tbl, pred)
    if tbl == nil then
        error("attempt to use filter on a nil table", 2)
    elseif pred == nil then
        error("filter: pred nil", 2)
    end

    local res = {}
    for k, v in pairs(tbl) do
        ---@diagnostic disable-next-line: need-check-nil
        if pred(v, k, tbl) then
            table.insert(res, v)
        end
    end
    return res
end

---Returns true if pred is true for any in list
---@generic K, V
---@param list table<K, V>
---@param pred fun(val: V, key: K, list: table): boolean
---@return boolean
function REVEL.some(list, pred)
    if list == nil then
        error("attempt to use some on a nil table", 2)
    elseif pred == nil then
        error("some: pred nil", 2)
    end

    return REVEL.findKey(list, pred) ~= nil
end

---Returns true if pred is true for all in list
---@generic K, V
---@param list table<K, V>
---@param pred fun(val: V, key: K, list: table): boolean
---@return boolean
function REVEL.every(list, pred)
    if list == nil then
        error("attempt to use every on a nil table", 2)
    elseif pred == nil then
        error("every: pred nil", 2)
    end

    for k, v in pairs(list) do
        if not pred(v, k, list) then
            return false
        end
    end
    return true
end

---Returns total of agg ran on every element, starting from init as total
---@generic K, V
---@param list table<K, V>
---@param agg fun(total: V, val: V, key: K, list: table): V
---@param init V
---@return V
function REVEL.reduce(list, agg, init)
    if list == nil then
        error("attempt to use reduce on a nil table", 2)
    elseif agg == nil then
        error("reduce: agg nil", 2)
    end

    local total = init
    for k, v in pairs(list) do
        total = agg(total, v, k, list)
    end
    return total
end

---Returns key of item
---@generic K, V
---@param list table<K, V>
---@param item V
---@return K?
function REVEL.keyOf(list, item)
    for k, v in pairs(list) do
        if item == v then
            return k
        end
    end
    return nil
end

---Returns first index of item
---@generic V
---@param list V[]
---@param item V
---@return integer?
function REVEL.indexOf(list, item)
    for i, v in ipairs(list) do
        if item == v then
            return i
        end
    end
    return nil
end

---Returns keys of item
---@generic K, V
---@param list table<K, V>
---@param item V
---@return table<integer, K>
function REVEL.keysOf(list, item)
    local res = {}
    for k, v in pairs(list) do
        if item == v then
            res[#res + 1] = k
        end
    end
    return res
end

---Returns key of item that matches pred
---@generic K, V
---@param list table<K, V>
---@param pred fun(val: V, key: K, list: table): boolean
---@return K?
function REVEL.findKey(list, pred)
    if list == nil then
        error("attempt to use findKey on a nil table", 2)
        return --redundant, avoid linter false positive warning
    elseif pred == nil then
        error("findKey: pred nil", 2)
        return --redundant, avoid linter false positive warning
    end

    for k, v in pairs(list) do
        if pred(v, k, list) then
            return k
        end
    end
    return nil
end

---Returns item that matches pred
---@generic K, V
---@param list table<K, V>
---@param pred fun(val: V, key: K, list: table): boolean
---@return V?
function REVEL.find(list, pred)
    if list == nil then
        error("attempt to use find on a nil table", 2)
        return --redundant, avoid linter false positive warning
    elseif pred == nil then
        error("find: pred nil", 2)
        return --redundant, avoid linter false positive warning
    end

    return list[REVEL.findKey(list, pred)]
end

---@generic K, V
---@param list table<K, V>|V[]
---@param val V
---@return boolean
function REVEL.includes(list, val)
    if list == nil then
        error("attempt to use includes on a nil table", 2)
    end

    return REVEL.some(list, function(v) return v == val end)
end

---Uses GetPtrHash for equals check
---@generic K, V
---@param list table<K, V>|V[]
---@param val V
---@return boolean
function REVEL.includesIsaac(list, val)
    if list == nil then
        error("attempt to use includesIsaac on a nil table", 2)
    elseif val == nil then
        return nil
    end

    local hash = GetPtrHash(val)
    return REVEL.some(list, function(v) return GetPtrHash(v) == hash end)
end

---@generic K, V
---@param list table<K, V>|V[]
---@param func fun(val: V, key: K, list: table)
function REVEL.forEach(list, func)
    if list == nil then
        error("attempt to use forEach on a nil table", 2)
        return --redundant, avoid linter false positive warning
    elseif func == nil then
        error("forEach: func nil", 2)
        return --redundant, avoid linter false positive warning
    end

    for k, v in pairs(list) do
        func(v, k, list)
    end
end

---Returns table of keys in list
---@generic K
---@param list table<K, any>
---@return K[]
function REVEL.keys(list)
    if list == nil then
        error("attempt to use keys on a nil table", 2)
    end

    return REVEL.flatmap(list, function(v,k) return k end)
end

---Returns list of values
---@generic V
---@param list table<any, V>
---@return V[]
function REVEL.values(list)
    if list == nil then
        error("attempt to use values on a nil table", 2)
    end

    return REVEL.flatmap(list, function(v) return v end)
end

---Returns list of entries
---@generic V, K
---@param tbl table
---@return {[1]: K, [2]: V}[]
function REVEL.entries(tbl)
    if tbl == nil then
        error("attempt to use entries on a nil table", 2)
    end

    return REVEL.flatmap(tbl, function(v,k) return { k, v } end)
end

---@generic V
---@param t V[]
---@return { [V]: true }
function REVEL.toSet(t)
    if t == nil then
        error("attempt to use toSet on a nil table", 2)
    end

	local map = {}
	for i,v in ipairs(t) do
		map[v] = true
	end
	return map
end

---Adds arguments to table
---@param ta any[]
---@param ... any
---@return any[]
function REVEL.extend(ta, ...)
    if ta == nil then
        error("attempt to use extend on a nil table", 2)
    end

    for _, v in ipairs({...}) do
        table.insert(ta, v)
    end
    return ta
end

---returns a copy of the original list extended with the arguments
---@param ta any[]
---@param ... any
---@return any[]
function REVEL.concat(ta, ...)
    if ta == nil then
        error("attempt to use concat on a nil table", 2)
    end

    local res = {}
    for _, v in ipairs(ta) do
        table.insert(res, v)
    end
    return REVEL.extend(res, ...)
end

---returns a copy of the original table
---@param t any[]
---@return any[]
function REVEL.copy(t)
    if t == nil then
        error("attempt to use copy on a nil table", 2)
    end

    return REVEL.concat(t)
end

---returns a copy of the original table (dict)
---@param t table
---@return table
function REVEL.copyDict(t)
    if t == nil then
        error("attempt to use copyDict on a nil table", 2)
    end

    local res = {}
    for k, v in pairs(t) do
        res[k] = v
    end
    return res
end

---@param t table
---@return boolean
function REVEL.isEmpty(t)
    if t == nil then
        error("attempt to use isEmpty on a nil table", 2)
    end

    return not next(t)
end

---returns a rough shuffled copy of the original list
---@generic V
---@param t V[]
---@return V[]
function REVEL.shuffle(t)
    if t == nil then
        error("attempt to use shuffle on a nil table", 2)
    end

    t = REVEL.copy(t)
    for i=1,#t*2 do
        local a = math.random(#t)
        local b = math.random(#t)
        t[a],t[b] = t[b],t[a]
    end
    return t
end

---@param ta table
---@param tb table
---@param recurse? boolean
function REVEL.mixin(ta, tb, recurse)
    if ta == nil then
        error("mixin: ta nil", 2)
    elseif tb == nil then
        error("mixin: tb nil", 2)
    end

    for k, v in pairs(tb) do
        if recurse 
        and type(ta[k]) == "table"
        and type(v) == "table"
        then
            REVEL.mixin(ta[k], v, true)
        else
            ta[k] = v
        end
    end
end

---@generic V
---@param list V[]
---@param from? integer
---@param to? integer
---@return V[]
function REVEL.slice(list, from, to)
    from = from or 1
    to = to or #list

    if from < 0 then
        from = #list + from
    end
    if to < 0 then
        to = #list + to
    end

    local out = {}
    for i = from, math.min(to, #list) do
        out[#out+1] = list[i]
    end

    return out
end

function REVEL.GetFolderName()
    return GetFolderName()
end

function REVEL.LoadCustomFont(font, revFolderPath)
    local basePath = "mods/" .. REVEL.GetFolderName() .. "/resources/"

    font:Load(basePath .. revFolderPath)
end

REVEL.ChampionBlacklist = {}

function REVEL.BlacklistChampionNpc(entDef)
    REVEL.Assert(entDef, "BlacklistChampionNpc | entDef nil!", 2)
    if not REVEL.ChampionBlacklist[entDef.id] then
        REVEL.ChampionBlacklist[entDef.id] = {}
    end
    REVEL.ChampionBlacklist[entDef.id][entDef.variant] = 1
end

function REVEL.TryGetTraceback(noNewline, isntErrorFunction)
    if not REV_DEBUG_REPLACED_LUA_FUNCS or isntErrorFunction then
        return debug and debug.traceback((not noNewline) and "\n" or "", 2) or ""
    else
        return ""
    end
end

function REVEL.IsReloading()
	return not not Isaac.GetPlayer(0)
end

---Allows to specify an error stack level like with error()
---@param v any # fails assertion if false or nil
---@param message? string # error string, will use "assertion failed!" if not specified
---@param level? integer # error level, see error() doc
function REVEL.Assert(v, message, level)
    message = message or "assertion failed!"
    if not v then
        error(message, (level or 1) + 1)
    end
end

Isaac.DebugString("Revelations: Loaded Basic Library!")
--end
REVEL.PcallWorkaroundBreakFunction()