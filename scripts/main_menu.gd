extends Control

# ==============================================================================
# JAK DODAĆ MUZYKĘ I DŹWIĘKI (INSTRUKCJA):
# 1. Kliknij prawym przyciskiem myszy na główny węzeł "main_menu" i dodaj węzeł "AudioStreamPlayer".
# 2. Przeciągnij plik muzyczny (np. .mp3 lub .ogg) z folderu projektu do pola "Stream" w Inspektorze.
# 3. Zaznacz pole "Autoplay" na "Wł." (On), aby muzyka grała od razu po włączeniu menu.
# 4. WAŻNE: W Inspektorze w polu "Bus" wybierz "Music" (dla muzyki) lub "SFX" (dla efektów dźwiękowych),
#    aby poniższe suwaki głośności działały poprawnie!
# ==============================================================================

# Referencje do głównych przycisków i panelu ustawień
@onready var main_buttons = $VBoxContainer
@onready var settings_panel = $SettingsPanel

func _on_button_pressed() -> void:
	# Przycisk Start — przełącza na główną scenę gry (main.tscn)
	get_tree().change_scene_to_file("res://sceans/main.tscn")

func _on_button_2_pressed() -> void:
	# Przycisk Settings — ukrywa główne przyciski i pokazuje panel ustawień
	main_buttons.visible = false
	settings_panel.visible = true

func _on_button_3_pressed() -> void:
	# Przycisk Quit — zamyka grę
	get_tree().quit()

func _on_back_button_pressed() -> void:
	# Przycisk Wróć — zamyka ustawienia i przywraca główne menu
	settings_panel.visible = false
	main_buttons.visible = true

func _on_music_slider_value_changed(value: float) -> void:
	# Zmiana głośności szyny audio "Music"
	# Aby ten suwak działał, węzeł AudioStreamPlayer z muzyką musi mieć ustawiony Bus na "Music" w Inspektorze
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	# Zmiana głośności szyny audio "SFX" (efekty dźwiękowe, np. kliknięcia przycisków)
	# Aby ten suwak działał, węzeł AudioStreamPlayer z dźwiękiem musi mieć ustawiony Bus na "SFX" w Inspektorze
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
