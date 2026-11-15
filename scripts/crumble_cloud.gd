# Platforma rozpada się po nadepnięciu, a potem odbudowuje się poza obszarem gracza.
extends StaticBody2D

@export var hold_time := 0.48
@export var reform_time := 2.2
@export var one_way_surface := false

@onready var surface: CollisionShape2D = $Surface
@onready var step_zone: Area2D = $StepZone
@onready var art: Node2D = $Art

var _armed := false
var _collapsed := false
var _time_left := 0.0


# Umożliwia przeskoczenie przez spód chmury tam, gdzie prowadzi do niej skok z niższego pomostu.
func _ready() -> void:
	surface.one_way_collision = one_way_surface


# Obsługuje uzbrojenie, ostrzeżenie, rozpad i powrót platformy. Odkłada odbudowę, jeśli odtworzona kolizja uwięziłaby gracza.
func _physics_process(delta: float) -> void:
	if _collapsed:
		_time_left -= delta
		if _time_left <= 0.0 and step_zone.get_overlapping_bodies().is_empty():
			_collapsed = false
			surface.set_deferred("disabled", false)
			art.modulate = Color.WHITE
			art.position.y = 0.0
		return

	if not _armed:
		for body in step_zone.get_overlapping_bodies():
			if body is CharacterBody2D and body.is_in_group("player") and body.is_on_floor():
				_armed = true
				_time_left = hold_time
				break
		return

	_time_left -= delta
	if _time_left <= 0.0:
		_armed = false
		_collapsed = true
		_time_left = reform_time
		surface.set_deferred("disabled", true)
		art.modulate = Color(0.87, 0.82, 1.0, 0.20)
		art.position.y = 7.0
	else:
		art.modulate = Color("#ffd395") if sin(_time_left * 65.0) > 0.0 else Color.WHITE
		art.position.y = 1.5 * sin(_time_left * 95.0)
