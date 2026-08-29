class_name ScorePanel
extends Control
## Egyszerű szöveges kijelző: mindkét játékos zsír-pontszáma és a
## talonban maradt lapok száma.

var _p1_label: Label
var _p2_label: Label
var _talon_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_p1_label = Label.new()
	_p2_label = Label.new()
	_talon_label = Label.new()
	var font_size := UiScale.font_size(16)
	for lbl in [_p1_label, _p2_label, _talon_label]:
		lbl.add_theme_font_size_override("font_size", font_size)
		vbox.add_child(lbl)

	update_scores(0, 0)
	update_talon(24)

func update_scores(p1_score: int, p2_score: int) -> void:
	_p1_label.text = "1. Játékos zsírja: %d" % p1_score
	_p2_label.text = "2. Játékos zsírja: %d" % p2_score

func update_talon(count: int) -> void:
	_talon_label.text = "Talon: %d lap" % count
