# Poziom 4. Płyty uruchamiają sprężyny, winda pokonuje lukę, a most działa przez określony czas.
extends Node2D

const BRIDGE_DURATION := 5.5
const LIFT_CENTER := Vector2(410.0, -424.0)

var _stage := 0
var _elapsed := 0.0
var _bridge_time := 0.0
var _bridge_secured := false
var _bridge_activated := false

@onready var player: CharacterBody2D = $player
@onready var status: Label = $HUD/Status
@onready var lift: AnimatableBody2D = $TransferLift
@onready var plates: Array[Node2D] = [$Terminals/Launch, $Terminals/Reverse, $Terminals/Reroute]
@onready var springs: Array[Area2D] = [$EastSpring, $ReverseSpring, $WestSpring]
@onready var bridge: Array[StaticBody2D] = [$PhaseWest, $PhaseEast]


# Podłącza detekcję końcowego pomostu i zaczyna z wygaszonym mostem.
func _ready() -> void:
	$FinalCheckpoint.body_entered.connect(_on_final_deck)
	_set_bridge(false)
	_update_status()


# Przesuwa windę po elipsie, zalicza płyty w kolejności i odlicza czas mostu po zejściu z płyty.
func _physics_process(delta: float) -> void:
	_elapsed += delta
	lift.position = LIFT_CENTER + Vector2(39.0 * sin(_elapsed * 1.55), 21.0 * cos(_elapsed * 1.55))
	if get_tree().current_scene == self:
		var camera: Camera2D = $Camera2D
		camera.global_position = camera.global_position.lerp(
			player.global_position, 1.0 - exp(-8.0 * delta)
		)
	if _stage < plates.size() and _on_plate(plates[_stage]):
		var plate := plates[_stage]
		springs[_stage].set_powered(true)
		plate.get_node("Light").color = Color("#ffd389")
		plate.get_node("Hint").text = "Powered"
		_stage += 1
		_update_status()

	if _bridge_secured or _stage < plates.size():
		return
	# Płyta podtrzymuje zasilanie. Konstrukcja zaczyna znikać dopiero po zejściu gracza.
	if _on_plate($Terminals/Bridge):
		if _bridge_time <= 0.0:
			_set_bridge(true)
		_bridge_activated = true
		_bridge_time = BRIDGE_DURATION
	elif _bridge_time > 0.0:
		_bridge_time = maxf(_bridge_time - delta, 0.0)
		if _bridge_time == 0.0:
			_set_bridge(false)
		elif _bridge_time <= 1.2:
			for deck in bridge:
				deck.modulate.a = 0.55 + 0.45 * absf(sin(_bridge_time * 22.0))
	_update_status()


# Sprawdza, czy stojący na podłodze gracz znajduje się nad płytą, aby przelot nad nią się nie liczył.
func _on_plate(plate: Node2D) -> bool:
	var offset := player.global_position + Vector2(12.0, -12.0) - plate.global_position
	return player.is_on_floor() and absf(offset.x) < 30.0 and absf(offset.y) < 30.0


# Synchronizuje kolor mostu i jego powierzchnię kolizji z zasilaniem.
func _set_bridge(powered: bool) -> void:
	for deck in bridge:
		deck.get_node("Surface").set_deferred("disabled", not powered)
		deck.modulate.a = 1.0 if powered else 0.22
	$Terminals/Bridge/Light.color = Color("#ffd389") if powered else Color("#ad7856")


# Po przekroczeniu mostu zabezpiecza go na stałe i odblokowuje wyjście ze szczytu.
func _on_final_deck(body: Node2D) -> void:
	if body != player or _stage != plates.size() or not _bridge_activated:
		return
	_bridge_secured = true
	_set_bridge(true)
	$exit.show()
	$exit.set_deferred("monitoring", true)
	_update_status()


# Pokazuje kolejne zadanie, a po uruchomieniu mostu zastępuje je odliczaniem.
func _update_status() -> void:
	if _bridge_secured:
		status.text = "Bridge locked in · Take the summit spring"
	elif _bridge_time > 0.0:
		status.text = "Phase bridge · %.1f seconds" % _bridge_time
	else:
		status.text = [
			"Stand on the brass plate to power the first spring",
			"Land on the next plate to power the spring facing left",
			"The west plate powers the spring to the upper deck",
			"Ride the transfer lift · Stand on the plate to start the bridge",
		][_stage]
