return function()


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


end