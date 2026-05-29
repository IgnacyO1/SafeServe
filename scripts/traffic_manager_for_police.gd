extends Node

@export var max_agents = 10
@export var npc_scene = preload("res://scenes/NPCCar.tscn")
@export var uciekinier_scene = preload("res://scenes/uciekinier.tscn") # <--- DODAJ TO

@onready var map_manager = get_node("../MapManager")
@onready var player = get_node("../Police")

var active_agents = []
var is_pursuit_mode = false # <--- Zmienna sterująca trybem

var uciekinier_spawned = false

func setup_mode(pursuit_active: bool):
	is_pursuit_mode = pursuit_active
	print("TRYB POŚCIGU USTAWIONY NA: ", pursuit_active)
	
	if is_pursuit_mode:
		# Czyścimy wszystko co zdążyło się zespawnować
		for agent in active_agents:
			if is_instance_valid(agent): agent.queue_free()
		active_agents.clear()
		uciekinier_spawned = false # Pozwalamy na spawn bossa

func _process(_delta):
	if is_pursuit_mode:
		# Spawnuje bossa TYLKO RAZ, gdy tylko map_manager będzie gotowy (będzie miał skalę itp.)
		if not uciekinier_spawned and map_manager:
			spawn_boss_car()
			uciekinier_spawned = true
		return # KLUCZOWE: Nie idź dalej do spawnowania NPC!
	# Reszta kodu spawnowania cywilów...
	for agent in active_agents:
		if is_instance_valid(agent):
			var dist = agent.global_position.distance_to(player.global_position)
			if dist > map_manager.load_radius * map_manager.chunk_size_px * 1.5:
				despawn_agent(agent)

	if active_agents.size() < max_agents and map_manager.road_network.size() > 0:
		spawn_random_agent()

func spawn_boss_car():
	var boss = uciekinier_scene.instantiate()
	add_child(boss)
	# Boss nie potrzebuje losowych punktów z sieci, bo ma je wbudowane w skrypcie
	boss.setup([], map_manager, false) 
	active_agents.append(boss)
	print("SPAWNED: Cyberkrab gotowy do ucieczki!")

func spawn_random_agent():
	if map_manager.road_network_nodes.is_empty():
		return

	# Spróbuj do 5 razy znaleźć węzeł w odpowiedniej odległości od gracza
	var spawn_node = Vector2.ZERO
	var found = false
	var max_spawn_dist = map_manager.load_radius * map_manager.chunk_size_px * 1.25
	
	for i in range(5):
		var node = map_manager.road_network_nodes.pick_random()
		var dist = node.distance_to(player.global_position)
		if dist <= max_spawn_dist and dist >= 500.0:
			spawn_node = node
			found = true
			break
			
	if not found:
		return

	# Sprawdź czy miejsce jest wolne (używając fizyki)
	var space_state = get_viewport().find_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Używamy małego koła do sprawdzenia czy droga jest wolna
	var circle = CircleShape2D.new()
	circle.radius = 50.0 # rozmiar auta w skali
	query.shape = circle
	query.transform = Transform2D(0, spawn_node)
	query.collision_mask = 1 | 2 # Sprawdzamy czy nie ma tam budynku lub innego auta
	
	var result = space_state.intersect_shape(query)
	if not result.is_empty():
		return # Miejsce zajęte, spróbuj w następnej klatce
	
	var road_data = map_manager.road_network[spawn_node].pick_random()
	var npc = npc_scene.instantiate()
	add_child(npc)
	
	# Przekazujemy punkty ORAZ status oneway do setup
	npc.setup(road_data.points, map_manager, road_data.oneway)
	var original_mask = npc.collision_mask
	npc.collision_mask = 0
	
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(npc):
			npc.collision_mask = original_mask
	)
	
	active_agents.append(npc)
	

func despawn_agent(agent):
	active_agents.erase(agent)
	agent.queue_free()
