# Obsługuje ruch, podwójny skok, sprężyny i powrót po obrażeniach.
extends CharacterBody2D

const SPEED := 130.0
const JUMP_VELOCITY := -300.0
const ACCEL := 900.0
const MAX_JUMPS := 2

var jump_count := 0
var _was_on_floor := false
var movement_lock: Callable
var _checkpoint: Variant
var _spring_speed := 0.0
var _spring_time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sfx: AudioStreamPlayer2D = $JumpSfx
@onready var land_sfx: AudioStreamPlayer2D = $LandSfx


# Pokazuje serca, gdy gracz pojawia się na poziomie.
func _ready() -> void:
	GameState.set_hud_visible(true)


# Zapamiętuje współrzędne bezpiecznego punktu powrotu.
func set_checkpoint(point: Vector2) -> void:
	_checkpoint = point


# Nadaje pęd sprężyny i zostawia jeden dodatkowy skok w powietrzu.
func launch_from_spring(impulse: Vector2) -> void:
	velocity.y = impulse.y
	_spring_speed = impulse.x
	_spring_time = 0.47 if impulse.x != 0.0 else 0.0
	jump_count = 1


# Przenosi gracza bez pędu z poprzedniego upadku i wznawia jego ruch.
func respawn_at(spawn_position: Vector2) -> void:
	global_position = _checkpoint if _checkpoint != null else spawn_position
	_spring_time = 0.0
	velocity = Vector2.ZERO
	jump_count = 0
	_was_on_floor = false
	set_physics_process(true)


# Ustawia prędkość, animację i wykonuje krok fizyki.
func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var locked: bool = movement_lock.is_valid() and movement_lock.call()
	var direction := Input.get_axis("ui_left", "ui_right")

	if on_floor:
		jump_count = 0
	else:
		velocity += get_gravity() * delta

	if on_floor and not _was_on_floor and velocity.y >= 0.0:
		land_sfx.play()
	_was_on_floor = on_floor

	if Input.is_action_just_pressed("ui_up") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		jump_sfx.play()

	# Pęd sprężyny działa przez chwilę, ale można korygować lot strzałkami.
	var horizontal_speed := direction * SPEED
	if _spring_time > 0.0:
		_spring_time -= delta
		horizontal_speed = _spring_speed + direction * SPEED * 0.45
	if locked:
		direction = 0.0
		velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, horizontal_speed, ACCEL * delta)

	if direction != 0.0:
		sprite.flip_h = direction < 0.0
		if not sprite.is_playing():
			sprite.play("default")
	else:
		sprite.stop()
		sprite.frame = 0

	move_and_slide()
