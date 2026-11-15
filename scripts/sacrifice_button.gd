# Opcjonalny przycisk otwierający przejście za cenę jednego życia.
extends Area2D

# Przycisk-ofiara: kosztuje 1 życie, ale otwiera przejście bez respawnu
signal sacrificed

var _used := false

@onready var sfx: AudioStreamPlayer2D = get_node_or_null("Sfx")


# Podłącza sygnał kontaktu tylko wtedy, gdy scena jeszcze tego nie zrobiła.
func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


# Raz odejmuje koszt, odtwarza dźwięk i informuje odbiorcę sygnału o aktywacji.
func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	# Koszt: 1 życie, ale bez respawnu — gracz zostaje na miejscu
	GameState.current_health = max(GameState.current_health - 1, 0)
	GameState._refresh_hearts()
	if sfx:
		sfx.play()
	sacrificed.emit()
