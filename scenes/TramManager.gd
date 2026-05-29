extends Node

@export var max_trams = 3
@export var tram_scene = preload("res://scenes/Tram/Tram.tscn")
@onready var map_manager = get_node("../MapManager")
@onready var player = get_node("../Car")

var active_trams = []

func _process(_delta):
	# Despawn: usuwamy tramwaj TYLKO gdy jego pozycja startowa wypadła z załadowanych chunków
	# lub gdy awaryjnie odjechał absurdalnie daleko (np. błąd mapy > 6000px)
	for i in range(active_trams.size() - 1, -1, -1):
		var tram = active_trams[i]
		if is_instance_valid(tram):
			var track_node = tram.last_node # Ostatni węzeł ścieżki tramwaju
			var dist_to_player = tram.segments[0].global_position.distance_to(player.global_position)
			
			# Warunek: usuń jeśli chunk z torami przestał istnieć ALBO gdy tramwaj uciekł za daleko
			if (not map_manager.tram_network.has(track_node) and dist_to_player > 3500.0) or dist_to_player > 9000.0:
				active_trams.remove_at(i)
				tram.queue_free()

	# Spawn jeśli brakuje
	if active_trams.size() < max_trams and map_manager.tram_nodes.size() > 0:
		spawn_tram()

func spawn_tram():
	var valid_nodes = []
	
	for node in map_manager.tram_nodes:
		var dist_to_player = node.distance_to(player.global_position)
		
		# 1. Kontrola widoczności: Spawn tylko poza wzrokiem (min 1200px) i w granicach ładowania (max 3500px)
		if dist_to_player >= 1400.0:
			
			# 2. Anty-kolizja: Sprawdź czy inny tramwaj nie stoi/jedzie już na tym węźle
			var node_occupied = false
			for active_tram in active_trams:
				if is_instance_valid(active_tram):
					# Jeśli środek lub przód jakiegoś tramwaju jest za blisko tego punktu, odrzucamy węzeł
					if active_tram.segments[0].global_position.distance_to(node) < 1000.0:
						node_occupied = true
						break
			
			if not node_occupied:
				valid_nodes.append(node)
	
	if valid_nodes.is_empty():
		return

	var spawn_node = valid_nodes.pick_random()
	var tram = tram_scene.instantiate()
	
	map_manager.add_child(tram)
	tram.init_tram(spawn_node, map_manager)
	active_trams.append(tram)
