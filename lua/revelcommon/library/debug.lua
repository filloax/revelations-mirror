REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()


function REVEL.DumpItemNameList()
    local a = ""
    for k,v in pairs(revel.data.run.inventory) do
        local item = REVEL.config:GetCollectible(tonumber(k))
        a = a..", "..item.Name
    end
    
    REVEL.DebugToString({"Current items:", a})
end

function REVEL.DumpTearFlags(e)
    local a = ""
    for k,v in pairs(TearFlags) do
        if HasBit(e.TearFlags, v) then
            a = a.."  "..tostring(k)
        end
    end
    REVEL.DebugToString(a)
end
  
function REVEL.DumpEntityFlags(e)
    local a = ""
    for k,v in pairs(EntityFlag) do
        if e:HasEntityFlags(v) then
            a = a.."  "..tostring(k)
        end
    end
    REVEL.DebugToString(a)
end

function REVEL.PrintLevelMap()
    local a = "\n"
    local b = "\n"
    local maxId
    for i=0, REVEL.level:GetRooms().Size-1 do
        if (not maxId) or REVEL.level:GetRooms():Get(i).GridIndex > maxId then
            maxId = REVEL.level:GetRooms():Get(i).GridIndex
        end
    end

    for y=0, maxId/13 + 1 do
        for x=0, 12 do
            local room = REVEL.level:GetRoomByIdx(x + y*13)
            if room.GridIndex == -1 then room = nil end       
            ---@diagnostic disable-next-line: need-check-nil
            local str1 = room and tostring(room.GridIndex) or ""
            a = a..(string.rep(room and " " or "_",3 - #str1)..str1).." "
            ---@diagnostic disable-next-line: need-check-nil
            local str2 = room and tostring(room.ListIndex) or ""
            b = b..(string.rep(room and " " or "_",2 - #str2)..str2).." "
        end
        a = a..'\n'
        b = b..'\n'
    end
    Isaac.DebugString(a..b)
    Isaac.DebugString("You're at: " .. tostring(StageAPI.GetCurrentListIndex()))
end

function REVEL.GridListToString(list, ...)
    local toMark = REVEL.toSet({...})
    local out = ""
    local width = REVEL.room:GetGridWidth()
    local set = REVEL.toSet(list)
  
    for i = 0, REVEL.room:GetGridSize() do
        if i % width == 0 and i > 0 then
            out = out .. "\n"
        end
    
        if toMark[i] then
            out = out .. "O"
        elseif set[i] then
            out = out .. "#"
        else
            out = out .. "-"
        end
    end

    return out
end

function REVEL.PrintPathMap(map, name, width, size)
    name = name or ""
    width = width or REVEL.room:GetGridWidth()
    local counter = 1
    local prntLine = ""
    Isaac.DebugString("Path Map " .. name .. " Start")
    for i = 0, size or REVEL.room:GetGridSize() do
        local add = " "
        if type(map[i]) == "number" then
            if map[i] < 10 then
                add = tostring(map[i]) .. add
            else
                add = tostring(map[i])
            end
        else
            add = "X" .. add
        end

        prntLine = prntLine .. add .. " "
        counter = counter + 1
        if counter > width then
            Isaac.DebugString(prntLine)
            counter = 1
            prntLine = ""
        end
    end
    Isaac.DebugString("Path Map End")
end

function REVEL.PrintPathMap2(pathmap, width)
    width = width or REVEL.room:GetGridWidth()
    local maxId, maxVal
    local toIntMap = {}
  
    --in case of printing collisions
    for index, value in pairs(pathmap) do
        if type(value) == "table" then
            toIntMap[index] = {}
            for i, val2 in pairs(value) do
                if type(val2) == "boolean" then
                    toIntMap[index][i] = val2 and 1 or 0
                else
                    toIntMap[index][i] = val2
                end
            end
        else
            if type(value) == "boolean" then
                toIntMap[index] = value and 1 or 0
            else
                toIntMap[index] = value
            end
        end
    end
    pathmap = toIntMap
  
    for index, value in pairs(pathmap) do
        if (not maxId) or index > maxId then
            maxId = index
        end
        if type(value) == "number" then
          if (not maxVal) or value > maxVal then
              maxVal = math.floor(value)
          end
        else
          for i, val2 in ipairs(value) do
              if (not maxVal) or val2 > maxVal then
                maxVal = math.floor(val2)
              end
          end
        end
    end
    local maxValLen = math.ceil(math.log(maxVal) / math.log(10))
  
    local height = maxId/width + 1
  
    for y=0, height - 1 do
        local a = ""
        for x=0, width - 1 do
            local value = pathmap[y * width + x]
            if type(value) == "number" then value = math.floor(value) end
            local str1 = value and tostring(value) or ""
            a = a..(string.rep(value and " " or "_", maxValLen - #str1)..str1).." "
        end
        Isaac.DebugString(a)
    end
end
  
local tearFlagsToKeys = {}
for key, flag in pairs(TearFlags) do
    tearFlagsToKeys[flag] = key
end

function REVEL.TearFlagsToString(tearFlags)
    local bits = toBits(tearFlags)
    local out = {}

    for i = 0, #bits - 1 do
        if bits[i + 1] == 1 then
            out[#out + 1] = tearFlagsToKeys[math.floor(2 ^ i)]
        end
    end

    return out
end

function REVEL.PrintGridSet(gridSet, width, valuesAreDividedGrids)
    local maxLen = 0
    local maxGrid = 0

    local dividedGridSet = gridSet

    if valuesAreDividedGrids then
        dividedGridSet = {}

        local maxSubdivisions = type(valuesAreDividedGrids) == "number" and valuesAreDividedGrids
        if not maxSubdivisions then
            for gridIndex, val in pairs(gridSet) do
                if not maxSubdivisions or val.Subdivisions > maxSubdivisions then
                    maxSubdivisions = val.Subdivisions
                end
            end
        end

        local newWidth = width * maxSubdivisions
        for gridIndex, val in pairs(gridSet) do
            local topLeftIndex = REVEL.GetTopLeftDividedGrid(gridIndex, maxSubdivisions)
            for x = 1, maxSubdivisions do
                for y = 0, maxSubdivisions - 1 do
                    local newIndex = topLeftIndex + x + y * newWidth
                    if type(val) == "table" then
                        local innerVal = val[x + y * maxSubdivisions]
                        dividedGridSet[newIndex] = innerVal
                    else
                        dividedGridSet[newIndex] = (x == 1 and y == 0) and val or ""
                    end
                end
            end
        end

        width = newWidth
    end

    local convertedSet = {}
    for gridIndex, val in pairs(dividedGridSet) do
      if val == true then
        convertedSet[gridIndex] = 1
      else
        convertedSet[gridIndex] = val
      end
    end

    for gridIndex, val in pairs(convertedSet) do
        local len = #tostring(val)
        if len > maxLen then maxLen = len end
        if gridIndex > maxGrid then maxGrid = gridIndex end
    end
    maxGrid = math.ceil(maxGrid / width) * width - 1

    local out1 = ""
    local out2 = ""

    for i = 0, maxGrid do
        local str
        if convertedSet[i] then
            str = string.format("%" .. maxLen .. "s", tostring(convertedSet[i]))
        else
            str = string.rep("-", maxLen)
        end
        out1 = out1 .. str .. " "
        if (i + 1) % width == 0 then
          out1 = out1 .. "\n"
        end
    end

    local maxGridLen = #tostring(maxGrid)

    for i = 0, maxGrid do
        local str
        if convertedSet[i] then
            str = string.format("%" .. maxGridLen .. "s", tostring(i))
        else
            str = string.rep("-", maxGridLen)
        end
        out2 = out2 .. str .. " "
        if (i + 1) % width == 0 then
          out2 = out2 .. "\n"
        end
    end

    Isaac.DebugString("\n" .. out1)
    Isaac.DebugString("\n" .. out2)
end

local Duration = 300
local Position = Vector(30, 30)
local Offset = 12
local LogMessages = {}

function REVEL.IngameLog(...)
    table.insert(LogMessages, 1, {Time = 60, Message = REVEL.ToStringMulti(...)})
end

local function ingamelogPostRender()
    if REVEL.DEBUG then
        for i, msg in ipairs(LogMessages) do
            Isaac.RenderText(msg.Message, Position.X, Position.Y + Offset * (i - 1), 255, 255, 255, REVEL.Lerp2Clamp(0, 1, msg.Time, 0, 15))
            if not REVEL.game:IsPaused() then
                msg.Time = msg.Time - 0.5
            end
        end
    end
end

function REVEL.PrintBrokenGrids()
    local w = REVEL.room:GetGridWidth()

    local a = ""

    for i = 0, REVEL.room:GetGridSize() - 1 do
        local x = i % w
        local y = math.floor(i / w)

        if x == 0 then
            a = a .. '\n'
        end
        local grid = REVEL.room:GetGridEntity(i)
        a = a .. ((grid and REVEL.IsGridBroken(grid)) and 'X' or 'O')
    end
    Isaac.DebugString(a)
end

revel:AddCallback(ModCallbacks.MC_POST_RENDER, ingamelogPostRender)
  
end

REVEL.PcallWorkaroundBreakFunction()