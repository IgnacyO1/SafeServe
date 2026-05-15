extends Node2D

# --- UNIKALNE USTAWIENIA TEJ TRASY ---
var start_pos_px = Vector2(-2356, 44164) 
var target_pos_px = Vector2(-62668, 73086)
var cutscene_path = "res://assets/Videos/cuscean1ver4.ogv" # <--- TU WPISZ ŚCIEŻKĘ DO PLIKU

@onready var player = $Car
@onready var map_manager = $MapManager

var coords_label: Label
var arrow_sprite: Polygon2D
var fade_rect: ColorRect
var video_player: VideoStreamPlayer
var is_changing_scene = false

func _ready():
	if not player: return
	setup_level()
	setup_ui()
	await get_tree().process_frame
	get_tree().current_scene.map.set_target(target_pos_px)

func setup_level():
	# Mówimy managerowi, gdzie ma zacząć generować świat
	if map_manager:
		map_manager.initialize_map(start_pos_px)

func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	# [KOD LABELA I STRZAŁKI BEZ ZMIAN]
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	canvas.add_child(coords_label)
	
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	arrow_sprite.polygon = PackedVector2Array([Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)])
	arrow_sprite.color = Color.RED
	arrow_container.add_child(arrow_sprite)

	# --- NOWOŚĆ: VIDEO PLAYER ---
	video_player = VideoStreamPlayer.new()
	video_player.stream = load(cutscene_path)
	video_player.expand = true
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.modulate.a = 0 # Ukryty na początku
	canvas.add_child(video_player)
	
	# Czarny ekran (na samej górze, layer 100 i ostatni child w canvas)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_rect)

func _process(_delta):

	if is_changing_scene: return # Blokada process podczas zmiany sceny
	
	if is_instance_valid(player) and arrow_sprite:
		var player_pos = player.global_position
		var dist_vec = target_pos_px - player_pos
		var dist_m = dist_vec.length() / 20.0
		get_tree().current_scene.map.set_player(player_pos, player.rotation)
		
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
			play_cutscene_sequence()
		

func play_cutscene_sequence():
	is_changing_scene = true
	
	# 1. Ściemnienie gry (Fade Out)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween.finished # Czekamy aż zgaśnie
	
	# 2. Przygotowanie wideo pod czarną zasłoną
	video_player.modulate.a = 1.0
	video_player.play()
	
	# 3. Rozjaśnienie wideo (Fade In wideo)
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	# 4. Czekamy aż film się skończy (lub używamy timer na 2s)
	await get_tree().create_timer(2.0).timeout
	
	# 5. Ściemnienie wideo (Fade Out przed zmianą sceny)
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	
	await tween_out.finished
	get_tree().change_scene_to_file("res://scenes/scena_3.tscn")
