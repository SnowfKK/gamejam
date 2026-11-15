# Obsługuje menu, muzykę i ustawienia głośności.
extends Control

@onready var main_buttons: VBoxContainer = $VBoxContainer
@onready var artwork: TextureRect = $TextureRect
@onready var settings_panel: Control = $SettingsPanel
@onready var menu_music: AudioStreamPlayer = $MenuMusic


# Uruchamia muzykę w pętli i odczytuje zapamiętaną głośność.
func _ready() -> void:
	GameState.set_hud_visible(false)
	var track := menu_music.stream as AudioStreamMP3
	if track:
		track.loop = true
		menu_music.play()
	var bus := AudioServer.get_bus_index("Music")
	if bus != -1:
		var volume := 0.0 if AudioServer.is_bus_mute(bus) else db_to_linear(AudioServer.get_bus_volume_db(bus))
		$SettingsPanel/VBoxContainer/MusicSlider.set_value_no_signal(volume)
	resized.connect(_layout_menu)
	_layout_menu()


# Ustawia grafikę i przyciski z odstępem od krawędzi okna.
func _layout_menu() -> void:
	var safe_margin := 56.0
	if size.x < size.y * 1.28:
		artwork.size = Vector2(size.x, size.y * 0.54)
		main_buttons.position = Vector2(size.x * 0.5, (size.y + artwork.size.y) * 0.5) - main_buttons.size * 0.5
	else:
		artwork.size = Vector2(size.x * 0.62, size.y)
		main_buttons.position = Vector2((size.x + artwork.size.x) * 0.5, size.y * 0.5) - main_buttons.size * 0.5
	main_buttons.position.x = clampf(main_buttons.position.x, safe_margin, maxf(safe_margin, size.x - main_buttons.size.x - safe_margin))


# Rozpoczyna kampanię od pierwszego poziomu.
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sceans/main.tscn")


# Otwiera panel ustawień bez zmiany sceny.
func _on_button_2_pressed() -> void:
	main_buttons.hide()
	settings_panel.show()


# Zamyka grę.
func _on_button_3_pressed() -> void:
	get_tree().quit()


# Wraca z ustawień do głównych przycisków.
func _on_back_button_pressed() -> void:
	settings_panel.hide()
	main_buttons.show()


# Zmienia głośność muzyki i wycisza ją przy zerze.
func _on_music_slider_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus != -1:
		AudioServer.set_bus_mute(bus, value == 0.0)
		if value > 0.0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(value))


# Ustawia głośność efektów na oddzielnej szynie SFX.
func _on_sfx_slider_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value))
