return function ()
    
local Knives = {}

---@deprecated
function REVEL.FireKnife(pos, spd, degree)
    local knf = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, pos, Vector(math.cos(math.rad(degree))*spd,math.sin(math.rad(degree))*spd), nil)
    knf:GetSprite():Load("gfx/008.000_moms knife.anm2", true)
    knf:GetSprite():Play("Idle", true)
    knf:GetSprite().Rotation = degree-90
    knf:GetSprite().Offset = Vector(0,-10)
    table.insert(Knives, knf)
    return knf
end

-- Only used by monolith and wandering soul, TODO: use a more vanilla-intended way to do this
function REVEL.FireReturningKnife(pos, time, degree, distance, parent, damage)
    local knf = Isaac.Spawn(EntityType.ENTITY_EFFECT, 6, 0, pos, Vector(math.cos(math.rad(degree))*(time/2),math.sin(math.rad(degree))*(time/2)), nil)
    knf:GetSprite():Load("gfx/008.000_moms knife.anm2", true)
    knf:GetSprite():Play("Idle", true)
    knf:GetSprite().Rotation = degree-90
    knf:GetSprite().Offset = Vector(0,-10)
    REVEL.GetData(knf).Returns = true
    REVEL.GetData(knf).ReturnSpdVec = knf.Velocity*((distance/time)/(distance/2))
    REVEL.GetData(knf).LifeSpan = time-1
    REVEL.GetData(knf).StartPos = pos
    REVEL.GetData(knf).Parent = parent
    REVEL.GetData(knf).Damage = damage
    table.insert(Knives, knf)
    return knf
end

revel:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    for i,knf in ipairs(Knives) do
        for _,e in ipairs(REVEL.roomEnemies) do
            if (e.Position-knf.Position):Length() <= e.Mass+10 then
                if REVEL.GetData(knf).Damage then e:TakeDamage(REVEL.player.Damage,EntityFlag.FLAG_POISON,EntityRef(REVEL.player),0)
                else e:TakeDamage(REVEL.GetData(knf).Damage,EntityFlag.FLAG_POISON,EntityRef(REVEL.player),0) end
            end
        end
        if REVEL.GetData(knf).Returns then
            knf.Velocity = knf.Velocity-REVEL.GetData(knf).ReturnSpdVec
            if REVEL.GetData(knf).Parent then knf.Position = knf.Position+REVEL.GetData(knf).Parent.Velocity end
            if knf.FrameCount >= REVEL.GetData(knf).LifeSpan then
                table.remove(Knives, i)
                knf:Remove()
            end
        elseif not REVEL.room:IsPositionInRoom(knf.Position, 100) then
            table.remove(Knives, i)
            knf:Remove()
        end
    end
end)

end