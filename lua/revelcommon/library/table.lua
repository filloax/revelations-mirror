REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

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

function REVEL.PrettyPrint(tbl, luaSyntax, level, noValSpacing)
    level = level or 0
    local spacing = string.rep("  ", level)

    if type(tbl) ~= "table" then
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
        table.insert(listItems, REVEL.PrettyPrint(v, luaSyntax, level + 1, true))
        done[k] = true
    end

    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(keyItems,
            spacing .. table_key_to_str(k) .. " = " .. REVEL.PrettyPrint(v, luaSyntax, level + 1, true))
        end
    end

    if #keyItems == 0 then
        if luaSyntax then
            return "{" .. table.concat(listItems, ", ") .. "}"
        else
            return "[" .. table.concat(listItems, ", ") .. "]"
        end
    else
        local spacingSub = string.rep("  ", level + 1)
        local spacingPre = string.rep("  ", math.max(level - 1, 0))
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
---@param max? integer
---@param step? integer = 1
---@return integer[]
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

-- TODO: check other branches if its still used and replace
-- DEPRECATED
function REVEL.IsIn(tbl, v)
    if REVEL.DEBUG then
        REVEL.DebugLog("WARN: IsIn is deprecated" .. REVEL.TryGetTraceback())
    end
	return REVEL.includes(tbl, v)
end


end

REVEL.PcallWorkaroundBreakFunction()