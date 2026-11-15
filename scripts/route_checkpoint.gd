# Flaga, która po dotknięciu staje się nowym punktem powrotu gracza.
extends Area2D


# Podłącza sygnał wejścia do strefy flagi.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Zapisuje punkt obok flagi, zmienia jej kolor i wyłącza kolejne aktywacje.
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	body.set_checkpoint(global_position + Vector2(-12.0, 0.0))
	$Flag.color = Color("#66eeba")
	set_deferred("monitoring", false)
