extends "res://scripts/radio.gd"


# Gdy węzeł trafi do drzewa sceny.
func _ready() -> void:
	GameConfig.save_level("res://scenes/scena_7.tscn")
	
	# --- Pierwsza wiadomość (stara logika) ---
	var sekundy_przed_wiadmoscia = randi_range(5, 10) # Tu ilość sekund, po której pojawia się popup
	await get_tree().create_timer(sekundy_przed_wiadmoscia).timeout
	radio.show_radio_message("Szybciej, szybciej, bo nam skurczybyk ucieknie!", "res://assets/Sounds/scena_6_krotkofalowka.wav") # Tu wystarczy zmienić ścieżkę
	
	# --- Druga wiadomość (Megafon - nowa logika) ---
	# Losujemy czas między 20 a 40 sekund od momentu włączenia sceny
	var sekundy_megafon = randi_range(20, 40)
	
	# Ponieważ powyższy await zabrał już 'sekundy_przed_wiadmoscia' czasu,
	# musimy odjąć ten czas, aby odliczanie było liczone OD WŁĄCZENIA SCENY, a nie od pierwszej wiadomości.
	var pozostaly_czas = sekundy_megafon - sekundy_przed_wiadmoscia
	
	# Na wypadek, gdyby wylosowany czas megafonu był mniejszy (co przy 20-40 vs 5-10 się nie stanie, ale to dobra praktyka)
	if pozostaly_czas > 0:
		await get_tree().create_timer(pozostaly_czas).timeout
	
	odtworz_dzwiek_megafonu()


# Funkcja, która dynamicznie tworzy odtwarzacz audio i puszcza dźwięk
func odtworz_dzwiek_megafonu() -> void:
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Ładowanie pliku dźwiękowego
	audio_player.stream = load("res://assets/Sounds/stój_megaphone.wav")
	audio_player.play()
	
	# Dobra praktyka: usuwamy obiekt z pamięci, kiedy skończy grać
	audio_player.finished.connect(func(): audio_player.queue_free())
