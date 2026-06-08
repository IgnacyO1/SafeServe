extends "res://scripts/radio.gd"


# Gdy węzeł trafi do drzewa sceny.
func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_7_multiplayer_version.tscn")
	if DisplayServer.get_name() == "headless":
		return
		
	# --- Pierwsza wiadomość ---
	var sekundy_przed_wiadmoscia = randi_range(5, 10) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout
	
	if is_inside_tree() and is_instance_valid(radio):
		radio.show_radio_message("Szybciej, szybciej, bo nam skurczybyk ucieknie!", "res://assets/Sounds/scena_6_krotkofalowka.wav") # Tu wystarczy zmienić ścieżkę
	
	# --- Druga wiadomość (Megafon) ---
	# Losujemy czas między 20 a 40 sekund od momentu włączenia sceny
	var sekundy_megafon = randi_range(20, 40)
	
	# Odejmujemy czas, który już minął na pierwszy komunikat
	var pozostaly_czas = sekundy_megafon - sekundy_przed_wiadmoscia
	
	if pozostaly_czas > 0:
		await get_tree().create_timer(pozostaly_czas).timeout
	
	# Bezpiecznik multiplayerowy: sprawdzamy, czy obiekt nadal istnieje w drzewie sceny
	if is_inside_tree():
		odtworz_dzwiek_megafonu()


# Funkcja dynamicznie tworząca odtwarzacz audio
func odtworz_dzwiek_megafonu() -> void:
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Ładowanie i odtwarzanie pliku dźwiękowego
	audio_player.stream = load("res://assets/Sounds/stój_megaphone.wav")
	audio_player.play()
	
	# Automatyczne usuwanie odtwarzacza po zakończeniu dźwięku
	audio_player.finished.connect(func(): audio_player.queue_free())
