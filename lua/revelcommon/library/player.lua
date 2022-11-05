local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

---@param player EntityPlayer
---@return integer
function REVEL.GetPlayerID(player)
    if not player then
        error("GetPlayerID | player nil", 2)
    end

    local data = player:GetData()

    -- see basiccore.lua
    if data.playerID then
        return data.playerID
    end
    -- force players IDs to be set, in case they weren't 
    -- initialized yet (eg. other mods that run evaluate_cache)
    -- before rev, or add items with cache flags
    local _ = REVEL.players

    REVEL.DebugStringMinor("Revelations | player ID accessed before initialization, initializing early (other mod?)")

    return data.playerID
end

function REVEL.HasPiercing(player)
    player = player:ToPlayer()
    if player then
        local flags = player.TearFlags
        if HasBit(flags, TearFlags.TEAR_BELIAL) or HasBit(flags, TearFlags.TEAR_EXPLOSIVE) or HasBit(flags, TearFlags.TEAR_PIERCING) then
            return true
        end

        if player:HasWeaponType(WeaponType.WEAPON_BOMBS) or player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) or player:HasWeaponType(WeaponType.WEAPON_KNIFE) or player:HasWeaponType(WeaponType.WEAPON_LASER) or player:HasWeaponType(WeaponType.WEAPON_ROCKETS) or player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            return true
        end
    end
end

function REVEL.GetBlackHearts(player)
    local soulHearts, maxRed = player:GetSoulHearts(), player:GetMaxHearts()
    local blackHearts = 0
    for i = 1, soulHearts + maxRed do
        if player:IsBlackHeart(i) or player:IsBlackHeart(i - 1) then
            blackHearts = blackHearts + 1
        end
    end

    return blackHearts
end

function REVEL.GetNonBlackSoulHearts(player)
    local soulHearts = player:GetSoulHearts()
    return soulHearts - REVEL.GetBlackHearts(player)
end

function REVEL.GetRandomPlayer()
    return REVEL.players[math.random(#REVEL.players)]
end

local ZeroChargeKnifeVel = 12
local FullChargeKnifeVel = 28.5

function REVEL.GetApproximateKnifeCharge(knife)
    if knife:IsFlying() then
        local vel = knife:GetKnifeVelocity()
        return REVEL.Saturate(REVEL.InvLerp(vel, ZeroChargeKnifeVel, FullChargeKnifeVel))
    end
    return 0
end

function REVEL.GetPlayerFromDmgSrc(src)
    local srcEnt, player = REVEL.GetEntFromRef(src), nil
    if srcEnt and srcEnt.Type == 1 then
        player = srcEnt:ToPlayer()
    elseif srcEnt and srcEnt.SpawnerType == 1 then
        if srcEnt.SpawnerEntity then
            player = srcEnt.SpawnerEntity:ToPlayer()
        else
            player = srcEnt:GetData().__player
        end
    end
    return player, srcEnt
end

function REVEL.GetMultiShotNum(player, no2020)
    local out = 1
  
    out = out + 2 * player:GetCollectibleNum(CollectibleType.COLLECTIBLE_INNER_EYE)
    out = out + 3 * player:GetCollectibleNum(CollectibleType.COLLECTIBLE_MUTANT_SPIDER)
    out = out + player:GetCollectibleNum(CollectibleType.COLLECTIBLE_THE_WIZ)
  
    if player:HasPlayerForm(PlayerForm.PLAYERFORM_BABY) then
        out = out + 2
    end
  
    if not no2020 then
        if out == 1 then
            out = out + (player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) and 1 or 0) + 2 * math.max(0, (player:GetCollectibleNum(CollectibleType.COLLECTIBLE_20_20) - 1))
        else
            out = out + 2 * player:GetCollectibleNum(CollectibleType.COLLECTIBLE_20_20)
        end
    end
  
    return out
end

--PLAYER DAMAGED THIS ROOM
function REVEL.WasPlayerDamagedThisRoom(player)
    return not not player:GetData().damagedThisRoom
end

local function damagedThisRoomPlayerTakeDmg(e, dmg, flag, src, invuln)
    e:GetData().damagedThisRoom = true
end

local function damagedThisRoomPostNewRoom()
    for _, player in ipairs(REVEL.players) do
        player:GetData().damagedThisRoom = nil
    end
end

-- Camera mode

local function disableDrop_InputAction(_, entity, hook, action)
    if action == ButtonAction.ACTION_DROP then
        if hook == InputHook.IS_ACTION_PRESSED or hook == InputHook.IS_ACTION_TRIGGERED then
            return false
        elseif hook == InputHook.GET_ACTION_VALUE then
            return 0
        end
    end
end

local RegisteredDisableDrop = false

---@param player? EntityPlayer use fake player if nil
function REVEL.PlayerCameraMode(player)
    local fakePlayer = false

    if not player then
        player = REVEL.NewPlayer(PlayerType.PLAYER_ISAAC, 0, REVEL.player)
        fakePlayer = true
    end

    local data = player:GetData()

    if not data.CameraMode then
        data.CameraMode = true

        ---@class Rev.CameraModeData
        data.Camera = {
            StartingPos = player.Position,
            FakePlayer = fakePlayer,
        }

        data.Camera.WasVisible = player.Visible
        player.Visible = false

        data.Camera.HadNoTarget = player:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
        player:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
        
        data.Camera.OldCollisionClass = player.EntityCollisionClass
        player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if not data.Camera.FakePlayer then
            data.Camera.StandinEffect = REVEL.ENT.PLAYER_CAMERA_STANDIN:spawn(player.Position, Vector.Zero, player)
            data.Camera.StandinEffect:GetData().Player = player
        end

        data.Camera.WasForgottenSoul = player:GetPlayerType() == PlayerType.PLAYER_THESOUL 
            and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
        if data.Camera.WasForgottenSoul then
            if not data.Camera.FakePlayer then
                REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, true)
            end
            local playerID = REVEL.GetPlayerID(player)
            local mainPlayer = REVEL.players[playerID]
            if mainPlayer:GetData().Bone then
                mainPlayer:GetData().Bone.Visible = false
            end
        end

        REVEL.LockPlayerControls(player, "Camera")
        
        if player:GetSubPlayer() then
            REVEL.LockPlayerControls(player:GetSubPlayer(), "Camera")
        end
        if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
            -- main player
            REVEL.LockPlayerControls(REVEL.players[REVEL.GetPlayerID(player)], "Camera")
        end

        if player:GetPlayerType() == PlayerType.PLAYER_THESOUL
        or player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
            REVEL.DelayFunction(1, function()
                if not RegisteredDisableDrop then
                    RegisteredDisableDrop = true
                    revel:AddCallback(ModCallbacks.MC_INPUT_ACTION, disableDrop_InputAction)
                end
            end)
        end

        if data.Bone then
            data.Bone.Visible = false
        end
        
        return player
    end
