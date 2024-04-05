return function ()

REVEL.MUSIC = {
    -- Music
    TRANSITION = Isaac.GetMusicIdByName("Transition Stinger"),
    WIND = Isaac.GetMusicIdByName("AmbientWind"),
    SIN = {
        SLOTH = Isaac.GetMusicIdByName("Sloth Sin"),
        ENVY = Isaac.GetMusicIdByName("Envy Sin"),
        GLUTTONY = Isaac.GetMusicIdByName("Gluttony Sin"),
        GREED = Isaac.GetMusicIdByName("Greed Sin"),
        LUST = Isaac.GetMusicIdByName("Lust Sin"),
        PRIDE = Isaac.GetMusicIdByName("Pride Sin"),
        WRATH = Isaac.GetMusicIdByName("Wrath Sin"),
        ALL = Isaac.GetMusicIdByName("All Sins")
    },

    HUB_ROOM = Isaac.GetMusicIdByName("Revelations Hub Room"),
    HUB_ROOM_STINGER = Isaac.GetMusicIdByName("Revelations Hub Room Stinger"),
    VANITY_SHOP = Isaac.GetMusicIdByName("Revelations Vanity Bazaar"),
    VANITY_CASINO = Isaac.GetMusicIdByName("Revelations Vanity Casino"),
    SPECIAL_NARC_REWARD_JINGLE = Isaac.GetMusicIdByName("Revelations Special Narc Reward"),

    -- Vanilla replacement
    SHOP = Isaac.GetMusicIdByName("Revelations Shop"),
    SECRET = Isaac.GetMusicIdByName("Revelations Secret Room"),
    SECRET_JINGLE = Isaac.GetMusicIdByName("Revelations Secret Room Jingle"),
    CHALLENGE = Isaac.GetMusicIdByName("Revelations Challenge Room"),
    CHALLENGE_END = Isaac.GetMusicIdByName("Revelations Challenge Room End"),
    BOSS_CALM = Isaac.GetMusicIdByName("Revelations Boss Calm"),
    TREASURE = {
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 1"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 2"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 3"),
        Isaac.GetMusicIdByName("Revelations Item Room Jingle 4"),
    },

    BLANK_MUSIC = Isaac.GetMusicIdByName("blank"),

    GLACIER = Isaac.GetMusicIdByName("Glacier"),
    GLACIER_BOSS = Isaac.GetMusicIdByName("Glacier Boss"),
    GLACIER_BOSS_INTRO = Isaac.GetMusicIdByName("Glacier Boss Intro"),
    GLACIER_BOSS_OUTRO = Isaac.GetMusicIdByName("Glacier Boss Outro"),
    MIRROR_BOSS_JINGLE = Isaac.GetMusicIdByName("Mirror Boss Jingle"),
    MIRROR_BOSS_NOINTRO = Isaac.GetMusicIdByName("Mirror Boss No Intro"),
    MIRROR_BOSS = Isaac.GetMusicIdByName("Mirror Boss"),
    MIRROR_BOSS_OUTRO = Isaac.GetMusicIdByName("Mirror Boss Outro"),
    MIRROR_DOOR_OPENS = Isaac.GetMusicIdByName("Mirror Door Opens"),
    GLACIER_ENTRANCE = Isaac.GetMusicIdByName("Glacier Entrance"),
    ELITE1 = Isaac.GetMusicIdByName("Glacier Elite"),

    TOMB = Isaac.GetMusicIdByName("Tomb"),
    TOMB_BOSS = Isaac.GetMusicIdByName("Tomb Boss"),
    TOMB_BOSS_INTRO = Isaac.GetMusicIdByName("Tomb Boss Intro"),
    TOMB_BOSS_OUTRO = Isaac.GetMusicIdByName("Tomb Boss Outro"),
    TOMB_ENTRANCE = Isaac.GetMusicIdByName("Tomb Entrance"),

    MIRROR_BOSS_2 = Isaac.GetMusicIdByName("Mirror Boss 2"),
    MIRROR_BOSS_2_NOINTRO = Isaac.GetMusicIdByName("Mirror Boss 2 No Intro"),
    MIRROR_BOSS_2_OUTRO = Isaac.GetMusicIdByName("Mirror Boss 2 Outro"),

    ELITE2 = Isaac.GetMusicIdByName("Tomb Elite"),
    ELITE_RAGTIME = REVEL.GetMusicAndCues("Tomb Elite Ragtime", "revel2.tomb_elite_boss_ragtime"),
}

StageAPI.StopOverridingMusic(REVEL.MUSIC.HUB_ROOM_STINGER)
StageAPI.StopOverridingMusic(REVEL.MUSIC.HUB_ROOM)
StageAPI.StopOverridingMusic(REVEL.MUSIC.SECRET_JINGLE)

StageAPI.StopOverridingMusic(REVEL.MUSIC.MIRROR_DOOR_OPENS)
StageAPI.StopOverridingMusic(REVEL.MUSIC.MIRROR_BOSS_OUTRO)
StageAPI.StopOverridingMusic(REVEL.MUSIC.MIRROR_BOSS_JINGLE)

StageAPI.StopOverridingMusic(REVEL.MUSIC.MIRROR_BOSS_2_OUTRO)
    
    
end