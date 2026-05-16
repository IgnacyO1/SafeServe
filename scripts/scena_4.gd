extends "res://scripts/radio.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sekundy_przed_wiadmoscia = randi_range(3, 4) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout 
	radio.show_radio_message("Uff, sprawa załatwiona. Wracajmy do bazy!", "res://assets/Sounds/uffsprawazalatwiona.wav") # Tu wystarczy zmienić ścieżkę