end

---@param player EntityPlayer
---@param restorePos? boolean
function REVEL.StopPlayerCameraMode(player, restorePos)
    local data = player:GetData()
    
    if data.CameraMode then
        if data.Camera.WasVisible then
            player.Visible = true
        end

        -- WILL break if more player camera modes are active at the same time, 
        -- but it shouldn't be a common usecase anyways
        -- At worst simply drop button will be active when it shouldn't
        if RegisteredDisableDrop then
            revel:RemoveCallback(ModCallbacks.MC_INPUT_ACTION, disableDrop_InputAction)
            RegisteredDisableDrop = false
        end


        REVEL.UnlockPlayerControls(player, "Camera")
        if player:GetSubPlayer() then
            REVEL.UnlockPlayerControls(player:GetSubPlayer(), "Camera")
        end    
        -- Shouldn't ever be the soul, but just in case
        if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
            -- main player
            REVEL.UnlockPlayerControls(REVEL.players[REVEL.GetPlayerID(player)], "Camera")
        end
        if not data.Camera.HadNoTarget then
            player:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
        end
        if data.Camera.StandinEffect 
        and data.Camera.StandinEffect:Exists() 
        then
            data.Camera.StandinEffect:Remove()
        end
        player.EntityCollisionClass = data.Camera.OldCollisionClass

        if restorePos then
            player.Position = data.Camera.StartingPos
        end

        if data.Bone then
            data.Bone.Visible = true
        end

        if data.Camera.WasForgottenSoul and not data.Camera.FakePlayer then
            REVEL.ForceInput(player, ButtonAction.ACTION_DROP, InputHook.IS_ACTION_TRIGGERED, true)
        end

        if data.Camera.FakePlayer then
            REVEL.RemoveExtraPlayer(player)
        end

        data.Camera = nil
        data.CameraMode = false
    end
end

local function cameraModePlayerTakeDmg(_, player)
    if player:GetData().CameraMode then
        return false
    end
end

---@param familiar EntityFamiliar
local function cameraModeFamiliarUpdate(_, familiar)
    local player = familiar.Player

    if player:GetData().CameraMode 
    and player:GetData().Camera.StandinEffect 
    and player:GetData().Camera.StandinEffect:Exists() 
    then
        familiar:FollowPosition(familiar.Position)
    end
end

local function cameraModeStandinPostRender(_, effect, renderOffset)
    local player = effect:GetData().Player

    if player and player:Exists() then
        local pos = Isaac.WorldToRenderPosition(effect.Position)
        + renderOffset -- - REVEL.room:GetRenderScrollOffset()

        player.Visible = true
        player:RenderGlow(pos)
        player:RenderBody(pos)
        player:RenderHead(pos)
        player:RenderTop(pos)
        player.Visible = false
    end
end

---Uses the addplayer hack to create a new player entity that doesn't crash the game
---@param playerType PlayerType
---@param controllerIndex integer
---@param strawmanParent? EntityPlayer
---@return EntityPlayer
function REVEL.NewPlayer(playerType, controllerIndex, strawmanParent)
    Isaac.ExecuteCommand("addplayer " .. playerType .. " " .. controllerIndex)
    
    local player = Isaac.GetPlayer(REVEL.game:GetNumPlayers() - 1)
    player.Parent = strawmanParent
    player:GetData().RevFakePlayer = true
    
    return player
