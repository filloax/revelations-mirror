-- Handier requiring at the start of the file than doing
-- REVEL.RevCallbacks.SOMELONGCALLBACKNAME each time

return {
    POST_LOAD = "POST_REVELATIONS_LOAD",

    POST_SAVEDATA_LOAD = "REV_POST_SAVEDATA_LOAD", -- ()
    EARLY_POST_NEW_ROOM = "REV_EARLY_POST_NEW_ROOM", -- ()
    POST_ROOM_CLEAR = "REV_POST_ROOM_CLEAR", -- (room)
    POST_GREED_CLEAR = "REV_POST_GREED_CLEAR", -- (room, wave)
    PRE_TEARIMPACTS_SOUND = "REV_PRE_TEARIMPACTS_SOUND", -- (tear, data, sprite)-> boolean
    PRE_PROJIMPACTS_SOUND = "REV_PRE_PROJIMPACTS_SOUND", -- (tear, data, sprite) -> boolean
    PRE_TEARS_FIRE_SOUND = "REV_PRE_TEARS_FIRE_SOUND", -- (tear, data, sprite) -> boolean # Remember that if you use FireTear, this runs before the function returns
    ON_TEAR = "REV_ON_TEAR", -- (tear, data, sprite, player): TearVariant
    POST_TEAR_POOF_INIT = "REV_POST_TEAR_POOF_INIT", -- (poof, data, spr, parent, grandparent)
    POST_PROJ_POOF_INIT = "REV_POST_PROJ_POOF_INIT", -- (poof, data, spr, parent, grandparent)
    POST_PICKUP_COLLECT = "REV_POST_PICKUP_COLLECT", -- (pickup, player, isPocket): PickupVariant
    TEAR_UPDATE_INIT = "REV_TEAR_UPDATE_INIT", -- (tear)
    FAMILIAR_UPDATE_INIT = "REV_FAMILIAR_UPDATE_INIT", -- (familiar): Variant
    BOMB_UPDATE_INIT = "REV_BOMB_UPDATE_INIT", -- (bomb): Variant
    PICKUP_UPDATE_INIT = "REV_PICKUP_UPDATE_INIT", -- (pickup): Variant
    LASER_UPDATE_INIT = "REV_LASER_UPDATE_INIT", -- (laser): Variant
    KNIFE_UPDATE_INIT = "REV_KNIFE_UPDATE_INIT", -- (knife): KnifeSubType
    PROJECTILE_UPDATE_INIT = "REV_PROJECTILE_UPDATE_INIT", -- (projectile): Variant
    NPC_UPDATE_INIT = "REV_NPC_UPDATE_INIT", -- (npc): Type
    -- EFFECT_UPDATE_INIT = "REV_EFFECT_UPDATE_INIT", -- (effect): Variant # disabled because it adds an update to all effects
    POST_INGAME_RELOAD = "REV_POST_INGAME_RELOAD", -- (isReload) 
    POST_ITEM_PICKUP = "REV_POST_ITEM_PICKUP", -- (player, playerID, itemID, isD4Effect)
    ITEM_CHECK = "REV_ITEM_CHECK", -- (item id, item table): ItemId -> boolean
    PRE_RENDER_REFLECTIONS = "REV_PRE_RENDER_REFLECTIONS", -- ()
    POST_RENDER_REFLECTIONS = "REV_POST_RENDER_REFLECTIONS", -- ()
    POST_RENDER_MIRROR_OVERLAYS = "REV_POST_RENDER_MIRROR_OVERLAYS", -- ()
    PRE_RENDER_ENTITY_REFLECTION = "REV_PRE_RENDER_ENTITY_REFLECTION", -- (entity, sprite, offset): Type -> boolean
    POST_RENDER_ENTITY_REFLECTION = "REV_POST_RENDER_ENTITY_REFLECTION", -- (entity, sprite, offset, didRender): Type
    POST_ENTITY_ZPOS_INIT = "REV_POST_ENTITY_ZPOS_INIT", -- (entity, airMovementData)
    PRE_ENTITY_ZPOS_UPDATE = "REV_PRE_ENTITY_ZPOS_UPDATE", -- (entity, airMovementData): return false to prevent update
    PRE_ENTITY_ZPOS_LAND = "REV_PRE_ENTITY_ZPOS_LAND", -- (entity, airMovementData, landFromGrid): return false to prevent landing, always called even in repeat ground updates
    POST_ENTITY_ZPOS_UPDATE = "REV_POST_ENTITY_ZPOS_UPDATE", -- (entity, airMovementData, landFromGrid)
    POST_ENTITY_ZPOS_LAND = "REV_POST_ENTITY_ZPOS_LAND", -- (entity, airMovementData, landFromGrid, oldZVelocity)
    PRE_ZPOS_COLLISION_CHECK = "REV_PRE_ZPOS_COLLISION_CHECK", -- (entity1, entity2, mode1, mode2, wouldCollide): Return true or false to replace result; true means it runs vanilla collision code (and continues vanilla callback stack), false means collision is prevented
    PRE_ZPOS_UPDATE_GFX = "REV_PRE_ZPOS_UPDATE_GFX", -- (entity, airMovementData, zPos): return false to not run base update gfx code
    POST_ZPOS_UPDATE_GFX = "REV_POST_ZPOS_UPDATE_GFX", -- (entity, airMovementData, zPos)
    -- Hook into ground level logic, to add features that have a different ground level depending on position
    -- (pos, entity?, currentLevel): Return number to replace ground level
    ZPOS_GET_GROUND_LEVEL = "REV_ZPOS_GET_GROUND_LEVEL",
    POST_MACHINE_UPDATE = "REV_POST_MACHINE_UPDATE", -- (machine), data: MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_INIT = "REV_POST_MACHINE_INIT", -- (machine, data): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_RENDER = "REV_POST_MACHINE_RENDER", -- (machine, data, renderOffset): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_EXPLODE = "REV_POST_MACHINE_EXPLODE", -- (machine, data): MachineVariant -> false to cancel [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_RESPAWN = "REV_POST_MACHINE_RESPAWN", -- (machine, newMachine, data): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    -- (boulder, ent, isGrid) -> boolean #ent is set if colliding with entity, gridentity as appropriate
    -- return true if the boulder should be destroyed (if entity set)
    -- or if it should spawn urny from ceiling if unset (colliding with wall)
    POST_BOULDER_IMPACT = "REV_POST_BOULDER_IMPACT",
    PRE_ESTIMATE_DPS = "REV_PRE_ESTIMATE_DPS", -- (player) -> number
    POST_SPAWN_CLEAR_AWARD = "REV_POST_SPAWN_CLEAR_AWARD", --(spawnPos, pickup)
    POST_ROCK_BREAK = "REV_POST_ROCK_BREAK", --(grid)
    POST_ENTITY_TAKE_DMG = "REV_POST_ENTITY_TAKE_DMG", --(entity, damage, flag, source, invuln): Type, Variant
    POST_BASE_PEFFECT_UPDATE = "REV_POST_BASE_PEFFECT_UPDATE", --(player)
    POST_BASE_PLAYER_INIT = "REV_POST_BASE_PLAYER_INIT", --(player)
    PRE_PLAYER_COLLISION_COLLOBJ = "REV_PRE_PLAYER_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision
    PRE_TEAR_COLLISION_COLLOBJ = "REV_PRE_TEAR_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision
    PRE_BOMB_COLLISION_COLLOBJ = "REV_PRE_BOMB_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision
    PRE_PICKUP_COLLISION_COLLOBJ = "REV_PRE_PICKUP_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision
    PRE_PROJECTILE_COLLISION_COLLOBJ = "REV_PRE_PROJECTILE_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision
    PRE_NPC_COLLISION_COLLOBJ = "REV_PRE_NPC_COLLISION_COLLOBJ", -- (ent, data, collObj) return false to ignore collision

    POST_STAGEAPI_NEW_ROOM_WRAPPER = "POST_STAGEAPI_NEW_ROOM_WRAPPER", --temporary
}