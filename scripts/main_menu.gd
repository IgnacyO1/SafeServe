extends Node2D

# --- KONFIGURACJA LOADING SCREENA ---
var loading_bg_tex = preload("res://assets/graphics/loading_background.png") 
var tips = [
	"TIP: Używaj siekiery, aby wyważyć zablokowane drzwi.",
	"TIP: Gaszenie ognia zajmuje czas, planuj trasę!",
	"TIP: Babcia czeka na ratunek w północnej części budynku.",
	"TIP: Czarna skrzynka jest kluczowa dla misji.",
	"TIP: Masz ograniczony czas, nie marnuj go na stanie w miejscu!"
]

var loading_layer: CanvasLayer = null
# POPRAWKA 1: Zmiana typu na ProgressBar (to naprawi błąd przypisania)
var progress_bar: ProgressBar = null 
var tip_label: Label = null

func _on_button_pressed(): 
	_uruchom_loading_screen()

func _uruchom_loading_screen():
	# 1. Tworzymy warstwę
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 100
	add_child(loading_layer)

	# 2. Tło
	var bg = TextureRect.new()
	bg.texture = loading_bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_layer.add_child(bg)

	# 3. Pasek postępu
	var bar_width = 800
	var bar_height = 40
	
	progress_bar = ProgressBar.new() # Przypisanie teraz zadziała
	progress_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	
	progress_bar.offset_left = -bar_width / 2
	progress_bar.offset_right = bar_width / 2
	progress_bar.offset_top = -100
	progress_bar.offset_bottom = -100 + bar_height
	
	progress_bar.value = 0
	loading_layer.add_child(progress_bar)

	# 4. Tekst z poradami
	tip_label = Label.new()
	tip_label.text = tips[randi() % tips.size()]
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	
	tip_label.offset_top = -180 
	tip_label.offset_bottom = -140
	
	tip_label.set("theme_override_font_sizes/font_size", 24)
	tip_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	tip_label.set("theme_override_constants/outline_size", 5)
	loading_layer.add_child(tip_label)

	# 5. Start
	_proces_ladowania()

func _proces_ladowania():
	var czas_ladowania = 10.0
	var kroki = 100
	var odstep = czas_ladowania / kroki

	for i in range(kroki + 1):
		if not is_instance_valid(progress_bar): break
		progress_bar.value = i
		if i % 30 == 0 and i > 0:
			tip_label.text = tips[randi() % tips.size()]
		await get_tree().create_timer(odstep).timeout

	get_tree().change_scene_to_file("res://scenes/scena_1.tscn")

func _on_button_2_pressed(): # Kontynuacja
	pass

func _on_button_3_pressed(): # Ustawienia
	pass

func _on_button_4_pressed(): # Wyjście 
	get_tree().quit()
