local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"

-- defined outside so it's already loaded, as it's needed by earlycallbacks.lua when it loads
local RevNPCs

function REVEL.GetChampionableEntityIds()
    if not RevNPCs then
        RevNPCs = {}

        local toCheck = {}
        for _, v in pairs(REVEL.ENT) do
            toCheck[#toCheck+1] = v
        end

        for _, entDef in ipairs(toCheck) do
            -- sub-table
            if not entDef.id and type(entDef) == "table" then
                for __, v in pairs(entDef) do
                    toCheck[#toCheck+1] = v
                end
                
            elseif entDef.id >= 10 and entDef.id ~= 1000 then
                if not RevNPCs[entDef.id] then
                    RevNPCs[entDef.id] = {}
                end
                RevNPCs[entDef.id][entDef.variant] = 1
            end
        end
    end
    return RevNPCs
end

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

local function GetShrineActiveAmount()
    local _, amount = REVEL.IsShrineEffectActive(ShrineTypes.CHAMPIONS, true)
    return amount
end

local CmdForceChampions = false

function REVEL.GetRevEnemyChampionChance()
    if CmdForceChampions then
        return 1
    end

    local activeAmount = GetShrineActiveAmount()
    if activeAmount > 0 then
        local increase = REVEL.Lerp2Clamp(
            REVEL.ShrineBalance.ChampionChanceIncreaseBase,
            REVEL.ShrineBalance.ChampionChanceIncreaseMax,
            activeAmount,
            1,
            REVEL.ShrineBalance.ChampionMaxAmount
        )
        return REVEL.GetChampionChance() + (increase / 100)
    else
        return 0
    end
end

-- Has chance even without shrine
function REVEL.GetRevBossChampionChance()
    if revel.data.run.madeAMistake[tostring(REVEL.GetStageChapter())] then
        return 1
    end

    local activeAmount = GetShrineActiveAmount()
    local increase = REVEL.Lerp2Clamp(
        REVEL.ShrineBalance.ChampionChanceIncreaseBase,
        REVEL.ShrineBalance.ChampionChanceIncreaseMax,
        activeAmount,
        1,
        REVEL.ShrineBalance.ChampionMaxAmount
    )
    
    return REVEL.GetChampionChance() + (increase / 100)
end

REVEL.NpcChampionRNG = REVEL.RNG()

local ChampionCheckEnabled = true

function REVEL.SetRevChampionsEnabled(val)
    ChampionCheckEnabled = val
end

---@param type EntityType
---@param variant integer
---@param subtype integer
---@param position Vector
---@param velocity Vector
---@param spawner? Entity
---@return Entity
function REVEL.SpawnNoChampion(type, variant, subtype, position, velocity, spawner)
    ChampionCheckEnabled = false
    local e = Isaac.Spawn(type, variant, subtype, position, velocity, spawner)
    ChampionCheckEnabled = true
    return e
end

local function CheckChampion(npc)
    if REVEL.IsRevelStage() 
    and ChampionCheckEnabled
    and not (REVEL.ChampionBlacklist[npc.Type] and REVEL.ChampionBlacklist[npc.Type][npc.Variant])
    and not npc:IsBoss() 
    and not npc.SpawnerEntity then
        local chance = REVEL.GetRevEnemyChampionChance()
        if chance > 0 then
            REVEL.NpcChampionRNG:SetSeed(npc.InitSeed, 40)
            if REVEL.NpcChampionRNG:RandomFloat() < chance then
                npc:MakeChampion(npc.InitSeed, -1, true)
                REVEL.DebugStringMinor(("Made npc %d.%d at %d a champion")
                    :format(npc.Type, npc.Variant, REVEL.room:GetGridIndex(npc.Position))
                )
            end
        end
    end
end

REVEL.EarlyCallbacks.revNpcChampions_PostNpcInit = {}
for type, varSet in pairs(REVEL.GetChampionableEntityIds()) do
    REVEL.EarlyCallbacks.revNpcChampions_PostNpcInit[type] = function(_, npc)
        if varSet[npc.Variant] then
            CheckChampion(npc)
        end
    end
end

local function championsExecuteCommand(_, cmd)
    if cmd == "forcechampions" or cmd == "fchamp" then
        CmdForceChampions = not CmdForceChampions

        if CmdForceChampions then
            REVEL.DebugLog("Enabled force rev enemy champions")
        else
            REVEL.DebugLog("Disabled force rev enemy champions")
        end
    end
end

revel:AddCallback(ModCallbacks.MC_EXECUTE_CMD, championsExecuteCommand)

end
REVEL.PcallWorkaroundBreakFunction()