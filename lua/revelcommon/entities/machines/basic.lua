local RevCallbacks = require "lua.revelcommon.enums.RevCallbacks"
REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

    -- Callbacks:

    -- REV_POST_MACHINE_UPDATE -- function(machine, data), can specify variant
    -- REV_POST_MACHINE_INIT -- function(machine, data), can specify variant
    -- REV_POST_MACHINE_RENDER -- function(machine, data, renderOffset), can specify variant

    -- REV_POST_MACHINE_EXPLODE -- function(machine, data), can specify variant
    --     return false to prevent the machine exploding in a vanilla way,
    --     nil/true to allow explosion

    -- REV_POST_MACHINE_RESPAWN -- function(machine, newMachine, data), can specify variant
    --     called when a machine is respawned to work around vanilla explosion
    --     behavior

    local MachineDefinitions = {
    }

    local ManagerOffset = REVEL.VEC_DOWN * 5

    -- Used for pickup spawn prevention
    function REVEL.RegisterMachine(entDef)
        MachineDefinitions[#MachineDefinitions + 1] = entDef
    end
    
    local function getDefEntities(entDef) return entDef:getInRoom() end
    
    local DisablePickupPrevention = false

    function REVEL.SpawnSlotRewardPickup(variant, subtype, pos, vel, spawner)
        DisablePickupPrevention = true
        local e = Isaac.Spawn(EntityType.ENTITY_PICKUP, variant, subtype, pos, vel, spawner)
        DisablePickupPrevention = false
        return e
    end

    -- Prevent machine pickup spawn
    local function machines_PreEntitySpawn(_, t, v, s, pos, vel, spawner, seed)
        if not DisablePickupPrevention and t == EntityType.ENTITY_PICKUP and v ~= PickupVariant.PICKUP_COLLECTIBLE then
            local machinesInRoom = REVEL.ConcatTables(table.unpack(REVEL.map(MachineDefinitions, getDefEntities)))
    
            if REVEL.some(machinesInRoom, function(machine)
                return pos:DistanceSquared(machine.Position) < 1
            end) then
                return {
                    StageAPI.E.DeleteMePickup.T,
                    StageAPI.E.DeleteMePickup.V,
                    0,
                    seed
                }
            end
        end
    end

    local isRespawn = false

    -- For init callbacks
    function REVEL.IsMachineRespawn()
        return isRespawn
    end

    local function InitMachine(machine)
        local data = machine:GetData()

        data.Init = true

        local manager = REVEL.ENT.SLOT_MANAGER:spawn(machine.Position + ManagerOffset, Vector.Zero, machine)
        manager:GetData().ManagedMachine = EntityPtr(machine)
        data.Manager = EntityPtr(manager)

        StageAPI.CallCallbacksWithParams(RevCallbacks.POST_MACHINE_INIT, false, machine.Variant, 
            machine, manager:GetData())
    end

    function REVEL.GetMachineData(machine)
        local manager = machine:GetData().Manager and machine:GetData().Manager.Ref
        if not manager then -- not init yet
            InitMachine(machine)
            manager = machine:GetData().Manager.Ref
        end

        return manager:GetData()
    end

    function REVEL.TryMachineInit(machine)
        if not machine:GetData().Init then
            InitMachine(machine)
        end
    end

    local function UpdateMachine(machine, data)
        StageAPI.CallCallbacksWithParams(RevCallbacks.POST_MACHINE_UPDATE, false, machine.Variant, 
            machine, data)
    end

    local function RenderMachine(machine, data, renderOffset)
        StageAPI.CallCallbacksWithParams(RevCallbacks.POST_MACHINE_RENDER, false, machine.Variant, 
            machine, data, renderOffset)
    end

    local function MachineExplosionCheck(machine)
        local data = machine:GetData().Manager.Ref:GetData()
        local explosions = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, -1, false, false)
        for _, e in ipairs(explosions) do
            if e.Position:DistanceSquared(machine.Position) < (40 * 2)^2 then
                local callbacks = StageAPI.GetCallbacks(RevCallbacks.POST_MACHINE_EXPLODE)
                local keepAlive = false
    
                for _, callback in ipairs(callbacks) do
                    if machine.Variant == callback.Params[1] or not callback.Params[1] then
                        local success, ret = StageAPI.TryCallback(callback, machine, data)
                        if success then
                            keepAlive = keepAlive or (ret == false)
                        end
                    end
                end

                if keepAlive then
                    isRespawn = true
                    local newMachine = Isaac.Spawn(machine.Type, machine.Variant, machine.SubType, machine.Position, Vector.Zero, nil)
                    isRespawn = false

                    newMachine:GetData().RespawnedMachine = true
                    newMachine:GetData().Manager = machine:GetData().Manager
                    newMachine:GetData().Init = true -- do not call init again, use respawn if needed

                    local manager = machine:GetData().Manager.Ref
                    manager:GetData().ManagedMachine = EntityPtr(newMachine)
                    
                    StageAPI.CallCallbacksWithParams(RevCallbacks.POST_MACHINE_RESPAWN, false, machine.Variant, 
                        machine, newMachine, data)

                    newMachine:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
                    machine:Remove()

                    REVEL.DebugStringMinor("Prevented machine explosion at", REVEL.room:GetGridIndex(newMachine.Position))
                else
                    machine:GetData().Died = true
                    machine:GetData().Manager.Ref:Remove()
                end

                break
            end
        end
    end

    local function machines_PostEffectUpdate(_, effect)
        local data = effect:GetData()
        local machine = data.ManagedMachine and data.ManagedMachine.Ref
        if machine and not machine:IsDead() then
            effect.Position = machine.Position + ManagerOffset
            effect.Velocity = machine.Velocity
            effect.Visible = machine.Visible

            UpdateMachine(machine, data)
        else
            effect:Remove()
        end
    end

    local function machines_PostEffectRender(_, effect, renderOffset)
        local data = effect:GetData()
        local machine = data.ManagedMachine and data.ManagedMachine.Ref

        if machine then
            RenderMachine(machine, data, renderOffset)
        end
    end

    local function machines_PostUpdate()
        local machines = Isaac.FindByType(6)

        for _, machine in ipairs(machines) do
            if REVEL.IsEntIn(MachineDefinitions, machine) then
                if not machine:GetData().Init then
                    InitMachine(machine)
                end

                if not machine:GetData().Died then
                    MachineExplosionCheck(machine)
                end
            end
        end
    end

    local function machines_PostNewRoom()
        local machines = Isaac.FindByType(6)

        for _, machine in ipairs(machines) do
            if not machine:GetData().Init
            and REVEL.IsEntIn(MachineDefinitions, machine) then
                InitMachine(machine)
            end
        end
    end

    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, machines_PostEffectUpdate, REVEL.ENT.SLOT_MANAGER.variant)
    revel:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, machines_PostEffectRender, REVEL.ENT.SLOT_MANAGER.variant)

    revel:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, machines_PreEntitySpawn)
    revel:AddCallback(ModCallbacks.MC_POST_UPDATE, machines_PostUpdate)
    revel:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, machines_PostNewRoom)
end