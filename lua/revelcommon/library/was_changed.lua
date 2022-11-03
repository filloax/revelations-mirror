REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
local wasChanged = {}

function REVEL.WasChanged(name, ...) --breaks with nil values
    local arg = {...}
    if wasChanged[name] == nil then
        wasChanged[name] = arg
        return true
    else
        if #arg ~= #wasChanged[name] then
            return true
        else
            for i,v in ipairs(wasChanged[name]) do
                if v ~= arg[i] then
                    wasChanged[name] = arg
                    return true
                end
            end
        end

        return false
    end
end
  
end

REVEL.PcallWorkaroundBreakFunction()