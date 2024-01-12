local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

return function()

--------------------
-- WANDERING SOUL --
--------------------

--[[
Passive Item.
Treasure Pool. Secret Pool.
Spawn a soul that helps you in combat
]]

local SoulDisabledItems = {
    [8]=1,[9]=1,[10]=1,[11]=1,[12]=1,[15]=1,[16]=1,[17]=1,[18]=1,[19]=1,[22]=1,[23]=1,[24]=1,[25]=1,[26]=1,
    [33]=1,[34]=1,[35]=1,[36]=1,[37]=1,[38]=1,[39]=1,[40]=1,[41]=1,[42]=1,[43]=1,[44]=1,[45]=1,[47]=1,[49]=1,
    [56]=1,[57]=1,[58]=1,[62]=1,[63]=1,[65]=1,[66]=1,[67]=1,[71]=1,[72]=1,[73]=1,[74]=1,[75]=1,[77]=1,[78]=1,[81]=1,[83]=1,
    [84]=1,[85]=1,[86]=1,[88]=1,[92]=1,[93]=1,[94]=1,[95]=1,[96]=1,[97]=1,[98]=1,[99]=1,[100]=1,[102]=1,[105]=1,[106]=1,[107]=1,[111]=1,[112]=1,[113]=1,[116]=1,
    [117]=1,[122]=1,[123]=1,[124]=1,[125]=1,[126]=1,[127]=1,[128]=1,[130]=1,[131]=1,[133]=1,[135]=1,[136]=1,[137]=1,
    [140]=1,[141]=1,[144]=1,[145]=1,[146]=1,[147]=1,[155]=1,[158]=1,[160]=1,[163]=1,[164]=1,[166]=1,[167]=1,[170]=1,[171]=1,[172]=1,[174]=1,[175]=1,
    [177]=1,[178]=1,[181]=1,[184]=1,[186]=1,[187]=1,[188]=1,[190]=1,[192]=1,[194]=1,[195]=1,[196]=1,[198]=1,[207]=1,[209]=1,[218]=1,
    [219]=1,[223]=1,[226]=1,[227]=1,[232]=1,[238]=1,[239]=1,[240]=1,[252]=1,[256]=1,[258]=1,[260]=1,[262]=1,[264]=1,[265]=1,[266]=1,[267]=1,[268]=1,[269]=1,[270]=1,[271]=1,[272]=1,[273]=1,[274]=1,[275]=1,[276]=1,[277]=1,[278]=1,[279]=1,[280]=1,[281]=1,[282]=1,[283]=1,[284]=1,
    [285]=1,[286]=1,[287]=1,[288]=1,[289]=1,[290]=1,[291]=1,[292]=1,[293]=1,[294]=1,[295]=1,[296]=1,[297]=1,
    [298]=1,[301]=1,[304]=1,[312]=1,[318]=1,[319]=1,[320]=1,[321]=1,[322]=1,[323]=1,[324]=1,[325]=1,[326]=1,[327]=1,[328]=1,
    [334]=1,[338]=1,[340]=1,[343]=1,[344]=1,[346]=1,[347]=1,[348]=1,[349]=1,[351]=1,[352]=1,[353]=1,[354]=1,
    [357]=1,[360]=1,[361]=1,[362]=1,[363]=1,[364]=1,[365]=1,[366]=1,[367]=1,[370]=1,[372]=1,[376]=1,[380]=1,[381]=1,[382]=1,[383]=1,[384]=1,[385]=1,[386]=1,[387]=1,[388]=1,[389]=1,[390]=1,[392]=1,[396]=1,[403]=1,[404]=1,[405]=1,[406]=1,[409]=1,[415]=1,
    [417]=1,[419]=1,[421]=1,[422]=1,[425]=1,[426]=1,[427]=1,[428]=1,[430]=1,[431]=1,[433]=1,[434]=1,[435]=1,[436]=1,[437]=1,[439]=1,[441]=1,[438]=1,[449]=1,[451]=1,
    [454]=1,[456]=1,[457]=1,[458]=1,[464]=1,[467]=1,[468]=1,[469]=1,[470]=1,[471]=1,[472]=1,[473]=1,[474]=1,[475]=1,[476]=1,[477]=1,[478]=1,[479]=1,[480]=1,[481]=1,[482]=1,[483]=1,
    [484]=1,[485]=1,[486]=1,[487]=1,[488]=1,[489]=1,[490]=1,[491]=1,[492]=1,[500]=1,[501]=1,[504]=1,[505]=1,[507]=1,[508]=1,[509]=1,[510]=1,[511]=1,[512]=1,
    [515]=1,[516]=1,[517]=1,[518]=1,[519]=1,[520]=1,[521]=1,[522]=1,[523]=1,[525]=1,[526]=1,[527]=1,[528]=1,[534]=1,
    [REVEL.ITEM.HYPER_DICE.id]=1,[REVEL.ITEM.MONOLITH.id]=1,[REVEL.ITEM.CHUM.id]=1,[REVEL.ITEM.ROBOT.id]=1,
    [REVEL.ITEM.ROBOT2.id]=1
}
local SoulItems = {
    [2]=function(d) d.AmountTears = d.AmountTears+2 end,
    [52]=function(d) d.WeaponType[WeaponType.WEAPON_BOMBS] = true end,
    [68]=function(d) d.WeaponType[WeaponType.WEAPON_LASER] = true end,
    [69]=function(d) d.Charging = true d.Damage = d.Damage*4 d.MaxFireDelay = d.MaxFireDelay*3 end,
    [114]=function(d) d.WeaponType[WeaponType.WEAPON_KNIFE] = true end,
    [118]=function(d) d.WeaponType[WeaponType.WEAPON_BRIMSTONE] = true end,
    [153]=function(d) d.AmountTears = d.AmountTears+3 end,
    [245]=function(d) d.AmountTears = d.AmountTears+1 end,
    [343]=function(d) d.Luck = d.Luck+1 end,
    [381]=function(d) d.MaxFireDelay = math.ceil(d.MaxFireDelay/1.7) end,
}

