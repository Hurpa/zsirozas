class_name TrickAreaView
extends Control
## Az asztal közepe: ide kell ejteni a lapokat (ez a "drop zone"), és itt
## jelennek meg egymásra csúsztatva az aktuális (több körös) ütés lapjai.
## Egy jól látható keret + felirat jelzi, hogy ide kell húzni a lapokat.
## A lapok mérete a rendelkezésre álló helyhez igazodik, és forgatáskor
## (refresh_layout) újraszámolódik.

const MAX_CARD_WIDTH_DESKTOP := 130.0
const MIN_CARD_WIDTH_DESKTOP := 60.0
const MAX_CARD_WIDTH_MOBILE := 180.0
const MIN_CARD_WIDTH_MOBILE := 90.0
const ASPECT_RATIO := 194.0 / 120.0

## A jelenlegi ütésben eddig lejátszott lapok - ebből épül fel a látvány,
## így képernyőméret-változáskor (refresh_layout) újra tudjuk rajzolni
## ugyanazokkal az adatokkal, más méretezéssel.
var _played: Array = []  # Array of {"card": CardData, "player_index": int}
var _card_views: Array = []
var _hint_label: Label

func _ready() -> void:
	# Ő maga csak vizuális jelzés / drop-zone (a drop-detektálás a
	# CardView-ban saját maga számolja ki a téglalap-metszést), ne fogja
	# meg az egeret, nehogy eltakarjon mögötte lévő elemeket.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(1, 1, 1, 0.04)
	frame_style.border_color = UiTheme.COLOR_GOLD
	frame_style.border_color.a = 0.45
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(20)

	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	_hint_label = Label.new()
	_hint_label.text = "Ide húzd a lapot"
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", UiTheme.COLOR_TEXT_MUTED)
	_hint_label.add_theme_font_size_override("font_size", UiScale.font_size(16))
	_hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hint_label)

func add_played_card(card: CardData, player_index: int) -> void:
	_played.append({"card": card, "player_index": player_index})
	_rebuild_visuals()

func clear_trick() -> void:
	_played.clear()
	_rebuild_visuals()

## Újraszámolja/újrarajzolja a jelenleg kirakott lapokat az AKTUÁLIS
## méretnek megfelelően - képernyő-átméretezéskor (pl. telefon elforgatás)
## kell hívni, hogy a lapok ne maradjanak "elszállt" pozícióban/méretben.
func refresh_layout() -> void:
	_rebuild_visuals()

func _rebuild_visuals() -> void:
	for cv in _card_views:
		cv.queue_free()
	_card_views.clear()

	var card_size := _compute_card_size()
	for i in range(_played.size()):
		var entry: Dictionary = _played[i]
		var cv := CardView.new()
		cv.display_size = card_size
		add_child(cv)
		cv.setup(entry["card"], true, false)
		var offset := Vector2(i * card_size.x * 0.22, entry["player_index"] * card_size.y * 0.1)
		cv.position = size / 2.0 - card_size / 2.0 + offset
		_card_views.append(cv)

	_hint_label.visible = _played.is_empty()

func _compute_card_size() -> Vector2:
	var is_mobile: bool = UiScale.is_mobile()
	var max_card_width: float = MAX_CARD_WIDTH_MOBILE if is_mobile else MAX_CARD_WIDTH_DESKTOP
	var min_card_width: float = MIN_CARD_WIDTH_MOBILE if is_mobile else MIN_CARD_WIDTH_DESKTOP

	var available_width: float = max(size.x - 32.0, 60.0)
	var available_height: float = max(size.y - 32.0, 60.0)
	var card_width: float = min(max_card_width, available_height / ASPECT_RATIO)
	card_width = min(card_width, available_width * 0.6)
	card_width = max(card_width, min_card_width)
	return Vector2(card_width, card_width * ASPECT_RATIO)
