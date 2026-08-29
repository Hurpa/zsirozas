class_name TrickState
extends RefCounted
## Az éppen aktív (esetleg több körös / "üsd le!") ütés nyilvántartása.
## A szabály lényege: az nyeri az ütést, aki utoljára tett le a kiadott
## ranggal megegyező (vagy hetes) lapot.

var leader_index: int = -1
var original_rank: CardData.Rank = CardData.Rank.SEVEN
var plays: Array = []  # Array of { "player_index": int, "card": CardData }
var is_active: bool = false

func start(p_leader_index: int, lead_card: CardData) -> void:
	leader_index = p_leader_index
	original_rank = lead_card.rank
	plays.clear()
	plays.append({"player_index": p_leader_index, "card": lead_card})
	is_active = true

func add_play(player_index: int, card: CardData) -> void:
	plays.append({"player_index": player_index, "card": card})

func all_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for p in plays:
		result.append(p["card"])
	return result

## Az utoljára illeszkedő (original_rank-kal megegyező, vagy hetes) lapot
## játszó fél viszi jelenleg az ütést.
func current_winner_index() -> int:
	var winner := leader_index
	for p in plays:
		var card: CardData = p["card"]
		if card.matches_rank(original_rank):
			winner = p["player_index"]
	return winner

func reset() -> void:
	leader_index = -1
	plays.clear()
	is_active = false
