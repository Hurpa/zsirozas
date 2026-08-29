class_name Deck
extends RefCounted
## A 32 lapos magyar kártyapakli (talon + a még ki nem osztott lapok
## reprezentációja is ugyanezzel az osztállyal történik).

var cards: Array[CardData] = []

func _init() -> void:
	build_full_deck()

func build_full_deck() -> void:
	cards.clear()
	for suit in CardData.Suit.values():
		for rank in CardData.Rank.values():
			cards.append(CardData.new(suit, rank))

func shuffle_deck() -> void:
	cards.shuffle()

func draw_one() -> CardData:
	if cards.is_empty():
		return null
	return cards.pop_back()

func is_empty() -> bool:
	return cards.is_empty()

func count() -> int:
	return cards.size()
