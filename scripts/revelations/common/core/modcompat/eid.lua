return function ()
    
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


-----Descriptions on Russian-----

if not __eidRusItemDescriptions then -- Items
    ---@diagnostic disable-next-line: lowercase-global
    __eidRusItemDescriptions = {}
end

__eidRusItemDescriptions[REVEL.ITEM.HEAVENLY_BELL.id] = {"Heavenly Bell / �������� �������", "���� ��������� ������� ���� �� �������� �� ������ �����:#1) � ������ ��������� ������� ����� ��������#2) �� ������������ ��������� �������� ���������#3) ����� � ������ �������� ���� �����#4) 3 ��������� ����� ����� �� ����� (���� �� �� �������� �����)#5) ����� ������ �� ����������� � ���� ������ �������#6) ��� ��������� ������ ����� �������� ���"}
__eidRusItemDescriptions[REVEL.ITEM.MINT_GUM.id] = {"Mint Gum / ������ ������", "����� ��������� ������#5 ������������ ��������� ��������� �����"}
__eidRusItemDescriptions[REVEL.ITEM.FECAL_FREAK.id] = {"Fecal Freak / ��������", "�������� ����� �� ������� ����� �������#� 1.5� ��������� �����#� +1.5 � �����#� �25% ��������� ��������#� �25% �������� �����"}
__eidRusItemDescriptions[REVEL.ITEM.LIL_BELIAL.id] = {"Lil Belial / ����� ������", "�������� ������#��������� ���������� ������#���� ����� ����� � ��� �������, � ������� �� ������� ����� ������, ���� �������"}
__eidRusItemDescriptions[REVEL.ITEM.AEGIS.id] = {"Aegis / �����", "���, ������� ������ ���������#��������� ��������"}
__eidRusItemDescriptions[REVEL.ITEM.BIRTHDAY_CANDLE.id] = {"Birthday Candle / ����� �� ��� ��������", "���� �������, �������� � ��� ���:#���� ��� ������ ���� - ���� ������ ����#���� ��� ������ - ���� ����#���� ��� ���� - ���� �����#���� ������ 15 ����� - ���� ��������#� � ���� ������ ���� + �� ���� ���������������"}
__eidRusItemDescriptions[REVEL.ITEM.DYNAMO.id] = {"Dynamo / ���������", "�������������� ������������ �����#������������ ������ ������"}
__eidRusItemDescriptions[REVEL.ITEM.BURNBUSH.id] = {"Burning Bush / ���������� ������", "�������, ����������� �������� ��������."}
__eidRusItemDescriptions[REVEL.ITEM.PENANCE.id] = {"Penance / ��������", "���� ������ � ������ �������� �����:#� +0.06 � �������� ����� �� ������ ���-������ ����#� +1 � ����� �� ������ ������� ������#� +0.15 � ����� �� ������ ���-������� ������"}
__eidRusItemDescriptions[REVEL.ITEM.ICETRAY.id] = {"Ice Tray / �������� ��� ����", "����� �������� ��������, ����������� �� ����#��������� ����� �� ����"}
__eidRusItemDescriptions[REVEL.ITEM.CLEANER.id] = {"Window Cleaner / ���������� ����", "����� ������� �������� ����� ������"}
__eidRusItemDescriptions[REVEL.ITEM.SPONGE.id] = {"Sponge Bombs / �����-�����", "����� ��������� �����#������� ������ �����, � ����������� �� ���������� ����������� ����"}
__eidRusItemDescriptions[REVEL.ITEM.PATIENCE.id] = {"Spirit of Patience / ��� ��������", "�������� ������� ������� ������ 0.3 ���., ���� ������ �� �����"}
__eidRusItemDescriptions[REVEL.ITEM.TAMPON.id] = {"Cutton Bud / ������ �������", "�������� ����� ��������� ����#���������� ���� �� ����� �������� ���� ����������������"}
__eidRusItemDescriptions[REVEL.ITEM.BCONTROL.id] = {"Birth Control / �����������������", "�������� ���������#� ������ ���� + � �����"}
__eidRusItemDescriptions[REVEL.ITEM.TBUG.id] = {"Tummy Bug, ���������� ���", "����� ���������� ����������� �������� �������� ��������� ���������, �������� � �������� ������ ����� ������� ���� �� ������� ����"}
__eidRusItemDescriptions[REVEL.ITEM.FFIRE.id] = {"Friendly Fire / ������������� �����", "��������� � ����#������ ������ ������ ����� �������� �� ������"}
__eidRusItemDescriptions[REVEL.ITEM.MONOLITH.id] = {"The Monolith / �������", "������������� ��� ���� �������#�������� ����� ����, ����� ������� �� 3 �������"}
__eidRusItemDescriptions[REVEL.ITEM.HYPER_DICE.id] = {"Hyper Dice / ����� �����", "������ �������� ������ ������#����������, ���� ������������ ������� �����"}
__eidRusItemDescriptions[REVEL.ITEM.MIRROR.id] = {"Mirror Shard / ������� �������", "����������� �������, �������� �������#����������� ������������ �� ������"}

if not __eidRusTrinketDescriptions then -- Trinkets
    ---@diagnostic disable-next-line: lowercase-global
    __eidRusTrinketDescriptions = {}
end

__eidRusTrinketDescriptions[REVEL.ITEM.SPARE_CHANGE.id] = {"Spare Change / ������ �����", "���� ����� ��� ����� � �������#���� 3 ����� ��� ����� � ������� �������#���� ������ ���� ��� ����� � ������� �������"}
__eidRusTrinketDescriptions[REVEL.ITEM.LIBRARY_CARD.id] = {"Library Card / ������������ �����", "���������� ���� � ����������"}
__eidRusTrinketDescriptions[REVEL.ITEM.ARCHAEOLOGY.id] = {"Archaeology / ����������", "������, �����, ������, ������ � ����� ���� � ��� ���� ���� ��������� �������� �������� ��� ����������"}
__eidRusTrinketDescriptions[REVEL.ITEM.GAGREFLEX.id] = {"Gag Reflex / ������� �������", "����� �������� ������ �������� �������� ������ �������� ����� � �������� �������"}

if not __eidRusCardDescriptions  then -- Cards
    ---@diagnostic disable-next-line: lowercase-global
    __eidRusCardDescriptions  = {}
end

__eidRusCardDescriptions[REVEL.POCKETITEM.LOTTERY_TICKET] = {"Lottery Ticket / ���������� �����", "������� ������� ����������, ������� ������ ��������� � �������"}

end