return {
    SINGLE_PROJ = 0, -- single projectile
    TWO_PROJ =1, -- two projectiles (uses params.Spread)
    THREE_PROJ = 2, -- three projectiles (uses params.Spread)
    THREE_PROJ_ALT = 3, -- three projectiles (uses params.Spread, more spread out?)
    FOUR_PROJ = 4, -- four projectiles (uses params.Spread)
    FIVE_PROJ = 5, -- five projectiles (uses params.Spread)
    PLUS = 6, -- four projectiles in a + pattern (uses velocity.x as speed)
    CROSS = 7, -- four projectiles in a x pattern (uses velocity.x as speed)
    STAR = 8, -- eight projectiles in a star pattern (uses velocity.x as speed)
    CIRCLE = 9, -- N projectiles in a circle (velocity.x = speed, velocity.y = N, params.FireDirectionLimit and params.DotProductLimit to fire in an arc only)
}