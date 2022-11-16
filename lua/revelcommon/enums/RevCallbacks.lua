-- Handier requiring at the start of the file than doing
-- REVEL.RevCallbacks.SOMELONGCALLBACKNAME each time

return {
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
    PRE_RENDER_ENTITY_REFLECTION = "REV_PRE_RENDER_ENTITY_REFLECTION", -- (entity, sprite, offset): Type -> boolean
    POST_RENDER_ENTITY_REFLECTION = "REV_POST_RENDER_ENTITY_REFLECTION", -- (entity, sprite, offset, didRender): Type
    PRE_ENTITY_AIR_MOVEMENT_UPDATE = "REV_PRE_ENTITY_AIR_MOVEMENT_UPDATE", -- (entity, airMovementData)
    PRE_ENTITY_AIR_MOVEMENT_LAND = "REV_PRE_ENTITY_AIR_MOVEMENT_LAND", -- (entity, airMovementData, landFromGrid)
    POST_ENTITY_AIR_MOVEMENT_UPDATE = "REV_POST_ENTITY_AIR_MOVEMENT_UPDATE", -- (entity, airMovementData, landFromGrid)
    POST_ENTITY_AIR_MOVEMENT_LAND = "REV_POST_ENTITY_AIR_MOVEMENT_LAND", -- (entity, airMovementData, landFromGrid, oldZVelocity)
    POST_MACHINE_UPDATE = "REV_POST_MACHINE_UPDATE", -- (machine), data: MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_INIT = "REV_POST_MACHINE_INIT", -- (machine, data): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_RENDER = "REV_POST_MACHINE_RENDER", -- (machine, data, renderOffset): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_EXPLODE = "REV_POST_MACHINE_EXPLODE", -- (machine, data): MachineVariant -> boolean [data is persistent across respawns, unlike normal :GetData()]
    POST_MACHINE_RESPAWN = "REV_POST_MACHINE_RESPAWN", -- (machine, newMachine, data): MachineVariant [data is persistent across respawns, unlike normal :GetData()]
    -- (boulder, ent, isGrid) -> boolean #ent is set if colliding with entity, gridentity as appropriate
    -- return true if the boulder should be destroyed (if entity set)
    -- or if it should spawn urny from ceiling if unset (colliding with wall)
    POST_BOULDER_IMPACT = "REV_POST_BOULDER_IMPACT",
    PRE_ESTIMATE_DPS = "REV_PRE_ESTIMATE_DPS", -- (player) -> number
    POST_SPAWN_CLEAR_AWARD = "REV_POST_SPAWN_CLEAR_AWARD", --(spawnPos, pickup)
    POST_ROCK_BREAK = "REV_POST_ROCK_BREAK", --(grid)
    POST_ENTITY_TAKE_DMG = "REV_POST_ENTITY_TAKE_DMG", --(entity, damage, flag, source, invuln): Type, Variant

    POST_STAGEAPI_NEW_ROOM_WRAPPER = "POST_STAGEAPI_NEW_ROOM_WRAPPER", --temporary
}