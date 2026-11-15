# Odtwarza utwór przypisany do sceny. Usunięcie sceny zatrzymuje jej muzykę.
extends AudioStreamPlayer


# Zapętla cały plik MP3 przed rozpoczęciem odtwarzania.
func _ready() -> void:
	var track := stream as AudioStreamMP3
	if track:
		track.loop = true
		play()