end

local PlayerDying = false
local AddedCallback = false

---@param type EntityType
---@param variant integer
---@param subType integer
---@param position Vector
---@param velocity Vector
---@param spawner Entity?
---@param seed integer
---@return {Type: integer, Variant: integer, SubType: integer, Seed: integer}?
local function removePlayer_Gibs_PreEntitySpawn(_, type, variant, subType, position, velocity, spawner, seed)
    if PlayerDying 
    and type == 1000
    and (
        variant == EffectVariant.BLOOD_EXPLOSION
        or variant == EffectVariant.BLOOD_PARTICLE
    ) then
        return {
            StageAPI.E.DeleteMeEffect.T,
            StageAPI.E.DeleteMeEffect.V,
            0,
            seed
        }
    end
end

---Remove player spawned by [`REVEL.NewPlayer`](player.lua), 
---use when game is not paused (else, make player invisible to
---stall)
---@param player EntityPlayer
function REVEL.RemoveExtraPlayer(player)
    -- :Remove() crashes

    player.ControlsEnabled = false
    player.Visible = false
    
    -- Runs as soon as game is not paused
    REVEL.DelayFunction(0, function()
        PlayerDying = true
        -- dynamic callback adding to avoid adding to the lag with many callbacks
        -- for a very specific occurrence
        if not AddedCallback then
            revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, removePlayer_Gibs_PreEntitySpawn)
            AddedCallback = true
        end
    
        player:Die()
        player:Update()
        player:GetSprite():SetLastFrame()
        player:Update()
        REVEL.sfx:Stop(SoundEffect.SOUND_DEATH)
        REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)

        REVEL.DelayFunction(1, function()
            PlayerDying = false
            if AddedCallback then
                revel:RemoveCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, removePlayer_Gibs_PreEntitySpawn)
                AddedCallback = false
            end
            REVEL.sfx:Stop(SoundEffect.SOUND_DEATH)
            REVEL.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
        end)
    end)
end

---If player can pass through mirror, have free mausoleum door, etc
---@param player EntityPlayer
---@return boolean
function REVEL.PlayerIsLost(player)
    return player:GetPlayerType() == PlayerType.PLAYER_THELOST
        or player:GetPlayerType() == PlayerType.PLAYER_THELOST_B
        or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B
        or player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B
        or player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
end

---Disable player controls and avoid overriding other functionalities that do
-- it, using an id to track different uses of this
-- This also keeps ControlsEnabled true on new room
---@param player EntityPlayer
---@param lockId any
function REVEL.LockPlayerControls(player, lockId)
    local data = player:GetData()
    if not data.__DisablePlayerControls then
        data.__DisablePlayerControls = {
            Set = {},
            LastState = nil,
        }
    end

    if REVEL.isEmpty(data.__DisablePlayerControls.Set) then
        data.__DisablePlayerControls.LastState = player.ControlsEnabled
        player.ControlsEnabled = false
    end


    if not data.__DisablePlayerControls.Set[lockId] then
        data.__DisablePlayerControls.Set[lockId] = true
    end
end

---See `REVEL.LockPlayerControls`
---@param player EntityPlayer
---@param lockId any
function REVEL.UnlockPlayerControls(player, lockId)
    local data = player:GetData()

    REVEL.Assert(data.__DisablePlayerControls, "UnlockPlayerControls | __DisablePlayerControls is nil!", 2)

    if data.__DisablePlayerControls.Set[lockId] then
        data.__DisablePlayerControls.Set[lockId] = nil
        if REVEL.isEmpty(data.__DisablePlayerControls.Set)
        and data.__DisablePlayerControls.LastState ~= nil
        then
            player.ControlsEnabled = data.__DisablePlayerControls.LastState
            data.__DisablePlayerControls.LastState = nil
        end
    end
end

local function lockPlayerControls_PostNewRoom()
    -- ControlsEnabled gets reset to true on first room frame
    REVEL.CallbackOnce(ModCallbacks.MC_POST_UPDATE, function()
        for _, player in ipairs(REVEL.players) do
            local data = player:GetData()
            if  data.__DisablePlayerControls then
                if not REVEL.isEmpty(data.__DisablePlayerControls.Set) then
                    player.ControlsEnabled = false
                end
            end
        end
    end)
end

StageAPI.AddCallback("Revelations", RevCallbacks.POST_ENTITY_TAKE_DMG, 1, damagedThisRoomPlayerTakeDmg, 1)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, damagedThisRoomPostNewRoom)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, lockPlayerControls_PostNewRoom)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, cameraModePlayerTakeDmg, 1)
revel:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, cameraModeFamiliarUpdate)
revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, cameraModeStandinPostRender, REVEL.ENT.PLAYER_CAMERA_STANDIN.variant)
    

end

REVEL.PcallWorkaroundBreakFunction()