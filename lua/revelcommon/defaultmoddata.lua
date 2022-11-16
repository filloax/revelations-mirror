REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()
-- Separate from definitions primarily so that all UNLOCKABLES will already be defined
REVEL.DEFAULT_MODDATA = {
    run = {
        level = {
            room = {},

            hub2Statues = {},
            revTrapdoors = {},
            MirrorDoorSpawned = false,
            MirrorDoorChance = 0,
            penanceHealState = 0,
            mirrorDoorRoomDimension = nil,
            mirrorDoorRoomIndex = -1,
            mirrorDoorRoomSlot = -1,
            hasMirrorDoor = false,
            mirrorRoomIndex = -1,


            shrineRoomSpawnAttempts = 0,
            maxShrineRoomAttempts = -1,
            roomsBeforeShrinesTriggered = {},
            shrineRoomIndex = -1,
            shrineTypes = {},
            shrineRewards = {},
            shrineRewardRooms = {},
            spawnedShrineRoom = false,
            -- didVshopDevilRoomTeleport = false,
            -- vShopDevilRoomTeleportPos = {80, 80},

            dante = {
                StartingRoomIndex = -1,
                OtherRoomDisplayData = {},
                RoomClearData = {
                    Current = {},
                    Other = {},
                },
                RoomClearAwards = {},
                RepFailsafe = false
            },

            destroyedPenanceStatue = false,
            unlockedHubRoom = false,
    
            eliteRoomIndex = -1, -- -1 = none, -2 = first seen, otherwise is grid index of elite room
    
            notablePickupsInRoom = {
                -- [tostring(listIndex)] = N
            },
            notablePickupsTakenFromRoom = {},
    
            localRestockVars = {}, -- [initseed] = {Payout = X, BreakChance = X}
    
            revendingMachineData = {},
            statwheelData = {},
            
            customPillsInRoom = {
                -- [tostring(listIndex)] = {{BaseColor = N, CustomColor = x, GridIndex = idx, Hash = y}, ...}
            },    

            clearFromStartRooms = {
                -- [tostring(listIndex)] = 0/1
            },

            revelShopSpawned = false,

            rerollsData = {
                
            },
        },

        unlockedTrinkets = {},
        unlockedCards = {},
        inventory = {},
        itemCount = {},
        itemHistory = {},
        trinketHistory = {},
        bellEffect = {},
        visitedDevil = false,
        visitedShop = false,
        visitedArcade = false,
        entityRegister = {},
        birthdayCandleStats = {0, 0, 0, 0},
        brokenWingsState = {0, 0, 0, 0},
        hyperDiceChance = 0,
        hyperDiceCorrupted = false,
        bcSynergyes = {
            [tostring(CollectibleType.COLLECTIBLE_LITTLE_GISH)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_GHOST_BABY)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_LITTLE_STEVEN)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_MULTIDIMENSIONAL_BABY)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_INTRUDER)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_SUCCUBUS)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_HOLY_WATER)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_FRUITY_PLUM)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_STAR_OF_BETHLEHEM)] = 0,
            [tostring(CollectibleType.COLLECTIBLE_HALLOWED_GROUND)] = 0,
            [tostring(REVEL.ITEM.ENVYS_ENMITY.id)] = 0,
            [tostring(REVEL.ITEM.BANDAGE_BABY.id)] = 0,
            [tostring(REVEL.ITEM.WILLO.id)] = 0,
        },
        penance = {
            {sh = 0, bh = 0, gh = 0},
            {sh = 0, bh = 0, gh = 0},
            {sh = 0, bh = 0, gh = 0},
            {sh = 0, bh = 0, gh = 0}
        },
        stats = {
            { --copied for each player below
                Damage = 0,
                MaxFireDelay = 0,
                ShotSpeed = 0,
                TearRange = 0,
                TearFallingSpeed = 0,
                MoveSpeed = 0,
                Luck = 0,

                mult = {
                    Damage = 1,
                    MaxFireDelay = 1,
                    ShotSpeed = 1,
                    TearRange = 1,
                    TearFallingSpeed = 1,
                    MoveSpeed = 1,
                    Luck = 1
                }
            },
        },
        penanceBlackHeartsOut = {0, 0, 0, 0},
        penanceTier = 0,
        urielSpawned = false,

        
        playerCustomPills = {
            { 
                -- [tostring(slotID)] = {BaseColor = N, CustomColor = x} 
            },
            {},
            {},
            {},
        },

        exploredRooms = 0,

        customActiveCharge = {
            {},
            {},
            {},
            {},
        },

        virgilBombs = 3,
        virgilTargetedRocks = {},
        virgilRevive = false,
        virgilTemp = {
          0,
          0,
          0,
          0
        },
        tempVirgilThisFloor = false,
    
        addictCount = 0,
    
        ferrymanRevives = {
            0,
            0,
            0,
            0
        },
        deathmaskCharge = 0,
    
        madeAMistake = {},
        activeShrines = {},   
        spawnedShrineRoomChapters = {},
        vanity = 0, 
        prankDiscount = {},

        sinamiBeat = {
            tomb = false,
            glacier = false
        },
    
        dante = {
            OtherRoom = -1,
            OtherInventory = {
                ---@type RevDante.Health
                hearts = {
                },
                secondActive = {
                    id = -1,
                    charge = -1
                },
                position = {X = false, Y = false},
                items = {},
                spriteScale = {X = 1, Y = 1},
                sizeMulti = {X = 1, Y = 1},
                trinket = -1,
                card = -1,
                pill = -1
            },
            BirthrightWhitelist = {},
            ActiveComesFromCharon = false,
            RedHeartPrioritizeDante = true,
            RedHeartPrioritySet = false,
            IsCombined = false,
            IsDante = false,
            IsInitialized = false,
            FirstMerge = false,
        },

        cursedGrailsFilled = {
            0,
            0,
            0,
            0
        },
    
        chewedPonysChewed = {
            0,
            0,
            0,
            0
        },
        
        itemsVoided = {},
        possiblySkippingFloor = false,
        skippedFloor = false,

        eliteEncountered = {
            glacier = false,
            tomb = false
        },

        globalRestockPayout = 5,    

        pactGrounding = {},

        spawnedMirrorShard = {},
    },

    minimapapi = {},

    BossesBeaten = {},
    unlockValues = {},
    firstRunSwitch = false,
    firstRunWarning = false,
    unlockedHorsePills = false,
    unlockedDross = false,
    unlockedAshpit = false,
    unlockedGehenna = false,
  
    BossesEncountered = {},
    RuthlessMenuUnlocked = false,
  
    pickedUpItems = {},
    wonWithItems = {},  

    stalactiteTargetsOn = 1,
    auroraOn = 1,
    shadersOn = 1,
    oldHubActive = 2,
    shaderColorBoostOn2 = 1,
    hudoffset = 0,
    charonMode = 0,
    charonAutoFace = 1,
    controllerToggle = 1,
    overlaysMode = 1,
    snowflakesMode = 2,
    menuPalette = 1,
    cLightSetting = 2,
    particlesOn = 2, --0= off, 1=reduced, 2=on
    volumeMult = 0.75,
    clearCacheMode = 1, --0=off, 1=every level/X minutes, 2=every room, see clearcache.lua
}

for i = 1, 3 do
    REVEL.DEFAULT_MODDATA.run.stats[#REVEL.DEFAULT_MODDATA.run.stats + 1] = 
        REVEL.CopyTable(REVEL.DEFAULT_MODDATA.run.stats[1])
end

Isaac.DebugString("Revelations: Loaded Common Default Save Data!")
end