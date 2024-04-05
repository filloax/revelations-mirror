return function ()

---@type table<string, RevItemDef|RevTrinketDef>
REVEL.ITEM = {
    -- Passive --
    HEAVENLY_BELL = REVEL.registerItem(1, "Heavenly Bell"),
    MINT_GUM = REVEL.registerItem(2, "Mint Gum", nil, nil, 1),
    FECAL_FREAK = REVEL.registerItem(3, "Fecal Freak", nil, nil, 1),
    LIL_BELIAL = REVEL.registerItem(4, "Lil Belial", nil),
    AEGIS = REVEL.registerItem(5, "Aegis", nil, nil, 1),
    BIRTHDAY_CANDLE = REVEL.registerItem(6, "Birthday Candle"),
    DYNAMO = REVEL.registerItem(7, "Dynamo", "gfx/characters/revelcommon/dynamo.anm2", nil, 1),
    BURNBUSH = REVEL.registerItem(8, "Burning Bush", "gfx/characters/revelcommon/bbush_nofire.anm2", nil, 1),
    PENANCE = REVEL.registerItem(9, "Penance"),
    ICETRAY = REVEL.registerItem(10, "Ice Tray"),
    CLEANER = REVEL.registerItem(11, "Window Cleaner"),
    SPONGE = REVEL.registerItem(12, "Sponge Bombs"),
    PATIENCE = REVEL.registerItem(13, "Spirit of Patience", "gfx/characters/revelcommon/spiritofpatience.anm2", nil, 1),
    TAMPON = REVEL.registerItem(14, "Cotton Bud"),
    BCONTROL = REVEL.registerItem(15, "Birth Control"),
    TBUG = REVEL.registerItem(16, "Tummy Bug", nil, nil, 1),
    FFIRE = REVEL.registerItem(17, "Friendly Fire"),

    WANDERING_SOUL = REVEL.registerItem(22, "Wandering Soul", nil, nil, 1),
    CABBAGE_PATCH = REVEL.registerItem(23, "Cabbage Patch", nil, nil, 1),
    HAPHEPHOBIA = REVEL.registerItem(24, "Haphephobia"),
    FERRYMANS_TOLL = REVEL.registerItem(25, "Ferryman's Toll"),
    DEATH_MASK = REVEL.registerItem(26, "Death Mask"),
    MIRROR_BOMBS = REVEL.registerItem(27, "Mirror Bombs"),
    CHARONS_OAR = REVEL.registerItem(28, "Broken Oar", "gfx/characters/revelcommon/item_brokenoar.anm2"),
    PERSEVERANCE = REVEL.registerItem(29, "Perseverance", nil, nil, 1),
    ADDICT = REVEL.registerItem(30, "Addict"),
    OPHANIM = REVEL.registerItem(31, "Ophanim", nil, nil, 1),
    PILGRIMS_WARD = REVEL.registerItem(32, "Pilgrim's Ward", nil, nil, 1),
    WRATHS_RAGE = REVEL.registerItem(33, "Wrath's Rage", "gfx/characters/revelcommon/item_wrathsrage1.anm2"),
    PRIDES_POSTURING = REVEL.registerItem(34, "Pride's Posturing"),
    SLOTHS_SADDLE = REVEL.registerItem(35, "Sloth's Saddle", nil, true),
    LOVERS_LIB = REVEL.registerItem(36, "Lover's Libido", nil, true),
    PRESCRIPTION = REVEL.registerItem(65, "Prescription", nil),
	GEODE = REVEL.registerItem(66, "Geode", nil),
	NOT_A_BULLET = REVEL.registerItem(67, "Not a Bullet", nil),
    
	-- Active --
    MONOLITH = REVEL.registerItem(18, "The Monolith", nil),
    HYPER_DICE = REVEL.registerItem(19, "Hyper Dice", nil, true),

    CHUM = REVEL.registerItem(37, "Chum Bucket", nil),
    ROBOT = REVEL.registerItem(38, "Cardboard Robot", nil),
    ROBOT2 = REVEL.registerItem(39, "Cardboard Robot (flipped)", nil, true),
    GFLAME = REVEL.registerItem(40, "Ghastly Flame", nil),
    GFLAME2 = REVEL.registerItem(41, "Ghastly Flame (lit)", nil, true),
    --PHYLACTERY_OLD = REVEL.registerItem("Phylactery Old", nil, true),
    PHYLACTERY = REVEL.registerItem(42, "Phylactery", nil, true),
    PHYLACTERY_MERGED = REVEL.registerItem(43, "Phylactery ", nil, true),
    PHYLACTERY_PICKUP_ITEM = REVEL.registerItem(44, "Phylactery  ", nil, true),
    PHYLACTERY_PICKUP_ITEM_CHARGE = REVEL.registerItem(45, "Phylactery   ", nil, true),
    WAKA_WAKA = REVEL.registerItem(46, "Waka Waka", nil),
    OOPS = REVEL.registerItem(47, "Oops!", nil),
    GUT = REVEL.registerItem(48, "Glutton's Gut", "gfx/characters/revelcommon/item_gluttonsgut_normal.anm2", true),
    MOXIE = REVEL.registerItem(49, "Moxie's Paw", nil),
    MUSIC_BOX = REVEL.registerItem(50, "Music Box", nil),
    HALF_CHEWED_PONY = REVEL.registerItem(51, "Half Chewed Pony", nil, true),
    MOXIE_YARN = REVEL.registerItem(52, "Moxie's Yarn", nil),

    SMBLADE_UNUSED = REVEL.registerItem(64, "Super Meat Blade", "gfx/characters/revelcommon/costume_supermeatblade.anm2"),
    SMBLADE = REVEL.registerItem(63, "Super Meat Blade ", "gfx/characters/revelcommon/costume_supermeatblade.anm2"),
	DRAMAMINE = REVEL.registerItem(62, "Dramamine", nil),
    
	-- Familiar --
    MIRROR = REVEL.registerItem(20, "Mirror Shard", nil, true),
    LIL_FRIDER = REVEL.registerItem(21, "Lil Frost Rider", nil, true),

    VIRGIL = REVEL.registerItem(53, "Virgil", nil),
    MIRROR2 = REVEL.registerItem(54, "Mirror Fragment", nil, true),
    CURSED_GRAIL = REVEL.registerItem(55, "Cursed Grail", nil),
    BANDAGE_BABY = REVEL.registerItem(56, "Bandage Baby", nil, nil, 1),
    LIL_MICHAEL = REVEL.registerItem(57, "Lil Michael", nil, nil, 1),
    HUNGRY_GRUB = REVEL.registerItem(58, "Hungry Grub", nil, nil, 1),
    ENVYS_ENMITY = REVEL.registerItem(59, "Envy's Enmity", nil, nil, 1),
    BARG_BURD = REVEL.registerItem(60, "Bargainer's Burden", nil, nil, 1),
    WILLO = REVEL.registerItem(61, "Willo", nil),

    -- Trinket --
    SPARE_CHANGE = REVEL.registerTrinket(1, "Spare Change", nil),
    LIBRARY_CARD = REVEL.registerTrinket(2, "Library Card", nil),
    ARCHAEOLOGY = REVEL.registerTrinket(3, "Archaeology", nil),
    GAGREFLEX = REVEL.registerTrinket(4, "Gag Reflex", nil),

    TELESCOPE = REVEL.registerTrinket(5, "Telescope", nil),
    SCRATCHED_SACK = REVEL.registerTrinket(6, "Scratched Sack", nil),
    MAX_HORN = REVEL.registerTrinket(7, "Maxwell's Horn", nil),
    MEMORY_CAP = REVEL.registerTrinket(8, "Memory Cap", nil),
    -- why is it shortened to Xmas in english anyways
    XMAS_STOCKING = REVEL.registerTrinket(9, "Christmas Stocking", nil),
}
    
end