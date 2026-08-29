class_name GameModel
extends RefCounted
## A teljes játékállapot egyetlen, Node-mentes objektumban.
## A Controller ezt módosítja a szabályok szerint, a View csak olvassa
## (a Controller által kibocsátott jelzések - signalok - alapján).

enum Phase {
	DEALING,
	LEAD,               # a vezető játékosnak kell lapot kiadnia
	FOLLOW,              # a másik játékosnak kell válaszolnia
	CONTINUE_DECISION,   # a vezetőnek el kell döntenie: folytatja-e az ütést
	DRAWING,
	GAME_OVER,
}

var players: Array[PlayerModel] = []
var deck: Deck
var trick: TrickState
var phase: Phase = Phase.DEALING
var active_player_index: int = 0
var dealer_index: int = 0

func _init() -> void:
	players = [PlayerModel.new(0, "1. Játékos"), PlayerModel.new(1, "2. Játékos")]
	deck = Deck.new()
	trick = TrickState.new()

func setup_new_hand(p_dealer_index: int) -> void:
	dealer_index = p_dealer_index
	deck.build_full_deck()
	deck.shuffle_deck()
	for p in players:
		p.hand.clear()
		p.captured.clear()
	for p in players:
		for i in range(4):
			p.hand.append(deck.draw_one())
	trick.reset()
	# Az osztó jobb oldali szomszédja (2 fősnél: a másik játékos) kezd.
	active_player_index = 1 - dealer_index
	phase = Phase.LEAD

func opponent_index(p: int) -> int:
	return 1 - p
