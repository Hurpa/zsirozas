class_name HandoffOverlay
extends Control
## Két játékos ugyanazon a gépen ("pass & play") - körváltáskor ez az
## átfedő képernyő takarja el a lapokat, amíg a következő játékos meg nem
## nyomja a Felfedés gombot. A tartalom CenterContainer-ben van, ami
## bármilyen képernyőméretnél/aránynál ténylegesen középre igazít.

signal revealed

var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.03, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(300, 0)
	_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT)
	_label.add_theme_font_size_override("font_size", UiScale.font_size(24))
	vbox.add_child(_label)

	var button := Button.new()
	button.text = "Felfedés"
	button.custom_minimum_size = UiScale.button_size(Vector2(200, 50))
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func(): revealed.emit())
	UiTheme.mark_primary(button)
	UiTheme.add_press_feedback(button)
	vbox.add_child(button)

	visible = false

func show_for_player(player_name: String) -> void:
	_label.text = "%s köre következik.\nAdd tovább a gépet, majd nyomd meg a Felfedés gombot." % player_name
	visible = true

func hide_overlay() -> void:
	visible = false
