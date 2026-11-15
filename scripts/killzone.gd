# Wykrywa upadek i odracza obrażenia na czas dźwięku.
extends Area2D

var _falling_player: CharacterBody2D

@onready var timer: Timer = $Timer
@onready var sfx: AudioStreamPlayer2D = $DeathSfx


# Zatrzymuje gracza i odlicza od początku dla każdego nowego upadku.
func _on_body_entered(body: Node2D) -> void:
	var player := body as CharacterBody2D
	if player == null or not player.is_in_group("player") or not player.is_physics_processing():
		return
	_falling_player = player
	player.set_physics_process(false)
	sfx.play()
	timer.start()


# Pomija karę, jeśli inne obrażenia już przeniosły gracza i wznowiły ruch.
func _on_timer_timeout() -> void:
	var player := _falling_player
	_falling_player = null
	if is_instance_valid(player) and player.is_inside_tree() and not player.is_physics_processing():
		GameState.take_damage()
