local RevCallbacks = require "scripts.revelations.common.enums.RevCallbacks"

return function()

-- Cards

local TarotCards = {
    Card.CARD_FOOL,
    Card.CARD_MAGICIAN,
    Card.CARD_HIGH_PRIESTESS,
    Card.CARD_EMPRESS,
    Card.CARD_EMPEROR,
    Card.CARD_HIEROPHANT,
    Card.CARD_LOVERS,
    Card.CARD_CHARIOT,
    Card.CARD_JUSTICE,
    Card.CARD_HERMIT,
    Card.CARD_WHEEL_OF_FORTUNE,
    Card.CARD_STRENGTH,
    Card.CARD_HANGED_MAN,
    Card.CARD_DEATH,
    Card.CARD_TEMPERANCE,
    Card.CARD_DEVIL,
    Card.CARD_TOWER,
    Card.CARD_STARS,
    Card.CARD_MOON,
    Card.CARD_SUN,
    Card.CARD_JUDGEMENT,
    Card.CARD_WORLD
}
local TarotCardsPowerful = {
    Card.CARD_EMPRESS,
    Card.CARD_HIEROPHANT,
    Card.CARD_CHARIOT,
    Card.CARD_STRENGTH,
    Card.CARD_DEATH,
    Card.CARD_SUN
}
local PlayingCards = {
    Card.CARD_CLUBS_2,
    Card.CARD_DIAMONDS_2,
    Card.CARD_SPADES_2,
    Card.CARD_HEARTS_2,
    Card.CARD_ACE_OF_CLUBS,
    Card.CARD_ACE_OF_DIAMONDS,
    Card.CARD_ACE_OF_SPADES,
    Card.CARD_ACE_OF_HEARTS,
    Card.CARD_JOKER,
    Card.CARD_RULES,
    Card.CARD_SUICIDE_KING
}
local PlayingCardsNotUnique = {
    Card.CARD_CLUBS_2,
    Card.CARD_DIAMONDS_2,
    Card.CARD_SPADES_2,
    Card.CARD_HEARTS_2,
    Card.CARD_ACE_OF_CLUBS,
    Card.CARD_ACE_OF_DIAMONDS,
    Card.CARD_ACE_OF_SPADES,
    Card.CARD_ACE_OF_HEARTS
}

function REVEL.GetRandomTarotCard(discouragePowerful)
    local card = TarotCards[math.random(#TarotCards)]
    if discouragePowerful and REVEL.includes(TarotCardsPowerful, card) then
        card = TarotCards[math.random(#TarotCards)] --roll again if we got a powerful card, makes them less likely to appear
    end
    return card
end

function REVEL.GetRandomPlayingCard(notUnique)
    if notUnique then
        return PlayingCardsNotUnique[math.random(#PlayingCardsNotUnique)]
    else
        return PlayingCards[math.random(#PlayingCards)]
    end
end

-- Pills


--using numbers cause I can't be bothered to do all that copypasting, 
-- you can check enums for what they are (I'm going to regret this aren't I)
local GoodEffects =    {2,  7, 12, 14, 16, 18,  5, 23, 20, 10, 24, 26, 41, 28, 34, 35, 36, 38, 43, 45, 46, 48}
local NeutralEffects = {0,  3,  4,  8,  9, 19, 21, 30, 32, 33, 39, 40, 44, 49}
local BadEffects =     {1,  6, 11, 13, 15, 17, 22, 25, 27, 29, 31, 37, 42, 47}

local GoodPills = {}
local NeutralPills = {}
local BadPills = {}

function REVEL.GetRandomGoodPill()
    return GoodPills[math.random(#GoodPills)]
end

function REVEL.GetRandomBadPill()
    return BadPills[math.random(#BadPills)]
end

function REVEL.GetRandomNeutralPill()
    return NeutralPills[math.random(#NeutralPills)]
end

--higher good Weight: higher chance for it to be good, 1 = normal weight, can use non int values too
function REVEL.GetRandomNonBadPill(goodWeigth)
    goodWeigth = goodWeigth or 1
    local tot = #NeutralPills + #GoodPills * goodWeigth
    local good = math.random() < #GoodPills * goodWeigth / tot --chance its a good pill, with equal weight it is (taking the total number of good/neutral effects into account) the same as the chance of getting a given neutral pill
    if good then
        return REVEL.randomFrom(GoodPills)
    else
        return REVEL.randomFrom(NeutralPills)
    end
end

local function listPills()
    local pool = REVEL.game:GetItemPool()

    GoodPills = {}
    NeutralPills = {}
    BadPills = {}

    for i=1, PillColor.NUM_PILLS-2 do
        local eff = pool:GetPillEffect(i)
        if REVEL.includes(GoodEffects, eff) then table.insert(GoodPills, i)
        elseif REVEL.includes(NeutralEffects, eff) then table.insert(NeutralPills, i)
        elseif REVEL.includes(BadEffects, eff) then table.insert(BadPills, i) end
    end
end

revel:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, listPills)
StageAPI.AddCallback("Revelations", RevCallbacks.POST_INGAME_RELOAD, 1, listPills)

end