local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")
local ShrineTypes       = require("lua.revelcommon.enums.ShrineTypes")

return function()

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOMS_LIST_USE, 1, function(newRoom)
    if REVEL.STAGE.Tomb:IsStage() then
        if REVEL.ShrineRoomSpawnCheck(newRoom, REVEL.RoomLists.TombShrines) then
            return REVEL.RoomLists.TombShrines
        end
    end
end)

StageAPI.AddCallback("Revelations", StageAPICallbacks.PRE_ROOM_LAYOUT_CHOOSE, 1, function(newRoom, roomsList)
    if roomsList == REVEL.RoomLists.TombShrines then
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
    "Tomb", 
    "gfx/grid/revel2/shrines/", 
    ".png", 
    "gfx/grid/revel2/shrines/tomb_shrine_effect.png", 
    Color(0,0,0,1, conv255ToFloat(147,115,68)),
    "gfx/ui/shrineplaques/tomb",
    {
        Base = KColor(0,0,0, 0.5),
        Light = KColor(1,1,1, 0.05),
        Name = KColor(0,0,0, 0.4),
        NameLight = KColor(1,1,1, 0.1),
    },
    REVEL.STAGE.Tomb
)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.MISCHIEF_T,
    EID_Description = {
        Name = "Mischief",
        Description = "Prank can appear in tomb rooms"
            .. "#Prank will taunt you, trigger traps and steal pickups."
            .. "#Defeating Prank will grant prizes, and a vanity discount."
    },
    OnTrigger = function()
        local prank

        local currentRoom = StageAPI.GetCurrentRoom()
        if currentRoom then
            for i = 0, REVEL.room:GetGridSize() do
                if currentRoom.Metadata:Has{Index = i, Name = "PrankSpawnPoint"} then
                    prank = REVEL.ENT.PRANK_TOMB:spawn(room:GetGridPosition(i), Vector.Zero, nil)
                    break
                end
            end
        end

        if not prank then
            prank = REVEL.ENT.PRANK_TOMB:spawn(REVEL.room:GetCenterPos(), Vector.Zero, nil)
        end

        REVEL.SetScaledBossHP(prank)
        revel.data.run.prank_tomb.hp = 1
        revel.data.run.prank_tomb.pickups = {}
        prank:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
        prank:GetData().State = "InitialPile"
        prank:GetData().PrankTimer = math.random(300, 450)
        prank.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        prank:GetSprite():Play("Submerged", true)
    end,
    TriggerExternal = function()
        revel.data.run.prank_tomb.hp = 1
        revel.data.run.prank_tomb.pickups = {}
    end,
    CanDoorsOpen = function()
        local pranks = REVEL.ENT.PRANK_TOMB:getInRoom()
        if #pranks <= 0 then return true end

        local isPrankPile = false
        local hasPrankStolenPickup = false
        for _, prank in ipairs(pranks) do
            local pdata = prank:GetData()
            if pdata.State == "InitialPile" then
                isPrankPile = true
                break
            end

            if pdata.StolenPickup then
                hasPrankStolenPickup = true
            end
        end

        return not isPrankPile and (hasPrankStolenPickup or #REVEL.CheckPrankablePickups() == 0)
    end
}, ShrineTypes.MISCHIEF)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.REVIVAL,
    DisplayName = "Revival",
    Description = "Restless rags\nStronger magic",
    HudIconFrame = 4,
    EID_Description = {
        Name = "Revival",
        Description = "Rag monsters are more dangerous" 
    },
    OnTrigger = function()
        for _, entity in ipairs(REVEL.roomEntities) do
            if REVEL.IsEntityRevivable(entity) then
                REVEL.BuffEntity(entity)
            end
        end
    end
})

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if REVEL.IsShrineEffectActive(ShrineTypes.REVIVAL) and not REVEL.room:IsClear() and REVEL.room:GetFrameCount() > 300 and math.random(1, 600) == 1 and #Isaac.FindByType(REVEL.ENT.NECRAGMANCER.id, REVEL.ENT.NECRAGMANCER.variant, -1, false, false) == 0 then
        local ragCount = REVEL.ENT.REVIVAL_RAG:countInRoom()
        if ragCount > 0 then
            local projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, -1, false, false)
            local proCount = 0
            for _, pro in ipairs(projectiles) do
                if pro:GetData().Necragmancer or pro:GetData().RevivalShrineTear then
                    proCount = proCount + 1
                end
            end

            if proCount < ragCount then
                local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, REVEL.room:GetCenterPos() + RandomVector() * (REVEL.room:GetGridWidth() * 40), Vector.Zero, nil):ToProjectile()
                proj:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                proj.Size = proj.Size * 4
                --proj:GetSprite():Load("gfx/bosses/revel2/aragnid/aragnid_magicball.anm2", true)
                --proj:GetSprite():Play("Idle", true)
                proj.Color = Color(1,1,1,1,0.5,0,0.3)
                proj.Scale = 2.5
                proj.Height = -20
                proj.FallingSpeed = 0
                proj.FallingAccel = -0.1
                proj.RenderZOffset = 100001
                proj.ProjectileFlags = ProjectileFlags.SMART
                proj:GetData().RevivalShrineTear = true
                proj:Update()
                proj.ProjectileFlags = 0
                proj:GetData().PurpleColor = proj.Color
                --proj.Color = Color(1, 1, 1, 1,conv255ToFloat( 0, 0, 0))
            end
        end
    end
