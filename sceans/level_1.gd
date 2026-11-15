# Wspólna obsługa startu poziomów 1 i 2 oraz punktu powrotu przy sprężynie na poziomie 1.
extends Node2D

@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $Camera2D


# Ustawia gracza i kamerę w punkcie startowym, żeby pierwsza klatka nie pokazywała innego miejsca.
func _ready() -> void:
	player.global_position = $SpawnPoint.global_position
	camera.global_position = player.global_position


# Prowadzi kamerę przy uruchomieniu pojedynczej sceny. W kampanii robi to główny skrypt.
func _physics_process(delta: float) -> void:
	if get_tree().current_scene == self:
		camera.global_position = camera.global_position.lerp(
			player.global_position, 1.0 - exp(-8.0 * delta)
		)


# Zapisuje punkt powrotu po pierwszym skutecznym odbiciu od końcowej sprężyny.
func _on_return_spring_launched(body: CharacterBody2D) -> void:
	body.set_checkpoint($ReturnCheckpoint.global_position)
	$SpringHint.text = "Checkpoint saved"
