extends Control

func _on_button_pressed() -> void:
	# Przycisk Start — przełącza na główną scenę gry (main.tscn)
	get_tree().change_scene_to_file("res://main.tscn")

func _on_button_2_pressed() -> void:
	# Przycisk Settings — otwiera ustawienia
	print("Otwarto ustawienia")

func _on_button_3_pressed() -> void:
	# Przycisk Quit — zamyka grę
	get_tree().quit()
