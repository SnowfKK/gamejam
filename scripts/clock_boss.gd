# Walka z bossem. Po ostrzeżeniu i ataku rdzeń sam się odsłania, dając czas na odbicie od sprężyny.
extends Node2D

# Kolejność faz: śledzenie, ostrzeżenie, atak, otwarty rdzeń i regeneracja.
enum Phase { TRACKING, WARNING, STRIKE, OPEN, RECOVER, DEFEATED }

const CENTER := Vector2(260, -151)
const LANE_HALF_WIDTH := 26.0
const ARENA_TOP := -400.0
const ARENA_BOTTOM := 14.0
const MAX_HEALTH := 6

var health := MAX_HEALTH
var phase := Phase.TRACKING
var _time_left := 0.75
var _lanes := PackedFloat32Array([0.0])
var _strike_hit := false
var _spring_armed := false
var _sweep_angle := 0.0

@onready var player: CharacterBody2D = $player
@onready var exit_zone: Area2D = $exit
@onready var status: Label = $HUD/Status
@onready var counter: Label = $HUD/Counter


# Łączy sygnały obu sprężyn i wyświetla początkowy stan walki.
func _ready() -> void:
	$WestSpring.launched.connect(_on_spring_launched)
	$EastSpring.launched.connect(_on_spring_launched)
	_update_text()


# Odmierza czas faz, sprawdza trafienia oraz odświeża rysunek. Każdy udany atak na rdzeń kończy bieżącą rundę.
func _physics_process(delta: float) -> void:
	if phase == Phase.DEFEATED:
		return
	if player.is_on_floor() and player.velocity.y >= 0.0:
		_spring_armed = false
	_time_left -= delta
	var player_center := player.global_position + Vector2(12, -12)
	match phase:
		Phase.TRACKING:
			_lanes = PackedFloat32Array([clampf(player_center.x, -65.0, 585.0)])
			# Po pierwszych trafieniach drugi pas wymusza wybór wolnego miejsca do uniku.
			if health <= 4:
				var other_lane := 520.0 - _lanes[0]
				if absf(other_lane - _lanes[0]) < 90.0:
					other_lane = _lanes[0] + 114.0
				_lanes.append(other_lane)
			if _time_left <= 0.0:
				_enter(Phase.WARNING, 0.75 if health >= 3 else 0.55)
		Phase.WARNING:
			if _time_left <= 0.0:
				_strike_hit = false
				_enter(Phase.STRIKE, 0.34)
		Phase.STRIKE:
			if not _strike_hit and _strike_reaches(player_center):
				_strike_hit = true
				_spring_armed = false
				GameState.take_damage()
			if _time_left <= 0.0:
				_open_core()
		Phase.OPEN:
			_sweep_angle += delta * (2.5 if health > 1 else 3.2)
			if health <= 3 and not _strike_hit and _hand_reaches(player_center):
				_strike_hit = true
				_spring_armed = false
				GameState.take_damage()

			# Zielony rdzeń przyjmuje tylko uderzenie z góry w trakcie odskoku od sprężyny.
			if _spring_armed and player.velocity.y > 20.0 and player_center.distance_to(CENTER) <= 46.0:
				_damage_core()
			elif _time_left <= 0.0:
				_enter(Phase.TRACKING, 0.48)
		Phase.RECOVER:
			if _time_left <= 0.0:
				_enter(Phase.TRACKING, 0.60)
	queue_redraw()


# Otwiera rdzeń natychmiast po ataku. Resetuje ostrza i odliczanie, aby każda próba zaczynała się w przewidywalnym stanie.
func _open_core() -> void:
	_strike_hit = false
	_sweep_angle = -PI * 0.5
	_enter(Phase.OPEN, 4.8 if health <= 3 else 5.5)


# Sprawdza odległość od ruchomego ostrza. W ostatniej rundzie drugie ostrze obraca się po przeciwnej stronie.
func _hand_reaches(target: Vector2) -> bool:
	var distance := CENTER.distance_to(target)
	if distance < 47.0 or distance > 125.0:
		return false
	var tip := CENTER + Vector2.from_angle(_sweep_angle) * 114.0
	if Geometry2D.get_closest_point_to_segment(target, CENTER, tip).distance_to(target) < 14.0:
		return true
	if health == 1:
		var second_tip := CENTER - Vector2.from_angle(_sweep_angle) * 96.0
		return Geometry2D.get_closest_point_to_segment(target, CENTER, second_tip).distance_to(target) < 13.0
	return false


# Sprawdza pionowe pasy lasera. Przy ostatnim życiu bossa uderzenie obejmuje także podłogę.
func _strike_reaches(target: Vector2) -> bool:
	if target.y < ARENA_TOP or target.y > ARENA_BOTTOM:
		return false
	if health == 1 and target.y >= -45.0:
		return true
	for lane in _lanes:
		if absf(target.x - lane) <= LANE_HALF_WIDTH + 10.0:
			return true
	return false


