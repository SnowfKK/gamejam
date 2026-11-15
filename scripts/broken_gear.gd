# Zębatka, którą można naprawić tylko raz i tylko stojąc w jej zasięgu.
extends Area2D

signal repaired

var _repaired := false

@onready var gear: Polygon2D = $Gear
@onready var prompt: Label = $Label


# Włącza wykrywanie gracza i przygotowuje kształt nienaprawionej zębatki.
func _ready() -> void:
	monitoring = true
	gear.color = Color("#ad7e62")
	gear.polygon = _make_teeth()


# Obraca zębatkę po naprawie, a wcześniej pokazuje podpowiedź tylko w pobliżu gracza.
func _process(delta: float) -> void:
	if _repaired:
		gear.rotation = fposmod(gear.rotation + 2.0 * delta, TAU)
		return
	prompt.visible = _player_nearby()


# Obsługuje E lub Enter. Przejmuje zdarzenie, aby to samo naciśnięcie nie uruchomiło innej interakcji.
func _unhandled_input(event: InputEvent) -> void:
	if _repaired or not _player_nearby():
		return
	if not event.is_action_pressed("clock_interact") and not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_repaired = true
	prompt.hide()
	gear.color = Color("#ffd073")
	repaired.emit()


# Sprawdza strefę zębatki, filtrując obiekty według grupy gracza.
func _player_nearby() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


# Buduje obrys z naprzemiennych promieni, które wyznaczają zęby koła.
func _make_teeth() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(48):
		var radius := 18.0 if i % 4 < 2 else 23.0
		points.append(Vector2.from_angle(TAU * i / 48.0) * radius)
	return points
