extends Node2D

var start_pos_px = Vector2(-18100, 50860)
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
	# VPS odpala się jako headless i od razu stawia serwer
	if DisplayServer.get_name() == "headless":
		run_as_dedicated_server()
	else:
		print("[GRA] Uruchomiono jako klient. Oczekiwanie na połączenie z menu...")

# =============================================================================
# LOGIKA VPS (SERWER)
# =============================================================================
func run_as_dedicated_server():
	print("\n=== [SERWER] URUCHAMIANIE SERWERA NA VPS ===")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(10567, 32)
	
	if error != OK:
		print("Błąd startu serwera: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	print("[SERWER] Serwer gotowy, nasłuchuje na porcie 10567.")
	
	if traffic_manager:
		traffic_manager.setup_mode(true)

func _on_player_connected(id: int):
	print("Gracz dołączył do pokoju. ID: ", id)
	var police_scene = load("res://scenes/PoliceMultiplayer/police_multiplayer.tscn")
	
	# ZABEZPIECZENIE: Jeśli scena się nie załaduje, nie wysypuj serwera
	if police_scene == null:
		print("[BŁĄD SERWERA] Nie można załadować sceny police_multiplayer.tscn! Sprawdź assety.")
		return
		
	var car = police_scene.instantiate()
	car.name = str(id)
	add_child(car)
	var player_spawn = start_pos_px
	if traffic_manager and traffic_manager.has_method("get_player_spawn_position"):
		player_spawn = traffic_manager.get_player_spawn_position()
	car.global_position = player_spawn

func _on_player_disconnected(id: int):
	print("Gracz opuścił pokój. ID: ", id)
	var car = get_node_or_null(str(id))
	if car:
		car.queue_free()
	
	# ZABEZPIECZENIE: Jeśli to był ostatni gracz, resetujemy sesję gry
	print(multiplayer.get_peers().size())
	if multiplayer.get_peers().size() == 0:
		print("jest")
		reset_game_session()

# Nowa funkcja czyszcząca stan świata na serwerze
func reset_game_session():
	print("[SERWER] Brak aktywnych graczy. Resetowanie stanu gry...")
	is_changing_scene = false # Resetujemy flagę, aby nowa rozgrywka mogła się zakończyć
	
	var boss = get_tree().get_first_node_in_group("uciekinier")
	if is_instance_valid(boss) and boss.has_method("reset_to_start"):
		boss.reset_to_start()

# =============================================================================
# LOGIKA GRACZA (KLIENT)
# =============================================================================
func run_as_client():
	print("\n=== [KLIENT] INICJOWANIE POŁĄCZENIA ===")
	setup_ui()
	
	if map_manager:
		map_manager.night_mode = true

	var peer = ENetMultiplayerPeer.new()
	var target_ip = "83.168.89.116"
	
	print("[KLIENT] Łączenie z: ", target_ip, ":10567")
	peer.create_client(target_ip, 10567) 
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(func(): 
		print("[KLIENT] Połączono z VPS pomyślnie!")
		if coords_label: coords_label.text = "POŁĄCZONO Z SERWEREM VPS"
	)
	multiplayer.connection_failed.connect(func(): 
		print("[KLIENT] Błąd połączenia z VPS.")
		if coords_label: coords_label.text = "BŁĄD: Serwer nie odpowiada"
	)

# =============================================================================
# PĘTLA PROCESU, RPC I UI (Zostają bez zmian, tak jak miałeś)
# =============================================================================
func _process(_delta):
	if DisplayServer.get_name() == "headless":
		_process_server()
	else:
		_process_client()

func _process_server():
	if is_changing_scene: return
	var boss = get_tree().get_first_node_in_group("uciekinier")
	if is_instance_valid(boss):
		var reached_end_of_path = boss.reached_end
		var is_close_and_blocked = false
		var closest_police_id: int = -1
		var closest_dist: float = INF
		var police_cars = get_tree().get_nodes_in_group("police")
		for police in police_cars:
			if is_instance_valid(police):
				var dist_m = boss.global_position.distance_to(police.global_position) / 20.0
				# Śledź kto jest najbliżej (zwycięzca)
				if dist_m < closest_dist:
					closest_dist = dist_m
					closest_police_id = str(police.name).to_int()
				if dist_m < 7.0 and boss.real_speed < 30.0:
					is_close_and_blocked = true
		if is_close_and_blocked or reached_end_of_path:
			is_changing_scene = true
			print("[SERWER] Koniec gry. Zwycięzca: ", closest_police_id, ". Wysyłam RPC.")
			rpc("trigger_end_game", closest_police_id)

func _process_client():
	if is_changing_scene: return
	if not is_instance_valid(local_player):
		var my_id = multiplayer.get_unique_id()
		local_player = get_node_or_null(str(my_id))
		if is_instance_valid(local_player) and map_manager:
			map_manager.player = local_player
			var start_for_map = start_pos_px
			if traffic_manager and traffic_manager.has_method("get_player_spawn_position"):
				start_for_map = traffic_manager.get_player_spawn_position()
			map_manager.initialize_map(start_for_map)
		return
	var boss = get_tree().get_first_node_in_group("uciekinier")
	if is_instance_valid(boss):
		var dist_to_boss = local_player.global_position.distance_to(boss.global_position)
		var dist_m = dist_to_boss / 20.0
		# Sprawdzamy najpierw, czy current_scene w ogóle istnieje
		var curr_scene = get_tree().current_scene
		if curr_scene and curr_scene.get("map") != null:
			curr_scene.map.set_player(local_player.global_position, local_player.rotation)
			curr_scene.map.set_target(boss.global_position)
		var dist_vec = boss.global_position - local_player.global_position
		arrow_sprite.rotation = dist_vec.angle() - local_player.rotation
		coords_label.text = "POŚCIG SIECIOWY\nDYSTANS DO CELU: %d m" % int(dist_m)
	else:
		coords_label.text = "OCZEKIWANIE NA START..."

@rpc("authority", "call_local", "reliable")
func trigger_end_game(winner_id: int = -1):
	# Zabezpieczenie przed podwójnym wywołaniem RPC
	if is_changing_scene:
		return
	# Serwer headless nie odgrywa cutsceny
	if DisplayServer.get_name() == "headless":
		return
	# Sprawdź czy to my wygraliśmy wyścig
	var my_id = multiplayer.get_unique_id()
	if winner_id != -1 and my_id != winner_id:
		GameConfig.multiplayer_loser = true
		print("[KLIENT] Przegrałeś wyścig! Zwycięzca: ", winner_id)
	else:
		GameConfig.multiplayer_loser = false
		print("[KLIENT] Wygrałeś wyścig!")
	play_cutscene_sequence()

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
	coords_label.text = "ŁĄCZENIE..."
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
	
	# --- CUTSCENA Z ZABEZPIECZENIAMI ---
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await tween.finished
	if not is_inside_tree(): return  # GUARD: węzeł mógł zostać usunięty
	
	video_player.modulate.a = 1.0
	video_player.play()
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	
	var tree = get_tree()
	if tree == null: return  # GUARD
	await tree.create_timer(2.0).timeout
	if not is_inside_tree(): return  # GUARD
	
	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
	await tween_out.finished
	if not is_inside_tree(): return  # GUARD
	
	# === ROZŁĄCZENIE MULTIPLAYER ===
	print("[KLIENT] Rozłączanie z serwera przed przejściem do sceny 8...")
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	print("[KLIENT] Rozłączono. Ładowanie sceny 8...")
	
	# === RĘCZNA ZMIANA SCENY ===
	# Scena multiplayer była dodana ręcznie do root (via add_child w multiplayer_wybór.gd),
	# a NIE przez change_scene_to_file(). Przez to change_scene_to_file() nie usuwa
	# starej sceny — jej CanvasLayer (layer 100) z czarnym fade_rect zasłania scenę 8.
	# Musimy ręcznie załadować scenę 8 i wyczyścić starą.
	
	tree = get_tree()
	if tree == null: return  # GUARD
	var root = tree.root
	
	# Bezpieczne załadowanie sceny 8
	var scene_8_res = load("res://scenes/scena_8.tscn")
	if scene_8_res == null:
		push_error("[CRITICAL] Nie można załadować scena_8.tscn!")
		return
	var scene_8 = scene_8_res.instantiate()
	
	# Bezpieczne znalezienie nadrzędnego węzła (RootMulti)
	var root_multi = self
	var safety = 0
	while root_multi.get_parent() != null and root_multi.get_parent() != root and safety < 50:
		root_multi = root_multi.get_parent()
		safety += 1
	
	if root_multi.get_parent() != root:
		push_error("[CRITICAL] Nie można znaleźć root_multi! Fallback: dodaję scenę 8 bezpośrednio.")
		root.add_child(scene_8)
		tree.current_scene = scene_8
		return
	
	# Wyczyść stary current_scene jeśli istnieje i jest prawidłowy
	if is_instance_valid(tree.current_scene) and tree.current_scene != root_multi:
		tree.current_scene.queue_free()
	
	# Dodaj scenę 8 jako nową current_scene
	root.add_child(scene_8)
	tree.current_scene = scene_8
	
	# Usuń starą scenę multiplayer (RootMulti wraz ze wszystkimi dziećmi, w tym self)
	# queue_free jest deferred — funkcja wykona się do końca przed faktycznym zwolnieniem
	root_multi.queue_free()
