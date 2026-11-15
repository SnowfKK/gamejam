# Autoload wspólny dla wszystkich scen. Przechowuje życia gracza i zarządza powrotem po obrażeniach.
extends Node

# Globalny stan gry: zdrowie gracza i HUD z serduszkami
const MAX_HEALTH := 4
const HEART_TEXTURE := preload("res://assets/life.png")

var current_health := MAX_HEALTH
var _hearts: Array[TextureRect] = []
var _hud_layer: CanvasLayer
var _damage_pending := false
var _previous_window_mode := Window.MODE_WINDOWED


# Tworzy HUD i odracza dopasowanie okna do czasu, gdy okno jest już gotowe.
func _ready() -> void:
	_build_hud()
	_fit_window_to_screen.call_deferred()


# Pomniejsza okno na małym ekranie, zachowując proporcje i miejsce na obramowanie systemowe.
func _fit_window_to_screen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	if window.mode != Window.MODE_WINDOWED or window.is_embedded():
		return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var available := usable.size - Vector2i(24, 64)
	if available.x <= 0 or available.y <= 0:
		return
	var ratio := minf(float(available.x) / window.size.x, float(available.y) / window.size.y)
	if ratio < 1.0:
		window.size = Vector2i(Vector2(window.size) * ratio)
		window.position = usable.position + (usable.size - window.size) / 2


# Obsługuje F11 i Escape niezależnie od sceny, także przy otwartym menu.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F11 or event.physical_keycode == KEY_F11):
		get_viewport().set_input_as_handled()
		_toggle_fullscreen()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path != "res://sceans/main_menu.tscn":
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file.call_deferred("res://sceans/main_menu.tscn")


# F11 przełącza pełny ekran i przywraca wcześniejszy stan okna po wyjściu.
func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.is_embedded():
		return
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = _previous_window_mode
		_fit_window_to_screen.call_deferred()
	else:
		_previous_window_mode = Window.MODE_MAXIMIZED if window.mode == Window.MODE_MAXIMIZED else Window.MODE_WINDOWED
		window.mode = Window.MODE_FULLSCREEN


# Tworzy oddzielną warstwę serc, aby kamera i tło nie przesuwały licznika.
func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 20
	add_child(_hud_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	_hud_layer.add_child(margin)

	var hbox := HBoxContainer.new()
	margin.add_child(hbox)

	var heart_tex := HEART_TEXTURE
	for i in MAX_HEALTH:
		var heart := TextureRect.new()
		heart.texture = heart_tex
		heart.custom_minimum_size = Vector2(32, 32)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(heart)
		_hearts.append(heart)

	_refresh_hearts()
	set_hud_visible(false)


# Przyciemnia wykorzystane serca, pozostawiając widoczną maksymalną liczbę żyć.
func _refresh_hearts() -> void:
	for i in _hearts.size():
		_hearts[i].modulate.a = 1.0 if i < current_health else 0.25


# Pozwala menu i ekranowi zwycięstwa schować HUD bez usuwania stanu gry.
func set_hud_visible(is_visible: bool) -> void:
	_hud_layer.visible = is_visible


# Zapamiętuje ofiarę, aby odroczone obrażenia nie przeszły na gracza z następnego poziomu.
func take_damage(amount := 1) -> void:
	if _damage_pending:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := scene.find_child("player", true, false) as CharacterBody2D
	if player == null:
		return
	_damage_pending = true
	_apply_damage.call_deferred(amount, scene, player)


# Odrzuca obrażenia po zmianie poziomu i wznawia grę od początku po utracie ostatniego serca.
func _apply_damage(amount: int, scene: Node, player: CharacterBody2D) -> void:
	_damage_pending = false
	if not is_instance_valid(scene) or get_tree().current_scene != scene:
		return
	if not is_instance_valid(player) or not scene.is_ancestor_of(player):
		return

	current_health = maxi(current_health - amount, 0)
	_refresh_hearts()
	if current_health == 0:
		restore_full_health()
		get_tree().change_scene_to_file("res://sceans/main.tscn")
		return

	var spawn := player.get_parent().get_node_or_null("SpawnPoint") as Marker2D
	if spawn:
		player.respawn_at(spawn.global_position)


# Uzupełnia wszystkie serca, gdy zaczyna się kolejny poziom lub nowa kampania.
func restore_full_health() -> void:
	current_health = MAX_HEALTH
	_refresh_hearts()
