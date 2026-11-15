extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const ACCEL = 900.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)

	if direction != 0.0:
		sprite.flip_h = direction < 0.0
		if not sprite.is_playing():
			sprite.play("default")
	else:
		sprite.stop()
		sprite.frame = 0

	move_and_slide()
