# Panel zegara na trzecim poziomie. Blokuje ruch poziomy podczas ustawiania godziny.
extends Area2D

signal clock_solved

const TOLERANCE := 10.0

@export var target_angle := 180.0
@export var rotate_speed := 90.0

var _angle := 0.0
var _solved := false
var _enabled := false

@onready var hand: Node2D = $Hand
@onready var face: Node2D = $Face
@onready var label: Label = $Label


# Odblokowuje panel po dwóch naprawach i przywraca jasny kolor tarczy.
func activate() -> void:
	_enabled = true
	face.modulate = Color.WHITE


# Informuje skrypt ruchu, czy klawisze lewo i prawo mają w tej chwili obsługiwać panel.
func controls_player(player: Node2D) -> bool:
	return _enabled and not _solved and overlaps_body(player)


# Wykrywa gracza w strefie i obraca wskazówkę. Podpowiedź zmienia się po wejściu w dopuszczalny zakres.
func _physics_process(delta: float) -> void:
	var in_zone := false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			in_zone = true
			break

	label.visible = in_zone and not _solved
	if not label.visible:
		return
	if not _enabled:
		label.text = "Repair both gears first"
		return

	var keyboard := Input.get_axis("clock_left", "clock_right")
	var arrows := Input.get_axis("ui_left", "ui_right")
	var direction := clampf(keyboard + arrows, -1.0, 1.0)
	_angle = fposmod(_angle + direction * rotate_speed * delta, 360.0)
	hand.rotation_degrees = _angle
	if _on_target():
		label.text = "E / Enter · Confirm"
		label.modulate = Color("#c4ffa2")
	else:
		label.text = "A/D or Left/Right · Set to VI"
		label.modulate = Color.WHITE


# Akceptuje potwierdzenie wewnątrz strefy tylko przy właściwym kącie. Sygnał kończy zagadkę.
func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or _solved or not _on_target():
		return
	if not event.is_action_pressed("clock_interact") and not event.is_action_pressed("ui_accept"):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			get_viewport().set_input_as_handled()
			_solved = true
			label.hide()
			hand.modulate = Color("#b5f6a1")
			clock_solved.emit()
			return


# Liczy najkrótszą odległość kątową, także gdy kąt przechodzi przez 0 lub 360 stopni.
func _on_target() -> bool:
	return absf(wrapf(_angle - target_angle, -180.0, 180.0)) <= TOLERANCE
