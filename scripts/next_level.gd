# Przejście między poziomami kampanii lub scenami uruchomionymi osobno.
extends Area2D

@export_file("*.tscn") var standalone_destination := ""

var _used := false


# Łączy strefę wyjścia z detekcją gracza.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Zleca przejście tylko raz i wyłącza strefę po zakończeniu kroku fizyki.
func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	var current := get_tree().current_scene
	if current == null:
		return
	if current.has_method("advance_level"):
		current.advance_level()
	elif not standalone_destination.is_empty():
		get_tree().change_scene_to_file.call_deferred(standalone_destination)
	else:
		return
	_used = true
	set_deferred("monitoring", false)
