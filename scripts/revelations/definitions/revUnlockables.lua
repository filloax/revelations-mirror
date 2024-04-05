return function ()

REVEL.UNLOCKABLES = {
    PENANCE = REVEL.unlockable("revel1/penance.png", REVEL.ITEM.PENANCE.id, "sarah vs mom", "penance"),
    HEAVENLY_BELL = REVEL.unlockable("revel1/heavenly_bell.png", REVEL.ITEM.HEAVENLY_BELL.id, "sarah vs the lamb", "heavenly bell"),
    ICETRAY = REVEL.unlockable("revel1/ice_tray.png", REVEL.ITEM.ICETRAY.id, "beat glacier", "ice tray"),
    GLACIER_CHAMPIONS = REVEL.unlockable("revel1/glacier_champions.png", nil, "beat glacier bosses", "champions", {sprite = "gfx/ui/achievement/revel1/glacier_champions_icon.png", width = 37, height = 35, scaleX = 2, scaleY = 2}),

    BANDAGE_BABY = REVEL.unlockable("revel2/bandage_baby.png", REVEL.ITEM.BANDAGE_BABY.id, "beat tomb", "bandage baby"),
    BROKEN_OAR = REVEL.unlockable("revel2/broken_oar.png", REVEL.ITEM.CHARONS_OAR.id, "dante vs mom", "broken oar"),
    DEATH_MASK = REVEL.unlockable("revel2/death_mask.png", REVEL.ITEM.DEATH_MASK.id, "dante vs mom's heart", "death mask"),
    OPHANIM = REVEL.unlockable("revel2/ophanim.png", REVEL.ITEM.OPHANIM.id, "sarah vs mom's heart", "ophanim"),
    LIL_MICHAEL = REVEL.unlockable("revel2/lil_michael.png", REVEL.ITEM.LIL_MICHAEL.id, "sarah vs hush", "lil michael"),
    PILGRIMS_WARD = REVEL.unlockable("revel2/pilgrims_ward.png", REVEL.ITEM.PILGRIMS_WARD.id, "sarah vs ???", "pilgrim's ward"),
    FERRYMANS_TOLL = REVEL.unlockable("revel2/ferrymans_toll.png", REVEL.ITEM.FERRYMANS_TOLL.id, "dante vs ???", "ferryman's toll"),
    GHASTLY_FLAME = REVEL.unlockable("revel2/ghastly_flame.png", REVEL.ITEM.GFLAME.id, "dante vs the lamb", "ghastly flame"),
    WANDERING_SOUL = REVEL.unlockable("revel2/wandering_soul.png", REVEL.ITEM.WANDERING_SOUL.id, "dante vs hush", "wandering soul"),
    MIRROR_BOMBS = REVEL.unlockable("revel2/mirror_bombs.png", REVEL.ITEM.MIRROR_BOMBS.id, "beat my reflection", "mirror bombs"),
    MAX_HORN = REVEL.unlockable("revel2/maxwells_horn.png", REVEL.ITEM.MAX_HORN.id, "beat craxwell", "maxwell's horn", nil, true),
    WILLO = REVEL.unlockable("revel2/willo.png", REVEL.ITEM.WILLO.id, "choose radiance", "willo"),

    TOMB_CHAMPIONS = REVEL.unlockable("revel2/tombchampion.png", nil, "beat tomb bosses", "champions", {sprite = "gfx/ui/achievement/revel2/tomb_champions_icon.png", width = 34, height = 30, scaleX = 2, scaleY = 2}),
}
    
end