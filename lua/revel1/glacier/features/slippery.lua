local ShrineTypes = require "lua.revelcommon.enums.ShrineTypes"
local RevRoomType = require "lua.revelcommon.enums.RevRoomType"
return function()

local FullIceRoomTypes = {
    RevRoomType.ICE_BOSS,
    RevRoomType.DANTE_MEGA_SATAN,
}

function REVEL.Glacier.IsIceIndex(index)
    local currentRoom = StageAPI.GetCurrentRoom()
    return currentRoom 
    and (
        REVEL.includes(FullIceRoomTypes, currentRoom:GetType()) 
        or (currentRoom.PersistentData.IcePitFrames and currentRoom.PersistentData.IcePitFrames[tostring(index)])
    ) 
    and not (currentRoom.PersistentData.SnowedTiles and currentRoom.PersistentData.SnowedTiles[tostring(index)])
end

function REVEL.Glacier.CheckIce(ent, currentRoom, ignoreCreep)
    if not ent:IsFlying() and REVEL.ZPos.GetPosition(ent) <= 0 then
        local index = REVEL.room:GetGridIndex(ent.Position)
        if REVEL.Glacier.IsIceIndex(index) then
            return true
        elseif not ignoreCreep then
            for _, creep in ipairs(REVEL.ENT.ICE_CREEP:getInRoom(-1, true, false)) do
                if creep:GetData().icecreep and ent.Position:DistanceSquared(creep.Position) < (ent.Size + creep.Size) ^ 1.9 then
                    return true
                end
            end
        end
    end
    return false
end

function REVEL.Glacier.RunIcePhysics(ent, currentRoom)
    local onIce = REVEL.Glacier.CheckIce(ent, currentRoom)

    if onIce then
        local data = ent:GetData()
        if data.PrevIceVelocity and data.PrevIceVelocity:DistanceSquared(ent.Velocity) < REVEL.GlacierBalance.IceVelocityThreshold ^ 2 and data.PrevIcePosition:DistanceSquared(ent.Position) < REVEL.GlacierBalance.IcePositionThreshold ^ 2 then
            ent.Velocity = REVEL.Lerp(ent.Velocity, ent:GetData().PrevIceVelocity, REVEL.GlacierBalance.IceSlipperiness)
        end

        data.PrevIceVelocity = ent.Velocity
        data.PrevIcePosition = ent.Position
    else
        ent:GetData().PrevIceVelocity = nil
        ent:GetData().PrevIcePosition = nil
    end

    return onIce
end

local function slipperyPostUpdate()
    if REVEL.game:IsGreedMode() then return end

    local currentRoom = StageAPI.GetCurrentRoom()
    if not (currentRoom and currentRoom.PersistentData.IcePitFrames and REVEL.room:GetFrameCount() > 5) then return end

    -- logic for mint gum checks for fragility
    if REVEL.IsShrineEffectActive(ShrineTypes.FRAGILITY) then
        for _, ent in ipairs(REVEL.roomEnemies) do
            local onIce = REVEL.Glacier.CheckIce(ent, currentRoom)
	    	local data = ent:GetData()
	    	if onIce then
	    		if not data.OnIce then
	    			data.OnIce = 0
	    		end

	    		data.OnIce = math.min(5, data.OnIce + 1)
	    	else
	    		if data.OnIce then
	    			if data.OnIce > 0 then
	    				data.OnIce = data.OnIce - 1
	    			else
	    				data.OnIce = nil
	    			end
	    		end
	    	end
        end
    end
end


revel:AddCallback(ModCallbacks.MC_POST_UPDATE, slipperyPostUpdate)

end