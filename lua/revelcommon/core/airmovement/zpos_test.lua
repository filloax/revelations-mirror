REVEL.LoadFunctions[#REVEL.LoadFunctions+1] = function()

-- Keybinds to test out z pos

local lastKeyIsMode = false

revel:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if REVEL.game:IsPaused() then return end

    local player = REVEL.player
    local rpos = Isaac.WorldToScreen(player.Position) + Vector(10, -20)

    Isaac.RenderText(REVEL.ZPos.GetPosition(player), rpos.X, rpos.Y, 255, 255, 255, 255)

    if Input.IsButtonTriggered(Keyboard.KEY_J, 0) then
        lastKeyIsMode = false
        REVEL.ZPos.AddVelocity(player, 6.5)
    elseif Input.IsButtonTriggered(Keyboard.KEY_K, 0) then
        lastKeyIsMode = false
        for _, npc in ipairs(REVEL.roomNPCs) do
            REVEL.ZPos.AddVelocity(npc, 8)
        end
    elseif Input.IsButtonTriggered(Keyboard.KEY_I, 0) then
        lastKeyIsMode = false
        REVEL.SpringPlayer(player)
    elseif Input.IsButtonTriggered(Keyboard.KEY_N, 0) then
        lastKeyIsMode = true
    elseif lastKeyIsMode then
        if Input.IsButtonTriggered(Keyboard.KEY_1, 0) then
            REVEL.ZPos.GetData(player).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.DONT_HANDLE
            REVEL.DebugLog("Set player to DONT_HANDLE")
            lastKeyIsMode = false
        elseif Input.IsButtonTriggered(Keyboard.KEY_2, 0) then
            REVEL.ZPos.GetData(player).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.HITBOX
            REVEL.DebugLog("Set player to HITBOX")
            lastKeyIsMode = false
        elseif Input.IsButtonTriggered(Keyboard.KEY_3, 0) then
            REVEL.ZPos.GetData(player).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.SIMPLE_AIRBORNE
            REVEL.DebugLog("Set player to SIMPLE_AIRBORNE")
            lastKeyIsMode = false
        elseif Input.IsButtonTriggered(Keyboard.KEY_8, 0) then
            for _, npc in ipairs(REVEL.roomNPCs) do
                REVEL.ZPos.GetData(npc).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.DONT_HANDLE
            end
            REVEL.DebugLog("Set npcs to DONT_HANDLE")
            lastKeyIsMode = false
        elseif Input.IsButtonTriggered(Keyboard.KEY_9, 0) then
            for _, npc in ipairs(REVEL.roomNPCs) do
                REVEL.ZPos.GetData(npc).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.HITBOX
            end
            REVEL.DebugLog("Set npcs to HITBOX")
            lastKeyIsMode = false
        elseif Input.IsButtonTriggered(Keyboard.KEY_0, 0) then
            for _, npc in ipairs(REVEL.roomNPCs) do
                REVEL.ZPos.GetData(npc).EntityCollisionMode = REVEL.ZPos.EntityCollisionMode.SIMPLE_AIRBORNE
            end
            REVEL.DebugLog("Set npcs to SIMPLE_AIRBORNE")
            lastKeyIsMode = false
        end
    end
end)

end