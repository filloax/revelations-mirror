return function()
    --------------------------------
    -- External Item Descriptions --
    --------------------------------

    function REVEL.LoadEID()
        -- Fix EID detecting the inner mods (DSS, Hub 2, etc) names
        local prevCurrentMod = EID._currentMod
        EID._currentMod = "Revelations"

        -- Chapter 1

        EID:addCollectible(REVEL.ITEM.HEAVENLY_BELL.id, "Gives a random effect each floor:#All secret rooms have items#Always spawn items when destroying machines##Always spawn dimes when destroying machines#3 pedestals options on bosses, only activates with no damage taken#On death, respawn as blue baby#Crawlspace always under shopkeeper")
        EID:addCollectible(REVEL.ITEM.MINT_GUM.id, "Tears slow enemies#Enemies that are hit five times in a row get frozen")
        EID:addCollectible(REVEL.ITEM.FECAL_FREAK.id, "Tear keys reversed#↑ {{Damage}} +50% Damage multiplier#↑ {{Damage}} +1.5 Damage up#↓ {{Range}} -25% Range multiplier#↓ {{Shotspeed}} -25% ShotSpeed multiplier")
        EID:addCollectible(REVEL.ITEM.LIL_BELIAL.id, "Targets enemies#Slows targeted enemies#If targeted enemies are killed in order, drops a card")
        EID:addCollectible(REVEL.ITEM.AEGIS.id, "Grants a shield that blocks shots from behind")
        EID:addCollectible(REVEL.ITEM.BIRTHDAY_CANDLE.id, "Drops a pickup that Isaac is missing#If birthday candle has nothing to give, grants an all stats up instead")
        EID:addCollectible(REVEL.ITEM.DYNAMO.id, "Charge attack that unleashes beams of energy in random directions")
        EID:addCollectible(REVEL.ITEM.BURNBUSH.id, "Flamethrower. Throws flames.")
        EID:addCollectible(REVEL.ITEM.PENANCE.id, "Black hearts transform into demons when damaged#A broken winged angel appears in angel rooms#Black hearts can be traded for rewards")
        EID:addCollectible(REVEL.ITEM.ICETRAY.id, "Fire ice cubes that slide on the ground#Ice cubes leave creep")
        EID:addCollectible(REVEL.ITEM.CLEANER.id, "Tears remove enemy creep#↑ {{Tears}} +1 Fire Rate up")
        EID:addCollectible(REVEL.ITEM.SPONGE.id, "{{Bomb}} +5 Bombs#Bombs absorb tears#Bombs get damage up when absorbing tears")
        EID:addCollectible(REVEL.ITEM.PATIENCE.id, "Standing still fires a blue laser that targets enemies")
        EID:addCollectible(REVEL.ITEM.TAMPON.id, "Absorb creep by walking through it#Absorbing creep decreases tear delay")
        EID:addCollectible(REVEL.ITEM.BCONTROL.id, "All familiars will be consumed and replaced with a damage up#Certain familiars may grant you special effects when consumed#This applies to all familiars you currently have")
        EID:addCollectible(REVEL.ITEM.TBUG.id, "Isaac will occasionally stop firing to release a spray of tears at a high arc")
        EID:addCollectible(REVEL.ITEM.FFIRE.id, "Fire immunity#Fires now shoot at enemies instead of the player#Red fires appear more often")
        EID:addCollectible(REVEL.ITEM.MONOLITH.id, "Places a monolith on the ground#Tears that pass through it will split into three")
        EID:addCollectible(REVEL.ITEM.HYPER_DICE.id, "Rerolls special room layouts#Using it has a small chance to eventually destroy and corrupt the die")
        EID:addCollectible(REVEL.ITEM.MIRROR.id, "Orbital that reflects projectiles at 2x speed#Applies bleed on contact")
        
        EID:addCollectible(REVEL.ITEM.SMBLADE_UNUSED.id, "Throws a sawblade that runs along walls#Lets any active sawblades jump to the opposite wall#Sawblades also hurt players")
        EID:addCollectible(REVEL.ITEM.SMBLADE.id, "Throws a sawblade that runs along walls#Lets any active sawblades jump to the opposite wall#Sawblades also hurt players")
        EID:addCollectible(REVEL.ITEM.PRESCRIPTION.id, "Drops a pill#Entering new rooms has a chance to use a pill that has been taken before")
        EID:addCollectible(REVEL.ITEM.GEODE.id, "Drops a rune#Any soul hearts dropped by tinted rocks are turned into runes instead")
        EID:addCollectible(REVEL.ITEM.NOT_A_BULLET.id, "↑ {{Shotspeed}} +0.2 Shotspeed#Damage up that scales with shotspeed")
        EID:addCollectible(REVEL.ITEM.DRAMAMINE.id, "Spawns a big stationary tear acting as landmine#Permanently floats and explodes on enemy contact#Synergizes with tear effects")
        
        EID:addTrinket(REVEL.ITEM.SPARE_CHANGE.id, "Drops a nickel when entering a shop#Drops 3 cents when entering an arcade#Drops a soul heart when entering a devil room")
        EID:addTrinket(REVEL.ITEM.LIBRARY_CARD.id, "Libraries can be entered for free")
        EID:addTrinket(REVEL.ITEM.ARCHAEOLOGY.id, "Pots, Mushrooms, Skulls, Polyps and Ice blocks are twice as likely to pay out with their drops when destroyed")
        EID:addTrinket(REVEL.ITEM.GAGREFLEX.id, "Taking a pill gives Isaac Ipecac for the room")
        EID:addTrinket(REVEL.ITEM.XMAS_STOCKING.id, "Chance for consumables to be replaced by the one you have less of#Can also replace hearts when at full health#Chance is 25%, and increases the higher the difference in amount is, up to 25%")
                
        -- Chapter 2
                
        EID:addCollectible(REVEL.ITEM.WANDERING_SOUL.id, "A ghost of a random character appears in every room#The ghost attacks enemies using the attacks of the ghost's character")
        EID:addCollectible(REVEL.ITEM.CABBAGE_PATCH.id, "Sprouts can appear in rooms#Watering sprouts will turn them into cabbage familiars#Cabbages come in many different flavors")
        EID:addCollectible(REVEL.ITEM.HAPHEPHOBIA.id, "While attacking, a ring will pulse from the player that pushes back enemies")
        EID:addCollectible(REVEL.ITEM.FERRYMANS_TOLL.id, "Spawns 2 random coins#Revives the player when they die at the cost of 33 coins#This price increases by 33 after every revival, maxing out at 99")
        EID:addCollectible(REVEL.ITEM.DEATH_MASK.id, "After 10 kills, a random enemy will be struck by lightning and converted into a friendly blue bony")
        EID:addCollectible(REVEL.ITEM.MIRROR_BOMBS.id, "{{Bomb}} +5 Bombs#Bombs have new unique effects based on the backdrop of the current room")
        EID:addCollectible(REVEL.ITEM.CHARONS_OAR.id, "Tears are replaced with a spread of tears of varying size and damage")
        EID:addCollectible(REVEL.ITEM.PERSEVERANCE.id, "Enemies take up to 2x more damage with consecutive hits#1.5x for bosses")
        EID:addCollectible(REVEL.ITEM.ADDICT.id, "Pill enemies will start spawning in rooms#These enemies will continue to increment until a pill is used#Angel pills drop good pills#Spider pills drop bad pills")
        EID:addCollectible(REVEL.ITEM.OPHANIM.id, "Grants a golden ring around the player that fires orbiting tears#Taking damage will make the ring bounce around the room until it rejoins you")
        EID:addCollectible(REVEL.ITEM.PILGRIMS_WARD.id, "A beam of light appears in uncleared rooms#Walking into the light will spawn a homing laser ring")
        EID:addCollectible(REVEL.ITEM.WRATHS_RAGE.id, "Bombs dropped by Isaac explode instantly#You don't take damage from your bomb explosions#Dropping bombs grants a damage bonus per room#")
        EID:addCollectible(REVEL.ITEM.PRIDES_POSTURING.id, "Firing for the first time in an uncleared room unleashes pride lasers#This also activates all of the players damage effects")
        EID:addCollectible(REVEL.ITEM.SLOTHS_SADDLE.id, "A small Sloth rests on the player's head#Speed Up in cleared rooms#A small maggot familiar spawns for every 10 damage dealt")
        EID:addCollectible(REVEL.ITEM.LOVERS_LIB.id, "Item pedestals grow legs and run away from the player#Catching these item pedestals spawns a random trinket")

        EID:addCollectible(REVEL.ITEM.CHUM.id, "Enemies spawn piles of meat when killed#When used, all piles of meat fire tears at enemies")
        EID:addCollectible(REVEL.ITEM.ROBOT.id, "Gives the player a cardboard robot suit for a short time#The player fires a large amount of short range lasers#Isaac absorbs damage while in the suit")
        EID:addCollectible(REVEL.ITEM.GFLAME.id, "Fires a purple flame#If the flame kills an enemy, using the item again will summon a ghost friend.")
        EID:addCollectible(REVEL.ITEM.WAKA_WAKA.id, "Enemy tears transform into fruits that can be eaten#Cherries increase damage#Lemons increase range#Oranges increase shot speed#Bananas increase speed")
        EID:addCollectible(REVEL.ITEM.OOPS.id, "Disables traps and hazards#Blows up anything explosive in the room#May explode when spammed")
        EID:addCollectible(REVEL.ITEM.MOXIE.id, "Short-ranged swipe attack#Deals damage with high knockback")
        EID:addCollectible(REVEL.ITEM.MUSIC_BOX.id, "Spawns a music box which plays a random song#Lullaby: Enemies become sleepy#Hymn: Isaac gains speed and damage#Samba: Isaac gains tears and piercing shots#Metal: Enemies randomly attack each other")
        EID:addCollectible(REVEL.ITEM.HALF_CHEWED_PONY.id, "Pony item, grants flight when held#Spawns a friendly submerged antlion that sucks in and chomps on enemies#Has a small chance to consume the pony and turn the antlion into a permanent familiar")
        EID:addCollectible(REVEL.ITEM.MOXIE_YARN.id, "Throws a ball of yarn that summons a friendly Catastrophe cat.")
        EID:addCollectible(REVEL.ITEM.GUT.id, "Consumes nearby enemies and projectiles.#Throws a projectile that scales based on how many things you consumed.#Alternatively, You may swallow to heal a full heart.")

        EID:addCollectible(REVEL.ITEM.VIRGIL.id, "Grants a familiar which has many abilities:#-Guides the player to special rooms#-Throws rocks at tinted rocks#Pushes troll bombs away from Isaac#-Can revive Isaac once#-Baits enemies to target him by throwing rocks#If Isaac takes damage, Virgil confuses the enemy.")
        EID:addCollectible(REVEL.ITEM.MIRROR2.id, "Two mirror shards can be thrown#The shards will fire a laser between each other")
        EID:addCollectible(REVEL.ITEM.CURSED_GRAIL.id, "Grants a grail familiar which will fill itself with blood when a sacrifice room is used#Each fill permanently increases damage by 0.2#This maxes out at 6 fills, granting flight")
        EID:addCollectible(REVEL.ITEM.BANDAGE_BABY.id, "Grants an orbiting familiar which fires bandage balls#Bandage balls turn into a pile of rags that slow enemies#The familiar can block shots, but collapses into a pile of rags.")
        EID:addCollectible(REVEL.ITEM.LIL_MICHAEL.id, "Grants a familiar which absorbs any shots fired at him#After firing 20 tears, Lil Micheal will unleash 20 tears of damage to a nearby enemy")
        EID:addCollectible(REVEL.ITEM.HUNGRY_GRUB.id, "Grants a familiar which can be fired in a direction#Attaches to enemies and feasts on them#Eating enemies increases its size and damage")
        EID:addCollectible(REVEL.ITEM.ENVYS_ENMITY.id, "Grants an orbiting Envy head familiar#When hit, splits into smaller envy heads which orbit further and deal more damage")
        EID:addCollectible(REVEL.ITEM.BARG_BURD.id, "Grants a sack familiar which can be flung at enemies#Having more pickups will increase the amount of damage the sack does")
        EID:addCollectible(REVEL.ITEM.WILLO.id, "Grants a friendly Grill o Wisp#Staying in its aura grants stat bonuses#Fires a homing tear at enemies")

        EID:addTrinket(REVEL.ITEM.TELESCOPE.id, "Improves the effects of zodiac sign items")
        EID:addTrinket(REVEL.ITEM.SCRATCHED_SACK.id, "When a room is cleared without taking damage, there is a small chance for the rewards to be doubled")
        EID:addTrinket(REVEL.ITEM.MAX_HORN.id, "Using an active item will cause a boulder to fall")
        EID:addTrinket(REVEL.ITEM.MEMORY_CAP.id, "Enemies can randomly appear as black boxes#Touching a black box will turn you into a black box#You are invincible while black boxed")

        -- Pocket items

        EID:addCard(REVEL.POCKETITEM.LOTTERY_TICKET.Id, "Item pedestals will start cycling between multiple items from the same pool.")     
        EID:addCard(REVEL.POCKETITEM.BELL_SHARD.Id, "Gives a random effect from the Heavenly Bell item")

        -- Transformations
        EID:assignTransformation("collectible", REVEL.ITEM.HEAVENLY_BELL.id, EID.TRANSFORMATION.ANGEL)
        EID:assignTransformation("collectible", REVEL.ITEM.OPHANIM.id, EID.TRANSFORMATION.ANGEL)
        EID:assignTransformation("collectible", REVEL.ITEM.LIL_MICHAEL.id, EID.TRANSFORMATION.ANGEL .. "," ..EID.TRANSFORMATION.CONJOINED)
        EID:assignTransformation("collectible", REVEL.ITEM.PILGRIMS_WARD.id, EID.TRANSFORMATION.ANGEL)
        EID:assignTransformation("collectible", REVEL.ITEM.LIL_BELIAL.id, EID.TRANSFORMATION.LEVIATHAN .. "," .. EID.TRANSFORMATION.CONJOINED)
        EID:assignTransformation("collectible", REVEL.ITEM.BANDAGE_BABY.id, EID.TRANSFORMATION.CONJOINED)
        EID:assignTransformation("collectible", REVEL.ITEM.ADDICT.id, EID.TRANSFORMATION.SPUN)
        EID:assignTransformation("collectible", REVEL.ITEM.FECAL_FREAK.id, EID.TRANSFORMATION.POOP)
        EID:assignTransformation("collectible", REVEL.ITEM.TBUG.id, EID.TRANSFORMATION.SPIDERBABY)

        -- Birthright
        EID:addBirthright(
            REVEL.CHAR.CHARON.Type, 
            "3 items are shared between Dante and Charon#The items are randomly chosen when Dante and Charon split in a new stage", 
            "Dante and Charon"
        )
        EID:addBirthright(
            REVEL.CHAR.DANTE.Type, 
            "3 items are shared between Dante and Charon#The items are randomly chosen when Dante and Charon split in a new stage", 
            "Dante and Charon"
        )
        EID:addBirthright(
            REVEL.CHAR.SARAH.Type, 
            "Black hearts are removed one at a time when hit"
        )

        -- Italian translation (WIP)
        do
            -- Chapter 1

            EID:addCollectible(REVEL.ITEM.HEAVENLY_BELL.id, "Dà un effetto casuale ogni livello:#Ogni secret rooms ha oggetti#Trova sempre oggetti distruggento slot machine#Monete da 1¢ diventano da 5¢#3 oggetti a scelta dopo boss, solo se nessun danno preso#Rinasci come ??? (Blue Baby)#Il mercante lascia una botola se distrutto", "Campana Celestiale", "it")
            EID:addCollectible(REVEL.ITEM.MINT_GUM.id, "Le lacrime rallentano i nemici#5 colpi vicini congelano un nemico", "Gomma alla Menta", "it")
            EID:addCollectible(REVEL.ITEM.FECAL_FREAK.id, "Tasti di fuoco invertiti#+1.5 Danno Aumentato#+50% Moltiplicatore di Danno", "Follia Fecale", "it")
            EID:addCollectible(REVEL.ITEM.LIL_BELIAL.id, "Bersaglia un nemico#Rallenta il nemico bersagliato#Se i nemici bersagliati sono uccisi in ordine, lascia una carta", "Piccolo Belial", "it")
            EID:addCollectible(REVEL.ITEM.AEGIS.id, "Scudo che fluttua dietro Isaac#Blocca ogni colpo", nil, "it")
            EID:addCollectible(REVEL.ITEM.BIRTHDAY_CANDLE.id, "Drops a pickup that Isaac is missing#If birthday candle has nothing to give, grants an all stats up instead", nil, "it")
            EID:addCollectible(REVEL.ITEM.DYNAMO.id, "Charge attack that unleashes beams of energy in random directions", nil, "it")
            EID:addCollectible(REVEL.ITEM.BURNBUSH.id, "Flamethrower. Throws flames.", nil, "it")
            EID:addCollectible(REVEL.ITEM.PENANCE.id, "A unique Angel Room appears after boss battles#Black Hearts can be given to the angel in this room for rewards#Upon taking damage, black hearts leave your health and become demons which charge into you until you clear the room.", nil, "it")
            EID:addCollectible(REVEL.ITEM.ICETRAY.id, "Fire ice cubes that slide on the ground#ice cubes leave creep", nil, "it")
            EID:addCollectible(REVEL.ITEM.CLEANER.id, "Tears remove enemy creep", nil, "it")
            EID:addCollectible(REVEL.ITEM.SPONGE.id, "Bombs absorb tears#Bombs get damage up when absorbing tears", nil, "it")
            EID:addCollectible(REVEL.ITEM.PATIENCE.id, "Fires blue laser every 0.3 seconds when standing still", nil, "it")
            EID:addCollectible(REVEL.ITEM.TAMPON.id, "Absorb creep by walking through it#Absorbing creep decreases tear delay", nil, "it")
            EID:addCollectible(REVEL.ITEM.BCONTROL.id, "Familiars are comsumed and replaced with a Damage up", nil, "it")
            EID:addCollectible(REVEL.ITEM.TBUG.id, "Isaac sometimes stops firing, followed by a brief charge#When charge is released fires a spray of tears on a high arc", nil, "it")
            EID:addCollectible(REVEL.ITEM.FFIRE.id, "Fire immunity#Fires now shoot at enemies instead of the player#", nil, "it")
            EID:addCollectible(REVEL.ITEM.MONOLITH.id, "Places a monolith on the ground#Tears that pass through it will split into three", nil, "it")
            EID:addCollectible(REVEL.ITEM.HYPER_DICE.id, "Rerolls special room layouts", nil, "it")
            EID:addCollectible(REVEL.ITEM.MIRROR.id, "Orbital that reflects projectiles at 2x speed#Gives blood collision damage", nil, "it")
            
            EID:addCollectible(REVEL.ITEM.SMBLADE_UNUSED.id, "Throws a sawblade that runs along walls#Lets any active sawblades jump to the opposite wall#Sawblades also hurt players", nil, "it")
            EID:addCollectible(REVEL.ITEM.SMBLADE.id, "Throws a sawblade that runs along walls#Lets any active sawblades jump to the opposite wall#Sawblades also hurt players", nil, "it")
            EID:addCollectible(REVEL.ITEM.PRESCRIPTION.id, "Small chance upon new room enter to proc one of your previously used pills again#Positive pills have a slightly higher chance to proc again", nil, "it")
            EID:addCollectible(REVEL.ITEM.GEODE.id, "Any soul hearts dropped by tinted rocks are turned into runes instead", nil, "it")
            EID:addCollectible(REVEL.ITEM.NOT_A_BULLET.id, "+0.2 Shotspeed#Damage up that scales with shotspeed", nil, "it")
            EID:addCollectible(REVEL.ITEM.DRAMAMINE.id, "Spawns a big stationary tear acting as landmine#Permanently floats and explodes on enemy contact#Synergizes with tear effects", nil, "it")
            
            EID:addTrinket(REVEL.ITEM.SPARE_CHANGE.id, "Drops a nickel when entering a shop#Drops 3 cents when entering an arcade#Drops a soul heart when entering a devil room", nil, "it")
            EID:addTrinket(REVEL.ITEM.LIBRARY_CARD.id, "Libraries can be entered for free", nil, "it")
            EID:addTrinket(REVEL.ITEM.ARCHAEOLOGY.id, "Pots, Mushrooms, Skulls, Polyps and Ice blocks are twice as likely to pay out with their drops when destroyed", nil, "it")
            EID:addTrinket(REVEL.ITEM.GAGREFLEX.id, "Taking a pill gives Isaac Ipecac for the room", nil, "it")
                        
            -- Chapter 2
                    
            EID:addCollectible(REVEL.ITEM.WANDERING_SOUL.id, "A ghost of a random character appears in every room#The ghost attacks enemies using the attacks of the ghost's character", nil, "it")
            EID:addCollectible(REVEL.ITEM.CABBAGE_PATCH.id, "Sprouts appear in every room and can be grown into cabbages by attacking them#Cabbages attack enemies and die after doing enough attacks", nil, "it")
            EID:addCollectible(REVEL.ITEM.HAPHEPHOBIA.id, "When attacking, a shockwave appears which pushes back nearby enemies", nil, "it")
            EID:addCollectible(REVEL.ITEM.FERRYMANS_TOLL.id, "Spawns 2 random coins#Revives the player when they die at the cost of 33 coins#This price increases by 33 after every revival, maxing out at 99", nil, "it")
            EID:addCollectible(REVEL.ITEM.DEATH_MASK.id, "After 10 kills a random enemy will be struck by lightning and converted into a friendly blue bony", nil, "it")
            EID:addCollectible(REVEL.ITEM.MIRROR_BOMBS.id, "+5 Bombs#Bombs have new unique effects based on the backdrop of the current room", nil, "it")
            EID:addCollectible(REVEL.ITEM.CHARONS_OAR.id, "Tears are replaced with a spread of tears", nil, "it")
            EID:addCollectible(REVEL.ITEM.PERSEVERANCE.id, "Enemies take more damage with consecutive hits", nil, "it")
            EID:addCollectible(REVEL.ITEM.ADDICT.id, "Pill enemies will start spawning in rooms#These enemies will continue to increment until a pill is used#Angel pills drop good pills#Spider pills drop bad pills", nil, "it")
            EID:addCollectible(REVEL.ITEM.OPHANIM.id, "A ring around the player will fire swerving tears in the four cardinal directions as the player fire tears#When damaged, the ring detaches from the player and travels across the room while firing tears", nil, "it")
            EID:addCollectible(REVEL.ITEM.PILGRIMS_WARD.id, "A beam of light appears in uncleared rooms#Walking into the light will spawn a laser ring around it and will move the light to a different location", nil, "it")
            EID:addCollectible(REVEL.ITEM.WRATHS_RAGE.id, "Attempting to place a bomb will immediately spawn the explosion without hurting the player#Every time an explosion is spawned this way the player's damage increases", nil, "it")
            EID:addCollectible(REVEL.ITEM.PRIDES_POSTURING.id, "Attacking for the first time in a room will trigger all player damage effects the player has, and spawn pride lasers", nil, "it")
            EID:addCollectible(REVEL.ITEM.SLOTHS_SADDLE.id, "A small Sloth rests on the player's head#Speed Up in cleared rooms#For every 10 damage dealt, a small maggot familiar spawns", nil, "it")
            EID:addCollectible(REVEL.ITEM.LOVERS_LIB.id, "Item pedestals grow legs and run away from the player#Catching item pedestals spawns a random trinket", nil, "it")

            EID:addCollectible(REVEL.ITEM.CHUM.id, "Enemies spawn piles of meat when killed#When used, all piles of meat fire tears at enemies", nil, "it")
            EID:addCollectible(REVEL.ITEM.ROBOT.id, "When used, gives the player a cardboard robot suit for a short time#The player fires a large amount of short range lasers#The suit absorbs damage but decreases the amount of time in the suit#Clearing rooms increases the amount of time in the suit", nil, "it")
            EID:addCollectible(REVEL.ITEM.GFLAME.id, "Candle item which fires a purple flame#If the flame kills an enemy, the next time this item is used it will spawn a ghost familiar which chases enemies and spawns flames.", nil, "it")
            EID:addCollectible(REVEL.ITEM.WAKA_WAKA.id, "Enemy tears transform into fruits that can be eaten#Cherries increase damage#Lemons increase range#Oranges increase shot speed#Bananas increase speed", nil, "it")
            EID:addCollectible(REVEL.ITEM.OOPS.id, "Disables traps and hazards#Blows up anything explosive in the room#May explode when spammed", nil, "it")
            EID:addCollectible(REVEL.ITEM.MOXIE.id, "When used, bandages appear and swipes any nearby enemies and projectiles away, dealing damage to enemies", nil, "it")
            EID:addCollectible(REVEL.ITEM.MUSIC_BOX.id, "When used, spawns a music box which will play a random song out of four#Lullaby: Enemies slow down and fall asleep. Damaging enemies in this state will wake them up#Hymn: The player gains +1 speed and +2 damage#Samba: The player's tear delay decreases by 2 and gains piercing and spectral tears#Metal: Enemies randomly attack each other", nil, "it")
            EID:addCollectible(REVEL.ITEM.HALF_CHEWED_PONY.id, "Pony item, grants flight when held#When used, spawns a friendly submerged antlion which sucks in and eats nearby enemies#There is a small chance for this antlion to suck in the player's pony instead#After sucking in the pony, the antlion emerges from the ground and follows the player while attacking enemies#The emerged antlion returns every floor, even if it was killed", nil, "it")
            EID:addCollectible(REVEL.ITEM.MOXIE_YARN.id, "When used, a ball of yarn can be thrown#The yarn will summon a random friendly Catastrophe cat.", nil, "it")
            EID:addCollectible(REVEL.ITEM.GUT.id, "Consumes nearby enemies and projectiles.#Throws a projectile that scales based on how many things you consumed.#Alternatively, You may swallow to heal a full heart.", nil, "it")

            EID:addCollectible(REVEL.ITEM.VIRGIL.id, "Grants a familiar which has many abilities:#-Guides the player to treasure rooms, shops, and boss rooms#-Throws rocks at tinted rocks#Pushes troll bombs away from the player#-Revives the player if they died, this only happens once#-Throws rocks at enemies, which makes the enemy target Virgil#If the player takes damage, Virgil confuses the enemy.", nil, "it")
            EID:addCollectible(REVEL.ITEM.MIRROR2.id, "Two mirror shards can be thrown#The shards will fire a laser between each other", nil, "it")
            EID:addCollectible(REVEL.ITEM.CURSED_GRAIL.id, "Grants a grail familiar which will fill itself with blood when a sacrifice room is used#Each fill permanently increases damage by 0.2#This maxes out at 6 fills, totaling at 3 damage and granting flight", nil, "it")
            EID:addCollectible(REVEL.ITEM.BANDAGE_BABY.id, "Grants an orbiting familiar which fires bandage balls at enemies#When a bandage ball lands, it turns into a pile of rags which will slow enemies when walked on#The familiar can block shots, but collapses into a pile of rags.", nil, "it")
            EID:addCollectible(REVEL.ITEM.LIL_MICHAEL.id, "Grants a familiar which absorbs any shots fired at him#After firing 20 tears, Lil Micheal does the total sum amount of damage absorbed from the tears to a nearby enemy", nil, "it")
            EID:addCollectible(REVEL.ITEM.HUNGRY_GRUB.id, "Grants a following familiar which can be fired in a direction#When it hits an enemy it attaches to it and feasts on it#Once it is done, it increases in size and deals more damage", nil, "it")
            EID:addCollectible(REVEL.ITEM.ENVYS_ENMITY.id, "Grants an orbiting Envy head familiar#When it is attacked, it splits into smaller envy heads which orbit further and deal more damage", nil, "it")
            EID:addCollectible(REVEL.ITEM.BARG_BURD.id, "Grants a sack familiar which can be flung at enemies#Having more pickups will increase the amount of damage the sack does", nil, "it")
            EID:addCollectible(REVEL.ITEM.WILLO.id, "Grants a friendly Grill o Wisp#Staying in its aura grants stat bonuses#Fires a homing tear at enemies which attack the player", nil, "it")

            EID:addTrinket(REVEL.ITEM.TELESCOPE.id, "Improves the effects of zodiac sign items", nil, "it")
            EID:addTrinket(REVEL.ITEM.SCRATCHED_SACK.id, "When a room is cleared, there is a small chance for the rewards to be doubled#Rewards will not be doubled if damage was taken in the room", nil, "it")
            EID:addTrinket(REVEL.ITEM.MAX_HORN.id, "Using an active item will cause a boulder to fall", nil, "it")
            EID:addTrinket(REVEL.ITEM.MEMORY_CAP.id, "Enemies can randomly appear as black boxes#Touching a black box will turn you into a black box#You are invincible while black boxed", nil, "it")
        end

        EID._currentMod = prevCurrentMod
    end

    ---Returns item description usable inside data.EID_Description in entities
    ---@param collectibleType CollectibleType
    ---@return {Name: string, Description: string, Transformation?: string}
    function REVEL.GetEidItemDesc(collectibleType)
        local arrayData = EID:getDescriptionData(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibleType)
        return {
            Name = arrayData[2],
            Description = arrayData[3],
            -- Transformation = arrayData[4],
        }
    end

    function REVEL.GetEidTrinketDesc(trinketType)
        local arrayData = EID:getDescriptionData(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinketType)
        return {
            Name = arrayData[2],
            Description = arrayData[3],
            -- Transformation = arrayData[4],
        }
    end

    if EID then
        REVEL.LoadEID()
    else
        local function loadEID_PostGameStarted()
			if EID then
				REVEL.LoadEID()
			end
            revel:RemoveCallback(ModCallbacks.MC_POST_GAME_STARTED, loadEID_PostGameStarted)
        end

        revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, loadEID_PostGameStarted)
    end

    
    ------------------
    -- Encyclopedia --
    ------------------

    if Encyclopedia then
        
        -- trinkets
        
        local TrinketWiki = {
            SPARE_CHANGE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Spare Change is a trinket added in Revelations Chapter One. If held, the players gets a certain amount of items upon entering certain rooms."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon entering a shop, a nickel will drop on the floor"},
                    {str = "Upon entering an arcade, three pennies will drop on the floor"},
                    {str = "Upon entering a Devil Deal Room, a Soul Heart will drop on the floor"},
                },
            },
            LIBRARY_CARD = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Library Card is a trinket that, when held, grants free access to Libraries."},
                },
            },
            ARCHAEOLOGY = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Archaeology is a trinket added in Revelations Chapter One. When held, rocks, pots, mushrooms, skulls, polyps, and ice blocks are twice as likely to drop a collectible from their respective pools when broken."},
                },
            },
            GAGREFLEX = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Gag Reflex is a trinket added in Revelations Chapter One. While held, the player gains Ipecac for the room if they take any pill. The effect only lasts for the room the pill is taken in."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The item is helpful if you don't have any bombs, and have a spare pill lying around."},
                    {str = "The way the trinket works is by actually giving you the Ipecac item for the room when using a pill, so it will be visible on the My Items page on the pause menu, and it will also count towards a transformation."},
                },
            },
            TELESCOPE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Telescope is a trinket added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Boosts the effects of the constellation collectibles when held"},
                    {str = "Cancer: -2 Tear Rate"},
                    {str = "Gemini: After taking damage, Gemini detaches for the current room."},
                    {str = "Taurus: Removes the speed penalty."},
                    {str = "Scorpio: Enemies leave a pool of green creep when dying."},
                    {str = "Sagittarius: Tears increase in damage by 50% per enemy they pierce."},
                    {str = "Aries: Doubles the ramming damage."},
                    {str = "Leo: Running over rocks sends out tears in a + pattern."},
                    {str = "Pisces: Knock back is stronger."},
                    {str = "Aquarius: Increase all blue puddle sizes."},
                    {str = "Virgo: Book of shadows invulnerability each time the player is hit."},
                    {str = "Libra: 20% Chance when using a key to get a bomb, and vice versa."},
                    {str = "Capricorn: +1 Extra luck."},
                    {str = "Interactions"},
                    {str = "Zodiac: No effect."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "Zodiac: No effect."},
                },
                { -- interactions/notes
                    {str = "interactions/notes", fsize = 2, clr = 3, halign = 0},
                    {str = "the Cancer's effect grants the same effect as the Trinket with the same name"},
                    {str = "Aquarius' Effect Stacks with Lost_Cork"},
                    {str = "Capricorn turns into a true All-stats up, as originally, none of the all stats up in Isaac increase luck"},
                },
            },
            SCRATCHED_SACK = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Scratched Sack is a trinket added in Revelations Chapter Two. When held, there is a chance that pickups dropped upon clearing a room will be doubled."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The chance to double pickups is dependent on the Luck stat."},
                    {str = "Taking damage before clearing the room causes the rewards to not be doubled."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Contract From Below: Doubling effect compounds and has a chance of quadrupling reward pickups."},
                },
            },
            MAX_HORN = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Maxwell's Horn is a trinket added in Chapter 2's Sin Update. When held, a boulder will fall on a random enemy in the room when the player uses an active item."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The boulder will always do 41 damage."},
                    {str = "The trinket is unlocked when the player beats Champion Maxwell for the first time."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "The trinket's effect is based on Pact of Peril's old passive effect. The effect was depreciated, and became a trinket."},
                    {str = "The trinket's design is based on Champion Maxwell, who is missing his horns."},
                },
            },
            XMAS_STOCKING = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Christmas Stocking is a trinket added after the Vanity Update. When held, coins, keys and bombs are replaced by the one you have the lowest amount of."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Hearts can also be replaced if all players are at full health."},
                    {str = "The replacement chance starts at 25%, and increases the higher the difference in amount between your consumables is. It caps at 75% when the difference is 20 or more, for example if you have 26 coins, 25 keys, and 5 bombs."},
                },
            },
        }
        
        for name,desc in pairs(TrinketWiki) do
            Encyclopedia.AddTrinket({
                Class = "Revelations",
                ID = REVEL.ITEM[name].id,
                WikiDesc = desc
            })
        end
        
        -- items
        
        local ItemWiki = {
            HYPER_DICE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Hyper Dice is an activated collectible added in Revelations Chapter One. It is a die that only rerolls special rooms of the same type and shape. "},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Treasure Room: Hyper Dice rerolls treasure rooms into other treasure rooms. Another item will only be offered if there is an item on the pedestal. "},
                    {str = "Shop: Hyper Dice rerolls shops into other shops, with either more or less items for sale."},
                    {str = "Boss Room: Hyper Dice is able to reroll the Boss Room during a fight to change the boss, or after the fight to fight a different boss. If you fight the boss a second time, you will get another item drop regardless of picking up the original item or not."},
                    {str = "Sacrifice Rooms: Hyper Dice is able to reroll Sacrifice Rooms, but currently it removes the spike in the middle of the room."},
                    {str = "Challenge Rooms: Hyper Dice can reroll challenge rooms before, during, or after the fight. You only need to fight the room one time. If you complete the challenge room, you may reroll the room and take its new contents without having to face the challenge a second time. If you reroll during a fight, it will reroll the enemies and rewards, but the fight will still be going."},
                    {str = "Curse Rooms: Hyper Dice will reroll the contents of Curse Rooms."},
                    {str = "Dice Rooms: Hyper Dice does not reroll the dice shown on the floor, but will reroll any collectibles on the ground, and will spawn new ones if the originals are taken."},
                    {str = "Devil Deal Rooms: Hyper Dice rerolls items and collectibles for sale, regardless if they are taken. You cannot reroll a regular Devil Real Room into a Krampus fight."},
                    {str = "Angel Deal Rooms: Hyper Dice rerolls items and collectibles in the room. If you reroll the room before fighting the angel, you will not be able to blow up the statue unless you leave the room and re-enter. If you fight the angel and then reroll, a statue will not spawn unless you leave and re-enter the room."},
                    {str = "Miniboss Rooms: Hyper Dice rerolls these rooms, such as Sin Fight Rooms or Krampus Fight Rooms into other miniboss bossfights. You can reroll during the fight or after the fight. "},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Hyper Dice can only be used a certain amount of times. Starting at 0 and capping at 100, each time you use it, the counter will double in chance for the dice to ''corrupt''. When the dice corrupts, you will lose the dice and will either be teleported to the Error Room, or all of your held items will be rerolled."},
                    {str = "The maximum amount of times you can use Hyper Dice is eight times."},
                    {str = "If using Hyper Dice spawns enemies in the room, all doors will be closed unless you defeat all enemies."},
                    {str = "Hyper Dice can't reroll a special room into a different type of special room."},
                    {str = "It also cannot reroll a 1x1 room into a 2x2 room, or a 2x1 room."},
                    {str = "Hyper Dice cannot be used outside of special rooms."},
                    {str = "Hyper Dice is extremely helpful with getting Key Piece 1 and Key Piece 2 on the same floor, as you can reroll the Angel Deal Room and fight the angels however many times you are able to reroll."},
                    {str = "Before Hyper Dice ''corrupts'', using it has a chance to play noises with distorted pitches, shuffle your consumables, and darken, pixelate or shake the screen."},
                    {str = "Hyper Dice's corruption chance is not separate per dice. If you pick up a second dice (such as duping it with Crooked Penny) it will still retain the corruption chance the last dice had."},
                    {str = "Delirium is the only boss that can be found when rerolling 2x2 boss rooms. Rerolling Delirium's room will do nothing."},
                    {str = "Mom's Heart can appear in boss rooms even if It Lives is unlocked. This can happen on any floor."},
                    {str = "You cannot reroll Revelation's Mirror Room or Dante Satan Room."},
                    {str = "Rerolling Item Rooms, Shops, etc can spawn modded items."},
                    {str = "Modded bosses, however, cannot be rerolled from normal bosses."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            MONOLITH = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "The Monolith is an activated collectible added in Revelations Chapter One."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use places the Monolith on the ground, and any tears shot through it will split into three."},
                    {str = "Notes"},
                    {str = "Tears split into three will be colored pink."},
                    {str = "A sound will also play when tears split."},
                    {str = "The Monolith can split any kind of tears, including Brimstone and Burning Bush."},
                    {str = "The Monolith does not change the range of shots that are fired into it, and split shots will roughly follow the range that the fired shot has left."},
                    {str = "Gallery"},
                    {str = "The Monolith on the ground next to a regularly sized Isaac."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Tears split into three will be colored pink."},
                    {str = "A sound will also play when tears split."},
                    {str = "The Monolith can split any kind of tears, including Brimstone and Burning Bush."},
                    {str = "The Monolith does not change the range of shots that are fired into it, and split shots will roughly follow the range that the fired shot has left."},
                    {str = "Gallery"},
                    {str = "The Monolith on the ground next to a regularly sized Isaac."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_DEVIL,
                }
            },
            AEGIS = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Aegis is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a shield behind the player that blocks shots."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Aegis does not deal contact damage."},
                    {str = "Enemies cannot move through it."},
                    {str = "This includes enemies like Peep's and Bloat's Eyes enemies, who will just bounce off the back of it"},
                    {str = "Does not block Brimstone or Explosions."},
                    {str = "It is not consumed by Birth Control."},
                    {str = "Its movement is not affected by Duct Tape."},
                    {str = "It blocks damage from blood donation machines when Aegis is facing it."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            BCONTROL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Birth Control is a passive collectible added in Revelations Chapter One."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Familiars and orbitals are consumed for 0.20 damage up. Some familiars also grant special effects to the player."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "It does not consume Mirror Shard, Lil Belial, Key Piece 1, Key Piece 2, Isaac's Heart, 1up!'s mushroom familiar, Dead Cat's Guppy familiar, or Spider Mod's spider familiar."},
                    {str = "Any collectible that is not classified by the game as a familiar collectible is not consumed by Birth Control, unless specifically coded to do so like in the case of BFFS!. This means Aegis, Death's List, and similar collectibles do not get consumed."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Rotten Baby: Grants the Mulligan"},
                    {str = "Bob's Brain: Grants Ipecac"},
                    {str = "GB Bug: Grants Missing No."},
                    {str = "Farting Baby: Grants The Black Bean"},
                    {str = "Dry Baby: Grants Missing Page 2"},
                    {str = "Lil Loki: Grants Loki's Horns"},
                    {str = "Depression: Grants Aquarius"},
                    {str = "Robo Baby: Grants Technology"},
                    {str = "Robo Baby 2.0: Grants Technology 2"},
                    {str = "Harlequin Baby: Grants The Wiz"},
                    {str = "Fate's Reward: Grants Fate"},
                    {str = "Lil Monstro: Grants Monstro's Lung"},
                    {str = "Lil Brimstone, Grants Brimstone"},
                    {str = "Seraphim: Grants Sacred Heart"},
                    {str = "Rainbow Baby: Grants 3 Dollar Bill"},
                    {str = "Lil Delirium: Grants Fruit Cake"},
                    {str = "Lil Abaddon: Grants Maw of the Void"},
                    {str = "Bot Fly: Grants Lost Contact"},
                    {str = "Psy Fly: Grants Spoon Bender"},
                    {str = "Incubus: Grants 20/20"},
                    {str = "Twisted Pair: Grants 20/20"},
                    {str = "Intruder: Grants Mutant Spider"},
                    {str = "Bloodshot Eye: Grants Eye Sore"},
                    {str = "Big Fan: Grants Bucket of Lard"},
                    {str = "Mom's Razor: Grants Backstabber"},
                    {str = "Freezer Baby: Grants Uranus"},
                    {str = "Lil Michael: Grants Spirit Sword"},
                    {str = "Big Fan: Grants Bucket of Lard"},
                    {str = "Lil Frost Rider: Grants Ice Tray"},
                    {str = "Brother Bobby: +1 Fire rate up"},
                    {str = "Milk: +1 Fire rate up"},
                    {str = "Paschal Candle: +1 Fire rate up"},
                    {str = "Sister Maggy: +0.8 Damage"},
                    {str = "Sacrificial Dagger: +0.8 Damage"},
                    {str = "Guardian Angel: +0.2 Speed"},
                    {str = "Yo Listen!: +1 Luck"},
                    {str = "Ghost Baby: Grants spectral"},
                    {str = "Little Steven: Grants homing tears"},
                    {str = "Little Gish: Grants slowing tears"},
                    {str = "Multidimensional Baby: Effect is permanently applied on the player"},
                    {str = "Succubus: Effect is permanently applied on the player"},
                    {str = "Angelic Prism: Effect is permanently applied on the player"},
                    {str = "Censer: Effect is permanently applied on the player"},
                    {str = "Lil Dumpy: Effect is permanently applied on the player"},
                    {str = "Willo: Effect is permanently applied on the player"},
                    {str = "Bandage Baby: Effect is permanently applied on the player"},
                    {str = "Holy Water: Effect may be randomly applied to tears"},
                    {str = "Star of Bethlehem: Fire rate and damage is doubled in boss rooms"},
                    {str = "Hallowed Ground: Holy poops may randomly appear in rooms"},
                    {str = "Any Spider themed familiar: Grants blue spiders"},
                    {str = "Any Fly themed familiar: Grants blue flies"},
                    {str = "Fruity Plum: x2 Fire rate, x0.75 Shot speed, Tears become slightly less accurate"},
                    {str = "Lost Soul: Turns you into The Lost, Grants Alabaster Box effect"},
                    {str = "Strawman: Turns you into Keeper, Grants Greed's Gullet"},
                    {str = "Sack of Pennies: Drops pennies"},
                    {str = "Sack of Sacks: Drops sacks"},
                    {str = "The Relic: Drops soul hearts"},
                    {str = "Little Chad: Drops red hearts"},
                    {str = "Mystery Sack: Drops random pickups"},
                    {str = "Lil Chest: Drops random pickups"},
                    {str = "Acid Baby: Drops pills"},
                    {str = "Rune Bag: Drops runes"},
                    {str = "Charged Baby: Drops batteries"},
                    {str = "Bomb Bag: Drops bombs"},
                    {str = "Dark Bum: Drops various dark bum related pickups"},
                    {str = "Bum Friend: Drops random pickups"},
                    {str = "Key Bum: Drops chests"},
                    {str = "Worm Friend: Drops a red heart"},
                    {str = "7 Seals: Drops 3 random locust trinkets, one of them gets automatically smelted"},
                    {str = "Sworn Protector: Drops an eternal heart"},
                    {str = "BBF: Smelts a Swallowed M80"},
                    {str = "Baby Bender: Grants homing tears"},
                    {str = "Child Leash: Speed is set to 1"},
                    {str = "Duct Tape: The player no longer slides around while moving"},
                    {str = "Extension Cord: A laser will fire at nearby enemies"},
                    {str = "--Fiend Folio--"},
                    {str = "Baby Crater: Effect is permanently applied on the player"},
                    {str = "Lil Lamb: Effect is permanently applied on the player"},
                    {str = "Deimos: Effect is permanently applied on the player"},
                    {str = "Dice Bag: Drops random glass dice"},
                    {str = "Greg the Egg: A new friend is automatically hatched"},
                    {str = "Lil Fiend: Turns you into Fiend"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SECRET,
                }
            },
            BIRTHDAY_CANDLE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Birthday Candle is a passive collectible added in Revelations Chapter One."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "The effect varies depending on the player's inventory when the item is picked up, in order of decreasing priority: "},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_BOSS,
                    Encyclopedia.ItemPools.POOL_GOLDEN_CHEST,
                }
            },
            BURNBUSH = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Burning Bush is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Changes Isaac's tears into a stream of fire, much like a flamethrower."},
                    {str = "As the player keeps firing, they will heat up. If the player heats up too much, they will have to stop firing to cool down before firing again."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Burning Bush can be a source of heat in Glacier's Chill Rooms."},
                    {str = "The amount of time needed to cool down is determined by the Tear Delay stat."},
                    {str = "Blue flames do more damage than orange fires."},
                    {str = "Just as with regular burn damage in the game, doing damage to enemies that have a Burning variant have a chance to turn them into that variant."},
                    {str = "BUG: Lilith can shoot Burning Bush directly from herself instead of her Incubus, since she is technically shooting from the mouth instead of the eyes."},
                    {str = "Burning Bush can instantly destroy the Ice Hazard enemies in the Glacier, destroying the monster inside."},
                    {str = "Burning Bush cannot, however, instantly destroy Ice Pooters, Blue-Ambered Spiders, or the ice stage of Stalactrites. Burning Bush CAN remove the ice off of these enemies, but the monsters will not be destroyed."},
                    {str = "Miniature forms of fires like ones from the Red Candle active item can also be shot occasionally."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Brimstone: The brimstone laser spawns little flames that shoot out to the sides of the laser which do damage to enemies and have a chance to apply burning. The laser has a chance to apply burning."},
                    {str = "Chocolate Milk: The player gains a charge effect, but is still able to fire flames at any time. The charged shot shoots a tear instead of flames."},
                    {str = "Cursed Eye: The player gains a charge effect, but is still able to fire flames at any time. The charged shot releases a large fan of tears."},
                    {str = "Dr. Fetus: The player shoots a large fan of bombs and flames. The bombs leave stationary flame when exploding, and also blast flames in random directions."},
                    {str = "Epic Fetus: Each explosion blasts flames in random directions. The Epic Fetus shot lasts a lot longer and shoots a lot more bombs than the regular 1 shot it normally does."},
                    {str = "Fecal Freak: While the majority of flames will fire backwards, some will fire forwards."},
                    {str = "Head of the Keeper: Each individual fire of the flamethrower has a chance to drop a coin, making this an easy way to get many pennies in a short amount of time."},
                    {str = "Ipecac: Ipecac shots spawn fires that go out in random directions when exploding. The fires have a chance to apply poison."},
                    {str = "Isaac's Tears: Isaac's Tear's shots are regular tears instead of flames. Unable to charge the item by shooting."},
                    {str = "Jacob's Ladder: Flames release electricity when hitting enemies."},
                    {str = "The Ludovico Technique: Fires spawn and go out in random directions from the main tear."},
                    {str = "Mint Gum: The flames are turned into snowflakes. Enemies can still be frozen, and they can also still be burned."},
                    {str = "Mom's Knife: Flames spawn from the point of the knife when shot. The longer the charge, the more fires spawned. While the flames can apply a burn effect, direct damage from the knife cannot."},
                    {str = "Pupula Duplex: Flames are tilted on their side, facing away from the player."},
                    {str = "Tammy's Head: Shoots regular tears."},
                    {str = "Technology: The laser has a chance to apply burning."},
                    {str = "Technology 2: The player will shoot half flames as they normally would. The laser has a chance to apply burning."},
                    {str = "Tech X: Shoots a ring of flames. The longer the charge, the larger the ring. The ring has a chance to apply burn."},
                    {str = "Technology Zero: Electricity spawns between every fire, creating a lot of electricity."},
                    {str = "Tiny Planet: Flames orbit around the player."},
                    {str = "Tummy Bug: While normally the player stops firing when charging a Tummy Bug shot, the played is still able to fire flames while charging a Tummy Bug shot."},
                    {str = "Maw of the Void: Flames are able to be shot while Maw of the Void is charging. When used the flames will randomly shoot out from the laser. The laser has the same appearance as Brimstone's laser."},
                    {str = "My Reflection: Turns the attack button into a scream button."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "8 Inch Nails: The flames appear upside-down."},
                    {str = "Circle of Protection:  The circle is now a Burning Ring of fire."},
                    {str = "Euthanasia: Overridden by Burning Bush."},
                    {str = "Incubus: Does not shoot Burning Bush shots."},
                    {str = "The Inner Eye: Overridden by Burning Bush."},
                    {str = "Loki's Horns: Overridden by Burning Bush."},
                    {str = "Mom's Eye: Overridden by Burning Bush."},
                    {str = "Ice Tray: Overridden by Burning Bush."},
                    {str = "BUG:When the flames from Burning Bush dissipate, Ice Tray's tear break particles appear."},
                    {str = "The Parasite: Overridden by Burning Bush."},
                    {str = "Proptosis: Flames nearly instantly dissipate."},
                    {str = "BUG: When the flames from Burning Bush dissipate, regular tear break particles appear."},
                    {str = "Tech.5: The laser does not have a chance to apply burning."},
                    {str = "Angelic Prism: when the Flamethrower goes through the prism, they split into 4 different colored regular tears at a Rate similar to Soy_Milk."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            TAMPON = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Cotton Bud is a passive collectible added in Revelations Chapter One."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Creep immunity."},
                    {str = "Decreases the players tear delay by 2 for 4 seconds per grid of creep they walk over."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Player creep will not trigger this item."},
                    {str = "Once the player gains the effect, they will be lit up yellow for the duration of the effect."},
                    {str = "The amount of time the effect lasts for stacks for each grid of creep the player absorbs."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
                    Encyclopedia.ItemPools.POOL_GREED_SHOP,
                }
            },
            DYNAMO = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Dynamo is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "The player gains a charge effect."},
                    {str = "As the player holds down the fire button, their eyes will start to glow. After 2 seconds of firing, the player will fully light up. If the player lets go of the fire button when fully lit up, three yellow lasers similar to the ones used by Pride will fire towards enemies."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "BUG: There is a chance that the player will be glowing yellow despite not actually being charged up."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            FECAL_FREAK = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Fecal Freak is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "The player's shooting keys are reversed."},
                    {str = "+1.50 Damage up."},
                    {str = "+50% Damage multiplier"},
                    {str = "-25% Range multiplier"},
                    {str = "-25% Shot Speed multiplier"},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Little poop particles can sometimes come out of the player when walking."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Aegis: Now blocks the front of the player."},
                    {str = "Burning Bush: While the majority of flames will fire backwards, some will fire forwards."},
                    {str = "Evil Eye: The eye will fire where the player is looking, but the shots will be reversed."},
                    {str = "Technology 2: The laser fires in front of the player while the tears fire behind the player."},
                    {str = "Tech.5 works the same way."},
                    {str = "Tiny Planet: The player will shoot in front of themself, instead of behind."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "Brimstone: Overrides Fecal Freak."},
                    {str = "Dr. Fetus: Overrides Fecal Freak."},
                    {str = "Epic Fetus: Overrides Fecal Freak."},
                    {str = "Incubus: Tears will correctly be reversed."},
                    {str = "Mom's Knife: Overrides Fecal Freak."},
                    {str = "Monstro's Lung: Fires a charge shot behind the player."},
                    {str = "Technology: Overrides Fecal Freak."},
                    {str = "Tech X: Overrides Fecal Freak."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            FFIRE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Friendly Fire is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Grants fire immunity."},
                    {str = "Red Fires shoot at enemies instead of the player."},
                    {str = "Red Fires spawn more often."},
                    {str = "Red hearts have a 1 in 5 chance to spawn from fires."},
                    {str = "Friendly Red Fires create warmth auras in Chill Rooms."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The player is immune to all fires, even enemy fire attacks from Mega Maw and Mega Satan."},
                    {str = "Fires specifically spawned by this item are signified by a blue tint on the fire."},
                    {str = "Fireplaces have collision detection with the player, even though they do not hurt the player. Fire attacks from enemies will just disappear upon hitting the player."},
                    {str = "Tear Delay of the fires match that of the players."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Stop Watch: The player can run into any fire hazard and trigger Stop Watch's slowing effect for the room without taking any damage"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            HEAVENLY_BELL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Heavenly Bell is an unlockable passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Heavenly Bell has 6 possible effects that can trigger upon travelling to new floors. On Normal mode, a thought bubble will appear above the player, along with a bell sound to signify the effect. On Hard mode, only the bell sound will play."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "The bell sound for effect number 1 is a reference to the Legend of Zelda."},
                    {str = "The bell sound for effect number 5 is the sound of bells mostly made during the commemoration of the dead"},
                    {str = "The bell sound for effect number 6 is the first four notes of the Indiana Jones theme."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            ICETRAY = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Ice Tray is an unlockable passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Changes the players tears into ice cubes which slide on the ground, leaving creep."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Ice Tray is unlocked by clearing the Glacier floorpath for the first time."},
                    {str = "Ice Tray's tears start in the air and fall to the ground before leaving creep. High tear height will produce less creep, as it will take longer for the tears to hit the ground."},
                    {str = "Tear changing items, such as Brimstone and Technology, will not leave creep over where they are shot."},
                    {str = "Ice Tray is given to the player if the player has Birth Control and consumes Lil Frost Rider."},
                    {str = "Ice Tray tears have infinite range, and only break when they hit a wall or something they cannot go through"},
                    {str = "Ice Tray has anti-lag measures implemented to stop the game from completely lagging out, as Ice Tray can easily lag the game"},
                    {str = "Tears disappear if they are active for too long (IE with Continuum or Rubber Cement), despite having infinite range."},
                    {str = "Tears automatically break no matter what if they go outside the room (except with Continuum)."},
                    {str = "Creep spaces itself out more if there is a lot of creep spawned by Ice Tray."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Explosivo: Tears attached to enemies will not leave creep on the ground."},
                    {str = "Ipecac: Launches explosive Ice Tray tears at a high arc, which slide when landing."},
                    {str = "Tummy Bug: Tears launched from Tummy Bug's charge slide when landing."},
                    {str = "The Monolith: The tears split from the Monolith will correctly slide."},
                    {str = "The Parasite: Tears split from the Parasite do not slide."},
                    {str = "Lead Pencil: Lead Pencil shots will not slide."},
                    {str = "Pop!: Tears will act like Pop! tears and do not slide on the ground."},
                    {str = "Technology 2: The player will shoot a laser out of one eye, and an Ice Tray shot from the other."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "8 Inch Nails: Nail shots will take the appearance of an Ice Tray shot."},
                    {str = "Brimstone: Overrides Ice Tray."},
                    {str = "Burning Bush: Overrides Ice Tray."},
                    {str = "BUG: When the flames from Burning Bush dissipate, Ice Tray's tear break particles appear."},
                    {str = "Dr. Fetus: Overrides Ice Tray."},
                    {str = "Epic Fetus: Overrides Ice Tray."},
                    {str = "Euthanasia: The euthanasia shot will take the appearance of an Ice Tray shot."},
                    {str = "The Ludovico Technique: Overrides Ice Tray."},
                    {str = "Mom's Knife: Overrides Ice Tray."},
                    {str = "Technology: Overrides Ice Tray."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            LIL_BELIAL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Belial is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Belial targets random enemies for the player to kill in order. Killing them in order guarantees a reward."},
                    {str = "Lil Belial slows his target down to 75% of its current speed."},
                    {str = "Enemies who Lil Belial is targeting will receive 1.5 extra damage when attacked."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Belial is not consumed by Birth Control."},
                    {str = "Lil Belial will not cancel targeting for the room if non-targeted enemies die from status effects like poison or burning."},
                    {str = "He will cancel his quest if familiars kill non-targeted enemies, however."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "The sound effect that plays when the player kills all of Lil Belial's targets in order is the same sound effect from when the player takes a devil deal in the original Binding of Isaac. [Sound]"},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Book of Belial: Increases extra damage dealt to 4.5."},
                    {str = "Death's List: Lil Belial carries Death's List's skull and they combine into a single familiar that grants both rewards upon completing the quest."},
                    {str = "Eye of Belial: Slows the target down to 50% of its speed."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_DEVIL,
                }
            },
            LIL_FRIDER = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Frost Rider is a familiar added in Revelations Chapter 1. It is always dropped after defeating Frost Rider."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Frost Rider attacks enemies by shooting an Ice Pooter at them, which leaves creep as it slides."},
                    {str = "When the ice pooter breaks, a friendly Pooter is spawned."},
                    {str = "Lil Frost Rider damages enemies on contact."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Ice Tray is given to the player if the player has Birth Control and consumes Lil Frost Rider."},
                    {str = "If 3 friendly Pooters are active, Lil Frost Rider will instead shoot an empty Ice Cube."},
                },
                Pools = {
                }
            },
            MINT_GUM = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Mint Gum is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Tears apply slow when hitting enemies."},
                    {str = "Hitting enemies five times in a row freezes them."},
                    {str = "Bosses take 10 hits to freeze."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "After freezing an enemy, there is a small cooldown before being able to freeze them again."},
                    {str = "Bosses have a very large cooldown."},
                    {str = "Some enemies, after they are frozen, will unfreeze and turn into their Glacier counterpart."},
                    {str = "When frozen enemies are killed, ice creep spawns where they died which the player can slide on."},
                    {str = "Mint Gum's slowing effect does not slow enemy projectiles."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Burning Bush: The flames are turned into snowflakes. Enemies can still be frozen and burned."},
                    {str = "Dr. Fetus and Epic Fetus: The explosions from these items will freeze enemies."},
                    {str = "Dynamo: The lasers freezes enemies."},
                    {str = "The Monolith: Shots split through the Monolith correctly freeze enemies."},
                    {str = "Spirit of Patience: The laser freezes enemies."},
                    {str = "Tummy Bug: Shots from this item freeze enemies."},
                    {str = "Finger!: The damage from the finger freezes enemies."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "Friendly Fire: Shots from fires do not freeze enemies."},
                    {str = "Incubus: Shots do not slow or freeze enemies."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            MIRROR = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "The Mirror Shard is a passive collectible added in Revelations Chapter 1. It is acquired from defeating Narcissus and Narcissus II."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "When it is collected by itself:"},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "In the future this item will have a use within the story. As of now it only acts as an orbital or damage item."},
                },
                Pools = {
                }
            },
            PENANCE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Penance is an unlockable passive collectible added in Revelations Chapter One, and was reworked in Chapter Two."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "All spawned Soul Hearts pickups are replaced with Black Hearts, as well as Soul Hearts gained through other means (such as Book of Revelations)."},
                    {str = "Soul Hearts already collected or spawned before obtaining Penance are unaffected."},
                    {str = "When returning to rooms with uncollected Black Hearts, any Black Hearts in the room will immediately transform into spirits and fly off-screen."},
                    {str = "Upon taking Black Heart damage while in combat, all of the player's Black Hearts will be removed and reform as spirits. Each Black Heart will spawn one spirit. These spirits will move to one of the cardinal sides of the player, charge for a moment and dash across the room, dealing contact damage to the player and enemies. After combat is finished, the spirits will disappear and black hearts will be restored with no damage."},
                    {str = "Taking Black Heart damage outside of combat damages the player normally."},
                    {str = "If Black Hearts are the only type of heart the player has, taking damage in combat immediately kills the player no matter how many Black Hearts they have."},
                    {str = "When dealing damage to the player, spirits may disappear, causing 1 black heart to be lost."},
                    {str = "All Angel Rooms are replaced with a unique layout featuring an Angel statue with a broken wing that offers no items normally. Upon entering, the Angel will fully refill the player's Red Hearts and remove all the player's Black Hearts. Because of this, it is highly not recommended to pick up Penance when playing a character that is unable to collect Red Heart Containers. Upon removing a certain number of Black Hearts, the Angel will reward the player with an item from the angel room pool, alongside additional rewards depending on how many times the player has been rewarded."},
                    {str = "The number of Black Hearts required begins at 1, then increases by 1 for each time the player was previously rewarded in that run (to a maximum of 5 required). Unused Black Hearts are returned upon leaving the Angel Room."},
                    {str = "The 2nd reward will always drop a Gold Heart alongside the item."},
                    {str = "The 3rd reward will always drop a Eternal Heart alongside the item."},
                    {str = "The 4th reward will always spawn an Eternal Chest alongside the item.  Additionally, when playing as Sarah, it immediately heals her broken wings and grants flight if they aren't already healed."},
                    {str = "The 5th reward and onward will always spawn both an Eternal Chest and a Eternal Heart alongside the item."},
                    {str = "When not playing as Sarah, Penance acts like Duality. Whenever a Devil or Angel room spawns after defeating a boss, the other will also spawn. The room not chosen will disappear."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Prior to Chapter Two, Penance converted Soul Hearts, Black Hearts, and Gold Hearts into stat upgrades upon travelling to a new floor instead of its current effect. Soul Hearts upgraded Shot Speed by 0.06 per half (to a maximum of 0.70, after which it would upgrade Range by 2.10 per half instead). Black Hearts upgraded Damage by 0.15 per half. Gold Hearts upgraded Luck by 1.00 per heart."},
                    {str = "It did not activate if the player had no Red Heart containers, except on Blue Baby, where it consumed any hearts over 6 total hearts."},
                    {str = "Sarah starts with this item."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            PATIENCE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Spirit of Patience is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "A laser will fire at the nearest enemy so long as the player is standing still."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The laser is separate from Isaac's tears. You may still fire regular tears if you have this item."},
                    {str = "The laser auto tracks the nearest enemy."},
                    {str = "The laser's damages matches the player's damage."},
                    {str = "The laser's fire rate is determined by the player's tear delay."},
                    {str = "The laser is affected by tear effects, such as Homing and Spectral."},
                    {str = "The laser is unaffected by Gnawed Leaf."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            SPONGE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Sponge Bombs is a passive collectible added in Revelations Chapter One."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "+5 Bombs."},
                    {str = "Changes the player's bombs into tiered bombs which can be increased in size and damage the more the tears they absorb."},
                    {str = "Sponge Bombs leave creep on the ground each time they absorb a tear."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The bomb's damage output and radius can be increased infinitely, but the fuse timer of the bomb makes it hard to increase it extremely high."},
                    {str = "Sponge Bombs can absorb both player and enemy tears."},
                    {str = "Sponge Bombs output a variety of effects upon explosion determined by the tear effects they absorb."},
                    {str = "The bombs output the amount of damage it absorbs. It starts with a base damage of 600, and it will absorb the damage that is put into it and will do that amount upon explosion."},
                    {str = "Since 3.50 damage counts as 35 damage, the third numeral always rounds up when being absorbed into Sponge Bombs. For instance, if the player has 3.51 damage, the bomb will absorb 36 damage, as the third numeral rounds up to the next one, making the five a six."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Burning Bush: Leaves a stationary flame where the bomb explodes"},
                    {str = "Fecal Freak: Gives the bomb a Butt Bomb effect upon exploding."},
                    {str = "Friendly Fire: Shots from fires can increase sponge bombs."},
                    {str = "Ipecac: Gives the sponge bomb a ton of damage, and makes it enormous."},
                    {str = "Mint Gum: The explosion counts as 2 hits required to freeze enemies. It persists like this for all tiers of Sponge Bombs."},
                    {str = "Sad Bombs: The tears that are produced from the explosion can be absorbed by other Sponge Bombs."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "Brimstone: Is not absorbed by Sponge Bombs."},
                    {str = "Dr. Fetus: The Sponge Bombs cannot absorb into each other, making enemy tears the only thing that can increase them."},
                    {str = "Epic Fetus: Epic Fetus shots do not absorb into sponge bombs."},
                    {str = "Mom's Knife: Is not absorbed by Sponge Bombs."},
                    {str = "Scatter Bombs: The scattered bombs are regular bombs that cannot absorb tears."},
                    {str = "Technology (all types): Sponge Bombs do not absorb any time of technology laser. This includes:Technology 2, Technology Zero, Tech.5, and Tech X."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Despite the similarities, the name is not a reference to Spongebob Squarepants."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_BOMB_BUM,
                }
            },
            TBUG = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Tummy Bug is a passive collectible added in Revelations Chapter 1."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "When a fire button is held, the player sometimes stops firing, followed by a brief charge. When the charge is released, the player fires a spray of tears in a high arc."},
                    {str = "When the player ingests a pill, a large pool of creep will spawn in the direction they are looking."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Regular charge items, such as Brimstone and Monstro's Lung, are still able to function with this item."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            CLEANER = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Window Cleaner is a passive collectible added in Revelations Chapter 1. "},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "-1 Tear Delay"},
                    {str = "The player's tears remove creep as they fly over it."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "It will not remove player-made creep."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_GOLDEN_CHEST,
                    Encyclopedia.ItemPools.POOL_CRANE_GAME,
                }
            },
            ROBOT = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Cardboard Robot is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, a large cardboard suit slams down on the player, dealing contact damage and knockback to any enemies nearby."},
                    {str = "For 15 seconds, the player moves around in the cardboard suit, firing seven constant lasers."},
                    {str = "Each individual laser does 33% of the players damage."},
                    {str = "If the player gets hit, 33% of the remaining time is depleted instead of taking damage."},
                    {str = "Upon clearing a room, the player gains 33% extra time."},
                    {str = "When time runs out, the player flings the suit off, and the suit explodes after a short period of time."},
                    {str = "Trivia"},
                    {str = "Cardboard Robot is a reference to the Overwatch hero D.Va."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Cardboard Robot is a reference to the Overwatch hero D.Va."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_CRANE_GAME,
                }
            },
            CHUM = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Chum Bucket is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effect
                    {str = "Effect", fsize = 2, clr = 3, halign = 0},
                    {str = "When killing enemies (except for certain small enemies such as flies), corpses are left on the ground."},
                    {str = "Upon use, corpses on the ground fire one of three different tear types at enemies in the room"},
                    {str = "Red Tear: Deal's the player's damage."},
                    {str = "Bone Tear: Deal's the player's damage and splits into bone fractures on impact."},
                    {str = "Tooth Tear: Deals 3x the player's damage."},
                    {str = "Notes"},
                    {str = "Black Flies and Attack Flies do not create meat piles."},
                    {str = "Segmented enemies such as Grubs create multiple meat piles per segment."},
                    {str = "Trivia"},
                    {str = "The Chum Bucket is the name of a restaurant in the popular tv show Spongebob Squarepants."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Black Flies and Attack Flies do not create meat piles."},
                    {str = "Segmented enemies such as Grubs create multiple meat piles per segment."},
                    {str = "Trivia"},
                    {str = "The Chum Bucket is the name of a restaurant in the popular tv show Spongebob Squarepants."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "The Chum Bucket is the name of a restaurant in the popular tv show Spongebob Squarepants."},
                },
                Pools = {
                }
            },
            GFLAME = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Ghastly Flame is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, the player can shoot out a purple flame that has homing."},
                    {str = "The flame scales to the player's damage."},
                    {str = "If the flame does the final blow to an enemy, the enemy's soul will be stored in the active item. The next time the player uses the item, a ghost familiar will spawn and seek out enemies, dropping stationary purple fires as it travels."},
                    {str = "The ghost familiar lasts for 20 seconds."},
                    {str = "Notes"},
                    {str = "The ghost familiar is not consumed by Birth Control or Sacrificial Altar."},
                    {str = "Synergies"},
                    {str = "BFFS!: Increases size and contact damage of the ghost familiar."},
                    {str = "Extension Cord: Electricity beams connect between the player and the ghost familiar while active."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The ghost familiar is not consumed by Birth Control or Sacrificial Altar."},
                    {str = "Synergies"},
                    {str = "BFFS!: Increases size and contact damage of the ghost familiar."},
                    {str = "Extension Cord: Electricity beams connect between the player and the ghost familiar while active."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "BFFS!: Increases size and contact damage of the ghost familiar."},
                    {str = "Extension Cord: Electricity beams connect between the player and the ghost familiar while active."},
                },
                Pools = {
                }
            },
            GUT = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Glutton's Gut is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, the player inhales and sucks in nearby enemies and projectiles."},
                    {str = "If the player has sucked up enemies and/or projectiles, they will stop inhaling and start chewing. The player can do one of two things while they are chewing:"},
                    {str = "If the player activates Glutton's Gut again, they will swallow and gain one red heart."},
                    {str = "If the player shoots in a direction, they will spit out a glob which scales in damage from 1x-6x of the player's damage based upon how much stuff the player inhaled. Upon impact it will also send out either 4 tears or 8 tears also depending on how much stuff the player inhaled."},
                    {str = "Using this during a boss fight makes the player inhale a large tear from the boss. Inhaling the tear does no damage to the boss, but it instantly maxes out the damage of the glob."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Entering another room does not empty the contents of the player's mouth, making it a useful way of getting some quick starting damage in on a boss fight."},
                    {str = "An enemy's health or strength does not determine if it can be eaten, so anything from a Dip to an Oob can be gobbled up just as easily."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "This item was inspired by Kirby, a popular Nintendo character."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            HALF_CHEWED_PONY = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Half-Chewed Pony is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Gives the player flight when held."},
                    {str = "Upon use, it summons a friendly submerged Antlion, sucking in enemies and doing damage to them."},
                    {str = "There is a 5% chance that when using Half-Chewed Pony, the friendly Antlion will instantly eat the pony, removing it from the player's inventory. When this happens, the Antlion will come up from the ground and act as a friendly regular Antlion, flying around and occasionally shooting a blast of projectiles around the room."},
                    {str = "If the Antlion dies, it will respawn at the start of the next floor."},
                    {str = "To stop the player from possibly getting stuck, if Half-Chewed Pony is taken away from the player, the player will remain with flight in the form of angel wings only for the duration of the rest of the room that he lost the pony in."},
                    {str = "Trivia"},
                    {str = "Half-Chewed Pony is War's pony. This is known because at the beginning of Sandy's bossfight, she is seen eating War."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Half-Chewed Pony is War's pony. This is known because at the beginning of Sandy's bossfight, she is seen eating War."},
                },
                Pools = {
                }
            },
            MOXIE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Moxie's Paw is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, swings a pair of bandages rapidly 360 around the player as a short range melee attack."},
                    {str = "It deals damage equal to the player's current damage times 1.2."},
                    {str = "Any enemies and projectiles caught in the swipes are knocked back."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            MOXIE_YARN = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Moxie's Yarn is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, the player can throw a ball of yarn which will summon one of the four Catastrophe bosses randomly. They will be friendly and swipe at nearby enemies. After a while, the summoned cat will curl up in some bandages and will go to sleep, needing to be re-summoned"},
                    {str = "Notes"},
                    {str = "All four cats may be out at once."},
                    {str = "You cannot spawn more than the four cats."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "All four cats may be out at once."},
                    {str = "You cannot spawn more than the four cats."},
                },
                Pools = {
                }
            },
            MUSIC_BOX = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Music Box is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, drops a music box on the ground that can play one of four different tunes, each with their own effects which last while the music box is playing."},
                    {str = "Lullaby - All enemies are gradually slowed, before eventually falling alseep, signified with small ''zzz''s above their heads. Any damage will wake them. Melody."},
                    {str = "Hymn - The player gains +1 speed, +2 damage, and homing tears for the duration. Melody."},
                    {str = "Samba - Tear Delay -2, Piercing and Spectral for the duration. Melody."},
                    {str = "Metal -  All enemies randomly attack each other for the duration.  Melody."},
                    {str = "Notes"},
                    {str = "Multiple music boxes placed down will stack the effects."},
                    {str = "Infinite music boxes can be placed down at a time."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Multiple music boxes placed down will stack the effects."},
                    {str = "Infinite music boxes can be placed down at a time."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
                    Encyclopedia.ItemPools.POOL_GREED_SHOP,
                    Encyclopedia.ItemPools.POOL_CRANE_GAME,
                }
            },
            OOPS = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Oops! is an active collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, certain traps are triggered or disabled."},
                    {str = "All spikes in the room are retracted."},
                    {str = "All bombs stuck in rocks and TNT are detonated."},
                    {str = "Buttons will be pressed."},
                    {str = "When activated in a Trap Room in Tomb, all traps in the room are triggered but are harmless to the player."},
                    {str = "If Oops! is used when there is nothing in the room it can affect, it will play a buzzer sound and not use any charge."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            WAKA_WAKA = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Waka Waka is an activated collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, all tears in the room turn into one of four fruit types. For five seconds, the player's head will look like pac-man and the player will be able to eat the different fruits, each giving different stat boosts for the remainder of the floor."},
                    {str = "Cherry: +0.10 Damage"},
                    {str = "Lemon: +1.00 Range"},
                    {str = "Orange: +0.05 Shot Speed"},
                    {str = "Banana: +0.05 Speed"},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "This item is based off of the popular gaming character Pac-Man."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_CRANE_GAME,
                }
            },
            ADDICT = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Addict is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "For each room the player doesn't take a pill, the next room will have a unique enemy called Skitterpills. An additional Skitterpill is added until a pill gets consumed."},
                    {str = "The Skitterpills are classified as good and bad, with good being depicted as a flying yellow pill, and bad being depicted by a red spider pill. Bad Skitterpills drop bad pills, while Good Skitterpills drop good/neutral pills (including Puberty)."},
                    {str = "All Skitterpills will disappear when the room is cleared or when all monsters go off screen (e.g. Mom's Hands lifting up). If they disappear in this way, they will not drop any pills."},
                    {str = "Taking a pill will reset the number of Skitterpills the player has to deal with per room."},
                    {str = "Pills dropped by Skitterpills will disappear after a short time."},
                    {str = "Using a pill in a room with active Skitterpills will kill them all and the pills that they drop won't disappear."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
                    Encyclopedia.ItemPools.POOL_GREED_SHOP,
                }
            },
            BANDAGE_BABY = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Bandage Baby is a passive collectible added in Revelations Chapter Two."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a mummy familiar that orbits the player and periodically lobs balls of rags at nearby enemies."},
                    {str = "The rag projectiles temporarily slow down enemies on contact."},
                    {str = "If the familiar misses its shot, the projectile leaves behind a pile of rags that also slows enemies that touch it."},
                    {str = "The familiar can block shots, but will collapse in a pile of rags, respawning after some time."},
                    {str = "The pile of rags created by the destroyed familiar can still slow enemies that touch it."},
                    {str = "Notes"},
                    {str = "Bandage Baby is unlocked by clearing the Tomb floorpath for the first time."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Bandage Baby is unlocked by clearing the Tomb floorpath for the first time."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            BARG_BURD = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Bargainer's Burden is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a familiar which deals contact damage to enemies."},
                    {str = "If the player holds the firing keys, the familiar will hold in place. When the firing keys are released, the familiar will fling towards the player, dealing extra damage to enemies it hits."},
                    {str = "The familiar will become bigger and deal more damage depending on how many pickups the player has"},
                    {str = "Tier 1 = 4.50 damage."},
                    {str = "Tier 2 = 6.63 damage."},
                    {str = "Tier 3 = 8.75 damage."},
                    {str = "Tier 4 = 10.88 damage."},
                    {str = "Tier 5 = 15 damage."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            CHARONS_OAR = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Broken Oar is a passive collectible added in Revelations Chapter Two."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "The player fires a spread of tears of varying size and damage."},
                    {str = "Synergies"},
                    {str = "20/20: Each tear in Broken Oar's spread shot is doubled."},
                    {str = "The Inner Eye: Increases size of Broken Oar's spread shot."},
                    {str = "Lachryphagy: Tears burst into more spread shots, which immediately combine and burst in a self-sustaining chain reaction."},
                    {str = "Monstro's Lung: Fires a massive burst of tears that covers a wide area."},
                    {str = "Mutant Spider: Increases size of Broken Oar's spread shot."},
                    {str = "Soy Milk: Spread shot from Broken Oar compensates somewhat for Soy Milk's poor accuracy and makes it easier to deal consistent damage with it."},
                    {str = "Technology Zero: Spread shots are linked together by many beams of electricity."},
                    {str = "Interactions"},
                    {str = "Anti-Gravity: Spread shots compound into bundles of floating tears, but releasing the shooting keys only causes one of them to start moving."},
                    {str = "Brimstone: Overridden by Brimstone."},
                    {str = "Epic Fetus: Overridden by Epic Fetus."},
                    {str = "Mom's Knife: Overridden by Mom's Knife."},
                    {str = "Technology: Overridden by Technology."},
                    {str = "Tech X: Overridden by Tech X."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "20/20: Each tear in Broken Oar's spread shot is doubled."},
                    {str = "The Inner Eye: Increases size of Broken Oar's spread shot."},
                    {str = "Lachryphagy: Tears burst into more spread shots, which immediately combine and burst in a self-sustaining chain reaction."},
                    {str = "Monstro's Lung: Fires a massive burst of tears that covers a wide area."},
                    {str = "Mutant Spider: Increases size of Broken Oar's spread shot."},
                    {str = "Soy Milk: Spread shot from Broken Oar compensates somewhat for Soy Milk's poor accuracy and makes it easier to deal consistent damage with it."},
                    {str = "Technology Zero: Spread shots are linked together by many beams of electricity."},
                    {str = "Interactions"},
                    {str = "Anti-Gravity: Spread shots compound into bundles of floating tears, but releasing the shooting keys only causes one of them to start moving."},
                    {str = "Brimstone: Overridden by Brimstone."},
                    {str = "Epic Fetus: Overridden by Epic Fetus."},
                    {str = "Mom's Knife: Overridden by Mom's Knife."},
                    {str = "Technology: Overridden by Technology."},
                    {str = "Tech X: Overridden by Tech X."},
                },
                { -- Interactions
                    {str = "Interactions", fsize = 2, clr = 3, halign = 0},
                    {str = "Anti-Gravity: Spread shots compound into bundles of floating tears, but releasing the shooting keys only causes one of them to start moving."},
                    {str = "Brimstone: Overridden by Brimstone."},
                    {str = "Epic Fetus: Overridden by Epic Fetus."},
                    {str = "Mom's Knife: Overridden by Mom's Knife."},
                    {str = "Technology: Overridden by Technology."},
                    {str = "Tech X: Overridden by Tech X."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            CABBAGE_PATCH = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Cabbage Patch is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "In any room, there will be 1-2 green sprouts on the ground. Shooting these sprouts will cause them to grow. When they are fully grown, they explode and spawn a vegetable familiar."},
                    {str = "The explosion does not hurt the player but will destroy rocks, damage enemies, reveal secret rooms, etc."},
                    {str = "Vegetable familiars constantly hop around, throwing themselves at enemies, doing damage equal to 1.5 of the player's damage."},
                    {str = "After throwing themselves at enemies 5 times, they will die."},
                    {str = "There are multiple variants of cabbages, increasing as you pick up specific items."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Some characters appear to start with certain vegetables unlocked. The Lost, for example, starts with Pumpkins despite Holy Mantle and D4 not granting Pumpkins."},
                    {str = "Items to unlock the variants seem to be both conceptually related and related from game mechanics. An example being Holy Light and Holy Mantle, both unlocking the Mustard. Holy Light creates the light beams that are part of Mustard's effects but Holy Mantle is simply Holy."},
                    {str = "Potato, Joseph Stalin, and possibly Corn's effects are references to the mobile game Plants vs. Zombies which also uses animated plants to fight enemies. The game has Potato Mines and Cob Cannons which operate in an identical way as the vegetables."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            CURSED_GRAIL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Cursed Grail is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "If there is a Sacrifice Room on the floor, the familiar will move to doors leading to it. When in the Sacrifice Room, the familiar will move to the side of the spikes."},
                    {str = "Upon taken damage from a Sacrifice Room spike, the player gains +0.50 damage. Each time damage is taken, blood will drop in the goblet."},
                    {str = "Upon taking damage the 6th time, the blood in the goblet will form blood wings that will grant the player flight"},
                    {str = "Taking damage on the spike from this point onwards will have no effect."},
                    {str = "Notes"},
                    {str = "The amount of blood collected in the grail persists between floors, so the same Sacrifice Room does not have to be used."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The amount of blood collected in the grail persists between floors, so the same Sacrifice Room does not have to be used."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_DEVIL,
                    Encyclopedia.ItemPools.POOL_CURSE,
                }
            },
            DEATH_MASK = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Death Mask is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "When the player kills 10 enemies, the next enemy closest to the player will instantly be killed by a strike of lightning."},
                    {str = "When an enemy is insta-killed, a friendly blue bony will spawn in place of the killed enemy that acts like a regular Bony."},
                    {str = "Notes"},
                    {str = "Book of the Dead: Lowers the kill count requirement by two. Friendly bonys and bone familiars spawned by this item will be colored blue, and the bone familiars deal more damage."},
                    {str = "Death's Touch: Lowers the kill count requirement by one."},
                    {str = "Death's List: Lowers the kill count requirement by one."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Book of the Dead: Lowers the kill count requirement by two. Friendly bonys and bone familiars spawned by this item will be colored blue, and the bone familiars deal more damage."},
                    {str = "Death's Touch: Lowers the kill count requirement by one."},
                    {str = "Death's List: Lowers the kill count requirement by one."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_DEVIL,
                }
            },
            ENVYS_ENMITY = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Envy's Enmity is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a Mini Envy head that orbits the player."},
                    {str = "When the player shoots through the head, it will split into two heads that orbit a little farther away from the player and deal more damage."},
                    {str = "When you have Bffs! the envy heads will turn into super envy heads which split an extra time"},
                    {str = "There are four different head stages:"},
                    {str = "1st Head = .14 damage."},
                    {str = "2nd Head = .26 damage."},
                    {str = "3rd Head = .38 damage."},
                    {str = "4th Head = .50 damage."},
                    {str = "Notes"},
                    {str = "The heads do not block enemy tears."},
                    {str = "The player can have a maximum of 8 tiny envy heads"},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The heads do not block enemy tears."},
                    {str = "The player can have a maximum of 8 tiny envy heads"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            FERRYMANS_TOLL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Ferryman's Toll is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Drops two random coins."},
                    {str = "Upon death, if the player has 33 coins, he will be revived and placed at the beginning of the floor by Charon."},
                    {str = "When being revived, the price of the next revival is raised by 33 coins, with the maximum price being 99 coins for the third revival."},
                    {str = "The player can only be revived three times."},
                    {str = "Notes"},
                    {str = "Keeper receives revives at 25 coins, 50 coins, 75 coins, and 99 coins."},
                    {str = "Dante keeps the coins after each revival, but the cost still raises."},
                    {str = "Trivia"},
                    {str = "This item is a reference to Charon's character in mythology,. He is the ferryman of the dead, requiring payment to bring lost souls across the rivers Styx."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Keeper receives revives at 25 coins, 50 coins, 75 coins, and 99 coins."},
                    {str = "Dante keeps the coins after each revival, but the cost still raises."},
                    {str = "Trivia"},
                    {str = "This item is a reference to Charon's character in mythology,. He is the ferryman of the dead, requiring payment to bring lost souls across the rivers Styx."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "This item is a reference to Charon's character in mythology,. He is the ferryman of the dead, requiring payment to bring lost souls across the rivers Styx."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_DEVIL,
                }
            },
            HAPHEPHOBIA = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Haphephobia is a passive collectibe added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "When firing, the player sends out a shockwave that knocks back nearby enemies."},
                    {str = "The shockwave has a cooldown that is tied to tear delay. The lower the player's tear delay, the quicker the cooldown. The higher the tear delay, the longer the cooldown."},
                    {str = "Notes"},
                    {str = "Haphephobia only effects bosses that are effected by knockback."},
                    {str = "Trivia"},
                    {str = "Haphephobia is the fear of being touched or touching others."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Haphephobia only effects bosses that are effected by knockback."},
                    {str = "Trivia"},
                    {str = "Haphephobia is the fear of being touched or touching others."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Haphephobia is the fear of being touched or touching others."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            HUNGRY_GRUB = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Hungry Grub is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Travels across the room in the direction the player fires. If Hungry Grub hits an enemy, it begins dealing damage for a short period of time. As Hungry Grub keeps damaging on enemies, it will grow in size and deal more damage. If Hungry Grub feeds on enough enemies, it start to leave a trail of red creep on the ground."},
                    {str = "Hungry Grub growth is reset per room."},
                    {str = "Hungry Grub cannot fly through Rocks."},
                    {str = "Hungry Grub defaults to the last Familiar in the familiar chain."},
                    {str = "As a result of this, collecting a lot of Familiars can make it harder to aim Hungry Grub."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            LIL_MICHAEL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Michael is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Lil Michael can absorb tears shot through him and store their damage for a large attack"},
                    {str = "Lil Michael floats in the direction the player is firing to try and absorb as many tears as he can"},
                    {str = "When the played has shot 20 tears, Lil Michael will attack an enemy with his sword doing damage equal to the amount of tears he has soaked up times 1.5."},
                    {str = "If Lil Michael has soaked up 0 tears, he will deal 0 damage."},
                    {str = "If the players tears have any special qualities, such as Ipecac's explosions, Lil Michael's attack will also have the same properties."},
                    {str = "Synergies"},
                    {str = "Finger!: Finger! constantly activates Lil Michael whether the player is firing or not."},
                    {str = "Notes"},
                    {str = "Bug: Lil Michael cannot absorb certain tear types, such as: Brimstone, Technology lasers, Dr Fetus and Epic Fetus Shots, and Ludo's shot."},
                    {str = "Bug: Brimstone is very bugged to the point that shooting Brimstone 20 times won't even send Lil Michael out for his attack."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Finger!: Finger! constantly activates Lil Michael whether the player is firing or not."},
                    {str = "Notes"},
                    {str = "Bug: Lil Michael cannot absorb certain tear types, such as: Brimstone, Technology lasers, Dr Fetus and Epic Fetus Shots, and Ludo's shot."},
                    {str = "Bug: Brimstone is very bugged to the point that shooting Brimstone 20 times won't even send Lil Michael out for his attack."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Bug: Lil Michael cannot absorb certain tear types, such as: Brimstone, Technology lasers, Dr Fetus and Epic Fetus Shots, and Ludo's shot."},
                    {str = "Bug: Brimstone is very bugged to the point that shooting Brimstone 20 times won't even send Lil Michael out for his attack."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            LOVERS_LIB = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Lover's Libido is a Passive Collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Item pedestals the player finds will grow legs and start fleeing the player."},
                    {str = "If the player catches the pedestal, they will be awarded with a random trinket."},
                    {str = "Notes"},
                    {str = "The player can damage the pedestal, but cannot kill it."},
                    {str = "If Chaos Card is used on the pedestal, it will die and will not drop any item."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The player can damage the pedestal, but cannot kill it."},
                    {str = "If Chaos Card is used on the pedestal, it will die and will not drop any item."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            MIRROR_BOMBS = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Mirror Bombs is a passive collectible added in Revelations Chapter Two."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "+5 Bombs."},
                    {str = "The player's bombs now have different effects based on the current room's appearance."},
                    {str = "This is room-based, not floor-based, so certain special rooms will have different effects regardless of the current floor. This is easily observable in Super Secret Rooms and The Void as most rooms there have varying appearances."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Certain effects may become more powerful depending on the number of mirror shards in the players possession"},
                    {str = "Glacier: Freezes all enemies in the room"},
                    {str = "Tomb: A boulder falls to crush a random enemy"},
                    {str = "Basement, Bedroom: Spawns blue flies"},
                    {str = "Cellar, Shop, Secret: Spawns blue spiders"},
                    {str = "Caves, Catacombs: Farts and poisons nearby enemies"},
                    {str = "Depths, Necropolis: Shoots a burst of bones in random directions"},
                    {str = "Womb, Utero, Scarred Womb, Blue Womb: Spawns damaging creep"},
                    {str = "Sheol: Fires brimstone lasers in cardinal directions"},
                    {str = "Dark Room: Damages all enemies in the room"},
                    {str = "Cathedral: Bombs have a damaging aura"},
                    {str = "Chest, Vault: Unlocks all chests in the room"},
                    {str = "Burning Basement: Spawns a flame"},
                    {str = "Flooded Caves: Randomly shoots tears in the cardinal, diagonal, or hexagonal directions"},
                    {str = "Dank Depths: Spawns slowing creep"},
                    {str = "Downpour, Dross: Shoots a burst of tears in random directions"},
                    {str = "Mines, Ashpit: Spawns rock waves"},
                    {str = "Mausoleum, Gehenna: Spawns homing flames that target and damage enemies"},
                    {str = "Corpse: Spawns a poison gas cloud and randomly fires tears that split on contact"},
                    {str = "Arcade: Has a chance to spawn a coin"},
                    {str = "Library: Has a chance to spawn a card"},
                    {str = "Sacrifice: Has a chance to spawn a heart"},
                    {str = "Planetarium: Has a chance to spawn a rune"},
                    {str = "Dice: Has a chance to activate a random dice room effect"},
                    {str = "Error: Bombs get replaced by random entities, has a small chance to spawn a glitched item"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_BOMB_BUM,
                }
            },
            OPHANIM = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Ophanim is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "For every few shots that the player fires, Ophanim will shoot 4 rotating tears that travel in a counter-clockwise circle around the player for a short time."},
                    {str = "If the player gets hit, Ophanim will detach from the player and fly around the room, firing a large amount of rotating tears. Ophanim will bounce on the walls twice before returning to the player."},
                    {str = "Notes"},
                    {str = "The rate at which Ophanim fires is tied to the player's tear delay."},
                    {str = "Ophanim's tear damage does not scale with the player's."},
                    {str = "If Ophanim is bouncing around the room and is making its way back to the player, the player can move around in a quick circle to outrun Ophanim, which will make Ophanim keep firing more tears."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The rate at which Ophanim fires is tied to the player's tear delay."},
                    {str = "Ophanim's tear damage does not scale with the player's."},
                    {str = "If Ophanim is bouncing around the room and is making its way back to the player, the player can move around in a quick circle to outrun Ophanim, which will make Ophanim keep firing more tears."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Ophanim are wheel-like celestial beings found in the Bible in the books of Daniel, Ezekiel, and Enoch."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            PERSEVERANCE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Perseverance is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Hitting an enemy will show two swords above that enemy's head. This enemy will now take increased damage the more the player hits that enemy, starting at 10% and going up to 200%. The streak is broken if the player hits another enemy."},
                    {str = "Bosses will only take a maximum of 100% increased damage."},
                    {str = "The streak will not be broken by completely missing a shot."},
                    {str = "Notes"},
                    {str = "When the status indicator over the enemy turns red, it means the damage bonuses have reached their cap."},
                    {str = "Synergies"},
                    {str = "Godhead: The damaging aura from Godhead will stack Perseverance, allowing the player to reach the damage cap extremely quickly."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "When the status indicator over the enemy turns red, it means the damage bonuses have reached their cap."},
                    {str = "Synergies"},
                    {str = "Godhead: The damaging aura from Godhead will stack Perseverance, allowing the player to reach the damage cap extremely quickly."},
                },
                { -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
                    {str = "Godhead: The damaging aura from Godhead will stack Perseverance, allowing the player to reach the damage cap extremely quickly."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            PILGRIMS_WARD = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Pilgrim's Ward is a passive collectible added in Revelations Chapter Two."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "In uncleared rooms, a sigil illuminated by a beam of light is present."},
                    {str = "If the player walks over the sigil, it creates a laser ring around itself and reappears somewhere else in the room."},
                    {str = "The laser ring homes in on enemy positions, and will also adjust its radius depending on how close or far the nearest enemy is."},
                    {str = "Notes"},
                    {str = "The laser ring synergizes with most items that affect lasers, and also scales with the player's damage."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "The laser ring synergizes with most items that affect lasers, and also scales with the player's damage."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Pilgrim's Ward was thought up in the last week of Chapter 2's development as a replacement for Broken Wings."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_ANGEL,
                }
            },
            PRIDES_POSTURING = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Pride's Posturing is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon firing for the first time in a room with enemies, Isaac will fire Pride lasers in the four diagonal directions while activating any player hurt effects they may have (such as Dead Bird)."},
                    {str = "Note"},
                    {str = "BUG As of the current version, Pride's Posturing incorrectly triggers Holy Mantle's effect, removing it from the player."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            SLOTHS_SADDLE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Sloth's Saddle is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "In cleared rooms, the player will have max speed."},
                    {str = "When the player does a collective 10 damage, a mini charger will spawn."},
                    {str = "The charger will charge around the room, dealing small amounts of damage to enemies."},
                    {str = "They will die when the room is cleared"},
                    {str = "Notes"},
                    {str = "Mini Chargers do not instantly die when rooms are cleared. If the player quickly moves into the next room, the previously spawned chargers will follow."},
                    {str = "The 10 damage needed to spawn mini chargers count for:"},
                    {str = "Black Heart damage."},
                    {str = "Bombs the player drops."},
                    {str = "But will NOT count for:"},
                    {str = "Familiar damage (except for Incubus, which will count)."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Mini Chargers do not instantly die when rooms are cleared. If the player quickly moves into the next room, the previously spawned chargers will follow."},
                    {str = "The 10 damage needed to spawn mini chargers count for:"},
                    {str = "Black Heart damage."},
                    {str = "Bombs the player drops."},
                    {str = "But will NOT count for:"},
                    {str = "Familiar damage (except for Incubus, which will count)."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            VIRGIL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Virgil is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effect
                    {str = "Effect", fsize = 2, clr = 3, halign = 0},
                    {str = "On the field:"},
                    {str = "Virgil guides the player through the floor, pointing to doors that lead to Treasure Rooms, Shops, and Boss Rooms."},
                    {str = "Virgil points out tinted rocks by throwing rocks at them. Virgil can do this three times per floor."},
                    {str = "If the player has no bombs, Virgil will instead throw a bomb at the tinted rock. Virgil can do this three times per floor."},
                    {str = "Virgil smacks nearby Troll Bombs away from the player."},
                    {str = "If the player dies, Virgil revives the player in the previous room with full health. Virgil can only do this once."},
                    {str = "In fights:"},
                    {str = "Virgil can throw a rock at enemies, which taunts them into chasing him."},
                    {str = "If the player takes collision damage, Virgil will angrily scold the enemy with a firm point, confusing the enemy for a short amount of time."},
                    {str = "Notes"},
                    {str = "Virgil has a 1/25 chance to spawn in the beginning of Revelation's floors. By walking over Virgil, the player recruits him for the floor."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Virgil has a 1/25 chance to spawn in the beginning of Revelation's floors. By walking over Virgil, the player recruits him for the floor."},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "In Divine Comedy, Virgil is a character who guides Dante through Hell and Purgatory."},
                    {str = "In the work, the character Virgil is based on Roman poet Publius Vergilius Maro."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
                    Encyclopedia.ItemPools.POOL_GREED_SHOP,
                }
            },
            WANDERING_SOUL = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Wandering Soul is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a ghost familiar which randomly takes the appearance of vanilla Binding of Isaac characters each room. The character that the ghost is portraying will have that characters regular base stats (Magdalene will be slow, Judas will do more damage, ect.)."},
                    {str = "These ghosts will follow enemies, shooting tears (or brimstone, in Azazel's case) at them from a distance."},
                    {str = "Notes"},
                    {str = "BFFS! does not affect Wandering Soul, nor does Birth Control."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "BFFS! does not affect Wandering Soul, nor does Birth Control."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_SECRET,
                }
            },
            WILLO = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Willo is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Willo bounces around the room, akin to the Wisps."},
                    {str = "Willo has a set path, but will move slightly away from the player if they are close."},
                    {str = "Willo produces a purple aura. When standing inside of it, the player will gain a 30% increase in damage."},
                    {str = "Willo will fire a homing tear at a nearby enemy when the player takes damage."},
                    {str = "Trivia"},
                    {str = "Willo's item concept used to be apart of the Pact of Radiance's bonus effect prior to the Sin Update."},
                    {str = "Gallery"},
                },
                { -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
                    {str = "Willo's item concept used to be apart of the Pact of Radiance's bonus effect prior to the Sin Update."},
                    {str = "Gallery"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
            WRATHS_RAGE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Wrath's Rage is a passive collectible added in Chapter 2's Sin Update."},
                },
                { -- Effect
                    {str = "Effect", fsize = 2, clr = 3, halign = 0},
                    {str = "Grants the player +5 bombs."},
                    {str = "Upon placing a bomb, it will instantly explode on the player, granting a damage increase in increments."},
                    {str = "The increments are 1, .5, .25, .13, .6, .3, .2, .1"},
                    {str = "The player will only get a damage increase for the first 8 bombs they place in the room"},
                    {str = "After the player places the third bomb, mini-fires will begin to trail the player, damaging enemies."},
                    {str = "The damage increase resets upon entering another room."},
                    {str = "Notes"},
                    {str = "Whilst the player will not take any damage from his own bombs, they will still take damage from other explosions."},
                    {str = "Upon using bombs, the costume will change to make Isaac appear more angry."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Whilst the player will not take any damage from his own bombs, they will still take damage from other explosions."},
                    {str = "Upon using bombs, the costume will change to make Isaac appear more angry."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
			PRESCRIPTION = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Prescription is a passive collectible added in Revelations Chapter 2's Neapolitan Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Drops a random pill."},
                    {str = "When entering a new room, has a chance to take a pill that the player has taken previously."},
                    {str = "Positive pills have a higher chance of activating than negative pills."},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
					Encyclopedia.ItemPools.POOL_GREED_SHOP,
                    Encyclopedia.ItemPools.POOL_CRANE_GAME,
                }
            },
			GEODE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Geode is a passive collectible added in Revelations Chapter 2."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "The Geode drops one random rune upon pickup."},
                    {str = "All soul heart drops from tinted rocks are replaced by rune drops."},
                },
				{ -- Notes
					{str = "Notes", fsize = 2, clr = 3, halign = 0},
					{str = "If the player has no runes unlocked, random cards will drop."},
				},
                Pools = {
                    Encyclopedia.ItemPools.POOL_SECRET,
                    Encyclopedia.ItemPools.POOL_GREED_SECRET,
                }
            },
			NOT_A_BULLET = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Not a Bullet is a passive collectible added in Revelations Chapter 2's Neapolitan Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Gives the player +0.2 shot speed."},
                    {str = "The players damage scales up based on their shot speed stat"},
                },
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                    Encyclopedia.ItemPools.POOL_BOSS,
                }
            },
			SMBLADE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Super Meat Blade is an activated collectible added in Revelations Chapter 2's Neapolitan Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "When used, the player will hold the blade above his head. Firing in any direction will send out a large saw blade, which will attach to a wall and begin to circle the room. The blade damages enemies and the player on contact"},
                    {str = "If there is a saw active in the room, activating the item will cause all blades in the room to travel across the room to the opposite wall."},
					{str = "This can be done even when the item is recharging."},
					{str = "The item can be used multiple times in a room if the player waits for it to recharge, allowing for multiple saws to be active at once."},
                },
				{ -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
					{str = "This item is a reference to one of Edmund McMillen's other games, Super Meat Boy."},
				},
                Pools = {
                    Encyclopedia.ItemPools.POOL_TREASURE,
                    Encyclopedia.ItemPools.POOL_GREED_TREASURE,
                }
            },
			DRAMAMINE = {
                { -- Info
                    {str = "Info", fsize = 2, clr = 3, halign = 0},
                    {str = "Dramamine is an activated collectible added in Revelations Chapter 2's Neapolitan Update."},
                },
                { -- Effects
                    {str = "Effects", fsize = 2, clr = 3, halign = 0},
                    {str = "Spawns a stationary explosive tear that acts like a landmine."},
                    {str = "Explodes when enemies comes into contact with it."},
					{str = "This explosion can damage the player, as well as destroy objects, like a normal bomb."},
					{str = "The tear spawned synergizes with the player's tear modifier items."},
                },
				{ -- Synergies
                    {str = "Synergies", fsize = 2, clr = 3, halign = 0},
					{str = "Lachryphagy: Spawns an explosive hungry shot that can be fed tears to increase in power."},
					{str = "Jacob's Ladder: Shoots out electricity when exploded."},
				},
				{ -- Trivia
                    {str = "Trivia", fsize = 2, clr = 3, halign = 0},
					{str = "Dramamine is a real drug used to stop nausea and vomiting, usually in tablet form."},
				},
                Pools = {
                    Encyclopedia.ItemPools.POOL_SHOP,
                    Encyclopedia.ItemPools.POOL_GREED_SHOP,
                }
            },
        }
        
        for name,desc in pairs(ItemWiki) do
            Encyclopedia.AddItem({
                Class = "Revelations",
                ID = REVEL.ITEM[name].id,
                WikiDesc = desc,
                Pools = desc.Pools
            })
        end
        
        -- cards
        
        Encyclopedia.AddCard({ -- Lottery Ticket
            Class = "Revelations",
            ID = REVEL.POCKETITEM.LOTTERY_TICKET.Id,
            WikiDesc = {
                { -- Effect
                    {str = "Effect", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, items for sale or items on pedestals will quickly cycle among the other items in that room's pool, and won't stop cycling until the player buys the item or picks it up."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "Since it affects items for sale, Devil Deal items with also cycle."},
                    {str = "If the player has Chaos, the cycle will change based upon whatever the room's pool was changed to."},
                },
            },
            Sprite = Encyclopedia.RegisterSprite("../content/gfx/ui_cardfronts.anm2", "55_LotteryTicket"),
        })
        
        Encyclopedia.AddCard({ -- Bell Shard
            Class = "Revelations",
            ID = REVEL.POCKETITEM.BELL_SHARD.Id,
            WikiDesc = {
                { -- Effect
                    {str = "Effect", fsize = 2, clr = 3, halign = 0},
                    {str = "Upon use, adds a random effect for the level, like the ones triggered by the Heavenly Bell item."},
                },
                { -- Notes
                    {str = "Notes", fsize = 2, clr = 3, halign = 0},
                    {str = "More uses in a level will create more effects, also stacking with the Heavenly Bell item itself."},
                },
            },
            Sprite = Encyclopedia.RegisterSprite("../content/gfx/ui_cardfronts.anm2", "BellShard"),
        })
        
    end

    ------------------------
    -- Music mod callback --
    ------------------------

    if MMC then
        REVEL.musicNoMMC = MusicManager()
        REVEL.music = MMC.Manager()
    end

    ----------------------
    -- Potato For Scale --
    ----------------------

    local function loadCompatValues()

        REVEL.COMP_ENTS = {
            POTATO_FOR_SCALE = REVEL.ent("Potato Dummy")
        }

    end

    revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, loadCompatValues)

    if Isaac.GetPlayer(0) then
        loadCompatValues()
    end

    -----------------
    -- Fiend Folio --
    -----------------

    local function LoadFiendFolioCompat(typeLoaded)
        if not FiendFolio then return end

        REVEL.FiendFolioCompatLoaded = REVEL.FiendFolioCompatLoaded or {}
        REVEL.FiendFolioCompatLoaded[typeLoaded] = true
    end

    local loadType = 1
    if FiendFolio then
        LoadFiendFolioCompat(loadType)
    else
        revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, function()
            if FiendFolio and not (REVEL.FiendFolioCompatLoaded or REVEL.FiendFolioCompatLoaded[loadType]) then
                LoadFiendFolioCompat(loadType)
            end
        end)
    end

    ------------------------
    -- Enhanced Boss Bars --
    ------------------------

    local function eString(ent)
        return ent.id .. "." .. ent.variant
    end

    local function LoadHPBars()
        if HPBars.BossIgnoreList then
            HPBars.BossIgnoreList[eString(REVEL.ENT.CHUCK_ICE_BLOCK)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_SNOWPILE)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_STALAGMITE)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.WILLIWAW)] = function(entity) 
                if entity.SubType > 0 then return true end end
            HPBars.BossIgnoreList[eString(REVEL.ENT.WENDY_SNOWPILE)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.NARCISSUS_MONSTROS_TOOTH)] = function(entity) return true end

            HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_CRICKET)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_TAMMY)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_GUPPY)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.CATASTROPHE_MOXIE)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.ARAGNID_INNARD)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.SARCOPHAGUTS_HEAD)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.JEFFREY_BABY)] = function(entity) return true end
            HPBars.BossIgnoreList[eString(REVEL.ENT.LOVERS_LIB_PD)] = function(entity) return true end
        end
        REVEL.HPBarsCompatLoaded = true
    end

    if HPBars then
        LoadHPBars()
    else
        revel:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.IMPORTANT, function()
            if HPBars and not REVEL.HPBarsCompatLoaded then
                LoadHPBars()
            end
        end)
    end

    Isaac.DebugString("Revelations: Loaded Common Mod Compatibility!")
end