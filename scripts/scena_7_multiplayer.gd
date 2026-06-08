extends "res://scripts/radio.gd"


# Gdy węzeł trafi do drzewa sceny.
func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_7_multiplayer.tscn")
	if DisplayServer.get_name() == "headless":
		return
	var sekundy_przed_wiadmoscia = randi_range(5, 10) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout
	if is_inside_tree() and is_instance_valid(radio):
		radio.show_radio_message("Szybciej, szybciej, bo nam skurczybyk ucieknie!", "res://assets/Sounds/scena_6_krotkofalowka.wav") # Tu wystarczy zmienić ścieżkę
