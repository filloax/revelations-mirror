-- Keep lines at max 40 characters, can use for that https://www.gillmeister-software.com/online-tools/text/add-line-breaks_change-line-length.aspx
REVEL.AddChangelog("Vanity (4.1.2)", "Dec 3 2022", [[- Community rooms! 
- Tomb Prank now has sand attack
- Nerf igloo firerate 
- Lovers libido works with curse 
of the blind 
- Vanity shops + curse of the blind fix 
- Narc spikes can't be mitosed 
- Minor epiphany compat tweak for 
vanity shop ]])
REVEL.AddChangelog("Vanity (4.1.1)", "Nov 19 2022", [[- Perseverance: quality 3 
- Punishment: cannot attempt steal 
Legemeton wisps 
- Various room tweaks 
- Fix room-related crash]])
REVEL.AddChangelog("Vanity (4.1.0)", "Nov 15 2022", [[- Add trinket: Memory Cap 
- Add trinket: Christmas Stocking
- Add object: Bell Shard 
- Add shrine: Pact of Mitosis
- Rev pocket items have announcer voice 
lines 
- Tutorial rooms for some rev floor 
mechanics that are much more likely to 
appear until first encountered 
- New rooms 
- New Fiend Folio-compat rooms, 
including skins for many FF enemies 

- Update internal MinimapAPI

Tweaks 
- Tweaked HP of a lot of Rev monsters 
- D+C: no bonus heart 
- D+C: extra boss items only on second 
stages 
- Sandshaper: AI rework, active instead 
of reactive 
- Dungo: shockwaves target player, can 
die before phase 2 
- Rag fatty: buffed 
- Anima: faster 
- Bloatbip: faster 
- Antlion egg: spawns less babies with 
more HP 
- Tomb revive traps close doors 
- Some item quality 
- Pact of grounding: 2->3 vanity 
- Vaniy shop items spawn the 
collectible, should be more compatible 
with various game features 
- More SFX 
- More EID support 

Fixes 
- D+C item dupes and knife/rep 
sequences issues 
- Rev item tracking counting fake items 
as real 
- Death certificate in rev stages, half 
of this on the StageAPI side 
- Mirror room shard dupe or vanishing 
- Elites being guaranteed, weren't 
supposed to 
- Champion Prong not needing 
achievement 
- Dynamo]])
REVEL.AddChangelog("Vanity (4.0.3)", "Nov 6 2022", [[- Vanity has functions for other mods
to spawn their own vanity shop items
- Hice and Iced Hive have new effects
when killed
- Rebalanced HP of several Glacier 
enemies
- Nerf Sarah demon speed
- Faster snowst attack
- Various reskins for FF enemies
- Increase sandbip hitbox
- Change ragtag behavior
- Room updates
- Fix Dante+Charon unlocks
- Fix Dante Satan room appearing for
sarah in her angel room
- Fixed a certain fun easter egg
- Fix birth control + legemeton
- Fix FF rooms not appearing
- Fix EID mod name
- Fix maxwell softlock with 
charmed enemies
- Remove old glacier bosses from
champion achievement
- Fix stalagmight + dark arts
- Fix fragile ice pit respawning]])
REVEL.AddChangelog("Vanity (4.0.2)", "Nov 5 2022", [[- Fix data not resetting between runs,
leading to persisting shrine pacts,
charon items and mirror door not
spawning again
- Fix Chuck softlock
- Ice Wraith doesn't block Dead Sea
Scrolls menu update (might need an
update in other mods that use DSS)
- Williwaw loses the dmg reduction if
he stays in  his intro for too long
- Increase aura radius of coal shards
- Increase vanity price of q4 items by
1, reduced the vanity price of the more
expensive items
- Fix haugrs not working
- Cracked key can be used in a certain
room too other than the red key
- Glass shards can no longer be abused
to respawn by rerolling etc.
- revunlock command is no longer 
tied to DEBUG mode]])
REVEL.AddChangelog("Vanity (4.0.1)", "Nov 4 2022", [[Hotfix
- Disable XL Rev floors until we find
a way to properly fix them
- Minor room tweaks

This is just an hotfix, full patch notes
for the update are in the previous
changelog]])
REVEL.AddChangelog("Vanity (4.0.0)", "Nov 4 2022", [[** Major Features
- Replace the Hub room with Hub 2, 
inside of the Repentance transition 
room, and usable by other mods. Old Hub 
can be enabled via setting, and is 
still found in the starting room 
- Shrine System overhaul: Shrines give 
Vanity, can be exchanged for rewards at 
chapter end in a new shop. The shop has 
many fun things... 
- New shrines, detailed below 
- New enemies and an elite, detailed 
below 
- Many boss balance tweaks and reworks, 
detailed below 
- MinimapAPI included with the mod, 
installing the standalone version is 
still supported and also recommended to 
have it always up to date 

** New enemies 

- Jackal 
- Gilded Jackal 
- Stabstack 
- Ragma 
- Harfang 
- Pine 
- Pinecone 
- Dune 
- Snot Rocket 
- Blockblockblockhead Gapers 
- New Elite: Ragtime, with his troupe 

** New shrines 

- Pact of Champions 
- Pact of Grounding 
- Pact of Scarcity 
- Pact of Masochism 
- Pact of Punishment 
- Pact of Hemorrhage 
- Pact of the Ice Wraith 
- Pact of Paranoia 

** Major general tweaks 

- Dante + Charon: Phylactery is a 
pocket active item 
- Dante + Charon: no longer force Curse 
of the Labyrinth, instead each 
character has a separate map memory 
- Glacier general graphics overhaul 
- Tomb grids graphics overhaul 
- Glacier is smaller (experimental) 
- Revending machine can have different 
item pools, and support for shop 
affecting items 
- Old hub has Repentance functionality 
if option is used, making Rev stages 
cost keys/bombs too 
- Birthright for Sarah and Dante +
Charon 
- Custom tracks for boss calm, shop, 
secret rooms, and more in rev floors, 
from the Afterlife OST (with 
permission) 
- Rev items support transformations 
- Restore rev item weights to normal, 
currently dynamic weight system + base 
weights made rev items way rarer 
- Add setting to disable dynamic item 
weights, setting rev items to always 
baseline weight 
- Sinami now has a reward, as Bertran 
is out and about, increases with 
retries 
- Something with Narcissus?


** Major boss tweaks 

- Chuck rework, doesn't use 
invincibility anymore and completely 
overhauled fight pattern 
- Sarcophaguts: buttons don't get all 
lowered when one is pressed, hard cap 
on gut amount, lower bullet speed and 
easier patterns, less hp, slightly more 
boulder damage, vulnerable during laser 
attack, guts spawn more spaced out to 
reduce shielding, buttons move slowly 
instead of completely stopping, can be 
shot from any angle instead of just the 
front when open, head only shoots when 
player is close, no long rooms, rework 
phase 2 guts attack 
- Narc 2: shard explosion has tracer 
tells, pillars can be damaged without 
bombs but less 
- Sandy: final attack lasts less (even 
less for Jeffrey), Jeffrey starts at 
50% HP, has slightly reduced damage 
- Maxwell lasers have a telegraph 
- Willywaw: more damage reduction 
during phase transitions, can only do 
Beast Winds attack once in phase 1, 
increased snowflake speed for it, and 
lasts much less for clone, clones no 
longer block shots, more time to shoot 
snowflakes during wind attack, Gateway 
Sniping slows down player 
- Catastrophe: yarn leaves a trail when 
it is damaging, remove shield for 
guppy's urn 
- Raging Long Legs: decreased health 
from spawns, reduced spider spawns 
- Punker: no longer shoots puckers 
during dash, more brimstone laser 
telegraph, removed from catacombs 
- Dungo: has high damage reduction 
instead of invincibility, hp bar 
streamlined during fight so boss 
progress is more visible, reduce 
shockwave fart frequency, reduced fart 
range, projectiles are more 
predictable, red poop projectiles no 
longer bounce, reduced red poop cap, 
small delay between phase 2 plunger 
attacks, shockwaves are targeted, 
coffins have a cooldown, golden 
boulders take damage when dropping 
coins 
- Auroric Glacier Pride 
- Tomb Gluttony has damage reduction 
instead of invincibility 
- Elite HP nerfed 
- Add GigaChuck 


** Other changes 

- Heavy internal refactor and rework 
- Pact of Gratuity renamed to Pact of 
Mischief 
- Pact of Radiance renamed to Pact of 
Frost 
- Improve how custom rooms (mirror, 
etc) work thanks to StageAPI changes 
- Slightly improve reflections 
depending on character 
- Better glacier shaders are default, 
since Repentance they should be 
compatible with all graphics cards (
that support Repentance) 
- Rev floors' name streak can now show 
up when holding tab 
- More sounds 
- Setting for global mod sound volume 
- Hud Offset setting automatically 
matched without manual config 
- "Never won with" no longer increases 
rev item chance with dynamic item 
weight 
- Starting room doodles for the rev 
characters 
- Dynamo has charge bar 
- Elites have a 33% chance to drop boss 
pool items 
- Narcissus 1+2 have outro jingles 
- Fragile ice easier to see 
- rperf command to test out performance 
of the mod via the log 
- Shrine pacts have HUD icons 
- Add addv command to add Vanity, vshop 
command to teleport to the vanity shop, 
revpact command to add a shrine pact 
- Tinted rock spiders drop runes with 
Geode 
- Can push hockey puck with 
swords/bones 
- Settings include a reset save button 
- Punker and RLL no longer required for 
the champions achievements 
- Freezing snowballs leave snow 
particles 
- Sand castle affected by archaeology, 
custom drops 
- Urny: clearer tell, no longer recoils 
off enemies 
- Wendy: damage reduction on phase 
transition 
- Freezerburn and Tomb Gluttony have a 
different color damage flash to show 
damage is being reduced 
- Remove Window Cleaner from boss item 
pool 
- Buff moxie's paw damage 
- More birth control effects for Rep 
familiars 
- Mirror bombs updated for rep floors 
- Ghost pepper, bird's eye, red candle 
can now break ice rocks 
- Rag family has glow eyes when buffed 
- More glow effects in general 
- Glacier Lust's body leaves creep for 
easier seeing 
- Fragile ice has a warning before 
snowsts break it 
- Narcissus 1+2 have a VS screen after 
the first encounter 

- A lot of new sfx! 
- Various minor sprite updates 
- Various minor polish 
- Various numerical boss and enemy 
tweaks 
- More optimization, hopefully 
- Lots of bug fixes, too many to write 
and/or remember 
- More rooms 

** Internals 

- Split most things into their own file 
- Made naming and spacing more 
consistent 
- StageAPI metaent update: Use StageAPI 
directions for traps too in rooms, etc. 
- Rev library is separated into various 
files, and has a library.md file to 
list all its functions. library.md can 
be generated/updated with a Python 
script, generate_library_list.py. 
- XML script to merge shaders 
- Rev now contains an enums folder that 
contains various custom enum files for 
rev and missing vanilla stuff, 
including rev/stageAPI callbacks 
- add idcheck.py to check for used ids 
in entities2.xml]])
REVEL.AddChangelog("Neap.Update (v3.0.5a)", "Dec 15 2020", [[-Fixed items]])
REVEL.AddChangelog("Neap.Update (v3.0.5)", "Dec 13 2020", [[-Chuck nerfs,
has resist instead of
invulnerability and
other minor tweaks

-Chuck has a new
death sequence

-New glacier rooms

-Mirror fragment no longer
removes mirror shard]])
REVEL.AddChangelog("Neap.Update (v3.0.4)", "Dec 07 2020", [[-Wendy and Bertran fix

-Menu changes,
changelog changes

-Reduced Rev item weights]])
REVEL.AddChangelog("Neap.Update (v3.0.3)", "Nov 25 2020", [[**ANNOUNCEMENT

Bertran, the Ch.3 charachter, got
released as a standalone mod by
DeadInfinity and Melon! Find it
in the Steam Workshop and linked
in Revelations' mod page

** Changelog

-Added External Item Descriptions
descriptions for Neapolitan items

-Williwaw tweaks

-Wendy fixes

-New Glacier rooms by Sunil

-New boss rooms, and tweaks

-Minor aragnid tweak

-Minor fixess
]])
REVEL.AddChangelog("Neap.Update (v3.0.2)", "Nov 14 2020", [[-Freezer burn tweaks,
now fires deal more damage to him
while not headless, but normal
attacks deal less damage at the same
time to encourage using the fires
against him

-Monsnow now in Glacier boss challenge
rooms, while Flurry Jr. and Duke of
Flakes are definitely dead

-Tweaks to Williwaw

-Hp scaling tweaks, especially
to forgotten
]])

