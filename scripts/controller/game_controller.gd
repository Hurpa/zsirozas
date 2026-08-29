class_name GameController
extends Node
## A Zsírozás játékmenetének vezérlője. A GameModel-t módosítja a
## pagat.com-i szabályok szerint, és signalokkal értesíti a View réteget
## a történtekről. A View sosem módosítja közvetlenül a Modelt - mindig
## a Controller publikus metódusain (try_play_card, decide_continue) keresztül.

signal hand_changed(player_index: int)
signal card_played(player_index: int, card: CardData, is_continuation: bool)
signal trick_ended(winner_index: int, collected_cards: Array)
signal talon_changed(count: int)
signal scores_changed
signal turn_changed(player_index: int, phase: int)
signal game_over(result: Dictionary)

var model: GameModel
var _last_trick_winner_index: int = -1

func start_new_game() -> void:
	model = GameModel.new()
	var starting_dealer := randi() % 2
	model.setup_new_hand(starting_dealer)
	_last_trick_winner_index = -1
	hand_changed.emit(0)
	hand_changed.emit(1)
	talon_changed.emit(model.deck.count())
	scores_changed.emit()
	turn_changed.emit(model.active_player_index, model.phase)

## Megpróbál lapot játszani. Visszaadja, hogy sikerült-e (szabályos volt-e).
func try_play_card(player_index: int, card: CardData) -> bool:
	if model == null or model.phase == GameModel.Phase.GAME_OVER:
		return false
	if player_index != model.active_player_index:
		return false
	var player: PlayerModel = model.players[player_index]
	if not player.has_card(card):
		return false

	match model.phase:
		GameModel.Phase.LEAD:
			return _play_lead(player, card)
		GameModel.Phase.FOLLOW:
			return _play_follow(player, card)
		_:
			return false

## A vezető dönt: folytatja-e a több körös ütést, vagy elengedi.
func decide_continue(leader_index: int, wants_continue: bool) -> void:
	if model.phase != GameModel.Phase.CONTINUE_DECISION:
		return
	if leader_index != model.trick.leader_index:
		return
	if not wants_continue:
		var winner_index := model.trick.current_winner_index()
		_end_trick(winner_index)
		return
	model.active_player_index = leader_index
	model.phase = GameModel.Phase.LEAD
	turn_changed.emit(leader_index, model.phase)

func _play_lead(player: PlayerModel, card: CardData) -> bool:
	var is_continuation := model.trick.is_active
	if is_continuation:
		if not card.matches_rank(model.trick.original_rank):
			return false
		player.remove_card(card)
		model.trick.add_play(player.index, card)
	else:
		player.remove_card(card)
		model.trick.start(player.index, card)

	card_played.emit(player.index, card, is_continuation)
	hand_changed.emit(player.index)

	var follower_index := model.opponent_index(player.index)
	model.active_player_index = follower_index
	model.phase = GameModel.Phase.FOLLOW
	turn_changed.emit(follower_index, model.phase)
	return true

func _play_follow(player: PlayerModel, card: CardData) -> bool:
	player.remove_card(card)
	model.trick.add_play(player.index, card)
	card_played.emit(player.index, card, false)
	hand_changed.emit(player.index)

	_resolve_round()
	return true

func _resolve_round() -> void:
	var leader_index := model.trick.leader_index
	var winner_index := model.trick.current_winner_index()

	if winner_index == leader_index:
		# A vezető oldala nyer -> az ütés lezárul, nem folytathatja tovább.
		_end_trick(leader_index)
		return

	var leader: PlayerModel = model.players[leader_index]
	var follower: PlayerModel = model.players[model.opponent_index(leader_index)]
	var can_continue := leader.has_matching_card(model.trick.original_rank)
	var hands_exhausted := leader.hand.is_empty() or follower.hand.is_empty()

	if not can_continue or hands_exhausted:
		_end_trick(winner_index)
		return

	model.active_player_index = leader_index
	model.phase = GameModel.Phase.CONTINUE_DECISION
	turn_changed.emit(leader_index, model.phase)

func _end_trick(winner_index: int) -> void:
	var collected: Array[CardData] = model.trick.all_cards()
	model.players[winner_index].add_captured(collected)
	_last_trick_winner_index = winner_index
	trick_ended.emit(winner_index, collected)
	scores_changed.emit()
	model.trick.reset()
	_draw_phase(winner_index)

func _draw_phase(winner_index: int) -> void:
	model.phase = GameModel.Phase.DRAWING
	var order := [winner_index, model.opponent_index(winner_index)]

	# FONTOS: a szabály szerint a győztessel kezdve KÖRBEN, egyesével
	# húznak, nem pedig úgy, hogy az egyik fél egyszerre felhúzza az összes
	# neki járó lapot (ez utóbbi méltánytalanul kiüríthetné a talont,
	# mielőtt a másik félhez sorra kerülne - pontosan ez okozott korábban
	# egy 4 vs 2 lapos, aránytalan végállást). "When there are insufficient
	# cards left in the talon..., the remaining talon cards are
	# distributed equally to the players." (pagat.com)
	var drew_any := true
	while drew_any and not model.deck.is_empty():
		drew_any = false
		for idx in order:
			if model.deck.is_empty():
				break
			var player: PlayerModel = model.players[idx]
			if player.hand.size() < 4:
				player.hand.append(model.deck.draw_one())
				drew_any = true

	hand_changed.emit(order[0])
	hand_changed.emit(order[1])
	talon_changed.emit(model.deck.count())

	# Mivel egy (több körös) ütésben mindenki mindig ugyanannyi lapot
	# játszik ki, a kezek a talon kiürüléséig mindig pontosan egyenlőek -
	# a fenti, körben-egyesével húzás miatt legfeljebb 1 lap különbség
	# alakulhat ki, ha a talon épp nem elég mindkettőjük feltöltéséhez.
	# Ha a talon már üres, és emiatt valamelyik félnek NINCS több lapja,
	# nem alakulhatna ki szabályos (mindkét fél által játszott) újabb
	# ütés - a leosztás itt véget ér. Ha a másiknál emiatt maradt egy
	# "gazdátlan" lap, azt (mivel nincs kivel ütésre vinni) jóváírjuk neki.
	if model.deck.is_empty() and _any_hand_empty():
		_sweep_remaining_cards()
		_finish_hand()
		return

	model.active_player_index = winner_index
	model.phase = GameModel.Phase.LEAD
	turn_changed.emit(winner_index, model.phase)

func _any_hand_empty() -> bool:
	for p in model.players:
		if p.hand.is_empty():
			return true
	return false

func _sweep_remaining_cards() -> void:
	for p in model.players:
		if not p.hand.is_empty():
			var leftover: Array[CardData] = p.hand.duplicate()
			p.add_captured(leftover)
			p.hand.clear()
			hand_changed.emit(p.index)

func _finish_hand() -> void:
	model.phase = GameModel.Phase.GAME_OVER
	var p0 := model.players[0]
	var p1 := model.players[1]
	var s0 := p0.score()
	var s1 := p1.score()
	var winner_index := -1
	if s0 > s1:
		winner_index = 0
	elif s1 > s0:
		winner_index = 1
	else:
		winner_index = _last_trick_winner_index

	var result := {
		"scores": [s0, s1],
		"winner_index": winner_index,
		"csupasz": p0.captured.size() == 32 or p1.captured.size() == 32,
		"kopasz": (s0 == 80 or s1 == 80) and not (p0.captured.size() == 32 or p1.captured.size() == 32),
	}
	game_over.emit(result)