local SoulCharacters = {
    PlayerType.PLAYER_ISAAC,
    PlayerType.PLAYER_MAGDALENA,
    PlayerType.PLAYER_CAIN,
    PlayerType.PLAYER_JUDAS,
    PlayerType.PLAYER_EVE,
    PlayerType.PLAYER_SAMSON,
    PlayerType.PLAYER_AZAZEL,
    PlayerType.PLAYER_EDEN,
    PlayerType.PLAYER_LAZARUS,
}

local SoulCharacterSpeed = {
    Default = 6,
    [PlayerType.PLAYER_MAGDALENA] = 5.1,
    [PlayerType.PLAYER_CAIN] = 7.8,
    [PlayerType.PLAYER_EVE] = 7.38,
}

local SoulCharacterHair = {
    [PlayerType.PLAYER_MAGDALENA] = "gfx/characters/character_002_magdalenehead.anm2",
    [PlayerType.PLAYER_CAIN] = "gfx/characters/character_003_cainseyepatch.anm2",
    [PlayerType.PLAYER_JUDAS] = "gfx/characters/character_004_judasfez.anm2",
    [PlayerType.PLAYER_EVE] = "gfx/characters/character_005_evehead.anm2",
    [PlayerType.PLAYER_SAMSON] = "gfx/characters/character_007_samsonhead.anm2",
    [PlayerType.PLAYER_AZAZEL] = "gfx/characters/character_008_azazelhead.anm2",
    [PlayerType.PLAYER_EDEN] = "gfx/characters/character_009_edenhair1.anm2",
    [PlayerType.PLAYER_LAZARUS] = "gfx/characters/character_lazarushair1.anm2",
    [PlayerType.PLAYER_LILITH] = "gfx/characters/character_lilithhair.anm2",
}
local SoulCharacterHeadSprite = {
    [PlayerType.PLAYER_AZAZEL] = "gfx/characters/revelcommon/costumes/character_custom_azazelhead.png",
}

---@return Rev.WanderingSoul
local function GetSoulData(soul)
    return REVEL.GetData(soul.Entity or soul).WanderingSoul
end

local function PickSoulCharacter(player, rng)
    local pdata = player:GetData()
    local char
    for i = 1, 100 do -- max 100 tries
        char = REVEL.randomFrom(SoulCharacters, rng)
        if #pdata.souls >= #SoulCharacters then 
            return char
        end
        local duplicatechar = false
        for _,s in ipairs(pdata.souls) do
            if GetSoulData(s).Character == char then
                duplicatechar = true
                break
            end
        end
        if not duplicatechar then
            return char
        end
    end
    REVEL.DebugToString("[WARN] Wandering Soul | Too many random attempts to pick soul")
    return char
