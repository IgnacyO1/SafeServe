extends "res://scripts/radio.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sekundy_przed_wiadmoscia = randi_range(10, 20) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout 
	radio.show_radio_message("Test message", "res://assets/Sounds/horn.mp3") # Tu wystarczy zmienić ścieżkę
