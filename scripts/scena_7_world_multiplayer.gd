extends Node2D

var start_pos_px = Vector2(-40671, 98832)
var cutscene_path = "res://assets/Videos/spin.ogv"

var local_player: CharacterBody2D = null 

@onready var map_manager = $MapManager
@onready var traffic_manager = $"Traffic Manager"

var coords_label: Label
var arrow_sprite: Polygon2D
var fade_rect: ColorRect
var night_overlay: ColorRect
var video_player: VideoStreamPlayer
var is_changing_scene = false

func _ready():
	# AUTOMATYCZNE WYKRYWANIE CONFIGU (SERWER VS KLIENT)
	# Jeśli uruchamiamy projekt z flgą --headless (np. na serwerze Linux VPS)
	if DisplayServer.get_name() == "headless":
		run_as_dedicated_server()
	else:
		run_as_client()

# =============================================================================
# LOGIKA SERWERA DEDYKOWANEGO
# =============================================================================
func run_as_dedicated_server():
	print("--- URUCHAMIANIE SERWERA DEDYKOWANEGO ---")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(10567, 32) # Port 10567, max 32 graczy
	
	if error != OK:
		print("Błąd startu serwera: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	
	# Podpinamy zdarzenia sieciowe serwera
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Serwer odpala uciekiniera (Bossa)
	if traffic_manager:
		traffic_manager.setup_mode(true)

func _on_player_connected(id: int):
	print("Gracz połączony z ID: ", id)
	# Spawnowanie radiowozu na serwerze dla nowego gracza
	var police_scene = load("res://scenes/PoliceMultiplayer/police_multiplayer.tscn")
	var car = police_scene.instantiate()
	car.name = str(id) # Nazwa węzła to ID sieciowe gracza
	add_child(car)
	
	# Nadajemy autorytet nad fizyką autka temu konkretnemu klientowi
	car.set_multiplayer_authority(id)
	car.global_position = start_pos_px

func _on_player_disconnected(id: int):
	print("Gracz rozłączony: ", id)
	var car = get_node_or_null(str(id))
	if car:
		car.queue_free()

# =============================================================================
# LOGIKA KLIENTA (GRACZA)
# =============================================================================
func run_as_client():
	print("--- URUCHAMIANIE KLIENTA ---")
	setup_ui()
	
	if map_manager:
		map_manager.night_mode = true

	var peer = ENetMultiplayerPeer.new()
	# Zmień "127.0.0.1" na adres IP swojego VPS, gdy wrzucisz serwer w sieć
	peer.create_client("127.0.0.1", 10567) 
	multiplayer.multiplayer_peer = peer

func _process(_delta):
	# Jeśli to serwer headless, nie przetwarzamy interfejsu ani kamery
	if DisplayServer.get_name() == "headless": return
	if is_changing_scene: return
	
	# Szukamy naszego własnego pojazdu na scenie
	if not is_instance_valid(local_player):
		var my_id = multiplayer.get_unique_id()
		local_player = get_node_or_null(str(my_id))
		
		# Gdy serwer zreplikuje nasze auto, aktywujemy pod nie MapManager
		if is_instance_valid(local_player) and map_manager:
			map_manager.player = local_player
			map_manager.initialize_map(start_pos_px)
		return

	var boss = get_tree().get_first_node_in_group("uciekinier")
	
	if is_instance_valid(boss):
		var dist_to_boss = local_player.global_position.distance_to(boss.global_position)
		var dist_m = dist_to_boss / 20.0
		
		# Aktualizacja radaru w HUD
		if get_tree().current_scene.get("map") != null:
			get_tree().current_scene.map.set_player(local_player.global_position, local_player.rotation)
			get_tree().current_scene.map.set_target(boss.global_position)

		# Strzałka kierunkowa HUD
		var dist_vec = boss.global_position - local_player.global_position
		arrow_sprite.rotation = dist_vec.angle() - local_player.rotation
		coords_label.text = "POŚCIG SIECIOWY\nDYSTANS DO CELU: %d m" % int(dist_m)

		# Każdy klient lokalnie sprawdza zreplikowane dane bosa, żeby odpalić cutscenę
		var is_close_and_blocked = (dist_m < 7.0 and boss.real_speed < 30.0)
		var reached_end_of_path = (boss.reached_end or boss.speed == 0.0)

		if is_close_and_blocked or reached_end_of_path:
			play_cutscene_sequence()
	else:
		coords_label.text = "OCZEKIWANIE NA SYGNAŁ CYBERKRABA..."

# =============================================================================
# FUNKCJE UI I CUTSCENKI (Tylko dla klientów)
# =============================================================================
func setup_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	night_overlay = ColorRect.new()
	night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night_overlay.color = Color(0.04, 0.10, 0.18, 0.36)
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_overlay.z_index = -5
	canvas.add_child(night_overlay)
	
	coords_label = Label.new()
	coords_label.position = Vector2(20, 20)
	coords_label.add_theme_font_size_override("font_size", 24)
	coords_label.modulate = Color(0.8, 0.95, 1.0, 1.0)
	canvas.add_child(coords_label)
	
	var arrow_container = Marker2D.new()
	arrow_container.position = Vector2(get_viewport_rect().size.x - 100, 100)
	canvas.add_child(arrow_container)
	
	arrow_sprite = Polygon2D.new()
	arrow_sprite.polygon = PackedVector2Array([Vector2(0, -25), Vector2(15, 15), Vector2(0, 5), Vector2(-15, 15)])
	arrow_sprite.color = Color(0.8, 0.9, 1.0, 1.0)
	arrow_container.add_child(arrow_sprite)

	video_player = VideoStreamPlayer.new()
	video_player.stream = load(cutscene_path)
	video_player.expand = true
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.modulate.a = 0
	canvas.add_child(video_player)
	
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fade_rect)

func play_cutscene_sequence():
	is_changing_scene = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	
	video_player.modulate.a = 1.0
	video_player.play()
	
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	await get_tree().create_timer(2.0).timeout
	
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await tween_out.finished
	get_tree().change_scene_to_file("res://scenes/scena_8.tscn")
