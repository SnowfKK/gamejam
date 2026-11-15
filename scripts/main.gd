# Zarządza kampanią, kamerą i interfejsem.
extends Node2D

const LEVELS: Array[String] = [
	"res://sceans/level1.tscn",
	"res://sceans/level_2.tscn",
	"res://sceans/level3.tscn",
	"res://sceans/level4.tscn",
	"res://sceans/level5.tscn",
]
const LEVEL_NAMES := ["Crumbling Skyway", "Relay Foundry", "Clockwork Crossing", "Switchback Engine", "The Clockkeeper"]
const CONTROLS_DURATION := 15.0
const END_DURATION := 30.0
const WIN_SCENE := "res://sceans/main_menu.tscn"

var level_index := 0
var current_level: Node2D
var level_label: Label
var win_art: TextureRect
var _changing := false
var _won := false
var controls: PanelContainer
var _controls_timer: Timer
var transition_sfx: AudioStreamPlayer


# Tworzy interfejs przed załadowaniem pierwszego poziomu.
func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	level_label = Label.new()
	level_label.position = Vector2(16, 49)
	level_label.add_theme_font_size_override("font_size", 25)
	level_label.add_theme_color_override("font_shadow_color", Color("#283449"))
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(level_label)

	var win_layer := CanvasLayer.new()
	win_layer.layer = 10
	add_child(win_layer)
	win_art = TextureRect.new()
	win_art.texture = preload("res://assets/end.png")
	win_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	win_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_layer.add_child(win_art)
	win_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_art.hide()

	transition_sfx = AudioStreamPlayer.new()
	transition_sfx.bus = &"SFX"
	transition_sfx.stream = preload("res://addons/GodotTogether/src/scripts/extras/halloween/knock2.ogg")
	add_child(transition_sfx)
	_build_controls(layer)
	load_level(0)


# Buduje przewodnik i jednorazowy zegar, który go ukryje.
func _build_controls(layer: CanvasLayer) -> void:
	controls = PanelContainer.new()
	layer.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	controls.offset_left = -285.0
	controls.offset_right = 285.0
	controls.offset_top = -198.0
	controls.offset_bottom = -53.0
	var label := Label.new()
	label.text = "HOW TO PLAY\nLeft / Right  Move      Up  Jump twice\nE / Enter  Repair & confirm      A/D  Turn the dial\nEsc  Main menu      F1  Controls      F11  Fullscreen"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	controls.add_child(label)
	_controls_timer = Timer.new()
	_controls_timer.one_shot = true
	add_child(_controls_timer)
	_controls_timer.timeout.connect(controls.hide)


# Usuwa poprzedni poziom, ustawia kamerę i pokazuje przewodnik na poziomie 1.
func load_level(index: int) -> void:
	_changing = false
	GameState.restore_full_health()
	if is_instance_valid(current_level):
		var old_cam := current_level.get_node_or_null("Camera2D") as Camera2D
		if old_cam:
			old_cam.enabled = false
		remove_child(current_level)
		current_level.queue_free()
	level_index = index
	_controls_timer.stop()
	controls.visible = index == 0
	if controls.visible:
		_controls_timer.start(CONTROLS_DURATION)
	var packed := load(LEVELS[index]) as PackedScene
	current_level = packed.instantiate() as Node2D
	add_child(current_level)
	level_label.text = "%d / %d · %s" % [index + 1, LEVELS.size(), LEVEL_NAMES[index]]
	var cam := current_level.get_node_or_null("Camera2D") as Camera2D
	var player := current_level.get_node_or_null("player") as Node2D
	if cam and player and not cam.is_in_group("fixed_camera"):
		cam.global_position = player.global_position
		cam.enabled = true


# Odracza przejście, bo wyjście jest wykrywane w trakcie fizyki.
func advance_level() -> void:
	if _changing:
		return
	_changing = true
	transition_sfx.play()
	if level_index + 1 < LEVELS.size():
		load_level.call_deferred(level_index + 1)
	else:
		_show_win.call_deferred()


# Pokazuje ekran zwycięstwa po przejściu ostatniego poziomu.
func _show_win() -> void:
	_won = true
	remove_child(current_level)
	current_level.queue_free()
	current_level = null
	GameState.set_hud_visible(false)
	level_label.hide()
	_controls_timer.stop()
	controls.hide()
	add_child(preload("res://sceans/sky_background.tscn").instantiate())
	win_art.show()
	get_tree().create_timer(END_DURATION).timeout.connect(_return_to_menu)


# Wraca do menu po 30 sekundach od wyświetlenia obrazu końcowego.
func _return_to_menu() -> void:
	get_tree().change_scene_to_file(WIN_SCENE)


# Przełącza przewodnik klawiszem F1 podczas rozgrywki.
func _unhandled_input(event: InputEvent) -> void:
	if not _won and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		controls.visible = not controls.visible
		_controls_timer.stop()


# Prowadzi kamerę za graczem, z wyjątkiem kamery areny bossa.
func _physics_process(delta: float) -> void:
	if _won or not is_instance_valid(current_level):
		return
	var cam := current_level.get_node_or_null("Camera2D") as Camera2D
	var player := current_level.get_node_or_null("player") as Node2D
	if cam == null or player == null or cam.is_in_group("fixed_camera"):
		return
	cam.global_position = cam.global_position.lerp(player.global_position, 1.0 - exp(-8.0 * delta))
