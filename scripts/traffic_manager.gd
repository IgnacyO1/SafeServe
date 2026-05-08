extends Node

@export var max_agents = 10
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
	# Wybieramy losowy węzeł drogi, który jest blisko gracza
	var nodes = map_manager.road_network.keys()
	var spawn_node = nodes.pick_random()
	
	# Opcjonalnie: sprawdź czy spawn_node jest blisko gracza, żeby nie spawnować na drugim końcu mapy
	
	var start_road = map_manager.road_network[spawn_node].pick_random()
	var npc = npc_scene.instantiate()
	add_child(npc)
	npc.setup(start_road, map_manager)
	active_agents.append(npc)

func despawn_agent(agent):
	active_agents.erase(agent)
	agent.queue_free()
