class_name ConfirmDialogView
extends Control
## Általános célú Igen/Nem megerősítő overlay. Jelenleg a "Főmenü" gomb
## használja játék közben, hogy ne lehessen véletlenül megszakítani a
## folyamatban lévő leosztást.

signal answered(confirmed: bool)

var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.02, 0.02, 0.65)
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

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	var no_btn := Button.new()
	no_btn.text = "Mégsem"
	no_btn.custom_minimum_size = UiScale.button_size(Vector2(140, 44))
	no_btn.pressed.connect(func(): answered.emit(false))
	UiTheme.mark_primary(no_btn)
	UiTheme.add_press_feedback(no_btn)
	hbox.add_child(no_btn)

	var yes_btn := Button.new()
	yes_btn.text = "Igen"
	yes_btn.custom_minimum_size = UiScale.button_size(Vector2(140, 44))
	yes_btn.pressed.connect(func(): answered.emit(true))
	UiTheme.add_press_feedback(yes_btn)
	hbox.add_child(yes_btn)

	visible = false

func show_with_message(message: String) -> void:
	_label.text = message
	visible = true

func hide_dialog() -> void:
	visible = false
