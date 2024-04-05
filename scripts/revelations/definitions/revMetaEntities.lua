return function ()
    
StageAPI.AddMetadataEntities{
    [199] = {
        [742] = {
            Name = "Dante Mega Satan",
        },

        [745] = {
            Name = "Disable Random Special Rock Spawn",
        },
        [746] = {
            Name = "Vanity Shop Item",
        },
        [747] = {
            Name = "Vanity Statwheel Init Workaround",
        },
        [748] = {
            Name = "Test - Airmovement Ground Level",
            BitValues = {
                GroundLevel = {ValueOffset = -32768, Length = 16},
            },
        },


        [750] = {
            Name = "RagtimeBoxDance",
            Tags = {
                "RagtimeDanceCore",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                JumpRotation = {Offset = 8, Length = 2},
            },
        },
        [751] = {
            Name = "RagtimeBoxDancePoint",
            Tags = {
                "RagtimeDanceExtra",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                JumpRotation = {Offset = 8, Length = 2},
            },
        },
        [752] = {
            Name = "RagtimeConga",
            Tags = {
                "RagtimeDanceCore",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                Direction = {Offset = 8, Length = 3},
            },
        },
        [753] = {
            Name = "RagtimeCongaPoint",
            Tags = {
                "RagtimeDanceExtra",
                "RagtimeDance",
                "Ragtime"
            },
            BitValues = {
                DanceID = {Offset = 0, Length = 8},
                Direction = {Offset = 8, Length = 3},
                IsEnd = {Offset = 11, Length = 1},
            },
        },
        [754] = {
            Name = "RagtimePlayerSafeSpot",
            Tags = {
                "Ragtime"
            },
        },
        [755] = {
            Name = "Dune Tile",
        },
        [756] = {
            Name = "Flaming Tomb",
            BitValues = {
                Rotation = {Offset = 0, Length = 2},
                Decorative = {Offset = 2, Length = 1},
            },        
        },

        [760] = {
            Name = "TrapUnknown"
        },
        [780] = {
            Name = "CoffinPacker",
            BlockEntities = true
        },
        [781] = {
            Name = "RevivalTear"
        },
        [782] = {
            Name = "AntlionAutoemerge"
        },
        [783] = {
            Name = "TileMongerTile"
        },
        [784] = {
            Name = "BombTrapBomb"
        },
        [785] = {
            Name = "ExtraItemSpawn"
        },
        [786] = {
            Name = "ExtinguishableFire"
        },
        [787] = {
            Name = "Anima"
        },


        [788] = {
            Name = "Tusky Random Rider (Force)",
            Tags = {
                "TuskyRider"
            }
        },
        [789] = {
            Name = "Tusky Random Rider (Or no rider)",
            Tags = {
                "TuskyRider"
            }
        },
    },
    [625] = {
        [274] = {
            Name = "Ice Pit",
        },
        [275] = {
            Name = "Fragile Ice Pit",
        },
        [276] = {
            Name = "No Fragility Forced Ice",
        },
    },
    [770] = { --metadata for handier check (ice blocks are always the same entity)
        [1011] = {
            Tags = {"ChuckIceBlock"},
            Name = "Chuck Ice Block (Cracked)",
        },
        [1012] = {
            Tags = {"ChuckIceBlock"},
            Name = "Chuck Ice Sphere",
        },
    },
    [789] = {
        
        -- Traps
        [6] = {
            Name = "ArrowTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [7] = {
            Name = "CoffinTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [8] = {
            Name = "BoulderTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [11] = {
            Name = "FlameTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [12] = {
            Name = "SpikeTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [13] = {
            Name = "SpikeTrapOffset",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [15] = {
            Name = "RevivalTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [16] = {
            Name = "BombTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },
        [17] = {
            Name = "BrimstoneTrap",
            Tags = {
                "RevTraps"
            },
            ConflictTag = "RevTraps"
        },

        -- Trap Stackable Modifiers
        [9] = {
            Name = "ObviousTrap"
        },
        [10] = {
            Name = "ForcedTrap"
        },
        [14] = {
            Name = "BadTrap"
        },

        -- Extra Metadata
        [50] = {
            Name = "FlameTrapAlwaysActive",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [51] = {
            Name = "FlameTrapTimed",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [52] = {
            Name = "FlameTrapTimedOffset",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [53] = {
            Name = "SpikeTrapSpike",
            Tags = {
                "SpikeTrap"
            },
        },
        [54] = {
            Name = "SpikeTrapSpikeOffset",
            Tags = {
                "SpikeTrap"
            },
        },
        [55] = {
            Name = "BrimstoneTrapTimed",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [56] = {
            Name = "BrimstoneTrapTimedOffset",
            Tags = {
                "AutoShooterTrap"
            },
        },
        [75] = {
            Name = "CoffinBlocker"
        },
        [76] = {
            Name = "RevivalRag"
        },
        [77] = {
            Name = "BoulderOffset"
        },
        [78] = {
            Name = "DisableOnClear"
        },
        [79] = {
            Name = "BrazierBlocker"
        },
        [90] = {
            Name = "ReducedHP"
        },
        [91] = {
            Name = "Championizer"
        },
        [92] = {
            Name = "NoChampion"
        },
        [150] = {
            Name = "AlwaysOnStalagSpike",
        },
    },
    --ID-Less, added via code not room editor
    TuskySpecificRider = {
        Name = "TuskySpecificRider",
        Tags = {
            "TuskyRider"
        }
    },
    AvalancheSpawnData = {
        Name = "AvalancheSpawnData",
    },
    PrankSpawnPoint = {
        Name = "PrankSpawnPoint"
    },
}

        
end