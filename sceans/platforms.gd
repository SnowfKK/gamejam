extends AnimatableBody2D

@export var move_distance: float = 100.0 # O ile pikseli platforma porusza się w górę
@export var duration: float = 2.0        # Czas ruchu w jedną stronę (w sekundach)

func _ready() -> void:
	var start_y = position.y
	var target_y = start_y - move_distance
	
	# Tworzymy nieskończoną pętlę ruchu w górę i w dół
	var tween = create_tween().set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(self, "position:y", target_y, duration)
	tween.tween_property(self, "position:y", start_y, duration)
