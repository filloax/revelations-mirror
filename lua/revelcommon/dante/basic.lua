local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
    
local gfxInfo = {
    Portrait = "gfx/ui/stage/revelcommon/dante_portrait.png",
    Name = "gfx/ui/boss/revelcommon/dante_charon_name.png",
    BossPortrait = "gfx/ui/boss/revelcommon/dante_charon_portrait.png",
    NoShake = false,
}

REVEL.Dante = {
    Callbacks = {},
}

StageAPI.AddPlayerGraphicsInfo(REVEL.CHAR.DANTE.Type, gfxInfo)
StageAPI.AddPlayerGraphicsInfo(REVEL.CHAR.CHARON.Type, gfxInfo)

---Returns true if the player is playing Dante&Charon, in general
---@param player EntityPlayer
---@return boolean
function REVEL.IsDanteCharon(player)
    if not player then error("IsDanteCharon | no player", 2) end

    return (player:GetPlayerType() == REVEL.CHAR.DANTE.Type or player:GetPlayerType() == REVEL.CHAR.CHARON.Type)
        and player.Variant == 0 
end

---Returns true if the player is playing Dante&Charon as Dante
---@param player EntityPlayer
---@return boolean
function REVEL.Dante.IsDante(player)
    if not player then error("IsDante | no player", 2) end

    return REVEL.IsDanteCharon(player) and revel.data.run.dante.IsDante
end

---Returns true if the player is playing Dante&Charon as Charon
---@param player EntityPlayer
---@return boolean
function REVEL.Dante.IsCharon(player)
    if not player then error("IsCharon | no player", 2) end

    return REVEL.IsDanteCharon(player) and not revel.data.run.dante.IsDante
end

function REVEL.Dante.IsMerged(player)
    if not player then error("IsMerged | no player", 2) end

    return REVEL.IsDanteCharon(player) and revel.data.run.dante.IsCombined
end

-- -1: run REVEL.IsDanteCharon check for all players to cover both player types
REVEL.AddCharacterUnlock(-1, "BROKEN_OAR", LevelStage.STAGE3_2, LevelStage.STAGE3_1, nil, nil, REVEL.IsDanteCharon)
REVEL.AddCharacterUnlock(-1, "FERRYMANS_TOLL", LevelStage.STAGE6, nil, StageType.STAGETYPE_WOTL, nil, REVEL.IsDanteCharon)
REVEL.AddCharacterUnlock(-1, "GHASTLY_FLAME", LevelStage.STAGE6, nil, StageType.STAGETYPE_ORIGINAL, nil, REVEL.IsDanteCharon)
REVEL.AddCharacterUnlock(-1, "DEATH_MASK", LevelStage.STAGE4_2, LevelStage.STAGE4_1, nil, nil, REVEL.IsDanteCharon)
REVEL.AddCharacterUnlock(-1, "WANDERING_SOUL", LevelStage.STAGE4_3, nil, nil, nil, REVEL.IsDanteCharon)

REVEL.PHYLACTERY_POCKET = true


revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, cmd)
    if cmd == "charonswitch" then
        REVEL.Dante.InventorySwitch(REVEL.player)
    elseif cmd == "charonmerge" then
        REVEL.Dante.Merge(REVEL.player, REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREED or REVEL.game.Difficulty == Difficulty.DIFFICULTY_GREEDIER)
    elseif cmd == "charonmode" then
        revel.data.charonMode = (revel.data.charonMode + 1) % 2
        if revel.data.charonMode == 0 then
            Isaac.ConsoleOutput("Changed Charon Switch Mode to firing keys (Default)")
        else
            Isaac.ConsoleOutput("Changed Charon Switch Mode to movement keys")
        end
    end
end)


-- Ignore and don't manage (swap)
REVEL.CharonBlacklist = {
    [CollectibleType.COLLECTIBLE_DEAD_CAT] = true,
    [CollectibleType.COLLECTIBLE_EXPERIMENTAL_TREATMENT] = true,
    [CollectibleType.COLLECTIBLE_ONE_UP] = true,
    [CollectibleType.COLLECTIBLE_LAZARUS_RAGS] = true,
    [CollectibleType.COLLECTIBLE_JUDAS_SHADOW] = true,
    [CollectibleType.COLLECTIBLE_ANKH] = true,
    [CollectibleType.COLLECTIBLE_GUPPYS_COLLAR] = true,
    [CollectibleType.COLLECTIBLE_HALO_OF_FLIES] = true,
    [CollectibleType.COLLECTIBLE_DEEP_POCKETS] = true,
    [CollectibleType.COLLECTIBLE_MOMS_PURSE] = true,
    [CollectibleType.COLLECTIBLE_SCHOOLBAG] = true,
    [CollectibleType.COLLECTIBLE_BIRTHRIGHT] = true,
}

-- Outright reroll
REVEL.CharonFullBan = {
    [CollectibleType.COLLECTIBLE_MOMS_PURSE] = true,
    [CollectibleType.COLLECTIBLE_SCHOOLBAG] = true,
    [CollectibleType.COLLECTIBLE_LITTLE_BAGGY] = true,
    [CollectibleType.COLLECTIBLE_STARTER_DECK] = true,
    [CollectibleType.COLLECTIBLE_POLYDACTYLY] = true,
    [CollectibleType.COLLECTIBLE_THERES_OPTIONS] = true,
    [CollectibleType.COLLECTIBLE_BELLY_BUTTON] = true,
    [CollectibleType.COLLECTIBLE_D4] = true,
    [CollectibleType.COLLECTIBLE_D100] = true,
    [CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM] = true,
    [CollectibleType.COLLECTIBLE_LEO] = true,
    [CollectibleType.COLLECTIBLE_INCUBUS] = true,
    [CollectibleType.COLLECTIBLE_ODD_MUSHROOM_RATE] = true,
    [CollectibleType.COLLECTIBLE_ODD_MUSHROOM_DAMAGE] = true,
    [CollectibleType.COLLECTIBLE_CAFFEINE_PILL] = true,
    [CollectibleType.COLLECTIBLE_4_5_VOLT] = true,
}

-- Changing player type messes pocket actives up
local function ChangeDantePlayerType(player, playerType)
    local prevItem = REVEL.Dante.GetPhylactery(player)
    local prevCharge = REVEL.Dante.GetPhylacteryCharge(player)

    if REVEL.PHYLACTERY_POCKET then
        player:RemoveCollectible(prevItem)
    end

    player:ChangePlayerType(playerType)

    if REVEL.PHYLACTERY_POCKET then
        REVEL.Dante.SetPhylactery(player, prevItem)
        player:SetActiveCharge(prevCharge, REVEL.Dante.GetPhylacteryActiveSlot())
    end
end

function REVEL.Dante.SwitchCostume(player, toCharon)
    local targetType
    if toCharon then
        targetType = REVEL.CHAR.CHARON.Type
        player:TryRemoveNullCostume(REVEL.COSTUME.DANTE_HAIR)
        player:AddNullCostume(REVEL.COSTUME.CHARON_HAIR)
        player:AddNullCostume(REVEL.COSTUME.BROKEN_OAR)
    else
        targetType = REVEL.CHAR.DANTE.Type
        player:TryRemoveNullCostume(REVEL.COSTUME.CHARON_HAIR)
        player:TryRemoveNullCostume(REVEL.COSTUME.BROKEN_OAR)
        player:AddNullCostume(REVEL.COSTUME.DANTE_HAIR)
    end

    if player:GetPlayerType() ~= targetType then
        ChangeDantePlayerType(player, targetType)
    end
end

end
REVEL.PcallWorkaroundBreakFunction()