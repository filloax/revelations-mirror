return function()

REVEL.BossTargetTimeTable = {
    -- GLACIER BOSSES
    [REVEL.ENT.MONSNOW.id] = {
        [REVEL.ENT.MONSNOW.variant] = {TargetLength = 30, Vulnerability = 0.6}
    },
    [REVEL.ENT.FLURRY_HEAD.id] = {
        [REVEL.ENT.FLURRY_HEAD.variant] = {TargetLength = 30, Vulnerability = 0.55}
    },
    [REVEL.ENT.DUKE_OF_FLAKES.id] = {
        [REVEL.ENT.DUKE_OF_FLAKES.variant] = {TargetLength = 30, Vulnerability = 0.25}
    },
    [REVEL.ENT.FROST_RIDER.id] = {
        [REVEL.ENT.FROST_RIDER.variant] = {TargetLength = 40, Vulnerability = 0.45}
    },
    [REVEL.ENT.FREEZER_BURN.id] = {
        [REVEL.ENT.FREEZER_BURN.variant] = {TargetLength = 45, Vulnerability = 0.5}
    },
    [REVEL.ENT.STALAGMITE.id] = {
        [REVEL.ENT.STALAGMITE.variant] = {TargetLength = 50, Vulnerability = 0.5}
    },
    [REVEL.ENT.WENDY.id] = {
        [REVEL.ENT.WENDY.variant] = {TargetLength = 60, Vulnerability = 0.42}
    },
    [REVEL.ENT.PRONG.id] = {
        [REVEL.ENT.PRONG.variant] = {TargetLength = 60, Vulnerability = 0.35}
    },
    [REVEL.ENT.WILLIWAW.id] = {
        [REVEL.ENT.WILLIWAW.variant] = {TargetLength = 60, Vulnerability = 0.40}
    },
    [REVEL.ENT.NARCISSUS.id] = {
        [REVEL.ENT.NARCISSUS.variant] = {TargetLength = 60, Vulnerability = 0.35}
    },
    [REVEL.ENT.CHUCK.id] = {
        [REVEL.ENT.CHUCK.variant] = {TargetLength = 30, Vulnerability = 0.5}
    },

    -- TOMB BOSSES
    [REVEL.ENT.CATASTROPHE_YARN.id] = {
        [REVEL.ENT.CATASTROPHE_YARN.variant] = {TargetLength = 65, Vulnerability = 0.4}
    },
    [REVEL.ENT.ARAGNID.id] = {
        [REVEL.ENT.ARAGNID.variant] = {TargetLength = 65, Vulnerability = 0.5}
    },
    [REVEL.ENT.MAXWELL.id] = {
        [REVEL.ENT.MAXWELL.variant] = {TargetLength = 80, Vulnerability = 0.25}
    },
    --Refers to first phase, ouch phase has parameters set in boss balance table
    [REVEL.ENT.SARCOPHAGUTS.id] = {
        [REVEL.ENT.SARCOPHAGUTS.variant] = {TargetLength = 70, Vulnerability = 0.3}
    },
    [REVEL.ENT.SANDY.id] = { -- includes phase 2
        [REVEL.ENT.SANDY.variant] = {TargetLength = 85, Vulnerability = 0.25}
    },
    [REVEL.ENT.JEFFREY_BABY.id] = {
        [REVEL.ENT.JEFFREY_BABY.variant] = {TargetLength = 35, Vulnerability = 0.3}
    },
    [REVEL.ENT.NARCISSUS_2.id] = {
        [REVEL.ENT.NARCISSUS_2.variant] = {TargetLength = 100, Vulnerability = 0.15}
    },
    [REVEL.ENT.DUNGO.id] = { -- dungo has a quarter, each boulder (red and normal) has a sixth
        [REVEL.ENT.DUNGO.variant] = {TargetLength = 40, Vulnerability = 0.5}
    },
    [REVEL.ENT.RAGTIME.id] = { -- split between phases
        [REVEL.ENT.RAGTIME.variant] = {TargetLength = 40, Vulnerability = 0.35}
    },

    -- Prank (same type)
    [REVEL.ENT.PRANK_GLACIER.id] = {
        [REVEL.ENT.PRANK_GLACIER.variant] = {TargetLength = 120, Vulnerability = 0.45},
        [REVEL.ENT.PRANK_TOMB.variant] = {TargetLength = 120, Vulnerability = 0.45}
    }
}

end