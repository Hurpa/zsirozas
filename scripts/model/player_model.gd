class_name PlayerModel
extends RefCounted
## Egy játékos állapota: kéz, megszerzett (elvitt) lapok, pontszám.

var index: int
var display_name: String
var hand: Array[CardData] = []
var captured: Array[CardData] = []

func _init(p_index: int, p_name: String) -> void:
	index = p_index
	display_name = p_name

func score() -> int:
	var total := 0
	for c in captured:
		total += c.value()
	return total

func has_card(card: CardData) -> bool:
	return hand.has(card)

func remove_card(card: CardData) -> void:
	hand.erase(card)

func add_captured(cards_to_add: Array[CardData]) -> void:
	for c in cards_to_add:
		captured.append(c)

func has_matching_card(target_rank: CardData.Rank) -> bool:
	for c in hand:
		if c.matches_rank(target_rank):
			return true
	return false
