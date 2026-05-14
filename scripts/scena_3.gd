extends Node2D

# --- UNIKALNE USTAWIENIA TEJ TRASY ---
var start_pos_px = Vector2(-2356, 44164)
var target_pos_px = Vector2(-62668, 73086)

@onready var player = $Car
@onready var map_manager = $MapManager

var coords_label: Label
var arrow_sprite: Polygon2D
var fade_rect: ColorRect # Do efektu przejścia
var is_changing_scene = false # Flaga, żeby nie odpalić przejścia 100 razy

func _ready():
	if not player: return
	setup_level()
	setup_ui()

func setup_level():
	# Mówimy managerowi, gdzie ma zacząć generować świat
	if map_manager:
		map_manager.initialize_map(start_pos_px)

func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(coords_label)
	
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	arrow_sprite.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)
	])
	arrow_sprite.color = Color.RED
	arrow_container.add_child(arrow_sprite)
	
	# czarny ekran do przejśćia później
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0) # Startujemy od przeźroczystego
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Żeby nie blokował kliknięć
	canvas.add_child(fade_rect)

func _process(_delta):
	if is_changing_scene: return # Blokada process podczas zmiany sceny
	
	if is_instance_valid(player) and arrow_sprite:
		var player_pos = player.global_position
		var dist_vec = target_pos_px - player_pos
		var dist_m = dist_vec.length() / 20.0
		
		# Aktualizacja UI
		coords_label.text = "GPS: %d, %d\nDO CELU: %d m" % [player_pos.x, player_pos.y, int(dist_m)]
		
		# Rotacja strzałki (Twoja sprawdzona metoda)
		arrow_sprite.rotation = dist_vec.angle() - player.rotation

		# --- LOGIKA DOJAZDU DO CELU ---
		# Sprawdzamy dystans (< 5m) i czy auto prawie stoi (prędkość < 10)
		var current_speed = 0.0
		if player is RigidBody2D:
			current_speed = player.linear_velocity.length()
		elif "velocity" in player: # Jeśli to CharacterBody2D
			current_speed = player.velocity.length()

		if dist_m < 5.0 and current_speed < 10.0:
			finish_level()

func finish_level():
	is_changing_scene = true
	print("Cel osiągnięty! Przełączam na Scenę 4...")
	
	# ŁADNE PRZEJŚCIE (FADE OUT)
	var tween = create_tween()
	# Animujemy kolor fade_rect z przeźroczystego do czarnego w 1.5 sekundy
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.5)
	
	# Po zakończeniu animacji zmień scenę
	tween.finished.connect(func():
		get_tree().change_scene_to_file("res://scenes/scena_4.tscn") # Upewnij się co do ścieżki!
	)
