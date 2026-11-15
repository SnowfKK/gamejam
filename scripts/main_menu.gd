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


# Dopasowuje obraz do okna i umieszcza przyciski w jego prawej części.
func _layout_menu() -> void:
	var artwork_size := artwork.texture.get_size()
	var scale_factor := minf(size.x / artwork_size.x, size.y / artwork_size.y)
	artwork.size = artwork_size * scale_factor
	artwork.position = (size - artwork.size) * 0.5

	main_buttons.size = Vector2(186.0, main_buttons.get_combined_minimum_size().y)
	var inset := artwork.size.x * 0.035
	main_buttons.position = artwork.position + Vector2(
		artwork.size.x - main_buttons.size.x - inset,
		(artwork.size.y - main_buttons.size.y) * 0.5
	)


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
