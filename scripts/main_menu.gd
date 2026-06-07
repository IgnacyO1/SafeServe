extends Node2D

# Konfiguracja LOADING SCREENA
var loading_bg_tex = preload("res://assets/graphics/loading_background.png") 
var tips = [
	"TIP: Gaszenie ognia zajmuje czas, planuj trasę!",
	"TIP: Starsza osoba czeka na ratunek w północnej części budynku.",
	"TIP: Masz ograniczony czas, nie marnuj go na stanie w miejscu!",
	"TIP: Jeździj głównymi drogami, nie będziesz się wderzał w budynki.",
	"TIP: Gdy przytrzymasz M, zobaczysz mapę.",
	"TIP: Jadąc ulicami, gdy wciśniesz H to zatrąbisz i samochody utworzą korytarz życia."
]

var loading_layer: CanvasLayer = null
var progress_bar: ProgressBar = null 
var tip_label: Label = null
var is_loading = false

func _on_button_pressed(): 
	if is_loading:
		return
	is_loading = true
	# Startujemy standardowo od ekranu ładowania
	_uruchom_loading_screen("res://scenes/scena_1.tscn")

func _uruchom_loading_screen(scene_path: String):
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 100
	add_child(loading_layer)

	# Tło
	var bg = TextureRect.new()
	bg.texture = loading_bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_layer.add_child(bg)

	# Pasek postępu
	var bar_width = 800
	var bar_height = 40
	
	progress_bar = ProgressBar.new() 
	progress_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	
	progress_bar.offset_left = -bar_width / 2
	progress_bar.offset_right = bar_width / 2
	progress_bar.offset_top = -100
	progress_bar.offset_bottom = -100 + bar_height
	
	progress_bar.value = 0
	loading_layer.add_child(progress_bar)

	# Tekst z poradami
	tip_label = Label.new()
	tip_label.text = tips[randi() % tips.size()]
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	
	tip_label.offset_top = -220 
	tip_label.offset_bottom = -160
	
	tip_label.set("theme_override_font_sizes/font_size", 36)
	tip_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	tip_label.set("theme_override_constants/outline_size", 8)
	loading_layer.add_child(tip_label)

	_proces_ladowania(scene_path)

func _proces_ladowania(scene_path: String):
	var progress = 0.0
	
	while progress < 100.0:
		if not is_instance_valid(progress_bar):
			break

		var increment = randf_range(2.7, 10.5)
		if progress > 90:
			increment *= 0.5

		progress += increment
		progress = min(progress, 100)
		progress_bar.value = progress

		if randi() % 12 == 0:
			tip_label.text = tips[randi() % tips.size()]

		var wait_time = randf_range(0.03, 0.05)
		if randi() % 10 == 0:
			wait_time += randf_range(0.15, 0.2)
		if randi() % 25 == 0:
			wait_time += randf_range(0.2, 0.5)

		await get_tree().create_timer(wait_time).timeout

	await get_tree().create_timer(0.1).timeout

	# Loading skończony -> kasujemy loading_layer
	if is_instance_valid(loading_layer):
		loading_layer.queue_free()
	
	# TERAZ odpalamy piękny ekran powitalny z efektami kinowymi
	_pokaz_ekran_powitalny_z_efektami(scene_path)

func _pokaz_ekran_powitalny_z_efektami(scene_path: String):
	var story_layer = CanvasLayer.new()
	story_layer.layer = 105
	add_child(story_layer)
	
	# Czarne tło (ustawiamy początkową przezroczystość na 0 do Fade In)
	var black_bg = ColorRect.new()
	black_bg.color = Color(0, 0, 0, 0)
	black_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	story_layer.add_child(black_bg)
	
	# Stylowy kontener na tekst
	var label = Label.new()
	label.text = "Cześć, Greg. To twój pierwszy dzień pracy na 112. Powodzenia."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Podkręcony wygląd tekstu
	label.set("theme_override_font_sizes/font_size", 38)
	label.set("theme_override_colors/font_color", Color.WHITE)
	label.modulate.a = 0.0 # Też startuje od niewidzialnego
	story_layer.add_child(label)
	
	# --- POBRANIE BUSU AUDIO ---
	# Jeśli masz osobny bus na muzykę, zmień "Master" na "Music"
	var bus_index = AudioServer.get_bus_index("Master") 
	
	# --- FADE IN (Płynne pojawianie się obrazu i ściszanie muzyki) ---
	var tween_in = create_tween().set_parallel(true)
	tween_in.tween_property(black_bg, "color:a", 1.0, 0.8) # Czarny ekran w 0.8s
	tween_in.tween_property(label, "modulate:a", 1.0, 1.2)   # Napis chwilę wolniej (1.2s)
	
	# Płynne ściszanie do -40 dB w czasie 1.2 sekundy (równo z napisem)
	tween_in.tween_method(
		func(volume): AudioServer.set_bus_volume_db(bus_index, volume),
		AudioServer.get_bus_volume_db(bus_index), # wartość początkowa (aktualna)
		-40.0,                                    # wartość docelowa
		1.2                                       # czas trwania w sekundach
	)
	
	await tween_in.finished
	
	# Czas na przeczytanie komunikatu (3 sekundy)
	await get_tree().create_timer(3.0).timeout
	
	# --- FADE OUT (Płynne znikanie do czerni przed nową sceną) ---
	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(label, "modulate:a", 0.0, 0.8) # Napis znika
	await tween_out.finished
	
	# Zmiana sceny w tle
	get_tree().change_scene_to_file(scene_path)
	
	# Ostateczne wyczyszczenie warstwy i odblokowanie stanu
	story_layer.queue_free()
	is_loading = false

func _on_button_2_pressed(): # Kontynuacja
	if is_loading:
		return
	is_loading = true
	var last_level = GameConfig.get_last_level()
	_uruchom_loading_screen(last_level)

func _on_button_3_pressed(): # Ustawienia
	get_tree().change_scene_to_file("res://scenes/ustawienia.tscn")

func _on_button_4_pressed(): # Wyjście 
	get_tree().quit()
