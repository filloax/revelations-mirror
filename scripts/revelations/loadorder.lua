--loadorder
return {
  -- Load MinimapAPI (if not already installed as a mod) before everything
  "scripts.revelations.libraries.handling.minimapapi.revMinimapapi",

  -- Basics, should load first.
  "scripts.revelations.common.library.early.basiclibrary",
  "scripts.revelations.common.library.early.roomLoadHelpers",

  -- Includes resetting of other mod callbacks
  "scripts.revelations.common.preinit",
  "scripts.revelations.chapter1.preinit", -- preinit is for requiring and operating on additional files
  "scripts.revelations.chapter2.preinit",

  -- Code necessary for definitions (functions, etc.)
  "scripts.revelations.common.core.early.basiccore",

  "scripts.revelations.definitions.revEntities",
  "scripts.revelations.definitions.revBosses",
  "scripts.revelations.definitions.revGridEntities",
  "scripts.revelations.definitions.revMetaEntities",
  "scripts.revelations.definitions.revCharacters",
  "scripts.revelations.definitions.revCostumes",
  "scripts.revelations.definitions.revItems",
  "scripts.revelations.definitions.revPocketItems",
  "scripts.revelations.definitions.revSfx",
  "scripts.revelations.definitions.revMusic",
  "scripts.revelations.definitions.revUnlockables",
  "scripts.revelations.definitions.revDefaultModData",

  -- First callbacks are added from here

  'scripts.revelations.common.core.saveHandling',
  "scripts.revelations.common.library",

  -- Standard core parts
  'scripts.revelations.common.core.clearcache',
  'scripts.revelations.common.core.updateShared',

  'scripts.revelations.common.core.hubroom',
  'scripts.revelations.common.core.mirrorgen',
  'scripts.revelations.common.core.elites',

  'scripts.revelations.common.core.misc',
  'scripts.revelations.common.core.dynamicItemWeights',
  'scripts.revelations.common.core.vanillaMusic',
  'scripts.revelations.common.core.musicCues',

  'scripts.revelations.common.core.taintedWarning',

  'scripts.revelations.common.core.commands',

  "scripts.revelations.characters.sarah",
  "scripts.revelations.characters.dante",

  -- Anything that should run after the basics
  "scripts.revelations.common.shrines",
  "scripts.revelations.common.entities",
  "scripts.revelations.common.bosses",

  "scripts.revelations.chapter1.glacier",
  "scripts.revelations.chapter1.entities",
  "scripts.revelations.chapter1.bosses",

  "scripts.revelations.chapter2.tomb",
  "scripts.revelations.chapter2.entities",
  "scripts.revelations.chapter2.bosses",
  
  -- Requires stages to be initialized
  "scripts.revelations.libraries.handling.minimapapi.mapapiLate",
  "scripts.revelations.libraries.handling.hubroom2",
  "scripts.revelations.common.core.late.modcompat",

  "scripts.revelations.items.items",

  "scripts.revelations.misc.testCompat",

  -- Must be last so that it renders after everything else.
  "scripts.revelations.libraries.handling.revdss",

  "scripts.revelations.misc.performanceTracker",
  "scripts.revelations.misc.postload",
}
