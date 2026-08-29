class_name ContinuePrompt
extends Control
## Akkor jelenik meg, amikor a vezető játékos ellenfele éppen nyerné az
## ütést, de a vezetőnek van még illeszkedő lapja (vagy hetese) - ő dönt:
## folytatja-e az ütést, vagy elengedi az ellenfélnek. CenterContainer-ben
## van a tartalom, hogy bármilyen felbontásnál valóban középre kerüljön.

signal answered(wants_continue: bool)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.02, 0.02, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = "Az ellenfél nyerné az ütést.\nFolytatod (van illeszkedő lapod vagy hetesed)?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	var yes_btn := Button.new()
	yes_btn.text = "Igen, folytatom"
	yes_btn.custom_minimum_size = UiScale.button_size(Vector2(160, 44))
	yes_btn.pressed.connect(func(): answered.emit(true))
	UiTheme.add_press_feedback(yes_btn)
	hbox.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "Nem, engedem"
	no_btn.custom_minimum_size = UiScale.button_size(Vector2(160, 44))
	no_btn.pressed.connect(func(): answered.emit(false))
	UiTheme.add_press_feedback(no_btn)
	hbox.add_child(no_btn)

	visible = false

func show_prompt() -> void:
	visible = true

func hide_prompt() -> void:
	visible = false
