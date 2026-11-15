# Steruje naprawą zegara, bramami, wahadłami i niebezpieczną wskazówką na poziomie 3.
extends Node2D

const FACE_CENTER := Vector2(515.0, -173.0)
const NUMERALS := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]

var _gears_fixed := 0
var _elapsed := 0.0
var _repaired := false

@onready var dial = $ClockDial
@onready var exit_zone: Area2D = $exit
@onready var objective: Label = $Objectives/Objective
@onready var clock_hand: AnimatableBody2D = $ClockHand
@onready var blade_hitbox: Area2D = $ClockHand/BladeHitbox
@onready var blade_edge: Polygon2D = $ClockHand/Edge
@onready var west_pendulum: AnimatableBody2D = $WestPendulum
@onready var east_pendulum: AnimatableBody2D = $EastPendulum
@onready var west_cable: Line2D = $Cables/West
@onready var east_cable: Line2D = $Cables/East
@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $Camera2D


# Ustawia punkt startowy i łączy sygnały zębatek, panelu oraz strefy ostrza.
func _ready() -> void:
	player.global_position = $SpawnPoint.global_position
	player.movement_lock = dial.controls_player.bind(player)
	$Gear1.repaired.connect(_on_gear_repaired.bind($FirstGate, $Gear1Checkpoint))
	$Gear2.repaired.connect(_on_gear_repaired.bind($SecondGate, $Gear2Checkpoint))
	dial.clock_solved.connect(_on_clock_solved)
	blade_hitbox.body_entered.connect(_on_blade_hit)


# Obraca wskazówkę i porusza wahadłami w takcie fizyki. Przy uruchomieniu samej sceny podąża też kamerą za graczem.
func _physics_process(delta: float) -> void:
	_elapsed += delta
	var rotation_speed := 0.20 if _repaired else 0.75
	clock_hand.rotation = wrapf(clock_hand.rotation + delta * rotation_speed, -PI, PI)
	_move_pendulum(west_pendulum, west_cable, 0.0, 181.0)
	_move_pendulum(east_pendulum, east_cable, 1.4, 178.0)
	if get_tree().current_scene == self:
		camera.global_position = camera.global_position.lerp(
			player.global_position, 1.0 - exp(-8.0 * delta)
		)


# Przesuwa platformę po łuku od punktu zawieszenia i dopasowuje do niej długość narysowanego przewodu.
func _move_pendulum(platform: AnimatableBody2D, cable: Line2D, phase: float, length: float) -> void:
	var angle := 0.20 * sin(_elapsed * 1.75 + phase)
	var displacement := Vector2.DOWN.rotated(angle) * length
	platform.position = cable.position + displacement
	cable.set_point_position(1, displacement)


# Otwiera bramę danej zębatki, zapisuje punkt powrotu i po drugiej naprawie aktywuje panel.
func _on_gear_repaired(gate: StaticBody2D, checkpoint: Marker2D) -> void:
	_open_gate(gate)
	player.set_checkpoint(checkpoint.global_position)
	_gears_fixed += 1
	objective.text = "Repair the gears · %d / 2" % _gears_fixed
	if _gears_fixed == 2:
		dial.activate()
		objective.text = "Dodge the blade · Set the clock to VI"


# Zgłasza obrażenie wyłącznie przy kontakcie gracza z ostrzem przed naprawą zegara.
func _on_blade_hit(body: Node2D) -> void:
	if not _repaired and body.is_in_group("player"):
		GameState.take_damage()


# Gasi promienie przy zegarze, zabezpiecza wskazówkę i uruchamia sprężynę prowadzącą na górny odcinek.
func _on_clock_solved() -> void:
	_repaired = true
	blade_hitbox.set_deferred("monitoring", false)
	blade_edge.color = Color("#8df0cc")
	for hazard in $Hazards.get_children():
		hazard.disable()
	_open_gate($ExitGate)
	$ClockSpring.set_powered(true)
	player.set_checkpoint($ClockCheckpoint.global_position)
	exit_zone.show()
	exit_zone.set_deferred("monitoring", true)
	objective.text = "Clock restored · Take the spring to the upper walkway"


# Ukrywa bramę i wyłącza kolizję z odroczeniem, bez zmiany kształtu podczas przetwarzania kontaktów.
func _open_gate(gate: StaticBody2D) -> void:
	gate.hide()
	gate.get_node("CollisionShape2D").set_deferred("disabled", true)


# Rysuje nieruchomą tarczę, podziałkę, cyfry rzymskie i refleksy na szkle.
func _draw() -> void:
	var brass := Color("#d1a173")
	var dark_metal := Color("#4f3d51")
	draw_circle(FACE_CENTER, 237.0, dark_metal, true, -1.0, true)
	draw_circle(FACE_CENTER, 230.0, brass, false, 5.0, true)
	draw_circle(FACE_CENTER, 221.0, Color("#574761"), true, -1.0, true)
	draw_circle(FACE_CENTER, 207.0, Color("#3d5569"), true, -1.0, true)
	draw_circle(FACE_CENTER, 199.0, Color("#455f77"), true, -1.0, true)
	draw_circle(FACE_CENTER, 163.0, Color("#7b8190"), false, 1.0, true)

	var font := ThemeDB.fallback_font
	for i in range(60):
		var direction := Vector2.UP.rotated(TAU * i / 60.0)
		var major := i % 5 == 0
		var inner := 193.0 if major else 199.0
		draw_line(FACE_CENTER + direction * inner, FACE_CENTER + direction * 207.0, brass, 2.0 if major else 1.0, true)
		if major:
			var numeral: String = NUMERALS[i / 5]
			var width := font.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			var label_pos := FACE_CENTER + direction * 179.0 + Vector2(-width * 0.5, 5.0)
			draw_string(font, label_pos, numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f6d5a7"))
			draw_circle(FACE_CENTER + direction * 219.0, 3.0, brass)
	draw_line(FACE_CENTER + Vector2(-164, -85), FACE_CENTER + Vector2(24, -187), Color(0.82, 0.93, 1.0, 0.24), 3.0, true)
	draw_line(FACE_CENTER + Vector2(-180, -58), FACE_CENTER + Vector2(62, -188), Color(0.82, 0.93, 1.0, 0.16), 7.0, true)
	draw_line(FACE_CENTER + Vector2(19, 146), FACE_CENTER + Vector2(180, 57), Color(0.82, 0.93, 1.0, 0.17), 4.0, true)
	draw_circle(FACE_CENTER, 16.0, dark_metal, true, -1.0, true)
	draw_circle(FACE_CENTER, 12.0, brass, false, 3.0, true)
