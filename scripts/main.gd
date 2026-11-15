extends Node2D

const LEVELS: Array[String] = [
	"res://sceans/level1.tscn",
	"res://sceans/level_2.tscn",
]

var level_index := 0
var current_level: Node2D
var level_label: Label
var _changing := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	level_label = Label.new()
	level_label.position = Vector2(16, 12)
	level_label.add_theme_font_size_override("font_size", 28)
	layer.add_child(level_label)
	load_level(0)


func load_level(index: int) -> void:
	_changing = false
	if current_level and is_instance_valid(current_level):
		var old_cam := current_level.get_node_or_null("Camera2D") as Camera2D
		if old_cam:
			old_cam.enabled = false
		current_level.queue_free()
	level_index = index
	var packed := load(LEVELS[index]) as PackedScene
	current_level = packed.instantiate() as Node2D
	add_child(current_level)
	level_label.text = "Level %d" % [index + 1]
	var cam := current_level.get_node_or_null("Camera2D") as Camera2D
	var player := current_level.get_node_or_null("player") as Node2D
	if cam and player:
		cam.global_position = player.global_position
		cam.enabled = true


func reload_level() -> void:
	if _changing:
		return
	_changing = true
	load_level.call_deferred(level_index)


func advance_level() -> void:
	if _changing:
		return
	_changing = true
	if level_index + 1 < LEVELS.size():
		load_level.call_deferred(level_index + 1)
	else:
		get_tree().change_scene_to_file.call_deferred("res://sceans/main_menu.tscn")


func _physics_process(delta: float) -> void:
	if current_level == null or not is_instance_valid(current_level):
		return
	var cam := current_level.get_node_or_null("Camera2D") as Camera2D
	var player := current_level.get_node_or_null("player") as Node2D
	if cam == null or player == null:
		return
	cam.global_position = cam.global_position.lerp(player.global_position, 1.0 - exp(-8.0 * delta))
