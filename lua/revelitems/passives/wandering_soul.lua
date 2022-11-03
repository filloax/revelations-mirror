local StageAPICallbacks = require("lua.revelcommon.enums.StageAPICallbacks")
local RevCallbacks      = require("lua.revelcommon.enums.RevCallbacks")

REVEL.LoadFunctions[#REVEL.LoadFunctions + 1] = function()

--------------------
-- WANDERING SOUL --
--------------------

--[[
Passive Item.
Treasure Pool. Secret Pool.
Spawn a soul that helps you in combat
]]

local soulmaxlifespan = -1
local soulDisabledItems = {
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
local soulItems = {
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

function revel:SpawnSouls()
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        if not data.souls then data.souls = {} end
        if REVEL.ITEM.WANDERING_SOUL:PlayerHasCollectible(player) then
            local amountsoulsneeded = player:GetCollectibleNum(REVEL.ITEM.WANDERING_SOUL.id) - #data.souls
            if amountsoulsneeded > 0 then
                for i = 1, amountsoulsneeded do
                    local soul = REVEL:AddSoul(player) --see actives/phylactery.lua
                    soul:GetData().LifeSpan = -9999999
                end
            end
        end
    end
end

function REVEL:GetPlayerItems(player)
    local itemlist = {}
    for item=1, CollectibleType.NUM_COLLECTIBLES + #REVEL.ITEM do
        if player:HasCollectible(item) then
            for i=1, player:GetCollectibleNum(item) do table.insert(itemlist, item) end
        end
    end
    return itemlist
end

function REVEL:RemovePlayerItems(player, forsoul)
    for item=1, CollectibleType.NUM_COLLECTIBLES+#REVEL.ITEM do
        if player:HasCollectible(item) and (not forsoul or not soulDisabledItems[item])  then
            for i=1, player:GetCollectibleNum(item) do player:RemoveCollectible(item) end
        end
    end
end

function REVEL:AddSoul(player)
    local data = player:GetData()
    if not data.souls then data.souls = {} end
    local pos = Vector(0,0)
    local i = 0
    while i ~= 50 do
        local dir = math.rad(math.random(1,360))
        local length = math.random(40,120)
        pos = player.Position+Vector(math.sin(dir)*length,math.cos(dir)*length)
        if pos.X > 0 and pos.X < REVEL.room:GetBottomRightPos().X and pos.Y > 0 and pos.Y < REVEL.room:GetBottomRightPos().X then
            break
        end
        i = i+1
    end
    if i == 50 then
        pos = player.Position
    end
    local soul = Isaac.Spawn(REVEL.ENT.SOUL.id, REVEL.ENT.SOUL.variant, 0, pos, Vector(0,0), player)
    soul:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
    soul:GetSprite():Load("gfx/familiar/revelcommon/soul.anm2", true)
    soul:GetSprite():Play("Appear", true)
    for i=0, 12 do soul:GetSprite():ReplaceSpritesheet(i, "gfx/characters/costumes/character_012_thelost.png") end
    soul:GetSprite():LoadGraphics()
    soul:GetData().Target = nil
    soul:GetData().State = "donothing"
    local characters = {PlayerType.PLAYER_ISAAC,PlayerType.PLAYER_MAGDALENA,PlayerType.PLAYER_CAIN,PlayerType.PLAYER_JUDAS,
    PlayerType.PLAYER_EVE,PlayerType.PLAYER_SAMSON,PlayerType.PLAYER_AZAZEL,PlayerType.PLAYER_EDEN,PlayerType.PLAYER_LAZARUS}
    while true do
        soul:GetData().Character = characters[math.random(#characters)]
        if #data.souls >= #characters then break end
        local duplicatechar = false
        for _,s in ipairs(data.souls) do
            if s.Entity:GetData().Character == soul:GetData().Character then
                duplicatechar = true
                break
            end
        end
        if not duplicatechar then break end
    end
    if soul:GetData().Character == PlayerType.PLAYER_MAGDALENA then soul:GetData().Speed = 5.1
    elseif soul:GetData().Character == PlayerType.PLAYER_CAIN then soul:GetData().Speed = 7.8
    elseif soul:GetData().Character == PlayerType.PLAYER_EVE then soul:GetData().Speed = 7.38
    else soul:GetData().Speed = 6 end
    soul:GetSprite().Offset = Vector(0,-3)
    soul:GetData().LifeSpan = 0
    soul:GetData().player = player
    soul:GetData().PrevVel = Vector(0,0)
    soul:GetData().AmountTears = 1
    soul:GetData().MaxFireDelay = 30
    soul:GetData().FireDelay = soul:GetData().MaxFireDelay
    soul:GetData().ShotSpeed = 10
    soul:GetData().Damage = 1.75
    soul:GetData().Luck = 0
    soul:GetData().Range = -1
    soul:GetData().TearRange = 340
    soul:GetData().TearFlags = TearFlags.TEAR_SPECTRAL
    soul:GetData().TearColor = Color(1,1,1,1,conv255ToFloat(30,30,30))
    soul:GetData().LaserColor = Color(1,1,1,1,conv255ToFloat(0,0,0))
    soul:GetData().BombVariant = BombVariant.BOMB_NORMAL
    soul:GetData().WeaponType = {[WeaponType.WEAPON_TEARS]=true}
    soul:GetData().Size = Vector(1,1)
    soul:GetData().EyeSide = 90
    soul:GetSprite().Color = Color(1,1,1,0.5,conv255ToFloat(1,0,0,0))
    soul:GetData().KnifeSprite = Sprite()
    soul:GetData().KnifeSprite:Load("gfx/008.000_moms knife.anm2", true)
    soul:GetData().KnifeSprite:Play("Idle", true)
    soul:GetData().KnifeSprite.Color = Color(0.70,0.70,0.70,1,conv255ToFloat(0,0,0))
    if soul:GetData().Character == PlayerType.PLAYER_AZAZEL then
        soul:GetData().WeaponType[WeaponType.WEAPON_BRIMSTONE] = true
        soul:GetData().ShortLaser = true
        soul:GetData().MaxFireDelay = soul:GetData().MaxFireDelay+60
        soul:GetData().FireDelay = soul:GetData().MaxFireDelay
    end
    soul:GetData().HairSprite = Sprite()
    soul:GetData().HairOffset = Vector(0,13.5)
    soul:GetData().HairSprite.Color = Color(1,1,1,0.9,conv255ToFloat(0,0,0))
    if soul:GetData().Character == PlayerType.PLAYER_MAGDALENA then
        soul:GetData().HairSprite:Load("gfx/characters/character_002_magdalenehead.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_CAIN then
        soul:GetData().HairSprite:Load("gfx/characters/character_003_cainseyepatch.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_JUDAS then
        soul:GetData().HairSprite:Load("gfx/characters/character_004_judasfez.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_EVE then
        soul:GetData().HairSprite:Load("gfx/characters/character_005_evehead.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_SAMSON then
        soul:GetData().HairSprite:Load("gfx/characters/character_007_samsonhead.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_AZAZEL then
        soul:GetData().HairSprite:Load("gfx/characters/character_008_azazelhead.anm2", true)
        soul:GetData().HairSprite:ReplaceSpritesheet(0, "gfx/characters/revelcommon/costumes/character_custom_azazelhead.png")
        soul:GetData().HairSprite:LoadGraphics()
    elseif soul:GetData().Character == PlayerType.PLAYER_EDEN then
        soul:GetData().HairSprite:Load("gfx/characters/character_009_edenhair1.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_LAZARUS then
        soul:GetData().HairSprite:Load("gfx/characters/character_lazarushair1.anm2", true)
    elseif soul:GetData().Character == PlayerType.PLAYER_LILITH then
        soul:GetData().HairSprite:Load("gfx/characters/character_lilithhair.anm2", true)
    else
        soul:GetData().HairSprite = nil
    end
    if soul:GetData().HairSprite then
        soul:GetData().HairSprite:SetFrame("HeadDown", 0)
    end
    soul:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
    soul:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
    soul:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
    soul.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
    soul.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
    table.insert(data.souls, {Items={},Entity=soul})
    soul:GetData().Index = #data.souls
    return soul
end

function REVEL:SplitSoulItems(player)
    local data = player:GetData()
    for _,soul in ipairs(data.souls) do
        soul.Items = {}
        soul.Entity:GetData().Speed = 6
        soul.Entity:GetData().AmountTears = 1
        soul.Entity:GetData().MaxFireDelay = 30
        soul.Entity:GetData().FireDelay = soul.Entity:GetData().MaxFireDelay
        soul.Entity:GetData().ShotSpeed = 10
        soul.Entity:GetData().Damage = 1.75
        soul.Entity:GetData().Luck = 0
        soul.Entity:GetData().Range = -1
        soul.Entity:GetData().TearRange = 340
        soul.Entity:GetData().TearFlags = TearFlags.TEAR_SPECTRAL
        soul.Entity:GetData().TearColor = Color(1,1,1,1,conv255ToFloat(30,30,30))
        soul.Entity:GetData().LaserColor = Color(1,1,1,1,conv255ToFloat(0,0,0))
        soul.Entity:GetData().BombVariant = BombVariant.BOMB_NORMAL
        soul.Entity:GetData().WeaponType = {[WeaponType.WEAPON_TEARS]=true}
    end
    local items = REVEL:GetPlayerItems(player)
    for _,item in ipairs(items) do
        while true do
            local r = math.random(1,#data.souls)
            if #data.souls[r].Items < math.ceil(#items/#data.souls) then
                table.insert(data.souls[r].Items, item)
                if soulItems[item] then soulItems[item](data.souls[r].Entity:GetData()) end
                break
            end
        end
    end
    local h = {r=player:GetHearts(),m=player:GetMaxHearts(),s=player:GetSoulHearts(),b=player:GetBlackHearts(),e=player:GetEternalHearts()}
    local p = {c=player:GetNumCoins(),b=player:GetNumBombs(),k=player:GetNumKeys()}
    for _,soul in ipairs(data.souls) do
        REVEL:RemovePlayerItems(player, true)
        for _,item in ipairs(soul.Items) do
            if not soulDisabledItems[item] then
                player:AddCollectible(item,0,false)
            end
        end
        player:EvaluateItems()
        for i=0, 12 do player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/costumes/character_012_thelost.png") end
        player:GetSprite():LoadGraphics()
        player.CanFly = true
        player.TearFlags = BitOr(player.TearFlags, TearFlags.TEAR_SPECTRAL)
        player.TearColor = Color(1,1,1,1,conv255ToFloat(30,30,30))
        local sdata = soul.Entity:GetData()
        if sdata.Character == PlayerType.PLAYER_MAGDALENA then sdata.Speed = player.MoveSpeed*5.1
        elseif sdata.Character == PlayerType.PLAYER_CAIN then sdata.Speed = player.MoveSpeed*7.8
        elseif sdata.Character == PlayerType.PLAYER_EVE then sdata.Speed = player.MoveSpeed*7.38
        else sdata.Speed = player.MoveSpeed*6 end
        sdata.MaxFireDelay = player.MaxFireDelay*3
        sdata.FireDelay = sdata.MaxFireDelay
        sdata.ShotSpeed = player.ShotSpeed*10
        sdata.Damage = player.Damage
        sdata.Luck = player.Luck
        sdata.Range = player.TearFallingSpeed*-2
        sdata.TearRange = player.TearRange
        sdata.TearColor = player.TearColor
        sdata.LaserColor = player.LaserColor
        sdata.TearFlags = player.TearFlags
        if sdata.Character == PlayerType.PLAYER_AZAZEL then
            sdata.WeaponType[WeaponType.WEAPON_BRIMSTONE] = true
            sdata.ShortLaser = true
            sdata.MaxFireDelay = sdata.MaxFireDelay+60
            sdata.FireDelay = sdata.MaxFireDelay
        end
        if player:HasCollectible(12) then 
            sdata.Damage = (sdata.Damage-0.3)*(2/3) 
            sdata.Range = -5.25/23.75 
            sdata.Speed = sdata.Speed-1.7 
            sdata.TearRange = sdata.TearRange+7
        end
        if player:HasCollectible(71) then 
            sdata.Speed = sdata.Speed-1.7 
            sdata.Range = -4.25/23.75 
            sdata.TearRange = sdata.TearRange+21
        end
        if player:HasCollectible(196) then 
            sdata.MaxFireDelay = math.ceil(sdata.MaxFireDelay) 
        end
        if player:HasCollectible(370) then 
            sdata.MaxFireDelay = math.ceil(sdata.MaxFireDelay*1.3) 
            sdata.Range = -5.25/23.75 
            sdata.TearRange = sdata.TearRange7
        end
        if sdata.Damage <= 3.50 then 
            sdata.Damage = sdata.Damage/2
        else 
            sdata.Damage = sdata.Damage-1.75 
        end
    end
    REVEL:RemovePlayerItems(player, true)
    if (data.TrueCoop.Save.PlayerName == "Charon" or REVEL.IsDanteCharon(player)) then
        data.soulcontrolled = #data.souls
        for _,item in ipairs(data.souls[data.soulcontrolled].Items) do
            if not soulDisabledItems[item] then
                player:AddCollectible(item, 0, false)
            end
        end
        for i=0, 12 do player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/costumes/character_012_thelost.png") end
        player:GetSprite():LoadGraphics()
        player.CanFly = true
        player.TearFlags = player.TearFlags | TearFlags.TEAR_SPECTRAL
        player.TearColor = Color(1,1,1,1,conv255ToFloat(30,30,30))
        data.soulstartposition = player.Position
    else
        for _,item in ipairs(items) do
            if not soulDisabledItems[item] then
                player:AddCollectible(item, 0, false)
            end
        end
    end
    player:AddMaxHearts(h.m-player:GetMaxHearts())
    player:AddHearts(h.r-player:GetHearts())
    player:AddEternalHearts(h.e-player:GetEternalHearts())
    player:AddSoulHearts(h.s-player:GetSoulHearts())
    player:AddBlackHearts(h.b-player:GetBlackHearts())
    player:AddCoins(p.c-player:GetNumCoins())
    player:AddBombs(p.b-player:GetNumBombs())
    player:AddKeys(p.k-player:GetNumKeys())
end

function revel:updateSouls(soul)
    if soul.Variant == REVEL.ENT.SOUL.variant then
        local data = soul:GetData()
        local player = data.player
        local pdata = player:GetData()
        if soul:GetSprite():IsPlaying("Appear") then
            if soul:GetSprite():GetFrame() ~= 10 then
                soul:GetData().HairOffset = Vector(0,soul:GetData().HairOffset.Y-1.5)
            end
            return
        end
        if soul:GetSprite():IsFinished("Death") then
            soul:Remove()
            return
        end
        if soul:GetSprite():IsPlaying("Death") then return end
        if data.LifeSpan == soulmaxlifespan then
            soul:GetSprite():Play("Death")
            soul:GetSprite().PlaybackSpeed = 1
            soul:GetSprite():RemoveOverlay()
            player.CanFly = false
            local h = {r=player:GetHearts(),m=player:GetMaxHearts(),s=player:GetSoulHearts(),b=player:GetBlackHearts(),e=player:GetEternalHearts()}
            local p = {c=player:GetNumCoins(),b=player:GetNumBombs(),k=player:GetNumKeys()}
            for i,soul in ipairs(pdata.souls) do
                if i ~= pdata.soulcontrolled then
                    for _,item in ipairs(soul.Items) do
                        if not soulDisabledItems[item] then
                            player:AddCollectible(item, 0, false)
                        end
                    end
                end
            end
            player:AddMaxHearts(h.m-player:GetMaxHearts())
            player:AddHearts(h.r-player:GetHearts())
            player:AddEternalHearts(h.e-player:GetEternalHearts())
            player:AddSoulHearts(h.s-player:GetSoulHearts())
            player:AddBlackHearts(h.b-player:GetBlackHearts())
            player:AddCoins(p.c-player:GetNumCoins())
            player:AddBombs(p.b-player:GetNumBombs())
            player:AddKeys(p.k-player:GetNumKeys())
            for i,s in ipairs(pdata.souls) do
                if s.Entity:GetData().Index == data.Index and pdata.soulcontrolled ~= i then
                    table.remove(pdata.souls, i)
                    if pdata.soulcontrolled and pdata.soulcontrolled > i then pdata.soulcontrolled = pdata.soulcontrolled-1 end
                end
            end
            if pdata.soulcontrolled and pdata.souls[pdata.soulcontrolled].Entity:GetData().LifeSpan == soulmaxlifespan then
                if #pdata.souls == 1 then
                    player:SetMinDamageCooldown(60)
                    player.Position = pdata.soulstartposition
                    for i=0, 12 do
                        player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/revelcommon/costumes/character_charon.png")
                    end
                    player:GetSprite():LoadGraphics()
                    pdata.souls[pdata.soulcontrolled].Entity:Remove()
                    pdata.souls = {}
                    pdata.soulcontrolled = nil
                    pdata.phylactery:GetSprite():Play("Reignite", true)
                else
                    for i,s in ipairs(pdata.souls) do
                        s.Entity:GetData().Index = i
                        if s.Entity:GetData().LifeSpan < soulmaxlifespan then
                            pdata.souls[pdata.soulcontrolled].Entity:GetData().LifeSpan = s.Entity:GetData().LifeSpan
                            s.Entity:GetSprite():Play("Death")
                            s.Entity:GetSprite().PlaybackSpeed = 1
                            table.remove(pdata.souls, i)
                            if pdata.soulcontrolled > i then pdata.soulcontrolled = pdata.soulcontrolled-1 end
                        end
                    end
                    player.CanFly = true
                end
            end
            return
        end
        if soul.FrameCount ~= 0 and soul.FrameCount ~= 1 then
            soul:GetSprite().PlaybackSpeed = 0.5+(soul.Velocity:Length()/12)
        end
        soul:GetSprite().Scale = data.Size
        -- Targeting
        if not REVEL.room:IsClear() then
            data.Target = REVEL.getClosestEnemy(soul, false, true, true, true)
            if data.Target then
                data.State = "fighting"
                soul:GetData().LifeSpan = soul:GetData().LifeSpan+1
            else data.State = "donothing" end
        end
        if pdata.soulcontrolled == data.Index then
            soul:GetSprite().Color = REVEL.NO_COLOR
            if data.HairSprite then data.HairSprite.Color = REVEL.NO_COLOR end
            data.State = "donothing"
            soul.Position = data.player.Position
            soul.Velocity = data.player.Velocity
        else
            soul:GetSprite().Color = Color(1,1,1,0.5,conv255ToFloat(0,0,0))
            if data.HairSprite then data.HairSprite.Color = Color(1,1,1,0.9,conv255ToFloat(0,0,0)) end
        end
        -- Movement
        soul.Velocity = Vector(0,0)
        if data.State == "fighting" then
            for _,othersoul in ipairs(pdata.souls) do
                if soul.Index ~= othersoul.Index and (othersoul.Entity.Position-soul.Position):Length() <= 40 then
                    soul.Velocity = soul.Velocity+(soul.Position-othersoul.Entity.Position):Resized(data.Speed*2)
                end
            end
            local PredictedTargetPos = data.Target.Position+(data.Target.Velocity*((soul.Position-data.Target.Position):Length()/40))
            if (soul.Position-data.Target.Position):Length() <= 60 then
                soul.Velocity = soul.Velocity+(soul.Position-data.Target.Position):Resized(data.Speed*2)
            elseif (soul.Position-data.Target.Position):Length() >= 120 then
                soul.Velocity = soul.Velocity+(data.Target.Position-soul.Position):Resized(data.Speed*2)
            elseif math.abs(soul.Position.X-PredictedTargetPos.X) > data.Speed/2 and math.abs(soul.Position.Y-PredictedTargetPos.Y) > data.Speed/2 then
                if math.abs(soul.Position.X-PredictedTargetPos.X) < math.abs(soul.Position.Y-PredictedTargetPos.Y) then
                    if soul.Position.X-PredictedTargetPos.X < 0 then soul.Velocity = soul.Velocity+Vector(data.Speed,0)
                    else soul.Velocity = soul.Velocity+Vector(-data.Speed,0) end
                else
                    if soul.Position.Y-PredictedTargetPos.Y < 0 then soul.Velocity = soul.Velocity+Vector(0,data.Speed)
                    else soul.Velocity = soul.Velocity+Vector(0,-data.Speed) end
                end
            end
            soul.Velocity = soul.Velocity+(soul.Velocity-REVEL.room:GetCenterPos()):Resized(data.Speed/2)+Vector(math.random()-0.5,math.random()-0.5)
        end
        if soul.Velocity.X ~= 0 and soul.Velocity.Y ~= 0 then
            if math.abs(soul.Velocity.X) > math.abs(soul.Velocity.Y) then
                if soul.Velocity.X < 0 and not soul:GetSprite():IsPlaying("WalkLeft") then
                    soul:GetSprite():Play("WalkLeft", true)
                elseif soul.Velocity.X > 0 and not soul:GetSprite():IsPlaying("WalkRight") then
                    soul:GetSprite():Play("WalkRight", true)
                end
            else
                if soul.Velocity.Y < 0 and not soul:GetSprite():IsPlaying("WalkUp") then
                    soul:GetSprite():Play("WalkUp", true)
                elseif soul.Velocity.Y > 0 and not soul:GetSprite():IsPlaying("WalkDown") then
                    soul:GetSprite():Play("WalkDown", true)
                end
            end
        elseif not soul:GetSprite():IsPlaying("WalkDown") then
            soul:GetSprite():Play("WalkDown", true)
        end
        soul.Velocity = soul.Velocity+((data.PrevVel-soul.Velocity)*0.9)
        if soul.Velocity:Length() > data.Speed then soul.Velocity = soul.Velocity:Resized(data.Speed) end
        soul:GetData().PrevVel = soul.Velocity
        if data.FireDelay <= data.MaxFireDelay then data.FireDelay = data.FireDelay-1 end
        -- Shooting
        if data.State == "fighting" then
            local TearDir = 0
            local LaserDir = 0
            local tearvariant = TearVariant.BLUE
            local charging = data.WeaponType[WeaponType.WEAPON_BRIMSTONE] or data.Charging
            if data.WeaponType[WeaponType.WEAPON_KNIFE] or data.WeaponType[WeaponType.WEAPON_BOMBS] then charging = false end
            data.FireDelay = data.FireDelay-1
            if math.abs(soul.Position.X-data.Target.Position.X) > math.abs(soul.Position.Y-data.Target.Position.Y) then
                if soul.Position.X-data.Target.Position.X < 0 then
                    TearDir = (Vector(data.ShotSpeed,0)):GetAngleDegrees()+90
                    LaserDir = 0
                    if charging then
                        if data.FireDelay > data.MaxFireDelay+29 then soul:GetSprite():SetOverlayFrame("HeadRightCharge", 20)
                        elseif data.FireDelay <= data.MaxFireDelay then soul:GetSprite():SetOverlayFrame("HeadRightCharge", math.floor(math.abs(data.FireDelay-data.MaxFireDelay)/(data.MaxFireDelay/18))) end
                    else
                        if data.FireDelay <= 1 then soul:GetSprite():SetOverlayFrame("HeadRight", 2)
                        else soul:GetSprite():SetOverlayFrame("HeadRight", 0) end
                    end
                else
                    TearDir = (Vector(-data.ShotSpeed,0)):GetAngleDegrees()+90
                    LaserDir = 180
                    if charging then
                        if data.FireDelay > data.MaxFireDelay+29 then soul:GetSprite():SetOverlayFrame("HeadLeftCharge", 20)
                        elseif data.FireDelay <= data.MaxFireDelay then soul:GetSprite():SetOverlayFrame("HeadLeftCharge", math.floor(math.abs(data.FireDelay-data.MaxFireDelay)/(data.MaxFireDelay/18))) end
                    else
                        if data.FireDelay <= 1 then soul:GetSprite():SetOverlayFrame("HeadLeft", 2)
                        else soul:GetSprite():SetOverlayFrame("HeadLeft", 0) end
                    end
                end
            else
                if soul.Position.Y-data.Target.Position.Y < 0 then
                    TearDir = (Vector(0,data.ShotSpeed)):GetAngleDegrees()-90
                    LaserDir = 90
                    if charging then
                        if data.FireDelay > data.MaxFireDelay+29 then soul:GetSprite():SetOverlayFrame("HeadDownCharge", 20)
                        elseif data.FireDelay <= data.MaxFireDelay then soul:GetSprite():SetOverlayFrame("HeadDownCharge", math.floor(math.abs(data.FireDelay-data.MaxFireDelay)/(data.MaxFireDelay/18))) end
                    else
                        if data.FireDelay <= 1 then soul:GetSprite():SetOverlayFrame("HeadDown", 2)
                        else soul:GetSprite():SetOverlayFrame("HeadDown", 0) end
                    end
                else
                    TearDir = (Vector(0,-data.ShotSpeed)):GetAngleDegrees()-90
                    LaserDir = 270
                    if charging then
                        if data.FireDelay > data.MaxFireDelay+29 then soul:GetSprite():SetOverlayFrame("HeadUpCharge", 20)
                        elseif data.FireDelay <= data.MaxFireDelay then soul:GetSprite():SetOverlayFrame("HeadUpCharge", math.floor(math.abs(data.FireDelay-data.MaxFireDelay)/(data.MaxFireDelay/18))) end
                    else
                        if data.FireDelay <= 1 then soul:GetSprite():SetOverlayFrame("HeadUp", 2)
                        else soul:GetSprite():SetOverlayFrame("HeadUp", 0) end
                    end
                end
            end
            if data.FireDelay <= 0 then
                data.FireDelay = data.MaxFireDelay
                local soulpos = soul.Position+soul:GetSprite().Offset
                for i=0, data.AmountTears-1 do
                    -- bombs
                    if data.WeaponType[WeaponType.WEAPON_BOMBS] then
                        local bomb = Isaac.Spawn(EntityType.ENTITY_BOMBDROP, data.BombVariant, 0, soul.Position, Vector(math.sin(math.rad(TearDir+(i*8-(data.AmountTears-1*4))))*data.ShotSpeed,math.cos(math.rad(TearDir+(i*8-(data.AmountTears-1*4))))*data.ShotSpeed)+(soul.Velocity*0.25), soul)
                    -- knife
                    elseif data.WeaponType[WeaponType.WEAPON_KNIFE] then
                        local KnifeDir = TearDir
                        if KnifeDir%180 == 0 then KnifeDir = KnifeDir+90
                        else KnifeDir = KnifeDir-90 end
                        local knf = REVEL.FireReturningKnife(soulpos+Vector(math.sin(math.rad(TearDir))*20,math.cos(math.rad(TearDir))*20), 30, KnifeDir, 200, soul, soul:GetData().Damage)
                        knf:GetSprite().Color = data.TearColor
                        soul:GetData().Knife = knf
                        data.FireDelay = data.MaxFireDelay+30
                    -- brimstone
                    elseif data.WeaponType[WeaponType.WEAPON_BRIMSTONE] then
                        local distance = 20
                        if TearDir == (Vector(0,data.ShotSpeed)):GetAngleDegrees()-90 then distance = 2 end
                        local laser = EntityLaser.ShootAngle(1, soulpos+Vector(math.sin(math.rad(TearDir))*distance,math.cos(math.rad(TearDir))*distance)+Vector(0,-22), LaserDir, 30, Vector(0,0), soul)
                        laser:GetSprite().Color = data.LaserColor
                        laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
                        laser.CollisionDamage = data.Damage/3
                        laser.SpawnerType = REVEL.ENT.SOUL.id
                        laser:ToLaser().TearFlags = data.TearFlags
                        if data.ShortLaser then laser:ToLaser().MaxDistance = 120 end
                        data.FireDelay = data.MaxFireDelay+30
                    -- lasers
                    elseif data.WeaponType[WeaponType.WEAPON_LASER] then
                        local distance = 20
                        if TearDir == (Vector(0,data.ShotSpeed)):GetAngleDegrees()-90 then distance = 2 end
                        local laser = EntityLaser.ShootAngle(2, soulpos+Vector(math.sin(math.rad(TearDir))*distance,math.cos(math.rad(TearDir))*distance)+Vector(0,-22), LaserDir, 30, Vector(0,0), soul)
                        laser:GetSprite().Color = data.LaserColor
                        laser.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
                        laser.CollisionDamage = data.Damage
                        laser.SpawnerType = REVEL.ENT.SOUL.id
                        laser:ToLaser().TearFlags = data.TearFlags
                        laser:ToLaser().OneHit = true
                        laser:ToLaser().Timeout = 1
                    -- tears
                    elseif data.WeaponType[WeaponType.WEAPON_TEARS] then
                        data.EyeSide = data.EyeSide*-1
                        local t = Isaac.Spawn(EntityType.ENTITY_TEAR, tearvariant, 0, soulpos+Vector(math.sin(math.rad(TearDir+data.EyeSide))*6,math.cos(math.rad(TearDir+data.EyeSide))*6), Vector(math.sin(math.rad(TearDir+((i-((data.AmountTears-1)*0.5))*16)))*data.ShotSpeed,math.cos(math.rad(TearDir+((i-((data.AmountTears-1)*0.5))*16)))*data.ShotSpeed)+(soul.Velocity*0.25), soul)
                        t.CollisionDamage = data.Damage
                        t:ToTear().TearFlags = data.TearFlags
                        t:ToTear().Height = - soul:GetData().TearRange * 17.5 / 260
                        t:ToTear().FallingSpeed = soul:GetData().Range
                        t:GetSprite().Color = data.TearColor
                        t:GetSprite().Scale = Vector(math.sqrt(data.Damage/1.75),math.sqrt(data.Damage/1.75))
                    end
                end
            end
        elseif data.State == "donothing" then
            data.FireDelay = data.MaxFireDelay
            soul:GetSprite():SetOverlayFrame("HeadDown", 0)
        end
        if data.HairSprite and data.FireDelay <= data.MaxFireDelay then
            if soul:GetSprite():IsOverlayFinished("HeadDown") then data.HairSprite:SetFrame("HeadDown", soul:GetSprite():GetOverlayFrame())
            elseif soul:GetSprite():IsOverlayFinished("HeadLeft") then data.HairSprite:SetFrame("HeadLeft", soul:GetSprite():GetOverlayFrame())
            elseif soul:GetSprite():IsOverlayFinished("HeadUp") then data.HairSprite:SetFrame("HeadUp", soul:GetSprite():GetOverlayFrame())
            elseif soul:GetSprite():IsOverlayFinished("HeadRight") then data.HairSprite:SetFrame("HeadRight", soul:GetSprite():GetOverlayFrame())
            elseif soul:GetSprite():IsOverlayFinished("HeadDownCharge") then data.HairSprite:SetFrame("HeadDown", 0)
            elseif soul:GetSprite():IsOverlayFinished("HeadLeftCharge") then data.HairSprite:SetFrame("HeadLeft", 0)
            elseif soul:GetSprite():IsOverlayFinished("HeadUpCharge") then data.HairSprite:SetFrame("HeadUp", 0)
            elseif soul:GetSprite():IsOverlayFinished("HeadRightCharge") then data.HairSprite:SetFrame("HeadRight", 0) end
        end
    end
end

function revel:renderSouls(soul, renderOffset)
    if not soul.Variant == REVEL.ENT.SOUL.variant then return end

    local sprite, data = soul:GetSprite(), soul:GetData()
    if data.HairSprite and not IsAnimOn(sprite, "Death") then
        local pos = Isaac.WorldToScreen(soul.Position + data.HairOffset) + sprite.Offset
        if REVEL.IsRenderPassReflection() then
            pos = pos + Vector(0, 8)
        end
        data.HairSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset())
    end
    if soul.Variant == REVEL.ENT.SOUL.variant 
    and data.WeaponType[WeaponType.WEAPON_KNIFE] 
    and not data.WeaponType[WeaponType.WEAPON_BOMBS] 
    and (not data.Knife or not data.Knife:Exists()) 
    and data.player:GetData().soulcontrolled ~= data.Index then
        if sprite:IsOverlayFinished("HeadRight") then 
            data.KnifeSprite.Rotation = 270
        elseif sprite:IsOverlayFinished("HeadUp") then 
            data.KnifeSprite.Rotation = 180
        elseif sprite:IsOverlayFinished("HeadLeft") then 
            data.KnifeSprite.Rotation = 90
        elseif sprite:IsOverlayFinished("HeadDown") then 
            data.KnifeSprite.Rotation = 0 
        end
        local wpos = soul.Position + Vector(
            math.sin(math.rad(data.KnifeSprite.Rotation * -1)) * 20,
            math.cos(math.rad(data.KnifeSprite.Rotation * -1)) * 20
        )
        local pos = Isaac.WorldToScreen(wpos) + sprite.Offset
        data.KnifeSprite:Render(pos + renderOffset - REVEL.room:GetRenderScrollOffset())
    end
end

function revel:roomEnter()
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        if data.soulcontrolled then
            player.CanFly = false
            for i,soul in ipairs(data.souls) do
                if i ~= data.soulcontrolled then
                    for _,item in ipairs(soul.Items) do
                        if not soulDisabledItems[item] then
                            player:AddCollectible(item, 0, false)
                        end
                    end
                end
            end
            for i=0, 12 do
                player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/revelcommon/costumes/character_charon.png")
            end
            player:GetSprite():LoadGraphics()
            data.phylactery:ToFamiliar():RemoveFromFollowers()
            data.phylactery:ToFamiliar():AddToFollowers()
        end
        data.soulcontrolled = nil
        data.souls = {}
        if not data.soulitemwasused then data.soulitemwasused = 0 end
    end
end

function revel:TakeDamage(player, dmg, flag, src, invuln)
    if player.Type == EntityType.ENTITY_PLAYER then
        local data = player:GetData()
        if src and src.Type == REVEL.ENT.SOUL.id or data.phylacterytarget then
            return false
        end
    end
end

revel:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if player:GetData().soulcontrolled then
        if flag == CacheFlag.CACHE_TEARFLAG then
            player.TearFlags = player.TearFlags | TearFlags.TEAR_SPECTRAL
        elseif flag == CacheFlag.CACHE_FLYING then
            player.CanFly = true
        elseif flag == CacheFlag.CACHE_TEARCOLOR then
            player.TearColor = Color(1,1,1,1,conv255ToFloat(30,30,30))
        end
    end
end)

function revel:GameStart(savestate)
    for _,player in ipairs(REVEL.players) do
        local data = player:GetData()
        if not savestate then
            data.phylactery = nil
        end
        if not data.souls then data.souls = {} end
    end
end

revel:AddCallback(ModCallbacks.MC_NPC_UPDATE, revel.updateSouls, REVEL.ENT.SOUL.id)
revel:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, revel.renderSouls, REVEL.ENT.SOUL.id)
StageAPI.AddCallback("Revelations", RevCallbacks.EARLY_POST_NEW_ROOM, 1, revel.roomEnter)
--revel:AddCallback(ModCallbacks.MC_POST_RENDER, revel.renderPhylactery)
--revel:AddCallback(ModCallbacks.MC_POST_UPDATE, revel.updatePhylactery)
revel:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, revel.TakeDamage)
revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, revel.GameStart)
revel:AddCallback(ModCallbacks.MC_POST_UPDATE, revel.SpawnSouls)

end

REVEL.PcallWorkaroundBreakFunction()