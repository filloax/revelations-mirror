return {
  -- Load MinimapAPI (if not already installed as a mod) before everything
  "lua.minimapapi",

  -- Basics, should load first.
  "lua.revelcommon.library.early.basiclibrary",
  "lua.revelcommon.library.early.room_load_helpers",
  "lua.revelcommon.library.early.sprite_cache",

  -- Includes resetting of other mod callbacks
  "lua.revelcommon.preinit",
  "lua.revel1.preinit", -- preinit is for requiring and operating on additional files
  "lua.revel2.preinit",

  -- Code necessary for definitions (functions, etc.)
  "lua.revelcommon.basiccore",

  "lua.revelcommon.definitions",
  "lua.revel1.definitions",
  "lua.revel2.definitions",

  -- First callbacks are added from here
  
  -- Callbacks to run before everything else
  "lua.revelcommon.earlycallbacks",

  "lua.revel_savehandling",

  "lua.revelcommon.core",
  "lua.revelcommon.library",

  "lua.revelcommon.defaultmoddata",
  "lua.revel1.defaultmoddata",
  "lua.revel2.defaultmoddata",

  -- Anything that should run after the basics
  "lua.revelcommon.mirrorgen", --so that it runs before elite room picking
  "lua.revelcommon.hubroom",
  "lua.revelcommon.shrines",
  "lua.revelcommon.sarah",
  "lua.revelcommon.dante",
  "lua.revelcommon.tainted_warning",
  "lua.revelcommon.entities",
  "lua.revelcommon.elites",
  "lua.revelcommon.bosses",

  "lua.revel1.glacier",
  "lua.revel1.entities",
  "lua.revel1.bosses",

  "lua.revel2.tomb",
  "lua.revel2.entities",
  "lua.revel2.bosses",

  -- Mod compatibility
  "lua.customgameover",
  "lua.revelcommon.modcompat",
  "lua.revel1.modcompat",
  "lua.revel2.modcompat",
  
  -- Requires stages to be initialized
  "lua.revelcommon.hubroom2",

  "lua.revelitems.items",

  "lua.test_compat",

  -- Must be last so that it renders after everything else.
  "lua.revel_menu",
  "lua.postload",
}
