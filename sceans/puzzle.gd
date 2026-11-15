# Trzy przekaźniki drugiego poziomu odbudowują most i odblokowują wyjście.
extends Node2D

var _buttons_pressed := {}
var _bridge_active := false

@onready var exit_zone: Area2D = $"../exit"
@onready var player: CharacterBody2D = $"../player"
@onready var status: Label = $HUD/Status
@onready var checkpoint: Marker2D = $Checkpoint

@onready var bridge: StaticBody2D = $Bridge
@onready var bridge_collision: CollisionShape2D = $Bridge/CollisionShape2D
@onready var button1: Area2D = $Button1
@onready var button2: Area2D = $Button2
@onready var button3: Area2D = $Button3


# Ukrywa most i jego kolizję na początku poziomu.
func _ready() -> void:
	# Most jest początkowo nieaktywny.
	bridge_collision.disabled = true
	bridge.visible = false


# Sprawdza obszary wszystkich przekaźników i uruchamia most po zebraniu kompletu.
func _physics_process(_delta: float) -> void:
	# Sprawdzamy stan przycisków.
	_check_button_press(button1, 1)
	_check_button_press(button2, 2)
	_check_button_press(button3, 3)
	
	# Wszystkie przyciski otwierają most.
	if _buttons_pressed.size() >= 3 and not _bridge_active:
		_activate_bridge()


# Zalicza każdy przekaźnik raz. Środkowy przekaźnik zapisuje punkt powrotu na półce nad wyspą.
func _check_button_press(button: Area2D, button_id: int) -> void:
	if _buttons_pressed.has(button_id):
		return
	
	# Szukamy gracza w obszarze przycisku.
	for body in button.get_overlapping_bodies():
		if body.is_in_group("player"):
			_buttons_pressed[button_id] = true
			button.modulate = Color(0.32, 1.0, 0.70)
			if button == button2:
				player.set_checkpoint($MidwayCheckpoint.global_position)
			status.text = "Step on the relays · %d / 3" % _buttons_pressed.size()
			break


# Przywraca widoczność i kolizję mostu, odblokowuje wyjście i zapisuje bezpieczny punkt powrotu.
func _activate_bridge() -> void:
	_bridge_active = true
	bridge.visible = true
	bridge_collision.disabled = false
	# Zielony kolor oznacza aktywny most.
	bridge.modulate = Color(0.52, 1.0, 0.78)
	exit_zone.modulate = Color.WHITE
	exit_zone.set_deferred("monitoring", true)
	player.set_checkpoint(checkpoint.global_position)
	status.text = "Bridge restored · Checkpoint saved"
