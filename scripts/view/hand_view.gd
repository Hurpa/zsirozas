class_name HandView
extends Control
## Egy játékos kezét jeleníti meg: vagy nyílt lapokkal (a felfedett,
## aktuális játékosnál), vagy csak hátlapokkal (a másik játékosnál).
## A lapok mérete és térköze DINAMIKUSAN, a ténylegesen rendelkezésre álló
## helyhez igazodik, hogy keskeny/álló mobilképernyőn is elférjen mind a
## (legfeljebb 4) lap, asztali gépen pedig ne legyenek indokolatlanul aprók.

const MAX_CARD_WIDTH_DESKTOP := 130.0
const MIN_CARD_WIDTH_DESKTOP := 62.0
const MAX_CARD_WIDTH_MOBILE := 175.0
const MIN_CARD_WIDTH_MOBILE := 92.0
const ASPECT_RATIO := 194.0 / 120.0  # magasság / szélesség, a natív lapképek alapján
const SIDE_MARGIN := 16.0
const TOP_MARGIN := 10.0

func _ready() -> void:
	# A HandView csak egy láthatatlan tartó a lapoknak - önmaga ne fogja meg
	# az egeret, különben eltakarhat mögötte/rajta lévő gombokat (pl. Főmenü).
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Nyílt lapok megjelenítése, opcionálisan interaktívan (húzható).
func render(cards: Array, p_face_up: bool, p_interactive: bool, p_drop_zone: Control, p_drag_layer: Control, on_dropped: Callable) -> void:
	_clear()
	var count: int = cards.size()
	var layout := _compute_layout(count)
	var start_x: float = _start_x(count, layout.card_size.x, layout.spacing)
	for i in range(count):
		var cv := CardView.new()
		cv.display_size = layout.card_size
		add_child(cv)
		cv.position = Vector2(start_x + i * layout.spacing, TOP_MARGIN)
		cv.setup(cards[i], p_face_up, p_interactive)
		cv.drop_zone = p_drop_zone
		cv.drag_layer = p_drag_layer
		if p_interactive:
			cv.dropped_on_target.connect(on_dropped)

## Csak a lapok darabszámát mutatja, hátlappal (a másik / rejtett kéz).
func render_backs(count: int) -> void:
	_clear()
	var layout := _compute_layout(count)
	var start_x: float = _start_x(count, layout.card_size.x, layout.spacing)
	for i in range(count):
		var cv := CardView.new()
		cv.display_size = layout.card_size
		add_child(cv)
		cv.position = Vector2(start_x + i * layout.spacing, TOP_MARGIN)
		cv.setup(null, false, false)

## Kiszámolja az aktuális (size alapján ismert, ténylegesen elérhető) hely
## alapján a lapok méretét és egymástól való vízszintes távolságát.
## Szűk helyen (pl. álló telefon) a lapok kisebbek lesznek ÉS jobban
## egymásra is csúszhatnak, hogy mind a 4 elférjen.
func _compute_layout(count: int) -> Dictionary:
	var is_mobile: bool = UiScale.is_mobile()
	var max_card_width: float = MAX_CARD_WIDTH_MOBILE if is_mobile else MAX_CARD_WIDTH_DESKTOP
	var min_card_width: float = MIN_CARD_WIDTH_MOBILE if is_mobile else MIN_CARD_WIDTH_DESKTOP

	var available_width: float = max(size.x - SIDE_MARGIN * 2.0, 80.0)
	var available_height: float = max(size.y - TOP_MARGIN * 2.0, 60.0)

	var card_width: float = max_card_width
	# A magasság korlátozza felülről (ne lógjon ki a sorból).
	card_width = min(card_width, available_height / ASPECT_RATIO)
	# Ha sok lap van kevés helyen, engedjük kisebbre, hogy elférjen - mobilon
	# nagyobb átfedést engedünk meg (a lapok maradjanak nagyok/olvashatók,
	# inkább csússzanak jobban egymásra).
	if count > 0:
		var overlap_allowance: float = 2.1 if is_mobile else 1.8
		var width_budget: float = (available_width / float(count)) * overlap_allowance
		card_width = min(card_width, width_budget)
	card_width = max(card_width, min_card_width)

	var card_size := Vector2(card_width, card_width * ASPECT_RATIO)

	var min_spacing_ratio: float = 0.22 if is_mobile else 0.26
	var spacing: float = card_width * 0.72
	if count > 1:
		var fit_spacing: float = (available_width - card_width) / float(count - 1)
		spacing = min(spacing, max(fit_spacing, card_width * min_spacing_ratio))

	return {"card_size": card_size, "spacing": spacing}

func _start_x(count: int, card_width: float, spacing: float) -> float:
	var total_width: float = card_width + spacing * max(0, count - 1)
	return (size.x - total_width) / 2.0

func _clear() -> void:
	for child in get_children():
		child.queue_free()
