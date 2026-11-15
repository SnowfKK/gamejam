extends Area2D

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	monitoring = false
	var main := get_tree().current_scene
	if main and main.has_method("advance_level"):
		main.advance_level()
