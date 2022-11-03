-- Separate file as basiclibrary was into too deep of a folder so 
-- the error workaround didn't work, lol
-- Top level so even longer mod folder names should work

local FolderName = nil

local function IsValidFolderName(name)
    local invalidFilenameChars = "\\/%?%*:|\"<>"
    local invalidFoldernameEndChars = invalidFilenameChars .. "$."
    local pattern = "[^" .. invalidFilenameChars .. "]*[^" .. invalidFoldernameEndChars .. "]"
    return string.match(name, pattern) == name
end

local function DetectFolderName()
    if FolderName then
        return FolderName
    end

    --[INFO] - Lua Debug: Failed to load module: ...Binding of Isaac Rebirth/mods/revelations/foldername.lua:35: folder check
    local _, err = pcall(function() 
        REVEL.DISABLE_ERROR_TRACEBACK = true
        error("folder check") 
        REVEL.DISABLE_ERROR_TRACEBACK = false
    end)

    local fileDepth = 0
    local slashFolder_Pattern = "[\\/][^\\/]*"
    local slashFile_Pattern = "[\\/][^\\/]*$"
    local slashBefore = string.find(err, string.rep(slashFolder_Pattern, fileDepth + 1) .. slashFile_Pattern)
    local slashAfter = string.find(err, string.rep(slashFolder_Pattern, fileDepth) .. slashFile_Pattern)
    local name = string.sub(err, slashBefore + 1, slashAfter - 1)

    if not IsValidFolderName(name) then
        if REVEL.IS_WORKSHOP then
            name = REVEL.FOLDER_NAME .. REVEL.MODID
        else
            name = REVEL.FOLDER_NAME
        end
        REVEL.DebugToString("Could not do folder name workaround, too long of a folder name? Using default")
    end

    REVEL.DebugStringMinor("Detected folder name:", name)

    FolderName = name

    return name
end

function _G.RevFolderNameDebugCheck()
    local _, err = pcall(function() 
        error("folder check") 
    end)
    REVEL.DebugLog("Debug output:", err)
end

return DetectFolderName