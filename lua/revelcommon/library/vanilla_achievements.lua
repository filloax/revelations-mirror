REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

-- Some workarounds for not being able to access achievement data
-- dumb way being to just consider them unlocked if they have been
-- found vanilla at least once

-- REP FLOOR UNLOCK DETECTION

local StageToData = {
    [LevelStage.STAGE1_1] = "unlockedDross",
    [LevelStage.STAGE1_2] = "unlockedDross",
    [LevelStage.STAGE2_1] = "unlockedAshpit",
    [LevelStage.STAGE2_2] = "unlockedAshpit",
    [LevelStage.STAGE3_1] = "unlockedGehenna",
    [LevelStage.STAGE3_2] = "unlockedGehenna",
}

function REVEL.HasUnlockedRepentanceAlt(levelStage)
    if StageToData[levelStage] then
        return revel.data[StageToData[levelStage]]
    end
    error(("HasUnlockedRepentanceAlt: no rep alt for stage '%d'"):format(levelStage), 2)
end


local function repAltDetectPostNewLevel()
    local levelStage, stageType = REVEL.level:GetStage(), REVEL.level:GetStageType()

    if stageType == StageType.STAGETYPE_REPENTANCE_B
    and StageToData[levelStage]
    and not revel.data[StageToData[levelStage]] then
        revel.data[StageToData[levelStage]] = true
    end
end


-- HORSE PILL UNLOCK DETECTION

function REVEL.HasUnlockedHorsePills()
    return revel.data.unlockedHorsePills
end

local function horsepilldetectPostPickupInit(_, pickup)
    if not revel.data.unlockedHorsePills
    and pickup.SubType > PillColor.PILL_GIANT_FLAG then
        revel.data.unlockedHorsePills = true
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, horsepilldetectPostPickupInit, PickupVariant.PICKUP_PILL)
revel:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, repAltDetectPostNewLevel)

end