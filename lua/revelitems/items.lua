local SubModules = {
    'lua.revelitems.actives.cardboard_robot',
    'lua.revelitems.actives.chum_bucket',
    'lua.revelitems.actives.dramamine',
    'lua.revelitems.actives.ghastly_flame',
    'lua.revelitems.actives.gluttons_gut',
    'lua.revelitems.actives.half_chewed_pony',
    'lua.revelitems.actives.hyper_dice',
    'lua.revelitems.actives.monolith',
    'lua.revelitems.actives.moxies_paw',
    'lua.revelitems.actives.moxies_yarn',
    'lua.revelitems.actives.music_box',
    'lua.revelitems.actives.oops',
    'lua.revelitems.actives.super_meat_blade',
    'lua.revelitems.actives.wakawaka',

    'lua.revelitems.familiars.bandage_baby',
    'lua.revelitems.familiars.bargainers_burden',
    'lua.revelitems.familiars.cursed_grail',
    'lua.revelitems.familiars.envys_enmity',
    'lua.revelitems.familiars.hungry_grub',
    'lua.revelitems.familiars.lil_belial',
    'lua.revelitems.familiars.lil_frider',
    'lua.revelitems.familiars.lil_michael',
    'lua.revelitems.familiars.mirror_fragment',
    'lua.revelitems.familiars.mirror_shard',
    'lua.revelitems.familiars.ophanim',
    'lua.revelitems.familiars.virgil',
    'lua.revelitems.familiars.willo',

    'lua.revelitems.passives.addict',
    'lua.revelitems.passives.aegis',
    'lua.revelitems.passives.birthday_candle',
    'lua.revelitems.passives.birth_control',
    'lua.revelitems.passives.burningbush',
    'lua.revelitems.passives.cabbage_patch',
    'lua.revelitems.passives.cotton_stick',
    'lua.revelitems.passives.death_mask',
    'lua.revelitems.passives.dynamo',
    'lua.revelitems.passives.fecal_freak',
    'lua.revelitems.passives.ferrymans_toll',
    'lua.revelitems.passives.friendly_fire',
    'lua.revelitems.passives.geode',
    'lua.revelitems.passives.haphephobia',
    'lua.revelitems.passives.heavenly_bell',
    'lua.revelitems.passives.ice_tray',
    'lua.revelitems.passives.lovers_libido',
    'lua.revelitems.passives.mint_gum',
    'lua.revelitems.passives.mirror_bombs',
    'lua.revelitems.passives.not_a_bullet',
    -- 'lua.revelitems.passives.penance_old',
    'lua.revelitems.passives.perseverance',
    'lua.revelitems.passives.pilgrims_ward',
    -- 'lua.revelitems.passives.pool_noodle',
    'lua.revelitems.passives.prescription',
    'lua.revelitems.passives.prides_posturing',
    'lua.revelitems.passives.sloths_saddle',
    'lua.revelitems.passives.spirit_patience',
    'lua.revelitems.passives.sponge_bombs',
    'lua.revelitems.passives.tummy_bug',
    'lua.revelitems.passives.wandering_soul',
    'lua.revelitems.passives.window_cleaner',
    'lua.revelitems.passives.wraths_rage',

    'lua.revelitems.pocketitems.lottery_ticket',
    'lua.revelitems.pocketitems.bell_shard',

    'lua.revelitems.trinkets.archaeology',
    'lua.revelitems.trinkets.gag_reflex',
    'lua.revelitems.trinkets.library_card',
    'lua.revelitems.trinkets.maxwells_horn',
    'lua.revelitems.trinkets.memory_cap',
    'lua.revelitems.trinkets.scratched_sack',
    'lua.revelitems.trinkets.spare_change',
    'lua.revelitems.trinkets.telescope',
    'lua.revelitems.trinkets.christmas_stocking',
}

local SubLoadFunctions = REVEL.LoadModulesFromTable(SubModules)

return function()

    --Pocket items pool
    do
        REVEL.CardPool = {
            REVEL.POCKETITEM.LOTTERY_TICKET.Id,
            REVEL.POCKETITEM.BELL_SHARD.Id,
        }
        REVEL.RunesPool = {
        
        }
        
        revel:AddCallback(ModCallbacks.MC_GET_CARD, function(_, rng, CurrentCard, Playing, Runes, OnlyRunes)
            local pool = REVEL.CardPool
            if OnlyRunes then pool = REVEL.RunesPool end
            local rollA = rng:RandomInt(#pool+Card.NUM_CARDS) + 1
            local rollB = rng:RandomInt(#pool) + 1
            if rollA > Card.NUM_CARDS then
                return pool[rollB]
            end
        end)
    end

    -- Pocket items announcer
    do
        local AnnouncerVoideMode = {
            RANDOM = 0,
            OFF = 1,
            ALWAYS = 2,
        }
        for _, item in pairs(REVEL.POCKETITEM) do
            if item.Announcer then
                revel:AddCallback(ModCallbacks.MC_USE_CARD, function(_, cardID, player, useFlags)
                    if Options.AnnouncerVoiceMode == AnnouncerVoideMode.ALWAYS
                    or Options.AnnouncerVoiceMode == AnnouncerVoideMode.RANDOM and math.random() < 0.5
                    then
                        REVEL.sfx:Play(item.Announcer)
                    end
                end, item.Id)
            end
        end
    end
    
    REVEL.RunLoadFunctions(SubLoadFunctions)

    Isaac.DebugString("Revelations: Loaded Items!")
end