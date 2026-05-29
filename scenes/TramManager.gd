extends Node

@export var max_trams = 3
@export var tram_scene = preload("res://scenes/Tram/Tram.tscn")
@onready var map_manager = get_node("../MapManager")
@onready var player = get_node("../Car")

var active_trams = []

func _process(_delta):
	# Despawn za daleko
	for i in range(active_trams.size() - 1, -1, -1):
		var tram = active_trams[i]
		if is_instance_valid(tram) and tram.segments[0].global_position.distance_to(player.global_position) > 4000.0:
			active_trams.remove_at(i)
			tram.queue_free()

	# Spawn jeśli brakuje
	if active_trams.size() < max_trams and map_manager.tram_nodes.size() > 0:
		spawn_tram()

# W TramManager.gd
func spawn_tram():
	var valid_nodes = []
	for node in map_manager.tram_nodes:
		var dist = node.distance_to(player.global_position)
		if dist >= 400.0 and dist <= 3000.0: # Bezpieczny dystans spawnu
			valid_nodes.append(node)
	
	if valid_nodes.is_empty():
		return

	var spawn_node = valid_nodes.pick_random()
	var tram = tram_scene.instantiate()
	
	# DODAJEMY JAKO DZIECKO MAP MANAGERA
	map_manager.add_child(tram)
	
	tram.init_tram(spawn_node, map_manager)
	active_trams.append(tram)
