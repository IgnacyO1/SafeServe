extends "res://scripts/radio.gd"


# Gdy węzeł trafi do drzewa sceny.
func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_4.tscn")
	var sekundy_przed_wiadmoscia = randi_range(3, 4) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout 
	radio.show_radio_message("Uff, sprawa załatwiona. Wracajmy do bazy!", "res://assets/Sounds/uffsprawazalatwiona.wav") # Tu wystarczy zmienić ścieżkę
