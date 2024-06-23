local StageAPICallbacks = require("scripts.revelations.common.enums.StageAPICallbacks")
local RevCallbacks      = require("scripts.revelations.common.enums.RevCallbacks")
local ShrineTypes       = require("scripts.revelations.common.enums.ShrineTypes")
local RevRoomType       = require("scripts.revelations.common.enums.RevRoomType")
local RoomTypeExtra     = require("scripts.revelations.common.enums.RoomTypeExtra")

return function()

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOMS_LIST_USE, 1, function(newRoom)
    if REVEL.STAGE.Glacier:IsStage() then
        if REVEL.ShrineRoomSpawnCheck(newRoom, REVEL.RoomLists.GlacierShrines) then
            return REVEL.RoomLists.GlacierShrines
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOM_LAYOUT_CHOOSE, 1, function(newRoom, roomsList)
    if roomsList == REVEL.RoomLists.GlacierShrines then
        return StageAPI.ChooseRoomLayout{
            RoomList = roomsList,
            Seed = newRoom.SpawnSeed,
            Shape = newRoom.Shape,
            IgnoreDoors = false,
            -- stageapi considers max possible doors for the original vanilla room layout
            -- that would have spawned instead of doors in room
            -- needed here as we don't necessarily have 4 door rooms
            Doors = REVEL.GetDoorsForRoomFromDesc(REVEL.level:GetCurrentRoomDesc()),
        }
    end
end)

REVEL.AddShrineSet(
    "Glacier", 
    "gfx/grid/revel1/shrines/", 
    nil, 
    "gfx/itemeffects/revelcommon/death_mask_lightning.png", 
    Color(0,0,0,1,conv255ToFloat(95,116,150)),
    "gfx/ui/shrineplaques/glacier",
    {
        Base = KColor(0,0,0, 0.65),
        Light = KColor(1,1,1, 0.05),
        Name = KColor(0 /255, 20 /255, 60 /255, 0.75),
        NameLight = KColor(1,1,1, 0.15),
    },
    REVEL.STAGE.Glacier
)
REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.MISCHIEF_G,
    EID_Description = {
        Name = "Mischief",
        Description = "Prank can appear in glacier rooms" 
            .. "#Prank will taunt you, throw snowballs and steal pickups."
            .. "#Defeating Prank will grant prizes, and a vanity discount."
    },
    OnTrigger = function()
        local prank

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            for i = 0, REVEL.room:GetGridSize() do
                if currentRoom.Metadata:Has{Index = i, Name = "PrankSpawnPoint"} then
                    prank = REVEL.ENT.PRANK_GLACIER:spawn(REVEL.room:GetGridPosition(i), Vector.Zero, nil)
                    break
                end
            end
        end

        if not prank then
            prank = REVEL.ENT.PRANK_GLACIER:spawn(REVEL.room:GetCenterPos(), Vector.Zero, nil)
        end

        REVEL.SetScaledBossHP(prank)
        revel.data.run.prank_glacier.hp = 1
        revel.data.run.prank_glacier.pickups = {}
        prank:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        REVEL.GetData(prank).PrankTimer = math.random(300, 450)
        prank:GetSprite():Play("Appear", true)
    end,
    TriggerExternal = function()
        revel.data.run.prank_glacier.hp = 1
        revel.data.run.prank_glacier.pickups = {}
    end,
    CanDoorsOpen = function()
        local pranks = REVEL.ENT.PRANK_GLACIER:getInRoom()
        if #pranks <= 0 then return true end

        local hasPrankStolenPickup = REVEL.some(pranks, function(prank)
            return REVEL.GetData(prank).StolenPickup
        end)

        return hasPrankStolenPickup or #REVEL.CheckPrankablePickups() == 0
    end
}, ShrineTypes.MISCHIEF)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.FROST,
    DisplayName = "Frost",
    Description = "More chill\nElusive warmth",
    HudIconFrame = 3,
    EID_Description = {
        Name = "Frost",
        Description = "Warmth areas are smaller"
            .. "#{{ColorOrange}}Grill O' Wisps{{CR}} move faster" 
            .. "#Freezing happens quicker"
    },
    OnTrigger = function()
        local currentRoom = StageAPI.GetCurrentRoom()
        currentRoom:SetTypeOverride(RevRoomType.CHILL)
        currentRoom.PersistentData.ChillShrine = true
        currentRoom.Data.RoomGfx = REVEL.GlacierChillRoomGfx
        for _, overlay in ipairs(REVEL.GetChillFadingOverlays()) do
            if (not overlay.Alpha or overlay.Alpha > 0) and not overlay.Fading and not overlay.FadingFinished then
                overlay:Fade(REVEL.DEFAULT_CHILL_FADE_TIME, 0, 1)
            end
        end

        REVEL.Glacier.SetFootprintsEnabledForRoom(false)

        if not REVEL.IsAchievementUnlocked("WILLO") then
            REVEL.UnlockAchievement("WILLO")
        end
        REVEL.ENT.GRILL_O_WISP:spawn(REVEL.room:GetCenterPos(), Vector.Zero, nil)
    end
})

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.FRAGILITY,
    DisplayName = "Fragility",
    Description = "Thinly coated\nFrozen life",
    HudIconFrame = 4,
    EID_Description = {
        Name = "Fragility",
        Description = "The floor can become frozen"
            .. "#You can now fall while standing on cracked ice"
            .. "#Frozen enemies can now move"
    },
    OnTrigger = function()
        local icePits = {}
        local shrineGridIndices = {34, 40}
        for i = 0, REVEL.room:GetGridSize() do
            local grid = REVEL.room:GetGridEntity(i)
            local pos = REVEL.room:GetGridPosition(i)
            local isShrine = false
            for _,gridInd in ipairs(shrineGridIndices) do
                if i == gridInd then
                    isShrine = true
                    break
                end
            end
            if (not grid or grid.Desc.Type == GridEntityType.GRID_DECORATION) and REVEL.room:IsPositionInRoom(pos, 0) and not isShrine then
                icePits[i] = true
            end
        end

        local pitFrames = {}
        local width = REVEL.room:GetGridWidth()
        for index, exists in pairs(icePits) do
            local adjacent = {index - 1, index + 1, index - width, index + width, index - width - 1, index + width - 1, index - width + 1, index + width + 1, true}
            for i = 1, 8 do
                adjacent[i] = icePits[adjacent[i]]
            end
            pitFrames[index] = StageAPI.GetPitFrame(table.unpack(adjacent))
        end

        local currentRoom = StageAPI.GetCurrentRoom()

        REVEL.GenerateRandomFragileIce(currentRoom, icePits)
        REVEL.FragileiceRoomLoad(currentRoom, false)

        currentRoom.PersistentData.IcePitFrames = pitFrames
        REVEL.LoadIcePits(pitFrames)
    end
})

