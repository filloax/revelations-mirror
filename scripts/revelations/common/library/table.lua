return function()

function REVEL.ConcatTables(...)
    local args, out = {...}, {}

    for _, tbl in ipairs(args) do
        for _, v in ipairs(tbl) do
            out[#out + 1] = v
        end
    end

    return out
end

function REVEL.ShiftTable(tbl, amount)
	local tbl_length = #tbl
	
	for i=1, amount do
		table.insert(tbl, 1, table.remove(tbl, tbl_length))
	end
end

-- return array with only the elements that returned true on the predicate
-- similar to REVEL.filter, but can take additional args
-- to the predicate with the ... parameter
-- predicate = function(i,v,...) that returns true or false depending on 
-- each entry
function REVEL.GetFilteredArray(t, predicate, ...)
    local ret = {}
  
    for i,v in ipairs(t) do
        if predicate(v, ...) then
            ret[#ret+1] = v
        end
    end
  
    return ret
end
  
function REVEL.TableToStringEnter(tbl)
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
    return "{" .. table.concat(result, ",\n") .. "}"
end

---@param tbl table
---@param newline? boolean
---@return string
function REVEL.ShallowTableToString(tbl, newline)
    local result, done = {}, {}

    for k, v in ipairs(tbl) do
        table.insert(result, tostring(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result,
            tostring(k) .. "=" .. tostring(v))
        end
    end

    local sep = ", "
    if newline then
        sep = ",\n"
    end

    return "{" .. table.concat(result, sep) .. "}"
end

if REVEL.DEBUG then
    function sts(tbl, newline)
        return REVEL.ShallowTableToString(tbl, newline)
    end
end

function REVEL.PrettyPrint(tbl, luaSyntax, maxDepth, level, noValSpacing)
    level = level or 0
    local spacing = string.rep("  ", level + 1)

    if type(tbl) ~= "table" then
        if maxDepth and level >= maxDepth then
            return "{...}"
        end

        local out = ""
        if type(tbl) == "string" then
            out = out .. '"'
        end
        if noValSpacing then
            out = out .. REVEL.ToString(tbl)
        else
            out = out .. spacing .. REVEL.ToString(tbl)
        end
        if type(tbl) == "string" then
            out = out .. '"'
        end
        return out
    end

    local listItems, keyItems, done = {}, {}, {}
    for k, v in ipairs(tbl) do
        table.insert(listItems, REVEL.PrettyPrint(v, luaSyntax, maxDepth, level + 1, true))
        done[k] = true
    end

    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(keyItems,
            spacing .. table_key_to_str(k) .. " = " .. REVEL.PrettyPrint(v, luaSyntax, maxDepth, level + 1, true))
        end
    end

    if #keyItems == 0 then
        if luaSyntax then
            return "{" .. table.concat(listItems, ", ") .. "}"
        else
            return "[" .. table.concat(listItems, ", ") .. "]"
        end
    else
        local spacingSub = string.rep("  ", level + 2)
        local spacingPre = string.rep("  ", math.max(level, 0))
        if #listItems == 0 then
            return "{\n" .. table.concat(keyItems, ",\n") .. "\n" .. spacingPre .. "}"
        else
            return "{\n" .. spacingSub .. table.concat(listItems, ", ") .. "\n" .. spacing .. table.concat(keyItems, ",\n") .. "\n" .. spacingPre .. "}"
        end
    end
end

function REVEL.FillTable(tableToFill, tableToFillFrom)
	for i, value in pairs(tableToFillFrom) do
		if tableToFill[i] ~= nil then
			if type(value) == "table" then
				tableToFill[i] = REVEL.FillTable(tableToFill[i], value)
			else
				tableToFill[i] = value
			end
		else
			if type(value) == "table" then
				tableToFill[i] = REVEL.FillTable({}, value)
			else
				tableToFill[i] = value
			end
		end
	end
	return tableToFill
end

local function isVector(x)
    return type(x) == "userdata" and x.X
end

-- rng is optional
function REVEL.GetFromMinMax(valueOrTable, rng)
    if type(valueOrTable) == "number" or isVector(valueOrTable) then
        return valueOrTable
    elseif type(valueOrTable) == "table" then
        local isFloat
        if type(valueOrTable.Min) == "number" then
            isFloat = math.modf(valueOrTable.Min) ~= valueOrTable.Min or math.modf(valueOrTable.Max) ~= valueOrTable.Max
        else
            isFloat = math.modf(valueOrTable.Min.X) ~= valueOrTable.Min.X or math.modf(valueOrTable.Max.X) ~= valueOrTable.Max.X
                or math.modf(valueOrTable.Min.Y) ~= valueOrTable.Min.Y or math.modf(valueOrTable.Max.Y) ~= valueOrTable.Max.Y
        end
        if isFloat then
            return StageAPI.RandomFloat(valueOrTable.Min, valueOrTable.Max, rng)
        elseif type(valueOrTable.Min) == "number" then
            return StageAPI.Random(valueOrTable.Min, valueOrTable.Max, rng)
        elseif isVector(valueOrTable.Min) then
            return Vector(
                StageAPI.RandomFloat(valueOrTable.Min.X, valueOrTable.Max.X, rng), 
                StageAPI.RandomFloat(valueOrTable.Min.Y, valueOrTable.Max.Y, rng)
            )
        end
    end
end

---@param min integer
---@param max integer inclusive
---@param step? integer = 1
---@return integer[]
---@overload fun(max: integer): integer[] min = 1
function REVEL.Range(min, max, step)
    local out = {}
  
    if not max then
        max = min
        min = 1
    end
  
    for i = min, max, step or 1 do
        out[#out + 1] = i
    end
  
    return out
end

function REVEL.KeyRange(min, max, step)
    return REVEL.toSet(REVEL.Range(min, max, step))
end

-- Usage: for i, v, tbl in REVEL.MultiTableIterate(table1, table2, ...) do
---@generic T
---@vararg T[]
---@return fun(): integer, T, T[]
function REVEL.MultiTableIterate(...)
    local i = 0
    local tables = {...}
    local currentTable = 1
    return function ()
        i = i + 1
        repeat
            if i > #tables[currentTable] then
                i = 1
                currentTable = currentTable + 1
                if not tables[currentTable] then
                    return nil
                end
            end
        until tables[currentTable][i]
            
        if tables[currentTable][i] then 
            return i, tables[currentTable][i], currentTable
        end
    end
end

-- Given an ordered array of numbers, returns the first index at or after the targetValue
-- Usually left and right should be not set when called outside of the function body
function REVEL.ClosestBinarySearch(numArray, targetValue, left, right)
    if #numArray == 0 then return nil end
    left = left or 1
    right = right or #numArray

    local i = math.ceil((left + right) / 2)

    --output: index whose number is higher or equal than target and previous is lower than target

    while numArray[i] == numArray[i - 1] do
        i = i - 1
    end

    if numArray[i] >= targetValue and (not numArray[i-1] or numArray[i-1] < targetValue) then
        return i
    else
        if numArray[i] > targetValue then
            if i > 1 then
                return REVEL.ClosestBinarySearch(numArray, targetValue, left, i - 1)
            else
                return -1
            end
        else
            if i < #numArray then
                return REVEL.ClosestBinarySearch(numArray, targetValue, i + 1, right)
            elseif numArray[#numArray] == targetValue then
                return #numArray + 1
            else
                return -2
            end
        end
    end
end

local function equals(v1, v2)
    -- for same type
    if type(v1) ~= "userdata" and type(v2) ~= "userdata" then
        return v1 == v2
    end

    local meta1 = getmetatable(v1)
    local meta2 = getmetatable(v2)
    if meta1 == nil and meta2 == nil then
        return true -- unreadable data, do not consider for diff
    elseif meta1 == nil or meta2 == nil then
        return false -- one is unreadable data but not both
    else
        local classtype1 = meta1.__type or meta1.__name
        local classtype2 = meta2.__type or meta2.__name

        if classtype1 ~= classtype2 then
            return false
        end

        if classtype1 == "Vector" then
            return v1.X == v2.X and v1.Y == v2.Y
        end
    end
end

---Returns difference between tables and subtables in a structured format.
---@param tbl1 table
---@param tbl2 table
---@return {Added: string[], Removed: string[], Changed: table}
function REVEL.TableDiff(tbl1, tbl2)
    local added = {}
    local removed = {}
    local changed = {}
    for k, v in pairs(tbl1) do
        if tbl2[k] == nil then
            removed[k] = v
        elseif type(tbl1[k]) == type(tbl2[k]) then
            if type(tbl1[k]) == "table" then
                local subDiff = REVEL.TableDiff(tbl1[k], tbl2[k])
                for k2, v2 in pairs(subDiff.Added) do
                    added[k .. "." .. k2] = v2
                end
                for k2, v2 in pairs(subDiff.Removed) do
                    removed[k .. "." .. k2] = v2
                end
                for k2, v2 in pairs(subDiff.Changed) do
                    changed[k .. "." .. k2] = v2
                end
            elseif not equals(tbl1[k], tbl2[k]) then
                changed[k] = {Was=tbl1[k], Is=tbl2[k]}
            end
        else
            changed[k] = {Was=tbl1[k], Is=tbl2[k]}
        end
    end
    for k, v in pairs(tbl2) do
        if tbl1[k] == nil then
            if type(v) == "table" then
                local subDiff = REVEL.TableDiff({}, v)
                for k2, v2 in pairs(subDiff.Added) do
                    added[k .. "." .. k2] = v2
                end
            else
                added[k] = v
            end
        end
    end

    return {
        Added = added,
        Removed = removed,
        Changed = changed,
    }
end

---Returns tbl[k] if present, or runs producer and assigns its
-- result to tbl[k] before returning it otherwise.
---@generic K, V
---@param tbl table<K, V>
---@param k K
---@param producer fun(): V
function REVEL.ComputeIfAbsent(tbl, k, producer)
    if not tbl[k] then
        tbl[k] = producer()
    end
    return tbl[k]
end

---@deprecated
function REVEL.IsIn(tbl, v)
    if REVEL.DEBUG then
        REVEL.DebugLog("WARN: IsIn is deprecated" .. REVEL.TryGetTraceback())
    end
	return REVEL.includes(tbl, v)
end


end