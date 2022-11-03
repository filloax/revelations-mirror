return {
    GROUND = 0, --makes the line check collide with anything that impedes ground movement
    GROUND_CHEAP = 1, --is a cheaper version of 0, but is not as reliable (For example, can return true if line of sight can be gained between diagonally adjacent rocks)
    EXPLOSION = 2, --is used for explosions, it only collides with walls and indestructible blocks
    PROJECTILE = 3, --is a line check that only collides with obstacles that can block projectiles
}