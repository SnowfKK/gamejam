extends Area2D

@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not timer.is_stopped():
		return
	body.set_physics_process(false)
	timer.start()


func _on_timer_timeout() -> void:
	var main := get_tree().current_scene
	if main and main.has_method("reload_level"):
		main.reload_level()
	else:
		get_tree().reload_current_scene()
