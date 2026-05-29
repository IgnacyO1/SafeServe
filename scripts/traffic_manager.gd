extends Node

@export var max_agents = 10
@export var npc_scene = preload("res://scenes/NPCCar.tscn")
@onready var map_manager = get_node("../MapManager")
@onready var player = get_node("../Car")

var active_agents = []

func _process(_delta):
	# Usuń agentów, którzy wyjechali za daleko (poza załadowane chunki)
	for agent in active_agents:
		if is_instance_valid(agent):
			var dist = agent.global_position.distance_to(player.global_position)
			if dist > map_manager.load_radius * map_manager.chunk_size_px * 1.5:
				despawn_agent(agent)

	# Jeśli brakuje agentów, zespawnuj nowych
	if active_agents.size() < max_agents and map_manager.road_network.size() > 0:
		spawn_random_agent()

func spawn_random_agent():
	if map_manager.major_nodes.is_empty():
		return

	# Spróbuj do 5 razy znaleźć węzeł w odpowiedniej odległości od gracza
	var spawn_node = Vector2.ZERO
	var found = false
	var max_spawn_dist = map_manager.load_radius * map_manager.chunk_size_px * 1.25
	
	for i in range(5):
		var node = map_manager.major_nodes.pick_random()
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
	
	var circle = CircleShape2D.new()
	circle.radius = 50.0
	query.shape = circle
	query.transform = Transform2D(0, spawn_node)
	query.collision_mask = 1 | 2
	
	var result = space_state.intersect_shape(query)
	if not result.is_empty():
		return # Miejsce zajęte
	
	# 3. Z opcji wychodzących z tego węzła losujemy TYLKO tę, która jest główną drogą
	var options = map_manager.road_network[spawn_node]
	var major_options = []
	for opt in options:
		if opt.get("is_major", false):
			major_options.append(opt)
			
	var road_data = major_options.pick_random()
	
	# 4. Reszta kodu bez zmian (instancjonowanie i setup NPC)
	var npc = npc_scene.instantiate()
	add_child(npc)
	
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
