# Wspólna sprężyna. Nadaje graczowi prędkość i informuje poziom o wykonanym odbiciu.
extends Area2D

signal launched(player: CharacterBody2D)

@export var bounce_velocity := Vector2(0.0, -670.0)
@export var starts_powered := true

@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx: AudioStreamPlayer2D = $Sfx

var _powered := false
var _base_scale: Vector2
var _squash_tween: Tween


# Zapamiętuje skalę grafiki i włącza sprężynę zgodnie z ustawieniem sceny.
func _ready() -> void:
	_base_scale = sprite.scale
	set_powered(starts_powered)
	body_entered.connect(_on_body_entered)


# Zmienia stan zasilania oraz kolor, żeby od razu było widać, czy sprężyna działa.
func set_powered(powered: bool) -> void:
	_powered = powered
	modulate = Color.WHITE if powered else Color("#687083")


# Odbija gracza w locie w dół lub stojącego na podłożu. Dźwięk i ściśnięcie pokazują moment odbicia.
func _on_body_entered(body: Node2D) -> void:
	if not _powered or not body.is_in_group("player"):
		return
	var player := body as CharacterBody2D
	if player == null or player.velocity.y < 0.0:
		return
	player.launch_from_spring(bounce_velocity)
	sfx.play()
	if _squash_tween:
		_squash_tween.kill()
	sprite.scale = Vector2(_base_scale.x, _base_scale.y * 0.55)
	_squash_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(sprite, "scale", _base_scale, 0.25)
	launched.emit(player)
