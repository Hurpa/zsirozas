extends Control
## Főmenü: cím + Új játék / Kilépés gombok.
## A tartalom egy CenterContainer-ben van, ami MINDIG ténylegesen középre
## igazít (horizontálisan és vertikálisan is), és ezt a képernyő
## méretének/arányának változásakor is dinamikusan újraszámolja.
## Az egységes, "sötét casino" vizuális stílust a UiTheme adja - lásd
## scripts/view/ui_theme.gd.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme()

	add_child(UiTheme.build_background())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Zsírozás"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UiTheme.COLOR_GOLD)
	title.add_theme_font_size_override("font_size", UiScale.font_size(86))
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "2 játékos - Add tovább és játssz"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_MUTED)
	subtitle.add_theme_font_size_override("font_size", UiScale.font_size(26))
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	vbox.add_child(spacer)

	var start_btn := Button.new()
	start_btn.text = "Új Játék"
	start_btn.custom_minimum_size = UiScale.button_size(Vector2(240, 54))
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.pressed.connect(func(): SceneManager.go_to_game())
	UiTheme.mark_primary(start_btn)
	UiTheme.add_press_feedback(start_btn)
	vbox.add_child(start_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Kilépés"
	quit_btn.custom_minimum_size = UiScale.button_size(Vector2(240, 54))
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_btn.pressed.connect(func(): get_tree().quit())
	UiTheme.add_press_feedback(quit_btn)
	vbox.add_child(quit_btn)