end

---@param player EntityPlayer
function REVEL.AddWanderingSoul(player)
    local pdata = player:GetData()
    if not pdata.souls then pdata.souls = {} end
    local pos = Vector(0,0)
    local i = 0
    while i ~= 50 do
        local dir = math.rad(math.random(1,360))
        local length = math.random(40,120)
        pos = player.Position + Vector(math.sin(dir)*length,math.cos(dir)*length)
        if  pos.X > 0 and pos.X < REVEL.room:GetBottomRightPos().X 
        and pos.Y > 0 and pos.Y < REVEL.room:GetBottomRightPos().X then
            break
        end
        i = i+1
    end
    if i == 50 then
        pos = player.Position
    end

    local soul = Isaac.Spawn(REVEL.ENT.SOUL.id, REVEL.ENT.SOUL.variant, 0, pos, Vector(0,0), player)
    local sprite = soul:GetSprite()
    soul:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

    sprite:Load("gfx/familiar/revelcommon/soul.anm2", true)
    sprite:Play("Appear", true)
    for i=0, 12 do 
        sprite:ReplaceSpritesheet(i, "gfx/characters/costumes/character_012_thelost.png") 
    end
    sprite:LoadGraphics()
    sprite.Offset = Vector(0,-3)
    sprite.Color = Color(1,1,1,0.5)

    ---@class Rev.WanderingSoul
    local soulData = {}
    REVEL.GetData(soul).WanderingSoul = soulData

    soulData.Target = nil
    soulData.State = "donothing"
    local rng = REVEL.RNG()
    rng:SetSeed(soul.InitSeed, 38)
    soulData.Character = PickSoulCharacter(player, rng)
    soulData.Speed = SoulCharacterSpeed[soulData.Character] or SoulCharacterSpeed.Default
    soulData.Player = player
    soulData.PrevVel = Vector.Zero
    soulData.AmountTears = 1
    soulData.MaxFireDelay = 30
    soulData.FireDelay = soulData.MaxFireDelay
    soulData.ShotSpeed = 10
    soulData.Damage = 1.75
    soulData.Luck = 0
    soulData.Range = -1
    soulData.TearRange = 340
    soulData.TearFlags = TearFlags.TEAR_SPECTRAL
    soulData.TearColor = Color(1,1,1,1, conv255ToFloat(30,30,30))
    soulData.LaserColor = Color.Default
    soulData.BombVariant = BombVariant.BOMB_NORMAL
    soulData.WeaponType = {[WeaponType.WEAPON_TEARS]=true}
    soulData.Size = Vector.One
    soulData.EyeSide = 90
    soulData.KnifeSprite = Sprite()
    soulData.KnifeSprite:Load("gfx/008.000_moms knife.anm2", true)
    soulData.KnifeSprite:Play("Idle", true)
    soulData.KnifeSprite.Color = Color(0.70, 0.70, 0.70)
    if soulData.Character == PlayerType.PLAYER_AZAZEL then
        soulData.WeaponType[WeaponType.WEAPON_BRIMSTONE] = true
        soulData.ShortLaser = true
        soulData.MaxFireDelay = soulData.MaxFireDelay+60
        soulData.FireDelay = soulData.MaxFireDelay
    end
    soulData.Charging = nil
    soulData.Knife = nil

    if SoulCharacterHair[soulData.Character] then
        soulData.HairSprite = Sprite()
        soulData.HairOffset = Vector(0,13.5)
        soulData.HairSprite.Color = Color(1,1,1,0.9,conv255ToFloat(0,0,0))
        soulData.HairSprite:Load(SoulCharacterHair[soulData.Character], true)
        if SoulCharacterHeadSprite[soulData.Character] then
            soulData.HairSprite:ReplaceSpritesheet(0, SoulCharacterHeadSprite[soulData.Character])
            soulData.HairSprite:LoadGraphics()
        end
        soulData.HairSprite:SetFrame("HeadDown", 0)
    end

    soul:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    soul:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
    soul:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)

    soul.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
    soul.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
    table.insert(pdata.souls, {Items={},Entity=soul})
    
    soulData.Index = #pdata.souls

    return soul
end

