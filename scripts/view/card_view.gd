class_name CardView
extends Control
## Egyetlen kártyalap vizuális reprezentációja. Kezeli a húzd-és-ejtsd
## interakciót, ha "interactive" be van kapcsolva. A View réteg tisztán
## megjelenítésért felel - a szabály-eldöntés a Controlleren keresztül
## történik, ide csak visszajelzés érkezik (return_to_home).

signal dropped_on_target(card_view: CardView, target: Control)

## A lapok natív képarányának referenciája (nem feltétlenül a tényleges
## megjelenítési méret - lásd display_size).
const CARD_SIZE := Vector2(120, 194)

var card_data: CardData = null
var face_up: bool = true
var interactive: bool = false

## A ténylegesen megjelenített méret. A HandView/TrickAreaView állítja be
## a rendelkezésre álló hely alapján, mielőtt a node fába kerülne - így
## különböző képernyőméreteken/tájolásokban is jól mutat (pl. keskeny,
## álló telefonon kisebb/összecsúszóbb lapok, széles asztali monitoron
## nagyobbak).
var display_size: Vector2 = CARD_SIZE

## Melyik Control-ra kell ejteni a lapot ahhoz, hogy játéknak számítson.
var drop_zone: Control = null
## Melyik Control-nak legyen a gyereke húzás közben (hogy minden fölött
## látszódjon), és amibe a húzás végén visszakerül, ha nem sikerült a lépés.
var drag_layer: Control = null

var _texture_rect: TextureRect
var _shadow_panel: Panel
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _home_parent: Node = null
var _home_position: Vector2 = Vector2.ZERO
var _home_index: int = -1

func _ready() -> void:
	custom_minimum_size = display_size
	size = display_size
	pivot_offset = display_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Lágy árnyék a lap mögött - "megemelt lap az asztalról" hatás,
	# ez adja a modernebb, mélységgel rendelkező megjelenést.
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.001)
	shadow_style.set_corner_radius_all(10)
	shadow_style.shadow_size = 12
	shadow_style.shadow_color = Color(0, 0, 0, 0.4)
	shadow_style.shadow_offset = Vector2(0, 6)
	_shadow_panel = Panel.new()
	_shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow_panel.size = display_size
	_shadow_panel.add_theme_stylebox_override("panel", shadow_style)
	add_child(_shadow_panel)

	_texture_rect = TextureRect.new()
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.size = display_size
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_texture_rect)

	_update_texture()

func setup(p_card_data: CardData, p_face_up: bool, p_interactive: bool) -> void:
	card_data = p_card_data
	face_up = p_face_up
	interactive = p_interactive
	if is_inside_tree():
		_update_texture()

func _update_texture() -> void:
	if not _texture_rect:
		return
	var file_name := "back.png"
	if face_up and card_data != null:
		file_name = card_data.texture_file_name()
	_texture_rect.texture = load("res://assets/cards/%s" % file_name)

## A húzás INDÍTÁSA pozíció-alapú (_gui_input) - ez helyes, hiszen a
## lenyomásnak épp a lap fölött kell történnie.
func _gui_input(event: InputEvent) -> void:
	if _dragging or not interactive or not face_up:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Az esemény "elhasználtnak" jelölése MINDIG a mellékhatásos hívás
			# (itt: _start_drag) ELŐTT történjen. Ha a sorrend fordított
			# lenne, és a mellékhatás (lásd _input lent) időközben pl.
			# jelenetváltást okozna, a node már kikerülhet az aktuális
			# Viewport-ból, és a get_viewport() null-t adna vissza.
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_start_drag(mb.global_position)

## Húzás KÖZBEN viszont MINDEN egéreseményt figyelünk (_input), nem csak
## azokat, amik épp a lap fölött történnek. Enélkül gyors egérmozgásnál a
## felengedés eseménye "lemaradhat" a lapról, a húzás sosem zárul le, és a
## kártya örökre a képernyőn ragad (ez okozta a korábbi hibát).
func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_update_drag((event as InputEventMouseMotion).global_position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			# Fontos: az utolsó lap kijátszása a leosztás végét is
			# jelentheti, ami szinkron módon jelenetváltást indíthat el
			# (_end_drag -> dropped_on_target -> ... -> game_over ->
			# SceneManager.go_to_result). Ezért a Viewportot MÉG a
			# jelenetváltás előtt kikérjük, és az "elhasználtnak" jelölést
			# is MÉG _end_drag() meghívása előtt elvégezzük - utána a node
			# már lehet, hogy nincs érvényes Viewport-ban.
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_end_drag(mb.global_position)

func _start_drag(global_pos: Vector2) -> void:
	_dragging = true
	_home_parent = get_parent()
	_home_position = position
	_home_index = get_index()
	_drag_offset = global_position - global_pos

	var target_layer: Node = drag_layer if drag_layer != null else _home_parent
	if target_layer != _home_parent:
		_home_parent.remove_child(self)
		target_layer.add_child(self)
	z_index = 100
	global_position = global_pos + _drag_offset
	_animate_scale(1.08)

func _update_drag(global_pos: Vector2) -> void:
	global_position = global_pos + _drag_offset

func _end_drag(global_pos: Vector2) -> void:
	_dragging = false
	z_index = 0
	if drop_zone != null and _is_over_drop_zone(global_pos):
		dropped_on_target.emit(self, drop_zone)
	else:
		return_to_home()

func _is_over_drop_zone(global_pos: Vector2) -> bool:
	var r := Rect2(drop_zone.global_position, drop_zone.size)
	return r.has_point(global_pos)

## Visszateszi a lapot az eredeti helyére (pl. mert a lépés szabálytalan
## volt, vagy mert a húzást a kezünkbe engedtük vissza).
func return_to_home() -> void:
	_animate_scale(1.0)
	if _home_parent == null:
		return
	if get_parent() != _home_parent:
		get_parent().remove_child(self)
		_home_parent.add_child(self)
		if _home_index >= 0:
			_home_parent.move_child(self, min(_home_index, _home_parent.get_child_count() - 1))
	position = _home_position
	z_index = 0

## Finom, gyors nagyítás-animáció - a lap MOZGÁSA (pozíciója) továbbra is
## azonnali marad, csak ez a kis "megemelés" érzés kap egy pillanatnyi
## átmenetet, ettől tűnik kézzelfoghatóbbnak/modernebbnek a húzás.
func _animate_scale(target: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(target, target), 0.08)