# Zapamiętuje odbicie gracza, aby w rdzeń można było trafić podczas opadania z tej próby.
func _on_spring_launched(body: CharacterBody2D) -> void:
	if body == player:
		_spring_armed = true


# Odejmuje punkt życia i odrzuca gracza w górę. Po ostatnim trafieniu uzbraja wyjście i wyłącza sprężyny.
func _damage_core() -> void:
	_spring_armed = false
	health -= 1
	player.velocity.y = -235.0
	if health == 0:
		_enter(Phase.DEFEATED, 0.0)
		$WestSpring.set_powered(false)
		$EastSpring.set_powered(false)
		exit_zone.show()
		exit_zone.set_deferred("monitoring", true)
	else:
		_enter(Phase.RECOVER, 0.75)


# Przełącza fazę i od razu aktualizuje komunikat, żeby ostrzeżenie odpowiadało aktualnemu stanowi walki.
func _enter(next: Phase, duration: float) -> void:
	phase = next
	_time_left = duration
	_update_text()


# Aktualizuje licznik życia i wyjaśnia działanie, którego wymaga aktualna faza.
func _update_text() -> void:
	counter.text = "The Clockkeeper    %d / %d" % [health, MAX_HEALTH]
	match phase:
		Phase.TRACKING:
			status.text = "The beam is tracking you · Keep moving"
		Phase.WARNING:
			status.text = "Floor sweep · Jump clear of the marked lanes!" if health == 1 else "The beam is locked · Get out of the marked lane"
		Phase.STRIKE:
			status.text = "Beam firing!"
		Phase.OPEN:
			status.text = "Core exposed · Bounce, then land on the green core"
		Phase.RECOVER:
			status.text = "Core cracked · Get ready for the next strike"
		Phase.DEFEATED:
			status.text = "The Clockkeeper is down · Take the exit"


# Rysuje tarczę, kolor rdzenia, ostrza oraz zapowiedzi laserów. Stan walki określa ich widoczność.
func _draw() -> void:
	var brass := Color("#ba8253")
	var trim := Color("#ffe0a2")
	var stone := Color("#352b46")
	draw_circle(CENTER, 101.0, stone, true, -1.0, true)
	draw_circle(CENTER, 91.0, brass, false, 12.0, true)
	for i in range(12):
		var direction := Vector2.UP.rotated(i * TAU / 12.0)
		draw_line(CENTER + direction * 70.0, CENTER + direction * 84.0, trim, 3.0, true)
	var hand := Vector2.UP.rotated(Time.get_ticks_msec() * 0.002)
	draw_line(CENTER, CENTER + hand * 64.0, trim, 5.0, true)
	var core_color := Color("#f2b05b")
	if phase == Phase.OPEN:
		core_color = Color("#78ffc8")
	elif phase == Phase.DEFEATED:
		core_color = Color("#688598")
	draw_circle(CENTER, 32.0, core_color, true, -1.0, true)
	draw_circle(CENTER, 25.0, stone, false, 3.0, true)
	if phase == Phase.OPEN and health <= 3:
		var sweep := Vector2.from_angle(_sweep_angle)
		draw_line(CENTER + sweep * 47.0, CENTER + sweep * 114.0, Color("#ff6b4d"), 8.0, true)
		draw_circle(CENTER + sweep * 114.0, 5.0, trim)
		if health == 1:
			draw_line(CENTER - sweep * 47.0, CENTER - sweep * 96.0, Color("#ff875a"), 7.0, true)
			draw_circle(CENTER - sweep * 96.0, 4.0, trim)
	if phase in [Phase.TRACKING, Phase.WARNING, Phase.STRIKE]:
		var intensity := 0.22 if phase == Phase.TRACKING else 0.53
		if phase == Phase.STRIKE:
			intensity = 0.93
		for lane in _lanes:
			var rect := Rect2(lane - LANE_HALF_WIDTH, ARENA_TOP, LANE_HALF_WIDTH * 2.0, ARENA_BOTTOM - ARENA_TOP)
			draw_rect(rect, Color(1.0, 0.32, 0.19, intensity))
			draw_rect(rect, Color(1.0, 0.77, 0.42, intensity), false, 2.0)
		if health == 1 and phase != Phase.TRACKING:
			var floor_band := Rect2(-80.0, -33.0, 680.0, 41.0)
			draw_rect(floor_band, Color(1.0, 0.42, 0.18, intensity))
			draw_rect(floor_band, Color(1.0, 0.83, 0.52, intensity), false, 2.0)