end)


REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.PERIL,
    DisplayName = "Peril",
    Description = "Trickier traps",
    HudIconFrame = 5,
    EID_Description = {
        Name = "Peril",
        Description = "Traps are more dangerous"
    },
    OnTrigger = function()
        local validCoffins = REVEL.filter(REVEL.ENT.CORNER_COFFIN:getInRoom(), function(coffin)
            local cdata = coffin:GetData()
            return cdata.IsPathable and (not cdata.SpawnEnemies or #cdata.SpawnEnemies == 0)
        end)

        if #validCoffins > 0 then
            local coffin = validCoffins[math.random(1, #validCoffins)]
            local cdata = coffin:GetData()
            local enemies = REVEL.CoffinEnemies[math.random(1, #REVEL.CoffinEnemies)]
            cdata.SpawnEnemies = REVEL.copy(enemies)
        end
    end,
    CanDoorsOpen = function()
        local isActiveCoffin = REVEL.some(REVEL.ENT.CORNER_COFFIN:getInRoom(), function(coffin)
            local cdata = coffin:GetData()
            return cdata.SpawnEnemies and #cdata.SpawnEnemies > 0
        end)

        return not isActiveCoffin
    end
})

local BlackListedPickupGrids = {
    GridEntityType.GRID_SPIKES,
    GridEntityType.GRID_TRAPDOOR,
    GridEntityType.GRID_PRESSURE_PLATE
}
function REVEL.IsFreePickupSpot(index, pos)
    if REVEL.roomFireGrids[index] then return false end

    if StageAPI.GetCustomGrid(index, REVEL.GRIDENT.HUB_TRAPDOOR.Name) then
        return false
    end

    if not pos then pos = REVEL.room:GetGridPosition(index) end
    if not REVEL.room:IsPositionInRoom(pos, 0) then return false end

    if REVEL.room:GetGridCollision(index) == 0 then
        local grid = REVEL.room:GetGridEntity(index)
        return not (grid and REVEL.includes(BlackListedPickupGrids, grid:GetType()))
    end
end

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.CHAMPIONS_T,
}, ShrineTypes.CHAMPIONS)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.PARANOIA,
    DisplayName = "Paranoia",
    Description = "Mystery traps",
    HudIconFrame = 3,
    EID_Description = {
        Name = "Paranoia",
        Description = "Trap tiles will be labelled with a \'?\'"
            .. "#Fake trap tiles can randomly spawn"
    },
    Sprite = "paranoia",
    OnTrigger = function()
        for _, trap in ipairs(Isaac.FindByType(StageAPI.E.FloorEffect.T, StageAPI.E.FloorEffect.V, -1, false, false)) do
            local tdata = trap:GetData()
            if tdata.TrapData then
                local sprite = trap:GetSprite()
                tdata.Animation = "Unknown"
                sprite:SetFrame(tdata.Animation, tdata.TrapTriggered and 1 or 0)
            end
        end    
    end,
})

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.PUNISHMENT_T,
}, ShrineTypes.PUNISHMENT)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.MASOCHISM_T,
}, ShrineTypes.MASOCHISM)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.SCARCITY_T,
}, ShrineTypes.SCARCITY)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.GROUNDING_T,
}, ShrineTypes.GROUNDING)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.PURGATORY_T,
}, ShrineTypes.PURGATORY)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.BLEEDING_T,
}, ShrineTypes.BLEEDING)

REVEL.AddShrine("Tomb", {
    Name = ShrineTypes.MITOSIS__T,
}, ShrineTypes.MITOSIS)

end