REVEL.AddChangelog("Neap.Update (v3.0.1)", "Nov 10 2020", [[-Rebalanced stalagmight,
should be easier now

-Prong sez: don't
go over the water,
it gets cold

-Added scripts to manually disable
shaders for users that get
black screens (if you're reading
this, it doesn't apply to you)

-Slightly increased some
of the new enemies' HP

-Minor shader optimisation

-Fixed some bugs
]])

REVEL.AddChangelog("Neap.Update (v3.0.0)", "Nov 08 2020", [[**NEAPOLITAN UPDATE

-Added 3 new bosses
to Glacier: Prong, Wendy
and Williwaw - replacing
Monsnow, Flurry Jr.,
Duke of Flakes

-Reworked other Glacier bosses,
Freezer Burn and Stalagmight
have entirely new fights

-15.5 new cool and good enemies
added to Glacier, with
approximately 500 new rooms
to go with them

-Added 5 new room features to
Glacier: Big Blowies, Frost
Shooters, Igloos, Lightable 
Fires, and Hockey Pucks

-New glacier mechanics:
Tough Chill, Total Freeze.
These are used by new and
old enemies

-Added Brimstone Traps to Tomb

-5 new items: Super Meat Blade,
Dramamine, Not a Bullet, 
Prescription, Geode

-Boss damage scaling is
way lighter and much
fairer, especially to
harder characters and
weaker item combos

-Removed boss damage scaling
from main path bosses
(Punker and Raging Long Legs)

-Complete minimapAPI integration

-Cooler Glacier snow, with shader

-Rare chance for northern climate

-Fragile ice now becomes an
actual pit, and reforms
7 seconds later

-Tweaks to many glacier
rooms and entities

-Lots and lots of polish
and minor improvements

**work on chapter 3
**is already underway
(and has been for
many months already)]])
    
REVEL.AddChangelog("Sin Update (v2.0.6)", "Jun 11 2020", [[-moved Discord news and
support to modding-general
in the BoI Discord server

-Partial minimapAPI integration

-rev menu overhaul
(omens?)

-big horn crash fix

-Fixed cursed grail not existing

-Various other item fixes]])

REVEL.AddChangelog("Sin Update (v2.0.5)", "Oct 30 2019", [[-Added some Glacier rooms

-Lil Belial + Death's List will
no longer remove Death's List

-Fixed a few bugs with Sandy

-Fixed War's boss intro portrait
being too low in Tomb

-Tweak Lover's Libido
interactions with Void,
Polaroid, etc.

-Tweaks to Vrigil and Lil
Frost Rider movement

-Pride's Posturing doesn't
trigger holy mantle

-Remote Detonator + Wrath's
Rage synergy

-Wandering Soul fixes

-Fix Unlocked Items being
removed from pools

-Fix Gag Reflex staying if you
take 2 pills in a room

-Fix overwriting global select
function]])

REVEL.AddChangelog("Sin Update (v2.0.4)", "Aug 22 2019", [[-Began work on the Neapolitan update!
Join us on Discord for details:
discord.gg/isaac

-Made a Twitter account!
revelationsmod

-Revamp ice physics

-Add a new intro to Narcissus 2

-Added a yellow active item outline
to some Revelations items which
have alternate use modes

-Made boss hall easier for other
mods to modify

-Made several small tweaks to
Narcissus 2's balance

-Raging Long Legs' champion form
has been adjusted

-Snow Flake enemies now have
an appear animation and start
off moving slowly

-Adjusted and added a few rooms

-Improved Mirror Shard's projectile
reflection

-Added missing animations to
Ice Tray tears

-Fixed issues with some Sarah
costumes

-Aragnid is feeling blue]])

REVEL.AddChangelog("Sin Update (v2.0.3)", [[-Fixed changelog not showing up
correctly on first game start

-Willo's graphics was updated

-Willo will now shoot a tear at
enemies when Isaac gets hurt

-Nerfed Perseverance and fixed a
problem with how it deals bonus damage

-Mint Gum will no longer freeze bosses

-Fixed Iced Hive projectiles
being invisible

-Fixed Envy's Enmity splitting from
being inside a tractor beam

-Punker and Raging Long Legs will now
only appear in standard shape boss rooms]])

REVEL.AddChangelog("Sin Update (v2.0.2)", [[-Fixed Maxwell and Ice Worm
bounces not showing costumes

-Added character select to
the boss hall challenge

-Fixed color of Window Cleaner tears

-Fixed issues with Mint Gum
vs Mask+Heart enemies

-Elites now have hp scaling

-Fixed a few issues with Dungo

-Fixed Hyper Dice + Butter!
granting infinite rerolls

-Fixed a Forgotten costume
alt not appearing

-In chill rooms, the Guillotine
familiar will now freeze instead of
the space above the player's body

-Non-champion stalag no longer
slides around with Black Hole

-Fixed shrine plaques momentarily
appearing if all ice worms in
the room are burrowed

-Fixed Ice Tray causing Haemolacria's
tear splitting to not work,
and other synergies

-Added Bloody and Haemolacria sprites
for Ice Tray tears

-Fixed spring traps when
re-entering Maxwell's room

-Made a hard boss harder]])

REVEL.AddChangelog("Sin Update (v2.0.1)", [[-Fixed Maxwell's Horn unlock

-Improved Maxwell and Catastrophe's
sounds

-Increased Narcissus 2's base health
and healing from pillars

-Nerf Narcissus 2's healing from
charm of the vampire and when
healing over his phase threshold

-Fix 8 Inch Nails not counting toward
a Cabbage Patch veggie

-Nerfed Burning Bush, should be
less prone to getting ridiculously
overpowered with other items

-Elites now check doors before
attempting to set a room

-Hub now works properly in XL
base floors

-Made a secret 8% more obvious

-Reduced the amount of spiders
spawned by Raging Long Legs

-Pride's Posturing can now only
be used on the first visit
of an unclear room

-Menu now closes itself on
new game, fixing being
able to take the boss
hall out of its challenge

-Fixed various rooms in
tomb and glacier]])

REVEL.AddChangelog("Sin Update (v2.0.0)", [[**Features

-Added champions for the Ch 2 bosses

-Added elite minibosses to
Revelations floors, appearing
occasionally in larger rooms
throughout the floor

-Sin minibosses now have
unique boss patterns in
Revelations floors

-Added new sin items rewarded
for beating Revelations sins

-Added the Hub room, replacing
transitions into Revelations
floors with a trapdoor that
allows you to choose any path,
also replacing Dante's "start in
Glacier" option

-Added a Rev Boss Practice
challenge, allowing you to
practice against bosses you
have encountered to learn their
patterns

-Shrines have been reworked,
now granting floor-wide rather
than permanent buffs. Two of
the original buffs have been
made into new items

-More rooms have been added
to Revelations floors, including
unique special rooms and
unique challenge waves

-Added several Tomb enemies
that did not make the cut for
the release build, and some
entirely new

-Added several new Ice Hazard
variants, containing Clotties,
Brother Blizzards, and Troll Bombs

-Added more secrets?

**Tweaks

-Sarah sin spawning has been
rebalanced, and her sins can now
be used to damage enemies

-Implemented Narcissus 2's iconic
laser attacks that have always
been a huge part of his personality

-Heavily tweaked Maxwell and
Sarcophaguts behind the scenes
for smoother gameplay

-Updated the palettes of most
monsters in Glacier to add
more variety

-Added unique sounds to many
existing bosses and monsters

-Added a healthbar to Prank

-Reworked Rolling Snowballs

-I. Blobs are much rarer in glacier

-Added particle graphics to
various situations, tweak
the "Particles" option in
the rev menu to reduce or
disable them

-Improved light effects,
can be disabled in Rev options

-Added more Revelations
floor monster reskins

-Sarah now has unique costume sprites
which retain her eye color

**Items

-Made burning bush more
consistent and less prone to
getting worse with more items

-Burning Bush now synergizes with
more items, old synergies improved

-Cabbage Patch now synergizes
with various items

-Addict now synergizes
with Starter Deck

-Lil Belial now synergizes
with Death's List

-Lil Michael now synergizes with
other weapon types

-Birth Control now synergizes with
more familiars and trinkets

-Death's Mask now synergizes
with Book of the Dead

-Ice Tray now synergizes with Ludo

-Cursed Grail will now sit by doors
which lead to the sacrifice room

**Fixes

-Raging Long Legs fires can now be
extinguished with more weapon types

-Fixed and tweaked shaders

-Adjusted ids, variants, and
subtypes of all entities to fit
within their internal ranges

-Fixed interactions with
Cardboard Robot + 9 Volt/AAA Battery

**A cold breeze
**is blowing in]])

REVEL.AddChangelog("Chapter 2 v1.1.2", [[-Fixed Hyper Dice crashing
the game, and re-enabled it

-Rebalanced Hyper Dice

-Revelations items now have a higher
chance to appear if they have not
been picked up or won with before

-Revelations items now work better
with Butter!, ? Card, Blank Card,
Void, and similar items

-Maxwell's room now respawns
spring traps on re-entry
and has tiles rather
than pits as a failsafe

-Pact of Gratuity no longer spawns
pickups in extra rooms

-Mirror door's mirror and frame
sprites now line up correctly

-Fix Hungry Grub colliding
with grid entities even
when following the player

-The Revending Machine will no longer
appear to contain Burning Bush
during room transitions

-Chill head sprite is now offset
when the player is flying

-Jeffrey can no longer be killed
instantly by void tears, euthanasia,
e. coli, or similar items

-Added Russian extra
item description support
]])

REVEL.AddChangelog("Chapter 2 v1.1.1", [[  (+ hotpatch)

-"Shader fix" option now
replaced by "Better shaders":
the effect of turning shader
fix on is now obtained by
leaving Better shaders off

-Updated Glacier rooms

-Updated Greed Mode rooms

-The Phylactery familiar and active
item icon will now flash to indicate
when dante/charon can give an item
to the other character

-The second boss reward collectible
is no longer automatically added
to the other character

-Maxwell should no longer
appear in wide and tall rooms

-Added more rooms for Sandy

-Sandy can now appear in
wide and tall rooms

-Antlion Eggs now have a
non-angered idle animation

-Incubus now works with Fecal Freak,
Ice Tray, and Broken Oar

-Merged Charon will now fire
Fecal Freak backwards

-The dime that appears when Dante
and Charon merge will now play
its appear animation

-Fecal Freak no longer
works when frozen

-The Forgotten now has unique
frozen head costume sprites

-The frozen head costume will now
scale with the player's size

-Dante's ink tears should no
longer apply a glitchy appearance
to abnormal tears (like fecal freak)

-Fixed the My Stuff pause paper
appearing when a run is started
or continued in the same session
after exiting the game using
the pause menu

-Fixed Flurry Jr. removing all
pickups that spawn in his room

-Fixed Shrine Room doors remaining
closed if Prank leaves the room
without stealing a pickup

-Shops which contain Greed in Glacier
and Tomb will now spawn their
revending machine with some effects

-Fixed Lottery Ticket using the
wrong front icon with True Co-op
]])

REVEL.AddChangelog("Chapter 2 v1.1.0", [[  (+ hotfix x2)

-Chill has been overhauled

-Replaced Stalagmight's spikes
with ice

-Added an option to fix
a shader bug that happened
on some AMD cards

-Increased the tell for
Stalagmight's triple shot

-Added a creep spewing
animation to Stalagmight's
stalactites

-Darkened shadows of
Stalactites, Small Stalactites,
and Stalactrites

-Charon's buffing over time
effect has been made
more extreme

-Dante now shoots ink tears

-Fixed Dante not being able
to start the floor
with soul hearts

-The Mirror room can now
spawn on Glacier 1 and
Tomb 1 as well

-Dante's starting room now has
additional tutorial drawings

-Chill rooms now have a
unique shader

-Buffed Tomb enemy HP

-Nerfed Bandage Baby

-Jeffrey cannot be knocked
back while trying to
get to sandy

-Prevented certain things
from targeting friendly
enemies

-Updated Glacier and Tomb rooms

-Updated Glacier and Tomb
boss rooms

-Renamed Next of Kin to
Jeffrey throughout the mod

-Increased Jeffrey's health
outside of the Sandy fight

-Adjusted chance for
special boss rewards

-Added a sound when Dante
hurts enemies by knocking
them into a wall

-Fixed overlays setting
changing shaders instead

-Charon will automatically
face the direction
you enter a room.
This can be disabled
in the settings menu

-Added a new sound
effect when Charon
loses a buff by
switching directions

-Changed Charon in the
To-Do list to Dante

-Fixed burning bush costume
covering hair

-Fixed Freezer Burn's fires
having a blue poof

-Added a synergy with
Charon and Broken Oar

-Disabled old phylactery

-Fixed a crash with
sand worms in L rooms

-Charon and Broken Oar's shots
are now evenly spread

-Reskinned Wall Hugger
and Slide in Tomb

-Fixed Penance angel
rooms resetting every entry

-Sin orbs burst from
Penance angel statue
when it is destroyed

-Changed Charon and Dante's
starting health to
one red heart and
one and a half
black hearts each

-Added a health up
to Charon and Dante's
first treasure room

-Polished to-do list

-Added menu palettes

-Updated credits

-Reduced Raging Long Legs' HP

-Prank no longer prioritizes
picking up pickups over
leaving the room if he
takes enough damage
or spends too much time
in a room

-Prank moves toward
pickups faster

-Moxie's yarn can
now be found in
the Revending Machine

-Made Charon's shot speed
buff a visible stat change
when not merged

-Latest changelog now
opens automatically
if not yet seen

-Cabbage patches now
only spawn on the first
visit of a room

-Mint gum now scales
correctly with weapon types

-Chill warmth checks
are now consistent

-Fixed brazier aura
occasionally not appearing

-Fragility no longer freezes
entities the player does
not collide with

-Increased range of Dante's
bash when facing the
same direction as
charon while merged

-Increased strength of Dante's
bash while merged slightly

-Added hit sound and
sprite scale increase
to Perseverance effect

-Nerfed Glacier shrine rooms

-Added Glacier rooms

-Ensured that Phylactery
is discharged after
swapping characters

-Blacklisted items that
change head size for
Dante and Charon

-Dante and Charon changing
into a new character
now removes phylactery
and merges your items

-Fixed Prank not initializing
when you make a mistake

-Fixed Antlion grid collision
after starting their
spew attack

-Added grid collision to
Peashy's nails after
impacting the ground

-Fragility shrine's freeze
effect now matches Mint Gum's

-Fixed Mint Gum's freezing
persisting forever if
the item is lost

-Fixed some instances
of Virgil getting stuck

-Glacier red fire
bullets are no
longer blue

-Cabbages can be
watered with
The Ludovico Technique

-Fixed Ice Tray
and spectral tears

-Maxwell now starts
from the opposite side
from the player

-Spending too much time
in Maxwell's tutorial
sends the player a hint

-Random traps can't spawn
near any possible
door location

-Mirror rooms now count
as uncleared

-Fixed Dante Satan room
being able to show up
more than once in a run

-Shrines now have wall
grid collision

-Fixed Narcissus 2 taking damage
while in the mirror

-Fixed most issues with
Dynamo's costume

-Updated spike trap skins
for Glacier and Tomb

-Added Small Grill-O-Wisps that
appear when a fire is
destroyed in a chill room

-Fixed Jeffrey not being able to
fly over grid entities
]])

REVEL.AddChangelog("Chapter 2 v1.0.7", [[-Fix changelogs with exactly the same
amount of lines as the last one
crashing the game when opened
]])

REVEL.AddChangelog("Chapter 2 v1.0.6", [[-Maxwell's boss fight music
only starts when the fight does

-Dante and Charon now remember where
exactly in rooms you left them

-Bandage baby now slows rather
than freezing

-Updated Tomb's rooms

-Added a failsafe for
Pyramid Head invincibility

-Remove boss hp debugging left in
]])

REVEL.AddChangelog("Chapter 2 v1.0.5", [[-Reduced Narcissus 2's HP slightly

-Added to the credits

-Updated Slambip's sprites

-Disabled boss scaling in
normal rooms (Punker
won't be crazy strong
in the chest)

-XL Glacier now properly
has a sale on the
Revending Machine

-Sandy and Jeffrey's HP
buffed considerably

-Prank will leave much faster
if you deal too much damage
in one room

-Fixed Canopic Jars being
unable to spawn items

-Updated some of Tomb's rooms

-Revival tears can no longer
spawn in cleared rooms

-Fixed Ice Tray tears being unable
to destroy poop and TNT

-Added some Revelations items
to more pools
]])

REVEL.AddChangelog("Chapter 2 v1.0.4", [[-Fixed save data being
wiped after a cutscene is played

-Added several failsafes to prevent
innards from becoming invincible

-Fixed menu flickering on first run

-Removed stray pixel on Sandy
and Jeffrey's spritesheets
]])

REVEL.AddChangelog("Chapter 2 v1.0.3", [[-Revelations menu now fully
supports controller inputs.

-Effects of chill reduced slightly

-Chill resets instantly on room switch

-Properly disabled delirium
transforming into glacier prank
]])

REVEL.AddChangelog("Chapter 2 v1.0.2", [[-Fixed Pact of Radiance chilling
bosses it shouldn't

-Lowered opacity of Pact of Radiance's
 friendly wisp's aura

-Fix Narcissus 2 not
having boss hp scaling

-Buffed boss hp scaling at lower levels
(high damage scaling
like knife is the same)

-Hungry Grub no longer
eats friendly enemies

-Brother Bloody no longer immune
to various damage sources

-Some Tomb rooms have been updated

-Fixed angel room music
playing too loudly for Sarah

-Reduced cloud opacity

-Added settings for starting in basement
as Dante and disabling clouds or
all overlays

-Added a black heart to Dante, split
between the two characters

-Added a max radius to Geicers, they
now cannot shoot further than 300 pixels

-Mirror Fragment whitelisted
from Birth Control

-Slightly reduced closeness
of Glacier Prank's chase

-Fixed Dante starting in Depths
in Greed Mode
]])

REVEL.AddChangelog("Chapter 2 v1.0.1", [[-Updated Stalagmight's rooms

-Temporarily removed
hyper dice due to instability

-Fixed antlion eggs respawning

-Dante now properly removes
charon's oar costume on switch

-Added shader on/off setting

-Fixed Sarah's costumes and
True Co-op fetus

-Added means of closing menu with
controller via bomb button.
Full controller support is
being worked on!

-Canopic jars now spawn innards
and correctly spawn no items
when their item is not unlocked

-Removed broken Revelations entries
from bestiary. We will consider
making our own later!
]])

REVEL.AddChangelog("Chapter 2 v1.0.0", [[-New rooms have been added to Glacier
and several of the base game's floors

-Many Glacier rooms have been rebalanced

-Freezerburn's Grill-O-Wisp is recolored
red to signal that it's special

-Grill-O-Wisps and Chill-O-Wisp
no longer have any collision

-Shrines, a new mechanic within Tomb,
have been added to glacier

-Snowflakes, Ice Hazards and Ice Hazard
enemies now have different sprites

-Splashers now have a glacier reskin

-Glacier's Entrance has been re-sprited

-Mirror sprites have been adjusted

-Screenshake from fighting the boss in
the mirror has been lessened a bit

-Glacier now has a special
visual shader

-A few items and trinkets
have been resprited

-Ice Worms have been reworked, and
should now be less confusing
and more fun to fight

-All of the Glacier bosses can now
show up on any of the Glacier floors

-Glacier can now get Curse of the
Labyrinth and Curse of Darkness

-Special poops now properly display as
different poops in Glacier

-Sarah has been completely reworked!
Additionally, Broken Wings
is no longer an unlock,
instead replaced by a new item,
Pilgrim's Ward!

-The "Dante Satan" room's free
Devil Deal item is no longer free

-Added special vending machines
to the shop on Tomb and Glacier]])
