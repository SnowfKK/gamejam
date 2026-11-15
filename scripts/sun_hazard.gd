# Wspólny promień słoneczny. Kolejno przechodzi przez przerwę, ostrzeżenie i fazę obrażeń.
extends Area2D

@export var safe_time := 10.0
@export var warning_time := 0.8
@export var danger_time := 1.5
@export var damage_interval := 0.5
@export var phase_offset := 0.0
@export var beam_size := Vector2.ZERO

@onready var visual: ColorRect = $ColorRect
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var laser: Line2D = $Laser
@onready var cooldown_bar: ProgressBar = $CooldownBar

var _elapsed := 0.0
var _damage_timer := 0.0


# Dopasowuje ślad lasera i pasek odliczania do prostokąta kolizji. Przesunięcie fazy rozdziela rytm wielu promieni.
func _ready() -> void:
	var rectangle := shape.shape as RectangleShape2D
	if beam_size != Vector2.ZERO:
		rectangle = RectangleShape2D.new()
		rectangle.size = beam_size
		shape.shape = rectangle
	var size := rectangle.size
	visual.position = shape.position - size * 0.5
	visual.size = size
	laser.points = PackedVector2Array([
		shape.position - Vector2(0.0, size.y * 0.5),
		shape.position + Vector2(0.0, size.y * 0.5),
	])
	laser.width = minf(8.0, size.x)
	cooldown_bar.position.y = visual.position.y - 12.0
	cooldown_bar.visible = beam_size != Vector2.ZERO
	_elapsed = phase_offset
	_update_visuals()


# Przesuwa zegar cyklu i zadaje obrażenie po upływie ustawionego czasu kontaktu z aktywnym promieniem.
func _physics_process(delta: float) -> void:
	_elapsed = fposmod(_elapsed + delta, maxf(safe_time + warning_time + danger_time, 0.01))
	_update_visuals()

	if _elapsed < safe_time + warning_time:
		_damage_timer = 0.0
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_damage_timer += delta
			if _damage_timer >= damage_interval:
				_damage_timer = 0.0
				GameState.take_damage()
			return
	_damage_timer = 0.0


# Całkowicie zatrzymuje cykl i ukrywa promień po otrzymaniu sygnału z poziomu.
func disable() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	hide()


# Zaznacza kolejne fazy przez zmianę jasności i aktualizuje pasek czasu do wystrzału.
func _update_visuals() -> void:
	var intensity := 0.0
	if _elapsed >= safe_time + warning_time:
		intensity = 1.0
	elif _elapsed >= safe_time:
		intensity = 0.35 + 0.15 * sin(_elapsed * 34.0)
	visual.modulate.a = intensity
	laser.modulate.a = intensity
	cooldown_bar.value = clampf(_elapsed / maxf(safe_time + warning_time, 0.01), 0.0, 1.0)
