class_name CardData
extends RefCounted
## Egyetlen kártyalap adatai. Tisztán adat + szabály-logika, semmilyen Node
## függőség nincs benne -> ez a "Model" réteg egyik alapköve.

enum Suit { ACORN, BELL, HEART, LEAF }
enum Rank { SEVEN, EIGHT, NINE, TEN, UNTER, OBER, KING, ACE }

const SUIT_FILE_NAMES := {
	Suit.ACORN: "acorn",
	Suit.BELL: "bell",
	Suit.HEART: "heart",
	Suit.LEAF: "leaf",
}

const RANK_FILE_NAMES := {
	Rank.SEVEN: "seven",
	Rank.EIGHT: "eight",
	Rank.NINE: "nine",
	Rank.TEN: "ten",
	Rank.UNTER: "unter",
	Rank.OBER: "ober",
	Rank.KING: "king",
	Rank.ACE: "ace",
}

const SUIT_NAMES_HU := {
	Suit.ACORN: "Makk",
	Suit.BELL: "Tök",
	Suit.HEART: "Piros",
	Suit.LEAF: "Zöld",
}

const RANK_NAMES_HU := {
	Rank.SEVEN: "Hetes",
	Rank.EIGHT: "Nyolcas",
	Rank.NINE: "Kilences",
	Rank.TEN: "Tízes",
	Rank.UNTER: "Alsó",
	Rank.OBER: "Felső",
	Rank.KING: "Király",
	Rank.ACE: "Ász",
}

var suit: Suit
var rank: Rank

func _init(p_suit: Suit, p_rank: Rank) -> void:
	suit = p_suit
	rank = p_rank

## Zsírozásban a hetes "vad" lap: bármilyen kiadott ranghoz illeszkedik.
## Ha maga a hetes van kiadva, akkor csak hetes illeszkedik rá.
func matches_rank(other_rank: Rank) -> bool:
	if rank == other_rank:
		return true
	if rank == Rank.SEVEN and other_rank != Rank.SEVEN:
		return true
	return false

func is_seven() -> bool:
	return rank == Rank.SEVEN

## "Zsír": ász és tízes 10 pontot ér, minden más lap 0-t.
func value() -> int:
	return 10 if (rank == Rank.ACE or rank == Rank.TEN) else 0

func texture_file_name() -> String:
	return "%s-%s.png" % [SUIT_FILE_NAMES[suit], RANK_FILE_NAMES[rank]]

func to_display_string() -> String:
	return "%s %s" % [SUIT_NAMES_HU[suit], RANK_NAMES_HU[rank]]

func id() -> String:
	return "%s-%s" % [SUIT_FILE_NAMES[suit], RANK_FILE_NAMES[rank]]