local function wsoul_PostPeffectUpdate(_, player)
    local data = player:GetData()
    if not data.souls then data.souls = {} end
    if REVEL.ITEM.WANDERING_SOUL:PlayerHasCollectible(player) then
        local amountsoulsneeded = player:GetCollectibleNum(REVEL.ITEM.WANDERING_SOUL.id) - #data.souls
        if amountsoulsneeded > 0 then
            for i = 1, amountsoulsneeded do
                local soul = REVEL.AddWanderingSoul(player)
            end
        end
    end
end

---@param soul EntityNPC
local function wsoul_PostNpcUpdate(_, soul)
    if soul.Variant == REVEL.ENT.SOUL.variant then
        local sprite = soul:GetSprite()
        local soulData = GetSoulData(soul)
        local player = soulData.Player
        local pdata = player:GetData()
        if sprite:IsPlaying("Appear") then
            if sprite:GetFrame() ~= 10 and soulData.HairOffset then
                soulData.HairOffset = Vector(0, soulData.HairOffset.Y-1.5)
            end
            return
        end
        if sprite:IsFinished("Death") then
            soul:Remove()
            return
        end
        if sprite:IsPlaying("Death") then return end

        if soul.FrameCount > 1 then
            sprite.PlaybackSpeed = 0.5+(soul.Velocity:Length()/12)
        end
        sprite.Scale = soulData.Size
        -- Targeting
        if not REVEL.room:IsClear() then
            soulData.Target = REVEL.getClosestEnemy(soul, false, true, true, true)
            if soulData.Target then
                soulData.State = "fighting"
            else soulData.State = "donothing" end
        end
        sprite.Color = Color(1,1,1,0.5)
        if soulData.HairSprite then 
            soulData.HairSprite.Color = Color(1,1,1,0.9) 
        end

        -- Movement
        soul.Velocity = Vector.Zero
        if soulData.State == "fighting" then
            for _,othersoul in ipairs(pdata.souls) do
                if soul.Index ~= othersoul.Index and (othersoul.Entity.Position-soul.Position):Length() <= 40 then
                    soul.Velocity = soul.Velocity+(soul.Position-othersoul.Entity.Position):Resized(soulData.Speed*2)
                end
            end
            local PredictedTargetPos = soulData.Target.Position+(soulData.Target.Velocity*((soul.Position-soulData.Target.Position):Length()/40))
            if (soul.Position-soulData.Target.Position):Length() <= 60 then
                soul.Velocity = soul.Velocity+(soul.Position-soulData.Target.Position):Resized(soulData.Speed*2)
            elseif (soul.Position-soulData.Target.Position):Length() >= 120 then
                soul.Velocity = soul.Velocity+(soulData.Target.Position-soul.Position):Resized(soulData.Speed*2)
            elseif math.abs(soul.Position.X-PredictedTargetPos.X) > soulData.Speed/2 and math.abs(soul.Position.Y-PredictedTargetPos.Y) > soulData.Speed/2 then
                if math.abs(soul.Position.X-PredictedTargetPos.X) < math.abs(soul.Position.Y-PredictedTargetPos.Y) then
                    if soul.Position.X-PredictedTargetPos.X < 0 then soul.Velocity = soul.Velocity+Vector(soulData.Speed,0)
                    else soul.Velocity = soul.Velocity+Vector(-soulData.Speed,0) end
                else
                    if soul.Position.Y-PredictedTargetPos.Y < 0 then soul.Velocity = soul.Velocity+Vector(0,soulData.Speed)
                    else soul.Velocity = soul.Velocity+Vector(0,-soulData.Speed) end
                end
            end
            soul.Velocity = soul.Velocity+(soul.Velocity-REVEL.room:GetCenterPos()):Resized(soulData.Speed/2)+Vector(math.random()-0.5,math.random()-0.5)
        end
        if soul.Velocity.X ~= 0 and soul.Velocity.Y ~= 0 then
            if math.abs(soul.Velocity.X) > math.abs(soul.Velocity.Y) then
                if soul.Velocity.X < 0 and not sprite:IsPlaying("WalkLeft") then
                    sprite:Play("WalkLeft", true)
                elseif soul.Velocity.X > 0 and not sprite:IsPlaying("WalkRight") then
                    sprite:Play("WalkRight", true)
                end
            else
                if soul.Velocity.Y < 0 and not sprite:IsPlaying("WalkUp") then
                    sprite:Play("WalkUp", true)
                elseif soul.Velocity.Y > 0 and not sprite:IsPlaying("WalkDown") then
                    sprite:Play("WalkDown", true)
                end
            end
        elseif not sprite:IsPlaying("WalkDown") then
            sprite:Play("WalkDown", true)
        end
        soul.Velocity = soul.Velocity+((soulData.PrevVel-soul.Velocity)*0.9)
        if soul.Velocity:Length() > soulData.Speed then 
            soul.Velocity = soul.Velocity:Resized(soulData.Speed) 
        end
        soulData.PrevVel = soul.Velocity
        if soulData.FireDelay <= soulData.MaxFireDelay then 
            soulData.FireDelay = soulData.FireDelay-1 
        end

        -- Shooting
        if soulData.State == "fighting" then
            local TearDir = 0
            local LaserDir = 0
            local tearvariant = TearVariant.BLUE
            local charging = soulData.WeaponType[WeaponType.WEAPON_BRIMSTONE] or soulData.Charging
            if soulData.WeaponType[WeaponType.WEAPON_KNIFE] or soulData.WeaponType[WeaponType.WEAPON_BOMBS] then charging = false end
            soulData.FireDelay = soulData.FireDelay-1
            if math.abs(soul.Position.X-soulData.Target.Position.X) > math.abs(soul.Position.Y-soulData.Target.Position.Y) then
                if soul.Position.X-soulData.Target.Position.X < 0 then
                    TearDir = (Vector(soulData.ShotSpeed,0)):GetAngleDegrees()+90
                    LaserDir = 0
                    if charging then
                        if soulData.FireDelay > soulData.MaxFireDelay+29 then sprite:SetOverlayFrame("HeadRightCharge", 20)
                        elseif soulData.FireDelay <= soulData.MaxFireDelay then sprite:SetOverlayFrame("HeadRightCharge", math.floor(math.abs(soulData.FireDelay-soulData.MaxFireDelay)/(soulData.MaxFireDelay/18))) end
                    else
                        if soulData.FireDelay <= 1 then sprite:SetOverlayFrame("HeadRight", 2)
                        else sprite:SetOverlayFrame("HeadRight", 0) end
                    end
                else
                    TearDir = (Vector(-soulData.ShotSpeed,0)):GetAngleDegrees()+90
                    LaserDir = 180
                    if charging then
                        if soulData.FireDelay > soulData.MaxFireDelay+29 then sprite:SetOverlayFrame("HeadLeftCharge", 20)
                        elseif soulData.FireDelay <= soulData.MaxFireDelay then sprite:SetOverlayFrame("HeadLeftCharge", math.floor(math.abs(soulData.FireDelay-soulData.MaxFireDelay)/(soulData.MaxFireDelay/18))) end
                    else
                        if soulData.FireDelay <= 1 then sprite:SetOverlayFrame("HeadLeft", 2)
                        else sprite:SetOverlayFrame("HeadLeft", 0) end
                    end
                end
            else
                if soul.Position.Y-soulData.Target.Position.Y < 0 then
                    TearDir = (Vector(0,soulData.ShotSpeed)):GetAngleDegrees()-90
                    LaserDir = 90
                    if charging then
                        if soulData.FireDelay > soulData.MaxFireDelay+29 then sprite:SetOverlayFrame("HeadDownCharge", 20)
                        elseif soulData.FireDelay <= soulData.MaxFireDelay then sprite:SetOverlayFrame("HeadDownCharge", math.floor(math.abs(soulData.FireDelay-soulData.MaxFireDelay)/(soulData.MaxFireDelay/18))) end
                    else
                        if soulData.FireDelay <= 1 then sprite:SetOverlayFrame("HeadDown", 2)
                        else sprite:SetOverlayFrame("HeadDown", 0) end
                    end
                else
                    TearDir = (Vector(0,-soulData.ShotSpeed)):GetAngleDegrees()-90
                    LaserDir = 270
                    if charging then
                        if soulData.FireDelay > soulData.MaxFireDelay+29 then sprite:SetOverlayFrame("HeadUpCharge", 20)
                        elseif soulData.FireDelay <= soulData.MaxFireDelay then sprite:SetOverlayFrame("HeadUpCharge", math.floor(math.abs(soulData.FireDelay-soulData.MaxFireDelay)/(soulData.MaxFireDelay/18))) end
                    else
                        if soulData.FireDelay <= 1 then sprite:SetOverlayFrame("HeadUp", 2)
                        else sprite:SetOverlayFrame("HeadUp", 0) end
                    end
                end
            end
            if soulData.FireDelay <= 0 then
                soulData.FireDelay = soulData.MaxFireDelay
                local soulpos = soul.Position+sprite.Offset
                for i=0, soulData.AmountTears-1 do
                    -- bombs
                    if soulData.WeaponType[WeaponType.WEAPON_BOMBS] then
                        local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, soulData.BombVariant, 0, soul.Position, Vector(math.sin(math.rad(TearDir+(i*8-(soulData.AmountTears-1*4))))*soulData.ShotSpeed,math.cos(math.rad(TearDir+(i*8-(soulData.AmountTears-1*4))))*soulData.ShotSpeed)+(soul.Velocity*0.25), soul)
                    -- knife
                    elseif soulData.WeaponType[WeaponType.WEAPON_KNIFE] then
                        local KnifeDir = TearDir
                        if KnifeDir%180 == 0 then KnifeDir = KnifeDir+90
                        else KnifeDir = KnifeDir-90 end
                        local knf = REVEL.FireReturningKnife(soulpos+Vector(math.sin(math.rad(TearDir))*20,math.cos(math.rad(TearDir))*20), 30, KnifeDir, 200, soul, soulData.Damage)
                        knf:GetSprite().Color = soulData.TearColor
                        soulData.Knife = knf
                        soulData.FireDelay = soulData.MaxFireDelay+30
                    -- brimstone
                    elseif soulData.WeaponType[WeaponType.WEAPON_BRIMSTONE] then
                        local distance = 20
                        if TearDir == (Vector(0,soulData.ShotSpeed)):GetAngleDegrees()-90 then distance = 2 end
                        local laser = EntityLaser.ShootAngle(1, soulpos+Vector(math.sin(math.rad(TearDir))*distance,math.cos(math.rad(TearDir))*distance)+Vector(0,-22), LaserDir, 30, Vector(0,0), soul)
                        laser:GetSprite().Color = soulData.LaserColor
                        laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
                        laser.CollisionDamage = soulData.Damage/3
                        laser.SpawnerType = REVEL.ENT.SOUL.id
                        laser:ToLaser().TearFlags = soulData.TearFlags
                        if soulData.ShortLaser then laser:ToLaser().MaxDistance = 120 end
                        soulData.FireDelay = soulData.MaxFireDelay+30
                    -- lasers
                    elseif soulData.WeaponType[WeaponType.WEAPON_LASER] then
                        local distance = 20
                        if TearDir == (Vector(0,soulData.ShotSpeed)):GetAngleDegrees()-90 then distance = 2 end
                        local laser = EntityLaser.ShootAngle(2, soulpos+Vector(math.sin(math.rad(TearDir))*distance,math.cos(math.rad(TearDir))*distance)+Vector(0,-22), LaserDir, 30, Vector(0,0), soul)
                        laser:GetSprite().Color = soulData.LaserColor
                        laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
                        laser.CollisionDamage = soulData.Damage
                        laser.SpawnerType = REVEL.ENT.SOUL.id
                        laser:ToLaser().TearFlags = soulData.TearFlags
                        laser:ToLaser().OneHit = true
                        laser:ToLaser().Timeout = 1
                    -- tears
                    elseif soulData.WeaponType[WeaponType.WEAPON_TEARS] then
                        soulData.EyeSide = soulData.EyeSide*-1
                        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, tearvariant, 0, soulpos+Vector(math.sin(math.rad(TearDir+soulData.EyeSide))*6,math.cos(math.rad(TearDir+soulData.EyeSide))*6), Vector(math.sin(math.rad(TearDir+((i-((soulData.AmountTears-1)*0.5))*16)))*soulData.ShotSpeed,math.cos(math.rad(TearDir+((i-((soulData.AmountTears-1)*0.5))*16)))*soulData.ShotSpeed)+(soul.Velocity*0.25), soul)
                        t.CollisionDamage = soulData.Damage
                        t:ToTear().TearFlags = soulData.TearFlags
                        t:ToTear().Height = - soulData.TearRange * 17.5 / 260
                        t:ToTear().FallingSpeed = soulData.Range
                        t:GetSprite().Color = soulData.TearColor
                        t:GetSprite().Scale = Vector(math.sqrt(soulData.Damage/1.75),math.sqrt(soulData.Damage/1.75))
                    end
                end
            end
        elseif soulData.State == "donothing" then
            soulData.FireDelay = soulData.MaxFireDelay
            sprite:SetOverlayFrame("HeadDown", 0)
        end
        if soulData.HairSprite and soulData.FireDelay <= soulData.MaxFireDelay then
            if sprite:IsOverlayFinished("HeadDown") then soulData.HairSprite:SetFrame("HeadDown", sprite:GetOverlayFrame())
            elseif sprite:IsOverlayFinished("HeadLeft") then soulData.HairSprite:SetFrame("HeadLeft", sprite:GetOverlayFrame())
            elseif sprite:IsOverlayFinished("HeadUp") then soulData.HairSprite:SetFrame("HeadUp", sprite:GetOverlayFrame())
            elseif sprite:IsOverlayFinished("HeadRight") then soulData.HairSprite:SetFrame("HeadRight", sprite:GetOverlayFrame())
            elseif sprite:IsOverlayFinished("HeadDownCharge") then soulData.HairSprite:SetFrame("HeadDown", 0)
            elseif sprite:IsOverlayFinished("HeadLeftCharge") then soulData.HairSprite:SetFrame("HeadLeft", 0)
            elseif sprite:IsOverlayFinished("HeadUpCharge") then soulData.HairSprite:SetFrame("HeadUp", 0)
            elseif sprite:IsOverlayFinished("HeadRightCharge") then soulData.HairSprite:SetFrame("HeadRight", 0) end
        end
    end
