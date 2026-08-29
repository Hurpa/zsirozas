extends Control
## A játékasztal View rétege. Felépíti a UI elemeket, létrehozza a
## Controllert, és a Controller signaljai alapján frissíti a kijelzőt.
## A View sosem nyúl közvetlenül a Modelhez - csak a Controller
## metódusait hívja (try_play_card, decide_continue), és a Controller
## signaljait hallgatja.

var controller: GameController
var top_hand: HandView
var bottom_hand: HandView
var trick_area: TrickAreaView
var score_panel: ScorePanel
var menu_btn: Button
var handoff_overlay: HandoffOverlay
var continue_prompt: ContinuePrompt
var quit_confirm: ConfirmDialogView

## Melyik játékos lapjai vannak éppen felfedve a képernyőn.
var last_revealed_index: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_resized)

	controller = GameController.new()
	add_child(controller)
	controller.hand_changed.connect(_on_hand_changed)
	controller.card_played.connect(_on_card_played)
	controller.trick_ended.connect(_on_trick_ended)
	controller.talon_changed.connect(_on_talon_changed)
	controller.scores_changed.connect(_on_scores_changed)
	controller.turn_changed.connect(_on_turn_changed)
	controller.game_over.connect(_on_game_over)

	# A VBoxContainer csak a következő képkockán számolja ki véglegesen a
	# kéz-sorok/asztal tényleges méretét. Ha rögtön itt indítanánk a
	# játékot, a legelső lapkirakás még a (nulla) kezdeti méretekkel
	# számolna. Egy frame várakozással ezt elkerüljük.
	await get_tree().process_frame
	controller.start_new_game()

func _build_ui() -> void:
	add_child(UiTheme.build_background())

	# A kéz-sorok és az asztal középső területe egy VBoxContainer-ben van,
	# ami a teljes képernyőt kitölti (anchors_preset FULL_RECT), és a
	# gyerekeit a "size_flags_stretch_ratio" arányában osztja el. Ez a
	# konténer MINDEN átméretezésnél (pl. telefon elforgatásakor) saját
	# maga, automatikusan újraszámolja a gyerekei méretét/pozícióját -
	# nekünk csak azt kell kézzel újraszámolnunk, amit MI rajzolunk a
	# kéz-sorokon/asztalon belülre (lásd _on_viewport_resized).
	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)

	top_hand = HandView.new()
	top_hand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_hand.size_flags_stretch_ratio = 1.0
	top_hand.custom_minimum_size = Vector2(0, 90)
	layout.add_child(top_hand)

	trick_area = TrickAreaView.new()
	trick_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trick_area.size_flags_stretch_ratio = 1.7
	trick_area.custom_minimum_size = Vector2(0, 140)
	layout.add_child(trick_area)

	bottom_hand = HandView.new()
	bottom_hand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_hand.size_flags_stretch_ratio = 1.3
	bottom_hand.custom_minimum_size = Vector2(0, 110)
	layout.add_child(bottom_hand)

	# A pontszám-panel és a Főmenü gomb a bal-felső / jobb-felső sarokban
	# lebeg, a fenti elrendezéstől függetlenül (nem foglal helyet belőle) -
	# a pozíciójukat _layout_corner_widgets() számolja ki a TÉNYLEGES
	# képernyőmérethez igazítva, átméretezéskor is.
	score_panel = ScorePanel.new()
	add_child(score_panel)

	menu_btn = Button.new()
	menu_btn.text = "Főmenü"
	menu_btn.custom_minimum_size = UiScale.button_size(Vector2(120, 44))
	menu_btn.size = menu_btn.custom_minimum_size
	menu_btn.pressed.connect(func(): quit_confirm.show_with_message(
		"Biztosan visszalépsz a főmenübe?\nA folyamatban lévő játék elvész."
	))
	UiTheme.add_press_feedback(menu_btn)
	add_child(menu_btn)

	handoff_overlay = HandoffOverlay.new()
	handoff_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(handoff_overlay)
	handoff_overlay.revealed.connect(_on_handoff_revealed)

	continue_prompt = ContinuePrompt.new()
	continue_prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(continue_prompt)
	continue_prompt.answered.connect(_on_continue_answered)

	quit_confirm = ConfirmDialogView.new()
	quit_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(quit_confirm)
	quit_confirm.answered.connect(_on_quit_confirm_answered)

	_layout_corner_widgets()

