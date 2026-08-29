class_name UiScale
extends RefCounted
## Kis segédosztály a mobil / asztali UI méretezés különbségeihez.
## Mobilon (Android/iOS export, vagy a Godot mobil app) nagyobb,
## ujjbarátabb célméreteket adunk a gomboknak, mint asztalon.

const MOBILE_MIN_TOUCH_WIDTH := 88.0
const MOBILE_MIN_TOUCH_HEIGHT := 64.0

static func is_mobile() -> bool:
	return OS.has_feature("mobile")

## A megadott "asztali" alapmérethez adja vissza a ténylegesen használandó
## minimum gombméretet: mobilon garantáltan legalább ujjbarát (~64px magas,
## ~88px széles), asztalon változatlanul az eredeti (kisebb, egérrel is
## kényelmes) méret. A base-t is felskálázzuk kicsit (nem csak alsó
## korlátozzuk), hogy a gombok VIZUÁLISAN is nagyobbnak, kényelmesebbnek
## tűnjenek, ne csak a láthatatlan érintési terület nőjön.
static func button_size(base: Vector2) -> Vector2:
	if not is_mobile():
		return base
	var scaled := base * 1.25
	return Vector2(max(scaled.x, MOBILE_MIN_TOUCH_WIDTH), max(scaled.y, MOBILE_MIN_TOUCH_HEIGHT))

## Betűméret mobilon nagyobb az olvashatóság/vizuális súly miatt.
static func font_size(base: int) -> int:
	return int(round(base * 1.25)) if is_mobile() else base
