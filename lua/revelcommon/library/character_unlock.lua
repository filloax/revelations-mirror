REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local CharacterUnlocks = {}

function REVEL.AddCharacterUnlock(playerType, unlock, stage, stageIfXL, stageType, isGreed, isPlayerCheck)
    if not CharacterUnlocks[playerType] then
        CharacterUnlocks[playerType] = {}
    end

    local unlock = {
        Unlock = unlock,
        Stage = stage,
        StageType = stageType,
        StageIfXL = stageIfXL,
        IsGreed = isGreed,
        IsPlayerCheck = isPlayerCheck
    }

    CharacterUnlocks[playerType][#CharacterUnlocks[playerType] + 1] = unlock

    return unlock
end

local function characterUnlockPlayerUpdate(_, player)
    if REVEL.room:IsClear() and REVEL.room:GetType() == RoomType.ROOM_BOSS then
        local ptype = player:GetPlayerType()
        local unlocks = CharacterUnlocks[ptype]
        if not unlocks then
            for _, unlockSet in pairs(CharacterUnlocks) do
                if unlockSet.IsPlayerCheck and unlockSet.IsPlayerCheck(player) then
                    unlocks = unlockSet
                    break
                end
            end
        end

        if unlocks then
            local stage, stageType = REVEL.level:GetStage(), REVEL.level:GetStageType()
            for _, unlock in ipairs(unlocks) do
                if not REVEL.IsAchievementUnlocked(unlock.Unlock)
                and (not unlock.IsGreed or REVEL.game:IsGreedMode())
                and (
                    stage == unlock.Stage 
                    or (
                        unlock.StageIfXL 
                        and HasBit(REVEL.level:GetCurses(), LevelCurse.CURSE_OF_LABYRINTH) 
                        and stage == unlock.StageIfXL 
                        and REVEL.room:IsCurrentRoomLastBoss()
                    )
                ) 
                and (not unlock.StageType or stageType == unlock.StageType)
                then
                    REVEL.DebugLog(unlock)
                    REVEL.UnlockAchievement(unlock.Unlock)
                end
            end
        end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, characterUnlockPlayerUpdate)

end