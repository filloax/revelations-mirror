local hub2 = require "scripts.hubroom2"

local game = Game()

hub2.LOG_ALL = false

local function Concat(...)
    local num = select("#", ...)
    local args = {...}
    local out = ""
    for i = 1, num do
        out = out .. tostring(args[i])
    end
    return out
end

function hub2.Log(...)
    local a = Concat(...)
    Isaac.DebugString("[Hub 2] " .. a)
    Isaac.ConsoleOutput("[Hub 2] " .. a .. "\n")
end

function hub2.LogMinor(...)
    local a = Concat(...)
    Isaac.DebugString("[Hub 2] " .. a)
    if hub2.LOG_ALL then
        Isaac.ConsoleOutput("[Hub 2] " .. a .. "\n")
    end
end

function hub2.LogDebug(...)
    if hub2.LOG_ALL then
        local a = Concat(...)
        Isaac.DebugString("[Hub 2] " .. a)
        -- Isaac.ConsoleOutput("[Hub 2] " .. a .. "\n")
    end
end

function hub2.HasBit(x, p)
    if not x or not p then
        error("HasBit | x or p nil: " .. tostring(x) .. ":" .. tostring(p), 2)
    end
    return (x & p) > 0
end

function hub2.BitOr(x, ...)
    local args = {...}
    for _, p in ipairs(args) do
        x = x | p
    end
    return x
end

-- unlocked trinkets/cards maps --

function hub2.IsTrinketUnlocked(trinketId)
    return not not hub2.data.run.unlockedTrinkets[tostring(trinketId)]
end

function hub2.IsCardUnlocked(cardId)
    return not not hub2.data.run.unlockedCards[tostring(cardId)]
end

function hub2.GetMaxTrinketId()
    local itemConfig = Isaac.GetItemConfig()
    local id = TrinketType.NUM_TRINKETS-1
    local step = 16
    while step > 0 do
        if itemConfig:GetTrinket(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end

function hub2.GetAllUnlockedTrinkets()
    hub2.data.run.unlockedTrinkets = {}
    
    local itempool = game:GetItemPool()
    local maxTrinketId = hub2.GetMaxTrinketId()
    
    -- there are very few trinkets that can be encountered multiple times, so to combat this it will loop more than otherwise needed
    for i=0, maxTrinketId*2 do
		hub2.TrinketHistorySkipTrinket = true
        hub2.data.run.unlockedTrinkets[tostring(itempool:GetTrinket())] = true
    end
    
    itempool:ResetTrinkets()
end

function hub2.GetMaxCardId()
    local itemConfig = Isaac.GetItemConfig()
    local id = Card.NUM_CARDS-1
    local step = 16
    while step > 0 do
        if itemConfig:GetCard(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end

function hub2.GetAllUnlockedCards()
    hub2.data.run.unlockedCards = {}
    
    local itempool = game:GetItemPool()
    local maxCardId = hub2.GetMaxCardId()
    
    local seeds = game:GetSeeds()
    
    -- not failure proof as it's possible to not have a card show up with itempool:GetCard(), but good enough for it's purpose
    for i=0, maxCardId*5 do
        local cardId = itempool:GetCard(seeds:GetNextSeed(), true, true, false)
        hub2.data.run.unlockedCards[tostring(cardId)] = true
    end
end

hub2:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if not isContinued then
        hub2.GetAllUnlockedTrinkets()
        hub2.GetAllUnlockedCards()
    end
end)

-- trinket history --

hub2:AddCallback(ModCallbacks.MC_GET_TRINKET, function(trinketType, rng)
    if not hub2.TrinketHistorySkipTrinket then
        hub2.data.run.trinketHistory[trinketType] = true
    else
        hub2.TrinketHistorySkipTrinket = false
    end
end)

function hub2.HasTrinketBeenEncounteredThisRun(trinketType)
    return not not hub2.data.run.trinketHistory[trinketType]
end

-- Some workarounds for not being able to access achievement data
-- dumb way being to just consider them unlocked if they have been
-- found vanilla at least once

-- REP FLOOR UNLOCK DETECTION

local stageToData = {
    [LevelStage.STAGE1_1] = "unlockedDross",
    [LevelStage.STAGE1_2] = "unlockedDross",
    [LevelStage.STAGE2_1] = "unlockedAshpit",
    [LevelStage.STAGE2_2] = "unlockedAshpit",
    [LevelStage.STAGE3_1] = "unlockedGehenna",
    [LevelStage.STAGE3_2] = "unlockedGehenna",
}

function hub2.HasUnlockedRepentanceAlt(levelStage)
    if stageToData[levelStage] then
        return hub2.data[stageToData[levelStage]]
    end
end


local function repAltDetectPostNewLevel()
	local level = game:GetLevel()
    local levelStage, stageType = level:GetStage(), level:GetStageType()

    if stageType == StageType.STAGETYPE_REPENTANCE_B
    and stageToData[levelStage]
    and not hub2.data[stageToData[levelStage]] then
        hub2.data[stageToData[levelStage]] = true
    end
end

hub2:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, repAltDetectPostNewLevel)

-- Get the next stage type in case of Repentance level transition
-- Example, if the next stage will be dross or downpour, etc
function hub2.SimulateStageTransitionStageType(levelStage, isRepPath)
	local level = game:GetLevel()
	
	local oldStage, oldStageType = level:GetAbsoluteStage(), level:GetStageType()
    local seeds = game:GetSeeds()
	local oldSeed = seeds:GetStartSeedString()
	
	local testStage = levelStage - 1
	local testStageType = isRepPath and StageType.STAGETYPE_REPENTANCE or StageType.STAGETYPE_ORIGINAL
	level:SetStage(testStage, testStageType)
	
	level:SetNextStage()
	local stageType = level:GetStageType()
	
	seeds:SetStartSeed(oldSeed)
    level:SetStage(oldStage, oldStageType)
	
    -- In case of curse of labyrinth and others it doesn't work
    if isRepPath and not (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) then
        local rng = RNG()
        rng:SetSeed(seeds:GetStageSeed(levelStage), 127)
        if rng:RandomFloat() < 0.5 or not hub2.HasUnlockedRepentanceAlt(levelStage) then
            stageType = StageType.STAGETYPE_REPENTANCE
        else
            stageType = StageType.STAGETYPE_REPENTANCE_B
        end
    end

	return stageType
end