extends Node

@export var max_agents = 50
@export var npc_scene = preload("res://scenes/NPCCar.tscn")
@onready var map_manager = get_node("../MapManager")
@onready var player = get_node("../Car")

var active_agents = []

func _process(_delta):
	# 1. Usuń agentów, którzy wyjechali za daleko (poza załadowane chunki)
	for agent in active_agents:
		if is_instance_valid(agent):
			var dist = agent.global_position.distance_to(player.global_position)
			if dist > map_manager.load_radius * map_manager.chunk_size_px * 1.5:
				despawn_agent(agent)

	# 2. Jeśli brakuje agentów, zespawnuj nowych
	if active_agents.size() < max_agents and map_manager.road_network.size() > 0:
		spawn_random_agent()

func spawn_random_agent():
	var nodes = map_manager.road_network.keys()
	var spawn_node = nodes.pick_random()
	
	# 1. Sprawdź czy miejsce jest wolne (używając fizyki)
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
	# Opcjonalnie: sprawdź czy spawn_node jest blisko gracza, żeby nie spawnować na drugim końcu mapy
	
	var road_data = map_manager.road_network[spawn_node].pick_random()
	var npc = npc_scene.instantiate()
	add_child(npc)
	
	# Przekazujemy punkty ORAZ status oneway do setup
	npc.setup(road_data.points, map_manager, road_data.oneway)
	# --- NOWOŚĆ: Wyłączenie kolizji NPC na start ---
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
