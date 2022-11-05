## 4.0.1

- Temporarily disable XL Rev floors until we find
a way to fix those properly
- Minor room tweaks

## Vanity Update - 4.0.0

Major Features

- Replace the Hub room with Hub 2, inside of the Repentance transition room, and usable by other mods. Old Hub can be enabled via setting, and is still found in the starting room
- Shrine System overhaul: Shrines give Vanity, can be exchanged for rewards at chapter end in a new shop. The shop has many fun things...
- New shrines, detailed below
- New enemies and an elite, detailed below
- Many boss balance tweaks and reworks, detailed below
- MinimapAPI included with the mod, installing the standalone version is still supported and also recommended to have it always up to date

New enemies

+ Jackal
+ Gilded Jackal
+ Stabstack
+ Ragma
+ Harfang
+ Pine
+ Pinecone
+ Snot Rocket
+ Dune
+ Blockblockblockhead Gapers
+ New Elite: Ragtime, with his troupe

New shrines

+ Pact of Champions
+ Pact of Grounding
+ Pact of Scarcity
+ Pact of Masochism
+ Pact of Punishment
+ Pact of Hemorrhage
+ Pact of the Ice Wraith
+ Pact of Paranoia

Major general tweaks

- Dante and Charon: Phylactery is a pocket active item
- Dante and Charon: no longer force Curse of the Labyrinth, instead each character has a separate map memory
- Glacier general graphics overhaul
- Tomb grids graphics overhaul
- Glacier is smaller (experimental)
- Revending machine can have different item pools, and support for shop affecting items
- Old hub has Repentance functionality if option is used, making Rev stages cost keys/bombs too
- Birthright for Sarah and Dante and Charon
- Custom tracks for boss calm, shop, secret rooms, and more in rev floors, from the Afterlife OST (with permission)
- Rev items support transformations
- Restore rev item weights to normal, currently dynamic weight system + base weights made rev items way rarer
- Add setting to disable dynamic item weights, setting rev items to always baseline weight
- Sinami now has a reward, as Bertran is out and about, increases with retries
- Something with Narcissus?


Major boss tweaks

- Chuck rework, doesn't use invincibility anymore and completely overhauled fight pattern
- Sarcophaguts: buttons don't get all lowered when one is pressed, hard cap on gut amount, lower bullet speed and easier patterns, less hp, slightly more boulder damage, vulnerable during laser attack, guts spawn more spaced out to reduce shielding, buttons move slowly instead of completely stopping, can be shot from any angle instead of just the front when open, head only shoots when player is close, no long rooms, rework phase 2 guts attack
- Narc 2: shard explosion has tracer tells, pillars can be damaged without bombs but less
- Sandy: final attack lasts less (even less for Jeffrey), Jeffrey starts at 50% HP, has slightly reduced damage
- Maxwell lasers have a telegraph
- Willywaw: more damage reduction during phase transitions, can only do Beast Winds attack once in phase 1, increased snowflake speed for it, and lasts much less for clone, clones no longer block shots, more time to shoot snowflakes during wind attack, Gateway Sniping slows down player
- Catastrophe: yarn leaves a trail when it is damaging, remove shield for guppy's urn
- Raging Long Legs: decreased health from spawns, reduced spider spawns
- Punker: no longer shoots puckers during dash, more brimstone laser telegraph, removed from catacombs
- Dungo: has high damage reduction instead of invincibility, hp bar streamlined during fight so boss progress is more visible, reduce shockwave fart frequency, reduced fart range, projectiles are more predictable, red poop projectiles no longer bounce, reduced red poop cap, small delay between phase 2 plunger attacks, shockwaves are targeted, coffins have a cooldown, golden boulders take damage when dropping coins
- Auroric Glacier Pride
- Snotty Glacier Sloth
- Tomb Gluttony has damage reduction instead of invincibility
- Elite HP nerfed
- Added GigaChuck


Other changes

* Heavy internal refactor and rework
- Pact of Gratuity renamed to Pact of Mischief
- Pact of Radiance renamed to Pact of Frost
- Improve how custom rooms (mirror, etc) work thanks to StageAPI changes
- Slightly improve reflections depending on character
- Better glacier shaders are default, since Repentance they should be compatible with all graphics cards (that support Repentance)
- Rev floors' name streak can now show up when holding tab
- More sounds
- Setting for global mod sound volume
- Hud Offset setting automatically matched without manual config
- "Never won with" no longer increases rev item chance with dynamic item weight
- Starting room doodles for the rev characters
- Dynamo has a charge bar
- Elites have a 33% chance to drop boss pool items
- Narcissus 1 and 2 have outro jingles
- Fragile ice easier to see
- `rperf` command to test out performance of the mod via the log
- Shrine pacts have HUD icons
- Add `addv` command to add Vanity, `vshop` command to teleport to the vanity shop, `revpact` command to add a shrine pact
- Tinted rock spiders drop runes with Geode
- Can push hockey puck with swords/bones
- Settings include a reset save button
- Punker and RLL no longer required for the champions achievements
- Freezing snowballs leave snow particles
- Sand castle affected by archaeology, custom drops
- Urny: clearer tell, no longer recoils off enemies
- Wendy: damage reduction on phase transition
- Freezerburn and Tomb Gluttony have a different color damage flash to show damage is being reduced
- Remove Window Cleaner from boss item pool
- Buff moxie's paw damage
- More birth control effects for Rep familiars
- Mirror bombs updated for rep floors
- Ghost pepper, bird's eye, red candle can now break ice rocks
- Rag family has glow eyes when buffed
- More glow effects in general
- Glacier Lust's body leaves creep for easier seeing
- Fragile ice has a warning before snowsts break it
- Narcissus 1 and 2 have a VS screen after the first encounter

- A lot of new sfx!
- Various minor sprite updates
- Various minor polish
- Various numerical boss and enemy tweaks 
- More optimization, hopefully
- Lots of bug fixes, too many to write and/or remember
- More rooms

Internals

* Split most things into their own file
* Made naming and spacing more consistent
* StageAPI metaent update: Use StageAPI directions for traps too in rooms, etc.
* Rev library is separated into various files, and has a `library.md` file to list all its functions. `library.md` can be generated/updated with a Python script, `generate_library_list.py`.
* XML script to merge shaders 
* Rev now contains an `enums` folder that contains various custom enum files for rev and missing vanilla stuff, including rev/stageAPI callbacks
* add `idcheck.py` to check for used ids in entities2.xml