--#region IceWraith

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.ICE_WRAITH,
    DisplayName = "Ice Wraith",
    Description = "Cold shoulder",
    HudIconFrame = 5,
    EID_Description = {
        Name = "Ice Wraith",
        Description = "A special {{ColorBlue}}Chill o' Wisp{{CR}} spawns, following you in every room"
    },
    OnTrigger = function()
        REVEL.ENT.ICE_WRAITH:spawn(REVEL.room:GetCenterPos(), Vector.Zero, nil)
    end
})
-- check will_o_wisps.lua for ice wraith logic, as it mostly acts like a chill o' wisp

local WraithRoomTypeBlacklist = {
    RoomType.ROOM_SHOP,
    RoomType.ROOM_ANGEL,
    RoomType.ROOM_DEVIL,
    RoomType.ROOM_SACRIFICE,
    RoomType.ROOM_DICE,
    RoomType.ROOM_ARCADE,
    RoomType.ROOM_LIBRARY,
    RoomType.ROOM_CHEST,
    RoomType.ROOM_PLANETARIUM,
    RevRoomType.VANITY,
    RevRoomType.CASINO,
    RevRoomType.DANTE_MEGA_SATAN,
    RevRoomType.HUB2D,
    RoomTypeExtra.ALT_TRANSITION,
    "Hub2Chamber",
}
WraithRoomTypeBlacklist = REVEL.toSet(WraithRoomTypeBlacklist)

function REVEL.Glacier.RoomGoodForIceWraith()
    local rtype = StageAPI.GetCurrentRoomType()
    return not WraithRoomTypeBlacklist[rtype]
end

--#endregion

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.CHAMPIONS_G,
}, ShrineTypes.CHAMPIONS)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.PUNISHMENT_G,
}, ShrineTypes.PUNISHMENT)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.MASOCHISM_G,
}, ShrineTypes.MASOCHISM)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.SCARCITY_G,
}, ShrineTypes.SCARCITY)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.GROUNDING_G,
}, ShrineTypes.GROUNDING)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.PURGATORY_G,
}, ShrineTypes.PURGATORY)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.BLEEDING_G,
}, ShrineTypes.BLEEDING)

REVEL.AddShrine("Glacier", {
    Name = ShrineTypes.MITOSIS__G,
}, ShrineTypes.MITOSIS)

--[[
    Shrines no longer have positive effects
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, e)
    if REVEL.IsShrineEffectActive(ShrineTypes.FRAGILITY) and e:ToNPC() and REVEL.GetData(e).OnIce then
        REVEL.GumHitEnt(e)
    end
end)
]]

end