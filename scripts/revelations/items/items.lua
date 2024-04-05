local SubModules = REVEL.PrefixAll("scripts.revelations.items.", {
    'actives.cardboard_robot',
    'actives.chum_bucket',
    'actives.dramamine',
    'actives.ghastly_flame',
    'actives.gluttons_gut',
    'actives.half_chewed_pony',
    'actives.hyper_dice',
    'actives.monolith',
    'actives.moxies_paw',
    'actives.moxies_yarn',
    'actives.music_box',
    'actives.oops',
    'actives.super_meat_blade',
    'actives.wakawaka',

    'familiars.bandage_baby',
    'familiars.bargainers_burden',
    'familiars.cursed_grail',
    'familiars.envys_enmity',
    'familiars.hungry_grub',
    'familiars.lil_belial',
    'familiars.lil_frider',
    'familiars.lil_michael',
    'familiars.mirror_fragment',
    'familiars.mirror_shard',
    'familiars.ophanim',
    'familiars.virgil',
    'familiars.willo',

    'passives.addict',
    'passives.aegis',
    'passives.birthday_candle',
    'passives.birth_control',
    'passives.burningbush',
    'passives.cabbage_patch',
    'passives.cotton_stick',
    'passives.death_mask',
    'passives.dynamo',
    'passives.fecal_freak',
    'passives.ferrymans_toll',
    'passives.friendly_fire',
    'passives.geode',
    'passives.haphephobia',
    'passives.heavenly_bell',
    'passives.ice_tray',
    'passives.lovers_libido',
    'passives.mint_gum',
    'passives.mirror_bombs',
    'passives.not_a_bullet',
    -- 'passives.penance_old',
    'passives.perseverance',
    'passives.pilgrims_ward',
    -- 'passives.pool_noodle',
    'passives.prescription',
    'passives.prides_posturing',
    'passives.sloths_saddle',
    'passives.spirit_patience',
    'passives.sponge_bombs',
    'passives.tummy_bug',
    'passives.wandering_soul',
    'passives.window_cleaner',
    'passives.wraths_rage',

    'pocketitems.lottery_ticket',
    'pocketitems.bell_shard',

    'trinkets.archaeology',
    'trinkets.gag_reflex',
    'trinkets.library_card',
    'trinkets.maxwells_horn',
    'trinkets.memory_cap',
    'trinkets.scratched_sack',
    'trinkets.spare_change',
    'trinkets.telescope',
    'trinkets.christmas_stocking',
})

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