## A sarokban lebegő elemek (pontszám, Főmenü gomb) pozícióját a TÉNYLEGES
## képernyőmérethez igazítja - ezt kell hívni induláskor és minden
## átméretezés/elforgatás után is.
func _layout_corner_widgets() -> void:
	var margin := 16.0
	score_panel.position = Vector2(margin, margin)
	var vp_width: float = get_viewport_rect().size.x
	menu_btn.position = Vector2(vp_width - menu_btn.size.x - margin, margin)

## Képernyő-átméretezéskor (pl. telefon elforgatásakor) hívódik. A
## VBoxContainer-es fő elrendezés automatikusan újraszámolja magát, de a
## kéz-sorokon/asztalon BELÜLI, kézzel pozicionált lapokat nekünk kell
## újrarajzolni az új méretekhez.
func _on_viewport_resized() -> void:
	_layout_corner_widgets()
	trick_area.refresh_layout()
	if last_revealed_index != -1:
		_refresh_display()

## Frissíti a képernyőt a "last_revealed_index" alapján: az ő lapjai
## látszanak nyitva lent, az ellenfélé hátlappal fent.
func _refresh_display() -> void:
	if last_revealed_index == -1:
		return
	var shown_idx := last_revealed_index
	var hidden_idx := controller.model.opponent_index(shown_idx)
	var phase: int = controller.model.phase
	var is_players_turn: bool = controller.model.active_player_index == shown_idx
	var interactive: bool = is_players_turn and (phase == GameModel.Phase.LEAD or phase == GameModel.Phase.FOLLOW)

	bottom_hand.render(
		controller.model.players[shown_idx].hand,
		true, interactive, trick_area, self, _on_card_dropped
	)
	top_hand.render_backs(controller.model.players[hidden_idx].hand.size())

func _on_card_dropped(card_view: CardView, _target: Control) -> void:
	var idx: int = controller.model.active_player_index
	var ok: bool = controller.try_play_card(idx, card_view.card_data)
	if ok:
		card_view.queue_free()
	else:
		card_view.return_to_home()

func _on_hand_changed(_player_index: int) -> void:
	if controller.model.phase == GameModel.Phase.GAME_OVER:
		return
	_refresh_display()

func _on_card_played(player_index: int, card: CardData, _is_continuation: bool) -> void:
	trick_area.add_played_card(card, player_index)

func _on_trick_ended(_winner_index: int, _cards) -> void:
	trick_area.clear_trick()

func _on_talon_changed(count: int) -> void:
	score_panel.update_talon(count)

func _on_scores_changed() -> void:
	var p0: PlayerModel = controller.model.players[0]
	var p1: PlayerModel = controller.model.players[1]
	score_panel.update_scores(p0.score(), p1.score())

func _on_turn_changed(player_index: int, phase: int) -> void:
	if phase == GameModel.Phase.GAME_OVER:
		return
	if player_index != last_revealed_index:
		continue_prompt.hide_prompt()
		handoff_overlay.show_for_player(controller.model.players[player_index].display_name)
	else:
		_activate_current_phase()

func _activate_current_phase() -> void:
	var phase: int = controller.model.phase
	if phase == GameModel.Phase.CONTINUE_DECISION:
		_refresh_display()
		continue_prompt.show_prompt()
	else:
		continue_prompt.hide_prompt()
		_refresh_display()

func _on_handoff_revealed() -> void:
	handoff_overlay.hide_overlay()
	last_revealed_index = controller.model.active_player_index
	_activate_current_phase()

func _on_continue_answered(wants_continue: bool) -> void:
	continue_prompt.hide_prompt()
	controller.decide_continue(controller.model.active_player_index, wants_continue)

func _on_game_over(result: Dictionary) -> void:
	SceneManager.go_to_result(result)

func _on_quit_confirm_answered(confirmed: bool) -> void:
	quit_confirm.hide_dialog()
	if confirmed:
		SceneManager.go_to_main_menu()