end

---@param soul EntityNPC
local function wsoul_PostNpcRender(_, soul, renderOffset)
    if not soul.Variant == REVEL.ENT.SOUL.variant then return end

    local sprite = soul:GetSprite()
    local soulData = GetSoulData(soul)

    if soulData.HairSprite and not IsAnimOn(sprite, "Death") then
        local pos = Isaac.WorldToScreen(soul.Position + soulData.HairOffset) + sprite.Offset
        if REVEL.IsRenderPassReflection() then
            pos = pos + Vector(0, 8)
        end
        soulData.HairSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset())
    end
    if soul.Variant == REVEL.ENT.SOUL.variant 
    and soulData.WeaponType[WeaponType.WEAPON_KNIFE] 
    and not soulData.WeaponType[WeaponType.WEAPON_BOMBS] 
    and (not soulData.Knife or not soulData.Knife:Exists())
    then 
        if sprite:IsOverlayFinished("HeadRight") then 
            soulData.KnifeSprite.Rotation = 270
        elseif sprite:IsOverlayFinished("HeadUp") then 
            soulData.KnifeSprite.Rotation = 180
        elseif sprite:IsOverlayFinished("HeadLeft") then 
            soulData.KnifeSprite.Rotation = 90
        elseif sprite:IsOverlayFinished("HeadDown") then 
            soulData.KnifeSprite.Rotation = 0 
        end
        local wpos = soul.Position + Vector(
            math.sin(math.rad(soulData.KnifeSprite.Rotation * -1)) * 20,
            math.cos(math.rad(soulData.KnifeSprite.Rotation * -1)) * 20
        )
        local pos = Isaac.WorldToScreen(wpos) + sprite.Offset
        soulData.KnifeSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset())
    end
end

local function wsoul_PostNewRoom()
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        data.souls = {}
    end
end

local function wsoul_EntTakeDmg(_, player, dmg, flag, src, invuln)
    if player.Type == EntityType.ENTITY_PLAYER then
        if src and src.Type == REVEL.ENT.SOUL.id then
            return false
        end
    end
end

local function wsoul_PostGameStarted(_, savestate)
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        if not savestate then
            data.phylactery = nil
        end
        if not data.souls then data.souls = {} end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, wsoul_PostNpcUpdate, REVEL.ENT.SOUL.id)
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, wsoul_PostNpcRender, REVEL.ENT.SOUL.id)

revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, wsoul_EntTakeDmg)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, wsoul_PostGameStarted)
revel:AddCallback(RevCallbacks.POST_BASE_PEFFECT_UPDATE, wsoul_PostPeffectUpdate)

StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, wsoul_PostNewRoom)

end