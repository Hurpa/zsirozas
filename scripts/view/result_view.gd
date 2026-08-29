extends Control
## Eredményképernyő: ki nyerte a leosztást, végeredmény, kopasz/csupasz jelzés.
## A tartalom egy CenterContainer-ben van, ami dinamikusan, a képernyő
## méretétől függetlenül is ténylegesen középre igazít.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()

	add_child(UiTheme.build_background())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var result: Dictionary = SceneManager.last_result
	var scores: Array = result.get("scores", [0, 0])
	var winner_index: int = result.get("winner_index", -1)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UiTheme.COLOR_GOLD)
	title.add_theme_font_size_override("font_size", UiScale.font_size(42))
	if winner_index == -1:
		title.text = "Döntetlen!"
	else:
		title.text = "%d. Játékos nyert!" % (winner_index + 1)
	vbox.add_child(title)

	var score_label := Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	score_label.custom_minimum_size = Vector2(280, 0)
	score_label.text = "Végeredmény: 1. Játékos %d - %d 2. Játékos" % [scores[0], scores[1]]
	vbox.add_child(score_label)

	if result.get("csupasz", false):
		var note := Label.new()
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.custom_minimum_size = Vector2(280, 0)
		note.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_MUTED)
		note.text = "Csupasz győzelem - minden lapot a győztes vitt el!"
		vbox.add_child(note)
	elif result.get("kopasz", false):
		var note2 := Label.new()
		note2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note2.autowrap_mode = TextServer.AUTOWRAP_WORD
		note2.custom_minimum_size = Vector2(280, 0)
		note2.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_MUTED)
		note2.text = "Kopasz győzelem - a vesztes egy zsírt sem vitt, de lapot igen."
		vbox.add_child(note2)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	vbox.add_child(spacer)

	var again_btn := Button.new()
	again_btn.text = "Új játék"
	again_btn.custom_minimum_size = UiScale.button_size(Vector2(240, 54))
	again_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again_btn.pressed.connect(func(): SceneManager.go_to_game())
	UiTheme.mark_primary(again_btn)
	UiTheme.add_press_feedback(again_btn)
	vbox.add_child(again_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Főmenü"
	menu_btn.custom_minimum_size = UiScale.button_size(Vector2(240, 54))
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func(): SceneManager.go_to_main_menu())
	UiTheme.add_press_feedback(menu_btn)
	vbox.add_child(menu_btn)
